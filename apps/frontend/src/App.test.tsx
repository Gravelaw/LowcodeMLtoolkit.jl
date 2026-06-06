import { act, cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import * as matchers from "@testing-library/jest-dom/matchers";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

expect.extend(matchers);
import App from "./App";

class MockWebSocket {
  static instances: MockWebSocket[] = [];

  readonly listeners = new Map<string, Set<(event?: unknown) => void>>();
  readonly sentMessages: string[] = [];
  readonly url: string;

  constructor(url: string) {
    this.url = url;
    MockWebSocket.instances.push(this);
  }

  addEventListener(type: string, listener: (event?: unknown) => void) {
    const listeners = this.listeners.get(type) ?? new Set();
    listeners.add(listener);
    this.listeners.set(type, listeners);
  }

  removeEventListener(type: string, listener: (event?: unknown) => void) {
    this.listeners.get(type)?.delete(listener);
  }

  send(message: string) {
    this.sentMessages.push(message);
  }

  close() {
    this.emit("close");
  }

  emit(type: string, event?: unknown) {
    for (const listener of this.listeners.get(type) ?? []) {
      listener(event);
    }
  }
}

function hubVerification(verified = true, blockers: string[] = []) {
  const status = verified ? "passed" : blockers.length > 0 ? "failed" : "pending";
  return {
    verified,
    sandbox: { status, details: "test sandbox verification", blockers, checkedAt: "2026-05-08T00:00:00Z" },
    artifacts: { status, details: "test artifact verification", blockers, checkedAt: "2026-05-08T00:00:00Z" },
    mirrors: { status, details: "test mirror verification", blockers, checkedAt: "2026-05-08T00:00:00Z" },
    blockers,
    evaluatedAt: "2026-05-08T00:00:00Z"
  };
}

function explainabilityEvidencePayload() {
  return {
    status: "ready",
    generatedAt: "2026-06-04T00:00:00Z",
    workflowId: "wf-live-contracts",
    checkpointTag: "cp/02-alpha-core",
    datasetCard: { datasetId: "foundation-sales-sample", sourceUri: "tests/contracts/fixtures/foundation.workflow.toml", checksumSha256: "abc123", schemaSummary: [{ name: "amount", type: "float64" }], rowCount: 3, limitations: ["local fixture"] },
    modelCard: { modelId: "foundation-linear-baseline", kind: "deterministic_linear_baseline", target: "amount", config: { seed: 42 }, metrics: { mae: 1.25, r2: 0.91 }, limitations: ["fixture model"] },
    explanation: { method: "deterministic_feature_contribution", featureImportance: [{ feature: "amount", importance: 0.62 }, { feature: "region", importance: 0.28 }, { feature: "window", importance: 0.10 }], localExample: { rowId: "foundation-row-1", prediction: 124.5, contributions: [] }, warnings: ["local only"] },
    reproducibilityBundleReady: true
  };
}

function healthPayload(overrides: Record<string, unknown> = {}) {
  return {
    service: "api-gateway",
    status: "ok",
    localProfile: "single-user",
    localHome: "/tmp/juliaflow",
    metadataMode: "single-user",
    metadataBackend: "file",
    metadataRoot: "/tmp/juliaflow/metadata",
    metadataReady: true,
    metadataSchemaStatus: "not_required",
    metadataConcurrencyStatus: "single_writer",
    metadataCapabilities: ["workflows", "executions", "authPolicy", "authDirectory", "auditEvents", "consumerCursors", "publishedDashboards"],
    dataEstateRoot: "/tmp/juliaflow/data",
    dataEstateZones: [
      { name: "raw", path: "/tmp/juliaflow/data/raw", exists: true, writable: true },
      { name: "processed", path: "/tmp/juliaflow/data/processed", exists: true, writable: true },
      { name: "features", path: "/tmp/juliaflow/data/features", exists: true, writable: true },
      { name: "models", path: "/tmp/juliaflow/data/models", exists: true, writable: true },
      { name: "runs", path: "/tmp/juliaflow/data/runs", exists: true, writable: true },
      { name: "checkpoints", path: "/tmp/juliaflow/data/checkpoints", exists: true, writable: true },
      { name: "dashboards", path: "/tmp/juliaflow/data/dashboards", exists: true, writable: true },
      { name: "logs", path: "/tmp/juliaflow/data/logs", exists: true, writable: true },
      { name: "extensions", path: "/tmp/juliaflow/data/extensions", exists: true, writable: true }
    ],
    dataEstateReady: true,
    dataEstateManaged: true,
    dataEstateManifestPath: "/tmp/juliaflow/data/_manifests",
    dataEstateManifestReady: true,
    dataEstateManifestChecksums: [{ zone: "raw", path: "/tmp/juliaflow/data/_manifests/raw.json", exists: true, checksumSha256: "abc123" }],
    dataEstateArtifactFormats: ["arrow_ipc", "parquet"],
    dataEstateQuotaBytes: 10000000000,
    dataEstateUsedBytes: 2048,
    dataEstateCleanupStatus: "ready",
    dataEstateBackupRoot: "/tmp/juliaflow/data/_backups",
    dataEstateBackupStatus: "ready",
    dataEstateDuckdbStatus: "ready",
    dataEstateDuckdbQueryPath: "/tmp/juliaflow/data/_duckdb/local-data-estate.sql",
    freeDiskStatus: "available",
    freeDiskBytes: 1024 * 1024 * 1024,
    localServiceUrls: {
      gateway: "http://127.0.0.1:8088",
      execution: "http://127.0.0.1:8090",
      frontend: "http://127.0.0.1:5173",
      streamWorker: "process",
      gpuWorker: "process"
    },
    postgresProfileStatus: "not_required",
    minioProfileStatus: "not_required",
    cloudCredentialsRequired: false,
    cpuThreadCount: 8,
    totalMemoryBytes: 16 * 1024 * 1024 * 1024,
    freeMemoryBytes: 8 * 1024 * 1024 * 1024,
    hardwareProfileStatus: "ready",
    hardwareSelectedBackend: "cpu",
    cpuSchedulerPolicy: "bounded_threads",
    cpuWorkerConcurrency: 4,
    cpuMemoryLimitBytes: 6 * 1024 * 1024 * 1024,
    gpuReadinessStatus: "cpu_fallback",
    gpuFallbackReason: "no_supported_gpu_required_for_local_bootstrap",
    gpuCudaStatus: "not_requested",
    gpuHardwareDeviceCount: 0,
    gpuSimulatedDeviceCount: 0,
    gpuTotalVramBytes: 0,
    gpuDeviceSummaries: [],
    explainabilityEvidence: explainabilityEvidencePayload(),
    repositoryBackend: "file",
    storeRoot: "/tmp/juliaflow",
    workflowCount: 0,
    checkpointCount: 0,
    executionCount: 0,
    realtimeTransport: "jsonrpc_websocket",
    eventBackboneMode: "dual_write",
    eventConsumerPollMs: 250,
    streamWorkerMode: "inline",
    gpuWorkerMode: "process",
    gpuRegistryDeviceCount: 0,
    gpuFallbackAvailable: true,
    eventLogSize: 0,
    latestEventSequence: 0,
    gatewayConsumerCursor: 0,
    gatewayConsumerLag: 0,
    eventConsumerCatchupPercent: 100,
    activeStreamExecutions: 0,
    queuedGpuExecutions: 0,
    queuedStreamExecutions: 0,
    activeGpuExecutions: 0,
    gpuWorkerOwnedExecutions: 0,
    queuedExecutionsTotal: 0,
    runningExecutionsTotal: 0,
    ...overrides
  };
}

describe("App", () => {
  beforeEach(() => {
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
    MockWebSocket.instances = [];
    delete window.__JULIAFLOW_CONFIG__;
    window.history.replaceState({}, "", "/");
  });

  afterEach(() => {
    cleanup();
  });

  it("uses runtime gateway config before Vite env fallback", async () => {
    vi.stubEnv("VITE_JULIAFLOW_GATEWAY_BASE_URL", "http://gateway-env.test");
    window.__JULIAFLOW_CONFIG__ = { gatewayBaseUrl: "http://gateway-runtime.test" };
    const fetchMock = vi.fn().mockResolvedValue(new Response(JSON.stringify([])));
    vi.stubGlobal("fetch", fetchMock);

    render(<App />);

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledWith("http://gateway-runtime.test/api/v1/workflows", expect.any(Object));
    });
  });

  it("renders the route shell and canvas-first authoring surface", () => {
    render(<App />);

    expect(screen.getByText(/Workflow Canvas/i)).toBeInTheDocument();
    expect(screen.getByText(/Authoring-first workflow builder/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /save workflow/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /run workflow/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /open bi workspace/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /add flow variable/i })).toBeInTheDocument();
    fireEvent.click(screen.getByRole("tab", { name: /validation/i }));
    expect(screen.getByText(/Components\/control-flow/i)).toBeInTheDocument();
    expect(screen.getByText(/Preparation Container/i)).toBeInTheDocument();
    expect(screen.getByText(/Region Switch/i)).toBeInTheDocument();
  });

  it("lets authors drag canvas nodes to new positions", () => {
    render(<App />);

    const node = screen.getByRole("button", { name: /Select CSV Reader/i });
    expect(node).toHaveStyle({ left: "36px", top: "44px" });

    fireEvent.mouseDown(node, { clientX: 100, clientY: 100 });
    fireEvent.mouseMove(window, { clientX: 160, clientY: 150 });
    fireEvent.mouseUp(window);

    expect(node).toHaveStyle({ left: "96px", top: "94px" });
    expect(screen.getByText(/Unsaved draft changes/i)).toBeInTheDocument();
  });

  it("lets authors add nodes, fix connections, save, and run in demo mode", async () => {
    render(<App />);

    fireEvent.change(screen.getByLabelText(/Connection peer node/i), {
      target: { value: "node-bi-outlet" }
    });
    fireEvent.change(screen.getByLabelText(/Connection peer port/i), {
      target: { value: "score_model" }
    });
    expect(screen.getAllByText(/Type mismatch/i).length).toBeGreaterThan(0);

    fireEvent.click(screen.getByRole("button", { name: /Add Join Tables to workflow/i }));
    expect(screen.getByRole("button", { name: /Select Join Tables 2/i })).toBeInTheDocument();
    expect(screen.getByText(/linked into the current graph slice/i)).toBeInTheDocument();

    fireEvent.click(screen.getAllByRole("button", { name: /Add BI Outlet to workflow/i })[0]);
    expect(screen.getByRole("button", { name: /Select BI Outlet 2/i })).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/Connection direction/i), {
      target: { value: "incoming" }
    });
    fireEvent.change(screen.getByLabelText(/Connection peer node/i), {
      target: { value: "node-join-2" }
    });
    fireEvent.change(screen.getByLabelText(/Connection anchor port/i), {
      target: { value: "dataset" }
    });
    fireEvent.change(screen.getByLabelText(/Connection peer port/i), {
      target: { value: "joined" }
    });

    fireEvent.click(screen.getByRole("button", { name: /add connection/i }));

    fireEvent.change(screen.getByLabelText(/Variable default batch_window/i), {
      target: { value: "2026-Q3" }
    });
    expect(screen.getByDisplayValue("2026-Q3")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /save workflow/i }));
    await waitFor(() => {
      expect(screen.getByText(/Draft saved locally/i)).toBeInTheDocument();
    });

    fireEvent.click(screen.getByRole("button", { name: /run workflow/i }));
    await waitFor(() => {
      expect(screen.getAllByText(/Demo canvas run/i).length).toBeGreaterThan(0);
    });
  });

  it("moves dashboard authoring into dedicated BI workspace and publishes a viewer snapshot", async () => {
    render(<App />);

    fireEvent.click(screen.getByRole("button", { name: /DashboardDraft and published BI surfaces/i }));

    expect(screen.getByRole("button", { name: /remove dashboard/i })).toBeDisabled();
    expect(screen.getByLabelText(/Dashboard name/i)).toHaveValue("Ops Forecast Overview");

    fireEvent.click(screen.getByRole("button", { name: /duplicate dashboard/i }));
    expect(screen.getByText(/Duplicated dashboard draft/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /remove dashboard/i })).not.toBeDisabled();
    expect(screen.getByRole("button", { name: /Ops Forecast Overview copy/i })).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /remove dashboard/i }));
    expect(screen.getByText(/Removed dashboard draft/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /remove dashboard/i })).toBeDisabled();

    fireEvent.change(screen.getByLabelText(/Dashboard dataset key/i), {
      target: { value: "exec_dataset" }
    });
    expect(screen.getByLabelText(/Dashboard dataset key/i)).toHaveValue("exec_dataset");

    fireEvent.click(screen.getByRole("button", { name: /Add chart/i }));
    expect(screen.getByText(/Added dashboard chart/i)).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/Publish visibility/i), {
      target: { value: "public" }
    });
    fireEvent.click(screen.getByRole("button", { name: /^Publish$/i }));

    await waitFor(() => {
      expect(screen.getByText(/Published dashboards/i)).toBeInTheDocument();
    });

    expect(screen.getByText(/read_only/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /copy share link/i })).toBeInTheDocument();
  });

  it("loads discovery metadata and hub trust\/upgrade state from gateway", async () => {
    vi.stubEnv("VITE_JULIAFLOW_GATEWAY_BASE_URL", "http://gateway.test");
    vi.stubGlobal("WebSocket", MockWebSocket as unknown as typeof WebSocket);

    let savedAuthPolicy: unknown = null;
    let savedAuthDirectory: unknown = null;
    let publishedHubManifest: unknown = null;
    const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      const url = String(input);

      if (url.endsWith("/health")) {
        return new Response(JSON.stringify(healthPayload({
          repositoryBackend: "postgres",
          workflowCount: 1,
          checkpointCount: 2,
          executionCount: 1,
          streamWorkerMode: "process",
          eventLogSize: 12,
          latestEventSequence: 12,
          gatewayConsumerCursor: 10,
          gatewayConsumerLag: 2,
          eventConsumerCatchupPercent: 83,
          activeStreamExecutions: 1,
          queuedGpuExecutions: 1,
          queuedStreamExecutions: 1,
          activeGpuExecutions: 1,
          gpuWorkerOwnedExecutions: 1,
          queuedExecutionsTotal: 1,
          runningExecutionsTotal: 1,
          authMode: "oidc",
          oidcDiscoveryConfigured: true,
          oidcJwksConfigured: true,
          oidcAllowedAlgorithms: ["HS256"]
        })));
      }

      if (url.endsWith("/api/v1/workflows") && init?.method === "GET") {
        return new Response(
          JSON.stringify({
            items: [
              {
                workflowId: "wf-live-contracts",
                name: "Live Contracts",
                version: "0.2.0",
                nodeCount: 4,
                latestCheckpoint: "cp/02-alpha-core",
                graphRevision: 2,
                dashboardCount: 1,
                runMode: "batch"
              }
            ]
          })
        );
      }

      if (url.endsWith("/api/v1/workflows/wf-live-contracts") && init?.method === "GET") {
        return new Response(
          JSON.stringify({
            workflowId: "wf-live-contracts",
            name: "Live Contracts",
            version: "0.2.0",
            nodeCount: 4,
            connectionCount: 3,
            flowVariableCount: 2,
            biOutletCount: 1,
            dashboardCount: 1,
            graphRevision: 2,
            runMode: "batch",
            nodes: sampleNodes(),
            connections: sampleConnections(),
            flowVariables: sampleFlowVariables(),
            biOutlets: [],
            dashboards: sampleDashboards(),
            runtime: { runMode: "batch" }
          })
        );
      }

      if (url.endsWith("/api/v1/executions") && init?.method === "GET") {
        return new Response(
          JSON.stringify({
            items: [
              {
                executionId: "exec-live-001",
                workflowId: "wf-live-contracts",
                workflowVersion: "0.2.0",
                checkpointTag: "cp/02-alpha-core",
                status: "running",
                mode: "cpu-batch-v1",
                plan: ["ingest", "score"],
                stages: [["ingest"], ["score"]],
                nodeCount: 4,
                connectionCount: 3,
                createdAt: "2026-04-18T12:00:00Z",
                updatedAt: "2026-04-18T12:01:00Z",
                statusHistory: [],
                explainabilityEvidence: explainabilityEvidencePayload(),
                controlFlowPlan: [
                  {
                    controlId: "loop-bi-refresh",
                    kind: "loop",
                    iterationMode: "table_rows",
                    maxIterations: 3,
                    startNodeId: "node-transform",
                    endNodeId: "node-bi-outlet",
                    bodyNodeIds: ["node-transform", "node-bi-outlet"],
                    bounded: true
                  },
                  {
                    controlId: "try-bi-outlet",
                    kind: "try_catch",
                    tryNodeIds: ["node-transform"],
                    catchNodeIds: ["node-bi-outlet"],
                    bounded: true
                  }
                ],
                controlFlowRecovery: {
                  controlId: "try-bi-outlet",
                  failedNodeId: "node-transform",
                  catchNodeIds: ["node-bi-outlet"],
                  status: "recovered",
                  bounded: true
                },
                executorSchedule: [
                  {
                    stageIndex: 1,
                    nodeIds: ["node-source"],
                    lanes: ["cpu"],
                    workerPools: ["alpha-cpu"],
                    schedulerPolicy: "topological_stage_barrier",
                    readyAfterStage: 0,
                    maxConcurrency: 1,
                    bounded: true,
                    dataflowPolicy: {
                      policyName: "callback_dataflow_stage_barrier",
                      callbackEnabled: true,
                      dataflowEnabled: true,
                      stageBarrier: "ready_after_previous_stage",
                      eligibleNodeIds: ["node-source"],
                      sourceNodeIds: ["node-source"],
                      sinkNodeIds: [],
                      lanes: ["cpu"],
                      workerPools: ["alpha-cpu"],
                      maxConcurrency: 1,
                      bounded: true
                    }
                  },
                  {
                    stageIndex: 2,
                    nodeIds: ["node-transform", "node-bi-outlet"],
                    lanes: ["cpu"],
                    workerPools: ["alpha-cpu"],
                    schedulerPolicy: "topological_stage_barrier",
                    readyAfterStage: 1,
                    maxConcurrency: 2,
                    bounded: true,
                    dataflowPolicy: {
                      policyName: "callback_dataflow_stage_barrier",
                      callbackEnabled: true,
                      dataflowEnabled: true,
                      stageBarrier: "ready_after_previous_stage",
                      eligibleNodeIds: ["node-transform", "node-bi-outlet"],
                      sourceNodeIds: [],
                      sinkNodeIds: ["node-bi-outlet"],
                      lanes: ["cpu"],
                      workerPools: ["alpha-cpu"],
                      maxConcurrency: 2,
                      bounded: true
                    }
                  }
                ],
                executorState: {
                  status: "running",
                  currentStageIndex: 2,
                  stageCount: 2,
                  activeNodeIds: ["node-transform", "node-bi-outlet"],
                  completedNodeIds: ["node-source"],
                  completedStageIndexes: [1],
                  workerId: "executor-worker-test",
                  bounded: true,
                  dataflowPolicy: {
                    policyName: "callback_dataflow_stage_barrier",
                    callbackEnabled: true,
                    dataflowEnabled: true,
                    stageBarrier: "ready_after_previous_stage",
                    eligibleNodeIds: ["node-source", "node-transform", "node-bi-outlet"],
                    sourceNodeIds: ["node-source"],
                    sinkNodeIds: ["node-bi-outlet"],
                    lanes: ["cpu"],
                    workerPools: ["alpha-cpu"],
                    maxConcurrency: 2,
                    bounded: true
                  },
                  stageResults: [
                    {
                      stageIndex: 1,
                      nodeIds: ["node-source"],
                      status: "completed",
                      nodeResults: [
                        {
                          nodeId: "node-source",
                          nodeType: "JuliaFlow.Base.CSVReader",
                          status: "executed",
                          outputKind: "node",
                          rowCount: 12,
                          outputRefs: ["memory://executor/run-1/node-source"]
                        }
                      ]
                    }
                  ],
                  nodeResults: [
                    {
                      nodeId: "node-source",
                      nodeType: "JuliaFlow.Base.CSVReader",
                      status: "executed",
                      outputKind: "node",
                      rowCount: 12,
                      outputRefs: ["memory://executor/run-1/node-source"]
                    }
                  ],
                  failedNodeId: "node-transform",
                  errorMessage: "fixture executor failure"
                },
                controlFlowBranchState: {
                  controlId: "try-bi-outlet",
                  failedNodeId: "node-transform",
                  branch: "catch",
                  catchNodeIds: ["node-bi-outlet"],
                  branchStages: [["node-bi-outlet"]],
                  branchStageIndex: 1,
                  branchStageCount: 1,
                  activeNodeIds: [],
                  completedNodeIds: ["node-bi-outlet"],
                  status: "completed",
                  bounded: true,
                  workerId: "control-flow-worker-test",
                  stageResults: [
                    {
                      stageIndex: 1,
                      nodeIds: ["node-bi-outlet"],
                      nodeResults: [
                        {
                          nodeId: "node-bi-outlet",
                          nodeType: "JuliaFlow.BI.DataOutlet",
                          status: "executed",
                          outputKind: "bi_outlet",
                          rowCount: 3
                        }
                      ]
                    }
                  ],
                  nodeResults: [
                    {
                      nodeId: "node-bi-outlet",
                      nodeType: "JuliaFlow.BI.DataOutlet",
                      status: "executed",
                      outputKind: "bi_outlet",
                      rowCount: 3
                    }
                  ]
                }
              }
            ]
          })
        );
      }

      if (url.endsWith("/api/v1/checkpoints") && init?.method === "GET") {
        return new Response(
          JSON.stringify({
            items: [
              {
                tag: "cp/02-alpha-core",
                summary: "alpha core",
                createdAt: "2026-04-18T12:00:00Z"
              }
            ]
          })
        );
      }

      if (url.endsWith("/api/v1/hub/extensions") && init?.method === "GET") {
        return new Response(
          JSON.stringify({
            items: [
              {
                extensionId: "juliaflow-base",
                manifest: {
                  extensionId: "juliaflow-base",
                  name: "JuliaFlow Base",
                  version: "0.1.0",
                  publisher: "official",
                  summary: "Official starter node pack.",
                  packageRef: "extensions/base",
                  tags: ["official", "starter"],
                  engineCompatibility: "alpha-core",
                  requiredContractVersion: "0.1.0",
                  supportedCheckpoints: ["cp/02-alpha-core"],
                  compatibleCheckpoints: ["cp/02-alpha-core"],
                  dependencies: [],
                  publisherIdentity: "official:juliaflow",
                  artifactHashes: {
                    package: "sha256:ef5563c1d3bb2319a9323daebe3e4907fce4c877835371b310dc31d50e521000"
                  },
                  compatibilitySandboxCommand: "julia --project=. extensions/base/test/runtests.jl",
                  mirrorRefs: ["mirror://official/juliaflow-base"]
                },
                installState: "enabled",
                compatibility: {
                  compatible: true,
                  warnings: [],
                  blockers: [],
                  evaluatedAt: "2026-04-20T00:00:00Z"
                },
                trust: {
                  trusted: true,
                  level: "official",
                  warnings: [],
                  blockers: [],
                  evaluatedAt: "2026-04-20T00:00:00Z"
                },
                upgrade: {
                  upgradeAvailable: false,
                  installedVersion: "0.1.0",
                  latestVersion: "0.1.0",
                  evaluatedAt: "2026-04-20T00:00:00Z"
                },
                verification: hubVerification(true)
              },
              {
                extensionId: "juliaflow-ops-preview",
                manifest: {
                  extensionId: "juliaflow-ops-preview",
                  name: "Ops Preview Pack",
                  version: "0.2.0",
                  publisher: "partner",
                  summary: "Preview Hub extension.",
                  packageRef: "hub://preview/ops-pack",
                  tags: ["preview", "ops"],
                  engineCompatibility: "alpha-core",
                  requiredContractVersion: "0.1.0",
                  supportedCheckpoints: ["cp/03-alpha-gpu-bi"],
                  compatibleCheckpoints: ["cp/03-alpha-gpu-bi"],
                  dependencies: [],
                  publisherIdentity: "partner:ops-preview",
                  artifactHashes: {
                    package: "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
                  },
                  compatibilitySandboxCommand: "julia --project=. extensions/ops-preview/test/runtests.jl",
                  mirrorRefs: ["mirror://offline/ops-preview"],
                  releaseNotesRef: "https://example.test/ops-preview"
                },
                installState: "upgrade_available",
                compatibility: {
                  compatible: false,
                  warnings: [],
                  blockers: ["Extension not validated for current checkpoint cp/02-alpha-core"],
                  evaluatedAt: "2026-04-20T00:00:00Z"
                },
                trust: {
                  trusted: false,
                  level: "untrusted",
                  warnings: ["Signature missing"],
                  blockers: ["Partner extension must provide signature"],
                  evaluatedAt: "2026-04-20T00:00:00Z"
                },
                upgrade: {
                  upgradeAvailable: true,
                  installedVersion: "0.1.0-alpha",
                  latestVersion: "0.2.0",
                  targetVersion: "0.2.0",
                  evaluatedAt: "2026-04-20T00:00:00Z"
                },
                verification: hubVerification(false, ["Extension not validated for current checkpoint cp/02-alpha-core"])
              }
            ]
          })
        );
      }

      if (url.endsWith("/api/v1/hub/extensions/register") && init?.method === "POST") {
        const request = JSON.parse(String(init.body));
        publishedHubManifest = request.manifest;
        return new Response(
          JSON.stringify({
            extension: {
              extensionId: request.manifest.extensionId,
              manifest: request.manifest,
              installState: "available",
              compatibility: {
                compatible: true,
                warnings: [],
                blockers: [],
                evaluatedAt: "2026-05-08T00:00:00Z"
              },
              trust: {
                trusted: true,
                level: "partner_verified",
                warnings: [],
                blockers: [],
                evaluatedAt: "2026-05-08T00:00:00Z"
              },
              upgrade: {
                upgradeAvailable: false,
                latestVersion: request.manifest.version,
                evaluatedAt: "2026-05-08T00:00:00Z"
              },
              verification: hubVerification(false)
            },
            status: "ok"
          })
        );
      }

      if (url.endsWith("/api/v1/admin/auth/policies") && init?.method === "GET") {
        return new Response(
          JSON.stringify({
            roleBindings: [
              { principalId: "user-owner", workspaceId: "workspace-a", role: "owner" },
              { principalId: "user-viewer", workspaceId: "workspace-a", role: "viewer" }
            ],
            resourcePolicies: [
              {
                resourceType: "workflow",
                resourceId: "wf-live-contracts",
                workspaceId: "workspace-a",
                permissionsByRole: { viewer: ["workflow:read"], owner: ["workflow:read", "policy:read"] }
              }
            ],
            updatedAt: "2026-05-04T00:00:00Z"
          })
        );
      }

      if (url.endsWith("/api/v1/admin/auth/policies") && init?.method === "PUT") {
        savedAuthPolicy = JSON.parse(String(init.body));
        return new Response(JSON.stringify(savedAuthPolicy));
      }

      if (url.endsWith("/api/v1/admin/auth/directory") && init?.method === "GET") {
        return new Response(
          JSON.stringify({
            users: [
              {
                principalId: "user-owner",
                displayName: "Security Owner",
                email: "owner@example.test",
                active: true,
                createdAt: "2026-05-05T00:00:00Z",
                updatedAt: "2026-05-05T00:00:00Z"
              },
              {
                principalId: "user-viewer",
                displayName: "Read Only",
                active: true,
                createdAt: "2026-05-05T00:00:00Z",
                updatedAt: "2026-05-05T00:00:00Z"
              }
            ],
            workspaces: [
              {
                workspaceId: "workspace-a",
                name: "Workspace A",
                active: true,
                createdAt: "2026-05-05T00:00:00Z",
                updatedAt: "2026-05-05T00:00:00Z"
              }
            ],
            updatedAt: "2026-05-05T00:00:00Z"
          })
        );
      }

      if (url.endsWith("/api/v1/admin/auth/directory") && init?.method === "PUT") {
        savedAuthDirectory = JSON.parse(String(init.body));
        return new Response(JSON.stringify(savedAuthDirectory));
      }

      if (url.endsWith("/api/v1/audit/actions") && init?.method === "GET") {
        return new Response(
          JSON.stringify({
            events: [
              {
                eventId: "audit-1",
                sequence: 11,
                occurredAt: "2026-05-04T00:00:00Z",
                action: "auth.policy.update",
                targetType: "auth_policy",
                targetId: "default",
                recordedAt: "2026-05-04T00:00:00Z",
                authContext: {
                  principalId: "user-owner",
                  workspaceId: "workspace-a",
                  role: "owner",
                  mode: "oidc",
                  permissions: ["audit:read", "policy:read"]
                },
                details: { Authorization: "[redacted]" }
              }
            ],
            count: 1,
            limit: 50
          })
        );
      }

      if (url.endsWith("/api/v1/workflows/wf-live-contracts/dashboards") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      throw new Error(`Unhandled fetch: ${url}`);
    });

    vi.stubGlobal("fetch", fetchMock as typeof fetch);

    render(<App />);

    await waitFor(() => {
      expect(screen.getAllByText(/Live Contracts/i).length).toBeGreaterThan(0);
    });

    expect(MockWebSocket.instances.at(-1)?.url).toBe("ws://gateway.test/api/v1/realtime");

    fireEvent.click(screen.getByRole("button", { name: /MonitorExecutions, workers, backbone/i }));
    expect(await screen.findByText(/Transport \+ worker modes/i)).toBeInTheDocument();
    expect(screen.getByText(/Appliance profile/i)).toBeInTheDocument();
    expect(screen.getByText(/Metadata mode/i)).toBeInTheDocument();
    expect(screen.getByText(/single-user \/ file/i)).toBeInTheDocument();
    expect(screen.getByText(/Metadata readiness/i)).toBeInTheDocument();
    expect(screen.getByText(/ready · not_required/i)).toBeInTheDocument();
    expect(screen.getByText(/Metadata concurrency/i)).toBeInTheDocument();
    expect(screen.getByText(/single_writer/i)).toBeInTheDocument();
    expect(screen.getByText(/Metadata capabilities/i)).toBeInTheDocument();
    expect(screen.getByText(/workflows, executions, authPolicy, authDirectory, auditEvents, consumerCursors, publishedDashboards/i)).toBeInTheDocument();
    expect(screen.getByText(/Hardware profile/i)).toBeInTheDocument();
    expect(screen.getByText(/ready · cpu/i)).toBeInTheDocument();
    expect(screen.getByText(/CPU scheduler/i)).toBeInTheDocument();
    expect(screen.getByText(/bounded_threads · 4 workers/i)).toBeInTheDocument();
    expect(screen.getByText(/CPU memory limit/i)).toBeInTheDocument();
    expect(screen.getByText(/GPU probe/i)).toBeInTheDocument();
    expect(screen.getByText(/not_requested · 0 hardware · 0 simulated/i)).toBeInTheDocument();
    expect(screen.getByText(/Explainability evidence/i)).toBeInTheDocument();
    expect(screen.getByText(/ready · foundation-sales-sample/i)).toBeInTheDocument();
    expect(screen.getByText(/Model card/i)).toBeInTheDocument();
    expect(screen.getByText(/deterministic_linear_baseline · 1.25 MAE/i)).toBeInTheDocument();
    expect(screen.getByText(/Explanation method/i)).toBeInTheDocument();
    expect(screen.getByText(/deterministic_feature_contribution · 3 features/i)).toBeInTheDocument();
    expect(screen.getByText(/foundation-sales-sample · deterministic_linear_baseline · deterministic_feature_contribution/i)).toBeInTheDocument();
    expect(screen.getByText(/Data estate/i)).toBeInTheDocument();
    expect(screen.getByText(/Estate manifests/i)).toBeInTheDocument();
    expect(screen.getByText(/ready · 1 checksums/i)).toBeInTheDocument();
    expect(screen.getByText(/Estate quota/i)).toBeInTheDocument();
    expect(screen.getByText(/DuckDB query/i)).toBeInTheDocument();
    expect(screen.getByText("Cleanup + backup")).toBeInTheDocument();
    expect(screen.getByText("ready / ready")).toBeInTheDocument();
    expect(screen.getByText(/Disk free/i)).toBeInTheDocument();
    expect(screen.getByText(/Postgres profile/i)).toBeInTheDocument();
    expect(screen.getByText(/MinIO profile/i)).toBeInTheDocument();
    expect(screen.getByText(/CPU threads/i)).toBeInTheDocument();
    expect(screen.getByText(/GPU readiness/i)).toBeInTheDocument();
    expect(screen.getByText(/dual_write/i)).toBeInTheDocument();
    expect(screen.getAllByText(/process/i).length).toBeGreaterThan(0);
    expect(screen.getByText(/Latest event sequence/i)).toBeInTheDocument();
    expect(screen.getByText(/Queued stream executions/i)).toBeInTheDocument();
    expect(screen.getByText(/Active GPU executions/i)).toBeInTheDocument();
    expect(screen.getByText(/GPU worker-owned executions/i)).toBeInTheDocument();
    expect(screen.getByText(/Consumer catch-up/i)).toBeInTheDocument();
    expect(screen.getByText(/Total queued executions/i)).toBeInTheDocument();
    expect(screen.getByText(/Total running executions/i)).toBeInTheDocument();
    expect(screen.getByText("loop-bi-refresh")).toBeInTheDocument();
    expect(screen.getByText(/loop · table_rows · max 3 · 2 nodes/i)).toBeInTheDocument();
    expect(screen.getByText("try-bi-outlet")).toBeInTheDocument();
    expect(screen.getByText(/try_catch · 1 try nodes · 1 catch nodes/i)).toBeInTheDocument();
    expect(screen.getByText(/recovered · node-transform via try-bi-outlet · 1 catch nodes/i)).toBeInTheDocument();
    expect(screen.getByText(/catch completed · 1 catch nodes · control-flow-worker-test/i)).toBeInTheDocument();
    expect(screen.getByText(/stage 1\/1 · active 0/i)).toBeInTheDocument();
    expect(screen.getByText(/2 stages · max concurrency 2 · topological_stage_barrier/i)).toBeInTheDocument();
    expect(screen.getByText(/executor running · stage 2\/2 · active 2 · completed 1/i)).toBeInTheDocument();
    expect(screen.getByText(/callback_dataflow_stage_barrier · eligible 3 · max concurrency 2 · callback on · dataflow on/i)).toBeInTheDocument();
    expect(screen.getByText(/callback_dataflow_stage_barrier · eligible 1 · sources 1 · sinks 0/i)).toBeInTheDocument();
    expect(screen.getByText(/callback_dataflow_stage_barrier · eligible 2 · sources 0 · sinks 1/i)).toBeInTheDocument();
    expect(screen.getByText(/1 results · failed node-transform · fixture executor failure/i)).toBeInTheDocument();
    expect(screen.getByText(/executed · node · 12 rows · 1 ref/i)).toBeInTheDocument();
    expect(screen.getByText(/executed · bi_outlet · 3 rows/i)).toBeInTheDocument();
    expect(screen.getAllByText("12").length).toBeGreaterThan(0);
    expect(screen.getByText("10")).toBeInTheDocument();
    expect(screen.getByText("2")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /HubTrust-aware extension lifecycle/i }));
    expect(await screen.findByText(/Extension marketplace/i)).toBeInTheDocument();
    expect(screen.getAllByText(/0.2.0/i).length).toBeGreaterThan(0);
    expect(screen.getByText("hub://preview/ops-pack")).toBeInTheDocument();
    expect(screen.getByText("https://example.test/ops-preview")).toBeInTheDocument();
    expect(screen.getByText(/package=sha256:bbbb/i)).toBeInTheDocument();
    expect(screen.getByText("julia --project=. extensions/ops-preview/test/runtests.jl")).toBeInTheDocument();
    expect(screen.getByText("mirror://offline/ops-preview")).toBeInTheDocument();
    expect(screen.getByText(/blocked\/pending · sandbox failed · artifacts failed · mirrors failed/i)).toBeInTheDocument();
    expect(screen.getAllByText(/test sandbox verification · test artifact verification · test mirror verification/i).length).toBeGreaterThan(0);
    expect(screen.getByText("Verification blockers")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /Blocked/i })).toBeDisabled();

    const enabledWithBlockers = {
      extensionId: "juliaflow-base",
      manifest: {
        extensionId: "juliaflow-base",
        name: "JuliaFlow Base",
        version: "0.1.0",
        publisher: "official",
        summary: "Official starter node pack.",
        packageRef: "extensions/base",
        tags: ["official", "starter"],
        engineCompatibility: "alpha-core",
        requiredContractVersion: "0.1.0",
        supportedCheckpoints: ["cp/02-alpha-core"],
        compatibleCheckpoints: ["cp/02-alpha-core"],
        dependencies: [],
        publisherIdentity: "official:juliaflow",
        artifactHashes: {
          package: "sha256:ef5563c1d3bb2319a9323daebe3e4907fce4c877835371b310dc31d50e521000"
        },
        compatibilitySandboxCommand: "julia --project=. extensions/base/test/runtests.jl",
        mirrorRefs: ["mirror://official/juliaflow-base"]
      },
      installState: "enabled",
      compatibility: {
        compatible: false,
        warnings: [],
        blockers: ["Extension must provide compatibility sandbox command"],
        evaluatedAt: "2026-05-08T00:00:00Z"
      },
      trust: {
        trusted: false,
        level: "untrusted",
        warnings: [],
        blockers: ["Artifact hash for package must use sha256:<64 hex digest>"],
        evaluatedAt: "2026-05-08T00:00:00Z"
      },
      upgrade: {
        upgradeAvailable: false,
        installedVersion: "0.1.0",
        latestVersion: "0.1.0",
        evaluatedAt: "2026-05-08T00:00:00Z"
      },
      verification: hubVerification(false, ["Extension must provide compatibility sandbox command"])
    };
    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({ extension: enabledWithBlockers, status: "ok" })));
    const disableButton = screen.getByRole("button", { name: /^Disable$/i });
    expect(disableButton).not.toBeDisabled();
    fireEvent.click(disableButton);
    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledWith(
        expect.stringMatching(/\/api\/v1\/hub\/extensions\/juliaflow-base\/install$/),
        expect.objectContaining({
          body: JSON.stringify({ action: "disable" }),
          method: "POST"
        })
      );
    });

    fireEvent.click(screen.getByRole("button", { name: /Publish sample extension/i }));
    expect(await screen.findByText(/Hub publish completed for juliaflow-private-mirror-pack/i)).toBeInTheDocument();
    expect(screen.getByText("Private Mirror Pack")).toBeInTheDocument();
    expect(publishedHubManifest).toMatchObject({
      extensionId: "juliaflow-private-mirror-pack",
      artifactHashes: {
        package: "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
      },
      compatibilitySandboxCommand: "julia --project=. extensions/private-mirror/test/runtests.jl",
      mirrorRefs: ["mirror://offline/private-mirror-pack", "private://workspace/private-mirror-pack"]
    });

    fireEvent.click(screen.getByRole("button", { name: /SettingsDelivery, theme, discovery/i }));
    expect(await screen.findByText(/Policy \+ audit management/i)).toBeInTheDocument();
    expect(screen.getByText(/OIDC discovery/i)).toBeInTheDocument();
    expect(screen.getAllByText(/configured/i).length).toBeGreaterThan(1);
    expect(screen.getAllByText(/user-owner/i).length).toBeGreaterThan(0);
    expect(screen.getByText("User/workspace directory")).toBeInTheDocument();
    expect(screen.getByText(/Security Owner/i)).toBeInTheDocument();
    expect(screen.getByText(/Workspace A/i)).toBeInTheDocument();
    expect(screen.getByText(/workflow:wf-live-contracts/i)).toBeInTheDocument();
    expect(screen.getByText(/auth.policy.update/i)).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/Auth policy principal id/i), {
      target: { value: "user-editor" }
    });
    fireEvent.change(screen.getByLabelText(/Auth policy role workspace id/i), {
      target: { value: "workspace-a" }
    });
    fireEvent.change(screen.getByLabelText(/Auth policy workspace role/i), {
      target: { value: "editor" }
    });
    fireEvent.click(screen.getByRole("button", { name: /Queue role binding/i }));
    expect(screen.getByText(/Queued role binding for user-editor/i)).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/Auth policy resource id/i), {
      target: { value: "wf-new-secure" }
    });
    fireEvent.change(screen.getByLabelText(/Auth policy resource workspace id/i), {
      target: { value: "workspace-a" }
    });
    fireEvent.click(screen.getByRole("button", { name: /Queue resource policy/i }));
    expect(screen.getByText(/Queued resource policy for workflow:wf-new-secure/i)).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /Save auth policy/i }));
    await waitFor(() => {
      expect(screen.getByText(/Auth policy saved to gateway/i)).toBeInTheDocument();
    });
    expect(savedAuthPolicy).toMatchObject({
      roleBindings: expect.arrayContaining([
        { principalId: "user-editor", workspaceId: "workspace-a", role: "editor" }
      ]),
      resourcePolicies: expect.arrayContaining([
        expect.objectContaining({ resourceType: "workflow", resourceId: "wf-new-secure", workspaceId: "workspace-a" })
      ])
    });

    fireEvent.change(screen.getByLabelText(/Auth directory principal id/i), {
      target: { value: "user-analyst" }
    });
    fireEvent.change(screen.getByLabelText(/Auth directory display name/i), {
      target: { value: "Analytics User" }
    });
    fireEvent.click(screen.getByRole("button", { name: /Queue directory user/i }));
    expect(screen.getByText(/Queued directory user user-analyst/i)).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/Auth directory workspace id/i), {
      target: { value: "workspace-b" }
    });
    fireEvent.change(screen.getByLabelText(/Auth directory workspace name/i), {
      target: { value: "Workspace B" }
    });
    fireEvent.click(screen.getByRole("button", { name: /Queue directory workspace/i }));
    expect(screen.getByText(/Queued directory workspace workspace-b/i)).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /Save auth directory/i }));
    await waitFor(() => {
      expect(screen.getByText(/Auth directory saved to gateway/i)).toBeInTheDocument();
    });
    expect(savedAuthDirectory).toMatchObject({
      users: expect.arrayContaining([
        expect.objectContaining({ principalId: "user-analyst", displayName: "Analytics User", active: true })
      ]),
      workspaces: expect.arrayContaining([
        expect.objectContaining({ workspaceId: "workspace-b", name: "Workspace B", active: true })
      ])
    });
  });

  it("uses share token when loading published dashboard by viewer URL", async () => {
    vi.stubEnv("VITE_JULIAFLOW_GATEWAY_BASE_URL", "http://gateway.test");
    window.history.replaceState({}, "", "/dashboard?dashboard=dashboard-shared&share=token-123");

    const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      const url = String(input);

      if (url.endsWith("/health")) {
        return new Response(JSON.stringify(healthPayload()));
      }

      if (url.endsWith("/api/v1/workflows") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (url.endsWith("/api/v1/executions") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (url.endsWith("/api/v1/checkpoints") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (url.endsWith("/api/v1/hub/extensions") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (
        url.endsWith("/api/v1/workflows/wf-phase0-cpu-forecast/dashboards") &&
        init?.method === "GET"
      ) {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (
        url.includes("/api/v1/dashboards/dashboard-shared?shareToken=token-123") &&
        init?.method === "GET"
      ) {
        return new Response(
          JSON.stringify({
            dashboardId: "dashboard-shared",
            workflowId: "wf-shared",
            name: "Shared Dashboard",
            version: 3,
            publishedAt: "2026-04-22T12:00:00Z",
            visibility: "public",
            shareToken: "token-123",
            binding: {
              outletNodeId: "node-bi-outlet",
              datasetKey: "shared_dataset",
              refreshMode: "live"
            },
            charts: [{ chartId: "chart-1", title: "Trend", family: "line", xField: "window", yField: "amount" }]
          })
        );
      }

      if (
        url.includes("/api/v1/dashboards/dashboard-shared/charts/chart-1/data?shareToken=token-123") &&
        init?.method === "GET"
      ) {
        return new Response(
          JSON.stringify({
            dashboardId: "dashboard-shared",
            chartId: "chart-1",
            datasetKey: "shared_dataset",
            family: "line",
            fields: ["window", "amount"],
            rows: [
              { window: "2026-Q1", amount: 12 },
              { window: "2026-Q2", amount: 18 }
            ],
            rowCount: 2,
            refreshedAt: "2026-04-24T12:00:00Z",
            semantic: {
              dimensions: ["window"],
              measures: ["amount"],
              xField: "window",
              yField: "amount",
              seriesField: null,
              availableDimensions: ["window"],
              availableMeasures: ["amount"]
            },
            cache: {
              cacheKey: "dashboard-shared:chart-1:v3",
              sourceVersion: 3,
              snapshotAt: "2026-04-22T12:00:00Z",
              refreshMode: "live",
              live: true,
              stale: false
            },
            exportFormats: ["json", "csv"]
          })
        );
      }

      throw new Error(`Unhandled fetch: ${url}`);
    });

    vi.stubGlobal("fetch", fetchMock as typeof fetch);

    render(<App />);

    await waitFor(() => {
      expect(
        fetchMock.mock.calls.some(([input]) =>
          String(input).includes("/api/v1/dashboards/dashboard-shared?shareToken=token-123")
        )
      ).toBe(true);
    });

    expect(await screen.findByText(/Shared Dashboard/i)).toBeInTheDocument();
    expect(await screen.findByText(/Refresh charts/i)).toBeInTheDocument();
    const clipboardWrite = vi.fn(async (_value: string) => undefined);
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { writeText: clipboardWrite }
    });

    expect(await screen.findByText(/live · live/i)).toBeInTheDocument();
    expect((await screen.findAllByText("12")).length).toBeGreaterThan(0);

    fireEvent.change(screen.getByLabelText(/Search published dashboard rows/i), {
      target: { value: "Q2" }
    });
    expect(screen.getAllByText(/Row search/i).length).toBeGreaterThan(0);
    expect(screen.getByLabelText(/Search published dashboard rows/i)).toHaveValue("Q2");
    expect((await screen.findAllByText("18")).length).toBeGreaterThan(0);

    fireEvent.click(screen.getByRole("button", { name: /Export filtered CSV/i }));
    await waitFor(() => {
      expect(clipboardWrite).toHaveBeenCalledWith("window,amount\n2026-Q2,18\n");
    });

    fireEvent.click(screen.getByRole("button", { name: /Clear row search/i }));
    expect(screen.getByLabelText(/Search published dashboard rows/i)).toHaveValue("");

    fireEvent.click(screen.getByRole("button", { name: "2026-Q1" }));
    expect(await screen.findByText(/Drilldown: Trend/i)).toBeInTheDocument();
    expect(screen.getAllByText(/window=2026-Q1/i).length).toBeGreaterThan(0);
    expect(screen.getByText(/Matching rows/i)).toBeInTheDocument();
    expect((await screen.findAllByText("2026-Q1")).length).toBeGreaterThan(0);

    fireEvent.click(screen.getByRole("button", { name: /Export filtered CSV/i }));
    await waitFor(() => {
      expect(clipboardWrite).toHaveBeenCalledWith("window,amount\n2026-Q1,12\n");
    });

    fireEvent.click(screen.getByRole("button", { name: /Copy selected row JSON/i }));
    await waitFor(() => {
      expect(clipboardWrite).toHaveBeenLastCalledWith(expect.stringContaining('"window": "2026-Q1"'));
    });
  });

  it("uses workspace token when loading workspace dashboard by viewer URL", async () => {
    vi.stubEnv("VITE_JULIAFLOW_GATEWAY_BASE_URL", "http://gateway.test");
    window.history.replaceState(
      {},
      "",
      "/dashboard?dashboard=dashboard-workspace&workspaceToken=workspace-123"
    );

    const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      const url = String(input);

      if (url.endsWith("/health")) {
        return new Response(JSON.stringify(healthPayload()));
      }

      if (url.endsWith("/api/v1/workflows") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (url.endsWith("/api/v1/executions") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (url.endsWith("/api/v1/checkpoints") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (url.endsWith("/api/v1/hub/extensions") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (
        url.endsWith("/api/v1/workflows/wf-phase0-cpu-forecast/dashboards") &&
        init?.method === "GET"
      ) {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (
        url.includes("/api/v1/dashboards/dashboard-workspace?workspaceToken=workspace-123") &&
        init?.method === "GET"
      ) {
        return new Response(
          JSON.stringify({
            dashboardId: "dashboard-workspace",
            workflowId: "wf-internal",
            name: "Workspace Dashboard",
            version: 2,
            publishedAt: "2026-04-23T10:00:00Z",
            visibility: "workspace",
            binding: {
              outletNodeId: "node-bi-outlet",
              datasetKey: "workspace_dataset",
              refreshMode: "manual"
            },
            charts: [{ chartId: "chart-1", title: "Internal Trend", family: "line", xField: "window", yField: "amount" }]
          })
        );
      }

      if (
        url.includes("/api/v1/dashboards/dashboard-workspace/charts/chart-1/data?workspaceToken=workspace-123") &&
        init?.method === "GET"
      ) {
        return new Response(
          JSON.stringify({
            dashboardId: "dashboard-workspace",
            chartId: "chart-1",
            datasetKey: "workspace_dataset",
            family: "line",
            fields: ["window", "amount"],
            rows: [{ window: "2026-Q1", amount: 5 }],
            rowCount: 1,
            refreshedAt: "2026-04-24T12:00:00Z",
            semantic: {
              dimensions: ["window"],
              measures: ["amount"],
              xField: "window",
              yField: "amount",
              seriesField: null,
              availableDimensions: ["window"],
              availableMeasures: ["amount"]
            },
            cache: {
              cacheKey: "dashboard-workspace:chart-1:v2",
              sourceVersion: 2,
              snapshotAt: "2026-04-23T10:00:00Z",
              refreshMode: "manual",
              live: false,
              stale: false
            },
            exportFormats: ["json", "csv"]
          })
        );
      }

      throw new Error(`Unhandled fetch: ${url}`);
    });

    vi.stubGlobal("fetch", fetchMock as typeof fetch);

    render(<App />);

    await waitFor(() => {
      expect(
        fetchMock.mock.calls.some(([input]) =>
          String(input).includes("/api/v1/dashboards/dashboard-workspace?workspaceToken=workspace-123")
        )
      ).toBe(true);
    });

    expect(await screen.findByText(/Workspace Dashboard/i)).toBeInTheDocument();
  });

  it("uses bearer auth when loading workspace dashboard without URL token", async () => {
    vi.stubEnv("VITE_JULIAFLOW_GATEWAY_BASE_URL", "http://gateway.test");
    vi.stubEnv("VITE_JULIAFLOW_WORKSPACE_BEARER_TOKEN", "workspace-bearer-123");
    window.history.replaceState({}, "", "/dashboard?dashboard=dashboard-workspace");

    const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      const url = String(input);

      if (url.endsWith("/health")) {
        return new Response(JSON.stringify(healthPayload()));
      }

      if (url.endsWith("/api/v1/workflows") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (url.endsWith("/api/v1/executions") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (url.endsWith("/api/v1/checkpoints") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (url.endsWith("/api/v1/hub/extensions") && init?.method === "GET") {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (
        url.endsWith("/api/v1/workflows/wf-phase0-cpu-forecast/dashboards") &&
        init?.method === "GET"
      ) {
        return new Response(JSON.stringify({ items: [] }));
      }

      if (url.endsWith("/api/v1/dashboards/dashboard-workspace") && init?.method === "GET") {
        const authHeader = new Headers(init?.headers).get("Authorization");
        if (authHeader !== "Bearer workspace-bearer-123") {
          throw new Error(`Missing workspace bearer auth header: ${authHeader}`);
        }
        return new Response(
          JSON.stringify({
            dashboardId: "dashboard-workspace",
            workflowId: "wf-internal",
            name: "Workspace Dashboard",
            version: 4,
            publishedAt: "2026-04-23T10:00:00Z",
            visibility: "workspace",
            binding: {
              outletNodeId: "node-bi-outlet",
              datasetKey: "workspace_dataset",
              refreshMode: "manual"
            },
            charts: [{ chartId: "chart-1", title: "Internal Trend", family: "line", xField: "window", yField: "amount" }]
          })
        );
      }

      if (url.endsWith("/api/v1/dashboards/dashboard-workspace/charts/chart-1/data") && init?.method === "GET") {
        const authHeader = new Headers(init?.headers).get("Authorization");
        if (authHeader !== "Bearer workspace-bearer-123") {
          throw new Error(`Missing workspace bearer auth header: ${authHeader}`);
        }
        return new Response(
          JSON.stringify({
            dashboardId: "dashboard-workspace",
            chartId: "chart-1",
            datasetKey: "workspace_dataset",
            family: "line",
            fields: ["window", "amount"],
            rows: [{ window: "2026-Q1", amount: 9 }],
            rowCount: 1,
            refreshedAt: "2026-04-24T12:00:00Z",
            semantic: {
              dimensions: ["window"],
              measures: ["amount"],
              xField: "window",
              yField: "amount",
              seriesField: null,
              availableDimensions: ["window"],
              availableMeasures: ["amount"]
            },
            cache: {
              cacheKey: "dashboard-workspace:chart-1:v4",
              sourceVersion: 4,
              snapshotAt: "2026-04-23T10:00:00Z",
              refreshMode: "manual",
              live: false,
              stale: false
            },
            exportFormats: ["json", "csv"]
          })
        );
      }

      throw new Error(`Unhandled fetch: ${url}`);
    });

    vi.stubGlobal("fetch", fetchMock as typeof fetch);

    render(<App />);

    await waitFor(() => {
      expect(
        fetchMock.mock.calls.some(([input, init]) => {
          if (!String(input).endsWith("/api/v1/dashboards/dashboard-workspace")) {
            return false;
          }
          return new Headers(init?.headers).get("Authorization") === "Bearer workspace-bearer-123";
        })
      ).toBe(true);
    });

    expect(await screen.findByText(/Workspace Dashboard/i)).toBeInTheDocument();
  });
});

function sampleNodes() {
  return [
    {
      id: "node-csv-reader",
      type: "io.csv_reader",
      name: "CSV Reader",
      executionHint: "cpu_only",
      ports: [{ id: "rows", direction: "output", type: "data_table" }],
      config: { path: "assets/forecast.csv" }
    },
    {
      id: "node-join",
      type: "transform.join",
      name: "Join Sales + Weather",
      executionHint: "cpu_only",
      ports: [
        { id: "left", direction: "input", type: "data_table" },
        { id: "right", direction: "input", type: "data_table" },
        { id: "joined", direction: "output", type: "data_table" }
      ],
      config: { key: "store_id", mode: "left_join" }
    },
    {
      id: "node-model-train",
      type: "ml.linear_regression",
      name: "Train Regressor",
      executionHint: "gpu_preferred",
      ports: [
        { id: "training_frame", direction: "input", type: "data_table" },
        { id: "model", direction: "output", type: "model" }
      ],
      config: { target: "demand", validationSplit: 0.2 }
    },
    {
      id: "node-bi-outlet",
      type: "bi.outlet",
      name: "BI Outlet",
      executionHint: "cpu_only",
      ports: [
        { id: "dataset", direction: "input", type: "data_table" },
        { id: "score_model", direction: "input", type: "model" },
        { id: "dashboard_stream", direction: "output", type: "stream_channel" }
      ],
      config: { dashboardId: "ops-forecast" }
    }
  ];
}

function sampleConnections() {
  return [
    {
      sourceNodeId: "node-csv-reader",
      sourcePortId: "rows",
      targetNodeId: "node-join",
      targetPortId: "left",
      dataType: "data_table"
    },
    {
      sourceNodeId: "node-join",
      sourcePortId: "joined",
      targetNodeId: "node-model-train",
      targetPortId: "training_frame",
      dataType: "data_table"
    },
    {
      sourceNodeId: "node-model-train",
      sourcePortId: "model",
      targetNodeId: "node-bi-outlet",
      targetPortId: "score_model",
      dataType: "model"
    }
  ];
}

function sampleFlowVariables() {
  return [
    { name: "batch_window", type: "String", default: "2026-Q2" },
    { name: "target_gpu", type: "GPUDeviceID", default: "cpu-fallback" }
  ];
}

function sampleDashboards() {
  return [
    {
      dashboardId: "ops-forecast",
      name: "Ops Forecast Overview",
      binding: {
        outletNodeId: "node-bi-outlet",
        datasetKey: "forecast_rows",
        refreshMode: "live"
      },
      charts: [
        { chartId: "chart-line", title: "Demand Trend", family: "line", xField: "horizon", yField: "demand" }
      ]
    }
  ];
}
