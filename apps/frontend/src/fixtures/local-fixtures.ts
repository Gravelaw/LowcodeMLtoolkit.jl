import type {
  DashboardDatasetRow,
  GatewayCheckpointRecord,
  GatewayDataImportProfile,
  GatewayDeployPackageRecord,
  GatewayHealthcheck,
  GatewayMlExperimentRecord,
  GatewayModelRegistryRecord,
  GatewayTransformRunRecord,
  GatewayVisualizeCheckpointExportRecord,
  GatewayWorkflowSummary,
  PublishedDashboardDefinition,
  WorkflowDefinition
} from "@juliaflow/contracts";

export const workflowId = "wf-local-churn";
export const dashboardId = "dashboard-local-churn";

export interface DatasetRow {
  customer_id: string;
  tenure_months: number;
  monthly_charges: number;
  contract_type: "monthly" | "annual" | "two_year";
  churn_risk: number;
  label: "retained" | "churned";
}

export const churnRows: DatasetRow[] = [
  { customer_id: "C-1001", tenure_months: 4, monthly_charges: 92.1, contract_type: "monthly", churn_risk: 0.82, label: "churned" },
  { customer_id: "C-1002", tenure_months: 28, monthly_charges: 63.4, contract_type: "annual", churn_risk: 0.22, label: "retained" },
  { customer_id: "C-1003", tenure_months: 13, monthly_charges: 108.8, contract_type: "monthly", churn_risk: 0.67, label: "churned" },
  { customer_id: "C-1004", tenure_months: 52, monthly_charges: 74.2, contract_type: "two_year", churn_risk: 0.14, label: "retained" },
  { customer_id: "C-1005", tenure_months: 7, monthly_charges: 88.5, contract_type: "monthly", churn_risk: 0.73, label: "churned" }
];

