#!/usr/bin/env node
import { existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROOT_DIR = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const LOCAL_JULIA = join(ROOT_DIR, ".juliaup", "bin", "julia");
const args = new Set(process.argv.slice(2));

function fail(message) {
  console.error(message);
  process.exit(1);
}

function osRelease() {
  try {
    return readFileSync("/etc/os-release", "utf8");
  } catch {
    return "";
  }
}

function assertDebianLinuxNode() {
  if (process.platform !== "linux") {
    fail("JuliaFlow JS tooling must run with native Debian/Linux Node.js.");
  }

  const nodePath = process.execPath.replaceAll("\\", "/").toLowerCase();
  if (nodePath.startsWith("/mnt/c/") || nodePath.includes("/program files/nodejs/")) {
    fail(`JuliaFlow detected Windows Node.js interop: ${process.execPath}`);
  }

  const release = osRelease().toLowerCase();
  if (release && !release.includes("id=debian") && !release.includes("id_like=debian")) {
    fail("JuliaFlow local development is currently provisioned for Debian-compatible Linux.");
  }
}

function juliaCommand() {
  if (process.env.JULIAFLOW_JULIA_CMD) {
    return process.env.JULIAFLOW_JULIA_CMD;
  }
  return existsSync(LOCAL_JULIA) ? LOCAL_JULIA : "julia";
}

function juliaEnv() {
  return {
    ...process.env,
    JULIAUP_DEPOT_PATH: process.env.JULIAUP_DEPOT_PATH ?? join(ROOT_DIR, ".juliaup"),
    JULIA_DEPOT_PATH: process.env.JULIA_DEPOT_PATH ?? join(ROOT_DIR, ".julia-depot")
  };
}

function assertJulia() {
  const command = juliaCommand();
  const result = spawnSync(command, ["--version"], {
    cwd: ROOT_DIR,
    env: juliaEnv(),
    encoding: "utf8"
  });
  if (result.status !== 0) {
    fail(`JuliaFlow could not start Julia with ${command}. Install Julia LTS for Debian or set JULIAFLOW_JULIA_CMD.`);
  }
  process.stdout.write(result.stdout);
}

assertDebianLinuxNode();
if (args.has("--julia")) {
  assertJulia();
}
