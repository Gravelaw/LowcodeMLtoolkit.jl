const RENAME_COLUMNS_NODE_KEY = "base.rename_columns"
const CAST_COLUMNS_NODE_KEY = "base.cast_columns"
const FILL_MISSING_NODE_KEY = "base.fill_missing"
const DROP_MISSING_NODE_KEY = "base.drop_missing"
const SORT_ROWS_NODE_KEY = "base.sort_rows"
const LIMIT_ROWS_NODE_KEY = "base.limit_rows"
const SAMPLE_ROWS_NODE_KEY = "base.sample_rows"
const DISTINCT_ROWS_NODE_KEY = "base.distinct_rows"
const ADD_CONSTANT_COLUMN_NODE_KEY = "base.add_constant_column"
const ROW_NUMBER_NODE_KEY = "base.row_number"
const CONCAT_ROWS_NODE_KEY = "base.concat_rows"
const INNER_JOIN_ROWS_NODE_KEY = "base.inner_join_rows"
const BASIC_STATS_NODE_KEY = "base.basic_stats"
const TABLE_PROFILE_NODE_KEY = "base.table_profile"
const SPLIT_ROWS_NODE_KEY = "base.split_rows"
const DERIVE_RATIO_NODE_KEY = "base.derive_ratio"
const BUCKETIZE_ROWS_NODE_KEY = "base.bucketize_rows"
const BI_OUTLET_NODE_KEY = "base.bi_outlet"
const TRIM_STRINGS_NODE_KEY = "base.trim_strings"
const NORMALIZE_CASE_NODE_KEY = "base.normalize_case"
const REPLACE_VALUES_NODE_KEY = "base.replace_values"
const REGEX_EXTRACT_NODE_KEY = "base.regex_extract"
const VALIDATE_SCHEMA_NODE_KEY = "base.validate_schema"
const TOP_N_ROWS_NODE_KEY = "base.top_n_rows"
const GROUP_FILTER_NODE_KEY = "base.group_filter"
const ROLLING_MEAN_NODE_KEY = "base.rolling_mean"
const RANK_ROWS_NODE_KEY = "base.rank_rows"
const PERCENTILE_ROWS_NODE_KEY = "base.percentile_rows"
const COALESCE_COLUMNS_NODE_KEY = "base.coalesce_columns"
const CLIP_VALUES_NODE_KEY = "base.clip_values"
const CUMULATIVE_SUM_NODE_KEY = "base.cumulative_sum"
const ROLLING_SUM_NODE_KEY = "base.rolling_sum"
const LAG_COLUMN_NODE_KEY = "base.lag_column"
const STRING_CONTAINS_FILTER_NODE_KEY = "base.string_contains_filter"
const COLUMN_MATH_NODE_KEY = "base.column_math"
const NULL_IF_NODE_KEY = "base.null_if"
const MIN_MAX_SCALE_NODE_KEY = "base.min_max_scale"
const Z_SCORE_NODE_KEY = "base.z_score"
const LEFT_JOIN_ROWS_NODE_KEY = "base.left_join_rows"
const ANTI_JOIN_ROWS_NODE_KEY = "base.anti_join_rows"
const UNION_DISTINCT_ROWS_NODE_KEY = "base.union_distinct_rows"
const UNPIVOT_ROWS_NODE_KEY = "base.unpivot_rows"
const PIVOT_ROWS_NODE_KEY = "base.pivot_rows"

const TIER1_INPUT_PORT_ID = "table_in"
const TIER1_OUTPUT_PORT_ID = "table_out"

struct RenameColumnsNode <: AbstractNode end
struct CastColumnsNode <: AbstractNode end
struct FillMissingNode <: AbstractNode end
struct DropMissingNode <: AbstractNode end
struct SortRowsNode <: AbstractNode end
struct LimitRowsNode <: AbstractNode end
struct SampleRowsNode <: AbstractNode end
struct DistinctRowsNode <: AbstractNode end
struct AddConstantColumnNode <: AbstractNode end
struct RowNumberNode <: AbstractNode end
struct ConcatRowsNode <: AbstractNode end
struct InnerJoinRowsNode <: AbstractNode end
struct BasicStatsNode <: AbstractNode end
struct TableProfileNode <: AbstractNode end
struct SplitRowsNode <: AbstractNode end
struct DeriveRatioNode <: AbstractNode end
struct BucketizeRowsNode <: AbstractNode end
struct BIOutletNode <: AbstractNode end
struct TrimStringsNode <: AbstractNode end
struct NormalizeCaseNode <: AbstractNode end
struct ReplaceValuesNode <: AbstractNode end
struct RegexExtractNode <: AbstractNode end
struct ValidateSchemaNode <: AbstractNode end
struct TopNRowsNode <: AbstractNode end
struct GroupFilterNode <: AbstractNode end
struct RollingMeanNode <: AbstractNode end
struct RankRowsNode <: AbstractNode end
struct PercentileRowsNode <: AbstractNode end
struct CoalesceColumnsNode <: AbstractNode end
struct ClipValuesNode <: AbstractNode end
struct CumulativeSumNode <: AbstractNode end
struct RollingSumNode <: AbstractNode end
struct LagColumnNode <: AbstractNode end
struct StringContainsFilterNode <: AbstractNode end
struct ColumnMathNode <: AbstractNode end
struct NullIfNode <: AbstractNode end
struct MinMaxScaleNode <: AbstractNode end
struct ZScoreNode <: AbstractNode end
struct LeftJoinRowsNode <: AbstractNode end
struct AntiJoinRowsNode <: AbstractNode end
struct UnionDistinctRowsNode <: AbstractNode end
struct UnpivotRowsNode <: AbstractNode end
struct PivotRowsNode <: AbstractNode end

function tier1_config(params::AbstractDict; defaults = Dict{String,Any}())
    normalized = Dict{String,Any}(String(key) => value for (key, value) in pairs(params))
    merged = Dict{String,Any}(String(key) => value for (key, value) in pairs(defaults))
    for (key, value) in pairs(normalized)
        merged[key] = value
    end
    input_port_id = String(get(merged, "input_port_id", TIER1_INPUT_PORT_ID))
    output_port_id = String(get(merged, "output_port_id", TIER1_OUTPUT_PORT_ID))
    isempty(input_port_id) && error("input_port_id must not be empty")
    isempty(output_port_id) && error("output_port_id must not be empty")
    merged["input_port_id"] = input_port_id
    merged["output_port_id"] = output_port_id
    return NodeConfig(merged)
