import { ActionFeedbackStatus, Card, CodeBlock, DataTable, StatusPill } from "../components/ui";
import { churnRows, localCode } from "../fixtures/local-fixtures";
import type { ActionFeedback, AppData } from "../types";

export function DataView({
  data,
  onImport,
  feedback
}: {
  data: AppData;
  onImport: () => void;
  feedback?: ActionFeedback;
}) {
  return (
    <div className="route-grid data-route">
      <section className="page-title">
        <div>
          <h1>Data</h1>
          <p>Profile, store, and query local datasets with Arrow, Parquet, and DuckDB evidence.</p>
        </div>
        <button type="button" className="jf-button primary" onClick={onImport}>Import Local Data</button>
      </section>
      <ActionFeedbackStatus feedback={feedback} />

      <Card title="Local Source Selector" eyebrow="Device only">
        <div className="source-grid">
          <button type="button" className="source-card active">CSV file<br /><small>data/raw/churn.csv</small></button>
          <button type="button" className="source-card">Arrow IPC<br /><small>customer-churn-local.arrow</small></button>
          <button type="button" className="source-card">DuckDB view<br /><small>local_data_estate.sql</small></button>
        </div>
      </Card>

      <Card title="Dataset Rows" className="wide">
        <DataTable
          columns={[
            { key: "customer_id", label: "Customer" },
            { key: "tenure_months", label: "Tenure" },
            { key: "monthly_charges", label: "Monthly Charges" },
            { key: "contract_type", label: "Contract" },
            { key: "churn_risk", label: "Risk" },
            { key: "label", label: "Label" }
          ]}
          rows={churnRows}
          getRowKey={(row) => row.customer_id}
        />
      </Card>

      <Card title="Profile Summary">
        <div className="profile-cards">
          <div><span>Rows</span><strong>{data.dataProfile.rowCount.toLocaleString()}</strong></div>
          <div><span>Checksum</span><strong>{data.dataProfile.checksumSha256.slice(0, 12)}</strong></div>
          <div><span>DuckDB</span><strong>{data.dataProfile.duckdbStatus}</strong></div>
          <div><span>Manifest</span><strong>{data.dataProfile.manifestReady ? "ready" : "pending"}</strong></div>
        </div>
      </Card>

      <Card title="Field Quality">
        <DataTable
          columns={[
            { key: "name", label: "Field" },
            { key: "type", label: "Type" },
            { key: "quality", label: "Quality" }
          ]}
          rows={data.dataProfile.profileSummary}
          getRowKey={(row) => String(row.name)}
        />
      </Card>

      <Card title="Data Handling Guarantees" className="right-panel">
        <ul className="check-list">
          <li>Source read from local filesystem</li>
          <li>Arrow IPC boundary preserved</li>
          <li>Parquet artifact stored in managed zone</li>
          <li>No connector requires cloud credentials</li>
        </ul>
        <StatusPill tone="green">Local only</StatusPill>
      </Card>

      <Card title="Generated Julia Code" className="wide">
        <CodeBlock label="data/import_profile.jl">{localCode.data}</CodeBlock>
      </Card>
    </div>
  );
}
