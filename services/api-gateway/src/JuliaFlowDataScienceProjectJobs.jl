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

function require_cpu_project_job_allowed(compute_settings::AbstractDict)
    String(get(compute_settings, "gpuPreference", "cpu_fallback")) == "cuda_required" &&
        error("cuda_required cannot run a CPU-only project job")
    return nothing
end

function project_job_resource_evidence(
    compute_settings::AbstractDict,
    gpu_registry::AbstractDict;
    execution_mode::AbstractString = "local_project_route",
    cpu_thread_count::Integer = Threads.nthreads(),
)
    requested_backend = String(compute_settings["selectedBackend"])
    devices = get(gpu_registry, "devices", Any[])
    hardware_count = count(device -> String(get(device, "mode", "")) == "hardware", devices)
    simulated_count = count(device -> String(get(device, "mode", "")) == "simulated", devices)
    require_cpu_project_job_allowed(compute_settings)
    # These project routes execute on the CPU. A visible device or a registry
    # entry is not evidence that fitting, profiling, or evaluation used CUDA.
    selected_backend = "cpu"
    dispatch_lane = "cpu"
    fallback_reason = requested_backend == "cpu" ? "cpu_selected" : "gpu_operation_not_implemented"
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
        "gpuReadinessStatus" => String(get(gpu_registry, "probe_status", "unprobed")),
        "gpuHardwareDeviceCount" => hardware_count,
        "gpuSimulatedDeviceCount" => simulated_count,
        "gpuFallbackReason" => fallback_reason,
        "evidenceVersion" => 2,
        "gpuProbeStatus" => String(get(gpu_registry, "probe_status", "unprobed")),
        "actualDeviceId" => "cpu",
        "actualExecutionBackend" => "cpu",
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
    if resource_evidence !== nothing || execution_evidence !== nothing || status in ("running", "completed")
        JuliaFlowGatewayRepository.JuliaFlowProjectPayloadValidation.validate_executed_resource_evidence!(resource_evidence)
    end
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    job = Dict{String,Any}(
        "jobId" => "job-" * replace(string(uuid4()), "-" => ""),
        "projectId" => project.project_id,
        "jobType" => String(job_type),
        "status" => String(status),
        "outputRefs" => normalized_refs(output_refs),
        "startedAt" => started_at === nothing ? timestamp : String(started_at),
    )
    resource_evidence === nothing || (job["resourceEvidence"] = normalized_dict(resource_evidence))
    dataset_id === nothing || (job["datasetId"] = String(dataset_id))
    split_plan_id === nothing || (job["splitPlanId"] = String(split_plan_id))
    source_record_id === nothing || (job["sourceRecordId"] = String(source_record_id))
    execution_evidence === nothing || (job["executionEvidence"] = normalized_dict(execution_evidence))
    finished_at === nothing || (job["finishedAt"] = String(finished_at))
    error_message === nothing || (job["errorMessage"] = String(error_message))
    JuliaFlowGatewayRepository.JuliaFlowProjectPayloadValidation.validate_project_children!(Dict("projectId" => project.project_id, "projectJobs" => [job]))
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
    worker_backed::Bool = false,
)
    JuliaFlowGatewayRepository.JuliaFlowProjectPayloadValidation.validate_executed_resource_evidence!(resource_evidence)
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    started = started_at === nothing ? timestamp : String(started_at)
    finished = finished_at === nothing ? started : String(finished_at)
    initial_status = worker_backed ? "accepted" : "completed"
    worker_started_at = worker_backed ? nothing : started
    worker_finished_at = worker_backed ? nothing : finished
    execution_plan = isempty(plan) ? ["validate_project_state", "materialize_project_artifact"] : [String(item) for item in plan]
    execution_id = "dsjob-" * replace(string(uuid4()), "-" => "")
    worker_id = "project-job-worker-" * execution_id[(lastindex(execution_id) - 7):lastindex(execution_id)]
    normalized_resource_evidence = resource_evidence === nothing ? Dict{String,Any}() : normalized_dict(resource_evidence)
    worker_dispatch = Dict{String,Any}(
        "orchestrationMode" => worker_backed ? "worker_service_tick" : "gateway_worker_dispatch",
        "dispatchStatus" => worker_backed ? "accepted" : "completed",
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
        status = initial_status,
        mode = "local_project_job",
        plan = execution_plan,
        stages = [execution_plan],
        node_count = length(execution_plan),
        connection_count = max(0, length(execution_plan) - 1),
        created_at = started,
        updated_at = worker_backed ? started : finished,
        status_history = worker_backed ?
            [Dict{String,Any}("status" => "accepted", "at" => started, "message" => "Project job accepted")] :
            [
                Dict{String,Any}("status" => "queued", "at" => started, "message" => "Project job queued"),
                Dict{String,Any}("status" => "running", "at" => started, "message" => "Project job started"),
                Dict{String,Any}("status" => "completed", "at" => finished, "message" => "Project job completed"),
            ],
        queued_at = worker_backed ? nothing : started,
        started_at = worker_started_at,
        finished_at = worker_finished_at,
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
