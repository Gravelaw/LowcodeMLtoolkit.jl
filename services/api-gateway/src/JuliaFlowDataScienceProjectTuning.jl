module JuliaFlowDataScienceProjectTuning

using ..JuliaFlowGatewayRepository
using ..JuliaFlowDataScienceProjectStatistics

export project_split_plan_for_request,
    validate_tuning_split_context,
    tuning_metric_names,
    tuning_max_trials,
    tuning_training_plan_record,
    upsert_training_plan!,
    tuning_trials,
    local_csv_validation_tuning_trials,
    tuning_study_record,
    tuning_output_refs

function safe_tuning_token(value::AbstractString)
    normalized = lowercase(strip(String(value)))
    normalized = replace(normalized, r"[^a-z0-9._-]+" => "-")
    normalized = strip(normalized, ['-', '.', '_'])
    isempty(normalized) && return ""
    return first(normalized, min(lastindex(normalized), 80))
end

function project_split_plan_for_request(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    body::AbstractDict,
    dataset_id::AbstractString,
    action::AbstractString,
)
    plans = [plan for plan in project.split_plans if String(get(plan, "datasetId", "")) == String(dataset_id)]
    isempty(plans) && error("$(String(action)) split plan required for dataset: $(String(dataset_id))")
    if haskey(body, "splitPlanId")
        split_plan_id = String(body["splitPlanId"])
        match = findfirst(plan -> String(get(plan, "splitPlanId", "")) == split_plan_id, plans)
        match === nothing && error("$(String(action)) split plan not found: $(split_plan_id)")
        return plans[match]
    end
    length(plans) == 1 || error("$(String(action)) splitPlanId required when multiple split plans exist")
    return plans[1]
end

function validate_tuning_split_context(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    body::AbstractDict,
    dataset_id::AbstractString,
)
    split_plan = project_split_plan_for_request(project, body, dataset_id, "tuning study")
    validation_fraction = Float64(get(split_plan, "validationFraction", 0.0))
    test_fraction = Float64(get(split_plan, "testFraction", 0.0))
    validation_fraction > 0 || error("tuning study validation split required")
    test_fraction > 0 || error("tuning study test split required")
    final_test_policy = String(get(body, "finalTestPolicy", "forbid_final_test"))
    final_test_policy in ("forbid_final_test", "use_final_test") || error("tuning study finalTestPolicy invalid")
    final_test_policy == "use_final_test" && error("tuning study final test data cannot be used for hyperparameter tuning")
    return split_plan, Dict{String,Any}(
        "projectId" => project.project_id,
        "datasetId" => String(dataset_id),
        "splitPlanId" => String(get(split_plan, "splitPlanId", "")),
        "splitStrategy" => String(get(split_plan, "strategy", "")),
        "finalTestPolicy" => final_test_policy,
        "validationFraction" => validation_fraction,
        "testFraction" => test_fraction,
    )
end

function tuning_metric_names(body::AbstractDict)
    raw_metrics = haskey(body, "metricNames") ? body["metricNames"] : ["rmse", "mae"]
    raw_metrics isa AbstractVector || error("tuning study metricNames must be an array")
    metrics = [safe_tuning_token(String(metric)) for metric in raw_metrics]
    metrics = [metric for metric in metrics if !isempty(metric)]
    isempty(metrics) && error("tuning study metric required")
    return metrics
end

function tuning_max_trials(body::AbstractDict)
    value = haskey(body, "maxTrials") ? Int(body["maxTrials"]) : 3
    1 <= value <= 100 || error("tuning study maxTrials must be between 1 and 100")
    return value
end

function tuning_training_plan_record(
    training_plan_id::AbstractString,
    target_column::AbstractString,
    task_type::AbstractString,
    metric_names::AbstractVector,
    split_plan::AbstractDict,
    timestamp::AbstractString,
)
    return Dict{String,Any}(
        "trainingPlanId" => String(training_plan_id),
        "targetColumn" => String(target_column),
        "taskType" => String(task_type),
        "metricNames" => String.(metric_names),
        "splitPlanId" => String(get(split_plan, "splitPlanId", "")),
        "seed" => Int(get(split_plan, "seed", 42)),
        "createdAt" => String(timestamp),
    )
end

