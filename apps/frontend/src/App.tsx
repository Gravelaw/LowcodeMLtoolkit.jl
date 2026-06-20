import { useEffect, useMemo, useState } from "react";
import { GatewayClientError, createGatewayClient } from "@juliaflow/contracts";
import { Shell, pathForView, viewFromPath } from "./components/Shell";
import {
  checkpoints,
  dashboardId,
  dataProfile,
  deployPackages,
  executionRecords,
  localHealth,
  localWorkflow,
  mlExperiments,
  modelRegistry,
  publishedDashboard,
  transformRuns,
  visualizeExports,
  workflowSummary
} from "./fixtures/local-fixtures";
import type { ActionFeedback, AppData, AppView } from "./types";
import type {
  GatewayHealthcheck,
  GatewayRequestOptions,
  JuliaFlowRuntimeContract,
  JuliaFlowRuntimeMode,
  JuliaFlowUnavailableCapability,
  JuliaFlowUnavailableState,
  PublishedDashboardDefinition,
  WorkflowDefinition,
  WorkspaceRole
} from "@juliaflow/contracts";
import { DataView } from "./views/DataView";
import { DeployView } from "./views/DeployView";
import { ExplorerView } from "./views/ExplorerView";
import { MlStudioView } from "./views/MlStudioView";
import { ModelsView } from "./views/ModelsView";
import { MonitorView } from "./views/MonitorView";
import { SettingsView } from "./views/SettingsView";
import { TransformView } from "./views/TransformView";
import { VisualizeView } from "./views/VisualizeView";

interface JuliaFlowRuntimeConfig {
  gatewayBaseUrl?: string;
  runtimeMode?: JuliaFlowRuntimeMode;
  gatewayAuthToken?: string;
  oidcAccessToken?: string;
  workspaceId?: string;
  workspaceRole?: WorkspaceRole;
}

