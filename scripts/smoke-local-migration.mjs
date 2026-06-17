#!/usr/bin/env node
import { existsSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROOT_DIR = resolve(fileURLToPath(new URL("..", import.meta.url)));
const keepHome = process.env.JULIAFLOW_KEEP_SMOKE_HOME === "1";
const home = process.env.JULIAFLOW_MIGRATION_SMOKE_HOME ?? mkdtempSync(join(tmpdir(), "juliaflow-migration-"));
const localJulia = join(ROOT_DIR, ".juliaup", "bin", "julia");
const juliaCommand = process.env.JULIAFLOW_JULIA_CMD ?? (existsSync(localJulia) ? localJulia : "julia");
const juliaEnv = {
  ...process.env,
  JULIAUP_DEPOT_PATH: process.env.JULIAUP_DEPOT_PATH ?? join(ROOT_DIR, ".juliaup"),
  JULIA_DEPOT_PATH: process.env.JULIA_DEPOT_PATH ?? join(ROOT_DIR, ".julia-depot")
};

async function main() {
  const probe = spawnSync(juliaCommand, ["--version"], { cwd: ROOT_DIR, env: juliaEnv, encoding: "utf8" });
  if (probe.status !== 0) {
    throw new Error(`Unable to start ${juliaCommand}; set JULIAFLOW_JULIA_CMD to a working Julia executable`);
  }
  const env = {
    ...juliaEnv,
    JULIAFLOW_APPLIANCE_BOOTSTRAP: "1",
    JULIAFLOW_LOCAL_PROFILE: "single-user",
    JULIAFLOW_HOME: home,
    JULIAFLOW_DATA_ESTATE_ROOT: join(home, "data"),
    JULIAFLOW_METADATA_ROOT: join(home, "metadata"),
    JULIAFLOW_STORE_ROOT: join(home, "metadata", "gateway-store"),
    JULIAFLOW_AUTH_MODE: "disabled",
    JULIAFLOW_EVENT_BACKBONE_MODE: "dual_write",
    JULIAFLOW_WORKFLOW_PATH: join(ROOT_DIR, "tests", "contracts", "fixtures", "foundation.workflow.toml")
  };
  const result = spawnSync(juliaCommand, ["--project=.", "scripts/smoke-local-migration.jl"], {
    cwd: ROOT_DIR,
    env,
    stdio: "inherit"
  });
  if (!keepHome && !process.env.JULIAFLOW_MIGRATION_SMOKE_HOME) {
    rmSync(home, { recursive: true, force: true });
  }
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
  console.log("[smoke:local-migration] passed");
}

main().catch((error) => {
  console.error(`[smoke:local-migration] ${error.message}`);
  process.exit(1);
});
