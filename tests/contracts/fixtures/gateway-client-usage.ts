import {
  createGatewayApiClient,
  gatewayEndpointPaths,
  gatewayExecutionStatuses,
  milestoneCheckpoints,
  type CreateCheckpointRequest,
  type CreateWorkflowRequest,
  type GatewayDataImportProfileRequest,
  type GatewayExecutionStatus,
  type GatewayMlExperimentRunRequest,
  type GatewayModelRegistryRequest,
  type GatewayTransformRunRequest,
  type GatewayVisualizeCheckpointExportRequest,
  type MilestoneCheckpointTag,
  type TransitionExecutionStatusRequest
} from "../../../packages/contracts/src/index";

const workflowRequest: CreateWorkflowRequest = {
  workflowToml: 'version = "0.1.0"'
};

const checkpointRequest: CreateCheckpointRequest = {
  tag: "cp/01-contracts-frozen",
  summary: "Contracts locked for parallel lanes"
};

const executionStatus: GatewayExecutionStatus = "queued";
const milestoneTag: MilestoneCheckpointTag = milestoneCheckpoints[1].tag;

const transitionRequest: TransitionExecutionStatusRequest = {
  status: executionStatus,
  message: `Moved to ${executionStatus}`,
  metadata: { lane: "contracts" }
};
const dataProfileRequest: GatewayDataImportProfileRequest = {
  datasetId: "contracts-profile",
  sourceUri: "local://data/raw/contracts.csv",
  targetZone: "raw"
};
const transformRunRequest: GatewayTransformRunRequest = {
  executionMode: "cpu_only",
  flowVariables: { JULIAFLOW_GPU_DEVICE: "cpu" }
};
const mlExperimentRunRequest: GatewayMlExperimentRunRequest = {
  executionMode: "gpu_preferred",
  datasetId: "foundation-sales-sample",
  target: "amount",
  algorithm: "deterministic_linear_baseline",
  flowVariables: { JULIAFLOW_GPU_DEVICE: "cpu" }
};
const modelRegistryRequest: GatewayModelRegistryRequest = {
  modelId: "foundation-linear-baseline",
  status: "registered",
  tags: ["local", "checkpointed"],
  owner: "local-user"
};
const visualizeCheckpointExportRequest: GatewayVisualizeCheckpointExportRequest = {
  checkpointTag: "cp/visualize-contracts",
  summary: "Visualize contracts checkpoint",
  visibility: "workspace",
  notes: "typed client fixture"
};

const client = createGatewayApiClient({
  baseUrl: "http://127.0.0.1:8088",
  fetch: async () =>
    new Response(
      JSON.stringify({
        service: "api-gateway",
        status: "ok",
        repositoryBackend: "FileGatewayRepository",
        storeRoot: "/tmp/juliaflow",
        workflowCount: 1,
        checkpointCount: 1,
        executionCount: 0
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" }
      }
    )
});

client.healthcheck();
client.createWorkflow(workflowRequest);
client.createCheckpoint(checkpointRequest);
client.transitionExecutionStatus("exec-1", transitionRequest);
client.importDataProfile(dataProfileRequest);
client.runWorkflowTransform("wf-foundation", transformRunRequest);
client.getWorkflowTransformHistory("wf-foundation");
client.runWorkflowMlExperiment("wf-foundation", mlExperimentRunRequest);
client.getWorkflowMlExperimentHistory("wf-foundation");
client.registerWorkflowModel("wf-foundation", modelRegistryRequest);
client.listWorkflowModels("wf-foundation");
client.exportVisualizeCheckpoint("wf-foundation", "dashboard-foundation", visualizeCheckpointExportRequest);

gatewayEndpointPaths.workflowDetail("foundation/workflow");
gatewayEndpointPaths.executionStatus("exec-1");
gatewayEndpointPaths.localDataImport;
gatewayEndpointPaths.workflowTransformRun("wf-foundation");
gatewayEndpointPaths.workflowTransformHistory("wf-foundation");
gatewayEndpointPaths.workflowMlExperimentRun("wf-foundation");
gatewayEndpointPaths.workflowMlExperimentHistory("wf-foundation");
gatewayEndpointPaths.workflowModelRegister("wf-foundation");
gatewayEndpointPaths.workflowModels("wf-foundation");
gatewayEndpointPaths.workflowVisualizeCheckpointExport("wf-foundation", "dashboard-foundation");
gatewayExecutionStatuses satisfies readonly GatewayExecutionStatus[];
milestoneTag satisfies MilestoneCheckpointTag;
