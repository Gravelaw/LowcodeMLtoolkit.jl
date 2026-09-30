import { stagePackage } from './delivery.mjs';
import { spawnSync } from 'node:child_process';
import { appendFileSync, mkdirSync, existsSync, copyFileSync, readFileSync, symlinkSync } from 'node:fs';
import { join } from 'node:path';
import { runProcess } from './process.mjs';
import { verifyParity } from './parity.mjs';
import { writeJson, inventory } from './evidence.mjs';

const [jobName, expectedHead, expectedTree] = process.argv.slice(2);
const manifest = verifyParity();
const job = manifest.jobs[jobName];
if (!job || !/^[a-f0-9]{40}$/.test(expectedHead ?? '') || !/^[a-f0-9]{40}$/.test(expectedTree ?? '')) throw new Error('Invalid job identity');
const out = process.env.JULIAFLOW_CI_EVIDENCE_DIR ?? '/evidence';
mkdirSync(out, { recursive: true });
// Write directly to the host-mounted evidence directory, including while a phase
// is hung. A container kill must not destroy browser or release diagnostics.
mkdirSync('artifacts', { recursive: true });
mkdirSync(join(out, 'release-verification'), { recursive: true });
symlinkSync(join(out, 'release-verification'), 'artifacts/release-verification', 'dir');
function git(args) {
  const r = spawnSync('git', args, { encoding: 'utf8', timeout: 30000 });
  if (r.status !== 0) throw new Error(r.stderr || 'git failed');
  return r.stdout.trim();
}
function candidate() { return { head: git(['rev-parse', 'HEAD']), tree: git(['rev-parse', 'HEAD^{tree}']), dirty: git(['status', '--porcelain', '--untracked-files=all']) }; }
const report = { job: jobName, expectedHead, expectedTree, startedAt: new Date().toISOString(), status: 'running',
  resourcePolicy: { juliaHeapHint: process.env.JULIAFLOW_CI_HEAP_HINT ?? null, precompileTasks: process.env.JULIA_NUM_PRECOMPILE_TASKS ?? null },
  steps: job.commands.map(command => ({ command, status: 'not_run' })) };
const save = () => writeJson(join(out, 'summary.json'), report);
const events = event => appendFileSync(join(out, 'events.jsonl'), JSON.stringify({ at: new Date().toISOString(), ...event }) + '\n');
const controller = new AbortController();
for (const s of ['SIGINT', 'SIGTERM']) process.on(s, () => controller.abort());
save();
try {
  report.before = candidate();
  if (report.before.head !== expectedHead || report.before.tree !== expectedTree || report.before.dirty) throw new Error('Candidate is not the requested clean commit');
  report.runtime = Object.fromEntries(['node', 'npm', 'julia', 'git'].map(c => [c, spawnSync(c, ['--version'], { encoding: 'utf8', timeout: 30000 }).stdout?.trim()]));
  const deadline = Math.min(Date.now() + job.timeoutMinutes * 60000, Number(process.env.JULIAFLOW_CI_DEADLINE) || Infinity);
  for (const [i, entry] of report.steps.entries()) {
    if (controller.signal.aborted) { report.status = 'cancelled'; break; }
    const remaining = deadline - Date.now();
    if (remaining <= 0) { report.status = 'timed_out'; break; }
    entry.status = 'running'; entry.startedAt = new Date().toISOString(); save();
    const result = await runProcess('bash', ['-eo', 'pipefail', '-c', entry.command], {
      logPath: join(out, `step-${i + 1}.log`), timeoutMs: remaining, signal: controller.signal,
      onEvent: event => { events({ step: i + 1, ...event }); }
    });
    Object.assign(entry, result); save();
    if (result.status !== 'passed') { report.status = result.status; break; }
  }
  if (report.status === 'running') report.status = 'passed';
  if (report.status === 'passed' && jobName === 'release-candidate') report.delivery = stagePackage(process.cwd(), out, expectedHead, expectedTree);
  report.after = candidate();
  if (report.after.head !== expectedHead || report.after.tree !== expectedTree || report.after.dirty) {
    report.status = 'failed'; report.error = 'Candidate drift or dirty checkout after job';
  }
} catch (error) { report.status = 'failed'; report.error = error.message; }
finally {
  try {
    for (const path of ['Manifest.toml', 'package-lock.json']) if (existsSync(path)) copyFileSync(path, join(out, path));
    // Browser trace archives are retained locally; never publish this directory automatically.
    const releaseSummary = 'artifacts/release-verification/latest/summary.json';
    if (existsSync(releaseSummary)) report.release = JSON.parse(readFileSync(releaseSummary, 'utf8'));
  } catch (error) { report.artifactError = error.message; report.status = 'failed'; }
  report.finishedAt = new Date().toISOString(); save(); writeJson(join(out, 'sha256.json'), inventory(out));
}
process.exitCode = report.status === 'passed' ? 0 : 1;
