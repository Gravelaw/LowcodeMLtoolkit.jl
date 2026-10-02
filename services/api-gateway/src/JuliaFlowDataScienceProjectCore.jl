module JuliaFlowDataScienceProjectCore

using ..JuliaFlowGatewayRepository
using ..JuliaFlowDataScienceProjectSplits

export project_id_from_body,
    materialize_project_record,
    validate_project_local_ref!,
    validate_project_name,
    validate_project_dataset_records!

const DATA_SCIENCE_PROJECT_ARRAY_FIELDS = Dict(
    "datasets" => :datasets,
    "schemaContracts" => :schema_contracts,
    "splitPlans" => :split_plans,
    "splitAssignments" => :split_assignments,
    "validationFolds" => :validation_folds,
    "finalTestLocks" => :final_test_locks,
    "projectJobs" => :project_jobs,
    "transformFitApplyRecords" => :transform_fit_apply_records,
    "statisticalAnalysisRuns" => :statistical_analysis_runs,
    "trainingPlans" => :training_plans,
    "tuningStudies" => :tuning_studies,
    "evaluationReports" => :evaluation_reports,
    "predictionExports" => :prediction_exports,
    "modelRegistryRecords" => :model_registry_records,
    "modelLifecycleRecords" => :model_lifecycle_records,
    "monitoringBaselines" => :monitoring_baselines,
    "driftReports" => :drift_reports,
    "reproducibilityEvidence" => :reproducibility_evidence,
)

# These records are produced by action handlers, never by aggregate requests.
# Repository restoration uses its own loader and preserves historical records.
const SERVER_OWNED_PROJECT_FIELDS = (
    "projectJobs", "transformFitApplyRecords", "statisticalAnalysisRuns",
    "tuningStudies", "evaluationReports", "predictionExports",
    "modelRegistryRecords", "modelLifecycleRecords", "monitoringBaselines",
    "driftReports", "reproducibilityEvidence",
)

function protect_execution_evidence!(existing, body)
    normalize = JuliaFlowGatewayRepository.JuliaFlowProjectPayloadValidation.contract_value
    for key in SERVER_OWNED_PROJECT_FIELDS
        haskey(body, key) || continue
        before = existing === nothing ? Any[] : getfield(existing, DATA_SCIENCE_PROJECT_ARRAY_FIELDS[key])
        normalize(before) == normalize(body[key]) ||
            error("data science project $(key) is server-owned execution evidence; use the project action")
    end
    existing === nothing && return nothing
    # Plans remain declarative until a server-produced result binds them.
    protected = Set(get(record, "trainingPlanId", "") for record in
        [existing.tuning_studies; existing.evaluation_reports])
    delete!(protected, "")
    if !isempty(protected) && haskey(body, "trainingPlans")
        before = [normalize(record) for record in existing.training_plans if get(record, "trainingPlanId", "") in protected]
        after = [normalize(record) for record in body["trainingPlans"] if get(record, "trainingPlanId", "") in protected]
        before == after || error("data science project executed training plans are immutable; create a new plan id")
    end
    return nothing
end

function safe_project_id(value::AbstractString)
    normalized = lowercase(strip(String(value)))
    normalized = replace(normalized, r"[^a-z0-9._-]+" => "-")
    normalized = strip(normalized, ['-', '.', '_'])
    isempty(normalized) && return "workflow-dataset"
    return first(normalized, min(lastindex(normalized), 80))
end

function normalized_record_vector(value)
    value isa AbstractVector || error("project child records must be arrays")
    all(entry -> entry isa AbstractDict, value) || error("project child records must be objects")
    return [Dict{String,Any}(String(key) => item for (key, item) in pairs(entry)) for entry in value]
end

function validate_project_local_ref!(value::AbstractString, label::AbstractString)
    uri = strip(String(value))
    isempty(uri) && error("data science project $(label) cannot be empty")
    (occursin('\0', uri) || occursin('\n', uri) || occursin('\r', uri)) && error("data science project $(label) contains invalid characters")
    normalized = replace(uri, "\\" => "/")
    lower = lowercase(normalized)
    startswith(lower, "local://") || error("data science project $(label) must use local:// managed local artifact refs")
    prefix_end = nextind(normalized, firstindex(normalized), length("local://") - 1)
    local_path = lastindex(normalized) > prefix_end ? normalized[nextind(normalized, prefix_end):end] : ""
    isempty(strip(local_path, ['/'])) && error("data science project $(label) local path cannot be empty")
    segments = split(local_path, '/'; keepempty = false)
    any(segment -> segment == "." || segment == "..", segments) && error("data science project $(label) cannot contain path traversal")
    occursin("%2e", lower) && error("data science project $(label) cannot contain encoded traversal")
    return nothing
