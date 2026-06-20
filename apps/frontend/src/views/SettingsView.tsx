import { useEffect, useState } from "react";
import type { GatewayComputeSettings, UpdateGatewayComputeSettingsRequest } from "@juliaflow/contracts";
import { Card, DataTable, StatusPill } from "../components/ui";
import type { ActionFeedback, AppData } from "../types";

function memoryGb(bytes: number): number {
  return Math.max(1, Math.round(bytes / 1_000_000_000));
}

function toBytes(gb: number): number {
  return Math.max(1, Math.round(gb)) * 1_000_000_000;
}

function draftFromSettings(settings: GatewayComputeSettings) {
  return {
    selectedBackend: settings.selectedBackend,
    cpuWorkerConcurrency: String(settings.cpuWorkerConcurrency),
    cpuMemoryLimitGb: String(memoryGb(settings.cpuMemoryLimitBytes)),
    gpuPreference: settings.gpuPreference,
    blasThreadCount: String(settings.blasThreadCount)
  };
}

export function SettingsView({
  data,
  feedback,
  onSaveComputeSettings
}: {
  data: AppData;
  feedback?: ActionFeedback;
  onSaveComputeSettings: (request: UpdateGatewayComputeSettingsRequest) => void;
}) {
  const latestCheckpointTag = data.checkpoints[0]?.tag ?? "No checkpoint yet";
  const computeSettings = data.health.computeSettings;
  const [draft, setDraft] = useState(() => draftFromSettings(computeSettings));

  useEffect(() => {
    setDraft(draftFromSettings(computeSettings));
  }, [computeSettings]);

  function saveComputeSettings() {
    onSaveComputeSettings({
      selectedBackend: draft.selectedBackend,
      cpuWorkerConcurrency: Number(draft.cpuWorkerConcurrency),
      cpuMemoryLimitBytes: toBytes(Number(draft.cpuMemoryLimitGb)),
      gpuPreference: draft.gpuPreference,
      blasThreadCount: Number(draft.blasThreadCount)
    });
  }

  return (
    <div className="route-grid settings-route">
      <section className="page-title">
        <div>
          <h1>Settings</h1>
          <p>Configure the local appliance profile, packages, runtime, security, API keys, and backup evidence.</p>
        </div>
        <button type="button" className="jf-button primary" onClick={saveComputeSettings}>Save Local Settings</button>
      </section>
      {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

      <Card title="Local Workspace Profile">
        <div className="key-values">
          <span>Profile</span><strong>{data.health.localProfile}</strong>
          <span>Workspace</span><strong>{data.health.localHome}</strong>
          <span>Metadata</span><strong>{data.health.metadataBackend}</strong>
          <span>Mode</span><strong>offline</strong>
        </div>
      </Card>

      <Card title="Project And Theme">
        <div className="source-grid">
          <button type="button" className="source-card active">Customer Churn Project<br /><small>active local project</small></button>
          <button type="button" className="source-card">Light appliance<br /><small>mock aligned</small></button>
        </div>
      </Card>

      <Card title="Package And Julia Runtime" className="wide">
        <DataTable
          columns={[
            { key: "name", label: "Area" },
            { key: "value", label: "Value" },
            { key: "status", label: "Status", render: (row) => <StatusPill tone="green">{String(row.status)}</StatusPill> }
          ]}
          rows={[
            { name: "Julia", value: "1.10.2", status: "up to date" },
            { name: "Packages", value: "142 installed", status: "offline cache ready" },
            { name: "Manifest", value: "Manifest.toml", status: "locked" },
            { name: "Offline Hub", value: data.health.hubCacheRoot, status: data.health.hubCacheStatus }
          ]}
          getRowKey={(row) => String(row.name)}
        />
      </Card>

      <Card title="Compute And Autosave">
        <div className="settings-form">
          <label>
            <span>Backend</span>
            <select
              value={draft.selectedBackend}
              onChange={(event) => setDraft((current) => ({ ...current, selectedBackend: event.target.value as GatewayComputeSettings["selectedBackend"] }))}
            >
              <option value="cpu">CPU</option>
              <option value="cuda">CUDA GPU</option>
              <option value="simulated_cuda">Simulated CUDA</option>
            </select>
          </label>
          <label>
            <span>Worker concurrency</span>
            <input
              type="number"
              min={1}
              max={data.health.cpuThreadCount}
              value={draft.cpuWorkerConcurrency}
              onChange={(event) => setDraft((current) => ({ ...current, cpuWorkerConcurrency: event.target.value }))}
            />
          </label>
          <label>
            <span>Memory limit (GB)</span>
            <input
              type="number"
              min={1}
              max={memoryGb(data.health.totalMemoryBytes)}
              value={draft.cpuMemoryLimitGb}
              onChange={(event) => setDraft((current) => ({ ...current, cpuMemoryLimitGb: event.target.value }))}
            />
          </label>
          <label>
            <span>GPU preference</span>
            <select
              value={draft.gpuPreference}
              onChange={(event) => setDraft((current) => ({ ...current, gpuPreference: event.target.value as GatewayComputeSettings["gpuPreference"] }))}
            >
              <option value="auto">Auto</option>
              <option value="cpu_fallback">CPU fallback</option>
              <option value="cuda_required">CUDA required</option>
            </select>
          </label>
          <label>
            <span>BLAS threads</span>
            <input
              type="number"
              min={1}
              max={data.health.cpuThreadCount}
              value={draft.blasThreadCount}
              onChange={(event) => setDraft((current) => ({ ...current, blasThreadCount: event.target.value }))}
            />
          </label>
        </div>
        <div className="key-values">
          <span>Applied backend</span><strong>{data.health.hardwareSelectedBackend}</strong>
          <span>Applied concurrency</span><strong>{data.health.cpuWorkerConcurrency}</strong>
          <span>Applied memory limit</span><strong>{memoryGb(data.health.cpuMemoryLimitBytes)} GB</strong>
          <span>Settings source</span><strong>{computeSettings.source}</strong>
        </div>
      </Card>

      <Card title="Security And API Keys" className="right-panel">
        <div className="key-values compact">
          <span>Gateway auth</span><strong>{data.health.authMode ?? "disabled"}</strong>
          <span>Dev fallback</span><strong>{data.health.authDevFallback ? "active" : "off"}</strong>
          <span>Runtime mode</span><strong>{data.runtimeMode}</strong>
          <span>Fixture fallback</span><strong>{data.runtime.fixtureSubstitutionAllowed ? "allowed" : "blocked"}</strong>
        </div>
        <ul className="check-list">
          <li>No cloud credentials required</li>
          <li>API keys stored only in local profile</li>
          <li>Audit events stay in local metadata</li>
          <li>Share tokens disabled by default</li>
        </ul>
        <StatusPill tone="green">Local trust boundary</StatusPill>
      </Card>

      <Card title="Backup And Restore" className="wide">
        <div className="key-values">
          <span>Backup root</span><strong>{data.health.dataEstateBackupRoot}</strong>
          <span>Status</span><strong>{data.health.dataEstateBackupStatus}</strong>
          <span>Last checkpoint</span><strong>{latestCheckpointTag}</strong>
          <span>Reproducibility</span><strong>bundle ready</strong>
        </div>
      </Card>
    </div>
  );
}
