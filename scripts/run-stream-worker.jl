include(joinpath(@__DIR__, "..", "services", "api-gateway", "src", "JuliaFlowApiGateway.jl"))

using .JuliaFlowApiGateway

store_root = get(ENV, "JULIAFLOW_STORE_ROOT", joinpath(@__DIR__, "..", "tmp", "gateway-store"))
backend = Symbol(get(ENV, "JULIAFLOW_GATEWAY_BACKEND", "file"))
connection_string = get(ENV, "JULIAFLOW_DATABASE_URL", "")
schema = get(ENV, "JULIAFLOW_DATABASE_SCHEMA", "public")
poll_ms = parse(Int, get(ENV, "JULIAFLOW_STREAM_WORKER_POLL_MS", "1000"))
run_once = get(ENV, "JULIAFLOW_WORKER_ONCE", "0") == "1"

function worker_tick!(state)
    JuliaFlowApiGateway.reload_state!(state)
    updated_executions = JuliaFlowApiGateway.JuliaFlowWorkerService.process_stream_worker_tick!(
        state.worker_service,
        state.executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = JuliaFlowApiGateway.JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    for execution in updated_executions
        JuliaFlowApiGateway.save_execution!(state.repository, execution; producer = "stream-worker")
        println("Stream worker promoted execution $(execution.execution_id) for workflow $(execution.workflow_id)")
    end
    return length(updated_executions)
end

state = load_state(
    JuliaFlowApiGateway.load_repository(
        backend = backend,
        store_root = store_root,
        connection_string = connection_string,
        schema = schema,
    ),
)
println("JuliaFlow stream worker watching backend $(JuliaFlowApiGateway.repository_backend(state))")

if run_once
    worker_tick!(state)
else
    while true
        worker_tick!(state)
        sleep(poll_ms / 1000)
    end
end
