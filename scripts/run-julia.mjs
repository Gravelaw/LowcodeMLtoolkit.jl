#!/usr/bin/env node
import { existsSync } from "node:fs";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROOT_DIR = resolve(fileURLToPath(new URL("..", import.meta.url)));
const LOCAL_JULIA = join(ROOT_DIR, ".juliaup", "bin", "julia");
const juliaCommand = process.env.JULIAFLOW_JULIA_CMD ?? (existsSync(LOCAL_JULIA) ? LOCAL_JULIA : "julia");

const result = spawnSync(juliaCommand, process.argv.slice(2), {
  cwd: ROOT_DIR,
  env: {
    ...process.env,
    JULIAUP_DEPOT_PATH: process.env.JULIAUP_DEPOT_PATH ?? join(ROOT_DIR, ".juliaup"),
    JULIA_DEPOT_PATH: process.env.JULIA_DEPOT_PATH ?? join(ROOT_DIR, ".julia-depot")
  },
  stdio: "inherit",
  shell: false
});

if (result.error) {
  console.error(result.error.stack ?? result.error.message);
  process.exit(1);
}

process.exit(result.status ?? 1);