end

function infer_tier1_schema(input_schemas::Vector{PortSchema}, label::String = "Table")
    validate_port_type(:data_table)
    input_label = isempty(input_schemas) ? label : input_schemas[1].label
    return [PortSchema(id = TIER1_OUTPUT_PORT_ID, direction = :output, type = :data_table, label = input_label)]
end

function input_payload(context::NodeContext, port_id::String)
    haskey(context.inputs, port_id) || error("missing input payload for port $(port_id)")
    payload = context.inputs[port_id]
    validate_arrow_boundary(payload)
    haskey(payload, :ref) || error("Arrow payload missing ref field")
    return payload
end

function rows_or_warning(payload::NamedTuple, output_port_id::String, node_key::String, context::NodeContext)
    rows = payload_rows(payload, context)
    rows === nothing || return rows
    return NodeResult(
        outputs = Dict(output_port_id => (; payload..., operation = node_key)),
        telemetry = Dict("node_key" => node_key, "input_ref" => String(payload.ref), "materialized" => false),
        warnings = ["$(node_key) requires inline rows for materialized execution"],
    )
end

function finish_table_node(payload::NamedTuple, context::NodeContext, node_key::String, output_port_id::String, rows::AbstractVector; schema = nothing, telemetry = Dict{String,Any}())
    output = table_payload(payload, context, node_key, rows; schema = schema)
    base_telemetry = Dict{String,Any}(
        "node_key" => node_key,
        "input_ref" => String(payload.ref),
        "output_ref" => output.ref,
        "row_count" => output.row_count,
        "materialized" => true,
    )
    merge!(base_telemetry, telemetry)
    return NodeResult(outputs = Dict(output_port_id => output), telemetry = base_telemetry)
end

