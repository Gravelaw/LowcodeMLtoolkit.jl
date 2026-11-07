# Local CI (AKS-69)

The local runner executes the repository CI commands through Docker or a dedicated WSL2 Ubuntu 24.04 distro. It does not publish GitHub checks, waive reviews, or certify a release. Hosted Debian investigation remains paused. The current user-authorized execution policy is described below; historical records retain their original scope.

## Dedicated WSL backend while Docker is unavailable

The Windows Docker installer currently reports an unregistered MSI installation. A separate `juliaflow-ci-ubuntu24` WSL2 distro provides native Linux execution without Docker Desktop. Its source image is Canonical `ubuntu-24.04.5-wsl-amd64.wsl`, SHA-256 `bb415d824822c4b878125729af451a5d18fb13d1cf5cbed9a7393ad64ac6039e`. The setup script verifies Node 25.9.0 and Julia 1.12.7 downloads against published hashes and installs PostgreSQL 16 inside that distro. The package inventory hash is recorded per run. The existing `ubn` distro is untouched.

Run `scripts/ci/wsl-prepare.sh` once as root in that dedicated distro, then commit the WSL runner before selecting it:

```sh
npm run ci:local:wsl -- --ref HEAD --base e436a7cce186735524af4eac04cc9125c04bcb55 --profile pr --cache cold
npm run ci:local:wsl -- --ref HEAD --base e436a7cce186735524af4eac04cc9125c04bcb55 --profile pr --cache warm
npm run ci:local:wsl -- --ref HEAD --base e436a7cce186735524af4eac04cc9125c04bcb55 --profile release-candidate
```

The same workflow mapping and command order apply. Every job uses a clean clone, its own PostgreSQL cluster, a fresh random credential, a unique run directory and a bounded deadline. Cold dependency/browser caches are run-local; warm caches are keyed and locked. Logs and release artifacts stream to `artifacts/local-ci/<run-id>` on the Windows host before cleanup. The runner removes only its marked job directory. WSL distros share a host kernel and network, and Windows drives are mounted in the distro; this backend is an execution environment, not a security sandbox. Run only trusted candidate commits. A WSL pass cannot establish Docker image build, Docker network/mount, Windows-native, or GitHub-check success. Keep those gates open.

## Prerequisites and commands

Use Docker with Linux containers and Compose, Git, and a working native Node/npm CLI. The runner builds pinned Ubuntu 24.04 / Node 25.9.0 / Julia 1.12.7 runtime images and uses PostgreSQL 16. The hosted job named Debian currently runs Ubuntu, not a literal Debian distribution. Internet access is required for the initial image/dependency build; offline product certification is separate.

Commit the implementation before selecting it. Only committed source is exported; uncommitted files and user worktrees are not mounted. Execute from the matching implementation checkout:

```sh
npm run ci:local:parity
npm run ci:local -- --ref HEAD --base e436a7cce186735524af4eac04cc9125c04bcb55 --profile pr --cache cold
npm run ci:local -- --ref HEAD --base e436a7cce186735524af4eac04cc9125c04bcb55 --profile pr --cache warm
npm run ci:local -- --ref HEAD --base e436a7cce186735524af4eac04cc9125c04bcb55 --profile push
npm run ci:local -- --ref HEAD --base e436a7cce186735524af4eac04cc9125c04bcb55 --profile release-candidate
npm run ci:local -- --ref HEAD --base e436a7cce186735524af4eac04cc9125c04bcb55 --profile pr --job web
```

PR runs web, Julia and release jobs; push runs web and Julia. Release-candidate runs validation without creating a tag or release. Job selection produces a partial result, never full-profile success. Independent jobs continue after a job assertion failure; existing release phases retain fail-fast order and report later phases not_run. Warm caches are keyed by runtime image inputs, dependency files and job; a container-name lock rejects simultaneous writers. Cold runs use fresh run-owned volumes. Images and warm caches are retained; no broad Docker prune is used.

Workflow hashes cover actions, conditions, environment and timeout declarations, with additional command/order/timeout checks. Review the mapping when a workflow changes; do not merely regenerate hashes to silence drift. Checkout and setup actions are implemented locally by clean clone, explicit SHA/base, pinned runtime layers and project-local Playwright installation. Hosted artifact upload is replaced with local retention. Linux is not Windows platform proof.

## Isolation and evidence

Each job receives its own private network, PostgreSQL container, random password and clean clone. PostgreSQL has no host port binding, so an existing host database on 5432 is unaffected. Test containers receive no Docker socket or host source mount. The explicit JULIAFLOW_CI_EXTERNAL_POSTGRES=1 mode supplies the real database URL and pg_isready while retaining all metadata assertions; normal development still uses Compose. Only trusted repository commits should run on this host.

Evidence lives at artifacts/local-ci/<run-id>. Summary and JSONL events are updated during execution, including command starts/exits, candidate identity, runtime versions, image identity and cleanup outcomes. Release and browser artifacts are written directly into the host-mounted evidence directory, so killing a container preserves partial evidence. SHA-256 manifests cover retained files. Source bundles and resolved Julia/npm manifests remain local and ignored by Git. Do not automatically publish bundles, traces or screenshots: browser traces may contain ephemeral test credentials. Console/process logs redact known secrets and credential patterns before writing.

SIGINT/SIGTERM and job deadlines trigger bounded process/container cleanup after evidence retention. Failed cleanup is reported; ownership labels prevent deleting resources belonging to another run. Defaults preserve the workflow limits: web/Julia 360 minutes, PR release 180 minutes, release-candidate 90 minutes. No readiness deadline or assertion is relaxed.

