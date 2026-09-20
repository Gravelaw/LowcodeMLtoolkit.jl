import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync, mkdtempSync, writeFileSync, unlinkSync, rmdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, relative, resolve } from "node:path";
import { execFileSync } from "node:child_process";
import { createGatewayApiClient } from "../../packages/contracts/src/index.ts";

const cases = JSON.parse(readFileSync(new URL("./fixtures/project-payload-cases.json", import.meta.url), "utf8"));
for (const fixture of [...cases.valid, ...cases.invalid]) fixture.payload = { ...structuredClone(cases.base), ...fixture.payload };

test("OpenAPI references resolve locally, including nested schema pointers", () => {
  const spec = JSON.parse(readFileSync(new URL("../../packages/contracts/openapi/openapi.json", import.meta.url), "utf8"));
  const pending = [spec];
  while (pending.length) {
    const node = pending.pop();
    if (!node || typeof node !== "object") continue;
    if (node.$ref) {
      assert.ok(node.$ref.startsWith("#/"), `nonlocal reference: ${node.$ref}`);
      let target = spec;
      for (const part of node.$ref.slice(2).split("/")) target = target?.[part.replaceAll("~1", "/").replaceAll("~0", "~")];
      assert.notEqual(target, undefined, `unresolved reference: ${node.$ref}`);
    }
    pending.push(...Object.values(node));
  }
});

test("shared legacy and populated project fixtures conform to the TypeScript contract", () => {
  const dir = mkdtempSync(join(tmpdir(), "juliaflow-contract-types-"));
  const file = join(dir, "payloads.ts");
  const importPath = relative(dir, resolve("packages/contracts/src/index.ts")).replaceAll("\\", "/");
  writeFileSync(file, `import type { DataScienceProject } from ${JSON.stringify(importPath)};\nconst cases: DataScienceProject[] = ${JSON.stringify(cases.valid.map(item => item.payload))};\nvoid cases;\n`);
  try {
    execFileSync(process.execPath, ["node_modules/typescript/bin/tsc", "--noEmit", "--strict", "--skipLibCheck", "--target", "ES2022", "--module", "ESNext", "--moduleResolution", "Bundler", "--allowImportingTsExtensions", file], { encoding: "utf8" });
  } finally {
    unlinkSync(file);
    rmdirSync(dir);
  }
});

test("typed project client preserves unavailable historical evidence across create, get and update", async () => {
  for (const fixture of cases.valid) {
    let stored;
    const methods = [];
    const client = createGatewayApiClient({ baseUrl: "http://localhost:8088", fetch: async (url, init) => {
      assert.match(String(url), /\/api\/v1\/data-science-projects/);
      methods.push(init.method);
      if (init.body) stored = JSON.parse(init.body);
      return new Response(JSON.stringify(stored), { status: 200, headers: { "Content-Type": "application/json" } });
    } });
    assert.deepEqual(await client.createDataScienceProject(fixture.payload), fixture.payload);
    assert.deepEqual(await client.getDataScienceProject(fixture.payload.projectId), fixture.payload);
    assert.deepEqual(await client.updateDataScienceProject(fixture.payload.projectId, fixture.payload), fixture.payload);
    assert.deepEqual(methods, ["POST", "GET", "PUT"]);
  }
});

test("typed project client propagates malformed-payload rejection", async () => {
  const client = createGatewayApiClient({ baseUrl: "http://localhost:8088", fetch: async () => new Response(JSON.stringify({ error: "data science project projectJobs invalid contract payload" }), { status: 400 }) });
  await assert.rejects(client.updateDataScienceProject("contract-project", cases.invalid[0].payload), /invalid contract payload/);
});
