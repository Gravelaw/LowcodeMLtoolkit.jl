import assert from "node:assert/strict";
import test from "node:test";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { createServer } from "node:net";
import { runInNewContext } from "node:vm";

test("local frontend serves selected runtime metadata without exposing credentials in its public script", async () => {
  const reservation = createServer();
  reservation.listen(0, "127.0.0.1");
  await once(reservation, "listening");
  const port = reservation.address().port;
  await new Promise((resolve, reject) => reservation.close((error) => error ? reject(error) : resolve()));
  const origin = `http://127.0.0.1:${port}`;
  const child = spawn(process.execPath, ["scripts/run-local-frontend.mjs"], {
    cwd: new URL("../../", import.meta.url), windowsHide: true,
    env: { ...process.env, JULIAFLOW_GATEWAY_HOST: "127.0.0.1", JULIAFLOW_FRONTEND_PORT: String(port),
      JULIAFLOW_RUNTIME_MODE: "local-appliance", JULIAFLOW_LOCAL_FRONTEND_URL: origin,
      VITE_JULIAFLOW_GATEWAY_AUTH_TOKEN: "bootstrap-test-credential" },
    stdio: ["ignore", "pipe", "pipe"]
  });
  let output = "";
  child.stdout.on("data", (chunk) => { output += chunk; });
  child.stderr.on("data", (chunk) => { output += chunk; });
  try {
    let response;
    const deadline = Date.now() + 30000;
    while (Date.now() < deadline && child.exitCode === null) {
      try { response = await fetch(`${origin}/juliaflow-config.js`); if (response.ok) break; } catch { /* starting */ }
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
    assert.ok(response?.ok, `local frontend did not start: ${output}`);
    assert.equal(response.headers.get("cache-control"), "no-store");
    const script = await response.text();
    assert.ok(!script.includes("bootstrap-test-credential"));
    const sandbox = { window: {} };
    runInNewContext(script, sandbox);
    assert.equal(sandbox.window.__JULIAFLOW_CONFIG__.runtimeMode, "local-appliance");
    assert.deepEqual(Object.keys(sandbox.window.__JULIAFLOW_CONFIG__), ["runtimeMode"]);
    const denied = await fetch(`${origin}/src/main.tsx`, { headers: { Origin: "https://untrusted.example" } });
    assert.notEqual(denied.headers.get("access-control-allow-origin"), "https://untrusted.example");
    assert.notEqual(denied.headers.get("access-control-allow-origin"), "*");
  } finally {
    if (child.exitCode === null) {
      const exited = once(child, "exit");
      child.kill();
      await exited;
    }
  }
});
