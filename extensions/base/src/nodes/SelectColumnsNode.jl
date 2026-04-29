const SELECT_COLUMNS_INPUT_PORT_ID = "table_in"
const SELECT_COLUMNS_OUTPUT_PORT_ID = "table_out"

struct SelectColumnsNode <: AbstractNode end

function configure(::Type{SelectColumnsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    normalized = Dict{String,Any}(String(key) => value for (key, value) in pairs(params))

    input_port_id = String(get(normalized, "input_port_id", SELECT_COLUMNS_INPUT_PORT_ID))
    output_port_id = String(get(normalized, "output_port_id", SELECT_COLUMNS_OUTPUT_PORT_ID))
    raw_columns = get(normalized, "columns", String[])
    columns = [String(column) for column in raw_columns]

    isempty(input_port_id) && error("input_port_id must not be empty")
    isempty(output_port_id) && error("output_port_id must not be empty")
    isempty(columns) && error("columns must contain at least one column")

    return NodeConfig(
        Dict(
            "input_port_id" => input_port_id,
            "output_port_id" => output_port_id,
            "columns" => columns,
        ),
    )
end

function infer_output_schema(::Type{SelectColumnsNode}, input_schemas::Vector{PortSchema})
    validate_port_type(:data_table)
    input_label = isempty(input_schemas) ? "Selected Columns" : input_schemas[1].label

    return [
        PortSchema(
            id = SELECT_COLUMNS_OUTPUT_PORT_ID,
            direction = :output,
            type = :data_table,
            label = input_label,
        ),
    ]
end

function execute(::Type{SelectColumnsNode}, context::NodeContext)
    input_port_id = String(get(context.config.values, "input_port_id", SELECT_COLUMNS_INPUT_PORT_ID))
    output_port_id = String(get(context.config.values, "output_port_id", SELECT_COLUMNS_OUTPUT_PORT_ID))
    columns = [String(column) for column in get(context.config.values, "columns", String[])]

    haskey(context.inputs, input_port_id) || error("missing input payload for port $(input_port_id)")
    payload = context.inputs[input_port_id]

    validate_arrow_boundary(payload)
    haskey(payload, :ref) || error("Arrow payload missing ref field")
    isempty(columns) && error("columns must contain at least one column")

    rows = payload_rows(payload, context)
    if rows === nothing
        projected_payload = (; payload..., selected_columns = columns)
        return NodeResult(
            outputs = Dict(output_port_id => projected_payload),
            telemetry = Dict(
                "node_key" => "base.select_columns",
                "input_port_id" => input_port_id,
                "output_port_id" => output_port_id,
                "input_ref" => String(payload.ref),
                "column_count" => length(columns),
                "materialized" => false,
            ),
            warnings = ["select_columns requires materialized rows for execution"],
        )
    end

    projected_rows = [Dict(column => row_value(row, column) for column in columns) for row in rows]
    projected_payload = table_payload(payload, context, "base.select_columns", projected_rows; schema = columns)

    return NodeResult(
        outputs = Dict(output_port_id => projected_payload),
        telemetry = Dict(
            "node_key" => "base.select_columns",
            "input_port_id" => input_port_id,
            "output_port_id" => output_port_id,
            "input_ref" => String(payload.ref),
            "output_ref" => projected_payload.ref,
            "column_count" => length(columns),
            "row_count" => length(projected_rows),
            "materialized" => true,
        ),
    )
end

function on_stream_event(::Type{SelectColumnsNode}, event, state, ::NodeContext)
    return (event, state)
end
