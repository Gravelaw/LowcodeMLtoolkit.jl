// GPUCompiler requires normal module compilation on the qualified Julia 1.12 host.
// Keep source-loading coverage and require a separate, non-skippable hardware phase.
export function juliaTestPhases({ cudaRequested, workerSelected }) {
  const phases = [{ name: "source-loading", compiledModules: "no", cudaSmoke: "0" }];
  if (cudaRequested && workerSelected) {
    phases.push({ name: "physical-cuda", compiledModules: "yes", cudaSmoke: "1" });
  }
  return phases;
}

export function executeJuliaTestPhases(phases, execute, announce = () => {}) {
  for (const phase of phases) {
    announce(phase);
    const result = execute(phase);
    if (result.error) throw result.error;
    if (result.status !== 0) return result.status ?? 1;
  }
  return 0;
}
