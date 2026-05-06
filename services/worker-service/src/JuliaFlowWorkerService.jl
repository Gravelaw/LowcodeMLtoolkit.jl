module JuliaFlowWorkerService

export WorkerServiceState,
    sync_worker_service!,
    should_dispatch_gpu_execution,
    queue_gpu_execution!,
    promote_gpu_execution!,
    process_gpu_worker_tick!,
    process_gpu_compute_tick!,
    queue_stream_execution!,
    promote_stream_execution!,
    process_stream_worker_tick!,
    process_stream_fixture_batch!,
    replay_stream_fixture_batch!,
    activate_stream_execution!,
    set_stream_lifecycle!,
    stop_stream_execution!,
    activate_gpu_execution!

Base.@kwdef mutable struct WorkerServiceState
    stream_execution_ids::Dict{String,String} = Dict{String,String}()
    gpu_execution_ids::Set{String} = Set{String}()
end

function stream_lifecycle_status(execution)
    return get(execution.metadata, "stream_lifecycle_status", nothing)
end


function stream_source_kind(workflow)
    workflow.runtime.source === nothing && return "none"
    return String(get(workflow.runtime.source, "kind", "unknown"))
end

function stream_fixture_events(workflow)
    workflow.runtime.source === nothing && return Any[]
    stream_source_kind(workflow) == "fixture" || return Any[]
    return collect(get(workflow.runtime.source, "events", Any[]))
end

function stream_window_size(workflow)
    workflow.runtime.window === nothing && return 1
    return max(Int(get(workflow.runtime.window, "size_seconds", 1)), 1)
end

function stream_policy_max_batches(workflow)
    workflow.runtime.policy === nothing && return 1
    return max(Int(get(workflow.runtime.policy, "max_in_flight_batches", 1)), 1)
end

function stream_policy_allowed_lateness(workflow)
    workflow.runtime.policy === nothing && return 0
    return max(Int(get(workflow.runtime.policy, "allowed_lateness_seconds", 0)), 0)
end

function stream_adapter_contract(workflow)
    kind = lowercase(stream_source_kind(workflow))
    source = workflow.runtime.source === nothing ? Dict{String,Any}() : workflow.runtime.source
    contract = Dict{String,Any}(
        "kind" => kind,
        "deliverySemantics" => "source_at_least_once_sink_exactly_once_fenced",
        "replayMode" => "committed_offset",
        "watermarkMode" => workflow.runtime.policy === nothing ? "processing_time" : String(get(workflow.runtime.policy, "watermark_mode", "processing_time")),
    )
    if kind == "kafka"
        contract["topic"] = String(get(source, "topic", "unknown"))
        contract["consumerGroup"] = String(get(source, "consumer_group", "unknown"))
        contract["bootstrapServers"] = [String(item) for item in get(source, "bootstrap_servers", Any[])]
        contract["offsetField"] = "offset"
        contract["partitionField"] = "partition"
    elseif kind == "nats"
        contract["subject"] = String(get(source, "subject", get(source, "topic", "unknown")))
        contract["durableConsumer"] = String(get(source, "durable_consumer", get(source, "consumer_group", "unknown")))
        contract["servers"] = [String(item) for item in get(source, "servers", Any[])]
        contract["sequenceField"] = "stream_sequence"
    elseif kind == "fixture"
        contract["eventCount"] = length(stream_fixture_events(workflow))
        contract["offsetField"] = "offset"
    end
    return contract
end

function event_time_seconds(event, fallback::Integer)
    event isa AbstractDict || return Int(fallback)
    if haskey(event, "event_time_seconds")
        return Int(event["event_time_seconds"])
    elseif haskey(event, "timestamp_seconds")
        return Int(event["timestamp_seconds"])
    elseif haskey(event, "offset")
        return Int(event["offset"])
    end
    return Int(fallback)
end

function fixture_window_summary(events, offset_start::Integer, workflow)
    isempty(events) && return Dict{String,Any}("kind" => "none", "size_seconds" => stream_window_size(workflow), "windows" => Dict{String,Any}[])
    size_seconds = stream_window_size(workflow)
    windows = Dict{Int,Int}()
    for (index, event) in enumerate(events)
        event_time = event_time_seconds(event, offset_start + index)
        window_start = div(event_time, size_seconds) * size_seconds
        windows[window_start] = get(windows, window_start, 0) + 1
    end
    return Dict{String,Any}(
        "kind" => String(get(workflow.runtime.window, "kind", "tumbling")),
        "size_seconds" => size_seconds,
        "windows" => [Dict("start" => key, "end" => key + size_seconds, "count" => windows[key]) for key in sort(collect(keys(windows)))],
    )
