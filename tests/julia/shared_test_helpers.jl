function test_base64url(bytes::Vector{UInt8})
    encoded = base64encode(bytes)
    encoded = replace(replace(encoded, '+' => '-'), '/' => '_')
    return replace(encoded, "=" => "")
end

function test_base64url_json(payload)
    return test_base64url(Vector{UInt8}(codeunits(JSON3.write(payload))))
end

function test_hs256_jwt(claims::Dict{String,Any}; secret::AbstractString = "oidc-secret", kid::Union{Nothing,AbstractString} = nothing)
    header = Dict{String,Any}("alg" => "HS256", "typ" => "JWT")
    kid === nothing || (header["kid"] = String(kid))
    signing_input = string(test_base64url_json(header), ".", test_base64url_json(claims))
    signature = test_base64url(hmac_sha256(Vector{UInt8}(codeunits(secret)), signing_input))
    return string(signing_input, ".", signature)
end

function test_oct_jwk(kid::AbstractString, secret::AbstractString)
    return Dict("kty" => "oct", "kid" => String(kid), "alg" => "HS256", "k" => test_base64url(Vector{UInt8}(codeunits(secret))))
end

function runtime_branch_workflow_text()
    return """
    version = "0.1.0"

    [workflow]
    id = "wf-catch-branch-dag"
    name = "Catch Branch DAG"

    [[workflow.bi_outlets]]
    node_id = "catch-bi"
    name = "Catch BI Outlet"
    rows = [
      { status = "recovered", count = 2 },
      { status = "audited", count = 1 }
    ]

    [[workflow.control_flow]]
    id = "try-catch-dag"
    kind = "try_catch"
    name = "Catch DAG Guard"
    try_node_ids = ["node-transform"]
    catch_node_ids = ["catch-log", "catch-clean", "catch-bi"]

    [runtime]
    run_mode = "batch"

    [[nodes]]
    id = "node-source"
    name = "Source"
    type = "JuliaFlow.Base.CSVReader"
    execution_hint = "cpu_only"
    ports = [{ id = "out", direction = "output", type = "data_table" }]
    config = { path = "assets/sample.csv" }

    [[nodes]]
    id = "node-transform"
    name = "Transform"
    type = "JuliaFlow.Base.ColumnSelect"
    execution_hint = "cpu_only"
    ports = [
      { id = "in", direction = "input", type = "data_table" },
      { id = "out", direction = "output", type = "data_table" }
    ]
    config = { columns = ["amount"] }

    [[nodes]]
    id = "catch-log"
    name = "Catch Log"
    type = "JuliaFlow.Base.AuditLog"
    execution_hint = "cpu_only"
    ports = []
    config = { event = "recover" }

    [[nodes]]
    id = "catch-clean"
    name = "Catch Clean"
    type = "JuliaFlow.Base.CleanRows"
    execution_hint = "cpu_only"
    ports = [{ id = "out", direction = "output", type = "data_table" }]
    config = { strategy = "safe" }

    [[nodes]]
    id = "catch-bi"
    name = "Catch BI"
    type = "JuliaFlow.BI.DataOutlet"
    execution_hint = "cpu_only"
    ports = [{ id = "in", direction = "input", type = "data_table" }]
    config = { outlet = "catch-bi" }

    [[connections]]
    source_node_id = "node-source"
    source_port_id = "out"
    target_node_id = "node-transform"
    target_port_id = "in"
    data_type = "data_table"

    [[connections]]
    source_node_id = "catch-clean"
    source_port_id = "out"
    target_node_id = "catch-bi"
    target_port_id = "in"
    data_type = "data_table"
    """
end
