using Test
using UUIDs
using JSON3
using Arrow
using DataFrames
using Base64

include(joinpath(@__DIR__, "..", "src", "JuliaFlowBaseExtension.jl"))

using .JuliaFlowBaseExtension
using .JuliaFlowBaseExtension.JuliaFlowNodeSDK: NodeContext, PortSchema

const SAMPLE_ROWS = [
    Dict("region" => "west", "month" => "2026-01", "amount" => 120.0, "feature_a" => 1.0, "feature_b" => 10.0, "sale_price" => 210.0),
    Dict("region" => "west", "month" => "2026-01", "amount" => 80.0, "feature_a" => 2.0, "feature_b" => 20.0, "sale_price" => 420.0),
    Dict("region" => "east", "month" => "2026-02", "amount" => 200.0, "feature_a" => 3.0, "feature_b" => 30.0, "sale_price" => 630.0),
]

const CLEANUP_ROWS = [
    Dict("customer" => "  Acme Corp  ", "status" => "New", "sku" => "SKU-100", "amount" => 10.0, "region" => "west"),
    Dict("customer" => "Beta LLC ", "status" => "new", "sku" => "SKU-200", "amount" => 30.0, "region" => "west"),
    Dict("customer" => " gamma inc", "status" => "old", "sku" => "SKU-300", "amount" => 20.0, "region" => "east"),
]

@testset "JuliaFlow base extension" begin
    registry = available_nodes()
    @test haskey(registry, DEFAULT_NODE_KEY)
    @test haskey(registry, ARROW_TABLE_SOURCE_NODE_KEY)
    @test haskey(registry, ARROW_TABLE_SINK_NODE_KEY)
    @test haskey(registry, SELECT_COLUMNS_NODE_KEY)
    @test haskey(registry, LINEAR_MODEL_TRAINER_NODE_KEY)
    @test haskey(registry, FILTER_ROWS_NODE_KEY)
    @test haskey(registry, AGGREGATE_ROWS_NODE_KEY)
    @test registry[DEFAULT_NODE_KEY] == ArrowPassthroughNode
    @test registry[ARROW_TABLE_SOURCE_NODE_KEY] == ArrowTableSourceNode
    @test registry[ARROW_TABLE_SINK_NODE_KEY] == ArrowTableSinkNode
    @test registry[SELECT_COLUMNS_NODE_KEY] == SelectColumnsNode
    @test registry[LINEAR_MODEL_TRAINER_NODE_KEY] == LinearModelTrainerNode
    @test registry[FILTER_ROWS_NODE_KEY] == FilterRowsNode
    @test registry[AGGREGATE_ROWS_NODE_KEY] == AggregateRowsNode

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
    @test result.telemetry["materialized"] == false
    @test only(schema).type == :data_table

    dir = mktempdir()
    target_path = joinpath(dir, "warehouse", "gold", "demo.arrow")
    mkpath(dirname(target_path))
    write(target_path, JSON3.write(Dict("rows" => SAMPLE_ROWS)))
    object_config = JuliaFlowBaseExtension.configure(
        ArrowTableSourceNode,
        Dict("output_port_id" => "source_out", "ref" => "warehouse://gold/demo.arrow"),
    )
    object_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        config = object_config,
        metadata = Dict{String,Any}("object_store_root" => dir),
    )
    object_result = JuliaFlowBaseExtension.execute(ArrowTableSourceNode, object_context)
    @test object_result.outputs["source_out"].row_count == 3
    @test object_result.outputs["source_out"].materialized == true
    @test object_result.telemetry["materialized"] == true

    adapter_ref = "object://prod/sales.arrow"
    adapter_config = JuliaFlowBaseExtension.configure(
        ArrowTableSourceNode,
        Dict("output_port_id" => "source_out", "ref" => adapter_ref),
    )
    adapter_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        config = adapter_config,
        metadata = Dict{String,Any}(
            "tabular_ref_reader" => (ref, _context) -> begin
                @test ref == adapter_ref
                return (rows = SAMPLE_ROWS, schema = ["region", "amount"], adapter = "arrow_dataframe_reader")
            end,
        ),
    )
    adapter_result = JuliaFlowBaseExtension.execute(ArrowTableSourceNode, adapter_context)
    @test adapter_result.outputs["source_out"].format == :arrow_ipc
    @test adapter_result.outputs["source_out"].ref == adapter_ref
    @test adapter_result.outputs["source_out"].schema == ["region", "amount"]
    @test adapter_result.outputs["source_out"].row_count == 3
    @test adapter_result.telemetry["materialization_adapter"] == "arrow_dataframe_reader"

    registry_ref = "object://prod/registry-sales.arrow"
    registry_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        config = JuliaFlowBaseExtension.configure(ArrowTableSourceNode, Dict("output_port_id" => "source_out", "ref" => registry_ref)),
        metadata = Dict{String,Any}(
            "tabular_adapter_name" => "service_arrow",
            "tabular_adapter_registry" => Dict(
                "service_arrow" => Dict(
                    "name" => "service_arrow_adapter",
                    "schemes" => ["object://"],
                    "reader" => (ref, _context) -> begin
                        @test ref == registry_ref
                        return Dict("rows" => SAMPLE_ROWS, "schema" => ["region", "amount"])
                    end,
                ),
            ),
        ),
    )
    registry_result = JuliaFlowBaseExtension.execute(ArrowTableSourceNode, registry_context)
    @test registry_result.outputs["source_out"].format == :arrow_ipc
    @test registry_result.outputs["source_out"].ref == registry_ref
    @test registry_result.outputs["source_out"].row_count == 3
    @test registry_result.outputs["source_out"].schema == ["region", "amount"]
    @test registry_result.telemetry["materialization_adapter"] == "service_arrow_adapter"
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
                rows = SAMPLE_ROWS,
            ),
        ),
        config = config,
    )

    result = JuliaFlowBaseExtension.execute(SelectColumnsNode, context)
    schema = JuliaFlowBaseExtension.infer_output_schema(
        SelectColumnsNode,
        [PortSchema(id = "table_in", direction = :input, type = :data_table, label = "Feature Table")],
    )

    @test result.outputs["table_out"].materialized == true
    @test result.outputs["table_out"].schema == ["feature_a", "feature_b"]
    @test result.outputs["table_out"].rows == [
        Dict("feature_a" => 1.0, "feature_b" => 10.0),
        Dict("feature_a" => 2.0, "feature_b" => 20.0),
        Dict("feature_a" => 3.0, "feature_b" => 30.0),
    ]
    @test result.telemetry["column_count"] == 2
    @test result.telemetry["materialized"] == true
    @test isempty(result.warnings)
    @test only(schema).label == "Feature Table"
end

@testset "Filter rows node" begin
    config = JuliaFlowBaseExtension.configure(
        FilterRowsNode,
        Dict(
            "input_port_id" => "table_in",
            "output_port_id" => "table_out",
            "predicate" => "amount > 100",
        ),
    )
    context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/sales.arrow",
                rows = SAMPLE_ROWS,
            ),
        ),
        config = config,
    )

    result = JuliaFlowBaseExtension.execute(FilterRowsNode, context)
    schema = JuliaFlowBaseExtension.infer_output_schema(
        FilterRowsNode,
        [PortSchema(id = "table_in", direction = :input, type = :data_table, label = "Sales Table")],
    )

    @test result.outputs["table_out"].materialized == true
    @test result.outputs["table_out"].row_count == 2
    @test [row["amount"] for row in result.outputs["table_out"].rows] == [120.0, 200.0]
    @test result.telemetry["node_key"] == "base.filter_rows"
    @test result.telemetry["materialized"] == true
    @test isempty(result.warnings)
    @test only(schema).label == "Sales Table"
end

