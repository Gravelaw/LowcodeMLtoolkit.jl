using Test
using Base64
using HTTP
using JSON3
using SHA
using TOML

include(joinpath(@__DIR__, "..", "..", "services", "node-sdk", "src", "JuliaFlowNodeSDK.jl"))
include(joinpath(@__DIR__, "..", "..", "services", "execution-service", "src", "JuliaFlowExecutionService.jl"))
include(joinpath(@__DIR__, "..", "..", "services", "worker-service", "src", "JuliaFlowWorkerService.jl"))
include(joinpath(@__DIR__, "..", "..", "services", "api-gateway", "src", "JuliaFlowApiGateway.jl"))
include(joinpath(@__DIR__, "..", "..", "extensions", "base", "src", "JuliaFlowBaseExtension.jl"))

using .JuliaFlowNodeSDK
using .JuliaFlowExecutionService
using .JuliaFlowWorkerService
using .JuliaFlowApiGateway
using .JuliaFlowBaseExtension

include(joinpath(@__DIR__, "repository_contract_tests.jl"))

mutable struct FakeRealtimeSocket
    messages::Vector{String}
end

HTTP.WebSockets.send(socket::FakeRealtimeSocket, message) = push!(socket.messages, String(message))

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

@testset "Node SDK" begin
    payload = (format = :arrow_ipc, ref = "minio://wf/output.arrow")
    @test validate_arrow_boundary(payload)
    @test validate_port_type(:data_table)
    @test validate_port_direction(:output)
    @test normalize_config(Dict("a" => 1)).values["a"] == 1
end

@testset "Execution Service" begin
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    parallel_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "parallel.workflow.toml")
    invalid_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "invalid.workflow.toml")

    workflow_text = read(foundation_path, String)
    gpu_workflow_text = """
    version = "0.3.0"

    [workflow]
    id = "wf-gpu-alpha"
    name = "GPU Alpha"

    [runtime]
    run_mode = "batch"

    [[nodes]]
    id = "node-source"
    type = "JuliaFlow.Base.CSVReader"
    name = "CSV Reader"
    execution_hint = "cpu_only"
    ports = [{ id = "out", direction = "output", type = "data_table" }]
    config = { path = "assets/sample.csv" }

    [[nodes]]
    id = "node-train"
    type = "JuliaFlow.Base.ModelTrain"
    name = "GPU Trainer"
    execution_hint = "gpu_required"
    ports = [
        { id = "in", direction = "input", type = "data_table" },
        { id = "model", direction = "output", type = "model" },
    ]
    config = { target = "amount", gpuDevicePreference = "nvidia0", gpuWorkload = "mock_vector_sum", mockInputValues = [1.0, 2.0, 3.0, 4.0] }
    capabilities = { execution_mode = "batch", resource_class = "gpu", accelerator = "cuda", worker_pool = "alpha-gpu" }

    [[connections]]
    source_node_id = "node-source"
    source_port_id = "out"
    target_node_id = "node-train"
    target_port_id = "in"
    data_type = "data_table"
    """
    workflow = load_workflow_definition(foundation_path)
    parallel_workflow = load_workflow_definition(parallel_path)
    gpu_workflow = load_workflow_definition_text(gpu_workflow_text)
    invalid_workflow = load_workflow_definition(invalid_path)
    workflow_from_text = load_workflow_definition_text(workflow_text)
    plan = build_execution_plan(workflow)
    stages = build_parallel_stages(parallel_workflow)
    errors = collect_validation_errors(invalid_workflow)

    @test validate_workflow(workflow)
    @test workflow_from_text.id == workflow.id
    @test plan == ["node-source", "node-transform", "node-bi"]
    @test stages == [["node-source"], ["node-left", "node-right"], ["node-sink"]]
    @test any(occursin("target port in on node-target must be input", error) for error in errors)

    result = execute_workflow(workflow)
    execute_with_flow_variables = execute_workflow(
        workflow;
        flow_variable_values = Dict("JULIAFLOW_GPU_DEVICE" => "nvidia:0"),
        execution_mode_override = "gpu_preferred",
    )
    spec = serialize_job_spec(parallel_workflow; checkpoint_tag = "cp/01-contracts-frozen")
    @test result["status"] == "accepted"
    @test result["mode"] == "batch_cpu"
    @test execute_with_flow_variables["flow_variables"]["JULIAFLOW_GPU_DEVICE"] == "nvidia:0"
    @test execute_with_flow_variables["requested_execution_mode"] == "gpu_preferred"
    @test execute_with_flow_variables["status_history"][1]["at"] isa AbstractString
    @test workflow.graph.revision == 2
    @test length(workflow.dashboards) == 1
    @test parallel_workflow.runtime.run_mode == :stream
    @test spec["resource_plan"][1]["lane"] == "cpu"
    @test spec["dispatch_plan"][1]["worker_pool"] == "alpha-cpu"
    @test spec["stream_lifecycle_status"] == "starting"
    appended = append_execution_event(spec; message = "heartbeat", metadata = Dict("stream_lifecycle_status" => "active"))
    @test appended["stream_lifecycle_status"] == "active"
    @test appended["status_history"][end]["message"] == "heartbeat"
    @test is_stream_workflow(parallel_workflow)
    @test spec["stages"][2] == ["node-left", "node-right"]
    @test spec["checkpoint_tag"] == "cp/01-contracts-frozen"
    gpu_spec = serialize_job_spec(gpu_workflow; checkpoint_tag = "cp/03-alpha-gpu-bi")
    @test gpu_spec["mode"] == "batch_gpu_required"
    @test gpu_spec["resource_plan"][2]["lane"] == "gpu"
    @test gpu_spec["dispatch_plan"][2]["worker_pool"] == "alpha-gpu"
    @test gpu_spec["dispatch_plan"][2]["isolation_mode"] == "isolated"
    @test gpu_spec["dispatch_plan"][2]["accelerator"] == "cuda"
    @test_throws ErrorException validate_workflow(invalid_workflow)
    @test_throws ErrorException execute_workflow(workflow; flow_variable_values = Dict("MISSING_VAR" => "oops"))
end

@testset "Gateway Repository" begin
    mktempdir() do store_root
        file_repo = JuliaFlowApiGateway.JuliaFlowGatewayRepository.ensure_repository!(
            JuliaFlowApiGateway.JuliaFlowGatewayRepository.FileGatewayRepository(store_root),
        )
        run_gateway_repository_contract!(file_repo; label = "File")
    end

    @testset "PostgreSQL integration scaffold" begin
        with_postgres_repository() do postgres_repo
            run_gateway_repository_contract!(postgres_repo; label = "PostgreSQL")
        end
    end
end

