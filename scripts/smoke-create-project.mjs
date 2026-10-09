import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { spawn } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { chromium } from "playwright";

const root = process.cwd();
const evidence = resolve(process.env.JULIAFLOW_CREATE_EVIDENCE_ROOT ?? join(tmpdir(), "juliaflow-create-evidence"));
mkdirSync(evidence, { recursive: true });
const home = mkdtempSync(join(tmpdir(), "juliaflow-create-project-"));
const rawRoot = join(home, "data", "raw");
mkdirSync(rawRoot, { recursive: true });
const csv = "id,value,category\na,1,first\nb,2,second\nc,3,first\n";
writeFileSync(join(rawRoot, "new-project.csv"), csv);
const checksum = createHash("sha256").update(csv).digest("hex");
const basePort = 22000 + Math.floor(Math.random() * 15000);
const gatewayUrl = `http://127.0.0.1:${basePort}`;
const frontendUrl = `http://127.0.0.1:${basePort + 1}`;
const authToken = randomBytes(32).toString("hex");
const children = new Set();
const checks = [];
let browser;
function start(name, executable, args, env = {}) {
  const child = spawn(executable, args, { cwd: root, env: { ...process.env, ...env }, stdio: ["ignore", "pipe", "pipe"], detached: process.platform !== "win32" });
  children.add(child);
  child.on("error", (error) => { child.startError = error; });
  const log = join(evidence, `${name}.log`);
  writeFileSync(log, "");
  child.stdout.on("data", (chunk) => writeFileSync(log, chunk, { flag: "a" }));
  child.stderr.on("data", (chunk) => writeFileSync(log, chunk, { flag: "a" }));
  return child;
}
async function stop(child) {
  if (!child || !child.pid || child.exitCode !== null || child.signalCode !== null) return;
  const exited = new Promise((resolve) => child.once("exit", resolve));
  if (process.platform === "win32") child.kill("SIGTERM"); else process.kill(-child.pid, "SIGTERM");
  await Promise.race([exited, new Promise((resolve) => setTimeout(resolve, 10000))]);
  if (child.exitCode === null && child.signalCode === null) {
    if (process.platform === "win32") child.kill("SIGKILL"); else process.kill(-child.pid, "SIGKILL");
    await exited;
  }
  children.delete(child);
}
async function api(path, options = {}) {
  const response = await fetch(`${gatewayUrl}${path}`, { ...options, headers: { Authorization: `Bearer ${authToken}`, "Content-Type": "application/json", ...options.headers } });
  assert.equal(response.ok, true, `${path} status=${response.status} ${response.ok ? "" : await response.text()}`);
  return response.json();
}
async function waitReady(child, url, headers = {}) {
  const deadline = Date.now() + 240000;
  while (Date.now() < deadline) {
    if (child.startError) throw child.startError;
    assert.equal(child.exitCode, null, "server exited during startup");
    try { if ((await fetch(url, { headers })).ok) return; } catch { /* Startup is bounded by the deadline. */ }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(`server readiness timed out: ${url}`);
}
function startGateway(label) {
  // Load the existing repository directly: no foundation workflow or project is seeded.
  return start(label, process.env.JULIA_EXE ?? process.env.JULIAFLOW_JULIA_CMD ?? "julia", ["--project=.", "-e", 'using JuliaFlowMonorepo.JuliaFlowApiGateway; state = load_state(ENV["JULIAFLOW_STORE_ROOT"]); serve_gateway(state; host="127.0.0.1", port=parse(Int, ENV["JULIAFLOW_GATEWAY_PORT"]))'], {
    JULIAFLOW_HOME: home, JULIAFLOW_DATA_ESTATE_ROOT: join(home, "data"), JULIAFLOW_METADATA_ROOT: join(home, "metadata"),
    JULIAFLOW_STORE_ROOT: join(home, "metadata", "gateway-store"), JULIAFLOW_GATEWAY_PORT: String(basePort),
    JULIAFLOW_RUNTIME_MODE: "local-appliance", JULIAFLOW_AUTH_MODE: "required", JULIAFLOW_DEV_AUTH_TOKEN: authToken,
    JULIAFLOW_CORS_ALLOW_ORIGIN: frontendUrl, JULIAFLOW_LOCAL_PROFILE: "single-user", JULIA_PKG_PRECOMPILE_AUTO: "0"
  });
}
async function openBrowser(storageState) {
  browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, storageState });
  await context.addInitScript((config) => { window.__JULIAFLOW_CONFIG__ = config; }, { gatewayBaseUrl: gatewayUrl, gatewayAuthToken: authToken, runtimeMode: "local-appliance" });
  const page = await context.newPage();
  const errors = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await page.goto(frontendUrl);
  return { page, context, errors };
}
async function create(page, name, description = "") {
  await page.getByRole("button", { name: "Create project", exact: true }).click();
  await page.getByLabel("Project name", { exact: true }).fill(name);
  await page.getByLabel("Description (optional)", { exact: true }).fill(description);
  const dialog = page.getByRole("dialog");
  const createdResponse = page.waitForResponse((response) => response.url().endsWith("/data-science-projects") && response.request().method() === "POST");
  await dialog.getByRole("button", { name: "Create project", exact: true }).evaluate((button) => { button.click(); button.click(); });
  const created = await (await createdResponse).json();
  await page.getByText(`Project saved and opened: ${created.projectId}.`, { exact: true }).waitFor();
  const id = await page.getByLabel("Open saved project").inputValue();
  assert.ok(id, "saved project selector must expose returned ID");
  return id;
}
try {
  let gateway = startGateway("gateway-first");
  // Vite uses the frontend package working directory.
  const web = spawn(process.execPath, [resolve(root, "node_modules/vite/bin/vite.js"), "--configLoader", "runner", "--host", "127.0.0.1", "--port", String(basePort + 1)], { cwd: join(root, "apps/frontend"), env: process.env, detached: process.platform !== "win32", stdio: ["ignore", "pipe", "pipe"] });
  children.add(web);
  web.stdout.on("data", (chunk) => writeFileSync(join(evidence, "frontend.log"), chunk, { flag: "a" }));
  web.stderr.on("data", (chunk) => writeFileSync(join(evidence, "frontend.log"), chunk, { flag: "a" }));
  await Promise.all([waitReady(gateway, `${gatewayUrl}/health`, { Authorization: `Bearer ${authToken}` }), waitReady(web, frontendUrl)]);
  assert.deepEqual((await api("/api/v1/data-science-projects")).items, []);
  assert.deepEqual((await api("/api/v1/workflows")).items, []);
  let session = await openBrowser();
  let { page } = session;
  await page.getByText("No saved projects. Create a project to begin.").waitFor();
  assert.equal(await page.getByLabel("Open saved project").inputValue(), "");
  assert.equal(await page.getByRole("button", { name: "Save Workflow" }).isDisabled(), true);
  await page.screenshot({ path: join(evidence, "empty-light.png"), fullPage: true });
  const createTrigger = page.getByRole("button", { name: "Create project", exact: true });
  await createTrigger.click();
  const validationDialog = page.getByRole("dialog");
  await validationDialog.getByRole("button", { name: "Create project", exact: true }).click();
  await validationDialog.getByRole("alert").waitFor();
  assert.equal(await page.getByLabel("Project name", { exact: true }).getAttribute("aria-invalid"), "true");
  await page.screenshot({ path: join(evidence, "dialog-required-light.png"), fullPage: true });
  await validationDialog.press("Escape");
  assert.equal(await createTrigger.evaluate((button) => document.activeElement === button), true);
  checks.push("required name error announced, Escape closes dialog and restores focus");
  checks.push("real zero-project/zero-workflow UI without preseed");
  let postCount = 0, importCount = 0;
  page.on("request", (request) => { if (request.method() === "POST" && request.url().endsWith("/data-science-projects")) postCount++; if (request.method() === "POST" && request.url().endsWith("/local-data/import")) importCount++; });
  const firstId = await create(page, "Durable CSV project", "Saved description across browser and gateway restart.");
  assert.equal(postCount, 1);
  const first = await api(`/api/v1/data-science-projects/${firstId}`);
  assert.equal(first.name, "Durable CSV project");
  assert.equal(first.description, "Saved description across browser and gateway restart.");
  checks.push("gateway create and exact-ID authorized readback");
  await page.getByRole("button", { name: "Data", exact: true }).click();
  await page.getByLabel("Dataset ID", { exact: true }).fill("persisted-csv");
  await page.getByLabel("Approved local CSV path", { exact: true }).fill("local://data/raw/new-project.csv");
  await page.getByRole("button", { name: "Import Local Data", exact: true }).click();
  await page.getByText("Gateway action completed locally.").waitFor();
  const before = await api(`/api/v1/data-science-projects/${firstId}`);
  assert.equal(before.datasets.length, 1);
  assert.equal(before.datasets[0].checksumSha256, checksum);
  assert.equal(before.datasets[0].rowCount, 3);
  assert.equal(before.datasets[0].columnCount, 3);
  assert.equal(before.schemaContracts[0].columns.length, 3);
  assert.equal(importCount, 1);
  await page.screenshot({ path: join(evidence, "import-light.png"), fullPage: true });
  checks.push("real bounded CSV profile, count/schema/source checksum");
  await page.getByRole("button", { name: "Explorer", exact: true }).click();
  const secondId = await create(page, "Second project");
  assert.notEqual(firstId, secondId);
  await page.getByLabel("Open saved project").selectOption(firstId);
  await page.getByText(/Active project:/).waitFor();
  // Browser folder-picker availability varies; verify failure deterministically without creating another project.
  await page.evaluate(() => { window.showDirectoryPicker = async () => { throw new DOMException("permission denied", "NotAllowedError"); }; });
  await page.getByRole("button", { name: "Write optional folder" }).click();
  await page.getByText(/Optional folder permission failed/).waitFor();
  assert.equal(await page.getByLabel("Open saved project").inputValue(), firstId);
  assert.equal((await api("/api/v1/data-science-projects")).items.length, 2);
  checks.push("second creation, deliberate selection, independent optional-folder failure");
  await page.getByRole("button", { name: "Toggle color theme" }).click();
  assert.equal(await page.evaluate(() => getComputedStyle(document.documentElement).getPropertyValue("--bg").trim()), "#141622");
  await page.screenshot({ path: join(evidence, "explorer-dark.png"), fullPage: true });
  assert.deepEqual(session.errors, []);
  const storage = await session.context.storageState();
  await browser.close(); browser = undefined;
  await stop(gateway);
  gateway = startGateway("gateway-restarted");
  await waitReady(gateway, `${gatewayUrl}/health`, { Authorization: `Bearer ${authToken}` });
  session = await openBrowser(storage); page = session.page;
  let reopenImports = 0;
  page.on("request", (request) => { if (request.method() === "POST" && request.url().endsWith("/local-data/import")) reopenImports++; });
  await page.getByText(/Active project:/).waitFor();
  assert.equal(await page.getByLabel("Open saved project").inputValue(), firstId);
  await page.getByRole("button", { name: "Data", exact: true }).click();
  await page.getByText(/Full profiling details and preview are unavailable/).waitFor();
  const after = await api(`/api/v1/data-science-projects/${firstId}`);
  assert.deepEqual(after.datasets, before.datasets);
  assert.deepEqual(after.schemaContracts, before.schemaContracts);
  assert.equal(reopenImports, 0);
  assert.deepEqual(session.errors, []);
  await page.screenshot({ path: join(evidence, "reopened-dark.png"), fullPage: true });
  checks.push("browser and gateway process restart against same data root, exact metadata retained, zero reimport");
  await page.getByRole("button", { name: "Explorer", exact: true }).click();
  let createdPosts = 0;
  page.on("request", (request) => { if (request.method() === "POST" && request.url().endsWith("/data-science-projects")) createdPosts++; });
  // A real successful POST with its response lost must not be retried or matched by name.
  await page.route("**/api/v1/data-science-projects", async (route) => {
    if (route.request().method() !== "POST") { await route.continue(); return; }
    await route.fetch();
    await route.abort("failed");
  });
  await page.getByRole("button", { name: "Create project", exact: true }).click();
  await page.getByLabel("Project name", { exact: true }).fill("Lost response project");
  await page.getByRole("dialog").getByRole("button", { name: "Create project", exact: true }).click();
  await page.getByText(/Creation outcome is uncertain/).waitFor();
  assert.equal(createdPosts, 1);
  assert.equal(await page.getByRole("dialog").getByRole("button", { name: "Create project", exact: true }).isDisabled(), true);
  await page.getByRole("button", { name: "Inspect saved projects" }).click();
  await page.getByRole("button", { name: "Cancel", exact: true }).click();
  assert.equal(await page.getByLabel("Open saved project").inputValue(), firstId);
  assert.equal((await api("/api/v1/data-science-projects")).items.length, 3);
  await page.unroute("**/api/v1/data-science-projects");
  checks.push("real successful POST with lost response: inventory inspection, no blind retry or name reconciliation");
  // Late import completion writes its original project but must not replace the switched view.
  await page.getByRole("button", { name: "Data", exact: true }).click();
  let releaseImport;
  const held = new Promise((resolve) => { releaseImport = resolve; });
  let importStarted;
  const started = new Promise((resolve) => { importStarted = resolve; });
  await page.route("**/api/v1/local-data/import", async (route) => {
    const payload = route.request().postDataJSON();
    assert.equal(payload.projectId, firstId);
    const result = await route.fetch();
    importStarted();
    await held;
    await route.fulfill({ response: result });
  });
  await page.getByLabel("Dataset ID", { exact: true }).fill("late-import");
  await page.getByLabel("Approved local CSV path", { exact: true }).fill("local://data/raw/new-project.csv");
  await page.getByRole("button", { name: "Import Local Data", exact: true }).click();
  await started;
  await page.getByRole("button", { name: "Explorer", exact: true }).click();
  await page.getByLabel("Open saved project").selectOption(secondId);
  await page.getByText("Second project", { exact: true }).waitFor();
  releaseImport();
  await page.waitForLoadState("networkidle");
  await page.getByRole("button", { name: "Data", exact: true }).click();
  await page.getByText("No dataset imported into this project.", { exact: true }).waitFor();
  assert.equal((await api(`/api/v1/data-science-projects/${secondId}`)).datasets.length, 0);
  assert.equal((await api(`/api/v1/data-science-projects/${firstId}`)).datasets.length, 2);
  await page.unroute("**/api/v1/local-data/import");
  checks.push("late import bound to original ID, active view ignores completion after project switch");
  await page.setViewportSize({ width: 390, height: 844 });
  await page.getByRole("button", { name: "Explorer", exact: true }).click();
  const mobileLayout = await page.evaluate(() => ({ width: innerWidth, scrollWidth: document.documentElement.scrollWidth, overflowing: [...document.querySelectorAll("body *")].filter((element) => element.getBoundingClientRect().right > innerWidth + 1).slice(0, 15).map((element) => ({ tag: element.tagName, className: element.className, text: element.textContent?.slice(0, 80) })) }));
  assert.ok(mobileLayout.scrollWidth <= mobileLayout.width, JSON.stringify(mobileLayout));
  await page.screenshot({ path: join(evidence, "explorer-mobile-dark.png"), fullPage: true });
  await page.getByRole("button", { name: "Toggle color theme" }).click();
  assert.equal(await page.locator("html").getAttribute("data-theme"), "light");
  await page.screenshot({ path: join(evidence, "explorer-mobile-light.png"), fullPage: true });
  checks.push("mobile viewport has no horizontal overflow and switches themes");
  const summary = { status: "passed", checks, firstId, secondId, checksum, home, evidence, playwrightVersion: JSON.parse(readFileSync(join(root, "node_modules/playwright/package.json"))).version, browserVersion: browser.version(), referenceBoards: "not available in this environment; no visual board comparison claimed" };
  writeFileSync(join(evidence, "summary.json"), JSON.stringify(summary, null, 2) + "\n");
  console.log(JSON.stringify(summary));
} catch (error) {
  writeFileSync(join(evidence, "summary.json"), JSON.stringify({ status: "failed", checks, error: error.message, home }, null, 2) + "\n");
  throw error;
} finally {
  await browser?.close();
  for (const child of children) await stop(child);
}
