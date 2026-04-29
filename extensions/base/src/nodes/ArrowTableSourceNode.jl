const SOURCE_OUTPUT_PORT_ID = "table_out"

struct ArrowTableSourceNode <: AbstractNode end

function configure(::Type{ArrowTableSourceNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    normalized = Dict{String,Any}(String(key) => value for (key, value) in pairs(params))

    output_port_id = String(get(normalized, "output_port_id", SOURCE_OUTPUT_PORT_ID))
    ref = String(get(normalized, "ref", ""))
    label = String(get(normalized, "label", "Arrow Table"))
    schema_ref = get(normalized, "schema_ref", nothing)

    isempty(output_port_id) && error("output_port_id must not be empty")
    isempty(ref) && error("ref must not be empty")

    return NodeConfig(
        Dict(
            "output_port_id" => output_port_id,
            "ref" => ref,
            "label" => label,
            "schema_ref" => schema_ref,
        ),
    )
end

function infer_output_schema(::Type{ArrowTableSourceNode}, ::Vector{PortSchema})
    validate_port_type(:data_table)

    return [
        PortSchema(
            id = SOURCE_OUTPUT_PORT_ID,
            direction = :output,
            type = :data_table,
            label = "Arrow Table",
        ),
    ]
end

function execute(::Type{ArrowTableSourceNode}, context::NodeContext)
    output_port_id = String(get(context.config.values, "output_port_id", SOURCE_OUTPUT_PORT_ID))
    ref = String(get(context.config.values, "ref", ""))
    schema_ref = get(context.config.values, "schema_ref", nothing)

    isempty(ref) && error("ref must not be empty")

    materialization = tabular_materialization_result(context, ref)
    rows = materialization === nothing ? nothing : materialization.rows
    payload = schema_ref === nothing ?
        (format = :arrow_ipc, ref = ref) :
        (format = :arrow_ipc, ref = ref, schema_ref = String(schema_ref))
    if materialization !== nothing
        payload = (; payload..., rows = rows, row_count = length(rows), materialized = true)
        materialization.schema === nothing || (payload = (; payload..., schema = materialization.schema))
    end

    telemetry = Dict(
        "node_key" => "base.arrow_table_source",
        "output_port_id" => output_port_id,
        "output_ref" => ref,
        "materialized" => rows !== nothing,
    )
    if rows !== nothing
        telemetry["row_count"] = length(rows)
        materialization.adapter === nothing || (telemetry["materialization_adapter"] = String(materialization.adapter))
    end

    return NodeResult(
        outputs = Dict(output_port_id => payload),
        telemetry = telemetry,
    )
end

function on_stream_event(::Type{ArrowTableSourceNode}, event, state, ::NodeContext)
    return (event, state)
end
