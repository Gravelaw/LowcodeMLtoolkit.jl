import type {
  DashboardDatasetRow,
  DataScienceProject,
  GatewayCheckpointRecord,
  GatewayDataImportProfile,
  GatewayDeployPackageRecord,
  GatewayExecutionRecord,
  GatewayHealthcheck,
  GatewayInteractiveChartSpec,
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

export const superstoreRows = [
  { order_id: "CA-2016-152156", order_date: "2016-11-08", segment: "Consumer", category: "Furniture", sales: 261.96, profit: 41.91 },
  { order_id: "CA-2016-152156", order_date: "2016-11-08", segment: "Consumer", category: "Furniture", sales: 731.94, profit: 219.58 },
  { order_id: "CA-2016-138688", order_date: "2016-06-12", segment: "Corporate", category: "Office Supplies", sales: 14.62, profit: 6.87 },
  { order_id: "US-2015-108966", order_date: "2015-10-11", segment: "Home Office", category: "Technology", sales: 957.58, profit: -383.03 }
];

const chartTimestamp = "2026-06-17T10:00:00Z";

function plotlyChartSpec({
  chartId,
  title,
  kind,
  data,
  summary,
  sourceLabel,
  height = 240,
  status,
  staleReason
}: {
  chartId: string;
  title: string;
  kind: GatewayInteractiveChartSpec["kind"];
  data: GatewayInteractiveChartSpec["data"];
  summary: string;
  sourceLabel: string;
  height?: number;
  status?: GatewayInteractiveChartSpec["status"];
  staleReason?: string;
}): GatewayInteractiveChartSpec {
  return {
    chartId,
    title,
    renderer: "plotly",
    kind,
    status: status ?? "ready",
    data,
    layout: {
      height,
      paper_bgcolor: "rgba(0,0,0,0)",
      plot_bgcolor: "rgba(0,0,0,0)",
      margin: { l: 34, r: 12, t: 20, b: 34 },
      font: { family: "Inter, system-ui, sans-serif", size: 11, color: "#344054" },
      xaxis: { automargin: true },
      yaxis: { automargin: true }
    },
    config: { displaylogo: false, responsive: true },
    source: { label: sourceLabel, localOnly: true, updatedAt: chartTimestamp },
    summary,
    staleReason,
    export: { fileName: chartId, png: true, html: true }
  };
}

const workspaceCharts: GatewayInteractiveChartSpec[] = [
  plotlyChartSpec({
    chartId: "workspace-cpu-trend",
    title: "CPU Trend",
    kind: "line",
    sourceLabel: "Fixture gateway health",
    summary: "CPU usage trend generated from local workspace health evidence.",
    data: [{ type: "scatter", mode: "lines+markers", x: ["-25m", "-20m", "-15m", "-10m", "-5m", "now"], y: [18, 21, 16, 26, 23, 28], line: { color: "#5b2eea", width: 3 } }]
  }),
  plotlyChartSpec({
    chartId: "workspace-ram-trend",
    title: "RAM Trend",
    kind: "line",
    sourceLabel: "Fixture gateway health",
    summary: "RAM usage trend generated from local workspace health evidence.",
    data: [{ type: "scatter", mode: "lines+markers", x: ["-25m", "-20m", "-15m", "-10m", "-5m", "now"], y: [32, 35, 37, 36, 39, 39], line: { color: "#16a34a", width: 3 } }]
  }),
  plotlyChartSpec({
    chartId: "workspace-disk-trend",
    title: "Disk Trend",
    kind: "line",
    sourceLabel: "Fixture data estate",
    summary: "Disk usage trend generated from managed local data estate evidence.",
    status: "stale",
    staleReason: "Disk evidence is older than the latest workspace health poll.",
    data: [{ type: "scatter", mode: "lines+markers", x: ["-25m", "-20m", "-15m", "-10m", "-5m", "now"], y: [36, 37, 38, 39, 40, 41], line: { color: "#2563eb", width: 3 } }]
  })
];

const churnProfileCharts: GatewayInteractiveChartSpec[] = [
  plotlyChartSpec({
    chartId: "data-churn-balance",
    title: "Churn Balance",
    kind: "bar",
    sourceLabel: "customer-churn-local profile",
    summary: "Target balance is generated from local profile evidence.",
    data: [{ type: "bar", x: ["retained", "churned"], y: [9188, 3312], marker: { color: ["#16a34a", "#5b2eea"] } }]
  }),
  plotlyChartSpec({
    chartId: "data-contract-risk",
    title: "Risk By Contract",
    kind: "bar",
    sourceLabel: "customer-churn-local profile",
    summary: "Contract risk is generated from local profile evidence.",
    data: [{ type: "bar", x: ["monthly", "annual", "two_year"], y: [0.61, 0.24, 0.12], marker: { color: ["#5b2eea", "#2563eb", "#16a34a"] } }]
  }),
  plotlyChartSpec({
    chartId: "data-missingness-churn",
    title: "Missing Values",
    kind: "bar",
    sourceLabel: "customer-churn-local profile",
    summary: "Missing value counts are generated from local profile evidence.",
    data: [{ type: "bar", x: ["customer_id", "tenure_months", "monthly_charges", "contract_type", "churn"], y: [0, 25, 0, 0, 0], marker: { color: "#d97706" } }]
  })
];

const superstoreProfileCharts: GatewayInteractiveChartSpec[] = [
  plotlyChartSpec({
    chartId: "data-sales-category",
    title: "Sales By Category",
    kind: "bar",
    sourceLabel: "global-superstore-local profile",
    summary: "Sales by category is generated from local profile evidence.",
    data: [{ type: "bar", x: ["Furniture", "Office Supplies", "Technology"], y: [741999, 719047, 836154], marker: { color: ["#5b2eea", "#2563eb", "#16a34a"] } }]
  }),
  plotlyChartSpec({
    chartId: "data-profit-segment",
    title: "Profit By Segment",
    kind: "bar",
    sourceLabel: "global-superstore-local profile",
    summary: "Profit by segment is generated from local profile evidence.",
    data: [{ type: "bar", x: ["Consumer", "Corporate", "Home Office"], y: [134119, 91979, 60299], marker: { color: ["#5b2eea", "#2563eb", "#16a34a"] } }]
  }),
  plotlyChartSpec({
    chartId: "data-missingness-superstore",
    title: "Missing Values",
    kind: "bar",
    sourceLabel: "global-superstore-local profile",
    summary: "Missing value counts are generated from local profile evidence.",
    data: [{ type: "bar", x: ["order_id", "order_date", "segment", "category", "sales", "profit"], y: [0, 0, 0, 0, 0, 0], marker: { color: "#d97706" } }]
  })
];

const transformCharts: GatewayInteractiveChartSpec[] = [
  plotlyChartSpec({
    chartId: "transform-rows-transform-2026-06-17-001",
    title: "Rows By Transform Node",
    kind: "bar",
    sourceLabel: "latest transform run",
    summary: "Rows by transform node are generated from local run evidence.",
    data: [{ type: "bar", x: ["source", "features"], y: [12500, 12500], marker: { color: "#5b2eea" } }]
  })
];

export const localHealth: GatewayHealthcheck = {
  service: "api-gateway",
  status: "ok",
  runtime: {
    mode: "demo",
    fixtureProvenance: "fixture",
    fixtureSubstitutionAllowed: true,
    unavailable: []
  },
  runtimeMode: "demo",
  fixtureProvenance: "fixture",
  fixtureSubstitutionAllowed: true,
  unavailable: [],
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
  computeSettings: {
    selectedBackend: "cpu",
    cpuWorkerConcurrency: 4,
    cpuMemoryLimitBytes: 6_000_000_000,
    gpuPreference: "cpu_fallback",
    blasThreadCount: 16,
    schedulerPolicy: "bounded_threads",
    source: "default",
    updatedAt: "2026-06-17T10:00:00Z"
  },
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
  runningExecutionsTotal: 0,
  workspaceSummary: {
    cpuUsagePercent: 28,
    ramUsedBytes: 6_200_000_000,
    ramTotalBytes: 16_000_000_000,
    diskUsedBytes: 300_000_000_000,
    diskTotalBytes: 512_000_000_000,
    localDatasetCount: 18,
    localModelCount: 24,
    recentRunCount: 7,
    packageInstalledCount: 142,
    packageOutdatedCount: 2,
    runtimeUptimeLabel: "2d 14h 32m",
    activeJobCount: 2,
    projectRoot: "/Users/alexj/JuliaFlowLocal/Projects",
    activities: [
      { label: "Pipeline completed", detail: "Customer Churn Analysis Pipeline", occurredAt: "2026-06-17T10:42:00Z", status: "completed" },
      { label: "Model trained", detail: "churn_model_v1.jls", occurredAt: "2026-06-17T10:24:00Z", status: "completed" },
      { label: "Dataset loaded", detail: "churn.csv (12,500 rows)", occurredAt: "2026-06-17T09:58:00Z", status: "ready" },
      { label: "EDA notebook executed", detail: "eda.jl", occurredAt: "2026-06-17T09:41:00Z", status: "completed" },
      { label: "Transform completed", detail: "Feature Engineering Pipeline", occurredAt: "2026-06-17T08:59:00Z", status: "completed" }
    ],
    artifacts: [
      { path: "Customer_Churn_Project/Project.toml", kind: "code", size: "2.1 KB", status: "local", localOnly: true },
      { path: "Customer_Churn_Project/data/churn.csv", kind: "dataset", size: "25.1 GB", status: "profiled", localOnly: true },
      { path: "Customer_Churn_Project/data/features/churn_features.parquet", kind: "table", size: "18.7 MB", status: "materialized", localOnly: true },
      { path: "Customer_Churn_Project/models/churn_model_v1.jls", kind: "model", size: "87.6 MB", status: "registered", localOnly: true },
      { path: "Customer_Churn_Project/results/metrics.csv", kind: "metadata", size: "3.1 KB", status: "checkpointed", localOnly: true }
    ]
  },
  charts: workspaceCharts
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
    { name: "customer_id", type: "String", quality: "unique customer key", role: "id", missingCount: 0, distinctCount: 12500, outlierCount: 0 },
    { name: "tenure_months", type: "Int64", quality: "99.8% complete", role: "feature", missingCount: 25, distinctCount: 73, outlierCount: 0 },
    { name: "monthly_charges", type: "Float64", quality: "0 outliers clipped", role: "feature", missingCount: 0, distinctCount: 1210, outlierCount: 0 },
    { name: "contract_type", type: "String", quality: "3 categories", role: "feature", missingCount: 0, distinctCount: 3, outlierCount: 0 },
    { name: "churn", type: "Bool", quality: "target balance checked", role: "label", missingCount: 0, distinctCount: 2, outlierCount: 0 }
  ],
  manifestReady: true,
  manifestChecksums: localHealth.dataEstateManifestChecksums,
  duckdbStatus: "ready",
  importedAt: "2026-06-17T10:00:00Z",
  localOnly: true,
  activeReadMode: "csv",
  sourceOptions: [
    { mode: "csv", label: "CSV raw source", path: "data/raw/churn.csv", status: "active", semantics: "Raw local file read for ingest and reproducible source checks." },
    { mode: "arrow_ipc", label: "Arrow IPC artifact", path: "data/raw/customer-churn-local.arrow", status: "ready", semantics: "Fast local columnar boundary used between JuliaFlow nodes." },
    { mode: "parquet", label: "Parquet managed artifact", path: "data/processed/customer-churn-local.parquet", status: "ready", semantics: "Durable local analytics artifact for processed and feature zones." },
    { mode: "duckdb", label: "DuckDB query view", path: "data/_duckdb/local-data-estate.sql", status: "ready", semantics: "Persistent local SQL view for profiling, joins, and aggregate reads." }
  ],
  lineageArtifacts: [
    { stage: "raw", artifactRef: "data/raw/churn.csv", format: "csv", checksumSha256: "b".repeat(64), rowCount: 12500 },
    { stage: "profiled", artifactRef: "data/raw/customer-churn-local.arrow", format: "arrow_ipc", checksumSha256: "b".repeat(64), rowCount: 12500 },
    { stage: "processed", artifactRef: "data/processed/customer-churn-local.parquet", format: "parquet", checksumSha256: "b".repeat(64), rowCount: 12500 },
    { stage: "query", artifactRef: "data/_duckdb/local-data-estate.sql", format: "duckdb", checksumSha256: "b".repeat(64), rowCount: 12500 }
  ],
  qualityChecks: [
    { checkId: "target-balance", label: "Target balance", status: "passed", detail: "Churn rate is 26.5%, suitable for stratified split." },
    { checkId: "leakage", label: "Leakage scan", status: "passed", detail: "No post-churn columns are marked as features." },
    { checkId: "missingness", label: "Missingness", status: "warning", detail: "25 tenure rows require imputation before training." }
  ],
  workflowReadiness: {
    targetColumn: "churn",
    trainTestSplit: "stratified 80/20",
    leakageWarnings: [],
    downstreamReady: true,
    recommendedNextAction: "Open ML Studio to train a local churn classifier or Transform to encode contract_type."
  },
  quickPlots: [
    { plotId: "churn-balance", title: "Churn Balance", kind: "target_balance", field: "churn", values: [{ label: "retained", value: 9188 }, { label: "churned", value: 3312 }] },
    { plotId: "contract-risk", title: "Risk By Contract", kind: "bar", field: "contract_type", values: [{ label: "monthly", value: 0.61 }, { label: "annual", value: 0.24 }, { label: "two_year", value: 0.12 }] }
  ],
  previewRows: churnRows.map(({ churn_risk: _risk, label, ...row }) => ({ ...row, churn: label === "churned" })),
  charts: churnProfileCharts
};

