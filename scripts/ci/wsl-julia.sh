#!/usr/bin/env bash
set -euo pipefail
# A GC hint, not an allocation cap: preserve test semantics in the 4 GiB WSL VM.
# Julia 1.12.7 requires the CLI option; its environment equivalent is ignored.
exec /opt/juliaflow-ci/julia/bin/julia --heap-size-hint=1500M "$@"
