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
const eventsSchemaPath = new URL("../../packages/contracts/schemas/events.schema.json", import.meta.url);

test("workflow fixture matches foundation contract expectations", async () => {
  const raw = await readFile(fixturePath, "utf8");
  const workflow = parse(raw);

  assert.equal(workflow.version, "0.1.0");
  assert.equal(workflow.workflow.name, "Foundation PoC");
  assert.equal(workflow.nodes.length, 3);
  assert.equal(workflow.connections.length, 2);
  assert.equal(workflow.nodes[0].ports[0].type, "data_table");
  assert.equal(workflow.flow_variables[0].type, "GPUDeviceID");
  assert.equal(workflow.workflow.graph.revision, 2);
  assert.equal(workflow.workflow.dashboards[0].charts.length, 5);
  assert.equal(workflow.workflow.containers[0].id, "container-prep");
  assert.deepEqual(workflow.workflow.containers[0].node_ids, ["node-source", "node-transform"]);
  assert.equal(workflow.workflow.components[0].flow_variable_scope, "isolated");
  assert.equal(workflow.workflow.control_flow[0].kind, "switch");
  assert.equal(workflow.workflow.control_flow[0].cases[0].target_node_id, "node-transform");
  assert.equal(workflow.workflow.control_flow[1].max_concurrency, 4);
  assert.equal(workflow.workflow.control_flow[2].kind, "loop");
  assert.equal(workflow.workflow.control_flow[2].max_iterations, 3);
  assert.equal(workflow.workflow.control_flow[3].kind, "try_catch");
  assert.deepEqual(workflow.workflow.control_flow[3].catch_node_ids, ["node-bi"]);
  assert.equal(workflow.runtime.run_mode, "batch");
});

