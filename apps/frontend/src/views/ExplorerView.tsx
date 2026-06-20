import { Card, MetricCard, StatusPill } from "../components/ui";
import type { ActionFeedback, AppData, LocalProjectArtifact } from "../types";

function formatBytes(value: number | undefined): string {
  if (!Number.isFinite(value) || !value || value <= 0) return "n/a";
  const units = ["B", "KB", "MB", "GB", "TB"];
  let size = value;
  let unitIndex = 0;
  while (size >= 1000 && unitIndex < units.length - 1) {
    size /= 1000;
    unitIndex += 1;
  }
  return `${size >= 10 || unitIndex === 0 ? size.toFixed(0) : size.toFixed(1)} ${units[unitIndex]}`;
}

function formatUpdatedAt(value: string | undefined, stale: boolean): string {
  if (!value) return stale ? "waiting for gateway health" : "fixture snapshot";
  const time = new Date(value);
  if (Number.isNaN(time.getTime())) return stale ? "last update stale" : "updated";
  return `${stale ? "stale since" : "updated"} ${time.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" })}`;
}

function percent(used: number, total: number): string {
  if (!Number.isFinite(used) || !Number.isFinite(total) || total <= 0) return "n/a";
  return `${Math.round((used / total) * 100)}%`;
}

function artifactKind(path: string): string {
  const lower = path.toLowerCase();
  if (lower.endsWith(".csv")) return "dataset";
  if (lower.endsWith(".arrow") || lower.endsWith(".parquet")) return "table";
  if (lower.endsWith(".jl") || lower.endsWith(".toml")) return "code";
  if (lower.endsWith(".jls")) return "model";
  if (lower.endsWith(".json") || lower.endsWith(".md")) return "metadata";
  return "artifact";
}

function groupArtifacts(files: LocalProjectArtifact[]) {
  const groups = new Map<string, LocalProjectArtifact[]>();
  for (const file of files) {
    const parts = file.path.split(/[\\/]/).filter(Boolean);
    const root = parts[0] ?? "Project";
    const folder = parts.length > 2 ? `${root}/${parts[1]}` : root;
    groups.set(folder, [...(groups.get(folder) ?? []), file]);
  }
  return Array.from(groups.entries()).map(([folder, artifacts]) => ({ folder, artifacts }));
}

