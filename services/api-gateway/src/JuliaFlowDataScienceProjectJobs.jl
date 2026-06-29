module JuliaFlowDataScienceProjectJobs

using ..JuliaFlowGatewayRepository
using UUIDs

export project_job_resource_evidence,
    project_job_record,
    record_project_job!,
    project_job_execution_record,
    project_job_execution_evidence

function normalized_dict(value)
    return Dict{String,Any}(String(key) => item for (key, item) in pairs(value))
end

function normalized_refs(items::AbstractVector)
    return [normalized_dict(item) for item in items]
end

function project_job_resource_evidence(
    compute_settings::AbstractDict,
    gpu_registry::AbstractDict;
    execution_mode::AbstractString = "local_project_route",
    cpu_thread_count::Integer = Threads.nthreads(),
)
    requested_backend = String(compute_settings["selectedBackend"])
    devices = get(gpu_registry, "devices", Any[])
    hardware_count = count(device -> String(get(device, "mode", "hardware")) == "hardware", devices)
    simulated_count = count(device -> String(get(device, "mode", "hardware")) == "simulated", devices)
    selected_backend =
        requested_backend == "cuda" && hardware_count == 0 ? "cpu" :
        requested_backend == "simulated_cuda" && simulated_count == 0 ? "cpu" :
        requested_backend
    dispatch_lane = selected_backend == "cpu" ? "cpu" : "gpu"
    fallback_reason =
        dispatch_lane == "gpu" ? "none" :
        requested_backend == "cuda" && hardware_count == 0 ? "no_cuda_device_available" :
        requested_backend == "simulated_cuda" && simulated_count == 0 ? "no_simulated_cuda_device_available" :
        "cpu_selected"
    return Dict{String,Any}(
        "executionMode" => String(execution_mode),
        "requestedBackend" => requested_backend,
        "selectedBackend" => selected_backend,
        "dispatchLane" => dispatch_lane,
        "workerPool" => dispatch_lane == "gpu" ? "local-$(selected_backend)" : "local-cpu",
        "schedulerPolicy" => String(compute_settings["schedulerPolicy"]),
        "cpuThreadCount" => Int(cpu_thread_count),
        "cpuWorkerConcurrency" => Int(compute_settings["cpuWorkerConcurrency"]),
        "cpuMemoryLimitBytes" => Int(compute_settings["cpuMemoryLimitBytes"]),
        "gpuReadinessStatus" => Int(get(gpu_registry, "device_count", 0)) > 0 ? "available" : "cpu_fallback",
        "gpuHardwareDeviceCount" => hardware_count,
        "gpuSimulatedDeviceCount" => simulated_count,
        "gpuFallbackReason" => fallback_reason,
    )
end

function project_job_record(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    job_type::AbstractString;
    status::AbstractString = "completed",
    dataset_id::Union{Nothing,AbstractString} = nothing,
    split_plan_id::Union{Nothing,AbstractString} = nothing,
    source_record_id::Union{Nothing,AbstractString} = nothing,
    output_refs::AbstractVector = Any[],
    resource_evidence::Union{Nothing,AbstractDict} = nothing,
    execution_evidence::Union{Nothing,AbstractDict} = nothing,
    error_message::Union{Nothing,AbstractString} = nothing,
    started_at::Union{Nothing,AbstractString} = nothing,
    finished_at::Union{Nothing,AbstractString} = nothing,
)
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    job = Dict{String,Any}(
        "jobId" => "job-" * replace(string(uuid4()), "-" => ""),
        "projectId" => project.project_id,
        "jobType" => String(job_type),
        "status" => String(status),
        "outputRefs" => normalized_refs(output_refs),
        "resourceEvidence" => resource_evidence === nothing ? Dict{String,Any}() : normalized_dict(resource_evidence),
        "startedAt" => started_at === nothing ? timestamp : String(started_at),
    )
    dataset_id === nothing || (job["datasetId"] = String(dataset_id))
    split_plan_id === nothing || (job["splitPlanId"] = String(split_plan_id))
    source_record_id === nothing || (job["sourceRecordId"] = String(source_record_id))
    execution_evidence === nothing || (job["executionEvidence"] = normalized_dict(execution_evidence))
    finished_at === nothing || (job["finishedAt"] = String(finished_at))
    error_message === nothing || (job["errorMessage"] = String(error_message))
    return job
end

