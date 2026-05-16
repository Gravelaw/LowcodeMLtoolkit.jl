import type {
  ConnectionDefinition,
  DashboardDefinition,
  GatewayCheckpointRecord,
  GatewayControlFlowPlanEntry,
  GatewayControlFlowRecovery,
  GatewayExecutionRecord,
  GatewayExecutionStatus,
  GatewayWorkflowMetadata,
  GatewayWorkflowSummary,
  NodeDefinition,
  WorkflowDefinition,
  WorkflowPortType,
  WorkflowStatus
} from "@juliaflow/contracts";
import { milestoneCheckpoints } from "@juliaflow/contracts";

export interface CanvasNodeLayout {
  x: number;
  y: number;
  width?: number;
  status: WorkflowStatus;
  runtime: string;
  checkpointTag?: string;
  notes: string;
}

export interface ExecutionRailItem {
  id: string;
  workflowId: string;
  status: WorkflowStatus;
  trigger: string;
  startedAt: string;
  duration: string;
  planner: string;
  controlFlowPlan?: GatewayControlFlowPlanEntry[];
  controlFlowRecovery?: GatewayControlFlowRecovery;
}

export interface CheckpointRailItem {
  tag: string;
  scope: string;
  state: "ready" | "validating" | "blocked";
  evidence: string;
}

export const sampleWorkflow: WorkflowDefinition = {
  version: "0.1.0",
  workflowId: "wf-phase0-cpu-forecast",
  name: "Phase 0 CPU Forecast Demo",
  flowVariables: [
    { name: "batch_window", type: "String", default: "2026-Q2" },
    { name: "target_gpu", type: "GPUDeviceID", default: "cpu-fallback" }
  ],
  runtime: {
    runMode: "batch"
  },
  nodes: [
    {
      id: "node-csv-reader",
      type: "io.csv_reader",
      name: "CSV Reader",
      executionHint: "cpu_only",
      ports: [{ id: "rows", direction: "output", type: "data_table" }],
      config: { path: "assets/forecast.csv", delimiter: "," }
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
      capabilities: {
        executionMode: "batch",
        resourceClass: "gpu",
        accelerator: "cuda",
        workerPool: "alpha-gpu"
      },
      ports: [
        { id: "training_frame", direction: "input", type: "data_table" },
        { id: "model", direction: "output", type: "model" }
      ],
      config: { target: "demand", validationSplit: 0.2 },
      gpuDevicePreference: "nvidia:0"
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
      config: { dashboardId: "ops-forecast", chart: "line+bar" }
    }
  ],
  connections: [
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
      sourceNodeId: "node-join",
      sourcePortId: "joined",
      targetNodeId: "node-bi-outlet",
      targetPortId: "dataset",
      dataType: "data_table"
    },
    {
      sourceNodeId: "node-model-train",
      sourcePortId: "model",
      targetNodeId: "node-bi-outlet",
      targetPortId: "score_model",
      dataType: "model"
    }
  ],
  containers: [
    {
      containerId: "container-prep",
      name: "Preparation Container",
      nodeIds: ["node-csv-reader", "node-join"],
      collapsed: false
    }
  ],
  components: [
    {
      componentId: "component-forecast-bi",
      name: "Forecast BI Component",
      nodeIds: ["node-join", "node-bi-outlet"],
      version: "0.1.0",
      flowVariableScope: "isolated",
      dashboardIds: ["ops-forecast"]
    }
  ],
  controlFlow: [
    {
      controlId: "switch-region",
      kind: "switch",
      name: "Region Switch",
      selector: "flow.region",
      cases: [
        { caseId: "north", label: "North", targetNodeId: "node-join" },
        { caseId: "default", label: "Default", targetNodeId: "node-bi-outlet" }
      ],
      defaultTargetNodeId: "node-bi-outlet"
    },
    {
      controlId: "parallel-forecast-chunks",
      kind: "parallel_chunk",
      name: "Parallel Forecast Chunks",
      sourceNodeId: "node-join",
      targetNodeId: "node-model-train",
      chunkSize: 1000,
      maxConcurrency: 4,
      resourceClass: "gpu"
    }
  ],
  graph: {
    revision: 1,
    selectedNodeId: "node-join",
    viewport: { x: 0, y: 0, zoom: 1 },
    nodeLayouts: [
      { nodeId: "node-csv-reader", x: 36, y: 44, width: 164, checkpointTag: "cp/00-foundation", notes: "Contract fixture mirrors WorkflowDefinition and node SDK port shapes." },
      { nodeId: "node-join", x: 264, y: 156, width: 188, checkpointTag: "cp/01-contracts-frozen", notes: "Execution planner seam remains explicit before multi-lane fan-out." },
      { nodeId: "node-model-train", x: 520, y: 66, width: 190, checkpointTag: "cp/02-alpha-core", notes: "Preserves BRD path for CUDA lane without blocking Phase 0 demo." },
      { nodeId: "node-bi-outlet", x: 760, y: 182, width: 174, checkpointTag: "cp/03-alpha-gpu-bi", notes: "Side rail models execution and rollback evidence for BI milestone." }
    ]
  },
  dashboards: [
    {
      dashboardId: "ops-forecast",
      name: "Ops Forecast Overview",
      binding: {
        outletNodeId: "node-bi-outlet",
        datasetKey: "forecast_rows",
        refreshMode: "live"
      },
      charts: [
        { chartId: "chart-line", title: "Demand Trend", family: "line", xField: "horizon", yField: "demand", panel: { x: 0, y: 0, w: 6, h: 4 } },
        { chartId: "chart-bar", title: "Regional Mix", family: "bar", xField: "region", yField: "demand", panel: { x: 6, y: 0, w: 6, h: 4 } },
        { chartId: "chart-area", title: "Capacity Envelope", family: "area", xField: "horizon", yField: "capacity", panel: { x: 0, y: 4, w: 6, h: 4 } },
        { chartId: "chart-table", title: "Forecast Table", family: "table", panel: { x: 6, y: 4, w: 6, h: 4 } },
        { chartId: "chart-metric", title: "Latest RMSE", family: "metric", yField: "rmse", panel: { x: 0, y: 8, w: 3, h: 2 } }
      ]
    }
  ]
};

