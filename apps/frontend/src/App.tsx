import { useDeferredValue, useEffect, useState, useTransition } from "react";
import {
  createGatewayClient,
  createGatewayRealtimeClient,
  milestoneCheckpoints,
  phaseSummaries,
  workflowStatuses,
  type ConnectionDefinition,
  type ExecutionHint,
  type GatewayExecutionStateChangedEvent,
  type FlowVariableDefinition,
  type GatewayHealthcheck,
  type GatewayNodeStateChangedEvent,
  type GatewayRealtimeNotification,
  type GatewayWorkflowStateChangedEvent,
  type GatewayWorkflowMetadata,
  type GatewayWorkflowSummary,
  type NodeDefinition,
  type WorkflowDefinition,
  type WorkflowStatus
} from "@juliaflow/contracts";
import { Panel, SectionTitle, StatusBadge } from "@juliaflow/ui";
import {
  buildCanvasNodeLayouts,
  buildCheckpointRailItems,
  buildExecutionRailItems,
  buildWorkflowFromGateway,
  canvasNodeLayouts,
  checkpointRailItems,
  executionRailItems,
  sampleWorkflow,
  type CanvasNodeLayout,
  type CheckpointRailItem,
  type ExecutionRailItem
} from "./sample-workflow";

const executionTabs = ["executions", "checkpoints"] as const;

type ExecutionTab = (typeof executionTabs)[number];
type DataSourceMode = "demo" | "live" | "fallback";
type ConnectionDraftDirection = "incoming" | "outgoing";
type RealtimeConnectionState = "idle" | "connecting" | "live" | "error";
type WorkflowPortDefinition = NodeDefinition["ports"][number];
type ValidationTone = "good" | "warn" | "live";
type ActionTone = "info" | "success" | "error" | "demo";

interface WorkspaceDataState {
  checkpoints: CheckpointRailItem[];
  dataSourceLabel: string;
  error: string | null;
  executionItems: ExecutionRailItem[];
  health: GatewayHealthcheck | null;
  isLoading: boolean;
  mode: DataSourceMode;
  workflow: WorkflowDefinition;
  workflows: GatewayWorkflowSummary[];
}

interface ActionFeedback {
  text: string;
  tone: ActionTone;
}

interface NodeValidationSummary {
  detail: string;
  label: string;
  tone: ValidationTone;
}

interface RealtimeNodeState {
  checkpointTag?: string;
  runtime: string;
  status: WorkflowStatus;
}

interface ConnectionDraftPreview {
  connection: ConnectionDefinition | null;
  detail: string;
  label: string;
  tone: ValidationTone;
}

function getGatewayBaseUrl(): string {
  return String(import.meta.env.VITE_JULIAFLOW_GATEWAY_BASE_URL ?? "").trim();
}

function createDemoState(): WorkspaceDataState {
  return {
    checkpoints: checkpointRailItems,
    dataSourceLabel: "Demo fixture",
    error: null,
    executionItems: executionRailItems,
    health: null,
    isLoading: false,
    mode: "demo",
    workflow: sampleWorkflow,
    workflows: []
  };
}

function createFallbackState(message: string): WorkspaceDataState {
  return {
    ...createDemoState(),
    dataSourceLabel: "Gateway fallback",
    error: message,
    mode: "fallback"
  };
}

function isSampleWorkflow(workflowSummary: GatewayWorkflowSummary): boolean {
  return workflowSummary.workflowId === sampleWorkflow.workflowId;
}

function toWorkflowShape(
  workflowSummary: GatewayWorkflowSummary,
  workflowMetadata: GatewayWorkflowMetadata | null
): WorkflowDefinition {
  if (isSampleWorkflow(workflowSummary)) {
    return {
      ...sampleWorkflow,
      name: workflowSummary.name,
      version: workflowSummary.version
    };
  }

  return buildWorkflowFromGateway(workflowSummary, workflowMetadata ?? undefined);
}

function useWorkspaceData(): WorkspaceDataState {
  const [state, setState] = useState<WorkspaceDataState>(() => createDemoState());

  useEffect(() => {
    const gatewayBaseUrl = getGatewayBaseUrl();
    if (gatewayBaseUrl.length === 0) {
      setState(createDemoState());
      return;
    }

    const abortController = new AbortController();
    const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });

    setState((currentState) => ({
      ...currentState,
      dataSourceLabel: `Gateway ${gatewayBaseUrl}`,
      isLoading: true
    }));

    async function load() {
      try {
        const [health, workflowResponse, executionResponse, checkpointResponse] = await Promise.all([
          gatewayClient.healthcheck({ signal: abortController.signal }),
          gatewayClient.listWorkflows({ signal: abortController.signal }),
          gatewayClient.listExecutions({ signal: abortController.signal }),
          gatewayClient.listCheckpoints({ signal: abortController.signal })
        ]);

        const activeWorkflow = workflowResponse.items[0] ?? null;
        const workflowMetadata =
          activeWorkflow === null
            ? null
            : await gatewayClient.getWorkflow(activeWorkflow.workflowId, {
                signal: abortController.signal
              });

        if (abortController.signal.aborted) {
          return;
        }

        setState({
          checkpoints:
            checkpointResponse.items.length > 0
              ? buildCheckpointRailItems(checkpointResponse.items)
              : checkpointRailItems,
          dataSourceLabel: `Gateway ${health.repositoryBackend}`,
          error: null,
          executionItems:
            executionResponse.items.length > 0
              ? buildExecutionRailItems(executionResponse.items)
              : executionRailItems,
          health,
          isLoading: false,
          mode: "live",
          workflow:
            activeWorkflow === null
              ? sampleWorkflow
              : toWorkflowShape(activeWorkflow, workflowMetadata),
          workflows: workflowResponse.items
        });
      } catch (error) {
        if (abortController.signal.aborted) {
          return;
        }

        const message = error instanceof Error ? error.message : "Unable to load gateway data.";
        setState(createFallbackState(message));
      }
    }

    void load();

    return () => {
      abortController.abort();
    };
  }, []);

  return state;
}

function formatNodeType(type: string): string {
  return type.replaceAll(".", " / ");
}

function formatPortType(type: string): string {
  return type.replaceAll("_", " ");
}

function summarizeConfigValue(value: unknown): string {
  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }

  if (Array.isArray(value)) {
    return value.join(", ");
  }

  if (value && typeof value === "object") {
    return `${Object.keys(value).length} fields`;
  }

  return "Not set";
}

function buildRepositoryGroupLabel(type: string): string {
  const [family = "workflow"] = type.split(".");
  return family.replaceAll("_", " ");
}

function buildStatusCounts(items: ExecutionRailItem[]): Array<{ count: number; label: WorkflowStatus }> {
  return workflowStatuses.map((status) => ({
    count: items.filter((item) => item.status === status).length,
    label: status
  }));
}

function findPortConnections(
  connections: ConnectionDefinition[],
  nodeId: string,
  port: WorkflowPortDefinition
): ConnectionDefinition[] {
  return connections.filter((connection) => {
    if (port.direction === "input") {
      return connection.targetNodeId === nodeId && connection.targetPortId === port.id;
    }
    return connection.sourceNodeId === nodeId && connection.sourcePortId === port.id;
  });
}

function buildNodeValidationSummary(
  node: NodeDefinition,
  connections: ConnectionDefinition[]
): NodeValidationSummary {
  const inputPorts = node.ports.filter((port) => port.direction === "input");
  const outputPorts = node.ports.filter((port) => port.direction === "output");
  const missingInputs = inputPorts.filter((port) => findPortConnections(connections, node.id, port).length === 0).length;
  const routedOutputs = outputPorts.filter((port) => findPortConnections(connections, node.id, port).length > 0).length;

  if (missingInputs > 0) {
    return {
      detail: `${missingInputs} required input${missingInputs === 1 ? "" : "s"} still open`,
      label: "Needs wiring",
      tone: "warn"
    };
  }

  if (outputPorts.length > 0 && routedOutputs === 0) {
    return {
      detail: "No downstream path yet",
      label: "Output pending",
      tone: "warn"
    };
  }

  if (node.executionHint === "gpu_preferred" || node.executionHint === "gpu_required") {
    return {
      detail: "Graph is wired, pending runtime target confirmation",
      label: "GPU-aware",
      tone: "live"
    };
  }

  return {
    detail: "Ports are satisfied for the current graph slice",
    label: "Ready",
    tone: "good"
  };
}

