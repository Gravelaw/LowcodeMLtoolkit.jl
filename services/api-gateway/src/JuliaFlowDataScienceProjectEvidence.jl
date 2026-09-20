module JuliaFlowDataScienceProjectEvidence

using JSON3
using SHA

export require_result, require_tuning, require_evaluation, context_evaluation,
    require_model_artifact, strict_evidence_mode, read_result

strict_evidence_mode(mode::AbstractString) = !(mode in ("demo", "development"))
unavailable(action) = error("$(action) source evidence unavailable; real local evidence is required")

function finite_evidence(value)
    pending = Any[value]
    for _ in 1:100_000
        isempty(pending) && return true
        item = pop!(pending)
        if item isa AbstractDict
            append!(pending, values(item))
        elseif item isa AbstractVector
            append!(pending, item)
        elseif item isa Real
            isfinite(item) || return false
        end
    end
    return isempty(pending)
end

function require_result(result, mode::AbstractString, action::AbstractString)
    strict_evidence_mode(mode) || return result
    result === nothing && unavailable(action)
    isempty(result) && unavailable(action)
    finite_evidence(result) || unavailable(action)
    return result
end

function read_result(compute::Function, mode::AbstractString, action::AbstractString)
    result = try
        compute()
    catch err
        if strict_evidence_mode(mode) && (err isa SystemError || err isa Base.IOError)
            unavailable(action)
        end
        rethrow()
    end
    return require_result(result, mode, action)
end

function require_metrics(metrics, action)
    metrics isa AbstractDict && !isempty(metrics) || unavailable(action)
    all(value -> value isa Real && !(value isa Bool) && isfinite(value), values(metrics)) || unavailable(action)
    return metrics
end

function require_tuning(study::AbstractDict, mode::AbstractString, action::AbstractString)
    strict_evidence_mode(mode) || return study
    validation = get(study, "validationEvidence", Dict{String,Any}())
    get(validation, "tuningExecutionMode", "") == "local_csv_validation_tuning" || unavailable(action)
    trials = get(study, "trials", Any[])
    isempty(trials) && unavailable(action)
    for trial in trials
        require_metrics(get(trial, "metrics", nothing), action)
        evidence = get(trial, "validationEvidence", Dict{String,Any}())
        get(evidence, "executionMode", "") == "local_csv_validation_tuning" || unavailable(action)
        get(evidence, "trainRowCount", 0) >= 2 || unavailable(action)
        get(evidence, "validationRowCount", 0) > 0 || unavailable(action)
    end
    return study
end

function require_evaluation(report::AbstractDict, mode::AbstractString, action::AbstractString)
    strict_evidence_mode(mode) || return report
    get(report, "finalTestOnly", false) === true || unavailable(action)
    validation = get(report, "validationEvidence", Dict{String,Any}())
    get(validation, "finalTestPolicy", "") == "use_final_test" || unavailable(action)
    get(validation, "tuningExecutionMode", "") == "local_csv_validation_tuning" || unavailable(action)
    execution_mode = get(validation, "evaluationExecutionMode", "")
    execution_mode in ("local_csv_baseline", "local_csv_trained_artifact", "mlj_package_backed_final_evaluation") || unavailable(action)
    evidence = get(validation, "evaluationDataEvidence", Dict{String,Any}())
    get(evidence, "executionMode", "") == execution_mode || unavailable(action)
    startswith(get(evidence, "sourceRef", ""), "local://data/") || unavailable(action)
    get(evidence, "trainRowCount", 0) >= 2 || unavailable(action)
    get(evidence, "testRowCount", 0) > 0 || unavailable(action)
    require_metrics(get(report, "metrics", nothing), action)
    finite_evidence(evidence) || unavailable(action)
    return report
end

function context_evaluation(project, context::AbstractDict, mode::AbstractString, action::AbstractString; required::Bool = false)
    strict_evidence_mode(mode) || return nothing
    project === nothing && unavailable(action)
    report_id = get(context, "evaluationReportId", "")
    split_id = get(context, "splitPlanId", "")
    candidates = [report for report in project.evaluation_reports if
        (!isempty(report_id) ? get(report, "evaluationReportId", "") == report_id :
            (!isempty(split_id) && get(report, "splitPlanId", "") == split_id))]
    if isempty(candidates)
        (required || !isempty(report_id)) && unavailable(action)
        return nothing
    end
    report = first(candidates)
    isempty(split_id) || get(report, "splitPlanId", "") == split_id || unavailable(action)
    dataset_id = get(context, "datasetId", "")
    validation = get(report, "validationEvidence", Dict{String,Any}())
    isempty(dataset_id) || get(validation, "datasetId", "") == dataset_id || unavailable(action)
    require_evaluation(report, mode, action)
    required && get(report, "approved", false) !== true && unavailable(action)
    return report
end

function require_model_artifact(artifact, mode::AbstractString, action::AbstractString, resolve_path::Function)
    strict_evidence_mode(mode) || return nothing
    artifact isa AbstractDict || unavailable(action)
    reference = get(artifact, "artifactRef", "")
    startswith(reference, "local://models/") || unavailable(action)
    checksum = lowercase(get(artifact, "checksumSha256", ""))
    occursin(r"^[a-f0-9]{64}$", checksum) || unavailable(action)
    path = resolve_path(reference)
    isfile(path) || unavailable(action)
    actual = open(path, "r") do io
        bytes2hex(sha256(io))
    end
    actual == checksum || unavailable(action)
    payload = JSON3.read(read(path, String), Dict{String,Any})
    get(payload, "nativeModelKind", get(payload, "modelKind", "")) in
        ("local_csv_single_feature_ols", "local_csv_multi_feature_ols", "local_csv_binary_centroid_classifier") || unavailable(action)
    get(payload, "trainRowCount", 0) >= 2 || unavailable(action)
    require_metrics(get(payload, "metrics", nothing), action)
    finite_evidence(payload) || unavailable(action)
    return payload
end

end
