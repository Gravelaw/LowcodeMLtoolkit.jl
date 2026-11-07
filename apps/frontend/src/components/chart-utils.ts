import type { GatewayInteractiveChartSpec } from "@juliaflow/contracts";

export type ChartReadiness = "ready" | "empty" | "stale" | "error";

export function chartFileName(spec: GatewayInteractiveChartSpec, extension: string) {
  return `${spec.export?.fileName ?? spec.chartId}.${extension}`;
}

export function chartReadiness(spec?: GatewayInteractiveChartSpec): ChartReadiness {
  if (!spec) return "empty";
  if (spec.status === "error") return "error";
  if (spec.status === "empty" || spec.data.length === 0) return "empty";
  if (spec.status === "stale") return "stale";
  return "ready";
}

export function canRenderChart(spec?: GatewayInteractiveChartSpec) {
  const readiness = chartReadiness(spec);
  return Boolean(spec && (readiness === "ready" || readiness === "stale"));
}

export function chartStatusLabel(spec?: GatewayInteractiveChartSpec) {
  const readiness = chartReadiness(spec);
  if (readiness === "stale") return "Stale local evidence";
  if (readiness === "error") return "Chart evidence error";
  if (readiness === "empty") return "No local chart data";
  return "Ready";
}

export function escapeHtml(value: string) {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
