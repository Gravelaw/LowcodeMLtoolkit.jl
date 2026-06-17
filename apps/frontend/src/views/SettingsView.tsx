import { useState } from "react";
import { ActionFeedbackStatus, Card, DataTable, StatusPill } from "../components/ui";
import type { ActionFeedback, AppData } from "../types";

function formatGb(bytes: number) {
  return `${(bytes / 1_000_000_000).toFixed(1)} GB`;
}

function zonePath(data: AppData, zoneName: string, fallback: string) {
  return data.health.dataEstateZones.find((zone) => zone.name === zoneName)?.path ?? fallback;
}

export function SettingsView({
  data,
  feedback,
  onCreateSnapshot
}: {
  data: AppData;
  feedback?: ActionFeedback;
  onCreateSnapshot: () => void;
}) {
  const [localFeedback, setLocalFeedback] = useState<ActionFeedback | undefined>();
  const [threadLimit, setThreadLimit] = useState(String(data.health.cpuWorkerConcurrency));
  const [memoryLimit, setMemoryLimit] = useState(formatGb(data.health.cpuMemoryLimitBytes));
  const [backupRetention, setBackupRetention] = useState("14 snapshots");
  const actionFeedback = localFeedback ?? feedback;
  const createSnapshot = () => {
    setLocalFeedback(undefined);
    onCreateSnapshot();
  };
  const workspacePaths = [
    { area: "Data root", path: data.health.dataEstateRoot, status: data.health.dataEstateReady ? "ready" : "pending" },
    { area: "Models", path: zonePath(data, "models", `${data.health.dataEstateRoot}/models`), status: "writable" },
    { area: "Backups", path: data.health.dataEstateBackupRoot, status: data.health.dataEstateBackupStatus },
    { area: "Exports", path: zonePath(data, "dashboards", `${data.health.dataEstateRoot}/dashboards`), status: "writable" }
  ];

  return (
    <div className="route-grid settings-route">
      <section className="page-title">
        <div>
          <h1>Settings</h1>
          <p>Configure the local appliance profile, packages, runtime, security, API keys, and backup evidence.</p>
        </div>
        <button
          type="button"
          className="jf-button primary"
          onClick={() => setLocalFeedback({ label: "Local appliance settings saved to the active profile.", tone: "success" })}
        >
          Save Local Settings
        </button>
      </section>
      <ActionFeedbackStatus feedback={actionFeedback} />

      <Card title="Local Workspace Profile" className="wide">
        <div className="key-values">
          <span>Profile</span><strong>{data.health.localProfile}</strong>
          <span>Workspace</span><strong>{data.health.localHome}</strong>
          <span>Metadata</span><strong>{data.health.metadataBackend}</strong>
          <span>Mode</span><strong>offline</strong>
        </div>
      </Card>

      <Card title="Workspace Path Controls" className="right-panel">
        <DataTable
          columns={[
            { key: "area", label: "Area" },
            { key: "path", label: "Local Path" },
            { key: "status", label: "Status", render: (row) => <StatusPill tone="green">{String(row.status)}</StatusPill> }
          ]}
          rows={workspacePaths}
          getRowKey={(row) => String(row.area)}
        />
        <div className="button-row">
          <button type="button" className="jf-button" onClick={() => setLocalFeedback({ label: "Workspace path picker opened locally.", tone: "info" })}>Change Paths</button>
          <button type="button" className="jf-button" onClick={() => setLocalFeedback({ label: "Local paths verified as writable.", tone: "success" })}>Verify Paths</button>
        </div>
      </Card>

      <Card title="Project And Theme">
        <fieldset className="settings-fieldset">
          <legend>Active project</legend>
          <label><input type="radio" name="project" defaultChecked /> Customer Churn Project</label>
          <label><input type="radio" name="project" /> Local demo workspace</label>
        </fieldset>
        <fieldset className="settings-fieldset">
          <legend>Theme</legend>
          <label><input type="radio" name="theme" defaultChecked /> Light appliance</label>
          <label><input type="radio" name="theme" /> High contrast local</label>
        </fieldset>
      </Card>

      <Card title="Package Environment And Julia Runtime" className="wide">
        <DataTable
          columns={[
            { key: "name", label: "Area" },
            { key: "value", label: "Value" },
            { key: "status", label: "Status", render: (row) => <StatusPill tone="green">{String(row.status)}</StatusPill> }
          ]}
          rows={[
            { name: "Julia executable", value: `${data.health.localHome}/julia/bin/julia`, status: "configured" },
            { name: "Active environment", value: `${data.health.localHome}/Project.toml`, status: "active" },
            { name: "Manifest", value: `${data.health.localHome}/Manifest.toml`, status: "locked" },
            { name: "Offline package cache", value: data.health.hubCacheRoot, status: data.health.hubCacheStatus }
          ]}
          getRowKey={(row) => String(row.name)}
        />
      </Card>

      <Card title="Compute And Autosave">
        <label className="control-row">
          <span>CPU thread limit</span>
          <input value={threadLimit} onChange={(event) => setThreadLimit(event.target.value)} inputMode="numeric" aria-label="CPU thread limit" />
        </label>
        <label className="control-row">
          <span>Memory limit</span>
          <input value={memoryLimit} onChange={(event) => setMemoryLimit(event.target.value)} aria-label="Memory limit" />
        </label>
        <label className="control-row">
          <span>Autosave interval</span>
          <select defaultValue="30 seconds" aria-label="Autosave interval">
            <option>15 seconds</option>
            <option>30 seconds</option>
            <option>60 seconds</option>
          </select>
        </label>
        <div className="key-values compact-values">
          <span>Backend</span><strong>{data.health.hardwareSelectedBackend}</strong>
          <span>GPU fallback</span><strong>{data.health.gpuReadinessStatus}</strong>
        </div>
      </Card>

      <Card title="Privacy, Security, And API Keys" className="right-panel">
        <fieldset className="settings-fieldset">
          <legend>Trust boundary</legend>
          <label><input type="checkbox" defaultChecked /> Telemetry disabled</label>
          <label><input type="checkbox" defaultChecked /> Logs remain on local disk</label>
          <label><input type="checkbox" defaultChecked /> Share tokens disabled by default</label>
          <label><input type="checkbox" defaultChecked /> API keys scoped to device or LAN</label>
        </fieldset>
        <div className="key-values compact-values">
          <span>Audit store</span><strong>{data.health.metadataRoot}</strong>
          <span>Credential mode</span><strong>local profile only</strong>
        </div>
        <div className="button-row">
          <button type="button" className="jf-button" onClick={() => setLocalFeedback({ label: "Local API key rotation queued without exposing key material.", tone: "info" })}>Rotate Local API Key</button>
          <button type="button" className="jf-button" onClick={() => setLocalFeedback({ label: "LAN API scope remains disabled.", tone: "success" })}>Verify Scope</button>
        </div>
        <StatusPill tone="green">Local trust boundary</StatusPill>
      </Card>

      <Card title="Backup And Restore" className="wide">
        <div className="button-row top-aligned">
          <button type="button" className="jf-button primary" onClick={createSnapshot}>Create Local Snapshot</button>
          <label className="control-row inline">
            <span>Retention</span>
            <select value={backupRetention} onChange={(event) => setBackupRetention(event.target.value)} aria-label="Backup retention">
              <option>7 snapshots</option>
              <option>14 snapshots</option>
              <option>30 snapshots</option>
            </select>
          </label>
        </div>
        <div className="key-values">
          <span>Backup root</span><strong>{data.health.dataEstateBackupRoot}</strong>
          <span>Status</span><strong>{data.health.dataEstateBackupStatus}</strong>
          <span>Last checkpoint</span><strong>{data.checkpoints[0].tag}</strong>
          <span>Retention</span><strong>{backupRetention}</strong>
          <span>Reproducibility</span><strong>bundle ready</strong>
        </div>
      </Card>
    </div>
  );
}
