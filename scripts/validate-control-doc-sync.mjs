#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const CONTROL_DOCS = [
  "Plan.md", "docs/TODO.md", "docs/risk-register.md",
  "docs/project-tracker.md", "docs/checkpoint-log.md"
];
const REQUIRED_FILES = [...CONTROL_DOCS, "docs/brd-traceability.md", "business-requirements-v0.3.0.md", "AGENTS.md"];
const LOCAL_OUTPUTS = [
  ".omo/", ".omx/", ".staging/", ".codex/", ".codex-archive/", ".codegraph/",
  ".julia-depot/", ".juliaup/", ".pytest_cache/", ".hypothesis/", ".uv-cache/",
  "review-tmp-semantic-aggregate/", "unsloth_compiled_cache/",
  "tmp/", "dist/", "node_modules/", "artifacts/", "coverage/", "test-results/", "playwright-report/"
];

function git(args, cwd) {
  const result = spawnSync("git", args, { cwd, encoding: "utf8", maxBuffer: 16 * 1024 * 1024 });
  if (result.status !== 0) {
    throw new Error(`git ${args.join(" ")} failed: ${(result.stderr || result.error?.message || "unknown error").trim()}`);
  }
  return result.stdout;
}

export function selectBaseline(args, env) {
  if (args.length && (args.length !== 2 || args[0] !== "--base" || !args[1].trim())) {
    throw new Error("Usage: validate-control-doc-sync.mjs [--base <commit-or-ref>]");
  }
  if (args.length) return args[1];
  if (env.JULIAFLOW_CONTROL_DOC_BASE) return env.JULIAFLOW_CONTROL_DOC_BASE;
  if (!["pull_request", "pull_request_target", "push"].includes(env.GITHUB_EVENT_NAME)) return null;
  if (!env.GITHUB_EVENT_PATH) throw new Error("GitHub change event requires an event payload or explicit baseline.");
  const event = JSON.parse(readFileSync(env.GITHUB_EVENT_PATH, "utf8"));
  const baseline = env.GITHUB_EVENT_NAME === "push" ? event.before : event.pull_request?.base?.sha;
  if (typeof baseline !== "string" || !/^[a-f0-9]{40}$/i.test(baseline) || /^0+$/.test(baseline)) {
    throw new Error("GitHub change event has no usable baseline; supply JULIAFLOW_CONTROL_DOC_BASE explicitly.");
  }
  return baseline;
}

export function collectChanges({ cwd = process.cwd(), baseline = null } = {}) {
  // Tracked paths are never excluded, even when they match a local-output prefix.
  const tracked = new Set(git(["diff", "--name-only", "--no-renames", "-z", "HEAD", "--"], cwd).split("\0").filter(Boolean));
  if (baseline) {
    const baseCommit = git(["rev-parse", "--verify", "--end-of-options", `${baseline}^{commit}`], cwd).trim();
    const mergeBase = git(["merge-base", baseCommit, "HEAD"], cwd).trim();
    for (const path of git(["diff", "--name-only", "--no-renames", "-z", mergeBase, "HEAD", "--"], cwd).split("\0").filter(Boolean)) tracked.add(path);
  }
  const untracked = git(["ls-files", "--others", "--exclude-standard", "-z"], cwd).split("\0").filter(Boolean);
  return [...new Set([...tracked, ...untracked.filter((path) => !LOCAL_OUTPUTS.some((prefix) => path.startsWith(prefix)))])].sort();
}

export function requiredDocuments(paths) {
  if (paths.includes("business-requirements-v0.3.0.md")) return [...CONTROL_DOCS, "docs/brd-traceability.md"];
  const changed = paths.filter((path) => !REQUIRED_FILES.includes(path));
  const product = changed.some((path) => !(
    path.startsWith("docs/") || path.endsWith(".md") || path === "LICENSE" ||
    path.startsWith("scripts/") || path.startsWith("tests/") || path.startsWith(".github/") || path === ".gitignore"
  ));
  if (product) return [...CONTROL_DOCS];
  if (changed.some((path) => path.startsWith("scripts/") || path.startsWith("tests/") || path.startsWith(".github/") || path === ".gitignore")) {
    return ["docs/project-tracker.md", "docs/checkpoint-log.md"];
  }
  return [];
}

export function validateControlDocs({ cwd = process.cwd(), baseline = null } = {}) {
  const paths = collectChanges({ cwd, baseline });
  const errors = REQUIRED_FILES.filter((path) => !existsSync(resolve(cwd, path))).map((path) => `Required control file is absent: ${path}`);
  for (const path of requiredDocuments(paths)) if (!paths.includes(path)) errors.push(`Required evidence update is missing: ${path}`);
  return { ok: errors.length === 0, paths, errors, baseline };
}

export function main(args = process.argv.slice(2), env = process.env) {
  try {
    const result = validateControlDocs({ baseline: selectBaseline(args, env) });
    if (!result.ok) {
      console.error(`Control-doc sync validation failed:\n${result.errors.join("\n")}`);
      process.exitCode = 1;
      return;
    }
    console.log(`Control-doc sync validation passed: ${result.paths.length} changed paths (${result.baseline ? "baseline + working tree" : "working tree only"}).`);
  } catch (error) {
    console.error(`Control-doc sync validation failed: ${error.message}`);
    process.exitCode = 1;
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
