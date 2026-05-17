module JuliaFlowGatewayRepository

include(joinpath(@__DIR__, "..", "..", "execution-service", "src", "JuliaFlowExecutionService.jl"))

using .JuliaFlowExecutionService
using Dates
using JSON3
using LibPQ
using UUIDs

export GatewayCheckpoint,
    GatewayExecution,
    GatewayEvent,
    GatewayRoleBinding,
    GatewayResourcePolicy,
    GatewayAuthPolicy,
    GatewayUserRecord,
    GatewayWorkspaceRecord,
    GatewayAuthDirectory,
    HubExtensionRecord,
    PublishedDashboardRecord,
    AbstractGatewayRepository,
    FileGatewayRepository,
    PostgreSQLGatewayRepository,
    ensure_repository!,
    load_workflows,
    load_checkpoints,
    load_executions,
    load_events,
    load_auth_policy,
    load_auth_directory,
    load_hub_extensions,
    load_published_dashboards,
    save_workflow!,
    save_checkpoint!,
    save_execution!,
    save_auth_policy!,
    save_auth_directory!,
    save_hub_extension!,
    save_published_dashboard!,
    append_event!,
    list_events_after,
    load_consumer_cursor,
    save_consumer_cursor!,
    create_postgres_schema!,
    load_repository

Base.@kwdef mutable struct GatewayCheckpoint
    tag::String
    summary::String
    created_at::String
end

Base.@kwdef mutable struct GatewayExecution
    execution_id::String
    workflow_id::String
    workflow_version::String
    checkpoint_tag::String
    status::String
    mode::String
    plan::Vector{String}
    stages::Vector{Vector{String}}
    node_count::Int
    connection_count::Int
    created_at::String
    updated_at::String = created_at
    status_history::Vector{Dict{String,Any}} = Dict{String,Any}[]
    queued_at::Union{Nothing,String} = nothing
    started_at::Union{Nothing,String} = nothing
    finished_at::Union{Nothing,String} = nothing
    metadata::Dict{String,Any} = Dict{String,Any}()
end

Base.@kwdef mutable struct GatewayEvent
    event_id::String
    event_type::String
    aggregate_type::String
    aggregate_id::String
    occurred_at::String
    sequence::Int
    producer::String
    payload_version::Int = 1
    payload::Dict{String,Any} = Dict{String,Any}()
end

Base.@kwdef mutable struct GatewayRoleBinding
    principal_id::String
    workspace_id::String
    role::String
end

Base.@kwdef mutable struct GatewayResourcePolicy
    resource_type::String
    resource_id::String
    workspace_id::String
    permissions_by_role::Dict{String,Vector{String}} = Dict{String,Vector{String}}()
end

Base.@kwdef mutable struct GatewayAuthPolicy
    role_bindings::Vector{GatewayRoleBinding} = GatewayRoleBinding[]
    resource_policies::Vector{GatewayResourcePolicy} = GatewayResourcePolicy[]
    updated_at::String = JuliaFlowExecutionService.iso8601_timestamp()
end

Base.@kwdef mutable struct GatewayUserRecord
    principal_id::String
    display_name::String
    email::Union{Nothing,String} = nothing
    active::Bool = true
    created_at::String = JuliaFlowExecutionService.iso8601_timestamp()
    updated_at::String = created_at
end

Base.@kwdef mutable struct GatewayWorkspaceRecord
    workspace_id::String
    name::String
    active::Bool = true
    created_at::String = JuliaFlowExecutionService.iso8601_timestamp()
    updated_at::String = created_at
end

Base.@kwdef mutable struct GatewayAuthDirectory
    users::Vector{GatewayUserRecord} = GatewayUserRecord[]
    workspaces::Vector{GatewayWorkspaceRecord} = GatewayWorkspaceRecord[]
    updated_at::String = JuliaFlowExecutionService.iso8601_timestamp()
end

function hub_verification_check(status::AbstractString, details::AbstractString; blockers::Vector{String} = String[])
    return Dict{String,Any}(
        "status" => String(status),
        "details" => String(details),
        "blockers" => blockers,
        "checkedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
    )
end

function hub_verification_default()
    timestamp = JuliaFlowExecutionService.iso8601_timestamp()
    return Dict{String,Any}(
        "verified" => false,
        "sandbox" => hub_verification_check("pending", "Compatibility sandbox has not been evaluated yet"),
        "artifacts" => hub_verification_check("pending", "Artifact hashes have not been verified yet"),
        "mirrors" => hub_verification_check("pending", "Mirror references have not been verified yet"),
        "blockers" => String[],
        "evaluatedAt" => timestamp,
    )
end

Base.@kwdef mutable struct HubExtensionRecord
    extension_id::String
    name::String
    version::String
    publisher::String
    summary::String
    package_ref::String
    tags::Vector{String} = String[]
    engine_compatibility::String = "alpha-core"
    required_contract_version::String = "0.1.0"
    supported_checkpoints::Vector{String} = String[]
    compatible_checkpoints::Vector{String} = String[]
    dependencies::Vector{String} = String[]
    publisher_identity::String = "unknown"
    artifact_hashes::Dict{String,String} = Dict{String,String}()
    compatibility_sandbox_command::Union{Nothing,String} = nothing
    mirror_refs::Vector{String} = String[]
    signature::Union{Nothing,String} = nothing
    release_notes_ref::Union{Nothing,String} = nothing
    install_state::String = "available"
    compatibility::Dict{String,Any} = Dict(
        "compatible" => true,
        "warnings" => String[],
        "blockers" => String[],
        "evaluatedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
    )
    trust::Dict{String,Any} = Dict(
        "trusted" => false,
        "level" => "untrusted",
        "warnings" => String[],
        "blockers" => String[],
        "evaluatedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
    )
    upgrade::Dict{String,Any} = Dict(
        "upgradeAvailable" => false,
        "latestVersion" => version,
        "evaluatedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
    )
    verification::Dict{String,Any} = hub_verification_default()
    installed_version::Union{Nothing,String} = nothing
    installed_at::Union{Nothing,String} = nothing
    enabled_at::Union{Nothing,String} = nothing
end

Base.@kwdef mutable struct PublishedDashboardRecord
    dashboard_id::String
    workflow_id::String
    name::String
    version::Int
    published_at::String
    visibility::String = "workspace"
    share_token::Union{Nothing,String} = nothing
    binding::Dict{String,Any}
    charts::Vector{Dict{String,Any}} = Dict{String,Any}[]
    datasets::Dict{String,Vector{Dict{String,Any}}} = Dict{String,Vector{Dict{String,Any}}}()
end

abstract type AbstractGatewayRepository end

Base.@kwdef struct FileGatewayRepository <: AbstractGatewayRepository
    root::String
end

Base.@kwdef struct PostgreSQLGatewayRepository <: AbstractGatewayRepository
    connection_string::String
    schema::String = "public"
end

function workflow_metadata_payload(workflow::WorkflowDefinition)
    payload = Dict(
        "workflowId" => workflow.id,
        "name" => workflow.name,
        "version" => workflow.version,
        "nodeCount" => length(workflow.nodes),
        "connectionCount" => length(workflow.connections),
        "flowVariableCount" => length(workflow.flow_variables),
        "biOutletCount" => length(workflow.bi_outlets),
        "dashboardCount" => length(workflow.dashboards),
        "runMode" => String(workflow.runtime.run_mode),
    )
    workflow.graph === nothing || (payload["graphRevision"] = workflow.graph.revision)
    return payload
end

function port_payload(port)
    return Dict(
        "id" => port.id,
        "direction" => String(port.direction),
        "type" => String(port.type),
        "label" => port.label,
    )
end

function node_payload(node::WorkflowNode)
    payload = Dict{String,Any}(
        "id" => node.id,
        "type" => node.type,
        "name" => node.name,
        "executionHint" => String(node.execution_hint),
        "ports" => [port_payload(port) for port in node.ports],
        "config" => node.config,
    )
    isempty(get(node.config, "gpuDevicePreference", "")) || nothing
    node.execution_hint == :gpu_preferred || node.execution_hint == :gpu_required || return payload
    if haskey(node.config, "gpuDevicePreference")
        payload["gpuDevicePreference"] = node.config["gpuDevicePreference"]
    end
    if node.capabilities !== nothing
        payload["capabilities"] = Dict(
            "executionMode" => String(node.capabilities.execution_mode),
            "resourceClass" => String(node.capabilities.resource_class),
        )
        node.capabilities.accelerator === nothing || (payload["capabilities"]["accelerator"] = node.capabilities.accelerator)
        node.capabilities.worker_pool === nothing || (payload["capabilities"]["workerPool"] = node.capabilities.worker_pool)
    end
    return payload
end

function connection_payload(connection::WorkflowConnection)
    payload = Dict(
        "sourceNodeId" => connection.source_node_id,
        "sourcePortId" => connection.source_port_id,
        "targetNodeId" => connection.target_node_id,
        "targetPortId" => connection.target_port_id,
        "dataType" => String(connection.data_type),
    )
    connection.label === nothing || (payload["label"] = connection.label)
    return payload
end

function graph_payload(graph::WorkflowGraph)
    payload = Dict{String,Any}(
        "revision" => graph.revision,
        "nodeLayouts" => [
            Dict{String,Any}(
                "nodeId" => layout.node_id,
                "x" => layout.x,
                "y" => layout.y,
            ) for layout in graph.node_layouts
        ],
    )
    graph.viewport === nothing || (payload["viewport"] = graph.viewport)
    graph.selected_node_id === nothing || (payload["selectedNodeId"] = graph.selected_node_id)
    for (index, layout) in enumerate(graph.node_layouts)
        layout.width === nothing || (payload["nodeLayouts"][index]["width"] = layout.width)
        layout.checkpoint_tag === nothing || (payload["nodeLayouts"][index]["checkpointTag"] = layout.checkpoint_tag)
        layout.notes === nothing || (payload["nodeLayouts"][index]["notes"] = layout.notes)
    end
    return payload
end

function container_payload(container::WorkflowContainer)
    return Dict{String,Any}(
        "containerId" => container.id,
        "name" => container.name,
        "nodeIds" => container.node_ids,
        "collapsed" => container.collapsed,
    )
end

function component_payload(component::WorkflowComponent)
    return Dict{String,Any}(
        "componentId" => component.id,
        "name" => component.name,
        "nodeIds" => component.node_ids,
        "version" => component.version,
        "flowVariableScope" => component.flow_variable_scope,
        "dashboardIds" => component.dashboard_ids,
    )