end

function validate_project_dataset_records!(records::Vector{Dict{String,Any}})
    seen = Set{String}()
    for record in records
        haskey(record, "datasetId") || error("data science project datasetId required")
        dataset_id = safe_project_id(String(record["datasetId"]))
        isempty(dataset_id) && error("data science project datasetId required")
        dataset_id in seen && error("data science project datasetId duplicated: $(dataset_id)")
        push!(seen, dataset_id)
        haskey(record, "sourceUri") || error("data science project dataset sourceUri required")
        Bool(get(record, "localOnly", true)) || error("data science project dataset localOnly must be true")
        validate_project_local_ref!(String(record["sourceUri"]), "dataset sourceUri")
        if haskey(record, "artifactRef") && record["artifactRef"] !== nothing
            validate_project_local_ref!(String(record["artifactRef"]), "dataset artifactRef")
        end
    end
    return records
end

function validate_project_name(body::AbstractDict)
    haskey(body, "name") || error("data science project missing name")
    name = strip(String(body["name"]))
    isempty(name) && error("data science project name cannot be empty")
    return name
end

function validate_project_schema_version(body::AbstractDict, existing::Union{Nothing,JuliaFlowGatewayRepository.DataScienceProjectRecord})
    schema_version = String(get(body, "schemaVersion", existing === nothing ? "1.0" : existing.schema_version))
    schema_version == "1.0" || error("data science project schemaVersion must be 1.0")
    return schema_version
end

function project_id_from_body(body::AbstractDict, name::AbstractString)
    requested = haskey(body, "projectId") ? String(body["projectId"]) : name
    project_id = safe_project_id(requested)
    isempty(project_id) && error("data science project id cannot be empty")
    return project_id
end

function validate_project_id_matches!(body::AbstractDict, project_id::AbstractString)
    haskey(body, "projectId") || return nothing
    safe_project_id(String(body["projectId"])) == project_id || error("project id mismatch")
    return nothing
end

function materialize_project_record(
    body::AbstractDict;
    existing::Union{Nothing,JuliaFlowGatewayRepository.DataScienceProjectRecord} = nothing,
    project_id_override::Union{Nothing,AbstractString} = nothing,
)
    JuliaFlowGatewayRepository.JuliaFlowProjectPayloadValidation.validate_project_children!(body)
    JuliaFlowDataScienceProjectSplits.protect_membership!(existing, body)
    protect_execution_evidence!(existing, body)
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    name = haskey(body, "name") ? strip(String(body["name"])) : (existing === nothing ? validate_project_name(body) : existing.name)
    isempty(name) && error("data science project name cannot be empty")
    project_id = project_id_override === nothing ? project_id_from_body(body, name) : String(project_id_override)
    validate_project_id_matches!(body, project_id)
    schema_version = validate_project_schema_version(body, existing)

    project = JuliaFlowGatewayRepository.DataScienceProjectRecord(
        project_id = project_id,
        schema_version = schema_version,
        name = name,
        description = haskey(body, "description") && body["description"] !== nothing ? String(body["description"]) : (existing === nothing ? nothing : existing.description),
        local_only = Bool(get(body, "localOnly", existing === nothing ? true : existing.local_only)),
        created_at = existing === nothing ? timestamp : existing.created_at,
        updated_at = timestamp,
    )

    for (json_key, field_name) in DATA_SCIENCE_PROJECT_ARRAY_FIELDS
        if haskey(body, json_key)
            records = normalized_record_vector(body[json_key])
            json_key == "datasets" && validate_project_dataset_records!(records)
            # Own nested values even for a validated echo; request mutation must
            # never mutate evidence retained in the existing project.
            setfield!(project, field_name, deepcopy(records))
        elseif existing !== nothing
            setfield!(project, field_name, deepcopy(getfield(existing, field_name)))
        end
    end

    return project
end

end
