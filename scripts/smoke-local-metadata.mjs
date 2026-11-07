#!/usr/bin/env node
import { existsSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { postgresReadiness } from "./ci/postgres.mjs";
import { redactStartup } from "./lib/startup-diagnostics.mjs";
const postgresProbe = postgresReadiness();

const ROOT_DIR = resolve(fileURLToPath(new URL("..", import.meta.url)));
const LOCAL_JULIA = join(ROOT_DIR, ".juliaup", "bin", "julia");
const keepHome = process.env.JULIAFLOW_KEEP_SMOKE_HOME === "1";
const postgresUrl = process.env.JULIAFLOW_DATABASE_URL ?? "postgresql://juliaflow:juliaflow@127.0.0.1:5432/juliaflow";
const schema = process.env.JULIAFLOW_DATABASE_SCHEMA ?? `juliaflow_smoke_${process.pid}`;

function juliaCommand() {
  return process.env.JULIAFLOW_JULIA_CMD ?? (existsSync(LOCAL_JULIA) ? LOCAL_JULIA : "julia");
}

function withJuliaEnv(env) {
  return {
    ...env,
    JULIAUP_DEPOT_PATH: env.JULIAUP_DEPOT_PATH ?? join(ROOT_DIR, ".juliaup"),
    JULIA_DEPOT_PATH: env.JULIA_DEPOT_PATH ?? process.env.JULIA_DEPOT_PATH ?? join(ROOT_DIR, ".julia-depot")
  };
}

function assertSafeSchemaName(schemaName) {
  if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(schemaName)) {
    throw new Error(`Unsafe Postgres schema name for metadata smoke: ${schemaName}`);
  }
}

function run(command, args, env) {
  const result = spawnSync(command, args, {
    cwd: ROOT_DIR,
    env: { ...process.env, ...env },
    stdio: "inherit"
  });
  if (result.status !== 0) {
    throw new Error(redactStartup(`${command} ${args.join(" ")} exited with ${result.status}`, { ...process.env, ...env }));
  }
}

function runDevLocalSmoke(profile, home, gatewayPort, extraArgs = [], extraEnv = {}) {
  run(process.execPath, [
    "scripts/dev-local.mjs",
    "--profile",
    profile,
    "--home",
    home,
    "--gateway-port",
    String(gatewayPort),
    "--smoke",
    ...extraArgs
  ], {
    JULIAFLOW_GATEWAY_PORT: String(gatewayPort),
    ...extraEnv
  });
}

function runRepositorySmoke(backend, home, storeName, extraEnv = {}) {
  run(juliaCommand(), ["--compiled-modules=no", "--project=.", "scripts/smoke-local-metadata.jl"], withJuliaEnv({
    JULIAFLOW_HOME: home,
    JULIAFLOW_STORE_ROOT: join(home, "metadata", storeName),
    JULIAFLOW_METADATA_SMOKE_BACKEND: backend,
    ...extraEnv
  }));
}

function cleanupPostgresSchema(schemaName) {
  assertSafeSchemaName(schemaName);
  run(juliaCommand(), ["--compiled-modules=no", "--project=.", "scripts/smoke-local-metadata.jl"], withJuliaEnv({
    JULIAFLOW_METADATA_SMOKE_BACKEND: "postgres-cleanup",
    JULIAFLOW_DATABASE_URL: postgresUrl,
    JULIAFLOW_DATABASE_SCHEMA: schemaName,
    JULIAFLOW_TEST_POSTGRES_URL: postgresUrl,
    JULIAFLOW_TEST_POSTGRES_SCHEMA: schemaName
  }));
}

const singleUserHome = process.env.JULIAFLOW_SINGLE_USER_SMOKE_HOME ?? mkdtempSync(join(tmpdir(), "juliaflow-metadata-single-"));
const labTeamHome = process.env.JULIAFLOW_LAB_TEAM_SMOKE_HOME ?? mkdtempSync(join(tmpdir(), "juliaflow-metadata-lab-"));

try {
  assertSafeSchemaName(schema);
  assertSafeSchemaName(`${schema}_contract`);

  runDevLocalSmoke("single-user", singleUserHome, 20000 + (process.pid % 1000), ["--no-deps"]);
  runRepositorySmoke("file", singleUserHome, "repository-contract-store");

  if (postgresProbe.external) {
    run(postgresProbe.command, postgresProbe.args, {});
  } else {
    run("docker", ["compose", "-f", "infra/docker/compose.dev.yml", "up", "-d", "postgres"], {});
  }
  runDevLocalSmoke("lab-team", labTeamHome, 21000 + (process.pid % 1000), ["--no-deps"], {
    JULIAFLOW_DATABASE_URL: postgresUrl,
    JULIAFLOW_DATABASE_SCHEMA: schema,
    JULIAFLOW_TEST_POSTGRES_URL: postgresUrl,
    JULIAFLOW_TEST_POSTGRES_SCHEMA: schema
  });
  try {
    runRepositorySmoke("postgres", labTeamHome, "repository-contract-store", {
      JULIAFLOW_DATABASE_URL: postgresUrl,
      JULIAFLOW_DATABASE_SCHEMA: `${schema}_contract`,
      JULIAFLOW_TEST_POSTGRES_URL: postgresUrl,
      JULIAFLOW_TEST_POSTGRES_SCHEMA: `${schema}_contract`
    });
  } finally {
    cleanupPostgresSchema(schema);
  }

  console.log("[smoke:local-metadata] passed");
} finally {
  if (!keepHome && !process.env.JULIAFLOW_SINGLE_USER_SMOKE_HOME) {
    rmSync(singleUserHome, { recursive: true, force: true });
  }
  if (!keepHome && !process.env.JULIAFLOW_LAB_TEAM_SMOKE_HOME) {
    rmSync(labTeamHome, { recursive: true, force: true });
  }
}
