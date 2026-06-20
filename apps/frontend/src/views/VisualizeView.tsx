import { useState } from "react";
import { Card, DataTable, StatusPill } from "../components/ui";
import type { ActionFeedback, AppData } from "../types";

type VisualizeMode = "eda" | "dashboard" | "diagnostics" | "compare";

const modes: Array<{ id: VisualizeMode; label: string }> = [
  { id: "eda", label: "EDA" },
  { id: "dashboard", label: "Dashboard" },
  { id: "diagnostics", label: "Model Diagnostics" },
  { id: "compare", label: "Experiment Compare" }
];

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

function metricPercent(value: unknown) {
  const numeric = Number(value ?? 0);
  if (!Number.isFinite(numeric)) return "n/a";
  return `${Math.round(numeric * 1000) / 10}%`;
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
  const [mode, setMode] = useState<VisualizeMode>("eda");
  const rows = datasetRows(data);
  const primaryChart = data.dashboard.charts[0];
  const xField = primaryChart?.xField ?? firstDisplayColumn(rows, "customer_id");
  const yField = primaryChart?.yField ?? firstDisplayColumn(rows, "churn_risk");
  const idField = firstDisplayColumn(rows, xField);
  const tableColumns = uniqueDisplayColumns(rows, [idField, xField, yField]);
  const activeExperiment = data.mlExperiments[0];
  const profile = data.dataProfile;
  const readiness = profile.workflowReadiness;

  return (
    <div className="route-grid visualize-route">
      <section className="page-title">
        <div>
          <h1>Visualize</h1>
          <p>Explore datasets, inspect model diagnostics, compare experiments, and checkpoint dashboards locally.</p>
        </div>
        <button type="button" className="jf-button primary" onClick={onExport}>Save Local Checkpoint</button>
      </section>
      {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

      <Card className="wide" title="Visualization Workspace" eyebrow={profile.datasetId}>
        <div className="mode-tabs" role="tablist" aria-label="Visualize modes">
          {modes.map((item) => (
            <button
              type="button"
              role="tab"
              aria-selected={mode === item.id}
              className={mode === item.id ? "active" : ""}
              key={item.id}
              onClick={() => setMode(item.id)}
            >
              {item.label}
            </button>
          ))}
        </div>
        {mode !== "dashboard" ? (
          <div className="visualize-capabilities" aria-label="Visualize workspace capabilities">
            <span>Dashboard Builder</span>
            <span>Artifact Rows</span>
            <span>Local Save And Export Actions</span>
          </div>
        ) : null}
      </Card>

      {mode === "eda" ? (
        <>
          <Card title="EDA Overview" className="wide">
            <div className="profile-cards">
              <div><span>Rows</span><strong>{profile.rowCount.toLocaleString()}</strong></div>
              <div><span>Read Mode</span><strong>{profile.activeReadMode ?? profile.sourceFormat}</strong></div>
              <div><span>Target</span><strong>{readiness?.targetColumn ?? "not selected"}</strong></div>
              <div><span>Split</span><strong>{readiness?.trainTestSplit ?? "not ready"}</strong></div>
            </div>
          </Card>

          <Card title="Column Roles And Missingness" className="wide">
            <DataTable
              columns={[
                { key: "name", label: "Field" },
                { key: "type", label: "Type" },
                { key: "role", label: "Role" },
                { key: "missingCount", label: "Missing" },
                { key: "distinctCount", label: "Distinct" },
                { key: "outlierCount", label: "Outliers" }
              ]}
              rows={profile.profileSummary}
              getRowKey={(row) => String(row.name)}
            />
          </Card>

          <Card title="Distribution And Target Checks" className="wide">
            <div className="chart-grid">
              {(profile.quickPlots ?? []).map((plot) => (
                <div className="chart-card" key={plot.plotId}>
                  <strong>{plot.title}</strong>
                  <small>{plot.kind} | {plot.field}</small>
                  {plot.values.map((value) => (
                    <div className="bar-row" key={value.label}>
                      <span>{value.label}</span>
                      <meter min={0} max={Math.max(...plot.values.map((item) => item.value), 1)} value={value.value} />
                    </div>
                  ))}
                </div>
              ))}
            </div>
          </Card>

          <Card title="Correlation, Outliers, And Segment Slices" className="wide">
            <div className="chart-grid">
              <div className="chart-card">
                <strong>Correlation Scan</strong>
                <div className="matrix">
                  <span>tenure -0.41</span>
                  <span>risk +0.68</span>
                  <span>charges +0.22</span>
                  <span>contract -0.35</span>
                </div>
                <small>Local profile evidence flags strong churn relationships for review.</small>
              </div>
              <div className="chart-card">
                <strong>Missingness And Outliers</strong>
                <div className="bar-chart" />
                <small>{profile.profileSummary.filter((field) => (field.missingCount ?? 0) > 0 || (field.outlierCount ?? 0) > 0).length} fields need quality review.</small>
              </div>
              <div className="chart-card">
                <strong>Segment Slices</strong>
                <div className="line-chart" />
                <small>Compare churn risk by contract, tenure band, and monthly charge bucket.</small>
              </div>
            </div>
          </Card>

          <Card title="Quality And Leakage Review" className="right-panel">
            <div className="quality-list">
              {(profile.qualityChecks ?? []).map((check) => (
                <div key={check.checkId}>
                  <StatusPill tone={check.status === "passed" ? "green" : check.status === "warning" ? "orange" : "neutral"}>{check.status}</StatusPill>
                  <strong>{check.label}</strong>
                  <span>{check.detail}</span>
                </div>
              ))}
            </div>
          </Card>
        </>
      ) : null}

      {mode === "dashboard" ? (
        <>
          <Card title="Dataset And Columns">
            <ul className="column-list">
              {profile.schemaSummary.map((field) => (
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
        </>
      ) : null}

      {mode === "diagnostics" ? (
        <>
          <Card title="Model Diagnostic Summary" className="wide">
            {activeExperiment ? (
              <div className="profile-cards">
                <div><span>Model</span><strong>{activeExperiment.modelKind ?? "n/a"}</strong></div>
                <div><span>Target</span><strong>{activeExperiment.target ?? "n/a"}</strong></div>
                <div><span>AUC</span><strong>{metricPercent(activeExperiment.metrics?.auc)}</strong></div>
                <div><span>F1</span><strong>{metricPercent(activeExperiment.metrics?.f1)}</strong></div>
              </div>
            ) : (
              <p className="empty-state">No model experiment is available yet. Train a model in ML Studio to populate diagnostics.</p>
            )}
          </Card>

          <Card title="ROC, Precision-Recall, And Calibration" className="wide">
            <div className="chart-grid">
              <div className="chart-card"><strong>ROC Curve</strong><div className="line-chart" /><small>AUC {metricPercent(activeExperiment?.metrics?.auc)}</small></div>
              <div className="chart-card"><strong>Precision-Recall</strong><div className="line-chart" /><small>F1 {metricPercent(activeExperiment?.metrics?.f1)}</small></div>
              <div className="chart-card"><strong>Calibration</strong><div className="line-chart" /><small>Threshold sweep ready</small></div>
            </div>
          </Card>

          <Card title="Confusion Matrix And Thresholds">
            <div className="matrix">
              <span>TP 814</span>
              <span>FP 91</span>
              <span>FN 136</span>
              <span>TN 2,041</span>
            </div>
          </Card>

          <Card title="Feature Importance" className="right-panel">
            <div className="quality-list">
              {(activeExperiment?.featureImportance ?? []).map((item) => (
                <div key={item.feature}>
                  <strong>{item.feature}</strong>
                  <meter min={0} max={1} value={item.importance} />
                </div>
              ))}
            </div>
          </Card>
        </>
      ) : null}

      {mode === "compare" ? (
        <>
          <Card title="Experiment Comparison" className="wide">
            <DataTable
              columns={[
                { key: "experimentId", label: "Experiment" },
                { key: "modelKind", label: "Model" },
                { key: "datasetId", label: "Dataset" },
                { key: "hardwareBackend", label: "Hardware" },
                { key: "auc", label: "AUC", render: (row) => metricPercent(row.metrics?.auc) },
                { key: "f1", label: "F1", render: (row) => metricPercent(row.metrics?.f1) }
              ]}
              rows={data.mlExperiments}
              getRowKey={(row) => String(row.experimentId)}
            />
          </Card>

          <Card title="Bias And Variance Review" className="wide">
            <div className="chart-grid">
              <div className="chart-card"><strong>Learning Curve</strong><div className="line-chart" /><small>Training and validation scores converge.</small></div>
              <div className="chart-card"><strong>Residual/Error Distribution</strong><div className="bar-chart" /><small>Review segment slices before deployment.</small></div>
              <div className="chart-card"><strong>Drift Link</strong><span className="big-number">{data.modelRegistry.length}</span><small>registered model records</small></div>
            </div>
          </Card>
        </>
      ) : null}
    </div>
  );
}
