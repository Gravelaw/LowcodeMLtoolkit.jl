import assert from "node:assert/strict";
import test from "node:test";
import { prepareJuliaRuntime, JULIA_PREPARATION_ARGS } from "../../scripts/lib/julia-runtime-bootstrap.mjs";

const fixture = (source, options = {}) => prepareJuliaRuntime({
  command: process.execPath, args: ["-e", source], env: process.env, log: () => {}, ...options
});

test("runtime preparation waits for completion before service readiness can begin", async () => {
  let completed = false;
  const pending = fixture("setTimeout(() => process.exit(0), 80)", { log: message => { if (message.includes('ready elapsedMs=')) completed = true; } });
  assert.equal(completed, false);
  await pending;
  assert.equal(completed, true);
  assert.deepEqual(JULIA_PREPARATION_ARGS.slice(0, 2), ["--startup-file=no", "--project=."]);
  assert.match(JULIA_PREPARATION_ARGS.at(-1), /Pkg.precompile\(; strict=true\).*using JuliaFlowMonorepo/);
});

test("preparation failure retains diagnostics and redacts credentials", async () => {
  await assert.rejects(fixture("console.error(process.env.TEST_API_KEY); console.error('broken package'); process.exit(7)", {
    env: { ...process.env, TEST_API_KEY: "private-bootstrap-fixture" }
  }), (error) => {
    assert.match(error.message, /code=7.*broken package/s);
    assert.ok(!error.message.includes("private-bootstrap-fixture"));
    assert.match(error.message, /cleanupIncomplete=false/);
    return true;
  });
});

test("preparation timeout bounds and closes its owned child", async () => {
  await assert.rejects(fixture("setInterval(() => {}, 1000)", { timeoutMs: 150 }), /status=timed_out.*cleanupIncomplete=false/s);
});

test("missing preparation executable fails without starting a service", async () => {
  await assert.rejects(prepareJuliaRuntime({ command: "juliaflow-missing-bootstrap-executable", env: process.env, log: () => {} }), /ENOENT/);
});

test("preparation cancellation remains distinct from timeout and stops its process tree", async () => {
  const controller = new AbortController();
  const command = fixture("setInterval(() => {}, 1000)", { signal: controller.signal });
  setTimeout(() => controller.abort(), 100);
  await assert.rejects(command, /status=cancelled.*cleanupIncomplete=false/);
});
