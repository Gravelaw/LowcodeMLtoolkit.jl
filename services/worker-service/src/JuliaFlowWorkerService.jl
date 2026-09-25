module JuliaFlowWorkerService

using JSON3

export WorkerServiceState,
    sync_worker_service!,
    should_dispatch_gpu_execution,
    queue_gpu_execution!,
    promote_gpu_execution!,
    process_gpu_worker_tick!,
    process_gpu_compute_tick!,
    process_control_flow_recovery_tick!,
    process_executor_schedule_tick!,
    process_data_science_project_job_tick!,
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
    control_flow_branch_execution_ids::Set{String} = Set{String}()
    executor_execution_ids::Set{String} = Set{String}()
    data_science_project_job_execution_ids::Set{String} = Set{String}()
end

function stream_lifecycle_status(execution)
    return get(execution.metadata, "stream_lifecycle_status", nothing)
end

function control_flow_recovery(execution)
    recovery = get(execution.metadata, "control_flow_recovery", nothing)
    recovery isa AbstractDict || return nothing
    return recovery
end

function has_completed_control_flow_branch(execution)
    branch_state = get(execution.metadata, "control_flow_branch_state", nothing)
    branch_state isa AbstractDict || return false
    return String(get(branch_state, "status", "")) == "completed"
end

function executor_schedule(execution)
    schedule = get(execution.metadata, "executor_schedule", Any[])
    schedule isa AbstractVector || return Any[]
    return schedule
end

function executor_state(execution)
    state = get(execution.metadata, "executor_state", nothing)
    state isa AbstractDict || return Dict{String,Any}()
    return Dict{String,Any}(String(key) => value for (key, value) in pairs(state))
end

function data_science_project_job(execution)
    job = get(execution.metadata, "data_science_project_job", nothing)
    job isa AbstractDict || return nothing
    return Dict{String,Any}(String(key) => value for (key, value) in pairs(job))
end

function data_science_project_worker_dispatch(execution)
    dispatch = get(execution.metadata, "worker_dispatch", nothing)
    dispatch isa AbstractDict || return Dict{String,Any}()
    return Dict{String,Any}(String(key) => value for (key, value) in pairs(dispatch))
end

function has_data_science_project_job(execution)
    return data_science_project_job(execution) !== nothing
end

function should_process_data_science_project_job(execution)
    has_data_science_project_job(execution) || return false
    String(execution.mode) == "local_project_job" || return false
    execution.status in ("accepted", "queued", "running") || return false
    return true
end

function data_science_project_job_worker_metadata(execution, dispatch_status::AbstractString)
    dispatch = data_science_project_worker_dispatch(execution)
    worker = String(get(dispatch, "workerId", get(execution.metadata, "worker_id", worker_id("project-job-worker", execution.execution_id))))
    dispatch["orchestrationMode"] = "worker_service_tick"
    dispatch["dispatchStatus"] = String(dispatch_status)
    dispatch["workerId"] = worker
    haskey(dispatch, "workerPool") || (dispatch["workerPool"] = "local-cpu")
    haskey(dispatch, "dispatchLane") || (dispatch["dispatchLane"] = "cpu")
    job = data_science_project_job(execution)
    return Dict{String,Any}(
        "worker_id" => worker,
        "worker_dispatch" => dispatch,
        "data_science_project_worker_state" => Dict{String,Any}(
            "status" => String(dispatch_status),
            "project_id" => String(get(job, "project_id", "")),
            "job_type" => String(get(job, "job_type", "")),
            "source_record_id" => String(get(job, "source_record_id", "")),
            "worker_id" => worker,
        ),
    )
end

function has_executor_schedule(execution)
    return !isempty(executor_schedule(execution))
end

function executor_worker_id(execution)
    return worker_id("executor-worker", execution.execution_id)
end

function executor_stage_node_ids(stage)
    return [String(node_id) for node_id in get(stage, "node_ids", Any[])]
end

function unique_executor_strings(values)
    seen = Set{String}()
    result = String[]
    for value in values
        item = String(value)
        item in seen && continue
        push!(seen, item)
        push!(result, item)
    end
    return result
end

function executor_schedule_dataflow_policy(schedule)
    policies = Dict{String,Any}[]
    for stage in schedule
        policy = get(stage, "dataflow_policy", nothing)
        policy isa AbstractDict || continue
        push!(policies, Dict{String,Any}(String(key) => value for (key, value) in pairs(policy)))
    end
    isempty(policies) && return nothing

    eligible_node_ids = String[]
    source_node_ids = String[]
    sink_node_ids = String[]
    lanes = String[]
    worker_pools = String[]
    for policy in policies
        append!(eligible_node_ids, [String(node_id) for node_id in get(policy, "eligible_node_ids", Any[])])
        append!(source_node_ids, [String(node_id) for node_id in get(policy, "source_node_ids", Any[])])
        append!(sink_node_ids, [String(node_id) for node_id in get(policy, "sink_node_ids", Any[])])
        append!(lanes, [String(lane) for lane in get(policy, "lanes", Any[])])
        append!(worker_pools, [String(pool) for pool in get(policy, "worker_pools", Any[])])
    end

    return Dict{String,Any}(
        "policy_name" => String(get(policies[1], "policy_name", "callback_dataflow_stage_barrier")),
        "callback_enabled" => all(Bool(get(policy, "callback_enabled", false)) for policy in policies),
        "dataflow_enabled" => all(Bool(get(policy, "dataflow_enabled", false)) for policy in policies),
        "stage_barrier" => String(get(policies[1], "stage_barrier", "ready_after_previous_stage")),
        "eligible_node_ids" => unique_executor_strings(eligible_node_ids),
        "source_node_ids" => unique_executor_strings(source_node_ids),
        "sink_node_ids" => unique_executor_strings(sink_node_ids),
        "lanes" => unique_executor_strings(lanes),
        "worker_pools" => unique_executor_strings(worker_pools),
        "max_concurrency" => maximum(Int(get(policy, "max_concurrency", 1)) for policy in policies),
        "bounded" => all(Bool(get(policy, "bounded", false)) for policy in policies),
    )
end

