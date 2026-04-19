module JuliaFlowGatewayRepository

include(joinpath(@__DIR__, "..", "..", "execution-service", "src", "JuliaFlowExecutionService.jl"))

using .JuliaFlowExecutionService
using Dates
using JSON3
using LibPQ

export GatewayCheckpoint,
    GatewayExecution,
    AbstractGatewayRepository,
    FileGatewayRepository,
    PostgreSQLGatewayRepository,
    ensure_repository!,
    load_workflows,
    load_checkpoints,
    load_executions,
    save_workflow!,
    save_checkpoint!,
    save_execution!,
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
            elseif string_key == "stream_lifecycle_status"
                payload["streamLifecycleStatus"] = String(value)
            else
                payload[string_key] = value
            end
        end
    end
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
        metadata[string_key] = value
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

function save_workflow!(repo::FileGatewayRepository, workflow_toml::AbstractString)
    ensure_repository!(repo)
    workflow = load_workflow_definition_text(workflow_toml)
    validate_workflow(workflow)
    write(joinpath(workflows_dir(repo), string(workflow.id, ".toml")), workflow_toml)
    return workflow
end

function save_checkpoint!(repo::FileGatewayRepository, checkpoint::GatewayCheckpoint)
    checkpoints = load_checkpoints(repo)
    filtered = [item for item in checkpoints if item.tag != checkpoint.tag]
    push!(filtered, checkpoint)
    persist_json_file!(checkpoints_file(repo), [checkpoint_payload(item) for item in filtered])
    return checkpoint
end

function save_execution!(repo::FileGatewayRepository, execution::GatewayExecution)
    executions = load_executions(repo)
    filtered = [item for item in executions if item.execution_id != execution.execution_id]
    push!(filtered, execution)
    persist_json_file!(executions_file(repo), [execution_payload(item) for item in filtered])
    return execution
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

function save_workflow!(repo::PostgreSQLGatewayRepository, workflow_toml::AbstractString)
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

function save_execution!(repo::PostgreSQLGatewayRepository, execution::GatewayExecution)
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
    return execution
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
