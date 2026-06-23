module JuliaFlowDataScienceProjectDeploy

using ..JuliaFlowGatewayRepository
using SHA

export local_deploy_service_code,
    deploy_package_records,
    deploy_endpoint_config,
    deploy_model_ref,
    deploy_artifact_evidence,
    deploy_package_record,
    deploy_package_checksum_payload

function normalized_dict(value)
    return Dict{String,Any}(String(key) => item for (key, item) in pairs(value))
end

function local_deploy_service_code(model_id::AbstractString, endpoint_url::AbstractString, model_ref::AbstractString)
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

function deploy_model_ref(model_record::AbstractDict)
    artifacts = get(model_record, "artifactEvidence", Any[])
    model_artifact = findfirst(item -> String(item["kind"]) == "model", artifacts)
    return model_artifact === nothing ? "local://models/$(String(model_record["modelId"])).json" : String(artifacts[model_artifact]["artifactRef"])
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
    return checksum_payload
end

end
