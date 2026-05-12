#!/usr/bin/env julia
include(joinpath(@__DIR__, "..", "services", "execution-service", "src", "JuliaFlowExecutionService.jl"))
using .JuliaFlowExecutionService
using .JuliaFlowExecutionService.JuliaFlowNodeSDK: PortSchema
using Dates
using JSON3

function tiny_workflow()
    node = WorkflowNode(
        id = "node-dispatch",
        name = "Dispatch Probe",
        type = "JuliaFlow.Base.Noop",
        execution_hint = :cpu_only,
        capabilities = NodeCapability(execution_mode = :batch, resource_class = :cpu),
        config = Dict{String,Any}(),
        ports = [PortSchema(id = "out", direction = :output, type = :data_table)],
    )
    return WorkflowDefinition(
        id = "wf-dispatch-bench",
        name = "Dispatch Bench",
        version = "0.1.0",
        nodes = [node],
        connections = WorkflowConnection[],
    )
end

iterations = parse(Int, get(ENV, "JULIAFLOW_DISPATCH_BENCH_ITERATIONS", "1000"))
threshold_ms = parse(Float64, get(ENV, "JULIAFLOW_DISPATCH_BENCH_THRESHOLD_MS", "5.0"))
workflow = tiny_workflow()
serialize_job_spec(workflow)
started = time_ns()
for _ in 1:iterations
    serialize_job_spec(workflow)
end
elapsed_ms = (time_ns() - started) / 1_000_000
avg_ms = elapsed_ms / iterations
result = Dict(
    "iterations" => iterations,
    "elapsedMs" => round(elapsed_ms; digits = 3),
    "avgDispatchMs" => round(avg_ms; digits = 6),
    "thresholdMs" => threshold_ms,
    "passed" => avg_ms <= threshold_ms,
)
println(JSON3.write(result))
result["passed"] || exit(1)