@testset "Worker Service" begin
    parallel_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "parallel.workflow.toml")
    kafka_workflow = load_workflow_definition(parallel_path)
    kafka_metadata = JuliaFlowWorkerService.build_stream_execution_metadata(kafka_workflow)
    @test kafka_metadata["stream_adapter_contract"]["kind"] == "kafka"
    @test kafka_metadata["stream_adapter_contract"]["topic"] == "parallel.events"
    @test kafka_metadata["stream_adapter_contract"]["consumerGroup"] == "juliaflow-dev"
    @test kafka_metadata["stream_adapter_contract"]["replayMode"] == "committed_offset"
    nats_workflow = load_workflow_definition(parallel_path)
    empty!(nats_workflow.runtime.source)
    nats_workflow.runtime.source["kind"] = "nats"
    nats_workflow.runtime.source["subject"] = "parallel.events"
    nats_workflow.runtime.source["durable_consumer"] = "juliaflow-dev"
    nats_workflow.runtime.source["servers"] = ["nats://localhost:4222"]
    nats_metadata = JuliaFlowWorkerService.build_stream_execution_metadata(nats_workflow)
    @test nats_metadata["stream_adapter_contract"]["kind"] == "nats"
    @test nats_metadata["stream_adapter_contract"]["subject"] == "parallel.events"
    @test nats_metadata["stream_adapter_contract"]["durableConsumer"] == "juliaflow-dev"
    parallel_workflow = load_workflow_definition(parallel_path)
    parallel_workflow.runtime.source["kind"] = "fixture"
    parallel_workflow.runtime.source["events"] = [
        Dict("offset" => 1, "event_time_seconds" => 0, "region" => "north", "amount" => 10.0),
        Dict("offset" => 2, "event_time_seconds" => 12, "region" => "south", "amount" => 20.0),
        Dict("offset" => 3, "event_time_seconds" => 41, "region" => "north", "amount" => 30.0),
    ]
    gpu_workflow_text = """
    version = "0.3.0"

    [workflow]
    id = "wf-gpu-alpha"
    name = "GPU Alpha"

    [runtime]
    run_mode = "batch"

    [[nodes]]
    id = "node-source"
    type = "JuliaFlow.Base.CSVReader"
    name = "CSV Reader"
    execution_hint = "cpu_only"
    ports = [{ id = "out", direction = "output", type = "data_table" }]
    config = { path = "assets/sample.csv" }

    [[nodes]]
    id = "node-train"
    type = "JuliaFlow.Base.ModelTrain"
    name = "GPU Trainer"
    execution_hint = "gpu_required"
    ports = [
        { id = "in", direction = "input", type = "data_table" },
        { id = "model", direction = "output", type = "model" },
    ]
    config = { target = "amount", gpuDevicePreference = "nvidia0", gpuWorkload = "mock_vector_sum", mockInputValues = [1.0, 2.0, 3.0, 4.0] }
    capabilities = { execution_mode = "batch", resource_class = "gpu", accelerator = "cuda", worker_pool = "alpha-gpu" }

    [[connections]]
    source_node_id = "node-source"
    source_port_id = "out"
    target_node_id = "node-train"
    target_port_id = "in"
    data_type = "data_table"
    """
    gpu_workflow = load_workflow_definition_text(gpu_workflow_text)
    workflows = Dict(
        parallel_workflow.id => parallel_workflow,
        gpu_workflow.id => gpu_workflow,
    )
    service = WorkerServiceState()
    executions = GatewayExecution[]

    push!(
        executions,
        JuliaFlowApiGateway.materialize_execution(
            execute_workflow(parallel_workflow; checkpoint_tag = "cp/02-alpha-core"),
        ),
    )
    queued_stream = queue_stream_execution!(
        service,
        workflows,
        executions,
        executions[1].execution_id;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test queued_stream.status == "queued"
    @test queued_stream.metadata["stream_lifecycle_status"] == "starting"

    processed_streams = process_stream_worker_tick!(
        service,
        executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test length(processed_streams) == 1
    activated_stream = processed_streams[1]
    @test activated_stream.status == "running"
    @test activated_stream.metadata["stream_lifecycle_status"] == "active"
    @test activated_stream.metadata["stream_topic"] == "parallel.events"
    @test activated_stream.metadata["stream_adapter"] == "fixture"
    @test activated_stream.metadata["stream_consumer_lag"] == 3
    @test service.stream_execution_ids[parallel_workflow.id] == activated_stream.execution_id

    first_batch = process_stream_fixture_batch!(
        service,
        workflows,
        executions,
        parallel_workflow.id;
        execution_record = JuliaFlowApiGateway.execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
        batch_size = 2,
    )
    @test first_batch.metadata["stream_processed_offset"] == 2
    @test first_batch.metadata["stream_processed_rows"] == 2
    @test first_batch.metadata["stream_consumer_lag"] == 1
    @test first_batch.metadata["stream_backpressure"] == "ok"
    @test first_batch.metadata["stream_watermark"] == 7
    @test first_batch.metadata["stream_window_state"]["windows"][1]["count"] == 2
    @test first_batch.metadata["stream_checkpoint_offsets"]["lastOffset"] == 2
    @test first_batch.metadata["stream_checkpoint_offsets"]["committedOffset"] == 2
    @test first_batch.metadata["stream_exactly_once_status"] == "committed"
    @test first_batch.metadata["stream_sink_transaction_id"] == "stream-$(first_batch.execution_id)-offset-0-2"

    replayed_first_batch = replay_stream_fixture_batch!(
        service,
        workflows,
        executions,
        parallel_workflow.id,
        0;
        execution_record = JuliaFlowApiGateway.execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
        batch_size = 2,
    )
    @test replayed_first_batch.metadata["stream_processed_offset"] == 2
    @test replayed_first_batch.metadata["stream_processed_rows"] == 2
    @test replayed_first_batch.metadata["stream_exactly_once_status"] == "duplicate_suppressed"
    @test replayed_first_batch.metadata["stream_replay_status"] == "duplicate_skipped"
    @test replayed_first_batch.metadata["stream_replay_offset"] == 0

    second_batch = process_stream_fixture_batch!(
        service,
        workflows,
        executions,
        parallel_workflow.id;
        execution_record = JuliaFlowApiGateway.execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test second_batch.metadata["stream_processed_offset"] == 3
    @test second_batch.metadata["stream_consumer_lag"] == 0
    @test second_batch.metadata["stream_window_state"]["windows"][1]["start"] == 30
    second_batch_payload = JuliaFlowApiGateway.execution_payload(second_batch)
    @test second_batch_payload["streamProcessedOffset"] == 3
    @test second_batch_payload["streamConsumerLag"] == 0
    @test second_batch_payload["streamBackpressure"] == "ok"
    @test second_batch_payload["streamWindowState"]["windows"][1]["start"] == 30

    paused_stream = set_stream_lifecycle!(
        service,
        executions,
        parallel_workflow.id;
        lifecycle_status = "paused",
        message = "Streaming execution paused",
        execution_record = JuliaFlowApiGateway.execution_record,
        append_execution_event = append_execution_event,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test paused_stream.metadata["stream_lifecycle_status"] == "paused"

    stopped_stream = stop_stream_execution!(
        service,
        executions,
        parallel_workflow.id;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test stopped_stream.status == "completed"
    @test stopped_stream.metadata["stream_lifecycle_status"] == "stopped"
    @test !haskey(service.stream_execution_ids, parallel_workflow.id)

    push!(
        executions,
        JuliaFlowApiGateway.materialize_execution(
            execute_workflow(gpu_workflow; checkpoint_tag = "cp/03-alpha-gpu-bi"),
        ),
    )
    activated_gpu = activate_gpu_execution!(
        service,
        executions,
        executions[end].execution_id;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test activated_gpu.status == "queued"
    @test activated_gpu.metadata["dispatch_lane"] == "gpu"
    @test activated_gpu.metadata["dispatch_worker_pool"] == "alpha-gpu"
    @test activated_gpu.metadata["dispatch_isolation_mode"] == "isolated"
    @test activated_gpu.metadata["dispatch_accelerator"] == "cuda"
    @test startswith(activated_gpu.metadata["worker_id"], "gpu-worker-")
    @test activated_gpu.execution_id in service.gpu_execution_ids

    promoted_gpu = promote_gpu_execution!(
        service,
        executions,
        activated_gpu.execution_id;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test promoted_gpu.status == "running"
    @test promoted_gpu.execution_id in service.gpu_execution_ids

    completed_gpu = process_gpu_compute_tick!(
        service,
        workflows,
        executions;
        execution_record = JuliaFlowApiGateway.execution_record,
        transition_execution_record = transition_execution_record,
        materialize_execution = JuliaFlowApiGateway.materialize_execution,
    )
    @test length(completed_gpu) == 1
    @test completed_gpu[1].status == "completed"
    @test completed_gpu[1].metadata["gpu_execution_path"] == "gpu"
    @test completed_gpu[1].metadata["gpu_device_id"] == "nvidia0"
    @test completed_gpu[1].metadata["gpu_workload_result"]["sum"] == 10.0

    withenv("JULIAFLOW_GPU_REGISTRY" => "") do
        fallback_executions = GatewayExecution[]
        push!(fallback_executions, JuliaFlowApiGateway.materialize_execution(execute_workflow(gpu_workflow; checkpoint_tag = "cp/03-alpha-gpu-bi")))
        fallback_service = WorkerServiceState()
        fallback_queued = activate_gpu_execution!(
            fallback_service,
            fallback_executions,
            fallback_executions[1].execution_id;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        fallback_running = promote_gpu_execution!(
            fallback_service,
            fallback_executions,
            fallback_queued.execution_id;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        fallback_completed = process_gpu_compute_tick!(
            fallback_service,
            workflows,
            fallback_executions;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        @test fallback_running.status == "running"
        @test length(fallback_completed) == 1
        @test fallback_completed[1].metadata["gpu_execution_path"] == "cpu_fallback"
        @test fallback_completed[1].metadata["gpu_fallback_used"] == true
    end
end

@testset "API Gateway" begin
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    parallel_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "parallel.workflow.toml")

    mktempdir() do store_root
        state = foundation_state(foundation_path; store_root = store_root)
        reloaded = load_state(store_root)
        updated_toml = replace(read(foundation_path, String), "Foundation PoC" => "Foundation PoC Updated")
        foundation_workflow_payload = Dict{String,Any}(
            "workflow" => Dict(
                "version" => "0.1.0",
                "workflowId" => "wf-foundation",
                "name" => "Foundation JSON Save",
                "flowVariables" => [
                    Dict("name" => "JULIAFLOW_GPU_DEVICE", "type" => "GPUDeviceID", "default" => "nvidia:0"),
                    Dict("name" => "BATCH_WINDOW", "type" => "String", "default" => "2026-Q2"),
                ],
                "graph" => Dict(
                    "revision" => 3,
                    "selectedNodeId" => "node-transform",
                    "viewport" => Dict("x" => 0.0, "y" => 0.0, "zoom" => 1.0),
                    "nodeLayouts" => [
                        Dict("nodeId" => "node-source", "x" => 44.0, "y" => 72.0, "width" => 180.0),
                        Dict("nodeId" => "node-transform", "x" => 280.0, "y" => 148.0, "width" => 188.0),
                        Dict("nodeId" => "node-bi", "x" => 560.0, "y" => 148.0, "width" => 176.0),
                    ],
                ),
                "dashboards" => [
                    Dict(
                        "dashboardId" => "dashboard-foundation",
                        "name" => "Foundation Overview",
                        "binding" => Dict(
                            "outletNodeId" => "node-bi",
                            "datasetKey" => "sales_overview",
                            "refreshMode" => "live",
                        ),
                        "charts" => [
                            Dict("chartId" => "chart-line", "title" => "Trend", "family" => "line", "xField" => "window", "yField" => "amount"),
                            Dict("chartId" => "chart-bar", "title" => "By Region", "family" => "bar", "xField" => "region", "yField" => "amount"),
                            Dict("chartId" => "chart-area", "title" => "Capacity", "family" => "area", "xField" => "window", "yField" => "capacity"),
                            Dict("chartId" => "chart-table", "title" => "Rows", "family" => "table"),
                            Dict("chartId" => "chart-metric", "title" => "Latest", "family" => "metric", "yField" => "amount"),
                        ],
                    ),
                ],
                "runtime" => Dict(
                    "runMode" => "batch",
                ),
                "nodes" => [
                    Dict(
                        "id" => "node-source",
                        "type" => "JuliaFlow.Base.CSVReader",
                        "name" => "CSV Reader",
                        "executionHint" => "cpu_only",
                        "capabilities" => Dict("executionMode" => "batch", "resourceClass" => "cpu"),
                        "ports" => [Dict("id" => "out", "direction" => "output", "type" => "data_table")],
                        "config" => Dict("path" => "assets/sample.csv"),
                    ),
                    Dict(
                        "id" => "node-transform",
                        "type" => "JuliaFlow.Base.ColumnSelect",
                        "name" => "Column Select",
                        "executionHint" => "cpu_only",
                        "capabilities" => Dict("executionMode" => "batch", "resourceClass" => "cpu"),
                        "ports" => [
                            Dict("id" => "in", "direction" => "input", "type" => "data_table"),
                            Dict("id" => "out", "direction" => "output", "type" => "data_table"),
                        ],
                        "config" => Dict("columns" => ["amount", "region"]),
                    ),
                    Dict(
                        "id" => "node-bi",
                        "type" => "JuliaFlow.BI.DataOutlet",
                        "name" => "BI Outlet",
                        "executionHint" => "cpu_only",
                        "capabilities" => Dict("executionMode" => "hybrid", "resourceClass" => "cpu"),
                        "ports" => [Dict("id" => "in", "direction" => "input", "type" => "data_table")],
                        "config" => Dict("outlet" => "sales-overview"),
                    ),
                ],
                "connections" => [
                    Dict(
                        "sourceNodeId" => "node-source",
                        "sourcePortId" => "out",
                        "targetNodeId" => "node-transform",
                        "targetPortId" => "in",
                        "dataType" => "data_table",
                    ),
                    Dict(
                        "sourceNodeId" => "node-transform",
                        "sourcePortId" => "out",
                        "targetNodeId" => "node-bi",
                        "targetPortId" => "in",
                        "dataType" => "data_table",
                    ),
                ],
            ),
        )
        gpu_workflow_payload = Dict{String,Any}(
            "workflow" => Dict(
                "version" => "0.3.0",
                "workflowId" => "wf-gpu-alpha",
                "name" => "GPU Alpha",
                "flowVariables" => [
                    Dict("name" => "JULIAFLOW_GPU_DEVICE", "type" => "GPUDeviceID", "default" => "nvidia:0"),
                ],
                "runtime" => Dict("runMode" => "batch"),
                "nodes" => [
                    Dict(
                        "id" => "node-source",
                        "type" => "JuliaFlow.Base.CSVReader",
                        "name" => "CSV Reader",
                        "executionHint" => "cpu_only",
                        "capabilities" => Dict("executionMode" => "batch", "resourceClass" => "cpu", "workerPool" => "alpha-cpu"),
                        "ports" => [Dict("id" => "out", "direction" => "output", "type" => "data_table")],
                        "config" => Dict("path" => "assets/sample.csv"),
                    ),
                    Dict(
                        "id" => "node-train",
                        "type" => "JuliaFlow.Base.ModelTrain",
                        "name" => "GPU Trainer",
                        "executionHint" => "gpu_required",
                        "capabilities" => Dict(
                            "executionMode" => "batch",
                            "resourceClass" => "gpu",
                            "accelerator" => "cuda",
                            "workerPool" => "alpha-gpu",
                        ),
                        "ports" => [
                            Dict("id" => "in", "direction" => "input", "type" => "data_table"),
                            Dict("id" => "model", "direction" => "output", "type" => "model"),
                        ],
                        "config" => Dict("target" => "amount", "gpuDevicePreference" => "nvidia:0"),
                    ),
                ],
                "connections" => [
                    Dict(
                        "sourceNodeId" => "node-source",
                        "sourcePortId" => "out",
                        "targetNodeId" => "node-train",
                        "targetPortId" => "in",
                        "dataType" => "data_table",
                    ),
                ],
            ),
        )

        @test occursin("\"status\":\"ok\"", healthcheck(state))
        @test occursin("wf-foundation", list_workflows_response(state))
        @test occursin("\"nodeCount\":3", get_workflow_response(state, "wf-foundation"))
        @test occursin("\"nodes\":[", get_workflow_response(state, "wf-foundation"))
        @test occursin("\"connections\":[", get_workflow_response(state, "wf-foundation"))
        @test occursin("\"graphRevision\":2", get_workflow_response(state, "wf-foundation"))
        @test occursin("\"extensionId\":\"juliaflow-base\"", JuliaFlowApiGateway.list_hub_extensions_response(state))
        execution_json = execution_accept_response(state, "wf-foundation")
        accepted_execution = JSON3.read(execution_json, Dict{String,Any})
        @test occursin("\"accepted\"", execution_json)
        @test occursin("\"executionId\":", execution_json)
        @test occursin("\"mode\":\"batch_cpu\"", execution_json)
        @test occursin("\"statusHistory\":[", execution_json)
        @test occursin("\"resourcePlan\":[", execution_json)
        @test accepted_execution["statusHistory"][1]["at"] isa AbstractString
        queued_execution_json = transition_execution_response!(
            state,
            accepted_execution["executionId"];
            status = "queued",
            message = "Queued for CPU scheduler",
            metadata = Dict{String,Any}("queueName" => "foundation-cpu"),
        )
        @test occursin("\"status\":\"queued\"", queued_execution_json)
        @test occursin("\"queueName\":\"foundation-cpu\"", queued_execution_json)
        @test occursin("cp/01-contracts-frozen", create_checkpoint_response!(state; tag = "cp/01-contracts-frozen", summary = "Contracts frozen"))
        @test occursin("cp/01-contracts-frozen", checkpoint_list_response(state))
        @test haskey(reloaded.workflows, "wf-foundation")
        @test isfile(joinpath(store_root, "checkpoints.json"))
        @test isfile(joinpath(store_root, "executions.json"))
        @test occursin("wf-parallel", import_workflow_response!(state; source_path = parallel_path))
        @test occursin("\"status\":\"created\"", create_workflow_response!(state; workflow_toml = read(parallel_path, String)))
        stream_execution_json = execution_accept_response(state, "wf-parallel")
        stream_execution = JSON3.read(stream_execution_json, Dict{String,Any})
        @test stream_execution["mode"] == "stream_cpu"
        @test stream_execution["streamLifecycleStatus"] == "active"
        @test stream_execution["stream_topic"] == "parallel.events"
        withenv("JULIAFLOW_STREAM_WORKER_MODE" => "process") do
            queued_stream_json = execution_accept_response(state, "wf-parallel")
            queued_stream = JSON3.read(queued_stream_json, Dict{String,Any})
            @test queued_stream["status"] == "queued"
            @test queued_stream["streamLifecycleStatus"] == "starting"
            processed_streams = JuliaFlowApiGateway.JuliaFlowWorkerService.process_stream_worker_tick!(
                state.worker_service,
                state.executions;
                execution_record = JuliaFlowApiGateway.execution_record,
                transition_execution_record = transition_execution_record,
                materialize_execution = JuliaFlowApiGateway.materialize_execution,
            )
            @test length(processed_streams) >= 1
            processed_stream = processed_streams[end]
            JuliaFlowApiGateway.save_execution!(state.repository, processed_stream)
            @test processed_stream.status == "running"
            @test processed_stream.metadata["stream_lifecycle_status"] == "active"
        end
        json_update = JuliaFlowApiGateway.update_workflow_response_from_body!(state, "wf-foundation", foundation_workflow_payload)
        json_gpu_create = JuliaFlowApiGateway.create_workflow_response_from_body!(state, gpu_workflow_payload)
        gpu_execution_json = execution_accept_response(state, "wf-gpu-alpha")
        gpu_execution = JSON3.read(gpu_execution_json, Dict{String,Any})
        @test occursin("\"status\":\"updated\"", json_update)
        @test occursin("\"status\":\"created\"", json_gpu_create)
        @test gpu_execution["status"] == "queued"
        @test gpu_execution["dispatchLane"] == "gpu"
        @test gpu_execution["dispatchWorkerPool"] == "alpha-gpu"
        @test gpu_execution["dispatchIsolationMode"] == "isolated"
        @test gpu_execution["dispatchAccelerator"] == "cuda"
        @test startswith(gpu_execution["workerId"], "gpu-worker-")
        @test gpu_execution["dispatchPlan"][2]["lane"] == "gpu"
        json_updated_workflow = JSON3.read(get_workflow_response(state, "wf-foundation"), Dict{String,Any})
        @test json_updated_workflow["name"] == "Foundation JSON Save"
        @test length(json_updated_workflow["flowVariables"]) == 2
        @test json_updated_workflow["flowVariables"][2]["name"] == "BATCH_WINDOW"
        @test json_updated_workflow["graph"]["revision"] == 3
        @test length(json_updated_workflow["dashboards"][1]["charts"]) == 5
        persisted_workflow = TOML.parse(read(joinpath(store_root, "workflows", "wf-foundation.toml"), String))
        @test persisted_workflow["flow_variables"][2]["default"] == "2026-Q2"
        @test persisted_workflow["workflow"]["graph"]["revision"] == 3
        @test occursin("\"status\":\"updated\"", update_workflow_response!(state, "wf-foundation"; workflow_toml = updated_toml))
        @test occursin("Foundation PoC Updated", get_workflow_response(state, "wf-foundation"))
        @test occursin("\"items\":[", execution_list_response(state))
        @test isfile(joinpath(store_root, "workflows", "wf-parallel.toml"))

        health_response = route_request(state, HTTP.Request("GET", "/health"))
        list_response = route_request(state, HTTP.Request("GET", "/api/v1/workflows"))
        detail_response = route_request(state, HTTP.Request("GET", "/api/v1/workflows/wf-foundation"))
        create_response = route_request(
            state,
            HTTP.Request("POST", "/api/v1/workflows", ["Content-Type" => "application/json"], JSON3.write(Dict("workflowToml" => read(parallel_path, String)))),
        )
        json_create_response = route_request(
            state,
            HTTP.Request("POST", "/api/v1/workflows", ["Content-Type" => "application/json"], JSON3.write(foundation_workflow_payload)),
        )
        update_response = route_request(
            state,
            HTTP.Request("PUT", "/api/v1/workflows/wf-foundation", ["Content-Type" => "application/json"], JSON3.write(Dict("workflowToml" => updated_toml))),
        )
        execute_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/execute",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "executionMode" => "gpu_preferred",
                        "flowVariables" => Dict("JULIAFLOW_GPU_DEVICE" => "nvidia:0"),
                    ),
                ),
            ),
        )
        hub_list_response = route_request(state, HTTP.Request("GET", "/api/v1/hub/extensions"))
        hub_install_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/juliaflow-ops-preview/install",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("action" => "enable")),
            ),
        )
        hub_register_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-labs-pack",
                            "name" => "JuliaFlow Labs Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Labs pack for compatible install tests.",
                            "packageRef" => "hub://labs/pack",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/labs-pack"
                        ),
                    ),
                ),
            ),
        )
        hub_bad_signature_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-bad-signature",
                            "name" => "Bad Signature Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Invalid signature format coverage.",
                            "packageRef" => "hub://labs/bad-signature",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "signed-partner-juliaflow-labs",
                            "releaseNotesRef" => "https://example.test/bad-signature"
                        ),
                    ),
                ),
            ),
        )
        hub_bad_release_notes_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-bad-release-notes",
                            "name" => "Bad Release Notes Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Invalid release notes URL coverage.",
                            "packageRef" => "hub://labs/bad-release-notes",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "http://example.test/bad-release-notes"
                        ),
                    ),
                ),
            ),
        )
        hub_bad_identity_suffix_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-bad-partner-identity",
                            "name" => "Bad Partner Identity Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Invalid partner identity suffix coverage.",
                            "packageRef" => "hub://labs/bad-partner-identity",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/bad-partner-identity"
                        ),
                    ),
                ),
            ),
        )
        hub_bad_signature_identity_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-bad-signature-identity",
                            "name" => "Bad Signature Identity Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Signature does not bind to publisher identity.",
                            "packageRef" => "hub://labs/bad-signature-identity",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:other-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/bad-signature-identity"
                        ),
                    ),
                ),
            ),
        )
        hub_bad_package_ref_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/register",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "manifest" => Dict(
                            "extensionId" => "juliaflow-bad-package-ref",
                            "name" => "Bad Package Ref Pack",
                            "version" => "0.2.0",
                            "publisher" => "partner",
                            "summary" => "Partner package ref scheme policy coverage.",
                            "packageRef" => "extensions/bad-package-ref",
                            "tags" => ["labs", "partner"],
                            "engineCompatibility" => "alpha-core",
                            "requiredContractVersion" => "0.1.0",
                            "supportedCheckpoints" => ["cp/01-contracts-frozen"],
                            "compatibleCheckpoints" => ["cp/01-contracts-frozen"],
                            "dependencies" => String[],
                            "publisherIdentity" => "partner:juliaflow-labs",
                            "signature" => "sig:partner:juliaflow-labs:v0.2.0",
                            "releaseNotesRef" => "https://example.test/bad-package-ref"
                        ),
                    ),
                ),
            ),
        )
        dashboard_publish_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/dashboards/dashboard-foundation/publish",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("visibility" => "public")),
            ),
        )
        dashboard_list_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/workflows/wf-foundation/dashboards"),
        )
        dashboard_publish_payload = JSON3.read(String(dashboard_publish_response.body), Dict{String,Any})
        dashboard_share_token = String(dashboard_publish_payload["dashboard"]["shareToken"])
        dashboard_get_unauthorized_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation"),
        )
        dashboard_get_invalid_token_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation?shareToken=wrong-token"),
        )
        dashboard_get_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation?shareToken=$(dashboard_share_token)"),
        )
        dashboard_chart_data_invalid_token_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation/charts/chart-line/data?shareToken=wrong-token"),
        )
        dashboard_chart_data_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation/charts/chart-line/data?shareToken=$(dashboard_share_token)"),
        )
        dashboard_chart_export_response = route_request(
            state,
            HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation/charts/chart-line/export.csv?shareToken=$(dashboard_share_token)"),
        )
        dashboard_publish_workspace_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/dashboards/dashboard-foundation/publish",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("visibility" => "workspace")),
            ),
        )
        dashboard_get_workspace_response = withenv("JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN" => "workspace-secret") do
            route_request(
                state,
                HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation"),
            )
        end
        dashboard_get_workspace_invalid_token_response = withenv("JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN" => "workspace-secret") do
            route_request(
                state,
                HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation?workspaceToken=wrong-token"),
            )
        end
        dashboard_get_workspace_authorized_response = withenv("JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN" => "workspace-secret") do
            route_request(
                state,
                HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation?workspaceToken=workspace-secret"),
            )
        end
        dashboard_get_workspace_bearer_invalid_response = withenv("JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN" => "workspace-secret") do
            route_request(
                state,
                HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation", ["Authorization" => "Bearer wrong-secret"]),
            )
        end
        dashboard_get_workspace_bearer_authorized_response = withenv("JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN" => "workspace-secret") do
            route_request(
                state,
                HTTP.Request("GET", "/api/v1/dashboards/dashboard-foundation", ["Authorization" => "Bearer workspace-secret"]),
            )
        end
        auth_missing_workflow_list_response = withenv("JULIAFLOW_DEV_AUTH_TOKEN" => "dev-secret") do
            route_request(state, HTTP.Request("GET", "/api/v1/workflows"))
        end
        auth_viewer_workflow_list_response = withenv("JULIAFLOW_DEV_AUTH_TOKEN" => "dev-secret") do
            route_request(
                state,
                HTTP.Request(
                    "GET",
                    "/api/v1/workflows",
                    ["Authorization" => "Bearer dev-secret", "X-JuliaFlow-Workspace-Role" => "viewer"],
                ),
            )
        end
        auth_viewer_execute_response = withenv("JULIAFLOW_DEV_AUTH_TOKEN" => "dev-secret") do
            route_request(
                state,
                HTTP.Request(
                    "POST",
                    "/api/v1/workflows/wf-foundation/execute",
                    ["Authorization" => "Bearer dev-secret", "X-JuliaFlow-Workspace-Role" => "viewer", "Content-Type" => "application/json"],
                    JSON3.write(Dict()),
                ),
            )
        end
        auth_editor_execute_response = withenv("JULIAFLOW_DEV_AUTH_TOKEN" => "dev-secret") do
            route_request(
                state,
                HTTP.Request(
                    "POST",
                    "/api/v1/workflows/wf-foundation/execute",
                    ["Authorization" => "Bearer dev-secret", "X-JuliaFlow-Workspace-Role" => "editor", "Content-Type" => "application/json"],
                    JSON3.write(Dict("executionMode" => "batch")),
                ),
            )
        end
        auth_editor_hub_install_response = withenv("JULIAFLOW_DEV_AUTH_TOKEN" => "dev-secret") do
            route_request(
                state,
                HTTP.Request(
                    "POST",
                    "/api/v1/hub/extensions/juliaflow-base/install",
                    ["Authorization" => "Bearer dev-secret", "X-JuliaFlow-Workspace-Role" => "editor", "Content-Type" => "application/json"],
                    JSON3.write(Dict("action" => "install")),
                ),
            )
        end
        hub_enable_registered_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/hub/extensions/juliaflow-labs-pack/install",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("action" => "enable")),
            ),
        )
        execution_list = route_request(state, HTTP.Request("GET", "/api/v1/executions"))
        checkpoint_post = route_request(
            state,
            HTTP.Request("POST", "/api/v1/checkpoints", ["Content-Type" => "application/json"], JSON3.write(Dict("tag" => "cp/02-alpha-core", "summary" => "Alpha core started"))),
        )
        import_post = route_request(
            state,
            HTTP.Request("POST", "/api/v1/workflows/import", ["Content-Type" => "application/json"], JSON3.write(Dict("sourcePath" => parallel_path))),
        )
        execute_payload = JSON3.read(String(execute_response.body), Dict{String,Any})
        execute_payload_id = get(execute_payload, "executionId", "missing-execution-id")
        gpu_execute_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-gpu-alpha/execute",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("executionMode" => "gpu_required")),
            ),
        )
        gpu_execute_payload = JSON3.read(String(gpu_execute_response.body), Dict{String,Any})
        preflight = route_request(
            state,
            HTTP.Request(
                "OPTIONS",
                "/api/v1/executions/$(execute_payload_id)/status",
                [
                    "Origin" => "http://127.0.0.1:5173",
                    "Access-Control-Request-Method" => "POST",
                ],
            ),
        )
        missing_route = route_request(state, HTTP.Request("GET", "/missing"))

        @test health_response.status == 200
        @test occursin("workflowCount", String(health_response.body))
        @test occursin("\"eventBackboneMode\":", String(health_response.body))
        @test occursin("\"streamWorkerMode\":", String(health_response.body))
        @test occursin("\"eventLogSize\":", String(health_response.body))
        @test occursin("\"latestEventSequence\":", String(health_response.body))
        @test occursin("\"gatewayConsumerCursor\":", String(health_response.body))
        @test occursin("\"gatewayConsumerLag\":", String(health_response.body))
        @test occursin("\"eventConsumerCatchupPercent\":", String(health_response.body))
        @test occursin("\"activeStreamExecutions\":", String(health_response.body))
        @test occursin("\"queuedGpuExecutions\":", String(health_response.body))
        @test occursin("\"queuedStreamExecutions\":", String(health_response.body))
        @test occursin("\"activeGpuExecutions\":", String(health_response.body))
        @test occursin("\"gpuWorkerOwnedExecutions\":", String(health_response.body))
        @test occursin("\"queuedExecutionsTotal\":", String(health_response.body))
        @test occursin("\"runningExecutionsTotal\":", String(health_response.body))
        @test list_response.status == 200
        @test occursin("wf-foundation", String(list_response.body))
        @test detail_response.status == 200
        @test occursin("\"workflowId\":\"wf-foundation\"", String(detail_response.body))
        @test hub_list_response.status == 200
        @test occursin("\"extensionId\":\"juliaflow-base\"", String(hub_list_response.body))
        @test hub_install_response.status == 409
        @test occursin("Extension not validated for current checkpoint", String(hub_install_response.body))
        @test hub_register_response.status == 201
        @test occursin("\"extensionId\":\"juliaflow-labs-pack\"", String(hub_register_response.body))
        @test occursin("\"compatible\":true", String(hub_register_response.body))
        @test hub_bad_signature_response.status == 201
        @test occursin("signature must use sig: prefix", String(hub_bad_signature_response.body))
        @test hub_bad_release_notes_response.status == 201
        @test occursin("release notes reference must be https URL", String(hub_bad_release_notes_response.body))
        @test hub_bad_identity_suffix_response.status == 201
        @test occursin("publisher identity suffix must not be empty", String(hub_bad_identity_suffix_response.body))
        @test hub_bad_signature_identity_response.status == 201
        @test occursin("signature must include publisher identity suffix", String(hub_bad_signature_identity_response.body))
        @test hub_bad_package_ref_response.status == 201
        @test occursin("package reference must use hub:// scheme", String(hub_bad_package_ref_response.body))
        @test dashboard_publish_response.status == 200
        @test occursin("\"dashboardId\":\"dashboard-foundation\"", String(dashboard_publish_response.body))
        @test occursin("\"version\":1", String(dashboard_publish_response.body))
        @test occursin("\"visibility\":\"public\"", String(dashboard_publish_response.body))
        @test occursin("\"shareToken\":", String(dashboard_publish_response.body))
        @test haskey(dashboard_publish_payload["dashboard"], "datasets")
        @test length(dashboard_publish_payload["dashboard"]["datasets"]["sales_overview"]) == 3
        @test dashboard_list_response.status == 200
        @test occursin("\"items\":[", String(dashboard_list_response.body))
        @test dashboard_get_unauthorized_response.status == 401
        @test occursin("invalid share token", String(dashboard_get_unauthorized_response.body))
        @test dashboard_get_invalid_token_response.status == 401
        @test occursin("invalid share token", String(dashboard_get_invalid_token_response.body))
        @test dashboard_get_response.status == 200
        @test occursin("\"publishedAt\":", String(dashboard_get_response.body))
        @test dashboard_chart_data_invalid_token_response.status == 401
        @test occursin("invalid share token", String(dashboard_chart_data_invalid_token_response.body))
        @test dashboard_chart_data_response.status == 200
        dashboard_chart_data_payload = JSON3.read(String(dashboard_chart_data_response.body), Dict{String,Any})
        @test dashboard_chart_data_payload["dashboardId"] == "dashboard-foundation"
        @test dashboard_chart_data_payload["chartId"] == "chart-line"
        @test dashboard_chart_data_payload["datasetKey"] == "sales_overview"
        @test dashboard_chart_data_payload["rowCount"] == 3
        @test dashboard_chart_data_payload["rows"][1]["window"] == "2026-Q1"
        @test dashboard_chart_data_payload["rows"][1]["amount"] == 120.0
        @test dashboard_chart_data_payload["fields"] == ["amount", "capacity", "region", "window"]
        @test dashboard_chart_data_payload["semantic"]["dimensions"] == ["window", "region"]
        @test dashboard_chart_data_payload["semantic"]["measures"] == ["amount", "capacity"]
        @test dashboard_chart_data_payload["semantic"]["availableMeasures"] == ["amount", "capacity"]
        @test dashboard_chart_data_payload["cache"]["cacheKey"] == "dashboard-foundation:chart-line:v1"
        @test dashboard_chart_data_payload["cache"]["live"] == true
        @test dashboard_chart_data_payload["exportFormats"] == ["json", "csv"]
        @test dashboard_chart_export_response.status == 200
        @test occursin("amount,capacity,region,window", String(dashboard_chart_export_response.body))
        @test occursin("120.0,180.0,west,2026-Q1", String(dashboard_chart_export_response.body))
        @test dashboard_publish_workspace_response.status == 200
        @test occursin("\"visibility\":\"workspace\"", String(dashboard_publish_workspace_response.body))
        @test dashboard_get_workspace_response.status == 401
        @test occursin("invalid workspace access token", String(dashboard_get_workspace_response.body))
        @test dashboard_get_workspace_invalid_token_response.status == 401
        @test occursin("invalid workspace access token", String(dashboard_get_workspace_invalid_token_response.body))
        @test dashboard_get_workspace_authorized_response.status == 200
        @test occursin("\"visibility\":\"workspace\"", String(dashboard_get_workspace_authorized_response.body))
        @test dashboard_get_workspace_bearer_invalid_response.status == 401
        @test occursin("invalid workspace access token", String(dashboard_get_workspace_bearer_invalid_response.body))
        @test dashboard_get_workspace_bearer_authorized_response.status == 200
        @test occursin("\"visibility\":\"workspace\"", String(dashboard_get_workspace_bearer_authorized_response.body))
        @test auth_missing_workflow_list_response.status == 401
        @test occursin("invalid auth token", String(auth_missing_workflow_list_response.body))
        @test auth_viewer_workflow_list_response.status == 200
        @test occursin("wf-foundation", String(auth_viewer_workflow_list_response.body))
        @test auth_viewer_execute_response.status == 403
        @test occursin("permission denied: workflow:execute", String(auth_viewer_execute_response.body))
        @test auth_editor_execute_response.status == 202
        @test auth_editor_hub_install_response.status == 403
        @test occursin("permission denied: hub:install", String(auth_editor_hub_install_response.body))
        @test hub_enable_registered_response.status == 200
        @test occursin("\"installState\":\"enabled\"", String(hub_enable_registered_response.body))
        @test create_response.status == 201
        @test occursin("\"status\":\"created\"", String(create_response.body))
        @test json_create_response.status == 201
        @test occursin("\"status\":\"created\"", String(json_create_response.body))
        @test update_response.status == 200
        @test occursin("\"status\":\"updated\"", String(update_response.body))
        @test execute_response.status == 202
        @test haskey(execute_payload, "executionId")
        @test occursin("\"checkpointTag\":\"cp/01-contracts-frozen\"", String(execute_response.body))
        @test occursin("\"requested_execution_mode\":\"gpu_preferred\"", String(execute_response.body))
        @test occursin("\"flow_variables\":{\"JULIAFLOW_GPU_DEVICE\":\"nvidia:0\"}", String(execute_response.body))
        @test occursin("\"resourcePlan\":[", String(execute_response.body))
        @test gpu_execute_response.status == 202
        @test gpu_execute_payload["status"] == "queued"
        @test gpu_execute_payload["dispatchLane"] == "gpu"
        @test gpu_execute_payload["dispatchWorkerPool"] == "alpha-gpu"
        @test startswith(gpu_execute_payload["workerId"], "gpu-worker-")
        worker_state = load_state(store_root)
        processed_gpu = JuliaFlowApiGateway.JuliaFlowWorkerService.process_gpu_worker_tick!(
            worker_state.worker_service,
            worker_state.executions;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        @test length(processed_gpu) >= 1
        promoted_gpu = processed_gpu[end]
        JuliaFlowApiGateway.save_execution!(worker_state.repository, promoted_gpu)
        changed_gpu = JuliaFlowApiGateway.sync_external_execution_updates!(state)
        @test any(execution.execution_id == gpu_execute_payload["executionId"] for execution in changed_gpu)
        synced_gpu_detail = JSON3.read(execution_detail_response(state, gpu_execute_payload["executionId"]), Dict{String,Any})
        @test synced_gpu_detail["status"] == "running"
        transition_response = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/executions/$(execute_payload_id)/status",
                ["Content-Type" => "application/json"],
                JSON3.write(
                    Dict(
                        "status" => "queued",
                        "message" => "Queued for worker dispatch",
                        "metadata" => Dict("workerId" => "worker-foundation-1"),
                    ),
                ),
            ),
        )
        invalid_transition = route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/executions/$(execute_payload_id)/status",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("status" => "accepted")),
            ),
        )
        execution_detail = route_request(state, HTTP.Request("GET", "/api/v1/executions/$(execute_payload_id)"))
        @test execution_list.status == 200
        @test occursin("\"items\":[", String(execution_list.body))
        @test transition_response.status == 200
        @test occursin("\"status\":\"queued\"", String(transition_response.body))
        @test occursin("\"workerId\":\"worker-foundation-1\"", String(transition_response.body))
        @test invalid_transition.status == 500
        @test occursin("invalid execution status transition", String(invalid_transition.body))
        @test execution_detail.status == 200
        @test occursin(execute_payload_id, String(execution_detail.body))
        @test occursin("\"status\":\"queued\"", String(execution_detail.body))
        @test checkpoint_post.status == 201
        @test occursin("cp/02-alpha-core", String(checkpoint_post.body))
        @test import_post.status == 201
        @test occursin("wf-parallel", String(import_post.body))
        @test preflight.status == 204
        @test any(header -> header.first == "Access-Control-Allow-Origin" && header.second == "*", preflight.headers)
        @test any(header -> header.first == "Access-Control-Allow-Methods" && occursin("OPTIONS", header.second), preflight.headers)
        @test missing_route.status == 404
        @test any(header -> header.first == "Access-Control-Allow-Origin" && header.second == "*", health_response.headers)
    end
