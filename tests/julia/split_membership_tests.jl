splits = JuliaFlowApiGateway.JuliaFlowDataScienceProjectSplits
tuning = JuliaFlowApiGateway.JuliaFlowDataScienceProjectTuning
transforms = JuliaFlowApiGateway.JuliaFlowDataScienceProjectTransforms
repo_module = JuliaFlowApiGateway.JuliaFlowGatewayRepository
root = mktempdir()
source_path = joinpath(root, "source.csv")
headers = ["x", "y", "group", "time", "depth"]
data_rows = [[string(i), string(i % 2), "group-$(i % 10)", "2026-01-$(lpad(string(31-i), 2, '0'))", string(31-i)] for i in 1:30]
write_table(rows) = write(source_path, join(headers, ',') * "\n" * join([join(row, ',') for row in rows], "\n") * "\n")
write_table(data_rows)
table = splits.split_table(source_path)
plan = Dict{String,Any}("splitPlanId" => "split-proof", "datasetId" => "data-proof", "strategy" => "random",
    "trainFraction" => 0.6, "validationFraction" => 0.2, "testFraction" => 0.2, "locked" => true, "seed" => 42,
    "createdAt" => "2026-09-20T00:00:00Z")
for strategy in ("random", "stratified", "grouped", "time", "depth")
    strategy_plan = merge(plan, Dict("strategy" => strategy, "groupColumn" => "group", "timeColumn" => "time", "depthColumn" => "depth"))
    rows = splits.split_rows(table, strategy_plan, "y")
    @test sort(vcat(values(rows)...)) == collect(1:30)
    @test isempty(intersect(rows["train"], rows["validation"]))
    @test isempty(intersect(rows["train"], rows["test"]))
    @test rows == splits.split_rows(table, strategy_plan, "y")
    if strategy == "grouped"
        groups(split) = Set(data_rows[index][3] for index in rows[split])
        @test isempty(intersect(groups("train"), groups("validation")))
        @test isempty(intersect(groups("train"), groups("test")))
        @test isempty(intersect(groups("validation"), groups("test")))
    elseif strategy in ("time", "depth")
        @test maximum(31 .- rows["train"]) < minimum(31 .- rows["validation"])
        @test maximum(31 .- rows["validation"]) < minimum(31 .- rows["test"])
    end
end
for invalid in (Dict("locked" => false), Dict("strategy" => "external"), Dict("strategy" => "grouped"),
    Dict("strategy" => "time"), Dict("strategy" => "depth"), Dict("trainFraction" => 0.9))
    @test_throws "split membership" splits.split_rows(table, merge(plan, invalid), "y")
end

project = DataScienceProjectRecord(project_id = "split-project", name = "Split Project")
project.split_plans = [plan]
project.schema_contracts = [Dict("schemaId" => "schema-proof", "datasetId" => "data-proof", "updatedAt" => "2026-09-20T00:00:00Z",
    "columns" => [Dict("name" => name, "role" => name == "y" ? "target" : name == "x" ? "feature" : name,
        "logicalType" => name in ("x", "y", "depth") ? "Float64" : "String", "inferredType" => "String", "nullable" => false) for name in headers])]
resolve_path(ref) = joinpath(root, replace(ref, "local://" => ""))
checksum = splits.file_checksum(source_path)
membership = splits.prepare_membership!(project, plan, table, checksum, "y", resolve_path)
membership["table"] = table
@test membership["new"]
@test length(project.split_assignments) == 30
@test length(project.validation_folds) == 1
@test length(project.final_test_locks) == 1
@test !isfile(resolve_path(membership["refs"]["train"]))
splits.persist_membership!(membership, resolve_path)
@test !membership["new"]
@test splits.require_membership_evidence(membership, membership) === nothing
for key in ("sourceChecksumSha256", "splitPlanChecksumSha256", "membershipChecksumSha256")
    @test_throws "source evidence unavailable" splits.require_membership_evidence(merge(membership, Dict(key => repeat("0", 64))), membership)