function buildValidationItems(
  node: NodeDefinition,
  layout: CanvasNodeLayout,
  connections: ConnectionDefinition[]
): Array<{ detail: string; label: string; tone: ValidationTone }> {
  const inputPorts = node.ports.filter((port) => port.direction === "input");
  const connectedInputs = inputPorts.filter((port) => findPortConnections(connections, node.id, port).length > 0);
  const outputPorts = node.ports.filter((port) => port.direction === "output");
  const routedOutputs = outputPorts.filter((port) => findPortConnections(connections, node.id, port).length > 0);
  const needsGpu = node.executionHint !== "cpu_only";
  const validationSummary = buildNodeValidationSummary(node, connections);

  return [
    {
      detail: validationSummary.detail,
      label: validationSummary.label,
      tone: validationSummary.tone
    },
    {
      detail: `${connectedInputs.length}/${inputPorts.length} inputs linked`,
      label: connectedInputs.length === inputPorts.length ? "Port compatibility" : "Open inputs",
      tone: connectedInputs.length === inputPorts.length ? "good" : "warn"
    },
    {
      detail: `${routedOutputs.length}/${outputPorts.length} outputs routed`,
      label: routedOutputs.length > 0 ? "Downstream path" : "Output path pending",
      tone: routedOutputs.length > 0 ? "good" : "warn"
    },
    {
      detail: needsGpu ? "GPU-capable target requested" : "CPU-safe target",
      label: "Execution target",
      tone: needsGpu ? "live" : "good"
    },
    {
      detail: layout.status === "running" || layout.status === "streaming_active" ? "Node is active" : "Awaiting run",
      label: "Recent run state",
      tone: layout.status === "running" || layout.status === "streaming_active" ? "live" : "warn"
    }
  ];
}

function buildSampleOutput(node: NodeDefinition): string {
  const outputPort = node.ports.find((port) => port.direction === "output");
  if (!outputPort) {
    return "No emitted sample for this node yet.";
  }

  switch (outputPort.type) {
    case "data_table":
      return "rows: 12k · schema: store_id, demand, weather_index, horizon";
    case "model":
      return "artifact: regression-v0.2 · metrics: rmse, mae, drift";
    case "stream_channel":
      return "channel: dashboard_stream · cadence: 1s refresh";
    case "flow_variable":
      return "variable payload: typed runtime parameter";
    case "gpu_buffer":
      return "gpu buffer staged for scoring lane";
    case "image":
      return "image payload queued for BI tile preview";
  }
}

function cloneNodeDefinition(node: NodeDefinition): NodeDefinition {
  return {
    ...node,
    ports: node.ports.map((port) => ({ ...port })),
    config: { ...node.config }
  };
}

function buildRepositoryCatalog(workflow: WorkflowDefinition): NodeDefinition[] {
  const catalog: NodeDefinition[] = [];
  const seenTypes = new Set<string>();

  for (const node of [...sampleWorkflow.nodes, ...workflow.nodes]) {
    if (seenTypes.has(node.type)) {
      continue;
    }
    seenTypes.add(node.type);
    catalog.push(cloneNodeDefinition(node));
  }

  return catalog;
}

function buildNodeLayoutsForWorkflow(
  workflow: WorkflowDefinition,
  mode: DataSourceMode
): Record<string, CanvasNodeLayout> {
  const baseLayouts =
    mode === "live" ? buildCanvasNodeLayouts(workflow) : Object.fromEntries(Object.entries(canvasNodeLayouts));
  const nextLayouts = { ...baseLayouts };
  let supplementalIndex = 0;

  for (const node of workflow.nodes) {
    if (nextLayouts[node.id]) {
      continue;
    }

    const index = Object.keys(baseLayouts).length + supplementalIndex;
    const column = index % 4;
    const row = Math.floor(index / 4);

    nextLayouts[node.id] = {
      x: 44 + column * 220,
      y: 56 + row * 164 + (column === 1 ? 38 : 0),
      width: 180,
      status: "configured",
      runtime: "Added from the repository during the current authoring session.",
      notes: `Draft node ${node.name} has not been persisted yet.`
    };
    supplementalIndex += 1;
  }

  return nextLayouts;
}

function buildFlowVariableDefault(type: FlowVariableDefinition["type"]): FlowVariableDefinition["default"] {
  switch (type) {
    case "Integer":
    case "Float64":
      return 0;
    case "Bool":
      return false;
    default:
      return "";
  }
}

function escapeTomlString(value: string): string {
  return value.replaceAll("\\", "\\\\").replaceAll("\"", "\\\"").replaceAll("\n", "\\n");
}

function serializeTomlValue(value: unknown): string {
  if (typeof value === "string") {
    return `"${escapeTomlString(value)}"`;
  }

  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }

  if (Array.isArray(value)) {
    return `[${value.map((item) => serializeTomlValue(item)).join(", ")}]`;
  }

  if (value === null || value === undefined) {
    return "\"\"";
  }

  return `"${escapeTomlString(JSON.stringify(value))}"`;
}

function serializeWorkflowToToml(workflow: WorkflowDefinition): string {
  const lines: string[] = [
    `version = ${serializeTomlValue(workflow.version)}`,
    `workflowId = ${serializeTomlValue(workflow.workflowId)}`,
    `name = ${serializeTomlValue(workflow.name)}`
  ];

  for (const flowVariable of workflow.flowVariables) {
    lines.push("", "[[flowVariables]]");
    lines.push(`name = ${serializeTomlValue(flowVariable.name)}`);
    lines.push(`type = ${serializeTomlValue(flowVariable.type)}`);
    if (flowVariable.default !== undefined && flowVariable.default !== null) {
      lines.push(`default = ${serializeTomlValue(flowVariable.default)}`);
    }
  }

  for (const node of workflow.nodes) {
    lines.push("", "[[nodes]]");
    lines.push(`id = ${serializeTomlValue(node.id)}`);
    lines.push(`type = ${serializeTomlValue(node.type)}`);
    lines.push(`name = ${serializeTomlValue(node.name)}`);
    lines.push(`executionHint = ${serializeTomlValue(node.executionHint)}`);
    if (node.gpuDevicePreference) {
      lines.push(`gpuDevicePreference = ${serializeTomlValue(node.gpuDevicePreference)}`);
    }

    if (Object.keys(node.config).length > 0) {
      lines.push("[nodes.config]");
      for (const [key, value] of Object.entries(node.config)) {
        lines.push(`${key} = ${serializeTomlValue(value)}`);
      }
    }

    for (const port of node.ports) {
      lines.push("[[nodes.ports]]");
      lines.push(`id = ${serializeTomlValue(port.id)}`);
      lines.push(`direction = ${serializeTomlValue(port.direction)}`);
      lines.push(`type = ${serializeTomlValue(port.type)}`);
    }
  }

  for (const connection of workflow.connections) {
    lines.push("", "[[connections]]");
    lines.push(`sourceNodeId = ${serializeTomlValue(connection.sourceNodeId)}`);
    lines.push(`sourcePortId = ${serializeTomlValue(connection.sourcePortId)}`);
    lines.push(`targetNodeId = ${serializeTomlValue(connection.targetNodeId)}`);
    lines.push(`targetPortId = ${serializeTomlValue(connection.targetPortId)}`);
    lines.push(`dataType = ${serializeTomlValue(connection.dataType)}`);
  }

  return `${lines.join("\n")}\n`;
}

function buildDraftNodeId(workflow: WorkflowDefinition, template: NodeDefinition): string {
  const baseId = template.id.replaceAll(/[^a-zA-Z0-9-_]/g, "-");
  const takenIds = new Set(workflow.nodes.map((node) => node.id));

  if (!takenIds.has(baseId)) {
    return baseId;
  }

  let index = 2;
  while (takenIds.has(`${baseId}-${index}`)) {
    index += 1;
  }
  return `${baseId}-${index}`;
}

function buildDraftNodeName(workflow: WorkflowDefinition, template: NodeDefinition): string {
  const similarNodes = workflow.nodes.filter((node) => node.type === template.type).length;
  return similarNodes === 0 ? template.name : `${template.name} ${similarNodes + 1}`;
}

function preferredConnectionDirection(node: NodeDefinition): ConnectionDraftDirection {
  const outputCount = node.ports.filter((port) => port.direction === "output").length;
  return outputCount > 0 ? "outgoing" : "incoming";
}