end

function stream_runtime_metadata(workflow, execution, events, offset_start::Integer)
    total_events = length(stream_fixture_events(workflow))
    processed_offset = offset_start + length(events)
    previous_rows = Int(get(execution.metadata, "stream_processed_rows", 0))
    previous_batches = Int(get(execution.metadata, "stream_batch_count", 0))
    lag = max(total_events - processed_offset, 0)
    max_batches = stream_policy_max_batches(workflow)
    watermark = isempty(events) ? Int(get(execution.metadata, "stream_watermark", 0)) : maximum(event_time_seconds(event, offset_start + index) for (index, event) in enumerate(events)) - stream_policy_allowed_lateness(workflow)
    batch_count = isempty(events) ? previous_batches : previous_batches + 1
    topic = workflow.runtime.source === nothing ? "unknown" : String(get(workflow.runtime.source, "topic", "fixture"))
    consumer_group = workflow.runtime.source === nothing ? "unknown" : String(get(workflow.runtime.source, "consumer_group", "fixture"))
    transaction_id = "stream-$(execution.execution_id)-offset-$(offset_start)-$(processed_offset)"
    return Dict{String,Any}(
        "stream_adapter" => stream_source_kind(workflow),
        "stream_processed_offset" => processed_offset,
        "stream_committed_offset" => processed_offset,
        "stream_processed_rows" => previous_rows + length(events),
        "stream_batch_count" => batch_count,
        "stream_consumer_lag" => lag,
        "stream_backpressure" => lag > max_batches ? "lagging" : "ok",
        "stream_watermark" => watermark,
        "stream_window_state" => fixture_window_summary(events, offset_start, workflow),
        "stream_last_checkpoint_id" => "stream-$(execution.execution_id)-batch-$(batch_count)",
        "stream_checkpoint_offsets" => Dict(
            "topic" => topic,
            "consumerGroup" => consumer_group,
            "lastOffset" => processed_offset,
            "committedOffset" => processed_offset,
            "lag" => lag,
            "transactionId" => transaction_id,
        ),
        "stream_sink_transaction_id" => transaction_id,
        "stream_idempotency_key" => "$(topic):$(consumer_group):$(processed_offset)",
        "stream_exactly_once_status" => isempty(events) ? "idle" : "committed",
    )
end

function gpu_registry()
    raw = strip(get(ENV, "JULIAFLOW_GPU_REGISTRY", "mock:nvidia0"))
    isempty(raw) && return Dict{String,Any}[]
    devices = Dict{String,Any}[]
    for (index, token) in enumerate(split(raw, ','))
        spec = strip(token)
        isempty(spec) && continue
        parts = split(spec, ':')
        accelerator = length(parts) >= 1 ? String(parts[1]) : "mock"
        device_id = length(parts) >= 2 ? String(parts[2]) : "device$(index - 1)"
        vendor = startswith(lowercase(accelerator), "cuda") || startswith(lowercase(accelerator), "nvidia") || lowercase(accelerator) == "mock" ? "nvidia" : accelerator
        push!(devices, Dict(
            "accelerator" => accelerator == "mock" ? "cuda" : accelerator,
            "device_id" => device_id,
            "vendor" => vendor,
            "mode" => accelerator == "mock" ? "simulated" : "hardware",
            "memory_gb" => 16,
        ))
    end
    return devices
end

function gpu_registry_health()
    devices = gpu_registry()
    return Dict(
        "device_count" => length(devices),
        "devices" => devices,
        "fallback_available" => true,
    )
end

function gpu_workflow_node(workflow)
    for node in workflow.nodes
        if node.capabilities !== nothing
            node.capabilities.resource_class == :gpu || continue
            return node
        end
        (node.execution_hint == :gpu_required || node.execution_hint == :gpu_preferred) || continue
        return node
    end
    return nothing
end

function gpu_requested_device(workflow, execution)
    if haskey(execution.metadata, "flow_variables")
        values = execution.metadata["flow_variables"]
        values isa AbstractDict && haskey(values, "JULIAFLOW_GPU_DEVICE") && return String(values["JULIAFLOW_GPU_DEVICE"])
    end
    node = gpu_workflow_node(workflow)
    node === nothing && return nothing
    haskey(node.config, "gpuDevicePreference") && return String(node.config["gpuDevicePreference"])
    return nothing
