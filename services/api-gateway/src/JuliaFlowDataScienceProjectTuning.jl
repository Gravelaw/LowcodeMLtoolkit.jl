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

function tuning_predictions_from_ols(ols::AbstractDict, feature_pairs::AbstractVector, validation_range)
    if length(feature_pairs) == 1 && haskey(ols, "slope")
        feature_values = feature_pairs[1].second
        return [Float64(ols["intercept"]) + Float64(ols["slope"]) * feature_values[row] for row in validation_range]
    end
    haskey(ols, "slopes") || return nothing
    slopes = get(ols, "slopes", Dict{String,Any}())
    return [
        Float64(ols["intercept"]) + sum(Float64(get(slopes, String(pair.first), 0.0)) * pair.second[row] for pair in feature_pairs)
        for row in validation_range
    ]
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
    candidates = tuning_candidate_feature_sets(String.(feature_columns), max_trials)
    isempty(candidates) && return nothing
    primary_metric = String(first(metric_names))
    lower_is_better = tuning_lower_is_better(primary_metric)
    trials = Dict{String,Any}[]
    best_index = 0
    best_value = lower_is_better ? Inf : -Inf
    for (index, candidate) in enumerate(candidates)
        feature_pairs = [column => numeric_columns[column] for column in candidate]
        train_pairs = [column => numeric_columns[column][1:train_count] for column in candidate]
        ols = length(candidate) == 1 ?
            JuliaFlowDataScienceProjectStatistics.simple_linear_ols(train_target, train_pairs[1].second) :
            JuliaFlowDataScienceProjectStatistics.simple_multi_linear_ols(train_target, train_pairs)
        ols === nothing && continue
        predictions = tuning_predictions_from_ols(ols, feature_pairs, validation_range)
        predictions === nothing && continue
        metrics = Dict{String,Any}()
        for metric in metric_names
            metrics[String(metric)] = tuning_metric_from_errors(String(metric), validation_target, predictions)
        end
        selection_value = Float64(get(metrics, primary_metric, 0.0))
        if best_index == 0 || (lower_is_better ? selection_value < best_value : selection_value > best_value)
            best_index = length(trials) + 1
            best_value = selection_value
        end
        model_kind = length(candidate) == 1 ? "local_csv_single_feature_ols" : "local_csv_multi_feature_ols"
        coefficients = model_kind == "local_csv_single_feature_ols" ?
            Dict{String,Any}("intercept" => ols["intercept"], "slope" => ols["slope"]) :
            Dict{String,Any}("intercept" => ols["intercept"], "slopes" => ols["slopes"])
        push!(
            trials,
            Dict{String,Any}(
                "trialId" => "$(String(study_id))-trial-$(index)",
                "parameters" => Dict(
                    "algorithm" => String(algorithm),
                    "modelFamily" => "local_csv_ols",
                    "featureColumns" => candidate,
                    "candidateIndex" => index,
                ),
                "metrics" => metrics,
                "validationEvidence" => Dict{String,Any}(
                    "executionMode" => "local_csv_validation_tuning",
                    "sourceRef" => String(get(dataset, "sourceUri", "")),
                    "targetColumn" => String(target_column),
                    "modelKind" => model_kind,
                    "featureColumn" => first(candidate),
                    "featureColumns" => candidate,
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