function buildConnectionDraftPreview(
  workflow: WorkflowDefinition,
  selectedNode: NodeDefinition,
  direction: ConnectionDraftDirection,
  peerNodeId: string,
  anchorPortId: string,
  peerPortId: string
): ConnectionDraftPreview {
  if (peerNodeId.length === 0) {
    return {
      connection: null,
      detail: "Choose node to link against selected node.",
      label: "Awaiting node",
      tone: "warn"
    };
  }

  const peerNode = workflow.nodes.find((node) => node.id === peerNodeId);
  if (!peerNode) {
    return {
      connection: null,
      detail: "Referenced peer node no longer exists in current draft.",
      label: "Node missing",
      tone: "warn"
    };
  }

  const anchorDirection = direction === "outgoing" ? "output" : "input";
  const peerDirection = direction === "outgoing" ? "input" : "output";
  const anchorPort = selectedNode.ports.find(
    (port) => port.id === anchorPortId && port.direction === anchorDirection
  );
  const peerPort = peerNode.ports.find(
    (port) => port.id === peerPortId && port.direction === peerDirection
  );

  if (!anchorPort || !peerPort) {
    return {
      connection: null,
      detail: "Select compatible source and target ports first.",
      label: "Awaiting ports",
      tone: "warn"
    };
  }

  if (anchorPort.type !== peerPort.type) {
    return {
      connection: null,
      detail: `${selectedNode.name}.${anchorPort.id} emits ${formatPortType(anchorPort.type)}, but ${peerNode.name}.${peerPort.id} expects ${formatPortType(peerPort.type)}.`,
      label: "Type mismatch",
      tone: "warn"
    };
  }

  const connection =
    direction === "outgoing"
      ? {
          sourceNodeId: selectedNode.id,
          sourcePortId: anchorPort.id,
          targetNodeId: peerNode.id,
          targetPortId: peerPort.id,
          dataType: anchorPort.type
        }
      : {
          sourceNodeId: peerNode.id,
          sourcePortId: peerPort.id,
          targetNodeId: selectedNode.id,
          targetPortId: anchorPort.id,
          dataType: anchorPort.type
        };

  const duplicateConnection = workflow.connections.find(
    (item) =>
      item.sourceNodeId === connection.sourceNodeId &&
      item.sourcePortId === connection.sourcePortId &&
      item.targetNodeId === connection.targetNodeId &&
      item.targetPortId === connection.targetPortId
  );
  if (duplicateConnection) {
    return {
      connection: null,
      detail: "This edge already exists in current graph slice.",
      label: "Duplicate edge",
      tone: "warn"
    };
  }

  const targetPortAlreadyLinked = workflow.connections.find(
    (item) =>
      item.targetNodeId === connection.targetNodeId && item.targetPortId === connection.targetPortId
  );
  if (targetPortAlreadyLinked) {
    return {
      connection: null,
      detail: `${connection.targetNodeId}.${connection.targetPortId} already has inbound edge.`,
      label: "Target occupied",
      tone: "warn"
    };
  }

  return {
    connection,
    detail: `${connection.sourceNodeId}.${connection.sourcePortId} -> ${connection.targetNodeId}.${connection.targetPortId} (${formatPortType(connection.dataType)})`,
    label: "Compatible edge",
    tone: "good"
  };
}

function describeConnection(
  workflow: WorkflowDefinition,
  connection: ConnectionDefinition
): string {
  const sourceNode = workflow.nodes.find((node) => node.id === connection.sourceNodeId);
  const targetNode = workflow.nodes.find((node) => node.id === connection.targetNodeId);
  const sourceLabel = sourceNode ? `${sourceNode.name}.${connection.sourcePortId}` : connection.sourceNodeId;
  const targetLabel = targetNode ? `${targetNode.name}.${connection.targetPortId}` : connection.targetNodeId;
  return `${sourceLabel} -> ${targetLabel}`;
}

function buildAutoConnection(
  currentWorkflow: WorkflowDefinition,
  selectedNodeId: string,
  nextNode: NodeDefinition
): ConnectionDefinition | null {
  const selectedNode = currentWorkflow.nodes.find((node) => node.id === selectedNodeId);
  if (!selectedNode) {
    return null;
  }

  const selectedOutputs = selectedNode.ports.filter((port) => port.direction === "output");
  const nextInputs = nextNode.ports.filter((port) => port.direction === "input");

  for (const output of selectedOutputs) {
    const matchingInput = nextInputs.find((input) => input.type === output.type);
    if (matchingInput) {
      return {
        sourceNodeId: selectedNode.id,
        sourcePortId: output.id,
        targetNodeId: nextNode.id,
        targetPortId: matchingInput.id,
        dataType: output.type
      };
    }
  }

  const selectedInputs = selectedNode.ports.filter((port) => port.direction === "input");
  const nextOutputs = nextNode.ports.filter((port) => port.direction === "output");

  for (const output of nextOutputs) {
    const matchingInput = selectedInputs.find((input) => input.type === output.type);
    if (matchingInput) {
      return {
        sourceNodeId: nextNode.id,
        sourcePortId: output.id,
        targetNodeId: selectedNode.id,
        targetPortId: matchingInput.id,
        dataType: output.type
      };
    }
  }

  return null;
}

function buildDraftExecution(workflow: WorkflowDefinition, trigger: string, status: WorkflowStatus): ExecutionRailItem {
  const timestamp = new Date().toISOString();

  return {
    id: `exec-demo-${Date.now()}`,
    workflowId: workflow.workflowId,
    status,
    trigger,
    startedAt: timestamp,
    duration: status === "running" ? "in-flight" : "00:00:01",
    planner: "frontend-demo"
  };
}

function buildActionTimestampLabel(): string {
  return new Date().toISOString().replace("T", " ").replace("Z", " UTC");
}

function buildRealtimeRuntimeLabel(
  status: WorkflowStatus,
  executionHint: ExecutionHint
): string {
  if (status === "running") {
    return executionHint === "cpu_only"
      ? "Realtime canvas pulse: CPU stage active."
      : "Realtime canvas pulse: accelerated stage active.";
  }

  if (status === "executed") {
    return "Realtime canvas pulse: latest stage completed.";
  }

  if (status === "error") {
    return "Realtime canvas pulse: latest stage reported failure.";
  }

  return executionHint === "cpu_only"
    ? "Realtime canvas pulse: stage configured on CPU path."
    : "Realtime canvas pulse: stage configured with GPU-aware path.";
}

function mergeExecutionRailItem(
  currentItems: ExecutionRailItem[],
  nextItem: ExecutionRailItem
): ExecutionRailItem[] {
  return [nextItem, ...currentItems.filter((item) => item.id !== nextItem.id)];
}

function mergeNodeLayouts(
  baseLayouts: Record<string, CanvasNodeLayout>,
  overrides: Record<string, RealtimeNodeState>
): Record<string, CanvasNodeLayout> {
  const nextLayouts = { ...baseLayouts };

  for (const [nodeId, override] of Object.entries(overrides)) {
    const currentLayout = nextLayouts[nodeId];
    if (!currentLayout) {
      continue;
    }

    nextLayouts[nodeId] = {
      ...currentLayout,
      checkpointTag: override.checkpointTag ?? currentLayout.checkpointTag,
      runtime: override.runtime,
      status: override.status
    };
  }

  return nextLayouts;
}

function parseNumericValue(rawValue: string, type: FlowVariableDefinition["type"]): number {
  if (type === "Integer") {
    return Number.parseInt(rawValue || "0", 10);
  }
  return Number.parseFloat(rawValue || "0");
}

function NodePort({
  direction,
  isConnected,
  port
}: {
  direction: "input" | "output";
  isConnected: boolean;
  port: WorkflowPortDefinition;
}) {
  return (
    <div
      className={`node-port is-${direction} ${isConnected ? "is-connected" : "is-open"}`}
      data-port-type={port.type}
    >
      <span className="node-port-dot" aria-hidden="true" />
      <small>{port.id}</small>
      <strong>{formatPortType(port.type)}</strong>
    </div>
  );
}

