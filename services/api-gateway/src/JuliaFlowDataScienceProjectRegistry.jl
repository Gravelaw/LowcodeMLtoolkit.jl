module JuliaFlowDataScienceProjectRegistry

using ..JuliaFlowGatewayRepository

export project_for_validation_context,
    upsert_model_registry_record!,
    upsert_model_lifecycle_record!,
    model_lifecycle_action_state

function normalized_dict(value)
    return Dict{String,Any}(String(key) => item for (key, item) in pairs(value))
end

function project_for_validation_context(
    projects::AbstractDict,
    validation_context::AbstractDict,
    action::AbstractString,
)
    project_id = String(get(validation_context, "projectId", ""))
    isempty(strip(project_id)) && return nothing
    haskey(projects, project_id) || error("$(String(action)) project not found: $(project_id)")
    return projects[project_id]
end

function upsert_model_registry_record!(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    model_record::AbstractDict,
)
    record = normalized_dict(model_record)
    model_id = String(get(record, "modelId", ""))
    isempty(strip(model_id)) && error("model registry modelId required")
    index = findfirst(item -> String(get(item, "modelId", "")) == model_id, project.model_registry_records)
    remaining = index === nothing ? project.model_registry_records : [
        item for (item_index, item) in enumerate(project.model_registry_records) if item_index != index
    ]
    project.model_registry_records = [record, remaining...]
    project.updated_at = String(get(record, "updatedAt", JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()))
    return record
end

function upsert_model_lifecycle_record!(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    validation_context::AbstractDict,
    model_id::AbstractString,
    lifecycle_state::AbstractString;
    evaluation_report_id::Union{Nothing,AbstractString} = nothing,
    deployed_endpoint_id::Union{Nothing,AbstractString} = nothing,
    updated_at::Union{Nothing,AbstractString} = nothing,
)
    timestamp = updated_at === nothing ? JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp() : String(updated_at)
    index = findfirst(record -> String(get(record, "modelId", "")) == String(model_id), project.model_lifecycle_records)
    existing = index === nothing ? Dict{String,Any}() : normalized_dict(project.model_lifecycle_records[index])
    record = Dict{String,Any}(
        "modelId" => String(model_id),
        "state" => String(lifecycle_state),
        "updatedAt" => timestamp,
    )

    report_id = evaluation_report_id === nothing ? String(get(validation_context, "evaluationReportId", get(existing, "evaluationReportId", ""))) : String(evaluation_report_id)
    isempty(strip(report_id)) || (record["evaluationReportId"] = report_id)
    endpoint_id = deployed_endpoint_id === nothing ? String(get(existing, "deployedEndpointId", "")) : String(deployed_endpoint_id)
    isempty(strip(endpoint_id)) || (record["deployedEndpointId"] = endpoint_id)
    haskey(existing, "rollbackModelId") && (record["rollbackModelId"] = String(existing["rollbackModelId"]))

    remaining = index === nothing ? project.model_lifecycle_records : [
        item for (item_index, item) in enumerate(project.model_lifecycle_records) if item_index != index
    ]
    project.model_lifecycle_records = [record, remaining...]
    project.updated_at = timestamp
    return record
end

function model_lifecycle_action_state(action::AbstractString)
    action == "mark_rollback_ready" && return "rollback_ready"
    action == "mark_rolled_back" && return "rolled_back"
    action == "request_retraining" && return "retraining_requested"
    error("model lifecycle action must be mark_rollback_ready, mark_rolled_back, or request_retraining")
end

end
