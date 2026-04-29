module JuliaFlowApiGateway

include(joinpath(@__DIR__, "JuliaFlowGatewayRepository.jl"))
include(joinpath(@__DIR__, "..", "..", "worker-service", "src", "JuliaFlowWorkerService.jl"))

using .JuliaFlowGatewayRepository
using .JuliaFlowWorkerService
using Dates
using HTTP
using JSON3
using UUIDs

export GatewayCheckpoint,
    GatewayExecution,
    GatewayState,
    load_state,
    reload_state!,
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
    sync_external_execution_updates!,
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
    hub_extensions::Dict{String,JuliaFlowGatewayRepository.HubExtensionRecord} = Dict{String,JuliaFlowGatewayRepository.HubExtensionRecord}()
    published_dashboards::Dict{String,JuliaFlowGatewayRepository.PublishedDashboardRecord} = Dict{String,JuliaFlowGatewayRepository.PublishedDashboardRecord}()
    worker_service::JuliaFlowWorkerService.WorkerServiceState = JuliaFlowWorkerService.WorkerServiceState()
    canvas_subscriptions::Dict{String,Any} = Dict{String,Any}()
    dashboard_subscriptions::Dict{String,Any} = Dict{String,Any}()
    processed_event_ids::Set{String} = Set{String}()
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
    state.hub_extensions = Dict(item.extension_id => item for item in JuliaFlowGatewayRepository.load_hub_extensions(state.repository))
    state.published_dashboards = Dict(item.dashboard_id => item for item in JuliaFlowGatewayRepository.load_published_dashboards(state.repository))
    sync_worker_service!(state.worker_service, state.executions)
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
    workflow = save_workflow!(state.repository, workflow_toml; producer = "api-gateway")
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
                if haskey(chart, "panel")
                    panel = normalized_string_dict(chart["panel"])
                    payload["panel"] = Dict(
                        "x" => Int(panel["x"]),
                        "y" => Int(panel["y"]),
                        "w" => Int(panel["w"]),
                        "h" => Int(panel["h"]),
                    )
                end
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
    event_stats = health_event_stats(state)
    execution_stats = health_execution_stats(state)
    queued_gpu_executions = count(
        execution -> execution.status == "queued" && JuliaFlowWorkerService.has_gpu_dispatch(execution),
        state.executions,
    )
    gpu_registry = JuliaFlowWorkerService.gpu_registry_health()
    return JSON3.write(
        Dict(
            "service" => "api-gateway",
            "status" => "ok",
            "repositoryBackend" => String(repository_backend(state)),
            "storeRoot" => store_id,
            "workflowCount" => length(state.workflows),
            "checkpointCount" => length(state.checkpoints),
            "executionCount" => length(state.executions),
            "realtimeTransport" => "jsonrpc_websocket",
            "eventBackboneMode" => event_backbone_mode(),
            "eventConsumerPollMs" => event_consumer_poll_ms(),
            "streamWorkerMode" => stream_worker_mode(),
            "gpuWorkerMode" => gpu_worker_mode(),
            "gpuRegistryDeviceCount" => gpu_registry["device_count"],
            "gpuFallbackAvailable" => gpu_registry["fallback_available"],
            "authMode" => gateway_auth_mode(),
            "authDevFallback" => dev_auth_token() === nothing && gateway_auth_mode() == "dev_token",
            "eventLogSize" => event_stats.event_log_size,
            "latestEventSequence" => event_stats.latest_event_sequence,
            "gatewayConsumerCursor" => event_stats.gateway_consumer_cursor,
            "gatewayConsumerLag" => event_stats.gateway_consumer_lag,
            "eventConsumerCatchupPercent" => event_stats.gateway_consumer_catchup_percent,
            "activeStreamExecutions" => length(state.worker_service.stream_execution_ids),
            "queuedGpuExecutions" => queued_gpu_executions,
            "queuedStreamExecutions" => execution_stats.queued_stream_executions,
            "activeGpuExecutions" => execution_stats.active_gpu_executions,
            "gpuWorkerOwnedExecutions" => execution_stats.gpu_worker_owned_executions,
            "queuedExecutionsTotal" => execution_stats.queued_executions_total,
            "runningExecutionsTotal" => execution_stats.running_executions_total,
        ),
    )
end

function event_consumer_poll_ms()
    return parse(Int, get(ENV, "JULIAFLOW_EVENT_CONSUMER_POLL_MS", "250"))
end

function event_backbone_mode()
    mode = lowercase(strip(get(ENV, "JULIAFLOW_EVENT_BACKBONE_MODE", "dual_write")))
    mode in ("dual_write", "consume") || error("unsupported JULIAFLOW_EVENT_BACKBONE_MODE: $(mode)")
    return mode
end

function event_backbone_enabled()
    return true
end

function gateway_event_consumer_id()
    return get(ENV, "JULIAFLOW_GATEWAY_CONSUMER_ID", "gateway-default")
end

function stream_worker_mode()
    mode = lowercase(strip(get(ENV, "JULIAFLOW_STREAM_WORKER_MODE", "inline")))
    mode in ("inline", "process") || error("unsupported JULIAFLOW_STREAM_WORKER_MODE: $(mode)")
    return mode
end

function gpu_worker_mode()
    mode = lowercase(strip(get(ENV, "JULIAFLOW_GPU_WORKER_MODE", "process")))
    mode in ("process", "disabled") || error("unsupported JULIAFLOW_GPU_WORKER_MODE: $(mode)")
    return mode
end

function workspace_dashboard_access_token()
    token = strip(get(ENV, "JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN", ""))
    return isempty(token) ? nothing : token
end

const GATEWAY_ROLE_PERMISSIONS = Dict(
    "owner" => Set([
        "workflow:read",
        "workflow:write",
        "workflow:execute",
        "execution:read",
        "execution:write",
        "checkpoint:read",
        "checkpoint:write",
        "dashboard:read",
        "dashboard:publish",
        "hub:read",
        "hub:publish",
        "hub:install",
    ]),
    "editor" => Set([
        "workflow:read",
        "workflow:write",
        "workflow:execute",
        "execution:read",
        "checkpoint:read",
        "dashboard:read",
        "dashboard:publish",
        "hub:read",
        "hub:publish",
    ]),
    "viewer" => Set([
        "workflow:read",
        "execution:read",
        "checkpoint:read",
        "dashboard:read",
        "hub:read",
    ]),
)

function gateway_auth_mode()
    mode = lowercase(strip(get(ENV, "JULIAFLOW_AUTH_MODE", "dev_token")))
    mode in ("disabled", "dev_token", "required") || error("unsupported JULIAFLOW_AUTH_MODE: $(mode)")
    return mode
end

function dev_auth_token()
    token = strip(get(ENV, "JULIAFLOW_DEV_AUTH_TOKEN", ""))
    return isempty(token) ? nothing : token
end

function request_header(request::HTTP.Request, header_name::AbstractString)
    needle = lowercase(String(header_name))
    for (key, value) in request.headers
        lowercase(String(key)) == needle || continue
        return String(value)
    end
    return nothing
end

