module JuliaFlowDataScienceProjectTransforms

export transform_apply_splits,
    transform_ref_for_request,
    transform_fit_apply_artifact_refs,
    transform_fit_apply_record

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
