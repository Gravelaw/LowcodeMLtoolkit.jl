using Test
using Base64
using HTTP
using JSON3
using SHA
using TOML

include(joinpath(@__DIR__, "..", "..", "services", "node-sdk", "src", "JuliaFlowNodeSDK.jl"))
include(joinpath(@__DIR__, "..", "..", "services", "execution-service", "src", "JuliaFlowExecutionService.jl"))
include(joinpath(@__DIR__, "..", "..", "services", "worker-service", "src", "JuliaFlowWorkerService.jl"))
include(joinpath(@__DIR__, "..", "..", "services", "api-gateway", "src", "JuliaFlowApiGateway.jl"))
include(joinpath(@__DIR__, "..", "..", "extensions", "base", "src", "JuliaFlowBaseExtension.jl"))

using .JuliaFlowNodeSDK
using .JuliaFlowExecutionService
using .JuliaFlowWorkerService
using .JuliaFlowApiGateway
using .JuliaFlowBaseExtension

include(joinpath(@__DIR__, "repository_contract_tests.jl"))

@testset "Data science project core helpers" begin
    body = Dict{String,Any}(
        "projectId" => "Wellbore Geology!",
        "schemaVersion" => "1.0",
        "name" => "Wellbore Geology",
        "description" => "Local workstation geology project",
        "datasets" => [
            Dict{String,Any}(
                "datasetId" => "Train Logs",
                "role" => "train",
                "sourceUri" => "local://raw/wellbore/train.csv",
                "artifactRef" => "local://processed/wellbore/train.arrow",
                "localOnly" => true,
            ),
        ],
        "schemaContracts" => [
            Dict{String,Any}(
                "schemaContractId" => "schema-wellbore",
                "columns" => [Dict{String,Any}("name" => "depth", "logicalType" => "continuous")],
            ),
        ],
    )
    project = JuliaFlowApiGateway.JuliaFlowDataScienceProjectCore.materialize_project_record(body)
    @test project.project_id == "wellbore-geology"
    @test project.name == "Wellbore Geology"
    @test project.description == "Local workstation geology project"
    @test project.datasets[1]["sourceUri"] == "local://raw/wellbore/train.csv"
    @test project.schema_contracts[1]["schemaContractId"] == "schema-wellbore"

    updated = JuliaFlowApiGateway.JuliaFlowDataScienceProjectCore.materialize_project_record(
        Dict{String,Any}(
            "name" => "Wellbore Geology Updated",
            "projectId" => "wellbore-geology",
            "splitPlans" => [Dict{String,Any}("splitPlanId" => "split-depth", "strategy" => "depth")],
        );
        existing = project,
        project_id_override = project.project_id,
    )
    @test updated.created_at == project.created_at
    @test updated.datasets == project.datasets
    @test updated.split_plans[1]["strategy"] == "depth"

    @test JuliaFlowApiGateway.JuliaFlowDataScienceProjectCore.project_id_from_body(
        Dict{String,Any}("projectId" => "Titanic / Baseline"),
        "Fallback",
    ) == "titanic-baseline"
    @test_throws ErrorException JuliaFlowApiGateway.JuliaFlowDataScienceProjectCore.materialize_project_record(
        Dict{String,Any}("name" => "Remote", "datasets" => [Dict{String,Any}("datasetId" => "remote", "sourceUri" => "https://example.com/data.csv")]),
    )
    @test_throws ErrorException JuliaFlowApiGateway.JuliaFlowDataScienceProjectCore.materialize_project_record(
        Dict{String,Any}("name" => "Traversal", "datasets" => [Dict{String,Any}("datasetId" => "bad", "sourceUri" => "local://raw/../secret.csv")]),
    )
    @test_throws ErrorException JuliaFlowApiGateway.JuliaFlowDataScienceProjectCore.materialize_project_record(
        Dict{String,Any}("name" => "Bad Shape", "datasets" => Dict{String,Any}("datasetId" => "bad")),
    )
    @test_throws ErrorException JuliaFlowApiGateway.JuliaFlowDataScienceProjectCore.materialize_project_record(
        Dict{String,Any}("name" => "Bad Version", "schemaVersion" => "2.0"),
    )
end

@testset "Data science project local source helpers" begin
    sources = JuliaFlowApiGateway.JuliaFlowDataScienceProjectLocalSources
    import_root = mktempdir()
    data_root = mktempdir()
    allowed_path = joinpath(import_root, "profile.csv")
    secret_path = joinpath(import_root, "secret-token.csv")
    credential_path = joinpath(import_root, "profile-with-auth-column.csv")
    escape_root = mktempdir()
    escape_path = joinpath(escape_root, "outside.csv")
    write(allowed_path, "region,amount\nnorth,12.5\n")
    write(secret_path, "region,amount\nnorth,12.5\n")
    write(credential_path, "region,access_token\nnorth,redacted\n")
    write(escape_path, "region,amount\nsouth,9.5\n")
    validate_ref = (value, label) -> JuliaFlowApiGateway.JuliaFlowDataScienceProjectCore.validate_project_local_ref!(value, label)

    roots = sources.local_data_import_roots(data_root, data_root; import_roots = import_root)
    @test realpath(import_root) in realpath.(filter(isdir, roots))
    @test sources.path_within_root(realpath(allowed_path), realpath(import_root))
    @test !sources.path_within_root(realpath(escape_path), realpath(import_root))
    @test sources.validate_local_data_import_source!(
        allowed_path;
        local_home = data_root,
        data_root = data_root,
        validate_local_ref = validate_ref,
        import_roots = import_root,
    ) == realpath(allowed_path)
    @test sources.validate_local_data_import_source!(
        "local://data/raw/profile.csv";
        local_home = data_root,
        data_root = data_root,
        validate_local_ref = validate_ref,
        import_roots = import_root,
    ) == "local://data/raw/profile.csv"
    @test_throws ErrorException sources.validate_local_data_import_source!(
        "https://example.com/data.csv";
        local_home = data_root,
        data_root = data_root,
        validate_local_ref = validate_ref,
        import_roots = import_root,
    )
    @test_throws ErrorException sources.validate_local_data_import_source!(
        escape_path;
        local_home = data_root,
        data_root = data_root,
        validate_local_ref = validate_ref,
        import_roots = import_root,
    )
    @test_throws ErrorException sources.validate_local_data_import_file!(secret_path, "csv"; max_bytes = 1024)
    @test_throws ErrorException sources.validate_local_data_import_file!(credential_path, "csv"; max_bytes = 1024)
    sources.validate_local_data_import_file!(allowed_path, "csv"; max_bytes = 1024)

    audit_details = sources.local_data_import_audit_source_details(allowed_path)
    @test audit_details["sourceKind"] == "file"
    @test audit_details["sourceBasename"] == "profile.csv"
    @test !haskey(audit_details, "sourcePath")
    remote_details = sources.local_data_import_audit_source_details("https://example.com/data.csv")
    @test remote_details["sourceKind"] == "remote"
    @test remote_details["scheme"] == "https"

    managed_data_path = joinpath(data_root, "raw", "profile.csv")
    mkpath(dirname(managed_data_path))
    write(managed_data_path, "region,amount\nnorth,12.5\n")
    @test sources.resolve_local_data_ref_path(
        "local://data/raw/profile.csv";
        local_home = data_root,
        data_root = data_root,
        validate_local_ref = validate_ref,
    ) == managed_data_path
    artifact_path = sources.local_data_ref_path_for_write(
        "local://analysis/profile/results.json";
        local_home = data_root,
        data_root = data_root,
        validate_local_ref = validate_ref,
    )
    @test sources.path_within_root(artifact_path, realpath(data_root))
    @test_throws ErrorException sources.local_data_ref_path_for_write(
        "local://analysis/../secret.json";
        local_home = data_root,
        data_root = data_root,
        validate_local_ref = validate_ref,
    )
end

@testset "Data science project catalog helpers" begin
    catalog = JuliaFlowApiGateway.JuliaFlowDataScienceProjectCatalog
    @test catalog.safe_local_dataset_id("Foundation Profile!") == "foundation-profile"
    @test catalog.safe_local_dataset_id("  ") == "workflow-dataset"
    @test length(catalog.safe_local_dataset_id(repeat("A", 100))) == 80

    health = Dict{String,Any}(
        "dataEstateDuckdbQueryPath" => "local://data/_duckdb/profile.sql",
        "dataEstateDuckdbStatus" => "ready",
    )
    options = catalog.data_source_options("Foundation Profile!", "local://data/raw/foundation-profile.csv", "raw", "duckdb", health)
    @test length(options) == 4
    @test options[1]["mode"] == "csv"
    @test only(filter(option -> option["mode"] == "duckdb", options))["status"] == "active"

    lineage = catalog.data_lineage_artifacts("Foundation Profile!", "local://data/raw/foundation-profile.csv", "raw", "abc123", 42, health)
    @test length(lineage) == 4
    @test lineage[2]["artifactRef"] == "local://data/raw/foundation-profile.arrow"
    @test lineage[3]["format"] == "parquet"
    @test lineage[4]["artifactRef"] == "local://data/_duckdb/profile.sql"

    churn_fixture = catalog.data_profile_fixture("foundation-profile", "local://data/raw/foundation-profile.csv")
    @test churn_fixture["rowCount"] == 12500
    @test !isempty(churn_fixture["schemaSummary"])
    @test !isempty(churn_fixture["profileSummary"])
    @test !isempty(churn_fixture["previewRows"])
    @test churn_fixture["workflowReadiness"]["downstreamReady"] == true
    @test !isempty(churn_fixture["quickPlots"])

    superstore_fixture = catalog.data_profile_fixture("global-superstore", "local://data/raw/superstore.csv")
    @test superstore_fixture["rowCount"] == 9800
    @test superstore_fixture["workflowReadiness"]["targetColumn"] == "profit"
    @test any(row -> row["name"] == "profit" && row["role"] == "label", superstore_fixture["profileSummary"])
end

@testset "Data science project prediction export helpers" begin
    export_helpers = JuliaFlowApiGateway.JuliaFlowDataScienceProjectPredictionExport
    @test export_helpers.prediction_export_format(Dict{String,Any}()) == "csv"
    @test export_helpers.prediction_export_format(Dict{String,Any}("format" => "JSONL")) == "jsonl"
    @test_throws ErrorException export_helpers.prediction_export_format(Dict{String,Any}("format" => "xlsx"))
    @test export_helpers.prediction_export_row_count(Dict{String,Any}(), Dict{String,Any}("rowCount" => 12)) == 12
    @test_throws ErrorException export_helpers.prediction_export_row_count(Dict{String,Any}("rowCount" => 0), Dict{String,Any}())

    body = Dict{String,Any}(
        "outputContractRef" => "contract-local",
        "outputContract" => Dict{String,Any}(
            "contractId" => "contract-local",
            "columns" => [
                Dict{String,Any}("name" => "prediction_id", "sourceColumn" => "prediction_id", "required" => true),
                Dict{String,Any}("name" => "score", "sourceColumn" => "prediction", "required" => true),
                Dict{String,Any}("name" => "dataset", "sourceColumn" => "dataset_id", "required" => false),
            ],
        ),
        "outputColumns" => ["prediction_id", "score"],
    )
    contract = export_helpers.prediction_export_contract(body, "contract-local")
    @test export_helpers.prediction_export_contract_column_names(contract) == ["prediction_id", "score", "dataset"]
    output_columns = export_helpers.prediction_export_output_columns(body, contract)
    @test output_columns == ["prediction_id", "score"]
    output_mappings = export_helpers.prediction_export_output_mappings(body, contract, output_columns)
    @test output_mappings == [
        Dict{String,Any}("outputColumn" => "prediction_id", "sourceColumn" => "prediction_id"),
        Dict{String,Any}("outputColumn" => "score", "sourceColumn" => "prediction"),
    ]
    @test_throws ErrorException export_helpers.prediction_export_contract(
        Dict{String,Any}("outputContract" => Dict{String,Any}("contractId" => "other", "columns" => [])),
        "contract-local",
    )
    @test_throws ErrorException export_helpers.prediction_export_output_columns(
        Dict{String,Any}("outputColumns" => ["prediction_id"]),
        contract,
    )
    @test_throws ErrorException export_helpers.prediction_export_output_mappings(
        Dict{String,Any}("outputMappings" => [Dict{String,Any}("outputColumn" => "score", "sourceColumn" => "unknown")]),
        contract,
        output_columns,
    )

    report = Dict{String,Any}("evaluationReportId" => "eval-1", "metrics" => Dict{String,Any}("accuracy" => 0.9, "f1" => 0.8))
    rows = export_helpers.prediction_export_rows("export-1", report, "dataset-1", "contract-local", 2)
    @test length(rows) == 2
    @test rows[1]["prediction_id"] == "export-1-1"
    @test rows[1]["prediction"] == 0.85
    selected_rows = export_helpers.selected_prediction_export_rows(rows, output_columns, output_mappings)
    @test selected_rows[1]["score"] == 0.85
    csv_content = export_helpers.prediction_export_content("csv", rows, output_columns, output_mappings)
    @test startswith(csv_content, "prediction_id,score\n")
    jsonl_content = export_helpers.prediction_export_content("jsonl", rows, output_columns, output_mappings)
    @test occursin("\"score\":0.85", jsonl_content)
end

@testset "Data science project registry payload helpers" begin
    payloads = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistryPayloads
    model_card = Dict{String,Any}(
        "modelId" => "wellbore-linear",
        "kind" => "regression",
        "target" => "formation",
        "metrics" => Dict{String,Any}("loss" => 0.22, "mae" => 0.11, "accuracy" => 0.91),
        "config" => Dict{String,Any}("algorithm" => "linear", "seed" => 42),
    )
    dataset_card = Dict{String,Any}("datasetId" => "wellbore-train", "checksumSha256" => "abc123")
    validation_context = Dict{String,Any}("projectId" => "wellbore", "splitPlanId" => "split-depth")

    metric_name, metric_value = payloads.model_registry_metric(model_card)
    @test metric_name == "mae"
    @test metric_value == 0.11
    @test payloads.model_registry_tags(Dict{String,Any}(), Dict{String,Any}()) == ["local", "checkpointed"]
    @test payloads.model_registry_tags(Dict{String,Any}(), Dict{String,Any}("tags" => ["validated"])) == ["validated"]
    @test payloads.model_registry_tags(Dict{String,Any}("tags" => ["champion"]), Dict{String,Any}("tags" => ["old"])) == ["champion"]

    record = payloads.model_registry_record(
        "wf-wellbore",
        "1.2.0",
        "exec-1",
        "cp-1",
        model_card,
        dataset_card,
        validation_context,
        Dict{String,Any}("modelId" => "wellbore-champion", "owner" => "principal-ds", "status" => "approved"),
        Dict{String,Any}("registeredAt" => "2026-06-22T00:00:00Z", "deploymentStatus" => "deployed", "tags" => ["old"]),
        "2026-06-23T00:00:00Z",
    )
    @test record["modelId"] == "wellbore-champion"
    @test record["workflowId"] == "wf-wellbore"
    @test record["workflowVersion"] == "1.2.0"
    @test record["experimentId"] == "ml-exec-1"
    @test record["owner"] == "principal-ds"
    @test record["status"] == "approved"
    @test record["tags"] == ["old"]
    @test record["primaryMetricName"] == "mae"
    @test record["primaryMetricValue"] == 0.11
    @test record["registeredAt"] == "2026-06-22T00:00:00Z"
    @test record["updatedAt"] == "2026-06-23T00:00:00Z"
    @test record["deploymentStatus"] == "deployed"
    @test record["localOnly"] == true
    @test length(record["artifactEvidence"]) == 3
    @test record["artifactEvidence"][1]["artifactRef"] == "local://models/wellbore-champion.json"
    @test record["artifactEvidence"][2]["checksumSha256"] == "abc123"
    @test record["validationEvidence"]["splitPlanId"] == "split-depth"
end

@testset "Data science project monitoring helpers" begin
    monitoring = JuliaFlowApiGateway.JuliaFlowDataScienceProjectMonitoring
    project = DataScienceProjectRecord(project_id = "monitoring-helper", name = "Monitoring Helper")
    prediction_export = Dict{String,Any}(
        "predictionExportId" => "export-helper",
        "evaluationReportId" => "eval-helper",
        "outputContractRef" => "contract://outputs/helper",
        "validationEvidence" => Dict{String,Any}("finalEvaluationApproved" => true, "datasetId" => "dataset-helper"),
    )
    project.prediction_exports = [prediction_export]

    @test monitoring.project_prediction_export_for_drift(project, Dict{String,Any}("predictionExportId" => "export-helper")) === prediction_export
    @test_throws ErrorException monitoring.project_prediction_export_for_drift(project, Dict{String,Any}("predictionExportId" => "missing-export"))
    @test monitoring.drift_metric_names(Dict{String,Any}()) == ["psi", "ks"]
    @test monitoring.drift_metric_names(Dict{String,Any}("metricNames" => ["Population Stability", "KS"])) == ["population-stability", "ks"]
    @test_throws ErrorException monitoring.drift_metric_names(Dict{String,Any}("metricNames" => []))
    @test monitoring.drift_threshold(Dict{String,Any}()) == 0.2
    @test_throws ErrorException monitoring.drift_threshold(Dict{String,Any}("threshold" => 1.5))

    timestamp = "2026-06-22T00:00:00Z"
    metrics = ["psi", "ks"]
    baseline = monitoring.monitoring_baseline_for_drift!(
        project,
        Dict{String,Any}("baselineId" => "baseline-helper"),
        "dataset-helper",
        prediction_export,
        metrics,
        timestamp,
    )
    @test baseline["baselineId"] == "baseline-helper"
    @test baseline["metricNames"] == metrics
    @test length(project.monitoring_baselines) == 1
    reused = monitoring.monitoring_baseline_for_drift!(
        project,
        Dict{String,Any}("baselineId" => "baseline-helper"),
        "dataset-helper",
        prediction_export,
        metrics,
        timestamp,
    )
    @test reused === baseline
    @test length(project.monitoring_baselines) == 1

    metric_values = monitoring.drift_metric_values(["psi", "ks", "wasserstein"])
    @test metric_values["psi"] == 0.08
    @test metric_values["wasserstein"] == 0.24
    @test monitoring.drift_status(metric_values, 0.2) == "moderate"
    @test monitoring.drift_status(metric_values, 0.1) == "high"
    report = monitoring.drift_report_record(
        project,
        baseline,
        prediction_export,
        "dataset-helper",
        metric_values,
        "moderate",
        timestamp;
        report_id = "drift-helper",
    )
    @test report["driftReportId"] == "drift-helper"
    @test report["validationEvidence"]["predictionExportId"] == "export-helper"
    output_refs = monitoring.drift_output_refs(project.project_id, "drift-helper", timestamp)
    @test output_refs[1]["path"] == "local://drift/monitoring-helper/drift-helper/report.json"
end

@testset "Data science project deploy helpers" begin
    deploy = JuliaFlowApiGateway.JuliaFlowDataScienceProjectDeploy
    endpoint = deploy.deploy_endpoint_config(Dict{String,Any}("host" => "127.0.0.1", "port" => 9000, "endpointPath" => "predict"))
    @test endpoint["endpointPath"] == "/predict"
    @test endpoint["endpointUrl"] == "http://127.0.0.1:9000/predict"

    model_record = Dict{String,Any}(
        "modelId" => "model-helper",
        "checkpointTag" => "chk-helper",
        "registryId" => "registry-helper",
        "artifactEvidence" => [
            Dict{String,Any}("kind" => "model", "artifactRef" => "local://models/model-helper.jls", "checksumSha256" => repeat("a", 64)),
            Dict{String,Any}("kind" => "metrics", "artifactRef" => "local://models/model-helper-metrics.json", "checksumSha256" => repeat("b", 64)),
        ],
    )
    @test deploy.deploy_model_ref(model_record) == "local://models/model-helper.jls"
    service_code = deploy.local_deploy_service_code("model-helper", endpoint["endpointUrl"], "local://models/model-helper.jls")
    @test occursin("model-helper", service_code)
    @test occursin(endpoint["endpointUrl"], service_code)

    artifact_evidence = deploy.deploy_artifact_evidence(
        "wf-helper",
        model_record,
        "deploy-helper",
        service_code,
        repeat("c", 64),
        repeat("d", 64),
    )
    @test length(artifact_evidence) == 5
    @test artifact_evidence[1]["artifactRef"] == "local://workflows/wf-helper.toml"
    @test artifact_evidence[2]["artifactRef"] == "local://deploy/packages/deploy-helper/service.jl"
    @test artifact_evidence[end]["kind"] == "metrics"

    package_record = deploy.deploy_package_record(
        "wf-helper",
        Dict{String,Any}("version" => "1.0.0"),
        model_record,
        Dict{String,Any}("projectId" => "project-helper", "splitPlanId" => "split-helper"),
        "deploy-helper",
        endpoint,
        service_code,
        artifact_evidence,
        "2026-06-23T00:00:00Z",
    )
    @test package_record["workflowId"] == "wf-helper"
    @test package_record["deploymentStatus"] == "local_ready"
    @test package_record["localOnly"] == true
    checksum_payload = deploy.deploy_package_checksum_payload(package_record)
    @test !haskey(checksum_payload, "packageChecksumSha256")
    @test checksum_payload["packageId"] == "deploy-helper"

    execution = GatewayExecution(
        execution_id = "exec-helper",
        workflow_id = "wf-helper",
        workflow_version = "1.0.0",
        checkpoint_tag = "chk-helper",
        status = "completed",
        mode = "batch",
        plan = String[],
        stages = Vector{String}[],
        node_count = 0,
        connection_count = 0,
        created_at = "2026-06-23T00:00:00Z",
        metadata = Dict{String,Any}("deploy_package_records" => [package_record]),
    )
    records = deploy.deploy_package_records(execution)
    @test length(records) == 1
    @test records[1]["packageId"] == "deploy-helper"
end

@testset "Data science project tuning helpers" begin
    tuning = JuliaFlowApiGateway.JuliaFlowDataScienceProjectTuning
    project = DataScienceProjectRecord(project_id = "tuning-helper", name = "Tuning Helper")
    project.split_plans = [
        Dict{String,Any}(
            "splitPlanId" => "split-helper",
            "datasetId" => "dataset-helper",
            "strategy" => "stratified",
            "validationFraction" => 0.2,
            "testFraction" => 0.2,
            "seed" => 99,
        ),
    ]
    split_plan = tuning.project_split_plan_for_request(project, Dict{String,Any}(), "dataset-helper", "tuning study")
    @test split_plan["splitPlanId"] == "split-helper"
    split_plan, validation_context = tuning.validate_tuning_split_context(
        project,
        Dict{String,Any}("finalTestPolicy" => "forbid_final_test"),
        "dataset-helper",
    )
    @test validation_context["projectId"] == "tuning-helper"
    @test validation_context["splitPlanId"] == "split-helper"
    @test validation_context["validationFraction"] == 0.2
    @test_throws ErrorException tuning.validate_tuning_split_context(
        project,
        Dict{String,Any}("finalTestPolicy" => "use_final_test"),
        "dataset-helper",
    )
    @test tuning.tuning_metric_names(Dict{String,Any}()) == ["rmse", "mae"]
    @test tuning.tuning_metric_names(Dict{String,Any}("metricNames" => ["Root Mean Square", "MAE"])) == ["root-mean-square", "mae"]
    @test_throws ErrorException tuning.tuning_metric_names(Dict{String,Any}("metricNames" => []))
    @test tuning.tuning_max_trials(Dict{String,Any}()) == 3
    @test_throws ErrorException tuning.tuning_max_trials(Dict{String,Any}("maxTrials" => 0))

    training_plan = tuning.tuning_training_plan_record(
        "training-helper",
        "target",
        "regression",
        ["rmse", "mae"],
        split_plan,
        "2026-06-23T00:00:00Z",
    )
    @test training_plan["seed"] == 99
    tuning.upsert_training_plan!(project, training_plan)
    @test length(project.training_plans) == 1
    training_plan_updated = merge(training_plan, Dict{String,Any}("taskType" => "classification"))
    tuning.upsert_training_plan!(project, training_plan_updated)
    @test length(project.training_plans) == 1
    @test project.training_plans[1]["taskType"] == "classification"

    trials = tuning.tuning_trials("tuning-helper", "study-helper", "MLJ.EvoTreesRegressor", ["rmse", "mae"], 2, "2026-06-23T00:00:00Z")
    @test length(trials) == 2
    @test trials[1]["trialId"] == "study-helper-trial-1"
    @test trials[1]["metrics"]["rmse"] == 0.5
    @test trials[2]["artifactRefs"][1]["path"] == "local://tuning/tuning-helper/study-helper/trial-2.json"
    study = tuning.tuning_study_record("study-helper", "training-helper", trials, validation_context, "2026-06-23T00:00:00Z")
    @test study["validationOnly"] == true
    @test study["bestTrialId"] == "study-helper-trial-1"
    output_refs = tuning.tuning_output_refs(trials)
    @test length(output_refs) == 2
    @test output_refs[1]["kind"] == "tuning_trial"
end

@testset "Data science project evaluation helpers" begin
    evaluation = JuliaFlowApiGateway.JuliaFlowDataScienceProjectEvaluation
    project = DataScienceProjectRecord(project_id = "evaluation-helper", name = "Evaluation Helper")
    training_plan = Dict{String,Any}(
        "trainingPlanId" => "training-helper",
        "splitPlanId" => "split-helper",
        "metricNames" => ["RMSE", "Mean Absolute"],
    )
    tuning_study = Dict{String,Any}(
        "tuningStudyId" => "tuning-helper",
        "trainingPlanId" => "training-helper",
        "validationOnly" => true,
        "validationEvidence" => Dict{String,Any}(
            "splitPlanId" => "split-helper",
            "finalTestPolicy" => "forbid_final_test",
        ),
    )
    project.training_plans = [training_plan]
    project.tuning_studies = [tuning_study]
    split_plan = Dict{String,Any}(
        "splitPlanId" => "split-helper",
        "datasetId" => "dataset-helper",
        "locked" => true,
        "testFraction" => 0.2,
    )

    @test evaluation.project_training_plan_for_request(project, Dict{String,Any}("trainingPlanId" => "training-helper")) === training_plan
    @test_throws ErrorException evaluation.project_training_plan_for_request(project, Dict{String,Any}("trainingPlanId" => "missing-training"))
    @test evaluation.project_tuning_study_for_final_evaluation(project, Dict{String,Any}("tuningStudyId" => "tuning-helper"), "training-helper") === tuning_study
    @test_throws ErrorException evaluation.project_tuning_study_for_final_evaluation(project, Dict{String,Any}("tuningStudyId" => "missing-tuning"), "training-helper")
    @test evaluation.final_evaluation_metric_names(Dict{String,Any}(), training_plan) == ["rmse", "mean-absolute"]
    @test evaluation.final_evaluation_metric_names(Dict{String,Any}("metricNames" => ["F1 Score"]), training_plan) == ["f1-score"]
    @test_throws ErrorException evaluation.final_evaluation_metric_names(Dict{String,Any}("metricNames" => []), training_plan)
    @test evaluation.final_evaluation_approval_threshold(Dict{String,Any}()) == 0.8
    @test_throws ErrorException evaluation.final_evaluation_approval_threshold(Dict{String,Any}("approvalThreshold" => 1.2))

    validation_context = evaluation.final_evaluation_validation_context(
        project,
        Dict{String,Any}("finalTestPolicy" => "use_final_test"),
        "dataset-helper",
        split_plan,
        training_plan,
        tuning_study,
    )
    @test validation_context["validationOnlyTuning"] == true
    @test validation_context["testFraction"] == 0.2
    @test_throws ErrorException evaluation.final_evaluation_validation_context(
        project,
        Dict{String,Any}("finalTestPolicy" => "forbid_final_test"),
        "dataset-helper",
        split_plan,
        training_plan,
        tuning_study,
    )

    metrics = evaluation.final_evaluation_metrics(["rmse", "mae"])
    @test metrics["rmse"] == 0.92
    @test metrics["mae"] == 0.9
    report = evaluation.final_evaluation_report_record(
        "eval-helper",
        project.project_id,
        training_plan,
        "split-helper",
        metrics,
        true,
        validation_context,
        "2026-06-23T00:00:00Z",
    )
    @test report["evaluationReportId"] == "eval-helper"
    @test report["approved"] == true
    @test report["finalTestOnly"] == true
    @test report["artifactRefs"][1]["path"] == "local://evaluation/evaluation-helper/eval-helper/report.json"
    @test evaluation.final_evaluation_output_refs(report)[1]["kind"] == "final_evaluation_report"
end

@testset "Data science project transform helpers" begin
    transforms = JuliaFlowApiGateway.JuliaFlowDataScienceProjectTransforms
    split_plan = Dict{String,Any}(
        "splitPlanId" => "split-helper",
        "validationFraction" => 0.2,
        "testFraction" => 0.2,
    )
    @test transforms.transform_apply_splits(Dict{String,Any}(), split_plan) == ["validation", "test"]
    @test transforms.transform_apply_splits(Dict{String,Any}("applySplits" => ["test", "test"]), split_plan) == ["test"]
    @test_throws ErrorException transforms.transform_apply_splits(Dict{String,Any}("applySplits" => ["train"]), split_plan)
    @test_throws ErrorException transforms.transform_apply_splits(
        Dict{String,Any}("applySplits" => ["validation"]),
        Dict{String,Any}("splitPlanId" => "split-no-validation", "validationFraction" => 0.0, "testFraction" => 0.2),
    )
    @test transforms.transform_ref_for_request(Dict{String,Any}(), "project-helper") == "local://transforms/project-helper/default-fit-apply.jl"
    @test transforms.transform_ref_for_request(Dict{String,Any}("transformRef" => "local://transforms/project-helper/custom.jl"), "project-helper") == "local://transforms/project-helper/custom.jl"
    @test_throws ErrorException transforms.transform_ref_for_request(Dict{String,Any}("transformRef" => "   "), "project-helper")

    refs = transforms.transform_fit_apply_artifact_refs("project-helper", "run-helper", ["validation", "test"], "2026-06-23T00:00:00Z")
    @test length(refs) == 3
    @test refs[1]["kind"] == "transform_fit_state"
    @test refs[2]["path"] == "local://transforms/project-helper/run-helper/validation.arrow"
    record = transforms.transform_fit_apply_record(
        "run-helper",
        "dataset-helper",
        split_plan,
        ["validation", "test"],
        "local://transforms/project-helper/custom.jl",
        refs,
        "2026-06-23T00:00:00Z",
    )
    @test record["transformRunId"] == "run-helper"
    @test record["fitSplit"] == "train"
    @test record["applySplits"] == ["validation", "test"]
    @test length(record["leakageChecks"]) == 2
    @test record["artifactRefs"][3]["kind"] == "transform_apply_output"
end

@testset "Data science project experiment helpers" begin
    experiments = JuliaFlowApiGateway.JuliaFlowDataScienceProjectExperiments
    project = DataScienceProjectRecord(project_id = "experiment-helper", name = "Experiment Helper")
    project.datasets = [Dict{String,Any}("datasetId" => "dataset-helper")]
    project.split_plans = [
        Dict{String,Any}(
            "splitPlanId" => "split-helper",
            "datasetId" => "dataset-helper",
            "strategy" => "stratified",
            "validationFraction" => 0.2,
            "testFraction" => 0.2,
        ),
    ]
    projects = Dict{String,DataScienceProjectRecord}(project.project_id => project)
    @test experiments.project_has_dataset(project, "dataset-helper")
    @test !experiments.project_has_dataset(project, "missing-dataset")
    @test experiments.ml_project_for_dataset(projects, Dict{String,Any}("projectId" => "experiment-helper"), "dataset-helper") === project
    @test experiments.ml_project_for_dataset(projects, Dict{String,Any}(), "dataset-helper") === project
    @test experiments.ml_project_for_dataset(projects, Dict{String,Any}(), "missing-dataset") === nothing
    @test_throws ErrorException experiments.ml_project_for_dataset(projects, Dict{String,Any}("projectId" => "missing-project"), "dataset-helper")

    second_project = DataScienceProjectRecord(project_id = "experiment-helper-2", name = "Experiment Helper 2")
    second_project.datasets = [Dict{String,Any}("datasetId" => "dataset-helper")]
    ambiguous_projects = Dict{String,DataScienceProjectRecord}(
        project.project_id => project,
        second_project.project_id => second_project,
    )
    @test_throws ErrorException experiments.ml_project_for_dataset(ambiguous_projects, Dict{String,Any}(), "dataset-helper")

    split_plan = experiments.ml_split_plan_for_request(project, Dict{String,Any}("splitPlanId" => "split-helper"), "dataset-helper")
    @test split_plan["splitPlanId"] == "split-helper"
    @test_throws ErrorException experiments.ml_split_plan_for_request(project, Dict{String,Any}("splitPlanId" => "missing-split"), "dataset-helper")

    validation_context = experiments.validate_ml_experiment_project_context(
        projects,
        Dict{String,Any}("projectId" => "experiment-helper", "splitPlanId" => "split-helper", "finalTestPolicy" => "forbid_final_test"),
        "dataset-helper",
    )
    @test validation_context["projectId"] == "experiment-helper"
    @test validation_context["splitPlanId"] == "split-helper"
    @test validation_context["validationFraction"] == 0.2
    @test_throws ErrorException experiments.validate_ml_experiment_project_context(
        projects,
        Dict{String,Any}("projectId" => "experiment-helper", "splitPlanId" => "split-helper", "finalTestPolicy" => "use_final_test"),
        "dataset-helper",
    )
    project_missing_validation = DataScienceProjectRecord(project_id = "experiment-helper-missing-validation", name = "Missing Validation")
    project_missing_validation.datasets = [Dict{String,Any}("datasetId" => "dataset-helper")]
    project_missing_validation.split_plans = [Dict{String,Any}("splitPlanId" => "split-missing-validation", "datasetId" => "dataset-helper", "validationFraction" => 0.0, "testFraction" => 0.2)]
    @test_throws ErrorException experiments.validate_ml_experiment_project_context(
        Dict{String,DataScienceProjectRecord}(project_missing_validation.project_id => project_missing_validation),
        Dict{String,Any}("projectId" => project_missing_validation.project_id),
        "dataset-helper",
    )
