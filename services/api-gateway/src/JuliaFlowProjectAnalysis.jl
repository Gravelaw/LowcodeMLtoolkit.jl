module JuliaFlowProjectAnalysis

using JSON3, SHA
using ..JuliaFlowDataScienceProjectStatistics
using ..JuliaFlowDataScienceProjectProfiling

export schema_fingerprint, measured_profile, scoped_evidence, validate_workspace, report_response, replay_code

const Stats = JuliaFlowDataScienceProjectStatistics
const Profile = JuliaFlowDataScienceProjectProfiling

# Serialize keys in a stable order so a schema revision has the same identity after reload.
struct CanonicalToken
    text::String
end
function canonical(value)
    stack = Any[value]
    output = String[]
    steps = 0
    while !isempty(stack)
        steps += 1
        steps <= 200_000 || error("analysis identity exceeds the bounded canonicalization limit")
        item = pop!(stack)
        if item isa CanonicalToken
            push!(output, item.text)
        elseif item isa AbstractDict
            push!(output, "{"); push!(stack, CanonicalToken("}"))
            keys_sorted = sort(collect(keys(item)); by = String)
            for i in reverse(eachindex(keys_sorted))
                key = keys_sorted[i]
                push!(stack, item[key], CanonicalToken(":"), CanonicalToken(JSON3.write(String(key))))
                i == 1 || push!(stack, CanonicalToken(","))
            end
        elseif item isa AbstractVector
            push!(output, "["); push!(stack, CanonicalToken("]"))
            for i in reverse(eachindex(item))
                push!(stack, item[i])
                i == 1 || push!(stack, CanonicalToken(","))
            end
        else
            push!(output, JSON3.write(item))
        end
    end
    return join(output)
end
"""Return a stable SHA-256 identity for the complete persisted schema contract."""
schema_fingerprint(schema) = bytes2hex(sha256(canonical(schema)))

function column_label(schema, name)
    index = findfirst(c -> get(c, "name", "") == name, get(schema, "columns", Any[]))
    index === nothing && return name
    unit = get(schema["columns"][index], "unit", "")
    return isempty(unit) ? name : "$(name) ($(unit))"
end

function verified_table(dataset, path)
    checksum = get(dataset, "checksumSha256", "")
    occursin(r"^[a-f0-9]{64}$", checksum) || error("analysis source checksum unavailable; import a verified source")
    path isa AbstractString && isfile(path) || error("analysis source evidence unavailable")
    filesize(path) <= Profile.MAX_PROFILE_BYTES || error("analysis source exceeds the 8 MiB qualification limit")
    before = open(io -> bytes2hex(sha256(io)), path)
    before == checksum || error("analysis source checksum changed; import a new dataset snapshot")
    headers, rows = Profile.read_profile_rows(path)
    open(io -> bytes2hex(sha256(io)), path) == before || error("analysis source changed during read")
    return Dict{String,Any}("headers" => headers, "rows" => rows)
end

function numeric_columns(table, schema)
    columns, _ = Stats.simple_numeric_columns(table)
    allowed = Set(String(c["name"]) for c in get(schema, "columns", Any[])
        if !(get(c, "role", "feature") in ("ignore", "sensitive", "id")) &&
            !(lowercase(String(get(c, "logicalType", ""))) in ("categorical", "string", "text", "boolean")))
    return sort([name for name in keys(columns) if name in allowed])
end

"""Reload verified bounded CSV bytes and return a measured profile without importing."""
function measured_profile(dataset, path, schema)
    verified_table(dataset, path)
    measured = Profile.local_csv_profile(path)
    result = merge(Dict{String,Any}(
        "datasetId" => dataset["datasetId"], "sourceUri" => dataset["sourceUri"], "sourceFormat" => "csv",
        "targetZone" => "raw", "artifactRef" => dataset["sourceUri"], "artifactFormats" => ["csv"],
        "checksumSha256" => dataset["checksumSha256"], "manifestReady" => true, "manifestChecksums" => Any[],
        "duckdbStatus" => "unavailable", "importedAt" => "", "localOnly" => true, "charts" => Any[]), measured)
    table = verified_table(dataset, path)
    return Dict("profile" => result, "schemaFingerprint" => schema_fingerprint(schema), "numericColumns" => numeric_columns(table, schema))
end

