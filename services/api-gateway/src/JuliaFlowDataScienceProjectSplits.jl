module JuliaFlowDataScienceProjectSplits

using SHA
using JSON3
using Dates
using Arrow
using ..JuliaFlowGatewayRepository

export split_table, split_rows, training_numeric_columns, require_numeric_rows,
    plan_fingerprint, prepare_membership!, persist_membership!, protect_membership!, require_membership_evidence

split_error(message) = error("split membership $(message)")
source_error(message) = error("source evidence unavailable; $(message)")
const PLAN_FIELDS = ("splitPlanId", "datasetId", "strategy", "trainFraction", "validationFraction", "testFraction", "groupColumn", "timeColumn", "depthColumn", "seed", "locked")
plan_fingerprint(plan) = bytes2hex(sha256(JSON3.write([get(plan, key, nothing) for key in PLAN_FIELDS])))

function split_table(path::AbstractString)
    # This bounded execution lane deliberately rejects CSV forms it cannot interpret.
    lines = open(path, "r") do io
        collect(Iterators.take(eachline(io), 1002))
    end
    2 <= length(lines) <= 1001 || source_error("requires 1 to 1000 complete CSV rows")
    any(line -> occursin('"', line), lines) && source_error("quoted CSV is unsupported in this execution lane")
    headers = String.(strip.(split(first(lines), ',')))
    all(!isempty, headers) && allunique(headers) || source_error("requires unique nonempty CSV headers")
    rows = [String.(strip.(split(line, ','; keepempty = true))) for line in lines[2:end]]
    all(row -> length(row) == length(headers), rows) || source_error("CSV row width does not match its header")
    return Dict{String,Any}("headers" => headers, "rows" => rows)
end

function validate_plan(plan)
    get(plan, "locked", false) === true || split_error("requires a locked plan")
    strategy = get(plan, "strategy", "")
    strategy in ("random", "stratified", "grouped", "time", "depth") || split_error("strategy is unsupported")
    fractions = Float64[get(plan, key, 0.0) for key in ("trainFraction", "validationFraction", "testFraction")]
    all(x -> isfinite(x) && 0 < x < 1, fractions) && isapprox(sum(fractions), 1.0; atol = 1e-8) || split_error("fractions must be positive and sum to one")
    return strategy, fractions
end

function column_values(table, name)
    index = findfirst(==(name), table["headers"])
    index === nothing && split_error("declared column is missing")
    values = [row[index] for row in table["rows"]]
    all(value -> !isempty(value) && !(lowercase(value) in ("na", "null", "missing", "nothing")), values) || split_error("declared grouping/order column has missing values")
    return values
end

function partition_groups(groups, fractions)
    length(groups) >= 3 || split_error("requires at least three independent groups")
    counts = cumsum(length.(groups))
    total = last(counts)
    first_cut = argmin([abs(counts[i] - total * fractions[1]) for i in 1:length(groups)-2])
    candidates = (first_cut + 1):(length(groups) - 1)
    second_cut = candidates[argmin([abs(counts[i] - total * (fractions[1] + fractions[2])) for i in candidates])]
    return Dict("train" => vcat(groups[1:first_cut]...),
        "validation" => vcat(groups[first_cut+1:second_cut]...), "test" => vcat(groups[second_cut+1:end]...))
end

function split_rows(table, plan, target_column::AbstractString)
    strategy, fractions = validate_plan(plan)
    n = length(table["rows"])
    n >= 4 || source_error("split execution requires at least four rows")
    seed = get(plan, "seed", 0)
    order_key(value) = bytes2hex(sha256(string(seed, ":", value)))
    result = if strategy == "random"
        partition_groups([[i] for i in sort(collect(1:n); by = order_key)], fractions)
    elseif strategy == "stratified"
        isempty(target_column) && split_error("stratified plans require a target column")
        labels = column_values(table, target_column)
        classes = sort(unique(labels))
        2 <= length(classes) <= 20 || split_error("stratification supports 2 to 20 discrete classes")
        combined = Dict("train" => Int[], "validation" => Int[], "test" => Int[])
        for label in classes
            indices = findall(==(label), labels)
            length(indices) >= 3 || split_error("each stratification class requires three rows")
            part = partition_groups([[i] for i in sort(indices; by = order_key)], fractions)
            for split in keys(combined)
                append!(combined[split], part[split])
            end
        end
        combined
    else
        key = strategy == "grouped" ? "groupColumn" : strategy == "time" ? "timeColumn" : "depthColumn"
        values = column_values(table, String(get(plan, key, "")))
        ordered_values = if strategy == "depth"
            parsed = tryparse.(Float64, values)
            all(value -> value !== nothing && isfinite(value), parsed) || split_error("depth requires finite numeric values")
            Float64.(parsed)
        elseif strategy == "time"
            parsed = [tryparse(DateTime, replace(value, r"Z$" => "")) for value in values]
            all(!isnothing, parsed) || split_error("time requires ISO dates/times in a common time zone")
            DateTime.(parsed)
        else
            values
        end
        labels = strategy == "grouped" ? sort(unique(ordered_values); by = order_key) : sort(unique(ordered_values))
        partition_groups([findall(==(label), ordered_values) for label in labels], fractions)
    end
    length(result["train"]) >= 2 || split_error("requires at least two training rows")
    foreach(sort!, Base.values(result))
    return result
