#!/usr/bin/env node
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROOT_DIR = resolve(fileURLToPath(new URL("..", import.meta.url)));
const profile = process.env.JULIAFLOW_LOCAL_PROFILE ?? "single-user";
const home = process.env.JULIAFLOW_SMOKE_HOME ?? mkdtempSync(join(tmpdir(), "juliaflow-local-"));
const gatewayPort = process.env.JULIAFLOW_GATEWAY_PORT ?? String(19000 + (process.pid % 1000));
const keepHome = process.env.JULIAFLOW_KEEP_SMOKE_HOME === "1";

const result = spawnSync(
  process.execPath,
  [
    "scripts/dev-local.mjs",
    "--profile",
    profile,
    "--home",
    home,
    "--gateway-port",
    gatewayPort,
    "--smoke",
    "--no-deps"
  ],
  {
    cwd: ROOT_DIR,
    env: { ...process.env, JULIAFLOW_GATEWAY_PORT: gatewayPort },
    stdio: "inherit"
  }
);

if (!keepHome && !process.env.JULIAFLOW_SMOKE_HOME) {
  rmSync(home, { recursive: true, force: true });
}

process.exit(result.status ?? 1);
