import { act, cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import * as matchers from "@testing-library/jest-dom/matchers";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import App from "./App";
import { canRenderChart, chartReadiness, chartStatusLabel } from "./components/chart-utils";
import {
  buildCanvasNodeLayouts,
  buildCheckpointRailItems,
  buildExecutionRailItems,
  buildWorkflowFromGateway,
  formatPortSummary,
  portTypeCounts
} from "./sample-workflow";
import {
  dataScienceProject,
  deployPackages,
  executionRecords,
  localHealth,
  localWorkflow,
  mlExperiments,
  modelRegistry,
  publishedDashboard,
  superstoreDataProfile,
  transformRuns,
  workflowSummary
} from "./fixtures/local-fixtures";

expect.extend(matchers);

const backendWorkflow = {
  ...localWorkflow,
  graph: {
    revision: workflowSummary.graphRevision,
    nodeLayouts: localWorkflow.nodes.map((node, index) => ({
      nodeId: node.id,
      x: 36 + index * 192,
      y: 44,
      width: 176
    }))
  }
};

describe("sample workflow helpers", () => {
  it("preserves Published dashboard bindings supplied with backend workflow metadata", () => {
    const metadata = { ...backendWorkflow, dashboards: [publishedDashboard] };
    const workflow = buildWorkflowFromGateway(workflowSummary, metadata);
    expect(workflow.dashboards).toHaveLength(1);
    expect(workflow.dashboards?.[0].dashboardId).toBe(publishedDashboard.dashboardId);
    expect(workflow.dashboards?.[0].binding).toEqual(publishedDashboard.binding);
    expect(workflow.dashboards?.[0].charts).toEqual(publishedDashboard.charts);
  });

  it("retains control-flow recovery evidence when mapping executions to the rail", () => {
    const recovery = { controlId: "try-import", failedNodeId: "import", catchNodeIds: ["report"], status: "recovered" as const, bounded: true };
    const plan = [{ controlId: "try-import", kind: "try_catch" as const, tryNodeIds: ["import"], catchNodeIds: ["report"], bounded: true }];
    const item = buildExecutionRailItems([{ ...executionRecords[0], controlFlowPlan: plan, controlFlowRecovery: recovery }])[0];
    expect(item.controlFlowPlan).toEqual(plan);
    expect(item.controlFlowRecovery).toEqual(recovery);
    expect(item.controlFlowRecovery?.failedNodeId).toBe("import");
  });

  it("preserves backend graph and runtime metadata rather than generating replacement nodes", () => {
    const workflow = buildWorkflowFromGateway(workflowSummary, backendWorkflow);
    expect(workflow.nodes).toEqual(backendWorkflow.nodes);
    expect(workflow.connections).toEqual(backendWorkflow.connections);
    expect(workflow.graph).toEqual(backendWorkflow.graph);
    expect(workflow.runtime).toEqual(backendWorkflow.runtime);
    const layouts = buildCanvasNodeLayouts(workflow);
    expect(layouts[workflow.nodes[0].id].x).toBe(36);
    expect(layouts[workflow.nodes[0].id].width).toBe(176);
  });

  it("shows execution failures, queue states, and stream state with backend reasons", () => {
    const base = executionRecords[0];
    const records = ["accepted", "queued", "running", "completed", "failed"].map((status) => ({
      ...base,
      status: status as typeof base.status,
      streamLifecycleStatus: undefined,
      dispatchLane: undefined,
      startedAt: undefined,
      finishedAt: undefined,
      updatedAt: base.createdAt,
      statusHistory: []
    }));
    const items = buildExecutionRailItems(records);
    expect(items.map((item) => item.status)).toEqual(["configured", "configured", "running", "executed", "error"]);
    expect(items[4].trigger).toBe("Gateway execution failed");
    expect(items[0].duration).toBe("in-flight");
    const stream = buildExecutionRailItems([{ ...records[2], streamLifecycleStatus: "active" }])[0];
    expect(stream.status).toBe("streaming_active");
    expect(stream.trigger).toBe("Stream lifecycle active");
    const dispatched = buildExecutionRailItems([{ ...records[1], dispatchLane: "cpu", dispatchWorkerPool: undefined }])[0];
    expect(dispatched.trigger).toBe("Dispatched to cpu lane");
    expect(dispatched.planner).toContain("cpu/default");
    const reason = buildExecutionRailItems([{ ...base, status: "failed", streamLifecycleStatus: undefined,
      statusHistory: [{ status: "failed", at: base.updatedAt, message: "Input artifact missing" }] }])[0];
    expect(reason.trigger).toBe("Input artifact missing");
  });

  it("keeps checkpoint tags and supplies distinct tags only for unnamed checkpoints", () => {
    const records = ["cp/saved", "", ""].map((tag) => ({
      tag, summary: "Saved execution evidence", createdAt: "2026-09-20T00:00:00Z",
      workflowId: "workflow-checkpoints", executionId: "execution-checkpoints"
    }));
    const items = buildCheckpointRailItems(records);
    expect(items.map((item) => item.tag)).toEqual(["cp/saved", "cp/live-02", "cp/live-03"]);
    expect(items.map((item) => item.state)).toEqual(["ready", "validating", "blocked"]);
    expect(items[0].scope).toBe("Saved execution evidence");
  });

  it("maps workflow metadata and helper outputs", () => {
    const workflow = buildWorkflowFromGateway({
      workflowId: "wf-helper",
      name: "Helper",
      version: "1.0.0",
      nodeCount: 3,
      connectionCount: 2,
      latestCheckpoint: "cp/test",
      executionCount: 1
    });

    expect(workflow.nodes.length).toBeGreaterThan(0);
    expect(Object.keys(buildCanvasNodeLayouts(workflow))).toHaveLength(workflow.nodes.length);
    expect(buildExecutionRailItems([])).toHaveLength(0);
    expect(buildCheckpointRailItems([])).toHaveLength(0);
    expect(formatPortSummary(workflow.connections, workflow.nodes[0].id)).toContain("out");
    expect(portTypeCounts(workflow).some((entry) => entry.type === "data_table")).toBe(true);
  });
});

describe("JuliaFlow local-only app redesign", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    window.history.pushState({}, "", "/");
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "", runtimeMode: "demo" };
    Object.defineProperty(window, "showDirectoryPicker", {
      configurable: true,
      value: undefined
    });
  });

  afterEach(() => {
    cleanup();
    vi.restoreAllMocks();
    vi.useRealTimers();
    window.__JULIAFLOW_CONFIG__ = undefined;
  });

  it("renders the mock-aligned local shell and navigates routes", () => {
    render(<App />);

    expect(screen.getByRole("status", { name: /100% local status/i })).toHaveTextContent("100% Local");
    expect(screen.getByRole("heading", { name: /local workspace overview/i })).toBeInTheDocument();
    expect(screen.getByText("Project Trust Boundary")).toBeInTheDocument();
    expect(screen.getByText("System Health")).toBeInTheDocument();
    expect(screen.getByLabelText("Local project artifact hierarchy")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "+ New Project" }));
    expect(screen.getByRole("dialog", { name: "Create New Project" })).toBeInTheDocument();
    expect(screen.getByLabelText("Description")).toHaveValue(
      "Creates a local workspace scaffold using the current appliance profile and sample workflow template."
    );
    fireEvent.change(screen.getByLabelText("Project name"), { target: { value: "A" } });
    fireEvent.click(screen.getByRole("button", { name: "Create Local Project" }));
    expect(screen.getByText("Project name must be at least 3 characters.")).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText("Project name"), { target: { value: "Foundation PoC" } });
    fireEvent.change(screen.getByLabelText("Description"), { target: { value: "Local churn analysis workspace" } });
    fireEvent.change(screen.getByLabelText("Folder path"), { target: { value: "/Users/alexj/JuliaFlowLocal/Projects/Foundation_PoC" } });
    fireEvent.click(screen.getByRole("button", { name: "Create Local Project" }));
    expect(screen.getByText("Local project scaffold created at /Users/alexj/JuliaFlowLocal/Projects/Foundation_PoC.")).toBeInTheDocument();
    expect(screen.getByText("Foundation_PoC/Project.toml")).toBeInTheDocument();
    fireEvent.click(screen.getAllByRole("button", { name: "Copy Path" })[0]);
    expect(screen.getByText(/Artifact path/)).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Open grid menu" }));
    expect(screen.getByRole("dialog", { name: "Module Launcher" })).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Close utility dialog" }));

    fireEvent.click(screen.getByRole("button", { name: "Open share panel" }));
    expect(screen.getByRole("dialog", { name: "Local Export And Share" })).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Prepare Bundle" }));
    expect(screen.getByText("Local reproducibility bundle export queued for this workspace.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Open help" }));
    expect(screen.getByRole("dialog", { name: "Workspace Help" })).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Done" }));

    fireEvent.click(screen.getByRole("button", { name: "Open local profile" }));
    expect(screen.getByRole("dialog", { name: "Local Profile" })).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Done" }));

    fireEvent.click(screen.getByRole("button", { name: "Data" }));
    expect(screen.getByRole("heading", { name: "Data" })).toBeInTheDocument();
    expect(screen.getByText("C-1001")).toBeInTheDocument();
    expect(screen.getByText("Dataset Catalog")).toBeInTheDocument();
    expect(screen.getByText("Read Mode Selector")).toBeInTheDocument();
    expect(screen.getByText("Artifact Lineage")).toBeInTheDocument();
    expect(screen.getByText("ML Readiness")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: /global-superstore-local/i }));
    expect(screen.getAllByText("CA-2016-152156").length).toBeGreaterThan(0);
    expect(screen.getAllByText("profit").length).toBeGreaterThan(0);
    fireEvent.click(screen.getByRole("button", { name: /duckdb query view/i }));
    expect(screen.getByText("Synthetic duckdb profile loaded from fixture.")).toBeInTheDocument();
    expect(screen.getByText("Generated Julia Code")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Transform" }));
    expect(screen.getByRole("heading", { name: "Transform" })).toBeInTheDocument();
    expect(screen.getByText("Visual Transform Pipeline")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "ML Studio" }));
    expect(screen.getByRole("heading", { name: "ML Studio" })).toBeInTheDocument();
    expect(screen.getByText("Experiment Tracker")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Models" }));
    expect(screen.getByRole("heading", { name: "Models" })).toBeInTheDocument();
    expect(screen.getAllByText("Churn Prediction").length).toBeGreaterThan(0);

    fireEvent.click(screen.getByRole("button", { name: "Visualize" }));
    expect(screen.getByRole("heading", { name: "Visualize" })).toBeInTheDocument();
    expect(screen.getByRole("tab", { name: "EDA" })).toHaveAttribute("aria-selected", "true");
    expect(screen.getByText("EDA Overview")).toBeInTheDocument();
    expect(screen.getByText("Distribution And Target Checks")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("tab", { name: "Model Diagnostics" }));
    expect(screen.getByText("ROC, Precision-Recall, And Calibration")).toBeInTheDocument();
    expect(screen.getByText("Confusion Matrix And Thresholds")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("tab", { name: "Experiment Compare" }));
    expect(screen.getByText("Experiment Comparison")).toBeInTheDocument();
    expect(screen.getByText("Bias And Variance Review")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("tab", { name: "Dashboard" }));
    expect(screen.getByText("Local Save And Export Actions")).toBeInTheDocument();
    expect(screen.getByText("Artifact Rows")).toBeInTheDocument();
    expect(screen.getByText("C-1001")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Deploy" }));
    expect(screen.getByRole("heading", { name: "Deploy" })).toBeInTheDocument();
    expect(screen.getByText("Generated Julia API Code")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Monitor" }));
    expect(screen.getByRole("heading", { name: "Execution Monitor" })).toBeInTheDocument();
    expect(screen.getAllByText("exec-local-churn-001").length).toBeGreaterThan(0);
    expect(screen.getByText("Executed Explainability Evidence")).toBeInTheDocument();
    expect(screen.getByText("bbbbbbbbbbbb")).toBeInTheDocument();
    expect(screen.getByText("data/models/churn_model_v1.jls")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Settings" }));
    expect(screen.getByRole("heading", { name: "Settings" })).toBeInTheDocument();
    expect(screen.getByText("Security And API Keys")).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText("Worker concurrency"), { target: { value: "2" } });
    fireEvent.click(screen.getByRole("button", { name: "Save Local Settings" }));
    expect(screen.getByText("Compute settings staged locally for this demo workspace.")).toBeInTheDocument();
    expect(screen.getByText("Applied concurrency")).toBeInTheDocument();
    expect(screen.getByText("2")).toBeInTheDocument();
  });

  it("writes project scaffold files when a target folder is granted", async () => {
    const writes: Array<{ path: string; content: string }> = [];
    const close = vi.fn(async () => undefined);

    function directoryHandle(path = "Browser_Project") {
      return {
        name: path,
        getDirectoryHandle: vi.fn(async (name: string) => directoryHandle(`${path}/${name}`)),
        getFileHandle: vi.fn(async (name: string) => ({
          createWritable: vi.fn(async () => ({
            write: vi.fn(async (content: string) => {
              writes.push({ path: `${path}/${name}`, content });
            }),
            close
          }))
        }))
      };
    }

    const rootDirectory = directoryHandle("Browser_Project");
    Object.defineProperty(window, "showDirectoryPicker", {
      configurable: true,
      value: vi.fn(async () => rootDirectory)
    });

    render(<App />);

    fireEvent.click(screen.getByRole("button", { name: "+ New Project" }));
    fireEvent.change(screen.getByLabelText("Project name"), { target: { value: "Browser Project" } });
    fireEvent.change(screen.getByLabelText("Description"), { target: { value: "Filesystem scaffold test" } });
    fireEvent.change(screen.getByLabelText("Folder path"), { target: { value: "/Users/alexj/JuliaFlowLocal/Projects/Browser_Project" } });
    fireEvent.click(screen.getByRole("button", { name: "Choose Target Folder" }));
    await screen.findByText("Write access granted: Browser_Project");

    fireEvent.click(screen.getByRole("button", { name: "Create Local Project" }));

    await waitFor(() => expect(writes.map((write) => write.path)).toEqual([
      "Browser_Project/Project.toml",
      "Browser_Project/README.md",
      "Browser_Project/workflows/wf-browser-project.toml",
      "Browser_Project/data/raw/.gitkeep"
    ]));
    expect(writes.find((write) => write.path.endsWith("README.md"))?.content).toContain("Filesystem scaffold test");
    expect(close).toHaveBeenCalledTimes(4);
    expect(screen.getByText("Local project scaffold written to Browser_Project.")).toBeInTheDocument();
  });

  it("runs redesigned actions through deterministic demo fallback without a gateway", () => {
    render(<App />);

    fireEvent.click(screen.getByRole("button", { name: /save workflow/i }));
    expect(screen.getByText("Workflow save stayed in deterministic demo mode.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /run workflow/i }));
    expect(screen.getByText("Workflow run stayed in deterministic demo mode.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Data" }));
    fireEvent.click(screen.getByRole("button", { name: /re-profile active dataset/i }));
    expect(screen.getByText("Synthetic csv profile loaded from fixture.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Transform" }));
    fireEvent.click(screen.getByRole("button", { name: /run transform/i }));
    expect(screen.getByText("Synthetic transform history displayed.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "ML Studio" }));
    fireEvent.click(screen.getByRole("button", { name: /train new model/i }));
    expect(screen.getByText("Synthetic ML experiment metrics displayed.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Models" }));
    fireEvent.click(screen.getByRole("button", { name: /register model/i }));
    expect(screen.getByText("Synthetic model registry detail displayed.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Visualize" }));
    fireEvent.click(screen.getByRole("tab", { name: "Dashboard" }));
    fireEvent.click(screen.getByRole("button", { name: /save local checkpoint/i }));
    expect(screen.getByText("Synthetic dashboard checkpoint export displayed.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Deploy" }));
    fireEvent.click(screen.getByRole("button", { name: /package local endpoint/i }));
    expect(screen.getByText("Synthetic local deploy package displayed.")).toBeInTheDocument();
  });

  it("classifies local chart specs for ready, stale, empty, and missing states", () => {
    const ready = localHealth.charts?.find((chart) => chart.chartId === "workspace-cpu-trend");
    const stale = localHealth.charts?.find((chart) => chart.chartId === "workspace-disk-trend");
    expect(chartReadiness(ready)).toBe("ready");
    expect(chartReadiness(stale)).toBe("stale");
    expect(canRenderChart(stale)).toBe(true);
    expect(chartStatusLabel(stale)).toBe("Stale local evidence");
    expect(chartReadiness(undefined)).toBe("empty");
    expect(canRenderChart({ ...ready!, status: "empty", data: [] })).toBe(false);
    expect(chartReadiness({ ...ready!, status: "stale", data: [] })).toBe("empty");
    expect(canRenderChart({ ...ready!, status: "stale", data: [] })).toBe(false);
  });

  it("updates Data sampling and Transform node config state", () => {
    render(<App />);

    fireEvent.click(screen.getByRole("button", { name: "Data" }));
    fireEvent.click(screen.getByRole("tab", { name: "sampling" }));
    fireEvent.change(screen.getByLabelText("Preview sample"), { target: { value: "2" } });
    fireEvent.click(screen.getByRole("tab", { name: "table" }));
    expect(screen.getByText("C-1001")).toBeInTheDocument();
    expect(screen.getByText("C-1005")).toBeInTheDocument();
    expect(screen.queryByText("C-1003")).not.toBeInTheDocument();
    expect(screen.getByText("Project Schema Diagnostics")).toBeInTheDocument();
    expect(screen.getByText("Validation And Test Plan")).toBeInTheDocument();
    expect(screen.getByText("Local Dataset Wizard")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /S3-compatible object store/ })).toBeDisabled();
    expect(screen.getByRole("button", { name: /Google Cloud Storage/ })).toBeDisabled();
    expect(screen.getByRole("button", { name: /Azure Blob Storage/ })).toBeDisabled();
    fireEvent.change(screen.getByLabelText("Dataset role"), { target: { value: "reference" } });
    expect(screen.getByDisplayValue("reference")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Apply Role Suggestions" }));
    expect(screen.getByText(/Assign target and id roles|Dataset onboarding is ready/)).toBeInTheDocument();
    fireEvent.click(screen.getByRole("tab", { name: "schema" }));
    fireEvent.change(screen.getByLabelText("Column role for monthly_charges"), { target: { value: "target" } });
    expect(screen.getByText("Project schema and validation choices updated in demo workspace.")).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText("Logical type for contract_type"), { target: { value: "ordinal" } });
    expect(screen.getByDisplayValue("ordinal")).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText("Validation strategy"), { target: { value: "grouped" } });
    expect(screen.getByDisplayValue("grouped")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Lock Final Test Split" }));
    expect(screen.getAllByRole("button", { name: "Final Test Locked" }).every((button) => button.hasAttribute("disabled"))).toBe(true);

    fireEvent.click(screen.getByRole("button", { name: "Transform" }));
    expect(screen.getByText("Pipeline Keyboard Outline")).toBeInTheDocument();
    expect(screen.getByLabelText("Keyboard-accessible transform nodes")).toBeInTheDocument();
    fireEvent.click(screen.getAllByText("Feature Engineering")[0]);
    fireEvent.change(screen.getByLabelText("Output column prefix"), { target: { value: "encoded_features" } });
    expect(screen.getByDisplayValue("encoded_features")).toBeInTheDocument();
    expect(screen.getAllByText(/encoded_features/).length).toBeGreaterThan(1);
    expect(screen.getByText("Unsaved canvas edits detected")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Trim Text" }));
    expect(screen.getAllByText("Trim Text").length).toBeGreaterThan(1);
    expect(screen.getByText("custom.palette_node")).toBeInTheDocument();
    expect(screen.getByDisplayValue("trim_text")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Validate" }));
    expect(screen.getByText("Pipeline is locally valid")).toBeInTheDocument();
  });

  it("renders project data profile and statistical workflow evidence in Data", async () => {
    window.__JULIAFLOW_CONFIG__ = {
      gatewayBaseUrl: "http://127.0.0.1:8088",
      runtimeMode: "local-appliance"
    };
    const datasetId = dataScienceProject.datasets[0]?.datasetId ?? "customer-churn-local";
    const projectWithDataEvidence = {
      ...dataScienceProject,
      statisticalAnalysisRuns: [
        {
          analysisRunId: "stats-project-data-001",
          datasetId,
          method: "summary, correlation, t_test, chi_square, anova",
          status: "completed",
          generatedCodeRef: "stats/customer-churn/statistical_eda.jl",
          resultRef: "stats/customer-churn/statistical_results.json",
          resultSummary: { pearson: 0.42, spearman: 0.39, tTestPValue: 0.018 },
          artifactRefs: [
            {
              refId: "stats-project-data-001-result",
              kind: "statistics",
              localOnly: true,
              checksumSha256: "d".repeat(64),
              path: "stats/customer-churn/statistical_results.json",
              generatedAt: "2026-06-27T09:15:00Z"
            }
          ],
          charts: [],
          warnings: [],
          createdAt: "2026-06-27T09:15:00Z"
        }
      ],
      projectJobs: [
        {
          jobId: "job-data-profile-001",
          projectId: dataScienceProject.projectId,
          jobType: "data_profile",
          status: "completed",
          datasetId,
          outputRefs: [
            {
              refId: "profile-project-data-001",
              kind: "dataset_profile",
              localOnly: true,
              checksumSha256: "e".repeat(64),
              path: "profiles/customer-churn/profile.json",
              generatedAt: "2026-06-27T09:00:00Z"
            }
          ],
          executionEvidence: {
            executionId: "exec-data-profile-001",
            workflowId: workflowSummary.workflowId,
            status: "completed",
            mode: "local_project_job",
            workerId: "local-cpu-worker",
            orchestrationMode: "worker_service_tick",
            dispatchStatus: "completed",
            workerPool: "local-cpu",
            dispatchLane: "cpu",
            queuedAt: "2026-06-27T09:00:00Z",
            startedAt: "2026-06-27T09:00:10Z",
            finishedAt: "2026-06-27T09:03:00Z"
          },
          startedAt: "2026-06-27T09:00:10Z",
          finishedAt: "2026-06-27T09:03:00Z"
        }
      ]
    };
    const health = {
      ...localHealth,
      runtime: {
        mode: "local-appliance",
        fixtureProvenance: "backend",
        fixtureSubstitutionAllowed: false,
        unavailable: []
      },
      runtimeMode: "local-appliance",
      fixtureProvenance: "backend",
      fixtureSubstitutionAllowed: false,
      unavailable: []
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.endsWith("/health")) return json(health);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: [], count: 0 });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json(backendWorkflow);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [publishedDashboard] });
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [projectWithDataEvidence], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: [], count: 0 });
      if (url.includes("/ml/experiments")) return json({ items: [], count: 0 });
      if (url.includes("/models")) return json({ items: [], count: 0 });
      if (url.includes("/deploy/packages")) return json({ items: [], count: 0 });
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    fireEvent.click(screen.getByRole("button", { name: "Data" }));
    expect(screen.getByText("Project Data Workflow Evidence")).toBeInTheDocument();
    expect(screen.getByText("job-data-profile-001")).toBeInTheDocument();
    expect(screen.getByText("exec-data-profile-001")).toBeInTheDocument();
    expect(screen.getByText("stats-project-data-001")).toBeInTheDocument();
    expect(screen.getByText("summary, correlation, t_test, chi_square, anova (completed)")).toBeInTheDocument();
    expect(screen.getAllByText("stats/customer-churn/statistical_results.json").length).toBeGreaterThan(0);
    expect(screen.getByText("stats/customer-churn/statistical_eda.jl")).toBeInTheDocument();
  });

  it("renders project-backed statistical analysis evidence in Visualize", async () => {
    window.__JULIAFLOW_CONFIG__ = {
      gatewayBaseUrl: "http://127.0.0.1:8088",
      runtimeMode: "local-appliance"
    };
    const datasetId = dataScienceProject.datasets[0]?.datasetId ?? "customer-churn-local";
    const projectWithVisualizeEvidence = {
      ...dataScienceProject,
      statisticalAnalysisRuns: [
        {
          analysisRunId: "stats-project-visualize-001",
          datasetId,
          method: "ols_residual_diagnostics",
          status: "completed",
          generatedCodeRef: "stats/customer-churn/ols_diagnostics.jl",
          resultRef: "stats/customer-churn/ols_diagnostics.json",
          resultSummary: { rSquared: 0.71, residualWarningCount: 1 },
          artifactRefs: [
            {
              refId: "stats-project-visualize-001-result",
              kind: "statistics",
              localOnly: true,
              checksumSha256: "f".repeat(64),
              path: "stats/customer-churn/ols_diagnostics.json",
              generatedAt: "2026-06-28T11:15:00Z"
            }
          ],
          charts: [],
          warnings: ["Residual normality warning"],
          createdAt: "2026-06-28T11:15:00Z"
        }
      ]
    };
    const health = {
      ...localHealth,
      runtime: {
        mode: "local-appliance",
        fixtureProvenance: "backend",
        fixtureSubstitutionAllowed: false,
        unavailable: []
      },
      runtimeMode: "local-appliance",
      fixtureProvenance: "backend",
      fixtureSubstitutionAllowed: false,
      unavailable: []
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.endsWith("/health")) return json(health);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: [], count: 0 });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json(backendWorkflow);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [publishedDashboard] });
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [projectWithVisualizeEvidence], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: [], count: 0 });
      if (url.includes("/ml/experiments")) return json({ items: [], count: 0 });
      if (url.includes("/models")) return json({ items: [], count: 0 });
      if (url.includes("/deploy/packages")) return json({ items: [], count: 0 });
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    fireEvent.click(screen.getByRole("button", { name: "Visualize" }));
    expect(screen.getByText("Project Statistical Analysis Evidence")).toBeInTheDocument();
    expect(screen.getByText("stats-project-visualize-001")).toBeInTheDocument();
    expect(screen.getByText("ols_residual_diagnostics")).toBeInTheDocument();
    expect(screen.getByText("stats/customer-churn/ols_diagnostics.json")).toBeInTheDocument();
    expect(screen.getByText("stats/customer-churn/ols_diagnostics.jl")).toBeInTheDocument();
    expect(screen.getByText("ffffffffffff")).toBeInTheDocument();
  });

  it("renders project-backed transform fit/apply evidence from the active project", async () => {
    window.__JULIAFLOW_CONFIG__ = {
      gatewayBaseUrl: "http://127.0.0.1:8088",
      runtimeMode: "development"
    };
    const transformRunId = "tf-project-transform-001";
    const transformExecutionId = "exec-project-transform-001";
    const projectWithTransformEvidence = {
      ...dataScienceProject,
      transformFitApplyRecords: [
        {
          transformRunId,
          datasetId: dataScienceProject.datasets[0]?.datasetId ?? "customer-churn-local",
          splitPlanId: dataScienceProject.splitPlans[0]?.splitPlanId ?? "split-customer-churn-validation",
          fitSplit: "train",
          applySplits: ["validation", "test"],
          transformRef: "transforms/customer-churn-fit-apply.jl",
          leakageChecks: [
            { checkId: "fit-train-only", status: "passed", detail: "Transform state was fit on train only." },
            { checkId: "apply-held-out", status: "passed", detail: "Frozen state applied to validation and test." }
          ],
          artifactRefs: [
            {
              refId: "tf-project-transform-001-artifact",
              kind: "transform",
              localOnly: true,
              checksumSha256: "b".repeat(64),
              path: "data/features/customer-churn-fit-apply.parquet",
              generatedAt: "2026-06-23T09:03:00Z"
            }
          ],
          createdAt: "2026-06-23T09:03:00Z"
        }
      ],
      projectJobs: [
        {
          jobId: "job-project-transform-001",
          projectId: dataScienceProject.projectId,
          jobType: "transform_fit_apply",
          status: "completed",
          datasetId: dataScienceProject.datasets[0]?.datasetId,
          splitPlanId: dataScienceProject.splitPlans[0]?.splitPlanId,
          sourceRecordId: transformRunId,
          outputRefs: [
            {
              refId: "tf-project-transform-001-artifact",
              kind: "transform",
              localOnly: true,
              checksumSha256: "b".repeat(64),
              path: "data/features/customer-churn-fit-apply.parquet",
              generatedAt: "2026-06-23T09:03:00Z"
            }
          ],
          executionEvidence: {
            executionId: transformExecutionId,
            workflowId: workflowSummary.workflowId,
            status: "completed",
            mode: "local_project_job",
            workerId: "local-cpu-worker",
            orchestrationMode: "worker_service_tick",
            dispatchStatus: "completed",
            workerPool: "local-cpu",
            dispatchLane: "cpu",
            queuedAt: "2026-06-23T09:00:00Z",
            startedAt: "2026-06-23T09:00:10Z",
            finishedAt: "2026-06-23T09:03:00Z"
          },
          startedAt: "2026-06-23T09:00:10Z",
          finishedAt: "2026-06-23T09:03:00Z"
        }
      ]
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.endsWith("/health")) return json(localHealth);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: executionRecords, count: executionRecords.length });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json(backendWorkflow);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [publishedDashboard] });
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [projectWithTransformEvidence], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: transformRuns, count: transformRuns.length });
      if (url.includes("/ml/experiments")) return json({ items: mlExperiments, count: mlExperiments.length });
      if (url.includes("/models")) return json({ items: modelRegistry, count: modelRegistry.length });
      if (url.includes("/deploy/packages")) return json({ items: deployPackages, count: deployPackages.length });
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    fireEvent.click(screen.getByRole("button", { name: "Transform" }));
    expect(screen.getByText("Project Transform Evidence")).toBeInTheDocument();
    expect(screen.getByText(transformRunId)).toBeInTheDocument();
    expect(screen.getByText("validation, test")).toBeInTheDocument();
    expect(screen.getByText("job-project-transform-001")).toBeInTheDocument();
    expect(screen.getByText(transformExecutionId)).toBeInTheDocument();
  });

  it("uses project-backed model registry and deploy job evidence when route lists are empty", async () => {
    window.__JULIAFLOW_CONFIG__ = {
      gatewayBaseUrl: "http://127.0.0.1:8088",
      runtimeMode: "local-appliance"
    };
    const projectModel = {
      ...modelRegistry[0],
      registryId: "reg-project-only",
      modelId: "Project Registry Model",
      status: "approved",
      deploymentStatus: "local_ready"
    };
    const projectWithModelAndDeployEvidence = {
      ...dataScienceProject,
      modelRegistryRecords: [projectModel],
      modelLifecycleRecords: [
        {
          modelId: projectModel.modelId,
          state: "approved",
          evaluationReportId: "eval-project-registry-model",
          updatedAt: "2026-06-24T09:00:00Z"
        }
      ],
      projectJobs: [
        {
          jobId: "job-project-deploy-001",
          projectId: dataScienceProject.projectId,
          jobType: "deploy_package",
          status: "completed",
          sourceRecordId: "pkg-project-deploy-001",
          outputRefs: [
            {
              refId: "pkg-project-deploy-001",
              kind: "deploy_package",
              localOnly: true,
              checksumSha256: "c".repeat(64),
              path: "deploy/project-registry-model/package.tar.gz",
              generatedAt: "2026-06-24T09:04:00Z"
            }
          ],
          executionEvidence: {
            executionId: "exec-project-deploy-001",
            workflowId: workflowSummary.workflowId,
            status: "completed",
            mode: "local_project_job",
            workerId: "local-cpu-worker",
            orchestrationMode: "worker_service_tick",
            dispatchStatus: "completed",
            workerPool: "local-cpu",
            dispatchLane: "cpu",
            queuedAt: "2026-06-24T09:00:00Z",
            startedAt: "2026-06-24T09:00:10Z",
            finishedAt: "2026-06-24T09:04:00Z"
          },
          startedAt: "2026-06-24T09:00:10Z",
          finishedAt: "2026-06-24T09:04:00Z"
        }
      ]
    };
    const health = {
      ...localHealth,
      runtime: {
        mode: "local-appliance",
        fixtureProvenance: "backend",
        fixtureSubstitutionAllowed: false,
        unavailable: []
      },
      runtimeMode: "local-appliance",
      fixtureProvenance: "backend",
      fixtureSubstitutionAllowed: false,
      unavailable: []
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.endsWith("/health")) return json(health);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: [], count: 0 });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json(backendWorkflow);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [publishedDashboard] });
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [projectWithModelAndDeployEvidence], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: [], count: 0 });
      if (url.includes("/ml/experiments")) return json({ items: [], count: 0 });
      if (url.includes("/models")) return json({ items: [], count: 0 });
      if (url.includes("/deploy/packages")) return json({ items: [], count: 0 });
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    fireEvent.click(screen.getByRole("button", { name: "Models" }));
    expect(screen.getAllByText("Project Registry Model").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Project-backed registry records").length).toBeGreaterThan(0);
    expect(screen.queryByText("No backend model registry records are available for this workspace yet. Register a model after training completes.")).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Deploy" }));
    expect(screen.getAllByText("job-project-deploy-001").length).toBeGreaterThan(0);
    expect(screen.getByText("exec-project-deploy-001")).toBeInTheDocument();
    expect(screen.getByText("deploy/project-registry-model/package.tar.gz")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /package local endpoint/i })).toBeEnabled();
    expect(screen.queryByText("No registered model is available.")).not.toBeInTheDocument();
  });

  it("renders project validation, tuning, evaluation, prediction, and drift evidence in ML Studio", async () => {
    window.__JULIAFLOW_CONFIG__ = {
      gatewayBaseUrl: "http://127.0.0.1:8088",
      runtimeMode: "local-appliance"
    };
    const projectWithValidationWorkflow = {
      ...dataScienceProject,
      trainingPlans: [
        {
          trainingPlanId: "plan-project-validation-001",
          targetColumn: "churn",
          taskType: "classification",
          metricNames: ["auc", "f1"],
          splitPlanId: dataScienceProject.splitPlans[0]?.splitPlanId ?? "split-customer-churn-validation",
          transformRef: "transforms/customer-churn-fit-apply.jl",
          seed: 42,
          createdAt: "2026-06-25T09:00:00Z"
        }
      ],
      tuningStudies: [
        {
          tuningStudyId: "tune-project-validation-001",
          trainingPlanId: "plan-project-validation-001",
          validationOnly: true,
          bestTrialId: "trial-project-validation-best",
          trials: [
            {
              trialId: "trial-project-validation-best",
              parameters: { max_depth: 6, learning_rate: 0.05 },
              metrics: { auc: 0.918, f1: 0.872 },
              artifactRefs: []
            }
          ],
          validationEvidence: {
            projectId: dataScienceProject.projectId,
            datasetId: dataScienceProject.datasets[0]?.datasetId,
            splitPlanId: dataScienceProject.splitPlans[0]?.splitPlanId,
            splitStrategy: "stratified",
            validationFraction: 0.15,
            testFraction: 0.15,
            finalTestPolicy: "forbid_final_test"
          },
          createdAt: "2026-06-25T09:20:00Z"
        }
      ],
      evaluationReports: [
        {
          evaluationReportId: "eval-project-validation-001",
          trainingPlanId: "plan-project-validation-001",
          splitPlanId: dataScienceProject.splitPlans[0]?.splitPlanId ?? "split-customer-churn-validation",
          metrics: { auc: 0.914, f1: 0.868 },
          approved: true,
          finalTestOnly: true,
          validationEvidence: {
            projectId: dataScienceProject.projectId,
            datasetId: dataScienceProject.datasets[0]?.datasetId,
            splitPlanId: dataScienceProject.splitPlans[0]?.splitPlanId,
            tuningStudyId: "tune-project-validation-001",
            finalTestPolicy: "use_final_test",
            validationOnlyTuning: true,
            testFraction: 0.15
          },
          generatedAt: "2026-06-25T09:45:00Z",
          artifactRefs: []
        }
      ],
      predictionExports: [
        {
          predictionExportId: "pred-project-validation-001",
          evaluationReportId: "eval-project-validation-001",
          outputContractRef: "contracts/churn-output.json",
          artifactRef: "exports/churn/predictions.parquet",
          rowCount: 3200,
          format: "parquet",
          outputColumns: ["customer_id", "prediction", "probability"],
          createdAt: "2026-06-25T10:00:00Z"
        }
      ],
      monitoringBaselines: [
        {
          baselineId: "baseline-project-validation-001",
          modelId: "Churn Prediction",
          datasetId: dataScienceProject.datasets[0]?.datasetId ?? "customer-churn-local",
          metricNames: ["psi", "ks"],
          predictionExportId: "pred-project-validation-001",
          evaluationReportId: "eval-project-validation-001",
          createdAt: "2026-06-25T10:10:00Z"
        }
      ],
      driftReports: [
        {
          driftReportId: "drift-project-validation-001",
          baselineId: "baseline-project-validation-001",
          status: "moderate",
          metrics: { psi: 0.21, ks: 0.12 },
          validationEvidence: {
            projectId: dataScienceProject.projectId,
            datasetId: dataScienceProject.datasets[0]?.datasetId,
            predictionExportId: "pred-project-validation-001",
            evaluationReportId: "eval-project-validation-001",
            outputContractRef: "contracts/churn-output.json"
          },
          generatedAt: "2026-06-25T10:30:00Z"
        }
      ]
    };
    const health = {
      ...localHealth,
      runtime: {
        mode: "local-appliance",
        fixtureProvenance: "backend",
        fixtureSubstitutionAllowed: false,
        unavailable: []
      },
      runtimeMode: "local-appliance",
      fixtureProvenance: "backend",
      fixtureSubstitutionAllowed: false,
      unavailable: []
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.endsWith("/health")) return json(health);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: [], count: 0 });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json(backendWorkflow);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [publishedDashboard] });
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [projectWithValidationWorkflow], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: [], count: 0 });
      if (url.includes("/ml/experiments")) return json({ items: mlExperiments, count: mlExperiments.length });
      if (url.includes("/models")) return json({ items: modelRegistry, count: modelRegistry.length });
      if (url.includes("/deploy/packages")) return json({ items: deployPackages, count: deployPackages.length });
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    fireEvent.click(screen.getByRole("button", { name: "ML Studio" }));
    expect(screen.getByText("Project Validation Workflow")).toBeInTheDocument();
    expect(screen.getByText("plan-project-validation-001")).toBeInTheDocument();
    expect(screen.getByText("tune-project-validation-001 (validation only)")).toBeInTheDocument();
    expect(screen.getByText("trial-project-validation-best")).toBeInTheDocument();
    expect(screen.getByText("eval-project-validation-001 (approved)")).toBeInTheDocument();
    expect(screen.getByText("pred-project-validation-001 (3,200 rows)")).toBeInTheDocument();
    expect(screen.getByText("drift-project-validation-001 (moderate)")).toBeInTheDocument();
  });

  it("renders project lifecycle rollback and retraining evidence in Models", async () => {
    window.__JULIAFLOW_CONFIG__ = {
      gatewayBaseUrl: "http://127.0.0.1:8088",
      runtimeMode: "local-appliance"
    };
    const lifecycleModel = {
      ...modelRegistry[0],
      registryId: "reg-lifecycle-project",
      modelId: "Lifecycle Review Model",
      status: "retraining_requested",
      deploymentStatus: "local_ready"
    };
    const projectWithLifecycleReview = {
      ...dataScienceProject,
      modelRegistryRecords: [lifecycleModel],
      modelLifecycleRecords: [
        {
          modelId: lifecycleModel.modelId,
          state: "retraining_requested",
          evaluationReportId: "eval-lifecycle-review-001",
          deployedEndpointId: "pkg-lifecycle-current",
          rollbackModelId: "Lifecycle Review Model v0",
          rollbackPackageId: "pkg-lifecycle-rollback",
          rollbackPackageRef: "deploy/lifecycle/rollback-package.tar.gz",
          lifecycleAction: "request_retraining",
          retrainingReason: "post-rollback retraining requested",
          retrainingTrainingPlanId: "retraining-plan-lifecycle-001",
          retrainingTuningStudyId: "retraining-tune-lifecycle-001",
          retrainingJobId: "job-retraining-lifecycle-001",
          validationEvidence: {
            projectId: dataScienceProject.projectId,
            modelId: lifecycleModel.modelId,
            previousState: "rolled_back",
            lifecycleAction: "request_retraining",
            rollbackModelId: "Lifecycle Review Model v0",
            retrainingTrainingPlanId: "retraining-plan-lifecycle-001",
            retrainingTuningStudyId: "retraining-tune-lifecycle-001",
            retrainingJobId: "job-retraining-lifecycle-001",
            reason: "post-rollback retraining requested"
          },
          updatedAt: "2026-06-26T09:30:00Z"
        }
      ],
      projectJobs: [
        {
          jobId: "job-lifecycle-review-001",
          projectId: dataScienceProject.projectId,
          jobType: "model_lifecycle",
          status: "completed",
          sourceRecordId: lifecycleModel.modelId,
          outputRefs: [],
          executionEvidence: {
            executionId: "exec-lifecycle-review-001",
            workflowId: workflowSummary.workflowId,
            status: "completed",
            mode: "local_project_job",
            workerId: "local-cpu-worker",
            orchestrationMode: "worker_service_tick",
            dispatchStatus: "completed",
            workerPool: "local-cpu",
            dispatchLane: "cpu",
            queuedAt: "2026-06-26T09:28:00Z",
            startedAt: "2026-06-26T09:28:10Z",
            finishedAt: "2026-06-26T09:30:00Z"
          },
          startedAt: "2026-06-26T09:28:10Z",
          finishedAt: "2026-06-26T09:30:00Z"
        }
      ]
    };
    const health = {
      ...localHealth,
      runtime: {
        mode: "local-appliance",
        fixtureProvenance: "backend",
        fixtureSubstitutionAllowed: false,
        unavailable: []
      },
      runtimeMode: "local-appliance",
      fixtureProvenance: "backend",
      fixtureSubstitutionAllowed: false,
      unavailable: []
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.endsWith("/health")) return json(health);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: [], count: 0 });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json(backendWorkflow);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [publishedDashboard] });
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [projectWithLifecycleReview], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: [], count: 0 });
      if (url.includes("/ml/experiments")) return json({ items: [], count: 0 });
      if (url.includes("/models")) return json({ items: [], count: 0 });
      if (url.includes("/deploy/packages")) return json({ items: [], count: 0 });
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    fireEvent.click(screen.getByRole("button", { name: "Models" }));
    expect(screen.getByText("Lifecycle Review")).toBeInTheDocument();
    expect(screen.getAllByText("Lifecycle Review Model").length).toBeGreaterThan(0);
    expect(screen.getByText("request_retraining")).toBeInTheDocument();
    expect(screen.getByText("Lifecycle Review Model v0")).toBeInTheDocument();
    expect(screen.getByText("job-retraining-lifecycle-001")).toBeInTheDocument();
    expect(screen.getByText("post-rollback retraining requested")).toBeInTheDocument();
    expect(screen.getByText("job-lifecycle-review-001")).toBeInTheDocument();
    expect(screen.getByText("exec-lifecycle-review-001")).toBeInTheDocument();
  });

  it("uses runtime gateway config before falling back to fixtures", async () => {
    window.__JULIAFLOW_CONFIG__ = {
      gatewayBaseUrl: "http://127.0.0.1:8088",
      runtimeMode: "development",
      gatewayAuthToken: "dev-secret",
      workspaceId: "workspace-a",
      workspaceRole: "editor"
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input, init) => {
      const url = String(input);
      const method = init?.method ?? "GET";
      if (url.endsWith("/health")) return json(localHealth);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: executionRecords, count: executionRecords.length });
      if (url.endsWith("/api/v1/local-data/import") && method === "POST") return json({ status: "profiled", profile: superstoreDataProfile });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json(backendWorkflow);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [publishedDashboard] });
      if (url.endsWith("/api/v1/data-science-projects/customer-churn-project") && method === "PUT") return json({
        ...dataScienceProject,
        updatedAt: "2026-06-21T10:30:00Z",
        schemaContracts: dataScienceProject.schemaContracts.map((schema) => ({
          ...schema,
          columns: schema.columns.map((column) => column.name === "monthly_charges" ? { ...column, role: "target" } : column)
        }))
      });
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [dataScienceProject], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: transformRuns, count: transformRuns.length });
      if (url.includes("/ml/experiments")) return json({ items: mlExperiments, count: mlExperiments.length });
      if (url.includes("/models/register") && method === "POST") return json({ status: "registered", model: modelRegistry[0] });
      if (url.includes("/models")) return json({ items: modelRegistry, count: modelRegistry.length });
      if (url.includes("/deploy/packages")) return json({ items: deployPackages, count: deployPackages.length });
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    fireEvent.click(screen.getByRole("button", { name: "Models" }));
    fireEvent.click(screen.getByRole("button", { name: /register model/i }));
    await waitFor(() => expect(screen.getByText("Gateway action completed locally.")).toBeInTheDocument());
    expect(fetchMock).toHaveBeenCalledWith(expect.stringContaining("/models/register"), expect.objectContaining({ method: "POST" }));
    const registerCall = fetchMock.mock.calls.find(([input]) => String(input).includes("/models/register"));
    expect(headerValue(registerCall?.[1], "authorization")).toBe("Bearer dev-secret");
    expect(headerValue(registerCall?.[1], "x-juliaflow-workspace")).toBe("workspace-a");
    expect(headerValue(registerCall?.[1], "x-juliaflow-workspace-role")).toBe("editor");

    fireEvent.click(screen.getByRole("button", { name: "Data" }));
    fireEvent.click(screen.getByRole("button", { name: /global-superstore-local/i }));
    fireEvent.click(screen.getByRole("button", { name: /duckdb query view/i }));
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith(
      "http://127.0.0.1:8088/api/v1/local-data/import",
      expect.objectContaining({
        method: "POST",
        body: expect.stringContaining("\"readMode\":\"duckdb\"")
      })
    ));
    await waitFor(() => expect(screen.getByText("Gateway action completed locally.")).toBeInTheDocument());
    expect(screen.getAllByText("CA-2016-152156").length).toBeGreaterThan(0);
    fireEvent.click(screen.getByRole("tab", { name: "schema" }));
    fireEvent.change(screen.getByLabelText("Column role for monthly_charges"), { target: { value: "target" } });
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith(
      "http://127.0.0.1:8088/api/v1/data-science-projects/customer-churn-project",
      expect.objectContaining({
        method: "PUT",
        body: expect.stringContaining("\"monthly_charges\"")
      })
    ));
    expect(screen.getByText("Project schema and validation choices saved to the local gateway.")).toBeInTheDocument();
  });

  it("refreshes project-backed training job evidence after an ML Studio run", async () => {
    window.__JULIAFLOW_CONFIG__ = {
      gatewayBaseUrl: "http://127.0.0.1:8088",
      runtimeMode: "development"
    };
    const trainingExecution = {
      ...executionRecords[0],
      executionId: "exec-training-ui-002",
      status: "completed",
      createdAt: "2026-06-22T09:00:00Z",
      updatedAt: "2026-06-22T09:03:00Z",
      startedAt: "2026-06-22T09:00:10Z",
      finishedAt: "2026-06-22T09:03:00Z"
    };
    const nextExperiment = {
      ...mlExperiments[0],
      experimentId: "experiment-training-ui-002",
      executionId: trainingExecution.executionId,
      validationEvidence: {
        ...mlExperiments[0].validationEvidence,
        projectId: dataScienceProject.projectId,
        trainingExecutionId: trainingExecution.executionId
      },
      executionEvidence: {
        executionId: trainingExecution.executionId,
        workflowId: workflowSummary.workflowId,
        status: "completed",
        mode: "worker",
        workerId: "local-cpu-worker",
        orchestrationMode: "gateway_worker_dispatch",
        dispatchStatus: "completed",
        workerPool: "local-cpu",
        dispatchLane: "cpu",
        queuedAt: "2026-06-22T09:00:00Z",
        startedAt: "2026-06-22T09:00:10Z",
        finishedAt: "2026-06-22T09:03:00Z"
      }
    };
    const refreshedProject = {
      ...dataScienceProject,
      projectJobs: [
        {
          jobId: "job-training-ui-002",
          projectId: dataScienceProject.projectId,
          jobType: "training",
          status: "completed",
          datasetId: dataScienceProject.datasets[0]?.datasetId,
          splitPlanId: dataScienceProject.splitPlans[0]?.splitPlanId,
          sourceRecordId: nextExperiment.experimentId,
          outputRefs: [
            {
              refId: "model-training-ui-002",
              kind: "model",
              localOnly: true,
              checksumSha256: "a".repeat(64),
              path: "models/churn-training-ui-002.jls",
              generatedAt: "2026-06-22T09:03:00Z"
            }
          ],
          executionEvidence: nextExperiment.executionEvidence,
          startedAt: "2026-06-22T09:00:10Z",
          finishedAt: "2026-06-22T09:03:00Z"
        }
      ]
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input, init) => {
      const url = String(input);
      const method = init?.method ?? "GET";
      if (url.endsWith("/health")) return json(localHealth);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: executionRecords, count: executionRecords.length });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/ml/experiments/run`) && method === "POST") {
        return json({ status: "accepted", execution: trainingExecution, experiment: nextExperiment });
      }
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json(backendWorkflow);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [publishedDashboard] });
      if (url.endsWith(`/api/v1/data-science-projects/${dataScienceProject.projectId}`)) return json(refreshedProject);
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [dataScienceProject], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: transformRuns, count: transformRuns.length });
      if (url.includes("/ml/experiments")) return json({ items: mlExperiments, count: mlExperiments.length });
      if (url.includes("/models")) return json({ items: modelRegistry, count: modelRegistry.length });
      if (url.includes("/deploy/packages")) return json({ items: deployPackages, count: deployPackages.length });
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    fireEvent.click(screen.getByRole("button", { name: "ML Studio" }));
    expect(screen.getByText("Project Training Job Evidence")).toBeInTheDocument();
    expect(screen.getByText("No project training job has been recorded yet. Train a model through the local gateway to attach worker dispatch evidence to this project.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /train new model/i }));
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith(
      expect.stringContaining(`/api/v1/workflows/${workflowSummary.workflowId}/ml/experiments/run`),
      expect.objectContaining({
        method: "POST",
        body: expect.stringContaining(`"projectId":"${dataScienceProject.projectId}"`)
      })
    ));
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith(
      `http://127.0.0.1:8088/api/v1/data-science-projects/${dataScienceProject.projectId}`,
      expect.objectContaining({ method: "GET" })
    ));
    await waitFor(() => expect(screen.getByText("job-training-ui-002")).toBeInTheDocument());
    expect(screen.getByText("exec-training-ui-002")).toBeInTheDocument();
    expect(screen.getAllByText("completed").length).toBeGreaterThan(0);

    fireEvent.click(screen.getByRole("button", { name: "Monitor" }));
    expect(screen.getByText("Project Job Ledger")).toBeInTheDocument();
    expect(screen.getByText("training")).toBeInTheDocument();
    expect(screen.getByText("experiment-training-ui-002")).toBeInTheDocument();
    expect(screen.getByText("exec-training-ui-002")).toBeInTheDocument();
  });

  it("polls gateway health and preserves stale values when refresh fails", async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    window.__JULIAFLOW_CONFIG__ = {
      gatewayBaseUrl: "http://127.0.0.1:8088",
      runtimeMode: "development"
    };
    let healthRequests = 0;
    const refreshedHealth = {
      ...localHealth,
      cpuThreadCount: 12,
      cpuWorkerConcurrency: 6,
      freeMemoryBytes: 8_000_000_000
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.endsWith("/health")) {
        healthRequests += 1;
        if (healthRequests === 1) return json(localHealth);
        if (healthRequests === 2) return json(refreshedHealth);
        throw new TypeError("gateway offline");
      }
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: executionRecords, count: executionRecords.length });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json(backendWorkflow);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [publishedDashboard] });
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [dataScienceProject], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: transformRuns, count: transformRuns.length });
      if (url.includes("/ml/experiments")) return json({ items: mlExperiments, count: mlExperiments.length });
      if (url.includes("/models")) return json({ items: modelRegistry, count: modelRegistry.length });
      if (url.includes("/deploy/packages")) return json({ items: deployPackages, count: deployPackages.length });
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await act(async () => {
      await vi.advanceTimersByTimeAsync(0);
    });
    expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" }));
    await act(async () => {
      await vi.advanceTimersByTimeAsync(5000);
    });
    expect(screen.getByText("12 threads")).toBeInTheDocument();

    await act(async () => {
      await vi.advanceTimersByTimeAsync(5000);
    });
    expect(screen.getByText("Stale")).toBeInTheDocument();
    expect(screen.getByText("12 threads")).toBeInTheDocument();
  });

  it("saves, runs, and monitors a workflow through the gateway lifecycle", async () => {
    window.__JULIAFLOW_CONFIG__ = {
      gatewayBaseUrl: "http://127.0.0.1:8088",
      runtimeMode: "development"
    };
    const nextExecution = {
      ...executionRecords[0],
      executionId: "exec-live-run-002",
      status: "accepted",
      createdAt: "2026-06-19T09:00:00Z",
      updatedAt: "2026-06-19T09:00:00Z",
      statusHistory: [{ status: "accepted", at: "2026-06-19T09:00:00Z", message: "Gateway accepted workflow run." }]
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input, init) => {
      const url = String(input);
      const method = init?.method ?? "GET";
      if (url.endsWith("/health")) return json(localHealth);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: [], count: 0 });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/execute`) && method === "POST") return json(nextExecution);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`) && method === "PUT") {
        return json({ workflowId: workflowSummary.workflowId, name: workflowSummary.name, version: "1.0.1", status: "updated" });
      }
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json(localWorkflow);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [publishedDashboard] });
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [dataScienceProject], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: transformRuns, count: transformRuns.length });
      if (url.includes("/ml/experiments")) return json({ items: mlExperiments, count: mlExperiments.length });
      if (url.includes("/models")) return json({ items: modelRegistry, count: modelRegistry.length });
      if (url.includes("/deploy/packages")) return json({ items: deployPackages, count: deployPackages.length });
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    fireEvent.click(screen.getByRole("button", { name: /save workflow/i }));
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith(expect.stringContaining(`/api/v1/workflows/${workflowSummary.workflowId}`), expect.objectContaining({ method: "PUT" })));
    expect(screen.getByText("Gateway action completed locally.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /run workflow/i }));
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith(expect.stringContaining(`/api/v1/workflows/${workflowSummary.workflowId}/execute`), expect.objectContaining({ method: "POST" })));

    fireEvent.click(screen.getByRole("button", { name: "Monitor" }));
    await waitFor(() => expect(screen.getAllByText("exec-live-run-002").length).toBeGreaterThan(0));
    expect(fetchMock).toHaveBeenCalledWith(expect.stringContaining(`/api/v1/workflows/${workflowSummary.workflowId}/execute`), expect.objectContaining({ method: "POST" }));
  });

  it("does not send auth headers when auth is disabled", async () => {
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "http://127.0.0.1:8088", runtimeMode: "development" };
    const disabledHealth = { ...localHealth, authMode: "disabled", authDevFallback: false };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.endsWith("/health")) return json(disabledHealth);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: executionRecords, count: executionRecords.length });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json({ ...workflowSummary, nodes: [], connections: [], flowVariables: [] });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [publishedDashboard] });
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [dataScienceProject], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: transformRuns, count: transformRuns.length });
      if (url.includes("/ml/experiments")) return json({ items: mlExperiments, count: mlExperiments.length });
      if (url.includes("/models")) return json({ items: modelRegistry, count: modelRegistry.length });
      if (url.includes("/deploy/packages")) return json({ items: deployPackages, count: deployPackages.length });
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    const healthCall = fetchMock.mock.calls.find(([input]) => String(input).endsWith("/health"));
    expect(headerValue(healthCall?.[1], "authorization")).toBeNull();
    expect(headerValue(healthCall?.[1], "x-juliaflow-workspace")).toBeNull();
  });

  it("does not silently substitute demo data in release mode when the gateway is absent", () => {
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "", runtimeMode: "release" };

    render(<App />);

    expect(screen.getByLabelText("Release mode unavailable")).toHaveTextContent("No gatewayBaseUrl is configured");
    fireEvent.click(screen.getByRole("button", { name: "Data" }));
    fireEvent.click(screen.getByRole("button", { name: /re-profile active dataset/i }));
    expect(screen.getByText("Release mode requires the local gateway before this action can run.")).toBeInTheDocument();
    expect(screen.queryByText("Synthetic csv profile loaded from fixture.")).not.toBeInTheDocument();
  });

  it("reports required-mode auth failures instead of falling back", async () => {
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "http://127.0.0.1:8088", runtimeMode: "release" };
    vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.endsWith("/health")) return json({ error: "auth token is required" }, 401);
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(screen.getByLabelText("Release mode unavailable")).toHaveTextContent("auth token is required"));
    expect(screen.getByLabelText("Release mode unavailable")).toHaveTextContent("Configure gatewayAuthToken or oidcAccessToken");
    expect(screen.queryByText("Gateway unavailable. Running deterministic local demo fallback.")).not.toBeInTheDocument();
  });

  it("keeps empty backend lists empty in local-appliance mode", async () => {
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "http://127.0.0.1:8088", runtimeMode: "local-appliance" };
    const health = {
      ...localHealth,
      runtime: {
        mode: "local-appliance",
        fixtureProvenance: "backend",
        fixtureSubstitutionAllowed: false,
        unavailable: []
      },
      runtimeMode: "local-appliance",
      fixtureProvenance: "backend",
      fixtureSubstitutionAllowed: false,
      unavailable: []
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.endsWith("/health")) return json(health);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: [], count: 0 });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json(backendWorkflow);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [] });
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [dataScienceProject], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: [], count: 0 });
      if (url.includes("/ml/experiments")) return json({ items: [], count: 0 });
      if (url.includes("/models")) return json({ items: [], count: 0 });
      if (url.includes("/deploy/packages")) return json({ items: [], count: 0 });
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", workflowId: workflowSummary.workflowId, name: "Empty", version: 1, publishedAt: "2026-06-18T00:00:00Z", visibility: "workspace", binding: { outletNodeId: "dashboard", datasetKey: "empty", refreshMode: "manual" }, charts: [], datasets: {} });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    fireEvent.click(screen.getByRole("button", { name: "Transform" }));
    expect(screen.queryByText("transform-2026-06-17-001")).not.toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Monitor" }));
    expect(screen.getByText("No backend execution records are available for this workspace yet. Run the workflow from Explorer after the local gateway is ready.")).toBeInTheDocument();
    expect(screen.queryByText("exec-local-churn-001")).not.toBeInTheDocument();
    expect(screen.getByText("No executed-run explainability evidence is attached to the latest execution.")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "ML Studio" }));
    expect(screen.getByText("No backend ML experiment records are available for this workspace yet. Train a model after the local gateway is ready, then this screen will show algorithm settings, metrics, feature importance, hardware evidence, and reproducibility details.")).toBeInTheDocument();
    expect(screen.queryByText("experiment-local-churn-001")).not.toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Visualize" }));
    fireEvent.click(screen.getByRole("tab", { name: "Dashboard" }));
    expect(screen.getByText("No artifact-backed dashboard rows are available for this published dashboard. Run the workflow and publish a dashboard snapshot with persisted dataset rows.")).toBeInTheDocument();
    expect(screen.queryByText("C-1001")).not.toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Models" }));
    expect(screen.getByText("No backend model registry records are available for this workspace yet. Register a model after training completes.")).toBeInTheDocument();
    expect(screen.queryByText("model-local-churn-001")).not.toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Deploy" }));
    expect(screen.getByText("No backend deploy package records are available yet. Package a local endpoint after a model is registered.")).toBeInTheDocument();
    expect(screen.getByText("No local endpoint packaged")).toBeInTheDocument();
    expect(screen.getAllByText("No registered model is available.").length).toBeGreaterThan(0);
    expect(screen.getByRole("button", { name: /package local endpoint/i })).toBeDisabled();
    fireEvent.click(screen.getByRole("button", { name: "Settings" }));
    expect(screen.getByRole("heading", { name: "Settings" })).toBeInTheDocument();
    expect(screen.queryByLabelText("Release mode unavailable")).not.toBeInTheDocument();
  });

  it("normalizes relative fixture data sources before local-appliance imports", async () => {
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "http://127.0.0.1:8088", runtimeMode: "local-appliance" };
    let importBody: Record<string, unknown> | undefined;
    const health = {
      ...localHealth,
      runtime: {
        mode: "local-appliance",
        fixtureProvenance: "backend",
        fixtureSubstitutionAllowed: false,
        unavailable: []
      },
      runtimeMode: "local-appliance",
      fixtureProvenance: "backend",
      fixtureSubstitutionAllowed: false,
      unavailable: []
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input, init) => {
      const url = String(input);
      if (url.endsWith("/health")) return json(health);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: [], count: 0 });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json(backendWorkflow);
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}/dashboards`)) return json({ items: [publishedDashboard] });
      if (url.endsWith("/api/v1/data-science-projects")) return json({ items: [dataScienceProject], count: 1 });
      if (url.includes("/transforms/history")) return json({ items: [], count: 0 });
      if (url.includes("/ml/experiments")) return json({ items: [], count: 0 });
      if (url.includes("/models")) return json({ items: [], count: 0 });
      if (url.includes("/deploy/packages")) return json({ items: [], count: 0 });
      if (url.endsWith("/api/v1/local-data/import")) {
        importBody = JSON.parse(String(init?.body));
        return json({ status: "profiled", profile: dataProfile, project: dataScienceProject });
      }
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    fireEvent.click(screen.getByRole("button", { name: "Data" }));
    fireEvent.click(screen.getByRole("button", { name: /import local data/i }));
    await waitFor(() => expect(importBody?.sourceUri).toBe("local://data/raw/customer-churn-local.csv"));
    expect(importBody?.projectId).toBe(dataScienceProject.projectId);
  });

  it("reports incomplete workflow metadata in local-appliance mode instead of rendering fixture canvas state", async () => {
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "http://127.0.0.1:8088", runtimeMode: "local-appliance" };
    const health = {
      ...localHealth,
      runtime: {
        mode: "local-appliance",
        fixtureProvenance: "backend",
        fixtureSubstitutionAllowed: false,
        unavailable: []
      },
      runtimeMode: "local-appliance",
      fixtureProvenance: "backend",
      fixtureSubstitutionAllowed: false,
      unavailable: []
    };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url.endsWith("/health")) return json(health);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith("/api/v1/executions")) return json({ items: [], count: 0 });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json({ ...workflowSummary, nodes: [], connections: [], flowVariables: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    await waitFor(() => expect(screen.getByLabelText("Release mode unavailable")).toHaveTextContent("incomplete workflow metadata"));
    expect(screen.getByLabelText("Release mode unavailable")).toHaveTextContent("Re-import or save the workflow");
    fireEvent.click(screen.getByRole("button", { name: "Transform" }));
    expect(screen.getByText("Workflow metadata is unavailable. Re-import or save the workflow through the local gateway before rendering the live transform canvas.")).toBeInTheDocument();
    expect(screen.queryByText("churn.csv")).not.toBeInTheDocument();
  });
});

function json(payload: unknown, status = 200) {
  return Promise.resolve(
    new Response(JSON.stringify(payload), {
      status,
      headers: { "Content-Type": "application/json" }
    })
  );
}

function headerValue(init: RequestInit | undefined, key: string): string | null {
  return new Headers(init?.headers).get(key);
}
