if !isdefined(Main, :JuliaFlowApiGateway)
    include(joinpath(@__DIR__, "..", "..", "services", "api-gateway", "src", "JuliaFlowApiGateway.jl"))
end

module ServerOwnedEvidenceTests
using Test, HTTP, JSON3, SHA
using ..JuliaFlowApiGateway

const Repo = JuliaFlowApiGateway.JuliaFlowGatewayRepository
const ProjectCore = JuliaFlowApiGateway.JuliaFlowDataScienceProjectCore
const Evidence = JuliaFlowApiGateway.JuliaFlowDataScienceProjectEvidence

function project_body()
    Dict{String,Any}("projectId" => "server-evidence", "name" => "Server evidence",
        "datasets" => [Dict("datasetId" => "server-data", "name" => "Data", "role" => "train",
            "sourceUri" => "local://data/raw/evidence.csv", "localOnly" => true)],
        "splitPlans" => [Dict("splitPlanId" => "server-split", "datasetId" => "server-data",
            "strategy" => "random", "trainFraction" => 0.6, "validationFraction" => 0.2,
            "testFraction" => 0.2, "seed" => 5, "locked" => true)])
end

function forged_report()
    Dict{String,Any}("evaluationReportId" => "forged", "trainingPlanId" => "training",
        "splitPlanId" => "server-split", "finalTestOnly" => true, "approved" => true,
        "metrics" => Dict("rmse" => 1.0), "validationEvidence" => Dict(
            "projectId" => "server-evidence", "datasetId" => "server-data",
            "splitPlanId" => "server-split", "finalTestPolicy" => "use_final_test",
            "tuningExecutionMode" => "local_csv_validation_tuning",
            "evaluationExecutionMode" => "local_csv_trained_artifact",
            "evaluationDataEvidence" => Dict("executionMode" => "local_csv_trained_artifact",
                "sourceRef" => "local://data/raw/evidence.csv", "trainRowCount" => 12,
                "testRowCount" => 4)))
end

@testset "server-owned aggregate admission" begin
    fake = forged_report()
    @test Repo.JuliaFlowProjectPayloadValidation.validate_project_children!(Dict("evaluationReports" => [fake])) isa AbstractDict
    # This payload meets the former strict shape guard, but carries no producer.
    @test Evidence.require_evaluation(fake, "release", "approval") === fake
    @test_throws "server-owned execution evidence" ProjectCore.materialize_project_record(merge(project_body(), Dict("evaluationReports" => [fake])))
    project = ProjectCore.materialize_project_record(project_body())
    # Restore sparse historical state through the repository loader, not admission.
    historical = merge(Repo.data_science_project_payload(project), Dict("evaluationReports" => [fake]))
    restored = Repo.gateway_data_science_project(historical)
    @test restored.evaluation_reports == [fake]
    @test_throws "source evidence unavailable" Evidence.context_evaluation(restored, Dict("evaluationReportId" => "forged"), "release", "approval"; required = true)
    @test_throws "server-owned execution evidence" ProjectCore.materialize_project_record(Dict("evaluationReports" => [merge(fake, Dict("metrics" => Dict("rmse" => 0.99)))]); existing = restored)
    @test_throws "server-owned execution evidence" ProjectCore.materialize_project_record(Dict("evaluationReports" => Any[]); existing = restored)
    echoed = JSON3.read(JSON3.write(Repo.data_science_project_payload(restored)), Dict{String,Any})
    @test ProjectCore.materialize_project_record(echoed; existing = restored).evaluation_reports == [fake]
    omitted = ProjectCore.materialize_project_record(Dict("name" => "Renamed"); existing = restored)
    @test omitted.evaluation_reports == [fake]
    omitted.evaluation_reports[1]["metrics"]["rmse"] = 0.0
    @test restored.evaluation_reports[1]["metrics"]["rmse"] == 1.0
    copied = ProjectCore.materialize_project_record(echoed; existing = restored)
    echoed["evaluationReports"][1]["approved"] = false
    @test copied.evaluation_reports[1]["approved"] === true
    for key in ProjectCore.SERVER_OWNED_PROJECT_FIELDS
        # The shared ownership guard applies equally to metadata/job copies.
        @test_throws "server-owned execution evidence" ProjectCore.protect_execution_evidence!(project, Dict(key => [Dict("copiedEvaluation" => fake)]))
        @test ProjectCore.protect_execution_evidence!(project, Dict(key => Any[])) === nothing
    end
    declaration = Dict("trainingPlanId" => "training", "targetColumn" => "y", "splitPlanId" => "server-split")
    @test length(ProjectCore.materialize_project_record(merge(project_body(), Dict("trainingPlans" => [declaration]))).training_plans) == 1
    restored.training_plans = [declaration]
    @test_throws "executed training plans are immutable" ProjectCore.materialize_project_record(Dict("trainingPlans" => [merge(declaration, Dict("targetColumn" => "other"))]); existing = restored)
end

