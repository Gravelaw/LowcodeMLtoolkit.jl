const DEFAULT_INPUT_PORT_ID = "table_in"
const DEFAULT_OUTPUT_PORT_ID = "table_out"

struct ArrowPassthroughNode <: AbstractNode end

function configure(::Type{ArrowPassthroughNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    normalized = Dict{String,Any}(String(key) => value for (key, value) in pairs(params))

    input_port_id = String(get(normalized, "input_port_id", DEFAULT_INPUT_PORT_ID))
    output_port_id = String(get(normalized, "output_port_id", DEFAULT_OUTPUT_PORT_ID))
    label = String(get(normalized, "label", "Arrow Table"))

    isempty(input_port_id) && error("input_port_id must not be empty")
    isempty(output_port_id) && error("output_port_id must not be empty")

    return NodeConfig(
        Dict(
            "input_port_id" => input_port_id,
            "output_port_id" => output_port_id,
            "label" => label,
        ),
    )
end

function infer_output_schema(::Type{ArrowPassthroughNode}, input_schemas::Vector{PortSchema})
    validate_port_type(:data_table)
    input_label = isempty(input_schemas) ? "Arrow Table" : input_schemas[1].label

    return [
        PortSchema(
            id = DEFAULT_OUTPUT_PORT_ID,
            direction = :output,
            type = :data_table,
            label = input_label,
        ),
    ]
end

function execute(::Type{ArrowPassthroughNode}, context::NodeContext)
    input_port_id = String(get(context.config.values, "input_port_id", DEFAULT_INPUT_PORT_ID))
    output_port_id = String(get(context.config.values, "output_port_id", DEFAULT_OUTPUT_PORT_ID))

    haskey(context.inputs, input_port_id) || error("missing input payload for port $(input_port_id)")
    payload = context.inputs[input_port_id]

    validate_arrow_boundary(payload)
    haskey(payload, :ref) || error("Arrow payload missing ref field")

    return NodeResult(
        outputs = Dict(output_port_id => payload),
        telemetry = Dict(
            "node_key" => "base.arrow_passthrough",
            "input_port_id" => input_port_id,
            "output_port_id" => output_port_id,
            "input_ref" => String(payload.ref),
            "boundary_format" => String(payload.format),
        ),
    )
end

function on_stream_event(::Type{ArrowPassthroughNode}, event, state, ::NodeContext)
    return (event, state)
end