end

@testset "Data science project statistical helpers" begin
    stats = JuliaFlowApiGateway.JuliaFlowDataScienceProjectStatistics
    methods = stats.statistical_analysis_methods(
        Dict{String,Any}("methods" => ["summary", "pearson correlation", "spearman_correlation", "ols", "anova", "t_test", "chi_square"]),
    )
    @test methods == ["summary", "pearson_correlation", "spearman_correlation", "ols", "anova", "t_test", "chi_square"]
    @test_throws ErrorException stats.statistical_analysis_methods(Dict{String,Any}("methods" => ["remote_eval"]))

    csv_path = joinpath(mktempdir(), "stats.csv")
    write(
        csv_path,
        join(
            [
                "amount,margin,region,segment",
                "10,1,East,A",
                "20,2,East,B",
                "30,3,West,A",
                "40,4,West,B",
            ],
            "\n",
        ),
    )
    dataset = Dict{String,Any}("datasetId" => "stats-sample", "sourceUri" => "local://data/stats.csv")
    evidence = stats.local_csv_statistical_evidence_from_path(
        dataset,
        csv_path,
        Dict{String,Any}(
            "targetColumn" => "amount",
            "featureColumns" => ["margin", "region", "segment"],
        ),
        methods,
    )
    @test evidence["executionMode"] == "local_csv"
    @test evidence["rowCount"] == 4
    @test evidence["numericColumns"] == ["amount", "margin"]
    amount_summary = only(filter(summary -> summary["column"] == "amount", evidence["summaries"]))
    @test amount_summary["mean"] == 25.0
    @test evidence["inferentialTests"]["ols"]["featureColumn"] == "margin"
    @test evidence["inferentialTests"]["ols"]["rSquared"] == 1.0
    @test evidence["inferentialTests"]["anova"]["dfBetween"] == 1
    @test evidence["inferentialTests"]["tTest"]["groups"] == ["East", "West"]
    @test evidence["inferentialTests"]["chiSquare"]["degreesOfFreedom"] == 1
    @test evidence["inferentialTests"]["spearmanCorrelation"]["columns"] == ["amount", "margin"]

    code = stats.statistical_analysis_code_artifact(
        "stats-sample",
        methods,
        Dict{String,Any}("targetColumn" => "amount", "featureColumns" => ["margin", "region"]),
    )
    @test occursin("# dataset: stats-sample", code)
    @test occursin("# targetColumn: amount", code)
    @test occursin("# featureColumns: margin, region", code)
end

@testset "Data science project registry helpers" begin
    helper_project = DataScienceProjectRecord(
        project_id = "project-registry-helper",
        name = "Registry Helper Project",
    )
    helper_projects = Dict(helper_project.project_id => helper_project)
    validation_context = Dict{String,Any}(
        "projectId" => helper_project.project_id,
        "evaluationReportId" => "eval-helper",
    )
    @test JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.project_for_validation_context(
        helper_projects,
        validation_context,
        "model registry",
    ) === helper_project
    @test JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.project_for_validation_context(
        helper_projects,
        Dict{String,Any}(),
        "model registry",
    ) === nothing
    @test_throws ErrorException JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.project_for_validation_context(
        helper_projects,
        Dict{String,Any}("projectId" => "missing-project"),
        "model registry",
    )

    first_record = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.upsert_model_registry_record!(
        helper_project,
        Dict{String,Any}(
            "modelId" => "model-helper",
            "status" => "registered",
            "updatedAt" => "2026-06-22T00:00:00Z",
        ),
    )
    @test first_record["status"] == "registered"
    @test length(helper_project.model_registry_records) == 1
    second_record = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.upsert_model_registry_record!(
        helper_project,
        Dict{String,Any}(
            "modelId" => "model-helper",
            "status" => "approved",
            "updatedAt" => "2026-06-22T00:01:00Z",
        ),
    )
    @test second_record["status"] == "approved"
    @test length(helper_project.model_registry_records) == 1
    @test helper_project.model_registry_records[1]["status"] == "approved"
    other_project = DataScienceProjectRecord(
        project_id = "project-registry-other",
        name = "Registry Other Project",
    )
    other_project.model_registry_records = [
        Dict{String,Any}("modelId" => "model-other", "workflowId" => "workflow-other", "updatedAt" => "2026-06-22T00:01:30Z"),
    ]
    helper_project.model_registry_records = [
        Dict{String,Any}("modelId" => "model-helper", "workflowId" => "workflow-helper", "status" => "approved"),
        Dict{String,Any}("modelId" => "model-sibling", "workflowId" => "workflow-helper", "status" => "registered"),
        Dict{String,Any}("modelId" => "model-other-workflow", "workflowId" => "workflow-other", "status" => "registered"),
    ]
    workflow_records = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.project_model_registry_records_for_workflow(
        Dict(helper_project.project_id => helper_project, other_project.project_id => other_project),
        "workflow-helper",
    )
    @test [record["modelId"] for record in workflow_records] == ["model-helper", "model-sibling"]
    deduped_records = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.dedupe_model_registry_records([
        Dict{String,Any}("modelId" => "model-helper", "status" => "project"),
        Dict{String,Any}("modelId" => "model-helper", "status" => "execution"),
        Dict{String,Any}("status" => "missing-model"),
        Dict{Symbol,Any}(:modelId => "model-sibling", :status => "execution"),
    ])
    @test length(deduped_records) == 2
    @test deduped_records[1]["status"] == "project"
    @test deduped_records[2]["modelId"] == "model-sibling"

    lifecycle_record = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.upsert_model_lifecycle_record!(
        helper_project,
        validation_context,
        "model-helper",
        "validated";
        updated_at = "2026-06-22T00:02:00Z",
    )
    @test lifecycle_record["evaluationReportId"] == "eval-helper"
    deployed_record = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.upsert_model_lifecycle_record!(
        helper_project,
        validation_context,
        "model-helper",
        "deployed";
        deployed_endpoint_id = "deploy-helper",
        updated_at = "2026-06-22T00:03:00Z",
    )
    @test deployed_record["deployedEndpointId"] == "deploy-helper"
    helper_project.model_lifecycle_records[1]["rollbackModelId"] = "model-helper-v0"
    rolled_back_record = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.upsert_model_lifecycle_record!(
        helper_project,
        validation_context,
        "model-helper",
        "rolled_back";
        updated_at = "2026-06-22T00:04:00Z",
    )
    @test rolled_back_record["deployedEndpointId"] == "deploy-helper"
    @test rolled_back_record["rollbackModelId"] == "model-helper-v0"
    @test length(helper_project.model_lifecycle_records) == 1
    synced_registry_record = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.update_model_registry_lifecycle_status!(
        helper_project,
        "model-helper",
        "approved",
        "2026-06-22T00:05:00Z";
        validation_evidence = Dict{String,Any}("lifecycleAction" => "approve_model"),
    )
    @test synced_registry_record["status"] == "approved"
    @test synced_registry_record["validationEvidence"]["lifecycleAction"] == "approve_model"
    @test_throws ErrorException JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.update_model_registry_lifecycle_status!(
        helper_project,
        "missing-model",
        "approved",
        "2026-06-22T00:05:00Z",
    )
    @test JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_state("approve_model") == "approved"
    @test JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_state("deprecate_model") == "deprecated"
    @test JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_state("archive_model") == "archived"
    @test JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_state("mark_rollback_ready") == "rollback_ready"
    @test JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_state("mark_rolled_back") == "rolled_back"
    @test JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_state("request_retraining") == "retraining_requested"
    @test_throws ErrorException JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_state("delete_model")

    action_project = DataScienceProjectRecord(
        project_id = "project-lifecycle-action-helper",
        name = "Lifecycle Action Helper",
    )
    action_project.model_lifecycle_records = [
        Dict{String,Any}(
            "modelId" => "model-action",
            "state" => "deployed",
            "deployedEndpointId" => "deploy-action",
            "evaluationReportId" => "eval-action",
        ),
    ]
    action_project.drift_reports = [Dict{String,Any}("driftReportId" => "drift-action")]
    approval_project = DataScienceProjectRecord(
        project_id = "project-lifecycle-approval-helper",
        name = "Lifecycle Approval Helper",
    )
    approval_project.model_lifecycle_records = [
        Dict{String,Any}(
            "modelId" => "model-approval",
            "state" => "validated",
            "evaluationReportId" => "eval-approval",
        ),
    ]
    approval_record, approval_index = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_record(
        approval_project,
        Dict{String,Any}(
            "modelId" => "model-approval",
            "action" => "approve_model",
            "reason" => "approved by validation board",
        ),
        "2026-06-25T00:00:00Z",
    )
    @test approval_index == 1
    @test approval_record["state"] == "approved"
    @test approval_record["validationEvidence"]["previousState"] == "validated"
    @test approval_record["evaluationReportId"] == "eval-approval"
    approval_project.model_lifecycle_records[1] = approval_record
    deprecated_record, deprecated_index = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_record(
        approval_project,
        Dict{String,Any}(
            "modelId" => "model-approval",
            "action" => "deprecate_model",
            "reason" => "superseded",
        ),
        "2026-06-25T00:01:00Z",
    )
    @test deprecated_index == 1
    @test deprecated_record["state"] == "deprecated"
    @test deprecated_record["deprecationReason"] == "superseded"
    approval_project.model_lifecycle_records[1] = deprecated_record
    archived_record, archived_index = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_record(
        approval_project,
        Dict{String,Any}(
            "modelId" => "model-approval",
            "action" => "archive_model",
            "reason" => "retention period elapsed",
        ),
        "2026-06-25T00:02:00Z",
    )
    @test archived_index == 1
    @test archived_record["state"] == "archived"
    @test archived_record["archiveReason"] == "retention period elapsed"
    @test_throws ErrorException JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_record(
        action_project,
        Dict{String,Any}(
            "modelId" => "model-action",
            "action" => "archive_model",
        ),
        "2026-06-25T00:00:00Z",
    )
    rollback_ready_record, rollback_ready_index = JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_record(
        action_project,
        Dict{String,Any}(
            "modelId" => "model-action",
            "action" => "mark_rollback_ready",
            "rollbackModelId" => "model-action-v0",
            "driftReportId" => "drift-action",
            "reason" => "validation drift",
        ),
        "2026-06-25T00:00:00Z",
    )
    @test rollback_ready_index == 1
    @test rollback_ready_record["state"] == "rollback_ready"
    @test rollback_ready_record["rollbackModelId"] == "model-action-v0"
    @test rollback_ready_record["rollbackReason"] == "validation drift"
    @test rollback_ready_record["evaluationReportId"] == "eval-action"
    @test rollback_ready_record["validationEvidence"]["driftReportId"] == "drift-action"
    @test rollback_ready_record["validationEvidence"]["previousState"] == "deployed"
    @test_throws ErrorException JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_record(
        action_project,
        Dict{String,Any}(
            "modelId" => "model-action",
            "action" => "mark_rollback_ready",
            "rollbackModelId" => "model-action",
        ),
        "2026-06-25T00:00:00Z",
    )
    @test_throws ErrorException JuliaFlowApiGateway.JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_record(
        action_project,
        Dict{String,Any}(
            "modelId" => "model-action",
            "action" => "request_retraining",
            "driftReportId" => "missing-drift",
        ),
        "2026-06-25T00:00:00Z",
    )
end