export const starterNodeCatalog: NodeDefinition[] = [
  {
    id: "template-csv-reader",
    type: "io.csv_reader",
    name: "CSV Reader",
    executionHint: "cpu_only",
    capabilities: { executionMode: "batch", resourceClass: "cpu" },
    ports: [{ id: "rows", direction: "output", type: "data_table" }],
    config: { path: "assets/source.csv", delimiter: "," }
  },
  {
    id: "template-filter",
    type: "transform.filter_rows",
    name: "Filter Rows",
    executionHint: "cpu_only",
    capabilities: { executionMode: "batch", resourceClass: "cpu" },
    ports: [
      { id: "in", direction: "input", type: "data_table" },
      { id: "out", direction: "output", type: "data_table" }
    ],
    config: { predicate: "amount > 0" }
  },
  {
    id: "template-join",
    type: "transform.join",
    name: "Join Tables",
    executionHint: "cpu_only",
    capabilities: { executionMode: "batch", resourceClass: "cpu" },
    ports: [
      { id: "left", direction: "input", type: "data_table" },
      { id: "right", direction: "input", type: "data_table" },
      { id: "joined", direction: "output", type: "data_table" }
    ],
    config: { key: "id", mode: "inner_join" }
  },
  {
    id: "template-aggregate",
    type: "transform.aggregate",
    name: "Aggregate",
    executionHint: "cpu_only",
    capabilities: { executionMode: "batch", resourceClass: "cpu" },
    ports: [
      { id: "in", direction: "input", type: "data_table" },
      { id: "out", direction: "output", type: "data_table" }
    ],
    config: { groupBy: ["region"], metrics: ["sum(amount)"] }
  },
  {
    id: "template-train",
    type: "ml.linear_regression",
    name: "Linear Trainer",
    executionHint: "gpu_preferred",
    capabilities: { executionMode: "batch", resourceClass: "gpu", accelerator: "cuda", workerPool: "alpha-gpu" },
    ports: [
      { id: "training_frame", direction: "input", type: "data_table" },
      { id: "model", direction: "output", type: "model" }
    ],
    config: { target: "demand", validationSplit: 0.2 },
    gpuDevicePreference: "nvidia:0"
  },
  {
    id: "template-stream-source",
    type: "stream.kafka_source",
    name: "Kafka Source",
    executionHint: "cpu_only",
    capabilities: { executionMode: "stream", resourceClass: "cpu", workerPool: "alpha-stream" },
    ports: [{ id: "stream_out", direction: "output", type: "stream_channel" }],
    config: { topic: "events.input", consumerGroup: "juliaflow-alpha" }
  },
  {
    id: "template-control-trigger",
    type: "control.manual_trigger",
    name: "Manual Trigger",
    executionHint: "cpu_only",
    capabilities: { executionMode: "hybrid", resourceClass: "cpu" },
    ports: [{ id: "tick", direction: "output", type: "flow_variable" }],
    config: { cadence: "manual" }
  },
  {
    id: "template-bi-outlet",
    type: "bi.outlet",
    name: "BI Outlet",
    executionHint: "cpu_only",
    capabilities: { executionMode: "hybrid", resourceClass: "cpu" },
    ports: [
      { id: "dataset", direction: "input", type: "data_table" },
      { id: "dashboard_stream", direction: "output", type: "stream_channel" }
    ],
    config: { dashboardId: "dashboard-1", chart: "line" }
  },
  {
    id: "template-sink",
    type: "io.arrow_sink",
    name: "Arrow Sink",
    executionHint: "cpu_only",
    capabilities: { executionMode: "batch", resourceClass: "cpu" },
    ports: [{ id: "table_in", direction: "input", type: "data_table" }],
    config: { destination: "memory://output.arrow" }
  }
];