end
@test splits.prepare_membership!(project, plan, table, checksum, "y", resolve_path)["rows"] == membership["rows"]
repository = repo_module.FileGatewayRepository(root = joinpath(root, "repository"))
mkpath(repository.root)
repo_module.save_data_science_project!(repository, project)
restored = only(repo_module.load_data_science_projects(repository))
@test splits.prepare_membership!(restored, plan, table, checksum, "y", resolve_path)["rows"] == membership["rows"]
for mutation in (p -> pop!(p.split_assignments), p -> push!(p.split_assignments, deepcopy(p.split_assignments[1])),
    p -> (p.split_assignments[1]["rowRef"] = "sha256:$(checksum)#row:999"),
    p -> (p.validation_folds[1]["validationRef"] = p.validation_folds[1]["trainRef"]),
    p -> (p.validation_folds[1]["index"] = 2), p -> (p.validation_folds[1]["strategy"] = "kfold"),
    p -> empty!(p.final_test_locks), p -> (p.final_test_locks[1]["lockedBy"] = ""))
    altered = deepcopy(restored)
    mutation(altered)
    @test_throws ErrorException splits.prepare_membership!(altered, plan, table, checksum, "y", resolve_path)
end
for field in ("splitPlans", "splitAssignments", "validationFolds", "finalTestLocks")
    @test_throws "immutable" splits.protect_membership!(restored, Dict(field => Any[]))
end
@test_throws "source evidence unavailable" splits.prepare_membership!(restored, plan, table, repeat("a", 64), "y", resolve_path)

# Counterfactual labels use fixed rows: membership does not get regenerated from changed labels.
rows = membership["rows"]
baseline_trials = tuning.local_csv_validation_tuning_trials("split-project", "study-proof", "local_classifier", ["accuracy"], 2,
    "2026-09-20T00:00:00Z", Dict("sourceUri" => "local://data/source.csv"), source_path, "y", plan; membership = rows)
@test baseline_trials !== nothing
prepared = transforms.prepare_numeric_fit_apply(project, "data-proof", membership, ["validation", "test"], "local://transforms/split-project/default-fit-apply.jl")
overflow_table = deepcopy(table)
for row in overflow_table["rows"]
    row[1] = "1"
end
overflow_table["rows"][first(rows["test"])][1] = "1e308"
@test_throws "transformed values are not finite" transforms.prepare_numeric_fit_apply(project, "data-proof",
    merge(membership, Dict("table" => overflow_table)), ["test"], "local://transforms/split-project/default-fit-apply.jl")
counterfactual = deepcopy(data_rows)
for index in rows["test"]
    counterfactual[index][2] = index % 2 == 0 ? "9999" : "not-a-number"
end
write_table(counterfactual)
changed_trials = tuning.local_csv_validation_tuning_trials("split-project", "study-proof", "local_classifier", ["accuracy"], 2,
    "2026-09-20T00:00:00Z", Dict("sourceUri" => "local://data/source.csv"), source_path, "y", plan; membership = rows)
@test changed_trials == baseline_trials
changed_membership = merge(membership, Dict("table" => splits.split_table(source_path)))
@test transforms.prepare_numeric_fit_apply(project, "data-proof", changed_membership, ["validation", "test"], "local://transforms/split-project/default-fit-apply.jl")["state"] == prepared["state"]
@test_throws "source evidence unavailable" splits.prepare_membership!(restored, plan, splits.split_table(source_path), splits.file_checksum(source_path), "y", resolve_path)
refs = transforms.transform_fit_apply_artifact_refs(project.project_id, "fit-proof", ["validation", "test"], "2026-09-20T00:00:00Z")
transforms.persist_numeric_fit_apply!(prepared, refs, "local://transforms/split-project/default-fit-apply.jl", resolve_path)
@test all(ref -> isfile(resolve_path(ref["path"])) && ref["checksumSha256"] == splits.file_checksum(resolve_path(ref["path"])), refs)
@test_throws "unsupported" transforms.prepare_numeric_fit_apply(project, "data-proof", membership, ["validation"], "local://custom.jl")
@test_throws "evaluation membership" transforms.prepare_numeric_fit_apply(project, "data-proof", membership, ["evaluation"], "local://transforms/split-project/default-fit-apply.jl")

