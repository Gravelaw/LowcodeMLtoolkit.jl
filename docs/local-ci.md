# Local CI

Local CI runs through [EasyCI](https://github.com/Gravelaw/EasyCI). EasyCI reads
`.github/workflows/ci.yml` and `release-candidate.yml` directly and runs their
steps natively in a dedicated WSL2 distro. JuliaFlow keeps no copy of the
workflow commands, so there is no parity mapping to keep in sync.
`ci.yml` is the only source.

The earlier in-repo runner (`scripts/ci/local.mjs`, `wsl.mjs`, `job.mjs`,
`parity.mjs`, `workflows.json`) was retired in issue #67. Before retirement,
EasyCI's native jobs gave the same verdicts as that runner on five commits,
and the release-candidate gate passed natively and was promoted with a
verified receipt. Older evidence is described in
[the archived verification report](archive/2026-11-11-pre-product-spec/verification-local-ci-aks69.md).

## One-time setup

1. Create the `juliaflow-ci-ubuntu24` WSL2 distro from Canonical
   `ubuntu-24.04.5-wsl-amd64.wsl` (SHA-256
   `bb415d824822c4b878125729af451a5d18fb13d1cf5cbed9a7393ad64ac6039e`).
2. Run `scripts/ci/wsl-prepare.sh` once as root inside it. It installs Node
   25.9.0 and Julia 1.12.7, both checked against their published hashes, and
   PostgreSQL 16.
3. Install EasyCI and check the machine, following
   [EasyCI's adopt guide](https://github.com/Gravelaw/EasyCI/blob/main/docs/guide/adopt.md):
   `python -m easyci doctor --repo <this checkout>`.

The JuliaFlow config lives in EasyCI at `examples/juliaflow/easyci.yml`.

## Running

```sh
python -m easyci plan --repo <this checkout> --profile pr --config <EasyCI>/examples/juliaflow/easyci.yml
python -m easyci run --repo <this checkout> --profile pr --config <EasyCI>/examples/juliaflow/easyci.yml
python -m easyci wait <run-id>
```

- **Profiles:** `pr` runs `web`, `julia` and `debian-release-gate`. `push` runs
  `web` and `julia`. The release-candidate profile runs `release-candidate.yml`.
- **Commit statuses:** EasyCI posts an `easyci/<job>` commit status per job to
  GitHub.
- **Clean copy:** each run uses a clean copy of the committed candidate.
  Uncommitted files are not tested.
- **Warm state:** the Julia depot, npm cache and Playwright browsers persist in
  the distro, so later runs reuse them.
- **Failures:** `python -m easyci explain <run-id>` gives the reason for a
  failure, and `python -m easyci logs` shows a job log.
- **Evidence:** EasyCI keeps run evidence with checksums. `python -m easyci verify`
  checks it is unchanged, and `python -m easyci promote` copies a passed
  release-candidate artifact to a release folder with a receipt.

## Memory in the 4 GiB WSL VM

The EasyCI config gives each Julia job these settings:
- a `julia` launcher with `--heap-size-hint=1500M`;
- `JULIA_NUM_PRECOMPILE_TASKS=1`;
- a temporary 3 GiB swap file, released by the job's cleanup hook.

Without them the kernel kills the test process (exit 137). Allow at least
3 GiB free disk per concurrent Julia job. No host `.wslconfig` setting,
`/etc/fstab` entry or other distro is changed.

The distro shares the host kernel and network, and Windows drives are mounted
in it. It is an execution environment, not a security sandbox, so run only
trusted commits.

## Hosted skip policy

`scripts/ci/execution-policy.json` selects `local` (currently active) or
`hosted`. In local mode, both hosted workflows run only the lightweight
`execution-policy` job. Their web, Julia and release jobs are skipped.

An invalid policy fails the routing job. To restore the hosted jobs, set the
mode to `hosted`. EasyCI skips the `execution-policy` job and runs every job
in the requested profile.

## Not covered

- A Linux WSL pass proves neither Windows-native behavior nor hosted GitHub
  check success.
- `npm run cd:local` (`scripts/ci/delivery.mjs`) promoted evidence written by
  the retired runner, so it has no producer now. Its future is tracked
  separately.