export const canvasNodeLayouts: Record<string, CanvasNodeLayout> = {
  "node-csv-reader": {
    x: 36,
    y: 44,
    width: 164,
    status: "configured",
    runtime: "Reads Arrow-ready source frame",
    checkpointTag: "cp/00-foundation",
    notes: "Contract fixture mirrors WorkflowDefinition and node SDK port shapes."
  },
  "node-join": {
    x: 264,
    y: 156,
    width: 188,
    status: "running",
    runtime: "Static planner maps batch join on CPU",
    checkpointTag: "cp/01-contracts-frozen",
    notes: "Execution planner seam remains explicit before multi-lane fan-out."
  },
  "node-model-train": {
    x: 520,
    y: 66,
    width: 190,
    status: "configured",
    runtime: "GPU hint captured, still scheduled on CPU prototype",
    checkpointTag: "cp/02-alpha-core",
    notes: "Preserves BRD path for CUDA lane without blocking Phase 0 demo."
  },
  "node-bi-outlet": {
    x: 760,
    y: 182,
    width: 174,
    status: "executed",
    runtime: "Dashboard outlet emits semantic-ready dataset",
    checkpointTag: "cp/03-alpha-gpu-bi",
    notes: "Side rail models execution and rollback evidence for BI milestone."
  }
};

export const executionRailItems: ExecutionRailItem[] = [
  {
    id: "exec-2026-04-18-001",
    workflowId: sampleWorkflow.workflowId,
    status: "running",
    trigger: "Manual canvas run",
    startedAt: "2026-04-18T11:32:00Z",
    duration: "00:03:18",
    planner: "cpu-batch-v1"
  },
  {
    id: "exec-2026-04-17-014",
    workflowId: sampleWorkflow.workflowId,
    status: "executed",
    trigger: "Checkpoint smoke test",
    startedAt: "2026-04-17T17:05:00Z",
    duration: "00:01:42",
    planner: "cpu-batch-v1"
  },
  {
    id: "exec-2026-04-16-007",
    workflowId: sampleWorkflow.workflowId,
    status: "error",
    trigger: "Schema migration rehearsal",
    startedAt: "2026-04-16T08:20:00Z",
    duration: "00:00:47",
    planner: "cpu-batch-v1"
  }
];

export const checkpointRailItems: CheckpointRailItem[] = [
  {
    tag: "cp/00-foundation",
    scope: "Repo bootstrap, contracts, CPU prototype",
    state: "ready",
    evidence: "OpenAPI snapshot + demo workflow fixture"
  },
  {
    tag: "cp/01-contracts-frozen",
    scope: "Workflow schema, node SDK, transport freeze",
    state: "validating",
    evidence: "Round-trip contract suite + generated client smoke"
  },
  {
    tag: "cp/02-alpha-core",
    scope: "Canvas, persistence, node library expansion",
    state: "blocked",
    evidence: "Pending drag graph and node repository slice"
  }
];