function upsert_training_plan!(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    training_plan::AbstractDict,
)
    training_plan_id = String(get(training_plan, "trainingPlanId", ""))
    existing_training = findfirst(plan -> String(get(plan, "trainingPlanId", "")) == training_plan_id, project.training_plans)
    if existing_training === nothing
        pushfirst!(project.training_plans, Dict{String,Any}(String(key) => value for (key, value) in pairs(training_plan)))
    else
        project.training_plans[existing_training] = Dict{String,Any}(String(key) => value for (key, value) in pairs(training_plan))
    end
    return project.training_plans[1]
end

function tuning_trials(
    project_id::AbstractString,
    study_id::AbstractString,
    algorithm::AbstractString,
    metric_names::AbstractVector,
    max_trials::Integer,
    timestamp::AbstractString,
)
    trials = Dict{String,Any}[]
    for index in 1:Int(max_trials)
        metrics = Dict{String,Any}()
        for (metric_index, metric) in enumerate(metric_names)
            metrics[String(metric)] = round(1.0 / (index + metric_index); digits = 4)
        end
        push!(
            trials,
            Dict{String,Any}(
                "trialId" => "$(String(study_id))-trial-$(index)",
                "parameters" => Dict("algorithm" => String(algorithm), "maxDepth" => 2 + index, "learningRate" => round(0.03 * index; digits = 3)),
                "metrics" => metrics,
                "artifactRefs" => [
                    Dict(
                        "refId" => "artifact-$(String(study_id))-trial-$(index)",
                        "kind" => "tuning_trial",
                        "localOnly" => true,
                        "path" => "local://tuning/$(String(project_id))/$(String(study_id))/trial-$(index).json",
                        "generatedAt" => String(timestamp),
                    ),
                ],
            ),
        )
    end
    return trials
end

function tuning_binary_auc(actual::Vector{Float64}, predicted::Vector{Float64})
    n = min(length(actual), length(predicted))
    n == 0 && return 0.0
    labels = sort(unique(round(value) for value in actual[1:n]))
    length(labels) == 2 || return 0.0
    positive_label = labels[2]
    positive_count = sum(round(actual[index]) == positive_label for index in 1:n)
    negative_count = n - positive_count
    (positive_count == 0 || negative_count == 0) && return 0.0
    ordered = sort([(Float64(predicted[index]), round(actual[index])) for index in 1:n], by = item -> item[1])
    rank_sum = 0.0
    index = 1
    while index <= n
        tie_end = index
        while tie_end < n && ordered[tie_end + 1][1] == ordered[index][1]
            tie_end += 1
        end
        average_rank = (index + tie_end) / 2
        for rank_index in index:tie_end
            ordered[rank_index][2] == positive_label && (rank_sum += average_rank)
        end
        index = tie_end + 1
    end
    return round((rank_sum - (positive_count * (positive_count + 1) / 2)) / (positive_count * negative_count); digits = 6)
end

function tuning_metric_from_errors(metric::AbstractString, actual::Vector{Float64}, predicted::Vector{Float64})
    n = min(length(actual), length(predicted))
    n == 0 && return 0.0
    errors = [actual[index] - predicted[index] for index in 1:n]
    metric_name = safe_tuning_token(metric)
    if metric_name in ("mae", "mean-absolute", "mean-absolute-error")
        return round(sum(abs(error) for error in errors) / n; digits = 6)
    elseif metric_name in ("mse", "mean-squared-error")
        return round(sum(error^2 for error in errors) / n; digits = 6)
    elseif metric_name in ("rmse", "root-mean-squared-error", "root-mean-square")
        return round(sqrt(sum(error^2 for error in errors) / n); digits = 6)
    elseif metric_name in ("r2", "r-squared")
        mean_actual = JuliaFlowDataScienceProjectStatistics.sample_mean(actual[1:n])
        sst = sum((value - mean_actual)^2 for value in actual[1:n])
        sse = sum(error^2 for error in errors)
        return round(sst == 0.0 ? 0.0 : 1.0 - (sse / sst); digits = 6)
    elseif metric_name in ("accuracy", "f1", "f1-score", "auc")
        metric_name == "auc" && return tuning_binary_auc(actual, predicted)
        rounded_actual = [round(value) for value in actual[1:n]]
        rounded_predicted = [round(value) for value in predicted[1:n]]
        correct = sum(rounded_actual[index] == rounded_predicted[index] for index in 1:n)
        if metric_name == "accuracy"
            return round(correct / n; digits = 6)
        end
        positive_label = maximum(rounded_actual)
        true_positive = sum(rounded_actual[index] == positive_label && rounded_predicted[index] == positive_label for index in 1:n)
        predicted_positive = sum(rounded_predicted[index] == positive_label for index in 1:n)
        actual_positive = sum(rounded_actual[index] == positive_label for index in 1:n)
        precision = predicted_positive == 0 ? 0.0 : true_positive / predicted_positive
        recall = actual_positive == 0 ? 0.0 : true_positive / actual_positive
        return round(precision + recall == 0.0 ? 0.0 : 2 * precision * recall / (precision + recall); digits = 6)
    end
    return round(max(0.0, 1.0 - (sum(abs(error) for error in errors) / n)); digits = 6)
