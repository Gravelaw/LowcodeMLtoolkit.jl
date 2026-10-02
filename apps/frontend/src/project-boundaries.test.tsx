import { act, cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import App from "./App";
import { DataView } from "./views/DataView";
import { canEditDisplayedDataset } from "./dataset-edit-boundary";
import type { AppData } from "./types";
import * as fixtures from "./fixtures/local-fixtures";

function viewData(): AppData {
  return {
    ...fixtures,
    mode: "demo", runtimeMode: "demo", runtime: fixtures.localHealth.runtime,
    unavailable: [], health: fixtures.localHealth, healthStale: false,
    workflow: fixtures.localWorkflow, dashboard: fixtures.publishedDashboard,
    dataProfiles: [fixtures.dataProfile, fixtures.superstoreDataProfile],
    executions: fixtures.executionRecords
  } as unknown as AppData;
}

function mockGateway(project = fixtures.dataScienceProject) {
  return vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
    const url = String(input);
    let payload: unknown = { items: [] };
    if (url.endsWith("/health")) payload = {
      ...fixtures.localHealth,
      workspaceSummary: { ...fixtures.localHealth.workspaceSummary, artifacts: [] }
    };
    else if (url.endsWith("/api/v1/workflows")) payload = { items: [fixtures.workflowSummary] };
    else if (url.endsWith(`/api/v1/workflows/${fixtures.workflowSummary.workflowId}`)) payload = {
      ...fixtures.localWorkflow,
      graph: {
        revision: fixtures.workflowSummary.graphRevision,
        nodeLayouts: fixtures.localWorkflow.nodes.map((node, index) => ({
          nodeId: node.id, x: 36 + index * 192, y: 44, width: 176
        }))
      }
    };
    else if (url.endsWith("/api/v1/data-science-projects")) payload = { items: [project] };
    else if (url.includes("/ml/experiments")) payload = { items: fixtures.mlExperiments };
    return new Response(JSON.stringify(payload), { status: 200, headers: { "content-type": "application/json" } });
  });
}

beforeEach(() => {
  window.history.pushState({}, "", "/");
  window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "", runtimeMode: "demo" };
});
afterEach(() => { cleanup(); vi.restoreAllMocks(); });

describe("dataset edit identity", () => {
  it("rejects stale project and displayed dataset identities but allows matching edits", () => {
    const data = viewData();
    const identity = { projectId: data.dataScienceProject.projectId, datasetId: data.dataProfile.datasetId };
    expect(canEditDisplayedDataset(data, identity)).toBe(true);
    expect(canEditDisplayedDataset(data, { ...identity, projectId: "stale-project" })).toBe(false);
    expect(canEditDisplayedDataset({ ...data, dataProfile: fixtures.superstoreDataProfile }, identity)).toBe(false);
    expect(canEditDisplayedDataset({ ...data, mode: "unavailable" }, identity)).toBe(false);
  });

  it("guards disabled split handlers when the displayed dataset has no matching project dataset", () => {
    const data = viewData();
    data.dataScienceProject = { ...data.dataScienceProject, datasets: [] };
    const update = vi.fn();
    render(<DataView data={data} onImport={vi.fn()} onSelectProfile={vi.fn()} onProjectUpdate={update} />);
    const strategy = screen.getByLabelText("Validation strategy") as HTMLSelectElement;
    expect(strategy.disabled).toBe(true);
    fireEvent.change(strategy, { target: { value: "grouped" } });
    expect(update).not.toHaveBeenCalled();
  });

  it("passes the displayed project and dataset identity for a matching schema edit", () => {
    const data = viewData();
    const update = vi.fn();
    render(<DataView data={data} onImport={vi.fn()} onSelectProfile={vi.fn()} onProjectUpdate={update} />);
    fireEvent.click(screen.getByRole("tab", { name: "schema" }));
    fireEvent.change(screen.getByLabelText("Column role for monthly_charges"), { target: { value: "target" } });
    expect(update).toHaveBeenCalledWith(expect.objectContaining({ schemaContracts: expect.any(Array) }), {
      projectId: data.dataScienceProject.projectId, datasetId: data.dataProfile.datasetId
    });
  });
});

describe("historical project evidence", () => {
  it.each([
    ["transform", "Project Transform Evidence"],
    ["visualize", "Project Statistical Analysis Evidence"],
    ["ml-studio", "Project Validation Workflow"],
    ["deploy", "Deployment Pipeline"],
    ["models", "Model Registry"],
    ["monitor", "Project Job Ledger"]
  ])("renders %s without entering the route error boundary", async (route, card) => {
    const project = {
      ...fixtures.dataScienceProject,
      transformFitApplyRecords: [{}], statisticalAnalysisRuns: [{}, {}], predictionExports: [{}],
      projectJobs: ["transform_fit_apply", "training", "deploy_package", "model_lifecycle"].flatMap((jobType) => [
        { jobType }, { jobType }
      ])
    } as typeof fixtures.dataScienceProject;
    window.history.pushState({}, "", `/${route}`);
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "http://127.0.0.1:8088", runtimeMode: "development" };
    mockGateway(project);
    await act(async () => { render(<App />); });
    await waitFor(() => expect(screen.getByText(card)).toBeTruthy());
    await waitFor(() => expect(screen.queryByText(/This module could not render/)).toBeNull());
  });

  it("keeps empty live appliance inventory empty", async () => {
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "http://127.0.0.1:8088", runtimeMode: "local-appliance" };
    const fetch = mockGateway();
    await act(async () => { render(<App />); });
    await waitFor(() => expect(fetch.mock.calls.some(([input]) => String(input).endsWith("/api/v1/data-science-projects"))).toBe(true));
    await waitFor(() => expect(screen.getByRole("heading", { name: "Local Workspace Overview" })).toBeTruthy());
    for (const file of fixtures.projectFiles) expect(screen.queryByText(file.path)).toBeNull();
  });
});
