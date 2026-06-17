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
import { dataProfile, deployPackages, mlExperiments, modelRegistry, transformRuns, workflowSummary } from "./fixtures/local-fixtures";
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
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "" };
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

    fireEvent.click(screen.getByRole("button", { name: "Deploy" }));
    expect(screen.getByRole("heading", { name: "Deploy" })).toBeInTheDocument();
    expect(screen.getByText("Generated Julia API Code")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Settings" }));
    expect(screen.getByRole("heading", { name: "Settings" })).toBeInTheDocument();
    expect(screen.getByText("Workspace Path Controls")).toBeInTheDocument();
    expect(screen.getByText("Privacy, Security, And API Keys")).toBeInTheDocument();
    expect(screen.getByLabelText("CPU thread limit")).toBeInTheDocument();
    expect(screen.getByLabelText("Backup retention")).toBeInTheDocument();
  });

  it("runs redesigned actions through deterministic demo fallback without a gateway", () => {
    render(<App />);

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

    fireEvent.click(screen.getByRole("button", { name: "Settings" }));
    fireEvent.click(screen.getByRole("button", { name: /create local snapshot/i }));
    expect(screen.getByRole("status", { name: /action feedback/i })).toHaveTextContent("Synthetic local backup snapshot prepared from fixture evidence.");
  });

  it("uses runtime gateway config before falling back to fixtures", async () => {
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "http://127.0.0.1:8088" };
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(async (input, init) => {
      const url = String(input);
      const method = init?.method ?? "GET";
      if (url.endsWith("/health")) return json(localHealth);
      if (url.endsWith("/api/v1/workflows")) return json({ items: [workflowSummary] });
      if (url.endsWith(`/api/v1/workflows/${workflowSummary.workflowId}`)) return json({ ...workflowSummary, nodes: [], connections: [], flowVariables: [] });
      if (url.includes("/transforms/history")) return json({ items: transformRuns, count: transformRuns.length });
      if (url.includes("/ml/experiments")) return json({ items: mlExperiments, count: mlExperiments.length });
      if (url.includes("/models/register") && method === "POST") return json({ status: "registered", model: modelRegistry[0] });
      if (url.includes("/models")) return json({ items: modelRegistry, count: modelRegistry.length });
      if (url.includes("/deploy/packages")) return json({ items: deployPackages, count: deployPackages.length });
      if (url.endsWith("/api/v1/local-backups") && method === "POST") {
        return json({
          status: "ok",
          backup: {
            backupId: "backup-unit-local",
            createdAt: "2026-06-17T10:30:00Z",
            schemaVersion: "juliaflow.backup.v1",
            localProfile: localHealth.localProfile,
            dataEstateRoot: localHealth.dataEstateRoot,
            backupChecksumSha256: "4".repeat(64)
          }
        });
      }
      if (url.includes("/dashboards/")) return json({ dashboardId: "dashboard-local-churn", charts: [], rows: [] });
      return json({});
    });

    render(<App />);

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8088/health", expect.objectContaining({ method: "GET" })));
    fireEvent.click(screen.getByRole("button", { name: "Models" }));
    fireEvent.click(screen.getByRole("button", { name: /register model/i }));
    await waitFor(() => expect(screen.getByText("Gateway action completed locally.")).toBeInTheDocument());
    expect(fetchMock).toHaveBeenCalledWith(expect.stringContaining("/models/register"), expect.objectContaining({ method: "POST" }));

    fireEvent.click(screen.getByRole("button", { name: "Settings" }));
    fireEvent.click(screen.getByRole("button", { name: /create local snapshot/i }));
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith(expect.stringContaining("/api/v1/local-backups"), expect.objectContaining({ method: "POST" })));
  });
});

function json(payload: unknown) {
  return Promise.resolve(
    new Response(JSON.stringify(payload), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    })
  );
}