end

function tuning_lower_is_better(metric::AbstractString)
    metric_name = safe_tuning_token(metric)
    return metric_name in ("mae", "mean-absolute", "mean-absolute-error", "mse", "mean-squared-error", "rmse", "root-mean-squared-error", "root-mean-square")
end

function tuning_candidate_feature_sets(feature_columns::Vector{String}, max_trials::Integer)
    candidates = Vector{Vector{String}}()
    for feature in feature_columns
        push!(candidates, [feature])
        length(candidates) >= max_trials && return candidates
    end
    for count in 2:length(feature_columns)
        push!(candidates, feature_columns[1:count])
        length(candidates) >= max_trials && return candidates
    end
    return candidates
end

function tuning_candidate_specs(feature_columns::Vector{String}, max_trials::Integer; classifier_mode::Bool = false)
    base_candidates = tuning_candidate_feature_sets(feature_columns, max_trials)
    specs = Dict{String,Any}[]
    for (index, candidate) in enumerate(base_candidates)
        push!(
            specs,
            Dict{String,Any}(
                "candidateIndex" => index,
                "featureColumns" => candidate,
                "hyperparameters" => classifier_mode ?
                    Dict{String,Any}("classificationThreshold" => 0.5) :
                    Dict{String,Any}("regularizationStrength" => 0.0),
            ),
        )
        length(specs) >= max_trials && return specs
    end
    variants = classifier_mode ? [0.4, 0.6, 0.3, 0.7] : [0.01, 0.1, 1.0, 10.0]
    for variant in variants
        for (index, candidate) in enumerate(base_candidates)
            push!(
                specs,
                Dict{String,Any}(
                    "candidateIndex" => index,
                    "featureColumns" => candidate,
                    "hyperparameters" => classifier_mode ?
                        Dict{String,Any}("classificationThreshold" => variant) :
                        Dict{String,Any}("regularizationStrength" => variant),
                ),
            )
            length(specs) >= max_trials && return specs
        end
    end
    return specs
end

function tuning_predictions_from_ols(ols::AbstractDict, feature_pairs::AbstractVector, validation_range; regularization_strength::Real = 0.0)
    shrink = 1.0 / (1.0 + max(Float64(regularization_strength), 0.0))
    if length(feature_pairs) == 1 && haskey(ols, "slope")
        feature_values = feature_pairs[1].second
        return [Float64(ols["intercept"]) + shrink * Float64(ols["slope"]) * feature_values[row] for row in validation_range]
    end
    haskey(ols, "slopes") || return nothing
    slopes = get(ols, "slopes", Dict{String,Any}())
    return [
        Float64(ols["intercept"]) + sum(shrink * Float64(get(slopes, String(pair.first), 0.0)) * pair.second[row] for pair in feature_pairs)
        for row in validation_range
    ]
end

function tuning_metric_predictions(metric::AbstractString, predictions::Vector{Float64}, classifier, threshold::Real)
    classifier === nothing && return predictions
    safe_tuning_token(metric) == "auc" && return predictions
    positive_label = Float64(get(classifier, "positiveLabel", 1.0))
    negative_label = Float64(get(classifier, "negativeLabel", 0.0))
    cutoff = Float64(threshold)
    return [probability >= cutoff ? positive_label : negative_label for probability in predictions]
end

