using Test
if !isdefined(Main, :JuliaFlowApiGateway)
    include(joinpath(@__DIR__, "../../services/api-gateway/src/JuliaFlowDataScienceProjectStatistics.jl"))
    include(joinpath(@__DIR__, "../../services/api-gateway/src/JuliaFlowDataScienceProjectProfiling.jl"))
    include(joinpath(@__DIR__, "../../services/api-gateway/src/JuliaFlowProjectAnalysis.jl"))
end

@testset "Scoped summary measured precision" begin
    analysis = isdefined(Main, :JuliaFlowApiGateway) ? JuliaFlowApiGateway.JuliaFlowProjectAnalysis : JuliaFlowProjectAnalysis
    for (values, mean, std) in (([1e-200, 2e-200, 3e-200], 2e-200, 1e-200),
                              ([1e-7, 2e-7, 3e-7], 2e-7, 1e-7),
                              ([2e-200, 2e-200], 2e-200, 0.0),
                              ([-1e-200, 0.0, 1e-200], 0.0, 1e-200),
                              ([1e300, 1.0, -1e300], 1/3, 1e300))
        mktemp() do path, io
            write(io, "x\n" * join(string.(values), '\n') * "\n"); close(io)
            dataset = Dict("datasetId"=>"precision", "sourceUri"=>"precision.csv", "checksumSha256"=>bytes2hex(analysis.sha256(read(path))))
            schema = Dict("columns"=>[Dict("name"=>"x", "logicalType"=>"numeric", "role"=>"feature")])
            request = Dict("methods"=>["summary"], "scope"=>Dict("datasetChecksum"=>dataset["checksumSha256"], "schemaFingerprint"=>analysis.schema_fingerprint(schema), "question"=>"Precision?", "filters"=>Any[]))
            evidence = analysis.scoped_evidence(dataset, path, request, schema)
            summary = only(evidence["summaries"])
            @test isapprox(summary["mean"], mean; rtol=1e-14, atol=0)
            @test isapprox(summary["std"], std; rtol=1e-14, atol=0)
            @test !any(occursin("numerical result range", warning) for warning in evidence["warnings"])
            @test !isempty(analysis.JSON3.write(evidence))
        end
    end
    @test isnan(analysis.scoped_sample_std([-1e308, 1e308]))
    @test isnan(analysis.scoped_sample_std([0.0, 0.0, 0.0, 0.0, nextfloat(0.0)]))
    @test analysis.scoped_sample_std([0.0, 0.0]) == 0.0
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

@testset "Correlation scale qualification" begin
    stats = isdefined(Main, :JuliaFlowApiGateway) ? JuliaFlowApiGateway.JuliaFlowDataScienceProjectStatistics : JuliaFlowDataScienceProjectStatistics
    for scale in (1.0, 1e-161, 1e-200, 1e300)
        x = scale .* [1.0, 2.0, 3.0]
        @test stats.pearson_correlation(x, 3 .* x) == 1.0
        @test stats.pearson_correlation(x, -3 .* x) == -1.0
        table = Dict("headers"=>["x","y"], "rows"=>[[string(x[i]),string(3*x[i])] for i in eachindex(x)])
        @test stats.paired_correlation(table, "x", "y") == 1.0
    end
    for offset in (1.0, 1e300)
        x = [offset, nextfloat(offset), nextfloat(nextfloat(offset))]
        @test stats.pearson_correlation(x, [1.0, 2.0, 3.0]) == 1.0
        @test stats.pearson_correlation(x, [3.0, 2.0, 1.0]) == -1.0
    end
    @test stats.pearson_correlation([-1e308, 0.0, 1e308], [-1.0, 0.0, 1.0]) == 1.0
    @test stats.pearson_correlation([1.0, 2.0, 3.0], [1.0, 3.0, 2.0]) == 0.5
    analysis = isdefined(Main, :JuliaFlowApiGateway) ? JuliaFlowApiGateway.JuliaFlowProjectAnalysis : JuliaFlowProjectAnalysis
    mktemp() do path, io
        write(io, "x,y\n1e-161,3e-161\n2e-161,6e-161\n3e-161,9e-161\n"); close(io)
        dataset = Dict("datasetId"=>"tiny", "sourceUri"=>"tiny.csv", "checksumSha256"=>bytes2hex(analysis.sha256(read(path))))
        schema = Dict("columns"=>[Dict("name"=>name,"logicalType"=>"numeric","role"=>"feature") for name in ("x","y")])
        request = Dict("methods"=>["summary","correlation"], "scope"=>Dict("datasetChecksum"=>dataset["checksumSha256"],"schemaFingerprint"=>analysis.schema_fingerprint(schema),"question"=>"Scale?","filters"=>Any[]))
        evidence = analysis.scoped_evidence(dataset,path,request,schema)
        @test evidence["correlationMatrix"][1][2] == 1.0
        @test evidence["correlationPairCounts"][1][2] == 3
    end
end
