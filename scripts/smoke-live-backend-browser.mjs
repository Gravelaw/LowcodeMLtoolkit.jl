import { createHash, randomBytes } from "node:crypto";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawn, spawnSync } from "node:child_process";

const root = process.cwd();
const artifactRoot = join(root, "artifacts", "release-verification", "live-backend-browser");
const logRoot = join(artifactRoot, "logs");
const portBase = 20000 + Math.floor(Math.random() * 20000);
const gatewayPort = process.env.JULIAFLOW_LIVE_GATEWAY_PORT ?? String(portBase);
const frontendPort = process.env.JULIAFLOW_LIVE_FRONTEND_PORT ?? String(portBase + 1);
const gatewayUrl = `http://127.0.0.1:${gatewayPort}`;
const frontendUrl = `http://127.0.0.1:${frontendPort}`;
const authToken = randomBytes(32).toString("hex");
const npmBin = process.platform === "win32" ? "npm.cmd" : "npm";
const juliaBin = process.env.JULIA_EXE ?? "julia";
const juliaArgs = ["--compiled-modules=no", "--pkgimages=no"];
const children = [];

rmSync(artifactRoot, { recursive: true, force: true });
mkdirSync(logRoot, { recursive: true });

const liveHome = mkdtempSync(join(tmpdir(), "juliaflow-live-browser-"));
const juliaDepot = join(liveHome, "julia-depot");
const hubCacheRoot = join(liveHome, "hub-cache");
const artifactRootPath = join(hubCacheRoot, "artifacts");
const mirrorRoot = join(hubCacheRoot, "mirrors");
const artifactPath = join(artifactRootPath, "live-browser-proof-package.txt");
const artifactStorePath = join(hubCacheRoot, "artifact-store.json");
const mirrorRegistryPath = join(hubCacheRoot, "mirror-registry.json");
const hubPackageRef = "hub://offline/live-browser-proof";
const hubMirrorRef = "mirror://offline/live-browser-proof";
const juliaEnv = {
  JULIA_PKG_PRECOMPILE_AUTO: "0"
};
if (process.env.JULIAFLOW_LIVE_ISOLATED_DEPOT === "1") {
  juliaEnv.JULIA_DEPOT_PATH = juliaDepot;
}

function writeOfflineHubRegistries() {
  const artifactBytes = "JuliaFlow live browser offline Hub proof package\n";
  mkdirSync(artifactRootPath, { recursive: true });
  mkdirSync(mirrorRoot, { recursive: true });
  writeFileSync(artifactPath, artifactBytes);
  writeFileSync(
    artifactStorePath,
    JSON.stringify({ [hubPackageRef]: { package: artifactPath } }, null, 2)
  );
  writeFileSync(
    mirrorRegistryPath,
    JSON.stringify({ [hubMirrorRef]: mirrorRoot }, null, 2)
  );
  return `sha256:${createHash("sha256").update(artifactBytes).digest("hex")}`;
}

function writeManagedLiveDataset() {
  const rawRoot = join(liveHome, "data", "raw");
  const datasetPath = join(rawRoot, "customer-churn-local.csv");
  mkdirSync(rawRoot, { recursive: true });
  const rows = Array.from({ length: 30 }, (_, index) => {
    const churn = index % 3 === 0 ? 1 : 0;
    const contract = churn ? "monthly" : index % 2 === 0 ? "annual" : "two_year";
    const tenure = 3 + index * 2;
    const monthlyCharges = (48 + index * 2.35 + churn * 18).toFixed(2);
    return `C-${String(index + 1).padStart(4, "0")},${tenure},${monthlyCharges},${contract},${churn}`;
  });
  writeFileSync(datasetPath, ["customer_id,tenure_months,monthly_charges,contract_type,churn", ...rows, ""].join("\n"));
}