end

function select_gpu_device(workflow, execution)
    devices = gpu_registry()
    requested = gpu_requested_device(workflow, execution)
    if requested !== nothing
        for device in devices
            if String(device["device_id"]) == requested
                return device
            end
        end
    end
    isempty(devices) && return nothing
    return devices[1]
end

function gpu_workload_config(workflow)
    node = gpu_workflow_node(workflow)
    node === nothing && return Dict{String,Any}("kind" => "mock_vector_sum", "input_values" => [1.0, 2.0, 3.0, 4.0])
    kind = haskey(node.config, "gpuWorkload") ? String(node.config["gpuWorkload"]) : "mock_vector_sum"
    values = haskey(node.config, "mockInputValues") ? [Float64(value) for value in node.config["mockInputValues"]] : [1.0, 2.0, 3.0, 4.0]
    return Dict{String,Any}("kind" => kind, "input_values" => values, "node_id" => node.id)
end

function execute_gpu_workload(workflow, execution)
    config = gpu_workload_config(workflow)
    values = [Float64(value) for value in get(config, "input_values", [1.0, 2.0, 3.0, 4.0])]
    kind = String(get(config, "kind", "mock_vector_sum"))
    if kind == "mock_vector_sum"
        return Dict(
            "kind" => kind,
            "input_size" => length(values),
            "sum" => sum(values),
            "mean" => isempty(values) ? 0.0 : sum(values) / length(values),
            "l2_norm" => sqrt(sum(value * value for value in values)),
        )
    elseif kind == "mock_matrix_energy"
        return Dict(
            "kind" => kind,
            "input_size" => length(values),
            "energy" => sum(value * value for value in values),
            "max" => isempty(values) ? 0.0 : maximum(values),
        )
    end
    error("unsupported gpu workload: $(kind)")
end

function gpu_runtime_metadata(workflow, execution)
    registry = gpu_registry_health()
    device = select_gpu_device(workflow, execution)
    result = execute_gpu_workload(workflow, execution)
    path = device === nothing ? "cpu_fallback" : "gpu"
    metadata = Dict{String,Any}(
        "gpu_registry" => registry,
        "gpu_execution_path" => path,
        "gpu_workload" => String(result["kind"]),
        "gpu_workload_result" => result,
        "gpu_fallback_used" => device === nothing,
    )
    if device === nothing
        metadata["gpu_device_id"] = "cpu-fallback"
        metadata["gpu_accelerator"] = "cpu"
    else
        metadata["gpu_device_id"] = String(device["device_id"])
        metadata["gpu_accelerator"] = String(device["accelerator"])
        metadata["gpu_vendor"] = String(device["vendor"])
    end
    return metadata
end

function has_gpu_dispatch(execution)
    get(execution.metadata, "dispatch_lane", nothing) == "gpu" && return true
    dispatch_plan = get(execution.metadata, "dispatch_plan", Any[])
    for entry in dispatch_plan
        String(get(entry, "lane", "")) == "gpu" && return true
    end
    return false
end

function gpu_dispatch_plan(execution)
    dispatch_plan = get(execution.metadata, "dispatch_plan", Any[])
    for entry in dispatch_plan
        String(get(entry, "lane", "")) == "gpu" || continue
        return Dict{String,Any}(String(key) => value for (key, value) in pairs(entry))
    end
    return nothing
end

function sync_worker_service!(service::WorkerServiceState, executions)
    empty!(service.stream_execution_ids)
    empty!(service.gpu_execution_ids)

    for execution in executions
        lifecycle = stream_lifecycle_status(execution)
        if lifecycle !== nothing && lifecycle != "stopped" && execution.status != "completed" && execution.status != "failed"
            service.stream_execution_ids[execution.workflow_id] = execution.execution_id
        end
        has_gpu_dispatch(execution) && push!(service.gpu_execution_ids, execution.execution_id)
    end

    return service
end

