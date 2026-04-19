const SINK_INPUT_PORT_ID = "table_in"

struct ArrowTableSinkNode <: AbstractNode end

function configure(::Type{ArrowTableSinkNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    normalized = Dict{String,Any}(String(key) => value for (key, value) in pairs(params))

    input_port_id = String(get(normalized, "input_port_id", SINK_INPUT_PORT_ID))
    destination_uri = String(get(normalized, "destination_uri", ""))
    mode = String(get(normalized, "mode", "overwrite"))

    isempty(input_port_id) && error("input_port_id must not be empty")
    isempty(destination_uri) && error("destination_uri must not be empty")

    return NodeConfig(
        Dict(
            "input_port_id" => input_port_id,
            "destination_uri" => destination_uri,
            "mode" => mode,
        ),
    )
end

function infer_output_schema(::Type{ArrowTableSinkNode}, ::Vector{PortSchema})
    return PortSchema[]
end

function execute(::Type{ArrowTableSinkNode}, context::NodeContext)
    input_port_id = String(get(context.config.values, "input_port_id", SINK_INPUT_PORT_ID))
    destination_uri = String(get(context.config.values, "destination_uri", ""))
    mode = String(get(context.config.values, "mode", "overwrite"))

    haskey(context.inputs, input_port_id) || error("missing input payload for port $(input_port_id)")
    payload = context.inputs[input_port_id]

    validate_arrow_boundary(payload)
    haskey(payload, :ref) || error("Arrow payload missing ref field")

    return NodeResult(
        telemetry = Dict(
            "node_key" => "base.arrow_table_sink",
            "input_port_id" => input_port_id,
            "input_ref" => String(payload.ref),
            "destination_uri" => destination_uri,
            "mode" => mode,
        ),
        warnings = ["placeholder sink does not persist data yet"],
    )
end

function on_stream_event(::Type{ArrowTableSinkNode}, event, state, ::NodeContext)
    return (event, state)
end
