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

export function MonitorView({ data }: { data: AppData }) {
  const latestExecution = data.executions[0];
  const nodeResults = latestExecution?.executorState?.nodeResults ?? [];

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
    </div>
  );
}