function executor_default_node_result(workflow, execution, node_id::AbstractString)
    node_type = workflow_node_type(workflow, node_id)
    row_count = bi_outlet_row_count(workflow, node_id)
    output_kind = row_count > 0 || occursin("DataOutlet", node_type) ? "bi_outlet" : "node"
    result = Dict{String,Any}(
        "node_id" => String(node_id),
        "node_type" => node_type,
        "status" => "executed",
        "output_kind" => output_kind,
        "row_count" => row_count,
    )
    row_count > 0 || (result["output_refs"] = ["memory://executor/$(execution.execution_id)/$(node_id)"])
    return result
end

function normalize_executor_node_result(raw_result, workflow, execution, node_id::AbstractString)
    result = raw_result isa AbstractDict ? Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_result)) :
        executor_default_node_result(workflow, execution, node_id)
    haskey(result, "node_id") || (result["node_id"] = String(get(result, "nodeId", node_id)))
    haskey(result, "node_type") || (result["node_type"] = String(get(result, "nodeType", workflow_node_type(workflow, node_id))))
    haskey(result, "status") || (result["status"] = "executed")
    haskey(result, "output_kind") || (result["output_kind"] = String(get(result, "outputKind", "node")))
    haskey(result, "row_count") || (result["row_count"] = Int(get(result, "rowCount", 0)))
    haskey(result, "output_refs") || (result["output_refs"] = [String(ref) for ref in get(result, "outputRefs", String[])])
    if !haskey(result, "error_message") && haskey(result, "errorMessage")
        result["error_message"] = String(result["errorMessage"])
    end
    result["node_id"] = String(result["node_id"])
    result["node_type"] = String(result["node_type"])
    result["status"] = String(result["status"])
    result["output_kind"] = String(result["output_kind"])
    result["row_count"] = Int(result["row_count"])
    result["output_refs"] = [String(ref) for ref in result["output_refs"]]
    if haskey(result, "error_message")
        result["error_message"] = String(result["error_message"])
    end
    return result
end

function executor_error_node_result(workflow, node_id::AbstractString, error)
    return Dict{String,Any}(
        "node_id" => String(node_id),
        "node_type" => workflow_node_type(workflow, node_id),
        "status" => "error",
        "output_kind" => "error",
        "row_count" => 0,
        "output_refs" => String[],
        "error_message" => sprint(showerror, error),
    )
end

function execute_executor_stage_nodes(workflow, execution, node_ids::Vector{String}, execute_stage_node)
    results = Dict{String,Any}[]
    for node_id in node_ids
        result = try
            raw_result = execute_stage_node === nothing ?
                executor_default_node_result(workflow, execution, node_id) :
                execute_stage_node(workflow, execution, node_id)
            normalize_executor_node_result(raw_result, workflow, execution, node_id)
        catch error
            executor_error_node_result(workflow, node_id, error)
        end
        push!(results, result)
        String(result["status"]) in ("error", "failed") && return results, result
    end
    return results, nothing
end

function executor_stage_result(stage; status::AbstractString = "completed", node_results = nothing)
    result = Dict{String,Any}(
        "stage_index" => Int(get(stage, "stage_index", 0)),
        "node_ids" => executor_stage_node_ids(stage),
        "status" => String(status),
    )
    node_results === nothing || (result["node_results"] = node_results)
    return result
end

function executor_completed_node_ids(schedule, completed_stage_count::Int)
    completed = String[]
    bounded_count = min(max(completed_stage_count, 0), length(schedule))
    for index in 1:bounded_count
        append!(completed, executor_stage_node_ids(schedule[index]))
    end
    return completed
end

function executor_stage_results(schedule, completed_stage_count::Int)
    bounded_count = min(max(completed_stage_count, 0), length(schedule))
    return [executor_stage_result(schedule[index]) for index in 1:bounded_count]
end

function executor_existing_stage_results(state)
    raw_results = get(state, "stage_results", Any[])
    raw_results isa AbstractVector || return Dict{String,Any}[]
    return [Dict{String,Any}(String(key) => value for (key, value) in pairs(result)) for result in raw_results]
end

function executor_existing_node_results(state)
    raw_results = get(state, "node_results", Any[])
    raw_results isa AbstractVector || return Dict{String,Any}[]
    return [Dict{String,Any}(String(key) => value for (key, value) in pairs(result)) for result in raw_results]
end

function executor_merge_stage_results(schedule, state, stage_result, completed_stage_count::Int)
    existing = Dict(Int(get(result, "stage_index", 0)) => result for result in executor_existing_stage_results(state))
    existing[Int(stage_result["stage_index"])] = stage_result
    bounded_count = min(max(completed_stage_count, 0), length(schedule))
    return [get(existing, index, executor_stage_result(schedule[index])) for index in 1:bounded_count]
end

function executor_state_metadata(
    execution,
    schedule;
    status::AbstractString,
    current_stage_index::Int,
    completed_stage_count::Int,
    stage_results = nothing,
    node_results = nothing,
    failed_node_id::Union{Nothing,AbstractString} = nothing,
    error_message::Union{Nothing,AbstractString} = nothing,
)
    stage_count = length(schedule)
    active_node_ids = status == "running" && 1 <= current_stage_index <= stage_count ?
        executor_stage_node_ids(schedule[current_stage_index]) : String[]
    completed_stage_indexes = collect(1:min(max(completed_stage_count, 0), stage_count))
    state = Dict{String,Any}(
        "status" => String(status),
        "current_stage_index" => Int(current_stage_index),
        "stage_count" => stage_count,
        "active_node_ids" => active_node_ids,
        "completed_node_ids" => executor_completed_node_ids(schedule, completed_stage_count),
        "completed_stage_indexes" => completed_stage_indexes,
        "worker_id" => executor_worker_id(execution),
        "bounded" => true,
        "stage_results" => stage_results === nothing ? executor_stage_results(schedule, completed_stage_count) : stage_results,
    )
    dataflow_policy = executor_schedule_dataflow_policy(schedule)
    dataflow_policy === nothing || (state["dataflow_policy"] = dataflow_policy)
    node_results === nothing || (state["node_results"] = node_results)
    failed_node_id === nothing || (state["failed_node_id"] = String(failed_node_id))
    error_message === nothing || (state["error_message"] = String(error_message))
    return Dict{String,Any}("executor_state" => state)
end

function should_process_executor_schedule(execution)
    has_executor_schedule(execution) || return false
    execution.status in ("accepted", "queued", "running") || return false
    execution.status == "running" && isempty(executor_state(execution)) && return false
    String(execution.mode) == "batch_cpu" || return false
    stream_lifecycle_status(execution) === nothing || return false
    get(execution.metadata, "dispatch_lane", nothing) === nothing || return false
    return true