@testset "Aggregate rows node" begin
    config = JuliaFlowBaseExtension.configure(
        AggregateRowsNode,
        Dict(
            "input_port_id" => "table_in",
            "output_port_id" => "table_out",
            "aggregation" => "sum",
            "value_column" => "amount",
            "group_by" => ["region", "month"],
        ),
    )
    context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/sales.arrow",
                rows = SAMPLE_ROWS,
            ),
        ),
        config = config,
    )

    result = JuliaFlowBaseExtension.execute(AggregateRowsNode, context)
    schema = JuliaFlowBaseExtension.infer_output_schema(
        AggregateRowsNode,
        [PortSchema(id = "table_in", direction = :input, type = :data_table, label = "Sales Table")],
    )

    @test result.outputs["table_out"].materialized == true
    @test result.outputs["table_out"].schema == ["region", "month", "sum_amount"]
    @test result.outputs["table_out"].rows == [
        Dict("region" => "east", "month" => "2026-02", "sum_amount" => 200.0),
        Dict("region" => "west", "month" => "2026-01", "sum_amount" => 200.0),
    ]
    @test result.telemetry["node_key"] == "base.aggregate_rows"
    @test result.telemetry["group_by_count"] == 2
    @test result.telemetry["materialized"] == true
    @test isempty(result.warnings)
    @test only(schema).label == "Sales Table"
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
    @test result.warnings == ["arrow_table_sink requires materialized rows for persistence"]

    dir = mktempdir()
    persisted_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/features.arrow",
                rows = SAMPLE_ROWS,
            ),
        ),
        config = config,
        metadata = Dict{String,Any}("object_store_root" => dir),
    )
    persisted = JuliaFlowBaseExtension.execute(ArrowTableSinkNode, persisted_context)
    @test persisted.telemetry["persisted"] == true
    @test persisted.telemetry["row_count"] == 3
    @test persisted.telemetry["written_row_count"] == 3
    @test isempty(persisted.warnings)
    persisted_path = persisted.telemetry["persisted_path"]
    @test isfile(persisted_path)
    raw = JSON3.read(read(persisted_path, String), Dict{String,Any})
    @test length(raw["rows"]) == 3

    append_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/features.arrow",
                rows = [Dict("region" => "north", "amount" => 9.0)],
            ),
        ),
        config = config,
        metadata = Dict{String,Any}("object_store_root" => dir),
    )
    appended = JuliaFlowBaseExtension.execute(ArrowTableSinkNode, append_context)
    @test appended.telemetry["row_count"] == 4
    @test appended.telemetry["written_row_count"] == 1
    appended_raw = JSON3.read(read(persisted_path, String), Dict{String,Any})
    @test length(appended_raw["rows"]) == 4

    writer_calls = Ref{Any}(nothing)
    writer_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/features.arrow",
                rows = SAMPLE_ROWS,
            ),
        ),
        config = config,
        metadata = Dict{String,Any}(
            "tabular_ref_writer" => (destination_uri, rows, _context) -> begin
                writer_calls[] = (destination_uri = destination_uri, rows = rows)
                return (ref = destination_uri, row_count = length(rows), adapter = "arrow_dataframe_writer")
            end,
        ),
    )
    writer_persisted = JuliaFlowBaseExtension.execute(ArrowTableSinkNode, writer_context)
    @test writer_calls[].destination_uri == "warehouse://gold/demo.arrow"
    @test length(writer_calls[].rows) == 3
    @test writer_persisted.telemetry["persisted"] == true
    @test writer_persisted.telemetry["persistence_adapter"] == "arrow_dataframe_writer"
    @test writer_persisted.telemetry["persisted_ref"] == "warehouse://gold/demo.arrow"
    @test writer_persisted.telemetry["row_count"] == 3
    @test isempty(writer_persisted.warnings)

    registry_writer_calls = Ref{Any}(nothing)
    registry_writer_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/features.arrow",
                rows = SAMPLE_ROWS,
            ),
        ),
        config = config,
        metadata = Dict{String,Any}(
            "tabular_adapter_name" => "warehouse_service",
            "tabular_adapter_registry" => Dict(
                "warehouse_service" => Dict(
                    "adapter" => "warehouse_service_adapter",
                    "supported_schemes" => ["warehouse://"],
                    "writer" => (destination_uri, rows, _context) -> begin
                        registry_writer_calls[] = (destination_uri = destination_uri, rows = rows)
                        return Dict("ref" => destination_uri, "row_count" => length(rows))
                    end,
                ),
            ),
        ),
    )
    registry_writer = JuliaFlowBaseExtension.execute(ArrowTableSinkNode, registry_writer_context)
    @test registry_writer_calls[].destination_uri == "warehouse://gold/demo.arrow"
    @test registry_writer.telemetry["persisted"] == true
    @test registry_writer.telemetry["persistence_adapter"] == "warehouse_service_adapter"
    @test registry_writer.telemetry["persisted_ref"] == "warehouse://gold/demo.arrow"
    @test registry_writer.telemetry["row_count"] == 3
    @test isempty(registry_writer.warnings)

    unsupported_registry_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/features.arrow",
                rows = SAMPLE_ROWS,
            ),
        ),
        config = config,
        metadata = Dict{String,Any}(
            "tabular_adapter_name" => "object_only",
            "tabular_adapter_registry" => Dict(
                "object_only" => Dict(
                    "schemes" => ["object://"],
                    "writer" => (_destination_uri, _rows, _context) -> error("wrong adapter called"),
                ),
            ),
        ),
    )
    unsupported_registry = JuliaFlowBaseExtension.execute(ArrowTableSinkNode, unsupported_registry_context)
    @test !haskey(unsupported_registry.telemetry, "persisted")
    @test unsupported_registry.warnings == ["arrow_table_sink requires tabular_ref_writer, tabular_ref_root, or object_store_root for persistence"]

    nothing_writer_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/features.arrow",
                rows = SAMPLE_ROWS,
            ),
        ),
        config = config,
        metadata = Dict{String,Any}(
            "tabular_ref_writer" => (_destination_uri, _rows, _context) -> nothing,
        ),
    )
    nothing_writer = JuliaFlowBaseExtension.execute(ArrowTableSinkNode, nothing_writer_context)
    @test !haskey(nothing_writer.telemetry, "persisted")
    @test nothing_writer.warnings == ["arrow_table_sink requires tabular_ref_writer, tabular_ref_root, or object_store_root for persistence"]

    traversal_config = JuliaFlowBaseExtension.configure(
        ArrowTableSinkNode,
        Dict(
            "input_port_id" => "table_in",
            "destination_uri" => "warehouse://../../escape.arrow",
            "mode" => "overwrite",
        ),
    )
    traversal_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/features.arrow",
                rows = SAMPLE_ROWS,
            ),
        ),
        config = traversal_config,
        metadata = Dict{String,Any}("object_store_root" => mktempdir()),
    )
    @test_throws ErrorException JuliaFlowBaseExtension.execute(ArrowTableSinkNode, traversal_context)

    raw_traversal_config = JuliaFlowBaseExtension.configure(
        ArrowTableSinkNode,
        Dict(
            "input_port_id" => "table_in",
            "destination_uri" => "../../escape.arrow",
            "mode" => "overwrite",
        ),
    )
    raw_traversal_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (
                format = :arrow_ipc,
                ref = "memory://wf/features.arrow",
                rows = SAMPLE_ROWS,
            ),
        ),
        config = raw_traversal_config,
        metadata = Dict{String,Any}("object_store_root" => mktempdir()),
    )
    @test_throws ErrorException JuliaFlowBaseExtension.execute(ArrowTableSinkNode, raw_traversal_context)

    symlink_dir = mktempdir()
    outside_file = tempname()
    write(outside_file, "outside")
    try
        symlink(outside_file, joinpath(symlink_dir, "sink.json"))
        symlink_sink_context = NodeContext(
            workflow_id = uuid4(),
            execution_id = uuid4(),
            node_id = uuid4(),
            inputs = Dict(
                "table_in" => (
                    format = :arrow_ipc,
                    ref = "memory://wf/features.arrow",
                    rows = SAMPLE_ROWS,
                ),
            ),
            config = JuliaFlowBaseExtension.configure(
                ArrowTableSinkNode,
                Dict("input_port_id" => "table_in", "destination_uri" => "sink.json", "mode" => "overwrite"),
            ),
            metadata = Dict{String,Any}("object_store_root" => symlink_dir),
        )
        @test_throws ErrorException JuliaFlowBaseExtension.execute(ArrowTableSinkNode, symlink_sink_context)
        @test read(outside_file, String) == "outside"

        outside_dir = mktempdir()
        symlink(outside_dir, joinpath(symlink_dir, "linked_dir"))
        parent_symlink_context = NodeContext(
            workflow_id = uuid4(),
            execution_id = uuid4(),
            node_id = uuid4(),
            inputs = Dict(
                "table_in" => (
                    format = :arrow_ipc,
                    ref = "memory://wf/features.arrow",
                    rows = SAMPLE_ROWS,
                ),
            ),
            config = JuliaFlowBaseExtension.configure(
                ArrowTableSinkNode,
                Dict("input_port_id" => "table_in", "destination_uri" => "linked_dir/escape.json", "mode" => "overwrite"),
            ),
            metadata = Dict{String,Any}("object_store_root" => symlink_dir),
        )
        @test_throws ErrorException JuliaFlowBaseExtension.execute(ArrowTableSinkNode, parent_symlink_context)
        @test !isfile(joinpath(outside_dir, "escape.json"))

        nested_symlink_context = NodeContext(
            workflow_id = uuid4(),
            execution_id = uuid4(),
            node_id = uuid4(),
            inputs = Dict(
                "table_in" => (
                    format = :arrow_ipc,
                    ref = "memory://wf/features.arrow",
                    rows = SAMPLE_ROWS,
                ),
            ),
            config = JuliaFlowBaseExtension.configure(
                ArrowTableSinkNode,
                Dict("input_port_id" => "table_in", "destination_uri" => "linked_dir/new/escape.json", "mode" => "overwrite"),
            ),
            metadata = Dict{String,Any}("object_store_root" => symlink_dir),
        )
        @test_throws ErrorException JuliaFlowBaseExtension.execute(ArrowTableSinkNode, nested_symlink_context)
        @test !isdir(joinpath(outside_dir, "new"))
        @test !isfile(joinpath(outside_dir, "new", "escape.json"))
    catch error
        error isa IOError || rethrow(error)
        @info "Skipping symlink sink rejection check on filesystem without symlink support"
    end
end

@testset "Executor dataflow helper runs base nodes" begin
    source_node = (
        id = "node-source",
        type = ARROW_TABLE_SOURCE_NODE_KEY,
        config = Dict("output_port_id" => "source_out", "ref" => "object://demo/source.arrow"),
    )
    filter_node = (
        id = "node-filter",
        type = FILTER_ROWS_NODE_KEY,
        config = Dict("input_port_id" => "table_in", "output_port_id" => "table_out", "predicate" => "amount >= 100"),
    )
    workflow = (
        id = string(uuid4()),
        nodes = [source_node, filter_node],
        connections = [
            (
                source_node_id = "node-source",
                source_port_id = "source_out",
                target_node_id = "node-filter",
                target_port_id = "table_in",
            ),
        ],
    )
    execution = (execution_id = string(uuid4()),)
    state = ExecutorDataflowState(
        metadata = Dict{String,Any}(
            "tabular_ref_reader" => (ref, _context) -> begin
                @test ref == "object://demo/source.arrow"
                return (rows = SAMPLE_ROWS, schema = ["region", "amount"], adapter = "executor_reader")
            end,
        ),
    )

    source_result = execute_executor_dataflow_node!(state, workflow, execution, "node-source")
    filter_result = execute_executor_dataflow_node!(state, workflow, execution, "node-filter")

    @test source_result["node_key"] == ARROW_TABLE_SOURCE_NODE_KEY
    @test source_result["row_count"] == 3
    @test haskey(state.outputs["node-source"], "source_out")
    @test filter_result["node_key"] == FILTER_ROWS_NODE_KEY
    @test filter_result["row_count"] == 2
    @test state.outputs["node-filter"]["table_out"].row_count == 2
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
            "feature_columns" => ["feature_a", "feature_b"],
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
                rows = SAMPLE_ROWS,
            ),
        ),
        config = config,
    )

    result = JuliaFlowBaseExtension.execute(LinearModelTrainerNode, context)
    schema = JuliaFlowBaseExtension.infer_output_schema(LinearModelTrainerNode, PortSchema[])

    @test result.outputs["model_out"].format == :juliaflow_model
    @test result.outputs["model_out"].trained_from_ref == "memory://wf/training.arrow"
    @test result.outputs["model_out"].ref == "memory://models/$(execution_id)/$(node_id)"
    @test result.outputs["model_out"].feature_columns == ["feature_a", "feature_b"]
    @test result.outputs["model_out"].row_count == 3
    @test isapprox(result.outputs["model_out"].coefficients["feature_a"], 210.0; atol = 1.0e-6)
    @test result.telemetry["algorithm"] == "linear_regression"
    @test result.telemetry["materialized"] == true
    @test isempty(result.warnings)
    @test only(schema).type == :model
end

function table_context(node_type, params; rows = SAMPLE_ROWS, extra_inputs = Dict{String,NamedTuple}())
    config = JuliaFlowBaseExtension.configure(node_type, params)
    inputs = Dict{String,NamedTuple}(
        "table_in" => (
            format = :arrow_ipc,
            ref = "memory://wf/tier1.arrow",
            rows = rows,
        ),
    )
    for (key, value) in pairs(extra_inputs)
        inputs[key] = value
    end
    return NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = inputs,
        config = config,
    )
end

@testset "External ref tabular materialization" begin
    store_ref = "object://warehouse/features.arrow"
    select_config = JuliaFlowBaseExtension.configure(
        SelectColumnsNode,
        Dict("input_port_id" => "table_in", "output_port_id" => "table_out", "columns" => ["region", "amount"]),
    )
    store_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict("table_in" => (format = :arrow_ipc, ref = store_ref)),
        config = select_config,
        metadata = Dict{String,Any}(
            "tabular_payload_store" => Dict(store_ref => (rows = SAMPLE_ROWS,)),
        ),
    )

    selected = JuliaFlowBaseExtension.execute(SelectColumnsNode, store_context)

    @test selected.outputs["table_out"].materialized == true
    @test selected.outputs["table_out"].source_ref == store_ref
    @test selected.outputs["table_out"].row_count == 3
    @test selected.outputs["table_out"].rows[1] == Dict("region" => "west", "amount" => 120.0)
    @test isempty(selected.warnings)

    dir = mktempdir()
    json_path = joinpath(dir, "sales.json")
    write(
        json_path,
        """{"rows":[{"region":"north","amount":50},{"region":"south","amount":175}]}""",
    )
    filter_config = JuliaFlowBaseExtension.configure(
        FilterRowsNode,
        Dict("input_port_id" => "table_in", "output_port_id" => "table_out", "predicate" => "amount >= 100"),
    )
    file_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict("table_in" => (format = :arrow_ipc, ref = "file://sales.json")),
        config = filter_config,
        metadata = Dict{String,Any}("tabular_ref_root" => dir, "allow_file_refs" => true),
    )

    filtered = JuliaFlowBaseExtension.execute(FilterRowsNode, file_context)

    @test filtered.outputs["table_out"].materialized == true
    @test filtered.outputs["table_out"].row_count == 1
    @test only(filtered.outputs["table_out"].rows)["region"] == "south"
    @test isempty(filtered.warnings)

    denied_file_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict("table_in" => (format = :arrow_ipc, ref = "file://sales.json")),
        config = filter_config,
        metadata = Dict{String,Any}("tabular_ref_root" => dir),
    )
    @test_throws ErrorException JuliaFlowBaseExtension.execute(FilterRowsNode, denied_file_context)

    escape_file_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict("table_in" => (format = :arrow_ipc, ref = "file:///etc/passwd")),
        config = filter_config,
        metadata = Dict{String,Any}("tabular_ref_root" => dir, "allow_file_refs" => true),
    )
    @test_throws ErrorException JuliaFlowBaseExtension.execute(FilterRowsNode, escape_file_context)

    symlink_path = joinpath(dir, "linked.json")
    try
        symlink("/etc/passwd", symlink_path)
        symlink_context = NodeContext(
            workflow_id = uuid4(),
            execution_id = uuid4(),
            node_id = uuid4(),
            inputs = Dict("table_in" => (format = :arrow_ipc, ref = "file://linked.json")),
            config = filter_config,
            metadata = Dict{String,Any}("tabular_ref_root" => dir, "allow_file_refs" => true),
        )
        @test_throws ErrorException JuliaFlowBaseExtension.execute(FilterRowsNode, symlink_context)
    catch error
        error isa IOError || rethrow(error)
        @info "Skipping symlink read rejection check on filesystem without symlink support"
    end

    small_limit_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict("table_in" => (format = :arrow_ipc, ref = "file://sales.json")),
        config = filter_config,
        metadata = Dict{String,Any}("tabular_ref_root" => dir, "allow_file_refs" => true, "max_ref_bytes" => 4),
    )
    @test_throws ErrorException JuliaFlowBaseExtension.execute(FilterRowsNode, small_limit_context)

