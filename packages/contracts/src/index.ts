export const workflowPortTypes = [
  "data_table",
  "model",
  "flow_variable",
  "image",
  "stream_channel",
  "gpu_buffer"
] as const;

export const workflowStatuses = [
  "idle",
  "configured",
  "running",
  "executed",
  "error",
  "streaming_active"
] as const;

export type WorkflowPortType = (typeof workflowPortTypes)[number];
export type WorkflowStatus = (typeof workflowStatuses)[number];
export type ExecutionHint = "cpu_only" | "gpu_preferred" | "gpu_required";
export const gatewayExecutionStatuses = [
  "accepted",
  "queued",
  "running",
  "completed",
  "failed"
] as const;
export type GatewayExecutionStatus = (typeof gatewayExecutionStatuses)[number];

export interface FlowVariableDefinition {
  name: string;
  type: "String" | "Integer" | "Float64" | "Bool" | "DateTime" | "GPUDeviceID";
  default?: string | number | boolean | null;
}

export type WorkflowRunMode = "batch" | "stream";
export type WorkflowResourceClass = "cpu" | "gpu";
export type NodeExecutionMode = "batch" | "stream" | "hybrid";
export type DashboardChartFamily = "line" | "bar" | "area" | "table" | "metric";
export type StreamingWindowKind = "tumbling" | "sliding";
export type StreamingWatermarkMode = "processing_time" | "event_time";
export type StreamLifecycleStatus = "idle" | "starting" | "active" | "paused" | "stopped";

export interface WorkflowNodeLayout {
  nodeId: string;
  x: number;
  y: number;
  width?: number;
  checkpointTag?: string;
  notes?: string;
}

export interface WorkflowViewportState {
  x: number;
  y: number;
  zoom: number;
}

export interface WorkflowGraphDefinition {
  revision: number;
  nodeLayouts: WorkflowNodeLayout[];
  viewport?: WorkflowViewportState;
  selectedNodeId?: string;
}

export interface NodeCapabilityDescriptor {
  executionMode: NodeExecutionMode;
  resourceClass: WorkflowResourceClass;
  accelerator?: "cuda";
  workerPool?: string;
}

export interface DashboardBindingDefinition {
  outletNodeId: string;
  datasetKey: string;
  refreshMode: "manual" | "live";
}

export interface DashboardChartDefinition {
  chartId: string;
  title: string;
  family: DashboardChartFamily;
  xField?: string;
  yField?: string;
  seriesField?: string;
}

export interface DashboardDefinition {
  dashboardId: string;
  name: string;
  binding: DashboardBindingDefinition;
  charts: DashboardChartDefinition[];
}

export interface StreamingSourceDefinition {
  kind: "kafka";
  topic: string;
  consumerGroup: string;
  bootstrapServers: string[];
}

export interface StreamingWindowDefinition {
  kind: StreamingWindowKind;
  sizeSeconds: number;
  slideSeconds?: number;
}

export interface StreamingPolicyDefinition {
  watermarkMode: StreamingWatermarkMode;
  allowedLatenessSeconds: number;
  maxInFlightBatches: number;
}

export interface WorkflowRuntimeDefinition {
  runMode: WorkflowRunMode;
  source?: StreamingSourceDefinition;
  window?: StreamingWindowDefinition;
  policy?: StreamingPolicyDefinition;
}

export interface NodeDefinition {
  id: string;
  type: string;
  name: string;
  executionHint: ExecutionHint;
  capabilities?: NodeCapabilityDescriptor;
  ports: Array<{
    id: string;
    direction: "input" | "output";
    type: WorkflowPortType;
    label?: string;
  }>;
  config: Record<string, unknown>;
  gpuDevicePreference?: string;
}

export interface ConnectionDefinition {
  sourceNodeId: string;
  sourcePortId: string;
  targetNodeId: string;
  targetPortId: string;
  dataType: WorkflowPortType;
  label?: string;
}

export interface WorkflowDefinition {
  version: string;
  workflowId: string;
  name: string;
  nodes: NodeDefinition[];
  connections: ConnectionDefinition[];
  flowVariables: FlowVariableDefinition[];
  graph?: WorkflowGraphDefinition;
  dashboards?: DashboardDefinition[];
  runtime?: WorkflowRuntimeDefinition;
}

