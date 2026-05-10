include(joinpath(@__DIR__, "..", "services", "node-sdk", "src", "JuliaFlowNodeSDK.jl"))
include(joinpath(@__DIR__, "..", "services", "execution-service", "src", "JuliaFlowExecutionService.jl"))
include(joinpath(@__DIR__, "..", "services", "worker-service", "src", "JuliaFlowWorkerService.jl"))
include(joinpath(@__DIR__, "..", "services", "api-gateway", "src", "JuliaFlowApiGateway.jl"))

using JSON3
using .JuliaFlowExecutionService
using .JuliaFlowWorkerService
using .JuliaFlowApiGateway

function main()
    events_path = get(ENV, "JULIAFLOW_KAFKA_EVENTS_JSONL", "")
    isempty(events_path) && error("JULIAFLOW_KAFKA_EVENTS_JSONL is required")
    sink_state_path = get(ENV, "JULIAFLOW_STREAM_SINK_STATE_PATH", joinpath(mktempdir(), "sink-state.json"))
    sink_output_path = get(ENV, "JULIAFLOW_STREAM_SINK_OUTPUT_PATH", joinpath(dirname(sink_state_path), "sink-output.jsonl"))
    workflow = load_workflow_definition(joinpath(@__DIR__, "..", "tests", "contracts", "fixtures", "parallel.workflow.toml"))
    service = WorkerServiceState()
    executions = GatewayExecution[
        JuliaFlowApiGateway.materialize_execution(execute_workflow(workflow; checkpoint_tag = "cp/live-kafka-smoke")),
    ]
    workflows = Dict(workflow.id => workflow)
    queue_stream_execution!(
        service,
        workflows,
        executions,
        executions[1].execution_id;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    process_stream_worker_tick!(
        service,
        executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    first = process_stream_fixture_batch!(
        service,
        workflows,
        executions,
        workflow.id;
        execution_record = JuliaFlowApiGateway.execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
        batch_size = 2,
    )
    duplicate = replay_stream_fixture_batch!(
        service,
        workflows,
        executions,
        workflow.id,
        0;
        execution_record = JuliaFlowApiGateway.execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
        batch_size = 2,
    )
    restarted = WorkerServiceState()
    sync_worker_service!(restarted, executions)
    second = replay_stream_fixture_batch!(
        restarted,
        workflows,
        executions,
        workflow.id,
        first.metadata["stream_committed_offset"];
        execution_record = JuliaFlowApiGateway.execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
        batch_size = 1,
    )
    output_rows = isfile(sink_output_path) ? length(readlines(sink_output_path)) : 0
    output_rows == 3 || error("expected 3 sink rows, got $(output_rows)")
    duplicate.metadata["stream_exactly_once_status"] == "duplicate_suppressed" || error("duplicate replay was not suppressed")
    println(JSON3.write(Dict(
        "status" => "passed",
        "adapter" => second.metadata["stream_adapter"],
        "committedOffset" => second.metadata["stream_committed_offset"],
        "replayStatus" => second.metadata["stream_replay_status"],
        "sinkRows" => output_rows,
        "sinkStatePath" => sink_state_path,
        "sinkOutputPath" => sink_output_path,
        "eventsPath" => events_path,
    )))
end

main()