end

@testset "Tier-1 table node registry" begin
    registry = available_nodes()
    @test length(registry) == 150
    for key in [
        RENAME_COLUMNS_NODE_KEY,
        CAST_COLUMNS_NODE_KEY,
        FILL_MISSING_NODE_KEY,
        DROP_MISSING_NODE_KEY,
        SORT_ROWS_NODE_KEY,
        LIMIT_ROWS_NODE_KEY,
        SAMPLE_ROWS_NODE_KEY,
        DISTINCT_ROWS_NODE_KEY,
        ADD_CONSTANT_COLUMN_NODE_KEY,
        ROW_NUMBER_NODE_KEY,
        CONCAT_ROWS_NODE_KEY,
        INNER_JOIN_ROWS_NODE_KEY,
        BASIC_STATS_NODE_KEY,
        TABLE_PROFILE_NODE_KEY,
        SPLIT_ROWS_NODE_KEY,
        DERIVE_RATIO_NODE_KEY,
        BUCKETIZE_ROWS_NODE_KEY,
        BI_OUTLET_NODE_KEY,
        TRIM_STRINGS_NODE_KEY,
        NORMALIZE_CASE_NODE_KEY,
        REPLACE_VALUES_NODE_KEY,
        REGEX_EXTRACT_NODE_KEY,
        VALIDATE_SCHEMA_NODE_KEY,
        TOP_N_ROWS_NODE_KEY,
        GROUP_FILTER_NODE_KEY,
        ROLLING_MEAN_NODE_KEY,
        RANK_ROWS_NODE_KEY,
        PERCENTILE_ROWS_NODE_KEY,
        COALESCE_COLUMNS_NODE_KEY,
        CLIP_VALUES_NODE_KEY,
        CUMULATIVE_SUM_NODE_KEY,
        ROLLING_SUM_NODE_KEY,
        LAG_COLUMN_NODE_KEY,
        STRING_CONTAINS_FILTER_NODE_KEY,
        COLUMN_MATH_NODE_KEY,
        NULL_IF_NODE_KEY,
        MIN_MAX_SCALE_NODE_KEY,
        Z_SCORE_NODE_KEY,
        LEFT_JOIN_ROWS_NODE_KEY,
        ANTI_JOIN_ROWS_NODE_KEY,
        UNION_DISTINCT_ROWS_NODE_KEY,
        UNPIVOT_ROWS_NODE_KEY,
        PIVOT_ROWS_NODE_KEY,
        DEDUPE_BY_KEY_NODE_KEY,
        VALUE_COUNTS_NODE_KEY,
        MISSINGNESS_SUMMARY_NODE_KEY,
        PARSE_DATE_NODE_KEY,
        DATE_BUCKET_NODE_KEY,
        DATE_PARTS_NODE_KEY,
        SPLIT_COLUMN_NODE_KEY,
        TOP_N_PER_GROUP_NODE_KEY,
        WEIGHTED_AVERAGE_NODE_KEY,
        GROUP_ROW_NUMBER_NODE_KEY,
        MOVING_MIN_NODE_KEY,
        MOVING_MAX_NODE_KEY,
        CUMULATIVE_COUNT_NODE_KEY,
        RIGHT_JOIN_ROWS_NODE_KEY,
        FULL_JOIN_ROWS_NODE_KEY,
        SEMI_JOIN_ROWS_NODE_KEY,
        LOOKUP_ENRICH_NODE_KEY,
        METRIC_DEFINITION_NODE_KEY,
        DIMENSION_MAPPING_NODE_KEY,
        KPI_THRESHOLD_NODE_KEY,
        CHART_DATASET_NODE_KEY,
        BOOLEAN_FLAG_NODE_KEY,
        TYPE_PROFILE_NODE_KEY,
        ROW_HASH_NODE_KEY,
        NORMALIZE_WHITESPACE_NODE_KEY,
        DROP_COLUMNS_NODE_KEY,
        KEEP_COLUMNS_MATCHING_NODE_KEY,
        COPY_COLUMN_NODE_KEY,
        CONCAT_COLUMNS_NODE_KEY,
        SUBSTRING_COLUMN_NODE_KEY,
        STRING_LENGTH_NODE_KEY,
        REGEX_REPLACE_NODE_KEY,
        ROUND_NUMBER_NODE_KEY,
        ABSOLUTE_VALUE_NODE_KEY,
        LOG_TRANSFORM_NODE_KEY,
        PERCENT_CHANGE_NODE_KEY,
        LEAD_COLUMN_NODE_KEY,
        CUMULATIVE_MEAN_NODE_KEY,
        GROUP_SUM_NODE_KEY,
        GROUP_MEAN_NODE_KEY,
        GROUP_MIN_NODE_KEY,
        GROUP_MAX_NODE_KEY,
        GROUP_COUNT_NODE_KEY,
        GROUP_PERCENT_OF_TOTAL_NODE_KEY,
        BUCKET_BY_THRESHOLDS_NODE_KEY,
        QUANTILE_BUCKET_NODE_KEY,
        ONE_HOT_ENCODE_NODE_KEY,
        METRIC_CARDS_NODE_KEY,
        DASHBOARD_SUMMARY_NODE_KEY,
        ROWS_TO_COLUMNS_NODE_KEY,
        CORRELATION_NODE_KEY,
        COVARIANCE_NODE_KEY,
        HISTOGRAM_NODE_KEY,
        OUTLIER_FLAG_NODE_KEY,
        STANDARDIZE_COLUMNS_NODE_KEY,
        TRAIN_TEST_SPLIT_NODE_KEY,
        LINEAR_SCORE_NODE_KEY,
        CLASSIFICATION_THRESHOLD_NODE_KEY,
        CONFUSION_MATRIX_NODE_KEY,
        REGRESSION_METRICS_NODE_KEY,
        KMEANS_ASSIGN_NODE_KEY,
        PCA_PROJECT_NODE_KEY,
        EVENT_TIME_ASSIGN_NODE_KEY,
        WATERMARK_FLAG_NODE_KEY,
        TUMBLING_WINDOW_NODE_KEY,
        SLIDING_WINDOW_NODE_KEY,
        STREAM_AGGREGATE_NODE_KEY,
        DEDUPE_EVENT_ID_NODE_KEY,
        SINK_TRANSACTION_MARKER_NODE_KEY,
        EXTENSION_MANIFEST_VALIDATE_NODE_KEY,
        COMPATIBILITY_REPORT_NODE_KEY,
        PACKAGE_HASH_VERIFY_NODE_KEY,
        OBJECT_STORE_LIST_NODE_KEY,
        DATASET_VERSION_NODE_KEY,
        SCHEMA_DRIFT_NODE_KEY,
        COLUMN_PRESENCE_NODE_KEY,
        NULL_RATE_NODE_KEY,
        DUPLICATE_RATE_NODE_KEY,
        CARDINALITY_NODE_KEY,
        COLUMN_SELECT_BY_TYPE_NODE_KEY,
        TIME_SINCE_PREVIOUS_NODE_KEY,
        SESSIONIZE_EVENTS_NODE_KEY,
        WINDOW_LAG_DELTA_NODE_KEY,
        ROLLING_STD_NODE_KEY,
        EXPANDING_MAX_NODE_KEY,
        CROSS_JOIN_ROWS_NODE_KEY,
        APPEND_METADATA_NODE_KEY,
        MASK_COLUMN_NODE_KEY,
        TOKENIZE_COLUMN_NODE_KEY,
        EXPLODE_LIST_NODE_KEY,
        JSON_EXTRACT_FIELD_NODE_KEY,
        DATASET_LINEAGE_NODE_KEY,
        POLICY_TAG_NODE_KEY,
        ACCESS_DECISION_NODE_KEY,
        GPU_CAPABILITY_FLAG_NODE_KEY,
        BATCH_ID_ASSIGN_NODE_KEY,
        REPLAY_OFFSET_NODE_KEY,
        EXACTLY_ONCE_KEY_NODE_KEY,
        SINK_COMMIT_PLAN_NODE_KEY,
        FEATURE_VECTOR_NODE_KEY,
    ]
        @test haskey(registry, key)
    end
end

