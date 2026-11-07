@testset "Final evaluation actual binary metrics and rejection" begin
    evaluation = JuliaFlowApiGateway.JuliaFlowDataScienceProjectEvaluation
    metric = evaluation.final_evaluation_metric_from_errors
    actual = [zeros(90); ones(10)]
    scores = [fill(0.4, 90); fill(0.3, 10)]
    @test metric("accuracy", actual, scores) == 0.9
    @test metric("f1", actual, scores) == 0.0
    @test metric("f1-score", actual, scores) == 0.0
    @test metric("auc", actual, scores) == 0.0
    @test metric("auc", [0.0, 1.0], [0.4, 0.4]) == 0.5
    @test metric("auc", [0.0, 1.0, 0.0, 1.0], [0.1, 0.5, 0.5, 0.9]) == 0.875
    @test metric("f1", [2.25, 7.75], [0.49, 0.5]; negative_label = 2.25, positive_label = 7.75) == 1.0
    @test metric("auc", [2.25, 7.75], [0.2, 0.8]; negative_label = 2.25, positive_label = 7.75) == 1.0
    @test metric("accuracy", [0.0, 1.0], [0.5, 0.5]) == 0.5
    @test metric("f1", [0.0, 0.0], [0.1, 0.2]) == 0.0
    @test metric("f1", [1.0, 1.0], [0.5, 0.9]) == 1.0
    @test_throws ErrorException metric("auc", [1.0, 1.0], [0.5, 0.9])
    @test_throws ErrorException metric("auc", [0.0, 0.0], [0.5, 0.9])
    @test_throws ErrorException metric("unknown", [0.0, 1.0], [0.2, 0.8])
    @test_throws ErrorException metric("f1", [0.0, 2.0], [0.2, 0.8])
    @test_throws ErrorException metric("f1", [0.0, 1.0], [0.2, 1.1])
    @test_throws ErrorException metric("f1", [0.0, 1.0], [0.2, 0.8]; classification_threshold = NaN)
    @test_throws ErrorException metric("mae", [1.0], [1.0, 2.0])
    @test_throws ErrorException metric("mae", Float64[], Float64[])
    @test_throws ErrorException metric("mae", [NaN], [1.0])
    @test_throws ErrorException metric("auc", [0.0, 1.0], [0.2, Inf])
    @test metric("mae", [1.0, 3.0], [2.0, 1.0]) == 1.5
    @test metric("mse", [1.0, 3.0], [2.0, 1.0]) == 2.5
    @test metric("rmse", [1.0, 3.0], [2.0, 1.0]) == round(sqrt(2.5); digits = 6)
    @test metric("r2", [1.0, 3.0], [2.0, 1.0]) == -1.5
    @test evaluation.final_evaluation_normalized_score("mae", 1.5, [1.0, 3.0]) == 0.25

    mktempdir() do directory
        path = joinpath(directory, "binary.csv")
        write(path, "x,y\n0,2.25\n10,7.75\n0,2.25\n10,7.75\n")
        membership = Dict("train" => [1, 2], "validation" => Int[], "test" => [3, 4])
        artifact = Dict{String,Any}(
            "modelKind" => "local_csv_binary_centroid_classifier", "targetColumn" => "y",
            "featureColumns" => ["x"], "trainingRowIndices" => [1, 2], "trainRowCount" => 2,
            "coefficients" => Dict{String,Any}("negativeLabel" => 2.25, "positiveLabel" => 7.75,
                "positivePrior" => 0.5, "positiveMeans" => Dict("x" => 10.0),
                "negativeMeans" => Dict("x" => 0.0), "featureScales" => Dict("x" => 1.0)))
        result = evaluation.final_evaluation_metrics_from_csv(Dict(), path, "y", ["accuracy", "f1", "auc"], Dict(), artifact; membership = membership)
        @test result["metrics"] == Dict("accuracy" => 1.0, "f1" => 1.0, "auc" => 1.0)
        @test_throws ErrorException evaluation.final_evaluation_metrics_from_csv(Dict(), path, "y", ["rmse"], Dict(), artifact; membership = membership)
        @test_throws ErrorException evaluation.final_evaluation_metrics_from_csv(Dict(), path, "y", ["auc"], Dict(); membership = membership)
        artifact["coefficients"]["positiveLabel"] = 1.0
        @test_throws ErrorException evaluation.final_evaluation_metrics_from_csv(Dict(), path, "y", ["f1"], Dict(), artifact; membership = membership)
    end
end

@testset "Generated Julia metadata remains comments" begin
    stats = JuliaFlowApiGateway.JuliaFlowDataScienceProjectStatistics
    mlj = JuliaFlowApiGateway.JuliaFlowDataScienceProjectMLJ
    # Compare parsed statements without loading optional MLJ packages or executing artifacts.
    statements(code) = filter(item -> !(item isa LineNumberNode), Meta.parseall(code).args)
    benign_stats = stats.statistical_analysis_code_artifact("dataset", ["summary"], Dict("targetColumn" => "target", "featureColumns" => ["feature"]))
    benign_mlj = mlj.mlj_generated_training_code("MLJ.LinearRegressor", "target", ["feature"])
    @test occursin("# dataset: dataset", benign_stats)
    @test occursin("# featureColumns: feature", benign_stats)
    @test occursin("model = @load LinearRegressor pkg=MLJLinearModels", benign_mlj)
    for payload in ("safe\nmetadata_injected = true\n#", "safe\r\nmetadata_injected = true\r\n#",
                    "safe\rmetadata_injected = true\r#", "safe\u2028metadata_injected = true\u2029#",
                    "safe\u0085metadata_injected = true", "#=\n=#\nmetadata_injected = true\n#",
                    "\"\\\nmetadata_injected = true\n#")
        # Each metadata sink is varied independently, including method and feature arrays.
        for code in (
            stats.statistical_analysis_code_artifact(payload, ["summary"], Dict()),
            stats.statistical_analysis_code_artifact("dataset", [payload], Dict()),
            stats.statistical_analysis_code_artifact("dataset", ["summary"], Dict("targetColumn" => payload)),
            stats.statistical_analysis_code_artifact("dataset", ["summary"], Dict("featureColumns" => [payload])),
        )
            @test statements(code) == statements(benign_stats)
            @test count(==('\n'), code) == count(==('\n'), benign_stats)
        end
        for code in (mlj.mlj_generated_training_code(payload, "target", ["feature"]),
                     mlj.mlj_generated_training_code("MLJ.LinearRegressor", payload, ["feature"]),
                     mlj.mlj_generated_training_code("MLJ.LinearRegressor", "target", [payload]))
            @test statements(code) == statements(benign_mlj)
            @test count(==('\n'), code) == count(==('\n'), benign_mlj)
        end
    end
end
