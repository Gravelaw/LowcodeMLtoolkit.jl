import { closeSync, existsSync, mkdtempSync, openSync, readSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runProcess } from "../ci/process.mjs";

export const JULIA_PREPARATION_ARGS = [
  "--startup-file=no", "--project=.", "-e",
  "using Pkg; Pkg.precompile(; strict=true); using JuliaFlowMonorepo"
];

function diagnosticTail(path) {
  if (!existsSync(path)) return "[no preparation output]";
  const length = Math.min(statSync(path).size, 16384);
  const buffer = Buffer.alloc(length);
  const file = openSync(path, "r");
  try {
    const bytes = readSync(file, buffer, 0, length, Math.max(0, statSync(path).size - length));
    return buffer.subarray(0, bytes).toString("utf8");
  } finally { closeSync(file); }
}

// Preparation has its own budget; it never extends endpoint readiness deadlines.
export async function prepareJuliaRuntime({ command, cwd, env = process.env, args = JULIA_PREPARATION_ARGS, timeoutMs = 600000, signal, log = console.log }) {
  if (!Number.isInteger(timeoutMs) || timeoutMs < 1) throw new Error("Invalid Julia preparation deadline");
  const logPath = join(mkdtempSync(join(tmpdir(), "juliaflow-prepare-")), "preparation.log");
  log(`[julia:prepare] starting deadlineMs=${timeoutMs} log=${logPath}`);
  const result = await runProcess(command, args, { cwd, env, logPath, timeoutMs, signal, echo: true });
  if (result.status !== "passed" || result.cleanupIncomplete) {
    const output = diagnosticTail(logPath);
    throw new Error(`Julia preparation failed status=${result.status} code=${result.exitCode} cleanupIncomplete=${Boolean(result.cleanupIncomplete)} pid=${result.pid ?? 'none'} log=${logPath}\n${output}`);
  }
  log(`[julia:prepare] ready elapsedMs=${result.durationMs}`);
  return { ...result, logPath };
}
