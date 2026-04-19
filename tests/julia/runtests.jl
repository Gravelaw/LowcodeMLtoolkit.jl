using Test
using HTTP
using JSON3
using TOML

include(joinpath(@__DIR__, "..", "..", "services", "node-sdk", "src", "JuliaFlowNodeSDK.jl"))
include(joinpath(@__DIR__, "..", "..", "services", "execution-service", "src", "JuliaFlowExecutionService.jl"))
include(joinpath(@__DIR__, "..", "..", "services", "api-gateway", "src", "JuliaFlowApiGateway.jl"))
include(joinpath(@__DIR__, "..", "..", "extensions", "base", "src", "JuliaFlowBaseExtension.jl"))

using .JuliaFlowNodeSDK
using .JuliaFlowExecutionService
using .JuliaFlowApiGateway
using .JuliaFlowBaseExtension

include(joinpath(@__DIR__, "repository_contract_tests.jl"))

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
    workflow = load_workflow_definition(foundation_path)
    parallel_workflow = load_workflow_definition(parallel_path)
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
    @test result["mode"] == "cpu_only"
    @test execute_with_flow_variables["flow_variables"]["JULIAFLOW_GPU_DEVICE"] == "nvidia:0"
    @test execute_with_flow_variables["requested_execution_mode"] == "gpu_preferred"
    @test execute_with_flow_variables["status_history"][1]["at"] isa AbstractString
    @test spec["stages"][2] == ["node-left", "node-right"]
    @test spec["checkpoint_tag"] == "cp/01-contracts-frozen"
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
                "nodes" => [
                    Dict(
                        "id" => "node-source",
                        "type" => "JuliaFlow.Base.CSVReader",
                        "name" => "CSV Reader",
                        "executionHint" => "cpu_only",
                        "ports" => [Dict("id" => "out", "direction" => "output", "type" => "data_table")],
                        "config" => Dict("path" => "assets/sample.csv"),
                    ),
                    Dict(
                        "id" => "node-transform",
                        "type" => "JuliaFlow.Base.ColumnSelect",
                        "name" => "Column Select",
                        "executionHint" => "cpu_only",
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

        @test occursin("\"status\":\"ok\"", healthcheck(state))
        @test occursin("wf-foundation", list_workflows_response(state))
        @test occursin("\"nodeCount\":3", get_workflow_response(state, "wf-foundation"))
        @test occursin("\"nodes\":[", get_workflow_response(state, "wf-foundation"))
        @test occursin("\"connections\":[", get_workflow_response(state, "wf-foundation"))
        execution_json = execution_accept_response(state, "wf-foundation")
        accepted_execution = JSON3.read(execution_json, Dict{String,Any})
        @test occursin("\"accepted\"", execution_json)
        @test occursin("\"executionId\":", execution_json)
        @test occursin("\"mode\":\"cpu_only\"", execution_json)
        @test occursin("\"statusHistory\":[", execution_json)
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
        json_update = JuliaFlowApiGateway.update_workflow_response_from_body!(state, "wf-foundation", foundation_workflow_payload)
        @test occursin("\"status\":\"updated\"", json_update)
        json_updated_workflow = JSON3.read(get_workflow_response(state, "wf-foundation"), Dict{String,Any})
        @test json_updated_workflow["name"] == "Foundation JSON Save"
        @test length(json_updated_workflow["flowVariables"]) == 2
        @test json_updated_workflow["flowVariables"][2]["name"] == "BATCH_WINDOW"
        persisted_workflow = TOML.parse(read(joinpath(store_root, "workflows", "wf-foundation.toml"), String))
        @test persisted_workflow["flow_variables"][2]["default"] == "2026-Q2"
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
        @test list_response.status == 200
        @test occursin("wf-foundation", String(list_response.body))
        @test detail_response.status == 200
        @test occursin("\"workflowId\":\"wf-foundation\"", String(detail_response.body))
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

    mktempdir() do store_root
        state = foundation_state(foundation_path; store_root = store_root)
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
        execute_event = JSON3.read(execute_notifications[1], Dict{String,Any})
        execute_state_event = JSON3.read(execute_notifications[2], Dict{String,Any})

        @test execute_reply["result"]["status"] == "accepted"
        @test execute_reply["result"]["jobId"] isa AbstractString
        @test execute_event["method"] == "workflow.state.changed"
        @test execute_state_event["method"] == "execution.state.changed"
        @test execute_state_event["params"]["executionId"] == execute_reply["result"]["jobId"]
        execution_record = JSON3.read(execution_detail_response(state, execute_reply["result"]["jobId"]), Dict{String,Any})
        @test execution_record["requested_execution_mode"] == "cpu_only"
        @test execution_record["flow_variables"]["JULIAFLOW_GPU_DEVICE"] == "cpu-fallback"
    end
end

@testset "Base Extension" begin
    @test haskey(available_nodes(), DEFAULT_NODE_KEY)
    result = execute_passthrough("memory://foundation.arrow")
    @test result.outputs[DEFAULT_OUTPUT_PORT_ID].ref == "memory://foundation.arrow"
end
