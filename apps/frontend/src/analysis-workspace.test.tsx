import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { AnalyseDataPanel } from "./views/AnalyseDataPanel";
import { dataScienceProject, dataProfile } from "./fixtures/local-fixtures";
import type { AnalysisProfileResponse, DataScienceProject, RunStatisticalAnalysisResponse } from "@juliaflow/contracts";

afterEach(cleanup);
const hash = "a".repeat(64);
let fixtureId = 0;
function fixture() {
  const datasetId = dataScienceProject.datasets[0].datasetId;
  const project: DataScienceProject = { ...structuredClone(dataScienceProject), projectId: `analysis-test-${++fixtureId}`, statisticalAnalysisRuns: [] };
  const measured: AnalysisProfileResponse = { profile: { ...dataProfile, datasetId, checksumSha256: hash }, schemaFingerprint: hash, numericColumns: ["value"] };
  const actions = { load: vi.fn(async (datasetId: string) => ({ ...measured, profile: { ...measured.profile, datasetId } })), run: vi.fn(), save: vi.fn(), export: vi.fn() };
  return { datasetId, project, measured, actions };
}
describe("Durable analysis workspace", () => {
  it("retains unsaved interpretation across route remounts without presenting it as saved", async () => {
    const { project, actions } = fixture();
    const first = render(<AnalyseDataPanel project={project} actions={actions} onBuildModel={() => {}} />);
    await screen.findByText(/Measured data loaded/);
    fireEvent.change(screen.getByLabelText("Analysis question"), { target: { value: "Unsaved question" } });
    first.unmount();
    render(<AnalyseDataPanel project={project} actions={actions} onBuildModel={() => {}} />);
    await screen.findByText(/Measured data loaded/);
    expect(screen.getByLabelText("Analysis question")).toHaveValue("Unsaved question");
    expect(screen.getByText("Unsaved changes")).toBeInTheDocument();
    expect(actions.save).not.toHaveBeenCalled();
  });
  it("runs against measured identity without model choices and saves draft findings separately", async () => {
    const { project, datasetId, actions } = fixture();
    const response: RunStatisticalAnalysisResponse = { status:"completed",project,analysisRun:{analysisRunId:"run-1",datasetId,method:"summary,correlation",status:"completed",warnings:[],createdAt:"now"} };
    actions.run.mockResolvedValue(response);
    actions.save.mockImplementation(async ({ scope, ...rest }) => ({ ...project, analysisWorkspace:{...rest, scope, revision:1} }));
    render(<AnalyseDataPanel project={project} actions={actions} onBuildModel={() => {}} />);
    await screen.findByText(/Measured data loaded/);
    fireEvent.change(screen.getByLabelText("Analysis question"),{target:{value:"How do values vary?"}});
    fireEvent.click(screen.getByRole("button",{name:"Run analysis",exact:true}));
    await waitFor(() => expect(actions.run).toHaveBeenCalledTimes(1));
    expect(actions.run.mock.calls[0][0]).toEqual({datasetId,methods:["summary","correlation"],scope:{datasetChecksum:hash,schemaFingerprint:hash,question:"How do values vary?",filters:[]}});
    await screen.findByText(/Analysis computed/);
    fireEvent.click(screen.getByRole("button",{name:"Save analysis and findings"}));
    await screen.findByText("Analysis and findings saved to this project.");
    expect(actions.save.mock.calls[0]).toEqual([{revision:0,datasetId,scope:{datasetChecksum:hash,schemaFingerprint:hash,question:"How do values vary?",filters:[]},analysisRunId:"run-1",findings:[]},0]);
  });
  it("guards duplicate submission and retains errors without claiming a save", async () => {
    const { project, actions } = fixture();
    let reject!: (e: Error) => void;
    actions.run.mockReturnValue(new Promise((_, fail) => { reject=fail; }));
    render(<AnalyseDataPanel project={project} actions={actions} onBuildModel={() => {}} />);
    await screen.findByText(/Measured data loaded/);
    fireEvent.change(screen.getByLabelText("Analysis question"),{target:{value:"Question"}});
    const button=screen.getByRole("button",{name:"Run analysis",exact:true});
    fireEvent.click(button);fireEvent.click(button);
    expect(actions.run).toHaveBeenCalledTimes(1);
    reject(new Error("Source checksum changed"));
    expect(await screen.findByRole("alert")).toHaveTextContent("Source checksum changed");
    expect(screen.getByLabelText("Analysis question")).toHaveValue("Question");
    expect(actions.save).not.toHaveBeenCalled();
  });
  it("invalidates selected results when scope changes and keeps saved notes editable", async () => {
    const { project, actions, datasetId } = fixture();
    project.analysisWorkspace={revision:3,datasetId,scope:{question:"Question",filters:[],datasetChecksum:hash,schemaFingerprint:hash},analysisRunId:"saved-run",findings:[{findingId:"f",analysisRunId:"saved-run",title:"Finding",notes:"Original"}]};
    project.statisticalAnalysisRuns=[{analysisRunId:"saved-run",datasetId,method:"summary",status:"completed",warnings:[],createdAt:"now",resultSummary:{scope:{datasetChecksum:hash,schemaFingerprint:hash,sourceRowCount:3,selectedRowCount:3},summaries:[]}}];
    render(<AnalyseDataPanel project={project} actions={actions} onBuildModel={() => {}} />);
    await screen.findByText(/Measured data loaded/);
    fireEvent.change(screen.getByLabelText("Finding notes 1"),{target:{value:"Edited"}});
    expect(screen.getByRole("button",{name:"Export analysis report"})).toBeDisabled();
    expect(screen.getByRole("heading",{name:"Immutable analysis evidence"})).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText("Analysis question"),{target:{value:"Different question"}});
    expect(screen.queryByRole("heading",{name:"Immutable analysis evidence"})).not.toBeInTheDocument();
    expect(screen.getByLabelText("Finding notes 1")).toHaveValue("Edited");
    expect(actions.run).not.toHaveBeenCalled();
  });
  it("preserves finding drafts and their original dataset when selecting another dataset", async () => {
    const { project, actions, datasetId } = fixture();
    project.datasets.push({ ...project.datasets[0], datasetId: "other-data", name: "Other data" });
    project.analysisWorkspace={revision:3,datasetId,scope:{question:"Question",filters:[],datasetChecksum:hash,schemaFingerprint:hash},analysisRunId:"saved-run",findings:[{findingId:"f",analysisRunId:"saved-run",title:"Finding",notes:"Original"}]};
    project.statisticalAnalysisRuns=[{analysisRunId:"saved-run",datasetId,method:"summary",status:"completed",warnings:[],createdAt:"now",resultSummary:{scope:{datasetChecksum:hash,schemaFingerprint:hash},summaries:[]}}];
    actions.save.mockImplementation(async (workspace) => ({ ...project, analysisWorkspace: { ...workspace, revision:4 } }));
    render(<AnalyseDataPanel project={project} actions={actions} onBuildModel={() => {}} />);
    await screen.findByText(/Measured data loaded/);
    fireEvent.change(screen.getByLabelText("Finding notes 1"), {target:{value:"Keep this draft"}});
    fireEvent.change(screen.getByLabelText("Analysis dataset"), {target:{value:"other-data"}});
    await waitFor(() => expect(actions.load).toHaveBeenLastCalledWith("other-data"));
    await waitFor(() => expect(screen.getByRole("button", {name:"Save analysis and findings"})).not.toBeDisabled());
    expect(screen.getByLabelText("Finding notes 1")).toHaveValue("Keep this draft");
    expect(screen.getByText(`Immutable evidence: saved-run · Dataset: ${datasetId}`)).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", {name:"Save analysis and findings"}));
    await screen.findByText("Analysis and findings saved to this project.");
    expect(actions.save.mock.calls[0][0].findings).toEqual([{findingId:"f",analysisRunId:"saved-run",title:"Finding",notes:"Keep this draft"}]);
    expect(actions.save.mock.calls[0][0].datasetId).toBe("other-data");
  });
});
