using JSON3

include(joinpath(@__DIR__, "..", "services", "worker-service", "src", "JuliaFlowWorkerService.jl"))

registry = JuliaFlowWorkerService.gpu_registry_health(; probe = true)
disk = try
    stats = diskstat(pwd())
    Dict("status" => "measured", "freeBytes" => Int(stats.bavail) * Int(stats.bsize))
catch
    Dict("status" => "unavailable", "freeBytes" => nothing)
end
devices = [
    Dict(
        "deviceId" => device["device_id"],
        "name" => device["name"],
        "memoryBytes" => device["memory_bytes"],
        "freeMemoryBytes" => get(device, "free_memory_bytes", nothing),
        "probeStatus" => device["probe_status"],
        "probeReason" => device["probe_reason"],
        "runtimeVersion" => get(device, "runtime_version", nothing),
        "driverVersion" => get(device, "driver_version", nothing),
    )
    for device in registry["devices"]
    if get(device, "mode", "") == "hardware"
]
result = Dict(
    "status" => registry["probe_status"],
    "reason" => registry["probe_reason"],
    "usableDeviceCount" => registry["device_count"],
    "visibleDeviceCount" => registry["visible_device_count"],
    "simulatedDeviceCount" => registry["simulated_device_count"],
    "devices" => devices,
    "juliaVersion" => string(VERSION),
    "platform" => string(Sys.KERNEL),
    "cpuThreads" => Sys.CPU_THREADS,
    "juliaThreads" => Threads.nthreads(),
    "totalMemoryBytes" => Int(Sys.total_memory()),
    "freeMemoryBytes" => Int(Sys.free_memory()),
    "disk" => disk,
)
println(JSON3.write(result))
if get(ENV, "JULIAFLOW_REQUIRE_CUDA_PROBE", "0") == "1" && registry["device_count"] < 1
    error("required physical CUDA operation probe did not pass")
end