@testset "Tier-1 table nodes materialize rows" begin
    renamed = JuliaFlowBaseExtension.execute(
        RenameColumnsNode,
        table_context(RenameColumnsNode, Dict("mapping" => Dict("amount" => "sales_amount"))),
    )
    @test haskey(first(renamed.outputs["table_out"].rows), "sales_amount")

    casted = JuliaFlowBaseExtension.execute(
        CastColumnsNode,
        table_context(CastColumnsNode, Dict("casts" => Dict("amount" => "int"))),
    )
    @test first(casted.outputs["table_out"].rows)["amount"] isa Int

    missing_rows = [
        Dict("id" => 1, "amount" => missing),
        Dict("id" => 2, "amount" => 3.0),
    ]
    filled = JuliaFlowBaseExtension.execute(
        FillMissingNode,
        table_context(FillMissingNode, Dict("fill_values" => Dict("amount" => 0.0)); rows = missing_rows),
    )
    @test first(filled.outputs["table_out"].rows)["amount"] == 0.0

    dropped = JuliaFlowBaseExtension.execute(
        DropMissingNode,
        table_context(DropMissingNode, Dict("columns" => ["amount"]); rows = missing_rows),
    )
    @test dropped.outputs["table_out"].row_count == 1

    sorted = JuliaFlowBaseExtension.execute(
        SortRowsNode,
        table_context(SortRowsNode, Dict("column" => "amount", "descending" => true)),
    )
    @test first(sorted.outputs["table_out"].rows)["amount"] == 200.0

    limited = JuliaFlowBaseExtension.execute(
        LimitRowsNode,
        table_context(LimitRowsNode, Dict("limit" => 1, "offset" => 1)),
    )
    @test only(limited.outputs["table_out"].rows)["amount"] == 80.0

    sampled = JuliaFlowBaseExtension.execute(
        SampleRowsNode,
        table_context(SampleRowsNode, Dict("every_n" => 2)),
    )
    @test sampled.outputs["table_out"].row_count == 2

    distinct_rows = [Dict("region" => "west"), Dict("region" => "west"), Dict("region" => "east")]
    distinct = JuliaFlowBaseExtension.execute(
        DistinctRowsNode,
        table_context(DistinctRowsNode, Dict("columns" => ["region"]); rows = distinct_rows),
    )
    @test distinct.outputs["table_out"].row_count == 2

    constant = JuliaFlowBaseExtension.execute(
        AddConstantColumnNode,
        table_context(AddConstantColumnNode, Dict("column" => "source", "value" => "fixture")),
    )
    @test first(constant.outputs["table_out"].rows)["source"] == "fixture"

    numbered = JuliaFlowBaseExtension.execute(
        RowNumberNode,
        table_context(RowNumberNode, Dict("column" => "rn", "start" => 10)),
    )
    @test [row["rn"] for row in numbered.outputs["table_out"].rows] == [10, 11, 12]

    concat = JuliaFlowBaseExtension.execute(
        ConcatRowsNode,
        table_context(
            ConcatRowsNode,
            Dict("right_input_port_id" => "right_table_in"),
            extra_inputs = Dict("right_table_in" => (format = :arrow_ipc, ref = "memory://wf/right.arrow", rows = [Dict("region" => "north", "amount" => 9.0)])),
        ),
    )
    @test concat.outputs["table_out"].row_count == 4

    left_join_rows = [Dict("id" => 1, "amount" => 10.0), Dict("id" => 2, "amount" => 20.0)]
    right_join_rows = [Dict("id" => 2, "segment" => "b")]
    joined = JuliaFlowBaseExtension.execute(
        InnerJoinRowsNode,
        table_context(
            InnerJoinRowsNode,
            Dict("left_key" => "id", "right_key" => "id", "right_input_port_id" => "right_table_in"),
            rows = left_join_rows,
            extra_inputs = Dict("right_table_in" => (format = :arrow_ipc, ref = "memory://wf/right.arrow", rows = right_join_rows)),
        ),
    )
    @test joined.outputs["table_out"].row_count == 1
    @test only(joined.outputs["table_out"].rows)["segment"] == "b"

    stats = JuliaFlowBaseExtension.execute(
        BasicStatsNode,
        table_context(BasicStatsNode, Dict("columns" => ["amount"])),
    )
    @test only(stats.outputs["table_out"].rows)["max"] == 200.0

    profile = JuliaFlowBaseExtension.execute(
        TableProfileNode,
        table_context(TableProfileNode, Dict{String,Any}()),
    )
    @test profile.outputs["table_out"].row_count >= 1

    split = JuliaFlowBaseExtension.execute(
        SplitRowsNode,
        table_context(SplitRowsNode, Dict("fraction" => 0.67, "split_column" => "split")),
    )
    @test [row["split"] for row in split.outputs["table_out"].rows] == ["train", "train", "test"]

    ratio = JuliaFlowBaseExtension.execute(
        DeriveRatioNode,
        table_context(DeriveRatioNode, Dict("numerator" => "sale_price", "denominator" => "amount", "output_column" => "price_per_amount")),
    )
    @test isapprox(first(ratio.outputs["table_out"].rows)["price_per_amount"], 1.75; atol = 1.0e-6)

    bucketed = JuliaFlowBaseExtension.execute(
        BucketizeRowsNode,
        table_context(BucketizeRowsNode, Dict("column" => "amount", "threshold" => 100.0, "output_column" => "amount_bucket")),
    )
    @test [row["amount_bucket"] for row in bucketed.outputs["table_out"].rows] == ["high", "low", "high"]

    outlet = JuliaFlowBaseExtension.execute(
        BIOutletNode,
        table_context(BIOutletNode, Dict("outlet_id" => "sales", "dataset_key" => "sales_rows")),
    )
    @test outlet.outputs["table_out"].row_count == 3
    @test outlet.telemetry["outlet_id"] == "sales"
end

@testset "Tier-1 cleanup and analytics nodes materialize rows" begin
    trimmed = JuliaFlowBaseExtension.execute(
        TrimStringsNode,
        table_context(TrimStringsNode, Dict("columns" => ["customer"]); rows = CLEANUP_ROWS),
    )
    @test first(trimmed.outputs["table_out"].rows)["customer"] == "Acme Corp"

    normalized = JuliaFlowBaseExtension.execute(
        NormalizeCaseNode,
        table_context(NormalizeCaseNode, Dict("columns" => ["status"], "case" => "upper"); rows = CLEANUP_ROWS),
    )
    @test [row["status"] for row in normalized.outputs["table_out"].rows] == ["NEW", "NEW", "OLD"]

    replaced = JuliaFlowBaseExtension.execute(
        ReplaceValuesNode,
        table_context(ReplaceValuesNode, Dict("column" => "status", "mapping" => Dict("new" => "active", "New" => "active")); rows = CLEANUP_ROWS),
    )
    @test [row["status"] for row in replaced.outputs["table_out"].rows] == ["active", "active", "old"]

    extracted = JuliaFlowBaseExtension.execute(
        RegexExtractNode,
        table_context(RegexExtractNode, Dict("source_column" => "sku", "pattern" => "SKU-(\\d+)", "output_column" => "sku_number"); rows = CLEANUP_ROWS),
    )
    @test [row["sku_number"] for row in extracted.outputs["table_out"].rows] == ["100", "200", "300"]
    @test_throws ErrorException JuliaFlowBaseExtension.execute(
        RegexExtractNode,
        table_context(RegexExtractNode, Dict("source_column" => "sku", "pattern" => "(a+)+", "output_column" => "unsafe"); rows = CLEANUP_ROWS),
    )

    validated = JuliaFlowBaseExtension.execute(
        ValidateSchemaNode,
        table_context(ValidateSchemaNode, Dict("required_columns" => ["customer", "amount", "missing_col"]); rows = CLEANUP_ROWS),
    )
    @test all(row["__valid"] == false for row in validated.outputs["table_out"].rows)
    @test validated.telemetry["invalid_count"] == 3

    top_n = JuliaFlowBaseExtension.execute(
        TopNRowsNode,
        table_context(TopNRowsNode, Dict("column" => "amount", "n" => 2, "descending" => true); rows = CLEANUP_ROWS),
    )
    @test [row["amount"] for row in top_n.outputs["table_out"].rows] == [30.0, 20.0]

    group_filtered = JuliaFlowBaseExtension.execute(
        GroupFilterNode,
        table_context(GroupFilterNode, Dict("group_by" => ["region"], "min_count" => 2); rows = CLEANUP_ROWS),
    )
    @test group_filtered.outputs["table_out"].row_count == 2
    @test all(row["region"] == "west" for row in group_filtered.outputs["table_out"].rows)

    rolling = JuliaFlowBaseExtension.execute(
        RollingMeanNode,
        table_context(RollingMeanNode, Dict("column" => "amount", "window" => 2, "output_column" => "amount_ma"); rows = CLEANUP_ROWS),
    )
    @test [row["amount_ma"] for row in rolling.outputs["table_out"].rows] == [10.0, 20.0, 25.0]

    ranked = JuliaFlowBaseExtension.execute(
        RankRowsNode,
        table_context(RankRowsNode, Dict("column" => "amount", "rank_column" => "amount_rank", "descending" => true); rows = CLEANUP_ROWS),
    )
    @test [row["amount_rank"] for row in ranked.outputs["table_out"].rows] == [1, 2, 3]
    @test [row["amount"] for row in ranked.outputs["table_out"].rows] == [30.0, 20.0, 10.0]

    percentiles = JuliaFlowBaseExtension.execute(
        PercentileRowsNode,
        table_context(PercentileRowsNode, Dict("columns" => ["amount"], "percentiles" => [0.5, 1.0]); rows = CLEANUP_ROWS),
    )
    @test percentiles.outputs["table_out"].rows == [
        Dict("column" => "amount", "percentile" => 0.5, "value" => 20.0),
        Dict("column" => "amount", "percentile" => 1.0, "value" => 30.0),
    ]
end

@testset "Tier-1 scale-out nodes materialize rows" begin
    scale_rows = [
        Dict("id" => 1, "group" => "a", "month" => "jan", "amount" => 10.0, "fallback" => missing, "label" => "Alpha customer", "status" => "N"),
        Dict("id" => 2, "group" => "a", "month" => "feb", "amount" => 20.0, "fallback" => 7.0, "label" => "beta account", "status" => ""),
        Dict("id" => 3, "group" => "b", "month" => "jan", "amount" => 40.0, "fallback" => 8.0, "label" => "Gamma account", "status" => "Y"),
    ]

    coalesced = JuliaFlowBaseExtension.execute(
        CoalesceColumnsNode,
        table_context(CoalesceColumnsNode, Dict("columns" => ["fallback", "amount"], "output_column" => "first_value"); rows = scale_rows),
    )
    @test [row["first_value"] for row in coalesced.outputs["table_out"].rows] == [10.0, 7.0, 8.0]

    clipped = JuliaFlowBaseExtension.execute(
        ClipValuesNode,
        table_context(ClipValuesNode, Dict("column" => "amount", "min" => 15.0, "max" => 25.0, "output_column" => "amount_clipped"); rows = scale_rows),
    )
    @test [row["amount_clipped"] for row in clipped.outputs["table_out"].rows] == [15.0, 20.0, 25.0]

    cumsum = JuliaFlowBaseExtension.execute(
        CumulativeSumNode,
        table_context(CumulativeSumNode, Dict("column" => "amount", "output_column" => "amount_csum"); rows = scale_rows),
    )
    @test [row["amount_csum"] for row in cumsum.outputs["table_out"].rows] == [10.0, 30.0, 70.0]

    rollsum = JuliaFlowBaseExtension.execute(
        RollingSumNode,
        table_context(RollingSumNode, Dict("column" => "amount", "window" => 2, "output_column" => "amount_rsum"); rows = scale_rows),
    )
    @test [row["amount_rsum"] for row in rollsum.outputs["table_out"].rows] == [10.0, 30.0, 60.0]

    lagged = JuliaFlowBaseExtension.execute(
        LagColumnNode,
        table_context(LagColumnNode, Dict("column" => "amount", "offset" => 1, "output_column" => "prev_amount", "default" => 0.0); rows = scale_rows),
    )
    @test [row["prev_amount"] for row in lagged.outputs["table_out"].rows] == [0.0, 10.0, 20.0]

    contains = JuliaFlowBaseExtension.execute(
        StringContainsFilterNode,
        table_context(StringContainsFilterNode, Dict("column" => "label", "substring" => "ACCOUNT", "case_sensitive" => false); rows = scale_rows),
    )
    @test contains.outputs["table_out"].row_count == 2

    math = JuliaFlowBaseExtension.execute(
        ColumnMathNode,
        table_context(ColumnMathNode, Dict("left" => "amount", "right_value" => 2.0, "operation" => "divide", "output_column" => "half_amount"); rows = scale_rows),
    )
    @test [row["half_amount"] for row in math.outputs["table_out"].rows] == [5.0, 10.0, 20.0]

    null_if = JuliaFlowBaseExtension.execute(
        NullIfNode,
        table_context(NullIfNode, Dict("column" => "status", "value" => "\"\""); rows = scale_rows),
    )
    @test null_if.outputs["table_out"].rows[2]["status"] === missing

    null_if_numeric = JuliaFlowBaseExtension.execute(
        NullIfNode,
        table_context(NullIfNode, Dict("column" => "amount", "value" => 20.0); rows = scale_rows),
    )
    @test null_if_numeric.outputs["table_out"].rows[2]["amount"] === missing

    scaled = JuliaFlowBaseExtension.execute(
        MinMaxScaleNode,
        table_context(MinMaxScaleNode, Dict("column" => "amount", "output_column" => "amount_scaled"); rows = scale_rows),
    )
    @test [row["amount_scaled"] for row in scaled.outputs["table_out"].rows] == [0.0, 1 / 3, 1.0]

    zscores = JuliaFlowBaseExtension.execute(
        ZScoreNode,
        table_context(ZScoreNode, Dict("column" => "amount", "output_column" => "amount_z"); rows = [Dict("amount" => 5.0), Dict("amount" => 5.0)]),
    )
    @test [row["amount_z"] for row in zscores.outputs["table_out"].rows] == [0.0, 0.0]

    left_rows = [Dict("id" => 1, "amount" => 10.0), Dict("id" => 2, "amount" => 20.0)]
    right_rows = [Dict("id" => 2, "segment" => "paid")]
    left_join = JuliaFlowBaseExtension.execute(
        LeftJoinRowsNode,
        table_context(
            LeftJoinRowsNode,
            Dict("left_key" => "id", "right_key" => "id", "right_input_port_id" => "right_table_in"),
            rows = left_rows,
            extra_inputs = Dict("right_table_in" => (format = :arrow_ipc, ref = "memory://wf/right.arrow", rows = right_rows)),
        ),
    )
    @test left_join.outputs["table_out"].row_count == 2
    @test left_join.outputs["table_out"].rows[2]["segment"] == "paid"

    anti_join = JuliaFlowBaseExtension.execute(
        AntiJoinRowsNode,
        table_context(
            AntiJoinRowsNode,
            Dict("left_key" => "id", "right_key" => "id", "right_input_port_id" => "right_table_in"),
            rows = left_rows,
            extra_inputs = Dict("right_table_in" => (format = :arrow_ipc, ref = "memory://wf/right.arrow", rows = right_rows)),
        ),
    )
    @test anti_join.outputs["table_out"].rows == [Dict("id" => 1, "amount" => 10.0)]

    unioned = JuliaFlowBaseExtension.execute(
        UnionDistinctRowsNode,
        table_context(
            UnionDistinctRowsNode,
            Dict("columns" => ["id"], "right_input_port_id" => "right_table_in"),
            rows = left_rows,
            extra_inputs = Dict("right_table_in" => (format = :arrow_ipc, ref = "memory://wf/right.arrow", rows = [Dict("id" => 2, "amount" => 22.0), Dict("id" => 3, "amount" => 30.0)])),
        ),
    )
    @test [row["id"] for row in unioned.outputs["table_out"].rows] == [1, 2, 3]

    unpivoted = JuliaFlowBaseExtension.execute(
        UnpivotRowsNode,
        table_context(UnpivotRowsNode, Dict("id_columns" => ["id"], "value_columns" => ["amount", "fallback"], "name_column" => "metric", "value_column" => "metric_value"); rows = scale_rows[1:1]),
    )
    @test unpivoted.outputs["table_out"].rows[1] == Dict("id" => 1, "metric" => "amount", "metric_value" => 10.0)
    @test unpivoted.outputs["table_out"].rows[2]["id"] == 1
    @test unpivoted.outputs["table_out"].rows[2]["metric"] == "fallback"
    @test unpivoted.outputs["table_out"].rows[2]["metric_value"] === missing

    pivoted = JuliaFlowBaseExtension.execute(
        PivotRowsNode,
        table_context(PivotRowsNode, Dict("index_columns" => ["group"], "names_from" => "month", "values_from" => "amount"); rows = scale_rows),
    )
    @test pivoted.outputs["table_out"].rows == [
        Dict("group" => "a", "jan" => 10.0, "feb" => 20.0),
        Dict("group" => "b", "jan" => 40.0),
    ]

    capped_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict(
            "table_in" => (format = :arrow_ipc, ref = "memory://wf/left.arrow", rows = left_rows),
            "right_table_in" => (format = :arrow_ipc, ref = "memory://wf/right.arrow", rows = [Dict("id" => 2, "segment" => "a"), Dict("id" => 2, "segment" => "b")]),
        ),
        config = JuliaFlowBaseExtension.configure(LeftJoinRowsNode, Dict("left_key" => "id", "right_key" => "id", "right_input_port_id" => "right_table_in")),
        metadata = Dict{String,Any}("max_output_rows" => 2),
    )
    @test_throws ErrorException JuliaFlowBaseExtension.execute(LeftJoinRowsNode, capped_context)

    wide_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict("table_in" => (format = :arrow_ipc, ref = "memory://wf/wide.arrow", rows = [Dict("id" => 1, "a" => 1, "b" => 2)])),
        config = JuliaFlowBaseExtension.configure(PivotRowsNode, Dict("index_columns" => ["id"], "names_from" => "a", "values_from" => "b")),
        metadata = Dict{String,Any}("max_columns" => 1),
    )
    @test_throws ErrorException JuliaFlowBaseExtension.execute(PivotRowsNode, wide_context)
