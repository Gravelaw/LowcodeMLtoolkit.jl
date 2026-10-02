module JuliaFlowDataScienceProjectEvidence

using JSON3
using SHA

export require_result, require_tuning, require_evaluation, context_evaluation,
    require_model_artifact, require_evaluation_model_binding, require_evaluation_report_artifact,
    strict_evidence_mode, read_result

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

function context_evaluation(project, context::AbstractDict, mode::AbstractString, action::AbstractString;
    required::Bool = false, resolve_path::Union{Nothing,Function} = nothing)
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
    get(validation, "projectId", "") == project.project_id || unavailable(action)
    execution = get(report, "executionEvidence", Dict{String,Any}())
    execution_id = get(execution, "executionId", "")
    !isempty(execution_id) && get(execution, "status", "") == "completed" || unavailable(action)
    get(validation, "executionId", "") == execution_id || unavailable(action)
    jobs = [job for job in project.project_jobs if
        get(job, "jobType", "") == "final_evaluation" && get(job, "status", "") == "completed" &&
        get(job, "projectId", "") == project.project_id &&
        get(job, "sourceRecordId", "") == get(report, "evaluationReportId", "") &&
        get(job, "datasetId", "") == get(validation, "datasetId", "") &&
        get(job, "splitPlanId", "") == get(report, "splitPlanId", "") &&
        get(get(job, "executionEvidence", Dict{String,Any}()), "executionId", "") == execution_id]
    length(jobs) == 1 || unavailable(action)
    resolve_path === nothing && unavailable(action)
    require_evaluation_report_artifact(report, mode, action, resolve_path)
    required && get(report, "approved", false) !== true && unavailable(action)
    return report
end

"""Verify the canonical producer report file against the retained logical report."""
function require_evaluation_report_artifact(report::AbstractDict, mode::AbstractString,
    action::AbstractString, resolve_path::Function)
    strict_evidence_mode(mode) || return nothing
    validation = get(report, "validationEvidence", Dict{String,Any}())
    project_id = get(validation, "projectId", "")
    report_id = get(report, "evaluationReportId", "")
    for token in (project_id, report_id)
        token isa AbstractString && occursin(r"^[A-Za-z0-9._-]+$", token) && !(token in (".", "..")) || unavailable(action)
    end
    canonical_ref = "local://evaluation/$(project_id)/$(report_id)/report.json"
    refs = [ref for ref in get(report, "artifactRefs", Any[]) if
        ref isa AbstractDict && get(ref, "kind", "") == "final_evaluation_report"]
    length(refs) == 1 || unavailable(action)
    ref = only(refs)
    get(ref, "path", "") == canonical_ref || unavailable(action)
    !haskey(ref, "artifactRef") || ref["artifactRef"] == canonical_ref || unavailable(action)
    checksum = get(ref, "checksumSha256", "")
    checksum isa AbstractString && occursin(r"^[a-f0-9]{64}$", checksum) || unavailable(action)
    path = resolve_path(canonical_ref)
    isfile(path) || unavailable(action)
    # File bytes are not numeric evidence; the value-count guard would otherwise
    # reject valid reports solely because their serialized text exceeds 100 KiB.
    bytes = try
        read(path)
    catch err
        (err isa SystemError || err isa Base.IOError) && unavailable(action)
        rethrow()
    end
    bytes2hex(sha256(bytes)) == checksum || unavailable(action)
    stored = try
        JSON3.read(String(bytes), Dict{String,Any})
    catch
        unavailable(action)
    end
    expected = Dict{String,Any}(key => get(report, key, nothing) for key in
        ("evaluationReportId", "trainingPlanId", "splitPlanId", "metrics", "approved",
            "finalTestOnly", "validationEvidence", "generatedAt"))
    # The producer writes the report before creating its execution/job. Only this
    # subsequently attached field is absent from the canonical file.
    expected["validationEvidence"] = Dict{String,Any}(String(key) => value for (key, value) in pairs(validation) if String(key) != "executionId")
    stored == expected || unavailable(action)
    return stored
end

"""Bind a verified model payload to the server-produced final evaluation and frozen source."""
function require_evaluation_model_binding(project, report::AbstractDict, payload::AbstractDict,
    model_artifact::AbstractDict, mode::AbstractString, action::AbstractString, resolve_path::Function)
    strict_evidence_mode(mode) || return nothing
    validation = get(report, "validationEvidence", Dict{String,Any}())
    evidence = get(validation, "evaluationDataEvidence", Dict{String,Any}())
    get(payload, "projectId", "") == project.project_id == get(validation, "projectId", "") || unavailable(action)
    get(payload, "datasetId", "") == get(validation, "datasetId", "") || unavailable(action)
    get(payload, "splitPlanId", "") == get(report, "splitPlanId", "") == get(validation, "splitPlanId", "") || unavailable(action)
    get(payload, "targetColumn", "") == get(evidence, "targetColumn", "") || unavailable(action)
    reference = get(model_artifact, "artifactRef", "")
    checksum = get(model_artifact, "checksumSha256", "")
    !isempty(reference) && occursin(r"^[a-f0-9]{64}$", checksum) || unavailable(action)
    get(evidence, "modelArtifactRef", "") == reference || unavailable(action)
    get(evidence, "modelArtifactChecksumSha256", "") == checksum || unavailable(action)
    for key in ("sourceChecksumSha256", "splitPlanChecksumSha256", "membershipChecksumSha256")
        digest = get(payload, key, "")
        occursin(r"^[a-f0-9]{64}$", digest) && digest == get(validation, key, "") || unavailable(action)
    end
    dataset = [record for record in project.datasets if get(record, "datasetId", "") == get(payload, "datasetId", "")]
    length(dataset) == 1 || unavailable(action)
    source_ref = get(payload, "sourceRef", "")
    source_ref == get(only(dataset), "sourceUri", "") == get(evidence, "sourceRef", "") || unavailable(action)
    source_path = resolve_path(source_ref)
    isfile(source_path) || unavailable(action)
    source_checksum = read_result(() -> open(io -> bytes2hex(sha256(io)), source_path, "r"), mode, action)
    source_checksum == get(payload, "sourceChecksumSha256", "") || unavailable(action)
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