function executionStatusToWorkflowStatus(status: GatewayExecutionStatus): WorkflowStatus {
  switch (status) {
    case "accepted":
    case "queued":
      return "configured";
    case "running":
      return "running";
    case "completed":
      return "executed";
    case "failed":
      return "error";
  }
}

function executionRecordToWorkflowStatus(record: GatewayExecutionRecord): WorkflowStatus {
  if (record.streamLifecycleStatus === "active") {
    return "streaming_active";
  }
  return executionStatusToWorkflowStatus(record.status);
}

function toCheckpointTag(checkpoint: string, fallbackIndex: number): string {
  return checkpoint.length > 0 ? checkpoint : `cp/live-${String(fallbackIndex + 1).padStart(2, "0")}`;
}

function syntheticNodeType(index: number, nodeCount: number, biOutletCount: number): string {
  if (index === 0) {
    return "io.workflow_source";
  }
  if (index === nodeCount - 1 && biOutletCount > 0) {
    return "bi.outlet";
  }
  if (index >= Math.max(1, nodeCount - biOutletCount)) {
    return "transform.dashboard_feed";
  }
  if (index % 3 === 0) {
    return "ml.feature_stage";
  }
  if (index % 2 === 0) {
    return "transform.batch_stage";
  }
  return "io.workflow_stage";
}

function syntheticExecutionHint(index: number): "cpu_only" | "gpu_preferred" {
  return index % 3 === 2 ? "gpu_preferred" : "cpu_only";
}

export function buildWorkflowFromGateway(
  summary: GatewayWorkflowSummary,
  metadata?: GatewayWorkflowMetadata
): WorkflowDefinition {
  if (metadata && metadata.nodes.length > 0) {
    return {
      version: metadata.version,
      workflowId: metadata.workflowId,
      name: metadata.name,
      nodes: metadata.nodes,
      connections: metadata.connections,
      flowVariables: metadata.flowVariables,
      graph: metadata.graph,
      dashboards: metadata.dashboards,
      runtime: metadata.runtime
    };
  }

  const nodeCount = Math.max(1, Math.min(metadata?.nodeCount ?? summary.nodeCount, 6));
  const connectionCount = Math.max(0, metadata?.connectionCount ?? Math.max(0, nodeCount - 1));
  const flowVariableCount = Math.max(0, Math.min(metadata?.flowVariableCount ?? 2, 4));
  const biOutletCount = Math.max(0, metadata?.biOutletCount ?? 0);

  const nodes = Array.from({ length: nodeCount }, (_, index) => {
    const id = `live-node-${index + 1}`;
    const outputType: WorkflowPortType = index === nodeCount - 1 && biOutletCount > 0 ? "stream_channel" : "data_table";

    return {
      id,
      type: syntheticNodeType(index, nodeCount, biOutletCount),
      name: index === 0 ? "Gateway Source" : index === nodeCount - 1 ? "Gateway Sink" : `Stage ${index}`,
      executionHint: syntheticExecutionHint(index),
      ports: [
        ...(index > 0
          ? [{ id: "in", direction: "input" as const, type: "data_table" as const }]
          : []),
        { id: "out", direction: "output" as const, type: outputType }
      ],
      config: {
        source: "gateway-metadata",
        position: index + 1,
        connectionBudget: connectionCount
      }
    };
  });

  const connections: ConnectionDefinition[] = [];
  for (let index = 1; index < nodes.length; index += 1) {
    connections.push({
      sourceNodeId: nodes[index - 1].id,
      sourcePortId: "out",
      targetNodeId: nodes[index].id,
      targetPortId: "in",
      dataType: "data_table"
    });
  }

  return {
    version: summary.version,
    workflowId: summary.workflowId,
    name: summary.name,
    nodes,
    connections,
    flowVariables: Array.from({ length: flowVariableCount }, (_, index) => ({
      name: `live_var_${index + 1}`,
      type: index % 2 === 0 ? "String" : "GPUDeviceID",
      default: index % 2 === 0 ? `value-${index + 1}` : "cpu-fallback"
    })),
    graph: {
      revision: summary.graphRevision ?? 1,
      nodeLayouts: nodes.map((node, index) => ({
        nodeId: node.id,
        x: 36 + (index % 3) * 248,
        y: 44 + Math.floor(index / 3) * 156,
        width: 176,
        checkpointTag: milestoneCheckpoints[Math.min(index, milestoneCheckpoints.length - 1)]?.tag
      }))
    },
    runtime: {
      runMode: summary.runMode ?? "batch"
    }
  };
}

