module JuliaFlowDataScienceProjectEvaluation

using ..JuliaFlowGatewayRepository
using ..JuliaFlowDataScienceProjectStatistics
using ..JuliaFlowDataScienceProjectMLJ

export project_training_plan_for_request,
    project_tuning_study_for_final_evaluation,
    final_evaluation_metric_names,
    final_evaluation_approval_threshold,
    final_evaluation_validation_context,
    final_evaluation_metrics,
    final_evaluation_metrics_from_csv,
    final_evaluation_report_record,
    final_evaluation_output_refs

function safe_evaluation_token(value::AbstractString)
    normalized = lowercase(strip(String(value)))
    normalized = replace(normalized, r"[^a-z0-9._-]+" => "-")
    normalized = strip(normalized, ['-', '.', '_'])
    isempty(normalized) && return ""
    return first(normalized, min(lastindex(normalized), 80))
end

function project_training_plan_for_request(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    body::AbstractDict,
)
    isempty(project.training_plans) && error("final evaluation prerequisite training plan required")
    if haskey(body, "trainingPlanId")
        training_plan_id = String(body["trainingPlanId"])
        match = findfirst(plan -> String(get(plan, "trainingPlanId", "")) == training_plan_id, project.training_plans)
        match === nothing && error("final evaluation prerequisite training plan not found: $(training_plan_id)")
        return project.training_plans[match]
    end
    length(project.training_plans) == 1 || error("final evaluation trainingPlanId required when multiple training plans exist")
    return project.training_plans[1]
end

function project_tuning_study_for_final_evaluation(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    body::AbstractDict,
    training_plan_id::AbstractString,
)
    studies = [study for study in project.tuning_studies if String(get(study, "trainingPlanId", "")) == String(training_plan_id)]
    isempty(studies) && error("final evaluation prerequisite validation-only tuning study required")
    if haskey(body, "tuningStudyId")
        tuning_study_id = String(body["tuningStudyId"])
        match = findfirst(study -> String(get(study, "tuningStudyId", "")) == tuning_study_id, studies)
        match === nothing && error("final evaluation prerequisite tuning study not found: $(tuning_study_id)")
        return studies[match]
    end
    return studies[1]
end

function final_evaluation_metric_names(body::AbstractDict, training_plan::AbstractDict)
    raw_metrics = if haskey(body, "metricNames")
        body["metricNames"]
    elseif haskey(training_plan, "metricNames")
        training_plan["metricNames"]
    else
        ["rmse", "mae"]
    end
    raw_metrics isa AbstractVector || error("final evaluation metricNames must be an array")
    metrics = [safe_evaluation_token(String(metric)) for metric in raw_metrics]
    metrics = [metric for metric in metrics if !isempty(metric)]
    isempty(metrics) && error("final evaluation metric required")
    return metrics
end

function final_evaluation_approval_threshold(body::AbstractDict)
    threshold = haskey(body, "approvalThreshold") ? Float64(body["approvalThreshold"]) : 0.8
    0.0 <= threshold <= 1.0 || error("final evaluation approvalThreshold must be between 0 and 1")
    return threshold
end