export const jsonRpcMethods = [
  "canvas.subscribe",
  "workflow.execute",
  "workflow.pause",
  "workflow.resume",
  "workflow.stop",
  "dashboard.subscribe"
] as const;

export const milestoneCheckpoints = [
  { tag: "cp/00-foundation", goal: "Monorepo, contracts, CI, CPU prototype" },
  { tag: "cp/01-contracts-frozen", goal: "Workflow schema, OpenAPI, JSON-RPC, SDK frozen" },
  { tag: "cp/02-alpha-core", goal: "Canvas, persistence, 150 core nodes" },
  { tag: "cp/03-alpha-gpu-bi", goal: "Single GPU lane and BI v0" },
  { tag: "cp/04-beta-streaming", goal: "Streaming runtime, windows, checkpoints" },
  { tag: "cp/05-beta-security-hub", goal: "RBAC, sandboxing, Hub public beta" },
  { tag: "cp/06-ga-platform", goal: "GA platform hardening and scale testing" },
  { tag: "cp/07-ga-enterprise", goal: "Enterprise deployment and audit readiness" },
  { tag: "cp/08-scale", goal: "Scale roadmap, ecosystem, advanced features" }
] as const;
export type MilestoneCheckpointTag = (typeof milestoneCheckpoints)[number]["tag"];

export const phaseSummaries = [
  {
    id: "phase-0",
    title: "Phase 0: Foundation",
    timeline: "Months 1-3",
    summary: "Bootstrap repo, contracts, CI/CD, Arrow IPC, CPU-only JES prototype, React canvas shell, tests, and observability baseline.",
    exitGate: "Internal PoC demo: 20-node batch ML pipeline on CPU"
  },
  {
    id: "phase-1",
    title: "Phase 1: Alpha",
    timeline: "Months 4-6",
    summary: "Ship draggable node canvas, typed ports, persistence, 150 core nodes, CUDA support, BI Dashboard v0, streaming MVP, and Hub v0.",
    exitGate: "Alpha release to 50 design partners"
  },
  {
    id: "phase-2",
    title: "Phase 2: Beta",
    timeline: "Months 7-12",
    summary: "Add components, flow variables, loop/control nodes, checkpoint recovery, BI semantic layer, live updates, RBAC, sandboxing, and public SDK.",
    exitGate: "Public beta launch with role-aware dashboards"
  },
  {
    id: "phase-3",
    title: "Phase 3: GA",
    timeline: "Months 13-18",
    summary: "Expand node library, multi-GPU scheduling, enterprise deployment paths, KNIME import, audit logs, and SOC 2 readiness work.",
    exitGate: "GA plus enterprise-ready deployment"
  },
  {
    id: "phase-4",
    title: "Phase 4: Scale",
    timeline: "Months 19-24",
    summary: "Add LLM nodes, AutoML, advanced geospatial, federated execution, compatibility bridges, and commercial hardening.",
    exitGate: "Scale targets and ecosystem maturity"
  }
] as const;

export interface GatewayHealthcheck {
  service: "api-gateway";
  status: "ok";
  repositoryBackend: string;
  storeRoot: string;
  workflowCount: number;
  checkpointCount: number;
  executionCount: number;
}

export interface GatewayWorkflowSummary {
  workflowId: string;
  name: string;
  version: string;
  nodeCount: number;
  latestCheckpoint: string;
  graphRevision?: number;
  dashboardCount?: number;
  runMode?: WorkflowRunMode;
}

export interface GatewayWorkflowMetadata {
  workflowId: string;
  name: string;
  version: string;
  nodeCount: number;
  connectionCount: number;
  flowVariableCount: number;
  biOutletCount: number;
  nodes: NodeDefinition[];
  connections: ConnectionDefinition[];
  flowVariables: FlowVariableDefinition[];
  biOutlets: Array<Record<string, unknown>>;
  graph?: WorkflowGraphDefinition;
  dashboards?: DashboardDefinition[];
  runtime?: WorkflowRuntimeDefinition;
}

export interface GatewayCheckpointRecord {
  tag: string;
  summary: string;
  createdAt: string;
}

export interface GatewayCheckpointCreateResponse {
  checkpoint: GatewayCheckpointRecord;
  checkpointCount: number;
}

export type HubExtensionPublisher = "official" | "partner";
export type HubInstallState = "available" | "installed" | "enabled";
export type HubInstallAction = "install" | "enable";

