module JuliaFlowExecutionService

include(joinpath(@__DIR__, "..", "..", "node-sdk", "src", "JuliaFlowNodeSDK.jl"))
using .JuliaFlowNodeSDK
using Dates
using TOML
using UUIDs

export WorkflowNode,
    NodeCapability,
    WorkflowConnection,
    WorkflowNodeLayout,
    WorkflowGraph,
    WorkflowContainer,
    WorkflowComponent,
    WorkflowControlFlow,
    DashboardBinding,
    DashboardPanel,
    DashboardChart,
    DashboardDefinition,
    WorkflowRuntime,
    WorkflowDefinition,
    workflow_to_toml,
    collect_validation_errors,
    normalize_execution_status,
    can_transition_execution_status,
    create_execution_record,
    transition_execution_record,
    load_workflow_definition_text,
    load_workflow_definition,
    build_parallel_stages,
    build_execution_plan,
    build_executor_schedule,
    serialize_job_spec,
    try_catch_recovery_metadata,
    append_execution_event,
    is_stream_workflow,
    validate_workflow,
    execute_workflow

const EXECUTION_HINTS = Set([:cpu_only, :gpu_preferred, :gpu_required])
const EXECUTION_STATUSES = Set([:accepted, :queued, :running, :completed, :failed])
const CONTROL_FLOW_KINDS = Set([:loop, :switch, :try_catch, :parallel_chunk])
const LOOP_ITERATION_MODES = Set([:table_rows, :files, :parameter_range, :streaming_batches])
const COMPONENT_FLOW_SCOPES = Set(["shared", "isolated"])
const WORKFLOW_RESOURCE_CLASSES = Set([:cpu, :gpu])
const EXECUTOR_DATAFLOW_POLICY_NAME = "callback_dataflow_stage_barrier"
const EXECUTION_STATUS_TRANSITIONS = Dict(
    :accepted => Set([:queued, :failed]),
    :queued => Set([:running, :failed]),
    :running => Set([:completed, :failed]),
    :completed => Set{Symbol}(),
    :failed => Set{Symbol}(),
)

Base.@kwdef struct NodeCapability
    execution_mode::Symbol
    resource_class::Symbol
    accelerator::Union{Nothing,String} = nothing
    worker_pool::Union{Nothing,String} = nothing
end

Base.@kwdef struct WorkflowNode
    id::String
    name::String
    type::String
    execution_hint::Symbol
    capabilities::Union{Nothing,NodeCapability} = nothing
    config::Dict{String,Any}
    ports::Vector{PortSchema}
end

Base.@kwdef struct WorkflowConnection
    source_node_id::String
    source_port_id::String
    target_node_id::String
    target_port_id::String
    data_type::Symbol
    label::Union{Nothing,String} = nothing
end

Base.@kwdef struct WorkflowNodeLayout
    node_id::String
    x::Float64
    y::Float64
    width::Union{Nothing,Float64} = nothing
    checkpoint_tag::Union{Nothing,String} = nothing
    notes::Union{Nothing,String} = nothing
end

Base.@kwdef struct WorkflowGraph
    revision::Int
    node_layouts::Vector{WorkflowNodeLayout} = WorkflowNodeLayout[]
    viewport::Union{Nothing,Dict{String,Any}} = nothing
    selected_node_id::Union{Nothing,String} = nothing
end

Base.@kwdef struct WorkflowContainer
    id::String
    name::String
    node_ids::Vector{String}
    collapsed::Bool = false
end

Base.@kwdef struct WorkflowComponent
    id::String
    name::String
    node_ids::Vector{String}
    version::String = "0.1.0"
    flow_variable_scope::String = "isolated"
    dashboard_ids::Vector{String} = String[]
end

Base.@kwdef struct WorkflowControlFlow
    id::String
    kind::Symbol
    name::Union{Nothing,String} = nothing
    start_node_id::Union{Nothing,String} = nothing
    end_node_id::Union{Nothing,String} = nothing
    iteration_mode::Union{Nothing,Symbol} = nothing
    max_iterations::Union{Nothing,Int} = nothing
    selector::Union{Nothing,String} = nothing
    cases::Vector{Dict{String,Any}} = Dict{String,Any}[]
    default_target_node_id::Union{Nothing,String} = nothing
    try_node_ids::Vector{String} = String[]
    catch_node_ids::Vector{String} = String[]
    source_node_id::Union{Nothing,String} = nothing
    target_node_id::Union{Nothing,String} = nothing
    chunk_size::Union{Nothing,Int} = nothing
    max_concurrency::Union{Nothing,Int} = nothing
    resource_class::Union{Nothing,Symbol} = nothing
end

Base.@kwdef struct DashboardBinding
    outlet_node_id::String
    dataset_key::String
    refresh_mode::String = "manual"
end

Base.@kwdef struct DashboardPanel
    x::Int
    y::Int
    w::Int
    h::Int
end

Base.@kwdef struct DashboardChart
    id::String
    title::String
    family::String
    x_field::Union{Nothing,String} = nothing
    y_field::Union{Nothing,String} = nothing
    series_field::Union{Nothing,String} = nothing
    panel::Union{Nothing,DashboardPanel} = nothing
end

Base.@kwdef struct DashboardDefinition
    id::String
    name::String
    binding::DashboardBinding
    charts::Vector{DashboardChart} = DashboardChart[]
end

Base.@kwdef struct WorkflowRuntime
    run_mode::Symbol = :batch
    source::Union{Nothing,Dict{String,Any}} = nothing
    window::Union{Nothing,Dict{String,Any}} = nothing
    policy::Union{Nothing,Dict{String,Any}} = nothing
end

Base.@kwdef struct WorkflowDefinition
    id::String
    name::String
    version::String
    nodes::Vector{WorkflowNode}
    connections::Vector{WorkflowConnection}
    flow_variables::Vector{Dict{String,Any}} = Dict{String,Any}[]
    bi_outlets::Vector{Dict{String,Any}} = Dict{String,Any}[]
    graph::Union{Nothing,WorkflowGraph} = nothing
    containers::Vector{WorkflowContainer} = WorkflowContainer[]
    components::Vector{WorkflowComponent} = WorkflowComponent[]
    control_flow::Vector{WorkflowControlFlow} = WorkflowControlFlow[]
    dashboards::Vector{DashboardDefinition} = DashboardDefinition[]
    runtime::WorkflowRuntime = WorkflowRuntime()
end

"""
Normalize execution status from `String` or `Symbol` to validated `Symbol`.
"""
function normalize_execution_status(status::Symbol)
    status in EXECUTION_STATUSES || error("unsupported execution status: $(status)")
    return status
