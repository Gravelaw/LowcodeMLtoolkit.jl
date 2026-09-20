import assert from "node:assert/strict";
import test from "node:test";
import { createServer } from "node:http";
import { once } from "node:events";
import { PassThrough } from "node:stream";
import { startDiagnosticProcess, waitForStartupJson, startupFailure, captureStartupOutput, redactStartup } from "../../scripts/lib/startup-diagnostics.mjs";

async function server(t, handler) {
  const instance = createServer(handler);
  instance.listen(0, "127.0.0.1");
  await once(instance, "listening");
  t.after(() => { instance.closeAllConnections(); return new Promise((resolve) => instance.close(resolve)); });
  return `http://127.0.0.1:${instance.address().port}/health`;
}
function child(t, source, env = process.env) {
  const gateway = startDiagnosticProcess(process.execPath, ["-e", source], { env, log: () => {} });
  t.after(() => gateway.stop());
  return gateway;
}
const ready = (value) => value?.status === "ok" && value?.metadataReady === true;

test("startup returns ready JSON and preserves authentication headers", async (t) => {
  const url = await server(t, (req, res) => {
    assert.equal(req.headers.authorization, "Bearer test-credential");
    res.end(JSON.stringify({ status: "ok", metadataReady: true }));
  });
  const gateway = child(t, "setInterval(() => {}, 1000)");
  const result = await waitForStartupJson(url, 3000, { process: gateway, headers: { Authorization: "Bearer test-credential" }, ready });
  assert.equal(result.metadataReady, true);
  await gateway.stop();
  assert.equal(gateway.snapshot().closed, true);
});

test("spawn failure reports ENOENT with the endpoint and closes pipes", async () => {
  const gateway = startDiagnosticProcess("juliaflow-intentionally-missing-executable", [], { env: process.env, log: () => {} });
  try {
    await assert.rejects(waitForStartupJson("http://127.0.0.1:1/health", 3000, { process: gateway, pollMs: 10 }), /endpoint=.*health.*ENOENT/);
  } finally { await gateway.stop(); }
  assert.equal(gateway.snapshot().spawned, false);
  assert.match(gateway.snapshot().spawnError, /ENOENT/);
  assert.equal(gateway.snapshot().closed, true);
});

test("early child exit interrupts readiness and retains final output after cleanup", async (t) => {
  const url = await server(t, () => {});
  const gateway = child(t, 'process.stderr.write("module failed\\n"); process.exitCode = 7;');
  const started = Date.now();
  await assert.rejects(waitForStartupJson(url, 5000, { process: gateway, pollMs: 10 }), /gateway exited code=7/);
  assert.ok(Date.now() - started < 4500, "exit must interrupt a pending fetch");
  await gateway.stop();
  assert.equal(gateway.snapshot().exitCode, 7);
  assert.equal(gateway.snapshot().closed, true);
  assert.match(gateway.output(), /module failed/);
});

test("connection refusal retains the underlying connection code and deadline", async () => {
  const instance = createServer();
  instance.listen(0, "127.0.0.1");
  await once(instance, "listening");
  const port = instance.address().port;
  await new Promise((resolve) => instance.close(resolve));
  await assert.rejects(waitForStartupJson(`http://127.0.0.1:${port}/health`, 150, { pollMs: 10 }), /endpoint=.*health elapsedMs=\d+ deadlineMs=150.*ECONNREFUSED/);
});

test("HTTP errors, malformed JSON and non-ready JSON do not pass readiness", async (t) => {
  for (const [name, handler, reason] of [
    ["http", (_req, res) => { res.statusCode = 503; res.end("unavailable"); }, /HTTP 503/],
    ["invalid", (_req, res) => res.end("invalid-json"), /SyntaxError/],
    ["non-ready", (_req, res) => res.end('{"status":"ok","metadataReady":false}'), /JSON response is not ready/]
  ]) {
    await t.test(name, async (t) => {
      const url = await server(t, handler);
      await assert.rejects(waitForStartupJson(url, 150, { ready, pollMs: 10 }), reason);
    });
  }
});

test("a non-ready response may become ready within the unchanged deadline", async (t) => {
  let requests = 0;
  const url = await server(t, (_req, res) => res.end(JSON.stringify({ status: "ok", metadataReady: ++requests > 1 })));
  assert.equal((await waitForStartupJson(url, 3000, { ready, pollMs: 10 })).metadataReady, true);
  assert.equal(requests, 2);
});

test("deadline bounds a hanging response body and cleanup closes a running child", async (t) => {
  const url = await server(t, (_req, res) => { res.writeHead(200); res.write('{"status":'); });
  const gateway = child(t, "setInterval(() => {}, 1000)");
  const started = Date.now();
  await assert.rejects(waitForStartupJson(url, 150, { process: gateway, ready }), /readiness deadline expired/);
  assert.ok(Date.now() - started < 2500, "pending body must respect the readiness deadline");
  await gateway.stop();
  assert.equal(gateway.snapshot().closed, true);
});

test("redaction handles secrets split across chunks and omits oversized lines", async () => {
  const stream = new PassThrough();
  let output = "";
  captureStartupOutput(stream, (line) => { output += line; }, (line) => redactStartup(line, { JULIAFLOW_DEV_AUTH_TOKEN: "split-secret-value" }));
  stream.write("token=split-se");
  stream.write("cret-value\npostgres://user:password@localhost/db\nAuthorization: Bearer other-secret\n");
  stream.write("x".repeat(4097));
  stream.write("secret-tail\nnext line\n");
  stream.end("final split-secret-value");
  await once(stream, "end");
  for (const secret of ["split-secret-value", "user:password", "other-secret", "secret-tail"]) assert.ok(!output.includes(secret));
  assert.match(output, /oversized gateway output line omitted/);
  assert.match(output, /next line/);
  assert.match(output, /final \[REDACTED\]/);
});

test("failure output is bounded and redacted after a real child closes", async (t) => {
  const secret = "configured-credential-value";
  const gateway = child(t, 'for (let i=0;i<200;i++) console.error("x".repeat(300)); console.error(process.env.JULIAFLOW_DEV_AUTH_TOKEN);', { ...process.env, JULIAFLOW_DEV_AUTH_TOKEN: secret });
  await once(gateway.child, "close");
  const message = startupFailure(new Error(`failed ${secret}`), gateway, gateway.snapshot()).message;
  assert.ok(gateway.output().length <= 16384);
  assert.ok(!message.includes(secret));
  assert.match(message, /stateAfterCleanup/);
  assert.equal(gateway.snapshot().closed, true);
});

test("cleanup escalates termination when the child ignores SIGTERM", { skip: process.platform === "win32" ? "Windows terminates SIGTERM directly; POSIX escalation runs in CI" : false }, async (t) => {
  const gateway = child(t, 'process.on("SIGTERM", () => {}); console.log("started"); setInterval(() => {}, 1000);');
  await once(gateway.child.stdout, "data");
  await gateway.stop(100);
  assert.equal(gateway.snapshot().signal, "SIGKILL");
  assert.equal(gateway.snapshot().closed, true);
});
