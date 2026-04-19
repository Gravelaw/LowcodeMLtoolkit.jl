using Test
using UUIDs

include(joinpath(@__DIR__, "..", "src", "JuliaFlowBaseExtension.jl"))

using .JuliaFlowBaseExtension
using .JuliaFlowBaseExtension.JuliaFlowNodeSDK: NodeContext, PortSchema

@testset "JuliaFlow base extension" begin
    registry = available_nodes()
    @test haskey(registry, DEFAULT_NODE_KEY)
    @test haskey(registry, ARROW_TABLE_SOURCE_NODE_KEY)
    @test haskey(registry, ARROW_TABLE_SINK_NODE_KEY)
    @test haskey(registry, SELECT_COLUMNS_NODE_KEY)
    @test haskey(registry, LINEAR_MODEL_TRAINER_NODE_KEY)
    @test registry[DEFAULT_NODE_KEY] == ArrowPassthroughNode
    @test registry[ARROW_TABLE_SOURCE_NODE_KEY] == ArrowTableSourceNode
    @test registry[ARROW_TABLE_SINK_NODE_KEY] == ArrowTableSinkNode
    @test registry[SELECT_COLUMNS_NODE_KEY] == SelectColumnsNode
    @test registry[LINEAR_MODEL_TRAINER_NODE_KEY] == LinearModelTrainerNode

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

@testset "Arrow table source node" begin
    config = JuliaFlowBaseExtension.configure(
        ArrowTableSourceNode,
        Dict(
            "output_port_id" => "source_out",
            "ref" => "minio://wf/source.arrow",
            "schema_ref" => "schema://source/v1",
        ),
    )
    context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        config = config,
    )

    result = JuliaFlowBaseExtension.execute(ArrowTableSourceNode, context)
    schema = JuliaFlowBaseExtension.infer_output_schema(ArrowTableSourceNode, PortSchema[])

    @test result.outputs["source_out"].format == :arrow_ipc
    @test result.outputs["source_out"].ref == "minio://wf/source.arrow"
    @test result.outputs["source_out"].schema_ref == "schema://source/v1"
    @test result.telemetry["node_key"] == "base.arrow_table_source"
    @test only(schema).type == :data_table
end

@testset "Select columns node" begin
    config = JuliaFlowBaseExtension.configure(
        SelectColumnsNode,
        Dict(
            "input_port_id" => "table_in",
            "output_port_id" => "table_out",
            "columns" => ["feature_a", "feature_b"],
        ),
    )
    context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/features.arrow",
            ),
        ),
        config = config,
    )

    result = JuliaFlowBaseExtension.execute(SelectColumnsNode, context)
    schema = JuliaFlowBaseExtension.infer_output_schema(
        SelectColumnsNode,
        [PortSchema(id = "table_in", direction = :input, type = :data_table, label = "Feature Table")],
    )

    @test result.outputs["table_out"].selected_columns == ["feature_a", "feature_b"]
    @test result.telemetry["column_count"] == 2
    @test result.warnings == ["placeholder transform forwards the original Arrow ref"]
    @test only(schema).label == "Feature Table"
end

@testset "Arrow table sink node" begin
    config = JuliaFlowBaseExtension.configure(
        ArrowTableSinkNode,
        Dict(
            "input_port_id" => "table_in",
            "destination_uri" => "warehouse://gold/demo.arrow",
            "mode" => "append",
        ),
    )
    context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/features.arrow",
            ),
        ),
        config = config,
    )

    result = JuliaFlowBaseExtension.execute(ArrowTableSinkNode, context)

    @test isempty(result.outputs)
    @test result.telemetry["destination_uri"] == "warehouse://gold/demo.arrow"
    @test result.telemetry["mode"] == "append"
    @test result.warnings == ["placeholder sink does not persist data yet"]
end

@testset "Linear model trainer node" begin
    execution_id = uuid4()
    node_id = uuid4()
    config = JuliaFlowBaseExtension.configure(
        LinearModelTrainerNode,
        Dict(
            "input_port_id" => "table_in",
            "output_port_id" => "model_out",
            "target_column" => "sale_price",
            "feature_columns" => ["sqft", "bedrooms"],
        ),
    )
    context = NodeContext(
        workflow_id = uuid4(),
        execution_id = execution_id,
        node_id = node_id,
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/training.arrow",
            ),
        ),
        config = config,
    )

    result = JuliaFlowBaseExtension.execute(LinearModelTrainerNode, context)
    schema = JuliaFlowBaseExtension.infer_output_schema(LinearModelTrainerNode, PortSchema[])

    @test result.outputs["model_out"].format == :juliaflow_model_stub
    @test result.outputs["model_out"].trained_from_ref == "memory://wf/training.arrow"
    @test result.outputs["model_out"].ref == "memory://models/$(execution_id)/$(node_id)"
    @test result.outputs["model_out"].feature_columns == ["sqft", "bedrooms"]
    @test result.telemetry["algorithm"] == "linear_regression"
    @test result.warnings == ["placeholder trainer emits model metadata only"]
    @test only(schema).type == :model
end
