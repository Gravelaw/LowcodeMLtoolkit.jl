module JuliaFlowDataScienceProjectMLJ

export mlj_algorithm_requested,
    mlj_package_status,
    mlj_model_family,
    mlj_model_kind,
    mlj_adapter_evidence,
    mlj_generated_training_code

function mlj_algorithm_requested(algorithm::AbstractString)
    normalized = lowercase(strip(String(algorithm)))
    return startswith(normalized, "mlj.") || occursin("mlj", normalized)
end

function mlj_package_status()
    return Dict{String,Any}(
        "mljPackageAvailable" => Base.find_package("MLJ") !== nothing,
        "mljLinearModelsPackageAvailable" => Base.find_package("MLJLinearModels") !== nothing,
    )
end

function mlj_model_family(algorithm::AbstractString; classifier_mode::Bool = false)
    requested = mlj_algorithm_requested(algorithm)
    normalized = lowercase(String(algorithm))
    if classifier_mode
        if requested && (occursin("logistic", normalized) || occursin("classifier", normalized) || occursin("xgboost", normalized))
            return "mlj_binary_classification"
        end
        return "local_csv_binary_centroid"
    end
    return requested ? "mlj_regression" : "local_csv_ols"
end

function mlj_model_kind(native_model_kind::AbstractString, algorithm::AbstractString; classifier_mode::Bool = false)
    mlj_algorithm_requested(algorithm) || return String(native_model_kind)
    classifier_mode && return "mlj_compatible_binary_classifier"
    return "mlj_compatible_linear_regressor"
end

function mlj_adapter_evidence(
    algorithm::AbstractString,
    native_model_kind::AbstractString,
    feature_columns::AbstractVector,
    target_column::AbstractString;
    classifier_mode::Bool = false,
)
    package_status = mlj_package_status()
    requested = mlj_algorithm_requested(algorithm)
    packages_available = Bool(package_status["mljPackageAvailable"]) && Bool(package_status["mljLinearModelsPackageAvailable"])
    execution_mode = requested && packages_available ? "mlj_package_backed_local_cpu" :
        (requested ? "mlj_unavailable_local_csv_fallback" : "local_csv_native")
    evidence = Dict{String,Any}(
        "requestedAlgorithm" => String(algorithm),
        "modelFamily" => mlj_model_family(algorithm; classifier_mode = classifier_mode),
        "modelKind" => mlj_model_kind(native_model_kind, algorithm; classifier_mode = classifier_mode),
        "nativeModelKind" => String(native_model_kind),
        "targetColumn" => String(target_column),
        "featureColumns" => String.(feature_columns),
        "mljRequested" => requested,
        "mljExecutionMode" => execution_mode,
        "mljAdapterVersion" => "1.0",
        "localFallbackUsed" => requested && !packages_available,
    )
    merge!(evidence, package_status)
    if requested && !packages_available
        evidence["mljUnavailableReason"] = "MLJ and MLJLinearModels are not installed in the active Julia project; local CSV artifact training was used as the explicit fallback."
    end
    return evidence
end

function mlj_generated_training_code(
    algorithm::AbstractString,
    target_column::AbstractString,
    feature_columns::AbstractVector;
    classifier_mode::Bool = false,
)
    model_name = classifier_mode ? "LogisticClassifier" : "LinearRegressor"
    return join(
        [
            "# JuliaFlow MLJ-compatible local training artifact",
            "# requestedAlgorithm: $(String(algorithm))",
            "# targetColumn: $(String(target_column))",
            "# featureColumns: $(join(String.(feature_columns), ", "))",
            "using MLJ",
            "using MLJLinearModels",
            "model = @load $(model_name) pkg=MLJLinearModels",
            "# JuliaFlow falls back to deterministic local CSV artifact scoring when MLJ packages are unavailable.",
        ],
        "\n",
    ) * "\n"
end

end
