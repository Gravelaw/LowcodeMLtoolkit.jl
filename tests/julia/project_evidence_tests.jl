evidence_policy = JuliaFlowApiGateway.JuliaFlowDataScienceProjectEvidence
for mode in ("release", "local-appliance")
    @test_throws "source evidence unavailable" evidence_policy.require_result(nothing, mode, "analysis")
    @test_throws "source evidence unavailable" evidence_policy.require_result(Dict("metric" => NaN), mode, "analysis")
    @test_throws "source evidence unavailable" evidence_policy.require_evaluation(Dict("approved" => true), mode, "approval")
end
for mode in ("demo", "development")
    @test evidence_policy.require_result(nothing, mode, "analysis") === nothing
    @test evidence_policy.require_evaluation(Dict("approved" => true), mode, "approval")["approved"]
end

function evidence_test_payload()
    return Dict{String,Any}(
        "projectId" => "evidence-project", "name" => "Evidence Boundary",
        "datasets" => [Dict("datasetId" => "evidence-data", "name" => "Evidence", "role" => "train",
            "sourceUri" => "local://data/raw/evidence.csv", "localOnly" => true)],
        "splitPlans" => [Dict("splitPlanId" => "evidence-split", "datasetId" => "evidence-data",
            "strategy" => "random", "trainFraction" => 0.6, "validationFraction" => 0.2,
            "testFraction" => 0.2, "seed" => 5, "locked" => true, "createdAt" => "2026-09-20T00:00:00Z")],
    )
end

function evidence_files(root; exclude = "")
    return Dict(relpath(joinpath(dir, file), root) => bytes2hex(sha256(read(joinpath(dir, file))))
        for (dir, _, files) in walkdir(root) for file in files if joinpath(dir, file) != exclude)
end