@testset "Data science project job helpers" begin
    helper_project = DataScienceProjectRecord(
        project_id = "project-job-helper",
        name = "Job Helper Project",
        schema_version = "1.0",
    )
    compute_settings = Dict{String,Any}(
        "selectedBackend" => "cuda",
        "schedulerPolicy" => "bounded_local",
        "cpuWorkerConcurrency" => 2,
        "cpuMemoryLimitBytes" => 4096,
    )
    empty_gpu_registry = Dict{String,Any}(
        "device_count" => 0,
        "devices" => Any[],
    )
    resource_evidence = JuliaFlowApiGateway.JuliaFlowDataScienceProjectJobs.project_job_resource_evidence(
        compute_settings,
        empty_gpu_registry;
        execution_mode = "unit_test_job",
        cpu_thread_count = 4,
    )
    @test resource_evidence["executionMode"] == "unit_test_job"
    @test resource_evidence["requestedBackend"] == "cuda"
    @test resource_evidence["selectedBackend"] == "cpu"
    @test resource_evidence["dispatchLane"] == "cpu"
    @test resource_evidence["workerPool"] == "local-cpu"
    @test resource_evidence["gpuFallbackReason"] == "no_cuda_device_available"
    @test resource_evidence["cpuThreadCount"] == 4

    artifact_refs = [
        Dict{String,Any}(
            "refId" => "artifact-job-helper",
            "kind" => "unit_test_artifact",
            "localOnly" => true,
        ),
    ]
    execution_evidence = Dict{String,Any}(
        "executionId" => "dsjob-helper",
        "status" => "completed",
    )
    job = JuliaFlowApiGateway.JuliaFlowDataScienceProjectJobs.record_project_job!(
        helper_project,
        "unit_test_job";
        dataset_id = "dataset-helper",
        split_plan_id = "split-helper",
        source_record_id = "source-helper",
        output_refs = artifact_refs,
        resource_evidence = resource_evidence,
        execution_evidence = execution_evidence,
        started_at = "2026-06-22T00:10:00Z",
        finished_at = "2026-06-22T00:11:00Z",
    )
    @test length(helper_project.project_jobs) == 1
    @test helper_project.project_jobs[1]["jobId"] == job["jobId"]
    @test job["datasetId"] == "dataset-helper"
    @test job["splitPlanId"] == "split-helper"
    @test job["sourceRecordId"] == "source-helper"
    @test job["outputRefs"][1]["kind"] == "unit_test_artifact"
    @test job["resourceEvidence"]["selectedBackend"] == "cpu"
    @test job["executionEvidence"]["executionId"] == "dsjob-helper"

    execution, worker_id = JuliaFlowApiGateway.JuliaFlowDataScienceProjectJobs.project_job_execution_record(
        helper_project,
        "unit_test_job";
        workflow_id = "wf-helper",
        checkpoint_tag = "cp-helper",
        dataset_id = "dataset-helper",
        source_record_id = "source-helper",
        output_refs = artifact_refs,
        resource_evidence = resource_evidence,
        started_at = "2026-06-22T00:12:00Z",
        finished_at = "2026-06-22T00:13:00Z",
        plan = ["validate_helper", "materialize_helper"],
    )
    @test startswith(execution.execution_id, "dsjob-")
    @test execution.workflow_id == "wf-helper"
    @test execution.checkpoint_tag == "cp-helper"
    @test execution.mode == "local_project_job"
    @test execution.plan == ["validate_helper", "materialize_helper"]
    @test execution.metadata["data_science_project_job"]["project_id"] == helper_project.project_id
    @test execution.metadata["data_science_project_job"]["job_type"] == "unit_test_job"
    @test execution.metadata["data_science_project_job"]["dataset_id"] == "dataset-helper"
    @test execution.metadata["data_science_project_job"]["source_record_id"] == "source-helper"
    @test execution.metadata["artifact_refs"][1]["refId"] == "artifact-job-helper"
    @test execution.metadata["resource_evidence"]["executionMode"] == "unit_test_job"
    @test execution.metadata["worker_id"] == worker_id
    @test execution.metadata["worker_dispatch"]["orchestrationMode"] == "gateway_worker_dispatch"
    @test execution.metadata["worker_dispatch"]["dispatchStatus"] == "completed"
    @test execution.metadata["worker_dispatch"]["workerPool"] == "local-cpu"
    @test execution.metadata["worker_dispatch"]["dispatchLane"] == "cpu"
    compact_evidence = JuliaFlowApiGateway.JuliaFlowDataScienceProjectJobs.project_job_execution_evidence(execution, worker_id)
    @test compact_evidence["executionId"] == execution.execution_id
    @test compact_evidence["workflowId"] == "wf-helper"
    @test compact_evidence["workerId"] == worker_id
    @test compact_evidence["orchestrationMode"] == "gateway_worker_dispatch"
    @test compact_evidence["dispatchStatus"] == "completed"
    @test compact_evidence["workerPool"] == "local-cpu"
    @test compact_evidence["dispatchLane"] == "cpu"
    @test compact_evidence["startedAt"] == "2026-06-22T00:12:00Z"
    @test compact_evidence["finishedAt"] == "2026-06-22T00:13:00Z"

    worker_execution, worker_backed_id = JuliaFlowApiGateway.JuliaFlowDataScienceProjectJobs.project_job_execution_record(
        helper_project,
        "unit_test_worker_job";
        workflow_id = "wf-helper",
        checkpoint_tag = "cp-helper",
        source_record_id = "source-helper",
        resource_evidence = resource_evidence,
        started_at = "2026-06-22T00:14:00Z",
        plan = ["validate_worker_helper", "materialize_worker_helper"],
        worker_backed = true,
    )
    @test worker_execution.status == "accepted"
    @test worker_execution.metadata["worker_dispatch"]["orchestrationMode"] == "worker_service_tick"
    @test worker_execution.metadata["worker_dispatch"]["dispatchStatus"] == "accepted"
    worker_service = JuliaFlowApiGateway.JuliaFlowWorkerService.WorkerServiceState()
    worker_executions = Any[worker_execution]
    first_worker_tick = JuliaFlowApiGateway.JuliaFlowWorkerService.process_data_science_project_job_tick!(
        worker_service,
        worker_executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = JuliaFlowApiGateway.JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test first_worker_tick[1].status == "queued"
    second_worker_tick = JuliaFlowApiGateway.JuliaFlowWorkerService.process_data_science_project_job_tick!(
        worker_service,
        worker_executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = JuliaFlowApiGateway.JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test second_worker_tick[1].status == "running"
    third_worker_tick = JuliaFlowApiGateway.JuliaFlowWorkerService.process_data_science_project_job_tick!(
        worker_service,
        worker_executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = JuliaFlowApiGateway.JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test third_worker_tick[1].status == "completed"
    @test third_worker_tick[1].metadata["worker_dispatch"]["dispatchStatus"] == "completed"
    @test third_worker_tick[1].metadata["data_science_project_worker_state"]["job_type"] == "unit_test_worker_job"
    worker_backed_evidence = JuliaFlowApiGateway.JuliaFlowDataScienceProjectJobs.project_job_execution_evidence(third_worker_tick[1], worker_backed_id)
    @test worker_backed_evidence["status"] == "completed"
    @test worker_backed_evidence["orchestrationMode"] == "worker_service_tick"
    @test worker_backed_evidence["dispatchStatus"] == "completed"
end

mutable struct FakeRealtimeSocket
    messages::Vector{String}
end

HTTP.WebSockets.send(socket::FakeRealtimeSocket, message) = push!(socket.messages, String(message))

function test_base64url(bytes::Vector{UInt8})
    encoded = base64encode(bytes)
    encoded = replace(replace(encoded, '+' => '-'), '/' => '_')
    return replace(encoded, "=" => "")
end

function test_base64url_json(payload)
    return test_base64url(Vector{UInt8}(codeunits(JSON3.write(payload))))
end

function test_hs256_jwt(claims::Dict{String,Any}; secret::AbstractString = "oidc-secret", kid::Union{Nothing,AbstractString} = nothing)
    header = Dict{String,Any}("alg" => "HS256", "typ" => "JWT")
    kid === nothing || (header["kid"] = String(kid))
    signing_input = string(test_base64url_json(header), ".", test_base64url_json(claims))
    signature = test_base64url(hmac_sha256(Vector{UInt8}(codeunits(secret)), signing_input))
    return string(signing_input, ".", signature)
end

function test_oct_jwk(kid::AbstractString, secret::AbstractString)
    return Dict("kty" => "oct", "kid" => String(kid), "alg" => "HS256", "k" => test_base64url(Vector{UInt8}(codeunits(secret))))
end

function runtime_branch_workflow_text()
    return """
    version = "0.1.0"

    [workflow]
    id = "wf-catch-branch-dag"
    name = "Catch Branch DAG"

    [[workflow.bi_outlets]]
    node_id = "catch-bi"
    name = "Catch BI Outlet"
    rows = [
      { status = "recovered", count = 2 },
      { status = "audited", count = 1 }
    ]

    [[workflow.control_flow]]
    id = "try-catch-dag"
    kind = "try_catch"
    name = "Catch DAG Guard"
    try_node_ids = ["node-transform"]
    catch_node_ids = ["catch-log", "catch-clean", "catch-bi"]

    [runtime]
    run_mode = "batch"

    [[nodes]]
    id = "node-source"
    name = "Source"
    type = "JuliaFlow.Base.CSVReader"
    execution_hint = "cpu_only"
    ports = [{ id = "out", direction = "output", type = "data_table" }]
    config = { path = "assets/sample.csv" }

    [[nodes]]
    id = "node-transform"
    name = "Transform"
    type = "JuliaFlow.Base.ColumnSelect"
    execution_hint = "cpu_only"
    ports = [
      { id = "in", direction = "input", type = "data_table" },
      { id = "out", direction = "output", type = "data_table" }
    ]
    config = { columns = ["amount"] }

    [[nodes]]
    id = "catch-log"
    name = "Catch Log"
    type = "JuliaFlow.Base.AuditLog"
    execution_hint = "cpu_only"
    ports = []
    config = { event = "recover" }

    [[nodes]]
    id = "catch-clean"
    name = "Catch Clean"
    type = "JuliaFlow.Base.CleanRows"
    execution_hint = "cpu_only"
    ports = [{ id = "out", direction = "output", type = "data_table" }]
    config = { strategy = "safe" }

    [[nodes]]
    id = "catch-bi"
    name = "Catch BI"
    type = "JuliaFlow.BI.DataOutlet"
    execution_hint = "cpu_only"
    ports = [{ id = "in", direction = "input", type = "data_table" }]
    config = { outlet = "catch-bi" }

    [[connections]]
    source_node_id = "node-source"
    source_port_id = "out"
    target_node_id = "node-transform"
    target_port_id = "in"
    data_type = "data_table"

    [[connections]]
    source_node_id = "catch-clean"
    source_port_id = "out"
    target_node_id = "catch-bi"
    target_port_id = "in"
    data_type = "data_table"
    """
end

@testset "Node SDK" begin
    payload = (format = :arrow_ipc, ref = "minio://wf/output.arrow")
    @test validate_arrow_boundary(payload)
    @test validate_port_type(:data_table)
    @test validate_port_direction(:output)
    @test normalize_config(Dict("a" => 1)).values["a"] == 1
end

@testset "Execution Service" begin
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    parallel_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "parallel.workflow.toml")
    invalid_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "invalid.workflow.toml")

    workflow_text = read(foundation_path, String)
    gpu_workflow_text = """
    version = "0.3.0"

    [workflow]
    id = "wf-gpu-alpha"
    name = "GPU Alpha"

    [runtime]
    run_mode = "batch"

    [[flow_variables]]
    name = "JULIAFLOW_GPU_DEVICE"
    type = "GPUDeviceID"
    default = "nvidia0"

    [[nodes]]
    id = "node-source"
    type = "JuliaFlow.Base.CSVReader"
    name = "CSV Reader"
    execution_hint = "cpu_only"
    ports = [{ id = "out", direction = "output", type = "data_table" }]
    config = { path = "assets/sample.csv" }

    [[nodes]]
    id = "node-train"
    type = "JuliaFlow.Base.ModelTrain"
    name = "GPU Trainer"
    execution_hint = "gpu_required"
    ports = [
        { id = "in", direction = "input", type = "data_table" },
        { id = "model", direction = "output", type = "model" },
    ]
    config = { target = "amount", gpuDevicePreference = "nvidia0", gpuWorkload = "mock_vector_sum", mockInputValues = [1.0, 2.0, 3.0, 4.0] }
    capabilities = { execution_mode = "batch", resource_class = "gpu", accelerator = "cuda", worker_pool = "alpha-gpu" }

    [[connections]]
    source_node_id = "node-source"
    source_port_id = "out"
    target_node_id = "node-train"
    target_port_id = "in"
    data_type = "data_table"
    """
    workflow = load_workflow_definition(foundation_path)
    parallel_workflow = load_workflow_definition(parallel_path)
    gpu_workflow = load_workflow_definition_text(gpu_workflow_text)
    invalid_control_workflow = load_workflow_definition_text(replace(
        workflow_text,
        "max_concurrency = 4" => "max_concurrency = 0";
        count = 1,
    ))
    invalid_loop_workflow = load_workflow_definition_text(replace(
        workflow_text,
        "end_node_id = \"node-bi\"" => "end_node_id = \"node-source\"";
        count = 1,
    ))
    invalid_try_catch_workflow = load_workflow_definition_text(replace(
        workflow_text,
        "catch_node_ids = [\"node-bi\"]" => "catch_node_ids = [\"node-missing\"]";
        count = 1,
    ))
    invalid_workflow = load_workflow_definition(invalid_path)
    workflow_from_text = load_workflow_definition_text(workflow_text)
    plan = build_execution_plan(workflow)
    stages = build_parallel_stages(parallel_workflow)
    errors = collect_validation_errors(invalid_workflow)

    @test validate_workflow(workflow)
    @test workflow_from_text.id == workflow.id
    @test plan == ["node-source", "node-transform", "node-bi"]
    @test stages == [["node-source"], ["node-left", "node-right"], ["node-sink"]]
    @test any(occursin("target port in on node-target must be input", error) for error in errors)

    result = execute_workflow(workflow)
    execute_with_flow_variables = execute_workflow(
        workflow;
        flow_variable_values = Dict("JULIAFLOW_GPU_DEVICE" => "nvidia:0"),
        execution_mode_override = "gpu_preferred",
    )
    spec = serialize_job_spec(parallel_workflow; checkpoint_tag = "cp/01-contracts-frozen")
    @test result["status"] == "accepted"
    @test result["mode"] == "batch_cpu"
    @test haskey(result, "observability_trace")
    @test length(result["observability_trace"]["trace_id"]) == 32
    @test result["observability_trace"]["spans"][1]["name"] == "execution.dispatch_plan"
    @test result["observability_trace"]["spans"][1]["attributes"]["workflow.id"] == "wf-foundation"
    @test execute_with_flow_variables["flow_variables"]["JULIAFLOW_GPU_DEVICE"] == "nvidia:0"
    @test execute_with_flow_variables["requested_execution_mode"] == "gpu_preferred"
    @test execute_with_flow_variables["status_history"][1]["at"] isa AbstractString
    @test workflow.graph.revision == 2
    @test workflow.containers[1].id == "container-prep"
    @test workflow.containers[1].node_ids == ["node-source", "node-transform"]
    @test workflow.components[1].flow_variable_scope == "isolated"
    @test workflow.components[1].dashboard_ids == ["dashboard-foundation"]
    @test workflow.control_flow[1].kind == :switch
    @test workflow.control_flow[1].cases[1]["target_node_id"] == "node-transform"
    @test workflow.control_flow[2].max_concurrency == 4
    @test workflow.control_flow[3].kind == :loop
    @test workflow.control_flow[3].max_iterations == 3
    @test workflow.control_flow[4].kind == :try_catch
    @test workflow.control_flow[4].catch_node_ids == ["node-bi"]
    @test result["control_flow_plan"][1]["control_id"] == "loop-bi-refresh"
    @test result["control_flow_plan"][1]["body_node_ids"] == ["node-transform", "node-bi"]
    @test result["control_flow_plan"][1]["bounded"] == true
    @test result["control_flow_plan"][2]["control_id"] == "try-bi-outlet"
    @test result["control_flow_plan"][2]["try_node_ids"] == ["node-transform"]
    @test result["control_flow_plan"][2]["catch_node_ids"] == ["node-bi"]
    recovery = try_catch_recovery_metadata(workflow, "node-transform")
    @test recovery["control_id"] == "try-bi-outlet"
    @test recovery["failed_node_id"] == "node-transform"
    @test recovery["catch_node_ids"] == ["node-bi"]
    @test recovery["status"] == "recovered"
    @test try_catch_recovery_metadata(workflow, "node-source") === nothing
    @test occursin("parallel chunk parallel-prep max concurrency", join(collect_validation_errors(invalid_control_workflow), "; "))
    @test occursin("loop loop-bi-refresh end node unreachable from start node", join(collect_validation_errors(invalid_loop_workflow), "; "))
    @test occursin("try/catch try-bi-outlet catch references missing node: node-missing", join(collect_validation_errors(invalid_try_catch_workflow), "; "))
    @test length(workflow.dashboards) == 1
    @test parallel_workflow.runtime.run_mode == :stream
    @test spec["resource_plan"][1]["lane"] == "cpu"
    @test spec["dispatch_plan"][1]["worker_pool"] == "alpha-cpu"
    @test spec["executor_schedule"][1]["node_ids"] == ["node-source"]
    @test spec["executor_schedule"][2]["node_ids"] == ["node-left", "node-right"]
    @test spec["executor_schedule"][2]["max_concurrency"] == 2
    @test spec["executor_schedule"][3]["ready_after_stage"] == 2
    @test spec["executor_schedule"][3]["scheduler_policy"] == "topological_stage_barrier"
    @test spec["executor_schedule"][1]["dataflow_policy"]["policy_name"] == "callback_dataflow_stage_barrier"
    @test spec["executor_schedule"][1]["dataflow_policy"]["callback_enabled"] == true
    @test spec["executor_schedule"][1]["dataflow_policy"]["source_node_ids"] == ["node-source"]
    @test spec["observability_trace"]["spans"][1]["attributes"]["dispatch.lane_count"] == length(spec["dispatch_plan"])
    @test spec["stream_lifecycle_status"] == "starting"
    appended = append_execution_event(spec; message = "heartbeat", metadata = Dict("stream_lifecycle_status" => "active"))
    @test appended["stream_lifecycle_status"] == "active"
    @test appended["status_history"][end]["message"] == "heartbeat"
    @test is_stream_workflow(parallel_workflow)
    @test spec["stages"][2] == ["node-left", "node-right"]
    @test spec["checkpoint_tag"] == "cp/01-contracts-frozen"
    gpu_spec = serialize_job_spec(gpu_workflow; checkpoint_tag = "cp/03-alpha-gpu-bi")
    @test gpu_spec["mode"] == "batch_gpu_required"
    @test gpu_spec["resource_plan"][2]["lane"] == "gpu"
    @test gpu_spec["dispatch_plan"][2]["worker_pool"] == "alpha-gpu"
    @test gpu_spec["dispatch_plan"][2]["isolation_mode"] == "isolated"
    @test gpu_spec["dispatch_plan"][2]["accelerator"] == "cuda"
    @test gpu_spec["dispatch_plan"][2]["scheduler_policy"] == "deterministic_device_id"
    @test gpu_spec["dispatch_plan"][2]["placement_reason"] == "gpu_lane_isolated_worker"
    @test gpu_spec["dispatch_plan"][2]["requested_device"] == "nvidia0"
    @test gpu_spec["dispatch_plan"][2]["worker_capacity"]["device_slots"] == 1
    gpu_override = execute_workflow(
        gpu_workflow;
        flow_variable_values = Dict("JULIAFLOW_GPU_DEVICE" => "nvidia:1"),
    )
    @test gpu_override["dispatch_plan"][2]["requested_device"] == "nvidia:1"
    @test_throws ErrorException validate_workflow(invalid_workflow)
    @test_throws ErrorException execute_workflow(workflow; flow_variable_values = Dict("MISSING_VAR" => "oops"))
end

@testset "Gateway Repository" begin
    mktempdir() do store_root
        file_repo = JuliaFlowApiGateway.JuliaFlowGatewayRepository.ensure_repository!(
            JuliaFlowApiGateway.JuliaFlowGatewayRepository.FileGatewayRepository(store_root),
        )
        run_gateway_repository_contract!(file_repo; label = "File")
    end

    @testset "PostgreSQL integration scaffold" begin
        with_postgres_repository() do postgres_repo
            run_gateway_repository_contract!(postgres_repo; label = "PostgreSQL")
            reader_repo = JuliaFlowApiGateway.JuliaFlowGatewayRepository.PostgreSQLGatewayRepository(
                postgres_repo.connection_string;
                schema = postgres_repo.schema,
            )
            workflows = JuliaFlowApiGateway.JuliaFlowGatewayRepository.load_workflows(reader_repo)
            @test haskey(workflows, "wf-foundation")
            @test workflows["wf-foundation"].name == "Foundation PoC Contract Test"
            @test JuliaFlowApiGateway.JuliaFlowGatewayRepository.load_consumer_cursor(reader_repo, "gateway-test") > 0
        end
    end
end

@testset "Worker Service" begin
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    parallel_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "parallel.workflow.toml")
    foundation_workflow = load_workflow_definition(foundation_path)
    kafka_workflow = load_workflow_definition(parallel_path)
    kafka_metadata = JuliaFlowWorkerService.build_stream_execution_metadata(kafka_workflow)
    @test kafka_metadata["stream_adapter_contract"]["kind"] == "kafka"
    @test kafka_metadata["stream_adapter_contract"]["topic"] == "parallel.events"
    @test kafka_metadata["stream_adapter_contract"]["consumerGroup"] == "juliaflow-dev"
    @test kafka_metadata["stream_adapter_contract"]["replayMode"] == "committed_offset"
    nats_workflow = load_workflow_definition(parallel_path)
    empty!(nats_workflow.runtime.source)
    nats_workflow.runtime.source["kind"] = "nats"
    nats_workflow.runtime.source["subject"] = "parallel.events"
    nats_workflow.runtime.source["durable_consumer"] = "juliaflow-dev"
    nats_workflow.runtime.source["servers"] = ["nats://localhost:4222"]
    nats_metadata = JuliaFlowWorkerService.build_stream_execution_metadata(nats_workflow)
    @test nats_metadata["stream_adapter_contract"]["kind"] == "nats"
    @test nats_metadata["stream_adapter_contract"]["subject"] == "parallel.events"
    @test nats_metadata["stream_adapter_contract"]["durableConsumer"] == "juliaflow-dev"
    parallel_workflow = load_workflow_definition(parallel_path)
    parallel_workflow.runtime.source["kind"] = "fixture"
    parallel_workflow.runtime.source["events"] = [
        Dict("offset" => 1, "event_time_seconds" => 0, "region" => "north", "amount" => 10.0),
        Dict("offset" => 2, "event_time_seconds" => 12, "region" => "south", "amount" => 20.0),
        Dict("offset" => 3, "event_time_seconds" => 41, "region" => "north", "amount" => 30.0),
    ]
    gpu_workflow_text = """
    version = "0.3.0"

    [workflow]
    id = "wf-gpu-alpha"
    name = "GPU Alpha"

    [runtime]
    run_mode = "batch"

    [[nodes]]
    id = "node-source"
    type = "JuliaFlow.Base.CSVReader"
    name = "CSV Reader"
    execution_hint = "cpu_only"
    ports = [{ id = "out", direction = "output", type = "data_table" }]
    config = { path = "assets/sample.csv" }

    [[nodes]]
    id = "node-train"
    type = "JuliaFlow.Base.ModelTrain"
    name = "GPU Trainer"
    execution_hint = "gpu_required"
    ports = [
        { id = "in", direction = "input", type = "data_table" },
        { id = "model", direction = "output", type = "model" },
    ]
    config = { target = "amount", gpuDevicePreference = "nvidia0", gpuWorkload = "mock_vector_sum", mockInputValues = [1.0, 2.0, 3.0, 4.0] }
    capabilities = { execution_mode = "batch", resource_class = "gpu", accelerator = "cuda", worker_pool = "alpha-gpu" }

    [[connections]]
    source_node_id = "node-source"
    source_port_id = "out"
    target_node_id = "node-train"
    target_port_id = "in"
    data_type = "data_table"
    """
    gpu_workflow = load_workflow_definition_text(gpu_workflow_text)
    runtime_branch_workflow = load_workflow_definition_text(runtime_branch_workflow_text())
    batch_parallel_workflow = load_workflow_definition_text(
        replace(
            replace(read(parallel_path, String), "run_mode = \"stream\"" => "run_mode = \"batch\""),
            "id = \"wf-parallel\"" => "id = \"wf-parallel-batch\"";
            count = 1,
        ),
    )
    workflows = Dict(
        foundation_workflow.id => foundation_workflow,
        parallel_workflow.id => parallel_workflow,
        gpu_workflow.id => gpu_workflow,
        runtime_branch_workflow.id => runtime_branch_workflow,
        batch_parallel_workflow.id => batch_parallel_workflow,
    )
    service = WorkerServiceState()
    executions = GatewayExecution[]

    push!(
        executions,
        JuliaFlowApiGateway.materialize_execution(
            execute_workflow(foundation_workflow; checkpoint_tag = "cp/02-alpha-core"),
        ),
    )
    recovery_record = append_execution_event(
        JuliaFlowApiGateway.execution_record(executions[1]);
        message = "Transform failed; route to catch",
        metadata = Dict(
            "control_flow_recovery" => try_catch_recovery_metadata(foundation_workflow, "node-transform"),
        ),
    )
    executions[1] = JuliaFlowApiGateway.materialize_execution(recovery_record)
    catch_branch = process_control_flow_recovery_tick!(
        service,
        workflows,
        executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test length(catch_branch) == 1
    @test catch_branch[1].status == "completed"
    @test catch_branch[1].metadata["control_flow_branch_state"]["branch"] == "catch"
    @test catch_branch[1].metadata["control_flow_branch_state"]["completed_node_ids"] == ["node-bi"]
    @test catch_branch[1].metadata["control_flow_branch_state"]["node_results"][1]["output_kind"] == "bi_outlet"
    @test catch_branch[1].metadata["control_flow_branch_state"]["node_results"][1]["row_count"] == 3
    @test catch_branch[1].execution_id in service.control_flow_branch_execution_ids
    catch_branch_payload = JuliaFlowApiGateway.execution_payload(catch_branch[1])
    @test catch_branch_payload["controlFlowBranchState"]["workerId"] == catch_branch[1].metadata["control_flow_branch_state"]["worker_id"]
    @test catch_branch_payload["controlFlowBranchState"]["nodeResults"][1]["rowCount"] == 3
    @test JuliaFlowApiGateway.node_runtime_status("node-transform", catch_branch[1]) == "error"
    @test JuliaFlowApiGateway.node_runtime_status("node-bi", catch_branch[1]) == "executed"

    runtime_branch_execution = JuliaFlowApiGateway.materialize_execution(
        execute_workflow(runtime_branch_workflow; checkpoint_tag = "cp/branch-dag"),
    )
    runtime_branch_record = append_execution_event(
        JuliaFlowApiGateway.execution_record(runtime_branch_execution);
        message = "Transform failed; schedule catch DAG",
        metadata = Dict(
            "control_flow_recovery" => try_catch_recovery_metadata(runtime_branch_workflow, "node-transform"),
        ),
    )
    push!(executions, JuliaFlowApiGateway.materialize_execution(runtime_branch_record))
    runtime_branches = process_control_flow_recovery_tick!(
        service,
        workflows,
        executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    runtime_branch = runtime_branches[end]
    runtime_branch_state = runtime_branch.metadata["control_flow_branch_state"]
    @test runtime_branch_state["branch_stages"] == [["catch-log", "catch-clean"], ["catch-bi"]]
    @test runtime_branch_state["branch_stage_index"] == 2
    @test runtime_branch_state["branch_stage_count"] == 2
    @test runtime_branch_state["completed_node_ids"] == ["catch-log", "catch-clean", "catch-bi"]
    @test runtime_branch_state["active_node_ids"] == String[]
    @test runtime_branch_state["stage_results"][1]["node_ids"] == ["catch-log", "catch-clean"]
    @test runtime_branch_state["stage_results"][2]["node_results"][1]["node_id"] == "catch-bi"
    @test runtime_branch_state["stage_results"][2]["node_results"][1]["row_count"] == 2
    runtime_branch_payload = JuliaFlowApiGateway.execution_payload(runtime_branch)
    @test runtime_branch_payload["controlFlowBranchState"]["branchStages"] == [["catch-log", "catch-clean"], ["catch-bi"]]
    @test runtime_branch_payload["controlFlowBranchState"]["branchStageIndex"] == 2
    @test runtime_branch_payload["controlFlowBranchState"]["stageResults"][2]["nodeResults"][1]["rowCount"] == 2

    push!(
        executions,
        JuliaFlowApiGateway.materialize_execution(
            execute_workflow(batch_parallel_workflow; checkpoint_tag = "cp/executor-multitick"),
        ),
    )
    executor_tick_one = process_executor_schedule_tick!(
        service,
        executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test executor_tick_one[1].status == "queued"
    @test executor_tick_one[1].metadata["executor_state"]["status"] == "queued"
    executor_tick_two = process_executor_schedule_tick!(
        service,
        executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test executor_tick_two[1].status == "running"
    @test executor_tick_two[1].metadata["executor_state"]["current_stage_index"] == 1
    @test executor_tick_two[1].metadata["executor_state"]["active_node_ids"] == ["node-source"]
    executor_tick_three = process_executor_schedule_tick!(
        service,
        executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test executor_tick_three[1].status == "running"
    @test executor_tick_three[1].metadata["executor_state"]["current_stage_index"] == 2
    @test executor_tick_three[1].metadata["executor_state"]["completed_node_ids"] == ["node-source"]
    @test executor_tick_three[1].metadata["executor_state"]["active_node_ids"] == ["node-left", "node-right"]
    executor_tick_four = process_executor_schedule_tick!(
        service,
        executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test executor_tick_four[1].status == "running"
    @test executor_tick_four[1].metadata["executor_state"]["current_stage_index"] == 3
    @test executor_tick_four[1].metadata["executor_state"]["completed_stage_indexes"] == [1, 2]
    executor_tick_five = process_executor_schedule_tick!(
        service,
        executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test executor_tick_five[1].status == "completed"
    @test executor_tick_five[1].metadata["executor_state"]["status"] == "completed"
    @test executor_tick_five[1].metadata["executor_state"]["completed_node_ids"] == ["node-source", "node-left", "node-right", "node-sink"]
    @test executor_tick_five[1].metadata["executor_state"]["stage_results"][3]["status"] == "completed"
    executor_payload = JuliaFlowApiGateway.execution_payload(executor_tick_five[1])
    @test executor_payload["executorState"]["currentStageIndex"] == 3
    @test executor_payload["executorState"]["completedStageIndexes"] == [1, 2, 3]
    @test executor_payload["executorState"]["stageResults"][2]["nodeIds"] == ["node-left", "node-right"]

    function executor_fixture_node_result(_workflow, execution, node_id)
        return Dict{String,Any}(
            "node_id" => String(node_id),
            "node_type" => "fixture.$(node_id)",
            "status" => "executed",
            "output_kind" => "node",
            "row_count" => node_id == "node-source" ? 11 : 0,
            "output_refs" => ["memory://executor/$(execution.execution_id)/$(node_id)"],
        )
    end

    executor_result_executions = GatewayExecution[]
    push!(
        executor_result_executions,
        JuliaFlowApiGateway.materialize_execution(
            execute_workflow(batch_parallel_workflow; checkpoint_tag = "cp/executor-node-results"),
        ),
    )
    executor_result_service = WorkerServiceState()
    for _ in 1:5
        process_executor_schedule_tick!(
            executor_result_service,
            executor_result_executions;
            workflows = workflows,
            execute_stage_node = executor_fixture_node_result,
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            append_execution_event = append_execution_event,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
    end
    executor_result_state = executor_result_executions[1].metadata["executor_state"]
    @test executor_result_executions[1].status == "completed"
    @test length(executor_result_state["node_results"]) == 4
    @test executor_result_state["stage_results"][1]["node_results"][1]["row_count"] == 11
    @test executor_result_state["stage_results"][2]["node_results"][1]["output_refs"][1] ==
        "memory://executor/$(executor_result_executions[1].execution_id)/node-left"
    executor_result_payload = JuliaFlowApiGateway.execution_payload(executor_result_executions[1])
    @test executor_result_payload["executorState"]["nodeResults"][1]["rowCount"] == 11
    @test executor_result_payload["executorState"]["stageResults"][2]["nodeResults"][2]["nodeId"] == "node-right"
    @test JuliaFlowApiGateway.node_runtime_status("node-right", executor_result_executions[1]) == "executed"

    function failing_executor_fixture_node(_workflow, execution, node_id)
        node_id == "node-left" && error("fixture executor failure")
        return executor_fixture_node_result(_workflow, execution, node_id)
    end

    executor_error_executions = GatewayExecution[]
    push!(
        executor_error_executions,
        JuliaFlowApiGateway.materialize_execution(
            execute_workflow(batch_parallel_workflow; checkpoint_tag = "cp/executor-node-error"),
        ),
    )
    executor_error_service = WorkerServiceState()
    for _ in 1:4
        process_executor_schedule_tick!(
            executor_error_service,
            executor_error_executions;
            workflows = workflows,
            execute_stage_node = failing_executor_fixture_node,
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            append_execution_event = append_execution_event,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
    end
    executor_error_state = executor_error_executions[1].metadata["executor_state"]
    @test executor_error_executions[1].status == "failed"
    @test executor_error_state["status"] == "failed"
    @test executor_error_state["failed_node_id"] == "node-left"
    @test occursin("fixture executor failure", executor_error_state["error_message"])
    @test executor_error_state["completed_node_ids"] == ["node-source"]
    @test executor_error_state["stage_results"][2]["status"] == "failed"
    @test executor_error_state["stage_results"][2]["node_results"][1]["status"] == "error"
    executor_error_payload = JuliaFlowApiGateway.execution_payload(executor_error_executions[1])
    @test executor_error_payload["executorState"]["failedNodeId"] == "node-left"
    @test occursin("fixture executor failure", executor_error_payload["executorState"]["errorMessage"])
    @test JuliaFlowApiGateway.node_runtime_status("node-left", executor_error_executions[1]) == "error"

    executor_dataflow_workflow = load_workflow_definition_text("""
    version = "0.1.0"

    [workflow]
    id = "wf-executor-dataflow"
    name = "Executor Dataflow"

    [runtime]
    run_mode = "batch"

    [[nodes]]
    id = "node-source"
    name = "Source"
    type = "JuliaFlow.Base.CSVReader"
    execution_hint = "cpu_only"
    ports = [{ id = "source_out", direction = "output", type = "data_table" }]
    config = { path = "object://executor/source.arrow" }

    [[nodes]]
    id = "node-select"
    name = "Select"
    type = "JuliaFlow.Base.ColumnSelect"
    execution_hint = "cpu_only"
    ports = [
      { id = "table_in", direction = "input", type = "data_table" },
      { id = "table_out", direction = "output", type = "data_table" }
    ]
    config = { columns = ["region", "amount"] }

    [[nodes]]
    id = "node-aggregate"
    name = "Aggregate"
    type = "JuliaFlow.Base.AggregateRows"
    execution_hint = "cpu_only"
    ports = [
      { id = "table_in", direction = "input", type = "data_table" },
      { id = "table_out", direction = "output", type = "data_table" }
    ]
    config = { group_by = ["region"], aggregation = "sum", value_column = "amount" }

    [[nodes]]
    id = "node-sink"
    name = "Sink"
    type = "JuliaFlow.Base.ArrowSink"
    execution_hint = "cpu_only"
    ports = [{ id = "table_in", direction = "input", type = "data_table" }]
    config = { destination = "warehouse://executor/result.arrow", mode = "overwrite" }

    [[connections]]
    source_node_id = "node-source"
    source_port_id = "source_out"
    target_node_id = "node-select"
    target_port_id = "table_in"
    data_type = "data_table"

    [[connections]]
    source_node_id = "node-select"
    source_port_id = "table_out"
    target_node_id = "node-aggregate"
    target_port_id = "table_in"
    data_type = "data_table"

    [[connections]]
    source_node_id = "node-aggregate"
    source_port_id = "table_out"
    target_node_id = "node-sink"
    target_port_id = "table_in"
    data_type = "data_table"
    """)
    dataflow_writer = Ref{Any}(nothing)
    dataflow_state = ExecutorDataflowState(
        metadata = Dict{String,Any}(
            "tabular_ref_reader" => (ref, _context) -> begin
                @test ref == "object://executor/source.arrow"
                return (
                    rows = [
                        Dict("region" => "west", "amount" => 120.0),
                        Dict("region" => "east", "amount" => 80.0),
                        Dict("region" => "north", "amount" => 200.0),
                    ],
                    schema = ["region", "amount"],
                    adapter = "executor_reader",
                )
            end,
            "tabular_ref_writer" => (destination_uri, rows, _context) -> begin
                dataflow_writer[] = (destination_uri = destination_uri, rows = rows)
                return (ref = destination_uri, row_count = length(rows), adapter = "executor_writer")
            end,
        ),
    )
    dataflow_executions = GatewayExecution[]
    push!(
        dataflow_executions,
        JuliaFlowApiGateway.materialize_execution(
            execute_workflow(executor_dataflow_workflow; checkpoint_tag = "cp/executor-dataflow"),
        ),
    )
    dataflow_service = WorkerServiceState()
    dataflow_workflows = Dict(executor_dataflow_workflow.id => executor_dataflow_workflow)
    for _ in 1:8
        process_executor_schedule_tick!(
            dataflow_service,
            dataflow_executions;
            workflows = dataflow_workflows,
            execute_stage_node = (workflow, execution, node_id) ->
                execute_executor_dataflow_node!(dataflow_state, workflow, execution, node_id),
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            append_execution_event = append_execution_event,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
    end
    dataflow_executor_state = dataflow_executions[1].metadata["executor_state"]
    @test dataflow_executions[1].status == "completed"
    @test dataflow_executor_state["dataflow_policy"]["policy_name"] == "callback_dataflow_stage_barrier"
    @test dataflow_executor_state["dataflow_policy"]["callback_enabled"] == true
    @test dataflow_executor_state["dataflow_policy"]["dataflow_enabled"] == true
    @test dataflow_executor_state["dataflow_policy"]["eligible_node_ids"] ==
        ["node-source", "node-select", "node-aggregate", "node-sink"]
    @test dataflow_executor_state["dataflow_policy"]["source_node_ids"] == ["node-source"]
    @test dataflow_executor_state["dataflow_policy"]["sink_node_ids"] == ["node-sink"]
    @test dataflow_executor_state["dataflow_policy"]["max_concurrency"] == 1
    @test length(dataflow_executor_state["node_results"]) == 4
    @test dataflow_executor_state["node_results"][1]["node_key"] == ARROW_TABLE_SOURCE_NODE_KEY
    @test dataflow_executor_state["node_results"][1]["row_count"] == 3
    @test dataflow_executor_state["node_results"][2]["node_key"] == SELECT_COLUMNS_NODE_KEY
    @test dataflow_executor_state["node_results"][2]["row_count"] == 3
    @test dataflow_executor_state["node_results"][3]["node_key"] == AGGREGATE_ROWS_NODE_KEY
    @test dataflow_executor_state["node_results"][3]["row_count"] == 3
    @test dataflow_executor_state["node_results"][4]["node_key"] == ARROW_TABLE_SINK_NODE_KEY
    @test dataflow_executor_state["node_results"][4]["persisted_ref"] == "warehouse://executor/result.arrow"
    @test dataflow_writer[].destination_uri == "warehouse://executor/result.arrow"
    @test length(dataflow_writer[].rows) == 3
    @test dataflow_writer[].rows[1]["region"] == "east"
    @test haskey(dataflow_state.outputs["node-aggregate"], "table_out")
    dataflow_payload = JuliaFlowApiGateway.execution_payload(dataflow_executions[1])
    @test dataflow_payload["executorSchedule"][1]["dataflowPolicy"]["policyName"] == "callback_dataflow_stage_barrier"
    @test dataflow_payload["executorSchedule"][1]["dataflowPolicy"]["sourceNodeIds"] == ["node-source"]
    @test dataflow_payload["executorSchedule"][4]["dataflowPolicy"]["sinkNodeIds"] == ["node-sink"]
    @test dataflow_payload["executorState"]["dataflowPolicy"]["eligibleNodeIds"] ==
        ["node-source", "node-select", "node-aggregate", "node-sink"]
    @test dataflow_payload["executorState"]["nodeResults"][3]["rowCount"] == 3
    @test JuliaFlowApiGateway.node_runtime_status("node-sink", dataflow_executions[1]) == "executed"

    function complete_gpu_workflow_once(workflow; registry = "mock:nvidia0")
        withenv("JULIAFLOW_GPU_REGISTRY" => registry) do
            local_executions = GatewayExecution[]
            push!(
                local_executions,
                JuliaFlowApiGateway.materialize_execution(
                    execute_workflow(workflow; checkpoint_tag = "cp/03-alpha-gpu-bi"),
                ),
            )
            local_service = WorkerServiceState()
            queued = activate_gpu_execution!(
                local_service,
                local_executions,
                local_executions[1].execution_id;
                execution_record = JuliaFlowApiGateway.execution_record,
                transition_execution_record = transition_execution_record,
                materialize_execution = JuliaFlowApiGateway.materialize_execution,
            )
            running = promote_gpu_execution!(
                local_service,
                local_executions,
                queued.execution_id;
                execution_record = JuliaFlowApiGateway.execution_record,
                transition_execution_record = transition_execution_record,
                materialize_execution = JuliaFlowApiGateway.materialize_execution,
            )
            completed = process_gpu_compute_tick!(
                local_service,
                Dict(workflow.id => workflow),
                local_executions;
                execution_record = JuliaFlowApiGateway.execution_record,
                transition_execution_record = transition_execution_record,
                materialize_execution = JuliaFlowApiGateway.materialize_execution,
            )
            @test running.status == "running"
            @test length(completed) == 1
            return queued, completed[1]
        end
    end

    push!(
        executions,
        JuliaFlowApiGateway.materialize_execution(
            execute_workflow(parallel_workflow; checkpoint_tag = "cp/02-alpha-core"),
        ),
    )
    queued_stream = queue_stream_execution!(
        service,
        workflows,
        executions,
        executions[end].execution_id;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test queued_stream.status == "queued"
    @test queued_stream.metadata["stream_lifecycle_status"] == "starting"

    processed_streams = process_stream_worker_tick!(
        service,
        executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test length(processed_streams) == 1
    activated_stream = processed_streams[1]
    @test activated_stream.status == "running"
    @test activated_stream.metadata["stream_lifecycle_status"] == "active"
    @test activated_stream.metadata["stream_topic"] == "parallel.events"
    @test activated_stream.metadata["stream_adapter"] == "fixture"
    @test activated_stream.metadata["stream_consumer_lag"] == 3
    @test service.stream_execution_ids[parallel_workflow.id] == activated_stream.execution_id

    first_batch = process_stream_fixture_batch!(
        service,
        workflows,
        executions,
        parallel_workflow.id;
        execution_record = JuliaFlowApiGateway.execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
        batch_size = 2,
    )
    @test first_batch.metadata["stream_processed_offset"] == 2
    @test first_batch.metadata["stream_processed_rows"] == 2
    @test first_batch.metadata["stream_consumer_lag"] == 1
    @test first_batch.metadata["stream_backpressure"] == "ok"
    @test first_batch.metadata["stream_watermark"] == 2
    @test first_batch.metadata["stream_watermark_state"]["mode"] == "processing_time"
    @test first_batch.metadata["stream_watermark_state"]["committedWatermark"] == 2
    @test first_batch.metadata["stream_window_state"]["windows"][1]["count"] == 2
    @test first_batch.metadata["stream_checkpoint_offsets"]["lastOffset"] == 2
    @test first_batch.metadata["stream_checkpoint_offsets"]["committedOffset"] == 2
    @test first_batch.metadata["stream_checkpoint_offsets"]["watermark"] == 2
    @test first_batch.metadata["stream_exactly_once_status"] == "committed"
    @test first_batch.metadata["stream_sink_transaction_id"] == "stream-$(first_batch.execution_id)-offset-0-2"
    @test first_batch.metadata["stream_sink_transaction_state"]["status"] == "committed"
    @test first_batch.metadata["stream_sink_transaction_state"]["fenceToken"] == "juliaflow-dev:0:2"

    replayed_first_batch = replay_stream_fixture_batch!(
        service,
        workflows,
        executions,
        parallel_workflow.id,
        0;
        execution_record = JuliaFlowApiGateway.execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
        batch_size = 2,
    )
    @test replayed_first_batch.metadata["stream_processed_offset"] == 2
    @test replayed_first_batch.metadata["stream_processed_rows"] == 2
    @test replayed_first_batch.metadata["stream_exactly_once_status"] == "duplicate_suppressed"
    @test replayed_first_batch.metadata["stream_replay_status"] == "duplicate_skipped"
    @test replayed_first_batch.metadata["stream_replay_offset"] == 0

    restarted_service = WorkerServiceState()
    sync_worker_service!(restarted_service, executions)
    @test restarted_service.stream_execution_ids[parallel_workflow.id] == first_batch.execution_id
    second_batch = replay_stream_fixture_batch!(
        restarted_service,
        workflows,
        executions,
        parallel_workflow.id,
        first_batch.metadata["stream_checkpoint_offsets"]["committedOffset"];
        execution_record = JuliaFlowApiGateway.execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
        batch_size = 1,
    )
    @test second_batch.metadata["stream_processed_offset"] == 3
    @test second_batch.metadata["stream_processed_rows"] == 3
    @test second_batch.metadata["stream_consumer_lag"] == 0
    @test second_batch.metadata["stream_watermark"] == 3
    @test second_batch.metadata["stream_replay_status"] == "restored_from_checkpoint"
    @test second_batch.metadata["stream_replay_offset"] == 2
    @test second_batch.metadata["stream_window_state"]["windows"][1]["start"] == 30
    second_batch_payload = JuliaFlowApiGateway.execution_payload(second_batch)
    @test second_batch_payload["streamProcessedOffset"] == 3
    @test second_batch_payload["streamConsumerLag"] == 0
    @test second_batch_payload["streamBackpressure"] == "ok"
    @test second_batch_payload["streamWatermarkState"]["mode"] == "processing_time"
    @test second_batch_payload["streamSinkTransactionState"]["status"] == "committed"
    @test second_batch_payload["streamWindowState"]["windows"][1]["start"] == 30

    mktempdir() do kafka_runtime_dir
        kafka_events_path = joinpath(kafka_runtime_dir, "kafka-events.jsonl")
        sink_state_path = joinpath(kafka_runtime_dir, "sink-state.json")
        sink_output_path = joinpath(kafka_runtime_dir, "sink-output.jsonl")
        write(
            kafka_events_path,
            join(
                [
                    JSON3.write(Dict("topic" => "parallel.events", "partition" => 0, "offset" => 1, "event_time_seconds" => 1, "region" => "north", "amount" => 10.0)),
                    JSON3.write(Dict("topic" => "parallel.events", "partition" => 0, "offset" => 2, "event_time_seconds" => 2, "region" => "south", "amount" => 20.0)),
                    JSON3.write(Dict("topic" => "parallel.events", "partition" => 0, "offset" => 3, "event_time_seconds" => 3, "region" => "north", "amount" => 30.0)),
                ],
                "\n",
            ) * "\n",
        )
        withenv(
            "JULIAFLOW_KAFKA_EVENTS_JSONL" => kafka_events_path,
            "JULIAFLOW_STREAM_SINK_STATE_PATH" => sink_state_path,
            "JULIAFLOW_STREAM_SINK_OUTPUT_PATH" => sink_output_path,
        ) do
            live_kafka_workflow = load_workflow_definition(parallel_path)
            live_kafka_service = WorkerServiceState()
            live_kafka_executions = GatewayExecution[
                JuliaFlowApiGateway.materialize_execution(
                    execute_workflow(live_kafka_workflow; checkpoint_tag = "cp/live-kafka-smoke"),
                ),
            ]
            queue_stream_execution!(
                live_kafka_service,
                Dict(live_kafka_workflow.id => live_kafka_workflow),
                live_kafka_executions,
                live_kafka_executions[1].execution_id;
                execution_record = JuliaFlowApiGateway.execution_record,
                transition_execution_record = transition_execution_record,
                materialize_execution = JuliaFlowApiGateway.materialize_execution,
            )
            process_stream_worker_tick!(
                live_kafka_service,
                live_kafka_executions;
                execution_record = JuliaFlowApiGateway.execution_record,
                transition_execution_record = transition_execution_record,
                materialize_execution = JuliaFlowApiGateway.materialize_execution,
            )
            kafka_first = process_stream_fixture_batch!(
                live_kafka_service,
                Dict(live_kafka_workflow.id => live_kafka_workflow),
                live_kafka_executions,
                live_kafka_workflow.id;
                execution_record = JuliaFlowApiGateway.execution_record,
                append_execution_event = append_execution_event,
                materialize_execution = JuliaFlowApiGateway.materialize_execution,
                batch_size = 2,
            )
            @test kafka_first.metadata["stream_adapter"] == "kafka"
            @test kafka_first.metadata["stream_processed_offset"] == 2
            @test kafka_first.metadata["stream_sink_transaction_state"]["status"] == "committed"
            @test length(readlines(sink_output_path)) == 2

            kafka_duplicate = replay_stream_fixture_batch!(
                live_kafka_service,
                Dict(live_kafka_workflow.id => live_kafka_workflow),
                live_kafka_executions,
                live_kafka_workflow.id,
                0;
                execution_record = JuliaFlowApiGateway.execution_record,
                append_execution_event = append_execution_event,
                materialize_execution = JuliaFlowApiGateway.materialize_execution,
                batch_size = 2,
            )
            @test kafka_duplicate.metadata["stream_exactly_once_status"] == "duplicate_suppressed"
            @test length(readlines(sink_output_path)) == 2

            live_kafka_restart = WorkerServiceState()
            sync_worker_service!(live_kafka_restart, live_kafka_executions)
            kafka_second = replay_stream_fixture_batch!(
                live_kafka_restart,
                Dict(live_kafka_workflow.id => live_kafka_workflow),
                live_kafka_executions,
                live_kafka_workflow.id,
                kafka_first.metadata["stream_committed_offset"];
                execution_record = JuliaFlowApiGateway.execution_record,
                append_execution_event = append_execution_event,
                materialize_execution = JuliaFlowApiGateway.materialize_execution,
                batch_size = 1,
            )
            @test kafka_second.metadata["stream_processed_offset"] == 3
            @test kafka_second.metadata["stream_replay_status"] == "restored_from_checkpoint"
            @test length(readlines(sink_output_path)) == 3
        end
    end

    event_time_workflow = load_workflow_definition(parallel_path)
    event_time_workflow.runtime.source["kind"] = "fixture"
    event_time_workflow.runtime.source["events"] = parallel_workflow.runtime.source["events"]
    event_time_workflow.runtime.policy["watermark_mode"] = "event_time"
    event_time_service = WorkerServiceState()
    event_time_executions = GatewayExecution[
        JuliaFlowApiGateway.materialize_execution(
            execute_workflow(event_time_workflow; checkpoint_tag = "cp/event-time-watermark"),
        ),
    ]
    queue_stream_execution!(
        event_time_service,
        Dict(event_time_workflow.id => event_time_workflow),
        event_time_executions,
        event_time_executions[1].execution_id;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    process_stream_worker_tick!(
        event_time_service,
        event_time_executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    event_time_batch = process_stream_fixture_batch!(
        event_time_service,
        Dict(event_time_workflow.id => event_time_workflow),
        event_time_executions,
        event_time_workflow.id;
        execution_record = JuliaFlowApiGateway.execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
        batch_size = 2,
    )
    @test event_time_batch.metadata["stream_watermark"] == 7
    @test event_time_batch.metadata["stream_watermark_state"]["mode"] == "event_time"
    @test event_time_batch.metadata["stream_watermark_state"]["source"] == "event_time"
    @test event_time_batch.metadata["stream_watermark_state"]["allowedLatenessSeconds"] == 5

    paused_stream = set_stream_lifecycle!(
        service,
        executions,
        parallel_workflow.id;
        lifecycle_status = "paused",
        message = "Streaming execution paused",
        execution_record = JuliaFlowApiGateway.execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test paused_stream.metadata["stream_lifecycle_status"] == "paused"

    stopped_stream = stop_stream_execution!(
        service,
        executions,
        parallel_workflow.id;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test stopped_stream.status == "completed"
    @test stopped_stream.metadata["stream_lifecycle_status"] == "stopped"
    @test !haskey(service.stream_execution_ids, parallel_workflow.id)

    push!(
        executions,
        JuliaFlowApiGateway.materialize_execution(
            execute_workflow(gpu_workflow; checkpoint_tag = "cp/03-alpha-gpu-bi"),
        ),
    )
    activated_gpu = activate_gpu_execution!(
        service,
        executions,
        executions[end].execution_id;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test activated_gpu.status == "queued"
    @test activated_gpu.metadata["dispatch_lane"] == "gpu"
    @test activated_gpu.metadata["dispatch_worker_pool"] == "alpha-gpu"
    @test activated_gpu.metadata["dispatch_isolation_mode"] == "isolated"
    @test activated_gpu.metadata["dispatch_accelerator"] == "cuda"
    @test activated_gpu.metadata["dispatch_scheduler_policy"] == "deterministic_device_id"
    @test activated_gpu.metadata["dispatch_placement_reason"] == "gpu_lane_isolated_worker"
    @test activated_gpu.metadata["dispatch_requested_device"] == "nvidia0"
    @test activated_gpu.metadata["dispatch_worker_capacity"]["device_slots"] == 1
    @test startswith(activated_gpu.metadata["worker_id"], "gpu-worker-")
    @test activated_gpu.execution_id in service.gpu_execution_ids

    promoted_gpu = promote_gpu_execution!(
        service,
        executions,
        activated_gpu.execution_id;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test promoted_gpu.status == "running"
    @test promoted_gpu.execution_id in service.gpu_execution_ids

    completed_gpu = process_gpu_compute_tick!(
        service,
        workflows,
        executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test length(completed_gpu) == 1
    @test completed_gpu[1].status == "completed"
    @test completed_gpu[1].metadata["gpu_execution_path"] == "gpu"
    @test completed_gpu[1].metadata["gpu_device_id"] == "nvidia0"
    @test completed_gpu[1].metadata["gpu_requested_device"] == "nvidia0"
    @test completed_gpu[1].metadata["gpu_selected_device"] == "nvidia0"
    @test completed_gpu[1].metadata["gpu_fallback_reason"] == "none"
    @test completed_gpu[1].metadata["gpu_placement_reason"] == "requested_device_match"
    @test completed_gpu[1].metadata["gpu_scheduler_policy"] == "deterministic_device_id"
    @test completed_gpu[1].metadata["gpu_worker_isolation_mode"] == "isolated"
    @test completed_gpu[1].metadata["gpu_worker_capacity"]["device_count"] == 1
    @test completed_gpu[1].metadata["gpu_workload_result"]["sum"] == 10.0

    requested_gpu_workflow = load_workflow_definition_text(replace(gpu_workflow_text, "gpuDevicePreference = \"nvidia0\"" => "gpuDevicePreference = \"nvidia1\""))
    _, requested_completed = complete_gpu_workflow_once(requested_gpu_workflow; registry = "cuda:nvidia0,cuda:nvidia1")
    @test requested_completed.metadata["gpu_execution_path"] == "gpu"
    @test requested_completed.metadata["gpu_requested_device"] == "nvidia1"
    @test requested_completed.metadata["gpu_selected_device"] == "nvidia1"
    @test requested_completed.metadata["gpu_fallback_reason"] == "none"
    @test requested_completed.metadata["gpu_request_satisfied"] == true
    @test requested_completed.metadata["gpu_placement_fallback_used"] == false

    requested_alias_gpu_workflow = load_workflow_definition_text(replace(gpu_workflow_text, "gpuDevicePreference = \"nvidia0\"" => "gpuDevicePreference = \"nvidia:1\""))
    _, requested_alias_completed = complete_gpu_workflow_once(requested_alias_gpu_workflow; registry = "cuda:nvidia0,cuda:nvidia1")
    @test requested_alias_completed.metadata["gpu_requested_device"] == "nvidia:1"
    @test requested_alias_completed.metadata["gpu_selected_device"] == "nvidia1"
    @test requested_alias_completed.metadata["gpu_fallback_reason"] == "none"
    @test requested_alias_completed.metadata["gpu_request_satisfied"] == true

    no_request_text = replace(gpu_workflow_text, ", gpuDevicePreference = \"nvidia0\"" => "")
    no_request_workflow = load_workflow_definition_text(no_request_text)
    no_request_queued, no_request_completed = complete_gpu_workflow_once(no_request_workflow; registry = "cuda:nvidia2,cuda:nvidia0")
    @test !haskey(no_request_queued.metadata, "dispatch_requested_device")
    @test no_request_completed.metadata["gpu_selected_device"] == "nvidia0"
    @test !haskey(no_request_completed.metadata, "gpu_requested_device")
    @test no_request_completed.metadata["gpu_placement_reason"] == "deterministic_default"
    @test no_request_completed.metadata["gpu_worker_capacity"]["device_count"] == 2

    invalid_gpu_workflow = load_workflow_definition_text(replace(gpu_workflow_text, "gpuDevicePreference = \"nvidia0\"" => "gpuDevicePreference = \"missing-device\""))
    _, invalid_completed = complete_gpu_workflow_once(invalid_gpu_workflow; registry = "cuda:nvidia2,cuda:nvidia0")
    @test invalid_completed.metadata["gpu_execution_path"] == "gpu"
    @test invalid_completed.metadata["gpu_requested_device"] == "missing-device"
    @test invalid_completed.metadata["gpu_selected_device"] == "nvidia0"
    @test invalid_completed.metadata["gpu_fallback_used"] == false
    @test invalid_completed.metadata["gpu_cpu_fallback_used"] == false
    @test invalid_completed.metadata["gpu_placement_fallback_used"] == true
    @test invalid_completed.metadata["gpu_request_satisfied"] == false
    @test invalid_completed.metadata["gpu_fallback_reason"] == "requested_device_unavailable"
    @test invalid_completed.metadata["gpu_placement_reason"] == "deterministic_default_after_request_miss"

    withenv("JULIAFLOW_GPU_REGISTRY" => "") do
        fallback_executions = GatewayExecution[]
        push!(fallback_executions, JuliaFlowApiGateway.materialize_execution(execute_workflow(gpu_workflow; checkpoint_tag = "cp/03-alpha-gpu-bi")))
        fallback_service = WorkerServiceState()
        fallback_queued = activate_gpu_execution!(
            fallback_service,
            fallback_executions,
            fallback_executions[1].execution_id;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        fallback_running = promote_gpu_execution!(
            fallback_service,
            fallback_executions,
            fallback_queued.execution_id;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        fallback_completed = process_gpu_compute_tick!(
            fallback_service,
            workflows,
            fallback_executions;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        @test fallback_running.status == "running"
        @test length(fallback_completed) == 1
        @test fallback_completed[1].metadata["gpu_execution_path"] == "cpu_fallback"
        @test fallback_completed[1].metadata["gpu_fallback_used"] == true
        @test fallback_completed[1].metadata["gpu_cpu_fallback_used"] == true
        @test fallback_completed[1].metadata["gpu_placement_fallback_used"] == true
        @test fallback_completed[1].metadata["gpu_request_satisfied"] == false
        @test fallback_completed[1].metadata["gpu_selected_device"] == "cpu-fallback"
        @test fallback_completed[1].metadata["gpu_fallback_reason"] == "registry_empty"
        @test fallback_completed[1].metadata["gpu_placement_reason"] == "no_matching_gpu_device"
        @test fallback_completed[1].metadata["gpu_worker_capacity"]["device_count"] == 0
    end
end

@testset "API Gateway" begin
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    parallel_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "parallel.workflow.toml")

    mktempdir() do store_root
        state = foundation_state(foundation_path; store_root = store_root)
        reloaded = load_state(store_root)
        import_root = mktempdir()
        import_source_path = joinpath(import_root, "foundation-profile.csv")
        secret_source_path = joinpath(import_root, "secrets.csv")
        large_source_path = joinpath(import_root, "large-profile.csv")
        unsupported_source_path = joinpath(import_root, "profile.exe")
        credential_content_path = joinpath(import_root, "profile-with-auth-column.csv")
        pii_content_path = joinpath(import_root, "profile-with-pii.csv")
        data_estate_root = mktempdir()
        foundation_raw_data_dir = joinpath(data_estate_root, "raw")
        mkpath(foundation_raw_data_dir)
        foundation_dataset_path = joinpath(foundation_raw_data_dir, "foundation-sales-sample.csv")
        write(import_source_path, "region,amount,window\nnorth,12.5,2026-Q2\nsouth,9.5,2026-Q2\n")
        write(secret_source_path, "api_key,value\nredacted,1\n")
        write(large_source_path, repeat("x", 2048))
        write(unsupported_source_path, "not,a,dataset\n")
        write(credential_content_path, "region,amount,access_token\nnorth,12.5,redacted\n")
        write(pii_content_path, "customer_id,ssn,amount\n1,000-00-0000,12.5\n")
        write(foundation_dataset_path, "region,segment,amount,margin\nnorth,retail,10,2\nsouth,enterprise,20,4\nnorth,retail,30,9\nsouth,enterprise,40,11\n")
        ENV["JULIAFLOW_IMPORT_ROOTS"] = import_root
        ENV["JULIAFLOW_IMPORT_MAX_BYTES"] = "1024"
        ENV["JULIAFLOW_DATA_ESTATE_ROOT"] = data_estate_root
        updated_toml = replace(read(foundation_path, String), "Foundation PoC" => "Foundation PoC Updated")
        foundation_workflow_payload = Dict{String,Any}(
            "workflow" => Dict(
                "version" => "0.1.0",
                "workflowId" => "wf-foundation",
                "name" => "Foundation JSON Save",
                "flowVariables" => [
                    Dict("name" => "JULIAFLOW_GPU_DEVICE", "type" => "GPUDeviceID", "default" => "nvidia:0"),
                    Dict("name" => "BATCH_WINDOW", "type" => "String", "default" => "2026-Q2"),
                ],
                "graph" => Dict(
                    "revision" => 3,
                    "selectedNodeId" => "node-transform",
                    "viewport" => Dict("x" => 0.0, "y" => 0.0, "zoom" => 1.0),
                    "nodeLayouts" => [
                        Dict("nodeId" => "node-source", "x" => 44.0, "y" => 72.0, "width" => 180.0),
                        Dict("nodeId" => "node-transform", "x" => 280.0, "y" => 148.0, "width" => 188.0),
                        Dict("nodeId" => "node-bi", "x" => 560.0, "y" => 148.0, "width" => 176.0),
                    ],
                ),
                "dashboards" => [
                    Dict(
                        "dashboardId" => "dashboard-foundation",
                        "name" => "Foundation Overview",
                        "binding" => Dict(
                            "outletNodeId" => "node-bi",
                            "datasetKey" => "sales_overview",
                            "refreshMode" => "live",
                        ),
                        "charts" => [
                            Dict("chartId" => "chart-line", "title" => "Trend", "family" => "line", "xField" => "window", "yField" => "amount"),
                            Dict("chartId" => "chart-bar", "title" => "By Region", "family" => "bar", "xField" => "region", "yField" => "amount"),
                            Dict("chartId" => "chart-area", "title" => "Capacity", "family" => "area", "xField" => "window", "yField" => "capacity"),
                            Dict("chartId" => "chart-table", "title" => "Rows", "family" => "table"),
                            Dict("chartId" => "chart-metric", "title" => "Latest", "family" => "metric", "yField" => "amount"),
                        ],
                    ),
                ],
                "runtime" => Dict(
                    "runMode" => "batch",
                ),
                "nodes" => [
                    Dict(
                        "id" => "node-source",
                        "type" => "JuliaFlow.Base.CSVReader",
                        "name" => "CSV Reader",
                        "executionHint" => "cpu_only",
                        "capabilities" => Dict("executionMode" => "batch", "resourceClass" => "cpu"),
                        "ports" => [Dict("id" => "out", "direction" => "output", "type" => "data_table")],
                        "config" => Dict("path" => "assets/sample.csv"),
                    ),
                    Dict(
                        "id" => "node-transform",
                        "type" => "JuliaFlow.Base.ColumnSelect",
                        "name" => "Column Select",
                        "executionHint" => "cpu_only",
                        "capabilities" => Dict("executionMode" => "batch", "resourceClass" => "cpu"),
                        "ports" => [
                            Dict("id" => "in", "direction" => "input", "type" => "data_table"),
                            Dict("id" => "out", "direction" => "output", "type" => "data_table"),
                        ],
                        "config" => Dict("columns" => ["amount", "region"]),
                    ),
                    Dict(
                        "id" => "node-bi",
                        "type" => "JuliaFlow.BI.DataOutlet",
                        "name" => "BI Outlet",
                        "executionHint" => "cpu_only",
                        "capabilities" => Dict("executionMode" => "hybrid", "resourceClass" => "cpu"),
                        "ports" => [Dict("id" => "in", "direction" => "input", "type" => "data_table")],
                        "config" => Dict("outlet" => "sales-overview"),
                    ),
                ],
                "connections" => [
                    Dict(
                        "sourceNodeId" => "node-source",
                        "sourcePortId" => "out",
                        "targetNodeId" => "node-transform",
                        "targetPortId" => "in",
                        "dataType" => "data_table",
                    ),
                    Dict(
                        "sourceNodeId" => "node-transform",
                        "sourcePortId" => "out",
                        "targetNodeId" => "node-bi",
                        "targetPortId" => "in",
                        "dataType" => "data_table",
                    ),
                ],
            ),
        )
        gpu_workflow_payload = Dict{String,Any}(
            "workflow" => Dict(
                "version" => "0.3.0",
                "workflowId" => "wf-gpu-alpha",
                "name" => "GPU Alpha",
                "flowVariables" => [
                    Dict("name" => "JULIAFLOW_GPU_DEVICE", "type" => "GPUDeviceID", "default" => "nvidia:0"),
                ],
                "runtime" => Dict("runMode" => "batch"),
                "nodes" => [
                    Dict(
                        "id" => "node-source",
                        "type" => "JuliaFlow.Base.CSVReader",
                        "name" => "CSV Reader",
                        "executionHint" => "cpu_only",
                        "capabilities" => Dict("executionMode" => "batch", "resourceClass" => "cpu", "workerPool" => "alpha-cpu"),
                        "ports" => [Dict("id" => "out", "direction" => "output", "type" => "data_table")],
                        "config" => Dict("path" => "assets/sample.csv"),
                    ),
                    Dict(
                        "id" => "node-train",
                        "type" => "JuliaFlow.Base.ModelTrain",
                        "name" => "GPU Trainer",
                        "executionHint" => "gpu_required",
                        "capabilities" => Dict(
                            "executionMode" => "batch",
                            "resourceClass" => "gpu",
                            "accelerator" => "cuda",
                            "workerPool" => "alpha-gpu",
                        ),
                        "ports" => [
                            Dict("id" => "in", "direction" => "input", "type" => "data_table"),
                            Dict("id" => "model", "direction" => "output", "type" => "model"),
                        ],
                        "config" => Dict("target" => "amount", "gpuDevicePreference" => "nvidia:0"),
                    ),
                ],
                "connections" => [
                    Dict(
                        "sourceNodeId" => "node-source",
                        "sourcePortId" => "out",
                        "targetNodeId" => "node-train",
                        "targetPortId" => "in",
                        "dataType" => "data_table",
                    ),
                ],
            ),
        )

        ENV["JULIAFLOW_LOCAL_PROFILE"] = "single-user"
        ENV["JULIAFLOW_HOME"] = store_root
        ENV["JULIAFLOW_DATA_ESTATE_ROOT"] = joinpath(store_root, "data-estate")
        ENV["JULIAFLOW_APPLIANCE_BOOTSTRAP"] = "1"
        @test occursin("\"status\":\"ok\"", healthcheck(state))
        @test occursin("\"localProfile\":\"single-user\"", healthcheck(state))
        health_payload = JSON3.read(healthcheck(state), Dict{String,Any})
        @test health_payload["runtimeMode"] == "development"
        @test health_payload["runtime"]["mode"] == "development"
        @test health_payload["runtime"]["fixtureProvenance"] == "backend"
        @test health_payload["runtime"]["fixtureSubstitutionAllowed"] == true
        @test health_payload["fixtureSubstitutionAllowed"] == true
        @test isempty(health_payload["unavailable"])
        previous_runtime_mode = get(ENV, "JULIAFLOW_RUNTIME_MODE", nothing)
        ENV["JULIAFLOW_RUNTIME_MODE"] = "release"
        release_health_payload = JSON3.read(healthcheck(state), Dict{String,Any})
        if previous_runtime_mode === nothing
            delete!(ENV, "JULIAFLOW_RUNTIME_MODE")
        else
            ENV["JULIAFLOW_RUNTIME_MODE"] = previous_runtime_mode
        end
        @test release_health_payload["runtimeMode"] == "release"
        @test release_health_payload["runtime"]["fixtureSubstitutionAllowed"] == false
        @test health_payload["metadataMode"] == "single-user"
        @test health_payload["metadataBackend"] == "file"
        @test health_payload["metadataReady"] == true
        @test health_payload["metadataSchemaStatus"] == "not_required"
        @test health_payload["metadataConcurrencyStatus"] == "single_writer"
        @test "workflows" in health_payload["metadataCapabilities"]
        @test "publishedDashboards" in health_payload["metadataCapabilities"]
        @test health_payload["dataEstateReady"] == true
        @test health_payload["dataEstateManaged"] == true
        @test health_payload["dataEstateManifestReady"] == true
        @test length(health_payload["dataEstateManifestChecksums"]) == 9
        @test all(item -> item["exists"] == true && !isempty(item["checksumSha256"]), health_payload["dataEstateManifestChecksums"])
        @test "arrow_ipc" in health_payload["dataEstateArtifactFormats"]
        @test "parquet" in health_payload["dataEstateArtifactFormats"]
        @test health_payload["dataEstateQuotaBytes"] > 0
        @test health_payload["dataEstateUsedBytes"] >= 0
        @test health_payload["dataEstateCleanupStatus"] == "ready"
        @test health_payload["dataEstateBackupStatus"] == "ready"
        @test health_payload["dataEstateDuckdbStatus"] == "ready"
        duckdb_query = read(String(health_payload["dataEstateDuckdbQueryPath"]), String)
        @test occursin(replace(String(health_payload["dataEstateRoot"]), "\\" => "/"), duckdb_query)
        @test !occursin("read_parquet('processed/**/*.parquet')", duckdb_query)
        @test health_payload["workspaceSummary"]["diskUsedBytes"] == health_payload["dataEstateUsedBytes"]
        @test all(!occursin("churn_model_v1", String(artifact["path"])) for artifact in health_payload["workspaceSummary"]["artifacts"])
        @test health_payload["hardwareProfileStatus"] == "ready"
        @test health_payload["hardwareSelectedBackend"] in ["cpu", "cuda", "simulated_cuda"]
        @test health_payload["cpuSchedulerPolicy"] == "bounded_threads"
        @test health_payload["cpuWorkerConcurrency"] >= 1
        @test health_payload["cpuWorkerConcurrency"] <= health_payload["cpuThreadCount"]
        @test health_payload["cpuMemoryLimitBytes"] > 0
        @test health_payload["cpuMemoryLimitBytes"] <= health_payload["totalMemoryBytes"]
        @test health_payload["computeSettings"]["selectedBackend"] in ["cpu", "cuda", "simulated_cuda"]
        @test health_payload["computeSettings"]["cpuWorkerConcurrency"] == health_payload["cpuWorkerConcurrency"]
        @test health_payload["computeSettings"]["cpuMemoryLimitBytes"] == health_payload["cpuMemoryLimitBytes"]
        @test health_payload["gpuCudaStatus"] in ["not_requested", "requested", "ready", "unavailable"]
        @test health_payload["gpuHardwareDeviceCount"] >= 0
        @test health_payload["gpuSimulatedDeviceCount"] >= 0
        @test health_payload["gpuTotalVramBytes"] >= 0
        @test length(health_payload["gpuDeviceSummaries"]) == health_payload["gpuHardwareDeviceCount"] + health_payload["gpuSimulatedDeviceCount"]
        @test health_payload["explainabilityEvidence"]["status"] == "ready"
        @test health_payload["explainabilityEvidence"]["datasetCard"]["datasetId"] == "foundation-sales-sample"
        @test health_payload["explainabilityEvidence"]["modelCard"]["kind"] == "deterministic_linear_baseline"
        @test length(health_payload["explainabilityEvidence"]["explanation"]["featureImportance"]) == 3
        @test health_payload["explainabilityEvidence"]["reproducibilityBundleReady"] == true
        @test isdir(health_payload["dataEstateManifestPath"])
        @test isdir(health_payload["dataEstateBackupRoot"])
        @test isfile(health_payload["dataEstateDuckdbQueryPath"])
        @test occursin("\"dataEstateReady\":true", healthcheck(state))
        @test occursin("\"cloudCredentialsRequired\":false", healthcheck(state))
        compute_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/settings/compute"),
        )
        @test compute_response.status == 200
        compute_payload = JSON3.read(String(compute_response.body), Dict{String,Any})
        @test compute_payload["schedulerPolicy"] == "bounded_threads"
        updated_compute_response = route_request(
            state,
            HTTP.Request("PUT", "/api/v1/settings/compute", ["Content-Type" => "application/json"], JSON3.write(Dict(
                "selectedBackend" => "cpu",
                "cpuWorkerConcurrency" => 1,
                "cpuMemoryLimitBytes" => 1_000_000_000,
                "gpuPreference" => "cpu_fallback",
                "blasThreadCount" => 1,
            ))),
        )
        @test updated_compute_response.status == 200
        updated_compute_payload = JSON3.read(String(updated_compute_response.body), Dict{String,Any})
        @test updated_compute_payload["source"] == "profile"
        @test updated_compute_payload["cpuWorkerConcurrency"] == 1
        refreshed_health_payload = JSON3.read(healthcheck(state), Dict{String,Any})
        @test refreshed_health_payload["cpuWorkerConcurrency"] == 1
        @test refreshed_health_payload["computeSettings"]["blasThreadCount"] == 1
        @test occursin("wf-foundation", list_workflows_response(state))
        @test occursin("\"nodeCount\":3", get_workflow_response(state, "wf-foundation"))
        @test occursin("\"nodes\":[", get_workflow_response(state, "wf-foundation"))
        @test occursin("\"connections\":[", get_workflow_response(state, "wf-foundation"))
        @test occursin("\"graphRevision\":2", get_workflow_response(state, "wf-foundation"))
        @test occursin("\"extensionId\":\"juliaflow-base\"", JuliaFlowApiGateway.list_hub_extensions_response(state))
        execution_json = execution_accept_response(state, "wf-foundation")
        accepted_execution = JSON3.read(execution_json, Dict{String,Any})
        @test occursin("\"accepted\"", execution_json)
        @test occursin("\"executionId\":", execution_json)
        @test occursin("\"mode\":\"batch_cpu\"", execution_json)
        @test occursin("\"statusHistory\":[", execution_json)
        @test occursin("\"resourcePlan\":[", execution_json)
        @test occursin("\"controlFlowPlan\":[", execution_json)
        @test accepted_execution["statusHistory"][1]["at"] isa AbstractString
        @test accepted_execution["controlFlowPlan"][1]["controlId"] == "loop-bi-refresh"
        @test accepted_execution["controlFlowPlan"][1]["bodyNodeIds"] == ["node-transform", "node-bi"]
        @test accepted_execution["controlFlowPlan"][2]["controlId"] == "try-bi-outlet"
        @test accepted_execution["controlFlowPlan"][2]["tryNodeIds"] == ["node-transform"]
        @test accepted_execution["controlFlowPlan"][2]["catchNodeIds"] == ["node-bi"]
        @test accepted_execution["explainabilityEvidence"]["datasetCard"]["datasetId"] == "foundation-sales-sample"
        @test accepted_execution["explainabilityEvidence"]["modelCard"]["kind"] == "deterministic_linear_baseline"
        @test accepted_execution["explainabilityEvidence"]["checkpointTag"] == accepted_execution["checkpointTag"]
        recovered_execution_json = transition_execution_response!(
            state,
            accepted_execution["executionId"];
            status = "failed",
            message = "Transform failed; route to catch",
            metadata = Dict{String,Any}("failedNodeId" => "node-transform"),
        )
        recovered_execution = JSON3.read(recovered_execution_json, Dict{String,Any})
        @test recovered_execution["status"] == "queued"
        @test recovered_execution["controlFlowRecovery"]["controlId"] == "try-bi-outlet"
        @test recovered_execution["controlFlowRecovery"]["failedNodeId"] == "node-transform"
        @test recovered_execution["controlFlowRecovery"]["catchNodeIds"] == ["node-bi"]
        @test recovered_execution["statusHistory"][end]["message"] == "Transform failed; route to catch"
        recovered_branches = JuliaFlowApiGateway.JuliaFlowWorkerService.process_control_flow_recovery_tick!(
            state.worker_service,
            state.workflows,
            state.executions;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            append_execution_event = append_execution_event,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        @test length(recovered_branches) == 1
        recovered_branch_payload = JuliaFlowApiGateway.execution_payload(recovered_branches[1])
        @test recovered_branch_payload["status"] == "completed"
        @test recovered_branch_payload["controlFlowBranchState"]["branch"] == "catch"
        @test recovered_branch_payload["controlFlowBranchState"]["completedNodeIds"] == ["node-bi"]
        @test recovered_branch_payload["controlFlowBranchState"]["branchStages"] == [["node-bi"]]
        @test recovered_branch_payload["controlFlowBranchState"]["branchStageCount"] == 1
        @test recovered_branch_payload["controlFlowBranchState"]["nodeResults"][1]["rowCount"] == 3
        uncaught_execution = JSON3.read(execution_accept_response(state, "wf-foundation"), Dict{String,Any})
        uncaught_failed_json = transition_execution_response!(
            state,
            uncaught_execution["executionId"];
            status = "failed",
            message = "Source failed without catch",
            metadata = Dict{String,Any}("failedNodeId" => "node-source"),
        )
        uncaught_failed = JSON3.read(uncaught_failed_json, Dict{String,Any})
        @test uncaught_failed["status"] == "failed"
        @test !haskey(uncaught_failed, "controlFlowRecovery")
        @test_throws ErrorException transition_execution_response!(
            state,
            uncaught_failed["executionId"];
            status = "failed",
            metadata = Dict{String,Any}("failedNodeId" => "node-transform"),
        )
        scheduler_execution = JSON3.read(execution_accept_response(state, "wf-foundation"), Dict{String,Any})
        @test scheduler_execution["executorSchedule"][1]["stageIndex"] == 1
        @test scheduler_execution["executorSchedule"][1]["schedulerPolicy"] == "topological_stage_barrier"
        @test scheduler_execution["executorSchedule"][1]["dataflowPolicy"]["policyName"] == "callback_dataflow_stage_barrier"
        @test scheduler_execution["executorSchedule"][2]["readyAfterStage"] == 1
        queued_execution_json = transition_execution_response!(
            state,
            scheduler_execution["executionId"];
            status = "queued",
            message = "Queued for CPU scheduler",
            metadata = Dict{String,Any}("queueName" => "foundation-cpu"),
        )
        @test occursin("\"status\":\"queued\"", queued_execution_json)
        @test occursin("\"queueName\":\"foundation-cpu\"", queued_execution_json)
        checkpoint_create_payload = JSON3.read(create_checkpoint_response!(state; tag = "cp/01-contracts-frozen", summary = "Contracts frozen"), Dict{String,Any})
        @test checkpoint_create_payload["checkpoint"]["tag"] == "cp/01-contracts-frozen"
        @test checkpoint_create_payload["checkpoint"]["explainabilityEvidence"]["datasetCard"]["datasetId"] == "foundation-sales-sample"
        @test occursin("cp/01-contracts-frozen", checkpoint_list_response(state))
        checkpoint_list_payload = JSON3.read(checkpoint_list_response(state), Dict{String,Any})
        @test checkpoint_list_payload["items"][end]["explainabilityEvidence"]["modelCard"]["kind"] == "deterministic_linear_baseline"
        @test haskey(reloaded.workflows, "wf-foundation")
        @test isfile(joinpath(store_root, "checkpoints.json"))
        @test isfile(joinpath(store_root, "executions.json"))
        @test occursin("wf-parallel", import_workflow_response!(state; source_path = parallel_path))
        @test occursin("\"status\":\"created\"", create_workflow_response!(state; workflow_toml = read(parallel_path, String)))
        stream_execution_json = execution_accept_response(state, "wf-parallel")
        stream_execution = JSON3.read(stream_execution_json, Dict{String,Any})
        @test stream_execution["mode"] == "stream_cpu"
        @test stream_execution["streamLifecycleStatus"] == "active"
        @test stream_execution["stream_topic"] == "parallel.events"
        withenv("JULIAFLOW_STREAM_WORKER_MODE" => "process") do
            queued_stream_json = execution_accept_response(state, "wf-parallel")
            queued_stream = JSON3.read(queued_stream_json, Dict{String,Any})
            @test queued_stream["status"] == "queued"
            @test queued_stream["streamLifecycleStatus"] == "starting"
            processed_streams = JuliaFlowApiGateway.JuliaFlowWorkerService.process_stream_worker_tick!(
                state.worker_service,
                state.executions;
                execution_record = JuliaFlowApiGateway.execution_record,
                transition_execution_record = transition_execution_record,
                materialize_execution = JuliaFlowApiGateway.materialize_execution,
            )
            @test length(processed_streams) >= 1
            processed_stream = processed_streams[end]
            JuliaFlowApiGateway.save_execution!(state.repository, processed_stream)
            @test processed_stream.status == "running"
            @test processed_stream.metadata["stream_lifecycle_status"] == "active"
        end
        json_update = JuliaFlowApiGateway.update_workflow_response_from_body!(state, "wf-foundation", foundation_workflow_payload)
        json_gpu_create = JuliaFlowApiGateway.create_workflow_response_from_body!(state, gpu_workflow_payload)
        gpu_execution_json = execution_accept_response(state, "wf-gpu-alpha")
        gpu_execution = JSON3.read(gpu_execution_json, Dict{String,Any})
        @test occursin("\"status\":\"updated\"", json_update)
        @test occursin("\"status\":\"created\"", json_gpu_create)
        @test gpu_execution["status"] == "queued"
        @test gpu_execution["dispatchLane"] == "gpu"
        @test gpu_execution["dispatchWorkerPool"] == "alpha-gpu"
        @test gpu_execution["dispatchIsolationMode"] == "isolated"
        @test gpu_execution["dispatchAccelerator"] == "cuda"
        @test gpu_execution["dispatchSchedulerPolicy"] == "deterministic_device_id"
        @test gpu_execution["dispatchPlacementReason"] == "gpu_lane_isolated_worker"
        @test gpu_execution["dispatchRequestedDevice"] == "nvidia:0"
        @test gpu_execution["dispatchWorkerCapacity"]["device_slots"] == 1
        @test startswith(gpu_execution["workerId"], "gpu-worker-")
        @test gpu_execution["dispatchPlan"][2]["lane"] == "gpu"
        @test gpu_execution["dispatchPlan"][2]["schedulerPolicy"] == "deterministic_device_id"
        @test gpu_execution["dispatchPlan"][2]["requestedDevice"] == "nvidia:0"
        json_updated_workflow = JSON3.read(get_workflow_response(state, "wf-foundation"), Dict{String,Any})
        @test json_updated_workflow["name"] == "Foundation JSON Save"
        @test length(json_updated_workflow["flowVariables"]) == 2
        @test json_updated_workflow["flowVariables"][2]["name"] == "BATCH_WINDOW"
        @test json_updated_workflow["graph"]["revision"] == 3
        @test length(json_updated_workflow["dashboards"][1]["charts"]) == 5
        persisted_workflow = TOML.parse(read(joinpath(store_root, "workflows", "wf-foundation.toml"), String))
        @test persisted_workflow["flow_variables"][2]["default"] == "2026-Q2"
        @test persisted_workflow["workflow"]["graph"]["revision"] == 3
        @test occursin("\"status\":\"updated\"", update_workflow_response!(state, "wf-foundation"; workflow_toml = updated_toml))
        @test occursin("Foundation PoC Updated", get_workflow_response(state, "wf-foundation"))
        @test occursin("\"items\":[", execution_list_response(state))
        @test isfile(joinpath(store_root, "workflows", "wf-parallel.toml"))

        health_response = route_request(state, HTTP.Request("GET", "/health"))
        metrics_route_response = route_request(state, HTTP.Request("GET", "/metrics"))
        list_response = route_request(state, HTTP.Request("GET", "/api/v1/workflows"))
        detail_response = route_request(state, HTTP.Request("GET", "/api/v1/workflows/wf-foundation"))
        create_response = route_request(
            state,
            HTTP.Request("POST", "/api/v1/workflows", ["Content-Type" => "application/json"], JSON3.write(Dict("workflowToml" => read(parallel_path, String)))),
        )
        json_create_response = route_request(
            state,
            HTTP.Request("POST", "/api/v1/workflows", ["Content-Type" => "application/json"], JSON3.write(foundation_workflow_payload)),
        )
        update_response = route_request(
            state,
            HTTP.Request("PUT", "/api/v1/workflows/wf-foundation", ["Content-Type" => "application/json"], JSON3.write(Dict("workflowToml" => updated_toml))),
        )
        execute_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/execute",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "executionMode" => "gpu_preferred",
                        "flowVariables" => Dict("JULIAFLOW_GPU_DEVICE" => "nvidia:0"),
                    ),
                ),
            ),
        )
        data_import_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/local-data/import",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "Foundation Profile",
                        "sourceUri" => import_source_path,
                        "format" => "csv",
                        "targetZone" => "raw",
                    ),
                ),
            ),
        )
        data_import_remote_source_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/local-data/import",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "Remote Profile",
                        "sourceUri" => "https://example.com/profile.csv",
                        "format" => "csv",
                        "targetZone" => "raw",
                    ),
                ),
            ),
        )
        data_import_escape_source_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/local-data/import",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "Escaped Profile",
                        "sourceUri" => foundation_path,
                        "format" => "csv",
                        "targetZone" => "raw",
                    ),
                ),
            ),
        )
        data_import_secret_source_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/local-data/import",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "Secret Profile",
                        "sourceUri" => secret_source_path,
                        "format" => "csv",
                        "targetZone" => "raw",
                    ),
                ),
            ),
        )
        data_import_large_source_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/local-data/import",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "Large Profile",
                        "sourceUri" => large_source_path,
                        "format" => "csv",
                        "targetZone" => "raw",
                    ),
                ),
            ),
        )
        data_import_unsupported_source_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/local-data/import",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "Unsupported Profile",
                        "sourceUri" => unsupported_source_path,
                        "format" => "csv",
                        "targetZone" => "raw",
                    ),
                ),
            ),
        )
        data_import_credential_content_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/local-data/import",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "Credential Content Profile",
                        "sourceUri" => credential_content_path,
                        "format" => "csv",
                        "targetZone" => "raw",
                    ),
                ),
            ),
        )
        data_import_pii_content_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/local-data/import",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "PII Content Profile",
                        "sourceUri" => pii_content_path,
                        "format" => "csv",
                        "targetZone" => "raw",
                    ),
                ),
            ),
        )
        data_science_project_create_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "projectId" => "wellbore-geology",
                        "name" => "Wellbore Geology",
                        "description" => "Local workstation project",
                        "datasets" => [
                            Dict(
                                "datasetId" => "wellbore-train",
                                "name" => "Wellbore train",
                                "role" => "train",
                                "sourceUri" => "local://data/raw/wellbore/train.csv",
                                "localOnly" => true,
                                "rowCount" => 100,
                                "columnCount" => 8,
                            ),
                        ],
                        "schemaContracts" => [
                            Dict(
                                "schemaId" => "schema-wellbore",
                                "datasetId" => "wellbore-train",
                                "updatedAt" => "2026-06-21T00:00:00Z",
                                "columns" => [
                                    Dict("name" => "depth", "inferredType" => "Float64", "logicalType" => "continuous", "role" => "depth", "nullable" => false),
                                    Dict("name" => "lithology", "inferredType" => "String", "logicalType" => "categorical", "role" => "target", "nullable" => false),
                                ],
                            ),
                        ],
                    ),
                ),
            ),
        )
        data_science_project_list_response = route_request(state, HTTP.Request("GET", "/api/v1/data-science-projects"))
        data_science_project_get_response = route_request(state, HTTP.Request("GET", "/api/v1/data-science-projects/wellbore-geology"))
        data_science_project_update_response = route_request(
            state,
            HTTP.Request(
                "PUT",
                "/api/v1/data-science-projects/wellbore-geology",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "name" => "Wellbore Geology Updated",
                        "splitPlans" => [
                            Dict(
                                "splitPlanId" => "split-wellbore-depth",
                                "datasetId" => "wellbore-train",
                                "strategy" => "depth",
                                "locked" => true,
                                "createdAt" => "2026-06-21T00:00:00Z",
                            ),
                        ],
                    ),
                ),
            ),
        )
        data_science_project_missing_name_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("description" => "Missing required name")),
            ),
        )
        data_science_project_duplicate_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("projectId" => "wellbore-geology", "name" => "Duplicate Wellbore Geology")),
            ),
        )
        data_science_project_bad_schema_version_response = route_request(
            state,
            HTTP.Request(
                "PUT",
                "/api/v1/data-science-projects/wellbore-geology",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("schemaVersion" => "2.0")),
            ),
        )
        data_science_project_bad_child_shape_response = route_request(
            state,
            HTTP.Request(
                "PUT",
                "/api/v1/data-science-projects/wellbore-geology",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("splitPlans" => Dict("splitPlanId" => "not-an-array"))),
            ),
        )
        data_science_project_id_mismatch_response = route_request(
            state,
            HTTP.Request(
                "PUT",
                "/api/v1/data-science-projects/wellbore-geology",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("projectId" => "other-project")),
            ),
        )
        data_science_project_remote_source_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "projectId" => "remote-source-project",
                        "name" => "Remote Source Project",
                        "datasets" => [
                            Dict(
                                "datasetId" => "remote-source",
                                "name" => "Remote source",
                                "role" => "train",
                                "sourceUri" => "https://example.com/data.csv",
                                "localOnly" => true,
                            ),
                        ],
                    ),
                ),
            ),
        )
        data_science_project_traversal_source_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "projectId" => "traversal-source-project",
                        "name" => "Traversal Source Project",
                        "datasets" => [
                            Dict(
                                "datasetId" => "traversal-source",
                                "name" => "Traversal source",
                                "role" => "train",
                                "sourceUri" => "local://data/raw/../secrets.csv",
                                "localOnly" => true,
                            ),
                        ],
                    ),
                ),
            ),
        )
        data_science_project_nonlocal_source_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "projectId" => "nonlocal-source-project",
                        "name" => "Nonlocal Source Project",
                        "datasets" => [
                            Dict(
                                "datasetId" => "nonlocal-source",
                                "name" => "Nonlocal source",
                                "role" => "train",
                                "sourceUri" => "local://data/raw/nonlocal.csv",
                                "localOnly" => false,
                            ),
                        ],
                    ),
                ),
            ),
        )
        data_science_project_missing_response = route_request(state, HTTP.Request("GET", "/api/v1/data-science-projects/missing-project"))
        ENV["JULIAFLOW_DATA_ESTATE_ROOT"] = data_estate_root
        data_science_project_foundation_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "projectId" => "foundation-ml-project",
                        "name" => "Foundation ML Project",
                        "datasets" => [
                            Dict(
                                "datasetId" => "foundation-sales-sample",
                                "name" => "Foundation sales sample",
                                "role" => "train",
                                "sourceUri" => "local://data/raw/foundation-sales-sample.csv",
                                "localOnly" => true,
                            ),
                        ],
                        "schemaContracts" => [
                            Dict(
                                "schemaId" => "schema-foundation-sales",
                                "datasetId" => "foundation-sales-sample",
                                "updatedAt" => "2026-06-21T00:00:00Z",
                                "columns" => [
                                    Dict("name" => "amount", "inferredType" => "Float64", "logicalType" => "continuous", "role" => "target", "nullable" => false),
                                    Dict("name" => "region", "inferredType" => "String", "logicalType" => "categorical", "role" => "group", "nullable" => false),
                                ],
                            ),
                        ],
                        "splitPlans" => [
                            Dict(
                                "splitPlanId" => "split-foundation-stratified",
                                "datasetId" => "foundation-sales-sample",
                                "strategy" => "stratified",
                                "trainFraction" => 0.7,
                                "validationFraction" => 0.15,
                                "testFraction" => 0.15,
                                "groupColumn" => "region",
                                "locked" => true,
                                "createdAt" => "2026-06-21T00:00:00Z",
                            ),
                        ],
                    ),
                ),
            ),
        )
        transform_fit_apply_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/transforms/fit-apply",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "splitPlanId" => "split-foundation-stratified",
                        "transformRef" => "local://transforms/foundation/fit-apply.jl",
                        "fitSplit" => "train",
                        "applySplits" => ["validation", "test"],
                    ),
                ),
            ),
        )
        transform_fit_apply_bad_fit_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/transforms/fit-apply",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "splitPlanId" => "split-foundation-stratified",
                        "fitSplit" => "validation",
                        "applySplits" => ["test"],
                    ),
                ),
            ),
        )
        transform_fit_apply_train_apply_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/transforms/fit-apply",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "splitPlanId" => "split-foundation-stratified",
                        "applySplits" => ["train", "validation"],
                    ),
                ),
            ),
        )
        statistical_analysis_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/statistical-analysis/run",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "methods" => ["summary", "pearson_correlation", "spearman_correlation", "ols", "anova", "t_test", "chi_square"],
                        "targetColumn" => "amount",
                        "featureColumns" => ["margin", "region", "segment"],
                    ),
                ),
            ),
        )
        statistical_analysis_bad_method_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/statistical-analysis/run",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("datasetId" => "foundation-sales-sample", "methods" => ["unsupported_method"])),
            ),
        )
        tuning_study_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/tuning/run",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "splitPlanId" => "split-foundation-stratified",
                        "trainingPlanId" => "training-foundation-eval",
                        "targetColumn" => "amount",
                        "taskType" => "regression",
                        "algorithm" => "MLJ.EvoTreesRegressor",
                        "metricNames" => ["rmse", "mae"],
                        "maxTrials" => 3,
                        "finalTestPolicy" => "forbid_final_test",
                    ),
                ),
            ),
        )
        final_evaluation_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/evaluation/run",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "splitPlanId" => "split-foundation-stratified",
                        "trainingPlanId" => "training-foundation-eval",
                        "metricNames" => ["rmse", "mae"],
                        "approvalThreshold" => 0.8,
                        "finalTestPolicy" => "use_final_test",
                    ),
                ),
            ),
        )
        final_evaluation_bad_policy_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/evaluation/run",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "splitPlanId" => "split-foundation-stratified",
                        "trainingPlanId" => "training-foundation-eval",
                        "finalTestPolicy" => "forbid_final_test",
                    ),
                ),
            ),
        )
        tuning_study_final_test_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/tuning/run",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "splitPlanId" => "split-foundation-stratified",
                        "targetColumn" => "amount",
                        "finalTestPolicy" => "use_final_test",
                    ),
                ),
            ),
        )
        final_evaluation_missing_training_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/evaluation/run",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "splitPlanId" => "split-foundation-stratified",
                        "trainingPlanId" => "missing-training-plan",
                        "finalTestPolicy" => "use_final_test",
                    ),
                ),
            ),
        )
        prediction_export_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/predictions/export",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "outputContractRef" => "contract://outputs/foundation-predictions",
                        "format" => "csv",
                        "rowCount" => 25,
                        "outputColumns" => [
                            "prediction_id",
                            "dataset_id",
                            "evaluation_report_id",
                            "output_contract_ref",
                            "prediction",
                        ],
                    ),
                ),
            ),
        )
        drift_report_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/drift/run",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "baselineId" => "baseline-foundation-drift",
                        "metricNames" => ["psi", "ks"],
                        "threshold" => 0.2,
                    ),
                ),
            ),
        )
        drift_report_bad_threshold_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/drift/run",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "metricNames" => ["psi"],
                        "threshold" => 2.0,
                    ),
                ),
            ),
        )
        prediction_export_bad_format_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/predictions/export",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "outputContractRef" => "contract://outputs/foundation-predictions",
                        "format" => "xlsx",
                    ),
                ),
            ),
        )
        prediction_export_missing_contract_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/predictions/export",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("datasetId" => "foundation-sales-sample")),
            ),
        )
        prediction_export_bad_columns_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/predictions/export",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "outputContractRef" => "contract://outputs/foundation-predictions",
                        "outputColumns" => ["prediction_id", "unknown_column"],
                    ),
                ),
            ),
        )
        prediction_export_mapped_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/predictions/export",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "outputContractRef" => "contract://outputs/scored-foundation-submission",
                        "outputContract" => Dict(
                            "contractId" => "contract://outputs/scored-foundation-submission",
                            "columns" => [
                                Dict("name" => "row_id", "sourceColumn" => "prediction_id", "required" => true),
                                Dict("name" => "score", "sourceColumn" => "prediction", "type" => "float64", "required" => true),
                            ],
                        ),
                        "outputColumns" => ["row_id", "score"],
                        "outputMappings" => [
                            Dict("outputColumn" => "score", "sourceColumn" => "prediction"),
                        ],
                        "format" => "csv",
                        "rowCount" => 3,
                    ),
                ),
            ),
        )
        prediction_export_bad_mapping_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/predictions/export",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "datasetId" => "foundation-sales-sample",
                        "outputContractRef" => "contract://outputs/bad-foundation-submission",
                        "outputContract" => Dict(
                            "contractId" => "contract://outputs/bad-foundation-submission",
                            "columns" => [
                                Dict("name" => "row_id", "sourceColumn" => "prediction_id", "required" => true),
                                Dict("name" => "score", "sourceColumn" => "not_a_scoring_column", "required" => true),
                            ],
                        ),
                        "outputColumns" => ["row_id", "score"],
                    ),
                ),
            ),
        )
        transform_run_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/transforms/run",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("executionMode" => "cpu_only")),
            ),
        )
        transform_history_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/workflows/wf-foundation/transforms/history"),
        )
        model_register_without_validation_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/models/register",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("modelId" => "unvalidated-foundation-model")),
            ),
        )
        deploy_package_without_validation_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/deploy/package",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("modelId" => "unvalidated-foundation-model")),
            ),
        )
        ml_experiment_run_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/ml/experiments/run",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "executionMode" => "cpu_only",
                        "projectId" => "foundation-ml-project",
                        "datasetId" => "foundation-sales-sample",
                        "splitPlanId" => "split-foundation-stratified",
                        "finalTestPolicy" => "forbid_final_test",
                        "target" => "amount",
                        "algorithm" => "deterministic_linear_baseline",
                    ),
                ),
            ),
        )
        ml_experiment_missing_split_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/ml/experiments/run",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "executionMode" => "cpu_only",
                        "projectId" => "foundation-ml-project",
                        "datasetId" => "foundation-sales-sample",
                        "splitPlanId" => "missing-split",
                        "target" => "amount",
                    ),
                ),
            ),
        )
        ml_experiment_final_test_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/ml/experiments/run",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "executionMode" => "cpu_only",
                        "projectId" => "foundation-ml-project",
                        "datasetId" => "foundation-sales-sample",
                        "splitPlanId" => "split-foundation-stratified",
                        "finalTestPolicy" => "use_final_test",
                        "target" => "amount",
                    ),
                ),
            ),
        )
        ml_experiment_history_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/workflows/wf-foundation/ml/experiments"),
        )
        model_register_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/models/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "modelId" => "foundation-linear-baseline",
                        "status" => "registered",
                        "tags" => ["local", "checkpointed", "reviewed"],
                        "owner" => "local-user",
                    ),
                ),
            ),
        )
        model_registry_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/workflows/wf-foundation/models"),
        )
        model_lifecycle_after_register_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/data-science-projects/foundation-ml-project"),
        )
        model_lifecycle_approval_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/models/lifecycle",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "modelId" => "foundation-linear-baseline",
                        "action" => "approve_model",
                        "reason" => "final evaluation evidence accepted",
                    ),
                ),
            ),
        )
        deploy_package_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/deploy/package",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "modelId" => "foundation-linear-baseline",
                        "endpointPath" => "/v1/predict",
                        "host" => "127.0.0.1",
                        "port" => 8000,
                        "notes" => "local deploy package proof",
                    ),
                ),
            ),
        )
        deploy_package_history_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/workflows/wf-foundation/deploy/packages"),
        )
        model_lifecycle_after_deploy_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/data-science-projects/foundation-ml-project"),
        )
        model_lifecycle_rolled_back_too_early_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/models/lifecycle",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "modelId" => "foundation-linear-baseline",
                        "action" => "mark_rolled_back",
                        "rollbackModelId" => "foundation-linear-baseline-v0",
                        "reason" => "rollback requires an explicit ready state first",
                    ),
                ),
            ),
        )
        model_lifecycle_rollback_ready_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/models/lifecycle",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "modelId" => "foundation-linear-baseline",
                        "action" => "mark_rollback_ready",
                        "rollbackModelId" => "foundation-linear-baseline-v0",
                        "reason" => "local drift review approved fallback model",
                    ),
                ),
            ),
        )
        model_lifecycle_rolled_back_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/models/lifecycle",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "modelId" => "foundation-linear-baseline",
                        "action" => "mark_rolled_back",
                        "reason" => "operator executed local rollback",
                    ),
                ),
            ),
        )
        deploy_package_history_after_rollback_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/workflows/wf-foundation/deploy/packages"),
        )
        model_lifecycle_retraining_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/models/lifecycle",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "modelId" => "foundation-linear-baseline",
                        "action" => "request_retraining",
                        "reason" => "post-rollback retraining requested",
                    ),
                ),
            ),
        )
        model_lifecycle_archive_too_early_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/models/lifecycle",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "modelId" => "foundation-linear-baseline",
                        "action" => "archive_model",
                        "reason" => "archive requires deprecation first",
                    ),
                ),
            ),
        )
        model_lifecycle_deprecated_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/models/lifecycle",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "modelId" => "foundation-linear-baseline",
                        "action" => "deprecate_model",
                        "reason" => "superseded by retraining review",
                    ),
                ),
            ),
        )
        model_lifecycle_archived_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/data-science-projects/foundation-ml-project/models/lifecycle",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "modelId" => "foundation-linear-baseline",
                        "action" => "archive_model",
                        "reason" => "local archive after deprecation",
                    ),
                ),
            ),
        )
        hub_list_response = route_request(state, HTTP.Request("GET", "/api/v1/hub/extensions"))
        hub_install_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/juliaflow-ops-preview/install",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("action" => "enable")),
            ),
        )
        hub_install_incompatible_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/juliaflow-ops-preview/install",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("action" => "install")),
            ),
        )
        hub_register_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-labs-pack",
                            "name" => "JuliaFlow Labs Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Labs pack for compatible install tests.",
                            "packageRef" => "hub://labs/pack",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/labs-pack",
                            "artifactHashes" => Dict("package" => "sha256:e97cfb2b9c49c0f5770cfed1060d2bd22a4b80d7ba0d44f36951438cb5ef54ce"),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["mirror://offline/labs-pack", "private://workspace/labs-pack"]
                        ),
                    ),
                ),
            ),
        )
        hub_bad_signature_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-bad-signature",
                            "name" => "Bad Signature Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Invalid signature format coverage.",
                            "packageRef" => "hub://labs/bad-signature",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "signed-partner-juliaflow-labs",
                            "releaseNotesRef" => "https://example.test/bad-signature",
                            "artifactHashes" => Dict("package" => "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["mirror://offline/labs-pack", "private://workspace/labs-pack"]
                        ),
                    ),
                ),
            ),
        )
        hub_bad_release_notes_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-bad-release-notes",
                            "name" => "Bad Release Notes Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Invalid release notes URL coverage.",
                            "packageRef" => "hub://labs/bad-release-notes",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "http://example.test/bad-release-notes",
                            "artifactHashes" => Dict("package" => "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["mirror://offline/labs-pack", "private://workspace/labs-pack"]
                        ),
                    ),
                ),
            ),
        )
        hub_bad_identity_suffix_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-bad-partner-identity",
                            "name" => "Bad Partner Identity Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Invalid partner identity suffix coverage.",
                            "packageRef" => "hub://labs/bad-partner-identity",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/bad-partner-identity",
                            "artifactHashes" => Dict("package" => "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["mirror://offline/labs-pack", "private://workspace/labs-pack"]
                        ),
                    ),
                ),
            ),
        )
        hub_bad_signature_identity_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-bad-signature-identity",
                            "name" => "Bad Signature Identity Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Signature does not bind to publisher identity.",
                            "packageRef" => "hub://labs/bad-signature-identity",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:other-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/bad-signature-identity",
                            "artifactHashes" => Dict("package" => "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["mirror://offline/labs-pack", "private://workspace/labs-pack"]
                        ),
                    ),
                ),
            ),
        )
        hub_bad_package_ref_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-bad-package-ref",
                            "name" => "Bad Package Ref Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Partner package ref scheme policy coverage.",
                            "packageRef" => "extensions/bad-package-ref",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/bad-package-ref",
                            "artifactHashes" => Dict("package" => "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["mirror://offline/labs-pack", "private://workspace/labs-pack"]
                        ),
                    ),
                ),
            ),
        )
        hub_official_missing_hash_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-official-missing-hash",
                            "name" => "Official Missing Hash Pack",
                            "version" => "0.2.0",
                            "publisher" => "official",
                            "summary" => "Official missing hash coverage.",
                            "packageRef" => "extensions/official-missing-hash",
                            "tags" => ["official"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "official:juliaflow",
                            "compatibilitySandboxCommand" => "julia --project=. extensions/base/test/runtests.jl",
                            "mirrorRefs" => ["mirror://official/missing-hash"]
                        ),
                    ),
                ),
            ),
        )
        hub_official_bad_hash_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-official-bad-hash",
                            "name" => "Official Bad Hash Pack",
                            "version" => "0.2.0",
                            "publisher" => "official",
                            "summary" => "Official bad hash coverage.",
                            "packageRef" => "extensions/official-bad-hash",
                            "tags" => ["official"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "official:juliaflow",
                            "artifactHashes" => Dict("package" => "sha256:bad"),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/base/test/runtests.jl",
                            "mirrorRefs" => ["mirror://official/bad-hash"]
                        ),
                    ),
                ),
            ),
        )
        hub_malformed_hash_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-malformed-hash",
                            "name" => "Malformed Hash Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Malformed artifact hash shape coverage.",
                            "packageRef" => "hub://labs/malformed-hash",
                            "artifactHashes" => "sha256:not-an-object",
                            "mirrorRefs" => ["mirror://offline/labs-pack"]
                        ),
                    ),
                ),
            ),
        )
        hub_official_file_mirror_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-official-file-mirror",
                            "name" => "Official File Mirror Pack",
                            "version" => "0.2.0",
                            "publisher" => "official",
                            "summary" => "Official file mirror rejection coverage.",
                            "packageRef" => "extensions/official-file-mirror",
                            "tags" => ["official"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "official:juliaflow",
                            "artifactHashes" => Dict("package" => "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/base/test/runtests.jl",
                            "mirrorRefs" => ["file:///tmp/juliaflow/official"]
                        ),
                    ),
                ),
            ),
        )
        hub_bad_artifact_hash_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-bad-artifact-hash",
                            "name" => "Bad Artifact Hash Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Invalid artifact hash policy coverage.",
                            "packageRef" => "hub://labs/bad-artifact-hash",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/bad-artifact-hash",
                            "artifactHashes" => Dict("package" => "md5:bad"),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["mirror://offline/labs-pack"]
                        ),
                    ),
                ),
            ),
        )
        hub_missing_sandbox_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-missing-sandbox",
                            "name" => "Missing Sandbox Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Missing sandbox command coverage.",
                            "packageRef" => "hub://labs/missing-sandbox",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/missing-sandbox",
                            "artifactHashes" => Dict("package" => "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
                            "mirrorRefs" => ["mirror://offline/labs-pack"]
                        ),
                    ),
                ),
            ),
        )
        hub_hash_mismatch_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-hash-mismatch",
                            "name" => "Hash Mismatch Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Install-time artifact hash mismatch coverage.",
                            "packageRef" => "hub://labs/hash-mismatch",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/hash-mismatch",
                            "artifactHashes" => Dict("package" => "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["mirror://offline/labs-pack"]
                        ),
                    ),
                ),
            ),
        )
        hub_sandbox_unsafe_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-unsafe-sandbox",
                            "name" => "Unsafe Sandbox Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Install-time sandbox allowlist coverage.",
                            "packageRef" => "hub://labs/unsafe-sandbox",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/unsafe-sandbox",
                            "artifactHashes" => Dict("package" => "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
                            "compatibilitySandboxCommand" => "python -m unsafe",
                            "mirrorRefs" => ["mirror://offline/labs-pack"]
                        ),
                    ),
                ),
            ),
        )
        hub_bad_mirror_ref_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-bad-mirror-ref",
                            "name" => "Bad Mirror Ref Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Invalid offline mirror reference coverage.",
                            "packageRef" => "hub://labs/bad-mirror-ref",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/bad-mirror-ref",
                            "artifactHashes" => Dict("package" => "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["https://example.test/mirror"]
                        ),
                    ),
                ),
            ),
        )
        hub_partner_file_mirror_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-file-mirror-ref",
                            "name" => "File Mirror Ref Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Partner file mirror rejection coverage.",
                            "packageRef" => "hub://labs/file-mirror-ref",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/file-mirror-ref",
                            "artifactHashes" => Dict("package" => "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["file:///tmp/juliaflow/partner"]
                        ),
                    ),
                ),
            ),
        )
        hub_enable_bad_artifact_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/juliaflow-bad-artifact-hash/install",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("action" => "enable")),
            ),
        )
        hub_enable_missing_sandbox_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/juliaflow-missing-sandbox/install",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("action" => "enable")),
            ),
        )
        hub_enable_hash_mismatch_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/juliaflow-hash-mismatch/install",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("action" => "enable")),
            ),
        )
        hub_enable_unsafe_sandbox_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/juliaflow-unsafe-sandbox/install",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("action" => "enable")),
            ),
        )
        hub_enable_bad_mirror_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/juliaflow-bad-mirror-ref/install",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("action" => "enable")),
            ),
        )
        hub_artifact_fixture_path = joinpath(store_root, "hub-artifacts", "labs-package.txt")
        mkpath(dirname(hub_artifact_fixture_path))
        write(hub_artifact_fixture_path, "downloaded hub package bytes\n")
        hub_artifact_hash = "sha256:" * bytes2hex(sha256(read(hub_artifact_fixture_path)))
        hub_artifact_store_path = joinpath(store_root, "hub-artifact-store.json")
        hub_mirror_registry_path = joinpath(store_root, "hub-mirror-registry.json")
        write(
            hub_artifact_store_path,
            JSON3.write(Dict("hub://labs/download-proof" => Dict("package" => hub_artifact_fixture_path))),
        )
        write(
            hub_mirror_registry_path,
            JSON3.write(Dict("mirror://offline/download-proof" => true, "private://workspace/download-proof" => true)),
        )
        hub_download_register_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-download-proof",
                            "name" => "Download Proof Pack",
                            "version" => "0.3.0",
                            "publisher" => "partner",
                            "summary" => "Downloaded artifact and private mirror proof.",
                            "packageRef" => "hub://labs/download-proof",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.3.0",
                            "releaseNotesRef" => "https://example.test/download-proof",
                            "artifactHashes" => Dict("package" => hub_artifact_hash),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["mirror://offline/download-proof", "private://workspace/download-proof"],
                        ),
                    ),
                ),
            ),
        )
        hub_download_enable_response = withenv(
            "JULIAFLOW_HUB_SANDBOX_EXECUTE" => "1",
            "JULIAFLOW_HUB_ARTIFACT_STORE" => hub_artifact_store_path,
            "JULIAFLOW_HUB_MIRROR_REGISTRY" => hub_mirror_registry_path,
        ) do
            route_request(
                state,
                HTTP.Request(
                    "POST",
                    "/api/v1/hub/extensions/juliaflow-download-proof/install",
                    ["Content-Type" => "application/json"],
                    JSON3.write(Dict("action" => "enable")),
                ),
            )
        end
        hub_missing_artifact_register_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-missing-artifact-file",
                            "name" => "Missing Artifact File Pack",
                            "version" => "0.3.0",
                            "publisher" => "partner",
                            "summary" => "Missing artifact store proof.",
                            "packageRef" => "hub://labs/missing-artifact-file",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.3.0",
                            "releaseNotesRef" => "https://example.test/missing-artifact-file",
                            "artifactHashes" => Dict("package" => hub_artifact_hash),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["mirror://offline/download-proof"],
                        ),
                    ),
                ),
            ),
        )
        hub_missing_artifact_enable_response = withenv(
            "JULIAFLOW_HUB_ARTIFACT_STORE" => hub_artifact_store_path,
            "JULIAFLOW_HUB_MIRROR_REGISTRY" => hub_mirror_registry_path,
        ) do
            route_request(
                state,
                HTTP.Request(
                    "POST",
                    "/api/v1/hub/extensions/juliaflow-missing-artifact-file/install",
                    ["Content-Type" => "application/json"],
                    JSON3.write(Dict("action" => "enable")),
                ),
            )
        end
        hub_missing_mirror_register_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-missing-mirror",
                            "name" => "Missing Mirror Pack",
                            "version" => "0.3.0",
                            "publisher" => "partner",
                            "summary" => "Missing mirror registry proof.",
                            "packageRef" => "hub://labs/download-proof",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.3.0",
                            "releaseNotesRef" => "https://example.test/missing-mirror",
                            "artifactHashes" => Dict("package" => hub_artifact_hash),
                            "compatibilitySandboxCommand" => "julia --project=. extensions/labs/test/runtests.jl",
                            "mirrorRefs" => ["mirror://offline/missing-mirror"],
                        ),
                    ),
                ),
            ),
        )
        hub_missing_mirror_enable_response = withenv(
            "JULIAFLOW_HUB_ARTIFACT_STORE" => hub_artifact_store_path,
            "JULIAFLOW_HUB_MIRROR_REGISTRY" => hub_mirror_registry_path,
        ) do
            route_request(
                state,
                HTTP.Request(
                    "POST",
                    "/api/v1/hub/extensions/juliaflow-missing-mirror/install",
                    ["Content-Type" => "application/json"],
                    JSON3.write(Dict("action" => "enable")),
                ),
            )
        end
        dashboard_publish_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/dashboards/dashboard-foundation/publish",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("visibility" => "public")),
            ),
        )
        dashboard_list_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/workflows/wf-foundation/dashboards"),
        )
        dashboard_publish_payload = JSON3.read(String(dashboard_publish_response.body), Dict{String,Any})
        dashboard_share_token = String(dashboard_publish_payload["dashboard"]["shareToken"])
        dashboard_get_unauthorized_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation"),
        )
        dashboard_get_invalid_token_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation?shareToken=wrong-token"),
        )
        dashboard_get_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation?shareToken=$(dashboard_share_token)"),
        )
        dashboard_chart_data_invalid_token_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation/charts/chart-line/data?shareToken=wrong-token"),
        )
        dashboard_chart_data_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation/charts/chart-line/data?shareToken=$(dashboard_share_token)"),
        )
        dashboard_chart_export_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation/charts/chart-line/export.csv?shareToken=$(dashboard_share_token)"),
        )
        dashboard_publish_workspace_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/dashboards/dashboard-foundation/publish",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("visibility" => "workspace")),
            ),
        )
        dashboard_get_workspace_response = withenv("JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN" => "workspace-secret") do
            route_request(
                state,
                HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation"),
            )
        end
        dashboard_get_workspace_invalid_token_response = withenv("JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN" => "workspace-secret") do
            route_request(
                state,
                HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation?workspaceToken=wrong-token"),
            )
        end
        dashboard_get_workspace_authorized_response = withenv("JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN" => "workspace-secret") do
            route_request(
                state,
                HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation?workspaceToken=workspace-secret"),
            )
        end
        dashboard_get_workspace_bearer_invalid_response = withenv("JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN" => "workspace-secret") do
            route_request(
                state,
                HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation", ["Authorization" => "Bearer wrong-secret"]),
            )
        end
        dashboard_get_workspace_bearer_authorized_response = withenv("JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN" => "workspace-secret") do
            route_request(
                state,
                HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation", ["Authorization" => "Bearer workspace-secret"]),
            )
        end
        auth_missing_workflow_list_response = withenv("JULIAFLOW_DEV_AUTH_TOKEN" => "dev-secret") do
            route_request(state, HTTP.Request("GET", "/api/v1/workflows"))
        end
        auth_viewer_workflow_list_response = withenv("JULIAFLOW_DEV_AUTH_TOKEN" => "dev-secret") do
            route_request(
                state,
                HTTP.Request(
                    "GET",
                    "/api/v1/workflows",
                    ["Authorization" => "Bearer dev-secret", "X-JuliaFlow-Workspace-Role" => "viewer"],
                ),
            )
        end
        auth_viewer_execute_response = withenv("JULIAFLOW_DEV_AUTH_TOKEN" => "dev-secret") do
            route_request(
                state,
                HTTP.Request(
                    "POST",
                    "/api/v1/workflows/wf-foundation/execute",
                    ["Authorization" => "Bearer dev-secret", "X-JuliaFlow-Workspace-Role" => "viewer", "Content-Type" => "application/json"],
                    JSON3.write(Dict()),
                ),
            )
        end
        auth_editor_execute_response = withenv("JULIAFLOW_DEV_AUTH_TOKEN" => "dev-secret") do
            route_request(
                state,
                HTTP.Request(
                    "POST",
                    "/api/v1/workflows/wf-foundation/execute",
                    ["Authorization" => "Bearer dev-secret", "X-JuliaFlow-Workspace-Role" => "editor", "Content-Type" => "application/json"],
                    JSON3.write(Dict("executionMode" => "batch")),
                ),
            )
        end
        auth_editor_hub_install_response = withenv("JULIAFLOW_DEV_AUTH_TOKEN" => "dev-secret") do
            route_request(
                state,
                HTTP.Request(
                    "POST",
                    "/api/v1/hub/extensions/juliaflow-base/install",
                    ["Authorization" => "Bearer dev-secret", "X-JuliaFlow-Workspace-Role" => "editor", "Content-Type" => "application/json"],
                    JSON3.write(Dict("action" => "install")),
                ),
            )
        end
        hub_enable_registered_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/juliaflow-labs-pack/install",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("action" => "enable")),
            ),
        )
        execution_list = route_request(state, HTTP.Request("GET", "/api/v1/executions"))
        checkpoint_post = route_request(
            state,
            HTTP.Request("POST", "/api/v1/checkpoints", ["Content-Type" => "application/json"], JSON3.write(Dict("tag" => "cp/02-alpha-core", "summary" => "Alpha core started"))),
        )
        import_post = route_request(
            state,
            HTTP.Request("POST", "/api/v1/workflows/import", ["Content-Type" => "application/json"], JSON3.write(Dict("sourcePath" => parallel_path))),
        )
        reproducibility_export_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/reproducibility-bundles",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict(
                    "workflowId" => "wf-foundation",
                    "checkpointTag" => "cp/02-alpha-core",
                    "dashboardId" => "dashboard-foundation",
                    "notes" => "local academic reproducibility proof",
                )),
            ),
        )
        reproducibility_export_payload = JSON3.read(String(reproducibility_export_response.body), Dict{String,Any})
        visualize_checkpoint_export_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/dashboards/dashboard-foundation/checkpoint-export",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict(
                    "checkpointTag" => "cp/visualize-export",
                    "summary" => "Visualize dashboard export checkpoint",
                    "visibility" => "workspace",
                    "notes" => "local visualize checkpoint export proof",
                )),
            ),
        )
        visualize_checkpoint_export_payload = JSON3.read(String(visualize_checkpoint_export_response.body), Dict{String,Any})
        imported_reproducibility_store = mktempdir()
        imported_reproducibility_state = load_state(imported_reproducibility_store)
        reproducibility_import_response = route_request(
            imported_reproducibility_state,
            HTTP.Request(
                "POST",
                "/api/v1/reproducibility-bundles/import",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("bundle" => reproducibility_export_payload["bundle"])),
            ),
        )
        tampered_reproducibility_bundle = Dict{String,Any}(String(key) => value for (key, value) in pairs(reproducibility_export_payload["bundle"]))
        tampered_reproducibility_bundle["notes"] = "tampered notes"
        reproducibility_import_tampered_response = route_request(
            load_state(mktempdir()),
            HTTP.Request(
                "POST",
                "/api/v1/reproducibility-bundles/import",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("bundle" => tampered_reproducibility_bundle)),
            ),
        )
        local_backup_export_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/local-backups",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("notes" => "local backup restore proof", "includeExecutions" => true)),
            ),
        )
        local_backup_export_payload = JSON3.read(String(local_backup_export_response.body), Dict{String,Any})
        imported_backup_home = mktempdir()
        imported_backup_state = withenv(
            "JULIAFLOW_HOME" => imported_backup_home,
            "JULIAFLOW_DATA_ESTATE_ROOT" => joinpath(imported_backup_home, "data"),
            "JULIAFLOW_METADATA_ROOT" => joinpath(imported_backup_home, "metadata"),
        ) do
            load_state(joinpath(imported_backup_home, "metadata", "gateway-store"))
        end
        local_backup_import_response = withenv(
            "JULIAFLOW_HOME" => imported_backup_home,
            "JULIAFLOW_DATA_ESTATE_ROOT" => joinpath(imported_backup_home, "data"),
            "JULIAFLOW_METADATA_ROOT" => joinpath(imported_backup_home, "metadata"),
        ) do
            route_request(
                imported_backup_state,
                HTTP.Request(
                    "POST",
                    "/api/v1/local-backups/import",
                    ["Content-Type" => "application/json"],
                    JSON3.write(Dict("backup" => local_backup_export_payload["backup"])),
                ),
            )
        end
        tampered_local_backup = Dict{String,Any}(String(key) => value for (key, value) in pairs(local_backup_export_payload["backup"]))
        tampered_local_backup["notes"] = "tampered local backup"
        local_backup_import_tampered_response = route_request(
            load_state(mktempdir()),
            HTTP.Request(
                "POST",
                "/api/v1/local-backups/import",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("backup" => tampered_local_backup)),
            ),
        )
        execute_payload = JSON3.read(String(execute_response.body), Dict{String,Any})
        execute_payload_id = get(execute_payload, "executionId", "missing-execution-id")
        gpu_execute_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-gpu-alpha/execute",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("executionMode" => "gpu_required")),
            ),
        )
        gpu_execute_payload = JSON3.read(String(gpu_execute_response.body), Dict{String,Any})
        preflight = route_request(
            state,
            HTTP.Request(
                "OPTIONS",
                "/api/v1/executions/$(execute_payload_id)/status",
                [
                    "Origin" => "http://127.0.0.1:5173",
                    "Access-Control-Request-Method" => "POST",
                ],
            ),
        )
        missing_route = route_request(state, HTTP.Request("GET", "/missing"))
        traced_health_route = route_request(
            state,
            HTTP.Request(
                "GET",
                "/health",
                ["traceparent" => "00-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-bbbbbbbbbbbbbbbb-01"],
            ),
        )

        @test health_response.status == 200
        @test occursin("workflowCount", String(health_response.body))
        @test occursin("\"eventBackboneMode\":", String(health_response.body))
        @test occursin("\"streamWorkerMode\":", String(health_response.body))
        @test occursin("\"eventLogSize\":", String(health_response.body))
        @test occursin("\"latestEventSequence\":", String(health_response.body))
        @test occursin("\"gatewayConsumerCursor\":", String(health_response.body))
        @test occursin("\"gatewayConsumerLag\":", String(health_response.body))
        @test occursin("\"eventConsumerCatchupPercent\":", String(health_response.body))
        @test occursin("\"activeStreamExecutions\":", String(health_response.body))
        @test occursin("\"queuedGpuExecutions\":", String(health_response.body))
        @test occursin("\"queuedStreamExecutions\":", String(health_response.body))
        @test occursin("\"activeGpuExecutions\":", String(health_response.body))
        @test occursin("\"gpuWorkerOwnedExecutions\":", String(health_response.body))
        @test occursin("\"queuedExecutionsTotal\":", String(health_response.body))
        @test occursin("\"runningExecutionsTotal\":", String(health_response.body))
        @test occursin("\"localProfile\":\"single-user\"", String(health_response.body))
        @test occursin("\"metadataMode\":\"single-user\"", String(health_response.body))
        @test occursin("\"metadataBackend\":\"file\"", String(health_response.body))
        @test occursin("\"metadataReady\":true", String(health_response.body))
        @test occursin("\"metadataConcurrencyStatus\":\"single_writer\"", String(health_response.body))
        @test occursin("\"metadataCapabilities\":", String(health_response.body))
        @test occursin("\"dataEstateZones\":", String(health_response.body))
        @test occursin("\"dataEstateReady\":", String(health_response.body))
        @test occursin("\"freeDiskStatus\":", String(health_response.body))
        @test occursin("\"localServiceUrls\":", String(health_response.body))
        @test occursin("\"postgresProfileStatus\":", String(health_response.body))
        @test occursin("\"minioProfileStatus\":", String(health_response.body))
        @test occursin("\"cloudCredentialsRequired\":false", String(health_response.body))
        @test occursin("\"cpuThreadCount\":", String(health_response.body))
        @test occursin("\"hardwareProfileStatus\":", String(health_response.body))
        @test occursin("\"hardwareSelectedBackend\":", String(health_response.body))
        @test occursin("\"cpuSchedulerPolicy\":", String(health_response.body))
        @test occursin("\"cpuWorkerConcurrency\":", String(health_response.body))
        @test occursin("\"cpuMemoryLimitBytes\":", String(health_response.body))
        @test occursin("\"gpuReadinessStatus\":", String(health_response.body))
        @test occursin("\"gpuCudaStatus\":", String(health_response.body))
        @test occursin("\"gpuDeviceSummaries\":", String(health_response.body))
        @test occursin("\"hubCacheRoot\":", String(health_response.body))
        @test occursin("\"hubArtifactStorePath\":", String(health_response.body))
        @test occursin("\"hubMirrorRegistryPath\":", String(health_response.body))
        @test occursin("\"hubArtifactCacheRoot\":", String(health_response.body))
        @test occursin("\"hubCacheStatus\":", String(health_response.body))
        @test occursin("\"hubOfflineInstallReady\":", String(health_response.body))
        @test occursin("\"localBackupRestoreReady\":", String(health_response.body))
        @test occursin("\"hubBundledExtensionCount\":", String(health_response.body))
        @test occursin("\"hubInstalledLocalExtensionCount\":", String(health_response.body))
        @test occursin("\"otelTraceSeamEnabled\":true", String(health_response.body))
        @test metrics_route_response.status == 200
        @test occursin("juliaflow_workflows_total", String(metrics_route_response.body))
        @test occursin("juliaflow_gateway_consumer_lag", String(metrics_route_response.body))
        @test occursin("juliaflow_observability_spans_total", String(metrics_route_response.body))
        @test traced_health_route.status == 200
        @test state.observability_span_count >= 1
        @test state.observability_spans[end]["trace_id"] == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        @test state.observability_spans[end]["name"] == "HTTP GET /health"
        @test list_response.status == 200
        @test occursin("wf-foundation", String(list_response.body))
        @test detail_response.status == 200
        @test occursin("\"workflowId\":\"wf-foundation\"", String(detail_response.body))
        @test hub_list_response.status == 200
        @test occursin("\"extensionId\":\"juliaflow-base\"", String(hub_list_response.body))
        @test hub_install_response.status == 409
        @test occursin("Extension not validated for current checkpoint", String(hub_install_response.body))
        @test hub_install_incompatible_response.status == 409
        @test occursin("Extension not validated for current checkpoint", String(hub_install_incompatible_response.body))
        @test hub_register_response.status == 201
        @test occursin("\"extensionId\":\"juliaflow-labs-pack\"", String(hub_register_response.body))
        @test occursin("\"compatible\":true", String(hub_register_response.body))
        @test occursin("\"artifactHashes\":{\"package\":\"sha256:e97cfb2b9c49c0f5770cfed1060d2bd22a4b80d7ba0d44f36951438cb5ef54ce\"}", String(hub_register_response.body))
        @test occursin("\"compatibilitySandboxCommand\":\"julia --project=. extensions/labs/test/runtests.jl\"", String(hub_register_response.body))
        @test occursin("\"mirrorRefs\":[\"mirror://offline/labs-pack\",\"private://workspace/labs-pack\"]", String(hub_register_response.body))
        @test hub_bad_signature_response.status == 201
        @test occursin("signature must use sig: prefix", String(hub_bad_signature_response.body))
        @test hub_bad_release_notes_response.status == 201
        @test occursin("release notes reference must be https URL", String(hub_bad_release_notes_response.body))
        @test hub_bad_identity_suffix_response.status == 201
        @test occursin("publisher identity suffix must not be empty", String(hub_bad_identity_suffix_response.body))
        @test hub_bad_signature_identity_response.status == 201
        @test occursin("signature must include publisher identity suffix", String(hub_bad_signature_identity_response.body))
        @test hub_bad_package_ref_response.status == 201
        @test occursin("package reference must use hub:// scheme", String(hub_bad_package_ref_response.body))
        @test hub_official_missing_hash_response.status == 400
        @test occursin("manifest missing artifactHashes", String(hub_official_missing_hash_response.body))
        @test hub_official_bad_hash_response.status == 201
        @test occursin("Artifact hash for package must use sha256:<64 hex digest>", String(hub_official_bad_hash_response.body))
        @test hub_malformed_hash_response.status == 400
        @test occursin("manifest artifactHashes must be object", String(hub_malformed_hash_response.body))
        @test hub_official_file_mirror_response.status == 201
        @test occursin("Mirror reference must use mirror:// or private:// scheme", String(hub_official_file_mirror_response.body))
        @test hub_bad_artifact_hash_response.status == 201
        @test occursin("Artifact hash for package must use sha256:<64 hex digest>", String(hub_bad_artifact_hash_response.body))
        @test hub_missing_sandbox_response.status == 201
        @test occursin("Extension must provide compatibility sandbox command", String(hub_missing_sandbox_response.body))
        @test hub_hash_mismatch_response.status == 201
        @test occursin("\"extensionId\":\"juliaflow-hash-mismatch\"", String(hub_hash_mismatch_response.body))
        @test hub_sandbox_unsafe_response.status == 201
        @test occursin("\"extensionId\":\"juliaflow-unsafe-sandbox\"", String(hub_sandbox_unsafe_response.body))
        @test hub_bad_mirror_ref_response.status == 201
        @test occursin("Mirror reference must use mirror:// or private:// scheme", String(hub_bad_mirror_ref_response.body))
        @test hub_partner_file_mirror_response.status == 201
        @test occursin("Mirror reference must use mirror:// or private:// scheme", String(hub_partner_file_mirror_response.body))
        @test hub_enable_bad_artifact_response.status == 409
        @test occursin("Artifact hash for package must use sha256:<64 hex digest>", String(hub_enable_bad_artifact_response.body))
        @test hub_enable_missing_sandbox_response.status == 409
        @test occursin("Extension must provide compatibility sandbox command", String(hub_enable_missing_sandbox_response.body))
        @test hub_enable_hash_mismatch_response.status == 409
        @test occursin("Artifact hash mismatch for package", String(hub_enable_hash_mismatch_response.body))
        @test hub_enable_unsafe_sandbox_response.status == 409
        @test occursin("Compatibility sandbox command must be bounded Julia extension test", String(hub_enable_unsafe_sandbox_response.body))
        @test hub_enable_bad_mirror_response.status == 409
        @test occursin("Mirror reference must use mirror:// or private:// scheme", String(hub_enable_bad_mirror_response.body))
        @test hub_download_register_response.status == 201
        @test hub_download_enable_response.status == 200
        @test occursin("Isolated compatibility sandbox command executed successfully", String(hub_download_enable_response.body))
        @test occursin("Downloaded artifact hashes verified from isolated artifact store", String(hub_download_enable_response.body))
        @test occursin("Offline/private mirror references resolved through local registry", String(hub_download_enable_response.body))
        @test hub_missing_artifact_register_response.status == 201
        @test hub_missing_artifact_enable_response.status == 409
        @test occursin("Artifact package missing from artifact store", String(hub_missing_artifact_enable_response.body))
        @test hub_missing_mirror_register_response.status == 201
        @test hub_missing_mirror_enable_response.status == 409
        @test occursin("Mirror reference not found in offline/private registry", String(hub_missing_mirror_enable_response.body))
        @test state.hub_extensions["juliaflow-bad-artifact-hash"].install_state != "enabled"
        @test state.hub_extensions["juliaflow-missing-sandbox"].install_state != "enabled"
        @test state.hub_extensions["juliaflow-hash-mismatch"].verification["artifacts"]["status"] == "failed"
        @test state.hub_extensions["juliaflow-unsafe-sandbox"].verification["sandbox"]["status"] == "failed"
        @test state.hub_extensions["juliaflow-bad-mirror-ref"].install_state != "enabled"
        @test state.hub_extensions["juliaflow-download-proof"].verification["sandbox"]["details"] == "Isolated compatibility sandbox command executed successfully"
        @test state.hub_extensions["juliaflow-download-proof"].verification["artifacts"]["details"] == "Downloaded artifact hashes verified from isolated artifact store"
        @test state.hub_extensions["juliaflow-download-proof"].verification["mirrors"]["details"] == "Offline/private mirror references resolved through local registry"
        hub_reloaded = load_state(store_root)
        hub_reloaded_labs = hub_reloaded.hub_extensions["juliaflow-labs-pack"]
        @test hub_reloaded_labs.artifact_hashes["package"] == "sha256:e97cfb2b9c49c0f5770cfed1060d2bd22a4b80d7ba0d44f36951438cb5ef54ce"
        @test hub_reloaded_labs.compatibility_sandbox_command == "julia --project=. extensions/labs/test/runtests.jl"
        @test hub_reloaded_labs.mirror_refs == ["mirror://offline/labs-pack", "private://workspace/labs-pack"]
        @test hub_reloaded_labs.verification["verified"] == true
        @test hub_reloaded_labs.verification["sandbox"]["status"] == "passed"
        @test hub_reloaded_labs.verification["artifacts"]["status"] == "passed"
        @test hub_reloaded_labs.verification["mirrors"]["status"] == "passed"
        @test dashboard_publish_response.status == 200
        @test occursin("\"dashboardId\":\"dashboard-foundation\"", String(dashboard_publish_response.body))
        @test occursin("\"version\":1", String(dashboard_publish_response.body))
        @test occursin("\"visibility\":\"public\"", String(dashboard_publish_response.body))
        @test occursin("\"shareToken\":", String(dashboard_publish_response.body))
        @test haskey(dashboard_publish_payload["dashboard"], "datasets")
        @test length(dashboard_publish_payload["dashboard"]["datasets"]["sales_overview"]) == 3
        @test dashboard_list_response.status == 200
        @test occursin("\"items\":[", String(dashboard_list_response.body))
        @test dashboard_get_unauthorized_response.status == 401
        @test occursin("invalid share token", String(dashboard_get_unauthorized_response.body))
        @test dashboard_get_invalid_token_response.status == 401
        @test occursin("invalid share token", String(dashboard_get_invalid_token_response.body))
        @test dashboard_get_response.status == 200
        @test occursin("\"publishedAt\":", String(dashboard_get_response.body))
        @test dashboard_chart_data_invalid_token_response.status == 401
        @test occursin("invalid share token", String(dashboard_chart_data_invalid_token_response.body))
        @test dashboard_chart_data_response.status == 200
        dashboard_chart_data_payload = JSON3.read(String(dashboard_chart_data_response.body), Dict{String,Any})
        @test dashboard_chart_data_payload["dashboardId"] == "dashboard-foundation"
        @test dashboard_chart_data_payload["chartId"] == "chart-line"
        @test dashboard_chart_data_payload["datasetKey"] == "sales_overview"
        @test dashboard_chart_data_payload["rowCount"] == 3
        @test dashboard_chart_data_payload["rows"][1]["window"] == "2026-Q1"
        @test dashboard_chart_data_payload["rows"][1]["amount"] == 120.0
        @test dashboard_chart_data_payload["fields"] == ["amount", "capacity", "region", "window"]
        @test dashboard_chart_data_payload["semantic"]["dimensions"] == ["window", "region"]
        @test dashboard_chart_data_payload["semantic"]["measures"] == ["amount", "capacity"]
        @test dashboard_chart_data_payload["semantic"]["availableMeasures"] == ["amount", "capacity"]
        @test dashboard_chart_data_payload["cache"]["cacheKey"] == "dashboard-foundation:chart-line:v1"
        @test dashboard_chart_data_payload["cache"]["live"] == true
        @test dashboard_chart_data_payload["exportFormats"] == ["json", "csv"]
        @test dashboard_chart_export_response.status == 200
        @test occursin("amount,capacity,region,window", String(dashboard_chart_export_response.body))
        @test occursin("120.0,180.0,west,2026-Q1", String(dashboard_chart_export_response.body))
        @test dashboard_publish_workspace_response.status == 200
        @test occursin("\"visibility\":\"workspace\"", String(dashboard_publish_workspace_response.body))
        @test dashboard_get_workspace_response.status == 401
        @test occursin("invalid workspace access token", String(dashboard_get_workspace_response.body))
        @test dashboard_get_workspace_invalid_token_response.status == 401
        @test occursin("invalid workspace access token", String(dashboard_get_workspace_invalid_token_response.body))
        @test dashboard_get_workspace_authorized_response.status == 200
        @test occursin("\"visibility\":\"workspace\"", String(dashboard_get_workspace_authorized_response.body))
        @test dashboard_get_workspace_bearer_invalid_response.status == 401
        @test occursin("invalid workspace access token", String(dashboard_get_workspace_bearer_invalid_response.body))
        @test dashboard_get_workspace_bearer_authorized_response.status == 200
        @test occursin("\"visibility\":\"workspace\"", String(dashboard_get_workspace_bearer_authorized_response.body))
        @test auth_missing_workflow_list_response.status == 401
        @test occursin("invalid auth token", String(auth_missing_workflow_list_response.body))
        @test auth_viewer_workflow_list_response.status == 200
        @test occursin("wf-foundation", String(auth_viewer_workflow_list_response.body))
        @test auth_viewer_execute_response.status == 403
        @test occursin("permission denied: workflow:execute", String(auth_viewer_execute_response.body))
        @test auth_editor_execute_response.status == 202
        @test auth_editor_hub_install_response.status == 403
        @test occursin("permission denied: hub:install", String(auth_editor_hub_install_response.body))
        @test hub_enable_registered_response.status == 200
        @test occursin("\"installState\":\"enabled\"", String(hub_enable_registered_response.body))
        @test create_response.status == 201
        @test occursin("\"status\":\"created\"", String(create_response.body))
        @test json_create_response.status == 201
        @test occursin("\"status\":\"created\"", String(json_create_response.body))
        @test update_response.status == 200
        @test occursin("\"status\":\"updated\"", String(update_response.body))
        @test execute_response.status == 202
        @test haskey(execute_payload, "executionId")
        @test haskey(execute_payload, "observabilityTrace")
        @test length(execute_payload["observabilityTrace"]["trace_id"]) == 32
        @test execute_payload["observabilityTrace"]["spans"][1]["name"] == "execution.dispatch_plan"
        @test occursin("\"checkpointTag\":\"cp/01-contracts-frozen\"", String(execute_response.body))
        @test occursin("\"requested_execution_mode\":\"gpu_preferred\"", String(execute_response.body))
        @test occursin("\"flow_variables\":{\"JULIAFLOW_GPU_DEVICE\":\"nvidia:0\"}", String(execute_response.body))
        @test occursin("\"resourcePlan\":[", String(execute_response.body))
        @test data_import_response.status == 201
        data_import_payload = JSON3.read(String(data_import_response.body), Dict{String,Any})
        @test data_import_payload["status"] == "profiled"
        @test data_import_payload["profile"]["datasetId"] == "foundation-profile"
        @test data_import_payload["profile"]["sourceUri"] == realpath(import_source_path)
        @test data_import_payload["profile"]["targetZone"] == "raw"
        @test startswith(data_import_payload["profile"]["artifactRef"], "local://data/raw/foundation-profile")
        @test data_import_payload["profile"]["localOnly"] == true
        @test data_import_payload["profile"]["activeReadMode"] == "csv"
        @test length(data_import_payload["profile"]["sourceOptions"]) == 4
        @test any(option -> option["mode"] == "duckdb", data_import_payload["profile"]["sourceOptions"])
        @test length(data_import_payload["profile"]["lineageArtifacts"]) == 4
        @test length(data_import_payload["profile"]["qualityChecks"]) >= 1
        @test data_import_payload["profile"]["workflowReadiness"]["downstreamReady"] == true
        @test length(data_import_payload["profile"]["quickPlots"]) >= 1
        @test length(data_import_payload["profile"]["previewRows"]) >= 1
        @test data_import_remote_source_response.status == 400
        @test occursin("sourceUri must be a local file path or local://", String(data_import_remote_source_response.body))
        @test data_import_escape_source_response.status == 400
        @test occursin("source escapes allowed import roots", String(data_import_escape_source_response.body))
        @test data_import_secret_source_response.status == 400
        @test occursin("appears to contain credentials or secrets", String(data_import_secret_source_response.body))
        @test data_import_large_source_response.status == 400
        @test occursin("source file exceeds size limit", String(data_import_large_source_response.body))
        @test data_import_unsupported_source_response.status == 400
        @test occursin("source extension is not supported", String(data_import_unsupported_source_response.body))
        @test data_import_credential_content_response.status == 400
        @test occursin("appears to contain credential content", String(data_import_credential_content_response.body))
        @test data_import_pii_content_response.status == 400
        @test occursin("appears to contain sensitive PII columns", String(data_import_pii_content_response.body))
        local_import_audit_events = filter(
            event -> event.event_type == "audit.action" && startswith(String(event.payload["action"]), "local.data.import"),
            JuliaFlowApiGateway.JuliaFlowGatewayRepository.load_events(state.repository),
        )
        @test any(
            event ->
                event.payload["action"] == "local.data.import" &&
                event.payload["targetId"] == "Foundation Profile" &&
                event.payload["details"]["outcome"] == "accepted" &&
                event.payload["details"]["sourceKind"] == "file" &&
                event.payload["details"]["sourceBasename"] == basename(import_source_path),
            local_import_audit_events,
        )
        @test any(
            event ->
                event.payload["action"] == "local.data.import.rejected" &&
                event.payload["targetId"] == "Credential Content Profile" &&
                event.payload["details"]["outcome"] == "rejected" &&
                occursin("credential content", String(event.payload["details"]["reason"])) &&
                !occursin(import_root, JSON3.write(event.payload)),
            local_import_audit_events,
        )
        @test any(
            event ->
                event.payload["action"] == "local.data.import.rejected" &&
                event.payload["targetId"] == "PII Content Profile" &&
                event.payload["details"]["outcome"] == "rejected" &&
                occursin("sensitive PII columns", String(event.payload["details"]["reason"])) &&
                !occursin("000-00-0000", JSON3.write(event.payload)),
            local_import_audit_events,
        )
        @test data_science_project_create_response.status == 201
        data_science_project_create_payload = JSON3.read(String(data_science_project_create_response.body), Dict{String,Any})
        @test data_science_project_create_payload["schemaVersion"] == "1.0"
        @test data_science_project_create_payload["projectId"] == "wellbore-geology"
        @test data_science_project_create_payload["localOnly"] == true
        @test data_science_project_create_payload["datasets"][1]["role"] == "train"
        @test data_science_project_create_payload["schemaContracts"][1]["columns"][1]["role"] == "depth"
        data_science_project_list_payload = JSON3.read(String(data_science_project_list_response.body), Dict{String,Any})
        @test data_science_project_list_response.status == 200
        @test length(data_science_project_list_payload["items"]) == 1
        @test data_science_project_get_response.status == 200
        @test occursin("\"projectId\":\"wellbore-geology\"", String(data_science_project_get_response.body))
        @test data_science_project_update_response.status == 200
        data_science_project_update_payload = JSON3.read(String(data_science_project_update_response.body), Dict{String,Any})
        @test data_science_project_update_payload["name"] == "Wellbore Geology Updated"
        @test data_science_project_update_payload["splitPlans"][1]["strategy"] == "depth"
        @test data_science_project_missing_name_response.status == 400
        @test occursin("data science project missing name", String(data_science_project_missing_name_response.body))
        @test data_science_project_duplicate_response.status == 409
        @test occursin("data science project already exists", String(data_science_project_duplicate_response.body))
        @test data_science_project_bad_schema_version_response.status == 400
        @test occursin("schemaVersion must be 1.0", String(data_science_project_bad_schema_version_response.body))
        @test data_science_project_bad_child_shape_response.status == 400
        @test occursin("project child records must be arrays", String(data_science_project_bad_child_shape_response.body))
        @test data_science_project_id_mismatch_response.status == 400
        @test occursin("project id mismatch", String(data_science_project_id_mismatch_response.body))
        @test data_science_project_remote_source_response.status == 400
        @test occursin("dataset sourceUri must use local://", String(data_science_project_remote_source_response.body))
        @test data_science_project_traversal_source_response.status == 400
        @test occursin("dataset sourceUri cannot contain path traversal", String(data_science_project_traversal_source_response.body))
        @test data_science_project_nonlocal_source_response.status == 400
        @test occursin("dataset localOnly must be true", String(data_science_project_nonlocal_source_response.body))
        @test data_science_project_missing_response.status == 404
        @test data_science_project_foundation_response.status == 201
        @test isfile(joinpath(store_root, "data-science-projects.json"))
        @test haskey(load_state(store_root).data_science_projects, "wellbore-geology")
        @test haskey(load_state(store_root).data_science_projects, "foundation-ml-project")
        @test transform_fit_apply_response.status == 201
        transform_fit_apply_payload = JSON3.read(String(transform_fit_apply_response.body), Dict{String,Any})
        @test transform_fit_apply_payload["status"] == "completed"
        @test transform_fit_apply_payload["transformRun"]["fitSplit"] == "train"
        @test "validation" in transform_fit_apply_payload["transformRun"]["applySplits"]
        @test "test" in transform_fit_apply_payload["transformRun"]["applySplits"]
        @test length(transform_fit_apply_payload["transformRun"]["leakageChecks"]) >= 2
        @test startswith(String(transform_fit_apply_payload["transformRun"]["executionEvidence"]["executionId"]), "dsjob-")
        @test transform_fit_apply_payload["transformRun"]["executionEvidence"]["mode"] == "local_project_job"
        @test length(transform_fit_apply_payload["project"]["transformFitApplyRecords"]) >= 1
        @test transform_fit_apply_bad_fit_response.status == 400
        @test occursin("fitSplit must be train", String(transform_fit_apply_bad_fit_response.body))
        @test transform_fit_apply_train_apply_response.status == 400
        @test occursin("can only apply to validation", String(transform_fit_apply_train_apply_response.body))
        @test statistical_analysis_response.status == 201
        statistical_analysis_payload = JSON3.read(String(statistical_analysis_response.body), Dict{String,Any})
        @test statistical_analysis_payload["status"] == "completed"
        @test statistical_analysis_payload["analysisRun"]["datasetId"] == "foundation-sales-sample"
        @test occursin("pearson_correlation", statistical_analysis_payload["analysisRun"]["method"])
        @test length(statistical_analysis_payload["analysisRun"]["charts"]) >= 1
        @test statistical_analysis_payload["analysisRun"]["resultSummary"]["executionMode"] == "local_csv"
        @test statistical_analysis_payload["analysisRun"]["resultSummary"]["rowCount"] == 4
        @test "amount" in statistical_analysis_payload["analysisRun"]["resultSummary"]["numericColumns"]
        amount_summary = only(filter(summary -> summary["column"] == "amount", statistical_analysis_payload["analysisRun"]["resultSummary"]["summaries"]))
        @test amount_summary["mean"] == 25.0
        @test statistical_analysis_payload["analysisRun"]["resultSummary"]["inferentialTests"]["ols"]["featureColumn"] == "margin"
        @test statistical_analysis_payload["analysisRun"]["resultSummary"]["inferentialTests"]["ols"]["rSquared"] > 0.9
        @test statistical_analysis_payload["analysisRun"]["resultSummary"]["inferentialTests"]["anova"]["groupColumn"] == "region"
        @test statistical_analysis_payload["analysisRun"]["resultSummary"]["inferentialTests"]["anova"]["dfBetween"] == 1
        @test statistical_analysis_payload["analysisRun"]["resultSummary"]["inferentialTests"]["tTest"]["groupColumn"] == "region"
        @test haskey(statistical_analysis_payload["analysisRun"]["resultSummary"]["inferentialTests"], "chiSquare")
        @test statistical_analysis_payload["analysisRun"]["resultSummary"]["inferentialTests"]["chiSquare"]["degreesOfFreedom"] == 1
        @test statistical_analysis_payload["analysisRun"]["resultSummary"]["inferentialTests"]["spearmanCorrelation"]["columns"] == statistical_analysis_payload["analysisRun"]["resultSummary"]["numericColumns"]
        @test length(statistical_analysis_payload["analysisRun"]["artifactRefs"]) == 2
        @test startswith(String(statistical_analysis_payload["analysisRun"]["executionEvidence"]["executionId"]), "dsjob-")
        @test statistical_analysis_payload["analysisRun"]["executionEvidence"]["status"] == "completed"
        stats_result_ref = String(statistical_analysis_payload["analysisRun"]["resultRef"])
        stats_code_ref = String(statistical_analysis_payload["analysisRun"]["generatedCodeRef"])
        stats_result_path = joinpath(data_estate_root, split(replace(stats_result_ref, "local://" => ""), '/')...)
        stats_code_path = joinpath(data_estate_root, split(replace(stats_code_ref, "local://" => ""), '/')...)
        @test isfile(stats_result_path)
        @test isfile(stats_code_path)
        @test occursin("\"executionMode\":\"local_csv\"", read(stats_result_path, String))
        @test all(ref -> haskey(ref, "checksumSha256") && haskey(ref, "sizeBytes"), statistical_analysis_payload["analysisRun"]["artifactRefs"])
        @test length(statistical_analysis_payload["project"]["statisticalAnalysisRuns"]) >= 1
        @test statistical_analysis_bad_method_response.status == 400
        @test occursin("statistical analysis unsupported methods", String(statistical_analysis_bad_method_response.body))
        @test tuning_study_response.status == 201
        tuning_study_payload = JSON3.read(String(tuning_study_response.body), Dict{String,Any})
        @test tuning_study_payload["status"] == "completed"
        @test tuning_study_payload["tuningStudy"]["validationOnly"] == true
        @test tuning_study_payload["tuningStudy"]["validationEvidence"]["finalTestPolicy"] == "forbid_final_test"
        @test startswith(String(tuning_study_payload["tuningStudy"]["executionEvidence"]["executionId"]), "dsjob-")
        @test tuning_study_payload["tuningStudy"]["validationEvidence"]["executionId"] == tuning_study_payload["tuningStudy"]["executionEvidence"]["executionId"]
        @test length(tuning_study_payload["tuningStudy"]["trials"]) == 3
        @test length(tuning_study_payload["project"]["tuningStudies"]) >= 1
        @test length(tuning_study_payload["project"]["trainingPlans"]) >= 1
        @test tuning_study_final_test_response.status == 400
        @test occursin("final test data cannot be used", String(tuning_study_final_test_response.body))
        @test final_evaluation_response.status == 201
        final_evaluation_payload = JSON3.read(String(final_evaluation_response.body), Dict{String,Any})
        @test final_evaluation_payload["status"] == "completed"
        @test final_evaluation_payload["evaluationReport"]["finalTestOnly"] == true
        @test final_evaluation_payload["evaluationReport"]["validationEvidence"]["finalTestPolicy"] == "use_final_test"
        @test final_evaluation_payload["evaluationReport"]["validationEvidence"]["validationOnlyTuning"] == true
        @test startswith(String(final_evaluation_payload["evaluationReport"]["executionEvidence"]["executionId"]), "dsjob-")
        @test final_evaluation_payload["evaluationReport"]["validationEvidence"]["executionId"] == final_evaluation_payload["evaluationReport"]["executionEvidence"]["executionId"]
        @test length(final_evaluation_payload["project"]["evaluationReports"]) >= 1
        @test final_evaluation_bad_policy_response.status == 400
        @test occursin("finalTestPolicy must be use_final_test", String(final_evaluation_bad_policy_response.body))
        @test final_evaluation_missing_training_response.status == 409
        @test occursin("training plan not found", String(final_evaluation_missing_training_response.body))
        @test prediction_export_response.status == 201
        prediction_export_payload = JSON3.read(String(prediction_export_response.body), Dict{String,Any})
        @test prediction_export_payload["status"] == "completed"
        @test prediction_export_payload["predictionExport"]["outputContractRef"] == "contract://outputs/foundation-predictions"
        @test prediction_export_payload["predictionExport"]["format"] == "csv"
        prediction_export_output_columns = String.(collect(prediction_export_payload["predictionExport"]["outputColumns"]))
        @test prediction_export_output_columns == [
            "prediction_id",
            "dataset_id",
            "evaluation_report_id",
            "output_contract_ref",
            "prediction",
        ]
        @test prediction_export_payload["predictionExport"]["validationEvidence"]["finalEvaluationApproved"] == true
        @test prediction_export_payload["predictionExport"]["validationEvidence"]["outputContractRef"] == "contract://outputs/foundation-predictions"
        @test prediction_export_payload["predictionExport"]["validationEvidence"]["outputSchemaValidated"] == true
        @test String.(collect(prediction_export_payload["predictionExport"]["validationEvidence"]["outputColumns"])) == prediction_export_output_columns
        @test length(prediction_export_payload["predictionExport"]["artifactRefs"]) == 1
        @test all(ref -> haskey(ref, "checksumSha256") && haskey(ref, "sizeBytes"), prediction_export_payload["predictionExport"]["artifactRefs"])
        prediction_artifact_ref = String(prediction_export_payload["predictionExport"]["artifactRef"])
        prediction_artifact_path = joinpath(data_estate_root, split(replace(prediction_artifact_ref, "local://" => ""), '/')...)
        @test isfile(prediction_artifact_path)
        prediction_artifact_content = read(prediction_artifact_path, String)
        @test startswith(prediction_artifact_content, "prediction_id,dataset_id,evaluation_report_id,output_contract_ref,prediction")
        @test occursin("contract://outputs/foundation-predictions", prediction_artifact_content)
        @test occursin(String(prediction_export_payload["predictionExport"]["evaluationReportId"]), prediction_artifact_content)
        prediction_export_execution_id = String(prediction_export_payload["predictionExport"]["executionEvidence"]["executionId"])
        @test startswith(prediction_export_execution_id, "dsjob-")
        @test prediction_export_payload["predictionExport"]["executionEvidence"]["status"] == "completed"
        @test prediction_export_payload["predictionExport"]["executionEvidence"]["mode"] == "local_project_job"
        @test prediction_export_payload["predictionExport"]["validationEvidence"]["executionId"] == prediction_export_execution_id
        persisted_prediction_execution_index = findfirst(execution -> execution.execution_id == prediction_export_execution_id, state.executions)
        @test persisted_prediction_execution_index !== nothing
        persisted_prediction_execution = state.executions[persisted_prediction_execution_index]
        @test haskey(state.workflows, persisted_prediction_execution.workflow_id)
        @test persisted_prediction_execution.status == "completed"
        @test persisted_prediction_execution.metadata["data_science_project_job"]["job_type"] == "prediction_export"
        @test persisted_prediction_execution.metadata["data_science_project_job"]["source_record_id"] == prediction_export_payload["predictionExport"]["predictionExportId"]
        @test persisted_prediction_execution.metadata["worker_dispatch"]["orchestrationMode"] == "worker_service_tick"
        @test persisted_prediction_execution.metadata["worker_dispatch"]["dispatchStatus"] == "completed"
        @test persisted_prediction_execution.metadata["data_science_project_worker_state"]["job_type"] == "prediction_export"
        @test persisted_prediction_execution.metadata["data_science_project_worker_state"]["status"] == "completed"
        @test [entry["status"] for entry in persisted_prediction_execution.status_history] == ["accepted", "queued", "running", "completed"]
        @test length(prediction_export_payload["project"]["predictionExports"]) >= 1
        @test prediction_export_payload["project"]["predictionExports"][1]["artifactRefs"][1]["checksumSha256"] == prediction_export_payload["predictionExport"]["artifactRefs"][1]["checksumSha256"]
        prediction_export_job = first(filter(job -> job["jobType"] == "prediction_export", prediction_export_payload["project"]["projectJobs"]))
        @test prediction_export_job["outputRefs"][1]["sizeBytes"] == prediction_export_payload["predictionExport"]["artifactRefs"][1]["sizeBytes"]
        @test prediction_export_job["resourceEvidence"]["executionMode"] == "prediction_export"
        @test prediction_export_job["resourceEvidence"]["dispatchLane"] in ["cpu", "gpu"]
        @test prediction_export_job["resourceEvidence"]["cpuWorkerConcurrency"] >= 1
        @test prediction_export_job["executionEvidence"]["executionId"] == prediction_export_execution_id
        @test prediction_export_job["executionEvidence"]["workerId"] == persisted_prediction_execution.metadata["worker_id"]
        @test prediction_export_job["executionEvidence"]["orchestrationMode"] == "worker_service_tick"
        @test prediction_export_job["executionEvidence"]["dispatchStatus"] == "completed"
        @test prediction_export_bad_format_response.status == 400
        @test occursin("format must be csv", String(prediction_export_bad_format_response.body))
        @test prediction_export_missing_contract_response.status == 400
        @test occursin("outputContractRef required", String(prediction_export_missing_contract_response.body))
        @test prediction_export_bad_columns_response.status == 400
        @test occursin("outputColumns unsupported", String(prediction_export_bad_columns_response.body))
        @test prediction_export_mapped_response.status == 201
        prediction_export_mapped_payload = JSON3.read(String(prediction_export_mapped_response.body), Dict{String,Any})
        @test prediction_export_mapped_payload["predictionExport"]["outputContractRef"] == "contract://outputs/scored-foundation-submission"
        @test String.(collect(prediction_export_mapped_payload["predictionExport"]["outputColumns"])) == ["row_id", "score"]
        @test String.(collect(prediction_export_mapped_payload["predictionExport"]["validationEvidence"]["outputContractColumns"])) == ["row_id", "score"]
        mapped_pairs = Dict(String(mapping["outputColumn"]) => String(mapping["sourceColumn"]) for mapping in prediction_export_mapped_payload["predictionExport"]["outputMappings"])
        @test mapped_pairs["row_id"] == "prediction_id"
        @test mapped_pairs["score"] == "prediction"
        @test prediction_export_mapped_payload["predictionExport"]["validationEvidence"]["contractRequiredColumnsSatisfied"] == true
        mapped_artifact_ref = String(prediction_export_mapped_payload["predictionExport"]["artifactRef"])
        mapped_artifact_path = joinpath(data_estate_root, split(replace(mapped_artifact_ref, "local://" => ""), '/')...)
        @test startswith(read(mapped_artifact_path, String), "row_id,score")
        @test prediction_export_bad_mapping_response.status == 400
        @test occursin("outputMappings unsupported sourceColumn", String(prediction_export_bad_mapping_response.body))
        @test drift_report_response.status == 201
        drift_report_payload = JSON3.read(String(drift_report_response.body), Dict{String,Any})
        @test drift_report_payload["status"] == "completed"
        @test drift_report_payload["monitoringBaseline"]["baselineId"] == "baseline-foundation-drift"
        @test drift_report_payload["driftReport"]["validationEvidence"]["outputContractRef"] == "contract://outputs/foundation-predictions"
        @test startswith(String(drift_report_payload["driftReport"]["executionEvidence"]["executionId"]), "dsjob-")
        @test drift_report_payload["driftReport"]["executionEvidence"]["orchestrationMode"] == "worker_service_tick"
        @test drift_report_payload["driftReport"]["executionEvidence"]["dispatchStatus"] == "completed"
        @test drift_report_payload["driftReport"]["validationEvidence"]["executionId"] == drift_report_payload["driftReport"]["executionEvidence"]["executionId"]
        @test length(drift_report_payload["driftReport"]["artifactRefs"]) == 1
        @test haskey(drift_report_payload["driftReport"]["artifactRefs"][1], "checksumSha256")
        @test haskey(drift_report_payload["driftReport"]["artifactRefs"][1], "sizeBytes")
        drift_artifact_ref = String(drift_report_payload["driftReport"]["artifactRefs"][1]["path"])
        drift_artifact_path = joinpath(data_estate_root, split(replace(drift_artifact_ref, "local://" => ""), '/')...)
        @test isfile(drift_artifact_path)
        drift_artifact_payload = JSON3.read(read(drift_artifact_path, String), Dict{String,Any})
        @test drift_artifact_payload["driftReportId"] == drift_report_payload["driftReport"]["driftReportId"]
        @test drift_artifact_payload["predictionExportId"] == prediction_export_payload["predictionExport"]["predictionExportId"]
        @test length(drift_report_payload["project"]["monitoringBaselines"]) >= 1
        @test length(drift_report_payload["project"]["driftReports"]) >= 1
        @test length(drift_report_payload["project"]["projectJobs"]) >= 6
        project_job_types = Set(String(job["jobType"]) for job in drift_report_payload["project"]["projectJobs"])
        @test issubset(
            Set(["transform_fit_apply", "statistical_analysis", "tuning_study", "final_evaluation", "prediction_export", "drift_report"]),
            project_job_types,
        )
        @test all(job -> String(job["status"]) == "completed", drift_report_payload["project"]["projectJobs"])
        @test all(job -> haskey(job, "outputRefs"), drift_report_payload["project"]["projectJobs"])
        @test all(job -> haskey(job, "resourceEvidence"), drift_report_payload["project"]["projectJobs"])
        @test all(job -> haskey(job["resourceEvidence"], "selectedBackend"), drift_report_payload["project"]["projectJobs"])
        @test all(job -> haskey(job["resourceEvidence"], "gpuFallbackReason"), drift_report_payload["project"]["projectJobs"])
        drift_job = first(filter(job -> job["jobType"] == "drift_report", drift_report_payload["project"]["projectJobs"]))
        @test drift_job["resourceEvidence"]["executionMode"] == "drift_report"
        @test drift_job["executionEvidence"]["orchestrationMode"] == "worker_service_tick"
        @test drift_job["executionEvidence"]["dispatchStatus"] == "completed"
        drift_execution = first(filter(
            execution -> execution.execution_id == drift_job["executionEvidence"]["executionId"],
            state.executions,
        ))
        @test drift_execution.metadata["worker_dispatch"]["orchestrationMode"] == "worker_service_tick"
        @test drift_execution.metadata["data_science_project_worker_state"]["job_type"] == "drift_report"
        @test drift_execution.metadata["data_science_project_worker_state"]["status"] == "completed"
        execution_backed_job_types = Set(["transform_fit_apply", "statistical_analysis", "tuning_study", "final_evaluation", "prediction_export", "drift_report"])
        execution_backed_jobs = filter(job -> String(job["jobType"]) in execution_backed_job_types, drift_report_payload["project"]["projectJobs"])
        @test issubset(execution_backed_job_types, Set(String(job["jobType"]) for job in execution_backed_jobs))
        @test all(job -> haskey(job, "executionEvidence"), execution_backed_jobs)
        for job in execution_backed_jobs
            job_execution_id = String(job["executionEvidence"]["executionId"])
            @test startswith(job_execution_id, "dsjob-")
            @test job["executionEvidence"]["status"] == "completed"
            @test job["executionEvidence"]["mode"] == "local_project_job"
            persisted_index = findfirst(execution -> execution.execution_id == job_execution_id, state.executions)
            @test persisted_index !== nothing
            persisted_execution = state.executions[persisted_index]
            @test haskey(state.workflows, persisted_execution.workflow_id)
            @test persisted_execution.metadata["data_science_project_job"]["job_type"] == job["jobType"]
            @test persisted_execution.metadata["data_science_project_job"]["source_record_id"] == job["sourceRecordId"]
        end
        @test drift_report_bad_threshold_response.status == 400
        @test occursin("threshold must be between 0 and 1", String(drift_report_bad_threshold_response.body))
        @test transform_run_response.status == 202
        transform_run_payload = JSON3.read(String(transform_run_response.body), Dict{String,Any})
        @test transform_run_payload["status"] == "accepted"
        @test transform_run_payload["run"]["workflowId"] == "wf-foundation"
        @test "node-source" in transform_run_payload["run"]["nodeIds"]
        @test length(transform_run_payload["run"]["artifactEvidence"]) >= 1
        @test transform_history_response.status == 200
        transform_history_payload = JSON3.read(String(transform_history_response.body), Dict{String,Any})
        @test transform_history_payload["count"] >= 1
        @test transform_history_payload["items"][1]["workflowId"] == "wf-foundation"
        @test model_register_without_validation_response.status == 409
        @test occursin("model registration validation evidence required", String(model_register_without_validation_response.body))
        @test deploy_package_without_validation_response.status == 409
        @test occursin("deploy package validation evidence required", String(deploy_package_without_validation_response.body))
        @test ml_experiment_run_response.status == 202
        ml_experiment_payload = JSON3.read(String(ml_experiment_run_response.body), Dict{String,Any})
        @test ml_experiment_payload["status"] == "accepted"
        @test ml_experiment_payload["experiment"]["workflowId"] == "wf-foundation"
        @test ml_experiment_payload["experiment"]["datasetId"] == "foundation-sales-sample"
        @test ml_experiment_payload["experiment"]["modelId"] == "foundation-linear-baseline"
        @test ml_experiment_payload["experiment"]["target"] == "amount"
        @test ml_experiment_payload["experiment"]["validationEvidence"]["projectId"] == "foundation-ml-project"
        @test ml_experiment_payload["experiment"]["validationEvidence"]["splitPlanId"] == "split-foundation-stratified"
        @test ml_experiment_payload["experiment"]["validationEvidence"]["finalTestPolicy"] == "forbid_final_test"
        @test haskey(ml_experiment_payload["experiment"]["metrics"], "mae")
        @test length(ml_experiment_payload["experiment"]["featureImportance"]) >= 1
        @test length(ml_experiment_payload["experiment"]["artifactEvidence"]) >= 3
        @test ml_experiment_payload["experiment"]["localOnly"] == true
        @test ml_experiment_missing_split_response.status == 400
        @test occursin("ml experiment split plan not found", String(ml_experiment_missing_split_response.body))
        @test ml_experiment_final_test_response.status == 400
        @test occursin("final test data cannot be used", String(ml_experiment_final_test_response.body))
        @test ml_experiment_history_response.status == 200
        ml_experiment_history_payload = JSON3.read(String(ml_experiment_history_response.body), Dict{String,Any})
        @test ml_experiment_history_payload["count"] >= 1
        @test ml_experiment_history_payload["items"][1]["workflowId"] == "wf-foundation"
        @test model_register_response.status == 201
        model_register_payload = JSON3.read(String(model_register_response.body), Dict{String,Any})
        @test model_register_payload["status"] == "registered"
        @test model_register_payload["model"]["workflowId"] == "wf-foundation"
        @test model_register_payload["model"]["modelId"] == "foundation-linear-baseline"
        @test model_register_payload["model"]["status"] == "registered"
        @test "reviewed" in model_register_payload["model"]["tags"]
        @test model_register_payload["model"]["primaryMetricName"] == "mae"
        @test length(model_register_payload["model"]["artifactEvidence"]) >= 3
        @test model_register_payload["model"]["validationEvidence"]["projectId"] == "foundation-ml-project"
        @test model_register_payload["model"]["validationEvidence"]["finalTestPolicy"] == "forbid_final_test"
        @test model_register_payload["model"]["localOnly"] == true
        @test model_registry_response.status == 200
        model_registry_payload = JSON3.read(String(model_registry_response.body), Dict{String,Any})
        @test model_registry_payload["count"] >= 1
        @test model_registry_payload["items"][1]["modelId"] == "foundation-linear-baseline"
        @test model_lifecycle_after_register_response.status == 200
        model_lifecycle_after_register_payload = JSON3.read(String(model_lifecycle_after_register_response.body), Dict{String,Any})
        register_registry_match = findfirst(
            record -> String(get(record, "modelId", "")) == "foundation-linear-baseline",
            model_lifecycle_after_register_payload["modelRegistryRecords"],
        )
        @test register_registry_match !== nothing
        registered_registry_record = model_lifecycle_after_register_payload["modelRegistryRecords"][register_registry_match]
        @test registered_registry_record["status"] == "registered"
        @test registered_registry_record["deploymentStatus"] == "not_deployed"
        @test registered_registry_record["validationEvidence"]["projectId"] == "foundation-ml-project"
        register_lifecycle_match = findfirst(
            record -> String(get(record, "modelId", "")) == "foundation-linear-baseline",
            model_lifecycle_after_register_payload["modelLifecycleRecords"],
        )
        @test register_lifecycle_match !== nothing
        registered_lifecycle_record = model_lifecycle_after_register_payload["modelLifecycleRecords"][register_lifecycle_match]
        @test registered_lifecycle_record["state"] == "validated"
        @test haskey(registered_lifecycle_record, "updatedAt")
        @test !haskey(registered_lifecycle_record, "deployedEndpointId")
        @test model_lifecycle_approval_response.status == 201
        approval_payload = JSON3.read(String(model_lifecycle_approval_response.body), Dict{String,Any})
        @test approval_payload["lifecycleRecord"]["state"] == "approved"
        @test approval_payload["lifecycleRecord"]["validationEvidence"]["previousState"] == "validated"
        approved_registry_record = first(filter(
            record -> String(get(record, "modelId", "")) == "foundation-linear-baseline",
            approval_payload["project"]["modelRegistryRecords"],
        ))
        @test approved_registry_record["status"] == "approved"
        @test approved_registry_record["validationEvidence"]["lifecycleAction"] == "approve_model"
        @test deploy_package_response.status == 201
        deploy_package_payload = JSON3.read(String(deploy_package_response.body), Dict{String,Any})
        @test deploy_package_payload["status"] == "packaged"
        @test deploy_package_payload["package"]["workflowId"] == "wf-foundation"
        @test deploy_package_payload["package"]["modelId"] == "foundation-linear-baseline"
        @test deploy_package_payload["package"]["endpointUrl"] == "http://127.0.0.1:8000/v1/predict"
        @test deploy_package_payload["package"]["deploymentStatus"] == "local_ready"
        @test length(deploy_package_payload["package"]["packageChecksumSha256"]) == 64
        @test length(deploy_package_payload["package"]["artifactEvidence"]) >= 5
        @test deploy_package_payload["package"]["validationEvidence"]["projectId"] == "foundation-ml-project"
        @test deploy_package_payload["package"]["validationEvidence"]["finalTestPolicy"] == "forbid_final_test"
        @test occursin("Genie", deploy_package_payload["package"]["serviceCode"])
        @test deploy_package_history_response.status == 200
        deploy_package_history_payload = JSON3.read(String(deploy_package_history_response.body), Dict{String,Any})
        @test deploy_package_history_payload["count"] >= 1
        @test deploy_package_history_payload["items"][1]["packageId"] == deploy_package_payload["package"]["packageId"]
        @test model_lifecycle_after_deploy_response.status == 200
        model_lifecycle_after_deploy_payload = JSON3.read(String(model_lifecycle_after_deploy_response.body), Dict{String,Any})
        deploy_registry_match = findfirst(
            record -> String(get(record, "modelId", "")) == "foundation-linear-baseline",
            model_lifecycle_after_deploy_payload["modelRegistryRecords"],
        )
        @test deploy_registry_match !== nothing
        deployed_registry_record = model_lifecycle_after_deploy_payload["modelRegistryRecords"][deploy_registry_match]
        @test deployed_registry_record["deploymentStatus"] == "local_ready"
        @test length(model_lifecycle_after_deploy_payload["modelRegistryRecords"]) == length(model_lifecycle_after_register_payload["modelRegistryRecords"])
        deploy_lifecycle_match = findfirst(
            record -> String(get(record, "modelId", "")) == "foundation-linear-baseline",
            model_lifecycle_after_deploy_payload["modelLifecycleRecords"],
        )
        @test deploy_lifecycle_match !== nothing
        deployed_lifecycle_record = model_lifecycle_after_deploy_payload["modelLifecycleRecords"][deploy_lifecycle_match]
        @test deployed_lifecycle_record["state"] == "deployed"
        @test deployed_lifecycle_record["deployedEndpointId"] == deploy_package_payload["package"]["packageId"]
        @test length(model_lifecycle_after_deploy_payload["modelLifecycleRecords"]) == length(model_lifecycle_after_register_payload["modelLifecycleRecords"])
        @test model_lifecycle_rolled_back_too_early_response.status == 400
        @test occursin("rollback requires rollback_ready", String(model_lifecycle_rolled_back_too_early_response.body))
        @test model_lifecycle_rollback_ready_response.status == 201
        rollback_ready_payload = JSON3.read(String(model_lifecycle_rollback_ready_response.body), Dict{String,Any})
        @test rollback_ready_payload["status"] == "completed"
        @test rollback_ready_payload["lifecycleRecord"]["state"] == "rollback_ready"
        @test rollback_ready_payload["lifecycleRecord"]["rollbackModelId"] == "foundation-linear-baseline-v0"
        @test rollback_ready_payload["lifecycleRecord"]["rollbackReason"] == "local drift review approved fallback model"
        @test rollback_ready_payload["lifecycleRecord"]["validationEvidence"]["previousState"] == "deployed"
        @test rollback_ready_payload["lifecycleRecord"]["validationEvidence"]["deployedEndpointId"] == deploy_package_payload["package"]["packageId"]
        rollback_lifecycle_job = first(filter(job -> job["jobType"] == "model_lifecycle", rollback_ready_payload["project"]["projectJobs"]))
        @test rollback_lifecycle_job["sourceRecordId"] == "foundation-linear-baseline"
        @test rollback_lifecycle_job["resourceEvidence"]["executionMode"] == "model_lifecycle_action"
        @test rollback_lifecycle_job["resourceEvidence"]["cpuThreadCount"] >= 1
        @test rollback_lifecycle_job["executionEvidence"]["orchestrationMode"] == "worker_service_tick"
        @test rollback_lifecycle_job["executionEvidence"]["dispatchStatus"] == "completed"
        @test rollback_lifecycle_job["executionEvidence"]["workerPool"] == rollback_lifecycle_job["resourceEvidence"]["workerPool"]
        @test rollback_lifecycle_job["executionEvidence"]["dispatchLane"] == rollback_lifecycle_job["resourceEvidence"]["dispatchLane"]
        rollback_lifecycle_execution = first(filter(
            execution -> execution.execution_id == rollback_lifecycle_job["executionEvidence"]["executionId"],
            state.executions,
        ))
        @test rollback_lifecycle_execution.metadata["worker_dispatch"]["orchestrationMode"] == "worker_service_tick"
        @test rollback_lifecycle_execution.metadata["worker_dispatch"]["dispatchStatus"] == "completed"
        @test rollback_lifecycle_execution.metadata["data_science_project_worker_state"]["status"] == "completed"
        @test [entry["status"] for entry in rollback_lifecycle_execution.status_history] == ["accepted", "queued", "running", "completed"]
        @test model_lifecycle_rolled_back_response.status == 201
        rolled_back_payload = JSON3.read(String(model_lifecycle_rolled_back_response.body), Dict{String,Any})
        @test rolled_back_payload["lifecycleRecord"]["state"] == "rolled_back"
        @test rolled_back_payload["lifecycleRecord"]["rollbackModelId"] == "foundation-linear-baseline-v0"
        @test rolled_back_payload["lifecycleRecord"]["validationEvidence"]["previousState"] == "rollback_ready"
        @test startswith(rolled_back_payload["lifecycleRecord"]["rollbackPackageId"], "rollback-")
        @test rolled_back_payload["lifecycleRecord"]["deployedEndpointId"] == rolled_back_payload["lifecycleRecord"]["rollbackPackageId"]
        @test rolled_back_payload["lifecycleRecord"]["validationEvidence"]["rollbackSourcePackageId"] == deploy_package_payload["package"]["packageId"]
        @test rolled_back_payload["lifecycleRecord"]["validationEvidence"]["rollbackPackageId"] == rolled_back_payload["lifecycleRecord"]["rollbackPackageId"]
        rolled_back_registry_record = first(filter(
            record -> String(get(record, "modelId", "")) == "foundation-linear-baseline",
            rolled_back_payload["project"]["modelRegistryRecords"],
        ))
        @test rolled_back_registry_record["status"] == "rolled_back"
        @test rolled_back_registry_record["deploymentStatus"] == "rolled_back"
        @test rolled_back_registry_record["rollbackModelId"] == "foundation-linear-baseline-v0"
        deploy_package_history_after_rollback_payload = JSON3.read(String(deploy_package_history_after_rollback_response.body), Dict{String,Any})
        rollback_package = first(filter(
            package -> String(get(package, "packageId", "")) == rolled_back_payload["lifecycleRecord"]["rollbackPackageId"],
            deploy_package_history_after_rollback_payload["items"],
        ))
        @test rollback_package["deploymentStatus"] == "rolled_back"
        @test rollback_package["modelId"] == "foundation-linear-baseline-v0"
        @test rollback_package["rollbackFromModelId"] == "foundation-linear-baseline"
        @test rollback_package["rollbackTargetModelId"] == "foundation-linear-baseline-v0"
        @test rollback_package["rollbackSourcePackageId"] == deploy_package_payload["package"]["packageId"]
        @test occursin("foundation-linear-baseline-v0", rollback_package["serviceCode"])
        @test length(rollback_package["packageChecksumSha256"]) == 64
        @test model_lifecycle_retraining_response.status == 201
        retraining_payload = JSON3.read(String(model_lifecycle_retraining_response.body), Dict{String,Any})
        @test retraining_payload["lifecycleRecord"]["state"] == "retraining_requested"
        @test retraining_payload["lifecycleRecord"]["retrainingReason"] == "post-rollback retraining requested"
        @test retraining_payload["lifecycleRecord"]["validationEvidence"]["previousState"] == "rolled_back"
        @test startswith(retraining_payload["lifecycleRecord"]["retrainingTrainingPlanId"], "retraining-")
        @test startswith(retraining_payload["lifecycleRecord"]["retrainingTuningStudyId"], "retraining-tuning-")
        @test startswith(retraining_payload["lifecycleRecord"]["retrainingJobId"], "job-")
        @test retraining_payload["lifecycleRecord"]["validationEvidence"]["retrainingTrainingPlanId"] == retraining_payload["lifecycleRecord"]["retrainingTrainingPlanId"]
        @test retraining_payload["lifecycleRecord"]["validationEvidence"]["retrainingTuningStudyId"] == retraining_payload["lifecycleRecord"]["retrainingTuningStudyId"]
        @test retraining_payload["lifecycleRecord"]["validationEvidence"]["retrainingJobId"] == retraining_payload["lifecycleRecord"]["retrainingJobId"]
        @test length(retraining_payload["project"]["modelLifecycleRecords"]) == length(model_lifecycle_after_deploy_payload["modelLifecycleRecords"])
        retraining_training_plan = first(filter(
            plan -> String(get(plan, "trainingPlanId", "")) == retraining_payload["lifecycleRecord"]["retrainingTrainingPlanId"],
            retraining_payload["project"]["trainingPlans"],
        ))
        @test retraining_training_plan["targetColumn"] == "amount"
        @test retraining_training_plan["splitPlanId"] == "split-foundation-stratified"
        @test retraining_training_plan["sourceModelId"] == "foundation-linear-baseline"
        retraining_tuning_study = first(filter(
            study -> String(get(study, "tuningStudyId", "")) == retraining_payload["lifecycleRecord"]["retrainingTuningStudyId"],
            retraining_payload["project"]["tuningStudies"],
        ))
        @test retraining_tuning_study["trainingPlanId"] == retraining_training_plan["trainingPlanId"]
        @test retraining_tuning_study["validationOnly"] == true
        @test retraining_tuning_study["validationEvidence"]["finalTestPolicy"] == "forbid_final_test"
        @test retraining_tuning_study["validationEvidence"]["lifecycleAction"] == "request_retraining"
        @test retraining_tuning_study["validationEvidence"]["retrainingOfModelId"] == "foundation-linear-baseline"
        @test retraining_tuning_study["executionEvidence"]["orchestrationMode"] == "worker_service_tick"
        retraining_job = first(filter(job -> job["jobType"] == "retraining", retraining_payload["project"]["projectJobs"]))
        @test retraining_job["jobId"] == retraining_payload["lifecycleRecord"]["retrainingJobId"]
        @test retraining_job["datasetId"] == "foundation-sales-sample"
        @test retraining_job["splitPlanId"] == "split-foundation-stratified"
        @test retraining_job["sourceRecordId"] == "foundation-linear-baseline"
        @test retraining_job["executionEvidence"]["orchestrationMode"] == "worker_service_tick"
        @test retraining_job["executionEvidence"]["dispatchStatus"] == "completed"
        @test retraining_payload["lifecycleRecord"]["validationEvidence"]["retrainingExecutionId"] == retraining_job["executionEvidence"]["executionId"]
        retraining_registry_record = first(filter(
            record -> String(get(record, "modelId", "")) == "foundation-linear-baseline",
            retraining_payload["project"]["modelRegistryRecords"],
        ))
        @test retraining_registry_record["status"] == "retraining_requested"
        @test retraining_registry_record["retrainingTrainingPlanId"] == retraining_training_plan["trainingPlanId"]
        @test retraining_registry_record["retrainingTuningStudyId"] == retraining_tuning_study["tuningStudyId"]
        retraining_lifecycle_job = first(filter(job -> job["jobType"] == "model_lifecycle", retraining_payload["project"]["projectJobs"]))
        @test retraining_lifecycle_job["executionEvidence"]["orchestrationMode"] == "worker_service_tick"
        @test retraining_lifecycle_job["executionEvidence"]["dispatchStatus"] == "completed"
        @test retraining_lifecycle_job["executionEvidence"]["workerPool"] == retraining_lifecycle_job["resourceEvidence"]["workerPool"]
        retraining_execution = first(filter(
            execution -> execution.execution_id == retraining_job["executionEvidence"]["executionId"],
            state.executions,
        ))
        @test retraining_execution.metadata["data_science_project_worker_state"]["job_type"] == "retraining"
        @test retraining_execution.metadata["data_science_project_worker_state"]["status"] == "completed"
        retraining_lifecycle_execution = first(filter(
            execution -> execution.execution_id == retraining_lifecycle_job["executionEvidence"]["executionId"],
            state.executions,
        ))
        @test retraining_lifecycle_execution.metadata["data_science_project_worker_state"]["job_type"] == "model_lifecycle"
        @test retraining_lifecycle_execution.metadata["data_science_project_worker_state"]["status"] == "completed"
        @test model_lifecycle_archive_too_early_response.status == 400
        @test occursin("archive requires deprecated", String(model_lifecycle_archive_too_early_response.body))
        @test model_lifecycle_deprecated_response.status == 201
        deprecated_payload = JSON3.read(String(model_lifecycle_deprecated_response.body), Dict{String,Any})
        @test deprecated_payload["lifecycleRecord"]["state"] == "deprecated"
        @test deprecated_payload["lifecycleRecord"]["deprecationReason"] == "superseded by retraining review"
        deprecated_registry_record = first(filter(
            record -> String(get(record, "modelId", "")) == "foundation-linear-baseline",
            deprecated_payload["project"]["modelRegistryRecords"],
        ))
        @test deprecated_registry_record["status"] == "deprecated"
        @test model_lifecycle_archived_response.status == 201
        archived_payload = JSON3.read(String(model_lifecycle_archived_response.body), Dict{String,Any})
        @test archived_payload["lifecycleRecord"]["state"] == "archived"
        @test archived_payload["lifecycleRecord"]["archiveReason"] == "local archive after deprecation"
        archived_registry_record = first(filter(
            record -> String(get(record, "modelId", "")) == "foundation-linear-baseline",
            archived_payload["project"]["modelRegistryRecords"],
        ))
        @test archived_registry_record["status"] == "archived"
        @test archived_registry_record["validationEvidence"]["lifecycleAction"] == "archive_model"
        @test gpu_execute_response.status == 202
        @test gpu_execute_payload["status"] == "queued"
        @test gpu_execute_payload["dispatchLane"] == "gpu"
        @test gpu_execute_payload["dispatchWorkerPool"] == "alpha-gpu"
        @test startswith(gpu_execute_payload["workerId"], "gpu-worker-")
        worker_state = load_state(store_root)
        processed_gpu = JuliaFlowApiGateway.JuliaFlowWorkerService.process_gpu_worker_tick!(
            worker_state.worker_service,
            worker_state.executions;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        @test length(processed_gpu) >= 1
        promoted_gpu = processed_gpu[end]
        JuliaFlowApiGateway.save_execution!(worker_state.repository, promoted_gpu)
        changed_gpu = JuliaFlowApiGateway.sync_external_execution_updates!(state)
        @test any(execution.execution_id == gpu_execute_payload["executionId"] for execution in changed_gpu)
        synced_gpu_detail = JSON3.read(execution_detail_response(state, gpu_execute_payload["executionId"]), Dict{String,Any})
        @test synced_gpu_detail["status"] == "running"
        transition_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/executions/$(execute_payload_id)/status",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "status" => "queued",
                        "message" => "Queued for worker dispatch",
                        "metadata" => Dict("workerId" => "worker-foundation-1"),
                    ),
                ),
            ),
        )
        invalid_transition = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/executions/$(execute_payload_id)/status",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("status" => "accepted")),
            ),
        )
        execution_detail = route_request(state, HTTP.Request("GET", "/api/v1/executions/$(execute_payload_id)"))
        @test execution_list.status == 200
        @test occursin("\"items\":[", String(execution_list.body))
        @test transition_response.status == 200
        @test occursin("\"status\":\"queued\"", String(transition_response.body))
        @test occursin("\"workerId\":\"worker-foundation-1\"", String(transition_response.body))
        @test invalid_transition.status == 500
        @test occursin("invalid execution status transition", String(invalid_transition.body))
        @test execution_detail.status == 200
        @test occursin(execute_payload_id, String(execution_detail.body))
        @test occursin("\"status\":\"queued\"", String(execution_detail.body))
        @test checkpoint_post.status == 201
        @test occursin("cp/02-alpha-core", String(checkpoint_post.body))
        @test reproducibility_export_response.status == 200
        @test reproducibility_export_payload["bundle"]["schemaVersion"] == "juliaflow.reproducibility.v1"
        @test reproducibility_export_payload["bundle"]["workflow"]["workflowId"] == "wf-foundation"
        @test reproducibility_export_payload["bundle"]["checkpoint"]["tag"] == "cp/02-alpha-core"
        @test reproducibility_export_payload["bundle"]["dataReferences"][1]["datasetId"] == "foundation-sales-sample"
        @test reproducibility_export_payload["bundle"]["datasetCards"][1]["checksumSha256"] == reproducibility_export_payload["bundle"]["dataReferences"][1]["checksumSha256"]
        @test reproducibility_export_payload["bundle"]["packageEnvironment"]["offlineOnly"] == true
        @test reproducibility_export_payload["bundle"]["runtimeConfig"]["cloudCredentialsRequired"] == false
        @test reproducibility_export_payload["bundle"]["randomSeeds"]["modelSeed"] == 42
        @test reproducibility_export_payload["bundle"]["modelArtifact"]["modelId"] == "foundation-linear-baseline"
        @test reproducibility_export_payload["bundle"]["metrics"]["mae"] == 1.25
        @test reproducibility_export_payload["bundle"]["explainabilityOutputs"]["method"] == "deterministic_feature_contribution"
        @test reproducibility_export_payload["bundle"]["dashboardSnapshot"]["dashboardId"] == "dashboard-foundation"
        @test length(reproducibility_export_payload["bundle"]["bundleChecksumSha256"]) == 64
        @test visualize_checkpoint_export_response.status == 201
        @test visualize_checkpoint_export_payload["status"] == "exported"
        @test visualize_checkpoint_export_payload["export"]["workflowId"] == "wf-foundation"
        @test visualize_checkpoint_export_payload["export"]["dashboardId"] == "dashboard-foundation"
        @test visualize_checkpoint_export_payload["export"]["checkpointTag"] == "cp/visualize-export"
        @test visualize_checkpoint_export_payload["export"]["dashboardSnapshotReady"] == true
        @test length(visualize_checkpoint_export_payload["export"]["bundleChecksumSha256"]) == 64
        @test length(visualize_checkpoint_export_payload["export"]["artifactEvidence"]) == 3
        @test visualize_checkpoint_export_payload["checkpoint"]["tag"] == "cp/visualize-export"
        @test visualize_checkpoint_export_payload["dashboard"]["dashboardId"] == "dashboard-foundation"
        @test visualize_checkpoint_export_payload["bundle"]["dashboardSnapshot"]["dashboardId"] == "dashboard-foundation"
        @test reproducibility_import_response.status == 201
        reproducibility_import_payload = JSON3.read(String(reproducibility_import_response.body), Dict{String,Any})
        @test reproducibility_import_payload["status"] == "imported"
        @test reproducibility_import_payload["workflowId"] == "wf-foundation"
        @test reproducibility_import_payload["checkpointTag"] == "cp/02-alpha-core"
        @test reproducibility_import_payload["dashboardId"] == "dashboard-foundation"
        @test haskey(imported_reproducibility_state.workflows, "wf-foundation")
        @test imported_reproducibility_state.checkpoints[end].tag == "cp/02-alpha-core"
        @test haskey(imported_reproducibility_state.published_dashboards, "dashboard-foundation")
        @test reproducibility_import_tampered_response.status == 400
        @test occursin("reproducibility bundle checksum mismatch", String(reproducibility_import_tampered_response.body))
        @test local_backup_export_response.status == 200
        @test local_backup_export_payload["backup"]["schemaVersion"] == "juliaflow.backup.v1"
        @test local_backup_export_payload["backup"]["workflows"][1]["workflowId"] == "wf-foundation"
        @test any(item -> item["tag"] == "cp/02-alpha-core", local_backup_export_payload["backup"]["checkpoints"])
        @test any(item -> item["dashboardId"] == "dashboard-foundation", local_backup_export_payload["backup"]["publishedDashboards"])
        @test length(local_backup_export_payload["backup"]["backupChecksumSha256"]) == 64
        @test local_backup_import_response.status == 201
        local_backup_import_payload = JSON3.read(String(local_backup_import_response.body), Dict{String,Any})
        @test local_backup_import_payload["status"] in ["restored", "restored_with_missing_artifacts"]
        @test local_backup_import_payload["backupId"] == local_backup_export_payload["backup"]["backupId"]
        @test "wf-foundation" in local_backup_import_payload["restored"]["workflows"]
        @test "cp/02-alpha-core" in local_backup_import_payload["restored"]["checkpoints"]
        @test "dashboard-foundation" in local_backup_import_payload["restored"]["publishedDashboards"]
        @test haskey(imported_backup_state.workflows, "wf-foundation")
        @test any(item -> item.tag == "cp/02-alpha-core", imported_backup_state.checkpoints)
        @test haskey(imported_backup_state.published_dashboards, "dashboard-foundation")
        @test local_backup_import_tampered_response.status == 400
        @test occursin("local backup checksum mismatch", String(local_backup_import_tampered_response.body))
        @test import_post.status == 201
        @test occursin("wf-parallel", String(import_post.body))
        @test preflight.status == 204
        @test any(header -> header.first == "Access-Control-Allow-Origin" && header.second == "*", preflight.headers)
        @test any(header -> header.first == "Access-Control-Allow-Methods" && occursin("OPTIONS", header.second), preflight.headers)
        @test missing_route.status == 404
        @test any(header -> header.first == "Access-Control-Allow-Origin" && header.second == "*", health_response.headers)
    end
