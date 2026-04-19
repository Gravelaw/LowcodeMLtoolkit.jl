module JuliaFlowApiGateway

include(joinpath(@__DIR__, "JuliaFlowGatewayRepository.jl"))

using .JuliaFlowGatewayRepository
using Dates
using HTTP
using JSON3
using UUIDs

export GatewayCheckpoint,
    GatewayExecution,
    GatewayState,
    load_state,
    persist_workflow_file!,
    persist_workflow_text!,
    foundation_state,
    healthcheck,
    list_workflows_response,
    get_workflow_response,
    execution_accept_response,
    execution_list_response,
    execution_detail_response,
    transition_execution_response!,
    create_checkpoint_response!,
    checkpoint_list_response,
    import_workflow_response!,
    create_workflow_response!,
    update_workflow_response!,
    handle_realtime_socket!,
    route_request,
    serve_gateway,
    repository_backend

const GatewayCheckpoint = JuliaFlowGatewayRepository.GatewayCheckpoint
const GatewayExecution = JuliaFlowGatewayRepository.GatewayExecution

Base.@kwdef mutable struct GatewayState
    repository::AbstractGatewayRepository
    workflows::Dict{String,JuliaFlowGatewayRepository.JuliaFlowExecutionService.WorkflowDefinition} = Dict{String,JuliaFlowGatewayRepository.JuliaFlowExecutionService.WorkflowDefinition}()
    checkpoints::Vector{GatewayCheckpoint} = GatewayCheckpoint[]
    executions::Vector{GatewayExecution} = GatewayExecution[]
    canvas_subscriptions::Dict{String,Any} = Dict{String,Any}()
    dashboard_subscriptions::Dict{String,Any} = Dict{String,Any}()
end

Base.@kwdef mutable struct CanvasSubscription
    subscription_id::String
    workflow_id::String
    socket
end

Base.@kwdef mutable struct DashboardSubscription
    subscription_id::String
    dashboard_id::String
    outlet_ids::Vector{String} = String[]
    socket
end

function repository_backend(state::GatewayState)
    return nameof(typeof(state.repository))
end

function reload_state!(state::GatewayState)
    state.workflows = load_workflows(state.repository)
    state.checkpoints = load_checkpoints(state.repository)
    state.executions = load_executions(state.repository)
    return state
end

function load_state(repository::AbstractGatewayRepository)
    state = GatewayState(repository = ensure_repository!(repository))
    return reload_state!(state)
end

function load_state(store_root::AbstractString)
    return load_state(load_repository(backend = :file, store_root = store_root))
end

function persist_workflow_text!(state::GatewayState, workflow_toml::AbstractString)
    workflow = save_workflow!(state.repository, workflow_toml)
    state.workflows[workflow.id] = workflow
    return workflow
end

function persist_workflow_file!(state::GatewayState, source_path::AbstractString)
    return persist_workflow_text!(state, read(source_path, String))
end

function normalized_string_dict(value)
    return Dict{String,Any}(String(key) => item for (key, item) in pairs(value))
end

function normalize_flow_variable(variable)
    normalized = normalized_string_dict(variable)
    haskey(normalized, "name") || error("flow variable missing name")
    haskey(normalized, "type") || error("flow variable missing type")

    result = Dict{String,Any}(
        "name" => String(normalized["name"]),
        "type" => String(normalized["type"]),
    )
    haskey(normalized, "default") && (result["default"] = normalized["default"])
    return result
end

function normalize_node_payload(node)
    normalized = normalized_string_dict(node)
    ports = [
        Dict{String,Any}(
            "id" => String(port["id"]),
            "direction" => String(port["direction"]),
            "type" => String(port["type"]),
            "label" => String(get(port, "label", port["id"])),
        ) for port in normalized["ports"]
    ]
    config = haskey(normalized, "config") ? normalized_string_dict(normalized["config"]) : Dict{String,Any}()
    if haskey(normalized, "gpuDevicePreference")
        config["gpuDevicePreference"] = normalized["gpuDevicePreference"]
    end

    capabilities = if haskey(normalized, "capabilities")
        normalized_capabilities = normalized_string_dict(normalized["capabilities"])
        capability_payload = Dict{String,Any}(
            "execution_mode" => String(get(normalized_capabilities, "executionMode", get(normalized_capabilities, "execution_mode", "batch"))),
            "resource_class" => String(get(normalized_capabilities, "resourceClass", get(normalized_capabilities, "resource_class", "cpu"))),
        )
        haskey(normalized_capabilities, "accelerator") && (capability_payload["accelerator"] = String(normalized_capabilities["accelerator"]))
        if haskey(normalized_capabilities, "workerPool")
            capability_payload["worker_pool"] = String(normalized_capabilities["workerPool"])
        elseif haskey(normalized_capabilities, "worker_pool")
            capability_payload["worker_pool"] = String(normalized_capabilities["worker_pool"])
        end
        capability_payload
    else
        nothing
    end

    payload = Dict{String,Any}(
        "id" => String(normalized["id"]),
        "name" => String(normalized["name"]),
        "type" => String(normalized["type"]),
        "execution_hint" => String(normalized["executionHint"]),
        "config" => config,
        "ports" => ports,
    )
    capabilities === nothing || (payload["capabilities"] = capabilities)
    return payload
end

