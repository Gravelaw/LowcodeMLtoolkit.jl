import { Card, DataTable, StatusPill } from "../components/ui";
import type { ActionFeedback, AppData } from "../types";

function datasetRows(data: AppData) {
  const datasetKey = data.dashboard.binding.datasetKey;
  return data.dashboard.datasets?.[datasetKey] ?? [];
}

function firstDisplayColumn(rows: Array<Record<string, unknown>>, fallback: string): string {
  return Object.keys(rows[0] ?? {}).find((key) => key !== fallback) ?? fallback;
}

function uniqueDisplayColumns(rows: Array<Record<string, unknown>>, candidates: string[]): string[] {
  const rowColumns = Object.keys(rows[0] ?? {});
  const selected: string[] = [];
  for (const candidate of [...candidates, ...rowColumns]) {
    if (candidate && !selected.includes(candidate)) selected.push(candidate);
    if (selected.length === 3) break;
  }
  return selected.length > 0 ? selected : ["record"];
}

export function VisualizeView({
  data,
  onExport,
  feedback
}: {
  data: AppData;
  onExport: () => void;
  feedback?: ActionFeedback;
}) {
  const rows = datasetRows(data);
  const primaryChart = data.dashboard.charts[0];
  const xField = primaryChart?.xField ?? firstDisplayColumn(rows, "customer_id");
  const yField = primaryChart?.yField ?? firstDisplayColumn(rows, "churn_risk");
  const idField = firstDisplayColumn(rows, xField);
  const tableColumns = uniqueDisplayColumns(rows, [idField, xField, yField]);

  return (
    <div className="route-grid visualize-route">
      <section className="page-title">
        <div>
          <h1>Visualize</h1>
          <p>Build dashboard snapshots from local datasets and checkpoint them for reproducibility.</p>
        </div>
        <button type="button" className="jf-button primary" onClick={onExport}>Save Local Checkpoint</button>
      </section>
      {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

      <Card title="Dataset And Columns">
        <ul className="column-list">
          {data.dataProfile.schemaSummary.map((field) => (
            <li key={field.name}><strong>{field.name}</strong><span>{field.type}</span></li>
          ))}
        </ul>
      </Card>

      <Card title="Dashboard Builder" className="wide dashboard-canvas">
        <div className="chart-grid">
          <div className="chart-card"><strong>{primaryChart?.title ?? "No chart configured"}</strong><div className="bar-chart" /></div>
          <div className="chart-card"><strong>{data.dashboard.name}</strong><div className="line-chart" /></div>
          <div className="chart-card"><strong>Artifact Rows</strong><span className="big-number">{rows.length.toLocaleString()}</span><small>{data.dashboard.binding.datasetKey}</small></div>
        </div>
        {rows.length === 0 ? (
          <p className="empty-state">No artifact-backed dashboard rows are available for this published dashboard. Run the workflow and publish a dashboard snapshot with persisted dataset rows.</p>
        ) : (
          <DataTable
            columns={[
              { key: tableColumns[0], label: "Record" },
              ...tableColumns.slice(1).map((key) => ({ key, label: key }))
            ]}
            rows={rows.slice(0, 3)}
            getRowKey={(row, index) => `${String(row[idField] ?? "row")}-${index}`}
          />
        )}
      </Card>

      <Card title="Chart Properties" className="right-panel">
        <div className="key-values">
          <span>Chart</span><strong>{primaryChart?.title ?? "No chart configured"}</strong>
          <span>X Field</span><strong>{xField}</strong>
          <span>Y Field</span><strong>{yField}</strong>
          <span>Dataset</span><strong>{data.dashboard.binding.datasetKey}</strong>
          <span>Refresh</span><strong>Manual local</strong>
        </div>
        <StatusPill tone={rows.length > 0 ? "green" : "neutral"}>{rows.length > 0 ? "Artifact rows ready" : "No artifact rows"}</StatusPill>
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