export const localHealth: GatewayHealthcheck = {
  service: "api-gateway",
  status: "ok",
  localProfile: "single-user",
  localHome: "/Users/alexj/JuliaFlowLocal",
  metadataMode: "single-user",
  metadataBackend: "file",
  metadataRoot: "/Users/alexj/JuliaFlowLocal/metadata",
  metadataReady: true,
  metadataSchemaStatus: "not_required",
  metadataConcurrencyStatus: "single_writer",
  metadataCapabilities: ["workflows", "executions", "publishedDashboards", "authPolicy", "auditEvents"],
  dataEstateRoot: "/Users/alexj/JuliaFlowLocal/data",
  dataEstateZones: [
    { name: "raw", path: "/Users/alexj/JuliaFlowLocal/data/raw", exists: true, writable: true },
    { name: "processed", path: "/Users/alexj/JuliaFlowLocal/data/processed", exists: true, writable: true },
    { name: "features", path: "/Users/alexj/JuliaFlowLocal/data/features", exists: true, writable: true },
    { name: "models", path: "/Users/alexj/JuliaFlowLocal/data/models", exists: true, writable: true },
    { name: "dashboards", path: "/Users/alexj/JuliaFlowLocal/data/dashboards", exists: true, writable: true },
    { name: "backups", path: "/Users/alexj/JuliaFlowLocal/data/_backups", exists: true, writable: true }
  ],
  dataEstateReady: true,
  dataEstateManaged: true,
  dataEstateManifestPath: "/Users/alexj/JuliaFlowLocal/data/_manifests",
  dataEstateManifestReady: true,
  dataEstateManifestChecksums: [{ zone: "raw", path: "data/_manifests/raw.json", exists: true, checksumSha256: "a".repeat(64) }],
  dataEstateArtifactFormats: ["arrow_ipc", "parquet"],
  dataEstateQuotaBytes: 512_000_000_000,
  dataEstateUsedBytes: 86_400_000_000,
  dataEstateCleanupStatus: "ready",
  dataEstateBackupRoot: "/Users/alexj/JuliaFlowLocal/data/_backups",
  dataEstateBackupStatus: "ready",
  localBackupRestoreReady: true,
  dataEstateDuckdbStatus: "ready",
  dataEstateDuckdbQueryPath: "/Users/alexj/JuliaFlowLocal/data/_duckdb/local-data-estate.sql",
  freeDiskStatus: "available",
  freeDiskBytes: 212_000_000_000,
  localServiceUrls: {
    gateway: "http://127.0.0.1:8088",
    execution: "process",
    frontend: "http://127.0.0.1:5173",
    streamWorker: "process",
    gpuWorker: "process"
  },
  postgresProfileStatus: "not_required",
  minioProfileStatus: "not_required",
  cloudCredentialsRequired: false,
  cpuThreadCount: 16,
  totalMemoryBytes: 16_000_000_000,
  freeMemoryBytes: 9_800_000_000,
  hardwareProfileStatus: "ready",
  hardwareSelectedBackend: "cpu",
  cpuSchedulerPolicy: "bounded_threads",
  cpuWorkerConcurrency: 4,
  cpuMemoryLimitBytes: 6_000_000_000,
  gpuReadinessStatus: "cpu_fallback",
  gpuFallbackReason: "not_required_for_local_churn_project",
  gpuCudaStatus: "not_requested",
  gpuHardwareDeviceCount: 0,
  gpuSimulatedDeviceCount: 0,
  gpuTotalVramBytes: 0,
  gpuDeviceSummaries: [],
  explainabilityEvidence: {
    status: "ready",
    generatedAt: "2026-06-17T10:00:00Z",
    workflowId,
    checkpointTag: "cp/local-churn-2026-06-17",
    datasetCard: {
      datasetId: "customer-churn-local",
      sourceUri: "data/raw/churn.csv",
      checksumSha256: "b".repeat(64),
      schemaSummary: [
        { name: "tenure_months", type: "Int64" },
        { name: "monthly_charges", type: "Float64" },
        { name: "contract_type", type: "String" }
      ],
      rowCount: 12500,
      limitations: ["Synthetic local fixture; no external data source"]
    },
    modelCard: {
      modelId: "churn_model_v1",
      kind: "MLJ.XGBoostClassifier",
      target: "churn",
      config: { max_depth: 4, seed: 42 },
      metrics: { auc: 0.912, f1: 0.861, accuracy: 0.893 },
      limitations: ["Local CPU training baseline"]
    },
    explanation: {
      method: "local_feature_contribution",
      featureImportance: [
        { feature: "tenure_months", importance: 0.32 },
        { feature: "monthly_charges", importance: 0.26 },
        { feature: "contract_type", importance: 0.21 },
        { feature: "support_tickets", importance: 0.11 }
      ],
      localExample: { rowId: "C-1001", prediction: 0.82, contributions: [] },
      warnings: ["Use local validation before deployment"]
    },
    reproducibilityBundleReady: true
  },
  hubCacheRoot: "/Users/alexj/JuliaFlowLocal/hub-cache",
  hubArtifactStorePath: "/Users/alexj/JuliaFlowLocal/hub-cache/artifact-store.json",
  hubMirrorRegistryPath: "/Users/alexj/JuliaFlowLocal/hub-cache/mirror-registry.json",
  hubArtifactCacheRoot: "/Users/alexj/JuliaFlowLocal/hub-cache/artifacts",
  hubCacheStatus: "ready",
  hubOfflineInstallReady: true,
  hubBundledExtensionCount: 8,
  hubInstalledLocalExtensionCount: 3,
  repositoryBackend: "file",
  storeRoot: "/Users/alexj/JuliaFlowLocal",
  workflowCount: 3,
  checkpointCount: 11,
  executionCount: 27,
  realtimeTransport: "jsonrpc_websocket",
  eventBackboneMode: "dual_write",
  eventConsumerPollMs: 250,
  streamWorkerMode: "inline",
  gpuWorkerMode: "process",
  gpuRegistryDeviceCount: 0,
  gpuFallbackAvailable: true,
  eventLogSize: 122,
  latestEventSequence: 122,
  gatewayConsumerCursor: 122,
  gatewayConsumerLag: 0,
  eventConsumerCatchupPercent: 100,
  activeStreamExecutions: 0,
  queuedGpuExecutions: 0,
  queuedStreamExecutions: 0,
  activeGpuExecutions: 0,
  gpuWorkerOwnedExecutions: 0,
  queuedExecutionsTotal: 0,
  runningExecutionsTotal: 0
};