end

@testset "API Gateway Realtime" begin
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")

    withenv("JULIAFLOW_EVENT_BACKBONE_MODE" => "dual_write") do
        mktempdir() do store_root
            state = foundation_state(foundation_path; store_root = store_root)
            JuliaFlowApiGateway.import_workflow_response!(state; source_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "parallel.workflow.toml"))
            socket = FakeRealtimeSocket(String[])
        canvas_response, canvas_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 1,
                    "method" => "canvas.subscribe",
                    "params" => Dict("workflowId" => "wf-foundation"),
                ),
            ),
            socket,
        )
        canvas_reply = JSON3.read(String(canvas_response), Dict{String,Any})
        workflow_event = JSON3.read(canvas_notifications[1], Dict{String,Any})
        node_event = JSON3.read(canvas_notifications[2], Dict{String,Any})

        @test canvas_reply["result"]["subscriptionId"] isa AbstractString
        @test workflow_event["method"] == "workflow.state.changed"
        @test workflow_event["params"]["workflowId"] == "wf-foundation"
        @test node_event["method"] == "node.state.changed"

        dashboard_response, dashboard_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 2,
                    "method" => "dashboard.subscribe",
                    "params" => Dict("dashboardId" => "ops-forecast", "outletIds" => ["bi-main"]),
                ),
            ),
        )
        dashboard_reply = JSON3.read(String(dashboard_response), Dict{String,Any})
        dashboard_event = JSON3.read(dashboard_notifications[1], Dict{String,Any})

        @test dashboard_reply["result"]["subscriptionId"] isa AbstractString
        @test dashboard_event["method"] == "dashboard.outlet.updated"
        @test dashboard_event["params"]["dashboardId"] == "ops-forecast"

        execute_response, execute_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 3,
                    "method" => "workflow.execute",
                    "params" => Dict(
                        "workflowId" => "wf-foundation",
                        "executionMode" => "cpu_only",
                        "flowVariables" => Dict("JULIAFLOW_GPU_DEVICE" => "cpu-fallback"),
                    ),
                ),
            ),
        )
        execute_reply = JSON3.read(String(execute_response), Dict{String,Any})

        @test execute_reply["result"]["status"] == "accepted"
        @test execute_reply["result"]["jobId"] isa AbstractString
        @test isempty(execute_notifications)
        execution_record = JSON3.read(execution_detail_response(state, execute_reply["result"]["jobId"]), Dict{String,Any})
        @test execution_record["requested_execution_mode"] == "cpu_only"
        @test execution_record["flow_variables"]["JULIAFLOW_GPU_DEVICE"] == "cpu-fallback"
        @test execution_record["resourcePlan"][1]["lane"] == "cpu"

        gpu_create_response = JuliaFlowApiGateway.create_workflow_response_from_body!(
            state,
            Dict(
                "workflow" => Dict(
                    "version" => "0.3.0",
                    "workflowId" => "wf-gpu-alpha",
                    "name" => "GPU Alpha",
                    "flowVariables" => [Dict("name" => "JULIAFLOW_GPU_DEVICE", "type" => "GPUDeviceID", "default" => "nvidia:0")],
                    "runtime" => Dict("runMode" => "batch"),
                    "nodes" => [
                        Dict(
                            "id" => "node-source",
                            "type" => "JuliaFlow.Base.CSVReader",
                            "name" => "CSV Reader",
                            "executionHint" => "cpu_only",
                            "capabilities" => Dict("executionMode" => "batch", "resourceClass" => "cpu", "workerPool" => "alpha-cpu"),
                            "ports" => [Dict("id" => "out", "direction" => "output", "type" => "data_table")],
                            "config" => Dict("path" => "assets/sample.csv"),
                        ),
                        Dict(
                            "id" => "node-train",
                            "type" => "JuliaFlow.Base.ModelTrain",
                            "name" => "GPU Trainer",
                            "executionHint" => "gpu_required",
                            "capabilities" => Dict(
                                "executionMode" => "batch",
                                "resourceClass" => "gpu",
                                "accelerator" => "cuda",
                                "workerPool" => "alpha-gpu",
                            ),
                            "ports" => [
                                Dict("id" => "in", "direction" => "input", "type" => "data_table"),
                                Dict("id" => "model", "direction" => "output", "type" => "model"),
                            ],
                            "config" => Dict("target" => "amount", "gpuDevicePreference" => "nvidia:0"),
                        ),
                    ],
                    "connections" => [
                        Dict(
                            "sourceNodeId" => "node-source",
                            "sourcePortId" => "out",
                            "targetNodeId" => "node-train",
                            "targetPortId" => "in",
                            "dataType" => "data_table",
                        ),
                    ],
                ),
            ),
        )
        @test occursin("\"status\":\"created\"", gpu_create_response)

        gpu_execute_response, gpu_execute_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 40,
                    "method" => "workflow.execute",
                    "params" => Dict("workflowId" => "wf-gpu-alpha", "executionMode" => "gpu_required"),
                ),
            ),
        )
        gpu_execute_reply = JSON3.read(String(gpu_execute_response), Dict{String,Any})
        @test gpu_execute_reply["result"]["status"] == "queued"
        @test isempty(gpu_execute_notifications)
        gpu_execution_record = JSON3.read(execution_detail_response(state, gpu_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test gpu_execution_record["dispatchLane"] == "gpu"
        @test gpu_execution_record["dispatchWorkerPool"] == "alpha-gpu"
        @test gpu_execution_record["dispatchIsolationMode"] == "isolated"
        @test startswith(gpu_execution_record["workerId"], "gpu-worker-")

        gpu_canvas_response, _ = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 41,
                    "method" => "canvas.subscribe",
                    "params" => Dict("workflowId" => "wf-gpu-alpha"),
                ),
            ),
            socket,
        )
        @test JSON3.read(String(gpu_canvas_response), Dict{String,Any})["result"]["subscriptionId"] isa AbstractString
        gpu_worker_state = load_state(store_root)
        processed_gpu = JuliaFlowApiGateway.JuliaFlowWorkerService.process_gpu_worker_tick!(
            gpu_worker_state.worker_service,
            gpu_worker_state.executions;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        @test length(processed_gpu) >= 1
        for execution in processed_gpu
            JuliaFlowApiGateway.save_execution!(gpu_worker_state.repository, execution)
        end
        changed_gpu = JuliaFlowApiGateway.sync_external_execution_updates!(state)
        @test any(execution.execution_id == gpu_execute_reply["result"]["jobId"] for execution in changed_gpu)
        synced_gpu_record = JSON3.read(execution_detail_response(state, gpu_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test synced_gpu_record["status"] == "running"
        @test any(
            occursin("\"method\":\"execution.state.changed\"", message) &&
                occursin("\"executionId\":\"" * gpu_execute_reply["result"]["jobId"] * "\"", message) &&
                occursin("\"status\":\"running\"", message)
            for message in socket.messages
        )
        completed_gpu = JuliaFlowApiGateway.JuliaFlowWorkerService.process_gpu_compute_tick!(
            gpu_worker_state.worker_service,
            state.workflows,
            gpu_worker_state.executions;
            execution_record = JuliaFlowApiGateway.execution_record,
            transition_execution_record = transition_execution_record,
            materialize_execution = JuliaFlowApiGateway.materialize_execution,
        )
        @test length(completed_gpu) >= 1
        for execution in completed_gpu
            JuliaFlowApiGateway.save_execution!(gpu_worker_state.repository, execution)
        end
        changed_gpu_complete = JuliaFlowApiGateway.sync_external_execution_updates!(state)
        @test any(execution.execution_id == gpu_execute_reply["result"]["jobId"] for execution in changed_gpu_complete)
        completed_gpu_record = JSON3.read(execution_detail_response(state, gpu_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test completed_gpu_record["status"] == "completed"
        @test completed_gpu_record["gpuExecutionPath"] == "gpu"
        @test completed_gpu_record["gpuWorkloadResult"]["sum"] == 10.0

        stream_execute_response, stream_execute_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 4,
                    "method" => "workflow.execute",
                    "params" => Dict("workflowId" => "wf-parallel"),
                ),
            ),
        )
        stream_execute_reply = JSON3.read(String(stream_execute_response), Dict{String,Any})
        @test stream_execute_reply["result"]["status"] == "running"
        @test isempty(stream_execute_notifications)
        stream_record = JSON3.read(execution_detail_response(state, stream_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test stream_record["streamLifecycleStatus"] == "active"

        pause_response, pause_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 5,
                    "method" => "workflow.pause",
                    "params" => Dict("workflowId" => "wf-parallel"),
                ),
            ),
        )
        pause_reply = JSON3.read(String(pause_response), Dict{String,Any})
        @test pause_reply["result"]["status"] == "paused"
        @test isempty(pause_notifications)
        paused_record = JSON3.read(execution_detail_response(state, stream_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test paused_record["streamLifecycleStatus"] == "paused"

        resume_response, resume_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 6,
                    "method" => "workflow.resume",
                    "params" => Dict("workflowId" => "wf-parallel"),
                ),
            ),
        )
        resume_reply = JSON3.read(String(resume_response), Dict{String,Any})
        @test resume_reply["result"]["status"] == "active"
        @test isempty(resume_notifications)
        resumed_record = JSON3.read(execution_detail_response(state, stream_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test resumed_record["streamLifecycleStatus"] == "active"

        stream_canvas_response, _ = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 7,
                    "method" => "canvas.subscribe",
                    "params" => Dict("workflowId" => "wf-parallel"),
                ),
            ),
            socket,
        )
        @test JSON3.read(String(stream_canvas_response), Dict{String,Any})["result"]["subscriptionId"] isa AbstractString

        stop_response, stop_notifications = JuliaFlowApiGateway.handle_realtime_request!(
            state,
            JSON3.write(
                Dict(
                    "jsonrpc" => "2.0",
                    "id" => 8,
                    "method" => "workflow.stop",
                    "params" => Dict("workflowId" => "wf-parallel"),
                ),
            ),
        )
        stop_reply = JSON3.read(String(stop_response), Dict{String,Any})
        @test stop_reply["result"]["status"] == "stopped"
        @test isempty(stop_notifications)
        stopped_record = JSON3.read(execution_detail_response(state, stream_execute_reply["result"]["jobId"]), Dict{String,Any})
        @test stopped_record["streamLifecycleStatus"] == "stopped"
        @test stopped_record["status"] == "completed"
        checkpoint_payload = JuliaFlowApiGateway.streaming_checkpoint_completed_payload(state, "wf-parallel", state.executions[end])
        @test haskey(checkpoint_payload, "consumerLag")
        @test haskey(checkpoint_payload["offsets"], "lastProcessedAt")
        JuliaFlowApiGateway.consume_gateway_events!(state)
        @test any(occursin("\"method\":\"streaming.checkpoint.completed\"", message) for message in socket.messages)

            withenv("JULIAFLOW_STREAM_WORKER_MODE" => "process") do
                external_socket = FakeRealtimeSocket(String[])
                external_canvas_response, _ = JuliaFlowApiGateway.handle_realtime_request!(
                    state,
                    JSON3.write(
                        Dict(
                            "jsonrpc" => "2.0",
                            "id" => 9,
                            "method" => "canvas.subscribe",
                            "params" => Dict("workflowId" => "wf-parallel"),
                        ),
                    ),
                    external_socket,
                )
                @test JSON3.read(String(external_canvas_response), Dict{String,Any})["result"]["subscriptionId"] isa AbstractString

                queued_stream_response, queued_stream_notifications = JuliaFlowApiGateway.handle_realtime_request!(
                    state,
                    JSON3.write(
                        Dict(
                            "jsonrpc" => "2.0",
                            "id" => 10,
                            "method" => "workflow.execute",
                            "params" => Dict("workflowId" => "wf-parallel"),
                        ),
                    ),
                )
                queued_stream_reply = JSON3.read(String(queued_stream_response), Dict{String,Any})
                @test queued_stream_reply["result"]["status"] == "queued"
                @test isempty(queued_stream_notifications)

                worker_state = load_state(store_root)
                processed_streams = JuliaFlowApiGateway.JuliaFlowWorkerService.process_stream_worker_tick!(
                    worker_state.worker_service,
                    worker_state.executions;
                    execution_record = JuliaFlowApiGateway.execution_record,
                    transition_execution_record = transition_execution_record,
                    materialize_execution = JuliaFlowApiGateway.materialize_execution,
                )
                @test length(processed_streams) >= 1
                for execution in processed_streams
                    JuliaFlowApiGateway.save_execution!(worker_state.repository, execution)
                end

                changed_executions = JuliaFlowApiGateway.sync_external_execution_updates!(state)
                @test any(execution.execution_id == queued_stream_reply["result"]["jobId"] for execution in changed_executions)

                synced_stream_record = JSON3.read(execution_detail_response(state, queued_stream_reply["result"]["jobId"]), Dict{String,Any})
                @test synced_stream_record["status"] == "running"
                @test synced_stream_record["streamLifecycleStatus"] == "active"
                @test any(
                    occursin("\"method\":\"execution.state.changed\"", message) &&
                        occursin("\"executionId\":\"" * queued_stream_reply["result"]["jobId"] * "\"", message) &&
                        occursin("\"status\":\"running\"", message)
                    for message in external_socket.messages
                )
            end
        end
    end

    withenv(
        "JULIAFLOW_EVENT_BACKBONE_MODE" => "dual_write",
        "JULIAFLOW_STREAM_WORKER_MODE" => "process",
    ) do
        mktempdir() do store_root
            state = foundation_state(foundation_path; store_root = store_root)
            JuliaFlowApiGateway.import_workflow_response!(state; source_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "parallel.workflow.toml"))
            socket = FakeRealtimeSocket(String[])
            canvas_response, _ = JuliaFlowApiGateway.handle_realtime_request!(
                state,
                JSON3.write(
                    Dict(
                        "jsonrpc" => "2.0",
                        "id" => 101,
                        "method" => "canvas.subscribe",
                        "params" => Dict("workflowId" => "wf-parallel"),
                    ),
                ),
                socket,
            )
            @test JSON3.read(String(canvas_response), Dict{String,Any})["result"]["subscriptionId"] isa AbstractString

            queued_stream_response, _ = JuliaFlowApiGateway.handle_realtime_request!(
                state,
                JSON3.write(
                    Dict(
                        "jsonrpc" => "2.0",
                        "id" => 102,
                        "method" => "workflow.execute",
                        "params" => Dict("workflowId" => "wf-parallel"),
                    ),
                ),
            )
            queued_stream_reply = JSON3.read(String(queued_stream_response), Dict{String,Any})
            @test queued_stream_reply["result"]["jobId"] isa AbstractString
            @test isempty(socket.messages)

            queued_events = JuliaFlowApiGateway.consume_gateway_events!(state)
            @test any(event.event_type == "execution.changed" for event in queued_events)
            @test any(
                occursin("\"method\":\"execution.state.changed\"", message) &&
                    occursin("\"executionId\":\"" * queued_stream_reply["result"]["jobId"] * "\"", message)
                for message in socket.messages
            )
            message_count_after_consume = length(socket.messages)
            @test isempty(JuliaFlowApiGateway.sync_external_execution_updates!(state))
            @test length(socket.messages) == message_count_after_consume

            worker_state = load_state(store_root)
            processed_streams = JuliaFlowApiGateway.JuliaFlowWorkerService.process_stream_worker_tick!(
                worker_state.worker_service,
                worker_state.executions;
                execution_record = JuliaFlowApiGateway.execution_record,
                transition_execution_record = transition_execution_record,
                materialize_execution = JuliaFlowApiGateway.materialize_execution,
            )
            @test length(processed_streams) >= 1
            for execution in processed_streams
                JuliaFlowApiGateway.save_execution!(worker_state.repository, execution; producer = "stream-worker")
            end

            consumed = JuliaFlowApiGateway.consume_gateway_events!(state)
            @test any(event.producer == "stream-worker" for event in consumed)
            synced_stream_record = JSON3.read(execution_detail_response(state, queued_stream_reply["result"]["jobId"]), Dict{String,Any})
            @test synced_stream_record["status"] == "running"
            @test synced_stream_record["streamLifecycleStatus"] == "active"
            message_count_after_worker_consume = length(socket.messages)
            @test isempty(JuliaFlowApiGateway.sync_external_execution_updates!(state))
            @test length(socket.messages) == message_count_after_worker_consume

            duplicate = JuliaFlowApiGateway.JuliaFlowGatewayRepository.append_event!(
                state.repository,
                "execution.changed";
                aggregate_type = "execution",
                aggregate_id = queued_stream_reply["result"]["jobId"],
                payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(synced_stream_record)),
                producer = "test-suite",
                event_id = "dup-event-001",
            )
            JuliaFlowApiGateway.process_gateway_event!(state, duplicate)
            message_count = length(socket.messages)
            @test !JuliaFlowApiGateway.process_gateway_event!(state, duplicate)
            @test length(socket.messages) == message_count

            restarted = load_state(store_root)
            restarted_socket = FakeRealtimeSocket(String[])
            JuliaFlowApiGateway.handle_realtime_request!(
                restarted,
                JSON3.write(
                    Dict(
                        "jsonrpc" => "2.0",
                        "id" => 103,
                        "method" => "canvas.subscribe",
                        "params" => Dict("workflowId" => "wf-parallel"),
                    ),
                ),
                restarted_socket,
            )
            replayed = JuliaFlowApiGateway.consume_gateway_events!(restarted)
            @test length(replayed) == 1
            @test replayed[1].event_id == "dup-event-001"
            @test isempty(JuliaFlowApiGateway.consume_gateway_events!(restarted))
        end
    end