end

function worker_id(prefix::AbstractString, execution_id::AbstractString)
    last_index = min(lastindex(execution_id), 8)
    return String(prefix) * "-" * execution_id[1:last_index]
end

function workflow_node_type(workflow, node_id::AbstractString)
    requested = String(node_id)
    for node in workflow.nodes
        node.id == requested && return node.type
    end
    return "unknown"
end

function bi_outlet_row_count(workflow, node_id::AbstractString)
    requested = String(node_id)
    for raw_outlet in workflow.bi_outlets
        raw_outlet isa AbstractDict || continue
        outlet = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_outlet))
        current_id = haskey(outlet, "node_id") ? String(outlet["node_id"]) : String(get(outlet, "nodeId", ""))
        current_id == requested || continue
        rows = get(outlet, "rows", Any[])
        return rows isa AbstractVector ? length(rows) : 0
    end
    return 0
end

function catch_node_result(workflow, node_id::AbstractString)
    node_type = workflow_node_type(workflow, node_id)
    row_count = bi_outlet_row_count(workflow, node_id)
    output_kind = row_count > 0 || occursin("DataOutlet", node_type) ? "bi_outlet" : "node"
    return Dict{String,Any}(
        "node_id" => String(node_id),
        "node_type" => node_type,
        "status" => "executed",
        "output_kind" => output_kind,
        "row_count" => row_count,
    )
end

function workflow_node_order(workflow)
    order = Dict{String,Int}()
    for (index, node) in pairs(workflow.nodes)
        order[node.id] = Int(index)
    end
    return order
end

function catch_branch_stages(workflow, catch_node_ids::Vector{String})
    order = workflow_node_order(workflow)
    catch_nodes = Set(catch_node_ids)
    in_degree = Dict(node_id => 0 for node_id in catch_node_ids)
    adjacency = Dict(node_id => String[] for node_id in catch_node_ids)
    for connection in workflow.connections
        source = connection.source_node_id
        target = connection.target_node_id
        source in catch_nodes && target in catch_nodes || continue
        push!(adjacency[source], target)
        in_degree[target] += 1
    end

    ready = [node_id for node_id in catch_node_ids if in_degree[node_id] == 0]
    stages = Vector{Vector{String}}()
    scheduled = 0
    max_stages = max(length(catch_node_ids), 1)
    while !isempty(ready) && length(stages) < max_stages
        sort!(ready, by = node_id -> get(order, node_id, typemax(Int)))
        stage = unique(copy(ready))
        push!(stages, stage)
        scheduled += length(stage)
        next_ready = String[]
        for current in stage
            for target in adjacency[current]
                in_degree[target] -= 1
                in_degree[target] == 0 && push!(next_ready, target)
            end
        end
        ready = next_ready
    end
    scheduled == length(catch_node_ids) || error("catch branch contains cycle or unresolved dependency")
    return stages
end

function catch_branch_stage_results(workflow, branch_stages::Vector{Vector{String}})
    return [
        Dict{String,Any}(
            "stage_index" => index,
            "node_ids" => copy(stage),
            "node_results" => [catch_node_result(workflow, node_id) for node_id in stage],
        ) for (index, stage) in pairs(branch_stages)
    ]
end

function control_flow_branch_metadata(workflow, execution, recovery)
    catch_node_ids = [String(node_id) for node_id in get(recovery, "catch_node_ids", Any[])]
    branch_stages = catch_branch_stages(workflow, catch_node_ids)
    completed_node_ids = reduce(vcat, branch_stages; init = String[])
    stage_results = catch_branch_stage_results(workflow, branch_stages)
    node_results = reduce(vcat, [stage["node_results"] for stage in stage_results]; init = Dict{String,Any}[])
    return Dict{String,Any}(
        "control_id" => String(get(recovery, "control_id", "")),
        "failed_node_id" => String(get(recovery, "failed_node_id", "")),
        "branch" => "catch",
        "catch_node_ids" => catch_node_ids,
        "branch_stages" => branch_stages,
        "branch_stage_index" => length(branch_stages),
        "branch_stage_count" => length(branch_stages),
        "active_node_ids" => String[],
        "completed_node_ids" => completed_node_ids,
        "status" => "completed",
        "bounded" => Bool(get(recovery, "bounded", true)),
        "worker_id" => worker_id("control-flow-worker", execution.execution_id),
        "stage_results" => stage_results,
        "node_results" => node_results,
    )
end


function stream_source_kind(workflow)
    workflow.runtime.source === nothing && return "none"
    return String(get(workflow.runtime.source, "kind", "unknown"))
end

function load_jsonl_events(path::AbstractString)
    isfile(path) || error("stream events JSONL file not found: $(path)")
    events = Any[]
    for line in eachline(path)
        value = strip(String(line))
        isempty(value) && continue
        push!(events, JSON3.read(value, Dict{String,Any}))
    end
    return events
end

function stream_kafka_events(workflow)
    source = workflow.runtime.source === nothing ? Dict{String,Any}() : workflow.runtime.source
    events_path = strip(get(ENV, "JULIAFLOW_KAFKA_EVENTS_JSONL", ""))
    isempty(events_path) && return Any[]
    topic = String(get(source, "topic", ""))
    events = Any[]
    for event in load_jsonl_events(events_path)
        event_topic = String(get(event, "topic", topic))
        event_topic == topic || continue
        push!(events, event)
    end
    sort!(events, by = event -> Int(get(event, "offset", length(events))))
    return events
end

function stream_fixture_events(workflow)
    workflow.runtime.source === nothing && return Any[]
    kind = stream_source_kind(workflow)
    kind == "kafka" && return stream_kafka_events(workflow)
    kind == "fixture" || return Any[]
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

function stream_policy_watermark_mode(workflow)
    workflow.runtime.policy === nothing && return "processing_time"
    return String(get(workflow.runtime.policy, "watermark_mode", "processing_time"))
end

