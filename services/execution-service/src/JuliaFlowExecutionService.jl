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
    DashboardBinding,
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
    serialize_job_spec,
    validate_workflow,
    execute_workflow

const EXECUTION_HINTS = Set([:cpu_only, :gpu_preferred, :gpu_required])
const EXECUTION_STATUSES = Set([:accepted, :queued, :running, :completed, :failed])
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

Base.@kwdef struct DashboardBinding
    outlet_node_id::String
    dataset_key::String
    refresh_mode::String = "manual"
end

Base.@kwdef struct DashboardChart
    id::String
    title::String
    family::String
    x_field::Union{Nothing,String} = nothing
    y_field::Union{Nothing,String} = nothing
    series_field::Union{Nothing,String} = nothing
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
    return Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")
end

function execution_status_event(status::Symbol; timestamp::String = iso8601_timestamp(), message::Union{Nothing,String} = nothing)
    event = Dict{String,Any}(
        "status" => String(status),
        "at" => timestamp,
    )
    message === nothing || (event["message"] = message)
    return event
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
        "resource_plan" => build_resource_plan(workflow),
    )
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

function parse_dashboard_binding(raw::Dict{String,Any})
    return DashboardBinding(
        outlet_node_id = String(raw["outlet_node_id"]),
        dataset_key = String(raw["dataset_key"]),
        refresh_mode = String(get(raw, "refresh_mode", "manual")),
    )
end

function parse_dashboard_chart(raw::Dict{String,Any})
    return DashboardChart(
        id = String(raw["id"]),
        title = String(raw["title"]),
        family = String(raw["family"]),
        x_field = haskey(raw, "x_field") ? String(raw["x_field"]) : nothing,
        y_field = haskey(raw, "y_field") ? String(raw["y_field"]) : nothing,
        series_field = haskey(raw, "series_field") ? String(raw["series_field"]) : nothing,
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

    for dashboard in workflow.dashboards
        haskey(node_lookup, dashboard.binding.outlet_node_id) ||
            push!(errors, "dashboard $(dashboard.id) references missing outlet node: $(dashboard.binding.outlet_node_id)")
        isempty(dashboard.charts) && push!(errors, "dashboard $(dashboard.id) must include at least one chart")
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

function execution_mode(workflow::WorkflowDefinition)
    run_mode = workflow.runtime.run_mode == :stream ? "stream" : "batch"
    any(node_resource_class(node) == :gpu for node in workflow.nodes) || return "$(run_mode)_cpu"
    any(node.execution_hint == :gpu_required for node in workflow.nodes) && return "$(run_mode)_gpu_required"
    return "$(run_mode)_gpu_preferred"
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
    execution_mode_override === nothing || (job["requested_execution_mode"] = String(execution_mode_override))
    return job
end

end
