import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import test from "node:test";
import { parse } from "smol-toml";

const execFileAsync = promisify(execFile);
const fixturePath = new URL("./fixtures/foundation.workflow.toml", import.meta.url);
const openApiPath = new URL("../../packages/contracts/openapi/openapi.json", import.meta.url);
const jsonRpcPath = new URL("../../packages/contracts/protocol/jsonrpc.json", import.meta.url);
const eventsSchemaPath = new URL("../../packages/contracts/schemas/events.schema.json", import.meta.url);
const repoRoot = fileURLToPath(new URL("../..", import.meta.url));

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
  assert.ok(spec.paths["/api/v1/reproducibility-bundles"]);
  assert.ok(spec.paths["/api/v1/reproducibility-bundles/import"]);
  assert.ok(spec.paths["/api/v1/local-backups"]);
  assert.ok(spec.paths["/api/v1/local-backups/import"]);
  assert.ok(spec.paths["/api/v1/local-data/import"]);
  assert.ok(spec.paths["/api/v1/data-science-projects"]);
  assert.ok(spec.paths["/api/v1/data-science-projects/{projectId}"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/transforms/run"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/transforms/history"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/ml/experiments/run"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/ml/experiments"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/models/register"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/models"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/deploy/package"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/deploy/packages"]);
  assert.ok(spec.paths["/api/v1/dashboards/{dashboardId}"]);
  assert.ok(spec.paths["/api/v1/dashboards/{dashboardId}/charts/{chartId}/data"]);
  assert.ok(spec.paths["/api/v1/dashboards/{dashboardId}/charts/{chartId}/export.csv"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/dashboards"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/dashboards/{dashboardId}/publish"]);
  assert.ok(spec.paths["/api/v1/workflows/{workflowId}/dashboards/{dashboardId}/checkpoint-export"]);
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
  assert.ok(schemas.JuliaFlowRuntimeContract);
  assert.deepEqual(schemas.JuliaFlowRuntimeContract.properties.mode.enum, [
    "demo",
    "development",
    "release",
    "local-appliance"
  ]);
  assert.ok(schemas.JuliaFlowUnavailableState);
  assert.ok(schemas.GatewayHealthcheck.properties.runtime);
  assert.ok(schemas.GatewayHealthcheck.properties.runtimeMode);
  assert.ok(schemas.GatewayHealthcheck.properties.fixtureProvenance);
  assert.ok(schemas.GatewayHealthcheck.properties.fixtureSubstitutionAllowed);
  assert.ok(schemas.GatewayHealthcheck.properties.unavailable);
  assert.ok(schemas.GatewayHealthcheck.required.includes("runtime"));
  assert.ok(schemas.GatewayHealthcheck.required.includes("fixtureSubstitutionAllowed"));
  assert.ok(schemas.GatewayHealthcheck.properties.localProfile);
  assert.ok(schemas.GatewayHealthcheck.properties.localHome);
  assert.ok(schemas.GatewayHealthcheck.properties.metadataMode);
  assert.deepEqual(schemas.GatewayHealthcheck.properties.metadataMode.enum, ["single-user", "lab-team"]);
  assert.ok(schemas.GatewayHealthcheck.properties.metadataBackend);
  assert.deepEqual(schemas.GatewayHealthcheck.properties.metadataBackend.enum, ["file", "postgres"]);
  assert.ok(schemas.GatewayHealthcheck.properties.metadataRoot);
  assert.ok(schemas.GatewayHealthcheck.properties.metadataReady);
  assert.ok(schemas.GatewayHealthcheck.properties.metadataSchemaStatus);
  assert.ok(schemas.GatewayHealthcheck.properties.metadataConcurrencyStatus);
  assert.ok(schemas.GatewayHealthcheck.properties.metadataCapabilities);
  assert.ok(schemas.GatewayHealthcheck.required.includes("metadataReady"));
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateRoot);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateZones);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateReady);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateManaged);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateManifestPath);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateManifestReady);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateManifestChecksums);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateArtifactFormats);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateQuotaBytes);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateUsedBytes);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateCleanupStatus);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateBackupRoot);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateBackupStatus);
  assert.ok(schemas.GatewayHealthcheck.properties.localBackupRestoreReady);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateDuckdbStatus);
  assert.ok(schemas.GatewayHealthcheck.properties.dataEstateDuckdbQueryPath);
  assert.ok(schemas.GatewayHealthcheck.required.includes("dataEstateManifestReady"));
  assert.ok(schemas.GatewayDataEstateManifestChecksum);
  assert.ok(schemas.GatewayDataEstateManifestChecksum.properties.checksumSha256);
  assert.ok(schemas.GatewayHealthcheck.properties.freeDiskStatus);
  assert.ok(schemas.GatewayHealthcheck.properties.freeDiskBytes);
  assert.ok(schemas.GatewayHealthcheck.properties.localServiceUrls);
  assert.ok(schemas.GatewayHealthcheck.properties.postgresProfileStatus);
  assert.ok(schemas.GatewayHealthcheck.properties.minioProfileStatus);
  assert.ok(schemas.GatewayHealthcheck.properties.cloudCredentialsRequired);
  assert.ok(schemas.GatewayHealthcheck.properties.cpuThreadCount);
  assert.ok(schemas.GatewayHealthcheck.properties.totalMemoryBytes);
  assert.ok(schemas.GatewayHealthcheck.properties.freeMemoryBytes);
  assert.ok(schemas.GatewayHealthcheck.properties.hardwareProfileStatus);
  assert.deepEqual(schemas.GatewayHealthcheck.properties.hardwareProfileStatus.enum, ["ready", "degraded"]);
  assert.ok(schemas.GatewayHealthcheck.properties.hardwareSelectedBackend);
  assert.deepEqual(schemas.GatewayHealthcheck.properties.hardwareSelectedBackend.enum, ["cpu", "cuda", "simulated_cuda"]);
  assert.ok(schemas.GatewayHealthcheck.properties.cpuSchedulerPolicy);
  assert.ok(schemas.GatewayHealthcheck.properties.cpuWorkerConcurrency);
  assert.ok(schemas.GatewayHealthcheck.properties.cpuMemoryLimitBytes);
  assert.ok(schemas.GatewayHealthcheck.properties.gpuReadinessStatus);
  assert.ok(schemas.GatewayHealthcheck.properties.gpuFallbackReason);
  assert.ok(schemas.GatewayHealthcheck.properties.gpuCudaStatus);
  assert.ok(schemas.GatewayHealthcheck.properties.gpuHardwareDeviceCount);
  assert.ok(schemas.GatewayHealthcheck.properties.gpuSimulatedDeviceCount);
  assert.ok(schemas.GatewayHealthcheck.properties.gpuTotalVramBytes);
  assert.ok(schemas.GatewayHealthcheck.properties.gpuDeviceSummaries);
  assert.ok(schemas.GatewayGpuDeviceSummary.properties.memoryBytes);
  assert.ok(schemas.GatewayExplainabilityEvidence);
  assert.ok(schemas.GatewayDatasetCardEvidence.properties.checksumSha256);
  assert.ok(schemas.GatewayModelCardEvidence.properties.metrics);
  assert.ok(schemas.GatewayExplanationEvidence.properties.featureImportance);
  assert.ok(schemas.GatewayHealthcheck.properties.explainabilityEvidence);
  assert.ok(schemas.GatewayHealthcheck.required.includes("explainabilityEvidence"));
  assert.ok(schemas.GatewayHealthcheck.properties.hubCacheRoot);
  assert.ok(schemas.GatewayHealthcheck.properties.hubArtifactStorePath);
  assert.ok(schemas.GatewayHealthcheck.properties.hubMirrorRegistryPath);
  assert.ok(schemas.GatewayHealthcheck.properties.hubArtifactCacheRoot);
  assert.ok(schemas.GatewayHealthcheck.properties.hubCacheStatus);
  assert.ok(schemas.GatewayHealthcheck.properties.hubOfflineInstallReady);
  assert.ok(schemas.GatewayHealthcheck.properties.hubBundledExtensionCount);
  assert.ok(schemas.GatewayHealthcheck.properties.hubInstalledLocalExtensionCount);
  assert.ok(schemas.GatewayHealthcheck.required.includes("hubOfflineInstallReady"));
  assert.ok(schemas.GatewayHealthcheck.required.includes("hardwareProfileStatus"));
  assert.ok(schemas.GatewayHealthcheck.required.includes("gpuDeviceSummaries"));
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
  assert.ok(schemas.GatewayDataEstateZoneStatus);
  assert.ok(schemas.GatewayLocalServiceUrls);
  assert.ok(schemas.DataImportProfileResponse);
  assert.ok(schemas.DataImportProfile.properties.artifactRef);
  assert.ok(schemas.DataImportProfileRequest.properties.readMode);
  assert.ok(schemas.DataImportProfile.properties.sourceOptions);
  assert.ok(schemas.DataImportProfile.properties.lineageArtifacts);
  assert.ok(schemas.DataImportProfile.properties.qualityChecks);
  assert.ok(schemas.DataImportProfile.properties.workflowReadiness);
  assert.ok(schemas.DataImportProfile.properties.quickPlots);
  assert.ok(schemas.DataImportProfile.properties.previewRows);
  assert.ok(schemas.DataScienceProject);
  assert.ok(schemas.DataScienceProject.properties.schemaVersion);
  assert.deepEqual(schemas.DataScienceProject.properties.schemaVersion.enum, ["1.0"]);
  assert.ok(schemas.ProjectDataset);
  assert.deepEqual(schemas.ProjectDataset.properties.role.enum, [
    "train",
    "validation",
    "test",
    "evaluation",
    "output",
    "reference"
  ]);
  assert.ok(schemas.SchemaContract);
  assert.ok(schemas.DatasetSplitPlan);
  assert.ok(schemas.DataScienceProjectListResponse);
  assert.ok(schemas.CreateDataScienceProjectRequest.required.includes("name"));
  assert.equal(schemas.UpdateDataScienceProjectRequest.additionalProperties, false);
  assert.ok(schemas.UpdateDataScienceProjectRequest.properties.schemaContracts);
  assert.ok(schemas.UpdateDataScienceProjectRequest.properties.splitPlans);
  assert.ok(schemas.UpdateDataScienceProjectRequest.properties.finalTestLocks);
  assert.ok(schemas.TransformRunResponse);
  assert.ok(schemas.TransformRunRecord.properties.artifactEvidence);
  assert.ok(schemas.TransformHistoryResponse);
  assert.ok(schemas.MlExperimentRunResponse);
  assert.ok(schemas.MlExperimentRunRequest.properties.projectId);
  assert.ok(schemas.MlExperimentRunRequest.properties.splitPlanId);
  assert.deepEqual(schemas.MlExperimentRunRequest.properties.finalTestPolicy.enum, ["forbid_final_test", "use_final_test"]);
  assert.ok(schemas.MlExperimentRecord.properties.metrics);
  assert.ok(schemas.MlExperimentRecord.properties.featureImportance);
  assert.ok(schemas.MlExperimentRecord.properties.artifactEvidence);
  assert.ok(schemas.MlExperimentRecord.properties.validationEvidence);
  assert.ok(schemas.MlExperimentHistoryResponse);
  assert.ok(schemas.ModelRegistryResponse);
  assert.ok(schemas.ModelRegistryRecord.properties.primaryMetricName);
  assert.ok(schemas.ModelRegistryRecord.properties.artifactEvidence);
  assert.ok(schemas.ModelRegistryRecord.properties.validationEvidence);
  assert.ok(schemas.ModelRegistryListResponse);
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
  assert.ok(schemas.GatewayExecutionRecord.properties.controlFlowRecovery);
  assert.ok(schemas.GatewayExecutionRecord.properties.controlFlowBranchState);
  assert.ok(schemas.GatewayControlFlowRecovery.properties.catchNodeIds);
  assert.ok(schemas.GatewayControlFlowBranchState.properties.nodeResults);
  assert.ok(schemas.GatewayControlFlowBranchNodeResult.properties.rowCount);
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
  assert.ok(schemas.GatewayExecutionRecord.properties.explainabilityEvidence);
  assert.ok(schemas.CheckpointRecord.properties.explainabilityEvidence);
  assert.ok(schemas.CreateCheckpointResponse.properties.checkpoint);
  assert.ok(schemas.CreateCheckpointResponse.properties.checkpointCount);
  assert.ok(schemas.ReproducibilityBundle);
  assert.ok(schemas.ReproducibilityBundle.properties.workflow);
  assert.ok(schemas.ReproducibilityBundle.properties.checkpoint);
  assert.ok(schemas.ReproducibilityBundle.properties.dataReferences);
  assert.ok(schemas.ReproducibilityBundle.properties.datasetCards);
  assert.ok(schemas.ReproducibilityBundle.properties.packageEnvironment);
  assert.ok(schemas.ReproducibilityBundle.properties.runtimeConfig);
  assert.ok(schemas.ReproducibilityBundle.properties.randomSeeds);
  assert.ok(schemas.ReproducibilityBundle.properties.modelArtifact);
  assert.ok(schemas.ReproducibilityBundle.properties.metrics);
  assert.ok(schemas.ReproducibilityBundle.properties.explainabilityOutputs);
  assert.ok(schemas.ReproducibilityBundle.properties.dashboardSnapshot);
  assert.ok(schemas.ReproducibilityBundle.properties.bundleChecksumSha256);
  assert.ok(schemas.ReproducibilityBundleExportRequest.properties.workflowId);
  assert.ok(schemas.ReproducibilityBundleExportResponse.properties.bundle);
  assert.ok(schemas.ReproducibilityBundleImportRequest.properties.bundle);
  assert.ok(schemas.ReproducibilityBundleImportResponse.properties.bundleChecksumSha256);
  assert.ok(schemas.VisualizeCheckpointExportRequest.properties.checkpointTag);
  assert.ok(schemas.VisualizeCheckpointExportRequest.properties.visibility);
  assert.ok(schemas.VisualizeCheckpointExportRecord.properties.artifactEvidence);
  assert.ok(schemas.VisualizeCheckpointExportRecord.properties.bundleChecksumSha256);
  assert.ok(schemas.VisualizeCheckpointExportResponse.properties.checkpoint);
  assert.ok(schemas.VisualizeCheckpointExportResponse.properties.dashboard);
  assert.ok(schemas.VisualizeCheckpointExportResponse.properties.bundle);
  assert.ok(schemas.DeployPackageRequest.properties.endpointPath);
  assert.ok(schemas.DeployPackageRecord.properties.packageChecksumSha256);
  assert.ok(schemas.DeployPackageRecord.properties.artifactEvidence);
  assert.ok(schemas.DeployPackageRecord.properties.validationEvidence);
  assert.ok(schemas.DeployPackageResponse.properties.package);
  assert.ok(schemas.DeployPackageHistoryResponse.properties.items);
  assert.ok(schemas.LocalBackupBundle);
  assert.ok(schemas.LocalBackupBundle.properties.dataEstate);
  assert.ok(schemas.LocalBackupBundle.properties.workflows);
  assert.ok(schemas.LocalBackupBundle.properties.checkpoints);
  assert.ok(schemas.LocalBackupBundle.properties.executions);
  assert.ok(schemas.LocalBackupBundle.properties.publishedDashboards);
  assert.ok(schemas.LocalBackupBundle.properties.hubExtensions);
  assert.ok(schemas.LocalBackupBundle.properties.authPolicy);
  assert.ok(schemas.LocalBackupBundle.properties.authDirectory);
  assert.ok(schemas.LocalBackupBundle.properties.backupChecksumSha256);
  assert.ok(schemas.LocalBackupArtifact.properties.relativePath);
  assert.ok(schemas.LocalBackupExportRequest.properties.includeExecutions);
  assert.ok(schemas.LocalBackupExportResponse.properties.backup);
  assert.ok(schemas.LocalBackupImportRequest.properties.backup);
  assert.ok(schemas.LocalBackupImportResponse.properties.missingArtifacts);
  assert.ok(schemas.LocalBackupImportResponse.properties.checkedArtifacts);
  assert.ok(schemas.LocalBackupImportResponse.properties.checksumMismatches);
  assert.ok(schemas.HubExtensionListResponse.properties.items);
  assert.ok(schemas.HubExtensionRecord.properties.compatibility);
  assert.ok(schemas.HubExtensionRecord.properties.trust);
  assert.ok(schemas.HubExtensionRecord.properties.upgrade);
  assert.ok(schemas.HubExtensionRecord.properties.verification);
  assert.ok(schemas.HubExtensionVerification.properties.sandbox);
  assert.ok(schemas.HubVerificationCheck.properties.blockers);
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
    process.execPath,
    ["node_modules/typescript/bin/tsc", "--noEmit", "-p", "packages/contracts/tsconfig.json"],
    {
      cwd: repoRoot
    }
  );
});
