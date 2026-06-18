import { Card, DataTable, StatusPill } from "../components/ui";
import type { AppData } from "../types";

export function SettingsView({ data }: { data: AppData }) {
  return (
    <div className="route-grid settings-route">
      <section className="page-title">
        <div>
          <h1>Settings</h1>
          <p>Configure the local appliance profile, packages, runtime, security, API keys, and backup evidence.</p>
        </div>
        <button type="button" className="jf-button primary">Save Local Settings</button>
      </section>

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
        <div className="key-values">
          <span>Backend</span><strong>{data.health.hardwareSelectedBackend}</strong>
          <span>Threads</span><strong>{data.health.cpuThreadCount}</strong>
          <span>GPU</span><strong>{data.health.gpuReadinessStatus}</strong>
          <span>Autosave</span><strong>30 seconds</strong>
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
          <span>Last checkpoint</span><strong>{data.checkpoints[0].tag}</strong>
          <span>Reproducibility</span><strong>bundle ready</strong>
        </div>
      </Card>
    </div>
  );
}