end

function control_flow_payload(control::WorkflowControlFlow)
    payload = Dict{String,Any}(
        "controlId" => control.id,
        "kind" => String(control.kind),
    )
    control.name === nothing || (payload["name"] = control.name)
    control.start_node_id === nothing || (payload["startNodeId"] = control.start_node_id)
    control.end_node_id === nothing || (payload["endNodeId"] = control.end_node_id)
    control.iteration_mode === nothing || (payload["iterationMode"] = String(control.iteration_mode))
    control.max_iterations === nothing || (payload["maxIterations"] = control.max_iterations)
    control.selector === nothing || (payload["selector"] = control.selector)
    isempty(control.cases) || (payload["cases"] = [
        Dict{String,Any}(
            "caseId" => String(get(item, "case_id", get(item, "caseId", ""))),
            "label" => String(get(item, "label", "")),
            "targetNodeId" => String(get(item, "target_node_id", get(item, "targetNodeId", ""))),
        ) for item in control.cases
    ])
    control.default_target_node_id === nothing || (payload["defaultTargetNodeId"] = control.default_target_node_id)
    isempty(control.try_node_ids) || (payload["tryNodeIds"] = control.try_node_ids)
    isempty(control.catch_node_ids) || (payload["catchNodeIds"] = control.catch_node_ids)
    control.source_node_id === nothing || (payload["sourceNodeId"] = control.source_node_id)
    control.target_node_id === nothing || (payload["targetNodeId"] = control.target_node_id)
    control.chunk_size === nothing || (payload["chunkSize"] = control.chunk_size)
    control.max_concurrency === nothing || (payload["maxConcurrency"] = control.max_concurrency)
    control.resource_class === nothing || (payload["resourceClass"] = String(control.resource_class))
    return payload
end

function dashboard_payload(dashboard::DashboardDefinition)
    payload = Dict{String,Any}(
        "dashboardId" => dashboard.id,
        "name" => dashboard.name,
        "binding" => Dict(
            "outletNodeId" => dashboard.binding.outlet_node_id,
            "datasetKey" => dashboard.binding.dataset_key,
            "refreshMode" => dashboard.binding.refresh_mode,
        ),
        "charts" => [
            Dict{String,Any}(
                "chartId" => chart.id,
                "title" => chart.title,
                "family" => chart.family,
            ) for chart in dashboard.charts
        ],
    )
    for (index, chart) in enumerate(dashboard.charts)
        chart.x_field === nothing || (payload["charts"][index]["xField"] = chart.x_field)
        chart.y_field === nothing || (payload["charts"][index]["yField"] = chart.y_field)
        chart.series_field === nothing || (payload["charts"][index]["seriesField"] = chart.series_field)
    end
    return payload
end

function runtime_payload(runtime::WorkflowRuntime)
    payload = Dict{String,Any}("runMode" => String(runtime.run_mode))
    runtime.source === nothing || (payload["source"] = runtime.source)
    runtime.window === nothing || (payload["window"] = runtime.window)
    runtime.policy === nothing || (payload["policy"] = runtime.policy)
    return payload
end

function workflow_detail_payload(workflow::WorkflowDefinition)
    payload = workflow_metadata_payload(workflow)
    payload["nodes"] = [node_payload(node) for node in workflow.nodes]
    payload["connections"] = [connection_payload(connection) for connection in workflow.connections]
    payload["flowVariables"] = [Dict{String,Any}(String(key) => value for (key, value) in pairs(variable)) for variable in workflow.flow_variables]
    payload["biOutlets"] = [Dict{String,Any}(String(key) => value for (key, value) in pairs(outlet)) for outlet in workflow.bi_outlets]
    workflow.graph === nothing || (payload["graph"] = graph_payload(workflow.graph))
    isempty(workflow.containers) || (payload["containers"] = [container_payload(container) for container in workflow.containers])
    isempty(workflow.components) || (payload["components"] = [component_payload(component) for component in workflow.components])
    isempty(workflow.control_flow) || (payload["controlFlow"] = [control_flow_payload(control) for control in workflow.control_flow])
    isempty(workflow.dashboards) || (payload["dashboards"] = [dashboard_payload(dashboard) for dashboard in workflow.dashboards])
    payload["runtime"] = runtime_payload(workflow.runtime)
    return payload
end

function checkpoint_payload(checkpoint::GatewayCheckpoint)
    return Dict(
        "tag" => checkpoint.tag,
        "summary" => checkpoint.summary,
        "createdAt" => checkpoint.created_at,
    )
end

function hub_extension_payload(extension::HubExtensionRecord)
    payload = Dict{String,Any}(
        "extensionId" => extension.extension_id,
        "manifest" => Dict{String,Any}(
            "extensionId" => extension.extension_id,
            "name" => extension.name,
            "version" => extension.version,
            "publisher" => extension.publisher,
            "summary" => extension.summary,
            "packageRef" => extension.package_ref,
            "tags" => extension.tags,
            "engineCompatibility" => extension.engine_compatibility,
            "requiredContractVersion" => extension.required_contract_version,
            "supportedCheckpoints" => extension.supported_checkpoints,
            "compatibleCheckpoints" => extension.compatible_checkpoints,
            "dependencies" => extension.dependencies,
            "publisherIdentity" => extension.publisher_identity,
            "artifactHashes" => extension.artifact_hashes,
            "mirrorRefs" => extension.mirror_refs,
        ),
        "installState" => extension.install_state,
        "compatibility" => extension.compatibility,
        "trust" => extension.trust,
        "upgrade" => extension.upgrade,
        "verification" => extension.verification,
    )
    extension.installed_version === nothing || (payload["installedVersion"] = extension.installed_version)
    extension.compatibility_sandbox_command === nothing || (payload["manifest"]["compatibilitySandboxCommand"] = extension.compatibility_sandbox_command)
    extension.signature === nothing || (payload["manifest"]["signature"] = extension.signature)
    extension.release_notes_ref === nothing || (payload["manifest"]["releaseNotesRef"] = extension.release_notes_ref)
    extension.installed_at === nothing || (payload["installedAt"] = extension.installed_at)
    extension.enabled_at === nothing || (payload["enabledAt"] = extension.enabled_at)
    return payload
end

