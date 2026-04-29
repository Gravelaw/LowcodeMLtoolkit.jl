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

function train_univariate_coefficients(rows, target_column::String, feature_columns::Vector{String})
    targets = numeric_values(rows, target_column)
    isempty(targets) && error("target column $(target_column) has no numeric values")
    target_mean = mean_value(targets)
    coefficients = Dict{String,Float64}()
    for feature in feature_columns
        values = numeric_values(rows, feature)
        length(values) == length(targets) || error("feature $(feature) numeric value count does not match target count")
        feature_mean = mean_value(values)
        numerator = sum((values[index] - feature_mean) * (targets[index] - target_mean) for index in eachindex(values))
        denominator = sum((value - feature_mean)^2 for value in values)
        coefficients[feature] = denominator == 0 ? 0.0 : numerator / denominator
    end
    intercept = target_mean - sum(get(coefficients, feature, 0.0) * mean_value(numeric_values(rows, feature)) for feature in feature_columns)
    return coefficients, intercept
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
    isempty(feature_columns) && error("feature_columns must contain at least one column")

    rows = payload_rows(payload, context)
    model_ref = "memory://models/$(context.execution_id)/$(context.node_id)"
    if rows === nothing
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
                "materialized" => false,
            ),
            warnings = ["linear_model_trainer requires materialized rows for training"],
        )
    end

    coefficients, intercept = train_univariate_coefficients(rows, target_column, feature_columns)
    model_payload = (
        format = :juliaflow_model,
        ref = model_ref,
        algorithm = algorithm,
        target_column = target_column,
        feature_columns = feature_columns,
        coefficients = coefficients,
        intercept = intercept,
        row_count = length(rows),
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
            "row_count" => length(rows),
            "materialized" => true,
        ),
    )
end

function on_stream_event(::Type{LinearModelTrainerNode}, event, state, ::NodeContext)
    return (event, state)
end
