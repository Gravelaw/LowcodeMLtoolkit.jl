import { Card, DataTable, MetricCard, StatusPill } from "../components/ui";
import type { ActionFeedback, AppData } from "../types";

export function ExplorerView({
  data,
  feedback,
  onSave,
  onRun
}: {
  data: AppData;
  feedback?: ActionFeedback;
  onSave: () => void;
  onRun: () => void;
}) {
  const health = data.health;
  const latestExecution = data.executions[0];
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

      <div className="metrics-row">
        <MetricCard label="CPU Usage" value="28%" detail={`${health.cpuThreadCount} local threads`} />
        <MetricCard label="RAM Usage" value="6.2 GB" detail="39% of 16 GB" tone="blue" />
        <MetricCard label="Disk Space" value="212 GB" detail="300 GB free" />
        <MetricCard label="Executions" value={String(data.executions.length)} detail={latestExecution?.status ?? "backend records"} tone="green" />
        <MetricCard label="Workflow Nodes" value={String(data.workflow.nodes.length)} detail={data.workflowSummary.version} tone="purple" />
      </div>

      <Card title="Workflow Lifecycle" eyebrow={data.workflowSummary.workflowId}>
        <div className="key-values">
          <span>Name</span><strong>{data.workflowSummary.name}</strong>
          <span>Version</span><strong>{data.workflowSummary.version}</strong>
          <span>Latest Execution</span><strong>{latestExecution?.executionId ?? "No backend execution yet"}</strong>
          <span>Status</span><strong>{latestExecution?.status ?? "not run"}</strong>
        </div>
      </Card>

      <Card title="Local Project Browser" eyebrow="~/JuliaFlowLocal/Projects">
        <DataTable
          columns={[
            { key: "path", label: "Path" },
            { key: "size", label: "Size" },
            { key: "status", label: "Status", render: (row) => <StatusPill tone="green">{String(row.status)}</StatusPill> }
          ]}
          rows={data.projectFiles}
          getRowKey={(row) => String(row.path)}
        />
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

      <Card title="System Health" className="right-panel">
        <div className="health-list">
          <div><span>Overall Status</span><StatusPill tone="green">Healthy</StatusPill></div>
          <div><span>CPU</span><strong>28%</strong></div>
          <div><span>RAM</span><strong>6.2 / 16 GB</strong></div>
          <div><span>Disk</span><strong>212 / 512 GB</strong></div>
          <div><span>Temperature</span><strong>48 C</strong></div>
        </div>
      </Card>

      <Card title="Privacy & Security (Local-First)" className="wide">
        <ul className="check-list">
          <li>100% local execution</li>
          <li>No cloud sync or telemetry</li>
          <li>No data leaves your device</li>
          <li>All files stored on your local filesystem</li>
        </ul>
        <StatusPill tone="green">Your data never leaves this device. Guaranteed.</StatusPill>
      </Card>

      <Card title="Local Compute">
        <div className="key-values">
          <span>Compute Backend</span><strong>CPU (Local)</strong>
          <span>Threads</span><strong>{health.cpuThreadCount}</strong>
          <span>BLAS</span><strong>OpenBLAS (Local)</strong>
          <span>GPU</span><strong>CPU fallback</strong>
        </div>
      </Card>

      <Card title="Local Packages">
        <div className="key-values">
          <span>Installed</span><strong>142</strong>
          <span>Outdated</span><strong>2</strong>
          <span>Last Updated</span><strong>Today, 9:41 AM</strong>
          <span>Hub Mode</span><strong>Offline cache ready</strong>
        </div>
      </Card>
    </div>
  );
}
