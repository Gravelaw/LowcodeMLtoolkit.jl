module JuliaFlowMonorepo

include(joinpath(@__DIR__, "..", "services", "node-sdk", "src", "JuliaFlowNodeSDK.jl"))
include(joinpath(@__DIR__, "..", "services", "execution-service", "src", "JuliaFlowExecutionService.jl"))
include(joinpath(@__DIR__, "..", "services", "api-gateway", "src", "JuliaFlowGatewayRepository.jl"))
include(joinpath(@__DIR__, "..", "services", "api-gateway", "src", "JuliaFlowApiGateway.jl"))

end