function auth_role_from_request(request::HTTP.Request)
    raw_role = request_header(request, "X-JuliaFlow-Workspace-Role")
    role = raw_role === nothing ? "owner" : lowercase(strip(String(raw_role)))
    haskey(GATEWAY_ROLE_PERMISSIONS, role) || error("unsupported workspace role: $(role)")
    return role
end

function auth_context_payload(request::HTTP.Request)
    mode = gateway_auth_mode()
    role = auth_role_from_request(request)
    if mode == "disabled"
        return Dict(
            "principalId" => "system:auth-disabled",
            "workspaceId" => "local-dev",
            "role" => "owner",
            "mode" => mode,
            "permissions" => sort(collect(GATEWAY_ROLE_PERMISSIONS["owner"])),
        )
    end

    expected_token = dev_auth_token()
    if expected_token === nothing
        mode == "required" && error("auth token is required but JULIAFLOW_DEV_AUTH_TOKEN is not configured")
        return Dict(
            "principalId" => "dev:local-user",
            "workspaceId" => "local-dev",
            "role" => "owner",
            "mode" => "dev_fallback",
            "permissions" => sort(collect(GATEWAY_ROLE_PERMISSIONS["owner"])),
        )
    end

    provided_token = bearer_token_from_request(request)
    provided_token == expected_token || error("invalid auth token")
    principal = request_header(request, "X-JuliaFlow-Principal")
    principal_id = principal === nothing || isempty(strip(principal)) ? "dev:token-user" : strip(principal)
    workspace = request_header(request, "X-JuliaFlow-Workspace")
    workspace_id = workspace === nothing || isempty(strip(workspace)) ? "local-dev" : strip(workspace)
    return Dict(
        "principalId" => principal_id,
        "workspaceId" => workspace_id,
        "role" => role,
        "mode" => mode,
        "permissions" => sort(collect(GATEWAY_ROLE_PERMISSIONS[role])),
    )
end

function require_permission!(request::HTTP.Request, permission::AbstractString)
    context = auth_context_payload(request)
    role = String(context["role"])
    permission in GATEWAY_ROLE_PERMISSIONS[role] || error("permission denied: $(permission)")
    return context
end

function bearer_token_from_request(request::HTTP.Request)
    for header in request.headers
        key = lowercase(String(header.first))
        key == "authorization" || continue
        value = strip(String(header.second))
        startswith(lowercase(value), "bearer ") || continue
        ncodeunits(value) > 7 || continue
        token = strip(value[8:end])
        return isempty(token) ? nothing : token
    end
    return nothing
end

function health_event_stats(state::GatewayState)
    events = JuliaFlowGatewayRepository.list_events_after(state.repository, 0)
    event_log_size = length(events)
    latest_sequence = event_log_size == 0 ? 0 : events[end].sequence
    gateway_consumer_cursor = JuliaFlowGatewayRepository.load_consumer_cursor(
        state.repository,
        gateway_event_consumer_id(),
    )
    gateway_consumer_lag = max(latest_sequence - gateway_consumer_cursor, 0)
    gateway_consumer_catchup_percent =
        latest_sequence == 0 ? 100 : Int(clamp(round((gateway_consumer_cursor / latest_sequence) * 100), 0, 100))
    return (
        event_log_size = event_log_size,
        latest_event_sequence = latest_sequence,
        gateway_consumer_cursor = gateway_consumer_cursor,
        gateway_consumer_lag = gateway_consumer_lag,
        gateway_consumer_catchup_percent = gateway_consumer_catchup_percent,
    )
end