After each run finalizes, both backends retain the latest **three completed runs total**, including passes, failures and partial runs. A cross-process lock covers the completed summary, retention decision and checksum manifest so another run cannot remove evidence during finalization. The current `summary.json` lists their IDs, statuses and commit heads under `retention.recent`, plus purged IDs. The fourth and older verified local run directories are removed with their logs, traces, bundles and manifests. A later run can inspect the two preceding directories before they expire. Active, interrupted-without-final-summary, malformed or unowned directories are never automatically removed; their IDs appear under `retention.unverified` for manual review. A lock or retention failure is reported separately from test outcome and makes the runner exit unsuccessfully. Copy exceptional evidence needed beyond three runs to a separately governed archive before it expires. This policy does not alter Git history or remote CI artifacts.

## Current verification boundary

At candidate `af1f87b`, cold WSL PR run `jfci-1790180924900-2f46c765` passed web and Julia with PostgreSQL-backed assertions. Its release job passed installation, contracts, build, tests, repository tests and base extension tests, then stalled in Julia package precompilation during `smoke-local-bootstrap`. After more than eight idle minutes, only that run's verified process group was terminated. The bootstrap readiness checks had not started; later smoke and browser phases are `not_run`. The retained artifact is an interrupted local infrastructure run, not a demonstrated product or hosted Debian diagnosis. Full release coverage remains open.

The later full cold diagnostic at `f912cc7` completed that precompilation and passed bootstrap readiness without changing versions or deadlines. Its five browser tests passed, but an owned Vite preview descendant had to be stopped manually after the tests so finalization could proceed. The cleanup defect is repaired in the current smoke script; this assisted run does not replace unattended same-candidate profile acceptance. See [diagnosis and hashes](verification-local-ci-aks69.md).

Focused Node runner tests cover argument validation, workflow drift, streaming redaction, spawn failure, timeout/cancellation, Linux descendant pipes, artifact retention and external-database preflight. Docker integration, cold/warm full suites, PostgreSQL service failure/isolation and matching Windows release validation require a functioning engine. An engine-preflight failure is retained and all unexecuted jobs remain not_run; it is not a product pass.

Docker Desktop currently fails at its Windows dockerInference socket. The old runtime socket directory was retained without deleting volumes or settings; the error recurred after recreation. No factory reset, global upgrade or host reboot was performed by this task. The user subsequently uninstalled Docker; reinstall reports MSI detection. Inspected registrations contain only a Docker reboot-required marker; restart/reinstallation remains a user-managed prerequisite. Resume container verification after the existing installation is restored. Existing product failures remain AKS-50/68 scope, without resuming hosted diagnosis.

Rollback is a scoped revert of AKS-69 code, with evidence preserved. Remove only verified run-owned resources using their recorded identifiers and ownership labels. Warm caches and original Docker data are not part of automatic cleanup.

## Local delivery and hosted skip policy (2026-09-30)

`scripts/ci/execution-policy.json` selects `local` (currently active) or `hosted`.
Both hosted workflows run only a lightweight policy job in local mode; their web,
Julia and release jobs are skipped. Invalid policy fails the routing job. Change
mode to `hosted` to restore hosted jobs. Local runners ignore this hosted selector
and always execute every command in the requested profile. Workflow fingerprints
still reject unreviewed drift. These changes take effect on GitHub only after
separate authorized publication; this task does not push or change protections.

Run the full local release-candidate profile, then promote its retained run:

```sh
npm run ci:local:wsl -- --ref HEAD --base 11856e4 --profile release-candidate --cache cold
npm run cd:local -- --run <successful-run-id>
```

The release job packages committed source, built frontend and resolved Julia
manifest before cleanup. CD verifies the complete run, every release phase,
identity, cleanup and file hashes, writes a versioned directory and atomically
updates `artifacts/local-releases/current.json`. Failed, partial, skipped or modified
evidence cannot promote. Existing versions are never overwritten. Previous versions
remain available for deliberate rollback using retained receipts. Promotion uses a
lock and preserves interrupted staging for diagnosis.

The local `.tar.gz` is a source-and-built-web delivery requiring Node 25, Julia 1.12,
PostgreSQL 16 and dependency installation. It is not a self-contained/offline EXE or
Docker image and does not certify other platforms. Release validation and package
promotion are distinct results. No remote upload or new persistent credential is
required. Existing per-run ephemeral database credentials stay isolated/redacted.

### WSL memory policy

Before each Julia job, the runner allocates a temporary 3 GiB swap file under
that job's owned directory. Web-only jobs do not allocate it. Preparation records
size, path and UUID in evidence; job summaries record the allocation. Cleanup
checks the resolved path and UUID, uses bounded `swapoff`, verifies inactivity,
then removes the owned directory. A cleanup failure preserves storage and blocks
promotion. Allow at least 3 GiB additional free disk per concurrent Julia job.
This does not modify `.wslconfig`, `/etc/fstab`, or other swap files, and survives
WSL shutdown through fresh preparation on each invocation.

Each isolated WSL job prepends a run-owned Julia launcher with
`--heap-size-hint=1500M` and sets `JULIA_NUM_PRECOMPILE_TASKS=1`.
This requests more frequent garbage collection and serial package precompilation;
it does not cap all native allocations or change assertions, compiled-module
policy or deadlines. Job summaries record these settings. The Julia 1.12.7 CLI
probe reports 1572864000 bytes; its environment-only hint probe reports zero.
No host WSL configuration or unrelated distro is changed.
[Julia memory guidance](https://docs.julialang.org/en/v1/manual/memory-management/).
