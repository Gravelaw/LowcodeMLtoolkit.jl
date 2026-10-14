import { existsSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { arch, platform, release } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { runProcess } from "./ci/process.mjs";

const root = process.cwd();
const artifactRoot = join(root, "artifacts", "release-verification", "latest");
const logRoot = join(artifactRoot, "logs");
const startedAt = new Date().toISOString();
const npmBin = process.platform === "win32" ? "npm.cmd" : "npm";
const doctorScript = process.platform === "win32" ? "doctor:windows" : "doctor:debian";
const localJulia = join(root, ".juliaup", "bin", "julia");
const juliaBin = process.env.JULIAFLOW_JULIA_CMD ?? (existsSync(localJulia) ? localJulia : "julia");
const gitBin = "git";
const requiredGpuTests = process.env.JULIAFLOW_CUDA_SMOKE === "1";
const juliaEnv = {
  JULIAUP_DEPOT_PATH: process.env.JULIAUP_DEPOT_PATH ?? join(root, ".juliaup"),
  JULIA_DEPOT_PATH: process.env.JULIA_DEPOT_PATH ?? join(root, ".julia-depot")
};

const args = new Set(process.argv.slice(2));
const skipped = {
  install: args.has("--skip-install"),
  julia: args.has("--skip-julia"),
  smokes: args.has("--skip-smokes"),
  browser: args.has("--skip-browser"),
  controlDocs: args.has("--skip-control-docs")
};
const enforceCleanCandidate = !Object.values(skipped).some(Boolean);

function gitOutput(args) {
  const result = spawnSync(gitBin, args, {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 1024 * 1024
  });
  if (result.status !== 0) {
    const detail = (result.stderr || result.stdout || result.error?.message || "unknown git error").trim();
    throw new Error(`git ${args.join(" ")} failed: ${detail}`);
  }
  return result.stdout.trim();
}

function readWorktreeStatus() {
  const output = gitOutput(["status", "--porcelain", "--untracked-files=all"]);
  return output ? output.split(/\r?\n/) : [];
}

const worktreeStatusAtStart = readWorktreeStatus();
const candidate = {
  commitSha: gitOutput(["rev-parse", "HEAD"]),
  treeSha: gitOutput(["rev-parse", "HEAD^{tree}"]),
  platform: {
    name: platform(),
    architecture: arch(),
    release: release()
  },
  cleanWorktreeRequired: enforceCleanCandidate,
  cleanWorktreeAtStart: worktreeStatusAtStart.length === 0,
  worktreeStatusAtStart
};

const commands = [
  { phase: "bootstrap", kind: "bootstrap", name: "npm-install", command: npmBin, args: ["install"], skip: skipped.install },
  { phase: "bootstrap", kind: "bootstrap", name: "doctor-host", command: npmBin, args: ["run", doctorScript] },
  { phase: "bootstrap", kind: "bootstrap", name: "julia-instantiate", command: npmBin, args: ["run", "julia:instantiate"], skip: skipped.julia },
  { phase: "contracts", kind: "product", name: "validate-contracts", command: npmBin, args: ["run", "validate:contracts"] },
  { phase: "frontend", kind: "product", name: "build", command: npmBin, args: ["run", "build"] },
  { phase: "frontend", kind: "product", name: "test", command: npmBin, args: ["run", "test"] },
  { phase: "julia", kind: "product", name: "julia-repo-tests", command: requiredGpuTests ? process.execPath : juliaBin,
    args: requiredGpuTests ? ["scripts/time-julia-runtests.mjs"] : ["--compiled-modules=no", "--project=.", "tests/julia/runtests.jl"], skip: skipped.julia },
  { phase: "julia", kind: "product", name: "julia-base-extension-tests", command: juliaBin, args: ["--compiled-modules=no", "--project=.", "extensions/base/test/runtests.jl"], skip: skipped.julia },
  { phase: "local-smoke", kind: "runtime", name: "smoke-local-bootstrap", command: npmBin, args: ["run", "smoke:local-bootstrap"], skip: skipped.smokes },
  { phase: "local-smoke", kind: "runtime", name: "smoke-local-data-estate", command: npmBin, args: ["run", "smoke:local-data-estate"], skip: skipped.smokes },
  { phase: "local-smoke", kind: "runtime", name: "smoke-local-metadata", command: npmBin, args: ["run", "smoke:local-metadata"], skip: skipped.smokes },
  { phase: "local-smoke", kind: "runtime", name: "smoke-local-hardware", command: npmBin, args: ["run", "smoke:local-hardware"], skip: skipped.smokes },
  { phase: "local-smoke", kind: "runtime", name: "smoke-local-explainability", command: npmBin, args: ["run", "smoke:local-explainability"], skip: skipped.smokes },
  { phase: "local-smoke", kind: "runtime", name: "smoke-local-offline-hub", command: npmBin, args: ["run", "smoke:local-offline-hub"], skip: skipped.smokes },
  { phase: "local-smoke", kind: "runtime", name: "smoke-local-reproducibility", command: npmBin, args: ["run", "smoke:local-reproducibility"], skip: skipped.smokes },
  { phase: "local-smoke", kind: "runtime", name: "smoke-local-migration", command: npmBin, args: ["run", "smoke:local-migration"], skip: skipped.smokes },
  { phase: "browser", kind: "runtime", name: "smoke-live-backend-browser", command: npmBin, args: ["run", "smoke:live-backend-browser"], skip: skipped.browser },
  { phase: "browser", kind: "runtime", name: "smoke-create-project", command: npmBin, args: ["run", "smoke:create-project"], skip: skipped.browser },
  { phase: "browser", kind: "runtime", name: "smoke-durable-analysis", command: npmBin, args: ["run", "smoke:durable-analysis"], skip: skipped.browser },
  { phase: "control-docs", kind: "control-docs", name: "validate-control-doc-sync", command: npmBin, args: ["run", "validate:control-doc-sync"], skip: skipped.controlDocs },
  { phase: "control-docs", kind: "control-docs", name: "validate-brd-traceability", command: npmBin, args: ["run", "validate:brd-traceability"], skip: skipped.controlDocs },
  { phase: "diff", kind: "product", name: "git-diff-check", command: gitBin, args: ["diff", "--check"] }
];

if (args.has("--list")) {
  for (const item of commands) {
    const status = item.skip ? "skip" : "run";
    console.log(`${status}\t${item.phase}\t${item.name}\t${item.command} ${item.args.join(" ")}`);
  }
  process.exit(0);
}

rmSync(artifactRoot, { recursive: true, force: true });
mkdirSync(logRoot, { recursive: true });

const results = [];
const cancellation = new AbortController();
for (const signal of ["SIGINT", "SIGTERM"]) process.on(signal, () => cancellation.abort());

function writeSummary(status, extra = {}) {
  const worktreeStatusAtFinish = readWorktreeStatus();
  const cleanWorktreeAtFinish = worktreeStatusAtFinish.length === 0;
  const summary = {
    status,
    startedAt,
    finishedAt: new Date().toISOString(),
    artifactRoot,
    commitSha: candidate.commitSha,
    treeSha: candidate.treeSha,
    platform: candidate.platform,
    cleanWorktree: candidate.cleanWorktreeAtStart && cleanWorktreeAtFinish,
    candidate: {
      ...candidate,
      cleanWorktreeAtFinish,
      worktreeStatusAtFinish
    },
    skipped,
    results: [...results, ...commands.filter(c => !results.some(r => r.name === c.name)).map(c => ({ name: c.name, phase: c.phase, status: c.skip ? "skipped" : "not_run" }))],
    ...extra
  };
  writeFileSync(join(artifactRoot, "summary.json"), `${JSON.stringify(summary, null, 2)}\n`);
}

if (enforceCleanCandidate && !candidate.cleanWorktreeAtStart) {
  results.push({
    name: "git-clean-worktree",
    phase: "candidate",
    failureKind: "governance",
    status: "failed",
    exitCode: 1,
    durationMs: 0
  });
  writeSummary("failed", {
    failedPhase: "candidate",
    failedCommand: "git-clean-worktree",
    failureKind: "governance"
  });
  console.error("Release verification requires a clean worktree for a no-skip candidate.");
  process.exit(1);
}

writeSummary("running");
for (const item of commands) {
  if (item.skip) {
    results.push({ name: item.name, phase: item.phase, status: "skipped" });
    continue;
  }

  console.log(`[${item.phase}] ${item.name}: ${item.command} ${item.args.join(" ")}`);
  writeSummary("running", { activePhase: item.name });
  const logPath = join(logRoot, `${item.name}.log`);
  writeFileSync(logPath, `$ ${item.command} ${item.args.join(" ")}\n`);
  const result = await runProcess(item.command, item.args, {
    cwd: root,
    env: item.command === juliaBin ? { ...process.env, ...juliaEnv } : process.env,
    logPath,
    signal: cancellation.signal
  });
  const durationMs = result.durationMs;

  const entry = {
    name: item.name,
    phase: item.phase,
    failureKind: item.kind,
    status: result.status,
    exitCode: result.exitCode,
    durationMs,
    log: join("logs", `${item.name}.log`)
  };
  results.push(entry);
  writeSummary("running");

  if (result.status !== "passed") {
    writeSummary(result.status, {
      failedPhase: item.phase,
      failedCommand: item.name,
      failureKind: item.kind
    });
    process.exit(result.exitCode || 1);
  }
}

const worktreeStatusAtFinish = readWorktreeStatus();
if (enforceCleanCandidate && (worktreeStatusAtFinish.length > 0 || gitOutput(["rev-parse", "HEAD"]) !== candidate.commitSha || gitOutput(["rev-parse", "HEAD^{tree}"]) !== candidate.treeSha)) {
  results.push({
    name: "git-clean-worktree-final",
    phase: "candidate",
    failureKind: "governance",
    status: "failed",
    exitCode: 1,
    durationMs: 0
  });
  writeSummary("failed", {
    failedPhase: "candidate",
    failedCommand: "git-clean-worktree-final",
    failureKind: "governance"
  });
  console.error("Release verification left the candidate worktree unclean.");
  process.exit(1);
}

writeSummary("passed");
console.log(`Release verification passed. Artifacts: ${artifactRoot}`);
