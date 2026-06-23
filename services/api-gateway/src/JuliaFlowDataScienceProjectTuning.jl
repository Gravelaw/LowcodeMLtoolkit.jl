module JuliaFlowDataScienceProjectTuning

using ..JuliaFlowGatewayRepository

export project_split_plan_for_request,
    validate_tuning_split_context,
    tuning_metric_names,
    tuning_max_trials,
    tuning_training_plan_record,
    upsert_training_plan!,
    tuning_trials,
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
        "bestTrialId" => trials[1]["trialId"],
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
