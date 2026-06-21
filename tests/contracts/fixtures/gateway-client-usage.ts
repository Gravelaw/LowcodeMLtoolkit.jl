import {
  createGatewayApiClient,
  gatewayEndpointPaths,
  gatewayExecutionStatuses,
  milestoneCheckpoints,
  type CreateDataScienceProjectRequest,
  type CreateCheckpointRequest,
  type CreateWorkflowRequest,
  type GatewayDataImportProfileRequest,
  type GatewayDeployPackageRequest,
  type GatewayExecutionStatus,
  type GatewayMlExperimentRunRequest,
  type GatewayModelRegistryRequest,
  type GatewayTransformRunRequest,
  type GatewayVisualizeCheckpointExportRequest,
  type RunDriftReportRequest,
  type RunFinalEvaluationRequest,
  type RunPredictionExportRequest,
  type RunStatisticalAnalysisRequest,
  type RunTransformFitApplyRequest,
  type RunTuningStudyRequest,
  type UpdateDataScienceProjectRequest,
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
  targetZone: "raw",
  readMode: "duckdb"
};
const dataScienceProjectRequest: CreateDataScienceProjectRequest = {
  projectId: "contracts-project",
  name: "Contracts Project",
  description: "Typed client fixture",
  datasets: [
    {
      datasetId: "contracts-train",
      name: "Contracts train",
      role: "train",
      sourceUri: "local://data/raw/contracts.csv",
      localOnly: true,
      rowCount: 12,
      columnCount: 3
    }
  ]
};
const dataScienceProjectUpdateRequest: UpdateDataScienceProjectRequest = {
  splitPlans: [
    {
      splitPlanId: "split-contracts",
      datasetId: "contracts-train",
      strategy: "stratified",
      trainFraction: 0.7,
      validationFraction: 0.15,
      testFraction: 0.15,
      seed: 42,
      locked: true,
      createdAt: "2026-06-21T00:00:00Z"
    }
  ]
};
const statisticalAnalysisRequest: RunStatisticalAnalysisRequest = {
  datasetId: "contracts-train",
  methods: ["summary", "pearson_correlation", "anova"],
  targetColumn: "amount",
  featureColumns: ["region", "discount"]
};
const transformFitApplyRequest: RunTransformFitApplyRequest = {
  datasetId: "contracts-train",
  splitPlanId: "split-contracts",
  transformRef: "local://transforms/contracts/fit-apply.jl",
  fitSplit: "train",
  applySplits: ["validation", "test"]
};
const tuningStudyRequest: RunTuningStudyRequest = {
  datasetId: "contracts-train",
  splitPlanId: "split-contracts",
  targetColumn: "amount",
  taskType: "regression",
  algorithm: "MLJ.EvoTreesRegressor",
  metricNames: ["rmse", "mae"],
  maxTrials: 3,
  finalTestPolicy: "forbid_final_test"
};
const finalEvaluationRequest: RunFinalEvaluationRequest = {
  datasetId: "contracts-train",
  splitPlanId: "split-contracts",
  trainingPlanId: "training-contracts",
  tuningStudyId: "tuning-contracts",
  metricNames: ["rmse", "mae"],
  approvalThreshold: 0.8,
  finalTestPolicy: "use_final_test"
};
const predictionExportRequest: RunPredictionExportRequest = {
  datasetId: "contracts-train",
  evaluationReportId: "eval-contracts",
  outputContractRef: "contract://outputs/churn-predictions",
  format: "csv",
  rowCount: 12
};
const driftReportRequest: RunDriftReportRequest = {
  datasetId: "contracts-train",
  predictionExportId: "pred-contracts",
  baselineId: "baseline-contracts",
  metricNames: ["psi", "ks"],
  threshold: 0.2
};
const transformRunRequest: GatewayTransformRunRequest = {
  executionMode: "cpu_only",
  flowVariables: { JULIAFLOW_GPU_DEVICE: "cpu" }
};
const mlExperimentRunRequest: GatewayMlExperimentRunRequest = {
  executionMode: "gpu_preferred",
  projectId: "foundation-project",
  datasetId: "foundation-sales-sample",
  splitPlanId: "split-foundation-stratified",
  finalTestPolicy: "forbid_final_test",
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
const deployPackageRequest: GatewayDeployPackageRequest = {
  modelId: "foundation-linear-baseline",
  endpointPath: "/v1/predict",
  host: "127.0.0.1",
  port: 8000,
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
client.listDataScienceProjects();
client.createDataScienceProject(dataScienceProjectRequest);
client.getDataScienceProject("contracts-project");
client.updateDataScienceProject("contracts-project", dataScienceProjectUpdateRequest);
client.runDataScienceProjectTransformFitApply("contracts-project", transformFitApplyRequest);
client.runDataScienceProjectStatisticalAnalysis("contracts-project", statisticalAnalysisRequest);
client.runDataScienceProjectTuningStudy("contracts-project", tuningStudyRequest);
client.runDataScienceProjectFinalEvaluation("contracts-project", finalEvaluationRequest);
client.runDataScienceProjectPredictionExport("contracts-project", predictionExportRequest);
client.runDataScienceProjectDriftReport("contracts-project", driftReportRequest);
client.runWorkflowTransform("wf-foundation", transformRunRequest);
client.getWorkflowTransformHistory("wf-foundation");
client.runWorkflowMlExperiment("wf-foundation", mlExperimentRunRequest);
client.getWorkflowMlExperimentHistory("wf-foundation");
client.registerWorkflowModel("wf-foundation", modelRegistryRequest);
client.listWorkflowModels("wf-foundation");
client.exportVisualizeCheckpoint("wf-foundation", "dashboard-foundation", visualizeCheckpointExportRequest);
client.packageWorkflowDeploy("wf-foundation", deployPackageRequest);
client.listWorkflowDeployPackages("wf-foundation");

gatewayEndpointPaths.workflowDetail("foundation/workflow");
gatewayEndpointPaths.executionStatus("exec-1");
gatewayEndpointPaths.localDataImport;
gatewayEndpointPaths.dataScienceProjects;
gatewayEndpointPaths.dataScienceProject("contracts-project");
gatewayEndpointPaths.dataScienceProjectTransformFitApply("contracts-project");
gatewayEndpointPaths.dataScienceProjectStatisticalAnalysisRun("contracts-project");
gatewayEndpointPaths.dataScienceProjectTuningRun("contracts-project");
gatewayEndpointPaths.dataScienceProjectFinalEvaluationRun("contracts-project");
gatewayEndpointPaths.dataScienceProjectPredictionExport("contracts-project");
gatewayEndpointPaths.dataScienceProjectDriftRun("contracts-project");
gatewayEndpointPaths.workflowTransformRun("wf-foundation");
gatewayEndpointPaths.workflowTransformHistory("wf-foundation");
gatewayEndpointPaths.workflowMlExperimentRun("wf-foundation");
gatewayEndpointPaths.workflowMlExperimentHistory("wf-foundation");
gatewayEndpointPaths.workflowModelRegister("wf-foundation");
gatewayEndpointPaths.workflowModels("wf-foundation");
gatewayEndpointPaths.workflowVisualizeCheckpointExport("wf-foundation", "dashboard-foundation");
gatewayEndpointPaths.workflowDeployPackage("wf-foundation");
gatewayEndpointPaths.workflowDeployPackages("wf-foundation");
gatewayExecutionStatuses satisfies readonly GatewayExecutionStatus[];
milestoneTag satisfies MilestoneCheckpointTag;
