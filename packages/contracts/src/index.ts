export const workflowPortTypes = [
  "data_table",
  "model",
  "flow_variable",
  "image",
  "stream_channel",
  "gpu_buffer"
] as const;

export const workflowStatuses = [
  "idle",
  "configured",
  "running",
  "executed",
  "error",
  "streaming_active"
] as const;

export type WorkflowPortType = (typeof workflowPortTypes)[number];
export type WorkflowStatus = (typeof workflowStatuses)[number];
export type ExecutionHint = "cpu_only" | "gpu_preferred" | "gpu_required";
export const gatewayExecutionStatuses = [
  "accepted",
  "queued",
  "running",
  "completed",
  "failed"
] as const;
export type GatewayExecutionStatus = (typeof gatewayExecutionStatuses)[number];

export interface FlowVariableDefinition {
  name: string;
  type: "String" | "Integer" | "Float64" | "Bool" | "DateTime" | "GPUDeviceID";
  default?: string | number | boolean | null;
}

export type WorkflowRunMode = "batch" | "stream";
export type WorkflowResourceClass = "cpu" | "gpu";
export type ComponentFlowVariableScope = "shared" | "isolated";
export type ControlFlowKind = "loop" | "switch" | "try_catch" | "parallel_chunk";
export type LoopIterationMode = "table_rows" | "files" | "parameter_range" | "streaming_batches";
export type NodeExecutionMode = "batch" | "stream" | "hybrid";
export type DashboardChartFamily = "line" | "bar" | "area" | "table" | "metric";
export type StreamingWindowKind = "tumbling" | "sliding";
export type StreamingWatermarkMode = "processing_time" | "event_time";
export type StreamLifecycleStatus = "idle" | "starting" | "active" | "paused" | "stopped";

export type GatewayAuthMode = "disabled" | "dev_token" | "required" | "dev_fallback" | "oidc";
export type JuliaFlowRuntimeMode = "demo" | "development" | "release" | "local-appliance";
export type JuliaFlowFixtureProvenance = "fixture" | "backend" | "unavailable";
export type JuliaFlowUnavailableCapability =
  | "workflows"
  | "workflowMetadata"
  | "executions"
  | "checkpoints"
  | "dashboards"
  | "hub"
  | "auth"
  | "explainability";

export interface JuliaFlowUnavailableState {
  capability: JuliaFlowUnavailableCapability;
  status: "empty" | "error" | "unavailable";
  reason: string;
  recovery: string;
  fixtureSubstituted: boolean;
}

export interface JuliaFlowRuntimeContract {
  mode: JuliaFlowRuntimeMode;
  fixtureProvenance: JuliaFlowFixtureProvenance;
  fixtureSubstitutionAllowed: boolean;
  unavailable: JuliaFlowUnavailableState[];
}

export type GatewayComputeBackend = "cpu" | "cuda" | "simulated_cuda";
export type GatewayGpuPreference = "auto" | "cpu_fallback" | "cuda_required";

export interface GatewayComputeSettings {
  selectedBackend: GatewayComputeBackend;
  cpuWorkerConcurrency: number;
  cpuMemoryLimitBytes: number;
  gpuPreference: GatewayGpuPreference;
  blasThreadCount: number;
  schedulerPolicy: "bounded_threads";
  source: "default" | "profile" | "request";
  updatedAt: string;
}

export interface UpdateGatewayComputeSettingsRequest {
  selectedBackend?: GatewayComputeBackend;
  cpuWorkerConcurrency?: number;
  cpuMemoryLimitBytes?: number;
  gpuPreference?: GatewayGpuPreference;
  blasThreadCount?: number;
}

export type WorkspaceRole = "owner" | "editor" | "viewer";
export type ResourcePermission =
  | "workflow:read"
  | "workflow:write"
  | "workflow:execute"
  | "execution:read"
  | "execution:write"
  | "checkpoint:read"
  | "checkpoint:write"
  | "backup:read"
  | "backup:write"
  | "dashboard:read"
  | "dashboard:publish"
  | "hub:read"
  | "hub:publish"
  | "hub:install"
  | "policy:read"
  | "policy:write"
  | "audit:read";

export interface GatewayAuthContext {
  principalId: string;
  workspaceId: string;
  role: WorkspaceRole;
  mode: GatewayAuthMode;
  permissions: ResourcePermission[];
}

export interface GatewayOidcProviderConfig {
  issuer: string;
  audience: string;
  discoveryPath?: string;
  discoveryUrl?: string;
  jwksPath?: string;
  jwksUrl?: string;
  allowedAlgorithms: string[];
}

export interface GatewayAuditActionEvent {
  action: string;
  targetType: string;
  targetId: string;
  recordedAt: string;
  authContext: GatewayAuthContext;
  details: Record<string, unknown>;
}

export interface GatewayRoleBinding {
  principalId: string;
  workspaceId: string;
  role: WorkspaceRole;
}

export interface GatewayResourcePolicy {
  resourceType: string;
  resourceId: string;
  workspaceId: string;
  permissionsByRole: Partial<Record<WorkspaceRole, ResourcePermission[]>>;
}

export interface GatewayAuthPolicy {
  roleBindings: GatewayRoleBinding[];
  resourcePolicies: GatewayResourcePolicy[];
  updatedAt: string;
}

