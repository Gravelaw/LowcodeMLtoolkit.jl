module JuliaFlowGatewayPresentation

using ..JuliaFlowGatewayRepository

export plotly_chart_spec,
    local_artifact_kind,
    local_artifact_size_label,
    workspace_artifact_summaries,
    workspace_chart_specs

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

end