export interface HubExtensionManifest {
  extensionId: string;
  name: string;
  version: string;
  publisher: HubExtensionPublisher;
  summary: string;
  packageRef: string;
  tags: string[];
  compatibleCheckpoints: string[];
}

export interface GatewayHubExtensionRecord {
  extensionId: string;
  manifest: HubExtensionManifest;
  installState: HubInstallState;
  installedAt?: string;
  enabledAt?: string;
}

export interface GatewayHubInstallRequest {
  action: HubInstallAction;
}

export interface GatewayHubInstallResponse {
  extension: GatewayHubExtensionRecord;
  status: "ok";
}

export interface GatewayExecutionStatusEvent {
  status: GatewayExecutionStatus;
  at: string;
  message?: string;
  metadata?: Record<string, unknown>;
}

export interface GatewayExecutionRecord {
  executionId: string;
  workflowId: string;
  workflowVersion: string;
  checkpointTag: string;
  status: GatewayExecutionStatus;
  mode: string;
  plan: string[];
  stages: string[][];
  nodeCount: number;
  connectionCount: number;
  createdAt: string;
  updatedAt: string;
  statusHistory: GatewayExecutionStatusEvent[];
  queuedAt?: string;
  startedAt?: string;
  finishedAt?: string;
  resourcePlan?: Array<{
    lane: WorkflowResourceClass;
    nodeIds: string[];
  }>;
  dispatchPlan?: Array<{
    lane: WorkflowResourceClass;
    nodeIds: string[];
    workerPool: string;
    isolationMode: "shared" | "isolated";
    accelerator?: "cuda";
  }>;
  dispatchLane?: WorkflowResourceClass;
  dispatchWorkerPool?: string;
  dispatchIsolationMode?: "shared" | "isolated";
  dispatchAccelerator?: "cuda";
  workerId?: string;
  streamLifecycleStatus?: StreamLifecycleStatus;
}

export interface GatewayListResponse<TItem> {
  items: TItem[];
}

export interface CreateWorkflowRequest {
  workflowToml?: string;
  workflow?: WorkflowDefinition;
}

export interface ImportWorkflowRequest {
  sourcePath: string;
}

export interface CreateWorkflowResponse {
  workflowId: string;
  name: string;
  version: string;
  status: "created";
}

export interface UpdateWorkflowResponse {
  workflowId: string;
  name: string;
  version: string;
  status: "updated";
}

export interface ImportWorkflowResponse {
  workflowId: string;
  name: string;
  persistedPath: string;
}

export interface CreateCheckpointRequest {
  tag: string;
  summary: string;
}

export interface TransitionExecutionStatusRequest {
  status: GatewayExecutionStatus;
  message?: string;
  metadata?: Record<string, unknown>;
}

export interface GatewayErrorPayload {
  error: string;
}

export const gatewayEndpointPaths = {
  health: "/health",
  workflows: "/api/v1/workflows",
  importWorkflow: "/api/v1/workflows/import",
  workflowDetail: (workflowId: string) => `/api/v1/workflows/${encodeURIComponent(workflowId)}`,
  workflowExecute: (workflowId: string) =>
    `/api/v1/workflows/${encodeURIComponent(workflowId)}/execute`,
  executions: "/api/v1/executions",
  executionDetail: (executionId: string) => `/api/v1/executions/${encodeURIComponent(executionId)}`,
  executionStatus: (executionId: string) =>
    `/api/v1/executions/${encodeURIComponent(executionId)}/status`,
  checkpoints: "/api/v1/checkpoints",
  hubExtensions: "/api/v1/hub/extensions",
  hubExtensionInstall: (extensionId: string) =>
    `/api/v1/hub/extensions/${encodeURIComponent(extensionId)}/install`
} as const;

export type GatewayStaticEndpointPath = Extract<
  (typeof gatewayEndpointPaths)[keyof typeof gatewayEndpointPaths],
  string
>;

export interface GatewayRequestOptions {
  headers?: HeadersInit;
  signal?: AbortSignal;
}

export interface GatewayClientOptions {
  baseUrl: string;
  fetch?: typeof fetch;
  headers?: HeadersInit;
}

export interface GatewayRealtimeClientOptions {
  baseUrl: string;
  WebSocket?: typeof WebSocket;
}