declare global {
  interface Window {
    __JULIAFLOW_CONFIG__?: JuliaFlowRuntimeConfig;
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
    workflow: localWorkflow,
    workflowSummary,
    dataProfile,
    transformRuns,
    executions: executionRecords,
    mlExperiments,
    modelRegistry,
    deployPackages,
    visualizeExports,
    checkpoints,
    dashboard: publishedDashboard
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

function prependUnique<TItem>(
  items: TItem[],
  nextItem: TItem,
  getKey: (item: TItem) => string
): TItem[] {
  const nextKey = getKey(nextItem);
  return [nextItem, ...items.filter((item) => getKey(item) !== nextKey)];
}

function isGatewayAuthError(error: unknown): boolean {
  return error instanceof GatewayClientError && (error.status === 401 || error.status === 403);
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
  const [data, setData] = useState<AppData>(() =>
    fixtureSubstitutionAllowed
      ? buildDemoData(runtimeMode)
      : buildUnavailableData(runtimeMode, [
          unavailableState("workflows", "Release mode is waiting for backend workflow metadata before rendering live workspace data.")
        ])
  );
  const [feedback, setFeedback] = useState<Partial<Record<AppView, ActionFeedback>>>({});

  useEffect(() => {
    const onPopState = () => setActiveView(getInitialView());
    window.addEventListener("popstate", onPopState);
    return () => window.removeEventListener("popstate", onPopState);
  }, []);

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
        const fallbackList = <TItem,>(items: TItem[]) =>
          fixtureSubstitutionAllowed ? { items, count: items.length } : Promise.reject(new Error("backend data required in release mode"));
        const fallbackValue = <TValue,>(value: TValue) =>
          fixtureSubstitutionAllowed ? value : Promise.reject(new Error("backend data required in release mode"));
        const [health, workflows, executions] = await Promise.all([
          client.healthcheck(requestOptions(abort.signal)),
          client.listWorkflows(requestOptions(abort.signal)),
          client.listExecutions(requestOptions(abort.signal)).catch(() => fallbackList(executionRecords))
        ]);
        if (!fixtureSubstitutionAllowed && workflows.items.length === 0) {
          setData(buildUnavailableData(runtimeMode, [
            unavailableState("workflows", "The release gateway returned no workflows.", "Create or import a workflow through the gateway, then reload.")
          ]));
          return;
        }
        const summary = workflows.items[0] ?? workflowSummary;
        const metadata = await client.getWorkflow(summary.workflowId, requestOptions(abort.signal)).catch(() => fallbackValue(localWorkflow));
        const workflowResult = workflowMetadataToDefinition(metadata, summary.workflowId);
        if (!workflowResult.ok && !fixtureSubstitutionAllowed) {
          setData(buildUnavailableData(runtimeMode, [
            unavailableState("workflows", workflowResult.reason, workflowResult.recovery)
          ], summary));
          return;
        }
        const workflow = workflowResult.ok ? workflowResult.workflow : localWorkflow;
        const [transforms, experiments, models, packages, dashboards] = await Promise.all([
          client.getWorkflowTransformHistory(summary.workflowId, requestOptions(abort.signal)).catch(() => fallbackList(transformRuns)),
          client.getWorkflowMlExperimentHistory(summary.workflowId, requestOptions(abort.signal)).catch(() => fallbackList(mlExperiments)),
          client.listWorkflowModels(summary.workflowId, requestOptions(abort.signal)).catch(() => fallbackList(modelRegistry)),
          client.listWorkflowDeployPackages(summary.workflowId, requestOptions(abort.signal)).catch(() => fallbackList(deployPackages)),
          client.listPublishedDashboards(summary.workflowId, requestOptions(abort.signal)).catch(() =>
            fixtureSubstitutionAllowed
              ? { items: [publishedDashboard] }
              : { items: [] }
          )
        ]);
        const dashboard =
          dashboards.items[0] ??
          (fixtureSubstitutionAllowed
            ? await client.getPublishedDashboard(dashboardId, undefined, requestOptions(abort.signal)).catch(() => fallbackValue(publishedDashboard))
            : dashboardFromWorkflow(workflow, summary));
        const liveRuntime = health.runtime ?? runtimeContract(runtimeMode);
        setData({
          mode: "live",
          runtimeMode: liveRuntime.mode,
          runtime: liveRuntime,
          unavailable: liveRuntime.unavailable,
          health: withRuntimeHealth(health, liveRuntime),
          workflow,
          workflowSummary: summary,
          dataProfile,
          executions: executions.items.length > 0 || !fixtureSubstitutionAllowed ? executions.items : executionRecords,
          transformRuns: transforms.items.length > 0 || !fixtureSubstitutionAllowed ? transforms.items : transformRuns,
          mlExperiments: experiments.items.length > 0 || !fixtureSubstitutionAllowed ? experiments.items : mlExperiments,
          modelRegistry: models.items.length > 0 || !fixtureSubstitutionAllowed ? models.items : modelRegistry,
          deployPackages: packages.items.length > 0 || !fixtureSubstitutionAllowed ? packages.items : deployPackages,
          visualizeExports,
          checkpoints,
          dashboard
        });
      } catch (error) {
        if (!abort.signal.aborted) {
          setData(
            isGatewayAuthError(error)
              ? buildUnavailableData(runtimeMode, [authUnavailableState(error)])
              : fixtureSubstitutionAllowed
              ? { ...buildDemoData(runtimeMode), mode: "fallback" }
              : buildUnavailableData(runtimeMode, [
                  unavailableState("workflows", "The release gateway could not provide required live workspace data.")
                ])
          );
        }
      }
    }

    void loadGatewayState();
    return () => abort.abort();
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

  const client = gatewayBaseUrl ? createGatewayClient({ baseUrl: gatewayBaseUrl, headers: gatewayAuthHeaders }) : null;

  const view = (() => {
    switch (activeView) {
      case "data":
        return (
          <DataView
            data={data}
            feedback={feedback.data}
            onImport={() =>
              withGatewayFallback(
                "data",
                () => client!.importDataProfile({ datasetId: "customer-churn-local", sourceUri: "data/raw/churn.csv", format: "csv", targetZone: "raw" }),
                (response) => setData((current) => ({ ...current, dataProfile: response.profile, mode: "live" })),
                "Synthetic local profile loaded from fixture."
              )
            }
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
                () => client!.runWorkflowMlExperiment(activeWorkflowId(data), { datasetId: "customer-churn-local", target: "churn", algorithm: "MLJ.XGBoostClassifier" }),
                (response) => setData((current) => ({
                  ...current,
                  mlExperiments: prependUnique(current.mlExperiments, response.experiment, (item) => item.experimentId),
                  mode: "live"
                })),
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
                (response) => setData((current) => ({
                  ...current,
                  modelRegistry: prependUnique(current.modelRegistry, response.model, (item) => item.registryId),
                  mode: "live"
                })),
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
                (response) => setData((current) => ({
                  ...current,
                  deployPackages: prependUnique(current.deployPackages, response.package, (item) => item.packageId),
                  mode: "live"
                })),
                "Synthetic local deploy package displayed."
              )
            }
          />
        );
      case "monitor":
        return <MonitorView data={data} />;
      case "settings":
        return <SettingsView data={data} />;
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
          />
        );
    }
  })();

  return (
    <Shell activeView={activeView} onNavigate={navigate} onPrimaryAction={() => setViewFeedback(activeView, "Local project template opened.", "info")}>
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
      {view}
    </Shell>
  );
}

export default App;
