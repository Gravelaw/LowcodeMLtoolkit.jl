import { expect, test, type Page } from "@playwright/test";
import {
  checkpoints,
  dashboardId,
  localHealth,
  localWorkflow,
  publishedDashboard,
  visualizeExports,
  workflowId,
  workflowSummary
} from "../../apps/frontend/src/fixtures/local-fixtures";

const irisProfile = {
  datasetId: "iris-local",
  sourceUri: "data/raw/iris.csv",
  sourceFormat: "csv",
  targetZone: "raw",
  artifactRef: "data/raw/iris-local.arrow",
  artifactFormats: ["arrow_ipc", "parquet"],
  checksumSha256: "7".repeat(64),
  rowCount: 150,
  schemaSummary: [
    { name: "sepal_length", type: "Float64" },
    { name: "sepal_width", type: "Float64" },
    { name: "petal_length", type: "Float64" },
    { name: "petal_width", type: "Float64" },
    { name: "species", type: "String" }
  ],
  profileSummary: [
    { name: "sepal_length", type: "Float64", quality: "150 complete local rows" },
    { name: "sepal_width", type: "Float64", quality: "150 complete local rows" },
    { name: "petal_length", type: "Float64", quality: "target-correlated numeric feature" },
    { name: "species", type: "String", quality: "3 local categories" }
  ],
  manifestReady: true,
  manifestChecksums: localHealth.dataEstateManifestChecksums,
  duckdbStatus: "ready",
  importedAt: "2026-06-17T19:20:00Z",
  localOnly: true
};

const irisTransform = {
  runId: "transform-iris-linear-001",
  workflowId,
  workflowVersion: "1.0.0",
  checkpointTag: "cp/iris-features-linear",
  status: "completed",
  startedAt: "2026-06-17T19:21:00Z",
  finishedAt: "2026-06-17T19:21:05Z",
  stageCount: 3,
  nodeIds: ["source", "profile", "features"],
  nodeResults: [
    { nodeId: "source", nodeType: "source.local_csv", status: "executed", rowCount: 150, artifactRefs: ["data/raw/iris-local.arrow"] },
    { nodeId: "features", nodeType: "transform.feature_engineer", status: "executed", rowCount: 150, artifactRefs: ["data/features/iris_linear_features.parquet"] }
  ],
  artifactEvidence: [{ nodeId: "features", artifactRefs: ["data/features/iris_linear_features.parquet", "data/features/iris_linear_features.arrow"] }],
  localOnly: true
};

const irisExperiment = {
  experimentId: "exp-iris-linear-001",
  workflowId,
  workflowVersion: "1.0.0",
  executionId: "exec-iris-linear-001",
  checkpointTag: "cp/iris-linear-model",
  status: "completed",
  modelId: "iris_petal_width_linear",
  modelKind: "MLJ.LinearRegressor",
  target: "petal_width",
  datasetId: "iris-local",
  datasetChecksumSha256: irisProfile.checksumSha256,
  metrics: { auc: 0.982, f1: 0.951, precision: 0.962, recall: 0.944, accuracy: 0.967 },
  featureImportance: [
    { feature: "petal_length", importance: 0.36 },
    { feature: "sepal_length", importance: 0.19 },
    { feature: "sepal_width", importance: 0.12 },
    { feature: "species", importance: 0.08 }
  ],
  hardwareBackend: "CPU (Local)",
  gpuReadinessStatus: "cpu_fallback",
  artifactEvidence: [
    { kind: "model", artifactRef: "data/models/iris_petal_width_linear.jls", checksumSha256: "8".repeat(64) },
    { kind: "metrics", artifactRef: "data/models/iris_linear_metrics.json", checksumSha256: "9".repeat(64) }
  ],
  startedAt: "2026-06-17T19:22:00Z",
  finishedAt: "2026-06-17T19:22:18Z",
  localOnly: true
};