end


@testset "Tier-1 BI/date/join scale nodes materialize rows" begin
    rows = [
        Dict("id" => 1, "region" => "west", "category" => "a", "date" => "2026-01-15", "label" => " Alpha   Customer ", "amount" => 10.0, "weight" => 1.0, "status" => "new", "segment_code" => "E"),
        Dict("id" => 2, "region" => "west", "category" => "a", "date" => "2026-01-20", "label" => "Beta Customer", "amount" => 30.0, "weight" => 3.0, "status" => missing, "segment_code" => "S"),
        Dict("id" => 3, "region" => "east", "category" => "b", "date" => "2026-02-05", "label" => "Gamma   Account", "amount" => 20.0, "weight" => 2.0, "status" => "old", "segment_code" => "S"),
        Dict("id" => 2, "region" => "west", "category" => "a", "date" => "2026-01-20", "label" => "Beta Customer", "amount" => 30.0, "weight" => 3.0, "status" => missing, "segment_code" => "S"),
    ]
    right_rows = [
        Dict("id" => 2, "segment" => "small"),
        Dict("id" => 4, "segment" => "enterprise"),
    ]

    deduped = JuliaFlowBaseExtension.execute(
        DedupeByKeyNode,
        table_context(DedupeByKeyNode, Dict("columns" => ["id"], "keep" => "first"); rows = rows),
    )
    @test [row["id"] for row in deduped.outputs["table_out"].rows] == [1, 2, 3]

    counts = JuliaFlowBaseExtension.execute(
        ValueCountsNode,
        table_context(ValueCountsNode, Dict("column" => "region", "count_column" => "n"); rows = rows),
    )
    @test counts.outputs["table_out"].rows == [Dict("region" => "east", "n" => 1), Dict("region" => "west", "n" => 3)]

    missingness = JuliaFlowBaseExtension.execute(
        MissingnessSummaryNode,
        table_context(MissingnessSummaryNode, Dict("columns" => ["status"]); rows = rows),
    )
    @test only(missingness.outputs["table_out"].rows)["missing_count"] == 2

    parsed = JuliaFlowBaseExtension.execute(
        ParseDateNode,
        table_context(ParseDateNode, Dict("column" => "date", "output_column" => "parsed"); rows = rows[1:1]),
    )
    @test only(parsed.outputs["table_out"].rows)["parsed"] == "2026-01-15"

    bucketed = JuliaFlowBaseExtension.execute(
        DateBucketNode,
        table_context(DateBucketNode, Dict("column" => "date", "granularity" => "month", "output_column" => "month_bucket"); rows = rows),
    )
    @test [row["month_bucket"] for row in bucketed.outputs["table_out"].rows] == ["2026-01", "2026-01", "2026-02", "2026-01"]

    date_parts = JuliaFlowBaseExtension.execute(
        DatePartsNode,
        table_context(DatePartsNode, Dict("column" => "date", "prefix" => "order"); rows = rows[1:1]),
    )
    @test only(date_parts.outputs["table_out"].rows)["order_month"] == 1

    split_col = JuliaFlowBaseExtension.execute(
        SplitColumnNode,
        table_context(SplitColumnNode, Dict("column" => "label", "delimiter" => " ", "output_columns" => ["word1", "word2"]); rows = [Dict("label" => "north region")]),
    )
    @test only(split_col.outputs["table_out"].rows)["word2"] == "region"

    top_group = JuliaFlowBaseExtension.execute(
        TopNPerGroupNode,
        table_context(TopNPerGroupNode, Dict("group_by" => ["region"], "order_by" => "amount", "n" => 1); rows = rows),
    )
    @test [row["amount"] for row in top_group.outputs["table_out"].rows] == [20.0, 30.0]

    weighted = JuliaFlowBaseExtension.execute(
        WeightedAverageNode,
        table_context(WeightedAverageNode, Dict("group_by" => ["region"], "value_column" => "amount", "weight_column" => "weight", "output_column" => "wavg"); rows = rows[1:3]),
    )
    @test weighted.outputs["table_out"].rows == [Dict("region" => "west", "wavg" => 25.0), Dict("region" => "east", "wavg" => 20.0)]

    group_numbered = JuliaFlowBaseExtension.execute(
        GroupRowNumberNode,
        table_context(GroupRowNumberNode, Dict("group_by" => ["region"], "order_by" => "amount", "column" => "grp_row"); rows = rows[1:3]),
    )
    @test [row["grp_row"] for row in group_numbered.outputs["table_out"].rows] == [1, 2, 1]

    moving_min = JuliaFlowBaseExtension.execute(
        MovingMinNode,
        table_context(MovingMinNode, Dict("column" => "amount", "window" => 2, "output_column" => "min2"); rows = rows[1:3]),
    )
    @test [row["min2"] for row in moving_min.outputs["table_out"].rows] == [10.0, 10.0, 20.0]

    moving_max = JuliaFlowBaseExtension.execute(
        MovingMaxNode,
        table_context(MovingMaxNode, Dict("column" => "amount", "window" => 2, "output_column" => "max2"); rows = rows[1:3]),
    )
    @test [row["max2"] for row in moving_max.outputs["table_out"].rows] == [10.0, 30.0, 30.0]

    counted = JuliaFlowBaseExtension.execute(
        CumulativeCountNode,
        table_context(CumulativeCountNode, Dict("column" => "row_count_so_far"); rows = rows[1:3]),
    )
    @test [row["row_count_so_far"] for row in counted.outputs["table_out"].rows] == [1, 2, 3]

    right_join = JuliaFlowBaseExtension.execute(
        RightJoinRowsNode,
        table_context(RightJoinRowsNode, Dict("left_key" => "id", "right_key" => "id", "right_input_port_id" => "right_table_in"); rows = rows[1:2], extra_inputs = Dict("right_table_in" => (format = :arrow_ipc, ref = "memory://wf/right.arrow", rows = right_rows))),
    )
    @test [row["id"] for row in right_join.outputs["table_out"].rows] == [2, 4]

    full_join = JuliaFlowBaseExtension.execute(
        FullJoinRowsNode,
        table_context(FullJoinRowsNode, Dict("left_key" => "id", "right_key" => "id", "right_input_port_id" => "right_table_in"); rows = rows[1:2], extra_inputs = Dict("right_table_in" => (format = :arrow_ipc, ref = "memory://wf/right.arrow", rows = right_rows))),
    )
    @test [row["id"] for row in full_join.outputs["table_out"].rows] == [1, 2, 4]

    semi_join = JuliaFlowBaseExtension.execute(
        SemiJoinRowsNode,
        table_context(SemiJoinRowsNode, Dict("left_key" => "id", "right_key" => "id", "right_input_port_id" => "right_table_in"); rows = rows[1:3], extra_inputs = Dict("right_table_in" => (format = :arrow_ipc, ref = "memory://wf/right.arrow", rows = right_rows))),
    )
    @test [row["id"] for row in semi_join.outputs["table_out"].rows] == [2]

    enriched = JuliaFlowBaseExtension.execute(
        LookupEnrichNode,
        table_context(LookupEnrichNode, Dict("left_key" => "id", "right_key" => "id", "columns" => ["segment"], "right_input_port_id" => "right_table_in"); rows = rows[1:2], extra_inputs = Dict("right_table_in" => (format = :arrow_ipc, ref = "memory://wf/right.arrow", rows = right_rows))),
    )
    @test enriched.outputs["table_out"].rows[2]["segment"] == "small"

    metric = JuliaFlowBaseExtension.execute(
        MetricDefinitionNode,
        table_context(MetricDefinitionNode, Dict("metric_name" => "revenue", "value_column" => "amount", "label_column" => "metric"); rows = rows[1:1]),
    )
    @test only(metric.outputs["table_out"].rows)["metric_value"] == 10.0

    mapped = JuliaFlowBaseExtension.execute(
        DimensionMappingNode,
        table_context(DimensionMappingNode, Dict("column" => "segment_code", "mapping" => Dict("E" => "enterprise", "S" => "smb"), "output_column" => "segment"); rows = rows[1:2]),
    )
    @test [row["segment"] for row in mapped.outputs["table_out"].rows] == ["enterprise", "smb"]

    kpi = JuliaFlowBaseExtension.execute(
        KpiThresholdNode,
        table_context(KpiThresholdNode, Dict("value_column" => "amount", "target" => 20.0, "status_column" => "kpi"); rows = rows[1:2]),
    )
    @test [row["kpi"] for row in kpi.outputs["table_out"].rows] == ["missed", "met"]

    chart = JuliaFlowBaseExtension.execute(
        ChartDatasetNode,
        table_context(ChartDatasetNode, Dict("x_field" => "date", "y_field" => "amount", "series_field" => "region", "dataset_key" => "sales"); rows = rows[1:2]),
    )
    @test chart.outputs["table_out"].rows[1] == Dict("x" => "2026-01-15", "y" => 10.0, "series" => "west")
    @test chart.telemetry["dataset_key"] == "sales"

    flagged = JuliaFlowBaseExtension.execute(
        BooleanFlagNode,
        table_context(BooleanFlagNode, Dict("column" => "amount", "operator" => "gte", "threshold" => 20.0, "output_column" => "large"); rows = rows[1:2]),
    )
    @test [row["large"] for row in flagged.outputs["table_out"].rows] == [false, true]

    type_profile = JuliaFlowBaseExtension.execute(
        TypeProfileNode,
        table_context(TypeProfileNode, Dict("columns" => ["amount", "status"]); rows = rows[1:2]),
    )
    @test type_profile.outputs["table_out"].row_count == 2
    @test first(type_profile.outputs["table_out"].rows)["dominant_type"] == "Float64"

    hashed = JuliaFlowBaseExtension.execute(
        RowHashNode,
        table_context(RowHashNode, Dict("columns" => ["id", "region"], "output_column" => "hash"); rows = rows[1:1]),
    )
    @test length(only(hashed.outputs["table_out"].rows)["hash"]) > 0

    normalized_ws = JuliaFlowBaseExtension.execute(
        NormalizeWhitespaceNode,
        table_context(NormalizeWhitespaceNode, Dict("columns" => ["label"]); rows = rows[1:1]),
    )
    @test only(normalized_ws.outputs["table_out"].rows)["label"] == "Alpha Customer"