# Exercise real gateway producers against one grouped, persisted split.
let local_root = mktempdir()
    data_root = joinpath(local_root, "data")
    mkpath(joinpath(data_root, "raw"))
    path = joinpath(data_root, "raw", "split.csv")
    original = join(headers, ',') * "\n" * join([join(row, ',') for row in data_rows], "\n") * "\n"
    write(path, original)
    withenv("JULIAFLOW_RUNTIME_MODE" => "local-appliance", "JULIAFLOW_AUTH_MODE" => "required",
        "JULIAFLOW_DEV_AUTH_TOKEN" => "split-test-token", "JULIAFLOW_HOME" => local_root,
        "JULIAFLOW_DATA_ESTATE_ROOT" => data_root) do
        state = foundation_state(joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml"); store_root = joinpath(local_root, "store"))
        request_headers = ["Authorization" => "Bearer split-test-token", "Content-Type" => "application/json"]
        send(method, endpoint, body) = route_request(state, HTTP.Request(method, endpoint, request_headers, JSON3.write(body)))
        base = "/api/v1/data-science-projects/split-project"
        grouped_plan = merge(plan, Dict("strategy" => "grouped", "groupColumn" => "group"))
        payload = Dict("projectId" => "split-project", "name" => "Split Project", "splitPlans" => [grouped_plan],
            "schemaContracts" => project.schema_contracts,
            "datasets" => [Dict("datasetId" => "data-proof", "name" => "Split data", "role" => "train", "localOnly" => true,
                "sourceUri" => "local://data/raw/split.csv")])
        @test send("POST", "/api/v1/data-science-projects", payload).status == 201
        context = Dict("projectId" => "split-project", "datasetId" => "data-proof", "splitPlanId" => "split-proof")
        preview = Dict{String,Any}("datasetId" => "data-proof", "target" => "y", "modelKind" => "local_classifier", "modelId" => "counterfactual")
        first_fit = JuliaFlowApiGateway.local_csv_training_artifact!(state, context, preview, "2026-09-20T00:00:00Z"; persist = false)
        @test first_fit !== nothing
        counterfactual_rows = deepcopy(data_rows)
        for index in first_fit["testRowIndices"]
            counterfactual_rows[index][2] = "not-a-number"
        end
        write(path, join(headers, ',') * "\n" * join([join(row, ',') for row in counterfactual_rows], "\n") * "\n")
        second_fit = JuliaFlowApiGateway.local_csv_training_artifact!(state, context, preview, "2026-09-20T00:00:00Z"; persist = false)
        @test second_fit !== nothing
        for key in ("nativeModelKind", "modelKind", "featureColumns", "coefficients", "metrics", "trainingRowIndices")
            @test first_fit[key] == second_fit[key]
        end
        @test isempty(state.data_science_projects["split-project"].split_assignments)
        write(path, original)
        transform_body = Dict("datasetId" => "data-proof", "splitPlanId" => "split-proof", "fitSplit" => "train", "applySplits" => ["validation", "test"])
        response = send("POST", base * "/transforms/fit-apply", transform_body)
        @test response.status == 201
        current = state.data_science_projects["split-project"]
        @test length(current.transform_fit_apply_records) == 1
        record = only(current.transform_fit_apply_records)
        proof = record["membershipEvidence"]
        @test record["transformKind"] == "numeric_standardize"
        expected_rows = splits.split_rows(splits.split_table(path), grouped_plan, "y")
        @test proof["trainingRowIndices"] == expected_rows["train"]
        for ref in record["artifactRefs"]
            artifact_path = JuliaFlowApiGateway.local_data_ref_path_for_write(ref["path"])
            @test isfile(artifact_path)
            @test ref["checksumSha256"] == splits.file_checksum(artifact_path)
            artifact = splits.Arrow.Table(read(artifact_path))
            if ref["kind"] == "transform_fit_state"
                @test artifact.feature == ["x"]
                @test only(artifact.mean) == sum(expected_rows["train"]) / length(expected_rows["train"])
            else
                split_name = first(splitext(basename(ref["path"])))
                @test collect(artifact._juliaflow_row_index) == expected_rows[split_name]
            end
        end
        training_response = send("POST", "/api/v1/workflows/wf-foundation/ml/experiments/run",
            merge(context, Dict("target" => "y", "algorithm" => "local_classifier", "finalTestPolicy" => "forbid_final_test")))
        @test training_response.status == 202
        experiment = JSON3.read(String(training_response.body), Dict{String,Any})["experiment"]
        model = only(filter(ref -> get(ref, "kind", "") == "trained_model", experiment["artifactEvidence"]))
        @test model["trainingRowIndices"] == expected_rows["train"]
        @test model["membershipChecksumSha256"] == proof["membershipChecksumSha256"]
        tuning_body = Dict("datasetId" => "data-proof", "splitPlanId" => "split-proof", "targetColumn" => "y", "algorithm" => "local_classifier",
            "metricNames" => ["accuracy"], "maxTrials" => 2, "finalTestPolicy" => "forbid_final_test")
        tuning_response = send("POST", base * "/tuning/run", tuning_body)
        @test tuning_response.status == 201
        tuned = JSON3.read(String(tuning_response.body), Dict{String,Any})
        study = tuned["tuningStudy"]
        @test study["validationEvidence"]["membershipChecksumSha256"] == proof["membershipChecksumSha256"]
        for trial in study["trials"]
            @test trial["validationEvidence"]["trainingRowIndices"] == expected_rows["train"]
            @test trial["validationEvidence"]["validationRowIndices"] == expected_rows["validation"]
        end
        evaluation_response = send("POST", base * "/evaluation/run", Dict("datasetId" => "data-proof", "splitPlanId" => "split-proof",
            "trainingPlanId" => tuned["trainingPlan"]["trainingPlanId"], "tuningStudyId" => study["tuningStudyId"],
            "finalTestPolicy" => "use_final_test", "approvalThreshold" => 0.0, "metricNames" => ["accuracy"]))
        @test evaluation_response.status == 201
        report = JSON3.read(String(evaluation_response.body), Dict{String,Any})["evaluationReport"]
        evidence = report["validationEvidence"]["evaluationDataEvidence"]
        @test evidence["trainingRowIndices"] == expected_rows["train"]
        @test evidence["testRowIndices"] == expected_rows["test"]
        @test evidence["trainRowCount"] == length(expected_rows["train"])
        @test isempty(intersect(evidence["trainingRowIndices"], expected_rows["validation"]))
        current = state.data_science_projects["split-project"]
        original_proof = current.tuning_studies[1]["validationEvidence"]["membershipChecksumSha256"]
        current.tuning_studies[1]["validationEvidence"]["membershipChecksumSha256"] = repeat("0", 64)
        @test send("POST", base * "/evaluation/run", Dict("datasetId" => "data-proof", "splitPlanId" => "split-proof",
            "trainingPlanId" => tuned["trainingPlan"]["trainingPlanId"], "tuningStudyId" => study["tuningStudyId"],
            "finalTestPolicy" => "use_final_test", "approvalThreshold" => 0.0, "metricNames" => ["accuracy"])).status == 409
        @test length(current.evaluation_reports) == 1
        current.tuning_studies[1]["validationEvidence"]["membershipChecksumSha256"] = original_proof
        snapshot = deepcopy(repo_module.data_science_project_payload(current))
        @test send("PUT", base, Dict("splitAssignments" => Any[])).status == 400
        @test repo_module.data_science_project_payload(state.data_science_projects["split-project"]) == snapshot
        for mutation in (p -> (p.validation_folds[1]["index"] = 2), p -> empty!(p.final_test_locks),
            p -> (p.split_plans[1]["locked"] = false), p -> (p.split_plans[1]["strategy"] = "external"))
            state.data_science_projects["split-project"] = deepcopy(current)
            mutation(state.data_science_projects["split-project"])
            before = deepcopy(repo_module.data_science_project_payload(state.data_science_projects["split-project"]))
            jobs_before = length(state.executions)
            rejected = send("POST", base * "/tuning/run", tuning_body)
            @test rejected.status == 400
            @test repo_module.data_science_project_payload(state.data_science_projects["split-project"]) == before
            @test length(state.executions) == jobs_before
        end
        state.data_science_projects["split-project"] = current
        write(path, replace(original, "1,1,group-1," => "1,9999,group-1,"))
        @test send("POST", base * "/tuning/run", tuning_body).status == 409
        @test repo_module.data_science_project_payload(current) == snapshot
    end
end