function stream_adapter_contract(workflow)
    kind = lowercase(stream_source_kind(workflow))
    source = workflow.runtime.source === nothing ? Dict{String,Any}() : workflow.runtime.source
    contract = Dict{String,Any}(
        "kind" => kind,
        "deliverySemantics" => "source_at_least_once_sink_exactly_once_fenced",
        "replayMode" => "committed_offset",
        "watermarkMode" => stream_policy_watermark_mode(workflow),
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

function stream_watermark_state(workflow, execution, events, offset_start::Integer, processed_offset::Integer)
    mode = stream_policy_watermark_mode(workflow)
    previous_watermark = Int(get(execution.metadata, "stream_watermark", 0))
    lateness = stream_policy_allowed_lateness(workflow)
    candidate = previous_watermark
    source = "previous"
    if !isempty(events)
        if mode == "event_time"
            candidate = maximum(event_time_seconds(event, offset_start + index) for (index, event) in enumerate(events)) - lateness
            source = "event_time"
        else
            candidate = processed_offset
            source = "processing_time"
        end
    end
    committed = max(previous_watermark, candidate)
    return Dict{String,Any}(
        "mode" => mode,
        "source" => source,
        "allowedLatenessSeconds" => lateness,
        "previousWatermark" => previous_watermark,
        "candidateWatermark" => candidate,
        "committedWatermark" => committed,
        "status" => committed > previous_watermark ? "advanced" : "held",
    )
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
    watermark_state = stream_watermark_state(workflow, execution, events, offset_start, processed_offset)
    watermark = Int(watermark_state["committedWatermark"])
    batch_count = isempty(events) ? previous_batches : previous_batches + 1
    topic = workflow.runtime.source === nothing ? "unknown" : String(get(workflow.runtime.source, "topic", "fixture"))
    consumer_group = workflow.runtime.source === nothing ? "unknown" : String(get(workflow.runtime.source, "consumer_group", "fixture"))
    transaction_id = "stream-$(execution.execution_id)-offset-$(offset_start)-$(processed_offset)"
    idempotency_key = "$(topic):$(consumer_group):$(processed_offset)"
    transaction_state = Dict{String,Any}(
        "status" => isempty(events) ? "idle" : "committed",
        "transactionId" => transaction_id,
        "idempotencyKey" => idempotency_key,
        "fenceToken" => "$(consumer_group):$(offset_start):$(processed_offset)",
        "checkpointOffset" => processed_offset,
        "committedOffset" => processed_offset,
        "sinkKind" => "workflow_output",
    )
    if !isempty(events)
        transaction_state = commit_external_stream_sink(events, transaction_state)
    end
    return Dict{String,Any}(
        "stream_adapter" => stream_source_kind(workflow),
        "stream_processed_offset" => processed_offset,
        "stream_committed_offset" => processed_offset,
        "stream_processed_rows" => previous_rows + length(events),
        "stream_batch_count" => batch_count,
        "stream_consumer_lag" => lag,
        "stream_backpressure" => lag > max_batches ? "lagging" : "ok",
        "stream_watermark" => watermark,
        "stream_watermark_state" => watermark_state,
        "stream_window_state" => fixture_window_summary(events, offset_start, workflow),
        "stream_last_checkpoint_id" => "stream-$(execution.execution_id)-batch-$(batch_count)",
        "stream_checkpoint_offsets" => Dict(
            "topic" => topic,
            "consumerGroup" => consumer_group,
            "lastOffset" => processed_offset,
            "committedOffset" => processed_offset,
            "lag" => lag,
            "watermark" => watermark,
            "transactionId" => transaction_id,
        ),
        "stream_sink_transaction_id" => transaction_id,
        "stream_sink_transaction_state" => transaction_state,
        "stream_idempotency_key" => idempotency_key,
        "stream_exactly_once_status" => isempty(events) ? "idle" : "committed",
    )
end

function commit_external_stream_sink(events, transaction_state::AbstractDict)
    state_path = strip(get(ENV, "JULIAFLOW_STREAM_SINK_STATE_PATH", ""))
    output_path = strip(get(ENV, "JULIAFLOW_STREAM_SINK_OUTPUT_PATH", ""))
    isempty(state_path) && return Dict{String,Any}(String(key) => value for (key, value) in pairs(transaction_state))
    state = isfile(state_path) ? JSON3.read(read(state_path, String), Dict{String,Any}) : Dict{String,Any}()
    keys = Set(String(item) for item in get(state, "idempotencyKeys", Any[]))
    key = String(transaction_state["idempotencyKey"])
    committed = Dict{String,Any}(String(item_key) => item_value for (item_key, item_value) in pairs(transaction_state))
    if key in keys
        committed["status"] = "duplicate_rejected"
        committed["duplicateRejected"] = true
        return committed
    end

    push!(keys, key)
    transactions = collect(get(state, "transactions", Any[]))
    push!(transactions, Dict(
        "transactionId" => String(transaction_state["transactionId"]),
        "idempotencyKey" => key,
        "committedOffset" => Int(transaction_state["committedOffset"]),
    ))
    next_state = Dict{String,Any}(
        "idempotencyKeys" => sort!(collect(keys)),
        "transactions" => transactions,
    )
    mkpath(dirname(state_path))
    write(state_path, JSON3.write(next_state))

    if !isempty(output_path)
        mkpath(dirname(output_path))
        open(output_path, "a") do io
            for event in events
                println(io, JSON3.write(Dict(
                    "transactionId" => String(transaction_state["transactionId"]),
                    "idempotencyKey" => key,
                    "event" => event,
                )))
            end
        end
    end
    return committed
end

function gpu_registry()
    raw = strip(get(ENV, "JULIAFLOW_GPU_REGISTRY", ""))
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
            # This environment value is a fixture/compatibility hint. It is
            # never proof that a physical device or driver is usable.
            "mode" => "simulated",
            "usable" => false,
            "memory_gb" => 16,
        ))
    end
    return devices
end

function cuda_failure_reason(error)
    description = lowercase(sprint(showerror, error))
    occursin("precompiled for cuda", description) && return "runtime_mismatch"
    occursin("insufficient driver", description) && return "driver_mismatch"
    occursin("out of memory", description) && return "insufficient_vram"
    occursin("permission", description) && return "device_inaccessible"
    return "cuda_driver_or_runtime_error"
end

const GPU_DISCOVERY_LOCK = ReentrantLock()
const GPU_DISCOVERY_CACHE = Ref{Any}(nothing)