end

function normalize_execution_status(status::AbstractString)
    return normalize_execution_status(Symbol(status))
end

"""
Return true when transition from `from_status` to `to_status` is allowed.
"""
function can_transition_execution_status(from_status, to_status)
    from_symbol = normalize_execution_status(from_status)
    to_symbol = normalize_execution_status(to_status)
    return to_symbol in EXECUTION_STATUS_TRANSITIONS[from_symbol]
end

function iso8601_timestamp()
    return Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss") * "Z"
end

function execution_status_event(status::Symbol; timestamp::String = iso8601_timestamp(), message::Union{Nothing,String} = nothing)
    event = Dict{String,Any}(
        "status" => String(status),
        "at" => timestamp,
    )
    message === nothing || (event["message"] = message)
    return event
end

function observability_trace_id()
    return replace(string(uuid4()), "-" => "")
end

function observability_span_id()
    return observability_trace_id()[1:16]
end

function execution_observability_trace(
    workflow::WorkflowDefinition,
    dispatch_plan::Vector{Dict{String,Any}};
    duration_ms::Real,
)
    trace_id = observability_trace_id()
    return Dict{String,Any}(
        "trace_id" => trace_id,
        "root_span_id" => observability_span_id(),
        "spans" => [
            Dict{String,Any}(
                "trace_id" => trace_id,
                "span_id" => observability_span_id(),
                "name" => "execution.dispatch_plan",
                "kind" => "internal",
                "started_at" => iso8601_timestamp(),
                "duration_ms" => duration_ms,
                "attributes" => Dict{String,Any}(
                    "workflow.id" => workflow.id,
                    "workflow.version" => workflow.version,
                    "workflow.node_count" => length(workflow.nodes),
                    "workflow.connection_count" => length(workflow.connections),
                    "dispatch.lane_count" => length(dispatch_plan),
                ),
            ),
        ],
    )
end

function build_control_flow_plan(workflow::WorkflowDefinition)
    plan = Dict{String,Any}[]

    for control in workflow.control_flow
        if control.kind == :loop
            push!(plan, Dict{String,Any}(
                "control_id" => control.id,
                "kind" => String(control.kind),
                "iteration_mode" => String(control.iteration_mode),
                "max_iterations" => control.max_iterations,
                "start_node_id" => control.start_node_id,
                "end_node_id" => control.end_node_id,
                "body_node_ids" => loop_body_node_ids(workflow, control),
                "bounded" => true,
            ))
        elseif control.kind == :try_catch
            push!(plan, Dict{String,Any}(
                "control_id" => control.id,
                "kind" => String(control.kind),
                "try_node_ids" => copy(control.try_node_ids),
                "catch_node_ids" => copy(control.catch_node_ids),
                "bounded" => true,
            ))
        end
    end

    return plan
end

function try_catch_recovery_metadata(workflow::WorkflowDefinition, failed_node_id::AbstractString)
    failed_node = String(failed_node_id)

    for control in workflow.control_flow
        control.kind == :try_catch || continue
        failed_node in control.try_node_ids || continue
        return Dict{String,Any}(
            "control_id" => control.id,
            "failed_node_id" => failed_node,
            "catch_node_ids" => copy(control.catch_node_ids),
            "status" => "recovered",
            "bounded" => true,
        )
    end

    return nothing
end

"""
Create durable execution record with state, timestamps, and transition history.
"""
function create_execution_record(
    workflow::WorkflowDefinition;
    execution_id::UUID = uuid4(),
    checkpoint_tag::String = "cp/00-foundation",
    initial_status::Union{Symbol,AbstractString} = :accepted,
    status_message::Union{Nothing,String} = nothing,
)
    status = normalize_execution_status(initial_status)
    stages = build_parallel_stages(workflow)
    plan = reduce(vcat, stages; init = String[])
    created_at = iso8601_timestamp()
    history = [execution_status_event(status; timestamp = created_at, message = status_message)]
    resource_plan = build_resource_plan(workflow)
    control_flow_plan = build_control_flow_plan(workflow)
    dispatch_started_at = time_ns()
    dispatch_plan = build_dispatch_plan(workflow)
    executor_schedule = build_executor_schedule(workflow, stages)
    dispatch_duration_ms = round((time_ns() - dispatch_started_at) / 1_000_000; digits = 3)

    record = Dict{String,Any}(
        "execution_id" => string(execution_id),
        "workflow_id" => workflow.id,
        "workflow_version" => workflow.version,
        "checkpoint_tag" => checkpoint_tag,
        "stages" => stages,
        "plan" => plan,
        "status" => String(status),
        "mode" => execution_mode(workflow),
        "node_count" => length(workflow.nodes),
        "connection_count" => length(workflow.connections),
        "created_at" => created_at,
        "updated_at" => created_at,
        "status_history" => history,
        "resource_plan" => resource_plan,
        "dispatch_plan" => dispatch_plan,
        "executor_schedule" => executor_schedule,
        "observability_trace" => execution_observability_trace(
            workflow,
            dispatch_plan;
            duration_ms = dispatch_duration_ms,
        ),
    )
    isempty(control_flow_plan) || (record["control_flow_plan"] = control_flow_plan)
    workflow.runtime.run_mode == :stream && (record["stream_lifecycle_status"] = "starting")

    if status == :queued
        record["queued_at"] = created_at
    elseif status == :running
        record["queued_at"] = created_at
        record["started_at"] = created_at
    elseif status == :completed || status == :failed
        record["finished_at"] = created_at
    end

    return record
end

"""
Apply validated lifecycle transition to execution record and append history event.
"""
function transition_execution_record(
    record::AbstractDict{<:Any,<:Any},
    to_status::Union{Symbol,AbstractString};
    message::Union{Nothing,String} = nothing,
    metadata::AbstractDict{<:Any,<:Any} = Dict{String,Any}(),
    timestamp::String = iso8601_timestamp(),
)
    current_status = get(record, "status", nothing)
    current_status === nothing && error("execution record missing status")

    from_symbol = normalize_execution_status(current_status)
    to_symbol = normalize_execution_status(to_status)
    can_transition_execution_status(from_symbol, to_symbol) ||
        error("invalid execution status transition: $(from_symbol) -> $(to_symbol)")

    updated = Dict{String,Any}(string(key) => value for (key, value) in pairs(record))
    history = get(updated, "status_history", Any[])
    events = history isa AbstractVector ? [item for item in history] : Any[]
    push!(events, execution_status_event(to_symbol; timestamp = timestamp, message = message))

    updated["status"] = String(to_symbol)
    updated["updated_at"] = timestamp
    updated["status_history"] = events

    if to_symbol == :queued
        updated["queued_at"] = get(updated, "queued_at", timestamp)
    elseif to_symbol == :running
        updated["queued_at"] = get(updated, "queued_at", timestamp)
        updated["started_at"] = timestamp
    elseif to_symbol == :completed || to_symbol == :failed
        updated["finished_at"] = timestamp
    end

    isempty(metadata) || merge!(updated, Dict{String,Any}(string(key) => value for (key, value) in pairs(metadata)))
    return updated
