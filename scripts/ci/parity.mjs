import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export function verifyParity(root = process.cwd()) {
  const manifest = JSON.parse(readFileSync(resolve(root, 'scripts/ci/workflows.json'), 'utf8'));
  for (const [path, expected] of Object.entries(manifest.workflows)) {
    const source = readFileSync(resolve(root, path), 'utf8').replaceAll('\r\n', '\n');
    const actual = createHash('sha256').update(source).digest('hex');
    if (actual !== expected) throw new Error(`Workflow parity drift: ${path}; review all commands, conditions, actions and timeouts before updating the mapping`);
    // Validate every command as well as the complete workflow fingerprint.
    const commands = [...source.matchAll(/^      - run: (.+)$/gm)].map(m => m[1]);
    const mapped = Object.values(manifest.jobs).filter(j => j.workflow === path).flatMap(j => j.commands);
    if (JSON.stringify(commands) !== JSON.stringify(mapped)) throw new Error(`Command mapping mismatch: ${path}`);
    for (const job of Object.values(manifest.jobs).filter(j => j.workflow === path)) {
      const section = source.split(`  ${job.job}:\n`)[1]?.split(/^  [a-z][\w-]*:\n/m)[0];
      if (!section) throw new Error(`Missing workflow job ${job.job}`);
      const timeout = Number(section.match(/^    timeout-minutes: (\d+)$/m)?.[1] ?? 360);
      if (timeout !== job.timeoutMinutes) throw new Error(`Timeout mapping mismatch: ${job.job}`);
    }
  }
  if (JSON.stringify(manifest.profiles) !== JSON.stringify({ pr: ['web', 'julia', 'debian-release-gate'], push: ['web', 'julia'], 'release-candidate': ['release-candidate'] })) throw new Error('Event/profile mapping mismatch');
  return manifest;
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  verifyParity();
  console.log('Local CI workflow mapping matches both complete workflow files.');
}
