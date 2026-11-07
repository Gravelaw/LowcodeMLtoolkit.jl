import { useEffect, useRef, useState } from "react";
import type { AnalysisFilter, AnalysisFinding, AnalysisProfileResponse, AnalysisReportResponse, AnalysisScopeRequest, AnalysisWorkspace, DataScienceProject, RunStatisticalAnalysisRequest, RunStatisticalAnalysisResponse } from "@juliaflow/contracts";
import { Card, DataTable } from "../components/ui";
import { InteractiveChart } from "../components/InteractiveChart";
import { AnalysisEvidenceTables } from "../components/AnalysisEvidenceTables";

interface Actions {
  load: (datasetId: string) => Promise<AnalysisProfileResponse>;
  run: (request: RunStatisticalAnalysisRequest) => Promise<RunStatisticalAnalysisResponse>;
  save: (workspace: AnalysisWorkspace, expectedRevision: number) => Promise<DataScienceProject>;
  export: () => Promise<AnalysisReportResponse>;
}

// Route changes retain unsaved work in this browser session. Only gateway saves are durable.
type AnalysisDraft = Omit<AnalysisWorkspace, "scope"> & {
  scope: Pick<AnalysisScopeRequest, "question" | "filters" | "xColumn" | "yColumn">;
};
const drafts = new Map<string, AnalysisDraft>();

