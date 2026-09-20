import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import test from "node:test";
import { checkedMilestoneItems } from "../../scripts/validate-brd-traceability.mjs";

const archive = new URL("../../docs/archive/2026-09-20/", import.meta.url);
const manifest = JSON.parse(readFileSync(new URL("manifest.json", archive), "utf8"));

test("historical control documents preserve their exact snapshot bytes", () => {
  assert.equal(manifest.sourceCommit, "a70ea67eda343655f70fe336c294f8ec9e638889");
  assert.equal(manifest.files.length, 8);
  for (const file of manifest.files) {
    assert.match(file.archivePath, /^[A-Za-z0-9_.-]+$/);
    const bytes = readFileSync(new URL(file.archivePath, archive));
    assert.equal(bytes.length, file.bytes, file.originalPath);
    assert.equal(createHash("sha256").update(bytes).digest("hex"), file.sha256, file.originalPath);
  }
});

test("consolidation retains every previously checked milestone title", () => {
  const before = checkedMilestoneItems(readFileSync(new URL("TODO.md", archive), "utf8"));
  const after = checkedMilestoneItems(readFileSync(new URL("../../docs/TODO.md", import.meta.url), "utf8"));
  assert.equal(before.length, 46);
  assert.deepEqual(after.map(({ section, title }) => ({ section, title })), before.map(({ section, title }) => ({ section, title })));
});

test("risk consolidation retains every historical risk identifier", () => {
  const before = readFileSync(new URL("risk-register.md", archive), "utf8");
  const after = readFileSync(new URL("../../docs/risk-register.md", import.meta.url), "utf8");
  const ids = [...before.matchAll(/^\| (R-[A-Z-]+-\d+) \|/gm)].map((match) => match[1]);
  assert.ok(ids.length > 20);
  for (const id of ids) assert.ok(after.includes(`| ${id} |`), id);
});
