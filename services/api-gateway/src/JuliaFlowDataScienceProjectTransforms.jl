module JuliaFlowDataScienceProjectTransforms

using ..JuliaFlowDataScienceProjectSplits
using ..JuliaFlowDataScienceProjectStatistics
using Arrow
using SHA

export transform_apply_splits,
    transform_ref_for_request,
    transform_fit_apply_artifact_refs,
    transform_fit_apply_record,
    prepare_numeric_fit_apply,
    persist_numeric_fit_apply!

function prepare_numeric_fit_apply(project, dataset_id, membership, apply_splits, transform_ref)
    default_ref = "local://transforms/$(project.project_id)/default-fit-apply.jl"
    transform_ref == default_ref || error("transform fit/apply custom transform execution is unsupported")
    all(split -> split in ("validation", "test"), apply_splits) || error("transform fit/apply evaluation membership is unavailable")
    schemas = [schema for schema in project.schema_contracts if get(schema, "datasetId", "") == dataset_id]
    length(schemas) == 1 || error("transform fit/apply requires one schema contract")
    roles = Dict(get(column, "name", "") => get(column, "role", "feature") for column in get(only(schemas), "columns", Any[]))
    count(==("target"), values(roles)) == 1 || error("transform fit/apply requires an explicit target role")
    rows = membership["rows"]
    numeric = JuliaFlowDataScienceProjectSplits.training_numeric_columns(membership["table"], rows["train"])
    features = sort([name for name in keys(numeric) if get(roles, name, "ignore") == "feature"])
    isempty(features) && error("transform fit/apply numeric training features are unavailable")
    any(name -> startswith(name, "_juliaflow_"), features) && error("transform fit/apply reserved column name")
    means = [sum(numeric[name][rows["train"]]) / length(rows["train"]) for name in features]
    scales = [max(sqrt(sum((value - means[i])^2 for value in numeric[name][rows["train"]]) / length(rows["train"])), eps(Float64)) for (i, name) in enumerate(features)]
    all(isfinite, means) && all(isfinite, scales) || error("source evidence unavailable; fitted transform parameters are not finite")
    outputs = Dict{String,Any}()
    for split in apply_splits
        JuliaFlowDataScienceProjectSplits.require_numeric_rows(numeric, features, rows[split])
        outputs[split] = (; _juliaflow_row_index = rows[split],
            (Symbol(name) => [(numeric[name][row] - means[i]) / scales[i] for row in rows[split]] for (i, name) in enumerate(features))...)
        all(column -> all(isfinite, column), values(outputs[split])) || error("source evidence unavailable; transformed values are not finite")
    end
    return Dict{String,Any}("state" => (feature = features, mean = means, scale = scales), "outputs" => outputs,
        "trainingRowIndices" => rows["train"], "membershipChecksumSha256" => membership["membershipChecksumSha256"])
end

function persist_numeric_fit_apply!(prepared, refs, transform_ref, resolve_path::Function)
    for ref in refs
        path = resolve_path(ref["path"])
        mkpath(dirname(path))
        table = ref["kind"] == "transform_fit_state" ? prepared["state"] : prepared["outputs"][first(splitext(basename(path))) ]
        Arrow.write(path, table)
        ref["checksumSha256"] = open(io -> bytes2hex(sha256(io)), path, "r")
        ref["sizeBytes"] = filesize(path)
        ref["checksumMode"] = "streaming_file_sha256"
    end
    path = resolve_path(transform_ref)
    mkpath(dirname(path))
    write(path, "# Built-in frozen numeric standardization. Parameters are in fit-state.arrow.\nstandardize(value, mean, scale) = (value - mean) / scale\n")
    return refs
end

function transform_apply_splits(body::AbstractDict, split_plan::AbstractDict)
    raw_splits = haskey(body, "applySplits") ? body["applySplits"] : ["validation", "test"]
    raw_splits isa AbstractVector || error("transform fit/apply applySplits must be an array")
    splits = [String(item) for item in raw_splits]
    all(item -> item in ("validation", "test", "evaluation"), splits) || error("transform fit/apply can only apply to validation, test, or evaluation splits")
    "train" in splits && error("transform fit/apply cannot apply fitted state back to train as an apply split")
    if "validation" in splits
        Float64(get(split_plan, "validationFraction", 0.0)) > 0 || error("transform fit/apply validation split required")
    end
    if "test" in splits
        Float64(get(split_plan, "testFraction", 0.0)) > 0 || error("transform fit/apply test split required")
    end
    isempty(splits) && error("transform fit/apply apply split required")
    return unique(splits)
end

function transform_ref_for_request(body::AbstractDict, project_id::AbstractString)
    transform_ref = haskey(body, "transformRef") ? String(body["transformRef"]) : "local://transforms/$(String(project_id))/default-fit-apply.jl"
    isempty(strip(transform_ref)) && error("transform fit/apply transformRef required")
    return transform_ref
end

function transform_fit_apply_artifact_refs(
    project_id::AbstractString,
    run_id::AbstractString,
    apply_splits::AbstractVector,
    timestamp::AbstractString,
)
    artifact_refs = [
        Dict(
            "refId" => "artifact-$(String(run_id))-fit",
            "kind" => "transform_fit_state",
            "localOnly" => true,
            "path" => "local://transforms/$(String(project_id))/$(String(run_id))/fit-state.arrow",
            "generatedAt" => String(timestamp),
        ),
    ]
    for split in apply_splits
        split_name = String(split)
        push!(
            artifact_refs,
            Dict(
                "refId" => "artifact-$(String(run_id))-apply-$(split_name)",
                "kind" => "transform_apply_output",
                "localOnly" => true,
                "path" => "local://transforms/$(String(project_id))/$(String(run_id))/$(split_name).arrow",
                "generatedAt" => String(timestamp),
            ),
        )
    end
    return artifact_refs
end

function transform_fit_apply_record(
    run_id::AbstractString,
    dataset_id::AbstractString,
    split_plan::AbstractDict,
    apply_splits::AbstractVector,
    transform_ref::AbstractString,
    artifact_refs::AbstractVector,
    timestamp::AbstractString,
)
    return Dict{String,Any}(
        "transformRunId" => String(run_id),
        "datasetId" => String(dataset_id),
        "splitPlanId" => String(get(split_plan, "splitPlanId", "")),
        "fitSplit" => "train",
        "applySplits" => String.(apply_splits),
        "transformRef" => String(transform_ref),
        "leakageChecks" => [
            Dict("checkId" => "fit-split-train-only", "status" => "passed", "detail" => "Transform state is fit only on the training split."),
            Dict("checkId" => "heldout-apply-only", "status" => "passed", "detail" => "Frozen transform state is applied to held-out splits without refitting."),
        ],
        "artifactRefs" => [Dict{String,Any}(String(key) => value for (key, value) in pairs(ref)) for ref in artifact_refs],
        "createdAt" => String(timestamp),
    )
end

end