const irisModel = {
  registryId: "reg-iris-linear-v1",
  modelId: "Iris Petal Linear Regression",
  workflowId,
  workflowVersion: "1.0.0",
  checkpointTag: "cp/iris-linear-model",
  experimentId: irisExperiment.experimentId,
  executionId: irisExperiment.executionId,
  modelKind: "MLJ.LinearRegressor",
  target: "petal_width",
  status: "registered",
  tags: ["iris", "linear-regression", "local"],
  owner: "julia_user",
  primaryMetricName: "R2",
  primaryMetricValue: 0.982,
  datasetId: "iris-local",
  datasetChecksumSha256: irisProfile.checksumSha256,
  artifactEvidence: [
    { kind: "model", artifactRef: "data/models/iris_petal_width_linear.jls", checksumSha256: "8".repeat(64) },
    { kind: "config", artifactRef: "data/models/iris_linear_config.toml", checksumSha256: "a".repeat(64) }
  ],
  registeredAt: "2026-06-17T19:23:00Z",
  updatedAt: "2026-06-17T19:23:00Z",
  deploymentStatus: "local_ready",
  localOnly: true
};

const irisPackage = {
  packageId: "pkg-iris-linear-local-001",
  workflowId,
  workflowVersion: "1.0.0",
  modelId: "Iris Petal Linear Regression",
  checkpointTag: "cp/iris-linear-model",
  endpointUrl: "http://127.0.0.1:8101/predict/iris-petal-width",
  endpointPath: "/predict/iris-petal-width",
  host: "127.0.0.1",
  port: 8101,
  serviceRef: "data/deploy/iris-linear/service.jl",
  packageRef: "data/deploy/iris-linear/package.tar.gz",
  packageChecksumSha256: "b".repeat(64),
  serviceCode: "using HTTP\nHTTP.serve(\"127.0.0.1\", 8101) do req\n    return HTTP.Response(200, \"local iris linear regression\")\nend",
  runCommand: "julia --project=. data/deploy/iris-linear/service.jl",
  modelRegistryId: irisModel.registryId,
  deploymentStatus: "local_ready",
  artifactEvidence: [
    { kind: "service", artifactRef: "data/deploy/iris-linear/service.jl", checksumSha256: "c".repeat(64) },
    { kind: "model", artifactRef: "data/models/iris_petal_width_linear.jls", checksumSha256: "8".repeat(64) }
  ],
  createdAt: "2026-06-17T19:24:00Z",
  localOnly: true
};

test("runs an Iris CSV through the local linear regression app cycle", async ({ page }) => {
  await page.addInitScript(() => {
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "http://127.0.0.1:8088" };
  });
  await mockIrisGateway(page);

  await page.goto("/");
  await expect(page.getByRole("status", { name: /100% local status/i })).toContainText("100% Local");

  await page.getByRole("button", { name: "Data", exact: true }).click();
  await page.getByRole("button", { name: /import local data/i }).click();
  await expect(page.getByRole("status", { name: /action feedback/i })).toContainText("Gateway action completed locally.");
  await expect(page.getByText("150 complete local rows").first()).toBeVisible();
  await expect(page.getByText("petal_length").first()).toBeVisible();

  await page.getByRole("button", { name: "Transform" }).click();
  await page.getByRole("button", { name: /run transform/i }).click();
  await expect(page.getByText("transform-iris-linear-001")).toBeVisible();
  await expect(page.getByText("iris_linear_features.parquet")).toBeVisible();

  await page.getByRole("button", { name: "ML Studio" }).click();
  await page.getByRole("button", { name: /train new model/i }).click();
  await expect(page.getByText("MLJ.LinearRegressor")).toBeVisible();
  await expect(page.getByText("petal_width")).toBeVisible();
  await expect(page.getByText("iris-local")).toBeVisible();

  await page.getByRole("button", { name: "Models" }).click();
  await page.getByRole("button", { name: /register model/i }).click();
  await expect(page.getByText("Iris Petal Linear Regression").first()).toBeVisible();
  await expect(page.getByText("data/models/iris_petal_width_linear.jls").first()).toBeVisible();

  await page.getByRole("button", { name: "Visualize" }).click();
  await page.getByRole("button", { name: /save local checkpoint/i }).click();
  await expect(page.getByText("Gateway action completed locally.")).toBeVisible();

  await page.getByRole("button", { name: "Deploy" }).click();
  await page.getByRole("button", { name: /package local endpoint/i }).click();
  await expect(page.getByText("pkg-iris-linear-local-001")).toBeVisible();
  await expect(page.getByText("data/deploy/iris-linear/package.tar.gz")).toBeVisible();

  await page.getByRole("button", { name: "Settings" }).click();
  await page.getByRole("button", { name: /create local snapshot/i }).click();
  await expect(page.getByRole("status", { name: /action feedback/i })).toContainText("Gateway action completed locally.");
});

