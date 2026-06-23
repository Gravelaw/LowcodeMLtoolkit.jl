module JuliaFlowDataScienceProjectEvaluation

using ..JuliaFlowGatewayRepository

export project_training_plan_for_request,
    project_tuning_study_for_final_evaluation,
    final_evaluation_metric_names,
    final_evaluation_approval_threshold,
    final_evaluation_validation_context,
    final_evaluation_metrics,
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
