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
  });

  afterEach(() => {
    cleanup();
  });

  it("renders the Alpha authoring shell with draft actions", () => {
    render(<App />);

    expect(screen.getByText(/JuliaFlow Alpha/i)).toBeInTheDocument();
    expect(screen.getByText(/Primary authoring workspace/i)).toBeInTheDocument();
    expect(screen.getAllByText(/Phase 0 CPU Forecast Demo/i).length).toBeGreaterThan(0);
    expect(screen.getByText(/Browse and quick-add/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /save workflow/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /run workflow/i })).toBeInTheDocument();
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

  it("lets authors add repository nodes, edit flow variables, and get demo run feedback", async () => {
    render(<App />);

    fireEvent.change(screen.getByLabelText(/Connection peer node/i), {
      target: { value: "node-bi-outlet" }
    });
    fireEvent.change(screen.getByLabelText(/Connection peer port/i), {
      target: { value: "score_model" }
    });
    expect(screen.getByText(/Type mismatch/i)).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /\+ join sales \+ weather/i }));
    expect(screen.getByRole("heading", { name: /Join Sales \+ Weather 2/i })).toBeInTheDocument();
    expect(screen.getByText(/linked into the current graph slice/i)).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /Add BI Outlet to workflow/i }));
    expect(screen.getByRole("heading", { name: /BI Outlet 2/i })).toBeInTheDocument();

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
    fireEvent.click(
      screen.getByRole("button", { name: /Remove Join Sales \+ Weather 2\.joined -> BI Outlet 2\.dataset/i })
    );
    expect(screen.getByText(/Compatible edge/i)).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /add connection/i }));
    expect(screen.getByText(/Added edge joined -> dataset/i)).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: /Remove Join Sales \+ Weather 2\.joined -> BI Outlet 2\.dataset/i })
    ).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /Remove Join Sales \+ Weather 2\.joined -> BI Outlet 2\.dataset/i }));
    expect(screen.queryByRole("button", { name: /Remove Join Sales \+ Weather 2\.joined -> BI Outlet 2\.dataset/i })).not.toBeInTheDocument();

    const defaultInput = screen.getByLabelText(/Variable default batch_window/i);
    fireEvent.change(defaultInput, { target: { value: "2026-Q3" } });
    expect(screen.getByDisplayValue("2026-Q3")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /save workflow/i }));
    await waitFor(() => {
      expect(screen.getByText(/Draft saved locally/i)).toBeInTheDocument();
    });

    fireEvent.click(screen.getByRole("button", { name: /run workflow/i }));
    await waitFor(() => {
      expect(screen.getByText(/Demo run queued/i)).toBeInTheDocument();
    });

    expect(screen.getAllByText(/Demo canvas run/i).length).toBeGreaterThan(0);
  });

  it("lets authors edit the dashboard composer in the workflow draft", () => {
    render(<App />);

    expect(screen.getByLabelText(/Dashboard name/i)).toHaveValue("Ops Forecast Overview");

    fireEvent.change(screen.getByLabelText(/Dashboard name/i), {
      target: { value: "Executive Overview" }
    });
    expect(screen.getByLabelText(/Dashboard name/i)).toHaveValue("Executive Overview");

    fireEvent.change(screen.getByLabelText(/Dashboard dataset key/i), {
      target: { value: "exec_dataset" }
    });
    expect(screen.getByLabelText(/Dashboard dataset key/i)).toHaveValue("exec_dataset");

    fireEvent.click(screen.getByRole("button", { name: /Add chart/i }));
    expect(screen.getByText(/Added dashboard chart/i)).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/Chart title chart-6/i), {
      target: { value: "Executive KPI" }
    });
    expect(screen.getByLabelText(/Chart title chart-6/i)).toHaveValue("Executive KPI");
    expect(screen.getByText(/Unsaved draft changes/i)).toBeInTheDocument();
  });

  it("updates the workflow through the gateway and surfaces live run feedback", async () => {
    vi.stubEnv("VITE_JULIAFLOW_GATEWAY_BASE_URL", "http://gateway.test");
    vi.stubGlobal("WebSocket", MockWebSocket as unknown as typeof WebSocket);

    let executionItems = [
      {
        executionId: "exec-live-001",
        workflowId: "wf-live-contracts",
        workflowVersion: "0.2.0",
        checkpointTag: "cp/01-contracts-frozen",
        status: "running",
        mode: "cpu-batch-v1",
        plan: ["ingest", "score"],
        stages: [["ingest"], ["score"]],
        nodeCount: 5,
        connectionCount: 4,
        createdAt: "2026-04-18T12:00:00Z",
        updatedAt: "2026-04-18T12:01:00Z",
        statusHistory: [
          {
            status: "running",
            at: "2026-04-18T12:01:00Z",
            message: "Gateway resumed execution"
          }
        ],
        startedAt: "2026-04-18T12:00:30Z"
      }
    ];

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
            executionCount: 1
          })
        );
      }

      if (url.endsWith("/api/v1/workflows") && init?.method === "GET") {
        return new Response(
          JSON.stringify({
            items: [
              {
                workflowId: "wf-live-contracts",
                name: "Live Contract Workflow",
                version: "0.2.0",
                nodeCount: 5,
                latestCheckpoint: "cp/01-contracts-frozen"
              }
            ]
          })
        );
      }

      if (url.endsWith("/api/v1/workflows/wf-live-contracts") && init?.method === "GET") {
        return new Response(
          JSON.stringify({
            workflowId: "wf-live-contracts",
            name: "Live Contract Workflow",
            version: "0.2.0",
            nodeCount: 5,
            connectionCount: 4,
            flowVariableCount: 3,
            biOutletCount: 1,
            nodes: [
              {
                id: "live-source",
                type: "io.live_source",
                name: "Live Source",
                executionHint: "cpu_only",
                ports: [{ id: "rows", direction: "output", type: "data_table" }],
                config: { source: "gateway" }
              },
              {
                id: "live-score",
                type: "ml.live_score",
                name: "Live Score",
                executionHint: "gpu_preferred",
                ports: [
                  { id: "frame", direction: "input", type: "data_table" },
                  { id: "model", direction: "output", type: "model" }
                ],
                config: { strategy: "incremental" }
              }
            ],
            connections: [
              {
                sourceNodeId: "live-source",
                sourcePortId: "rows",
                targetNodeId: "live-score",
                targetPortId: "frame",
                dataType: "data_table"
              }
            ],
            flowVariables: [
              {
                name: "live_window",
                type: "String",
                default: "today"
              }
            ],
            biOutlets: []
          })
        );
      }

      if (url.endsWith("/api/v1/executions") && init?.method === "GET") {
        return new Response(
          JSON.stringify({
            items: executionItems
          })
        );
      }

      if (url.endsWith("/api/v1/checkpoints") && init?.method === "GET") {
        return new Response(
          JSON.stringify({
            items: [
              {
                tag: "cp/01-contracts-frozen",
                summary: "Contracts locked",
                createdAt: "2026-04-18T10:00:00Z"
              }
            ]
          })
        );
      }

      if (url.endsWith("/api/v1/workflows/wf-live-contracts") && init?.method === "PUT") {
        const body = JSON.parse(String(init.body)) as {
          workflow: {
            flowVariables: Array<{ default?: string; name: string }>;
          };
        };
        expect(body.workflow.flowVariables.find((item) => item.name === "live_window")?.default).toBe("tomorrow");

        return new Response(
          JSON.stringify({
            workflowId: "wf-live-contracts",
            name: "Live Contract Workflow",
            version: "0.2.0",
            status: "updated"
          })
        );
      }

      if (url.endsWith("/api/v1/workflows/wf-live-contracts/execute") && init?.method === "POST") {
        executionItems = [
          {
            executionId: "exec-live-002",
            workflowId: "wf-live-contracts",
            workflowVersion: "0.2.0",
            checkpointTag: "cp/01-contracts-frozen",
            status: "running",
            mode: "cpu-batch-v1",
            plan: ["ingest", "score"],
            stages: [["ingest"], ["score"]],
            nodeCount: 5,
            connectionCount: 4,
            createdAt: "2026-04-18T12:02:00Z",
            updatedAt: "2026-04-18T12:02:10Z",
            statusHistory: [
              {
                status: "running",
                at: "2026-04-18T12:02:10Z",
                message: "Gateway started new execution"
              }
            ],
            startedAt: "2026-04-18T12:02:01Z"
          },
          ...executionItems
        ];

        return new Response(
          JSON.stringify({
            executionId: "exec-live-002",
            workflowId: "wf-live-contracts",
            workflowVersion: "0.2.0",
            checkpointTag: "cp/01-contracts-frozen",
            status: "running",
            mode: "cpu-batch-v1",
            plan: ["ingest", "score"],
            stages: [["ingest"], ["score"]],
            nodeCount: 5,
            connectionCount: 4,
            createdAt: "2026-04-18T12:02:00Z",
            updatedAt: "2026-04-18T12:02:10Z",
            statusHistory: [
              {
                status: "running",
                at: "2026-04-18T12:02:10Z",
                message: "Gateway started new execution"
              }
            ],
            startedAt: "2026-04-18T12:02:01Z"
          })
        );
      }

      throw new Error(`Unhandled request: ${url} (${init?.method ?? "GET"})`);
    });

    vi.stubGlobal("fetch", fetchMock);

    render(<App />);

    await waitFor(() => {
      expect(screen.getByText(/Gateway postgres/i)).toBeInTheDocument();
    });
    expect(screen.getByText(/Realtime connecting|Realtime live/i)).toBeInTheDocument();

    const realtimeSocket = MockWebSocket.instances.at(-1);
    expect(realtimeSocket?.url).toBe("ws://gateway.test/api/v1/realtime");
    await act(async () => {
      for (const socket of MockWebSocket.instances) {
        socket.emit("open");
      }
    });
    expect(
      MockWebSocket.instances.some((socket) =>
        socket.sentMessages.some((message) => message.includes("\"method\":\"canvas.subscribe\""))
      )
    ).toBe(true);

    fireEvent.change(screen.getByLabelText(/Variable default live_window/i), {
      target: { value: "tomorrow" }
    });
    fireEvent.click(screen.getByRole("button", { name: /update workflow/i }));

    await waitFor(() => {
      expect(screen.getByText(/Updated wf-live-contracts/i)).toBeInTheDocument();
    });

    fireEvent.click(screen.getByRole("button", { name: /run workflow/i }));

    await waitFor(() => {
      expect(screen.getByText(/Run started for wf-live-contracts/i)).toBeInTheDocument();
    });

    executionItems = [
      {
        executionId: "exec-live-003",
        workflowId: "wf-live-contracts",
        workflowVersion: "0.2.0",
        checkpointTag: "cp/02-alpha-core",
        status: "completed",
        mode: "cpu-batch-v1",
        plan: ["ingest", "score"],
        stages: [["ingest"], ["score"]],
        nodeCount: 5,
        connectionCount: 4,
        createdAt: "2026-04-18T12:05:00Z",
        updatedAt: "2026-04-18T12:06:00Z",
        statusHistory: [
          {
            status: "completed",
            at: "2026-04-18T12:06:00Z",
            message: "Realtime completion event"
          }
        ],
        startedAt: "2026-04-18T12:05:05Z",
        finishedAt: "2026-04-18T12:06:00Z"
      },
      ...executionItems
    ];

    await act(async () => {
      MockWebSocket.instances.at(-1)?.emit("message", {
        data: JSON.stringify({
          jsonrpc: "2.0",
          method: "execution.state.changed",
          params: {
            executionId: "exec-live-003",
            workflowId: "wf-live-contracts",
            workflowVersion: "0.2.0",
            checkpointTag: "cp/02-alpha-core",
            status: "completed",
            mode: "cpu-batch-v1",
            plan: ["ingest", "score"],
            stages: [["ingest"], ["score"]],
            nodeCount: 5,
            connectionCount: 4,
            createdAt: "2026-04-18T12:05:00Z",
            updatedAt: "2026-04-18T12:06:00Z",
            statusHistory: [
              {
                status: "completed",
                at: "2026-04-18T12:06:00Z",
                message: "Realtime completion event"
              }
            ],
            startedAt: "2026-04-18T12:05:05Z",
            finishedAt: "2026-04-18T12:06:00Z"
          }
        })
      });
      MockWebSocket.instances.at(-1)?.emit("message", {
        data: JSON.stringify({
          jsonrpc: "2.0",
          method: "node.state.changed",
          params: {
            subscriptionId: "canvas-1",
            workflowId: "wf-live-contracts",
            nodeId: "live-score",
            nodeType: "ml.live_score",
            status: "running",
            executionHint: "gpu_preferred"
          }
        })
      });
      MockWebSocket.instances.at(-1)?.emit("message", {
        data: JSON.stringify({
          jsonrpc: "2.0",
          method: "workflow.state.changed",
          params: {
            subscriptionId: "canvas-1",
            workflowId: "wf-live-contracts",
            name: "Live Contract Workflow",
            version: "0.2.0",
            nodeCount: 5,
            connectionCount: 4,
            latestCheckpoint: "cp/02-alpha-core",
            executionCount: 2
          }
        })
      });
    });

    await waitFor(() => {
      expect(screen.getByText(/Realtime canvas pulse: accelerated stage active./i)).toBeInTheDocument();
    });
    expect(screen.getAllByText(/exec-live-003/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/Realtime completion event/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/exec-live-002/i).length).toBeGreaterThan(0);
    expect(fetchMock).toHaveBeenCalled();
  });
});