function visible_nvidia_devices()
    lock(GPU_DISCOVERY_LOCK) do
        cached = GPU_DISCOVERY_CACHE[]
        cached !== nothing && time() - cached[1] < 10 && return deepcopy(cached[2])
        executable = Sys.which("nvidia-smi")
        devices = Dict{String,Any}[]
        if executable !== nothing
            try
                output = mktemp() do path, io
                    close(io)
                    open(path, "w") do stream
                        command = Cmd([executable, "--query-gpu=index,uuid,memory.total,driver_version", "--format=csv,noheader,nounits"])
                        process = run(pipeline(command, stdout = stream, stderr = devnull); wait = false)
                        if timedwait(() -> process_exited(process), 5.0) == :timed_out
                            kill(process)
                            wait(process)
                            return ""
                        end
                        success(process) || return ""
                    end
                    read(path, String)
                end
                for line in split(output, '\n')
                    parts = split(strip(line), ',')
                    length(parts) == 4 || continue
                    index = tryparse(Int, strip(parts[1]))
                    memory_mib = tryparse(Int, strip(parts[3]))
                    device_id = strip(parts[2])
                    index === nothing && continue
                    memory_mib === nothing && continue
                    occursin(r"^GPU-[a-fA-F0-9-]{36}$", device_id) || continue
                    push!(devices, Dict{String,Any}(
                        "accelerator" => "cuda", "device_id" => device_id,
                        "index" => index, "vendor" => "nvidia", "mode" => "hardware",
                        "name" => "NVIDIA device", "memory_bytes" => memory_mib * 1024 * 1024,
                        "memory_gb" => memory_mib * 1024 * 1024 ÷ 1_000_000_000,
                        "driver_version" => strip(parts[4]), "usable" => false,
                        "probe_status" => "unprobed", "probe_reason" => "not_requested",
                    ))
                end
            catch
                # An inventory command is not an operational CUDA probe.
            end
        end
        GPU_DISCOVERY_CACHE[] = (time(), deepcopy(devices))
        return devices
    end
end

function physical_gpu_devices()
    if get(ENV, "JULIAFLOW_DISABLE_HARDWARE_PROBE", "0") == "1"
        return Dict{String,Any}[], "skipped", "probe_disabled"
    end
    CUDA = try
        Base.require(Base.PkgId(Base.UUID("052768ef-5323-5732-b1bb-66c8b64840ba"), "CUDA"))
    catch error
        return Dict{String,Any}[], "failed", cuda_failure_reason(error) == "cuda_driver_or_runtime_error" ?
            "cuda_package_unavailable" : cuda_failure_reason(error)
    end
    # CUDA methods enter the method table when Base.require loads the package.
    # Cross that world boundary before calling them from this module.
    return Base.invokelatest(physical_gpu_devices_loaded, CUDA)
end

function physical_gpu_devices_loaded(CUDA)
    try
        CUDA.functional() || return Dict{String,Any}[], "failed", "cuda_runtime_unavailable"
        devices = Dict{String,Any}[]
        for device in CUDA.devices()
            device_id = "GPU-" * string(CUDA.uuid(device))
            probe = try
                CUDA.device!(device) do
                    input = CUDA.CuArray([1.0, 2.0])
                    output = input .* 2.0 .+ 1.0
                    CUDA.synchronize()
                    values = Array(output)
                    values == [3.0, 5.0] || error("CUDA probe output mismatch")
                    CUDA.device(output) == device || error("CUDA operation used another device")
                    Dict("status" => "passed", "reason" => "none", "free_memory_bytes" => Int(CUDA.free_memory()))
                end
            catch error
                reason = cuda_failure_reason(error)
                Dict("status" => "failed", "reason" => reason == "cuda_driver_or_runtime_error" ?
                    "allocation_or_operation_failed" : reason, "free_memory_bytes" => 0)
            end
            push!(devices, Dict{String,Any}(
                "accelerator" => "cuda", "device_id" => device_id, "index" => Int(CUDA.deviceid(device)),
                "vendor" => "nvidia", "mode" => "hardware", "name" => String(CUDA.name(device)),
                "memory_bytes" => Int(CUDA.totalmem(device)),
                "memory_gb" => Int(CUDA.totalmem(device)) ÷ 1_000_000_000,
                "free_memory_bytes" => probe["free_memory_bytes"], "usable" => probe["status"] == "passed",
                "probe_status" => probe["status"], "probe_reason" => probe["reason"],
                "runtime_version" => string(CUDA.runtime_version()), "driver_version" => string(CUDA.driver_version()),
            ))
        end
        isempty(devices) && return devices, "failed", "no_cuda_device_visible"
        any(device -> device["usable"], devices) || return devices, "failed", "no_usable_cuda_device"
        return devices, "passed", "none"
    catch error
        return Dict{String,Any}[], "failed", cuda_failure_reason(error)
    end
end