function execution_payload(execution::GatewayExecution)
    payload = Dict(
        "executionId" => execution.execution_id,
        "workflowId" => execution.workflow_id,
        "workflowVersion" => execution.workflow_version,
        "checkpointTag" => execution.checkpoint_tag,
        "status" => execution.status,
        "mode" => execution.mode,
        "plan" => execution.plan,
        "stages" => execution.stages,
        "nodeCount" => execution.node_count,
        "connectionCount" => execution.connection_count,
        "createdAt" => execution.created_at,
        "updatedAt" => execution.updated_at,
        "statusHistory" => execution.status_history,
    )
    execution.queued_at === nothing || (payload["queuedAt"] = execution.queued_at)
    execution.started_at === nothing || (payload["startedAt"] = execution.started_at)
    execution.finished_at === nothing || (payload["finishedAt"] = execution.finished_at)
    if !isempty(execution.metadata)
        for (key, value) in pairs(execution.metadata)
            string_key = String(key)
            if string_key == "resource_plan"
                payload["resourcePlan"] = [
                    Dict(
                        "lane" => String(get(item, "lane", "")),
                        "nodeIds" => [String(node_id) for node_id in get(item, "node_ids", Any[])],
                    ) for item in value
                ]
            elseif string_key == "control_flow_plan"
                payload["controlFlowPlan"] = [
                    let
                        entry = Dict{String,Any}(
                            "controlId" => String(get(item, "control_id", "")),
                            "kind" => String(get(item, "kind", "")),
                            "bounded" => Bool(get(item, "bounded", false)),
                        )
                        haskey(item, "iteration_mode") && (entry["iterationMode"] = String(item["iteration_mode"]))
                        haskey(item, "max_iterations") && (entry["maxIterations"] = Int(item["max_iterations"]))
                        haskey(item, "start_node_id") && (entry["startNodeId"] = String(item["start_node_id"]))
                        haskey(item, "end_node_id") && (entry["endNodeId"] = String(item["end_node_id"]))
                        haskey(item, "body_node_ids") && (entry["bodyNodeIds"] = [String(node_id) for node_id in item["body_node_ids"]])
                        haskey(item, "try_node_ids") && (entry["tryNodeIds"] = [String(node_id) for node_id in item["try_node_ids"]])
                        haskey(item, "catch_node_ids") && (entry["catchNodeIds"] = [String(node_id) for node_id in item["catch_node_ids"]])
                        entry
                    end for item in value
                ]
            elseif string_key == "control_flow_recovery"
                payload["controlFlowRecovery"] = Dict{String,Any}(
                    "controlId" => String(get(value, "control_id", "")),
                    "failedNodeId" => String(get(value, "failed_node_id", "")),
                    "catchNodeIds" => [String(node_id) for node_id in get(value, "catch_node_ids", Any[])],
                    "status" => String(get(value, "status", "")),
                    "bounded" => Bool(get(value, "bounded", false)),
                )
            elseif string_key == "control_flow_branch_state"
                payload["controlFlowBranchState"] = Dict{String,Any}(
                    "controlId" => String(get(value, "control_id", "")),
                    "failedNodeId" => String(get(value, "failed_node_id", "")),
                    "branch" => String(get(value, "branch", "")),
                    "catchNodeIds" => [String(node_id) for node_id in get(value, "catch_node_ids", Any[])],
                    "branchStages" => [
                        [String(node_id) for node_id in stage] for stage in get(value, "branch_stages", Any[])
                    ],
                    "branchStageIndex" => Int(get(value, "branch_stage_index", 0)),
                    "branchStageCount" => Int(get(value, "branch_stage_count", 0)),
                    "activeNodeIds" => [String(node_id) for node_id in get(value, "active_node_ids", Any[])],
                    "completedNodeIds" => [String(node_id) for node_id in get(value, "completed_node_ids", Any[])],
                    "status" => String(get(value, "status", "")),
                    "bounded" => Bool(get(value, "bounded", false)),
                    "workerId" => String(get(value, "worker_id", "")),
                    "stageResults" => [
                        Dict{String,Any}(
                            "stageIndex" => Int(get(item, "stage_index", 0)),
                            "nodeIds" => [String(node_id) for node_id in get(item, "node_ids", Any[])],
                            "nodeResults" => [
                                Dict{String,Any}(
                                    "nodeId" => String(get(result, "node_id", "")),
                                    "nodeType" => String(get(result, "node_type", "")),
                                    "status" => String(get(result, "status", "")),
                                    "outputKind" => String(get(result, "output_kind", "")),
                                    "rowCount" => Int(get(result, "row_count", 0)),
                                ) for result in get(item, "node_results", Any[])
                            ],
                        ) for item in get(value, "stage_results", Any[])
                    ],
                    "nodeResults" => [
                        Dict{String,Any}(
                            "nodeId" => String(get(item, "node_id", "")),
                            "nodeType" => String(get(item, "node_type", "")),
                            "status" => String(get(item, "status", "")),
                            "outputKind" => String(get(item, "output_kind", "")),
                            "rowCount" => Int(get(item, "row_count", 0)),
                        ) for item in get(value, "node_results", Any[])
                    ],
                )
            elseif string_key == "dispatch_plan"
                payload["dispatchPlan"] = [
                    Dict{String,Any}(
                        "lane" => String(get(item, "lane", "")),
                        "nodeIds" => [String(node_id) for node_id in get(item, "node_ids", Any[])],
                        "workerPool" => String(get(item, "worker_pool", "")),
                        "isolationMode" => String(get(item, "isolation_mode", "shared")),
                    ) for item in value
                ]
                for (index, item) in enumerate(value)
                    haskey(item, "accelerator") && (payload["dispatchPlan"][index]["accelerator"] = String(item["accelerator"]))
                    haskey(item, "scheduler_policy") && (payload["dispatchPlan"][index]["schedulerPolicy"] = String(item["scheduler_policy"]))
                    haskey(item, "placement_reason") && (payload["dispatchPlan"][index]["placementReason"] = String(item["placement_reason"]))
                    haskey(item, "requested_device") && (payload["dispatchPlan"][index]["requestedDevice"] = String(item["requested_device"]))
                    haskey(item, "worker_capacity") && (payload["dispatchPlan"][index]["workerCapacity"] = item["worker_capacity"])
                end
            elseif string_key == "observability_trace"
                payload["observabilityTrace"] = value
            elseif string_key == "stream_lifecycle_status"
                payload["streamLifecycleStatus"] = String(value)
            elseif string_key == "stream_adapter"
                payload["streamAdapter"] = String(value)
            elseif string_key == "stream_adapter_contract"
                payload["streamAdapterContract"] = value
            elseif string_key == "stream_processed_offset"
                payload["streamProcessedOffset"] = Int(value)
            elseif string_key == "stream_committed_offset"
                payload["streamCommittedOffset"] = Int(value)
            elseif string_key == "stream_processed_rows"
                payload["streamProcessedRows"] = Int(value)
            elseif string_key == "stream_batch_count"
                payload["streamBatchCount"] = Int(value)
            elseif string_key == "stream_consumer_lag"
                payload["streamConsumerLag"] = Int(value)
            elseif string_key == "stream_backpressure"
                payload["streamBackpressure"] = String(value)
            elseif string_key == "stream_watermark"
                payload["streamWatermark"] = value
            elseif string_key == "stream_watermark_state"
                payload["streamWatermarkState"] = value
            elseif string_key == "stream_window_state"
                payload["streamWindowState"] = value
            elseif string_key == "stream_last_checkpoint_id"
                payload["streamLastCheckpointId"] = String(value)
            elseif string_key == "stream_checkpoint_offsets"
                payload["streamCheckpointOffsets"] = value
            elseif string_key == "stream_sink_transaction_id"
                payload["streamSinkTransactionId"] = String(value)
            elseif string_key == "stream_sink_transaction_state"
                payload["streamSinkTransactionState"] = value
            elseif string_key == "stream_idempotency_key"
                payload["streamIdempotencyKey"] = String(value)
            elseif string_key == "stream_exactly_once_status"
                payload["streamExactlyOnceStatus"] = String(value)
            elseif string_key == "stream_replay_status"
                payload["streamReplayStatus"] = String(value)
            elseif string_key == "stream_replay_offset"
                payload["streamReplayOffset"] = Int(value)
            elseif string_key == "dispatch_lane"
                payload["dispatchLane"] = String(value)
            elseif string_key == "dispatch_worker_pool"
                payload["dispatchWorkerPool"] = String(value)
            elseif string_key == "dispatch_isolation_mode"
                payload["dispatchIsolationMode"] = String(value)
            elseif string_key == "dispatch_accelerator"
                payload["dispatchAccelerator"] = String(value)
            elseif string_key == "dispatch_scheduler_policy"
                payload["dispatchSchedulerPolicy"] = String(value)
            elseif string_key == "dispatch_placement_reason"
                payload["dispatchPlacementReason"] = String(value)
            elseif string_key == "dispatch_requested_device"
                payload["dispatchRequestedDevice"] = String(value)
            elseif string_key == "dispatch_worker_capacity"
                payload["dispatchWorkerCapacity"] = value
            elseif string_key == "worker_id"
                payload["workerId"] = String(value)
            elseif string_key == "gpu_execution_path"
                payload["gpuExecutionPath"] = String(value)
            elseif string_key == "gpu_device_id"
                payload["gpuDeviceId"] = String(value)
            elseif string_key == "gpu_accelerator"
                payload["gpuAccelerator"] = String(value)
            elseif string_key == "gpu_vendor"
                payload["gpuVendor"] = String(value)
            elseif string_key == "gpu_fallback_used"
                payload["gpuFallbackUsed"] = Bool(value)
            elseif string_key == "gpu_cpu_fallback_used"
                payload["gpuCpuFallbackUsed"] = Bool(value)
            elseif string_key == "gpu_placement_fallback_used"
                payload["gpuPlacementFallbackUsed"] = Bool(value)
            elseif string_key == "gpu_request_satisfied"
                payload["gpuRequestSatisfied"] = Bool(value)
            elseif string_key == "gpu_workload"
                payload["gpuWorkload"] = String(value)
            elseif string_key == "gpu_workload_result"
                payload["gpuWorkloadResult"] = value
            elseif string_key == "gpu_registry"
                payload["gpuRegistry"] = value
            elseif string_key == "gpu_requested_device"
                payload["gpuRequestedDevice"] = String(value)
            elseif string_key == "gpu_selected_device"
                payload["gpuSelectedDevice"] = String(value)
            elseif string_key == "gpu_fallback_reason"
                payload["gpuFallbackReason"] = String(value)
            elseif string_key == "gpu_placement_reason"
                payload["gpuPlacementReason"] = String(value)
            elseif string_key == "gpu_scheduler_policy"
                payload["gpuSchedulerPolicy"] = String(value)
            elseif string_key == "gpu_worker_isolation_mode"
                payload["gpuWorkerIsolationMode"] = String(value)
            elseif string_key == "gpu_worker_capacity"
                payload["gpuWorkerCapacity"] = value
            else
                payload[string_key] = value
            end
        end
    end
    return payload
end

function event_payload(event::GatewayEvent)
    return Dict(
        "eventId" => event.event_id,
        "eventType" => event.event_type,
        "aggregateType" => event.aggregate_type,
        "aggregateId" => event.aggregate_id,
        "occurredAt" => event.occurred_at,
        "sequence" => event.sequence,
        "producer" => event.producer,
        "payloadVersion" => event.payload_version,
        "payload" => event.payload,
    )
end

function role_binding_payload(binding::GatewayRoleBinding)
    return Dict(
        "principalId" => binding.principal_id,
        "workspaceId" => binding.workspace_id,
        "role" => binding.role,
    )
end

function resource_policy_payload(policy::GatewayResourcePolicy)
    return Dict(
        "resourceType" => policy.resource_type,
        "resourceId" => policy.resource_id,
        "workspaceId" => policy.workspace_id,
        "permissionsByRole" => policy.permissions_by_role,
    )
end

function auth_policy_payload(policy::GatewayAuthPolicy)
    return Dict(
        "roleBindings" => [role_binding_payload(binding) for binding in policy.role_bindings],
        "resourcePolicies" => [resource_policy_payload(item) for item in policy.resource_policies],
        "updatedAt" => policy.updated_at,
    )
end

function user_record_payload(user::GatewayUserRecord)
    payload = Dict{String,Any}(
        "principalId" => user.principal_id,
        "displayName" => user.display_name,
        "active" => user.active,
        "createdAt" => user.created_at,
        "updatedAt" => user.updated_at,
    )
    user.email === nothing || (payload["email"] = user.email)
    return payload
end

function workspace_record_payload(workspace::GatewayWorkspaceRecord)
    return Dict{String,Any}(
        "workspaceId" => workspace.workspace_id,
        "name" => workspace.name,
        "active" => workspace.active,
        "createdAt" => workspace.created_at,
        "updatedAt" => workspace.updated_at,
    )
end

function auth_directory_payload(directory::GatewayAuthDirectory)
    return Dict(
        "users" => [user_record_payload(user) for user in directory.users],
        "workspaces" => [workspace_record_payload(workspace) for workspace in directory.workspaces],
        "updatedAt" => directory.updated_at,
    )
end

function published_dashboard_payload(dashboard::PublishedDashboardRecord)
    payload = Dict(
        "dashboardId" => dashboard.dashboard_id,
        "workflowId" => dashboard.workflow_id,
        "name" => dashboard.name,
        "version" => dashboard.version,
        "publishedAt" => dashboard.published_at,
        "visibility" => dashboard.visibility,
        "binding" => dashboard.binding,
        "charts" => dashboard.charts,
    )
    isempty(dashboard.datasets) || (payload["datasets"] = dashboard.datasets)
    dashboard.share_token === nothing || (payload["shareToken"] = dashboard.share_token)
    return payload
end

