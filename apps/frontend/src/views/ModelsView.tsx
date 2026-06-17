import { ActionFeedbackStatus, Card, DataTable, MetricCard, StatusPill } from "../components/ui";
import type { ActionFeedback, AppData } from "../types";

export function ModelsView({
  data,
  onRegister,
  feedback
}: {
  data: AppData;
  onRegister: () => void;
  feedback?: ActionFeedback;
}) {
  const selected = data.modelRegistry[0];
  return (
    <div className="route-grid models-route">
      <section className="page-title">
        <div>
          <h1>Models</h1>
          <p>Fully local model registry and monitoring. All models are stored on your machine.</p>
        </div>
        <button type="button" className="jf-button primary" onClick={onRegister}>Register Model</button>
      </section>
      <ActionFeedbackStatus feedback={feedback} />

      <Card title="Model Registry" className="wide">
        <DataTable
          columns={[
            { key: "modelId", label: "Model Name" },
            { key: "workflowVersion", label: "Local Version" },
            { key: "owner", label: "Owner" },
            { key: "modelKind", label: "Type" },
            { key: "primaryMetricValue", label: "Primary Metric" },
            { key: "deploymentStatus", label: "Deployment", render: (row) => <StatusPill tone="green">{String(row.deploymentStatus)}</StatusPill> }
          ]}
          rows={data.modelRegistry}
          getRowKey={(row) => String(row.registryId)}
        />
      </Card>

      <Card title="Churn Prediction" className="right-panel detail-drawer">
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
          <span>Model Path</span><strong>{selected.artifactEvidence[0].artifactRef}</strong>
        </div>
        <h3>Artifacts (Stored on Disk)</h3>
        <ul className="artifact-list">
          {selected.artifactEvidence.map((artifact) => <li key={artifact.artifactRef}>{artifact.artifactRef}</li>)}
        </ul>
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
