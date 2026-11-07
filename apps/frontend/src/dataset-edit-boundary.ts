import type { AppData } from "./types";

export interface DatasetEditIdentity {
  projectId: string;
  datasetId: string;
}

/** Validate against current state, including callbacks retained from an older render. */
export function canEditDisplayedDataset(data: AppData, identity: DatasetEditIdentity): boolean {
  const project = data.dataScienceProject;
  return data.mode !== "unavailable"
    && Boolean(identity.projectId && identity.datasetId)
    && identity.projectId === project.projectId
    && identity.datasetId === data.dataProfile.datasetId
    && project.datasets.some((dataset) => dataset.datasetId === identity.datasetId)
    && project.schemaContracts.some((schema) => schema.datasetId === identity.datasetId);
}
