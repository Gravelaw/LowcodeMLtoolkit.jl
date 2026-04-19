import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";
import { promisify } from "node:util";
import test from "node:test";
import { parse } from "smol-toml";

const execFileAsync = promisify(execFile);
const fixturePath = new URL("./fixtures/foundation.workflow.toml", import.meta.url);
const openApiPath = new URL("../../packages/contracts/openapi/openapi.json", import.meta.url);
const jsonRpcPath = new URL("../../packages/contracts/protocol/jsonrpc.json", import.meta.url);

test("workflow fixture matches foundation contract expectations", async () => {
  const raw = await readFile(fixturePath, "utf8");
  const workflow = parse(raw);

  assert.equal(workflow.version, "0.1.0");
  assert.equal(workflow.workflow.name, "Foundation PoC");
  assert.equal(workflow.nodes.length, 3);
  assert.equal(workflow.connections.length, 2);
  assert.equal(workflow.nodes[0].ports[0].type, "data_table");
  assert.equal(workflow.flow_variables[0].type, "GPUDeviceID");
});

test("openapi spec exposes workflow and checkpoint surfaces", async () => {
  const raw = await readFile(openApiPath, "utf8");
  const spec = JSON.parse(raw);

  assert.equal(spec.openapi, "3.1.0");
  assert.ok(spec.paths["/health"]);
  assert.ok(spec.paths["/api/v1/workflows"]);
  assert.ok(spec.paths["/api/v1/workflows/import"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}"]);
  assert.ok(spec.paths["/api/v1/executions"]);
  assert.ok(spec.paths["/api/v1/executions/{executionId}"]);
  assert.ok(spec.paths["/api/v1/executions/{executionId}/status"]);
  assert.ok(spec.paths["/api/v1/checkpoints"]);
  assert.deepEqual(
    spec.paths["/api/v1/executions/{executionId}/status"].post.requestBody.content["application/json"].schema.properties.status.enum,
    ["accepted", "queued", "running", "completed", "failed"]
  );
});

test("jsonrpc protocol exposes execution and dashboard channels", async () => {
  const raw = await readFile(jsonRpcPath, "utf8");
  const protocol = JSON.parse(raw);
  const methodNames = protocol.methods.map((method) => method.name);

  assert.ok(methodNames.includes("workflow.execute"));
  assert.ok(methodNames.includes("dashboard.subscribe"));
  assert.ok(protocol.events.includes("execution.state.changed"));
  assert.ok(protocol.events.includes("streaming.checkpoint.completed"));
});

test("contracts package typechecks typed gateway client surface", async () => {
  await execFileAsync(
    "npx",
    ["tsc", "--noEmit", "-p", "packages/contracts/tsconfig.json"],
    {
      cwd: new URL("../..", import.meta.url).pathname
    }
  );
});
