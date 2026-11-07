using Test
using SHA

include(joinpath(@__DIR__, "..", "..", "services", "api-gateway", "src", "JuliaFlowDataScienceProjectProfiling.jl"))
using .JuliaFlowDataScienceProjectProfiling
if !isdefined(Main, :JuliaFlowDataScienceProjectLocalSources)
    include(joinpath(@__DIR__, "..", "..", "services", "api-gateway", "src", "JuliaFlowDataScienceProjectLocalSources.jl"))
end

@testset "real local CSV profiling" begin
    @test normalize_profile_request(Dict("datasetName" => "  Measured Data  "))["datasetName"] == "Measured Data"
    @test !haskey(normalize_profile_request(Dict()), "datasetName")
    for field in ("datasetId", "datasetName", "datasetRole", "projectId", "sourceUri", "format", "targetZone", "readMode", "connector")
        for value in (nothing, 42, Dict("name" => "invalid"), Any[], "", "  ", "invalid\nname")
            @test_throws "local data import $(field)" normalize_profile_request(Dict(field => value))
        end
    end
    mktempdir() do root
        first_path = joinpath(root, "superstore.csv")
        second_path = joinpath(root, "renamed.csv")
        write(first_path, "region,amount\nnorth,12.5\nsouth,9.5\n")
        write(second_path, "region,amount\nwest,99\nwest,\neast,1\n")
        first_profile = local_csv_profile(first_path)
        second_profile = local_csv_profile(second_path)
        same_content_renamed = joinpath(root, "churn.csv")
        cp(first_path, same_content_renamed)
        @test local_csv_profile(same_content_renamed) == first_profile
        @test first_profile["rowCount"] == 2
        @test second_profile["rowCount"] == 3
        @test first_profile["schemaSummary"][2]["type"] == "Float64"
        @test first_profile["profileSummary"][2]["numericSummary"] == Dict("count" => 2, "minimum" => 9.5, "maximum" => 12.5, "mean" => 11.0)
        @test second_profile["profileSummary"][2]["missingCount"] == 1
        @test first_profile["previewRows"][1]["region"] == "north"
        @test any(value -> value["label"] == "west" && value["value"] == 2, second_profile["quickPlots"][1]["values"])
        @test first_profile["profileSummary"] != second_profile["profileSummary"]
        @test !any(row -> row["name"] == "profit", first_profile["profileSummary"])

        write(second_path, "amount,mixed\n2,2\n10,text\n-1.5,10\nNA,NA\n")
        typed = local_csv_profile(second_path)
        numbers = [row["amount"] for row in typed["previewRows"] if row["amount"] !== nothing]
        @test all(value -> value isa Float64, numbers)
        @test sort(numbers) == [-1.5, 2.0, 10.0]
        @test sort(numbers; rev = true) == [10.0, 2.0, -1.5]
        @test typed["previewRows"][4]["amount"] === nothing
        @test typed["previewRows"][1]["mixed"] == "2"
        @test typed["previewRows"][2]["mixed"] == "text"
        @test typed["previewRows"][4]["mixed"] === nothing
        write(second_path, "category\n(missing)\nNA\n(missing) [missing cells]\n")
        categories = local_csv_profile(second_path)
        values = categories["quickPlots"][1]["values"]
        @test length(values) == 3
        @test length(unique(item["label"] for item in values)) == 3
        @test only(filter(item -> item["missing"], values))["value"] == 1
        @test only(filter(item -> item["label"] == "(missing)", values))["value"] == 1
        @test categories["profileSummary"][1]["missingCount"] == 1
        @test categories["profileSummary"][1]["distinctCount"] == 2

        sources = JuliaFlowDataScienceProjectLocalSources
        checksum = bytes2hex(sha256(read(first_path)))
        data_root = joinpath(root, "managed")
        managed = sources.materialize_profile_source!(first_path, checksum; data_root, zone = "raw", max_bytes = 8 * 1024 * 1024)
        @test managed == "local://data/raw/imports/$(checksum).csv"
        destination = joinpath(data_root, "raw", "imports", "$(checksum).csv")
        @test read(destination) == read(first_path)
        @test sources.materialize_profile_source!(first_path, checksum; data_root, zone = "raw", max_bytes = 8 * 1024 * 1024) == managed
        @test_throws "source changed" sources.materialize_profile_source!(second_path, checksum; data_root, zone = "raw", max_bytes = 8 * 1024 * 1024)
        write(destination, "corrupt")
        @test_throws "checksum conflict" sources.materialize_profile_source!(first_path, checksum; data_root, zone = "raw", max_bytes = 8 * 1024 * 1024)

        write(second_path, "region,amount\n\"north,west\",1\n")
        @test_throws "quoted CSV is unsupported" local_csv_profile(second_path)
        write(second_path, "region,amount\nnorth\n")
        @test_throws "column count mismatch" local_csv_profile(second_path)
        write(second_path, "region,amount\n" * repeat("north,1\n", 1_001))
        @test_throws "at most 1,000 rows" local_csv_profile(second_path)
        write(second_path, "region,amount\n" * repeat("x", 8 * 1024 * 1024))
        @test_throws "up to 8 MiB" local_csv_profile(second_path)
    end
end
