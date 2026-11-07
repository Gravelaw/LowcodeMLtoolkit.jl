#!/usr/bin/env node
import { postgresReadiness } from "./ci/postgres.mjs";
import { existsSync, mkdirSync, statfsSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawn, spawnSync } from "node:child_process";
import { localAuthEnv } from "./lib/local-auth.mjs";
import { startDiagnosticProcess, waitForStartupJson, startupFailure } from "./lib/startup-diagnostics.mjs";
import { prepareJuliaRuntime } from "./lib/julia-runtime-bootstrap.mjs";

const ROOT_DIR = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const PROFILES = new Set(["single-user", "lab-team", "s3-compatible-local", "developer"]);
const ZONES = ["raw", "processed", "features", "models", "runs", "checkpoints", "dashboards", "logs", "extensions"];
const LOCAL_JULIA = join(ROOT_DIR, ".juliaup", "bin", "julia");

function juliaCommand() {
  if (process.env.JULIAFLOW_JULIA_CMD) {
    return process.env.JULIAFLOW_JULIA_CMD;
  }
  return existsSync(LOCAL_JULIA) ? LOCAL_JULIA : "julia";
}

function withJuliaEnv(env) {
  return {
    ...env,
    JULIAUP_DEPOT_PATH: env.JULIAUP_DEPOT_PATH ?? join(ROOT_DIR, ".juliaup"),
    JULIA_DEPOT_PATH: env.JULIA_DEPOT_PATH ?? join(ROOT_DIR, ".julia-depot")
  };
}

function parseArgs(argv) {
  const options = {
    profile: "single-user",
    home: "",
    gatewayPort: process.env.JULIAFLOW_GATEWAY_PORT ?? "8088",
    executionPort: process.env.JULIAFLOW_EXECUTION_PORT ?? "8090",
    frontendPort: process.env.JULIAFLOW_FRONTEND_PORT ?? "5173",
    host: process.env.JULIAFLOW_LOCAL_HOST ?? "127.0.0.1",
    startDeps: true,
    skipInstantiate: false,
    smoke: false,
    printConfig: false
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--profile") {
      options.profile = argv[++index] ?? "";
    } else if (arg.startsWith("--profile=")) {
      options.profile = arg.slice("--profile=".length);
    } else if (arg === "--home") {
      options.home = argv[++index] ?? "";
    } else if (arg.startsWith("--home=")) {
      options.home = arg.slice("--home=".length);
    } else if (arg === "--gateway-port") {
      options.gatewayPort = argv[++index] ?? "";
    } else if (arg.startsWith("--gateway-port=")) {
      options.gatewayPort = arg.slice("--gateway-port=".length);
    } else if (arg === "--execution-port") {
      options.executionPort = argv[++index] ?? "";
    } else if (arg.startsWith("--execution-port=")) {
      options.executionPort = arg.slice("--execution-port=".length);
    } else if (arg === "--frontend-port") {
      options.frontendPort = argv[++index] ?? "";
    } else if (arg.startsWith("--frontend-port=")) {
      options.frontendPort = arg.slice("--frontend-port=".length);
    } else if (arg === "--host") {
      options.host = argv[++index] ?? "";
    } else if (arg.startsWith("--host=")) {
      options.host = arg.slice("--host=".length);
    } else if (arg === "--no-deps") {
      options.startDeps = false;
    } else if (arg === "--skip-instantiate") {
      options.skipInstantiate = true;
    } else if (arg === "--smoke") {
      options.smoke = true;
    } else if (arg === "--print-config") {
      options.printConfig = true;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unsupported argument: ${arg}`);
    }
  }

  if (!PROFILES.has(options.profile)) {
    throw new Error(`Unsupported profile ${options.profile}. Expected one of ${[...PROFILES].join(", ")}`);
  }
  return options;
}

function printHelp() {
  console.log(`Usage: npm run dev:local -- [--profile single-user|lab-team|s3-compatible-local|developer]

Options:
  --home PATH             Override JULIAFLOW_HOME.
  --gateway-port PORT     Gateway port, default 8088.
  --execution-port PORT   Execution service port, default 8090.
  --frontend-port PORT    Frontend port, default 5173.
  --no-deps               Do not start optional Docker Compose profile dependencies.
  --skip-instantiate      Skip Julia Pkg.instantiate(); use only after dependencies are known installed.
  --smoke                 Start a bounded gateway smoke and exit after health/workflow checks.
  --print-config          Initialize local folders and print resolved config without starting services.
`);
}

function defaultHome() {
  if (process.env.JULIAFLOW_HOME) {
    return process.env.JULIAFLOW_HOME;
  }
  if (process.platform === "win32") {
    return join(process.env.LOCALAPPDATA ?? process.env.APPDATA ?? homedir(), "JuliaFlow");
  }
  return join(homedir(), ".juliaflow");
}

function numberOption(value, name) {
  const parsed = Number.parseInt(String(value), 10);
  if (!Number.isInteger(parsed) || parsed <= 0 || parsed > 65535) {
    throw new Error(`${name} must be a valid TCP port`);
  }
  return String(parsed);
}

function serviceUrls(options) {
  const gatewayPort = numberOption(options.gatewayPort, "gateway port");
  const executionPort = numberOption(options.executionPort, "execution port");
  const frontendPort = numberOption(options.frontendPort, "frontend port");
  const host = options.host || "127.0.0.1";
  return {
    gateway: `http://${host}:${gatewayPort}`,
    execution: `http://${host}:${executionPort}`,
    frontend: `http://${host}:${frontendPort}`,
    streamWorker: "process",
    gpuWorker: "process"
  };
}