function build_stream_execution_metadata(workflow)
    metadata = Dict{String,Any}(
        "stream_lifecycle_status" => "starting",
        "stream_run_mode" => String(workflow.runtime.run_mode),
        "stream_adapter" => stream_source_kind(workflow),
        "stream_adapter_contract" => stream_adapter_contract(workflow),
        "stream_processed_offset" => 0,
        "stream_committed_offset" => 0,
        "stream_processed_rows" => 0,
        "stream_batch_count" => 0,
        "stream_consumer_lag" => length(stream_fixture_events(workflow)),
        "stream_backpressure" => length(stream_fixture_events(workflow)) > stream_policy_max_batches(workflow) ? "lagging" : "ok",
    )
    if workflow.runtime.source !== nothing
        metadata["stream_topic"] = String(get(workflow.runtime.source, "topic", "unknown"))
        metadata["stream_consumer_group"] = String(get(workflow.runtime.source, "consumer_group", "unknown"))
        metadata["stream_bootstrap_servers"] = [String(item) for item in get(workflow.runtime.source, "bootstrap_servers", Any[])]
    end
    workflow.runtime.window === nothing || (metadata["stream_window"] = workflow.runtime.window)
    workflow.runtime.policy === nothing || (metadata["stream_policy"] = workflow.runtime.policy)
    return metadata
end

function duplicate_replay_metadata(execution, replay_offset::Integer)
    committed_offset = Int(get(execution.metadata, "stream_committed_offset", get(execution.metadata, "stream_processed_offset", 0)))
    checkpoint_offsets = get(execution.metadata, "stream_checkpoint_offsets", Dict{String,Any}())
    transaction_id = String(get(execution.metadata, "stream_sink_transaction_id", "stream-$(execution.execution_id)-offset-$(committed_offset)-$(committed_offset)"))
    return Dict{String,Any}(
        "stream_replay_status" => "duplicate_skipped",
        "stream_exactly_once_status" => "duplicate_suppressed",
        "stream_replay_offset" => Int(replay_offset),
        "stream_committed_offset" => committed_offset,
        "stream_checkpoint_offsets" => checkpoint_offsets,
        "stream_sink_transaction_id" => transaction_id,
        "stream_idempotency_key" => String(get(execution.metadata, "stream_idempotency_key", transaction_id)),
    )
end

function gpu_dispatch_metadata(execution)
    dispatch = gpu_dispatch_plan(execution)
    dispatch === nothing && return Dict{String,Any}()

    metadata = Dict{String,Any}(
        "dispatch_lane" => "gpu",
        "dispatch_worker_pool" => String(get(dispatch, "worker_pool", "alpha-gpu")),
        "dispatch_isolation_mode" => String(get(dispatch, "isolation_mode", "isolated")),
        "worker_id" => "gpu-worker-" * execution.execution_id[1:8],
    )
    haskey(dispatch, "accelerator") && (metadata["dispatch_accelerator"] = String(dispatch["accelerator"]))
    return metadata
end

function should_dispatch_gpu_execution(workflow, execution)
    workflow.runtime.run_mode == :stream && return false
    return gpu_dispatch_plan(execution) !== nothing
end

function find_execution_index(executions, execution_id::AbstractString)
    for (index, execution) in pairs(executions)
        execution.execution_id == execution_id && return index
    end
    error("execution not found: $(execution_id)")
end

function find_stream_execution_index(service::WorkerServiceState, executions, workflow_id::AbstractString)
    if haskey(service.stream_execution_ids, workflow_id)
        return find_execution_index(executions, service.stream_execution_ids[workflow_id])
    end

    for (index, execution) in Iterators.reverse(collect(pairs(executions)))
        execution.workflow_id == workflow_id || continue
        lifecycle = stream_lifecycle_status(execution)
        lifecycle === nothing && continue
        lifecycle == "stopped" && continue
        execution.status == "completed" && continue
        execution.status == "failed" && continue
        service.stream_execution_ids[workflow_id] = execution.execution_id
        return index
    end

    error("stream execution not found for workflow: $(workflow_id)")
end

function activate_stream_execution!(
    service::WorkerServiceState,
    workflows,
    executions,
    execution_id::AbstractString;
    execution_record,
    transition_execution_record,
    materialize_execution,
)
    index = find_execution_index(executions, execution_id)
    current_execution = executions[index]
    workflow = workflows[current_execution.workflow_id]

    queued = transition_execution_record(
        execution_record(current_execution),
        "queued";
        message = "Queued for streaming broker lane",
        metadata = build_stream_execution_metadata(workflow),
    )
    running = transition_execution_record(
        queued,
        "running";
        message = "Streaming broker connected",
        metadata = Dict{String,Any}("stream_lifecycle_status" => "active"),
    )
    updated_execution = materialize_execution(running)
    executions[index] = updated_execution
    service.stream_execution_ids[updated_execution.workflow_id] = updated_execution.execution_id
    return updated_execution
end

