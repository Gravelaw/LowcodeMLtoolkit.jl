import { readFileSync, appendFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export function hostedEnabled(policy) {
  if (policy.version !== 1 || !['local', 'hosted'].includes(policy.mode)) {
    throw new Error('Invalid CI execution policy; refusing to silently skip quality gates');
  }
  return policy.mode === 'hosted';
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const enabled = hostedEnabled(JSON.parse(readFileSync('scripts/ci/execution-policy.json', 'utf8')));
  if (process.env.GITHUB_OUTPUT) appendFileSync(process.env.GITHUB_OUTPUT, `enabled=${enabled}\n`);
  console.log(enabled ? 'Hosted quality gates enabled.' : 'Local CI active: hosted quality jobs skipped. Local evidence and review remain required.');
}
