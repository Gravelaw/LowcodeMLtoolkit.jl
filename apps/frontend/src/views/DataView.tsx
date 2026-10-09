import { useMemo, useRef, useState } from "react";
import type { KeyboardEvent } from "react";
import { Card, CodeBlock, DataTable, StatusPill } from "../components/ui";
import { InteractiveChart } from "../components/InteractiveChart";
import { localCode } from "../fixtures/local-fixtures";
import type { ActionFeedback, AppData } from "../types";
import type { DatasetEditIdentity } from "../dataset-edit-boundary";
import type {
  DataScienceColumnRole,
  DataScienceProjectDatasetRole,
  DataScienceSplitStrategy,
  DatasetSplitPlan,
  GatewayDataImportProfile,
  GatewayDataSourceOption,
  ProjectDataset,
  SchemaColumnContract,
  UpdateDataScienceProjectRequest
} from "@juliaflow/contracts";

type DataTab = "table" | "schema" | "profile" | "filters" | "sort" | "joins" | "transforms" | "sampling" | "lineage";

const dataTabs: DataTab[] = ["table", "schema", "profile", "filters", "sort", "joins", "transforms", "sampling", "lineage"];
const columnRoles: DataScienceColumnRole[] = ["feature", "target", "id", "group", "time", "depth", "sensitive", "ignore"];
const datasetRoles: DataScienceProjectDatasetRole[] = ["train", "validation", "test", "evaluation", "output", "reference"];
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

function splitFractionLabel(value: number | undefined): string {
  return typeof value === "number" && Number.isFinite(value)
    ? `${Math.round(value * 100)}%`
    : "unavailable";
}

function compareValues(a: unknown, b: unknown) {
  if (typeof a === "number" && typeof b === "number") return a - b;
  return String(a ?? "").localeCompare(String(b ?? ""));
}

function uniqueValues(rows: Array<Record<string, unknown>>, field: string) {
  return Array.from(new Set(rows.map((row) => String(row[field] ?? "")).filter(Boolean))).slice(0, 6);
}

function moveDataTabFocus(event: KeyboardEvent<HTMLButtonElement>, index: number, select: (tab: DataTab) => void) {
  const direction = event.key === "ArrowRight" ? 1 : event.key === "ArrowLeft" ? -1 : 0;
  const nextIndex = event.key === "Home" ? 0 : event.key === "End" ? dataTabs.length - 1 : direction ? (index + direction + dataTabs.length) % dataTabs.length : -1;
  if (nextIndex < 0) return;
  event.preventDefault();
  select(dataTabs[nextIndex]);
  event.currentTarget.parentElement?.querySelectorAll<HTMLButtonElement>("[role='tab']")[nextIndex]?.focus();
}

function semanticColumnOption(schemaColumns: SchemaColumnContract[], role: DataScienceColumnRole) {
  return schemaColumns.find((column) => column.role === role)?.name ?? "";
}

function wizardRoleForColumn(column: SchemaColumnContract): DataScienceColumnRole {
  const name = column.name.toLowerCase();
  if (/(^|_)(churn|label|target|outcome|response)($|_)/.test(name)) return "target";
  if (/(^|_)(id|uuid|key)($|_)/.test(name)) return "id";
  if (/(group|segment|contract|category|class)/.test(name)) return "group";
  if (/(date|time|timestamp|tenure)/.test(name)) return "time";
  if (/(depth|measured_depth|tvd)/.test(name)) return "depth";
  if (/(email|phone|ssn|token|secret|password)/.test(name)) return "sensitive";
  return column.role === "ignore" ? "ignore" : "feature";
}

function newestBy<T>(items: T[], timestamp: (item: T) => string | undefined): T | undefined {
  return [...items].sort((left, right) => (timestamp(right) ?? "").localeCompare(timestamp(left) ?? ""))[0];
}