function check_scope(scope, dataset, schema)
    scope isa AbstractDict || error("analysis scope required")
    scope["datasetChecksum"] == dataset["checksumSha256"] || error("analysis dataset snapshot is stale")
    scope["schemaFingerprint"] == schema_fingerprint(schema) || error("analysis schema is stale; refresh measured data")
    !isempty(strip(String(scope["question"]))) && length(String(scope["question"])) <= 500 || error("analysis question requires 1 to 500 characters")
    filters = scope["filters"]
    filters isa AbstractVector && length(filters) <= 10 || error("analysis supports at most 10 filters")
    return nothing
end

function matches_filter(row, headers, filter)
    index = findfirst(==(String(filter["column"])), headers)
    index === nothing && error("analysis filter column unavailable")
    op, value = String(filter["operator"]), String(filter["value"])
    length(value) <= 200 || error("analysis filter value exceeds 200 characters")
    op == "eq" && return row[index] == value
    op in ("gte", "lte") || error("analysis filter operator unavailable")
    bound = tryparse(Float64, value)
    bound !== nothing && isfinite(bound) || error("analysis numeric filter requires a finite bound")
    number = tryparse(Float64, row[index])
    number !== nothing && isfinite(number) || return false
    return op == "gte" ? number >= bound : number <= bound
end

"""Compute bounded, schema-bound analysis with original row identity and explicit pairwise missingness."""
function scoped_evidence(dataset, path, body, schema)
    methods = Stats.statistical_analysis_methods(body)
    all(m -> m in ("summary", "correlation", "pearson_correlation"), methods) || error("scoped analysis supports summary and Pearson correlation; other methods require separate qualification")
    scope = body["scope"]
    check_scope(scope, dataset, schema)
    table = verified_table(dataset, path)
    ids = [i for (i, row) in enumerate(table["rows"]) if all(f -> matches_filter(row, table["headers"], f), scope["filters"])]
    isempty(ids) && error("analysis filter selects no rows; adjust the scope")
    selected = Dict{String,Any}("headers" => table["headers"], "rows" => table["rows"][ids])
    allowed = numeric_columns(table, schema)
    length(allowed) <= 64 || error("analysis supports at most 64 enabled numeric columns; adjust schema roles")
    indexes = [findfirst(==(name), table["headers"]) for name in allowed]
    numeric_table = Dict{String,Any}("headers" => allowed, "rows" => [[row[i] for i in indexes] for row in selected["rows"]])
    evidence = Stats.local_csv_statistical_evidence_from_path(dataset, path, body, methods; table = numeric_table)
    evidence === nothing && error("analysis numeric evidence unavailable for this schema")
    names = evidence["numericColumns"]
    keep = [i for i in eachindex(names) if names[i] in allowed]
    evidence["numericColumns"] = names[keep]
    evidence["summaries"] = [s for s in evidence["summaries"] if s["column"] in allowed]
    for key in ("correlationMatrix", "spearmanCorrelationMatrix", "correlationPairCounts")
        matrix = evidence[key]
        evidence[key] = [[matrix[i][j] for j in keep] for i in keep]
    end
    isempty(keep) && error("analysis has no schema-enabled numeric columns")
    evidence["scope"] = merge(Dict{String,Any}(scope), Dict(
        "datasetId" => dataset["datasetId"], "sourceRowCount" => length(table["rows"]),
        "selectedRowCount" => length(ids), "rowIds" => ids, "scopeId" => bytes2hex(sha256(canonical(Dict("scope" => scope, "rowIds" => ids))))))
    evidence["computeProvenance"] = Dict("producer" => "api-gateway", "actualBackend" => "cpu", "juliaVersion" => string(VERSION), "operationVersion" => "bounded-analysis-1", "workerComputed" => false)
    x, y = String(get(scope, "xColumn", "")), String(get(scope, "yColumn", ""))
    if !isempty(x) || !isempty(y)
        x in allowed && y in allowed || error("analysis chart columns must be schema-enabled numeric columns")
        xv, yv = Stats.paired_numeric_values(selected, x, y)
        evidence["scatter"] = Dict("xColumn" => x, "yColumn" => y, "xLabel" => column_label(schema, x), "yLabel" => column_label(schema, y), "x" => xv, "y" => yv, "count" => length(xv))
    end
    distribution_column = isempty(x) ? first(evidence["numericColumns"]) : x
    index = findfirst(==(distribution_column), selected["headers"])
    distribution = [tryparse(Float64, row[index]) for row in selected["rows"]]
    evidence["distribution"] = Dict("column" => distribution_column, "label" => column_label(schema, distribution_column), "values" => [v for v in distribution if v !== nothing && isfinite(v)])
    evidence["warnings"] = ["Correlation describes association, not causation.", "Missing numeric pairs are excluded together by original row; constant or insufficient pairs are unavailable.", "Analysis scope is independent of modeling population and holdout selection."]
    overflowed = false
    for summary in evidence["summaries"], key in ("mean", "std", "min", "max")
        value = summary[key]
        if value isa Number && !isfinite(value)
            summary[key] = nothing; overflowed = true
        end
    end
    for key in ("correlationMatrix", "spearmanCorrelationMatrix")
        overflowed |= any(value isa Number && !isfinite(value) for row in evidence[key] for value in row)
        evidence[key] = [[value isa Number && !isfinite(value) ? nothing : value for value in row] for row in evidence[key]]
    end
    overflowed && push!(evidence["warnings"], "Some finite inputs exceeded numerical result range; affected results are unavailable.")
    return evidence
