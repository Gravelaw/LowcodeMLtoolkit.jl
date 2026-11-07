import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync, mkdirSync, cpSync, existsSync, lstatSync, realpathSync, renameSync, rmdirSync } from 'node:fs';
import { join, resolve, dirname, relative, isAbsolute } from 'node:path';
import { fileURLToPath } from 'node:url';
import { inventory, writeJson } from './evidence.mjs';

const phases = ['npm-install', 'doctor-host', 'julia-instantiate', 'validate-contracts', 'build', 'test',
  'julia-repo-tests', 'julia-base-extension-tests', 'smoke-local-bootstrap', 'smoke-local-data-estate',
  'smoke-local-metadata', 'smoke-local-hardware', 'smoke-local-explainability', 'smoke-local-offline-hub',
  'smoke-local-reproducibility', 'smoke-local-migration', 'smoke-live-backend-browser', 'smoke-create-project', 'smoke-durable-analysis',
  'validate-control-doc-sync', 'validate-brd-traceability', 'git-diff-check'];
const json = path => JSON.parse(readFileSync(path, 'utf8'));
const hash = path => createHash('sha256').update(readFileSync(path)).digest('hex');
function run(command, args, cwd) {
  const result = spawnSync(command, args, { cwd, encoding: 'utf8', windowsHide: true, timeout: 120000 });
  if (result.status !== 0) throw new Error(`${command}: ${result.error?.message ?? result.stderr}`);
  return result.stdout.trim();
}
export function requireRelease(release, head, tree) {
  if (release.status !== 'passed' || release.commitSha !== head || release.treeSha !== tree ||
      release.cleanWorktree !== true || !release.skipped ||
      ['install', 'julia', 'smokes', 'browser', 'controlDocs'].some(key => release.skipped[key] !== false) ||
      Object.values(release.skipped).some(x => x !== false) ||
      !Array.isArray(release.results) || release.results.length !== phases.length ||
      phases.some((name, i) => release.results[i]?.name !== name || release.results[i]?.status !== 'passed' || release.results[i]?.exitCode !== 0)) {
    throw new Error('Full clean same-candidate release validation with every phase passed is required');
  }
}
// Called inside the verified isolated checkout, before its owned cleanup.
export function stagePackage(root, out, head, tree) {
  requireRelease(json(join(out, 'release-verification/latest/summary.json')), head, tree);
  if (run('git', ['rev-parse', 'HEAD'], root) !== head || run('git', ['status', '--porcelain'], root)) throw new Error('Package candidate drift');
  const version = json(join(root, 'package.json')).version;
  if (!/^[0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9.-]+)?$/.test(version)) throw new Error('Invalid package version');
  const delivery = join(out, 'delivery'); mkdirSync(delivery);
  const contents = join(delivery, 'contents'); mkdirSync(contents);
  const sourceTar = join(delivery, 'source.tar');
  run('git', ['archive', '--format=tar', `--output=${sourceTar}`, head], root);
  run('tar', ['-xf', sourceTar, '-C', contents], root);
  if (!existsSync(join(root, 'apps/frontend/dist/index.html'))) throw new Error('Built frontend missing');
  cpSync(join(root, 'apps/frontend/dist'), join(contents, 'apps/frontend/dist'), { recursive: true });
  // Resolved dependency metadata is local-only and never added to Git.
  cpSync(join(root, 'Manifest.toml'), join(contents, 'Manifest.toml'));
  writeJson(join(contents, 'local-release.json'), { version, head, tree, platform: process.platform,
    kind: 'source-and-built-web', offlineInstaller: false, runtimePrerequisites: ['Node 25', 'Julia 1.12', 'PostgreSQL 16'] });
  const name = `juliaflow-${version}-${head.slice(0, 12)}-${process.platform}.tar.gz`;
  run('tar', ['-czf', join(delivery, name), '-C', contents, '.'], root);
  const entries = run('tar', ['-tzf', join(delivery, name)], root).split(/\r?\n/);
  for (const required of ['./package.json', './Project.toml', './Manifest.toml', './apps/frontend/dist/index.html', './local-release.json']) {
    if (!entries.includes(required)) throw new Error(`Package missing ${required}`);
  }
  const metadata = { version, head, tree, name, sha256: hash(join(delivery, name)), kind: 'source-and-built-web' };
  writeJson(join(delivery, 'package.json'), metadata);
  return metadata;
}
function verifiedFile(root, path) {
  if (typeof path !== 'string' || isAbsolute(path) || path.split(/[\\/]/).includes('..')) throw new Error('Invalid evidence path');
  const file = join(root, path), rel = relative(root, realpathSync(file));
  if (rel.startsWith('..') || isAbsolute(rel) || !lstatSync(file).isFile() || lstatSync(file).isSymbolicLink()) throw new Error('Evidence path escapes or is not a regular file');
  return file;
}
export function promote(root, id) {
  if (!/^jfci-[0-9]+-[a-f0-9]{8}$/.test(id)) throw new Error('Invalid run id');
  const ciRoot = realpathSync(join(root, 'artifacts/local-ci'));
  const out = realpathSync(join(ciRoot, id));
  if (dirname(out) !== ciRoot || lstatSync(join(ciRoot, id)).isSymbolicLink()) throw new Error('Evidence directory escapes');
  const hashes = json(verifiedFile(out, 'sha256.json'));
  for (const [path, expected] of Object.entries(hashes)) if (hash(verifiedFile(out, path)) !== expected) throw new Error(`Evidence checksum mismatch: ${path}`);
  for (const path of ['summary.json', 'release-candidate/summary.json', 'release-candidate/release-verification/latest/summary.json', 'release-candidate/delivery/package.json']) {
    if (!hashes[path]) throw new Error(`Evidence manifest missing ${path}`);
  }
  const report = json(join(out, 'summary.json'));
  if (report.status !== 'passed' || report.completeProfile !== true || report.options?.profile !== 'release-candidate' ||
      report.cleanupStatus !== 'passed' || report.evidenceFinalization !== 'passed' || report.jobs.length !== 1 ||
      report.jobs[0].name !== 'release-candidate' || report.jobs[0].status !== 'passed' || report.jobs[0].cleanup?.status !== 'passed') throw new Error('Completed full release-candidate profile and cleanup required');
  const job = json(join(out, 'release-candidate/summary.json'));
  const requiredCommands = ['npm ci', 'npx playwright install --with-deps chromium', 'npm run verify:release'];
  if (job.status !== 'passed' || job.expectedHead !== report.head || job.expectedTree !== report.tree ||
      job.steps?.length !== requiredCommands.length || job.steps.some((s, i) => s.command !== requiredCommands[i] || s.status !== 'passed' || s.exitCode !== 0)) throw new Error('Incomplete release job');
  requireRelease(json(join(out, 'release-candidate/release-verification/latest/summary.json')), report.head, report.tree);
  const pack = json(join(out, 'release-candidate/delivery/package.json'));
  if (pack.head !== report.head || pack.tree !== report.tree || !/^juliaflow-[a-zA-Z0-9.-]+\.tar\.gz$/.test(pack.name)) throw new Error('Package identity mismatch');
  const packagePath = `release-candidate/delivery/${pack.name}`;
  if (!hashes[packagePath] || hash(verifiedFile(out, packagePath)) !== pack.sha256) throw new Error('Package checksum mismatch');
  const releases = join(root, 'artifacts/local-releases'); mkdirSync(releases, { recursive: true });
  const lock = join(releases, '.promotion.lock'); mkdirSync(lock);
  try {
    const destination = join(releases, pack.name.replace(/\.tar\.gz$/, ''));
    if (existsSync(destination)) throw new Error('Version already exists; refusing overwrite');
    const pending = join(releases, `.pending-${id}`); mkdirSync(pending);
    cpSync(join(out, packagePath), join(pending, pack.name));
    if (hash(join(pending, pack.name)) !== pack.sha256) throw new Error('Copied package checksum mismatch');
    const receipt = { ...pack, runId: id, promotedAt: new Date().toISOString(), localOnly: true, certifiesRelease: false };
    writeJson(join(pending, 'receipt.json'), receipt);
    cpSync(join(out, 'summary.json'), join(pending, 'ci-summary.json'));
    cpSync(join(out, 'release-candidate/release-verification/latest/summary.json'), join(pending, 'release-summary.json'));
    writeJson(join(pending, 'sha256.json'), inventory(pending));
    renameSync(pending, destination);
    writeJson(join(releases, 'current.json'), { ...receipt, directory: relative(releases, destination) });
    return destination;
  } finally { rmdirSync(lock); }
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    if (process.argv.length !== 4 || process.argv[2] !== '--run') throw new Error('Usage: npm run cd:local -- --run <successful-release-candidate-run-id>');
    console.log(`Promoted locally: ${promote(process.cwd(), process.argv[3])}`);
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