export interface GatewayRealtimeRequest {
  jsonrpc: "2.0";
  id: number;
  method: (typeof jsonRpcMethods)[number];
  params: Record<string, unknown>;
}

export interface GatewayRealtimeSuccessResponse<TResult> {
  jsonrpc: "2.0";
  id: number;
  result: TResult;
}

export interface GatewayRealtimeErrorResponse {
  jsonrpc: "2.0";
  id: number | null;
  error: {
    code: number;
    message: string;
  };
}

export interface GatewayWorkflowStateChangedEvent {
  subscriptionId: string;
  workflowId: string;
  name: string;
  version: string;
  nodeCount: number;
  connectionCount: number;
  latestCheckpoint: string;
  executionCount: number;
  graphRevision?: number;
  dashboardCount?: number;
  runMode?: WorkflowRunMode;
}

export interface GatewayNodeStateChangedEvent {
  subscriptionId: string;
  workflowId: string;
  nodeId: string;
  nodeType: string;
  status: WorkflowStatus;
  executionHint: ExecutionHint;
}

export interface GatewayDashboardOutletUpdatedEvent {
  subscriptionId: string;
  dashboardId: string;
  outletIds: string[];
  latestCheckpoint: string;
  updatedAt: string;
}

export interface GatewayStreamingCheckpointCompletedEvent {
  subscriptionId?: string;
  workflowId: string;
  checkpointId: string;
  offsets: Record<string, unknown>;
  stateVersion: number;
}

export interface GatewayExecutionStateChangedEvent extends GatewayExecutionRecord {
  subscriptionId?: string;
}

export interface GatewayRepositorySaveChangedEvent {
  subscriptionId?: string;
  workflowId: string;
  workflowVersion: string;
  graphRevision?: number;
  savedAt: string;
}

export interface GatewayRealtimeNotificationMap {
  "workflow.state.changed": GatewayWorkflowStateChangedEvent;
  "node.state.changed": GatewayNodeStateChangedEvent;
  "dashboard.outlet.updated": GatewayDashboardOutletUpdatedEvent;
  "streaming.checkpoint.completed": GatewayStreamingCheckpointCompletedEvent;
  "execution.state.changed": GatewayExecutionStateChangedEvent;
  "repository.save.changed": GatewayRepositorySaveChangedEvent;
}

export type GatewayRealtimeNotificationMethod = keyof GatewayRealtimeNotificationMap;

export type GatewayRealtimeNotification =
  {
    [TMethod in GatewayRealtimeNotificationMethod]: {
      jsonrpc: "2.0";
      method: TMethod;
      params: GatewayRealtimeNotificationMap[TMethod];
    };
  }[GatewayRealtimeNotificationMethod];

export interface GatewayRealtimeClient {
  socket: WebSocket;
  close(code?: number, reason?: string): void;
  request<TResult>(
    method: (typeof jsonRpcMethods)[number],
    params: Record<string, unknown>
  ): Promise<TResult>;
}