end

@testset "API Gateway Realtime" begin
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")

    withenv("JULIAFLOW_EVENT_BACKBONE_MODE" => "dual_write") do
        mktempdir() do store_root
            state = foundation_state(foundation_path; store_root = store_root)
            JuliaFlowApiGateway.import_workflow_response!(state; source_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "parallel.workflow.toml"))
            socket = FakeRealtimeSocket(String[])
        canvas_response, canvas_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 1,
                    "method" => "canvas.subscribe",
                    "params" => Dict("workflowId" => "wf-foundation"),
                ),
            ),
            socket,
        )
        canvas_reply = JSON3.read(String(canvas_response), Dict{String,Any})
        workflow_event = JSON3.read(canvas_notifications[1], Dict{String,Any})
        node_event = JSON3.read(canvas_notifications[2], Dict{String,Any})

        @test canvas_reply["result"]["subscriptionId"] isa AbstractString
        @test workflow_event["method"] == "workflow.state.changed"
        @test workflow_event["params"]["workflowId"] == "wf-foundation"
        @test node_event["method"] == "node.state.changed"

        dashboard_response, dashboard_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 2,
                    "method" => "dashboard.subscribe",
                    "params" => Dict("dashboardId" => "ops-forecast", "outletIds" => ["bi-main"]),
                ),
            ),
        )
        dashboard_reply = JSON3.read(String(dashboard_response), Dict{String,Any})
        dashboard_event = JSON3.read(dashboard_notifications[1], Dict{String,Any})

        @test dashboard_reply["result"]["subscriptionId"] isa AbstractString
        @test dashboard_event["method"] == "dashboard.outlet.updated"
        @test dashboard_event["params"]["dashboardId"] == "ops-forecast"

        execute_response, execute_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 3,
                    "method" => "workflow.execute",
                    "params" => Dict(
                        "workflowId" => "wf-foundation",
                        "executionMode" => "cpu_only",
                        "flowVariables" => Dict("JULIAFLOW_GPU_DEVICE" => "cpu-fallback"),
                    ),
                ),
            ),
        )
        execute_reply = JSON3.read(String(execute_response), Dict{String,Any})

        @test execute_reply["result"]["status"] == "accepted"
        @test execute_reply["result"]["jobId"] isa AbstractString
        @test isempty(execute_notifications)
        execution_record = JSON3.read(execution_detail_response(state, execute_reply["result"]["jobId"]), Dict{String,Any})
        @test execution_record["requested_execution_mode"] == "cpu_only"
        @test execution_record["flow_variables"]["JULIAFLOW_GPU_DEVICE"] == "cpu-fallback"
        @test execution_record["resourcePlan"][1]["lane"] == "cpu"

        gpu_create_response = JuliaFlowApiGateway.create_workflow_response_from_body!(
            state,
            Dict(
                "workflow" => Dict(
                    "version" => "0.3.0",
                    "workflowId" => "wf-gpu-alpha",
                    "name" => "GPU Alpha",
                    "flowVariables" => [Dict("name" => "JULIAFLOW_GPU_DEVICE", "type" => "GPUDeviceID", "default" => "nvidia:0")],
                    "runtime" => Dict("runMode" => "batch"),
                    "nodes" => [
                        Dict(
                            "id" => "node-source",
                            "type" => "JuliaFlow.Base.CSVReader",
                            "name" => "CSV Reader",
                            "executionHint" => "cpu_only",
                            "capabilities" => Dict("executionMode" => "batch", "resourceClass" => "cpu", "workerPool" => "alpha-cpu"),
                            "ports" => [Dict("id" => "out", "direction" => "output", "type" => "data_table")],
                            "config" => Dict("path" => "assets/sample.csv"),
                        ),
                        Dict(
                            "id" => "node-train",
                            "type" => "JuliaFlow.Base.ModelTrain",
                            "name" => "GPU Trainer",
                            "executionHint" => "gpu_required",
                            "capabilities" => Dict(
                                "executionMode" => "batch",
                                "resourceClass" => "gpu",
                                "accelerator" => "cuda",
                                "workerPool" => "alpha-gpu",
                            ),
                            "ports" => [
                                Dict("id" => "in", "direction" => "input", "type" => "data_table"),
                                Dict("id" => "model", "direction" => "output", "type" => "model"),
                            ],
                            "config" => Dict("target" => "amount", "gpuDevicePreference" => "nvidia:0"),
                        ),
                    ],
                    "connections" => [
                        Dict(
                            "sourceNodeId" => "node-source",
                            "sourcePortId" => "out",
                            "targetNodeId" => "node-train",
                            "targetPortId" => "in",
                            "dataType" => "data_table",
                        ),
                    ],
                ),
            ),
        )
        @test occursin("\"status\":\"created\"", gpu_create_response)

        gpu_execute_response, gpu_execute_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 40,
                    "method" => "workflow.execute",
                    "params" => Dict("workflowId" => "wf-gpu-alpha", "executionMode" => "gpu_required"),
                ),
            ),
        )
        gpu_execute_reply = JSON3.read(String(gpu_execute_response), Dict{String,Any})
        @test gpu_execute_reply["result"]["status"] == "queued"
        @test isempty(gpu_execute_notifications)
        gpu_execution_record = JSON3.read(execution_detail_response(state, gpu_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test gpu_execution_record["dispatchLane"] == "gpu"
        @test gpu_execution_record["dispatchWorkerPool"] == "alpha-gpu"
        @test gpu_execution_record["dispatchIsolationMode"] == "isolated"
        @test startswith(gpu_execution_record["workerId"], "gpu-worker-")

        gpu_canvas_response, _ = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 41,
                    "method" => "canvas.subscribe",
                    "params" => Dict("workflowId" => "wf-gpu-alpha"),
                ),
            ),
            socket,
        )
        @test JSON3.read(String(gpu_canvas_response), Dict{String,Any})["result"]["subscriptionId"] isa AbstractString
        gpu_worker_state = load_state(store_root)
        processed_gpu = JuliaFlowApiGateway.JuliaFlowWorkerService.process_gpu_worker_tick!(
            gpu_worker_state.worker_service,
            gpu_worker_state.executions;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        @test length(processed_gpu) >= 1
        for execution in processed_gpu
            JuliaFlowApiGateway.save_execution!(gpu_worker_state.repository, execution)
        end
        changed_gpu = JuliaFlowApiGateway.sync_external_execution_updates!(state)
        @test any(execution.execution_id == gpu_execute_reply["result"]["jobId"] for execution in changed_gpu)
        synced_gpu_record = JSON3.read(execution_detail_response(state, gpu_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test synced_gpu_record["status"] == "running"
        @test any(
            occursin("\"method\":\"execution.state.changed\"", message) &&
                occursin("\"executionId\":\"" * gpu_execute_reply["result"]["jobId"] * "\"", message) &&
                occursin("\"status\":\"running\"", message)
            for message in socket.messages
        )
        completed_gpu = JuliaFlowApiGateway.JuliaFlowWorkerService.process_gpu_compute_tick!(
            gpu_worker_state.worker_service,
            state.workflows,
            gpu_worker_state.executions;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        @test length(completed_gpu) >= 1
        for execution in completed_gpu
            JuliaFlowApiGateway.save_execution!(gpu_worker_state.repository, execution)
        end
        changed_gpu_complete = JuliaFlowApiGateway.sync_external_execution_updates!(state)
        @test any(execution.execution_id == gpu_execute_reply["result"]["jobId"] for execution in changed_gpu_complete)
        completed_gpu_record = JSON3.read(execution_detail_response(state, gpu_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test completed_gpu_record["status"] == "completed"
        @test completed_gpu_record["gpuExecutionPath"] == "gpu"
        @test completed_gpu_record["gpuWorkloadResult"]["sum"] == 10.0

        stream_execute_response, stream_execute_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 4,
                    "method" => "workflow.execute",
                    "params" => Dict("workflowId" => "wf-parallel"),
                ),
            ),
        )
        stream_execute_reply = JSON3.read(String(stream_execute_response), Dict{String,Any})
        @test stream_execute_reply["result"]["status"] == "running"
        @test isempty(stream_execute_notifications)
        stream_record = JSON3.read(execution_detail_response(state, stream_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test stream_record["streamLifecycleStatus"] == "active"

        pause_response, pause_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 5,
                    "method" => "workflow.pause",
                    "params" => Dict("workflowId" => "wf-parallel"),
                ),
            ),
        )
        pause_reply = JSON3.read(String(pause_response), Dict{String,Any})
        @test pause_reply["result"]["status"] == "paused"
        @test isempty(pause_notifications)
        paused_record = JSON3.read(execution_detail_response(state, stream_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test paused_record["streamLifecycleStatus"] == "paused"

        resume_response, resume_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 6,
                    "method" => "workflow.resume",
                    "params" => Dict("workflowId" => "wf-parallel"),
                ),
            ),
        )
        resume_reply = JSON3.read(String(resume_response), Dict{String,Any})
        @test resume_reply["result"]["status"] == "active"
        @test isempty(resume_notifications)
        resumed_record = JSON3.read(execution_detail_response(state, stream_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test resumed_record["streamLifecycleStatus"] == "active"

        stream_canvas_response, _ = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 7,
                    "method" => "canvas.subscribe",
                    "params" => Dict("workflowId" => "wf-parallel"),
                ),
            ),
            socket,
        )
        @test JSON3.read(String(stream_canvas_response), Dict{String,Any})["result"]["subscriptionId"] isa AbstractString

        stop_response, stop_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 8,
                    "method" => "workflow.stop",
                    "params" => Dict("workflowId" => "wf-parallel"),
                ),
            ),
        )
        stop_reply = JSON3.read(String(stop_response), Dict{String,Any})
        @test stop_reply["result"]["status"] == "stopped"
        @test isempty(stop_notifications)
        stopped_record = JSON3.read(execution_detail_response(state, stream_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test stopped_record["streamLifecycleStatus"] == "stopped"
        @test stopped_record["status"] == "completed"
        checkpoint_payload = JuliaFlowApiGateway.streaming_checkpoint_completed_payload(state, "wf-parallel", state.executions[end])
        @test haskey(checkpoint_payload, "consumerLag")
        @test haskey(checkpoint_payload["offsets"], "lastProcessedAt")
        JuliaFlowApiGateway.consume_gateway_events!(state)
        @test any(occursin("\"method\":\"streaming.checkpoint.completed\"", message) for message in socket.messages)

            withenv("JULIAFLOW_STREAM_WORKER_MODE" => "process") do
                external_socket = FakeRealtimeSocket(String[])
                external_canvas_response, _ = JuliaFlowApiGateway.handle_realtime_request!(
                    state,
                    JSON3.write(
                        Dict(
                            "jsonrpc" => "2.0",
                            "id" => 9,
                            "method" => "canvas.subscribe",
                            "params" => Dict("workflowId" => "wf-parallel"),
                        ),
                    ),
                    external_socket,
                )
                @test JSON3.read(String(external_canvas_response), Dict{String,Any})["result"]["subscriptionId"] isa AbstractString

                queued_stream_response, queued_stream_notifications = JuliaFlowApiGateway.handle_realtime_request!(
                    state,
                    JSON3.write(
                        Dict(
                            "jsonrpc" => "2.0",
                            "id" => 10,
                            "method" => "workflow.execute",
                            "params" => Dict("workflowId" => "wf-parallel"),
                        ),
                    ),
                )
                queued_stream_reply = JSON3.read(String(queued_stream_response), Dict{String,Any})
                @test queued_stream_reply["result"]["status"] == "queued"
                @test isempty(queued_stream_notifications)

                worker_state = load_state(store_root)
                processed_streams = JuliaFlowApiGateway.JuliaFlowWorkerService.process_stream_worker_tick!(
                    worker_state.worker_service,
                    worker_state.executions;
                    execution_record = JuliaFlowApiGateway.execution_record,
                    transition_execution_record = transition_execution_record,
                    materialize_execution = JuliaFlowApiGateway.materialize_execution,
                )
                @test length(processed_streams) >= 1
                for execution in processed_streams
                    JuliaFlowApiGateway.save_execution!(worker_state.repository, execution)
                end

                changed_executions = JuliaFlowApiGateway.sync_external_execution_updates!(state)
                @test any(execution.execution_id == queued_stream_reply["result"]["jobId"] for execution in changed_executions)

                synced_stream_record = JSON3.read(execution_detail_response(state, queued_stream_reply["result"]["jobId"]), Dict{String,Any})
                @test synced_stream_record["status"] == "running"
                @test synced_stream_record["streamLifecycleStatus"] == "active"
                @test any(
                    occursin("\"method\":\"execution.state.changed\"", message) &&
                        occursin("\"executionId\":\"" * queued_stream_reply["result"]["jobId"] * "\"", message) &&
                        occursin("\"status\":\"running\"", message)
                    for message in external_socket.messages
                )
            end
        end
    end

    withenv(
        "JULIAFLOW_EVENT_BACKBONE_MODE" => "dual_write",
        "JULIAFLOW_STREAM_WORKER_MODE" => "process",
    ) do
        mktempdir() do store_root
            state = foundation_state(foundation_path; store_root = store_root)
            JuliaFlowApiGateway.import_workflow_response!(state; source_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "parallel.workflow.toml"))
            socket = FakeRealtimeSocket(String[])
            canvas_response, _ = JuliaFlowApiGateway.handle_realtime_request!(
                state,
                JSON3.write(
                    Dict(
                        "jsonrpc" => "2.0",
                        "id" => 101,
                        "method" => "canvas.subscribe",
                        "params" => Dict("workflowId" => "wf-parallel"),
                    ),
                ),
                socket,
            )
            @test JSON3.read(String(canvas_response), Dict{String,Any})["result"]["subscriptionId"] isa AbstractString

            queued_stream_response, _ = JuliaFlowApiGateway.handle_realtime_request!(
                state,
                JSON3.write(
                    Dict(
                        "jsonrpc" => "2.0",
                        "id" => 102,
                        "method" => "workflow.execute",
                        "params" => Dict("workflowId" => "wf-parallel"),
                    ),
                ),
            )
            queued_stream_reply = JSON3.read(String(queued_stream_response), Dict{String,Any})
            @test queued_stream_reply["result"]["jobId"] isa AbstractString
            @test isempty(socket.messages)

            queued_events = JuliaFlowApiGateway.consume_gateway_events!(state)
            @test any(event.event_type == "execution.changed" for event in queued_events)
            @test any(
                occursin("\"method\":\"execution.state.changed\"", message) &&
                    occursin("\"executionId\":\"" * queued_stream_reply["result"]["jobId"] * "\"", message)
                for message in socket.messages
            )
            message_count_after_consume = length(socket.messages)
            @test isempty(JuliaFlowApiGateway.sync_external_execution_updates!(state))
            @test length(socket.messages) == message_count_after_consume

            worker_state = load_state(store_root)
            processed_streams = JuliaFlowApiGateway.JuliaFlowWorkerService.process_stream_worker_tick!(
                worker_state.worker_service,
                worker_state.executions;
                execution_record = JuliaFlowApiGateway.execution_record,
                transition_execution_record = transition_execution_record,
                materialize_execution = JuliaFlowApiGateway.materialize_execution,
            )
            @test length(processed_streams) >= 1
            for execution in processed_streams
                JuliaFlowApiGateway.save_execution!(worker_state.repository, execution; producer = "stream-worker")
            end

            consumed = JuliaFlowApiGateway.consume_gateway_events!(state)
            @test any(event.producer == "stream-worker" for event in consumed)
            synced_stream_record = JSON3.read(execution_detail_response(state, queued_stream_reply["result"]["jobId"]), Dict{String,Any})
            @test synced_stream_record["status"] == "running"
            @test synced_stream_record["streamLifecycleStatus"] == "active"
            message_count_after_worker_consume = length(socket.messages)
            @test isempty(JuliaFlowApiGateway.sync_external_execution_updates!(state))
            @test length(socket.messages) == message_count_after_worker_consume

            duplicate = JuliaFlowApiGateway.JuliaFlowGatewayRepository.append_event!(
                state.repository,
                "execution.changed";
                aggregate_type = "execution",
                aggregate_id = queued_stream_reply["result"]["jobId"],
                payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(synced_stream_record)),
                producer = "test-suite",
                event_id = "dup-event-001",
            )
            JuliaFlowApiGateway.process_gateway_event!(state, duplicate)
            message_count = length(socket.messages)
            @test !JuliaFlowApiGateway.process_gateway_event!(state, duplicate)
            @test length(socket.messages) == message_count

            restarted = load_state(store_root)
            restarted_socket = FakeRealtimeSocket(String[])
            JuliaFlowApiGateway.handle_realtime_request!(
                restarted,
                JSON3.write(
                    Dict(
                        "jsonrpc" => "2.0",
                        "id" => 103,
                        "method" => "canvas.subscribe",
                        "params" => Dict("workflowId" => "wf-parallel"),
                    ),
                ),
                restarted_socket,
            )
            replayed = JuliaFlowApiGateway.consume_gateway_events!(restarted)
            @test length(replayed) == 1
            @test replayed[1].event_id == "dup-event-001"
            @test isempty(JuliaFlowApiGateway.consume_gateway_events!(restarted))
        end
    end
