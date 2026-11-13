// Build the local release package after a passing `npm run verify:release`.
// The release-candidate workflow uploads artifacts/release-package as the
// `juliaflow-release-package` artifact; `easyci promote` copies it into a
// release folder with a receipt. Run it only in a clean checkout of the candidate.
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// Every phase of scripts/verify-release.mjs, in order. A test keeps this list in step with that file.
export const phases = ['npm-install', 'doctor-host', 'julia-instantiate', 'validate-contracts', 'build', 'test',
  'julia-repo-tests', 'julia-base-extension-tests', 'smoke-local-bootstrap', 'smoke-local-data-estate',
  'smoke-local-metadata', 'smoke-local-hardware', 'smoke-local-explainability', 'smoke-local-offline-hub',
  'smoke-local-reproducibility', 'smoke-local-migration', 'smoke-live-backend-browser', 'smoke-create-project', 'smoke-durable-analysis',
  'git-diff-check'];
const required = ['./package.json', './Project.toml', './Manifest.toml', './apps/frontend/dist/index.html', './local-release.json'];

const json = path => JSON.parse(readFileSync(path, 'utf8'));
const writeJson = (path, value) => writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`);
const hash = path => createHash('sha256').update(readFileSync(path)).digest('hex');
function run(command, args, cwd) {
  const result = spawnSync(command, args, { cwd, encoding: 'utf8', windowsHide: true, timeout: 120000 });
  if (result.status !== 0) throw new Error(`${command}: ${result.error?.message ?? result.stderr}`);
  return result.stdout.trim();
}

export function requireRelease(release, head, tree) {
  if (release.status !== 'passed' || release.commitSha !== head || release.treeSha !== tree ||
      release.cleanWorktree !== true || !release.skipped ||
      ['install', 'julia', 'smokes', 'browser'].some(key => release.skipped[key] !== false) ||
      Object.values(release.skipped).some(x => x !== false) ||
      !Array.isArray(release.results) || release.results.length !== phases.length ||
      phases.some((name, i) => release.results[i]?.name !== name || release.results[i]?.status !== 'passed' || release.results[i]?.exitCode !== 0)) {
    throw new Error('Full clean same-candidate release validation with every phase passed is required');
  }
}

export function buildPackage(root, out = join(root, 'artifacts/release-package')) {
  const head = run('git', ['rev-parse', 'HEAD'], root), tree = run('git', ['rev-parse', 'HEAD^{tree}'], root);
  const summary = join(root, 'artifacts/release-verification/latest/summary.json');
  if (!existsSync(summary)) throw new Error('Release verification summary missing; run npm run verify:release first');
  requireRelease(json(summary), head, tree);
  if (run('git', ['status', '--porcelain'], root)) throw new Error('Package candidate drift: the worktree is not clean');
  const version = json(join(root, 'package.json')).version;
  if (!/^[0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9.-]+)?$/.test(version)) throw new Error('Invalid package version');
  if (!existsSync(join(root, 'apps/frontend/dist/index.html'))) throw new Error('Built frontend missing');
  // Resolved dependency metadata is local-only and never added to Git.
  if (!existsSync(join(root, 'Manifest.toml'))) throw new Error('Resolved Manifest.toml missing');
  if (existsSync(out)) throw new Error(`Package output already exists; refusing to overwrite ${out}`);

  const staging = mkdtempSync(join(tmpdir(), 'juliaflow-package-'));
  try {
    const contents = join(staging, 'contents'), sourceTar = join(staging, 'source.tar');
    mkdirSync(contents);
    run('git', ['archive', '--format=tar', `--output=${sourceTar}`, head], root);
    run('tar', ['-xf', sourceTar, '-C', contents], root);
    cpSync(join(root, 'apps/frontend/dist'), join(contents, 'apps/frontend/dist'), { recursive: true });
    cpSync(join(root, 'Manifest.toml'), join(contents, 'Manifest.toml'));
    writeJson(join(contents, 'local-release.json'), { version, head, tree, platform: process.platform,
      kind: 'source-and-built-web', offlineInstaller: false, runtimePrerequisites: ['Node 25', 'Julia 1.12', 'PostgreSQL 16'] });
    const name = `juliaflow-${version}-${head.slice(0, 12)}-${process.platform}.tar.gz`;
    const archive = join(staging, name);
    run('tar', ['-czf', archive, '-C', contents, '.'], root);
    const entries = run('tar', ['-tzf', archive], root).split(/\r?\n/);
    for (const entry of required) if (!entries.includes(entry)) throw new Error(`Package missing ${entry}`);
    mkdirSync(out, { recursive: true });
    cpSync(archive, join(out, name));
    const metadata = { version, head, tree, name, sha256: hash(join(out, name)), kind: 'source-and-built-web' };
    if (metadata.sha256 !== hash(archive)) throw new Error('Copied package checksum mismatch');
    writeJson(join(out, 'package.json'), metadata);
    return metadata;
  } finally {
    rmSync(staging, { recursive: true, force: true });
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const pack = buildPackage(process.cwd());
    console.log(`Release package ${pack.name} (sha256 ${pack.sha256}) written to artifacts/release-package`);
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
