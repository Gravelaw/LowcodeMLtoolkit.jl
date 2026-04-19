module JuliaFlowBaseExtension

include(joinpath(@__DIR__, "..", "..", "..", "services", "node-sdk", "src", "JuliaFlowNodeSDK.jl"))
using .JuliaFlowNodeSDK
using UUIDs

include(joinpath(@__DIR__, "nodes", "ArrowPassthroughNode.jl"))
include(joinpath(@__DIR__, "nodes", "ArrowTableSourceNode.jl"))
include(joinpath(@__DIR__, "nodes", "ArrowTableSinkNode.jl"))
include(joinpath(@__DIR__, "nodes", "SelectColumnsNode.jl"))
include(joinpath(@__DIR__, "nodes", "LinearModelTrainerNode.jl"))

const DEFAULT_NODE_KEY = "base.arrow_passthrough"
const ARROW_TABLE_SOURCE_NODE_KEY = "base.arrow_table_source"
const ARROW_TABLE_SINK_NODE_KEY = "base.arrow_table_sink"
const SELECT_COLUMNS_NODE_KEY = "base.select_columns"
const LINEAR_MODEL_TRAINER_NODE_KEY = "base.linear_model_trainer"
const NODE_REGISTRY = Dict(
    DEFAULT_NODE_KEY => ArrowPassthroughNode,
    ARROW_TABLE_SOURCE_NODE_KEY => ArrowTableSourceNode,
    ARROW_TABLE_SINK_NODE_KEY => ArrowTableSinkNode,
    SELECT_COLUMNS_NODE_KEY => SelectColumnsNode,
    LINEAR_MODEL_TRAINER_NODE_KEY => LinearModelTrainerNode,
)

export ArrowPassthroughNode,
    ArrowTableSourceNode,
    ArrowTableSinkNode,
    SelectColumnsNode,
    LinearModelTrainerNode,
    DEFAULT_INPUT_PORT_ID,
    DEFAULT_OUTPUT_PORT_ID,
    DEFAULT_NODE_KEY,
    ARROW_TABLE_SOURCE_NODE_KEY,
    ARROW_TABLE_SINK_NODE_KEY,
    SELECT_COLUMNS_NODE_KEY,
    LINEAR_MODEL_TRAINER_NODE_KEY,
    SOURCE_OUTPUT_PORT_ID,
    SINK_INPUT_PORT_ID,
    SELECT_COLUMNS_INPUT_PORT_ID,
    SELECT_COLUMNS_OUTPUT_PORT_ID,
    TRAINER_INPUT_PORT_ID,
    TRAINER_OUTPUT_PORT_ID,
    available_nodes,
    execute_passthrough

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
