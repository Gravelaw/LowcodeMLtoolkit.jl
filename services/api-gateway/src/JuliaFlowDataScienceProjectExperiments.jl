module JuliaFlowDataScienceProjectExperiments

using ..JuliaFlowGatewayRepository

export project_has_dataset,
    ml_project_for_dataset,
    ml_split_plan_for_request,
    validate_ml_experiment_project_context

function project_has_dataset(project::JuliaFlowGatewayRepository.DataScienceProjectRecord, dataset_id::AbstractString)
    return any(dataset -> String(get(dataset, "datasetId", "")) == String(dataset_id), project.datasets)
end

function ml_project_for_dataset(projects::AbstractDict, body::AbstractDict, dataset_id::AbstractString)
    if haskey(body, "projectId")
        project_id = String(body["projectId"])
        haskey(projects, project_id) || error("ml experiment project not found: $(project_id)")
        project = projects[project_id]
        project_has_dataset(project, dataset_id) || error("ml experiment dataset not registered in project: $(String(dataset_id))")
        return project
    end
    matches = [project for project in values(projects) if project_has_dataset(project, dataset_id)]
    isempty(matches) && return nothing
    length(matches) == 1 || error("ml experiment projectId required for dataset with multiple projects: $(String(dataset_id))")
    return matches[1]
end

function ml_split_plan_for_request(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    body::AbstractDict,
    dataset_id::AbstractString,
)
    plans = [plan for plan in project.split_plans if String(get(plan, "datasetId", "")) == String(dataset_id)]
    isempty(plans) && error("ml experiment split plan required for dataset: $(String(dataset_id))")
    if haskey(body, "splitPlanId")
        split_plan_id = String(body["splitPlanId"])
        match = findfirst(plan -> String(get(plan, "splitPlanId", "")) == split_plan_id, plans)
        match === nothing && error("ml experiment split plan not found: $(split_plan_id)")
        return plans[match]
    end
    length(plans) == 1 || error("ml experiment splitPlanId required when multiple split plans exist")
    return plans[1]
end

function validate_ml_experiment_project_context(projects::AbstractDict, body::AbstractDict, dataset_id::AbstractString)
    project = ml_project_for_dataset(projects, body, dataset_id)
    project === nothing && return Dict{String,Any}()
    split_plan = ml_split_plan_for_request(project, body, dataset_id)
    validation_fraction = Float64(get(split_plan, "validationFraction", 0.0))
    test_fraction = Float64(get(split_plan, "testFraction", 0.0))
    validation_fraction > 0 || error("ml experiment validation split required")
    test_fraction > 0 || error("ml experiment test split required")
    final_test_policy = String(get(body, "finalTestPolicy", "forbid_final_test"))
    final_test_policy in ("forbid_final_test", "use_final_test") || error("ml experiment finalTestPolicy invalid")
    final_test_policy == "use_final_test" && error("ml experiment final test data cannot be used for training or tuning")
    return Dict{String,Any}(
        "projectId" => project.project_id,
        "splitPlanId" => String(get(split_plan, "splitPlanId", "")),
        "splitStrategy" => String(get(split_plan, "strategy", "")),
        "finalTestPolicy" => final_test_policy,
        "validationFraction" => validation_fraction,
        "testFraction" => test_fraction,
    )
end

end
