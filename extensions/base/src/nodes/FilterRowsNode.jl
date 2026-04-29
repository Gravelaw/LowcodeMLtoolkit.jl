const FILTER_ROWS_INPUT_PORT_ID = "table_in"
const FILTER_ROWS_OUTPUT_PORT_ID = "table_out"

struct FilterRowsNode <: AbstractNode end

function configure(::Type{FilterRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    normalized = Dict{String,Any}(String(key) => value for (key, value) in pairs(params))

    input_port_id = String(get(normalized, "input_port_id", FILTER_ROWS_INPUT_PORT_ID))
    output_port_id = String(get(normalized, "output_port_id", FILTER_ROWS_OUTPUT_PORT_ID))
    predicate = String(get(normalized, "predicate", "true"))

    isempty(input_port_id) && error("input_port_id must not be empty")
    isempty(output_port_id) && error("output_port_id must not be empty")
    isempty(strip(predicate)) && error("predicate must not be empty")

    return NodeConfig(
        Dict(
            "input_port_id" => input_port_id,
            "output_port_id" => output_port_id,
            "predicate" => predicate,
        ),
    )
end

function infer_output_schema(::Type{FilterRowsNode}, input_schemas::Vector{PortSchema})
    validate_port_type(:data_table)
    input_label = isempty(input_schemas) ? "Filtered Rows" : input_schemas[1].label

    return [
        PortSchema(
            id = FILTER_ROWS_OUTPUT_PORT_ID,
            direction = :output,
            type = :data_table,
            label = input_label,
        ),
    ]
end

function execute(::Type{FilterRowsNode}, context::NodeContext)
    input_port_id = String(get(context.config.values, "input_port_id", FILTER_ROWS_INPUT_PORT_ID))
    output_port_id = String(get(context.config.values, "output_port_id", FILTER_ROWS_OUTPUT_PORT_ID))
    predicate = String(get(context.config.values, "predicate", "true"))

    haskey(context.inputs, input_port_id) || error("missing input payload for port $(input_port_id)")
    payload = context.inputs[input_port_id]

    validate_arrow_boundary(payload)
    haskey(payload, :ref) || error("Arrow payload missing ref field")
    isempty(strip(predicate)) && error("predicate must not be empty")

    rows = payload_rows(payload, context)
    if rows === nothing
        filtered_payload = (; payload..., predicate = predicate)
        return NodeResult(
            outputs = Dict(output_port_id => filtered_payload),
            telemetry = Dict(
                "node_key" => "base.filter_rows",
                "input_port_id" => input_port_id,
                "output_port_id" => output_port_id,
                "input_ref" => String(payload.ref),
                "predicate" => predicate,
                "materialized" => false,
            ),
            warnings = ["filter_rows requires materialized rows for execution"],
        )
    end

    filtered_rows = [row_to_dict(row) for row in rows if predicate_matches(row, predicate)]
    filtered_payload = table_payload(payload, context, "base.filter_rows", filtered_rows)

    return NodeResult(
        outputs = Dict(output_port_id => filtered_payload),
        telemetry = Dict(
            "node_key" => "base.filter_rows",
            "input_port_id" => input_port_id,
            "output_port_id" => output_port_id,
            "input_ref" => String(payload.ref),
            "output_ref" => filtered_payload.ref,
            "predicate" => predicate,
            "input_row_count" => length(rows),
            "row_count" => length(filtered_rows),
            "materialized" => true,
        ),
    )
end

function on_stream_event(::Type{FilterRowsNode}, event, state, ::NodeContext)
    return (event, state)
end