function queue_stream_execution!(
    service::WorkerServiceState,
    workflows,
    executions,
    execution_id::AbstractString;
    execution_record,
    transition_execution_record,
    materialize_execution,
)
    index = find_execution_index(executions, execution_id)
    current_execution = executions[index]
    workflow = workflows[current_execution.workflow_id]

    queued = transition_execution_record(
        execution_record(current_execution),
        "queued";
        message = "Queued for streaming broker lane",
        metadata = build_stream_execution_metadata(workflow),
    )
    updated_execution = materialize_execution(queued)
    executions[index] = updated_execution
    service.stream_execution_ids[updated_execution.workflow_id] = updated_execution.execution_id
    return updated_execution
end

function promote_stream_execution!(
    service::WorkerServiceState,
    executions,
    execution_id::AbstractString;
    execution_record,
    transition_execution_record,
    materialize_execution,
)
    index = find_execution_index(executions, execution_id)
    current_execution = executions[index]
    running = transition_execution_record(
        execution_record(current_execution),
        "running";
        message = "Streaming broker connected",
        metadata = Dict{String,Any}("stream_lifecycle_status" => "active"),
    )
    updated_execution = materialize_execution(running)
    executions[index] = updated_execution
    service.stream_execution_ids[updated_execution.workflow_id] = updated_execution.execution_id
    return updated_execution
end

function process_stream_worker_tick!(
    service::WorkerServiceState,
    executions;
    execution_record,
    transition_execution_record,
    materialize_execution,
)
    updated_executions = Any[]
    for execution in executions
        lifecycle = stream_lifecycle_status(execution)
        execution.status == "queued" || continue
        lifecycle == "starting" || continue
        push!(
            updated_executions,
            promote_stream_execution!(
                service,
                executions,
                execution.execution_id;
                execution_record = execution_record,
                transition_execution_record = transition_execution_record,
                materialize_execution = materialize_execution,
            ),
        )
    end
    return updated_executions
end


function process_stream_fixture_batch!(
    service::WorkerServiceState,
    workflows,
    executions,
    workflow_id::AbstractString;
    execution_record,
    append_execution_event,
    materialize_execution,
    batch_size::Union{Nothing,Integer} = nothing,
)
    index = find_stream_execution_index(service, executions, workflow_id)
    current_execution = executions[index]
    lifecycle = stream_lifecycle_status(current_execution)
    lifecycle == "active" || error("stream execution must be active to process fixture batch")
    workflow = workflows[workflow_id]
    events = stream_fixture_events(workflow)
    offset = Int(get(current_execution.metadata, "stream_processed_offset", 0))
    limit = batch_size === nothing ? stream_policy_max_batches(workflow) : max(Int(batch_size), 1)
    offset >= length(events) && return current_execution
    next_offset = min(offset + limit, length(events))
    batch = events[(offset + 1):next_offset]
    metadata = stream_runtime_metadata(workflow, current_execution, batch, offset)
    updated = append_execution_event(
        execution_record(current_execution);
        message = "Streaming fixture batch processed",
        metadata = metadata,
    )
    execution = materialize_execution(updated)
    executions[index] = execution
    service.stream_execution_ids[workflow_id] = execution.execution_id
    return execution
end

function replay_stream_fixture_batch!(
    service::WorkerServiceState,
    workflows,
    executions,
    workflow_id::AbstractString,
    replay_offset::Integer;
    execution_record,
    append_execution_event,
    materialize_execution,
    batch_size::Union{Nothing,Integer} = nothing,
)
    index = find_stream_execution_index(service, executions, workflow_id)
    current_execution = executions[index]
    lifecycle = stream_lifecycle_status(current_execution)
    lifecycle == "active" || error("stream execution must be active to replay fixture batch")
    committed_offset = Int(get(current_execution.metadata, "stream_committed_offset", get(current_execution.metadata, "stream_processed_offset", 0)))
    replay_offset = max(Int(replay_offset), 0)
    if replay_offset < committed_offset
        updated = append_execution_event(
            execution_record(current_execution);
            message = "Streaming replay duplicate skipped",
            metadata = duplicate_replay_metadata(current_execution, replay_offset),
        )
        execution = materialize_execution(updated)
        executions[index] = execution
        service.stream_execution_ids[workflow_id] = execution.execution_id
        return execution
    elseif replay_offset > committed_offset
        error("stream replay offset ahead of committed offset")
    end
    return process_stream_fixture_batch!(
        service,
        workflows,
        executions,
        workflow_id;
        execution_record = execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = materialize_execution,
        batch_size = batch_size,
    )