function health_execution_stats(state::GatewayState)
    queued_stream_executions = count(
        execution -> execution.status == "queued" && get(execution.metadata, "stream_lifecycle_status", nothing) == "starting",
        state.executions,
    )
    active_gpu_executions = count(
        execution -> execution.status == "running" && JuliaFlowWorkerService.has_gpu_dispatch(execution),
        state.executions,
    )
    queued_executions_total = count(execution -> execution.status == "queued", state.executions)
    running_executions_total = count(execution -> execution.status == "running", state.executions)
    return (
        queued_stream_executions = queued_stream_executions,
        active_gpu_executions = active_gpu_executions,
        gpu_worker_owned_executions = length(state.worker_service.gpu_execution_ids),
        queued_executions_total = queued_executions_total,
        running_executions_total = running_executions_total,
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

function activate_gpu_execution!(state::GatewayState, execution::GatewayExecution)
    updated_execution = JuliaFlowWorkerService.activate_gpu_execution!(
        state.worker_service,
        state.executions,
        execution.execution_id;
        execution_record = execution_record,
        transition_execution_record = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
        materialize_execution = materialize_execution,
    )
    save_execution!(state.repository, updated_execution; producer = "api-gateway")
    event_backbone_enabled() || broadcast_execution_update!(state, updated_execution.workflow_id, updated_execution)
    return updated_execution
end

function queue_stream_execution!(state::GatewayState, execution::GatewayExecution)
    updated_execution = JuliaFlowWorkerService.queue_stream_execution!(
        state.worker_service,
        state.workflows,
        state.executions,
        execution.execution_id;
        execution_record = execution_record,
        transition_execution_record = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
        materialize_execution = materialize_execution,
    )
    save_execution!(state.repository, updated_execution; producer = "api-gateway")
    event_backbone_enabled() || broadcast_execution_update!(state, updated_execution.workflow_id, updated_execution)
    return updated_execution
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
    save_execution!(state.repository, execution; producer = "api-gateway")
    push!(state.executions, execution)
    workflow = state.workflows[workflow_id]
    if JuliaFlowGatewayRepository.JuliaFlowExecutionService.is_stream_workflow(workflow)
        if stream_worker_mode() == "process"
            execution = queue_stream_execution!(state, execution)
        else
            execution = activate_stream_execution!(state, execution)
        end
        return JSON3.write(execution_payload(execution))
    elseif should_dispatch_gpu_execution(workflow, execution)
        execution = activate_gpu_execution!(state, execution)
        return JSON3.write(execution_payload(execution))
    end
    event_backbone_enabled() || broadcast_execution_update!(state, workflow_id, execution)
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

function execution_sync_fingerprint(execution::GatewayExecution)
    return (
        execution.updated_at,
        execution.status,
        get(execution.metadata, "stream_lifecycle_status", nothing),
        get(execution.metadata, "stream_processed_offset", nothing),
        get(execution.metadata, "stream_consumer_lag", nothing),
        get(execution.metadata, "stream_batch_count", nothing),
        get(execution.metadata, "worker_id", nothing),
        length(execution.status_history),
    )
end

function sync_external_execution_updates!(state::GatewayState)
    if event_backbone_enabled()
        events = consume_gateway_events!(state)
        changed_executions = GatewayExecution[]
        for event in events
            event.event_type == "execution.changed" || continue
            push!(changed_executions, JuliaFlowGatewayRepository.gateway_execution(event.payload))
        end
        return changed_executions
    end

    latest_executions = load_executions(state.repository)
    current_by_id = Dict(execution.execution_id => execution for execution in state.executions)
    changed_executions = GatewayExecution[]

    for execution in latest_executions
        current = get(current_by_id, execution.execution_id, nothing)
        current === nothing && push!(changed_executions, execution)
        current === nothing || execution_sync_fingerprint(current) == execution_sync_fingerprint(execution) || push!(changed_executions, execution)
    end

    state.executions = latest_executions
    sync_worker_service!(state.worker_service, state.executions)

    for execution in changed_executions
        broadcast_execution_update!(state, execution.workflow_id, execution)
        if get(execution.metadata, "stream_lifecycle_status", nothing) == "stopped" && execution.status == "completed"
            broadcast_stream_checkpoint!(state, execution.workflow_id, execution)
        end
    end

    return changed_executions
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
    save_execution!(state.repository, execution; producer = "api-gateway")
    event_backbone_enabled() || broadcast_execution_update!(state, execution.workflow_id, execution)
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

function current_contract_version()
    return "0.1.0"
end

function normalized_version_tuple(version::AbstractString)
    raw_parts = split(replace(String(version), r"[^0-9]+" => "."), '.')
    parts = Int[]
    for part in raw_parts
        isempty(part) && continue
        value = tryparse(Int, part)
        push!(parts, value === nothing ? 0 : value)
    end
    while length(parts) < 4
        push!(parts, 0)
    end
    return tuple(parts[1], parts[2], parts[3], parts[4])
end

function version_is_newer(candidate::AbstractString, installed::AbstractString)
    return normalized_version_tuple(candidate) > normalized_version_tuple(installed)
end

function signature_matches_partner_identity(signature::AbstractString, identity_suffix::AbstractString)
    isempty(identity_suffix) && return false
    marker = ":" * String(identity_suffix) * ":"
    return occursin(marker, String(signature))
end

function evaluate_hub_extension_trust(extension::JuliaFlowGatewayRepository.HubExtensionRecord)
    warnings = String[]
    blockers = String[]
    trusted = false
    level = "untrusted"
    signature = extension.signature === nothing ? "" : strip(extension.signature)
    release_notes_ref = extension.release_notes_ref === nothing ? "" : strip(extension.release_notes_ref)

    if extension.publisher == "official"
        if extension.publisher_identity == "official:juliaflow"
            trusted = true
            level = "official"
        else
            push!(blockers, "Official extension publisher identity must be registered with gateway")
        end
    elseif extension.publisher == "partner"
        identity_suffix = length(extension.publisher_identity) > 8 ? strip(extension.publisher_identity[9:end]) : ""
        if !startswith(extension.publisher_identity, "partner:")
            push!(blockers, "Partner extension must use partner-scoped publisher identity")
        elseif isempty(identity_suffix)
            push!(blockers, "Partner extension publisher identity suffix must not be empty")
        end
        if !startswith(extension.package_ref, "hub://")
            push!(blockers, "Partner extension package reference must use hub:// scheme")
        end
        if isempty(signature)
            push!(blockers, "Partner extension must provide signature")
        elseif !startswith(signature, "sig:")
            push!(blockers, "Partner extension signature must use sig: prefix")
        elseif !signature_matches_partner_identity(signature, identity_suffix)
            push!(blockers, "Partner extension signature must include publisher identity suffix")
        end
        if isempty(release_notes_ref)
            push!(blockers, "Partner extension must provide release notes reference")
        elseif !startswith(lowercase(release_notes_ref), "https://")
            push!(blockers, "Partner extension release notes reference must be https URL")
        end
        if isempty(blockers)
            trusted = true
            level = "partner_verified"
        end
    else
        push!(blockers, "Unsupported publisher type $(extension.publisher)")
    end

    return Dict(
        "trusted" => trusted,
        "level" => level,
        "warnings" => warnings,
        "blockers" => blockers,
        "evaluatedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
    )
end

function build_hub_upgrade_info(latest_version::AbstractString, installed_version)
    upgrade_available = installed_version !== nothing && version_is_newer(latest_version, String(installed_version))
    payload = Dict{String,Any}(
        "upgradeAvailable" => upgrade_available,
        "latestVersion" => String(latest_version),
        "evaluatedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
    )
    installed_version === nothing || (payload["installedVersion"] = String(installed_version))
    upgrade_available && (payload["targetVersion"] = String(latest_version))
    return payload
end

function evaluate_hub_extension_compatibility(state::GatewayState, extension::JuliaFlowGatewayRepository.HubExtensionRecord)
    blockers = String[]
    warnings = String[]
    current_checkpoint = latest_checkpoint_tag(state)

    supported_checkpoints = isempty(extension.supported_checkpoints) ? extension.compatible_checkpoints : extension.supported_checkpoints
    current_checkpoint in supported_checkpoints || push!(blockers, "Extension not validated for current checkpoint $(current_checkpoint)")
    extension.required_contract_version == current_contract_version() ||
        push!(blockers, "Requires contract version $(extension.required_contract_version), gateway provides $(current_contract_version())")
    startswith(lowercase(extension.engine_compatibility), "alpha") || push!(warnings, "Engine compatibility range $(extension.engine_compatibility) not yet enforced beyond Alpha")

    return Dict(
        "compatible" => isempty(blockers),
        "warnings" => warnings,
        "blockers" => blockers,
        "evaluatedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
    )
end

function materialize_hub_extension(
    current::JuliaFlowGatewayRepository.HubExtensionRecord;
    install_state::AbstractString = current.install_state,
    installed_at = current.installed_at,
    enabled_at = current.enabled_at,
    compatibility = current.compatibility,
    trust = current.trust,
    upgrade = current.upgrade,
    installed_version = current.installed_version,
)
    return JuliaFlowGatewayRepository.HubExtensionRecord(
        extension_id = current.extension_id,
        name = current.name,
        version = current.version,
        publisher = current.publisher,
        summary = current.summary,
        package_ref = current.package_ref,
        tags = current.tags,
        engine_compatibility = current.engine_compatibility,
        required_contract_version = current.required_contract_version,
        supported_checkpoints = current.supported_checkpoints,
        compatible_checkpoints = current.compatible_checkpoints,
        dependencies = current.dependencies,
        publisher_identity = current.publisher_identity,
        signature = current.signature,
        release_notes_ref = current.release_notes_ref,
        install_state = String(install_state),
        compatibility = compatibility,
        trust = trust,
        upgrade = upgrade,
        installed_version = installed_version,
        installed_at = installed_at,
        enabled_at = enabled_at,
    )
end

function list_hub_extensions_response(state::GatewayState)
    extensions = sort(collect(values(state.hub_extensions)); by = item -> item.extension_id)
    return JSON3.write(Dict("items" => [JuliaFlowGatewayRepository.hub_extension_payload(item) for item in extensions]))
end

function list_published_dashboards_response(state::GatewayState, workflow_id::AbstractString)
    dashboards = sort(
        [item for item in values(state.published_dashboards) if item.workflow_id == workflow_id];
        by = item -> item.dashboard_id,
    )
    return JSON3.write(Dict("items" => [JuliaFlowGatewayRepository.published_dashboard_payload(item) for item in dashboards]))
end

function register_hub_extension_response!(state::GatewayState, request_body::AbstractDict{<:Any,<:Any})
    haskey(request_body, "manifest") || error("missing manifest")
    manifest = normalized_string_dict(request_body["manifest"])
    required_fields = ("extensionId", "name", "version", "publisher", "summary", "packageRef")
    for field in required_fields
        haskey(manifest, field) || error("manifest missing $(field)")
    end

    candidate = JuliaFlowGatewayRepository.HubExtensionRecord(
        extension_id = String(manifest["extensionId"]),
        name = String(manifest["name"]),
        version = String(manifest["version"]),
        publisher = String(manifest["publisher"]),
        summary = String(manifest["summary"]),
        package_ref = String(manifest["packageRef"]),
        tags = [String(entry) for entry in get(manifest, "tags", Any[])],
        engine_compatibility = String(get(manifest, "engineCompatibility", "alpha-core")),
        required_contract_version = String(get(manifest, "requiredContractVersion", current_contract_version())),
        supported_checkpoints = [String(entry) for entry in get(manifest, "supportedCheckpoints", Any[])],
        compatible_checkpoints = [String(entry) for entry in get(manifest, "compatibleCheckpoints", get(manifest, "supportedCheckpoints", Any[]))],
        dependencies = [String(entry) for entry in get(manifest, "dependencies", Any[])],
        publisher_identity = String(get(manifest, "publisherIdentity", String(manifest["publisher"]))),
        signature = haskey(manifest, "signature") ? String(manifest["signature"]) : nothing,
        release_notes_ref = haskey(manifest, "releaseNotesRef") ? String(manifest["releaseNotesRef"]) : nothing,
    )
    existing = get(state.hub_extensions, candidate.extension_id, nothing)
    compatibility = evaluate_hub_extension_compatibility(state, candidate)
    trust = evaluate_hub_extension_trust(candidate)
    installed_version = if existing === nothing
        nothing
    elseif existing.installed_version !== nothing
        existing.installed_version
    elseif existing.install_state in ("installed", "enabled", "disabled", "upgrade_available")
        existing.version
    else
        nothing
    end
    upgrade = build_hub_upgrade_info(candidate.version, installed_version)
    install_state = if !Bool(compatibility["compatible"])
        "incompatible"
    elseif Bool(get(upgrade, "upgradeAvailable", false))
        "upgrade_available"
    elseif existing !== nothing && existing.install_state in ("enabled", "disabled", "installed")
        existing.install_state
    else
        "available"
    end
    updated = materialize_hub_extension(
        candidate;
        install_state = install_state,
        compatibility = compatibility,
        trust = trust,
        upgrade = upgrade,
        installed_version = installed_version,
        installed_at = existing === nothing ? nothing : existing.installed_at,
        enabled_at = existing === nothing ? nothing : existing.enabled_at,
    )
    state.hub_extensions[updated.extension_id] = updated
    JuliaFlowGatewayRepository.save_hub_extension!(state.repository, updated; producer = "api-gateway")
    return JSON3.write(Dict("status" => "ok", "extension" => JuliaFlowGatewayRepository.hub_extension_payload(updated)))
end

function dashboard_chart_payload(chart)
    payload = Dict{String,Any}(
        "chartId" => String(get(chart, "id", get(chart, "chartId", ""))),
        "title" => String(chart["title"]),
        "family" => String(chart["family"]),
    )
    haskey(chart, "x_field") && chart["x_field"] !== nothing && (payload["xField"] = String(chart["x_field"]))
    haskey(chart, "xField") && chart["xField"] !== nothing && (payload["xField"] = String(chart["xField"]))
    haskey(chart, "y_field") && chart["y_field"] !== nothing && (payload["yField"] = String(chart["y_field"]))
    haskey(chart, "yField") && chart["yField"] !== nothing && (payload["yField"] = String(chart["yField"]))
    haskey(chart, "series_field") && chart["series_field"] !== nothing && (payload["seriesField"] = String(chart["series_field"]))
    haskey(chart, "seriesField") && chart["seriesField"] !== nothing && (payload["seriesField"] = String(chart["seriesField"]))
    if haskey(chart, "panel") && chart["panel"] !== nothing
        panel = chart["panel"]
        payload["panel"] = Dict(
            "x" => Int(panel["x"]),
            "y" => Int(panel["y"]),
            "w" => Int(panel["w"]),
            "h" => Int(panel["h"]),
        )
    end
    return payload
end

function dashboard_row_dict(row)
    row isa AbstractDict || error("dashboard dataset rows must be objects")
    return Dict{String,Any}(String(key) => value for (key, value) in pairs(row))
end

function dashboard_dataset_rows(raw_rows)
    raw_rows isa AbstractVector || error("dashboard dataset rows must be a vector")
    return [dashboard_row_dict(row) for row in raw_rows]
end

function bi_outlet_value(outlet::AbstractDict, keys...; default = nothing)
    for key in keys
        haskey(outlet, key) && return outlet[key]
    end
    return default
end

function published_dashboard_datasets(workflow, draft)
    datasets = Dict{String,Vector{Dict{String,Any}}}()
    dataset_key = draft.binding.dataset_key
    outlet_node_id = draft.binding.outlet_node_id
    for raw_outlet in workflow.bi_outlets
        outlet = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_outlet))
        node_id = String(bi_outlet_value(outlet, "node_id", "nodeId"; default = ""))
        isempty(node_id) || node_id == outlet_node_id || continue
        if haskey(outlet, "datasets")
            for (key, rows) in pairs(outlet["datasets"])
                datasets[String(key)] = dashboard_dataset_rows(rows)
            end
        end
        if haskey(outlet, "rows")
            datasets[dataset_key] = dashboard_dataset_rows(outlet["rows"])
        end
    end
    return datasets
