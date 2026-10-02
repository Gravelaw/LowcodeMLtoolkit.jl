#!/usr/bin/env bash
set -euo pipefail

mode=${1:-}
run_id=${2:-}
job=${3:-}
if [[ ! $run_id =~ ^jfci-[0-9]+-[a-f0-9]{8}$ ]] || [[ ! $job =~ ^[a-z][a-z-]+$ ]]; then
  echo 'Invalid WSL job identity' >&2
  exit 1
fi
run_root="/ci-run/$run_id/$job"

cleanup() {
  [[ -e $run_root ]] || return 0
  if [[ ! -f $run_root/owner || $(cat "$run_root/owner") != "$run_id:$job" ]]; then
    echo 'WSL cleanup refused: ownership mismatch' >&2
    return 1
  fi
  local stopped=1
  if [[ -d $run_root/pg && -f $run_root/pg/postmaster.pid ]]; then
    if ! runuser -u postgres -- /usr/lib/postgresql/16/bin/pg_ctl -D "$run_root/pg" -m immediate -w -t 30 stop >/dev/null 2>&1; then
      stopped=0
    fi
    if runuser -u postgres -- /usr/lib/postgresql/16/bin/pg_ctl -D "$run_root/pg" status >/dev/null 2>&1; then
      stopped=0
    fi
  fi
  if [[ -n ${evidence:-} && -f $run_root/postgres.log ]]; then
    cp "$run_root/postgres.log" "$evidence/postgres.log" || return 1
  fi
  if [[ $stopped != 1 ]]; then
    echo 'WSL cleanup refused: PostgreSQL shutdown unverified' >&2
    return 1
  fi
  rm -rf -- "$run_root"
}
on_exit() {
  local result=$?
  if ! cleanup; then result=1; fi
  if [[ -n ${evidence:-} && -d $evidence ]]; then
    printf '{"exitCode":%s,"endedAt":"%s"}\n' "$result" "$(date -u +%FT%TZ)" > "$evidence/wsl-exit.json"
  fi
  exit "$result"
}
if [[ $mode == cleanup ]]; then
  evidence=${4:-}
  cleanup
  exit 0
fi
if [[ $mode != run || $# != 11 ]]; then
  echo 'Invalid WSL job arguments' >&2
  exit 1
fi
head=$4 tree=$5 base=$6 bundle=$7 evidence=$8 cache_mode=$9 cache_key=${10} port=${11}
if [[ ! $head =~ ^[a-f0-9]{40}$ || ! $tree =~ ^[a-f0-9]{40}$ || ! $base =~ ^[a-f0-9]{40}$ ||
      ! $cache_key =~ ^[a-f0-9]{16}$ || ! $port =~ ^[0-9]{5}$ ||
      ! $bundle == /mnt/?/* || ! $evidence == /mnt/?/* ||
      ! $cache_mode =~ ^(cold|warm)$ ]]; then
  echo 'Invalid WSL job inputs' >&2
  exit 1
fi
if [[ $(id -u) != 0 ]] || ! grep -q '^VERSION_ID="24.04"$' /etc/os-release; then
  echo 'Dedicated Ubuntu 24.04 root runtime required' >&2
  exit 1
fi
if [[ -e $run_root ]]; then echo 'WSL job directory already exists' >&2; exit 1; fi
mkdir -p "$run_root" "$evidence"
printf '%s' "$run_id:$job" > "$run_root/owner"
printf '%s' "$$" > "$evidence/wsl-pid"
trap on_exit EXIT

export PATH=/opt/juliaflow-ci/node/bin:/opt/juliaflow-ci/julia/bin:/usr/lib/postgresql/16/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
for tool in node npm julia pg_ctl git runuser; do command -v "$tool" >/dev/null; done
git clone --quiet "$bundle" "$run_root/repo"
git -C "$run_root/repo" checkout --quiet --detach "$head"

# Keep compiler/depot preparation from exhausting the shared WSL VM. All mapped
# commands still run, with unchanged assertions, compile modes and deadlines.
mkdir -p "$run_root/bin"
sed 's/\r$//' "$run_root/repo/scripts/ci/wsl-julia.sh" > "$run_root/bin/julia"
chmod 755 "$run_root/bin/julia"
export PATH="$run_root/bin:$PATH"
export JULIA_NUM_PRECOMPILE_TASKS=1 JULIAFLOW_CI_HEAP_HINT=1500M

mkdir -p "$run_root/pg" "$run_root/socket"
chown postgres:postgres "$run_root/pg" "$run_root/socket"
chmod 755 "$run_root" "$(dirname "$run_root")"
touch "$run_root/postgres.log"
chown postgres:postgres "$run_root/postgres.log"
password=${JULIAFLOW_CI_PG_PASSWORD:?runner password required}
if [[ ! $password =~ ^[a-f0-9]{48}$ ]]; then echo 'Invalid runner password' >&2; exit 1; fi
printf '%s\n' "$password" > "$run_root/pg-password"
chown postgres:postgres "$run_root/pg-password"
chmod 600 "$run_root/pg-password"
if ! runuser -u postgres -- initdb -D "$run_root/pg" -U juliaflow --pwfile="$run_root/pg-password" \
  --auth-host=scram-sha-256 --auth-local=trust --no-instructions > "$evidence/postgres-init.log" 2>&1; then
  cat "$evidence/postgres-init.log" >&2
  exit 1
fi
if ! runuser -u postgres -- pg_ctl -D "$run_root/pg" -l "$run_root/postgres.log" \
  -o "-p $port -h 127.0.0.1 -k $run_root/socket" start > "$evidence/postgres-start.log" 2>&1; then
  cat "$evidence/postgres-start.log" >&2
  exit 1
fi
ready=0
for _ in {1..60}; do
  if pg_isready -h 127.0.0.1 -p "$port" -U juliaflow -d postgres >/dev/null 2>&1; then ready=1; break; fi
  sleep .5
done
if [[ $ready != 1 ]]; then echo 'PostgreSQL readiness timed out' >&2; exit 1; fi
runuser -u postgres -- createdb -h "$run_root/socket" -p "$port" -U juliaflow juliaflow

if [[ $cache_mode == warm ]]; then
  cache=/ci-cache/$cache_key
  mkdir -p /ci-cache
  exec 9>"/ci-cache/$cache_key.lock"
  flock -w 30 9 || { echo 'Warm cache is held by another run' >&2; exit 1; }
else
  cache=$run_root/cache
fi
mkdir -p "$cache/npm" "$cache/julia" "$cache/playwright"
export NPM_CONFIG_CACHE="$cache/npm" JULIA_DEPOT_PATH="$cache/julia" PLAYWRIGHT_BROWSERS_PATH="$cache/playwright"
export JULIAFLOW_CONTROL_DOC_BASE="$base" JULIAFLOW_CI_EXTERNAL_POSTGRES=1 JULIAFLOW_JULIA_CMD=julia
export JULIAFLOW_DATABASE_URL="postgresql://juliaflow:$password@127.0.0.1:$port/juliaflow"
export JULIAFLOW_TEST_POSTGRES_URL="$JULIAFLOW_DATABASE_URL"
export JULIAFLOW_TEST_POSTGRES_SCHEMA="juliaflow_ci_${run_id##*-}_${job//-/_}"
export JULIAFLOW_CI_EVIDENCE_DIR="$evidence"
export JULIAFLOW_CI_DEADLINE=${JULIAFLOW_CI_DEADLINE:?deadline required}
cd "$run_root/repo"
node scripts/ci/job.mjs "$job" "$head" "$tree"