function spawnLogged(name, command, args, env = {}) {
  const logPath = join(logRoot, `${name}.log`);
  writeFileSync(logPath, `$ ${command} ${args.join(" ")}\n\n`);
  const shell = process.platform === "win32" && (command === "npm" || command.endsWith(".cmd"));
  const child = spawn(command, args, {
    cwd: root,
    env: { ...process.env, ...env },
    stdio: ["ignore", "pipe", "pipe"],
    windowsHide: true,
    detached: process.platform !== "win32",
    shell
  });
  child.stdout.on("data", (chunk) => {
    process.stdout.write(chunk);
    writeFileSync(logPath, chunk, { flag: "a" });
  });
  child.stderr.on("data", (chunk) => {
    process.stderr.write(chunk);
    writeFileSync(logPath, chunk, { flag: "a" });
  });
  children.push(child);
  return child;
}

function runLogged(name, command, args, env = {}) {
  const logPath = join(logRoot, `${name}.log`);
  const shell = process.platform === "win32" && (command === "npm" || command.endsWith(".cmd"));
  const result = spawnSync(command, args, {
    cwd: root,
    env: { ...process.env, ...env },
    encoding: "utf8",
    maxBuffer: 64 * 1024 * 1024,
    shell
  });
  const log = [
    `$ ${command} ${args.join(" ")}`,
    `exitCode=${result.status}`,
    "",
    "----- stdout -----",
    result.stdout ?? "",
    "",
    "----- stderr -----",
    result.stderr ?? "",
    "",
    "----- spawn error -----",
    result.error ? result.error.stack ?? result.error.message : "",
    ""
  ].join("\n");
  writeFileSync(logPath, log);
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.status !== 0) {
    throw new Error(`${name} failed with exit code ${result.status}`);
  }
}

async function waitFor(url, label, timeoutMs = 180000) {
  const deadline = Date.now() + timeoutMs;
  let lastError = "";
  while (Date.now() < deadline) {
    try {
      const response = await fetch(url);
      if (response.ok) return response;
      lastError = `${response.status} ${response.statusText}`;
    } catch (error) {
      lastError = error instanceof Error ? error.message : String(error);
    }
    await new Promise((resolveWait) => setTimeout(resolveWait, 1000));
  }
  throw new Error(`${label} did not become ready at ${url}: ${lastError}`);
}

async function postJson(url, body) {
  return fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json", Authorization: `Bearer ${authToken}` },
    body: JSON.stringify(body)
  });
}

function stopChildren() {
  for (const child of children.reverse()) {
    if (child.pid === undefined) continue;
    if (process.platform === "win32") {
      if (child.exitCode === null) spawnSync("taskkill.exe", ["/pid", String(child.pid), "/T", "/F"], { stdio: "ignore" });
    } else {
      // npm may exit before its Vite child. Signal the owned process group even
      // when the direct child has already exited, so inherited pipes can close.
      try { process.kill(-child.pid, "SIGTERM"); }
      catch (error) { if (error.code !== "ESRCH") throw error; }
    }
  }
}