async function mockIrisGateway(page: Page) {
  await page.route("http://127.0.0.1:8088/**", async (route) => {
    const request = route.request();
    const url = new URL(request.url());
    const path = url.pathname;
    const method = request.method();

    if (path === "/health") return route.fulfill(json(localHealth));
    if (path === "/api/v1/workflows") return route.fulfill(json({ items: [workflowSummary] }));
    if (path === `/api/v1/workflows/${workflowId}`) return route.fulfill(json(localWorkflow));
    if (path === "/api/v1/local-data/import" && method === "POST") return route.fulfill(json({ status: "profiled", profile: irisProfile }));
    if (path === `/api/v1/workflows/${workflowId}/transforms/history`) return route.fulfill(json({ items: [], count: 0 }));
    if (path === `/api/v1/workflows/${workflowId}/transforms/run` && method === "POST") {
      return route.fulfill(json({ status: "accepted", execution: { executionId: "exec-iris-transform", workflowId, workflowVersion: "1.0.0", checkpointTag: irisTransform.checkpointTag, status: "completed", mode: "batch", plan: [], stages: [], nodeCount: 5, connectionCount: 5, createdAt: irisTransform.startedAt, updatedAt: irisTransform.finishedAt, statusHistory: [] }, run: irisTransform }));
    }
    if (path === `/api/v1/workflows/${workflowId}/ml/experiments`) return route.fulfill(json({ items: [], count: 0 }));
    if (path === `/api/v1/workflows/${workflowId}/ml/experiments/run` && method === "POST") {
      return route.fulfill(json({ status: "accepted", execution: { executionId: irisExperiment.executionId, workflowId, workflowVersion: "1.0.0", checkpointTag: irisExperiment.checkpointTag, status: "completed", mode: "batch", plan: [], stages: [], nodeCount: 5, connectionCount: 5, createdAt: irisExperiment.startedAt, updatedAt: irisExperiment.finishedAt, statusHistory: [] }, experiment: irisExperiment }));
    }
    if (path === `/api/v1/workflows/${workflowId}/models`) return route.fulfill(json({ items: [], count: 0 }));
    if (path === `/api/v1/workflows/${workflowId}/models/register` && method === "POST") return route.fulfill(json({ status: "registered", model: irisModel }));
    if (path === `/api/v1/workflows/${workflowId}/deploy/packages`) return route.fulfill(json({ items: [], count: 0 }));
    if (path === `/api/v1/workflows/${workflowId}/deploy/package` && method === "POST") return route.fulfill(json({ status: "packaged", package: irisPackage }));
    if (path === `/api/v1/workflows/${workflowId}/dashboards/${dashboardId}/checkpoint-export` && method === "POST") {
      return route.fulfill(json({ status: "exported", export: visualizeExports[0], checkpoint: checkpoints[0], dashboard: publishedDashboard, bundle: { bundleId: "bundle-iris-linear", createdAt: "2026-06-17T19:25:00Z", schemaVersion: "juliaflow.reproducibility.v1", workflow: localWorkflow, checkpoint: checkpoints[0], dataReferences: [], datasetCards: [irisProfile], packageEnvironment: {}, runtimeConfig: {}, randomSeeds: {}, modelArtifact: { modelId: irisModel.modelId, artifactRef: "data/models/iris_petal_width_linear.jls", checksumSha256: "8".repeat(64) }, metrics: irisExperiment.metrics, evaluationOutputs: {}, explainabilityOutputs: {}, notes: "iris linear regression browser cycle", localOnly: true, bundleChecksumSha256: "d".repeat(64) } }));
    }
    if (path === "/api/v1/local-backups" && method === "POST") {
      return route.fulfill(json({ status: "ok", backup: { backupId: "backup-iris-linear", createdAt: "2026-06-17T19:26:00Z", schemaVersion: "juliaflow.backup.v1", localProfile: localHealth.localProfile, dataEstateRoot: localHealth.dataEstateRoot, backupChecksumSha256: "e".repeat(64) } }));
    }
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