function gateway_execution(item)
    status_history = Dict{String,Any}[]
    if haskey(item, "statusHistory")
        for event in item["statusHistory"]
            push!(status_history, Dict{String,Any}(String(key) => value for (key, value) in pairs(event)))
        end
    end

    metadata = Dict{String,Any}()
    for (key, value) in pairs(item)
        string_key = String(key)
        if string_key in (
            "executionId",
            "workflowId",
            "workflowVersion",
            "checkpointTag",
            "status",
            "mode",
            "plan",
            "stages",
            "nodeCount",
            "connectionCount",
            "createdAt",
            "updatedAt",
            "statusHistory",
            "queuedAt",
            "startedAt",
            "finishedAt",
        )
            continue
        end
        if string_key == "resourcePlan"
            metadata["resource_plan"] = [
                Dict{String,Any}(
                    "lane" => String(get(entry, "lane", "")),
                    "node_ids" => [String(node_id) for node_id in get(entry, "nodeIds", Any[])],
                ) for entry in value
            ]
        elseif string_key == "controlFlowPlan"
            metadata["control_flow_plan"] = [
                let
                    plan_entry = Dict{String,Any}(
                        "control_id" => String(get(entry, "controlId", "")),
                        "kind" => String(get(entry, "kind", "")),
                        "bounded" => Bool(get(entry, "bounded", false)),
                    )
                    haskey(entry, "iterationMode") && (plan_entry["iteration_mode"] = String(entry["iterationMode"]))
                    haskey(entry, "maxIterations") && (plan_entry["max_iterations"] = Int(entry["maxIterations"]))
                    haskey(entry, "startNodeId") && (plan_entry["start_node_id"] = String(entry["startNodeId"]))
                    haskey(entry, "endNodeId") && (plan_entry["end_node_id"] = String(entry["endNodeId"]))
                    haskey(entry, "bodyNodeIds") && (plan_entry["body_node_ids"] = [String(node_id) for node_id in entry["bodyNodeIds"]])
                    haskey(entry, "tryNodeIds") && (plan_entry["try_node_ids"] = [String(node_id) for node_id in entry["tryNodeIds"]])
                    haskey(entry, "catchNodeIds") && (plan_entry["catch_node_ids"] = [String(node_id) for node_id in entry["catchNodeIds"]])
                    plan_entry
                end for entry in value
            ]
        elseif string_key == "controlFlowRecovery"
            metadata["control_flow_recovery"] = Dict{String,Any}(
                "control_id" => String(get(value, "controlId", "")),
                "failed_node_id" => String(get(value, "failedNodeId", "")),
                "catch_node_ids" => [String(node_id) for node_id in get(value, "catchNodeIds", Any[])],
                "status" => String(get(value, "status", "")),
                "bounded" => Bool(get(value, "bounded", false)),
            )
        elseif string_key == "controlFlowBranchState"
            metadata["control_flow_branch_state"] = Dict{String,Any}(
                "control_id" => String(get(value, "controlId", "")),
                "failed_node_id" => String(get(value, "failedNodeId", "")),
                "branch" => String(get(value, "branch", "")),
                "catch_node_ids" => [String(node_id) for node_id in get(value, "catchNodeIds", Any[])],
                "branch_stages" => [
                    [String(node_id) for node_id in stage] for stage in get(value, "branchStages", Any[])
                ],
                "branch_stage_index" => Int(get(value, "branchStageIndex", 0)),
                "branch_stage_count" => Int(get(value, "branchStageCount", 0)),
                "active_node_ids" => [String(node_id) for node_id in get(value, "activeNodeIds", Any[])],
                "completed_node_ids" => [String(node_id) for node_id in get(value, "completedNodeIds", Any[])],
                "status" => String(get(value, "status", "")),
                "bounded" => Bool(get(value, "bounded", false)),
                "worker_id" => String(get(value, "workerId", "")),
                "stage_results" => [
                    Dict{String,Any}(
                        "stage_index" => Int(get(item, "stageIndex", 0)),
                        "node_ids" => [String(node_id) for node_id in get(item, "nodeIds", Any[])],
                        "node_results" => [
                            Dict{String,Any}(
                                "node_id" => String(get(result, "nodeId", "")),
                                "node_type" => String(get(result, "nodeType", "")),
                                "status" => String(get(result, "status", "")),
                                "output_kind" => String(get(result, "outputKind", "")),
                                "row_count" => Int(get(result, "rowCount", 0)),
                            ) for result in get(item, "nodeResults", Any[])
                        ],
                    ) for item in get(value, "stageResults", Any[])
                ],
                "node_results" => [
                    Dict{String,Any}(
                        "node_id" => String(get(item, "nodeId", "")),
                        "node_type" => String(get(item, "nodeType", "")),
                        "status" => String(get(item, "status", "")),
                        "output_kind" => String(get(item, "outputKind", "")),
                        "row_count" => Int(get(item, "rowCount", 0)),
                    ) for item in get(value, "nodeResults", Any[])
                ],
            )
        elseif string_key == "dispatchPlan"
            metadata["dispatch_plan"] = [
                let
                    entry = Dict{String,Any}(
                        "lane" => String(get(item, "lane", "")),
                        "node_ids" => [String(node_id) for node_id in get(item, "nodeIds", Any[])],
                        "worker_pool" => String(get(item, "workerPool", "")),
                        "isolation_mode" => String(get(item, "isolationMode", "shared")),
                    )
                    haskey(item, "accelerator") && (entry["accelerator"] = String(item["accelerator"]))
                    haskey(item, "schedulerPolicy") && (entry["scheduler_policy"] = String(item["schedulerPolicy"]))
                    haskey(item, "placementReason") && (entry["placement_reason"] = String(item["placementReason"]))
                    haskey(item, "requestedDevice") && (entry["requested_device"] = String(item["requestedDevice"]))
                    haskey(item, "workerCapacity") && (entry["worker_capacity"] = item["workerCapacity"])
                    entry
                end for item in value
            ]
        elseif string_key == "streamLifecycleStatus"
            metadata["stream_lifecycle_status"] = value
        elseif string_key == "streamAdapter"
            metadata["stream_adapter"] = value
        elseif string_key == "streamAdapterContract"
            metadata["stream_adapter_contract"] = value
        elseif string_key == "streamProcessedOffset"
            metadata["stream_processed_offset"] = value
        elseif string_key == "streamCommittedOffset"
            metadata["stream_committed_offset"] = value
        elseif string_key == "streamProcessedRows"
            metadata["stream_processed_rows"] = value
        elseif string_key == "streamBatchCount"
            metadata["stream_batch_count"] = value
        elseif string_key == "streamConsumerLag"
            metadata["stream_consumer_lag"] = value
        elseif string_key == "streamBackpressure"
            metadata["stream_backpressure"] = value
        elseif string_key == "streamWatermark"
            metadata["stream_watermark"] = value
        elseif string_key == "streamWatermarkState"
            metadata["stream_watermark_state"] = value
        elseif string_key == "streamWindowState"
            metadata["stream_window_state"] = value
        elseif string_key == "streamLastCheckpointId"
            metadata["stream_last_checkpoint_id"] = value
        elseif string_key == "streamCheckpointOffsets"
            metadata["stream_checkpoint_offsets"] = value
        elseif string_key == "streamSinkTransactionId"
            metadata["stream_sink_transaction_id"] = value
        elseif string_key == "streamSinkTransactionState"
            metadata["stream_sink_transaction_state"] = value
        elseif string_key == "streamIdempotencyKey"
            metadata["stream_idempotency_key"] = value
        elseif string_key == "streamExactlyOnceStatus"
            metadata["stream_exactly_once_status"] = value
        elseif string_key == "streamReplayStatus"
            metadata["stream_replay_status"] = value
        elseif string_key == "streamReplayOffset"
            metadata["stream_replay_offset"] = value
        elseif string_key == "dispatchLane"
            metadata["dispatch_lane"] = value
        elseif string_key == "dispatchWorkerPool"
            metadata["dispatch_worker_pool"] = value
        elseif string_key == "dispatchIsolationMode"
            metadata["dispatch_isolation_mode"] = value
        elseif string_key == "dispatchAccelerator"
            metadata["dispatch_accelerator"] = value
        elseif string_key == "dispatchSchedulerPolicy"
            metadata["dispatch_scheduler_policy"] = value
        elseif string_key == "dispatchPlacementReason"
            metadata["dispatch_placement_reason"] = value
        elseif string_key == "dispatchRequestedDevice"
            metadata["dispatch_requested_device"] = value
        elseif string_key == "dispatchWorkerCapacity"
            metadata["dispatch_worker_capacity"] = value
        elseif string_key == "workerId"
            metadata["worker_id"] = value
        elseif string_key == "gpuExecutionPath"
            metadata["gpu_execution_path"] = value
        elseif string_key == "gpuDeviceId"
            metadata["gpu_device_id"] = value
        elseif string_key == "gpuAccelerator"
            metadata["gpu_accelerator"] = value
        elseif string_key == "gpuVendor"
            metadata["gpu_vendor"] = value
        elseif string_key == "gpuFallbackUsed"
            metadata["gpu_fallback_used"] = value
        elseif string_key == "gpuCpuFallbackUsed"
            metadata["gpu_cpu_fallback_used"] = value
        elseif string_key == "gpuPlacementFallbackUsed"
            metadata["gpu_placement_fallback_used"] = value
        elseif string_key == "gpuRequestSatisfied"
            metadata["gpu_request_satisfied"] = value
        elseif string_key == "gpuWorkload"
            metadata["gpu_workload"] = value
        elseif string_key == "gpuWorkloadResult"
            metadata["gpu_workload_result"] = value
        elseif string_key == "gpuRegistry"
            metadata["gpu_registry"] = value
        elseif string_key == "gpuRequestedDevice"
            metadata["gpu_requested_device"] = value
        elseif string_key == "gpuSelectedDevice"
            metadata["gpu_selected_device"] = value
        elseif string_key == "gpuFallbackReason"
            metadata["gpu_fallback_reason"] = value
        elseif string_key == "gpuPlacementReason"
            metadata["gpu_placement_reason"] = value
        elseif string_key == "gpuSchedulerPolicy"
            metadata["gpu_scheduler_policy"] = value
        elseif string_key == "gpuWorkerIsolationMode"
            metadata["gpu_worker_isolation_mode"] = value
        elseif string_key == "gpuWorkerCapacity"
            metadata["gpu_worker_capacity"] = value
        else
            metadata[string_key] = value
        end
    end

    return GatewayExecution(
        execution_id = String(item["executionId"]),
        workflow_id = String(item["workflowId"]),
        workflow_version = String(item["workflowVersion"]),
        checkpoint_tag = String(item["checkpointTag"]),
        status = String(item["status"]),
        mode = String(item["mode"]),
        plan = [String(entry) for entry in item["plan"]],
        stages = [[String(entry) for entry in stage] for stage in item["stages"]],
        node_count = Int(item["nodeCount"]),
        connection_count = Int(item["connectionCount"]),
        created_at = String(item["createdAt"]),
        updated_at = String(get(item, "updatedAt", item["createdAt"])),
        status_history = status_history,
        queued_at = haskey(item, "queuedAt") ? String(item["queuedAt"]) : nothing,
        started_at = haskey(item, "startedAt") ? String(item["startedAt"]) : nothing,
        finished_at = haskey(item, "finishedAt") ? String(item["finishedAt"]) : nothing,
        metadata = metadata,
    )