function gpu_registry_health(; probe::Bool = false)
    simulated = gpu_registry()
    visible = visible_nvidia_devices()
    tested, status, reason = probe ? physical_gpu_devices() : (Dict{String,Any}[], "unprobed", "not_requested")
    physical = Dict{String,Any}[]
    for device in visible
        match = findfirst(tested_device -> tested_device["device_id"] == device["device_id"], tested)
        if match === nothing
            push!(physical, probe ? merge(device, Dict("probe_status" => status, "probe_reason" => reason)) : device)
        else
            push!(physical, merge(device, tested[match]))
        end
    end
    for device in tested
        any(visible_device -> visible_device["device_id"] == device["device_id"], visible) || push!(physical, device)
    end
    devices = [physical; simulated]
    return Dict(
        "device_count" => count(device -> get(device, "usable", false), physical),
        "visible_device_count" => length(physical),
        "simulated_device_count" => length(simulated),
        "probe_status" => status,
        "probe_reason" => reason,
        "cuda_installed" => Base.find_package("CUDA") !== nothing,
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

function sorted_gpu_devices(registry = gpu_registry_health(; probe = true))
    devices = [device for device in registry["devices"] if get(device, "mode", "") == "hardware" && get(device, "usable", false)]
    sort!(devices, by = device -> (String(device["device_id"]), String(device["accelerator"])))
    return devices
end

function gpu_device_matches(device, requested::AbstractString)
    device_id = String(device["device_id"])
    accelerator = String(device["accelerator"])
    vendor = String(get(device, "vendor", accelerator))
    requested_value = lowercase(strip(String(requested)))
    device_id_value = lowercase(device_id)
    accelerator_value = lowercase(accelerator)
    vendor_value = lowercase(vendor)
    numeric_suffix = replace(device_id_value, r"^[A-Za-z_\-]+" => "")
    aliases = Set([
        device_id_value,
        "$(accelerator_value):$(device_id_value)",
        "$(vendor_value):$(device_id_value)",
    ])
    if haskey(device, "index")
        index = Int(device["index"])
        union!(aliases, ["$(index)", "cuda:$(index)", "nvidia:$(index)", "nvidia$(index)"])
    end
    isempty(numeric_suffix) || push!(aliases, "$(accelerator_value):$(numeric_suffix)")
    isempty(numeric_suffix) || push!(aliases, "$(vendor_value):$(numeric_suffix)")
    requested_value in aliases && return true
    return false
end

function gpu_device_capacity(devices)
    return Dict{String,Any}(
        "device_count" => length(devices),
        "worker_device_limit" => 1,
        "isolation_mode" => "isolated",
        "available_device_ids" => [String(device["device_id"]) for device in devices],
    )
end

function gpu_placement_decision(workflow, execution; registry = gpu_registry_health(; probe = true))
    devices = sorted_gpu_devices(registry)
    requested = gpu_requested_device(workflow, execution)
    if isempty(devices)
        return Dict{String,Any}(
            "device" => nothing,
            "requested_device" => requested,
            "selected_device" => "cpu-fallback",
            "fallback_reason" => String(get(registry, "probe_reason", "no_usable_cuda_device")),
            "placement_reason" => "no_matching_gpu_device",
            "scheduler_policy" => "deterministic_device_id",
            "worker_capacity" => gpu_device_capacity(devices),
        )
    end

    if requested !== nothing
        for device in devices
            if gpu_device_matches(device, requested)
                return Dict{String,Any}(
                    "device" => device,
                    "requested_device" => requested,
                    "selected_device" => String(device["device_id"]),
                    "fallback_reason" => "none",
                    "placement_reason" => "requested_device_match",
                    "scheduler_policy" => "deterministic_device_id",
                    "worker_capacity" => gpu_device_capacity(devices),
                )
            end
        end
        return Dict{String,Any}(
            "device" => nothing,
            "requested_device" => requested,
            "selected_device" => "cpu-fallback",
            "fallback_reason" => "requested_device_unavailable",
            "placement_reason" => "no_matching_gpu_device",
            "scheduler_policy" => "deterministic_device_id",
            "worker_capacity" => gpu_device_capacity(devices),
        )
    end

    device = devices[1]
    return Dict{String,Any}(
        "device" => device,
        "requested_device" => nothing,
        "selected_device" => String(device["device_id"]),
        "fallback_reason" => "none",
        "placement_reason" => "deterministic_default",
        "scheduler_policy" => "deterministic_device_id",
        "worker_capacity" => gpu_device_capacity(devices),
    )
end

function select_gpu_device(workflow, execution)
    return gpu_placement_decision(workflow, execution)["device"]
end

function gpu_workload_config(workflow)
    node = gpu_workflow_node(workflow)
    node === nothing && return Dict{String,Any}("kind" => "mock_vector_sum", "input_values" => [1.0, 2.0, 3.0, 4.0])
    kind = haskey(node.config, "gpuWorkload") ? String(node.config["gpuWorkload"]) : "mock_vector_sum"
    values = haskey(node.config, "mockInputValues") ? [Float64(value) for value in node.config["mockInputValues"]] : [1.0, 2.0, 3.0, 4.0]
    return Dict{String,Any}("kind" => kind, "input_values" => values, "node_id" => node.id)
end

struct GpuUnavailableError <: Exception
    reason::String
end

function gpu_required(workflow, execution)
    requested = String(get(execution.metadata, "requested_execution_mode", ""))
    requested in ("gpu_required", "cuda_required", "batch_gpu_required") && return true
    node = gpu_workflow_node(workflow)
    return node !== nothing && node.execution_hint == :gpu_required
end

function execute_gpu_workload(workflow, execution; device = nothing)
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
    elseif kind == "cuda_ka_vector_affine"
        if device === nothing
            output = values .* 2.0 .+ 1.0
            return Dict("kind" => "cpu_vector_affine", "input_size" => length(values),
                "sum" => sum(output), "first" => isempty(output) ? 0.0 : output[1],
                "last" => isempty(output) ? 0.0 : output[end])
        end
        return execute_cuda_ka_vector_affine(values, device)
    end
    error("unsupported gpu workload: $(kind)")
end

function execute_cuda_ka_vector_affine(values::Vector{Float64}, selected::AbstractDict)
    CUDA = Base.require(Base.PkgId(Base.UUID("052768ef-5323-5732-b1bb-66c8b64840ba"), "CUDA"))
    KA = Base.require(Base.PkgId(Base.UUID("63c18a36-062a-441e-b654-da1e3ab1ce7c"), "KernelAbstractions"))
    return Base.invokelatest(execute_cuda_ka_vector_affine_loaded, values, selected, CUDA, KA)
end

function execute_cuda_ka_vector_affine_loaded(values, selected, CUDA, KA)
    CUDA.functional() || error("CUDA runtime is not functional")
    selected_id = String(selected["device_id"])
    devices = collect(CUDA.devices())
    chosen = findfirst(device -> "GPU-" * string(CUDA.uuid(device)) == selected_id, devices)
    chosen === nothing && throw(GpuUnavailableError("selected_device_disappeared"))
    return CUDA.device!(devices[chosen]) do
        Int(CUDA.free_memory()) >= max(1024 * 1024, length(values) * 24) ||
            throw(GpuUnavailableError("insufficient_vram"))
        input = CUDA.CuArray(values)
        output = input .* 2.0 .+ 1.0
        CUDA.synchronize()
        actual = CUDA.device(output)
        actual_id = "GPU-" * string(CUDA.uuid(actual))
        actual_id == selected_id || error("CUDA output device differs from selected device")
        host_output = Array(output)
        Dict(
            "kind" => "cuda_ka_vector_affine", "backend" => string(KA.get_backend(output)),
            "device_count" => length(devices), "selected_device_id" => selected_id,
            "actual_device_id" => actual_id, "runtime_version" => string(CUDA.runtime_version()),
            "driver_version" => string(CUDA.driver_version()),
            "device_memory_limit_bytes" => Int(CUDA.totalmem(actual)),
            "input_size" => length(values), "sum" => sum(host_output),
            "first" => isempty(host_output) ? 0.0 : host_output[1],
            "last" => isempty(host_output) ? 0.0 : host_output[end],
        )
    end
end

function gpu_runtime_metadata(workflow, execution)
    kind = String(gpu_workload_config(workflow)["kind"])
    actual_gpu_workload = kind == "cuda_ka_vector_affine"
    gpu_required(workflow, execution) && !actual_gpu_workload &&
        throw(GpuUnavailableError("no_supported_gpu_workload"))
    registry = gpu_registry_health(; probe = actual_gpu_workload)
    placement = gpu_placement_decision(workflow, execution; registry)
    device = placement["device"]
    if gpu_required(workflow, execution) && device === nothing
        throw(GpuUnavailableError(String(placement["fallback_reason"])))
    end
    result = execute_gpu_workload(workflow, execution; device = actual_gpu_workload ? device : nothing)
    path = actual_gpu_workload && device !== nothing ? "gpu" : "cpu_fallback"
    request_satisfied = path == "gpu" &&
        (placement["requested_device"] === nothing || String(placement["fallback_reason"]) == "none")
    placement_fallback_used = placement["requested_device"] !== nothing && !request_satisfied
    metadata = Dict{String,Any}(
        "gpu_registry" => registry,
        "gpu_execution_path" => path,
        "gpu_workload" => String(result["kind"]),
        "gpu_workload_result" => result,
        "gpu_fallback_used" => path != "gpu",
        "gpu_cpu_fallback_used" => path != "gpu",
        "gpu_placement_fallback_used" => placement_fallback_used,
        "gpu_request_satisfied" => request_satisfied,
        "gpu_selected_device" => path == "gpu" ? String(placement["selected_device"]) : "cpu-fallback",
        "gpu_fallback_reason" => path == "gpu" ? "none" :
            actual_gpu_workload ? String(placement["fallback_reason"]) : "mock_workload_cpu_only",
        "gpu_placement_reason" => String(placement["placement_reason"]),
        "gpu_scheduler_policy" => String(placement["scheduler_policy"]),
        "gpu_worker_isolation_mode" => "isolated",
        "gpu_worker_capacity" => placement["worker_capacity"],
        "gpu_evidence_version" => 2,
        "gpu_probe_status" => String(registry["probe_status"]),
        "gpu_planned_device" => String(placement["selected_device"]),
        "gpu_actual_device" => path == "gpu" ? String(result["actual_device_id"]) : "cpu",
    )
    placement["requested_device"] === nothing || (metadata["gpu_requested_device"] = String(placement["requested_device"]))
    if path != "gpu"
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
    empty!(service.control_flow_branch_execution_ids)
    empty!(service.data_science_project_job_execution_ids)

    for execution in executions
        lifecycle = stream_lifecycle_status(execution)
        if lifecycle !== nothing && lifecycle != "stopped" && execution.status != "completed" && execution.status != "failed"
            service.stream_execution_ids[execution.workflow_id] = execution.execution_id
        end
        has_gpu_dispatch(execution) && push!(service.gpu_execution_ids, execution.execution_id)
        has_completed_control_flow_branch(execution) && push!(service.control_flow_branch_execution_ids, execution.execution_id)
        has_data_science_project_job(execution) && push!(service.data_science_project_job_execution_ids, execution.execution_id)
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
        "stream_watermark_state" => get(execution.metadata, "stream_watermark_state", Dict{String,Any}()),
        "stream_sink_transaction_id" => transaction_id,
        "stream_sink_transaction_state" => get(execution.metadata, "stream_sink_transaction_state", Dict{String,Any}()),
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
        "dispatch_scheduler_policy" => String(get(dispatch, "scheduler_policy", "deterministic_device_id")),
        "dispatch_placement_reason" => String(get(dispatch, "placement_reason", "gpu_lane_isolated_worker")),
        "dispatch_worker_capacity" => get(dispatch, "worker_capacity", Dict{String,Any}("concurrency" => 1, "device_slots" => 1)),
        "worker_id" => "gpu-worker-" * execution.execution_id[1:8],
    )
    haskey(dispatch, "accelerator") && (metadata["dispatch_accelerator"] = String(dispatch["accelerator"]))
    haskey(dispatch, "requested_device") && (metadata["dispatch_requested_device"] = String(dispatch["requested_device"]))
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