export interface GatewayUserRecord {
  principalId: string;
  displayName: string;
  email?: string;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface GatewayWorkspaceRecord {
  workspaceId: string;
  name: string;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface GatewayAuthDirectory {
  users: GatewayUserRecord[];
  workspaces: GatewayWorkspaceRecord[];
  updatedAt: string;
}

export interface GatewayAuditQueryResponse {
  events: Array<GatewayAuditActionEvent & { eventId: string; sequence: number; occurredAt: string }>;
  count: number;
  limit: number;
}

export interface WorkflowNodeLayout {
  nodeId: string;
  x: number;
  y: number;
  width?: number;
  checkpointTag?: string;
  notes?: string;
}

export interface WorkflowViewportState {
  x: number;
  y: number;
  zoom: number;
}

export interface WorkflowGraphDefinition {
  revision: number;
  nodeLayouts: WorkflowNodeLayout[];
  viewport?: WorkflowViewportState;
  selectedNodeId?: string;
}

export interface WorkflowContainerDefinition {
  containerId: string;
  name: string;
  nodeIds: string[];
  collapsed?: boolean;
}

export interface WorkflowComponentDefinition {
  componentId: string;
  name: string;
  nodeIds: string[];
  version: string;
  flowVariableScope: ComponentFlowVariableScope;
  dashboardIds?: string[];
}

export interface ControlFlowCaseDefinition {
  caseId: string;
  label: string;
  targetNodeId: string;
}

export interface WorkflowControlFlowDefinition {
  controlId: string;
  kind: ControlFlowKind;
  name?: string;
  startNodeId?: string;
  endNodeId?: string;
  iterationMode?: LoopIterationMode;
  maxIterations?: number;
  selector?: string;
  cases?: ControlFlowCaseDefinition[];
  defaultTargetNodeId?: string;
  tryNodeIds?: string[];
  catchNodeIds?: string[];
  sourceNodeId?: string;
  targetNodeId?: string;
  chunkSize?: number;
  maxConcurrency?: number;
  resourceClass?: WorkflowResourceClass;
}

export interface NodeCapabilityDescriptor {
  executionMode: NodeExecutionMode;
  resourceClass: WorkflowResourceClass;
  accelerator?: "cuda";
  workerPool?: string;
}

export interface DashboardBindingDefinition {
  outletNodeId: string;
  datasetKey: string;
  refreshMode: "manual" | "live";
}

export interface DashboardChartDefinition {
  chartId: string;
  title: string;
  family: DashboardChartFamily;
  xField?: string;
  yField?: string;
  seriesField?: string;
  panel?: DashboardPanelDefinition;
}

export interface DashboardPanelDefinition {
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface DashboardDefinition {
  dashboardId: string;
  name: string;
  binding: DashboardBindingDefinition;
  charts: DashboardChartDefinition[];
}

export type DashboardDatasetRow = Record<string, string | number | boolean | null>;

export interface PublishedDashboardDefinition {
  dashboardId: string;
  workflowId: string;
  name: string;
  version: number;
  publishedAt: string;
  visibility: "workspace" | "public";
  shareToken?: string;
  binding: DashboardBindingDefinition;
  charts: DashboardChartDefinition[];
  datasets?: Record<string, DashboardDatasetRow[]>;
}

export interface GatewayDashboardChartSemantic {
  dimensions: string[];
  measures: string[];
  xField: string;
  yField: string;
  seriesField?: string | null;
  availableDimensions: string[];
  availableMeasures: string[];
}

export interface GatewayDashboardChartCache {
  cacheKey: string;
  sourceVersion: number;
  snapshotAt: string;
  refreshMode: DashboardBindingDefinition["refreshMode"];
  live: boolean;
  stale: boolean;
}

export interface GatewayDashboardChartDataResponse {
  dashboardId: string;
  chartId: string;
  datasetKey: string;
  family: DashboardChartFamily;
  fields: string[];
  rows: DashboardDatasetRow[];
  rowCount: number;
  refreshedAt: string;
  semantic: GatewayDashboardChartSemantic;
  cache: GatewayDashboardChartCache;
  exportFormats: Array<"json" | "csv">;
}

export interface StreamingSourceDefinition {
  kind: "kafka";
  topic: string;
  consumerGroup: string;
  bootstrapServers: string[];
}

export interface StreamingWindowDefinition {
  kind: StreamingWindowKind;
  sizeSeconds: number;
  slideSeconds?: number;
}

export interface StreamingPolicyDefinition {
  watermarkMode: StreamingWatermarkMode;
  allowedLatenessSeconds: number;
  maxInFlightBatches: number;
}

export interface WorkflowRuntimeDefinition {
  runMode: WorkflowRunMode;
  source?: StreamingSourceDefinition;
  window?: StreamingWindowDefinition;
  policy?: StreamingPolicyDefinition;
}

export interface NodeDefinition {
  id: string;
  type: string;
  name: string;
  executionHint: ExecutionHint;
  capabilities?: NodeCapabilityDescriptor;
  ports: Array<{
    id: string;
    direction: "input" | "output";
    type: WorkflowPortType;
    label?: string;
  }>;
  config: Record<string, unknown>;
  gpuDevicePreference?: string;
}

export interface ConnectionDefinition {
  sourceNodeId: string;
  sourcePortId: string;
  targetNodeId: string;
  targetPortId: string;
  dataType: WorkflowPortType;
  label?: string;
}

export interface WorkflowDefinition {
  version: string;
  workflowId: string;
  name: string;
  nodes: NodeDefinition[];
  connections: ConnectionDefinition[];
  flowVariables: FlowVariableDefinition[];
  containers?: WorkflowContainerDefinition[];
  components?: WorkflowComponentDefinition[];
  controlFlow?: WorkflowControlFlowDefinition[];
  graph?: WorkflowGraphDefinition;
  dashboards?: DashboardDefinition[];
  runtime?: WorkflowRuntimeDefinition;
}

export const jsonRpcMethods = [
  "canvas.subscribe",
  "workflow.execute",
  "workflow.pause",
  "workflow.resume",
  "workflow.stop",
  "dashboard.subscribe"
] as const;

export const milestoneCheckpoints = [
  { tag: "cp/00-foundation", goal: "Monorepo, contracts, CI, CPU prototype" },
  { tag: "cp/01-contracts-frozen", goal: "Workflow schema, OpenAPI, JSON-RPC, SDK frozen" },
  { tag: "cp/02-alpha-core", goal: "Canvas, persistence, 150 core nodes" },
  { tag: "cp/03-alpha-gpu-bi", goal: "Single GPU lane and BI v0" },
  { tag: "cp/04-beta-streaming", goal: "Streaming runtime, windows, checkpoints" },
  { tag: "cp/05-beta-security-hub", goal: "RBAC, sandboxing, Hub public beta" },
  { tag: "cp/06-ga-platform", goal: "GA platform hardening and scale testing" },
  { tag: "cp/07-ga-enterprise", goal: "Enterprise deployment and audit readiness" },
  { tag: "cp/08-scale", goal: "Scale roadmap, ecosystem, advanced features" }
] as const;
export type MilestoneCheckpointTag = (typeof milestoneCheckpoints)[number]["tag"];

export const phaseSummaries = [
  {
    id: "phase-0",
    title: "Phase 0: Foundation",
    timeline: "Months 1-3",
    summary: "Bootstrap repo, contracts, CI/CD, Arrow IPC, CPU-only JES prototype, React canvas shell, tests, and observability baseline.",
    exitGate: "Internal PoC demo: 20-node batch ML pipeline on CPU"
  },
  {
    id: "phase-1",
    title: "Phase 1: Alpha",
    timeline: "Months 4-6",
    summary: "Ship draggable node canvas, typed ports, persistence, 150 core nodes, CUDA support, BI Dashboard v0, streaming MVP, and Hub v0.",
    exitGate: "Alpha release to 50 design partners"
  },
  {
    id: "phase-2",
    title: "Phase 2: Beta",
    timeline: "Months 7-12",
    summary: "Add components, flow variables, loop/control nodes, checkpoint recovery, BI semantic layer, live updates, RBAC, sandboxing, and public SDK.",
    exitGate: "Public beta launch with role-aware dashboards"
  },
  {
    id: "phase-3",
    title: "Phase 3: GA",
    timeline: "Months 13-18",
    summary: "Expand node library, multi-GPU scheduling, enterprise deployment paths, KNIME import, audit logs, and SOC 2 readiness work.",
    exitGate: "GA plus enterprise-ready deployment"
  },
  {
    id: "phase-4",
    title: "Phase 4: Scale",
    timeline: "Months 19-24",
    summary: "Add LLM nodes, AutoML, advanced geospatial, federated execution, compatibility bridges, and commercial hardening.",
    exitGate: "Scale targets and ecosystem maturity"
  }
] as const;

export interface GatewayGpuDeviceSummary {
  deviceId: string;
  vendor: string;
  accelerator: string;
  mode: "hardware" | "simulated" | string;
  memoryBytes: number;
}

export interface GatewayDatasetCardEvidence { datasetId: string; sourceUri: string; checksumSha256: string; schemaSummary: Array<{ name: string; type: string }>; rowCount: number; limitations: string[]; }
export interface GatewayModelCardEvidence { modelId: string; kind: string; target: string; config: Record<string, string | number | boolean>; metrics: Record<string, number>; limitations: string[]; }
export interface GatewayExplanationEvidence { method: string; featureImportance: Array<{ feature: string; importance: number }>; localExample: { rowId: string; prediction: number; contributions: Array<{ feature: string; contribution: number }>; }; warnings: string[]; }
export interface GatewayExplainabilityEvidence { status: "ready" | "pending"; generatedAt: string; workflowId: string; checkpointTag: string; datasetCard: GatewayDatasetCardEvidence; modelCard: GatewayModelCardEvidence; explanation: GatewayExplanationEvidence; reproducibilityBundleReady: boolean; }

export type GatewayInteractiveChartRenderer = "plotly";
export type GatewayInteractiveChartStatus = "ready" | "empty" | "stale" | "error";

export interface GatewayInteractiveChartSource {
  label: string;
  localOnly: boolean;
  updatedAt?: string;
  evidenceRef?: string;
}

export interface GatewayInteractiveChartExport {
  fileName: string;
  png?: boolean;
  html?: boolean;
}

export interface GatewayInteractiveChartSpec {
  chartId: string;
  title: string;
  description?: string;
  renderer: GatewayInteractiveChartRenderer;
  kind: "line" | "bar" | "histogram" | "indicator" | "scatter" | "heatmap" | string;
  status: GatewayInteractiveChartStatus;
  data: Array<Record<string, unknown>>;
  layout: Record<string, unknown>;
  config?: Record<string, unknown>;
  source: GatewayInteractiveChartSource;
  summary: string;
  emptyReason?: string;
  staleReason?: string;
  export?: GatewayInteractiveChartExport;
}

export type DataScienceProjectDatasetRole = "train" | "validation" | "test" | "evaluation" | "output" | "reference";
export type DataScienceColumnRole =
  | "feature"
  | "target"
  | "id"
  | "group"
  | "time"
  | "depth"
  | "sensitive"
  | "ignore";
export type DataScienceSplitStrategy = "random" | "stratified" | "grouped" | "time" | "depth" | "external";
export type DataScienceModelLifecycleState =
  | "candidate"
  | "validated"
  | "approved"
  | "deployed"
  | "rollback_ready"
  | "rolled_back"
  | "retraining_requested"
  | "deprecated"
  | "archived";

export interface DataScienceProjectEvidenceRef {
  refId: string;
  kind: string;
  localOnly: boolean;
  checksumSha256?: string;
  sizeBytes?: number;
  path?: string;
  generatedAt?: string;
}

export interface ProjectDataset {
  datasetId: string;
  name: string;
  role: DataScienceProjectDatasetRole;
  sourceUri: string;
  localOnly: boolean;
  rowCount?: number;
  columnCount?: number;
  checksumSha256?: string;
  artifactRef?: string;
}

export interface SchemaColumnContract {
  name: string;
  inferredType: string;
  logicalType: string;
  role: DataScienceColumnRole;
  nullable: boolean;
  unit?: string;
  description?: string;
}

export interface SchemaContract {
  schemaId: string;
  datasetId: string;
  columns: SchemaColumnContract[];
  updatedAt: string;
}

export interface DatasetSplitPlan {
  splitPlanId: string;
  datasetId: string;
  strategy: DataScienceSplitStrategy;
  trainFraction?: number;
  validationFraction?: number;
  testFraction?: number;
  groupColumn?: string;
  timeColumn?: string;
  depthColumn?: string;
  seed?: number;
  locked: boolean;
  createdAt: string;
}

export interface SplitAssignment {
  splitAssignmentId: string;
  splitPlanId: string;
  datasetId: string;
  split: "train" | "validation" | "test" | "evaluation";
  rowRef: string;
}

export interface ValidationFold {
  foldId: string;
  splitPlanId: string;
  strategy: DataScienceSplitStrategy | "kfold";
  index: number;
  trainRef: string;
  validationRef: string;
}

export interface FinalTestLock {
  lockId: string;
  splitPlanId: string;
  lockedAt: string;
  reason: string;
  lockedBy: string;
}

export type DataScienceProjectJobType =
  | "data_profile"
  | "training"
  | "transform_fit_apply"
  | "statistical_analysis"
  | "tuning_study"
  | "final_evaluation"
  | "prediction_export"
  | "drift_report"
  | "deploy_package"
  | "model_lifecycle"
  | "retraining";

export type DataScienceProjectJobStatus = "queued" | "running" | "completed" | "failed" | "cancelled";

export interface DataScienceProjectJobResourceEvidence {
  executionMode: string;
  requestedBackend: GatewayComputeBackend | string;
  selectedBackend: GatewayComputeBackend | string;
  dispatchLane: WorkflowResourceClass | string;
  workerPool: string;
  schedulerPolicy: string;
  cpuThreadCount: number;
  cpuWorkerConcurrency: number;
  cpuMemoryLimitBytes: number;
  gpuReadinessStatus: "available" | "cpu_fallback" | string;
  gpuHardwareDeviceCount: number;
  gpuSimulatedDeviceCount: number;
  gpuFallbackReason: string;
}

export interface DataScienceProjectJobExecutionEvidence {
  executionId: string;
  workflowId: string;
  status: GatewayExecutionStatus | string;
  mode: string;
  workerId?: string;
  orchestrationMode?: "gateway_worker_dispatch" | string;
  dispatchStatus?: "queued" | "running" | "completed" | "failed" | string;
  workerPool?: string;
  dispatchLane?: WorkflowResourceClass | string;
  queuedAt?: string;
  startedAt?: string;
  finishedAt?: string;
}

export interface DataScienceProjectJobRecord {
  jobId: string;
  projectId: string;
  jobType: DataScienceProjectJobType;
  status: DataScienceProjectJobStatus;
  datasetId?: string;
  splitPlanId?: string;
  sourceRecordId?: string;
  outputRefs: DataScienceProjectEvidenceRef[];
  resourceEvidence?: DataScienceProjectJobResourceEvidence;
  executionEvidence?: DataScienceProjectJobExecutionEvidence;
  startedAt: string;
  finishedAt?: string;
  errorMessage?: string;
}

export interface TransformFitApplyRecord {
  transformRunId: string;
  datasetId: string;
  splitPlanId: string;
  fitSplit: "train";
  applySplits: Array<"validation" | "test" | "evaluation">;
  transformRef: string;
  leakageChecks: Array<{
    checkId: string;
    status: "passed" | "warning" | "failed";
    detail: string;
  }>;
  artifactRefs: DataScienceProjectEvidenceRef[];
  createdAt: string;
}

export interface StatisticalAnalysisRun {
  analysisRunId: string;
  datasetId: string;
  method: string;
  status: "queued" | "running" | "completed" | "failed" | "unavailable";
  generatedCodeRef?: string;
  resultRef?: string;
  resultSummary?: Record<string, unknown>;
  artifactRefs?: DataScienceProjectEvidenceRef[];
  charts?: GatewayInteractiveChartSpec[];
  warnings: string[];
  createdAt: string;
}

export interface RunStatisticalAnalysisRequest {
  datasetId?: string;
  methods?: Array<"summary" | "correlation" | "t_test" | "chi_square" | "anova" | string>;
  targetColumn?: string;
  featureColumns?: string[];
}

export interface RunStatisticalAnalysisResponse {
  status: "completed";
  analysisRun: StatisticalAnalysisRun;
  project: DataScienceProject;
}

export interface RunTransformFitApplyRequest {
  datasetId?: string;
  splitPlanId?: string;
  transformRef?: string;
  fitSplit?: "train";
  applySplits?: Array<"validation" | "test" | "evaluation">;
}

export interface RunTransformFitApplyResponse {
  status: "completed";
  transformRun: TransformFitApplyRecord;
  project: DataScienceProject;
}

export interface RunTuningStudyRequest {
  datasetId?: string;
  splitPlanId?: string;
  trainingPlanId?: string;
  targetColumn?: string;
  taskType?: "classification" | "regression" | "ranking" | "clustering" | string;
  algorithm?: string;
  metricNames?: string[];
  maxTrials?: number;
  finalTestPolicy?: "forbid_final_test" | "use_final_test";
}

export interface RunTuningStudyResponse {
  status: "completed";
  trainingPlan: TrainingPlan;
  tuningStudy: TuningStudy;
  project: DataScienceProject;
}

export interface RunFinalEvaluationRequest {
  datasetId?: string;
  splitPlanId?: string;
  trainingPlanId?: string;
  tuningStudyId?: string;
  metricNames?: string[];
  approvalThreshold?: number;
  finalTestPolicy?: "use_final_test";
}

export interface RunFinalEvaluationResponse {
  status: "completed";
  evaluationReport: EvaluationReport;
  project: DataScienceProject;
}

export interface PredictionOutputColumnContract {
  name: string;
  type?: string;
  required?: boolean;
  sourceColumn?: string;
  description?: string;
}

export interface PredictionOutputContract {
  contractId: string;
  columns: PredictionOutputColumnContract[];
  primaryKey?: string[];
  createdAt?: string;
}

export interface PredictionOutputMapping {
  outputColumn: string;
  sourceColumn: string;
}

export interface RunPredictionExportRequest {
  datasetId?: string;
  evaluationReportId?: string;
  outputContractRef?: string;
  outputContract?: PredictionOutputContract;
  outputMappings?: PredictionOutputMapping[];
  format?: "csv" | "parquet" | "jsonl" | string;
  rowCount?: number;
  outputColumns?: string[];
}

export interface RunPredictionExportResponse {
  status: "completed";
  predictionExport: PredictionExport;
  project: DataScienceProject;
}

export interface RunDriftReportRequest {
  datasetId?: string;
  predictionExportId?: string;
  baselineId?: string;
  metricNames?: string[];
  threshold?: number;
}

export interface RunDriftReportResponse {
  status: "completed";
  monitoringBaseline: MonitoringBaseline;
  driftReport: DriftReport;
  project: DataScienceProject;
}

export type DataScienceModelLifecycleAction =
  | "approve_model"
  | "deprecate_model"
  | "archive_model"
  | "mark_rollback_ready"
  | "mark_rolled_back"
  | "request_retraining";

export interface RunModelLifecycleActionRequest {
  modelId: string;
  action: DataScienceModelLifecycleAction;
  rollbackModelId?: string;
  driftReportId?: string;
  reason?: string;
}

export interface RunModelLifecycleActionResponse {
  status: "completed";
  lifecycleRecord: ModelLifecycleRecord;
  project: DataScienceProject;
}

export interface TrainingPlan {
  trainingPlanId: string;
  targetColumn: string;
  taskType: "classification" | "regression" | "ranking" | "clustering" | string;
  metricNames: string[];
  splitPlanId: string;
  transformRef?: string;
  seed?: number;
  createdAt: string;
}

export interface TuningTrial {
  trialId: string;
  parameters: Record<string, string | number | boolean>;
  metrics: Record<string, number>;
  artifactRefs: DataScienceProjectEvidenceRef[];
}

export interface TuningStudy {
  tuningStudyId: string;
  trainingPlanId: string;
  validationOnly: boolean;
  trials: TuningTrial[];
  bestTrialId?: string;
  validationEvidence?: {
    projectId?: string;
    datasetId?: string;
    splitPlanId?: string;
    splitStrategy?: string;
    validationFraction?: number;
    testFraction?: number;
    finalTestPolicy?: "forbid_final_test" | "use_final_test";
  };
  createdAt: string;
}

export interface EvaluationReport {
  evaluationReportId: string;
  trainingPlanId: string;
  splitPlanId: string;
  metrics: Record<string, number>;
  approved: boolean;
  finalTestOnly?: boolean;
  validationEvidence?: {
    projectId?: string;
    datasetId?: string;
    splitPlanId?: string;
    tuningStudyId?: string;
    finalTestPolicy?: "use_final_test";
    validationOnlyTuning?: boolean;
    testFraction?: number;
  };
  generatedAt: string;
  artifactRefs: DataScienceProjectEvidenceRef[];
}

export interface PredictionExport {
  predictionExportId: string;
  evaluationReportId?: string;
  outputContractRef?: string;
  artifactRef: string;
  rowCount: number;
  format?: string;
  outputColumns?: string[];
  outputContract?: PredictionOutputContract;
  outputMappings?: PredictionOutputMapping[];
  artifactRefs?: DataScienceProjectEvidenceRef[];
  executionEvidence?: DataScienceProjectJobExecutionEvidence;
  validationEvidence?: {
    projectId?: string;
    datasetId?: string;
    evaluationReportId?: string;
    executionId?: string;
    outputContractRef?: string;
    outputColumns?: string[];
    outputContractColumns?: string[];
    outputMappings?: PredictionOutputMapping[];
    outputSchemaValidated?: boolean;
    contractRequiredColumnsSatisfied?: boolean;
    finalEvaluationApproved?: boolean;
    finalTestOnly?: boolean;
  };
  createdAt: string;
}

export interface ModelLifecycleRecord {
  modelId: string;
  state: DataScienceModelLifecycleState;
  evaluationReportId?: string;
  deployedEndpointId?: string;
  rollbackModelId?: string;
  rollbackPackageId?: string;
  rollbackPackageRef?: string;
  lifecycleAction?: DataScienceModelLifecycleAction;
  rollbackReason?: string;
  retrainingReason?: string;
  retrainingTrainingPlanId?: string;
  retrainingTuningStudyId?: string;
  retrainingJobId?: string;
  deprecationReason?: string;
  archiveReason?: string;
  validationEvidence?: {
    projectId?: string;
    modelId?: string;
    previousState?: DataScienceModelLifecycleState;
    lifecycleAction?: DataScienceModelLifecycleAction;
    deployedEndpointId?: string;
    rollbackModelId?: string;
    rollbackPackageId?: string;
    rollbackPackageRef?: string;
    retrainingTrainingPlanId?: string;
    retrainingTuningStudyId?: string;
    retrainingJobId?: string;
    driftReportId?: string;
    reason?: string;
  };
  updatedAt: string;
}

export interface MonitoringBaseline {
  baselineId: string;
  modelId: string;
  datasetId: string;
  metricNames: string[];
  predictionExportId?: string;
  evaluationReportId?: string;
  createdAt: string;
}

export interface DriftReport {
  driftReportId: string;
  baselineId: string;
  status: "not_available" | "low" | "moderate" | "high";
  metrics: Record<string, number>;
  validationEvidence?: {
    projectId?: string;
    datasetId?: string;
    predictionExportId?: string;
    evaluationReportId?: string;
    outputContractRef?: string;
  };
  generatedAt: string;
}

export interface DataScienceProject {
  schemaVersion: "1.0";
  projectId: string;
  name: string;
  description?: string;
  localOnly: boolean;
  createdAt: string;
  updatedAt: string;
  datasets: ProjectDataset[];
  schemaContracts: SchemaContract[];
  splitPlans: DatasetSplitPlan[];
  splitAssignments: SplitAssignment[];
  validationFolds: ValidationFold[];
  finalTestLocks: FinalTestLock[];
  projectJobs: DataScienceProjectJobRecord[];
  transformFitApplyRecords: TransformFitApplyRecord[];
  statisticalAnalysisRuns: StatisticalAnalysisRun[];
  trainingPlans: TrainingPlan[];
  tuningStudies: TuningStudy[];
  evaluationReports: EvaluationReport[];
  predictionExports: PredictionExport[];
  modelRegistryRecords: GatewayModelRegistryRecord[];
  modelLifecycleRecords: ModelLifecycleRecord[];
  monitoringBaselines: MonitoringBaseline[];
  driftReports: DriftReport[];
  reproducibilityEvidence: DataScienceProjectEvidenceRef[];
}

export interface CreateDataScienceProjectRequest {
  projectId?: string;
  name: string;
  description?: string;
  datasets?: ProjectDataset[];
  schemaContracts?: SchemaContract[];
}

export interface UpdateDataScienceProjectRequest extends Partial<CreateDataScienceProjectRequest> {
  splitPlans?: DatasetSplitPlan[];
  splitAssignments?: SplitAssignment[];
  validationFolds?: ValidationFold[];
  finalTestLocks?: FinalTestLock[];
  projectJobs?: DataScienceProjectJobRecord[];
  transformFitApplyRecords?: TransformFitApplyRecord[];
  statisticalAnalysisRuns?: StatisticalAnalysisRun[];
  trainingPlans?: TrainingPlan[];
  tuningStudies?: TuningStudy[];
  evaluationReports?: EvaluationReport[];
  predictionExports?: PredictionExport[];
  modelRegistryRecords?: GatewayModelRegistryRecord[];
  modelLifecycleRecords?: ModelLifecycleRecord[];
  monitoringBaselines?: MonitoringBaseline[];
  driftReports?: DriftReport[];
  reproducibilityEvidence?: DataScienceProjectEvidenceRef[];
}

export interface GatewayLocalWorkspaceActivity {
  label: string;
  detail: string;
  occurredAt: string;
  status: "completed" | "running" | "warning" | "ready" | string;
}

export interface GatewayLocalArtifactSummary {
  path: string;
  kind: "dataset" | "table" | "code" | "model" | "metadata" | "artifact" | string;
  size: string;
  status: string;
  localOnly: boolean;
}

export interface GatewayWorkspaceSummary {
  cpuUsagePercent: number;
  ramUsedBytes: number;
  ramTotalBytes: number;
  diskUsedBytes: number;
  diskTotalBytes: number;
  localDatasetCount: number;
  localModelCount: number;
  recentRunCount: number;
  packageInstalledCount: number;
  packageOutdatedCount: number;
  runtimeUptimeLabel: string;
  activeJobCount: number;
  projectRoot: string;
  activities: GatewayLocalWorkspaceActivity[];
  artifacts: GatewayLocalArtifactSummary[];
}

export interface GatewayHealthcheck {
  service: "api-gateway";
  status: "ok";
  runtime: JuliaFlowRuntimeContract;
  runtimeMode: JuliaFlowRuntimeMode;
  fixtureProvenance: JuliaFlowFixtureProvenance;
  fixtureSubstitutionAllowed: boolean;
  unavailable: JuliaFlowUnavailableState[];
  localProfile: "single-user" | "lab-team" | "s3-compatible-local" | "developer";
  localHome: string;
  metadataMode: "single-user" | "lab-team";
  metadataBackend: "file" | "postgres";
  metadataRoot: string;
  metadataReady: boolean;
  metadataSchemaStatus: "not_required" | "ready" | "missing" | "error";
  metadataConcurrencyStatus: "single_writer" | "shared_postgres_ready" | "unverified";
  metadataCapabilities: Array<
    | "workflows"
    | "executions"
    | "authPolicy"
    | "authDirectory"
    | "auditEvents"
    | "consumerCursors"
    | "publishedDashboards"
  >;
  dataEstateRoot: string;
  dataEstateZones: GatewayDataEstateZoneStatus[];
  dataEstateReady: boolean;
  dataEstateManaged: boolean;
  dataEstateManifestPath: string;
  dataEstateManifestReady: boolean;
  dataEstateManifestChecksums: GatewayDataEstateManifestChecksum[];
  dataEstateArtifactFormats: Array<"arrow_ipc" | "parquet">;
  dataEstateQuotaBytes: number;
  dataEstateUsedBytes: number;
  dataEstateCleanupStatus: "ready" | "pending";
  dataEstateBackupRoot: string;
  dataEstateBackupStatus: "ready" | "pending";
  localBackupRestoreReady: boolean;
  dataEstateDuckdbStatus: "ready" | "pending";
  dataEstateDuckdbQueryPath: string;
  freeDiskStatus: "available" | "unavailable" | "unknown";
  freeDiskBytes: number;
  localServiceUrls: GatewayLocalServiceUrls;
  postgresProfileStatus: "not_required" | "configured" | "missing";
  minioProfileStatus: "not_required" | "configured" | "missing";
  cloudCredentialsRequired: boolean;
  cpuThreadCount: number;
  totalMemoryBytes: number;
  freeMemoryBytes: number;
  hardwareProfileStatus: "ready" | "degraded";
  hardwareSelectedBackend: "cpu" | "cuda" | "simulated_cuda" | string;
  cpuSchedulerPolicy: "bounded_threads" | string;
  cpuWorkerConcurrency: number;
  cpuMemoryLimitBytes: number;
  gpuReadinessStatus: "available" | "cpu_fallback";
  gpuFallbackReason: string;
  gpuCudaStatus: "not_requested" | "requested" | "ready" | "unavailable" | string;
  gpuHardwareDeviceCount: number;
  gpuSimulatedDeviceCount: number;
  gpuTotalVramBytes: number;
  gpuDeviceSummaries: GatewayGpuDeviceSummary[];
  computeSettings: GatewayComputeSettings;
  explainabilityEvidence: GatewayExplainabilityEvidence;
  hubCacheRoot: string;
  hubArtifactStorePath: string;
  hubMirrorRegistryPath: string;
  hubArtifactCacheRoot: string;
  hubCacheStatus: "ready" | "pending";
  hubOfflineInstallReady: boolean;
  hubBundledExtensionCount: number;
  hubInstalledLocalExtensionCount: number;
  repositoryBackend: string;
  storeRoot: string;
  workflowCount: number;
  checkpointCount: number;
  executionCount: number;
  realtimeTransport: "jsonrpc_websocket";
  eventBackboneMode: "dual_write" | "consume";
  eventConsumerPollMs: number;
  streamWorkerMode: "inline" | "process";
  gpuWorkerMode: "process" | "disabled";
  gpuRegistryDeviceCount: number;
  gpuFallbackAvailable: boolean;
  eventLogSize: number;
  latestEventSequence: number;
  gatewayConsumerCursor: number;
  gatewayConsumerLag: number;
  eventConsumerCatchupPercent: number;
  activeStreamExecutions: number;
  queuedGpuExecutions: number;
  queuedStreamExecutions: number;
  activeGpuExecutions: number;
  gpuWorkerOwnedExecutions: number;
  queuedExecutionsTotal: number;
  runningExecutionsTotal: number;
  otelTraceSeamEnabled?: boolean;
  observabilitySpanCount?: number;
  observabilityRecentSpanCount?: number;
  lastTraceId?: string | null;
  lastSpanName?: string | null;
  authMode?: GatewayAuthMode;
  authDevFallback?: boolean;
  oidcDiscoveryConfigured?: boolean;
  oidcJwksConfigured?: boolean;
  oidcAllowedAlgorithms?: string[];
  workspaceSummary?: GatewayWorkspaceSummary;
  charts?: GatewayInteractiveChartSpec[];
}

export interface GatewayDataEstateZoneStatus {
  name: string;
  path: string;
  exists: boolean;
  writable: boolean;
}

export interface GatewayDataEstateManifestChecksum {
  zone: string;
  path: string;
  exists: boolean;
  checksumSha256: string;
}

export interface GatewayLocalServiceUrls {
  gateway: string;
  execution: string;
  frontend: string;
  streamWorker: string;
  gpuWorker: string;
}

export interface ObservabilitySpanRecord {
  trace_id: string;
  span_id: string;
  name: string;
  kind: "server" | "internal" | string;
  started_at: string;
  duration_ms: number;
  status?: number;
  method?: string;
  path?: string;
  attributes?: Record<string, unknown>;
}

export interface ObservabilityTraceRecord {
  trace_id: string;
  root_span_id: string;
  spans: ObservabilitySpanRecord[];
}

export interface GatewayWorkflowSummary {
  workflowId: string;
  name: string;
  version: string;
  nodeCount: number;
  latestCheckpoint: string;
  graphRevision?: number;
  dashboardCount?: number;
  runMode?: WorkflowRunMode;
}

export interface GatewayWorkflowMetadata {
  workflowId: string;
  name: string;
  version: string;
  nodeCount: number;
  connectionCount: number;
  flowVariableCount: number;
  biOutletCount: number;
  dashboardCount: number;
  graphRevision?: number;
  runMode: WorkflowRunMode;
  nodes: NodeDefinition[];
  connections: ConnectionDefinition[];
  flowVariables: FlowVariableDefinition[];
  biOutlets: Array<Record<string, unknown>>;
  containers?: WorkflowContainerDefinition[];
  components?: WorkflowComponentDefinition[];
  controlFlow?: WorkflowControlFlowDefinition[];
  graph?: WorkflowGraphDefinition;
  dashboards?: DashboardDefinition[];
  runtime?: WorkflowRuntimeDefinition;
}

export interface GatewayCheckpointRecord {
  tag: string;
  summary: string;
  createdAt: string;
  explainabilityEvidence?: GatewayExplainabilityEvidence;
}

export interface GatewayCheckpointCreateResponse {
  checkpoint: GatewayCheckpointRecord;
  checkpointCount: number;
}

export interface GatewayDashboardPublishResponse {
  dashboard: PublishedDashboardDefinition;
  status: "ok";
}

export interface GatewayDashboardPublishRequest {
  visibility?: "workspace" | "public";
}

export interface GatewayPublishedDashboardListResponse {
  items: PublishedDashboardDefinition[];
}

export interface GatewayReproducibilityBundleExportRequest {
  workflowId: string;
  checkpointTag: string;
  dashboardId?: string;
  notes?: string;
}

export interface GatewayReproducibilityBundle {
  bundleId: string;
  createdAt: string;
  schemaVersion: "juliaflow.reproducibility.v1";
  workflow: GatewayWorkflowMetadata;
  checkpoint: GatewayCheckpointRecord;
  dataReferences: Array<{ datasetId: string; sourceUri: string; checksumSha256: string; rowCount: number }>;
  datasetCards: GatewayDatasetCardEvidence[];
  packageEnvironment: Record<string, string | boolean>;
  runtimeConfig: Record<string, string | number | boolean>;
  randomSeeds: Record<string, number>;
  modelArtifact: { modelId: string; artifactRef: string; checksumSha256: string };
  metrics: Record<string, number>;
  evaluationOutputs: Record<string, unknown>;
  explainabilityOutputs: GatewayExplanationEvidence;
  dashboardSnapshot?: PublishedDashboardDefinition | null;
  notes: string;
  localOnly: boolean;
  bundleChecksumSha256: string;
}

export interface GatewayReproducibilityBundleExportResponse {
  status: "ok";
  bundle: GatewayReproducibilityBundle;
}

export interface GatewayVisualizeCheckpointExportRequest {
  checkpointTag?: string;
  summary?: string;
  visibility?: "workspace" | "public";
  notes?: string;
}

export interface GatewayVisualizeCheckpointExportArtifact {
  kind: "dashboard_snapshot" | "checkpoint" | "reproducibility_bundle";
  artifactRef: string;
  checksumSha256: string;
}

export interface GatewayVisualizeCheckpointExportRecord {
  exportId: string;
  workflowId: string;
  dashboardId: string;
  dashboardVersion: number;
  checkpointTag: string;
  checkpointSummary: string;
  bundleId: string;
  bundleChecksumSha256: string;
  dashboardSnapshotReady: boolean;
  artifactEvidence: GatewayVisualizeCheckpointExportArtifact[];
  createdAt: string;
  localOnly: boolean;
}

export interface GatewayVisualizeCheckpointExportResponse {
  status: "exported";
  export: GatewayVisualizeCheckpointExportRecord;
  checkpoint: GatewayCheckpointRecord;
  dashboard: PublishedDashboardDefinition;
  bundle: GatewayReproducibilityBundle;
}

export interface GatewayReproducibilityBundleImportRequest {
  bundle: GatewayReproducibilityBundle;
}

export interface GatewayReproducibilityBundleImportResponse {
  status: "imported";
  bundleId: string;
  workflowId: string;
  checkpointTag: string;
  dashboardId?: string | null;
  bundleChecksumSha256: string;
}

export interface GatewayLocalBackupExportRequest {
  notes?: string;
  includeExecutions?: boolean;
}

export interface GatewayLocalBackupArtifact {
  relativePath: string;
  sizeBytes: number;
  checksumSha256: string;
  present: boolean;
}

export interface GatewayLocalBackupBundle {
  backupId: string;
  createdAt: string;
  schemaVersion: "juliaflow.backup.v1";
  notes: string;
  localOnly: boolean;
  appliance: Record<string, string | boolean>;
  dataEstate: {
    root: string;
    zones: GatewayDataEstateZoneStatus[];
    artifactFormats: Array<"arrow_ipc" | "parquet">;
    manifestChecksums: GatewayDataEstateManifestChecksum[];
    artifacts: GatewayLocalBackupArtifact[];
  };
  workflows: GatewayWorkflowMetadata[];
  checkpoints: GatewayCheckpointRecord[];
  executions: GatewayExecutionRecord[];
  dataScienceProjects: DataScienceProject[];
  modelRegistryRecords: GatewayModelRegistryRecord[];
  publishedDashboards: PublishedDashboardDefinition[];
  hubExtensions: GatewayHubExtensionRecord[];
  authPolicy: GatewayAuthPolicy;
  authDirectory: GatewayAuthDirectory;
  packageEnvironment: Record<string, string | boolean>;
  runtimeConfig: Record<string, string | number | boolean>;
  backupChecksumSha256: string;
}

export interface GatewayLocalBackupExportResponse {
  status: "ok";
  backup: GatewayLocalBackupBundle;
}

export interface GatewayLocalBackupImportRequest {
  backup: GatewayLocalBackupBundle;
}

export interface GatewayLocalBackupImportResponse {
  status: "restored" | "restored_with_missing_artifacts";
  backupId: string;
  backupChecksumSha256: string;
  restored: {
    workflows: string[];
    checkpoints: string[];
    executions: string[];
    dataScienceProjects: string[];
    modelRegistryRecords: string[];
    publishedDashboards: string[];
    hubExtensions: string[];
    authPolicy: boolean;
    authDirectory: boolean;
  };
  missingArtifacts: GatewayLocalBackupArtifact[];
  checkedArtifacts: Array<{ relativePath: string; checksumSha256: string; sizeBytes: number }>;
  checksumMismatches: Array<{
    relativePath: string;
    expectedChecksumSha256: string;
    actualChecksumSha256: string;
    sizeBytes: number;
  }>;
}

export interface GatewayDataImportProfileRequest {
  projectId?: string;
  datasetId?: string;
  sourceUri?: string;
  format?: "csv" | "json" | "parquet" | "arrow_ipc" | string;
  targetZone?: string;
  readMode?: "csv" | "arrow_ipc" | "parquet" | "duckdb" | string;
}

export interface GatewayDataProfileField {
  name: string;
  type: string;
  quality: string;
  role?: "id" | "feature" | "label" | "timestamp" | "sensitive" | "ignored" | "derived" | string;
  missingCount?: number;
  distinctCount?: number;
  outlierCount?: number;
}

export interface GatewayDataSourceOption {
  mode: "csv" | "arrow_ipc" | "parquet" | "duckdb" | string;
  label: string;
  path: string;
  status: "active" | "ready" | "pending" | "unavailable" | string;
  semantics: string;
}

export interface GatewayDataLineageArtifact {
  stage: "raw" | "profiled" | "processed" | "features" | "query" | string;
  artifactRef: string;
  format: "csv" | "arrow_ipc" | "parquet" | "duckdb" | string;
  checksumSha256: string;
  rowCount: number;
}

export interface GatewayDataQualityCheck {
  checkId: string;
  label: string;
  status: "passed" | "warning" | "failed" | string;
  detail: string;
}

export interface GatewayDataWorkflowReadiness {
  targetColumn: string;
  trainTestSplit: string;
  leakageWarnings: string[];
  downstreamReady: boolean;
  recommendedNextAction: string;
}

export interface GatewayDataQuickPlot {
  plotId: string;
  title: string;
  kind: "histogram" | "bar" | "line" | "target_balance" | string;
  field: string;
  values: Array<{ label: string; value: number }>;
}

export interface GatewayDataImportProfile {
  datasetId: string;
  sourceUri: string;
  sourceFormat: string;
  targetZone: string;
  artifactRef: string;
  artifactFormats: Array<"arrow_ipc" | "parquet">;
  checksumSha256: string;
  rowCount: number;
  schemaSummary: Array<{ name: string; type: string }>;
  profileSummary: GatewayDataProfileField[];
  manifestReady: boolean;
  manifestChecksums: GatewayDataEstateManifestChecksum[];
  duckdbStatus: "ready" | "pending" | string;
  importedAt: string;
  localOnly: boolean;
  activeReadMode?: string;
  sourceOptions?: GatewayDataSourceOption[];
  lineageArtifacts?: GatewayDataLineageArtifact[];
  qualityChecks?: GatewayDataQualityCheck[];
  workflowReadiness?: GatewayDataWorkflowReadiness;
  quickPlots?: GatewayDataQuickPlot[];
  previewRows?: Array<Record<string, string | number | boolean | null>>;
  charts?: GatewayInteractiveChartSpec[];
}

export interface GatewayDataImportProfileResponse {
  status: "profiled";
  profile: GatewayDataImportProfile;
  project?: DataScienceProject;
}

export interface GatewayTransformNodeResult {
  nodeId: string;
  nodeType: string;
  status: string;
  rowCount: number;
  artifactRefs: string[];
}

export interface GatewayTransformArtifactEvidence {
  nodeId: string;
  artifactRefs: string[];
}

export interface GatewayTransformRunRecord {
  runId: string;
  workflowId: string;
  workflowVersion: string;
  checkpointTag: string;
  status: GatewayExecutionStatus | string;
  startedAt: string;
  finishedAt?: string | null;
  stageCount: number;
  nodeIds: string[];
  nodeResults: GatewayTransformNodeResult[];
  artifactEvidence: GatewayTransformArtifactEvidence[];
  localOnly: boolean;
  charts?: GatewayInteractiveChartSpec[];
  validation?: {
    status: "valid" | "warning" | "invalid" | string;
    messages: string[];
    updatedAt: string;
  };
}

export interface GatewayTransformRunRequest {
  executionMode?: ExecutionHint;
  flowVariables?: Record<string, string | number | boolean>;
}

export interface GatewayTransformRunResponse {
  status: "accepted";
  execution: GatewayExecutionRecord;
  run: GatewayTransformRunRecord;
}

export interface GatewayTransformHistoryResponse {
  items: GatewayTransformRunRecord[];
  count: number;
}

export interface GatewayMlExperimentArtifactEvidence {
  kind: "dataset" | "model" | "explanation" | "reproducibility_bundle" | string;
  artifactRef: string;
  checksumSha256: string;
}

export interface GatewayMlExperimentRecord {
  experimentId: string;
  workflowId: string;
  workflowVersion: string;
  executionId: string;
  checkpointTag: string;
  status: GatewayExecutionStatus | string;
  modelId: string;
  modelKind: string;
  target: string;
  datasetId: string;
  datasetChecksumSha256: string;
  metrics: Record<string, number>;
  featureImportance: Array<{ feature: string; importance: number }>;
  hardwareBackend: string;
  gpuReadinessStatus: string;
  artifactEvidence: GatewayMlExperimentArtifactEvidence[];
  validationEvidence?: {
    projectId?: string;
    splitPlanId?: string;
    splitStrategy?: string;
    finalTestPolicy?: "forbid_final_test" | "use_final_test";
    validationFraction?: number;
    testFraction?: number;
    executionId?: string;
    trainingExecutionId?: string;
  };
  executionEvidence?: DataScienceProjectJobExecutionEvidence;
  startedAt: string;
  finishedAt?: string | null;
  localOnly: boolean;
}

export interface GatewayMlExperimentRunRequest {
  executionMode?: ExecutionHint;
  projectId?: string;
  datasetId?: string;
  splitPlanId?: string;
  finalTestPolicy?: "forbid_final_test" | "use_final_test";
  target?: string;
  algorithm?: string;
  flowVariables?: Record<string, string | number | boolean>;
}

export interface GatewayMlExperimentRunResponse {
  status: "accepted";
  execution: GatewayExecutionRecord;
  experiment: GatewayMlExperimentRecord;
}

export interface GatewayMlExperimentHistoryResponse {
  items: GatewayMlExperimentRecord[];
  count: number;
}

export interface GatewayModelRegistryArtifactEvidence {
  kind: "model" | "dataset" | "config" | "explanation" | string;
  artifactRef: string;
  checksumSha256: string;
}

export interface GatewayModelRegistryRecord {
  registryId: string;
  modelId: string;
  workflowId: string;
  workflowVersion: string;
  checkpointTag: string;
  experimentId?: string | null;
  executionId?: string | null;
  modelKind: string;
  target: string;
  status: "registered" | "candidate" | "approved" | "deprecated" | "archived" | string;
  tags: string[];
  owner: string;
  primaryMetricName: string;
  primaryMetricValue: number;
  datasetId: string;
  datasetChecksumSha256: string;
  artifactEvidence: GatewayModelRegistryArtifactEvidence[];
  validationEvidence?: {
    projectId?: string;
    splitPlanId?: string;
    splitStrategy?: string;
    finalTestPolicy?: "forbid_final_test" | "use_final_test";
    validationFraction?: number;
    testFraction?: number;
  };
  registeredAt: string;
  updatedAt: string;
  deploymentStatus: "not_deployed" | "local_ready" | "archived" | string;
  localOnly: boolean;
}

export interface GatewayModelRegistryRequest {
  modelId?: string;
  status?: "registered" | "candidate" | "approved" | "deprecated" | "archived" | string;
  tags?: string[];
  owner?: string;
}

export interface GatewayModelRegistryResponse {
  status: "registered";
  model: GatewayModelRegistryRecord;
}

export interface GatewayModelRegistryListResponse {
  items: GatewayModelRegistryRecord[];
  count: number;
}

export interface GatewayDeployPackageArtifactEvidence {
  kind: "workflow" | "model" | "dataset" | "service" | "config" | string;
  artifactRef: string;
  checksumSha256: string;
}

export interface GatewayDeployPackageRecord {
  packageId: string;
  workflowId: string;
  workflowVersion: string;
  modelId: string;
  checkpointTag: string;
  endpointUrl: string;
  endpointPath: string;
  host: string;
  port: number;
  serviceRef: string;
  packageRef: string;
  packageChecksumSha256: string;
  serviceCode: string;
  runCommand: string;
  modelRegistryId?: string | null;
  deploymentStatus: "local_ready" | "packaged" | "failed" | string;
  rollbackFromModelId?: string;
  rollbackTargetModelId?: string;
  rollbackSourcePackageId?: string;
  rollbackReason?: string;
  artifactEvidence: GatewayDeployPackageArtifactEvidence[];
  validationEvidence?: {
    projectId?: string;
    splitPlanId?: string;
    splitStrategy?: string;
    finalTestPolicy?: "forbid_final_test" | "use_final_test";
    validationFraction?: number;
    testFraction?: number;
    executionId?: string;
    deployPackageExecutionId?: string;
  };
  executionEvidence?: DataScienceProjectJobExecutionEvidence;
  createdAt: string;
  localOnly: boolean;
}

export interface GatewayDeployPackageRequest {
  modelId?: string;
  endpointPath?: string;
  host?: string;
  port?: number;
  notes?: string;
}

export interface GatewayDeployPackageResponse {
  status: "packaged";
  package: GatewayDeployPackageRecord;
}

export interface GatewayDeployPackageHistoryResponse {
  items: GatewayDeployPackageRecord[];
  count: number;
}

export type HubExtensionPublisher = "official" | "partner";
export type HubInstallState =
  | "available"
  | "installed"
  | "enabled"
  | "disabled"
  | "upgrade_available"
  | "incompatible";
export type HubInstallAction = "install" | "enable" | "disable" | "upgrade";

export interface HubExtensionCompatibilityResult {
  compatible: boolean;
  warnings: string[];
  blockers: string[];
  evaluatedAt: string;
}

export interface HubExtensionTrustResult {
  trusted: boolean;
  level: "official" | "partner_verified" | "untrusted";
  warnings: string[];
  blockers: string[];
  evaluatedAt: string;
}

export interface HubExtensionUpgradeInfo {
  upgradeAvailable: boolean;
  installedVersion?: string;
  latestVersion: string;
  targetVersion?: string;
  evaluatedAt: string;
}

export type HubVerificationStatus = "pending" | "passed" | "failed";

export interface HubVerificationCheck {
  status: HubVerificationStatus;
  details: string;
  blockers: string[];
  checkedAt: string;
}

export interface HubExtensionVerification {
  verified: boolean;
  sandbox: HubVerificationCheck;
  artifacts: HubVerificationCheck;
  mirrors: HubVerificationCheck;
  blockers: string[];
  evaluatedAt: string;
}

export interface HubExtensionManifest {
  extensionId: string;
  name: string;
  version: string;
  publisher: HubExtensionPublisher;
  summary: string;
  packageRef: string;
  tags: string[];
  engineCompatibility: string;
  requiredContractVersion: string;
  supportedCheckpoints: string[];
  compatibleCheckpoints: string[];
  dependencies: string[];
  publisherIdentity: string;
  artifactHashes: Record<string, string>;
  compatibilitySandboxCommand?: string;
  mirrorRefs: string[];
  signature?: string;
  releaseNotesRef?: string;
}

export interface GatewayHubExtensionRecord {
  extensionId: string;
  manifest: HubExtensionManifest;
  installState: HubInstallState;
  compatibility: HubExtensionCompatibilityResult;
  trust: HubExtensionTrustResult;
  upgrade: HubExtensionUpgradeInfo;
  verification: HubExtensionVerification;
  installedAt?: string;
  enabledAt?: string;
}

export interface GatewayHubInstallRequest {
  action: HubInstallAction;
}

export interface GatewayHubRegisterRequest {
  manifest: HubExtensionManifest;
}

export interface GatewayHubInstallResponse {
  extension: GatewayHubExtensionRecord;
  status: "ok";
}

export interface GatewayHubRegisterResponse {
  extension: GatewayHubExtensionRecord;
  status: "ok";
}

export interface GatewayExecutionStatusEvent {
  status: GatewayExecutionStatus;
  at: string;
  message?: string;
  metadata?: Record<string, unknown>;
}

export interface GatewayLoopControlFlowPlanEntry {
  controlId: string;
  kind: "loop";
  iterationMode: LoopIterationMode;
  maxIterations: number;
  startNodeId: string;
  endNodeId: string;
  bodyNodeIds: string[];
  bounded: boolean;
}

export interface GatewayTryCatchControlFlowPlanEntry {
  controlId: string;
  kind: "try_catch";
  tryNodeIds: string[];
  catchNodeIds: string[];
  bounded: boolean;
}

export type GatewayControlFlowPlanEntry =
  | GatewayLoopControlFlowPlanEntry
  | GatewayTryCatchControlFlowPlanEntry;

export interface GatewayControlFlowRecovery {
  controlId: string;
  failedNodeId: string;
  catchNodeIds: string[];
  status: "recovered";
  bounded: boolean;
}

export interface GatewayControlFlowBranchNodeResult {
  nodeId: string;
  nodeType: string;
  status: "executed";
  outputKind: string;
  rowCount: number;
}

export interface GatewayControlFlowBranchState {
  controlId: string;
  failedNodeId: string;
  branch: "catch";
  catchNodeIds: string[];
  branchStages?: string[][];
  branchStageIndex?: number;
  branchStageCount?: number;
  activeNodeIds: string[];
  completedNodeIds: string[];
  status: "completed";
  bounded: boolean;
  workerId: string;
  stageResults?: Array<{
    stageIndex: number;
    nodeIds: string[];
    nodeResults: GatewayControlFlowBranchNodeResult[];
  }>;
  nodeResults: GatewayControlFlowBranchNodeResult[];
}

export interface GatewayExecutorDataflowPolicy {
  policyName: "callback_dataflow_stage_barrier" | string;
  callbackEnabled: boolean;
  dataflowEnabled: boolean;
  stageBarrier: "ready_after_previous_stage" | string;
  eligibleNodeIds: string[];
  sourceNodeIds: string[];
  sinkNodeIds: string[];
  lanes: WorkflowResourceClass[];
  workerPools: string[];
  maxConcurrency: number;
  bounded: boolean;
}

export interface GatewayExecutorScheduleStage {
  stageIndex: number;
  nodeIds: string[];
  lanes: WorkflowResourceClass[];
  workerPools: string[];
  schedulerPolicy: "topological_stage_barrier" | string;
  readyAfterStage: number;
  maxConcurrency: number;
  bounded: boolean;
  dataflowPolicy?: GatewayExecutorDataflowPolicy;
}


export interface GatewayExecutorStageResult {
  stageIndex: number;
  nodeIds: string[];
  status: "completed" | string;
  nodeResults?: GatewayExecutorNodeResult[];
}

export interface GatewayExecutorNodeResult {
  nodeId: string;
  nodeType: string;
  status: "executed" | "error" | string;
  outputKind: "node" | "bi_outlet" | "error" | string;
  rowCount: number;
  outputRefs: string[];
  errorMessage?: string;
}

export interface GatewayExecutorState {
  status: "queued" | "running" | "completed" | string;
  currentStageIndex: number;
  stageCount: number;
  activeNodeIds: string[];
  completedNodeIds: string[];
  completedStageIndexes: number[];
  workerId: string;
  bounded: boolean;
  stageResults: GatewayExecutorStageResult[];
  dataflowPolicy?: GatewayExecutorDataflowPolicy;
  nodeResults?: GatewayExecutorNodeResult[];
  failedNodeId?: string;
  errorMessage?: string;
}

export interface GatewayExecutionRecord {
  executionId: string;
  workflowId: string;
  workflowVersion: string;
  checkpointTag: string;
  status: GatewayExecutionStatus;
  mode: string;
  plan: string[];
  stages: string[][];
  nodeCount: number;
  connectionCount: number;
  createdAt: string;
  updatedAt: string;
  statusHistory: GatewayExecutionStatusEvent[];
  queuedAt?: string;
  startedAt?: string;
  finishedAt?: string;
  resourcePlan?: Array<{
    lane: WorkflowResourceClass;
    nodeIds: string[];
  }>;
  controlFlowPlan?: GatewayControlFlowPlanEntry[];
  controlFlowRecovery?: GatewayControlFlowRecovery;
  controlFlowBranchState?: GatewayControlFlowBranchState;
  dispatchPlan?: Array<{
    lane: WorkflowResourceClass;
    nodeIds: string[];
    workerPool: string;
    isolationMode: "shared" | "isolated";
    accelerator?: "cuda";
    schedulerPolicy?: "deterministic_device_id" | "shared_cpu" | string;
    placementReason?: string;
    requestedDevice?: string;
    workerCapacity?: Record<string, unknown>;
  }>;
  executorSchedule?: GatewayExecutorScheduleStage[];
  executorState?: GatewayExecutorState;
  explainabilityEvidence?: GatewayExplainabilityEvidence;
  dispatchLane?: WorkflowResourceClass;
  dispatchWorkerPool?: string;
  dispatchIsolationMode?: "shared" | "isolated";
  dispatchAccelerator?: "cuda";
  dispatchSchedulerPolicy?: "deterministic_device_id" | "shared_cpu" | string;
  dispatchPlacementReason?: string;
  dispatchRequestedDevice?: string;
  dispatchWorkerCapacity?: Record<string, unknown>;
  observabilityTrace?: ObservabilityTraceRecord;
  workerId?: string;
  streamLifecycleStatus?: StreamLifecycleStatus;
  streamAdapter?: "fixture" | "kafka" | "none" | string;
  streamAdapterContract?: Record<string, string | number | string[]>;
  streamProcessedOffset?: number;
  streamCommittedOffset?: number;
  streamProcessedRows?: number;
  streamBatchCount?: number;
  streamConsumerLag?: number;
  streamBackpressure?: "ok" | "lagging" | string;
  streamWatermark?: number;
  streamWatermarkState?: Record<string, string | number>;
  streamWindowState?: {
    kind: string;
    size_seconds: number;
    windows: Array<{ start: number; end: number; count: number }>;
  };
  streamLastCheckpointId?: string;
  streamCheckpointOffsets?: Record<string, string | number>;
  streamSinkTransactionId?: string;
  streamSinkTransactionState?: Record<string, string | number>;
  streamIdempotencyKey?: string;
  streamExactlyOnceStatus?: "idle" | "committed" | "duplicate_suppressed" | string;
  streamReplayStatus?: "duplicate_skipped" | string;
  streamReplayOffset?: number;
  gpuExecutionPath?: "gpu" | "cpu_fallback";
  gpuDeviceId?: string;
  gpuAccelerator?: string;
  gpuVendor?: string;
  gpuFallbackUsed?: boolean;
  gpuCpuFallbackUsed?: boolean;
  gpuPlacementFallbackUsed?: boolean;
  gpuRequestSatisfied?: boolean;
  gpuWorkload?: string;
  gpuWorkloadResult?: Record<string, unknown>;
  gpuRegistry?: {
    device_count: number;
    devices: Array<Record<string, unknown>>;
    fallback_available: boolean;
  };
  gpuRequestedDevice?: string;
  gpuSelectedDevice?: string;
  gpuFallbackReason?: "none" | "registry_empty" | "requested_device_unavailable" | string;
  gpuPlacementReason?: string;
  gpuSchedulerPolicy?: "deterministic_device_id" | string;
  gpuWorkerIsolationMode?: "isolated" | string;
  gpuWorkerCapacity?: Record<string, unknown>;
}

export interface GatewayListResponse<TItem> {
  items: TItem[];
}

export interface CreateWorkflowRequest {
  workflowToml?: string;
  workflow?: WorkflowDefinition;
}

export interface ImportWorkflowRequest {
  sourcePath: string;
}

export interface CreateWorkflowResponse {
  workflowId: string;
  name: string;
  version: string;
  status: "created";
}

export interface UpdateWorkflowResponse {
  workflowId: string;
  name: string;
  version: string;
  status: "updated";
}

export interface ImportWorkflowResponse {
  workflowId: string;
  name: string;
  persistedPath: string;
}

export interface CreateCheckpointRequest {
  tag: string;
  summary: string;
}

export interface TransitionExecutionStatusRequest {
  status: GatewayExecutionStatus;
  message?: string;
  metadata?: Record<string, unknown>;
}

export interface GatewayErrorPayload {
  error: string;
}

export interface GatewayPublishedDashboardReadRequest {
  shareToken?: string;
  workspaceToken?: string;
}

function dashboardChartPath(
  dashboardId: string,
  chartId: string,
  suffix: "data" | "export.csv",
  request?: GatewayPublishedDashboardReadRequest
): string {
  const path = `/api/v1/dashboards/${encodeURIComponent(dashboardId)}/charts/${encodeURIComponent(chartId)}/${suffix}`;
  const params = new URLSearchParams();
  if (request?.shareToken) {
    params.set("shareToken", request.shareToken);
  }
  if (request?.workspaceToken) {
    params.set("workspaceToken", request.workspaceToken);
  }
  if (params.size === 0) {
    return path;
  }
  return `${path}?${params.toString()}`;
}

export const gatewayEndpointPaths = {
  health: "/health",
  computeSettings: "/api/v1/settings/compute",
  workflows: "/api/v1/workflows",
  importWorkflow: "/api/v1/workflows/import",
  workflowDetail: (workflowId: string) => `/api/v1/workflows/${encodeURIComponent(workflowId)}`,
  workflowExecute: (workflowId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/execute`,
  executions: "/api/v1/executions",
  executionDetail: (executionId: string) => `/api/v1/executions/${encodeURIComponent(executionId)}`,
  executionStatus: (executionId: string) =>
    `/api/v1/executions/${encodeURIComponent(executionId)}/status`,
  checkpoints: "/api/v1/checkpoints",
  reproducibilityBundles: "/api/v1/reproducibility-bundles",
  reproducibilityBundleImport: "/api/v1/reproducibility-bundles/import",
  localBackups: "/api/v1/local-backups",
  localBackupImport: "/api/v1/local-backups/import",
  localDataImport: "/api/v1/local-data/import",
  dataScienceProjects: "/api/v1/data-science-projects",
  dataScienceProject: (projectId: string) =>
    `/api/v1/data-science-projects/${encodeURIComponent(projectId)}`,
  dataScienceProjectTransformFitApply: (projectId: string) =>
    `/api/v1/data-science-projects/${encodeURIComponent(projectId)}/transforms/fit-apply`,
  dataScienceProjectStatisticalAnalysisRun: (projectId: string) =>
    `/api/v1/data-science-projects/${encodeURIComponent(projectId)}/statistical-analysis/run`,
  dataScienceProjectTuningRun: (projectId: string) =>
    `/api/v1/data-science-projects/${encodeURIComponent(projectId)}/tuning/run`,
  dataScienceProjectFinalEvaluationRun: (projectId: string) =>
    `/api/v1/data-science-projects/${encodeURIComponent(projectId)}/evaluation/run`,
  dataScienceProjectPredictionExport: (projectId: string) =>
    `/api/v1/data-science-projects/${encodeURIComponent(projectId)}/predictions/export`,
  dataScienceProjectDriftRun: (projectId: string) =>
    `/api/v1/data-science-projects/${encodeURIComponent(projectId)}/drift/run`,
  dataScienceProjectModelLifecycle: (projectId: string) =>
    `/api/v1/data-science-projects/${encodeURIComponent(projectId)}/models/lifecycle`,
  publishedDashboard: (dashboardId: string, request?: GatewayPublishedDashboardReadRequest) => {
    const path = `/api/v1/dashboards/${encodeURIComponent(dashboardId)}`;
    const params = new URLSearchParams();
    if (request?.shareToken) {
      params.set("shareToken", request.shareToken);
    }
    if (request?.workspaceToken) {
      params.set("workspaceToken", request.workspaceToken);
    }
    if (params.size === 0) {
      return path;
    }
    return `${path}?${params.toString()}`;
  },
  publishedDashboardChartData: (
    dashboardId: string,
    chartId: string,
    request?: GatewayPublishedDashboardReadRequest
  ) => dashboardChartPath(dashboardId, chartId, "data", request),
  publishedDashboardChartDataCsv: (
    dashboardId: string,
    chartId: string,
    request?: GatewayPublishedDashboardReadRequest
  ) => dashboardChartPath(dashboardId, chartId, "export.csv", request),
  workflowPublishedDashboards: (workflowId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/dashboards`,
  workflowTransformRun: (workflowId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/transforms/run`,
  workflowTransformHistory: (workflowId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/transforms/history`,
  workflowMlExperimentRun: (workflowId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/ml/experiments/run`,
  workflowMlExperimentHistory: (workflowId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/ml/experiments`,
  workflowModelRegister: (workflowId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/models/register`,
  workflowModels: (workflowId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/models`,
  workflowDeployPackage: (workflowId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/deploy/package`,
  workflowDeployPackages: (workflowId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/deploy/packages`,
  publishDashboard: (workflowId: string, dashboardId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/dashboards/${encodeURIComponent(dashboardId)}/publish`,
  workflowVisualizeCheckpointExport: (workflowId: string, dashboardId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/dashboards/${encodeURIComponent(dashboardId)}/checkpoint-export`,
  hubExtensions: "/api/v1/hub/extensions",
  hubExtensionRegister: "/api/v1/hub/extensions/register",
  hubExtensionInstall: (extensionId: string) =>
    `/api/v1/hub/extensions/${encodeURIComponent(extensionId)}/install`,
  authPolicies: "/api/v1/admin/auth/policies",
  authDirectory: "/api/v1/admin/auth/directory",
  auditActions: "/api/v1/audit/actions"
} as const;

export type GatewayStaticEndpointPath = Extract<
  (typeof gatewayEndpointPaths)[keyof typeof gatewayEndpointPaths],
  string
>;

export interface GatewayRequestOptions {
  headers?: HeadersInit;
  signal?: AbortSignal;
}

export interface GatewayClientOptions {
  baseUrl: string;
  fetch?: typeof fetch;
  headers?: HeadersInit;
}

export interface GatewayRealtimeClientOptions {
  baseUrl: string;
  WebSocket?: typeof WebSocket;
}

export interface GatewayRealtimeRequest {
  jsonrpc: "2.0";
  id: number;
  method: (typeof jsonRpcMethods)[number];
  params: Record<string, unknown>;
}

export interface GatewayRealtimeSuccessResponse<TResult> {
  jsonrpc: "2.0";
  id: number;
  result: TResult;
}

export interface GatewayRealtimeErrorResponse {
  jsonrpc: "2.0";
  id: number | null;
  error: {
    code: number;
    message: string;
  };
}

export interface GatewayWorkflowStateChangedEvent {
  subscriptionId: string;
  workflowId: string;
  name: string;
  version: string;
  nodeCount: number;
  connectionCount: number;
  latestCheckpoint: string;
  executionCount: number;
  graphRevision?: number;
  dashboardCount?: number;
  runMode?: WorkflowRunMode;
}

export interface GatewayNodeStateChangedEvent {
  subscriptionId: string;
  workflowId: string;
  nodeId: string;
  nodeType: string;
  status: WorkflowStatus;
  executionHint: ExecutionHint;
}

export interface GatewayDashboardOutletUpdatedEvent {
  subscriptionId: string;
  dashboardId: string;
  outletIds: string[];
  latestCheckpoint: string;
  updatedAt: string;
}

export interface GatewayStreamingCheckpointCompletedEvent {
  subscriptionId?: string;
  workflowId: string;
  checkpointId: string;
  offsets: Record<string, unknown>;
  stateVersion: number;
}

export interface GatewayExecutionStateChangedEvent extends GatewayExecutionRecord {
  subscriptionId?: string;
}

export interface GatewayRepositorySaveChangedEvent {
  subscriptionId?: string;
  workflowId: string;
  workflowVersion: string;
  graphRevision?: number;
  savedAt: string;
}

export interface GatewayHubExtensionChangedEvent {
  extensionId: string;
  manifest: HubExtensionManifest;
  installState: HubInstallState;
  trust: HubExtensionTrustResult;
  upgrade: HubExtensionUpgradeInfo;
  installedAt?: string;
  enabledAt?: string;
}

export type GatewayDurableEventType =
  | "execution.changed"
  | "stream.checkpoint.completed"
  | "repository.save.changed"
  | "hub.extension.changed"
  | "dashboard.published"
  | "audit.action"
  | "auth.policy.changed"
  | "auth.directory.changed";

export interface GatewayDurableEventEnvelope<
  TType extends GatewayDurableEventType = GatewayDurableEventType,
  TPayload = unknown
> {
  eventId: string;
  eventType: TType;
  aggregateType: string;
  aggregateId: string;
  occurredAt: string;
  sequence: number;
  producer: string;
  payloadVersion: number;
  payload: TPayload;
}

export interface GatewayDurableEventPayloadMap {
  "execution.changed": GatewayExecutionStateChangedEvent;
  "stream.checkpoint.completed": GatewayStreamingCheckpointCompletedEvent;
  "repository.save.changed": GatewayRepositorySaveChangedEvent;
  "hub.extension.changed": GatewayHubExtensionChangedEvent;
  "dashboard.published": PublishedDashboardDefinition;
  "audit.action": GatewayAuditActionEvent;
  "auth.policy.changed": GatewayAuthPolicy;
  "auth.directory.changed": GatewayAuthDirectory;
}

export type GatewayDurableEvent =
  {
    [TType in GatewayDurableEventType]: GatewayDurableEventEnvelope<
      TType,
      GatewayDurableEventPayloadMap[TType]
    >;
  }[GatewayDurableEventType];

export interface GatewayRealtimeNotificationMap {
  "workflow.state.changed": GatewayWorkflowStateChangedEvent;
  "node.state.changed": GatewayNodeStateChangedEvent;
  "dashboard.outlet.updated": GatewayDashboardOutletUpdatedEvent;
  "dashboard.published": PublishedDashboardDefinition;
  "streaming.checkpoint.completed": GatewayStreamingCheckpointCompletedEvent;
  "execution.state.changed": GatewayExecutionStateChangedEvent;
  "repository.save.changed": GatewayRepositorySaveChangedEvent;
}

export type GatewayRealtimeNotificationMethod = keyof GatewayRealtimeNotificationMap;

export type GatewayRealtimeNotification =
  {
    [TMethod in GatewayRealtimeNotificationMethod]: {
      jsonrpc: "2.0";
      method: TMethod;
      params: GatewayRealtimeNotificationMap[TMethod];
    };
  }[GatewayRealtimeNotificationMethod];

export interface GatewayRealtimeClient {
  socket: WebSocket;
  close(code?: number, reason?: string): void;
  request<TResult>(
    method: (typeof jsonRpcMethods)[number],
    params: Record<string, unknown>
  ): Promise<TResult>;
}

export interface GatewayApiClient {
  healthcheck(options?: GatewayRequestOptions): Promise<GatewayHealthcheck>;
  getComputeSettings(options?: GatewayRequestOptions): Promise<GatewayComputeSettings>;
  updateComputeSettings(
    request: UpdateGatewayComputeSettingsRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayComputeSettings>;
  listWorkflows(options?: GatewayRequestOptions): Promise<GatewayListResponse<GatewayWorkflowSummary>>;
  createWorkflow(
    request: CreateWorkflowRequest,
    options?: GatewayRequestOptions
  ): Promise<CreateWorkflowResponse>;
  importWorkflow(
    request: ImportWorkflowRequest,
    options?: GatewayRequestOptions
  ): Promise<ImportWorkflowResponse>;
  getWorkflow(
    workflowId: string,
    options?: GatewayRequestOptions
  ): Promise<GatewayWorkflowMetadata>;
  updateWorkflow(
    workflowId: string,
    request: CreateWorkflowRequest,
    options?: GatewayRequestOptions
  ): Promise<UpdateWorkflowResponse>;
  executeWorkflow(
    workflowId: string,
    options?: GatewayRequestOptions
  ): Promise<GatewayExecutionRecord>;
  listExecutions(options?: GatewayRequestOptions): Promise<GatewayListResponse<GatewayExecutionRecord>>;
  getExecution(
    executionId: string,
    options?: GatewayRequestOptions
  ): Promise<GatewayExecutionRecord>;
  transitionExecutionStatus(
    executionId: string,
    request: TransitionExecutionStatusRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayExecutionRecord>;
  listCheckpoints(options?: GatewayRequestOptions): Promise<GatewayListResponse<GatewayCheckpointRecord>>;
  createCheckpoint(
    request: CreateCheckpointRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayCheckpointCreateResponse>;
  exportReproducibilityBundle(
    request: GatewayReproducibilityBundleExportRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayReproducibilityBundleExportResponse>;
  importReproducibilityBundle(
    request: GatewayReproducibilityBundleImportRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayReproducibilityBundleImportResponse>;
  exportLocalBackup(
    request: GatewayLocalBackupExportRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayLocalBackupExportResponse>;
  importLocalBackup(
    request: GatewayLocalBackupImportRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayLocalBackupImportResponse>;
  importDataProfile(
    request: GatewayDataImportProfileRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayDataImportProfileResponse>;
  listDataScienceProjects(options?: GatewayRequestOptions): Promise<GatewayListResponse<DataScienceProject>>;
  createDataScienceProject(
    request: CreateDataScienceProjectRequest,
    options?: GatewayRequestOptions
  ): Promise<DataScienceProject>;
  getDataScienceProject(
    projectId: string,
    options?: GatewayRequestOptions
  ): Promise<DataScienceProject>;
  updateDataScienceProject(
    projectId: string,
    request: UpdateDataScienceProjectRequest,
    options?: GatewayRequestOptions
  ): Promise<DataScienceProject>;
  runDataScienceProjectTransformFitApply(
    projectId: string,
    request?: RunTransformFitApplyRequest,
    options?: GatewayRequestOptions
  ): Promise<RunTransformFitApplyResponse>;
  runDataScienceProjectStatisticalAnalysis(
    projectId: string,
    request?: RunStatisticalAnalysisRequest,
    options?: GatewayRequestOptions
  ): Promise<RunStatisticalAnalysisResponse>;
  runDataScienceProjectTuningStudy(
    projectId: string,
    request?: RunTuningStudyRequest,
    options?: GatewayRequestOptions
  ): Promise<RunTuningStudyResponse>;
  runDataScienceProjectFinalEvaluation(
    projectId: string,
    request?: RunFinalEvaluationRequest,
    options?: GatewayRequestOptions
  ): Promise<RunFinalEvaluationResponse>;
  runDataScienceProjectPredictionExport(
    projectId: string,
    request?: RunPredictionExportRequest,
    options?: GatewayRequestOptions
  ): Promise<RunPredictionExportResponse>;
  runDataScienceProjectDriftReport(
    projectId: string,
    request?: RunDriftReportRequest,
    options?: GatewayRequestOptions
  ): Promise<RunDriftReportResponse>;
  runDataScienceProjectModelLifecycleAction(
    projectId: string,
    request: RunModelLifecycleActionRequest,
    options?: GatewayRequestOptions
  ): Promise<RunModelLifecycleActionResponse>;
  runWorkflowTransform(
    workflowId: string,
    request?: GatewayTransformRunRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayTransformRunResponse>;
  getWorkflowTransformHistory(
    workflowId: string,
    options?: GatewayRequestOptions
  ): Promise<GatewayTransformHistoryResponse>;
  runWorkflowMlExperiment(
    workflowId: string,
    request?: GatewayMlExperimentRunRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayMlExperimentRunResponse>;
  getWorkflowMlExperimentHistory(
    workflowId: string,
    options?: GatewayRequestOptions
  ): Promise<GatewayMlExperimentHistoryResponse>;
  registerWorkflowModel(
    workflowId: string,
    request?: GatewayModelRegistryRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayModelRegistryResponse>;
  listWorkflowModels(
    workflowId: string,
    options?: GatewayRequestOptions
  ): Promise<GatewayModelRegistryListResponse>;
  packageWorkflowDeploy(
    workflowId: string,
    request?: GatewayDeployPackageRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayDeployPackageResponse>;
  listWorkflowDeployPackages(
    workflowId: string,
    options?: GatewayRequestOptions
  ): Promise<GatewayDeployPackageHistoryResponse>;
  listPublishedDashboards(
    workflowId: string,
    options?: GatewayRequestOptions
  ): Promise<GatewayPublishedDashboardListResponse>;
  getPublishedDashboard(
    dashboardId: string,
    request?: GatewayPublishedDashboardReadRequest,
    options?: GatewayRequestOptions
  ): Promise<PublishedDashboardDefinition>;
  getPublishedDashboardChartData(
    dashboardId: string,
    chartId: string,
    request?: GatewayPublishedDashboardReadRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayDashboardChartDataResponse>;
  getPublishedDashboardChartDataCsv(
    dashboardId: string,
    chartId: string,
    request?: GatewayPublishedDashboardReadRequest,
    options?: GatewayRequestOptions
  ): Promise<string>;
  publishDashboard(
    workflowId: string,
    dashboardId: string,
    request?: GatewayDashboardPublishRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayDashboardPublishResponse>;
  exportVisualizeCheckpoint(
    workflowId: string,
    dashboardId: string,
    request?: GatewayVisualizeCheckpointExportRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayVisualizeCheckpointExportResponse>;
  listHubExtensions(
    options?: GatewayRequestOptions
  ): Promise<GatewayListResponse<GatewayHubExtensionRecord>>;
  registerHubExtension(
    request: GatewayHubRegisterRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayHubRegisterResponse>;
  installHubExtension(
    extensionId: string,
    request: GatewayHubInstallRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayHubInstallResponse>;
  getAuthPolicy(options?: GatewayRequestOptions): Promise<GatewayAuthPolicy>;
  updateAuthPolicy(
    request: GatewayAuthPolicy,
    options?: GatewayRequestOptions
  ): Promise<GatewayAuthPolicy>;
  getAuthDirectory(options?: GatewayRequestOptions): Promise<GatewayAuthDirectory>;
  updateAuthDirectory(
    request: GatewayAuthDirectory,
    options?: GatewayRequestOptions
  ): Promise<GatewayAuthDirectory>;
  queryAuditActions(options?: GatewayRequestOptions): Promise<GatewayAuditQueryResponse>;
}

export class GatewayClientError extends Error {
  readonly status: number;
  readonly payload: unknown;

  constructor(message: string, status: number, payload: unknown) {
    super(message);
    this.name = "GatewayClientError";
    this.status = status;
    this.payload = payload;
  }
}

function trimTrailingSlash(baseUrl: string): string {
  return baseUrl.endsWith("/") ? baseUrl.slice(0, -1) : baseUrl;
}

function buildUrl(baseUrl: string, path: string): string {
  return `${trimTrailingSlash(baseUrl)}${path}`;
}

function buildRealtimeUrl(baseUrl: string): string {
  const httpUrl = new URL(buildUrl(baseUrl, "/api/v1/realtime"));
  httpUrl.protocol = httpUrl.protocol === "https:" ? "wss:" : "ws:";
  return httpUrl.toString();
}

async function parseGatewayResponse(response: Response): Promise<unknown> {
  const body = await response.text();
  if (body.length === 0) {
    return null;
  }

  try {
    return JSON.parse(body) as unknown;
  } catch {
    return body;
  }
}

function mergeHeaders(baseHeaders?: HeadersInit, requestHeaders?: HeadersInit): Headers {
  const headers = new Headers(baseHeaders);
  if (requestHeaders) {
    new Headers(requestHeaders).forEach((value, key) => {
      headers.set(key, value);
    });
  }
  return headers;
}

export function createGatewayApiClient(options: GatewayClientOptions): GatewayApiClient {
  const gatewayFetch = options.fetch ?? globalThis.fetch;
  if (!gatewayFetch) {
    throw new Error("fetch implementation required to create Gateway API client");
  }

  async function request<TResponse>(
    method: string,
    path: string,
    body?: unknown,
    requestOptions?: GatewayRequestOptions
  ): Promise<TResponse> {
    const headers = mergeHeaders(options.headers, requestOptions?.headers);
    headers.set("Accept", "application/json");

    let payload: string | undefined;
    if (body !== undefined) {
      headers.set("Content-Type", "application/json");
      payload = JSON.stringify(body);
    }

    const response = await gatewayFetch(buildUrl(options.baseUrl, path), {
      method,
      headers,
      body: payload,
      signal: requestOptions?.signal
    });
    const parsed = await parseGatewayResponse(response);

    if (!response.ok) {
      const message =
        typeof parsed === "object" &&
        parsed !== null &&
        "error" in parsed &&
        typeof (parsed as Record<string, unknown>).error === "string"
          ? String((parsed as Record<string, unknown>).error)
          : `Gateway request failed with status ${response.status}`;
      throw new GatewayClientError(message, response.status, parsed);
    }

    return parsed as TResponse;
  }

  async function requestText(
    method: string,
    path: string,
    requestOptions?: GatewayRequestOptions
  ): Promise<string> {
    const headers = mergeHeaders(options.headers, requestOptions?.headers);
    headers.set("Accept", "text/csv");
    const response = await gatewayFetch(buildUrl(options.baseUrl, path), {
      method,
      headers,
      signal: requestOptions?.signal
    });
    const body = await response.text();
    if (!response.ok) {
      throw new GatewayClientError(`Gateway request failed with status ${response.status}`, response.status, body);
    }
    return body;
  }

  return {
    healthcheck: (requestOptions) =>
      request<GatewayHealthcheck>("GET", gatewayEndpointPaths.health, undefined, requestOptions),
    getComputeSettings: (requestOptions) =>
      request<GatewayComputeSettings>("GET", gatewayEndpointPaths.computeSettings, undefined, requestOptions),
    updateComputeSettings: (settings, requestOptions) =>
      request<GatewayComputeSettings>("PUT", gatewayEndpointPaths.computeSettings, settings, requestOptions),
    listWorkflows: (requestOptions) =>
      request<GatewayListResponse<GatewayWorkflowSummary>>(
        "GET",
        gatewayEndpointPaths.workflows,
        undefined,
        requestOptions
      ),
    createWorkflow: (workflow, requestOptions) =>
      request<CreateWorkflowResponse>(
        "POST",
        gatewayEndpointPaths.workflows,
        workflow,
        requestOptions
      ),
    importWorkflow: (workflowImport, requestOptions) =>
      request<ImportWorkflowResponse>(
        "POST",
        gatewayEndpointPaths.importWorkflow,
        workflowImport,
        requestOptions
      ),
    getWorkflow: (workflowId, requestOptions) =>
      request<GatewayWorkflowMetadata>(
        "GET",
        gatewayEndpointPaths.workflowDetail(workflowId),
        undefined,
        requestOptions
      ),
    updateWorkflow: (workflowId, workflow, requestOptions) =>
      request<UpdateWorkflowResponse>(
        "PUT",
        gatewayEndpointPaths.workflowDetail(workflowId),
        workflow,
        requestOptions
      ),
    executeWorkflow: (workflowId, requestOptions) =>
      request<GatewayExecutionRecord>(
        "POST",
        gatewayEndpointPaths.workflowExecute(workflowId),
        undefined,
        requestOptions
      ),
    listExecutions: (requestOptions) =>
      request<GatewayListResponse<GatewayExecutionRecord>>(
        "GET",
        gatewayEndpointPaths.executions,
        undefined,
        requestOptions
      ),
    getExecution: (executionId, requestOptions) =>
      request<GatewayExecutionRecord>(
        "GET",
        gatewayEndpointPaths.executionDetail(executionId),
        undefined,
        requestOptions
      ),
    transitionExecutionStatus: (executionId, transition, requestOptions) =>
      request<GatewayExecutionRecord>(
        "POST",
        gatewayEndpointPaths.executionStatus(executionId),
        transition,
        requestOptions
      ),
    listCheckpoints: (requestOptions) =>
      request<GatewayListResponse<GatewayCheckpointRecord>>(
        "GET",
        gatewayEndpointPaths.checkpoints,
        undefined,
        requestOptions
      ),
    createCheckpoint: (checkpoint, requestOptions) =>
      request<GatewayCheckpointCreateResponse>(
        "POST",
        gatewayEndpointPaths.checkpoints,
        checkpoint,
        requestOptions
      ),
    exportReproducibilityBundle: (bundleRequest, requestOptions) =>
      request<GatewayReproducibilityBundleExportResponse>(
        "POST",
        gatewayEndpointPaths.reproducibilityBundles,
        bundleRequest,
        requestOptions
      ),
    importReproducibilityBundle: (bundleRequest, requestOptions) =>
      request<GatewayReproducibilityBundleImportResponse>(
        "POST",
        gatewayEndpointPaths.reproducibilityBundleImport,
        bundleRequest,
        requestOptions
      ),
    exportLocalBackup: (backupRequest, requestOptions) =>
      request<GatewayLocalBackupExportResponse>(
        "POST",
        gatewayEndpointPaths.localBackups,
        backupRequest,
        requestOptions
      ),
    importLocalBackup: (backupRequest, requestOptions) =>
      request<GatewayLocalBackupImportResponse>(
        "POST",
        gatewayEndpointPaths.localBackupImport,
        backupRequest,
        requestOptions
      ),
    importDataProfile: (dataImportRequest, requestOptions) =>
      request<GatewayDataImportProfileResponse>(
        "POST",
        gatewayEndpointPaths.localDataImport,
        dataImportRequest,
        requestOptions
      ),
    listDataScienceProjects: (requestOptions) =>
      request<GatewayListResponse<DataScienceProject>>(
        "GET",
        gatewayEndpointPaths.dataScienceProjects,
        undefined,
        requestOptions
      ),
    createDataScienceProject: (projectRequest, requestOptions) =>
      request<DataScienceProject>(
        "POST",
        gatewayEndpointPaths.dataScienceProjects,
        projectRequest,
        requestOptions
      ),
    getDataScienceProject: (projectId, requestOptions) =>
      request<DataScienceProject>(
        "GET",
        gatewayEndpointPaths.dataScienceProject(projectId),
        undefined,
        requestOptions
      ),
    updateDataScienceProject: (projectId, projectRequest, requestOptions) =>
      request<DataScienceProject>(
        "PUT",
        gatewayEndpointPaths.dataScienceProject(projectId),
        projectRequest,
        requestOptions
      ),
    runDataScienceProjectTransformFitApply: (projectId, transformRequest, requestOptions) =>
      request<RunTransformFitApplyResponse>(
        "POST",
        gatewayEndpointPaths.dataScienceProjectTransformFitApply(projectId),
        transformRequest ?? {},
        requestOptions
      ),
    runDataScienceProjectStatisticalAnalysis: (projectId, analysisRequest, requestOptions) =>
      request<RunStatisticalAnalysisResponse>(
        "POST",
        gatewayEndpointPaths.dataScienceProjectStatisticalAnalysisRun(projectId),
        analysisRequest ?? {},
        requestOptions
      ),
    runDataScienceProjectTuningStudy: (projectId, tuningRequest, requestOptions) =>
      request<RunTuningStudyResponse>(
        "POST",
        gatewayEndpointPaths.dataScienceProjectTuningRun(projectId),
        tuningRequest ?? {},
        requestOptions
      ),
    runDataScienceProjectFinalEvaluation: (projectId, evaluationRequest, requestOptions) =>
      request<RunFinalEvaluationResponse>(
        "POST",
        gatewayEndpointPaths.dataScienceProjectFinalEvaluationRun(projectId),
        evaluationRequest ?? {},
        requestOptions
      ),
    runDataScienceProjectPredictionExport: (projectId, predictionRequest, requestOptions) =>
      request<RunPredictionExportResponse>(
        "POST",
        gatewayEndpointPaths.dataScienceProjectPredictionExport(projectId),
        predictionRequest ?? {},
        requestOptions
      ),
    runDataScienceProjectDriftReport: (projectId, driftRequest, requestOptions) =>
      request<RunDriftReportResponse>(
        "POST",
        gatewayEndpointPaths.dataScienceProjectDriftRun(projectId),
        driftRequest ?? {},
        requestOptions
      ),
    runDataScienceProjectModelLifecycleAction: (projectId, lifecycleRequest, requestOptions) =>
      request<RunModelLifecycleActionResponse>(
        "POST",
        gatewayEndpointPaths.dataScienceProjectModelLifecycle(projectId),
        lifecycleRequest,
        requestOptions
      ),
    runWorkflowTransform: (workflowId, transformRequest, requestOptions) =>
      request<GatewayTransformRunResponse>(
        "POST",
        gatewayEndpointPaths.workflowTransformRun(workflowId),
        transformRequest ?? {},
        requestOptions
      ),
    getWorkflowTransformHistory: (workflowId, requestOptions) =>
      request<GatewayTransformHistoryResponse>(
        "GET",
        gatewayEndpointPaths.workflowTransformHistory(workflowId),
        undefined,
        requestOptions
      ),
    runWorkflowMlExperiment: (workflowId, experimentRequest, requestOptions) =>
      request<GatewayMlExperimentRunResponse>(
        "POST",
        gatewayEndpointPaths.workflowMlExperimentRun(workflowId),
        experimentRequest ?? {},
        requestOptions
      ),
    getWorkflowMlExperimentHistory: (workflowId, requestOptions) =>
      request<GatewayMlExperimentHistoryResponse>(
        "GET",
        gatewayEndpointPaths.workflowMlExperimentHistory(workflowId),
        undefined,
        requestOptions
      ),
    registerWorkflowModel: (workflowId, modelRequest, requestOptions) =>
      request<GatewayModelRegistryResponse>(
        "POST",
        gatewayEndpointPaths.workflowModelRegister(workflowId),
        modelRequest ?? {},
        requestOptions
      ),
    listWorkflowModels: (workflowId, requestOptions) =>
      request<GatewayModelRegistryListResponse>(
        "GET",
        gatewayEndpointPaths.workflowModels(workflowId),
        undefined,
        requestOptions
      ),
    packageWorkflowDeploy: (workflowId, deployRequest, requestOptions) =>
      request<GatewayDeployPackageResponse>(
        "POST",
        gatewayEndpointPaths.workflowDeployPackage(workflowId),
        deployRequest ?? {},
        requestOptions
      ),
    listWorkflowDeployPackages: (workflowId, requestOptions) =>
      request<GatewayDeployPackageHistoryResponse>(
        "GET",
        gatewayEndpointPaths.workflowDeployPackages(workflowId),
        undefined,
        requestOptions
      ),
    listPublishedDashboards: (workflowId, requestOptions) =>
      request<GatewayPublishedDashboardListResponse>(
        "GET",
        gatewayEndpointPaths.workflowPublishedDashboards(workflowId),
        undefined,
        requestOptions
      ),
    getPublishedDashboard: (dashboardId, readRequest, requestOptions) =>
      request<PublishedDashboardDefinition>(
        "GET",
        gatewayEndpointPaths.publishedDashboard(dashboardId, readRequest),
        undefined,
        requestOptions
      ),
    getPublishedDashboardChartData: (dashboardId, chartId, readRequest, requestOptions) =>
      request<GatewayDashboardChartDataResponse>(
        "GET",
        gatewayEndpointPaths.publishedDashboardChartData(dashboardId, chartId, readRequest),
        undefined,
        requestOptions
      ),
    getPublishedDashboardChartDataCsv: (dashboardId, chartId, readRequest, requestOptions) =>
      requestText(
        "GET",
        gatewayEndpointPaths.publishedDashboardChartDataCsv(dashboardId, chartId, readRequest),
        requestOptions
      ),
    publishDashboard: (workflowId, dashboardId, publishRequest, requestOptions) =>
      request<GatewayDashboardPublishResponse>(
        "POST",
        gatewayEndpointPaths.publishDashboard(workflowId, dashboardId),
        publishRequest,
        requestOptions
      ),
    exportVisualizeCheckpoint: (workflowId, dashboardId, exportRequest, requestOptions) =>
      request<GatewayVisualizeCheckpointExportResponse>(
        "POST",
        gatewayEndpointPaths.workflowVisualizeCheckpointExport(workflowId, dashboardId),
        exportRequest ?? {},
        requestOptions
      ),
    listHubExtensions: (requestOptions) =>
      request<GatewayListResponse<GatewayHubExtensionRecord>>(
        "GET",
        gatewayEndpointPaths.hubExtensions,
        undefined,
        requestOptions
      ),
    registerHubExtension: (registerRequest, requestOptions) =>
      request<GatewayHubRegisterResponse>(
        "POST",
        gatewayEndpointPaths.hubExtensionRegister,
        registerRequest,
        requestOptions
      ),
    installHubExtension: (extensionId, installRequest, requestOptions) =>
      request<GatewayHubInstallResponse>(
        "POST",
        gatewayEndpointPaths.hubExtensionInstall(extensionId),
        installRequest,
        requestOptions
      ),
    getAuthPolicy: (requestOptions) =>
      request<GatewayAuthPolicy>(
        "GET",
        gatewayEndpointPaths.authPolicies,
        undefined,
        requestOptions
      ),
    updateAuthPolicy: (policy, requestOptions) =>
      request<GatewayAuthPolicy>(
        "PUT",
        gatewayEndpointPaths.authPolicies,
        policy,
        requestOptions
      ),
    getAuthDirectory: (requestOptions) =>
      request<GatewayAuthDirectory>(
        "GET",
        gatewayEndpointPaths.authDirectory,
        undefined,
        requestOptions
      ),
    updateAuthDirectory: (directory, requestOptions) =>
      request<GatewayAuthDirectory>(
        "PUT",
        gatewayEndpointPaths.authDirectory,
        directory,
        requestOptions
      ),
    queryAuditActions: (requestOptions) =>
      request<GatewayAuditQueryResponse>(
        "GET",
        gatewayEndpointPaths.auditActions,
        undefined,
        requestOptions
      )
  };
}

export const createGatewayClient = createGatewayApiClient;

export function createGatewayRealtimeClient(
  options: GatewayRealtimeClientOptions
): GatewayRealtimeClient {
  const RealtimeSocket = options.WebSocket ?? globalThis.WebSocket;
  if (!RealtimeSocket) {
    throw new Error("WebSocket implementation required to create Gateway realtime client");
  }

  const socket = new RealtimeSocket(buildRealtimeUrl(options.baseUrl));
  let nextRequestId = 1;
  const pendingRequests = new Map<
    number,
    {
      reject: (error: unknown) => void;
      resolve: (value: unknown) => void;
    }
  >();

  socket.addEventListener("message", (event) => {
    const rawData = typeof event.data === "string" ? event.data : String(event.data);
    const payload = JSON.parse(rawData) as
      | GatewayRealtimeSuccessResponse<unknown>
      | GatewayRealtimeErrorResponse
      | GatewayRealtimeNotification;

    if ("id" in payload) {
      const pendingRequest = pendingRequests.get(payload.id ?? -1);
      if (!pendingRequest) {
        return;
      }

      pendingRequests.delete(payload.id ?? -1);
      if ("error" in payload) {
        pendingRequest.reject(
          new GatewayClientError(payload.error.message, payload.error.code, payload.error)
        );
        return;
      }

      pendingRequest.resolve(payload.result);
    }
  });

  socket.addEventListener("close", () => {
    for (const [requestId, pendingRequest] of pendingRequests) {
      pendingRequests.delete(requestId);
      pendingRequest.reject(new Error("Gateway realtime connection closed"));
    }
  });

  return {
    socket,
    close: (code, reason) => {
      socket.close(code, reason);
    },
    request: <TResult>(method: (typeof jsonRpcMethods)[number], params: Record<string, unknown>) => {
      const requestId = nextRequestId;
      nextRequestId += 1;

      return new Promise<TResult>((resolve, reject) => {
        pendingRequests.set(requestId, {
          reject,
          resolve: (value) => {
            resolve(value as TResult);
          }
        });
        socket.send(
          JSON.stringify({
            jsonrpc: "2.0",
            id: requestId,
            method,
            params
          } satisfies GatewayRealtimeRequest)
        );
      });
    }
  };
}