end


@testset "Tier-1 100-node expansion materializes rows" begin
    rows = [
        Dict("id" => 1, "region" => "west", "category" => "alpha", "label" => "West Alpha", "amount" => 10.125, "cost" => -4.0, "metric" => "revenue", "value" => 10.0),
        Dict("id" => 2, "region" => "west", "category" => "beta", "label" => "West Beta", "amount" => 30.0, "cost" => 6.0, "metric" => "cost", "value" => 4.0),
        Dict("id" => 3, "region" => "east", "category" => "alpha", "label" => "East Alpha", "amount" => 20.0, "cost" => -2.0, "metric" => "margin", "value" => 6.0),
    ]

    dropped = JuliaFlowBaseExtension.execute(
        DropColumnsNode,
        table_context(DropColumnsNode, Dict("columns" => ["cost"]); rows = rows[1:1]),
    )
    @test !haskey(only(dropped.outputs["table_out"].rows), "cost")

    kept = JuliaFlowBaseExtension.execute(
        KeepColumnsMatchingNode,
        table_context(KeepColumnsMatchingNode, Dict("pattern" => "^(id|amount)\$"); rows = rows[1:1]),
    )
    @test sort(collect(keys(only(kept.outputs["table_out"].rows)))) == ["amount", "id"]

    copied = JuliaFlowBaseExtension.execute(
        CopyColumnNode,
        table_context(CopyColumnNode, Dict("source" => "amount", "output_column" => "amount_copy"); rows = rows[1:1]),
    )
    @test only(copied.outputs["table_out"].rows)["amount_copy"] == 10.125

    concatenated = JuliaFlowBaseExtension.execute(
        ConcatColumnsNode,
        table_context(ConcatColumnsNode, Dict("columns" => ["region", "category"], "separator" => ":", "output_column" => "slug"); rows = rows[1:1]),
    )
    @test only(concatenated.outputs["table_out"].rows)["slug"] == "west:alpha"

    substring = JuliaFlowBaseExtension.execute(
        SubstringColumnNode,
        table_context(SubstringColumnNode, Dict("column" => "label", "start" => 6, "length" => 5, "output_column" => "short"); rows = rows[1:1]),
    )
    @test only(substring.outputs["table_out"].rows)["short"] == "Alpha"

    lengths = JuliaFlowBaseExtension.execute(
        StringLengthNode,
        table_context(StringLengthNode, Dict("column" => "label", "output_column" => "label_len"); rows = rows[1:1]),
    )
    @test only(lengths.outputs["table_out"].rows)["label_len"] == 10

    replaced = JuliaFlowBaseExtension.execute(
        RegexReplaceNode,
        table_context(RegexReplaceNode, Dict("column" => "label", "pattern" => " ", "replacement" => "-", "output_column" => "label_slug"); rows = rows[1:1]),
    )
    @test only(replaced.outputs["table_out"].rows)["label_slug"] == "West-Alpha"

    rounded = JuliaFlowBaseExtension.execute(
        RoundNumberNode,
        table_context(RoundNumberNode, Dict("column" => "amount", "digits" => 1, "output_column" => "rounded"); rows = rows[1:1]),
    )
    @test only(rounded.outputs["table_out"].rows)["rounded"] == 10.1

    absed = JuliaFlowBaseExtension.execute(
        AbsoluteValueNode,
        table_context(AbsoluteValueNode, Dict("column" => "cost", "output_column" => "abs_cost"); rows = rows[1:1]),
    )
    @test only(absed.outputs["table_out"].rows)["abs_cost"] == 4.0

    logged = JuliaFlowBaseExtension.execute(
        LogTransformNode,
        table_context(LogTransformNode, Dict("column" => "amount", "base" => 10.0, "output_column" => "log_amount"); rows = [Dict("amount" => 100.0)]),
    )
    @test isapprox(only(logged.outputs["table_out"].rows)["log_amount"], 2.0; atol = 1.0e-8)

    pct = JuliaFlowBaseExtension.execute(
        PercentChangeNode,
        table_context(PercentChangeNode, Dict("column" => "amount", "output_column" => "pct"); rows = rows),
    )
    @test pct.outputs["table_out"].rows[1]["pct"] === missing
    @test isapprox(pct.outputs["table_out"].rows[2]["pct"], 1.962962962962963; atol = 1.0e-8)

    leaded = JuliaFlowBaseExtension.execute(
        LeadColumnNode,
        table_context(LeadColumnNode, Dict("column" => "amount", "output_column" => "next_amount", "default" => 0.0); rows = rows),
    )
    @test [row["next_amount"] for row in leaded.outputs["table_out"].rows] == [30.0, 20.0, 0.0]

    cummean = JuliaFlowBaseExtension.execute(
        CumulativeMeanNode,
        table_context(CumulativeMeanNode, Dict("column" => "amount", "output_column" => "cum_mean"); rows = rows),
    )
    @test isapprox(cummean.outputs["table_out"].rows[2]["cum_mean"], 20.0625; atol = 1.0e-8)

    group_sum = JuliaFlowBaseExtension.execute(
        GroupSumNode,
        table_context(GroupSumNode, Dict("group_by" => ["region"], "value_column" => "amount", "output_column" => "sum_amount"); rows = rows),
    )
    @test group_sum.outputs["table_out"].rows[1] == Dict("region" => "west", "sum_amount" => 40.125)

    group_mean = JuliaFlowBaseExtension.execute(
        GroupMeanNode,
        table_context(GroupMeanNode, Dict("group_by" => ["region"], "value_column" => "amount", "output_column" => "mean_amount"); rows = rows),
    )
    @test group_mean.outputs["table_out"].rows[2] == Dict("region" => "east", "mean_amount" => 20.0)

    group_min = JuliaFlowBaseExtension.execute(
        GroupMinNode,
        table_context(GroupMinNode, Dict("group_by" => ["region"], "value_column" => "amount", "output_column" => "min_amount"); rows = rows),
    )
    @test group_min.outputs["table_out"].rows[1]["min_amount"] == 10.125

    group_max = JuliaFlowBaseExtension.execute(
        GroupMaxNode,
        table_context(GroupMaxNode, Dict("group_by" => ["region"], "value_column" => "amount", "output_column" => "max_amount"); rows = rows),
    )
    @test group_max.outputs["table_out"].rows[1]["max_amount"] == 30.0

    group_count = JuliaFlowBaseExtension.execute(
        GroupCountNode,
        table_context(GroupCountNode, Dict("group_by" => ["region"], "output_column" => "n"); rows = rows),
    )
    @test [row["n"] for row in group_count.outputs["table_out"].rows] == [2, 1]

    pct_total = JuliaFlowBaseExtension.execute(
        GroupPercentOfTotalNode,
        table_context(GroupPercentOfTotalNode, Dict("group_by" => ["region"], "value_column" => "amount", "output_column" => "share"); rows = rows),
    )
    @test isapprox(pct_total.outputs["table_out"].rows[1]["share"], 10.125 / 40.125; atol = 1.0e-8)

    buckets = JuliaFlowBaseExtension.execute(
        BucketByThresholdsNode,
        table_context(BucketByThresholdsNode, Dict("column" => "amount", "thresholds" => [15.0, 25.0], "labels" => ["low", "mid", "high"], "output_column" => "band"); rows = rows),
    )
    @test [row["band"] for row in buckets.outputs["table_out"].rows] == ["low", "high", "mid"]

    quantiles = JuliaFlowBaseExtension.execute(
        QuantileBucketNode,
        table_context(QuantileBucketNode, Dict("column" => "amount", "buckets" => 3, "output_column" => "q"); rows = rows),
    )
    @test [row["q"] for row in quantiles.outputs["table_out"].rows] == [1, 3, 2]

    one_hot = JuliaFlowBaseExtension.execute(
        OneHotEncodeNode,
        table_context(OneHotEncodeNode, Dict("column" => "category", "categories" => ["alpha", "beta"], "prefix" => "cat"); rows = rows[1:2]),
    )
    @test [row["cat_alpha"] for row in one_hot.outputs["table_out"].rows] == [1, 0]
    @test [row["cat_beta"] for row in one_hot.outputs["table_out"].rows] == [0, 1]

    metric_cards = JuliaFlowBaseExtension.execute(
        MetricCardsNode,
        table_context(MetricCardsNode, Dict("metrics" => ["amount", "cost"], "aggregation" => "sum"); rows = rows),
    )
    @test metric_cards.outputs["table_out"].rows[1] == Dict("metric" => "amount", "value" => 60.125, "aggregation" => "sum")

    dashboard = JuliaFlowBaseExtension.execute(
        DashboardSummaryNode,
        table_context(DashboardSummaryNode, Dict("numeric_columns" => ["amount"]); rows = rows),
    )
    @test only(dashboard.outputs["table_out"].rows)["row_count"] == 3
    @test only(dashboard.outputs["table_out"].rows)["amount_sum"] == 60.125

    widened = JuliaFlowBaseExtension.execute(
        RowsToColumnsNode,
        table_context(RowsToColumnsNode, Dict("key_column" => "metric", "value_column" => "value"); rows = rows),
    )
    @test only(widened.outputs["table_out"].rows) == Dict("revenue" => 10.0, "cost" => 4.0, "margin" => 6.0)
end

