import { useMemo, useState } from "react";
import { Card, CodeBlock, DataTable, StatusPill } from "../components/ui";
import { InteractiveChart } from "../components/InteractiveChart";
import { localCode } from "../fixtures/local-fixtures";
import type { ActionFeedback, AppData } from "../types";
import type {
  DataScienceColumnRole,
  DataScienceSplitStrategy,
  DatasetSplitPlan,
  GatewayDataImportProfile,
  GatewayDataSourceOption,
  SchemaColumnContract,
  UpdateDataScienceProjectRequest
} from "@juliaflow/contracts";

type DataTab = "table" | "schema" | "profile" | "filters" | "sort" | "joins" | "transforms" | "sampling" | "lineage";

const dataTabs: DataTab[] = ["table", "schema", "profile", "filters", "sort", "joins", "transforms", "sampling", "lineage"];
const columnRoles: DataScienceColumnRole[] = ["feature", "target", "id", "group", "time", "depth", "sensitive", "ignore"];
const logicalTypes = ["continuous", "categorical", "binary", "date", "datetime", "identifier", "text", "ordinal"];
const splitStrategies: DataScienceSplitStrategy[] = ["random", "stratified", "grouped", "time", "depth", "external"];

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

function semanticColumnOption(schemaColumns: SchemaColumnContract[], role: DataScienceColumnRole) {
  return schemaColumns.find((column) => column.role === role)?.name ?? "";
}