end

function gateway_event(item)
    payload = haskey(item, "payload") ?
        Dict{String,Any}(String(key) => value for (key, value) in pairs(item["payload"])) :
        Dict{String,Any}()
    return GatewayEvent(
        event_id = String(item["eventId"]),
        event_type = String(item["eventType"]),
        aggregate_type = String(item["aggregateType"]),
        aggregate_id = String(item["aggregateId"]),
        occurred_at = String(item["occurredAt"]),
        sequence = Int(item["sequence"]),
        producer = String(item["producer"]),
        payload_version = Int(get(item, "payloadVersion", 1)),
        payload = payload,
    )
end

function gateway_role_binding(item)
    return GatewayRoleBinding(
        principal_id = String(item["principalId"]),
        workspace_id = String(get(item, "workspaceId", "local-dev")),
        role = String(item["role"]),
    )
end

function gateway_resource_policy(item)
    permissions = Dict{String,Vector{String}}()
    for (role, values) in pairs(get(item, "permissionsByRole", Dict{String,Any}()))
        permissions[String(role)] = [String(value) for value in values]
    end
    return GatewayResourcePolicy(
        resource_type = String(item["resourceType"]),
        resource_id = String(item["resourceId"]),
        workspace_id = String(get(item, "workspaceId", "local-dev")),
        permissions_by_role = permissions,
    )
end

function gateway_auth_policy(item)
    return GatewayAuthPolicy(
        role_bindings = [gateway_role_binding(binding) for binding in get(item, "roleBindings", Any[])],
        resource_policies = [gateway_resource_policy(policy) for policy in get(item, "resourcePolicies", Any[])],
        updated_at = String(get(item, "updatedAt", JuliaFlowExecutionService.iso8601_timestamp())),
    )
end

function gateway_user_record(item)
    created_at = String(get(item, "createdAt", JuliaFlowExecutionService.iso8601_timestamp()))
    return GatewayUserRecord(
        principal_id = String(item["principalId"]),
        display_name = String(get(item, "displayName", item["principalId"])),
        email = haskey(item, "email") && item["email"] !== nothing ? String(item["email"]) : nothing,
        active = Bool(get(item, "active", true)),
        created_at = created_at,
        updated_at = String(get(item, "updatedAt", created_at)),
    )
end

function gateway_workspace_record(item)
    created_at = String(get(item, "createdAt", JuliaFlowExecutionService.iso8601_timestamp()))
    return GatewayWorkspaceRecord(
        workspace_id = String(item["workspaceId"]),
        name = String(get(item, "name", item["workspaceId"])),
        active = Bool(get(item, "active", true)),
        created_at = created_at,
        updated_at = String(get(item, "updatedAt", created_at)),
    )
end

function gateway_auth_directory(item)
    return GatewayAuthDirectory(
        users = [gateway_user_record(user) for user in get(item, "users", Any[])],
        workspaces = [gateway_workspace_record(workspace) for workspace in get(item, "workspaces", Any[])],
        updated_at = String(get(item, "updatedAt", JuliaFlowExecutionService.iso8601_timestamp())),
    )
end

function gateway_published_dashboard(item)
    return PublishedDashboardRecord(
        dashboard_id = String(item["dashboardId"]),
        workflow_id = String(item["workflowId"]),
        name = String(item["name"]),
        version = Int(item["version"]),
        published_at = String(item["publishedAt"]),
        visibility = String(get(item, "visibility", "workspace")),
        share_token = haskey(item, "shareToken") ? String(item["shareToken"]) : nothing,
        binding = Dict{String,Any}(String(key) => value for (key, value) in pairs(item["binding"])),
        charts = [Dict{String,Any}(String(key) => value for (key, value) in pairs(chart)) for chart in item["charts"]],
        datasets = haskey(item, "datasets") ? Dict{String,Vector{Dict{String,Any}}}(
            String(key) => [Dict{String,Any}(String(row_key) => row_value for (row_key, row_value) in pairs(row)) for row in rows]
            for (key, rows) in pairs(item["datasets"])
        ) : Dict{String,Vector{Dict{String,Any}}}(),
    )
end

function gateway_hub_extension(item)
    manifest = Dict{String,Any}(String(key) => value for (key, value) in pairs(item["manifest"]))
    return HubExtensionRecord(
        extension_id = String(item["extensionId"]),
        name = String(manifest["name"]),
        version = String(manifest["version"]),
        publisher = String(manifest["publisher"]),
        summary = String(manifest["summary"]),
        package_ref = String(manifest["packageRef"]),
        tags = [String(entry) for entry in get(manifest, "tags", Any[])],
        engine_compatibility = String(get(manifest, "engineCompatibility", "alpha-core")),
        required_contract_version = String(get(manifest, "requiredContractVersion", "0.1.0")),
        supported_checkpoints = [String(entry) for entry in get(manifest, "supportedCheckpoints", get(manifest, "compatibleCheckpoints", Any[]))],
        compatible_checkpoints = [String(entry) for entry in get(manifest, "compatibleCheckpoints", Any[])],
        dependencies = [String(entry) for entry in get(manifest, "dependencies", Any[])],
        publisher_identity = String(get(manifest, "publisherIdentity", "unknown")),
        artifact_hashes = haskey(manifest, "artifactHashes") ?
            Dict{String,String}(String(key) => String(value) for (key, value) in pairs(manifest["artifactHashes"])) :
            Dict{String,String}(),
        compatibility_sandbox_command = haskey(manifest, "compatibilitySandboxCommand") ? String(manifest["compatibilitySandboxCommand"]) : nothing,
        mirror_refs = [String(entry) for entry in get(manifest, "mirrorRefs", Any[])],
        signature = haskey(manifest, "signature") ? String(manifest["signature"]) : nothing,
        release_notes_ref = haskey(manifest, "releaseNotesRef") ? String(manifest["releaseNotesRef"]) : nothing,
        install_state = String(get(item, "installState", "available")),
        compatibility = haskey(item, "compatibility") ?
            Dict{String,Any}(String(key) => value for (key, value) in pairs(item["compatibility"])) :
            Dict(
                "compatible" => true,
                "warnings" => String[],
                "blockers" => String[],
                "evaluatedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
            ),
        trust = haskey(item, "trust") ?
            Dict{String,Any}(String(key) => value for (key, value) in pairs(item["trust"])) :
            Dict(
                "trusted" => false,
                "level" => "untrusted",
                "warnings" => String[],
                "blockers" => String[],
                "evaluatedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
            ),
        upgrade = haskey(item, "upgrade") ?
            Dict{String,Any}(String(key) => value for (key, value) in pairs(item["upgrade"])) :
            Dict(
                "upgradeAvailable" => false,
                "latestVersion" => String(manifest["version"]),
                "evaluatedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
            ),
        verification = haskey(item, "verification") ?
            Dict{String,Any}(String(key) => value for (key, value) in pairs(item["verification"])) :
            hub_verification_default(),
        installed_version = haskey(item, "installedVersion") ? String(item["installedVersion"]) : nothing,
        installed_at = haskey(item, "installedAt") ? String(item["installedAt"]) : nothing,
        enabled_at = haskey(item, "enabledAt") ? String(item["enabledAt"]) : nothing,
    )
end

function FileGatewayRepository(root::AbstractString)
    return FileGatewayRepository(root = String(root))
end

function PostgreSQLGatewayRepository(connection_string::AbstractString; schema::AbstractString = "public")
    return PostgreSQLGatewayRepository(connection_string = String(connection_string), schema = String(schema))
end

function workflows_dir(repo::FileGatewayRepository)
    return joinpath(repo.root, "workflows")
end

function checkpoints_file(repo::FileGatewayRepository)
    return joinpath(repo.root, "checkpoints.json")
end

function executions_file(repo::FileGatewayRepository)
    return joinpath(repo.root, "executions.json")
end

function event_log_file(repo::FileGatewayRepository)
    return joinpath(repo.root, "event-log.json")
end

function event_cursors_file(repo::FileGatewayRepository)
    return joinpath(repo.root, "event-cursors.json")
end

function auth_policy_file(repo::FileGatewayRepository)
    return joinpath(repo.root, "auth-policy.json")
end

function auth_directory_file(repo::FileGatewayRepository)
    return joinpath(repo.root, "auth-directory.json")
end

function hub_extensions_file(repo::FileGatewayRepository)
    return joinpath(repo.root, "hub-extensions.json")
end

function published_dashboards_file(repo::FileGatewayRepository)
    return joinpath(repo.root, "published-dashboards.json")
end

function default_hub_extensions()
    return HubExtensionRecord[
        HubExtensionRecord(
            extension_id = "juliaflow-base",
            name = "JuliaFlow Base",
            version = "0.1.0",
            publisher = "official",
            summary = "Official starter node pack with source, transform, trainer, BI, and sink nodes.",
            package_ref = "extensions/base",
            tags = ["official", "starter", "alpha"],
            engine_compatibility = "alpha-core",
            required_contract_version = "0.1.0",
            supported_checkpoints = ["cp/02-alpha-core", "cp/03-alpha-gpu-bi"],
            compatible_checkpoints = ["cp/02-alpha-core", "cp/03-alpha-gpu-bi"],
            dependencies = String[],
            publisher_identity = "official:juliaflow",
            artifact_hashes = Dict("package" => "sha256:ef5563c1d3bb2319a9323daebe3e4907fce4c877835371b310dc31d50e521000"),
            compatibility_sandbox_command = "julia --project=. extensions/base/test/runtests.jl",
            mirror_refs = ["mirror://official/juliaflow-base"],
            install_state = "enabled",
            trust = Dict(
                "trusted" => true,
                "level" => "official",
                "warnings" => String[],
                "blockers" => String[],
                "evaluatedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
            ),
            upgrade = Dict(
                "upgradeAvailable" => false,
                "installedVersion" => "0.1.0",
                "latestVersion" => "0.1.0",
                "evaluatedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
            ),
            installed_version = "0.1.0",
            installed_at = JuliaFlowExecutionService.iso8601_timestamp(),
            enabled_at = JuliaFlowExecutionService.iso8601_timestamp(),
        ),
        HubExtensionRecord(
            extension_id = "juliaflow-ops-preview",
            name = "Ops Preview Pack",
            version = "0.1.0-alpha",
            publisher = "partner",
            summary = "Preview extension catalog entry for install/enable flow scaffolding.",
            package_ref = "hub://preview/ops-pack",
            tags = ["preview", "ops", "hub-v0"],
            engine_compatibility = "alpha-core",
            required_contract_version = "0.1.0",
            supported_checkpoints = ["cp/03-alpha-gpu-bi"],
            compatible_checkpoints = ["cp/03-alpha-gpu-bi"],
            dependencies = String[],
            publisher_identity = "partner:ops-preview",
            artifact_hashes = Dict("package" => "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"),
            compatibility_sandbox_command = "julia --project=. extensions/ops-preview/test/runtests.jl",
            mirror_refs = ["mirror://offline/ops-preview"],
            install_state = "available",
            compatibility = Dict(
                "compatible" => false,
                "warnings" => String[],
                "blockers" => ["Extension not validated for current checkpoint cp/00-foundation"],
                "evaluatedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
            ),
            trust = Dict(
                "trusted" => false,
                "level" => "untrusted",
                "warnings" => ["Signature missing for partner extension"],
                "blockers" => ["Partner extension must provide signature and known publisher identity"],
                "evaluatedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
            ),
            upgrade = Dict(
                "upgradeAvailable" => false,
                "latestVersion" => "0.1.0-alpha",
                "evaluatedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
            ),
        ),
    ]