@testset "Package-backed Arrow/DataFrames materialization" begin
    mktempdir() do dir
        source_path = joinpath(dir, "object", "prod", "source.arrow")
        mkpath(dirname(source_path))
        Arrow.write(source_path, DataFrames.DataFrame(region = ["west", "east"], amount = [12.5, 7.5]))

        source_context = NodeContext(
            workflow_id = uuid4(),
            execution_id = uuid4(),
            node_id = uuid4(),
            config = JuliaFlowBaseExtension.configure(ArrowTableSourceNode, Dict("output_port_id" => "source_out", "ref" => "object://prod/source.arrow")),
            metadata = Dict{String,Any}("object_store_root" => dir, "enable_arrow_dataframe_adapter" => true),
        )
        source = JuliaFlowBaseExtension.execute(ArrowTableSourceNode, source_context)
        @test source.outputs["source_out"].format == :arrow_ipc
        @test source.outputs["source_out"].row_count == 2
        @test source.outputs["source_out"].schema == ["region", "amount"]
        @test source.outputs["source_out"].rows == [Dict("region" => "west", "amount" => 12.5), Dict("region" => "east", "amount" => 7.5)]
        @test source.telemetry["materialization_adapter"] == "arrow_dataframe_file"

        sink_context = NodeContext(
            workflow_id = uuid4(),
            execution_id = uuid4(),
            node_id = uuid4(),
            inputs = Dict("table_in" => (format = :arrow_ipc, ref = "memory://wf/native.arrow", rows = SAMPLE_ROWS[1:2])),
            config = JuliaFlowBaseExtension.configure(ArrowTableSinkNode, Dict("input_port_id" => "table_in", "destination_uri" => "warehouse://gold/native.arrow")),
            metadata = Dict{String,Any}("object_store_root" => dir, "enable_arrow_dataframe_adapter" => true),
        )
        sink = JuliaFlowBaseExtension.execute(ArrowTableSinkNode, sink_context)
        @test isempty(sink.warnings)
        @test sink.telemetry["persisted"] == true
        @test sink.telemetry["persistence_adapter"] == "arrow_dataframe_file"
        @test sink.telemetry["row_count"] == 2
        @test isfile(joinpath(dir, "warehouse", "gold", "native.arrow"))

        roundtrip_context = NodeContext(
            workflow_id = uuid4(),
            execution_id = uuid4(),
            node_id = uuid4(),
            config = JuliaFlowBaseExtension.configure(ArrowTableSourceNode, Dict("output_port_id" => "source_out", "ref" => "warehouse://gold/native.arrow")),
            metadata = Dict{String,Any}("object_store_root" => dir, "enable_arrow_dataframe_adapter" => true),
        )
        roundtrip = JuliaFlowBaseExtension.execute(ArrowTableSourceNode, roundtrip_context)
        @test roundtrip.outputs["source_out"].row_count == 2
        @test [row["region"] for row in roundtrip.outputs["source_out"].rows] == ["west", "west"]
        @test [row["amount"] for row in roundtrip.outputs["source_out"].rows] == [120.0, 80.0]
    end
end



function test_arrow_base64(rows)
    path = tempname() * ".arrow"
    try
        Arrow.write(path, DataFrames.DataFrame(rows))
        return base64encode(read(path))
    finally
        isfile(path) && rm(path; force = true)
    end
end

@testset "Remote object-store adapter materialization" begin
    remote_rows = [Dict("region" => "north", "amount" => 40.0), Dict("region" => "south", "amount" => 50.0)]
    read_payload = Dict("format" => "arrow_ipc_base64", "data" => test_arrow_base64(remote_rows), "adapter" => "remote_arrow_service")
    write_requests = Any[]
    transport = (operation, ref, body, _context) -> begin
        if operation == "read"
            @test ref == "s3://analytics/source.arrow"
            return read_payload
        elseif operation == "write"
            @test ref == "s3://analytics/out.arrow"
            @test body["format"] == "arrow_ipc_base64"
            @test body["row_count"] == 2
            @test length(String(body["data"])) > 0
            push!(write_requests, body)
            return Dict("ref" => ref, "row_count" => body["row_count"], "adapter" => "remote_arrow_service")
        end
        error("unexpected remote operation $(operation)")
    end
    metadata = Dict{String,Any}(
        "enable_remote_object_store_adapter" => true,
        "remote_object_store_adapter" => Dict(
            "name" => "remote_arrow_service",
            "schemes" => ["s3://"],
            "transport" => transport,
        ),
    )

    source_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        config = JuliaFlowBaseExtension.configure(ArrowTableSourceNode, Dict("output_port_id" => "source_out", "ref" => "s3://analytics/source.arrow")),
        metadata = metadata,
    )
    remote_source = JuliaFlowBaseExtension.execute(ArrowTableSourceNode, source_context)
    @test remote_source.outputs["source_out"].format == :arrow_ipc
    @test remote_source.outputs["source_out"].row_count == 2
    @test Set(remote_source.outputs["source_out"].schema) == Set(["region", "amount"])
    @test remote_source.outputs["source_out"].rows == remote_rows
    @test remote_source.telemetry["materialization_adapter"] == "remote_arrow_service"

    sink_context = NodeContext(
        workflow_id = uuid4(),
        execution_id = uuid4(),
        node_id = uuid4(),
        inputs = Dict("table_in" => (format = :arrow_ipc, ref = "memory://wf/remote.arrow", rows = remote_rows)),
        config = JuliaFlowBaseExtension.configure(ArrowTableSinkNode, Dict("input_port_id" => "table_in", "destination_uri" => "s3://analytics/out.arrow")),
        metadata = metadata,
    )
    remote_sink = JuliaFlowBaseExtension.execute(ArrowTableSinkNode, sink_context)
    @test isempty(remote_sink.warnings)
    @test remote_sink.telemetry["persisted"] == true
    @test remote_sink.telemetry["persistence_adapter"] == "remote_arrow_service"
    @test remote_sink.telemetry["persisted_ref"] == "s3://analytics/out.arrow"
    @test remote_sink.telemetry["row_count"] == 2
    @test length(write_requests) == 1
end

@testset "Tier-1 125-node advanced nodes materialize rows" begin
    rows = [
        Dict("id" => 1, "x" => 1.0, "y" => 2.0, "amount" => 10.0, "actual" => 1, "predicted" => 1, "score" => 0.9, "event_id" => "e1", "event_time" => "2026-01-01", "region" => "west", "hash" => "abc", "expected_hash" => "abc", "ref" => "object://sales/a.arrow", "size" => 10),
        Dict("id" => 2, "x" => 2.0, "y" => 4.0, "amount" => 20.0, "actual" => 0, "predicted" => 1, "score" => 0.6, "event_id" => "e2", "event_time" => "2026-01-02", "region" => "west", "hash" => "bad", "expected_hash" => "ok", "ref" => "object://sales/b.json", "size" => 20),
        Dict("id" => 3, "x" => 3.0, "y" => 6.0, "amount" => 30.0, "actual" => 1, "predicted" => 0, "score" => 0.4, "event_id" => "e1", "event_time" => "2026-02-01", "region" => "east", "hash" => "zzz", "expected_hash" => "zzz", "ref" => "object://ops/c.arrow", "size" => 30),
    ]

    corr = JuliaFlowBaseExtension.execute(CorrelationNode, table_context(CorrelationNode, Dict("left_column" => "x", "right_column" => "y"); rows = rows))
    @test isapprox(only(corr.outputs["table_out"].rows)["correlation"], 1.0; atol = 1.0e-8)

    cov = JuliaFlowBaseExtension.execute(CovarianceNode, table_context(CovarianceNode, Dict("left_column" => "x", "right_column" => "y"); rows = rows))
    @test isapprox(only(cov.outputs["table_out"].rows)["covariance"], 2.0; atol = 1.0e-8)

    hist = JuliaFlowBaseExtension.execute(HistogramNode, table_context(HistogramNode, Dict("column" => "amount", "thresholds" => [15.0, 25.0], "labels" => ["low", "mid", "high"]); rows = rows))
    @test [row["count"] for row in hist.outputs["table_out"].rows] == [1, 1, 1]

    outliers = JuliaFlowBaseExtension.execute(OutlierFlagNode, table_context(OutlierFlagNode, Dict("column" => "amount", "threshold" => 0.5, "output_column" => "outlier"); rows = rows))
    @test [row["outlier"] for row in outliers.outputs["table_out"].rows] == [true, false, true]

    standardized = JuliaFlowBaseExtension.execute(StandardizeColumnsNode, table_context(StandardizeColumnsNode, Dict("columns" => ["amount"]); rows = rows))
    @test isapprox(standardized.outputs["table_out"].rows[2]["amount_z"], 0.0; atol = 1.0e-8)

    split = JuliaFlowBaseExtension.execute(TrainTestSplitNode, table_context(TrainTestSplitNode, Dict("train_ratio" => 2 / 3, "output_column" => "split"); rows = rows))
    @test [row["split"] for row in split.outputs["table_out"].rows] == ["train", "train", "test"]

    scored = JuliaFlowBaseExtension.execute(LinearScoreNode, table_context(LinearScoreNode, Dict("coefficients" => Dict("x" => 2.0, "amount" => 0.1), "intercept" => 1.0, "output_column" => "model_score"); rows = rows[1:1]))
    @test only(scored.outputs["table_out"].rows)["model_score"] == 4.0

    classified = JuliaFlowBaseExtension.execute(ClassificationThresholdNode, table_context(ClassificationThresholdNode, Dict("score_column" => "score", "threshold" => 0.5, "output_column" => "class"); rows = rows))
    @test [row["class"] for row in classified.outputs["table_out"].rows] == [1, 1, 0]

    matrix = JuliaFlowBaseExtension.execute(ConfusionMatrixNode, table_context(ConfusionMatrixNode, Dict("actual_column" => "actual", "predicted_column" => "predicted"); rows = rows))
    @test Dict(row["cell"] => row["count"] for row in matrix.outputs["table_out"].rows) == Dict("tp" => 1, "fp" => 1, "fn" => 1, "tn" => 0)

    metrics = JuliaFlowBaseExtension.execute(RegressionMetricsNode, table_context(RegressionMetricsNode, Dict("actual_column" => "actual", "predicted_column" => "score"); rows = rows))
    @test isapprox(only(metrics.outputs["table_out"].rows)["mae"], (0.1 + 0.6 + 0.6) / 3; atol = 1.0e-8)

    clusters = JuliaFlowBaseExtension.execute(KMeansAssignNode, table_context(KMeansAssignNode, Dict("feature_columns" => ["x", "y"], "centroids" => [[1.0, 2.0], [3.0, 6.0]], "output_column" => "cluster"); rows = rows))
    @test [row["cluster"] for row in clusters.outputs["table_out"].rows] == [1, 1, 2]

    pca = JuliaFlowBaseExtension.execute(PcaProjectNode, table_context(PcaProjectNode, Dict("components" => Dict("pc1" => Dict("x" => 1.0, "y" => 0.5))); rows = rows[1:1]))
    @test only(pca.outputs["table_out"].rows)["pc1"] == 2.0

    event_time = JuliaFlowBaseExtension.execute(EventTimeAssignNode, table_context(EventTimeAssignNode, Dict("timestamp_column" => "event_time", "output_column" => "assigned_time"); rows = rows[1:1]))
    @test only(event_time.outputs["table_out"].rows)["assigned_time"] == "2026-01-01"

    watermark = JuliaFlowBaseExtension.execute(WatermarkFlagNode, table_context(WatermarkFlagNode, Dict("timestamp_column" => "event_time", "watermark" => "2026-01-02", "output_column" => "late"); rows = rows))
    @test [row["late"] for row in watermark.outputs["table_out"].rows] == [true, true, false]

    tumbling = JuliaFlowBaseExtension.execute(TumblingWindowNode, table_context(TumblingWindowNode, Dict("timestamp_column" => "event_time", "granularity" => "month", "output_column" => "month_window"); rows = rows))
    @test [row["month_window"] for row in tumbling.outputs["table_out"].rows] == ["2026-01", "2026-01", "2026-02"]

    sliding = JuliaFlowBaseExtension.execute(SlidingWindowNode, table_context(SlidingWindowNode, Dict("step" => 2, "output_column" => "window_id"); rows = rows))
    @test [row["window_id"] for row in sliding.outputs["table_out"].rows] == [1, 1, 2]

    stream_aggregate = JuliaFlowBaseExtension.execute(StreamAggregateNode, table_context(StreamAggregateNode, Dict("group_by" => ["region"], "value_column" => "amount", "operation" => "sum", "output_column" => "sum_amount"); rows = rows))
    @test stream_aggregate.outputs["table_out"].rows == [Dict("region" => "west", "sum_amount" => 30.0), Dict("region" => "east", "sum_amount" => 30.0)]

    event_deduped = JuliaFlowBaseExtension.execute(DedupeEventIdNode, table_context(DedupeEventIdNode, Dict("event_id_column" => "event_id"); rows = rows))
    @test [row["event_id"] for row in event_deduped.outputs["table_out"].rows] == ["e1", "e2"]

    marked = JuliaFlowBaseExtension.execute(SinkTransactionMarkerNode, table_context(SinkTransactionMarkerNode, Dict("transaction_id" => "tx-1", "status" => "committed"); rows = rows[1:1]))
    @test only(marked.outputs["table_out"].rows)["sink_transaction_id"] == "tx-1"
    @test marked.telemetry["transaction_id"] == "tx-1"

    manifests = [Dict("name" => "base", "version" => "1.0", "node_count" => 125), Dict("name" => "bad")]
    manifest_check = JuliaFlowBaseExtension.execute(ExtensionManifestValidateNode, table_context(ExtensionManifestValidateNode, Dict{String,Any}(); rows = manifests))
    @test [row["manifest_valid"] for row in manifest_check.outputs["table_out"].rows] == [true, false]

    compatibility = JuliaFlowBaseExtension.execute(CompatibilityReportNode, table_context(CompatibilityReportNode, Dict("current_version" => "1.12"); rows = [Dict("min_julia" => "1.10"), Dict("min_julia" => "1.13")]))
    @test [row["compatible"] for row in compatibility.outputs["table_out"].rows] == [true, false]

    hash_check = JuliaFlowBaseExtension.execute(PackageHashVerifyNode, table_context(PackageHashVerifyNode, Dict{String,Any}(); rows = rows))
    @test [row["hash_verified"] for row in hash_check.outputs["table_out"].rows] == [true, false, true]

    listed = JuliaFlowBaseExtension.execute(ObjectStoreListNode, table_context(ObjectStoreListNode, Dict("ref_column" => "ref", "prefix" => "object://sales", "extension" => ".arrow"); rows = rows))
    @test listed.outputs["table_out"].rows == [Dict("ref" => "object://sales/a.arrow", "size" => 10)]

    versioned = JuliaFlowBaseExtension.execute(DatasetVersionNode, table_context(DatasetVersionNode, Dict("columns" => ["id", "amount"], "output_column" => "version"); rows = rows[1:1]))
    @test length(only(versioned.outputs["table_out"].rows)["version"]) > 0

    drift = JuliaFlowBaseExtension.execute(SchemaDriftNode, table_context(SchemaDriftNode, Dict("expected_columns" => ["id", "x", "missing_col"]); rows = rows[1:1]))
    @test only(drift.outputs["table_out"].rows)["drift_detected"] == true
    @test occursin("missing_col", only(drift.outputs["table_out"].rows)["missing_columns"])
