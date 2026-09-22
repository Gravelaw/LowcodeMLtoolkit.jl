export async function waitForService(probe, { timeoutMs = 30000, intervalMs = 500, signal } = {}) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline && !signal?.aborted) {
    if (await probe()) return;
    await new Promise(resolve => setTimeout(resolve, Math.min(intervalMs, Math.max(0, deadline - Date.now()))));
  }
  throw new Error(signal?.aborted ? 'Service readiness cancelled' : 'Service readiness timed out');
}
export function removeOwnedResource(docker, resource, id) {
  if (!['container', 'network', 'volume'].includes(resource.kind)) throw new Error('Unknown resource kind');
  const label = docker([resource.kind, 'inspect', resource.name, '--format', resource.kind === 'container' ? '{{index .Config.Labels "org.juliaflow.ci.run"}}' : '{{index .Labels "org.juliaflow.ci.run"}}']);
  if (label !== id) throw new Error('Ownership label mismatch; cleanup refused');
  docker([resource.kind, 'rm', ...(resource.kind === 'container' ? ['-f', '-v'] : []), resource.name]);
}
