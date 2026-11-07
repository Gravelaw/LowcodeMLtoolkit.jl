#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) != 0 ]] || ! grep -q '^VERSION_ID="24.04"$' /etc/os-release; then
  echo 'Run as root in the dedicated Ubuntu 24.04 WSL distro.' >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  bash ca-certificates curl git xz-utils python3 procps build-essential \
  libatomic1 libstdc++6 postgresql-16 postgresql-client-16

mkdir -p /opt/juliaflow-ci/node /opt/juliaflow-ci/julia
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

curl --fail --location --silent --show-error \
  https://nodejs.org/dist/v25.9.0/node-v25.9.0-linux-x64.tar.xz -o "$work/node.tar.xz"
echo '1d8db7d6e291d167e8c467ae4094be175e1a0b3969c7ae1f8955b9f7824f7b2e  '"$work/node.tar.xz" | sha256sum --check --status
tar -xJf "$work/node.tar.xz" -C /opt/juliaflow-ci/node --strip-components=1

curl --fail --location --silent --show-error \
  https://julialang-s3.julialang.org/bin/linux/x64/1.12/julia-1.12.7-linux-x86_64.tar.gz -o "$work/julia.tar.gz"
echo '4e7e9e776634d24835250de67cde39b0d4af15bc432eb20697e6be6c28ea69e8  '"$work/julia.tar.gz" | sha256sum --check --status
tar -xzf "$work/julia.tar.gz" -C /opt/juliaflow-ci/julia --strip-components=1

for tool in node npm npx; do ln -sfn "/opt/juliaflow-ci/node/bin/$tool" "/usr/local/bin/$tool"; done
ln -sfn /opt/juliaflow-ci/julia/bin/julia /usr/local/bin/julia
node --version
npm --version
julia --version
pg_config --version
dpkg-query -W -f='${Package} ${Version}\n' | sort > /opt/juliaflow-ci/packages.txt