function normalize_connection_payload(connection)
    normalized = normalized_string_dict(connection)
    payload = Dict{String,Any}(
        "source_node_id" => String(normalized["sourceNodeId"]),
        "source_port_id" => String(normalized["sourcePortId"]),
        "target_node_id" => String(normalized["targetNodeId"]),
        "target_port_id" => String(normalized["targetPortId"]),
        "data_type" => String(normalized["dataType"]),
    )
    haskey(normalized, "label") && (payload["label"] = String(normalized["label"]))
    return payload
end

function normalize_graph_payload(graph)
    normalized = normalized_string_dict(graph)
    payload = Dict{String,Any}(
        "revision" => Int(get(normalized, "revision", 1)),
        "node_layouts" => [
            let
                layout = normalized_string_dict(item)
                node_layout = Dict{String,Any}(
                    "node_id" => String(get(layout, "nodeId", get(layout, "node_id", ""))),
                    "x" => Float64(layout["x"]),
                    "y" => Float64(layout["y"]),
                )
                haskey(layout, "width") && (node_layout["width"] = Float64(layout["width"]))
                if haskey(layout, "checkpointTag")
                    node_layout["checkpoint_tag"] = String(layout["checkpointTag"])
                elseif haskey(layout, "checkpoint_tag")
                    node_layout["checkpoint_tag"] = String(layout["checkpoint_tag"])
                end
                haskey(layout, "notes") && (node_layout["notes"] = String(layout["notes"]))
                node_layout
            end for item in get(normalized, "nodeLayouts", get(normalized, "node_layouts", Any[]))
        ],
    )
    if haskey(normalized, "viewport")
        payload["viewport"] = normalized_string_dict(normalized["viewport"])
    end
    if haskey(normalized, "selectedNodeId")
        payload["selected_node_id"] = String(normalized["selectedNodeId"])
    elseif haskey(normalized, "selected_node_id")
        payload["selected_node_id"] = String(normalized["selected_node_id"])
    end
    return payload
end

function normalize_dashboard_payload(dashboard)
    normalized = normalized_string_dict(dashboard)
    binding = normalized_string_dict(normalized["binding"])
    return Dict{String,Any}(
        "id" => String(get(normalized, "dashboardId", get(normalized, "id", ""))),
        "name" => String(normalized["name"]),
        "binding" => Dict{String,Any}(
            "outlet_node_id" => String(get(binding, "outletNodeId", get(binding, "outlet_node_id", ""))),
            "dataset_key" => String(get(binding, "datasetKey", get(binding, "dataset_key", ""))),
            "refresh_mode" => String(get(binding, "refreshMode", get(binding, "refresh_mode", "manual"))),
        ),
        "charts" => [
            let
                chart = normalized_string_dict(item)
                payload = Dict{String,Any}(
                    "id" => String(get(chart, "chartId", get(chart, "id", ""))),
                    "title" => String(chart["title"]),
                    "family" => String(chart["family"]),
                )
                haskey(chart, "xField") && (payload["x_field"] = String(chart["xField"]))
                haskey(chart, "x_field") && (payload["x_field"] = String(chart["x_field"]))
                haskey(chart, "yField") && (payload["y_field"] = String(chart["yField"]))
                haskey(chart, "y_field") && (payload["y_field"] = String(chart["y_field"]))
                haskey(chart, "seriesField") && (payload["series_field"] = String(chart["seriesField"]))
                haskey(chart, "series_field") && (payload["series_field"] = String(chart["series_field"]))
                payload
            end for item in get(normalized, "charts", Any[])
        ],
    )
end

function normalize_runtime_payload(runtime)
    normalized = normalized_string_dict(runtime)
    payload = Dict{String,Any}(
        "run_mode" => String(get(normalized, "runMode", get(normalized, "run_mode", "batch"))),
    )
    haskey(normalized, "source") && (payload["source"] = normalized_string_dict(normalized["source"]))
    haskey(normalized, "window") && (payload["window"] = normalized_string_dict(normalized["window"]))
    haskey(normalized, "policy") && (payload["policy"] = normalized_string_dict(normalized["policy"]))
    return payload
end

function workflow_toml_from_request(body::AbstractDict{<:Any,<:Any})
    if haskey(body, "workflowToml")
        return String(body["workflowToml"])
    end
    haskey(body, "workflow") || error("missing workflow or workflowToml")

    workflow_payload = normalized_string_dict(body["workflow"])
    haskey(workflow_payload, "workflowId") || error("workflow missing workflowId")
    haskey(workflow_payload, "name") || error("workflow missing name")
    haskey(workflow_payload, "version") || error("workflow missing version")

    raw = Dict{String,Any}(
        "version" => String(workflow_payload["version"]),
        "workflow" => Dict{String,Any}(
            "id" => String(workflow_payload["workflowId"]),
            "name" => String(workflow_payload["name"]),
        ),
        "flow_variables" => [
            normalize_flow_variable(variable) for variable in get(workflow_payload, "flowVariables", Any[])
        ],
        "nodes" => [normalize_node_payload(node) for node in workflow_payload["nodes"]],
        "connections" => [normalize_connection_payload(connection) for connection in workflow_payload["connections"]],
    )

    if haskey(workflow_payload, "biOutlets")
        raw["workflow"]["bi_outlets"] = [
            normalized_string_dict(outlet) for outlet in workflow_payload["biOutlets"]
        ]
    end
    if haskey(workflow_payload, "graph")
        raw["workflow"]["graph"] = normalize_graph_payload(workflow_payload["graph"])
    end
    if haskey(workflow_payload, "dashboards")
        raw["workflow"]["dashboards"] = [
            normalize_dashboard_payload(dashboard) for dashboard in workflow_payload["dashboards"]
        ]
    end
    if haskey(workflow_payload, "runtime")
        raw["runtime"] = normalize_runtime_payload(workflow_payload["runtime"])
    end

    workflow = JuliaFlowGatewayRepository.JuliaFlowExecutionService.parse_workflow_definition(raw)
    return JuliaFlowGatewayRepository.JuliaFlowExecutionService.workflow_to_toml(workflow)
