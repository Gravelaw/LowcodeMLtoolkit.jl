import { randomBytes } from "node:crypto";

// Bootstrap credentials stay in child-process environments, never persisted or logged.
export function localAuthEnv(source, frontendUrl) {
  const runtimeMode = (source.JULIAFLOW_RUNTIME_MODE ?? "local-appliance").trim().toLowerCase();
  if (!["demo", "development", "release", "local-appliance"].includes(runtimeMode)) {
    throw new Error("Unsupported JULIAFLOW_RUNTIME_MODE");
  }
  const authMode = (source.JULIAFLOW_AUTH_MODE ?? "required").trim().toLowerCase();
  if (!["disabled", "dev_token", "required", "oidc"].includes(authMode)) {
    throw new Error("Unsupported JULIAFLOW_AUTH_MODE");
  }
  const strict = runtimeMode === "release" || runtimeMode === "local-appliance";
  if (strict && authMode === "disabled") throw new Error("Disabled auth requires explicit demo/development runtime mode");
  const origins = (source.JULIAFLOW_CORS_ALLOW_ORIGIN ?? new URL(frontendUrl).origin).trim();
  if (strict && (!origins || origins.split(",").some((origin) => origin.trim() === "*"))) {
    throw new Error("Local-appliance/release requires explicit CORS origins");
  }
  for (const origin of origins.split(",").map((value) => value.trim())) {
    if (origin === "*" && !strict) continue;
    const parsed = new URL(origin);
    if (!["http:", "https:"].includes(parsed.protocol) || parsed.origin !== origin) {
      throw new Error("CORS entries must be exact HTTP(S) origins");
    }
  }
  const env = {
    JULIAFLOW_RUNTIME_MODE: runtimeMode,
    VITE_JULIAFLOW_RUNTIME_MODE: runtimeMode,
    JULIAFLOW_AUTH_MODE: authMode,
    JULIAFLOW_CORS_ALLOW_ORIGIN: origins
  };
  if (authMode === "required" || authMode === "dev_token") {
    const token = source.JULIAFLOW_DEV_AUTH_TOKEN?.trim() || randomBytes(32).toString("hex");
    env.JULIAFLOW_DEV_AUTH_TOKEN = token;
    env.VITE_JULIAFLOW_GATEWAY_AUTH_TOKEN = token;
  } else {
    // Do not let an inherited dev token mask the frontend's OIDC token.
    env.VITE_JULIAFLOW_GATEWAY_AUTH_TOKEN = "";
  }
  return env;
}
