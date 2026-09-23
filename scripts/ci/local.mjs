import { spawnSync } from 'node:child_process';
import { randomBytes, createHash } from 'node:crypto';
import { mkdirSync, readFileSync, existsSync, appendFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { verifyParity } from './parity.mjs';
import { runProcess } from './process.mjs';
import { writeJson, inventory } from './evidence.mjs';
import { waitForService, removeOwnedResource } from './resources.mjs';

export function parseArgs(argv) {
  const options = { profile: 'pr', cache: 'cold' };
  for (let i = 0; i < argv.length; i += 2) {
    const key = argv[i]?.replace(/^--/, '');
    if (!['ref', 'base', 'profile', 'job', 'cache'].includes(key) || !argv[i + 1] || argv[i + 1].startsWith('--')) throw new Error(`Invalid option ${argv[i]}`);
    options[key] = argv[i + 1];
  }
  if (!options.ref || !options.base || !['pr', 'push', 'release-candidate'].includes(options.profile) || !['cold', 'warm'].includes(options.cache)) throw new Error('Usage: ci:local --ref <commit> --base <commit> --profile pr|push|release-candidate [--job name] [--cache cold|warm]');
  return options;
}
function command(name, args, cwd, timeout = 30000) {
  const r = spawnSync(name, args, { cwd, encoding: 'utf8', windowsHide: true, timeout, maxBuffer: 16 * 1024 * 1024 });
  if (r.status !== 0) throw new Error(`${name} failed: ${r.error?.message ?? r.stderr ?? r.status}`);
  return r.stdout.trim();
}
export async function main(argv) {
  const options = parseArgs(argv), root = process.cwd(), manifest = verifyParity(root);
  const profileJobs = manifest.profiles[options.profile];
  if (options.job && !profileJobs.includes(options.job)) throw new Error('Job is not part of this profile');
  const head = command('git', ['rev-parse', '--verify', `${options.ref}^{commit}`], root);
  const base = command('git', ['rev-parse', '--verify', `${options.base}^{commit}`], root);
  const tree = command('git', ['rev-parse', `${head}^{tree}`], root);
  if (!/^[a-f0-9]{40}$/.test(head) || !/^[a-f0-9]{40}$/.test(base)) throw new Error('Invalid commit');
  const id = `jfci-${Date.now()}-${randomBytes(4).toString('hex')}`;
  const out = join(root, 'artifacts', 'local-ci', id); mkdirSync(out, { recursive: true });
  const report = { id, head, tree, base, options, completeProfile: !options.job, status: 'running',
    certifiesRelease: false,
    jobs: profileJobs.map(name => ({ name, status: options.job && options.job !== name ? 'skipped' : 'not_run' })), resources: [], startedAt: new Date().toISOString() };
  const save = () => writeJson(join(out, 'summary.json'), report);
  const events = event => appendFileSync(join(out, 'events.jsonl'), JSON.stringify({ at: new Date().toISOString(), ...event }) + '\n');
  const abort = new AbortController();
  const cancel = () => abort.abort();
  process.on('SIGINT', cancel); process.on('SIGTERM', cancel);
  const docker = args => command('docker', args, root);
  async function runDocker(args, name, timeoutMs) {
    const result = await runProcess('docker', args, { cwd: root, logPath: join(out, `${name}.log`), timeoutMs, signal: abort.signal, onEvent: events });
    if (result.status !== 'passed') throw Object.assign(new Error(`${name}: ${result.status}`), { status: result.status });
  }
  function own(kind, name) { report.resources.push({ kind, name }); save(); return name; }
  save();
  try {
    // The selected candidate supplies both the tests and the runner/image mapping.
    for (const path of ['infra/docker/ci/Dockerfile', 'scripts/ci/workflows.json', 'scripts/ci/local.mjs']) {
      const selected = command('git', ['show', `${head}:${path}`], root).replaceAll('\r\n', '\n');
      if (selected !== readFileSync(join(root, path), 'utf8').replaceAll('\r\n', '\n').trim()) throw new Error(`Runner differs from selected candidate: ${path}; commit changes and select that commit`);
    }
    report.phase = 'docker-preflight'; save();
    report.docker = JSON.parse(docker(['version', '--format', '{{json .Server}}']));
    report.compose = docker(['compose', 'version', '--short']); save();
    report.phase = 'prepare-image'; save();
    // Export committed history only. User worktrees and untracked files are never mounted.
    const bundle = join(out, 'source.bundle');
    command('git', ['bundle', 'create', bundle, '--all'], root, 120000);
    const imageKey = createHash('sha256').update(readFileSync(join(root, 'infra/docker/ci/Dockerfile'))).update(JSON.stringify(manifest.images)).digest('hex').slice(0, 16);
    const image = `juliaflow-local-ci:${imageKey}`;
    await runDocker(['build', '--label', 'org.juliaflow.local-ci=true', '-t', image,
      ...['ubuntu', 'node', 'julia'].flatMap(k => ['--build-arg', `${k.toUpperCase()}_IMAGE=${manifest.images[k]}`]),
      '-f', 'infra/docker/ci/Dockerfile', 'infra/docker/ci'], 'image-build', 30 * 60000);
    report.image = JSON.parse(docker(['image', 'inspect', image, '--format', '{{json .}}'])).Id; save();
    for (const entry of report.jobs) {
      if (entry.status === 'skipped') continue;
      if (abort.signal.aborted) { report.status = 'cancelled'; break; }
      const jobId = `${id}-${entry.name}`, jobOut = join(out, entry.name); mkdirSync(jobOut, { recursive: true });
      entry.status = 'running'; entry.startedAt = new Date().toISOString(); save();
      report.phase = entry.name; save();
      const deadline = Date.now() + manifest.jobs[entry.name].timeoutMinutes * 60000;
      const network = own('network', `${jobId}-net`);
      docker(['network', 'create', '--label', `org.juliaflow.ci.run=${id}`, network]);
      const pg = own('container', `${jobId}-postgres`), password = randomBytes(24).toString('hex');
      // No published host ports: unrelated PostgreSQL instances cannot collide.
      docker(['run', '-d', '--name', pg, '--label', `org.juliaflow.ci.run=${id}`, '--network', network, '--network-alias', 'postgres',
        '-e', 'POSTGRES_DB=juliaflow', '-e', 'POSTGRES_USER=juliaflow', '-e', `POSTGRES_PASSWORD=${password}`, manifest.images.postgres]);
      await waitForService(() => {
        try { command('docker', ['exec', pg, 'pg_isready', '-U', 'juliaflow', '-d', 'juliaflow'], root, 3000); return true; } catch { return false; }
      }, { signal: abort.signal });
      const dependencyKey = createHash('sha256').update(command('git', ['show', `${head}:package-lock.json`], root)).update(command('git', ['show', `${head}:Project.toml`], root)).digest('hex').slice(0, 12);
      const cacheKey = options.cache === 'cold' ? jobId : `jfci-warm-${imageKey}-${dependencyKey}-${entry.name}`;
      if (options.cache === 'warm') {
        // Reserving this name serializes cache writers. Never remove another run's lock.
        const lock = own('container', `${cacheKey}-lock`);
        docker(['create', '--name', lock, '--label', `org.juliaflow.ci.run=${id}`, image, 'true']);
      }
      const mounts = [];
      for (const tool of ['npm', 'julia']) {
        const volume = `${cacheKey}-${tool}`;
        if (options.cache === 'cold') own('volume', volume);
        docker(['volume', 'create', '--label', options.cache === 'cold' ? `org.juliaflow.ci.run=${id}` : 'org.juliaflow.ci.cache=warm', volume]);
        mounts.push('--mount', `type=volume,source=${volume},target=/cache/${tool}`);
      }
      const runner = own('container', `${jobId}-runner`);
      const url = `postgresql://juliaflow:${password}@postgres:5432/juliaflow`;
      const args = ['create', '--init', '--name', runner, '--label', `org.juliaflow.ci.run=${id}`, '--network', network,
        '--mount', `type=bind,source=${bundle},target=/input/source.bundle,readonly`, '--mount', `type=bind,source=${jobOut},target=/evidence`, ...mounts,
        '-e', `JULIAFLOW_CONTROL_DOC_BASE=${base}`, '-e', 'JULIAFLOW_CI_EXTERNAL_POSTGRES=1', '-e', `JULIAFLOW_DATABASE_URL=${url}`,
        '-e', `JULIAFLOW_TEST_POSTGRES_URL=${url}`, '-e', 'JULIAFLOW_JULIA_CMD=julia',
        '-e', `JULIAFLOW_TEST_POSTGRES_SCHEMA=juliaflow_ci_${id.slice(-8)}_${entry.name.replaceAll('-', '_')}`,
        '-e', `JULIAFLOW_CI_DEADLINE=${deadline}`,
        image, 'bash', '-euc', `git clone /input/source.bundle /workspace/repo; cd /workspace/repo; git checkout --detach ${head}; node scripts/ci/job.mjs ${entry.name} ${head} ${tree}`];
      docker(args);
      const result = await runProcess('docker', ['start', '-a', runner], { cwd: root, env: { ...process.env, JULIAFLOW_DATABASE_URL: url, POSTGRES_PASSWORD: password },
        logPath: join(jobOut, 'container.log'), signal: abort.signal, timeoutMs: Math.max(1, deadline - Date.now()), onEvent: events });
      if (result.status !== 'passed') { try { docker(['stop', '--time', '10', runner]); } catch { /* finally removes owned container */ } }
      const summaryPath = join(jobOut, 'summary.json');
      entry.result = existsSync(summaryPath) ? JSON.parse(readFileSync(summaryPath, 'utf8')) : null;
      entry.status = result.status === 'passed' ? entry.result?.status ?? 'failed' : result.status;
      save();
    }
    if (report.status === 'running') report.status = report.jobs.some(j => ['failed', 'timed_out', 'cancelled', 'not_run', 'running'].includes(j.status)) ? 'failed' : options.job ? 'partial' : 'passed';
  } catch (error) { report.status = abort.signal.aborted ? 'cancelled' : error.status ?? 'failed'; report.error = error.message; }
  finally {
    // Evidence is already bind-mounted on the host before any resource is removed.
    report.cleanup = [];
    for (const resource of [...report.resources].reverse()) {
      try {
        removeOwnedResource(docker, resource, id);
        report.cleanup.push({ ...resource, status: 'passed' });
      } catch (error) { report.cleanup.push({ ...resource, status: 'failed', error: error.message }); }
    }
    if (report.cleanup.some(r => r.status === 'failed') && report.status === 'passed') report.status = 'failed';
    report.finishedAt = new Date().toISOString(); save(); writeJson(join(out, 'sha256.json'), inventory(out));
    process.removeListener('SIGINT', cancel); process.removeListener('SIGTERM', cancel);
    console.log(`Local CI ${report.status}. Evidence: ${out}`);
  }
  return report.status === 'passed' || report.status === 'partial' ? 0 : 1;
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).then(code => { process.exitCode = code; }).catch(error => { console.error(error.message); process.exitCode = 1; });
}
