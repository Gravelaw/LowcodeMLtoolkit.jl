const startup_started_ns = time_ns()
function startup_stage(stage::AbstractString)
    elapsed_ms = round(Int, (time_ns() - startup_started_ns) / 1_000_000)
    println(stderr, "[gateway:startup] $(stage) elapsedMs=$(elapsed_ms)")
    flush(stderr)
end

startup_stage("module-loading")
using JuliaFlowMonorepo
using JuliaFlowMonorepo.JuliaFlowApiGateway
startup_stage("module-loaded")

workflow_path = get(ENV, "JULIAFLOW_WORKFLOW_PATH", joinpath(@__DIR__, "..", "tests", "contracts", "fixtures", "foundation.workflow.toml"))
store_root = get(ENV, "JULIAFLOW_STORE_ROOT", joinpath(@__DIR__, "..", "tmp", "gateway-store"))
backend = Symbol(get(ENV, "JULIAFLOW_GATEWAY_BACKEND", "file"))
connection_string = get(ENV, "JULIAFLOW_DATABASE_URL", "")
schema = get(ENV, "JULIAFLOW_DATABASE_SCHEMA", "public")
host = get(ENV, "JULIAFLOW_GATEWAY_HOST", "127.0.0.1")
port = parse(Int, get(ENV, "JULIAFLOW_GATEWAY_PORT", "8088"))

startup_stage("state-initializing")
state = foundation_state(
    workflow_path;
    store_root = store_root,
    backend = backend,
    connection_string = connection_string,
    schema = schema,
)
startup_stage("state-ready")
println("JuliaFlow API gateway starting on http://$(host):$(port)")
println("Backend: $(repository_backend(state))")

startup_stage("listener-starting")
serve_gateway(state; host = host, port = port)
