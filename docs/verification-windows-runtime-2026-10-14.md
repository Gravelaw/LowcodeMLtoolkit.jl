# Windows runtime follow-up (AKS-69 / AKS-58)

This increment starts from `fbaae563380e7906e37414edcaf53f626b5d1911`.
The retained October 14 qualification failures belong to that revision and are
not overwritten by these fixes. This is development evidence, not release or
human acceptance. Exact final-candidate aggregate verification and independent
correctness, UI and local security review are required before publication.

## Startup and process ownership

`dev:local` installs declared dependencies, then runs strict `Pkg.precompile`
and imports `JuliaFlowMonorepo` before starting services. Preparation has a
600-second execution budget and a bounded cleanup grace period. Its redacted
log is retained; failures, cancellation and incomplete termination prevent
service startup. A failed termination reports the owned PID and incomplete
cleanup rather than hanging or claiming the process was stopped. The existing
60/90-second endpoint readiness deadlines are unchanged. Dependency installation
itself remains a separate synchronous operation without this preparation bound.

## GPU test contract

The timed harness preserves source-loading coverage with
`--compiled-modules=no` and `JULIAFLOW_CUDA_SMOKE=0`. With
`JULIAFLOW_CUDA_SMOKE=1`, a worker-containing slice also requires a second phase
with normal compiled loading and the unchanged real hardware assertions. Either
phase failing fails the command. Qualified commands are
`npm run julia:test:worker`, `npm run julia:test:timed`, and GPU-opted-in
`npm run verify:release`. CPU-only slices do not establish GPU qualification.

The raw `npm run julia:test` command retains its no-compiled-modules behavior.
GPU opt-in through that raw entrypoint still exposes the unsupported-mode
failure on this Windows hardware; it is not an alternative qualification gate.
The retained minimal CUDA broadcast failure reported unsupported
`gpu_gc_pool_alloc` and dynamic invocations in GPUCompiler. Normal compiled
loading successfully allocated, broadcast, synchronized and read back values,
and ran the KernelAbstractions affine kernel on the physical selected device.

## Version provenance and CUDA diagnostic

The health contract adds optional `juliaVersion`, populated from Julia `VERSION`.
Older gateways remain compatible. Shell and settings display measured live
health values, identify stale values as last reported, and show unavailable
for missing versions or demo data. They no longer claim literal Julia 1.10.2
or unverified update status. Node 26 frontend test workers disable its
experimental process storage when supported so jsdom browser storage is tested.

The CUDA warning remains visible: the runtime reported 13.4 while the selected
artifact/toolkit reported 13.2. The diagnostic found both task-owned
`cudart64_13.dll` and NVIDIA's Windows DriverStore hybrid runtime loaded.
This is evidence of a runtime/toolkit discrepancy, not proof of its upstream
cause or compatibility. No driver, CUDA preference, vendor package or warning
was changed. Passing operations do not dismiss the diagnostic or qualify all
algorithms, other devices, other vendors or operating systems.

## Acceptance and evidence limits

Retained qualification evidence includes real Edge application workflows,
light/dark screenshots, table Tab entry and ArrowRight scrolling, and reflow at
viewport/device-scale equivalents of 100/200/400 percent. Native browser UI
zoom and human/assistive-technology acceptance remain unrun: this environment
has no working browser UI automation capability. CSS zoom is not native zoom.
Opaque solid HTML text contrast sampling is not a full WCAG assessment.

Focused follow-up results: frontend 71 passed; contract suite 74 passed with
3 platform skips; production build passed; local CI runner tests 24 passed
with 2 platform skips. The injected failed-termination regression passed.
The two-phase worker run passed 55 helper + 216 worker assertions with source
loading and 55 helper + 225 worker assertions with required physical CUDA.
Fresh compilation passed in a new depot with no compiled cache: existing
dependency packages/artifacts/registry were shared through task-owned junctions,
with two precompile tasks. Strict preparation completed in 465.444 seconds;
gateway health became ready in 8.770 seconds, within the unchanged 60-second
service deadline, and the foundation workflow smoke passed. The installed Edge
155.0.4283.45 application workflow passed all 11 stages; its light screenshot
shows the measured Julia 1.12.6 badge. Gateway regression and exact aggregate
results must be recorded separately with candidate identity. The final review
uses a checksummed immutable patch until a committed candidate is available.

The initial AKS-69 evidence update was rejected by automatic approval review.
The user explicitly approved the update; the subsequent write and readback
confirmed the cleanup finding, disposition and bounded test results are recorded.
The issue remains In Progress. This does not close milestone acceptance.

Docker's installed client cannot reach the daemon (`docker_engine` named pipe
missing). No Docker Desktop executable was found in the standard installed
locations. No installation, environment switch, hosted workflow, PR, merge,
tag, deployment or billing/security setting change is authorized here.
Rolling remains deferred until October 19. Wider platform, original-board,
full fitting and participant acceptance stay open.
