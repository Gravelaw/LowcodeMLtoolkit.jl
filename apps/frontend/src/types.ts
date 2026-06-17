import type {
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

export type AppView =
  | "explorer"
  | "data"
  | "transform"
  | "ml-studio"
  | "models"
  | "visualize"
  | "deploy"
  | "settings";

export type DataMode = "demo" | "live" | "fallback";

export interface AppData {
  mode: DataMode;
  health: GatewayHealthcheck;
  workflow: WorkflowDefinition;
  workflowSummary: GatewayWorkflowSummary;
  dataProfile: GatewayDataImportProfile;
  transformRuns: GatewayTransformRunRecord[];
  mlExperiments: GatewayMlExperimentRecord[];
  modelRegistry: GatewayModelRegistryRecord[];
  deployPackages: GatewayDeployPackageRecord[];
  visualizeExports: GatewayVisualizeCheckpointExportRecord[];
  checkpoints: GatewayCheckpointRecord[];
  dashboard: PublishedDashboardDefinition;
}

export interface ActionFeedback {
  label: string;
  tone: "info" | "success" | "error";
}
