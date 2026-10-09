import { expect, test, type Page } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { join } from "node:path";
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
  transformRuns,
  visualizeExports,
  workflowId,
  workflowSummary
} from "../../apps/frontend/src/fixtures/local-fixtures";

const consoleErrorsByTest = new WeakMap<Page, string[]>();

test.beforeEach(async ({ page }) => {
  const consoleErrors: string[] = [];
  consoleErrorsByTest.set(page, consoleErrors);
  page.on("console", (message) => {
    if (message.type() === "error") {
      consoleErrors.push(message.text());
    }
  });
  page.on("pageerror", (error) => consoleErrors.push(error.message));
  await page.addInitScript(() => {
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "http://127.0.0.1:8088" };
  });
  await mockGateway(page);
  await page.goto("/");
  await expect(page.getByRole("status", { name: /100% local status/i })).toContainText("100% Local");
  await page.getByRole("button", { name: "Data", exact: true }).click();
  await page.getByLabel("Dataset ID", { exact: true }).fill(dataProfile.datasetId);
  await page.getByLabel("Approved local CSV path", { exact: true }).fill(dataProfile.sourceUri);
  await page.getByRole("button", { name: "Import Local Data", exact: true }).click();
  await expect(page.getByText("Gateway action completed locally.")).toBeVisible();
  await page.getByRole("button", { name: "Explorer", exact: true }).click();
});

test.afterEach(async ({ page }) => {
  const majorErrors = (consoleErrorsByTest.get(page) ?? []).filter((entry) => {
    return !entry.includes("favicon") && !entry.includes("ResizeObserver loop");
  });
  expect(majorErrors).toEqual([]);
});