end

@testset "Base Extension" begin
    @test haskey(available_nodes(), DEFAULT_NODE_KEY)
    result = execute_passthrough("memory://foundation.arrow")
    @test result.outputs[DEFAULT_OUTPUT_PORT_ID].ref == "memory://foundation.arrow"
end

@testset "Gateway Audit Events" begin
    store_root = mktempdir()
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    state = foundation_state(foundation_path; store_root = store_root)

    create_body = JSON3.write(
        Dict(
            "workflow" => Dict(
                "workflowId" => "wf-audit",
                "name" => "Audit Workflow",
                "version" => "0.1.0",
                "nodes" => Any[
                    Dict(
                        "id" => "node-source",
                        "name" => "Source",
                        "type" => "source.table",
                        "executionHint" => "cpu_only",
                        "config" => Dict("ref" => "memory://audit.arrow"),
                        "ports" => Any[
                            Dict("id" => "table_out", "direction" => "output", "type" => "data_table", "label" => "Table Out"),
                        ],
                    ),
                ],
                "connections" => Any[],
                "flowVariables" => Any[],
            ),
        ),
    )

    create_response = route_request(
        state,
        HTTP.Request("POST", "/api/v1/workflows", ["Content-Type" => "application/json"], create_body),
    )
    @test create_response.status == 201

    execute_response = route_request(
        state,
        HTTP.Request(
            "POST",
            "/api/v1/workflows/wf-audit/execute",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("executionMode" => "cpu_only")),
        ),
    )
    @test execute_response.status == 202

    checkpoint_response = route_request(
        state,
        HTTP.Request(
            "POST",
            "/api/v1/checkpoints",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("tag" => "cp/audit-events", "summary" => "audit checkpoint")),
        ),
    )
    @test checkpoint_response.status == 201

    events = JuliaFlowApiGateway.JuliaFlowGatewayRepository.load_events(state.repository)
    audit_events = filter(event -> event.event_type == "audit.action", events)
    @test length(audit_events) >= 3
    @test any(event.payload["action"] == "workflow.create" && event.aggregate_id == "wf-audit" for event in audit_events)
    @test any(event.payload["action"] == "workflow.execute" && event.aggregate_id == "wf-audit" for event in audit_events)
    @test any(event.payload["action"] == "checkpoint.create" && event.aggregate_id == "cp/audit-events" for event in audit_events)
    @test all(haskey(event.payload, "authContext") for event in audit_events)
