import type {
  GatewayCheckpointRecord,
  GatewayDataImportProfile,
  GatewayDeployPackageRecord,
  GatewayExecutionRecord,
  GatewayHealthcheck,
  GatewayMlExperimentRecord,
  GatewayModelRegistryRecord,
  GatewayTransformRunRecord,
  GatewayVisualizeCheckpointExportRecord,
  GatewayWorkflowSummary,
  JuliaFlowRuntimeContract,
  JuliaFlowRuntimeMode,
  JuliaFlowUnavailableState,
  PublishedDashboardDefinition,
  WorkflowDefinition
} from "@juliaflow/contracts";

export type AppView =
  | "explorer"
  | "data"
  | "transform"
  | "ml-studio"
  | "models"
  | "visualize"
  | "deploy"
  | "monitor"
  | "settings";

export type DataMode = "demo" | "live" | "fallback" | "unavailable";

export interface AppData {
  mode: DataMode;
  runtimeMode: JuliaFlowRuntimeMode;
  runtime: JuliaFlowRuntimeContract;
  unavailable: JuliaFlowUnavailableState[];
  health: GatewayHealthcheck;
  workflow: WorkflowDefinition;
  workflowSummary: GatewayWorkflowSummary;
  dataProfile: GatewayDataImportProfile;
  transformRuns: GatewayTransformRunRecord[];
  executions: GatewayExecutionRecord[];
  mlExperiments: GatewayMlExperimentRecord[];
  modelRegistry: GatewayModelRegistryRecord[];
  deployPackages: GatewayDeployPackageRecord[];
  visualizeExports: GatewayVisualizeCheckpointExportRecord[];
  checkpoints: GatewayCheckpointRecord[];
  dashboard: PublishedDashboardDefinition;
  projectFiles: LocalProjectArtifact[];
}

export interface ActionFeedback {
  label: string;
  tone: "info" | "success" | "error";
}

export interface LocalProjectArtifact {
  path: string;
  size: string;
  status: string;
}