function NodeCard({
  connections,
  isDimmed,
  isSelected,
  layout,
  node,
  onSelect,
  validation
}: {
  connections: ConnectionDefinition[];
  isDimmed: boolean;
  isSelected: boolean;
  layout: CanvasNodeLayout;
  node: NodeDefinition;
  onSelect: (nodeId: string) => void;
  validation: NodeValidationSummary;
}) {
  const inputPorts = node.ports.filter((port) => port.direction === "input");
  const outputPorts = node.ports.filter((port) => port.direction === "output");

  return (
    <button
      aria-label={`Select ${node.name}`}
      className={`canvas-node is-${validation.tone} ${isSelected ? "is-selected" : ""} ${isDimmed ? "is-dimmed" : ""}`}
      onClick={() => {
        onSelect(node.id);
      }}
      style={{
        left: `${layout.x}px`,
        top: `${layout.y}px`,
        width: layout.width ? `${layout.width}px` : undefined
      }}
      type="button"
    >
      <div className="canvas-node-head">
        <span className="canvas-node-type">{formatNodeType(node.type)}</span>
        <StatusBadge label={layout.status} />
      </div>
      <strong>{node.name}</strong>
      <small className="canvas-node-runtime">{layout.runtime}</small>
      <div className={`canvas-node-validation is-${validation.tone}`}>
        <strong>{validation.label}</strong>
        <span>{validation.detail}</span>
      </div>
      <div className="canvas-node-ports">
        <div className="node-port-column">
          {inputPorts.map((port) => (
            <NodePort
              direction="input"
              isConnected={findPortConnections(connections, node.id, port).length > 0}
              key={port.id}
              port={port}
            />
          ))}
        </div>
        <div className="node-port-column is-output">
          {outputPorts.map((port) => (
            <NodePort
              direction="output"
              isConnected={findPortConnections(connections, node.id, port).length > 0}
              key={port.id}
              port={port}
            />
          ))}
        </div>
      </div>
    </button>
  );
}

function CanvasConnection({
  connection,
  isActive,
  isDimmed,
  layouts
}: {
  connection: ConnectionDefinition;
  isActive: boolean;
  isDimmed: boolean;
  layouts: Record<string, CanvasNodeLayout>;
}) {
  const sourceLayout = layouts[connection.sourceNodeId];
  const targetLayout = layouts[connection.targetNodeId];

  if (!sourceLayout || !targetLayout) {
    return null;
  }

  const sourceWidth = sourceLayout.width ?? 190;
  const startX = sourceLayout.x + sourceWidth;
  const startY = sourceLayout.y + 66;
  const endX = targetLayout.x;
  const endY = targetLayout.y + 66;
  const width = Math.hypot(endX - startX, endY - startY);
  const angle = Math.atan2(endY - startY, endX - startX);

  return (
    <div
      aria-hidden="true"
      className={`canvas-edge ${isActive ? "is-active" : ""} ${isDimmed ? "is-dimmed" : ""}`}
      data-port-type={connection.dataType}
      style={{
        left: `${startX}px`,
        top: `${startY}px`,
        transform: `rotate(${angle}rad)`,
        width: `${width}px`
      }}
    >
      <span>{formatPortType(connection.dataType)}</span>
    </div>
  );
}

function RepositoryEntry({
  node,
  onAdd,
  selectedType
}: {
  node: NodeDefinition;
  onAdd: (node: NodeDefinition) => void;
  selectedType: string;
}) {
  return (
    <button
      aria-label={`Add ${node.name} to workflow`}
      className={`repository-item ${selectedType === node.type ? "is-selected" : ""}`}
      onClick={() => {
        onAdd(node);
      }}
      type="button"
    >
      <div className="repository-copy">
        <strong>{node.name}</strong>
        <span>{formatNodeType(node.type)}</span>
      </div>
      <div className="repository-meta">
        <small>{node.executionHint}</small>
        <span className="repository-action">Add node</span>
      </div>
    </button>
  );
}

function PortSchema({
  connections,
  node,
  port
}: {
  connections: ConnectionDefinition[];
  node: NodeDefinition;
  port: WorkflowPortDefinition;
}) {
  const linkedCount = findPortConnections(connections, node.id, port).length;

  return (
    <div className="inspector-row">
      <strong>{port.id}</strong>
      <span>
        {formatPortType(port.type)} · {linkedCount > 0 ? `${linkedCount} linked` : "open"}
      </span>
    </div>
  );
}

