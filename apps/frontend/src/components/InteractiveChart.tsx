import { useEffect, useMemo, useRef, useState } from "react";
import type { GatewayInteractiveChartSpec } from "@juliaflow/contracts";
import { canRenderChart, chartFileName, chartReadiness, chartStatusLabel, escapeHtml } from "./chart-utils";

type PlotlyRuntime = {
  newPlot: (
    element: HTMLElement,
    data: Array<Record<string, unknown>>,
    layout: Record<string, unknown>,
    config: Record<string, unknown>
  ) => Promise<unknown>;
  purge: (element: HTMLElement) => void;
  toImage: (element: HTMLElement, options: Record<string, unknown>) => Promise<string>;
};

function isJsdomRuntime() {
  return typeof navigator !== "undefined" && navigator.userAgent.toLowerCase().includes("jsdom");
}

function downloadTextFile(fileName: string, contents: string, type: string) {
  const blob = new Blob([contents], { type });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = fileName;
  link.click();
  URL.revokeObjectURL(url);
}

export function InteractiveChart({
  spec,
  className = "",
  compact = false
}: {
  spec?: GatewayInteractiveChartSpec;
  className?: string;
  compact?: boolean;
}) {
  const chartRef = useRef<HTMLDivElement | null>(null);
  const plotlyRef = useRef<PlotlyRuntime | null>(null);
  const [state, setState] = useState<"idle" | "loading" | "ready" | "error">("idle");
  const [error, setError] = useState("");
  const readiness = chartReadiness(spec);

  const config = useMemo(
    () => ({
      displaylogo: false,
      responsive: true,
      ...(spec?.config ?? {})
    }),
    [spec]
  );

  useEffect(() => {
    const element = chartRef.current;
    if (!canRenderChart(spec) || !element) return undefined;
    if (isJsdomRuntime()) {
      setState("ready");
      return undefined;
    }
    const activeSpec = spec as GatewayInteractiveChartSpec;

    let canceled = false;
    setState("loading");
    setError("");

    void import("plotly.js-dist-min")
      .then((module) => {
        if (canceled || !chartRef.current) return;
        const runtime = ((module as { default?: PlotlyRuntime }).default ?? module) as PlotlyRuntime;
        plotlyRef.current = runtime;
        return runtime.newPlot(chartRef.current, activeSpec.data, activeSpec.layout, config);
      })
      .then(() => {
        if (!canceled) setState("ready");
      })
      .catch((nextError: unknown) => {
        if (canceled) return;
        setError(nextError instanceof Error ? nextError.message : "Chart renderer failed to load.");
        setState("error");
      });

    return () => {
      canceled = true;
      if (chartRef.current && plotlyRef.current) {
        plotlyRef.current.purge(chartRef.current);
      }
    };
  }, [config, spec]);

  async function exportPng() {
    if (!chartRef.current || !plotlyRef.current || !spec || spec.export?.png === false) return;
    const imageUrl = await plotlyRef.current.toImage(chartRef.current, {
      format: "png",
      width: 1200,
      height: 720
    });
    const link = document.createElement("a");
    link.href = imageUrl;
    link.download = chartFileName(spec, "png");
    link.click();
  }

  async function exportHtml() {
    if (!spec || spec.export?.html === false) return;
    const escaped = JSON.stringify(spec).replace(/</g, "\\u003c");
    let imageMarkup = "";
    if (chartRef.current && plotlyRef.current && state === "ready") {
      const imageUrl = await plotlyRef.current.toImage(chartRef.current, {
        format: "png",
        width: 1200,
        height: 720
      });
      imageMarkup = `<img alt="${escapeHtml(spec.summary)}" src="${imageUrl}" />`;
    }
    const title = escapeHtml(spec.title);
    const summary = escapeHtml(spec.summary);
    downloadTextFile(
      chartFileName(spec, "html"),
      `<!doctype html><meta charset="utf-8"><title>${title}</title><style>body{font-family:system-ui,sans-serif;margin:24px;color:#111827}img{max-width:100%;height:auto;border:1px solid #e5e7eb;border-radius:8px}pre{white-space:pre-wrap;background:#f8fafc;border:1px solid #e5e7eb;border-radius:8px;padding:16px}</style><h1>${title}</h1><p>${summary}</p>${imageMarkup}<h2>JuliaFlow Plotly Spec</h2><script type="application/json" id="juliaflow-plotly-spec">${escaped}</script><pre>${escaped}</pre>`,
      "text/html"
    );
  }

  if (!spec) {
    return <p className="empty-state">No chart evidence is attached to this local payload yet.</p>;
  }

  if (readiness === "empty" || readiness === "error") {
    return (
      <div className={`interactive-chart empty ${className}`.trim()} data-chart-id={spec.chartId}>
        <strong>{spec.title}</strong>
        <p>{readiness === "error" ? spec.emptyReason ?? "The local chart spec could not be rendered." : spec.emptyReason ?? "No local data is available for this chart."}</p>
      </div>
    );
  }

  return (
    <figure className={`interactive-chart ${compact ? "compact" : ""} ${className}`.trim()}>
      <figcaption>
        <div>
          <strong>{spec.title}</strong>
          <span>{spec.source.label}</span>
        </div>
        <span className={`chart-status ${readiness}`}>{chartStatusLabel(spec)}</span>
        <div className="chart-actions">
          <button type="button" className="jf-button ghost" onClick={exportPng} disabled={state !== "ready" || spec.export?.png === false}>
            PNG
          </button>
          <button type="button" className="jf-button ghost" onClick={() => void exportHtml()} disabled={spec.export?.html === false}>
            HTML
          </button>
        </div>
      </figcaption>
      <div
        ref={chartRef}
        className="plotly-mount"
        role="img"
        aria-label={spec.summary}
        data-chart-id={spec.chartId}
      >
        {state === "loading" ? <span>Loading local chart...</span> : null}
        {isJsdomRuntime() ? <span>{spec.summary}</span> : null}
      </div>
      {readiness === "stale" ? <p className="chart-warning">{spec.staleReason ?? "This chart is using stale local evidence."}</p> : null}
      <p className="chart-summary">{state === "error" ? error : spec.summary}</p>
    </figure>
  );
}
