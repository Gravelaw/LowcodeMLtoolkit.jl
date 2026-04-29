using Test
using UUIDs
using JSON3

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
    @test length(registry) == 50
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
