import type { DataScienceProject, GatewayDataImportProfile } from "@juliaflow/contracts";

/** No project ID means no gateway mutation may target this empty view. */
export function emptyProject(): DataScienceProject {
  return {
    schemaVersion: "1.0", projectId: "", name: "No project selected", localOnly: true,
    createdAt: "", updatedAt: "", datasets: [], schemaContracts: [], splitPlans: [],
    splitAssignments: [], validationFolds: [], finalTestLocks: [], projectJobs: [],
    transformFitApplyRecords: [], statisticalAnalysisRuns: [], trainingPlans: [], tuningStudies: [],
    evaluationReports: [], predictionExports: [], modelRegistryRecords: [], modelLifecycleRecords: [],
    monitoringBaselines: [], driftReports: [], reproducibilityEvidence: []
  };
}

/** Reopening renders only saved metadata; it neither fabricates nor reimports a profile. */
export function savedDatasetProfiles(project: DataScienceProject): GatewayDataImportProfile[] {
  return project.datasets.map((dataset) => ({
    ...emptyProfile(), datasetId: dataset.datasetId, sourceUri: dataset.sourceUri,
    artifactRef: dataset.artifactRef ?? "", checksumSha256: dataset.checksumSha256 ?? "",
    rowCount: dataset.rowCount ?? 0,
    schemaSummary: (project.schemaContracts.find((schema) => schema.datasetId === dataset.datasetId)?.columns ?? [])
      .map((column) => ({ name: column.name, type: column.inferredType })),
    sourceFormat: "csv", targetZone: "raw", localOnly: dataset.localOnly
  }));
}

export function emptyProfile(): GatewayDataImportProfile {
  return {
    datasetId: "", sourceUri: "", sourceFormat: "unavailable", targetZone: "raw", artifactRef: "",
    artifactFormats: [], checksumSha256: "", rowCount: 0, schemaSummary: [], profileSummary: [],
    manifestReady: false, manifestChecksums: [], duckdbStatus: "unavailable", importedAt: "", localOnly: true,
    previewRows: [], charts: []
  };
}
