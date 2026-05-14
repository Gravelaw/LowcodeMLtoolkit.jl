include(joinpath(@__DIR__, "..", "services", "execution-service", "src", "JuliaFlowExecutionService.jl"))

using .JuliaFlowExecutionService
using HTTP

host = get(ENV, "JULIAFLOW_EXECUTION_HOST", "0.0.0.0")
port = parse(Int, get(ENV, "JULIAFLOW_EXECUTION_PORT", "8090"))

function execution_service_response(request::HTTP.Request)
    path = HTTP.URI(request.target).path
    if request.method == "GET" && path == "/health"
        return HTTP.Response(200, ["Content-Type" => "application/json"], "{\"status\":\"ok\",\"service\":\"execution-service\"}")
    elseif request.method == "GET" && path == "/metrics"
        body = "# HELP juliaflow_execution_service_up Execution service health.\n# TYPE juliaflow_execution_service_up gauge\njuliaflow_execution_service_up 1\n"
        return HTTP.Response(200, ["Content-Type" => "text/plain; version=0.0.4"], body)
    end
    return HTTP.Response(404, ["Content-Type" => "application/json"], "{\"error\":\"not_found\"}")
end

println("JuliaFlow execution service serving on http://$(host):$(port)")
HTTP.serve(execution_service_response, host, port; verbose = false)