export function buildCanvasNodeLayouts(workflow: WorkflowDefinition): Record<string, CanvasNodeLayout> {
  const statuses: WorkflowStatus[] = ["configured", "running", "configured", "executed", "configured", "executed"];

  return Object.fromEntries(
    workflow.nodes.map((node, index) => {
      const layout = workflow.graph?.nodeLayouts.find((item) => item.nodeId === node.id);
      const column = index % 3;
      const row = Math.floor(index / 3);

      return [
        node.id,
        {
          x: layout?.x ?? 36 + column * 248,
          y: layout?.y ?? 44 + row * 156 + (column === 1 ? 64 : 0),
          width: layout?.width ?? 168 + (column === 1 ? 14 : 0),
          status: statuses[index % statuses.length],
          runtime:
            node.executionHint === "gpu_preferred"
              ? "Gateway metadata indicates a GPU-capable stage."
              : "Gateway metadata indicates a CPU-oriented stage.",
          checkpointTag:
            layout?.checkpointTag ?? milestoneCheckpoints[Math.min(index, milestoneCheckpoints.length - 1)]?.tag,
          notes: layout?.notes ?? `Synthetic canvas card derived from gateway metadata for ${workflow.workflowId}.`
        } satisfies CanvasNodeLayout
      ];
    })
  );
}

export function buildExecutionRailItems(records: GatewayExecutionRecord[]): ExecutionRailItem[] {
  return records.map((record) => {
    const start = record.startedAt ?? record.createdAt;
    const end = record.finishedAt ?? record.updatedAt;
    const statusEvent = record.statusHistory.at(-1);

    return {
      id: record.executionId,
      workflowId: record.workflowId,
      status: executionRecordToWorkflowStatus(record),
      trigger:
        statusEvent?.message ??
        (record.dispatchLane
          ? `Dispatched to ${record.dispatchLane} lane`
          : undefined) ??
        (record.streamLifecycleStatus
          ? `Stream lifecycle ${record.streamLifecycleStatus}`
          : `Gateway execution ${record.status}`),
      startedAt: start,
      duration: start === end ? "in-flight" : `${start} -> ${end}`,
      planner: record.streamLifecycleStatus
        ? `${record.mode} · ${record.streamLifecycleStatus}`
        : record.dispatchLane
          ? `${record.mode} · ${record.dispatchLane}/${record.dispatchWorkerPool ?? "default"}`
          : record.mode,
      controlFlowPlan: record.controlFlowPlan,
      controlFlowRecovery: record.controlFlowRecovery
    };
  });
}

export function buildCheckpointRailItems(records: GatewayCheckpointRecord[]): CheckpointRailItem[] {
  return records.map((record, index) => ({
    tag: toCheckpointTag(record.tag, index),
    scope: record.summary,
    state: index === 0 ? "ready" : index === 1 ? "validating" : "blocked",
    evidence: `Created ${record.createdAt}`
  }));
}

export function formatPortSummary(connections: ConnectionDefinition[], nodeId: string): string {
  let inbound = 0;
  let outbound = 0;

  for (const connection of connections) {
    if (connection.targetNodeId === nodeId) {
      inbound += 1;
    }
    if (connection.sourceNodeId === nodeId) {
      outbound += 1;
    }
  }

  return `${inbound} in / ${outbound} out`;
}

export function portTypeCounts(workflow: WorkflowDefinition): Array<{ type: WorkflowPortType; count: number }> {
  const counts = new Map<WorkflowPortType, number>();

  for (const node of workflow.nodes) {
    for (const port of node.ports) {
      counts.set(port.type, (counts.get(port.type) ?? 0) + 1);
    }
  }

  return Array.from(counts.entries()).map(([type, count]) => ({ type, count }));
}
