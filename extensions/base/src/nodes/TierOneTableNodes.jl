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
const DEDUPE_BY_KEY_NODE_KEY = "base.dedupe_by_key"
const VALUE_COUNTS_NODE_KEY = "base.value_counts"
const MISSINGNESS_SUMMARY_NODE_KEY = "base.missingness_summary"
const PARSE_DATE_NODE_KEY = "base.parse_date"
const DATE_BUCKET_NODE_KEY = "base.date_bucket"
const DATE_PARTS_NODE_KEY = "base.date_parts"
const SPLIT_COLUMN_NODE_KEY = "base.split_column"
const TOP_N_PER_GROUP_NODE_KEY = "base.top_n_per_group"
const WEIGHTED_AVERAGE_NODE_KEY = "base.weighted_average"
const GROUP_ROW_NUMBER_NODE_KEY = "base.group_row_number"
const MOVING_MIN_NODE_KEY = "base.moving_min"
const MOVING_MAX_NODE_KEY = "base.moving_max"
const CUMULATIVE_COUNT_NODE_KEY = "base.cumulative_count"
const RIGHT_JOIN_ROWS_NODE_KEY = "base.right_join_rows"
const FULL_JOIN_ROWS_NODE_KEY = "base.full_join_rows"
const SEMI_JOIN_ROWS_NODE_KEY = "base.semi_join_rows"
const LOOKUP_ENRICH_NODE_KEY = "base.lookup_enrich"
const METRIC_DEFINITION_NODE_KEY = "base.metric_definition"
const DIMENSION_MAPPING_NODE_KEY = "base.dimension_mapping"
const KPI_THRESHOLD_NODE_KEY = "base.kpi_threshold"
const CHART_DATASET_NODE_KEY = "base.chart_dataset"
const BOOLEAN_FLAG_NODE_KEY = "base.boolean_flag"
const TYPE_PROFILE_NODE_KEY = "base.type_profile"
const ROW_HASH_NODE_KEY = "base.row_hash"
const NORMALIZE_WHITESPACE_NODE_KEY = "base.normalize_whitespace"
const DROP_COLUMNS_NODE_KEY = "base.drop_columns"
const KEEP_COLUMNS_MATCHING_NODE_KEY = "base.keep_columns_matching"
const COPY_COLUMN_NODE_KEY = "base.copy_column"
const CONCAT_COLUMNS_NODE_KEY = "base.concat_columns"
const SUBSTRING_COLUMN_NODE_KEY = "base.substring_column"
const STRING_LENGTH_NODE_KEY = "base.string_length"
const REGEX_REPLACE_NODE_KEY = "base.regex_replace"
const ROUND_NUMBER_NODE_KEY = "base.round_number"
const ABSOLUTE_VALUE_NODE_KEY = "base.absolute_value"
const LOG_TRANSFORM_NODE_KEY = "base.log_transform"
const PERCENT_CHANGE_NODE_KEY = "base.percent_change"
const LEAD_COLUMN_NODE_KEY = "base.lead_column"
const CUMULATIVE_MEAN_NODE_KEY = "base.cumulative_mean"
const GROUP_SUM_NODE_KEY = "base.group_sum"
const GROUP_MEAN_NODE_KEY = "base.group_mean"
const GROUP_MIN_NODE_KEY = "base.group_min"
const GROUP_MAX_NODE_KEY = "base.group_max"
const GROUP_COUNT_NODE_KEY = "base.group_count"
const GROUP_PERCENT_OF_TOTAL_NODE_KEY = "base.group_percent_of_total"
const BUCKET_BY_THRESHOLDS_NODE_KEY = "base.bucket_by_thresholds"
const QUANTILE_BUCKET_NODE_KEY = "base.quantile_bucket"
const ONE_HOT_ENCODE_NODE_KEY = "base.one_hot_encode"
const METRIC_CARDS_NODE_KEY = "base.metric_cards"
const DASHBOARD_SUMMARY_NODE_KEY = "base.dashboard_summary"
const ROWS_TO_COLUMNS_NODE_KEY = "base.rows_to_columns"
const CORRELATION_NODE_KEY = "base.correlation"
const COVARIANCE_NODE_KEY = "base.covariance"
const HISTOGRAM_NODE_KEY = "base.histogram"
const OUTLIER_FLAG_NODE_KEY = "base.outlier_flag"
const STANDARDIZE_COLUMNS_NODE_KEY = "base.standardize_columns"
const TRAIN_TEST_SPLIT_NODE_KEY = "base.train_test_split"
const LINEAR_SCORE_NODE_KEY = "base.linear_score"
const CLASSIFICATION_THRESHOLD_NODE_KEY = "base.classification_threshold"
const CONFUSION_MATRIX_NODE_KEY = "base.confusion_matrix"
const REGRESSION_METRICS_NODE_KEY = "base.regression_metrics"
const KMEANS_ASSIGN_NODE_KEY = "base.kmeans_assign"
const PCA_PROJECT_NODE_KEY = "base.pca_project"
const EVENT_TIME_ASSIGN_NODE_KEY = "base.event_time_assign"
const WATERMARK_FLAG_NODE_KEY = "base.watermark_flag"
const TUMBLING_WINDOW_NODE_KEY = "base.tumbling_window"
const SLIDING_WINDOW_NODE_KEY = "base.sliding_window"
const STREAM_AGGREGATE_NODE_KEY = "base.stream_aggregate"
const DEDUPE_EVENT_ID_NODE_KEY = "base.dedupe_event_id"
const SINK_TRANSACTION_MARKER_NODE_KEY = "base.sink_transaction_marker"
const EXTENSION_MANIFEST_VALIDATE_NODE_KEY = "base.extension_manifest_validate"
const COMPATIBILITY_REPORT_NODE_KEY = "base.compatibility_report"
const PACKAGE_HASH_VERIFY_NODE_KEY = "base.package_hash_verify"
const OBJECT_STORE_LIST_NODE_KEY = "base.object_store_list"
const DATASET_VERSION_NODE_KEY = "base.dataset_version"
const SCHEMA_DRIFT_NODE_KEY = "base.schema_drift"
const COLUMN_PRESENCE_NODE_KEY = "base.column_presence"
const NULL_RATE_NODE_KEY = "base.null_rate"
const DUPLICATE_RATE_NODE_KEY = "base.duplicate_rate"
const CARDINALITY_NODE_KEY = "base.cardinality"
const COLUMN_SELECT_BY_TYPE_NODE_KEY = "base.column_select_by_type"
const TIME_SINCE_PREVIOUS_NODE_KEY = "base.time_since_previous"
const SESSIONIZE_EVENTS_NODE_KEY = "base.sessionize_events"
const WINDOW_LAG_DELTA_NODE_KEY = "base.window_lag_delta"
const ROLLING_STD_NODE_KEY = "base.rolling_std"
const EXPANDING_MAX_NODE_KEY = "base.expanding_max"
const CROSS_JOIN_ROWS_NODE_KEY = "base.cross_join_rows"
const APPEND_METADATA_NODE_KEY = "base.append_metadata"
const MASK_COLUMN_NODE_KEY = "base.mask_column"
const TOKENIZE_COLUMN_NODE_KEY = "base.tokenize_column"
const EXPLODE_LIST_NODE_KEY = "base.explode_list"
const JSON_EXTRACT_FIELD_NODE_KEY = "base.json_extract_field"
const DATASET_LINEAGE_NODE_KEY = "base.dataset_lineage"
const POLICY_TAG_NODE_KEY = "base.policy_tag"
const ACCESS_DECISION_NODE_KEY = "base.access_decision"
const GPU_CAPABILITY_FLAG_NODE_KEY = "base.gpu_capability_flag"
const BATCH_ID_ASSIGN_NODE_KEY = "base.batch_id_assign"
const REPLAY_OFFSET_NODE_KEY = "base.replay_offset"
const EXACTLY_ONCE_KEY_NODE_KEY = "base.exactly_once_key"
const SINK_COMMIT_PLAN_NODE_KEY = "base.sink_commit_plan"
const FEATURE_VECTOR_NODE_KEY = "base.feature_vector"

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
struct DedupeByKeyNode <: AbstractNode end
struct ValueCountsNode <: AbstractNode end
struct MissingnessSummaryNode <: AbstractNode end
struct ParseDateNode <: AbstractNode end
struct DateBucketNode <: AbstractNode end
struct DatePartsNode <: AbstractNode end
struct SplitColumnNode <: AbstractNode end
struct TopNPerGroupNode <: AbstractNode end
struct WeightedAverageNode <: AbstractNode end
struct GroupRowNumberNode <: AbstractNode end
struct MovingMinNode <: AbstractNode end
struct MovingMaxNode <: AbstractNode end
struct CumulativeCountNode <: AbstractNode end
struct RightJoinRowsNode <: AbstractNode end
struct FullJoinRowsNode <: AbstractNode end
struct SemiJoinRowsNode <: AbstractNode end
struct LookupEnrichNode <: AbstractNode end
struct MetricDefinitionNode <: AbstractNode end
struct DimensionMappingNode <: AbstractNode end
struct KpiThresholdNode <: AbstractNode end
struct ChartDatasetNode <: AbstractNode end
struct BooleanFlagNode <: AbstractNode end
struct TypeProfileNode <: AbstractNode end
struct RowHashNode <: AbstractNode end
struct NormalizeWhitespaceNode <: AbstractNode end
struct DropColumnsNode <: AbstractNode end
struct KeepColumnsMatchingNode <: AbstractNode end
struct CopyColumnNode <: AbstractNode end
struct ConcatColumnsNode <: AbstractNode end
struct SubstringColumnNode <: AbstractNode end
struct StringLengthNode <: AbstractNode end
struct RegexReplaceNode <: AbstractNode end
struct RoundNumberNode <: AbstractNode end
struct AbsoluteValueNode <: AbstractNode end
struct LogTransformNode <: AbstractNode end
struct PercentChangeNode <: AbstractNode end
struct LeadColumnNode <: AbstractNode end
struct CumulativeMeanNode <: AbstractNode end
struct GroupSumNode <: AbstractNode end
struct GroupMeanNode <: AbstractNode end
struct GroupMinNode <: AbstractNode end
struct GroupMaxNode <: AbstractNode end
struct GroupCountNode <: AbstractNode end
struct GroupPercentOfTotalNode <: AbstractNode end
struct BucketByThresholdsNode <: AbstractNode end
struct QuantileBucketNode <: AbstractNode end
struct OneHotEncodeNode <: AbstractNode end
struct MetricCardsNode <: AbstractNode end
struct DashboardSummaryNode <: AbstractNode end
struct RowsToColumnsNode <: AbstractNode end
struct CorrelationNode <: AbstractNode end
struct CovarianceNode <: AbstractNode end
struct HistogramNode <: AbstractNode end
struct OutlierFlagNode <: AbstractNode end
struct StandardizeColumnsNode <: AbstractNode end
struct TrainTestSplitNode <: AbstractNode end
struct LinearScoreNode <: AbstractNode end
struct ClassificationThresholdNode <: AbstractNode end
struct ConfusionMatrixNode <: AbstractNode end
struct RegressionMetricsNode <: AbstractNode end
struct KMeansAssignNode <: AbstractNode end
struct PcaProjectNode <: AbstractNode end
struct EventTimeAssignNode <: AbstractNode end
struct WatermarkFlagNode <: AbstractNode end
struct TumblingWindowNode <: AbstractNode end
struct SlidingWindowNode <: AbstractNode end
struct StreamAggregateNode <: AbstractNode end
struct DedupeEventIdNode <: AbstractNode end
struct SinkTransactionMarkerNode <: AbstractNode end
struct ExtensionManifestValidateNode <: AbstractNode end
struct CompatibilityReportNode <: AbstractNode end
struct PackageHashVerifyNode <: AbstractNode end
struct ObjectStoreListNode <: AbstractNode end
struct DatasetVersionNode <: AbstractNode end
struct SchemaDriftNode <: AbstractNode end
struct ColumnPresenceNode <: AbstractNode end
struct NullRateNode <: AbstractNode end
struct DuplicateRateNode <: AbstractNode end
struct CardinalityNode <: AbstractNode end
struct ColumnSelectByTypeNode <: AbstractNode end
struct TimeSincePreviousNode <: AbstractNode end
struct SessionizeEventsNode <: AbstractNode end
struct WindowLagDeltaNode <: AbstractNode end
struct RollingStdNode <: AbstractNode end
struct ExpandingMaxNode <: AbstractNode end
struct CrossJoinRowsNode <: AbstractNode end
struct AppendMetadataNode <: AbstractNode end
struct MaskColumnNode <: AbstractNode end
struct TokenizeColumnNode <: AbstractNode end
struct ExplodeListNode <: AbstractNode end
struct JsonExtractFieldNode <: AbstractNode end
struct DatasetLineageNode <: AbstractNode end
struct PolicyTagNode <: AbstractNode end
struct AccessDecisionNode <: AbstractNode end
struct GpuCapabilityFlagNode <: AbstractNode end
struct BatchIdAssignNode <: AbstractNode end
struct ReplayOffsetNode <: AbstractNode end
struct ExactlyOnceKeyNode <: AbstractNode end
struct SinkCommitPlanNode <: AbstractNode end
struct FeatureVectorNode <: AbstractNode end

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


