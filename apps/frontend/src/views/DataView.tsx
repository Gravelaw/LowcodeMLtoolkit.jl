import { useMemo, useState } from "react";
import { Card, CodeBlock, DataTable, StatusPill } from "../components/ui";
import { InteractiveChart } from "../components/InteractiveChart";
import { localCode } from "../fixtures/local-fixtures";
import type { ActionFeedback, AppData } from "../types";
import type { GatewayDataImportProfile, GatewayDataSourceOption } from "@juliaflow/contracts";

type DataTab = "table" | "schema" | "profile" | "filters" | "sort" | "joins" | "transforms" | "sampling" | "lineage";

const dataTabs: DataTab[] = ["table", "schema", "profile", "filters", "sort", "joins", "transforms", "sampling", "lineage"];

function tabLabel(tab: DataTab) {
  if (tab === "transforms") return "feature ops";
  return tab;
}

function previewColumns(rows: Array<Record<string, unknown>>, schema: GatewayDataImportProfile["schemaSummary"]) {
  const keys = Object.keys(rows[0] ?? {});
  const ordered = [...schema.map((field) => field.name), ...keys].filter((key, index, all) => key && all.indexOf(key) === index);
  return ordered.slice(0, 7).map((key) => ({ key, label: key.replaceAll("_", " ") }));
}

function sourceRequest(profile: GatewayDataImportProfile, option?: GatewayDataSourceOption) {
  const mode = option?.mode ?? profile.activeReadMode ?? profile.sourceFormat;
  return {
    datasetId: profile.datasetId,
    sourceUri: option?.mode === "csv" ? profile.sourceUri : option?.path ?? profile.sourceUri,
    format: mode,
    targetZone: profile.targetZone,
    readMode: mode
  };
}

function modeTone(status: string | undefined) {
  if (status === "active" || status === "ready") return "green";
  if (status === "pending") return "orange";
  if (status === "unavailable") return "neutral";
  return "blue";
}

function compareValues(a: unknown, b: unknown) {
  if (typeof a === "number" && typeof b === "number") return a - b;
  return String(a ?? "").localeCompare(String(b ?? ""));
}

function uniqueValues(rows: Array<Record<string, unknown>>, field: string) {
  return Array.from(new Set(rows.map((row) => String(row[field] ?? "")).filter(Boolean))).slice(0, 6);
}