end

@testset "Base Extension" begin
    @test haskey(available_nodes(), DEFAULT_NODE_KEY)
    result = execute_passthrough("memory://foundation.arrow")
    @test result.outputs[DEFAULT_OUTPUT_PORT_ID].ref == "memory://foundation.arrow"
end

@testset "Gateway Audit Events" begin
    store_root = mktempdir()
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    state = foundation_state(foundation_path; store_root = store_root)

    create_body = JSON3.write(
        Dict(
            "workflow" => Dict(
                "workflowId" => "wf-audit",
                "name" => "Audit Workflow",
                "version" => "0.1.0",
                "nodes" => Any[
                    Dict(
                        "id" => "node-source",
                        "name" => "Source",
                        "type" => "source.table",
                        "executionHint" => "cpu_only",
                        "config" => Dict("ref" => "memory://audit.arrow"),
                        "ports" => Any[
                            Dict("id" => "table_out", "direction" => "output", "type" => "data_table", "label" => "Table Out"),
                        ],
                    ),
                ],
                "connections" => Any[],
                "flowVariables" => Any[],
            ),
        ),
    )

    create_response = route_request(
        state,
        HTTP.Request("POST", "/api/v1/workflows", ["Content-Type" => "application/json"], create_body),
    )
    @test create_response.status == 201

    execute_response = route_request(
        state,
        HTTP.Request(
            "POST",
            "/api/v1/workflows/wf-audit/execute",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("executionMode" => "cpu_only")),
        ),
    )
    @test execute_response.status == 202

    checkpoint_response = route_request(
        state,
        HTTP.Request(
            "POST",
            "/api/v1/checkpoints",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("tag" => "cp/audit-events", "summary" => "audit checkpoint")),
        ),
    )
    @test checkpoint_response.status == 201

    events = JuliaFlowApiGateway.JuliaFlowGatewayRepository.load_events(state.repository)
    audit_events = filter(event -> event.event_type == "audit.action", events)
    @test length(audit_events) >= 3
    @test any(event.payload["action"] == "workflow.create" && event.aggregate_id == "wf-audit" for event in audit_events)
    @test any(event.payload["action"] == "workflow.execute" && event.aggregate_id == "wf-audit" for event in audit_events)
    @test any(event.payload["action"] == "checkpoint.create" && event.aggregate_id == "cp/audit-events" for event in audit_events)
    @test all(haskey(event.payload, "authContext") for event in audit_events)
