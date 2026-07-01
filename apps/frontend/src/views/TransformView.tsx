import { useEffect, useMemo, useState } from "react";
import {
  Background,
  Controls,
  MiniMap,
  ReactFlow,
  addEdge,
  useEdgesState,
  useNodesState,
  type Connection,
  type Edge,
  type Node
} from "@xyflow/react";
import { Card, CodeBlock, DataTable, StatusPill } from "../components/ui";
import { InteractiveChart } from "../components/InteractiveChart";
import { localCode } from "../fixtures/local-fixtures";
import type { ActionFeedback, AppData } from "../types";

const paletteGroups = [
  { group: "Data Cleaning", items: ["Clean Missing Values", "Remove Duplicates", "Trim Text", "Outlier Handling", "Type Cast"] },
  { group: "Encoding", items: ["Encode Categorical", "One-Hot Encode", "Label Encode", "Target Encode"] },
  { group: "Feature Engineering", items: ["Create Date Features", "Binning", "Mathematical Transform", "Lag Window"] },
  { group: "Combine", items: ["Join Tables", "Union", "Append"] },
  { group: "Aggregate", items: ["Group And Aggregate", "Pivot", "Window Aggregate"] }
];

type PaletteNodeMetadata = {
  id: string;
  name: string;
  type: string;
  executionHint: string;
  config?: Record<string, unknown>;
};

function workflowNodesToFlowNodes(data: AppData): Node[] {
  return data.workflow.nodes.map((node, index) => ({
    id: node.id,
    type: "default",
    position: { x: (index % 4) * 230, y: Math.floor(index / 4) * 150 },
    data: {
      label: (
        <div className="flow-node-label">
          <strong>{node.name}</strong>
          <span>{node.type}</span>
        </div>
      )
    }
  }));
}

function workflowConnectionsToFlowEdges(data: AppData): Edge[] {
  return data.workflow.connections.map((connection, index) => ({
    id: `${connection.sourceNodeId}-${connection.targetNodeId}-${index}`,
    source: connection.sourceNodeId,
    target: connection.targetNodeId,
    animated: true,
    label: connection.dataType
  }));
}

function afterPreviewRows(rows: Array<Record<string, unknown>>) {
  return rows.map((row) => ({
    customer_id: row.customer_id,
    tenure_bucket: Number(row.tenure_months ?? 0) > 24 ? "established" : "new",
    monthly_charges_norm: typeof row.monthly_charges === "number" ? Number((row.monthly_charges / 120).toFixed(2)) : row.monthly_charges,
    contract_monthly: row.contract_type === "monthly" ? 1 : 0,
    churn: row.churn
  }));
}

function latestProjectTransformEvidence(data: AppData) {
  const record = [...data.dataScienceProject.transformFitApplyRecords]
    .sort((left, right) => right.createdAt.localeCompare(left.createdAt))[0];
  const job = [...data.dataScienceProject.projectJobs]
    .filter((item) => item.jobType === "transform_fit_apply")
    .filter((item) => !record || !item.sourceRecordId || item.sourceRecordId === record.transformRunId)
    .sort((left, right) => right.startedAt.localeCompare(left.startedAt))[0];
  return { record, job };
}

