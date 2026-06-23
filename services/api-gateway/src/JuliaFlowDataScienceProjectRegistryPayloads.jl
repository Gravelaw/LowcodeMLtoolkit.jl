module JuliaFlowDataScienceProjectRegistryPayloads

using JSON3
using SHA

export model_registry_metric,
    model_registry_tags,
    model_registry_record

function canonical_json(value)
    return JSON3.write(value)
end

function checksum_json(value)
    return bytes2hex(sha256(Vector{UInt8}(codeunits(canonical_json(value)))))
end

function model_registry_metric(model_card::AbstractDict)
    metrics = model_card["metrics"]
    preferred = ["mae", "accuracy", "auc", "r2", "loss"]
    for name in preferred
        if haskey(metrics, name)
            return name, Float64(metrics[name])
        end
    end
    for (key, value) in pairs(metrics)
        return String(key), Float64(value)
    end
    return "metric", 0.0
end

function model_registry_tags(request_body::AbstractDict, existing::AbstractDict)
    haskey(request_body, "tags") && return [String(tag) for tag in request_body["tags"]]
    haskey(existing, "tags") && return [String(tag) for tag in existing["tags"]]
    return ["local", "checkpointed"]
end

function model_registry_record(
    workflow_id::AbstractString,
    workflow_version::AbstractString,
    execution_id::AbstractString,
    checkpoint_tag::AbstractString,
    model_card::AbstractDict,
    dataset_card::AbstractDict,
    validation_context::AbstractDict,
    request_body::AbstractDict,
    existing::AbstractDict,
    timestamp::AbstractString,
)
    metric_name, metric_value = model_registry_metric(model_card)
    model_id = haskey(request_body, "modelId") ? String(request_body["modelId"]) : String(model_card["modelId"])
    registered_at = haskey(existing, "registeredAt") ? String(existing["registeredAt"]) : String(timestamp)

    return Dict{String,Any}(
        "registryId" => "model-" * model_id,
        "modelId" => model_id,
        "workflowId" => String(workflow_id),
        "workflowVersion" => String(workflow_version),
        "checkpointTag" => String(checkpoint_tag),
        "experimentId" => "ml-" * String(execution_id),
        "executionId" => String(execution_id),
        "modelKind" => String(model_card["kind"]),
        "target" => String(model_card["target"]),
        "status" => haskey(request_body, "status") ? String(request_body["status"]) : String(get(existing, "status", "registered")),
        "tags" => model_registry_tags(request_body, existing),
        "owner" => haskey(request_body, "owner") ? String(request_body["owner"]) : String(get(existing, "owner", "local-user")),
        "primaryMetricName" => metric_name,
        "primaryMetricValue" => metric_value,
        "datasetId" => String(dataset_card["datasetId"]),
        "datasetChecksumSha256" => String(dataset_card["checksumSha256"]),
        "artifactEvidence" => [
            Dict{String,Any}(
                "kind" => "model",
                "artifactRef" => "local://models/$(model_id).json",
                "checksumSha256" => checksum_json(model_card),
            ),
            Dict{String,Any}(
                "kind" => "dataset",
                "artifactRef" => "local://data/curated/$(String(dataset_card["datasetId"])).arrow",
                "checksumSha256" => String(dataset_card["checksumSha256"]),
            ),
            Dict{String,Any}(
                "kind" => "config",
                "artifactRef" => "local://models/$(model_id)-config.json",
                "checksumSha256" => checksum_json(model_card["config"]),
            ),
        ],
        "validationEvidence" => validation_context,
        "registeredAt" => registered_at,
        "updatedAt" => String(timestamp),
        "deploymentStatus" => String(get(existing, "deploymentStatus", "not_deployed")),
        "localOnly" => true,
    )
end

end