end

function publish_dashboard_response!(
    state::GatewayState,
    workflow_id::AbstractString,
    dashboard_id::AbstractString;
    visibility::AbstractString = "workspace",
)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    workflow = state.workflows[workflow_id]
    dashboard = findfirst(item -> item.id == dashboard_id, workflow.dashboards)
    dashboard === nothing && error("dashboard not found: $(dashboard_id)")
    visibility in ("workspace", "public") || error("unsupported dashboard visibility: $(visibility)")
    draft = workflow.dashboards[dashboard]
    published_version = haskey(state.published_dashboards, dashboard_id) ? state.published_dashboards[dashboard_id].version + 1 : 1

    published = JuliaFlowGatewayRepository.PublishedDashboardRecord(
        dashboard_id = draft.id,
        workflow_id = workflow.id,
        name = draft.name,
        version = published_version,
        published_at = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        visibility = String(visibility),
        share_token = visibility == "public" ? replace(string(uuid4()), "-" => "")[1:12] : nothing,
        binding = Dict(
            "outletNodeId" => draft.binding.outlet_node_id,
            "datasetKey" => draft.binding.dataset_key,
            "refreshMode" => draft.binding.refresh_mode,
        ),
        charts = [dashboard_chart_payload(Dict(
            "id" => chart.id,
            "title" => chart.title,
            "family" => chart.family,
            "x_field" => chart.x_field,
            "y_field" => chart.y_field,
            "series_field" => chart.series_field,
            "panel" => chart.panel === nothing ? nothing : Dict("x" => chart.panel.x, "y" => chart.panel.y, "w" => chart.panel.w, "h" => chart.panel.h),
        )) for chart in draft.charts],
        datasets = published_dashboard_datasets(workflow, draft),
    )
    state.published_dashboards[published.dashboard_id] = published
    JuliaFlowGatewayRepository.save_published_dashboard!(state.repository, published; producer = "api-gateway")
    return JSON3.write(Dict("status" => "ok", "dashboard" => JuliaFlowGatewayRepository.published_dashboard_payload(published)))