function tuning_ols_coefficients(ols::AbstractDict, model_kind::AbstractString, regularization_strength::Real)
    shrink = 1.0 / (1.0 + max(Float64(regularization_strength), 0.0))
    if model_kind == "local_csv_single_feature_ols"
        return Dict{String,Any}(
            "intercept" => ols["intercept"],
            "slope" => round(shrink * Float64(ols["slope"]); digits = 6),
            "unregularizedSlope" => ols["slope"],
        )
    end
    slopes = get(ols, "slopes", Dict{String,Any}())
    return Dict{String,Any}(
        "intercept" => ols["intercept"],
        "slopes" => Dict(String(key) => round(shrink * Float64(value); digits = 6) for (key, value) in pairs(slopes)),
        "unregularizedSlopes" => slopes,
    )
end

function tuning_classifier_requested(algorithm::AbstractString, target_values::Vector{Float64})
    algorithm_name = lowercase(String(algorithm))
    classifier_algorithm = occursin("class", algorithm_name) || occursin("logistic", algorithm_name) || occursin("xgboost", algorithm_name)
    return classifier_algorithm && length(unique(target_values)) == 2
end

function local_csv_validation_tuning_trials(
    project_id::AbstractString,
    study_id::AbstractString,
    algorithm::AbstractString,
    metric_names::AbstractVector,
    max_trials::Integer,
    timestamp::AbstractString,
    dataset::AbstractDict,
    source_path::AbstractString,
    target_column::AbstractString,
    split_plan::AbstractDict,
)
    table = JuliaFlowDataScienceProjectStatistics.parse_simple_csv(source_path)
    table === nothing && return nothing
    numeric_columns, _ = JuliaFlowDataScienceProjectStatistics.simple_numeric_columns(table)
    haskey(numeric_columns, String(target_column)) || return nothing
    feature_columns = JuliaFlowDataScienceProjectStatistics.candidate_numeric_feature_columns(numeric_columns, target_column)
    isempty(feature_columns) && return nothing
    target_values = numeric_columns[String(target_column)]
    row_count = length(target_values)
    for column in feature_columns
        row_count = min(row_count, length(numeric_columns[column]))
    end
    validation_count = max(1, round(Int, row_count * Float64(get(split_plan, "validationFraction", 0.0))))
    test_count = max(0, round(Int, row_count * Float64(get(split_plan, "testFraction", 0.0))))
    train_count = row_count - validation_count - test_count
    train_count >= 2 || return nothing
    train_count + validation_count <= row_count || return nothing
    validation_range = (train_count + 1):(train_count + validation_count)
    train_target = target_values[1:train_count]
    validation_target = target_values[validation_range]
    primary_metric = String(first(metric_names))
    lower_is_better = tuning_lower_is_better(primary_metric)
    classifier_mode = tuning_classifier_requested(algorithm, target_values[1:row_count])
    candidate_specs = tuning_candidate_specs(String.(feature_columns), max_trials; classifier_mode = classifier_mode)
    isempty(candidate_specs) && return nothing
    trials = Dict{String,Any}[]
    best_index = 0
    best_value = lower_is_better ? Inf : -Inf
    for (index, spec) in enumerate(candidate_specs)
        candidate = Vector{String}(spec["featureColumns"])
        hyperparameters = Dict{String,Any}(String(key) => value for (key, value) in pairs(get(spec, "hyperparameters", Dict{String,Any}())))
        regularization_strength = Float64(get(hyperparameters, "regularizationStrength", 0.0))
        classification_threshold = Float64(get(hyperparameters, "classificationThreshold", 0.5))
        feature_pairs = [column => numeric_columns[column] for column in candidate]
        train_pairs = [column => numeric_columns[column][1:train_count] for column in candidate]
        classifier = classifier_mode ? JuliaFlowDataScienceProjectStatistics.simple_binary_centroid_classifier(train_target, train_pairs) : nothing
        ols = classifier === nothing ? (
            length(candidate) == 1 ?
                JuliaFlowDataScienceProjectStatistics.simple_linear_ols(train_target, train_pairs[1].second) :
                JuliaFlowDataScienceProjectStatistics.simple_multi_linear_ols(train_target, train_pairs)
        ) : nothing
        (classifier === nothing && ols === nothing) && continue
        predictions = classifier !== nothing ?
            JuliaFlowDataScienceProjectStatistics.binary_centroid_probabilities(classifier, feature_pairs, validation_range) :
            tuning_predictions_from_ols(ols, feature_pairs, validation_range; regularization_strength = regularization_strength)
        predictions === nothing && continue
        metrics = Dict{String,Any}()
        for metric in metric_names
            metric_predictions = tuning_metric_predictions(String(metric), predictions, classifier, classification_threshold)
            metrics[String(metric)] = tuning_metric_from_errors(String(metric), validation_target, metric_predictions)
        end
        selection_value = Float64(get(metrics, primary_metric, 0.0))
        if best_index == 0 || (lower_is_better ? selection_value < best_value : selection_value > best_value)
            best_index = length(trials) + 1
            best_value = selection_value
        end
        model_kind = classifier !== nothing ? "local_csv_binary_centroid_classifier" : (length(candidate) == 1 ? "local_csv_single_feature_ols" : "local_csv_multi_feature_ols")
        model_family = classifier !== nothing ? "local_csv_binary_centroid" : "local_csv_ols"
        coefficients = if classifier !== nothing
            Dict{String,Any}(
                "positiveLabel" => classifier["positiveLabel"],
                "negativeLabel" => classifier["negativeLabel"],
                "positivePrior" => classifier["positivePrior"],
                "positiveMeans" => classifier["positiveMeans"],
                "negativeMeans" => classifier["negativeMeans"],
                "featureScales" => classifier["featureScales"],
            )
        elseif model_kind == "local_csv_single_feature_ols"
            tuning_ols_coefficients(ols, model_kind, regularization_strength)
        else
            tuning_ols_coefficients(ols, model_kind, regularization_strength)
        end
        push!(
            trials,
            Dict{String,Any}(
                "trialId" => "$(String(study_id))-trial-$(index)",
                "parameters" => Dict(
                    "algorithm" => String(algorithm),
                    "modelFamily" => model_family,
                    "featureColumns" => candidate,
                    "candidateIndex" => Int(get(spec, "candidateIndex", index)),
                    "searchIndex" => index,
                    "hyperparameters" => hyperparameters,
                ),
                "metrics" => metrics,
                "validationEvidence" => Dict{String,Any}(
                    "executionMode" => "local_csv_validation_tuning",
                    "searchMode" => "feature_set_and_hyperparameter_grid",
                    "sourceRef" => String(get(dataset, "sourceUri", "")),
                    "targetColumn" => String(target_column),
                    "modelKind" => model_kind,
                    "featureColumn" => first(candidate),
                    "featureColumns" => candidate,
                    "hyperparameters" => hyperparameters,
                    "selectionMetric" => primary_metric,
                    "selectionDirection" => lower_is_better ? "lower_is_better" : "higher_is_better",
                    "selectionValue" => selection_value,
                    "trainRowCount" => train_count,
                    "validationRowCount" => validation_count,
                    "testRowCount" => test_count,
                    "coefficients" => coefficients,
                ),
                "artifactRefs" => [
                    Dict(
                        "refId" => "artifact-$(String(study_id))-trial-$(index)",
                        "kind" => "tuning_trial",
                        "localOnly" => true,
                        "path" => "local://tuning/$(String(project_id))/$(String(study_id))/trial-$(index).json",
                        "generatedAt" => String(timestamp),
                    ),
                ],
            ),
        )
    end
    isempty(trials) && return nothing
    best_index == 0 && (best_index = 1)
    for (index, trial) in enumerate(trials)
        trial["selected"] = index == best_index
        trial["validationEvidence"]["selected"] = index == best_index
    end
    return trials
end

function tuning_study_record(
    study_id::AbstractString,
    training_plan_id::AbstractString,
    trials::AbstractVector,
    validation_context::AbstractDict,
    timestamp::AbstractString,
)
    return Dict{String,Any}(
        "tuningStudyId" => String(study_id),
        "trainingPlanId" => String(training_plan_id),
        "validationOnly" => true,
        "trials" => [Dict{String,Any}(String(key) => value for (key, value) in pairs(trial)) for trial in trials],
        "bestTrialId" => begin
            selected = findfirst(trial -> Bool(get(trial, "selected", false)), trials)
            selected === nothing ? trials[1]["trialId"] : trials[selected]["trialId"]
        end,
        "validationEvidence" => Dict{String,Any}(String(key) => value for (key, value) in pairs(validation_context)),
        "createdAt" => String(timestamp),
    )
end

function tuning_output_refs(trials::AbstractVector)
    output_refs = Dict{String,Any}[]
    for trial in trials
        append!(output_refs, get(trial, "artifactRefs", Dict{String,Any}[]))
    end
    return output_refs
end

end
