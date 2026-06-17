#!/usr/bin/env node
import { createHash } from "node:crypto";
import { existsSync, mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROOT_DIR = resolve(fileURLToPath(new URL("..", import.meta.url)));
const keepHome = process.env.JULIAFLOW_KEEP_SMOKE_HOME === "1";
const home = process.env.JULIAFLOW_OFFLINE_HUB_SMOKE_HOME ?? mkdtempSync(join(tmpdir(), "juliaflow-offline-hub-"));
const hubCacheRoot = join(home, "hub-cache");
const artifactRoot = join(hubCacheRoot, "artifacts");
const mirrorRoot = join(hubCacheRoot, "mirrors");
const artifactPath = join(artifactRoot, "offline-proof-package.txt");
const artifactStorePath = join(hubCacheRoot, "artifact-store.json");
const mirrorRegistryPath = join(hubCacheRoot, "mirror-registry.json");
const packageRef = "hub://offline/offline-proof";
const unsafePackageRef = "hub://offline/unsafe-proof";
const mirrorRef = "mirror://offline/offline-proof";
const localJulia = join(ROOT_DIR, ".juliaup", "bin", "julia");
const juliaCommand = process.env.JULIAFLOW_JULIA_CMD ?? (existsSync(localJulia) ? localJulia : "julia");
const juliaEnv = {
  ...process.env,
  JULIAUP_DEPOT_PATH: process.env.JULIAUP_DEPOT_PATH ?? join(ROOT_DIR, ".juliaup"),
  JULIA_DEPOT_PATH: process.env.JULIA_DEPOT_PATH ?? join(ROOT_DIR, ".julia-depot")
};

function sha256FileBytes(content) {
  return `sha256:${createHash("sha256").update(content).digest("hex")}`;
}

function writeOfflineRegistries() {
  const artifactBytes = "JuliaFlow offline Hub proof package\n";
  mkdirSync(artifactRoot, { recursive: true });
  mkdirSync(mirrorRoot, { recursive: true });
  writeFileSync(artifactPath, artifactBytes);
  writeFileSync(
    artifactStorePath,
    JSON.stringify({
      [packageRef]: { package: artifactPath },
      [unsafePackageRef]: { package: artifactPath }
    }, null, 2)
  );
  writeFileSync(
    mirrorRegistryPath,
    JSON.stringify({ [mirrorRef]: mirrorRoot }, null, 2)
  );
  return sha256FileBytes(artifactBytes);
}

async function main() {
  const artifactHash = writeOfflineRegistries();
  const juliaProbe = spawnSync(juliaCommand, ["--version"], { cwd: ROOT_DIR, env: juliaEnv, encoding: "utf8" });
  if (juliaProbe.status !== 0) {
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
    JULIAFLOW_HUB_CACHE_ROOT: hubCacheRoot,
    JULIAFLOW_HUB_ARTIFACT_STORE: artifactStorePath,
    JULIAFLOW_HUB_MIRROR_REGISTRY: mirrorRegistryPath,
    JULIAFLOW_AUTH_MODE: "disabled",
    JULIAFLOW_EVENT_BACKBONE_MODE: "dual_write",
    JULIAFLOW_HUB_SANDBOX_EXECUTE: "0",
    JULIAFLOW_WORKFLOW_PATH: join(ROOT_DIR, "tests", "contracts", "fixtures", "foundation.workflow.toml"),
    JULIAFLOW_OFFLINE_HUB_ARTIFACT_HASH: artifactHash
  };
  const result = spawnSync(juliaCommand, ["--project=.", "scripts/smoke-local-offline-hub.jl"], {
    cwd: ROOT_DIR,
    env,
    stdio: "inherit"
  });
  if (!keepHome && !process.env.JULIAFLOW_OFFLINE_HUB_SMOKE_HOME) {
    rmSync(home, { recursive: true, force: true });
  }
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
  console.log("[smoke:local-offline-hub] passed");
}

main().catch((error) => {
  console.error(`[smoke:local-offline-hub] ${error.message}`);
  process.exit(1);
});
