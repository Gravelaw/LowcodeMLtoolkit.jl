import { spawn, spawnSync } from 'node:child_process';
import { appendFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { captureStartupOutput, redactStartup } from '../lib/startup-diagnostics.mjs';

// Stream complete, redacted lines; never buffer an entire compiler/test phase.
export function runProcess(command, args, { cwd = process.cwd(), env = process.env, logPath,
  timeoutMs = 0, signal, onEvent = () => {}, echo = true, graceMs = 3000, terminate } = {}) {
  return new Promise(resolve => {
    const started = Date.now();
    let reason, error, timer, escalation, pipeDeadline, cleanupIncomplete = false, closed = false;
    if (logPath) mkdirSync(dirname(logPath), { recursive: true });
    const write = text => { if (logPath) appendFileSync(logPath, text); if (echo) process.stdout.write(text); };
    const redact = text => redactStartup(text, env);
    if (signal?.aborted) return resolve({ status: 'cancelled', exitCode: null, durationMs: 0 });
    const child = spawn(command, args, { cwd, env, windowsHide: true, detached: process.platform !== 'win32',
      shell: process.platform === 'win32' && /(?:\.cmd|^npm|^npx)$/.test(command), stdio: ['ignore', 'pipe', 'pipe'] });
    function kill(force) {
      if (!child.pid) return;
      try {
        if (terminate) terminate(child.pid, force);
        else if (process.platform === 'win32') {
          const result = spawnSync('taskkill.exe', ['/pid', String(child.pid), '/T', '/F'], { windowsHide: true, timeout: 5000, stdio: 'ignore' });
          if (result.status !== 0) write(redact(`cleanup: taskkill failed (status=${result.status}): ${result.error?.message ?? 'termination unverified'}\n`));
        }
        else process.kill(-child.pid, force ? 'SIGKILL' : 'SIGTERM');
      } catch (e) { if (e.code !== 'ESRCH') write(redact(`cleanup: ${e.message}\n`)); }
    }
    function stop(status) {
      if (closed || reason) return;
      reason = status;
      onEvent({ event: status, pid: child.pid });
      kill(false);
      escalation = setTimeout(() => kill(true), graceMs);
      boundPipes();
    }
    function boundPipes() {
      pipeDeadline ??= setTimeout(() => {
        if (closed) return;
        cleanupIncomplete = true;
        reason ??= 'failed';
        write('Process pipes remained open after cleanup; descendant cleanup is unverified.\n');
        child.stdout.destroy(); child.stderr.destroy();
        child.unref();
        finish(null, null);
      }, graceMs + 1000);
    }
    const abort = () => stop('cancelled');
    signal?.addEventListener('abort', abort, { once: true });
    child.once('spawn', () => onEvent({ event: 'spawn', pid: child.pid }));
    child.once('error', e => { error = redact(e.message); write(`${error}\n`); });
    captureStartupOutput(child.stdout, write, redact);
    captureStartupOutput(child.stderr, write, redact);
    child.once('exit', (code, sig) => {
      if (closed) return;
      clearTimeout(timer);
      onEvent({ event: 'exit', pid: child.pid, code, signal: sig });
      // A descendant retaining stdio must not keep a completed command alive.
      if (process.platform !== 'win32') { kill(false); escalation ??= setTimeout(() => kill(true), graceMs); }
      else if (child.pid) {
        const cleanup = spawnSync(`${process.env.SystemRoot}/System32/WindowsPowerShell/v1.0/powershell.exe`,
          ['-NoProfile', '-NonInteractive', '-File', fileURLToPath(new URL('./stop-windows-descendants.ps1', import.meta.url)),
            '-ParentId', String(child.pid), '-StartedMs', String(started), '-ExitedMs', String(Date.now())],
          { windowsHide: true, timeout: 5000, encoding: 'utf8' });
        if (cleanup.status !== 0) { cleanupIncomplete = true; reason ??= 'failed'; write(redact(`Descendant cleanup failed: ${cleanup.error?.message ?? cleanup.stderr}\n`)); }
      }
      boundPipes();
    });
    function finish(code, sig) {
      if (closed) return;
      if (process.platform !== 'win32') kill(true);
      closed = true; clearTimeout(timer); clearTimeout(escalation); clearTimeout(pipeDeadline); signal?.removeEventListener('abort', abort);
      const result = { status: reason ?? (code === 0 && !error ? 'passed' : 'failed'), exitCode: code, signal: sig,
        error, cleanupIncomplete, pid: child.pid, durationMs: Date.now() - started };
      onEvent({ event: 'close', ...result }); resolve(result);
    }
    child.once('close', finish);
    if (timeoutMs) timer = setTimeout(() => stop('timed_out'), timeoutMs);
  });
}
