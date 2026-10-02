import { Component, useEffect, useMemo, useRef, useState } from "react";
import { GatewayClientError, createGatewayClient } from "@juliaflow/contracts";
import { Shell, pathForView, viewFromPath } from "./components/Shell";
import {
  checkpoints,
  dashboardId,
  dataProfile,
  dataScienceProject,
  deployPackages,
  executionRecords,
  localHealth,
  localWorkflow,
  mlExperiments,
  modelRegistry,
  publishedDashboard,
  projectFiles,
  superstoreDataProfile,
  transformRuns,
  visualizeExports,
  workflowSummary
} from "./fixtures/local-fixtures";
import type { ActionFeedback, AppData, AppView, LocalProjectArtifact } from "./types";
import type {
  DataScienceProject,
  GatewayDataImportProfile,
  GatewayDataImportProfileRequest,
  GatewayHealthcheck,
  GatewayRequestOptions,
  JuliaFlowRuntimeContract,
  JuliaFlowRuntimeMode,
  JuliaFlowUnavailableCapability,
  JuliaFlowUnavailableState,
  PublishedDashboardDefinition,
  UpdateDataScienceProjectRequest,
  UpdateGatewayComputeSettingsRequest,
  WorkflowDefinition,
  WorkspaceRole
} from "@juliaflow/contracts";
import { canEditDisplayedDataset, type DatasetEditIdentity } from "./dataset-edit-boundary";
import { DataView } from "./views/DataView";
import { DeployView } from "./views/DeployView";
import { ExplorerView } from "./views/ExplorerView";
import { MlStudioView } from "./views/MlStudioView";
import { ModelsView } from "./views/ModelsView";
import { MonitorView } from "./views/MonitorView";
import { SettingsView } from "./views/SettingsView";
import { TransformView } from "./views/TransformView";
import { VisualizeView } from "./views/VisualizeView";
import type { ReactNode } from "react";

interface JuliaFlowRuntimeConfig {
  gatewayBaseUrl?: string;
  runtimeMode?: JuliaFlowRuntimeMode;
  gatewayAuthToken?: string;
  oidcAccessToken?: string;
  workspaceId?: string;
  workspaceRole?: WorkspaceRole;
}

interface LocalFileSystemWritableFileStream {
  write(data: string): Promise<void>;
  close(): Promise<void>;
}

interface LocalFileSystemFileHandle {
  createWritable(): Promise<LocalFileSystemWritableFileStream>;
}

interface LocalFileSystemDirectoryHandle {
  name: string;
  getDirectoryHandle(name: string, options?: { create?: boolean }): Promise<LocalFileSystemDirectoryHandle>;
  getFileHandle(name: string, options?: { create?: boolean }): Promise<LocalFileSystemFileHandle>;
}

declare global {
  interface Window {
    __JULIAFLOW_CONFIG__?: JuliaFlowRuntimeConfig;
    showDirectoryPicker?: (options?: { mode?: "read" | "readwrite" }) => Promise<LocalFileSystemDirectoryHandle>;
  }
}

function getGatewayBaseUrl(): string {
  const runtimeUrl = typeof window === "undefined" ? "" : String(window.__JULIAFLOW_CONFIG__?.gatewayBaseUrl ?? "").trim();
  if (runtimeUrl.length > 0) return runtimeUrl;
  return String(import.meta.env.VITE_JULIAFLOW_GATEWAY_BASE_URL ?? "").trim();
}

function normalizeRuntimeMode(value: unknown): JuliaFlowRuntimeMode {
  const mode = String(value ?? "").trim();
  if (mode === "demo" || mode === "development" || mode === "release" || mode === "local-appliance") {
    return mode;
  }
  return "demo";
}

function getRuntimeMode(): JuliaFlowRuntimeMode {
  const runtimeMode = typeof window === "undefined" ? "" : window.__JULIAFLOW_CONFIG__?.runtimeMode;
  return normalizeRuntimeMode(runtimeMode ?? import.meta.env.VITE_JULIAFLOW_RUNTIME_MODE);
}

function getRuntimeConfigString(key: keyof JuliaFlowRuntimeConfig, envValue: unknown): string {
  const runtimeValue = typeof window === "undefined" ? "" : window.__JULIAFLOW_CONFIG__?.[key];
  const value = String(runtimeValue ?? envValue ?? "").trim();
  return value;
}

function normalizeWorkspaceRole(value: unknown): WorkspaceRole | undefined {
  const role = String(value ?? "").trim();
  if (role === "owner" || role === "editor" || role === "viewer") return role;
  return undefined;
}

function getGatewayAuthHeaders(): HeadersInit | undefined {
  const token =
    getRuntimeConfigString("gatewayAuthToken", import.meta.env.VITE_JULIAFLOW_GATEWAY_AUTH_TOKEN) ||
    getRuntimeConfigString("oidcAccessToken", import.meta.env.VITE_JULIAFLOW_OIDC_ACCESS_TOKEN);
  const workspaceId = getRuntimeConfigString("workspaceId", import.meta.env.VITE_JULIAFLOW_WORKSPACE_ID);
  const workspaceRole = normalizeWorkspaceRole(
    typeof window === "undefined"
      ? import.meta.env.VITE_JULIAFLOW_WORKSPACE_ROLE
      : window.__JULIAFLOW_CONFIG__?.workspaceRole ?? import.meta.env.VITE_JULIAFLOW_WORKSPACE_ROLE
  );
  const headers: Record<string, string> = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (workspaceId) headers["X-JuliaFlow-Workspace"] = workspaceId;
  if (workspaceRole) headers["X-JuliaFlow-Workspace-Role"] = workspaceRole;
  return Object.keys(headers).length > 0 ? headers : undefined;
}

function allowsFixtureSubstitution(mode: JuliaFlowRuntimeMode): boolean {
  return mode === "demo" || mode === "development";
}

function unavailableState(
  capability: JuliaFlowUnavailableCapability,
  reason: string,
  recovery = "Start the local gateway and reload this release workspace."
): JuliaFlowUnavailableState {
  return {
    capability,
    status: "unavailable",
    reason,
    recovery,
    fixtureSubstituted: false
  };
}

function runtimeContract(
  mode: JuliaFlowRuntimeMode,
  unavailable: JuliaFlowUnavailableState[] = []
): JuliaFlowRuntimeContract {
  return {
    mode,
    fixtureProvenance: allowsFixtureSubstitution(mode) ? "fixture" : "unavailable",
    fixtureSubstitutionAllowed: allowsFixtureSubstitution(mode),
    unavailable
  };
}

function getInitialView(): AppView {
  if (typeof window === "undefined") return "explorer";
  return viewFromPath(window.location.pathname || "/");
}

function withRuntimeHealth(
  health: GatewayHealthcheck,
  runtime: JuliaFlowRuntimeContract
): GatewayHealthcheck {
  return {
    ...health,
    runtime,
    runtimeMode: runtime.mode,
    fixtureProvenance: runtime.fixtureProvenance,
    fixtureSubstitutionAllowed: runtime.fixtureSubstitutionAllowed,
    unavailable: runtime.unavailable
  };
}

