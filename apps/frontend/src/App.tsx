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

function getInitialView(): AppView {
  if (typeof window === "undefined") return "explorer";
  return viewFromPath(window.location.pathname || "/");
}

function buildDemoData(): AppData {
  return {
    mode: "demo",
    health: localHealth,
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
  const [activeView, setActiveView] = useState<AppView>(() => getInitialView());
  const [data, setData] = useState<AppData>(() => buildDemoData());
  const [feedback, setFeedback] = useState<Partial<Record<AppView, ActionFeedback>>>({});

  useEffect(() => {
    const onPopState = () => setActiveView(getInitialView());
    window.addEventListener("popstate", onPopState);
    return () => window.removeEventListener("popstate", onPopState);
  }, []);

  useEffect(() => {
    if (!gatewayBaseUrl) return;
    const abort = new AbortController();
    const client = createGatewayClient({ baseUrl: gatewayBaseUrl });

    async function loadGatewayState() {
      try {
        const [health, workflows, transforms, experiments, models, packages, dashboard] = await Promise.all([
          client.healthcheck({ signal: abort.signal }),
          client.listWorkflows({ signal: abort.signal }),
          client.getWorkflowTransformHistory(workflowId, { signal: abort.signal }).catch(() => ({ items: transformRuns, count: transformRuns.length })),
          client.getWorkflowMlExperimentHistory(workflowId, { signal: abort.signal }).catch(() => ({ items: mlExperiments, count: mlExperiments.length })),
          client.listWorkflowModels(workflowId, { signal: abort.signal }).catch(() => ({ items: modelRegistry, count: modelRegistry.length })),
          client.listWorkflowDeployPackages(workflowId, { signal: abort.signal }).catch(() => ({ items: deployPackages, count: deployPackages.length })),
          client.getPublishedDashboard(dashboardId, undefined, { signal: abort.signal }).catch(() => publishedDashboard)
        ]);
        const summary = workflows.items[0] ?? workflowSummary;
        const metadata = await client.getWorkflow(summary.workflowId, { signal: abort.signal }).catch(() => localWorkflow);
        setData({
          mode: "live",
          health,
          workflow: workflowMetadataToDefinition(metadata),
          workflowSummary: summary,
          dataProfile,
          transformRuns: transforms.items.length > 0 ? transforms.items : transformRuns,
          mlExperiments: experiments.items.length > 0 ? experiments.items : mlExperiments,
          modelRegistry: models.items.length > 0 ? models.items : modelRegistry,
          deployPackages: packages.items.length > 0 ? packages.items : deployPackages,
          visualizeExports,
          checkpoints,
          dashboard
        });
      } catch {
        if (!abort.signal.aborted) {
          setData({ ...buildDemoData(), mode: "fallback" });
        }
      }
    }

    void loadGatewayState();
    return () => abort.abort();
  }, [gatewayBaseUrl]);

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
      setViewFeedback(view, fallbackLabel);
      return;
    }
    try {
      const result = await action();
      onSuccess(result);
      setViewFeedback(view, "Gateway action completed locally.");
    } catch {
      setViewFeedback(view, fallbackLabel, "info");
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
      {view}
    </Shell>
  );
}

export default App;
