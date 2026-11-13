import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { hostedEnabled } from '../../scripts/ci/hosted-policy.mjs';
import { buildPackage, phases, requireRelease } from '../../scripts/package-release.mjs';

const head = 'a'.repeat(40), tree = 'b'.repeat(40);
const temp = () => mkdtempSync(join(tmpdir(), 'juliaflow-package-test-'));
const writeJson = (path, value) => { mkdirSync(join(path, '..'), { recursive: true }); writeFileSync(path, JSON.stringify(value)); };
function release(commitSha = head, treeSha = tree) {
  return { status: 'passed', commitSha, treeSha, cleanWorktree: true,
    skipped: { install: false, julia: false, smokes: false, browser: false },
    results: phases.map(name => ({ name, status: 'passed', exitCode: 0 })) };
}
// A committed probe repository with the ignored build outputs a release run leaves behind.
function candidate() {
  const root = temp();
  const run = (cmd, args) => {
    const result = spawnSync(cmd, args, { cwd: root, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr); return result.stdout.trim();
  };
  run('git', ['init']);
  writeJson(join(root, 'package.json'), { name: 'synthetic-package-probe', version: '0.1.0' });
  writeFileSync(join(root, 'Project.toml'), '[deps]\n');
  writeFileSync(join(root, '.gitignore'), 'apps/frontend/dist/\nManifest.toml\nartifacts/\n');
  run('git', ['add', '.']);
  run('git', ['-c', 'user.name=Local CI Probe', '-c', 'user.email=probe@localhost', 'commit', '-m', 'probe']);
  const sha = run('git', ['rev-parse', 'HEAD']), treeSha = run('git', ['rev-parse', 'HEAD^{tree}']);
  mkdirSync(join(root, 'apps/frontend/dist'), { recursive: true });
  writeFileSync(join(root, 'apps/frontend/dist/index.html'), '<h1>Archive probe</h1>');
  writeFileSync(join(root, 'Manifest.toml'), '# synthetic probe only\n');
  writeJson(join(root, 'artifacts/release-verification/latest/summary.json'), release(sha, treeSha));
  return { root, sha, treeSha, run };
}

test('hosted policy selects local/hosted and rejects malformed mode without silent skipping', () => {
  assert.equal(hostedEnabled({ version: 1, mode: 'local' }), false);
  assert.equal(hostedEnabled({ version: 1, mode: 'hosted' }), true);
  assert.throws(() => hostedEnabled({ version: 1, mode: 'typo' }));
  assert.throws(() => hostedEnabled({ mode: 'local' }));
  const path = join(temp(), 'output');
  const p = spawnSync(process.execPath, ['scripts/ci/hosted-policy.mjs'], { env: { ...process.env, GITHUB_OUTPUT: path }, encoding: 'utf8' });
  assert.equal(p.status, 0); assert.equal(readFileSync(path, 'utf8'), 'enabled=false\n');
  for (const file of ['ci.yml', 'release-candidate.yml']) {
    const source = readFileSync(`.github/workflows/${file}`, 'utf8').replaceAll('\r\n', '\n');
    for (const name of file === 'ci.yml' ? ['web', 'julia', 'debian-release-gate'] : ['debian-release-gate']) {
      assert.ok(source.includes(`  ${name}:\n    needs: execution-policy\n    if: needs.execution-policy.outputs.enabled == 'true'`));
    }
  }
});

test('package phase list matches every verify:release phase in order', () => {
  const declared = [...readFileSync('scripts/verify-release.mjs', 'utf8').matchAll(/kind: "[^"]+", name: "([^"]+)"/g)].map(m => m[1]);
  assert.ok(declared.length > 0);
  assert.deepEqual(phases, declared);
});

test('release workflow packages after verify:release and uploads the package for promotion', () => {
  const source = readFileSync('.github/workflows/release-candidate.yml', 'utf8').replaceAll('\r\n', '\n');
  assert.ok(source.includes('      - run: npm run verify:release\n      - run: npm run package:release\n'));
  assert.ok(source.includes('          name: juliaflow-release-package\n          path: artifacts/release-package\n          if-no-files-found: error\n'));
});

test('full release gate rejects each missing, skipped or failed phase and different candidate', () => {
  requireRelease(release(), head, tree);
  for (let i = 0; i < phases.length; i++) {
    for (const status of ['failed', 'skipped', 'not_run', 'running']) {
      const r = release(); r.results[i].status = status; assert.throws(() => requireRelease(r, head, tree));
    }
  }
  for (const alter of [r => r.results.pop(), r => r.skipped.browser = true, r => r.cleanWorktree = false, r => r.commitSha = tree]) {
    const r = release(); alter(r); assert.throws(() => requireRelease(r, head, tree));
  }
});

test('package archive round-trips committed source, built web and dependency metadata', () => {
  const c = candidate(), unpacked = temp();
  const pack = buildPackage(c.root);
  const out = join(c.root, 'artifacts/release-package');
  assert.equal(pack.head, c.sha); assert.equal(pack.tree, c.treeSha);
  assert.deepEqual(JSON.parse(readFileSync(join(out, 'package.json'))), pack);
  c.run('tar', ['-xzf', join(out, pack.name), '-C', unpacked]);
  assert.equal(readFileSync(join(unpacked, 'apps/frontend/dist/index.html'), 'utf8'), '<h1>Archive probe</h1>');
  assert.equal(JSON.parse(readFileSync(join(unpacked, 'local-release.json'))).head, c.sha);
  assert.equal(readFileSync(join(unpacked, 'Manifest.toml'), 'utf8'), '# synthetic probe only\n');
  assert.throws(() => buildPackage(c.root), /already exists/);
});

test('failed, missing or other-candidate verification, dirty worktree and missing outputs write no package', () => {
  const changes = [
    c => writeJson(join(c.root, 'artifacts/release-verification/latest/summary.json'), { ...release(c.sha, c.treeSha), status: 'failed' }),
    c => writeJson(join(c.root, 'artifacts/release-verification/latest/summary.json'), release(head, c.treeSha)),
    c => writeFileSync(join(c.root, 'artifacts/release-verification/latest/summary.json'), ''),
    c => writeFileSync(join(c.root, 'untracked.txt'), 'drift'),
  ];
  for (const change of changes) {
    const c = candidate(); change(c);
    assert.throws(() => buildPackage(c.root));
    assert.equal(existsSync(join(c.root, 'artifacts/release-package')), false);
  }
  for (const missing of ['Manifest.toml', 'apps/frontend/dist/index.html', 'artifacts/release-verification/latest/summary.json']) {
    const c = candidate(); spawnSync(process.execPath, ['-e', `require('fs').rmSync(${JSON.stringify(join(c.root, missing))})`]);
    assert.throws(() => buildPackage(c.root), /missing/);
    assert.equal(existsSync(join(c.root, 'artifacts/release-package')), false);
  }
});