end

function append_execution_event(
    record::AbstractDict{<:Any,<:Any};
    message::Union{Nothing,String} = nothing,
    metadata::AbstractDict{<:Any,<:Any} = Dict{String,Any}(),
    timestamp::String = iso8601_timestamp(),
)
    current_status = get(record, "status", nothing)
    current_status === nothing && error("execution record missing status")

    updated = Dict{String,Any}(string(key) => value for (key, value) in pairs(record))
    history = get(updated, "status_history", Any[])
    events = history isa AbstractVector ? [item for item in history] : Any[]
    push!(events, execution_status_event(normalize_execution_status(current_status); timestamp = timestamp, message = message))
    updated["updated_at"] = timestamp
    updated["status_history"] = events
    isempty(metadata) || merge!(updated, Dict{String,Any}(string(key) => value for (key, value) in pairs(metadata)))
    return updated
end

function parse_node(raw::Dict{String,Any})
    ports = [
        PortSchema(
            id = port["id"],
            direction = Symbol(port["direction"]),
            type = Symbol(port["type"]),
            label = get(port, "label", port["id"]),
        ) for port in raw["ports"]
    ]
    return WorkflowNode(
        id = raw["id"],
        name = raw["name"],
        type = raw["type"],
        execution_hint = Symbol(raw["execution_hint"]),
        capabilities = haskey(raw, "capabilities") ? parse_capabilities(raw["capabilities"]) : nothing,
        config = get(raw, "config", Dict{String,Any}()),
        ports = ports,
    )
end

function parse_capabilities(raw::Dict{String,Any})
    return NodeCapability(
        execution_mode = Symbol(get(raw, "execution_mode", "batch")),
        resource_class = Symbol(get(raw, "resource_class", "cpu")),
        accelerator = haskey(raw, "accelerator") ? String(raw["accelerator"]) : nothing,
        worker_pool = haskey(raw, "worker_pool") ? String(raw["worker_pool"]) : nothing,
    )
end

function parse_connection(raw::Dict{String,Any})
    return WorkflowConnection(
        source_node_id = raw["source_node_id"],
        source_port_id = raw["source_port_id"],
        target_node_id = raw["target_node_id"],
        target_port_id = raw["target_port_id"],
        data_type = Symbol(raw["data_type"]),
        label = haskey(raw, "label") ? String(raw["label"]) : nothing,
    )
end

function parse_graph_layout(raw::Dict{String,Any})
    return WorkflowNodeLayout(
        node_id = String(raw["node_id"]),
        x = Float64(raw["x"]),
        y = Float64(raw["y"]),
        width = haskey(raw, "width") ? Float64(raw["width"]) : nothing,
        checkpoint_tag = haskey(raw, "checkpoint_tag") ? String(raw["checkpoint_tag"]) : nothing,
        notes = haskey(raw, "notes") ? String(raw["notes"]) : nothing,
    )
end

function parse_graph(raw::Dict{String,Any})
    return WorkflowGraph(
        revision = Int(get(raw, "revision", 1)),
        node_layouts = [parse_graph_layout(item) for item in get(raw, "node_layouts", Dict{String,Any}[])],
        viewport = haskey(raw, "viewport") ? Dict{String,Any}(String(key) => value for (key, value) in pairs(raw["viewport"])) : nothing,
        selected_node_id = haskey(raw, "selected_node_id") ? String(raw["selected_node_id"]) : nothing,
    )
end

function parse_container(raw::Dict{String,Any})
    return WorkflowContainer(
        id = String(get(raw, "id", get(raw, "container_id", ""))),
        name = String(raw["name"]),
        node_ids = [String(item) for item in get(raw, "node_ids", String[])],
        collapsed = Bool(get(raw, "collapsed", false)),
    )
end

function parse_component(raw::Dict{String,Any})
    return WorkflowComponent(
        id = String(get(raw, "id", get(raw, "component_id", ""))),
        name = String(raw["name"]),
        node_ids = [String(item) for item in get(raw, "node_ids", String[])],
        version = String(get(raw, "version", "0.1.0")),
        flow_variable_scope = String(get(raw, "flow_variable_scope", "isolated")),
        dashboard_ids = [String(item) for item in get(raw, "dashboard_ids", String[])],
    )
end

function optional_string(raw::Dict{String,Any}, key::String)
    return haskey(raw, key) ? String(raw[key]) : nothing
end

function optional_int(raw::Dict{String,Any}, key::String)
    return haskey(raw, key) ? Int(raw[key]) : nothing
end

function optional_symbol(raw::Dict{String,Any}, key::String)
    return haskey(raw, key) ? Symbol(raw[key]) : nothing
end

function parse_control_flow(raw::Dict{String,Any})
    return WorkflowControlFlow(
        id = String(get(raw, "id", get(raw, "control_id", ""))),
        kind = Symbol(raw["kind"]),
        name = optional_string(raw, "name"),
        start_node_id = optional_string(raw, "start_node_id"),
        end_node_id = optional_string(raw, "end_node_id"),
        iteration_mode = optional_symbol(raw, "iteration_mode"),
        max_iterations = optional_int(raw, "max_iterations"),
        selector = optional_string(raw, "selector"),
        cases = [Dict{String,Any}(String(key) => value for (key, value) in pairs(item)) for item in get(raw, "cases", Dict{String,Any}[])],
        default_target_node_id = optional_string(raw, "default_target_node_id"),
        try_node_ids = [String(item) for item in get(raw, "try_node_ids", String[])],
        catch_node_ids = [String(item) for item in get(raw, "catch_node_ids", String[])],
        source_node_id = optional_string(raw, "source_node_id"),
        target_node_id = optional_string(raw, "target_node_id"),
        chunk_size = optional_int(raw, "chunk_size"),
        max_concurrency = optional_int(raw, "max_concurrency"),
        resource_class = optional_symbol(raw, "resource_class"),
    )
