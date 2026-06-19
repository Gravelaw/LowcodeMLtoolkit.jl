import { Card, CodeBlock, DataTable, StatusPill } from "../components/ui";
import { localCode } from "../fixtures/local-fixtures";
import type { ActionFeedback, AppData } from "../types";

export function TransformView({
  data,
  onRun,
  feedback
}: {
  data: AppData;
  onRun: () => void;
  feedback?: ActionFeedback;
}) {
  const latest = data.transformRuns[0];
  return (
    <div className="route-grid transform-route">
      <section className="page-title">
        <div>
          <h1>Transform</h1>
          <p>Build local feature pipelines with lineage, preview tables, and generated Julia transforms.</p>
        </div>
        <button type="button" className="jf-button primary" onClick={onRun}>Run Transform</button>
      </section>
      {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

      <Card title="Visual Transform Pipeline" className="wide">
        <div className="pipeline">
          {data.workflow.nodes.map((node, index) => (
            <div className="pipeline-node" key={node.id}>
              <span>{index + 1}</span>
              <strong>{node.name}</strong>
              <small>{node.type}</small>
            </div>
          ))}
        </div>
      </Card>

      <Card title="Transform Library">
        <div className="library-list">
          {["Clean missing values", "One-hot encode", "Window aggregate", "Normalize columns", "Write Arrow IPC"].map((item) => (
            <button type="button" key={item}>{item}</button>
          ))}
        </div>
      </Card>

      <Card title="Selected Node Settings" className="right-panel">
        <div className="key-values">
          <span>Node</span><strong>Feature Engineering</strong>
          <span>Imputation</span><strong>Median</strong>
          <span>Encoding</span><strong>One hot</strong>
          <span>Output</span><strong>features/churn_features.parquet</strong>
        </div>
      </Card>

      <Card title="Lineage And History">
        <DataTable
          columns={[
            { key: "runId", label: "Run" },
            { key: "checkpointTag", label: "Checkpoint" },
            { key: "status", label: "Status", render: (row) => <StatusPill tone="green">{String(row.status)}</StatusPill> },
            { key: "stageCount", label: "Stages" }
          ]}
          rows={data.transformRuns}
          getRowKey={(row) => String(row.runId)}
        />
      </Card>

      <Card title="Preview Tables" className="wide">
        {latest ? (
          <DataTable
            columns={[
              { key: "nodeId", label: "Node" },
              { key: "nodeType", label: "Type" },
              { key: "rowCount", label: "Rows" },
              { key: "artifactRefs", label: "Artifacts", render: (row) => String(row.artifactRefs).replace(",", ", ") }
            ]}
            rows={latest.nodeResults}
            getRowKey={(row) => String(row.nodeId)}
          />
        ) : (
          <p className="empty-state">No transform run artifacts have been returned by the backend yet.</p>
        )}
      </Card>

      <Card title="Generated Julia Code" className="wide">
        <CodeBlock label="transforms/feature_engineering.jl">{localCode.transform}</CodeBlock>
      </Card>
    </div>
  );
}
