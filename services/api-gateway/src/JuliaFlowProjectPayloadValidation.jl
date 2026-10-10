module JuliaFlowProjectPayloadValidation

using JSON3
using JSONSchema

const CONTRACT_PATH = normpath(joinpath(@__DIR__, "..", "..", "..", "packages", "contracts", "openapi", "openapi.json"))
const CONTRACT_SCHEMAS = JSON3.read(read(CONTRACT_PATH, String), Dict{String,Any})["components"]["schemas"]

function contract_schema(definition::AbstractDict)
    schemas = Dict{String,Any}()
    pending = Any[definition]
    # Compile only the relevant local reference closure; never resolve remote schemas.
    for _ in 1:100_000
        isempty(pending) && break
        node = pop!(pending)
        if node isa AbstractDict
            if haskey(node, "\$ref")
                ref = String(node["\$ref"])
                startswith(ref, "#/components/schemas/") || error("project contract schema must use local component refs")
                name = split(ref, '/')[4]
                if !haskey(schemas, name)
                    schemas[name] = CONTRACT_SCHEMAS[name]
                    push!(pending, schemas[name])
                end
            end
            append!(pending, values(node))
        elseif node isa AbstractVector
            append!(pending, node)
        end
    end
    isempty(pending) || error("project contract schema exceeds validation bounds")
    return JSONSchema.Schema(merge(Dict{String,Any}("components" => Dict("schemas" => schemas)), definition))
end

const PROJECT_CHILD_SCHEMAS = Dict(
    field => contract_schema(definition)
    for (field, definition) in CONTRACT_SCHEMAS["DataScienceProject"]["properties"]
    if get(definition, "type", nothing) == "array"
)
const RESOURCE_SCHEMA = contract_schema(Dict("\$ref" => "#/components/schemas/DataScienceProjectJobResourceEvidence"))

function contract_value(value)
    # Persisted records can mix native dictionaries with nested JSON3 views.
    # Normalize throughout, since JSONSchema's JSON3 adapter handles only a root view.
    root = Dict{String,Any}()
    pending = Any[(value, root, "value", 0)]
    for _ in 1:100_000
        isempty(pending) && return root["value"]
        item, parent, key, depth = pop!(pending)
        depth <= 64 || error("data science project invalid contract payload nesting")
        if item isa AbstractDict
            parent[key] = Dict{String,Any}()
            append!(pending, ((child, parent[key], String(child_key), depth + 1) for (child_key, child) in pairs(item)))
        elseif item isa AbstractVector
            parent[key] = Vector{Any}(undef, length(item))
            append!(pending, ((child, parent[key], index, depth + 1) for (index, child) in enumerate(item)))
        elseif item isa AbstractString
            parent[key] = String(item)
        else
            parent[key] = item
        end
    end
    isempty(pending) || error("data science project invalid contract payload size")
    return root["value"]
end

function validate_project_children!(payload::AbstractDict)
    for (field, schema) in PROJECT_CHILD_SCHEMAS
        haskey(payload, field) || continue
        payload[field] isa AbstractVector || error("project child records must be arrays")
        all(entry -> entry isa AbstractDict, payload[field]) || error("project child records must be objects")
        issue = JSONSchema.validate(schema, contract_value(payload[field]))
        issue === nothing || error("data science project $(field) invalid contract payload ($(issue.reason))")
    end
    if haskey(payload, "analysisWorkspace")
        schema = contract_schema(Dict("\$ref" => "#/components/schemas/AnalysisWorkspace"))
        JSONSchema.validate(schema, contract_value(payload["analysisWorkspace"])) === nothing || error("analysisWorkspace invalid contract payload")
    end
    if haskey(payload, "projectId")
        for job in get(payload, "projectJobs", Any[])
            job["projectId"] == payload["projectId"] || error("data science project projectJobs projectId mismatch")
        end
    end
    return payload
end

function validate_executed_resource_evidence!(evidence)
    evidence isa AbstractDict && !isempty(evidence) || error("data science project resourceEvidence required for newly executed jobs")
    JSONSchema.validate(RESOURCE_SCHEMA, contract_value(evidence)) === nothing || error("data science project resourceEvidence invalid contract payload")
    return evidence
end

function stored_project_payload(payload::AbstractDict)
    normalized = contract_value(payload)
    # Older import producers used profile-role aliases in persisted schema columns.
    # Their meanings are unchanged; never invent missing fields or resource evidence.
    schemas = get(normalized, "schemaContracts", Any[])
    if schemas isa AbstractVector
        for schema in schemas
            schema isa AbstractDict || continue
            columns = get(schema, "columns", Any[])
            columns isa AbstractVector || continue
            for column in columns
                column isa AbstractDict || continue
                role = get(column, "role", nothing)
                role == "label" && (column["role"] = "target")
                role == "timestamp" && (column["role"] = "time")
            end
        end
    end
    return validate_project_children!(normalized)
end

end