end

function parse_dashboard_binding(raw::Dict{String,Any})
    return DashboardBinding(
        outlet_node_id = String(raw["outlet_node_id"]),
        dataset_key = String(raw["dataset_key"]),
        refresh_mode = String(get(raw, "refresh_mode", "manual")),
    )
end

function parse_dashboard_chart(raw::Dict{String,Any})
    panel = haskey(raw, "panel") ?
        DashboardPanel(
            x = Int(raw["panel"]["x"]),
            y = Int(raw["panel"]["y"]),
            w = Int(raw["panel"]["w"]),
            h = Int(raw["panel"]["h"]),
        ) :
        nothing
    return DashboardChart(
        id = String(raw["id"]),
        title = String(raw["title"]),
        family = String(raw["family"]),
        x_field = haskey(raw, "x_field") ? String(raw["x_field"]) : nothing,
        y_field = haskey(raw, "y_field") ? String(raw["y_field"]) : nothing,
        series_field = haskey(raw, "series_field") ? String(raw["series_field"]) : nothing,
        panel = panel,
    )
end

function parse_dashboard(raw::Dict{String,Any})
    return DashboardDefinition(
        id = String(raw["id"]),
        name = String(raw["name"]),
        binding = parse_dashboard_binding(raw["binding"]),
        charts = [parse_dashboard_chart(item) for item in get(raw, "charts", Dict{String,Any}[])],
    )
end

function parse_runtime(raw)
    return WorkflowRuntime(
        run_mode = Symbol(get(raw, "run_mode", "batch")),
        source = haskey(raw, "source") ? Dict{String,Any}(String(key) => value for (key, value) in pairs(raw["source"])) : nothing,
        window = haskey(raw, "window") ? Dict{String,Any}(String(key) => value for (key, value) in pairs(raw["window"])) : nothing,
        policy = haskey(raw, "policy") ? Dict{String,Any}(String(key) => value for (key, value) in pairs(raw["policy"])) : nothing,
    )
end

function parse_workflow_definition(raw::Dict{String,Any})
    nodes = [parse_node(node) for node in raw["nodes"]]
    connections = [parse_connection(conn) for conn in raw["connections"]]
    flow_variables = get(raw, "flow_variables", Dict{String,Any}[])
    bi_outlets = get(raw["workflow"], "bi_outlets", Dict{String,Any}[])
    graph = haskey(raw["workflow"], "graph") ? parse_graph(raw["workflow"]["graph"]) : nothing
    containers = [parse_container(item) for item in get(raw["workflow"], "containers", Dict{String,Any}[])]
    components = [parse_component(item) for item in get(raw["workflow"], "components", Dict{String,Any}[])]
    control_flow = [parse_control_flow(item) for item in get(raw["workflow"], "control_flow", Dict{String,Any}[])]
    dashboards = [parse_dashboard(item) for item in get(raw["workflow"], "dashboards", Dict{String,Any}[])]
    runtime = haskey(raw, "runtime") ? parse_runtime(raw["runtime"]) : WorkflowRuntime()
    return WorkflowDefinition(
        id = raw["workflow"]["id"],
        name = raw["workflow"]["name"],
        version = raw["version"],
        nodes = nodes,
        connections = connections,
        flow_variables = flow_variables,
        bi_outlets = bi_outlets,
        graph = graph,
        containers = containers,
        components = components,
        control_flow = control_flow,
        dashboards = dashboards,
        runtime = runtime,
    )
end