export function DataView({
  data,
  onImport,
  onSelectProfile,
  onProjectUpdate,
  feedback
}: {
  data: AppData;
  onImport: (request?: ReturnType<typeof sourceRequest>) => void | Promise<void>;
  onSelectProfile: (profile: GatewayDataImportProfile) => void;
  onProjectUpdate: (request: UpdateDataScienceProjectRequest, identity: DatasetEditIdentity) => void;
  feedback?: ActionFeedback;
}) {
  const [importSource, setImportSource] = useState("");
  const [importDataset, setImportDataset] = useState("");
  const [importing, setImporting] = useState(false);
  const importLock = useRef(false);
  async function importLocalCsv() {
    if (importLock.current || !data.dataScienceProject.projectId || !importSource.trim() || !importDataset.trim()) return;
    importLock.current = true;
    setImporting(true);
    try { await onImport({ datasetId: importDataset.trim(), sourceUri: importSource.trim(), format: "csv", targetZone: "raw", readMode: "csv" }); }
    finally { importLock.current = false; setImporting(false); }
  }
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
  const projectDataset = project.datasets.find((dataset) => dataset.datasetId === activeProfile.datasetId);
  const schemaContract = project.schemaContracts.find((schema) => schema.datasetId === activeProfile.datasetId);
  const schemaColumns = schemaContract?.columns ?? [];
  const canEditDataset = Boolean(projectDataset && schemaContract);
  function submitProjectUpdate(request: UpdateDataScienceProjectRequest) {
    if (!canEditDataset) return;
    onProjectUpdate(request, { projectId: project.projectId, datasetId: activeProfile.datasetId });
  }
  const activeSplitPlan = project.splitPlans.find((plan) => plan.datasetId === activeProfile.datasetId);
  const finalTestLock = activeSplitPlan
    ? project.finalTestLocks.find((lock) => lock.splitPlanId === activeSplitPlan.splitPlanId)
    : undefined;
  const latestDataProfileJob = newestBy(
    project.projectJobs.filter((job) => job.jobType === "data_profile" && (!job.datasetId || job.datasetId === activeProfile.datasetId)),
    (job) => job.startedAt
  );
  const latestStatisticalRun = newestBy(
    project.statisticalAnalysisRuns.filter((run) => !run.datasetId || run.datasetId === activeProfile.datasetId),
    (run) => run.createdAt
  );
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
  const wizardTarget = semanticColumnOption(schemaColumns, "target");
  const wizardId = semanticColumnOption(schemaColumns, "id");
  const wizardGroup = semanticColumnOption(schemaColumns, "group");
  const wizardTime = semanticColumnOption(schemaColumns, "time");
  const wizardDepth = semanticColumnOption(schemaColumns, "depth");
  const wizardSensitiveCount = schemaColumns.filter((column) => column.role === "sensitive").length;
  const wizardReady = Boolean(projectDataset && schemaContract && activeSplitPlan && wizardTarget && wizardId && finalTestLock);

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
    if (!canEditDataset || !schemaContract) return;
    const updatedSchema = {
      ...schemaContract,
      updatedAt: new Date().toISOString(),
      columns: schemaContract.columns.map((column) => (
        column.name === columnName
          ? { ...column, ...patch }
          : column
      ))
    };
    submitProjectUpdate({
      schemaContracts: project.schemaContracts.map((schema) => (
        schema.schemaId === updatedSchema.schemaId ? updatedSchema : schema
      ))
    });
  }

  function updateProjectDataset(dataset: ProjectDataset) {
    if (!canEditDataset || dataset.datasetId !== activeProfile.datasetId) return;
    submitProjectUpdate({
      datasets: project.datasets.map((item) => (
        item.datasetId === dataset.datasetId ? dataset : item
      ))
    });
  }

  function updateSplitPlan(patch: Partial<DatasetSplitPlan>) {
    if (!canEditDataset || !activeSplitPlan) return;
    const updatedPlan = {
      ...activeSplitPlan,
      ...patch
    };
    submitProjectUpdate({
      splitPlans: project.splitPlans.map((plan) => (
        plan.splitPlanId === updatedPlan.splitPlanId ? updatedPlan : plan
      ))
    });
  }

  function applyWizardDefaults() {
    if (!canEditDataset || !schemaContract || !activeSplitPlan) return;
    const nextColumns = schemaContract.columns.map((column) => ({
      ...column,
      role: wizardRoleForColumn(column),
      logicalType: column.logicalType || column.inferredType
    }));
    const targetColumn = nextColumns.find((column) => column.role === "target")?.name;
    const groupColumn = nextColumns.find((column) => column.role === "group")?.name;
    const timeColumn = nextColumns.find((column) => column.role === "time")?.name;
    const depthColumn = nextColumns.find((column) => column.role === "depth")?.name;
    submitProjectUpdate({
      schemaContracts: project.schemaContracts.map((schema) => (
        schema.schemaId === schemaContract.schemaId
          ? { ...schemaContract, columns: nextColumns, updatedAt: new Date().toISOString() }
          : schema
      )),
      splitPlans: project.splitPlans.map((plan) => (
        plan.splitPlanId === activeSplitPlan.splitPlanId
          ? {
              ...activeSplitPlan,
              strategy: groupColumn ? "stratified" : "random",
              groupColumn,
              timeColumn,
              depthColumn,
              trainFraction: activeSplitPlan.trainFraction ?? 0.7,
              validationFraction: activeSplitPlan.validationFraction ?? 0.15,
              testFraction: activeSplitPlan.testFraction ?? 0.15
            }
          : plan
      )),
      datasets: projectDataset
        ? project.datasets.map((dataset) => (
            dataset.datasetId === projectDataset.datasetId
              ? { ...dataset, role: targetColumn ? "train" : dataset.role }
              : dataset
          ))
        : project.datasets
    });
  }

  function lockFinalTestSplit() {
    if (!canEditDataset || !activeSplitPlan) return;
    const lock = finalTestLock ?? {
      lockId: `lock-${activeSplitPlan.splitPlanId}`,
      splitPlanId: activeSplitPlan.splitPlanId,
      lockedAt: new Date().toISOString(),
      reason: "Final test split locked from Data workspace before model tuning or promotion.",
      lockedBy: "local-user"
    };
    submitProjectUpdate({
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
          <p>{project.projectId ? project.name : "Open or create a saved project to import data."} All data is stored and processed locally on this machine.</p>
        </div>
        <div className="button-row">
          <button type="button" className="jf-button primary" disabled={!activeProfile.datasetId || !project.projectId || importing} onClick={() => onImport(sourceRequest(activeProfile, activeOption))}>
            Re-profile Active Dataset
          </button>
        </div>
      </section>
      {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

      <section className="wide csv-import-form" aria-label="Import CSV into saved project">
        <label>Dataset ID<input value={importDataset} onChange={(event) => setImportDataset(event.target.value)} /></label>
        <label>Approved local CSV path<input value={importSource} onChange={(event) => setImportSource(event.target.value)} placeholder="local://data/raw/example.csv" /></label>
        <button type="button" className="jf-button primary" disabled={!project.projectId || importing || !importSource.trim() || !importDataset.trim()} onClick={() => void importLocalCsv()}>{importing ? "Importing…" : "Import Local Data"}</button>
        <p>Unquoted CSV only, unique headers, up to 1,000 rows and 8 MiB. The gateway validates the approved source and checksum.</p>
      </section>
      {!activeProfile.profileScope ? <p className="wide feedback info">{activeProfile.datasetId ? "Saved dataset metadata reopened. Full profiling details and preview are unavailable; no automatic re-import was performed." : "No dataset imported into this project."}</p> : null}
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
          <div><span>Preview / saved rows</span><strong>{preview.length.toLocaleString()} / {activeProfile.rowCount.toLocaleString()}</strong></div>
          <div><span>Columns</span><strong>{activeProfile.schemaSummary.length}</strong></div>
          <div><span>Missing Values</span><strong>{activeProfile.profileScope ? activeProfile.profileSummary.reduce((sum, field) => sum + (field.missingCount ?? 0), 0).toLocaleString() : "unavailable"}</strong></div>
          <div><span>Quality</span><strong>{qualityHighlight ?? "unavailable"}</strong></div>
          <div><span>Source</span><strong>{activeProfile.activeReadMode ?? activeProfile.sourceFormat}</strong></div>
        </div>
        <button type="button" className="jf-button secondary full-width" disabled={!activeProfile.datasetId || !project.projectId || importing} onClick={() => onImport(sourceRequest(activeProfile, activeOption))}>
          Re-profile Active Read Mode
        </button>
      </Card>

      <Card title="Project Schema Diagnostics" eyebrow={project.projectId} className="right-panel">
        {projectDataset ? <div className="key-values wrap-values" aria-label="Saved dataset metadata">
          <span>Dataset ID</span><strong>{projectDataset.datasetId}</strong>
          <span>Saved source</span><strong>{projectDataset.sourceUri}</strong>
          <span>Saved artifact</span><strong>{projectDataset.artifactRef ?? "unavailable"}</strong>
          <span>Source checksum</span><strong>{projectDataset.checksumSha256 ?? "unavailable"}</strong>
          <span>Saved rows</span><strong>{projectDataset.rowCount ?? "unavailable"}</strong>
          <span>Saved columns</span><strong>{projectDataset.columnCount ?? "unavailable"}</strong>
        </div> : null}
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

      <Card title="Local Dataset Wizard" eyebrow="Project-backed onboarding" className="right-panel">
        {projectDataset && schemaContract && activeSplitPlan ? (
          <div className="dataset-wizard">
            <div className="key-values wrap-values">
              <span>Dataset</span><strong>{projectDataset.name}</strong>
              <span>Source grant</span><strong>{projectDataset.localOnly ? "local-only" : "blocked"}</strong>
              <span>Dataset role</span><strong>{projectDataset.role}</strong>
              <span>Target</span><strong>{wizardTarget || "not assigned"}</strong>
              <span>Identifier</span><strong>{wizardId || "not assigned"}</strong>
              <span>Group</span><strong>{wizardGroup || "not assigned"}</strong>
              <span>Time/depth</span><strong>{[wizardTime, wizardDepth].filter(Boolean).join(" / ") || "not assigned"}</strong>
              <span>Sensitive</span><strong>{wizardSensitiveCount}</strong>
              <span>Final test</span><strong>{finalTestLock ? "locked" : "unlocked"}</strong>
            </div>
            <div className="control-panel-grid single">
              <label>
                <span>Dataset role</span>
                <select
                  disabled={!canEditDataset}
                  aria-label="Dataset role"
                  value={projectDataset.role}
                  onChange={(event) => updateProjectDataset({ ...projectDataset, role: event.target.value as DataScienceProjectDatasetRole })}
                >
                  {datasetRoles.map((role) => <option key={role}>{role}</option>)}
                </select>
              </label>
              <button type="button" className="jf-button secondary full-width" disabled={!canEditDataset} onClick={applyWizardDefaults}>
                Apply Role Suggestions
              </button>
              <button type="button" className="jf-button primary full-width" disabled={!canEditDataset || Boolean(finalTestLock)} onClick={lockFinalTestSplit}>
                {finalTestLock ? "Final Test Locked" : "Lock Wizard Split"}
              </button>
            </div>
            <p className={`workflow-guidance ${wizardReady ? "ready" : "blocked"}`} aria-live="polite">
              {wizardReady
                ? "Dataset onboarding is ready for split-aware EDA, baseline training, validation-only tuning, and final evaluation."
                : "Assign target and id roles, choose a validation strategy, then lock the final test split before tuning or model promotion."}
            </p>
          </div>
        ) : (
          <p className="empty-state">The displayed dataset has no matching project dataset, schema contract, or split plan. Select or import a matching dataset before editing.</p>
        )}
      </Card>

      <Card title="Validation And Test Plan" className="right-panel">
        {activeSplitPlan ? (
          <div className="control-panel-grid single">
            <label>
              <span>Validation strategy</span>
              <select
                disabled={!canEditDataset}
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
                disabled={!canEditDataset}
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
                disabled={!canEditDataset}
                aria-label="Validation depth column"
                value={activeSplitPlan.depthColumn ?? ""}
                onChange={(event) => updateSplitPlan({ depthColumn: event.target.value || undefined })}
              >
                <option value="">None</option>
                {schemaColumns.map((column) => <option key={column.name}>{column.name}</option>)}
              </select>
            </label>
            <p className="workspace-state-line">
              Train / validation / test: <strong>{splitFractionLabel(activeSplitPlan.trainFraction)}</strong> / <strong>{splitFractionLabel(activeSplitPlan.validationFraction)}</strong> / <strong>{splitFractionLabel(activeSplitPlan.testFraction)}</strong>
            </p>
            <button type="button" className="jf-button secondary full-width" disabled={!canEditDataset || Boolean(finalTestLock)} onClick={lockFinalTestSplit}>
              {finalTestLock ? "Final Test Locked" : "Lock Final Test Split"}
            </button>
            {finalTestLock ? <p className="empty-state">Locked by {finalTestLock.lockedBy}: {finalTestLock.reason}</p> : null}
          </div>
        ) : (
          <p className="empty-state">No split plan is attached to this project yet.</p>
        )}
      </Card>

      <Card title="Project Data Workflow Evidence" className="right-panel">
        <div className="key-values wrap-values">
          <span>Profile Job</span><strong>{latestDataProfileJob?.jobId ?? "No project profile job"}</strong>
          <span>Profile Execution</span><strong>{latestDataProfileJob?.executionEvidence?.executionId ?? "pending"}</strong>
          <span>Statistical Run</span><strong>{latestStatisticalRun?.analysisRunId ?? "No statistical run"}</strong>
          <span>Method</span><strong>{latestStatisticalRun ? `${latestStatisticalRun.method} (${latestStatisticalRun.status})` : "No statistical evidence"}</strong>
          <span>Result</span><strong>{latestStatisticalRun?.resultRef ?? "No result artifact"}</strong>
          <span>Code</span><strong>{latestStatisticalRun?.generatedCodeRef ?? "No generated statistics code"}</strong>
          <span>Artifacts</span><strong>{latestStatisticalRun?.artifactRefs?.map((ref) => ref.path ?? ref.refId).join(", ") || "No artifacts"}</strong>
        </div>
      </Card>

      <Card title="Dataset Catalog" eyebrow={data.runtimeMode === "demo" ? "Local fixtures" : "Saved project datasets"}>
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
              className={`source-card ${option.mode === activeProfile.activeReadMode ? "active" : ""} ${option.status === "unavailable" ? "disabled" : ""}`}
              key={option.mode}
              disabled={option.status === "unavailable"}
              title={option.status === "unavailable" ? option.semantics : option.label}
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
          {dataTabs.map((tab, index) => (
            <button
              type="button"
              role="tab"
              id={`data-tab-${tab}`}
              tabIndex={activeTab === tab ? 0 : -1}
              key={tab}
              className={activeTab === tab ? "active" : ""}
              aria-selected={activeTab === tab}
              onClick={() => setActiveTab(tab)}
              onKeyDown={(event) => moveDataTabFocus(event, index, setActiveTab)}
            >
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
            <p className="empty-state">{!activeProfile.profileScope ? "Saved preview unavailable. Re-profile the local dataset to load a preview." : "No preview rows match the active filter. Clear filters or re-profile the local dataset."}</p>
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
                    disabled={!canEditDataset}
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
                    disabled={!canEditDataset}
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
                    disabled={!canEditDataset}
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
        {data.runtimeMode === "demo" ? <CodeBlock label="data/import_profile.jl">{localCode.data}</CodeBlock> : <p className="empty-state">Generated import code is unavailable in saved project metadata.</p>}
      </Card>
    </div>
  );
}
