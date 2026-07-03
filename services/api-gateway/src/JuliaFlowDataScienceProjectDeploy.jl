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

function local_deploy_service_code(
    model_id::AbstractString,
    endpoint_url::AbstractString,
    model_ref::AbstractString,
    model_artifact::Union{Nothing,AbstractDict} = nothing,
)
    if model_artifact !== nothing && String(get(model_artifact, "modelKind", "")) in ("local_csv_single_feature_ols", "local_csv_multi_feature_ols")
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
    model_kind = String(get(model_artifact, "modelKind", ""))
    return model_kind in ("local_csv_single_feature_ols", "local_csv_multi_feature_ols") ?
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
