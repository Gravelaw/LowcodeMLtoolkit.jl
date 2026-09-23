import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, readdirSync, writeFileSync, renameSync, lstatSync, copyFileSync, realpathSync, rmSync } from 'node:fs';
import { join, relative, dirname, isAbsolute } from 'node:path';
import { redactStartup } from '../lib/startup-diagnostics.mjs';

export function writeJson(path, value) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(`${path}.tmp`, JSON.stringify(value, null, 2) + '\n');
  renameSync(`${path}.tmp`, path);
}
export function inventory(root) {
  const files = {};
  function visit(dir) {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const path = join(dir, entry.name);
      if (entry.isSymbolicLink()) continue;
      if (entry.isDirectory()) visit(path);
      else if (entry.isFile() && entry.name !== 'sha256.json') files[relative(root, path).replaceAll('\\', '/')] = createHash('sha256').update(readFileSync(path)).digest('hex');
    }
  }
  visit(root); return files;
}
export function retainTree(source, target, env = {}) {
  if (!lstatSync(source, { throwIfNoEntry: false })) return;
  if (lstatSync(source).isSymbolicLink()) throw new Error('Evidence symlink rejected');
  mkdirSync(target, { recursive: true });
  for (const entry of readdirSync(source, { withFileTypes: true })) {
    const from = join(source, entry.name), to = join(target, entry.name);
    if (entry.isSymbolicLink()) throw new Error('Evidence symlink rejected');
    if (entry.isDirectory()) retainTree(from, to, env);
    else if (/\.(log|json|txt|md|toml|jsonl)$/i.test(entry.name)) writeFileSync(to, redactStartup(readFileSync(from, 'utf8'), env));
    else copyFileSync(from, to);
  }
}

// Retain the three latest completed local runs across both backends. Never
// remove an unverified directory or a run whose summary still says running.
export function pruneCompletedRuns(evidenceRoot, currentId, keep = 3) {
  if (!Number.isSafeInteger(keep) || keep < 1 || !/^jfci-[0-9]+-[a-f0-9]{8}$/.test(currentId)) throw new Error('Invalid evidence retention request');
  const root = realpathSync(evidenceRoot);
  const completed = [], unverified = [];
  for (const entry of readdirSync(root, { withFileTypes: true })) {
    if (!/^jfci-[0-9]+-[a-f0-9]{8}$/.test(entry.name)) continue;
    if (!entry.isDirectory() || entry.isSymbolicLink()) { unverified.push(entry.name); continue; }
    const target = join(root, entry.name), summaryPath = join(target, 'summary.json');
    const targetReal = realpathSync(target);
    if (dirname(targetReal) !== root || isAbsolute(relative(root, targetReal))) { unverified.push(entry.name); continue; }
    const summaryStat = lstatSync(summaryPath, { throwIfNoEntry: false });
    if (!summaryStat?.isFile() || summaryStat.size > 1024 * 1024) { unverified.push(entry.name); continue; }
    let summary;
    try { summary = JSON.parse(readFileSync(summaryPath, 'utf8')); } catch { unverified.push(entry.name); continue; }
    if (summary.id !== entry.name || summary.status === 'running' ||
        !['passed', 'failed', 'timed_out', 'cancelled', 'partial'].includes(summary.status) ||
        typeof summary.finishedAt !== 'string' || !Number.isFinite(Date.parse(summary.finishedAt))) {
      unverified.push(entry.name); continue;
    }
    completed.push({ id: entry.name, target: targetReal, finishedAt: Date.parse(summary.finishedAt), status: summary.status, head: summary.head ?? null });
  }
  if (!completed.some(run => run.id === currentId)) throw new Error('Current run has no completed, owned summary');
  completed.sort((a, b) => b.finishedAt - a.finishedAt || b.id.localeCompare(a.id));
  const keepIds = completed.slice(0, keep).map(run => run.id);
  if (!keepIds.includes(currentId)) throw new Error('Current run is outside the retention window');
  const purged = [];
  for (const run of completed.slice(keep)) {
    // Recheck immediately before recursive removal, including the exact path.
    if (dirname(realpathSync(run.target)) !== root || lstatSync(run.target).isSymbolicLink()) throw new Error(`Evidence path changed: ${run.id}`);
    rmSync(run.target, { recursive: true });
    purged.push(run.id);
  }
  return { keep, retained: keepIds, recent: completed.slice(0, keep).map(({ id, status, head, finishedAt }) =>
    ({ id, status, head, finishedAt: new Date(finishedAt).toISOString() })), purged, unverified };
}

export function finishRunEvidence(out, report) {
  report.finishedAt = new Date().toISOString();
  writeJson(join(out, 'summary.json'), report);
  try { report.retention = pruneCompletedRuns(dirname(out), report.id); }
  catch (error) {
    report.retention = { status: 'failed', error: error.message };
    report.status = 'failed';
  }
  writeJson(join(out, 'summary.json'), report);
  writeJson(join(out, 'sha256.json'), inventory(out));
}
