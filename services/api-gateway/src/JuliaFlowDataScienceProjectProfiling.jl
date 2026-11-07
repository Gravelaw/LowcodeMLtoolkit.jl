module JuliaFlowDataScienceProjectProfiling

export local_csv_profile, normalize_profile_request

const MAX_PROFILE_ROWS = 1_000
const MAX_PROFILE_BYTES = 8 * 1024 * 1024
const MISSING_VALUES = Set(["", "missing", "na", "null", "nothing"])

"Validate import request strings before any managed-file or project mutation."
function normalize_profile_request(body::AbstractDict)
    normalized = Dict{String,Any}(String(key) => value for (key, value) in pairs(body))
    for field in ("datasetId", "datasetName", "datasetRole", "projectId", "sourceUri", "format", "targetZone", "readMode", "connector")
        haskey(normalized, field) || continue
        value = normalized[field]
        value isa AbstractString || error("local data import $(field) must be a nonempty string")
        text = strip(String(value))
        isempty(text) && error("local data import $(field) must be a nonempty string")
        any(character -> character in ('\0', '\r', '\n'), text) && error("local data import $(field) contains invalid characters")
        normalized[field] = text
    end
    return normalized
end

"Read and validate rows in the bounded local profiling envelope."
function read_profile_rows(path::AbstractString)
    filesize(path) <= MAX_PROFILE_BYTES || error("local data import CSV profile supports files up to 8 MiB")
    lines = readlines(path)
    isempty(lines) && error("local data import CSV profile requires a header")
    # The downstream statistical reader has the same unquoted CSV envelope.
    any(line -> occursin('"', line), lines) && error("local data import quoted CSV is unsupported by local profiling and downstream analysis")
    headers = [String(strip(value)) for value in split(first(lines), ','; keepempty = true)]
    (isempty(headers) || any(isempty, headers) || length(unique(headers)) != length(headers)) &&
        error("local data import CSV profile requires nonempty unique headers")
    rows = Vector{Vector{String}}()
    for (row_number, line) in enumerate(lines[2:end])
        line_number = row_number + 1
        isempty(strip(line)) && error("local data import CSV profile does not support blank data lines (line $(line_number))")
        values = [String(strip(value)) for value in split(line, ','; keepempty = true)]
        length(values) == length(headers) || error("local data import CSV profile column count mismatch at line $(line_number)")
        push!(rows, values)
        length(rows) <= MAX_PROFILE_ROWS || error("local data import CSV profile supports at most 1,000 rows")
    end
    isempty(rows) && error("local data import CSV profile requires at least one data row")
    return headers, rows
end

function profile_columns(headers, rows)
    schema = Dict{String,Any}[]
    summary = Dict{String,Any}[]
    missing_total = 0
    for (column_index, header) in enumerate(headers)
        values = [row[column_index] for row in rows]
        present = [value for value in values if !(lowercase(value) in MISSING_VALUES)]
        missing_count = length(values) - length(present)
        missing_total += missing_count
        numeric = !isempty(present) && all(value -> begin
            parsed = tryparse(Float64, value)
            parsed !== nothing && isfinite(parsed)
        end, present)
        column_type = numeric ? "Float64" : "String"
        push!(schema, Dict("name" => header, "type" => column_type))
        field = Dict{String,Any}(
            "name" => header, "type" => column_type, "role" => "feature",
            "missingCount" => missing_count, "distinctCount" => length(unique(present)),
            "quality" => "Measured from $(length(rows)) local CSV rows",
        )
        if numeric
            numbers = parse.(Float64, present)
            numeric_summary = Dict{String,Any}("count" => length(numbers), "minimum" => minimum(numbers), "maximum" => maximum(numbers), "mean" => sum(value / length(numbers) for value in numbers))
            isfinite(numeric_summary["mean"]) || error("local data import CSV numeric summary exceeds finite range")
            field["numericSummary"] = numeric_summary
            field["quality"] *= "; min=$(numeric_summary["minimum"]), max=$(numeric_summary["maximum"]), mean=$(numeric_summary["mean"])"
        end
        push!(summary, field)
    end
    return schema, summary, missing_total
end

function profile_value_count_plot(headers, rows)
    plots = Dict{String,Any}[]
    for (column_index, header) in enumerate(headers)
        counts = Dict{Union{Nothing,String},Int}()
        for row in rows
            value = row[column_index]
            category = lowercase(value) in MISSING_VALUES ? nothing : value
            counts[category] = get(counts, category, 0) + 1
        end
        length(counts) <= 12 || continue
        missing_label = "(missing)"
        for _ in 1:(length(counts) + 1)
            haskey(counts, missing_label) || break
            missing_label *= " [missing cells]"
        end
        categories = sort(collect(keys(counts)); by = key -> key === nothing ? (0, "") : (1, key))
        push!(plots, Dict(
            "plotId" => "value-counts-$(column_index)", "title" => "$(header) value counts",
            "kind" => "bar", "field" => header,
            "values" => [Dict("label" => category === nothing ? missing_label : category,
                "value" => counts[category], "missing" => category === nothing) for category in categories],
        ))
        break
    end
    return plots
end

function profile_preview_value(value::AbstractString, column_type::AbstractString)
    lowercase(value) in MISSING_VALUES && return nothing
    return column_type == "Float64" ? parse(Float64, value) : value
end

"""
    local_csv_profile(path::AbstractString)

Read an unquoted, unique-header CSV with 1–1,000 rows and at most 8 MiB. Return
file-derived schema, missing/distinct counts, numeric summaries, preview, and plots.
Reject malformed or unsupported inputs; never create artifacts or mutate the file.
"""
function local_csv_profile(path::AbstractString)
    headers, rows = read_profile_rows(path)
    schema, summary, missing_total = profile_columns(headers, rows)
    preview = [Dict{String,Any}(headers[index] => profile_preview_value(row[index], schema[index]["type"])
        for index in eachindex(headers)) for row in Iterators.take(rows, 5)]
    plots = profile_value_count_plot(headers, rows)
    checks = Dict{String,Any}[
        Dict("checkId" => "csv-shape", "label" => "CSV row shape", "status" => "passed", "detail" => "All $(length(rows)) rows match $(length(headers)) unique headers."),
        Dict("checkId" => "missingness", "label" => "Missing values", "status" => missing_total == 0 ? "passed" : "warning", "detail" => "$(missing_total) empty or missing-marked cells across the file."),
    ]
    return Dict{String,Any}(
        "rowCount" => length(rows), "schemaSummary" => schema, "profileSummary" => summary,
        "previewRows" => preview, "qualityChecks" => checks, "quickPlots" => plots,
        "workflowReadiness" => Dict("downstreamReady" => false, "targetColumn" => "", "trainTestSplit" => "not_planned", "leakageWarnings" => String[], "recommendedNextAction" => "Review schema and create a split plan before training."),
        "profileScope" => "complete_unquoted_csv_1000_rows",
    )
end

end
