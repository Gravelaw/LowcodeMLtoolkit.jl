using Test
if !isdefined(Main, :JuliaFlowApiGateway)
    include(joinpath(@__DIR__, "../../services/api-gateway/src/JuliaFlowDataScienceProjectStatistics.jl"))
    include(joinpath(@__DIR__, "../../services/api-gateway/src/JuliaFlowDataScienceProjectProfiling.jl"))
    include(joinpath(@__DIR__, "../../services/api-gateway/src/JuliaFlowProjectAnalysis.jl"))
end

@testset "Bounded analysis identity and range" begin
    analysis = isdefined(Main, :JuliaFlowApiGateway) ? JuliaFlowApiGateway.JuliaFlowProjectAnalysis : JuliaFlowProjectAnalysis
    @test analysis.canonical(Dict("b"=>[1,2], "a"=>Dict("x"=>nothing))) == "{\"a\":{\"x\":null},\"b\":[1,2]}"
    mktemp() do path, io
        write(io, "x\n1e308\n1e308\n"); close(io)
        dataset = Dict("datasetId"=>"huge", "sourceUri"=>"verified.csv", "checksumSha256"=>bytes2hex(analysis.sha256(read(path))))
        schema = Dict("columns"=>[Dict("name"=>"x", "logicalType"=>"numeric", "role"=>"feature")])
        request = Dict("methods"=>["summary","correlation"], "scope"=>Dict("datasetChecksum"=>dataset["checksumSha256"], "schemaFingerprint"=>analysis.schema_fingerprint(schema), "question"=>"Range?", "filters"=>Any[]))
        evidence = analysis.scoped_evidence(dataset, path, request, schema)
        @test evidence["summaries"][1]["mean"] === nothing
        @test any(occursin("numerical result range", warning) for warning in evidence["warnings"])
        @test !isempty(analysis.JSON3.write(evidence))
        names = ["x$i" for i in 1:65]
        write(path, join(names, ',') * "\n" * join(fill("1",65), ',') * "\n")
        dataset["checksumSha256"] = bytes2hex(analysis.sha256(read(path)))
        schema["columns"] = [Dict("name"=>name, "logicalType"=>"numeric", "role"=>"feature") for name in names]
        request["scope"]["datasetChecksum"] = dataset["checksumSha256"]
        request["scope"]["schemaFingerprint"] = analysis.schema_fingerprint(schema)
        @test_throws ErrorException analysis.scoped_evidence(dataset, path, request, schema)
    end
end
@testset "Statistical original row alignment" begin
    stats = isdefined(Main, :JuliaFlowApiGateway) ? JuliaFlowApiGateway.JuliaFlowDataScienceProjectStatistics : JuliaFlowDataScienceProjectStatistics
    mktemp() do path, io
        write(io, "x,y,group\n1,10,A\n,20,B\n3,,A\n4,40,B\n")
        close(io)
        evidence = stats.local_csv_statistical_evidence_from_path(Dict("sourceUri" => "test"), path,
            Dict("targetColumn" => "y", "featureColumns" => ["x", "group"]), ["summary", "correlation", "ols"])
        @test evidence["correlationMatrix"][1][2] == 1.0
        @test evidence["correlationPairCounts"][1][2] == 2
        @test evidence["inferentialTests"]["ols"]["slope"] == 10.0
        @test evidence["inferentialTests"]["ols"]["n"] == 2
        @test stats.paired_group_values(Dict("headers" => ["x", "g"], "rows" => [["", "A"], ["2", "B"]]), "x", "g") == ([2.0], ["B"])
        @test stats.paired_correlation(Dict("headers" => ["x", "y"], "rows" => [["1", "2"], ["1", "3"]]), "x", "y") === nothing
    end
end