end

function training_numeric_columns(table, train_rows)
    n = length(table["rows"])
    columns = Dict{String,Vector{Float64}}()
    for (index, header) in enumerate(table["headers"])
        # Held-out values never decide feature eligibility; retain their row positions.
        train_values = [tryparse(Float64, table["rows"][row][index]) for row in train_rows]
        all(value -> value !== nothing && isfinite(value), train_values) || continue
        columns[String(header)] = [something(tryparse(Float64, table["rows"][row][index]), NaN) for row in 1:n]
    end
    return columns
end

function require_numeric_rows(columns, names, rows)
    all(name -> haskey(columns, name) && all(row -> isfinite(columns[name][row]), rows), names) || source_error("required numeric values are unavailable in the selected rows")
    return nothing
end

row_ref(checksum, index) = "sha256:$(checksum)#row:$(index)"
file_checksum(path) = open(io -> bytes2hex(sha256(io)), path, "r")
membership_checksum(rows) = bytes2hex(sha256(JSON3.write([rows[key] for key in ("train", "validation", "test")])))

function require_membership_evidence(evidence, membership)
    for key in ("sourceChecksumSha256", "splitPlanChecksumSha256", "membershipChecksumSha256")
        get(evidence, key, "") == membership[key] || source_error("upstream result does not match the frozen split evidence")
    end
    return nothing
end

function validate_rows(rows, table, plan, target)
    n = length(table["rows"])
    combined = vcat(rows["train"], rows["validation"], rows["test"])
    length(combined) == n && sort(combined) == collect(1:n) || split_error("rows must be complete, unique and disjoint")
    length(rows["train"]) >= 2 && !isempty(rows["validation"]) && !isempty(rows["test"]) || split_error("train/validation/test rows are incomplete")
    # Rechecking stratification labels here would inspect final-test labels during tuning.
    # Their original snapshot and plan are bound by checksums; never resplit them.
    if get(plan, "strategy", "") != "stratified"
        rows == split_rows(table, plan, target) || split_error("stored rows do not match the declared strategy/seed")
    end
    return rows
end