end

"""Validate a draft against immutable evidence and increment its optimistic save revision."""
function validate_workspace(body, project, dataset, schema)
    current_revision = get(project.analysis_workspace, "revision", 0)
    body["expectedRevision"] == current_revision || error("analysis workspace revision conflict; reopen the saved project before retrying")
    workspace = deepcopy(body["workspace"])
    workspace["revision"] == current_revision || error("analysis workspace revision mismatch")
    workspace["datasetId"] == dataset["datasetId"] || error("analysis workspace dataset mismatch")
    check_scope(workspace["scope"], dataset, schema)
    findings = workspace["findings"]
    length(findings) <= 50 || error("analysis finding limit exceeded")
    ids = Set{String}()
    for finding in findings
        id = String(finding["findingId"])
        occursin(r"^[a-zA-Z0-9_-]{1,80}$", id) && !(id in ids) || error("analysis finding id invalid or duplicated")
        push!(ids, id)
        length(String(finding["title"])) <= 500 && length(String(finding["notes"])) <= 10_000 || error("analysis finding text limit exceeded")
        any(r -> get(r,"analysisRunId", "") == finding["analysisRunId"] && get(r,"datasetId", "") == dataset["datasetId"] && haskey(get(r,"resultSummary",Dict()), "scope"), project.statistical_analysis_runs) || error("analysis finding must reference immutable scoped evidence in this dataset")
    end
    run_id = get(workspace, "analysisRunId", "")
    if !isempty(run_id)
        run = findfirst(r -> get(r, "analysisRunId", "") == run_id, project.statistical_analysis_runs)
        run === nothing && error("analysis run unavailable")
        evidence_scope = get(get(project.statistical_analysis_runs[run], "resultSummary", Dict()), "scope", Dict())
        all(k -> get(evidence_scope,k,nothing) == get(workspace["scope"],k,nothing), ("datasetChecksum","schemaFingerprint","filters","question","xColumn","yColumn")) || error("analysis saved view differs from its evidence; run analysis again")
    end
    workspace["revision"] = current_revision + 1
    return workspace
end

escape_html(value) = replace(string(value), '&' => "&amp;", '<' => "&lt;", '>' => "&gt;", '"' => "&quot;", '\'' => "&#39;")
function csv_cell(value)
    text = string(value)
    if value isa AbstractString && occursin(r"^[=+@-]", lstrip(text))
        text = "'" * text
    end
    return "\"" * replace(text, "\"" => "\"\"") * "\""
end

function report_scatter(evidence)
    scatter = get(evidence, "scatter", nothing)
    scatter === nothing && return ""
    x, y = scatter["x"], scatter["y"]
    isempty(x) && return "<p>No complete chart pairs.</p>"
    xmin, xmax, ymin, ymax = minimum(x), maximum(x), minimum(y), maximum(y)
    dx, dy = xmax - xmin, ymax - ymin
    isfinite(dx) && isfinite(dy) || return "<p>Scatter rendering unavailable at this numeric range; accessible chart values are retained below.</p>"
    dx = dx == 0 ? 1.0 : dx; dy = dy == 0 ? 1.0 : dy
    points = join(["<circle cx=\"$(40 + 520 * (x[i] - xmin) / dx)\" cy=\"$(270 - 230 * (y[i] - ymin) / dy)\" r=\"3\" fill=\"#40456A\"/>" for i in eachindex(x)])
    return "<figure><figcaption>$(escape_html(scatter["xColumn"])) and $(escape_html(scatter["yColumn"])) · $(length(x)) complete pairs</figcaption><svg role=\"img\" aria-label=\"Selected complete-pair scatter plot\" viewBox=\"0 0 600 310\"><path d=\"M40 30 V270 H570\" fill=\"none\" stroke=\"#202333\"/>$(points)</svg><p>Full accessible chart data is retained below. Association does not establish cause.</p></figure>"
