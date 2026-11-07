module JuliaFlowDataScienceProjectMLJ

import DataFrames
import Serialization
using ..JuliaFlowDataScienceProjectStatistics

export mlj_algorithm_requested,
    mlj_package_status,
    mlj_model_family,
    mlj_model_kind,
    mlj_adapter_evidence,
    mlj_persist_machine_artifact,
    mlj_persisted_prediction_result,
    mlj_package_prediction_result,
    mlj_generated_training_code

function mlj_algorithm_requested(algorithm::AbstractString)
    normalized = lowercase(strip(String(algorithm)))
    return startswith(normalized, "mlj.") || occursin("mlj", normalized)
end

function env_bool_override(name::AbstractString)
    value = get(ENV, String(name), "")
    isempty(strip(value)) && return nothing
    normalized = lowercase(strip(value))
    normalized in ("1", "true", "yes", "available") && return true
    normalized in ("0", "false", "no", "unavailable") && return false
    return nothing
end

function package_available(package_name::AbstractString)
    override = env_bool_override("JULIAFLOW_TEST_$(uppercase(String(package_name)))_AVAILABLE")
    override === nothing || return override
    return Base.find_package(String(package_name)) !== nothing
end

function package_version(package_name::AbstractString, available::Bool)
    available || return nothing
    override = get(ENV, "JULIAFLOW_TEST_$(uppercase(String(package_name)))_VERSION", "")
    !isempty(strip(override)) && return strip(override)
    return "installed"
end

function mlj_package_status()
    mlj_available = package_available("MLJ")
    linear_available = package_available("MLJLinearModels")
    package_fit_enabled = env_bool_override("JULIAFLOW_ENABLE_MLJ_PACKAGE_FIT") === true
    return Dict{String,Any}(
        "mljPackageAvailable" => mlj_available,
        "mljLinearModelsPackageAvailable" => linear_available,
        "mljPackageVersion" => package_version("MLJ", mlj_available),
        "mljLinearModelsPackageVersion" => package_version("MLJLinearModels", linear_available),
        "mljPackageFitEnabled" => package_fit_enabled,
        "mljPackageDetectionMode" => (
            haskey(ENV, "JULIAFLOW_TEST_MLJ_AVAILABLE") || haskey(ENV, "JULIAFLOW_TEST_MLJLINEARMODELS_AVAILABLE") ?
                "env_override" :
                "base_find_package"
        ),
    )
end

function mlj_supported_package_model(algorithm::AbstractString; classifier_mode::Bool = false)
    normalized = lowercase(String(algorithm))
    if classifier_mode
        return occursin("logistic", normalized)
    end
    return occursin("linear", normalized)
end