export const dataScienceProject: DataScienceProject = {
  schemaVersion: "1.0",
  projectId: "customer-churn-project",
  name: "Customer Churn Local Project",
  description: "Local project aggregate for schema diagnostics, validation discipline, and downstream ML evidence.",
  localOnly: true,
  createdAt: "2026-06-21T00:00:00Z",
  updatedAt: "2026-06-21T00:00:00Z",
  datasets: [
    {
      datasetId: dataProfile.datasetId,
      name: "Customer Churn",
      role: "train",
      sourceUri: dataProfile.sourceUri,
      localOnly: true,
      rowCount: dataProfile.rowCount,
      columnCount: dataProfile.schemaSummary.length,
      checksumSha256: dataProfile.checksumSha256,
      artifactRef: dataProfile.artifactRef
    }
  ],
  schemaContracts: [
    {
      schemaId: "schema-customer-churn-local",
      datasetId: dataProfile.datasetId,
      updatedAt: "2026-06-21T00:00:00Z",
      columns: [
        { name: "customer_id", inferredType: "String", logicalType: "identifier", role: "id", nullable: false, description: "Stable customer identifier used for row tracing." },
        { name: "tenure_months", inferredType: "Int64", logicalType: "continuous", role: "feature", nullable: true, unit: "months", description: "Customer tenure; nullable until imputation is configured." },
        { name: "monthly_charges", inferredType: "Float64", logicalType: "continuous", role: "feature", nullable: false, unit: "USD", description: "Monthly billing charge." },
        { name: "contract_type", inferredType: "String", logicalType: "categorical", role: "group", nullable: false, description: "Contract category, also suitable for grouped validation checks." },
        { name: "churn", inferredType: "Bool", logicalType: "binary", role: "target", nullable: false, description: "Binary churn target." }
      ]
    }
  ],
  splitPlans: [
    {
      splitPlanId: "split-customer-churn-validation",
      datasetId: dataProfile.datasetId,
      strategy: "stratified",
      trainFraction: 0.7,
      validationFraction: 0.15,
      testFraction: 0.15,
      groupColumn: "contract_type",
      seed: 42,
      locked: false,
      createdAt: "2026-06-21T00:00:00Z"
    }
  ],
  splitAssignments: [],
  validationFolds: [
    {
      foldId: "fold-customer-churn-001",
      splitPlanId: "split-customer-churn-validation",
      strategy: "stratified",
      index: 1,
      trainRef: "data/splits/customer-churn/train-fold-001.arrow",
      validationRef: "data/splits/customer-churn/validation-fold-001.arrow"
    }
  ],
  finalTestLocks: [],
  projectJobs: [],
  transformFitApplyRecords: [],
  statisticalAnalysisRuns: [],
  trainingPlans: [],
  tuningStudies: [],
  evaluationReports: [],
  predictionExports: [],
  modelRegistryRecords: [],
  modelLifecycleRecords: [],
  monitoringBaselines: [],
  driftReports: [],
  reproducibilityEvidence: [
    {
      refId: "schema-contract-customer-churn-local",
      kind: "schema_contract",
      localOnly: true,
      checksumSha256: dataProfile.checksumSha256,
      path: "data/contracts/schema-customer-churn-local.json",
      generatedAt: "2026-06-21T00:00:00Z"
    }
  ]
};