function App() {
  const workspaceData = useWorkspaceData();
  const gatewayBaseUrl = getGatewayBaseUrl();
  const [query, setQuery] = useState("");
  const [selectedNodeId, setSelectedNodeId] = useState(
    workspaceData.workflow.nodes[1]?.id ?? workspaceData.workflow.nodes[0]?.id ?? ""
  );
  const [activeRail, setActiveRail] = useState<ExecutionTab>("executions");
  const [workflow, setWorkflow] = useState<WorkflowDefinition>(workspaceData.workflow);
  const [executionItems, setExecutionItems] = useState<ExecutionRailItem[]>(workspaceData.executionItems);
  const [knownWorkflowIds, setKnownWorkflowIds] = useState<string[]>(
    workspaceData.workflows.map((item) => item.workflowId)
  );
  const [isDirty, setIsDirty] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isRunningWorkflow, setIsRunningWorkflow] = useState(false);
  const [actionFeedback, setActionFeedback] = useState<ActionFeedback | null>(null);
  const [connectionDraftDirection, setConnectionDraftDirection] =
    useState<ConnectionDraftDirection>("outgoing");
  const [connectionDraftPeerNodeId, setConnectionDraftPeerNodeId] = useState("");
  const [connectionDraftAnchorPortId, setConnectionDraftAnchorPortId] = useState("");
  const [connectionDraftPeerPortId, setConnectionDraftPeerPortId] = useState("");
  const [realtimeConnectionState, setRealtimeConnectionState] =
    useState<RealtimeConnectionState>("idle");
  const [realtimeNodeStates, setRealtimeNodeStates] = useState<Record<string, RealtimeNodeState>>(
    {}
  );
  const [isPending, startTransition] = useTransition();
  const deferredQuery = useDeferredValue(query);
  const normalizedNeedle = deferredQuery.trim().toLowerCase();

  useEffect(() => {
    setWorkflow(workspaceData.workflow);
    setExecutionItems(workspaceData.executionItems);
    setKnownWorkflowIds(workspaceData.workflows.map((item) => item.workflowId));
    setRealtimeNodeStates({});
    setIsDirty(false);
  }, [workspaceData.executionItems, workspaceData.workflow, workspaceData.workflows]);

  useEffect(() => {
    if (gatewayBaseUrl.length === 0 || workflow.workflowId.length === 0) {
      setRealtimeConnectionState("idle");
      return;
    }

    let isClosed = false;
    const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });
    const realtimeClient = createGatewayRealtimeClient({ baseUrl: gatewayBaseUrl });

    async function refreshExecutionItems() {
      const executionResponse = await gatewayClient.listExecutions();
      if (isClosed) {
        return;
      }

      startTransition(() => {
        setExecutionItems(buildExecutionRailItems(executionResponse.items));
      });
    }

    async function refreshWorkflowSnapshot(event: GatewayWorkflowStateChangedEvent) {
      if (isDirty || event.workflowId !== workflow.workflowId) {
        return;
      }

      const metadata = await gatewayClient.getWorkflow(event.workflowId);
      if (isClosed) {
        return;
      }

      startTransition(() => {
        setWorkflow(
          buildWorkflowFromGateway(
            {
              workflowId: event.workflowId,
              name: event.name,
              version: event.version,
              nodeCount: event.nodeCount,
              latestCheckpoint: event.latestCheckpoint
            },
            metadata
          )
        );
      });
    }

    function handleNodeStateChanged(event: GatewayNodeStateChangedEvent) {
      if (event.workflowId !== workflow.workflowId) {
        return;
      }

      startTransition(() => {
        setRealtimeNodeStates((currentStates) => ({
          ...currentStates,
          [event.nodeId]: {
            checkpointTag: milestoneCheckpoints[2]?.tag,
            runtime: buildRealtimeRuntimeLabel(event.status, event.executionHint),
            status: event.status
          }
        }));
      });
    }

    function handleExecutionStateChanged(event: GatewayExecutionStateChangedEvent) {
      const nextExecutionItem = buildExecutionRailItems([event])[0];
      startTransition(() => {
        setExecutionItems((currentItems) => mergeExecutionRailItem(currentItems, nextExecutionItem));
      });
    }

    async function handleRealtimeMessage(message: MessageEvent) {
      const payload = JSON.parse(String(message.data)) as GatewayRealtimeNotification | { id?: number };
      if (!("method" in payload)) {
        return;
      }

      if (payload.method === "node.state.changed") {
        handleNodeStateChanged(payload.params);
        return;
      }

      if (payload.method === "execution.state.changed") {
        handleExecutionStateChanged(payload.params);
        return;
      }

      if (payload.method === "workflow.state.changed") {
        setKnownWorkflowIds((currentIds) =>
          currentIds.includes(payload.params.workflowId)
            ? currentIds
            : [...currentIds, payload.params.workflowId]
        );
        await Promise.all([refreshExecutionItems(), refreshWorkflowSnapshot(payload.params)]);
      }
    }

    setRealtimeConnectionState("connecting");

    const handleOpen = () => {
      setRealtimeConnectionState("live");
      void realtimeClient
        .request("canvas.subscribe", {
          workflowId: workflow.workflowId
        })
        .catch((error: unknown) => {
          if (isClosed) {
            return;
          }
          const message =
            error instanceof Error ? error.message : "Unable to subscribe to realtime canvas.";
          setRealtimeConnectionState("error");
          setActionFeedback({ text: `Realtime sync failed: ${message}`, tone: "error" });
        });
    };

    const handleClose = () => {
      if (!isClosed) {
        setRealtimeConnectionState("error");
      }
    };

    const handleError = () => {
      setRealtimeConnectionState("error");
    };

    realtimeClient.socket.addEventListener("open", handleOpen);
    const handleMessage = (event: MessageEvent) => {
      void handleRealtimeMessage(event);
    };

    realtimeClient.socket.addEventListener("message", handleMessage);
    realtimeClient.socket.addEventListener("close", handleClose);
    realtimeClient.socket.addEventListener("error", handleError);

    return () => {
      isClosed = true;
      realtimeClient.socket.removeEventListener("open", handleOpen);
      realtimeClient.socket.removeEventListener("message", handleMessage);
      realtimeClient.socket.removeEventListener("close", handleClose);
      realtimeClient.socket.removeEventListener("error", handleError);
      realtimeClient.close(1000, "workflow changed");
    };
  }, [gatewayBaseUrl, isDirty, startTransition, workflow.workflowId]);

  useEffect(() => {
    const nodeIds = new Set(workflow.nodes.map((node) => node.id));
    if (!nodeIds.has(selectedNodeId)) {
      setSelectedNodeId(workflow.nodes[1]?.id ?? workflow.nodes[0]?.id ?? "");
    }
  }, [selectedNodeId, workflow]);

  const selectedNodeForDraft = workflow.nodes.find((node) => node.id === selectedNodeId) ?? workflow.nodes[0];

  useEffect(() => {
    setConnectionDraftDirection(preferredConnectionDirection(selectedNodeForDraft));
  }, [selectedNodeForDraft]);

  useEffect(() => {
    const nextPeerNode = workflow.nodes.find((node) => node.id !== selectedNodeForDraft.id) ?? null;
    if (nextPeerNode === null) {
      setConnectionDraftPeerNodeId("");
      return;
    }

    setConnectionDraftPeerNodeId((currentPeerNodeId) => {
      if (currentPeerNodeId.length > 0 && currentPeerNodeId !== selectedNodeForDraft.id) {
        const existingPeerNode = workflow.nodes.find((node) => node.id === currentPeerNodeId);
        if (existingPeerNode) {
          return currentPeerNodeId;
        }
      }

      return nextPeerNode.id;
    });
  }, [selectedNodeForDraft.id, workflow.nodes]);

  const repositoryCatalog = buildRepositoryCatalog(workflow);
  const filteredRepositoryNodes = repositoryCatalog.filter((node) => {
    if (!normalizedNeedle) {
      return true;
    }
    return `${node.name} ${node.type} ${node.executionHint}`.toLowerCase().includes(normalizedNeedle);
  });

  const filteredPhases = phaseSummaries.filter((phase) => {
    if (!normalizedNeedle) {
      return true;
    }
    return `${phase.id} ${phase.title} ${phase.exitGate}`.toLowerCase().includes(normalizedNeedle);
  });

  const nodeLayouts = mergeNodeLayouts(
    buildNodeLayoutsForWorkflow(workflow, workspaceData.mode),
    realtimeNodeStates
  );
  const matchedNodeIds = new Set(
    workflow.nodes
      .filter((node) => {
        if (!normalizedNeedle) {
          return true;
        }
        return `${node.name} ${node.type} ${node.executionHint}`.toLowerCase().includes(normalizedNeedle);
      })
      .map((node) => node.id)
  );
  const validationByNodeId = Object.fromEntries(
    workflow.nodes.map((node) => [node.id, buildNodeValidationSummary(node, workflow.connections)])
  ) as Record<string, NodeValidationSummary>;
  const selectedNode = selectedNodeForDraft;
  const peerNodes = workflow.nodes.filter((node) => node.id !== selectedNode.id);
  const selectedPeerNode = peerNodes.find((node) => node.id === connectionDraftPeerNodeId) ?? peerNodes[0] ?? null;
  const anchorPorts = selectedNode.ports.filter((port) =>
    connectionDraftDirection === "outgoing" ? port.direction === "output" : port.direction === "input"
  );
  const peerPorts = (selectedPeerNode?.ports ?? []).filter((port) =>
    connectionDraftDirection === "outgoing" ? port.direction === "input" : port.direction === "output"
  );
  const selectedNodeLayout = nodeLayouts[selectedNode.id];
  const latestExecution = executionItems[0] ?? null;
  const validationItems = buildValidationItems(selectedNode, selectedNodeLayout, workflow.connections);
  const sampleOutput = buildSampleOutput(selectedNode);
  const repositoryFamilies = new Set(workflow.nodes.map((node) => buildRepositoryGroupLabel(node.type)));
  const biOutletNode = workflow.nodes.find((node) => node.type === "bi.outlet") ?? null;
  const selectedSliceNodeIds = new Set<string>([selectedNode.id]);
  const statusCounts = buildStatusCounts(executionItems);
  const unresolvedNodeCount = workflow.nodes.filter((node) => validationByNodeId[node.id].tone === "warn").length;
  const quickAddNodes = repositoryCatalog.slice(0, 3);
  const workflowExistsOnGateway = knownWorkflowIds.includes(workflow.workflowId) || workspaceData.mode === "live";
  const relatedConnections = workflow.connections.filter(
    (connection) =>
      connection.sourceNodeId === selectedNode.id || connection.targetNodeId === selectedNode.id
  );
  const connectionPreview = buildConnectionDraftPreview(
    workflow,
    selectedNode,
    connectionDraftDirection,
    selectedPeerNode?.id ?? "",
    connectionDraftAnchorPortId,
    connectionDraftPeerPortId
  );

  for (const connection of workflow.connections) {
    if (connection.sourceNodeId === selectedNode.id || connection.targetNodeId === selectedNode.id) {
      selectedSliceNodeIds.add(connection.sourceNodeId);
      selectedSliceNodeIds.add(connection.targetNodeId);
    }
  }

  useEffect(() => {
    const nextAnchorPortId = anchorPorts[0]?.id ?? "";
    setConnectionDraftAnchorPortId((currentAnchorPortId) =>
      anchorPorts.some((port) => port.id === currentAnchorPortId) ? currentAnchorPortId : nextAnchorPortId
    );
  }, [anchorPorts]);

  useEffect(() => {
    const nextPeerPortId = peerPorts[0]?.id ?? "";
    setConnectionDraftPeerPortId((currentPeerPortId) =>
      peerPorts.some((port) => port.id === currentPeerPortId) ? currentPeerPortId : nextPeerPortId
    );
  }, [peerPorts]);

  function updateWorkflowDraft(updater: (currentWorkflow: WorkflowDefinition) => WorkflowDefinition) {
    setWorkflow((currentWorkflow) => updater(currentWorkflow));
    setIsDirty(true);
  }

  async function persistWorkflow(reason: "save" | "run"): Promise<string | null> {
    if (gatewayBaseUrl.length === 0) {
      setActionFeedback({
        text: `${reason === "save" ? "Draft saved" : "Draft prepared"} locally at ${buildActionTimestampLabel()}.`,
        tone: "demo"
      });
      setIsDirty(false);
      return workflow.workflowId;
    }

    setIsSaving(true);
    setActionFeedback({
      text: reason === "save" ? "Saving workflow draft to gateway..." : "Syncing workflow draft before run...",
      tone: "info"
    });

    try {
      const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });
      const workflowToml = serializeWorkflowToToml(workflow);
      const response = workflowExistsOnGateway
        ? await gatewayClient.updateWorkflow(workflow.workflowId, { workflowToml })
        : await gatewayClient.createWorkflow({ workflowToml });

      setKnownWorkflowIds((currentIds) =>
        currentIds.includes(response.workflowId) ? currentIds : [...currentIds, response.workflowId]
      );
      setWorkflow((currentWorkflow) => ({
        ...currentWorkflow,
        workflowId: response.workflowId,
        name: response.name,
        version: response.version
      }));
      setIsDirty(false);
      setActionFeedback({
        text: `${response.status === "created" ? "Created" : "Updated"} ${response.workflowId} at ${buildActionTimestampLabel()}.`,
        tone: "success"
      });
      return response.workflowId;
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unable to persist workflow.";
      setActionFeedback({ text: `Save failed: ${message}`, tone: "error" });
      return null;
    } finally {
      setIsSaving(false);
    }
  }

  async function handleRunWorkflow() {
    setIsRunningWorkflow(true);
    setActiveRail("executions");

    try {
      let workflowId = workflow.workflowId;
      if (isDirty) {
        const persistedWorkflowId = await persistWorkflow("run");
        if (persistedWorkflowId === null) {
          return;
        }
        workflowId = persistedWorkflowId;
      }

      if (gatewayBaseUrl.length === 0) {
        const draftExecution = buildDraftExecution(workflow, "Demo canvas run", "running");
        setExecutionItems((currentItems) => [draftExecution, ...currentItems]);
        setActionFeedback({
          text: `Demo run queued for ${workflowId} at ${buildActionTimestampLabel()}.`,
          tone: "demo"
        });
        return;
      }

      const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });
      const executionRecord = await gatewayClient.executeWorkflow(workflowId);
      const nextExecutionItem = buildExecutionRailItems([executionRecord])[0];
      setExecutionItems((currentItems) => [nextExecutionItem, ...currentItems.filter((item) => item.id !== nextExecutionItem.id)]);
      setActionFeedback({
        text: `Run started for ${workflowId}: ${executionRecord.executionId}.`,
        tone: "success"
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unable to start workflow.";
      setActionFeedback({ text: `Run failed: ${message}`, tone: "error" });
    } finally {
      setIsRunningWorkflow(false);
    }
  }

  function handleAddNode(template: NodeDefinition) {
    const nextNode = cloneNodeDefinition(template);
    nextNode.id = buildDraftNodeId(workflow, template);
    nextNode.name = buildDraftNodeName(workflow, template);
    const autoConnection = buildAutoConnection(workflow, selectedNodeId, nextNode);

    updateWorkflowDraft((currentWorkflow) => ({
      ...currentWorkflow,
      nodes: [...currentWorkflow.nodes, nextNode],
      connections:
        autoConnection === null
          ? currentWorkflow.connections
          : [...currentWorkflow.connections, autoConnection]
    }));

    setSelectedNodeId(nextNode.id);
    setActionFeedback({
      text:
        autoConnection === null
          ? `${nextNode.name} added to the draft graph.`
          : `${nextNode.name} added and linked into the current graph slice.`,
      tone: "info"
    });
  }

  function handleFlowVariableChange(
    index: number,
    updates: Partial<FlowVariableDefinition>
  ) {
    updateWorkflowDraft((currentWorkflow) => ({
      ...currentWorkflow,
      flowVariables: currentWorkflow.flowVariables.map((flowVariable, flowVariableIndex) =>
        flowVariableIndex === index ? { ...flowVariable, ...updates } : flowVariable
      )
    }));
  }

  function handleAddFlowVariable() {
    updateWorkflowDraft((currentWorkflow) => ({
      ...currentWorkflow,
      flowVariables: [
        ...currentWorkflow.flowVariables,
        {
          name: `variable_${currentWorkflow.flowVariables.length + 1}`,
          type: "String",
          default: ""
        }
      ]
    }));
    setActionFeedback({ text: "Added a new flow variable to the draft.", tone: "info" });
  }

  function handleRemoveFlowVariable(index: number) {
    updateWorkflowDraft((currentWorkflow) => ({
      ...currentWorkflow,
      flowVariables: currentWorkflow.flowVariables.filter((_, flowVariableIndex) => flowVariableIndex !== index)
    }));
    setActionFeedback({ text: "Removed the selected flow variable from the draft.", tone: "info" });
  }

  function handleAddConnection() {
    if (connectionPreview.connection === null) {
      setActionFeedback({
        text: `Connection blocked: ${connectionPreview.detail}`,
        tone: "error"
      });
      return;
    }

    updateWorkflowDraft((currentWorkflow) => ({
      ...currentWorkflow,
      connections: [...currentWorkflow.connections, connectionPreview.connection!]
    }));
    setActionFeedback({
      text: `Added edge ${connectionPreview.connection.sourcePortId} -> ${connectionPreview.connection.targetPortId}.`,
      tone: "success"
    });
  }

  function handleRemoveConnection(connection: ConnectionDefinition) {
    updateWorkflowDraft((currentWorkflow) => ({
      ...currentWorkflow,
      connections: currentWorkflow.connections.filter(
        (item) =>
          !(
            item.sourceNodeId === connection.sourceNodeId &&
            item.sourcePortId === connection.sourcePortId &&
            item.targetNodeId === connection.targetNodeId &&
            item.targetPortId === connection.targetPortId
          )
      )
    }));
    setActionFeedback({
      text: `Removed edge ${connection.sourcePortId} -> ${connection.targetPortId}.`,
      tone: "info"
    });
  }

  return (
    <div className="app-shell">
      <header className="workspace-header">
        <div className="workspace-header-copy">
          <p className="eyebrow">JuliaFlow Alpha</p>
          <h1>Primary authoring workspace</h1>
          <p className="lede">
            Build pipelines first: browse nodes, reason about typed graph links, and tune the selected
            node with runtime-aware context while BI remains a visible downstream path.
          </p>
        </div>
        <div className="workspace-header-status" aria-live="polite">
          <span className={`source-pill is-${workspaceData.mode}`}>{workspaceData.dataSourceLabel}</span>
          {gatewayBaseUrl.length > 0 ? (
            <span className="hero-status-copy">Realtime {realtimeConnectionState}</span>
          ) : null}
          <span className="hero-status-copy">{workflow.name}</span>
          <span className="hero-status-copy">{workflow.version}</span>
          {isDirty ? <span className="hero-status-copy">Unsaved draft changes</span> : null}
          {workspaceData.isLoading ? <span className="hero-status-copy">Syncing gateway snapshot...</span> : null}
          {workspaceData.error ? <span className="hero-status-copy">Fallback active: {workspaceData.error}</span> : null}
          {workspaceData.health ? (
            <span className="hero-status-copy">
              {workspaceData.health.workflowCount} workflows · {workspaceData.health.executionCount} executions
            </span>
          ) : null}
        </div>
      </header>

      <main className="workspace-main">
        <section className="workspace-stage panel">
          <div className="panel-inner workspace-stage-inner">
            <div className="workspace-overview">
              <div>
                <p className="panel-kicker">Workflow canvas</p>
                <h2 className="workspace-title">{workflow.name}</h2>
                <p className="panel-detail">
                  The canvas is the primary interaction surface. Repository browse, graph reasoning, and
                  the selected node inspector all stay in one line of sight.
                </p>
              </div>
              <div className="workspace-metrics" aria-label="Workflow workspace metrics">
                <div className="metric-tile">
                  <span>Node families</span>
                  <strong>{repositoryFamilies.size || 1}</strong>
                </div>
                <div className="metric-tile">
                  <span>Flow variables</span>
                  <strong>{workflow.flowVariables.length}</strong>
                </div>
                <div className="metric-tile">
                  <span>Connections</span>
                  <strong>{workflow.connections.length}</strong>
                </div>
                <div className="metric-tile">
                  <span>Validation gaps</span>
                  <strong>{unresolvedNodeCount}</strong>
                </div>
              </div>
            </div>

            <div className="builder-grid">
              <aside className="repository-panel">
                <div className="repository-header">
                  <div>
                    <p className="panel-kicker">Node repository</p>
                    <h3>Browse and quick-add</h3>
                  </div>
                  <span>{filteredRepositoryNodes.length} results</span>
                </div>

                <label className="search-field">
                  <span>Search node packs</span>
                  <input
                    onChange={(event) => {
                      const nextValue = event.target.value;
                      startTransition(() => {
                        setQuery(nextValue);
                      });
                    }}
                    placeholder="Search csv, join, model, outlet..."
                    type="search"
                    value={query}
                  />
                </label>

                <div className="quick-add-panel">
                  <div className="quick-add-head">
                    <span>Quick add</span>
                    <small>Alpha cue</small>
                  </div>
                  <div className="quick-add-list">
                    {quickAddNodes.map((node) => (
                      <button
                        className="quick-add-chip"
                        key={node.type}
                        onClick={() => {
                          handleAddNode(node);
                        }}
                        type="button"
                      >
                        + {node.name}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="flow-variable-panel">
                  <div className="quick-add-head">
                    <span>Flow variables</span>
                    <small>{workflow.flowVariables.length} exposed</small>
                  </div>
                  <button className="secondary-action-button is-full-width" onClick={handleAddFlowVariable} type="button">
                    Add flow variable
                  </button>
                  <div className="flow-variable-editor-list">
                    {workflow.flowVariables.map((flowVariable, index) => (
                      <article className="flow-variable-editor" key={`${flowVariable.name}-${index}`}>
                        <div className="flow-variable-editor-head">
                          <strong>{flowVariable.name}</strong>
                          <button
                            aria-label={`Remove ${flowVariable.name}`}
                            className="danger-action-button"
                            onClick={() => {
                              handleRemoveFlowVariable(index);
                            }}
                            type="button"
                          >
                            Remove
                          </button>
                        </div>
                        <label className="flow-variable-field">
                          <span>Name</span>
                          <input
                            aria-label={`Variable name ${flowVariable.name}`}
                            onChange={(event) => {
                              handleFlowVariableChange(index, { name: event.target.value });
                            }}
                            type="text"
                            value={flowVariable.name}
                          />
                        </label>
                        <label className="flow-variable-field">
                          <span>Type</span>
                          <select
                            aria-label={`Variable type ${flowVariable.name}`}
                            onChange={(event) => {
                              const nextType = event.target.value as FlowVariableDefinition["type"];
                              handleFlowVariableChange(index, {
                                type: nextType,
                                default: buildFlowVariableDefault(nextType)
                              });
                            }}
                            value={flowVariable.type}
                          >
                            <option value="String">String</option>
                            <option value="Integer">Integer</option>
                            <option value="Float64">Float64</option>
                            <option value="Bool">Bool</option>
                            <option value="DateTime">DateTime</option>
                            <option value="GPUDeviceID">GPUDeviceID</option>
                          </select>
                        </label>
                        {flowVariable.type === "Bool" ? (
                          <label className="flow-variable-field">
                            <span>Default</span>
                            <input
                              aria-label={`Variable default ${flowVariable.name}`}
                              checked={Boolean(flowVariable.default)}
                              onChange={(event) => {
                                handleFlowVariableChange(index, { default: event.target.checked });
                              }}
                              type="checkbox"
                            />
                          </label>
                        ) : (
                          <label className="flow-variable-field">
                            <span>Default</span>
                            <input
                              aria-label={`Variable default ${flowVariable.name}`}
                              onChange={(event) => {
                                if (flowVariable.type === "Integer" || flowVariable.type === "Float64") {
                                  handleFlowVariableChange(index, {
                                    default: parseNumericValue(event.target.value, flowVariable.type)
                                  });
                                  return;
                                }
                                handleFlowVariableChange(index, { default: event.target.value });
                              }}
                              step={flowVariable.type === "Float64" ? "any" : undefined}
                              type={
                                flowVariable.type === "Integer" || flowVariable.type === "Float64"
                                  ? "number"
                                  : "text"
                              }
                              value={String(flowVariable.default ?? "")}
                            />
                          </label>
                        )}
                      </article>
                    ))}
                  </div>
                </div>

                <div className="repository-list">
                  {filteredRepositoryNodes.length > 0 ? (
                    filteredRepositoryNodes.map((node) => (
                      <RepositoryEntry
                        key={node.type}
                        node={node}
                        onAdd={handleAddNode}
                        selectedType={selectedNode.type}
                      />
                    ))
                  ) : (
                    <div className="repository-empty">
                      <strong>No repository matches</strong>
                      <span>Try a node type, execution hint, or output target.</span>
                    </div>
                  )}
                </div>
              </aside>

              <section className="canvas-panel">
                <div className="canvas-panel-head">
                  <div>
                    <p className="panel-kicker">Canvas</p>
                    <h3>Typed graph workspace</h3>
                  </div>
                  <div className="canvas-summary" aria-live="polite">
                    <span>{Math.max(1, knownWorkflowIds.length || workspaceData.workflows.length)} snapshot</span>
                    <span>{selectedSliceNodeIds.size} node slice</span>
                    <span className={unresolvedNodeCount > 0 ? "canvas-summary-alert" : ""}>
                      {unresolvedNodeCount} validation gap{unresolvedNodeCount === 1 ? "" : "s"}
                    </span>
                    <span>{latestExecution ? latestExecution.status : "idle"} runtime</span>
                  </div>
                </div>

                <div className="canvas-actions">
                  <div className="canvas-action-buttons">
                    <button
                      className="primary-action-button"
                      disabled={isSaving || isRunningWorkflow}
                      onClick={() => {
                        void persistWorkflow("save");
                      }}
                      type="button"
                    >
                      {isSaving ? "Saving..." : workflowExistsOnGateway ? "Update workflow" : "Save workflow"}
                    </button>
                    <button
                      className="secondary-action-button"
                      disabled={isRunningWorkflow || isSaving}
                      onClick={() => {
                        void handleRunWorkflow();
                      }}
                      type="button"
                    >
                      {isRunningWorkflow ? "Running..." : "Run workflow"}
                    </button>
                  </div>
                  {actionFeedback ? (
                    <div className={`canvas-action-feedback is-${actionFeedback.tone}`} role="status">
                      {actionFeedback.text}
                    </div>
                  ) : null}
                </div>

                <div className="canvas-handoff">
                  <span>BI path</span>
                  <strong>
                    {biOutletNode ? `${selectedNode.name} -> ${biOutletNode.name} dashboard handoff` : "No BI outlet yet"}
                  </strong>
                </div>

                <div className="canvas-scaffold" aria-hidden="true">
                  <span>Sources</span>
                  <span>Transforms</span>
                  <span>Modeling</span>
                  <span>BI output</span>
                </div>

                <div className="canvas-preview" aria-label="Workflow canvas">
                  {workflow.connections.map((connection) => {
                    const edgeDimmed =
                      normalizedNeedle.length > 0 &&
                      !matchedNodeIds.has(connection.sourceNodeId) &&
                      !matchedNodeIds.has(connection.targetNodeId);

                    return (
                      <CanvasConnection
                        connection={connection}
                        isActive={
                          connection.sourceNodeId === selectedNode.id ||
                          connection.targetNodeId === selectedNode.id
                        }
                        isDimmed={edgeDimmed}
                        key={`${connection.sourceNodeId}:${connection.targetNodeId}:${connection.targetPortId}`}
                        layouts={nodeLayouts}
                      />
                    );
                  })}

                  {workflow.nodes.map((node) => (
                    <NodeCard
                      connections={workflow.connections}
                      isDimmed={normalizedNeedle.length > 0 && !matchedNodeIds.has(node.id)}
                      isSelected={node.id === selectedNode.id}
                      key={node.id}
                      layout={nodeLayouts[node.id]}
                      node={node}
                      onSelect={(nodeId) => {
                        startTransition(() => {
                          setSelectedNodeId(nodeId);
                        });
                      }}
                      validation={validationByNodeId[node.id]}
                    />
                  ))}
                </div>
              </section>

              <aside className="inspector-panel">
                <SectionTitle
                  kicker="Inspector"
                  title={selectedNode.name}
                  detail="Configuration, schema, validation, execution target, and recent run state stay together so the panel reads like an actionable node editor."
                />

                <div className="inspector-metrics">
                  <div className="inspector-block">
                    <span>Type</span>
                    <strong>{selectedNode.type}</strong>
                  </div>
                  <div className="inspector-block">
                    <span>Target</span>
                    <strong>{selectedNode.gpuDevicePreference ?? selectedNode.executionHint}</strong>
                  </div>
                </div>

                <section className="inspector-section">
                  <div className="inspector-section-heading">
                    <span>Configuration</span>
                    <strong>{Object.keys(selectedNode.config ?? {}).length}</strong>
                  </div>
                  <div className="inspector-stack">
                    {Object.entries(selectedNode.config ?? {}).map(([key, value]) => (
                      <div className="inspector-row" key={key}>
                        <strong>{key}</strong>
                        <span>{summarizeConfigValue(value)}</span>
                      </div>
                    ))}
                  </div>
                </section>

                <section className="inspector-section">
                  <div className="inspector-section-heading">
                    <span>Schema and sample output</span>
                    <strong>{selectedNode.ports.length}</strong>
                  </div>
                  <div className="inspector-stack">
                    {selectedNode.ports.map((port) => (
                      <PortSchema connections={workflow.connections} key={port.id} node={selectedNode} port={port} />
                    ))}
                    <div className="sample-output">
                      <span>Sample output</span>
                      <strong>{sampleOutput}</strong>
                    </div>
                  </div>
                </section>

                <section className="inspector-section">
                  <div className="inspector-section-heading">
                    <span>Connections</span>
                    <strong>{relatedConnections.length}</strong>
                  </div>
                  <div className="inspector-stack">
                    <div className="connection-editor">
                      <div className="flow-variable-field">
                        <span>Direction</span>
                        <select
                          aria-label="Connection direction"
                          onChange={(event) => {
                            setConnectionDraftDirection(event.target.value as ConnectionDraftDirection);
                          }}
                          value={connectionDraftDirection}
                        >
                          <option value="outgoing">From selected node</option>
                          <option value="incoming">Into selected node</option>
                        </select>
                      </div>

                      <div className="flow-variable-field">
                        <span>{connectionDraftDirection === "outgoing" ? "Target node" : "Source node"}</span>
                        <select
                          aria-label="Connection peer node"
                          onChange={(event) => {
                            setConnectionDraftPeerNodeId(event.target.value);
                          }}
                          value={selectedPeerNode?.id ?? ""}
                        >
                          {peerNodes.length === 0 ? <option value="">No peer nodes</option> : null}
                          {peerNodes.map((node) => (
                            <option key={node.id} value={node.id}>
                              {node.name}
                            </option>
                          ))}
                        </select>
                      </div>

                      <div className="flow-variable-field">
                        <span>{connectionDraftDirection === "outgoing" ? "Source port" : "Target port"}</span>
                        <select
                          aria-label="Connection anchor port"
                          onChange={(event) => {
                            setConnectionDraftAnchorPortId(event.target.value);
                          }}
                          value={connectionDraftAnchorPortId}
                        >
                          {anchorPorts.length === 0 ? <option value="">No compatible ports</option> : null}
                          {anchorPorts.map((port) => (
                            <option key={port.id} value={port.id}>
                              {port.id} · {formatPortType(port.type)}
                            </option>
                          ))}
                        </select>
                      </div>

                      <div className="flow-variable-field">
                        <span>{connectionDraftDirection === "outgoing" ? "Target port" : "Source port"}</span>
                        <select
                          aria-label="Connection peer port"
                          onChange={(event) => {
                            setConnectionDraftPeerPortId(event.target.value);
                          }}
                          value={connectionDraftPeerPortId}
                        >
                          {peerPorts.length === 0 ? <option value="">No compatible ports</option> : null}
                          {peerPorts.map((port) => (
                            <option key={port.id} value={port.id}>
                              {port.id} · {formatPortType(port.type)}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>

                    <div className={`validation-item is-${connectionPreview.tone}`}>
                      <strong>{connectionPreview.label}</strong>
                      <span>{connectionPreview.detail}</span>
                    </div>

                    <div className="connection-editor-actions">
                      <button
                        className="secondary-action-button is-full-width"
                        disabled={connectionPreview.connection === null}
                        onClick={handleAddConnection}
                        type="button"
                      >
                        Add connection
                      </button>
                    </div>

                    <div className="connection-list">
                      {relatedConnections.length === 0 ? (
                        <div className="inspector-row">
                          <strong>No linked edges</strong>
                          <span>Selected node still needs manual wiring.</span>
                        </div>
                      ) : (
                        relatedConnections.map((connection) => (
                          <div className="connection-list-item" key={describeConnection(workflow, connection)}>
                            <div>
                              <strong>{describeConnection(workflow, connection)}</strong>
                              <span>{formatPortType(connection.dataType)}</span>
                            </div>
                            <button
                              aria-label={`Remove ${describeConnection(workflow, connection)}`}
                              className="danger-action-button"
                              onClick={() => {
                                handleRemoveConnection(connection);
                              }}
                              type="button"
                            >
                              Remove
                            </button>
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                </section>

                <section className="inspector-section">
                  <div className="inspector-section-heading">
                    <span>Validation</span>
                    <strong>{validationItems.length}</strong>
                  </div>
                  <div className="validation-list">
                    {validationItems.map((item) => (
                      <div className={`validation-item is-${item.tone}`} key={item.label}>
                        <strong>{item.label}</strong>
                        <span>{item.detail}</span>
                      </div>
                    ))}
                  </div>
                </section>
              </aside>
            </div>
          </div>
        </section>

        <section className="secondary-grid">
          <Panel className="rail-panel">
            <SectionTitle
              kicker="Operations"
              title="Execution and rollback rail"
              detail="Runtime remains nearby, but secondary to authoring. Use it to confirm readiness, monitor runs, and inspect checkpoint evidence."
            />

            <div className="rail-spotlight">
              <div className="rail-spotlight-copy">
                <span>Latest runtime pulse</span>
                <strong>{latestExecution ? latestExecution.id : "No active execution"}</strong>
                <p>
                  {latestExecution
                    ? `${latestExecution.trigger} · ${latestExecution.duration} · ${latestExecution.planner}`
                    : "Execution history will appear here when gateway runs are available."}
                </p>
              </div>
              <StatusBadge label={latestExecution ? latestExecution.status : "idle"} />
            </div>

            <div className="runtime-metrics">
              {statusCounts.map((item) => (
                <div className="runtime-metric" key={item.label}>
                  <span>{item.label}</span>
                  <strong>{item.count}</strong>
                </div>
              ))}
            </div>

            <div className="rail-tabs" role="tablist" aria-label="Execution rail views">
              {executionTabs.map((tab) => (
                <button
                  aria-selected={activeRail === tab}
                  className={`rail-tab ${activeRail === tab ? "is-active" : ""}`}
                  key={tab}
                  onClick={() => {
                    startTransition(() => {
                      setActiveRail(tab);
                    });
                  }}
                  role="tab"
                  type="button"
                >
                  {tab}
                </button>
              ))}
            </div>

            {activeRail === "executions" ? (
              <div className="rail-list" role="tabpanel">
                {executionItems.map((item) => (
                  <article className="rail-card" key={item.id}>
                    <div className="rail-card-top">
                      <strong>{item.id}</strong>
                      <StatusBadge label={item.status} />
                    </div>
                    <p>{item.trigger}</p>
                    <dl className="rail-metadata">
                      <div>
                        <dt>Started</dt>
                        <dd>{item.startedAt}</dd>
                      </div>
                      <div>
                        <dt>Duration</dt>
                        <dd>{item.duration}</dd>
                      </div>
                      <div>
                        <dt>Planner</dt>
                        <dd>{item.planner}</dd>
                      </div>
                    </dl>
                  </article>
                ))}
              </div>
            ) : (
              <div className="rail-list" role="tabpanel">
                {workspaceData.checkpoints.map((item) => (
                  <article className="rail-card" key={item.tag}>
                    <div className="rail-card-top">
                      <strong>{item.tag}</strong>
                      <span className={`checkpoint-state is-${item.state}`}>{item.state}</span>
                    </div>
                    <p>{item.scope}</p>
                    <small>{item.evidence}</small>
                  </article>
                ))}
              </div>
            )}

            <div className="checkpoint-policy">
              <h2>Checkpoint policy</h2>
              <ul className="checkpoint-list">
                {milestoneCheckpoints.slice(0, 4).map((checkpoint) => (
                  <li key={checkpoint.tag}>
                    <strong>{checkpoint.tag}</strong>
                    <span>{checkpoint.goal}</span>
                  </li>
                ))}
              </ul>
            </div>
          </Panel>

          <Panel className="phase-panel">
            <SectionTitle
              kicker="Roadmap"
              title="Program phases"
              detail="Milestones stay visible as support context, not as the dominant screen story."
            />
            <div aria-busy={isPending} className="phase-list">
              {filteredPhases.map((phase) => (
                <article className="phase-card" key={phase.id}>
                  <div className="phase-heading">
                    <h2>{phase.title}</h2>
                    <span>{phase.timeline}</span>
                  </div>
                  <p>{phase.summary}</p>
                  <strong>{phase.exitGate}</strong>
                </article>
              ))}
            </div>
          </Panel>
        </section>
      </main>
    </div>
  );
}

export default App;
