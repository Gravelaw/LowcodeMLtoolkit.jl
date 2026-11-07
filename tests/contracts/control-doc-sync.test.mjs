import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { CONTROL_DOCS, collectChanges, selectBaseline, validateControlDocs } from "../../scripts/validate-control-doc-sync.mjs";

function fixture(t) {
  const cwd = mkdtempSync(join(tmpdir(), "juliaflow-control-docs-"));
  t.after(() => rmSync(cwd, { recursive: true, force: true }));
  const git = (...args) => {
    const result = spawnSync("git", args, { cwd, encoding: "utf8", env: { ...process.env, GIT_CONFIG_NOSYSTEM: "1", GIT_CONFIG_GLOBAL: process.platform === "win32" ? "NUL" : "/dev/null" } });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  };
  const put = (path, text = "fixture\n") => {
    mkdirSync(dirname(join(cwd, path)), { recursive: true });
    writeFileSync(join(cwd, path), text);
  };
  git("init", "--quiet");
  git("config", "user.name", "Test");
  git("config", "user.email", "test@example.invalid");
  git("config", "commit.gpgsign", "false");
  for (const path of [...CONTROL_DOCS, "docs/brd-traceability.md", "AGENTS.md", "business-requirements-v0.3.0.md", "services/example.jl"]) put(path);
  const commit = () => { git("add", "--all"); git("commit", "--quiet", "-m", "fixture"); return git("rev-parse", "HEAD"); };
  return { cwd, git, put, commit, baseline: commit() };
}

test("clean committed product changes require all control documents", (t) => {
  const f = fixture(t);
  f.put("services/example.jl", "changed\n"); f.commit();
  assert.equal(validateControlDocs({ cwd: f.cwd }).ok, true);
  const result = validateControlDocs({ cwd: f.cwd, baseline: f.baseline });
  assert.equal(result.ok, false);
  assert.equal(result.errors.length, CONTROL_DOCS.length);
  for (const path of CONTROL_DOCS) f.put(path, "verified update\n");
  f.commit();
  assert.equal(validateControlDocs({ cwd: f.cwd, baseline: f.baseline }).ok, true);
});

test("staged and unstaged changes remain visible with a committed baseline", (t) => {
  const f = fixture(t);
  f.put("services/staged.jl"); f.git("add", "services/staged.jl");
  f.put("services/example.jl", "unstaged\n");
  assert.deepEqual(collectChanges({ cwd: f.cwd, baseline: f.baseline }), ["services/example.jl", "services/staged.jl"]);
  assert.equal(validateControlDocs({ cwd: f.cwd, baseline: f.baseline }).ok, false);
});

test("designated untracked outputs are ignored but user images remain visible", (t) => {
  const f = fixture(t);
  f.put(".omo/evidence/result.json"); f.put("unsloth_compiled_cache/generated.py");
  f.put("review-tmp-semantic-aggregate/result.txt");
  assert.deepEqual(collectChanges({ cwd: f.cwd }), []);
  f.put("docs/images/user-owned.png");
  assert.deepEqual(collectChanges({ cwd: f.cwd }), ["docs/images/user-owned.png"]);
});

test("tracked local-output paths cannot bypass governance", (t) => {
  const f = fixture(t);
  f.put(".omo/script.js"); f.commit();
  assert.equal(validateControlDocs({ cwd: f.cwd, baseline: f.baseline }).ok, false);
});

test("maintenance requires tracker and checkpoint without forced scope/risk churn", (t) => {
  const f = fixture(t);
  f.put("scripts/maintenance.mjs");
  assert.equal(validateControlDocs({ cwd: f.cwd }).errors.length, 2);
  f.put("docs/project-tracker.md", "maintenance evidence\n");
  f.put("docs/checkpoint-log.md", "maintenance evidence\n");
  assert.equal(validateControlDocs({ cwd: f.cwd }).ok, true);
});

test("documentation editing needs no fabricated product status changes", (t) => {
  const f = fixture(t);
  f.put("README.md", "clearer instructions\n");
  assert.equal(validateControlDocs({ cwd: f.cwd }).ok, true);
});

test("BRD changes require traceability as well as current control documents", (t) => {
  const f = fixture(t);
  f.put("business-requirements-v0.3.0.md", "new requirement\n");
  for (const path of CONTROL_DOCS) f.put(path, "updated\n");
  assert.deepEqual(validateControlDocs({ cwd: f.cwd }).errors, ["Required evidence update is missing: docs/brd-traceability.md"]);
});

test("deleting a required document is rejected even when present in the diff", (t) => {
  const f = fixture(t);
  f.git("rm", "Plan.md");
  assert.match(validateControlDocs({ cwd: f.cwd }).errors.join("\n"), /Required control file is absent: Plan.md/);
});

test("invalid baseline fails instead of silently checking a clean tree", (t) => {
  const f = fixture(t);
  assert.throws(() => validateControlDocs({ cwd: f.cwd, baseline: "missing-ref" }), /failed/);
  const script = fileURLToPath(new URL("../../scripts/validate-control-doc-sync.mjs", import.meta.url));
  const result = spawnSync(process.execPath, [script, "--base", "missing-ref"], { cwd: f.cwd, encoding: "utf8" });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /validation failed/);
});

test("PR/push events select base SHAs and absent or zero baselines fail closed", (t) => {
  const f = fixture(t);
  const eventPath = join(f.cwd, "event.json");
  writeFileSync(eventPath, JSON.stringify({ pull_request: { base: { sha: f.baseline } } }));
  const env = { GITHUB_EVENT_NAME: "pull_request", GITHUB_EVENT_PATH: eventPath };
  assert.equal(selectBaseline([], env), f.baseline);
  assert.equal(selectBaseline(["--base", "HEAD"], env), "HEAD");
  assert.equal(selectBaseline([], { JULIAFLOW_CONTROL_DOC_BASE: "origin/main" }), "origin/main");
  assert.throws(() => selectBaseline([], { GITHUB_EVENT_NAME: "pull_request" }), /requires/);
  writeFileSync(eventPath, JSON.stringify({ before: f.baseline }));
  assert.equal(selectBaseline([], { ...env, GITHUB_EVENT_NAME: "push" }), f.baseline);
  writeFileSync(eventPath, JSON.stringify({ before: "0".repeat(40) }));
  assert.throws(() => selectBaseline([], { ...env, GITHUB_EVENT_NAME: "push" }), /no usable baseline/);
  assert.throws(() => selectBaseline(["--base"], {}), /Usage/);
});

test("CI retains history and installs dependencies before browser binaries", () => {
  for (const name of ["ci.yml", "release-candidate.yml"]) {
    const text = readFileSync(new URL(`../../.github/workflows/${name}`, import.meta.url), "utf8");
    const gate = text.slice(text.indexOf("  debian-release-gate:"));
    assert.ok(gate.indexOf("- run: npm ci") >= 0, name);
    assert.ok(gate.indexOf("- run: npm ci") < gate.indexOf("- run: npx playwright install"), name);
  }
  const ci = readFileSync(new URL("../../.github/workflows/ci.yml", import.meta.url), "utf8");
  assert.match(ci.slice(ci.indexOf("  web:"), ci.indexOf("  julia:")), /fetch-depth: 0/);
  assert.match(ci.slice(ci.indexOf("  debian-release-gate:")), /fetch-depth: 0/);
});