function record_project_job!(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    job_type::AbstractString;
    kwargs...
)
    job = project_job_record(project, job_type; kwargs...)
    project.project_jobs = [job, project.project_jobs...]
    return job
end

function project_job_execution_record(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    job_type::AbstractString;
    workflow_id::AbstractString,
    checkpoint_tag::AbstractString,
    dataset_id::Union{Nothing,AbstractString} = nothing,
    source_record_id::Union{Nothing,AbstractString} = nothing,
    output_refs::AbstractVector = Any[],
    resource_evidence::Union{Nothing,AbstractDict} = nothing,
    started_at::Union{Nothing,AbstractString} = nothing,
    finished_at::Union{Nothing,AbstractString} = nothing,
    plan::AbstractVector = String[],
)
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    started = started_at === nothing ? timestamp : String(started_at)
    finished = finished_at === nothing ? started : String(finished_at)
    execution_plan = isempty(plan) ? ["validate_project_state", "materialize_project_artifact"] : [String(item) for item in plan]
    execution_id = "dsjob-" * replace(string(uuid4()), "-" => "")
    worker_id = "project-job-worker-" * execution_id[(lastindex(execution_id) - 7):lastindex(execution_id)]
    normalized_resource_evidence = resource_evidence === nothing ? Dict{String,Any}() : normalized_dict(resource_evidence)
    worker_dispatch = Dict{String,Any}(
        "orchestrationMode" => "gateway_worker_dispatch",
        "dispatchStatus" => "completed",
        "workerId" => worker_id,
        "workerPool" => String(get(normalized_resource_evidence, "workerPool", "local-cpu")),
        "dispatchLane" => String(get(normalized_resource_evidence, "dispatchLane", "cpu")),
        "executionMode" => String(get(normalized_resource_evidence, "executionMode", "local_project_job")),
    )
    metadata = Dict{String,Any}(
        "data_science_project_job" => Dict{String,Any}(
            "project_id" => project.project_id,
            "job_type" => String(job_type),
            "dataset_id" => dataset_id === nothing ? "" : String(dataset_id),
            "source_record_id" => source_record_id === nothing ? "" : String(source_record_id),
        ),
        "artifact_refs" => normalized_refs(output_refs),
        "worker_id" => worker_id,
        "worker_dispatch" => worker_dispatch,
    )
    isempty(normalized_resource_evidence) || (metadata["resource_evidence"] = normalized_resource_evidence)
    execution = JuliaFlowGatewayRepository.GatewayExecution(
        execution_id = execution_id,
        workflow_id = String(workflow_id),
        workflow_version = project.schema_version,
        checkpoint_tag = String(checkpoint_tag),
        status = "completed",
        mode = "local_project_job",
        plan = execution_plan,
        stages = [execution_plan],
        node_count = length(execution_plan),
        connection_count = max(0, length(execution_plan) - 1),
        created_at = started,
        updated_at = finished,
        status_history = [
            Dict{String,Any}("status" => "queued", "at" => started, "message" => "Project job queued"),
            Dict{String,Any}("status" => "running", "at" => started, "message" => "Project job started"),
            Dict{String,Any}("status" => "completed", "at" => finished, "message" => "Project job completed"),
        ],
        queued_at = started,
        started_at = started,
        finished_at = finished,
        metadata = metadata,
    )
    return execution, worker_id
end

function project_job_execution_evidence(execution::JuliaFlowGatewayRepository.GatewayExecution, worker_id::AbstractString)
    started = execution.started_at === nothing ? execution.created_at : String(execution.started_at)
    finished = execution.finished_at === nothing ? execution.updated_at : String(execution.finished_at)
    evidence = Dict{String,Any}(
        "executionId" => execution.execution_id,
        "workflowId" => execution.workflow_id,
        "status" => execution.status,
        "mode" => execution.mode,
        "workerId" => String(worker_id),
        "queuedAt" => execution.queued_at === nothing ? started : String(execution.queued_at),
        "startedAt" => started,
        "finishedAt" => finished,
    )
    dispatch = get(execution.metadata, "worker_dispatch", nothing)
    if dispatch isa AbstractDict
        normalized_dispatch = normalized_dict(dispatch)
        for key in ("orchestrationMode", "dispatchStatus", "workerPool", "dispatchLane")
            haskey(normalized_dispatch, key) && (evidence[key] = String(normalized_dispatch[key]))
        end
    end
    return evidence
end

end
