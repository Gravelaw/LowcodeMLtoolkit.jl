import { useDeferredValue, useEffect, useRef, useState, useTransition } from "react";
import {
  createGatewayClient,
  createGatewayRealtimeClient,
  milestoneCheckpoints,
  phaseSummaries,
  workflowStatuses,
  type ConnectionDefinition,
  type DashboardChartDefinition,
  type DashboardChartFamily,
  type DashboardDefinition,
  type DashboardDatasetRow,
  type ExecutionHint,
  type GatewayDashboardChartDataResponse,
  type GatewayDashboardPublishResponse,
  type GatewayDashboardPublishRequest,
  type GatewayAuditActionEvent,
  type GatewayAuthDirectory,
  type GatewayAuthPolicy,
  type GatewayExecutionStateChangedEvent,
  type GatewayHealthcheck,
  type GatewayHubExtensionRecord,
  type GatewayHubInstallRequest,
  type GatewayHubRegisterRequest,
  type HubExtensionManifest,
  type GatewayNodeStateChangedEvent,
  type GatewayRealtimeNotification,
  type GatewayWorkflowMetadata,
  type GatewayWorkflowStateChangedEvent,
  type GatewayWorkflowSummary,
  type NodeDefinition,
  type PublishedDashboardDefinition,
  type ResourcePermission,
  type WorkspaceRole,
  type WorkflowDefinition,
  type WorkflowStatus
} from "@juliaflow/contracts";
import { Panel, SectionTitle, StatusBadge } from "@juliaflow/ui";
import {
  buildCanvasNodeLayouts,
  buildCheckpointRailItems,
  buildExecutionRailItems,
  buildWorkflowFromGateway,
  checkpointRailItems,
  executionRailItems,
  sampleWorkflow,
  starterNodeCatalog,
  type CanvasNodeLayout,
  type CheckpointRailItem,
  type ExecutionRailItem
} from "./sample-workflow";

const executionTabs = ["executions", "checkpoints"] as const;

type ExecutionTab = (typeof executionTabs)[number];
type DataSourceMode = "demo" | "live" | "fallback";
type ConnectionDraftDirection = "incoming" | "outgoing";
type RealtimeConnectionState = "idle" | "connecting" | "live" | "error";
type AppView = "canvas" | "dashboard" | "hub" | "monitor" | "settings";
type InspectorTab = "config" | "ports" | "validation" | "runtime";
type WorkflowPortDefinition = NodeDefinition["ports"][number];
type ValidationTone = "good" | "warn" | "live";
type ActionTone = "info" | "success" | "error" | "demo";

const workspaceRoleOptions: WorkspaceRole[] = ["owner", "editor", "viewer"];
const resourcePermissionOptions: ResourcePermission[] = [
  "workflow:read",
  "workflow:write",
  "workflow:execute",
  "execution:read",
  "execution:write",
  "checkpoint:read",
  "checkpoint:write",
  "dashboard:read",
  "dashboard:publish",
  "hub:read",
  "hub:publish",
  "hub:install",
  "policy:read",
  "policy:write",
  "audit:read"
];

interface RoleBindingDraft {
  principalId: string;
  workspaceId: string;
  role: WorkspaceRole;
}

interface ResourcePolicyDraft {
  resourceType: string;
  resourceId: string;
  workspaceId: string;
  ownerPermissions: string;
  editorPermissions: string;
  viewerPermissions: string;
}

interface AuthUserDraft {
  principalId: string;
  displayName: string;
  email: string;
  active: boolean;
}

interface AuthWorkspaceDraft {
  workspaceId: string;
  name: string;
  active: boolean;
}

interface ViewerChartFilter {
  field: string;
  value: string;
}

interface ViewerChartDrilldown {
  chartId: string;
  chartTitle: string;
  filter: ViewerChartFilter | null;
  matchingRowCount: number;
  row: DashboardDatasetRow;
  rowIndex: number;
}

const dashboardChartFamilies: DashboardChartFamily[] = ["line", "bar", "area", "table", "metric"];

interface WorkspaceDataState {
  checkpoints: CheckpointRailItem[];
  dataSourceLabel: string;
  error: string | null;
  executionItems: ExecutionRailItem[];
  health: GatewayHealthcheck | null;
  hubExtensions: GatewayHubExtensionRecord[];
  authPolicy: GatewayAuthPolicy | null;
  authDirectory: GatewayAuthDirectory | null;
  auditActions: GatewayAuditActionEvent[];
  authAdminError: string | null;
  isLoading: boolean;
  mode: DataSourceMode;
  workflow: WorkflowDefinition;
  workflows: GatewayWorkflowSummary[];
}

interface ActionFeedback {
  text: string;
  tone: ActionTone;
}

interface JuliaFlowRuntimeConfig {
  gatewayBaseUrl?: string;
}