end

@testset "Gateway OIDC RBAC Policy" begin
    store_root = mktempdir()
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    state = foundation_state(foundation_path; store_root = store_root)

    owner_token = test_hs256_jwt(
        Dict{String,Any}(
            "iss" => "https://issuer.test",
            "aud" => "juliaflow-gateway",
            "sub" => "user-owner",
            "juliaflow_workspace" => "workspace-a",
            "juliaflow_role" => "owner",
            "exp" => 4102444800,
        ),
    )
    viewer_claims_owner_token = test_hs256_jwt(
        Dict{String,Any}(
            "iss" => "https://issuer.test",
            "aud" => "juliaflow-gateway",
            "sub" => "user-viewer",
            "juliaflow_workspace" => "workspace-a",
            "juliaflow_role" => "owner",
            "exp" => 4102444800,
        ),
    )
    disabled_user_token = test_hs256_jwt(
        Dict{String,Any}(
            "iss" => "https://issuer.test",
            "aud" => "juliaflow-gateway",
            "sub" => "user-disabled",
            "juliaflow_workspace" => "workspace-a",
            "juliaflow_role" => "owner",
            "exp" => 4102444800,
        ),
    )
    wrong_signature_token = string(viewer_claims_owner_token[1:end-2], "xx")

    env_pairs = (
        "JULIAFLOW_AUTH_MODE" => "oidc",
        "JULIAFLOW_OIDC_ISSUER" => "https://issuer.test",
        "JULIAFLOW_OIDC_AUDIENCE" => "juliaflow-gateway",
        "JULIAFLOW_OIDC_HS256_SECRET" => "oidc-secret",
    )

    missing_token_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows"))
    end
    invalid_token_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(wrong_signature_token)"]))
    end
    directory_body = Dict(
        "users" => Any[
            Dict("principalId" => "user-owner", "displayName" => "Owner User", "email" => "owner@example.test", "active" => true),
            Dict("principalId" => "user-viewer", "displayName" => "Viewer User", "active" => true),
            Dict("principalId" => "user-disabled", "displayName" => "Disabled User", "active" => false),
        ],
        "workspaces" => Any[
            Dict("workspaceId" => "workspace-a", "name" => "Workspace A", "active" => true),
        ],
    )
    save_directory_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request(
                "PUT",
                "/api/v1/admin/auth/directory",
                ["Authorization" => "Bearer $(owner_token)", "Content-Type" => "application/json"],
                JSON3.write(directory_body),
            ),
        )
    end
    lockout_directory_body = Dict(
        "users" => Any[
            Dict("principalId" => "user-viewer", "displayName" => "Viewer User", "active" => true),
        ],
        "workspaces" => Any[
            Dict("workspaceId" => "workspace-a", "name" => "Workspace A", "active" => true),
        ],
    )
    lockout_directory_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request(
                "PUT",
                "/api/v1/admin/auth/directory",
                ["Authorization" => "Bearer $(owner_token)", "Content-Type" => "application/json"],
                JSON3.write(lockout_directory_body),
            ),
        )
    end
    get_directory_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request("GET", "/api/v1/admin/auth/directory", ["Authorization" => "Bearer $(owner_token)"]),
        )
    end
    disabled_user_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(disabled_user_token)"]),
        )
    end
    policy_body = Dict(
        "roleBindings" => Any[
            Dict("principalId" => "user-viewer", "workspaceId" => "workspace-a", "role" => "viewer"),
        ],
        "resourcePolicies" => Any[
            Dict(
                "resourceType" => "workflow",
                "resourceId" => "wf-foundation",
                "workspaceId" => "workspace-a",
                "permissionsByRole" => Dict("viewer" => ["workflow:read"]),
            ),
        ],
    )
    invalid_directory_policy_body = Dict(
        "roleBindings" => Any[
            Dict("principalId" => "user-disabled", "workspaceId" => "workspace-a", "role" => "viewer"),
        ],
        "resourcePolicies" => Any[],
    )
    save_policy_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request(
                "PUT",
                "/api/v1/admin/auth/policies",
                ["Authorization" => "Bearer $(owner_token)", "Content-Type" => "application/json"],
                JSON3.write(policy_body),
            ),
        )
    end
    invalid_directory_policy_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request(
                "PUT",
                "/api/v1/admin/auth/policies",
                ["Authorization" => "Bearer $(owner_token)", "Content-Type" => "application/json"],
                JSON3.write(invalid_directory_policy_body),
            ),
        )
    end
    get_policy_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request("GET", "/api/v1/admin/auth/policies", ["Authorization" => "Bearer $(owner_token)"]),
        )
    end
    viewer_read_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request("GET", "/api/v1/workflows/wf-foundation", ["Authorization" => "Bearer $(viewer_claims_owner_token)"]),
        )
    end
    viewer_execute_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request(
                "POST",
                "/api/v1/workflows/wf-foundation/execute",
                ["Authorization" => "Bearer $(viewer_claims_owner_token)", "Content-Type" => "application/json"],
                JSON3.write(Dict()),
            ),
        )
    end
    audit_query_response = withenv(env_pairs...) do
        route_request(
            state,
            HTTP.Request("GET", "/api/v1/audit/actions?targetType=auth_policy&limit=10", ["Authorization" => "Bearer $(owner_token)"]),
        )
    end

    @test missing_token_response.status == 401
    @test occursin("OIDC bearer token is required", String(missing_token_response.body))
    @test invalid_token_response.status == 401
    @test occursin("invalid OIDC token signature", String(invalid_token_response.body))
    @test save_directory_response.status == 200
    @test occursin("user-viewer", String(save_directory_response.body))
    @test lockout_directory_response.status == 400
    @test occursin("admin principal not active in directory", String(lockout_directory_response.body))
    @test get_directory_response.status == 200
    @test occursin("Workspace A", String(get_directory_response.body))
    @test disabled_user_response.status == 403
    @test occursin("principal not active in directory", String(disabled_user_response.body))
    @test save_policy_response.status == 200
    @test occursin("user-viewer", String(save_policy_response.body))
    @test invalid_directory_policy_response.status == 400
    @test occursin("role binding principal not active in directory", String(invalid_directory_policy_response.body))
    @test get_policy_response.status == 200
    @test occursin("resourcePolicies", String(get_policy_response.body))
    @test viewer_read_response.status == 200
    @test viewer_execute_response.status == 403
    @test occursin("permission denied: workflow:execute", String(viewer_execute_response.body))
    @test audit_query_response.status == 200
    audit_payload = JSON3.read(String(audit_query_response.body), Dict{String,Any})
    @test audit_payload["count"] >= 1
    @test any(event["action"] == "auth.policy.update" for event in audit_payload["events"])
    @test !occursin("oidc-secret", String(audit_query_response.body))
    @test isfile(joinpath(store_root, "auth-policy.json"))
    @test isfile(joinpath(store_root, "auth-directory.json"))
