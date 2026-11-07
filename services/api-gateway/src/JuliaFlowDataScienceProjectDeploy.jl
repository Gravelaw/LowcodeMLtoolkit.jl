module JuliaFlowDataScienceProjectDeploy

using ..JuliaFlowGatewayRepository
using SHA

export local_deploy_service_code,
    deploy_package_records,
    deploy_endpoint_config,
    deploy_model_artifact,
    deploy_model_ref,
    deploy_runtime_inference_mode,
    deploy_artifact_evidence,
    deploy_package_record,
    deploy_package_checksum_payload

function normalized_dict(value)
    return Dict{String,Any}(String(key) => item for (key, item) in pairs(value))
end

function local_csv_ols_service_code(model_id::AbstractString, endpoint_url::AbstractString, model_ref::AbstractString, model_artifact::AbstractDict)
    feature_columns = String.(get(model_artifact, "featureColumns", [String(get(model_artifact, "featureColumn", ""))]))
    isempty(feature_columns) && (feature_columns = [String(get(model_artifact, "featureColumn", ""))])
    inference_mode = String(get(model_artifact, "modelKind", "local_csv_single_feature_ols"))
    return """using Genie, JSON3

const MODEL_PATH = "$(String(model_ref))"
const FEATURE_COLUMNS = $(repr(feature_columns))

function local_model_path(ref::AbstractString)
    if startswith(String(ref), "local://")
        data_root = get(ENV, "JULIAFLOW_DATA_ESTATE_ROOT", joinpath(homedir(), ".juliaflow", "data"))
        relative = replace(String(ref), "local://" => "")
        return joinpath(data_root, split(relative, "/")...)
    end
    return String(ref)
end

function load_model()
    return JSON3.read(read(local_model_path(MODEL_PATH), String), Dict{String,Any})
end

function numeric_payload_value(payload, name::AbstractString)
    if payload isa AbstractDict && haskey(payload, name)
        return Float64(payload[name])
    elseif payload isa AbstractDict && haskey(payload, "features")
        features = payload["features"]
        if features isa AbstractDict && haskey(features, name)
            return Float64(features[name])
        end
    end
    error("missing numeric feature: " * String(name))
end

function score(payload)
    model = load_model()
    coefficients = model["coefficients"]
    intercept = Float64(coefficients["intercept"])
    if haskey(model, "featureColumns") && haskey(coefficients, "slopes")
        slopes = coefficients["slopes"]
        prediction = intercept
        for column in model["featureColumns"]
            prediction += Float64(slopes[String(column)]) * numeric_payload_value(payload, String(column))
        end
        return round(prediction; digits = 6)
    end
    feature = numeric_payload_value(payload, String(model["featureColumn"]))
    return round(intercept + Float64(coefficients["slope"]) * feature; digits = 6)
end

route("/v1/predict", method = POST) do
    payload = JSON3.read(rawpayload())
    prediction = score(payload)
    return JSON3.write(Dict(
        "modelId" => "$(String(model_id))",
        "endpoint" => "$(String(endpoint_url))",
        "localOnly" => true,
        "modelArtifactRef" => MODEL_PATH,
        "inferenceMode" => "$(inference_mode)",
        "featureColumns" => FEATURE_COLUMNS,
        "prediction" => prediction,
    ))
end

up(host = "127.0.0.1", port = 8000)
"""
end