function download(name: string, value: string, type: string) {
  const url = URL.createObjectURL(new Blob([value], { type }));
  const link = document.createElement("a");
  link.href = url; link.download = name; link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

/** Findings are drafts; computed records stay in the server-owned project aggregate. */
export function AnalyseDataPanel({ project, actions, onBuildModel }: { project: DataScienceProject; actions?: Actions; onBuildModel: () => void }) {
  const saved = project.analysisWorkspace;
  const cached = drafts.get(project.projectId);
  const draft = cached?.revision === (saved?.revision ?? 0) ? cached : undefined;
  const initial = draft ?? saved;
  const [datasetId, setDatasetId] = useState(initial?.datasetId ?? project.datasets[0]?.datasetId ?? "");
  const [question, setQuestion] = useState(initial?.scope.question ?? "");
  const [filters, setFilters] = useState<AnalysisFilter[]>(initial?.scope.filters ?? []);
  const [xColumn, setXColumn] = useState(initial?.scope.xColumn ?? "");
  const [yColumn, setYColumn] = useState(initial?.scope.yColumn ?? "");
  const [runId, setRunId] = useState(initial?.analysisRunId ?? "");
  const [findings, setFindings] = useState<AnalysisFinding[]>(initial?.findings ?? []);
  const [profile, setProfile] = useState<AnalysisProfileResponse>();
  const [busy, setBusy] = useState("");
  const busyRef = useRef(false);
  const generation = useRef(0);
  const [dirty, setDirty] = useState(Boolean(draft));
  const [message, setMessage] = useState("");
  const [error, setError] = useState(false);
  const [revision, setRevision] = useState(saved?.revision ?? 0);
  const currentRun = project.statisticalAnalysisRuns.find((r) => r.analysisRunId === runId && r.datasetId === datasetId);
  const evidence = currentRun?.resultSummary;
  const scope = evidence?.scope as Record<string, unknown> | undefined;
  const dataset = project.datasets.find((d) => d.datasetId === datasetId);
  const schema = project.schemaContracts.find((s) => s.datasetId === datasetId);
  const stale = Boolean(scope && (scope.datasetChecksum !== dataset?.checksumSha256 || scope.schemaFingerprint !== profile?.schemaFingerprint));
  const summaryRows = ((evidence?.summaries ?? []) as Record<string, unknown>[]).map((row) => ({
    ...row,
    ...Object.fromEntries(["mean", "std", "min", "max"].map((key) => [key, row[key] ?? "unavailable"]))
  }));

  useEffect(() => {
    if (!dirty) { drafts.delete(project.projectId); return; }
    // Draft text does not require a successful measured refresh. Source identity
    // is acquired only by requestScope before a real run/save.
    drafts.set(project.projectId, { revision, datasetId, scope: { question, filters, xColumn, yColumn },
      findings, ...(runId ? { analysisRunId: runId } : {}) });
    const warn = (event: BeforeUnloadEvent) => { event.preventDefault(); event.returnValue = ""; };
    window.addEventListener("beforeunload", warn);
    return () => window.removeEventListener("beforeunload", warn);
  }, [dirty, project.projectId, revision, datasetId, profile, question, filters, xColumn, yColumn, findings, runId]);

  async function perform(label: string, action: () => Promise<void>) {
    if (busyRef.current) return;
    busyRef.current = true; setBusy(label); setMessage(""); setError(false);
    const ticket = generation.current;
    try { await action(); }
    catch (e) { if (ticket === generation.current) { setMessage(e instanceof Error ? e.message : "Local analysis request failed."); setError(true); } }
    finally { if (ticket === generation.current) { busyRef.current = false; setBusy(""); } }
  }

  async function loadMeasured() {
    if (!actions || !datasetId) return;
    const ticket = generation.current;
    const response = await actions.load(datasetId);
    if (ticket !== generation.current) return;
    setProfile(response);
    setMessage("Measured data loaded from the saved source. No reimport was performed.");
  }

  useEffect(() => {
    const ticket = ++generation.current;
    busyRef.current = false; setBusy(""); setProfile(undefined);
    void perform("Loading measured data", loadMeasured);
    return () => { if (ticket === generation.current) ++generation.current; };
    // The project-keyed parent remounts on project changes; only dataset changes reload bytes.
  }, [datasetId]);

  function changeScope(change: () => void) { change(); setRunId(""); setDirty(true); }
  function requestScope(): AnalysisScopeRequest {
    if (!profile) throw new Error("Refresh measured data before running or saving.");
    if (Boolean(xColumn) !== Boolean(yColumn)) throw new Error("Select both chart axes or clear both before running or saving.");
    return { datasetChecksum: profile.profile.checksumSha256, schemaFingerprint: profile.schemaFingerprint, filters, question,
      ...(xColumn && yColumn ? { xColumn, yColumn } : {}) };
  }

  return <section className="analysis-workspace wide" aria-label="Analyse Data workspace">
    <Card title="Analyse Data" eyebrow="Analysis-only journey · no training or split required" className="wide">
      <div className="analysis-status" aria-live="polite">
        <span>Project: <strong>{project.name}</strong></span><span>Dataset: <strong>{datasetId || "Select or import data"}</strong></span>
        <span>Scope: <strong>{filters.length ? `${filters.length} filters` : "Full source"}</strong></span>
        <span>Save: <strong>{dirty ? "Unsaved changes" : `Saved revision ${revision}`}</strong></span>
      </div>
      <div className="analysis-controls">
        <label>Analysis dataset<select aria-label="Analysis dataset" value={datasetId} disabled={!!busy} onChange={(e) => { changeScope(() => { setDatasetId(e.target.value); setFilters([]); setXColumn(""); setYColumn(""); }); }}>
          <option value="">Choose imported data</option>{project.datasets.map((d) => <option key={d.datasetId} value={d.datasetId}>{d.name}</option>)}
        </select></label>
        <button className="jf-button secondary" disabled={!actions || !datasetId || !!busy} onClick={() => void perform("Refreshing measured data", loadMeasured)}>Refresh measured data</button>
      </div>
      {!datasetId ? <p>Open a saved project and import local data in Data before analysing.</p> : null}
      {message ? <p className={`feedback ${error ? "error" : "success"}`} role={error ? "alert" : "status"}>{message}</p> : null}
      {busy ? <p role="status">{busy}…</p> : null}
      <label>Analysis question<input maxLength={500} value={question} disabled={!!busy} onChange={(e) => changeScope(() => setQuestion(e.target.value))} placeholder="What does this data tell us?" /></label>
      <details open={filters.length > 0}><summary>Analysis filters ({filters.length})</summary>
        {filters.map((filter, index) => <div className="analysis-controls" key={index}>
          <label>Filter column {index + 1}<select aria-label={`Filter column ${index + 1}`} value={filter.column} disabled={!!busy} onChange={(e) => changeScope(() => setFilters(filters.map((f, i) => i === index ? { ...f, column: e.target.value } : f)))}>
            {(profile?.profile.schemaSummary ?? []).map((c) => <option key={c.name} value={c.name}>{c.name}</option>)}
          </select></label>
          <label>Filter operator {index + 1}<select aria-label={`Filter operator ${index + 1}`} value={filter.operator} disabled={!!busy} onChange={(e) => changeScope(() => setFilters(filters.map((f, i) => i === index ? { ...f, operator: e.target.value as AnalysisFilter["operator"] } : f)))}>
            <option value="eq">Equals</option><option value="gte">At least</option><option value="lte">At most</option>
          </select></label>
          <label>Filter value {index + 1}<input maxLength={200} value={filter.value} disabled={!!busy} onChange={(e) => changeScope(() => setFilters(filters.map((f,i) => i === index ? { ...f, value: e.target.value } : f)))} /></label>
          <button className="jf-button secondary" disabled={!!busy} onClick={() => changeScope(() => setFilters(filters.filter((_,i) => i !== index)))}>Remove filter {index + 1}</button>
        </div>)}
        <button className="jf-button secondary" disabled={!profile || !!busy || filters.length >= 10} onClick={() => changeScope(() => setFilters([...filters, { column: profile!.profile.schemaSummary[0]?.name ?? "", operator: "eq", value: "" }]))}>Add analysis filter</button>
      </details>
      <details><summary>Chart and method</summary><p>Measured summaries, missingness and Pearson correlation. Other statistical methods require separate qualification.</p>
        <div className="analysis-controls">{(["x", "y"] as const).map((axis) => <label key={axis}>{axis.toUpperCase()} column<select aria-label={`${axis.toUpperCase()} column`} value={axis === "x" ? xColumn : yColumn} disabled={!!busy} onChange={(e) => changeScope(() => axis === "x" ? setXColumn(e.target.value) : setYColumn(e.target.value))}>
          <option value="">No scatter axis selected</option>{(profile?.numericColumns ?? []).map((c) => <option key={c} value={c}>{c}{schema?.columns.find((x) => x.name === c)?.unit ? ` (${schema.columns.find((x) => x.name === c)?.unit})` : ""}</option>)}
        </select></label>)}</div>
      </details>
      <div className="analysis-controls">
        <button className="jf-button primary" disabled={!actions || !profile || !question.trim() || !!busy || Boolean(xColumn) !== Boolean(yColumn)} onClick={() => void perform("Running analysis", async () => {
          const ticket = generation.current;
          const response = await actions!.run({ datasetId, methods: ["summary", "correlation"], scope: requestScope() });
          if (ticket !== generation.current) return;
          setRunId(response.analysisRun.analysisRunId); setDirty(true); setMessage("Analysis computed. Save to retain this view and its findings.");
        })}>Run analysis</button>
        <button className="jf-button secondary" disabled={!actions || !profile || !dirty || !!busy || !question.trim() || Boolean(xColumn) !== Boolean(yColumn)} onClick={() => void perform("Saving analysis", async () => {
          const ticket = generation.current;
          const workspace: AnalysisWorkspace = { revision, datasetId, scope: requestScope(), findings, ...(runId ? { analysisRunId: runId } : {}) };
          const result = await actions!.save(workspace, revision);
          if (ticket !== generation.current) return;
          setRevision(result.analysisWorkspace!.revision); setDirty(false); setMessage("Analysis and findings saved to this project.");
        })}>Save analysis and findings</button>
        <button className="jf-button secondary" disabled={!actions || dirty || !saved?.analysisRunId || !!busy || stale} onClick={() => void perform("Exporting report", async () => {
          const response = await actions!.export(); download(`${response.fileName}.html`, response.html, "text/html;charset=utf-8");
          setMessage(`Presentation report exported. SHA-256 ${response.checksumSha256}. Source CSV file is excluded; this is separate from a reopenable project package.`);
        })}>Export analysis report</button>
        <button className="jf-button secondary" disabled={!actions || dirty || !saved?.analysisRunId || !!busy || stale} onClick={() => void perform("Exporting summary table", async () => {
          const response = await actions!.export(); download(`${response.fileName}.csv`, response.csv, "text/csv;charset=utf-8");
        })}>Export summary CSV</button>
      </div>
    </Card>
    {profile ? <Card title="Measured schema and preview" className="wide">
      <p>{profile.profile.rowCount} full-source rows · checksum {profile.profile.checksumSha256.slice(0,12)} · supported unquoted CSV: ≤1,000 rows / 8 MiB / 64 enabled numeric columns</p>
      <DataTable caption="Measured dataset preview" columns={profile.profile.schemaSummary.map((c) => ({key:c.name,label:c.name}))} rows={profile.profile.previewRows ?? []} getRowKey={(_,i) => String(i)} />
      <p>Schema and role corrections are saved in Data; refresh measured data after changes. Ignored, sensitive, ID and categorical fields are excluded from numeric analysis.</p>
    </Card> : null}
    {currentRun ? <Card title="Immutable analysis evidence" className="wide">
      {stale ? <p role="alert">Source or schema changed. Historical evidence is retained; refresh data and run a new analysis.</p> : null}
      <p>Run {currentRun.analysisRunId} · {String(scope?.selectedRowCount ?? "unavailable")} selected of {String(scope?.sourceRowCount ?? "unavailable")} rows · actual compute: CPU, gateway</p>
      <DataTable caption="Numeric summaries" columns={[{key:"column",label:"Column"},{key:"count",label:"Valid"},{key:"missingCount",label:"Missing"},{key:"mean",label:"Mean"},{key:"std",label:"SD"},{key:"min",label:"Min"},{key:"max",label:"Max"}]} rows={summaryRows} getRowKey={(r) => String(r.column)} />
      <div className="chart-grid">{currentRun.charts?.map((chart) => <InteractiveChart spec={chart} key={chart.chartId} />)}</div>
      {evidence ? <AnalysisEvidenceTables evidence={evidence} /> : null}
      {currentRun.warnings.map((warning) => <p key={warning} className="feedback info">{warning}</p>)}
      <button className="jf-button secondary" disabled={!!busy || findings.length >= 50} onClick={() => { setFindings([...findings,{findingId:crypto.randomUUID(),analysisRunId:runId,title:question,notes:""}]);setDirty(true); }}>Add finding</button>
    </Card> : null}
    <Card title="Editable findings" className="wide">
      {findings.length === 0 ? <p>No findings yet. Run analysis, then add your interpretation.</p> : findings.map((finding,i) => <fieldset key={finding.findingId} disabled={!!busy}>
        <legend>Finding {i + 1}</legend><p>Immutable evidence: {finding.analysisRunId} · Dataset: {project.statisticalAnalysisRuns.find((run) => run.analysisRunId === finding.analysisRunId)?.datasetId ?? "unavailable"}</p>
        <label>Finding title {i + 1}<input value={finding.title} maxLength={500} onChange={(e) => {setFindings(findings.map((f,n) => n === i ? {...f,title:e.target.value} : f));setDirty(true);}} /></label>
        <label>Finding notes {i + 1}<textarea aria-label={`Finding notes ${i + 1}`} value={finding.notes} maxLength={10000} onChange={(e) => {setFindings(findings.map((f,n) => n === i ? {...f,notes:e.target.value} : f));setDirty(true);}} /></label>
        <button className="jf-button secondary" onClick={() => {setFindings(findings.filter((_,n) => n !== i));setDirty(true);}}>Remove finding {i + 1}</button>
      </fieldset>)}
      <p>Findings remain editable. Saved runs, source identities, filters and numeric results remain immutable.</p>
      <button className="jf-button secondary" disabled={!!busy} onClick={onBuildModel}>Build Model in this project</button>
      <p>Modeling requires an explicit population, target and split. Analysis filters are not transferred automatically.</p>
    </Card>
  </section>;
}
