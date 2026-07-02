import { expect, test } from "@playwright/test";

const gatewayUrl = process.env.JULIAFLOW_LIVE_GATEWAY_URL ?? "http://127.0.0.1:18088";
const hubArtifactHash = process.env.JULIAFLOW_LIVE_HUB_ARTIFACT_HASH ?? "";
const hubPackageRef = process.env.JULIAFLOW_LIVE_HUB_PACKAGE_REF ?? "hub://offline/live-browser-proof";
const hubMirrorRef = process.env.JULIAFLOW_LIVE_HUB_MIRROR_REF ?? "mirror://offline/live-browser-proof";

test.describe("live-backend release smoke", () => {
  test.beforeEach(async ({ page }) => {
    await page.addInitScript((config) => {
      window.__JULIAFLOW_CONFIG__ = config;
    }, {
      gatewayBaseUrl: gatewayUrl,
      runtimeMode: "local-appliance"
    });
  });

  test("uses local gateway data through the release UI without demo substitution", async ({ page, request }) => {
    const projectId = "live-browser-data-project";
    const datasetId = "customer-churn-local";
    const createProject = await request.post(`${gatewayUrl}/api/v1/data-science-projects`, {
      data: {
        projectId,
        name: "Live Browser Data Project",
        description: "Local-appliance browser proof for project-backed Data evidence."
      }
    });
    expect(createProject.ok()).toBeTruthy();
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
    expect(importProfile.ok()).toBeTruthy();
    const statistics = await request.post(`${gatewayUrl}/api/v1/data-science-projects/${projectId}/statistical-analysis/run`, {
      data: {
        datasetId,
        methods: ["summary", "pearson_correlation", "spearman_correlation", "ols", "t_test", "chi_square", "anova"],
        targetColumn: "churn",
        featureColumn: "monthly_charges",
        groupColumn: "contract_type"
      }
    });
    expect(statistics.ok()).toBeTruthy();

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
    await page.getByRole("button", { name: /import local data/i }).click();
    await expect(page.getByText("Gateway action completed locally.")).toBeVisible();

    await page.getByRole("button", { name: "Explorer" }).click();
    await page.getByRole("button", { name: /save workflow/i }).click();
    await expect(page.getByText("Gateway action completed locally.")).toBeVisible();
    await page.getByRole("button", { name: /run workflow/i }).click();
    await expect(page.getByText("Gateway action completed locally.")).toBeVisible();

    await page.getByRole("button", { name: "Monitor" }).click();
    await expect(page.getByRole("heading", { name: "Execution Monitor" })).toBeVisible();
    await expect(page.getByRole("cell", { name: "wf-foundation" }).first()).toBeVisible();
    await expect(page.getByText("exec-local-churn-001")).toHaveCount(0);

    await page.getByRole("button", { name: "Visualize" }).click();
    await expect(page.getByRole("heading", { name: "Visualize" })).toBeVisible();
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
});
