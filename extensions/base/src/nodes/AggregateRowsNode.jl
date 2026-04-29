const AGGREGATE_ROWS_INPUT_PORT_ID = "table_in"
const AGGREGATE_ROWS_OUTPUT_PORT_ID = "table_out"

struct AggregateRowsNode <: AbstractNode end

function configure(::Type{AggregateRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    normalized = Dict{String,Any}(String(key) => value for (key, value) in pairs(params))

    input_port_id = String(get(normalized, "input_port_id", AGGREGATE_ROWS_INPUT_PORT_ID))
    output_port_id = String(get(normalized, "output_port_id", AGGREGATE_ROWS_OUTPUT_PORT_ID))
    aggregation = String(get(normalized, "aggregation", "row_count"))
    value_column = String(get(normalized, "value_column", ""))
    group_by = [String(column) for column in get(normalized, "group_by", String[])]

    isempty(input_port_id) && error("input_port_id must not be empty")
    isempty(output_port_id) && error("output_port_id must not be empty")
    isempty(strip(aggregation)) && error("aggregation must not be empty")

    return NodeConfig(
        Dict(
            "input_port_id" => input_port_id,
            "output_port_id" => output_port_id,
            "aggregation" => aggregation,
            "value_column" => value_column,
            "group_by" => group_by,
        ),
    )
end

function infer_output_schema(::Type{AggregateRowsNode}, input_schemas::Vector{PortSchema})
    validate_port_type(:data_table)
    input_label = isempty(input_schemas) ? "Aggregated Rows" : input_schemas[1].label

    return [
        PortSchema(
            id = AGGREGATE_ROWS_OUTPUT_PORT_ID,
            direction = :output,
            type = :data_table,
            label = input_label,
        ),
    ]
end

function aggregate_value(rows, aggregation::String, value_column::String)
    normalized = lowercase(strip(aggregation))
    if normalized in ["row_count", "count"]
        return length(rows)
    end
    isempty(value_column) && error("value_column must be set for $(aggregation) aggregation")
    values = numeric_values(rows, value_column)
    normalized == "sum" && return sum(values)
    normalized == "mean" && return mean_value(values)
    normalized == "min" && return isempty(values) ? NaN : minimum(values)
    normalized == "max" && return isempty(values) ? NaN : maximum(values)
    error("unsupported aggregation: $(aggregation)")
end

function execute(::Type{AggregateRowsNode}, context::NodeContext)
    input_port_id = String(get(context.config.values, "input_port_id", AGGREGATE_ROWS_INPUT_PORT_ID))
    output_port_id = String(get(context.config.values, "output_port_id", AGGREGATE_ROWS_OUTPUT_PORT_ID))
    aggregation = String(get(context.config.values, "aggregation", "row_count"))
    value_column = String(get(context.config.values, "value_column", ""))
    group_by = [String(column) for column in get(context.config.values, "group_by", String[])]

    haskey(context.inputs, input_port_id) || error("missing input payload for port $(input_port_id)")
    payload = context.inputs[input_port_id]

    validate_arrow_boundary(payload)
    haskey(payload, :ref) || error("Arrow payload missing ref field")
    isempty(strip(aggregation)) && error("aggregation must not be empty")

    rows = payload_rows(payload, context)
    if rows === nothing
        aggregated_payload = (; payload..., aggregation = aggregation, group_by = group_by, value_column = value_column)
        return NodeResult(
            outputs = Dict(output_port_id => aggregated_payload),
            telemetry = Dict(
                "node_key" => "base.aggregate_rows",
                "input_port_id" => input_port_id,
                "output_port_id" => output_port_id,
                "input_ref" => String(payload.ref),
                "aggregation" => aggregation,
                "group_by_count" => length(group_by),
                "materialized" => false,
            ),
            warnings = ["aggregate_rows requires materialized rows for execution"],
        )
    end

    grouped = Dict{Tuple,Vector{Any}}()
    for row in rows
        key = Tuple(row_value(row, column) for column in group_by)
        group_rows = get!(grouped, key, Any[])
        push!(group_rows, row)
    end

    output_column = lowercase(aggregation) in ["row_count", "count"] ? "row_count" : "$(lowercase(aggregation))_$(value_column)"
    aggregated_rows = Dict{String,Any}[]
    for (key, group_rows) in grouped
        output_row = Dict{String,Any}()
        for (index, column) in enumerate(group_by)
            output_row[column] = key[index]
        end
        output_row[output_column] = aggregate_value(group_rows, aggregation, value_column)
        push!(aggregated_rows, output_row)
    end
    if isempty(group_by) && isempty(aggregated_rows)
        push!(aggregated_rows, Dict(output_column => aggregate_value(Any[], aggregation, value_column)))
    end
    sort!(aggregated_rows, by = row -> join([string(row[column]) for column in group_by], "|"))

    schema = vcat(group_by, [output_column])
    aggregated_payload = table_payload(payload, context, "base.aggregate_rows", aggregated_rows; schema = schema)

    return NodeResult(
        outputs = Dict(output_port_id => aggregated_payload),
        telemetry = Dict(
            "node_key" => "base.aggregate_rows",
            "input_port_id" => input_port_id,
            "output_port_id" => output_port_id,
            "input_ref" => String(payload.ref),
            "output_ref" => aggregated_payload.ref,
            "aggregation" => aggregation,
            "group_by_count" => length(group_by),
            "row_count" => length(aggregated_rows),
            "materialized" => true,
        ),
    )
end

function on_stream_event(::Type{AggregateRowsNode}, event, state, ::NodeContext)
    return (event, state)
end