function simple_date_parts(value)
    text = String(strip(string(value)))
    matched = match(r"^(\d{4})-(\d{2})-(\d{2})", text)
    matched === nothing && error("date value must start with YYYY-MM-DD")
    year = parse(Int, matched.captures[1])
    month = parse(Int, matched.captures[2])
    day = parse(Int, matched.captures[3])
    1 <= month <= 12 || error("date month out of range")
    1 <= day <= 31 || error("date day out of range")
    return (year = year, month = month, day = day, iso = @sprintf("%04d-%02d-%02d", year, month, day))
end

function group_join_key(row::AbstractDict, key::String)
    haskey(row, key) || error("row missing key $(key)")
    return row[key]
end

function merge_join_rows(left::AbstractDict, right::AbstractDict)
    output = copy(left)
    for (key, value) in right
        output[haskey(output, key) ? "right_$(key)" : key] = value
    end
    return output
end

function right_index_rows(rows, key::String)
    index = Dict{Any,Vector{Dict{String,Any}}}()
    for row in rows
        row_dict = row_to_dict(row)
        push!(get!(index, group_join_key(row_dict, key), Dict{String,Any}[]), row_dict)
    end
    return index
end

function stable_row_fingerprint(row::AbstractDict, columns::Vector{String})
    selected = isempty(columns) ? sort(collect(keys(row))) : columns
    total = UInt64(1469598103934665603)
    for column in selected
        token = string(column, "=", get(row, column, missing), "|")
        for byte in codeunits(token)
            total = (total ⊻ UInt64(byte)) * UInt64(1099511628211)
        end
    end
    return string(total, base = 16)
end

function condition_passes(value, operator::String, threshold)
    operator == "gt" && return value > threshold
    operator == "gte" && return value >= threshold
    operator == "lt" && return value < threshold
    operator == "lte" && return value <= threshold
    operator == "eq" && return value == threshold
    operator == "neq" && return value != threshold
    error("unsupported operator: $(operator)")
end