end

function authorized_published_dashboard(
    state::GatewayState,
    dashboard_id::AbstractString;
    share_token::Union{Nothing,AbstractString} = nothing,
    workspace_token::Union{Nothing,AbstractString} = nothing,
    workspace_bearer_token::Union{Nothing,AbstractString} = nothing,
)
    haskey(state.published_dashboards, dashboard_id) || error("published dashboard not found: $(dashboard_id)")
    dashboard = state.published_dashboards[dashboard_id]
    if dashboard.visibility == "workspace"
        expected_workspace_token = workspace_dashboard_access_token()
        expected_workspace_token === nothing && error("workspace dashboard access token is not configured")
        provided_workspace_token = workspace_token === nothing ? "" : strip(String(workspace_token))
        provided_workspace_bearer_token = workspace_bearer_token === nothing ? "" : strip(String(workspace_bearer_token))
        has_token_access = provided_workspace_token == expected_workspace_token
        has_bearer_access = provided_workspace_bearer_token == expected_workspace_token
        (has_token_access || has_bearer_access) || error("invalid workspace access token")
        return dashboard
    end
    expected_share_token = dashboard.share_token === nothing ? "" : strip(String(dashboard.share_token))
    provided_share_token = share_token === nothing ? "" : strip(String(share_token))
    isempty(expected_share_token) && error("published dashboard missing share token")
    provided_share_token == expected_share_token || error("invalid share token")
    return dashboard
end

function get_published_dashboard_response(
    state::GatewayState,
    dashboard_id::AbstractString;
    share_token::Union{Nothing,AbstractString} = nothing,
    workspace_token::Union{Nothing,AbstractString} = nothing,
    workspace_bearer_token::Union{Nothing,AbstractString} = nothing,
)
    dashboard = authorized_published_dashboard(
        state,
        dashboard_id;
        share_token = share_token,
        workspace_token = workspace_token,
        workspace_bearer_token = workspace_bearer_token,
    )
    return JSON3.write(JuliaFlowGatewayRepository.published_dashboard_payload(dashboard))
end

function chart_data_rows(dashboard::JuliaFlowGatewayRepository.PublishedDashboardRecord, chart::Dict{String,Any})
    family = String(chart["family"])
    x_field = String(get(chart, "xField", "bucket"))
    y_field = String(get(chart, "yField", "value"))
    dataset_key = String(dashboard.binding["datasetKey"])
    if haskey(dashboard.datasets, dataset_key)
        return [Dict{String,Any}(String(key) => value for (key, value) in pairs(row)) for row in dashboard.datasets[dataset_key]]
    end
    if family == "metric"
        return [Dict("label" => dataset_key, y_field => dashboard.version)]
    elseif family == "table"
        return [
            Dict("field" => x_field, "value" => dataset_key),
            Dict("field" => y_field, "value" => dashboard.version),
        ]
    end
    return [
        Dict(x_field => "baseline", y_field => 10),
        Dict(x_field => "current", y_field => 15 + dashboard.version),
        Dict(x_field => "target", y_field => 20),
    ]
end

function chart_data_fields(rows::Vector{Dict{String,Any}})
    field_set = Set{String}()
    for row in rows
        for key in keys(row)
            push!(field_set, String(key))
        end
    end
    return sort(collect(field_set))
end

function field_is_numeric(rows::Vector{Dict{String,Any}}, field::String)
    observed = 0
    for row in rows
        haskey(row, field) || continue
        value = row[field]
        (value === missing || value === nothing) && continue
        value isa Number || return false
        observed += 1
    end
    return observed > 0
end

function chart_semantic(chart::Dict{String,Any}, rows::Vector{Dict{String,Any}}, fields::Vector{String})
    x_field = String(get(chart, "xField", "bucket"))
    y_field = String(get(chart, "yField", "value"))
    series_field = haskey(chart, "seriesField") && chart["seriesField"] !== nothing ? String(chart["seriesField"]) : nothing
    measures = String[]
    dimensions = String[]
    for field in fields
        if field == y_field || field_is_numeric(rows, field)
            push!(measures, field)
        else
            push!(dimensions, field)
        end
    end
    ordered_dimensions = unique(dimensions)
    if x_field in fields
        ordered_dimensions = vcat([x_field], [field for field in ordered_dimensions if field != x_field])
    end
    if series_field !== nothing && series_field in fields && !(series_field in ordered_dimensions)
        push!(ordered_dimensions, series_field)
    end
    ordered_measures = unique(measures)
    if y_field in fields
        ordered_measures = vcat([y_field], [field for field in ordered_measures if field != y_field])
    end
    return Dict(
        "dimensions" => ordered_dimensions,
        "measures" => ordered_measures,
        "xField" => x_field,
        "yField" => y_field,
        "seriesField" => series_field,
        "availableDimensions" => [field for field in fields if !(field in ordered_measures)],
        "availableMeasures" => ordered_measures,
    )
end

function chart_cache_info(dashboard::JuliaFlowGatewayRepository.PublishedDashboardRecord, chart_id::AbstractString)
    refresh_mode = String(get(dashboard.binding, "refreshMode", "manual"))
    return Dict(
        "cacheKey" => "$(dashboard.dashboard_id):$(chart_id):v$(dashboard.version)",
        "sourceVersion" => dashboard.version,
        "snapshotAt" => dashboard.published_at,
        "refreshMode" => refresh_mode,
        "live" => refresh_mode == "live",
        "stale" => false,
    )
end

function csv_escape(value)
    value === nothing && return ""
    raw = string(value)
    if occursin(",", raw) || occursin("\"", raw) || occursin("\n", raw) || occursin("\r", raw)
        return "\"" * replace(raw, "\"" => "\"\"") * "\""
    end
    return raw
end

function chart_data_csv(rows::Vector{Dict{String,Any}}, fields::Vector{String})
    lines = [join([csv_escape(field) for field in fields], ",")]
    for row in rows
        push!(lines, join([csv_escape(get(row, field, "")) for field in fields], ","))
    end
    return join(lines, "\n") * "\n"
end

function published_dashboard_chart_data(
    state::GatewayState,
    dashboard_id::AbstractString,
    chart_id::AbstractString;
    share_token::Union{Nothing,AbstractString} = nothing,
    workspace_token::Union{Nothing,AbstractString} = nothing,
    workspace_bearer_token::Union{Nothing,AbstractString} = nothing,
)
    dashboard = authorized_published_dashboard(
        state,
        dashboard_id;
        share_token = share_token,
        workspace_token = workspace_token,
        workspace_bearer_token = workspace_bearer_token,
    )
    chart_index = findfirst(chart -> String(chart["chartId"]) == String(chart_id), dashboard.charts)
    chart_index === nothing && error("dashboard chart not found: $(chart_id)")
    chart = dashboard.charts[chart_index]
    rows = chart_data_rows(dashboard, chart)
    fields = chart_data_fields(rows)
    payload = Dict(
        "dashboardId" => dashboard.dashboard_id,
        "chartId" => String(chart_id),
        "datasetKey" => String(dashboard.binding["datasetKey"]),
        "family" => String(chart["family"]),
        "fields" => fields,
        "rows" => rows,
        "rowCount" => length(rows),
        "refreshedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        "semantic" => chart_semantic(chart, rows, fields),
        "cache" => chart_cache_info(dashboard, chart_id),
        "exportFormats" => ["json", "csv"],
    )
    return payload
