using Test, HTTP, JSON3, SHA
if !isdefined(Main, :JuliaFlowApiGateway)
    include(joinpath(@__DIR__, "..", "..", "services", "api-gateway", "src", "JuliaFlowApiGateway.jl"))
end
using .JuliaFlowApiGateway

@testset "Real file profile HTTP boundary" begin
    mktempdir() do root
        source_dir = joinpath(root, "sources")
        mkpath(source_dir)
        withenv("JULIAFLOW_HOME" => root, "JULIAFLOW_DATA_ESTATE_ROOT" => joinpath(root, "data"),
                "JULIAFLOW_IMPORT_ROOTS" => source_dir, "JULIAFLOW_RUNTIME_MODE" => "local-appliance",
                "JULIAFLOW_AUTH_MODE" => "required", "JULIAFLOW_DEV_AUTH_TOKEN" => "profile-boundary-token",
                "JULIAFLOW_DISABLE_HARDWARE_PROBE" => "1", "JULIAFLOW_CORS_ALLOW_ORIGIN" => nothing) do
            fixture = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
            state = foundation_state(fixture; store_root = joinpath(root, "store"))
            request_for = function(path; format = "csv", dataset_id = "Superstore", token = true)
                headers = ["Content-Type" => "application/json"]
                token && push!(headers, "Authorization" => "Bearer profile-boundary-token")
                HTTP.Request("POST", "/api/v1/local-data/import", headers,
                    JSON3.write(Dict("datasetId" => dataset_id, "sourceUri" => path, "format" => format)))
            end
            csv = joinpath(source_dir, "data.csv")
            write(csv, "region,amount\nnorth,12.5\nsouth,9.5\n")
            response = route_request(state, request_for(csv))
            @test response.status == 201
            profile = JSON3.read(String(response.body), Dict{String,Any})["profile"]
            @test profile["rowCount"] == 2
            @test profile["artifactRef"] == realpath(csv)
            @test profile["checksumSha256"] == bytes2hex(sha256(read(csv)))
            @test profile["profileSummary"][2]["numericSummary"]["mean"] == 11
            @test length(profile["lineageArtifacts"]) == 1
            renamed = route_request(state, request_for(csv; dataset_id = "Churn"))
            @test JSON3.read(String(renamed.body), Dict{String,Any})["profile"]["schemaSummary"] == profile["schemaSummary"]
            @test route_request(state, request_for(csv; token = false)).status == 401

            headers = ["Content-Type" => "application/json", "Authorization" => "Bearer profile-boundary-token"]
            send(method, path, body; gateway = state) = route_request(gateway, HTTP.Request(method, path, headers, JSON3.write(body)))
            base = "/api/v1/data-science-projects/profile-project"
            @test send("POST", "/api/v1/data-science-projects", Dict("projectId" => "profile-project", "name" => "Profile Round Trip")).status == 201
            imported = send("POST", "/api/v1/local-data/import", Dict("projectId" => "profile-project", "datasetId" => "measured",
                "sourceUri" => csv, "format" => "csv"))
            @test imported.status == 201
            imported_payload = JSON3.read(String(imported.body), Dict{String,Any})
            datasets = imported_payload["project"]["datasets"]
            dataset = only(datasets)
            managed_ref = dataset["sourceUri"]
            @test startswith(managed_ref, "local://data/raw/imports/")
            @test dataset["artifactRef"] == managed_ref
            @test dataset["importSourceUri"] == realpath(csv)
            @test imported_payload["profile"]["artifactRef"] == managed_ref
            @test length(imported_payload["profile"]["lineageArtifacts"]) == 2
            @test bytes2hex(sha256(read(JuliaFlowApiGateway.resolve_local_data_ref_path(managed_ref)))) == dataset["checksumSha256"]
            dataset["role"] = "reference"
            @test send("PUT", base, Dict("datasets" => datasets)).status == 200
            # Wizard defaults resubmit the same complete dataset array.
            @test send("PUT", base, Dict("name" => "Wizard Round Trip", "datasets" => datasets)).status == 200
            reloaded = load_state(joinpath(root, "store"))
            @test only(reloaded.data_science_projects["profile-project"].datasets)["sourceUri"] == managed_ref
            @test only(reloaded.data_science_projects["profile-project"].datasets)["importSourceUri"] == realpath(csv)
            write(csv, "region,amount\nchanged,999\n") # Imported managed bytes remain reproducible.
            analyzed = send("POST", base * "/statistical-analysis/run", Dict("datasetId" => "measured", "methods" => ["summary"]); gateway = reloaded)
            @test analyzed.status == 201
            actual = JSON3.read(String(analyzed.body), Dict{String,Any})["analysisRun"]["resultSummary"]
            @test actual["executionMode"] == "local_csv"
            @test actual["sourceRef"] == managed_ref
            @test actual["rowCount"] == 2
            @test only(actual["summaries"])["mean"] == 11

            # Request-shape failures must precede creation of a new managed copy.
            invalid_name_source = joinpath(source_dir, "invalid-name.csv")
            write(invalid_name_source, "region,amount\nunique,123.75\n")
            for invalid_name in (nothing, 42, Dict("name" => "invalid"), Any[], "", "  ")
                before_project = deepcopy(JuliaFlowApiGateway.JuliaFlowGatewayRepository.data_science_project_payload(reloaded.data_science_projects["profile-project"]))
                before_files = sort(readdir(joinpath(root, "data", "raw", "imports")))
                rejected = send("POST", "/api/v1/local-data/import", Dict("projectId" => "profile-project", "datasetId" => "invalid-name",
                    "datasetName" => invalid_name, "sourceUri" => invalid_name_source, "format" => "csv"); gateway = reloaded)
                @test rejected.status == 400
                @test occursin("datasetName must be a nonempty string", String(rejected.body))
                @test JuliaFlowApiGateway.JuliaFlowGatewayRepository.data_science_project_payload(reloaded.data_science_projects["profile-project"]) == before_project
                @test sort(readdir(joinpath(root, "data", "raw", "imports"))) == before_files
                rejected_ref = "local://data/raw/imports/$(bytes2hex(sha256(read(invalid_name_source)))).csv"
                @test JuliaFlowApiGateway.resolve_local_data_ref_path(rejected_ref) === nothing
            end

            unsupported = joinpath(source_dir, "data.json")
            write(unsupported, "[{\"amount\":1}]")
            @test route_request(state, request_for(unsupported; format = "json")).status == 400
            for content in ("a,b\n1\n", "a,b\n\"quoted\",1\n", "a,b\n" * repeat("1,2\n", 1_001))
                write(csv, content)
                before_project = deepcopy(JuliaFlowApiGateway.JuliaFlowGatewayRepository.data_science_project_payload(reloaded.data_science_projects["profile-project"]))
                before_files = sort(readdir(joinpath(root, "data", "raw", "imports")))
                @test send("POST", "/api/v1/local-data/import", Dict("projectId" => "profile-project", "datasetId" => "rejected", "sourceUri" => csv, "format" => "csv"); gateway = reloaded).status == 400
                @test JuliaFlowApiGateway.JuliaFlowGatewayRepository.data_science_project_payload(reloaded.data_science_projects["profile-project"]) == before_project
                @test sort(readdir(joinpath(root, "data", "raw", "imports"))) == before_files
            end
        end
    end
end
