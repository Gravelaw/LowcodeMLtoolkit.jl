import { spawnSync } from 'node:child_process';
import { randomBytes, createHash } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync, existsSync, appendFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from './local.mjs';
import { verifyParity } from './parity.mjs';
import { runProcess } from './process.mjs';
import { writeJson, inventory } from './evidence.mjs';

const distro = 'juliaflow-ci-ubuntu24';
function command(name, args, cwd, timeout = 30000) {
  const result = spawnSync(name, args, { cwd, encoding: 'utf8', windowsHide: true, timeout, maxBuffer: 16 * 1024 * 1024 });
  if (result.status !== 0) throw new Error(`${name} failed: ${result.error?.message ?? result.stderr ?? result.status}`);
  return result.stdout.trim();
}
function wsl(args, cwd, timeout) { return command('wsl', ['-d', distro, '-u', 'root', '--exec', ...args], cwd, timeout); }
function wslPath(path, cwd) {
  const converted = wsl(['wslpath', '-u', path], cwd);
  if (!/^\/mnt\/[a-z]\//.test(converted)) throw new Error('Evidence and source bundle must be on a WSL-mounted Windows drive');
  return converted;
}
export async function main(argv) {
  const options = parseArgs(argv), root = process.cwd(), mapping = verifyParity(root);
  const names = mapping.profiles[options.profile];
  if (options.job && !names.includes(options.job)) throw new Error('Job is not part of this profile');
  const head = command('git', ['rev-parse', '--verify', `${options.ref}^{commit}`], root);
  const base = command('git', ['rev-parse', '--verify', `${options.base}^{commit}`], root);
  const tree = command('git', ['rev-parse', `${head}^{tree}`], root);
  const id = `jfci-${Date.now()}-${randomBytes(4).toString('hex')}`;
  const out = join(root, 'artifacts', 'local-ci', id); mkdirSync(out, { recursive: true });
  const report = { id, backend: 'wsl', distro, head, tree, base, options, completeProfile: !options.job,
    certifiesRelease: false, status: 'running', startedAt: new Date().toISOString(),
    jobs: names.map(name => ({ name, status: options.job && options.job !== name ? 'skipped' : 'not_run' })) };
  const save = () => writeJson(join(out, 'summary.json'), report);
  const events = event => appendFileSync(join(out, 'events.jsonl'), JSON.stringify({ at: new Date().toISOString(), ...event }) + '\n');
  const abort = new AbortController();
  const cancel = () => abort.abort();
  process.on('SIGINT', cancel); process.on('SIGTERM', cancel);
  save();
  try {
    for (const path of ['scripts/ci/workflows.json', 'scripts/ci/wsl.mjs', 'scripts/ci/wsl-job.sh', 'scripts/ci/job.mjs']) {
      const selected = command('git', ['show', `${head}:${path}`], root).replaceAll('\r\n', '\n');
      if (selected !== readFileSync(join(root, path), 'utf8').replaceAll('\r\n', '\n').trim()) throw new Error(`Runner differs from selected candidate: ${path}; commit changes and select that commit`);
    }
    report.phase = 'wsl-preflight'; save();
    const os = wsl(['bash', '-euc', '. /etc/os-release; printf "%s" "$VERSION_ID"'], root);
    if (os !== '24.04') throw new Error(`Expected Ubuntu 24.04; found ${os}`);
    report.runtime = Object.fromEntries(['node', 'npm', 'julia', 'pg_config'].map(tool => [tool, wsl([tool, '--version'], root)]));
    if (report.runtime.node !== 'v25.9.0' || !report.runtime.julia.includes('1.12.7') || !report.runtime.pg_config.includes('16.')) throw new Error('Dedicated WSL runtime versions do not match the CI baseline');
    report.packagesSha256 = wsl(['sha256sum', '/opt/juliaflow-ci/packages.txt'], root).split(' ')[0];
    report.ubuntuImageSha256 = 'bb415d824822c4b878125729af451a5d18fb13d1cf5cbed9a7393ad64ac6039e';
    report.phase = 'prepare-source'; save();
    const bundle = join(out, 'source.bundle');
    command('git', ['bundle', 'create', bundle, '--all'], root, 120000);
    const script = join(out, 'wsl-job.sh');
    writeFileSync(script, command('git', ['show', `${head}:scripts/ci/wsl-job.sh`], root).replaceAll('\r\n', '\n') + '\n');
    const bundlePath = wslPath(bundle, root), scriptPath = wslPath(script, root);
    const dependencyKey = createHash('sha256').update(command('git', ['show', `${head}:package-lock.json`], root)).update(command('git', ['show', `${head}:Project.toml`], root)).digest('hex').slice(0, 16);
    for (const entry of report.jobs) {
      if (entry.status === 'skipped') continue;
      if (abort.signal.aborted) { report.status = 'cancelled'; break; }
      const jobOut = join(out, entry.name); mkdirSync(jobOut, { recursive: true });
      const evidence = wslPath(jobOut, root);
      const deadline = Date.now() + mapping.jobs[entry.name].timeoutMinutes * 60000;
      const port = 30000 + (randomBytes(2).readUInt16BE() % 20000);
      const cacheKey = createHash('sha256').update(`${dependencyKey}:${entry.name}:${report.packagesSha256}`).digest('hex').slice(0, 16);
      entry.startedAt = new Date().toISOString(); entry.status = 'running'; report.phase = entry.name; save();
      const args = ['-d', distro, '-u', 'root', '--exec', 'env', `JULIAFLOW_CI_DEADLINE=${deadline}`,
        'setsid', '--wait', 'bash', scriptPath, 'run', id, entry.name, head, tree, base, bundlePath, evidence, options.cache, cacheKey, String(port)];
      const result = await runProcess('wsl', args, { cwd: root, logPath: join(jobOut, 'wsl.log'),
        timeoutMs: Math.max(1, deadline - Date.now()), signal: abort.signal, onEvent: events });
      if (result.status !== 'passed') {
        const pidFile = join(jobOut, 'wsl-pid');
        if (existsSync(pidFile)) {
          const pid = readFileSync(pidFile, 'utf8').trim();
          if (/^[1-9][0-9]*$/.test(pid)) {
            try { wsl(['bash', '-c', 'kill -TERM -- -"$1" 2>/dev/null || true; sleep 2; kill -KILL -- -"$1" 2>/dev/null || true', '_', pid], root, 10000); }
            catch (error) { entry.cleanupError = error.message; }
          }
        }
      }
      try { wsl(['bash', scriptPath, 'cleanup', id, entry.name, evidence], root, 30000); }
      catch (error) { entry.cleanupError = error.message; }
      const summaryPath = join(jobOut, 'summary.json');
      entry.result = existsSync(summaryPath) ? JSON.parse(readFileSync(summaryPath, 'utf8')) : null;
      entry.status = result.status === 'passed' ? entry.result?.status ?? 'failed' : result.status;
      if (entry.cleanupError) entry.status = 'failed';
      entry.finishedAt = new Date().toISOString(); save();
    }
    if (report.status === 'running') report.status = report.jobs.some(j => ['failed', 'timed_out', 'cancelled', 'not_run', 'running'].includes(j.status)) ? 'failed' : options.job ? 'partial' : 'passed';
  } catch (error) { report.status = abort.signal.aborted ? 'cancelled' : 'failed'; report.error = error.message; }
  finally {
    report.finishedAt = new Date().toISOString(); save(); writeJson(join(out, 'sha256.json'), inventory(out));
    process.removeListener('SIGINT', cancel); process.removeListener('SIGTERM', cancel);
    console.log(`Local WSL CI ${report.status}. Evidence: ${out}`);
  }
  return report.status === 'passed' || report.status === 'partial' ? 0 : 1;
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).then(code => { process.exitCode = code; }).catch(error => { console.error(error.message); process.exitCode = 1; });
}