function local_csv_binary_classifier_service_code(model_id::AbstractString, endpoint_url::AbstractString, model_ref::AbstractString, model_artifact::AbstractDict)
    feature_columns = String.(get(model_artifact, "featureColumns", String[]))
    inference_mode = String(get(model_artifact, "modelKind", "local_csv_binary_centroid_classifier"))
    return """using Genie, JSON3

const MODEL_PATH = "$(String(model_ref))"
const FEATURE_COLUMNS = $(repr(feature_columns))

function local_model_path(ref::AbstractString)
    if startswith(String(ref), "local://")
        data_root = get(ENV, "JULIAFLOW_DATA_ESTATE_ROOT", joinpath(homedir(), ".juliaflow", "data"))
        relative = replace(String(ref), "local://" => "")
        return joinpath(data_root, split(relative, "/")...)
    end
    return String(ref)
end

function load_model()
    return JSON3.read(read(local_model_path(MODEL_PATH), String), Dict{String,Any})
end

function numeric_payload_value(payload, name::AbstractString)
    if payload isa AbstractDict && haskey(payload, name)
        return Float64(payload[name])
    elseif payload isa AbstractDict && haskey(payload, "features")
        features = payload["features"]
        if features isa AbstractDict && haskey(features, name)
            return Float64(features[name])
        end
    end
    error("missing numeric feature: " * String(name))
end

function score(payload)
    model = load_model()
    coefficients = model["coefficients"]
    positive_means = coefficients["positiveMeans"]
    negative_means = coefficients["negativeMeans"]
    scales = coefficients["featureScales"]
    prior = min(max(Float64(coefficients["positivePrior"]), 1.0e-6), 1.0 - 1.0e-6)
    raw_score = log(prior / (1.0 - prior))
    usable = 0
    for column in model["featureColumns"]
        name = String(column)
        positive_mean = Float64(positive_means[name])
        negative_mean = Float64(negative_means[name])
        midpoint = (positive_mean + negative_mean) / 2
        direction = positive_mean >= negative_mean ? 1.0 : -1.0
        scale = max(Float64(scales[name]), 1.0e-6)
        raw_score += direction * (numeric_payload_value(payload, name) - midpoint) / scale
        usable += 1
    end
    usable > 0 && (raw_score /= usable)
    probability = round(1.0 / (1.0 + exp(-raw_score)); digits = 6)
    positive_label = Float64(coefficients["positiveLabel"])
    negative_label = Float64(coefficients["negativeLabel"])
    return probability, probability >= 0.5 ? positive_label : negative_label
end

route("/v1/predict", method = POST) do
    payload = JSON3.read(rawpayload())
    probability, prediction = score(payload)
    return JSON3.write(Dict(
        "modelId" => "$(String(model_id))",
        "endpoint" => "$(String(endpoint_url))",
        "localOnly" => true,
        "modelArtifactRef" => MODEL_PATH,
        "inferenceMode" => "$(inference_mode)",
        "featureColumns" => FEATURE_COLUMNS,
        "prediction" => prediction,
        "probability" => probability,
    ))
end

up(host = "127.0.0.1", port = 8000)
"""
end

function mlj_machine_service_code(model_id::AbstractString, endpoint_url::AbstractString, model_artifact::AbstractDict)
    machine_ref = String(get(model_artifact, "mljMachineArtifactRef", ""))
    machine_checksum = String(get(model_artifact, "mljMachineArtifactChecksumSha256", ""))
    feature_columns = String.(get(model_artifact, "featureColumns", String[]))
    prediction_mode = String(get(model_artifact, "mljMachinePredictionMode", "continuous_prediction"))
    positive_label = String(get(model_artifact, "mljMachinePositiveLabel", ""))
    return """using DataFrames, Genie, JSON3, MLJ, MLJLinearModels, Serialization, SHA

const MACHINE_REF = "$(machine_ref)"
const MACHINE_CHECKSUM_SHA256 = "$(machine_checksum)"
const FEATURE_COLUMNS = $(repr(feature_columns))
const PREDICTION_MODE = "$(prediction_mode)"
const POSITIVE_LABEL = "$(positive_label)"

function local_model_path(ref::AbstractString)
    if startswith(String(ref), "local://")
        data_root = get(ENV, "JULIAFLOW_DATA_ESTATE_ROOT", joinpath(homedir(), ".juliaflow", "data"))
        relative = replace(String(ref), "local://" => "")
        return joinpath(data_root, split(relative, "/")...)
    end
    return String(ref)
end

function load_machine()
    path = local_model_path(MACHINE_REF)
    isfile(path) || error("MLJ machine artifact not found")
    actual_checksum = bytes2hex(sha256(read(path)))
    actual_checksum == MACHINE_CHECKSUM_SHA256 || error("MLJ machine artifact checksum mismatch")
    return open(path, "r") do io
        Serialization.deserialize(io)
    end
end

function numeric_payload_value(payload, name::AbstractString)
    if payload isa AbstractDict && haskey(payload, name)
        return Float64(payload[name])
    elseif payload isa AbstractDict && haskey(payload, "features")
        features = payload["features"]
        if features isa AbstractDict && haskey(features, name)
            return Float64(features[name])
        end
    end
    error("missing numeric feature: " * String(name))
end

function score(payload)
    frame = DataFrame(Dict(Symbol(name) => [numeric_payload_value(payload, name)] for name in FEATURE_COLUMNS))
    raw_prediction = only(MLJ.predict(load_machine(), frame))
    if PREDICTION_MODE == "positive_class_probability"
        return round(Float64(MLJ.pdf(raw_prediction, POSITIVE_LABEL)); digits = 6)
    end
    return round(Float64(raw_prediction); digits = 6)
end

route("/v1/predict", method = POST) do
    payload = JSON3.read(rawpayload())
    prediction = score(payload)
    return JSON3.write(Dict(
        "modelId" => "$(String(model_id))",
        "endpoint" => "$(String(endpoint_url))",
        "localOnly" => true,
        "modelArtifactRef" => MACHINE_REF,
        "modelArtifactChecksumSha256" => MACHINE_CHECKSUM_SHA256,
        "inferenceMode" => "mlj_persisted_machine",
        "predictionMode" => PREDICTION_MODE,
        "featureColumns" => FEATURE_COLUMNS,
        "prediction" => prediction,
    ))
end

up(host = "127.0.0.1", port = 8000)
"""
end