export const superstoreDataProfile: GatewayDataImportProfile = {
  datasetId: "global-superstore-local",
  sourceUri: "data/raw/global_superstore.csv",
  sourceFormat: "csv",
  targetZone: "raw",
  artifactRef: "data/raw/global-superstore-local.arrow",
  artifactFormats: ["arrow_ipc", "parquet"],
  checksumSha256: "9".repeat(64),
  rowCount: 9800,
  schemaSummary: [
    { name: "order_id", type: "String" },
    { name: "order_date", type: "Date" },
    { name: "segment", type: "String" },
    { name: "category", type: "String" },
    { name: "sales", type: "Float64" },
    { name: "profit", type: "Float64" }
  ],
  profileSummary: [
    { name: "order_id", type: "String", quality: "unique order-line key", role: "id", missingCount: 0, distinctCount: 5009, outlierCount: 0 },
    { name: "order_date", type: "Date", quality: "date range ready", role: "timestamp", missingCount: 0, distinctCount: 1237, outlierCount: 0 },
    { name: "segment", type: "String", quality: "3 categories", role: "feature", missingCount: 0, distinctCount: 3, outlierCount: 0 },
    { name: "category", type: "String", quality: "3 categories", role: "feature", missingCount: 0, distinctCount: 3, outlierCount: 0 },
    { name: "sales", type: "Float64", quality: "right-skewed; winsorize recommended", role: "feature", missingCount: 0, distinctCount: 5825, outlierCount: 181 },
    { name: "profit", type: "Float64", quality: "target candidate; negative values present", role: "label", missingCount: 0, distinctCount: 7287, outlierCount: 224 }
  ],
  manifestReady: true,
  manifestChecksums: localHealth.dataEstateManifestChecksums,
  duckdbStatus: "ready",
  importedAt: "2026-06-17T10:00:00Z",
  localOnly: true,
  activeReadMode: "duckdb",
  sourceOptions: [
    { mode: "csv", label: "CSV raw source", path: "data/raw/global_superstore.csv", status: "ready", semantics: "Raw local file read for ingest and reproducible source checks." },
    { mode: "arrow_ipc", label: "Arrow IPC artifact", path: "data/raw/global-superstore-local.arrow", status: "ready", semantics: "Fast local columnar boundary used between JuliaFlow nodes." },
    { mode: "parquet", label: "Parquet managed artifact", path: "data/processed/global-superstore-local.parquet", status: "ready", semantics: "Durable local analytics artifact for processed and feature zones." },
    { mode: "duckdb", label: "DuckDB query view", path: "data/_duckdb/local-data-estate.sql", status: "active", semantics: "Persistent local SQL view for profiling, joins, and aggregate reads." }
  ],
  lineageArtifacts: [
    { stage: "raw", artifactRef: "data/raw/global_superstore.csv", format: "csv", checksumSha256: "9".repeat(64), rowCount: 9800 },
    { stage: "profiled", artifactRef: "data/raw/global-superstore-local.arrow", format: "arrow_ipc", checksumSha256: "9".repeat(64), rowCount: 9800 },
    { stage: "processed", artifactRef: "data/processed/global-superstore-local.parquet", format: "parquet", checksumSha256: "9".repeat(64), rowCount: 9800 },
    { stage: "query", artifactRef: "data/_duckdb/local-data-estate.sql", format: "duckdb", checksumSha256: "9".repeat(64), rowCount: 9800 }
  ],
  qualityChecks: [
    { checkId: "dates-parse", label: "Order dates parse", status: "passed", detail: "Order and ship dates are typed for time-series EDA." },
    { checkId: "profit-outliers", label: "Profit outliers", status: "warning", detail: "224 high-leverage profit rows should be reviewed before regression." },
    { checkId: "lineage-ready", label: "Local artifact lineage", status: "passed", detail: "Raw, Arrow, Parquet, and DuckDB bindings are available locally." }
  ],
  workflowReadiness: {
    targetColumn: "profit",
    trainTestSplit: "time-aware 80/20",
    leakageWarnings: ["Avoid using ship_date-derived delivery duration before validating order-time availability."],
    downstreamReady: true,
    recommendedNextAction: "Open Visualize for sales/profit EDA or Transform to build aggregate features."
  },
  quickPlots: [
    { plotId: "sales-category", title: "Sales By Category", kind: "bar", field: "category", values: [{ label: "Furniture", value: 741999 }, { label: "Office Supplies", value: 719047 }, { label: "Technology", value: 836154 }] },
    { plotId: "profit-segment", title: "Profit By Segment", kind: "bar", field: "segment", values: [{ label: "Consumer", value: 134119 }, { label: "Corporate", value: 91979 }, { label: "Home Office", value: 60299 }] }
  ],
  previewRows: superstoreRows,
  charts: superstoreProfileCharts
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
    localOnly: true,
    charts: transformCharts,
    validation: {
      status: "valid",
      messages: ["Pipeline nodes resolved locally.", "Artifact outputs are attached to this run."],
      updatedAt: "2026-06-17T10:10:18Z"
    }
  }
];

