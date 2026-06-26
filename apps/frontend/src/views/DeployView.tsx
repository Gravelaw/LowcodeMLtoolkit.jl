import { Card, CodeBlock, DataTable, StatusPill } from "../components/ui";
import { localCode } from "../fixtures/local-fixtures";
import type { ActionFeedback, AppData } from "../types";

function deployBlockedReason(data: AppData) {
  const model = data.modelRegistry[0];
  if (!model) return "No registered model is available.";
  const lifecycle = data.dataScienceProject.modelLifecycleRecords.find((record) => record.modelId === model.modelId);
  if (model.status === "archived" || lifecycle?.state === "archived") return "Archived models cannot be packaged.";
  if (model.status === "deprecated" || lifecycle?.state === "deprecated") return "Deprecated models require a new approval before packaging.";
  if (!model.validationEvidence?.projectId) return "Validation evidence is required before local packaging.";
  if (model.validationEvidence.finalTestPolicy !== "forbid_final_test") return "Packaging is blocked until final-test leakage policy is satisfied.";
  return "";
}

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
  const endpointStatus = current?.deploymentStatus ?? "No package";
  const endpointUrl = current?.endpointUrl ?? "No local endpoint packaged";
  const endpointPort = current?.port ? `127.0.0.1:${current.port}` : "package endpoint first";
  const packageBlockedReason = deployBlockedReason(data);
  return (
    <div className="route-grid deploy-route">
      <section className="page-title">
        <div>
          <h1>Deploy</h1>
          <p>Package local endpoints for this machine without cloud registries or managed inference.</p>
        </div>
        <button type="button" className="jf-button primary" onClick={onPackage} disabled={Boolean(packageBlockedReason)} title={packageBlockedReason || "Package local endpoint"}>Package Local Endpoint</button>
      </section>
      {packageBlockedReason ? <p className="feedback info">{packageBlockedReason}</p> : null}
      {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

      <Card title="Local Targets">
        <div className="source-grid">
          <button type="button" className="source-card active">Local HTTP<br /><small>{endpointPort}</small></button>
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
          <span>Status</span><strong>{endpointStatus}</strong>
          <span>Endpoint</span><strong>{endpointUrl}</strong>
          <span>Package Gate</span><strong>{packageBlockedReason || "Ready"}</strong>
          <span>Latency</span><strong>14.2 ms</strong>
          <span>Requests 24h</span><strong>12,842</strong>
        </div>
        <StatusPill tone={current ? "green" : "neutral"}>{current ? "No cloud telemetry" : "No package yet"}</StatusPill>
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
        {data.deployPackages.length === 0 ? (
          <p className="empty-state">No backend deploy package records are available yet. Package a local endpoint after a model is registered.</p>
        ) : (
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
        )}
      </Card>

      <Card title="Generated Julia API Code" className="wide">
        <CodeBlock label="deploy/service.jl">{localCode.deploy}</CodeBlock>
      </Card>
    </div>
  );
}