function local_deploy_service_code(
    model_id::AbstractString,
    endpoint_url::AbstractString,
    model_ref::AbstractString,
    model_artifact::Union{Nothing,AbstractDict} = nothing,
)
    if model_artifact !== nothing &&
       String(get(model_artifact, "mljMachineArtifactRef", "")) != "" &&
       String(get(model_artifact, "mljMachineArtifactChecksumSha256", "")) != ""
        return mlj_machine_service_code(model_id, endpoint_url, model_artifact)
    end
    native_model_kind = model_artifact === nothing ? "" : String(get(model_artifact, "nativeModelKind", String(get(model_artifact, "modelKind", ""))))
    if model_artifact !== nothing && native_model_kind == "local_csv_binary_centroid_classifier"
        return local_csv_binary_classifier_service_code(model_id, endpoint_url, model_ref, model_artifact)
    end
    if model_artifact !== nothing && native_model_kind in ("local_csv_single_feature_ols", "local_csv_multi_feature_ols")
        return local_csv_ols_service_code(model_id, endpoint_url, model_ref, model_artifact)
    end
    return """using Genie, JSON3

const MODEL_PATH = "$(String(model_ref))"

route("/v1/predict", method = POST) do
    payload = JSON3.read(rawpayload())
    return JSON3.write(Dict(
        "modelId" => "$(String(model_id))",
        "endpoint" => "$(String(endpoint_url))",
        "localOnly" => true,
        "payload" => payload,
    ))
end

up(host = "127.0.0.1", port = 8000)
"""
end

function deploy_package_records(execution::JuliaFlowGatewayRepository.GatewayExecution)
    raw_records = get(execution.metadata, "deploy_package_records", Any[])
    return [normalized_dict(record) for record in raw_records]
end

function deploy_endpoint_config(body::AbstractDict)
    host = haskey(body, "host") ? String(body["host"]) : "127.0.0.1"
    port = haskey(body, "port") ? Int(body["port"]) : 8000
    endpoint_path = haskey(body, "endpointPath") ? String(body["endpointPath"]) : "/v1/predict"
    startswith(endpoint_path, "/") || (endpoint_path = "/" * endpoint_path)
    endpoint_url = "http://$(host):$(port)$(endpoint_path)"
    return Dict{String,Any}(
        "host" => host,
        "port" => port,
        "endpointPath" => endpoint_path,
        "endpointUrl" => endpoint_url,
    )
end

function deploy_model_artifact(model_record::AbstractDict)
    artifacts = get(model_record, "artifactEvidence", Any[])
    index = findfirst(item -> item isa AbstractDict && String(get(item, "kind", "")) == "model", artifacts)
    return index === nothing ? nothing : normalized_dict(artifacts[index])
end

function deploy_model_ref(model_record::AbstractDict)
    model_artifact = deploy_model_artifact(model_record)
    return model_artifact === nothing ? "local://models/$(String(model_record["modelId"])).json" : String(model_artifact["artifactRef"])
end