export function DataView({
  data,
  onImport,
  onSelectProfile,
  onProjectUpdate,
  feedback
}: {
  data: AppData;
  onImport: (request?: ReturnType<typeof sourceRequest>) => void;
  onSelectProfile: (profile: GatewayDataImportProfile) => void;
  onProjectUpdate: (request: UpdateDataScienceProjectRequest) => void;
  feedback?: ActionFeedback;
}) {
  const [activeTab, setActiveTab] = useState<DataTab>("table");
  const [filterField, setFilterField] = useState("contract_type");
  const [filterValue, setFilterValue] = useState("all");
  const [sortField, setSortField] = useState("tenure_months");
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("asc");
  const [activeSourceLabel, setActiveSourceLabel] = useState("Local Files");
  const [sampleSize, setSampleSize] = useState("all");
  const activeProfile = data.dataProfile;
  const dataProfiles = data.dataProfiles?.length > 0 ? data.dataProfiles : [activeProfile];
  const sourceOptions = activeProfile.sourceOptions ?? [];
  const previewRows = activeProfile.previewRows ?? [];
  const project = data.dataScienceProject;
  const schemaContract = project.schemaContracts.find((schema) => schema.datasetId === activeProfile.datasetId) ?? project.schemaContracts[0];
  const schemaColumns = schemaContract?.columns ?? [];
  const activeSplitPlan = project.splitPlans.find((plan) => plan.datasetId === activeProfile.datasetId) ?? project.splitPlans[0];
  const finalTestLock = activeSplitPlan
    ? project.finalTestLocks.find((lock) => lock.splitPlanId === activeSplitPlan.splitPlanId)
    : undefined;
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

  const filteredPreview = useMemo(() => {
    const filtered = filterValue === "all"
      ? previewRows
      : previewRows.filter((row) => String(row[effectiveFilterField] ?? "") === filterValue);
    return [...filtered].sort((left, right) => {
      const result = compareValues(left[effectiveSortField], right[effectiveSortField]);
      return sortDirection === "asc" ? result : -result;
    });
  }, [effectiveFilterField, effectiveSortField, filterValue, previewRows, sortDirection]);
  const preview = useMemo(() => {
    if (sampleSize === "all") return filteredPreview;
    return filteredPreview.slice(0, Number(sampleSize));
  }, [filteredPreview, sampleSize]);
  const columns = previewColumns(preview.length ? preview : previewRows, activeProfile.schemaSummary);

  function updateSchemaColumn(columnName: string, patch: Partial<SchemaColumnContract>) {
    if (!schemaContract) return;
    const updatedSchema = {
      ...schemaContract,
      updatedAt: new Date().toISOString(),
      columns: schemaContract.columns.map((column) => (
        column.name === columnName
          ? { ...column, ...patch }
          : column
      ))
    };
    onProjectUpdate({
      schemaContracts: project.schemaContracts.map((schema) => (
        schema.schemaId === updatedSchema.schemaId ? updatedSchema : schema
      ))
    });
  }

  function updateSplitPlan(patch: Partial<DatasetSplitPlan>) {
    if (!activeSplitPlan) return;
    const updatedPlan = {
      ...activeSplitPlan,
      ...patch
    };
    onProjectUpdate({
      splitPlans: project.splitPlans.map((plan) => (
        plan.splitPlanId === updatedPlan.splitPlanId ? updatedPlan : plan
      ))
    });
  }

  function lockFinalTestSplit() {
    if (!activeSplitPlan) return;
    const lock = finalTestLock ?? {
      lockId: `lock-${activeSplitPlan.splitPlanId}`,
      splitPlanId: activeSplitPlan.splitPlanId,
      lockedAt: new Date().toISOString(),
      reason: "Final test split locked from Data workspace before model tuning or promotion.",
      lockedBy: "local-user"
    };
    onProjectUpdate({
      splitPlans: project.splitPlans.map((plan) => (
        plan.splitPlanId === activeSplitPlan.splitPlanId ? { ...plan, locked: true } : plan
      )),
      finalTestLocks: finalTestLock ? project.finalTestLocks : [...project.finalTestLocks, lock]
    });
  }

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
              className={`source-row ${source.enabled ? "" : "disabled"} ${activeSourceLabel === source.label ? "active" : ""}`}
              key={source.label}
              disabled={!source.enabled}
              title={source.enabled ? source.detail : source.reason}
              onClick={() => {
                setActiveSourceLabel(source.label);
                if (source.option) onImport(sourceRequest(activeProfile, source.option));
              }}
            >
              <strong>{source.label}</strong>
              <span>{source.detail}</span>
              <StatusPill tone={modeTone(source.status)}>{source.status}</StatusPill>
              {!source.enabled ? <small>{source.reason}</small> : null}
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

      <Card title="Project Schema Diagnostics" eyebrow={project.projectId} className="right-panel">
        {schemaContract ? (
          <div className="key-values wrap-values">
            <span>Schema</span><strong>{schemaContract.schemaId}</strong>
            <span>Columns</span><strong>{schemaColumns.length}</strong>
            <span>Target</span><strong>{semanticColumnOption(schemaColumns, "target") || "not set"}</strong>
            <span>Group</span><strong>{semanticColumnOption(schemaColumns, "group") || "not set"}</strong>
            <span>Updated</span><strong>{schemaContract.updatedAt}</strong>
          </div>
        ) : (
          <p className="empty-state">No schema contract is attached to this project yet.</p>
        )}
      </Card>

      <Card title="Validation And Test Plan" className="right-panel">
        {activeSplitPlan ? (
          <div className="control-panel-grid single">
            <label>
              <span>Validation strategy</span>
              <select
                aria-label="Validation strategy"
                value={activeSplitPlan.strategy}
                onChange={(event) => updateSplitPlan({ strategy: event.target.value as DataScienceSplitStrategy })}
              >
                {splitStrategies.map((strategy) => <option key={strategy}>{strategy}</option>)}
              </select>
            </label>
            <label>
              <span>Group column</span>
              <select
                aria-label="Validation group column"
                value={activeSplitPlan.groupColumn ?? ""}
                onChange={(event) => updateSplitPlan({ groupColumn: event.target.value || undefined })}
              >
                <option value="">None</option>
                {schemaColumns.map((column) => <option key={column.name}>{column.name}</option>)}
              </select>
            </label>
            <label>
              <span>Depth column</span>
              <select
                aria-label="Validation depth column"
                value={activeSplitPlan.depthColumn ?? ""}
                onChange={(event) => updateSplitPlan({ depthColumn: event.target.value || undefined })}
              >
                <option value="">None</option>
                {schemaColumns.map((column) => <option key={column.name}>{column.name}</option>)}
              </select>
            </label>
            <p className="workspace-state-line">
              Train / validation / test: <strong>{Math.round((activeSplitPlan.trainFraction ?? 0) * 100)}%</strong> / <strong>{Math.round((activeSplitPlan.validationFraction ?? 0) * 100)}%</strong> / <strong>{Math.round((activeSplitPlan.testFraction ?? 0) * 100)}%</strong>
            </p>
            <button type="button" className="jf-button secondary full-width" disabled={Boolean(finalTestLock)} onClick={lockFinalTestSplit}>
              {finalTestLock ? "Final Test Locked" : "Lock Final Test Split"}
            </button>
            {finalTestLock ? <p className="empty-state">Locked by {finalTestLock.lockedBy}: {finalTestLock.reason}</p> : null}
          </div>
        ) : (
          <p className="empty-state">No split plan is attached to this project yet.</p>
        )}
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
        <p className="workspace-state-line">
          Active source: <strong>{activeSourceLabel}</strong> | Preview: <strong>{preview.length.toLocaleString()}</strong> of <strong>{filteredPreview.length.toLocaleString()}</strong> filtered rows
        </p>
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
            columns={[
              { key: "name", label: "Column" },
              { key: "inferredType", label: "Inferred" },
              {
                key: "logicalType",
                label: "Logical type",
                render: (row) => (
                  <select
                    aria-label={`Logical type for ${row.name}`}
                    value={row.logicalType}
                    onChange={(event) => updateSchemaColumn(row.name, { logicalType: event.target.value })}
                  >
                    {logicalTypes.map((type) => <option key={type}>{type}</option>)}
                  </select>
                )
              },
              {
                key: "role",
                label: "Role",
                render: (row) => (
                  <select
                    aria-label={`Column role for ${row.name}`}
                    value={row.role}
                    onChange={(event) => updateSchemaColumn(row.name, { role: event.target.value as DataScienceColumnRole })}
                  >
                    {columnRoles.map((role) => <option key={role}>{role}</option>)}
                  </select>
                )
              },
              {
                key: "nullable",
                label: "Nullable",
                render: (row) => (
                  <input
                    aria-label={`Nullable ${row.name}`}
                    type="checkbox"
                    checked={row.nullable}
                    onChange={(event) => updateSchemaColumn(row.name, { nullable: event.target.checked })}
                  />
                )
              }
            ]}
            rows={schemaColumns}
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
        {activeTab === "sampling" ? (
          <div className="control-panel-grid">
            <label>
              <span>Preview sample</span>
              <select value={sampleSize} onChange={(event) => setSampleSize(event.target.value)}>
                <option value="all">All filtered rows</option>
                <option value="2">First 2 rows</option>
                <option value="3">First 3 rows</option>
                <option value="5">First 5 rows</option>
              </select>
            </label>
            <p className="empty-state">Sampling changes the visible preview only. Persisted stratified sampling remains a gateway contract follow-up.</p>
          </div>
        ) : null}
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