@testset "HTTP admission and genuine producer evidence" begin
    for mode in ("release", "local-appliance", "demo")
        mktempdir() do root
            data_root = joinpath(root, "data")
            mkpath(joinpath(data_root, "raw"))
            source_path = joinpath(data_root, "raw", "evidence.csv")
            write(source_path, "x,y\n" * join(["$(i),$(2i + 1)" for i in 1:20], "\n") * "\n")
            withenv("JULIAFLOW_RUNTIME_MODE" => mode, "JULIAFLOW_AUTH_MODE" => "required",
                "JULIAFLOW_DEV_AUTH_TOKEN" => "server-evidence-token", "JULIAFLOW_HOME" => root,
                "JULIAFLOW_DATA_ESTATE_ROOT" => data_root) do
                state = foundation_state(joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml"); store_root = joinpath(root, "store"))
                headers = ["Authorization" => "Bearer server-evidence-token", "Content-Type" => "application/json"]
                send(method, path, body) = route_request(state, HTTP.Request(method, path, headers, JSON3.write(body)))
                path = "/api/v1/data-science-projects/server-evidence"
                files() = Dict(relpath(joinpath(dir, file), data_root) => bytes2hex(sha256(read(joinpath(dir, file)))) for (dir, _, fs) in walkdir(data_root) for file in fs)
                before = files()
                rejected = send("POST", "/api/v1/data-science-projects", merge(project_body(), Dict("evaluationReports" => [forged_report()])))
                @test rejected.status == 400
                @test isempty(state.data_science_projects)
                @test files() == before
                @test send("POST", "/api/v1/data-science-projects", project_body()).status == 201
                snapshot() = deepcopy(Repo.data_science_project_payload(state.data_science_projects["server-evidence"]))
                before = snapshot()
                before_files = files()
                executions = length(state.executions)
                @test send("PUT", path, Dict("evaluationReports" => [forged_report()])).status == 400
                @test snapshot() == before
                @test files() == before_files
                @test length(state.executions) == executions
                @test send("PUT", path, before).status == 200
                @test send("PUT", path, Dict("name" => "Updated")).status == 200
                mode == "demo" && return
                legitimate_project = deepcopy(state.data_science_projects["server-evidence"])
                historical_report = forged_report()
                historical_report["executionEvidence"] = Dict("executionId" => "historical-execution", "workflowId" => "wf-foundation", "status" => "completed", "mode" => "local_project_job")
                historical_report["validationEvidence"]["executionId"] = "historical-execution"
                historical_report["validationEvidence"]["evaluationDataEvidence"]["featureColumn"] = "x"
                historical_report["validationEvidence"]["evaluationDataEvidence"]["modelKind"] = "local_csv_single_feature_ols"
                historical_report["validationEvidence"]["evaluationDataEvidence"]["trainingRowIndices"] = collect(1:12)
                historical_report["validationEvidence"]["evaluationDataEvidence"]["coefficients"] = Dict("slope" => 2.0, "intercept" => 1.0)
                historical_job = Dict("jobId" => "historical-job", "projectId" => "server-evidence", "jobType" => "final_evaluation", "status" => "completed", "sourceRecordId" => "forged", "datasetId" => "server-data", "splitPlanId" => "server-split", "executionEvidence" => historical_report["executionEvidence"], "outputRefs" => Any[], "startedAt" => "2026-09-20T00:00:00Z")
                historical_prediction = Dict("predictionExportId" => "historical-prediction", "evaluationReportId" => "forged", "artifactRef" => "local://predictions/historical.csv", "format" => "csv", "rowCount" => 3, "validationEvidence" => Dict("datasetId" => "server-data", "finalEvaluationApproved" => true))
                historical_path = JuliaFlowApiGateway.local_data_ref_path_for_write(historical_prediction["artifactRef"])
                mkpath(dirname(historical_path))
                write(historical_path, "prediction\n3\n5\n7\n")
                historical_project = Repo.gateway_data_science_project(merge(snapshot(), Dict("evaluationReports" => [historical_report], "projectJobs" => [historical_job], "predictionExports" => [historical_prediction])))
                state.data_science_projects["server-evidence"] = historical_project
                historical_before = snapshot()
                historical_files = files()
                historical_executions = length(state.executions)
                @test send("POST", path * "/predictions/export", Dict("datasetId" => "server-data", "evaluationReportId" => "forged", "outputContractRef" => "local://contracts/prediction.json", "format" => "csv", "rowCount" => 3)).status == 409
                @test send("POST", path * "/drift/run", Dict("datasetId" => "server-data", "predictionExportId" => "historical-prediction")).status == 409
                @test snapshot() == historical_before
                @test files() == historical_files
                @test length(state.executions) == historical_executions
                state.data_science_projects["server-evidence"] = legitimate_project
                training = send("POST", "/api/v1/workflows/wf-foundation/ml/experiments/run", Dict("projectId" => "server-evidence", "datasetId" => "server-data", "splitPlanId" => "server-split", "target" => "y", "algorithm" => "LinearRegressor", "finalTestPolicy" => "forbid_final_test"))
                @test training.status == 202
                tuning = send("POST", path * "/tuning/run", Dict("datasetId" => "server-data", "splitPlanId" => "server-split", "targetColumn" => "y", "algorithm" => "LinearRegressor", "metricNames" => ["rmse"], "maxTrials" => 2, "finalTestPolicy" => "forbid_final_test"))
                @test tuning.status == 201
                tuning_body = JSON3.read(String(tuning.body), Dict{String,Any})
                evaluation = send("POST", path * "/evaluation/run", Dict("datasetId" => "server-data", "splitPlanId" => "server-split", "trainingPlanId" => tuning_body["trainingPlan"]["trainingPlanId"], "tuningStudyId" => tuning_body["tuningStudy"]["tuningStudyId"], "finalTestPolicy" => "use_final_test", "approvalThreshold" => 0.0, "metricNames" => ["rmse"]))
                @test evaluation.status == 201
                report = JSON3.read(String(evaluation.body), Dict{String,Any})["evaluationReport"]
                project = state.data_science_projects["server-evidence"]
                @test Evidence.context_evaluation(project, Dict("evaluationReportId" => report["evaluationReportId"]), mode, "approval"; required = true, resolve_path = JuliaFlowApiGateway.local_data_ref_path_for_write) == report
                @test JuliaFlowApiGateway.require_evaluation_consumer_evidence(project, report, "prediction export") == report
                canonical_report = JuliaFlowApiGateway.local_data_ref_path_for_write(report["artifactRefs"][1]["path"])
                report_bytes = read(canonical_report)
                @test Evidence.require_evaluation_report_artifact(report, mode, "approval", JuliaFlowApiGateway.local_data_ref_path_for_write)["metrics"] == report["metrics"]
                changed_report = deepcopy(report)
                changed_report["metrics"]["rmse"] = 0.99
                @test_throws "source evidence unavailable" Evidence.require_evaluation_report_artifact(changed_report, mode, "approval", JuliaFlowApiGateway.local_data_ref_path_for_write)
                alias_report = deepcopy(report)
                alias_report["artifactRefs"][1]["artifactRef"] = "local://evaluation/another/report.json"
                @test_throws "source evidence unavailable" Evidence.require_evaluation_report_artifact(alias_report, mode, "approval", JuliaFlowApiGateway.local_data_ref_path_for_write)
                write(canonical_report, "{}")
                @test_throws "source evidence unavailable" Evidence.require_evaluation_report_artifact(report, mode, "approval", JuliaFlowApiGateway.local_data_ref_path_for_write)
                write(canonical_report, report_bytes)
                @test send("PUT", path, snapshot()).status == 200
                registered = send("POST", "/api/v1/workflows/wf-foundation/models/register", Dict("modelId" => "server-model"))
                @test registered.status == 201
                model = JSON3.read(String(registered.body), Dict{String,Any})["model"]
                artifact = JuliaFlowApiGateway.JuliaFlowDataScienceProjectDeploy.deploy_model_artifact(model)
                payload = Evidence.require_model_artifact(artifact, mode, "approval", JuliaFlowApiGateway.local_data_ref_path_for_write)
                @test Evidence.require_evaluation_model_binding(project, report, payload, artifact, mode, "approval", JuliaFlowApiGateway.local_data_ref_path_for_write) == report
                for (key, value) in (("datasetId", "other"), ("splitPlanId", "other"), ("sourceChecksumSha256", repeat("a", 64)))
                    @test_throws "source evidence unavailable" Evidence.require_evaluation_model_binding(project, report, merge(payload, Dict(key => value)), artifact, mode, "approval", JuliaFlowApiGateway.local_data_ref_path_for_write)
                end
                @test_throws "source evidence unavailable" Evidence.require_evaluation_model_binding(project, report, payload, merge(artifact, Dict("artifactRef" => "local://models/another/model.json")), mode, "approval", JuliaFlowApiGateway.local_data_ref_path_for_write)
                @test send("POST", path * "/models/lifecycle", Dict("modelId" => "server-model", "action" => "approve_model")).status == 201
                before = snapshot()
                before_files = files()
                forged = deepcopy(report)
                forged["metrics"]["rmse"] = 0.99
                @test send("PUT", path, Dict("evaluationReports" => [forged])).status == 400
                @test send("PUT", path, Dict("projectJobs" => Any[])).status == 400
                @test send("PUT", path, Dict("modelRegistryRecords" => Any[])).status == 400
                @test snapshot() == before
                @test files() == before_files
                @test send("PUT", path, before).status == 200
                write(source_path, "x,y\n1,999\n")
                @test_throws "source evidence unavailable" Evidence.require_evaluation_model_binding(project, report, payload, artifact, mode, "approval", JuliaFlowApiGateway.local_data_ref_path_for_write)
            end
        end
    end
end
end