end

function ensure_repository!(repo::FileGatewayRepository)
    mkpath(workflows_dir(repo))
    return repo
end

function connect(repo::PostgreSQLGatewayRepository)
    return LibPQ.Connection(repo.connection_string)
end

function create_postgres_schema!(repo::PostgreSQLGatewayRepository)
    conn = connect(repo)
    try
        execute(conn, "CREATE SCHEMA IF NOT EXISTS $(repo.schema);")
        execute(
            conn,
            """
            CREATE TABLE IF NOT EXISTS $(repo.schema).workflows (
                workflow_id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                version TEXT NOT NULL,
                workflow_toml TEXT NOT NULL,
                metadata JSONB NOT NULL,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
            """,
        )
        execute(
            conn,
            """
            CREATE TABLE IF NOT EXISTS $(repo.schema).checkpoints (
                tag TEXT PRIMARY KEY,
                summary TEXT NOT NULL,
                created_at TIMESTAMPTZ NOT NULL
            );
            """,
        )
        execute(
            conn,
            """
            CREATE TABLE IF NOT EXISTS $(repo.schema).executions (
                execution_id TEXT PRIMARY KEY,
                workflow_id TEXT NOT NULL,
                workflow_version TEXT NOT NULL,
                checkpoint_tag TEXT NOT NULL,
                status TEXT NOT NULL,
                mode TEXT NOT NULL,
                execution_payload JSONB NOT NULL,
                created_at TIMESTAMPTZ NOT NULL
            );
            """,
        )
        execute(
            conn,
            """
            CREATE TABLE IF NOT EXISTS $(repo.schema).hub_extensions (
                extension_id TEXT PRIMARY KEY,
                extension_payload JSONB NOT NULL,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
            """,
        )
        execute(
            conn,
            """
            CREATE TABLE IF NOT EXISTS $(repo.schema).event_log (
                event_id TEXT PRIMARY KEY,
                event_type TEXT NOT NULL,
                aggregate_type TEXT NOT NULL,
                aggregate_id TEXT NOT NULL,
                sequence BIGSERIAL UNIQUE,
                occurred_at TIMESTAMPTZ NOT NULL,
                producer TEXT NOT NULL,
                payload_version INTEGER NOT NULL DEFAULT 1,
                payload JSONB NOT NULL
            );
            """,
        )
        execute(
            conn,
            "CREATE INDEX IF NOT EXISTS $(repo.schema)_event_log_sequence_idx ON $(repo.schema).event_log (sequence);",
        )
        execute(
            conn,
            "CREATE INDEX IF NOT EXISTS $(repo.schema)_event_log_aggregate_idx ON $(repo.schema).event_log (aggregate_type, aggregate_id, sequence);",
        )
        execute(
            conn,
            """
            CREATE TABLE IF NOT EXISTS $(repo.schema).event_cursors (
                consumer_id TEXT PRIMARY KEY,
                last_sequence BIGINT NOT NULL DEFAULT 0,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
            """,
        )
        execute(
            conn,
            """
            CREATE TABLE IF NOT EXISTS $(repo.schema).auth_policy (
                policy_id TEXT PRIMARY KEY,
                policy_payload JSONB NOT NULL,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
            """,
        )
        execute(
            conn,
            """
            CREATE TABLE IF NOT EXISTS $(repo.schema).auth_directory (
                directory_id TEXT PRIMARY KEY,
                directory_payload JSONB NOT NULL,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
            """,
        )
        execute(
            conn,
            """
            CREATE TABLE IF NOT EXISTS $(repo.schema).published_dashboards (
                dashboard_id TEXT PRIMARY KEY,
                dashboard_payload JSONB NOT NULL,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
            """,
        )
    finally
        close(conn)
    end
    return repo
end

function ensure_repository!(repo::PostgreSQLGatewayRepository)
    return create_postgres_schema!(repo)
end

function load_checkpoints(repo::FileGatewayRepository)
    isfile(checkpoints_file(repo)) || return GatewayCheckpoint[]
    raw = JSON3.read(read(checkpoints_file(repo), String))
    checkpoints = GatewayCheckpoint[]
    for item in raw
        push!(
            checkpoints,
            GatewayCheckpoint(
                tag = String(item["tag"]),
                summary = String(item["summary"]),
                created_at = String(item["createdAt"]),
            ),
        )
    end
    return checkpoints
end

function load_executions(repo::FileGatewayRepository)
    isfile(executions_file(repo)) || return GatewayExecution[]
    raw = JSON3.read(read(executions_file(repo), String))
    executions = GatewayExecution[]
    for item in raw
        push!(executions, gateway_execution(item))
    end
    return executions
end

function load_events(repo::FileGatewayRepository)
    isfile(event_log_file(repo)) || return GatewayEvent[]
    raw = JSON3.read(read(event_log_file(repo), String))
    events = GatewayEvent[]
    for item in raw
        push!(events, gateway_event(item))
    end
    sort!(events; by = event -> event.sequence)
    return events
end

function load_auth_policy(repo::FileGatewayRepository)
    isfile(auth_policy_file(repo)) || return GatewayAuthPolicy()
    raw = JSON3.read(read(auth_policy_file(repo), String), Dict{String,Any})
    return gateway_auth_policy(raw)
end

function load_auth_directory(repo::FileGatewayRepository)
    isfile(auth_directory_file(repo)) || return GatewayAuthDirectory()
    raw = JSON3.read(read(auth_directory_file(repo), String), Dict{String,Any})
    return gateway_auth_directory(raw)
end

function load_hub_extensions(repo::FileGatewayRepository)
    isfile(hub_extensions_file(repo)) || return default_hub_extensions()
    raw = JSON3.read(read(hub_extensions_file(repo), String))
    extensions = HubExtensionRecord[]
    for item in raw
        push!(extensions, gateway_hub_extension(item))
    end
    return extensions
end

function load_published_dashboards(repo::FileGatewayRepository)
    isfile(published_dashboards_file(repo)) || return PublishedDashboardRecord[]
    raw = JSON3.read(read(published_dashboards_file(repo), String))
    dashboards = PublishedDashboardRecord[]
    for item in raw
        push!(dashboards, gateway_published_dashboard(item))
    end
    return dashboards
end

function load_workflows(repo::FileGatewayRepository)
    ensure_repository!(repo)
    workflows = Dict{String,WorkflowDefinition}()
    for filename in sort(readdir(workflows_dir(repo)))
        endswith(filename, ".toml") || continue
        workflow = load_workflow_definition(joinpath(workflows_dir(repo), filename))
        workflows[workflow.id] = workflow
    end
    return workflows
end

function persist_json_file!(path::AbstractString, payload)
    write(path, JSON3.write(payload))
    return path
end

function save_workflow!(repo::FileGatewayRepository, workflow_toml::AbstractString; producer::AbstractString = "api-gateway")
    ensure_repository!(repo)
    workflow = load_workflow_definition_text(workflow_toml)
    validate_workflow(workflow)
    write(joinpath(workflows_dir(repo), string(workflow.id, ".toml")), workflow_toml)
    payload = Dict{String,Any}(
        "workflowId" => workflow.id,
        "workflowVersion" => workflow.version,
        "savedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
    )
    workflow.graph === nothing || (payload["graphRevision"] = workflow.graph.revision)
    append_event!(
        repo,
        "repository.save.changed";
        aggregate_type = "workflow",
        aggregate_id = workflow.id,
        payload = payload,
        producer = producer,
    )
    return workflow
end

function save_checkpoint!(repo::FileGatewayRepository, checkpoint::GatewayCheckpoint)
    checkpoints = load_checkpoints(repo)
    filtered = [item for item in checkpoints if item.tag != checkpoint.tag]
    push!(filtered, checkpoint)
    persist_json_file!(checkpoints_file(repo), [checkpoint_payload(item) for item in filtered])
    return checkpoint
end

function save_execution!(repo::FileGatewayRepository, execution::GatewayExecution; producer::AbstractString = "api-gateway")
    executions = load_executions(repo)
    filtered = [item for item in executions if item.execution_id != execution.execution_id]
    push!(filtered, execution)
    persist_json_file!(executions_file(repo), [execution_payload(item) for item in filtered])
    append_event!(
        repo,
        "execution.changed";
        aggregate_type = "execution",
        aggregate_id = execution.execution_id,
        payload = execution_payload(execution),
        producer = producer,
    )
    return execution
end

function save_auth_policy!(repo::FileGatewayRepository, policy::GatewayAuthPolicy; producer::AbstractString = "api-gateway")
    normalized = GatewayAuthPolicy(
        role_bindings = policy.role_bindings,
        resource_policies = policy.resource_policies,
        updated_at = JuliaFlowExecutionService.iso8601_timestamp(),
    )
    persist_json_file!(auth_policy_file(repo), auth_policy_payload(normalized))
    append_event!(
        repo,
        "auth.policy.changed";
        aggregate_type = "auth_policy",
        aggregate_id = "default",
        payload = auth_policy_payload(normalized),
        producer = producer,
    )
    return normalized
end