export function DataView({
  data,
  onImport,
  onSelectProfile,
  feedback
}: {
  data: AppData;
  onImport: (request?: ReturnType<typeof sourceRequest>) => void;
  onSelectProfile: (profile: GatewayDataImportProfile) => void;
  feedback?: ActionFeedback;
}) {
  const [activeTab, setActiveTab] = useState<DataTab>("table");
  const [filterField, setFilterField] = useState("contract_type");
  const [filterValue, setFilterValue] = useState("all");
  const [sortField, setSortField] = useState("tenure_months");
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("asc");
  const activeProfile = data.dataProfile;
  const dataProfiles = data.dataProfiles?.length > 0 ? data.dataProfiles : [activeProfile];
  const sourceOptions = activeProfile.sourceOptions ?? [];
  const previewRows = activeProfile.previewRows ?? [];
  const activeOption = sourceOptions.find((option) => option.mode === activeProfile.activeReadMode) ?? sourceOptions[0];
  const qualityHighlight = activeProfile.profileSummary.find((field) => field.quality.includes("% complete"))?.quality;
  const numericFields = activeProfile.schemaSummary.filter((field) => /int|float|double|number/i.test(field.type)).map((field) => field.name);
  const categoricalFields = activeProfile.schemaSummary.filter((field) => /string|bool|date/i.test(field.type)).map((field) => field.name);
  const effectiveFilterField = activeProfile.schemaSummary.some((field) => field.name === filterField)
    ? filterField
    : categoricalFields[0] ?? activeProfile.schemaSummary[0]?.name ?? "field";
  const effectiveSortField = activeProfile.schemaSummary.some((field) => field.name === sortField)
    ? sortField
    : numericFields[0] ?? activeProfile.schemaSummary[0]?.name ?? "field";
  const filterOptions = uniqueValues(previewRows, effectiveFilterField);

  const preview = useMemo(() => {
    const filtered = filterValue === "all"
      ? previewRows
      : previewRows.filter((row) => String(row[effectiveFilterField] ?? "") === filterValue);
    return [...filtered].sort((left, right) => {
      const result = compareValues(left[effectiveSortField], right[effectiveSortField]);
      return sortDirection === "asc" ? result : -result;
    });
  }, [effectiveFilterField, effectiveSortField, filterValue, previewRows, sortDirection]);
  const columns = previewColumns(preview.length ? preview : previewRows, activeProfile.schemaSummary);

  const sourceBrowser = [
    { label: "Local Files", detail: "Browse local CSV, Arrow, Parquet", status: "ready", enabled: true, option: sourceOptions.find((option) => option.mode === "csv") },
    { label: "Watched Folders", detail: "Auto-detect new files", status: "pending", enabled: false, reason: "Folder watcher is not wired to the gateway yet." },
    { label: "DuckDB (Local)", detail: "Profile and query local artifacts", status: activeProfile.duckdbStatus, enabled: activeProfile.duckdbStatus === "ready", option: sourceOptions.find((option) => option.mode === "duckdb") },
    { label: "SQLite (Local)", detail: "Local .sqlite and .db files", status: "unavailable", enabled: false, reason: "SQLite connector contract is not implemented yet." },
    { label: "PostgreSQL (Local)", detail: "Lab/team metadata mode", status: data.health.postgresProfileStatus, enabled: false, reason: "PostgreSQL source import is not implemented for this slice." },
    { label: "MySQL (Local)", detail: "Local MySQL server", status: "unavailable", enabled: false, reason: "MySQL source import is not implemented yet." },
    { label: "USB Import", detail: "Import from mounted drives", status: "unavailable", enabled: false, reason: "Native removable-drive picker needs desktop shell integration." },
    { label: "Drop File Or URL", detail: "Drag and drop local file paths", status: "pending", enabled: false, reason: "Drop handling is intentionally disabled until backed by local import validation." }
  ];

  return (
    <div className="route-grid data-route">
      <section className="page-title">
        <div>
          <h1>Data</h1>
          <p>Customer Churn Dataset. All data is stored and processed locally on this machine.</p>
        </div>
        <div className="button-row">
          <button type="button" className="jf-button secondary" onClick={() => onImport(sourceRequest(activeProfile, sourceOptions.find((option) => option.mode === "csv") ?? activeOption))}>
            Import Local Data
          </button>
          <button type="button" className="jf-button primary" onClick={() => onImport(sourceRequest(activeProfile, activeOption))}>
            Re-profile Active Dataset
          </button>
        </div>
      </section>
      {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

      <Card title="Local Data Sources" eyebrow="All sources stay on this device">
        <div className="source-stack">
          {sourceBrowser.map((source) => (
            <button
              type="button"
              className={`source-row ${source.enabled ? "" : "disabled"}`}
              key={source.label}
              disabled={!source.enabled}
              title={source.enabled ? source.detail : source.reason}
              onClick={() => source.option && onImport(sourceRequest(activeProfile, source.option))}
            >
              <strong>{source.label}</strong>
              <span>{source.detail}</span>
              <StatusPill tone={modeTone(source.status)}>{source.status}</StatusPill>
            </button>
          ))}
        </div>
      </Card>

      <Card title="Local Data Profile" className="right-panel">
        <div className="profile-cards single">
          <div><span>Rows</span><strong>{preview.length.toLocaleString()} / {activeProfile.rowCount.toLocaleString()}</strong></div>
          <div><span>Columns</span><strong>{activeProfile.schemaSummary.length}</strong></div>
          <div><span>Missing Values</span><strong>{activeProfile.profileSummary.reduce((sum, field) => sum + (field.missingCount ?? 0), 0).toLocaleString()}</strong></div>
          <div><span>Quality</span><strong>{qualityHighlight ?? "profile ready"}</strong></div>
          <div><span>Source</span><strong>{activeProfile.activeReadMode ?? activeProfile.sourceFormat}</strong></div>
        </div>
        <button type="button" className="jf-button secondary full-width" onClick={() => onImport(sourceRequest(activeProfile, activeOption))}>
          Re-profile Active Read Mode
        </button>
      </Card>

      <Card title="Dataset Catalog" eyebrow="Local fixtures">
        <div className="source-grid">
          {dataProfiles.map((profile) => (
            <button
              type="button"
              className={`source-card ${profile.datasetId === activeProfile.datasetId ? "active" : ""}`}
              key={profile.datasetId}
              onClick={() => onSelectProfile(profile)}
            >
              {profile.datasetId}
              <br />
              <small>{profile.sourceUri}</small>
            </button>
          ))}
        </div>
      </Card>

      <Card title="Read Mode Selector" eyebrow="CSV -> Arrow -> Parquet -> DuckDB" className="wide">
        <div className="source-grid">
          {sourceOptions.map((option) => (
            <button
              type="button"
              className={`source-card ${option.mode === activeProfile.activeReadMode ? "active" : ""}`}
              key={option.mode}
              onClick={() => onImport(sourceRequest(activeProfile, option))}
            >
              {option.label}
              <br />
              <small>{option.path}</small>
              <StatusPill tone={modeTone(option.status)}>{option.status}</StatusPill>
              <span className="source-card-detail">{option.semantics}</span>
            </button>
          ))}
        </div>
      </Card>

      <Card title="Table Workspace" eyebrow={`${filterValue === "all" ? "No filter" : `${effectiveFilterField} = ${filterValue}`} / sort ${effectiveSortField} ${sortDirection}`} className="wide">
        <div className="mode-tabs" role="tablist" aria-label="Data table workspace tabs">
          {dataTabs.map((tab) => (
            <button type="button" key={tab} className={activeTab === tab ? "active" : ""} aria-selected={activeTab === tab} onClick={() => setActiveTab(tab)}>
              {tabLabel(tab)}
            </button>
          ))}
        </div>

        {activeTab === "table" ? (
          preview.length > 0 ? (
            <DataTable
              columns={columns}
              rows={preview}
              getRowKey={(row, index) => `${activeProfile.datasetId}-${String(row[String(columns[0]?.key ?? "row")] ?? "row")}-${index}`}
            />
          ) : (
            <p className="empty-state">No preview rows match the active filter. Clear filters or re-profile the local dataset.</p>
          )
        ) : null}

        {activeTab === "schema" ? (
          <DataTable
            columns={[{ key: "name", label: "Column" }, { key: "type", label: "Type" }]}
            rows={activeProfile.schemaSummary}
            getRowKey={(row) => row.name}
          />
        ) : null}

        {activeTab === "profile" ? (
          <DataTable
            columns={[
              { key: "name", label: "Field" },
              { key: "type", label: "Type" },
              { key: "role", label: "Role" },
              { key: "quality", label: "Quality" },
              { key: "missingCount", label: "Missing" },
              { key: "outlierCount", label: "Outliers" }
            ]}
            rows={activeProfile.profileSummary}
            getRowKey={(row) => String(row.name)}
          />
        ) : null}

        {activeTab === "filters" ? (
          <div className="control-panel-grid">
            <label>
              <span>Filter field</span>
              <select value={effectiveFilterField} onChange={(event) => { setFilterField(event.target.value); setFilterValue("all"); }}>
                {categoricalFields.map((field) => <option key={field}>{field}</option>)}
              </select>
            </label>
            <label>
              <span>Value</span>
              <select value={filterValue} onChange={(event) => setFilterValue(event.target.value)}>
                <option value="all">All values</option>
                {filterOptions.map((value) => <option key={value}>{value}</option>)}
              </select>
            </label>
            <p className="empty-state">Filter changes update the preview table and profile row count immediately.</p>
          </div>
        ) : null}

        {activeTab === "sort" ? (
          <div className="control-panel-grid">
            <label>
              <span>Sort field</span>
              <select value={effectiveSortField} onChange={(event) => setSortField(event.target.value)}>
                {[...numericFields, ...categoricalFields].map((field) => <option key={field}>{field}</option>)}
              </select>
            </label>
            <label>
              <span>Direction</span>
              <select value={sortDirection} onChange={(event) => setSortDirection(event.target.value === "desc" ? "desc" : "asc")}>
                <option value="asc">Ascending</option>
                <option value="desc">Descending</option>
              </select>
            </label>
          </div>
        ) : null}

        {activeTab === "joins" ? <p className="empty-state">Join planning is visible but disabled until persisted join contracts are added to the gateway.</p> : null}
        {activeTab === "transforms" ? <p className="empty-state">Open Transform to build persisted feature pipelines from this dataset profile.</p> : null}
        {activeTab === "sampling" ? <p className="empty-state">Sampling is pending local stratified sampler contracts; current preview shows deterministic first rows from profile evidence.</p> : null}
        {activeTab === "lineage" ? (
          <div className="lineage-list">
            {(activeProfile.lineageArtifacts ?? []).map((artifact) => (
              <div key={`${artifact.stage}-${artifact.artifactRef}`}>
                <span>{artifact.stage}</span>
                <strong>{artifact.format}</strong>
                <small>{artifact.artifactRef}</small>
                <small>{artifact.rowCount.toLocaleString()} rows | {artifact.checksumSha256.slice(0, 10)}</small>
              </div>
            ))}
          </div>
        ) : null}
      </Card>

      <Card title="Quality Checks">
        <div className="quality-list">
          {(activeProfile.qualityChecks ?? []).map((check) => (
            <div key={check.checkId}>
              <StatusPill tone={check.status === "passed" ? "green" : check.status === "warning" ? "orange" : "neutral"}>{check.status}</StatusPill>
              <strong>{check.label}</strong>
              <span>{check.detail}</span>
            </div>
          ))}
        </div>
      </Card>

      <Card title="Artifact Lineage" className="right-panel">
        <div className="lineage-list">
          {(activeProfile.lineageArtifacts ?? []).map((artifact) => (
            <div key={`${artifact.stage}-${artifact.artifactRef}`}>
              <span>{artifact.stage}</span>
              <strong>{artifact.format}</strong>
              <small>{artifact.artifactRef}</small>
              <small>{artifact.rowCount.toLocaleString()} rows | {artifact.checksumSha256.slice(0, 10)}</small>
            </div>
          ))}
        </div>
      </Card>

      <Card title="ML Readiness" className="right-panel readiness-panel">
        {activeProfile.workflowReadiness ? (
          <div className="key-values wrap-values">
            <span>Target</span><strong>{activeProfile.workflowReadiness.targetColumn}</strong>
            <span>Split</span><strong>{activeProfile.workflowReadiness.trainTestSplit}</strong>
            <span>Status</span><strong>{activeProfile.workflowReadiness.downstreamReady ? "ready" : "blocked"}</strong>
            <span>Next</span><strong>{activeProfile.workflowReadiness.recommendedNextAction}</strong>
          </div>
        ) : (
          <p className="empty-state">No modeling-readiness evidence is attached to this profile yet.</p>
        )}
      </Card>

      <Card title="Quick EDA Charts" eyebrow="Julia-generated Plotly specs" className="wide">
        <div className="chart-grid">
          {(activeProfile.charts ?? []).map((spec) => (
            <InteractiveChart key={spec.chartId} spec={spec} />
          ))}
        </div>
      </Card>

      <Card title="Generated Julia Code" className="wide">
        <CodeBlock label="data/import_profile.jl">{localCode.data}</CodeBlock>
      </Card>
    </div>
  );
}