function buildDemoData(runtimeMode: JuliaFlowRuntimeMode = "demo"): AppData {
  const runtime = runtimeContract(runtimeMode);
  return {
    mode: "demo",
    runtimeMode,
    runtime,
    unavailable: [],
    health: withRuntimeHealth(localHealth, runtime),
    healthLastUpdatedAt: undefined,
    healthStale: false,
    workflow: localWorkflow,
    workflowSummary,
    dataProfile,
    dataProfiles: [dataProfile, superstoreDataProfile],
    dataScienceProject,
    transformRuns,
    executions: executionRecords,
    mlExperiments,
    modelRegistry,
    deployPackages,
    visualizeExports,
    checkpoints,
    dashboard: publishedDashboard,
    projectFiles
  };
}

function workflowUnavailableDefinition(summary: typeof workflowSummary = workflowSummary): WorkflowDefinition {
  return {
    version: summary.version,
    workflowId: summary.workflowId,
    name: summary.name,
    nodes: [],
    connections: [],
    flowVariables: [],
    graph: {
      revision: summary.graphRevision ?? 0,
      nodeLayouts: []
    },
    dashboards: [],
    runtime: {
      runMode: summary.runMode ?? "batch"
    }
  };
}

function buildUnavailableData(
  runtimeMode: JuliaFlowRuntimeMode,
  unavailable: JuliaFlowUnavailableState[],
  summary: typeof workflowSummary = workflowSummary
): AppData {
  const runtime = runtimeContract(runtimeMode, unavailable);
  const base = buildDemoData(runtimeMode);
  const workflow = allowsFixtureSubstitution(runtimeMode) ? base.workflow : workflowUnavailableDefinition(summary);
  return {
    ...base,
    mode: "unavailable",
    runtime,
    unavailable,
    health: withRuntimeHealth(localHealth, runtime),
    healthLastUpdatedAt: undefined,
    healthStale: true,
    workflow,
    workflowSummary: summary,
    executions: [],
    transformRuns: [],
    mlExperiments: [],
    modelRegistry: [],
    deployPackages: [],
    visualizeExports: [],
    dashboard: dashboardFromWorkflow(workflow, summary)
  };
}

type WorkflowMetadataResult =
  | { ok: true; workflow: WorkflowDefinition }
  | { ok: false; reason: string; recovery: string };

function workflowMetadataToDefinition(metadata: unknown, workflowId: string): WorkflowMetadataResult {
  if (
    metadata &&
    typeof metadata === "object" &&
    "workflowId" in metadata &&
    (metadata as { workflowId?: unknown }).workflowId === workflowId &&
    "nodes" in metadata &&
    Array.isArray((metadata as { nodes?: unknown[] }).nodes) &&
    (metadata as { nodes?: unknown[] }).nodes!.length > 0 &&
    "connections" in metadata &&
    Array.isArray((metadata as { connections?: unknown[] }).connections) &&
    "flowVariables" in metadata &&
    Array.isArray((metadata as { flowVariables?: unknown[] }).flowVariables) &&
    "graph" in metadata &&
    typeof (metadata as { graph?: unknown }).graph === "object" &&
    Array.isArray((metadata as { graph?: { nodeLayouts?: unknown[] } }).graph?.nodeLayouts) &&
    "runtime" in metadata &&
    typeof (metadata as { runtime?: unknown }).runtime === "object"
  ) {
    return { ok: true, workflow: metadata as WorkflowDefinition };
  }
  return {
    ok: false,
    reason: `The gateway returned incomplete workflow metadata for ${workflowId}.`,
    recovery: "Re-import or save the workflow so the gateway returns nodes, connections, flow variables, graph layout, and runtime metadata before rendering the live canvas."
  };
}

function workflowDashboardId(workflow: WorkflowDefinition): string | undefined {
  return workflow.dashboards?.[0]?.dashboardId;
}

function dashboardFromWorkflow(
  workflow: WorkflowDefinition,
  summary: typeof workflowSummary
): PublishedDashboardDefinition {
  const source = workflow.dashboards?.[0];
  return {
    dashboardId: source?.dashboardId ?? `${summary.workflowId}-dashboard`,
    workflowId: summary.workflowId,
    name: source?.name ?? `${summary.name} Dashboard`,
    version: 0,
    publishedAt: "",
    visibility: "workspace",
    binding: source?.binding ?? publishedDashboard.binding,
    charts: source?.charts ?? [],
    datasets: {}
  };
}

function activeWorkflowId(data: AppData): string {
  return data.workflowSummary.workflowId;
}

function activeDashboardId(data: AppData): string {
  return data.dashboard.dashboardId || workflowDashboardId(data.workflow) || dashboardId;
}

type UtilityDialog = "grid" | "share" | "help" | "profile" | null;

class RouteErrorBoundary extends Component<
  { activeView: AppView; children: ReactNode },
  { error: Error | null }
> {
  state = { error: null };

  static getDerivedStateFromError(error: Error) {
    return { error };
  }

  componentDidUpdate(previousProps: { activeView: AppView }) {
    if (previousProps.activeView !== this.props.activeView && this.state.error) {
      this.setState({ error: null });
    }
  }

  render() {
    if (this.state.error) {
      return (
        <section className="route-error" role="alert">
          <h1>{this.props.activeView.replace("-", " ")} unavailable</h1>
          <p>This module could not render the current live workspace payload. Use another module, retry after the local gateway refreshes, or check Settings for runtime status.</p>
        </section>
      );
    }
    return this.props.children;
  }
}

interface ProjectFormState {
  name: string;
  description: string;
  folderPath: string;
}

interface ProjectScaffoldFile {
  path: string[];
  content: string;
}

const moduleLaunchItems: Array<{ id: AppView; label: string; summary: string }> = [
  { id: "explorer", label: "Explorer", summary: "Project overview, local artifacts, and run controls" },
  { id: "data", label: "Data", summary: "Import, profile, and local data estate evidence" },
  { id: "transform", label: "Transform", summary: "Feature and transformation pipeline work" },
  { id: "ml-studio", label: "ML Studio", summary: "Training, metrics, and model evidence" },
  { id: "visualize", label: "Visualize", summary: "Dashboards, checkpoints, and visual evidence" },
  { id: "settings", label: "Settings", summary: "Runtime, auth, and local appliance settings" }
];