export interface GatewayApiClient {
  healthcheck(options?: GatewayRequestOptions): Promise<GatewayHealthcheck>;
  listWorkflows(options?: GatewayRequestOptions): Promise<GatewayListResponse<GatewayWorkflowSummary>>;
  createWorkflow(
    request: CreateWorkflowRequest,
    options?: GatewayRequestOptions
  ): Promise<CreateWorkflowResponse>;
  importWorkflow(
    request: ImportWorkflowRequest,
    options?: GatewayRequestOptions
  ): Promise<ImportWorkflowResponse>;
  getWorkflow(
    workflowId: string,
    options?: GatewayRequestOptions
  ): Promise<GatewayWorkflowMetadata>;
  updateWorkflow(
    workflowId: string,
    request: CreateWorkflowRequest,
    options?: GatewayRequestOptions
  ): Promise<UpdateWorkflowResponse>;
  executeWorkflow(
    workflowId: string,
    options?: GatewayRequestOptions
  ): Promise<GatewayExecutionRecord>;
  listExecutions(options?: GatewayRequestOptions): Promise<GatewayListResponse<GatewayExecutionRecord>>;
  getExecution(
    executionId: string,
    options?: GatewayRequestOptions
  ): Promise<GatewayExecutionRecord>;
  transitionExecutionStatus(
    executionId: string,
    request: TransitionExecutionStatusRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayExecutionRecord>;
  listCheckpoints(options?: GatewayRequestOptions): Promise<GatewayListResponse<GatewayCheckpointRecord>>;
  createCheckpoint(
    request: CreateCheckpointRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayCheckpointCreateResponse>;
  listHubExtensions(
    options?: GatewayRequestOptions
  ): Promise<GatewayListResponse<GatewayHubExtensionRecord>>;
  installHubExtension(
    extensionId: string,
    request: GatewayHubInstallRequest,
    options?: GatewayRequestOptions
  ): Promise<GatewayHubInstallResponse>;
}

export class GatewayClientError extends Error {
  readonly status: number;
  readonly payload: unknown;

  constructor(message: string, status: number, payload: unknown) {
    super(message);
    this.name = "GatewayClientError";
    this.status = status;
    this.payload = payload;
  }
}

function trimTrailingSlash(baseUrl: string): string {
  return baseUrl.endsWith("/") ? baseUrl.slice(0, -1) : baseUrl;
}

function buildUrl(baseUrl: string, path: string): string {
  return `${trimTrailingSlash(baseUrl)}${path}`;
}

function buildRealtimeUrl(baseUrl: string): string {
  const httpUrl = new URL(buildUrl(baseUrl, "/api/v1/realtime"));
  httpUrl.protocol = httpUrl.protocol === "https:" ? "wss:" : "ws:";
  return httpUrl.toString();
}

async function parseGatewayResponse(response: Response): Promise<unknown> {
  const body = await response.text();
  if (body.length === 0) {
    return null;
  }

  try {
    return JSON.parse(body) as unknown;
  } catch {
    return body;
  }
}

function mergeHeaders(baseHeaders?: HeadersInit, requestHeaders?: HeadersInit): Headers {
  const headers = new Headers(baseHeaders);
  if (requestHeaders) {
    new Headers(requestHeaders).forEach((value, key) => {
      headers.set(key, value);
    });
  }
  return headers;
}

export function createGatewayApiClient(options: GatewayClientOptions): GatewayApiClient {
  const gatewayFetch = options.fetch ?? globalThis.fetch;
  if (!gatewayFetch) {
    throw new Error("fetch implementation required to create Gateway API client");
  }

  async function request<TResponse>(
    method: string,
    path: string,
    body?: unknown,
    requestOptions?: GatewayRequestOptions
  ): Promise<TResponse> {
    const headers = mergeHeaders(options.headers, requestOptions?.headers);
    headers.set("Accept", "application/json");

    let payload: string | undefined;
    if (body !== undefined) {
      headers.set("Content-Type", "application/json");
      payload = JSON.stringify(body);
    }

    const response = await gatewayFetch(buildUrl(options.baseUrl, path), {
      method,
      headers,
      body: payload,
      signal: requestOptions?.signal
    });
    const parsed = await parseGatewayResponse(response);

    if (!response.ok) {
      const message =
        typeof parsed === "object" &&
        parsed !== null &&
        "error" in parsed &&
        typeof (parsed as Record<string, unknown>).error === "string"
          ? String((parsed as Record<string, unknown>).error)
          : `Gateway request failed with status ${response.status}`;
      throw new GatewayClientError(message, response.status, parsed);
    }

    return parsed as TResponse;
  }

  return {
    healthcheck: (requestOptions) =>
      request<GatewayHealthcheck>("GET", gatewayEndpointPaths.health, undefined, requestOptions),
    listWorkflows: (requestOptions) =>
      request<GatewayListResponse<GatewayWorkflowSummary>>(
        "GET",
        gatewayEndpointPaths.workflows,
        undefined,
        requestOptions
      ),
    createWorkflow: (workflow, requestOptions) =>
      request<CreateWorkflowResponse>(
        "POST",
        gatewayEndpointPaths.workflows,
        workflow,
        requestOptions
      ),
    importWorkflow: (workflowImport, requestOptions) =>
      request<ImportWorkflowResponse>(
        "POST",
        gatewayEndpointPaths.importWorkflow,
        workflowImport,
        requestOptions
      ),
    getWorkflow: (workflowId, requestOptions) =>
      request<GatewayWorkflowMetadata>(
        "GET",
        gatewayEndpointPaths.workflowDetail(workflowId),
        undefined,
        requestOptions
      ),
    updateWorkflow: (workflowId, workflow, requestOptions) =>
      request<UpdateWorkflowResponse>(
        "PUT",
        gatewayEndpointPaths.workflowDetail(workflowId),
        workflow,
        requestOptions
      ),
    executeWorkflow: (workflowId, requestOptions) =>
      request<GatewayExecutionRecord>(
        "POST",
        gatewayEndpointPaths.workflowExecute(workflowId),
        undefined,
        requestOptions
      ),
    listExecutions: (requestOptions) =>
      request<GatewayListResponse<GatewayExecutionRecord>>(
        "GET",
        gatewayEndpointPaths.executions,
        undefined,
        requestOptions
      ),
    getExecution: (executionId, requestOptions) =>
      request<GatewayExecutionRecord>(
        "GET",
        gatewayEndpointPaths.executionDetail(executionId),
        undefined,
        requestOptions
      ),
    transitionExecutionStatus: (executionId, transition, requestOptions) =>
      request<GatewayExecutionRecord>(
        "POST",
        gatewayEndpointPaths.executionStatus(executionId),
        transition,
        requestOptions
      ),
    listCheckpoints: (requestOptions) =>
      request<GatewayListResponse<GatewayCheckpointRecord>>(
        "GET",
        gatewayEndpointPaths.checkpoints,
        undefined,
        requestOptions
      ),
    createCheckpoint: (checkpoint, requestOptions) =>
      request<GatewayCheckpointCreateResponse>(
        "POST",
        gatewayEndpointPaths.checkpoints,
        checkpoint,
        requestOptions
      ),
    listHubExtensions: (requestOptions) =>
      request<GatewayListResponse<GatewayHubExtensionRecord>>(
        "GET",
        gatewayEndpointPaths.hubExtensions,
        undefined,
        requestOptions
      ),
    installHubExtension: (extensionId, installRequest, requestOptions) =>
      request<GatewayHubInstallResponse>(
        "POST",
        gatewayEndpointPaths.hubExtensionInstall(extensionId),
        installRequest,
        requestOptions
      )
  };
}

export const createGatewayClient = createGatewayApiClient;

export function createGatewayRealtimeClient(
  options: GatewayRealtimeClientOptions
): GatewayRealtimeClient {
  const RealtimeSocket = options.WebSocket ?? globalThis.WebSocket;
  if (!RealtimeSocket) {
    throw new Error("WebSocket implementation required to create Gateway realtime client");
  }

  const socket = new RealtimeSocket(buildRealtimeUrl(options.baseUrl));
  let nextRequestId = 1;
  const pendingRequests = new Map<
    number,
    {
      reject: (error: unknown) => void;
      resolve: (value: unknown) => void;
    }
  >();

  socket.addEventListener("message", (event) => {
    const rawData = typeof event.data === "string" ? event.data : String(event.data);
    const payload = JSON.parse(rawData) as
      | GatewayRealtimeSuccessResponse<unknown>
      | GatewayRealtimeErrorResponse
      | GatewayRealtimeNotification;

    if ("id" in payload) {
      const pendingRequest = pendingRequests.get(payload.id ?? -1);
      if (!pendingRequest) {
        return;
      }

      pendingRequests.delete(payload.id ?? -1);
      if ("error" in payload) {
        pendingRequest.reject(
          new GatewayClientError(payload.error.message, payload.error.code, payload.error)
        );
        return;
      }

      pendingRequest.resolve(payload.result);
    }
  });

  socket.addEventListener("close", () => {
    for (const [requestId, pendingRequest] of pendingRequests) {
      pendingRequests.delete(requestId);
      pendingRequest.reject(new Error("Gateway realtime connection closed"));
    }
  });

  return {
    socket,
    close: (code, reason) => {
      socket.close(code, reason);
    },
    request: <TResult>(method: (typeof jsonRpcMethods)[number], params: Record<string, unknown>) => {
      const requestId = nextRequestId;
      nextRequestId += 1;

      return new Promise<TResult>((resolve, reject) => {
        pendingRequests.set(requestId, {
          reject,
          resolve: (value) => {
            resolve(value as TResult);
          }
        });
        socket.send(
          JSON.stringify({
            jsonrpc: "2.0",
            id: requestId,
            method,
            params
          } satisfies GatewayRealtimeRequest)
        );
      });
    }
  };
}