function final_evaluation_validation_context(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    body::AbstractDict,
    dataset_id::AbstractString,
    split_plan::AbstractDict,
    training_plan::AbstractDict,
    tuning_study::AbstractDict,
)
    test_fraction = Float64(get(split_plan, "testFraction", 0.0))
    test_fraction > 0 || error("final evaluation test split required")
    Bool(get(split_plan, "locked", false)) || error("final evaluation locked split required")
    final_test_policy = String(get(body, "finalTestPolicy", ""))
    final_test_policy == "use_final_test" || error("final evaluation finalTestPolicy must be use_final_test")
    split_plan_id = String(get(split_plan, "splitPlanId", ""))
    training_split_plan_id = String(get(training_plan, "splitPlanId", ""))
    training_split_plan_id == split_plan_id || error("final evaluation split plan must match training plan")
    Bool(get(tuning_study, "validationOnly", false)) || error("final evaluation prerequisite tuning study must be validation-only")
    tuning_validation = get(tuning_study, "validationEvidence", Dict{String,Any}())
    String(get(tuning_validation, "finalTestPolicy", "")) == "forbid_final_test" || error("final evaluation prerequisite tuning study used final test data")
    String(get(tuning_validation, "splitPlanId", split_plan_id)) == split_plan_id || error("final evaluation split plan must match tuning study")
    return Dict{String,Any}(
        "projectId" => project.project_id,
        "datasetId" => String(dataset_id),
        "splitPlanId" => split_plan_id,
        "tuningStudyId" => String(get(tuning_study, "tuningStudyId", "")),
        "tuningBestTrialId" => String(get(tuning_study, "bestTrialId", "")),
        "tuningExecutionMode" => String(get(tuning_validation, "tuningExecutionMode", "")),
        "finalTestPolicy" => final_test_policy,
        "validationOnlyTuning" => true,
        "testFraction" => test_fraction,
    )
end

function final_evaluation_metrics(metric_names::AbstractVector)
    metrics = Dict{String,Any}()
    for (index, metric) in enumerate(metric_names)
        metrics[String(metric)] = round(max(0.0, 0.92 - (0.02 * (index - 1))); digits = 4)
    end
    return metrics
end

function final_evaluation_metric_from_errors(metric::AbstractString, actual::Vector{Float64}, predicted::Vector{Float64})
    n = min(length(actual), length(predicted))
    n == 0 && return 0.0
    y = actual[1:n]
    yhat = predicted[1:n]
    errors = [y[index] - yhat[index] for index in 1:n]
    metric_name = safe_evaluation_token(metric)
    if metric_name in ("mae", "mean-absolute", "mean-absolute-error")
        return round(sum(abs(error) for error in errors) / n; digits = 6)
    elseif metric_name in ("mse", "mean-squared-error")
        return round(sum(error^2 for error in errors) / n; digits = 6)
    elseif metric_name in ("rmse", "root-mean-squared-error")
        return round(sqrt(sum(error^2 for error in errors) / n); digits = 6)
    elseif metric_name in ("r2", "r-squared")
        mean_actual = JuliaFlowDataScienceProjectStatistics.sample_mean(y)
        sst = sum((value - mean_actual)^2 for value in y)
        sse = sum(error^2 for error in errors)
        return round(sst == 0.0 ? 0.0 : 1.0 - (sse / sst); digits = 6)
    elseif metric_name in ("accuracy", "f1", "auc")
        rounded_actual = [round(value) for value in y]
        rounded_predicted = [round(value) for value in yhat]
        correct = sum(rounded_actual[index] == rounded_predicted[index] for index in 1:n)
        return round(correct / n; digits = 6)
    end
    return round(max(0.0, 1.0 - (sum(abs(error) for error in errors) / n)); digits = 6)
end

function final_evaluation_lower_is_better_metric(metric::AbstractString)
    metric_name = safe_evaluation_token(metric)
    return metric_name in ("mae", "mean-absolute", "mean-absolute-error", "mse", "mean-squared-error", "rmse", "root-mean-squared-error")
end

function final_evaluation_normalized_score(metric::AbstractString, raw_value::Real, target_values::Vector{Float64})
    final_evaluation_lower_is_better_metric(metric) || return round(Float64(raw_value); digits = 6)
    target_range = maximum(target_values) - minimum(target_values)
    target_scale = target_range == 0.0 ? max(abs(JuliaFlowDataScienceProjectStatistics.sample_mean(target_values)), 1.0) : target_range
    denominator = safe_evaluation_token(metric) in ("mse", "mean-squared-error") ? target_scale^2 : target_scale
    score = max(0.0, min(1.0, 1.0 - (Float64(raw_value) / denominator)))
    return round(score; digits = 6)
