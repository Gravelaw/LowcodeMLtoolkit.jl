import type {
  GatewayCheckpointRecord,
  GatewayDataImportProfile,
  DataScienceProject,
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
  healthLastUpdatedAt?: string;
  healthStale: boolean;
  workflow: WorkflowDefinition;
  workflowSummary: GatewayWorkflowSummary;
  dataProfile: GatewayDataImportProfile;
  dataProfiles: GatewayDataImportProfile[];
  dataScienceProject: DataScienceProject;
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
  kind?: string;
  size: string;
  status: string;
  localOnly?: boolean;
}
