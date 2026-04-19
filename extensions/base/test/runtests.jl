using Test
using UUIDs

include(joinpath(@__DIR__, "..", "src", "JuliaFlowBaseExtension.jl"))

using .JuliaFlowBaseExtension
using .JuliaFlowBaseExtension.JuliaFlowNodeSDK: NodeContext, PortSchema

@testset "JuliaFlow base extension" begin
    registry = available_nodes()
    @test haskey(registry, DEFAULT_NODE_KEY)
    @test registry[DEFAULT_NODE_KEY] == ArrowPassthroughNode

    config = JuliaFlowBaseExtension.configure(
        ArrowPassthroughNode,
        Dict("input_port_id" => "table_in", "output_port_id" => "table_out"),
    )
    context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "minio://wf/demo.arrow",
                schema_ref = "schema://demo/v1",
            ),
        ),
        config = config,
    )

    result = JuliaFlowBaseExtension.execute(ArrowPassthroughNode, context)
    schema = JuliaFlowBaseExtension.infer_output_schema(
        ArrowPassthroughNode,
        [PortSchema(id = "table_in", direction = :input, type = :data_table, label = "Demo Table")],
    )

    @test result.outputs["table_out"].format == :arrow_ipc
    @test result.outputs["table_out"].ref == "minio://wf/demo.arrow"
    @test result.telemetry["node_key"] == "base.arrow_passthrough"
    @test only(schema).type == :data_table
    @test only(schema).label == "Demo Table"
end
