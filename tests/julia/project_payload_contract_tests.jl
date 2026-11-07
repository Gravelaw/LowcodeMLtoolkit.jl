cases = JSON3.read(read(joinpath(@__DIR__, "..", "contracts", "fixtures", "project-payload-cases.json"), String), Dict{String,Any})
for fixture in vcat(cases["valid"], cases["invalid"])
    fixture["payload"] = merge(deepcopy(cases["base"]), fixture["payload"])
end
repo_module = JuliaFlowApiGateway.JuliaFlowGatewayRepository
core = JuliaFlowApiGateway.JuliaFlowDataScienceProjectCore
jobs = JuliaFlowApiGateway.JuliaFlowDataScienceProjectJobs
profile = Dict{String,Any}(
    "datasetId" => "profile-contract", "importedAt" => "2026-09-20T00:00:00Z",
    "schemaSummary" => [Dict("name" => "outcome", "type" => "Bool"), Dict("name" => "observed", "type" => "Date")],
    "profileSummary" => [Dict("name" => "outcome", "role" => "label"), Dict("name" => "observed", "role" => "timestamp")],
)
profile_contract = JuliaFlowApiGateway.schema_contract_from_profile(profile)
@test [column["role"] for column in profile_contract["columns"]] == ["target", "time"]
@test repo_module.JuliaFlowProjectPayloadValidation.validate_project_children!(Dict("schemaContracts" => [profile_contract])) isa AbstractDict
@test_throws "invalid contract payload" JuliaFlowApiGateway.JuliaFlowDataScienceProjectCatalog.schema_role_from_profile("unrecognized")
old_profile = deepcopy(profile_contract)
old_profile["columns"][1]["role"] = "label"
old_profile["columns"][2]["role"] = "timestamp"
historical_profile = merge(deepcopy(cases["valid"][1]["payload"]), Dict("schemaContracts" => [old_profile]))
@test_throws "schemaContracts invalid contract payload" core.materialize_project_record(historical_profile)
restored_profile = repo_module.gateway_data_science_project(historical_profile)
@test restored_profile.schema_contracts == [profile_contract]
@test !haskey(restored_profile.project_jobs[1], "resourceEvidence")
substring_record = Dict("modelId" => strip(" model-1 "), "state" => strip(" approved "), "updatedAt" => strip(" 2026-09-20T00:00:00Z "))
@test substring_record["modelId"] isa SubString
@test repo_module.JuliaFlowProjectPayloadValidation.validate_project_children!(Dict("modelLifecycleRecords" => [substring_record])) isa AbstractDict
repo = repo_module.FileGatewayRepository(root = mktempdir())
repo_module.ensure_repository!(repo)
for fixture in cases["valid"]
    payload = fixture["payload"]
    # Historical import/storage remains supported; generic requests cannot author
    # the completed jobs and tuning evidence in these fixtures.
    @test_throws "server-owned execution evidence" core.materialize_project_record(payload)
    project = repo_module.gateway_data_science_project(payload)
    @test project.project_jobs == payload["projectJobs"]
    repo_module.save_data_science_project!(repo, project)
    loaded = only(repo_module.load_data_science_projects(repo))
    @test loaded.project_jobs == payload["projectJobs"]
    @test repo_module.gateway_data_science_project(repo_module.data_science_project_payload(loaded)).project_jobs == payload["projectJobs"]
end
for fixture in cases["invalid"]
    @test_throws ErrorException core.materialize_project_record(fixture["payload"])
    @test_throws ErrorException repo_module.gateway_data_science_project(fixture["payload"])
end
legacy = repo_module.gateway_data_science_project(cases["valid"][1]["payload"])
@test !haskey(legacy.project_jobs[1], "resourceEvidence")
@test_throws ErrorException jobs.project_job_record(legacy, "training")
@test_throws ErrorException jobs.project_job_record(legacy, "training"; resource_evidence = Dict{String,Any}())
@test_throws "resourceEvidence required" jobs.project_job_record(legacy, "training"; status = "failed", execution_evidence = Dict("executionId" => "executed-failure"))
@test_throws ErrorException jobs.project_job_execution_record(legacy, "training"; workflow_id = "wf-foundation", checkpoint_tag = "latest")
@test !haskey(jobs.project_job_record(legacy, "training"; status = "queued"), "resourceEvidence")
resource = jobs.project_job_resource_evidence(Dict("selectedBackend" => "cpu", "schedulerPolicy" => "bounded_local", "cpuWorkerConcurrency" => 1, "cpuMemoryLimitBytes" => 1048576), Dict("devices" => Any[], "device_count" => 0))
@test jobs.project_job_record(legacy, "training"; resource_evidence = resource)["resourceEvidence"] == resource
@test resource["evidenceVersion"] == 2
@test resource["actualExecutionBackend"] == "cpu"
@test_throws "invalid contract payload" jobs.project_job_record(
    legacy, "training"; resource_evidence = merge(resource, Dict("evidenceVersion" => 3)))
@test_throws "invalid contract payload" jobs.project_job_record(
    legacy, "training"; resource_evidence = merge(resource, Dict("actualExecutionBackend" => "imaginary")))

# Reject mutated runtime objects before file replacement or PostgreSQL connection work.
repo_module.save_data_science_project!(repo, legacy)
before = read(repo_module.data_science_projects_file(repo), String)
bad = deepcopy(legacy)
bad.project_jobs[1]["resourceEvidence"] = Dict("selectedBackend" => "cpu")
@test_throws ErrorException repo_module.save_data_science_project!(repo, bad)
@test read(repo_module.data_science_projects_file(repo), String) == before
postgres = repo_module.PostgreSQLGatewayRepository(connection_string = "not-a-real-connection")
@test_throws "projectJobs invalid contract payload" repo_module.save_data_science_project!(postgres, bad)
invalid_model = Dict("modelId" => "malformed", "workflowId" => "wf-foundation", "validationEvidence" => Dict("projectId" => legacy.project_id))
@test_throws "modelRegistryRecords invalid contract payload" repo_module.save_model_registry_record!(repo, invalid_model)
@test !isfile(repo_module.model_registry_file(repo))
@test read(repo_module.data_science_projects_file(repo), String) == before
@test_throws "modelRegistryRecords invalid contract payload" repo_module.save_model_registry_record!(postgres, invalid_model)

withenv("JULIAFLOW_RUNTIME_MODE" => "local-appliance", "JULIAFLOW_AUTH_MODE" => "required", "JULIAFLOW_DEV_AUTH_TOKEN" => "contract-test-token") do
    state = foundation_state(joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml"); store_root = mktempdir())
    headers = ["Authorization" => "Bearer contract-test-token", "Content-Type" => "application/json"]
    valid = cases["valid"][1]["payload"]
    response = route_request(state, HTTP.Request("POST", "/api/v1/data-science-projects", headers, JSON3.write(valid)))
    @test response.status == 400
    @test occursin("server-owned execution evidence", String(response.body))
    @test !haskey(state.data_science_projects, "contract-project")
    response = route_request(state, HTTP.Request("POST", "/api/v1/data-science-projects", headers, JSON3.write(cases["base"])))
    @test response.status == 201
    @test isempty(JSON3.read(String(response.body))["projectJobs"])
    baseline = repo_module.data_science_project_payload(state.data_science_projects["contract-project"])
    for fixture in cases["invalid"]
        response = route_request(state, HTTP.Request("PUT", "/api/v1/data-science-projects/contract-project", headers, JSON3.write(fixture["payload"])))
        @test response.status == 400
        @test repo_module.data_science_project_payload(state.data_science_projects["contract-project"]) == baseline
    end
end