test("sidebar navigation reaches every redesigned local-only route", async ({ page }) => {
  await expect(page.getByRole("heading", { name: "Local Workspace Overview" })).toBeVisible();
  await expect(page.getByText("Privacy & Security (Local-First)")).toBeVisible();

  await page.getByRole("button", { name: "Data" }).click();
  await expect(page.getByRole("heading", { name: "Data", exact: true })).toBeVisible();
  await expect(page.getByText("C-1001")).toBeVisible();
  await expect(page.getByText("99.8% complete")).toBeVisible();

  await page.getByRole("button", { name: "Transform" }).click();
  await expect(page.getByRole("heading", { name: "Transform", exact: true })).toBeVisible();
  await expect(page.getByText("Visual Transform Pipeline")).toBeVisible();
  await expect(page.getByText("transform-2026-06-17-001")).toBeVisible();

  await page.getByRole("button", { name: "ML Studio" }).click();
  await expect(page.getByRole("heading", { name: "ML Studio" })).toBeVisible();
  await expect(page.getByText("Experiment Tracker")).toBeVisible();
  await expect(page.getByText("0.912")).toBeVisible();

  await page.getByRole("button", { name: "Models" }).click();
  await expect(page.getByRole("heading", { name: "Models", exact: true })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Model Registry" })).toBeVisible();
  await expect(page.getByText("Artifacts (Stored on Disk)")).toBeVisible();

  await page.getByRole("button", { name: "Visualize" }).click();
  await expect(page.getByRole("heading", { name: "Visualize" })).toBeVisible();
  await expect(page.getByText("Dashboard Builder")).toBeVisible();
  await expect(page.getByText("Local Save And Export Actions")).toBeVisible();

  await page.getByRole("button", { name: "Deploy" }).click();
  await expect(page.getByRole("heading", { name: "Deploy", exact: true })).toBeVisible();
  await expect(page.getByText("Endpoint Monitoring")).toBeVisible();
  await expect(page.getByText("Generated Julia API Code")).toBeVisible();

  await page.getByRole("button", { name: "Settings" }).click();
  await expect(page.getByRole("heading", { name: "Settings" })).toBeVisible();
  await expect(page.getByText("Security And API Keys")).toBeVisible();
  await expect(page.getByText("Backup And Restore")).toBeVisible();
});

test("backend-backed local actions use mocked gateway fixtures", async ({ page }) => {
  await page.getByRole("button", { name: "Data" }).click();
  await page.getByLabel("Dataset ID", { exact: true }).fill(dataProfile.datasetId);
  await page.getByLabel("Approved local CSV path", { exact: true }).fill(dataProfile.sourceUri);
  await page.getByRole("button", { name: /import local data/i }).click();
  await expect(page.getByText("Gateway action completed locally.")).toBeVisible();

  await page.getByRole("button", { name: "Transform" }).click();
  await page.getByRole("button", { name: /run transform/i }).click();
  await expect(page.getByText("Gateway action completed locally.")).toBeVisible();

  await page.getByRole("button", { name: "ML Studio" }).click();
  await page.getByRole("button", { name: /train new model/i }).click();
  await expect(page.getByText("Gateway action completed locally.")).toBeVisible();

  await page.getByRole("button", { name: "Models" }).click();
  await page.getByRole("button", { name: /register model/i }).click();
  await expect(page.getByText("Gateway action completed locally.")).toBeVisible();

  await page.getByRole("button", { name: "Visualize" }).click();
  await page.getByRole("button", { name: /save local checkpoint/i }).click();
  await expect(page.getByText("Gateway action completed locally.")).toBeVisible();

  await page.getByRole("button", { name: "Deploy" }).click();
  await page.getByRole("button", { name: /package local endpoint/i }).click();
  await expect(page.getByText("Gateway action completed locally.")).toBeVisible();
});

test("dataset onboarding and keyboard accessibility persist through the project aggregate", async ({ page }) => {
  await page.getByRole("button", { name: "Data" }).click();
  await expect(page.getByRole("heading", { name: "Local Dataset Wizard" })).toBeVisible();
  await page.getByLabel("Dataset role").selectOption("validation");
  await expect(page.getByText("validation", { exact: true }).first()).toBeVisible();
  await page.getByLabel("Validation strategy").selectOption("grouped");
  await page.getByRole("button", { name: "Lock Wizard Split" }).click();
  await expect(page.getByRole("button", { name: "Final Test Locked" }).first()).toBeDisabled();
  await expect(page.locator(".source-row:disabled")).not.toHaveCount(0);

  const tableTab = page.getByRole("tab", { name: "table" });
  await tableTab.focus();
  await tableTab.press("ArrowRight");
  await expect(page.getByRole("tab", { name: "schema" })).toHaveAttribute("aria-selected", "true");

  await page.getByRole("button", { name: "Transform", exact: true }).click();
  const transformOutline = page.getByRole("list", { name: "Keyboard-accessible transform nodes" });
  const firstNode = transformOutline.getByRole("listitem").first();
  await firstNode.focus();
  await firstNode.press("Enter");
  await expect(firstNode).toHaveAttribute("aria-pressed", "true");
});

test("dialogs trap focus, close with Escape, and restore their trigger", async ({ page }, testInfo) => {
  const newProject = page.getByRole("button", { name: "+ New Project" });
  await newProject.focus();
  await newProject.click();
  const projectDialog = page.getByRole("dialog", { name: "Create New Project" });
  await expect(projectDialog).toBeVisible();
  await expect(projectDialog.locator(":focus")).toHaveCount(1);
  await projectDialog.press("Escape");
  await expect(projectDialog).toBeHidden();
  await expect(newProject).toBeFocused();

  if (testInfo.project.name === "chromium-desktop") {
    const helpTrigger = page.getByRole("button", { name: "Open help" });
    await helpTrigger.click();
    const helpDialog = page.getByRole("dialog", { name: "Workspace Help" });
    await expect(helpDialog).toBeVisible();
    await helpDialog.press("Escape");
    await expect(helpTrigger).toBeFocused();
  }
});

test("Explorer Data Transform mock parity screenshots and interactions", async ({ page }, testInfo) => {
  const screenshotDir = join("artifacts", "mock-parity", testInfo.project.name);
  mkdirSync(screenshotDir, { recursive: true });

  await expect(page.getByRole("heading", { name: "Local Workspace Overview" })).toBeVisible();
  await expect(page.locator('[data-chart-id="workspace-cpu-trend"] .svg-container')).toBeVisible({ timeout: 10_000 });
  await expect(page.getByText("Stale local evidence")).toBeVisible();
  await page.screenshot({ path: join(screenshotDir, "explorer.png"), fullPage: true });

  await page.getByRole("button", { name: "Data" }).click();
  await expect(page.getByRole("heading", { name: "Data", exact: true })).toBeVisible();
  await expect(page.locator('[data-chart-id="data-churn-balance"] .svg-container')).toBeVisible({ timeout: 10_000 });
  await page.getByRole("tab", { name: "filters" }).click();
  await page.getByRole("combobox", { name: "Value", exact: true }).selectOption("monthly");
  await page.getByRole("tab", { name: "table" }).click();
  await expect(page.getByText("C-1001")).toBeVisible();
  await expect(page.getByText("C-1002")).not.toBeVisible();
  await page.getByRole("tab", { name: "sampling" }).click();
  await page.getByLabel("Preview sample").selectOption("2");
  await page.getByRole("tab", { name: "table" }).click();
  await expect(page.getByText("C-1003")).not.toBeVisible();
  await page.screenshot({ path: join(screenshotDir, "data.png"), fullPage: true });

  await page.getByRole("button", { name: "Transform", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Transform", exact: true })).toBeVisible();
  await expect(page.locator('[data-chart-id="transform-rows-transform-2026-06-17-001"] .svg-container')).toBeVisible({ timeout: 10_000 });
  await page.getByText("Feature Engineering").first().click();
  const transformSettings = page.locator(".right-panel").filter({ hasText: "Transform Settings" });
  await expect(transformSettings.getByText("transform.feature_engineer")).toBeVisible();
  await transformSettings.getByLabel("Output column prefix").fill("encoded_features");
  await expect(page.getByText("Unsaved canvas edits detected")).toBeVisible();
  await page.getByRole("button", { name: "Validate" }).click();
  await expect(page.getByText("Pipeline is locally valid")).toBeVisible();
  await page.screenshot({ path: join(screenshotDir, "transform.png"), fullPage: true });
});

async function mockGateway(page: Page) {
  let project = structuredClone(dataScienceProject);
  await page.route("http://127.0.0.1:8088/**", async (route) => {
    const request = route.request();
    const url = new URL(request.url());
    const path = url.pathname;
    const method = request.method();

    if (path === "/health") return route.fulfill(json(localHealth));
    if (path === "/api/v1/workflows") return route.fulfill(json({ items: [workflowSummary] }));
    if (path === "/api/v1/executions") return route.fulfill(json({ items: executionRecords }));
    if (path === "/api/v1/data-science-projects" && method === "GET") return route.fulfill(json({ items: [project], count: 1 }));
    if (path === `/api/v1/data-science-projects/${project.projectId}` && method === "GET") return route.fulfill(json(project));
    if (path === `/api/v1/data-science-projects/${project.projectId}` && method === "PUT") {
      project = { ...project, ...(request.postDataJSON() as object), updatedAt: new Date().toISOString() };
      return route.fulfill(json(project));
    }
    if (path === `/api/v1/workflows/${workflowId}`) return route.fulfill(json(localWorkflow));
    if (path === `/api/v1/workflows/${workflowId}/dashboards`) return route.fulfill(json({ items: [publishedDashboard] }));
    if (path === `/api/v1/workflows/${workflowId}/transforms/history`) return route.fulfill(json({ items: transformRuns, count: transformRuns.length }));
    if (path === `/api/v1/workflows/${workflowId}/transforms/run` && method === "POST") {
      return route.fulfill(json({ status: "accepted", execution: { executionId: "exec-transform", workflowId, workflowVersion: "1.0.0", checkpointTag: transformRuns[0].checkpointTag, status: "completed", mode: "batch", plan: [], stages: [], nodeCount: 5, connectionCount: 5, createdAt: transformRuns[0].startedAt, updatedAt: transformRuns[0].finishedAt, statusHistory: [] }, run: transformRuns[0] }));
    }
    if (path === `/api/v1/workflows/${workflowId}/ml/experiments`) return route.fulfill(json({ items: mlExperiments, count: mlExperiments.length }));
    if (path === `/api/v1/workflows/${workflowId}/ml/experiments/run` && method === "POST") {
      return route.fulfill(json({ status: "accepted", execution: { executionId: "exec-ml", workflowId, workflowVersion: "1.0.0", checkpointTag: mlExperiments[0].checkpointTag, status: "completed", mode: "batch", plan: [], stages: [], nodeCount: 5, connectionCount: 5, createdAt: mlExperiments[0].startedAt, updatedAt: mlExperiments[0].finishedAt, statusHistory: [] }, experiment: mlExperiments[0] }));
    }
    if (path === `/api/v1/workflows/${workflowId}/models`) return route.fulfill(json({ items: modelRegistry, count: modelRegistry.length }));
    if (path === `/api/v1/workflows/${workflowId}/models/register` && method === "POST") return route.fulfill(json({ status: "registered", model: modelRegistry[0] }));
    if (path === `/api/v1/workflows/${workflowId}/deploy/packages`) return route.fulfill(json({ items: deployPackages, count: deployPackages.length }));
    if (path === `/api/v1/workflows/${workflowId}/deploy/package` && method === "POST") return route.fulfill(json({ status: "packaged", package: deployPackages[0] }));
    if (path === `/api/v1/workflows/${workflowId}/dashboards/${dashboardId}/checkpoint-export` && method === "POST") {
      return route.fulfill(json({ status: "exported", export: visualizeExports[0], checkpoint: checkpoints[0], dashboard: publishedDashboard, bundle: { bundleId: "bundle-churn-v3", createdAt: "2026-06-17T10:26:00Z", schemaVersion: "juliaflow.reproducibility.v1", workflow: localWorkflow, checkpoint: checkpoints[0], dataReferences: [], datasetCards: [], packageEnvironment: {}, runtimeConfig: {}, randomSeeds: {}, modelArtifact: { modelId: "churn_model_v1", artifactRef: "data/models/churn_model_v1.jls", checksumSha256: "c".repeat(64) }, metrics: {}, evaluationOutputs: {}, explainabilityOutputs: localHealth.explainabilityEvidence.explanation, notes: "local fixture", localOnly: true, bundleChecksumSha256: "3".repeat(64) } }));
    }
    if (path === "/api/v1/local-data/import" && method === "POST") return route.fulfill(json({ status: "profiled", profile: dataProfile }));
    if (path === `/api/v1/dashboards/${dashboardId}`) return route.fulfill(json(publishedDashboard));
    return route.fulfill(json({}));
  });
}

function json(body: unknown) {
  return {
    status: 200,
    contentType: "application/json",
    body: JSON.stringify(body)
  };
}