export function TransformView({
  data,
  onRun,
  feedback
}: {
  data: AppData;
  onRun: () => void;
  feedback?: ActionFeedback;
}) {
  const initialNodes = useMemo(() => workflowNodesToFlowNodes(data), [data]);
  const initialEdges = useMemo(() => workflowConnectionsToFlowEdges(data), [data]);
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);
  const [selectedNodeId, setSelectedNodeId] = useState(data.workflow.nodes.find((node) => node.id === "features")?.id ?? data.workflow.nodes[0]?.id ?? "");
  const [query, setQuery] = useState("");
  const [validationStatus, setValidationStatus] = useState<"valid" | "warning">("valid");
  const [nodeConfigs, setNodeConfigs] = useState<Record<string, { strategy: string; output: string }>>({});
  const [paletteNodes, setPaletteNodes] = useState<Record<string, PaletteNodeMetadata>>({});
  const latest = data.transformRuns[0];
  const workflowIdentity = `${data.workflow.workflowId}:${data.workflow.nodes.map((node) => node.id).join(",")}:${data.workflow.connections.map((connection) => `${connection.sourceNodeId}->${connection.targetNodeId}`).join(",")}`;
  const selectedNode = data.workflow.nodes.find((node) => node.id === selectedNodeId) ?? paletteNodes[selectedNodeId];
  const selectedConfig = nodeConfigs[selectedNodeId] ?? {
    strategy: String(selectedNode?.config?.strategy ?? "median"),
    output: String(selectedNode?.config?.output ?? "features")
  };
  const beforeRows = data.dataProfile.previewRows ?? [];
  const afterRows = afterPreviewRows(beforeRows);
  const projectEvidence = latestProjectTransformEvidence(data);
  const filteredPalette = paletteGroups.map((group) => ({
    ...group,
    items: group.items.filter((item) => item.toLowerCase().includes(query.toLowerCase()) || group.group.toLowerCase().includes(query.toLowerCase()))
  })).filter((group) => group.items.length > 0);

  useEffect(() => {
    setNodes(initialNodes);
    setEdges(initialEdges);
    setPaletteNodes({});
    setNodeConfigs({});
    setSelectedNodeId(data.workflow.nodes.find((node) => node.id === "features")?.id ?? data.workflow.nodes[0]?.id ?? "");
    setValidationStatus("valid");
  }, [workflowIdentity, initialNodes, initialEdges, setEdges, setNodes, data.workflow.nodes]);

  function onConnect(connection: Connection) {
    setEdges((current) => addEdge({ ...connection, animated: true }, current));
    setValidationStatus("warning");
  }

  function updateSelectedConfig(nextConfig: Partial<{ strategy: string; output: string }>) {
    setNodeConfigs((current) => ({
      ...current,
      [selectedNodeId]: {
        ...selectedConfig,
        ...nextConfig
      }
    }));
    setValidationStatus("warning");
  }

  function validatePipeline() {
    const hasDisconnectedEdit = nodes.length > 1 && edges.length === 0;
    setValidationStatus(hasDisconnectedEdit ? "warning" : "valid");
  }

  function runPipeline() {
    validatePipeline();
    onRun();
  }

  function addPaletteNode(label: string, group: string) {
    const id = `${label.toLowerCase().replace(/[^a-z0-9]+/g, "-")}-${nodes.length + 1}`;
    const metadata: PaletteNodeMetadata = {
      id,
      name: label,
      type: "custom.palette_node",
      executionHint: "cpu_only",
      config: {
        strategy: group,
        output: label.toLowerCase().replace(/[^a-z0-9]+/g, "_")
      }
    };
    setNodes((current) => [
      ...current,
      {
        id,
        type: "default",
        position: { x: 120 + (current.length % 3) * 220, y: 120 + Math.floor(current.length / 3) * 140 },
        data: {
          label: (
            <div className="flow-node-label">
              <strong>{label}</strong>
              <span>{group}</span>
            </div>
          )
        }
      }
    ]);
    setPaletteNodes((current) => ({ ...current, [id]: metadata }));
    setNodeConfigs((current) => ({
      ...current,
      [id]: {
        strategy: String(metadata.config?.strategy ?? "custom"),
        output: String(metadata.config?.output ?? "features")
      }
    }));
    setSelectedNodeId(id);
    setValidationStatus("warning");
  }

  return (
    <div className="route-grid transform-route">
      <section className="page-title">
        <div>
          <h1>Transform</h1>
          <p>Customer 360 Prep Pipeline. Build and run local feature pipelines with lineage, preview tables, and generated Julia transforms.</p>
        </div>
        <div className="button-row">
          <button type="button" className="jf-button secondary" onClick={validatePipeline}>
            Validate
          </button>
          <button type="button" className="jf-button primary" onClick={runPipeline}>Run Transform</button>
        </div>
      </section>
      {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

      <Card title="Transform Palette" eyebrow="Search grouped local transforms">
        <label className="search-field">
          <span>Search transforms</span>
          <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="clean, encode, join" />
        </label>
        <div className="library-list grouped">
          {filteredPalette.map((group) => (
            <section key={group.group}>
              <h3>{group.group}</h3>
              {group.items.map((item) => (
                <button type="button" key={item} onClick={() => addPaletteNode(item, group.group)}>
                  {item}
                </button>
              ))}
            </section>
          ))}
        </div>
      </Card>

      <Card title="Visual Transform Pipeline" eyebrow="React Flow local node canvas" className="wide transform-canvas-card">
        {nodes.length > 0 ? (
          <div className="flow-canvas" aria-label="Editable transform pipeline canvas">
            <ReactFlow
              nodes={nodes}
              edges={edges}
              onNodesChange={onNodesChange}
              onEdgesChange={onEdgesChange}
              onConnect={onConnect}
              onNodeClick={(_, node) => setSelectedNodeId(node.id)}
              fitView
            >
              <MiniMap pannable zoomable />
              <Controls />
              <Background gap={18} size={1} />
            </ReactFlow>
          </div>
        ) : (
          <p className="empty-state">Workflow metadata is unavailable. Re-import or save the workflow through the local gateway before rendering the live transform canvas.</p>
        )}
      </Card>

      <Card title="Transform Settings" className="right-panel">
        <div className="key-values wrap-values">
          <span>Node</span><strong>{selectedNode?.name ?? (selectedNodeId || "No node selected")}</strong>
          <span>Type</span><strong>{selectedNode?.type ?? "custom.palette_node"}</strong>
          <span>Execution</span><strong>{selectedNode?.executionHint ?? "cpu_only"}</strong>
          <span>Strategy</span><strong>{selectedConfig.strategy}</strong>
          <span>Output</span><strong>{selectedConfig.output}</strong>
        </div>
        <div className="control-panel-grid">
          <label>
            <span>Strategy</span>
            <select value={selectedConfig.strategy} onChange={(event) => updateSelectedConfig({ strategy: event.target.value })}>
              <option value="median">Median</option>
              <option value="mode">Mode</option>
              <option value="one_hot">One hot</option>
              <option value="standardize">Standardize</option>
            </select>
          </label>
          <label>
            <span>Output column prefix</span>
            <input value={selectedConfig.output} onChange={(event) => updateSelectedConfig({ output: event.target.value })} />
          </label>
        </div>
      </Card>

      <Card title="Validation And Run Evidence">
        <div className="quality-list">
          <div>
            <StatusPill tone={validationStatus === "valid" ? "green" : "orange"}>{validationStatus}</StatusPill>
            <strong>{validationStatus === "valid" ? "Pipeline is locally valid" : "Unsaved canvas edits detected"}</strong>
            <span>{validationStatus === "valid" ? latest?.validation?.messages.join(" ") ?? "Pipeline canvas is connected." : "Validate before run to persist the canvas configuration."}</span>
          </div>
          <div>
            <StatusPill tone={latest?.status === "completed" ? "green" : "orange"}>{latest?.status ?? "not run"}</StatusPill>
            <strong>{latest?.checkpointTag ?? "No checkpoint yet"}</strong>
            <span>{latest ? `${latest.stageCount} stages, ${latest.nodeResults.length} node results` : "Run the transform pipeline to create local artifacts."}</span>
          </div>
        </div>
      </Card>

      <Card title="Project Transform Evidence" className="right-panel">
        {projectEvidence.record ? (
          <div className="key-values wrap-values">
            <span>Transform Run</span><strong>{projectEvidence.record.transformRunId}</strong>
            <span>Fit Split</span><strong>{projectEvidence.record.fitSplit}</strong>
            <span>Apply Splits</span><strong>{projectEvidence.record.applySplits.join(", ")}</strong>
            <span>Leakage Checks</span><strong>{projectEvidence.record.leakageChecks.map((check) => check.status).join(", ")}</strong>
            <span>Job</span><strong>{projectEvidence.job?.jobId ?? "No project job linked"}</strong>
            <span>Execution</span><strong>{projectEvidence.job?.executionEvidence?.executionId ?? "pending"}</strong>
          </div>
        ) : (
          <p className="empty-state">
            No project-backed transform fit/apply evidence is attached yet. Run the project transform workflow through the local gateway to record train-only fitting and held-out split application.
          </p>
        )}
      </Card>

      <Card title="Pipeline Metrics" eyebrow="Julia-generated Plotly specs" className="right-panel">
        {(latest?.charts ?? []).map((spec) => (
          <InteractiveChart key={spec.chartId} spec={spec} compact />
        ))}
      </Card>

      <Card title="Lineage And History">
        <DataTable
          columns={[
            { key: "runId", label: "Run" },
            { key: "checkpointTag", label: "Checkpoint" },
            { key: "status", label: "Status", render: (row) => <StatusPill tone={String(row.status) === "completed" ? "green" : "orange"}>{String(row.status)}</StatusPill> },
            { key: "stageCount", label: "Stages" }
          ]}
          rows={data.transformRuns}
          getRowKey={(row) => String(row.runId)}
        />
      </Card>

      <Card title="Before And After Preview" className="wide">
        <div className="preview-split">
          <section>
            <h3>Before</h3>
            <DataTable
              columns={[
                { key: "customer_id", label: "Customer" },
                { key: "tenure_months", label: "Tenure" },
                { key: "monthly_charges", label: "Monthly" },
                { key: "contract_type", label: "Contract" },
                { key: "churn", label: "Churn" }
              ]}
              rows={beforeRows}
              getRowKey={(row, index) => `${String(row.customer_id ?? "row")}-before-${index}`}
            />
          </section>
          <section>
            <h3>After</h3>
            <DataTable
              columns={[
                { key: "customer_id", label: "Customer" },
                { key: "tenure_bucket", label: "Bucket" },
                { key: "monthly_charges_norm", label: "Norm" },
                { key: "contract_monthly", label: "Monthly Flag" },
                { key: "churn", label: "Churn" }
              ]}
              rows={afterRows}
              getRowKey={(row, index) => `${String(row.customer_id ?? "row")}-after-${index}`}
            />
          </section>
        </div>
      </Card>

      <Card title="Artifact Output">
        <div className="lineage-list">
          {(latest?.artifactEvidence ?? []).map((artifact) => (
            <div key={artifact.nodeId}>
              <span>{artifact.nodeId}</span>
              <strong>{artifact.artifactRefs.length} artifacts</strong>
              {artifact.artifactRefs.map((ref) => <small key={ref}>{ref}</small>)}
            </div>
          ))}
        </div>
      </Card>

      <Card title="Generated Julia Code" className="wide">
        <CodeBlock label="transforms/feature_engineering.jl">{localCode.transform}</CodeBlock>
      </Card>

      <Card title="Logs" className="wide">
        <CodeBlock label="transform.log">{`[info] selected node: ${selectedNode?.id ?? selectedNodeId}
[info] validation: ${validationStatus}
[info] selected config: ${JSON.stringify(selectedConfig)}
[info] latest run status: ${latest?.status ?? "not-run"}
[info] output: data/features/churn_features.parquet`}</CodeBlock>
      </Card>
    </div>
  );
}