function prepare_membership!(project, plan, table, checksum::AbstractString, target::AbstractString, resolve_path::Function)
    validate_plan(plan)
    plan_id = String(get(plan, "splitPlanId", ""))
    dataset_id = String(get(plan, "datasetId", ""))
    isempty(plan_id) && split_error("plan id is required")
    fingerprint = plan_fingerprint(plan)
    assignments = [record for record in project.split_assignments if get(record, "splitPlanId", "") == plan_id]
    folds = [record for record in project.validation_folds if get(record, "splitPlanId", "") == plan_id]
    locks = [record for record in project.final_test_locks if get(record, "splitPlanId", "") == plan_id]
    length(locks) <= 1 || split_error("requires exactly one final-test lock")
    if !isempty(locks)
        all(key -> get(only(locks), key, "") isa AbstractString && !isempty(strip(get(only(locks), key, ""))), ("lockId", "lockedAt", "reason", "lockedBy")) || split_error("final-test lock is incomplete")
        tryparse(DateTime, replace(String(only(locks)["lockedAt"]), r"Z$" => "")) !== nothing || split_error("lock timestamp is invalid")
    end
    directory = "local://splits/" * first(bytes2hex(sha256(project.project_id * ":" * plan_id)), 24) * "/" * first(String(checksum), 16) * "-" * first(fingerprint, 16)
    refs = Dict(split => "$(directory)/$(split).arrow" for split in ("train", "validation", "test"))
    is_new = isempty(assignments)
    rows = Dict("train" => Int[], "validation" => Int[], "test" => Int[])
    if is_new
        isempty(folds) || split_error("provided folds require complete persisted assignments; external/kfold refs are unsupported")
        rows = split_rows(table, plan, target)
    else
        length(folds) == 1 && length(locks) == 1 || split_error("persisted assignments require one verified fold and lock")
        for record in assignments
            get(record, "datasetId", "") == dataset_id || split_error("assignment dataset mismatch")
            split = get(record, "split", "")
            haskey(rows, split) || split_error("unsupported assignment split")
            ref = get(record, "rowRef", "")
            startswith(ref, "sha256:$(checksum)#row:") || source_error("split source checksum changed or historical membership lacks source proof")
            index = tryparse(Int, last(Base.split(ref, "#row:")))
            index !== nothing && 1 <= index <= length(table["rows"]) || split_error("row reference is invalid")
            push!(rows[split], index)
        end
        ids = [get(record, "splitAssignmentId", "") for record in assignments]
        all(id -> id isa AbstractString && !isempty(id), ids) && allunique(ids) || split_error("assignment ids must be nonempty and unique")
        foreach(sort!, Base.values(rows))
    end
    validate_rows(rows, table, plan, target)
    digest = membership_checksum(rows)
    if is_new
        assignments = [Dict{String,Any}("splitAssignmentId" => "$(plan_id)-row-$(index)", "splitPlanId" => plan_id,
            "datasetId" => dataset_id, "split" => split, "rowRef" => row_ref(checksum, index))
            for split in ("train", "validation", "test") for index in rows[split]]
        timestamp = JuliaFlowGatewayRepository.JuliaFlowExecutionService.iso8601_timestamp()
        lock = isempty(locks) ? Dict{String,Any}("lockId" => "lock-$(plan_id)", "splitPlanId" => plan_id,
            "lockedAt" => timestamp, "reason" => "Materialized the requested locked plan before local execution.", "lockedBy" => "local-gateway") : deepcopy(only(locks))
        merge!(lock, Dict("sourceChecksumSha256" => String(checksum), "splitPlanChecksumSha256" => fingerprint,
            "membershipChecksumSha256" => digest, "testRef" => refs["test"]))
        fold = Dict{String,Any}("foldId" => "fold-$(plan_id)-1", "splitPlanId" => plan_id, "strategy" => plan["strategy"], "index" => 1,
            "trainRef" => refs["train"], "validationRef" => refs["validation"], "sourceChecksumSha256" => String(checksum),
            "splitPlanChecksumSha256" => fingerprint, "membershipChecksumSha256" => digest)
        append!(project.split_assignments, assignments)
        push!(project.validation_folds, fold)
        project.final_test_locks = [record for record in project.final_test_locks if get(record, "splitPlanId", "") != plan_id]
        push!(project.final_test_locks, lock)
    else
        fold, lock = only(folds), only(locks)
        get(fold, "foldId", "") isa AbstractString && !isempty(strip(get(fold, "foldId", ""))) || split_error("fold id is required")
        get(fold, "index", 0) == 1 && get(fold, "strategy", "") == plan["strategy"] || split_error("fold strategy/index is unsupported")
        for record in (fold, lock)
            get(record, "sourceChecksumSha256", "") == checksum || source_error("stored membership source proof is unavailable")
            get(record, "splitPlanChecksumSha256", "") == fingerprint || split_error("locked plan was changed; create a new plan")
            get(record, "membershipChecksumSha256", "") == digest || split_error("stored membership checksum mismatch")
        end
        for (split, record, ref_key, checksum_key) in (("train", fold, "trainRef", "trainChecksumSha256"),
            ("validation", fold, "validationRef", "validationChecksumSha256"), ("test", lock, "testRef", "testChecksumSha256"))
            get(record, ref_key, "") == refs[split] || split_error("fold/lock reference mismatch")
            path = resolve_path(refs[split])
            isfile(path) || split_error("membership artifact is missing")
            get(record, checksum_key, "") == file_checksum(path) || split_error("membership artifact checksum mismatch")
            artifact = Arrow.Table(read(path))
            collect(artifact.rowIndex) == rows[split] && String.(artifact.rowRef) == [row_ref(checksum, i) for i in rows[split]] || split_error("fold artifact row mismatch")
        end
    end
    return Dict{String,Any}("rows" => rows, "refs" => refs, "fold" => fold, "lock" => lock, "new" => is_new,
        "sourceChecksumSha256" => String(checksum), "splitPlanChecksumSha256" => fingerprint, "membershipChecksumSha256" => digest)
end

function persist_membership!(membership, resolve_path::Function)
    membership["new"] || return membership
    for (split, record, key) in (("train", membership["fold"], "trainChecksumSha256"),
        ("validation", membership["fold"], "validationChecksumSha256"), ("test", membership["lock"], "testChecksumSha256"))
        rows = membership["rows"][split]
        path = resolve_path(membership["refs"][split])
        mkpath(dirname(path))
        Arrow.write(path, (rowIndex = rows, rowRef = [row_ref(membership["sourceChecksumSha256"], i) for i in rows]))
        record[key] = file_checksum(path)
    end
    membership["new"] = false
    return membership
end

function protect_membership!(existing, body)
    existing === nothing && return nothing
    protected = Set(get(record, "splitPlanId", "") for record in existing.split_assignments)
    isempty(protected) && return nothing
    normalize = JuliaFlowGatewayRepository.JuliaFlowProjectPayloadValidation.contract_value
    for (field, records) in (("splitPlans", existing.split_plans), ("splitAssignments", existing.split_assignments),
        ("validationFolds", existing.validation_folds), ("finalTestLocks", existing.final_test_locks))
        haskey(body, field) || continue
        before = [normalize(record) for record in records if get(record, "splitPlanId", "") in protected]
        after = [normalize(record) for record in body[field] if get(record, "splitPlanId", "") in protected]
        before == after || split_error("persisted assignments, folds, locks and plans are immutable; create a new plan id")
    end
    return nothing
end

end