for mode in ("release", "local-appliance")
    local_root = mktempdir()
    data_root = joinpath(local_root, "data")
    mkpath(joinpath(data_root, "raw"))
    source_path = joinpath(data_root, "raw", "evidence.csv")
    withenv("JULIAFLOW_RUNTIME_MODE" => mode, "JULIAFLOW_AUTH_MODE" => "required",
        "JULIAFLOW_DEV_AUTH_TOKEN" => "evidence-test-token", "JULIAFLOW_HOME" => local_root,
        "JULIAFLOW_DATA_ESTATE_ROOT" => data_root) do
        state = foundation_state(joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml"); store_root = joinpath(local_root, "store"))
        headers = ["Authorization" => "Bearer evidence-test-token", "Content-Type" => "application/json"]
        send(path, body) = route_request(state, HTTP.Request("POST", path, headers, JSON3.write(body)))
        base = "/api/v1/data-science-projects/evidence-project"
        created = send("/api/v1/data-science-projects", evidence_test_payload())
        @test created.status == 201
        stats_body = Dict("datasetId" => "evidence-data", "methods" => ["summary"], "targetColumn" => "y")
        tuning_body = Dict("datasetId" => "evidence-data", "splitPlanId" => "evidence-split",
            "targetColumn" => "y", "algorithm" => "LinearRegressor", "metricNames" => ["rmse"],
            "maxTrials" => 2, "finalTestPolicy" => "forbid_final_test")
        training_body = Dict("projectId" => "evidence-project", "datasetId" => "evidence-data",
            "splitPlanId" => "evidence-split", "target" => "y", "algorithm" => "LinearRegressor",
            "finalTestPolicy" => "forbid_final_test")
        repo_module = JuliaFlowApiGateway.JuliaFlowGatewayRepository
        snapshot() = deepcopy(repo_module.data_science_project_payload(state.data_science_projects["evidence-project"]))
        function rejected_without_product_changes(path, body; unreadable_source = false)
            before = snapshot()
            excluded = unreadable_source ? source_path : ""
            before_files = evidence_files(data_root; exclude = excluded)
            executions_before = length(state.executions)
            response = send(path, body)
            @test response.status == 409
            @test occursin("source evidence unavailable", String(response.body))
            @test snapshot() == before
            @test evidence_files(data_root; exclude = excluded) == before_files
            @test length(state.executions) == executions_before
        end
        for content in (nothing, "x,y\na,b\nc,d\n", "x,y\nNaN,NaN\nInf,Inf\nNaN,NaN\n")
            content === nothing || write(source_path, content)
            rejected_without_product_changes(base * "/statistical-analysis/run", stats_body)
            rejected_without_product_changes(base * "/tuning/run", tuning_body)
            rejected_without_product_changes("/api/v1/workflows/wf-foundation/ml/experiments/run", training_body)
        end
        # A directory is an unsuitable source; no claim of OS ACL permission coverage.
        rm(source_path)
        mkdir(source_path)
        rejected_without_product_changes(base * "/statistical-analysis/run", stats_body)
        rm(source_path)

        write(source_path, "x,y\n" * join(["$(index),$(2 * index + 1)" for index in 1:20], "\n") * "\n")
        original_source = read(source_path)
        if Sys.iswindows()
            # Deny shared reads without changing ACLs or affecting any user-owned path.
            handle = ccall((:CreateFileW, "kernel32"), Ptr{Cvoid},
                (Cwstring, UInt32, UInt32, Ptr{Cvoid}, UInt32, UInt32, Ptr{Cvoid}),
                source_path, 0x80000000, 0, C_NULL, 3, 0x80, C_NULL)
            @test handle != Ptr{Cvoid}(typemax(UInt))
            try
                rejected_without_product_changes(base * "/statistical-analysis/run", stats_body; unreadable_source = true)
                rejected_without_product_changes(base * "/tuning/run", tuning_body; unreadable_source = true)
                rejected_without_product_changes("/api/v1/workflows/wf-foundation/ml/experiments/run", training_body; unreadable_source = true)
            finally
                ccall((:CloseHandle, "kernel32"), Int32, (Ptr{Cvoid},), handle)
            end
        else
            original_mode = stat(source_path).mode & 0o777
            chmod(source_path, 0o000)
            try
                if ccall(:geteuid, Cuint, ()) == 0
                    @test_skip false # Root bypasses file permission checks.
                else
                    rejected_without_product_changes(base * "/statistical-analysis/run", stats_body; unreadable_source = true)
                    rejected_without_product_changes(base * "/tuning/run", tuning_body; unreadable_source = true)
                end
            finally
                chmod(source_path, original_mode)
            end
        end
        @test read(source_path) == original_source
        @test send(base * "/statistical-analysis/run", stats_body).status == 201
        training_response = send("/api/v1/workflows/wf-foundation/ml/experiments/run", training_body)
        @test training_response.status == 202
        training = JSON3.read(String(training_response.body), Dict{String,Any})["experiment"]
        @test Set(keys(training["metrics"])) == Set(["trainR2", "trainSse"])
        tuning_response = send(base * "/tuning/run", tuning_body)
        @test tuning_response.status == 201
        tuning = JSON3.read(String(tuning_response.body), Dict{String,Any})
        evaluation_body = Dict("datasetId" => "evidence-data", "splitPlanId" => "evidence-split",
            "trainingPlanId" => tuning["trainingPlan"]["trainingPlanId"], "tuningStudyId" => tuning["tuningStudy"]["tuningStudyId"],
            "finalTestPolicy" => "use_final_test", "approvalThreshold" => 0.0, "metricNames" => ["rmse"])
        evaluation_response = send(base * "/evaluation/run", evaluation_body)
        @test evaluation_response.status == 201
        report = JSON3.read(String(evaluation_response.body), Dict{String,Any})["evaluationReport"]
        @test report["validationEvidence"]["evaluationExecutionMode"] == "local_csv_trained_artifact"
        prediction_body = Dict("datasetId" => "evidence-data", "evaluationReportId" => report["evaluationReportId"],
            "outputContractRef" => "local://contracts/evidence.json", "format" => "csv", "rowCount" => 3)
        # Historical approval alone cannot authorize exports, lifecycle promotion or final evaluation.
        project = state.data_science_projects["evidence-project"]
        project.evaluation_reports[1]["validationEvidence"]["evaluationExecutionMode"] = "deterministic_fallback"
        project.model_lifecycle_records = [Dict("modelId" => "historical-model", "state" => "validated",
            "evaluationReportId" => report["evaluationReportId"], "updatedAt" => "2026-09-20T00:00:00Z")]
        rejected_without_product_changes(base * "/predictions/export", prediction_body)
        rejected_without_product_changes(base * "/models/lifecycle", Dict("modelId" => "historical-model", "action" => "approve_model"))
        rejected_without_product_changes("/api/v1/workflows/wf-foundation/models/register", Dict("modelId" => "rejected-model"))
        rejected_without_product_changes("/api/v1/workflows/wf-foundation/deploy/package", Dict("modelId" => "rejected-model"))
        project.evaluation_reports[1]["validationEvidence"]["evaluationExecutionMode"] = "local_csv_trained_artifact"
        model_artifact = only(filter(item -> get(item, "kind", "") == "trained_model", training["artifactEvidence"]))
        model_path = JuliaFlowApiGateway.local_data_ref_path_for_write(model_artifact["artifactRef"])
        original_model = read(model_path)
        write(model_path, "{}")
        rejected_without_product_changes("/api/v1/workflows/wf-foundation/models/register", Dict("modelId" => "rejected-model"))
        rejected_without_product_changes("/api/v1/workflows/wf-foundation/deploy/package", Dict("modelId" => "rejected-model"))
        write(model_path, original_model)
        project.tuning_studies[1]["validationEvidence"]["tuningExecutionMode"] = "deterministic_fallback"
        rejected_without_product_changes(base * "/evaluation/run", evaluation_body)
        project.tuning_studies[1]["validationEvidence"]["tuningExecutionMode"] = "local_csv_validation_tuning"
        # A previously valid tuning run does not authorize missing/nonnumeric evaluation data.
        for content in ("x,y\na,b\nc,d\n", "")
            write(source_path, content)
            rejected_without_product_changes(base * "/evaluation/run", evaluation_body)
        end
        # Missing prediction artifact cannot create a baseline, report, or successful drift job.
        project.prediction_exports = [Dict("predictionExportId" => "missing-prediction", "evaluationReportId" => report["evaluationReportId"],
            "artifactRef" => "local://predictions/missing.csv", "format" => "csv", "rowCount" => 3,
            "validationEvidence" => Dict("datasetId" => "evidence-data", "finalEvaluationApproved" => true))]
        rejected_without_product_changes(base * "/drift/run", Dict("datasetId" => "evidence-data", "predictionExportId" => "missing-prediction"))
    end
end

withenv("JULIAFLOW_RUNTIME_MODE" => "demo", "JULIAFLOW_AUTH_MODE" => "disabled",
    "JULIAFLOW_HOME" => mktempdir(), "JULIAFLOW_DATA_ESTATE_ROOT" => mktempdir()) do
    state = foundation_state(joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml"); store_root = mktempdir())
    headers = ["Content-Type" => "application/json"]
    @test route_request(state, HTTP.Request("POST", "/api/v1/data-science-projects", headers, JSON3.write(evidence_test_payload()))).status == 201
    response = route_request(state, HTTP.Request("POST", "/api/v1/data-science-projects/evidence-project/statistical-analysis/run", headers,
        JSON3.write(Dict("datasetId" => "evidence-data", "methods" => ["summary"]))))
    @test response.status == 201
    @test occursin("fixture", String(response.body))
end
