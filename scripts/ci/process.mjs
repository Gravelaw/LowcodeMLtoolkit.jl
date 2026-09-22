import { spawn, spawnSync } from 'node:child_process';
import { appendFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { captureStartupOutput, redactStartup } from '../lib/startup-diagnostics.mjs';

// Stream complete, redacted lines; never buffer an entire compiler/test phase.
export function runProcess(command, args, { cwd = process.cwd(), env = process.env, logPath,
  timeoutMs = 0, signal, onEvent = () => {}, echo = true, graceMs = 3000 } = {}) {
  return new Promise(resolve => {
    const started = Date.now();
    let reason, error, timer, escalation, closed = false;
    if (logPath) mkdirSync(dirname(logPath), { recursive: true });
    const write = text => { if (logPath) appendFileSync(logPath, text); if (echo) process.stdout.write(text); };
    const redact = text => redactStartup(text, env);
    if (signal?.aborted) return resolve({ status: 'cancelled', exitCode: null, durationMs: 0 });
    const child = spawn(command, args, { cwd, env, windowsHide: true, detached: process.platform !== 'win32',
      shell: process.platform === 'win32' && /(?:\.cmd|^npm|^npx)$/.test(command), stdio: ['ignore', 'pipe', 'pipe'] });
    function kill(force) {
      if (!child.pid) return;
      try {
        if (process.platform === 'win32') spawnSync('taskkill.exe', ['/pid', String(child.pid), '/T', '/F'], { windowsHide: true, timeout: 5000, stdio: 'ignore' });
        else process.kill(-child.pid, force ? 'SIGKILL' : 'SIGTERM');
      } catch (e) { if (e.code !== 'ESRCH') write(redact(`cleanup: ${e.message}\n`)); }
    }
    function stop(status) {
      if (closed || reason) return;
      reason = status;
      onEvent({ event: status, pid: child.pid });
      kill(false);
      escalation = setTimeout(() => kill(true), graceMs);
    }
    const abort = () => stop('cancelled');
    signal?.addEventListener('abort', abort, { once: true });
    child.once('spawn', () => onEvent({ event: 'spawn', pid: child.pid }));
    child.once('error', e => { error = redact(e.message); write(`${error}\n`); });
    captureStartupOutput(child.stdout, write, redact);
    captureStartupOutput(child.stderr, write, redact);
    child.once('exit', (code, sig) => {
      onEvent({ event: 'exit', pid: child.pid, code, signal: sig });
      // A descendant retaining stdio must not keep a completed command alive.
      if (process.platform !== 'win32') { kill(false); escalation ??= setTimeout(() => kill(true), graceMs); }
    });
    child.once('close', (code, sig) => {
      if (process.platform !== 'win32') kill(true);
      closed = true; clearTimeout(timer); clearTimeout(escalation); signal?.removeEventListener('abort', abort);
      const result = { status: reason ?? (code === 0 && !error ? 'passed' : 'failed'), exitCode: code, signal: sig,
        error, durationMs: Date.now() - started };
      onEvent({ event: 'close', ...result }); resolve(result);
    });
    if (timeoutMs) timer = setTimeout(() => stop('timed_out'), timeoutMs);
  });
}