test("openapi spec exposes workflow and checkpoint surfaces", async () => {
  const raw = await readFile(openApiPath, "utf8");
  const spec = JSON.parse(raw);
  const schemas = spec.components.schemas;

  assert.equal(spec.openapi, "3.1.0");
  assert.ok(spec.paths["/health"]);
  assert.ok(spec.paths["/metrics"]);
  assert.ok(spec.paths["/api/v1/workflows"]);
  assert.ok(spec.paths["/api/v1/workflows/import"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}"]);
  assert.ok(spec.paths["/api/v1/executions"]);
  assert.ok(spec.paths["/api/v1/executions/{executionId}"]);
  assert.ok(spec.paths["/api/v1/executions/{executionId}/status"]);
  assert.ok(spec.paths["/api/v1/checkpoints"]);
  assert.ok(spec.paths["/api/v1/dashboards/{dashboardId}"]);
  assert.ok(spec.paths["/api/v1/dashboards/{dashboardId}/charts/{chartId}/data"]);
  assert.ok(spec.paths["/api/v1/dashboards/{dashboardId}/charts/{chartId}/export.csv"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/dashboards"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/dashboards/{dashboardId}/publish"]);
  assert.ok(spec.paths["/api/v1/hub/extensions"]);
  assert.ok(spec.paths["/api/v1/hub/extensions/register"]);
  assert.ok(spec.paths["/api/v1/hub/extensions/{extensionId}/install"]);
  assert.ok(spec.paths["/api/v1/admin/auth/policies"]);
  assert.ok(spec.paths["/api/v1/admin/auth/directory"]);
  assert.ok(spec.paths["/api/v1/audit/actions"]);
  assert.ok(spec.components.parameters.DashboardShareToken);
  assert.ok(spec.components.parameters.DashboardWorkspaceToken);
  assert.ok(spec.components.parameters.DashboardAuthorizationHeader);
  assert.ok(schemas.DashboardChartDataResponse);
  assert.ok(schemas.DashboardDatasetRow);
  assert.ok(schemas.DashboardChartSemantic);
  assert.ok(schemas.DashboardChartCache);
  assert.equal(schemas.DashboardChartDataResponse.properties.rowCount.type, "integer");
  assert.ok(schemas.DashboardChartDataResponse.properties.cache);
  assert.ok(schemas.DashboardChartDataResponse.properties.exportFormats);
  assert.ok(schemas.PublishedDashboard.properties.datasets);
  assert.ok(schemas.GatewayAuthDirectory);
  assert.ok(schemas.GatewayUserRecord);
  assert.ok(schemas.GatewayWorkspaceRecord);
  assert.ok(
    spec.paths["/api/v1/dashboards/{dashboardId}"].get.parameters.some(
      (parameter) => parameter.$ref?.endsWith("/DashboardShareToken")
    )
  );
  assert.ok(
    spec.paths["/api/v1/dashboards/{dashboardId}"].get.parameters.some(
      (parameter) => parameter.$ref?.endsWith("/DashboardWorkspaceToken")
    )
  );
  assert.ok(
    spec.paths["/api/v1/dashboards/{dashboardId}"].get.parameters.some(
      (parameter) => parameter.$ref?.endsWith("/DashboardAuthorizationHeader")
    )
  );

  assert.ok(
    spec.paths["/api/v1/workflows"].post.requestBody.content["application/json"].schema.$ref.endsWith(
      "/CreateWorkflowRequest"
    )
  );
  assert.ok(
    spec.paths["/api/v1/workflows/{workflowId}/execute"].post.requestBody.content["application/json"].schema.$ref.endsWith(
      "/ExecuteWorkflowRequest"
    )
  );
  assert.ok(
    spec.paths["/api/v1/executions/{executionId}"].get.responses["200"].content["application/json"].schema.$ref.endsWith(
      "/GatewayExecutionRecord"
    )
  );
  assert.deepEqual(schemas.GatewayExecutionStatus.enum, [
    "accepted",
    "queued",
    "running",
    "completed",
    "failed"
  ]);
  assert.ok(schemas.CreateWorkflowRequest.properties.workflowToml);
  assert.ok(schemas.CreateWorkflowRequest.properties.workflow);
  assert.ok(schemas.ExecuteWorkflowRequest.properties.executionMode);
  assert.ok(schemas.ExecuteWorkflowRequest.properties.flowVariables);
  assert.ok(schemas.GatewayHealthcheck.properties.realtimeTransport);
  assert.ok(schemas.GatewayHealthcheck.properties.eventBackboneMode);
  assert.ok(schemas.GatewayHealthcheck.properties.eventConsumerPollMs);
  assert.ok(schemas.GatewayHealthcheck.properties.streamWorkerMode);
  assert.ok(schemas.GatewayHealthcheck.properties.gpuWorkerMode);
  assert.ok(schemas.GatewayHealthcheck.properties.eventLogSize);
  assert.ok(schemas.GatewayHealthcheck.properties.latestEventSequence);
  assert.ok(schemas.GatewayHealthcheck.properties.gatewayConsumerCursor);
  assert.ok(schemas.GatewayHealthcheck.properties.gatewayConsumerLag);
  assert.ok(schemas.GatewayHealthcheck.properties.eventConsumerCatchupPercent);
  assert.ok(schemas.GatewayHealthcheck.properties.activeStreamExecutions);
  assert.ok(schemas.GatewayHealthcheck.properties.queuedGpuExecutions);
  assert.ok(schemas.GatewayHealthcheck.properties.queuedStreamExecutions);
  assert.ok(schemas.GatewayHealthcheck.properties.activeGpuExecutions);
  assert.ok(schemas.GatewayHealthcheck.properties.gpuWorkerOwnedExecutions);
  assert.ok(schemas.GatewayHealthcheck.properties.queuedExecutionsTotal);
  assert.ok(schemas.GatewayHealthcheck.properties.runningExecutionsTotal);
  assert.ok(schemas.GatewayHealthcheck.properties.otelTraceSeamEnabled);
  assert.ok(schemas.GatewayHealthcheck.properties.observabilitySpanCount);
  assert.ok(schemas.GatewayHealthcheck.properties.observabilityRecentSpanCount);
  assert.ok(schemas.GatewayHealthcheck.properties.lastTraceId);
  assert.ok(schemas.GatewayHealthcheck.properties.lastSpanName);
  assert.ok(schemas.GatewayHealthcheck.properties.authMode);
  assert.ok(schemas.GatewayHealthcheck.properties.authMode.enum.includes("oidc"));
  assert.ok(schemas.GatewayHealthcheck.properties.oidcDiscoveryConfigured);
  assert.ok(schemas.GatewayHealthcheck.properties.oidcJwksConfigured);
  assert.ok(schemas.GatewayHealthcheck.properties.oidcAllowedAlgorithms);
  assert.ok(schemas.GatewayAuthContext);
  assert.deepEqual(schemas.GatewayAuthContext.properties.role.enum, ["owner", "editor", "viewer"]);
  assert.ok(schemas.GatewayAuthContext.properties.mode.enum.includes("oidc"));
  assert.ok(schemas.GatewayOidcProviderConfig);
  assert.ok(schemas.GatewayAuthPolicy);
  assert.ok(schemas.GatewayRoleBinding);
  assert.ok(schemas.GatewayResourcePolicy);
  assert.ok(schemas.GatewayAuditQueryResponse);
  assert.ok(schemas.WorkflowContainerDefinition);
  assert.ok(schemas.WorkflowComponentDefinition);
  assert.ok(schemas.WorkflowControlFlowDefinition);
  assert.ok(schemas.ControlFlowCaseDefinition);
  assert.ok(schemas.CreateWorkflowRequest.properties.workflow.properties.containers);
  assert.ok(schemas.CreateWorkflowRequest.properties.workflow.properties.components);
  assert.ok(schemas.CreateWorkflowRequest.properties.workflow.properties.controlFlow);
  assert.ok(schemas.WorkflowDetail.properties.containers);
  assert.ok(schemas.WorkflowDetail.properties.components);
  assert.ok(schemas.WorkflowDetail.properties.controlFlow);
  assert.ok(schemas.WorkflowDetail.properties.graphRevision);
  assert.ok(schemas.WorkflowDetail.properties.dashboardCount);
  assert.ok(schemas.WorkflowDetail.properties.runMode);
  assert.ok(schemas.WorkflowDetail.properties.graph);
  assert.ok(schemas.WorkflowDetail.properties.dashboards);
  assert.ok(schemas.WorkflowDetail.properties.runtime);
  assert.ok(schemas.WorkflowDetail.properties.biOutlets);
  assert.ok(schemas.GatewayExecutionRecord.properties.resourcePlan);
  assert.ok(schemas.GatewayExecutionRecord.properties.controlFlowPlan);
  assert.equal(schemas.GatewayControlFlowPlanEntry.oneOf.length, 2);
  assert.ok(schemas.GatewayLoopControlFlowPlanEntry);
  assert.ok(schemas.GatewayTryCatchControlFlowPlanEntry);
  assert.ok(schemas.GatewayControlFlowPlanEntry.properties.bodyNodeIds);
  assert.ok(schemas.GatewayControlFlowPlanEntry.properties.tryNodeIds);
  assert.ok(schemas.GatewayControlFlowPlanEntry.properties.catchNodeIds);
  assert.deepEqual(schemas.GatewayControlFlowPlanEntry.properties.kind.enum, ["loop", "try_catch"]);
  assert.ok(schemas.GatewayExecutionRecord.properties.dispatchPlan);
  assert.ok(schemas.GatewayExecutionRecord.properties.dispatchLane);
  assert.ok(schemas.GatewayExecutionRecord.properties.dispatchWorkerPool);
  assert.ok(schemas.GatewayExecutionRecord.properties.dispatchIsolationMode);
  assert.ok(schemas.GatewayExecutionRecord.properties.dispatchAccelerator);
  assert.ok(schemas.GatewayExecutionRecord.properties.dispatchSchedulerPolicy);
  assert.ok(schemas.GatewayExecutionRecord.properties.dispatchPlacementReason);
  assert.ok(schemas.GatewayExecutionRecord.properties.dispatchRequestedDevice);
  assert.ok(schemas.GatewayExecutionRecord.properties.dispatchWorkerCapacity);
  assert.ok(schemas.GatewayExecutionRecord.properties.observabilityTrace);
  assert.ok(schemas.ObservabilityTraceRecord.properties.spans);
  assert.ok(schemas.ObservabilitySpanRecord.properties.duration_ms);
  assert.ok(schemas.GatewayExecutionRecord.properties.workerId);
  assert.ok(schemas.GatewayExecutionRecord.properties.streamLifecycleStatus);
  assert.ok(schemas.GatewayExecutionRecord.properties.streamAdapter);
  assert.ok(schemas.GatewayExecutionRecord.properties.streamAdapterContract);
  assert.ok(schemas.GatewayExecutionRecord.properties.streamConsumerLag);
  assert.ok(schemas.GatewayExecutionRecord.properties.streamWindowState);
  assert.ok(schemas.GatewayExecutionRecord.properties.streamWatermarkState);
  assert.ok(schemas.GatewayExecutionRecord.properties.streamCommittedOffset);
  assert.ok(schemas.GatewayExecutionRecord.properties.streamSinkTransactionId);
  assert.ok(schemas.GatewayExecutionRecord.properties.streamSinkTransactionState);
  assert.ok(schemas.GatewayExecutionRecord.properties.streamIdempotencyKey);
  assert.ok(schemas.GatewayExecutionRecord.properties.streamExactlyOnceStatus);
  assert.ok(schemas.GatewayExecutionRecord.properties.gpuExecutionPath);
  assert.ok(schemas.GatewayExecutionRecord.properties.gpuWorkloadResult);
  assert.ok(schemas.GatewayExecutionRecord.properties.gpuCpuFallbackUsed);
  assert.ok(schemas.GatewayExecutionRecord.properties.gpuPlacementFallbackUsed);
  assert.ok(schemas.GatewayExecutionRecord.properties.gpuRequestSatisfied);
  assert.ok(schemas.GatewayExecutionRecord.properties.gpuRequestedDevice);
  assert.ok(schemas.GatewayExecutionRecord.properties.gpuSelectedDevice);
  assert.ok(schemas.GatewayExecutionRecord.properties.gpuFallbackReason);
  assert.ok(schemas.GatewayExecutionRecord.properties.gpuPlacementReason);
  assert.ok(schemas.GatewayExecutionRecord.properties.gpuSchedulerPolicy);
  assert.ok(schemas.GatewayExecutionRecord.properties.gpuWorkerIsolationMode);
  assert.ok(schemas.GatewayExecutionRecord.properties.gpuWorkerCapacity);
  assert.ok(schemas.CreateCheckpointResponse.properties.checkpoint);
  assert.ok(schemas.CreateCheckpointResponse.properties.checkpointCount);
  assert.ok(schemas.HubExtensionListResponse.properties.items);
  assert.ok(schemas.HubExtensionRecord.properties.compatibility);
  assert.ok(schemas.HubExtensionRecord.properties.trust);
  assert.ok(schemas.HubExtensionRecord.properties.upgrade);
  assert.ok(schemas.HubExtensionRecord.properties.manifest.properties.artifactHashes);
  assert.ok(schemas.HubExtensionRecord.properties.manifest.properties.compatibilitySandboxCommand);
  assert.ok(schemas.HubExtensionRecord.properties.manifest.properties.mirrorRefs);
  assert.ok(schemas.HubCompatibilityResult.properties.blockers);
  assert.ok(schemas.HubRegisterRequest.properties.manifest);
  assert.ok(schemas.HubRegisterResponse.properties.extension);
  assert.deepEqual(schemas.HubInstallRequest.properties.action.enum, [
    "install",
    "enable",
    "disable",
    "upgrade"
  ]);
  assert.ok(schemas.PublishedDashboard.properties.charts);
  assert.ok(schemas.PublishedDashboard.properties.visibility);
  assert.ok(schemas.DashboardPublishResponse.properties.dashboard);
});

test("jsonrpc protocol exposes execution and dashboard channels", async () => {
  const raw = await readFile(jsonRpcPath, "utf8");
  const protocol = JSON.parse(raw);
  const methodNames = protocol.methods.map((method) => method.name);

  assert.ok(methodNames.includes("workflow.execute"));
  assert.ok(methodNames.includes("dashboard.subscribe"));
  assert.ok(protocol.events.includes("execution.state.changed"));
  assert.ok(protocol.events.includes("dashboard.published"));
  assert.ok(protocol.events.includes("streaming.checkpoint.completed"));
});

test("event schema exposes durable envelope and backbone event types", async () => {
  const raw = await readFile(eventsSchemaPath, "utf8");
  const schema = JSON.parse(raw);
  const durableEvent = schema.properties.durableEvent;

  assert.ok(durableEvent);
  assert.deepEqual(durableEvent.required, [
    "eventId",
    "eventType",
    "aggregateType",
    "aggregateId",
    "occurredAt",
    "sequence",
    "producer",
    "payloadVersion",
    "payload"
  ]);
  assert.deepEqual(durableEvent.properties.eventType.enum, [
    "execution.changed",
    "stream.checkpoint.completed",
    "repository.save.changed",
    "hub.extension.changed",
    "dashboard.published",
    "audit.action",
    "auth.policy.changed",
    "auth.directory.changed"
  ]);
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
