import { Card, CodeBlock, DataTable, MetricCard, StatusPill } from "../components/ui";
import { localCode } from "../fixtures/local-fixtures";
import type { ActionFeedback, AppData } from "../types";

function formatMetric(value: unknown): string {
  return typeof value === "number" && Number.isFinite(value) ? value.toFixed(3) : "n/a";
}

export function MlStudioView({
  data,
  onRun,
  feedback
}: {
  data: AppData;
  onRun: () => void;
  feedback?: ActionFeedback;
}) {
  const experiment = data.mlExperiments[0];
  if (!experiment) {
    return (
      <div className="route-grid ml-route">
        <section className="page-title">
          <div>
            <h1>ML Studio</h1>
            <p>Train local MLJ pipelines with reproducible metrics, explainability, and hardware fallback evidence.</p>
          </div>
          <button type="button" className="jf-button primary" onClick={onRun}>Train New Model</button>
        </section>
        {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

        <Card title="No ML Experiments Yet" className="wide">
          <p className="empty-state">
            No backend ML experiment records are available for this workspace yet. Train a model after the local gateway is ready, then this screen will show algorithm settings, metrics, feature importance, hardware evidence, and reproducibility details.
          </p>
        </Card>
      </div>
    );
  }

  return (
    <div className="route-grid ml-route">
      <section className="page-title">
        <div>
          <h1>ML Studio</h1>
          <p>Train local MLJ pipelines with reproducible metrics, explainability, and hardware fallback evidence.</p>
        </div>
        <button type="button" className="jf-button primary" onClick={onRun}>Train New Model</button>
      </section>
      {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

      <Card title="Algorithm Config">
        <div className="key-values">
          <span>Framework</span><strong>MLJ.jl</strong>
          <span>Algorithm</span><strong>{experiment.modelKind}</strong>
          <span>Target</span><strong>{experiment.target}</strong>
          <span>Seed</span><strong>42</strong>
        </div>
      </Card>

      <div className="metrics-row compact">
        <MetricCard label="AUC" value={formatMetric(experiment.metrics.auc)} detail="validation fold" />
        <MetricCard label="F1 Score" value={formatMetric(experiment.metrics.f1)} detail="threshold 0.42" tone="blue" />
        <MetricCard label="Precision" value={formatMetric(experiment.metrics.precision)} detail="local test split" tone="green" />
        <MetricCard label="Recall" value={formatMetric(experiment.metrics.recall)} detail="local test split" tone="orange" />
      </div>

      <Card title="ROC, Confusion, Feature Importance" className="wide">
        <div className="chart-grid">
          <div className="chart-card"><strong>ROC Curve</strong><div className="line-chart" /></div>
          <div className="chart-card"><strong>Confusion Matrix</strong><div className="matrix"><span>812</span><span>47</span><span>68</span><span>421</span></div></div>
          <div className="chart-card">
            <strong>Feature Importance</strong>
            {experiment.featureImportance.map((feature) => (
              <label className="bar-row" key={feature.feature}>
                <span>{feature.feature}</span>
                <meter value={feature.importance} min={0} max={0.4} />
              </label>
            ))}
          </div>
        </div>
      </Card>

      <Card title="Experiment Tracker">
        <DataTable
          columns={[
            { key: "experimentId", label: "Experiment" },
            { key: "checkpointTag", label: "Checkpoint" },
            { key: "status", label: "Status", render: (row) => <StatusPill tone="green">{String(row.status)}</StatusPill> },
            { key: "hardwareBackend", label: "Hardware" }
          ]}
          rows={data.mlExperiments}
          getRowKey={(row) => String(row.experimentId)}
        />
      </Card>

      <Card title="Hardware And Hyperparameters" className="right-panel">
        <div className="key-values">
          <span>Backend</span><strong>{experiment.hardwareBackend}</strong>
          <span>GPU</span><strong>{experiment.gpuReadinessStatus}</strong>
          <span>Data</span><strong>{experiment.datasetId}</strong>
          <span>Bundle</span><strong>ready</strong>
        </div>
      </Card>

      <Card title="MLJ Pipeline" className="wide">
        <CodeBlock label="models/train_churn.jl">{localCode.ml}</CodeBlock>
      </Card>
    </div>
  );
}