end

"""Render escaped presentation HTML and formula-safe summary CSV from saved evidence."""
function report_response(project, runs)
    workspace = project.analysis_workspace
    isempty(workspace) && error("analysis save a workspace before exporting")
    ids = unique([get(workspace,"analysisRunId", ""); [f["analysisRunId"] for f in workspace["findings"]]])
    selected = [r for r in runs if get(r,"analysisRunId", "") in ids]
    isempty(selected) && error("analysis report needs saved analysis evidence")
    sections = String[]
    csv = ["run,column,count,missing,mean,std,min,max"]
    for run in selected
        evidence = run["resultSummary"]
        table = "<table><caption>Numeric summaries</caption><thead><tr>" * join(["<th>$(escape_html(k))</th>" for k in ("column","count","missingCount","mean","std","min","max")]) * "</tr></thead><tbody>"
        for row in evidence["summaries"]
            keys = ("column","count","missingCount","mean","std","min","max")
            table *= "<tr>" * join(["<td>$(escape_html(get(row,k,"unavailable")))</td>" for k in keys]) * "</tr>"
            push!(csv, join(csv_cell.([run["analysisRunId"]; [get(row,k, "unavailable") for k in keys]]), ","))
        end
        push!(sections, "<h2>$(escape_html(run["analysisRunId"]))</h2>" * table * "</tbody></table>" * report_scatter(evidence) * "<h3>Scope, correlation, chart data and provenance</h3><pre>$(escape_html(JSON3.write(evidence)))</pre><p>$(escape_html(join(run["warnings"], " ")))</p>")
    end
    notes = join(["<h3>$(escape_html(f["title"]))</h3><p>$(escape_html(f["notes"]))</p><p>Evidence: $(escape_html(f["analysisRunId"]))</p>" for f in workspace["findings"]])
    html = "<!doctype html><html lang=\"en\"><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width\"><title>JuliaFlow analysis report</title><style>body{font:16px system-ui;max-width:1100px;margin:2rem auto;padding:1rem;color:#202333}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ccc;padding:.5rem;text-align:left}pre{white-space:pre-wrap;overflow-wrap:anywhere}p{white-space:pre-wrap}</style><body><h1>$(escape_html(workspace["scope"]["question"]))</h1><p>Project: $(escape_html(project.name)); dataset: $(escape_html(workspace["datasetId"])); saved revision: $(workspace["revision"])</p><p>Presentation report. Source CSV file is not included. Reopenable project packages are a separate export.</p>" * notes * join(sections) * "</body></html>"
    return Dict("fileName" => "juliaflow-analysis-report", "html" => html, "csv" => join(csv,"\r\n") * "\r\n", "checksumSha256" => bytes2hex(sha256(html)))
end

"""Capture the qualified algorithms and request in replayable, checksum-bound Julia code."""
function replay_code(dataset, body, schema)
    # Capture the actual bounded algorithms, not only metadata or a reference to a mutable checkout.
    sources = join([read(joinpath(@__DIR__, name), String) for name in
        ("JuliaFlowDataScienceProjectStatistics.jl", "JuliaFlowDataScienceProjectProfiling.jl", "JuliaFlowProjectAnalysis.jl")], "\n")
    data = repr(JSON3.write(dataset)); request = repr(JSON3.write(body)); schema_json = repr(JSON3.write(schema))
    return "# JuliaFlow bounded analysis replay; Julia $(VERSION), JSON3 and SHA required.\n# Pass the original checksum-matching CSV as ARGS[1].\n" * sources * "\nusing JSON3\nlength(ARGS) == 1 || error(\"Pass the source CSV path\")\ndataset = JSON3.read($(data), Dict{String,Any})\nrequest = JSON3.read($(request), Dict{String,Any})\nschema = JSON3.read($(schema_json), Dict{String,Any})\nprintln(JSON3.write(JuliaFlowProjectAnalysis.scoped_evidence(dataset, ARGS[1], request, schema)))\n"
end

end