function initLocalHome(options) {
  const home = resolve(options.home || defaultHome());
  const dataRoot = resolve(process.env.JULIAFLOW_DATA_ESTATE_ROOT ?? join(home, "data"));
  const metadataRoot = resolve(process.env.JULIAFLOW_METADATA_ROOT ?? join(home, "metadata"));
  const storeRoot = resolve(process.env.JULIAFLOW_STORE_ROOT ?? join(metadataRoot, "gateway-store"));
  const hubCacheRoot = resolve(process.env.JULIAFLOW_HUB_CACHE_ROOT ?? join(home, "hub-cache"));
  const hubArtifactCacheRoot = resolve(process.env.JULIAFLOW_HUB_ARTIFACT_CACHE_ROOT ?? join(hubCacheRoot, "artifacts"));
  const hubArtifactStorePath = resolve(process.env.JULIAFLOW_HUB_ARTIFACT_STORE ?? join(hubCacheRoot, "artifact-store.json"));
  const hubMirrorRegistryPath = resolve(process.env.JULIAFLOW_HUB_MIRROR_REGISTRY ?? join(hubCacheRoot, "mirror-registry.json"));

  mkdirSync(home, { recursive: true });
  mkdirSync(metadataRoot, { recursive: true });
  mkdirSync(storeRoot, { recursive: true });
  mkdirSync(hubCacheRoot, { recursive: true });
  mkdirSync(hubArtifactCacheRoot, { recursive: true });
  if (!existsSync(hubArtifactStorePath)) {
    writeFileSync(hubArtifactStorePath, "{}\n");
  }
  if (!existsSync(hubMirrorRegistryPath)) {
    writeFileSync(hubMirrorRegistryPath, "{}\n");
  }

  const zones = ZONES.map((name) => {
    const path = join(dataRoot, name);
    mkdirSync(path, { recursive: true });
    return { name, path };
  });

  let freeDiskBytes = null;
  try {
    const stats = statfsSync(dataRoot);
    freeDiskBytes = Number(stats.bavail) * Number(stats.bsize);
  } catch {
    freeDiskBytes = null;
  }

  return {
    profile: options.profile,
    home,
    dataRoot,
    metadataRoot,
    storeRoot,
    hubCacheRoot,
    hubArtifactCacheRoot,
    hubArtifactStorePath,
    hubMirrorRegistryPath,
    zones,
    freeDiskBytes,
    serviceUrls: serviceUrls(options)
  };
}