function process_executor_schedule_tick!(
    service::WorkerServiceState,
    executions;
    workflows = nothing,
    execute_stage_node = nothing,
    execution_record,
    transition_execution_record,
    append_execution_event,
    materialize_execution,
)
    updated_executions = Any[]
    for (index, execution) in pairs(executions)
        should_process_executor_schedule(execution) || continue
        schedule = executor_schedule(execution)
        state = executor_state(execution)
        current_stage = Int(get(state, "current_stage_index", 0))

        if execution.status == "accepted"
            metadata = executor_state_metadata(execution, schedule; status = "queued", current_stage_index = 0, completed_stage_count = 0)
            updated = transition_execution_record(execution_record(execution), "queued"; message = "Queued for executor schedule", metadata = metadata)
        elseif execution.status == "queued"
            metadata = executor_state_metadata(execution, schedule; status = "running", current_stage_index = 1, completed_stage_count = 0)
            updated = transition_execution_record(execution_record(execution), "running"; message = "Executor stage 1 started", metadata = metadata)
        else
            workflow = workflows === nothing ? nothing : get(workflows, execution.workflow_id, nothing)
            stage_index = min(max(current_stage, 1), length(schedule))
            stage_node_ids = executor_stage_node_ids(schedule[stage_index])
            node_results, failed_result = workflow === nothing ?
                (nothing, nothing) :
                execute_executor_stage_nodes(workflow, execution, stage_node_ids, execute_stage_node)
            completed_count = failed_result === nothing ? stage_index : max(stage_index - 1, 0)
            stage_status = failed_result === nothing ? "completed" : "failed"
            stage_result = executor_stage_result(schedule[stage_index]; status = stage_status, node_results = node_results)
            stage_results = executor_merge_stage_results(schedule, state, stage_result, stage_index)
            all_node_results = node_results === nothing ? nothing : vcat(executor_existing_node_results(state), node_results)

            if failed_result !== nothing
                metadata = executor_state_metadata(
                    execution,
                    schedule;
                    status = "failed",
                    current_stage_index = stage_index,
                    completed_stage_count = completed_count,
                    stage_results = stage_results,
                    node_results = all_node_results,
                    failed_node_id = failed_result["node_id"],
                    error_message = get(failed_result, "error_message", "executor node failed"),
                )
                metadata["failedNodeId"] = failed_result["node_id"]
                updated = transition_execution_record(
                    execution_record(execution),
                    "failed";
                    message = "Executor node $(failed_result["node_id"]) failed",
                    metadata = metadata,
                )
            elseif current_stage >= length(schedule)
                metadata = executor_state_metadata(
                    execution,
                    schedule;
                    status = "completed",
                    current_stage_index = length(schedule),
                    completed_stage_count = length(schedule),
                    stage_results = stage_results,
                    node_results = all_node_results,
                )
                updated = transition_execution_record(execution_record(execution), "completed"; message = "Executor schedule completed", metadata = metadata)
            else
                next_stage = max(current_stage + 1, 1)
                metadata = executor_state_metadata(
                    execution,
                    schedule;
                    status = "running",
                    current_stage_index = next_stage,
                    completed_stage_count = max(current_stage, 1),
                    stage_results = stage_results,
                    node_results = all_node_results,
                )
                updated = append_execution_event(execution_record(execution); message = "Executor stage $(max(current_stage, 1)) completed", metadata = metadata)
            end
        end

        materialized = materialize_execution(updated)
        executions[index] = materialized
        push!(service.executor_execution_ids, materialized.execution_id)
        push!(updated_executions, materialized)
    end
    return updated_executions