end

@testset "Gateway OIDC RBAC Policy" begin
    store_root = mktempdir()
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    state = foundation_state(foundation_path; store_root = store_root)

    owner_token = test_hs256_jwt(
        Dict{String,Any}(
            "iss" => "https://issuer.test",
            "aud" => "juliaflow-gateway",
            "sub" => "user-owner",
            "juliaflow_workspace" => "workspace-a",
            "juliaflow_role" => "owner",
            "exp" => 4102444800,
        ),
    )
    viewer_claims_owner_token = test_hs256_jwt(
        Dict{String,Any}(
            "iss" => "https://issuer.test",
            "aud" => "juliaflow-gateway",
            "sub" => "user-viewer",
            "juliaflow_workspace" => "workspace-a",
            "juliaflow_role" => "owner",
            "exp" => 4102444800,
        ),
    )
    disabled_user_token = test_hs256_jwt(
        Dict{String,Any}(
            "iss" => "https://issuer.test",
            "aud" => "juliaflow-gateway",
            "sub" => "user-disabled",
            "juliaflow_workspace" => "workspace-a",
            "juliaflow_role" => "owner",
            "exp" => 4102444800,
        ),
    )
    keycloak_style_owner_token = test_hs256_jwt(
        Dict{String,Any}(
            "iss" => "https://issuer.test",
            "aud" => "juliaflow-gateway",
            "sub" => "user-keycloak-owner",
            "realm_access" => Dict("roles" => ["default-roles-juliaflow", "owner"]),
            "exp" => 4102444800,
        ),
    )
    wrong_signature_token = string(viewer_claims_owner_token[1:end-2], "xx")

    env_pairs = (
        "JULIAFLOW_AUTH_MODE" => "oidc",
        "JULIAFLOW_OIDC_ISSUER" => "https://issuer.test",
        "JULIAFLOW_OIDC_AUDIENCE" => "juliaflow-gateway",
        "JULIAFLOW_OIDC_HS256_SECRET" => "oidc-secret",
    )

    missing_token_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows"))
    end
    invalid_token_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(wrong_signature_token)"]))
    end
    keycloak_role_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(keycloak_style_owner_token)", "X-JuliaFlow-Workspace" => "workspace-a"]),
        )
    end
    directory_body = Dict(
        "users" => Any[
            Dict("principalId" => "user-owner", "displayName" => "Owner User", "email" => "owner@example.test", "active" => true),
            Dict("principalId" => "user-viewer", "displayName" => "Viewer User", "active" => true),
            Dict("principalId" => "user-disabled", "displayName" => "Disabled User", "active" => false),
        ],
        "workspaces" => Any[
            Dict("workspaceId" => "workspace-a", "name" => "Workspace A", "active" => true),
        ],
    )
    save_directory_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request(
                "PUT",
                "/api/v1/admin/auth/directory",
                ["Authorization" => "Bearer $(owner_token)", "Content-Type" => "application/json"],
                JSON3.write(directory_body),
            ),
        )
    end
    lockout_directory_body = Dict(
        "users" => Any[
            Dict("principalId" => "user-viewer", "displayName" => "Viewer User", "active" => true),
        ],
        "workspaces" => Any[
            Dict("workspaceId" => "workspace-a", "name" => "Workspace A", "active" => true),
        ],
    )
    lockout_directory_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request(
                "PUT",
                "/api/v1/admin/auth/directory",
                ["Authorization" => "Bearer $(owner_token)", "Content-Type" => "application/json"],
                JSON3.write(lockout_directory_body),
            ),
        )
    end
    get_directory_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request("GET", "/api/v1/admin/auth/directory", ["Authorization" => "Bearer $(owner_token)"]),
        )
    end
    disabled_user_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(disabled_user_token)"]),
        )
    end
    policy_body = Dict(
        "roleBindings" => Any[
            Dict("principalId" => "user-viewer", "workspaceId" => "workspace-a", "role" => "viewer"),
        ],
        "resourcePolicies" => Any[
            Dict(
                "resourceType" => "workflow",
                "resourceId" => "wf-foundation",
                "workspaceId" => "workspace-a",
                "permissionsByRole" => Dict("viewer" => ["workflow:read"]),
            ),
        ],
    )
    invalid_directory_policy_body = Dict(
        "roleBindings" => Any[
            Dict("principalId" => "user-disabled", "workspaceId" => "workspace-a", "role" => "viewer"),
        ],
        "resourcePolicies" => Any[],
    )
    save_policy_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request(
                "PUT",
                "/api/v1/admin/auth/policies",
                ["Authorization" => "Bearer $(owner_token)", "Content-Type" => "application/json"],
                JSON3.write(policy_body),
            ),
        )
    end
    invalid_directory_policy_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request(
                "PUT",
                "/api/v1/admin/auth/policies",
                ["Authorization" => "Bearer $(owner_token)", "Content-Type" => "application/json"],
                JSON3.write(invalid_directory_policy_body),
            ),
        )
    end
    get_policy_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request("GET", "/api/v1/admin/auth/policies", ["Authorization" => "Bearer $(owner_token)"]),
        )
    end
    viewer_read_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request("GET", "/api/v1/workflows/wf-foundation", ["Authorization" => "Bearer $(viewer_claims_owner_token)"]),
        )
    end
    viewer_execute_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/execute",
                ["Authorization" => "Bearer $(viewer_claims_owner_token)", "Content-Type" => "application/json"],
                JSON3.write(Dict()),
            ),
        )
    end
    audit_query_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request("GET", "/api/v1/audit/actions?targetType=auth_policy&limit=10", ["Authorization" => "Bearer $(owner_token)"]),
        )
    end

    @test missing_token_response.status == 401
    @test occursin("OIDC bearer token is required", String(missing_token_response.body))
    @test invalid_token_response.status == 401
    @test occursin("invalid OIDC token signature", String(invalid_token_response.body))
    @test keycloak_role_response.status == 200
    @test save_directory_response.status == 200
    @test occursin("user-viewer", String(save_directory_response.body))
    @test lockout_directory_response.status == 400
    @test occursin("admin principal not active in directory", String(lockout_directory_response.body))
    @test get_directory_response.status == 200
    @test occursin("Workspace A", String(get_directory_response.body))
    @test disabled_user_response.status == 403
    @test occursin("principal not active in directory", String(disabled_user_response.body))
    @test save_policy_response.status == 200
    @test occursin("user-viewer", String(save_policy_response.body))
    @test invalid_directory_policy_response.status == 400
    @test occursin("role binding principal not active in directory", String(invalid_directory_policy_response.body))
    @test get_policy_response.status == 200
    @test occursin("resourcePolicies", String(get_policy_response.body))
    @test viewer_read_response.status == 200
    @test viewer_execute_response.status == 403
    @test occursin("permission denied: workflow:execute", String(viewer_execute_response.body))
    @test audit_query_response.status == 200
    audit_payload = JSON3.read(String(audit_query_response.body), Dict{String,Any})
    @test audit_payload["count"] >= 1
    @test any(event["action"] == "auth.policy.update" for event in audit_payload["events"])
    @test !occursin("oidc-secret", String(audit_query_response.body))
    @test isfile(joinpath(store_root, "auth-policy.json"))
    @test isfile(joinpath(store_root, "auth-directory.json"))
