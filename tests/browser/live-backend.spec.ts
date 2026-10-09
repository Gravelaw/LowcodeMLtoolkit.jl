import { expect, test } from "@playwright/test";

const gatewayUrl = process.env.JULIAFLOW_LIVE_GATEWAY_URL ?? "http://127.0.0.1:18088";
const gatewayAuthToken = process.env.JULIAFLOW_LIVE_AUTH_TOKEN ?? "";
test.use({ extraHTTPHeaders: { Authorization: `Bearer ${gatewayAuthToken}` } });
const hubArtifactHash = process.env.JULIAFLOW_LIVE_HUB_ARTIFACT_HASH ?? "";
const hubPackageRef = process.env.JULIAFLOW_LIVE_HUB_PACKAGE_REF ?? "hub://offline/live-browser-proof";
const hubMirrorRef = process.env.JULIAFLOW_LIVE_HUB_MIRROR_REF ?? "mirror://offline/live-browser-proof";

async function expectOk(response: { ok(): boolean; status(): number; text(): Promise<string> }, label: string) {
  if (!response.ok()) {
    throw new Error(`${label} failed: ${response.status()} ${await response.text()}`);
  }
}

test.describe("live-backend release smoke", () => {
  test.beforeEach(async ({ page }) => {
    await page.addInitScript((config) => {
      window.__JULIAFLOW_CONFIG__ = config;
    }, {
      gatewayBaseUrl: gatewayUrl,
      gatewayAuthToken,
      runtimeMode: "local-appliance"
    });
  });

  test.afterEach(async ({ page }) => {
    // Let in-flight health polling finish before Playwright closes the page.
    // The harness still rejects every server connection error and credential leak.
    await page.waitForLoadState("networkidle");
  });

  test("rejects unauthenticated and cross-origin mutations including realtime upgrades", async ({ request }) => {
    const before = await request.get(`${gatewayUrl}/api/v1/data-science-projects`);
    const beforePayload = await before.json();
    for (const headers of [{ Authorization: "" }, { Origin: "https://untrusted.example" }, { Origin: "null" }]) {
      const response = await request.post(`${gatewayUrl}/api/v1/data-science-projects`, {
        headers, data: { projectId: "unauthorized-browser-probe", name: "Unauthorized" }
      });
      expect(response.status()).toBe(headers.Authorization === "" ? 401 : 403);
    }
    for (const headers of [{ Authorization: "" }, { Origin: "https://untrusted.example" }]) {
      const upgrade = await request.get(`${gatewayUrl}/api/v1/realtime`, {
        headers: { Connection: "Upgrade", Upgrade: "websocket", "Sec-WebSocket-Version": "13", "Sec-WebSocket-Key": "dGhlIHNhbXBsZSBub25jZQ==", ...headers }
      });
      expect(upgrade.status()).toBe(headers.Authorization === "" ? 401 : 403);
      expect(upgrade.headers()["connection"]).toBe("close");
    }
    const after = await request.get(`${gatewayUrl}/api/v1/data-science-projects`);
    expect(await after.json()).toEqual(beforePayload);
  });

  test("authenticates a browser realtime subscription without credentials in the URL", async ({ page }) => {
    await page.context().setExtraHTTPHeaders({});
    // Use a real HTTP document so browser local-network protection sees its actual address space.
    await page.goto("/juliaflow-config.js");
    const result = await page.evaluate(({ url, token }) => new Promise<{ protocol: string; subscriptionId: string }>((resolve, reject) => {
      const encoded = btoa(token).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
      const ws = new WebSocket(url.replace(/^http/, "ws") + "/api/v1/realtime", ["juliaflow", `juliaflow.bearer.${encoded}`]);
      const timeout = setTimeout(() => { ws.close(); reject(new Error("Realtime subscription timed out")); }, 10000);
      ws.onerror = () => { clearTimeout(timeout); reject(new Error("Realtime authentication failed")); };
      ws.onopen = () => ws.send(JSON.stringify({ jsonrpc: "2.0", id: 1, method: "canvas.subscribe", params: { workflowId: "wf-foundation" } }));
      ws.onmessage = (event) => {
        const message = JSON.parse(event.data);
        if (message.id !== 1) return;
        clearTimeout(timeout);
        if (message.error) reject(new Error(message.error.message));
        else ws.onclose = () => resolve({ protocol: ws.protocol, subscriptionId: message.result.subscriptionId });
        ws.close();
      };
    }), { url: gatewayUrl, token: gatewayAuthToken });
    expect(result.protocol).toBe("juliaflow");
    expect(result.subscriptionId).toMatch(/^canvas-/);
  });

  test("rejects missing evidence from a real browser without creating successful results", async ({ page, request }) => {
    const projectId = "unavailable-browser-project";
    const datasetId = "unavailable-browser-data";
    const splitPlanId = "unavailable-browser-split";
    const create = await request.post(`${gatewayUrl}/api/v1/data-science-projects`, {
      data: {
        projectId, name: "Unavailable evidence browser proof",
        datasets: [{ datasetId, name: "Missing source", role: "train", sourceUri: "local://data/raw/does-not-exist.csv", localOnly: true }],
        splitPlans: [{ splitPlanId, datasetId, strategy: "random", trainFraction: 0.6, validationFraction: 0.2, testFraction: 0.2, locked: true, seed: 42, createdAt: new Date().toISOString() }]
      }
    });
    await expectOk(create, "create missing-evidence project");
    const before = await (await request.get(`${gatewayUrl}/api/v1/data-science-projects/${projectId}`)).json();
    await page.goto("/juliaflow-config.js");
    const results = await page.evaluate(async ({ url, token, project, dataset, split }) => {
      const calls = [
        [`/data-science-projects/${project}/statistical-analysis/run`, { datasetId: dataset, methods: ["summary"] }],
        [`/data-science-projects/${project}/tuning/run`, { datasetId: dataset, splitPlanId: split, targetColumn: "y", algorithm: "LinearRegressor", metricNames: ["rmse"], maxTrials: 2, finalTestPolicy: "forbid_final_test" }],
        ["/workflows/wf-foundation/ml/experiments/run", { projectId: project, datasetId: dataset, splitPlanId: split, target: "y", algorithm: "LinearRegressor", finalTestPolicy: "forbid_final_test" }]
      ] as const;
      const outcomes = [];
      for (const [path, body] of calls) {
        const response = await fetch(`${url}/api/v1${path}`, {
          method: "POST", headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" }, body: JSON.stringify(body)
        });
        outcomes.push({ status: response.status, body: await response.json() });
      }
      return outcomes;
    }, { url: gatewayUrl, token: gatewayAuthToken, project: projectId, dataset: datasetId, split: splitPlanId });
    for (const result of results) {
      expect(result.status).toBe(409);
      expect(result.body.error).toContain("source evidence unavailable");
      expect(result.body.metrics).toBeUndefined();
      expect(result.body.artifactRefs).toBeUndefined();
    }
    const after = await (await request.get(`${gatewayUrl}/api/v1/data-science-projects/${projectId}`)).json();
    expect(after).toEqual(before);
    expect(after.projectJobs).toEqual([]);
    expect(after.evaluationReports).toEqual([]);
    expect(after.modelLifecycleRecords).toEqual([]);
  });

  test("uses local gateway data through the release UI without demo substitution", async ({ page, request }) => {
    const projectId = "live-browser-data-project";
    const datasetId = "customer-churn-local";
    const splitPlanId = "split-live-browser-customer-churn";
    const createProject = await request.post(`${gatewayUrl}/api/v1/data-science-projects`, {
      data: {
        projectId,
        name: "Live Browser Data Project",
        description: "Local-appliance browser proof for project-backed Data evidence."
      }
    });
    await expectOk(createProject, "create project");
    const importProfile = await request.post(`${gatewayUrl}/api/v1/local-data/import`, {
      data: {
        projectId,
        datasetId,
        sourceUri: `local://data/raw/${datasetId}.csv`,
        format: "csv",
        targetZone: "raw",
        readMode: "csv"
      }
    });
    await expectOk(importProfile, "import profile");
    const statistics = await request.post(`${gatewayUrl}/api/v1/data-science-projects/${projectId}/statistical-analysis/run`, {
      data: {
        datasetId,
        methods: ["summary", "pearson_correlation", "spearman_correlation", "ols", "t_test", "chi_square", "anova"],
        targetColumn: "churn",
        featureColumn: "monthly_charges",
        groupColumn: "contract_type"
      }
    });
    await expectOk(statistics, "statistical analysis");
    const updateProject = await request.put(`${gatewayUrl}/api/v1/data-science-projects/${projectId}`, {
      data: {
        projectId,
        name: "Live Browser Data Project",
        splitPlans: [
          {
            splitPlanId,
            datasetId,
            strategy: "stratified",
            trainFraction: 0.7,
            validationFraction: 0.15,
            testFraction: 0.15,
            seed: 42,
            locked: true,
            createdAt: new Date().toISOString()
          }
        ],
        finalTestLocks: [
          {
            lockId: "final-lock-live-browser-customer-churn",
            splitPlanId,
            lockedAt: new Date().toISOString(),
            reason: "Live browser smoke protects final test evidence.",
            lockedBy: "live-browser"
          }
        ]
      }
    });
    await expectOk(updateProject, "update project split plan");
    const training = await request.post(`${gatewayUrl}/api/v1/workflows/wf-foundation/ml/experiments/run`, {
      data: {
        projectId,
        datasetId,
        splitPlanId,
        finalTestPolicy: "forbid_final_test",
        target: "churn",
        algorithm: "MLJ.XGBoostClassifier"
      }
    });
    await expectOk(training, "training run");
    const tuning = await request.post(`${gatewayUrl}/api/v1/data-science-projects/${projectId}/tuning/run`, {
      data: {
        datasetId,
        splitPlanId,
        finalTestPolicy: "forbid_final_test",
        targetColumn: "churn",
        taskType: "classification",
        algorithm: "MLJ.XGBoostClassifier",
        metricNames: ["auc", "f1"],
        maxTrials: 3
      }
    });
    await expectOk(tuning, "tuning run");
    const tuningPayload = await tuning.json();
    const trainingPlanId = tuningPayload.trainingPlan.trainingPlanId;
    const tuningStudyId = tuningPayload.tuningStudy.tuningStudyId;
    const evaluation = await request.post(`${gatewayUrl}/api/v1/data-science-projects/${projectId}/evaluation/run`, {
      data: {
        datasetId,
        splitPlanId,
        trainingPlanId,
        tuningStudyId,
        finalTestPolicy: "use_final_test",
        approvalThreshold: 0.1,
        metricNames: ["auc", "f1"]
      }
    });
    await expectOk(evaluation, "final evaluation");
    const evaluationPayload = await evaluation.json();
    expect(["local_csv_trained_artifact", "mlj_package_backed_final_evaluation"]).toContain(evaluationPayload.evaluationReport.validationEvidence.evaluationExecutionMode);
    expect(evaluationPayload.evaluationReport.approved).toBe(true);
    expect(evaluationPayload.evaluationReport.metrics.f1).toBeGreaterThanOrEqual(0.1);
    const evaluationReportId = evaluationPayload.evaluationReport.evaluationReportId;
    const prediction = await request.post(`${gatewayUrl}/api/v1/data-science-projects/${projectId}/predictions/export`, {
      data: {
        datasetId,
        evaluationReportId,
        outputContractRef: "local://contracts/live-browser/prediction-output.json",
        format: "csv",
        rowCount: 5,
        outputColumns: ["prediction_id", "dataset_id", "prediction"],
        outputContract: {
          columns: [
            { name: "prediction_id", sourceColumn: "prediction_id", required: true },
            { name: "dataset_id", sourceColumn: "dataset_id", required: true },
            { name: "prediction", sourceColumn: "prediction", required: true }
          ]
        },
        outputMappings: [
          { sourceColumn: "prediction_id", outputColumn: "prediction_id" },
          { sourceColumn: "dataset_id", outputColumn: "dataset_id" },
          { sourceColumn: "prediction", outputColumn: "prediction" }
        ]
      }
    });
    await expectOk(prediction, "prediction export");
    const predictionPayload = await prediction.json();
    const predictionExportId = predictionPayload.predictionExport.predictionExportId;
    const drift = await request.post(`${gatewayUrl}/api/v1/data-science-projects/${projectId}/drift/run`, {
      data: {
        datasetId,
        predictionExportId,
        metricNames: ["psi", "missing_rate"],
        threshold: 0.9
      }
    });
    await expectOk(drift, "drift report");
    const driftPayload = await drift.json();
    expect(["local_csv_prediction_distribution", "mlj_package_backed_prediction_distribution"]).toContain(driftPayload.driftReport.validationEvidence.driftExecutionMode);
    const registerModel = await request.post(`${gatewayUrl}/api/v1/workflows/wf-foundation/models/register`, {
      data: { modelId: "Churn Prediction", owner: "julia_user", tags: ["churn", "local"] }
    });
    await expectOk(registerModel, "model register");
    const lifecycle = await request.post(`${gatewayUrl}/api/v1/data-science-projects/${projectId}/models/lifecycle`, {
      data: {
        modelId: "Churn Prediction",
        action: "approve_model",
        evaluationReportId,
        reason: "Live browser smoke approves the validated local model."
      }
    });
    await expectOk(lifecycle, "model lifecycle");
    const deployPackage = await request.post(`${gatewayUrl}/api/v1/workflows/wf-foundation/deploy/package`, {
      data: { modelId: "Churn Prediction", endpointPath: "/predict/churn", host: "127.0.0.1", port: 8099 }
    });
    await expectOk(deployPackage, "deploy package");

    await page.goto("/");
    await expect(page.getByRole("heading", { name: "Local Workspace Overview" })).toBeVisible();
    await expect(page.getByRole("status", { name: /100% local status/i })).toContainText("100% Local");
    await expect(page.getByText("Gateway unavailable. Running deterministic local demo fallback.")).toHaveCount(0);
    await expect(page.getByLabel("Release mode unavailable")).toHaveCount(0);

    await page.getByRole("button", { name: "Data" }).click();
    await expect(page.getByText("Project Data Workflow Evidence")).toBeVisible();
    await expect(page.getByText(/^dsjob-[a-f0-9]+$/).first()).toBeVisible();
    await expect(page.getByText(/summary,pearson_correlation,spearman_correlation,ols,t_test,chi_square,anova \(completed\)/)).toBeVisible();
    await expect(page.getByText(new RegExp(`local://analysis/${datasetId}/stats-.*?/results.json`)).first()).toBeVisible();
    await expect(page.getByText(new RegExp(`local://analysis/${datasetId}/stats-.*?/analysis.jl`)).first()).toBeVisible();
    await page.getByLabel("Dataset ID", { exact: true }).fill(datasetId);
    await page.getByLabel("Approved local CSV path", { exact: true }).fill(`local://data/raw/${datasetId}.csv`);
    await page.getByRole("button", { name: /import local data/i }).click();
    await expect(page.getByText("Gateway action completed locally.")).toBeVisible();

    await page.getByRole("button", { name: "Explorer" }).click();
    await page.getByRole("button", { name: /save workflow/i }).click();
    await expect(page.getByText("Gateway action completed locally.")).toBeVisible();
    await page.getByRole("button", { name: /run workflow/i }).click();
    await expect(page.getByText("Gateway action completed locally.")).toBeVisible();

    await page.getByRole("button", { name: "ML Studio" }).click();
    await expect(page.getByText("Project Training Job Evidence")).toBeVisible();
    await expect(page.getByText(/^dsjob-[a-f0-9]+$/).first()).toBeVisible();
    await expect(page.getByText("Project Validation Workflow")).toBeVisible();
    await expect(page.getByText(new RegExp(`${trainingPlanId}`))).toBeVisible();
    await expect(page.getByText(new RegExp(`${tuningStudyId} \\(validation only\\)`))).toBeVisible();
    await expect(page.getByText(new RegExp(`${evaluationReportId} \\(approved\\)`))).toBeVisible();
    await expect(page.getByText(new RegExp(`${predictionExportId} \\(5 rows\\)`))).toBeVisible();

    await page.getByRole("button", { name: "Models" }).click();
    await expect(page.getByRole("heading", { name: "Models", exact: true })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Model Registry" })).toBeVisible();
    await expect(page.getByText("Churn Prediction").first()).toBeVisible();
    await expect(page.getByText("Lifecycle Review")).toBeVisible();
    await expect(page.getByText("deployed").first()).toBeVisible();
    await expect(page.getByText(/job-[a-f0-9]+/).first()).toBeVisible();
    await expect(page.getByText(/^dsjob-[a-f0-9]+$/).first()).toBeVisible();

    await page.getByRole("button", { name: "Deploy" }).click();
    await expect(page.getByRole("heading", { name: "Deploy", exact: true })).toBeVisible();
    const endpointMonitoring = page.locator(".right-panel").filter({ hasText: "Endpoint Monitoring" });
    await expect(endpointMonitoring.getByText("Package Gate")).toBeVisible();
    await expect(endpointMonitoring.getByText("Ready", { exact: true })).toBeVisible();
    await expect(endpointMonitoring.getByText("Project Job")).toBeVisible();
    await expect(endpointMonitoring.getByText(/job-[a-f0-9]+/).first()).toBeVisible();
    await expect(endpointMonitoring.getByText(/^dsjob-[a-f0-9]+$/).first()).toBeVisible();
    await expect(page.getByText("Package History")).toBeVisible();
    await expect(page.getByText("local_ready").first()).toBeVisible();

    await page.getByRole("button", { name: "Monitor" }).click();
    await expect(page.getByRole("heading", { name: "Execution Monitor" })).toBeVisible();
    await expect(page.getByRole("cell", { name: "wf-foundation" }).first()).toBeVisible();
    await expect(page.getByText("exec-local-churn-001")).toHaveCount(0);

    await page.getByRole("button", { name: "Visualize" }).click();
    await expect(page.getByRole("heading", { name: "Visualize" })).toBeVisible();
    await expect(page.getByText("Project Statistical Analysis Evidence")).toBeVisible();
    await expect(page.getByText(/summary,pearson_correlation,spearman_correlation,ols,t_test,chi_square,anova/)).toBeVisible();
    await expect(page.getByText(new RegExp(`local://analysis/${datasetId}/stats-.*?/results.json`)).first()).toBeVisible();
    await expect(page.getByText(new RegExp(`local://analysis/${datasetId}/stats-.*?/analysis.jl`)).first()).toBeVisible();
    await expect(page.getByText("Dashboard Builder")).toBeVisible();
    await expect(page.getByText("Artifact Rows", { exact: true })).toBeVisible();
    await expect(page.getByText("No artifact-backed dashboard rows are available")).toHaveCount(0);
    await page.getByRole("button", { name: /save local checkpoint/i }).click();
    await expect(page.getByText("Gateway action completed locally.")).toBeVisible();

    await page.getByRole("button", { name: "Settings" }).click();
    await expect(page.getByRole("heading", { name: "Settings" })).toBeVisible();
    await expect(page.getByText("Security And API Keys")).toBeVisible();
    await expect(page.getByText("local-appliance")).toBeVisible();
    await expect(page.getByText("blocked")).toBeVisible();

    const hubList = await request.get(`${gatewayUrl}/api/v1/hub/extensions`);
    expect(hubList.ok()).toBeTruthy();
    const hubPayload = await hubList.json();
    expect(Array.isArray(hubPayload.items)).toBeTruthy();
    const register = await request.post(`${gatewayUrl}/api/v1/hub/extensions/register`, {
      data: {
        manifest: {
          extensionId: "juliaflow-live-browser-proof",
          name: "Live Browser Proof Pack",
          version: "0.1.0",
          publisher: "official",
          summary: "Local offline Hub install proof for live backend browser QA.",
          packageRef: hubPackageRef,
          tags: ["official", "offline", "local-first"],
          engineCompatibility: "alpha-core",
          requiredContractVersion: "0.1.0",
          supportedCheckpoints: ["cp/00-foundation", "cp/01-contracts-frozen", "cp/02-alpha-core", "cp/03-alpha-gpu-bi", "cp/dashboard-v3"],
          compatibleCheckpoints: ["cp/00-foundation", "cp/01-contracts-frozen", "cp/02-alpha-core", "cp/03-alpha-gpu-bi", "cp/dashboard-v3"],
          dependencies: [],
          publisherIdentity: "official:juliaflow",
          artifactHashes: { package: hubArtifactHash },
          compatibilitySandboxCommand: "julia --project=. extensions/labs/test/runtests.jl",
          mirrorRefs: [hubMirrorRef]
        }
      }
    });
    expect(register.ok()).toBeTruthy();
    const install = await request.post(`${gatewayUrl}/api/v1/hub/extensions/juliaflow-live-browser-proof/install`, {
      data: { action: "enable" }
    });
    if (!install.ok()) {
      throw new Error(`Hub install failed: ${install.status()} ${await install.text()}`);
    }
    const installPayload = await install.json();
    expect(["installed", "enabled"]).toContain(installPayload.extension.installState);

    const bundle = await request.post(`${gatewayUrl}/api/v1/reproducibility-bundles`, {
      data: {
        workflowId: "wf-foundation",
        checkpointTag: "cp/dashboard-v3",
        dashboardId: "dashboard-foundation",
        notes: "live backend browser smoke"
      }
    });
    expect(bundle.ok()).toBeTruthy();
    const bundlePayload = await bundle.json();
    expect(bundlePayload.bundle.bundleChecksumSha256).toMatch(/^[a-f0-9]{64}$/);
  });

  test("persists the grouped split selected in the existing Data UI", async ({ page, request }) => {
    const projectId = "live-browser-data-project";
    const datasetId = "customer-churn-local";
    const splitPlanId = "grouped-ui-proof";
    const endpoint = `${gatewayUrl}/api/v1/data-science-projects/${projectId}`;
    const project = await (await request.get(endpoint)).json();
    const added = await request.put(endpoint, { data: {
      splitPlans: [{ splitPlanId, datasetId, strategy: "random", trainFraction: 0.6,
        validationFraction: 0.2, testFraction: 0.2, seed: 42, locked: false, createdAt: new Date().toISOString() }, ...project.splitPlans]
    } });
    await expectOk(added, "add unmaterialized split plan");
    await page.goto("/");
    await page.getByRole("button", { name: "Data", exact: true }).click();
    // Wait for real project hydration before operating the existing controls.
    await expect(page.getByText(/^dsjob-[a-f0-9]+$/).first()).toBeVisible();
    await expect(page.getByLabel("Validation strategy", { exact: true })).toHaveValue("random");
    async function updateFromUi(action: () => Promise<unknown>) {
      const response = page.waitForResponse((item) => item.url() === endpoint && item.request().method() === "PUT");
      await action();
      await expectOk(await response, "persist UI split choice");
    }
    // File-derived profiles do not infer a training target from fixture names.
    // Assign it through the same persisted schema control a user must operate.
    await page.getByRole("tab", { name: "schema", exact: true }).click();
    await updateFromUi(() => page.getByLabel("Column role for churn", { exact: true }).selectOption("target"));
    await expect(page.getByLabel("Column role for churn", { exact: true })).toHaveValue("target");
    await updateFromUi(() => page.getByLabel("Validation strategy", { exact: true }).selectOption("grouped"));
    await expect(page.getByLabel("Validation strategy", { exact: true })).toHaveValue("grouped");
    await updateFromUi(() => page.getByLabel("Validation group column", { exact: true }).selectOption("contract_type"));
    await updateFromUi(() => page.getByRole("button", { name: "Lock Final Test Split", exact: true }).click());
    const lockedButtons = page.getByRole("button", { name: "Final Test Locked", exact: true });
    await expect(lockedButtons).toHaveCount(2);
    await expect(lockedButtons.nth(0)).toBeDisabled();
    await expect(lockedButtons.nth(1)).toBeDisabled();
    const fitted = await request.post(`${endpoint}/transforms/fit-apply`, { data: {
      datasetId, splitPlanId, fitSplit: "train", applySplits: ["validation", "test"]
    } });
    await expectOk(fitted, "materialize grouped fit/apply");
    const persisted = await (await request.get(endpoint)).json();
    const plan = persisted.splitPlans.find((item: { splitPlanId: string }) => item.splitPlanId === splitPlanId);
    expect(plan).toMatchObject({ strategy: "grouped", groupColumn: "contract_type", locked: true });
    const assignments = persisted.splitAssignments.filter((item: { splitPlanId: string }) => item.splitPlanId === splitPlanId);
    expect(assignments).toHaveLength(30);
    const groupSplits = new Map<string, Set<string>>();
    for (const assignment of assignments) {
      const rowIndex = Number(assignment.rowRef.split("#row:")[1]) - 1;
      const group = rowIndex % 3 === 0 ? "monthly" : rowIndex % 2 === 0 ? "annual" : "two_year";
      const partitions = groupSplits.get(group) ?? new Set<string>();
      partitions.add(assignment.split);
      groupSplits.set(group, partitions);
    }
    expect(groupSplits.size).toBe(3);
    expect([...groupSplits.values()].every((partitions) => partitions.size === 1)).toBe(true);
    expect(new Set(assignments.map((item: { split: string }) => item.split))).toEqual(new Set(["train", "validation", "test"]));
    const transform = persisted.transformFitApplyRecords.find((item: { splitPlanId: string }) => item.splitPlanId === splitPlanId);
    expect(transform.transformKind).toBe("numeric_standardize");
    expect(transform.artifactRefs).toHaveLength(3);
    expect(transform.artifactRefs.every((item: { checksumSha256: string }) => /^[a-f0-9]{64}$/.test(item.checksumSha256))).toBe(true);
    const rejected = await request.put(endpoint, { data: {
      splitPlans: persisted.splitPlans.map((item: { splitPlanId: string }) => item.splitPlanId === splitPlanId ? { ...item, strategy: "random" } : item)
    } });
    expect(rejected.status()).toBe(400);
    expect(await (await request.get(endpoint)).json()).toEqual(persisted);
  });
});