end

function foundation_state(
    workflow_path::AbstractString;
    store_root::AbstractString = mktempdir(),
    backend::Symbol = :file,
    connection_string::AbstractString = "",
    schema::AbstractString = "public",
)
    repository = load_repository(backend = backend, store_root = store_root, connection_string = connection_string, schema = schema)
    state = load_state(repository)

    if isempty(state.workflows)
        persist_workflow_file!(state, workflow_path)
    end
    if isempty(state.checkpoints)
        checkpoint = GatewayCheckpoint(
            tag = "cp/00-foundation",
            summary = "Foundation scaffold complete",
            created_at = string(now(UTC)),
        )
        save_checkpoint!(state.repository, checkpoint)
        push!(state.checkpoints, checkpoint)
    end
    return state
end

function latest_checkpoint_tag(state::GatewayState)
    isempty(state.checkpoints) && return "uncheckpointed"
    return state.checkpoints[end].tag
end

function checkpoint_payload(checkpoint::GatewayCheckpoint)
    return JuliaFlowGatewayRepository.checkpoint_payload(checkpoint)
end

function execution_payload(execution::GatewayExecution)
    return JuliaFlowGatewayRepository.execution_payload(execution)
end

function healthcheck(state::GatewayState)
    store_id = state.repository isa FileGatewayRepository ? state.repository.root : "postgresql"
    return JSON3.write(
        Dict(
            "service" => "api-gateway",
            "status" => "ok",
            "repositoryBackend" => String(repository_backend(state)),
            "storeRoot" => store_id,
            "workflowCount" => length(state.workflows),
            "checkpointCount" => length(state.checkpoints),
            "executionCount" => length(state.executions),
        ),
    )
end

function list_workflows_response(state::GatewayState)
    items = [
        Dict(
            "workflowId" => workflow.id,
            "name" => workflow.name,
            "version" => workflow.version,
            "nodeCount" => length(workflow.nodes),
            "latestCheckpoint" => latest_checkpoint_tag(state),
        ) for workflow in values(state.workflows)
    ]
    sort!(items, by = item -> item["workflowId"])
    return JSON3.write(Dict("items" => items))
end