end

function published_dashboard_chart_data_response(state::GatewayState, dashboard_id::AbstractString, chart_id::AbstractString; kwargs...)
    return JSON3.write(published_dashboard_chart_data(state, dashboard_id, chart_id; kwargs...))
end

function published_dashboard_chart_data_csv_response(state::GatewayState, dashboard_id::AbstractString, chart_id::AbstractString; kwargs...)
    payload = published_dashboard_chart_data(state, dashboard_id, chart_id; kwargs...)
    return chart_data_csv(payload["rows"], payload["fields"])
end

function install_hub_extension_response!(
    state::GatewayState,
    extension_id::AbstractString;
    action::AbstractString = "install",
)
    haskey(state.hub_extensions, extension_id) || error("hub extension not found: $(extension_id)")
    current = state.hub_extensions[extension_id]
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    action in ("install", "enable", "disable", "upgrade") || error("unsupported Hub action: $(action)")
    compatibility = evaluate_hub_extension_compatibility(state, current)
    trust = evaluate_hub_extension_trust(current)
    if action in ("enable", "upgrade") && (!Bool(compatibility["compatible"]) || !Bool(trust["trusted"]))
        blocked = materialize_hub_extension(
            current;
            install_state = "incompatible",
            compatibility = compatibility,
            trust = trust,
            upgrade = build_hub_upgrade_info(current.version, current.installed_version),
        )
        state.hub_extensions[extension_id] = blocked
        JuliaFlowGatewayRepository.save_hub_extension!(state.repository, blocked; producer = "api-gateway")
        error(join(vcat([String(entry) for entry in compatibility["blockers"]], [String(entry) for entry in trust["blockers"]]), "; "))
    end

    installed_version = current.installed_version
    next_install_state =
        action == "disable" ? "disabled" :
        action == "enable" ? "enabled" :
        action == "upgrade" ? (current.enabled_at === nothing ? "installed" : "enabled") :
        current.install_state in ("enabled", "disabled") ? current.install_state : "installed"

    if action == "install" && installed_version === nothing
        installed_version = current.version
    elseif action == "enable" && installed_version === nothing
        installed_version = current.version
    elseif action == "upgrade"
        installed_version = current.version
    end

    upgrade = build_hub_upgrade_info(current.version, installed_version)

    updated = materialize_hub_extension(
        current;
        install_state = Bool(get(upgrade, "upgradeAvailable", false)) && action != "upgrade" ? "upgrade_available" : next_install_state,
        installed_at = action == "install" && current.installed_at === nothing ? timestamp : current.installed_at,
        enabled_at = action == "enable" ? timestamp : (action == "disable" ? nothing : current.enabled_at),
        compatibility = compatibility,
        trust = trust,
        upgrade = upgrade,
        installed_version = installed_version,
    )
    state.hub_extensions[extension_id] = updated
    JuliaFlowGatewayRepository.save_hub_extension!(state.repository, updated; producer = "api-gateway")
    return JSON3.write(Dict("status" => "ok", "extension" => JuliaFlowGatewayRepository.hub_extension_payload(updated)))
end

function import_workflow_response!(state::GatewayState; source_path::AbstractString)
    workflow = persist_workflow_file!(state, source_path)
    event_backbone_enabled() || broadcast_workflow_save!(state, workflow.id)
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
    event_backbone_enabled() || broadcast_workflow_save!(state, workflow.id)
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
    event_backbone_enabled() || broadcast_workflow_save!(state, workflow.id)
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

function classify_gateway_error(err)
    message = sprint(showerror, err)

    if occursin("published dashboard not found", message)
        return 404, message
    elseif occursin("route not found", message)
        return 404, message
    elseif occursin("missing ", message)
        return 400, message
    elseif occursin("invalid share token", message)
        return 401, message
    elseif occursin("invalid workspace access token", message)
        return 401, message
    elseif occursin("invalid auth token", message)
        return 401, message
    elseif occursin("auth token is required", message)
        return 401, message
    elseif occursin("permission denied", message)
        return 403, message
    elseif occursin("unsupported workspace role", message)
        return 403, message
    elseif occursin("Extension not validated for current checkpoint", message)
        return 409, message
    end

    return 500, message
end

