import { ActionFeedbackStatus, Card, CodeBlock, DataTable, StatusPill } from "../components/ui";
import { localCode } from "../fixtures/local-fixtures";
import type { ActionFeedback, AppData } from "../types";

export function DeployView({
  data,
  onPackage,
  feedback
}: {
  data: AppData;
  onPackage: () => void;
  feedback?: ActionFeedback;
}) {
  const current = data.deployPackages[0];
  return (
    <div className="route-grid deploy-route">
      <section className="page-title">
        <div>
          <h1>Deploy</h1>
          <p>Package local endpoints for this machine without cloud registries or managed inference.</p>
        </div>
        <button type="button" className="jf-button primary" onClick={onPackage}>Package Local Endpoint</button>
      </section>
      <ActionFeedbackStatus feedback={feedback} />

      <Card title="Local Targets">
        <div className="source-grid">
          <button type="button" className="source-card active">Local HTTP<br /><small>127.0.0.1:{current.port}</small></button>
          <button type="button" className="source-card">Batch scorer<br /><small>local process</small></button>
          <button type="button" className="source-card">Notebook call<br /><small>Julia REPL</small></button>
        </div>
      </Card>

      <Card title="Deployment Pipeline" className="wide">
        <div className="pipeline">
          {["Select model", "Bundle artifacts", "Generate Julia API", "Start local endpoint", "Record request log"].map((step, index) => (
            <div className="pipeline-node" key={step}>
              <span>{index + 1}</span>
              <strong>{step}</strong>
              <small>local ready</small>
            </div>
          ))}
        </div>
      </Card>

      <Card title="Endpoint Monitoring" className="right-panel">
        <div className="key-values">
          <span>Status</span><strong>{current.deploymentStatus}</strong>
          <span>Endpoint</span><strong>{current.endpointUrl}</strong>
          <span>Latency</span><strong>14.2 ms</strong>
          <span>Requests 24h</span><strong>12,842</strong>
        </div>
        <StatusPill tone="green">No cloud telemetry</StatusPill>
      </Card>

      <Card title="Recent Local Requests">
        <DataTable
          columns={[
            { key: "id", label: "Request" },
            { key: "status", label: "Status" },
            { key: "latency", label: "Latency" }
          ]}
          rows={[
            { id: "req-104", status: "200 local", latency: "13 ms" },
            { id: "req-103", status: "200 local", latency: "15 ms" },
            { id: "req-102", status: "200 local", latency: "14 ms" }
          ]}
          getRowKey={(row) => String(row.id)}
        />
      </Card>

      <Card title="Package History" className="wide">
        <DataTable
          columns={[
            { key: "packageId", label: "Package" },
            { key: "modelId", label: "Model" },
            { key: "checkpointTag", label: "Checkpoint" },
            { key: "deploymentStatus", label: "Status", render: (row) => <StatusPill tone="green">{String(row.deploymentStatus)}</StatusPill> },
            { key: "packageRef", label: "Artifact" }
          ]}
          rows={data.deployPackages}
          getRowKey={(row) => String(row.packageId)}
        />
      </Card>

      <Card title="Generated Julia API Code" className="wide">
        <CodeBlock label="deploy/service.jl">{localCode.deploy}</CodeBlock>
      </Card>
    </div>
  );
}
