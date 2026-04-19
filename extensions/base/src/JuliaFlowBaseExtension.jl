module JuliaFlowBaseExtension

include(joinpath(@__DIR__, "..", "..", "..", "services", "node-sdk", "src", "JuliaFlowNodeSDK.jl"))
using .JuliaFlowNodeSDK
using UUIDs

include(joinpath(@__DIR__, "nodes", "ArrowPassthroughNode.jl"))

const DEFAULT_NODE_KEY = "base.arrow_passthrough"
const NODE_REGISTRY = Dict(DEFAULT_NODE_KEY => ArrowPassthroughNode)

export ArrowPassthroughNode, DEFAULT_INPUT_PORT_ID, DEFAULT_OUTPUT_PORT_ID, DEFAULT_NODE_KEY, available_nodes, execute_passthrough

function available_nodes()
    return copy(NODE_REGISTRY)
end

function execute_passthrough(input_ref::String)
    config = configure(
        ArrowPassthroughNode,
        Dict("input_port_id" => DEFAULT_INPUT_PORT_ID, "output_port_id" => DEFAULT_OUTPUT_PORT_ID),
    )
    ctx = NodeContext(
        workflow_id = UUID("11111111-1111-1111-1111-111111111111"),
        execution_id = UUID("22222222-2222-2222-2222-222222222222"),
        node_id = UUID("33333333-3333-3333-3333-333333333333"),
        inputs = Dict(DEFAULT_INPUT_PORT_ID => (format = :arrow_ipc, ref = input_ref)),
        config = config,
    )
    return execute(ArrowPassthroughNode, ctx)
end

end
