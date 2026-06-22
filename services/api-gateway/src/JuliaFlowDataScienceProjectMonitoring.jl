module JuliaFlowDataScienceProjectMonitoring

using ..JuliaFlowGatewayRepository
using UUIDs

export project_prediction_export_for_drift,
    drift_metric_names,
    drift_threshold,
    monitoring_baseline_for_drift!,
    drift_metric_values,
    drift_status,
    drift_report_record,
    drift_output_refs

function safe_drift_token(value::AbstractString)
    normalized = lowercase(strip(String(value)))
    normalized = replace(normalized, r"[^a-z0-9._-]+" => "-")
    normalized = strip(normalized, ['-', '.', '_'])
    isempty(normalized) && return ""
    return first(normalized, min(lastindex(normalized), 80))
end

function project_prediction_export_for_drift(project::JuliaFlowGatewayRepository.DataScienceProjectRecord, body::AbstractDict)
    isempty(project.prediction_exports) && error("drift report prerequisite prediction export required")
    if haskey(body, "predictionExportId")
        export_id = String(body["predictionExportId"])
        match = findfirst(export_record -> String(get(export_record, "predictionExportId", "")) == export_id, project.prediction_exports)
        match === nothing && error("drift report prerequisite prediction export not found: $(export_id)")
        return project.prediction_exports[match]
    end
    return project.prediction_exports[1]
end

function drift_metric_names(body::AbstractDict)
    raw_metrics = haskey(body, "metricNames") ? body["metricNames"] : ["psi", "ks"]
    raw_metrics isa AbstractVector || error("drift report metricNames must be an array")
    metrics = [safe_drift_token(String(metric)) for metric in raw_metrics]
    metrics = [metric for metric in metrics if !isempty(metric)]
    isempty(metrics) && error("drift report metric required")
    return metrics
end

function drift_threshold(body::AbstractDict)
    threshold = haskey(body, "threshold") ? Float64(body["threshold"]) : 0.2
    0.0 <= threshold <= 1.0 || error("drift report threshold must be between 0 and 1")
    return threshold
end

function monitoring_baseline_for_drift!(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    body::AbstractDict,
    dataset_id::AbstractString,
    prediction_export::AbstractDict,
    metric_names::AbstractVector,
    timestamp::AbstractString,
)
    if haskey(body, "baselineId")
        baseline_id = String(body["baselineId"])
        match = findfirst(baseline -> String(get(baseline, "baselineId", "")) == baseline_id, project.monitoring_baselines)
        match !== nothing && return project.monitoring_baselines[match]
    else
        match = findfirst(
            baseline -> String(get(baseline, "predictionExportId", "")) == String(get(prediction_export, "predictionExportId", "")),
            project.monitoring_baselines,
        )
        match !== nothing && return project.monitoring_baselines[match]
    end
    baseline_id = haskey(body, "baselineId") ? String(body["baselineId"]) : "baseline-" * replace(string(uuid4()), "-" => "")
    baseline = Dict{String,Any}(
        "baselineId" => baseline_id,
        "modelId" => String(get(prediction_export, "evaluationReportId", "approved-final-evaluation")),
        "datasetId" => String(dataset_id),
        "metricNames" => String.(metric_names),
        "predictionExportId" => String(get(prediction_export, "predictionExportId", "")),
        "evaluationReportId" => String(get(prediction_export, "evaluationReportId", "")),
        "createdAt" => String(timestamp),
    )
    project.monitoring_baselines = [baseline, project.monitoring_baselines...]
    return baseline
end

function drift_metric_values(metric_names::AbstractVector)
    metrics = Dict{String,Any}()
    for (index, metric) in enumerate(metric_names)
        metrics[String(metric)] = round(min(1.0, 0.08 * index); digits = 4)
    end
    return metrics
end

function drift_status(metrics::AbstractDict, threshold::Real)
    max_metric = maximum(Float64(value) for value in values(metrics))
    return max_metric >= Float64(threshold) * 2 ? "high" : max_metric >= Float64(threshold) ? "moderate" : "low"
end

function drift_report_record(
    project::JuliaFlowGatewayRepository.DataScienceProjectRecord,
    baseline::AbstractDict,
    prediction_export::AbstractDict,
    dataset_id::AbstractString,
    metrics::AbstractDict,
    status::AbstractString,
    timestamp::AbstractString;
    report_id::AbstractString = "drift-" * replace(string(uuid4()), "-" => ""),
)
    return Dict{String,Any}(
        "driftReportId" => String(report_id),
        "baselineId" => String(get(baseline, "baselineId", "")),
        "status" => String(status),
        "metrics" => Dict{String,Any}(String(key) => value for (key, value) in pairs(metrics)),
        "validationEvidence" => Dict{String,Any}(
            "projectId" => project.project_id,
            "datasetId" => String(dataset_id),
            "predictionExportId" => String(get(prediction_export, "predictionExportId", "")),
            "evaluationReportId" => String(get(prediction_export, "evaluationReportId", "")),
            "outputContractRef" => String(get(prediction_export, "outputContractRef", "")),
        ),
        "generatedAt" => String(timestamp),
    )
end

function drift_output_refs(project_id::AbstractString, report_id::AbstractString, timestamp::AbstractString)
    return [
        Dict(
            "refId" => "artifact-$(String(report_id))",
            "kind" => "drift_report",
            "localOnly" => true,
            "path" => "local://drift/$(String(project_id))/$(String(report_id))/report.json",
            "generatedAt" => String(timestamp),
        ),
    ]
end

end
