import { Card, CodeBlock, DataTable, StatusPill } from "../components/ui";
import { localCode } from "../fixtures/local-fixtures";
import type { ActionFeedback, AppData } from "../types";
import type { GatewayDataImportProfile, GatewayDataSourceOption } from "@juliaflow/contracts";

function previewColumns(rows: Array<Record<string, unknown>>, schema: GatewayDataImportProfile["schemaSummary"]) {
  const keys = Object.keys(rows[0] ?? {});
  const ordered = [...schema.map((field) => field.name), ...keys].filter((key, index, all) => key && all.indexOf(key) === index);
  return ordered.slice(0, 6).map((key) => ({ key, label: key.replaceAll("_", " ") }));
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
  const activeProfile = data.dataProfile;
  const dataProfiles = data.dataProfiles?.length > 0 ? data.dataProfiles : [activeProfile];
  const sourceOptions = activeProfile.sourceOptions ?? [];
  const previewRows = activeProfile.previewRows ?? [];
  const preview = previewRows.length > 0 ? previewRows : [];
  const columns = previewColumns(preview, activeProfile.schemaSummary);
  const readiness = activeProfile.workflowReadiness;
  const activeOption = sourceOptions.find((option) => option.mode === activeProfile.activeReadMode) ?? sourceOptions[0];

  return (
    <div className="route-grid data-route">
      <section className="page-title">
        <div>
          <h1>Data</h1>
          <p>Import, profile, validate, and route local datasets through Arrow, Parquet, and DuckDB evidence.</p>
        </div>
        <button type="button" className="jf-button primary" onClick={() => onImport(sourceRequest(activeProfile, activeOption))}>
          Re-profile Active Dataset
        </button>
      </section>
      {feedback ? <p className={`feedback ${feedback.tone}`}>{feedback.label}</p> : null}

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

      <Card title="Dataset Preview" className="wide">
        {preview.length > 0 ? (
          <DataTable
            columns={columns}
            rows={preview}
            getRowKey={(row, index) => `${activeProfile.datasetId}-${String(row[String(columns[0]?.key ?? "row")] ?? "row")}-${index}`}
          />
        ) : (
          <p className="empty-state">No preview rows are available. Import or profile a local dataset to populate this table.</p>
        )}
      </Card>

      <Card title="Profile Summary">
        <div className="profile-cards">
          <div><span>Rows</span><strong>{activeProfile.rowCount.toLocaleString()}</strong></div>
          <div><span>Read Mode</span><strong>{activeProfile.activeReadMode ?? activeProfile.sourceFormat}</strong></div>
          <div><span>DuckDB</span><strong>{activeProfile.duckdbStatus}</strong></div>
          <div><span>Manifest</span><strong>{activeProfile.manifestReady ? "ready" : "pending"}</strong></div>
        </div>
      </Card>

      <Card title="Field Roles And Quality" className="wide">
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

      <Card title="ML Readiness" className="right-panel">
        {readiness ? (
          <div className="key-values">
            <span>Target</span><strong>{readiness.targetColumn}</strong>
            <span>Split</span><strong>{readiness.trainTestSplit}</strong>
            <span>Status</span><strong>{readiness.downstreamReady ? "ready" : "blocked"}</strong>
            <span>Next</span><strong>{readiness.recommendedNextAction}</strong>
          </div>
        ) : (
          <p className="empty-state">No modeling-readiness evidence is attached to this profile yet.</p>
        )}
      </Card>

      <Card title="Quick EDA Checks" className="wide">
        <div className="chart-grid">
          {(activeProfile.quickPlots ?? []).map((plot) => (
            <div className="chart-card" key={plot.plotId}>
              <strong>{plot.title}</strong>
              <small>{plot.kind} | {plot.field}</small>
              {plot.values.map((value) => (
                <div className="bar-row" key={value.label}>
                  <span>{value.label}</span>
                  <meter min={0} max={Math.max(...plot.values.map((item) => item.value), 1)} value={value.value} />
                </div>
              ))}
            </div>
          ))}
        </div>
      </Card>

      <Card title="Generated Julia Code" className="wide">
        <CodeBlock label="data/import_profile.jl">{localCode.data}</CodeBlock>
      </Card>
    </div>
  );
}
