using JSON3
using Test

if get(ENV, "JULIAFLOW_CUDA_SMOKE", "0") != "1"
    println(JSON3.write(Dict("status" => "skipped", "reason" => "set JULIAFLOW_CUDA_SMOKE=1")))
    exit(0)
end

try
    @eval using CUDA
    @eval using KernelAbstractions
catch err
    println(JSON3.write(Dict("status" => "failed", "reason" => "CUDA/KernelAbstractions packages are not installed", "error" => sprint(showerror, err))))
    exit(2)
end

CUDA.functional() || error("CUDA runtime is not functional")
devices = collect(CUDA.devices())
device_count = length(devices)
require_multi = get(ENV, "JULIAFLOW_REQUIRE_MULTI_GPU", "0") == "1"
if require_multi && device_count < 2
    error("multi-GPU smoke requires at least 2 visible CUDA devices; found $(device_count)")
end

@kernel function affine_kernel!(output, input)
    index = @index(Global)
    output[index] = input[index] * 2.0f0 + 1.0f0
end

input = CUDA.CuArray(Float32[1, 2, 3, 4, 5, 6, 7, 8])
output = similar(input)
backend = CUDABackend()
kernel! = affine_kernel!(backend, 64)
kernel!(output, input; ndrange = length(input))
KernelAbstractions.synchronize(backend)
result = Array(output)
@test result == Float32[3, 5, 7, 9, 11, 13, 15, 17]

println(JSON3.write(Dict(
    "status" => "passed",
    "backend" => string(backend),
    "deviceCount" => device_count,
    "requireMultiGpu" => require_multi,
    "selectedDevice" => string(CUDA.device()),
    "inputSize" => length(input),
    "sum" => sum(result),
)))
