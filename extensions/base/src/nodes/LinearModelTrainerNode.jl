const TRAINER_INPUT_PORT_ID = "table_in"
const TRAINER_OUTPUT_PORT_ID = "model_out"

struct LinearModelTrainerNode <: AbstractNode end

function configure(::Type{LinearModelTrainerNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    normalized = Dict{String,Any}(String(key) => value for (key, value) in pairs(params))

    input_port_id = String(get(normalized, "input_port_id", TRAINER_INPUT_PORT_ID))
    output_port_id = String(get(normalized, "output_port_id", TRAINER_OUTPUT_PORT_ID))
    target_column = String(get(normalized, "target_column", ""))
    raw_feature_columns = get(normalized, "feature_columns", String[])
    feature_columns = [String(column) for column in raw_feature_columns]
    algorithm = String(get(normalized, "algorithm", "linear_regression"))

    isempty(input_port_id) && error("input_port_id must not be empty")
    isempty(output_port_id) && error("output_port_id must not be empty")
    isempty(target_column) && error("target_column must not be empty")

    return NodeConfig(
        Dict(
            "input_port_id" => input_port_id,
            "output_port_id" => output_port_id,
            "target_column" => target_column,
            "feature_columns" => feature_columns,
            "algorithm" => algorithm,
        ),
    )
end

function infer_output_schema(::Type{LinearModelTrainerNode}, ::Vector{PortSchema})
    validate_port_type(:model)

    return [
        PortSchema(
            id = TRAINER_OUTPUT_PORT_ID,
            direction = :output,
            type = :model,
            label = "Trained Model",
        ),
    ]
end

function execute(::Type{LinearModelTrainerNode}, context::NodeContext)
    input_port_id = String(get(context.config.values, "input_port_id", TRAINER_INPUT_PORT_ID))
    output_port_id = String(get(context.config.values, "output_port_id", TRAINER_OUTPUT_PORT_ID))
    target_column = String(get(context.config.values, "target_column", ""))
    feature_columns = [String(column) for column in get(context.config.values, "feature_columns", String[])]
    algorithm = String(get(context.config.values, "algorithm", "linear_regression"))

    haskey(context.inputs, input_port_id) || error("missing input payload for port $(input_port_id)")
    payload = context.inputs[input_port_id]

    validate_arrow_boundary(payload)
    haskey(payload, :ref) || error("Arrow payload missing ref field")
    isempty(target_column) && error("target_column must not be empty")

    model_ref = "memory://models/$(context.execution_id)/$(context.node_id)"
    model_payload = (
        format = :juliaflow_model_stub,
        ref = model_ref,
        algorithm = algorithm,
        target_column = target_column,
        feature_columns = feature_columns,
        trained_from_ref = String(payload.ref),
    )

    return NodeResult(
        outputs = Dict(output_port_id => model_payload),
        telemetry = Dict(
            "node_key" => "base.linear_model_trainer",
            "input_port_id" => input_port_id,
            "output_port_id" => output_port_id,
            "training_ref" => String(payload.ref),
            "algorithm" => algorithm,
            "feature_count" => length(feature_columns),
        ),
        warnings = ["placeholder trainer emits model metadata only"],
    )
end

function on_stream_event(::Type{LinearModelTrainerNode}, event, state, ::NodeContext)
    return (event, state)
end