function baseEnv(config, options) {
  const env = {
    ...process.env,
    JULIAFLOW_APPLIANCE_BOOTSTRAP: "1",
    JULIAFLOW_LOCAL_PROFILE: config.profile,
    JULIAFLOW_HOME: config.home,
    JULIAFLOW_DATA_ESTATE_ROOT: config.dataRoot,
    JULIAFLOW_METADATA_ROOT: config.metadataRoot,
    JULIAFLOW_STORE_ROOT: config.storeRoot,
    JULIAFLOW_HUB_CACHE_ROOT: config.hubCacheRoot,
    JULIAFLOW_HUB_ARTIFACT_STORE: config.hubArtifactStorePath,
    JULIAFLOW_HUB_MIRROR_REGISTRY: config.hubMirrorRegistryPath,
    JULIAFLOW_GATEWAY_HOST: options.host,
    JULIAFLOW_GATEWAY_PORT: numberOption(options.gatewayPort, "gateway port"),
    JULIAFLOW_EXECUTION_HOST: options.host,
    JULIAFLOW_EXECUTION_PORT: numberOption(options.executionPort, "execution port"),
    JULIAFLOW_FRONTEND_PORT: numberOption(options.frontendPort, "frontend port"),
    JULIAFLOW_LOCAL_GATEWAY_URL: config.serviceUrls.gateway,
    JULIAFLOW_LOCAL_EXECUTION_URL: config.serviceUrls.execution,
    JULIAFLOW_LOCAL_FRONTEND_URL: config.serviceUrls.frontend,
    JULIAFLOW_GATEWAY_BACKEND: config.profile === "lab-team" ? "postgres" : "file",
    JULIAFLOW_WORKFLOW_PATH: join(ROOT_DIR, "tests", "contracts", "fixtures", "foundation.workflow.toml"),
    JULIAFLOW_EVENT_BACKBONE_MODE: process.env.JULIAFLOW_EVENT_BACKBONE_MODE ?? "dual_write",
    JULIAFLOW_STREAM_WORKER_MODE: process.env.JULIAFLOW_STREAM_WORKER_MODE ?? "process",
    JULIAFLOW_GPU_WORKER_MODE: process.env.JULIAFLOW_GPU_WORKER_MODE ?? "process",
    ...localAuthEnv(process.env, config.serviceUrls.frontend),
    VITE_JULIAFLOW_GATEWAY_BASE_URL: config.serviceUrls.gateway
  };

  if (config.profile === "lab-team" && !env.JULIAFLOW_DATABASE_URL) {
    env.JULIAFLOW_DATABASE_URL = "postgresql://juliaflow:juliaflow@127.0.0.1:5432/juliaflow";
  }
  if (config.profile === "s3-compatible-local") {
    env.JULIAFLOW_MINIO_ENDPOINT = env.JULIAFLOW_MINIO_ENDPOINT ?? "http://127.0.0.1:9000";
  }
  return env;
}

function spawnProcess(label, command, args, env) {
  console.log(`[dev:local] starting ${label}`);
  const child = spawn(command, args, {
    cwd: ROOT_DIR,
    env,
    stdio: ["ignore", "pipe", "pipe"],
    shell: false
  });
  child.stdout.on("data", (chunk) => process.stdout.write(`[${label}] ${chunk}`));
  child.stderr.on("data", (chunk) => process.stderr.write(`[${label}] ${chunk}`));
  return child;
}

function ensureJuliaDependencies(env, options) {
  if (options.skipInstantiate || env.JULIAFLOW_SKIP_INSTANTIATE === "1") {
    console.log("[dev:local] skipping Julia dependency instantiation");
    return;
  }
  // Install declared dependencies before the separately bounded preparation phase.
  console.log("[dev:local] ensuring Julia dependencies");
  const result = spawnSync(
    juliaCommand(),
    ["--project=.", "-e", "using Pkg; Pkg.instantiate()"],
    {
      cwd: ROOT_DIR,
      env: withJuliaEnv(env),
      stdio: "inherit",
      shell: false
    }
  );
  if (result.status !== 0) {
    throw new Error("Julia dependency bootstrap failed; rerun after fixing Julia packages, or pass --skip-instantiate only when dependencies are already installed");
  }
}