declare global {
  interface Window {
    __JULIAFLOW_CONFIG__?: JuliaFlowRuntimeConfig;
  }
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

interface DragState {
  nodeId: string;
  originX: number;
  originY: number;
  pointerStartX: number;
  pointerStartY: number;
}

interface ConnectionDraftPreview {
  connection: ConnectionDefinition | null;
  detail: string;
  label: string;
  tone: ValidationTone;
}

function getGatewayBaseUrl(): string {
  const runtimeUrl = typeof window === "undefined" ? "" : String(window.__JULIAFLOW_CONFIG__?.gatewayBaseUrl ?? "").trim();
  if (runtimeUrl.length > 0) {
    return runtimeUrl;
  }
  return String(import.meta.env.VITE_JULIAFLOW_GATEWAY_BASE_URL ?? "").trim();
}

function getInitialViewerDashboardId(): string | null {
  if (typeof window === "undefined") {
    return null;
  }
  const params = new URLSearchParams(window.location.search);
  const dashboardId = params.get("dashboard");
  return dashboardId && dashboardId.length > 0 ? dashboardId : null;
}

function getInitialViewerShareToken(): string | null {
  if (typeof window === "undefined") {
    return null;
  }
  const params = new URLSearchParams(window.location.search);
  const shareToken = params.get("share");
  return shareToken && shareToken.length > 0 ? shareToken : null;
}

function getInitialViewerWorkspaceToken(): string | null {
  if (typeof window === "undefined") {
    return null;
  }
  const params = new URLSearchParams(window.location.search);
  const workspaceToken = params.get("workspaceToken");
  return workspaceToken && workspaceToken.length > 0 ? workspaceToken : null;
}

function getConfiguredWorkspaceDashboardToken(): string | null {
  const token = String(import.meta.env.VITE_JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN ?? "").trim();
  return token.length > 0 ? token : null;
}

function getConfiguredWorkspaceDashboardBearerToken(): string | null {
  const token = String(import.meta.env.VITE_JULIAFLOW_WORKSPACE_BEARER_TOKEN ?? "").trim();
  return token.length > 0 ? token : null;
}

function getInitialPathname(): string {
  if (typeof window === "undefined") {
    return "/";
  }
  return window.location.pathname || "/";
}

function getAppViewFromPath(pathname: string): AppView {
  if (pathname.startsWith("/dashboard")) {
    return "dashboard";
  }
  if (pathname.startsWith("/hub")) {
    return "hub";
  }
  if (pathname.startsWith("/monitor")) {
    return "monitor";
  }
  if (pathname.startsWith("/settings")) {
    return "settings";
  }
  return "canvas";
}

function buildViewPath(view: AppView): string {
  switch (view) {
    case "dashboard":
      return "/dashboard";
    case "hub":
      return "/hub";
    case "monitor":
      return "/monitor";
    case "settings":
      return "/settings";
    default:
      return "/";
  }
}

function buildDashboardViewerSearch(
  dashboardId: string,
  shareToken?: string | null,
  workspaceToken?: string | null
): string {
  const params = new URLSearchParams();
  params.set("dashboard", dashboardId);
  if (shareToken) {
    params.set("share", shareToken);
  }
  if (workspaceToken) {
    params.set("workspaceToken", workspaceToken);
  }
  return `?${params.toString()}`;
}


const demoAuthPolicy: GatewayAuthPolicy = {
  roleBindings: [
    { principalId: "dev:local-user", workspaceId: "local-dev", role: "owner" }
  ],
  resourcePolicies: [
    {
      resourceType: "workflow",
      resourceId: "*",
      workspaceId: "local-dev",
      permissionsByRole: {
        owner: ["workflow:read", "workflow:write", "workflow:execute", "audit:read", "policy:read", "policy:write"],
        editor: ["workflow:read", "workflow:write", "workflow:execute"],
        viewer: ["workflow:read"]
      }
    }
  ],
  updatedAt: "2026-05-04T00:00:00Z"
};

const demoAuthDirectory: GatewayAuthDirectory = {
  users: [
    {
      principalId: "dev:local-user",
      displayName: "Local developer",
      email: "dev@juliaflow.local",
      active: true,
      createdAt: "2026-05-05T00:00:00Z",
      updatedAt: "2026-05-05T00:00:00Z"
    }
  ],
  workspaces: [
    {
      workspaceId: "local-dev",
      name: "Local development",
      active: true,
      createdAt: "2026-05-05T00:00:00Z",
      updatedAt: "2026-05-05T00:00:00Z"
    }
  ],
  updatedAt: "2026-05-05T00:00:00Z"
};

const demoAuditActions: GatewayAuditActionEvent[] = [
  {
    action: "auth.policy.update",
    targetType: "auth_policy",
    targetId: "default",
    recordedAt: "2026-05-04T00:00:00Z",
    authContext: {
      principalId: "dev:local-user",
      workspaceId: "local-dev",
      role: "owner",
      mode: "dev_fallback",
      permissions: ["audit:read", "policy:read", "policy:write"]
    },
    details: {}
  }
];

function createHubVerification(
  verified: boolean,
  evaluatedAt: string,
  blockers: string[] = []
): GatewayHubExtensionRecord["verification"] {
  const status = verified ? "passed" : blockers.length > 0 ? "failed" : "pending";
  const details = verified ? "Verification proof recorded" : "Verification proof pending";

  return {
    verified,
    sandbox: { status, details, blockers, checkedAt: evaluatedAt },
    artifacts: { status, details, blockers, checkedAt: evaluatedAt },
    mirrors: { status, details, blockers, checkedAt: evaluatedAt },
    blockers,
    evaluatedAt
  };
}

const demoHubExtensions: GatewayHubExtensionRecord[] = [
  {
    extensionId: "juliaflow-base",
    manifest: {
      extensionId: "juliaflow-base",
      name: "JuliaFlow Base",
      version: "0.1.0",
      publisher: "official",
      summary: "Official starter node pack with source, transform, trainer, BI, and sink nodes.",
      packageRef: "extensions/base",
      tags: ["official", "starter", "alpha"],
      engineCompatibility: "alpha-core",
      requiredContractVersion: "0.1.0",
      supportedCheckpoints: ["cp/02-alpha-core", "cp/03-alpha-gpu-bi"],
      compatibleCheckpoints: ["cp/02-alpha-core", "cp/03-alpha-gpu-bi"],
      dependencies: [],
      publisherIdentity: "official:juliaflow",
      artifactHashes: { package: "sha256:ef5563c1d3bb2319a9323daebe3e4907fce4c877835371b310dc31d50e521000" },
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
    verification: createHubVerification(true, "2026-04-20T00:00:00Z"),
    installedAt: "2026-04-20T00:00:00Z",
    enabledAt: "2026-04-20T00:00:00Z"
  },
  {
    extensionId: "juliaflow-ops-preview",
    manifest: {
      extensionId: "juliaflow-ops-preview",
      name: "Ops Preview Pack",
      version: "0.2.0",
      publisher: "partner",
      summary: "Preview catalog entry for Hub v0 install and enable flows.",
      packageRef: "hub://preview/ops-pack",
      tags: ["preview", "ops", "hub-v0"],
      engineCompatibility: "alpha-core",
      requiredContractVersion: "0.1.0",
      supportedCheckpoints: ["cp/03-alpha-gpu-bi"],
      compatibleCheckpoints: ["cp/03-alpha-gpu-bi"],
      dependencies: [],
      publisherIdentity: "partner:ops-preview",
      artifactHashes: { package: "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" },
      compatibilitySandboxCommand: "julia --project=. extensions/ops-preview/test/runtests.jl",
      mirrorRefs: ["mirror://offline/ops-preview"]
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
      warnings: ["Signature missing for partner extension"],
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
    verification: createHubVerification(false, "2026-04-20T00:00:00Z", [
      "Extension not validated for current checkpoint cp/02-alpha-core"
    ]),
    installedAt: "2026-04-20T00:00:00Z"
  }
];

function createEmptyRoleBindingDraft(): RoleBindingDraft {
  return {
    principalId: "",
    workspaceId: "",
    role: "viewer"
  };
}

function createEmptyResourcePolicyDraft(): ResourcePolicyDraft {
  return {
    resourceType: "workflow",
    resourceId: "",
    workspaceId: "",
    ownerPermissions: "workflow:read, workflow:write, workflow:execute, policy:read, policy:write, audit:read",
    editorPermissions: "workflow:read, workflow:write, workflow:execute",
    viewerPermissions: "workflow:read"
  };
}

function createEmptyAuthUserDraft(): AuthUserDraft {
  return {
    principalId: "",
    displayName: "",
    email: "",
    active: true
  };
}

function createEmptyAuthWorkspaceDraft(): AuthWorkspaceDraft {
  return {
    workspaceId: "",
    name: "",
    active: true
  };
}

function parsePermissionDraft(rawValue: string): ResourcePermission[] | null {
  const requestedPermissions = rawValue
    .split(",")
    .map((permission) => permission.trim())
    .filter((permission) => permission.length > 0);

  for (const permission of requestedPermissions) {
    if (!resourcePermissionOptions.includes(permission as ResourcePermission)) {
      return null;
    }
  }

  return requestedPermissions as ResourcePermission[];
}

function createDemoState(): WorkspaceDataState {
  return {
    checkpoints: checkpointRailItems,
    dataSourceLabel: "Demo fixture",
    error: null,
    executionItems: executionRailItems,
    health: null,
    hubExtensions: demoHubExtensions,
    authPolicy: demoAuthPolicy,
    authDirectory: demoAuthDirectory,
    auditActions: demoAuditActions,
    authAdminError: null,
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
        const [health, workflowResponse, executionResponse, checkpointResponse, hubExtensionResponse, authPolicyResult, authDirectoryResult, auditActionsResult] = await Promise.all([
          gatewayClient.healthcheck({ signal: abortController.signal }),
          gatewayClient.listWorkflows({ signal: abortController.signal }),
          gatewayClient.listExecutions({ signal: abortController.signal }),
          gatewayClient.listCheckpoints({ signal: abortController.signal }),
          gatewayClient.listHubExtensions({ signal: abortController.signal }),
          gatewayClient.getAuthPolicy({ signal: abortController.signal }).then(
            (policy) => ({ policy, error: null }),
            (error: unknown) => ({ policy: null, error: error instanceof Error ? error.message : "Auth policy unavailable" })
          ),
          gatewayClient.getAuthDirectory({ signal: abortController.signal }).then(
            (directory) => ({ directory, error: null }),
            (error: unknown) => ({ directory: null, error: error instanceof Error ? error.message : "Auth directory unavailable" })
          ),
          gatewayClient.queryAuditActions({ signal: abortController.signal }).then(
            (response) => ({ events: response.events, error: null }),
            (error: unknown) => ({ events: [], error: error instanceof Error ? error.message : "Audit query unavailable" })
          )
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
          hubExtensions:
            hubExtensionResponse.items.length > 0 ? hubExtensionResponse.items : demoHubExtensions,
          authPolicy: authPolicyResult.policy,
          authDirectory: authDirectoryResult.directory,
          auditActions: auditActionsResult.events,
          authAdminError: authPolicyResult.error ?? authDirectoryResult.error ?? auditActionsResult.error,
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

function chartPreviewSeries(data: GatewayDashboardChartDataResponse) {
  const measure = data.semantic.measures[0];
  const dimension = data.semantic.dimensions[0] ?? data.fields[0] ?? "label";
  return data.rows.slice(0, 6).map((row, index) => ({
    id: `${dimension}-${index}`,
    label: String(row[dimension] ?? `row-${index + 1}`),
    value: Number(row[measure] ?? 0)
  }));
}

function chartPreviewMetric(data: GatewayDashboardChartDataResponse) {
  const measure = data.semantic.measures[0];
  const firstRow = data.rows[0] ?? {};
  return {
    label: data.datasetKey,
    measure,
    value: firstRow[measure] ?? "pending"
  };
}

function renderPublishedChartPreview(
  chart: DashboardChartDefinition,
  data: GatewayDashboardChartDataResponse | undefined,
  activeFilter: ViewerChartFilter | null,
  onSelectFilter: (filter: ViewerChartFilter) => void,
  onOpenDrilldown: (row: DashboardDatasetRow, rowIndex: number, filter: ViewerChartFilter | null, matchingRowCount: number) => void
) {
  if (!data) {
    return <div className="repository-empty"><span>Chart data pending.</span></div>;
  }

  if (chart.family === "metric") {
    const metric = chartPreviewMetric(data);
    return (
      <div className="inspector-stack">
        <div className="inspector-row">
          <strong>{metric.measure}</strong>
          <span>{String(metric.value)}</span>
        </div>
        <div className="inspector-row">
          <strong>Dataset</strong>
          <span>{metric.label}</span>
        </div>
        {activeFilter ? <div className="inspector-row"><strong>Filter</strong><span>{activeFilter.field}={activeFilter.value}</span></div> : null}
        {data.rows[0] ? (
          <button
            className="secondary-action-button"
            onClick={() => {
              onOpenDrilldown(data.rows[0], 0, activeFilter, data.rowCount);
            }}
            type="button"
          >
            Drill into metric row
          </button>
        ) : null}
      </div>
    );
  }

  if (chart.family === "table") {
    const previewFields = data.fields.slice(0, 4);
    return (
      <div className="repository-table-scroll">
        <table className="repository-table">
          <thead>
            <tr>
              {previewFields.map((field) => (
                <th key={field}>{field}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {data.rows.slice(0, 4).map((row, rowIndex) => (
              <tr key={`${chart.chartId}-row-${rowIndex}`}>
                {previewFields.map((field) => (
                  <td key={`${field}-${rowIndex}`}>
                  <button
                    className="route-list-item"
                    onClick={() => {
                      const nextFilter = { field, value: String(row[field] ?? "") };
                      const matchingRowCount = data.rows.filter(
                        (candidate) => String(candidate[nextFilter.field] ?? "") === nextFilter.value
                      ).length;
                      onSelectFilter(nextFilter);
                      onOpenDrilldown(row, rowIndex, nextFilter, matchingRowCount);
                    }}
                    type="button"
                  >
                    {String(row[field] ?? "-")}
                  </button>
                </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  }

  const series = chartPreviewSeries(data);
  const maxValue = Math.max(...series.map((entry) => entry.value), 1);
  return (
    <div className="inspector-stack">
      {series.map((entry, index) => {
        const width = `${Math.max((entry.value / maxValue) * 100, 12)}%`;
        const background =
          chart.family === "bar"
            ? "linear-gradient(90deg, rgba(86,156,214,0.85), rgba(86,156,214,0.2))"
            : chart.family === "area"
              ? "linear-gradient(90deg, rgba(106,190,120,0.7), rgba(106,190,120,0.18))"
              : "linear-gradient(90deg, rgba(200,124,255,0.85), rgba(200,124,255,0.2))";
        return (
          <div className="inspector-stack" key={entry.id}>
            <div className="inspector-row">
              <button
                className={`route-list-item ${activeFilter?.value === entry.label ? "is-active" : ""}`}
                onClick={() => {
                  const dimension = data.semantic.dimensions[0] ?? data.fields[0] ?? "label";
                  const nextFilter = { field: dimension, value: entry.label };
                  const matchingRowCount = data.rows.filter(
                    (candidate) => String(candidate[nextFilter.field] ?? "") === nextFilter.value
                  ).length;
                  onSelectFilter(nextFilter);
                  const row = data.rows[index];
                  if (row) {
                    onOpenDrilldown(row, index, nextFilter, matchingRowCount);
                  }
                }}
                type="button"
              >
                {entry.label}
              </button>
              <span>{entry.value}</span>
            </div>
            <div
              aria-hidden="true"
              style={{
                width,
                height: chart.family === "line" ? 4 : 12,
                borderRadius: 999,
                background,
                opacity: chart.family === "area" ? 0.9 : 1
              }}
            />
          </div>
        );
      })}
    </div>
  );
}

function chartRefreshSummary(data?: GatewayDashboardChartDataResponse) {
  if (!data) {
    return "pending";
  }
  return data.cache.live ? `live · ${data.cache.refreshMode}` : `snapshot · ${data.cache.refreshMode}`;
}

function applyViewerChartFilter(
  data: GatewayDashboardChartDataResponse,
  filter: ViewerChartFilter | null
): GatewayDashboardChartDataResponse {
  if (!filter) {
    return data;
  }
  const rows = data.rows.filter((row) => String(row[filter.field] ?? "") === filter.value);
  return { ...data, rows, rowCount: rows.length };
}

function applyViewerRowSearch(
  data: GatewayDashboardChartDataResponse,
  search: string
): GatewayDashboardChartDataResponse {
  const needle = search.trim().toLowerCase();
  if (needle.length === 0) {
    return data;
  }
  const rows = data.rows.filter((row) =>
    data.fields.some((field) => String(row[field] ?? "").toLowerCase().includes(needle))
  );
  return { ...data, rows, rowCount: rows.length };
}

function applyViewerChartView(
  data: GatewayDashboardChartDataResponse,
  filter: ViewerChartFilter | null,
  search: string
): GatewayDashboardChartDataResponse {
  return applyViewerRowSearch(applyViewerChartFilter(data, filter), search);
}

function chartRowsJson(rows: DashboardDatasetRow[]): string {
  return `${JSON.stringify(rows, null, 2)}
`;
}

function chartCsv(data: GatewayDashboardChartDataResponse): string {
  const fields = data.fields;
  const escape = (value: unknown) => {
    const raw = String(value ?? "");
    return raw.includes(",") || raw.includes('"') || raw.includes("\n")
      ? `"${raw.replaceAll('"', '""')}"`
      : raw;
  };
  const lines = [fields.map(escape).join(",")];
  for (const row of data.rows) {
    lines.push(fields.map((field) => escape(row[field])).join(","));
  }
  return `${lines.join("\n")}\n`;
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

function buildDashboardId(workflow: WorkflowDefinition): string {
  const takenIds = new Set((workflow.dashboards ?? []).map((dashboard) => dashboard.dashboardId));
  let index = Math.max(1, takenIds.size + 1);
  while (takenIds.has(`dashboard-${index}`)) {
    index += 1;
  }
  return `dashboard-${index}`;
}

function buildDashboardChartId(dashboard: DashboardDefinition): string {
  const takenIds = new Set(dashboard.charts.map((chart) => chart.chartId));
  let index = Math.max(1, takenIds.size + 1);
  while (takenIds.has(`chart-${index}`)) {
    index += 1;
  }
  return `chart-${index}`;
}

function buildDashboardPanel(index: number) {
  const column = index % 2;
  const row = Math.floor(index / 2);
  return {
    x: column * 6,
    y: row * 4,
    w: 6,
    h: 4
  };
}

function createDefaultDashboard(workflow: WorkflowDefinition): DashboardDefinition {
  const outletNode =
    workflow.nodes.find((node) => node.type === "bi.outlet") ??
    workflow.nodes.find((node) => node.ports.some((port) => port.direction === "output" && port.type === "stream_channel")) ??
    workflow.nodes[0];

  return {
    dashboardId: buildDashboardId(workflow),
    name: `Dashboard ${((workflow.dashboards ?? []).length || 0) + 1}`,
    binding: {
      outletNodeId: outletNode?.id ?? workflow.workflowId,
      datasetKey: "dataset_main",
      refreshMode: "manual"
    },
    charts: [
      {
        chartId: "chart-1",
        title: "Primary Chart",
        family: "line",
        xField: "x",
        yField: "y",
        panel: buildDashboardPanel(0)
      }
    ]
  };
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
      detail: "Graph is wired and waiting on runtime target confirmation",
      label: "GPU-aware",
      tone: "live"
    };
  }

  return {
    detail: "Node is wired for next execution",
    label: "Ready",
    tone: "good"
  };
}

function buildValidationItems(
  node: NodeDefinition,
  layout: CanvasNodeLayout | undefined,
  connections: ConnectionDefinition[]
): NodeValidationSummary[] {
  return [
    buildNodeValidationSummary(node, connections),
    {
      detail: layout?.checkpointTag ?? "No checkpoint tag attached",
      label: "Checkpoint",
      tone: layout?.checkpointTag ? "good" : "warn"
    },
    {
      detail: layout?.runtime ?? "Awaiting runtime metadata",
      label: "Runtime label",
      tone: "live"
    }
  ];
}

function buildSampleOutput(node: NodeDefinition): string {
  const outputPort = node.ports.find((port) => port.direction === "output");
  return outputPort ? `${outputPort.id} emits ${formatPortType(outputPort.type)} payloads.` : "No output port on selected node.";
}

function cloneNodeDefinition(node: NodeDefinition): NodeDefinition {
  return {
    ...node,
    ports: node.ports.map((port) => ({ ...port })),
    config: { ...node.config }
  };
}

function buildRepositoryCatalog(workflow: WorkflowDefinition): NodeDefinition[] {
  const usedTypes = new Set(workflow.nodes.map((node) => node.type));
  return starterNodeCatalog
    .map((node) => ({ ...cloneNodeDefinition(node), name: usedTypes.has(node.type) ? node.name : node.name }))
    .sort((left, right) => left.name.localeCompare(right.name));
}

function findGraphLayout(workflow: WorkflowDefinition, nodeId: string) {
  return workflow.graph?.nodeLayouts.find((layout) => layout.nodeId === nodeId);
}

function upsertGraphLayout(
  workflow: WorkflowDefinition,
  nodeId: string,
  updates: Partial<NonNullable<WorkflowDefinition["graph"]>["nodeLayouts"][number]>
): WorkflowDefinition {
  const nodeLayouts = workflow.graph?.nodeLayouts ?? [];
  const existing = nodeLayouts.find((layout) => layout.nodeId === nodeId);
  const nextLayout = {
    nodeId,
    x: existing?.x ?? 40,
    y: existing?.y ?? 40,
    ...existing,
    ...updates
  };

  return {
    ...workflow,
    graph: {
      revision: (workflow.graph?.revision ?? 0) + 1,
      viewport: workflow.graph?.viewport ?? { x: 0, y: 0, zoom: 1 },
      selectedNodeId: workflow.graph?.selectedNodeId ?? nodeId,
      nodeLayouts: [...nodeLayouts.filter((layout) => layout.nodeId !== nodeId), nextLayout]
    }
  };
}

function applyNodePositionOverrides(
  workflow: WorkflowDefinition,
  nodePositionOverrides: Record<string, { x: number; y: number }>,
  selectedNodeId: string
): WorkflowDefinition {
  const nodeIds = Object.keys(nodePositionOverrides);
  if (nodeIds.length === 0) {
    return workflow;
  }

  const existingLayouts = workflow.graph?.nodeLayouts ?? [];
  const layoutMap = new Map(existingLayouts.map((layout) => [layout.nodeId, layout]));

  const nextLayouts = workflow.nodes.map((node, index) => {
    const override = nodePositionOverrides[node.id];
    const current = layoutMap.get(node.id);
    return {
      nodeId: node.id,
      x: override?.x ?? current?.x ?? 36 + (index % 3) * 248,
      y: override?.y ?? current?.y ?? 44 + Math.floor(index / 3) * 156,
      width: current?.width,
      checkpointTag: current?.checkpointTag,
      notes: current?.notes
    };
  });

  return {
    ...workflow,
    graph: {
      revision: (workflow.graph?.revision ?? 0) + 1,
      viewport: workflow.graph?.viewport ?? { x: 0, y: 0, zoom: 1 },
      selectedNodeId,
      nodeLayouts: nextLayouts
    }
  };
}

function mergeNodeLayouts(
  baseLayouts: Record<string, CanvasNodeLayout>,
  realtimeNodeStates: Record<string, RealtimeNodeState>
): Record<string, CanvasNodeLayout> {
  return Object.fromEntries(
    Object.entries(baseLayouts).map(([nodeId, layout]) => {
      const realtime = realtimeNodeStates[nodeId];
      if (!realtime) {
        return [nodeId, layout];
      }
      return [
        nodeId,
        {
          ...layout,
          checkpointTag: realtime.checkpointTag ?? layout.checkpointTag,
          runtime: realtime.runtime,
          status: realtime.status
        }
      ];
    })
  );
}

function mergeLayoutPositions(
  baseLayouts: Record<string, CanvasNodeLayout>,
  nodePositionOverrides: Record<string, { x: number; y: number }>
): Record<string, CanvasNodeLayout> {
  return Object.fromEntries(
    Object.entries(baseLayouts).map(([nodeId, layout]) => {
      const override = nodePositionOverrides[nodeId];
      if (!override) {
        return [nodeId, layout];
      }
      return [nodeId, { ...layout, x: override.x, y: override.y }];
    })
  );
}

function buildFlowVariableDefault(type: WorkflowDefinition["flowVariables"][number]["type"]) {
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

function parseNumericValue(rawValue: string, type: WorkflowDefinition["flowVariables"][number]["type"]) {
  if (type === "Integer") {
    return Number.parseInt(rawValue, 10) || 0;
  }
  return Number.parseFloat(rawValue) || 0;
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
      detail: "Peer node not found in current draft.",
      label: "Missing peer",
      tone: "warn"
    };
  }

  const anchorPort = selectedNode.ports.find((port) => port.id === anchorPortId);
  const peerPort = peerNode.ports.find((port) => port.id === peerPortId);
  if (!anchorPort || !peerPort) {
    return {
      connection: null,
      detail: "Choose ports on both sides.",
      label: "Awaiting ports",
      tone: "warn"
    };
  }

  const sourceNodeId = direction === "outgoing" ? selectedNode.id : peerNode.id;
  const sourcePortId = direction === "outgoing" ? anchorPort.id : peerPort.id;
  const targetNodeId = direction === "outgoing" ? peerNode.id : selectedNode.id;
  const targetPortId = direction === "outgoing" ? peerPort.id : anchorPort.id;
  const dataType = direction === "outgoing" ? anchorPort.type : peerPort.type;

  if (anchorPort.type !== peerPort.type) {
    return {
      connection: null,
      detail: "Type mismatch between selected ports.",
      label: "Type mismatch",
      tone: "warn"
    };
  }

  const duplicate = workflow.connections.some(
    (connection) =>
      connection.sourceNodeId === sourceNodeId &&
      connection.sourcePortId === sourcePortId &&
      connection.targetNodeId === targetNodeId &&
      connection.targetPortId === targetPortId
  );
  if (duplicate) {
    return {
      connection: null,
      detail: "Connection already exists in current draft.",
      label: "Duplicate edge",
      tone: "warn"
    };
  }

  const occupiedTarget = workflow.connections.some(
    (connection) =>
      connection.targetNodeId === targetNodeId &&
      connection.targetPortId === targetPortId
  );
  if (occupiedTarget) {
    return {
      connection: null,
      detail: "Target port already occupied.",
      label: "Target occupied",
      tone: "warn"
    };
  }

  return {
    connection: {
      sourceNodeId,
      sourcePortId,
      targetNodeId,
      targetPortId,
      dataType
    },
    detail: `${sourcePortId} can connect to ${targetPortId}.`,
    label: "Compatible edge",
    tone: "good"
  };
}

function describeConnection(workflow: WorkflowDefinition, connection: ConnectionDefinition): string {
  const sourceNode = workflow.nodes.find((node) => node.id === connection.sourceNodeId);
  const targetNode = workflow.nodes.find((node) => node.id === connection.targetNodeId);
  return `${sourceNode?.name ?? connection.sourceNodeId}.${connection.sourcePortId} -> ${targetNode?.name ?? connection.targetNodeId}.${connection.targetPortId}`;
}

function buildAutoConnection(workflow: WorkflowDefinition, selectedNodeId: string, nextNode: NodeDefinition): ConnectionDefinition | null {
  const selectedNode = workflow.nodes.find((node) => node.id === selectedNodeId);
  if (!selectedNode) {
    return null;
  }

  const outputPort = selectedNode.ports.find((port) => port.direction === "output");
  const inputPort = nextNode.ports.find((port) => port.direction === "input" && port.type === outputPort?.type);
  if (!outputPort || !inputPort) {
    return null;
  }

  return {
    sourceNodeId: selectedNode.id,
    sourcePortId: outputPort.id,
    targetNodeId: nextNode.id,
    targetPortId: inputPort.id,
    dataType: outputPort.type
  };
}

function controlFlowNodeIds(controlFlow: NonNullable<WorkflowDefinition["controlFlow"]>[number]): string[] {
  return [
    controlFlow.startNodeId,
    controlFlow.endNodeId,
    controlFlow.defaultTargetNodeId,
    controlFlow.sourceNodeId,
    controlFlow.targetNodeId,
    ...(controlFlow.tryNodeIds ?? []),
    ...(controlFlow.catchNodeIds ?? []),
    ...(controlFlow.cases ?? []).map((item) => item.targetNodeId)
  ].filter((nodeId): nodeId is string => Boolean(nodeId));
}

function describeControlFlow(controlFlow: NonNullable<WorkflowDefinition["controlFlow"]>[number]): string {
  switch (controlFlow.kind) {
    case "loop":
      return `${controlFlow.iterationMode ?? "loop"} / max ${controlFlow.maxIterations ?? "unset"}`;
    case "switch":
      return `${controlFlow.selector ?? "selector"} / ${controlFlow.cases?.length ?? 0} cases`;
    case "try_catch":
      return `${controlFlow.tryNodeIds?.length ?? 0} try nodes / ${controlFlow.catchNodeIds?.length ?? 0} catch nodes`;
    case "parallel_chunk":
      return `chunk ${controlFlow.chunkSize ?? "unset"} / concurrency ${controlFlow.maxConcurrency ?? "unset"}`;
    default:
      return "control-flow metadata";
  }
}

function buildDraftExecution(workflow: WorkflowDefinition, trigger: string, status: WorkflowStatus): ExecutionRailItem {
  return {
    id: `exec-${Date.now()}`,
    workflowId: workflow.workflowId,
    status,
    trigger,
    startedAt: new Date().toISOString(),
    duration: "00:00:08",
    planner: workflow.runtime?.runMode === "stream" ? "stream-worker" : "cpu-batch-v1"
  };
}

function buildActionTimestampLabel(): string {
  return new Date().toISOString();
}

function buildRealtimeRuntimeLabel(status: WorkflowStatus, executionHint: ExecutionHint): string {
  if (status === "streaming_active") {
    return "Realtime stream active";
  }
  if (executionHint === "gpu_preferred" || executionHint === "gpu_required") {
    return "GPU-capable runtime path";
  }
  return "CPU-oriented runtime path";
}

function mergeExecutionRailItem(currentItems: ExecutionRailItem[], nextItem: ExecutionRailItem): ExecutionRailItem[] {
  return [nextItem, ...currentItems.filter((item) => item.id !== nextItem.id)];
}

function getHubTrust(extension: GatewayHubExtensionRecord) {
  return extension.trust ?? {
    trusted: false,
    level: "untrusted",
    warnings: [] as string[],
    blockers: [] as string[],
    evaluatedAt: ""
  };
}

function getHubUpgrade(extension: GatewayHubExtensionRecord) {
  return extension.upgrade ?? {
    upgradeAvailable: false,
    latestVersion: extension.manifest.version,
    evaluatedAt: ""
  };
}

function hubActionBlocked(extension: GatewayHubExtensionRecord) {
  if (extension.installState === "enabled") {
    return false;
  }
  return (
    extension.installState === "incompatible" ||
    extension.compatibility.blockers.length > 0 ||
    getHubTrust(extension).blockers.length > 0 ||
    extension.verification.blockers.length > 0
  );
}

function buildSampleHubManifest(): HubExtensionManifest {
  return {
    extensionId: "juliaflow-private-mirror-pack",
    name: "Private Mirror Pack",
    version: "0.1.0",
    publisher: "partner",
    summary: "Sample published partner pack with artifact hash, sandbox command, and offline mirror metadata.",
    packageRef: "hub://private/mirror-pack",
    tags: ["partner", "private", "offline-mirror"],
    engineCompatibility: "alpha-core",
    requiredContractVersion: "0.1.0",
    supportedCheckpoints: ["cp/02-alpha-core"],
    compatibleCheckpoints: ["cp/02-alpha-core"],
    dependencies: [],
    publisherIdentity: "partner:private-mirror",
    artifactHashes: { package: "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" },
    compatibilitySandboxCommand: "julia --project=. extensions/private-mirror/test/runtests.jl",
    mirrorRefs: ["mirror://offline/private-mirror-pack", "private://workspace/private-mirror-pack"],
    signature: "sig:partner:private-mirror:v0.1.0",
    releaseNotesRef: "https://example.test/private-mirror-pack"
  };
}

function NodeCard({
  isDimmed,
  isSelected,
  layout,
  node,
  onDragStart,
  onSelect,
  selectedConnections
}: {
  isDimmed: boolean;
  isSelected: boolean;
  layout: CanvasNodeLayout | undefined;
  node: NodeDefinition;
  onDragStart: (nodeId: string, clientX: number, clientY: number) => void;
  onSelect: (nodeId: string) => void;
  selectedConnections: ConnectionDefinition[];
}) {
  const validation = buildNodeValidationSummary(node, selectedConnections);
  return (
    <button
      aria-label={`Select ${node.name}`}
      className={`canvas-node is-${validation.tone} ${isSelected ? "is-selected" : ""} ${isDimmed ? "is-dimmed" : ""}`}
      onClick={() => {
        onSelect(node.id);
      }}
      onMouseDown={(event) => {
        onDragStart(node.id, event.clientX, event.clientY);
      }}
      style={{
        left: `${layout?.x ?? 0}px`,
        top: `${layout?.y ?? 0}px`,
        width: `${layout?.width ?? 180}px`
      }}
      type="button"
    >
      <div className="canvas-node-head">
        <div>
          <small className="canvas-node-type">{formatNodeType(node.type)}</small>
          <strong>{node.name}</strong>
        </div>
        <StatusBadge label={layout?.status ?? "configured"} />
      </div>
      <div className="canvas-node-runtime">{layout?.runtime ?? "Configured runtime"}</div>
      <div className="canvas-node-ports">
        <div className="node-port-column">
          {node.ports
            .filter((port) => port.direction === "input")
            .map((port) => (
              <div
                className={`node-port ${findPortConnections(selectedConnections, node.id, port).length > 0 ? "is-connected" : "is-open"}`}
                data-port-type={port.type}
                key={port.id}
              >
                <span className="node-port-dot" />
                <small>{formatPortType(port.type)}</small>
                <strong>{port.id}</strong>
              </div>
            ))}
        </div>
        <div className="node-port-column is-output">
          {node.ports
            .filter((port) => port.direction === "output")
            .map((port) => (
              <div
                className={`node-port is-output ${findPortConnections(selectedConnections, node.id, port).length > 0 ? "is-connected" : "is-open"}`}
                data-port-type={port.type}
                key={port.id}
              >
                <span className="node-port-dot" />
                <small>{formatPortType(port.type)}</small>
                <strong>{port.id}</strong>
              </div>
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
  nodeLayouts
}: {
  connection: ConnectionDefinition;
  isActive: boolean;
  isDimmed: boolean;
  nodeLayouts: Record<string, CanvasNodeLayout>;
}) {
  const sourceLayout = nodeLayouts[connection.sourceNodeId];
  const targetLayout = nodeLayouts[connection.targetNodeId];
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
  const [activeView, setActiveView] = useState<AppView>(() => {
    const dashboardId = getInitialViewerDashboardId();
    return dashboardId ? "dashboard" : getAppViewFromPath(getInitialPathname());
  });
  const [activeInspectorTab, setActiveInspectorTab] = useState<InspectorTab>("config");
  const [selectedNodeId, setSelectedNodeId] = useState(
    workspaceData.workflow.nodes[1]?.id ?? workspaceData.workflow.nodes[0]?.id ?? ""
  );
  const [activeRail, setActiveRail] = useState<ExecutionTab>("executions");
  const [workflow, setWorkflow] = useState<WorkflowDefinition>(workspaceData.workflow);
  const [executionItems, setExecutionItems] = useState<ExecutionRailItem[]>(workspaceData.executionItems);
  const [hubExtensions, setHubExtensions] = useState<GatewayHubExtensionRecord[]>(workspaceData.hubExtensions);
  const [authPolicyDraft, setAuthPolicyDraft] = useState<GatewayAuthPolicy>(workspaceData.authPolicy ?? demoAuthPolicy);
  const [authDirectoryDraft, setAuthDirectoryDraft] = useState<GatewayAuthDirectory>(workspaceData.authDirectory ?? demoAuthDirectory);
  const [roleBindingDraft, setRoleBindingDraft] = useState<RoleBindingDraft>(() => createEmptyRoleBindingDraft());
  const [resourcePolicyDraft, setResourcePolicyDraft] = useState<ResourcePolicyDraft>(() => createEmptyResourcePolicyDraft());
  const [authUserDraft, setAuthUserDraft] = useState<AuthUserDraft>(() => createEmptyAuthUserDraft());
  const [authWorkspaceDraft, setAuthWorkspaceDraft] = useState<AuthWorkspaceDraft>(() => createEmptyAuthWorkspaceDraft());
  const [publishedDashboards, setPublishedDashboards] = useState<PublishedDashboardDefinition[]>([]);
  const [publishedDashboard, setPublishedDashboard] = useState<PublishedDashboardDefinition | null>(null);
  const [activeDashboardId, setActiveDashboardId] = useState<string | null>(
    workspaceData.workflow.dashboards?.[0]?.dashboardId ?? null
  );
  const [viewerDashboardId, setViewerDashboardId] = useState<string | null>(getInitialViewerDashboardId);
  const [viewerShareToken, setViewerShareToken] = useState<string | null>(getInitialViewerShareToken);
  const [viewerWorkspaceToken, setViewerWorkspaceToken] = useState<string | null>(getInitialViewerWorkspaceToken);
  const [viewerDashboard, setViewerDashboard] = useState<PublishedDashboardDefinition | null>(null);
  const [dashboardChartData, setDashboardChartData] = useState<Record<string, GatewayDashboardChartDataResponse>>({});
  const [viewerChartFilter, setViewerChartFilter] = useState<ViewerChartFilter | null>(null);
  const [viewerRowSearch, setViewerRowSearch] = useState("");
  const [viewerChartDrilldown, setViewerChartDrilldown] = useState<ViewerChartDrilldown | null>(null);
  const [viewerChartRefreshNonce, setViewerChartRefreshNonce] = useState(0);
  const [isViewerRefreshing, setIsViewerRefreshing] = useState(false);
  const [publishVisibility, setPublishVisibility] = useState<"workspace" | "public">("workspace");
  const [nodePositionOverrides, setNodePositionOverrides] = useState<Record<string, { x: number; y: number }>>({});
  const [knownWorkflowIds, setKnownWorkflowIds] = useState<string[]>(
    workspaceData.workflows.map((item) => item.workflowId)
  );
  const [isDirty, setIsDirty] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isSavingAuthPolicy, setIsSavingAuthPolicy] = useState(false);
  const [isSavingAuthDirectory, setIsSavingAuthDirectory] = useState(false);
  const [isRunningWorkflow, setIsRunningWorkflow] = useState(false);
  const [actionFeedback, setActionFeedback] = useState<ActionFeedback | null>(null);
  const [connectionDraftDirection, setConnectionDraftDirection] = useState<ConnectionDraftDirection>("outgoing");
  const [connectionDraftPeerNodeId, setConnectionDraftPeerNodeId] = useState("");
  const [connectionDraftAnchorPortId, setConnectionDraftAnchorPortId] = useState("");
  const [connectionDraftPeerPortId, setConnectionDraftPeerPortId] = useState("");
  const [realtimeConnectionState, setRealtimeConnectionState] = useState<RealtimeConnectionState>("idle");
  const [realtimeNodeStates, setRealtimeNodeStates] = useState<Record<string, RealtimeNodeState>>({});
  const dragStateRef = useRef<DragState | null>(null);
  const [isPending, startTransition] = useTransition();
  const deferredQuery = useDeferredValue(query);
  const normalizedNeedle = deferredQuery.trim().toLowerCase();

  useEffect(() => {
    setWorkflow(workspaceData.workflow);
    setExecutionItems(workspaceData.executionItems);
    setHubExtensions(workspaceData.hubExtensions);
    setAuthPolicyDraft(workspaceData.authPolicy ?? demoAuthPolicy);
    setAuthDirectoryDraft(workspaceData.authDirectory ?? demoAuthDirectory);
    setNodePositionOverrides({});
    setKnownWorkflowIds(workspaceData.workflows.map((item) => item.workflowId));
    setRealtimeNodeStates({});
    setIsDirty(false);
    setPublishedDashboard(null);
    setPublishedDashboards([]);
    setActiveDashboardId(workspaceData.workflow.dashboards?.[0]?.dashboardId ?? null);
  }, [workspaceData.authDirectory, workspaceData.authPolicy, workspaceData.executionItems, workspaceData.hubExtensions, workspaceData.workflow, workspaceData.workflows]);

  useEffect(() => {
    function handlePopState() {
      const dashboardId = getInitialViewerDashboardId();
      setViewerDashboardId(dashboardId);
      setViewerShareToken(getInitialViewerShareToken());
      setViewerWorkspaceToken(getInitialViewerWorkspaceToken());
      setActiveView(dashboardId ? "dashboard" : getAppViewFromPath(getInitialPathname()));
    }

    window.addEventListener("popstate", handlePopState);
    return () => {
      window.removeEventListener("popstate", handlePopState);
    };
  }, []);

  useEffect(() => {
    if (viewerDashboardId === null || typeof window === "undefined") {
      return;
    }
    if (window.location.pathname.startsWith("/dashboard")) {
      return;
    }
    window.history.replaceState(
      {},
      "",
      `${buildViewPath("dashboard")}${buildDashboardViewerSearch(
        viewerDashboardId,
        viewerShareToken,
        viewerWorkspaceToken
      )}`
    );
  }, [viewerDashboardId, viewerShareToken, viewerWorkspaceToken]);

  useEffect(() => {
    if (viewerDashboardId === null) {
      setViewerDashboard(null);
      setDashboardChartData({});
      setViewerChartFilter(null);
      setViewerRowSearch("");
      setViewerChartDrilldown(null);
      return;
    }

    const existingDashboard = publishedDashboards.find((item) => item.dashboardId === viewerDashboardId);
    if (existingDashboard) {
      setViewerDashboard(existingDashboard);
      return;
    }

    if (gatewayBaseUrl.length === 0) {
      setViewerDashboard(null);
      return;
    }

    let isClosed = false;
    const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });
    const workspaceBearerToken = getConfiguredWorkspaceDashboardBearerToken();
    const requestOptions =
      workspaceBearerToken === null ? undefined : { headers: { Authorization: `Bearer ${workspaceBearerToken}` } };

    gatewayClient
      .getPublishedDashboard(viewerDashboardId, {
        shareToken: viewerShareToken ?? undefined,
        workspaceToken: viewerWorkspaceToken ?? getConfiguredWorkspaceDashboardToken() ?? undefined
      }, requestOptions)
      .then((dashboard) => {
        if (!isClosed) {
          setViewerDashboard(dashboard);
        }
      })
      .catch(() => {
        if (!isClosed) {
          setViewerDashboard(null);
        }
      });

    return () => {
      isClosed = true;
    };
  }, [gatewayBaseUrl, publishedDashboards, viewerDashboardId, viewerShareToken, viewerWorkspaceToken]);

  useEffect(() => {
    setDashboardChartData({});
    if (viewerDashboard === null || gatewayBaseUrl.length === 0) {
      return;
    }

    let isClosed = false;
    const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });
    const workspaceBearerToken = getConfiguredWorkspaceDashboardBearerToken();
    const requestOptions =
      workspaceBearerToken === null ? undefined : { headers: { Authorization: `Bearer ${workspaceBearerToken}` } };
    const readRequest = {
      shareToken: viewerDashboard.shareToken ?? viewerShareToken ?? undefined,
      workspaceToken: viewerWorkspaceToken ?? getConfiguredWorkspaceDashboardToken() ?? undefined
    };

    setIsViewerRefreshing(true);
    Promise.all(
      viewerDashboard.charts.map((chart) =>
        gatewayClient
          .getPublishedDashboardChartData(viewerDashboard.dashboardId, chart.chartId, readRequest, requestOptions)
          .then((data) => [chart.chartId, data] as const)
      )
    )
      .then((entries) => {
        if (!isClosed) {
          setDashboardChartData(Object.fromEntries(entries));
        }
      })
      .catch(() => {
        if (!isClosed) {
          setDashboardChartData({});
        }
      })
      .finally(() => {
        if (!isClosed) {
          setIsViewerRefreshing(false);
        }
      });

    return () => {
      isClosed = true;
    };
  }, [gatewayBaseUrl, viewerDashboard, viewerShareToken, viewerWorkspaceToken, viewerChartRefreshNonce]);

  useEffect(() => {
    if (viewerDashboard === null) {
      return;
    }
    const shouldPoll = Object.values(dashboardChartData).some((item) => item.cache.live);
    if (!shouldPoll) {
      return;
    }
    const timer = window.setInterval(() => {
      setViewerChartRefreshNonce((value) => value + 1);
    }, 15000);
    return () => {
      window.clearInterval(timer);
    };
  }, [dashboardChartData, viewerDashboard]);

  useEffect(() => {
    if (workflow.workflowId.length === 0) {
      setPublishedDashboards([]);
      return;
    }

    if (gatewayBaseUrl.length === 0) {
      setPublishedDashboards((currentDashboards) => {
        if (publishedDashboard === null) {
          return currentDashboards;
        }
        return [
          ...currentDashboards.filter((item) => item.dashboardId !== publishedDashboard.dashboardId),
          publishedDashboard
        ].sort((left, right) => left.dashboardId.localeCompare(right.dashboardId));
      });
      return;
    }

    let isClosed = false;
    const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });

    gatewayClient
      .listPublishedDashboards(workflow.workflowId)
      .then((response) => {
        if (!isClosed) {
          setPublishedDashboards(response.items);
        }
      })
      .catch(() => {
        if (!isClosed) {
          setPublishedDashboards([]);
        }
      });

    return () => {
      isClosed = true;
    };
  }, [gatewayBaseUrl, publishedDashboard, workflow.workflowId]);

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

    function handleDashboardPublished(dashboard: PublishedDashboardDefinition) {
      startTransition(() => {
        setPublishedDashboards((currentDashboards) =>
          [
            ...currentDashboards.filter((item) => item.dashboardId !== dashboard.dashboardId),
            dashboard
          ].sort((left, right) => left.dashboardId.localeCompare(right.dashboardId))
        );
      });
      if (dashboard.dashboardId === viewerDashboardId) {
        setViewerDashboard(dashboard);
        setViewerChartRefreshNonce((value) => value + 1);
      }
    }

    function handleDashboardOutletUpdated(dashboardId: string) {
      if (dashboardId !== viewerDashboardId) {
        return;
      }
      setViewerChartRefreshNonce((value) => value + 1);
      setActionFeedback({ text: `Live dashboard data invalidated for ${dashboardId}.`, tone: "info" });
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

      if (payload.method === "dashboard.published") {
        handleDashboardPublished(payload.params);
        return;
      }

      if (payload.method === "dashboard.outlet.updated") {
        handleDashboardOutletUpdated(payload.params.dashboardId);
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

    const handleMessage = (event: MessageEvent) => {
      void handleRealtimeMessage(event);
    };

    realtimeClient.socket.addEventListener("open", handleOpen);
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
  const filteredHubExtensions = hubExtensions.filter((extension) => {
    if (!normalizedNeedle) {
      return true;
    }
    return `${extension.manifest.name} ${extension.manifest.publisherIdentity} ${extension.manifest.summary} ${extension.manifest.tags.join(" ")}`
      .toLowerCase()
      .includes(normalizedNeedle);
  });
  const groupedRepositoryNodes = Array.from(
    filteredRepositoryNodes.reduce((groups, node) => {
      const groupLabel = buildRepositoryGroupLabel(node.type);
      groups.set(groupLabel, [...(groups.get(groupLabel) ?? []), node]);
      return groups;
    }, new Map<string, NodeDefinition[]>())
  );
  const filteredPhases = phaseSummaries.filter((phase) => {
    if (!normalizedNeedle) {
      return true;
    }
    return `${phase.id} ${phase.title} ${phase.exitGate}`.toLowerCase().includes(normalizedNeedle);
  });

  const nodeLayouts = mergeLayoutPositions(
    mergeNodeLayouts(buildCanvasNodeLayouts(workflow), realtimeNodeStates),
    nodePositionOverrides
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
  const selectedContainers = (workflow.containers ?? []).filter((container) => container.nodeIds.includes(selectedNode.id));
  const selectedComponents = (workflow.components ?? []).filter((component) => component.nodeIds.includes(selectedNode.id));
  const selectedControlFlow = (workflow.controlFlow ?? []).filter((controlFlow) =>
    controlFlowNodeIds(controlFlow).includes(selectedNode.id)
  );
  const repositoryFamilies = new Set(workflow.nodes.map((node) => buildRepositoryGroupLabel(node.type)));
  const biOutletNode = workflow.nodes.find((node) => node.type === "bi.outlet") ?? null;
  const dashboards = workflow.dashboards ?? [];
  const primaryDashboard =
    dashboards.find((dashboard) => dashboard.dashboardId === activeDashboardId) ?? dashboards[0] ?? null;
  const activePublishedDashboard =
    publishedDashboards.find((dashboard) => dashboard.dashboardId === primaryDashboard?.dashboardId) ??
    (publishedDashboard && primaryDashboard && publishedDashboard.dashboardId === primaryDashboard.dashboardId
      ? publishedDashboard
      : null);
  const selectedSliceNodeIds = new Set<string>([selectedNode.id]);
  const statusCounts = buildStatusCounts(executionItems);
  const unresolvedNodeCount = workflow.nodes.filter((node) => validationByNodeId[node.id].tone === "warn").length;
  const quickAddNodes = repositoryCatalog.slice(0, 3);
  const workflowExistsOnGateway = knownWorkflowIds.includes(workflow.workflowId) || workspaceData.mode === "live";
  const isAuthPolicySaveDisabled =
    isSavingAuthPolicy || (gatewayBaseUrl.length > 0 && workspaceData.authPolicy === null);
  const isAuthDirectorySaveDisabled =
    isSavingAuthDirectory || (gatewayBaseUrl.length > 0 && workspaceData.authDirectory === null);
  const relatedConnections = workflow.connections.filter(
    (connection) => connection.sourceNodeId === selectedNode.id || connection.targetNodeId === selectedNode.id
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

  function handleNodeDragStart(nodeId: string, clientX: number, clientY: number) {
    const layout = nodeLayouts[nodeId];
    if (!layout) {
      return;
    }

    dragStateRef.current = {
      nodeId,
      originX: layout.x,
      originY: layout.y,
      pointerStartX: clientX,
      pointerStartY: clientY
    };
    setSelectedNodeId(nodeId);
  }

  useEffect(() => {
    function handleMouseMove(event: MouseEvent) {
      const dragState = dragStateRef.current;
      if (!dragState) {
        return;
      }

      const nextX = Math.max(20, dragState.originX + event.clientX - dragState.pointerStartX);
      const nextY = Math.max(20, dragState.originY + event.clientY - dragState.pointerStartY);

      setNodePositionOverrides((currentOverrides) => ({
        ...currentOverrides,
        [dragState.nodeId]: { x: nextX, y: nextY }
      }));
    }

    function handleMouseUp() {
      const dragState = dragStateRef.current;
      if (dragState === null) {
        return;
      }

      dragStateRef.current = null;
      setWorkflow((currentWorkflow) =>
        applyNodePositionOverrides(currentWorkflow, nodePositionOverrides, dragState.nodeId)
      );
      setNodePositionOverrides({});
      setIsDirty(true);
    }

    window.addEventListener("mousemove", handleMouseMove);
    window.addEventListener("mouseup", handleMouseUp);

    return () => {
      window.removeEventListener("mousemove", handleMouseMove);
      window.removeEventListener("mouseup", handleMouseUp);
    };
  }, [nodePositionOverrides]);

  async function persistWorkflow(reason: "save" | "run"): Promise<string | null> {
    const persistableWorkflow = applyNodePositionOverrides(workflow, nodePositionOverrides, selectedNodeId);
    if (gatewayBaseUrl.length === 0) {
      setActionFeedback({
        text: `${reason === "save" ? "Draft saved" : "Draft prepared"} locally at ${buildActionTimestampLabel()}.`,
        tone: "demo"
      });
      setWorkflow(persistableWorkflow);
      setNodePositionOverrides({});
      setIsDirty(false);
      return persistableWorkflow.workflowId;
    }

    setIsSaving(true);
    setActionFeedback({
      text: reason === "save" ? "Saving workflow draft to gateway..." : "Syncing workflow draft before run...",
      tone: "info"
    });

    try {
      const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });
      const response = workflowExistsOnGateway
        ? await gatewayClient.updateWorkflow(workflow.workflowId, { workflow: persistableWorkflow })
        : await gatewayClient.createWorkflow({ workflow: persistableWorkflow });

      setKnownWorkflowIds((currentIds) =>
        currentIds.includes(response.workflowId) ? currentIds : [...currentIds, response.workflowId]
      );
      setWorkflow({
        ...persistableWorkflow,
        workflowId: response.workflowId,
        name: response.name,
        version: response.version
      });
      setNodePositionOverrides({});
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
    setActiveView("monitor");

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
      setExecutionItems((currentItems) => mergeExecutionRailItem(currentItems, nextExecutionItem));
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
    nextNode.config = { ...nextNode.config };
    if (!nextNode.config.label) {
      nextNode.config.label = nextNode.name;
    }
    const autoConnection = buildAutoConnection(workflow, selectedNodeId, nextNode);

    updateWorkflowDraft((currentWorkflow) => ({
      ...upsertGraphLayout(
        {
          ...currentWorkflow,
          nodes: [...currentWorkflow.nodes, nextNode],
          connections:
            autoConnection === null
              ? currentWorkflow.connections
              : [...currentWorkflow.connections, autoConnection]
        },
        nextNode.id,
        {
          x: 44 + (currentWorkflow.nodes.length % 4) * 220,
          y: 56 + Math.floor(currentWorkflow.nodes.length / 4) * 164,
          width: 180,
          notes: `Draft node ${nextNode.name} has not been persisted yet.`
        }
      )
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

  function handleFlowVariableChange(index: number, updates: Partial<WorkflowDefinition["flowVariables"][number]>) {
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
          default: buildFlowVariableDefault("String")
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

  function ensureDashboardDraft(): DashboardDefinition {
    return primaryDashboard ?? createDefaultDashboard(workflow);
  }

  function handleCreateDashboard() {
    const nextDashboard = createDefaultDashboard(workflow);
    updateWorkflowDraft((currentWorkflow) => ({
      ...currentWorkflow,
      dashboards: [...(currentWorkflow.dashboards ?? []), nextDashboard]
    }));
    setActiveDashboardId(nextDashboard.dashboardId);
    setActionFeedback({
      text: `Added dashboard draft ${nextDashboard.dashboardId}.`,
      tone: "success"
    });
  }

  function handleDuplicateDashboard() {
    const seedDashboard = ensureDashboardDraft();
    const nextDashboardId = buildDashboardId(workflow);
    const nextDashboard: DashboardDefinition = {
      ...seedDashboard,
      dashboardId: nextDashboardId,
      name: `${seedDashboard.name} copy`,
      charts: seedDashboard.charts.map((chart, index) => ({
        ...chart,
        chartId: `chart-${index + 1}`,
        panel: chart.panel ? { ...chart.panel } : undefined
      }))
    };
    updateWorkflowDraft((currentWorkflow) => ({
      ...currentWorkflow,
      dashboards: [...(currentWorkflow.dashboards ?? []), nextDashboard]
    }));
    setActiveDashboardId(nextDashboard.dashboardId);
    setActionFeedback({
      text: `Duplicated dashboard draft ${seedDashboard.dashboardId} into ${nextDashboard.dashboardId}.`,
      tone: "success"
    });
  }

  function handleRemoveDashboard() {
    if (primaryDashboard === null) {
      return;
    }
    const currentDashboards = dashboards;
    if (currentDashboards.length <= 1) {
      setActionFeedback({
        text: "At least one dashboard draft must remain.",
        tone: "error"
      });
      return;
    }
    const currentIndex = currentDashboards.findIndex(
      (dashboard) => dashboard.dashboardId === primaryDashboard.dashboardId
    );
    const nextDashboard =
      currentDashboards[currentIndex + 1] ?? currentDashboards[currentIndex - 1] ?? currentDashboards[0];
    updateWorkflowDraft((currentWorkflow) => ({
      ...currentWorkflow,
      dashboards: (currentWorkflow.dashboards ?? []).filter(
        (dashboard) => dashboard.dashboardId !== primaryDashboard.dashboardId
      )
    }));
    setActiveDashboardId(nextDashboard?.dashboardId ?? null);
    setActionFeedback({
      text: `Removed dashboard draft ${primaryDashboard.dashboardId}.`,
      tone: "info"
    });
  }

  function handleDashboardChange(updates: Partial<DashboardDefinition>) {
    const seedDashboard = ensureDashboardDraft();
    const nextDashboard = {
      ...seedDashboard,
      ...updates
    };

    updateWorkflowDraft((currentWorkflow) => ({
      ...currentWorkflow,
      dashboards:
        (currentWorkflow.dashboards?.length ?? 0) > 0
          ? (currentWorkflow.dashboards ?? []).map((dashboard) =>
              dashboard.dashboardId === seedDashboard.dashboardId ? nextDashboard : dashboard
            )
          : [nextDashboard]
    }));
    setActiveDashboardId(nextDashboard.dashboardId);
  }

  function handleDashboardBindingChange(updates: Partial<DashboardDefinition["binding"]>) {
    const seedDashboard = ensureDashboardDraft();
    handleDashboardChange({
      binding: {
        ...seedDashboard.binding,
        ...updates
      }
    });
  }

  function handleDashboardChartChange(chartId: string, updates: Partial<DashboardChartDefinition>) {
    const seedDashboard = ensureDashboardDraft();
    handleDashboardChange({
      charts: seedDashboard.charts.map((chart) =>
        chart.chartId === chartId ? { ...chart, ...updates } : chart
      )
    });
  }

  function handleAddDashboardChart() {
    const seedDashboard = ensureDashboardDraft();
    const nextChart: DashboardChartDefinition = {
      chartId: buildDashboardChartId(seedDashboard),
      title: `Chart ${seedDashboard.charts.length + 1}`,
      family: "bar",
      xField: "dimension",
      yField: "value",
      panel: buildDashboardPanel(seedDashboard.charts.length)
    };
    handleDashboardChange({
      charts: [...seedDashboard.charts, nextChart]
    });
    setActionFeedback({
      text: `Added dashboard chart ${nextChart.chartId}.`,
      tone: "info"
    });
  }

  function handleRemoveDashboardChart(chartId: string) {
    const seedDashboard = ensureDashboardDraft();
    handleDashboardChange({
      charts: seedDashboard.charts.filter((chart) => chart.chartId !== chartId)
    });
    setActionFeedback({
      text: `Removed dashboard chart ${chartId}.`,
      tone: "info"
    });
  }

  async function handlePublishDashboard() {
    const draftDashboard = ensureDashboardDraft();
    const request: GatewayDashboardPublishRequest = { visibility: publishVisibility };

    if (gatewayBaseUrl.length === 0) {
      const shareToken =
        publishVisibility === "public" ? `share-${Math.random().toString(36).slice(2, 10)}` : undefined;
      const nextPublished: PublishedDashboardDefinition = {
        dashboardId: draftDashboard.dashboardId,
        workflowId: workflow.workflowId,
        name: draftDashboard.name,
        version: (publishedDashboard?.dashboardId === draftDashboard.dashboardId ? publishedDashboard.version : 0) + 1,
        publishedAt: new Date().toISOString(),
        visibility: publishVisibility,
        shareToken,
        binding: draftDashboard.binding,
        charts: draftDashboard.charts
      };
      setPublishedDashboard(nextPublished);
      setPublishedDashboards((currentDashboards) =>
        [
          ...currentDashboards.filter((item) => item.dashboardId !== nextPublished.dashboardId),
          nextPublished
        ].sort((left, right) => left.dashboardId.localeCompare(right.dashboardId))
      );
      openPublishedDashboard(nextPublished);
      setActionFeedback({
        text: `Published dashboard ${draftDashboard.dashboardId} v${nextPublished.version}.`,
        tone: "success"
      });
      return;
    }

    try {
      const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });
      const response: GatewayDashboardPublishResponse = await gatewayClient.publishDashboard(
        workflow.workflowId,
        draftDashboard.dashboardId,
        request
      );
      setPublishedDashboard(response.dashboard);
      setPublishedDashboards((currentDashboards) =>
        [
          ...currentDashboards.filter((item) => item.dashboardId !== response.dashboard.dashboardId),
          response.dashboard
        ].sort((left, right) => left.dashboardId.localeCompare(right.dashboardId))
      );
      openPublishedDashboard(response.dashboard);
      setActionFeedback({
        text: `Published dashboard ${response.dashboard.dashboardId} v${response.dashboard.version}.`,
        tone: "success"
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unable to publish dashboard.";
      setActionFeedback({ text: `Dashboard publish failed: ${message}`, tone: "error" });
    }
  }

  async function handleCopyDashboardShareLink() {
    const activeDashboard = viewerDashboard ?? activePublishedDashboard;
    if (!activeDashboard || typeof window === "undefined") {
      return;
    }

    const url = `${window.location.origin}${buildViewPath("dashboard")}${buildDashboardViewerSearch(
      activeDashboard.dashboardId,
      activeDashboard.shareToken ?? viewerShareToken,
      activeDashboard.visibility === "workspace"
        ? viewerWorkspaceToken ?? getConfiguredWorkspaceDashboardToken()
        : null
    )}`;
    try {
      if (!("clipboard" in navigator) || typeof navigator.clipboard.writeText !== "function") {
        throw new Error("clipboard unavailable");
      }
      await navigator.clipboard.writeText(url);
      setActionFeedback({ text: `Dashboard share link copied for ${activeDashboard.dashboardId}.`, tone: "success" });
    } catch {
      setActionFeedback({ text: `Dashboard share link: ${url}`, tone: "info" });
    }
  }

  function handleRefreshViewerCharts() {
    setViewerChartRefreshNonce((value) => value + 1);
    setActionFeedback({ text: "Published dashboard refresh requested.", tone: "info" });
  }

  async function writeViewerClipboard(payload: string, successText: string, failurePrefix: string) {
    try {
      if (!("clipboard" in navigator) || typeof navigator.clipboard.writeText !== "function") {
        throw new Error("clipboard unavailable");
      }
      await navigator.clipboard.writeText(payload);
      setActionFeedback({ text: successText, tone: "success" });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unable to write viewer export.";
      setActionFeedback({ text: `${failurePrefix}: ${message}`, tone: "error" });
    }
  }

  async function handleExportDashboardChart(chartId: string, scope: "full" | "filtered" = "filtered") {
    const chartData = dashboardChartData[chartId];
    if (!chartData) {
      setActionFeedback({ text: `Chart export failed: chart data pending for ${chartId}.`, tone: "error" });
      return;
    }
    const exportData = scope === "filtered"
      ? applyViewerChartView(chartData, viewerChartFilter, viewerRowSearch)
      : chartData;
    const viewLabels = [
      viewerChartFilter ? `filter ${viewerChartFilter.field}=${viewerChartFilter.value}` : null,
      viewerRowSearch.trim().length > 0 ? `search ${viewerRowSearch.trim()}` : null
    ].filter((label): label is string => label !== null);
    const filterLabel = scope === "filtered" && viewLabels.length > 0
      ? ` with ${viewLabels.join(" and ")}`
      : scope === "full"
        ? " with all rows"
        : "";
    await writeViewerClipboard(chartCsv(exportData), `Chart CSV copied for ${chartId}${filterLabel}.`, "Chart export failed");
  }

  async function handleExportDrilldownJson() {
    if (!viewerChartDrilldown) {
      setActionFeedback({ text: "Drilldown export failed: no selected row.", tone: "error" });
      return;
    }
    await writeViewerClipboard(
      chartRowsJson([viewerChartDrilldown.row]),
      `Selected row JSON copied for ${viewerChartDrilldown.chartId}.`,
      "Drilldown export failed"
    );
  }

  function handleCloseDashboardViewer() {
    setViewerDashboardId(null);
    setViewerShareToken(null);
    setViewerWorkspaceToken(null);
    setViewerDashboard(null);
    setViewerRowSearch("");
    setViewerChartDrilldown(null);
    if (typeof window !== "undefined") {
      window.history.replaceState({}, "", buildViewPath("dashboard"));
    }
  }

  async function handleHubInstall(extension: GatewayHubExtensionRecord) {
    if (hubActionBlocked(extension)) {
      setActionFeedback({
        text: `Hub action blocked for ${extension.extensionId}: resolve trust and compatibility blockers first.`,
        tone: "error"
      });
      return;
    }

    const nextAction: GatewayHubInstallRequest = {
      action:
        getHubUpgrade(extension).upgradeAvailable
          ? "upgrade"
          : extension.installState === "enabled"
            ? "disable"
            : extension.installState === "available"
              ? "install"
              : "enable"
    };

    if (gatewayBaseUrl.length === 0) {
      setHubExtensions((currentExtensions) =>
        currentExtensions.map((item) =>
          item.extensionId === extension.extensionId
            ? {
                ...item,
                installState:
                  nextAction.action === "disable"
                    ? "disabled"
                    : nextAction.action === "upgrade"
                      ? "enabled"
                      : nextAction.action === "install"
                        ? "installed"
                        : "enabled",
                upgrade:
                  nextAction.action === "upgrade"
                    ? {
                        ...getHubUpgrade(item),
                        upgradeAvailable: false,
                        installedVersion: item.manifest.version,
                        latestVersion: item.manifest.version,
                        targetVersion: undefined
                      }
                    : item.upgrade
              }
            : item
        )
      );
      setActionFeedback({
        text: `Demo Hub ${nextAction.action} queued for ${extension.extensionId}.`,
        tone: "demo"
      });
      return;
    }

    try {
      const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });
      const response = await gatewayClient.installHubExtension(extension.extensionId, nextAction);
      setHubExtensions((currentExtensions) =>
        currentExtensions.map((item) =>
          item.extensionId === extension.extensionId ? response.extension : item
        )
      );
      setActionFeedback({
        text: `Hub ${nextAction.action} completed for ${extension.extensionId}.`,
        tone: "success"
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unable to update Hub extension.";
      setActionFeedback({ text: `Hub update failed: ${message}`, tone: "error" });
    }
  }

  async function handleHubPublishSample() {
    const manifest = buildSampleHubManifest();
    const registerRequest: GatewayHubRegisterRequest = { manifest };

    if (gatewayBaseUrl.length === 0) {
      const demoRecord: GatewayHubExtensionRecord = {
        extensionId: manifest.extensionId,
        manifest,
        installState: "available",
        compatibility: {
          compatible: true,
          warnings: [],
          blockers: [],
          evaluatedAt: buildActionTimestampLabel()
        },
        trust: {
          trusted: true,
          level: "partner_verified",
          warnings: [],
          blockers: [],
          evaluatedAt: buildActionTimestampLabel()
        },
        upgrade: {
          upgradeAvailable: false,
          latestVersion: manifest.version,
          evaluatedAt: buildActionTimestampLabel()
        },
        verification: createHubVerification(false, buildActionTimestampLabel())
      };
      setHubExtensions((currentExtensions) => [
        demoRecord,
        ...currentExtensions.filter((item) => item.extensionId !== manifest.extensionId)
      ]);
      setActionFeedback({
        text: `Demo Hub publish queued for ${manifest.extensionId}.`,
        tone: "demo"
      });
      return;
    }

    try {
      const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });
      const response = await gatewayClient.registerHubExtension(registerRequest);
      setHubExtensions((currentExtensions) => [
        response.extension,
        ...currentExtensions.filter((item) => item.extensionId !== response.extension.extensionId)
      ]);
      setActionFeedback({
        text: `Hub publish completed for ${response.extension.extensionId}.`,
        tone: "success"
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unable to publish Hub extension.";
      setActionFeedback({ text: `Hub publish failed: ${message}`, tone: "error" });
    }
  }

  function handleAddRoleBinding() {
    const principalId = roleBindingDraft.principalId.trim();
    const workspaceId = roleBindingDraft.workspaceId.trim();
    if (principalId.length === 0 || workspaceId.length === 0) {
      setActionFeedback({ text: "Role binding needs principal and workspace.", tone: "error" });
      return;
    }

    const nextBinding = {
      principalId,
      workspaceId,
      role: roleBindingDraft.role
    };
    setAuthPolicyDraft((currentPolicy) => ({
      ...currentPolicy,
      roleBindings: [
        ...currentPolicy.roleBindings.filter(
          (binding) => binding.principalId !== principalId || binding.workspaceId !== workspaceId
        ),
        nextBinding
      ]
    }));
    setRoleBindingDraft(createEmptyRoleBindingDraft());
    setActionFeedback({ text: `Queued role binding for ${principalId}.`, tone: "info" });
  }

  function handleRemoveRoleBinding(index: number) {
    setAuthPolicyDraft((currentPolicy) => ({
      ...currentPolicy,
      roleBindings: currentPolicy.roleBindings.filter((_, bindingIndex) => bindingIndex !== index)
    }));
    setActionFeedback({ text: "Queued role binding removal.", tone: "info" });
  }

  function handleAddResourcePolicy() {
    const resourceType = resourcePolicyDraft.resourceType.trim();
    const resourceId = resourcePolicyDraft.resourceId.trim();
    const workspaceId = resourcePolicyDraft.workspaceId.trim();
    const ownerPermissions = parsePermissionDraft(resourcePolicyDraft.ownerPermissions);
    const editorPermissions = parsePermissionDraft(resourcePolicyDraft.editorPermissions);
    const viewerPermissions = parsePermissionDraft(resourcePolicyDraft.viewerPermissions);

    if (resourceType.length === 0 || resourceId.length === 0 || workspaceId.length === 0) {
      setActionFeedback({ text: "Resource policy needs type, id, and workspace.", tone: "error" });
      return;
    }
    if (!ownerPermissions || !editorPermissions || !viewerPermissions) {
      setActionFeedback({ text: "Resource policy has an unknown permission.", tone: "error" });
      return;
    }

    const nextPolicy = {
      resourceType,
      resourceId,
      workspaceId,
      permissionsByRole: {
        owner: ownerPermissions,
        editor: editorPermissions,
        viewer: viewerPermissions
      }
    };
    setAuthPolicyDraft((currentPolicy) => ({
      ...currentPolicy,
      resourcePolicies: [
        ...currentPolicy.resourcePolicies.filter(
          (policy) =>
            policy.resourceType !== resourceType ||
            policy.resourceId !== resourceId ||
            policy.workspaceId !== workspaceId
        ),
        nextPolicy
      ]
    }));
    setResourcePolicyDraft(createEmptyResourcePolicyDraft());
    setActionFeedback({ text: `Queued resource policy for ${resourceType}:${resourceId}.`, tone: "info" });
  }

  function handleRemoveResourcePolicy(index: number) {
    setAuthPolicyDraft((currentPolicy) => ({
      ...currentPolicy,
      resourcePolicies: currentPolicy.resourcePolicies.filter((_, policyIndex) => policyIndex !== index)
    }));
    setActionFeedback({ text: "Queued resource policy removal.", tone: "info" });
  }

  function handleAddAuthUser() {
    const principalId = authUserDraft.principalId.trim();
    const displayName = authUserDraft.displayName.trim();
    if (principalId.length === 0 || displayName.length === 0) {
      setActionFeedback({ text: "Directory user needs principal and display name.", tone: "error" });
      return;
    }

    const timestamp = new Date().toISOString();
    const nextUser = {
      principalId,
      displayName,
      email: authUserDraft.email.trim() || undefined,
      active: authUserDraft.active,
      createdAt:
        authDirectoryDraft.users.find((user) => user.principalId === principalId)?.createdAt ?? timestamp,
      updatedAt: timestamp
    };
    setAuthDirectoryDraft((currentDirectory) => ({
      ...currentDirectory,
      users: [
        ...currentDirectory.users.filter((user) => user.principalId !== principalId),
        nextUser
      ]
    }));
    setAuthUserDraft(createEmptyAuthUserDraft());
    setActionFeedback({ text: `Queued directory user ${principalId}.`, tone: "info" });
  }

  function handleRemoveAuthUser(index: number) {
    setAuthDirectoryDraft((currentDirectory) => ({
      ...currentDirectory,
      users: currentDirectory.users.filter((_, userIndex) => userIndex !== index)
    }));
    setActionFeedback({ text: "Queued directory user removal.", tone: "info" });
  }

  function handleAddAuthWorkspace() {
    const workspaceId = authWorkspaceDraft.workspaceId.trim();
    const name = authWorkspaceDraft.name.trim();
    if (workspaceId.length === 0 || name.length === 0) {
      setActionFeedback({ text: "Directory workspace needs id and name.", tone: "error" });
      return;
    }

    const timestamp = new Date().toISOString();
    const nextWorkspace = {
      workspaceId,
      name,
      active: authWorkspaceDraft.active,
      createdAt:
        authDirectoryDraft.workspaces.find((workspace) => workspace.workspaceId === workspaceId)?.createdAt ?? timestamp,
      updatedAt: timestamp
    };
    setAuthDirectoryDraft((currentDirectory) => ({
      ...currentDirectory,
      workspaces: [
        ...currentDirectory.workspaces.filter((workspace) => workspace.workspaceId !== workspaceId),
        nextWorkspace
      ]
    }));
    setAuthWorkspaceDraft(createEmptyAuthWorkspaceDraft());
    setActionFeedback({ text: `Queued directory workspace ${workspaceId}.`, tone: "info" });
  }

  function handleRemoveAuthWorkspace(index: number) {
    setAuthDirectoryDraft((currentDirectory) => ({
      ...currentDirectory,
      workspaces: currentDirectory.workspaces.filter((_, workspaceIndex) => workspaceIndex !== index)
    }));
    setActionFeedback({ text: "Queued directory workspace removal.", tone: "info" });
  }

  async function handleSaveAuthPolicy() {
    if (gatewayBaseUrl.length > 0 && workspaceData.authPolicy === null) {
      setActionFeedback({ text: "Auth policy save blocked until gateway policy loads.", tone: "error" });
      return;
    }

    const nextPolicy: GatewayAuthPolicy = {
      ...authPolicyDraft,
      updatedAt: new Date().toISOString()
    };

    if (gatewayBaseUrl.length === 0) {
      setAuthPolicyDraft(nextPolicy);
      setActionFeedback({ text: "Demo auth policy changes stored locally.", tone: "demo" });
      return;
    }

    setIsSavingAuthPolicy(true);
    try {
      const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });
      const response = await gatewayClient.updateAuthPolicy(nextPolicy);
      setAuthPolicyDraft(response);
      setActionFeedback({ text: "Auth policy saved to gateway.", tone: "success" });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unable to save auth policy.";
      setActionFeedback({ text: `Auth policy save failed: ${message}`, tone: "error" });
    } finally {
      setIsSavingAuthPolicy(false);
    }
  }

  async function handleSaveAuthDirectory() {
    if (gatewayBaseUrl.length > 0 && workspaceData.authDirectory === null) {
      setActionFeedback({ text: "Auth directory save blocked until gateway directory loads.", tone: "error" });
      return;
    }

    const nextDirectory: GatewayAuthDirectory = {
      ...authDirectoryDraft,
      updatedAt: new Date().toISOString()
    };

    if (gatewayBaseUrl.length === 0) {
      setAuthDirectoryDraft(nextDirectory);
      setActionFeedback({ text: "Demo auth directory changes stored locally.", tone: "demo" });
      return;
    }

    setIsSavingAuthDirectory(true);
    try {
      const gatewayClient = createGatewayClient({ baseUrl: gatewayBaseUrl });
      const response = await gatewayClient.updateAuthDirectory(nextDirectory);
      setAuthDirectoryDraft(response);
      setActionFeedback({ text: "Auth directory saved to gateway.", tone: "success" });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unable to save auth directory.";
      setActionFeedback({ text: `Auth directory save failed: ${message}`, tone: "error" });
    } finally {
      setIsSavingAuthDirectory(false);
    }
  }

  function navigateToView(view: AppView) {
    const nextPath =
      view === "dashboard" && viewerDashboardId
        ? `${buildViewPath(view)}${buildDashboardViewerSearch(
            viewerDashboardId,
            viewerShareToken,
            viewerWorkspaceToken
          )}`
        : buildViewPath(view);
    setActiveView(view);
    if (typeof window !== "undefined") {
      window.history.pushState({}, "", nextPath);
    }
  }

  function openPublishedDashboard(dashboard: PublishedDashboardDefinition) {
    setViewerDashboardId(dashboard.dashboardId);
    setViewerShareToken(dashboard.shareToken ?? null);
    const workspaceToken =
      dashboard.visibility === "workspace" ? viewerWorkspaceToken ?? getConfiguredWorkspaceDashboardToken() : null;
    setViewerWorkspaceToken(workspaceToken);
    setViewerDashboard(dashboard);
    setActiveView("dashboard");
    if (typeof window !== "undefined") {
      window.history.pushState(
        {},
        "",
        `${buildViewPath("dashboard")}${buildDashboardViewerSearch(
          dashboard.dashboardId,
          dashboard.shareToken,
          workspaceToken
        )}`
      );
    }
  }

  const navigationItems: Array<{ id: AppView; label: string; note: string }> = [
    { id: "canvas", label: "Canvas", note: "Authoring-first workflow builder" },
    { id: "dashboard", label: "Dashboard", note: "Draft and published BI surfaces" },
    { id: "hub", label: "Hub", note: "Trust-aware extension lifecycle" },
    { id: "monitor", label: "Monitor", note: "Executions, workers, backbone" },
    { id: "settings", label: "Settings", note: "Delivery, theme, discovery" }
  ];

  return (
    <div className="product-shell">
      <aside className="product-sidebar">
        <div className="product-brand">
          <strong>JuliaFlow</strong>
          <span>Alpha platform shell</span>
        </div>
        <nav className="product-nav" aria-label="Primary">
          {navigationItems.map((item) => (
            <button
              aria-current={activeView === item.id ? "page" : undefined}
              className={`product-nav-item ${activeView === item.id ? "is-active" : ""}`}
              key={item.id}
              onClick={() => {
                navigateToView(item.id);
              }}
              type="button"
            >
              <strong>{item.label}</strong>
              <span>{item.note}</span>
            </button>
          ))}
        </nav>
        <div className="product-sidebar-footer">
          <span className={`source-pill is-${workspaceData.mode}`}>{workspaceData.dataSourceLabel}</span>
          <span className="hero-status-copy">Realtime {realtimeConnectionState}</span>
          <span className="hero-status-copy">{workflow.runtime?.runMode === "stream" ? "Streaming MVP" : "Batch mode"}</span>
        </div>
      </aside>

      <div className="product-frame">
        <header className="product-topbar">
          <div className="product-topbar-copy">
            <p className="eyebrow">JuliaFlow Alpha</p>
            <h1>
              {activeView === "canvas"
                ? "Workflow Canvas"
                : activeView === "dashboard"
                  ? "BI Workspace"
                  : activeView === "hub"
                    ? "Hub Marketplace"
                    : activeView === "monitor"
                      ? "Execution Monitor"
                      : "Platform Settings"}
            </h1>
            <p className="lede">
              {activeView === "canvas"
                ? "Authoring is primary. Repository, canvas, and inspector stay in one operational line of sight."
                : activeView === "dashboard"
                  ? "Draft dashboard authoring and published dashboard viewing now live in one dedicated surface."
                  : activeView === "hub"
                    ? "Compatibility, trust, and upgrade state are visible before lifecycle actions."
                    : activeView === "monitor"
                      ? "Runtime health, durable event backbone, and checkpoint evidence stay close to active executions."
                      : "Connection, route discovery, milestone context, and default publish behavior stay explicit."}
            </p>
          </div>
          <div className="product-topbar-actions">
            <label className="search-field">
              <span>Cross-view search</span>
              <input
                aria-label="Cross-view search"
                onChange={(event) => {
                  setQuery(event.target.value);
                }}
                placeholder="nodes, hub packages, roadmap, runtime..."
                type="search"
                value={query}
              />
            </label>
            <div className="workspace-header-status" aria-live="polite">
              <span className="hero-status-copy">{workflow.name}</span>
              <span className="hero-status-copy">{workflow.version}</span>
              {isDirty ? <span className="hero-status-copy">Unsaved draft changes</span> : null}
              {workspaceData.health ? (
                <span className="hero-status-copy">
                  {workspaceData.health.workflowCount} workflows · {workspaceData.health.executionCount} executions
                </span>
              ) : null}
              {workspaceData.error ? <span className="hero-status-copy">Fallback active: {workspaceData.error}</span> : null}
            </div>
          </div>
        </header>

        <main className="product-main">
          {activeView === "canvas" ? (
            <section className="workspace-main">
              <section className="workspace-stage panel">
                <div className="panel-inner workspace-stage-inner">
                  <div className="workspace-overview">
                    <div>
                      <p className="panel-kicker">Authoring</p>
                      <h2 className="workspace-title">{workflow.name}</h2>
                      <p className="panel-detail">
                        Typed graph editing, runtime-aware validation, and downstream BI handoff stay focused on build flow.
                      </p>
                    </div>
                    <div className="workspace-metrics">
                      <div className="metric-tile">
                        <span>Workflow nodes</span>
                        <strong>{workflow.nodes.length}</strong>
                      </div>
                      <div className="metric-tile">
                        <span>Connections</span>
                        <strong>{workflow.connections.length}</strong>
                      </div>
                      <div className="metric-tile">
                        <span>Validation gaps</span>
                        <strong>{unresolvedNodeCount}</strong>
                      </div>
                      <div className="metric-tile">
                        <span>Selected runtime</span>
                        <strong>{selectedNodeLayout?.runtime ?? "Configured"}</strong>
                      </div>
                    </div>
                  </div>

                  <div className="builder-grid builder-grid--fluid">
                    <aside className="repository-panel">
                      <div className="repository-header">
                        <div>
                          <p className="panel-kicker">Node library</p>
                          <h3>Insert + workflow assets</h3>
                        </div>
                        <span>{filteredRepositoryNodes.length} matches</span>
                      </div>

                      <div className="quick-add-panel">
                        <div className="quick-add-head">
                          <div>
                            <span>Quick insert</span>
                            <small>{quickAddNodes.length} starter actions</small>
                          </div>
                          <span>{repositoryFamilies.size} families</span>
                        </div>
                        <div className="quick-add-list">
                          {quickAddNodes.map((node) => (
                            <button
                              aria-label={`Add ${node.name} to workflow`}
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
                          <div>
                            <span>Flow variables</span>
                            <small>{workflow.flowVariables.length} scoped inputs</small>
                          </div>
                          <button className="secondary-action-button" onClick={handleAddFlowVariable} type="button">
                            Add flow variable
                          </button>
                        </div>
                        <div className="flow-variable-list">
                          {workflow.flowVariables.map((flowVariable, index) => (
                            <label className="flow-variable-chip" key={`${flowVariable.name}-${index}`}>
                              <strong>{flowVariable.name}</strong>
                              <input
                                aria-label={`Variable default ${flowVariable.name}`}
                                onChange={(event) => {
                                  const rawValue = event.target.value;
                                  handleFlowVariableChange(index, {
                                    default:
                                      flowVariable.type === "String"
                                        ? rawValue
                                        : parseNumericValue(rawValue, flowVariable.type)
                                  });
                                }}
                                type="text"
                                value={String(flowVariable.default ?? "")}
                              />
                              <button
                                className="danger-action-button"
                                onClick={() => {
                                  handleRemoveFlowVariable(index);
                                }}
                                type="button"
                              >
                                Remove
                              </button>
                            </label>
                          ))}
                        </div>
                      </div>

                      <div className="repository-list">
                        {groupedRepositoryNodes.length > 0 ? (
                          groupedRepositoryNodes.map(([groupLabel, nodes]) => (
                            <section className="repository-group" key={groupLabel}>
                              <div className="quick-add-head">
                                <div>
                                  <span>{groupLabel}</span>
                                  <small>{nodes.length} nodes</small>
                                </div>
                              </div>
                              <div className="repository-group-list">
                                {nodes.map((node) => (
                                  <RepositoryEntry
                                    key={node.type}
                                    node={node}
                                    onAdd={handleAddNode}
                                    selectedType={selectedNode.type}
                                  />
                                ))}
                              </div>
                            </section>
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
                          <button
                            className="secondary-action-button"
                            onClick={() => {
                              navigateToView("dashboard");
                            }}
                            type="button"
                          >
                            Open BI workspace
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

                      <div className="canvas-preview">
                        {workflow.connections.map((connection) => (
                          <CanvasConnection
                            connection={connection}
                            isActive={selectedSliceNodeIds.has(connection.sourceNodeId) && selectedSliceNodeIds.has(connection.targetNodeId)}
                            isDimmed={
                              normalizedNeedle.length > 0 &&
                              !(matchedNodeIds.has(connection.sourceNodeId) && matchedNodeIds.has(connection.targetNodeId))
                            }
                            key={`${connection.sourceNodeId}-${connection.sourcePortId}-${connection.targetNodeId}-${connection.targetPortId}`}
                            nodeLayouts={nodeLayouts}
                          />
                        ))}

                        {workflow.nodes.map((node) => (
                          <NodeCard
                            isDimmed={normalizedNeedle.length > 0 && !matchedNodeIds.has(node.id)}
                            isSelected={selectedNode.id === node.id}
                            key={node.id}
                            layout={nodeLayouts[node.id]}
                            node={node}
                            onDragStart={handleNodeDragStart}
                            onSelect={setSelectedNodeId}
                            selectedConnections={workflow.connections}
                          />
                        ))}
                      </div>
                    </section>

                    <aside className="inspector-panel">
                      <div className="repository-header">
                        <div>
                          <p className="panel-kicker">Inspector</p>
                          <h3>{selectedNode.name}</h3>
                        </div>
                        <StatusBadge label={selectedNodeLayout?.status ?? "configured"} />
                      </div>

                      <div className="inspector-tabs" role="tablist" aria-label="Inspector sections">
                        {(["config", "ports", "validation", "runtime"] as InspectorTab[]).map((tab) => (
                          <button
                            aria-selected={activeInspectorTab === tab}
                            className={`rail-tab ${activeInspectorTab === tab ? "is-active" : ""}`}
                            key={tab}
                            onClick={() => {
                              setActiveInspectorTab(tab);
                            }}
                            role="tab"
                            type="button"
                          >
                            {tab}
                          </button>
                        ))}
                      </div>

                      {activeInspectorTab === "config" ? (
                        <>
                          <div className="inspector-metrics">
                            <div className="inspector-block">
                              <span>Type</span>
                              <strong>{formatNodeType(selectedNode.type)}</strong>
                            </div>
                            <div className="inspector-block">
                              <span>Execution</span>
                              <strong>{selectedNode.executionHint}</strong>
                            </div>
                          </div>
                          <section className="inspector-section">
                            <div className="inspector-section-heading">
                              <strong>Node config</strong>
                              <span>{Object.keys(selectedNode.config).length} fields</span>
                            </div>
                            <div className="inspector-stack">
                              {Object.entries(selectedNode.config).map(([key, value]) => (
                                <div className="inspector-row" key={key}>
                                  <strong>{key}</strong>
                                  <span>{summarizeConfigValue(value)}</span>
                                </div>
                              ))}
                            </div>
                          </section>
                          <section className="inspector-section">
                            <div className="inspector-section-heading">
                              <strong>Connection editor</strong>
                              <span>{connectionPreview.label}</span>
                            </div>
                            <div className="connection-editor">
                              <label className="flow-variable-field">
                                <span>Connection direction</span>
                                <select
                                  aria-label="Connection direction"
                                  onChange={(event) => {
                                    setConnectionDraftDirection(event.target.value as ConnectionDraftDirection);
                                  }}
                                  value={connectionDraftDirection}
                                >
                                  <option value="outgoing">outgoing</option>
                                  <option value="incoming">incoming</option>
                                </select>
                              </label>
                              <label className="flow-variable-field">
                                <span>Connection peer node</span>
                                <select
                                  aria-label="Connection peer node"
                                  onChange={(event) => {
                                    setConnectionDraftPeerNodeId(event.target.value);
                                  }}
                                  value={selectedPeerNode?.id ?? ""}
                                >
                                  {peerNodes.map((node) => (
                                    <option key={node.id} value={node.id}>
                                      {node.name}
                                    </option>
                                  ))}
                                </select>
                              </label>
                              <label className="flow-variable-field">
                                <span>Connection anchor port</span>
                                <select
                                  aria-label="Connection anchor port"
                                  onChange={(event) => {
                                    setConnectionDraftAnchorPortId(event.target.value);
                                  }}
                                  value={connectionDraftAnchorPortId}
                                >
                                  {anchorPorts.map((port) => (
                                    <option key={port.id} value={port.id}>
                                      {port.id}
                                    </option>
                                  ))}
                                </select>
                              </label>
                              <label className="flow-variable-field">
                                <span>Connection peer port</span>
                                <select
                                  aria-label="Connection peer port"
                                  onChange={(event) => {
                                    setConnectionDraftPeerPortId(event.target.value);
                                  }}
                                  value={connectionDraftPeerPortId}
                                >
                                  {peerPorts.map((port) => (
                                    <option key={port.id} value={port.id}>
                                      {port.id}
                                    </option>
                                  ))}
                                </select>
                              </label>
                              <div className="connection-editor-actions">
                                <button className="secondary-action-button" onClick={handleAddConnection} type="button">
                                  Add connection
                                </button>
                              </div>
                              <div className={`validation-item is-${connectionPreview.tone}`}>
                                <strong>{connectionPreview.label}</strong>
                                <span>{connectionPreview.detail}</span>
                              </div>
                            </div>
                          </section>
                        </>
                      ) : null}

                      {activeInspectorTab === "ports" ? (
                        <>
                          <section className="inspector-section">
                            <div className="inspector-section-heading">
                              <strong>Ports</strong>
                              <span>{selectedNode.ports.length} typed links</span>
                            </div>
                            <div className="inspector-stack">
                              {selectedNode.ports.map((port) => (
                                <PortSchema connections={workflow.connections} key={port.id} node={selectedNode} port={port} />
                              ))}
                            </div>
                          </section>
                          <section className="inspector-section">
                            <div className="inspector-section-heading">
                              <strong>Connections</strong>
                              <span>{relatedConnections.length} linked edges</span>
                            </div>
                            <div className="connection-list">
                              {relatedConnections.map((connection) => (
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
                              ))}
                            </div>
                          </section>
                        </>
                      ) : null}

                      {activeInspectorTab === "validation" ? (
                        <section className="inspector-section">
                          <div className="inspector-section-heading">
                            <strong>Validation + sample</strong>
                            <span>{selectedNodeLayout?.runtime ?? "Configured"}</span>
                          </div>
                          <div className="validation-list">
                            {validationItems.map((item) => (
                              <div className={`validation-item is-${item.tone}`} key={item.label}>
                                <strong>{item.label}</strong>
                                <span>{item.detail}</span>
                              </div>
                            ))}
                          </div>
                          <div className="sample-output">
                            <strong>Sample output</strong>
                            <span>{sampleOutput}</span>
                          </div>
                          <div className="sample-output">
                            <strong>Components/control-flow</strong>
                            <span>
                              {selectedContainers.length + selectedComponents.length + selectedControlFlow.length} metadata bindings
                            </span>
                          </div>
                          <div className="validation-list">
                            {selectedContainers.map((container) => (
                              <div className="validation-item is-good" key={container.containerId}>
                                <strong>{container.name}</strong>
                                <span>Container / {container.nodeIds.length} nodes</span>
                              </div>
                            ))}
                            {selectedComponents.map((component) => (
                              <div className="validation-item is-good" key={component.componentId}>
                                <strong>{component.name}</strong>
                                <span>Component / {component.flowVariableScope} variables</span>
                              </div>
                            ))}
                            {selectedControlFlow.map((controlFlow) => (
                              <div className="validation-item is-good" key={controlFlow.controlId}>
                                <strong>{controlFlow.name ?? controlFlow.controlId}</strong>
                                <span>{controlFlow.kind}: {describeControlFlow(controlFlow)}</span>
                              </div>
                            ))}
                          </div>
                        </section>
                      ) : null}

                      {activeInspectorTab === "runtime" ? (
                        <>
                          <section className="inspector-section">
                            <div className="inspector-section-heading">
                              <strong>Selected runtime</strong>
                              <span>{selectedNodeLayout?.status ?? "configured"}</span>
                            </div>
                            <div className="inspector-stack">
                              <div className="inspector-row">
                                <strong>Runtime label</strong>
                                <span>{selectedNodeLayout?.runtime ?? "Configured"}</span>
                              </div>
                              <div className="inspector-row">
                                <strong>Latest execution</strong>
                                <span>{latestExecution ? latestExecution.id : "No runs yet"}</span>
                              </div>
                              <div className="inspector-row">
                                <strong>Realtime</strong>
                                <span>{realtimeConnectionState}</span>
                              </div>
                              {workspaceData.health ? (
                                <div className="inspector-row">
                                  <strong>Backbone</strong>
                                  <span>{workspaceData.health.eventBackboneMode}</span>
                                </div>
                              ) : null}
                            </div>
                          </section>
                        </>
                      ) : null}
                    </aside>
                  </div>
                </div>
              </section>
            </section>
          ) : null}

          {activeView === "dashboard" ? (
            <section className="workspace-main">
              <section className="workspace-stage panel">
                <div className="panel-inner workspace-stage-inner">
                  <div className="workspace-overview">
                    <div>
                      <p className="panel-kicker">BI workspace</p>
                      <h2 className="workspace-title">{primaryDashboard?.name ?? "No dashboard draft yet"}</h2>
                      <p className="panel-detail">
                        Draft authoring stays editable while published snapshots remain read-only and shareable.
                      </p>
                    </div>
                    <div className="quick-add-list">
                      <button className="secondary-action-button" onClick={handleCreateDashboard} type="button">
                        Create dashboard
                      </button>
                      <button className="secondary-action-button" onClick={handleDuplicateDashboard} type="button">
                        Duplicate dashboard
                      </button>
                      <button
                        className="danger-action-button"
                        disabled={dashboards.length <= 1}
                        onClick={handleRemoveDashboard}
                        type="button"
                      >
                        Remove dashboard
                      </button>
                      <label className="flow-variable-field flow-variable-field--inline">
                        <span>Publish visibility</span>
                        <select
                          aria-label="Publish visibility"
                          onChange={(event) => {
                            setPublishVisibility(event.target.value as "workspace" | "public");
                          }}
                          value={publishVisibility}
                        >
                          <option value="workspace">workspace</option>
                          <option value="public">public</option>
                        </select>
                      </label>
                      <button className="secondary-action-button" onClick={() => { void handlePublishDashboard(); }} type="button">
                        Publish
                      </button>
                      <button
                        className="secondary-action-button"
                        disabled={!viewerDashboard}
                        onClick={() => {
                          void handleCopyDashboardShareLink();
                        }}
                        type="button"
                      >
                        Copy share link
                      </button>
                    </div>
                  </div>
                  {actionFeedback ? (
                    <div className={`canvas-action-feedback is-${actionFeedback.tone}`} role="status">
                      {actionFeedback.text}
                    </div>
                  ) : null}
                </div>
              </section>

              <section className="secondary-grid dashboard-grid">
                <Panel className="rail-panel">
                  <SectionTitle
                    kicker="Drafts"
                    title="Draft dashboards"
                    detail="Switch between workflow-bound dashboard drafts and edit one at a time."
                  />
                  {dashboards.length > 0 ? (
                    <div className="route-card-list">
                      {dashboards.map((dashboard) => (
                        <button
                          className={`route-list-item ${dashboard.dashboardId === primaryDashboard?.dashboardId ? "is-active" : ""}`}
                          key={dashboard.dashboardId}
                          onClick={() => {
                            setActiveDashboardId(dashboard.dashboardId);
                          }}
                          type="button"
                        >
                          <strong>{dashboard.name}</strong>
                          <span>{dashboard.dashboardId}</span>
                        </button>
                      ))}
                    </div>
                  ) : (
                    <div className="repository-empty">
                      <strong>No dashboard definitions attached yet.</strong>
                      <span>Create first dashboard to start authoring BI layouts.</span>
                    </div>
                  )}

                  {primaryDashboard ? (
                    <div className="dashboard-editor">
                      <label className="flow-variable-field">
                        <span>Dashboard name</span>
                        <input
                          aria-label="Dashboard name"
                          onChange={(event) => {
                            handleDashboardChange({ name: event.target.value });
                          }}
                          type="text"
                          value={primaryDashboard.name}
                        />
                      </label>
                      <label className="flow-variable-field">
                        <span>Outlet node</span>
                        <select
                          aria-label="Dashboard outlet node"
                          onChange={(event) => {
                            handleDashboardBindingChange({ outletNodeId: event.target.value });
                          }}
                          value={primaryDashboard.binding.outletNodeId}
                        >
                          {workflow.nodes
                            .filter(
                              (node) =>
                                node.type === "bi.outlet" ||
                                node.ports.some(
                                  (port) => port.direction === "output" && port.type === "stream_channel"
                                )
                            )
                            .map((node) => (
                              <option key={node.id} value={node.id}>
                                {node.name}
                              </option>
                            ))}
                        </select>
                      </label>
                      <label className="flow-variable-field">
                        <span>Dataset key</span>
                        <input
                          aria-label="Dashboard dataset key"
                          onChange={(event) => {
                            handleDashboardBindingChange({ datasetKey: event.target.value });
                          }}
                          type="text"
                          value={primaryDashboard.binding.datasetKey}
                        />
                      </label>
                      <label className="flow-variable-field">
                        <span>Refresh mode</span>
                        <select
                          aria-label="Dashboard refresh mode"
                          onChange={(event) => {
                            handleDashboardBindingChange({
                              refreshMode: event.target.value as DashboardDefinition["binding"]["refreshMode"]
                            });
                          }}
                          value={primaryDashboard.binding.refreshMode}
                        >
                          <option value="manual">manual</option>
                          <option value="live">live</option>
                        </select>
                      </label>
                      <div className="quick-add-list">
                        <button className="secondary-action-button" onClick={handleAddDashboardChart} type="button">
                          Add chart
                        </button>
                      </div>
                      <div className="connection-list">
                        {primaryDashboard.charts.map((chart) => (
                          <div className="flow-variable-editor" key={chart.chartId}>
                            <div className="flow-variable-editor-head">
                              <strong>{chart.chartId}</strong>
                              <button
                                aria-label={`Remove ${chart.chartId}`}
                                className="danger-action-button"
                                disabled={primaryDashboard.charts.length <= 1}
                                onClick={() => {
                                  handleRemoveDashboardChart(chart.chartId);
                                }}
                                type="button"
                              >
                                Remove
                              </button>
                            </div>
                            <label className="flow-variable-field">
                              <span>Chart title</span>
                              <input
                                aria-label={`Chart title ${chart.chartId}`}
                                onChange={(event) => {
                                  handleDashboardChartChange(chart.chartId, { title: event.target.value });
                                }}
                                type="text"
                                value={chart.title}
                              />
                            </label>
                            <label className="flow-variable-field">
                              <span>Chart family</span>
                              <select
                                aria-label={`Chart family ${chart.chartId}`}
                                onChange={(event) => {
                                  handleDashboardChartChange(chart.chartId, {
                                    family: event.target.value as DashboardChartFamily
                                  });
                                }}
                                value={chart.family}
                              >
                                {dashboardChartFamilies.map((family) => (
                                  <option key={family} value={family}>
                                    {family}
                                  </option>
                                ))}
                              </select>
                            </label>
                            <label className="flow-variable-field">
                              <span>X field</span>
                              <input
                                aria-label={`Chart x field ${chart.chartId}`}
                                onChange={(event) => {
                                  handleDashboardChartChange(chart.chartId, { xField: event.target.value });
                                }}
                                type="text"
                                value={chart.xField ?? ""}
                              />
                            </label>
                            <label className="flow-variable-field">
                              <span>Y field</span>
                              <input
                                aria-label={`Chart y field ${chart.chartId}`}
                                onChange={(event) => {
                                  handleDashboardChartChange(chart.chartId, { yField: event.target.value });
                                }}
                                type="text"
                                value={chart.yField ?? ""}
                              />
                            </label>
                            <div className="inspector-row">
                              <strong>Panel</strong>
                              <span>
                                {chart.panel
                                  ? `x:${chart.panel.x} y:${chart.panel.y} w:${chart.panel.w} h:${chart.panel.h}`
                                  : "unplaced"}
                              </span>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  ) : null}
                </Panel>

                <Panel className="phase-panel">
                  <SectionTitle
                    kicker="Published"
                    title="Published dashboards"
                    detail="Viewer deep links stay backward-compatible while snapshots remain separate from draft edits."
                  />
                  {publishedDashboards.length > 0 ? (
                    <div className="route-card-list">
                      {publishedDashboards.map((dashboard) => (
                        <button
                          className={`route-list-item ${viewerDashboardId === dashboard.dashboardId ? "is-active" : ""}`}
                          key={dashboard.dashboardId}
                          onClick={() => {
                            openPublishedDashboard(dashboard);
                          }}
                          type="button"
                        >
                          <strong>{dashboard.name}</strong>
                          <span>v{dashboard.version} · {dashboard.visibility}</span>
                        </button>
                      ))}
                    </div>
                  ) : (
                    <div className="repository-empty">
                      <strong>No published dashboards yet.</strong>
                      <span>Publish a draft to create a read-only snapshot and share link.</span>
                    </div>
                  )}

                  {viewerDashboard ? (
                    <div className="published-dashboard-viewer">
                      <div className="rail-spotlight">
                        <div className="rail-spotlight-copy">
                          <span>Published dashboard</span>
                          <strong>{viewerDashboard.name}</strong>
                          <p>
                            v{viewerDashboard.version} · {viewerDashboard.publishedAt} · {viewerDashboard.visibility}
                          </p>
                        </div>
                        <div className="quick-add-list">
                          <StatusBadge label="read_only" />
                          <button className="secondary-action-button" onClick={handleCloseDashboardViewer} type="button">
                            Clear viewer
                          </button>
                        </div>
                      </div>
                      <div className="inspector-stack">
                        <div className="inspector-row">
                          <strong>Dashboard</strong>
                          <span>{viewerDashboard.dashboardId}</span>
                        </div>
                        <div className="inspector-row">
                          <strong>Dataset</strong>
                          <span>{viewerDashboard.binding.datasetKey}</span>
                        </div>
                        <div className="inspector-row">
                          <strong>Refresh mode</strong>
                          <span>{viewerDashboard.binding.refreshMode}</span>
                        </div>
                        <div className="inspector-row">
                          <strong>Share token</strong>
                          <span>{viewerDashboard.shareToken ?? "workspace only"}</span>
                        </div>
                        <div className="repository-detail-actions">
                          <button className="secondary-action-button" onClick={handleRefreshViewerCharts} type="button">
                            {isViewerRefreshing ? "Refreshing…" : "Refresh charts"}
                          </button>
                          {viewerChartFilter ? (
                            <button
                              className="secondary-action-button"
                              onClick={() => {
                                setViewerChartFilter(null);
                                setViewerChartDrilldown(null);
                              }}
                              type="button"
                            >
                              Clear filter {viewerChartFilter.field}={viewerChartFilter.value}
                            </button>
                          ) : null}
                          {viewerRowSearch.trim().length > 0 ? (
                            <button
                              className="secondary-action-button"
                              onClick={() => {
                                setViewerRowSearch("");
                                setViewerChartDrilldown(null);
                              }}
                              type="button"
                            >
                              Clear row search
                            </button>
                          ) : null}
                        </div>
                        <label className="search-field">
                          <span>Viewer row search</span>
                          <input
                            aria-label="Search published dashboard rows"
                            onChange={(event) => {
                              setViewerRowSearch(event.target.value);
                              setViewerChartDrilldown(null);
                            }}
                            placeholder="filter visible rows..."
                            type="search"
                            value={viewerRowSearch}
                          />
                        </label>
                        <div className="inspector-row">
                          <strong>Selection</strong>
                          <span>{viewerChartFilter ? `${viewerChartFilter.field}=${viewerChartFilter.value}` : "all rows"}</span>
                        </div>
                        <div className="inspector-row">
                          <strong>Row search</strong>
                          <span>{viewerRowSearch.trim().length > 0 ? viewerRowSearch.trim() : "none"}</span>
                        </div>
                        <div className="inspector-row">
                          <strong>Drilldown</strong>
                          <span>{viewerChartDrilldown ? `${viewerChartDrilldown.chartTitle} row ${viewerChartDrilldown.rowIndex + 1}` : "no row selected"}</span>
                        </div>
                      </div>
                      {viewerChartDrilldown ? (
                        <div className="flow-variable-editor" aria-label="Published chart drilldown">
                          <div className="flow-variable-editor-head">
                            <strong>Drilldown: {viewerChartDrilldown.chartTitle}</strong>
                            <StatusBadge label={`row_${viewerChartDrilldown.rowIndex + 1}`} />
                          </div>
                          <div className="repository-detail-actions">
                            <button
                              className="secondary-action-button"
                              onClick={() => {
                                void handleExportDrilldownJson();
                              }}
                              type="button"
                            >
                              Copy selected row JSON
                            </button>
                          </div>
                          <div className="inspector-stack">
                            <div className="inspector-row">
                              <strong>Active filter</strong>
                              <span>{viewerChartDrilldown.filter ? `${viewerChartDrilldown.filter.field}=${viewerChartDrilldown.filter.value}` : "none"}</span>
                            </div>
                            <div className="inspector-row">
                              <strong>Matching rows</strong>
                              <span>{viewerChartDrilldown.matchingRowCount}</span>
                            </div>
                            {Object.entries(viewerChartDrilldown.row).map(([field, value]) => (
                              <div className="inspector-row" key={`${viewerChartDrilldown.chartId}-${field}`}>
                                <strong>{field}</strong>
                                <span>{String(value ?? "-")}</span>
                              </div>
                            ))}
                          </div>
                        </div>
                      ) : null}
                      <div className="flow-variable-editor-list">
                        {viewerDashboard.charts.map((chart) => {
                          const chartData = dashboardChartData[chart.chartId];
                          const filteredChartData = chartData
                            ? applyViewerChartView(chartData, viewerChartFilter, viewerRowSearch)
                            : undefined;
                          return (
                            <article className="flow-variable-editor" key={chart.chartId}>
                              <div className="flow-variable-editor-head">
                                <strong>{chart.title}</strong>
                                <StatusBadge label={chart.family} />
                              </div>
                              <div className="repository-detail-actions">
                                <button
                                  className="secondary-action-button"
                                  onClick={() => {
                                    void handleExportDashboardChart(chart.chartId, "filtered");
                                  }}
                                  type="button"
                                >
                                  Export filtered CSV
                                </button>
                                <button
                                  className="secondary-action-button"
                                  onClick={() => {
                                    void handleExportDashboardChart(chart.chartId, "full");
                                  }}
                                  type="button"
                                >
                                  Export all CSV
                                </button>
                              </div>
                              <div className="inspector-stack">
                                <div className="inspector-row">
                                  <strong>Chart</strong>
                                  <span>{chart.chartId}</span>
                                </div>
                                <div className="inspector-row">
                                  <strong>Family</strong>
                                  <span>{chart.family}</span>
                                </div>
                                <div className="inspector-row">
                                  <strong>Rows</strong>
                                  <span>{filteredChartData?.rowCount ?? "pending"}</span>
                                </div>
                                <div className="inspector-row">
                                  <strong>Fields</strong>
                                  <span>{filteredChartData?.fields.join(", ") ?? "pending"}</span>
                                </div>
                                <div className="inspector-row">
                                  <strong>Semantic</strong>
                                  <span>
                                    {filteredChartData
                                      ? `${filteredChartData.semantic.dimensions.join(" / ")} · ${filteredChartData.semantic.measures.join(" / ")}`
                                      : "pending"}
                                  </span>
                                </div>
                                <div className="inspector-row">
                                  <strong>Refresh</strong>
                                  <span>{chartRefreshSummary(filteredChartData)}</span>
                                </div>
                              </div>
                              {renderPublishedChartPreview(
                                chart,
                                filteredChartData,
                                viewerChartFilter,
                                setViewerChartFilter,
                                (row, rowIndex, filter, matchingRowCount) => {
                                  setViewerChartDrilldown({
                                    chartId: chart.chartId,
                                    chartTitle: chart.title,
                                    filter,
                                    matchingRowCount,
                                    row,
                                    rowIndex
                                  });
                                }
                              )}
                            </article>
                          );
                        })}
                      </div>
                    </div>
                  ) : null}
                </Panel>
              </section>
            </section>
          ) : null}

          {activeView === "hub" ? (
            <section className="workspace-main">
              <section className="workspace-stage panel">
                <div className="panel-inner workspace-stage-inner">
                  <div className="workspace-overview">
                    <div>
                      <p className="panel-kicker">Hub</p>
                      <h2 className="workspace-title">Extension marketplace</h2>
                      <p className="panel-detail">
                        Trust, compatibility, artifact hashes, sandbox commands, mirrors, and lifecycle actions are surfaced before installation.
                      </p>
                      <button
                        className="secondary-action-button"
                        onClick={() => {
                          void handleHubPublishSample();
                        }}
                        type="button"
                      >
                        Publish sample extension
                      </button>
                    </div>
                    <div className="workspace-metrics">
                      <div className="metric-tile">
                        <span>Visible extensions</span>
                        <strong>{filteredHubExtensions.length}</strong>
                      </div>
                      <div className="metric-tile">
                        <span>Trusted</span>
                        <strong>{hubExtensions.filter((item) => getHubTrust(item).trusted).length}</strong>
                      </div>
                      <div className="metric-tile">
                        <span>Upgrade ready</span>
                        <strong>{hubExtensions.filter((item) => getHubUpgrade(item).upgradeAvailable).length}</strong>
                      </div>
                      <div className="metric-tile">
                        <span>Blocked</span>
                        <strong>{hubExtensions.filter((item) => item.compatibility.blockers.length > 0 || getHubTrust(item).blockers.length > 0).length}</strong>
                      </div>
                    </div>
                  </div>
                  {actionFeedback ? (
                    <div className={`canvas-action-feedback is-${actionFeedback.tone}`} role="status">
                      {actionFeedback.text}
                    </div>
                  ) : null}
                </div>
              </section>

              <section className="hub-grid">
                {filteredHubExtensions.map((extension) => (
                  <article className="hub-card" key={extension.extensionId}>
                    <div className="hub-card-head">
                      <div>
                        <strong>{extension.manifest.name}</strong>
                        <span>{extension.manifest.publisherIdentity}</span>
                      </div>
                      <StatusBadge label={extension.installState} />
                    </div>
                    <p>{extension.manifest.summary}</p>
                    <div className="connection-tags">
                      {extension.manifest.tags.map((tag) => (
                        <span className="flow-variable-chip" key={tag}>
                          {tag}
                        </span>
                      ))}
                    </div>
                    <div className="inspector-stack">
                      <div className="inspector-row">
                        <strong>Version</strong>
                        <span>{extension.manifest.version}</span>
                      </div>
                      <div className="inspector-row">
                        <strong>Package ref</strong>
                        <span>{extension.manifest.packageRef}</span>
                      </div>
                      <div className="inspector-row">
                        <strong>Release notes</strong>
                        <span>{extension.manifest.releaseNotesRef ?? "not provided"}</span>
                      </div>
                      <div className="inspector-row">
                        <strong>Artifact hashes</strong>
                        <span>
                          {Object.entries(extension.manifest.artifactHashes ?? {})
                            .map(([artifact, hash]) => `${artifact}=${hash}`)
                            .join("; ") || "not provided"}
                        </span>
                      </div>
                      <div className="inspector-row">
                        <strong>Sandbox command</strong>
                        <span>{extension.manifest.compatibilitySandboxCommand ?? "not provided"}</span>
                      </div>
                      <div className="inspector-row">
                        <strong>Mirror refs</strong>
                        <span>{(extension.manifest.mirrorRefs ?? []).join("; ") || "not provided"}</span>
                      </div>
                      <div className="inspector-row">
                        <strong>Trust</strong>
                        <span>{getHubTrust(extension).level}</span>
                      </div>
                      <div className="inspector-row">
                        <strong>Latest version</strong>
                        <span>{getHubUpgrade(extension).latestVersion}</span>
                      </div>
                      <div className="inspector-row">
                        <strong>Installed version</strong>
                        <span>{getHubUpgrade(extension).installedVersion ?? "not installed"}</span>
                      </div>
                      <div className="inspector-row">
                        <strong>Verification</strong>
                        <span>
                          {extension.verification.verified ? "verified" : "blocked/pending"} · sandbox{" "}
                          {extension.verification.sandbox.status} · artifacts {extension.verification.artifacts.status} ·
                          mirrors {extension.verification.mirrors.status}
                        </span>
                      </div>
                      <div className="inspector-row">
                        <strong>Verification details</strong>
                        <span>
                          {extension.verification.sandbox.details} · {extension.verification.artifacts.details} ·{" "}
                          {extension.verification.mirrors.details}
                        </span>
                      </div>
                      {extension.compatibility.blockers.length > 0 ? (
                        <div className="inspector-row">
                          <strong>Compatibility blockers</strong>
                          <span>{extension.compatibility.blockers.join("; ")}</span>
                        </div>
                      ) : null}
                      {getHubTrust(extension).blockers.length > 0 ? (
                        <div className="inspector-row">
                          <strong>Trust blockers</strong>
                          <span>{getHubTrust(extension).blockers.join("; ")}</span>
                        </div>
                      ) : null}
                      {extension.verification.blockers.length > 0 ? (
                        <div className="inspector-row">
                          <strong>Verification blockers</strong>
                          <span>{extension.verification.blockers.join("; ")}</span>
                        </div>
                      ) : null}
                    </div>
                    <div className="hub-card-actions">
                      <button
                        className="secondary-action-button"
                        disabled={hubActionBlocked(extension)}
                        onClick={() => {
                          void handleHubInstall(extension);
                        }}
                        type="button"
                      >
                        {hubActionBlocked(extension)
                          ? "Blocked"
                          : getHubUpgrade(extension).upgradeAvailable
                            ? "Upgrade"
                            : extension.installState === "enabled"
                              ? "Disable"
                              : extension.installState === "available"
                                ? "Install"
                                : "Enable"}
                      </button>
                    </div>
                  </article>
                ))}
              </section>
            </section>
          ) : null}

          {activeView === "monitor" ? (
            <section className="workspace-main">
              <section className="workspace-stage panel">
                <div className="panel-inner workspace-stage-inner">
                  <div className="workspace-overview">
                    <div>
                      <p className="panel-kicker">Runtime</p>
                      <h2 className="workspace-title">Executions + backbone</h2>
                      <p className="panel-detail">
                        Worker lanes, consumer settings, queue evidence, and checkpoint state stay visible in one monitor view.
                      </p>
                    </div>
                    <div className="workspace-metrics">
                      {statusCounts.map((item) => (
                        <div className="metric-tile" key={item.label}>
                          <span>{item.label}</span>
                          <strong>{item.count}</strong>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </section>

              <section className="monitor-grid">
                <Panel className="rail-panel">
                  <SectionTitle
                    kicker="Discovery"
                    title="Transport + worker modes"
                    detail="Health endpoint now exposes realtime transport, durable backbone mode, consumer poll, and worker lanes."
                  />
                  <div className="inspector-stack">
                    <div className="inspector-row">
                      <strong>Repository backend</strong>
                      <span>{workspaceData.health?.repositoryBackend ?? workspaceData.mode}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Realtime transport</strong>
                      <span>{workspaceData.health?.realtimeTransport ?? "jsonrpc_websocket"}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Event backbone</strong>
                      <span>{workspaceData.health?.eventBackboneMode ?? "dual_write"}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Consumer poll</strong>
                      <span>{workspaceData.health?.eventConsumerPollMs ?? 250} ms</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Stream worker</strong>
                      <span>{workspaceData.health?.streamWorkerMode ?? "inline"}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>GPU worker</strong>
                      <span>{workspaceData.health?.gpuWorkerMode ?? "process"}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Event log entries</strong>
                      <span>{workspaceData.health?.eventLogSize ?? 0}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Latest event sequence</strong>
                      <span>{workspaceData.health?.latestEventSequence ?? 0}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Gateway cursor</strong>
                      <span>{workspaceData.health?.gatewayConsumerCursor ?? 0}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Consumer lag</strong>
                      <span>{workspaceData.health?.gatewayConsumerLag ?? 0}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Consumer catch-up</strong>
                      <span>{workspaceData.health?.eventConsumerCatchupPercent ?? 0}%</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Active streams</strong>
                      <span>{workspaceData.health?.activeStreamExecutions ?? 0}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Queued GPU executions</strong>
                      <span>{workspaceData.health?.queuedGpuExecutions ?? 0}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Queued stream executions</strong>
                      <span>{workspaceData.health?.queuedStreamExecutions ?? 0}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Active GPU executions</strong>
                      <span>{workspaceData.health?.activeGpuExecutions ?? 0}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>GPU worker-owned executions</strong>
                      <span>{workspaceData.health?.gpuWorkerOwnedExecutions ?? 0}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Total queued executions</strong>
                      <span>{workspaceData.health?.queuedExecutionsTotal ?? 0}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Total running executions</strong>
                      <span>{workspaceData.health?.runningExecutionsTotal ?? 0}</span>
                    </div>
                  </div>
                </Panel>

                <Panel className="rail-panel">
                  <SectionTitle
                    kicker="Executions"
                    title="Active and recent runs"
                    detail="Runtime evidence moved out of canvas and into dedicated monitor context."
                  />
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
                          {item.controlFlowPlan && item.controlFlowPlan.length > 0 ? (
                            <div className="inspector-stack" aria-label={`Control-flow runtime plan ${item.id}`}>
                              {item.controlFlowPlan.map((controlPlan) => (
                                <div className="inspector-row" key={controlPlan.controlId}>
                                  <strong>{controlPlan.controlId}</strong>
                                  {controlPlan.kind === "loop" ? (
                                    <span>
                                      {controlPlan.kind} · {controlPlan.iterationMode} · max {controlPlan.maxIterations} ·{" "}
                                      {controlPlan.bodyNodeIds.length} nodes
                                    </span>
                                  ) : (
                                    <span>
                                      {controlPlan.kind} · {controlPlan.tryNodeIds.length} try nodes ·{" "}
                                      {controlPlan.catchNodeIds.length} catch nodes
                                    </span>
                                  )}
                                </div>
                              ))}
                            </div>
                          ) : null}
                          {item.controlFlowRecovery ? (
                            <div className="inspector-row">
                              <strong>Recovery</strong>
                              <span>
                                {item.controlFlowRecovery.status} · {item.controlFlowRecovery.failedNodeId} via{" "}
                                {item.controlFlowRecovery.controlId} · {item.controlFlowRecovery.catchNodeIds.length} catch nodes
                              </span>
                            </div>
                          ) : null}
                          {item.controlFlowBranchState ? (
                            <div className="inspector-row">
                              <strong>Branch</strong>
                              <span>
                                {item.controlFlowBranchState.branch} {item.controlFlowBranchState.status} ·{" "}
                                {item.controlFlowBranchState.completedNodeIds.length} catch nodes ·{" "}
                                {item.controlFlowBranchState.workerId}
                                {item.controlFlowBranchState.branchStageCount ? (
                                  <>
                                    {" "}
                                    · stage {item.controlFlowBranchState.branchStageIndex ?? 0}/
                                    {item.controlFlowBranchState.branchStageCount} · active{" "}
                                    {item.controlFlowBranchState.activeNodeIds.length}
                                  </>
                                ) : null}
                              </span>
                            </div>
                          ) : null}
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
                </Panel>

                <Panel className="phase-panel">
                  <SectionTitle
                    kicker="Published artifacts"
                    title="Dashboards + extensions"
                    detail="Artifact surfaces visible next to runtime so operators can trace publish and upgrade state."
                  />
                  <div className="route-card-list">
                    {publishedDashboards.map((dashboard) => (
                      <div className="route-list-item" key={dashboard.dashboardId}>
                        <strong>{dashboard.name}</strong>
                        <span>dashboard · v{dashboard.version} · {dashboard.visibility}</span>
                      </div>
                    ))}
                    {hubExtensions.map((extension) => (
                      <div className="route-list-item" key={extension.extensionId}>
                        <strong>{extension.manifest.name}</strong>
                        <span>{extension.installState} · {getHubUpgrade(extension).latestVersion}</span>
                      </div>
                    ))}
                  </div>
                </Panel>
              </section>
            </section>
          ) : null}

          {activeView === "settings" ? (
            <section className="workspace-main">
              <section className="settings-grid">
                <Panel className="rail-panel">
                  <SectionTitle
                    kicker="Platform"
                    title="Connection + theme defaults"
                    detail="Calmer token system, route shell, and discovery metadata now have one settings surface."
                  />
                  <div className="inspector-stack">
                    <div className="inspector-row">
                      <strong>Theme baseline</strong>
                      <span>Calmer dark, light-ready tokens</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Publish default</strong>
                      <span>{publishVisibility}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Realtime state</strong>
                      <span>{realtimeConnectionState}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Current route</strong>
                      <span>{buildViewPath(activeView)}</span>
                    </div>
                  </div>
                </Panel>

                <Panel className="rail-panel">
                  <SectionTitle
                    kicker="Security admin"
                    title="Policy + audit management"
                    detail="Editable admin draft proves persisted role/resource policies can be changed while audit queries stay redacted."
                  />
                  {workspaceData.authAdminError ? (
                    <div className="repository-empty">
                      <span>Auth admin API unavailable: {workspaceData.authAdminError}</span>
                    </div>
                  ) : null}
                  {actionFeedback ? (
                    <div className={`canvas-action-feedback is-${actionFeedback.tone}`} role="status">
                      {actionFeedback.text}
                    </div>
                  ) : null}
                  <div className="inspector-stack">
                    <div className="inspector-row">
                      <strong>Auth mode</strong>
                      <span>{workspaceData.health?.authMode ?? "demo"}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>OIDC discovery</strong>
                      <span>{workspaceData.health?.oidcDiscoveryConfigured ? "configured" : "not configured"}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>OIDC JWKS</strong>
                      <span>{workspaceData.health?.oidcJwksConfigured ? "configured" : "not configured"}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Allowed algorithms</strong>
                      <span>{workspaceData.health?.oidcAllowedAlgorithms?.join(", ") ?? "HS256"}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Role bindings</strong>
                      <span>{authPolicyDraft.roleBindings.length}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Directory users</strong>
                      <span>{authDirectoryDraft.users.length}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Directory workspaces</strong>
                      <span>{authDirectoryDraft.workspaces.length}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Resource policies</strong>
                      <span>{authPolicyDraft.resourcePolicies.length}</span>
                    </div>
                    <div className="inspector-row">
                      <strong>Policy updated</strong>
                      <span>{authPolicyDraft.updatedAt}</span>
                    </div>
                  </div>

                  <div className="checkpoint-policy">
                    <h2>User/workspace directory</h2>
                    <div className="route-card-list">
                      {authDirectoryDraft.users.slice(0, 6).map((user, index) => (
                        <div className="route-list-item" key={user.principalId}>
                          <strong>{user.principalId}</strong>
                          <span>{user.displayName} · {user.active ? "active" : "disabled"}</span>
                          <button
                            className="danger-action-button"
                            onClick={() => {
                              handleRemoveAuthUser(index);
                            }}
                            type="button"
                          >
                            Remove directory user
                          </button>
                        </div>
                      ))}
                      {authDirectoryDraft.workspaces.slice(0, 6).map((workspace, index) => (
                        <div className="route-list-item" key={workspace.workspaceId}>
                          <strong>{workspace.workspaceId}</strong>
                          <span>{workspace.name} · {workspace.active ? "active" : "disabled"}</span>
                          <button
                            className="danger-action-button"
                            onClick={() => {
                              handleRemoveAuthWorkspace(index);
                            }}
                            type="button"
                          >
                            Remove directory workspace
                          </button>
                        </div>
                      ))}
                    </div>

                    <div className="flow-variable-editor-list" aria-label="Editable auth directory controls">
                      <section className="flow-variable-editor">
                        <div className="flow-variable-editor-head">
                          <strong>Add directory user</strong>
                          <button className="secondary-action-button" onClick={handleAddAuthUser} type="button">
                            Queue directory user
                          </button>
                        </div>
                        <label className="flow-variable-field">
                          <span>Principal ID</span>
                          <input
                            aria-label="Auth directory principal id"
                            onChange={(event) => {
                              setAuthUserDraft((currentDraft) => ({
                                ...currentDraft,
                                principalId: event.target.value
                              }));
                            }}
                            value={authUserDraft.principalId}
                          />
                        </label>
                        <label className="flow-variable-field">
                          <span>Display name</span>
                          <input
                            aria-label="Auth directory display name"
                            onChange={(event) => {
                              setAuthUserDraft((currentDraft) => ({
                                ...currentDraft,
                                displayName: event.target.value
                              }));
                            }}
                            value={authUserDraft.displayName}
                          />
                        </label>
                        <label className="flow-variable-field">
                          <span>Email</span>
                          <input
                            aria-label="Auth directory email"
                            onChange={(event) => {
                              setAuthUserDraft((currentDraft) => ({
                                ...currentDraft,
                                email: event.target.value
                              }));
                            }}
                            value={authUserDraft.email}
                          />
                        </label>
                        <label className="flow-variable-field">
                          <span>
                            <input
                              aria-label="Auth directory user active"
                              checked={authUserDraft.active}
                              onChange={(event) => {
                                setAuthUserDraft((currentDraft) => ({
                                  ...currentDraft,
                                  active: event.target.checked
                                }));
                              }}
                              type="checkbox"
                            />
                            Active user
                          </span>
                        </label>
                      </section>

                      <section className="flow-variable-editor">
                        <div className="flow-variable-editor-head">
                          <strong>Add directory workspace</strong>
                          <button className="secondary-action-button" onClick={handleAddAuthWorkspace} type="button">
                            Queue directory workspace
                          </button>
                        </div>
                        <label className="flow-variable-field">
                          <span>Workspace ID</span>
                          <input
                            aria-label="Auth directory workspace id"
                            onChange={(event) => {
                              setAuthWorkspaceDraft((currentDraft) => ({
                                ...currentDraft,
                                workspaceId: event.target.value
                              }));
                            }}
                            value={authWorkspaceDraft.workspaceId}
                          />
                        </label>
                        <label className="flow-variable-field">
                          <span>Name</span>
                          <input
                            aria-label="Auth directory workspace name"
                            onChange={(event) => {
                              setAuthWorkspaceDraft((currentDraft) => ({
                                ...currentDraft,
                                name: event.target.value
                              }));
                            }}
                            value={authWorkspaceDraft.name}
                          />
                        </label>
                        <label className="flow-variable-field">
                          <span>
                            <input
                              aria-label="Auth directory workspace active"
                              checked={authWorkspaceDraft.active}
                              onChange={(event) => {
                                setAuthWorkspaceDraft((currentDraft) => ({
                                  ...currentDraft,
                                  active: event.target.checked
                                }));
                              }}
                              type="checkbox"
                            />
                            Active workspace
                          </span>
                        </label>
                      </section>

                      <button
                        className="primary-action-button"
                        disabled={isAuthDirectorySaveDisabled}
                        onClick={() => {
                          void handleSaveAuthDirectory();
                        }}
                        type="button"
                      >
                        {isSavingAuthDirectory ? "Saving auth directory..." : "Save auth directory"}
                      </button>
                    </div>
                  </div>

                  <div className="route-card-list">
                    {authPolicyDraft.roleBindings.slice(0, 6).map((binding, index) => (
                      <div className="route-list-item" key={`${binding.principalId}:${binding.workspaceId}`}>
                        <strong>{binding.principalId}</strong>
                        <span>{binding.workspaceId} · {binding.role}</span>
                        <button
                          className="danger-action-button"
                          onClick={() => {
                            handleRemoveRoleBinding(index);
                          }}
                          type="button"
                        >
                          Remove role binding
                        </button>
                      </div>
                    ))}
                    {authPolicyDraft.resourcePolicies.slice(0, 6).map((policy, index) => (
                      <div className="route-list-item" key={`${policy.resourceType}:${policy.resourceId}:${policy.workspaceId}`}>
                        <strong>{policy.resourceType}:{policy.resourceId}</strong>
                        <span>{policy.workspaceId} · {Object.keys(policy.permissionsByRole).join(", ")}</span>
                        <button
                          className="danger-action-button"
                          onClick={() => {
                            handleRemoveResourcePolicy(index);
                          }}
                          type="button"
                        >
                          Remove resource policy
                        </button>
                      </div>
                    ))}
                  </div>

                  <div className="flow-variable-editor-list" aria-label="Editable auth policy controls">
                    <section className="flow-variable-editor">
                      <div className="flow-variable-editor-head">
                        <strong>Add role binding</strong>
                        <button className="secondary-action-button" onClick={handleAddRoleBinding} type="button">
                          Queue role binding
                        </button>
                      </div>
                      <label className="flow-variable-field">
                        <span>Principal ID</span>
                        <input
                          aria-label="Auth policy principal id"
                          onChange={(event) => {
                            setRoleBindingDraft((currentDraft) => ({
                              ...currentDraft,
                              principalId: event.target.value
                            }));
                          }}
                          value={roleBindingDraft.principalId}
                        />
                      </label>
                      <label className="flow-variable-field">
                        <span>Workspace ID</span>
                        <input
                          aria-label="Auth policy role workspace id"
                          onChange={(event) => {
                            setRoleBindingDraft((currentDraft) => ({
                              ...currentDraft,
                              workspaceId: event.target.value
                            }));
                          }}
                          value={roleBindingDraft.workspaceId}
                        />
                      </label>
                      <label className="flow-variable-field">
                        <span>Role</span>
                        <select
                          aria-label="Auth policy workspace role"
                          onChange={(event) => {
                            setRoleBindingDraft((currentDraft) => ({
                              ...currentDraft,
                              role: event.target.value as WorkspaceRole
                            }));
                          }}
                          value={roleBindingDraft.role}
                        >
                          {workspaceRoleOptions.map((role) => (
                            <option key={role} value={role}>{role}</option>
                          ))}
                        </select>
                      </label>
                    </section>

                    <section className="flow-variable-editor">
                      <div className="flow-variable-editor-head">
                        <strong>Add resource policy</strong>
                        <button className="secondary-action-button" onClick={handleAddResourcePolicy} type="button">
                          Queue resource policy
                        </button>
                      </div>
                      <label className="flow-variable-field">
                        <span>Resource type</span>
                        <input
                          aria-label="Auth policy resource type"
                          onChange={(event) => {
                            setResourcePolicyDraft((currentDraft) => ({
                              ...currentDraft,
                              resourceType: event.target.value
                            }));
                          }}
                          value={resourcePolicyDraft.resourceType}
                        />
                      </label>
                      <label className="flow-variable-field">
                        <span>Resource ID</span>
                        <input
                          aria-label="Auth policy resource id"
                          onChange={(event) => {
                            setResourcePolicyDraft((currentDraft) => ({
                              ...currentDraft,
                              resourceId: event.target.value
                            }));
                          }}
                          value={resourcePolicyDraft.resourceId}
                        />
                      </label>
                      <label className="flow-variable-field">
                        <span>Workspace ID</span>
                        <input
                          aria-label="Auth policy resource workspace id"
                          onChange={(event) => {
                            setResourcePolicyDraft((currentDraft) => ({
                              ...currentDraft,
                              workspaceId: event.target.value
                            }));
                          }}
                          value={resourcePolicyDraft.workspaceId}
                        />
                      </label>
                      <label className="flow-variable-field">
                        <span>Owner permissions</span>
                        <input
                          aria-label="Auth policy owner permissions"
                          onChange={(event) => {
                            setResourcePolicyDraft((currentDraft) => ({
                              ...currentDraft,
                              ownerPermissions: event.target.value
                            }));
                          }}
                          value={resourcePolicyDraft.ownerPermissions}
                        />
                      </label>
                      <label className="flow-variable-field">
                        <span>Editor permissions</span>
                        <input
                          aria-label="Auth policy editor permissions"
                          onChange={(event) => {
                            setResourcePolicyDraft((currentDraft) => ({
                              ...currentDraft,
                              editorPermissions: event.target.value
                            }));
                          }}
                          value={resourcePolicyDraft.editorPermissions}
                        />
                      </label>
                      <label className="flow-variable-field">
                        <span>Viewer permissions</span>
                        <input
                          aria-label="Auth policy viewer permissions"
                          onChange={(event) => {
                            setResourcePolicyDraft((currentDraft) => ({
                              ...currentDraft,
                              viewerPermissions: event.target.value
                            }));
                          }}
                          value={resourcePolicyDraft.viewerPermissions}
                        />
                      </label>
                    </section>

                    <button
                      className="primary-action-button"
                      disabled={isAuthPolicySaveDisabled}
                      onClick={() => {
                        void handleSaveAuthPolicy();
                      }}
                      type="button"
                    >
                      {isSavingAuthPolicy ? "Saving auth policy..." : "Save auth policy"}
                    </button>
                  </div>

                  <div className="checkpoint-policy">
                    <h2>Audit actions</h2>
                    <ul className="checkpoint-list">
                      {workspaceData.auditActions.slice(0, 4).map((event) => (
                        <li key={`${event.recordedAt}:${event.action}:${event.targetId}`}>
                          <strong>{event.action}</strong>
                          <span>{event.targetType}:{event.targetId} · {event.authContext.principalId}</span>
                        </li>
                      ))}
                    </ul>
                    {workspaceData.auditActions.length === 0 ? (
                      <div className="repository-empty"><span>No audit actions loaded.</span></div>
                    ) : null}
                  </div>
                </Panel>

                <Panel className="phase-panel">
                  <SectionTitle
                    kicker="Roadmap"
                    title="Program phases"
                    detail="Roadmap remains available, but moved out of primary authoring surface."
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
              </section>
            </section>
          ) : null}
        </main>
      </div>
    </div>
  );
}

export default App;
