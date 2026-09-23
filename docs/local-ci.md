# Local CI (AKS-69)

The local runner executes the repository CI commands through Docker or a dedicated WSL2 Ubuntu 24.04 distro. It does not publish GitHub checks, waive reviews, or certify a release. Hosted Debian investigation remains paused. Both GitHub workflow files are unchanged.

## Dedicated WSL backend while Docker is unavailable

The Windows Docker installer currently reports an unregistered MSI installation. A separate `juliaflow-ci-ubuntu24` WSL2 distro provides native Linux execution without Docker Desktop. Its source image is Canonical `ubuntu-24.04.5-wsl-amd64.wsl`, SHA-256 `bb415d824822c4b878125729af451a5d18fb13d1cf5cbed9a7393ad64ac6039e`. The setup script verifies Node 25.9.0 and Julia 1.12.7 downloads against published hashes and installs PostgreSQL 16 inside that distro. The package inventory hash is recorded per run. The existing `ubn` distro is untouched.

Run `scripts/ci/wsl-prepare.sh` once as root in that dedicated distro, then commit the WSL runner before selecting it:

```sh
npm run ci:local:wsl -- --ref HEAD --base e436a7cce186735524af4eac04cc9125c04bcb55 --profile pr --cache cold
npm run ci:local:wsl -- --ref HEAD --base e436a7cce186735524af4eac04cc9125c04bcb55 --profile pr --cache warm
npm run ci:local:wsl -- --ref HEAD --base e436a7cce186735524af4eac04cc9125c04bcb55 --profile release-candidate
```

The same workflow mapping and command order apply. Every job uses a clean clone, its own PostgreSQL cluster, a fresh random credential, a unique run directory and a bounded deadline. Cold dependency/browser caches are run-local; warm caches are keyed and locked. Logs and release artifacts stream to `artifacts/local-ci/<run-id>` on the Windows host before cleanup. The runner removes only its marked job directory. WSL distros share a host kernel and network, and Windows drives are mounted in the distro; this backend is an execution environment, not a security sandbox. A WSL pass cannot establish Docker image build, Docker network/mount, Windows-native, or GitHub-check success. Keep those gates open.

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

## Current verification boundary

Focused Node runner tests cover argument validation, workflow drift, streaming redaction, spawn failure, timeout/cancellation, Linux descendant pipes, artifact retention and external-database preflight. Docker integration, cold/warm full suites, PostgreSQL service failure/isolation and matching Windows release validation require a functioning engine. An engine-preflight failure is retained and all unexecuted jobs remain not_run; it is not a product pass.

Docker Desktop currently fails at its Windows dockerInference socket. The old runtime socket directory was retained without deleting volumes or settings; the error recurred after recreation. No factory reset, global upgrade or host reboot was performed by this task. The user subsequently uninstalled Docker; reinstall reports MSI detection. Inspected registrations contain only a Docker reboot-required marker; restart/reinstallation remains a user-managed prerequisite. Resume container verification after the existing installation is restored. Existing product failures remain AKS-50/68 scope, without resuming hosted diagnosis.

Rollback is a scoped revert of AKS-69 code, with evidence preserved. Remove only verified run-owned resources using their recorded identifiers and ownership labels. Warm caches and original Docker data are not part of automatic cleanup.
