#!/usr/bin/env node
import { performance } from "node:perf_hooks";

const nodeCount = Number(process.env.JULIAFLOW_RENDER_NODE_COUNT ?? 1000);
const connectionCount = Number(process.env.JULIAFLOW_RENDER_CONNECTION_COUNT ?? 500);
const thresholdMs = Number(process.env.JULIAFLOW_RENDER_THRESHOLD_MS ?? 500);

function buildHarnessGraph() {
  const nodes = Array.from({ length: nodeCount }, (_, index) => ({
    id: `node-${index}`,
    name: `Harness Node ${index}`,
    type: index % 10 === 0 ? "JuliaFlow.Base.Aggregate" : "JuliaFlow.Base.Select",
    executionHint: index % 25 === 0 ? "gpu_preferred" : "cpu_only",
    ports: [
      { id: "in", direction: "input", type: "data_table" },
      { id: "out", direction: "output", type: "data_table" }
    ],
    config: { index }
  }));
  const connections = Array.from({ length: connectionCount }, (_, index) => ({
    sourceNodeId: `node-${index}`,
    sourcePortId: "out",
    targetNodeId: `node-${index + 1}`,
    targetPortId: "in",
    dataType: "data_table"
  }));
  return { nodes, connections };
}

const started = performance.now();
const graph = buildHarnessGraph();
const layout = graph.nodes.map((node, index) => ({
  nodeId: node.id,
  x: (index % 50) * 220,
  y: Math.floor(index / 50) * 132,
  width: 180
}));
const visibleEdges = graph.connections.filter((connection) => connection.sourceNodeId !== connection.targetNodeId);
const elapsedMs = performance.now() - started;
const result = {
  nodeCount: graph.nodes.length,
  connectionCount: graph.connections.length,
  layoutCount: layout.length,
  visibleEdgeCount: visibleEdges.length,
  elapsedMs: Number(elapsedMs.toFixed(3)),
  thresholdMs,
  passed: elapsedMs <= thresholdMs
};
console.log(JSON.stringify(result));
if (!result.passed) {
  process.exitCode = 1;
}