function save_auth_directory!(repo::FileGatewayRepository, directory::GatewayAuthDirectory; producer::AbstractString = "api-gateway")
    timestamp = JuliaFlowExecutionService.iso8601_timestamp()
    normalized = GatewayAuthDirectory(
        users = [
            GatewayUserRecord(
                principal_id = user.principal_id,
                display_name = user.display_name,
                email = user.email,
                active = user.active,
                created_at = user.created_at,
                updated_at = timestamp,
            ) for user in directory.users
        ],
        workspaces = [
            GatewayWorkspaceRecord(
                workspace_id = workspace.workspace_id,
                name = workspace.name,
                active = workspace.active,
                created_at = workspace.created_at,
                updated_at = timestamp,
            ) for workspace in directory.workspaces
        ],
        updated_at = timestamp,
    )
    persist_json_file!(auth_directory_file(repo), auth_directory_payload(normalized))
    append_event!(
        repo,
        "auth.directory.changed";
        aggregate_type = "auth_directory",
        aggregate_id = "default",
        payload = auth_directory_payload(normalized),
        producer = producer,
    )
    return normalized
end

function save_hub_extension!(repo::FileGatewayRepository, extension::HubExtensionRecord; producer::AbstractString = "api-gateway")
    extensions = load_hub_extensions(repo)
    filtered = [item for item in extensions if item.extension_id != extension.extension_id]
    push!(filtered, extension)
    sort!(filtered, by = item -> item.extension_id)
    persist_json_file!(hub_extensions_file(repo), [hub_extension_payload(item) for item in filtered])
    append_event!(
        repo,
        "hub.extension.changed";
        aggregate_type = "hub_extension",
        aggregate_id = extension.extension_id,
        payload = hub_extension_payload(extension),
        producer = producer,
    )
    return extension
end

function save_published_dashboard!(repo::FileGatewayRepository, dashboard::PublishedDashboardRecord; producer::AbstractString = "api-gateway")
    dashboards = load_published_dashboards(repo)
    filtered = [item for item in dashboards if item.dashboard_id != dashboard.dashboard_id]
    push!(filtered, dashboard)
    sort!(filtered, by = item -> item.dashboard_id)
    persist_json_file!(published_dashboards_file(repo), [published_dashboard_payload(item) for item in filtered])
    append_event!(
        repo,
        "dashboard.published";
        aggregate_type = "dashboard",
        aggregate_id = dashboard.dashboard_id,
        payload = published_dashboard_payload(dashboard),
        producer = producer,
    )
    return dashboard
end

function append_event!(
    repo::FileGatewayRepository,
    event_type::AbstractString;
    aggregate_type::AbstractString,
    aggregate_id::AbstractString,
    payload::Dict{String,Any},
    producer::AbstractString = "api-gateway",
    payload_version::Integer = 1,
    occurred_at::AbstractString = JuliaFlowExecutionService.iso8601_timestamp(),
    event_id::AbstractString = string(uuid4()),
)
    events = load_events(repo)
    next_sequence = isempty(events) ? 1 : events[end].sequence + 1
    event = GatewayEvent(
        event_id = String(event_id),
        event_type = String(event_type),
        aggregate_type = String(aggregate_type),
        aggregate_id = String(aggregate_id),
        occurred_at = String(occurred_at),
        sequence = next_sequence,
        producer = String(producer),
        payload_version = Int(payload_version),
        payload = payload,
    )
    push!(events, event)
    persist_json_file!(event_log_file(repo), [event_payload(item) for item in events])
    return event
end

function list_events_after(repo::FileGatewayRepository, after_sequence::Integer; limit::Integer = 0)
    events = [event for event in load_events(repo) if event.sequence > after_sequence]
    limit > 0 && (events = events[1:min(limit, length(events))])
    return events
end

function load_consumer_cursor(repo::FileGatewayRepository, consumer_id::AbstractString)
    isfile(event_cursors_file(repo)) || return 0
    raw = JSON3.read(read(event_cursors_file(repo), String), Dict{String,Any})
    haskey(raw, consumer_id) || return 0
    return Int(raw[consumer_id])
end

function save_consumer_cursor!(repo::FileGatewayRepository, consumer_id::AbstractString, last_sequence::Integer)
    cursors = isfile(event_cursors_file(repo)) ?
        JSON3.read(read(event_cursors_file(repo), String), Dict{String,Any}) :
        Dict{String,Any}()
    cursors[String(consumer_id)] = Int(last_sequence)
    persist_json_file!(event_cursors_file(repo), cursors)
    return Int(last_sequence)
end

function load_checkpoints(repo::PostgreSQLGatewayRepository)
    ensure_repository!(repo)
    conn = connect(repo)
    checkpoints = GatewayCheckpoint[]
    try
        result = execute(conn, "SELECT tag, summary, created_at::text FROM $(repo.schema).checkpoints ORDER BY created_at ASC;")
        for row in result
            push!(
                checkpoints,
                GatewayCheckpoint(
                    tag = String(row[1]),
                    summary = String(row[2]),
                    created_at = String(row[3]),
                ),
            )
        end
    finally
        close(conn)
    end
    return checkpoints
end

function load_executions(repo::PostgreSQLGatewayRepository)
    ensure_repository!(repo)
    conn = connect(repo)
    executions = GatewayExecution[]
    try
        result = execute(conn, "SELECT execution_payload FROM $(repo.schema).executions ORDER BY created_at ASC;")
        for row in result
            item = JSON3.read(String(row[1]))
            push!(executions, gateway_execution(item))
        end
    finally
        close(conn)
    end
    return executions
end

function load_events(repo::PostgreSQLGatewayRepository)
    ensure_repository!(repo)
    conn = connect(repo)
    events = GatewayEvent[]
    try
        result = execute(
            conn,
            """
            SELECT event_id, event_type, aggregate_type, aggregate_id, occurred_at::text, sequence, producer, payload_version, payload
            FROM $(repo.schema).event_log
            ORDER BY sequence ASC;
            """,
        )
        for row in result
            push!(
                events,
                GatewayEvent(
                    event_id = String(row[1]),
                    event_type = String(row[2]),
                    aggregate_type = String(row[3]),
                    aggregate_id = String(row[4]),
                    occurred_at = String(row[5]),
                    sequence = Int(row[6]),
                    producer = String(row[7]),
                    payload_version = Int(row[8]),
                    payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(JSON3.read(String(row[9]), Dict{String,Any}))),
                ),
            )
        end
    finally
        close(conn)
    end
    return events
end

function load_auth_policy(repo::PostgreSQLGatewayRepository)
    ensure_repository!(repo)
    conn = connect(repo)
    try
        result = execute(conn, "SELECT policy_payload FROM $(repo.schema).auth_policy WHERE policy_id = 'default';")
        row = iterate(result)
        row === nothing && return GatewayAuthPolicy()
        return gateway_auth_policy(JSON3.read(String(row[1][1]), Dict{String,Any}))
    finally
        close(conn)
    end
end

function load_auth_directory(repo::PostgreSQLGatewayRepository)
    ensure_repository!(repo)
    conn = connect(repo)
    try
        result = execute(conn, "SELECT directory_payload FROM $(repo.schema).auth_directory WHERE directory_id = 'default';")
        row = iterate(result)
        row === nothing && return GatewayAuthDirectory()
        return gateway_auth_directory(JSON3.read(String(row[1][1]), Dict{String,Any}))
    finally
        close(conn)
    end
end

function load_hub_extensions(repo::PostgreSQLGatewayRepository)
    ensure_repository!(repo)
    conn = connect(repo)
    extensions = HubExtensionRecord[]
    try
        result = execute(conn, "SELECT extension_payload FROM $(repo.schema).hub_extensions ORDER BY extension_id ASC;")
        for row in result
            item = JSON3.read(String(row[1]))
            push!(extensions, gateway_hub_extension(item))
        end
    finally
        close(conn)
    end
    isempty(extensions) && return default_hub_extensions()
    return extensions
end

function load_published_dashboards(repo::PostgreSQLGatewayRepository)
    ensure_repository!(repo)
    conn = connect(repo)
    dashboards = PublishedDashboardRecord[]
    try
        result = execute(conn, "SELECT dashboard_payload FROM $(repo.schema).published_dashboards ORDER BY dashboard_id ASC;")
        for row in result
            item = JSON3.read(String(row[1]))
            push!(dashboards, gateway_published_dashboard(item))
        end
    finally
        close(conn)
    end
    return dashboards
end

function load_workflows(repo::PostgreSQLGatewayRepository)
    ensure_repository!(repo)
    conn = connect(repo)
    workflows = Dict{String,WorkflowDefinition}()
    try
        result = execute(conn, "SELECT workflow_toml FROM $(repo.schema).workflows ORDER BY workflow_id ASC;")
        for row in result
            workflow = load_workflow_definition_text(String(row[1]))
            workflows[workflow.id] = workflow
        end
    finally
        close(conn)
    end
    return workflows
end

function save_workflow!(repo::PostgreSQLGatewayRepository, workflow_toml::AbstractString; producer::AbstractString = "api-gateway")
    ensure_repository!(repo)
    workflow = load_workflow_definition_text(workflow_toml)
    validate_workflow(workflow)
    conn = connect(repo)
    try
        execute(
            conn,
            """
            INSERT INTO $(repo.schema).workflows (workflow_id, name, version, workflow_toml, metadata, updated_at)
            VALUES (\$1, \$2, \$3, \$4, \$5::jsonb, NOW())
            ON CONFLICT (workflow_id) DO UPDATE
            SET name = EXCLUDED.name,
                version = EXCLUDED.version,
                workflow_toml = EXCLUDED.workflow_toml,
                metadata = EXCLUDED.metadata,
                updated_at = NOW();
            """,
            [workflow.id, workflow.name, workflow.version, workflow_toml, JSON3.write(workflow_metadata_payload(workflow))],
        )
    finally
        close(conn)
    end
    payload = Dict{String,Any}(
        "workflowId" => workflow.id,
        "workflowVersion" => workflow.version,
        "savedAt" => JuliaFlowExecutionService.iso8601_timestamp(),
    )
    workflow.graph === nothing || (payload["graphRevision"] = workflow.graph.revision)
    append_event!(
        repo,
        "repository.save.changed";
        aggregate_type = "workflow",
        aggregate_id = workflow.id,
        payload = payload,
        producer = producer,
    )
    return workflow
end