end

@testset "Gateway OIDC JWKS Rotation" begin
    store_root = mktempdir()
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    state = foundation_state(foundation_path; store_root = store_root)
    jwks_path = joinpath(store_root, "jwks.json")
    discovery_path = joinpath(store_root, "openid-configuration.json")

    write(
        discovery_path,
        JSON3.write(Dict("issuer" => "https://issuer.test", "jwks_uri" => jwks_path)),
    )
    write(jwks_path, JSON3.write(Dict("keys" => [test_oct_jwk("kid-old", "old-secret")])) )

    claims = Dict{String,Any}(
        "iss" => "https://issuer.test",
        "aud" => "juliaflow-gateway",
        "sub" => "user-owner",
        "juliaflow_workspace" => "workspace-a",
        "juliaflow_role" => "owner",
        "exp" => 4102444800,
    )
    old_token = test_hs256_jwt(claims; secret = "old-secret", kid = "kid-old")
    new_token = test_hs256_jwt(claims; secret = "new-secret", kid = "kid-new")

    env_pairs = (
        "JULIAFLOW_AUTH_MODE" => "oidc",
        "JULIAFLOW_OIDC_DISCOVERY_PATH" => discovery_path,
        "JULIAFLOW_OIDC_AUDIENCE" => "juliaflow-gateway",
        "JULIAFLOW_OIDC_ALLOWED_ALGORITHMS" => "HS256",
    )

    old_key_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(old_token)"]))
    end
    missing_key_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(new_token)"]))
    end

    write(jwks_path, JSON3.write(Dict("keys" => [test_oct_jwk("kid-new", "new-secret")])) )

    rotated_old_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(old_token)"]))
    end
    rotated_new_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(new_token)"]))
    end

    @test old_key_response.status == 200
    @test missing_key_response.status == 401
    @test occursin("OIDC JWKS key not found: kid-new", String(missing_key_response.body))
    @test rotated_old_response.status == 401
    @test occursin("OIDC JWKS key not found: kid-old", String(rotated_old_response.body))
    @test rotated_new_response.status == 200
