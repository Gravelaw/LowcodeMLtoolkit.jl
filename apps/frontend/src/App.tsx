import { useEffect, useMemo, useState } from "react";
import { createGatewayClient } from "@juliaflow/contracts";
import { Shell, pathForView, viewFromPath } from "./components/Shell";
import {
  checkpoints,
  dashboardId,
  dataProfile,
  deployPackages,
  localHealth,
  localWorkflow,
  mlExperiments,
  modelRegistry,
  publishedDashboard,
  transformRuns,
  visualizeExports,
  workflowId,
  workflowSummary
} from "./fixtures/local-fixtures";
import type { ActionFeedback, AppData, AppView } from "./types";
import type {
  GatewayHealthcheck,
  JuliaFlowRuntimeContract,
  JuliaFlowRuntimeMode,
  JuliaFlowUnavailableCapability,
  JuliaFlowUnavailableState
} from "@juliaflow/contracts";
import { DataView } from "./views/DataView";
import { DeployView } from "./views/DeployView";
import { ExplorerView } from "./views/ExplorerView";
import { MlStudioView } from "./views/MlStudioView";
import { ModelsView } from "./views/ModelsView";
import { SettingsView } from "./views/SettingsView";
import { TransformView } from "./views/TransformView";
import { VisualizeView } from "./views/VisualizeView";

interface JuliaFlowRuntimeConfig {
  gatewayBaseUrl?: string;
  runtimeMode?: JuliaFlowRuntimeMode;
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
    mlExperiments,
    modelRegistry,
    deployPackages,
    visualizeExports,
    checkpoints,
    dashboard: publishedDashboard
  };
}

function buildUnavailableData(
  runtimeMode: JuliaFlowRuntimeMode,
  unavailable: JuliaFlowUnavailableState[]
): AppData {
  const runtime = runtimeContract(runtimeMode, unavailable);
  return {
    ...buildDemoData(runtimeMode),
    mode: "unavailable",
    runtime,
    unavailable,
    health: withRuntimeHealth(localHealth, runtime)
  };
}

function workflowMetadataToDefinition(metadata: unknown): typeof localWorkflow {
  if (
    metadata &&
    typeof metadata === "object" &&
    "workflowId" in metadata &&
    "nodes" in metadata &&
    Array.isArray((metadata as { nodes?: unknown[] }).nodes)
  ) {
    return metadata as typeof localWorkflow;
  }
  return localWorkflow;
}

function prependUnique<TItem>(
  items: TItem[],
  nextItem: TItem,
  getKey: (item: TItem) => string
): TItem[] {
  const nextKey = getKey(nextItem);
  return [nextItem, ...items.filter((item) => getKey(item) !== nextKey)];
}

function App() {
  const gatewayBaseUrl = useMemo(() => getGatewayBaseUrl(), []);
  const runtimeMode = useMemo(() => getRuntimeMode(), []);
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
    const client = createGatewayClient({ baseUrl: gatewayBaseUrl });

    async function loadGatewayState() {
      try {
        const fallbackList = <TItem,>(items: TItem[]) =>
          fixtureSubstitutionAllowed ? { items, count: items.length } : Promise.reject(new Error("backend data required in release mode"));
        const fallbackValue = <TValue,>(value: TValue) =>
          fixtureSubstitutionAllowed ? value : Promise.reject(new Error("backend data required in release mode"));
        const [health, workflows, transforms, experiments, models, packages, dashboard] = await Promise.all([
          client.healthcheck({ signal: abort.signal }),
          client.listWorkflows({ signal: abort.signal }),
          client.getWorkflowTransformHistory(workflowId, { signal: abort.signal }).catch(() => fallbackList(transformRuns)),
          client.getWorkflowMlExperimentHistory(workflowId, { signal: abort.signal }).catch(() => fallbackList(mlExperiments)),
          client.listWorkflowModels(workflowId, { signal: abort.signal }).catch(() => fallbackList(modelRegistry)),
          client.listWorkflowDeployPackages(workflowId, { signal: abort.signal }).catch(() => fallbackList(deployPackages)),
          client.getPublishedDashboard(dashboardId, undefined, { signal: abort.signal }).catch(() => fallbackValue(publishedDashboard))
        ]);
        if (!fixtureSubstitutionAllowed && workflows.items.length === 0) {
          setData(buildUnavailableData(runtimeMode, [
            unavailableState("workflows", "The release gateway returned no workflows.", "Create or import a workflow through the gateway, then reload.")
          ]));
          return;
        }
        const summary = workflows.items[0] ?? workflowSummary;
        const metadata = await client.getWorkflow(summary.workflowId, { signal: abort.signal }).catch(() => fallbackValue(localWorkflow));
        const liveRuntime = health.runtime ?? runtimeContract(runtimeMode);
        setData({
          mode: "live",
          runtimeMode: liveRuntime.mode,
          runtime: liveRuntime,
          unavailable: liveRuntime.unavailable,
          health: withRuntimeHealth(health, liveRuntime),
          workflow: workflowMetadataToDefinition(metadata),
          workflowSummary: summary,
          dataProfile,
          transformRuns: transforms.items.length > 0 || !fixtureSubstitutionAllowed ? transforms.items : transformRuns,
          mlExperiments: experiments.items.length > 0 || !fixtureSubstitutionAllowed ? experiments.items : mlExperiments,
          modelRegistry: models.items.length > 0 || !fixtureSubstitutionAllowed ? models.items : modelRegistry,
          deployPackages: packages.items.length > 0 || !fixtureSubstitutionAllowed ? packages.items : deployPackages,
          visualizeExports,
          checkpoints,
          dashboard
        });
      } catch {
        if (!abort.signal.aborted) {
          setData(
            fixtureSubstitutionAllowed
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
  }, [fixtureSubstitutionAllowed, gatewayBaseUrl, runtimeMode]);

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
    } catch {
      setViewFeedback(
        view,
        fixtureSubstitutionAllowed ? fallbackLabel : "Release mode did not substitute fixture results for this failed gateway action.",
        fixtureSubstitutionAllowed ? "info" : "error"
      );
    }
  }

  const client = gatewayBaseUrl ? createGatewayClient({ baseUrl: gatewayBaseUrl }) : null;

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
                () => client!.runWorkflowTransform(workflowId, {}),
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
                () => client!.runWorkflowMlExperiment(workflowId, { datasetId: "customer-churn-local", target: "churn", algorithm: "MLJ.XGBoostClassifier" }),
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
                () => client!.registerWorkflowModel(workflowId, { modelId: "Churn Prediction", owner: "julia_user", tags: ["churn", "local"] }),
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
                () => client!.exportVisualizeCheckpoint(workflowId, dashboardId, { checkpointTag: "cp/dashboard-v3", visibility: "workspace" }),
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
                () => client!.packageWorkflowDeploy(workflowId, { modelId: "Churn Prediction", endpointPath: "/predict/churn", host: "127.0.0.1", port: 8099 }),
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
      case "settings":
        return <SettingsView data={data} />;
      case "explorer":
      default:
        return <ExplorerView data={data} />;
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