function configure(::Type{RenameColumnsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("mapping" => Dict{String,String}()))
end
function infer_output_schema(::Type{RenameColumnsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Renamed Rows")
end
function execute(::Type{RenameColumnsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, RENAME_COLUMNS_NODE_KEY, context)
    rows isa NodeResult && return rows
    mapping = Dict(String(k) => String(v) for (k, v) in pairs(get(context.config.values, "mapping", Dict())))
    isempty(mapping) && error("mapping must contain at least one rename")
    renamed = Dict{String,Any}[]
    for row in rows
        row_dict = row_to_dict(row)
        next_row = Dict{String,Any}()
        for (key, value) in row_dict
            next_row[get(mapping, key, key)] = value
        end
        push!(renamed, next_row)
    end
    return finish_table_node(payload, context, RENAME_COLUMNS_NODE_KEY, output_port_id, renamed)
end

function cast_value(value, target_type::String)
    value === missing && return missing
    value === nothing && return missing
    normalized = lowercase(strip(target_type))
    normalized in ["string", "text"] && return string(value)
    normalized in ["int", "integer"] && return value isa Number ? Int(value) : parse(Int, string(value))
    normalized in ["float", "float64", "number"] && return value isa Number ? Float64(value) : parse(Float64, string(value))
    normalized in ["bool", "boolean"] && return value isa Bool ? value : lowercase(string(value)) in ["true", "1", "yes"]
    error("unsupported cast type: $(target_type)")
end
function configure(::Type{CastColumnsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("casts" => Dict{String,String}()))
end
function infer_output_schema(::Type{CastColumnsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Casted Rows")
end
function execute(::Type{CastColumnsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, CAST_COLUMNS_NODE_KEY, context)
    rows isa NodeResult && return rows
    casts = Dict(String(k) => String(v) for (k, v) in pairs(get(context.config.values, "casts", Dict())))
    isempty(casts) && error("casts must contain at least one column cast")
    casted = Dict{String,Any}[]
    for row in rows
        row_dict = row_to_dict(row)
        next_row = copy(row_dict)
        for (column, target_type) in casts
            haskey(next_row, column) || error("row missing column $(column)")
            next_row[column] = cast_value(next_row[column], target_type)
        end
        push!(casted, next_row)
    end
    return finish_table_node(payload, context, CAST_COLUMNS_NODE_KEY, output_port_id, casted)
end

function configure(::Type{FillMissingNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("fill_values" => Dict{String,Any}()))
end
function infer_output_schema(::Type{FillMissingNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Filled Rows")
end
function execute(::Type{FillMissingNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, FILL_MISSING_NODE_KEY, context)
    rows isa NodeResult && return rows
    fill_values = Dict(String(k) => v for (k, v) in pairs(get(context.config.values, "fill_values", Dict())))
    filled = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        for (column, fill_value) in fill_values
            if get(next_row, column, missing) === missing || get(next_row, column, nothing) === nothing
                next_row[column] = fill_value
            end
        end
        push!(filled, next_row)
    end
    return finish_table_node(payload, context, FILL_MISSING_NODE_KEY, output_port_id, filled)
end

function configure(::Type{DropMissingNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[]))
end
function infer_output_schema(::Type{DropMissingNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Non-missing Rows")
end
function execute(::Type{DropMissingNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DROP_MISSING_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = [String(column) for column in get(context.config.values, "columns", String[])]
    kept = Dict{String,Any}[]
    for row in rows
        row_dict = row_to_dict(row)
        selected = isempty(columns) ? collect(keys(row_dict)) : columns
        any_missing = any(get(row_dict, column, missing) === missing || get(row_dict, column, nothing) === nothing for column in selected)
        any_missing || push!(kept, row_dict)
    end
    return finish_table_node(payload, context, DROP_MISSING_NODE_KEY, output_port_id, kept)
end

function configure(::Type{SortRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "descending" => false))
end
function infer_output_schema(::Type{SortRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Sorted Rows")
end
function execute(::Type{SortRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, SORT_ROWS_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    isempty(column) && error("column must not be empty")
    sorted = [row_to_dict(row) for row in rows]
    sort!(sorted, by = row -> row[column], rev = Bool(get(context.config.values, "descending", false)))
    return finish_table_node(payload, context, SORT_ROWS_NODE_KEY, output_port_id, sorted)
end

function configure(::Type{LimitRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("limit" => 10, "offset" => 0))
end
function infer_output_schema(::Type{LimitRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Limited Rows")
end
function execute(::Type{LimitRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, LIMIT_ROWS_NODE_KEY, context)
    rows isa NodeResult && return rows
    limit = Int(get(context.config.values, "limit", 10))
    offset = Int(get(context.config.values, "offset", 0))
    limit >= 0 || error("limit must be >= 0")
    offset >= 0 || error("offset must be >= 0")
    start_index = min(offset + 1, length(rows) + 1)
    stop_index = min(offset + limit, length(rows))
    limited = start_index > stop_index ? Dict{String,Any}[] : [row_to_dict(row) for row in rows[start_index:stop_index]]
    return finish_table_node(payload, context, LIMIT_ROWS_NODE_KEY, output_port_id, limited)
end

function configure(::Type{SampleRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("every_n" => 2, "limit" => 0))
end
function infer_output_schema(::Type{SampleRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Sampled Rows")
end
function execute(::Type{SampleRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, SAMPLE_ROWS_NODE_KEY, context)
    rows isa NodeResult && return rows
    every_n = max(1, Int(get(context.config.values, "every_n", 2)))
    limit = Int(get(context.config.values, "limit", 0))
    sampled = [row_to_dict(rows[index]) for index in 1:every_n:length(rows)]
    if limit > 0 && length(sampled) > limit
        sampled = sampled[1:limit]
    end
    return finish_table_node(payload, context, SAMPLE_ROWS_NODE_KEY, output_port_id, sampled)
end

function configure(::Type{DistinctRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[]))
end
function infer_output_schema(::Type{DistinctRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Distinct Rows")
end
function execute(::Type{DistinctRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DISTINCT_ROWS_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = [String(column) for column in get(context.config.values, "columns", String[])]
    seen = Set{String}()
    distinct = Dict{String,Any}[]
    for row in rows
        row_dict = row_to_dict(row)
        selected = isempty(columns) ? sort(collect(keys(row_dict))) : columns
        key = join([string(get(row_dict, column, missing)) for column in selected], "\u001f")
        if !(key in seen)
            push!(seen, key)
            push!(distinct, row_dict)
        end
    end
    return finish_table_node(payload, context, DISTINCT_ROWS_NODE_KEY, output_port_id, distinct)
end

function configure(::Type{AddConstantColumnNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "value" => missing))
end
function infer_output_schema(::Type{AddConstantColumnNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Augmented Rows")
end
function execute(::Type{AddConstantColumnNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, ADD_CONSTANT_COLUMN_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    isempty(column) && error("column must not be empty")
    value = get(context.config.values, "value", missing)
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[column] = value
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, ADD_CONSTANT_COLUMN_NODE_KEY, output_port_id, output)
end

function configure(::Type{RowNumberNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "row_number", "start" => 1))
end
function infer_output_schema(::Type{RowNumberNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Numbered Rows")
end
function execute(::Type{RowNumberNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, ROW_NUMBER_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "row_number"))
    start = Int(get(context.config.values, "start", 1))
    output = Dict{String,Any}[]
    for (offset, row) in enumerate(rows)
        next_row = row_to_dict(row)
        next_row[column] = start + offset - 1
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, ROW_NUMBER_NODE_KEY, output_port_id, output)
end

function configure(::Type{ConcatRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("right_input_port_id" => "right_table_in"))
end
function infer_output_schema(::Type{ConcatRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Concatenated Rows")
end
function execute(::Type{ConcatRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    left_payload = input_payload(context, String(context.config.values["input_port_id"]))
    right_payload = input_payload(context, String(get(context.config.values, "right_input_port_id", "right_table_in")))
    left_rows = payload_rows(left_payload, context)
    right_rows = payload_rows(right_payload, context)
    if left_rows === nothing || right_rows === nothing
        return NodeResult(warnings = ["$(CONCAT_ROWS_NODE_KEY) requires inline rows for both inputs"])
    end
    output = Dict{String,Any}[]
    for row in left_rows
        checked_output_push!(output, row_to_dict(row), context)
    end
    for row in right_rows
        checked_output_push!(output, row_to_dict(row), context)
    end
    return finish_table_node(left_payload, context, CONCAT_ROWS_NODE_KEY, output_port_id, output; telemetry = Dict("right_input_ref" => String(right_payload.ref)))
end

function configure(::Type{InnerJoinRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("right_input_port_id" => "right_table_in", "left_key" => "id", "right_key" => "id"))
end
function infer_output_schema(::Type{InnerJoinRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Joined Rows")
end
function execute(::Type{InnerJoinRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    left_payload = input_payload(context, String(context.config.values["input_port_id"]))
    right_payload = input_payload(context, String(get(context.config.values, "right_input_port_id", "right_table_in")))
    left_rows = payload_rows(left_payload, context)
    right_rows = payload_rows(right_payload, context)
    if left_rows === nothing || right_rows === nothing
        return NodeResult(warnings = ["$(INNER_JOIN_ROWS_NODE_KEY) requires inline rows for both inputs"])
    end
    left_key = String(get(context.config.values, "left_key", "id"))
    right_key = String(get(context.config.values, "right_key", "id"))
    right_index = Dict{Any,Vector{Dict{String,Any}}}()
    for row in right_rows
        row_dict = row_to_dict(row)
        push!(get!(right_index, row_dict[right_key], Dict{String,Any}[]), row_dict)
    end
    joined = Dict{String,Any}[]
    for left in left_rows
        left_dict = row_to_dict(left)
        for right_dict in get(right_index, left_dict[left_key], Dict{String,Any}[])
            output_row = copy(left_dict)
            for (key, value) in right_dict
                output_row[haskey(output_row, key) ? "right_$(key)" : key] = value
            end
            checked_output_push!(joined, output_row, context)
        end
    end
    return finish_table_node(left_payload, context, INNER_JOIN_ROWS_NODE_KEY, output_port_id, joined; telemetry = Dict("right_input_ref" => String(right_payload.ref)))
end

function configure(::Type{BasicStatsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[]))
end
function infer_output_schema(::Type{BasicStatsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Basic Stats")
end
function execute(::Type{BasicStatsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, BASIC_STATS_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = [String(column) for column in get(context.config.values, "columns", String[])]
    if isempty(columns) && !isempty(rows)
        first_row = row_to_dict(first(rows))
        columns = [key for (key, value) in pairs(first_row) if value isa Number]
    end
    stats = Dict{String,Any}[]
    for column in columns
        values = numeric_values(rows, column)
        checked_output_push!(stats, Dict("column" => column, "count" => length(values), "mean" => mean_value(values), "min" => isempty(values) ? NaN : minimum(values), "max" => isempty(values) ? NaN : maximum(values)), context)
    end
    return finish_table_node(payload, context, BASIC_STATS_NODE_KEY, output_port_id, stats; schema = ["column", "count", "mean", "min", "max"])
end

function configure(::Type{TableProfileNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params)
end
function infer_output_schema(::Type{TableProfileNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Table Profile")
end
function execute(::Type{TableProfileNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, TABLE_PROFILE_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = isempty(rows) ? String[] : sort(collect(keys(row_to_dict(first(rows)))))
    profile = Dict{String,Any}[]
    for column in columns
        missing_count = count(row -> get(row_to_dict(row), column, missing) === missing || get(row_to_dict(row), column, nothing) === nothing, rows)
        checked_output_push!(profile, Dict("column" => column, "row_count" => length(rows), "missing_count" => missing_count), context)
    end
    return finish_table_node(payload, context, TABLE_PROFILE_NODE_KEY, output_port_id, profile; schema = ["column", "row_count", "missing_count"])
end

function configure(::Type{SplitRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("fraction" => 0.8, "split_column" => "split"))
end
function infer_output_schema(::Type{SplitRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Split Rows")
end
function execute(::Type{SplitRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, SPLIT_ROWS_NODE_KEY, context)
    rows isa NodeResult && return rows
    fraction = Float64(get(context.config.values, "fraction", 0.8))
    0 <= fraction <= 1 || error("fraction must be between 0 and 1")
    split_column = String(get(context.config.values, "split_column", "split"))
    cutoff = floor(Int, length(rows) * fraction)
    output = Dict{String,Any}[]
    for (index, row) in enumerate(rows)
        next_row = row_to_dict(row)
        next_row[split_column] = index <= cutoff ? "train" : "test"
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, SPLIT_ROWS_NODE_KEY, output_port_id, output)
end

function configure(::Type{DeriveRatioNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("numerator" => "", "denominator" => "", "output_column" => "ratio"))
end
function infer_output_schema(::Type{DeriveRatioNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Ratio Rows")
end
function execute(::Type{DeriveRatioNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DERIVE_RATIO_NODE_KEY, context)
    rows isa NodeResult && return rows
    numerator = String(get(context.config.values, "numerator", ""))
    denominator = String(get(context.config.values, "denominator", ""))
    output_column = String(get(context.config.values, "output_column", "ratio"))
    isempty(numerator) && error("numerator must not be empty")
    isempty(denominator) && error("denominator must not be empty")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        denom = row_value(row, denominator)
        next_row[output_column] = denom == 0 ? NaN : row_value(row, numerator) / denom
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, DERIVE_RATIO_NODE_KEY, output_port_id, output)
end

function configure(::Type{BucketizeRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "threshold" => 0.0, "output_column" => "bucket"))
end
function infer_output_schema(::Type{BucketizeRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Bucketized Rows")
end
function execute(::Type{BucketizeRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, BUCKETIZE_ROWS_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    threshold = Float64(get(context.config.values, "threshold", 0.0))
    output_column = String(get(context.config.values, "output_column", "bucket"))
    isempty(column) && error("column must not be empty")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_column] = row_value(row, column) < threshold ? "low" : "high"
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, BUCKETIZE_ROWS_NODE_KEY, output_port_id, output)
end

function configure(::Type{BIOutletNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("outlet_id" => "default", "dataset_key" => "dataset"))
end
function infer_output_schema(::Type{BIOutletNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "BI Outlet Rows")
end
function execute(::Type{BIOutletNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, BI_OUTLET_NODE_KEY, context)
    rows isa NodeResult && return rows
    output = [row_to_dict(row) for row in rows]
    outlet_id = String(get(context.config.values, "outlet_id", "default"))
    dataset_key = String(get(context.config.values, "dataset_key", "dataset"))
    return finish_table_node(payload, context, BI_OUTLET_NODE_KEY, output_port_id, output; telemetry = Dict("outlet_id" => outlet_id, "dataset_key" => dataset_key))
end

function selected_columns(config_values::Dict{String,Any}, rows)
    configured = [String(column) for column in get(config_values, "columns", String[])]
    if !isempty(configured) || isempty(rows)
        return configured
    end
    first_row = row_to_dict(first(rows))
    return [key for (key, value) in pairs(first_row) if value isa AbstractString]
end

function configure(::Type{TrimStringsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[]))
end
function infer_output_schema(::Type{TrimStringsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Trimmed Rows")
end
function execute(::Type{TrimStringsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, TRIM_STRINGS_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = selected_columns(context.config.values, rows)
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        for column in columns
            haskey(next_row, column) && next_row[column] isa AbstractString && (next_row[column] = strip(next_row[column]))
        end
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, TRIM_STRINGS_NODE_KEY, output_port_id, output; telemetry = Dict("column_count" => length(columns)))
end

function configure(::Type{NormalizeCaseNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[], "case" => "lower"))
end
function infer_output_schema(::Type{NormalizeCaseNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Case-normalized Rows")
end
function execute(::Type{NormalizeCaseNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, NORMALIZE_CASE_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = selected_columns(context.config.values, rows)
    case_mode = lowercase(String(get(context.config.values, "case", "lower")))
    case_mode in ["lower", "upper"] || error("case must be lower or upper")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        for column in columns
            if haskey(next_row, column) && next_row[column] isa AbstractString
                next_row[column] = case_mode == "upper" ? uppercase(next_row[column]) : lowercase(next_row[column])
            end
        end
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, NORMALIZE_CASE_NODE_KEY, output_port_id, output; telemetry = Dict("case" => case_mode))
end

function configure(::Type{ReplaceValuesNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "mapping" => Dict{String,Any}()))
end
function infer_output_schema(::Type{ReplaceValuesNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Replaced Rows")
end
function execute(::Type{ReplaceValuesNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, REPLACE_VALUES_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    isempty(column) && error("column must not be empty")
    mapping = Dict(String(k) => v for (k, v) in pairs(get(context.config.values, "mapping", Dict())))
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        key = string(get(next_row, column, ""))
        haskey(mapping, key) && (next_row[column] = mapping[key])
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, REPLACE_VALUES_NODE_KEY, output_port_id, output; telemetry = Dict("replacement_count" => length(mapping)))
end

function configure(::Type{RegexExtractNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("source_column" => "", "pattern" => "", "output_column" => "extracted", "group" => 1))
end
function infer_output_schema(::Type{RegexExtractNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Regex-extracted Rows")
end
function safe_regex(pattern::String)
    length(pattern) <= 256 || error("regex pattern too long")
    occursin(r"\([^)]*[+*][^)]*\)[+*]", pattern) && error("nested regex quantifiers are not allowed")
    occursin(r"\\[1-9]", pattern) && error("regex backreferences are not allowed")
    return Regex(pattern)
end
function bounded_regex_cell(value)
    text = string(value)
    length(text) <= 4096 || error("regex input too long")
    return text
end
function execute(::Type{RegexExtractNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, REGEX_EXTRACT_NODE_KEY, context)
    rows isa NodeResult && return rows
    source_column = String(get(context.config.values, "source_column", ""))
    pattern = String(get(context.config.values, "pattern", ""))
    output_column = String(get(context.config.values, "output_column", "extracted"))
    group = Int(get(context.config.values, "group", 1))
    isempty(source_column) && error("source_column must not be empty")
    isempty(pattern) && error("pattern must not be empty")
    regex = safe_regex(pattern)
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        matched = match(regex, bounded_regex_cell(row_value(row, source_column)))
        next_row[output_column] = matched === nothing || group > length(matched.captures) ? missing : matched.captures[group]
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, REGEX_EXTRACT_NODE_KEY, output_port_id, output)
end

function configure(::Type{ValidateSchemaNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("required_columns" => String[]))
end
function infer_output_schema(::Type{ValidateSchemaNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Schema Validation Rows")
end
function execute(::Type{ValidateSchemaNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, VALIDATE_SCHEMA_NODE_KEY, context)
    rows isa NodeResult && return rows
    required_columns = [String(column) for column in get(context.config.values, "required_columns", String[])]
    output = Dict{String,Any}[]
    invalid_count = 0
    for row in rows
        next_row = row_to_dict(row)
        missing_columns = [column for column in required_columns if !haskey(next_row, column)]
        next_row["__valid"] = isempty(missing_columns)
        next_row["__errors"] = join(["missing:$(column)" for column in missing_columns], ";")
        isempty(missing_columns) || (invalid_count += 1)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, VALIDATE_SCHEMA_NODE_KEY, output_port_id, output; telemetry = Dict("invalid_count" => invalid_count))
end

function configure(::Type{TopNRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "n" => 10, "descending" => true))
end
function infer_output_schema(::Type{TopNRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Top-N Rows")
end
function execute(::Type{TopNRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, TOP_N_ROWS_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    n = Int(get(context.config.values, "n", 10))
    isempty(column) && error("column must not be empty")
    n >= 0 || error("n must be >= 0")
    output = [row_to_dict(row) for row in rows]
    sort!(output, by = row -> row[column], rev = Bool(get(context.config.values, "descending", true)))
    length(output) > n && (output = output[1:n])
    return finish_table_node(payload, context, TOP_N_ROWS_NODE_KEY, output_port_id, output)
end

function configure(::Type{GroupFilterNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("group_by" => String[], "min_count" => 1))
end
function infer_output_schema(::Type{GroupFilterNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Group-filtered Rows")
end
function execute(::Type{GroupFilterNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, GROUP_FILTER_NODE_KEY, context)
    rows isa NodeResult && return rows
    group_by = [String(column) for column in get(context.config.values, "group_by", String[])]
    isempty(group_by) && error("group_by must contain at least one column")
    min_count = Int(get(context.config.values, "min_count", 1))
    counts = Dict{String,Int}()
    row_keys = String[]
    for row in rows
        row_dict = row_to_dict(row)
        key = join([string(row_dict[column]) for column in group_by], "\u001f")
        counts[key] = get(counts, key, 0) + 1
        push!(row_keys, key)
    end
    output = [row_to_dict(rows[index]) for index in eachindex(rows) if counts[row_keys[index]] >= min_count]
    return finish_table_node(payload, context, GROUP_FILTER_NODE_KEY, output_port_id, output; telemetry = Dict("group_count" => length(counts)))
end

function configure(::Type{RollingMeanNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "window" => 3, "output_column" => "rolling_mean"))
end
function infer_output_schema(::Type{RollingMeanNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Rolling Mean Rows")
end
function execute(::Type{RollingMeanNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, ROLLING_MEAN_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    window = Int(get(context.config.values, "window", 3))
    output_column = String(get(context.config.values, "output_column", "rolling_mean"))
    isempty(column) && error("column must not be empty")
    window > 0 || error("window must be > 0")
    values = [Float64(row_value(row, column)) for row in rows]
    output = Dict{String,Any}[]
    for index in eachindex(rows)
        start_index = max(1, index - window + 1)
        next_row = row_to_dict(rows[index])
        next_row[output_column] = mean_value(values[start_index:index])
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, ROLLING_MEAN_NODE_KEY, output_port_id, output)
end

function configure(::Type{RankRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "rank_column" => "rank", "descending" => true))
end
function infer_output_schema(::Type{RankRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Ranked Rows")
end
function execute(::Type{RankRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, RANK_ROWS_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    rank_column = String(get(context.config.values, "rank_column", "rank"))
    isempty(column) && error("column must not be empty")
    output = [row_to_dict(row) for row in rows]
    sort!(output, by = row -> row[column], rev = Bool(get(context.config.values, "descending", true)))
    for (rank, row) in enumerate(output)
        row[rank_column] = rank
    end
    return finish_table_node(payload, context, RANK_ROWS_NODE_KEY, output_port_id, output)
end

function percentile_value(values::Vector{Float64}, percentile::Float64)
    isempty(values) && return NaN
    sorted = sort(values)
    clamped = min(max(percentile, 0.0), 1.0)
    index = max(1, min(length(sorted), ceil(Int, clamped * length(sorted))))
    return sorted[index]
end

function configure(::Type{PercentileRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[], "percentiles" => [0.5, 0.9]))
end
function infer_output_schema(::Type{PercentileRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Percentile Rows")
end
function execute(::Type{PercentileRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, PERCENTILE_ROWS_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = [String(column) for column in get(context.config.values, "columns", String[])]
    isempty(columns) && !isempty(rows) && (columns = [key for (key, value) in pairs(row_to_dict(first(rows))) if value isa Number])
    percentiles = [Float64(value) for value in get(context.config.values, "percentiles", [0.5, 0.9])]
    output = Dict{String,Any}[]
    for column in columns
        values = numeric_values(rows, column)
        for percentile in percentiles
            checked_output_push!(output, Dict("column" => column, "percentile" => percentile, "value" => percentile_value(values, percentile)), context)
        end
    end
    return finish_table_node(payload, context, PERCENTILE_ROWS_NODE_KEY, output_port_id, output; schema = ["column", "percentile", "value"])
end


function present_value(value)
    return !(value === missing || value === nothing)
end

function typed_config_columns(config_values::Dict{String,Any}, key::String)
    return [String(column) for column in get(config_values, key, String[])]
end

function row_key(row::AbstractDict, columns::Vector{String})
    return join([string(get(row, column, missing)) for column in columns], "\u001f")
end

function configure(::Type{CoalesceColumnsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[], "output_column" => "coalesced"))
end
function infer_output_schema(::Type{CoalesceColumnsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Coalesced Rows")
end
function execute(::Type{CoalesceColumnsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, COALESCE_COLUMNS_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    output_column = String(get(context.config.values, "output_column", "coalesced"))
    isempty(columns) && error("columns must contain at least one column")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_column] = missing
        for column in columns
            value = get(next_row, column, missing)
            if present_value(value)
                next_row[output_column] = value
                break
            end
        end
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, COALESCE_COLUMNS_NODE_KEY, output_port_id, output)
end

function configure(::Type{ClipValuesNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "min" => -Inf, "max" => Inf, "output_column" => ""))
end
function infer_output_schema(::Type{ClipValuesNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Clipped Rows")
end
function execute(::Type{ClipValuesNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, CLIP_VALUES_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    isempty(column) && error("column must not be empty")
    min_value = Float64(get(context.config.values, "min", -Inf))
    max_value = Float64(get(context.config.values, "max", Inf))
    min_value <= max_value || error("min must be <= max")
    output_column = String(get(context.config.values, "output_column", ""))
    isempty(output_column) && (output_column = column)
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        value = row_value(row, column)
        value isa Number || error("column $(column) contains non-numeric value $(value)")
        next_row[output_column] = min(max(Float64(value), min_value), max_value)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, CLIP_VALUES_NODE_KEY, output_port_id, output)
end

function configure(::Type{CumulativeSumNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "output_column" => "cumulative_sum"))
end
function infer_output_schema(::Type{CumulativeSumNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Cumulative Sum Rows")
end
function execute(::Type{CumulativeSumNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, CUMULATIVE_SUM_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    output_column = String(get(context.config.values, "output_column", "cumulative_sum"))
    isempty(column) && error("column must not be empty")
    running = 0.0
    output = Dict{String,Any}[]
    for row in rows
        value = row_value(row, column)
        value isa Number || error("column $(column) contains non-numeric value $(value)")
        running += Float64(value)
        next_row = row_to_dict(row)
        next_row[output_column] = running
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, CUMULATIVE_SUM_NODE_KEY, output_port_id, output)
end

function configure(::Type{RollingSumNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "window" => 3, "output_column" => "rolling_sum"))
end
function infer_output_schema(::Type{RollingSumNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Rolling Sum Rows")
end
function execute(::Type{RollingSumNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, ROLLING_SUM_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    window = Int(get(context.config.values, "window", 3))
    output_column = String(get(context.config.values, "output_column", "rolling_sum"))
    isempty(column) && error("column must not be empty")
    window > 0 || error("window must be > 0")
    values = [Float64(row_value(row, column)) for row in rows]
    output = Dict{String,Any}[]
    for index in eachindex(rows)
        start_index = max(1, index - window + 1)
        next_row = row_to_dict(rows[index])
        next_row[output_column] = sum(values[start_index:index])
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, ROLLING_SUM_NODE_KEY, output_port_id, output)
end

function configure(::Type{LagColumnNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "offset" => 1, "output_column" => "lag", "default" => missing))
end
function infer_output_schema(::Type{LagColumnNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Lagged Rows")
end
function execute(::Type{LagColumnNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, LAG_COLUMN_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    offset = Int(get(context.config.values, "offset", 1))
    output_column = String(get(context.config.values, "output_column", "lag"))
    default_value = get(context.config.values, "default", missing)
    isempty(column) && error("column must not be empty")
    offset > 0 || error("offset must be > 0")
    output = Dict{String,Any}[]
    for index in eachindex(rows)
        next_row = row_to_dict(rows[index])
        next_row[output_column] = index > offset ? row_value(rows[index - offset], column) : default_value
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, LAG_COLUMN_NODE_KEY, output_port_id, output)
end

function configure(::Type{StringContainsFilterNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "substring" => "", "case_sensitive" => true))
end
function infer_output_schema(::Type{StringContainsFilterNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "String-filtered Rows")
end
function execute(::Type{StringContainsFilterNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, STRING_CONTAINS_FILTER_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    substring = String(get(context.config.values, "substring", ""))
    case_sensitive = Bool(get(context.config.values, "case_sensitive", true))
    isempty(column) && error("column must not be empty")
    needle = case_sensitive ? substring : lowercase(substring)
    output = Dict{String,Any}[]
    for row in rows
        haystack = string(row_value(row, column))
        haystack = case_sensitive ? haystack : lowercase(haystack)
        occursin(needle, haystack) && checked_output_push!(output, row_to_dict(row), context)
    end
    return finish_table_node(payload, context, STRING_CONTAINS_FILTER_NODE_KEY, output_port_id, output)
end

function configure(::Type{ColumnMathNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("left" => "", "right" => "", "right_value" => missing, "operation" => "add", "output_column" => "value"))
end
function infer_output_schema(::Type{ColumnMathNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Column Math Rows")
end
function execute(::Type{ColumnMathNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, COLUMN_MATH_NODE_KEY, context)
    rows isa NodeResult && return rows
    left_column = String(get(context.config.values, "left", ""))
    right_column = String(get(context.config.values, "right", ""))
    operation = lowercase(String(get(context.config.values, "operation", "add")))
    output_column = String(get(context.config.values, "output_column", "value"))
    isempty(left_column) && error("left must not be empty")
    operation in ["add", "subtract", "multiply", "divide"] || error("unsupported operation: $(operation)")
    has_right_value = get(context.config.values, "right_value", missing) !== missing
    (!isempty(right_column) || has_right_value) || error("right or right_value is required")
    output = Dict{String,Any}[]
    for row in rows
        left = Float64(row_value(row, left_column))
        right = has_right_value ? Float64(get(context.config.values, "right_value", missing)) : Float64(row_value(row, right_column))
        result = operation == "add" ? left + right : operation == "subtract" ? left - right : operation == "multiply" ? left * right : right == 0 ? NaN : left / right
        next_row = row_to_dict(row)
        next_row[output_column] = result
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, COLUMN_MATH_NODE_KEY, output_port_id, output; telemetry = Dict("operation" => operation))
end

function configure(::Type{NullIfNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "value" => ""))
end
function infer_output_schema(::Type{NullIfNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Null-if Rows")
end
function execute(::Type{NullIfNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, NULL_IF_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    expected = parse_literal(get(context.config.values, "value", ""))
    isempty(column) && error("column must not be empty")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        get(next_row, column, missing) == expected && (next_row[column] = missing)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, NULL_IF_NODE_KEY, output_port_id, output)
end

function configure(::Type{MinMaxScaleNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "output_column" => "scaled"))
end
function infer_output_schema(::Type{MinMaxScaleNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Min-max Scaled Rows")
end
function execute(::Type{MinMaxScaleNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, MIN_MAX_SCALE_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    output_column = String(get(context.config.values, "output_column", "scaled"))
    isempty(column) && error("column must not be empty")
    values = numeric_values(rows, column)
    min_value = isempty(values) ? 0.0 : minimum(values)
    range_value = isempty(values) ? 0.0 : maximum(values) - min_value
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_column] = range_value == 0 ? 0.0 : (Float64(row_value(row, column)) - min_value) / range_value
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, MIN_MAX_SCALE_NODE_KEY, output_port_id, output)
end

function configure(::Type{ZScoreNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "output_column" => "z_score"))
end
function infer_output_schema(::Type{ZScoreNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Z-score Rows")
end
function execute(::Type{ZScoreNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, Z_SCORE_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    output_column = String(get(context.config.values, "output_column", "z_score"))
    isempty(column) && error("column must not be empty")
    values = numeric_values(rows, column)
    average = mean_value(values)
    variance = isempty(values) ? 0.0 : sum((value - average)^2 for value in values) / length(values)
    stddev = sqrt(variance)
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_column] = stddev == 0 ? 0.0 : (Float64(row_value(row, column)) - average) / stddev
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, Z_SCORE_NODE_KEY, output_port_id, output)
end

function configure(::Type{LeftJoinRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("right_input_port_id" => "right_table_in", "left_key" => "id", "right_key" => "id"))
end
function infer_output_schema(::Type{LeftJoinRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Left-joined Rows")
end
function execute(::Type{LeftJoinRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    left_payload = input_payload(context, String(context.config.values["input_port_id"]))
    right_payload = input_payload(context, String(get(context.config.values, "right_input_port_id", "right_table_in")))
    left_rows = payload_rows(left_payload, context)
    right_rows = payload_rows(right_payload, context)
    if left_rows === nothing || right_rows === nothing
        return NodeResult(warnings = ["$(LEFT_JOIN_ROWS_NODE_KEY) requires inline rows for both inputs"])
    end
    left_key = String(get(context.config.values, "left_key", "id"))
    right_key = String(get(context.config.values, "right_key", "id"))
    right_index = Dict{Any,Vector{Dict{String,Any}}}()
    for row in right_rows
        row_dict = row_to_dict(row)
        push!(get!(right_index, row_dict[right_key], Dict{String,Any}[]), row_dict)
    end
    output = Dict{String,Any}[]
    for row in left_rows
        left_dict = row_to_dict(row)
        matches = get(right_index, left_dict[left_key], Dict{String,Any}[])
        if isempty(matches)
            checked_output_push!(output, left_dict, context)
        else
            for right_dict in matches
                next_row = copy(left_dict)
                for (key, value) in right_dict
                    next_row[haskey(next_row, key) ? "right_$(key)" : key] = value
                end
                checked_output_push!(output, next_row, context)
            end
        end
    end
    return finish_table_node(left_payload, context, LEFT_JOIN_ROWS_NODE_KEY, output_port_id, output; telemetry = Dict("right_input_ref" => String(right_payload.ref)))
end

function configure(::Type{AntiJoinRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("right_input_port_id" => "right_table_in", "left_key" => "id", "right_key" => "id"))
end
function infer_output_schema(::Type{AntiJoinRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Anti-joined Rows")
end
function execute(::Type{AntiJoinRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    left_payload = input_payload(context, String(context.config.values["input_port_id"]))
    right_payload = input_payload(context, String(get(context.config.values, "right_input_port_id", "right_table_in")))
    left_rows = payload_rows(left_payload, context)
    right_rows = payload_rows(right_payload, context)
    if left_rows === nothing || right_rows === nothing
        return NodeResult(warnings = ["$(ANTI_JOIN_ROWS_NODE_KEY) requires inline rows for both inputs"])
    end
    left_key = String(get(context.config.values, "left_key", "id"))
    right_key = String(get(context.config.values, "right_key", "id"))
    right_keys = Set{Any}([row_value(row, right_key) for row in right_rows])
    output = Dict{String,Any}[]
    for row in left_rows
        if !(row_value(row, left_key) in right_keys)
            checked_output_push!(output, row_to_dict(row), context)
        end
    end
    return finish_table_node(left_payload, context, ANTI_JOIN_ROWS_NODE_KEY, output_port_id, output; telemetry = Dict("right_input_ref" => String(right_payload.ref)))
end

function configure(::Type{UnionDistinctRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("right_input_port_id" => "right_table_in", "columns" => String[]))
end
function infer_output_schema(::Type{UnionDistinctRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Union-distinct Rows")
end
function execute(::Type{UnionDistinctRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    left_payload = input_payload(context, String(context.config.values["input_port_id"]))
    right_payload = input_payload(context, String(get(context.config.values, "right_input_port_id", "right_table_in")))
    left_rows = payload_rows(left_payload, context)
    right_rows = payload_rows(right_payload, context)
    if left_rows === nothing || right_rows === nothing
        return NodeResult(warnings = ["$(UNION_DISTINCT_ROWS_NODE_KEY) requires inline rows for both inputs"])
    end
    columns = typed_config_columns(context.config.values, "columns")
    output = Dict{String,Any}[]
    seen = Set{String}()
    for source_rows in (left_rows, right_rows)
        for row in source_rows
            row_dict = row_to_dict(row)
        key_columns = isempty(columns) ? sort(collect(keys(row_dict))) : columns
        key = row_key(row_dict, key_columns)
            if !(key in seen)
                push!(seen, key)
                checked_output_push!(output, row_dict, context)
            end
        end
    end
    return finish_table_node(left_payload, context, UNION_DISTINCT_ROWS_NODE_KEY, output_port_id, output; telemetry = Dict("right_input_ref" => String(right_payload.ref)))
end

function configure(::Type{UnpivotRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("id_columns" => String[], "value_columns" => String[], "name_column" => "variable", "value_column" => "value"))
end
function infer_output_schema(::Type{UnpivotRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Unpivoted Rows")
end
function execute(::Type{UnpivotRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, UNPIVOT_ROWS_NODE_KEY, context)
    rows isa NodeResult && return rows
    id_columns = typed_config_columns(context.config.values, "id_columns")
    value_columns = typed_config_columns(context.config.values, "value_columns")
    name_column = String(get(context.config.values, "name_column", "variable"))
    value_column = String(get(context.config.values, "value_column", "value"))
    isempty(value_columns) && error("value_columns must contain at least one column")
    output = Dict{String,Any}[]
    for row in rows
        row_dict = row_to_dict(row)
        for column in value_columns
            next_row = Dict{String,Any}()
            for id_column in id_columns
                next_row[id_column] = get(row_dict, id_column, missing)
            end
            next_row[name_column] = column
            next_row[value_column] = get(row_dict, column, missing)
            checked_output_push!(output, next_row, context)
        end
    end
    return finish_table_node(payload, context, UNPIVOT_ROWS_NODE_KEY, output_port_id, output)
end

function configure(::Type{PivotRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("index_columns" => String[], "names_from" => "", "values_from" => ""))
end
function infer_output_schema(::Type{PivotRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Pivoted Rows")
end
function execute(::Type{PivotRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, PIVOT_ROWS_NODE_KEY, context)
    rows isa NodeResult && return rows
    index_columns = typed_config_columns(context.config.values, "index_columns")
    names_from = String(get(context.config.values, "names_from", ""))
    values_from = String(get(context.config.values, "values_from", ""))
    isempty(index_columns) && error("index_columns must contain at least one column")
    isempty(names_from) && error("names_from must not be empty")
    isempty(values_from) && error("values_from must not be empty")
    groups = Dict{String,Dict{String,Any}}()
    order = String[]
    for row in rows
        row_dict = row_to_dict(row)
        key = row_key(row_dict, index_columns)
        if !haskey(groups, key)
            groups[key] = Dict{String,Any}(column => row_dict[column] for column in index_columns)
            push!(order, key)
        end
        groups[key][string(row_dict[names_from])] = row_dict[values_from]
    end
    output = Dict{String,Any}[]
    for key in order
        checked_output_push!(output, groups[key], context)
    end
    return finish_table_node(payload, context, PIVOT_ROWS_NODE_KEY, output_port_id, output)
end

for node_type in (
    RenameColumnsNode, CastColumnsNode, FillMissingNode, DropMissingNode, SortRowsNode,
    LimitRowsNode, SampleRowsNode, DistinctRowsNode, AddConstantColumnNode, RowNumberNode,
    ConcatRowsNode, InnerJoinRowsNode, BasicStatsNode, TableProfileNode, SplitRowsNode,
    DeriveRatioNode, BucketizeRowsNode, BIOutletNode, TrimStringsNode, NormalizeCaseNode,
    ReplaceValuesNode, RegexExtractNode, ValidateSchemaNode, TopNRowsNode, GroupFilterNode,
    RollingMeanNode, RankRowsNode, PercentileRowsNode, CoalesceColumnsNode, ClipValuesNode,
    CumulativeSumNode, RollingSumNode, LagColumnNode, StringContainsFilterNode, ColumnMathNode,
    NullIfNode, MinMaxScaleNode, ZScoreNode, LeftJoinRowsNode, AntiJoinRowsNode,
    UnionDistinctRowsNode, UnpivotRowsNode, PivotRowsNode,
)
    @eval function on_stream_event(::Type{$node_type}, event, state, ::NodeContext)
        return (event, state)
    end
end
