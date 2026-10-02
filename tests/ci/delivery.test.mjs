import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { hostedEnabled } from '../../scripts/ci/hosted-policy.mjs';
import { requireRelease, promote, stagePackage } from '../../scripts/ci/delivery.mjs';
import { inventory, writeJson } from '../../scripts/ci/evidence.mjs';

const head = 'a'.repeat(40), tree = 'b'.repeat(40), id = 'jfci-12345678-abcdef12';
const temp = () => mkdtempSync(join(tmpdir(), 'juliaflow-delivery-test-'));
const phases = [...readFileSync('scripts/verify-release.mjs', 'utf8').matchAll(/kind: "[^"]+", name: "([^"]+)"/g)].map(m => m[1]);
function release() { return { status: 'passed', commitSha: head, treeSha: tree, cleanWorktree: true,
  skipped: { install: false, julia: false, smokes: false, browser: false, controlDocs: false },
  results: phases.map(name => ({ name, status: 'passed', exitCode: 0 })) }; }
function fixture() {
  const root = temp(), out = join(root, 'artifacts/local-ci', id), delivery = join(out, 'release-candidate/delivery');
  mkdirSync(delivery, { recursive: true });
  const name = 'juliaflow-0.1.0-aaaaaaaaaaaa-linux.tar.gz';
  // Synthetic package exercises promotion integrity, not product verification.
  writeFileSync(join(delivery, name), 'unit-test-package');
  writeJson(join(delivery, 'package.json'), { name, head, tree, version: '0.1.0', sha256: inventory(delivery)[name] });
  writeJson(join(out, 'release-candidate/release-verification/latest/summary.json'), release());
  writeJson(join(out, 'release-candidate/summary.json'), { status: 'passed', expectedHead: head, expectedTree: tree,
    steps: ['npm ci', 'npx playwright install --with-deps chromium', 'npm run verify:release'].map(command => ({ command, status: 'passed', exitCode: 0 })) });
  writeJson(join(out, 'summary.json'), { status: 'passed', head, tree, completeProfile: true, options: { profile: 'release-candidate' },
    cleanupStatus: 'passed', evidenceFinalization: 'passed', jobs: [{ name: 'release-candidate', status: 'passed', cleanup: { status: 'passed' } }] });
  writeJson(join(out, 'sha256.json'), inventory(out));
  return { root, out, delivery, name };
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
test('promotion copies validated version, persists receipt/current pointer and refuses overwrite', () => {
  const f = fixture(); const dest = promote(f.root, id);
  assert.equal(readFileSync(join(dest, f.name), 'utf8'), 'unit-test-package');
  const pointer = join(f.root, 'artifacts/local-releases/current.json');
  const before = readFileSync(pointer, 'utf8'); assert.equal(JSON.parse(before).head, head);
  assert.throws(() => promote(f.root, id), /already exists/);
  assert.equal(readFileSync(pointer, 'utf8'), before);
});
test('partial, failed, unfinalized and cleanup-failed runs never promote even with consistent hashes', () => {
  for (const change of [r => r.status = 'failed', r => r.completeProfile = false, r => r.cleanupStatus = 'failed',
    r => r.options.profile = 'pr', r => r.evidenceFinalization = 'failed']) {
    const f = fixture(), p = join(f.out, 'summary.json'), r = JSON.parse(readFileSync(p)); change(r); writeJson(p, r);
    writeJson(join(f.out, 'sha256.json'), inventory(f.out));
    assert.throws(() => promote(f.root, id)); assert.equal(existsSync(join(f.root, 'artifacts/local-releases/current.json')), false);
  }
});
test('tampered package, missing checksum and path escape fail without a current pointer', () => {
  for (const change of [f => writeFileSync(join(f.delivery, f.name), 'tampered'), f => writeJson(join(f.out, 'sha256.json'), {}),
    f => writeJson(join(f.out, 'sha256.json'), { '../outside': 'bad' })]) {
    const f = fixture(); change(f); assert.throws(() => promote(f.root, id));
    assert.equal(existsSync(join(f.root, 'artifacts/local-releases/current.json')), false);
  }
});
test('package archive round-trips committed source, built web and dependency metadata', () => {
  const root = temp(), out = temp(), unpacked = temp();
  const run = (cmd, args) => {
    const result = spawnSync(cmd, args, { cwd: root, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr); return result.stdout.trim();
  };
  run('git', ['init']);
  writeJson(join(root, 'package.json'), { name: 'synthetic-package-probe', version: '0.1.0' });
  writeFileSync(join(root, 'Project.toml'), '[deps]\n');
  writeFileSync(join(root, '.gitignore'), 'apps/frontend/dist/\nManifest.toml\n');
  run('git', ['add', '.']);
  run('git', ['-c', 'user.name=Local CI Probe', '-c', 'user.email=probe@localhost', 'commit', '-m', 'probe']);
  const candidate = run('git', ['rev-parse', 'HEAD']), candidateTree = run('git', ['rev-parse', 'HEAD^{tree}']);
  mkdirSync(join(root, 'apps/frontend/dist'), { recursive: true });
  writeFileSync(join(root, 'apps/frontend/dist/index.html'), '<h1>Archive probe</h1>');
  writeFileSync(join(root, 'Manifest.toml'), '# synthetic probe only\n');
  writeJson(join(out, 'release-verification/latest/summary.json'), { ...release(), commitSha: candidate, treeSha: candidateTree });
  const pack = stagePackage(root, out, candidate, candidateTree);
  run('tar', ['-xzf', join(out, 'delivery', pack.name), '-C', unpacked]);
  assert.equal(readFileSync(join(unpacked, 'apps/frontend/dist/index.html'), 'utf8'), '<h1>Archive probe</h1>');
  assert.equal(JSON.parse(readFileSync(join(unpacked, 'local-release.json'))).head, candidate);
  assert.equal(readFileSync(join(unpacked, 'Manifest.toml'), 'utf8'), '# synthetic probe only\n');
});
