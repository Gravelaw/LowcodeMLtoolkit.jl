import assert from 'node:assert/strict';
import test from 'node:test';
import { runProcess } from '../../scripts/ci/process.mjs';

test('termination failure settles with an unverified owned PID instead of waiting forever', async () => {
  let pid;
  const start = Date.now();
  try {
    const result = await runProcess(process.execPath, ['-e', 'setInterval(() => {}, 1000)'], {
      timeoutMs: 100, graceMs: 30, echo: false,
      terminate: () => { throw new Error('injected termination failure'); },
      onEvent: event => { if (event.event === 'spawn') pid = event.pid; }
    });
    assert.equal(result.status, 'timed_out');
    assert.equal(result.cleanupIncomplete, true);
    assert.equal(result.pid, pid);
    assert.equal(result.exitCode, null);
    assert.ok(Date.now() - start < 5000, 'cleanup must settle within its grace budget');
    assert.doesNotThrow(() => process.kill(pid, 0), 'fixture still runs when termination fails');
  } finally {
    // Only this test's newly spawned child is owned and eligible for cleanup.
    if (pid) process.kill(pid, 'SIGKILL');
  }
});