end

@testset "Gateway OIDC JWKS Rotation" begin
    store_root = mktempdir()
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    state = foundation_state(foundation_path; store_root = store_root)
    jwks_path = joinpath(store_root, "jwks.json")
    discovery_path = joinpath(store_root, "openid-configuration.json")

    write(
        discovery_path,
        JSON3.write(Dict("issuer" => "https://issuer.test", "jwks_uri" => jwks_path)),
    )
    write(jwks_path, JSON3.write(Dict("keys" => [test_oct_jwk("kid-old", "old-secret")])) )

    claims = Dict{String,Any}(
        "iss" => "https://issuer.test",
        "aud" => "juliaflow-gateway",
        "sub" => "user-owner",
        "juliaflow_workspace" => "workspace-a",
        "juliaflow_role" => "owner",
        "exp" => 4102444800,
    )
    old_token = test_hs256_jwt(claims; secret = "old-secret", kid = "kid-old")
    new_token = test_hs256_jwt(claims; secret = "new-secret", kid = "kid-new")

    env_pairs = (
        "JULIAFLOW_AUTH_MODE" => "oidc",
        "JULIAFLOW_OIDC_DISCOVERY_PATH" => discovery_path,
        "JULIAFLOW_OIDC_AUDIENCE" => "juliaflow-gateway",
        "JULIAFLOW_OIDC_ALLOWED_ALGORITHMS" => "HS256",
    )

    old_key_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(old_token)"]))
    end
    missing_key_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(new_token)"]))
    end

    write(jwks_path, JSON3.write(Dict("keys" => [test_oct_jwk("kid-new", "new-secret")])) )

    rotated_old_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(old_token)"]))
    end
    rotated_new_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(new_token)"]))
    end

    @test old_key_response.status == 200
    @test missing_key_response.status == 401
    @test occursin("OIDC JWKS key not found: kid-new", String(missing_key_response.body))
    @test rotated_old_response.status == 401
    @test occursin("OIDC JWKS key not found: kid-old", String(rotated_old_response.body))
    @test rotated_new_response.status == 200