function save_checkpoint!(repo::PostgreSQLGatewayRepository, checkpoint::GatewayCheckpoint)
    ensure_repository!(repo)
    conn = connect(repo)
    try
        execute(
            conn,
            """
            INSERT INTO $(repo.schema).checkpoints (tag, summary, created_at)
            VALUES (\$1, \$2, \$3::timestamptz)
            ON CONFLICT (tag) DO UPDATE
            SET summary = EXCLUDED.summary,
                created_at = EXCLUDED.created_at;
            """,
            [checkpoint.tag, checkpoint.summary, checkpoint.created_at],
        )
    finally
        close(conn)
    end
    return checkpoint
end

function save_execution!(repo::PostgreSQLGatewayRepository, execution::GatewayExecution; producer::AbstractString = "api-gateway")
    ensure_repository!(repo)
    conn = connect(repo)
    try
        execute(
            conn,
            """
            INSERT INTO $(repo.schema).executions (
                execution_id,
                workflow_id,
                workflow_version,
                checkpoint_tag,
                status,
                mode,
                execution_payload,
                created_at
            )
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7::jsonb, \$8::timestamptz)
            ON CONFLICT (execution_id) DO UPDATE
            SET status = EXCLUDED.status,
                mode = EXCLUDED.mode,
                execution_payload = EXCLUDED.execution_payload,
                created_at = EXCLUDED.created_at;
            """,
            [
                execution.execution_id,
                execution.workflow_id,
                execution.workflow_version,
                execution.checkpoint_tag,
                execution.status,
                execution.mode,
                JSON3.write(execution_payload(execution)),
                execution.created_at,
            ],
        )
    finally
        close(conn)
    end
    append_event!(
        repo,
        "execution.changed";
        aggregate_type = "execution",
        aggregate_id = execution.execution_id,
        payload = execution_payload(execution),
        producer = producer,
    )
    return execution
end

function save_auth_policy!(repo::PostgreSQLGatewayRepository, policy::GatewayAuthPolicy; producer::AbstractString = "api-gateway")
    ensure_repository!(repo)
    normalized = GatewayAuthPolicy(
        role_bindings = policy.role_bindings,
        resource_policies = policy.resource_policies,
        updated_at = JuliaFlowExecutionService.iso8601_timestamp(),
    )
    conn = connect(repo)
    try
        execute(
            conn,
            """
            INSERT INTO $(repo.schema).auth_policy (policy_id, policy_payload, updated_at)
            VALUES ('default', \$1::jsonb, NOW())
            ON CONFLICT (policy_id) DO UPDATE
            SET policy_payload = EXCLUDED.policy_payload,
                updated_at = NOW();
            """,
            [JSON3.write(auth_policy_payload(normalized))],
        )
    finally
        close(conn)
    end
    append_event!(
        repo,
        "auth.policy.changed";
        aggregate_type = "auth_policy",
        aggregate_id = "default",
        payload = auth_policy_payload(normalized),
        producer = producer,
    )
    return normalized
end

function save_auth_directory!(repo::PostgreSQLGatewayRepository, directory::GatewayAuthDirectory; producer::AbstractString = "api-gateway")
    ensure_repository!(repo)
    timestamp = JuliaFlowExecutionService.iso8601_timestamp()
    normalized = GatewayAuthDirectory(
        users = [
            GatewayUserRecord(
                principal_id = user.principal_id,
                display_name = user.display_name,
                email = user.email,
                active = user.active,
                created_at = user.created_at,
                updated_at = timestamp,
            ) for user in directory.users
        ],
        workspaces = [
            GatewayWorkspaceRecord(
                workspace_id = workspace.workspace_id,
                name = workspace.name,
                active = workspace.active,
                created_at = workspace.created_at,
                updated_at = timestamp,
            ) for workspace in directory.workspaces
        ],
        updated_at = timestamp,
    )
    conn = connect(repo)
    try
        execute(
            conn,
            """
            INSERT INTO $(repo.schema).auth_directory (directory_id, directory_payload, updated_at)
            VALUES ('default', \$1::jsonb, NOW())
            ON CONFLICT (directory_id) DO UPDATE
            SET directory_payload = EXCLUDED.directory_payload,
                updated_at = NOW();
            """,
            [JSON3.write(auth_directory_payload(normalized))],
        )
    finally
        close(conn)
    end
    append_event!(
        repo,
        "auth.directory.changed";
        aggregate_type = "auth_directory",
        aggregate_id = "default",
        payload = auth_directory_payload(normalized),
        producer = producer,
    )
    return normalized
end

function save_hub_extension!(repo::PostgreSQLGatewayRepository, extension::HubExtensionRecord; producer::AbstractString = "api-gateway")
    ensure_repository!(repo)
    conn = connect(repo)
    try
        execute(
            conn,
            """
            INSERT INTO $(repo.schema).hub_extensions (extension_id, extension_payload, updated_at)
            VALUES (\$1, \$2::jsonb, NOW())
            ON CONFLICT (extension_id) DO UPDATE
            SET extension_payload = EXCLUDED.extension_payload,
                updated_at = NOW();
            """,
            [extension.extension_id, JSON3.write(hub_extension_payload(extension))],
        )
    finally
        close(conn)
    end
    append_event!(
        repo,
        "hub.extension.changed";
        aggregate_type = "hub_extension",
        aggregate_id = extension.extension_id,
        payload = hub_extension_payload(extension),
        producer = producer,
    )
    return extension
end

function save_published_dashboard!(repo::PostgreSQLGatewayRepository, dashboard::PublishedDashboardRecord; producer::AbstractString = "api-gateway")
    ensure_repository!(repo)
    conn = connect(repo)
    try
        execute(
            conn,
            """
            INSERT INTO $(repo.schema).published_dashboards (dashboard_id, dashboard_payload, updated_at)
            VALUES (\$1, \$2::jsonb, NOW())
            ON CONFLICT (dashboard_id) DO UPDATE
            SET dashboard_payload = EXCLUDED.dashboard_payload,
                updated_at = NOW();
            """,
            [dashboard.dashboard_id, JSON3.write(published_dashboard_payload(dashboard))],
        )
    finally
        close(conn)
    end
    append_event!(
        repo,
        "dashboard.published";
        aggregate_type = "dashboard",
        aggregate_id = dashboard.dashboard_id,
        payload = published_dashboard_payload(dashboard),
        producer = producer,
    )
    return dashboard
end

function append_event!(
    repo::PostgreSQLGatewayRepository,
    event_type::AbstractString;
    aggregate_type::AbstractString,
    aggregate_id::AbstractString,
    payload::Dict{String,Any},
    producer::AbstractString = "api-gateway",
    payload_version::Integer = 1,
    occurred_at::AbstractString = JuliaFlowExecutionService.iso8601_timestamp(),
    event_id::AbstractString = string(uuid4()),
)
    ensure_repository!(repo)
    conn = connect(repo)
    try
        result = execute(
            conn,
            """
            INSERT INTO $(repo.schema).event_log (
                event_id,
                event_type,
                aggregate_type,
                aggregate_id,
                occurred_at,
                producer,
                payload_version,
                payload
            )
            VALUES (\$1, \$2, \$3, \$4, \$5::timestamptz, \$6, \$7, \$8::jsonb)
            RETURNING sequence;
            """,
            [String(event_id), String(event_type), String(aggregate_type), String(aggregate_id), String(occurred_at), String(producer), Int(payload_version), JSON3.write(payload)],
        )
        row = iterate(result)
        row === nothing && error("failed to append event")
        sequence = Int(row[1][1])
        return GatewayEvent(
            event_id = String(event_id),
            event_type = String(event_type),
            aggregate_type = String(aggregate_type),
            aggregate_id = String(aggregate_id),
            occurred_at = String(occurred_at),
            sequence = sequence,
            producer = String(producer),
            payload_version = Int(payload_version),
            payload = payload,
        )
    finally
        close(conn)
    end
end

function list_events_after(repo::PostgreSQLGatewayRepository, after_sequence::Integer; limit::Integer = 0)
    ensure_repository!(repo)
    conn = connect(repo)
    query = """
        SELECT event_id, event_type, aggregate_type, aggregate_id, occurred_at::text, sequence, producer, payload_version, payload
        FROM $(repo.schema).event_log
        WHERE sequence > \$1
        ORDER BY sequence ASC
    """
    limit > 0 && (query *= "\nLIMIT $(Int(limit))")
    query *= ";"
    events = GatewayEvent[]
    try
        result = execute(conn, query, [Int(after_sequence)])
        for row in result
            push!(
                events,
                GatewayEvent(
                    event_id = String(row[1]),
                    event_type = String(row[2]),
                    aggregate_type = String(row[3]),
                    aggregate_id = String(row[4]),
                    occurred_at = String(row[5]),
                    sequence = Int(row[6]),
                    producer = String(row[7]),
                    payload_version = Int(row[8]),
                    payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(JSON3.read(String(row[9]), Dict{String,Any}))),
                ),
            )
        end
    finally
        close(conn)
    end
    return events
end

function load_consumer_cursor(repo::PostgreSQLGatewayRepository, consumer_id::AbstractString)
    ensure_repository!(repo)
    conn = connect(repo)
    try
        result = execute(
            conn,
            "SELECT last_sequence FROM $(repo.schema).event_cursors WHERE consumer_id = \$1;",
            [String(consumer_id)],
        )
        row = iterate(result)
        row === nothing && return 0
        return Int(row[1][1])
    finally
        close(conn)
    end
end

function save_consumer_cursor!(repo::PostgreSQLGatewayRepository, consumer_id::AbstractString, last_sequence::Integer)
    ensure_repository!(repo)
    conn = connect(repo)
    try
        execute(
            conn,
            """
            INSERT INTO $(repo.schema).event_cursors (consumer_id, last_sequence, updated_at)
            VALUES (\$1, \$2, NOW())
            ON CONFLICT (consumer_id) DO UPDATE
            SET last_sequence = EXCLUDED.last_sequence,
                updated_at = NOW();
            """,
            [String(consumer_id), Int(last_sequence)],
        )
    finally
        close(conn)
    end
    return Int(last_sequence)
end

function load_repository(; backend::Symbol = :file, store_root::AbstractString = mktempdir(), connection_string::AbstractString = "", schema::AbstractString = "public")
    if backend == :file
        return ensure_repository!(FileGatewayRepository(store_root))
    elseif backend == :postgres
        isempty(connection_string) && error("connection_string required for postgres backend")
        return ensure_repository!(PostgreSQLGatewayRepository(connection_string; schema = schema))
    end
    error("unsupported repository backend: $(backend)")
end

end