function configure(::Type{DedupeByKeyNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[], "keep" => "first"))
end
function infer_output_schema(::Type{DedupeByKeyNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Deduplicated Rows")
end
function execute(::Type{DedupeByKeyNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DEDUPE_BY_KEY_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    keep = lowercase(String(get(context.config.values, "keep", "first")))
    keep in ["first", "last"] || error("keep must be first or last")
    output = Dict{String,Any}[]
    seen = Set{String}()
    source = keep == "first" ? rows : reverse(rows)
    for row in source
        row_dict = row_to_dict(row)
        key = row_key(row_dict, isempty(columns) ? sort(collect(keys(row_dict))) : columns)
        if !(key in seen)
            push!(seen, key)
            push!(output, row_dict)
        end
    end
    keep == "last" && reverse!(output)
    return finish_table_node(payload, context, DEDUPE_BY_KEY_NODE_KEY, output_port_id, output; telemetry = Dict("dedupe_key_count" => length(seen)))
end

function configure(::Type{ValueCountsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "count_column" => "count"))
end
function infer_output_schema(::Type{ValueCountsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Value Counts")
end
function execute(::Type{ValueCountsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, VALUE_COUNTS_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    count_column = String(get(context.config.values, "count_column", "count"))
    isempty(column) && error("column must not be empty")
    counts = Dict{Any,Int}()
    for row in rows
        value = get(row_to_dict(row), column, missing)
        counts[value] = get(counts, value, 0) + 1
    end
    output = Dict{String,Any}[]
    for value in sort(collect(keys(counts)); by = string)
        checked_output_push!(output, Dict(column => value, count_column => counts[value]), context)
    end
    return finish_table_node(payload, context, VALUE_COUNTS_NODE_KEY, output_port_id, output; schema = [column, count_column])
end

function configure(::Type{MissingnessSummaryNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[]))
end
function infer_output_schema(::Type{MissingnessSummaryNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Missingness Summary")
end
function execute(::Type{MissingnessSummaryNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, MISSINGNESS_SUMMARY_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    isempty(columns) && !isempty(rows) && (columns = sort(collect(keys(row_to_dict(first(rows))))))
    output = Dict{String,Any}[]
    for column in columns
        missing_count = count(row -> !present_value(get(row_to_dict(row), column, missing)), rows)
        checked_output_push!(output, Dict("column" => column, "row_count" => length(rows), "missing_count" => missing_count, "missing_ratio" => isempty(rows) ? 0.0 : missing_count / length(rows)), context)
    end
    return finish_table_node(payload, context, MISSINGNESS_SUMMARY_NODE_KEY, output_port_id, output; schema = ["column", "row_count", "missing_count", "missing_ratio"])
end

function configure(::Type{ParseDateNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "output_column" => "parsed_date"))
end
function infer_output_schema(::Type{ParseDateNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Parsed Date Rows")
end
function execute(::Type{ParseDateNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, PARSE_DATE_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    output_column = String(get(context.config.values, "output_column", "parsed_date"))
    isempty(column) && error("column must not be empty")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_column] = simple_date_parts(row_value(row, column)).iso
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, PARSE_DATE_NODE_KEY, output_port_id, output)
end

function configure(::Type{DateBucketNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "granularity" => "month", "output_column" => "date_bucket"))
end
function infer_output_schema(::Type{DateBucketNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Date-bucketed Rows")
end
function execute(::Type{DateBucketNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DATE_BUCKET_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    granularity = lowercase(String(get(context.config.values, "granularity", "month")))
    output_column = String(get(context.config.values, "output_column", "date_bucket"))
    granularity in ["year", "month", "day"] || error("granularity must be year, month, or day")
    output = Dict{String,Any}[]
    for row in rows
        parts = simple_date_parts(row_value(row, column))
        bucket = granularity == "year" ? @sprintf("%04d", parts.year) : granularity == "month" ? @sprintf("%04d-%02d", parts.year, parts.month) : parts.iso
        next_row = row_to_dict(row)
        next_row[output_column] = bucket
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, DATE_BUCKET_NODE_KEY, output_port_id, output; telemetry = Dict("granularity" => granularity))
end

function configure(::Type{DatePartsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "prefix" => "date"))
end
function infer_output_schema(::Type{DatePartsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Date Part Rows")
end
function execute(::Type{DatePartsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DATE_PARTS_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    prefix = String(get(context.config.values, "prefix", "date"))
    isempty(column) && error("column must not be empty")
    output = Dict{String,Any}[]
    for row in rows
        parts = simple_date_parts(row_value(row, column))
        next_row = row_to_dict(row)
        next_row["$(prefix)_year"] = parts.year
        next_row["$(prefix)_month"] = parts.month
        next_row["$(prefix)_day"] = parts.day
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, DATE_PARTS_NODE_KEY, output_port_id, output)
end

function configure(::Type{SplitColumnNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "delimiter" => " ", "output_columns" => String[]))
end
function infer_output_schema(::Type{SplitColumnNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Split Column Rows")
end
function execute(::Type{SplitColumnNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, SPLIT_COLUMN_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    delimiter = String(get(context.config.values, "delimiter", " "))
    output_columns = typed_config_columns(context.config.values, "output_columns")
    isempty(column) && error("column must not be empty")
    isempty(output_columns) && error("output_columns must contain at least one column")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        pieces = split(string(row_value(row, column)), delimiter; keepempty = true)
        for (index, output_column) in enumerate(output_columns)
            next_row[output_column] = index <= length(pieces) ? String(pieces[index]) : missing
        end
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, SPLIT_COLUMN_NODE_KEY, output_port_id, output)
end

function configure(::Type{TopNPerGroupNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("group_by" => String[], "order_by" => "", "n" => 1, "descending" => true))
end
function infer_output_schema(::Type{TopNPerGroupNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Top-N Per Group Rows")
end
function execute(::Type{TopNPerGroupNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, TOP_N_PER_GROUP_NODE_KEY, context)
    rows isa NodeResult && return rows
    group_by = typed_config_columns(context.config.values, "group_by")
    order_by = String(get(context.config.values, "order_by", ""))
    n = Int(get(context.config.values, "n", 1))
    isempty(group_by) && error("group_by must contain at least one column")
    isempty(order_by) && error("order_by must not be empty")
    n >= 0 || error("n must be >= 0")
    groups = Dict{String,Vector{Dict{String,Any}}}()
    for row in rows
        row_dict = row_to_dict(row)
        push!(get!(groups, row_key(row_dict, group_by), Dict{String,Any}[]), row_dict)
    end
    output = Dict{String,Any}[]
    for key in sort(collect(keys(groups)))
        group_rows = groups[key]
        sort!(group_rows, by = row -> row[order_by], rev = Bool(get(context.config.values, "descending", true)))
        for row in group_rows[1:min(n, length(group_rows))]
            checked_output_push!(output, row, context)
        end
    end
    return finish_table_node(payload, context, TOP_N_PER_GROUP_NODE_KEY, output_port_id, output)
end

function configure(::Type{WeightedAverageNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("group_by" => String[], "value_column" => "", "weight_column" => "", "output_column" => "weighted_average"))
end
function infer_output_schema(::Type{WeightedAverageNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Weighted Average Rows")
end
function execute(::Type{WeightedAverageNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, WEIGHTED_AVERAGE_NODE_KEY, context)
    rows isa NodeResult && return rows
    group_by = typed_config_columns(context.config.values, "group_by")
    value_column = String(get(context.config.values, "value_column", ""))
    weight_column = String(get(context.config.values, "weight_column", ""))
    output_column = String(get(context.config.values, "output_column", "weighted_average"))
    isempty(value_column) && error("value_column must not be empty")
    isempty(weight_column) && error("weight_column must not be empty")
    groups = Dict{String,Dict{String,Any}}()
    order = String[]
    for row in rows
        row_dict = row_to_dict(row)
        key = isempty(group_by) ? "__all__" : row_key(row_dict, group_by)
        if !haskey(groups, key)
            groups[key] = Dict{String,Any}("weighted_sum" => 0.0, "weight_sum" => 0.0)
            for column in group_by
                groups[key][column] = row_dict[column]
            end
            push!(order, key)
        end
        weight = Float64(row_value(row_dict, weight_column))
        groups[key]["weighted_sum"] += Float64(row_value(row_dict, value_column)) * weight
        groups[key]["weight_sum"] += weight
    end
    output = Dict{String,Any}[]
    for key in order
        item = groups[key]
        row = Dict{String,Any}(column => item[column] for column in group_by)
        row[output_column] = item["weight_sum"] == 0 ? NaN : item["weighted_sum"] / item["weight_sum"]
        checked_output_push!(output, row, context)
    end
    return finish_table_node(payload, context, WEIGHTED_AVERAGE_NODE_KEY, output_port_id, output)
end

function configure(::Type{GroupRowNumberNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("group_by" => String[], "order_by" => "", "column" => "group_row_number"))
end
function infer_output_schema(::Type{GroupRowNumberNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Group Row Number Rows")
end
function execute(::Type{GroupRowNumberNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, GROUP_ROW_NUMBER_NODE_KEY, context)
    rows isa NodeResult && return rows
    group_by = typed_config_columns(context.config.values, "group_by")
    order_by = String(get(context.config.values, "order_by", ""))
    column = String(get(context.config.values, "column", "group_row_number"))
    grouped = Dict{String,Vector{Dict{String,Any}}}()
    order = String[]
    for row in rows
        row_dict = row_to_dict(row)
        key = isempty(group_by) ? "__all__" : row_key(row_dict, group_by)
        haskey(grouped, key) || push!(order, key)
        push!(get!(grouped, key, Dict{String,Any}[]), row_dict)
    end
    output = Dict{String,Any}[]
    for key in order
        group_rows = grouped[key]
        isempty(order_by) || sort!(group_rows, by = row -> row[order_by])
        for (index, row) in enumerate(group_rows)
            row[column] = index
            checked_output_push!(output, row, context)
        end
    end
    return finish_table_node(payload, context, GROUP_ROW_NUMBER_NODE_KEY, output_port_id, output)
end

function configure(::Type{MovingMinNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "window" => 3, "output_column" => "moving_min"))
end
function infer_output_schema(::Type{MovingMinNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Moving Min Rows")
end
function execute(::Type{MovingMinNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, MOVING_MIN_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    window = Int(get(context.config.values, "window", 3))
    output_column = String(get(context.config.values, "output_column", "moving_min"))
    isempty(column) && error("column must not be empty")
    window > 0 || error("window must be > 0")
    values = [Float64(row_value(row, column)) for row in rows]
    output = Dict{String,Any}[]
    for index in eachindex(rows)
        next_row = row_to_dict(rows[index])
        next_row[output_column] = minimum(values[max(1, index - window + 1):index])
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, MOVING_MIN_NODE_KEY, output_port_id, output)
end

function configure(::Type{MovingMaxNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "window" => 3, "output_column" => "moving_max"))
end
function infer_output_schema(::Type{MovingMaxNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Moving Max Rows")
end
function execute(::Type{MovingMaxNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, MOVING_MAX_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    window = Int(get(context.config.values, "window", 3))
    output_column = String(get(context.config.values, "output_column", "moving_max"))
    isempty(column) && error("column must not be empty")
    window > 0 || error("window must be > 0")
    values = [Float64(row_value(row, column)) for row in rows]
    output = Dict{String,Any}[]
    for index in eachindex(rows)
        next_row = row_to_dict(rows[index])
        next_row[output_column] = maximum(values[max(1, index - window + 1):index])
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, MOVING_MAX_NODE_KEY, output_port_id, output)
end

function configure(::Type{CumulativeCountNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "cumulative_count"))
end
function infer_output_schema(::Type{CumulativeCountNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Cumulative Count Rows")
end
function execute(::Type{CumulativeCountNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, CUMULATIVE_COUNT_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "cumulative_count"))
    output = Dict{String,Any}[]
    for (index, row) in enumerate(rows)
        next_row = row_to_dict(row)
        next_row[column] = index
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, CUMULATIVE_COUNT_NODE_KEY, output_port_id, output)
end

function configure(::Type{RightJoinRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("right_input_port_id" => "right_table_in", "left_key" => "id", "right_key" => "id"))
end
function infer_output_schema(::Type{RightJoinRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Right-joined Rows")
end
function execute(::Type{RightJoinRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    left_payload = input_payload(context, String(context.config.values["input_port_id"]))
    right_payload = input_payload(context, String(get(context.config.values, "right_input_port_id", "right_table_in")))
    left_rows = payload_rows(left_payload, context)
    right_rows = payload_rows(right_payload, context)
    if left_rows === nothing || right_rows === nothing
        return NodeResult(warnings = ["$(RIGHT_JOIN_ROWS_NODE_KEY) requires inline rows for both inputs"])
    end
    left_key = String(get(context.config.values, "left_key", "id"))
    right_key = String(get(context.config.values, "right_key", "id"))
    left_index = right_index_rows(left_rows, left_key)
    output = Dict{String,Any}[]
    for right in right_rows
        right_dict = row_to_dict(right)
        matches = get(left_index, group_join_key(right_dict, right_key), Dict{String,Any}[])
        if isempty(matches)
            checked_output_push!(output, right_dict, context)
        else
            for left_dict in matches
                checked_output_push!(output, merge_join_rows(left_dict, right_dict), context)
            end
        end
    end
    return finish_table_node(left_payload, context, RIGHT_JOIN_ROWS_NODE_KEY, output_port_id, output; telemetry = Dict("right_input_ref" => String(right_payload.ref)))
end

function configure(::Type{FullJoinRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("right_input_port_id" => "right_table_in", "left_key" => "id", "right_key" => "id"))
end
function infer_output_schema(::Type{FullJoinRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Full-joined Rows")
end
function execute(::Type{FullJoinRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    left_payload = input_payload(context, String(context.config.values["input_port_id"]))
    right_payload = input_payload(context, String(get(context.config.values, "right_input_port_id", "right_table_in")))
    left_rows = payload_rows(left_payload, context)
    right_rows = payload_rows(right_payload, context)
    if left_rows === nothing || right_rows === nothing
        return NodeResult(warnings = ["$(FULL_JOIN_ROWS_NODE_KEY) requires inline rows for both inputs"])
    end
    left_key = String(get(context.config.values, "left_key", "id"))
    right_key = String(get(context.config.values, "right_key", "id"))
    right_index = right_index_rows(right_rows, right_key)
    matched_right = Set{Any}()
    output = Dict{String,Any}[]
    for left in left_rows
        left_dict = row_to_dict(left)
        key = group_join_key(left_dict, left_key)
        matches = get(right_index, key, Dict{String,Any}[])
        if isempty(matches)
            checked_output_push!(output, left_dict, context)
        else
            push!(matched_right, key)
            for right_dict in matches
                checked_output_push!(output, merge_join_rows(left_dict, right_dict), context)
            end
        end
    end
    for right in right_rows
        right_dict = row_to_dict(right)
        key = group_join_key(right_dict, right_key)
        key in matched_right || checked_output_push!(output, right_dict, context)
    end
    return finish_table_node(left_payload, context, FULL_JOIN_ROWS_NODE_KEY, output_port_id, output; telemetry = Dict("right_input_ref" => String(right_payload.ref)))
end

function configure(::Type{SemiJoinRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("right_input_port_id" => "right_table_in", "left_key" => "id", "right_key" => "id"))
end
function infer_output_schema(::Type{SemiJoinRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Semi-joined Rows")
end
function execute(::Type{SemiJoinRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    left_payload = input_payload(context, String(context.config.values["input_port_id"]))
    right_payload = input_payload(context, String(get(context.config.values, "right_input_port_id", "right_table_in")))
    left_rows = payload_rows(left_payload, context)
    right_rows = payload_rows(right_payload, context)
    if left_rows === nothing || right_rows === nothing
        return NodeResult(warnings = ["$(SEMI_JOIN_ROWS_NODE_KEY) requires inline rows for both inputs"])
    end
    left_key = String(get(context.config.values, "left_key", "id"))
    right_key = String(get(context.config.values, "right_key", "id"))
    right_keys = Set{Any}([row_value(row, right_key) for row in right_rows])
    output = Dict{String,Any}[]
    for row in left_rows
        row_value(row, left_key) in right_keys && checked_output_push!(output, row_to_dict(row), context)
    end
    return finish_table_node(left_payload, context, SEMI_JOIN_ROWS_NODE_KEY, output_port_id, output; telemetry = Dict("right_input_ref" => String(right_payload.ref)))
end

function configure(::Type{LookupEnrichNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("right_input_port_id" => "right_table_in", "left_key" => "id", "right_key" => "id", "columns" => String[]))
end
function infer_output_schema(::Type{LookupEnrichNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Lookup-enriched Rows")
end
function execute(::Type{LookupEnrichNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    left_payload = input_payload(context, String(context.config.values["input_port_id"]))
    right_payload = input_payload(context, String(get(context.config.values, "right_input_port_id", "right_table_in")))
    left_rows = payload_rows(left_payload, context)
    right_rows = payload_rows(right_payload, context)
    if left_rows === nothing || right_rows === nothing
        return NodeResult(warnings = ["$(LOOKUP_ENRICH_NODE_KEY) requires inline rows for both inputs"])
    end
    left_key = String(get(context.config.values, "left_key", "id"))
    right_key = String(get(context.config.values, "right_key", "id"))
    columns = typed_config_columns(context.config.values, "columns")
    lookup = Dict{Any,Dict{String,Any}}()
    for row in right_rows
        row_dict = row_to_dict(row)
        lookup[group_join_key(row_dict, right_key)] = row_dict
    end
    output = Dict{String,Any}[]
    for row in left_rows
        next_row = row_to_dict(row)
        right = get(lookup, group_join_key(next_row, left_key), nothing)
        if right !== nothing
            selected = isempty(columns) ? [column for column in keys(right) if column != right_key] : columns
            for column in selected
                next_row[column] = get(right, column, missing)
            end
        end
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(left_payload, context, LOOKUP_ENRICH_NODE_KEY, output_port_id, output; telemetry = Dict("right_input_ref" => String(right_payload.ref)))
end

function configure(::Type{MetricDefinitionNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("metric_name" => "metric", "value_column" => "", "label_column" => "metric"))
end
function infer_output_schema(::Type{MetricDefinitionNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Metric Definition Rows")
end
function execute(::Type{MetricDefinitionNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, METRIC_DEFINITION_NODE_KEY, context)
    rows isa NodeResult && return rows
    metric_name = String(get(context.config.values, "metric_name", "metric"))
    value_column = String(get(context.config.values, "value_column", ""))
    label_column = String(get(context.config.values, "label_column", "metric"))
    isempty(value_column) && error("value_column must not be empty")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[label_column] = metric_name
        next_row["metric_value"] = row_value(row, value_column)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, METRIC_DEFINITION_NODE_KEY, output_port_id, output)
end

function configure(::Type{DimensionMappingNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "mapping" => Dict{String,Any}(), "output_column" => "dimension"))
end
function infer_output_schema(::Type{DimensionMappingNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Dimension-mapped Rows")
end
function execute(::Type{DimensionMappingNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DIMENSION_MAPPING_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    output_column = String(get(context.config.values, "output_column", "dimension"))
    isempty(column) && error("column must not be empty")
    mapping = Dict(String(k) => v for (k, v) in pairs(get(context.config.values, "mapping", Dict())))
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        key = string(get(next_row, column, ""))
        next_row[output_column] = get(mapping, key, key)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, DIMENSION_MAPPING_NODE_KEY, output_port_id, output; telemetry = Dict("mapping_count" => length(mapping)))
end

function configure(::Type{KpiThresholdNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("value_column" => "", "target" => 0.0, "status_column" => "kpi_status"))
end
function infer_output_schema(::Type{KpiThresholdNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "KPI Threshold Rows")
end
function execute(::Type{KpiThresholdNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, KPI_THRESHOLD_NODE_KEY, context)
    rows isa NodeResult && return rows
    value_column = String(get(context.config.values, "value_column", ""))
    target = Float64(get(context.config.values, "target", 0.0))
    isempty(value_column) && error("value_column must not be empty")
    status_column = String(get(context.config.values, "status_column", "kpi_status"))
    output = Dict{String,Any}[]
    for row in rows
        value = Float64(row_value(row, value_column))
        next_row = row_to_dict(row)
        next_row[status_column] = value >= target ? "met" : "missed"
        next_row["kpi_delta"] = value - target
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, KPI_THRESHOLD_NODE_KEY, output_port_id, output; telemetry = Dict("target" => target))
end

function configure(::Type{ChartDatasetNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("x_field" => "", "y_field" => "", "series_field" => "", "dataset_key" => "dataset"))
end
function infer_output_schema(::Type{ChartDatasetNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Chart Dataset Rows")
end
function execute(::Type{ChartDatasetNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, CHART_DATASET_NODE_KEY, context)
    rows isa NodeResult && return rows
    x_field = String(get(context.config.values, "x_field", ""))
    y_field = String(get(context.config.values, "y_field", ""))
    series_field = String(get(context.config.values, "series_field", ""))
    isempty(x_field) && error("x_field must not be empty")
    isempty(y_field) && error("y_field must not be empty")
    output = Dict{String,Any}[]
    for row in rows
        row_dict = row_to_dict(row)
        next_row = Dict{String,Any}("x" => get(row_dict, x_field, missing), "y" => get(row_dict, y_field, missing))
        isempty(series_field) || (next_row["series"] = get(row_dict, series_field, missing))
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, CHART_DATASET_NODE_KEY, output_port_id, output; telemetry = Dict("dataset_key" => String(get(context.config.values, "dataset_key", "dataset"))))
end

function configure(::Type{BooleanFlagNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "", "operator" => "gte", "threshold" => 0.0, "output_column" => "flag"))
end
function infer_output_schema(::Type{BooleanFlagNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Boolean Flag Rows")
end
function execute(::Type{BooleanFlagNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, BOOLEAN_FLAG_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", ""))
    operator = lowercase(String(get(context.config.values, "operator", "gte")))
    isempty(column) && error("column must not be empty")
    threshold = get(context.config.values, "threshold", 0.0)
    output_column = String(get(context.config.values, "output_column", "flag"))
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_column] = condition_passes(row_value(row, column), operator, threshold)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, BOOLEAN_FLAG_NODE_KEY, output_port_id, output; telemetry = Dict("operator" => operator))
end

function configure(::Type{TypeProfileNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[]))
end
function infer_output_schema(::Type{TypeProfileNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Type Profile Rows")
end
function execute(::Type{TypeProfileNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, TYPE_PROFILE_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    isempty(columns) && !isempty(rows) && (columns = sort(collect(keys(row_to_dict(first(rows))))))
    output = Dict{String,Any}[]
    for column in columns
        counts = Dict{String,Int}()
        for row in rows
            value = get(row_to_dict(row), column, missing)
            typename = value === missing || value === nothing ? "missing" : string(typeof(value))
            counts[typename] = get(counts, typename, 0) + 1
        end
        dominant = isempty(counts) ? "missing" : sort(collect(keys(counts)); by = key -> (-counts[key], key))[1]
        checked_output_push!(output, Dict("column" => column, "dominant_type" => dominant, "type_count" => length(counts)), context)
    end
    return finish_table_node(payload, context, TYPE_PROFILE_NODE_KEY, output_port_id, output; schema = ["column", "dominant_type", "type_count"])
end

function configure(::Type{RowHashNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[], "output_column" => "row_hash"))
end
function infer_output_schema(::Type{RowHashNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Row Hash Rows")
end
function execute(::Type{RowHashNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, ROW_HASH_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    output_column = String(get(context.config.values, "output_column", "row_hash"))
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_column] = stable_row_fingerprint(next_row, columns)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, ROW_HASH_NODE_KEY, output_port_id, output)
end

function configure(::Type{NormalizeWhitespaceNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[]))
end
function infer_output_schema(::Type{NormalizeWhitespaceNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Whitespace-normalized Rows")
end
function execute(::Type{NormalizeWhitespaceNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, NORMALIZE_WHITESPACE_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        target_columns = isempty(columns) ? [key for (key, value) in pairs(next_row) if value isa AbstractString] : columns
        for column in target_columns
            haskey(next_row, column) || continue
            next_row[column] = replace(strip(string(next_row[column])), r"\s+" => " ")
        end
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, NORMALIZE_WHITESPACE_NODE_KEY, output_port_id, output)
end


function output_column(config_values::Dict{String,Any}, default::String)
    return String(get(config_values, "output_column", default))
end

function config_thresholds(config_values::Dict{String,Any})
    thresholds = get(config_values, "thresholds", Float64[])
    thresholds isa AbstractVector || error("thresholds must be a vector")
    return [Float64(value) for value in thresholds]
end

function grouped_row_sets(rows, columns::Vector{String})
    groups = Dict{String,Vector{Dict{String,Any}}}()
    values = Dict{String,Dict{String,Any}}()
    order = String[]
    for row in rows
        row_dict = row_to_dict(row)
        key = join([string(get(row_dict, column, missing)) for column in columns], "\u001f")
        if !haskey(groups, key)
            groups[key] = Dict{String,Any}[]
            values[key] = Dict{String,Any}(column => get(row_dict, column, missing) for column in columns)
            push!(order, key)
        end
        push!(groups[key], row_dict)
    end
    return [(key = key, values = values[key], rows = groups[key]) for key in order]
end

function numeric_cell(row::AbstractDict, column::String)
    value = get(row, column, missing)
    (value === missing || value === nothing) && return nothing
    value isa Number || error("column $(column) contains non-numeric value $(value)")
    return Float64(value)
end

function group_numeric_values(rows, column::String)
    values = Float64[]
    for row in rows
        value = numeric_cell(row, column)
        value === nothing || push!(values, value)
    end
    return values
end

function configure(::Type{DropColumnsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[]))
end
function infer_output_schema(::Type{DropColumnsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Column-dropped Rows")
end
function execute(::Type{DropColumnsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DROP_COLUMNS_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = Set(typed_config_columns(context.config.values, "columns"))
    output = Dict{String,Any}[]
    for row in rows
        row_dict = row_to_dict(row)
        next_row = Dict{String,Any}(key => value for (key, value) in row_dict if !(key in columns))
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, DROP_COLUMNS_NODE_KEY, output_port_id, output)
end

function configure(::Type{KeepColumnsMatchingNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("pattern" => ".*"))
end
function infer_output_schema(::Type{KeepColumnsMatchingNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Pattern-kept Columns")
end
function execute(::Type{KeepColumnsMatchingNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, KEEP_COLUMNS_MATCHING_NODE_KEY, context)
    rows isa NodeResult && return rows
    pattern = safe_regex(String(get(context.config.values, "pattern", ".*")))
    output = Dict{String,Any}[]
    for row in rows
        row_dict = row_to_dict(row)
        next_row = Dict{String,Any}(key => value for (key, value) in row_dict if occursin(pattern, key))
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, KEEP_COLUMNS_MATCHING_NODE_KEY, output_port_id, output)
end

function configure(::Type{CopyColumnNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("source" => "value", "output_column" => "value_copy"))
end
function infer_output_schema(::Type{CopyColumnNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Copied Column Rows")
end
function execute(::Type{CopyColumnNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, COPY_COLUMN_NODE_KEY, context)
    rows isa NodeResult && return rows
    source = String(get(context.config.values, "source", "value"))
    output_name = output_column(context.config.values, "$(source)_copy")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = get(next_row, source, missing)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, COPY_COLUMN_NODE_KEY, output_port_id, output)
end

function configure(::Type{ConcatColumnsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[], "separator" => " ", "output_column" => "combined", "skip_missing" => true))
end
function infer_output_schema(::Type{ConcatColumnsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Concatenated Column Rows")
end
function execute(::Type{ConcatColumnsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, CONCAT_COLUMNS_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    isempty(columns) && error("columns must not be empty")
    separator = String(get(context.config.values, "separator", " "))
    skip_missing = Bool(get(context.config.values, "skip_missing", true))
    output_name = output_column(context.config.values, "combined")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        pieces = String[]
        for column in columns
            value = get(next_row, column, missing)
            (value === missing || value === nothing) && skip_missing && continue
            push!(pieces, value === missing || value === nothing ? "" : string(value))
        end
        next_row[output_name] = join(pieces, separator)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, CONCAT_COLUMNS_NODE_KEY, output_port_id, output)
end

function configure(::Type{SubstringColumnNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "start" => 1, "length" => 0, "output_column" => "substring"))
end
function infer_output_schema(::Type{SubstringColumnNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Substring Rows")
end
function execute(::Type{SubstringColumnNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, SUBSTRING_COLUMN_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    start_index = max(1, Int(get(context.config.values, "start", 1)))
    length_value = Int(get(context.config.values, "length", 0))
    output_name = output_column(context.config.values, "substring")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        text = string(get(next_row, column, ""))
        if start_index > lastindex(text)
            next_row[output_name] = ""
        else
            stop_index = length_value <= 0 ? lastindex(text) : min(lastindex(text), start_index + length_value - 1)
            next_row[output_name] = text[start_index:stop_index]
        end
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, SUBSTRING_COLUMN_NODE_KEY, output_port_id, output)
end

function configure(::Type{StringLengthNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "output_column" => "length"))
end
function infer_output_schema(::Type{StringLengthNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "String-length Rows")
end
function execute(::Type{StringLengthNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, STRING_LENGTH_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    output_name = output_column(context.config.values, "length")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = length(string(get(next_row, column, "")))
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, STRING_LENGTH_NODE_KEY, output_port_id, output)
end

function configure(::Type{RegexReplaceNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "pattern" => "\\s+", "replacement" => " ", "output_column" => "replaced"))
end
function infer_output_schema(::Type{RegexReplaceNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Regex-replaced Rows")
end
function execute(::Type{RegexReplaceNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, REGEX_REPLACE_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    regex = safe_regex(String(get(context.config.values, "pattern", "\\s+")))
    replacement = String(get(context.config.values, "replacement", " "))
    output_name = output_column(context.config.values, "replaced")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = replace(string(get(next_row, column, "")), regex => replacement)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, REGEX_REPLACE_NODE_KEY, output_port_id, output)
end

function configure(::Type{RoundNumberNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "digits" => 0, "output_column" => "rounded"))
end
function infer_output_schema(::Type{RoundNumberNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Rounded Rows")
end
function execute(::Type{RoundNumberNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, ROUND_NUMBER_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    digits = Int(get(context.config.values, "digits", 0))
    output_name = output_column(context.config.values, "rounded")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        value = numeric_cell(next_row, column)
        next_row[output_name] = value === nothing ? missing : round(value; digits = digits)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, ROUND_NUMBER_NODE_KEY, output_port_id, output)
end

function configure(::Type{AbsoluteValueNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "output_column" => "absolute"))
end
function infer_output_schema(::Type{AbsoluteValueNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Absolute-value Rows")
end
function execute(::Type{AbsoluteValueNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, ABSOLUTE_VALUE_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    output_name = output_column(context.config.values, "absolute")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        value = numeric_cell(next_row, column)
        next_row[output_name] = value === nothing ? missing : abs(value)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, ABSOLUTE_VALUE_NODE_KEY, output_port_id, output)
end

function configure(::Type{LogTransformNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "base" => "e", "output_column" => "log_value"))
end
function infer_output_schema(::Type{LogTransformNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Log-transformed Rows")
end
function execute(::Type{LogTransformNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, LOG_TRANSFORM_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    base_raw = get(context.config.values, "base", "e")
    base = base_raw isa Number ? Float64(base_raw) : lowercase(String(base_raw)) == "e" ? ℯ : parse(Float64, String(base_raw))
    base > 0 && base != 1 || error("base must be positive and not equal to 1")
    output_name = output_column(context.config.values, "log_value")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        value = numeric_cell(next_row, column)
        if value === nothing
            next_row[output_name] = missing
        else
            value > 0 || error("log transform requires positive values")
            next_row[output_name] = log(value) / log(base)
        end
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, LOG_TRANSFORM_NODE_KEY, output_port_id, output)
end

function configure(::Type{PercentChangeNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "output_column" => "percent_change"))
end
function infer_output_schema(::Type{PercentChangeNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Percent-change Rows")
end
function execute(::Type{PercentChangeNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, PERCENT_CHANGE_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    output_name = output_column(context.config.values, "percent_change")
    output = Dict{String,Any}[]
    previous = nothing
    for row in rows
        next_row = row_to_dict(row)
        current = numeric_cell(next_row, column)
        next_row[output_name] = previous === nothing || previous == 0 || current === nothing ? missing : (current - previous) / previous
        previous = current
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, PERCENT_CHANGE_NODE_KEY, output_port_id, output)
end

function configure(::Type{LeadColumnNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "offset" => 1, "output_column" => "next_value", "default" => missing))
end
function infer_output_schema(::Type{LeadColumnNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Lead-column Rows")
end
function execute(::Type{LeadColumnNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, LEAD_COLUMN_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    offset = max(1, Int(get(context.config.values, "offset", 1)))
    default = get(context.config.values, "default", missing)
    output_name = output_column(context.config.values, "next_value")
    output = Dict{String,Any}[]
    normalized = [row_to_dict(row) for row in rows]
    for index in eachindex(normalized)
        next_row = copy(normalized[index])
        target = index + offset
        next_row[output_name] = target <= length(normalized) ? get(normalized[target], column, missing) : default
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, LEAD_COLUMN_NODE_KEY, output_port_id, output)
end

function configure(::Type{CumulativeMeanNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "output_column" => "cumulative_mean"))
end
function infer_output_schema(::Type{CumulativeMeanNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Cumulative-mean Rows")
end
function execute(::Type{CumulativeMeanNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, CUMULATIVE_MEAN_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    output_name = output_column(context.config.values, "cumulative_mean")
    output = Dict{String,Any}[]
    total = 0.0
    count = 0
    for row in rows
        next_row = row_to_dict(row)
        value = numeric_cell(next_row, column)
        if value !== nothing
            total += value
            count += 1
        end
        next_row[output_name] = count == 0 ? missing : total / count
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, CUMULATIVE_MEAN_NODE_KEY, output_port_id, output)
end

function group_aggregate_result(payload, context, node_key::String, output_port_id::String, rows, value_column::String, output_name::String, aggregate)
    groups = grouped_row_sets(rows, typed_config_columns(context.config.values, "group_by"))
    output = Dict{String,Any}[]
    for group in groups
        values = group_numeric_values(group.rows, value_column)
        next_row = copy(group.values)
        next_row[output_name] = isempty(values) ? missing : aggregate(values)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, node_key, output_port_id, output)
end

function configure(::Type{GroupSumNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("group_by" => String[], "value_column" => "value", "output_column" => "sum"))
end
function infer_output_schema(::Type{GroupSumNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Group-sum Rows")
end
function execute(::Type{GroupSumNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, GROUP_SUM_NODE_KEY, context)
    rows isa NodeResult && return rows
    return group_aggregate_result(payload, context, GROUP_SUM_NODE_KEY, output_port_id, rows, String(get(context.config.values, "value_column", "value")), output_column(context.config.values, "sum"), sum)
end

function configure(::Type{GroupMeanNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("group_by" => String[], "value_column" => "value", "output_column" => "mean"))
end
function infer_output_schema(::Type{GroupMeanNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Group-mean Rows")
end
function execute(::Type{GroupMeanNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, GROUP_MEAN_NODE_KEY, context)
    rows isa NodeResult && return rows
    return group_aggregate_result(payload, context, GROUP_MEAN_NODE_KEY, output_port_id, rows, String(get(context.config.values, "value_column", "value")), output_column(context.config.values, "mean"), values -> sum(values) / length(values))
end

function configure(::Type{GroupMinNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("group_by" => String[], "value_column" => "value", "output_column" => "min"))
end
function infer_output_schema(::Type{GroupMinNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Group-min Rows")
end
function execute(::Type{GroupMinNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, GROUP_MIN_NODE_KEY, context)
    rows isa NodeResult && return rows
    return group_aggregate_result(payload, context, GROUP_MIN_NODE_KEY, output_port_id, rows, String(get(context.config.values, "value_column", "value")), output_column(context.config.values, "min"), minimum)
end

function configure(::Type{GroupMaxNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("group_by" => String[], "value_column" => "value", "output_column" => "max"))
end
function infer_output_schema(::Type{GroupMaxNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Group-max Rows")
end
function execute(::Type{GroupMaxNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, GROUP_MAX_NODE_KEY, context)
    rows isa NodeResult && return rows
    return group_aggregate_result(payload, context, GROUP_MAX_NODE_KEY, output_port_id, rows, String(get(context.config.values, "value_column", "value")), output_column(context.config.values, "max"), maximum)
end

function configure(::Type{GroupCountNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("group_by" => String[], "output_column" => "count"))
end
function infer_output_schema(::Type{GroupCountNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Group-count Rows")
end
function execute(::Type{GroupCountNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, GROUP_COUNT_NODE_KEY, context)
    rows isa NodeResult && return rows
    groups = grouped_row_sets(rows, typed_config_columns(context.config.values, "group_by"))
    output_name = output_column(context.config.values, "count")
    output = Dict{String,Any}[]
    for group in groups
        next_row = copy(group.values)
        next_row[output_name] = length(group.rows)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, GROUP_COUNT_NODE_KEY, output_port_id, output)
end

function configure(::Type{GroupPercentOfTotalNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("group_by" => String[], "value_column" => "value", "output_column" => "percent_of_total"))
end
function infer_output_schema(::Type{GroupPercentOfTotalNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Group-percent Rows")
end
function execute(::Type{GroupPercentOfTotalNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, GROUP_PERCENT_OF_TOTAL_NODE_KEY, context)
    rows isa NodeResult && return rows
    group_by = typed_config_columns(context.config.values, "group_by")
    value_column = String(get(context.config.values, "value_column", "value"))
    output_name = output_column(context.config.values, "percent_of_total")
    totals = Dict{String,Float64}()
    normalized = [row_to_dict(row) for row in rows]
    for group in grouped_row_sets(normalized, group_by)
        totals[group.key] = sum(group_numeric_values(group.rows, value_column))
    end
    output = Dict{String,Any}[]
    for row in normalized
        key = join([string(get(row, column, missing)) for column in group_by], "\u001f")
        value = numeric_cell(row, value_column)
        total = get(totals, key, 0.0)
        next_row = copy(row)
        next_row[output_name] = value === nothing || total == 0 ? missing : value / total
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, GROUP_PERCENT_OF_TOTAL_NODE_KEY, output_port_id, output)
end

function configure(::Type{BucketByThresholdsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "thresholds" => Float64[], "labels" => String[], "output_column" => "bucket"))
end
function infer_output_schema(::Type{BucketByThresholdsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Threshold-bucket Rows")
end
function execute(::Type{BucketByThresholdsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, BUCKET_BY_THRESHOLDS_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    thresholds = config_thresholds(context.config.values)
    labels_raw = get(context.config.values, "labels", String[])
    labels = [String(label) for label in labels_raw]
    length(labels) == length(thresholds) + 1 || error("labels length must equal thresholds length + 1")
    output_name = output_column(context.config.values, "bucket")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        value = numeric_cell(next_row, column)
        bucket_index = length(labels)
        if value !== nothing
            for (index, threshold) in enumerate(thresholds)
                if value <= threshold
                    bucket_index = index
                    break
                end
            end
        end
        next_row[output_name] = value === nothing ? missing : labels[bucket_index]
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, BUCKET_BY_THRESHOLDS_NODE_KEY, output_port_id, output)
end

function configure(::Type{QuantileBucketNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "buckets" => 4, "output_column" => "quantile_bucket"))
end
function infer_output_schema(::Type{QuantileBucketNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Quantile-bucket Rows")
end
function execute(::Type{QuantileBucketNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, QUANTILE_BUCKET_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    buckets = max(1, Int(get(context.config.values, "buckets", 4)))
    output_name = output_column(context.config.values, "quantile_bucket")
    normalized = [row_to_dict(row) for row in rows]
    sorted_values = sort(unique([value for value in (numeric_cell(row, column) for row in normalized) if value !== nothing]))
    output = Dict{String,Any}[]
    for row in normalized
        next_row = copy(row)
        value = numeric_cell(next_row, column)
        if value === nothing || isempty(sorted_values)
            next_row[output_name] = missing
        else
            rank = findfirst(isequal(value), sorted_values)
            next_row[output_name] = min(buckets, max(1, ceil(Int, rank * buckets / length(sorted_values))))
        end
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, QUANTILE_BUCKET_NODE_KEY, output_port_id, output)
end

function configure(::Type{OneHotEncodeNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "category", "categories" => String[], "prefix" => "is"))
end
function infer_output_schema(::Type{OneHotEncodeNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "One-hot Rows")
end
function execute(::Type{OneHotEncodeNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, ONE_HOT_ENCODE_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "category"))
    raw_categories = get(context.config.values, "categories", String[])
    categories = isempty(raw_categories) ? sort(unique([string(get(row_to_dict(row), column, "")) for row in rows])) : [string(value) for value in raw_categories]
    prefix = String(get(context.config.values, "prefix", "is"))
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        value = string(get(next_row, column, ""))
        for category in categories
            safe_category = replace(lowercase(category), r"[^a-z0-9]+" => "_")
            next_row["$(prefix)_$(safe_category)"] = value == category ? 1 : 0
        end
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, ONE_HOT_ENCODE_NODE_KEY, output_port_id, output)
end

function configure(::Type{MetricCardsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("metrics" => String[], "aggregation" => "sum"))
end
function infer_output_schema(::Type{MetricCardsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Metric-card Rows")
end
function execute(::Type{MetricCardsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, METRIC_CARDS_NODE_KEY, context)
    rows isa NodeResult && return rows
    metrics = typed_config_columns(context.config.values, "metrics")
    isempty(metrics) && error("metrics must not be empty")
    aggregation = lowercase(String(get(context.config.values, "aggregation", "sum")))
    output = Dict{String,Any}[]
    for metric in metrics
        values = numeric_values(rows, metric)
        value = aggregation == "mean" ? mean_value(values) : aggregation == "count" ? length(values) : sum(values)
        checked_output_push!(output, Dict("metric" => metric, "value" => value, "aggregation" => aggregation), context)
    end
    return finish_table_node(payload, context, METRIC_CARDS_NODE_KEY, output_port_id, output; telemetry = Dict("metric_count" => length(metrics)))
end

function configure(::Type{DashboardSummaryNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("numeric_columns" => String[]))
end
function infer_output_schema(::Type{DashboardSummaryNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Dashboard-summary Rows")
end
function execute(::Type{DashboardSummaryNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DASHBOARD_SUMMARY_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "numeric_columns")
    summary = Dict{String,Any}("row_count" => length(rows))
    for column in columns
        values = numeric_values(rows, column)
        summary["$(column)_sum"] = sum(values)
        summary["$(column)_mean"] = mean_value(values)
    end
    return finish_table_node(payload, context, DASHBOARD_SUMMARY_NODE_KEY, output_port_id, [summary])
end

function configure(::Type{RowsToColumnsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("key_column" => "metric", "value_column" => "value"))
end
function infer_output_schema(::Type{RowsToColumnsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Rows-to-columns Summary")
end
function execute(::Type{RowsToColumnsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, ROWS_TO_COLUMNS_NODE_KEY, context)
    rows isa NodeResult && return rows
    key_column = String(get(context.config.values, "key_column", "metric"))
    value_column = String(get(context.config.values, "value_column", "value"))
    output = Dict{String,Any}()
    for row in rows
        row_dict = row_to_dict(row)
        output[string(get(row_dict, key_column, ""))] = get(row_dict, value_column, missing)
    end
    return finish_table_node(payload, context, ROWS_TO_COLUMNS_NODE_KEY, output_port_id, [output])
end


function paired_numeric_values(rows, left_column::String, right_column::String)
    left_values = Float64[]
    right_values = Float64[]
    for row in rows
        row_dict = row_to_dict(row)
        left = numeric_cell(row_dict, left_column)
        right = numeric_cell(row_dict, right_column)
        if left !== nothing && right !== nothing
            push!(left_values, left)
            push!(right_values, right)
        end
    end
    return (left = left_values, right = right_values)
end

function sample_covariance(left_values::Vector{Float64}, right_values::Vector{Float64})
    length(left_values) == length(right_values) || error("paired values length mismatch")
    length(left_values) >= 2 || return 0.0
    left_mean = mean_value(left_values)
    right_mean = mean_value(right_values)
    total = 0.0
    for index in eachindex(left_values)
        total += (left_values[index] - left_mean) * (right_values[index] - right_mean)
    end
    return total / (length(left_values) - 1)
end

function configure(::Type{CorrelationNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("left_column" => "x", "right_column" => "y"))
end
function infer_output_schema(::Type{CorrelationNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Correlation")
end
function execute(::Type{CorrelationNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, CORRELATION_NODE_KEY, context)
    rows isa NodeResult && return rows
    left_column = String(get(context.config.values, "left_column", "x"))
    right_column = String(get(context.config.values, "right_column", "y"))
    paired = paired_numeric_values(rows, left_column, right_column)
    cov = sample_covariance(paired.left, paired.right)
    left_std = sqrt(sample_covariance(paired.left, paired.left))
    right_std = sqrt(sample_covariance(paired.right, paired.right))
    correlation = left_std == 0 || right_std == 0 ? 0.0 : cov / (left_std * right_std)
    output = [Dict("left_column" => left_column, "right_column" => right_column, "correlation" => correlation, "row_count" => length(paired.left))]
    return finish_table_node(payload, context, CORRELATION_NODE_KEY, output_port_id, output)
end

function configure(::Type{CovarianceNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("left_column" => "x", "right_column" => "y"))
end
function infer_output_schema(::Type{CovarianceNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Covariance")
end
function execute(::Type{CovarianceNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, COVARIANCE_NODE_KEY, context)
    rows isa NodeResult && return rows
    left_column = String(get(context.config.values, "left_column", "x"))
    right_column = String(get(context.config.values, "right_column", "y"))
    paired = paired_numeric_values(rows, left_column, right_column)
    output = [Dict("left_column" => left_column, "right_column" => right_column, "covariance" => sample_covariance(paired.left, paired.right), "row_count" => length(paired.left))]
    return finish_table_node(payload, context, COVARIANCE_NODE_KEY, output_port_id, output)
end

function configure(::Type{HistogramNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "thresholds" => Float64[], "labels" => String[]))
end
function infer_output_schema(::Type{HistogramNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Histogram")
end
function execute(::Type{HistogramNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, HISTOGRAM_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    thresholds = config_thresholds(context.config.values)
    labels = [String(label) for label in get(context.config.values, "labels", String[])]
    isempty(labels) && (labels = ["bin_$(index)" for index in 1:(length(thresholds)+1)])
    length(labels) == length(thresholds) + 1 || error("labels length must equal thresholds length + 1")
    counts = Dict(label => 0 for label in labels)
    for row in rows
        value = numeric_cell(row_to_dict(row), column)
        value === nothing && continue
        bucket_index = length(labels)
        for (index, threshold) in enumerate(thresholds)
            if value <= threshold
                bucket_index = index
                break
            end
        end
        counts[labels[bucket_index]] += 1
    end
    output = Dict{String,Any}[]
    for label in labels
        checked_output_push!(output, Dict("bucket" => label, "count" => counts[label]), context)
    end
    return finish_table_node(payload, context, HISTOGRAM_NODE_KEY, output_port_id, output)
end

function configure(::Type{OutlierFlagNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "threshold" => 3.0, "output_column" => "is_outlier"))
end
function infer_output_schema(::Type{OutlierFlagNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Outlier-flagged Rows")
end
function execute(::Type{OutlierFlagNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, OUTLIER_FLAG_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    threshold = Float64(get(context.config.values, "threshold", 3.0))
    output_name = output_column(context.config.values, "is_outlier")
    values = numeric_values(rows, column)
    mean = mean_value(values)
    std = sqrt(sample_covariance(values, values))
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        value = numeric_cell(next_row, column)
        z = std == 0 || value === nothing ? 0.0 : abs((value - mean) / std)
        next_row[output_name] = z > threshold
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, OUTLIER_FLAG_NODE_KEY, output_port_id, output)
end

function configure(::Type{StandardizeColumnsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[], "suffix" => "_z"))
end
function infer_output_schema(::Type{StandardizeColumnsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Standardized Rows")
end
function execute(::Type{StandardizeColumnsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, STANDARDIZE_COLUMNS_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    suffix = String(get(context.config.values, "suffix", "_z"))
    stats = Dict{String,Any}()
    for column in columns
        values = numeric_values(rows, column)
        stats[column] = (mean = mean_value(values), std = sqrt(sample_covariance(values, values)))
    end
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        for column in columns
            value = numeric_cell(next_row, column)
            stat = stats[column]
            next_row["$(column)$(suffix)"] = value === nothing || stat.std == 0 ? 0.0 : (value - stat.mean) / stat.std
        end
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, STANDARDIZE_COLUMNS_NODE_KEY, output_port_id, output)
end

function configure(::Type{TrainTestSplitNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("train_ratio" => 0.8, "output_column" => "split"))
end
function infer_output_schema(::Type{TrainTestSplitNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Train-test Rows")
end
function execute(::Type{TrainTestSplitNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, TRAIN_TEST_SPLIT_NODE_KEY, context)
    rows isa NodeResult && return rows
    ratio = Float64(get(context.config.values, "train_ratio", 0.8))
    0 <= ratio <= 1 || error("train_ratio must be between 0 and 1")
    output_name = output_column(context.config.values, "split")
    cutoff = floor(Int, length(rows) * ratio)
    output = Dict{String,Any}[]
    for (index, row) in enumerate(rows)
        next_row = row_to_dict(row)
        next_row[output_name] = index <= cutoff ? "train" : "test"
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, TRAIN_TEST_SPLIT_NODE_KEY, output_port_id, output)
end

function coefficient_map(raw)
    raw isa AbstractDict || error("coefficients must be a dict")
    return Dict{String,Float64}(String(key) => Float64(value) for (key, value) in pairs(raw))
end

function configure(::Type{LinearScoreNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("coefficients" => Dict{String,Any}(), "intercept" => 0.0, "output_column" => "score"))
end
function infer_output_schema(::Type{LinearScoreNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Scored Rows")
end
function execute(::Type{LinearScoreNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, LINEAR_SCORE_NODE_KEY, context)
    rows isa NodeResult && return rows
    coefficients = coefficient_map(get(context.config.values, "coefficients", Dict{String,Any}()))
    intercept = Float64(get(context.config.values, "intercept", 0.0))
    output_name = output_column(context.config.values, "score")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        score = intercept
        for (column, coefficient) in coefficients
            value = numeric_cell(next_row, column)
            value === nothing || (score += value * coefficient)
        end
        next_row[output_name] = score
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, LINEAR_SCORE_NODE_KEY, output_port_id, output)
end

function configure(::Type{ClassificationThresholdNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("score_column" => "score", "threshold" => 0.5, "output_column" => "prediction"))
end
function infer_output_schema(::Type{ClassificationThresholdNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Classified Rows")
end
function execute(::Type{ClassificationThresholdNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, CLASSIFICATION_THRESHOLD_NODE_KEY, context)
    rows isa NodeResult && return rows
    score_column = String(get(context.config.values, "score_column", "score"))
    threshold = Float64(get(context.config.values, "threshold", 0.5))
    output_name = output_column(context.config.values, "prediction")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        score = numeric_cell(next_row, score_column)
        next_row[output_name] = score !== nothing && score >= threshold ? 1 : 0
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, CLASSIFICATION_THRESHOLD_NODE_KEY, output_port_id, output)
end

function configure(::Type{ConfusionMatrixNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("actual_column" => "actual", "predicted_column" => "predicted", "positive_value" => 1))
end
function infer_output_schema(::Type{ConfusionMatrixNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Confusion Matrix")
end
function execute(::Type{ConfusionMatrixNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, CONFUSION_MATRIX_NODE_KEY, context)
    rows isa NodeResult && return rows
    actual_column = String(get(context.config.values, "actual_column", "actual"))
    predicted_column = String(get(context.config.values, "predicted_column", "predicted"))
    positive = get(context.config.values, "positive_value", 1)
    counts = Dict("tp" => 0, "fp" => 0, "tn" => 0, "fn" => 0)
    for row in rows
        row_dict = row_to_dict(row)
        actual = get(row_dict, actual_column, missing) == positive
        predicted = get(row_dict, predicted_column, missing) == positive
        if actual && predicted
            counts["tp"] += 1
        elseif !actual && predicted
            counts["fp"] += 1
        elseif actual && !predicted
            counts["fn"] += 1
        else
            counts["tn"] += 1
        end
    end
    output = [Dict("cell" => cell, "count" => counts[cell]) for cell in ["tp", "fp", "fn", "tn"]]
    return finish_table_node(payload, context, CONFUSION_MATRIX_NODE_KEY, output_port_id, output)
end

function configure(::Type{RegressionMetricsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("actual_column" => "actual", "predicted_column" => "predicted"))
end
function infer_output_schema(::Type{RegressionMetricsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Regression Metrics")
end
function execute(::Type{RegressionMetricsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, REGRESSION_METRICS_NODE_KEY, context)
    rows isa NodeResult && return rows
    actual_column = String(get(context.config.values, "actual_column", "actual"))
    predicted_column = String(get(context.config.values, "predicted_column", "predicted"))
    squared = Float64[]
    absolute = Float64[]
    for row in rows
        row_dict = row_to_dict(row)
        actual = numeric_cell(row_dict, actual_column)
        predicted = numeric_cell(row_dict, predicted_column)
        (actual === nothing || predicted === nothing) && continue
        error_value = predicted - actual
        push!(squared, error_value^2)
        push!(absolute, abs(error_value))
    end
    output = [Dict("rmse" => sqrt(mean_value(squared)), "mae" => mean_value(absolute), "row_count" => length(squared))]
    return finish_table_node(payload, context, REGRESSION_METRICS_NODE_KEY, output_port_id, output)
end

function configure(::Type{KMeansAssignNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("feature_columns" => String[], "centroids" => Any[], "output_column" => "cluster"))
end
function infer_output_schema(::Type{KMeansAssignNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Cluster-assigned Rows")
end
function execute(::Type{KMeansAssignNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, KMEANS_ASSIGN_NODE_KEY, context)
    rows isa NodeResult && return rows
    features = typed_config_columns(context.config.values, "feature_columns")
    centroids = get(context.config.values, "centroids", Any[])
    isempty(features) && error("feature_columns must not be empty")
    isempty(centroids) && error("centroids must not be empty")
    output_name = output_column(context.config.values, "cluster")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        values = [numeric_cell(next_row, column) for column in features]
        best_index = 1
        best_distance = Inf
        for (index, centroid) in enumerate(centroids)
            centroid_values = [Float64(value) for value in centroid]
            length(centroid_values) == length(values) || error("centroid dimension mismatch")
            distance = sum((values[i] - centroid_values[i])^2 for i in eachindex(values))
            if distance < best_distance
                best_index = index
                best_distance = distance
            end
        end
        next_row[output_name] = best_index
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, KMEANS_ASSIGN_NODE_KEY, output_port_id, output)
end

function configure(::Type{PcaProjectNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("components" => Dict{String,Any}()))
end
function infer_output_schema(::Type{PcaProjectNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "PCA-projected Rows")
end
function execute(::Type{PcaProjectNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, PCA_PROJECT_NODE_KEY, context)
    rows isa NodeResult && return rows
    raw_components = get(context.config.values, "components", Dict{String,Any}())
    raw_components isa AbstractDict || error("components must be a dict")
    components = Dict{String,Dict{String,Float64}}(String(name) => coefficient_map(weights) for (name, weights) in pairs(raw_components))
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        for (component, weights) in components
            score = 0.0
            for (column, weight) in weights
                value = numeric_cell(next_row, column)
                value === nothing || (score += value * weight)
            end
            next_row[component] = score
        end
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, PCA_PROJECT_NODE_KEY, output_port_id, output)
end

function configure(::Type{EventTimeAssignNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("timestamp_column" => "timestamp", "output_column" => "event_time"))
end
function infer_output_schema(::Type{EventTimeAssignNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Event-time Rows")
end
function execute(::Type{EventTimeAssignNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, EVENT_TIME_ASSIGN_NODE_KEY, context)
    rows isa NodeResult && return rows
    timestamp_column = String(get(context.config.values, "timestamp_column", "timestamp"))
    output_name = output_column(context.config.values, "event_time")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        value = string(get(next_row, timestamp_column, ""))
        parts = simple_date_parts(value)
        next_row[output_name] = parts.iso
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, EVENT_TIME_ASSIGN_NODE_KEY, output_port_id, output)
end

function configure(::Type{WatermarkFlagNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("timestamp_column" => "event_time", "watermark" => "1970-01-01", "output_column" => "past_watermark"))
end
function infer_output_schema(::Type{WatermarkFlagNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Watermark-flagged Rows")
end
function execute(::Type{WatermarkFlagNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, WATERMARK_FLAG_NODE_KEY, context)
    rows isa NodeResult && return rows
    timestamp_column = String(get(context.config.values, "timestamp_column", "event_time"))
    watermark = String(get(context.config.values, "watermark", "1970-01-01"))
    output_name = output_column(context.config.values, "past_watermark")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = string(get(next_row, timestamp_column, "")) <= watermark
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, WATERMARK_FLAG_NODE_KEY, output_port_id, output)
end

function configure(::Type{TumblingWindowNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("timestamp_column" => "event_time", "granularity" => "day", "output_column" => "window_start"))
end
function infer_output_schema(::Type{TumblingWindowNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Tumbling-window Rows")
end
function execute(::Type{TumblingWindowNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, TUMBLING_WINDOW_NODE_KEY, context)
    rows isa NodeResult && return rows
    timestamp_column = String(get(context.config.values, "timestamp_column", "event_time"))
    granularity = lowercase(String(get(context.config.values, "granularity", "day")))
    output_name = output_column(context.config.values, "window_start")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        parts = simple_date_parts(get(next_row, timestamp_column, ""))
        next_row[output_name] = granularity == "month" ? @sprintf("%04d-%02d", parts.year, parts.month) : parts.iso
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, TUMBLING_WINDOW_NODE_KEY, output_port_id, output)
end

function configure(::Type{SlidingWindowNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("window" => 3, "step" => 1, "output_column" => "window_id"))
end
function infer_output_schema(::Type{SlidingWindowNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Sliding-window Rows")
end
function execute(::Type{SlidingWindowNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, SLIDING_WINDOW_NODE_KEY, context)
    rows isa NodeResult && return rows
    step = max(1, Int(get(context.config.values, "step", 1)))
    output_name = output_column(context.config.values, "window_id")
    output = Dict{String,Any}[]
    for (index, row) in enumerate(rows)
        next_row = row_to_dict(row)
        next_row[output_name] = floor(Int, (index - 1) / step) + 1
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, SLIDING_WINDOW_NODE_KEY, output_port_id, output)
end

function configure(::Type{StreamAggregateNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("group_by" => String[], "value_column" => "value", "operation" => "sum", "output_column" => "value"))
end
function infer_output_schema(::Type{StreamAggregateNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Stream Aggregate")
end
function execute(::Type{StreamAggregateNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, STREAM_AGGREGATE_NODE_KEY, context)
    rows isa NodeResult && return rows
    operation = lowercase(String(get(context.config.values, "operation", "sum")))
    value_column = String(get(context.config.values, "value_column", "value"))
    output_name = output_column(context.config.values, "value")
    groups = grouped_row_sets(rows, typed_config_columns(context.config.values, "group_by"))
    output = Dict{String,Any}[]
    for group in groups
        values = group_numeric_values(group.rows, value_column)
        next_row = copy(group.values)
        next_row[output_name] = operation == "count" ? length(group.rows) : operation == "mean" ? mean_value(values) : sum(values)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, STREAM_AGGREGATE_NODE_KEY, output_port_id, output)
end

function configure(::Type{DedupeEventIdNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("event_id_column" => "event_id"))
end
function infer_output_schema(::Type{DedupeEventIdNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Deduped Events")
end
function execute(::Type{DedupeEventIdNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DEDUPE_EVENT_ID_NODE_KEY, context)
    rows isa NodeResult && return rows
    event_id_column = String(get(context.config.values, "event_id_column", "event_id"))
    seen = Set{Any}()
    output = Dict{String,Any}[]
    for row in rows
        row_dict = row_to_dict(row)
        event_id = get(row_dict, event_id_column, missing)
        event_id in seen && continue
        push!(seen, event_id)
        checked_output_push!(output, row_dict, context)
    end
    return finish_table_node(payload, context, DEDUPE_EVENT_ID_NODE_KEY, output_port_id, output)
end

function configure(::Type{SinkTransactionMarkerNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("transaction_id" => "tx", "status" => "pending"))
end
function infer_output_schema(::Type{SinkTransactionMarkerNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Sink Transaction Rows")
end
function execute(::Type{SinkTransactionMarkerNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, SINK_TRANSACTION_MARKER_NODE_KEY, context)
    rows isa NodeResult && return rows
    transaction_id = String(get(context.config.values, "transaction_id", "tx"))
    status = String(get(context.config.values, "status", "pending"))
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row["sink_transaction_id"] = transaction_id
        next_row["sink_status"] = status
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, SINK_TRANSACTION_MARKER_NODE_KEY, output_port_id, output; telemetry = Dict("transaction_id" => transaction_id))
end

function configure(::Type{ExtensionManifestValidateNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("required_columns" => ["name", "version", "node_count"]))
end
function infer_output_schema(::Type{ExtensionManifestValidateNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Manifest Validation")
end
function execute(::Type{ExtensionManifestValidateNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, EXTENSION_MANIFEST_VALIDATE_NODE_KEY, context)
    rows isa NodeResult && return rows
    required = typed_config_columns(context.config.values, "required_columns")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        missing_columns = [column for column in required if !haskey(next_row, column) || get(next_row, column, missing) === missing]
        next_row["manifest_valid"] = isempty(missing_columns)
        next_row["missing_columns"] = join(missing_columns, ",")
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, EXTENSION_MANIFEST_VALIDATE_NODE_KEY, output_port_id, output)
end

function configure(::Type{CompatibilityReportNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("current_version" => "1.10", "min_column" => "min_julia", "output_column" => "compatible"))
end
function infer_output_schema(::Type{CompatibilityReportNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Compatibility Report")
end
function execute(::Type{CompatibilityReportNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, COMPATIBILITY_REPORT_NODE_KEY, context)
    rows isa NodeResult && return rows
    current_version = String(get(context.config.values, "current_version", "1.10"))
    min_column = String(get(context.config.values, "min_column", "min_julia"))
    output_name = output_column(context.config.values, "compatible")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = current_version >= string(get(next_row, min_column, "0"))
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, COMPATIBILITY_REPORT_NODE_KEY, output_port_id, output)
end

function configure(::Type{PackageHashVerifyNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("hash_column" => "hash", "expected_column" => "expected_hash", "output_column" => "hash_verified"))
end
function infer_output_schema(::Type{PackageHashVerifyNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Hash Verification")
end
function execute(::Type{PackageHashVerifyNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, PACKAGE_HASH_VERIFY_NODE_KEY, context)
    rows isa NodeResult && return rows
    hash_column = String(get(context.config.values, "hash_column", "hash"))
    expected_column = String(get(context.config.values, "expected_column", "expected_hash"))
    output_name = output_column(context.config.values, "hash_verified")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = string(get(next_row, hash_column, "")) == string(get(next_row, expected_column, ""))
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, PACKAGE_HASH_VERIFY_NODE_KEY, output_port_id, output)
end

function configure(::Type{ObjectStoreListNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("ref_column" => "ref", "prefix" => "", "extension" => ""))
end
function infer_output_schema(::Type{ObjectStoreListNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Object-store Listing")
end
function execute(::Type{ObjectStoreListNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, OBJECT_STORE_LIST_NODE_KEY, context)
    rows isa NodeResult && return rows
    ref_column = String(get(context.config.values, "ref_column", "ref"))
    prefix = String(get(context.config.values, "prefix", ""))
    extension = String(get(context.config.values, "extension", ""))
    output = Dict{String,Any}[]
    for row in rows
        row_dict = row_to_dict(row)
        ref = string(get(row_dict, ref_column, ""))
        startswith(ref, prefix) || continue
        isempty(extension) || endswith(ref, extension) || continue
        checked_output_push!(output, Dict("ref" => ref, "size" => get(row_dict, "size", missing)), context)
    end
    return finish_table_node(payload, context, OBJECT_STORE_LIST_NODE_KEY, output_port_id, output)
end

function configure(::Type{DatasetVersionNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[], "output_column" => "version_id"))
end
function infer_output_schema(::Type{DatasetVersionNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Dataset-version Rows")
end
function execute(::Type{DatasetVersionNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DATASET_VERSION_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    output_name = output_column(context.config.values, "version_id")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = stable_row_fingerprint(next_row, columns)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, DATASET_VERSION_NODE_KEY, output_port_id, output)
end

function configure(::Type{SchemaDriftNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("expected_columns" => String[]))
end
function infer_output_schema(::Type{SchemaDriftNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Schema Drift")
end
function execute(::Type{SchemaDriftNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, SCHEMA_DRIFT_NODE_KEY, context)
    rows isa NodeResult && return rows
    expected = Set(typed_config_columns(context.config.values, "expected_columns"))
    observed = isempty(rows) ? Set{String}() : Set(keys(row_to_dict(first(rows))))
    missing_columns = sort(collect(setdiff(expected, observed)))
    extra_columns = sort(collect(setdiff(observed, expected)))
    output = [Dict("missing_columns" => join(missing_columns, ","), "extra_columns" => join(extra_columns, ","), "drift_detected" => !isempty(missing_columns) || !isempty(extra_columns))]
    return finish_table_node(payload, context, SCHEMA_DRIFT_NODE_KEY, output_port_id, output)
end


function date_ordinal(value)
    parts = simple_date_parts(value)
    return parts.year * 372 + parts.month * 31 + parts.day
end

function configure(::Type{ColumnPresenceNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("expected_columns" => String[]))
end
function infer_output_schema(::Type{ColumnPresenceNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Column Presence")
end
function execute(::Type{ColumnPresenceNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, COLUMN_PRESENCE_NODE_KEY, context)
    rows isa NodeResult && return rows
    expected = typed_config_columns(context.config.values, "expected_columns")
    observed = isempty(rows) ? Set{String}() : Set(keys(row_to_dict(first(rows))))
    output = [Dict("column" => column, "present" => column in observed) for column in expected]
    return finish_table_node(payload, context, COLUMN_PRESENCE_NODE_KEY, output_port_id, output)
end

function configure(::Type{NullRateNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[]))
end
function infer_output_schema(::Type{NullRateNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Null Rate")
end
function execute(::Type{NullRateNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, NULL_RATE_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    isempty(columns) && !isempty(rows) && (columns = sort(collect(keys(row_to_dict(first(rows))))))
    output = Dict{String,Any}[]
    for column in columns
        count = sum(row -> get(row_to_dict(row), column, missing) === missing || get(row_to_dict(row), column, nothing) === nothing, rows)
        checked_output_push!(output, Dict("column" => column, "null_count" => count, "null_rate" => isempty(rows) ? 0.0 : count / length(rows)), context)
    end
    return finish_table_node(payload, context, NULL_RATE_NODE_KEY, output_port_id, output)
end

function configure(::Type{DuplicateRateNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[]))
end
function infer_output_schema(::Type{DuplicateRateNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Duplicate Rate")
end
function execute(::Type{DuplicateRateNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DUPLICATE_RATE_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    seen = Set{String}()
    duplicates = 0
    for row in rows
        key = stable_row_fingerprint(row_to_dict(row), columns)
        if key in seen
            duplicates += 1
        else
            push!(seen, key)
        end
    end
    output = [Dict("duplicate_count" => duplicates, "duplicate_rate" => isempty(rows) ? 0.0 : duplicates / length(rows))]
    return finish_table_node(payload, context, DUPLICATE_RATE_NODE_KEY, output_port_id, output)
end

function configure(::Type{CardinalityNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[]))
end
function infer_output_schema(::Type{CardinalityNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Cardinality")
end
function execute(::Type{CardinalityNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, CARDINALITY_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    output = Dict{String,Any}[]
    for column in columns
        values = Set{Any}(get(row_to_dict(row), column, missing) for row in rows)
        checked_output_push!(output, Dict("column" => column, "unique_count" => length(values)), context)
    end
    return finish_table_node(payload, context, CARDINALITY_NODE_KEY, output_port_id, output)
end

function configure(::Type{ColumnSelectByTypeNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("type" => "numeric"))
end
function infer_output_schema(::Type{ColumnSelectByTypeNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Type-selected Columns")
end
function execute(::Type{ColumnSelectByTypeNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, COLUMN_SELECT_BY_TYPE_NODE_KEY, context)
    rows isa NodeResult && return rows
    target = lowercase(String(get(context.config.values, "type", "numeric")))
    columns = isempty(rows) ? String[] : sort(collect(keys(row_to_dict(first(rows)))))
    keep = String[]
    for column in columns
        values = [get(row_to_dict(row), column, missing) for row in rows if get(row_to_dict(row), column, missing) !== missing]
        isempty(values) && continue
        matches = target == "numeric" ? all(value -> value isa Number, values) : target == "string" ? all(value -> value isa AbstractString, values) : true
        matches && push!(keep, column)
    end
    output = Dict{String,Any}[]
    for row in rows
        row_dict = row_to_dict(row)
        checked_output_push!(output, Dict{String,Any}(column => row_dict[column] for column in keep), context)
    end
    return finish_table_node(payload, context, COLUMN_SELECT_BY_TYPE_NODE_KEY, output_port_id, output)
end

function configure(::Type{TimeSincePreviousNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("timestamp_column" => "event_time", "output_column" => "days_since_previous"))
end
function infer_output_schema(::Type{TimeSincePreviousNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Time Delta Rows")
end
function execute(::Type{TimeSincePreviousNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, TIME_SINCE_PREVIOUS_NODE_KEY, context)
    rows isa NodeResult && return rows
    timestamp_column = String(get(context.config.values, "timestamp_column", "event_time"))
    output_name = output_column(context.config.values, "days_since_previous")
    previous = nothing
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        current = date_ordinal(get(next_row, timestamp_column, "1970-01-01"))
        next_row[output_name] = previous === nothing ? missing : current - previous
        previous = current
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, TIME_SINCE_PREVIOUS_NODE_KEY, output_port_id, output)
end

function configure(::Type{SessionizeEventsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("timestamp_column" => "event_time", "max_gap_days" => 1, "output_column" => "session_id"))
end
function infer_output_schema(::Type{SessionizeEventsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Sessionized Events")
end
function execute(::Type{SessionizeEventsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, SESSIONIZE_EVENTS_NODE_KEY, context)
    rows isa NodeResult && return rows
    timestamp_column = String(get(context.config.values, "timestamp_column", "event_time"))
    max_gap = Int(get(context.config.values, "max_gap_days", 1))
    output_name = output_column(context.config.values, "session_id")
    previous = nothing
    session = 1
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        current = date_ordinal(get(next_row, timestamp_column, "1970-01-01"))
        previous === nothing || current - previous <= max_gap || (session += 1)
        next_row[output_name] = session
        previous = current
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, SESSIONIZE_EVENTS_NODE_KEY, output_port_id, output)
end

function configure(::Type{WindowLagDeltaNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "output_column" => "delta"))
end
function infer_output_schema(::Type{WindowLagDeltaNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Lag Delta Rows")
end
function execute(::Type{WindowLagDeltaNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, WINDOW_LAG_DELTA_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    output_name = output_column(context.config.values, "delta")
    previous = nothing
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        current = numeric_cell(next_row, column)
        next_row[output_name] = previous === nothing || current === nothing ? missing : current - previous
        previous = current
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, WINDOW_LAG_DELTA_NODE_KEY, output_port_id, output)
end

function configure(::Type{RollingStdNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "window" => 3, "output_column" => "rolling_std"))
end
function infer_output_schema(::Type{RollingStdNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Rolling Std Rows")
end
function execute(::Type{RollingStdNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, ROLLING_STD_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    window = max(1, Int(get(context.config.values, "window", 3)))
    output_name = output_column(context.config.values, "rolling_std")
    output = Dict{String,Any}[]
    normalized = [row_to_dict(row) for row in rows]
    for index in eachindex(normalized)
        start_index = max(1, index - window + 1)
        values = [numeric_cell(normalized[i], column) for i in start_index:index]
        next_row = copy(normalized[index])
        next_row[output_name] = sqrt(sample_covariance(values, values))
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, ROLLING_STD_NODE_KEY, output_port_id, output)
end

function configure(::Type{ExpandingMaxNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "output_column" => "expanding_max"))
end
function infer_output_schema(::Type{ExpandingMaxNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Expanding Max Rows")
end
function execute(::Type{ExpandingMaxNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, EXPANDING_MAX_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    output_name = output_column(context.config.values, "expanding_max")
    current_max = -Inf
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        value = numeric_cell(next_row, column)
        value === nothing || (current_max = max(current_max, value))
        next_row[output_name] = current_max
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, EXPANDING_MAX_NODE_KEY, output_port_id, output)
end

function configure(::Type{CrossJoinRowsNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("right_input_port_id" => "right_table_in"))
end
function infer_output_schema(::Type{CrossJoinRowsNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Cross-joined Rows")
end
function execute(::Type{CrossJoinRowsNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    left_payload = input_payload(context, String(context.config.values["input_port_id"]))
    right_payload = input_payload(context, String(get(context.config.values, "right_input_port_id", "right_table_in")))
    left_rows = payload_rows(left_payload, context)
    right_rows = payload_rows(right_payload, context)
    left_rows === nothing && return rows_or_warning(left_payload, output_port_id, CROSS_JOIN_ROWS_NODE_KEY, context)
    right_rows === nothing && return rows_or_warning(right_payload, output_port_id, CROSS_JOIN_ROWS_NODE_KEY, context)
    output = Dict{String,Any}[]
    for left in left_rows, right in right_rows
        checked_output_push!(output, merge_join_rows(row_to_dict(left), row_to_dict(right)), context)
    end
    return finish_table_node(left_payload, context, CROSS_JOIN_ROWS_NODE_KEY, output_port_id, output)
end

function configure(::Type{AppendMetadataNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("metadata" => Dict{String,Any}()))
end
function infer_output_schema(::Type{AppendMetadataNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Metadata-appended Rows")
end
function execute(::Type{AppendMetadataNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, APPEND_METADATA_NODE_KEY, context)
    rows isa NodeResult && return rows
    metadata = Dict{String,Any}(String(key) => value for (key, value) in pairs(get(context.config.values, "metadata", Dict{String,Any}())))
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        merge!(next_row, metadata)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, APPEND_METADATA_NODE_KEY, output_port_id, output)
end

function configure(::Type{MaskColumnNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "value", "visible_suffix" => 0, "mask" => "***", "output_column" => "masked"))
end
function infer_output_schema(::Type{MaskColumnNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Masked Rows")
end
function execute(::Type{MaskColumnNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, MASK_COLUMN_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "value"))
    suffix = max(0, Int(get(context.config.values, "visible_suffix", 0)))
    mask = String(get(context.config.values, "mask", "***"))
    output_name = output_column(context.config.values, "masked")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        text = string(get(next_row, column, ""))
        keep = suffix == 0 ? "" : text[max(1, lastindex(text)-suffix+1):end]
        next_row[output_name] = string(mask, keep)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, MASK_COLUMN_NODE_KEY, output_port_id, output)
end

function configure(::Type{TokenizeColumnNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "text", "delimiter" => " ", "output_column" => "tokens"))
end
function infer_output_schema(::Type{TokenizeColumnNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Tokenized Rows")
end
function execute(::Type{TokenizeColumnNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, TOKENIZE_COLUMN_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "text"))
    delimiter = String(get(context.config.values, "delimiter", " "))
    output_name = output_column(context.config.values, "tokens")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = split(string(get(next_row, column, "")), delimiter; keepempty = false)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, TOKENIZE_COLUMN_NODE_KEY, output_port_id, output)
end

function configure(::Type{ExplodeListNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "items", "delimiter" => ","))
end
function infer_output_schema(::Type{ExplodeListNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Exploded Rows")
end
function execute(::Type{ExplodeListNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, EXPLODE_LIST_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "items"))
    delimiter = String(get(context.config.values, "delimiter", ","))
    output = Dict{String,Any}[]
    for row in rows
        row_dict = row_to_dict(row)
        raw = get(row_dict, column, Any[])
        values = raw isa AbstractVector ? raw : split(string(raw), delimiter; keepempty = false)
        for value in values
            next_row = copy(row_dict)
            next_row[column] = value
            checked_output_push!(output, next_row, context)
        end
    end
    return finish_table_node(payload, context, EXPLODE_LIST_NODE_KEY, output_port_id, output)
end

function configure(::Type{JsonExtractFieldNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "json", "field" => "value", "output_column" => "extracted"))
end
function infer_output_schema(::Type{JsonExtractFieldNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "JSON-extracted Rows")
end
function execute(::Type{JsonExtractFieldNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, JSON_EXTRACT_FIELD_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "json"))
    field = String(get(context.config.values, "field", "value"))
    output_name = output_column(context.config.values, "extracted")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        parsed = json_to_julia(JSON3.read(string(get(next_row, column, "{}"))))
        next_row[output_name] = parsed isa AbstractDict ? get(parsed, field, missing) : missing
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, JSON_EXTRACT_FIELD_NODE_KEY, output_port_id, output)
end

function configure(::Type{DatasetLineageNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("source_dataset" => "source", "output_dataset" => "output", "operation" => "transform"))
end
function infer_output_schema(::Type{DatasetLineageNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Dataset Lineage")
end
function execute(::Type{DatasetLineageNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, DATASET_LINEAGE_NODE_KEY, context)
    rows isa NodeResult && return rows
    lineage = Dict("source_dataset" => String(get(context.config.values, "source_dataset", "source")), "output_dataset" => String(get(context.config.values, "output_dataset", "output")), "operation" => String(get(context.config.values, "operation", "transform")))
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        merge!(next_row, lineage)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, DATASET_LINEAGE_NODE_KEY, output_port_id, output)
end

function configure(::Type{PolicyTagNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("column" => "column", "mapping" => Dict{String,Any}(), "output_column" => "policy_tag"))
end
function infer_output_schema(::Type{PolicyTagNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Policy-tagged Rows")
end
function execute(::Type{PolicyTagNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, POLICY_TAG_NODE_KEY, context)
    rows isa NodeResult && return rows
    column = String(get(context.config.values, "column", "column"))
    mapping = Dict{String,Any}(String(key) => value for (key, value) in pairs(get(context.config.values, "mapping", Dict{String,Any}())))
    output_name = output_column(context.config.values, "policy_tag")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = get(mapping, string(get(next_row, column, "")), "public")
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, POLICY_TAG_NODE_KEY, output_port_id, output)
end

function configure(::Type{AccessDecisionNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("role" => "viewer", "allowed_roles" => ["owner", "editor"], "output_column" => "allowed"))
end
function infer_output_schema(::Type{AccessDecisionNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Access Decisions")
end
function execute(::Type{AccessDecisionNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, ACCESS_DECISION_NODE_KEY, context)
    rows isa NodeResult && return rows
    role = String(get(context.config.values, "role", "viewer"))
    allowed_roles = Set(String(value) for value in get(context.config.values, "allowed_roles", ["owner", "editor"]))
    output_name = output_column(context.config.values, "allowed")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = role in allowed_roles
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, ACCESS_DECISION_NODE_KEY, output_port_id, output)
end

function configure(::Type{GpuCapabilityFlagNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("required_memory_mb" => 0, "available_memory_mb" => 0, "output_column" => "gpu_eligible"))
end
function infer_output_schema(::Type{GpuCapabilityFlagNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "GPU Capability Rows")
end
function execute(::Type{GpuCapabilityFlagNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, GPU_CAPABILITY_FLAG_NODE_KEY, context)
    rows isa NodeResult && return rows
    required = Float64(get(context.config.values, "required_memory_mb", 0))
    available = Float64(get(context.config.values, "available_memory_mb", 0))
    output_name = output_column(context.config.values, "gpu_eligible")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = available >= required
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, GPU_CAPABILITY_FLAG_NODE_KEY, output_port_id, output)
end

function configure(::Type{BatchIdAssignNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("batch_id" => "batch-1"))
end
function infer_output_schema(::Type{BatchIdAssignNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Batch Rows")
end
function execute(::Type{BatchIdAssignNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, BATCH_ID_ASSIGN_NODE_KEY, context)
    rows isa NodeResult && return rows
    batch_id = String(get(context.config.values, "batch_id", "batch-1"))
    output = Dict{String,Any}[]
    for (index, row) in enumerate(rows)
        next_row = row_to_dict(row)
        next_row["batch_id"] = batch_id
        next_row["batch_row_number"] = index
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, BATCH_ID_ASSIGN_NODE_KEY, output_port_id, output)
end

function configure(::Type{ReplayOffsetNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("start_offset" => 0, "output_column" => "replay_offset"))
end
function infer_output_schema(::Type{ReplayOffsetNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Replay Offset Rows")
end
function execute(::Type{ReplayOffsetNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, REPLAY_OFFSET_NODE_KEY, context)
    rows isa NodeResult && return rows
    start_offset = Int(get(context.config.values, "start_offset", 0))
    output_name = output_column(context.config.values, "replay_offset")
    output = Dict{String,Any}[]
    for (index, row) in enumerate(rows)
        next_row = row_to_dict(row)
        next_row[output_name] = start_offset + index - 1
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, REPLAY_OFFSET_NODE_KEY, output_port_id, output)
end

function configure(::Type{ExactlyOnceKeyNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[], "output_column" => "exactly_once_key"))
end
function infer_output_schema(::Type{ExactlyOnceKeyNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Exactly-once Key Rows")
end
function execute(::Type{ExactlyOnceKeyNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, EXACTLY_ONCE_KEY_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    output_name = output_column(context.config.values, "exactly_once_key")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = stable_row_fingerprint(next_row, columns)
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, EXACTLY_ONCE_KEY_NODE_KEY, output_port_id, output)
end

function configure(::Type{SinkCommitPlanNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("sink" => "default", "mode" => "commit"))
end
function infer_output_schema(::Type{SinkCommitPlanNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Sink Commit Plan")
end
function execute(::Type{SinkCommitPlanNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, SINK_COMMIT_PLAN_NODE_KEY, context)
    rows isa NodeResult && return rows
    output = [Dict("sink" => String(get(context.config.values, "sink", "default")), "mode" => String(get(context.config.values, "mode", "commit")), "row_count" => length(rows), "ready" => true)]
    return finish_table_node(payload, context, SINK_COMMIT_PLAN_NODE_KEY, output_port_id, output)
end

function configure(::Type{FeatureVectorNode}, params::AbstractDict{K,V}) where {K<:AbstractString,V}
    return tier1_config(params; defaults = Dict("columns" => String[], "output_column" => "features"))
end
function infer_output_schema(::Type{FeatureVectorNode}, input_schemas::Vector{PortSchema})
    return infer_tier1_schema(input_schemas, "Feature-vector Rows")
end
function execute(::Type{FeatureVectorNode}, context::NodeContext)
    output_port_id = String(context.config.values["output_port_id"])
    payload = input_payload(context, String(context.config.values["input_port_id"]))
    rows = rows_or_warning(payload, output_port_id, FEATURE_VECTOR_NODE_KEY, context)
    rows isa NodeResult && return rows
    columns = typed_config_columns(context.config.values, "columns")
    output_name = output_column(context.config.values, "features")
    output = Dict{String,Any}[]
    for row in rows
        next_row = row_to_dict(row)
        next_row[output_name] = [numeric_cell(next_row, column) for column in columns]
        checked_output_push!(output, next_row, context)
    end
    return finish_table_node(payload, context, FEATURE_VECTOR_NODE_KEY, output_port_id, output)
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
    UnionDistinctRowsNode, UnpivotRowsNode, PivotRowsNode, DedupeByKeyNode, ValueCountsNode,
    MissingnessSummaryNode, ParseDateNode, DateBucketNode, DatePartsNode, SplitColumnNode,
    TopNPerGroupNode, WeightedAverageNode, GroupRowNumberNode, MovingMinNode, MovingMaxNode,
    CumulativeCountNode, RightJoinRowsNode, FullJoinRowsNode, SemiJoinRowsNode, LookupEnrichNode,
    MetricDefinitionNode, DimensionMappingNode, KpiThresholdNode, ChartDatasetNode, BooleanFlagNode,
    TypeProfileNode, RowHashNode, NormalizeWhitespaceNode,
    DropColumnsNode, KeepColumnsMatchingNode, CopyColumnNode, ConcatColumnsNode, SubstringColumnNode,
    StringLengthNode, RegexReplaceNode, RoundNumberNode, AbsoluteValueNode, LogTransformNode,
    PercentChangeNode, LeadColumnNode, CumulativeMeanNode, GroupSumNode, GroupMeanNode,
    GroupMinNode, GroupMaxNode, GroupCountNode, GroupPercentOfTotalNode, BucketByThresholdsNode,
    QuantileBucketNode, OneHotEncodeNode, MetricCardsNode, DashboardSummaryNode, RowsToColumnsNode,
)
    @eval function on_stream_event(::Type{$node_type}, event, state, ::NodeContext)
        return (event, state)
    end
end