end

@testset "Gateway OIDC RS256 JWKS" begin
    store_root = mktempdir()
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    state = foundation_state(foundation_path; store_root = store_root)
    jwks_path = joinpath(store_root, "jwks-rs256.json")
    discovery_path = joinpath(store_root, "openid-configuration-rs256.json")

    rsa_modulus = "kuIo4j5IbOMTRjVQWeMj6N6SyIF2Q9yLuGvmhZquzGGF9YubMVj9NPlRUk2vsB6pHd-FOE1WANIgdduQUkdJCJYuIWcQ1yV039DFdJs7IwkcSOCrA70ML7MItFupK2eV6D7llqgZoOG2n1Xfa5EATUZtqVHGoprYXMhgFatDXq5_6Ssl8tRrpoS2Gwzu6DPFDtZWnu598BzFLsKFYmNyk5UTKT6l76T79HuzGdiienfHp-Rq-IgEN3TJtVQgxAZclDfoHEHbTAGaLfHbAGC-wXmviRY9sNkhnDivoU0X6_tY44GzkQXe_5BX2xAjZAGqHckTsvwGzVI9MAWdZGq8YQ"
    rsa_exponent = "AQAB"
    rs256_token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6InJzYS1saXZlLXRlc3QifQ.eyJpc3MiOiJodHRwczovL2lzc3Vlci50ZXN0IiwiYXVkIjoianVsaWFmbG93LWdhdGV3YXkiLCJzdWIiOiJ1c2VyLW93bmVyIiwianVsaWFmbG93X3dvcmtzcGFjZSI6IndvcmtzcGFjZS1hIiwianVsaWFmbG93X3JvbGUiOiJvd25lciIsImV4cCI6NDEwMjQ0NDgwMH0.VxYxaMFtZ4INHQBa8oat21Q5q5oTT-Eqb8lvqBlvIyFqlVuJ2XZjCUQMq0JioA7PsPrCvWcavFkFOBNYavrtvMfGKCQnB29hy_AonuUriwtIP6JxFBhtl6M_2pQiQb_qjKah-j3OVw-BKmOiB3NLAku9cWHdIURz-altxrINzkiYqvfGaQciznCz4xjiv6Is2r28IDSCFIksQeMcYYOmkDgs_QCklwISt4r69A1TEL3QrYjnW7--oU9W2MsuBjqahtN5oJejyeFBEPHqUx6cWIrRRdh_UAQWSe-aPYIDBJiPJW2aiF898DNMr99aOf1er_LAq1b1DCMORes-A9O4YQ"
    tampered_token = string(rs256_token[1:end-2], "xx")

    write(
        discovery_path,
        JSON3.write(Dict("issuer" => "https://issuer.test", "jwks_uri" => jwks_path)),
    )
    write(
        jwks_path,
        JSON3.write(
            Dict(
                "keys" => [
                    Dict(
                        "kty" => "RSA",
                        "kid" => "rsa-live-test",
                        "alg" => "RS256",
                        "use" => "sig",
                        "n" => rsa_modulus,
                        "e" => rsa_exponent,
                    ),
                ],
            ),
        ),
    )

    env_pairs = (
        "JULIAFLOW_AUTH_MODE" => "oidc",
        "JULIAFLOW_OIDC_DISCOVERY_PATH" => discovery_path,
        "JULIAFLOW_OIDC_AUDIENCE" => "juliaflow-gateway",
        "JULIAFLOW_OIDC_ALLOWED_ALGORITHMS" => "RS256",
    )

    valid_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(rs256_token)"]))
    end
    tampered_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(tampered_token)"]))
    end

    @test valid_response.status == 200
    @test occursin("wf-foundation", String(valid_response.body))
    @test tampered_response.status == 401
    @test occursin("invalid OIDC token signature", String(tampered_response.body))
end