function workflow_to_toml(workflow::WorkflowDefinition)
    document = Dict{String,Any}(
        "version" => workflow.version,
        "workflow" => Dict{String,Any}(
            "id" => workflow.id,
            "name" => workflow.name,
        ),
        "flow_variables" => [Dict{String,Any}(String(key) => value for (key, value) in pairs(variable)) for variable in workflow.flow_variables],
        "nodes" => [
            let
                node_payload = Dict{String,Any}(
                "id" => node.id,
                "name" => node.name,
                "type" => node.type,
                "execution_hint" => String(node.execution_hint),
                "config" => Dict{String,Any}(String(key) => value for (key, value) in pairs(node.config)),
                "ports" => [
                    Dict{String,Any}(
                        "id" => port.id,
                        "direction" => String(port.direction),
                        "type" => String(port.type),
                        "label" => port.label,
                    ) for port in node.ports
                ],
                )
                if node.capabilities !== nothing
                    node_payload["capabilities"] = Dict{String,Any}(
                        "execution_mode" => String(node.capabilities.execution_mode),
                        "resource_class" => String(node.capabilities.resource_class),
                    )
                    node.capabilities.accelerator === nothing || (node_payload["capabilities"]["accelerator"] = node.capabilities.accelerator)
                    node.capabilities.worker_pool === nothing || (node_payload["capabilities"]["worker_pool"] = node.capabilities.worker_pool)
                end
                node_payload
            end for node in workflow.nodes
        ],
        "connections" => [
            let
                connection_payload = Dict{String,Any}(
                "source_node_id" => connection.source_node_id,
                "source_port_id" => connection.source_port_id,
                "target_node_id" => connection.target_node_id,
                "target_port_id" => connection.target_port_id,
                "data_type" => String(connection.data_type),
                )
                connection.label === nothing || (connection_payload["label"] = connection.label)
                connection_payload
            end for connection in workflow.connections
        ],
        "runtime" => Dict{String,Any}("run_mode" => String(workflow.runtime.run_mode)),
    )

    if !isempty(workflow.bi_outlets)
        document["workflow"]["bi_outlets"] = [Dict{String,Any}(String(key) => value for (key, value) in pairs(outlet)) for outlet in workflow.bi_outlets]
    end
    if workflow.graph !== nothing
        graph_payload = Dict{String,Any}(
            "revision" => workflow.graph.revision,
            "node_layouts" => [
                Dict{String,Any}(
                    "node_id" => layout.node_id,
                    "x" => layout.x,
                    "y" => layout.y,
                ) for layout in workflow.graph.node_layouts
            ],
        )
        workflow.graph.viewport === nothing || (graph_payload["viewport"] = workflow.graph.viewport)
        workflow.graph.selected_node_id === nothing || (graph_payload["selected_node_id"] = workflow.graph.selected_node_id)
        for (index, layout) in enumerate(workflow.graph.node_layouts)
            layout.width === nothing || (graph_payload["node_layouts"][index]["width"] = layout.width)
            layout.checkpoint_tag === nothing || (graph_payload["node_layouts"][index]["checkpoint_tag"] = layout.checkpoint_tag)
            layout.notes === nothing || (graph_payload["node_layouts"][index]["notes"] = layout.notes)
        end
        document["workflow"]["graph"] = graph_payload
    end
    if !isempty(workflow.containers)
        document["workflow"]["containers"] = [
            Dict{String,Any}(
                "id" => container.id,
                "name" => container.name,
                "node_ids" => container.node_ids,
                "collapsed" => container.collapsed,
            ) for container in workflow.containers
        ]
    end
    if !isempty(workflow.components)
        document["workflow"]["components"] = [
            Dict{String,Any}(
                "id" => component.id,
                "name" => component.name,
                "node_ids" => component.node_ids,
                "version" => component.version,
                "flow_variable_scope" => component.flow_variable_scope,
                "dashboard_ids" => component.dashboard_ids,
            ) for component in workflow.components
        ]
    end
    if !isempty(workflow.control_flow)
        document["workflow"]["control_flow"] = [
            let
                payload = Dict{String,Any}(
                    "id" => control.id,
                    "kind" => String(control.kind),
                )
                control.name === nothing || (payload["name"] = control.name)
                control.start_node_id === nothing || (payload["start_node_id"] = control.start_node_id)
                control.end_node_id === nothing || (payload["end_node_id"] = control.end_node_id)
                control.iteration_mode === nothing || (payload["iteration_mode"] = String(control.iteration_mode))
                control.max_iterations === nothing || (payload["max_iterations"] = control.max_iterations)
                control.selector === nothing || (payload["selector"] = control.selector)
                isempty(control.cases) || (payload["cases"] = control.cases)
                control.default_target_node_id === nothing || (payload["default_target_node_id"] = control.default_target_node_id)
                isempty(control.try_node_ids) || (payload["try_node_ids"] = control.try_node_ids)
                isempty(control.catch_node_ids) || (payload["catch_node_ids"] = control.catch_node_ids)
                control.source_node_id === nothing || (payload["source_node_id"] = control.source_node_id)
                control.target_node_id === nothing || (payload["target_node_id"] = control.target_node_id)
                control.chunk_size === nothing || (payload["chunk_size"] = control.chunk_size)
                control.max_concurrency === nothing || (payload["max_concurrency"] = control.max_concurrency)
                control.resource_class === nothing || (payload["resource_class"] = String(control.resource_class))
                payload
            end for control in workflow.control_flow
        ]
    end
    if !isempty(workflow.dashboards)
        document["workflow"]["dashboards"] = [
            Dict{String,Any}(
                "id" => dashboard.id,
                "name" => dashboard.name,
                "binding" => Dict{String,Any}(
                    "outlet_node_id" => dashboard.binding.outlet_node_id,
                    "dataset_key" => dashboard.binding.dataset_key,
                    "refresh_mode" => dashboard.binding.refresh_mode,
                ),
                "charts" => [
                    Dict{String,Any}(
                        "id" => chart.id,
                        "title" => chart.title,
                        "family" => chart.family,
                    ) for chart in dashboard.charts
                ],
            ) for dashboard in workflow.dashboards
        ]
        for (dashboard_index, dashboard) in enumerate(workflow.dashboards)
            for (chart_index, chart) in enumerate(dashboard.charts)
                chart.x_field === nothing || (document["workflow"]["dashboards"][dashboard_index]["charts"][chart_index]["x_field"] = chart.x_field)
                chart.y_field === nothing || (document["workflow"]["dashboards"][dashboard_index]["charts"][chart_index]["y_field"] = chart.y_field)
                chart.series_field === nothing || (document["workflow"]["dashboards"][dashboard_index]["charts"][chart_index]["series_field"] = chart.series_field)
                chart.panel === nothing || (document["workflow"]["dashboards"][dashboard_index]["charts"][chart_index]["panel"] = Dict(
                    "x" => chart.panel.x,
                    "y" => chart.panel.y,
                    "w" => chart.panel.w,
                    "h" => chart.panel.h,
                ))
            end
        end
    end
    workflow.runtime.source === nothing || (document["runtime"]["source"] = workflow.runtime.source)
    workflow.runtime.window === nothing || (document["runtime"]["window"] = workflow.runtime.window)
    workflow.runtime.policy === nothing || (document["runtime"]["policy"] = workflow.runtime.policy)

    io = IOBuffer()
    TOML.print(io, document)
    return String(take!(io))
end

function load_workflow_definition_text(contents::AbstractString)
    raw = TOML.parse(contents)
    return parse_workflow_definition(raw)
end

function load_workflow_definition(path::AbstractString)
    return load_workflow_definition_text(read(path, String))
end

function port_lookup(node::WorkflowNode)
    lookup = Dict{String,PortSchema}()
    for port in node.ports
        validate_port_direction(port.direction)
        validate_port_type(port.type)
        lookup[port.id] = port
    end
    return lookup
end

function push_missing_node_error!(errors::Vector{String}, node_lookup::Dict{String,WorkflowNode}, owner::String, node_id::AbstractString)
    haskey(node_lookup, String(node_id)) || push!(errors, "$(owner) references missing node: $(node_id)")
    return errors
end

