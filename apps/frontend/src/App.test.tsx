import { act, cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
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

describe("App", () => {
  beforeEach(() => {
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
    MockWebSocket.instances = [];
    window.history.replaceState({}, "", "/");
  });

  afterEach(() => {
    cleanup();
  });

  it("renders the route shell and canvas-first authoring surface", () => {
    render(<App />);

    expect(screen.getByText(/Workflow Canvas/i)).toBeInTheDocument();
    expect(screen.getByText(/Authoring-first workflow builder/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /save workflow/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /run workflow/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /open bi workspace/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /add flow variable/i })).toBeInTheDocument();
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

    const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      const url = String(input);

      if (url.endsWith("/health")) {
        return new Response(
          JSON.stringify({
            service: "api-gateway",
            status: "ok",
            repositoryBackend: "postgres",
            storeRoot: "/tmp/juliaflow",
            workflowCount: 1,
            checkpointCount: 2,
              executionCount: 1,
              realtimeTransport: "jsonrpc_websocket",
              eventBackboneMode: "dual_write",
              eventConsumerPollMs: 250,
              streamWorkerMode: "process",
              gpuWorkerMode: "process",
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
            })
          );
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
                statusHistory: []
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
                  publisherIdentity: "official:juliaflow"
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
                }
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
                }
              }
            ]
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
    expect(screen.getByText(/dual_write/i)).toBeInTheDocument();
    expect(screen.getAllByText(/process/i).length).toBeGreaterThan(0);
    expect(screen.getByText(/Latest event sequence/i)).toBeInTheDocument();
    expect(screen.getByText(/Queued stream executions/i)).toBeInTheDocument();
    expect(screen.getByText(/Active GPU executions/i)).toBeInTheDocument();
    expect(screen.getByText(/GPU worker-owned executions/i)).toBeInTheDocument();
    expect(screen.getByText(/Consumer catch-up/i)).toBeInTheDocument();
    expect(screen.getByText(/Total queued executions/i)).toBeInTheDocument();
    expect(screen.getByText(/Total running executions/i)).toBeInTheDocument();
    expect(screen.getAllByText("12").length).toBeGreaterThan(0);
    expect(screen.getByText("10")).toBeInTheDocument();
    expect(screen.getByText("2")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /HubTrust-aware extension lifecycle/i }));
    expect(await screen.findByText(/Extension marketplace/i)).toBeInTheDocument();
    expect(screen.getAllByText(/0.2.0/i).length).toBeGreaterThan(0);
    expect(screen.getByText("hub://preview/ops-pack")).toBeInTheDocument();
    expect(screen.getByText("https://example.test/ops-preview")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /Upgrade/i })).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /SettingsDelivery, theme, discovery/i }));
    expect(await screen.findByText(/Policy \+ audit visibility/i)).toBeInTheDocument();
    expect(screen.getByText(/OIDC discovery/i)).toBeInTheDocument();
    expect(screen.getAllByText(/configured/i).length).toBeGreaterThan(1);
    expect(screen.getAllByText(/user-owner/i).length).toBeGreaterThan(0);
    expect(screen.getByText(/workflow:wf-live-contracts/i)).toBeInTheDocument();
    expect(screen.getByText(/auth.policy.update/i)).toBeInTheDocument();
  });

  it("uses share token when loading published dashboard by viewer URL", async () => {
    vi.stubEnv("VITE_JULIAFLOW_GATEWAY_BASE_URL", "http://gateway.test");
    window.history.replaceState({}, "", "/dashboard?dashboard=dashboard-shared&share=token-123");

    const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      const url = String(input);

      if (url.endsWith("/health")) {
        return new Response(
          JSON.stringify({
            service: "api-gateway",
            status: "ok",
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
            runningExecutionsTotal: 0
          })
        );
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
        return new Response(
          JSON.stringify({
            service: "api-gateway",
            status: "ok",
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
            runningExecutionsTotal: 0
          })
        );
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
        return new Response(
          JSON.stringify({
            service: "api-gateway",
            status: "ok",
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
            runningExecutionsTotal: 0
          })
        );
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
