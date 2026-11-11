import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import test from "node:test";

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



test("BRD v0.4.1 snapshot keeps original bytes across platform checkouts", () => {
  const root = new URL("../../docs/archive/2026-09-20-brd-v0.4.1/", import.meta.url);
  const record = JSON.parse(readFileSync(new URL("manifest.json", root), "utf8"));
  assert.equal(record.sourceCommit, "c363e0086552334fc2268222550ea031c548b4f9");
  assert.equal(record.files.length, 1);
  for (const file of record.files) {
    assert.match(file.archivePath, /^[A-Za-z0-9_.-]+$/);
    const bytes = readFileSync(new URL(file.archivePath, root));
    assert.equal(bytes.length, file.bytes);
    assert.equal(createHash("sha256").update(bytes).digest("hex"), file.sha256);
  }
});

test("pre-product-spec snapshot keeps original bytes", () => {
  const root = new URL("../../docs/archive/2026-11-11-pre-product-spec/", import.meta.url);
  const record = JSON.parse(readFileSync(new URL("manifest.json", root), "utf8"));
  assert.match(record.sourceCommit, /^[0-9a-f]{40}$/);
  assert.equal(record.files.length, 32);
  for (const file of record.files) {
    assert.match(file.archivePath, /^[A-Za-z0-9_.-]+$/);
    const bytes = readFileSync(new URL(file.archivePath, root));
    assert.equal(bytes.length, file.bytes, file.originalPath);
    assert.equal(createHash("sha256").update(bytes).digest("hex"), file.sha256, file.originalPath);
  }
});