function validate_control_flow!(
    errors::Vector{String},
    node_lookup::Dict{String,WorkflowNode},
    workflow::WorkflowDefinition,
    control::WorkflowControlFlow,
)
    control.kind in CONTROL_FLOW_KINDS || push!(errors, "unsupported control flow kind on $(control.id): $(control.kind)")

    if control.kind == :loop
        control.start_node_id === nothing && push!(errors, "loop $(control.id) missing start node")
        control.end_node_id === nothing && push!(errors, "loop $(control.id) missing end node")
        control.iteration_mode in LOOP_ITERATION_MODES || push!(errors, "loop $(control.id) has unsupported iteration mode")
        control.max_iterations !== nothing && control.max_iterations > 0 || push!(errors, "loop $(control.id) max iterations must be > 0")
        control.start_node_id === nothing || push_missing_node_error!(errors, node_lookup, "loop $(control.id)", control.start_node_id)
        control.end_node_id === nothing || push_missing_node_error!(errors, node_lookup, "loop $(control.id)", control.end_node_id)
        if control.start_node_id !== nothing &&
           control.end_node_id !== nothing &&
           haskey(node_lookup, control.start_node_id) &&
           haskey(node_lookup, control.end_node_id)
            try
                loop_body_node_ids(workflow, control)
            catch err
                push!(errors, sprint(showerror, err))
            end
        end
    elseif control.kind == :switch
        control.selector === nothing && push!(errors, "switch $(control.id) missing selector")
        isempty(control.cases) && push!(errors, "switch $(control.id) must include at least one case")
        for case in control.cases
            label = String(get(case, "label", ""))
            target = String(get(case, "target_node_id", get(case, "targetNodeId", "")))
            isempty(label) && push!(errors, "switch $(control.id) case missing label")
            isempty(target) && push!(errors, "switch $(control.id) case missing target node")
            isempty(target) || push_missing_node_error!(errors, node_lookup, "switch $(control.id) case", target)
        end
        control.default_target_node_id === nothing || push_missing_node_error!(errors, node_lookup, "switch $(control.id) default", control.default_target_node_id)
    elseif control.kind == :try_catch
        isempty(control.try_node_ids) && push!(errors, "try/catch $(control.id) missing try nodes")
        isempty(control.catch_node_ids) && push!(errors, "try/catch $(control.id) missing catch nodes")
        for node_id in control.try_node_ids
            push_missing_node_error!(errors, node_lookup, "try/catch $(control.id) try", node_id)
        end
        for node_id in control.catch_node_ids
            push_missing_node_error!(errors, node_lookup, "try/catch $(control.id) catch", node_id)
        end
    elseif control.kind == :parallel_chunk
        control.source_node_id === nothing && push!(errors, "parallel chunk $(control.id) missing source node")
        control.chunk_size !== nothing && control.chunk_size > 0 || push!(errors, "parallel chunk $(control.id) chunk size must be > 0")
        control.max_concurrency !== nothing && 0 < control.max_concurrency <= 1024 || push!(errors, "parallel chunk $(control.id) max concurrency must be between 1 and 1024")
        control.resource_class === nothing || control.resource_class in WORKFLOW_RESOURCE_CLASSES || push!(errors, "parallel chunk $(control.id) has unsupported resource class")
        control.source_node_id === nothing || push_missing_node_error!(errors, node_lookup, "parallel chunk $(control.id)", control.source_node_id)
        control.target_node_id === nothing || push_missing_node_error!(errors, node_lookup, "parallel chunk $(control.id)", control.target_node_id)
    end

    return errors
end

function collect_validation_errors(workflow::WorkflowDefinition)
    errors = String[]
    node_lookup = Dict{String,WorkflowNode}()

    for node in workflow.nodes
        if haskey(node_lookup, node.id)
            push!(errors, "duplicate node id: $(node.id)")
            continue
        end
        node.execution_hint in EXECUTION_HINTS || push!(errors, "unsupported execution hint on $(node.id): $(node.execution_hint)")
        node_lookup[node.id] = node

        port_ids = Set{String}()
        for port in node.ports
            try
                validate_port_direction(port.direction)
                validate_port_type(port.type)
            catch err
                push!(errors, sprint(showerror, err))
            end
            if port.id in port_ids
                push!(errors, "duplicate port id $(port.id) on node $(node.id)")
            else
                push!(port_ids, port.id)
            end
        end
    end

    for connection in workflow.connections
        haskey(node_lookup, connection.source_node_id) || begin
            push!(errors, "missing source node: $(connection.source_node_id)")
            continue
        end
        haskey(node_lookup, connection.target_node_id) || begin
            push!(errors, "missing target node: $(connection.target_node_id)")
            continue
        end

        source_port = get(port_lookup(node_lookup[connection.source_node_id]), connection.source_port_id, nothing)
        target_port = get(port_lookup(node_lookup[connection.target_node_id]), connection.target_port_id, nothing)

        source_port === nothing && push!(errors, "missing source port $(connection.source_port_id) on node $(connection.source_node_id)")
        target_port === nothing && push!(errors, "missing target port $(connection.target_port_id) on node $(connection.target_node_id)")
        source_port === nothing && continue
        target_port === nothing && continue

        source_port.direction == :output || push!(errors, "source port $(connection.source_port_id) on $(connection.source_node_id) must be output")
        target_port.direction == :input || push!(errors, "target port $(connection.target_port_id) on $(connection.target_node_id) must be input")
        connection.data_type == source_port.type || push!(errors, "connection data type mismatch on source $(connection.source_node_id).$(connection.source_port_id)")
        connection.data_type == target_port.type || push!(errors, "connection data type mismatch on target $(connection.target_node_id).$(connection.target_port_id)")
    end

    if workflow.graph !== nothing
        workflow.graph.revision >= 1 || push!(errors, "workflow graph revision must be >= 1")
        layout_node_ids = Set{String}()
        for layout in workflow.graph.node_layouts
            haskey(node_lookup, layout.node_id) || push!(errors, "graph layout references missing node: $(layout.node_id)")
            if layout.node_id in layout_node_ids
                push!(errors, "duplicate graph layout node id: $(layout.node_id)")
            else
                push!(layout_node_ids, layout.node_id)
            end
        end
    end

    container_ids = Set{String}()
    for container in workflow.containers
        isempty(container.id) && push!(errors, "container id must not be empty")
        if container.id in container_ids
            push!(errors, "duplicate container id: $(container.id)")
        else
            push!(container_ids, container.id)
        end
        isempty(container.node_ids) && push!(errors, "container $(container.id) must include at least one node")
        for node_id in container.node_ids
            push_missing_node_error!(errors, node_lookup, "container $(container.id)", node_id)
        end
    end

    component_ids = Set{String}()
    for component in workflow.components
        isempty(component.id) && push!(errors, "component id must not be empty")
        if component.id in component_ids
            push!(errors, "duplicate component id: $(component.id)")
        else
            push!(component_ids, component.id)
        end
        component.flow_variable_scope in COMPONENT_FLOW_SCOPES ||
            push!(errors, "component $(component.id) has unsupported flow variable scope")
        isempty(component.node_ids) && push!(errors, "component $(component.id) must include at least one node")
        for node_id in component.node_ids
            push_missing_node_error!(errors, node_lookup, "component $(component.id)", node_id)
        end
    end

    control_ids = Set{String}()
    for control in workflow.control_flow
        isempty(control.id) && push!(errors, "control flow id must not be empty")
        if control.id in control_ids
            push!(errors, "duplicate control flow id: $(control.id)")
        else
            push!(control_ids, control.id)
        end
        validate_control_flow!(errors, node_lookup, workflow, control)
    end

    for dashboard in workflow.dashboards
        haskey(node_lookup, dashboard.binding.outlet_node_id) ||
            push!(errors, "dashboard $(dashboard.id) references missing outlet node: $(dashboard.binding.outlet_node_id)")
        isempty(dashboard.charts) && push!(errors, "dashboard $(dashboard.id) must include at least one chart")
        for chart in dashboard.charts
            chart.panel === nothing && continue
            chart.panel.w > 0 || push!(errors, "dashboard $(dashboard.id) chart $(chart.id) panel width must be > 0")
            chart.panel.h > 0 || push!(errors, "dashboard $(dashboard.id) chart $(chart.id) panel height must be > 0")
        end
    end

    return errors