end

@testset "Gateway OIDC RS256 JWKS" begin
    store_root = mktempdir()
    foundation_path = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
    state = foundation_state(foundation_path; store_root = store_root)
    jwks_path = joinpath(store_root, "jwks-rs256.json")
    discovery_path = joinpath(store_root, "openid-configuration-rs256.json")

    rsa_modulus = "kuIo4j5IbOMTRjVQWeMj6N6SyIF2Q9yLuGvmhZquzGGF9YubMVj9NPlRUk2vsB6pHd-FOE1WANIgdduQUkdJCJYuIWcQ1yV039DFdJs7IwkcSOCrA70ML7MItFupK2eV6D7llqgZoOG2n1Xfa5EATUZtqVHGoprYXMhgFatDXq5_6Ssl8tRrpoS2Gwzu6DPFDtZWnu598BzFLsKFYmNyk5UTKT6l76T79HuzGdiienfHp-Rq-IgEN3TJtVQgxAZclDfoHEHbTAGaLfHbAGC-wXmviRY9sNkhnDivoU0X6_tY44GzkQXe_5BX2xAjZAGqHckTsvwGzVI9MAWdZGq8YQ"
    rsa_exponent = "AQAB"
    rs256_token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6InJzYS1saXZlLXRlc3QifQ.eyJpc3MiOiJodHRwczovL2lzc3Vlci50ZXN0IiwiYXVkIjoianVsaWFmbG93LWdhdGV3YXkiLCJzdWIiOiJ1c2VyLW93bmVyIiwianVsaWFmbG93X3dvcmtzcGFjZSI6IndvcmtzcGFjZS1hIiwianVsaWFmbG93X3JvbGUiOiJvd25lciIsImV4cCI6NDEwMjQ0NDgwMH0.VxYxaMFtZ4INHQBa8oat21Q5q5oTT-Eqb8lvqBlvIyFqlVuJ2XZjCUQMq0JioA7PsPrCvWcavFkFOBNYavrtvMfGKCQnB29hy_AonuUriwtIP6JxFBhtl6M_2pQiQb_qjKah-j3OVw-BKmOiB3NLAku9cWHdIURz-altxrINzkiYqvfGaQciznCz4xjiv6Is2r28IDSCFIksQeMcYYOmkDgs_QCklwISt4r69A1TEL3QrYjnW7--oU9W2MsuBjqahtN5oJejyeFBEPHqUx6cWIrRRdh_UAQWSe-aPYIDBJiPJW2aiF898DNMr99aOf1er_LAq1b1DCMORes-A9O4YQ"
    tampered_token = string(rs256_token[1:end-2], "xx")

    write(
        discovery_path,
        JSON3.write(Dict("issuer" => "https://issuer.test", "jwks_uri" => jwks_path)),
    )
    write(
        jwks_path,
        JSON3.write(
            Dict(
                "keys" => [
                    Dict(
                        "kty" => "RSA",
                        "kid" => "rsa-live-test",
                        "alg" => "RS256",
                        "use" => "sig",
                        "n" => rsa_modulus,
                        "e" => rsa_exponent,
                    ),
                ],
            ),
        ),
    )

    env_pairs = (
        "JULIAFLOW_AUTH_MODE" => "oidc",
        "JULIAFLOW_OIDC_DISCOVERY_PATH" => discovery_path,
        "JULIAFLOW_OIDC_AUDIENCE" => "juliaflow-gateway",
        "JULIAFLOW_OIDC_ALLOWED_ALGORITHMS" => "RS256",
    )

    valid_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(rs256_token)"]))
    end
    tampered_response = withenv(env_pairs...) do
        route_request(state, HTTP.Request("GET", "/api/v1/workflows", ["Authorization" => "Bearer $(tampered_token)"]))
    end

    @test valid_response.status == 200
    @test occursin("wf-foundation", String(valid_response.body))
    @test tampered_response.status == 401
    @test occursin("invalid OIDC token signature", String(tampered_response.body))
end