export const localWorkflow: WorkflowDefinition = {
  version: "1.0.0",
  workflowId,
  name: "Customer Churn Local Pipeline",
  flowVariables: [{ name: "project", type: "String", default: "Customer_Churn_Project" }],
  runtime: { runMode: "batch" },
  nodes: [
    { id: "source", type: "source.local_csv", name: "churn.csv", executionHint: "cpu_only", ports: [{ id: "rows", direction: "output", type: "data_table" }], config: { path: "data/raw/churn.csv" } },
    { id: "profile", type: "profile.duckdb", name: "Profile In DuckDB", executionHint: "cpu_only", ports: [{ id: "rows", direction: "input", type: "data_table" }, { id: "profile", direction: "output", type: "data_table" }], config: {} },
    { id: "features", type: "transform.feature_engineer", name: "Feature Engineering", executionHint: "cpu_only", ports: [{ id: "rows", direction: "input", type: "data_table" }, { id: "features", direction: "output", type: "data_table" }], config: { impute: "median", encode: "onehot" } },
    { id: "train", type: "ml.xgboost", name: "Train Churn Model", executionHint: "cpu_only", ports: [{ id: "features", direction: "input", type: "data_table" }, { id: "model", direction: "output", type: "model" }], config: { target: "churn", seed: 42 } },
    { id: "dashboard", type: "bi.dashboard", name: "Local Dashboard", executionHint: "cpu_only", ports: [{ id: "features", direction: "input", type: "data_table" }, { id: "model", direction: "input", type: "model" }], config: { dashboardId } }
  ],
  connections: [
    { sourceNodeId: "source", sourcePortId: "rows", targetNodeId: "profile", targetPortId: "rows", dataType: "data_table" },
    { sourceNodeId: "profile", sourcePortId: "profile", targetNodeId: "features", targetPortId: "rows", dataType: "data_table" },
    { sourceNodeId: "features", sourcePortId: "features", targetNodeId: "train", targetPortId: "features", dataType: "data_table" },
    { sourceNodeId: "features", sourcePortId: "features", targetNodeId: "dashboard", targetPortId: "features", dataType: "data_table" },
    { sourceNodeId: "train", sourcePortId: "model", targetNodeId: "dashboard", targetPortId: "model", dataType: "model" }
  ],
  dashboards: [
    {
      dashboardId,
      name: "Churn Operations",
      binding: { outletNodeId: "dashboard", datasetKey: "churn_rows", refreshMode: "manual" },
      charts: [
        { chartId: "risk", title: "Risk Distribution", family: "bar", xField: "contract_type", yField: "churn_risk", panel: { x: 0, y: 0, w: 6, h: 4 } },
        { chartId: "retention", title: "Retention Trend", family: "line", xField: "tenure_months", yField: "churn_risk", panel: { x: 6, y: 0, w: 6, h: 4 } }
      ]
    }
  ]
};

export const workflowSummary: GatewayWorkflowSummary = {
  workflowId,
  name: localWorkflow.name,
  version: "1.0.0",
  nodeCount: localWorkflow.nodes.length,
  latestCheckpoint: "cp/local-churn-2026-06-17",
  graphRevision: 8,
  dashboardCount: 1,
  runMode: "batch"
};

export const dataProfile: GatewayDataImportProfile = {
  datasetId: "customer-churn-local",
  sourceUri: "data/raw/churn.csv",
  sourceFormat: "csv",
  targetZone: "raw",
  artifactRef: "data/raw/customer-churn-local.arrow",
  artifactFormats: ["arrow_ipc", "parquet"],
  checksumSha256: "b".repeat(64),
  rowCount: 12500,
  schemaSummary: [
    { name: "customer_id", type: "String" },
    { name: "tenure_months", type: "Int64" },
    { name: "monthly_charges", type: "Float64" },
    { name: "contract_type", type: "String" },
    { name: "churn", type: "Bool" }
  ],
  profileSummary: [
    { name: "tenure_months", type: "Int64", quality: "99.8% complete" },
    { name: "monthly_charges", type: "Float64", quality: "0 outliers clipped" },
    { name: "contract_type", type: "String", quality: "3 categories" }
  ],
  manifestReady: true,
  manifestChecksums: localHealth.dataEstateManifestChecksums,
  duckdbStatus: "ready",
  importedAt: "2026-06-17T10:00:00Z",
  localOnly: true
};

