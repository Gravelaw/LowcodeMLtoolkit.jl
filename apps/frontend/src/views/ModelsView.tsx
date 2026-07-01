import { Card, DataTable, MetricCard, StatusPill } from "../components/ui";
import type { ActionFeedback, AppData } from "../types";

function lifecycleGateReason(state?: string, hasEvaluation?: boolean, hasEndpoint?: boolean) {
  if (!state) return "No lifecycle record is attached to this model.";
  if ((state === "candidate" || state === "validated") && !hasEvaluation) return "Approval is blocked until final evaluation evidence is attached.";
  if (state === "approved") return "Deployment can proceed after local package evidence is created.";
  if (state === "deployed" && !hasEndpoint) return "Rollback review is blocked until a deployed endpoint id is attached.";
  if (state === "deprecated") return "Archive is available after deprecation review.";
  if (state === "archived") return "Lifecycle actions are closed for this archived model.";
  return "Next lifecycle action is available when the matching review evidence is present.";
}

export function ModelsView({
  data,
  onRegister,
  feedback
}: {
  data: AppData;
  onRegister: () => void;
  feedback?: ActionFeedback;
}) {
  const registryRows = data.modelRegistry.length > 0 ? data.modelRegistry : data.dataScienceProject.modelRegistryRecords;
  const registrySource = data.modelRegistry.length > 0 ? "Workflow registry endpoint" : "Project-backed registry records";
  const selected = registryRows[0];
  const artifactEvidence = selected?.artifactEvidence ?? [];
  const lifecycle = selected ? data.dataScienceProject.modelLifecycleRecords.find((record) => record.modelId === selected.modelId) : undefined;
  const lifecycleState = lifecycle?.state ?? selected?.status;
  const gateReason = lifecycleGateReason(lifecycleState, Boolean(lifecycle?.evaluationReportId), Boolean(lifecycle?.deployedEndpointId));
  return (
    <div className="route-grid models-route">
      <section className="page-title">
        <div>
          <h1>Models</h1>
          <p>Fully local model registry and monitoring. All models are stored on your machine.</p>
        </div>
        <button type="button" className="jf-button primary" onClick={onRegister}>Register Model</button>
      </section>
      {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

      <Card title="Model Registry" className="wide">
        <p className="card-note">Source: {registrySource}</p>
        <DataTable
          columns={[
            { key: "modelId", label: "Model Name" },
            { key: "workflowVersion", label: "Local Version" },
            { key: "owner", label: "Owner" },
            { key: "modelKind", label: "Type" },
            { key: "primaryMetricValue", label: "Primary Metric" },
            { key: "deploymentStatus", label: "Deployment", render: (row) => <StatusPill tone="green">{String(row.deploymentStatus)}</StatusPill> }
          ]}
          rows={registryRows}
          getRowKey={(row) => String(row.registryId)}
        />
      </Card>

      <Card title={selected?.modelId ?? "No Model Selected"} className="right-panel detail-drawer">
        {selected ? (
          <>
            <div className="drawer-head">
              <h2>{selected.modelId}</h2>
              <StatusPill tone="green">Healthy</StatusPill>
            </div>
            <div className="metrics-grid-small">
              <MetricCard label={selected.primaryMetricName} value={selected.primaryMetricValue.toFixed(3)} detail="latest" />
              <MetricCard label="F1 Score" value="0.861" detail="v1.2.0" tone="blue" />
              <MetricCard label="Precision" value="0.872" detail="v1.2.0" tone="green" />
              <MetricCard label="Recall" value="0.850" detail="v1.2.0" tone="orange" />
            </div>
            <div className="key-values">
              <span>Framework</span><strong>MLJ.jl</strong>
              <span>Training Data</span><strong>25.1 GB local</strong>
              <span>Model Path</span><strong>{artifactEvidence[0]?.artifactRef ?? "No local model artifact"}</strong>
              <span>Lifecycle</span><strong>{lifecycleState ?? "No lifecycle evidence"}</strong>
              <span>Registry Source</span><strong>{registrySource}</strong>
              <span>Gate</span><strong>{gateReason}</strong>
            </div>
            <h3>Artifacts (Stored on Disk)</h3>
            {artifactEvidence.length === 0 ? (
              <p className="empty-state">No local model artifacts are attached to this registry record yet.</p>
            ) : (
              <ul className="artifact-list">
                {artifactEvidence.map((artifact) => <li key={artifact.artifactRef}>{artifact.artifactRef}</li>)}
              </ul>
            )}
          </>
        ) : (
          <p className="empty-state">No backend model registry records are available for this workspace yet. Register a model after training completes.</p>
        )}
      </Card>

      <Card title="Model Comparison" className="wide">
        <DataTable
          columns={[
            { key: "metric", label: "Metric" },
            { key: "churn", label: "Churn Prediction v1.2" },
            { key: "fraud", label: "Fraud Detection v2.0" },
            { key: "clv", label: "Customer CLV v1.1" }
          ]}
          rows={[
            { metric: "AUC", churn: "0.912", fraud: "0.876", clv: "-" },
            { metric: "F1 Score", churn: "0.861", fraud: "0.812", clv: "-" },
            { metric: "Training Data", churn: "25.1 GB", fraud: "18.7 GB", clv: "31.2 GB" }
          ]}
          getRowKey={(row) => String(row.metric)}
        />
      </Card>

      <Card title="Version Performance">
        <div className="line-chart tall" />
      </Card>

      <Card title="Drift And Monitoring">
        <label className="bar-row"><span>tenure_months</span><meter value={0.18} min={0} max={1} /></label>
        <label className="bar-row"><span>monthly_charges</span><meter value={0.37} min={0} max={1} /></label>
        <label className="bar-row"><span>contract_type</span><meter value={0.79} min={0} max={1} /></label>
        <StatusPill tone="green">No cloud registry</StatusPill>
      </Card>
    </div>
  );
}
