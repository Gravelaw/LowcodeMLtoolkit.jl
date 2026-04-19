module JuliaFlowExecutionService

include(joinpath(@__DIR__, "..", "..", "node-sdk", "src", "JuliaFlowNodeSDK.jl"))
using .JuliaFlowNodeSDK
using TOML
using UUIDs

export WorkflowNode,
    WorkflowConnection,
    WorkflowDefinition,
    load_workflow_definition,
    build_execution_plan,
    execute_workflow

Base.@kwdef struct WorkflowNode
    id::String
    name::String
    type::String
    execution_hint::Symbol
    config::Dict{String,Any}
    ports::Vector{PortSchema}
end

Base.@kwdef struct WorkflowConnection
    source_node_id::String
    source_port_id::String
    target_node_id::String
    target_port_id::String
    data_type::Symbol
end

Base.@kwdef struct WorkflowDefinition
    id::String
    name::String
    version::String
    nodes::Vector{WorkflowNode}
    connections::Vector{WorkflowConnection}
end

function parse_node(raw::Dict{String,Any})
    ports = [
        PortSchema(
            id = port["id"],
            direction = Symbol(port["direction"]),
            type = Symbol(port["type"]),
        ) for port in raw["ports"]
    ]
    return WorkflowNode(
        id = raw["id"],
        name = raw["name"],
        type = raw["type"],
        execution_hint = Symbol(raw["execution_hint"]),
        config = get(raw, "config", Dict{String,Any}()),
        ports = ports,
    )
end

function parse_connection(raw::Dict{String,Any})
    return WorkflowConnection(
        source_node_id = raw["source_node_id"],
        source_port_id = raw["source_port_id"],
        target_node_id = raw["target_node_id"],
        target_port_id = raw["target_port_id"],
        data_type = Symbol(raw["data_type"]),
    )
end

function load_workflow_definition(path::AbstractString)
    raw = TOML.parsefile(path)
    nodes = [parse_node(node) for node in raw["nodes"]]
    connections = [parse_connection(conn) for conn in raw["connections"]]
    return WorkflowDefinition(
        id = raw["workflow"]["id"],
        name = raw["workflow"]["name"],
        version = raw["version"],
        nodes = nodes,
        connections = connections,
    )
end

function build_execution_plan(workflow::WorkflowDefinition)
    in_degree = Dict(node.id => 0 for node in workflow.nodes)
    adjacency = Dict(node.id => String[] for node in workflow.nodes)

    for connection in workflow.connections
        push!(adjacency[connection.source_node_id], connection.target_node_id)
        in_degree[connection.target_node_id] += 1
    end

    ready = [node.id for node in workflow.nodes if in_degree[node.id] == 0]
    plan = String[]

    while !isempty(ready)
        current = popfirst!(ready)
        push!(plan, current)
        for target in adjacency[current]
            in_degree[target] -= 1
            if in_degree[target] == 0
                push!(ready, target)
            end
        end
    end

    length(plan) == length(workflow.nodes) || error("workflow contains cycle")
    return plan
end

function execute_workflow(workflow::WorkflowDefinition)
    plan = build_execution_plan(workflow)
    execution_id = uuid4()

    return Dict(
        "execution_id" => string(execution_id),
        "workflow_id" => workflow.id,
        "plan" => plan,
        "status" => "accepted",
        "mode" => "cpu_only",
    )
end

end

