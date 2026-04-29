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

    rows = payload_rows(payload, context)
    writer_result = rows === nothing ? nothing : persist_tabular_rows(context, destination_uri, rows)
    storage_root = local_storage_root(context)
    target_path = writer_result === nothing && storage_root !== nothing ? confined_storage_write_path(String(storage_root), destination_uri) : nothing
    telemetry = Dict{String,Any}(
        "node_key" => "base.arrow_table_sink",
        "input_port_id" => input_port_id,
        "input_ref" => String(payload.ref),
        "destination_uri" => destination_uri,
        "mode" => mode,
    )
    warnings = String[]

    if rows === nothing
        push!(warnings, "arrow_table_sink requires materialized rows for persistence")
    elseif writer_result !== nothing
        telemetry["persisted"] = true
        telemetry["persistence_adapter"] = String(writer_result.adapter)
        telemetry["row_count"] = writer_result.row_count
        writer_result.ref === nothing || (telemetry["persisted_ref"] = String(writer_result.ref))
        writer_result.path === nothing || (telemetry["persisted_path"] = String(writer_result.path))
    elseif target_path === nothing
        push!(warnings, "arrow_table_sink requires tabular_ref_writer, tabular_ref_root, or object_store_root for persistence")
    else
        persisted_rows = Dict{String,Any}[]
        if lowercase(mode) == "append" && isfile(target_path)
            for row in rows_from_json_ref(target_path, context)
                checked_output_push!(persisted_rows, row, context)
            end
        elseif !(lowercase(mode) in ["overwrite", "append"])
            error("unsupported sink mode $(mode)")
        end
        for row in rows
            checked_output_push!(persisted_rows, row, context)
        end
        write(target_path, JSON3.write(Dict("rows" => persisted_rows)))
        telemetry["persisted"] = true
        telemetry["persisted_path"] = target_path
        telemetry["row_count"] = length(persisted_rows)
        telemetry["written_row_count"] = length(rows)
    end

    return NodeResult(
        telemetry = telemetry,
        warnings = warnings,
    )
end

function on_stream_event(::Type{ArrowTableSinkNode}, event, state, ::NodeContext)
    return (event, state)
end
