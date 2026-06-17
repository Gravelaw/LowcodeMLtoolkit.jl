import { ActionFeedbackStatus, Card, DataTable, StatusPill } from "../components/ui";
import { churnRows } from "../fixtures/local-fixtures";
import type { ActionFeedback, AppData } from "../types";

export function VisualizeView({
  data,
  onExport,
  feedback
}: {
  data: AppData;
  onExport: () => void;
  feedback?: ActionFeedback;
}) {
  return (
    <div className="route-grid visualize-route">
      <section className="page-title">
        <div>
          <h1>Visualize</h1>
          <p>Build dashboard snapshots from local datasets and checkpoint them for reproducibility.</p>
        </div>
        <button type="button" className="jf-button primary" onClick={onExport}>Save Local Checkpoint</button>
      </section>
      <ActionFeedbackStatus feedback={feedback} />

      <Card title="Dataset And Columns">
        <ul className="column-list">
          {data.dataProfile.schemaSummary.map((field) => (
            <li key={field.name}><strong>{field.name}</strong><span>{field.type}</span></li>
          ))}
        </ul>
      </Card>

      <Card title="Dashboard Builder" className="wide dashboard-canvas">
        <div className="chart-grid">
          <div className="chart-card"><strong>Churn Risk By Contract</strong><div className="bar-chart" /></div>
          <div className="chart-card"><strong>Retention Trend</strong><div className="line-chart" /></div>
          <div className="chart-card"><strong>Local Metric</strong><span className="big-number">12,500</span><small>rows in local profile</small></div>
        </div>
        <DataTable
          columns={[
            { key: "customer_id", label: "Customer" },
            { key: "contract_type", label: "Contract" },
            { key: "churn_risk", label: "Risk" }
          ]}
          rows={churnRows.slice(0, 3)}
          getRowKey={(row) => row.customer_id}
        />
      </Card>

      <Card title="Chart Properties" className="right-panel">
        <div className="key-values">
          <span>Chart</span><strong>Risk Distribution</strong>
          <span>X Field</span><strong>contract_type</strong>
          <span>Y Field</span><strong>churn_risk</strong>
          <span>Refresh</span><strong>Manual local</strong>
        </div>
        <StatusPill tone="green">Local export enabled</StatusPill>
      </Card>

      <Card title="Local Save And Export Actions" className="wide">
        <DataTable
          columns={[
            { key: "exportId", label: "Export" },
            { key: "checkpointTag", label: "Checkpoint" },
            { key: "bundleId", label: "Bundle" },
            { key: "localOnly", label: "Mode", render: () => <StatusPill tone="green">local only</StatusPill> }
          ]}
          rows={data.visualizeExports}
          getRowKey={(row) => String(row.exportId)}
        />
      </Card>
    </div>
  );
}
