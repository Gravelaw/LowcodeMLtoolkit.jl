#!/usr/bin/env node
import { mkdtempSync, rmSync, writeFileSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROOT_DIR = resolve(fileURLToPath(new URL("..", import.meta.url)));
const SOURCE = join(ROOT_DIR, "tests", "julia", "runtests.jl");
const TEST_DIR = join(ROOT_DIR, "tests", "julia").replaceAll("\\", "/");

const rawArgs = process.argv.slice(2);
const args = new Set(rawArgs);
const dryRun = args.has("--dry-run");
const keepTemp = args.has("--keep-temp") || dryRun;
const listSlices = args.has("--list");

const SLICES = {
  presentation: ["Gateway presentation helpers"],
  helpers: [
    "Data science project core helpers",
    "Data science project local source helpers",
    "Data science project catalog helpers",
    "Data science project prediction export helpers",
    "Data science project registry payload helpers",
    "Data science project monitoring helpers",
    "Data science project deploy helpers",
    "Data science project tuning helpers",
    "Data science project evaluation helpers",
    "Data science project transform helpers",
    "Data science project experiment helpers",
    "Data science project statistical helpers",
    "Data science project registry helpers",
    "Data science project job helpers"
  ],
  tuning: ["Data science project tuning helpers"],
  "project-contracts": ["Data science project core helpers", "Data science project job helpers", "Project payload contract boundary"],
  "project-evidence": ["Project real evidence boundary"],
  splits: ["Project split membership boundary"],
  "local-sources": ["Data science project local source helpers", "Gateway managed path boundary"],
  "node-sdk": ["Node SDK"],
  "execution-service": ["Execution Service"],
  repository: ["Gateway Repository", "Project payload contract boundary"],
  worker: ["Data science project job helpers", "Worker Service"],
  "api-gateway": ["API Gateway", "Gateway local browser boundary", "Project real evidence boundary", "Project split membership boundary", "Local CSV profiling boundary", "Real file profile route boundary", "Durable scoped analysis boundary"],
  realtime: ["API Gateway Realtime", "Gateway realtime cleanup"],
  "base-extension": ["Base Extension"],
  auth: [
    "Gateway Audit Events",
    "Gateway OIDC RBAC Policy",
    "Gateway OIDC JWKS Rotation",
    "Gateway OIDC RS256 JWKS"
  ]
};

function selectedLabelsFromArgs(values) {
  const labels = new Set();

  for (const value of values) {
    if (value.startsWith("--slice=")) {
      const sliceName = value.slice("--slice=".length);
      for (const label of SLICES[sliceName] ?? []) {
        labels.add(label);
      }
    } else if (!value.startsWith("--")) {
      for (const label of SLICES[value] ?? [value]) {
        labels.add(label);
      }
    }
  }

  return labels.size > 0 ? labels : null;
}

const selectedLabels = selectedLabelsFromArgs(rawArgs);

function juliaString(value) {
  return JSON.stringify(value);
}

function topLevelLabels(source) {
  return [...source.matchAll(/^@testset "([^"]+)" begin/gm)].map((match) => match[1]);
}

function wrapSelectedTopLevel(source, labels) {
  if (!labels) {
    return source;
  }

  const pattern = /^@testset "([^"]+)" begin/gm;
  let output = "";
  let lastIndex = 0;
  let previousLabel = null;
  let match;

  while ((match = pattern.exec(source)) !== null) {
    output += source.slice(lastIndex, match.index);

    if (previousLabel !== null) {
      output += `\nend # JuliaFlow selected testset guard: ${previousLabel}\n`;
    }

    output += labels.has(match[1]) ? "if true\n" : "if false\n";
    output += match[0];
    lastIndex = match.index + match[0].length;
    previousLabel = match[1];
  }

  output += source.slice(lastIndex);
  if (previousLabel !== null) {
    output += `\nend # JuliaFlow selected testset guard: ${previousLabel}\n`;
  }

  return output;
}

function buildInstrumentedSource(source) {
  const prelude = [
    `const JF_TIMED_TEST_DIR = ${juliaString(TEST_DIR)}`,
    "const JF_TIMED_START = time()",
    "function jf_timed_mark(label)",
    "    elapsed = round(time() - JF_TIMED_START; digits = 2)",
    '    println("[JF-TIME] $(elapsed)s $(label)")',
    "end",
    'atexit(() -> jf_timed_mark("total"))',
    'jf_timed_mark("load: tests/julia/runtests.jl")',
    ""
  ].join("\n");

  const replacedDir = wrapSelectedTopLevel(source.replaceAll("@__DIR__", "JF_TIMED_TEST_DIR"), selectedLabels);
  let markerCount = 0;
  const instrumented = replacedDir.replace(/^@testset "([^"]+)" begin/gm, (line, label) => {
    markerCount += 1;
    return `jf_timed_mark(${juliaString(`start: ${label}`)})\n${line}`;
  });

  return {
    source: `${prelude}${instrumented}`,
    markerCount
  };
}

const rawSource = readFileSync(SOURCE, "utf8");
const labels = topLevelLabels(rawSource);
if (listSlices) {
  console.log("Available slices:");
  for (const [name, sliceLabels] of Object.entries(SLICES)) {
    console.log(`  ${name}: ${sliceLabels.join(", ")}`);
  }
  console.log("Top-level testsets:");
  for (const label of labels) {
    console.log(`  ${label}`);
  }
  process.exit(0);
}

if (selectedLabels) {
  const unknownLabels = [...selectedLabels].filter((label) => !labels.includes(label));
  if (unknownLabels.length > 0) {
    console.error(`Unknown Julia testset label(s): ${unknownLabels.join(", ")}`);
    process.exit(1);
  }
}

const { source, markerCount } = buildInstrumentedSource(rawSource);
const tempDir = mkdtempSync(join(tmpdir(), "juliaflow-runtests-"));
const tempFile = join(tempDir, "runtests.timed.jl");
writeFileSync(tempFile, source, "utf8");

console.log(`[JF-TIME] instrumented ${markerCount} top-level Julia testsets`);
if (selectedLabels) {
  console.log(`[JF-TIME] selected testsets: ${[...selectedLabels].join(", ")}`);
}
console.log(`[JF-TIME] temp file: ${tempFile}`);

let status = 0;
try {
  if (!dryRun) {
    const result = spawnSync(
      process.execPath,
      ["scripts/run-julia.mjs", "--compiled-modules=no", "--project=.", tempFile],
      {
        cwd: ROOT_DIR,
        env: process.env,
        stdio: "inherit",
        shell: false
      }
    );

    if (result.error) {
      console.error(result.error.stack ?? result.error.message);
      status = 1;
    } else {
      status = result.status ?? 1;
    }
  }
} finally {
  if (!keepTemp) {
    rmSync(tempDir, { recursive: true, force: true });
  }
}

process.exit(status);
