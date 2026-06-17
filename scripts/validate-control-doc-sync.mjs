#!/usr/bin/env node
import { spawnSync } from "node:child_process";

const CONTROL_DOCS = new Set([
  "Plan.md",
  "docs/TODO.md",
  "docs/risk-register.md",
  "docs/project-tracker.md",
  "docs/checkpoint-log.md"
]);

const OPTIONAL_CONTROL_DOCS = new Set([
  "docs/brd-traceability.md",
  "AGENTS.md"
]);

function gitLines(args) {
  const result = spawnSync("git", args, { encoding: "utf8" });
  if (result.status !== 0) {
    console.error(result.stdout ?? "");
    console.error(result.stderr ?? result.error?.message ?? "git command failed");
    process.exit(1);
  }
  return result.stdout
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
}

const changed = new Set([
  ...gitLines(["diff", "--name-only", "HEAD", "--"]),
  ...gitLines(["ls-files", "--others", "--exclude-standard"])
]);

const ignoredPrefixes = [
  ".omx/",
  "tmp/",
  "dist/",
  "node_modules/"
];

const relevant = [...changed].filter((path) => !ignoredPrefixes.some((prefix) => path.startsWith(prefix)));
const nonControl = relevant.filter((path) => !CONTROL_DOCS.has(path) && !OPTIONAL_CONTROL_DOCS.has(path));
const missing = [...CONTROL_DOCS].filter((path) => !changed.has(path));

if (relevant.length === 0) {
  console.log("Control-doc sync validation passed: no working-tree changes.");
  process.exit(0);
}

if (nonControl.length > 0 && missing.length > 0) {
  console.error("Control-doc sync validation failed.");
  console.error("Non-control changes are present, so every slice/phase/review must update:");
  for (const path of missing) {
    console.error(`- ${path}`);
  }
  console.error("\nNon-control changes detected:");
  for (const path of nonControl.slice(0, 40)) {
    console.error(`- ${path}`);
  }
  if (nonControl.length > 40) {
    console.error(`- ... ${nonControl.length - 40} more`);
  }
  process.exit(1);
}

console.log("Control-doc sync validation passed.");
console.log(`Changed files checked: ${relevant.length}.`);