try {
  const workflowPath = resolve(root, "tests", "contracts", "fixtures", "foundation.workflow.toml");
  const hubArtifactHash = writeOfflineHubRegistries();
  writeManagedLiveDataset();
  runLogged("julia-instantiate", juliaBin, [...juliaArgs, "--project=.", "-e", "using Pkg; Pkg.instantiate()"], juliaEnv);
  spawnLogged("gateway", juliaBin, [...juliaArgs, "--project=.", "scripts/run-api-gateway.jl"], {
    ...juliaEnv,
    JULIAFLOW_GATEWAY_HOST: "127.0.0.1",
    JULIAFLOW_GATEWAY_PORT: gatewayPort,
    JULIAFLOW_RUNTIME_MODE: "local-appliance",
    JULIAFLOW_AUTH_MODE: "required",
    JULIAFLOW_DEV_AUTH_TOKEN: authToken,
    JULIAFLOW_CORS_ALLOW_ORIGIN: frontendUrl,
    JULIAFLOW_LOCAL_PROFILE: "single-user",
    JULIAFLOW_APPLIANCE_BOOTSTRAP: "1",
    JULIAFLOW_HOME: liveHome,
    JULIAFLOW_DATA_ESTATE_ROOT: join(liveHome, "data"),
    JULIAFLOW_METADATA_ROOT: join(liveHome, "metadata"),
    JULIAFLOW_STORE_ROOT: join(liveHome, "metadata", "gateway-store"),
    JULIAFLOW_HUB_CACHE_ROOT: hubCacheRoot,
    JULIAFLOW_HUB_ARTIFACT_STORE: artifactStorePath,
    JULIAFLOW_HUB_MIRROR_REGISTRY: mirrorRegistryPath,
    JULIAFLOW_HUB_SANDBOX_EXECUTE: "0",
    JULIAFLOW_WORKFLOW_PATH: workflowPath
  });
  await waitFor(`${gatewayUrl}/health`, "gateway");

  const publishResponse = await postJson(
    `${gatewayUrl}/api/v1/workflows/wf-foundation/dashboards/dashboard-foundation/publish`,
    { visibility: "workspace" }
  );
  if (!publishResponse.ok) {
    throw new Error(`dashboard prepublish failed: ${publishResponse.status} ${await publishResponse.text()}`);
  }

  runLogged("frontend-build", npmBin, ["--workspace", "@juliaflow/frontend", "run", "build"]);
  spawnLogged("frontend", npmBin, ["--workspace", "@juliaflow/frontend", "run", "preview", "--", "--host", "127.0.0.1", "--port", frontendPort]);
  await waitFor(frontendUrl, "frontend");

  const result = await new Promise((resolveRun) => {
    const child = spawnLogged("playwright", npmBin, ["exec", "--", "playwright", "test", "--config", "playwright.live.config.ts"], {
      JULIAFLOW_LIVE_FRONTEND_URL: frontendUrl,
      JULIAFLOW_LIVE_GATEWAY_URL: gatewayUrl,
      JULIAFLOW_LIVE_AUTH_TOKEN: authToken,
      JULIAFLOW_LIVE_HUB_ARTIFACT_HASH: hubArtifactHash,
      JULIAFLOW_LIVE_HUB_PACKAGE_REF: hubPackageRef,
      JULIAFLOW_LIVE_HUB_MIRROR_REF: hubMirrorRef,
      JULIAFLOW_RUNTIME_MODE: "local-appliance"
    });
    child.on("exit", (code) => resolveRun(code ?? 1));
  });
  if (result !== 0) {
    throw new Error(`live-backend Playwright smoke failed with exit code ${result}`);
  }
  const gatewayLog = readFileSync(join(logRoot, "gateway.log"), "utf8");
  if (/Unexpected websocket server error|handle_connection handler error/.test(gatewayLog)) {
    throw new Error("Gateway reported a realtime connection lifecycle error");
  }
  if (gatewayLog.includes(authToken) || gatewayLog.includes(Buffer.from(authToken).toString("base64url"))) {
    throw new Error("Gateway log exposed an ephemeral authentication credential");
  }

  writeFileSync(join(artifactRoot, "summary.json"), `${JSON.stringify({
    status: "passed",
    gatewayUrl,
    frontendUrl,
    liveHome,
    finishedAt: new Date().toISOString()
  }, null, 2)}\n`);
  console.log(`Live-backend browser smoke passed. Artifacts: ${artifactRoot}`);
} catch (error) {
  writeFileSync(join(artifactRoot, "summary.json"), `${JSON.stringify({
    status: "failed",
    gatewayUrl,
    frontendUrl,
    liveHome,
    error: error instanceof Error ? error.message : String(error),
    finishedAt: new Date().toISOString()
  }, null, 2)}\n`);
  throw error;
} finally {
  stopChildren();
  if (process.env.JULIAFLOW_KEEP_LIVE_BROWSER_HOME !== "1") {
    rmSync(liveHome, { recursive: true, force: true });
  }
}