export const executionRecords: GatewayExecutionRecord[] = [
  {
    executionId: "exec-local-churn-001",
    workflowId,
    workflowVersion: "1.0.0",
    checkpointTag: "cp/local-churn-2026-06-17",
    status: "completed",
    mode: "batch",
    plan: ["source", "profile", "features", "train", "dashboard"],
    stages: [["source"], ["profile"], ["features"], ["train", "dashboard"]],
    nodeCount: localWorkflow.nodes.length,
    connectionCount: localWorkflow.connections.length,
    createdAt: "2026-06-17T10:08:00Z",
    updatedAt: "2026-06-17T10:15:41Z",
    queuedAt: "2026-06-17T10:08:01Z",
    startedAt: "2026-06-17T10:08:04Z",
    finishedAt: "2026-06-17T10:15:41Z",
    statusHistory: [
      { status: "accepted", at: "2026-06-17T10:08:00Z", message: "Gateway accepted local churn workflow run." },
      { status: "running", at: "2026-06-17T10:08:04Z", message: "Worker started CPU-local execution." },
      { status: "completed", at: "2026-06-17T10:15:41Z", message: "Execution completed with local artifacts." }
    ],
    executorState: {
      status: "completed",
      currentStageIndex: 4,
      stageCount: 4,
      activeNodeIds: [],
      completedNodeIds: ["source", "profile", "features", "train", "dashboard"],
      completedStageIndexes: [0, 1, 2, 3],
      workerId: "local-cpu-worker",
      bounded: true,
      stageResults: [
        { stageIndex: 0, nodeIds: ["source"], status: "completed" },
        { stageIndex: 1, nodeIds: ["profile"], status: "completed" },
        { stageIndex: 2, nodeIds: ["features"], status: "completed" },
        { stageIndex: 3, nodeIds: ["train", "dashboard"], status: "completed" }
      ],
      nodeResults: [
        { nodeId: "source", nodeType: "source.local_csv", status: "executed", outputKind: "node", rowCount: 12500, outputRefs: ["data/raw/customer-churn-local.arrow"] },
        { nodeId: "features", nodeType: "transform.feature_engineer", status: "executed", outputKind: "node", rowCount: 12500, outputRefs: ["data/features/churn_features.parquet"] },
        { nodeId: "train", nodeType: "ml.xgboost", status: "executed", outputKind: "node", rowCount: 1, outputRefs: ["data/models/churn_model_v1.jls"] },
        { nodeId: "dashboard", nodeType: "bi.dashboard", status: "executed", outputKind: "bi_outlet", rowCount: 12500, outputRefs: ["data/dashboards/churn_v3.json"] }
      ]
    },
    explainabilityEvidence: localHealth.explainabilityEvidence,
    dispatchLane: "cpu",
    dispatchWorkerPool: "local-cpu",
    dispatchIsolationMode: "shared",
    dispatchSchedulerPolicy: "shared_cpu",
    dispatchPlacementReason: "Local appliance CPU fallback is deterministic for the demo fixture."
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
    validationEvidence: {
      projectId: "customer-churn-project",
      splitPlanId: "split-churn-stratified",
      splitStrategy: "stratified",
      finalTestPolicy: "forbid_final_test",
      validationFraction: 0.15,
      testFraction: 0.15
    },
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