const invalidProjectNamePattern = /[<>:"/\\|?*]/;

function projectRoot(health: GatewayHealthcheck): string {
  const localHome = String(health.localHome ?? "").trim();
  return localHome ? `${localHome.replace(/[\\/]$/, "")}/Projects` : "~/JuliaFlowLocal/Projects";
}

function slugifyProjectName(name: string): string {
  const slug = name
    .trim()
    .replace(/[^A-Za-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
  return slug || "Local_Project";
}

function projectPathFor(root: string, name: string): string {
  const separator = root.includes("\\") && !root.includes("/") ? "\\" : "/";
  return `${root.replace(/[\\/]+$/, "")}${separator}${slugifyProjectName(name)}`;
}

function isLocalPath(path: string): boolean {
  return /^(~[\\/]|[A-Za-z]:[\\/]|\\\\|\/)/.test(path);
}

function normalizeProjectPath(path: string): string {
  return path.trim().replace(/[\\/]+$/, "");
}

function validateProjectForm(form: ProjectFormState, data: AppData): string | null {
  const name = form.name.trim();
  const folderPath = normalizeProjectPath(form.folderPath);
  if (name.length < 3) return "Project name must be at least 3 characters.";
  if (invalidProjectNamePattern.test(name)) return "Project name cannot include path or reserved filename characters.";
  if (!form.description.trim()) return "Project description is required.";
  if (!folderPath) return "Folder path is required.";
  if (!isLocalPath(folderPath)) return "Folder path must be an absolute local path or a home-relative path.";
  if (/\.\.(?:[\\/]|$)/.test(folderPath)) return "Folder path cannot contain parent-directory traversal.";
  const normalizedTarget = folderPath.replace(/\\/g, "/").toLowerCase();
  const existingRoots = new Set((data.projectFiles ?? []).map((file) => String(file.path).split(/[\\/]/)[0].toLowerCase()));
  const targetParts = normalizedTarget.split("/");
  const targetFolderName = targetParts[targetParts.length - 1] ?? "";
  if (existingRoots.has(slugifyProjectName(name).toLowerCase()) || existingRoots.has(targetFolderName)) {
    return "A project with this folder name already exists in the local project browser.";
  }
  return null;
}

function scaffoldProjectFiles(form: ProjectFormState, workflowId: string): LocalProjectArtifact[] {
  const root = slugifyProjectName(form.name);
  return [
    { path: `${root}/Project.toml`, size: "scaffold", status: "created" },
    { path: `${root}/README.md`, size: "description", status: "created" },
    { path: `${root}/workflows/${workflowId}.toml`, size: "template", status: "created" },
    { path: `${root}/data/raw/.gitkeep`, size: "0 B", status: "ready" }
  ];
}

function scaffoldProjectFileContents(form: ProjectFormState, workflowId: string): ProjectScaffoldFile[] {
  const projectName = form.name.trim();
  const projectDescription = form.description.trim();
  return [
    {
      path: ["Project.toml"],
      content: `name = "${slugifyProjectName(projectName)}"\nversion = "0.1.0"\ndescription = "${projectDescription.replace(/"/g, "\\\"")}"\n`
    },
    {
      path: ["README.md"],
      content: `# ${projectName}\n\n${projectDescription}\n\nGenerated by JuliaFlow Local.\n`
    },
    {
      path: ["workflows", `${workflowId}.toml`],
      content: `workflow_id = "${workflowId}"\nname = "${projectName.replace(/"/g, "\\\"")}"\nversion = "0.1.0"\n\n[nodes]\n`
    },
    {
      path: ["data", "raw", ".gitkeep"],
      content: ""
    }
  ];
}

async function writeProjectScaffold(
  directoryHandle: LocalFileSystemDirectoryHandle,
  files: ProjectScaffoldFile[]
): Promise<void> {
  for (const file of files) {
    let currentDirectory = directoryHandle;
    const directories = file.path.slice(0, -1);
    const fileName = file.path[file.path.length - 1];
    for (const directory of directories) {
      currentDirectory = await currentDirectory.getDirectoryHandle(directory, { create: true });
    }
    const fileHandle = await currentDirectory.getFileHandle(fileName, { create: true });
    const writable = await fileHandle.createWritable();
    await writable.write(file.content);
    await writable.close();
  }
}

function prependUnique<TItem>(
  items: TItem[],
  nextItem: TItem,
  getKey: (item: TItem) => string
): TItem[] {
  const nextKey = getKey(nextItem);
  return [nextItem, ...items.filter((item) => getKey(item) !== nextKey)];
}

function upsertDataProfile(
  profiles: GatewayDataImportProfile[] | undefined,
  profile: GatewayDataImportProfile
): GatewayDataImportProfile[] {
  return [profile, ...(profiles ?? []).filter((item) => item.datasetId !== profile.datasetId)];
}

function isAbsoluteLocalPath(value: string): boolean {
  return /^[a-zA-Z]:[\\/]/.test(value) || value.startsWith("/") || value.startsWith("\\\\");
}

function gatewayImportSourceUri(
  profile: GatewayDataImportProfile,
  fixtureSubstitutionAllowed: boolean,
  request?: GatewayDataImportProfileRequest
): string {
  const sourceUri = String(request?.sourceUri ?? profile.sourceUri).trim();
  if (fixtureSubstitutionAllowed || sourceUri.toLowerCase().startsWith("local://") || isAbsoluteLocalPath(sourceUri)) {
    return sourceUri;
  }
  const datasetId = String(request?.datasetId ?? profile.datasetId);
  const sourceFormat = String(request?.format ?? profile.sourceFormat ?? "csv");
  const targetZone = String(request?.targetZone ?? profile.targetZone ?? "raw");
  return `local://data/${targetZone}/${datasetId}.${sourceFormat}`;
}

function isGatewayAuthError(error: unknown): boolean {
  return error instanceof GatewayClientError && (error.status === 401 || error.status === 403);
}

function isDataScienceProject(value: unknown): value is DataScienceProject {
  return Boolean(
    value &&
    typeof value === "object" &&
    "projectId" in value &&
    Array.isArray((value as DataScienceProject).datasets) &&
    Array.isArray((value as DataScienceProject).schemaContracts) &&
    Array.isArray((value as DataScienceProject).projectJobs)
  );
}

const dialogFocusableSelector = [
  "button:not([disabled])",
  "[href]",
  "input:not([disabled])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  "[tabindex]:not([tabindex='-1'])"
].join(",");

function manageDialogFocus(dialog: HTMLElement | null, close: () => void) {
  if (!dialog) return;
  const focusable = () => Array.from(dialog.querySelectorAll<HTMLElement>(dialogFocusableSelector))
    .filter((element) => !element.hidden && element.getAttribute("aria-hidden") !== "true");
  (focusable()[0] ?? dialog).focus();
  const onKeyDown = (event: KeyboardEvent) => {
    if (event.key === "Escape") {
      event.preventDefault();
      close();
      return;
    }
    if (event.key !== "Tab") return;
    const elements = focusable();
    if (elements.length === 0) {
      event.preventDefault();
      dialog.focus();
      return;
    }
    const first = elements[0];
    const last = elements[elements.length - 1];
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  };
  dialog.addEventListener("keydown", onKeyDown);
  return () => dialog.removeEventListener("keydown", onKeyDown);
}

function authUnavailableState(error: unknown): JuliaFlowUnavailableState {
  const reason = error instanceof GatewayClientError ? error.message : "Gateway authentication failed.";
  return unavailableState(
    "auth",
    reason,
    "Configure gatewayAuthToken or oidcAccessToken in juliaflow-config.js, then retry."
  );
}

function App() {
  const gatewayBaseUrl = useMemo(() => getGatewayBaseUrl(), []);
  const runtimeMode = useMemo(() => getRuntimeMode(), []);
  const gatewayAuthHeaders = useMemo(() => getGatewayAuthHeaders(), []);
  const fixtureSubstitutionAllowed = allowsFixtureSubstitution(runtimeMode);
  const [activeView, setActiveView] = useState<AppView>(() => getInitialView());
  const [projectDialogOpen, setProjectDialogOpen] = useState(false);
  const [utilityDialog, setUtilityDialog] = useState<UtilityDialog>(null);
  const projectDialogRef = useRef<HTMLElement | null>(null);
  const utilityDialogRef = useRef<HTMLElement | null>(null);
  const projectDialogTriggerRef = useRef<HTMLElement | null>(null);
  const utilityDialogTriggerRef = useRef<HTMLElement | null>(null);
  const [data, setData] = useState<AppData>(() =>
    fixtureSubstitutionAllowed
      ? buildDemoData(runtimeMode)
      : buildUnavailableData(runtimeMode, [
          unavailableState("workflows", "Release mode is waiting for backend workflow metadata before rendering live workspace data.")
        ])
  );
  const currentDataRef = useRef(data);
  currentDataRef.current = data;
  const [projectForm, setProjectForm] = useState<ProjectFormState>(() => ({
    name: workflowSummary.name,
    description: "Creates a local workspace scaffold using the current appliance profile and sample workflow template.",
    folderPath: projectPathFor(projectRoot(localHealth), workflowSummary.name)
  }));
  const [projectDirectoryHandle, setProjectDirectoryHandle] = useState<LocalFileSystemDirectoryHandle | null>(null);
  const [projectDirectoryLabel, setProjectDirectoryLabel] = useState("");
  const [projectFormError, setProjectFormError] = useState("");
  const [feedback, setFeedback] = useState<Partial<Record<AppView, ActionFeedback>>>({});

  useEffect(() => {
    const onPopState = () => setActiveView(getInitialView());
    window.addEventListener("popstate", onPopState);
    return () => window.removeEventListener("popstate", onPopState);
  }, []);

  useEffect(() => {
    if (!projectDialogOpen) {
      projectDialogTriggerRef.current?.focus();
      return;
    }
    return manageDialogFocus(projectDialogRef.current, () => setProjectDialogOpen(false));
  }, [projectDialogOpen]);

  useEffect(() => {
    if (!utilityDialog) {
      utilityDialogTriggerRef.current?.focus();
      return;
    }
    return manageDialogFocus(utilityDialogRef.current, () => setUtilityDialog(null));
  }, [utilityDialog]);

  useEffect(() => {
    if (!gatewayBaseUrl) {
      if (!fixtureSubstitutionAllowed) {
        setData(buildUnavailableData(runtimeMode, [
          unavailableState("workflows", "No gatewayBaseUrl is configured for release/local-appliance runtime mode.")
        ]));
      }
      return;
    }
    const abort = new AbortController();
    const client = createGatewayClient({ baseUrl: gatewayBaseUrl, headers: gatewayAuthHeaders });
    const requestOptions = (signal: AbortSignal): GatewayRequestOptions => ({ signal });

    async function loadGatewayState() {
      try {
        const requiredFailure = (label: string, error: unknown) =>
          new Error(`${label}: ${error instanceof Error ? error.message : "backend data required in release mode"}`);
        const fallbackList = <TItem,>(items: TItem[], label: string, error: unknown) =>
          fixtureSubstitutionAllowed ? { items, count: items.length } : Promise.reject(requiredFailure(label, error));
        const fallbackValue = <TValue,>(value: TValue, label: string, error: unknown) =>
          fixtureSubstitutionAllowed ? value : Promise.reject(requiredFailure(label, error));
        const [health, workflows, executions] = await Promise.all([
          client.healthcheck(requestOptions(abort.signal)),
          client.listWorkflows(requestOptions(abort.signal)),
          client.listExecutions(requestOptions(abort.signal)).catch((error) => fallbackList(executionRecords, "execution history", error))
        ]);
        if (!fixtureSubstitutionAllowed && workflows.items.length === 0) {
          setData(buildUnavailableData(runtimeMode, [
            unavailableState("workflows", "The release gateway returned no workflows.", "Create or import a workflow through the gateway, then reload.")
          ]));
          return;
        }
        const summary = workflows.items[0] ?? workflowSummary;
        const metadata = await client.getWorkflow(summary.workflowId, requestOptions(abort.signal)).catch((error) => fallbackValue(localWorkflow, "workflow metadata", error));
        const workflowResult = workflowMetadataToDefinition(metadata, summary.workflowId);
        if (!workflowResult.ok && !fixtureSubstitutionAllowed) {
          setData(buildUnavailableData(runtimeMode, [
            unavailableState("workflows", workflowResult.reason, workflowResult.recovery)
          ], summary));
          return;
        }
        const workflow = workflowResult.ok ? workflowResult.workflow : localWorkflow;
        const [transforms, experiments, models, packages, dashboards, projects] = await Promise.all([
          client.getWorkflowTransformHistory(summary.workflowId, requestOptions(abort.signal)).catch((error) => fallbackList(transformRuns, "transform history", error)),
          client.getWorkflowMlExperimentHistory(summary.workflowId, requestOptions(abort.signal)).catch((error) => fallbackList(mlExperiments, "experiment history", error)),
          client.listWorkflowModels(summary.workflowId, requestOptions(abort.signal)).catch((error) => fallbackList(modelRegistry, "model registry", error)),
          client.listWorkflowDeployPackages(summary.workflowId, requestOptions(abort.signal)).catch((error) => fallbackList(deployPackages, "deploy package history", error)),
          client.listPublishedDashboards(summary.workflowId, requestOptions(abort.signal)).catch(() =>
            fixtureSubstitutionAllowed
              ? { items: [publishedDashboard] }
              : { items: [] }
          ),
          client.listDataScienceProjects(requestOptions(abort.signal)).catch((error) => fallbackList([dataScienceProject], "data science projects", error))
        ]);
        const dashboard =
          dashboards.items[0] ??
          dashboardFromWorkflow(workflow, summary);
        if (!fixtureSubstitutionAllowed && projects.items.length === 0) {
          setData(buildUnavailableData(runtimeMode, [
            unavailableState("workflowMetadata", "The local gateway returned no data science project aggregate.", "Create or import a data science project through the gateway, then reload.")
          ], summary));
          return;
        }
        const liveRuntime = health.runtime ?? runtimeContract(runtimeMode);
        setData({
          mode: "live",
          runtimeMode: liveRuntime.mode,
          runtime: liveRuntime,
          unavailable: liveRuntime.unavailable,
          health: withRuntimeHealth(health, liveRuntime),
          healthLastUpdatedAt: new Date().toISOString(),
          healthStale: false,
          workflow,
          workflowSummary: summary,
          dataProfile,
          dataProfiles: [dataProfile, superstoreDataProfile],
          dataScienceProject: projects.items[0] ?? dataScienceProject,
          executions: executions.items.length > 0 || !fixtureSubstitutionAllowed ? executions.items : executionRecords,
          transformRuns: transforms.items.length > 0 || !fixtureSubstitutionAllowed ? transforms.items : transformRuns,
          mlExperiments: experiments.items.length > 0 || !fixtureSubstitutionAllowed ? experiments.items : mlExperiments,
          modelRegistry: models.items.length > 0 || !fixtureSubstitutionAllowed ? models.items : modelRegistry,
          deployPackages: packages.items.length > 0 || !fixtureSubstitutionAllowed ? packages.items : deployPackages,
          visualizeExports,
          checkpoints,
          dashboard,
          projectFiles: health.workspaceSummary?.artifacts?.length
            ? health.workspaceSummary.artifacts
            : fixtureSubstitutionAllowed ? projectFiles : []
        });
      } catch (error) {
        if (!abort.signal.aborted) {
          const gatewayReason = error instanceof Error ? error.message : "unknown gateway error";
          setData(
            isGatewayAuthError(error)
              ? buildUnavailableData(runtimeMode, [authUnavailableState(error)])
              : fixtureSubstitutionAllowed
              ? { ...buildDemoData(runtimeMode), mode: "fallback" }
              : buildUnavailableData(runtimeMode, [
                  unavailableState("workflows", `The release gateway could not provide required live workspace data: ${gatewayReason}`)
                ])
          );
        }
      }
    }

    void loadGatewayState();
    const interval = window.setInterval(async () => {
      try {
        const health = await client.healthcheck(requestOptions(abort.signal));
        const liveRuntime = health.runtime ?? runtimeContract(runtimeMode);
        setData((current) => ({
          ...current,
          mode: current.mode === "unavailable" ? current.mode : "live",
          runtimeMode: liveRuntime.mode,
          runtime: liveRuntime,
          unavailable: current.mode === "unavailable" ? current.unavailable : liveRuntime.unavailable,
          health: withRuntimeHealth(health, liveRuntime),
          healthLastUpdatedAt: new Date().toISOString(),
          healthStale: false
        }));
      } catch (error) {
        if (!abort.signal.aborted) {
          setData((current) => ({ ...current, healthStale: true }));
        }
      }
    }, 5000);
    return () => {
      abort.abort();
      window.clearInterval(interval);
    };
  }, [fixtureSubstitutionAllowed, gatewayAuthHeaders, gatewayBaseUrl, runtimeMode]);

  function navigate(view: AppView) {
    setActiveView(view);
    const nextPath = pathForView(view);
    if (window.location.pathname !== nextPath) {
      window.history.pushState({}, "", nextPath);
    }
  }

  function setViewFeedback(view: AppView, label: string, tone: ActionFeedback["tone"] = "success") {
    setFeedback((current) => ({ ...current, [view]: { label, tone } }));
  }

  function openProjectDialog() {
    projectDialogTriggerRef.current = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    setProjectForm({
      name: data.workflowSummary.name,
      description: "Creates a local workspace scaffold using the current appliance profile and sample workflow template.",
      folderPath: projectPathFor(projectRoot(data.health), data.workflowSummary.name)
    });
    setProjectDirectoryHandle(null);
    setProjectDirectoryLabel("");
    setProjectFormError("");
    setProjectDialogOpen(true);
  }

  function openUtilityDialog(dialog: Exclude<UtilityDialog, null>) {
    utilityDialogTriggerRef.current = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    setUtilityDialog(dialog);
  }

  async function chooseProjectFolder() {
    if (!window.showDirectoryPicker) {
      setProjectFormError("Native folder picking is not available in this browser. Type a local path or use Chromium/Edge to grant write access.");
      return;
    }
    try {
      const directoryHandle = await window.showDirectoryPicker({ mode: "readwrite" });
      setProjectDirectoryHandle(directoryHandle);
      setProjectDirectoryLabel(directoryHandle.name);
      setProjectFormError("");
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") return;
      setProjectFormError("JuliaFlow could not access the selected folder. Choose a writable local folder and retry.");
    }
  }

  async function createLocalProject() {
    const validationError = validateProjectForm(projectForm, data);
    if (validationError) {
      setProjectFormError(validationError);
      return;
    }
    const name = projectForm.name.trim();
    const projectSlug = slugifyProjectName(name);
    const workflowId = `wf-${projectSlug.toLowerCase().replace(/_/g, "-")}`;
    const targetPath = normalizeProjectPath(projectForm.folderPath);
    const createdFiles = scaffoldProjectFiles(projectForm, workflowId);
    try {
      if (projectDirectoryHandle) {
        await writeProjectScaffold(projectDirectoryHandle, scaffoldProjectFileContents(projectForm, workflowId));
      }
    } catch (error) {
      setProjectFormError("JuliaFlow could not write the scaffold files. Confirm folder write permission and retry.");
      return;
    }
    setData((current) => ({
      ...current,
      workflow: {
        ...current.workflow,
        workflowId,
        name
      },
      workflowSummary: {
        ...current.workflowSummary,
        workflowId,
        name,
        version: "0.1.0"
      },
      projectFiles: [...createdFiles, ...(current.projectFiles ?? [])]
    }));
    setProjectDialogOpen(false);
    navigate("explorer");
    setProjectDirectoryHandle(null);
    setProjectDirectoryLabel("");
    setViewFeedback(
      "explorer",
      projectDirectoryHandle
        ? `Local project scaffold written to ${projectDirectoryLabel || targetPath}.`
        : `Local project scaffold created at ${targetPath}.`,
      "success"
    );
  }

  function setUtilityFeedback(label: string, tone: ActionFeedback["tone"] = "success") {
    setUtilityDialog(null);
    setViewFeedback(activeView, label, tone);
  }

  async function copyArtifactPath(path: string) {
    try {
      if (navigator.clipboard) {
        await navigator.clipboard.writeText(path);
      }
      setViewFeedback("explorer", `Artifact path copied: ${path}`, "success");
    } catch {
      setViewFeedback("explorer", `Artifact path ready to copy: ${path}`, "info");
    }
  }

  function applyComputeSettingsToHealth(settings: typeof data.health.computeSettings) {
    setData((current) => ({
      ...current,
      health: {
        ...current.health,
        computeSettings: settings,
        hardwareSelectedBackend: settings.selectedBackend,
        cpuWorkerConcurrency: settings.cpuWorkerConcurrency,
        cpuMemoryLimitBytes: settings.cpuMemoryLimitBytes,
        cpuSchedulerPolicy: settings.schedulerPolicy,
        gpuReadinessStatus: settings.selectedBackend === "cpu" ? "cpu_fallback" : current.health.gpuReadinessStatus,
        gpuCudaStatus: settings.selectedBackend === "cuda" ? current.health.gpuCudaStatus : "not_requested"
      },
      healthLastUpdatedAt: new Date().toISOString(),
      healthStale: false
    }));
  }

  async function saveComputeSettings(request: UpdateGatewayComputeSettingsRequest) {
    if (!client) {
      applyComputeSettingsToHealth({
        ...data.health.computeSettings,
        ...request,
        selectedBackend: request.selectedBackend ?? data.health.computeSettings.selectedBackend,
        cpuWorkerConcurrency: request.cpuWorkerConcurrency ?? data.health.computeSettings.cpuWorkerConcurrency,
        cpuMemoryLimitBytes: request.cpuMemoryLimitBytes ?? data.health.computeSettings.cpuMemoryLimitBytes,
        gpuPreference: request.gpuPreference ?? data.health.computeSettings.gpuPreference,
        blasThreadCount: request.blasThreadCount ?? data.health.computeSettings.blasThreadCount,
        source: "request",
        updatedAt: new Date().toISOString()
      });
      setViewFeedback("settings", "Compute settings staged locally for this demo workspace.", "info");
      return;
    }
    try {
      const settings = await client.updateComputeSettings(request);
      applyComputeSettingsToHealth(settings);
      setViewFeedback("settings", "Compute settings saved to the local gateway profile.");
    } catch (error) {
      setViewFeedback(
        "settings",
        isGatewayAuthError(error)
          ? "Gateway authentication failed. Configure the local gateway token and retry."
          : "Compute settings could not be saved by the local gateway.",
        "error"
      );
    }
  }

  async function withGatewayFallback<T>(
    view: AppView,
    action: () => Promise<T>,
    onSuccess: (result: T) => void,
    fallbackLabel: string
  ) {
    if (!gatewayBaseUrl) {
      setViewFeedback(
        view,
        fixtureSubstitutionAllowed ? fallbackLabel : "Release mode requires the local gateway before this action can run.",
        fixtureSubstitutionAllowed ? "success" : "error"
      );
      return;
    }
    try {
      const result = await action();
      onSuccess(result);
      setViewFeedback(view, "Gateway action completed locally.");
    } catch (error) {
      setViewFeedback(
        view,
        isGatewayAuthError(error)
          ? "Gateway authentication failed. Configure the local gateway token in Settings and retry."
          : fixtureSubstitutionAllowed ? fallbackLabel : "Release mode did not substitute fixture results for this failed gateway action.",
        isGatewayAuthError(error) ? "error" : fixtureSubstitutionAllowed ? "info" : "error"
      );
    }
  }

  function applyDataScienceProjectUpdate(project: DataScienceProject) {
    setData((current) => ({
      ...current,
      dataScienceProject: project,
      mode: current.mode === "unavailable" ? current.mode : current.mode
    }));
  }

  async function refreshDataScienceProject(projectId: string) {
    if (!client) return;
    try {
      const project = await client.getDataScienceProject(projectId);
      if (isDataScienceProject(project)) {
        applyDataScienceProjectUpdate(project);
      }
    } catch (error) {
      setViewFeedback(
        activeView,
        isGatewayAuthError(error)
          ? "Gateway authentication failed while refreshing project evidence."
          : "Project evidence refresh could not be completed by the local gateway.",
        "error"
      );
    }
  }

  async function updateDataScienceProject(request: UpdateDataScienceProjectRequest, identity: DatasetEditIdentity) {
    if (!canEditDisplayedDataset(currentDataRef.current, identity)) {
      setViewFeedback("data", "The displayed dataset no longer matches the active project. Select or import a matching dataset before saving.", "error");
      return;
    }
    const projectId = data.dataScienceProject.projectId;
    const localProject: DataScienceProject = {
      ...data.dataScienceProject,
      ...request,
      projectId,
      schemaVersion: "1.0",
      localOnly: true,
      updatedAt: new Date().toISOString(),
      datasets: request.datasets ?? data.dataScienceProject.datasets,
      schemaContracts: request.schemaContracts ?? data.dataScienceProject.schemaContracts,
      splitPlans: request.splitPlans ?? data.dataScienceProject.splitPlans,
      splitAssignments: request.splitAssignments ?? data.dataScienceProject.splitAssignments,
      validationFolds: request.validationFolds ?? data.dataScienceProject.validationFolds,
      finalTestLocks: request.finalTestLocks ?? data.dataScienceProject.finalTestLocks,
      projectJobs: request.projectJobs ?? data.dataScienceProject.projectJobs,
      transformFitApplyRecords: request.transformFitApplyRecords ?? data.dataScienceProject.transformFitApplyRecords,
      statisticalAnalysisRuns: request.statisticalAnalysisRuns ?? data.dataScienceProject.statisticalAnalysisRuns,
      trainingPlans: request.trainingPlans ?? data.dataScienceProject.trainingPlans,
      tuningStudies: request.tuningStudies ?? data.dataScienceProject.tuningStudies,
      evaluationReports: request.evaluationReports ?? data.dataScienceProject.evaluationReports,
      predictionExports: request.predictionExports ?? data.dataScienceProject.predictionExports,
      modelRegistryRecords: request.modelRegistryRecords ?? data.dataScienceProject.modelRegistryRecords,
      modelLifecycleRecords: request.modelLifecycleRecords ?? data.dataScienceProject.modelLifecycleRecords,
      monitoringBaselines: request.monitoringBaselines ?? data.dataScienceProject.monitoringBaselines,
      driftReports: request.driftReports ?? data.dataScienceProject.driftReports,
      reproducibilityEvidence: request.reproducibilityEvidence ?? data.dataScienceProject.reproducibilityEvidence
    };
    if (!gatewayBaseUrl) {
      if (fixtureSubstitutionAllowed) {
        applyDataScienceProjectUpdate(localProject);
        setViewFeedback("data", "Project schema and validation choices updated in demo workspace.", "success");
      } else {
        setViewFeedback("data", "Release mode requires the local gateway before project schema changes can be saved.", "error");
      }
      return;
    }
    try {
      const project = await client!.updateDataScienceProject(projectId, request);
      applyDataScienceProjectUpdate(project);
      setViewFeedback("data", "Project schema and validation choices saved to the local gateway.");
    } catch (error) {
      if (fixtureSubstitutionAllowed && !isGatewayAuthError(error)) {
        applyDataScienceProjectUpdate(localProject);
        setViewFeedback("data", "Gateway project update failed; deterministic demo project state was updated locally.", "info");
        return;
      }
      setViewFeedback(
        "data",
        isGatewayAuthError(error)
          ? "Gateway authentication failed. Configure the local gateway token and retry."
          : "Project schema and validation choices could not be saved by the local gateway.",
        "error"
      );
    }
  }

  const client = gatewayBaseUrl ? createGatewayClient({ baseUrl: gatewayBaseUrl, headers: gatewayAuthHeaders }) : null;

  const view = (() => {
    switch (activeView) {
      case "data":
        return (
          <DataView
            data={data}
            feedback={feedback.data}
            onSelectProfile={(profile) =>
              setData((current) => ({
                ...current,
                dataProfile: profile,
                dataProfiles: upsertDataProfile(current.dataProfiles, profile)
              }))
            }
            onProjectUpdate={updateDataScienceProject}
            onImport={(request?: GatewayDataImportProfileRequest) => {
              const baseRequest = request ?? {
                datasetId: data.dataProfile.datasetId,
                sourceUri: data.dataProfile.sourceUri,
                format: data.dataProfile.activeReadMode ?? data.dataProfile.sourceFormat,
                targetZone: data.dataProfile.targetZone,
                readMode: data.dataProfile.activeReadMode ?? data.dataProfile.sourceFormat
              };
              const nextRequest: GatewayDataImportProfileRequest = {
                projectId: data.dataScienceProject.projectId,
                ...baseRequest,
                sourceUri: gatewayImportSourceUri(data.dataProfile, fixtureSubstitutionAllowed, baseRequest)
              };
              if (!gatewayBaseUrl && fixtureSubstitutionAllowed && nextRequest.readMode) {
                setData((current) => {
                  const nextProfile: GatewayDataImportProfile = {
                    ...current.dataProfile,
                    activeReadMode: nextRequest.readMode,
                    sourceFormat: String(nextRequest.format ?? current.dataProfile.sourceFormat),
                    sourceOptions: current.dataProfile.sourceOptions?.map((option) => ({
                      ...option,
                      status: option.mode === nextRequest.readMode ? "active" : option.status === "active" ? "ready" : option.status
                    }))
                  };
                  return {
                    ...current,
                    dataProfile: nextProfile,
                    dataProfiles: upsertDataProfile(current.dataProfiles, nextProfile)
                  };
                });
              }
              return withGatewayFallback(
                "data",
                () => client!.importDataProfile(nextRequest),
                (response) => setData((current) => ({
                  ...current,
                  dataProfile: response.profile,
                  dataProfiles: upsertDataProfile(current.dataProfiles, response.profile),
                  dataScienceProject: response.project ?? current.dataScienceProject,
                  mode: "live"
                })),
                `Synthetic ${nextRequest.readMode ?? data.dataProfile.activeReadMode ?? "csv"} profile loaded from fixture.`
              );
            }}
          />
        );
      case "transform":
        return (
          <TransformView
            data={data}
            feedback={feedback["transform"]}
            onRun={() =>
              withGatewayFallback(
                "transform",
                () => client!.runWorkflowTransform(activeWorkflowId(data), {}),
                (response) => setData((current) => ({
                  ...current,
                  transformRuns: prependUnique(current.transformRuns, response.run, (item) => item.runId),
                  mode: "live"
                })),
                "Synthetic transform history displayed."
              )
            }
          />
        );
      case "ml-studio":
        return (
          <MlStudioView
            data={data}
            feedback={feedback["ml-studio"]}
            onRun={() =>
              withGatewayFallback(
                "ml-studio",
                () => client!.runWorkflowMlExperiment(activeWorkflowId(data), {
                  projectId: data.dataScienceProject.projectId,
                  datasetId: data.dataProfile.datasetId,
                  splitPlanId: data.dataScienceProject.splitPlans.find((plan) => plan.datasetId === data.dataProfile.datasetId)?.splitPlanId,
                  finalTestPolicy: "forbid_final_test",
                  target: data.dataProfile.workflowReadiness?.targetColumn ?? "churn",
                  algorithm: "MLJ.XGBoostClassifier"
                }),
                (response) => {
                  setData((current) => ({
                    ...current,
                    mlExperiments: prependUnique(current.mlExperiments, response.experiment, (item) => item.experimentId),
                    mode: "live"
                  }));
                  if (response.experiment.validationEvidence?.projectId) {
                    void refreshDataScienceProject(response.experiment.validationEvidence.projectId);
                  }
                },
                "Synthetic ML experiment metrics displayed."
              )
            }
          />
        );
      case "models":
        return (
          <ModelsView
            data={data}
            feedback={feedback.models}
            onRegister={() =>
              withGatewayFallback(
                "models",
                () => client!.registerWorkflowModel(activeWorkflowId(data), { modelId: "Churn Prediction", owner: "julia_user", tags: ["churn", "local"] }),
                (response) => {
                  setData((current) => ({
                    ...current,
                    modelRegistry: prependUnique(current.modelRegistry, response.model, (item) => item.registryId),
                    mode: "live"
                  }));
                  void refreshDataScienceProject(data.dataScienceProject.projectId);
                },
                "Synthetic model registry detail displayed."
              )
            }
          />
        );
      case "visualize":
        return (
          <VisualizeView
            data={data}
            feedback={feedback.visualize}
            onExport={() =>
              withGatewayFallback(
                "visualize",
                () => client!.exportVisualizeCheckpoint(activeWorkflowId(data), activeDashboardId(data), { checkpointTag: "cp/dashboard-v3", visibility: "workspace" }),
                (response) => setData((current) => ({
                  ...current,
                  visualizeExports: prependUnique(current.visualizeExports, response.export, (item) => item.exportId),
                  dashboard: response.dashboard,
                  mode: "live"
                })),
                "Synthetic dashboard checkpoint export displayed."
              )
            }
          />
        );
      case "deploy":
        return (
          <DeployView
            data={data}
            feedback={feedback.deploy}
            onPackage={() =>
              withGatewayFallback(
                "deploy",
                () => client!.packageWorkflowDeploy(activeWorkflowId(data), { modelId: "Churn Prediction", endpointPath: "/predict/churn", host: "127.0.0.1", port: 8099 }),
                (response) => {
                  setData((current) => ({
                    ...current,
                    deployPackages: prependUnique(current.deployPackages, response.package, (item) => item.packageId),
                    mode: "live"
                  }));
                  void refreshDataScienceProject(data.dataScienceProject.projectId);
                },
                "Synthetic local deploy package displayed."
              )
            }
          />
        );
      case "monitor":
        return <MonitorView data={data} />;
      case "settings":
        return <SettingsView data={data} feedback={feedback.settings} onSaveComputeSettings={saveComputeSettings} />;
      case "explorer":
      default:
        return (
          <ExplorerView
            data={data}
            feedback={feedback.explorer}
            onSave={() =>
              withGatewayFallback(
                "explorer",
                () => client!.updateWorkflow(data.workflowSummary.workflowId, { workflow: data.workflow }),
                (response) => setData((current) => ({
                  ...current,
                  workflowSummary: {
                    ...current.workflowSummary,
                    workflowId: response.workflowId,
                    name: response.name,
                    version: response.version
                  },
                  mode: "live"
                })),
                "Workflow save stayed in deterministic demo mode."
              )
            }
            onRun={() =>
              withGatewayFallback(
                "explorer",
                () => client!.executeWorkflow(data.workflowSummary.workflowId),
                (execution) => setData((current) => ({
                  ...current,
                  executions: prependUnique(current.executions, execution, (item) => item.executionId),
                  mode: "live"
                })),
                "Workflow run stayed in deterministic demo mode."
              )
            }
            onCopyArtifactPath={copyArtifactPath}
            onOpenSettings={() => navigate("settings")}
          />
        );
    }
  })();

  return (
    <Shell
      activeView={activeView}
      onNavigate={navigate}
      onPrimaryAction={openProjectDialog}
      onGridAction={() => openUtilityDialog("grid")}
      onShareAction={() => openUtilityDialog("share")}
      onHelpAction={() => openUtilityDialog("help")}
      onProfileAction={() => openUtilityDialog("profile")}
    >
      {data.mode === "fallback" ? (
        <p className="feedback info">Gateway unavailable. Running deterministic local demo fallback.</p>
      ) : null}
      {data.mode === "unavailable" ? (
        <section className="feedback error" aria-label="Release mode unavailable">
          <strong>Release mode requires backend-provided workspace data.</strong>
          {data.unavailable.map((item) => (
            <span key={item.capability}>{item.capability}: {item.reason} {item.recovery}</span>
          ))}
        </section>
      ) : null}
      {projectDialogOpen ? (
        <div className="modal-backdrop" role="presentation">
          <section ref={projectDialogRef} className="project-dialog" role="dialog" aria-modal="true" aria-labelledby="new-project-title">
            <div className="project-dialog-head">
              <div>
                <p className="jf-eyebrow">Local project</p>
                <h2 id="new-project-title">Create New Project</h2>
              </div>
              <button type="button" className="icon-button" aria-label="Close new project dialog" onClick={() => setProjectDialogOpen(false)}>
                x
              </button>
            </div>
            <div className="project-template">
              <strong>{data.workflowSummary.name}</strong>
              <span>{data.workflowSummary.workflowId}</span>
              <p>Creates a local workspace scaffold using the current appliance profile and sample workflow template.</p>
            </div>
            <div className="form-grid">
              <label>
                <span>Project name</span>
                <input
                  value={projectForm.name}
                  onChange={(event) => setProjectForm((current) => ({
                    ...current,
                    name: event.target.value,
                    folderPath: projectPathFor(projectRoot(data.health), event.target.value)
                  }))}
                />
              </label>
              <label>
                <span>Description</span>
                <textarea
                  value={projectForm.description}
                  rows={3}
                  onChange={(event) => setProjectForm((current) => ({ ...current, description: event.target.value }))}
                />
              </label>
              <label>
                <span>Folder path</span>
                <input
                  value={projectForm.folderPath}
                  onChange={(event) => {
                    setProjectDirectoryHandle(null);
                    setProjectDirectoryLabel("");
                    setProjectForm((current) => ({ ...current, folderPath: event.target.value }));
                  }}
                />
              </label>
            </div>
            <div className="folder-access-row">
              <button type="button" className="jf-button secondary" onClick={chooseProjectFolder}>Choose Target Folder</button>
              <span>
                {projectDirectoryLabel
                  ? `Write access granted: ${projectDirectoryLabel}`
                  : window.showDirectoryPicker
                  ? "Optional: grant write access to create files in the selected folder."
                  : "Native folder write access is unavailable in this browser; the typed path will be staged in the workspace."}
              </span>
            </div>
            {projectFormError ? <p className="feedback error">{projectFormError}</p> : null}
            <div className="key-values">
              <span>Workspace</span><strong>{data.health.localHome ?? "Configured local home"}</strong>
              <span>Profile</span><strong>{data.health.localProfile ?? data.runtimeMode}</strong>
              <span>Metadata</span><strong>{data.health.metadataBackend ?? "file"}</strong>
              <span>Workflow</span><strong>{data.workflowSummary.version}</strong>
            </div>
            <div className="dialog-actions">
              <button type="button" className="jf-button secondary" onClick={() => setProjectDialogOpen(false)}>Cancel</button>
              <button type="button" className="jf-button primary" onClick={createLocalProject}>Create Local Project</button>
            </div>
          </section>
        </div>
      ) : null}
      {utilityDialog ? (
        <div className="modal-backdrop" role="presentation">
          <section ref={utilityDialogRef} className="project-dialog utility-dialog" role="dialog" aria-modal="true" aria-labelledby="utility-dialog-title">
            <div className="project-dialog-head">
              <div>
                <p className="jf-eyebrow">Local workspace</p>
                <h2 id="utility-dialog-title">
                  {utilityDialog === "grid" ? "Module Launcher" : utilityDialog === "share" ? "Local Export And Share" : utilityDialog === "help" ? "Workspace Help" : "Local Profile"}
                </h2>
              </div>
              <button type="button" className="icon-button" aria-label="Close utility dialog" onClick={() => setUtilityDialog(null)}>
                x
              </button>
            </div>
            {utilityDialog === "grid" ? (
              <div className="module-grid">
                {moduleLaunchItems.map((item) => (
                  <button
                    type="button"
                    key={item.id}
                    className={activeView === item.id ? "module-tile active" : "module-tile"}
                    onClick={() => {
                      setUtilityDialog(null);
                      navigate(item.id);
                    }}
                  >
                    <strong>{item.label}</strong>
                    <span>{item.summary}</span>
                  </button>
                ))}
              </div>
            ) : null}
            {utilityDialog === "share" ? (
              <div className="utility-stack">
                <div className="key-values">
                  <span>Project bundle</span><strong>{slugifyProjectName(data.workflowSummary.name)}.juliaflow-bundle.json</strong>
                  <span>Local path</span><strong>{projectRoot(data.health)}</strong>
                  <span>Mode</span><strong>{data.runtimeMode}</strong>
                </div>
                <div className="dialog-actions">
                  <button type="button" className="jf-button secondary" onClick={() => setUtilityFeedback("Local project path is ready to copy from the share panel.", "info")}>Copy Path</button>
                  <button type="button" className="jf-button primary" onClick={() => setUtilityFeedback("Local reproducibility bundle export queued for this workspace.")}>Prepare Bundle</button>
                </div>
              </div>
            ) : null}
            {utilityDialog === "help" ? (
              <div className="utility-stack">
                <p className="empty-state">This local workspace runs without cloud sync. Use Explorer to save or run the workflow, Data to inspect local datasets, ML Studio for training, and Visualize for checkpointed dashboard evidence.</p>
                <div className="dialog-actions">
                  <button type="button" className="jf-button secondary" onClick={() => { setUtilityDialog(null); navigate("settings"); }}>Open Settings</button>
                  <button type="button" className="jf-button primary" onClick={() => setUtilityDialog(null)}>Done</button>
                </div>
              </div>
            ) : null}
            {utilityDialog === "profile" ? (
              <div className="utility-stack">
                <div className="key-values">
                  <span>Initials</span><strong>AJ</strong>
                  <span>Profile</span><strong>{data.health.localProfile ?? "single-user"}</strong>
                  <span>Auth</span><strong>{data.health.authMode ?? "disabled"}</strong>
                  <span>Home</span><strong>{data.health.localHome}</strong>
                </div>
                <div className="dialog-actions">
                  <button type="button" className="jf-button secondary" onClick={() => { setUtilityDialog(null); navigate("settings"); }}>Profile Settings</button>
                  <button type="button" className="jf-button primary" onClick={() => setUtilityDialog(null)}>Done</button>
                </div>
              </div>
            ) : null}
          </section>
        </div>
      ) : null}
      <RouteErrorBoundary activeView={activeView}>
        {view}
      </RouteErrorBoundary>
    </Shell>
  );
}

export default App;