end

function validate_workflow(workflow::WorkflowDefinition)
    errors = collect_validation_errors(workflow)
    isempty(errors) || error(join(errors, "; "))
    return true
end

function graph_state(workflow::WorkflowDefinition)
    node_order = Dict(node.id => index for (index, node) in enumerate(workflow.nodes))
    in_degree = Dict(node.id => 0 for node in workflow.nodes)
    adjacency = Dict(node.id => String[] for node in workflow.nodes)

    for connection in workflow.connections
        push!(adjacency[connection.source_node_id], connection.target_node_id)
        in_degree[connection.target_node_id] += 1
    end

    return (node_order = node_order, in_degree = in_degree, adjacency = adjacency)
end

function control_flow_graph(workflow::WorkflowDefinition)
    node_order = Dict(node.id => index for (index, node) in enumerate(workflow.nodes))
    adjacency = Dict(node.id => String[] for node in workflow.nodes)
    reverse_adjacency = Dict(node.id => String[] for node in workflow.nodes)

    for connection in workflow.connections
        haskey(adjacency, connection.source_node_id) || continue
        haskey(reverse_adjacency, connection.target_node_id) || continue
        push!(adjacency[connection.source_node_id], connection.target_node_id)
        push!(reverse_adjacency[connection.target_node_id], connection.source_node_id)
    end

    return (node_order = node_order, adjacency = adjacency, reverse_adjacency = reverse_adjacency)
end

function bounded_reachable_nodes(adjacency::Dict{String,Vector{String}}, start_node_id::String, max_nodes::Int)
    visited = Set([start_node_id])
    frontier = [start_node_id]

    for _ in 1:max_nodes
        isempty(frontier) && break
        next_frontier = String[]
        for current_node_id in frontier
            for target_node_id in get(adjacency, current_node_id, String[])
                target_node_id in visited && continue
                push!(visited, target_node_id)
                push!(next_frontier, target_node_id)
            end
        end
        frontier = next_frontier
    end

    return visited
end

function loop_body_node_ids(workflow::WorkflowDefinition, control::WorkflowControlFlow)
    control.start_node_id === nothing && error("loop $(control.id) missing start node")
    control.end_node_id === nothing && error("loop $(control.id) missing end node")

    graph = control_flow_graph(workflow)
    max_nodes = max(length(workflow.nodes), 1)
    forward = bounded_reachable_nodes(graph.adjacency, control.start_node_id, max_nodes)
    control.end_node_id in forward || error("loop $(control.id) end node unreachable from start node")
    backward = bounded_reachable_nodes(graph.reverse_adjacency, control.end_node_id, max_nodes)
    body = [node_id for node_id in intersect(forward, backward)]
    sort!(body, by = node_id -> graph.node_order[node_id])
    return body
end

function build_parallel_stages(workflow::WorkflowDefinition)
    validate_workflow(workflow)
    state = graph_state(workflow)
    node_order = state.node_order
    in_degree = state.in_degree
    adjacency = state.adjacency

    ready = [node.id for node in workflow.nodes if in_degree[node.id] == 0]
    stages = Vector{Vector{String}}()

    while !isempty(ready)
        stage = copy(ready)
        push!(stages, stage)
        next_ready = String[]

        for current in stage
            for target in adjacency[current]
                in_degree[target] -= 1
                if in_degree[target] == 0
                    push!(next_ready, target)
                end
            end
        end

        sort!(next_ready, by = node_id -> node_order[node_id])
        ready = unique(next_ready)
    end

    sum(length, stages) == length(workflow.nodes) || error("workflow contains cycle")
    return stages
end

function build_execution_plan(workflow::WorkflowDefinition)
    stages = build_parallel_stages(workflow)
    return reduce(vcat, stages; init = String[])
end

function node_resource_class(node::WorkflowNode)
    node.capabilities !== nothing && return node.capabilities.resource_class
    node.execution_hint == :gpu_required && return :gpu
    node.execution_hint == :gpu_preferred && return :gpu
    return :cpu
end

function lane_worker_pool(workflow::WorkflowDefinition, lane::Symbol)
    pools = String[]
    for node in workflow.nodes
        node_resource_class(node) == lane || continue
        node.capabilities === nothing && continue
        node.capabilities.worker_pool === nothing && continue
        push!(pools, node.capabilities.worker_pool)
    end
    isempty(pools) && return lane == :gpu ? "alpha-gpu" : "alpha-cpu"
    return sort(unique(pools))[1]
end

function lane_accelerator(workflow::WorkflowDefinition, lane::Symbol)
    lane == :gpu || return nothing
    for node in workflow.nodes
        node_resource_class(node) == :gpu || continue
        node.capabilities === nothing && continue
        node.capabilities.accelerator === nothing && continue
        return node.capabilities.accelerator
    end
    return "cuda"
end

function lane_requested_device(workflow::WorkflowDefinition, lane::Symbol)
    lane == :gpu || return nothing
    for node in workflow.nodes
        node_resource_class(node) == :gpu || continue
        haskey(node.config, "gpuDevicePreference") || continue
        return String(node.config["gpuDevicePreference"])
    end
    return nothing
end

function lane_scheduler_policy(lane::Symbol)
    return lane == :gpu ? "deterministic_device_id" : "shared_cpu"
end

function lane_placement_reason(lane::Symbol)
    return lane == :gpu ? "gpu_lane_isolated_worker" : "cpu_lane_shared_worker"
end

function lane_worker_capacity(lane::Symbol)
    if lane == :gpu
        return Dict{String,Any}("concurrency" => 1, "device_slots" => 1)
    end
    return Dict{String,Any}("concurrency" => 0, "device_slots" => 0)
end

function build_resource_plan(workflow::WorkflowDefinition)
    lanes = Dict(:cpu => String[], :gpu => String[])
    for node in workflow.nodes
        push!(lanes[node_resource_class(node)], node.id)
    end

    result = Dict{String,Any}[]
    for lane in (:cpu, :gpu)
        isempty(lanes[lane]) && continue
        push!(result, Dict("lane" => String(lane), "node_ids" => lanes[lane]))
    end

    return result
end