function append_audit_event!(
    state::GatewayState,
    request::HTTP.Request,
    action::AbstractString;
    target_type::AbstractString,
    target_id::AbstractString,
    details = Dict{String,Any}(),
)
    payload = Dict{String,Any}(
        "action" => String(action),
        "targetType" => String(target_type),
        "targetId" => String(target_id),
        "recordedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        "authContext" => auth_context_payload(request),
        "details" => Dict{String,Any}(String(key) => value for (key, value) in pairs(details)),
    )
    return JuliaFlowGatewayRepository.append_event!(
        state.repository,
        "audit.action";
        aggregate_type = String(target_type),
        aggregate_id = String(target_id),
        payload = payload,
        producer = "api-gateway",
    )
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
    offsets = get(
        execution.metadata,
        "stream_checkpoint_offsets",
        Dict(
            "topic" => get(execution.metadata, "stream_topic", "unknown"),
            "consumerGroup" => get(execution.metadata, "stream_consumer_group", "unknown"),
        ),
    )
    offsets = Dict{String,Any}(String(key) => value for (key, value) in pairs(offsets))
    offsets["lastProcessedAt"] = execution.updated_at
    return Dict(
        "workflowId" => String(workflow_id),
        "checkpointId" => String(get(execution.metadata, "stream_last_checkpoint_id", "stream-" * execution.execution_id)),
        "offsets" => offsets,
        "watermark" => get(execution.metadata, "stream_watermark", nothing),
        "consumerLag" => get(execution.metadata, "stream_consumer_lag", 0),
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

function broadcast_stream_checkpoint_event!(state::GatewayState, payload::Dict{String,Any})
    workflow_id = String(payload["workflowId"])
    notifications = String[
        jsonrpc_notification("streaming.checkpoint.completed", payload),
    ]
    broadcast_canvas_notifications!(state, workflow_id, notifications)
    return nothing
end

function broadcast_dashboard_published!(state::GatewayState, dashboard::JuliaFlowGatewayRepository.PublishedDashboardRecord)
    notifications = String[
        jsonrpc_notification("dashboard.published", JuliaFlowGatewayRepository.published_dashboard_payload(dashboard)),
        jsonrpc_notification(
            "dashboard.outlet.updated",
            dashboard_outlet_updated_payload(state, dashboard.dashboard_id, String[]),
        ),
    ]
    broadcast_dashboard_notifications!(state, dashboard.dashboard_id, notifications)
    return nothing
end

function upsert_execution!(state::GatewayState, execution::GatewayExecution)
    for (index, current) in pairs(state.executions)
        if current.execution_id == execution.execution_id
            state.executions[index] = execution
            sync_worker_service!(state.worker_service, state.executions)
            return execution
        end
    end
    push!(state.executions, execution)
    sync_worker_service!(state.worker_service, state.executions)
    return execution
end

function process_gateway_event!(state::GatewayState, event::JuliaFlowGatewayRepository.GatewayEvent)
    event.event_id in state.processed_event_ids && return false
    push!(state.processed_event_ids, event.event_id)

    if event.event_type == "execution.changed"
        execution = JuliaFlowGatewayRepository.gateway_execution(event.payload)
        upsert_execution!(state, execution)
        broadcast_execution_update!(state, execution.workflow_id, execution)
    elseif event.event_type == "repository.save.changed"
        workflow_id = String(event.payload["workflowId"])
        workflows = load_workflows(state.repository)
        haskey(workflows, workflow_id) && (state.workflows[workflow_id] = workflows[workflow_id])
        broadcast_workflow_save!(state, workflow_id)
    elseif event.event_type == "hub.extension.changed"
        extension = JuliaFlowGatewayRepository.gateway_hub_extension(event.payload)
        state.hub_extensions[extension.extension_id] = extension
    elseif event.event_type == "dashboard.published"
        dashboard = JuliaFlowGatewayRepository.gateway_published_dashboard(event.payload)
        state.published_dashboards[dashboard.dashboard_id] = dashboard
        broadcast_dashboard_published!(state, dashboard)
    elseif event.event_type == "stream.checkpoint.completed"
        broadcast_stream_checkpoint_event!(state, event.payload)
    end
    return true
end

function consume_gateway_events!(state::GatewayState; consumer_id::AbstractString = gateway_event_consumer_id())
    cursor = load_consumer_cursor(state.repository, consumer_id)
    events = JuliaFlowGatewayRepository.list_events_after(state.repository, cursor)
    processed = JuliaFlowGatewayRepository.GatewayEvent[]
    for event in events
        process_gateway_event!(state, event) && push!(processed, event)
        save_consumer_cursor!(state.repository, consumer_id, event.sequence)
    end
    return processed
end

function activate_stream_execution!(state::GatewayState, execution::GatewayExecution)
    updated_execution = JuliaFlowWorkerService.activate_stream_execution!(
        state.worker_service,
        state.workflows,
        state.executions,
        execution.execution_id;
        execution_record = execution_record,
        transition_execution_record = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
        materialize_execution = materialize_execution,
    )
    save_execution!(state.repository, updated_execution; producer = "api-gateway")
    event_backbone_enabled() || broadcast_execution_update!(state, updated_execution.workflow_id, updated_execution)
    return updated_execution
end

function set_stream_lifecycle_response!(
    state::GatewayState,
    workflow_id::AbstractString,
    lifecycle_status::AbstractString;
    message::AbstractString,
)
    execution = JuliaFlowWorkerService.set_stream_lifecycle!(
        state.worker_service,
        state.executions,
        workflow_id;
        lifecycle_status = lifecycle_status,
        message = message,
        execution_record = execution_record,
        append_execution_event = JuliaFlowGatewayRepository.JuliaFlowExecutionService.append_execution_event,
        materialize_execution = materialize_execution,
    )
    save_execution!(state.repository, execution; producer = "api-gateway")
    event_backbone_enabled() || broadcast_execution_update!(state, execution.workflow_id, execution)
    return execution
end

function stop_stream_execution_response!(state::GatewayState, workflow_id::AbstractString)
    execution = JuliaFlowWorkerService.stop_stream_execution!(
        state.worker_service,
        state.executions,
        workflow_id;
        execution_record = execution_record,
        transition_execution_record = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
        materialize_execution = materialize_execution,
    )
    save_execution!(state.repository, execution; producer = "api-gateway")
    checkpoint_payload = streaming_checkpoint_completed_payload(state, execution.workflow_id, execution)
    append_event!(
        state.repository,
        "stream.checkpoint.completed";
        aggregate_type = "workflow",
        aggregate_id = execution.workflow_id,
        payload = checkpoint_payload,
        producer = "api-gateway",
    )
    if !event_backbone_enabled()
        broadcast_execution_update!(state, execution.workflow_id, execution)
        broadcast_stream_checkpoint!(state, execution.workflow_id, execution)
    end
    return execution
end

function latest_execution_for_workflow(state::GatewayState, workflow_id::AbstractString)
    for execution in Iterators.reverse(state.executions)
        execution.workflow_id == workflow_id && return execution
    end
    return nothing
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
        return Dict("jobId" => String(execution["executionId"]), "status" => String(execution["status"])), String[]
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

function start_gateway_sync_task!(state::GatewayState)
    return nothing
end

function start_gateway_event_consumer_task!(state::GatewayState)
    event_backbone_enabled() || return nothing
    poll_ms = event_consumer_poll_ms()
    poll_ms > 0 || return nothing

    @async begin
        while true
            try
                consume_gateway_events!(state)
            catch
            end
            sleep(poll_ms / 1000)
        end
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
    uri = HTTP.URI(String(request.target))
    path = uri.path
    segments = split(path, '/'; keepempty = false)
    query_params = HTTP.queryparams(uri)

    try
        method == "OPTIONS" && return empty_response(204)
        method == "GET" && segments == ["health"] && return json_response(200, healthcheck(state))
        method == "GET" && segments == ["api", "v1", "workflows"] && begin
            require_permission!(request, "workflow:read")
            return json_response(200, list_workflows_response(state))
        end
        method == "GET" && segments == ["api", "v1", "executions"] && begin
            require_permission!(request, "execution:read")
            return json_response(200, execution_list_response(state))
        end
        method == "GET" && length(segments) == 7 && segments[1:3] == ["api", "v1", "dashboards"] && segments[5] == "charts" && segments[7] == "data" && begin
            share_token = haskey(query_params, "shareToken") ? String(query_params["shareToken"]) : nothing
            workspace_token = haskey(query_params, "workspaceToken") ? String(query_params["workspaceToken"]) : nothing
            workspace_bearer_token = bearer_token_from_request(request)
            return json_response(200, published_dashboard_chart_data_response(state, segments[4], segments[6]; share_token = share_token, workspace_token = workspace_token, workspace_bearer_token = workspace_bearer_token))
        end
        method == "GET" && length(segments) == 7 && segments[1:3] == ["api", "v1", "dashboards"] && segments[5] == "charts" && segments[7] == "export.csv" && begin
            share_token = haskey(query_params, "shareToken") ? String(query_params["shareToken"]) : nothing
            workspace_token = haskey(query_params, "workspaceToken") ? String(query_params["workspaceToken"]) : nothing
            workspace_bearer_token = bearer_token_from_request(request)
            body = published_dashboard_chart_data_csv_response(state, segments[4], segments[6]; share_token = share_token, workspace_token = workspace_token, workspace_bearer_token = workspace_bearer_token)
            headers = ["Content-Type" => "text/csv; charset=utf-8", "Content-Disposition" => "attachment; filename=\"$(segments[4])-$(segments[6]).csv\"", base_headers()...]
            return HTTP.Response(200, headers, body)
        end
        method == "GET" && length(segments) == 4 && segments[1:3] == ["api", "v1", "dashboards"] && begin
            share_token = haskey(query_params, "shareToken") ? String(query_params["shareToken"]) : nothing
            workspace_token = haskey(query_params, "workspaceToken") ? String(query_params["workspaceToken"]) : nothing
            workspace_bearer_token = bearer_token_from_request(request)
            return json_response(200, get_published_dashboard_response(state, segments[4]; share_token = share_token, workspace_token = workspace_token, workspace_bearer_token = workspace_bearer_token))
        end
        method == "GET" && length(segments) == 5 && segments[1:3] == ["api", "v1", "workflows"] && segments[5] == "dashboards" && begin
            require_permission!(request, "dashboard:read")
            return json_response(200, list_published_dashboards_response(state, segments[4]))
        end
        method == "GET" && segments == ["api", "v1", "hub", "extensions"] && begin
            require_permission!(request, "hub:read")
            return json_response(200, list_hub_extensions_response(state))
        end
        method == "POST" && segments == ["api", "v1", "hub", "extensions", "register"] && begin
            require_permission!(request, "hub:publish")
            body = parse_request_body(request)
            response = register_hub_extension_response!(state, body)
            extension_id = haskey(body, "manifest") && body["manifest"] isa AbstractDict && haskey(body["manifest"], "extensionId") ?
                String(body["manifest"]["extensionId"]) :
                "unknown"
            append_audit_event!(state, request, "hub.extension.register"; target_type = "hub_extension", target_id = extension_id)
            return json_response(201, response)
        end
        method == "POST" && length(segments) == 7 && segments[1:3] == ["api", "v1", "workflows"] && segments[5] == "dashboards" && segments[7] == "publish" && begin
            require_permission!(request, "dashboard:publish")
            body = parse_request_body(request)
            visibility = haskey(body, "visibility") ? String(body["visibility"]) : "workspace"
            response = publish_dashboard_response!(state, segments[4], segments[6]; visibility = visibility)
            append_audit_event!(state, request, "dashboard.publish"; target_type = "dashboard", target_id = segments[6], details = Dict("workflowId" => segments[4], "visibility" => visibility))
            return json_response(200, response)
        end
        method == "POST" && segments == ["api", "v1", "workflows"] && begin
            require_permission!(request, "workflow:write")
            body = parse_request_body(request)
            response = create_workflow_response_from_body!(state, body)
            workflow_id = haskey(body, "workflow") && body["workflow"] isa AbstractDict && haskey(body["workflow"], "workflowId") ?
                String(body["workflow"]["workflowId"]) :
                "unknown"
            append_audit_event!(state, request, "workflow.create"; target_type = "workflow", target_id = workflow_id)
            return json_response(201, response)
        end
        method == "POST" && length(segments) == 6 && segments[1:4] == ["api", "v1", "hub", "extensions"] && segments[6] == "install" && begin
            require_permission!(request, "hub:install")
            body = parse_request_body(request)
            action = haskey(body, "action") ? String(body["action"]) : "install"
            response = install_hub_extension_response!(state, segments[5]; action = action)
            append_audit_event!(state, request, "hub.extension.$(action)"; target_type = "hub_extension", target_id = segments[5])
            return json_response(200, response)
        end
        method == "POST" && segments == ["api", "v1", "workflows", "import"] && begin
            require_permission!(request, "workflow:write")
            body = parse_request_body(request)
            haskey(body, "sourcePath") || return error_response(400, "missing sourcePath")
            response = import_workflow_response!(state; source_path = String(body["sourcePath"]))
            append_audit_event!(state, request, "workflow.import"; target_type = "workflow", target_id = String(body["sourcePath"]))
            return json_response(201, response)
        end
        method == "GET" && length(segments) == 4 && segments[1:3] == ["api", "v1", "workflows"] && begin
            require_permission!(request, "workflow:read")
            return json_response(200, get_workflow_response(state, segments[4]))
        end
        method == "PUT" && length(segments) == 4 && segments[1:3] == ["api", "v1", "workflows"] && begin
            require_permission!(request, "workflow:write")
            body = parse_request_body(request)
            response = update_workflow_response_from_body!(state, segments[4], body)
            append_audit_event!(state, request, "workflow.update"; target_type = "workflow", target_id = segments[4])
            return json_response(200, response)
        end
        method == "POST" && length(segments) == 5 && segments[1:3] == ["api", "v1", "workflows"] && segments[5] == "execute" && begin
            require_permission!(request, "workflow:execute")
            body = parse_request_body(request)
            flow_variable_values = haskey(body, "flowVariables") ? normalized_string_dict(body["flowVariables"]) : Dict{String,Any}()
            execution_mode_override = haskey(body, "executionMode") ? String(body["executionMode"]) : nothing
            response = execution_accept_response(
                state,
                segments[4];
                flow_variable_values = flow_variable_values,
                execution_mode_override = execution_mode_override,
            )
            append_audit_event!(state, request, "workflow.execute"; target_type = "workflow", target_id = segments[4], details = execution_mode_override === nothing ? Dict{String,Any}() : Dict("executionMode" => execution_mode_override))
            return json_response(
                202,
                response,
            )
        end
        method == "GET" && length(segments) == 4 && segments[1:3] == ["api", "v1", "executions"] && begin
            require_permission!(request, "execution:read")
            return json_response(200, execution_detail_response(state, segments[4]))
        end
        method == "POST" && length(segments) == 5 && segments[1:3] == ["api", "v1", "executions"] && segments[5] == "status" && begin
            require_permission!(request, "execution:write")
            body = parse_request_body(request)
            haskey(body, "status") || return error_response(400, "missing status")
            message = haskey(body, "message") ? String(body["message"]) : nothing
            metadata = if haskey(body, "metadata")
                Dict{String,Any}(String(key) => value for (key, value) in pairs(body["metadata"]))
            else
                Dict{String,Any}()
            end
            response = transition_execution_response!(
                state,
                segments[4];
                status = String(body["status"]),
                message = message,
                metadata = metadata,
            )
            append_audit_event!(state, request, "execution.status.transition"; target_type = "execution", target_id = segments[4], details = Dict("status" => String(body["status"])))
            return json_response(
                200,
                response,
            )
        end
        method == "GET" && segments == ["api", "v1", "checkpoints"] && begin
            require_permission!(request, "checkpoint:read")
            return json_response(200, checkpoint_list_response(state))
        end
        method == "POST" && segments == ["api", "v1", "checkpoints"] && begin
            require_permission!(request, "checkpoint:write")
            body = parse_request_body(request)
            haskey(body, "tag") || return error_response(400, "missing tag")
            haskey(body, "summary") || return error_response(400, "missing summary")
            response = create_checkpoint_response!(state; tag = String(body["tag"]), summary = String(body["summary"]))
            append_audit_event!(state, request, "checkpoint.create"; target_type = "checkpoint", target_id = String(body["tag"]))
            return json_response(
                201,
                response,
            )
        end
        return error_response(404, "route not found")
    catch err
        status, message = classify_gateway_error(err)
        return error_response(status, message)
    end
end

function serve_gateway(state::GatewayState; host::AbstractString = "127.0.0.1", port::Integer = 8088)
    start_gateway_event_consumer_task!(state)
    start_gateway_sync_task!(state)
    return HTTP.serve(gateway_stream_handler(state), host, port; verbose = false, stream = true)
end

end