export function ExplorerView({
  data,
  feedback,
  onSave,
  onRun,
  onCopyArtifactPath,
  onOpenSettings
}: {
  data: AppData;
  feedback?: ActionFeedback;
  onSave: () => void;
  onRun: () => void;
  onCopyArtifactPath: (path: string) => void;
  onOpenSettings: () => void;
}) {
  const health = data.health;
  const latestExecution = data.executions[0];
  const memoryUsedBytes = Math.max(0, health.totalMemoryBytes - health.freeMemoryBytes);
  const diskUsedBytes = Math.max(0, health.dataEstateQuotaBytes - health.freeDiskBytes);
  const artifactGroups = groupArtifacts(data.projectFiles);

  return (
    <div className="route-grid explorer-route">
      <section className="page-title">
        <div>
          <span className="title-icon">Desktop</span>
          <h1>Local Workspace Overview</h1>
          <p>Everything runs on your machine. No data leaves your device.</p>
        </div>
        <div className="button-row">
          <button type="button" className="jf-button secondary" onClick={onSave}>Save Workflow</button>
          <button type="button" className="jf-button primary" onClick={onRun}>Run Workflow</button>
        </div>
      </section>
      {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

      <Card
        title="System Health"
        eyebrow={formatUpdatedAt(data.healthLastUpdatedAt, data.healthStale)}
        className="wide system-health-card"
        action={<StatusPill tone={data.healthStale || health.hardwareProfileStatus === "degraded" ? "orange" : "green"}>{data.healthStale ? "Stale" : health.hardwareProfileStatus}</StatusPill>}
      >
        <div className="system-health-grid">
          <div className="health-metric">
            <span>CPU Runtime</span>
            <strong>{health.cpuThreadCount} threads</strong>
            <small>{health.cpuWorkerConcurrency} worker concurrency, {health.cpuSchedulerPolicy}</small>
          </div>
          <div className="health-metric">
            <span>Memory</span>
            <strong>{formatBytes(memoryUsedBytes)} / {formatBytes(health.totalMemoryBytes)}</strong>
            <small>{formatBytes(health.freeMemoryBytes)} free, {percent(memoryUsedBytes, health.totalMemoryBytes)} used</small>
          </div>
          <div className="health-metric">
            <span>Data Estate Disk</span>
            <strong>{formatBytes(diskUsedBytes)} / {formatBytes(health.dataEstateQuotaBytes)}</strong>
            <small>{formatBytes(health.freeDiskBytes)} free, {health.freeDiskStatus}</small>
          </div>
          <div className="health-metric">
            <span>GPU</span>
            <strong>{health.gpuReadinessStatus}</strong>
            <small>{health.hardwareSelectedBackend}, {health.gpuFallbackReason}</small>
          </div>
        </div>
      </Card>

      <div className="metrics-row explorer-summary-row">
        <MetricCard label="Executions" value={String(data.executions.length)} detail={latestExecution?.status ?? "backend records"} tone="green" />
        <MetricCard label="Workflow Nodes" value={String(data.workflow.nodes.length)} detail={data.workflowSummary.version} tone="purple" />
        <MetricCard label="Metadata" value={health.metadataBackend} detail={health.metadataConcurrencyStatus} tone="blue" />
        <MetricCard label="Local Artifacts" value={String(data.projectFiles.length)} detail={health.dataEstateManaged ? "managed data estate" : "unmanaged paths"} tone="orange" />
      </div>

      <Card title="Workflow Lifecycle" eyebrow={data.workflowSummary.workflowId}>
        <div className="key-values">
          <span>Name</span><strong>{data.workflowSummary.name}</strong>
          <span>Version</span><strong>{data.workflowSummary.version}</strong>
          <span>Latest Execution</span><strong>{latestExecution?.executionId ?? "No backend execution yet"}</strong>
          <span>Status</span><strong>{latestExecution?.status ?? "not run"}</strong>
        </div>
      </Card>

      <Card title="Local Project Browser" eyebrow={health.dataEstateRoot}>
        <div className="artifact-tree" aria-label="Local project artifact hierarchy">
          {artifactGroups.map((group) => (
            <section key={group.folder} className="artifact-group">
              <div className="artifact-folder">
                <strong>{group.folder}</strong>
                <small>{group.artifacts.length} artifacts</small>
              </div>
              <ul>
                {group.artifacts.map((artifact) => {
                  const name = artifact.path.split(/[\\/]/).filter(Boolean).at(-1) ?? artifact.path;
                  return (
                    <li key={artifact.path}>
                      <div>
                        <strong>{name}</strong>
                        <span>{artifact.path}</span>
                      </div>
                      <small>{artifactKind(artifact.path)} · {artifact.size}</small>
                      <StatusPill tone="green">{artifact.status}</StatusPill>
                      <button type="button" className="jf-button ghost" onClick={() => onCopyArtifactPath(artifact.path)}>Copy Path</button>
                    </li>
                  );
                })}
              </ul>
            </section>
          ))}
        </div>
      </Card>

      <Card title="Recent Local Activity">
        <ol className="activity-list">
          {[
            "Pipeline completed",
            "Model trained: churn_model_v1.jls",
            "Dataset loaded: churn.csv",
            "EDA notebook executed",
            "Transform completed"
          ].map((item, index) => (
            <li key={item}>
              <span className="activity-dot" />
              <strong>{item}</strong>
              <small>{index + 2}m ago</small>
            </li>
          ))}
        </ol>
      </Card>

      <Card title="Project Trust Boundary" eyebrow={data.workflowSummary.name} className="wide">
        <div className="key-values">
          <span>Local home</span><strong>{health.localHome}</strong>
          <span>Data estate</span><strong>{health.dataEstateRoot}</strong>
          <span>Metadata</span><strong>{health.metadataBackend} · {health.metadataReady ? "ready" : "not ready"}</strong>
          <span>Auth mode</span><strong>{health.authMode ?? "disabled"}</strong>
          <span>Backup</span><strong>{health.dataEstateBackupStatus} · {health.dataEstateBackupRoot}</strong>
          <span>Runtime</span><strong>{data.runtimeMode} · {health.fixtureProvenance}</strong>
        </div>
      </Card>

      <Card
        title="Local Compute"
        eyebrow="Runtime health source"
        action={<button type="button" className="jf-button secondary" onClick={onOpenSettings}>Open Settings</button>}
      >
        <div className="key-values">
          <span>Compute Backend</span><strong>{health.hardwareSelectedBackend}</strong>
          <span>Threads</span><strong>{health.cpuThreadCount}</strong>
          <span>Worker concurrency</span><strong>{health.cpuWorkerConcurrency}</strong>
          <span>Memory limit</span><strong>{formatBytes(health.cpuMemoryLimitBytes)}</strong>
          <span>GPU</span><strong>{health.gpuReadinessStatus}</strong>
          <span>CUDA</span><strong>{health.gpuCudaStatus}</strong>
        </div>
      </Card>

      <Card title="Local Packages">
        <div className="key-values">
          <span>Installed</span><strong>142</strong>
          <span>Outdated</span><strong>2</strong>
          <span>Last Updated</span><strong>Today, 9:41 AM</strong>
          <span>Hub Mode</span><strong>{health.hubCacheStatus}</strong>
        </div>
      </Card>
    </div>
  );
}