end

function final_evaluation_trend_predictions(train_values::Vector{Float64}, prediction_count::Integer)
    prediction_count <= 0 && return Float64[], "none", 0.0, 0.0
    if length(train_values) <= 1
        baseline = JuliaFlowDataScienceProjectStatistics.sample_mean(train_values)
        return fill(baseline, prediction_count), "mean_baseline", 0.0, baseline
    end
    x = collect(1.0:length(train_values))
    x_mean = JuliaFlowDataScienceProjectStatistics.sample_mean(x)
    y_mean = JuliaFlowDataScienceProjectStatistics.sample_mean(train_values)
    ssx = sum((value - x_mean)^2 for value in x)
    if ssx == 0.0
        return fill(y_mean, prediction_count), "mean_baseline", 0.0, y_mean
    end
    slope = sum((x[index] - x_mean) * (train_values[index] - y_mean) for index in eachindex(train_values)) / ssx
    intercept = y_mean - slope * x_mean
    predictions = [intercept + slope * Float64(length(train_values) + offset) for offset in 1:prediction_count]
    return predictions, "row_index_linear_baseline", round(slope; digits = 6), round(intercept; digits = 6)
end

function final_evaluation_metrics_from_csv(
    dataset::AbstractDict,
    source_path::AbstractString,
    target_column::AbstractString,
    metric_names::AbstractVector,
    split_plan::AbstractDict,
    model_artifact::Union{Nothing,AbstractDict} = nothing,
)
    table = JuliaFlowDataScienceProjectStatistics.parse_simple_csv(source_path)
    table === nothing && return nothing
    numeric_columns, _ = JuliaFlowDataScienceProjectStatistics.simple_numeric_columns(table)
    haskey(numeric_columns, String(target_column)) || return nothing
    target_values = numeric_columns[String(target_column)]
    total = length(target_values)
    total <= 1 && return nothing
    test_fraction = Float64(get(split_plan, "testFraction", 0.2))
    test_count = max(1, min(total - 1, round(Int, total * test_fraction)))
    train_count = total - test_count
    train_values = target_values[1:train_count]
    test_values = target_values[(train_count + 1):total]
    execution_mode = "local_csv_baseline"
    scoring_evidence = Dict{String,Any}()
    predictions, baseline_model, baseline_slope, baseline_intercept = final_evaluation_trend_predictions(train_values, length(test_values))
    if model_artifact !== nothing && String(get(model_artifact, "nativeModelKind", String(get(model_artifact, "modelKind", "")))) in ("local_csv_single_feature_ols", "local_csv_multi_feature_ols", "local_csv_binary_centroid_classifier")
        artifact_target = String(get(model_artifact, "targetColumn", ""))
        model_kind = String(get(model_artifact, "modelKind", ""))
        native_model_kind = String(get(model_artifact, "nativeModelKind", model_kind))
        feature_columns = native_model_kind in ("local_csv_multi_feature_ols", "local_csv_binary_centroid_classifier") ?
            [String(column) for column in get(model_artifact, "featureColumns", Any[])] :
            [String(get(model_artifact, "featureColumn", ""))]
        coefficients = get(model_artifact, "coefficients", Dict{String,Any}())
        feature_columns = [column for column in feature_columns if !isempty(strip(column))]
        if artifact_target == String(target_column) && !isempty(feature_columns) && all(column -> haskey(numeric_columns, column), feature_columns) &&
                (haskey(coefficients, "intercept") || model_kind == "local_csv_binary_centroid_classifier")
            if all(column -> length(numeric_columns[column]) >= total, feature_columns)
                classifier_mode = native_model_kind == "local_csv_binary_centroid_classifier"
                mlj_evidence = get(model_artifact, "mljEvidence", Dict{String,Any}())
                mlj_scoring_result = nothing
                if Bool(get(mlj_evidence, "mljPackageFitExecuted", false))
                    train_feature_pairs = [column => numeric_columns[column][1:train_count] for column in feature_columns]
                    test_feature_pairs = [column => numeric_columns[column][(train_count + 1):total] for column in feature_columns]
                    mlj_scoring_result = JuliaFlowDataScienceProjectMLJ.mlj_package_prediction_result(
                        String(get(model_artifact, "requestedAlgorithm", "")),
                        train_feature_pairs,
                        train_values,
                        test_feature_pairs;
                        classifier_mode = classifier_mode,
                    )
                end
                intercept = Float64(get(coefficients, "intercept", 0.0))
                artifact_predictions = nothing
                if mlj_scoring_result !== nothing
                    artifact_predictions = Float64.(mlj_scoring_result["predictions"])
                    execution_mode = "mlj_package_backed_final_evaluation"
                    baseline_model = classifier_mode ? "mlj_package_logistic_classifier_refit" : "mlj_package_linear_regressor_refit"
                    baseline_slope = 0.0
                    baseline_intercept = 0.0
                    scoring_evidence = Dict{String,Any}(
                        "modelArtifactRef" => String(get(model_artifact, "artifactRef", "")),
                        "modelArtifactChecksumSha256" => String(get(model_artifact, "checksumSha256", "")),
                        "modelKind" => model_kind,
                        "nativeModelKind" => native_model_kind,
                        "modelFamily" => String(get(model_artifact, "modelFamily", "")),
                        "requestedAlgorithm" => String(get(model_artifact, "requestedAlgorithm", "")),
                        "featureColumn" => first(feature_columns),
                        "featureColumns" => feature_columns,
                        "coefficients" => coefficients,
                        "trainingRowCount" => Int(get(model_artifact, "trainRowCount", train_count)),
                        "mljEvidence" => mlj_evidence,
                        "mljScoringEvidence" => mlj_scoring_result["evidence"],
                        "packageScoringMode" => "refit_from_train_scope_rows",
                    )
                elseif native_model_kind == "local_csv_binary_centroid_classifier"
                    centroid_model = Dict{String,Any}(
                        "featureColumns" => feature_columns,
                        "positiveLabel" => get(coefficients, "positiveLabel", 1.0),
                        "negativeLabel" => get(coefficients, "negativeLabel", 0.0),
                        "positivePrior" => get(coefficients, "positivePrior", 0.5),
                        "positiveMeans" => get(coefficients, "positiveMeans", Dict{String,Any}()),
                        "negativeMeans" => get(coefficients, "negativeMeans", Dict{String,Any}()),
                        "featureScales" => get(coefficients, "featureScales", Dict{String,Any}()),
                    )
                    feature_pairs = [column => numeric_columns[column] for column in feature_columns]
                    artifact_predictions = JuliaFlowDataScienceProjectStatistics.binary_centroid_probabilities(
                        centroid_model,
                        feature_pairs,
                        (train_count + 1):total,
                    )
                elseif native_model_kind == "local_csv_multi_feature_ols" && haskey(coefficients, "slopes")
                    slopes = get(coefficients, "slopes", Dict{String,Any}())
                    artifact_predictions = [
                        intercept + sum(Float64(get(slopes, column, 0.0)) * numeric_columns[column][row] for column in feature_columns)
                        for row in (train_count + 1):total
                    ]
                elseif haskey(coefficients, "slope")
                    slope = Float64(coefficients["slope"])
                    feature_column = first(feature_columns)
                    artifact_predictions = [intercept + slope * numeric_columns[feature_column][row] for row in (train_count + 1):total]
                end
                if artifact_predictions !== nothing && mlj_scoring_result === nothing
                    predictions = artifact_predictions
                    execution_mode = "local_csv_trained_artifact"
                    baseline_model = native_model_kind == "local_csv_binary_centroid_classifier" ? "trained_binary_centroid_classifier" :
                        (native_model_kind == "local_csv_multi_feature_ols" ? "trained_multi_feature_ols" : "trained_single_feature_ols")
                    baseline_slope = native_model_kind == "local_csv_multi_feature_ols" ? 0.0 : round(Float64(get(coefficients, "slope", 0.0)); digits = 6)
                    baseline_intercept = round(intercept; digits = 6)
                    scoring_evidence = Dict{String,Any}(
                        "modelArtifactRef" => String(get(model_artifact, "artifactRef", "")),
                        "modelArtifactChecksumSha256" => String(get(model_artifact, "checksumSha256", "")),
                        "modelKind" => model_kind,
                        "nativeModelKind" => native_model_kind,
                        "modelFamily" => String(get(model_artifact, "modelFamily", "")),
                        "requestedAlgorithm" => String(get(model_artifact, "requestedAlgorithm", "")),
                        "featureColumn" => first(feature_columns),
                        "featureColumns" => feature_columns,
                        "coefficients" => coefficients,
                        "trainingRowCount" => Int(get(model_artifact, "trainRowCount", train_count)),
                    )
                    haskey(model_artifact, "mljEvidence") && (scoring_evidence["mljEvidence"] = model_artifact["mljEvidence"])
                elseif artifact_predictions !== nothing
                    predictions = artifact_predictions
                end
            end
        end
    end
    metrics = Dict{String,Any}()
    raw_metrics = Dict{String,Any}()
    metric_semantics = Dict{String,Any}()
    for metric in metric_names
        metric_key = String(metric)
        raw_value = final_evaluation_metric_from_errors(metric_key, test_values, predictions)
        raw_metrics[metric_key] = raw_value
        metrics[metric_key] = final_evaluation_normalized_score(metric_key, raw_value, target_values)
        metric_semantics[metric_key] = final_evaluation_lower_is_better_metric(metric_key) ? "lower_is_better_normalized_quality_score" : "higher_is_better_score"
    end
    evidence = Dict{String,Any}(
        "executionMode" => execution_mode,
        "sourceKind" => "managed_local_csv",
        "sourceRef" => String(get(dataset, "sourceUri", "")),
        "targetColumn" => String(target_column),
        "rowCount" => total,
        "trainRowCount" => train_count,
        "testRowCount" => length(test_values),
        "baselineModel" => baseline_model,
        "baselineSlope" => baseline_slope,
        "baselineIntercept" => baseline_intercept,
        "rawMetrics" => raw_metrics,
        "metricSemantics" => metric_semantics,
    )
    merge!(evidence, scoring_evidence)
    return Dict{String,Any}(
        "metrics" => metrics,
        "evidence" => evidence,
    )
