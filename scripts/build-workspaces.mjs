#!/usr/bin/env node
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { build as viteBuild } from "vite";
import react from "@vitejs/plugin-react";

const ROOT_DIR = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const FRONTEND_DIR = resolve(ROOT_DIR, "apps", "frontend");
const NODE_MODULES_DIR = resolve(ROOT_DIR, "node_modules");

function ensureDependency(path, name) {
  if (!existsSync(path)) {
    throw new Error("Missing " + name + ". Run npm install before npm run build.");
  }
}

function run(label, command, args, cwd) {
  console.log("[build] " + label);
  const result = spawnSync(command, args, {
    cwd,
    env: process.env,
    stdio: "inherit",
    shell: false
  });
  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0) {
    throw new Error(label + " exited with " + result.status);
  }
}

async function main() {
  const tsc = resolve(NODE_MODULES_DIR, "typescript", "bin", "tsc");
  ensureDependency(tsc, "TypeScript");

  rmSync(resolve(FRONTEND_DIR, "dist"), { recursive: true, force: true });
  mkdirSync(resolve(FRONTEND_DIR, "node_modules", ".vite-temp"), { recursive: true });

  run("frontend typecheck", process.execPath, [tsc, "--noEmit", "-p", "tsconfig.json"], FRONTEND_DIR);
  run("frontend vite config typecheck", process.execPath, [tsc, "--noEmit", "-p", "tsconfig.node.json"], FRONTEND_DIR);

  console.log("[build] frontend production bundle");
  await viteBuild({
    root: FRONTEND_DIR,
    configFile: false,
    plugins: [react()]
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("[build] " + error.message);
    process.exit(1);
  });