function build_dispatch_plan(workflow::WorkflowDefinition)
    resource_plan = build_resource_plan(workflow)
    dispatch_plan = Dict{String,Any}[]

    for lane_entry in resource_plan
        lane = Symbol(get(lane_entry, "lane", "cpu"))
        entry = Dict{String,Any}(
            "lane" => String(lane),
            "node_ids" => get(lane_entry, "node_ids", String[]),
            "worker_pool" => lane_worker_pool(workflow, lane),
            "isolation_mode" => lane == :gpu ? "isolated" : "shared",
            "scheduler_policy" => lane_scheduler_policy(lane),
            "placement_reason" => lane_placement_reason(lane),
            "worker_capacity" => lane_worker_capacity(lane),
        )
        accelerator = lane_accelerator(workflow, lane)
        accelerator === nothing || (entry["accelerator"] = accelerator)
        requested_device = lane_requested_device(workflow, lane)
        requested_device === nothing || (entry["requested_device"] = requested_device)
        push!(dispatch_plan, entry)
    end

    return dispatch_plan
end

function build_executor_schedule(workflow::WorkflowDefinition, stages::Vector{Vector{String}})
    node_lookup = Dict(node.id => node for node in workflow.nodes)
    schedule = Dict{String,Any}[]

    for (index, stage) in pairs(stages)
        lanes = Symbol[]
        worker_pools = String[]
        for node_id in stage
            node = node_lookup[node_id]
            lane = node_resource_class(node)
            push!(lanes, lane)
            push!(worker_pools, lane_worker_pool(workflow, lane))
        end
        lane_names = sort(unique(String(lane) for lane in lanes))
        worker_pool_names = sort(unique(worker_pools))
        entry = Dict{String,Any}(
            "stage_index" => Int(index),
            "node_ids" => copy(stage),
            "lanes" => lane_names,
            "worker_pools" => worker_pool_names,
            "scheduler_policy" => "topological_stage_barrier",
            "ready_after_stage" => index == 1 ? 0 : Int(index - 1),
            "max_concurrency" => length(stage),
            "bounded" => true,
        )
        dataflow_policy = executor_dataflow_stage_policy(
            node_lookup,
            stage,
            lane_names,
            worker_pool_names,
            Int(index),
        )
        dataflow_policy === nothing || (entry["dataflow_policy"] = dataflow_policy)
        push!(schedule, entry)
    end

    return schedule
end

function data_table_port_ids(node::WorkflowNode, direction::Symbol)
    return [
        String(port.id) for port in node.ports
            if port.direction == direction && port.type == :data_table
    ]
end

function executor_dataflow_stage_policy(node_lookup, stage, lanes, worker_pools, stage_index::Int)
    eligible_node_ids = String[]
    source_node_ids = String[]
    sink_node_ids = String[]

    for node_id in stage
        node = node_lookup[String(node_id)]
        input_ports = data_table_port_ids(node, :input)
        output_ports = data_table_port_ids(node, :output)
        isempty(input_ports) && isempty(output_ports) && continue
        push!(eligible_node_ids, String(node_id))
        isempty(input_ports) || !isempty(output_ports) || push!(sink_node_ids, String(node_id))
        isempty(output_ports) || !isempty(input_ports) || push!(source_node_ids, String(node_id))
    end

    isempty(eligible_node_ids) && return nothing
    return Dict{String,Any}(
        "policy_name" => EXECUTOR_DATAFLOW_POLICY_NAME,
        "callback_enabled" => true,
        "dataflow_enabled" => true,
        "stage_barrier" => "ready_after_previous_stage",
        "stage_index" => stage_index,
        "eligible_node_ids" => eligible_node_ids,
        "source_node_ids" => source_node_ids,
        "sink_node_ids" => sink_node_ids,
        "lanes" => copy(lanes),
        "worker_pools" => copy(worker_pools),
        "max_concurrency" => length(eligible_node_ids),
        "bounded" => true,
    )
end

function execution_mode(workflow::WorkflowDefinition)
    run_mode = workflow.runtime.run_mode == :stream ? "stream" : "batch"
    any(node_resource_class(node) == :gpu for node in workflow.nodes) || return "$(run_mode)_cpu"
    any(node.execution_hint == :gpu_required for node in workflow.nodes) && return "$(run_mode)_gpu_required"
    return "$(run_mode)_gpu_preferred"
end

function apply_gpu_request_override!(job::Dict{String,Any}, flow_variable_values::AbstractDict{<:Any,<:Any})
    haskey(flow_variable_values, "JULIAFLOW_GPU_DEVICE") || return job
    requested_device = String(flow_variable_values["JULIAFLOW_GPU_DEVICE"])
    for entry in get(job, "dispatch_plan", Any[])
        entry isa AbstractDict || continue
        String(get(entry, "lane", "")) == "gpu" || continue
        entry["requested_device"] = requested_device
    end
    return job
end

function is_stream_workflow(workflow::WorkflowDefinition)
    return workflow.runtime.run_mode == :stream
end

function serialize_job_spec(workflow::WorkflowDefinition; execution_id::UUID = uuid4(), checkpoint_tag::String = "cp/00-foundation")
    return create_execution_record(
        workflow;
        execution_id = execution_id,
        checkpoint_tag = checkpoint_tag,
        initial_status = :accepted,
    )
end

function validate_flow_variable_values(workflow::WorkflowDefinition, flow_variable_values::AbstractDict{<:Any,<:Any})
    isempty(flow_variable_values) && return Dict{String,Any}()
    defined_names = Set(String(variable["name"]) for variable in workflow.flow_variables if haskey(variable, "name"))
    normalized = Dict{String,Any}(String(key) => value for (key, value) in pairs(flow_variable_values))

    for name in keys(normalized)
        name in defined_names || error("unknown flow variable: $(name)")
    end

    return normalized
end

function execute_workflow(
    workflow::WorkflowDefinition;
    checkpoint_tag::String = "cp/00-foundation",
    flow_variable_values::AbstractDict{<:Any,<:Any} = Dict{String,Any}(),
    execution_mode_override::Union{Nothing,AbstractString} = nothing,
)
    validate_workflow(workflow)
    job = serialize_job_spec(workflow; checkpoint_tag = checkpoint_tag)
    validated_values = validate_flow_variable_values(workflow, flow_variable_values)
    isempty(validated_values) || (job["flow_variables"] = validated_values)
    apply_gpu_request_override!(job, validated_values)
    execution_mode_override === nothing || (job["requested_execution_mode"] = String(execution_mode_override))
    return job
end

end
