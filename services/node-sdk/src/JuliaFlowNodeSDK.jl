module JuliaFlowNodeSDK

using Dates
using UUIDs

export PortSchema,
    NodeConfig,
    NodeContext,
    NodeResult,
    AbstractNode,
    ExecutionDevice,
    CpuDevice,
    GpuDevice,
    validate_arrow_boundary,
    validate_port_type

const PORT_TYPES = Set([
    :data_table,
    :model,
    :flow_variable,
    :image,
    :stream_channel,
    :gpu_buffer,
])

abstract type ExecutionDevice end
struct CpuDevice <: ExecutionDevice
    pool::String
end
struct GpuDevice <: ExecutionDevice
    vendor::String
    device_id::String
end

Base.@kwdef struct PortSchema
    id::String
    direction::Symbol
    type::Symbol
    label::String = id
end

Base.@kwdef struct NodeConfig
    values::Dict{String,Any} = Dict{String,Any}()
end

Base.@kwdef struct NodeContext
    workflow_id::UUID
    execution_id::UUID
    node_id::UUID
    inputs::Dict{String,NamedTuple} = Dict{String,NamedTuple}()
    config::NodeConfig = NodeConfig()
    device::ExecutionDevice = CpuDevice("default")
    metadata::Dict{String,Any} = Dict{String,Any}()
    started_at::DateTime = now(UTC)
end

Base.@kwdef struct NodeResult
    outputs::Dict{String,NamedTuple} = Dict{String,NamedTuple}()
    telemetry::Dict{String,Any} = Dict{String,Any}()
    warnings::Vector{String} = String[]
end

abstract type AbstractNode end

function validate_port_type(port_type::Symbol)
    port_type in PORT_TYPES || error("unsupported port type: $(port_type)")
    return true
end

function validate_arrow_boundary(payload::NamedTuple)
    haskey(payload, :format) || error("payload missing format field")
    payload.format == :arrow_ipc || error("payload format must be :arrow_ipc")
    return true
end

function configure(::Type{T}, params::Dict{String,Any}) where {T<:AbstractNode}
    return NodeConfig(copy(params))
end

function infer_output_schema(::Type{T}, input_schemas::Vector{PortSchema}) where {T<:AbstractNode}
    return input_schemas
end

function execute(::Type{T}, ::NodeContext) where {T<:AbstractNode}
    error("node execute not implemented")
end

function on_stream_event(::Type{T}, event, state, ::NodeContext) where {T<:AbstractNode}
    return (event, state)
end

end

