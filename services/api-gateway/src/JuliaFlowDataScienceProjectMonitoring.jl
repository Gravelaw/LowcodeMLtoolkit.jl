module JuliaFlowDataScienceProjectMonitoring

using ..JuliaFlowGatewayRepository
using ..JuliaFlowDataScienceProjectStatistics
using JSON3
using UUIDs

export project_prediction_export_for_drift,
    drift_metric_names,
    drift_threshold,
    monitoring_baseline_for_drift!,
    prediction_column_values_from_content,
    drift_metric_values_from_predictions,
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

function prediction_column_values_from_content(content::AbstractString, format::AbstractString)
    values = Float64[]
    if String(format) == "jsonl"
        for line in split(content, '\n')
            isempty(strip(line)) && continue
            row = JSON3.read(line, Dict{String,Any})
            haskey(row, "prediction") || continue
            parsed = tryparse(Float64, String(row["prediction"]))
            parsed === nothing || push!(values, parsed)
        end
        return values
    end
    lines = [line for line in split(content, '\n') if !isempty(strip(line))]
    isempty(lines) && return values
    headers = [strip(header) for header in split(lines[1], ',')]
    prediction_index = findfirst(header -> header == "prediction", headers)
    prediction_index === nothing && return values
    for line in lines[2:end]
        columns = [strip(column) for column in split(line, ',')]
        length(columns) >= prediction_index || continue
        parsed = tryparse(Float64, columns[prediction_index])
        parsed === nothing || push!(values, parsed)
    end
    return values
end

function drift_ks_statistic(left::Vector{Float64}, right::Vector{Float64})
    n = min(length(left), length(right))
    n == 0 && return 0.0
    left_values = sort(left[1:n])
    right_values = sort(right[1:n])
    combined = sort(unique(vcat(left_values, right_values)))
    isempty(combined) && return 0.0
    max_delta = 0.0
    for value in combined
        left_cdf = count(item -> item <= value, left_values) / n
        right_cdf = count(item -> item <= value, right_values) / n
        max_delta = max(max_delta, abs(left_cdf - right_cdf))
    end
    return round(max_delta; digits = 6)
end

function drift_psi_value(left::Vector{Float64}, right::Vector{Float64})
    n = min(length(left), length(right))
    n == 0 && return 0.0
    left_values = left[1:n]
    right_values = right[1:n]
    lower = min(minimum(left_values), minimum(right_values))
    upper = max(maximum(left_values), maximum(right_values))
    upper == lower && return 0.0
    bucket_count = min(10, max(2, n))
    epsilon = 1.0e-6
    psi = 0.0
    for bucket in 1:bucket_count
        bucket_lower = lower + (upper - lower) * (bucket - 1) / bucket_count
        bucket_upper = lower + (upper - lower) * bucket / bucket_count
        left_count = count(value -> bucket == bucket_count ? bucket_lower <= value <= bucket_upper : bucket_lower <= value < bucket_upper, left_values)
        right_count = count(value -> bucket == bucket_count ? bucket_lower <= value <= bucket_upper : bucket_lower <= value < bucket_upper, right_values)
        expected = max(left_count / n, epsilon)
        actual = max(right_count / n, epsilon)
        psi += (actual - expected) * log(actual / expected)
    end
    return round(max(0.0, psi); digits = 6)
end

function drift_metric_values_from_predictions(metric_names::AbstractVector, baseline_predictions::Vector{Float64}, current_predictions::Vector{Float64})
    n = min(length(baseline_predictions), length(current_predictions))
    n == 0 && return nothing
    baseline = baseline_predictions[1:n]
    current = current_predictions[1:n]
    mean_delta = abs(JuliaFlowDataScienceProjectStatistics.sample_mean(current) - JuliaFlowDataScienceProjectStatistics.sample_mean(baseline))
    baseline_scale = max(abs(JuliaFlowDataScienceProjectStatistics.sample_mean(baseline)), 1.0)
    metrics = Dict{String,Any}()
    for metric in metric_names
        key = String(metric)
        normalized = safe_drift_token(key)
        metrics[key] = if normalized in ("psi", "population-stability", "population-stability-index")
            drift_psi_value(baseline, current)
        elseif normalized in ("ks", "kolmogorov-smirnov")
            drift_ks_statistic(baseline, current)
        elseif normalized in ("mean-shift", "mean-delta")
            round(min(1.0, mean_delta / baseline_scale); digits = 6)
        else
            round(min(1.0, mean_delta / baseline_scale); digits = 6)
        end
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