function startDeps(profile, startDeps) {
  if (!startDeps || profile === "single-user" || profile === "developer") {
    return null;
  }
  const services = profile === "lab-team" ? ["postgres"] : ["minio"];
  const child = spawnProcess("compose", "docker", ["compose", "-f", "infra/docker/compose.dev.yml", "up", "-d", ...services], process.env);
  return new Promise((resolvePromise, rejectPromise) => {
    child.on("exit", async (code) => {
      if (code !== 0) {
        rejectPromise(new Error(`docker compose exited with ${code}`));
        return;
      }
      try {
        if (profile === "lab-team") {
          await waitForPostgres();
        }
        resolvePromise();
      } catch (error) {
        rejectPromise(error);
      }
    });
  });
}

async function waitForPostgres(timeoutMs = 30000) {
  const probe = postgresReadiness();
  const started = Date.now();
  let lastError = null;
  while (Date.now() - started < timeoutMs) {
    const result = spawnSync(
      probe.command,
      probe.args,
      { cwd: ROOT_DIR, env: process.env, stdio: "pipe", shell: false }
    );
    if (result.status === 0) {
      console.log("[dev:local] postgres ready");
      return;
    }
    lastError = new Error(String(result.stderr || result.stdout || `pg_isready exited with ${result.status}`).trim());
    await new Promise((resolvePromise) => setTimeout(resolvePromise, 500));
  }
  throw new Error(`Timed out waiting for Postgres readiness: ${lastError?.message ?? "pg_isready did not succeed"}`);
}