end

function process_data_science_project_job_tick!(
    service::WorkerServiceState,
    executions;
    execution_record,
    transition_execution_record,
    materialize_execution,
)
    updated_executions = Any[]
    for (index, execution) in pairs(executions)
        should_process_data_science_project_job(execution) || continue

        if execution.status == "accepted"
            metadata = data_science_project_job_worker_metadata(execution, "queued")
            updated = transition_execution_record(
                execution_record(execution),
                "queued";
                message = "Queued for data science project worker",
                metadata = metadata,
            )
        elseif execution.status == "queued"
            metadata = data_science_project_job_worker_metadata(execution, "running")
            updated = transition_execution_record(
                execution_record(execution),
                "running";
                message = "Data science project worker started",
                metadata = metadata,
            )
        else
            metadata = data_science_project_job_worker_metadata(execution, "completed")
            updated = transition_execution_record(
                execution_record(execution),
                "completed";
                message = "Data science project worker completed",
                metadata = metadata,
            )
        end

        materialized = materialize_execution(updated)
        executions[index] = materialized
        push!(service.data_science_project_job_execution_ids, materialized.execution_id)
        push!(updated_executions, materialized)
    end
    return updated_executions
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

    workflow = workflows[workflow_id]
    events = stream_fixture_events(workflow)
    limit = batch_size === nothing ? stream_policy_max_batches(workflow) : max(Int(batch_size), 1)
    committed_offset >= length(events) && return current_execution
    next_offset = min(committed_offset + limit, length(events))
    batch = events[(committed_offset + 1):next_offset]
    metadata = stream_runtime_metadata(workflow, current_execution, batch, committed_offset)
    metadata["stream_replay_status"] = "restored_from_checkpoint"
    metadata["stream_replay_offset"] = committed_offset
    updated = append_execution_event(
        execution_record(current_execution);
        message = "Streaming replay restored from checkpoint",
        metadata = metadata,
    )
    execution = materialize_execution(updated)
    executions[index] = execution
    service.stream_execution_ids[workflow_id] = execution.execution_id
    return execution
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
        updated = try
            metadata = gpu_runtime_metadata(workflow, execution)
            transition_execution_record(
                execution_record(execution),
                "completed";
                message = metadata["gpu_execution_path"] == "gpu" ? "GPU worker completed workload" : "GPU worker completed workload via CPU fallback",
                metadata = metadata,
            )
        catch error
            reason = error isa GpuUnavailableError ? error.reason : "gpu_execution_error"
            requested = gpu_requested_device(workflow, execution)
            failure_evidence = Dict{String,Any}(
                "gpu_evidence_version" => 2, "gpu_execution_path" => "unavailable",
                "gpu_probe_status" => reason == "no_supported_gpu_workload" ? "unprobed" :
                    reason == "probe_disabled" ? "skipped" : "failed",
                "gpu_planned_device" => "unavailable", "gpu_actual_device" => "none",
                "gpu_fallback_used" => false, "gpu_cpu_fallback_used" => false,
                "gpu_fallback_reason" => reason,
            )
            requested === nothing || (failure_evidence["gpu_requested_device"] = String(requested))
            transition_execution_record(
                execution_record(execution),
                "failed";
                message = "GPU worker could not execute the requested workload",
                metadata = failure_evidence,
            )
        end
        updated_execution = materialize_execution(updated)
        index = find_execution_index(executions, execution.execution_id)
        executions[index] = updated_execution
        push!(service.gpu_execution_ids, updated_execution.execution_id)
        push!(updated_executions, updated_execution)
    end
    return updated_executions
end

function process_control_flow_recovery_tick!(
    service::WorkerServiceState,
    workflows,
    executions;
    execution_record,
    transition_execution_record,
    append_execution_event,
    materialize_execution,
)
    updated_executions = Any[]
    for execution in executions
        execution.status == "completed" && continue
        execution.status == "failed" && continue
        recovery = control_flow_recovery(execution)
        recovery === nothing && continue
        has_completed_control_flow_branch(execution) && continue
        workflow = workflows[execution.workflow_id]

        current = execution_record(execution)
        if execution.status == "accepted"
            current = transition_execution_record(
                current,
                "queued";
                message = "Catch branch queued for worker execution",
            )
        end
        if String(get(current, "status", "")) == "queued"
            current = transition_execution_record(
                current,
                "running";
                message = "Catch branch worker started",
            )
        end

        metadata = Dict{String,Any}(
            "control_flow_branch_state" => control_flow_branch_metadata(workflow, execution, recovery),
        )
        if String(get(current, "status", "")) == "running"
            current = transition_execution_record(
                current,
                "completed";
                message = "Catch branch worker completed",
                metadata = metadata,
            )
        else
            current = append_execution_event(
                current;
                message = "Catch branch worker completed",
                metadata = metadata,
            )
        end

        updated_execution = materialize_execution(current)
        index = find_execution_index(executions, execution.execution_id)
        executions[index] = updated_execution
        push!(service.control_flow_branch_execution_ids, updated_execution.execution_id)
        push!(updated_executions, updated_execution)
    end
    return updated_executions
end

end
