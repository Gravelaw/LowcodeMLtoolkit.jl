import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import * as matchers from "@testing-library/jest-dom/matchers";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import App from "./App";
import {
  buildCanvasNodeLayouts,
  buildCheckpointRailItems,
  buildExecutionRailItems,
  buildWorkflowFromGateway,
  formatPortSummary,
  portTypeCounts
} from "./sample-workflow";
import { dataProfile, deployPackages, executionRecords, mlExperiments, modelRegistry, transformRuns, workflowSummary } from "./fixtures/local-fixtures";
import { localHealth } from "./fixtures/local-fixtures";

expect.extend(matchers);

describe("sample workflow helpers", () => {
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
  });

  afterEach(() => {
    cleanup();
    vi.restoreAllMocks();
    window.__JULIAFLOW_CONFIG__ = undefined;
  });

  it("renders the mock-aligned local shell and navigates routes", () => {
    render(<App />);

    expect(screen.getByRole("status", { name: /100% local status/i })).toHaveTextContent("100% Local");
    expect(screen.getByRole("heading", { name: /local workspace overview/i })).toBeInTheDocument();
    expect(screen.getByText("Privacy & Security (Local-First)")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Data" }));
    expect(screen.getByRole("heading", { name: "Data" })).toBeInTheDocument();
    expect(screen.getByText("C-1001")).toBeInTheDocument();
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
  });

  it("runs redesigned actions through deterministic demo fallback without a gateway", () => {
    render(<App />);

    fireEvent.click(screen.getByRole("button", { name: /save workflow/i }));
    expect(screen.getByText("Workflow save stayed in deterministic demo mode.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /run workflow/i }));
    expect(screen.getByText("Workflow run stayed in deterministic demo mode.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Data" }));
    fireEvent.click(screen.getByRole("button", { name: /import local data/i }));
    expect(screen.getByText("Synthetic local profile loaded from fixture.")).toBeInTheDocument();

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
    fireEvent.click(screen.getByRole("button", { name: /save local checkpoint/i }));
    expect(screen.getByText("Synthetic dashboard checkpoint export displayed.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Deploy" }));
    fireEvent.click(screen.getByRole("button", { name: /package local endpoint/i }));
    expect(screen.getByText("Synthetic local deploy package displayed.")).toBeInTheDocument();
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
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json({ ...workflowSummary, nodes: [], connections: [], flowVariables: [] });
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
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json({ ...workflowSummary, nodes: [], connections: [], flowVariables: [] });
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
    fireEvent.click(screen.getByRole("button", { name: /import local data/i }));
    expect(screen.getByText("Release mode requires the local gateway before this action can run.")).toBeInTheDocument();
    expect(screen.queryByText("Synthetic local profile loaded from fixture.")).not.toBeInTheDocument();
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
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json({ ...workflowSummary, nodes: [], connections: [], flowVariables: [] });
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
    fireEvent.click(screen.getByRole("button", { name: "Visualize" }));
    expect(screen.getByText("No artifact-backed dashboard rows are available for this published dashboard. Run the workflow and publish a dashboard snapshot with persisted dataset rows.")).toBeInTheDocument();
    expect(screen.queryByText("C-1001")).not.toBeInTheDocument();
    expect(screen.queryByLabelText("Release mode unavailable")).not.toBeInTheDocument();
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
