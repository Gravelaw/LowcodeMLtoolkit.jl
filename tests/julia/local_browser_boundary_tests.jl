withenv("JULIAFLOW_RUNTIME_MODE" => "local-appliance", "JULIAFLOW_AUTH_MODE" => "required",
    "JULIAFLOW_DEV_AUTH_TOKEN" => "boundary-test-token", "JULIAFLOW_CORS_ALLOW_ORIGIN" => nothing,
    "JULIAFLOW_LOCAL_FRONTEND_URL" => "http://127.0.0.1:5173") do
    mktempdir() do store
        state = foundation_state(joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml"); store_root = store)
        request_for = function(id; origin = "http://127.0.0.1:5173", token = "boundary-test-token")
            headers = ["Content-Type" => "application/json"]
            origin === nothing || push!(headers, "Origin" => origin)
            token === nothing || push!(headers, "Authorization" => "Bearer $(token)")
            HTTP.Request("POST", "/api/v1/data-science-projects", headers, JSON3.write(Dict("projectId" => id, "name" => id)))
        end
        for (origin, token, status) in [("https://evil.example", "boundary-test-token", 403), ("null", "boundary-test-token", 403), ("http://127.0.0.1:5173", nothing, 401), ("http://127.0.0.1:5173", "wrong", 401)]
            before = length(state.data_science_projects)
            response = route_request(state, request_for("rejected"; origin, token))
            @test response.status == status
            @test length(state.data_science_projects) == before
        end
        for mode in ("disabled", "dev_token", "required")
            withenv("JULIAFLOW_AUTH_MODE" => mode, "JULIAFLOW_DEV_AUTH_TOKEN" => " ") do
                @test route_request(state, request_for("no-fallback")).status == 401
            end
        end
        withenv("JULIAFLOW_CORS_ALLOW_ORIGIN" => "*") do
            @test route_request(state, request_for("wildcard"; origin = "https://evil.example")).status == 403
        end
        @test route_request(state, request_for("authorized-cli"; origin = nothing)).status == 201
        withenv("JULIAFLOW_CORS_ALLOW_ORIGIN" => "http://127.0.0.1:5173,http://localhost:5173") do
            response = route_request(state, request_for("authorized-browser"; origin = "http://localhost:5173"))
            @test response.status == 201
            @test HTTP.header(response, "Access-Control-Allow-Origin") == "http://localhost:5173"
            @test HTTP.header(response, "Vary") == "Origin"
        end
        for role in ("viewer", "editor", "owner")
            request = HTTP.Request("POST", "/api/v1/local-backups", ["Authorization" => "Bearer boundary-test-token", "X-JuliaFlow-Workspace-Role" => role, "Content-Type" => "application/json"], "{}")
            @test route_request(state, request).status == (role == "owner" ? 200 : 403)
        end
        rpc = JSON3.write(Dict("jsonrpc" => "2.0", "id" => 1, "method" => "workflow.execute", "params" => Dict("workflowId" => "wf-foundation")))
        viewer = HTTP.Request("GET", "/api/v1/realtime", ["Authorization" => "Bearer boundary-test-token", "X-JuliaFlow-Workspace-Role" => "viewer"])
        before = length(state.executions)
        response, _ = JuliaFlowApiGateway.handle_realtime_request!(state, rpc; auth_request = viewer)
        @test occursin("permission denied", response)
        @test length(state.executions) == before
        response, _ = JuliaFlowApiGateway.handle_realtime_request!(state, rpc)
        @test occursin("invalid auth token", response)
        @test length(state.executions) == before
        subscribe = JSON3.write(Dict("jsonrpc" => "2.0", "id" => 2, "method" => "canvas.subscribe", "params" => Dict("workflowId" => "wf-foundation")))
        response, _ = JuliaFlowApiGateway.handle_realtime_request!(state, subscribe; auth_request = viewer)
        @test haskey(JSON3.read(response, Dict{String,Any}), "result")
        owner = HTTP.Request("GET", "/api/v1/realtime", ["Authorization" => "Bearer boundary-test-token"])
        response, _ = JuliaFlowApiGateway.handle_realtime_request!(state, rpc; auth_request = owner)
        @test haskey(JSON3.read(response, Dict{String,Any}), "result")
        repository = JuliaFlowApiGateway.JuliaFlowGatewayRepository
        policy = repository.gateway_auth_policy(Dict("resourcePolicies" => [Dict(
            "resourceType" => "dashboard", "resourceId" => "dashboard-foundation", "workspaceId" => "local-dev",
            "permissionsByRole" => Dict("viewer" => String[], "owner" => ["dashboard:read"]))]))
        repository.save_auth_policy!(state.repository, policy)
        dashboard_rpc = JSON3.write(Dict("jsonrpc" => "2.0", "id" => 3, "method" => "dashboard.subscribe", "params" => Dict("dashboardId" => "dashboard-foundation")))
        response, notifications = JuliaFlowApiGateway.handle_realtime_request!(state, dashboard_rpc; auth_request = viewer)
        @test occursin("permission denied", response)
        @test isempty(notifications)
        response, notifications = JuliaFlowApiGateway.handle_realtime_request!(state, dashboard_rpc; auth_request = owner)
        @test haskey(JSON3.read(response, Dict{String,Any}), "result")
        @test !isempty(notifications)
        encoded = replace(replace(rstrip(base64encode("boundary-test-token"), '='), '+' => '-'), '/' => '_')
        protocol_request = HTTP.Request("GET", "/api/v1/realtime", ["Sec-WebSocket-Protocol" => "juliaflow, juliaflow.bearer.$(encoded)"])
        authenticated = JuliaFlowApiGateway.realtime_auth_request(protocol_request)
        @test JuliaFlowApiGateway.bearer_token_from_request(authenticated) == "boundary-test-token"
        @test !HTTP.hasheader(authenticated, "Sec-WebSocket-Protocol")
        for protocol in ("juliaflow.bearer.", "juliaflow.bearer.!!!!", "juliaflow.bearer.$(encoded),juliaflow.bearer.$(encoded)")
            @test_throws ErrorException JuliaFlowApiGateway.realtime_auth_request(HTTP.Request("GET", "/api/v1/realtime", ["Sec-WebSocket-Protocol" => protocol]))
        end
        @test_throws ErrorException JuliaFlowApiGateway.realtime_auth_request(HTTP.Request("GET", "/api/v1/realtime", ["Authorization" => "Bearer wrong", "Sec-WebSocket-Protocol" => "juliaflow.bearer.$(encoded)"]))
    end
end
withenv("JULIAFLOW_RUNTIME_MODE" => "development", "JULIAFLOW_AUTH_MODE" => "disabled", "JULIAFLOW_CORS_ALLOW_ORIGIN" => "*") do
    @test JuliaFlowApiGateway.auth_context_payload(HTTP.Request("GET", "/"))["role"] == "owner"
    @test JuliaFlowApiGateway.validate_cors_origin!(HTTP.Request("GET", "/", ["Origin" => "https://demo.example"])) === nothing
end
