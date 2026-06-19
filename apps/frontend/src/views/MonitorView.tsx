import { Card, DataTable, StatusPill } from "../components/ui";
import type { AppData } from "../types";

function statusTone(status: string): "green" | "blue" | "orange" | "neutral" {
  if (status === "completed") return "green";
  if (status === "running") return "blue";
  if (status === "accepted" || status === "queued") return "orange";
  return "neutral";
}

function formatNodes(nodes: string[]): string {
  return nodes.length > 0 ? nodes.join(", ") : "None";
}

function modelArtifactRefs(data: AppData): string[] {
  const latestExecution = data.executions[0];
  const nodeRefs = latestExecution?.executorState?.nodeResults
    ?.filter((result) => result.outputKind === "node" && result.nodeType.includes("ml"))
    .flatMap((result) => result.outputRefs) ?? [];
  return nodeRefs.length > 0 ? nodeRefs : data.modelRegistry[0]?.artifactEvidence.map((artifact) => artifact.artifactRef) ?? [];
}

export function MonitorView({ data }: { data: AppData }) {
  const latestExecution = data.executions[0];
  const nodeResults = latestExecution?.executorState?.nodeResults ?? [];
  const explainability = latestExecution?.explainabilityEvidence;
  const artifactRefs = modelArtifactRefs(data);
  const primaryMetric = explainability
    ? Object.entries(explainability.modelCard.metrics)[0]
    : undefined;

  return (
    <div className="route-grid monitor-route">
      <section className="page-title">
        <div>
          <span className="title-icon">Monitor</span>
          <h1>Execution Monitor</h1>
          <p>Backend execution records and runtime evidence for the local workflow lifecycle.</p>
        </div>
        {latestExecution ? <StatusPill tone={statusTone(latestExecution.status)}>{latestExecution.status}</StatusPill> : null}
      </section>

      <Card title="Execution Records" className="wide" eyebrow={data.runtime.fixtureSubstitutionAllowed ? "demo-permitted" : "backend-only"}>
        {data.executions.length === 0 ? (
          <p className="empty-state">No backend execution records are available for this workspace yet. Run the workflow from Explorer after the local gateway is ready.</p>
        ) : (
          <DataTable
            columns={[
              { key: "executionId", label: "Execution" },
              { key: "workflowId", label: "Workflow" },
              { key: "status", label: "Status", render: (row) => <StatusPill tone={statusTone(String(row.status))}>{String(row.status)}</StatusPill> },
              { key: "mode", label: "Mode" },
              { key: "updatedAt", label: "Updated" }
            ]}
            rows={data.executions}
            getRowKey={(row) => row.executionId}
          />
        )}
      </Card>

      <Card title="Latest Execution">
        {latestExecution ? (
          <div className="key-values">
            <span>Execution ID</span><strong>{latestExecution.executionId}</strong>
            <span>Checkpoint</span><strong>{latestExecution.checkpointTag}</strong>
            <span>Plan</span><strong>{formatNodes(latestExecution.plan)}</strong>
            <span>Completed Nodes</span><strong>{formatNodes(latestExecution.executorState?.completedNodeIds ?? [])}</strong>
          </div>
        ) : (
          <p className="empty-state">Monitor is waiting for a real execution id from the gateway.</p>
        )}
      </Card>

      <Card title="Node Results" className="right-panel">
        {nodeResults.length === 0 ? (
          <p className="empty-state">No executor node results are attached to the latest execution.</p>
        ) : (
          <ul className="activity-list">
            {nodeResults.map((result) => (
              <li key={result.nodeId}>
                <span>{result.nodeId}</span>
                <strong>{result.rowCount} rows</strong>
              </li>
            ))}
          </ul>
        )}
      </Card>

      <Card title="Executed Explainability Evidence" className="wide">
        {latestExecution && explainability ? (
          <div className="key-values">
            <span>Execution</span><strong>{latestExecution.executionId}</strong>
            <span>Workflow</span><strong>{explainability.workflowId}</strong>
            <span>Dataset Checksum</span><strong>{explainability.datasetCard.checksumSha256.slice(0, 12)}</strong>
            <span>Model Artifact</span><strong>{artifactRefs[0] ?? "No model artifact ref"}</strong>
            <span>Metric</span><strong>{primaryMetric ? `${primaryMetric[0]} ${primaryMetric[1]}` : "No metric"}</strong>
            <span>Explanation</span><strong>{explainability.explanation.method}</strong>
          </div>
        ) : (
          <p className="empty-state">No executed-run explainability evidence is attached to the latest execution.</p>
        )}
      </Card>
    </div>
  );
}