export const transformRuns: GatewayTransformRunRecord[] = [
  {
    runId: "transform-2026-06-17-001",
    workflowId,
    workflowVersion: "1.0.0",
    checkpointTag: "cp/features-v3",
    status: "completed",
    startedAt: "2026-06-17T10:10:00Z",
    finishedAt: "2026-06-17T10:10:18Z",
    stageCount: 4,
    nodeIds: ["source", "profile", "features", "dashboard"],
    nodeResults: [
      { nodeId: "source", nodeType: "source.local_csv", status: "executed", rowCount: 12500, artifactRefs: ["data/raw/customer-churn-local.arrow"] },
      { nodeId: "features", nodeType: "transform.feature_engineer", status: "executed", rowCount: 12500, artifactRefs: ["data/features/churn_features.parquet"] }
    ],
    artifactEvidence: [{ nodeId: "features", artifactRefs: ["data/features/churn_features.parquet", "data/features/churn_features.arrow"] }],
    localOnly: true
  }
];

export const mlExperiments: GatewayMlExperimentRecord[] = [
  {
    experimentId: "exp-churn-xgb-042",
    workflowId,
    workflowVersion: "1.0.0",
    executionId: "exec-ml-042",
    checkpointTag: "cp/model-v1.2",
    status: "completed",
    modelId: "churn_model_v1",
    modelKind: "MLJ.XGBoostClassifier",
    target: "churn",
    datasetId: "customer-churn-local",
    datasetChecksumSha256: "b".repeat(64),
    metrics: { auc: 0.912, f1: 0.861, precision: 0.872, recall: 0.85, accuracy: 0.893 },
    featureImportance: localHealth.explainabilityEvidence.explanation.featureImportance,
    hardwareBackend: "CPU (Local)",
    gpuReadinessStatus: "cpu_fallback",
    artifactEvidence: [
      { kind: "model", artifactRef: "data/models/churn_model_v1.jls", checksumSha256: "c".repeat(64) },
      { kind: "explanation", artifactRef: "data/models/churn_model_v1_explain.json", checksumSha256: "d".repeat(64) }
    ],
    startedAt: "2026-06-17T10:12:00Z",
    finishedAt: "2026-06-17T10:15:41Z",
    localOnly: true
  }
];

export const modelRegistry: GatewayModelRegistryRecord[] = [
  {
    registryId: "reg-churn-v1",
    modelId: "Churn Prediction",
    workflowId,
    workflowVersion: "1.0.0",
    checkpointTag: "cp/model-v1.2",
    experimentId: "exp-churn-xgb-042",
    executionId: "exec-ml-042",
    modelKind: "MLJ.XGBoostClassifier",
    target: "churn",
    status: "registered",
    tags: ["churn", "classification", "local"],
    owner: "julia_user",
    primaryMetricName: "AUC",
    primaryMetricValue: 0.912,
    datasetId: "customer-churn-local",
    datasetChecksumSha256: "b".repeat(64),
    artifactEvidence: [
      { kind: "model", artifactRef: "data/models/churn_model_v1.jls", checksumSha256: "c".repeat(64) },
      { kind: "config", artifactRef: "data/models/training_config.toml", checksumSha256: "e".repeat(64) }
    ],
    registeredAt: "2026-06-17T10:18:00Z",
    updatedAt: "2026-06-17T10:24:00Z",
    deploymentStatus: "local_ready",
    localOnly: true
  },
  {
    registryId: "reg-clv-v1",
    modelId: "Customer Lifetime Value",
    workflowId,
    workflowVersion: "1.0.0",
    checkpointTag: "cp/clv-v1",
    modelKind: "MLJ.EvoTreeRegressor",
    target: "ltv",
    status: "candidate",
    tags: ["clv", "finance"],
    owner: "julia_user",
    primaryMetricName: "RMSE",
    primaryMetricValue: 412.3,
    datasetId: "customer-churn-local",
    datasetChecksumSha256: "b".repeat(64),
    artifactEvidence: [{ kind: "model", artifactRef: "data/models/clv_model_v1.jls", checksumSha256: "f".repeat(64) }],
    registeredAt: "2026-06-16T15:00:00Z",
    updatedAt: "2026-06-17T09:00:00Z",
    deploymentStatus: "not_deployed",
    localOnly: true
  }
];

