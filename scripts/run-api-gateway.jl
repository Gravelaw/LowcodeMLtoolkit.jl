include(joinpath(@__DIR__, "..", "services", "api-gateway", "src", "JuliaFlowApiGateway.jl"))

using .JuliaFlowApiGateway

workflow_path = get(ENV, "JULIAFLOW_WORKFLOW_PATH", joinpath(@__DIR__, "..", "tests", "contracts", "fixtures", "foundation.workflow.toml"))
store_root = get(ENV, "JULIAFLOW_STORE_ROOT", joinpath(@__DIR__, "..", "tmp", "gateway-store"))
backend = Symbol(get(ENV, "JULIAFLOW_GATEWAY_BACKEND", "file"))
connection_string = get(ENV, "JULIAFLOW_DATABASE_URL", "")
schema = get(ENV, "JULIAFLOW_DATABASE_SCHEMA", "public")
host = get(ENV, "JULIAFLOW_GATEWAY_HOST", "127.0.0.1")
port = parse(Int, get(ENV, "JULIAFLOW_GATEWAY_PORT", "8088"))

state = foundation_state(
    workflow_path;
    store_root = store_root,
    backend = backend,
    connection_string = connection_string,
    schema = schema,
)
println("JuliaFlow API gateway serving on http://$(host):$(port)")
println("Backend: $(repository_backend(state))")

serve_gateway(state; host = host, port = port)
