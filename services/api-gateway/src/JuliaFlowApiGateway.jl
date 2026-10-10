module JuliaFlowApiGateway

include(joinpath(@__DIR__, "JuliaFlowGatewayRepository.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectSplits.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectCore.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectEvidence.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectRegistry.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectRegistryPayloads.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectJobs.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectStatistics.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectProfiling.jl"))
include(joinpath(@__DIR__, "JuliaFlowProjectAnalysis.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectLocalSources.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectCatalog.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectPredictionExport.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectMonitoring.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectDeploy.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectMLJ.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectTuning.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectEvaluation.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectTransforms.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectExperiments.jl"))
include(joinpath(@__DIR__, "JuliaFlowDataScienceProjectRoutes.jl"))
include(joinpath(@__DIR__, "JuliaFlowGatewayPresentation.jl"))
include(joinpath(@__DIR__, "..", "..", "worker-service", "src", "JuliaFlowWorkerService.jl"))

using .JuliaFlowGatewayRepository
using .JuliaFlowDataScienceProjectRegistry
using .JuliaFlowDataScienceProjectRegistryPayloads
using .JuliaFlowDataScienceProjectJobs
using .JuliaFlowDataScienceProjectStatistics
using .JuliaFlowDataScienceProjectLocalSources
using .JuliaFlowDataScienceProjectCatalog
using .JuliaFlowDataScienceProjectPredictionExport
using .JuliaFlowDataScienceProjectMonitoring
using .JuliaFlowDataScienceProjectDeploy
using .JuliaFlowDataScienceProjectMLJ
using .JuliaFlowDataScienceProjectTuning
using .JuliaFlowDataScienceProjectEvaluation
using .JuliaFlowDataScienceProjectTransforms
using .JuliaFlowDataScienceProjectExperiments
using .JuliaFlowDataScienceProjectRoutes
using .JuliaFlowGatewayPresentation
using .JuliaFlowWorkerService
using Base64
using Dates
using HTTP
using JSON3
using SHA
using UUIDs

export GatewayCheckpoint,
    GatewayExecution,
    DataScienceProjectRecord,
    GatewayState,
    load_state,
    reload_state!,
    persist_workflow_file!,
    persist_workflow_text!,
    foundation_state,
    healthcheck,
    compute_settings_response,
    update_compute_settings_response!,
    list_workflows_response,
    get_workflow_response,
    execution_accept_response,
    execution_list_response,
    execution_detail_response,
    transition_execution_response!,
    create_checkpoint_response!,
    checkpoint_list_response,
    visualize_checkpoint_export_response!,
    reproducibility_bundle_export_response!,
    reproducibility_bundle_import_response!,
    local_backup_export_response!,
    local_backup_restore_response!,
    list_data_science_projects_response,
    create_data_science_project_response!,
    get_data_science_project_response,
    update_data_science_project_response!,
    import_workflow_response!,
    create_workflow_response!,
    update_workflow_response!,
    handle_realtime_socket!,
    sync_external_execution_updates!,
    route_request,
    serve_gateway,
    repository_backend

const GatewayCheckpoint = JuliaFlowGatewayRepository.GatewayCheckpoint
const GatewayExecution = JuliaFlowGatewayRepository.GatewayExecution
const DataScienceProjectRecord = JuliaFlowGatewayRepository.DataScienceProjectRecord
const COMPUTE_BACKENDS = Set(["cpu", "cuda", "simulated_cuda"])
const GPU_PREFERENCES = Set(["auto", "cpu_fallback", "cuda_required"])

Base.@kwdef mutable struct GatewayState
    repository::AbstractGatewayRepository
    workflows::Dict{String,JuliaFlowGatewayRepository.JuliaFlowExecutionService.WorkflowDefinition} = Dict{String,JuliaFlowGatewayRepository.JuliaFlowExecutionService.WorkflowDefinition}()
    checkpoints::Vector{GatewayCheckpoint} = GatewayCheckpoint[]
    executions::Vector{GatewayExecution} = GatewayExecution[]
    hub_extensions::Dict{String,JuliaFlowGatewayRepository.HubExtensionRecord} = Dict{String,JuliaFlowGatewayRepository.HubExtensionRecord}()
    published_dashboards::Dict{String,JuliaFlowGatewayRepository.PublishedDashboardRecord} = Dict{String,JuliaFlowGatewayRepository.PublishedDashboardRecord}()
    data_science_projects::Dict{String,DataScienceProjectRecord} = Dict{String,DataScienceProjectRecord}()
    project_mutation_lock::ReentrantLock = ReentrantLock()
    mutating_projects::Set{String} = Set{String}()
    worker_service::JuliaFlowWorkerService.WorkerServiceState = JuliaFlowWorkerService.WorkerServiceState()
    canvas_subscriptions::Dict{String,Any} = Dict{String,Any}()
    dashboard_subscriptions::Dict{String,Any} = Dict{String,Any}()
    processed_event_ids::Set{String} = Set{String}()
    observability_spans::Vector{Dict{String,Any}} = Dict{String,Any}[]
    observability_span_count::Int = 0
end

Base.@kwdef mutable struct CanvasSubscription
    subscription_id::String
    workflow_id::String
    socket
end

Base.@kwdef mutable struct DashboardSubscription
    subscription_id::String
    dashboard_id::String
    outlet_ids::Vector{String} = String[]
    socket
end

function repository_backend(state::GatewayState)
    return nameof(typeof(state.repository))
end

function reload_state!(state::GatewayState)
    state.workflows = load_workflows(state.repository)
    state.checkpoints = load_checkpoints(state.repository)
    state.executions = load_executions(state.repository)
    state.hub_extensions = Dict(item.extension_id => item for item in JuliaFlowGatewayRepository.load_hub_extensions(state.repository))
    state.published_dashboards = Dict(item.dashboard_id => item for item in JuliaFlowGatewayRepository.load_published_dashboards(state.repository))
    state.data_science_projects = Dict(item.project_id => item for item in JuliaFlowGatewayRepository.load_data_science_projects(state.repository))
    sync_worker_service!(state.worker_service, state.executions)
    return state
end

function load_state(repository::AbstractGatewayRepository)
    state = GatewayState(repository = ensure_repository!(repository))
    return reload_state!(state)
end

function load_state(store_root::AbstractString)
    return load_state(load_repository(backend = :file, store_root = store_root))
end

function persist_workflow_text!(state::GatewayState, workflow_toml::AbstractString)
    workflow = save_workflow!(state.repository, workflow_toml; producer = "api-gateway")
    state.workflows[workflow.id] = workflow
    return workflow
end

function persist_workflow_file!(state::GatewayState, source_path::AbstractString)
    return persist_workflow_text!(state, read(source_path, String))
end

function normalized_string_dict(value)
    return Dict{String,Any}(String(key) => item for (key, item) in pairs(value))
end

function json_compatible_value(value)
    if value isa AbstractDict || value isa JSON3.Object
        return Dict{String,Any}(String(key) => json_compatible_value(item) for (key, item) in pairs(value))
    elseif value isa AbstractVector || value isa JSON3.Array || value isa Tuple
        return [json_compatible_value(item) for item in value]
    elseif value isa Symbol
        return String(value)
    end
    return value
end

function normalize_flow_variable(variable)
    normalized = normalized_string_dict(variable)
    haskey(normalized, "name") || error("flow variable missing name")
    haskey(normalized, "type") || error("flow variable missing type")

    result = Dict{String,Any}(
        "name" => String(normalized["name"]),
        "type" => String(normalized["type"]),
    )
    haskey(normalized, "default") && (result["default"] = normalized["default"])
    return result
end

function normalize_node_payload(node)
    normalized = normalized_string_dict(node)
    ports = [
        Dict{String,Any}(
            "id" => String(port["id"]),
            "direction" => String(port["direction"]),
            "type" => String(port["type"]),
            "label" => String(get(port, "label", port["id"])),
        ) for port in normalized["ports"]
    ]
    config = haskey(normalized, "config") ? normalized_string_dict(normalized["config"]) : Dict{String,Any}()
    if haskey(normalized, "gpuDevicePreference")
        config["gpuDevicePreference"] = normalized["gpuDevicePreference"]
    end

    capabilities = if haskey(normalized, "capabilities")
        normalized_capabilities = normalized_string_dict(normalized["capabilities"])
        capability_payload = Dict{String,Any}(
            "execution_mode" => String(get(normalized_capabilities, "executionMode", get(normalized_capabilities, "execution_mode", "batch"))),
            "resource_class" => String(get(normalized_capabilities, "resourceClass", get(normalized_capabilities, "resource_class", "cpu"))),
        )
        haskey(normalized_capabilities, "accelerator") && (capability_payload["accelerator"] = String(normalized_capabilities["accelerator"]))
        if haskey(normalized_capabilities, "workerPool")
            capability_payload["worker_pool"] = String(normalized_capabilities["workerPool"])
        elseif haskey(normalized_capabilities, "worker_pool")
            capability_payload["worker_pool"] = String(normalized_capabilities["worker_pool"])
        end
        capability_payload
    else
        nothing
    end

    payload = Dict{String,Any}(
        "id" => String(normalized["id"]),
        "name" => String(normalized["name"]),
        "type" => String(normalized["type"]),
        "execution_hint" => String(normalized["executionHint"]),
        "config" => config,
        "ports" => ports,
    )
    capabilities === nothing || (payload["capabilities"] = capabilities)
    return payload
end

function normalize_connection_payload(connection)
    normalized = normalized_string_dict(connection)
    payload = Dict{String,Any}(
        "source_node_id" => String(normalized["sourceNodeId"]),
        "source_port_id" => String(normalized["sourcePortId"]),
        "target_node_id" => String(normalized["targetNodeId"]),
        "target_port_id" => String(normalized["targetPortId"]),
        "data_type" => String(normalized["dataType"]),
    )
    haskey(normalized, "label") && (payload["label"] = String(normalized["label"]))
    return payload
end

function normalize_graph_payload(graph)
    normalized = normalized_string_dict(graph)
    payload = Dict{String,Any}(
        "revision" => Int(get(normalized, "revision", 1)),
        "node_layouts" => [
            let
                layout = normalized_string_dict(item)
                node_layout = Dict{String,Any}(
                    "node_id" => String(get(layout, "nodeId", get(layout, "node_id", ""))),
                    "x" => Float64(layout["x"]),
                    "y" => Float64(layout["y"]),
                )
                haskey(layout, "width") && (node_layout["width"] = Float64(layout["width"]))
                if haskey(layout, "checkpointTag")
                    node_layout["checkpoint_tag"] = String(layout["checkpointTag"])
                elseif haskey(layout, "checkpoint_tag")
                    node_layout["checkpoint_tag"] = String(layout["checkpoint_tag"])
                end
                haskey(layout, "notes") && (node_layout["notes"] = String(layout["notes"]))
                node_layout
            end for item in get(normalized, "nodeLayouts", get(normalized, "node_layouts", Any[]))
        ],
    )
    if haskey(normalized, "viewport")
        payload["viewport"] = normalized_string_dict(normalized["viewport"])
    end
    if haskey(normalized, "selectedNodeId")
        payload["selected_node_id"] = String(normalized["selectedNodeId"])
    elseif haskey(normalized, "selected_node_id")
        payload["selected_node_id"] = String(normalized["selected_node_id"])
    end
    return payload
end

function normalize_container_payload(container)
    normalized = normalized_string_dict(container)
    return Dict{String,Any}(
        "id" => String(get(normalized, "containerId", get(normalized, "id", ""))),
        "name" => String(normalized["name"]),
        "node_ids" => [String(item) for item in get(normalized, "nodeIds", get(normalized, "node_ids", Any[]))],
        "collapsed" => Bool(get(normalized, "collapsed", false)),
    )
end

function normalize_component_payload(component)
    normalized = normalized_string_dict(component)
    return Dict{String,Any}(
        "id" => String(get(normalized, "componentId", get(normalized, "id", ""))),
        "name" => String(normalized["name"]),
        "node_ids" => [String(item) for item in get(normalized, "nodeIds", get(normalized, "node_ids", Any[]))],
        "version" => String(get(normalized, "version", "0.1.0")),
        "flow_variable_scope" => String(get(normalized, "flowVariableScope", get(normalized, "flow_variable_scope", "isolated"))),
        "dashboard_ids" => [String(item) for item in get(normalized, "dashboardIds", get(normalized, "dashboard_ids", Any[]))],
    )
end

function normalize_control_flow_case(case_payload)
    normalized = normalized_string_dict(case_payload)
    return Dict{String,Any}(
        "case_id" => String(get(normalized, "caseId", get(normalized, "case_id", ""))),
        "label" => String(normalized["label"]),
        "target_node_id" => String(get(normalized, "targetNodeId", get(normalized, "target_node_id", ""))),
    )
end

function normalize_control_flow_payload(control_flow)
    normalized = normalized_string_dict(control_flow)
    payload = Dict{String,Any}(
        "id" => String(get(normalized, "controlId", get(normalized, "id", ""))),
        "kind" => String(normalized["kind"]),
    )
    haskey(normalized, "name") && (payload["name"] = String(normalized["name"]))
    haskey(normalized, "startNodeId") && (payload["start_node_id"] = String(normalized["startNodeId"]))
    haskey(normalized, "start_node_id") && (payload["start_node_id"] = String(normalized["start_node_id"]))
    haskey(normalized, "endNodeId") && (payload["end_node_id"] = String(normalized["endNodeId"]))
    haskey(normalized, "end_node_id") && (payload["end_node_id"] = String(normalized["end_node_id"]))
    haskey(normalized, "iterationMode") && (payload["iteration_mode"] = String(normalized["iterationMode"]))
    haskey(normalized, "iteration_mode") && (payload["iteration_mode"] = String(normalized["iteration_mode"]))
    haskey(normalized, "maxIterations") && (payload["max_iterations"] = Int(normalized["maxIterations"]))
    haskey(normalized, "max_iterations") && (payload["max_iterations"] = Int(normalized["max_iterations"]))
    haskey(normalized, "selector") && (payload["selector"] = String(normalized["selector"]))
    haskey(normalized, "cases") && (payload["cases"] = [normalize_control_flow_case(item) for item in normalized["cases"]])
    haskey(normalized, "defaultTargetNodeId") && (payload["default_target_node_id"] = String(normalized["defaultTargetNodeId"]))
    haskey(normalized, "default_target_node_id") && (payload["default_target_node_id"] = String(normalized["default_target_node_id"]))
    haskey(normalized, "tryNodeIds") && (payload["try_node_ids"] = [String(item) for item in normalized["tryNodeIds"]])
    haskey(normalized, "try_node_ids") && (payload["try_node_ids"] = [String(item) for item in normalized["try_node_ids"]])
    haskey(normalized, "catchNodeIds") && (payload["catch_node_ids"] = [String(item) for item in normalized["catchNodeIds"]])
    haskey(normalized, "catch_node_ids") && (payload["catch_node_ids"] = [String(item) for item in normalized["catch_node_ids"]])
    haskey(normalized, "sourceNodeId") && (payload["source_node_id"] = String(normalized["sourceNodeId"]))
    haskey(normalized, "source_node_id") && (payload["source_node_id"] = String(normalized["source_node_id"]))
    haskey(normalized, "targetNodeId") && (payload["target_node_id"] = String(normalized["targetNodeId"]))
    haskey(normalized, "target_node_id") && (payload["target_node_id"] = String(normalized["target_node_id"]))
    haskey(normalized, "chunkSize") && (payload["chunk_size"] = Int(normalized["chunkSize"]))
    haskey(normalized, "chunk_size") && (payload["chunk_size"] = Int(normalized["chunk_size"]))
    haskey(normalized, "maxConcurrency") && (payload["max_concurrency"] = Int(normalized["maxConcurrency"]))
    haskey(normalized, "max_concurrency") && (payload["max_concurrency"] = Int(normalized["max_concurrency"]))
    haskey(normalized, "resourceClass") && (payload["resource_class"] = String(normalized["resourceClass"]))
    haskey(normalized, "resource_class") && (payload["resource_class"] = String(normalized["resource_class"]))
    return payload
end

function normalize_dashboard_payload(dashboard)
    normalized = normalized_string_dict(dashboard)
    binding = normalized_string_dict(normalized["binding"])
    return Dict{String,Any}(
        "id" => String(get(normalized, "dashboardId", get(normalized, "id", ""))),
        "name" => String(normalized["name"]),
        "binding" => Dict{String,Any}(
            "outlet_node_id" => String(get(binding, "outletNodeId", get(binding, "outlet_node_id", ""))),
            "dataset_key" => String(get(binding, "datasetKey", get(binding, "dataset_key", ""))),
            "refresh_mode" => String(get(binding, "refreshMode", get(binding, "refresh_mode", "manual"))),
        ),
        "charts" => [
            let
                chart = normalized_string_dict(item)
                payload = Dict{String,Any}(
                    "id" => String(get(chart, "chartId", get(chart, "id", ""))),
                    "title" => String(chart["title"]),
                    "family" => String(chart["family"]),
                )
                haskey(chart, "xField") && (payload["x_field"] = String(chart["xField"]))
                haskey(chart, "x_field") && (payload["x_field"] = String(chart["x_field"]))
                haskey(chart, "yField") && (payload["y_field"] = String(chart["yField"]))
                haskey(chart, "y_field") && (payload["y_field"] = String(chart["y_field"]))
                haskey(chart, "seriesField") && (payload["series_field"] = String(chart["seriesField"]))
                haskey(chart, "series_field") && (payload["series_field"] = String(chart["series_field"]))
                if haskey(chart, "panel")
                    panel = normalized_string_dict(chart["panel"])
                    payload["panel"] = Dict(
                        "x" => Int(panel["x"]),
                        "y" => Int(panel["y"]),
                        "w" => Int(panel["w"]),
                        "h" => Int(panel["h"]),
                    )
                end
                payload
            end for item in get(normalized, "charts", Any[])
        ],
    )
end

function normalize_runtime_payload(runtime)
    normalized = normalized_string_dict(runtime)
    payload = Dict{String,Any}(
        "run_mode" => String(get(normalized, "runMode", get(normalized, "run_mode", "batch"))),
    )
    haskey(normalized, "source") && (payload["source"] = normalized_string_dict(normalized["source"]))
    haskey(normalized, "window") && (payload["window"] = normalized_string_dict(normalized["window"]))
    haskey(normalized, "policy") && (payload["policy"] = normalized_string_dict(normalized["policy"]))
    return payload
end

function workflow_toml_from_request(body::AbstractDict{<:Any,<:Any})
    if haskey(body, "workflowToml")
        return String(body["workflowToml"])
    end
    haskey(body, "workflow") || error("missing workflow or workflowToml")

    workflow_payload = normalized_string_dict(body["workflow"])
    haskey(workflow_payload, "workflowId") || error("workflow missing workflowId")
    haskey(workflow_payload, "name") || error("workflow missing name")
    haskey(workflow_payload, "version") || error("workflow missing version")

    raw = Dict{String,Any}(
        "version" => String(workflow_payload["version"]),
        "workflow" => Dict{String,Any}(
            "id" => String(workflow_payload["workflowId"]),
            "name" => String(workflow_payload["name"]),
        ),
        "flow_variables" => [
            normalize_flow_variable(variable) for variable in get(workflow_payload, "flowVariables", Any[])
        ],
        "nodes" => [normalize_node_payload(node) for node in workflow_payload["nodes"]],
        "connections" => [normalize_connection_payload(connection) for connection in workflow_payload["connections"]],
    )

    if haskey(workflow_payload, "biOutlets")
        raw["workflow"]["bi_outlets"] = [
            normalized_string_dict(outlet) for outlet in workflow_payload["biOutlets"]
        ]
    end
    if haskey(workflow_payload, "graph")
        raw["workflow"]["graph"] = normalize_graph_payload(workflow_payload["graph"])
    end
    if haskey(workflow_payload, "containers")
        raw["workflow"]["containers"] = [
            normalize_container_payload(container) for container in workflow_payload["containers"]
        ]
    end
    if haskey(workflow_payload, "components")
        raw["workflow"]["components"] = [
            normalize_component_payload(component) for component in workflow_payload["components"]
        ]
    end
    if haskey(workflow_payload, "controlFlow")
        raw["workflow"]["control_flow"] = [
            normalize_control_flow_payload(control_flow) for control_flow in workflow_payload["controlFlow"]
        ]
    elseif haskey(workflow_payload, "control_flow")
        raw["workflow"]["control_flow"] = [
            normalize_control_flow_payload(control_flow) for control_flow in workflow_payload["control_flow"]
        ]
    end
    if haskey(workflow_payload, "dashboards")
        raw["workflow"]["dashboards"] = [
            normalize_dashboard_payload(dashboard) for dashboard in workflow_payload["dashboards"]
        ]
    end
    if haskey(workflow_payload, "runtime")
        raw["runtime"] = normalize_runtime_payload(workflow_payload["runtime"])
    end

    workflow = JuliaFlowGatewayRepository.JuliaFlowExecutionService.parse_workflow_definition(raw)
    return JuliaFlowGatewayRepository.JuliaFlowExecutionService.workflow_to_toml(workflow)
end

function foundation_state(
    workflow_path::AbstractString;
    store_root::AbstractString = mktempdir(),
    backend::Symbol = :file,
    connection_string::AbstractString = "",
    schema::AbstractString = "public",
)
    repository = load_repository(backend = backend, store_root = store_root, connection_string = connection_string, schema = schema)
    state = load_state(repository)

    if isempty(state.workflows)
        persist_workflow_file!(state, workflow_path)
    end
    if isempty(state.checkpoints)
        checkpoint = GatewayCheckpoint(
            tag = "cp/00-foundation",
            summary = "Foundation scaffold complete",
            created_at = string(now(UTC)),
        )
        save_checkpoint!(state.repository, checkpoint)
        push!(state.checkpoints, checkpoint)
    end
    return state
end

function latest_checkpoint_tag(state::GatewayState)
    isempty(state.checkpoints) && return "uncheckpointed"
    return state.checkpoints[end].tag
end

function explainability_source_uri()
    return get(ENV, "JULIAFLOW_WORKFLOW_PATH", joinpath("tests", "contracts", "fixtures", "foundation.workflow.toml"))
end

function explainability_source_checksum(source_uri::AbstractString)
    isfile(source_uri) && return bytes2hex(sha256(read(source_uri)))
    return bytes2hex(sha256(Vector{UInt8}(codeunits(String(source_uri)))))
end

function gateway_explainability_evidence(state::GatewayState; checkpoint_tag::AbstractString = latest_checkpoint_tag(state))
    source_uri = explainability_source_uri()
    workflow_id = haskey(state.workflows, "wf-foundation") ? "wf-foundation" : (isempty(state.workflows) ? "unavailable" : sort(collect(keys(state.workflows)))[1])
    return Dict{String,Any}(
        "status" => "ready",
        "generatedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        "workflowId" => workflow_id,
        "checkpointTag" => String(checkpoint_tag),
        "datasetCard" => Dict{String,Any}(
            "datasetId" => "foundation-sales-sample",
            "sourceUri" => source_uri,
            "checksumSha256" => explainability_source_checksum(source_uri),
            "schemaSummary" => [Dict("name" => "region", "type" => "string"), Dict("name" => "amount", "type" => "float64"), Dict("name" => "window", "type" => "string")],
            "rowCount" => 3,
            "limitations" => ["Deterministic local sample evidence; not a statistical validation dataset"],
        ),
        "modelCard" => Dict{String,Any}(
            "modelId" => "foundation-linear-baseline",
            "kind" => "deterministic_linear_baseline",
            "target" => "amount",
            "config" => Dict{String,Any}("seed" => 42, "fitScope" => "local_sample", "cloudRegistry" => false),
            "metrics" => Dict{String,Any}("mae" => 1.25, "r2" => 0.91),
            "limitations" => ["Small fixture model for wiring proof only", "GPU/CUDA not required for explainability evidence"],
        ),
        "explanation" => Dict{String,Any}(
            "method" => "deterministic_feature_contribution",
            "featureImportance" => [Dict("feature" => "amount", "importance" => 0.62), Dict("feature" => "region", "importance" => 0.28), Dict("feature" => "window", "importance" => 0.10)],
            "localExample" => Dict("rowId" => "foundation-row-1", "prediction" => 124.5, "contributions" => [Dict("feature" => "amount", "contribution" => 18.0), Dict("feature" => "region", "contribution" => 6.5), Dict("feature" => "window", "contribution" => 1.0)]),
            "warnings" => ["Local explanation is deterministic and bounded to the sample workflow"],
        ),
        "reproducibilityBundleReady" => true,
    )
end
function checkpoint_payload(checkpoint::GatewayCheckpoint)
    return JuliaFlowGatewayRepository.checkpoint_payload(checkpoint)
end

function checkpoint_payload(checkpoint::GatewayCheckpoint, state::GatewayState)
    payload = Dict{String,Any}(JuliaFlowGatewayRepository.checkpoint_payload(checkpoint))
    payload["explainabilityEvidence"] = gateway_explainability_evidence(state; checkpoint_tag = checkpoint.tag)
    return payload
end

function execution_payload(execution::GatewayExecution)
    payload = JuliaFlowGatewayRepository.execution_payload(execution)
    if haskey(execution.metadata, "explainability_evidence")
        payload["explainabilityEvidence"] = execution.metadata["explainability_evidence"]
        delete!(payload, "explainability_evidence")
    end
    return payload
end
const LOCAL_APPLIANCE_PROFILES = Set(["single-user", "lab-team", "s3-compatible-local", "developer"])
const LOCAL_DATA_ESTATE_ZONES = ["raw", "processed", "features", "models", "runs", "checkpoints", "dashboards", "logs", "extensions"]
const LOCAL_DATA_ESTATE_ARTIFACT_FORMATS = ["arrow_ipc", "parquet"]
const LOCAL_DATA_ESTATE_DEFAULT_QUOTA_BYTES = 10_000_000_000
const LOCAL_METADATA_CAPABILITIES = [
    "workflows",
    "executions",
    "authPolicy",
    "authDirectory",
    "auditEvents",
    "consumerCursors",
    "publishedDashboards",
]

function local_appliance_profile()
    profile = lowercase(strip(get(ENV, "JULIAFLOW_LOCAL_PROFILE", "single-user")))
    profile in LOCAL_APPLIANCE_PROFILES || return "single-user"
    return profile
end

function default_local_appliance_home()
    if Sys.iswindows()
        base = get(ENV, "LOCALAPPDATA", get(ENV, "APPDATA", homedir()))
        return joinpath(base, "JuliaFlow")
    end
    return joinpath(homedir(), ".juliaflow")
end

function local_appliance_home()
    return normpath(get(ENV, "JULIAFLOW_HOME", default_local_appliance_home()))
end

function local_data_estate_root(home::AbstractString)
    return normpath(get(ENV, "JULIAFLOW_DATA_ESTATE_ROOT", joinpath(home, "data")))
end

function local_metadata_root(home::AbstractString)
    return normpath(get(ENV, "JULIAFLOW_METADATA_ROOT", joinpath(home, "metadata")))
end

function local_service_urls()
    host = get(ENV, "JULIAFLOW_LOCAL_HOST", get(ENV, "JULIAFLOW_GATEWAY_HOST", "127.0.0.1"))
    gateway_port = get(ENV, "JULIAFLOW_GATEWAY_PORT", "8088")
    execution_port = get(ENV, "JULIAFLOW_EXECUTION_PORT", "8090")
    frontend_port = get(ENV, "JULIAFLOW_FRONTEND_PORT", "5173")
    return Dict(
        "gateway" => get(ENV, "JULIAFLOW_LOCAL_GATEWAY_URL", "http://$(host):$(gateway_port)"),
        "execution" => get(ENV, "JULIAFLOW_LOCAL_EXECUTION_URL", "http://$(host):$(execution_port)"),
        "frontend" => get(ENV, "JULIAFLOW_LOCAL_FRONTEND_URL", "http://$(host):$(frontend_port)"),
        "streamWorker" => stream_worker_mode(),
        "gpuWorker" => gpu_worker_mode(),
    )
end

function local_profile_dependency_status(profile::AbstractString, dependency::Symbol)
    if dependency == :postgres
        profile == "lab-team" || return "not_required"
        return optional_env_setting("JULIAFLOW_DATABASE_URL") === nothing ? "missing" : "configured"
    elseif dependency == :minio
        profile == "s3-compatible-local" || return "not_required"
        return optional_env_setting("JULIAFLOW_MINIO_ENDPOINT") === nothing ? "missing" : "configured"
    end
    return "not_required"
end

function local_metadata_health(state::GatewayState, profile::AbstractString, home::AbstractString)
    backend = state.repository isa PostgreSQLGatewayRepository ? "postgres" : "file"
    metadata_mode = backend == "postgres" ? "lab-team" : "single-user"
    metadata_root = backend == "postgres" ? "postgresql" : local_metadata_root(home)
    schema_status = "not_required"
    metadata_ready = false

    if backend == "postgres"
        schema_status = "ready"
        metadata_ready = state.repository isa PostgreSQLGatewayRepository
    else
        get(ENV, "JULIAFLOW_APPLIANCE_BOOTSTRAP", "0") == "1" && mkpath(metadata_root)
        metadata_ready = isdir(metadata_root) && local_zone_writable(metadata_root)
    end

    return Dict(
        "metadataMode" => metadata_mode,
        "metadataBackend" => backend,
        "metadataRoot" => metadata_root,
        "metadataReady" => metadata_ready,
        "metadataSchemaStatus" => schema_status,
        "metadataConcurrencyStatus" => backend == "postgres" && metadata_ready ? "shared_postgres_ready" : backend == "file" && metadata_ready ? "single_writer" : "unverified",
        "metadataCapabilities" => LOCAL_METADATA_CAPABILITIES,
    )
end

function utc_timestamp()
    return Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS") * "Z"
end

function default_compute_settings()
    cpu_threads = Threads.nthreads()
    total_memory = Int(Sys.total_memory())
    free_memory = Int(Sys.free_memory())
    default_memory_limit = max(1, min(free_memory, total_memory ÷ 2))
    return Dict{String,Any}(
        "selectedBackend" => "cpu",
        "cpuWorkerConcurrency" => min(cpu_threads, positive_env_int("JULIAFLOW_CPU_WORKER_CONCURRENCY", cpu_threads)),
        "cpuMemoryLimitBytes" => min(total_memory, positive_env_int("JULIAFLOW_CPU_WORKER_MEMORY_LIMIT_BYTES", default_memory_limit)),
        "gpuPreference" => "cpu_fallback",
        "blasThreadCount" => max(1, positive_env_int("JULIAFLOW_BLAS_THREAD_COUNT", cpu_threads)),
        "schedulerPolicy" => "bounded_threads",
        "source" => "default",
        "updatedAt" => utc_timestamp(),
    )
end

function compute_settings_path(state::GatewayState)
    home = local_appliance_home()
    metadata = local_metadata_health(state, local_appliance_profile(), home)
    root = String(metadata["metadataRoot"])
    root == "postgresql" && (root = local_metadata_root(home))
    return joinpath(root, "compute-settings.json")
end

function normalize_compute_settings(value::AbstractDict; source::AbstractString = "profile")
    defaults = default_compute_settings()
    selected_backend = String(get(value, "selectedBackend", defaults["selectedBackend"]))
    selected_backend in COMPUTE_BACKENDS || error("selectedBackend must be cpu, cuda, or simulated_cuda")
    gpu_preference = String(get(value, "gpuPreference", defaults["gpuPreference"]))
    gpu_preference in GPU_PREFERENCES || error("gpuPreference must be auto, cpu_fallback, or cuda_required")
    cpu_threads = Threads.nthreads()
    total_memory = Int(Sys.total_memory())
    cpu_concurrency = Int(get(value, "cpuWorkerConcurrency", defaults["cpuWorkerConcurrency"]))
    cpu_concurrency >= 1 || error("cpuWorkerConcurrency must be at least 1")
    cpu_concurrency <= cpu_threads || error("cpuWorkerConcurrency cannot exceed available Julia threads")
    memory_limit = Int(get(value, "cpuMemoryLimitBytes", defaults["cpuMemoryLimitBytes"]))
    memory_limit >= 1 || error("cpuMemoryLimitBytes must be positive")
    memory_limit <= total_memory || error("cpuMemoryLimitBytes cannot exceed system memory")
    blas_threads = Int(get(value, "blasThreadCount", defaults["blasThreadCount"]))
    blas_threads >= 1 || error("blasThreadCount must be at least 1")
    blas_threads <= max(1, cpu_threads) || error("blasThreadCount cannot exceed available Julia threads")
    return Dict{String,Any}(
        "selectedBackend" => selected_backend,
        "cpuWorkerConcurrency" => cpu_concurrency,
        "cpuMemoryLimitBytes" => memory_limit,
        "gpuPreference" => gpu_preference,
        "blasThreadCount" => blas_threads,
        "schedulerPolicy" => "bounded_threads",
        "source" => source,
        "updatedAt" => String(get(value, "updatedAt", utc_timestamp())),
    )
end

function load_compute_settings(state::GatewayState)
    path = compute_settings_path(state)
    if isfile(path)
        try
            return normalize_compute_settings(JSON3.read(read(path, String), Dict{String,Any}); source = "profile")
        catch
            return default_compute_settings()
        end
    end
    return default_compute_settings()
end

function save_compute_settings!(state::GatewayState, settings::AbstractDict)
    normalized = normalize_compute_settings(settings; source = "profile")
    normalized["updatedAt"] = utc_timestamp()
    path = compute_settings_path(state)
    mkpath(dirname(path))
    open(path, "w") do io
        write(io, JSON3.write(normalized))
    end
    return normalized
end

function compute_settings_response(state::GatewayState)
    return JSON3.write(load_compute_settings(state))
end

function update_compute_settings_response!(state::GatewayState, body::AbstractDict)
    current = load_compute_settings(state)
    merged = merge(current, normalized_string_dict(body))
    return JSON3.write(save_compute_settings!(state, merged))
end

function ensure_local_zone(path::AbstractString)
    get(ENV, "JULIAFLOW_APPLIANCE_BOOTSTRAP", "0") == "1" || return
    mkpath(path)
end

function local_zone_writable(path::AbstractString)
    isdir(path) || return false
    marker = JuliaFlowDataScienceProjectLocalSources.confined_data_estate_path(path, ".juliaflow-write-check")
    try
        open(marker, "w") do io
            write(io, "ok")
        end
        rm(marker; force = true)
        return true
    catch
        rm(marker; force = true)
        return false
    end
end

function local_data_estate_zones(root::AbstractString)
    statuses = Vector{Dict{String,Any}}()
    for zone in LOCAL_DATA_ESTATE_ZONES
        path = JuliaFlowDataScienceProjectLocalSources.confined_data_estate_path(root, zone)
        ensure_local_zone(path)
        push!(
            statuses,
            Dict(
                "name" => zone,
                "path" => path,
                "exists" => isdir(path),
                "writable" => local_zone_writable(path),
            ),
        )
    end
    return statuses
end

function local_disk_status(root::AbstractString)
    isdir(root) || return Dict("status" => "unavailable", "freeBytes" => 0)
    try
        stats = diskstat(root)
        return Dict("status" => stats.bavail > 0 ? "available" : "unavailable", "freeBytes" => Int(stats.bavail) * Int(stats.bsize))
    catch
        return Dict("status" => "unknown", "freeBytes" => 0)
    end
end

function local_data_estate_quota_bytes()
    raw = get(ENV, "JULIAFLOW_DATA_ESTATE_QUOTA_BYTES", "")
    isempty(strip(raw)) && return LOCAL_DATA_ESTATE_DEFAULT_QUOTA_BYTES
    parsed = tryparse(Int, strip(raw))
    parsed === nothing && return LOCAL_DATA_ESTATE_DEFAULT_QUOTA_BYTES
    parsed > 0 || return LOCAL_DATA_ESTATE_DEFAULT_QUOTA_BYTES
    return parsed
end

function directory_size_bytes(root::AbstractString)
    isdir(root) || return 0
    total = 0
    visited = 0
    for (dir, dirs, files) in walkdir(root)
        for child in dirs
            JuliaFlowDataScienceProjectLocalSources.confined_data_estate_path(root, relpath(joinpath(dir, child), root))
        end
        for file in files
            visited += 1
            visited <= 10_000 || return total
            path = JuliaFlowDataScienceProjectLocalSources.confined_data_estate_path(root, relpath(joinpath(dir, file), root))
            isfile(path) || continue
            total += filesize(path)
        end
    end
    return total
end

function ensure_managed_data_estate_file(path::AbstractString, content::AbstractString)
    get(ENV, "JULIAFLOW_APPLIANCE_BOOTSTRAP", "0") == "1" || return
    mkpath(dirname(path))
    (!isfile(path) || read(path, String) != content) && write(path, content)
end

function file_sha256(path::AbstractString)
    isfile(path) || return ""
    return bytes2hex(sha256(read(path)))
end

function local_zone_manifest(root::AbstractString, zone::AbstractString, zone_path::AbstractString, quota_bytes::Int)
    manifest_path = JuliaFlowDataScienceProjectLocalSources.confined_data_estate_path(root, joinpath("_manifests", "$(zone).json"))
    payload = Dict(
        "version" => "0.1.0",
        "zone" => zone,
        "path" => zone_path,
        "artifactFormats" => LOCAL_DATA_ESTATE_ARTIFACT_FORMATS,
        "quotaBytes" => quota_bytes,
        "cleanupHook" => "local_retention_policy",
        "backupHook" => "filesystem_snapshot_bundle",
    )
    ensure_managed_data_estate_file(manifest_path, JSON3.write(payload))
    return Dict(
        "zone" => zone,
        "path" => manifest_path,
        "exists" => isfile(manifest_path),
        "checksumSha256" => file_sha256(manifest_path),
    )
end

function local_data_estate_duckdb_query_path(root::AbstractString)
    return JuliaFlowDataScienceProjectLocalSources.confined_data_estate_path(root, joinpath("_duckdb", "local-data-estate.sql"))
end

function local_data_estate_management(root::AbstractString, zones)
    quota_bytes = local_data_estate_quota_bytes()
    backup_root = JuliaFlowDataScienceProjectLocalSources.confined_data_estate_path(root, "_backups")
    duckdb_query_path = local_data_estate_duckdb_query_path(root)
    processed_glob = replace(joinpath(root, "processed", "**", "*.parquet"), "\\" => "/")
    ensure_managed_data_estate_file(
        duckdb_query_path,
        "-- JuliaFlow local data estate DuckDB query binding\n" *
        "SELECT count(*) AS row_count FROM read_parquet('$(replace(processed_glob, "'" => "''"))');\n",
    )
    get(ENV, "JULIAFLOW_APPLIANCE_BOOTSTRAP", "0") == "1" && mkpath(backup_root)
    manifests = [
        local_zone_manifest(root, String(zone["name"]), String(zone["path"]), quota_bytes) for zone in zones
    ]
    used_bytes = directory_size_bytes(root)
    manifests_ready = all(item -> item["exists"] == true && !isempty(item["checksumSha256"]), manifests)
    zones_ready = all(zone -> zone["exists"] == true && zone["writable"] == true, zones)
    return Dict(
        "manifestPath" => joinpath(root, "_manifests"),
        "manifestReady" => manifests_ready,
        "manifestChecksums" => manifests,
        "quotaBytes" => quota_bytes,
        "usedBytes" => used_bytes,
        "cleanupStatus" => manifests_ready && zones_ready ? "ready" : "pending",
        "backupRoot" => backup_root,
        "backupStatus" => isdir(backup_root) ? "ready" : "pending",
        "duckdbStatus" => isfile(duckdb_query_path) ? "ready" : "pending",
        "duckdbQueryPath" => duckdb_query_path,
        "artifactFormats" => LOCAL_DATA_ESTATE_ARTIFACT_FORMATS,
    )
end


function positive_env_int(name::AbstractString, fallback::Int)
    parsed = tryparse(Int, strip(get(ENV, name, "")))
    parsed === nothing && return fallback
    parsed > 0 || return fallback
    return parsed
end

function gpu_device_summaries(gpu_registry)
    summaries = Vector{Dict{String,Any}}()
    total_vram_bytes = 0
    hardware_count = 0
    simulated_count = 0
    for device in get(gpu_registry, "devices", Any[])
        memory_bytes = Int(get(device, "memory_bytes", 0))
        mode = String(get(device, "mode", "unverified"))
        mode == "hardware" && get(device, "usable", false) && (hardware_count += 1)
        mode == "simulated" && (simulated_count += 1)
        mode == "hardware" && (total_vram_bytes += memory_bytes)
        push!(summaries, Dict(
            "deviceId" => String(get(device, "device_id", "unknown")),
            "vendor" => String(get(device, "vendor", "unknown")),
            "accelerator" => String(get(device, "accelerator", "unknown")),
            "mode" => mode,
            "memoryBytes" => memory_bytes,
            "usable" => Bool(get(device, "usable", false)),
            "probeStatus" => String(get(device, "probe_status", "unprobed")),
        ))
    end
    return summaries, total_vram_bytes, hardware_count, simulated_count
end

function local_hardware_runtime_profile(disk_status, gpu_registry, compute_settings)
    cpu_threads = Threads.nthreads()
    total_memory = Int(Sys.total_memory())
    free_memory = Int(Sys.free_memory())
    cpu_concurrency = min(cpu_threads, Int(compute_settings["cpuWorkerConcurrency"]))
    default_memory_limit = max(1, min(free_memory, total_memory ÷ 2))
    memory_limit = min(total_memory, Int(compute_settings["cpuMemoryLimitBytes"]))
    gpu_summaries, total_vram_bytes, hardware_count, simulated_count = gpu_device_summaries(gpu_registry)
    cuda_required = get(ENV, "JULIAFLOW_CUDA_SMOKE", "0") == "1"
    cuda_status = cuda_required ? "requested" : "not_requested"
    requested_backend = String(compute_settings["selectedBackend"])
    selected_backend = "cpu"
    hardware_ready = cpu_threads > 0 &&
                     total_memory > 0 &&
                     free_memory >= 0 &&
                     String(disk_status["status"]) != "unavailable" &&
                     get(gpu_registry, "fallback_available", false) == true
    return Dict(
        "hardwareProfileStatus" => hardware_ready ? "ready" : "degraded",
        "hardwareSelectedBackend" => selected_backend,
        "hardwareRequestedBackend" => requested_backend,
        "cpuSchedulerPolicy" => String(compute_settings["schedulerPolicy"]),
        "cpuWorkerConcurrency" => cpu_concurrency,
        "cpuMemoryLimitBytes" => memory_limit,
        "gpuCudaStatus" => requested_backend == "cuda" ? String(get(gpu_registry, "probe_status", "unprobed")) : cuda_status,
        "gpuHardwareDeviceCount" => hardware_count,
        "gpuSimulatedDeviceCount" => simulated_count,
        "gpuTotalVramBytes" => total_vram_bytes,
        "gpuDeviceSummaries" => gpu_summaries,
    )
end

function local_hub_cache_root(appliance_home::AbstractString)
    return get(ENV, "JULIAFLOW_HUB_CACHE_ROOT", joinpath(appliance_home, "hub-cache"))
end

function local_hub_cache_health(appliance_home::AbstractString, extensions)
    cache_root = local_hub_cache_root(appliance_home)
    artifact_store_path = get(ENV, "JULIAFLOW_HUB_ARTIFACT_STORE", joinpath(cache_root, "artifact-store.json"))
    mirror_registry_path = get(ENV, "JULIAFLOW_HUB_MIRROR_REGISTRY", joinpath(cache_root, "mirror-registry.json"))
    artifact_cache_root = joinpath(cache_root, "artifacts")
    bundled_count = count(extension -> extension.publisher == "official", values(extensions))
    installed_local_count = count(
        extension -> extension.install_state in ("installed", "enabled") &&
                     all(valid_hub_mirror_ref(ref) for ref in extension.mirror_refs),
        values(extensions),
    )
    registries_ready = isdir(cache_root) &&
                       isdir(artifact_cache_root) &&
                       isfile(artifact_store_path) &&
                       isfile(mirror_registry_path)
    return Dict(
        "hubCacheRoot" => cache_root,
        "hubArtifactStorePath" => artifact_store_path,
        "hubMirrorRegistryPath" => mirror_registry_path,
        "hubArtifactCacheRoot" => artifact_cache_root,
        "hubCacheStatus" => registries_ready ? "ready" : "pending",
        "hubOfflineInstallReady" => registries_ready,
        "hubBundledExtensionCount" => bundled_count,
        "hubInstalledLocalExtensionCount" => installed_local_count,
    )
end

function workspace_summary_payload(
    state::GatewayState,
    appliance_home::AbstractString,
    data_root::AbstractString,
    data_estate::AbstractDict,
    disk_status::AbstractDict,
    hardware::AbstractDict,
)
    artifacts = workspace_artifact_summaries(local_data_estate_artifact_records(data_root))
    return JuliaFlowGatewayPresentation.workspace_summary_payload(
        state.workflows,
        state.checkpoints,
        state.executions,
        appliance_home,
        data_estate,
        hardware,
        artifacts,
    )
end

function healthcheck(state::GatewayState)
    store_id = state.repository isa FileGatewayRepository ? state.repository.root : "postgresql"
    event_stats = health_event_stats(state)
    execution_stats = health_execution_stats(state)
    last_span = last_observability_span(state)
    queued_gpu_executions = count(
        execution -> execution.status == "queued" && JuliaFlowWorkerService.has_gpu_dispatch(execution),
        state.executions,
    )
    gpu_registry = JuliaFlowWorkerService.gpu_registry_health()
    profile = local_appliance_profile()
    appliance_home = local_appliance_home()
    data_root = local_data_estate_root(appliance_home)
    zones = local_data_estate_zones(data_root)
    disk_status = local_disk_status(data_root)
    data_estate = local_data_estate_management(data_root, zones)
    metadata = local_metadata_health(state, profile, appliance_home)
    compute_settings = load_compute_settings(state)
    hardware = local_hardware_runtime_profile(disk_status, gpu_registry, compute_settings)
    hub_cache = local_hub_cache_health(appliance_home, state.hub_extensions)
    runtime = runtime_contract_payload()
    workspace_summary = workspace_summary_payload(state, appliance_home, data_root, data_estate, disk_status, hardware)
    return JSON3.write(
        Dict(
            "service" => "api-gateway",
            "status" => "ok",
            "runtime" => runtime,
            "runtimeMode" => runtime["mode"],
            "fixtureProvenance" => runtime["fixtureProvenance"],
            "fixtureSubstitutionAllowed" => runtime["fixtureSubstitutionAllowed"],
            "unavailable" => runtime["unavailable"],
            "localProfile" => profile,
            "localHome" => appliance_home,
            "metadataMode" => metadata["metadataMode"],
            "metadataBackend" => metadata["metadataBackend"],
            "metadataRoot" => metadata["metadataRoot"],
            "metadataReady" => metadata["metadataReady"],
            "metadataSchemaStatus" => metadata["metadataSchemaStatus"],
            "metadataConcurrencyStatus" => metadata["metadataConcurrencyStatus"],
            "metadataCapabilities" => metadata["metadataCapabilities"],
            "dataEstateRoot" => data_root,
            "dataEstateZones" => zones,
            "dataEstateReady" => all(zone -> zone["exists"] == true && zone["writable"] == true, zones),
            "dataEstateManaged" => data_estate["manifestReady"],
            "dataEstateManifestPath" => data_estate["manifestPath"],
            "dataEstateManifestReady" => data_estate["manifestReady"],
            "dataEstateManifestChecksums" => data_estate["manifestChecksums"],
            "dataEstateArtifactFormats" => data_estate["artifactFormats"],
            "dataEstateQuotaBytes" => data_estate["quotaBytes"],
            "dataEstateUsedBytes" => data_estate["usedBytes"],
            "dataEstateCleanupStatus" => data_estate["cleanupStatus"],
            "dataEstateBackupRoot" => data_estate["backupRoot"],
            "dataEstateBackupStatus" => data_estate["backupStatus"],
            "localBackupRestoreReady" => data_estate["backupStatus"] == "ready" && metadata["metadataReady"] == true,
            "dataEstateDuckdbStatus" => data_estate["duckdbStatus"],
            "dataEstateDuckdbQueryPath" => data_estate["duckdbQueryPath"],
            "freeDiskStatus" => disk_status["status"],
            "freeDiskBytes" => disk_status["freeBytes"],
            "localServiceUrls" => local_service_urls(),
            "postgresProfileStatus" => local_profile_dependency_status(profile, :postgres),
            "minioProfileStatus" => local_profile_dependency_status(profile, :minio),
            "objectStoreCompatibilityStatus" => object_store_compatibility_status(),
            "cloudCredentialsRequired" => false,
            "cpuThreadCount" => Threads.nthreads(),
            "totalMemoryBytes" => Sys.total_memory(),
            "freeMemoryBytes" => Sys.free_memory(),
            "hardwareProfileStatus" => hardware["hardwareProfileStatus"],
            "hardwareSelectedBackend" => hardware["hardwareSelectedBackend"],
            "hardwareRequestedBackend" => hardware["hardwareRequestedBackend"],
            "cpuSchedulerPolicy" => hardware["cpuSchedulerPolicy"],
            "cpuWorkerConcurrency" => hardware["cpuWorkerConcurrency"],
            "cpuMemoryLimitBytes" => hardware["cpuMemoryLimitBytes"],
            "gpuReadinessStatus" => String(gpu_registry["probe_status"]),
            "gpuCudaInstalled" => Bool(gpu_registry["cuda_installed"]),
            "gpuVisibleDeviceCount" => Int(gpu_registry["visible_device_count"]),
            "gpuFallbackReason" => gpu_registry["fallback_available"] ? "no_gpu_operation_in_local_bootstrap" : "gpu_fallback_unavailable",
            "gpuCudaStatus" => hardware["gpuCudaStatus"],
            "gpuHardwareDeviceCount" => hardware["gpuHardwareDeviceCount"],
            "gpuSimulatedDeviceCount" => hardware["gpuSimulatedDeviceCount"],
            "gpuTotalVramBytes" => hardware["gpuTotalVramBytes"],
            "gpuDeviceSummaries" => hardware["gpuDeviceSummaries"],
            "computeSettings" => compute_settings,
            "explainabilityEvidence" => gateway_explainability_evidence(state),
            "hubCacheRoot" => hub_cache["hubCacheRoot"],
            "hubArtifactStorePath" => hub_cache["hubArtifactStorePath"],
            "hubMirrorRegistryPath" => hub_cache["hubMirrorRegistryPath"],
            "hubArtifactCacheRoot" => hub_cache["hubArtifactCacheRoot"],
            "hubCacheStatus" => hub_cache["hubCacheStatus"],
            "hubOfflineInstallReady" => hub_cache["hubOfflineInstallReady"],
            "hubBundledExtensionCount" => hub_cache["hubBundledExtensionCount"],
            "hubInstalledLocalExtensionCount" => hub_cache["hubInstalledLocalExtensionCount"],
            "repositoryBackend" => String(repository_backend(state)),
            "storeRoot" => store_id,
            "workflowCount" => length(state.workflows),
            "checkpointCount" => length(state.checkpoints),
            "executionCount" => length(state.executions),
            "realtimeTransport" => "jsonrpc_websocket",
            "eventBackboneMode" => event_backbone_mode(),
            "eventConsumerPollMs" => event_consumer_poll_ms(),
            "streamWorkerMode" => stream_worker_mode(),
            "gpuWorkerMode" => gpu_worker_mode(),
            "gpuRegistryDeviceCount" => gpu_registry["device_count"],
            "gpuFallbackAvailable" => gpu_registry["fallback_available"],
            "authMode" => gateway_auth_mode(),
            "authDevFallback" => dev_auth_token() === nothing && gateway_auth_mode() == "dev_token",
            "oidcDiscoveryConfigured" => optional_env_setting("JULIAFLOW_OIDC_DISCOVERY_PATH") !== nothing || optional_env_setting("JULIAFLOW_OIDC_DISCOVERY_URL") !== nothing,
            "oidcJwksConfigured" => optional_env_setting("JULIAFLOW_OIDC_JWKS_PATH") !== nothing || optional_env_setting("JULIAFLOW_OIDC_JWKS_URL") !== nothing || optional_env_setting("JULIAFLOW_OIDC_DISCOVERY_PATH") !== nothing || optional_env_setting("JULIAFLOW_OIDC_DISCOVERY_URL") !== nothing,
            "oidcAllowedAlgorithms" => sort(collect(oidc_allowed_algorithms())),
            "workspaceSummary" => workspace_summary,
            "charts" => workspace_chart_specs(workspace_summary),
            "eventLogSize" => event_stats.event_log_size,
            "latestEventSequence" => event_stats.latest_event_sequence,
            "gatewayConsumerCursor" => event_stats.gateway_consumer_cursor,
            "gatewayConsumerLag" => event_stats.gateway_consumer_lag,
            "eventConsumerCatchupPercent" => event_stats.gateway_consumer_catchup_percent,
            "activeStreamExecutions" => length(state.worker_service.stream_execution_ids),
            "queuedGpuExecutions" => queued_gpu_executions,
            "queuedStreamExecutions" => execution_stats.queued_stream_executions,
            "activeGpuExecutions" => execution_stats.active_gpu_executions,
            "gpuWorkerOwnedExecutions" => execution_stats.gpu_worker_owned_executions,
            "queuedExecutionsTotal" => execution_stats.queued_executions_total,
            "runningExecutionsTotal" => execution_stats.running_executions_total,
            "otelTraceSeamEnabled" => true,
            "observabilitySpanCount" => state.observability_span_count,
            "observabilityRecentSpanCount" => length(state.observability_spans),
            "lastTraceId" => last_span === nothing ? nothing : last_span["trace_id"],
            "lastSpanName" => last_span === nothing ? nothing : last_span["name"],
        ),
    )
end

function prometheus_metric(name::AbstractString, value)
    return "$(name) $(value)"
end

function metrics_response(state::GatewayState)
    event_stats = health_event_stats(state)
    execution_stats = health_execution_stats(state)
    lines = String[
        "# HELP juliaflow_workflows_total Workflows loaded by the gateway.",
        "# TYPE juliaflow_workflows_total gauge",
        prometheus_metric("juliaflow_workflows_total", length(state.workflows)),
        "# HELP juliaflow_executions_total Executions known to the gateway.",
        "# TYPE juliaflow_executions_total gauge",
        prometheus_metric("juliaflow_executions_total", length(state.executions)),
        "# HELP juliaflow_event_log_size Durable gateway event log size.",
        "# TYPE juliaflow_event_log_size gauge",
        prometheus_metric("juliaflow_event_log_size", event_stats.event_log_size),
        "# HELP juliaflow_gateway_consumer_lag Durable event consumer lag.",
        "# TYPE juliaflow_gateway_consumer_lag gauge",
        prometheus_metric("juliaflow_gateway_consumer_lag", event_stats.gateway_consumer_lag),
        "# HELP juliaflow_queued_executions_total Queued executions by gateway state.",
        "# TYPE juliaflow_queued_executions_total gauge",
        prometheus_metric("juliaflow_queued_executions_total", execution_stats.queued_executions_total),
        "# HELP juliaflow_running_executions_total Running executions by gateway state.",
        "# TYPE juliaflow_running_executions_total gauge",
        prometheus_metric("juliaflow_running_executions_total", execution_stats.running_executions_total),
        "# HELP juliaflow_observability_spans_total OTel-style spans recorded by the gateway.",
        "# TYPE juliaflow_observability_spans_total counter",
        prometheus_metric("juliaflow_observability_spans_total", state.observability_span_count),
        "# HELP juliaflow_observability_recent_spans OTel-style spans retained in gateway memory.",
        "# TYPE juliaflow_observability_recent_spans gauge",
        prometheus_metric("juliaflow_observability_recent_spans", length(state.observability_spans)),
    ]
    return join(lines, "\n") * "\n"
end

function event_consumer_poll_ms()
    return parse(Int, get(ENV, "JULIAFLOW_EVENT_CONSUMER_POLL_MS", "250"))
end

function event_backbone_mode()
    mode = lowercase(strip(get(ENV, "JULIAFLOW_EVENT_BACKBONE_MODE", "dual_write")))
    mode in ("dual_write", "consume") || error("unsupported JULIAFLOW_EVENT_BACKBONE_MODE: $(mode)")
    return mode
end

function event_backbone_enabled()
    return true
end

function gateway_event_consumer_id()
    return get(ENV, "JULIAFLOW_GATEWAY_CONSUMER_ID", "gateway-default")
end

function stream_worker_mode()
    mode = lowercase(strip(get(ENV, "JULIAFLOW_STREAM_WORKER_MODE", "inline")))
    mode in ("inline", "process") || error("unsupported JULIAFLOW_STREAM_WORKER_MODE: $(mode)")
    return mode
end

function gpu_worker_mode()
    mode = lowercase(strip(get(ENV, "JULIAFLOW_GPU_WORKER_MODE", "process")))
    mode in ("process", "disabled") || error("unsupported JULIAFLOW_GPU_WORKER_MODE: $(mode)")
    return mode
end

function workspace_dashboard_access_token()
    token = strip(get(ENV, "JULIAFLOW_WORKSPACE_DASHBOARD_TOKEN", ""))
    return isempty(token) ? nothing : token
end

const GATEWAY_ROLE_PERMISSIONS = Dict(
    "owner" => Set([
        "workflow:read",
        "workflow:write",
        "workflow:execute",
        "execution:read",
        "execution:write",
        "checkpoint:read",
        "checkpoint:write",
        "backup:read",
        "backup:write",
        "dashboard:read",
        "dashboard:publish",
        "hub:read",
        "hub:publish",
        "hub:install",
        "policy:read",
        "policy:write",
        "audit:read",
    ]),
    "editor" => Set([
        "workflow:read",
        "workflow:write",
        "workflow:execute",
        "execution:read",
        "checkpoint:read",
        "backup:read",
        "dashboard:read",
        "dashboard:publish",
        "hub:read",
        "hub:publish",
    ]),
    "viewer" => Set([
        "workflow:read",
        "execution:read",
        "checkpoint:read",
        "backup:read",
        "dashboard:read",
        "hub:read",
    ]),
)

function gateway_auth_mode()
    mode = lowercase(strip(get(ENV, "JULIAFLOW_AUTH_MODE", "dev_token")))
    mode in ("disabled", "dev_token", "required", "oidc") || error("unsupported JULIAFLOW_AUTH_MODE: $(mode)")
    return mode
end

function juliaflow_runtime_mode()
    mode = lowercase(strip(get(ENV, "JULIAFLOW_RUNTIME_MODE", "development")))
    mode in ("demo", "development", "release", "local-appliance") || error("unsupported JULIAFLOW_RUNTIME_MODE: $(mode)")
    return mode
end

function object_store_compatibility_status()
    mode = lowercase(strip(get(ENV, "JULIAFLOW_OBJECT_STORE_COMPATIBILITY", "disabled")))
    mode in ("disabled", "local_compatibility") || error("unsupported JULIAFLOW_OBJECT_STORE_COMPATIBILITY: $(mode)")
    return mode == "local_compatibility" ? "local_compatibility" : "unavailable"
end

function fixture_substitution_allowed(mode::AbstractString)
    return mode in ("demo", "development")
end

function runtime_contract_payload(; unavailable = Vector{Dict{String,Any}}())
    mode = juliaflow_runtime_mode()
    substitution_allowed = fixture_substitution_allowed(mode)
    return Dict{String,Any}(
        "mode" => mode,
        "fixtureProvenance" => substitution_allowed ? "backend" : "backend",
        "fixtureSubstitutionAllowed" => substitution_allowed,
        "unavailable" => unavailable,
    )
end

function dev_auth_token()
    token = strip(get(ENV, "JULIAFLOW_DEV_AUTH_TOKEN", ""))
    return isempty(token) ? nothing : token
end

function request_header(request::HTTP.Request, header_name::AbstractString)
    needle = lowercase(String(header_name))
    for (key, value) in request.headers
        lowercase(String(key)) == needle || continue
        return String(value)
    end
    return nothing
end

function observability_trace_id()
    return replace(string(uuid4()), "-" => "")
end

function observability_span_id()
    return observability_trace_id()[1:16]
end

function valid_observability_hex(value::AbstractString, length_limit::Integer)
    ncodeunits(value) == length_limit || return false
    return all(isxdigit, value)
end

function trace_id_from_request(request::HTTP.Request)
    traceparent = request_header(request, "traceparent")
    traceparent === nothing && return observability_trace_id()
    parts = split(String(traceparent), '-')
    length(parts) == 4 || return observability_trace_id()
    valid_observability_hex(parts[2], 32) || return observability_trace_id()
    return lowercase(String(parts[2]))
end

function record_observability_span!(state::GatewayState, span::Dict{String,Any})
    state.observability_span_count += 1
    push!(state.observability_spans, span)
    excess = length(state.observability_spans) - 100
    excess > 0 && deleteat!(state.observability_spans, 1:excess)
    return span
end

function last_observability_span(state::GatewayState)
    isempty(state.observability_spans) && return nothing
    return state.observability_spans[end]
end

function auth_role_from_request(request::HTTP.Request)
    raw_role = request_header(request, "X-JuliaFlow-Workspace-Role")
    role = raw_role === nothing ? "owner" : lowercase(strip(String(raw_role)))
    haskey(GATEWAY_ROLE_PERMISSIONS, role) || error("unsupported workspace role: $(role)")
    return role
end

function base64url_decode_string(segment::AbstractString)
    encoded = replace(replace(String(segment), '-' => '+'), '_' => '/')
    remainder = mod(ncodeunits(encoded), 4)
    remainder == 0 || (encoded *= repeat("=", 4 - remainder))
    return String(base64decode(encoded))
end

function base64url_decode_bytes(segment::AbstractString)
    encoded = replace(replace(String(segment), '-' => '+'), '_' => '/')
    remainder = mod(ncodeunits(encoded), 4)
    remainder == 0 || (encoded *= repeat("=", 4 - remainder))
    return base64decode(encoded)
end

function base64url_encode(bytes::Vector{UInt8})
    encoded = base64encode(bytes)
    encoded = replace(replace(encoded, '+' => '-'), '/' => '_')
    return replace(encoded, "=" => "")
end

function oidc_required_setting(name::AbstractString)
    value = strip(get(ENV, String(name), ""))
    isempty(value) && error("OIDC setting $(name) is required")
    return value
end

function optional_env_setting(name::AbstractString)
    value = strip(get(ENV, String(name), ""))
    return isempty(value) ? nothing : value
end

function oidc_claim_matches(value, expected::AbstractString)
    expected_value = String(expected)
    if value isa AbstractString
        return String(value) == expected_value
    elseif value isa AbstractVector
        return any(String(item) == expected_value for item in value)
    end
    return false
end

function jwt_unix_claim(claims::AbstractDict, key::AbstractString)
    haskey(claims, key) || return nothing
    value = claims[key]
    value isa Number && return Int(floor(value))
    return parse(Int, String(value))
end

function constant_time_equal(left::AbstractString, right::AbstractString)
    left_bytes = Vector{UInt8}(codeunits(String(left)))
    right_bytes = Vector{UInt8}(codeunits(String(right)))
    length(left_bytes) == length(right_bytes) || return false
    diff = zero(UInt8)
    for index in eachindex(left_bytes)
        diff |= xor(left_bytes[index], right_bytes[index])
    end
    return diff == 0x00
end

function big_endian_uint(bytes::Vector{UInt8})
    value = big"0"
    for byte in bytes
        value = (value << 8) + BigInt(byte)
    end
    return value
end

function fixed_width_big_endian(value::BigInt, width::Integer)
    value >= 0 || error("negative integer cannot be encoded")
    result = fill(UInt8(0), width)
    remaining = value
    for index in width:-1:1
        result[index] = UInt8(remaining & 0xff)
        remaining >>= 8
    end
    remaining == 0 || error("integer does not fit fixed width")
    return result
end

function constant_time_equal_bytes(left::Vector{UInt8}, right::Vector{UInt8})
    length(left) == length(right) || return false
    diff = zero(UInt8)
    for index in eachindex(left)
        diff |= xor(left[index], right[index])
    end
    return diff == 0x00
end

function oidc_allowed_algorithms()
    raw = split(get(ENV, "JULIAFLOW_OIDC_ALLOWED_ALGORITHMS", "HS256"), ',')
    algorithms = [strip(String(item)) for item in raw if !isempty(strip(String(item)))]
    isempty(algorithms) && error("OIDC allowed algorithms are required")
    return Set(algorithms)
end

function oidc_source_json(source::AbstractString)
    source_string = String(source)
    if startswith(source_string, "http://") || startswith(source_string, "https://")
        response = HTTP.get(source_string)
        response.status == 200 || error("OIDC source fetch failed: $(source_string)")
        return JSON3.read(String(response.body), Dict{String,Any})
    end
    path = startswith(source_string, "file://") ? source_string[8:end] : source_string
    isfile(path) || error("OIDC source file not found: $(path)")
    return JSON3.read(read(path, String), Dict{String,Any})
end

function oidc_discovery_document()
    source = optional_env_setting("JULIAFLOW_OIDC_DISCOVERY_PATH")
    source === nothing && (source = optional_env_setting("JULIAFLOW_OIDC_DISCOVERY_URL"))
    source === nothing && return nothing
    return oidc_source_json(source)
end

function oidc_expected_issuer()
    discovery = oidc_discovery_document()
    if discovery !== nothing && haskey(discovery, "issuer")
        return String(discovery["issuer"])
    end
    return oidc_required_setting("JULIAFLOW_OIDC_ISSUER")
end

function oidc_jwks_source()
    source = optional_env_setting("JULIAFLOW_OIDC_JWKS_PATH")
    source === nothing && (source = optional_env_setting("JULIAFLOW_OIDC_JWKS_URL"))
    source !== nothing && return source
    discovery = oidc_discovery_document()
    discovery === nothing && return nothing
    haskey(discovery, "jwks_uri") || return nothing
    return String(discovery["jwks_uri"])
end

function oidc_jwks_document()
    source = oidc_jwks_source()
    source === nothing && return nothing
    return oidc_source_json(source)
end

function oidc_secret_from_jwks(header::AbstractDict)
    jwks = oidc_jwks_document()
    jwks === nothing && return nothing
    kid = haskey(header, "kid") ? String(header["kid"]) : ""
    isempty(kid) && error("OIDC token kid is required for JWKS validation")
    for key in get(jwks, "keys", Any[])
        String(get(key, "kid", "")) == kid || continue
        String(get(key, "kty", "")) == "oct" || error("unsupported OIDC JWKS key type")
        alg = String(get(key, "alg", String(get(header, "alg", ""))))
        alg == "HS256" || error("unsupported OIDC JWKS key alg")
        haskey(key, "k") || error("OIDC JWKS key material is missing")
        return base64url_decode_bytes(String(key["k"]))
    end
    error("OIDC JWKS key not found: $(kid)")
end

function oidc_rsa_jwk(header::AbstractDict)
    jwks = oidc_jwks_document()
    jwks === nothing && error("OIDC JWKS is required for RS256 validation")
    kid = haskey(header, "kid") ? String(header["kid"]) : ""
    isempty(kid) && error("OIDC token kid is required for JWKS validation")
    for key in get(jwks, "keys", Any[])
        String(get(key, "kid", "")) == kid || continue
        String(get(key, "kty", "")) == "RSA" || error("unsupported OIDC JWKS key type")
        alg = String(get(key, "alg", String(get(header, "alg", ""))))
        alg == "RS256" || error("unsupported OIDC JWKS key alg")
        haskey(key, "n") || error("OIDC RSA key modulus is missing")
        haskey(key, "e") || error("OIDC RSA key exponent is missing")
        return key
    end
    error("OIDC JWKS key not found: $(kid)")
end

function oidc_hs256_secret(header::AbstractDict)
    jwks_secret = oidc_secret_from_jwks(header)
    jwks_secret === nothing || return jwks_secret
    secret = oidc_required_setting("JULIAFLOW_OIDC_HS256_SECRET")
    return Vector{UInt8}(codeunits(secret))
end

function verify_rs256_signature(header::AbstractDict, signing_input::AbstractString, signature::AbstractString)
    key = oidc_rsa_jwk(header)
    modulus_bytes = base64url_decode_bytes(String(key["n"]))
    exponent_bytes = base64url_decode_bytes(String(key["e"]))
    isempty(modulus_bytes) && error("OIDC RSA key modulus is empty")
    isempty(exponent_bytes) && error("OIDC RSA key exponent is empty")
    length(modulus_bytes) >= 256 || error("OIDC RSA key modulus is too small")
    modulus = big_endian_uint(modulus_bytes)
    exponent = big_endian_uint(exponent_bytes)
    signature_bytes = base64url_decode_bytes(signature)
    length(signature_bytes) == length(modulus_bytes) || return false

    decrypted = powermod(big_endian_uint(signature_bytes), exponent, modulus)
    encoded = fixed_width_big_endian(decrypted, length(modulus_bytes))
    digest_info_prefix = UInt8[
        0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86,
        0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05,
        0x00, 0x04, 0x20,
    ]
    digest = sha256(Vector{UInt8}(codeunits(String(signing_input))))
    expected_tail = [digest_info_prefix; digest]
    length(encoded) >= length(expected_tail) + 11 || return false
    encoded[1] == 0x00 || return false
    encoded[2] == 0x01 || return false
    separator = length(encoded) - length(expected_tail)
    separator >= 11 || return false
    for index in 3:(separator - 1)
        encoded[index] == 0xff || return false
    end
    encoded[separator] == 0x00 || return false
    return constant_time_equal_bytes(encoded[(separator + 1):end], expected_tail)
end

function validate_oidc_jwt(token::AbstractString)
    segments = split(String(token), '.')
    length(segments) == 3 || error("invalid OIDC token")
    header = JSON3.read(base64url_decode_string(segments[1]), Dict{String,Any})
    claims = JSON3.read(base64url_decode_string(segments[2]), Dict{String,Any})
    alg = String(get(header, "alg", ""))
    alg in oidc_allowed_algorithms() || error("unsupported OIDC token alg")

    signing_input = string(segments[1], ".", segments[2])
    if alg == "HS256"
        expected_signature = base64url_encode(hmac_sha256(oidc_hs256_secret(header), signing_input))
        constant_time_equal(expected_signature, String(segments[3])) || error("invalid OIDC token signature")
    elseif alg == "RS256"
        verify_rs256_signature(header, signing_input, String(segments[3])) || error("invalid OIDC token signature")
    else
        error("unsupported OIDC token alg")
    end

    issuer = oidc_expected_issuer()
    audience = oidc_required_setting("JULIAFLOW_OIDC_AUDIENCE")
    haskey(claims, "iss") && String(claims["iss"]) == issuer || error("invalid OIDC token issuer")
    haskey(claims, "aud") && oidc_claim_matches(claims["aud"], audience) || error("invalid OIDC token audience")
    haskey(claims, "sub") || error("invalid OIDC token subject")

    now_seconds = Int(floor(datetime2unix(now(UTC))))
    exp = jwt_unix_claim(claims, "exp")
    exp === nothing && error("invalid OIDC token expiry")
    now_seconds < exp || error("expired OIDC token")
    nbf = jwt_unix_claim(claims, "nbf")
    nbf === nothing || now_seconds >= nbf || error("OIDC token not yet valid")
    return claims
end

function oidc_claim_roles(claims::AbstractDict)
    roles = String[]
    if haskey(claims, "realm_access") && claims["realm_access"] isa AbstractDict
        append!(roles, [String(role) for role in get(claims["realm_access"], "roles", Any[])])
    end
    if haskey(claims, "resource_access") && claims["resource_access"] isa AbstractDict
        for (_, resource) in pairs(claims["resource_access"])
            resource isa AbstractDict || continue
            append!(roles, [String(role) for role in get(resource, "roles", Any[])])
        end
    end
    return roles
end

function role_from_claims(claims::AbstractDict)
    raw_role = get(claims, "juliaflow_role", get(claims, "role", nothing))
    if raw_role === nothing
        claim_roles = Set(lowercase(strip(role)) for role in oidc_claim_roles(claims))
        for role in ("owner", "editor", "viewer")
            (role in claim_roles || "juliaflow-$(role)" in claim_roles) && return role
        end
        raw_role = "viewer"
    end
    role = lowercase(strip(String(raw_role)))
    haskey(GATEWAY_ROLE_PERMISSIONS, role) || error("unsupported workspace role: $(role)")
    return role
end

function workspace_from_claims(claims::AbstractDict, request::HTTP.Request)
    raw_workspace = get(claims, "juliaflow_workspace", get(claims, "workspace_id", ""))
    workspace = strip(String(raw_workspace))
    !isempty(workspace) && return workspace
    header_workspace = request_header(request, "X-JuliaFlow-Workspace")
    return header_workspace === nothing || isempty(strip(header_workspace)) ? "local-dev" : strip(header_workspace)
end

function auth_context_from_role(principal_id::AbstractString, workspace_id::AbstractString, role::AbstractString, mode::AbstractString)
    return Dict(
        "principalId" => String(principal_id),
        "workspaceId" => String(workspace_id),
        "role" => String(role),
        "mode" => String(mode),
        "permissions" => sort(collect(GATEWAY_ROLE_PERMISSIONS[String(role)])),
    )
end

function apply_persisted_role_binding(state::GatewayState, context::Dict{String,Any})
    policy = JuliaFlowGatewayRepository.load_auth_policy(state.repository)
    principal_id = String(context["principalId"])
    workspace_id = String(context["workspaceId"])
    for binding in policy.role_bindings
        binding.principal_id == principal_id || continue
        binding.workspace_id == workspace_id || continue
        haskey(GATEWAY_ROLE_PERMISSIONS, binding.role) || error("unsupported workspace role: $(binding.role)")
        context["role"] = binding.role
        context["permissions"] = sort(collect(GATEWAY_ROLE_PERMISSIONS[binding.role]))
        return context
    end
    return context
end

function enforce_auth_directory_context!(state::GatewayState, context::Dict{String,Any})
    directory = JuliaFlowGatewayRepository.load_auth_directory(state.repository)
    principal_id = String(context["principalId"])
    workspace_id = String(context["workspaceId"])
    if !isempty(directory.users)
        any(user.principal_id == principal_id && user.active for user in directory.users) ||
            error("permission denied: principal not active in directory: $(principal_id)")
    end
    if !isempty(directory.workspaces)
        any(workspace.workspace_id == workspace_id && workspace.active for workspace in directory.workspaces) ||
            error("permission denied: workspace not active in directory: $(workspace_id)")
    end
    return context
end

function auth_context_payload(request::HTTP.Request; state::Union{Nothing,GatewayState} = nothing)
    mode = gateway_auth_mode()
    role = auth_role_from_request(request)
    if mode == "disabled"
        fixture_substitution_allowed(juliaflow_runtime_mode()) || error("auth token is required in release/local-appliance mode")
        return auth_context_from_role("system:auth-disabled", "local-dev", "owner", mode)
    elseif mode == "oidc"
        token = bearer_token_from_request(request)
        token === nothing && error("OIDC bearer token is required")
        claims = validate_oidc_jwt(token)
        context = auth_context_from_role(
            String(claims["sub"]),
            workspace_from_claims(claims, request),
            role_from_claims(claims),
            mode,
        )
        state === nothing || enforce_auth_directory_context!(state, context)
        state === nothing || apply_persisted_role_binding(state, context)
        return context
    end

    expected_token = dev_auth_token()
    if expected_token === nothing
        (mode == "required" || !fixture_substitution_allowed(juliaflow_runtime_mode())) && error("auth token is required but JULIAFLOW_DEV_AUTH_TOKEN is not configured")
        return auth_context_from_role("dev:local-user", "local-dev", "owner", "dev_fallback")
    end

    provided_token = bearer_token_from_request(request)
    provided_token == expected_token || error("invalid auth token")
    principal = request_header(request, "X-JuliaFlow-Principal")
    principal_id = principal === nothing || isempty(strip(principal)) ? "dev:token-user" : strip(principal)
    workspace = request_header(request, "X-JuliaFlow-Workspace")
    workspace_id = workspace === nothing || isempty(strip(workspace)) ? "local-dev" : strip(workspace)
    context = auth_context_from_role(principal_id, workspace_id, role, mode)
    state === nothing || enforce_auth_directory_context!(state, context)
    state === nothing || apply_persisted_role_binding(state, context)
    return context
end

function enforce_resource_policy!(
    state::GatewayState,
    context::Dict{String,Any},
    permission::AbstractString,
    resource_type::Union{Nothing,AbstractString},
    resource_id::Union{Nothing,AbstractString},
)
    (resource_type === nothing || resource_id === nothing) && return context
    policy = JuliaFlowGatewayRepository.load_auth_policy(state.repository)
    workspace_id = String(context["workspaceId"])
    role = String(context["role"])
    for item in policy.resource_policies
        item.resource_type == String(resource_type) || continue
        item.resource_id == String(resource_id) || item.resource_id == "*" || continue
        item.workspace_id == workspace_id || item.workspace_id == "*" || error("permission denied: $(permission)")
        allowed = get(item.permissions_by_role, role, String[])
        String(permission) in allowed || error("permission denied: $(permission)")
        return context
    end
    return context
end

function require_permission!(request::HTTP.Request, permission::AbstractString)
    context = auth_context_payload(request)
    role = String(context["role"])
    permission in GATEWAY_ROLE_PERMISSIONS[role] || error("permission denied: $(permission)")
    return context
end

function require_permission!(
    state::GatewayState,
    request::HTTP.Request,
    permission::AbstractString;
    resource_type::Union{Nothing,AbstractString} = nothing,
    resource_id::Union{Nothing,AbstractString} = nothing,
)
    context = auth_context_payload(request; state = state)
    role = String(context["role"])
    permission in GATEWAY_ROLE_PERMISSIONS[role] || error("permission denied: $(permission)")
    return enforce_resource_policy!(state, context, permission, resource_type, resource_id)
end

function bearer_token_from_request(request::HTTP.Request)
    for header in request.headers
        key = lowercase(String(header.first))
        key == "authorization" || continue
        value = strip(String(header.second))
        startswith(lowercase(value), "bearer ") || continue
        ncodeunits(value) > 7 || continue
        token = strip(value[8:end])
        return isempty(token) ? nothing : token
    end
    return nothing
end

function health_event_stats(state::GatewayState)
    events = JuliaFlowGatewayRepository.list_events_after(state.repository, 0)
    event_log_size = length(events)
    latest_sequence = event_log_size == 0 ? 0 : events[end].sequence
    gateway_consumer_cursor = JuliaFlowGatewayRepository.load_consumer_cursor(
        state.repository,
        gateway_event_consumer_id(),
    )
    gateway_consumer_lag = max(latest_sequence - gateway_consumer_cursor, 0)
    gateway_consumer_catchup_percent =
        latest_sequence == 0 ? 100 : Int(clamp(round((gateway_consumer_cursor / latest_sequence) * 100), 0, 100))
    return (
        event_log_size = event_log_size,
        latest_event_sequence = latest_sequence,
        gateway_consumer_cursor = gateway_consumer_cursor,
        gateway_consumer_lag = gateway_consumer_lag,
        gateway_consumer_catchup_percent = gateway_consumer_catchup_percent,
    )
end

function health_execution_stats(state::GatewayState)
    queued_stream_executions = count(
        execution -> execution.status == "queued" && get(execution.metadata, "stream_lifecycle_status", nothing) == "starting",
        state.executions,
    )
    active_gpu_executions = count(
        execution -> execution.status == "running" && JuliaFlowWorkerService.has_gpu_dispatch(execution),
        state.executions,
    )
    queued_executions_total = count(execution -> execution.status == "queued", state.executions)
    running_executions_total = count(execution -> execution.status == "running", state.executions)
    return (
        queued_stream_executions = queued_stream_executions,
        active_gpu_executions = active_gpu_executions,
        gpu_worker_owned_executions = length(state.worker_service.gpu_execution_ids),
        queued_executions_total = queued_executions_total,
        running_executions_total = running_executions_total,
    )
end

function list_workflows_response(state::GatewayState)
    items = [
        Dict(
            "workflowId" => workflow.id,
            "name" => workflow.name,
            "version" => workflow.version,
            "nodeCount" => length(workflow.nodes),
            "latestCheckpoint" => latest_checkpoint_tag(state),
        ) for workflow in values(state.workflows)
    ]
    sort!(items, by = item -> item["workflowId"])
    return JSON3.write(Dict("items" => items))
end

function get_workflow_response(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    workflow = state.workflows[workflow_id]
    return JSON3.write(JuliaFlowGatewayRepository.workflow_detail_payload(workflow))
end

function materialize_execution(job::Dict{String,Any})
    status_history = Dict{String,Any}[]
    for event in get(job, "status_history", Any[])
        normalized = Dict{String,Any}(String(key) => value for (key, value) in pairs(event))
        if haskey(normalized, "timestamp") && !haskey(normalized, "at")
            normalized["at"] = normalized["timestamp"]
            delete!(normalized, "timestamp")
        end
        push!(status_history, normalized)
    end

    metadata = Dict{String,Any}()
    for (key, value) in pairs(job)
        string_key = String(key)
        if string_key in (
            "execution_id",
            "workflow_id",
            "workflow_version",
            "checkpoint_tag",
            "status",
            "mode",
            "plan",
            "stages",
            "node_count",
            "connection_count",
            "created_at",
            "updated_at",
            "status_history",
            "queued_at",
            "started_at",
            "finished_at",
        )
            continue
        end
        metadata[string_key] = value
    end

    return GatewayExecution(
        execution_id = String(job["execution_id"]),
        workflow_id = String(job["workflow_id"]),
        workflow_version = String(job["workflow_version"]),
        checkpoint_tag = String(job["checkpoint_tag"]),
        status = String(job["status"]),
        mode = String(job["mode"]),
        plan = [String(entry) for entry in job["plan"]],
        stages = [[String(entry) for entry in stage] for stage in job["stages"]],
        node_count = Int(job["node_count"]),
        connection_count = Int(job["connection_count"]),
        created_at = String(job["created_at"]),
        updated_at = String(get(job, "updated_at", job["created_at"])),
        status_history = status_history,
        queued_at = haskey(job, "queued_at") ? String(job["queued_at"]) : nothing,
        started_at = haskey(job, "started_at") ? String(job["started_at"]) : nothing,
        finished_at = haskey(job, "finished_at") ? String(job["finished_at"]) : nothing,
        metadata = metadata,
    )
end

function activate_gpu_execution!(state::GatewayState, execution::GatewayExecution)
    updated_execution = JuliaFlowWorkerService.activate_gpu_execution!(
        state.worker_service,
        state.executions,
        execution.execution_id;
        execution_record = execution_record,
        transition_execution_record = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
        materialize_execution = materialize_execution,
    )
    save_execution!(state.repository, updated_execution; producer = "api-gateway")
    event_backbone_enabled() || broadcast_execution_update!(state, updated_execution.workflow_id, updated_execution)
    return updated_execution
end

function queue_stream_execution!(state::GatewayState, execution::GatewayExecution)
    updated_execution = JuliaFlowWorkerService.queue_stream_execution!(
        state.worker_service,
        state.workflows,
        state.executions,
        execution.execution_id;
        execution_record = execution_record,
        transition_execution_record = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
        materialize_execution = materialize_execution,
    )
    save_execution!(state.repository, updated_execution; producer = "api-gateway")
    event_backbone_enabled() || broadcast_execution_update!(state, updated_execution.workflow_id, updated_execution)
    return updated_execution
end

function execution_accept_response(
    state::GatewayState,
    workflow_id::AbstractString;
    flow_variable_values::Dict{String,Any} = Dict{String,Any}(),
    execution_mode_override::Union{Nothing,String} = nothing,
)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    job = JuliaFlowGatewayRepository.JuliaFlowExecutionService.execute_workflow(
        state.workflows[workflow_id];
        checkpoint_tag = latest_checkpoint_tag(state),
        flow_variable_values = flow_variable_values,
        execution_mode_override = execution_mode_override,
    )
    execution = materialize_execution(job)
    workflow = state.workflows[workflow_id]
    compute_settings = load_compute_settings(state)
    selected_backend = String(compute_settings["selectedBackend"])
    settings_source = String(compute_settings["source"])
    execution.metadata["computeSettingsApplied"] = compute_settings
    if !JuliaFlowGatewayRepository.JuliaFlowExecutionService.is_stream_workflow(workflow) && !should_dispatch_gpu_execution(workflow, execution)
        haskey(execution.metadata, "dispatchSchedulerPolicy") || (execution.metadata["dispatchSchedulerPolicy"] = String(compute_settings["schedulerPolicy"]))
        haskey(execution.metadata, "dispatchWorkerPool") || (execution.metadata["dispatchWorkerPool"] = selected_backend == "cpu" ? "local-cpu" : "local-$(selected_backend)")
        haskey(execution.metadata, "dispatchPlacementReason") || (execution.metadata["dispatchPlacementReason"] = "Applied local compute settings from $(settings_source) profile.")
    end
    execution.metadata["explainability_evidence"] = gateway_explainability_evidence(state; checkpoint_tag = execution.checkpoint_tag)
    save_execution!(state.repository, execution; producer = "api-gateway")
    push!(state.executions, execution)
    if JuliaFlowGatewayRepository.JuliaFlowExecutionService.is_stream_workflow(workflow)
        if stream_worker_mode() == "process"
            execution = queue_stream_execution!(state, execution)
        else
            execution = activate_stream_execution!(state, execution)
        end
        return JSON3.write(execution_payload(execution))
    elseif should_dispatch_gpu_execution(workflow, execution)
        execution = activate_gpu_execution!(state, execution)
        return JSON3.write(execution_payload(execution))
    end
    event_backbone_enabled() || broadcast_execution_update!(state, workflow_id, execution)
    return JSON3.write(execution_payload(execution))
end

function execution_list_response(state::GatewayState)
    return JSON3.write(Dict("items" => [execution_payload(execution) for execution in state.executions]))
end

function execution_detail_response(state::GatewayState, execution_id::AbstractString)
    for execution in state.executions
        execution.execution_id == execution_id && return JSON3.write(execution_payload(execution))
    end
    error("execution not found: $(execution_id)")
end

function execution_record(execution::GatewayExecution)
    record = Dict{String,Any}(
        "execution_id" => execution.execution_id,
        "workflow_id" => execution.workflow_id,
        "workflow_version" => execution.workflow_version,
        "checkpoint_tag" => execution.checkpoint_tag,
        "status" => execution.status,
        "mode" => execution.mode,
        "plan" => execution.plan,
        "stages" => execution.stages,
        "node_count" => execution.node_count,
        "connection_count" => execution.connection_count,
        "created_at" => execution.created_at,
        "updated_at" => execution.updated_at,
        "status_history" => execution.status_history,
    )
    execution.queued_at === nothing || (record["queued_at"] = execution.queued_at)
    execution.started_at === nothing || (record["started_at"] = execution.started_at)
    execution.finished_at === nothing || (record["finished_at"] = execution.finished_at)
    isempty(execution.metadata) || merge!(record, execution.metadata)
    return record
end

function execution_sync_fingerprint(execution::GatewayExecution)
    return (
        execution.updated_at,
        execution.status,
        get(execution.metadata, "stream_lifecycle_status", nothing),
        get(execution.metadata, "stream_processed_offset", nothing),
        get(execution.metadata, "stream_consumer_lag", nothing),
        get(execution.metadata, "stream_batch_count", nothing),
        get(execution.metadata, "worker_id", nothing),
        length(execution.status_history),
    )
end

function sync_external_execution_updates!(state::GatewayState)
    if event_backbone_enabled()
        events = consume_gateway_events!(state)
        changed_executions = GatewayExecution[]
        for event in events
            event.event_type == "execution.changed" || continue
            push!(changed_executions, JuliaFlowGatewayRepository.gateway_execution(event.payload))
        end
        return changed_executions
    end

    latest_executions = load_executions(state.repository)
    current_by_id = Dict(execution.execution_id => execution for execution in state.executions)
    changed_executions = GatewayExecution[]

    for execution in latest_executions
        current = get(current_by_id, execution.execution_id, nothing)
        current === nothing && push!(changed_executions, execution)
        current === nothing || execution_sync_fingerprint(current) == execution_sync_fingerprint(execution) || push!(changed_executions, execution)
    end

    state.executions = latest_executions
    sync_worker_service!(state.worker_service, state.executions)

    for execution in changed_executions
        broadcast_execution_update!(state, execution.workflow_id, execution)
        if get(execution.metadata, "stream_lifecycle_status", nothing) == "stopped" && execution.status == "completed"
            broadcast_stream_checkpoint!(state, execution.workflow_id, execution)
        end
    end

    return changed_executions
end

function find_execution_index(state::GatewayState, execution_id::AbstractString)
    for (index, execution) in pairs(state.executions)
        execution.execution_id == execution_id && return index
    end
    error("execution not found: $(execution_id)")
end

const HTTP_RESERVED_EXECUTION_FIELDS = Set(lowercase(replace(key, "_" => "")) for key in (
    "execution_id", "workflow_id", "workflow_version", "checkpoint_tag", "status", "mode", "plan", "stages",
    "node_count", "connection_count", "created_at", "updated_at", "status_history", "queued_at", "started_at", "finished_at",
    "explainability_evidence", "ml_validation_context", "ml_training_artifact_evidence", "ml_training_execution_evidence",
    "ml_training_metrics", "model_registry_record", "deploy_package_records", "data_science_project_job", "artifact_refs",
    "data_science_project_worker_state", "worker_dispatch", "resource_evidence", "executor_state",
))

"Validate HTTP metadata before transitions; producer echoes are checked and omitted from the merge."
function admit_execution_status_metadata(state::GatewayState, execution_id::AbstractString, metadata::AbstractDict)
    execution = state.executions[find_execution_index(state, execution_id)]
    current = (execution_record(execution), execution_payload(execution))
    admitted = Dict{String,Any}()
    for (key, value) in pairs(metadata)
        field = String(key)
        normalized = lowercase(replace(field, "_" => ""))
        if normalized in HTTP_RESERVED_EXECUTION_FIELDS
            unchanged = any(any(lowercase(replace(String(existing_key), "_" => "")) == normalized &&
                isequal(json_compatible_value(existing_value), json_compatible_value(value))
                for (existing_key, existing_value) in pairs(record)) for record in current)
            unchanged || error("execution metadata $(field) is server owned")
            continue
        end
        admitted[field] = value
    end
    return admitted
end

function transition_execution_response!(
    state::GatewayState,
    execution_id::AbstractString;
    status::AbstractString,
    message::Union{Nothing,String} = nothing,
    metadata::Dict{String,Any} = Dict{String,Any}(),
)
    index = find_execution_index(state, execution_id)
    current_execution = state.executions[index]
    failed_node_key = haskey(metadata, "failedNodeId") ? "failedNodeId" :
                      (haskey(metadata, "failed_node_id") ? "failed_node_id" : nothing)
    if String(status) == "failed" && failed_node_key !== nothing && !(current_execution.status in ("completed", "failed"))
        failed_node_id = string(metadata[failed_node_key])
        recovery = JuliaFlowGatewayRepository.JuliaFlowExecutionService.try_catch_recovery_metadata(
            state.workflows[current_execution.workflow_id],
            failed_node_id,
        )
        if recovery !== nothing
            recovery_message = message === nothing ? "Try/catch recovery planned" : message
            recovery_metadata = Dict{String,Any}("control_flow_recovery" => recovery)
            current_record = execution_record(current_execution)
            updated = current_execution.status == "accepted" ?
                      JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record(
                          current_record,
                          "queued";
                          message = recovery_message,
                          metadata = recovery_metadata,
                      ) :
                      JuliaFlowGatewayRepository.JuliaFlowExecutionService.append_execution_event(
                          current_record;
                          message = recovery_message,
                          metadata = recovery_metadata,
                      )
            execution = materialize_execution(updated)
            state.executions[index] = execution
            save_execution!(state.repository, execution; producer = "api-gateway")
            event_backbone_enabled() || broadcast_execution_update!(state, execution.workflow_id, execution)
            return JSON3.write(execution_payload(execution))
        end
    end
    updated = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record(
        execution_record(current_execution),
        status;
        message = message,
        metadata = metadata,
    )
    execution = materialize_execution(updated)
    state.executions[index] = execution
    save_execution!(state.repository, execution; producer = "api-gateway")
    event_backbone_enabled() || broadcast_execution_update!(state, execution.workflow_id, execution)
    return JSON3.write(execution_payload(execution))
end

function create_checkpoint_response!(state::GatewayState; tag::String, summary::String)
    checkpoint = GatewayCheckpoint(
        tag = tag,
        summary = summary,
        created_at = string(now(UTC)),
    )
    save_checkpoint!(state.repository, checkpoint)
    push!(state.checkpoints, checkpoint)
    return JSON3.write(
        Dict(
            "checkpoint" => checkpoint_payload(checkpoint, state),
            "checkpointCount" => length(state.checkpoints),
        ),
    )
end

function checkpoint_list_response(state::GatewayState)
    return JSON3.write(Dict("items" => [checkpoint_payload(checkpoint, state) for checkpoint in state.checkpoints]))
end

function canonical_json(value)
    if value isa AbstractDict || value isa JSON3.Object
        parts = String[]
        normalized = Dict{String,Any}(String(key) => item for (key, item) in pairs(value))
        for key in sort(collect(keys(normalized)))
            push!(parts, JSON3.write(key) * ":" * canonical_json(normalized[key]))
        end
        return "{" * join(parts, ",") * "}"
    elseif value isa AbstractVector || value isa JSON3.Array
        return "[" * join([canonical_json(item) for item in value], ",") * "]"
    elseif value === nothing
        return "null"
    elseif value isa AbstractString || value isa Number || value isa Bool
        return JSON3.write(value)
    else
        return JSON3.write(value)
    end
end

function reproducibility_bundle_checksum(bundle::AbstractDict)
    checksum_payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(bundle))
    delete!(checksum_payload, "bundleChecksumSha256")
    materialized_payload = JSON3.read(JSON3.write(checksum_payload), Dict{String,Any})
    return bytes2hex(sha256(Vector{UInt8}(codeunits(canonical_json(materialized_payload)))))
end

function artifact_checksum(payload)
    materialized_payload = JSON3.read(JSON3.write(payload), Dict{String,Any})
    return bytes2hex(sha256(Vector{UInt8}(codeunits(canonical_json(materialized_payload)))))
end

function find_checkpoint(state::GatewayState, checkpoint_tag::AbstractString)
    for checkpoint in state.checkpoints
        checkpoint.tag == checkpoint_tag && return checkpoint
    end
    return nothing
end

function package_environment_metadata()
    project_path = joinpath(pwd(), "Project.toml")
    package_path = joinpath(pwd(), "package.json")
    return Dict{String,Any}(
        "juliaVersion" => string(VERSION),
        "projectPath" => project_path,
        "projectChecksumSha256" => isfile(project_path) ? bytes2hex(sha256(read(project_path))) : "",
        "packagePath" => package_path,
        "packageChecksumSha256" => isfile(package_path) ? bytes2hex(sha256(read(package_path))) : "",
        "offlineOnly" => true,
    )
end

function reproducibility_runtime_config(state::GatewayState)
    health = JSON3.read(healthcheck(state), Dict{String,Any})
    return Dict{String,Any}(
        "localProfile" => health["localProfile"],
        "metadataMode" => health["metadataMode"],
        "metadataBackend" => health["metadataBackend"],
        "hardwareSelectedBackend" => health["hardwareSelectedBackend"],
        "cpuThreadCount" => health["cpuThreadCount"],
        "cpuWorkerConcurrency" => health["cpuWorkerConcurrency"],
        "gpuReadinessStatus" => health["gpuReadinessStatus"],
        "cloudCredentialsRequired" => health["cloudCredentialsRequired"],
        "hubOfflineInstallReady" => health["hubOfflineInstallReady"],
    )
end

function reproducibility_bundle_payload(
    state::GatewayState;
    workflow_id::AbstractString,
    checkpoint_tag::AbstractString,
    dashboard_id::Union{Nothing,AbstractString} = nothing,
    notes::Union{Nothing,AbstractString} = nothing,
)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    checkpoint = find_checkpoint(state, checkpoint_tag)
    checkpoint === nothing && error("checkpoint not found: $(checkpoint_tag)")
    checkpoint_evidence = checkpoint_payload(checkpoint, state)
    explainability = checkpoint_evidence["explainabilityEvidence"]
    dashboard_snapshot = nothing
    if dashboard_id !== nothing
        haskey(state.published_dashboards, dashboard_id) || error("published dashboard not found: $(dashboard_id)")
        dashboard = state.published_dashboards[String(dashboard_id)]
        dashboard.workflow_id == workflow_id || error("dashboard $(dashboard_id) does not belong to workflow $(workflow_id)")
        dashboard_snapshot = JuliaFlowGatewayRepository.published_dashboard_payload(dashboard)
    end

    bundle = Dict{String,Any}(
        "bundleId" => "repro-" * replace(string(uuid4()), "-" => ""),
        "createdAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        "schemaVersion" => "juliaflow.reproducibility.v1",
        "workflow" => JuliaFlowGatewayRepository.workflow_detail_payload(state.workflows[String(workflow_id)]),
        "checkpoint" => checkpoint_evidence,
        "dataReferences" => [Dict{String,Any}(
            "datasetId" => explainability["datasetCard"]["datasetId"],
            "sourceUri" => explainability["datasetCard"]["sourceUri"],
            "checksumSha256" => explainability["datasetCard"]["checksumSha256"],
            "rowCount" => explainability["datasetCard"]["rowCount"],
        )],
        "datasetCards" => [explainability["datasetCard"]],
        "packageEnvironment" => package_environment_metadata(),
        "runtimeConfig" => reproducibility_runtime_config(state),
        "randomSeeds" => Dict{String,Any}(
            "modelSeed" => get(explainability["modelCard"]["config"], "seed", 42),
            "runtimeSeed" => 42,
        ),
        "modelArtifact" => Dict{String,Any}(
            "modelId" => explainability["modelCard"]["modelId"],
            "artifactRef" => "local://models/" * String(explainability["modelCard"]["modelId"]) * ".json",
            "checksumSha256" => bytes2hex(sha256(Vector{UInt8}(codeunits(canonical_json(explainability["modelCard"]))))),
        ),
        "metrics" => explainability["modelCard"]["metrics"],
        "evaluationOutputs" => Dict{String,Any}(
            "modelCard" => explainability["modelCard"],
            "limitations" => explainability["modelCard"]["limitations"],
        ),
        "explainabilityOutputs" => explainability["explanation"],
        "dashboardSnapshot" => dashboard_snapshot,
        "notes" => notes === nothing ? "" : String(notes),
        "localOnly" => true,
    )
    bundle["bundleChecksumSha256"] = reproducibility_bundle_checksum(bundle)
    return bundle
end

function reproducibility_bundle_export_response!(
    state::GatewayState,
    body::AbstractDict,
)
    haskey(body, "workflowId") || error("missing workflowId")
    haskey(body, "checkpointTag") || error("missing checkpointTag")
    dashboard_id = haskey(body, "dashboardId") ? String(body["dashboardId"]) : nothing
    notes = haskey(body, "notes") ? String(body["notes"]) : nothing
    bundle = reproducibility_bundle_payload(
        state;
        workflow_id = String(body["workflowId"]),
        checkpoint_tag = String(body["checkpointTag"]),
        dashboard_id = dashboard_id,
        notes = notes,
    )
    return JSON3.write(Dict("status" => "ok", "bundle" => bundle))
end

function visualize_checkpoint_export_response!(
    state::GatewayState,
    workflow_id::AbstractString,
    dashboard_id::AbstractString,
    body::AbstractDict,
)
    visibility = haskey(body, "visibility") ? String(body["visibility"]) : "workspace"
    checkpoint_tag = haskey(body, "checkpointTag") ?
        String(body["checkpointTag"]) :
        "cp/visualize-" * replace(JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(), r"[^A-Za-z0-9]+" => "-")
    summary = haskey(body, "summary") ?
        String(body["summary"]) :
        "Visualize checkpoint export for $(dashboard_id)"
    notes = haskey(body, "notes") ? String(body["notes"]) : "visualize checkpoint export"

    dashboard_response = JSON3.read(
        publish_dashboard_response!(state, workflow_id, dashboard_id; visibility = visibility),
        Dict{String,Any},
    )
    checkpoint_response = JSON3.read(
        create_checkpoint_response!(state; tag = checkpoint_tag, summary = summary),
        Dict{String,Any},
    )
    bundle = reproducibility_bundle_payload(
        state;
        workflow_id = workflow_id,
        checkpoint_tag = checkpoint_tag,
        dashboard_id = dashboard_id,
        notes = notes,
    )
    dashboard = dashboard_response["dashboard"]
    checkpoint = checkpoint_response["checkpoint"]
    export_id = "visualize-export-" * replace(string(uuid4()), "-" => "")
    evidence = [
        Dict{String,Any}(
            "kind" => "dashboard_snapshot",
            "artifactRef" => "local://dashboards/$(dashboard_id)/v$(dashboard["version"]).json",
            "checksumSha256" => artifact_checksum(dashboard),
        ),
        Dict{String,Any}(
            "kind" => "checkpoint",
            "artifactRef" => "local://checkpoints/$(checkpoint_tag).json",
            "checksumSha256" => artifact_checksum(checkpoint),
        ),
        Dict{String,Any}(
            "kind" => "reproducibility_bundle",
            "artifactRef" => "local://reproducibility/$(bundle["bundleId"]).json",
            "checksumSha256" => String(bundle["bundleChecksumSha256"]),
        ),
    ]
    export_record = Dict{String,Any}(
        "exportId" => export_id,
        "workflowId" => String(workflow_id),
        "dashboardId" => String(dashboard_id),
        "dashboardVersion" => dashboard["version"],
        "checkpointTag" => checkpoint_tag,
        "checkpointSummary" => summary,
        "bundleId" => bundle["bundleId"],
        "bundleChecksumSha256" => bundle["bundleChecksumSha256"],
        "dashboardSnapshotReady" => bundle["dashboardSnapshot"] !== nothing,
        "artifactEvidence" => evidence,
        "createdAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        "localOnly" => true,
    )
    return JSON3.write(Dict(
        "status" => "exported",
        "export" => export_record,
        "checkpoint" => checkpoint,
        "dashboard" => dashboard,
        "bundle" => bundle,
    ))
end

function reproducibility_bundle_import_response!(
    state::GatewayState,
    body::AbstractDict,
)
    haskey(body, "bundle") || error("missing bundle")
    raw_bundle = body["bundle"]
    raw_bundle isa AbstractDict || error("bundle must be an object")
    bundle = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_bundle))
    declared_checksum = String(get(bundle, "bundleChecksumSha256", ""))
    isempty(declared_checksum) && error("bundle missing bundleChecksumSha256")
    actual_checksum = reproducibility_bundle_checksum(bundle)
    declared_checksum == actual_checksum || error("reproducibility bundle checksum mismatch")

    workflow_payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(bundle["workflow"]))
    workflow_toml = workflow_toml_from_request(Dict{String,Any}("workflow" => workflow_payload))
    workflow_response = JSON3.read(create_workflow_response!(state; workflow_toml = workflow_toml), Dict{String,Any})

    checkpoint_body = Dict{String,Any}(String(key) => value for (key, value) in pairs(bundle["checkpoint"]))
    checkpoint = GatewayCheckpoint(
        tag = String(checkpoint_body["tag"]),
        summary = String(checkpoint_body["summary"]),
        created_at = String(checkpoint_body["createdAt"]),
    )
    save_checkpoint!(state.repository, checkpoint)
    existing_index = findfirst(item -> item.tag == checkpoint.tag, state.checkpoints)
    if existing_index === nothing
        push!(state.checkpoints, checkpoint)
    else
        state.checkpoints[existing_index] = checkpoint
    end

    restored_dashboard_id = nothing
    if haskey(bundle, "dashboardSnapshot") && bundle["dashboardSnapshot"] !== nothing
        dashboard_payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(bundle["dashboardSnapshot"]))
        dashboard = JuliaFlowGatewayRepository.gateway_published_dashboard(dashboard_payload)
        state.published_dashboards[dashboard.dashboard_id] = dashboard
        JuliaFlowGatewayRepository.save_published_dashboard!(state.repository, dashboard; producer = "reproducibility-import")
        restored_dashboard_id = dashboard.dashboard_id
    end

    return JSON3.write(Dict{String,Any}(
        "status" => "imported",
        "bundleId" => String(bundle["bundleId"]),
        "workflowId" => String(workflow_response["workflowId"]),
        "checkpointTag" => checkpoint.tag,
        "dashboardId" => restored_dashboard_id,
        "bundleChecksumSha256" => declared_checksum,
    ))
end

function local_backup_checksum(backup::AbstractDict)
    checksum_payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(backup))
    delete!(checksum_payload, "backupChecksumSha256")
    materialized_payload = JSON3.read(JSON3.write(checksum_payload), Dict{String,Any})
    return bytes2hex(sha256(Vector{UInt8}(codeunits(canonical_json(materialized_payload)))))
end

function local_data_estate_artifact_records(root::AbstractString)
    isdir(root) || return Dict{String,Any}[]
    records = Dict{String,Any}[]
    root_path = realpath(root)
    visited = 0
    for (dir, dirs, files) in walkdir(root_path)
        "_backups" in splitpath(relpath(dir, root_path)) && continue
        for child in dirs
            JuliaFlowDataScienceProjectLocalSources.confined_data_estate_path(root_path, relpath(joinpath(dir, child), root_path))
        end
        for file in sort(files)
            visited += 1
            visited <= 10_000 || return records
            path = JuliaFlowDataScienceProjectLocalSources.confined_data_estate_path(root_path, relpath(joinpath(dir, file), root_path))
            isfile(path) || continue
            relative_path = relpath(path, root_path)
            push!(
                records,
                Dict{String,Any}(
                    "relativePath" => relative_path,
                    "sizeBytes" => filesize(path),
                    "checksumSha256" => local_artifact_checksum(path),
                    "present" => true,
                ),
            )
        end
    end
    sort!(records; by = item -> String(item["relativePath"]))
    return records
end

function safe_local_dataset_id(value::AbstractString)
    return JuliaFlowDataScienceProjectCatalog.safe_local_dataset_id(value)
end

function data_profile_fixture(dataset_id::AbstractString, source_uri::AbstractString)
    return JuliaFlowDataScienceProjectCatalog.data_profile_fixture(dataset_id, source_uri)
end

function data_source_options(dataset_id::AbstractString, source_uri::AbstractString, target_zone::AbstractString, read_mode::AbstractString, health::AbstractDict)
    return JuliaFlowDataScienceProjectCatalog.data_source_options(dataset_id, source_uri, target_zone, read_mode, health)
end

function data_lineage_artifacts(dataset_id::AbstractString, source_uri::AbstractString, target_zone::AbstractString, checksum::AbstractString, row_count::Integer, health::AbstractDict)
    return JuliaFlowDataScienceProjectCatalog.data_lineage_artifacts(dataset_id, source_uri, target_zone, checksum, row_count, health)
end

function data_profile_chart_specs(dataset_id::AbstractString, fixture::AbstractDict, source_uri::AbstractString)
    plots = get(fixture, "quickPlots", Any[])
    chart_specs = Dict{String,Any}[]
    for plot in plots
        values = get(plot, "values", Any[])
        labels = [String(item["label"]) for item in values]
        numbers = [Float64(item["value"]) for item in values]
        plot_id = String(get(plot, "plotId", "profile-chart"))
        title = String(get(plot, "title", plot_id))
        kind = String(get(plot, "kind", "bar"))
        trace_type = kind == "line" ? "scatter" : "bar"
        trace = trace_type == "scatter" ?
            Dict("type" => "scatter", "mode" => "lines+markers", "x" => labels, "y" => numbers, "line" => Dict("color" => "#5b2eea", "width" => 3)) :
            Dict("type" => "bar", "x" => labels, "y" => numbers, "marker" => Dict("color" => ["#5b2eea", "#16a34a", "#2563eb", "#d97706"]))
        push!(
            chart_specs,
            plotly_chart_spec(
                "data-$(plot_id)",
                title,
                kind,
                [trace];
                layout = Dict("height" => 240, "xaxis" => Dict("automargin" => true), "yaxis" => Dict("automargin" => true)),
                source_label = "Data profile $(dataset_id)",
                evidence_ref = source_uri,
                summary = "$(title) uses local profile evidence for $(dataset_id).",
            ),
        )
    end
    profile_rows = get(fixture, "profileSummary", Any[])
    if !isempty(profile_rows)
        push!(
            chart_specs,
            plotly_chart_spec(
                "data-missingness-$(dataset_id)",
                "Missing Values",
                "bar",
                [
                    Dict(
                        "type" => "bar",
                        "x" => [String(row["name"]) for row in profile_rows],
                        "y" => [Int(get(row, "missingCount", 0)) for row in profile_rows],
                        "marker" => Dict("color" => "#d97706"),
                    ),
                ];
                layout = Dict("height" => 240, "xaxis" => Dict("automargin" => true), "yaxis" => Dict("title" => "Rows")),
                source_label = "Data profile $(dataset_id)",
                evidence_ref = source_uri,
                summary = "Missing value counts are generated from local profile evidence.",
            ),
        )
    end
    return chart_specs
end

function schema_contract_from_profile(profile::AbstractDict)
    dataset_id = String(profile["datasetId"])
    profile_rows = Dict(
        String(get(row, "name", "")) => row
        for row in get(profile, "profileSummary", Any[])
    )
    columns = Dict{String,Any}[]
    for column in get(profile, "schemaSummary", Any[])
        name = String(get(column, "name", ""))
        row = get(profile_rows, name, Dict{String,Any}())
        push!(
            columns,
            Dict{String,Any}(
                "name" => name,
                "inferredType" => String(get(column, "type", "String")),
                "logicalType" => String(get(column, "type", "String")),
                "role" => JuliaFlowDataScienceProjectCatalog.schema_role_from_profile(String(get(row, "role", "feature"))),
                "nullable" => Int(get(row, "missingCount", 0)) > 0,
            ),
        )
    end
    return Dict{String,Any}(
        "schemaId" => "schema-$(dataset_id)-profile",
        "datasetId" => dataset_id,
        "columns" => columns,
        "updatedAt" => String(profile["importedAt"]),
    )
end

function upsert_project_schema_contract!(project::DataScienceProjectRecord, schema_contract::Dict{String,Any})
    schema_id = String(schema_contract["schemaId"])
    project.schema_contracts = [
        schema for schema in project.schema_contracts
        if String(get(schema, "schemaId", "")) != schema_id
    ]
    project.schema_contracts = [schema_contract, project.schema_contracts...]
    return schema_contract
end

function profile_dataset_role(project::DataScienceProjectRecord, dataset_id::AbstractString, body::AbstractDict)
    if haskey(body, "datasetRole")
        return String(body["datasetRole"])
    end
    for dataset in project.datasets
        String(get(dataset, "datasetId", "")) == String(dataset_id) && return String(get(dataset, "role", "train"))
    end
    return "train"
end

function upsert_project_dataset_profile!(
    state::GatewayState,
    project::DataScienceProjectRecord,
    profile::Dict{String,Any},
    body::AbstractDict,
)
    dataset_id = String(profile["datasetId"])
    timestamp = String(profile["importedAt"])
    managed_source_ref = String(profile["artifactRef"])
    dataset_record = Dict{String,Any}(
        "datasetId" => dataset_id,
        "name" => String(get(body, "datasetName", dataset_id)),
        "role" => profile_dataset_role(project, dataset_id, body),
        "sourceUri" => managed_source_ref,
        "localOnly" => true,
        "rowCount" => Int(profile["rowCount"]),
        "columnCount" => length(get(profile, "schemaSummary", Any[])),
        "checksumSha256" => String(profile["checksumSha256"]),
        "artifactRef" => String(profile["artifactRef"]),
        "importSourceUri" => String(profile["sourceUri"]),
    )
    project.datasets = [
        dataset for dataset in project.datasets
        if String(get(dataset, "datasetId", "")) != dataset_id
    ]
    project.datasets = [dataset_record, project.datasets...]
    schema_contract = upsert_project_schema_contract!(project, schema_contract_from_profile(profile))
    output_refs = [
        Dict{String,Any}(
            "refId" => "artifact-profile-$(dataset_id)",
            "kind" => "data_profile",
            "localOnly" => true,
            "checksumSha256" => String(profile["checksumSha256"]),
            "path" => String(profile["artifactRef"]),
            "generatedAt" => timestamp,
        ),
        Dict{String,Any}(
            "refId" => String(schema_contract["schemaId"]),
            "kind" => "schema_contract",
            "localOnly" => true,
            "generatedAt" => timestamp,
        ),
    ]
    resource_evidence = data_science_project_job_resource_evidence(state; execution_mode = "data_profile")
    execution_evidence = data_science_project_execution_evidence!(
        state,
        project,
        "data_profile";
        dataset_id = dataset_id,
        source_record_id = dataset_id,
        output_refs = output_refs,
        resource_evidence = resource_evidence,
        started_at = timestamp,
        finished_at = timestamp,
        plan = ["validate_local_profile_source", "profile_dataset_schema", "update_project_catalog"],
        worker_backed = true,
    )
    record_data_science_project_job!(
        project,
        "data_profile";
        dataset_id = dataset_id,
        source_record_id = dataset_id,
        output_refs = output_refs,
        resource_evidence = resource_evidence,
        execution_evidence = execution_evidence,
        started_at = timestamp,
        finished_at = timestamp,
    )
    profile["projectId"] = project.project_id
    profile["executionEvidence"] = execution_evidence
    return execution_evidence
end

function split_env_paths(value::AbstractString)
    return JuliaFlowDataScienceProjectLocalSources.split_env_paths(value)
end

function local_data_import_roots()
    home = local_appliance_home()
    return JuliaFlowDataScienceProjectLocalSources.local_data_import_roots(home, local_data_estate_root(home))
end

function path_within_root(path::AbstractString, root::AbstractString)
    return JuliaFlowDataScienceProjectLocalSources.path_within_root(path, root)
end

function local_data_import_max_bytes()
    return positive_env_int("JULIAFLOW_IMPORT_MAX_BYTES", 512 * 1024 * 1024)
end

function sensitive_import_path(path::AbstractString)
    return JuliaFlowDataScienceProjectLocalSources.sensitive_import_path(path)
end

function local_data_import_sample(path::AbstractString; max_bytes::Integer = 16_384)
    return JuliaFlowDataScienceProjectLocalSources.local_data_import_sample(path; max_bytes)
end

function validate_local_data_import_sample!(path::AbstractString)
    return JuliaFlowDataScienceProjectLocalSources.validate_local_data_import_sample!(path)
end

function validate_source_identifier!(value::AbstractString, label::AbstractString)
    return JuliaFlowDataScienceProjectLocalSources.validate_source_identifier!(value, label)
end

function validate_local_data_import_connector_policy!(body::AbstractDict, source_uri::AbstractString)
    return JuliaFlowDataScienceProjectLocalSources.validate_local_data_import_connector_policy!(body, source_uri)
end

function validate_local_data_import_file!(path::AbstractString, source_format::AbstractString)
    return JuliaFlowDataScienceProjectLocalSources.validate_local_data_import_file!(
        path,
        source_format;
        max_bytes = local_data_import_max_bytes(),
    )
end

function validate_local_data_import_source!(source_uri::AbstractString)
    home = local_appliance_home()
    return JuliaFlowDataScienceProjectLocalSources.validate_local_data_import_source!(
        source_uri;
        local_home = home,
        data_root = local_data_estate_root(home),
        validate_local_ref = validate_project_local_ref!,
    )
end

function local_data_import_audit_source_details(source_uri)
    return JuliaFlowDataScienceProjectLocalSources.local_data_import_audit_source_details(source_uri)
end

function local_data_import_redaction_preview(source_uri)
    return JuliaFlowDataScienceProjectLocalSources.local_data_import_redaction_preview(source_uri)
end

function local_data_import_audit_details(body::AbstractDict; outcome::AbstractString, reason = nothing)
    dataset_id = haskey(body, "datasetId") ? String(body["datasetId"]) : "workflow-dataset"
    details = Dict{String,Any}(
        "datasetId" => dataset_id,
        "format" => haskey(body, "format") ? String(body["format"]) : "csv",
        "targetZone" => haskey(body, "targetZone") ? String(body["targetZone"]) : "raw",
        "outcome" => String(outcome),
    )
    merge!(details, local_data_import_audit_source_details(get(body, "sourceUri", nothing)))
    raw_source_uri = get(body, "sourceUri", nothing)
    managed_source = raw_source_uri !== nothing && startswith(lowercase(replace(strip(String(raw_source_uri)), "\\" => "/")), "local://")
    details["connector"] = lowercase(String(get(body, "connector", managed_source ? "managed_local" : "local_file")))
    details["redactionPreview"] = local_data_import_redaction_preview(get(body, "sourceUri", nothing))
    reason === nothing || (details["reason"] = String(reason))
    return details
end

function data_import_profile_response!(state::GatewayState, body::AbstractDict; auth_context = nothing)
    body = JuliaFlowDataScienceProjectProfiling.normalize_profile_request(body)
    if haskey(body, "projectId")
        project_id = String(body["projectId"])
        haskey(state.data_science_projects, project_id) || error("data science project not found: $(project_id)")
        auth_context === nothing || enforce_resource_policy!(state, auth_context, "workflow:write", "data_science_project", project_id)
    end
    ensure_cpu_project_job_allowed(state)
    health = JSON3.read(healthcheck(state), Dict{String,Any})
    evidence = gateway_explainability_evidence(state)
    dataset_card = Dict{String,Any}(String(key) => value for (key, value) in pairs(evidence["datasetCard"]))
    requested_dataset_id = String(get(body, "datasetId", dataset_card["datasetId"]))
    dataset_id = safe_local_dataset_id(requested_dataset_id)
    default_source_uri = "local://data/raw/$(dataset_id).csv"
    source_format = String(get(body, "format", "csv"))
    requested_source_uri = String(get(body, "sourceUri", default_source_uri))
    connector = validate_local_data_import_connector_policy!(body, requested_source_uri)
    source_uri = validate_local_data_import_source!(requested_source_uri)
    managed_source = startswith(lowercase(replace(source_uri, "\\" => "/")), "local://")
    source_path = if managed_source
        resolved = resolve_local_data_ref_path(source_uri)
        resolved === nothing && error("managed_local sourceUri must reference an existing local://data artifact")
        resolved
    else
        source_uri
    end
    validate_local_data_import_file!(source_path, source_format)
    (lowercase(source_format) == "csv" && lowercase(splitext(source_path)[2]) == ".csv") ||
        error("local data import real-file profiling currently supports CSV files only; $(source_format) is unavailable")
    target_zone = String(get(body, "targetZone", "raw"))
    read_mode = lowercase(String(get(body, "readMode", "csv")))
    read_mode == "csv" || error("local data import real-file profiling readMode $(read_mode) is unavailable; use csv")
    zones = [String(zone["name"]) for zone in health["dataEstateZones"]]
    target_zone in zones || error("data estate zone not found: $(target_zone)")
    filesize(source_path) <= JuliaFlowDataScienceProjectProfiling.MAX_PROFILE_BYTES ||
        error("local data import CSV profile supports files up to 8 MiB")
    checksum = explainability_source_checksum(source_path)
    imported_at = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    artifact_ref = source_uri
    profile_evidence = JuliaFlowDataScienceProjectProfiling.local_csv_profile(source_path)
    checksum == explainability_source_checksum(source_path) || error("source evidence unavailable: local CSV source changed during profiling; retry import")
    row_count = Int(profile_evidence["rowCount"])
    source_options = data_source_options(dataset_id, source_uri, target_zone, read_mode, health)
    for option in source_options
        String(option["mode"]) in ("arrow_ipc", "parquet", "duckdb") || continue
        option["status"] = "unavailable"
        option["semantics"] = "No derived artifact or query view was created by this CSV profile."
    end

    profile = Dict{String,Any}(
        "datasetId" => dataset_id,
        "sourceUri" => source_uri,
        "sourceConnector" => connector,
        "sourceFormat" => source_format,
        "targetZone" => target_zone,
        "artifactRef" => artifact_ref,
        "artifactFormats" => String[],
        "checksumSha256" => checksum,
        "rowCount" => row_count,
        "schemaSummary" => profile_evidence["schemaSummary"],
        "profileSummary" => profile_evidence["profileSummary"],
        "profileScope" => profile_evidence["profileScope"],
        "manifestReady" => Bool(health["dataEstateManifestReady"]),
        "manifestChecksums" => health["dataEstateManifestChecksums"],
        "duckdbStatus" => health["dataEstateDuckdbStatus"],
        "importedAt" => imported_at,
        "localOnly" => true,
        "activeReadMode" => read_mode,
        "sourceOptions" => source_options,
        "lineageArtifacts" => [Dict("stage" => "raw", "artifactRef" => source_uri, "format" => "csv", "checksumSha256" => checksum, "rowCount" => row_count)],
        "qualityChecks" => profile_evidence["qualityChecks"],
        "workflowReadiness" => profile_evidence["workflowReadiness"],
        "quickPlots" => profile_evidence["quickPlots"],
        "previewRows" => profile_evidence["previewRows"],
        "charts" => data_profile_chart_specs(dataset_id, profile_evidence, source_uri),
    )
    response = Dict{String,Any}("status" => "profiled", "profile" => profile)
    if haskey(body, "projectId")
        project_id = String(body["projectId"])
        haskey(state.data_science_projects, project_id) || error("data science project not found: $(project_id)")
        project = deepcopy(state.data_science_projects[project_id])
        profile_dataset_role(project, dataset_id, body) in ("train", "validation", "test", "evaluation", "output", "reference") ||
            error("local data import dataset role invalid")
        if !managed_source
            # Verified copies are shared by checksum. Retain them on later job/storage
            # failure; never roll back by deleting a copy another dataset may use.
            home = local_appliance_home()
            profile["artifactRef"] = JuliaFlowDataScienceProjectLocalSources.materialize_profile_source!(
                source_path, checksum; data_root = local_data_estate_root(home), zone = target_zone,
                max_bytes = JuliaFlowDataScienceProjectProfiling.MAX_PROFILE_BYTES)
            profile["artifactFormats"] = ["csv"]
            push!(profile["lineageArtifacts"], Dict("stage" => "managed_source", "artifactRef" => profile["artifactRef"],
                "format" => "csv", "checksumSha256" => checksum, "rowCount" => row_count))
        end
        upsert_project_dataset_profile!(state, project, profile, body)
        state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
        response["project"] = JuliaFlowGatewayRepository.data_science_project_payload(state.data_science_projects[project.project_id])
    end
    return JSON3.write(response)
end

function transform_node_ids(workflow)
    return [
        node.id for node in workflow.nodes
        if startswith(node.type, "io.") ||
            startswith(node.type, "transform.") ||
            occursin(".CSVReader", node.type) ||
            occursin(".Column", node.type) ||
            occursin(".Aggregate", node.type) ||
            node.type == "bi.outlet"
    ]
end

function transform_artifact_ref(execution::GatewayExecution, node_id::AbstractString)
    return "local://data/runs/$(execution.execution_id)/$(String(node_id)).arrow"
end

function transform_run_chart_specs(run_id::AbstractString, node_results)
    if isempty(node_results)
        return [
            plotly_chart_spec(
                "transform-empty-$(run_id)",
                "Transform Rows",
                "bar",
                Dict{String,Any}[];
                status = "empty",
                empty_reason = "No transform node results were returned by the local execution.",
                summary = "No transform metrics are available for this run yet.",
            ),
        ]
    end
    labels = [String(result["nodeId"]) for result in node_results]
    row_counts = [Int(get(result, "rowCount", 0)) for result in node_results]
    return [
        plotly_chart_spec(
            "transform-rows-$(run_id)",
            "Rows By Transform Node",
            "bar",
            [
                Dict(
                    "type" => "bar",
                    "x" => labels,
                    "y" => row_counts,
                    "marker" => Dict("color" => "#5b2eea"),
                ),
            ];
            layout = Dict("height" => 250, "xaxis" => Dict("automargin" => true), "yaxis" => Dict("title" => "Rows")),
            source_label = "Transform run $(run_id)",
            evidence_ref = "local://data/runs/$(run_id)",
            summary = "Rows by transform node are generated from local run evidence.",
        ),
    ]
end

function transform_run_payload(state::GatewayState, execution::GatewayExecution)
    haskey(state.workflows, execution.workflow_id) || error("workflow not found: $(execution.workflow_id)")
    workflow = state.workflows[execution.workflow_id]
    node_ids = transform_node_ids(workflow)
    node_results = if haskey(execution.metadata, "executor_state")
        [
            Dict{String,Any}(
                "nodeId" => String(get(item, "node_id", "")),
                "nodeType" => String(get(item, "node_type", "")),
                "status" => String(get(item, "status", "")),
                "rowCount" => Int(get(item, "row_count", 0)),
                "artifactRefs" => isempty(get(item, "output_refs", Any[])) ?
                    [transform_artifact_ref(execution, String(get(item, "node_id", "")))] :
                    [String(ref) for ref in get(item, "output_refs", Any[])],
            )
            for item in get(execution.metadata["executor_state"], "node_results", Any[])
            if String(get(item, "node_id", "")) in node_ids
        ]
    else
        Dict{String,Any}[]
    end
    if isempty(node_results)
        node_results = [
            Dict{String,Any}(
                "nodeId" => String(node_id),
                "nodeType" => state.workflows[execution.workflow_id].nodes[findfirst(node -> node.id == node_id, workflow.nodes)].type,
                "status" => node_runtime_status(node_id, execution),
                "rowCount" => 0,
                "artifactRefs" => [transform_artifact_ref(execution, node_id)],
            )
            for node_id in node_ids
        ]
    end

    return Dict{String,Any}(
        "runId" => execution.execution_id,
        "workflowId" => execution.workflow_id,
        "workflowVersion" => execution.workflow_version,
        "checkpointTag" => execution.checkpoint_tag,
        "status" => execution.status,
        "startedAt" => execution.started_at === nothing ? execution.created_at : execution.started_at,
        "finishedAt" => execution.finished_at,
        "stageCount" => length(execution.stages),
        "nodeIds" => node_ids,
        "nodeResults" => node_results,
        "artifactEvidence" => [
            Dict("nodeId" => String(result["nodeId"]), "artifactRefs" => result["artifactRefs"])
            for result in node_results
        ],
        "localOnly" => true,
        "charts" => transform_run_chart_specs(execution.execution_id, node_results),
        "validation" => Dict(
            "status" => isempty(node_results) ? "warning" : "valid",
            "messages" => isempty(node_results) ? ["No transform node results were available."] : ["Pipeline nodes resolved locally.", "Artifact outputs are attached to this run."],
            "updatedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        ),
    )
end

function transform_run_response!(state::GatewayState, workflow_id::AbstractString, body::AbstractDict)
    flow_variable_values = haskey(body, "flowVariables") ? normalized_string_dict(body["flowVariables"]) : Dict{String,Any}()
    execution_mode_override = haskey(body, "executionMode") ? String(body["executionMode"]) : nothing
    execution = JSON3.read(
        execution_accept_response(
            state,
            workflow_id;
            flow_variable_values = flow_variable_values,
            execution_mode_override = execution_mode_override,
        ),
        Dict{String,Any},
    )
    execution_id = String(execution["executionId"])
    matched = findfirst(item -> item.execution_id == execution_id, state.executions)
    matched === nothing && error("transform execution not found: $(execution_id)")
    run = transform_run_payload(state, state.executions[matched])
    return JSON3.write(Dict("status" => "accepted", "execution" => execution, "run" => run))
end

function transform_history_response(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    runs = [
        transform_run_payload(state, execution)
        for execution in reverse(state.executions)
        if execution.workflow_id == workflow_id
    ]
    return JSON3.write(Dict("items" => runs, "count" => length(runs)))
end

function ml_experiment_artifact_refs(execution::GatewayExecution, evidence::AbstractDict)
    dataset_card = evidence["datasetCard"]
    model_card = evidence["modelCard"]
    explanation = evidence["explanation"]
    return [
        Dict{String,Any}(
            "kind" => "dataset",
            "artifactRef" => "local://data/curated/$(String(dataset_card["datasetId"])).arrow",
            "checksumSha256" => String(dataset_card["checksumSha256"]),
        ),
        Dict{String,Any}(
            "kind" => "model",
            "artifactRef" => "local://models/$(String(model_card["modelId"])).json",
            "checksumSha256" => bytes2hex(sha256(Vector{UInt8}(codeunits(canonical_json(model_card))))),
        ),
        Dict{String,Any}(
            "kind" => "explanation",
            "artifactRef" => "local://explainability/$(execution.execution_id)/feature-importance.json",
            "checksumSha256" => bytes2hex(sha256(Vector{UInt8}(codeunits(canonical_json(explanation))))),
        ),
        Dict{String,Any}(
            "kind" => "reproducibility_bundle",
            "artifactRef" => "local://reproducibility/$(execution.checkpoint_tag)/bundle.json",
            "checksumSha256" => bytes2hex(sha256(Vector{UInt8}(codeunits(canonical_json(evidence))))),
        ),
    ]
end

function project_numeric_feature_columns(project, dataset_id, numeric_columns, target)
    candidates = JuliaFlowDataScienceProjectStatistics.candidate_numeric_feature_columns(numeric_columns, target)
    schemas = [schema for schema in project.schema_contracts if get(schema, "datasetId", "") == dataset_id]
    isempty(schemas) && return candidates
    length(schemas) == 1 || error("split membership requires one schema contract per dataset")
    allowed = Set(String(get(column, "name", "")) for column in get(only(schemas), "columns", Any[]) if get(column, "role", "") == "feature")
    return [column for column in candidates if column in allowed]
end

function project_execution_membership!(project::DataScienceProjectRecord, dataset::AbstractDict, split_plan::AbstractDict, target::AbstractString)
    source_path = resolve_local_data_ref_path(String(get(dataset, "sourceUri", "")))
    source_path === nothing && return nothing
    checksum = local_artifact_checksum(source_path)
    table = JuliaFlowDataScienceProjectSplits.split_table(source_path)
    local_artifact_checksum(source_path) == checksum || error("source evidence unavailable; dataset changed during membership validation")
    membership = JuliaFlowDataScienceProjectSplits.prepare_membership!(project, split_plan, table, checksum, target, local_data_ref_path_for_write)
    membership["table"] = table
    numeric = JuliaFlowDataScienceProjectSplits.training_numeric_columns(table, membership["rows"]["train"])
    membership["featureColumns"] = project_numeric_feature_columns(project, String(get(dataset, "datasetId", "")), numeric, target)
    return membership
end

function split_membership_evidence(membership)
    membership === nothing && return Dict{String,Any}()
    return Dict{String,Any}("sourceChecksumSha256" => membership["sourceChecksumSha256"],
        "splitPlanChecksumSha256" => membership["splitPlanChecksumSha256"],
        "membershipChecksumSha256" => membership["membershipChecksumSha256"],
        "trainingRowIndices" => membership["rows"]["train"], "validationRowIndices" => membership["rows"]["validation"],
        "testRowIndices" => membership["rows"]["test"])
end

function local_csv_training_artifact!(
    state::GatewayState,
    validation_context::AbstractDict,
    experiment::Dict{String,Any},
    timestamp::AbstractString;
    persist::Bool = true,
)
    project = project_for_model_lifecycle(state, validation_context, "ml experiment training")
    project === nothing && return nothing
    project = deepcopy(project)
    dataset_id = String(experiment["datasetId"])
    dataset_index = findfirst(dataset -> String(get(dataset, "datasetId", "")) == dataset_id, project.datasets)
    dataset_index === nothing && return nothing
    dataset = project.datasets[dataset_index]
    target_column = String(experiment["target"])
    split_plan = project_split_plan_for_request(project, validation_context, dataset_id, "ml experiment")
    membership = project_execution_membership!(project, dataset, split_plan, target_column)
    membership === nothing && return nothing
    rows = membership["rows"]
    numeric_columns = JuliaFlowDataScienceProjectSplits.training_numeric_columns(membership["table"], rows["train"])
    haskey(numeric_columns, target_column) || return nothing
    feature_columns = membership["featureColumns"]
    isempty(feature_columns) && return nothing
    target_values = numeric_columns[target_column]
    train_count, validation_count, test_count = length(rows["train"]), length(rows["validation"]), length(rows["test"])
    train_target = target_values[rows["train"]]
    feature_pairs = [column => numeric_columns[column][rows["train"]] for column in feature_columns]
    requested_algorithm = lowercase(String(get(experiment, "modelKind", "")))
    target_labels = sort(unique(train_target))
    classification_requested = occursin("class", requested_algorithm) || occursin("logistic", requested_algorithm) || occursin("xgboost", requested_algorithm)
    binary_classifier = classification_requested && length(target_labels) == 2 ?
        JuliaFlowDataScienceProjectStatistics.simple_binary_centroid_classifier(train_target, feature_pairs) :
        nothing
    ols = binary_classifier === nothing ? (
        length(feature_pairs) == 1 ?
            JuliaFlowDataScienceProjectStatistics.simple_linear_ols(train_target, feature_pairs[1].second) :
            JuliaFlowDataScienceProjectStatistics.simple_multi_linear_ols(train_target, feature_pairs)
    ) : nothing
    (binary_classifier === nothing && ols === nothing) && return nothing
    native_model_kind = binary_classifier !== nothing ? "local_csv_binary_centroid_classifier" : (length(feature_pairs) == 1 ? "local_csv_single_feature_ols" : "local_csv_multi_feature_ols")
    model_kind = JuliaFlowDataScienceProjectMLJ.mlj_model_kind(native_model_kind, String(get(experiment, "modelKind", "")); classifier_mode = binary_classifier !== nothing)
    mlj_evidence = JuliaFlowDataScienceProjectMLJ.mlj_adapter_evidence(
        String(get(experiment, "modelKind", "")),
        native_model_kind,
        feature_columns,
        target_column;
        classifier_mode = binary_classifier !== nothing,
        train_feature_pairs = feature_pairs,
        train_target = train_target,
    )
    machine_artifact_ref = ""
    if persist && Bool(get(mlj_evidence, "mljRequested", false))
        if Bool(get(mlj_evidence, "mljPackageFitExecuted", false))
            machine_artifact_ref = "local://models/$(project.project_id)/$(String(experiment["modelId"]))/machine.jls"
            machine_artifact_path = local_data_ref_path_for_write(machine_artifact_ref)
            persistence_evidence = JuliaFlowDataScienceProjectMLJ.mlj_persist_machine_artifact(
                String(get(experiment, "modelKind", "")),
                feature_pairs,
                train_target,
                machine_artifact_path;
                classifier_mode = binary_classifier !== nothing,
            )
            delete!(persistence_evidence, "mljMachineArtifactPath")
            if String(get(persistence_evidence, "mljMachinePersistenceStatus", "")) == "persisted"
                persistence_evidence["mljMachineArtifactRef"] = machine_artifact_ref
                persistence_evidence["mljMachineArtifactChecksumSha256"] = local_artifact_checksum(machine_artifact_path)
                persistence_evidence["mljMachineArtifactSizeBytes"] = filesize(machine_artifact_path)
                persistence_evidence["mljMachineArtifactChecksumMode"] = "streaming_file_sha256"
            else
                machine_artifact_ref = ""
            end
            merge!(mlj_evidence, persistence_evidence)
        else
            mlj_evidence["mljMachinePersistenceStatus"] = "not_attempted"
            mlj_evidence["mljMachinePersistenceReason"] = "MLJ package fitting did not complete, so no fitted machine artifact was persisted."
        end
    end
    feature_column = first(feature_columns)
    coefficients = if native_model_kind == "local_csv_binary_centroid_classifier"
        Dict{String,Any}(
            "positiveLabel" => binary_classifier["positiveLabel"],
            "negativeLabel" => binary_classifier["negativeLabel"],
            "positivePrior" => binary_classifier["positivePrior"],
            "positiveMeans" => binary_classifier["positiveMeans"],
            "negativeMeans" => binary_classifier["negativeMeans"],
            "featureScales" => binary_classifier["featureScales"],
        )
    elseif native_model_kind == "local_csv_single_feature_ols"
        Dict{String,Any}(
            "intercept" => ols["intercept"],
            "slope" => ols["slope"],
        )
    else
        Dict{String,Any}(
            "intercept" => ols["intercept"],
            "slopes" => ols["slopes"],
        )
    end
    model_id = String(experiment["modelId"])
    artifact_ref = "local://models/$(project.project_id)/$(model_id)/model.json"
    artifact_payload = Dict{String,Any}(
        "modelId" => model_id,
        "modelKind" => model_kind,
        "nativeModelKind" => native_model_kind,
        "modelFamily" => String(get(mlj_evidence, "modelFamily", "")),
        "requestedAlgorithm" => String(get(experiment, "modelKind", "")),
        "projectId" => project.project_id,
        "datasetId" => dataset_id,
        "sourceRef" => String(get(dataset, "sourceUri", "")),
        "targetColumn" => target_column,
        "featureColumn" => feature_column,
        "featureColumns" => feature_columns,
        "splitPlanId" => String(get(validation_context, "splitPlanId", "")),
        "trainRowCount" => train_count,
        "validationRowCount" => validation_count,
        "testRowCount" => test_count,
        "coefficients" => coefficients,
        "metrics" => native_model_kind == "local_csv_binary_centroid_classifier" ?
            Dict{String,Any}("trainAccuracy" => binary_classifier["trainAccuracy"]) :
            Dict{String,Any}("trainR2" => ols["rSquared"], "trainSse" => ols["sse"]),
        "mljEvidence" => mlj_evidence,
        "generatedJuliaCode" => JuliaFlowDataScienceProjectMLJ.mlj_generated_training_code(
            String(get(experiment, "modelKind", "")),
            target_column,
            feature_columns;
            classifier_mode = binary_classifier !== nothing,
        ),
        "createdAt" => String(timestamp),
        "localOnly" => true,
    )
    merge!(artifact_payload, split_membership_evidence(membership))
    JuliaFlowDataScienceProjectEvidence.require_result(artifact_payload, juliaflow_runtime_mode(), "ml experiment training")
    persist || return artifact_payload
    artifact_path = local_data_ref_path_for_write(artifact_ref)
    content = JSON3.write(artifact_payload) * "\n"
    artifact = write_local_artifact!(artifact_path, content)
    training_artifact = Dict{String,Any}(
        "kind" => "trained_model",
        "artifactRef" => artifact_ref,
        "checksumSha256" => artifact["checksumSha256"],
        "sizeBytes" => artifact["sizeBytes"],
        "checksumMode" => artifact["checksumMode"],
        "modelKind" => model_kind,
        "nativeModelKind" => native_model_kind,
        "modelFamily" => String(get(mlj_evidence, "modelFamily", "")),
        "requestedAlgorithm" => String(get(experiment, "modelKind", "")),
        "targetColumn" => target_column,
        "featureColumn" => feature_column,
        "featureColumns" => feature_columns,
        "trainRowCount" => train_count,
        "metrics" => artifact_payload["metrics"],
        "mljEvidence" => mlj_evidence,
    )
    if !isempty(machine_artifact_ref)
        training_artifact["mljMachineArtifactRef"] = machine_artifact_ref
        training_artifact["mljMachineArtifactChecksumSha256"] = String(mlj_evidence["mljMachineArtifactChecksumSha256"])
        training_artifact["mljMachineArtifactSizeBytes"] = Int(mlj_evidence["mljMachineArtifactSizeBytes"])
        training_artifact["mljMachinePredictionMode"] = String(mlj_evidence["mljMachinePredictionMode"])
        training_artifact["mljMachinePositiveLabel"] = String(get(mlj_evidence, "mljMachinePositiveLabel", ""))
    end
    merge!(training_artifact, split_membership_evidence(membership))
    JuliaFlowDataScienceProjectSplits.persist_membership!(membership, local_data_ref_path_for_write)
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    return training_artifact
end

function ml_experiment_output_refs(experiment::AbstractDict, timestamp::AbstractString)
    experiment_id = String(experiment["experimentId"])
    refs = Dict{String,Any}[]
    for (index, artifact) in enumerate(get(experiment, "artifactEvidence", Any[]))
        artifact isa AbstractDict || continue
        artifact_kind = String(get(artifact, "kind", "artifact"))
        push!(
            refs,
            Dict{String,Any}(
                "refId" => "$(experiment_id)-$(artifact_kind)-$(index)",
                "kind" => "training_$(artifact_kind)",
                "localOnly" => true,
                "checksumSha256" => String(get(artifact, "checksumSha256", "")),
                "path" => String(get(artifact, "artifactRef", "")),
                "generatedAt" => String(timestamp),
            ),
        )
    end
    return refs
end

function record_ml_experiment_project_job!(
    state::GatewayState,
    validation_context::AbstractDict,
    experiment::Dict{String,Any},
    source_execution::GatewayExecution,
    timestamp::AbstractString,
)
    project = project_for_model_lifecycle(state, validation_context, "ml experiment training")
    project === nothing && return nothing

    experiment_id = String(experiment["experimentId"])
    dataset_id = String(experiment["datasetId"])
    split_plan_id = String(get(validation_context, "splitPlanId", ""))
    output_refs = ml_experiment_output_refs(experiment, timestamp)
    resource_evidence = data_science_project_job_resource_evidence(state; execution_mode = "training")
    execution_evidence = data_science_project_execution_evidence!(
        state,
        project,
        "training";
        workflow_id = source_execution.workflow_id,
        dataset_id = dataset_id,
        source_record_id = experiment_id,
        output_refs = output_refs,
        resource_evidence = resource_evidence,
        started_at = timestamp,
        finished_at = timestamp,
        plan = ["validate_training_split_policy", "execute_local_training_workflow", "record_training_artifacts"],
        worker_backed = true,
    )
    experiment["executionEvidence"] = execution_evidence
    experiment["validationEvidence"]["executionId"] = execution_evidence["executionId"]
    experiment["validationEvidence"]["trainingExecutionId"] = execution_evidence["executionId"]
    source_execution.metadata["ml_training_execution_evidence"] = execution_evidence
    source_execution.metadata["ml_validation_context"] = experiment["validationEvidence"]
    save_execution!(state.repository, source_execution; producer = "api-gateway")
    record_data_science_project_job!(
        project,
        "training";
        dataset_id = dataset_id,
        split_plan_id = isempty(strip(split_plan_id)) ? nothing : split_plan_id,
        source_record_id = experiment_id,
        output_refs = output_refs,
        resource_evidence = resource_evidence,
        execution_evidence = execution_evidence,
        started_at = timestamp,
        finished_at = timestamp,
    )
    project.updated_at = String(timestamp)
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    return execution_evidence
end

function project_has_dataset(project::DataScienceProjectRecord, dataset_id::AbstractString)
    return JuliaFlowDataScienceProjectExperiments.project_has_dataset(project, dataset_id)
end

function ml_project_for_dataset(state::GatewayState, body::AbstractDict, dataset_id::AbstractString)
    return JuliaFlowDataScienceProjectExperiments.ml_project_for_dataset(state.data_science_projects, body, dataset_id)
end

function ml_split_plan_for_request(project::DataScienceProjectRecord, body::AbstractDict, dataset_id::AbstractString)
    return JuliaFlowDataScienceProjectExperiments.ml_split_plan_for_request(project, body, dataset_id)
end

function validate_ml_experiment_project_context(state::GatewayState, body::AbstractDict, dataset_id::AbstractString)
    return JuliaFlowDataScienceProjectExperiments.validate_ml_experiment_project_context(state.data_science_projects, body, dataset_id)
end

function model_validation_context(execution::GatewayExecution, action::AbstractString)
    haskey(execution.metadata, "ml_validation_context") ||
        error("$(String(action)) validation evidence required")
    return Dict{String,Any}(
        String(key) => value for (key, value) in pairs(execution.metadata["ml_validation_context"])
    )
end

function project_for_model_lifecycle(state::GatewayState, validation_context::AbstractDict, action::AbstractString)
    return JuliaFlowDataScienceProjectRegistry.project_for_validation_context(
        state.data_science_projects,
        validation_context,
        action,
    )
end

function upsert_project_model_registry!(state::GatewayState, model_record::AbstractDict)
    validation_context = get(model_record, "validationEvidence", Dict{String,Any}())
    project = project_for_model_lifecycle(state, validation_context, "model registry")
    project === nothing && return nothing

    record = JuliaFlowGatewayRepository.save_model_registry_record!(state.repository, model_record; producer = "api-gateway")
    refreshed = Dict(item.project_id => item for item in JuliaFlowGatewayRepository.load_data_science_projects(state.repository))
    haskey(refreshed, project.project_id) && (state.data_science_projects[project.project_id] = refreshed[project.project_id])
    return record
end

function upsert_project_model_lifecycle!(
    state::GatewayState,
    validation_context::AbstractDict,
    model_id::AbstractString,
    lifecycle_state::AbstractString;
    evaluation_report_id::Union{Nothing,AbstractString} = nothing,
    deployed_endpoint_id::Union{Nothing,AbstractString} = nothing,
    updated_at::Union{Nothing,AbstractString} = nothing,
)
    project = project_for_model_lifecycle(state, validation_context, "model lifecycle")
    project === nothing && return nothing

    record = JuliaFlowDataScienceProjectRegistry.upsert_model_lifecycle_record!(
        project,
        validation_context,
        model_id,
        lifecycle_state;
        evaluation_report_id = evaluation_report_id,
        deployed_endpoint_id = deployed_endpoint_id,
        updated_at = updated_at,
    )
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    return record
end

function deploy_package_record_by_id(state::GatewayState, package_id::AbstractString)
    for execution in reverse(state.executions)
        for package_record in deploy_package_records(execution)
            String(get(package_record, "packageId", "")) == String(package_id) || continue
            return execution, package_record
        end
    end
    return nothing, nothing
end

function rollback_deploy_package_payload!(
    state::GatewayState,
    lifecycle_record::Dict{String,Any},
    timestamp::AbstractString,
)
    source_package_id = String(get(lifecycle_record, "deployedEndpointId", ""))
    rollback_model_id = String(get(lifecycle_record, "rollbackModelId", ""))
    isempty(strip(source_package_id)) && error("model lifecycle rollback source package required")
    isempty(strip(rollback_model_id)) && error("model lifecycle rollback target model required")
    source_execution, source_package = deploy_package_record_by_id(state, source_package_id)
    source_execution === nothing && error("model lifecycle rollback source package not found: $(source_package_id)")
    workflow_id = String(source_package["workflowId"])
    haskey(state.workflows, workflow_id) || error("model lifecycle rollback workflow not found: $(workflow_id)")

    endpoint_config = Dict{String,Any}(
        "endpointUrl" => String(source_package["endpointUrl"]),
        "endpointPath" => String(source_package["endpointPath"]),
        "host" => String(source_package["host"]),
        "port" => Int(source_package["port"]),
    )
    package_id = "rollback-" * replace(string(uuid4()), "-" => "")
    rollback_model_ref = "local://models/$(rollback_model_id).json"
    service_code = local_deploy_service_code(rollback_model_id, String(endpoint_config["endpointUrl"]), rollback_model_ref)
    workflow_payload = JuliaFlowGatewayRepository.workflow_detail_payload(state.workflows[workflow_id])
    config_payload = Dict{String,Any}(
        "endpointPath" => String(endpoint_config["endpointPath"]),
        "host" => String(endpoint_config["host"]),
        "port" => Int(endpoint_config["port"]),
        "checkpointTag" => String(source_package["checkpointTag"]),
        "rollbackFromModelId" => String(lifecycle_record["modelId"]),
        "rollbackTargetModelId" => rollback_model_id,
        "rollbackSourcePackageId" => source_package_id,
    )
    rollback_model_record = Dict{String,Any}(
        "modelId" => rollback_model_id,
        "checkpointTag" => String(source_package["checkpointTag"]),
        "artifactEvidence" => [
            Dict{String,Any}(
                "kind" => "model",
                "artifactRef" => rollback_model_ref,
                "checksumSha256" => bytes2hex(sha256(Vector{UInt8}(codeunits(rollback_model_ref)))),
            ),
        ],
    )
    artifact_evidence = JuliaFlowDataScienceProjectDeploy.deploy_artifact_evidence(
        workflow_id,
        rollback_model_record,
        package_id,
        service_code,
        artifact_checksum(workflow_payload),
        artifact_checksum(config_payload),
    )
    validation_context = get(source_package, "validationEvidence", Dict{String,Any}())
    validation_context = validation_context isa AbstractDict ? Dict{String,Any}(String(key) => value for (key, value) in pairs(validation_context)) : Dict{String,Any}()
    validation_context["lifecycleAction"] = "mark_rolled_back"
    validation_context["rollbackFromModelId"] = String(lifecycle_record["modelId"])
    validation_context["rollbackTargetModelId"] = rollback_model_id
    validation_context["rollbackSourcePackageId"] = source_package_id

    package_record = JuliaFlowDataScienceProjectDeploy.deploy_package_record(
        workflow_id,
        workflow_payload,
        rollback_model_record,
        validation_context,
        package_id,
        endpoint_config,
        service_code,
        artifact_evidence,
        timestamp,
    )
    package_record["deploymentStatus"] = "rolled_back"
    package_record["rollbackFromModelId"] = String(lifecycle_record["modelId"])
    package_record["rollbackTargetModelId"] = rollback_model_id
    package_record["rollbackSourcePackageId"] = source_package_id
    haskey(lifecycle_record, "rollbackReason") && (package_record["rollbackReason"] = String(lifecycle_record["rollbackReason"]))
    package_record["packageChecksumSha256"] = artifact_checksum(JuliaFlowDataScienceProjectDeploy.deploy_package_checksum_payload(package_record))

    source_execution.metadata["deploy_package_records"] = [package_record, deploy_package_records(source_execution)...]
    save_execution!(state.repository, source_execution; producer = "api-gateway")
    lifecycle_record["deployedEndpointId"] = package_id
    lifecycle_record["rollbackPackageId"] = package_id
    lifecycle_record["rollbackPackageRef"] = String(package_record["packageRef"])
    lifecycle_record["validationEvidence"]["rollbackPackageId"] = package_id
    lifecycle_record["validationEvidence"]["rollbackPackageRef"] = String(package_record["packageRef"])
    lifecycle_record["validationEvidence"]["rollbackSourcePackageId"] = source_package_id
    return package_record
end

function project_model_registry_record_by_model_id(project::DataScienceProjectRecord, model_id::AbstractString)
    match = findfirst(record -> String(get(record, "modelId", "")) == String(model_id), project.model_registry_records)
    match === nothing && error("model registry record not found: $(String(model_id))")
    return Dict{String,Any}(String(key) => value for (key, value) in pairs(project.model_registry_records[match]))
end

function retraining_tuning_payload!(
    state::GatewayState,
    project::DataScienceProjectRecord,
    lifecycle_record::Dict{String,Any},
    timestamp::AbstractString,
)
    model_id = String(lifecycle_record["modelId"])
    registry_record = project_model_registry_record_by_model_id(project, model_id)
    registry_validation = get(registry_record, "validationEvidence", Dict{String,Any}())
    validation_seed = registry_validation isa AbstractDict ? Dict{String,Any}(String(key) => value for (key, value) in pairs(registry_validation)) : Dict{String,Any}()
    dataset_id = String(get(registry_record, "datasetId", get(validation_seed, "datasetId", "")))
    isempty(strip(dataset_id)) && !isempty(project.datasets) && (dataset_id = String(get(project.datasets[1], "datasetId", "")))
    isempty(strip(dataset_id)) && error("model lifecycle retraining dataset evidence required")
    target_column = String(get(registry_record, "target", get(validation_seed, "targetColumn", "")))
    isempty(strip(target_column)) && error("model lifecycle retraining target evidence required")
    split_plan_id = String(get(validation_seed, "splitPlanId", ""))
    tuning_body = Dict{String,Any}(
        "datasetId" => dataset_id,
        "targetColumn" => target_column,
        "taskType" => String(get(registry_record, "taskType", "regression")),
        "algorithm" => String(get(registry_record, "modelKind", "MLJ.EvoTreesRegressor")),
        "metricNames" => [String(get(registry_record, "primaryMetricName", "rmse"))],
        "maxTrials" => 3,
        "finalTestPolicy" => "forbid_final_test",
    )
    isempty(strip(split_plan_id)) || (tuning_body["splitPlanId"] = split_plan_id)
    split_plan, validation_context = validate_tuning_split_context(project, tuning_body, dataset_id)
    validation_context["lifecycleAction"] = "request_retraining"
    validation_context["retrainingOfModelId"] = model_id
    validation_context["sourceLifecycleState"] = String(get(lifecycle_record["validationEvidence"], "previousState", ""))
    validation_context["deployedEndpointId"] = String(get(lifecycle_record, "deployedEndpointId", ""))
    haskey(lifecycle_record, "retrainingReason") && (validation_context["reason"] = String(lifecycle_record["retrainingReason"]))

    training_plan_id = "retraining-" * replace(string(uuid4()), "-" => "")
    training_plan = JuliaFlowDataScienceProjectTuning.tuning_training_plan_record(
        training_plan_id,
        target_column,
        String(tuning_body["taskType"]),
        tuning_body["metricNames"],
        split_plan,
        timestamp,
    )
    training_plan["sourceModelId"] = model_id
    training_plan["lifecycleAction"] = "request_retraining"
    training_plan["validationEvidence"] = Dict{String,Any}(String(key) => value for (key, value) in pairs(validation_context))
    JuliaFlowDataScienceProjectTuning.upsert_training_plan!(project, training_plan)

    study_id = "retraining-tuning-" * replace(string(uuid4()), "-" => "")
    resource_evidence = data_science_project_job_resource_evidence(state; execution_mode = "retraining")
    dataset = data_science_project_dataset(project, dataset_id)
    membership = JuliaFlowDataScienceProjectEvidence.read_result(() -> project_execution_membership!(project, dataset, split_plan, target_column), juliaflow_runtime_mode(), "model lifecycle retraining")
    merge!(validation_context, split_membership_evidence(membership))
    trials = local_csv_validation_tuning_trials(dataset, split_plan, project.project_id, study_id,
        String(tuning_body["algorithm"]), tuning_body["metricNames"], Int(tuning_body["maxTrials"]),
        timestamp, target_column, String(get(resource_evidence, "selectedBackend", "cpu")); membership = membership)
    JuliaFlowDataScienceProjectEvidence.require_result(trials, juliaflow_runtime_mode(), "model lifecycle retraining")
    if trials === nothing
        trials = JuliaFlowDataScienceProjectTuning.tuning_trials(project.project_id, study_id, String(tuning_body["algorithm"]), tuning_body["metricNames"], Int(tuning_body["maxTrials"]), timestamp)
        validation_context["tuningExecutionMode"] = "deterministic_fallback"
    else
        validation_context["tuningExecutionMode"] = "local_csv_validation_tuning"
    end
    membership === nothing || JuliaFlowDataScienceProjectSplits.persist_membership!(membership, local_data_ref_path_for_write)
    annotate_tuning_trial_resource_evidence!(trials, resource_evidence)
    persist_tuning_trial_artifacts!(trials)
    tuning_study = JuliaFlowDataScienceProjectTuning.tuning_study_record(study_id, training_plan_id, trials, validation_context, timestamp)
    tuning_study["sourceModelId"] = model_id
    tuning_study["lifecycleAction"] = "request_retraining"
    tuning_output_refs = JuliaFlowDataScienceProjectTuning.tuning_output_refs(trials)
    execution_evidence = data_science_project_execution_evidence!(
        state,
        project,
        "retraining";
        dataset_id = dataset_id,
        source_record_id = model_id,
        output_refs = tuning_output_refs,
        resource_evidence = resource_evidence,
        started_at = timestamp,
        finished_at = timestamp,
        plan = ["validate_retraining_request", "enforce_validation_only_tuning", "run_retraining_trials", "record_retraining_review_candidate"],
        worker_backed = true,
    )
    tuning_study["executionEvidence"] = execution_evidence
    tuning_study["validationEvidence"]["executionId"] = execution_evidence["executionId"]
    project.tuning_studies = [tuning_study, project.tuning_studies...]
    retraining_job = record_data_science_project_job!(
        project,
        "retraining";
        dataset_id = dataset_id,
        split_plan_id = String(get(split_plan, "splitPlanId", "")),
        source_record_id = model_id,
        output_refs = tuning_output_refs,
        resource_evidence = resource_evidence,
        execution_evidence = execution_evidence,
        started_at = timestamp,
        finished_at = timestamp,
    )
    return Dict{String,Any}(
        "trainingPlan" => training_plan,
        "tuningStudy" => tuning_study,
        "job" => retraining_job,
        "executionEvidence" => execution_evidence,
    )
end

function model_lifecycle_action_response!(state::GatewayState, project_id::AbstractString, body::AbstractDict)
    haskey(state.data_science_projects, project_id) || error("data science project not found: $(project_id)")
    ensure_cpu_project_job_allowed(state)
    project = deepcopy(state.data_science_projects[project_id])
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    record, index = JuliaFlowDataScienceProjectRegistry.model_lifecycle_action_record(
        project,
        body,
        timestamp,
    )
    model_id = String(record["modelId"])
    if String(get(record, "lifecycleAction", "")) in ("approve_model", "mark_rollback_ready", "mark_rolled_back", "request_retraining")
        JuliaFlowDataScienceProjectEvidence.context_evaluation(project, record, juliaflow_runtime_mode(), "model lifecycle"; required = true, resolve_path = local_data_ref_path_for_write)
        if !fixture_substitution_allowed(juliaflow_runtime_mode())
            target_model_id = String(get(record, "lifecycleAction", "")) == "mark_rolled_back" ? String(get(record, "rollbackModelId", "")) : model_id
            registry = project_model_registry_record_by_model_id(project, target_model_id)
            model_artifact = JuliaFlowDataScienceProjectDeploy.deploy_model_artifact(registry)
            model_payload = JuliaFlowDataScienceProjectEvidence.require_model_artifact(model_artifact, juliaflow_runtime_mode(), "model lifecycle", local_data_ref_path_for_write)
            registry_report = JuliaFlowDataScienceProjectEvidence.context_evaluation(project, get(registry, "validationEvidence", Dict{String,Any}()), juliaflow_runtime_mode(), "model lifecycle"; required = true, resolve_path = local_data_ref_path_for_write)
            JuliaFlowDataScienceProjectEvidence.require_evaluation_model_binding(project, registry_report, model_payload,
                model_artifact, juliaflow_runtime_mode(), "model lifecycle", resolve_local_data_ref_path)
            if String(get(record, "lifecycleAction", "")) != "mark_rolled_back"
                get(registry_report, "evaluationReportId", "") == get(record, "evaluationReportId", "") || JuliaFlowDataScienceProjectEvidence.unavailable("model lifecycle")
            end
        end
    end
    rollback_package_record = nothing
    retraining_payload = nothing
    if String(get(record, "lifecycleAction", "")) == "mark_rolled_back"
        rollback_package_record = rollback_deploy_package_payload!(state, record, timestamp)
    elseif String(get(record, "lifecycleAction", "")) == "request_retraining"
        retraining_payload = retraining_tuning_payload!(state, project, record, timestamp)
        record["retrainingTrainingPlanId"] = String(retraining_payload["trainingPlan"]["trainingPlanId"])
        record["retrainingTuningStudyId"] = String(retraining_payload["tuningStudy"]["tuningStudyId"])
        record["retrainingJobId"] = String(retraining_payload["job"]["jobId"])
        record["validationEvidence"]["retrainingTrainingPlanId"] = String(record["retrainingTrainingPlanId"])
        record["validationEvidence"]["retrainingTuningStudyId"] = String(record["retrainingTuningStudyId"])
        record["validationEvidence"]["retrainingJobId"] = String(record["retrainingJobId"])
        record["validationEvidence"]["retrainingExecutionId"] = String(retraining_payload["executionEvidence"]["executionId"])
    end

    remaining = [item for (item_index, item) in enumerate(project.model_lifecycle_records) if item_index != index]
    project.model_lifecycle_records = [record, remaining...]
    registry_record = nothing
    if String(get(record, "state", "")) in ("approved", "deprecated", "archived", "rolled_back", "retraining_requested")
        registry_record = JuliaFlowDataScienceProjectRegistry.update_model_registry_lifecycle_status!(
            project,
            model_id,
            String(record["state"]),
            timestamp;
            validation_evidence = record["validationEvidence"],
        )
        if String(get(record, "state", "")) == "rolled_back"
            registry_record["deploymentStatus"] = "rolled_back"
            registry_record["rollbackModelId"] = String(get(record, "rollbackModelId", ""))
            registry_record["rollbackPackageId"] = String(get(record, "rollbackPackageId", ""))
        elseif String(get(record, "state", "")) == "retraining_requested"
            registry_record["retrainingTrainingPlanId"] = String(get(record, "retrainingTrainingPlanId", ""))
            registry_record["retrainingTuningStudyId"] = String(get(record, "retrainingTuningStudyId", ""))
            registry_record["retrainingJobId"] = String(get(record, "retrainingJobId", ""))
        end
    end
    resource_evidence = data_science_project_job_resource_evidence(state; execution_mode = "model_lifecycle_action")
    execution_evidence = data_science_project_execution_evidence!(
        state,
        project,
        "model_lifecycle";
        source_record_id = model_id,
        resource_evidence = resource_evidence,
        started_at = timestamp,
        finished_at = timestamp,
        plan = ["validate_model_lifecycle_state", "record_local_lifecycle_transition"],
        worker_backed = true,
    )
    record["validationEvidence"]["executionId"] = execution_evidence["executionId"]
    rollback_package_record === nothing || (record["validationEvidence"]["rollbackPackageExecutionId"] = execution_evidence["executionId"])
    record_data_science_project_job!(
        project,
        "model_lifecycle";
        source_record_id = model_id,
        resource_evidence = resource_evidence,
        execution_evidence = execution_evidence,
        started_at = timestamp,
        finished_at = timestamp,
    )
    project.updated_at = timestamp
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    if registry_record !== nothing
        JuliaFlowGatewayRepository.save_model_registry_record!(state.repository, registry_record; producer = "api-gateway")
        refreshed = Dict(item.project_id => item for item in JuliaFlowGatewayRepository.load_data_science_projects(state.repository))
        haskey(refreshed, project.project_id) && (state.data_science_projects[project.project_id] = refreshed[project.project_id])
    end
    payload = JuliaFlowGatewayRepository.data_science_project_payload(state.data_science_projects[project.project_id])
    return JSON3.write(Dict("status" => "completed", "lifecycleRecord" => record, "project" => payload))
end

function ml_experiment_payload(state::GatewayState, execution::GatewayExecution; request_body::AbstractDict = Dict{String,Any}())
    haskey(state.workflows, execution.workflow_id) || error("workflow not found: $(execution.workflow_id)")
    workflow = state.workflows[execution.workflow_id]
    evidence = haskey(execution.metadata, "explainability_evidence") ?
        execution.metadata["explainability_evidence"] :
        gateway_explainability_evidence(state; checkpoint_tag = execution.checkpoint_tag)
    dataset_card = evidence["datasetCard"]
    model_card = evidence["modelCard"]
    explanation = evidence["explanation"]
    health = JSON3.read(healthcheck(state), Dict{String,Any})
    dataset_id = haskey(request_body, "datasetId") ? String(request_body["datasetId"]) : String(dataset_card["datasetId"])
    target = haskey(request_body, "target") ? String(request_body["target"]) : String(model_card["target"])
    model_kind = haskey(request_body, "algorithm") ? String(request_body["algorithm"]) : String(model_card["kind"])
    validation_context = haskey(execution.metadata, "ml_validation_context") ?
        json_compatible_value(execution.metadata["ml_validation_context"]) :
        Dict{String,Any}()

    payload = Dict{String,Any}(
        "experimentId" => "ml-" * execution.execution_id,
        "workflowId" => execution.workflow_id,
        "workflowVersion" => workflow.version,
        "executionId" => execution.execution_id,
        "checkpointTag" => execution.checkpoint_tag,
        "status" => execution.status,
        "modelId" => String(model_card["modelId"]),
        "modelKind" => model_kind,
        "target" => target,
        "datasetId" => dataset_id,
        "datasetChecksumSha256" => String(dataset_card["checksumSha256"]),
        "metrics" => model_card["metrics"],
        "featureImportance" => explanation["featureImportance"],
        "hardwareBackend" => String(health["hardwareSelectedBackend"]),
        "gpuReadinessStatus" => String(health["gpuReadinessStatus"]),
        "artifactEvidence" => ml_experiment_artifact_refs(execution, evidence),
        "validationEvidence" => validation_context,
        "startedAt" => execution.started_at === nothing ? execution.created_at : execution.started_at,
        "finishedAt" => execution.finished_at,
        "localOnly" => true,
    )
    if haskey(execution.metadata, "ml_training_execution_evidence")
        payload["executionEvidence"] = execution.metadata["ml_training_execution_evidence"]
    end
    if haskey(execution.metadata, "ml_training_metrics")
        measured = normalized_string_dict(execution.metadata["ml_training_metrics"])
        payload["metrics"] = fixture_substitution_allowed(juliaflow_runtime_mode()) ?
            merge(Dict{String,Any}(String(key) => value for (key, value) in pairs(payload["metrics"])), measured) : measured
    end
    if haskey(execution.metadata, "ml_training_artifact_evidence")
        artifact = json_compatible_value(execution.metadata["ml_training_artifact_evidence"])
        artifact_ref = String(get(artifact, "artifactRef", ""))
        existing_refs = Set(String(get(item, "artifactRef", "")) for item in payload["artifactEvidence"])
        artifact_ref in existing_refs || push!(payload["artifactEvidence"], artifact)
        payload["validationEvidence"]["trainingArtifactRef"] = artifact_ref
        payload["validationEvidence"]["trainingArtifactChecksumSha256"] = String(get(artifact, "checksumSha256", ""))
        payload["validationEvidence"]["trainingExecutionMode"] = String(get(artifact, "modelKind", ""))
        payload["validationEvidence"]["trainingFeatureColumn"] = String(get(artifact, "featureColumn", ""))
        payload["validationEvidence"]["trainingFeatureColumns"] = get(artifact, "featureColumns", String[])
        payload["validationEvidence"]["trainingRowCount"] = Int(get(artifact, "trainRowCount", 0))
    end
    return json_compatible_value(payload)
end

function ml_experiment_run_response!(state::GatewayState, workflow_id::AbstractString, body::AbstractDict; auth_context = nothing)
    ensure_cpu_project_job_allowed(state)
    flow_variable_values = haskey(body, "flowVariables") ? normalized_string_dict(body["flowVariables"]) : Dict{String,Any}()
    execution_mode_override = haskey(body, "executionMode") ? String(body["executionMode"]) : nothing
    evidence = gateway_explainability_evidence(state)
    dataset_card = evidence["datasetCard"]
    dataset_id = haskey(body, "datasetId") ? String(body["datasetId"]) : String(dataset_card["datasetId"])
    validation_context = validate_ml_experiment_project_context(state, body, dataset_id)
    if auth_context !== nothing && haskey(validation_context, "projectId")
        enforce_resource_policy!(state, auth_context, "workflow:write", "data_science_project", String(validation_context["projectId"]))
    end
    if !fixture_substitution_allowed(juliaflow_runtime_mode())
        model_card = evidence["modelCard"]
        preview = Dict{String,Any}("datasetId" => dataset_id, "modelId" => String(model_card["modelId"]),
            "target" => String(get(body, "target", model_card["target"])), "modelKind" => String(get(body, "algorithm", model_card["kind"])))
        JuliaFlowDataScienceProjectEvidence.read_result(() -> local_csv_training_artifact!(state, validation_context, preview,
            JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(); persist = false), juliaflow_runtime_mode(), "ml experiment training")
    end
    execution = JSON3.read(
        execution_accept_response(
            state,
            workflow_id;
            flow_variable_values = flow_variable_values,
            execution_mode_override = execution_mode_override,
        ),
        Dict{String,Any},
    )
    execution_id = String(execution["executionId"])
    matched = findfirst(item -> item.execution_id == execution_id, state.executions)
    matched === nothing && error("ML experiment execution not found: $(execution_id)")
    isempty(validation_context) || (state.executions[matched].metadata["ml_validation_context"] = validation_context)
    experiment = ml_experiment_payload(state, state.executions[matched]; request_body = body)
    if !isempty(validation_context)
        training_artifact = local_csv_training_artifact!(
            state,
            validation_context,
            experiment,
            JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        )
        JuliaFlowDataScienceProjectEvidence.require_result(training_artifact, juliaflow_runtime_mode(), "ml experiment training")
        if training_artifact !== nothing
            state.executions[matched].metadata["ml_training_artifact_evidence"] = training_artifact
            state.executions[matched].metadata["ml_training_metrics"] = get(training_artifact, "metrics", Dict{String,Any}())
            push!(experiment["artifactEvidence"], training_artifact)
            measured = normalized_string_dict(get(training_artifact, "metrics", Dict{String,Any}()))
            experiment["metrics"] = fixture_substitution_allowed(juliaflow_runtime_mode()) ?
                merge(Dict{String,Any}(String(key) => value for (key, value) in pairs(experiment["metrics"])), measured) : measured
            experiment["validationEvidence"]["trainingArtifactRef"] = String(get(training_artifact, "artifactRef", ""))
            experiment["validationEvidence"]["trainingArtifactChecksumSha256"] = String(get(training_artifact, "checksumSha256", ""))
            experiment["validationEvidence"]["trainingExecutionMode"] = String(get(training_artifact, "modelKind", ""))
            experiment["validationEvidence"]["trainingFeatureColumn"] = String(get(training_artifact, "featureColumn", ""))
            experiment["validationEvidence"]["trainingFeatureColumns"] = get(training_artifact, "featureColumns", String[])
            experiment["validationEvidence"]["trainingRowCount"] = Int(get(training_artifact, "trainRowCount", 0))
        end
        record_ml_experiment_project_job!(
            state,
            validation_context,
            experiment,
            state.executions[matched],
            JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        )
    end
    return JSON3.write(Dict("status" => "accepted", "execution" => execution, "experiment" => experiment))
end

function ml_experiment_history_response(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    experiments = Dict{String,Any}[]
    for execution in reverse(state.executions)
        execution.workflow_id == workflow_id || continue
        haskey(execution.metadata, "explainability_evidence") || continue
        (haskey(execution.metadata, "ml_validation_context") || haskey(execution.metadata, "ml_training_execution_evidence")) || continue
        try
            push!(experiments, ml_experiment_payload(state, execution))
        catch error
            @error "Failed to materialize ML experiment history payload" execution_id = execution.execution_id exception = (error, catch_backtrace())
            rethrow()
        end
    end
    return JSON3.write(Dict("items" => experiments, "count" => length(experiments)))
end

function model_registry_metric(model_card::AbstractDict)
    return JuliaFlowDataScienceProjectRegistryPayloads.model_registry_metric(model_card)
end

function model_registry_payload(state::GatewayState, execution::GatewayExecution; request_body::AbstractDict = Dict{String,Any}())
    haskey(state.workflows, execution.workflow_id) || error("workflow not found: $(execution.workflow_id)")
    workflow = state.workflows[execution.workflow_id]
    evidence = haskey(execution.metadata, "explainability_evidence") ?
        execution.metadata["explainability_evidence"] :
        gateway_explainability_evidence(state; checkpoint_tag = execution.checkpoint_tag)
    model_card = evidence["modelCard"]
    dataset_card = evidence["datasetCard"]
    now = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    existing = haskey(execution.metadata, "model_registry_record") ? execution.metadata["model_registry_record"] : Dict{String,Any}()
    validation_context = model_validation_context(execution, "model registration")

    record = JuliaFlowDataScienceProjectRegistryPayloads.model_registry_record(
        execution.workflow_id,
        workflow.version,
        execution.execution_id,
        execution.checkpoint_tag,
        model_card,
        dataset_card,
        validation_context,
        request_body,
        existing,
        now,
    )
    if haskey(execution.metadata, "ml_training_artifact_evidence")
        artifact = execution.metadata["ml_training_artifact_evidence"]
        model_artifact = Dict{String,Any}(
            "kind" => "model",
            "artifactRef" => String(get(artifact, "artifactRef", "")),
            "checksumSha256" => String(get(artifact, "checksumSha256", "")),
            "sizeBytes" => Int(get(artifact, "sizeBytes", 0)),
            "modelKind" => String(get(artifact, "modelKind", "")),
            "nativeModelKind" => String(get(artifact, "nativeModelKind", String(get(artifact, "modelKind", "")))),
            "modelFamily" => String(get(artifact, "modelFamily", "")),
            "requestedAlgorithm" => String(get(artifact, "requestedAlgorithm", "")),
            "targetColumn" => String(get(artifact, "targetColumn", "")),
            "featureColumn" => String(get(artifact, "featureColumn", "")),
            "featureColumns" => get(artifact, "featureColumns", String[]),
            "trainRowCount" => Int(get(artifact, "trainRowCount", 0)),
        )
        haskey(artifact, "mljEvidence") && (model_artifact["mljEvidence"] = artifact["mljEvidence"])
        for key in (
            "mljMachineArtifactRef",
            "mljMachineArtifactChecksumSha256",
            "mljMachineArtifactSizeBytes",
            "mljMachinePredictionMode",
            "mljMachinePositiveLabel",
        )
            haskey(artifact, key) && (model_artifact[key] = artifact[key])
        end
        artifacts = [item for item in get(record, "artifactEvidence", Any[]) if String(get(item, "kind", "")) != "model"]
        record["artifactEvidence"] = [model_artifact, artifacts...]
        record["modelKind"] = String(get(artifact, "modelKind", record["modelKind"]))
        record["validationEvidence"]["trainingNativeModelKind"] = String(get(artifact, "nativeModelKind", String(get(artifact, "modelKind", ""))))
        record["validationEvidence"]["trainingModelFamily"] = String(get(artifact, "modelFamily", ""))
        record["validationEvidence"]["trainingRequestedAlgorithm"] = String(get(artifact, "requestedAlgorithm", ""))
        record["validationEvidence"]["trainingArtifactRef"] = String(get(artifact, "artifactRef", ""))
        record["validationEvidence"]["trainingArtifactChecksumSha256"] = String(get(artifact, "checksumSha256", ""))
        record["validationEvidence"]["trainingExecutionMode"] = String(get(artifact, "modelKind", ""))
        record["validationEvidence"]["trainingFeatureColumn"] = String(get(artifact, "featureColumn", ""))
        record["validationEvidence"]["trainingFeatureColumns"] = get(artifact, "featureColumns", String[])
        record["validationEvidence"]["trainingRowCount"] = Int(get(artifact, "trainRowCount", 0))
        haskey(artifact, "mljMachineArtifactRef") && begin
            record["validationEvidence"]["mljMachineArtifactRef"] = artifact["mljMachineArtifactRef"]
            record["validationEvidence"]["mljMachineArtifactChecksumSha256"] = artifact["mljMachineArtifactChecksumSha256"]
        end
    end
    return record
end

function latest_model_execution(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    matching = [
        execution for execution in reverse(state.executions)
        if execution.workflow_id == workflow_id &&
            haskey(execution.metadata, "explainability_evidence") &&
            (haskey(execution.metadata, "ml_validation_context") || haskey(execution.metadata, "ml_training_artifact_evidence"))
    ]
    isempty(matching) && (matching = [
        execution for execution in reverse(state.executions)
        if execution.workflow_id == workflow_id && haskey(execution.metadata, "explainability_evidence")
    ])
    return isempty(matching) ? nothing : matching[1]
end

function strict_model_execution_evidence(state::GatewayState, execution::GatewayExecution, action::AbstractString; evaluation_required::Bool = false)
    mode = juliaflow_runtime_mode()
    fixture_substitution_allowed(mode) && return nothing, nothing
    context = model_validation_context(execution, action)
    project = project_for_model_lifecycle(state, context, action)
    artifact = JuliaFlowDataScienceProjectEvidence.require_model_artifact(
        get(execution.metadata, "ml_training_artifact_evidence", nothing), mode, action, local_data_ref_path_for_write)
    project === nothing && JuliaFlowDataScienceProjectEvidence.unavailable(action)
    get(artifact, "projectId", "") == project.project_id || JuliaFlowDataScienceProjectEvidence.unavailable(action)
    get(artifact, "splitPlanId", "") == get(context, "splitPlanId", "") || JuliaFlowDataScienceProjectEvidence.unavailable(action)
    report = JuliaFlowDataScienceProjectEvidence.context_evaluation(project, context, mode, action; required = evaluation_required, resolve_path = local_data_ref_path_for_write)
    if report !== nothing
        validation = get(report, "validationEvidence", Dict{String,Any}())
        get(validation, "datasetId", "") == get(artifact, "datasetId", "") || JuliaFlowDataScienceProjectEvidence.unavailable(action)
        evidence = get(validation, "evaluationDataEvidence", Dict{String,Any}())
        get(evidence, "targetColumn", "") == get(artifact, "targetColumn", "") || JuliaFlowDataScienceProjectEvidence.unavailable(action)
        JuliaFlowDataScienceProjectEvidence.require_evaluation_model_binding(project, report, artifact,
            get(execution.metadata, "ml_training_artifact_evidence", Dict{String,Any}()), mode, action, resolve_local_data_ref_path)
    end
    return artifact, report
end

function enforce_model_registry_destination_policy!(state::GatewayState, auth_context, record::AbstractDict)
    auth_context === nothing && return nothing
    context = get(record, "validationEvidence", Dict{String,Any}())
    if haskey(context, "projectId")
        enforce_resource_policy!(state, auth_context, "workflow:write", "data_science_project", String(context["projectId"]))
    end
    # Model IDs are global upsert keys. Authorize the record being replaced too.
    for existing in JuliaFlowGatewayRepository.load_model_registry_records(state.repository)
        get(existing, "modelId", "") == get(record, "modelId", "") || continue
        existing_context = get(existing, "validationEvidence", Dict{String,Any}())
        haskey(existing_context, "projectId") || continue
        enforce_resource_policy!(state, auth_context, "workflow:write", "data_science_project", String(existing_context["projectId"]))
    end
    return nothing
end

function model_register_response!(state::GatewayState, workflow_id::AbstractString, body::AbstractDict; auth_context = nothing)
    execution = latest_model_execution(state, workflow_id)
    execution === nothing && error("model evidence not found for workflow: $(workflow_id)")
    validation_context = get(execution.metadata, "ml_validation_context", Dict{String,Any}())
    if auth_context !== nothing && haskey(validation_context, "projectId")
        enforce_resource_policy!(state, auth_context, "workflow:write", "data_science_project", String(validation_context["projectId"]))
    end
    artifact, report = strict_model_execution_evidence(state, execution, "model registration")
    if !fixture_substitution_allowed(juliaflow_runtime_mode())
        String(get(body, "status", "registered")) == "registered" || error("model registration source evidence unavailable for direct status promotion; use lifecycle review")
    end
    record = model_registry_payload(state, execution; request_body = body)
    if artifact !== nothing
        record["datasetId"] = artifact["datasetId"]
        record["target"] = artifact["targetColumn"]
        source_path = resolve_local_data_ref_path(String(get(artifact, "sourceRef", "")))
        source_path === nothing && JuliaFlowDataScienceProjectEvidence.unavailable("model registration")
        record["datasetChecksumSha256"] = local_artifact_checksum(source_path)
        metrics = report === nothing ? artifact["metrics"] : report["metrics"]
        metric_name = first(sort(String.(collect(keys(metrics)))))
        record["primaryMetricName"] = metric_name
        record["primaryMetricValue"] = metrics[metric_name]
        record["artifactEvidence"] = [item for item in record["artifactEvidence"] if get(item, "kind", "") == "model"]
        record["validationEvidence"]["datasetId"] = artifact["datasetId"]
        report === nothing || (record["validationEvidence"]["evaluationReportId"] = report["evaluationReportId"])
    end
    enforce_model_registry_destination_policy!(state, auth_context, record)
    execution.metadata["model_registry_record"] = record
    upsert_project_model_registry!(state, record)
    upsert_project_model_lifecycle!(
        state,
        record["validationEvidence"],
        String(record["modelId"]),
        "validated";
        updated_at = String(record["updatedAt"]),
    )
    save_execution!(state.repository, execution; producer = "api-gateway")
    return JSON3.write(Dict("status" => "registered", "model" => record))
end

function model_registry_list_response(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    project_records = JuliaFlowGatewayRepository.load_model_registry_records(state.repository; workflow_id = workflow_id)
    execution_records = [
        haskey(execution.metadata, "model_registry_record") ?
            execution.metadata["model_registry_record"] :
            model_registry_payload(state, execution)
        for execution in reverse(state.executions)
        if execution.workflow_id == workflow_id &&
            haskey(execution.metadata, "explainability_evidence") &&
            (haskey(execution.metadata, "model_registry_record") || haskey(execution.metadata, "ml_validation_context"))
    ]
    records = [project_records..., execution_records...]
    deduped = JuliaFlowDataScienceProjectRegistry.dedupe_model_registry_records(records)
    return JSON3.write(Dict("items" => deduped, "count" => length(deduped)))
end

function local_deploy_service_code(
    model_id::AbstractString,
    endpoint_url::AbstractString,
    model_ref::AbstractString,
    model_artifact = nothing,
)
    return JuliaFlowDataScienceProjectDeploy.local_deploy_service_code(model_id, endpoint_url, model_ref, model_artifact)
end

function deploy_package_records(execution::GatewayExecution)
    return JuliaFlowDataScienceProjectDeploy.deploy_package_records(execution)
end

function deploy_package_output_refs(package_record::AbstractDict, timestamp::AbstractString)
    package_id = String(package_record["packageId"])
    refs = [
        Dict{String,Any}(
            "refId" => package_id,
            "kind" => "deploy_package",
            "localOnly" => true,
            "checksumSha256" => String(package_record["packageChecksumSha256"]),
            "path" => String(package_record["packageRef"]),
            "generatedAt" => String(timestamp),
        ),
    ]
    for (index, artifact) in enumerate(get(package_record, "artifactEvidence", Any[]))
        artifact isa AbstractDict || continue
        artifact_kind = String(get(artifact, "kind", "artifact"))
        push!(
            refs,
            Dict{String,Any}(
                "refId" => "$(package_id)-$(artifact_kind)-$(index)",
                "kind" => "deploy_$(artifact_kind)",
                "localOnly" => true,
                "checksumSha256" => String(get(artifact, "checksumSha256", "")),
                "path" => String(get(artifact, "artifactRef", "")),
                "generatedAt" => String(timestamp),
            ),
        )
    end
    return refs
end

function record_deploy_package_project_job!(
    state::GatewayState,
    validation_context::AbstractDict,
    package_record::Dict{String,Any},
    timestamp::AbstractString,
)
    project = project_for_model_lifecycle(state, validation_context, "deploy package")
    project === nothing && return nothing

    output_refs = deploy_package_output_refs(package_record, timestamp)
    resource_evidence = data_science_project_job_resource_evidence(state; execution_mode = "deploy_package")
    execution_evidence = data_science_project_execution_evidence!(
        state,
        project,
        "deploy_package";
        source_record_id = String(package_record["packageId"]),
        output_refs = output_refs,
        resource_evidence = resource_evidence,
        started_at = timestamp,
        finished_at = timestamp,
        plan = ["validate_deploy_package_evidence", "materialize_local_service_package", "record_deploy_package_artifacts"],
        worker_backed = true,
    )
    package_record["executionEvidence"] = execution_evidence
    package_record["validationEvidence"]["executionId"] = execution_evidence["executionId"]
    package_record["validationEvidence"]["deployPackageExecutionId"] = execution_evidence["executionId"]
    record_data_science_project_job!(
        project,
        "deploy_package";
        source_record_id = String(package_record["packageId"]),
        output_refs = output_refs,
        resource_evidence = resource_evidence,
        execution_evidence = execution_evidence,
        started_at = timestamp,
        finished_at = timestamp,
    )
    project.updated_at = String(timestamp)
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    return execution_evidence
end

function deploy_package_payload!(state::GatewayState, workflow_id::AbstractString, body::AbstractDict; auth_context = nothing)
    ensure_cpu_project_job_allowed(state)
    execution = latest_model_execution(state, workflow_id)
    execution === nothing && error("model evidence not found for workflow: $(workflow_id)")
    validation_context = model_validation_context(execution, "deploy package")
    if auth_context !== nothing && haskey(validation_context, "projectId")
        enforce_resource_policy!(state, auth_context, "workflow:write", "data_science_project", String(validation_context["projectId"]))
    end
    strict_model_execution_evidence(state, execution, "deploy package"; evaluation_required = true)
    model_record = haskey(execution.metadata, "model_registry_record") ?
        Dict{String,Any}(String(key) => value for (key, value) in pairs(execution.metadata["model_registry_record"])) :
        model_registry_payload(state, execution)

    if haskey(body, "modelId") && String(body["modelId"]) != String(model_record["modelId"])
        model_record = model_registry_payload(state, execution; request_body = Dict{String,Any}("modelId" => String(body["modelId"])))
    end
    enforce_model_registry_destination_policy!(state, auth_context, model_record)

    endpoint_config = JuliaFlowDataScienceProjectDeploy.deploy_endpoint_config(body)
    endpoint_url = String(endpoint_config["endpointUrl"])
    package_id = "deploy-" * replace(string(uuid4()), "-" => "")
    model_artifact = JuliaFlowDataScienceProjectDeploy.deploy_model_artifact(model_record)
    model_ref = JuliaFlowDataScienceProjectDeploy.deploy_model_ref(model_record)
    validation_context = Dict{String,Any}(String(key) => value for (key, value) in pairs(validation_context))
    validation_context["deployRuntimeInferenceMode"] = JuliaFlowDataScienceProjectDeploy.deploy_runtime_inference_mode(model_artifact)
    model_artifact === nothing || begin
        validation_context["deployRuntimeModelArtifactRef"] = String(get(model_artifact, "artifactRef", ""))
        validation_context["deployRuntimeModelArtifactChecksumSha256"] = String(get(model_artifact, "checksumSha256", ""))
    end
    service_code = local_deploy_service_code(String(model_record["modelId"]), endpoint_url, model_ref, model_artifact)
    workflow_payload = JuliaFlowGatewayRepository.workflow_detail_payload(state.workflows[String(workflow_id)])
    config_payload = Dict{String,Any}(
        "endpointPath" => String(endpoint_config["endpointPath"]),
        "host" => String(endpoint_config["host"]),
        "port" => Int(endpoint_config["port"]),
        "checkpointTag" => model_record["checkpointTag"],
        "notes" => haskey(body, "notes") ? String(body["notes"]) : "",
    )
    artifact_evidence = JuliaFlowDataScienceProjectDeploy.deploy_artifact_evidence(
        workflow_id,
        model_record,
        package_id,
        service_code,
        artifact_checksum(workflow_payload),
        artifact_checksum(config_payload),
    )
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    package_record = JuliaFlowDataScienceProjectDeploy.deploy_package_record(
        workflow_id,
        workflow_payload,
        model_record,
        validation_context,
        package_id,
        endpoint_config,
        service_code,
        artifact_evidence,
        timestamp,
    )
    package_record["packageChecksumSha256"] = artifact_checksum(JuliaFlowDataScienceProjectDeploy.deploy_package_checksum_payload(package_record))
    record_deploy_package_project_job!(state, validation_context, package_record, timestamp)
    package_record["packageChecksumSha256"] = artifact_checksum(JuliaFlowDataScienceProjectDeploy.deploy_package_checksum_payload(package_record))

    model_record["deploymentStatus"] = "local_ready"
    model_record["updatedAt"] = package_record["createdAt"]
    execution.metadata["model_registry_record"] = model_record
    execution.metadata["deploy_package_records"] = [package_record, deploy_package_records(execution)...]
    upsert_project_model_registry!(state, model_record)
    upsert_project_model_lifecycle!(
        state,
        validation_context,
        String(model_record["modelId"]),
        "deployed";
        deployed_endpoint_id = String(package_record["packageId"]),
        updated_at = String(package_record["createdAt"]),
    )
    save_execution!(state.repository, execution; producer = "api-gateway")
    return package_record
end

function deploy_package_response!(state::GatewayState, workflow_id::AbstractString, body::AbstractDict; auth_context = nothing)
    package_record = deploy_package_payload!(state, workflow_id, body; auth_context = auth_context)
    return JSON3.write(Dict("status" => "packaged", "package" => package_record))
end

function deploy_package_history_response(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    records = Dict{String,Any}[]
    for execution in reverse(state.executions)
        execution.workflow_id == workflow_id || continue
        append!(records, deploy_package_records(execution))
    end
    return JSON3.write(Dict("items" => records, "count" => length(records)))
end

function local_backup_payload(
    state::GatewayState;
    notes::Union{Nothing,AbstractString} = nothing,
    include_executions::Bool = true,
)
    health = JSON3.read(healthcheck(state), Dict{String,Any})
    data_root = String(health["dataEstateRoot"])
    workflows = [
        JuliaFlowGatewayRepository.workflow_detail_payload(state.workflows[workflow_id])
        for workflow_id in sort(collect(keys(state.workflows)))
    ]
    auth_policy = JuliaFlowGatewayRepository.auth_policy_payload(JuliaFlowGatewayRepository.load_auth_policy(state.repository))
    auth_directory = JuliaFlowGatewayRepository.auth_directory_payload(JuliaFlowGatewayRepository.load_auth_directory(state.repository))
    backup = Dict{String,Any}(
        "backupId" => "backup-" * replace(string(uuid4()), "-" => ""),
        "createdAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        "schemaVersion" => "juliaflow.backup.v1",
        "notes" => notes === nothing ? "" : String(notes),
        "localOnly" => true,
        "appliance" => Dict{String,Any}(
            "localProfile" => health["localProfile"],
            "localHome" => health["localHome"],
            "repositoryBackend" => health["repositoryBackend"],
            "metadataMode" => health["metadataMode"],
            "metadataBackend" => health["metadataBackend"],
            "metadataRoot" => health["metadataRoot"],
            "cloudCredentialsRequired" => health["cloudCredentialsRequired"],
        ),
        "dataEstate" => Dict{String,Any}(
            "root" => data_root,
            "zones" => health["dataEstateZones"],
            "artifactFormats" => health["dataEstateArtifactFormats"],
            "manifestChecksums" => health["dataEstateManifestChecksums"],
            "artifacts" => local_data_estate_artifact_records(data_root),
        ),
        "workflows" => workflows,
        "checkpoints" => [checkpoint_payload(checkpoint, state) for checkpoint in state.checkpoints],
        "executions" => include_executions ? [execution_payload(execution) for execution in state.executions] : Dict{String,Any}[],
        "dataScienceProjects" => [
            JuliaFlowGatewayRepository.data_science_project_payload(state.data_science_projects[project_id])
            for project_id in sort(collect(keys(state.data_science_projects)))
        ],
        "modelRegistryRecords" => JuliaFlowGatewayRepository.load_model_registry_records(state.repository),
        "publishedDashboards" => [
            JuliaFlowGatewayRepository.published_dashboard_payload(state.published_dashboards[dashboard_id])
            for dashboard_id in sort(collect(keys(state.published_dashboards)))
        ],
        "hubExtensions" => [
            JuliaFlowGatewayRepository.hub_extension_payload(state.hub_extensions[extension_id])
            for extension_id in sort(collect(keys(state.hub_extensions)))
        ],
        "authPolicy" => auth_policy,
        "authDirectory" => auth_directory,
        "authMetadataRedacted" => Dict{String,Any}(
            "sensitiveFieldsRedacted" => true,
            "policy" => redacted_value(auth_policy),
            "directory" => redacted_value(auth_directory),
        ),
        "packageEnvironment" => package_environment_metadata(),
        "runtimeConfig" => reproducibility_runtime_config(state),
    )
    backup["backupChecksumSha256"] = local_backup_checksum(backup)
    return backup
end

function local_backup_export_response!(state::GatewayState, body::AbstractDict)
    notes = haskey(body, "notes") ? String(body["notes"]) : nothing
    include_executions = haskey(body, "includeExecutions") ? Bool(body["includeExecutions"]) : true
    backup = local_backup_payload(state; notes = notes, include_executions = include_executions)
    return JSON3.write(Dict("status" => "ok", "backup" => backup))
end

function safe_backup_artifact_path(root::AbstractString, relative_path::AbstractString)
    return JuliaFlowDataScienceProjectLocalSources.confined_data_estate_path(root, relative_path)
end

function validate_backup_artifacts(backup::AbstractDict, data_root::AbstractString)
    missing = Dict{String,Any}[]
    checked = Dict{String,Any}[]
    mismatches = Dict{String,Any}[]
    data_estate = Dict{String,Any}(String(key) => value for (key, value) in pairs(backup["dataEstate"]))
    for raw_artifact in get(data_estate, "artifacts", Any[])
        artifact = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_artifact))
        relative_path = String(artifact["relativePath"])
        path = safe_backup_artifact_path(data_root, relative_path)
        expected_checksum = String(get(artifact, "checksumSha256", ""))
        if !isfile(path)
            push!(missing, artifact)
            continue
        end
        actual_checksum = local_artifact_checksum(path)
        if !isempty(expected_checksum) && actual_checksum != expected_checksum
            push!(
                mismatches,
                Dict{String,Any}(
                    "relativePath" => relative_path,
                    "expectedChecksumSha256" => expected_checksum,
                    "actualChecksumSha256" => actual_checksum,
                    "sizeBytes" => filesize(path),
                ),
            )
            continue
        end
        push!(
            checked,
            Dict{String,Any}(
                "relativePath" => relative_path,
                "checksumSha256" => actual_checksum,
                "sizeBytes" => filesize(path),
            ),
        )
    end
    return missing, checked, mismatches
end

function restore_workflows_from_backup!(state::GatewayState, backup::AbstractDict)
    restored = String[]
    for raw_workflow in get(backup, "workflows", Any[])
        workflow_payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_workflow))
        workflow_toml = workflow_toml_from_request(Dict{String,Any}("workflow" => workflow_payload))
        workflow = save_workflow!(state.repository, workflow_toml; producer = "local-backup-restore")
        state.workflows[workflow.id] = workflow
        push!(restored, workflow.id)
    end
    return restored
end

function restore_checkpoints_from_backup!(state::GatewayState, backup::AbstractDict)
    restored = String[]
    for raw_checkpoint in get(backup, "checkpoints", Any[])
        checkpoint_payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_checkpoint))
        checkpoint = GatewayCheckpoint(
            tag = String(checkpoint_payload["tag"]),
            summary = String(checkpoint_payload["summary"]),
            created_at = String(checkpoint_payload["createdAt"]),
        )
        save_checkpoint!(state.repository, checkpoint)
        index = findfirst(item -> item.tag == checkpoint.tag, state.checkpoints)
        index === nothing ? push!(state.checkpoints, checkpoint) : (state.checkpoints[index] = checkpoint)
        push!(restored, checkpoint.tag)
    end
    return restored
end

function restore_executions_from_backup!(state::GatewayState, backup::AbstractDict)
    restored = String[]
    for raw_execution in get(backup, "executions", Any[])
        execution_payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_execution))
        execution = JuliaFlowGatewayRepository.gateway_execution(execution_payload)
        save_execution!(state.repository, execution; producer = "local-backup-restore")
        index = findfirst(item -> item.execution_id == execution.execution_id, state.executions)
        index === nothing ? push!(state.executions, execution) : (state.executions[index] = execution)
        push!(restored, execution.execution_id)
    end
    sync_worker_service!(state.worker_service, state.executions)
    return restored
end

function restore_dashboards_from_backup!(state::GatewayState, backup::AbstractDict)
    restored = String[]
    for raw_dashboard in get(backup, "publishedDashboards", Any[])
        dashboard_payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_dashboard))
        dashboard = JuliaFlowGatewayRepository.gateway_published_dashboard(dashboard_payload)
        state.published_dashboards[dashboard.dashboard_id] = dashboard
        JuliaFlowGatewayRepository.save_published_dashboard!(state.repository, dashboard; producer = "local-backup-restore")
        push!(restored, dashboard.dashboard_id)
    end
    return restored
end

function restore_data_science_projects_from_backup!(state::GatewayState, backup::AbstractDict)
    restored = String[]
    for raw_project in get(backup, "dataScienceProjects", Any[])
        project_payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_project))
        project = JuliaFlowGatewayRepository.gateway_data_science_project(project_payload)
        state.data_science_projects[project.project_id] = project
        JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "local-backup-restore")
        push!(restored, project.project_id)
    end
    return restored
end

function restore_model_registry_records_from_backup!(state::GatewayState, backup::AbstractDict)
    restored = String[]
    for raw_record in get(backup, "modelRegistryRecords", Any[])
        record = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_record))
        saved = JuliaFlowGatewayRepository.save_model_registry_record!(
            state.repository,
            record;
            producer = "local-backup-restore",
        )
        push!(restored, String(saved["modelId"]))
    end
    return restored
end

function restore_hub_extensions_from_backup!(state::GatewayState, backup::AbstractDict)
    restored = String[]
    for raw_extension in get(backup, "hubExtensions", Any[])
        extension_payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_extension))
        extension = JuliaFlowGatewayRepository.gateway_hub_extension(extension_payload)
        state.hub_extensions[extension.extension_id] = extension
        JuliaFlowGatewayRepository.save_hub_extension!(state.repository, extension; producer = "local-backup-restore")
        push!(restored, extension.extension_id)
    end
    return restored
end

function restore_auth_from_backup!(state::GatewayState, backup::AbstractDict)
    if haskey(backup, "authPolicy")
        policy_payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(backup["authPolicy"]))
        policy = JuliaFlowGatewayRepository.gateway_auth_policy(policy_payload)
        JuliaFlowGatewayRepository.save_auth_policy!(state.repository, policy; producer = "local-backup-restore")
    end
    if haskey(backup, "authDirectory")
        directory_payload = Dict{String,Any}(String(key) => value for (key, value) in pairs(backup["authDirectory"]))
        directory = JuliaFlowGatewayRepository.gateway_auth_directory(directory_payload)
        JuliaFlowGatewayRepository.save_auth_directory!(state.repository, directory; producer = "local-backup-restore")
    end
    return true
end

function local_backup_restore_response!(state::GatewayState, body::AbstractDict)
    haskey(body, "backup") || error("missing backup")
    raw_backup = body["backup"]
    raw_backup isa AbstractDict || error("backup must be an object")
    backup = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_backup))
    String(get(backup, "schemaVersion", "")) == "juliaflow.backup.v1" || error("unsupported local backup schemaVersion")
    declared_checksum = String(get(backup, "backupChecksumSha256", ""))
    isempty(declared_checksum) && error("backup missing backupChecksumSha256")
    actual_checksum = local_backup_checksum(backup)
    declared_checksum == actual_checksum || error("local backup checksum mismatch")

    health = JSON3.read(healthcheck(state), Dict{String,Any})
    missing_artifacts, checked_artifacts, checksum_mismatches = validate_backup_artifacts(backup, String(health["dataEstateRoot"]))
    restored_workflows = restore_workflows_from_backup!(state, backup)
    restored_checkpoints = restore_checkpoints_from_backup!(state, backup)
    restored_executions = restore_executions_from_backup!(state, backup)
    restored_projects = restore_data_science_projects_from_backup!(state, backup)
    restored_model_registry_records = restore_model_registry_records_from_backup!(state, backup)
    restored_dashboards = restore_dashboards_from_backup!(state, backup)
    restored_hub_extensions = restore_hub_extensions_from_backup!(state, backup)
    restore_auth_from_backup!(state, backup)
    status = isempty(missing_artifacts) && isempty(checksum_mismatches) ? "restored" : "restored_with_missing_artifacts"

    return JSON3.write(Dict{String,Any}(
        "status" => status,
        "backupId" => String(backup["backupId"]),
        "backupChecksumSha256" => declared_checksum,
        "restored" => Dict{String,Any}(
            "workflows" => restored_workflows,
            "checkpoints" => restored_checkpoints,
            "executions" => restored_executions,
            "dataScienceProjects" => restored_projects,
            "modelRegistryRecords" => restored_model_registry_records,
            "publishedDashboards" => restored_dashboards,
            "hubExtensions" => restored_hub_extensions,
            "authPolicy" => haskey(backup, "authPolicy"),
            "authDirectory" => haskey(backup, "authDirectory"),
        ),
        "missingArtifacts" => missing_artifacts,
        "checkedArtifacts" => checked_artifacts,
        "checksumMismatches" => checksum_mismatches,
    ))
end

function current_contract_version()
    return "0.1.0"
end

function normalized_version_tuple(version::AbstractString)
    raw_parts = split(replace(String(version), r"[^0-9]+" => "."), '.')
    parts = Int[]
    for part in raw_parts
        isempty(part) && continue
        value = tryparse(Int, part)
        push!(parts, value === nothing ? 0 : value)
    end
    while length(parts) < 4
        push!(parts, 0)
    end
    return tuple(parts[1], parts[2], parts[3], parts[4])
end

function version_is_newer(candidate::AbstractString, installed::AbstractString)
    return normalized_version_tuple(candidate) > normalized_version_tuple(installed)
end

function signature_matches_partner_identity(signature::AbstractString, identity_suffix::AbstractString)
    isempty(identity_suffix) && return false
    marker = ":" * String(identity_suffix) * ":"
    return occursin(marker, String(signature))
end

function valid_hub_artifact_hash(value::AbstractString)
    hash = lowercase(strip(String(value)))
    startswith(hash, "sha256:") || return false
    digest = hash[8:end]
    length(digest) == 64 || return false
    return all(isxdigit, digest)
end

function valid_hub_mirror_ref(value::AbstractString)
    mirror_ref = lowercase(strip(String(value)))
    return startswith(mirror_ref, "mirror://") || startswith(mirror_ref, "private://")
end

function deterministic_hub_artifact_hash(package_ref::AbstractString, artifact::AbstractString)
    bytes = Vector{UInt8}(codeunits("juliaflow-hub-artifact\n$(String(package_ref))\n$(String(artifact))"))
    return string("sha256:", bytes2hex(sha256(bytes)))
end

function sha256_file_hash(path::AbstractString)
    return string("sha256:", bytes2hex(sha256(read(path))))
end

function hub_sandbox_command_allowed(command::AbstractString)
    command_text = strip(String(command))
    isempty(command_text) && return false
    for marker in (';', '&', '|', '`', '$', '<', '>')
        occursin(string(marker), command_text) && return false
    end
    return startswith(command_text, "julia --project=. extensions/") &&
        endswith(command_text, "/test/runtests.jl")
end

function hub_sandbox_script_path(command::AbstractString)
    hub_sandbox_command_allowed(command) || return nothing
    parts = split(strip(String(command)))
    length(parts) == 3 || return nothing
    script_path = String(parts[3])
    ".." in split(script_path, '/') && return nothing
    return normpath(script_path)
end

function execute_hub_sandbox_command(command::AbstractString)
    script_path = hub_sandbox_script_path(command)
    script_path === nothing && return false, "Compatibility sandbox command must be bounded Julia extension test"
    isfile(script_path) || return false, "Compatibility sandbox script not found: $(script_path)"

    if get(ENV, "JULIAFLOW_HUB_SANDBOX_EXECUTE", "0") != "1"
        return true, "Bounded compatibility sandbox command accepted"
    end

    command_result = Cmd(vcat(Base.julia_cmd().exec, ["--project=.", script_path]))
    passed = try
        success(pipeline(command_result, stdout = devnull, stderr = devnull))
    catch
        false
    end
    return passed, passed ? "Isolated compatibility sandbox command executed successfully" :
                   "Compatibility sandbox command failed in isolated runner"
end

function hub_json_registry(path::AbstractString)
    registry_path = strip(String(path))
    isempty(registry_path) && return nothing
    isfile(registry_path) || return Dict{String,Any}()
    try
        return JSON3.read(read(registry_path, String), Dict{String,Any})
    catch
        return Dict{String,Any}()
    end
end

function hub_registry_path(registry_path::AbstractString, raw_path)
    candidate = String(raw_path)
    isabspath(candidate) && return candidate
    return joinpath(dirname(String(registry_path)), candidate)
end

function hub_artifact_hash(package_ref::AbstractString, artifact::AbstractString)
    store_path = strip(get(ENV, "JULIAFLOW_HUB_ARTIFACT_STORE", ""))
    store = hub_json_registry(store_path)
    store === nothing && return deterministic_hub_artifact_hash(package_ref, artifact), "deterministic"

    package_entry = get(store, String(package_ref), nothing)
    package_entry isa AbstractDict || return nothing, "missing"
    raw_path = get(package_entry, String(artifact), nothing)
    raw_path isa AbstractString || return nothing, "missing"
    artifact_path = hub_registry_path(store_path, raw_path)
    isfile(artifact_path) || return nothing, "missing"
    return sha256_file_hash(artifact_path), "downloaded"
end

function hub_mirror_resolved(mirror_ref::AbstractString)
    valid_hub_mirror_ref(mirror_ref) || return false, "invalid"
    registry_path = strip(get(ENV, "JULIAFLOW_HUB_MIRROR_REGISTRY", ""))
    registry = hub_json_registry(registry_path)
    registry === nothing && return true, "scheme"

    raw_value = get(registry, String(mirror_ref), nothing)
    raw_value === nothing && return false, "missing"
    raw_value isa Bool && return Bool(raw_value), "registry"
    raw_value isa AbstractString || return false, "missing"
    raw_path = hub_registry_path(registry_path, raw_value)
    return isfile(raw_path) || isdir(raw_path), "registry"
end

function evaluate_hub_install_verification(extension::JuliaFlowGatewayRepository.HubExtensionRecord)
    blockers = String[]
    sandbox_blockers = String[]
    artifact_blockers = String[]
    mirror_blockers = String[]
    sandbox_details = "Compatibility sandbox verification failed"
    artifact_modes = Set{String}()
    mirror_modes = Set{String}()
    sandbox_command = extension.compatibility_sandbox_command === nothing ? "" : strip(extension.compatibility_sandbox_command)

    sandbox_passed, sandbox_details = execute_hub_sandbox_command(sandbox_command)
    sandbox_passed || push!(sandbox_blockers, sandbox_details)

    for (artifact, declared_hash) in extension.artifact_hashes
        expected_hash, artifact_mode = hub_artifact_hash(extension.package_ref, artifact)
        push!(artifact_modes, artifact_mode)
        expected_hash === nothing && push!(artifact_blockers, "Artifact $(artifact) missing from artifact store")
        expected_hash === nothing && continue
        declared_hash == expected_hash ||
            push!(artifact_blockers, "Artifact hash mismatch for $(artifact)")
    end
    isempty(extension.artifact_hashes) && push!(artifact_blockers, "Extension must provide at least one artifact hash")

    for mirror_ref in extension.mirror_refs
        resolved, mirror_mode = hub_mirror_resolved(mirror_ref)
        push!(mirror_modes, mirror_mode)
        resolved || push!(
            mirror_blockers,
            mirror_mode == "invalid" ? "Mirror reference must use mirror:// or private:// scheme" :
            "Mirror reference not found in offline/private registry: $(mirror_ref)",
        )
    end
    isempty(extension.mirror_refs) && push!(mirror_blockers, "Extension must provide at least one mirror reference")
    artifact_details = "Declared artifact hashes match deterministic package proof"
    ("downloaded" in artifact_modes) && (artifact_details = "Downloaded artifact hashes verified from isolated artifact store")
    mirror_details = "Mirror references are supported for offline/private resolution"
    ("registry" in mirror_modes) && (mirror_details = "Offline/private mirror references resolved through local registry")

    append!(blockers, sandbox_blockers)
    append!(blockers, artifact_blockers)
    append!(blockers, mirror_blockers)

    return Dict{String,Any}(
        "verified" => isempty(blockers),
        "sandbox" => JuliaFlowGatewayRepository.hub_verification_check(
            isempty(sandbox_blockers) ? "passed" : "failed",
            isempty(sandbox_blockers) ? sandbox_details : "Compatibility sandbox verification failed";
            blockers = sandbox_blockers,
        ),
        "artifacts" => JuliaFlowGatewayRepository.hub_verification_check(
            isempty(artifact_blockers) ? "passed" : "failed",
            isempty(artifact_blockers) ? artifact_details : "Artifact hash verification failed";
            blockers = artifact_blockers,
        ),
        "mirrors" => JuliaFlowGatewayRepository.hub_verification_check(
            isempty(mirror_blockers) ? "passed" : "failed",
            isempty(mirror_blockers) ? mirror_details : "Mirror verification failed";
            blockers = mirror_blockers,
        ),
        "blockers" => blockers,
        "evaluatedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
    )
end

function hub_artifact_hashes_from_manifest(manifest::AbstractDict{String,Any})
    haskey(manifest, "artifactHashes") || error("manifest missing artifactHashes")
    raw_hashes = manifest["artifactHashes"]
    raw_hashes isa AbstractString && error("manifest artifactHashes must be object")
    raw_hashes isa AbstractVector && error("manifest artifactHashes must be object")

    hashes = Dict{String,String}()
    for (artifact, hash) in pairs(raw_hashes)
        hash isa AbstractString || error("manifest artifactHashes values must be strings")
        hashes[String(artifact)] = String(hash)
    end
    return hashes
end

function hub_mirror_refs_from_manifest(manifest::AbstractDict{String,Any})
    haskey(manifest, "mirrorRefs") || error("manifest missing mirrorRefs")
    raw_mirror_refs = manifest["mirrorRefs"]
    raw_mirror_refs isa AbstractString && error("manifest mirrorRefs must be an array")
    raw_mirror_refs isa AbstractVector || error("manifest mirrorRefs must be an array")
    return [String(entry) for entry in raw_mirror_refs]
end

function evaluate_hub_extension_trust(extension::JuliaFlowGatewayRepository.HubExtensionRecord)
    warnings = String[]
    blockers = String[]
    trusted = false
    level = "untrusted"
    signature = extension.signature === nothing ? "" : strip(extension.signature)
    release_notes_ref = extension.release_notes_ref === nothing ? "" : strip(extension.release_notes_ref)

    if isempty(extension.artifact_hashes)
        push!(blockers, "Extension must provide at least one artifact hash")
    else
        for (artifact, hash) in extension.artifact_hashes
            valid_hub_artifact_hash(hash) || push!(blockers, "Artifact hash for $(artifact) must use sha256:<64 hex digest>")
        end
    end

    if extension.publisher == "official"
        if extension.publisher_identity != "official:juliaflow"
            push!(blockers, "Official extension publisher identity must be registered with gateway")
        end
    elseif extension.publisher == "partner"
        identity_suffix = length(extension.publisher_identity) > 8 ? strip(extension.publisher_identity[9:end]) : ""
        if !startswith(extension.publisher_identity, "partner:")
            push!(blockers, "Partner extension must use partner-scoped publisher identity")
        elseif isempty(identity_suffix)
            push!(blockers, "Partner extension publisher identity suffix must not be empty")
        end
        if !startswith(extension.package_ref, "hub://")
            push!(blockers, "Partner extension package reference must use hub:// scheme")
        end
        if isempty(signature)
            push!(blockers, "Partner extension must provide signature")
        elseif !startswith(signature, "sig:")
            push!(blockers, "Partner extension signature must use sig: prefix")
        elseif !signature_matches_partner_identity(signature, identity_suffix)
            push!(blockers, "Partner extension signature must include publisher identity suffix")
        end
        if isempty(release_notes_ref)
            push!(blockers, "Partner extension must provide release notes reference")
        elseif !startswith(lowercase(release_notes_ref), "https://")
            push!(blockers, "Partner extension release notes reference must be https URL")
        end
    else
        push!(blockers, "Unsupported publisher type $(extension.publisher)")
    end

    if isempty(blockers)
        trusted = true
        level = extension.publisher == "official" ? "official" : "partner_verified"
    end

    return Dict(
        "trusted" => trusted,
        "level" => level,
        "warnings" => warnings,
        "blockers" => blockers,
        "evaluatedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
    )
end

function build_hub_upgrade_info(latest_version::AbstractString, installed_version)
    upgrade_available = installed_version !== nothing && version_is_newer(latest_version, String(installed_version))
    payload = Dict{String,Any}(
        "upgradeAvailable" => upgrade_available,
        "latestVersion" => String(latest_version),
        "evaluatedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
    )
    installed_version === nothing || (payload["installedVersion"] = String(installed_version))
    upgrade_available && (payload["targetVersion"] = String(latest_version))
    return payload
end

function evaluate_hub_extension_compatibility(state::GatewayState, extension::JuliaFlowGatewayRepository.HubExtensionRecord)
    blockers = String[]
    warnings = String[]
    current_checkpoint = latest_checkpoint_tag(state)

    supported_checkpoints = isempty(extension.supported_checkpoints) ? extension.compatible_checkpoints : extension.supported_checkpoints
    current_checkpoint in supported_checkpoints || push!(blockers, "Extension not validated for current checkpoint $(current_checkpoint)")
    extension.required_contract_version == current_contract_version() ||
        push!(blockers, "Requires contract version $(extension.required_contract_version), gateway provides $(current_contract_version())")
    startswith(lowercase(extension.engine_compatibility), "alpha") || push!(warnings, "Engine compatibility range $(extension.engine_compatibility) not yet enforced beyond Alpha")
    sandbox_command = extension.compatibility_sandbox_command === nothing ? "" : strip(extension.compatibility_sandbox_command)
    isempty(sandbox_command) && push!(blockers, "Extension must provide compatibility sandbox command")
    for mirror_ref in extension.mirror_refs
        valid_hub_mirror_ref(mirror_ref) ||
            push!(blockers, "Mirror reference must use mirror:// or private:// scheme")
    end

    return Dict(
        "compatible" => isempty(blockers),
        "warnings" => warnings,
        "blockers" => blockers,
        "evaluatedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
    )
end

function materialize_hub_extension(
    current::JuliaFlowGatewayRepository.HubExtensionRecord;
    install_state::AbstractString = current.install_state,
    installed_at = current.installed_at,
    enabled_at = current.enabled_at,
    compatibility = current.compatibility,
    trust = current.trust,
    upgrade = current.upgrade,
    verification = current.verification,
    installed_version = current.installed_version,
)
    return JuliaFlowGatewayRepository.HubExtensionRecord(
        extension_id = current.extension_id,
        name = current.name,
        version = current.version,
        publisher = current.publisher,
        summary = current.summary,
        package_ref = current.package_ref,
        tags = current.tags,
        engine_compatibility = current.engine_compatibility,
        required_contract_version = current.required_contract_version,
        supported_checkpoints = current.supported_checkpoints,
        compatible_checkpoints = current.compatible_checkpoints,
        dependencies = current.dependencies,
        publisher_identity = current.publisher_identity,
        artifact_hashes = current.artifact_hashes,
        compatibility_sandbox_command = current.compatibility_sandbox_command,
        mirror_refs = current.mirror_refs,
        signature = current.signature,
        release_notes_ref = current.release_notes_ref,
        install_state = String(install_state),
        compatibility = compatibility,
        trust = trust,
        upgrade = upgrade,
        verification = verification,
        installed_version = installed_version,
        installed_at = installed_at,
        enabled_at = enabled_at,
    )
end

function list_hub_extensions_response(state::GatewayState)
    extensions = sort(collect(values(state.hub_extensions)); by = item -> item.extension_id)
    return JSON3.write(Dict("items" => [JuliaFlowGatewayRepository.hub_extension_payload(item) for item in extensions]))
end

function list_published_dashboards_response(state::GatewayState, workflow_id::AbstractString)
    dashboards = sort(
        [item for item in values(state.published_dashboards) if item.workflow_id == workflow_id];
        by = item -> item.dashboard_id,
    )
    return JSON3.write(Dict("items" => [JuliaFlowGatewayRepository.published_dashboard_payload(item) for item in dashboards]))
end

function register_hub_extension_response!(state::GatewayState, request_body::AbstractDict{<:Any,<:Any})
    haskey(request_body, "manifest") || error("missing manifest")
    manifest = normalized_string_dict(request_body["manifest"])
    required_fields = ("extensionId", "name", "version", "publisher", "summary", "packageRef", "artifactHashes", "mirrorRefs")
    for field in required_fields
        haskey(manifest, field) || error("manifest missing $(field)")
    end

    candidate = JuliaFlowGatewayRepository.HubExtensionRecord(
        extension_id = String(manifest["extensionId"]),
        name = String(manifest["name"]),
        version = String(manifest["version"]),
        publisher = String(manifest["publisher"]),
        summary = String(manifest["summary"]),
        package_ref = String(manifest["packageRef"]),
        tags = [String(entry) for entry in get(manifest, "tags", Any[])],
        engine_compatibility = String(get(manifest, "engineCompatibility", "alpha-core")),
        required_contract_version = String(get(manifest, "requiredContractVersion", current_contract_version())),
        supported_checkpoints = [String(entry) for entry in get(manifest, "supportedCheckpoints", Any[])],
        compatible_checkpoints = [String(entry) for entry in get(manifest, "compatibleCheckpoints", get(manifest, "supportedCheckpoints", Any[]))],
        dependencies = [String(entry) for entry in get(manifest, "dependencies", Any[])],
        publisher_identity = String(get(manifest, "publisherIdentity", String(manifest["publisher"]))),
        artifact_hashes = hub_artifact_hashes_from_manifest(manifest),
        compatibility_sandbox_command = haskey(manifest, "compatibilitySandboxCommand") ? String(manifest["compatibilitySandboxCommand"]) : nothing,
        mirror_refs = hub_mirror_refs_from_manifest(manifest),
        signature = haskey(manifest, "signature") ? String(manifest["signature"]) : nothing,
        release_notes_ref = haskey(manifest, "releaseNotesRef") ? String(manifest["releaseNotesRef"]) : nothing,
    )
    existing = get(state.hub_extensions, candidate.extension_id, nothing)
    compatibility = evaluate_hub_extension_compatibility(state, candidate)
    trust = evaluate_hub_extension_trust(candidate)
    installed_version = if existing === nothing
        nothing
    elseif existing.installed_version !== nothing
        existing.installed_version
    elseif existing.install_state in ("installed", "enabled", "disabled", "upgrade_available")
        existing.version
    else
        nothing
    end
    upgrade = build_hub_upgrade_info(candidate.version, installed_version)
    install_state = if !Bool(compatibility["compatible"])
        "incompatible"
    elseif Bool(get(upgrade, "upgradeAvailable", false))
        "upgrade_available"
    elseif existing !== nothing && existing.install_state in ("enabled", "disabled", "installed")
        existing.install_state
    else
        "available"
    end
    updated = materialize_hub_extension(
        candidate;
        install_state = install_state,
        compatibility = compatibility,
        trust = trust,
        upgrade = upgrade,
        installed_version = installed_version,
        installed_at = existing === nothing ? nothing : existing.installed_at,
        enabled_at = existing === nothing ? nothing : existing.enabled_at,
    )
    state.hub_extensions[updated.extension_id] = updated
    JuliaFlowGatewayRepository.save_hub_extension!(state.repository, updated; producer = "api-gateway")
    return JSON3.write(Dict("status" => "ok", "extension" => JuliaFlowGatewayRepository.hub_extension_payload(updated)))
end

function dashboard_chart_payload(chart)
    payload = Dict{String,Any}(
        "chartId" => String(get(chart, "id", get(chart, "chartId", ""))),
        "title" => String(chart["title"]),
        "family" => String(chart["family"]),
    )
    haskey(chart, "x_field") && chart["x_field"] !== nothing && (payload["xField"] = String(chart["x_field"]))
    haskey(chart, "xField") && chart["xField"] !== nothing && (payload["xField"] = String(chart["xField"]))
    haskey(chart, "y_field") && chart["y_field"] !== nothing && (payload["yField"] = String(chart["y_field"]))
    haskey(chart, "yField") && chart["yField"] !== nothing && (payload["yField"] = String(chart["yField"]))
    haskey(chart, "series_field") && chart["series_field"] !== nothing && (payload["seriesField"] = String(chart["series_field"]))
    haskey(chart, "seriesField") && chart["seriesField"] !== nothing && (payload["seriesField"] = String(chart["seriesField"]))
    if haskey(chart, "panel") && chart["panel"] !== nothing
        panel = chart["panel"]
        payload["panel"] = Dict(
            "x" => Int(panel["x"]),
            "y" => Int(panel["y"]),
            "w" => Int(panel["w"]),
            "h" => Int(panel["h"]),
        )
    end
    return payload
end

function dashboard_row_dict(row)
    row isa AbstractDict || error("dashboard dataset rows must be objects")
    return Dict{String,Any}(String(key) => value for (key, value) in pairs(row))
end

function dashboard_dataset_rows(raw_rows)
    raw_rows isa AbstractVector || error("dashboard dataset rows must be a vector")
    return [dashboard_row_dict(row) for row in raw_rows]
end

function bi_outlet_value(outlet::AbstractDict, keys...; default = nothing)
    for key in keys
        haskey(outlet, key) && return outlet[key]
    end
    return default
end

function published_dashboard_datasets(workflow, draft)
    datasets = Dict{String,Vector{Dict{String,Any}}}()
    dataset_key = draft.binding.dataset_key
    outlet_node_id = draft.binding.outlet_node_id
    for raw_outlet in workflow.bi_outlets
        outlet = Dict{String,Any}(String(key) => value for (key, value) in pairs(raw_outlet))
        node_id = String(bi_outlet_value(outlet, "node_id", "nodeId"; default = ""))
        isempty(node_id) || node_id == outlet_node_id || continue
        if haskey(outlet, "datasets")
            for (key, rows) in pairs(outlet["datasets"])
                datasets[String(key)] = dashboard_dataset_rows(rows)
            end
        end
        if haskey(outlet, "rows")
            datasets[dataset_key] = dashboard_dataset_rows(outlet["rows"])
        end
    end
    return datasets
end

function publish_dashboard_response!(
    state::GatewayState,
    workflow_id::AbstractString,
    dashboard_id::AbstractString;
    visibility::AbstractString = "workspace",
)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    workflow = state.workflows[workflow_id]
    dashboard = findfirst(item -> item.id == dashboard_id, workflow.dashboards)
    dashboard === nothing && error("dashboard not found: $(dashboard_id)")
    visibility in ("workspace", "public") || error("unsupported dashboard visibility: $(visibility)")
    draft = workflow.dashboards[dashboard]
    published_version = haskey(state.published_dashboards, dashboard_id) ? state.published_dashboards[dashboard_id].version + 1 : 1

    published = JuliaFlowGatewayRepository.PublishedDashboardRecord(
        dashboard_id = draft.id,
        workflow_id = workflow.id,
        name = draft.name,
        version = published_version,
        published_at = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        visibility = String(visibility),
        share_token = visibility == "public" ? replace(string(uuid4()), "-" => "")[1:12] : nothing,
        binding = Dict(
            "outletNodeId" => draft.binding.outlet_node_id,
            "datasetKey" => draft.binding.dataset_key,
            "refreshMode" => draft.binding.refresh_mode,
        ),
        charts = [dashboard_chart_payload(Dict(
            "id" => chart.id,
            "title" => chart.title,
            "family" => chart.family,
            "x_field" => chart.x_field,
            "y_field" => chart.y_field,
            "series_field" => chart.series_field,
            "panel" => chart.panel === nothing ? nothing : Dict("x" => chart.panel.x, "y" => chart.panel.y, "w" => chart.panel.w, "h" => chart.panel.h),
        )) for chart in draft.charts],
        datasets = published_dashboard_datasets(workflow, draft),
    )
    state.published_dashboards[published.dashboard_id] = published
    JuliaFlowGatewayRepository.save_published_dashboard!(state.repository, published; producer = "api-gateway")
    return JSON3.write(Dict("status" => "ok", "dashboard" => JuliaFlowGatewayRepository.published_dashboard_payload(published)))
end

function authorized_published_dashboard(
    state::GatewayState,
    dashboard_id::AbstractString;
    share_token::Union{Nothing,AbstractString} = nothing,
    workspace_token::Union{Nothing,AbstractString} = nothing,
    workspace_bearer_token::Union{Nothing,AbstractString} = nothing,
)
    haskey(state.published_dashboards, dashboard_id) || error("published dashboard not found: $(dashboard_id)")
    dashboard = state.published_dashboards[dashboard_id]
    if dashboard.visibility == "workspace"
        expected_workspace_token = workspace_dashboard_access_token()
        expected_workspace_token === nothing && error("workspace dashboard access token is not configured")
        provided_workspace_token = workspace_token === nothing ? "" : strip(String(workspace_token))
        provided_workspace_bearer_token = workspace_bearer_token === nothing ? "" : strip(String(workspace_bearer_token))
        has_token_access = provided_workspace_token == expected_workspace_token
        has_bearer_access = provided_workspace_bearer_token == expected_workspace_token
        (has_token_access || has_bearer_access) || error("invalid workspace access token")
        return dashboard
    end
    expected_share_token = dashboard.share_token === nothing ? "" : strip(String(dashboard.share_token))
    provided_share_token = share_token === nothing ? "" : strip(String(share_token))
    isempty(expected_share_token) && error("published dashboard missing share token")
    provided_share_token == expected_share_token || error("invalid share token")
    return dashboard
end

function get_published_dashboard_response(
    state::GatewayState,
    dashboard_id::AbstractString;
    share_token::Union{Nothing,AbstractString} = nothing,
    workspace_token::Union{Nothing,AbstractString} = nothing,
    workspace_bearer_token::Union{Nothing,AbstractString} = nothing,
)
    dashboard = authorized_published_dashboard(
        state,
        dashboard_id;
        share_token = share_token,
        workspace_token = workspace_token,
        workspace_bearer_token = workspace_bearer_token,
    )
    return JSON3.write(JuliaFlowGatewayRepository.published_dashboard_payload(dashboard))
end

function published_dashboard_chart_data(
    state::GatewayState,
    dashboard_id::AbstractString,
    chart_id::AbstractString;
    share_token::Union{Nothing,AbstractString} = nothing,
    workspace_token::Union{Nothing,AbstractString} = nothing,
    workspace_bearer_token::Union{Nothing,AbstractString} = nothing,
)
    dashboard = authorized_published_dashboard(
        state,
        dashboard_id;
        share_token = share_token,
        workspace_token = workspace_token,
        workspace_bearer_token = workspace_bearer_token,
    )
    return JuliaFlowGatewayPresentation.dashboard_chart_data_payload(dashboard, chart_id)
end

function published_dashboard_chart_data_response(state::GatewayState, dashboard_id::AbstractString, chart_id::AbstractString; kwargs...)
    return JSON3.write(published_dashboard_chart_data(state, dashboard_id, chart_id; kwargs...))
end

function published_dashboard_chart_data_csv_response(state::GatewayState, dashboard_id::AbstractString, chart_id::AbstractString; kwargs...)
    payload = published_dashboard_chart_data(state, dashboard_id, chart_id; kwargs...)
    return JuliaFlowGatewayPresentation.chart_data_csv(payload["rows"], payload["fields"])
end

function install_hub_extension_response!(
    state::GatewayState,
    extension_id::AbstractString;
    action::AbstractString = "install",
)
    haskey(state.hub_extensions, extension_id) || error("hub extension not found: $(extension_id)")
    current = state.hub_extensions[extension_id]
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    action in ("install", "enable", "disable", "upgrade") || error("unsupported Hub action: $(action)")
    compatibility = evaluate_hub_extension_compatibility(state, current)
    trust = evaluate_hub_extension_trust(current)
    verification = action == "disable" ? current.verification : evaluate_hub_install_verification(current)
    if action in ("install", "enable", "upgrade") && (!Bool(compatibility["compatible"]) || !Bool(trust["trusted"]))
        blocked = materialize_hub_extension(
            current;
            install_state = "incompatible",
            compatibility = compatibility,
            trust = trust,
            upgrade = build_hub_upgrade_info(current.version, current.installed_version),
            verification = verification,
        )
        state.hub_extensions[extension_id] = blocked
        JuliaFlowGatewayRepository.save_hub_extension!(state.repository, blocked; producer = "api-gateway")
        error(join(vcat([String(entry) for entry in compatibility["blockers"]], [String(entry) for entry in trust["blockers"]]), "; "))
    end
    if action in ("install", "enable", "upgrade") && !Bool(get(verification, "verified", false))
        blocked = materialize_hub_extension(
            current;
            install_state = "incompatible",
            compatibility = compatibility,
            trust = trust,
            upgrade = build_hub_upgrade_info(current.version, current.installed_version),
            verification = verification,
        )
        state.hub_extensions[extension_id] = blocked
        JuliaFlowGatewayRepository.save_hub_extension!(state.repository, blocked; producer = "api-gateway")
        error(join([String(entry) for entry in get(verification, "blockers", String[])], "; "))
    end

    installed_version = current.installed_version
    next_install_state =
        action == "disable" ? "disabled" :
        action == "enable" ? "enabled" :
        action == "upgrade" ? (current.enabled_at === nothing ? "installed" : "enabled") :
        current.install_state in ("enabled", "disabled") ? current.install_state : "installed"

    if action == "install" && installed_version === nothing
        installed_version = current.version
    elseif action == "enable" && installed_version === nothing
        installed_version = current.version
    elseif action == "upgrade"
        installed_version = current.version
    end

    upgrade = build_hub_upgrade_info(current.version, installed_version)

    updated = materialize_hub_extension(
        current;
        install_state = Bool(get(upgrade, "upgradeAvailable", false)) && action != "upgrade" ? "upgrade_available" : next_install_state,
        installed_at = action == "install" && current.installed_at === nothing ? timestamp : current.installed_at,
        enabled_at = action == "enable" ? timestamp : (action == "disable" ? nothing : current.enabled_at),
        compatibility = compatibility,
        trust = trust,
        upgrade = upgrade,
        verification = verification,
        installed_version = installed_version,
    )
    state.hub_extensions[extension_id] = updated
    JuliaFlowGatewayRepository.save_hub_extension!(state.repository, updated; producer = "api-gateway")
    return JSON3.write(Dict("status" => "ok", "extension" => JuliaFlowGatewayRepository.hub_extension_payload(updated)))
end

function import_workflow_response!(state::GatewayState; source_path::AbstractString)
    workflow = persist_workflow_file!(state, source_path)
    event_backbone_enabled() || broadcast_workflow_save!(state, workflow.id)
    return JSON3.write(
        Dict(
            "workflowId" => workflow.id,
            "name" => workflow.name,
            "persistedPath" => string(source_path),
        ),
    )
end

function create_workflow_response!(state::GatewayState; workflow_toml::AbstractString)
    payload = String(workflow_toml)
    workflow = persist_workflow_text!(state, payload)
    event_backbone_enabled() || broadcast_workflow_save!(state, workflow.id)
    return JSON3.write(
        Dict(
            "workflowId" => workflow.id,
            "name" => workflow.name,
            "version" => workflow.version,
            "status" => "created",
        ),
    )
end

function create_workflow_response_from_body!(state::GatewayState, request_body::AbstractDict{<:Any,<:Any})
    return create_workflow_response!(state; workflow_toml = workflow_toml_from_request(request_body))
end

function update_workflow_response!(
    state::GatewayState,
    workflow_id::AbstractString;
    workflow_toml::AbstractString,
)
    payload = String(workflow_toml)
    updated = JuliaFlowGatewayRepository.JuliaFlowExecutionService.load_workflow_definition_text(payload)
    updated.id == workflow_id || error("workflow id mismatch: expected $(workflow_id), got $(updated.id)")
    workflow = persist_workflow_text!(state, payload)
    event_backbone_enabled() || broadcast_workflow_save!(state, workflow.id)
    return JSON3.write(
        Dict(
            "workflowId" => workflow.id,
            "name" => workflow.name,
            "version" => workflow.version,
            "status" => "updated",
        ),
    )
end

function update_workflow_response_from_body!(state::GatewayState, workflow_id::AbstractString, request_body::AbstractDict{<:Any,<:Any})
    return update_workflow_response!(state, workflow_id; workflow_toml = workflow_toml_from_request(request_body))
end

function validate_project_local_ref!(value::AbstractString, label::AbstractString)
    return JuliaFlowDataScienceProjectCore.validate_project_local_ref!(value, label)
end

function validate_project_dataset_records!(records::Vector{Dict{String,Any}})
    return JuliaFlowDataScienceProjectCore.validate_project_dataset_records!(records)
end

function validate_project_name(body::AbstractDict)
    return JuliaFlowDataScienceProjectCore.validate_project_name(body)
end

function validate_project_schema_version(body::AbstractDict, existing::Union{Nothing,DataScienceProjectRecord})
    return JuliaFlowDataScienceProjectCore.validate_project_schema_version(body, existing)
end

function project_id_from_body(body::AbstractDict, name::AbstractString)
    return JuliaFlowDataScienceProjectCore.project_id_from_body(body, name)
end

function validate_project_id_matches!(body::AbstractDict, project_id::AbstractString)
    return JuliaFlowDataScienceProjectCore.validate_project_id_matches!(body, project_id)
end

function data_science_project_job_resource_evidence(state::GatewayState; execution_mode::AbstractString = "local_project_route")
    compute_settings = load_compute_settings(state)
    gpu_registry = JuliaFlowWorkerService.gpu_registry_health()
    return JuliaFlowDataScienceProjectJobs.project_job_resource_evidence(
        compute_settings,
        gpu_registry;
        execution_mode = execution_mode,
        cpu_thread_count = Threads.nthreads(),
    )
end

function ensure_cpu_project_job_allowed(state::GatewayState)
    JuliaFlowDataScienceProjectJobs.require_cpu_project_job_allowed(load_compute_settings(state))
    return nothing
end

function materialize_data_science_project(
    body::AbstractDict;
    existing::Union{Nothing,DataScienceProjectRecord} = nothing,
    project_id_override::Union{Nothing,AbstractString} = nothing,
)
    return JuliaFlowDataScienceProjectCore.materialize_project_record(
        body;
        existing = existing,
        project_id_override = project_id_override,
    )
end

function list_data_science_projects_response(state::GatewayState; auth_context = nothing)
    items = Dict{String,Any}[]
    for project in values(state.data_science_projects)
        if auth_context !== nothing
            try
                enforce_resource_policy!(state, auth_context, "workflow:read", "data_science_project", project.project_id)
            catch err
                err isa ErrorException && err.msg == "permission denied: workflow:read" || rethrow()
                continue
            end
        end
        push!(items, JuliaFlowGatewayRepository.data_science_project_payload(project))
    end
    sort!(items; by = item -> String(item["projectId"]))
    return JSON3.write(Dict("items" => items))
end

function create_data_science_project_response!(state::GatewayState, body::AbstractDict)
    name = validate_project_name(body)
    project_id = project_id_from_body(body, name)
    haskey(state.data_science_projects, project_id) && error("data science project already exists: $(project_id)")
    project = materialize_data_science_project(body; project_id_override = project_id)
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    return JSON3.write(JuliaFlowGatewayRepository.data_science_project_payload(state.data_science_projects[project.project_id]))
end

function get_data_science_project_response(state::GatewayState, project_id::AbstractString)
    haskey(state.data_science_projects, project_id) || error("data science project not found: $(project_id)")
    return JSON3.write(JuliaFlowGatewayRepository.data_science_project_payload(state.data_science_projects[project_id]))
end

function update_data_science_project_response!(state::GatewayState, project_id::AbstractString, body::AbstractDict)
    haskey(state.data_science_projects, project_id) || error("data science project not found: $(project_id)")
    project = materialize_data_science_project(body; existing = state.data_science_projects[project_id], project_id_override = project_id)
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    return JSON3.write(JuliaFlowGatewayRepository.data_science_project_payload(state.data_science_projects[project.project_id]))
end

function data_science_project_job_record(
    project::DataScienceProjectRecord,
    job_type::AbstractString;
    kwargs...
)
    return JuliaFlowDataScienceProjectJobs.project_job_record(project, job_type; kwargs...)
end

function record_data_science_project_job!(
    project::DataScienceProjectRecord,
    job_type::AbstractString;
    kwargs...
)
    return JuliaFlowDataScienceProjectJobs.record_project_job!(project, job_type; kwargs...)
end

function data_science_project_execution_evidence!(
    state::GatewayState,
    project::DataScienceProjectRecord,
    job_type::AbstractString;
    workflow_id::Union{Nothing,AbstractString} = nothing,
    dataset_id::Union{Nothing,AbstractString} = nothing,
    source_record_id::Union{Nothing,AbstractString} = nothing,
    output_refs::AbstractVector = Any[],
    resource_evidence::Union{Nothing,AbstractDict} = nothing,
    started_at::Union{Nothing,AbstractString} = nothing,
    finished_at::Union{Nothing,AbstractString} = nothing,
    plan::AbstractVector = String[],
    worker_backed::Bool = false,
)
    workflow_ids = sort(String.(collect(keys(state.workflows))))
    selected_workflow_id = workflow_id === nothing ? (isempty(workflow_ids) ? project.project_id : first(workflow_ids)) : String(workflow_id)
    execution, worker_id = JuliaFlowDataScienceProjectJobs.project_job_execution_record(
        project,
        job_type;
        workflow_id = selected_workflow_id,
        checkpoint_tag = latest_checkpoint_tag(state),
        dataset_id = dataset_id,
        source_record_id = source_record_id,
        output_refs = output_refs,
        resource_evidence = resource_evidence,
        started_at = started_at,
        finished_at = finished_at,
        plan = plan,
        worker_backed = worker_backed,
    )
    save_execution!(state.repository, execution; producer = "api-gateway")
    push!(state.executions, execution)
    if worker_backed
        for _ in 1:4
            execution.status == "completed" && break
            updated = JuliaFlowWorkerService.process_data_science_project_job_tick!(
                state.worker_service,
                state.executions;
                execution_record = execution_record,
                transition_execution_record = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
                materialize_execution = materialize_execution,
            )
            isempty(updated) && error("data science project worker did not process execution: $(execution.execution_id)")
            execution_index = findfirst(item -> item.execution_id == execution.execution_id, state.executions)
            execution_index === nothing && error("data science project worker execution missing: $(execution.execution_id)")
            execution = state.executions[execution_index]
            save_execution!(state.repository, execution; producer = "api-gateway")
        end
        execution.status == "completed" || error("data science project worker did not complete execution: $(execution.execution_id)")
    end
    return JuliaFlowDataScienceProjectJobs.project_job_execution_evidence(execution, worker_id)
end

function transform_apply_splits(body::AbstractDict, split_plan::AbstractDict)
    return JuliaFlowDataScienceProjectTransforms.transform_apply_splits(body, split_plan)
end

function run_transform_fit_apply_response!(state::GatewayState, project_id::AbstractString, body::AbstractDict)
    haskey(state.data_science_projects, project_id) || error("data science project not found: $(project_id)")
    ensure_cpu_project_job_allowed(state)
    project = deepcopy(state.data_science_projects[project_id])
    dataset_id = statistical_analysis_dataset(project, body)
    split_plan = project_split_plan_for_request(project, body, dataset_id, "transform fit/apply")
    Bool(get(split_plan, "locked", false)) || error("transform fit/apply locked split required")
    fit_split = String(get(body, "fitSplit", "train"))
    fit_split == "train" || error("transform fit/apply fitSplit must be train")
    apply_splits = transform_apply_splits(body, split_plan)
    transform_ref = JuliaFlowDataScienceProjectTransforms.transform_ref_for_request(body, project.project_id)
    dataset = data_science_project_dataset(project, dataset_id)
    target_columns = [String(get(column, "name", "")) for schema in project.schema_contracts
        if get(schema, "datasetId", "") == dataset_id for column in get(schema, "columns", Any[]) if get(column, "role", "") == "target"]
    target = length(target_columns) == 1 ? only(target_columns) : ""
    membership = JuliaFlowDataScienceProjectEvidence.read_result(() -> project_execution_membership!(project, dataset, split_plan, target), juliaflow_runtime_mode(), "transform fit/apply")
    prepared = membership === nothing ? nothing : JuliaFlowDataScienceProjectTransforms.prepare_numeric_fit_apply(project, dataset_id, membership, apply_splits, transform_ref)
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    run_id = "transform-fit-apply-" * replace(string(uuid4()), "-" => "")
    artifact_refs = JuliaFlowDataScienceProjectTransforms.transform_fit_apply_artifact_refs(project.project_id, run_id, apply_splits, timestamp)
    transform_run = JuliaFlowDataScienceProjectTransforms.transform_fit_apply_record(
        run_id,
        dataset_id,
        split_plan,
        apply_splits,
        transform_ref,
        artifact_refs,
        timestamp,
    )
    if prepared !== nothing
        JuliaFlowDataScienceProjectSplits.persist_membership!(membership, local_data_ref_path_for_write)
        JuliaFlowDataScienceProjectTransforms.persist_numeric_fit_apply!(prepared, transform_run["artifactRefs"], transform_ref, local_data_ref_path_for_write)
        artifact_refs = transform_run["artifactRefs"]
        transform_run["membershipEvidence"] = split_membership_evidence(membership)
        transform_run["transformKind"] = "numeric_standardize"
    end
    project.transform_fit_apply_records = [transform_run, project.transform_fit_apply_records...]
    resource_evidence = data_science_project_job_resource_evidence(state; execution_mode = "transform_fit_apply")
    execution_evidence = data_science_project_execution_evidence!(
        state,
        project,
        "transform_fit_apply";
        dataset_id = dataset_id,
        source_record_id = run_id,
        output_refs = artifact_refs,
        resource_evidence = resource_evidence,
        started_at = timestamp,
        finished_at = timestamp,
        plan = ["validate_locked_split", "fit_train_transform_state", "apply_frozen_transform_to_heldout_splits"],
        worker_backed = true,
    )
    transform_run["executionEvidence"] = execution_evidence
    record_data_science_project_job!(
        project,
        "transform_fit_apply";
        dataset_id = dataset_id,
        split_plan_id = String(get(split_plan, "splitPlanId", "")),
        source_record_id = run_id,
        output_refs = artifact_refs,
        resource_evidence = resource_evidence,
        execution_evidence = execution_evidence,
        started_at = timestamp,
        finished_at = timestamp,
    )
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    payload = JuliaFlowGatewayRepository.data_science_project_payload(state.data_science_projects[project.project_id])
    return JSON3.write(Dict("status" => "completed", "transformRun" => transform_run, "project" => payload))
end

function statistical_analysis_dataset(project::DataScienceProjectRecord, body::AbstractDict)
    dataset_id = if haskey(body, "datasetId")
        String(body["datasetId"])
    elseif !isempty(project.datasets)
        String(get(project.datasets[1], "datasetId", ""))
    else
        error("statistical analysis dataset required")
    end
    project_has_dataset(project, dataset_id) || error("statistical analysis dataset not registered in project: $(dataset_id)")
    return dataset_id
end

function statistical_analysis_methods(body::AbstractDict)
    return JuliaFlowDataScienceProjectStatistics.statistical_analysis_methods(body)
end

function data_science_project_dataset(project::DataScienceProjectRecord, dataset_id::AbstractString)
    dataset_index = findfirst(dataset -> String(get(dataset, "datasetId", "")) == String(dataset_id), project.datasets)
    dataset_index === nothing && error("statistical analysis dataset not registered in project: $(dataset_id)")
    return project.datasets[dataset_index]
end

function resolve_local_data_ref_path(source_ref::AbstractString)
    home = local_appliance_home()
    return JuliaFlowDataScienceProjectLocalSources.resolve_local_data_ref_path(
        source_ref;
        local_home = home,
        data_root = local_data_estate_root(home),
        validate_local_ref = validate_project_local_ref!,
    )
end

function local_data_ref_path_for_write(local_ref::AbstractString)
    home = local_appliance_home()
    return JuliaFlowDataScienceProjectLocalSources.local_data_ref_path_for_write(
        local_ref;
        local_home = home,
        data_root = local_data_estate_root(home),
        validate_local_ref = validate_project_local_ref!,
    )
end

function local_artifact_checksum(path::AbstractString)
    return JuliaFlowDataScienceProjectLocalSources.local_artifact_checksum(path)
end

function resolve_local_artifact_ref_path(local_ref::AbstractString)
    home = local_appliance_home()
    return JuliaFlowDataScienceProjectLocalSources.resolve_local_artifact_ref_path(local_ref;
        local_home = home, data_root = local_data_estate_root(home), validate_local_ref = validate_project_local_ref!)
end

function write_local_artifact!(path::AbstractString, content::AbstractString)
    return JuliaFlowDataScienceProjectLocalSources.write_local_artifact!(path, content)
end

function requested_feature_columns(body::AbstractDict)
    return JuliaFlowDataScienceProjectStatistics.requested_feature_columns(body)
end

function local_csv_statistical_evidence(dataset::AbstractDict, body::AbstractDict, methods::AbstractVector)
    source_uri = String(get(dataset, "sourceUri", ""))
    source_path = resolve_local_data_ref_path(source_uri)
    source_path === nothing && return nothing
    return JuliaFlowDataScienceProjectStatistics.local_csv_statistical_evidence_from_path(
        dataset,
        source_path,
        body,
        methods,
    )
end

function statistical_analysis_charts(dataset_id::AbstractString, run_id::AbstractString, fixture::AbstractDict, evidence = nothing)
    profile_rows = evidence === nothing ? get(fixture, "profileSummary", Any[]) : get(evidence, "summaries", Any[])
    charts = Dict{String,Any}[]
    if !isempty(profile_rows)
        push!(
            charts,
            plotly_chart_spec(
                "$(run_id)-missingness",
                "Missingness By Column",
                "bar",
                [
                    Dict(
                        "type" => "bar",
                        "x" => [String(get(row, "name", get(row, "column", ""))) for row in profile_rows],
                        "y" => [Int(get(row, "missingCount", 0)) for row in profile_rows],
                        "marker" => Dict("color" => "#d97706"),
                    ),
                ];
                source_label = "Statistical EDA $(dataset_id)",
                summary = "Missingness chart generated from local statistical EDA profile evidence.",
                evidence_ref = "local://analysis/$(dataset_id)/$(run_id)/results.json",
            ),
        )
    end
    correlation_columns = evidence === nothing ? ["feature_1", "feature_2", "target"] : [String(column) for column in get(evidence, "numericColumns", String[])]
    correlation_matrix = evidence === nothing ? [[1.0, 0.42, 0.31], [0.42, 1.0, 0.56], [0.31, 0.56, 1.0]] : get(evidence, "correlationMatrix", Any[])
    isempty(correlation_columns) && (correlation_columns = ["numeric_column"])
    isempty(correlation_matrix) && (correlation_matrix = [[1.0]])
    push!(
        charts,
        plotly_chart_spec(
            "$(run_id)-correlation",
            "Correlation Evidence",
            "heatmap",
            [
                Dict(
                    "type" => "heatmap",
                    "x" => correlation_columns,
                    "y" => correlation_columns,
                    "z" => correlation_matrix,
                    "colorscale" => "Viridis",
                ),
            ];
            source_label = "Statistical EDA $(dataset_id)",
            summary = "Correlation heatmap generated locally for statistical EDA review.",
            evidence_ref = "local://analysis/$(dataset_id)/$(run_id)/results.json",
        ),
    )
    return charts
end

function statistical_analysis_code_artifact(dataset_id::AbstractString, methods::AbstractVector, body::AbstractDict)
    return JuliaFlowDataScienceProjectStatistics.statistical_analysis_code_artifact(dataset_id, methods, body)
end

function persist_statistical_analysis_artifacts!(
    analysis_run::Dict{String,Any},
    dataset_id::AbstractString,
    methods::AbstractVector,
    body::AbstractDict,
    evidence;
    replay_code = nothing,
)
    code_ref = String(analysis_run["generatedCodeRef"])
    result_ref = String(analysis_run["resultRef"])
    code_path = local_data_ref_path_for_write(code_ref)
    result_path = local_data_ref_path_for_write(result_ref)
    code = replay_code === nothing ? statistical_analysis_code_artifact(dataset_id, methods, body) : replay_code
    result_payload = Dict{String,Any}(
        "analysisRunId" => String(analysis_run["analysisRunId"]),
        "datasetId" => dataset_id,
        "method" => String(analysis_run["method"]),
        "status" => String(analysis_run["status"]),
        "resultSummary" => evidence === nothing ? Dict{String,Any}("executionMode" => "fixture_fallback") : evidence,
        "warnings" => analysis_run["warnings"],
        "createdAt" => String(analysis_run["createdAt"]),
    )
    result_json = JSON3.write(result_payload)
    code_artifact = write_local_artifact!(code_path, code)
    result_artifact = write_local_artifact!(result_path, result_json)
    analysis_run["artifactRefs"] = [
        Dict(
            "refId" => "artifact-$(analysis_run["analysisRunId"])-code",
            "kind" => "statistical_analysis_code",
            "localOnly" => true,
            "path" => code_ref,
            "checksumSha256" => code_artifact["checksumSha256"],
            "sizeBytes" => code_artifact["sizeBytes"],
            "checksumMode" => code_artifact["checksumMode"],
            "generatedAt" => String(analysis_run["createdAt"]),
        ),
        Dict(
            "refId" => "artifact-$(analysis_run["analysisRunId"])-results",
            "kind" => "statistical_analysis_results",
            "localOnly" => true,
            "path" => result_ref,
            "checksumSha256" => result_artifact["checksumSha256"],
            "sizeBytes" => result_artifact["sizeBytes"],
            "checksumMode" => result_artifact["checksumMode"],
            "generatedAt" => String(analysis_run["createdAt"]),
        ),
    ]
    return analysis_run["artifactRefs"]
end

function run_statistical_analysis_response!(state::GatewayState, project_id::AbstractString, body::AbstractDict)
    haskey(state.data_science_projects, project_id) || error("data science project not found: $(project_id)")
    ensure_cpu_project_job_allowed(state)
    project = deepcopy(state.data_science_projects[project_id])
    dataset_id = statistical_analysis_dataset(project, body)
    dataset = data_science_project_dataset(project, dataset_id)
    methods = statistical_analysis_methods(body)
    if haskey(body, "scope")
        validator = JuliaFlowGatewayRepository.JuliaFlowProjectPayloadValidation
        request_schema = validator.contract_schema(Dict("\$ref" => "#/components/schemas/RunStatisticalAnalysisRequest"))
        validator.JSONSchema.validate(request_schema, validator.contract_value(body)) === nothing || error("analysis run invalid contract payload")
    end
    run_id = "stats-" * replace(string(uuid4()), "-" => "")
    fixture = data_profile_fixture(dataset_id, "local://data/$(dataset_id)")
    schema = analysis_schema(project, dataset_id)
    evidence = JuliaFlowDataScienceProjectEvidence.read_result(
        () -> haskey(body, "scope") ? JuliaFlowProjectAnalysis.scoped_evidence(dataset, resolve_local_data_ref_path(dataset["sourceUri"]), body, schema) : local_csv_statistical_evidence(dataset, body, methods), juliaflow_runtime_mode(), "statistical analysis")
    warnings = evidence === nothing ? String[] : String.(get(evidence, "warnings", String[]))
    haskey(body, "scope") || haskey(body, "targetColumn") || push!(warnings, "No targetColumn supplied; inferential tests are recorded as exploratory evidence.")
    evidence === nothing && push!(warnings, "Managed local CSV source was not available; fixture profile evidence was used for this statistical EDA run.")
    analysis_run = Dict{String,Any}(
        "analysisRunId" => run_id,
        "datasetId" => dataset_id,
        "method" => join(methods, ","),
        "status" => "completed",
        "generatedCodeRef" => "local://analysis/$(dataset_id)/$(run_id)/analysis.jl",
        "resultRef" => "local://analysis/$(dataset_id)/$(run_id)/results.json",
        "charts" => statistical_analysis_charts(dataset_id, run_id, fixture, evidence),
        "warnings" => warnings,
        "createdAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
    )
    evidence === nothing || (analysis_run["resultSummary"] = evidence)
    replay = nothing
    if haskey(body, "scope")
        replay = JuliaFlowProjectAnalysis.replay_code(dataset, body, schema)
        distribution = evidence["distribution"]
        push!(analysis_run["charts"], plotly_chart_spec("$(run_id)-distribution", "$(distribution["column"]) distribution", "histogram",
            [Dict("type" => "histogram", "x" => distribution["values"], "name" => String(distribution["column"]))];
            layout = Dict("xaxis" => Dict("title" => distribution["label"]), "yaxis" => Dict("title" => "Valid row count")),
            source_label = "$(evidence["rowCount"]) selected original rows", summary = "Measured nonmissing numeric values; counts computed from the selected scope", evidence_ref = analysis_run["resultRef"]))
        if haskey(evidence, "scatter")
            scatter = evidence["scatter"]
            push!(analysis_run["charts"], plotly_chart_spec("$(run_id)-scatter", "$(scatter["xColumn"]) and $(scatter["yColumn"])", "scatter",
                [Dict("type" => "scatter", "mode" => "markers", "x" => scatter["x"], "y" => scatter["y"], "name" => "Selected complete pairs")];
                layout = Dict("xaxis" => Dict("title" => scatter["xLabel"]), "yaxis" => Dict("title" => scatter["yLabel"])),
                source_label = "$(evidence["rowCount"]) selected original rows", summary = "$(scatter["count"]) complete pairs; association is not causation", evidence_ref = analysis_run["resultRef"]))
        end
    end
    artifact_refs = persist_statistical_analysis_artifacts!(analysis_run, dataset_id, methods, body, evidence; replay_code = replay)
    project.statistical_analysis_runs = [analysis_run, project.statistical_analysis_runs...]
    timestamp = String(analysis_run["createdAt"])
    resource_evidence = data_science_project_job_resource_evidence(state; execution_mode = "statistical_analysis")
    execution_evidence = data_science_project_execution_evidence!(
        state,
        project,
        "statistical_analysis";
        dataset_id = dataset_id,
        source_record_id = run_id,
        output_refs = artifact_refs,
        resource_evidence = resource_evidence,
        started_at = timestamp,
        finished_at = timestamp,
        plan = ["load_local_dataset_profile", "compute_statistical_tests", "materialize_statistical_analysis_artifacts"],
        worker_backed = !haskey(body, "scope"),
    )
    analysis_run["executionEvidence"] = execution_evidence
    record_data_science_project_job!(
        project,
        "statistical_analysis";
        dataset_id = dataset_id,
        source_record_id = run_id,
        output_refs = artifact_refs,
        resource_evidence = resource_evidence,
        execution_evidence = execution_evidence,
        started_at = timestamp,
        finished_at = timestamp,
    )
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    payload = JuliaFlowGatewayRepository.data_science_project_payload(state.data_science_projects[project.project_id])
    return JSON3.write(Dict("status" => "completed", "analysisRun" => analysis_run, "project" => payload))
end

function project_split_plan_for_request(project::DataScienceProjectRecord, body::AbstractDict, dataset_id::AbstractString, action::AbstractString)
    return JuliaFlowDataScienceProjectTuning.project_split_plan_for_request(project, body, dataset_id, action)
end

function validate_tuning_split_context(project::DataScienceProjectRecord, body::AbstractDict, dataset_id::AbstractString)
    return JuliaFlowDataScienceProjectTuning.validate_tuning_split_context(project, body, dataset_id)
end

function tuning_metric_names(body::AbstractDict)
    return JuliaFlowDataScienceProjectTuning.tuning_metric_names(body)
end

function tuning_max_trials(body::AbstractDict)
    return JuliaFlowDataScienceProjectTuning.tuning_max_trials(body)
end

function local_csv_validation_tuning_trials(
    dataset::AbstractDict,
    split_plan::AbstractDict,
    project_id::AbstractString,
    study_id::AbstractString,
    algorithm::AbstractString,
    metric_names::AbstractVector,
    max_trials::Integer,
    timestamp::AbstractString,
    target_column::AbstractString,
    selected_backend::AbstractString = "cpu";
    membership = nothing,
)
    source_path = resolve_local_data_ref_path(String(get(dataset, "sourceUri", "")))
    source_path === nothing && return nothing
    return JuliaFlowDataScienceProjectTuning.local_csv_validation_tuning_trials(
        project_id,
        study_id,
        algorithm,
        metric_names,
        max_trials,
        timestamp,
        dataset,
        source_path,
        target_column,
        split_plan,
        selected_backend;
        membership = membership === nothing ? nothing : membership["rows"],
        allowed_features = membership === nothing ? nothing : membership["featureColumns"],
    )
end

function annotate_tuning_trial_resource_evidence!(trials::Vector{Dict{String,Any}}, resource_evidence::AbstractDict)
    for (index, trial) in enumerate(trials)
        trial_resource = Dict{String,Any}(String(key) => value for (key, value) in pairs(resource_evidence))
        trial_resource["executionMode"] = "validation_only_tuning_trial"
        trial_resource["trialIndex"] = index
        trial_resource["trialId"] = String(get(trial, "trialId", ""))
        trial_resource["candidateIndex"] = Int(get(get(trial, "parameters", Dict{String,Any}()), "candidateIndex", index))
        trial["resourceEvidence"] = trial_resource
        validation = get!(trial, "validationEvidence", Dict{String,Any}())
        if !haskey(validation, "gpuTrialEvidence")
            gpu_evidence = JuliaFlowDataScienceProjectTuning.tuning_gpu_trial_capability(String(get(trial_resource, "selectedBackend", "cpu")))
            if String(get(gpu_evidence, "gpuTrialExecutionStatus", "")) == "ready"
                gpu_evidence["gpuTrialExecutionStatus"] = "skipped"
                gpu_evidence["gpuTrialSkippedReason"] = "trial_data_unavailable_for_gpu_metric_execution"
            end
            validation["gpuTrialEvidence"] = gpu_evidence
        end
        validation["resourceEvidence"] = trial_resource
        validation["dispatchLane"] = String(get(trial_resource, "dispatchLane", "cpu"))
        validation["workerPool"] = String(get(trial_resource, "workerPool", "local-cpu"))
    end
    return trials
end

function persist_tuning_trial_artifacts!(trials::Vector{Dict{String,Any}})
    for trial in trials
        refs = get(trial, "artifactRefs", Dict{String,Any}[])
        isempty(refs) && continue
        ref = refs[1]
        artifact_ref = String(get(ref, "path", ""))
        isempty(strip(artifact_ref)) && continue
        artifact_path = local_data_ref_path_for_write(artifact_ref)
        content = JSON3.write(
            Dict(
                "trialId" => String(get(trial, "trialId", "")),
                "parameters" => get(trial, "parameters", Dict{String,Any}()),
                "metrics" => get(trial, "metrics", Dict{String,Any}()),
                "selected" => Bool(get(trial, "selected", false)),
                "validationEvidence" => get(trial, "validationEvidence", Dict{String,Any}()),
                "resourceEvidence" => get(trial, "resourceEvidence", Dict{String,Any}()),
            ),
        ) * "\n"
        artifact = write_local_artifact!(artifact_path, content)
        ref["checksumSha256"] = artifact["checksumSha256"]
        ref["sizeBytes"] = artifact["sizeBytes"]
        ref["checksumMode"] = artifact["checksumMode"]
    end
    return trials
end

function run_tuning_study_response!(state::GatewayState, project_id::AbstractString, body::AbstractDict)
    haskey(state.data_science_projects, project_id) || error("data science project not found: $(project_id)")
    ensure_cpu_project_job_allowed(state)
    project = deepcopy(state.data_science_projects[project_id])
    dataset_id = statistical_analysis_dataset(project, body)
    dataset = data_science_project_dataset(project, dataset_id)
    split_plan, validation_context = validate_tuning_split_context(project, body, dataset_id)
    haskey(body, "targetColumn") || error("tuning study targetColumn required")
    target_column = String(body["targetColumn"])
    task_type = haskey(body, "taskType") ? String(body["taskType"]) : "regression"
    algorithm = haskey(body, "algorithm") ? String(body["algorithm"]) : "MLJ.EvoTreesRegressor"
    metric_names = tuning_metric_names(body)
    max_trials = tuning_max_trials(body)
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    training_plan_id = haskey(body, "trainingPlanId") ? String(body["trainingPlanId"]) : "training-" * replace(string(uuid4()), "-" => "")
    training_plan = JuliaFlowDataScienceProjectTuning.tuning_training_plan_record(
        training_plan_id,
        target_column,
        task_type,
        metric_names,
        split_plan,
        timestamp,
    )
    JuliaFlowDataScienceProjectTuning.upsert_training_plan!(project, training_plan)
    study_id = "tuning-" * replace(string(uuid4()), "-" => "")
    resource_evidence = data_science_project_job_resource_evidence(state; execution_mode = "validation_only_tuning")
    membership = JuliaFlowDataScienceProjectEvidence.read_result(() -> project_execution_membership!(project, dataset, split_plan, target_column), juliaflow_runtime_mode(), "tuning study")
    merge!(validation_context, split_membership_evidence(membership))
    trials = JuliaFlowDataScienceProjectEvidence.read_result(() -> local_csv_validation_tuning_trials(
        dataset,
        split_plan,
        project.project_id,
        study_id,
        algorithm,
        metric_names,
        max_trials,
        timestamp,
        target_column,
        String(get(resource_evidence, "selectedBackend", "cpu"));
        membership = membership,
    ), juliaflow_runtime_mode(), "tuning study")
    if trials === nothing
        trials = JuliaFlowDataScienceProjectTuning.tuning_trials(project.project_id, study_id, algorithm, metric_names, max_trials, timestamp)
        validation_context["tuningExecutionMode"] = "deterministic_fallback"
        validation_context["tuningWarning"] = "Managed local CSV source or numeric target was unavailable; deterministic tuning trial evidence was used."
    else
        validation_context["tuningExecutionMode"] = "local_csv_validation_tuning"
    end
    membership === nothing || JuliaFlowDataScienceProjectSplits.persist_membership!(membership, local_data_ref_path_for_write)
    annotate_tuning_trial_resource_evidence!(trials, resource_evidence)
    persist_tuning_trial_artifacts!(trials)
    tuning_study = JuliaFlowDataScienceProjectTuning.tuning_study_record(study_id, training_plan_id, trials, validation_context, timestamp)
    project.tuning_studies = [tuning_study, project.tuning_studies...]
    tuning_output_refs = JuliaFlowDataScienceProjectTuning.tuning_output_refs(trials)
    execution_evidence = data_science_project_execution_evidence!(
        state,
        project,
        "tuning_study";
        dataset_id = dataset_id,
        source_record_id = study_id,
        output_refs = tuning_output_refs,
        resource_evidence = resource_evidence,
        started_at = timestamp,
        finished_at = timestamp,
        plan = ["validate_training_split_policy", "run_validation_only_trials", "select_best_trial"],
        worker_backed = true,
    )
    tuning_study["executionEvidence"] = execution_evidence
    tuning_study["validationEvidence"]["executionId"] = execution_evidence["executionId"]
    record_data_science_project_job!(
        project,
        "tuning_study";
        dataset_id = dataset_id,
        split_plan_id = String(get(split_plan, "splitPlanId", "")),
        source_record_id = study_id,
        output_refs = tuning_output_refs,
        resource_evidence = resource_evidence,
        execution_evidence = execution_evidence,
        started_at = timestamp,
        finished_at = timestamp,
    )
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    payload = JuliaFlowGatewayRepository.data_science_project_payload(state.data_science_projects[project.project_id])
    return JSON3.write(Dict("status" => "completed", "trainingPlan" => training_plan, "tuningStudy" => tuning_study, "project" => payload))
end

function project_training_plan_for_request(project::DataScienceProjectRecord, body::AbstractDict)
    return JuliaFlowDataScienceProjectEvaluation.project_training_plan_for_request(project, body)
end

function project_tuning_study_for_final_evaluation(project::DataScienceProjectRecord, body::AbstractDict, training_plan_id::AbstractString)
    return JuliaFlowDataScienceProjectEvaluation.project_tuning_study_for_final_evaluation(project, body, training_plan_id)
end

function final_evaluation_metric_names(body::AbstractDict, training_plan::AbstractDict)
    return JuliaFlowDataScienceProjectEvaluation.final_evaluation_metric_names(body, training_plan)
end

function final_evaluation_approval_threshold(body::AbstractDict)
    return JuliaFlowDataScienceProjectEvaluation.final_evaluation_approval_threshold(body)
end

function local_csv_training_model_artifact(project::DataScienceProjectRecord, dataset_id::AbstractString, split_plan_id::AbstractString, training_plan::AbstractDict)
    target_column = String(get(training_plan, "targetColumn", ""))
    for job in project.project_jobs
        String(get(job, "jobType", "")) == "training" || continue
        String(get(job, "datasetId", "")) == String(dataset_id) || continue
        String(get(job, "splitPlanId", "")) == String(split_plan_id) || continue
        for ref in get(job, "outputRefs", Any[])
            ref isa AbstractDict || continue
            kind = String(get(ref, "kind", ""))
            kind in ("training_trained_model", "trained_model") || continue
            artifact_ref = String(get(ref, "path", get(ref, "artifactRef", "")))
            isempty(strip(artifact_ref)) && continue
            artifact_path = local_data_ref_path_for_write(artifact_ref)
            isfile(artifact_path) || continue
            checksum = local_artifact_checksum(artifact_path)
            expected_checksum = strip(String(get(ref, "checksumSha256", "")))
            if !isempty(expected_checksum) && lowercase(expected_checksum) != checksum
                error("final evaluation training artifact checksum mismatch: $(artifact_ref)")
            end
            payload = try
                JSON3.read(read(artifact_path, String), Dict{String,Any})
            catch
                error("final evaluation training artifact must contain JSON: $(artifact_ref)")
            end
            String(get(payload, "nativeModelKind", String(get(payload, "modelKind", "")))) in ("local_csv_single_feature_ols", "local_csv_multi_feature_ols", "local_csv_binary_centroid_classifier") || continue
            isempty(strip(target_column)) || String(get(payload, "targetColumn", "")) == target_column || continue
            payload["artifactRef"] = artifact_ref
            payload["checksumSha256"] = checksum
            payload["sizeBytes"] = filesize(artifact_path)
            payload["checksumMode"] = "streaming_file_sha256"
            return payload
        end
    end
    return nothing
end

function local_csv_final_evaluation_result(
    dataset::AbstractDict,
    training_plan::AbstractDict,
    metric_names::AbstractVector,
    split_plan::AbstractDict,
    model_artifact = nothing;
    membership = nothing,
)
    source_uri = String(get(dataset, "sourceUri", ""))
    source_path = resolve_local_data_ref_path(source_uri)
    source_path === nothing && return nothing
    target_column = String(get(training_plan, "targetColumn", ""))
    isempty(strip(target_column)) && return nothing
    return JuliaFlowDataScienceProjectEvaluation.final_evaluation_metrics_from_csv(
        dataset,
        source_path,
        target_column,
        metric_names,
        split_plan,
        model_artifact;
        membership = membership === nothing ? nothing : membership["rows"],
    )
end

function local_csv_prediction_values_from_report(dataset::AbstractDict, report::AbstractDict, row_count::Integer)
    validation = get(report, "validationEvidence", Dict{String,Any}())
    evidence = get(validation, "evaluationDataEvidence", Dict{String,Any}())
    execution_mode = String(get(evidence, "executionMode", ""))
    execution_mode in ("local_csv_trained_artifact", "mlj_package_backed_final_evaluation") || return nothing, nothing
    model_kind = String(get(evidence, "modelKind", ""))
    native_model_kind = String(get(evidence, "nativeModelKind", model_kind))
    feature_columns = native_model_kind in ("local_csv_multi_feature_ols", "local_csv_binary_centroid_classifier") ?
        [String(column) for column in get(evidence, "featureColumns", Any[])] :
        [String(get(evidence, "featureColumn", ""))]
    feature_columns = [column for column in feature_columns if !isempty(strip(column))]
    isempty(feature_columns) && return nothing, nothing
    source_path = resolve_local_data_ref_path(String(get(dataset, "sourceUri", "")))
    source_path === nothing && return nothing, nothing
    table = JuliaFlowDataScienceProjectSplits.split_table(source_path)
    train_rows = Int.(get(evidence, "trainingRowIndices", Int[]))
    isempty(train_rows) && return nothing, nothing
    maximum(train_rows) <= length(table["rows"]) && row_count <= length(table["rows"]) || return nothing, nothing
    numeric_columns = JuliaFlowDataScienceProjectSplits.training_numeric_columns(table, train_rows)
    JuliaFlowDataScienceProjectSplits.require_numeric_rows(numeric_columns, feature_columns, collect(1:Int(row_count)))
    all(column -> haskey(numeric_columns, column), feature_columns) || return nothing, nothing
    if execution_mode == "mlj_package_backed_final_evaluation"
        target_column = String(get(evidence, "targetColumn", ""))
        if haskey(numeric_columns, target_column)
            get(validation, "sourceChecksumSha256", "") == local_artifact_checksum(source_path) || error("source evidence unavailable; package refitting requires the frozen training source")
            train_count = length(train_rows)
            if train_count > 0 && all(length(numeric_columns[column]) >= max(train_count, Int(row_count)) for column in feature_columns) && length(numeric_columns[target_column]) >= train_count
                train_feature_pairs = [column => numeric_columns[column][train_rows] for column in feature_columns]
                train_target = numeric_columns[target_column][train_rows]
                prediction_feature_pairs = [column => numeric_columns[column][1:Int(row_count)] for column in feature_columns]
                mlj_result = JuliaFlowDataScienceProjectMLJ.mlj_package_prediction_result(
                    String(get(evidence, "requestedAlgorithm", "")),
                    train_feature_pairs,
                    train_target,
                    prediction_feature_pairs;
                    classifier_mode = native_model_kind == "local_csv_binary_centroid_classifier",
                )
                mlj_result !== nothing && return Float64.(mlj_result["predictions"]), "mlj_package_backed_prediction_export"
            end
        end
    end
    coefficients = get(evidence, "coefficients", Dict{String,Any}())
    intercept = Float64(get(evidence, "baselineIntercept", 0.0))
    if haskey(coefficients, "intercept")
        intercept = Float64(coefficients["intercept"])
    end
    values = Float64[]
    if native_model_kind == "local_csv_binary_centroid_classifier"
        centroid_model = Dict{String,Any}(
            "featureColumns" => feature_columns,
            "positiveLabel" => get(coefficients, "positiveLabel", 1.0),
            "negativeLabel" => get(coefficients, "negativeLabel", 0.0),
            "positivePrior" => get(coefficients, "positivePrior", 0.5),
            "positiveMeans" => get(coefficients, "positiveMeans", Dict{String,Any}()),
            "negativeMeans" => get(coefficients, "negativeMeans", Dict{String,Any}()),
            "featureScales" => get(coefficients, "featureScales", Dict{String,Any}()),
        )
        feature_pairs = [column => numeric_columns[column] for column in feature_columns]
        probabilities = JuliaFlowDataScienceProjectStatistics.binary_centroid_probabilities(centroid_model, feature_pairs, 1:Int(row_count))
        return probabilities, "local_csv_trained_artifact"
    end
    for index in 1:Int(row_count)
        if native_model_kind == "local_csv_multi_feature_ols" && haskey(coefficients, "slopes")
            slopes = get(coefficients, "slopes", Dict{String,Any}())
            prediction = intercept + sum(
                Float64(get(slopes, column, 0.0)) * numeric_columns[column][min(index, length(numeric_columns[column]))]
                for column in feature_columns
            )
            push!(values, round(prediction; digits = 6))
        else
            slope = haskey(coefficients, "slope") ? Float64(coefficients["slope"]) : Float64(get(evidence, "baselineSlope", 0.0))
            feature_column = first(feature_columns)
            feature = numeric_columns[feature_column][min(index, length(numeric_columns[feature_column]))]
            push!(values, round(intercept + slope * feature; digits = 6))
        end
    end
    return values, "local_csv_trained_artifact"
end

function evaluation_model_runtime_evidence(report::AbstractDict)
    validation = get(report, "validationEvidence", Dict{String,Any}())
    evidence = get(validation, "evaluationDataEvidence", Dict{String,Any}())
    runtime = Dict{String,Any}()
    for key in ("modelKind", "nativeModelKind", "modelFamily", "requestedAlgorithm", "modelArtifactRef", "modelArtifactChecksumSha256", "packageScoringMode")
        haskey(evidence, key) && (runtime[key] = evidence[key])
    end
    haskey(evidence, "mljEvidence") && (runtime["mljEvidence"] = evidence["mljEvidence"])
    haskey(evidence, "mljScoringEvidence") && (runtime["mljScoringEvidence"] = evidence["mljScoringEvidence"])
    return isempty(runtime) ? nothing : runtime
end

function persist_final_evaluation_report_artifact!(evaluation_report::Dict{String,Any})
    artifact_refs = get(evaluation_report, "artifactRefs", Dict{String,Any}[])
    isempty(artifact_refs) && return artifact_refs
    artifact_ref = String(get(artifact_refs[1], "path", ""))
    isempty(strip(artifact_ref)) && return artifact_refs
    artifact_path = local_data_ref_path_for_write(artifact_ref)
    content = JSON3.write(
        Dict(
            "evaluationReportId" => String(get(evaluation_report, "evaluationReportId", "")),
            "trainingPlanId" => String(get(evaluation_report, "trainingPlanId", "")),
            "splitPlanId" => String(get(evaluation_report, "splitPlanId", "")),
            "metrics" => get(evaluation_report, "metrics", Dict{String,Any}()),
            "approved" => Bool(get(evaluation_report, "approved", false)),
            "finalTestOnly" => Bool(get(evaluation_report, "finalTestOnly", false)),
            "validationEvidence" => get(evaluation_report, "validationEvidence", Dict{String,Any}()),
            "generatedAt" => String(get(evaluation_report, "generatedAt", "")),
        ),
    ) * "\n"
    artifact = write_local_artifact!(artifact_path, content)
    materialized_refs = [
        merge(
            Dict{String,Any}(String(key) => value for (key, value) in pairs(ref)),
            artifact,
        ) for ref in artifact_refs
    ]
    evaluation_report["artifactRefs"] = materialized_refs
    return materialized_refs
end

function run_final_evaluation_response!(state::GatewayState, project_id::AbstractString, body::AbstractDict)
    haskey(state.data_science_projects, project_id) || error("data science project not found: $(project_id)")
    ensure_cpu_project_job_allowed(state)
    project = deepcopy(state.data_science_projects[project_id])
    dataset_id = statistical_analysis_dataset(project, body)
    dataset = data_science_project_dataset(project, dataset_id)
    split_plan = project_split_plan_for_request(project, body, dataset_id, "final evaluation")
    training_plan = project_training_plan_for_request(project, body)
    split_plan_id = String(get(split_plan, "splitPlanId", ""))
    tuning_study = project_tuning_study_for_final_evaluation(project, body, String(get(training_plan, "trainingPlanId", "")))
    validation_context = JuliaFlowDataScienceProjectEvaluation.final_evaluation_validation_context(
        project,
        body,
        dataset_id,
        split_plan,
        training_plan,
        tuning_study,
    )
    JuliaFlowDataScienceProjectEvidence.require_tuning(tuning_study, juliaflow_runtime_mode(), "final evaluation")
    metric_names = final_evaluation_metric_names(body, training_plan)
    approval_threshold = final_evaluation_approval_threshold(body)
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    report_id = "eval-" * replace(string(uuid4()), "-" => "")
    membership = JuliaFlowDataScienceProjectEvidence.read_result(() -> project_execution_membership!(project, dataset, split_plan, String(get(training_plan, "targetColumn", ""))), juliaflow_runtime_mode(), "final evaluation")
    merge!(validation_context, split_membership_evidence(membership))
    training_model_artifact = local_csv_training_model_artifact(project, dataset_id, split_plan_id, training_plan)
    if membership !== nothing
        JuliaFlowDataScienceProjectSplits.require_membership_evidence(get(tuning_study, "validationEvidence", Dict{String,Any}()), membership)
        training_model_artifact === nothing || JuliaFlowDataScienceProjectSplits.require_membership_evidence(training_model_artifact, membership)
    end
    evaluation_result = JuliaFlowDataScienceProjectEvidence.read_result(
        () -> local_csv_final_evaluation_result(dataset, training_plan, metric_names, split_plan, training_model_artifact; membership = membership), juliaflow_runtime_mode(), "final evaluation")
    metrics = evaluation_result === nothing ? JuliaFlowDataScienceProjectEvaluation.final_evaluation_metrics(metric_names) : evaluation_result["metrics"]
    approved = all(value -> Float64(value) >= approval_threshold, values(metrics))
    evaluation_report = JuliaFlowDataScienceProjectEvaluation.final_evaluation_report_record(
        report_id,
        project.project_id,
        training_plan,
        split_plan_id,
        metrics,
        approved,
        validation_context,
        timestamp,
    )
    if evaluation_result === nothing
        evaluation_report["validationEvidence"]["evaluationExecutionMode"] = "deterministic_fallback"
        evaluation_report["validationEvidence"]["evaluationWarning"] = "Managed local CSV source or numeric target was unavailable; deterministic fallback metrics were used."
    else
        evaluation_report["validationEvidence"]["evaluationExecutionMode"] = evaluation_result["evidence"]["executionMode"]
        evaluation_report["validationEvidence"]["evaluationDataEvidence"] = evaluation_result["evidence"]
    end
    membership === nothing || JuliaFlowDataScienceProjectSplits.persist_membership!(membership, local_data_ref_path_for_write)
    output_refs = persist_final_evaluation_report_artifact!(evaluation_report)
    project.evaluation_reports = [evaluation_report, project.evaluation_reports...]
    resource_evidence = data_science_project_job_resource_evidence(state; execution_mode = "final_evaluation")
    execution_evidence = data_science_project_execution_evidence!(
        state,
        project,
        "final_evaluation";
        dataset_id = dataset_id,
        source_record_id = report_id,
        output_refs = output_refs,
        resource_evidence = resource_evidence,
        started_at = timestamp,
        finished_at = timestamp,
        plan = ["validate_final_test_policy", "score_final_test_split", "materialize_evaluation_report"],
        worker_backed = true,
    )
    evaluation_report["executionEvidence"] = execution_evidence
    evaluation_report["validationEvidence"]["executionId"] = execution_evidence["executionId"]
    record_data_science_project_job!(
        project,
        "final_evaluation";
        dataset_id = dataset_id,
        split_plan_id = split_plan_id,
        source_record_id = report_id,
        output_refs = output_refs,
        resource_evidence = resource_evidence,
        execution_evidence = execution_evidence,
        started_at = timestamp,
        finished_at = timestamp,
    )
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    payload = JuliaFlowGatewayRepository.data_science_project_payload(state.data_science_projects[project.project_id])
    return JSON3.write(Dict("status" => "completed", "evaluationReport" => evaluation_report, "project" => payload))
end

function project_evaluation_report_for_prediction_export(project::DataScienceProjectRecord, body::AbstractDict)
    isempty(project.evaluation_reports) && error("prediction export prerequisite approved final evaluation required")
    if haskey(body, "evaluationReportId")
        report_id = String(body["evaluationReportId"])
        match = findfirst(report -> String(get(report, "evaluationReportId", "")) == report_id, project.evaluation_reports)
        match === nothing && error("prediction export prerequisite evaluation report not found: $(report_id)")
        return project.evaluation_reports[match]
    end
    return project.evaluation_reports[1]
end

function prediction_export_format(body::AbstractDict)
    return JuliaFlowDataScienceProjectPredictionExport.prediction_export_format(body)
end

function prediction_export_row_count(body::AbstractDict, dataset::AbstractDict)
    return JuliaFlowDataScienceProjectPredictionExport.prediction_export_row_count(body, dataset)
end

const PREDICTION_EXPORT_COLUMNS = JuliaFlowDataScienceProjectPredictionExport.PREDICTION_EXPORT_COLUMNS

function prediction_export_contract(body::AbstractDict, output_contract_ref::AbstractString)
    return JuliaFlowDataScienceProjectPredictionExport.prediction_export_contract(body, output_contract_ref)
end

function prediction_export_contract_column_names(contract::AbstractDict)
    return JuliaFlowDataScienceProjectPredictionExport.prediction_export_contract_column_names(contract)
end

function prediction_export_output_columns(body::AbstractDict, contract::AbstractDict)
    return JuliaFlowDataScienceProjectPredictionExport.prediction_export_output_columns(body, contract)
end

function prediction_export_output_mappings(body::AbstractDict, contract::AbstractDict, output_columns::AbstractVector)
    return JuliaFlowDataScienceProjectPredictionExport.prediction_export_output_mappings(body, contract, output_columns)
end

function prediction_export_rows(
    export_id::AbstractString,
    report::AbstractDict,
    dataset_id::AbstractString,
    output_contract_ref::AbstractString,
    row_count::Integer;
    prediction_values = nothing,
)
    return JuliaFlowDataScienceProjectPredictionExport.prediction_export_rows(
        export_id,
        report,
        dataset_id,
        output_contract_ref,
        row_count;
        prediction_values = prediction_values,
    )
end

function selected_prediction_export_rows(rows::AbstractVector, output_columns::AbstractVector, output_mappings::AbstractVector)
    return JuliaFlowDataScienceProjectPredictionExport.selected_prediction_export_rows(rows, output_columns, output_mappings)
end

function prediction_export_content(format::AbstractString, rows::AbstractVector, output_columns::AbstractVector, output_mappings::AbstractVector)
    return JuliaFlowDataScienceProjectPredictionExport.prediction_export_content(format, rows, output_columns, output_mappings)
end

function prediction_output_contract_import_max_bytes()
    return positive_env_int("JULIAFLOW_OUTPUT_CONTRACT_MAX_BYTES", min(local_data_import_max_bytes(), 1024 * 1024))
end

function prediction_output_contract_import_format(raw_import::AbstractDict)
    format = lowercase(strip(String(get(raw_import, "format", "json"))))
    format == "json" || error("prediction export outputContractImport format must be json")
    return format
end

function validate_prediction_output_contract_import_file!(path::AbstractString)
    sensitive_import_path(path) && error("prediction export outputContractImport source appears to contain credentials or secrets")
    isfile(path) || error("prediction export outputContractImport source file not found")
    extension = lowercase(splitext(path)[2])
    extension == ".json" || error("prediction export outputContractImport source extension must be .json")
    size = filesize(path)
    size > 0 || error("prediction export outputContractImport source file is empty")
    size <= prediction_output_contract_import_max_bytes() || error("prediction export outputContractImport source file exceeds size limit")
    return nothing
end

function prediction_output_contract_import_path(raw_import::AbstractDict)
    source_uri = strip(String(get(raw_import, "sourceUri", "")))
    !isempty(source_uri) || error("prediction export outputContractImport sourceUri required")
    format = prediction_output_contract_import_format(raw_import)
    normalized = replace(source_uri, "\\" => "/")
    is_managed_ref = startswith(lowercase(normalized), "local://")
    connector = strip(String(get(raw_import, "connector", is_managed_ref ? "managed_local" : "local_file")))
    connector in ("managed_local", "local_file") || error("prediction export outputContractImport connector must be managed_local or local_file")
    is_managed_ref && connector == "managed_local" || !is_managed_ref && connector == "local_file" || error("prediction export outputContractImport connector does not match sourceUri")
    path = is_managed_ref ? local_data_ref_path_for_write(source_uri) : validate_local_data_import_source!(source_uri)
    validate_prediction_output_contract_import_file!(path)
    checksum = local_artifact_checksum(path)
    if haskey(raw_import, "checksumSha256")
        expected = lowercase(strip(String(raw_import["checksumSha256"])))
        !isempty(expected) || error("prediction export outputContractImport checksumSha256 cannot be empty")
        expected == checksum || error("prediction export outputContractImport checksum mismatch")
    end
    bytes = read(path)
    details = local_data_import_audit_source_details(source_uri)
    details["connector"] = connector
    details["format"] = format
    details["checksumSha256"] = checksum
    details["sizeBytes"] = length(bytes)
    details["checksumMode"] = "streaming_file_sha256"
    return path, bytes, details
end

function prediction_export_contract_and_import(body::AbstractDict, output_contract_ref::AbstractString)
    if haskey(body, "outputContractImport")
        haskey(body, "outputContract") && error("prediction export outputContract and outputContractImport cannot both be provided")
        raw_import = body["outputContractImport"]
        raw_import isa AbstractDict || error("prediction export outputContractImport must be an object")
        _, bytes, import_details = prediction_output_contract_import_path(raw_import)
        content = try
            String(copy(bytes))
        catch
            error("prediction export outputContractImport source must be UTF-8 JSON")
        end
        raw_contract = try
            JSON3.read(content, Dict{String,Any})
        catch
            error("prediction export outputContractImport source must contain valid JSON")
        end
        contract = prediction_export_contract(Dict{String,Any}("outputContract" => raw_contract), output_contract_ref)
        return contract, import_details
    end
    return prediction_export_contract(body, output_contract_ref), nothing
end

function persist_prediction_export_artifact!(
    prediction_export::Dict{String,Any},
    report::AbstractDict,
    dataset_id::AbstractString,
    output_contract_ref::AbstractString,
    output_columns::AbstractVector,
    output_mappings::AbstractVector,
    ;
    prediction_values = nothing,
)
    artifact_ref = String(prediction_export["artifactRef"])
    artifact_path = local_data_ref_path_for_write(artifact_ref)
    rows = prediction_export_rows(
        String(prediction_export["predictionExportId"]),
        report,
        dataset_id,
        output_contract_ref,
        Int(prediction_export["rowCount"]);
        prediction_values = prediction_values,
    )
    content = prediction_export_content(String(get(prediction_export, "format", "csv")), rows, output_columns, output_mappings)
    artifact = write_local_artifact!(artifact_path, content)
    artifact_refs = [
        Dict(
            "refId" => "artifact-$(prediction_export["predictionExportId"])",
            "kind" => "prediction_export",
            "localOnly" => true,
            "path" => artifact_ref,
            "checksumSha256" => artifact["checksumSha256"],
            "sizeBytes" => artifact["sizeBytes"],
            "checksumMode" => artifact["checksumMode"],
            "generatedAt" => String(prediction_export["createdAt"]),
        ),
    ]
    prediction_export["artifactRefs"] = artifact_refs
    return artifact_refs
end

"Require the selected report's producer and original trained model before consuming its scoring evidence."
function require_evaluation_consumer_evidence(project::DataScienceProjectRecord, report::AbstractDict, action::AbstractString)
    mode = juliaflow_runtime_mode()
    validated = JuliaFlowDataScienceProjectEvidence.context_evaluation(project,
        Dict("evaluationReportId" => get(report, "evaluationReportId", "")), mode, action; required = true, resolve_path = local_data_ref_path_for_write)
    fixture_substitution_allowed(mode) && return report
    isequal(json_compatible_value(report), json_compatible_value(validated)) || JuliaFlowDataScienceProjectEvidence.unavailable(action)
    evidence = get(get(report, "validationEvidence", Dict{String,Any}()), "evaluationDataEvidence", Dict{String,Any}())
    if get(evidence, "executionMode", "") in ("local_csv_trained_artifact", "mlj_package_backed_final_evaluation")
        artifact = Dict("artifactRef" => get(evidence, "modelArtifactRef", ""),
            "checksumSha256" => get(evidence, "modelArtifactChecksumSha256", ""))
        payload = JuliaFlowDataScienceProjectEvidence.require_model_artifact(artifact, mode, action, local_data_ref_path_for_write)
        JuliaFlowDataScienceProjectEvidence.require_evaluation_model_binding(project, report, payload, artifact, mode, action, resolve_local_data_ref_path)
    end
    return report
end

function run_prediction_export_response!(state::GatewayState, project_id::AbstractString, body::AbstractDict)
    haskey(state.data_science_projects, project_id) || error("data science project not found: $(project_id)")
    ensure_cpu_project_job_allowed(state)
    project = deepcopy(state.data_science_projects[project_id])
    dataset_id = statistical_analysis_dataset(project, body)
    dataset_index = findfirst(dataset -> String(get(dataset, "datasetId", "")) == String(dataset_id), project.datasets)
    dataset_index === nothing && error("prediction export dataset not registered: $(dataset_id)")
    dataset = project.datasets[dataset_index]
    report = project_evaluation_report_for_prediction_export(project, body)
    require_evaluation_consumer_evidence(project, report, "prediction export")
    Bool(get(report, "approved", false)) || error("prediction export prerequisite approved final evaluation required")
    Bool(get(report, "finalTestOnly", false)) || error("prediction export prerequisite final evaluation evidence required")
    validation = get(report, "validationEvidence", Dict{String,Any}())
    String(get(validation, "finalTestPolicy", "")) == "use_final_test" || error("prediction export prerequisite final test evidence required")
    output_contract_ref = haskey(body, "outputContractRef") ? String(body["outputContractRef"]) : ""
    !isempty(strip(output_contract_ref)) || error("prediction export outputContractRef required")
    format = prediction_export_format(body)
    row_count = prediction_export_row_count(body, dataset)
    output_contract, output_contract_import = prediction_export_contract_and_import(body, output_contract_ref)
    output_columns = prediction_export_output_columns(body, output_contract)
    output_mappings = prediction_export_output_mappings(body, output_contract, output_columns)
    output_contract_columns = prediction_export_contract_column_names(output_contract)
    prediction_values, prediction_scoring_mode = local_csv_prediction_values_from_report(dataset, report, row_count)
    if prediction_values === nothing
        prediction_values, prediction_scoring_mode = JuliaFlowDataScienceProjectPredictionExport.prediction_export_prediction_values(report, row_count)
    end
    if !fixture_substitution_allowed(juliaflow_runtime_mode())
        prediction_scoring_mode == "metric_average_fallback" && JuliaFlowDataScienceProjectEvidence.unavailable("prediction export")
        source_path = resolve_local_data_ref_path(String(get(dataset, "sourceUri", "")))
        source_path === nothing && JuliaFlowDataScienceProjectEvidence.unavailable("prediction export")
        table = JuliaFlowDataScienceProjectEvidence.read_result(() -> JuliaFlowDataScienceProjectStatistics.parse_simple_csv(source_path), juliaflow_runtime_mode(), "prediction export")
        columns, _ = JuliaFlowDataScienceProjectStatistics.simple_numeric_columns(table)
        target_column = String(get(get(validation, "evaluationDataEvidence", Dict{String,Any}()), "targetColumn", ""))
        JuliaFlowDataScienceProjectEvidence.require_result(get(columns, target_column, nothing), juliaflow_runtime_mode(), "prediction export")
        JuliaFlowDataScienceProjectEvidence.require_result(prediction_values, juliaflow_runtime_mode(), "prediction export")
    end
    model_runtime_evidence = evaluation_model_runtime_evidence(report)
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    export_id = "pred-" * replace(string(uuid4()), "-" => "")
    artifact_ref = "local://predictions/$(project.project_id)/$(export_id)/predictions.$(format)"
    prediction_export = Dict{String,Any}(
        "predictionExportId" => export_id,
        "evaluationReportId" => String(get(report, "evaluationReportId", "")),
        "outputContractRef" => output_contract_ref,
        "artifactRef" => artifact_ref,
        "rowCount" => row_count,
        "format" => format,
        "outputColumns" => output_columns,
        "outputContract" => output_contract,
        "outputMappings" => output_mappings,
        "validationEvidence" => Dict{String,Any}(
            "projectId" => project.project_id,
            "datasetId" => dataset_id,
            "evaluationReportId" => String(get(report, "evaluationReportId", "")),
            "outputContractRef" => output_contract_ref,
            "outputColumns" => output_columns,
            "outputContractColumns" => output_contract_columns,
            "outputMappings" => output_mappings,
            "outputSchemaValidated" => true,
            "contractRequiredColumnsSatisfied" => true,
            "finalEvaluationApproved" => true,
            "finalTestOnly" => true,
            "predictionScoringMode" => prediction_scoring_mode,
            "sourceEvaluationMode" => String(get(validation, "evaluationExecutionMode", "unknown")),
        ),
        "createdAt" => timestamp,
    )
    model_runtime_evidence === nothing || (prediction_export["validationEvidence"]["modelRuntimeEvidence"] = model_runtime_evidence)
    output_contract_import === nothing || begin
        prediction_export["outputContractImport"] = output_contract_import
        prediction_export["validationEvidence"]["outputContractImport"] = output_contract_import
    end
    artifact_refs = persist_prediction_export_artifact!(prediction_export, report, dataset_id, output_contract_ref, output_columns, output_mappings; prediction_values = prediction_values)
    resource_evidence = data_science_project_job_resource_evidence(state; execution_mode = "prediction_export")
    execution_evidence = data_science_project_execution_evidence!(
        state,
        project,
        "prediction_export";
        dataset_id = dataset_id,
        source_record_id = export_id,
        output_refs = artifact_refs,
        resource_evidence = resource_evidence,
        started_at = timestamp,
        finished_at = timestamp,
        plan = ["validate_final_evaluation", "score_local_predictions", "materialize_prediction_export"],
        worker_backed = true,
    )
    prediction_export["executionEvidence"] = execution_evidence
    prediction_export["validationEvidence"]["executionId"] = execution_evidence["executionId"]
    project.prediction_exports = [prediction_export, project.prediction_exports...]
    record_data_science_project_job!(
        project,
        "prediction_export";
        dataset_id = dataset_id,
        source_record_id = export_id,
        output_refs = artifact_refs,
        resource_evidence = resource_evidence,
        execution_evidence = execution_evidence,
        started_at = timestamp,
        finished_at = timestamp,
    )
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    payload = JuliaFlowGatewayRepository.data_science_project_payload(state.data_science_projects[project.project_id])
    return JSON3.write(Dict("status" => "completed", "predictionExport" => prediction_export, "project" => payload))
end

function persist_drift_report_artifact!(
    drift_report::Dict{String,Any},
    baseline::AbstractDict,
    prediction_export::AbstractDict,
    output_refs::AbstractVector,
)
    isempty(output_refs) && return output_refs
    artifact_ref = String(get(output_refs[1], "path", ""))
    isempty(strip(artifact_ref)) && return output_refs
    artifact_path = local_data_ref_path_for_write(artifact_ref)
    content = JSON3.write(
        Dict{String,Any}(
            "driftReportId" => String(drift_report["driftReportId"]),
            "baselineId" => String(get(baseline, "baselineId", "")),
            "predictionExportId" => String(get(prediction_export, "predictionExportId", "")),
            "status" => String(drift_report["status"]),
            "metrics" => drift_report["metrics"],
            "featureDrift" => get(drift_report, "featureDrift", Dict{String,Any}()),
            "validationEvidence" => drift_report["validationEvidence"],
            "generatedAt" => String(drift_report["generatedAt"]),
        ),
    )
    artifact = write_local_artifact!(artifact_path, content)
    materialized_refs = [
        Dict{String,Any}(String(key) => value for (key, value) in pairs(ref))
        for ref in output_refs
    ]
    materialized_refs[1]["checksumSha256"] = artifact["checksumSha256"]
    materialized_refs[1]["sizeBytes"] = artifact["sizeBytes"]
    materialized_refs[1]["checksumMode"] = artifact["checksumMode"]
    drift_report["artifactRefs"] = materialized_refs
    return materialized_refs
end

function project_prediction_export_for_drift(project::DataScienceProjectRecord, body::AbstractDict)
    return JuliaFlowDataScienceProjectMonitoring.project_prediction_export_for_drift(project, body)
end

function drift_metric_names(body::AbstractDict)
    return JuliaFlowDataScienceProjectMonitoring.drift_metric_names(body)
end

function drift_threshold(body::AbstractDict)
    return JuliaFlowDataScienceProjectMonitoring.drift_threshold(body)
end

function monitoring_baseline_for_drift!(project::DataScienceProjectRecord, body::AbstractDict, dataset_id::AbstractString, prediction_export::AbstractDict, metric_names::AbstractVector, timestamp::AbstractString)
    return JuliaFlowDataScienceProjectMonitoring.monitoring_baseline_for_drift!(project, body, dataset_id, prediction_export, metric_names, timestamp)
end

function prediction_export_artifact_values(prediction_export::AbstractDict)
    artifact_ref = String(get(prediction_export, "artifactRef", ""))
    if isempty(strip(artifact_ref))
        refs = get(prediction_export, "artifactRefs", Any[])
        isempty(refs) && return nothing
        artifact_ref = String(get(refs[1], "path", ""))
    end
    isempty(strip(artifact_ref)) && return nothing
    artifact_path = local_data_ref_path_for_write(artifact_ref)
    isfile(artifact_path) || return nothing
    refs = get(prediction_export, "artifactRefs", Any[])
    if !isempty(refs) && refs[1] isa AbstractDict
        expected_checksum = lowercase(strip(String(get(refs[1], "checksumSha256", ""))))
        if !isempty(expected_checksum)
            checksum = local_artifact_checksum(artifact_path)
            expected_checksum == checksum || error("drift prediction export artifact checksum mismatch: $(artifact_ref)")
        end
    end
    content = read(artifact_path, String)
    format = String(get(prediction_export, "format", lowercase(splitext(artifact_path)[2][2:end])))
    values = JuliaFlowDataScienceProjectMonitoring.prediction_column_values_from_content(content, format)
    return isempty(values) ? nothing : values
end

function local_csv_drift_metric_result(dataset::AbstractDict, prediction_export::AbstractDict, report::AbstractDict, metric_names::AbstractVector)
    baseline_predictions = prediction_export_artifact_values(prediction_export)
    baseline_predictions === nothing && return nothing
    current_predictions, scoring_mode = local_csv_prediction_values_from_report(dataset, report, length(baseline_predictions))
    current_predictions === nothing && return nothing
    metrics = JuliaFlowDataScienceProjectMonitoring.drift_metric_values_from_predictions(
        metric_names,
        baseline_predictions,
        Float64.(current_predictions),
    )
    metrics === nothing && return nothing
    drift_execution_mode = scoring_mode == "mlj_package_backed_prediction_export" ?
        "mlj_package_backed_prediction_distribution" :
        "local_csv_prediction_distribution"
    evidence = Dict{String,Any}(
        "executionMode" => drift_execution_mode,
        "predictionScoringMode" => scoring_mode,
        "baselinePredictionCount" => length(baseline_predictions),
        "currentPredictionCount" => length(current_predictions),
        "sourcePredictionExportId" => String(get(prediction_export, "predictionExportId", "")),
        "artifactRef" => String(get(prediction_export, "artifactRef", "")),
    )
    model_runtime_evidence = evaluation_model_runtime_evidence(report)
    model_runtime_evidence === nothing || (evidence["modelRuntimeEvidence"] = model_runtime_evidence)
    return Dict{String,Any}(
        "metrics" => metrics,
        "evidence" => evidence,
    )
end

function local_csv_feature_drift_result(dataset::AbstractDict, report::AbstractDict, metric_names::AbstractVector, threshold::Real)
    validation = get(report, "validationEvidence", Dict{String,Any}())
    evidence = get(validation, "evaluationDataEvidence", Dict{String,Any}())
    source_path = resolve_local_data_ref_path(String(get(dataset, "sourceUri", "")))
    source_path === nothing && return nothing
    table = JuliaFlowDataScienceProjectSplits.split_table(source_path)
    train_rows = Int.(get(evidence, "trainingRowIndices", Int[]))
    test_rows = Int.(get(evidence, "testRowIndices", Int[]))
    (isempty(train_rows) || isempty(test_rows)) && return nothing
    maximum([train_rows; test_rows]) <= length(table["rows"]) || return nothing
    numeric_columns = JuliaFlowDataScienceProjectSplits.training_numeric_columns(table, train_rows)
    isempty(numeric_columns) && return nothing
    target_column = String(get(evidence, "targetColumn", ""))
    feature_columns = [String(column) for column in get(evidence, "featureColumns", Any[]) if haskey(numeric_columns, String(column))]
    if isempty(feature_columns)
        feature_columns = JuliaFlowDataScienceProjectStatistics.candidate_numeric_feature_columns(numeric_columns, target_column)
    end
    feature_columns = [column for column in feature_columns if column != target_column && haskey(numeric_columns, column)]
    isempty(feature_columns) && return nothing
    row_count = minimum(length(numeric_columns[column]) for column in feature_columns)
    train_count = length(train_rows)
    current_count = length(test_rows)
    current_count > 0 || return nothing
    baseline_columns = Dict{String,Vector{Float64}}(
        column => numeric_columns[column][train_rows]
        for column in feature_columns
    )
    current_columns = Dict{String,Vector{Float64}}(
        column => numeric_columns[column][test_rows]
        for column in feature_columns
    )
    feature_drift = JuliaFlowDataScienceProjectMonitoring.drift_metric_values_from_feature_columns(metric_names, baseline_columns, current_columns)
    feature_drift === nothing && return nothing
    metrics = Dict{String,Any}("aggregateMetric" => feature_drift["aggregateMetric"])
    status = JuliaFlowDataScienceProjectMonitoring.drift_status(metrics, threshold)
    feature_drift["status"] = status
    feature_drift["evidence"] = Dict{String,Any}(
        "executionMode" => "local_csv_feature_distribution",
        "sourceKind" => "managed_local_csv",
        "sourceRef" => String(get(dataset, "sourceUri", "")),
        "baselineSplit" => "train",
        "currentSplit" => "test",
        "baselineRowCount" => train_count,
        "currentRowCount" => current_count,
        "splitPlanId" => String(get(report, "splitPlanId", String(get(validation, "splitPlanId", "")))),
        "evaluationReportId" => String(get(report, "evaluationReportId", "")),
    )
    return feature_drift
end

function run_drift_report_response!(state::GatewayState, project_id::AbstractString, body::AbstractDict)
    haskey(state.data_science_projects, project_id) || error("data science project not found: $(project_id)")
    ensure_cpu_project_job_allowed(state)
    project = deepcopy(state.data_science_projects[project_id])
    dataset_id = statistical_analysis_dataset(project, body)
    dataset = data_science_project_dataset(project, dataset_id)
    prediction_export = project_prediction_export_for_drift(project, body)
    validation = get(prediction_export, "validationEvidence", Dict{String,Any}())
    Bool(get(validation, "finalEvaluationApproved", false)) || error("drift report prerequisite approved final evaluation required")
    String(get(validation, "datasetId", dataset_id)) == String(dataset_id) || error("drift report dataset must match prediction export")
    report = project_evaluation_report_for_prediction_export(project, Dict{String,Any}("evaluationReportId" => String(get(prediction_export, "evaluationReportId", ""))))
    require_evaluation_consumer_evidence(project, report, "drift report")
    metric_names = drift_metric_names(body)
    threshold = drift_threshold(body)
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    baseline = monitoring_baseline_for_drift!(project, body, dataset_id, prediction_export, metric_names, timestamp)
    drift_result = JuliaFlowDataScienceProjectEvidence.read_result(
        () -> local_csv_drift_metric_result(dataset, prediction_export, report, metric_names), juliaflow_runtime_mode(), "drift report")
    feature_drift = local_csv_feature_drift_result(dataset, report, metric_names, threshold)
    metrics = drift_result === nothing ? JuliaFlowDataScienceProjectMonitoring.drift_metric_values(metric_names) : drift_result["metrics"]
    status = JuliaFlowDataScienceProjectMonitoring.drift_status(metrics, threshold)
    drift_report = JuliaFlowDataScienceProjectMonitoring.drift_report_record(project, baseline, prediction_export, dataset_id, metrics, status, timestamp)
    if drift_result === nothing
        drift_report["validationEvidence"]["driftExecutionMode"] = "deterministic_fallback"
        drift_report["validationEvidence"]["driftWarning"] = "Prediction artifact or local CSV scoring evidence was unavailable; deterministic drift metrics were used."
    else
        drift_report["validationEvidence"]["driftExecutionMode"] = drift_result["evidence"]["executionMode"]
        drift_report["validationEvidence"]["driftDataEvidence"] = drift_result["evidence"]
    end
    if feature_drift !== nothing
        drift_report["featureDrift"] = feature_drift
        drift_report["validationEvidence"]["featureDriftExecutionMode"] = feature_drift["evidence"]["executionMode"]
        drift_report["validationEvidence"]["featureDriftEvidence"] = feature_drift["evidence"]
    end
    report_id = String(drift_report["driftReportId"])
    output_refs = JuliaFlowDataScienceProjectMonitoring.drift_output_refs(project.project_id, report_id, timestamp)
    output_refs = persist_drift_report_artifact!(drift_report, baseline, prediction_export, output_refs)
    resource_evidence = data_science_project_job_resource_evidence(state; execution_mode = "drift_report")
    execution_evidence = data_science_project_execution_evidence!(
        state,
        project,
        "drift_report";
        dataset_id = dataset_id,
        source_record_id = report_id,
        output_refs = output_refs,
        resource_evidence = resource_evidence,
        started_at = timestamp,
        finished_at = timestamp,
        plan = ["validate_monitoring_baseline", "compute_local_drift_metrics", "materialize_drift_report"],
        worker_backed = true,
    )
    drift_report["executionEvidence"] = execution_evidence
    drift_report["validationEvidence"]["executionId"] = execution_evidence["executionId"]
    project.drift_reports = [drift_report, project.drift_reports...]
    record_data_science_project_job!(
        project,
        "drift_report";
        dataset_id = dataset_id,
        source_record_id = report_id,
        output_refs = output_refs,
        resource_evidence = resource_evidence,
        execution_evidence = execution_evidence,
        started_at = timestamp,
        finished_at = timestamp,
    )
    state.data_science_projects[project.project_id] = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    payload = JuliaFlowGatewayRepository.data_science_project_payload(state.data_science_projects[project.project_id])
    return JSON3.write(Dict("status" => "completed", "monitoringBaseline" => baseline, "driftReport" => drift_report, "project" => payload))
end

function cors_origin()
    return get(ENV, "JULIAFLOW_CORS_ALLOW_ORIGIN", get(ENV, "JULIAFLOW_LOCAL_FRONTEND_URL", "http://127.0.0.1:5173"))
end

function cors_allowed_origins()
    configured = strip(cors_origin())
    configured == "*" && return Set(["*"])
    origins = Set{String}()
    for origin in split(configured, ',')
        normalized = strip(String(origin))
        isempty(normalized) || push!(origins, normalized)
    end
    return origins
end

function validate_cors_origin!(request::HTTP.Request)
    origin = request_header(request, "Origin")
    origin === nothing && return nothing
    allowed = cors_allowed_origins()
    if "*" in allowed
        fixture_substitution_allowed(juliaflow_runtime_mode()) || error("CORS origin not allowed: wildcard requires demo/development mode")
        return nothing
    end
    String(origin) in allowed || error("CORS origin not allowed")
    return nothing
end

function base_headers()
    return [
        "Access-Control-Allow-Headers" => "Content-Type, Authorization, X-JuliaFlow-Workspace, X-JuliaFlow-Workspace-Role, X-JuliaFlow-Principal",
        "Access-Control-Allow-Methods" => "GET, POST, PUT, OPTIONS",
        "Access-Control-Max-Age" => "86400",
    ]
end

function apply_cors_headers!(response::HTTP.Response, request::HTTP.Request)
    origin = request_header(request, "Origin")
    origin === nothing && return response
    allowed = cors_allowed_origins()
    if String(origin) in allowed
        HTTP.setheader(response, "Access-Control-Allow-Origin" => String(origin))
        HTTP.setheader(response, "Vary" => "Origin")
    elseif "*" in allowed && fixture_substitution_allowed(juliaflow_runtime_mode())
        HTTP.setheader(response, "Access-Control-Allow-Origin" => "*")
    end
    return response
end

function json_response(status::Integer, body::AbstractString)
    return HTTP.Response(status, ["Content-Type" => "application/json", base_headers()...], body)
end

function text_response(status::Integer, body::AbstractString; content_type::AbstractString = "text/plain; charset=utf-8")
    return HTTP.Response(status, ["Content-Type" => content_type, base_headers()...], body)
end

function empty_response(status::Integer)
    return HTTP.Response(status, base_headers())
end

function error_response(status::Integer, message::AbstractString)
    return json_response(status, JSON3.write(Dict("error" => message)))
end

function classify_gateway_error(err)
    message = sprint(showerror, err)

    if occursin("source evidence unavailable", message)
        return 409, message
    elseif occursin("execution metadata ", message) && occursin(" is server owned", message)
        return 400, message
    elseif occursin("data science project ", message) && (
        occursin(" is server-owned execution evidence; use the project action", message) ||
        occursin("executed training plans are immutable; create a new plan id", message)
    )
        return 400, message
    elseif occursin("split membership ", message)
        return 400, message
    elseif occursin("published dashboard not found", message)
        return 404, message
    elseif occursin("data science project not found", message)
        return 404, message
    elseif occursin("data science project already exists", message)
        return 409, message
    elseif occursin("data science project schemaVersion must be 1.0", message)
        return 400, message
    elseif occursin("data science project dataset", message)
        return 400, message
    elseif occursin("local data import ", message)
        return 400, message
    elseif occursin("managed_local connector", message) || occursin("managed_local sourceUri", message)
        return 400, message
    elseif occursin("local_file connector", message)
        return 400, message
    elseif occursin("DuckDB source import is unavailable", message)
        return 400, message
    elseif occursin("PostgreSQL local source import is unavailable", message)
        return 400, message
    elseif occursin("remote/provider source connectors", message)
        return 400, message
    elseif occursin("PostgreSQL source ", message)
        return 400, message
    elseif occursin("databaseSchema and databaseTable", message)
        return 400, message
    elseif occursin("project child records must be", message) ||
           (startswith(message, "data science project ") && (occursin("invalid contract payload", message) || occursin("projectJobs projectId mismatch", message) || occursin("resourceEvidence required", message)))
        return 400, message
    elseif occursin("project id mismatch", message)
        return 400, message
    elseif occursin("ml experiment ", message) && (
        occursin("project not found", message) ||
        occursin("dataset not registered", message) ||
        occursin("split plan", message) ||
        occursin("validation split required", message) ||
        occursin("test split required", message) ||
        occursin("finalTestPolicy", message) ||
        occursin("final test data cannot be used", message)
    )
        return 400, message
    elseif occursin("validation evidence required", message) && (
        occursin("model registration", message) ||
        occursin("deploy package", message)
    )
        return 409, message
    elseif occursin("final evaluation prerequisite", message)
        return 409, message
    elseif occursin("prediction export prerequisite", message)
        return 409, message
    elseif occursin("drift report prerequisite", message)
        return 409, message
    elseif occursin("transform fit/apply ", message)
        return 400, message
    elseif occursin("statistical analysis ", message)
        return 400, message
    elseif occursin("tuning study ", message)
        return 400, message
    elseif occursin("final evaluation ", message)
        return 400, message
    elseif occursin("prediction export ", message)
        return 400, message
    elseif occursin("drift report ", message)
        return 400, message
    elseif occursin("model lifecycle record not found", message)
        return 409, message
    elseif occursin("model lifecycle ", message)
        return 400, message
    elseif startswith(message, "data science project mutation in progress")
        return 409, message
    elseif startswith(message, "analysis ") || startswith(message, "scoped analysis ")
        return 400, message
    elseif occursin("route not found", message)
        return 404, message
    elseif occursin("Artifact ", message) && occursin(" missing from artifact store", message)
        return 409, message
    elseif occursin("Mirror reference not found in offline/private registry", message)
        return 409, message
    elseif occursin("duplicate ", message)
        return 400, message
    elseif occursin("missing ", message)
        return 400, message
    elseif occursin("reproducibility bundle checksum mismatch", message)
        return 400, message
    elseif occursin("local backup checksum mismatch", message)
        return 400, message
    elseif occursin("local backup artifact checksum mismatch", message)
        return 400, message
    elseif occursin("backup artifact path escapes data estate", message)
        return 400, message
    elseif occursin("unsupported local backup schemaVersion", message)
        return 400, message
    elseif occursin("manifest ", message)
        return 400, message
    elseif occursin("invalid share token", message)
        return 401, message
    elseif occursin("invalid workspace access token", message)
        return 401, message
    elseif occursin("invalid auth token", message)
        return 401, message
    elseif occursin("auth token is required", message)
        return 401, message
    elseif occursin("OIDC bearer token is required", message)
        return 401, message
    elseif occursin("OIDC setting", message)
        return 401, message
    elseif occursin("OIDC token", message)
        return 401, message
    elseif occursin("OIDC", message)
        return 401, message
    elseif occursin("permission denied", message)
        return 403, message
    elseif occursin("CORS origin not allowed", message)
        return 403, message
    elseif occursin("not active in directory", message)
        return 400, message
    elseif occursin("unsupported workspace role", message)
        return 403, message
    elseif occursin("Extension not validated for current checkpoint", message)
        return 409, message
    elseif occursin("Artifact hash for", message)
        return 409, message
    elseif occursin("Artifact hash mismatch", message)
        return 409, message
    elseif occursin("Compatibility sandbox command must be bounded", message)
        return 409, message
    elseif occursin("Extension must provide compatibility sandbox command", message)
        return 409, message
    elseif occursin("Mirror reference must use", message)
        return 409, message
    elseif occursin("Extension must provide at least one artifact hash", message)
        return 409, message
    end

    return 500, message
end

function append_audit_event!(
    state::GatewayState,
    request::HTTP.Request,
    action::AbstractString;
    target_type::AbstractString,
    target_id::AbstractString,
    details = Dict{String,Any}(),
)
    payload = Dict{String,Any}(
        "action" => String(action),
        "targetType" => String(target_type),
        "targetId" => String(target_id),
        "recordedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        "authContext" => auth_context_payload(request; state = state),
        "details" => Dict{String,Any}(String(key) => value for (key, value) in pairs(details)),
    )
    return JuliaFlowGatewayRepository.append_event!(
        state.repository,
        "audit.action";
        aggregate_type = String(target_type),
        aggregate_id = String(target_id),
        payload = payload,
        producer = "api-gateway",
    )
end

function parse_auth_policy_payload(body::AbstractDict)
    role_bindings = JuliaFlowGatewayRepository.GatewayRoleBinding[]
    for item in get(body, "roleBindings", Any[])
        role = lowercase(strip(String(item["role"])))
        haskey(GATEWAY_ROLE_PERMISSIONS, role) || error("unsupported workspace role: $(role)")
        push!(
            role_bindings,
            JuliaFlowGatewayRepository.GatewayRoleBinding(
                principal_id = String(item["principalId"]),
                workspace_id = String(get(item, "workspaceId", "local-dev")),
                role = role,
            ),
        )
    end

    resource_policies = JuliaFlowGatewayRepository.GatewayResourcePolicy[]
    for item in get(body, "resourcePolicies", Any[])
        permissions_by_role = Dict{String,Vector{String}}()
        for (role, permissions) in pairs(get(item, "permissionsByRole", Dict{String,Any}()))
            role_key = lowercase(strip(String(role)))
            haskey(GATEWAY_ROLE_PERMISSIONS, role_key) || error("unsupported workspace role: $(role_key)")
            normalized_permissions = [String(permission) for permission in permissions]
            all(permission -> permission in GATEWAY_ROLE_PERMISSIONS[role_key], normalized_permissions) ||
                error("resource policy includes permission outside role scope")
            permissions_by_role[role_key] = normalized_permissions
        end
        push!(
            resource_policies,
            JuliaFlowGatewayRepository.GatewayResourcePolicy(
                resource_type = String(item["resourceType"]),
                resource_id = String(item["resourceId"]),
                workspace_id = String(get(item, "workspaceId", "local-dev")),
                permissions_by_role = permissions_by_role,
            ),
        )
    end

    return JuliaFlowGatewayRepository.GatewayAuthPolicy(
        role_bindings = role_bindings,
        resource_policies = resource_policies,
    )
end

function nonempty_string(value, field_name::AbstractString)
    text = strip(String(value))
    isempty(text) && error("missing $(field_name)")
    return text
end

function parse_auth_directory_payload(body::AbstractDict)
    timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    seen_users = Set{String}()
    users = JuliaFlowGatewayRepository.GatewayUserRecord[]
    for item in get(body, "users", Any[])
        principal_id = nonempty_string(item["principalId"], "principalId")
        principal_id in seen_users && error("duplicate principalId: $(principal_id)")
        push!(seen_users, principal_id)
        created_at = String(get(item, "createdAt", timestamp))
        push!(
            users,
            JuliaFlowGatewayRepository.GatewayUserRecord(
                principal_id = principal_id,
                display_name = nonempty_string(get(item, "displayName", principal_id), "displayName"),
                email = haskey(item, "email") && item["email"] !== nothing && !isempty(strip(String(item["email"]))) ? strip(String(item["email"])) : nothing,
                active = Bool(get(item, "active", true)),
                created_at = created_at,
                updated_at = String(get(item, "updatedAt", timestamp)),
            ),
        )
    end

    seen_workspaces = Set{String}()
    workspaces = JuliaFlowGatewayRepository.GatewayWorkspaceRecord[]
    for item in get(body, "workspaces", Any[])
        workspace_id = nonempty_string(item["workspaceId"], "workspaceId")
        workspace_id in seen_workspaces && error("duplicate workspaceId: $(workspace_id)")
        push!(seen_workspaces, workspace_id)
        created_at = String(get(item, "createdAt", timestamp))
        push!(
            workspaces,
            JuliaFlowGatewayRepository.GatewayWorkspaceRecord(
                workspace_id = workspace_id,
                name = nonempty_string(get(item, "name", workspace_id), "workspace name"),
                active = Bool(get(item, "active", true)),
                created_at = created_at,
                updated_at = String(get(item, "updatedAt", timestamp)),
            ),
        )
    end

    return JuliaFlowGatewayRepository.GatewayAuthDirectory(
        users = users,
        workspaces = workspaces,
        updated_at = String(get(body, "updatedAt", timestamp)),
    )
end

function directory_has_records(directory::JuliaFlowGatewayRepository.GatewayAuthDirectory)
    return !isempty(directory.users) || !isempty(directory.workspaces)
end

function validate_policy_directory_references!(
    policy::JuliaFlowGatewayRepository.GatewayAuthPolicy,
    directory::JuliaFlowGatewayRepository.GatewayAuthDirectory,
)
    directory_has_records(directory) || return policy
    active_users = Set(user.principal_id for user in directory.users if user.active)
    active_workspaces = Set(workspace.workspace_id for workspace in directory.workspaces if workspace.active)
    for binding in policy.role_bindings
        binding.principal_id in active_users || error("role binding principal not active in directory: $(binding.principal_id)")
        binding.workspace_id in active_workspaces || error("role binding workspace not active in directory: $(binding.workspace_id)")
    end
    for resource_policy in policy.resource_policies
        resource_policy.workspace_id == "*" && continue
        resource_policy.workspace_id in active_workspaces ||
            error("resource policy workspace not active in directory: $(resource_policy.workspace_id)")
    end
    return policy
end

function validate_directory_retains_admin!(
    directory::JuliaFlowGatewayRepository.GatewayAuthDirectory,
    context::Dict{String,Any},
)
    principal_id = String(context["principalId"])
    workspace_id = String(context["workspaceId"])
    if !isempty(directory.users)
        any(user.principal_id == principal_id && user.active for user in directory.users) ||
            error("admin principal not active in directory: $(principal_id)")
    end
    if !isempty(directory.workspaces)
        any(workspace.workspace_id == workspace_id && workspace.active for workspace in directory.workspaces) ||
            error("admin workspace not active in directory: $(workspace_id)")
    end
    return directory
end

function auth_policy_response(state::GatewayState)
    return JSON3.write(JuliaFlowGatewayRepository.auth_policy_payload(JuliaFlowGatewayRepository.load_auth_policy(state.repository)))
end

function save_auth_policy_response!(state::GatewayState, body::AbstractDict)
    policy = parse_auth_policy_payload(body)
    validate_policy_directory_references!(policy, JuliaFlowGatewayRepository.load_auth_directory(state.repository))
    saved = JuliaFlowGatewayRepository.save_auth_policy!(state.repository, policy)
    return JSON3.write(JuliaFlowGatewayRepository.auth_policy_payload(saved))
end

function auth_directory_response(state::GatewayState)
    directory = JuliaFlowGatewayRepository.load_auth_directory(state.repository)
    return JSON3.write(JuliaFlowGatewayRepository.auth_directory_payload(directory))
end

function save_auth_directory_response!(state::GatewayState, body::AbstractDict, context::Dict{String,Any})
    directory = parse_auth_directory_payload(body)
    validate_directory_retains_admin!(directory, context)
    saved = JuliaFlowGatewayRepository.save_auth_directory!(state.repository, directory)
    return JSON3.write(JuliaFlowGatewayRepository.auth_directory_payload(saved))
end

function redacted_value(value)
    if value isa AbstractDict
        redacted = Dict{String,Any}()
        for (key, item) in pairs(value)
            key_string = String(key)
            lowered = lowercase(key_string)
            if occursin("token", lowered) || occursin("authorization", lowered) || occursin("secret", lowered)
                redacted[key_string] = "[redacted]"
            else
                redacted[key_string] = redacted_value(item)
            end
        end
        return redacted
    elseif value isa AbstractVector
        return [redacted_value(item) for item in value]
    end
    return value
end

function audit_action_query_response(state::GatewayState, query_params)
    limit = haskey(query_params, "limit") ? min(max(parse(Int, String(query_params["limit"])), 1), 200) : 50
    action_filter = haskey(query_params, "action") ? String(query_params["action"]) : nothing
    target_type_filter = haskey(query_params, "targetType") ? String(query_params["targetType"]) : nothing
    target_id_filter = haskey(query_params, "targetId") ? String(query_params["targetId"]) : nothing
    principal_filter = haskey(query_params, "principalId") ? String(query_params["principalId"]) : nothing

    matches = Dict{String,Any}[]
    for event in reverse(JuliaFlowGatewayRepository.load_events(state.repository))
        event.event_type == "audit.action" || continue
        payload = redacted_value(event.payload)
        action_filter === nothing || String(get(payload, "action", "")) == action_filter || continue
        target_type_filter === nothing || String(get(payload, "targetType", "")) == target_type_filter || continue
        target_id_filter === nothing || String(get(payload, "targetId", "")) == target_id_filter || continue
        auth_context = get(payload, "authContext", Dict{String,Any}())
        principal_filter === nothing || String(get(auth_context, "principalId", "")) == principal_filter || continue
        payload["eventId"] = event.event_id
        payload["sequence"] = event.sequence
        payload["occurredAt"] = event.occurred_at
        push!(matches, payload)
        length(matches) >= limit && break
    end

    return JSON3.write(Dict("events" => matches, "count" => length(matches), "limit" => limit))
end

function parse_request_body(request::HTTP.Request)
    isempty(request.body) && return Dict{String,Any}()
    return copy(JSON3.read(String(request.body), Dict{String,Any}))
end

function jsonrpc_success(id, result)
    return JSON3.write(Dict("jsonrpc" => "2.0", "id" => id, "result" => result))
end

function jsonrpc_error(id, code::Integer, message::AbstractString)
    return JSON3.write(
        Dict(
            "jsonrpc" => "2.0",
            "id" => id,
            "error" => Dict("code" => code, "message" => String(message)),
        ),
    )
end

function jsonrpc_notification(method::AbstractString, params)
    return JSON3.write(Dict("jsonrpc" => "2.0", "method" => String(method), "params" => params))
end

function workflow_state_changed_payload(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    workflow = state.workflows[workflow_id]
    payload = Dict(
        "workflowId" => workflow.id,
        "name" => workflow.name,
        "version" => workflow.version,
        "nodeCount" => length(workflow.nodes),
        "connectionCount" => length(workflow.connections),
        "latestCheckpoint" => latest_checkpoint_tag(state),
        "executionCount" => count(execution -> execution.workflow_id == workflow_id, state.executions),
        "dashboardCount" => length(workflow.dashboards),
        "runMode" => String(workflow.runtime.run_mode),
    )
    workflow.graph === nothing || (payload["graphRevision"] = workflow.graph.revision)
    return payload
end

function repository_save_changed_payload(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    workflow = state.workflows[workflow_id]
    payload = Dict{String,Any}(
        "workflowId" => workflow.id,
        "workflowVersion" => workflow.version,
        "savedAt" => string(now(UTC)),
    )
    workflow.graph === nothing || (payload["graphRevision"] = workflow.graph.revision)
    return payload
end

function workflow_dashboard_ids(state::GatewayState, workflow_id::AbstractString)
    haskey(state.workflows, workflow_id) || return String[]
    return [dashboard.id for dashboard in state.workflows[workflow_id].dashboards]
end

function broadcast_workflow_save!(state::GatewayState, workflow_id::AbstractString)
    notifications = String[
        jsonrpc_notification("repository.save.changed", repository_save_changed_payload(state, workflow_id)),
        jsonrpc_notification("workflow.state.changed", workflow_state_changed_payload(state, workflow_id)),
    ]
    broadcast_canvas_notifications!(state, workflow_id, notifications)
    for dashboard_id in workflow_dashboard_ids(state, workflow_id)
        dashboard_notifications = String[
            jsonrpc_notification(
                "dashboard.outlet.updated",
                dashboard_outlet_updated_payload(state, dashboard_id, String[]),
            ),
        ]
        broadcast_dashboard_notifications!(state, dashboard_id, dashboard_notifications)
    end
    return nothing
end

function broadcast_execution_update!(state::GatewayState, workflow_id::AbstractString, execution::GatewayExecution)
    notifications = String[
        jsonrpc_notification("workflow.state.changed", workflow_state_changed_payload(state, workflow_id)),
        jsonrpc_notification("execution.state.changed", execution_state_changed_payload(execution)),
    ]
    for payload in node_state_changed_payloads(state, workflow_id; execution = execution)
        push!(notifications, jsonrpc_notification("node.state.changed", payload))
    end
    broadcast_canvas_notifications!(state, workflow_id, notifications)
    for dashboard_id in workflow_dashboard_ids(state, workflow_id)
        dashboard_notifications = String[
            jsonrpc_notification(
                "dashboard.outlet.updated",
                dashboard_outlet_updated_payload(state, dashboard_id, String[]),
            ),
        ]
        broadcast_dashboard_notifications!(state, dashboard_id, dashboard_notifications)
    end
    return nothing
end

function streaming_checkpoint_completed_payload(state::GatewayState, workflow_id::AbstractString, execution::GatewayExecution)
    offsets = get(
        execution.metadata,
        "stream_checkpoint_offsets",
        Dict(
            "topic" => get(execution.metadata, "stream_topic", "unknown"),
            "consumerGroup" => get(execution.metadata, "stream_consumer_group", "unknown"),
        ),
    )
    offsets = Dict{String,Any}(String(key) => value for (key, value) in pairs(offsets))
    offsets["lastProcessedAt"] = execution.updated_at
    return Dict(
        "workflowId" => String(workflow_id),
        "checkpointId" => String(get(execution.metadata, "stream_last_checkpoint_id", "stream-" * execution.execution_id)),
        "offsets" => offsets,
        "watermark" => get(execution.metadata, "stream_watermark", nothing),
        "consumerLag" => get(execution.metadata, "stream_consumer_lag", 0),
        "stateVersion" => length(execution.status_history),
    )
end

function broadcast_stream_checkpoint!(state::GatewayState, workflow_id::AbstractString, execution::GatewayExecution)
    notifications = String[
        jsonrpc_notification(
            "streaming.checkpoint.completed",
            streaming_checkpoint_completed_payload(state, workflow_id, execution),
        ),
    ]
    broadcast_canvas_notifications!(state, workflow_id, notifications)
    return nothing
end

function broadcast_stream_checkpoint_event!(state::GatewayState, payload::Dict{String,Any})
    workflow_id = String(payload["workflowId"])
    notifications = String[
        jsonrpc_notification("streaming.checkpoint.completed", payload),
    ]
    broadcast_canvas_notifications!(state, workflow_id, notifications)
    return nothing
end

function broadcast_dashboard_published!(state::GatewayState, dashboard::JuliaFlowGatewayRepository.PublishedDashboardRecord)
    notifications = String[
        jsonrpc_notification("dashboard.published", JuliaFlowGatewayRepository.published_dashboard_payload(dashboard)),
        jsonrpc_notification(
            "dashboard.outlet.updated",
            dashboard_outlet_updated_payload(state, dashboard.dashboard_id, String[]),
        ),
    ]
    broadcast_dashboard_notifications!(state, dashboard.dashboard_id, notifications)
    return nothing
end

function upsert_execution!(state::GatewayState, execution::GatewayExecution)
    for (index, current) in pairs(state.executions)
        if current.execution_id == execution.execution_id
            state.executions[index] = execution
            sync_worker_service!(state.worker_service, state.executions)
            return execution
        end
    end
    push!(state.executions, execution)
    sync_worker_service!(state.worker_service, state.executions)
    return execution
end

function process_gateway_event!(state::GatewayState, event::JuliaFlowGatewayRepository.GatewayEvent)
    event.event_id in state.processed_event_ids && return false
    push!(state.processed_event_ids, event.event_id)

    if event.event_type == "execution.changed"
        execution = JuliaFlowGatewayRepository.gateway_execution(event.payload)
        upsert_execution!(state, execution)
        broadcast_execution_update!(state, execution.workflow_id, execution)
    elseif event.event_type == "repository.save.changed"
        workflow_id = String(event.payload["workflowId"])
        workflows = load_workflows(state.repository)
        haskey(workflows, workflow_id) && (state.workflows[workflow_id] = workflows[workflow_id])
        broadcast_workflow_save!(state, workflow_id)
    elseif event.event_type == "hub.extension.changed"
        extension = JuliaFlowGatewayRepository.gateway_hub_extension(event.payload)
        state.hub_extensions[extension.extension_id] = extension
    elseif event.event_type == "dashboard.published"
        dashboard = JuliaFlowGatewayRepository.gateway_published_dashboard(event.payload)
        state.published_dashboards[dashboard.dashboard_id] = dashboard
        broadcast_dashboard_published!(state, dashboard)
    elseif event.event_type == "stream.checkpoint.completed"
        broadcast_stream_checkpoint_event!(state, event.payload)
    end
    return true
end

function consume_gateway_events!(state::GatewayState; consumer_id::AbstractString = gateway_event_consumer_id())
    cursor = load_consumer_cursor(state.repository, consumer_id)
    events = JuliaFlowGatewayRepository.list_events_after(state.repository, cursor)
    processed = JuliaFlowGatewayRepository.GatewayEvent[]
    for event in events
        process_gateway_event!(state, event) && push!(processed, event)
        save_consumer_cursor!(state.repository, consumer_id, event.sequence)
    end
    return processed
end

function activate_stream_execution!(state::GatewayState, execution::GatewayExecution)
    updated_execution = JuliaFlowWorkerService.activate_stream_execution!(
        state.worker_service,
        state.workflows,
        state.executions,
        execution.execution_id;
        execution_record = execution_record,
        transition_execution_record = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
        materialize_execution = materialize_execution,
    )
    save_execution!(state.repository, updated_execution; producer = "api-gateway")
    event_backbone_enabled() || broadcast_execution_update!(state, updated_execution.workflow_id, updated_execution)
    return updated_execution
end

function set_stream_lifecycle_response!(
    state::GatewayState,
    workflow_id::AbstractString,
    lifecycle_status::AbstractString;
    message::AbstractString,
)
    execution = JuliaFlowWorkerService.set_stream_lifecycle!(
        state.worker_service,
        state.executions,
        workflow_id;
        lifecycle_status = lifecycle_status,
        message = message,
        execution_record = execution_record,
        append_execution_event = JuliaFlowGatewayRepository.JuliaFlowExecutionService.append_execution_event,
        materialize_execution = materialize_execution,
    )
    save_execution!(state.repository, execution; producer = "api-gateway")
    event_backbone_enabled() || broadcast_execution_update!(state, execution.workflow_id, execution)
    return execution
end

function stop_stream_execution_response!(state::GatewayState, workflow_id::AbstractString)
    execution = JuliaFlowWorkerService.stop_stream_execution!(
        state.worker_service,
        state.executions,
        workflow_id;
        execution_record = execution_record,
        transition_execution_record = JuliaFlowGatewayRepository.JuliaFlowExecutionService.transition_execution_record,
        materialize_execution = materialize_execution,
    )
    save_execution!(state.repository, execution; producer = "api-gateway")
    checkpoint_payload = streaming_checkpoint_completed_payload(state, execution.workflow_id, execution)
    append_event!(
        state.repository,
        "stream.checkpoint.completed";
        aggregate_type = "workflow",
        aggregate_id = execution.workflow_id,
        payload = checkpoint_payload,
        producer = "api-gateway",
    )
    if !event_backbone_enabled()
        broadcast_execution_update!(state, execution.workflow_id, execution)
        broadcast_stream_checkpoint!(state, execution.workflow_id, execution)
    end
    return execution
end

function latest_execution_for_workflow(state::GatewayState, workflow_id::AbstractString)
    for execution in Iterators.reverse(state.executions)
        execution.workflow_id == workflow_id && return execution
    end
    return nothing
end

function active_node_ids(execution::GatewayExecution)
    branch_state = get(execution.metadata, "control_flow_branch_state", nothing)
    if branch_state isa AbstractDict
        active_nodes = get(branch_state, "active_node_ids", Any[])
        !isempty(active_nodes) && return Set(String(node_id) for node_id in active_nodes)
    end

    executor_state = get(execution.metadata, "executor_state", nothing)
    if executor_state isa AbstractDict
        active_nodes = get(executor_state, "active_node_ids", Any[])
        !isempty(active_nodes) && return Set(String(node_id) for node_id in active_nodes)
    end

    isempty(execution.stages) && return Set{String}()

    if execution.status == "accepted" || execution.status == "queued"
        return Set(String(node_id) for node_id in execution.stages[1])
    elseif execution.status == "running"
        return Set(String(node_id) for node_id in execution.stages[1])
    elseif execution.status == "completed"
        return Set{String}()
    elseif execution.status == "failed"
        return Set{String}()
    end

    return Set{String}()
end

function node_runtime_status(node_id::AbstractString, execution::Union{Nothing,GatewayExecution})
    execution === nothing && return "configured"

    branch_state = get(execution.metadata, "control_flow_branch_state", nothing)
    if branch_state isa AbstractDict
        failed_node_id = String(get(branch_state, "failed_node_id", ""))
        completed_nodes = Set(String(item) for item in get(branch_state, "completed_node_ids", Any[]))
        active_nodes = Set(String(item) for item in get(branch_state, "active_node_ids", Any[]))
        failed_node_id == String(node_id) && return "error"
        String(node_id) in completed_nodes && return "executed"
        String(node_id) in active_nodes && return "running"
    end

    recovery = get(execution.metadata, "control_flow_recovery", nothing)
    if recovery isa AbstractDict && String(get(recovery, "failed_node_id", "")) == String(node_id)
        return "error"
    end

    executor_state = get(execution.metadata, "executor_state", nothing)
    if executor_state isa AbstractDict
        failed_node_id = String(get(executor_state, "failed_node_id", ""))
        failed_node_id == String(node_id) && return "error"
        for result in get(executor_state, "node_results", Any[])
            String(get(result, "node_id", "")) == String(node_id) || continue
            String(get(result, "status", "")) in ("error", "failed") && return "error"
            String(get(result, "status", "")) == "executed" && return "executed"
        end
        completed_nodes = Set(String(item) for item in get(executor_state, "completed_node_ids", Any[]))
        active_nodes = Set(String(item) for item in get(executor_state, "active_node_ids", Any[]))
        String(node_id) in completed_nodes && return "executed"
        String(node_id) in active_nodes && return "running"
    end

    if execution.status == "completed"
        return "executed"
    elseif execution.status == "failed"
        return "error"
    elseif get(execution.metadata, "stream_lifecycle_status", nothing) == "active"
        return "streaming_active"
    elseif node_id in active_node_ids(execution)
        return "running"
    end

    return "configured"
end

function node_state_changed_payloads(
    state::GatewayState,
    workflow_id::AbstractString;
    execution::Union{Nothing,GatewayExecution} = latest_execution_for_workflow(state, workflow_id),
)
    haskey(state.workflows, workflow_id) || error("workflow not found: $(workflow_id)")
    workflow = state.workflows[workflow_id]
    return [
        Dict(
            "workflowId" => workflow.id,
            "nodeId" => node.id,
            "nodeType" => node.type,
            "status" => node_runtime_status(node.id, execution),
            "executionHint" => String(node.execution_hint),
        ) for node in workflow.nodes
    ]
end

function dashboard_outlet_updated_payload(state::GatewayState, dashboard_id::AbstractString, outlet_ids)
    return Dict(
        "dashboardId" => String(dashboard_id),
        "outletIds" => [String(outlet_id) for outlet_id in outlet_ids],
        "latestCheckpoint" => latest_checkpoint_tag(state),
        "updatedAt" => string(now(UTC)),
    )
end

function execution_state_changed_payload(execution::GatewayExecution)
    return execution_payload(execution)
end

function register_canvas_subscription!(state::GatewayState, subscription_id::AbstractString, workflow_id::AbstractString, ws)
    state.canvas_subscriptions[String(subscription_id)] = CanvasSubscription(
        subscription_id = String(subscription_id),
        workflow_id = String(workflow_id),
        socket = ws,
    )
    return subscription_id
end

function register_dashboard_subscription!(state::GatewayState, subscription_id::AbstractString, dashboard_id::AbstractString, outlet_ids, ws)
    state.dashboard_subscriptions[String(subscription_id)] = DashboardSubscription(
        subscription_id = String(subscription_id),
        dashboard_id = String(dashboard_id),
        outlet_ids = [String(outlet_id) for outlet_id in outlet_ids],
        socket = ws,
    )
    return subscription_id
end

function drop_socket_subscriptions!(state::GatewayState, ws)
    filter!(entry -> last(entry).socket !== ws, state.canvas_subscriptions)
    filter!(entry -> last(entry).socket !== ws, state.dashboard_subscriptions)
    return nothing
end

function send_notification_safely!(socket, notification::AbstractString)
    try
        HTTP.WebSockets.send(socket, notification)
        return true
    catch
        return false
    end
end

function broadcast_canvas_notifications!(state::GatewayState, workflow_id::AbstractString, notifications::Vector{String})
    stale_ids = String[]
    for (subscription_id, subscription) in state.canvas_subscriptions
        subscription.workflow_id == workflow_id || continue
        delivered = true
        for notification in notifications
            delivered = send_notification_safely!(subscription.socket, notification) && delivered
        end
        delivered || push!(stale_ids, subscription_id)
    end
    for subscription_id in stale_ids
        delete!(state.canvas_subscriptions, subscription_id)
    end
    return nothing
end

function broadcast_dashboard_notifications!(state::GatewayState, dashboard_id::AbstractString, notifications::Vector{String})
    stale_ids = String[]
    for (subscription_id, subscription) in state.dashboard_subscriptions
        subscription.dashboard_id == dashboard_id || continue
        delivered = true
        for notification in notifications
            delivered = send_notification_safely!(subscription.socket, notification) && delivered
        end
        delivered || push!(stale_ids, subscription_id)
    end
    for subscription_id in stale_ids
        delete!(state.dashboard_subscriptions, subscription_id)
    end
    return nothing
end

function realtime_method_result!(state::GatewayState, method::AbstractString, params::Dict{String,Any}, ws = nothing)
    if method == "canvas.subscribe"
        haskey(params, "workflowId") || error("missing workflowId")
        workflow_id = String(params["workflowId"])
        subscription_id = "canvas-" * string(uuid4())
        ws === nothing || register_canvas_subscription!(state, subscription_id, workflow_id, ws)
        notifications = String[
            jsonrpc_notification(
                "workflow.state.changed",
                merge(Dict("subscriptionId" => subscription_id), workflow_state_changed_payload(state, workflow_id)),
            ),
        ]
        for payload in node_state_changed_payloads(state, workflow_id)
            push!(
                notifications,
                jsonrpc_notification(
                    "node.state.changed",
                    merge(Dict("subscriptionId" => subscription_id), payload),
                ),
            )
        end
        latest_execution = latest_execution_for_workflow(state, workflow_id)
        if latest_execution !== nothing
            push!(
                notifications,
                jsonrpc_notification(
                    "execution.state.changed",
                    merge(Dict("subscriptionId" => subscription_id), execution_state_changed_payload(latest_execution)),
                ),
            )
        end
        return Dict("subscriptionId" => subscription_id), notifications
    elseif method == "dashboard.subscribe"
        haskey(params, "dashboardId") || error("missing dashboardId")
        dashboard_id = String(params["dashboardId"])
        outlet_ids = get(params, "outletIds", Any[])
        subscription_id = "dashboard-" * string(uuid4())
        ws === nothing || register_dashboard_subscription!(state, subscription_id, dashboard_id, outlet_ids, ws)
        notifications = String[
            jsonrpc_notification(
                "dashboard.outlet.updated",
                merge(
                    Dict("subscriptionId" => subscription_id),
                    dashboard_outlet_updated_payload(state, dashboard_id, outlet_ids),
                ),
            ),
        ]
        return Dict("subscriptionId" => subscription_id), notifications
    elseif method == "workflow.execute"
        haskey(params, "workflowId") || error("missing workflowId")
        workflow_id = String(params["workflowId"])
        flow_variable_values = haskey(params, "flowVariables") ? normalized_string_dict(params["flowVariables"]) : Dict{String,Any}()
        execution_mode_override = haskey(params, "executionMode") ? String(params["executionMode"]) : nothing
        execution = JSON3.read(
            execution_accept_response(
                state,
                workflow_id;
                flow_variable_values = flow_variable_values,
                execution_mode_override = execution_mode_override,
            ),
            Dict{String,Any},
        )
        return Dict("jobId" => String(execution["executionId"]), "status" => String(execution["status"])), String[]
    elseif method == "workflow.pause"
        haskey(params, "workflowId") || error("missing workflowId")
        workflow_id = String(params["workflowId"])
        execution = set_stream_lifecycle_response!(
            state,
            workflow_id,
            "paused";
            message = "Streaming execution paused",
        )
        return Dict("jobId" => execution.execution_id, "status" => "paused"), String[]
    elseif method == "workflow.resume"
        haskey(params, "workflowId") || error("missing workflowId")
        workflow_id = String(params["workflowId"])
        execution = set_stream_lifecycle_response!(
            state,
            workflow_id,
            "active";
            message = "Streaming execution resumed",
        )
        return Dict("jobId" => execution.execution_id, "status" => "active"), String[]
    elseif method == "workflow.stop"
        haskey(params, "workflowId") || error("missing workflowId")
        workflow_id = String(params["workflowId"])
        execution = stop_stream_execution_response!(state, workflow_id)
        return Dict("jobId" => execution.execution_id, "status" => "stopped"), String[]
    end

    error("method not found: $(method)")
end

function handle_realtime_request!(state::GatewayState, raw_message, ws = nothing; auth_request::HTTP.Request = HTTP.Request("GET", "/api/v1/realtime"))
    request_id = nothing
    try
        request = copy(JSON3.read(String(raw_message), Dict{String,Any}))
        version = get(request, "jsonrpc", nothing)
        version == "2.0" || return jsonrpc_error(get(request, "id", nothing), -32600, "invalid request"), String[]
        haskey(request, "method") || error("missing method")
        method = String(request["method"])
        params = haskey(request, "params") ? Dict{String,Any}(String(key) => value for (key, value) in pairs(request["params"])) : Dict{String,Any}()
        request_id = get(request, "id", nothing)
        validate_cors_origin!(auth_request)
        is_dashboard = method == "dashboard.subscribe"
        is_mutation = method in ("workflow.execute", "workflow.pause", "workflow.resume", "workflow.stop")
        permission = is_dashboard ? "dashboard:read" : is_mutation ? "workflow:execute" : "workflow:read"
        resource_id = get(params, is_dashboard ? "dashboardId" : "workflowId", nothing)
        resource_type = resource_id === nothing ? nothing : is_dashboard ? "dashboard" : "workflow"
        require_permission!(state, auth_request, permission; resource_type, resource_id = resource_id === nothing ? nothing : String(resource_id))
        result, notifications = realtime_method_result!(state, method, params, ws)
        return jsonrpc_success(request_id, result), notifications
    catch err
        message = sprint(showerror, err)
        if startswith(message, "method not found")
            return jsonrpc_error(request_id, -32601, message), String[]
        elseif startswith(message, "missing ")
            return jsonrpc_error(request_id, -32602, message), String[]
        end
        return jsonrpc_error(request_id, -32000, message), String[]
    end
end

function handle_realtime_socket!(state::GatewayState, ws, auth_request::HTTP.Request)
    try
        for message in ws
            response, notifications = handle_realtime_request!(state, message, ws; auth_request = auth_request)
            HTTP.WebSockets.send(ws, response)
            for notification in notifications
                HTTP.WebSockets.send(ws, notification)
            end
        end
    finally
        drop_socket_subscriptions!(state, ws)
    end
    return nothing
end

function start_gateway_sync_task!(state::GatewayState)
    return nothing
end

function start_gateway_event_consumer_task!(state::GatewayState)
    event_backbone_enabled() || return nothing
    poll_ms = event_consumer_poll_ms()
    poll_ms > 0 || return nothing

    @async begin
        while true
            try
                consume_gateway_events!(state)
            catch
            end
            sleep(poll_ms / 1000)
        end
    end
    return nothing
end

function realtime_auth_request(request::HTTP.Request)
    protocols = strip.(split(something(request_header(request, "Sec-WebSocket-Protocol"), ""), ','))
    credentials = filter(protocol -> startswith(protocol, "juliaflow.bearer."), protocols)
    isempty(credentials) && return HTTP.Request(String(request.method), String(request.target), copy(request.headers))
    length(credentials) == 1 || error("invalid auth token")
    encoded = String(only(credentials))[18:end]
    (0 < ncodeunits(encoded) <= 16384 && occursin(r"^[A-Za-z0-9_-]+$", encoded)) || error("invalid auth token")
    token = try
        base64url_decode_string(encoded)
    catch
        error("invalid auth token")
    end
    (isempty(strip(token)) || occursin('\r', token) || occursin('\n', token)) && error("invalid auth token")
    bearer = bearer_token_from_request(request)
    (bearer === nothing || bearer == token) || error("invalid auth token")
    headers = filter(header -> !(lowercase(String(first(header))) in ("authorization", "sec-websocket-protocol")), request.headers)
    push!(headers, "Authorization" => "Bearer $(token)")
    return HTTP.Request(String(request.method), String(request.target), headers)
end

function gateway_stream_handler(state::GatewayState)
    rest_handler = HTTP.Handlers.streamhandler(request -> route_request(state, request))

    return function(http::HTTP.Streams.Stream)
        request = http.message
        path = HTTP.URI(String(request.target)).path
        if path == "/api/v1/realtime" && HTTP.WebSockets.isupgrade(request)
            auth_request = request
            try
                validate_cors_origin!(request)
                auth_request = realtime_auth_request(request)
                require_permission!(state, auth_request, "workflow:read")
            catch err
                status, message = classify_gateway_error(err)
                response = apply_cors_headers!(error_response(status, message), request)
                filter!(header -> !(lowercase(String(first(header))) in ("authorization", "sec-websocket-protocol")), request.headers)
                HTTP.setstatus(http, response.status)
                for header in response.headers
                    HTTP.setheader(http, header)
                end
                # HTTP.jl closes upgrade-request connections after writing the response.
                # Tell clients not to reuse that socket after a rejected handshake.
                HTTP.setheader(http, "Connection" => "close")
                HTTP.startwrite(http)
                write(http, response.body)
                return nothing
            end
            protocols = strip.(split(something(request_header(request, "Sec-WebSocket-Protocol"), ""), ','))
            "juliaflow" in protocols && HTTP.setheader(http, "Sec-WebSocket-Protocol" => "juliaflow")
            # HTTP.jl keeps/logs the handshake request on protocol errors: remove credentials first.
            filter!(header -> !(lowercase(String(first(header))) in ("authorization", "sec-websocket-protocol")), request.headers)
            return HTTP.WebSockets.upgrade(http) do ws
                handle_realtime_socket!(state, ws, auth_request)
            end
        end
        return rest_handler(http)
    end
end

function route_request(state::GatewayState, request::HTTP.Request)
    started_at = now(UTC)
    started_ns = time_ns()
    method = String(request.method)
    uri = HTTP.URI(String(request.target))
    span = Dict{String,Any}(
        "trace_id" => trace_id_from_request(request),
        "span_id" => observability_span_id(),
        "name" => "HTTP $(method) $(uri.path)",
        "kind" => "server",
        "method" => method,
        "path" => uri.path,
        "started_at" => Dates.format(started_at, dateformat"yyyy-mm-ddTHH:MM:SS.sss") * "Z",
    )
    status = 500
    try
        response = route_request_inner(state, request)
        apply_cors_headers!(response, request)
        status = Int(response.status)
        return response
    finally
        span["status"] = status
        span["duration_ms"] = round((time_ns() - started_ns) / 1_000_000; digits = 3)
        record_observability_span!(state, span)
    end
end

function analysis_schema(project, dataset_id)
    index = findfirst(s -> get(s, "datasetId", "") == dataset_id, project.schema_contracts)
    index === nothing && error("analysis schema unavailable")
    return project.schema_contracts[index]
end

function analysis_action_response!(state, project_id, action, body)
    haskey(state.data_science_projects, project_id) || error("data science project not found")
    project = deepcopy(state.data_science_projects[project_id])
    if action == :analysis_export
        # Export verifies the persisted result/code bytes, not only stored reference labels.
        workspace = project.analysis_workspace
        isempty(workspace) && error("analysis save a workspace before exporting")
        dataset = data_science_project_dataset(project, workspace["datasetId"])
        schema = analysis_schema(project, workspace["datasetId"])
        JuliaFlowProjectAnalysis.check_scope(workspace["scope"], dataset, schema)
        JuliaFlowProjectAnalysis.verified_table(dataset, resolve_local_data_ref_path(dataset["sourceUri"]))
        ids = unique([get(workspace, "analysisRunId", ""); [get(f,"analysisRunId", "") for f in get(workspace,"findings",Any[])]])
        selected = [r for r in project.statistical_analysis_runs if get(r,"analysisRunId", "") in ids]
        for run in selected, ref in get(run, "artifactRefs", Any[])
            path = resolve_local_artifact_ref_path(ref["path"])
            path !== nothing && isfile(path) && local_artifact_checksum(path) == ref["checksumSha256"] || error("analysis report evidence artifact unavailable or changed")
            if get(ref, "kind", "") == "statistical_analysis_results"
                result = JSON3.read(read(path, String), Dict{String,Any})
                all(key -> get(result, key, nothing) == get(run, key, nothing),
                    ("analysisRunId", "datasetId", "method", "status", "resultSummary", "warnings", "createdAt")) ||
                    error("analysis report stored evidence differs from its verified result artifact")
            end
        end
        return JSON3.write(JuliaFlowProjectAnalysis.report_response(project, selected))
    end
    validator = JuliaFlowGatewayRepository.JuliaFlowProjectPayloadValidation
    request_contract = action == :analysis_profile ? Dict("type" => "object", "additionalProperties" => false,
        "required" => ["datasetId"], "properties" => Dict("datasetId" => Dict("type" => "string", "minLength" => 1))) :
        Dict("\$ref" => "#/components/schemas/SaveAnalysisWorkspaceRequest")
    request_schema = validator.contract_schema(request_contract)
    validator.JSONSchema.validate(request_schema, validator.contract_value(body)) === nothing || error("analysis request invalid contract payload")
    dataset_id = action == :analysis_profile ? String(body["datasetId"]) : String(body["workspace"]["datasetId"])
    dataset = data_science_project_dataset(project, dataset_id)
    schema = analysis_schema(project, dataset_id)
    path = resolve_local_data_ref_path(dataset["sourceUri"])
    path === nothing && error("analysis source evidence unavailable")
    if action == :analysis_profile
        return JSON3.write(JuliaFlowProjectAnalysis.measured_profile(dataset, path, schema))
    end
    JuliaFlowProjectAnalysis.verified_table(dataset, path)
    project.analysis_workspace = JuliaFlowProjectAnalysis.validate_workspace(body, project, dataset, schema)
    project.updated_at = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
    saved = JuliaFlowGatewayRepository.save_data_science_project!(state.repository, project; producer = "api-gateway")
    state.data_science_projects[project_id] = saved
    return JSON3.write(JuliaFlowGatewayRepository.data_science_project_payload(saved))
end

"""Claim one project mutation; reject overlaps without holding a mutex during I/O."""
function with_project_mutation(action::Function, state::GatewayState, project_id::AbstractString)
    lock(state.project_mutation_lock) do
        project_id in state.mutating_projects && error("data science project mutation in progress; retry after it completes")
        push!(state.mutating_projects, project_id)
    end
    try
        return action()
    finally
        lock(state.project_mutation_lock) do
            delete!(state.mutating_projects, project_id)
        end
    end
end

function data_science_project_route_response(state::GatewayState, request::HTTP.Request, route)
    route.action in (:list, :get, :create, :analysis_profile, :analysis_export) && return data_science_project_route_response_owned(state, request, route)
    require_permission!(state, request, "workflow:write"; resource_type = "data_science_project", resource_id = route.project_id)
    return with_project_mutation(state, route.project_id) do
        data_science_project_route_response_owned(state, request, route)
    end
end

function data_science_project_route_response_owned(state::GatewayState, request::HTTP.Request, route)
    action = route.action
    project_id = route.project_id
    if action == :list
        context = require_permission!(state, request, "workflow:read")
        return json_response(200, list_data_science_projects_response(state; auth_context = context))
    elseif action == :create
        require_permission!(state, request, "workflow:write")
        body = parse_request_body(request)
        response = create_data_science_project_response!(state, body)
        project = JSON3.read(response, Dict{String,Any})
        created_id = String(project["projectId"])
        append_audit_event!(state, request, "data_science_project.create"; target_type = "data_science_project", target_id = created_id)
        return json_response(201, response)
    end

    permission = action == :get ? "workflow:read" : "workflow:write"
    require_permission!(state, request, permission; resource_type = "data_science_project", resource_id = project_id)
    action == :get && return json_response(200, get_data_science_project_response(state, project_id))
    body = parse_request_body(request)
    response, audit_action, status = if action == :update
        (update_data_science_project_response!(state, project_id, body), "data_science_project.update", 200)
    elseif action in (:analysis_profile, :analysis_workspace, :analysis_export)
        (analysis_action_response!(state, project_id, action, body), "data_science_project.$(action)", 200)
    elseif action == :transform_fit_apply
        (run_transform_fit_apply_response!(state, project_id, body), "data_science_project.transform.fit_apply", 201)
    elseif action == :statistical_analysis
        (run_statistical_analysis_response!(state, project_id, body), "data_science_project.statistical_analysis.run", 201)
    elseif action == :tuning
        (run_tuning_study_response!(state, project_id, body), "data_science_project.tuning.run", 201)
    elseif action == :evaluation
        (run_final_evaluation_response!(state, project_id, body), "data_science_project.evaluation.run", 201)
    elseif action == :prediction_export
        (run_prediction_export_response!(state, project_id, body), "data_science_project.predictions.export", 201)
    elseif action == :drift
        (run_drift_report_response!(state, project_id, body), "data_science_project.drift.run", 201)
    elseif action == :model_lifecycle
        (model_lifecycle_action_response!(state, project_id, body), "data_science_project.model.lifecycle", 201)
    else
        error("unsupported data science project route action: $(action)")
    end
    append_audit_event!(state, request, audit_action; target_type = "data_science_project", target_id = project_id)
    return json_response(status, response)
end

function route_request_inner(state::GatewayState, request::HTTP.Request)
    method = String(request.method)
    uri = HTTP.URI(String(request.target))
    path = uri.path
    segments = split(path, '/'; keepempty = false)
    query_params = HTTP.queryparams(uri)

    try
        validate_cors_origin!(request)
        method == "OPTIONS" && return empty_response(204)
        method == "GET" && segments == ["health"] && begin
            health = JSON3.read(healthcheck(state), Dict{String,Any})
            # The local inventory has no project ownership mapping. Keep it internal.
            health["workspaceSummary"]["artifacts"] = Any[]
            return json_response(200, JSON3.write(health))
        end
        method == "GET" && segments == ["metrics"] && return text_response(200, metrics_response(state); content_type = "text/plain; version=0.0.4")
        method == "GET" && segments == ["api", "v1", "settings", "compute"] && begin
            require_permission!(state, request, "workflow:read")
            return json_response(200, compute_settings_response(state))
        end
        method == "PUT" && segments == ["api", "v1", "settings", "compute"] && begin
            require_permission!(state, request, "workflow:write")
            body = parse_request_body(request)
            response = update_compute_settings_response!(state, body)
            append_audit_event!(state, request, "settings.compute.update"; target_type = "settings", target_id = "compute")
            return json_response(200, response)
        end
        method == "GET" && segments == ["api", "v1", "workflows"] && begin
            require_permission!(state, request, "workflow:read")
            return json_response(200, list_workflows_response(state))
        end
        method == "GET" && segments == ["api", "v1", "executions"] && begin
            require_permission!(state, request, "execution:read")
            return json_response(200, execution_list_response(state))
        end
        method == "GET" && segments == ["api", "v1", "audit", "actions"] && begin
            require_permission!(state, request, "audit:read")
            return json_response(200, audit_action_query_response(state, query_params))
        end
        method == "GET" && segments == ["api", "v1", "admin", "auth", "policies"] && begin
            require_permission!(state, request, "policy:read")
            return json_response(200, auth_policy_response(state))
        end
        method == "PUT" && segments == ["api", "v1", "admin", "auth", "policies"] && begin
            require_permission!(state, request, "policy:write")
            body = parse_request_body(request)
            response = save_auth_policy_response!(state, body)
            append_audit_event!(state, request, "auth.policy.update"; target_type = "auth_policy", target_id = "default")
            return json_response(200, response)
        end
        method == "GET" && segments == ["api", "v1", "admin", "auth", "directory"] && begin
            require_permission!(state, request, "policy:read")
            return json_response(200, auth_directory_response(state))
        end
        method == "PUT" && segments == ["api", "v1", "admin", "auth", "directory"] && begin
            context = require_permission!(state, request, "policy:write")
            body = parse_request_body(request)
            response = save_auth_directory_response!(state, body, context)
            append_audit_event!(state, request, "auth.directory.update"; target_type = "auth_directory", target_id = "default")
            return json_response(200, response)
        end
        method == "GET" && length(segments) == 7 && segments[1:3] == ["api", "v1", "dashboards"] && segments[5] == "charts" && segments[7] == "data" && begin
            share_token = haskey(query_params, "shareToken") ? String(query_params["shareToken"]) : nothing
            workspace_token = haskey(query_params, "workspaceToken") ? String(query_params["workspaceToken"]) : nothing
            workspace_bearer_token = bearer_token_from_request(request)
            return json_response(200, published_dashboard_chart_data_response(state, segments[4], segments[6]; share_token = share_token, workspace_token = workspace_token, workspace_bearer_token = workspace_bearer_token))
        end
        method == "GET" && length(segments) == 7 && segments[1:3] == ["api", "v1", "dashboards"] && segments[5] == "charts" && segments[7] == "export.csv" && begin
            share_token = haskey(query_params, "shareToken") ? String(query_params["shareToken"]) : nothing
            workspace_token = haskey(query_params, "workspaceToken") ? String(query_params["workspaceToken"]) : nothing
            workspace_bearer_token = bearer_token_from_request(request)
            body = published_dashboard_chart_data_csv_response(state, segments[4], segments[6]; share_token = share_token, workspace_token = workspace_token, workspace_bearer_token = workspace_bearer_token)
            headers = ["Content-Type" => "text/csv; charset=utf-8", "Content-Disposition" => "attachment; filename=\"$(segments[4])-$(segments[6]).csv\"", base_headers()...]
            return HTTP.Response(200, headers, body)
        end
        method == "GET" && length(segments) == 4 && segments[1:3] == ["api", "v1", "dashboards"] && begin
            share_token = haskey(query_params, "shareToken") ? String(query_params["shareToken"]) : nothing
            workspace_token = haskey(query_params, "workspaceToken") ? String(query_params["workspaceToken"]) : nothing
            workspace_bearer_token = bearer_token_from_request(request)
            return json_response(200, get_published_dashboard_response(state, segments[4]; share_token = share_token, workspace_token = workspace_token, workspace_bearer_token = workspace_bearer_token))
        end
        method == "GET" && length(segments) == 5 && segments[1:3] == ["api", "v1", "workflows"] && segments[5] == "dashboards" && begin
            require_permission!(state, request, "dashboard:read")
            return json_response(200, list_published_dashboards_response(state, segments[4]))
        end
        method == "GET" && segments == ["api", "v1", "hub", "extensions"] && begin
            require_permission!(state, request, "hub:read")
            return json_response(200, list_hub_extensions_response(state))
        end
        method == "POST" && segments == ["api", "v1", "hub", "extensions", "register"] && begin
            require_permission!(state, request, "hub:publish")
            body = parse_request_body(request)
            response = register_hub_extension_response!(state, body)
            extension_id = haskey(body, "manifest") && body["manifest"] isa AbstractDict && haskey(body["manifest"], "extensionId") ?
                String(body["manifest"]["extensionId"]) :
                "unknown"
            append_audit_event!(state, request, "hub.extension.register"; target_type = "hub_extension", target_id = extension_id)
            return json_response(201, response)
        end
        method == "POST" && length(segments) == 7 && segments[1:3] == ["api", "v1", "workflows"] && segments[5] == "dashboards" && segments[7] == "publish" && begin
            require_permission!(state, request, "dashboard:publish")
            body = parse_request_body(request)
            visibility = haskey(body, "visibility") ? String(body["visibility"]) : "workspace"
            response = publish_dashboard_response!(state, segments[4], segments[6]; visibility = visibility)
            append_audit_event!(state, request, "dashboard.publish"; target_type = "dashboard", target_id = segments[6], details = Dict("workflowId" => segments[4], "visibility" => visibility))
            return json_response(200, response)
        end
        method == "POST" && length(segments) == 7 && segments[1:3] == ["api", "v1", "workflows"] && segments[5] == "dashboards" && segments[7] == "checkpoint-export" && begin
            require_permission!(state, request, "dashboard:publish")
            require_permission!(state, request, "checkpoint:write")
            require_permission!(state, request, "checkpoint:read")
            body = parse_request_body(request)
            response = visualize_checkpoint_export_response!(state, segments[4], segments[6], body)
            target_id = haskey(body, "checkpointTag") ? String(body["checkpointTag"]) : segments[6]
            append_audit_event!(state, request, "workflow.visualize.checkpoint_export"; target_type = "dashboard", target_id = segments[6], details = Dict("workflowId" => segments[4], "checkpointTag" => target_id))
            return json_response(201, response)
        end
        method == "POST" && segments == ["api", "v1", "reproducibility-bundles"] && begin
            require_permission!(state, request, "checkpoint:read")
            body = parse_request_body(request)
            response = reproducibility_bundle_export_response!(state, body)
            target_id = haskey(body, "checkpointTag") ? String(body["checkpointTag"]) : "unknown"
            append_audit_event!(state, request, "reproducibility.bundle.export"; target_type = "checkpoint", target_id = target_id)
            return json_response(200, response)
        end
        method == "POST" && segments == ["api", "v1", "reproducibility-bundles", "import"] && begin
            require_permission!(state, request, "workflow:write")
            require_permission!(state, request, "checkpoint:write")
            body = parse_request_body(request)
            response = reproducibility_bundle_import_response!(state, body)
            append_audit_event!(state, request, "reproducibility.bundle.import"; target_type = "reproducibility_bundle", target_id = "import")
            return json_response(201, response)
        end
        method == "POST" && segments == ["api", "v1", "local-backups"] && begin
            require_permission!(state, request, "backup:read")
            require_permission!(state, request, "backup:write")
            body = parse_request_body(request)
            response = local_backup_export_response!(state, body)
            append_audit_event!(state, request, "local.backup.export"; target_type = "local_backup", target_id = "export")
            return json_response(200, response)
        end
        method == "POST" && segments == ["api", "v1", "local-backups", "import"] && begin
            require_permission!(state, request, "backup:write")
            body = parse_request_body(request)
            response = local_backup_restore_response!(state, body)
            append_audit_event!(state, request, "local.backup.import"; target_type = "local_backup", target_id = "import")
            return json_response(201, response)
        end
        method == "POST" && segments == ["api", "v1", "local-data", "import"] && begin
            context = require_permission!(state, request, "workflow:write")
            body = parse_request_body(request)
            target_id = haskey(body, "datasetId") ? String(body["datasetId"]) : "workflow-dataset"
            try
                response = if haskey(body, "projectId")
                    enforce_resource_policy!(state, context, "workflow:write", "data_science_project", String(body["projectId"]))
                    with_project_mutation(state, String(body["projectId"])) do
                        data_import_profile_response!(state, body; auth_context = context)
                    end
                else
                    data_import_profile_response!(state, body; auth_context = context)
                end
                append_audit_event!(
                    state,
                    request,
                    "local.data.import";
                    target_type = "dataset",
                    target_id = target_id,
                    details = local_data_import_audit_details(body; outcome = "accepted"),
                )
                return json_response(201, response)
            catch err
                status, message = classify_gateway_error(err)
                append_audit_event!(
                    state,
                    request,
                    "local.data.import.rejected";
                    target_type = "dataset",
                    target_id = target_id,
                    details = local_data_import_audit_details(body; outcome = "rejected", reason = message),
                )
                return error_response(status, message)
            end
        end
        project_route = JuliaFlowDataScienceProjectRoutes.match_project_route(method, segments)
        project_route === nothing || return data_science_project_route_response(state, request, project_route)
        method == "POST" && segments == ["api", "v1", "workflows"] && begin
            require_permission!(state, request, "workflow:write")
            body = parse_request_body(request)
            response = create_workflow_response_from_body!(state, body)
            workflow_id = haskey(body, "workflow") && body["workflow"] isa AbstractDict && haskey(body["workflow"], "workflowId") ?
                String(body["workflow"]["workflowId"]) :
                "unknown"
            append_audit_event!(state, request, "workflow.create"; target_type = "workflow", target_id = workflow_id)
            return json_response(201, response)
        end
        method == "POST" && length(segments) == 6 && segments[1:4] == ["api", "v1", "hub", "extensions"] && segments[6] == "install" && begin
            require_permission!(state, request, "hub:install")
            body = parse_request_body(request)
            action = haskey(body, "action") ? String(body["action"]) : "install"
            response = install_hub_extension_response!(state, segments[5]; action = action)
            append_audit_event!(state, request, "hub.extension.$(action)"; target_type = "hub_extension", target_id = segments[5])
            return json_response(200, response)
        end
        method == "POST" && segments == ["api", "v1", "workflows", "import"] && begin
            require_permission!(state, request, "workflow:write")
            body = parse_request_body(request)
            haskey(body, "sourcePath") || return error_response(400, "missing sourcePath")
            response = import_workflow_response!(state; source_path = String(body["sourcePath"]))
            append_audit_event!(state, request, "workflow.import"; target_type = "workflow", target_id = String(body["sourcePath"]))
            return json_response(201, response)
        end
        method == "GET" && length(segments) == 4 && segments[1:3] == ["api", "v1", "workflows"] && begin
            require_permission!(state, request, "workflow:read"; resource_type = "workflow", resource_id = segments[4])
            return json_response(200, get_workflow_response(state, segments[4]))
        end
        method == "PUT" && length(segments) == 4 && segments[1:3] == ["api", "v1", "workflows"] && begin
            require_permission!(state, request, "workflow:write"; resource_type = "workflow", resource_id = segments[4])
            body = parse_request_body(request)
            response = update_workflow_response_from_body!(state, segments[4], body)
            append_audit_event!(state, request, "workflow.update"; target_type = "workflow", target_id = segments[4])
            return json_response(200, response)
        end
        method == "POST" && length(segments) == 6 && segments[1:3] == ["api", "v1", "workflows"] && segments[5:6] == ["transforms", "run"] && begin
            require_permission!(state, request, "workflow:execute"; resource_type = "workflow", resource_id = segments[4])
            body = parse_request_body(request)
            response = transform_run_response!(state, segments[4], body)
            append_audit_event!(state, request, "workflow.transform.run"; target_type = "workflow", target_id = segments[4])
            return json_response(202, response)
        end
        method == "GET" && length(segments) == 6 && segments[1:3] == ["api", "v1", "workflows"] && segments[5:6] == ["transforms", "history"] && begin
            require_permission!(state, request, "execution:read")
            return json_response(200, transform_history_response(state, segments[4]))
        end
        method == "POST" && length(segments) == 7 && segments[1:3] == ["api", "v1", "workflows"] && segments[5:7] == ["ml", "experiments", "run"] && begin
            context = require_permission!(state, request, "workflow:execute"; resource_type = "workflow", resource_id = segments[4])
            body = parse_request_body(request)
            response = ml_experiment_run_response!(state, segments[4], body; auth_context = context)
            append_audit_event!(state, request, "workflow.ml.experiment.run"; target_type = "workflow", target_id = segments[4])
            return json_response(202, response)
        end
        method == "GET" && length(segments) == 6 && segments[1:3] == ["api", "v1", "workflows"] && segments[5:6] == ["ml", "experiments"] && begin
            require_permission!(state, request, "execution:read")
            return json_response(200, ml_experiment_history_response(state, segments[4]))
        end
        method == "POST" && length(segments) == 6 && segments[1:3] == ["api", "v1", "workflows"] && segments[5:6] == ["models", "register"] && begin
            context = require_permission!(state, request, "workflow:write"; resource_type = "workflow", resource_id = segments[4])
            body = parse_request_body(request)
            response = model_register_response!(state, segments[4], body; auth_context = context)
            append_audit_event!(state, request, "workflow.model.register"; target_type = "workflow", target_id = segments[4])
            return json_response(201, response)
        end
        method == "GET" && length(segments) == 5 && segments[1:3] == ["api", "v1", "workflows"] && segments[5] == "models" && begin
            require_permission!(state, request, "workflow:read"; resource_type = "workflow", resource_id = segments[4])
            return json_response(200, model_registry_list_response(state, segments[4]))
        end
        method == "POST" && length(segments) == 6 && segments[1:3] == ["api", "v1", "workflows"] && segments[5:6] == ["deploy", "package"] && begin
            context = require_permission!(state, request, "workflow:write"; resource_type = "workflow", resource_id = segments[4])
            require_permission!(state, request, "checkpoint:read")
            body = parse_request_body(request)
            response = deploy_package_response!(state, segments[4], body; auth_context = context)
            append_audit_event!(state, request, "workflow.deploy.package"; target_type = "workflow", target_id = segments[4])
            return json_response(201, response)
        end
        method == "GET" && length(segments) == 6 && segments[1:3] == ["api", "v1", "workflows"] && segments[5:6] == ["deploy", "packages"] && begin
            require_permission!(state, request, "workflow:read"; resource_type = "workflow", resource_id = segments[4])
            return json_response(200, deploy_package_history_response(state, segments[4]))
        end
        method == "POST" && length(segments) == 5 && segments[1:3] == ["api", "v1", "workflows"] && segments[5] == "execute" && begin
            require_permission!(state, request, "workflow:execute"; resource_type = "workflow", resource_id = segments[4])
            body = parse_request_body(request)
            flow_variable_values = haskey(body, "flowVariables") ? normalized_string_dict(body["flowVariables"]) : Dict{String,Any}()
            execution_mode_override = haskey(body, "executionMode") ? String(body["executionMode"]) : nothing
            response = execution_accept_response(
                state,
                segments[4];
                flow_variable_values = flow_variable_values,
                execution_mode_override = execution_mode_override,
            )
            append_audit_event!(state, request, "workflow.execute"; target_type = "workflow", target_id = segments[4], details = execution_mode_override === nothing ? Dict{String,Any}() : Dict("executionMode" => execution_mode_override))
            return json_response(
                202,
                response,
            )
        end
        method == "GET" && length(segments) == 4 && segments[1:3] == ["api", "v1", "executions"] && begin
            require_permission!(state, request, "execution:read")
            return json_response(200, execution_detail_response(state, segments[4]))
        end
        method == "POST" && length(segments) == 5 && segments[1:3] == ["api", "v1", "executions"] && segments[5] == "status" && begin
            require_permission!(state, request, "execution:write")
            body = parse_request_body(request)
            haskey(body, "status") || return error_response(400, "missing status")
            message = haskey(body, "message") ? String(body["message"]) : nothing
            metadata = if haskey(body, "metadata")
                admit_execution_status_metadata(state, segments[4], body["metadata"])
            else
                Dict{String,Any}()
            end
            response = transition_execution_response!(
                state,
                segments[4];
                status = String(body["status"]),
                message = message,
                metadata = metadata,
            )
            append_audit_event!(state, request, "execution.status.transition"; target_type = "execution", target_id = segments[4], details = Dict("status" => String(body["status"])))
            return json_response(
                200,
                response,
            )
        end
        method == "GET" && segments == ["api", "v1", "checkpoints"] && begin
            require_permission!(state, request, "checkpoint:read")
            return json_response(200, checkpoint_list_response(state))
        end
        method == "POST" && segments == ["api", "v1", "checkpoints"] && begin
            require_permission!(state, request, "checkpoint:write")
            body = parse_request_body(request)
            haskey(body, "tag") || return error_response(400, "missing tag")
            haskey(body, "summary") || return error_response(400, "missing summary")
            response = create_checkpoint_response!(state; tag = String(body["tag"]), summary = String(body["summary"]))
            append_audit_event!(state, request, "checkpoint.create"; target_type = "checkpoint", target_id = String(body["tag"]))
            return json_response(
                201,
                response,
            )
        end
        return error_response(404, "route not found")
    catch err
        status, message = classify_gateway_error(err)
        return error_response(status, message)
    end
end

function serve_gateway(state::GatewayState; host::AbstractString = "127.0.0.1", port::Integer = 8088)
    start_gateway_event_consumer_task!(state)
    start_gateway_sync_task!(state)
    return HTTP.serve(gateway_stream_handler(state), host, port; verbose = false, stream = true)
end

end