export const deployPackages: GatewayDeployPackageRecord[] = [
  {
    packageId: "pkg-churn-local-001",
    workflowId,
    workflowVersion: "1.0.0",
    modelId: "Churn Prediction",
    checkpointTag: "cp/model-v1.2",
    endpointUrl: "http://127.0.0.1:8099/predict/churn",
    endpointPath: "/predict/churn",
    host: "127.0.0.1",
    port: 8099,
    serviceRef: "data/deploy/churn/service.jl",
    packageRef: "data/deploy/churn/package.tar.gz",
    packageChecksumSha256: "1".repeat(64),
    serviceCode: "using HTTP\nHTTP.serve(\"127.0.0.1\", 8099) do req\n    return HTTP.Response(200, \"local churn prediction\")\nend",
    runCommand: "julia --project=. data/deploy/churn/service.jl",
    modelRegistryId: "reg-churn-v1",
    deploymentStatus: "local_ready",
    artifactEvidence: [
      { kind: "service", artifactRef: "data/deploy/churn/service.jl", checksumSha256: "2".repeat(64) },
      { kind: "model", artifactRef: "data/models/churn_model_v1.jls", checksumSha256: "c".repeat(64) }
    ],
    createdAt: "2026-06-17T10:30:00Z",
    localOnly: true
  }
];

export const visualizeExports: GatewayVisualizeCheckpointExportRecord[] = [
  {
    exportId: "viz-export-001",
    workflowId,
    dashboardId,
    dashboardVersion: 3,
    checkpointTag: "cp/dashboard-v3",
    checkpointSummary: "Local dashboard snapshot with churn explainability",
    bundleId: "bundle-churn-v3",
    bundleChecksumSha256: "3".repeat(64),
    dashboardSnapshotReady: true,
    artifactEvidence: [
      { kind: "dashboard_snapshot", artifactRef: "data/dashboards/churn_v3.json", checksumSha256: "4".repeat(64) },
      { kind: "reproducibility_bundle", artifactRef: "data/checkpoints/bundle-churn-v3.json", checksumSha256: "3".repeat(64) }
    ],
    createdAt: "2026-06-17T10:26:00Z",
    localOnly: true
  }
];

export const checkpoints: GatewayCheckpointRecord[] = [
  { tag: "cp/local-churn-2026-06-17", summary: "Local churn workflow with data, model, dashboard, and deploy evidence.", createdAt: "2026-06-17T10:32:00Z", explainabilityEvidence: localHealth.explainabilityEvidence },
  { tag: "cp/features-v3", summary: "Feature table materialized as local Arrow and Parquet artifacts.", createdAt: "2026-06-17T10:10:18Z" }
];

export const publishedDashboard: PublishedDashboardDefinition = {
  dashboardId,
  workflowId,
  name: "Churn Operations",
  version: 3,
  publishedAt: "2026-06-17T10:26:00Z",
  visibility: "workspace",
  shareToken: "local-share-token",
  binding: { outletNodeId: "dashboard", datasetKey: "churn_rows", refreshMode: "manual" },
  charts: localWorkflow.dashboards?.[0]?.charts ?? [],
  datasets: { churn_rows: churnRows as unknown as DashboardDatasetRow[] }
};

export const projectFiles = [
  { path: "Customer_Churn_Project/data/churn.csv", size: "25.1 GB", status: "profiled" },
  { path: "Customer_Churn_Project/notebooks/eda.jl", size: "24 KB", status: "local" },
  { path: "Customer_Churn_Project/models/churn_model_v1.jls", size: "87.6 MB", status: "registered" },
  { path: "Customer_Churn_Project/results/metrics.csv", size: "3.1 KB", status: "checkpointed" }
];

export const localCode = {
  data: "using CSV, DataFrames, Arrow, DuckDB\nrows = CSV.read(\"data/raw/churn.csv\", DataFrame)\nArrow.write(\"data/raw/customer-churn-local.arrow\", rows)",
  transform: "using DataFrames\nfeatures = transform(churn, :contract_type => ByRow(string) => :contract)\nselect!(features, Not(:customer_id))",
  ml: "using MLJ\nmodel = @load XGBoostClassifier pkg=XGBoost\nmach = machine(model, features, y)\nfit!(mach)",
  deploy: deployPackages[0].serviceCode
};
