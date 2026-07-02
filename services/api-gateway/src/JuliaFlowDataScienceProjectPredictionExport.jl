module JuliaFlowDataScienceProjectPredictionExport

using JSON3

export PREDICTION_EXPORT_COLUMNS,
    prediction_export_format,
    prediction_export_row_count,
    prediction_export_contract,
    prediction_export_contract_column_names,
    prediction_export_output_columns,
    prediction_export_output_mappings,
    prediction_export_prediction_values,
    prediction_export_rows,
    selected_prediction_export_rows,
    prediction_export_content

const PREDICTION_EXPORT_COLUMNS = [
    "prediction_id",
    "dataset_id",
    "evaluation_report_id",
    "output_contract_ref",
    "prediction",
]

function safe_export_token(value::AbstractString)
    normalized = lowercase(strip(String(value)))
    normalized = replace(normalized, r"[^a-z0-9._-]+" => "-")
    normalized = strip(normalized, ['-', '.', '_'])
    isempty(normalized) && return "csv"
    return first(normalized, min(lastindex(normalized), 80))
end

function csv_escape(value)
    value === nothing && return ""
    text = string(value)
    if occursin(",", text) || occursin("\"", text) || occursin("\n", text)
        return "\"" * replace(text, "\"" => "\"\"") * "\""
    end
    return text
end

function prediction_export_format(body::AbstractDict)
    format = haskey(body, "format") ? safe_export_token(String(body["format"])) : "csv"
    format in ("csv", "parquet", "jsonl") || error("prediction export format must be csv, parquet, or jsonl")
    return format
end

function prediction_export_row_count(body::AbstractDict, dataset::AbstractDict)
    value = if haskey(body, "rowCount")
        Int(body["rowCount"])
    else
        Int(get(dataset, "rowCount", 1))
    end
    value > 0 || error("prediction export rowCount must be positive")
    return value
end

function prediction_export_contract(body::AbstractDict, output_contract_ref::AbstractString)
    contract_columns = [
        Dict{String,Any}("name" => column, "sourceColumn" => column, "required" => true)
        for column in PREDICTION_EXPORT_COLUMNS
    ]
    contract = Dict{String,Any}(
        "contractId" => String(output_contract_ref),
        "columns" => contract_columns,
    )
    if haskey(body, "outputContract")
        raw_contract = body["outputContract"]
        raw_contract isa AbstractDict || error("prediction export outputContract must be an object")
        contract_id = strip(String(get(raw_contract, "contractId", output_contract_ref)))
        !isempty(contract_id) || error("prediction export outputContract contractId required")
        if !isempty(strip(String(output_contract_ref))) && contract_id != String(output_contract_ref)
            error("prediction export outputContract contractId must match outputContractRef")
        end
        raw_columns = get(raw_contract, "columns", Any[])
        raw_columns isa AbstractVector || error("prediction export outputContract columns must be an array")
        isempty(raw_columns) && error("prediction export outputContract columns required")
        parsed_columns = Dict{String,Any}[]
        seen = Set{String}()
        for raw_column in raw_columns
            raw_column isa AbstractDict || error("prediction export outputContract columns must be objects")
            name = strip(String(get(raw_column, "name", "")))
            !isempty(name) || error("prediction export outputContract column name required")
            name in seen && error("prediction export outputContract duplicate column: $(name)")
            push!(seen, name)
            source_column = strip(String(get(raw_column, "sourceColumn", name)))
            column = Dict{String,Any}(
                "name" => name,
                "sourceColumn" => source_column,
                "required" => Bool(get(raw_column, "required", true)),
            )
            haskey(raw_column, "type") && (column["type"] = String(raw_column["type"]))
            haskey(raw_column, "description") && (column["description"] = String(raw_column["description"]))
            push!(parsed_columns, column)
        end
        contract = Dict{String,Any}(
            "contractId" => contract_id,
            "columns" => parsed_columns,
        )
        haskey(raw_contract, "primaryKey") && (contract["primaryKey"] = raw_contract["primaryKey"])
        haskey(raw_contract, "createdAt") && (contract["createdAt"] = String(raw_contract["createdAt"]))
    end
    return contract
end

function prediction_export_contract_column_names(contract::AbstractDict)
    return [String(get(column, "name", "")) for column in get(contract, "columns", Any[])]
end

function prediction_export_output_columns(body::AbstractDict, contract::AbstractDict)
    contract_columns = prediction_export_contract_column_names(contract)
    raw = haskey(body, "outputColumns") ? body["outputColumns"] : contract_columns
    raw isa AbstractVector || error("prediction export outputColumns must be an array")
    columns = String[]
    unsupported = String[]
    for value in raw
        column = strip(String(value))
        isempty(column) && error("prediction export outputColumns cannot include empty column names")
        if column in contract_columns
            push!(columns, column)
        else
            push!(unsupported, column)
        end
    end
    isempty(columns) && error("prediction export outputColumns must include at least one column")
    isempty(unsupported) || error("prediction export outputColumns unsupported by output contract: $(join(unique(unsupported), ", "))")
    selected = unique(columns)
    required_columns = [
        String(get(column, "name", ""))
        for column in get(contract, "columns", Any[])
        if Bool(get(column, "required", true))
    ]
    missing_required = setdiff(required_columns, selected)
    isempty(missing_required) || error("prediction export outputColumns missing required output contract columns: $(join(missing_required, ", "))")
    return selected