function mlj_capability_status(package_status::AbstractDict, algorithm::AbstractString; classifier_mode::Bool = false)
    packages_available = Bool(get(package_status, "mljPackageAvailable", false)) &&
        Bool(get(package_status, "mljLinearModelsPackageAvailable", false))
    package_fit_enabled = Bool(get(package_status, "mljPackageFitEnabled", false))
    supported_model = mlj_supported_package_model(algorithm; classifier_mode = classifier_mode)
    route_wired = packages_available && package_fit_enabled && supported_model
    support_status = route_wired ? "ready_missing_training_data" :
        (!packages_available ? "packages_unavailable" :
            (!package_fit_enabled ? "disabled_by_default" : "unsupported_algorithm"))
    support_reason = support_status == "ready_missing_training_data" ?
        "MLJ package-backed fitting is route-wired and waiting for train-scope feature/target rows." :
        (support_status == "packages_unavailable" ?
            "MLJ and MLJLinearModels are not both discoverable in the active Julia project." :
            (support_status == "disabled_by_default" ?
                "MLJ package-backed fitting is disabled by default; set JULIAFLOW_ENABLE_MLJ_PACKAGE_FIT=true after dependency and reproducibility review." :
                "The requested MLJ algorithm is outside the bounded LinearRegressor/LogisticClassifier package-backed proof family."))
    return Dict{String,Any}(
        "mljPackagesAvailable" => packages_available,
        "mljPackageFitSupported" => route_wired,
        "mljPackageFitRouteWired" => route_wired,
        "mljPackageFitAttempted" => false,
        "mljPackageFitExecuted" => false,
        "mljPackageScoringExecuted" => false,
        "mljPackageSupportStatus" => support_status,
        "mljPackageExecutionStatus" => support_status,
        "mljPackageExecutionReason" => support_reason,
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

function mlj_training_data_ready(train_feature_pairs, train_target)
    train_feature_pairs === nothing && return false
    train_target === nothing && return false
    isempty(train_feature_pairs) && return false
    isempty(train_target) && return false
    target_count = length(train_target)
    target_count > 0 || return false
    for pair in train_feature_pairs
        length(pair.second) == target_count || return false
    end
    return true
end

function mlj_runtime_imports_available()
    try
        Base.eval(@__MODULE__, :(import MLJ))
        Base.eval(@__MODULE__, :(import MLJLinearModels))
        return true, ""
    catch error
        return false, sprint(showerror, error)
    end
end

function mlj_persist_machine_artifact(
    algorithm::AbstractString,
    train_feature_pairs,
    train_target,
    artifact_path::AbstractString;
    classifier_mode::Bool = false,
)
    package_status = mlj_package_status()
    capability_status = mlj_capability_status(package_status, algorithm; classifier_mode = classifier_mode)
    if !mlj_algorithm_requested(algorithm) || !Bool(get(capability_status, "mljPackageFitRouteWired", false))
        return Dict{String,Any}(
            "mljMachinePersistenceStatus" => "unavailable",
            "mljMachinePersistenceReason" => String(get(capability_status, "mljPackageExecutionReason", "MLJ package persistence is unavailable.")),
        )
    end
    mlj_training_data_ready(train_feature_pairs, train_target) || return Dict{String,Any}(
        "mljMachinePersistenceStatus" => "missing_training_data",
        "mljMachinePersistenceReason" => "MLJ machine persistence requires aligned train-scope feature and target rows.",
    )
    runtime_available, runtime_error = mlj_runtime_imports_available()
    runtime_available || return Dict{String,Any}(
        "mljMachinePersistenceStatus" => "runtime_import_failed",
        "mljMachinePersistenceReason" => "MLJ machine persistence runtime imports failed: $(runtime_error)",
    )

    try
        return Base.invokelatest(() -> begin
            frame = mlj_feature_frame(train_feature_pairs)
            y = classifier_mode ? MLJ.coerce(string.(collect(train_target)), MLJ.Multiclass) : collect(train_target)
            model_type = Base.eval(
                @__MODULE__,
                classifier_mode ?
                    :(MLJ.@load LogisticClassifier pkg=MLJLinearModels verbosity=0) :
                    :(MLJ.@load LinearRegressor pkg=MLJLinearModels verbosity=0),
            )
            machine = MLJ.machine(model_type(), frame, y)
            MLJ.fit!(machine, verbosity = 0)
            mkpath(dirname(String(artifact_path)))
            open(String(artifact_path), "w") do io
                Serialization.serialize(io, machine)
            end
            Dict{String,Any}(
                "mljMachinePersistenceStatus" => "persisted",
                "mljMachinePersistenceReason" => "Fitted MLJ machine serialized after train-scope fitting.",
                "mljMachineArtifactPath" => String(artifact_path),
                "mljMachineModelType" => String(nameof(model_type)),
                "mljMachineFeatureColumns" => [String(pair.first) for pair in train_feature_pairs],
                "mljMachinePredictionMode" => classifier_mode ? "positive_class_probability" : "continuous_prediction",
                "mljMachinePositiveLabel" => classifier_mode ? string(maximum(Float64.(collect(train_target)))) : "",
                "mljMachineTrainingRowCount" => length(y),
            )
        end)
    catch error
        return Dict{String,Any}(
            "mljMachinePersistenceStatus" => "persistence_failed",
            "mljMachinePersistenceReason" => "Fitted MLJ machine persistence failed: $(sprint(showerror, error))",
        )
    end
end

function mlj_persisted_prediction_result(
    artifact_path::AbstractString,
    prediction_feature_pairs;
    classifier_mode::Bool = false,
    positive_label::AbstractString = "",
)
    isfile(String(artifact_path)) || return Dict{String,Any}(
        "status" => "artifact_missing",
        "reason" => "Persisted MLJ machine artifact was not found.",
    )
    (prediction_feature_pairs === nothing || isempty(prediction_feature_pairs)) && return Dict{String,Any}(
        "status" => "missing_prediction_data",
        "reason" => "Persisted MLJ machine scoring requires feature rows.",
    )
    runtime_available, runtime_error = mlj_runtime_imports_available()
    runtime_available || return Dict{String,Any}(
        "status" => "runtime_import_failed",
        "reason" => "Persisted MLJ machine scoring runtime imports failed: $(runtime_error)",
    )

    try
        return Base.invokelatest(() -> begin
            machine = open(String(artifact_path), "r") do io
                Serialization.deserialize(io)
            end
            frame = mlj_feature_frame(prediction_feature_pairs)
            raw_predictions = MLJ.predict(machine, frame)
            values = if classifier_mode
                isempty(strip(String(positive_label))) && error("positive class label required")
                [Float64(MLJ.pdf(prediction, String(positive_label))) for prediction in raw_predictions]
            else
                Float64.(raw_predictions)
            end
            Dict{String,Any}(
                "status" => "scored",
                "predictions" => [round(value; digits = 6) for value in values],
                "predictionCount" => length(values),
                "predictionMode" => classifier_mode ? "positive_class_probability" : "continuous_prediction",
                "scoringSource" => "persisted_mlj_machine",
            )
        end)
    catch error
        return Dict{String,Any}(
            "status" => "scoring_failed",
            "reason" => "Persisted MLJ machine scoring failed: $(sprint(showerror, error))",
        )
    end
end

function mlj_runtime_fit_attempt(
    algorithm::AbstractString,
    train_feature_pairs,
    train_target;
    classifier_mode::Bool = false,
)
    runtime_available, runtime_error = mlj_runtime_imports_available()
    runtime_available || return Dict{String,Any}(
        "mljPackageFitAttempted" => true,
        "mljPackageRuntimeAvailable" => false,
        "mljPackageFitExecuted" => false,
        "mljPackageScoringExecuted" => false,
        "mljPackageExecutionStatus" => "runtime_import_failed",
        "mljPackageExecutionReason" => "MLJ package-backed fitting was route-wired, but runtime imports failed: $(runtime_error)",
    )

    try
        return Base.invokelatest(() -> begin
            frame = DataFrames.DataFrame(
                Dict(Symbol(pair.first) => collect(pair.second) for pair in train_feature_pairs)
            )
            y = classifier_mode ? MLJ.coerce(string.(collect(train_target)), MLJ.Multiclass) : collect(train_target)
            model_type = Base.eval(
                @__MODULE__,
                classifier_mode ?
                    :(MLJ.@load LogisticClassifier pkg=MLJLinearModels verbosity=0) :
                    :(MLJ.@load LinearRegressor pkg=MLJLinearModels verbosity=0),
            )
            model = model_type()
            machine = MLJ.machine(model, frame, y)
            MLJ.fit!(machine, verbosity = 0)
            predictions = MLJ.predict(machine, frame)
            Dict{String,Any}(
                "mljPackageFitAttempted" => true,
                "mljPackageRuntimeAvailable" => true,
                "mljPackageFitExecuted" => true,
                "mljPackageScoringExecuted" => true,
                "mljPackageExecutionStatus" => "fit_executed",
                "mljPackageExecutionReason" => "MLJ package-backed fitting executed on train-scope rows.",
                "mljPackageModelType" => String(nameof(model_type)),
                "mljPackagePredictionCount" => length(predictions),
                "mljPackageTrainingRowCount" => length(y),
                "mljPackageTrainingColumnCount" => length(train_feature_pairs),
                "mljPackageFitBackend" => "local_cpu",
                "mljPackageRequestedAlgorithm" => String(algorithm),
            )
        end)
    catch error
        return Dict{String,Any}(
            "mljPackageFitAttempted" => true,
            "mljPackageRuntimeAvailable" => true,
            "mljPackageFitExecuted" => false,
            "mljPackageScoringExecuted" => false,
            "mljPackageExecutionStatus" => "fit_failed",
            "mljPackageExecutionReason" => "MLJ package-backed fitting failed and local CSV fallback remains active: $(sprint(showerror, error))",
        )
    end
end

function mlj_feature_frame(feature_pairs)
    return DataFrames.DataFrame(Dict(Symbol(pair.first) => collect(pair.second) for pair in feature_pairs))
end

function mlj_prediction_data_ready(train_feature_pairs, train_target, prediction_feature_pairs)
    mlj_training_data_ready(train_feature_pairs, train_target) || return false
    prediction_feature_pairs === nothing && return false
    isempty(prediction_feature_pairs) && return false
    prediction_count = length(first(prediction_feature_pairs).second)
    prediction_count > 0 || return false
    train_columns = Set(String(pair.first) for pair in train_feature_pairs)
    prediction_columns = Set(String(pair.first) for pair in prediction_feature_pairs)
    train_columns == prediction_columns || return false
    for pair in prediction_feature_pairs
        length(pair.second) == prediction_count || return false
    end
    return true
end

function mlj_order_prediction_pairs(train_feature_pairs, prediction_feature_pairs)
    by_name = Dict(String(pair.first) => pair.second for pair in prediction_feature_pairs)
    return [String(pair.first) => by_name[String(pair.first)] for pair in train_feature_pairs]
end

function mlj_package_prediction_result(
    algorithm::AbstractString,
    train_feature_pairs,
    train_target,
    prediction_feature_pairs;
    classifier_mode::Bool = false,
)
    package_status = mlj_package_status()
    capability_status = mlj_capability_status(package_status, algorithm; classifier_mode = classifier_mode)
    if !mlj_algorithm_requested(algorithm) || !Bool(get(capability_status, "mljPackageFitRouteWired", false))
        return nothing
    end
    mlj_prediction_data_ready(train_feature_pairs, train_target, prediction_feature_pairs) || return nothing
    runtime_available, _ = mlj_runtime_imports_available()
    runtime_available || return nothing
    ordered_prediction_pairs = mlj_order_prediction_pairs(train_feature_pairs, prediction_feature_pairs)
    try
        return Base.invokelatest(() -> begin
            train_frame = mlj_feature_frame(train_feature_pairs)
            prediction_frame = mlj_feature_frame(ordered_prediction_pairs)
            y = classifier_mode ? MLJ.coerce(string.(collect(train_target)), MLJ.Multiclass) : collect(train_target)
            model_type = Base.eval(
                @__MODULE__,
                classifier_mode ?
                    :(MLJ.@load LogisticClassifier pkg=MLJLinearModels verbosity=0) :
                    :(MLJ.@load LinearRegressor pkg=MLJLinearModels verbosity=0),
            )
            model = model_type()
            machine = MLJ.machine(model, train_frame, y)
            MLJ.fit!(machine, verbosity = 0)
            raw_predictions = MLJ.predict(machine, prediction_frame)
            prediction_values = if classifier_mode
                positive_label = string(maximum(Float64.(collect(train_target))))
                [Float64(MLJ.pdf(prediction, positive_label)) for prediction in raw_predictions]
            else
                Float64.(raw_predictions)
            end
            scoring_evidence = Dict{String,Any}(
                "mljPackageRuntimeAvailable" => true,
                "mljPackageFitAttempted" => true,
                "mljPackageFitExecuted" => true,
                "mljPackageScoringExecuted" => true,
                "mljPackageExecutionStatus" => "scoring_executed",
                "mljPackageExecutionReason" => "MLJ package-backed model refit on train-scope rows and scored requested rows.",
                "mljPackageModelType" => String(nameof(model_type)),
                "mljPackageTrainingRowCount" => length(y),
                "mljPackageTrainingColumnCount" => length(train_feature_pairs),
                "mljPackagePredictionCount" => length(prediction_values),
                "mljPackageFitBackend" => "local_cpu",
                "mljPackageRequestedAlgorithm" => String(algorithm),
                "mljPackagePredictionMode" => classifier_mode ? "positive_class_probability" : "continuous_prediction",
                "mljPackageScoringSource" => "refit_from_train_scope_rows",
            )
            evidence = Dict{String,Any}()
            merge!(evidence, package_status)
            merge!(evidence, capability_status)
            merge!(evidence, scoring_evidence)
            return Dict{String,Any}(
                "predictions" => [round(value; digits = 6) for value in prediction_values],
                "evidence" => evidence,
            )
        end)
    catch
        return nothing
    end
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
    train_feature_pairs = nothing,
    train_target = nothing,
)
    package_status = mlj_package_status()
    requested = mlj_algorithm_requested(algorithm)
    capability_status = mlj_capability_status(package_status, algorithm; classifier_mode = classifier_mode)
    if requested && Bool(get(capability_status, "mljPackageFitRouteWired", false))
        if mlj_training_data_ready(train_feature_pairs, train_target)
            merge!(
                capability_status,
                mlj_runtime_fit_attempt(
                    algorithm,
                    train_feature_pairs,
                    train_target;
                    classifier_mode = classifier_mode,
                ),
            )
        else
            capability_status["mljPackageExecutionStatus"] = "ready_missing_training_data"
            capability_status["mljPackageExecutionReason"] = "MLJ package-backed fitting is route-wired, but train-scope feature/target rows were not supplied."
        end
        capability_status["mljPackageSupportStatus"] = String(capability_status["mljPackageExecutionStatus"])
    end
    packages_available = Bool(capability_status["mljPackagesAvailable"])
    fit_executed = Bool(capability_status["mljPackageFitExecuted"])
    execution_mode = requested && fit_executed ? "mlj_package_backed_local_cpu" :
        (requested && packages_available ? "mlj_available_local_csv_adapter" :
            (requested ? "mlj_unavailable_local_csv_fallback" : "local_csv_native"))
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
        "localFallbackUsed" => requested && !fit_executed,
    )
    merge!(evidence, package_status)
    merge!(evidence, capability_status)
    if requested && !fit_executed
        evidence["mljUnavailableReason"] = String(capability_status["mljPackageExecutionReason"])
        evidence["mljFallbackReason"] = packages_available ?
            "MLJ package-backed fitting did not complete for this route; local CSV artifact training is recorded as the explicit adapter fallback with package-fit enablement, route-wiring, and runtime status preserved." :
            "MLJ and MLJLinearModels are not installed in the active Julia project; local CSV artifact training was used as the explicit fallback."
    elseif requested && fit_executed
        evidence["mljFallbackReason"] = "MLJ package-backed fitting executed; deterministic local CSV coefficients remain stored as reproducibility fallback evidence."
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
            "# requestedAlgorithm: $(JuliaFlowDataScienceProjectStatistics.generated_code_comment_metadata(algorithm))",
            "# targetColumn: $(JuliaFlowDataScienceProjectStatistics.generated_code_comment_metadata(target_column))",
            "# featureColumns: $(JuliaFlowDataScienceProjectStatistics.generated_code_comment_metadata(join(String.(feature_columns), ", ")))",
            "using MLJ",
            "using MLJLinearModels",
            "model = @load $(model_name) pkg=MLJLinearModels",
            "mach = machine(model, X_train, y_train)",
            "fit!(mach)",
            "yhat = predict(mach, X_validation)",
            "# JuliaFlow records package availability, explicit enablement, route wiring, and execution separately.",
            "# When mljPackageFitExecuted is false, deterministic local CSV artifact scoring remains the explicit fallback.",
        ],
        "\n",
    ) * "\n"
end

end
