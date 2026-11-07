module JuliaFlowMonorepo

include(joinpath(@__DIR__, "..", "services", "node-sdk", "src", "JuliaFlowNodeSDK.jl"))
include(joinpath(@__DIR__, "..", "services", "execution-service", "src", "JuliaFlowExecutionService.jl"))
include(joinpath(@__DIR__, "..", "services", "worker-service", "src", "JuliaFlowWorkerService.jl"))
include(joinpath(@__DIR__, "..", "services", "api-gateway", "src", "JuliaFlowGatewayRepository.jl"))
include(joinpath(@__DIR__, "..", "services", "api-gateway", "src", "JuliaFlowApiGateway.jl"))
# Cache the request dispatcher during dependency preparation, before the local
# launcher's readiness deadline starts. This compiles code without running a
# request, creating appliance state, or opening a listener.
precompile(JuliaFlowApiGateway.route_request,
    (JuliaFlowApiGateway.GatewayState, JuliaFlowApiGateway.HTTP.Request))

end