end

function set_stream_lifecycle!(
    service::WorkerServiceState,
    executions,
    workflow_id::AbstractString;
    lifecycle_status::AbstractString,
    message::AbstractString,
    execution_record,
    append_execution_event,
    materialize_execution,
)
    index = find_stream_execution_index(service, executions, workflow_id)
    current_execution = executions[index]
    updated = append_execution_event(
        execution_record(current_execution);
        message = message,
        metadata = Dict{String,Any}("stream_lifecycle_status" => String(lifecycle_status)),
    )
    execution = materialize_execution(updated)
    executions[index] = execution
    service.stream_execution_ids[workflow_id] = execution.execution_id
    return execution
end

function stop_stream_execution!(
    service::WorkerServiceState,
    executions,
    workflow_id::AbstractString;
    execution_record,
    transition_execution_record,
    materialize_execution,
)
    index = find_stream_execution_index(service, executions, workflow_id)
    current_execution = executions[index]
    updated = transition_execution_record(
        execution_record(current_execution),
        "completed";
        message = "Streaming execution stopped",
        metadata = Dict{String,Any}("stream_lifecycle_status" => "stopped"),
    )
    execution = materialize_execution(updated)
    executions[index] = execution
    delete!(service.stream_execution_ids, workflow_id)
    return execution
end

function activate_gpu_execution!(
    service::WorkerServiceState,
    executions,
    execution_id::AbstractString;
    execution_record,
    transition_execution_record,
    materialize_execution,
)
    index = find_execution_index(executions, execution_id)
    current_execution = executions[index]
    queued = transition_execution_record(
        execution_record(current_execution),
        "queued";
        message = "Queued for isolated GPU worker lane",
        metadata = gpu_dispatch_metadata(current_execution),
    )
    updated_execution = materialize_execution(queued)
    executions[index] = updated_execution
    push!(service.gpu_execution_ids, updated_execution.execution_id)
    return updated_execution
end

function queue_gpu_execution!(
    service::WorkerServiceState,
    executions,
    execution_id::AbstractString;
    execution_record,
    transition_execution_record,
    materialize_execution,
)
    return activate_gpu_execution!(
        service,
        executions,
        execution_id;
        execution_record = execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = materialize_execution,
    )
end

function promote_gpu_execution!(
    service::WorkerServiceState,
    executions,
    execution_id::AbstractString;
    execution_record,
    transition_execution_record,
    materialize_execution,
)
    index = find_execution_index(executions, execution_id)
    current_execution = executions[index]
    running = transition_execution_record(
        execution_record(current_execution),
        "running";
        message = "GPU worker started execution",
    )
    updated_execution = materialize_execution(running)
    executions[index] = updated_execution
    push!(service.gpu_execution_ids, updated_execution.execution_id)
    return updated_execution
end

function process_gpu_worker_tick!(
    service::WorkerServiceState,
    executions;
    execution_record,
    transition_execution_record,
    materialize_execution,
)
    updated_executions = Any[]
    for execution in executions
        execution.status == "queued" || continue
        has_gpu_dispatch(execution) || continue
        push!(
            updated_executions,
            promote_gpu_execution!(
                service,
                executions,
                execution.execution_id;
                execution_record = execution_record,
                transition_execution_record = transition_execution_record,
                materialize_execution = materialize_execution,
            ),
        )
    end
    return updated_executions
end

function process_gpu_compute_tick!(
    service::WorkerServiceState,
    workflows,
    executions;
    execution_record,
    transition_execution_record,
    materialize_execution,
)
    updated_executions = Any[]
    for execution in executions
        execution.status == "running" || continue
        has_gpu_dispatch(execution) || continue
        get(execution.metadata, "gpu_workload_result", nothing) === nothing || continue
        workflow = workflows[execution.workflow_id]
        metadata = gpu_runtime_metadata(workflow, execution)
        completed = transition_execution_record(
            execution_record(execution),
            "completed";
            message = metadata["gpu_execution_path"] == "gpu" ? "GPU worker completed workload" : "GPU worker completed workload via CPU fallback",
            metadata = metadata,
        )
        updated_execution = materialize_execution(completed)
        index = find_execution_index(executions, execution.execution_id)
        executions[index] = updated_execution
        push!(service.gpu_execution_ids, updated_execution.execution_id)
        push!(updated_executions, updated_execution)
    end
    return updated_executions
end

end