function get_workflow_response(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    workflow = state.workflows[workflow_id]
    return JSON3.write(JuliaFlowGatewayRepository.workflow_detail_payload(workflow))
end

function materialize_execution(job::Dict{String,Any})
    status_history = Dict{String,Any}[]
    for event in get(job, "status_history", Any[])
        normalized = Dict{String,Any}(String(key) => value for (key, value) in pairs(event))
        if haskey(normalized, "timestamp") && !haskey(normalized, "at")
            normalized["at"] = normalized["timestamp"]
            delete!(normalized, "timestamp")
        end
        push!(status_history, normalized)
    end

    metadata = Dict{String,Any}()
    for (key, value) in pairs(job)
        string_key = String(key)
        if string_key in (
            "execution_id",
            "workflow_id",
            "workflow_version",
            "checkpoint_tag",
            "status",
            "mode",
            "plan",
            "stages",
            "node_count",
            "connection_count",
            "created_at",
            "updated_at",
            "status_history",
            "queued_at",
            "started_at",
            "finished_at",
        )
            continue
        end
        metadata[string_key] = value
    end

    return GatewayExecution(
        execution_id = String(job["execution_id"]),
        workflow_id = String(job["workflow_id"]),
        workflow_version = String(job["workflow_version"]),
        checkpoint_tag = String(job["checkpoint_tag"]),
        status = String(job["status"]),
        mode = String(job["mode"]),
        plan = [String(entry) for entry in job["plan"]],
        stages = [[String(entry) for entry in stage] for stage in job["stages"]],
        node_count = Int(job["node_count"]),
        connection_count = Int(job["connection_count"]),
        created_at = String(job["created_at"]),
        updated_at = String(get(job, "updated_at", job["created_at"])),
        status_history = status_history,
        queued_at = haskey(job, "queued_at") ? String(job["queued_at"]) : nothing,
        started_at = haskey(job, "started_at") ? String(job["started_at"]) : nothing,
        finished_at = haskey(job, "finished_at") ? String(job["finished_at"]) : nothing,
        metadata = metadata,
    )
end

function execution_accept_response(
    state::GatewayState,
    workflow_id::AbstractString;
    flow_variable_values::Dict{String,Any} = Dict{String,Any}(),
    execution_mode_override::Union{Nothing,String} = nothing,
)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    job = JuliaFlowGatewayRepository.JuliaFlowExecutionService.execute_workflow(
        state.workflows[workflow_id];
        checkpoint_tag = latest_checkpoint_tag(state),
        flow_variable_values = flow_variable_values,
        execution_mode_override = execution_mode_override,
    )
    execution = materialize_execution(job)
    save_execution!(state.repository, execution)
    push!(state.executions, execution)
    workflow = state.workflows[workflow_id]
    if JuliaFlowGatewayRepository.JuliaFlowExecutionService.is_stream_workflow(workflow)
        execution = activate_stream_execution!(state, execution)
        return JSON3.write(execution_payload(execution))
    end
    broadcast_execution_update!(state, workflow_id, execution)
    return JSON3.write(execution_payload(execution))
end

function execution_list_response(state::GatewayState)
    return JSON3.write(Dict("items" => [execution_payload(execution) for execution in state.executions]))
end

function execution_detail_response(state::GatewayState, execution_id::AbstractString)
    for execution in state.executions
        execution.execution_id == execution_id && return JSON3.write(execution_payload(execution))
    end
    error("execution not found: $(execution_id)")
end

function execution_record(execution::GatewayExecution)
    record = Dict{String,Any}(
        "execution_id" => execution.execution_id,
        "workflow_id" => execution.workflow_id,
        "workflow_version" => execution.workflow_version,
        "checkpoint_tag" => execution.checkpoint_tag,
        "status" => execution.status,
        "mode" => execution.mode,
        "plan" => execution.plan,
        "stages" => execution.stages,
        "node_count" => execution.node_count,
        "connection_count" => execution.connection_count,
        "created_at" => execution.created_at,
        "updated_at" => execution.updated_at,
        "status_history" => execution.status_history,
    )
    execution.queued_at === nothing || (record["queued_at"] = execution.queued_at)
    execution.started_at === nothing || (record["started_at"] = execution.started_at)
    execution.finished_at === nothing || (record["finished_at"] = execution.finished_at)
    isempty(execution.metadata) || merge!(record, execution.metadata)
    return record
end

function find_execution_index(state::GatewayState, execution_id::AbstractString)
    for (index, execution) in pairs(state.executions)
        execution.execution_id == execution_id && return index
    end
    error("execution not found: $(execution_id)")
end

function transition_execution_response!(
    state::GatewayState,
    execution_id::AbstractString;
    status::AbstractString,
    message::Union{Nothing,String} = nothing,
    metadata::Dict{String,Any} = Dict{String,Any}(),
)
    index = find_execution_index(state, execution_id)
    updated = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record(
        execution_record(state.executions[index]),
        status;
        message = message,
        metadata = metadata,
    )
    execution = materialize_execution(updated)
    state.executions[index] = execution
    save_execution!(state.repository, execution)
    broadcast_execution_update!(state, execution.workflow_id, execution)
    return JSON3.write(execution_payload(execution))
end

function create_checkpoint_response!(state::GatewayState; tag::String, summary::String)
    checkpoint = GatewayCheckpoint(
        tag = tag,
        summary = summary,
        created_at = string(now(UTC)),
    )
    save_checkpoint!(state.repository, checkpoint)
    push!(state.checkpoints, checkpoint)
    return JSON3.write(
        Dict(
            "checkpoint" => checkpoint_payload(checkpoint),
            "checkpointCount" => length(state.checkpoints),
        ),
    )
end

function checkpoint_list_response(state::GatewayState)
    return JSON3.write(Dict("items" => [checkpoint_payload(checkpoint) for checkpoint in state.checkpoints]))
end

function import_workflow_response!(state::GatewayState; source_path::AbstractString)
    workflow = persist_workflow_file!(state, source_path)
    broadcast_workflow_save!(state, workflow.id)
    return JSON3.write(
        Dict(
            "workflowId" => workflow.id,
            "name" => workflow.name,
            "persistedPath" => string(source_path),
        ),
    )
end

function create_workflow_response!(state::GatewayState; workflow_toml::AbstractString)
    payload = String(workflow_toml)
    workflow = persist_workflow_text!(state, payload)
    broadcast_workflow_save!(state, workflow.id)
    return JSON3.write(
        Dict(
            "workflowId" => workflow.id,
            "name" => workflow.name,
            "version" => workflow.version,
            "status" => "created",
        ),
    )
end

function create_workflow_response_from_body!(state::GatewayState, request_body::AbstractDict{<:Any,<:Any})
    return create_workflow_response!(state; workflow_toml = workflow_toml_from_request(request_body))
end

function update_workflow_response!(
    state::GatewayState,
    workflow_id::AbstractString;
    workflow_toml::AbstractString,
)
    payload = String(workflow_toml)
    updated = JuliaFlowGatewayRepository.JuliaFlowExecutionService.load_workflow_definition_text(payload)
    updated.id == workflow_id || error("workflow id mismatch: expected $(workflow_id), got $(updated.id)")
    workflow = persist_workflow_text!(state, payload)
    broadcast_workflow_save!(state, workflow.id)
    return JSON3.write(
        Dict(
            "workflowId" => workflow.id,
            "name" => workflow.name,
            "version" => workflow.version,
            "status" => "updated",
        ),
    )
end

function update_workflow_response_from_body!(state::GatewayState, workflow_id::AbstractString, request_body::AbstractDict{<:Any,<:Any})
    return update_workflow_response!(state, workflow_id; workflow_toml = workflow_toml_from_request(request_body))
end

function cors_origin()
    return get(ENV, "JULIAFLOW_CORS_ALLOW_ORIGIN", "*")
end

function base_headers()
    return [
        "Access-Control-Allow-Origin" => cors_origin(),
        "Access-Control-Allow-Headers" => "Content-Type, Authorization",
        "Access-Control-Allow-Methods" => "GET, POST, PUT, OPTIONS",
        "Access-Control-Max-Age" => "86400",
    ]
end

function json_response(status::Integer, body::AbstractString)
    return HTTP.Response(status, ["Content-Type" => "application/json", base_headers()...], body)
end

function empty_response(status::Integer)
    return HTTP.Response(status, base_headers())
end

function error_response(status::Integer, message::AbstractString)
    return json_response(status, JSON3.write(Dict("error" => message)))
end

function parse_request_body(request::HTTP.Request)
    isempty(request.body) && return Dict{String,Any}()
    return copy(JSON3.read(String(request.body), Dict{String,Any}))
end

function jsonrpc_success(id, result)
    return JSON3.write(Dict("jsonrpc" => "2.0", "id" => id, "result" => result))
end

function jsonrpc_error(id, code::Integer, message::AbstractString)
    return JSON3.write(
        Dict(
            "jsonrpc" => "2.0",
            "id" => id,
            "error" => Dict("code" => code, "message" => String(message)),
        ),
    )
end

function jsonrpc_notification(method::AbstractString, params)
    return JSON3.write(Dict("jsonrpc" => "2.0", "method" => String(method), "params" => params))
end

function workflow_state_changed_payload(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    workflow = state.workflows[workflow_id]
    payload = Dict(
        "workflowId" => workflow.id,
        "name" => workflow.name,
        "version" => workflow.version,
        "nodeCount" => length(workflow.nodes),
        "connectionCount" => length(workflow.connections),
        "latestCheckpoint" => latest_checkpoint_tag(state),
        "executionCount" => count(execution -> execution.workflow_id == workflow_id, state.executions),
        "dashboardCount" => length(workflow.dashboards),
        "runMode" => String(workflow.runtime.run_mode),
    )
    workflow.graph === nothing || (payload["graphRevision"] = workflow.graph.revision)
    return payload
end

function repository_save_changed_payload(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    workflow = state.workflows[workflow_id]
    payload = Dict{String,Any}(
        "workflowId" => workflow.id,
        "workflowVersion" => workflow.version,
        "savedAt" => string(now(UTC)),
    )
    workflow.graph === nothing || (payload["graphRevision"] = workflow.graph.revision)
    return payload
end

function workflow_dashboard_ids(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || return String[]
    return [dashboard.id for dashboard in state.workflows[workflow_id].dashboards]
end

function broadcast_workflow_save!(state::GatewayState, workflow_id::AbstractString)
    notifications = String[
        jsonrpc_notification("repository.save.changed", repository_save_changed_payload(state, workflow_id)),
        jsonrpc_notification("workflow.state.changed", workflow_state_changed_payload(state, workflow_id)),
    ]
    broadcast_canvas_notifications!(state, workflow_id, notifications)
    for dashboard_id in workflow_dashboard_ids(state, workflow_id)
        dashboard_notifications = String[
            jsonrpc_notification(
                "dashboard.outlet.updated",
                dashboard_outlet_updated_payload(state, dashboard_id, String[]),
            ),
        ]
        broadcast_dashboard_notifications!(state, dashboard_id, dashboard_notifications)
    end
    return nothing
end

function broadcast_execution_update!(state::GatewayState, workflow_id::AbstractString, execution::GatewayExecution)
    notifications = String[
        jsonrpc_notification("workflow.state.changed", workflow_state_changed_payload(state, workflow_id)),
        jsonrpc_notification("execution.state.changed", execution_state_changed_payload(execution)),
    ]
    for payload in node_state_changed_payloads(state, workflow_id; execution = execution)
        push!(notifications, jsonrpc_notification("node.state.changed", payload))
    end
    broadcast_canvas_notifications!(state, workflow_id, notifications)
    for dashboard_id in workflow_dashboard_ids(state, workflow_id)
        dashboard_notifications = String[
            jsonrpc_notification(
                "dashboard.outlet.updated",
                dashboard_outlet_updated_payload(state, dashboard_id, String[]),
            ),
        ]
        broadcast_dashboard_notifications!(state, dashboard_id, dashboard_notifications)
    end
    return nothing
end

function streaming_checkpoint_completed_payload(state::GatewayState, workflow_id::AbstractString, execution::GatewayExecution)
    return Dict(
        "workflowId" => String(workflow_id),
        "checkpointId" => "stream-" * execution.execution_id,
        "offsets" => Dict(
            "topic" => get(execution.metadata, "stream_topic", "unknown"),
            "consumerGroup" => get(execution.metadata, "stream_consumer_group", "unknown"),
            "lastProcessedAt" => execution.updated_at,
        ),
        "stateVersion" => length(execution.status_history),
    )
end

function broadcast_stream_checkpoint!(state::GatewayState, workflow_id::AbstractString, execution::GatewayExecution)
    notifications = String[
        jsonrpc_notification(
            "streaming.checkpoint.completed",
            streaming_checkpoint_completed_payload(state, workflow_id, execution),
        ),
    ]
    broadcast_canvas_notifications!(state, workflow_id, notifications)
    return nothing
end

function build_stream_execution_metadata(workflow)
    metadata = Dict{String,Any}(
        "stream_lifecycle_status" => "starting",
        "stream_run_mode" => String(workflow.runtime.run_mode),
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

function activate_stream_execution!(state::GatewayState, execution::GatewayExecution)
    workflow = state.workflows[execution.workflow_id]
    index = find_execution_index(state, execution.execution_id)
    queued = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record(
        execution_record(execution),
        "queued";
        message = "Queued for streaming broker lane",
        metadata = build_stream_execution_metadata(workflow),
    )
    running = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record(
        queued,
        "running";
        message = "Streaming broker connected",
        metadata = Dict{String,Any}("stream_lifecycle_status" => "active"),
    )
    updated_execution = materialize_execution(running)
    state.executions[index] = updated_execution
    save_execution!(state.repository, updated_execution)
    broadcast_execution_update!(state, updated_execution.workflow_id, updated_execution)
    return updated_execution
end

function set_stream_lifecycle_response!(
    state::GatewayState,
    workflow_id::AbstractString,
    lifecycle_status::AbstractString;
    message::AbstractString,
)
    index = find_stream_execution_index(state, workflow_id)
    current_execution = state.executions[index]
    updated = JuliaFlowGatewayRepository.JuliaFlowExecutionService.append_execution_event(
        execution_record(current_execution);
        message = message,
        metadata = Dict{String,Any}("stream_lifecycle_status" => String(lifecycle_status)),
    )
    execution = materialize_execution(updated)
    state.executions[index] = execution
    save_execution!(state.repository, execution)
    broadcast_execution_update!(state, execution.workflow_id, execution)
    return execution
end

function stop_stream_execution_response!(state::GatewayState, workflow_id::AbstractString)
    index = find_stream_execution_index(state, workflow_id)
    current_execution = state.executions[index]
    updated = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record(
        execution_record(current_execution),
        "completed";
        message = "Streaming execution stopped",
        metadata = Dict{String,Any}("stream_lifecycle_status" => "stopped"),
    )
    execution = materialize_execution(updated)
    state.executions[index] = execution
    save_execution!(state.repository, execution)
    broadcast_execution_update!(state, execution.workflow_id, execution)
    broadcast_stream_checkpoint!(state, execution.workflow_id, execution)
    return execution
end

function latest_execution_for_workflow(state::GatewayState, workflow_id::AbstractString)
    for execution in Iterators.reverse(state.executions)
        execution.workflow_id == workflow_id && return execution
    end
    return nothing
end

function latest_stream_execution_for_workflow(state::GatewayState, workflow_id::AbstractString)
    for execution in Iterators.reverse(state.executions)
        execution.workflow_id == workflow_id || continue
        lifecycle = get(execution.metadata, "stream_lifecycle_status", nothing)
        lifecycle === nothing && continue
        return execution
    end
    return nothing
end

function find_stream_execution_index(state::GatewayState, workflow_id::AbstractString)
    execution = latest_stream_execution_for_workflow(state, workflow_id)
    execution === nothing && error("stream execution not found for workflow: $(workflow_id)")
    return find_execution_index(state, execution.execution_id)
end

function active_node_ids(execution::GatewayExecution)
    isempty(execution.stages) && return Set{String}()

    if execution.status == "accepted" || execution.status == "queued"
        return Set(String(node_id) for node_id in execution.stages[1])
    elseif execution.status == "running"
        return Set(String(node_id) for node_id in execution.stages[1])
    elseif execution.status == "completed"
        return Set{String}()
    elseif execution.status == "failed"
        return Set{String}()
    end

    return Set{String}()
end

function node_runtime_status(node_id::AbstractString, execution::Union{Nothing,GatewayExecution})
    execution === nothing && return "configured"

    if execution.status == "completed"
        return "executed"
    elseif execution.status == "failed"
        return "error"
    elseif get(execution.metadata, "stream_lifecycle_status", nothing) == "active"
        return "streaming_active"
    elseif node_id in active_node_ids(execution)
        return "running"
    end

    return "configured"
end

function node_state_changed_payloads(
    state::GatewayState,
    workflow_id::AbstractString;
    execution::Union{Nothing,GatewayExecution} = latest_execution_for_workflow(state, workflow_id),
)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    workflow = state.workflows[workflow_id]
    return [
        Dict(
            "workflowId" => workflow.id,
            "nodeId" => node.id,
            "nodeType" => node.type,
            "status" => node_runtime_status(node.id, execution),
            "executionHint" => String(node.execution_hint),
        ) for node in workflow.nodes
    ]
end

function dashboard_outlet_updated_payload(state::GatewayState, dashboard_id::AbstractString, outlet_ids)
    return Dict(
        "dashboardId" => String(dashboard_id),
        "outletIds" => [String(outlet_id) for outlet_id in outlet_ids],
        "latestCheckpoint" => latest_checkpoint_tag(state),
        "updatedAt" => string(now(UTC)),
    )
end

function execution_state_changed_payload(execution::GatewayExecution)
    return execution_payload(execution)
end

function register_canvas_subscription!(state::GatewayState, subscription_id::AbstractString, workflow_id::AbstractString, ws)
    state.canvas_subscriptions[String(subscription_id)] = CanvasSubscription(
        subscription_id = String(subscription_id),
        workflow_id = String(workflow_id),
        socket = ws,
    )
    return subscription_id
end

function register_dashboard_subscription!(state::GatewayState, subscription_id::AbstractString, dashboard_id::AbstractString, outlet_ids, ws)
    state.dashboard_subscriptions[String(subscription_id)] = DashboardSubscription(
        subscription_id = String(subscription_id),
        dashboard_id = String(dashboard_id),
        outlet_ids = [String(outlet_id) for outlet_id in outlet_ids],
        socket = ws,
    )
    return subscription_id
end

function drop_socket_subscriptions!(state::GatewayState, ws)
    filter!((_, subscription) -> subscription.socket !== ws, state.canvas_subscriptions)
    filter!((_, subscription) -> subscription.socket !== ws, state.dashboard_subscriptions)
    return nothing
end

function send_notification_safely!(socket, notification::AbstractString)
    try
        HTTP.WebSockets.send(socket, notification)
        return true
    catch
        return false
    end
end

function broadcast_canvas_notifications!(state::GatewayState, workflow_id::AbstractString, notifications::Vector{String})
    stale_ids = String[]
    for (subscription_id, subscription) in state.canvas_subscriptions
        subscription.workflow_id == workflow_id || continue
        delivered = true
        for notification in notifications
            delivered = send_notification_safely!(subscription.socket, notification) && delivered
        end
        delivered || push!(stale_ids, subscription_id)
    end
    for subscription_id in stale_ids
        delete!(state.canvas_subscriptions, subscription_id)
    end
    return nothing
end

function broadcast_dashboard_notifications!(state::GatewayState, dashboard_id::AbstractString, notifications::Vector{String})
    stale_ids = String[]
    for (subscription_id, subscription) in state.dashboard_subscriptions
        subscription.dashboard_id == dashboard_id || continue
        delivered = true
        for notification in notifications
            delivered = send_notification_safely!(subscription.socket, notification) && delivered
        end
        delivered || push!(stale_ids, subscription_id)
    end
    for subscription_id in stale_ids
        delete!(state.dashboard_subscriptions, subscription_id)
    end
    return nothing
end

function realtime_method_result!(state::GatewayState, method::AbstractString, params::Dict{String,Any}, ws = nothing)
    if method == "canvas.subscribe"
        haskey(params, "workflowId") || error("missing workflowId")
        workflow_id = String(params["workflowId"])
        subscription_id = "canvas-" * string(uuid4())
        ws === nothing || register_canvas_subscription!(state, subscription_id, workflow_id, ws)
        notifications = String[
            jsonrpc_notification(
                "workflow.state.changed",
                merge(Dict("subscriptionId" => subscription_id), workflow_state_changed_payload(state, workflow_id)),
            ),
        ]
        for payload in node_state_changed_payloads(state, workflow_id)
            push!(
                notifications,
                jsonrpc_notification(
                    "node.state.changed",
                    merge(Dict("subscriptionId" => subscription_id), payload),
                ),
            )
        end
        latest_execution = latest_execution_for_workflow(state, workflow_id)
        if latest_execution !== nothing
            push!(
                notifications,
                jsonrpc_notification(
                    "execution.state.changed",
                    merge(Dict("subscriptionId" => subscription_id), execution_state_changed_payload(latest_execution)),
                ),
            )
        end
        return Dict("subscriptionId" => subscription_id), notifications
    elseif method == "dashboard.subscribe"
        haskey(params, "dashboardId") || error("missing dashboardId")
        dashboard_id = String(params["dashboardId"])
        outlet_ids = get(params, "outletIds", Any[])
        subscription_id = "dashboard-" * string(uuid4())
        ws === nothing || register_dashboard_subscription!(state, subscription_id, dashboard_id, outlet_ids, ws)
        notifications = String[
            jsonrpc_notification(
                "dashboard.outlet.updated",
                merge(
                    Dict("subscriptionId" => subscription_id),
                    dashboard_outlet_updated_payload(state, dashboard_id, outlet_ids),
                ),
            ),
        ]
        return Dict("subscriptionId" => subscription_id), notifications
    elseif method == "workflow.execute"
        haskey(params, "workflowId") || error("missing workflowId")
        workflow_id = String(params["workflowId"])
        flow_variable_values = haskey(params, "flowVariables") ? normalized_string_dict(params["flowVariables"]) : Dict{String,Any}()
        execution_mode_override = haskey(params, "executionMode") ? String(params["executionMode"]) : nothing
        execution = JSON3.read(
            execution_accept_response(
                state,
                workflow_id;
                flow_variable_values = flow_variable_values,
                execution_mode_override = execution_mode_override,
            ),
            Dict{String,Any},
        )
        return Dict("jobId" => String(execution["executionId"]), "status" => "accepted"), String[]
    elseif method == "workflow.pause"
        haskey(params, "workflowId") || error("missing workflowId")
        workflow_id = String(params["workflowId"])
        execution = set_stream_lifecycle_response!(
            state,
            workflow_id,
            "paused";
            message = "Streaming execution paused",
        )
        return Dict("jobId" => execution.execution_id, "status" => "paused"), String[]
    elseif method == "workflow.resume"
        haskey(params, "workflowId") || error("missing workflowId")
        workflow_id = String(params["workflowId"])
        execution = set_stream_lifecycle_response!(
            state,
            workflow_id,
            "active";
            message = "Streaming execution resumed",
        )
        return Dict("jobId" => execution.execution_id, "status" => "active"), String[]
    elseif method == "workflow.stop"
        haskey(params, "workflowId") || error("missing workflowId")
        workflow_id = String(params["workflowId"])
        execution = stop_stream_execution_response!(state, workflow_id)
        return Dict("jobId" => execution.execution_id, "status" => "stopped"), String[]
    end

    error("method not found: $(method)")
end

function handle_realtime_request!(state::GatewayState, raw_message, ws = nothing)
    request_id = nothing
    try
        request = copy(JSON3.read(String(raw_message), Dict{String,Any}))
        version = get(request, "jsonrpc", nothing)
        version == "2.0" || return jsonrpc_error(get(request, "id", nothing), -32600, "invalid request"), String[]
        haskey(request, "method") || error("missing method")
        method = String(request["method"])
        params = haskey(request, "params") ? Dict{String,Any}(String(key) => value for (key, value) in pairs(request["params"])) : Dict{String,Any}()
        request_id = get(request, "id", nothing)
        result, notifications = realtime_method_result!(state, method, params, ws)
        return jsonrpc_success(request_id, result), notifications
    catch err
        message = sprint(showerror, err)
        if startswith(message, "method not found")
            return jsonrpc_error(request_id, -32601, message), String[]
        elseif startswith(message, "missing ")
            return jsonrpc_error(request_id, -32602, message), String[]
        end
        return jsonrpc_error(request_id, -32000, message), String[]
    end
end

function handle_realtime_socket!(state::GatewayState, ws)
    try
        for message in ws
            response, notifications = handle_realtime_request!(state, message, ws)
            HTTP.WebSockets.send(ws, response)
            for notification in notifications
                HTTP.WebSockets.send(ws, notification)
            end
        end
    finally
        drop_socket_subscriptions!(state, ws)
    end
    return nothing
end

function gateway_stream_handler(state::GatewayState)
    rest_handler = HTTP.Handlers.streamhandler(request -> route_request(state, request))

    return function(http::HTTP.Streams.Stream)
        request = http.message
        path = HTTP.URI(String(request.target)).path
        if path == "/api/v1/realtime" && HTTP.WebSockets.isupgrade(request)
            return HTTP.WebSockets.upgrade(http) do ws
                handle_realtime_socket!(state, ws)
            end
        end
        return rest_handler(http)
    end
end

function route_request(state::GatewayState, request::HTTP.Request)
    method = String(request.method)
    path = HTTP.URI(String(request.target)).path
    segments = split(path, '/'; keepempty = false)

    try
        method == "OPTIONS" && return empty_response(204)
        method == "GET" && segments == ["health"] && return json_response(200, healthcheck(state))
        method == "GET" && segments == ["api", "v1", "workflows"] && return json_response(200, list_workflows_response(state))
        method == "GET" && segments == ["api", "v1", "executions"] && return json_response(200, execution_list_response(state))
        method == "POST" && segments == ["api", "v1", "workflows"] && begin
            body = parse_request_body(request)
            return json_response(201, create_workflow_response_from_body!(state, body))
        end
        method == "POST" && segments == ["api", "v1", "workflows", "import"] && begin
            body = parse_request_body(request)
            haskey(body, "sourcePath") || return error_response(400, "missing sourcePath")
            return json_response(201, import_workflow_response!(state; source_path = String(body["sourcePath"])))
        end
        method == "GET" && length(segments) == 4 && segments[1:3] == ["api", "v1", "workflows"] && begin
            return json_response(200, get_workflow_response(state, segments[4]))
        end
        method == "PUT" && length(segments) == 4 && segments[1:3] == ["api", "v1", "workflows"] && begin
            body = parse_request_body(request)
            return json_response(200, update_workflow_response_from_body!(state, segments[4], body))
        end
        method == "POST" && length(segments) == 5 && segments[1:3] == ["api", "v1", "workflows"] && segments[5] == "execute" && begin
            body = parse_request_body(request)
            flow_variable_values = haskey(body, "flowVariables") ? normalized_string_dict(body["flowVariables"]) : Dict{String,Any}()
            execution_mode_override = haskey(body, "executionMode") ? String(body["executionMode"]) : nothing
            return json_response(
                202,
                execution_accept_response(
                    state,
                    segments[4];
                    flow_variable_values = flow_variable_values,
                    execution_mode_override = execution_mode_override,
                ),
            )
        end
        method == "GET" && length(segments) == 4 && segments[1:3] == ["api", "v1", "executions"] && begin
            return json_response(200, execution_detail_response(state, segments[4]))
        end
        method == "POST" && length(segments) == 5 && segments[1:3] == ["api", "v1", "executions"] && segments[5] == "status" && begin
            body = parse_request_body(request)
            haskey(body, "status") || return error_response(400, "missing status")
            message = haskey(body, "message") ? String(body["message"]) : nothing
            metadata = if haskey(body, "metadata")
                Dict{String,Any}(String(key) => value for (key, value) in pairs(body["metadata"]))
            else
                Dict{String,Any}()
            end
            return json_response(
                200,
                transition_execution_response!(
                    state,
                    segments[4];
                    status = String(body["status"]),
                    message = message,
                    metadata = metadata,
                ),
            )
        end
        method == "GET" && segments == ["api", "v1", "checkpoints"] && return json_response(200, checkpoint_list_response(state))
        method == "POST" && segments == ["api", "v1", "checkpoints"] && begin
            body = parse_request_body(request)
            haskey(body, "tag") || return error_response(400, "missing tag")
            haskey(body, "summary") || return error_response(400, "missing summary")
            return json_response(
                201,
                create_checkpoint_response!(state; tag = String(body["tag"]), summary = String(body["summary"])),
            )
        end
        return error_response(404, "route not found")
    catch err
        return error_response(500, sprint(showerror, err))
    end
end

function serve_gateway(state::GatewayState; host::AbstractString = "127.0.0.1", port::Integer = 8088)
    return HTTP.serve(gateway_stream_handler(state), host, port; verbose = false, stream = true)
end

end
