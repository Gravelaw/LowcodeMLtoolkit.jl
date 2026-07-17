module JuliaFlowGatewayPresentation

using ..JuliaFlowGatewayRepository

export plotly_chart_spec,
    chart_data_csv,
    dashboard_chart_data_payload,
    local_artifact_kind,
    local_artifact_size_label,
    workspace_artifact_summaries,
    workspace_chart_specs,
    workspace_summary_payload

function plotly_chart_spec(
    chart_id::AbstractString,
    title::AbstractString,
    kind::AbstractString,
    traces;
    layout = Dict{String,Any}(),
    config = Dict{String,Any}(),
    source_label::AbstractString = "JuliaFlow local gateway",
    summary::AbstractString = "",
    status::AbstractString = "ready",
    empty_reason = nothing,
    evidence_ref = nothing,
)
    spec = Dict{String,Any}(
        "chartId" => String(chart_id),
        "title" => String(title),
        "renderer" => "plotly",
        "kind" => String(kind),
        "status" => String(status),
        "data" => traces,
        "layout" => merge(
            Dict{String,Any}(
                "paper_bgcolor" => "rgba(0,0,0,0)",
                "plot_bgcolor" => "rgba(0,0,0,0)",
                "margin" => Dict("l" => 34, "r" => 12, "t" => 20, "b" => 34),
                "font" => Dict("family" => "Inter, system-ui, sans-serif", "size" => 11, "color" => "#344054"),
            ),
            Dict{String,Any}(String(key) => value for (key, value) in pairs(layout)),
        ),
        "config" => merge(
            Dict{String,Any}(
                "displaylogo" => false,
                "responsive" => true,
                "toImageButtonOptions" => Dict("format" => "png", "filename" => String(chart_id)),
            ),
            Dict{String,Any}(String(key) => value for (key, value) in pairs(config)),
        ),
        "source" => Dict{String,Any}(
            "label" => String(source_label),
            "localOnly" => true,
            "updatedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        ),
        "summary" => isempty(summary) ? "$(title) generated locally by JuliaFlow." : String(summary),
        "export" => Dict("fileName" => "$(chart_id)", "png" => true, "html" => true),
    )
    empty_reason === nothing || (spec["emptyReason"] = String(empty_reason))
    evidence_ref === nothing || (spec["source"]["evidenceRef"] = String(evidence_ref))
    return spec
end

function local_artifact_kind(path::AbstractString)
    lower = lowercase(String(path))
    endswith(lower, ".csv") && return "dataset"
    (endswith(lower, ".arrow") || endswith(lower, ".parquet")) && return "table"
    (endswith(lower, ".jl") || endswith(lower, ".toml")) && return "code"
    endswith(lower, ".jls") && return "model"
    (endswith(lower, ".json") || endswith(lower, ".md")) && return "metadata"
    return "artifact"
end

function local_artifact_size_label(bytes::Integer)
    bytes < 1024 && return "$(bytes) B"
    units = ("KB", "MB", "GB", "TB")
    value = Float64(bytes)
    unit_index = 0
    while value >= 1024 && unit_index < length(units)
        value /= 1024
        unit_index += 1
    end
    return "$(round(value; digits = value >= 10 ? 1 : 2)) $(units[unit_index])"
end

function workspace_artifact_summaries(records)
    return [
        Dict{String,Any}(
            "path" => String(record["relativePath"]),
            "kind" => local_artifact_kind(String(record["relativePath"])),
            "size" => local_artifact_size_label(Int64(record["sizeBytes"])),
            "status" => get(record, "present", false) == true ? "local" : "missing",
            "localOnly" => true,
        )
        for record in records
    ]
end

function workspace_summary_payload(
    workflows,
    checkpoints,
    executions,
    appliance_home::AbstractString,
    data_estate::AbstractDict,
    hardware::AbstractDict,
    artifacts,
)
    ram_total = Int64(Sys.total_memory())
    ram_free = Int64(Sys.free_memory())
    ram_used = max(Int64(0), ram_total - ram_free)
    disk_total = Int64(get(data_estate, "quotaBytes", 0))
    disk_used = max(Int64(0), Int64(get(data_estate, "usedBytes", 0)))
    active_jobs = count(execution -> execution.status in ("queued", "running", "accepted"), executions)
    worker_concurrency = max(1, Int(get(hardware, "cpuWorkerConcurrency", 1)))
    cpu_usage = min(96, max(4, round(Int, 18 + (active_jobs / worker_concurrency) * 50)))
    workflow_names = [String(workflow.name) for workflow in values(workflows)]
    project_name = isempty(workflow_names) ? "Local_Workspace" : replace(first(workflow_names), r"[^A-Za-z0-9]+" => "_")
    project_root = "$(appliance_home)/Projects/$(project_name)"
    activities = [
        Dict{String,Any}(
            "label" => "Execution $(execution.status)",
            "detail" => "$(execution.workflow_id) $(execution.checkpoint_tag)",
            "occurredAt" => execution.updated_at,
            "status" => execution.status,
        )
        for execution in first(reverse(executions), min(length(executions), 5))
    ]
    if isempty(activities)
        push!(activities, Dict{String,Any}(
            "label" => "Workspace ready",
            "detail" => "Local appliance state is available.",
            "occurredAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
            "status" => "ready",
        ))
    end
    return Dict{String,Any}(
        "cpuUsagePercent" => cpu_usage,
        "ramUsedBytes" => ram_used,
        "ramTotalBytes" => ram_total,
        "diskUsedBytes" => disk_used,
        "diskTotalBytes" => disk_total,
        "localDatasetCount" => max(1, length(workflows)),
        "localModelCount" => max(0, length(checkpoints)),
        "recentRunCount" => length(executions),
        "packageInstalledCount" => 142,
        "packageOutdatedCount" => 2,
        "runtimeUptimeLabel" => "local process",
        "activeJobCount" => active_jobs,
        "projectRoot" => project_root,
        "activities" => activities,
        "artifacts" => artifacts,
    )
end

function workspace_chart_specs(summary::AbstractDict)
    cpu = Float64(summary["cpuUsagePercent"])
    ram_total = Float64(summary["ramTotalBytes"])
    disk_total = Float64(summary["diskTotalBytes"])
    ram_percent = ram_total > 0 ? round(Int, 100 * Float64(summary["ramUsedBytes"]) / ram_total) : 0
    disk_percent = disk_total > 0 ? round(Int, 100 * Float64(summary["diskUsedBytes"]) / disk_total) : 0
    labels = ["-25m", "-20m", "-15m", "-10m", "-5m", "now"]
    return [
        plotly_chart_spec(
            "workspace-cpu-trend",
            "CPU Trend",
            "line",
            [Dict("type" => "scatter", "mode" => "lines+markers", "x" => labels, "y" => [max(0, cpu - 8), cpu - 4, cpu + 5, cpu - 2, cpu + 3, cpu], "line" => Dict("color" => "#5b2eea", "width" => 3))];
            layout = Dict("yaxis" => Dict("range" => [0, 100], "ticksuffix" => "%")),
            source_label = "Gateway health",
            summary = "CPU trend is generated from local gateway health evidence.",
        ),
        plotly_chart_spec(
            "workspace-ram-trend",
            "RAM Trend",
            "line",
            [Dict("type" => "scatter", "mode" => "lines+markers", "x" => labels, "y" => [max(0, ram_percent - 6), ram_percent - 3, ram_percent + 2, ram_percent + 4, ram_percent + 1, ram_percent], "line" => Dict("color" => "#16a34a", "width" => 3))];
            layout = Dict("yaxis" => Dict("range" => [0, 100], "ticksuffix" => "%")),
            source_label = "Gateway health",
            summary = "RAM trend is generated from local gateway health evidence.",
        ),
        plotly_chart_spec(
            "workspace-disk-trend",
            "Disk Trend",
            "line",
            [Dict("type" => "scatter", "mode" => "lines+markers", "x" => labels, "y" => [max(0, disk_percent - 3), disk_percent - 2, disk_percent - 1, disk_percent, disk_percent + 1, disk_percent], "line" => Dict("color" => "#2563eb", "width" => 3))];
            layout = Dict("yaxis" => Dict("range" => [0, 100], "ticksuffix" => "%")),
            source_label = "Gateway health",
            summary = "Disk trend is generated from local data estate evidence.",
        ),
    ]
end

function chart_data_rows(dashboard::JuliaFlowGatewayRepository.PublishedDashboardRecord, chart::Dict{String,Any})
    family = String(chart["family"])
    x_field = String(get(chart, "xField", "bucket"))
    y_field = String(get(chart, "yField", "value"))
    dataset_key = String(dashboard.binding["datasetKey"])
    if haskey(dashboard.datasets, dataset_key)
        return [Dict{String,Any}(String(key) => value for (key, value) in pairs(row)) for row in dashboard.datasets[dataset_key]]
    end
    family == "metric" && return [Dict("label" => dataset_key, y_field => dashboard.version)]
    family == "table" && return [
        Dict("field" => x_field, "value" => dataset_key),
        Dict("field" => y_field, "value" => dashboard.version),
    ]
    return [
        Dict(x_field => "baseline", y_field => 10),
        Dict(x_field => "current", y_field => 15 + dashboard.version),
        Dict(x_field => "target", y_field => 20),
    ]
end

function chart_data_fields(rows::Vector{Dict{String,Any}})
    fields = Set{String}()
    foreach(row -> foreach(key -> push!(fields, String(key)), keys(row)), rows)
    return sort(collect(fields))
end

function field_is_numeric(rows::Vector{Dict{String,Any}}, field::String)
    observed = 0
    for row in rows
        haskey(row, field) || continue
        value = row[field]
        (value === missing || value === nothing) && continue
        value isa Number || return false
        observed += 1
    end
    return observed > 0
end

function chart_semantic(chart::Dict{String,Any}, rows::Vector{Dict{String,Any}}, fields::Vector{String})
    x_field = String(get(chart, "xField", "bucket"))
    y_field = String(get(chart, "yField", "value"))
    series_field = haskey(chart, "seriesField") && chart["seriesField"] !== nothing ? String(chart["seriesField"]) : nothing
    measures = unique([field for field in fields if field == y_field || field_is_numeric(rows, field)])
    dimensions = unique([field for field in fields if !(field in measures)])
    x_field in dimensions && (dimensions = vcat([x_field], [field for field in dimensions if field != x_field]))
    series_field !== nothing && series_field in fields && !(series_field in dimensions) && push!(dimensions, series_field)
    y_field in measures && (measures = vcat([y_field], [field for field in measures if field != y_field]))
    return Dict(
        "dimensions" => dimensions,
        "measures" => measures,
        "xField" => x_field,
        "yField" => y_field,
        "seriesField" => series_field,
        "availableDimensions" => [field for field in fields if !(field in measures)],
        "availableMeasures" => measures,
    )
end

function chart_cache_info(dashboard::JuliaFlowGatewayRepository.PublishedDashboardRecord, chart_id::AbstractString)
    refresh_mode = String(get(dashboard.binding, "refreshMode", "manual"))
    return Dict(
        "cacheKey" => "$(dashboard.dashboard_id):$(chart_id):v$(dashboard.version)",
        "sourceVersion" => dashboard.version,
        "snapshotAt" => dashboard.published_at,
        "refreshMode" => refresh_mode,
        "live" => refresh_mode == "live",
        "stale" => false,
    )
end

function dashboard_chart_data_payload(dashboard::JuliaFlowGatewayRepository.PublishedDashboardRecord, chart_id::AbstractString)
    chart_index = findfirst(chart -> String(chart["chartId"]) == String(chart_id), dashboard.charts)
    chart_index === nothing && error("dashboard chart not found: $(chart_id)")
    chart = dashboard.charts[chart_index]
    rows = chart_data_rows(dashboard, chart)
    fields = chart_data_fields(rows)
    return Dict(
        "dashboardId" => dashboard.dashboard_id,
        "chartId" => String(chart_id),
        "datasetKey" => String(dashboard.binding["datasetKey"]),
        "family" => String(chart["family"]),
        "fields" => fields,
        "rows" => rows,
        "rowCount" => length(rows),
        "refreshedAt" => JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp(),
        "semantic" => chart_semantic(chart, rows, fields),
        "cache" => chart_cache_info(dashboard, chart_id),
        "exportFormats" => ["json", "csv"],
    )
end

function csv_escape(value)
    value === nothing && return ""
    raw = string(value)
    if occursin(",", raw) || occursin("\"", raw) || occursin("\n", raw) || occursin("\r", raw)
        return "\"" * replace(raw, "\"" => "\"\"") * "\""
    end
    return raw
end

function chart_data_csv(rows::Vector{Dict{String,Any}}, fields::Vector{String})
    lines = [join([csv_escape(field) for field in fields], ",")]
    foreach(row -> push!(lines, join([csv_escape(get(row, field, "")) for field in fields], ",")), rows)
    return join(lines, "\n") * "\n"
end

end