async function runSmoke(config, env) {
  const julia = juliaCommand();
  console.log("[dev:local] starting api-gateway");
  // Match the compiled-module policy used by normal dev:local startup.
  const gateway = startDiagnosticProcess(
    julia,
    ["--project=.", "scripts/run-api-gateway.jl"],
    { cwd: ROOT_DIR, env: withJuliaEnv(env) }
  );
  let failure;
  let stateAtFailure;
  let cleanupError;
  try {
    const startupTimeoutMs = config.profile === "lab-team" ? 90000 : 60000;
    const health = await waitForStartupJson(`${config.serviceUrls.gateway}/health`, startupTimeoutMs, {
      process: gateway, ready: (payload) => payload?.status === "ok" && payload?.metadataReady === true
    });
    console.log(`[dev:local] listener ready endpoint=${config.serviceUrls.gateway}/health elapsedMs=${gateway.snapshot().elapsedMs}`);
    const token = env.JULIAFLOW_AUTH_MODE === "oidc" ? env.VITE_JULIAFLOW_OIDC_ACCESS_TOKEN : env.JULIAFLOW_DEV_AUTH_TOKEN;
    const headers = token ? { Authorization: `Bearer ${token}` } : {};
    const workflows = await waitForStartupJson(`${config.serviceUrls.gateway}/api/v1/workflows`, 30000, {
      headers, process: gateway, ready: (payload) => Array.isArray(payload?.items)
    });
    if (health.localProfile !== config.profile) {
      throw new Error(`Expected localProfile ${config.profile}, got ${health.localProfile}`);
    }
    const expectedMetadataBackend = config.profile === "lab-team" ? "postgres" : "file";
    const expectedMetadataMode = config.profile === "lab-team" ? "lab-team" : "single-user";
    if (health.metadataBackend !== expectedMetadataBackend || health.metadataMode !== expectedMetadataMode) {
      throw new Error(`Expected metadata ${expectedMetadataMode}/${expectedMetadataBackend}, got ${health.metadataMode}/${health.metadataBackend}`);
    }
    if (health.metadataReady !== true) {
      throw new Error("Gateway health did not report metadata readiness");
    }
    if (expectedMetadataBackend === "postgres" && health.metadataSchemaStatus !== "ready") {
      throw new Error("Gateway health did not report ready Postgres metadata schema");
    }
    if (expectedMetadataBackend === "file" && health.metadataConcurrencyStatus !== "single_writer") {
      throw new Error("Gateway health did not report single-writer file metadata concurrency");
    }
    if (expectedMetadataBackend === "postgres" && health.metadataConcurrencyStatus !== "shared_postgres_ready") {
      throw new Error("Gateway health did not report shared Postgres metadata concurrency");
    }
    for (const capability of ["workflows", "executions", "authPolicy", "authDirectory", "auditEvents", "consumerCursors", "publishedDashboards"]) {
      if (!health.metadataCapabilities?.includes(capability)) {
        throw new Error(`Gateway health missing metadata capability ${capability}`);
      }
    }
    if (!Array.isArray(health.dataEstateZones) || health.dataEstateZones.length !== ZONES.length) {
      throw new Error("Gateway health did not report all local data-estate zones");
    }
    if (health.dataEstateManifestReady !== true || !Array.isArray(health.dataEstateManifestChecksums)) {
      throw new Error("Gateway health did not report managed data-estate manifests");
    }
    if (!health.dataEstateArtifactFormats?.includes("arrow_ipc") || !health.dataEstateArtifactFormats?.includes("parquet")) {
      throw new Error("Gateway health did not report Arrow/Parquet artifact formats");
    }
    if (health.dataEstateCleanupStatus !== "ready" || health.dataEstateBackupStatus !== "ready") {
      throw new Error("Gateway health did not report cleanup and backup hooks as ready");
    }
    if (health.dataEstateDuckdbStatus !== "ready") {
      throw new Error("Gateway health did not report DuckDB query binding as ready");
    }
    if (health.hardwareProfileStatus !== "ready") {
      throw new Error(`Gateway health did not report ready hardware profile: ${health.hardwareProfileStatus}`);
    }
    if (!["cpu", "cuda", "simulated_cuda"].includes(health.hardwareSelectedBackend)) {
      throw new Error(`Gateway health reported unsupported hardware backend: ${health.hardwareSelectedBackend}`);
    }
    if (health.cpuSchedulerPolicy !== "bounded_threads") {
      throw new Error(`Gateway health did not report bounded CPU scheduler policy: ${health.cpuSchedulerPolicy}`);
    }
    if (!Number.isInteger(health.cpuWorkerConcurrency) || health.cpuWorkerConcurrency < 1 || health.cpuWorkerConcurrency > health.cpuThreadCount) {
      throw new Error("Gateway health did not report bounded CPU worker concurrency");
    }
    if (!Number.isInteger(health.cpuMemoryLimitBytes) || health.cpuMemoryLimitBytes < 1 || health.cpuMemoryLimitBytes > health.totalMemoryBytes) {
      throw new Error("Gateway health did not report bounded CPU memory limit");
    }
    if (!Number.isInteger(health.gpuHardwareDeviceCount) || !Number.isInteger(health.gpuSimulatedDeviceCount)) {
      throw new Error("Gateway health did not report GPU hardware/simulated device counts");
    }
    if (!Array.isArray(health.gpuDeviceSummaries)) {
      throw new Error("Gateway health did not report GPU device summaries");
    }
    if (health.explainabilityEvidence?.status !== "ready") {
      throw new Error("Gateway health did not report ready explainability evidence");
    }
    if (health.explainabilityEvidence.datasetCard?.datasetId !== "foundation-sales-sample") {
      throw new Error("Gateway health did not report foundation dataset card evidence");
    }
    if (health.explainabilityEvidence.modelCard?.kind !== "deterministic_linear_baseline") {
      throw new Error("Gateway health did not report deterministic model card evidence");
    }
    if (!Array.isArray(health.explainabilityEvidence.explanation?.featureImportance) || health.explainabilityEvidence.explanation.featureImportance.length < 1) {
      throw new Error("Gateway health did not report feature-importance evidence");
    }
    if (health.hubCacheStatus !== "ready" || health.hubOfflineInstallReady !== true) {
      throw new Error("Gateway health did not report ready offline Hub cache");
    }
    if (health.hubArtifactStorePath !== config.hubArtifactStorePath || health.hubMirrorRegistryPath !== config.hubMirrorRegistryPath) {
      throw new Error("Gateway health did not report local Hub artifact/mirror registry paths");
    }
    if (!Number.isInteger(health.hubBundledExtensionCount) || health.hubBundledExtensionCount < 1) {
      throw new Error("Gateway health did not report bundled Hub extensions");
    }
    if (!["not_requested", "requested", "ready", "unavailable"].includes(health.gpuCudaStatus)) {
      throw new Error(`Gateway health reported unsupported CUDA status: ${health.gpuCudaStatus}`);
    }
    if (!workflows.items?.some((item) => item.workflowId === "wf-foundation")) {
      throw new Error("Sample foundation workflow was not available");
    }
    console.log("[dev:local] smoke passed");
    console.log(JSON.stringify({ profile: config.profile, home: config.home, workflowCount: workflows.items.length }, null, 2));
  } catch (error) {
    failure = error;
    stateAtFailure = gateway.snapshot();
  } finally {
    try { await gateway.stop(); } catch (error) { cleanupError = error; }
  }
  if (failure || cleanupError) throw startupFailure(failure ?? cleanupError, gateway, stateAtFailure, cleanupError);
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const config = initLocalHome(options);
  const env = baseEnv(config, options);

  if (options.printConfig) {
    console.log(JSON.stringify(config, null, 2));
    return;
  }

  await startDeps(options.profile, options.startDeps);
  ensureJuliaDependencies(env, options);
  console.log("[dev:local] preparing Julia runtime before service startup");
  const preparation = new AbortController();
  const cancelPreparation = () => preparation.abort();
  process.once("SIGINT", cancelPreparation);
  process.once("SIGTERM", cancelPreparation);
  try {
    await prepareJuliaRuntime({ command: juliaCommand(), cwd: ROOT_DIR, env: withJuliaEnv(env), signal: preparation.signal });
  } finally {
    process.removeListener("SIGINT", cancelPreparation);
    process.removeListener("SIGTERM", cancelPreparation);
  }

  if (options.smoke) {
    await runSmoke(config, env);
    return;
  }

  const children = [
    spawnProcess("api-gateway", juliaCommand(), ["--project=.", "scripts/run-api-gateway.jl"], withJuliaEnv(env)),
    spawnProcess("execution-service", juliaCommand(), ["--project=.", "scripts/run-execution-service.jl"], withJuliaEnv(env)),
    spawnProcess("stream-worker", juliaCommand(), ["--project=.", "scripts/run-stream-worker.jl"], withJuliaEnv(env)),
    spawnProcess("gpu-worker", juliaCommand(), ["--project=.", "scripts/run-gpu-worker.jl"], withJuliaEnv(env)),
    spawnProcess("frontend", process.execPath, ["scripts/run-local-frontend.mjs"], env)
  ];

  console.log(`[dev:local] profile=${config.profile}`);
  console.log(`[dev:local] runtime=${env.JULIAFLOW_RUNTIME_MODE} auth=${env.JULIAFLOW_AUTH_MODE}`);
  console.log(`[dev:local] home=${config.home}`);
  console.log(`[dev:local] gateway=${config.serviceUrls.gateway}`);
  console.log(`[dev:local] frontend=${config.serviceUrls.frontend}`);

  const stop = () => {
    for (const child of children) {
      child.kill("SIGTERM");
    }
  };
  process.on("SIGINT", () => {
    stop();
    process.exit(130);
  });
  process.on("SIGTERM", () => {
    stop();
    process.exit(143);
  });

  await new Promise((resolvePromise, rejectPromise) => {
    for (const child of children) {
      child.on("exit", (code) => {
        if (code !== 0 && code !== null) {
          stop();
          rejectPromise(new Error(`Local service exited with ${code}`));
        }
      });
    }
  });
}

main().catch((error) => {
  console.error(`[dev:local] ${error.message}`);
  process.exitCode = 1;
});