end


@testset "Tier-1 150-node quality and governance nodes materialize rows" begin
    rows = [
        Dict("id" => 1, "amount" => 10.0, "score" => 0.1, "event_time" => "2026-01-01", "text" => "alpha beta", "items" => "red,blue", "json" => "{\"city\":\"Paris\"}", "email" => "alice@example.com", "column" => "email", "region" => "west"),
        Dict("id" => 2, "amount" => 15.0, "score" => 0.4, "event_time" => "2026-01-03", "text" => "gamma", "items" => "green", "json" => "{\"city\":\"Rome\"}", "email" => "bob@example.com", "column" => "amount", "region" => "west"),
        Dict("id" => 2, "amount" => missing, "score" => 0.9, "event_time" => "2026-01-04", "text" => "alpha", "items" => "red", "json" => "{\"city\":\"Oslo\"}", "email" => "carol@example.com", "column" => "email", "region" => "east"),
    ]

    presence = JuliaFlowBaseExtension.execute(ColumnPresenceNode, table_context(ColumnPresenceNode, Dict("expected_columns" => ["id", "missing_col"]); rows = rows))
    @test [row["present"] for row in presence.outputs["table_out"].rows] == [true, false]

    null_rate = JuliaFlowBaseExtension.execute(NullRateNode, table_context(NullRateNode, Dict("columns" => ["amount"]); rows = rows))
    @test only(null_rate.outputs["table_out"].rows)["null_count"] == 1

    duplicate_rate = JuliaFlowBaseExtension.execute(DuplicateRateNode, table_context(DuplicateRateNode, Dict("columns" => ["id"]); rows = rows))
    @test only(duplicate_rate.outputs["table_out"].rows)["duplicate_count"] == 1

    cardinality = JuliaFlowBaseExtension.execute(CardinalityNode, table_context(CardinalityNode, Dict("columns" => ["region"]); rows = rows))
    @test only(cardinality.outputs["table_out"].rows)["unique_count"] == 2

    numeric_only = JuliaFlowBaseExtension.execute(ColumnSelectByTypeNode, table_context(ColumnSelectByTypeNode, Dict("type" => "numeric"); rows = rows[1:2]))
    @test sort(collect(keys(first(numeric_only.outputs["table_out"].rows)))) == ["amount", "id", "score"]

    since_previous = JuliaFlowBaseExtension.execute(TimeSincePreviousNode, table_context(TimeSincePreviousNode, Dict("timestamp_column" => "event_time", "output_column" => "gap"); rows = rows))
    @test isequal([row["gap"] for row in since_previous.outputs["table_out"].rows], [missing, 2, 1])

    sessions = JuliaFlowBaseExtension.execute(SessionizeEventsNode, table_context(SessionizeEventsNode, Dict("timestamp_column" => "event_time", "max_gap_days" => 1, "output_column" => "session"); rows = rows))
    @test [row["session"] for row in sessions.outputs["table_out"].rows] == [1, 2, 2]

    delta = JuliaFlowBaseExtension.execute(WindowLagDeltaNode, table_context(WindowLagDeltaNode, Dict("column" => "score", "output_column" => "score_delta"); rows = rows))
    @test isequal([row["score_delta"] for row in delta.outputs["table_out"].rows], [missing, 0.30000000000000004, 0.5])

    rolling_std = JuliaFlowBaseExtension.execute(RollingStdNode, table_context(RollingStdNode, Dict("column" => "score", "window" => 2, "output_column" => "score_std"); rows = rows))
    @test isapprox(rolling_std.outputs["table_out"].rows[2]["score_std"], sqrt(0.045); atol = 1.0e-8)

    expanding = JuliaFlowBaseExtension.execute(ExpandingMaxNode, table_context(ExpandingMaxNode, Dict("column" => "score", "output_column" => "max_score"); rows = rows))
    @test [row["max_score"] for row in expanding.outputs["table_out"].rows] == [0.1, 0.4, 0.9]

    crossed = JuliaFlowBaseExtension.execute(
        CrossJoinRowsNode,
        table_context(CrossJoinRowsNode, Dict("right_input_port_id" => "right_table_in"); rows = rows[1:2], extra_inputs = Dict("right_table_in" => (format = :arrow_ipc, ref = "memory://wf/right.arrow", rows = [Dict("segment" => "a"), Dict("segment" => "b")]))),
    )
    @test crossed.outputs["table_out"].row_count == 4

    appended = JuliaFlowBaseExtension.execute(AppendMetadataNode, table_context(AppendMetadataNode, Dict("metadata" => Dict("source" => "unit")); rows = rows[1:1]))
    @test only(appended.outputs["table_out"].rows)["source"] == "unit"

    masked = JuliaFlowBaseExtension.execute(MaskColumnNode, table_context(MaskColumnNode, Dict("column" => "email", "visible_suffix" => 4, "output_column" => "masked_email"); rows = rows[1:1]))
    @test only(masked.outputs["table_out"].rows)["masked_email"] == "***.com"

    tokenized = JuliaFlowBaseExtension.execute(TokenizeColumnNode, table_context(TokenizeColumnNode, Dict("column" => "text", "output_column" => "tokens"); rows = rows[1:1]))
    @test only(tokenized.outputs["table_out"].rows)["tokens"] == ["alpha", "beta"]

    exploded = JuliaFlowBaseExtension.execute(ExplodeListNode, table_context(ExplodeListNode, Dict("column" => "items", "delimiter" => ","); rows = rows[1:1]))
    @test [row["items"] for row in exploded.outputs["table_out"].rows] == ["red", "blue"]

    extracted = JuliaFlowBaseExtension.execute(JsonExtractFieldNode, table_context(JsonExtractFieldNode, Dict("column" => "json", "field" => "city", "output_column" => "city"); rows = rows[1:1]))
    @test only(extracted.outputs["table_out"].rows)["city"] == "Paris"

    lineage = JuliaFlowBaseExtension.execute(DatasetLineageNode, table_context(DatasetLineageNode, Dict("source_dataset" => "raw", "output_dataset" => "gold", "operation" => "clean"); rows = rows[1:1]))
    @test only(lineage.outputs["table_out"].rows)["output_dataset"] == "gold"

    tagged = JuliaFlowBaseExtension.execute(PolicyTagNode, table_context(PolicyTagNode, Dict("column" => "column", "mapping" => Dict("email" => "pii"), "output_column" => "tag"); rows = rows[1:2]))
    @test [row["tag"] for row in tagged.outputs["table_out"].rows] == ["pii", "public"]

    access = JuliaFlowBaseExtension.execute(AccessDecisionNode, table_context(AccessDecisionNode, Dict("role" => "viewer", "allowed_roles" => ["owner", "viewer"], "output_column" => "allowed"); rows = rows[1:1]))
    @test only(access.outputs["table_out"].rows)["allowed"] == true

    gpu = JuliaFlowBaseExtension.execute(GpuCapabilityFlagNode, table_context(GpuCapabilityFlagNode, Dict("required_memory_mb" => 1000, "available_memory_mb" => 2000, "output_column" => "gpu_ok"); rows = rows[1:1]))
    @test only(gpu.outputs["table_out"].rows)["gpu_ok"] == true

    batched = JuliaFlowBaseExtension.execute(BatchIdAssignNode, table_context(BatchIdAssignNode, Dict("batch_id" => "b-7"); rows = rows[1:2]))
    @test [row["batch_row_number"] for row in batched.outputs["table_out"].rows] == [1, 2]

    offsets = JuliaFlowBaseExtension.execute(ReplayOffsetNode, table_context(ReplayOffsetNode, Dict("start_offset" => 42, "output_column" => "offset"); rows = rows[1:2]))
    @test [row["offset"] for row in offsets.outputs["table_out"].rows] == [42, 43]

    exactly_once = JuliaFlowBaseExtension.execute(ExactlyOnceKeyNode, table_context(ExactlyOnceKeyNode, Dict("columns" => ["id", "event_time"], "output_column" => "dedupe_key"); rows = rows[1:1]))
    @test length(only(exactly_once.outputs["table_out"].rows)["dedupe_key"]) > 0

    commit_plan = JuliaFlowBaseExtension.execute(SinkCommitPlanNode, table_context(SinkCommitPlanNode, Dict("sink" => "warehouse", "mode" => "commit"); rows = rows))
    @test only(commit_plan.outputs["table_out"].rows)["row_count"] == 3

    features = JuliaFlowBaseExtension.execute(FeatureVectorNode, table_context(FeatureVectorNode, Dict("columns" => ["id", "score"], "output_column" => "features"); rows = rows[1:1]))
    @test only(features.outputs["table_out"].rows)["features"] == [1.0, 0.1]
end
