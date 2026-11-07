import assert from "node:assert/strict";
import test from "node:test";
import { localAuthEnv } from "../../scripts/lib/local-auth.mjs";

test("local startup supplies fresh credentials to the existing frontend interface", () => {
  const env = localAuthEnv({}, "http://127.0.0.1:5173");
  assert.equal(env.JULIAFLOW_AUTH_MODE, "required");
  assert.equal(env.JULIAFLOW_RUNTIME_MODE, "local-appliance");
  assert.equal(env.JULIAFLOW_CORS_ALLOW_ORIGIN, "http://127.0.0.1:5173");
  assert.match(env.JULIAFLOW_DEV_AUTH_TOKEN, /^[a-f0-9]{64}$/);
  assert.equal(env.VITE_JULIAFLOW_GATEWAY_AUTH_TOKEN, env.JULIAFLOW_DEV_AUTH_TOKEN);
  assert.notEqual(localAuthEnv({}, "http://127.0.0.1:5173").JULIAFLOW_DEV_AUTH_TOKEN, env.JULIAFLOW_DEV_AUTH_TOKEN);
});

test("configured token and OIDC auth remain usable", () => {
  assert.equal(localAuthEnv({ JULIAFLOW_DEV_AUTH_TOKEN: " configured " }, "http://localhost:5173").VITE_JULIAFLOW_GATEWAY_AUTH_TOKEN, "configured");
  const oidc = localAuthEnv({ JULIAFLOW_AUTH_MODE: "oidc" }, "http://localhost:5173");
  assert.equal(oidc.VITE_JULIAFLOW_GATEWAY_AUTH_TOKEN, "");
  assert.equal(oidc.JULIAFLOW_DEV_AUTH_TOKEN, undefined);
});

test("insecure startup requires explicit development/demo scope", () => {
  for (const mode of ["release", "local-appliance"]) {
    assert.throws(() => localAuthEnv({ JULIAFLOW_RUNTIME_MODE: mode, JULIAFLOW_AUTH_MODE: "disabled" }, "http://localhost:5173"));
    assert.throws(() => localAuthEnv({ JULIAFLOW_RUNTIME_MODE: mode, JULIAFLOW_CORS_ALLOW_ORIGIN: "*" }, "http://localhost:5173"));
  }
  assert.equal(localAuthEnv({ JULIAFLOW_RUNTIME_MODE: "development", JULIAFLOW_AUTH_MODE: "disabled", JULIAFLOW_CORS_ALLOW_ORIGIN: "*" }, "http://localhost:5173").JULIAFLOW_AUTH_MODE, "disabled");
  for (const origin of ["null", "http://localhost:5173/path", "http://user:secret@localhost:5173", ""]) {
    assert.throws(() => localAuthEnv({ JULIAFLOW_CORS_ALLOW_ORIGIN: origin }, "http://localhost:5173"));
  }
});