end

function prediction_export_output_mappings(body::AbstractDict, contract::AbstractDict, output_columns::AbstractVector)
    allowed_outputs = Set(prediction_export_contract_column_names(contract))
    selected_outputs = Set(String.(output_columns))
    mappings = Dict{String,String}()
    for column in get(contract, "columns", Any[])
        output_column = String(get(column, "name", ""))
        source_column = strip(String(get(column, "sourceColumn", output_column)))
        !isempty(source_column) || error("prediction export outputContract sourceColumn required for $(output_column)")
        mappings[output_column] = source_column
    end
    if haskey(body, "outputMappings")
        raw_mappings = body["outputMappings"]
        raw_mappings isa AbstractVector || error("prediction export outputMappings must be an array")
        for raw_mapping in raw_mappings
            raw_mapping isa AbstractDict || error("prediction export outputMappings entries must be objects")
            output_column = strip(String(get(raw_mapping, "outputColumn", "")))
            source_column = strip(String(get(raw_mapping, "sourceColumn", "")))
            !isempty(output_column) || error("prediction export outputMappings outputColumn required")
            !isempty(source_column) || error("prediction export outputMappings sourceColumn required")
            output_column in allowed_outputs || error("prediction export outputMappings unknown outputColumn: $(output_column)")
            mappings[output_column] = source_column
        end
    end
    unsupported_sources = unique([
        source for (output, source) in mappings
        if output in selected_outputs && !(source in PREDICTION_EXPORT_COLUMNS)
    ])
    isempty(unsupported_sources) || error("prediction export outputMappings unsupported sourceColumn: $(join(unsupported_sources, ", "))")
    return [
        Dict{String,Any}("outputColumn" => output_column, "sourceColumn" => mappings[String(output_column)])
        for output_column in output_columns
    ]
end

function prediction_export_prediction_values(report::AbstractDict, row_count::Integer)
    validation = get(report, "validationEvidence", Dict{String,Any}())
    evidence = get(validation, "evaluationDataEvidence", Dict{String,Any}())
    baseline_model = String(get(evidence, "baselineModel", ""))
    if baseline_model == "row_index_linear_baseline"
        slope = Float64(get(evidence, "baselineSlope", 0.0))
        intercept = Float64(get(evidence, "baselineIntercept", 0.0))
        return [round(intercept + slope * index; digits = 6) for index in 1:Int(row_count)], "local_csv_row_index_baseline"
    elseif baseline_model == "mean_baseline"
        baseline = Float64(get(evidence, "baselineIntercept", 0.0))
        return fill(round(baseline; digits = 6), Int(row_count)), "local_csv_mean_baseline"
    end
    metrics = get(report, "metrics", Dict{String,Any}())
    metric_values = [Float64(value) for value in values(metrics)]
    baseline = isempty(metric_values) ? 0.5 : sum(metric_values) / length(metric_values)
    return [round(clamp(baseline - 0.001 * (index - 1), 0.0, 1.0); digits = 6) for index in 1:Int(row_count)], "metric_average_fallback"
end

function prediction_export_rows(export_id::AbstractString, report::AbstractDict, dataset_id::AbstractString, output_contract_ref::AbstractString, row_count::Integer)
    predictions, _ = prediction_export_prediction_values(report, row_count)
    return [
        Dict{String,Any}(
            "prediction_id" => "$(String(export_id))-$(index)",
            "dataset_id" => String(dataset_id),
            "evaluation_report_id" => String(get(report, "evaluationReportId", "")),
            "output_contract_ref" => String(output_contract_ref),
            "prediction" => predictions[index],
        ) for index in 1:Int(row_count)
    ]
end

function selected_prediction_export_rows(rows::AbstractVector, output_columns::AbstractVector, output_mappings::AbstractVector)
    mapping_by_output = Dict(String(mapping["outputColumn"]) => String(mapping["sourceColumn"]) for mapping in output_mappings)
    return [
        Dict{String,Any}(
            column => row[mapping_by_output[String(column)]]
            for column in output_columns
        ) for row in rows
    ]
end

function prediction_export_content(format::AbstractString, rows::AbstractVector, output_columns::AbstractVector, output_mappings::AbstractVector)
    selected_rows = selected_prediction_export_rows(rows, output_columns, output_mappings)
    if String(format) == "jsonl"
        return join([JSON3.write(row) for row in selected_rows], "\n") * "\n"
    elseif String(format) == "csv"
        header = join([csv_escape(column) for column in output_columns], ",")
        lines = [
            join(
                [csv_escape(get(row, column, "")) for column in output_columns],
                ",",
            ) for row in selected_rows
        ]
        return join([header, lines...], "\n") * "\n"
    end
    return JSON3.write(Dict("format" => String(format), "outputColumns" => output_columns, "rows" => selected_rows)) * "\n"
end

end
