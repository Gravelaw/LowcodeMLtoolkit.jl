using Test, HTTP, JSON3, SHA
if !isdefined(Main, :JuliaFlowApiGateway)
    include(joinpath(@__DIR__, "../../services/api-gateway/src/JuliaFlowApiGateway.jl"))
end
using .JuliaFlowApiGateway
@testset "Durable scoped analysis" begin
    mktempdir() do root
        source = joinpath(root, "sources"); mkpath(source)
        csv = joinpath(source, "homes.csv")
        write(csv, "area,price,region\n1,10,A\n,20,B\n3,,A\n4,40,B\n")
        withenv("JULIAFLOW_HOME" => root, "JULIAFLOW_DATA_ESTATE_ROOT" => joinpath(root,"data"),
            "JULIAFLOW_IMPORT_ROOTS" => source, "JULIAFLOW_RUNTIME_MODE" => "local-appliance",
            "JULIAFLOW_AUTH_MODE" => "required", "JULIAFLOW_DEV_AUTH_TOKEN" => "analysis-test-token",
            "JULIAFLOW_DISABLE_HARDWARE_PROBE" => "1") do
            store = joinpath(root, "store"); state = load_state(store)
            headers = ["Content-Type" => "application/json", "Authorization" => "Bearer analysis-test-token"]
            send(path, body; gateway=state, auth=true) = route_request(gateway, HTTP.Request("POST",path,auth ? headers : headers[1:1],JSON3.write(body)))
            payload(response) = JSON3.read(String(response.body), Dict{String,Any})
            @test send("/api/v1/data-science-projects",Dict("name"=>"Homes","projectId"=>"homes")).status == 201
            base = "/api/v1/data-science-projects/homes"
            @test send("/api/v1/local-data/import",Dict("projectId"=>"homes","datasetId"=>"homes-data","sourceUri"=>csv,"format"=>"csv")).status == 201
            profile_response = send(base*"/analysis/profile",Dict("datasetId"=>"homes-data"))
            @test profile_response.status == 200
            profile = payload(profile_response)
            @test profile["profile"]["rowCount"] == 4
            @test send(base*"/analysis/profile",Dict("datasetId"=>"homes-data"); auth=false).status == 401
            @test send(base*"/analysis/profile",Dict("datasetId"=>nothing)).status == 400
            @test send(base*"/analysis/workspace",Dict()).status == 400
            started, release = Channel{Nothing}(1), Channel{Nothing}(1)
            owner = @async JuliaFlowApiGateway.with_project_mutation(state, "homes") do
                put!(started, nothing); take!(release)
            end
            take!(started)
            @test send(base*"/analysis/workspace",Dict()).status == 409
            @test send(base*"/analysis/workspace",Dict(); auth=false).status == 401
            put!(release, nothing); wait(owner)
            @test isempty(state.mutating_projects)
            @test_throws ErrorException JuliaFlowApiGateway.with_project_mutation(() -> error("failure"), state, "homes")
            @test isempty(state.mutating_projects)
            scope = Dict("datasetChecksum"=>profile["profile"]["checksumSha256"],"schemaFingerprint"=>profile["schemaFingerprint"],"filters"=>Any[],"question"=>"What explains price? \$(@eval Main replay_injected = true)","xColumn"=>"area","yColumn"=>"price")
            request = Dict("datasetId"=>"homes-data","methods"=>["summary","correlation"],"scope"=>scope)
            response = send(base*"/statistical-analysis/run",request)
            @test response.status == 201
            run = payload(response)["analysisRun"]
            @test run["resultSummary"]["correlationMatrix"][1][2] == 1.0
            @test run["resultSummary"]["correlationPairCounts"][1][2] == 2
            @test run["resultSummary"]["scope"]["rowIds"] == [1,2,3,4]
            @test run["resultSummary"]["scatter"]["count"] == 2
            @test run["resultSummary"]["computeProvenance"]["workerComputed"] == false
            workspace = Dict("revision"=>0,"datasetId"=>"homes-data","scope"=>scope,"analysisRunId"=>run["analysisRunId"],"findings"=>[Dict("findingId"=>"note-1","analysisRunId"=>run["analysisRunId"],"title"=>"Association","notes"=>"<script>alert(1)</script> is text; not causation.")])
            saved = send(base*"/analysis/workspace",Dict("expectedRevision"=>0,"workspace"=>workspace))
            @test saved.status == 200
            @test payload(saved)["analysisWorkspace"]["revision"] == 1
            aggregate = payload(saved)
            aggregate["analysisWorkspace"]["findings"][1]["notes"] = "bypass dedicated save"
            @test route_request(state, HTTP.Request("PUT", base, headers, JSON3.write(aggregate))).status == 400
            @test state.data_science_projects["homes"].analysis_workspace["findings"][1]["notes"] == workspace["findings"][1]["notes"]
            @test send(base*"/analysis/workspace",Dict("expectedRevision"=>0,"workspace"=>workspace)).status == 400
            reloaded = load_state(store)
            @test reloaded.data_science_projects["homes"].analysis_workspace["findings"][1]["notes"] == workspace["findings"][1]["notes"]
            @test reloaded.data_science_projects["homes"].statistical_analysis_runs[1] == state.data_science_projects["homes"].statistical_analysis_runs[1]
            report = send(base*"/analysis/export",Dict();gateway=reloaded)
            report.status == 200 || println("Report error: ", String(report.body))
            @test report.status == 200
            export_result = payload(report)
            @test occursin("&lt;script&gt;",export_result["html"])
            @test !occursin("<script>",export_result["html"])
            @test occursin("Presentation report",export_result["html"])
            @test occursin("area",export_result["csv"])
            @test bytes2hex(sha256(export_result["html"])) == export_result["checksumSha256"]
            @test occursin("Pearson correlations and complete-pair counts", export_result["html"])
            @test occursin("Selected complete scatter pairs", export_result["html"])
            @test occursin("Selected finite distribution values", export_result["html"])
            @test occursin("tabindex=\"0\"", export_result["html"])
            chart_evidence = deepcopy(run["resultSummary"])
            chart_evidence["scatter"]["xLabel"] = "Area (m²) <script>bad</script>"
            chart_evidence["scatter"]["yLabel"] = "Price (USD)"
            chart_html = JuliaFlowApiGateway.JuliaFlowProjectAnalysis.report_scatter(chart_evidence)
            @test occursin("Area (m²) &lt;script&gt;bad&lt;/script&gt;", chart_html)
            @test occursin("Price (USD)", chart_html)
            @test !occursin("<script>", chart_html)
            @test occursin("text-anchor", chart_html)
            chart_evidence["correlationMatrix"][1][2] = nothing
            @test occursin("unavailable", JuliaFlowApiGateway.JuliaFlowProjectAnalysis.report_chart_tables(chart_evidence))
            chart_evidence["scatter"]["x"] = [-floatmax(Float64), floatmax(Float64)]
            @test occursin("rendering unavailable", JuliaFlowApiGateway.JuliaFlowProjectAnalysis.report_scatter(chart_evidence))
            @test occursin(string(floatmax(Float64)), JuliaFlowApiGateway.JuliaFlowProjectAnalysis.report_chart_tables(chart_evidence))
            @test JuliaFlowApiGateway.JuliaFlowProjectAnalysis.csv_cell("=SUM(A1:A2)") == "\"'=SUM(A1:A2)\""
            bad = deepcopy(request);bad["scope"]["datasetChecksum"] = repeat("0",64)
            @test send(base*"/statistical-analysis/run",bad).status == 400
            bad = deepcopy(request);bad["methods"] = ["anova"]
            @test send(base*"/statistical-analysis/run",bad).status == 400
            filtered = deepcopy(request);filtered["scope"]["filters"] = [Dict("column"=>"region","operator"=>"eq","value"=>"B")]
            filtered_response = send(base*"/statistical-analysis/run",filtered)
            @test filtered_response.status == 201
            @test payload(filtered_response)["analysisRun"]["resultSummary"]["scope"]["rowIds"] == [2,4]
            bad = deepcopy(filtered);bad["scope"]["filters"][1]["value"]="No rows"
            @test send(base*"/statistical-analysis/run",bad).status == 400
            before = length(state.data_science_projects["homes"].statistical_analysis_runs)
            managed = JuliaFlowApiGateway.resolve_local_data_ref_path(state.data_science_projects["homes"].datasets[1]["sourceUri"])
            original = read(managed,String);write(managed, original*"5,50,C\n")
            @test send(base*"/statistical-analysis/run",request).status == 400
            @test send(base*"/analysis/export",Dict()).status == 400
            @test length(state.data_science_projects["homes"].statistical_analysis_runs) == before
            write(managed,original)
            analysis = JuliaFlowApiGateway.JuliaFlowProjectAnalysis
            schema = deepcopy(state.data_science_projects["homes"].schema_contracts[1])
            area = findfirst(c -> c["name"] == "area", schema["columns"])
            schema["columns"][area]["role"] = "ignore"
            restricted = deepcopy(request)
            delete!(restricted["scope"], "xColumn"); delete!(restricted["scope"], "yColumn")
            restricted["scope"]["schemaFingerprint"] = analysis.schema_fingerprint(schema)
            restricted_evidence = analysis.scoped_evidence(state.data_science_projects["homes"].datasets[1], managed, restricted, schema)
            @test restricted_evidence["numericColumns"] == ["price"]
            @test_throws ErrorException analysis.scoped_evidence(state.data_science_projects["homes"].datasets[1], managed, request, schema)
            code_path = JuliaFlowApiGateway.resolve_local_artifact_ref_path(run["generatedCodeRef"])
            output = read(`$(Base.julia_cmd()) --startup-file=no --project=$(normpath(joinpath(@__DIR__,"../.."))) $code_path $managed`,String)
            replay = JSON3.read(output,Dict{String,Any})
            @test replay["correlationMatrix"] == run["resultSummary"]["correlationMatrix"]
            @test replay["scope"] == run["resultSummary"]["scope"]
            second_csv = joinpath(source, "second.csv")
            write(second_csv, "area,price,region\n2,25,C\n6,60,C\n")
            @test send("/api/v1/local-data/import",Dict("projectId"=>"homes","datasetId"=>"homes-second","sourceUri"=>second_csv,"format"=>"csv")).status == 201
            second_profile = payload(send(base*"/analysis/profile",Dict("datasetId"=>"homes-second")))
            second_workspace = deepcopy(workspace)
            second_workspace["revision"] = 1; second_workspace["datasetId"] = "homes-second"
            second_workspace["scope"]["schemaFingerprint"] = second_profile["schemaFingerprint"]
            second_workspace["scope"]["datasetChecksum"] = second_profile["profile"]["checksumSha256"]
            @test send(base*"/analysis/workspace",Dict("expectedRevision"=>1,"workspace"=>second_workspace)).status == 400
            delete!(second_workspace, "analysisRunId")
            @test send(base*"/analysis/workspace",Dict("expectedRevision"=>1,"workspace"=>second_workspace)).status == 200
            @test state.data_science_projects["homes"].analysis_workspace["findings"][1]["analysisRunId"] == run["analysisRunId"]
            @test load_state(store).data_science_projects["homes"].analysis_workspace["findings"][1]["notes"] == workspace["findings"][1]["notes"]
            @test send(base*"/analysis/export",Dict()).status == 200
            write(managed, original*"5,50,C\n")
            @test send(base*"/analysis/export",Dict()).status == 400
            write(managed, original)
            original_summary = deepcopy(state.data_science_projects["homes"].statistical_analysis_runs[2]["resultSummary"])
            state.data_science_projects["homes"].statistical_analysis_runs[2]["resultSummary"]["rowCount"] = 999
            @test send(base*"/analysis/export",Dict()).status == 400
            state.data_science_projects["homes"].statistical_analysis_runs[2]["resultSummary"] = original_summary
            result_path = JuliaFlowApiGateway.resolve_local_artifact_ref_path(run["resultRef"])
            write(result_path,"tampered")
            @test send(base*"/analysis/export",Dict()).status == 400
        end
    end
end