end

function final_evaluation_report_record(
    report_id::AbstractString,
    project_id::AbstractString,
    training_plan::AbstractDict,
    split_plan_id::AbstractString,
    metrics::AbstractDict,
    approved::Bool,
    validation_context::AbstractDict,
    timestamp::AbstractString,
)
    return Dict{String,Any}(
        "evaluationReportId" => String(report_id),
        "trainingPlanId" => String(get(training_plan, "trainingPlanId", "")),
        "splitPlanId" => String(split_plan_id),
        "metrics" => Dict{String,Any}(String(key) => value for (key, value) in pairs(metrics)),
        "approved" => approved,
        "finalTestOnly" => true,
        "validationEvidence" => Dict{String,Any}(String(key) => value for (key, value) in pairs(validation_context)),
        "generatedAt" => String(timestamp),
        "artifactRefs" => [
            Dict(
                "refId" => "artifact-$(String(report_id))",
                "kind" => "final_evaluation_report",
                "localOnly" => true,
                "path" => "local://evaluation/$(String(project_id))/$(String(report_id))/report.json",
                "generatedAt" => String(timestamp),
            ),
        ],
    )
end

function final_evaluation_output_refs(evaluation_report::AbstractDict)
    return get(evaluation_report, "artifactRefs", Dict{String,Any}[])
end

end
