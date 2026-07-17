#!/usr/bin/env node
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROOT_DIR = resolve(fileURLToPath(new URL("..", import.meta.url)));
const keepHome = process.env.JULIAFLOW_KEEP_SMOKE_HOME === "1";
const home = process.env.JULIAFLOW_HARDWARE_SMOKE_HOME ?? mkdtempSync(join(tmpdir(), "juliaflow-hardware-"));
const gatewayPort = 22000 + (process.pid % 1000);

function run(command, args, env = {}, options = {}) {
  const result = spawnSync(command, args, {
    cwd: ROOT_DIR,
    env: { ...process.env, ...env },
    stdio: options.capture ? ["ignore", "pipe", "pipe"] : "inherit",
    encoding: options.capture ? "utf8" : undefined
  });
  if (result.status !== 0) {
    const stderr = options.capture ? result.stderr : "";
    throw new Error(`${command} ${args.join(" ")} exited with ${result.status}${stderr ? `: ${stderr}` : ""}`);
  }
  return result;
}

function parseLastJsonLine(output) {
  const lines = output.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  for (const line of lines.reverse()) {
    try {
      return JSON.parse(line);
    } catch {
      // Keep scanning for the JSON status line emitted by Julia.
    }
  }
  throw new Error(`No JSON status line found in output: ${output}`);
}

try {
  run(process.execPath, [
    "scripts/dev-local.mjs",
    "--profile",
    "single-user",
    "--home",
    home,
    "--gateway-port",
    String(gatewayPort),
    "--smoke",
    "--no-deps"
  ], {
    JULIAFLOW_GATEWAY_PORT: String(gatewayPort),
    JULIAFLOW_GPU_REGISTRY: "",
    JULIAFLOW_CPU_WORKER_CONCURRENCY: "2",
    JULIAFLOW_CPU_WORKER_MEMORY_LIMIT_BYTES: String(512 * 1024 * 1024)
  });

  const cudaSmoke = run(process.execPath, ["scripts/run-julia.mjs", "--project=.", "scripts/smoke-cuda-kernel.jl"], {
    JULIAFLOW_CUDA_SMOKE: "0"
  }, { capture: true });
  const cudaStatus = parseLastJsonLine(cudaSmoke.stdout);
  if (cudaStatus.status !== "skipped") {
    throw new Error(`Expected CUDA smoke skip without JULIAFLOW_CUDA_SMOKE=1, got ${cudaStatus.status}`);
  }

  console.log(JSON.stringify({
    status: "passed",
    profile: "single-user",
    home,
    gatewayPort,
    gpuRegistry: "cpu-fallback",
    cudaSmoke: cudaStatus
  }, null, 2));
  console.log("[smoke:local-hardware] passed");
} finally {
  if (!keepHome && !process.env.JULIAFLOW_HARDWARE_SMOKE_HOME) {
    rmSync(home, { recursive: true, force: true });
  }
}