function deploy_runtime_inference_mode(model_artifact)
    model_artifact isa AbstractDict || return "echo_payload_fallback"
    if !isempty(strip(String(get(model_artifact, "mljMachineArtifactRef", "")))) &&
       !isempty(strip(String(get(model_artifact, "mljMachineArtifactChecksumSha256", ""))))
        return "mlj_persisted_machine"
    end
    model_kind = String(get(model_artifact, "modelKind", ""))
    native_model_kind = String(get(model_artifact, "nativeModelKind", model_kind))
    return native_model_kind in ("local_csv_single_feature_ols", "local_csv_multi_feature_ols", "local_csv_binary_centroid_classifier") ?
        model_kind :
        "echo_payload_fallback"
end

function deploy_artifact_evidence(
    workflow_id::AbstractString,
    model_record::AbstractDict,
    package_id::AbstractString,
    service_code::AbstractString,
    workflow_checksum::AbstractString,
    config_checksum::AbstractString,
)
    artifact_evidence = [
        Dict{String,Any}(
            "kind" => "workflow",
            "artifactRef" => "local://workflows/$(String(workflow_id)).toml",
            "checksumSha256" => String(workflow_checksum),
        ),
        Dict{String,Any}(
            "kind" => "service",
            "artifactRef" => "local://deploy/packages/$(String(package_id))/service.jl",
            "checksumSha256" => bytes2hex(sha256(Vector{UInt8}(codeunits(service_code)))),
        ),
        Dict{String,Any}(
            "kind" => "config",
            "artifactRef" => "local://deploy/packages/$(String(package_id))/juliaflow-deploy.json",
            "checksumSha256" => String(config_checksum),
        ),
    ]
    append!(artifact_evidence, [normalized_dict(item) for item in get(model_record, "artifactEvidence", Any[])])
    model_artifact = deploy_model_artifact(model_record)
    if model_artifact !== nothing && !isempty(strip(String(get(model_artifact, "mljMachineArtifactRef", ""))))
        push!(
            artifact_evidence,
            Dict{String,Any}(
                "kind" => "mlj_machine",
                "artifactRef" => String(model_artifact["mljMachineArtifactRef"]),
                "checksumSha256" => String(get(model_artifact, "mljMachineArtifactChecksumSha256", "")),
                "sizeBytes" => Int(get(model_artifact, "mljMachineArtifactSizeBytes", 0)),
                "predictionMode" => String(get(model_artifact, "mljMachinePredictionMode", "")),
            ),
        )
    end
    return artifact_evidence
end

function deploy_package_record(
    workflow_id::AbstractString,
    workflow_payload::AbstractDict,
    model_record::AbstractDict,
    validation_context::AbstractDict,
    package_id::AbstractString,
    endpoint_config::AbstractDict,
    service_code::AbstractString,
    artifact_evidence::AbstractVector,
    created_at::AbstractString,
)
    return Dict{String,Any}(
        "packageId" => String(package_id),
        "workflowId" => String(workflow_id),
        "workflowVersion" => String(workflow_payload["version"]),
        "modelId" => String(model_record["modelId"]),
        "checkpointTag" => String(model_record["checkpointTag"]),
        "endpointUrl" => String(endpoint_config["endpointUrl"]),
        "endpointPath" => String(endpoint_config["endpointPath"]),
        "host" => String(endpoint_config["host"]),
        "port" => Int(endpoint_config["port"]),
        "serviceRef" => "local://deploy/packages/$(String(package_id))/service.jl",
        "packageRef" => "local://deploy/packages/$(String(package_id)).json",
        "packageChecksumSha256" => "",
        "serviceCode" => String(service_code),
        "runCommand" => "julia --project=. local-deploy/$(String(package_id))/service.jl",
        "modelRegistryId" => get(model_record, "registryId", nothing),
        "deploymentStatus" => "local_ready",
        "artifactEvidence" => [normalized_dict(item) for item in artifact_evidence],
        "validationEvidence" => normalized_dict(validation_context),
        "createdAt" => String(created_at),
        "localOnly" => true,
    )
end

function deploy_package_checksum_payload(package_record::AbstractDict)
    checksum_payload = normalized_dict(package_record)
    delete!(checksum_payload, "packageChecksumSha256")
    delete!(checksum_payload, "executionEvidence")
    validation = get(checksum_payload, "validationEvidence", nothing)
    if validation isa AbstractDict
        validation_payload = normalized_dict(validation)
        delete!(validation_payload, "executionId")
        delete!(validation_payload, "deployPackageExecutionId")
        checksum_payload["validationEvidence"] = validation_payload
    end
    return checksum_payload
end

end
