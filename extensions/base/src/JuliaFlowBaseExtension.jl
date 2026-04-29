module JuliaFlowBaseExtension

include(joinpath(@__DIR__, "..", "..", "..", "services", "node-sdk", "src", "JuliaFlowNodeSDK.jl"))
using .JuliaFlowNodeSDK
using JSON3
using UUIDs

include(joinpath(@__DIR__, "nodes", "TabularPayload.jl"))
include(joinpath(@__DIR__, "nodes", "ArrowPassthroughNode.jl"))
include(joinpath(@__DIR__, "nodes", "ArrowTableSourceNode.jl"))
include(joinpath(@__DIR__, "nodes", "ArrowTableSinkNode.jl"))
include(joinpath(@__DIR__, "nodes", "SelectColumnsNode.jl"))
include(joinpath(@__DIR__, "nodes", "LinearModelTrainerNode.jl"))
include(joinpath(@__DIR__, "nodes", "FilterRowsNode.jl"))
include(joinpath(@__DIR__, "nodes", "AggregateRowsNode.jl"))
include(joinpath(@__DIR__, "nodes", "TierOneTableNodes.jl"))

const DEFAULT_NODE_KEY = "base.arrow_passthrough"
const ARROW_TABLE_SOURCE_NODE_KEY = "base.arrow_table_source"
const ARROW_TABLE_SINK_NODE_KEY = "base.arrow_table_sink"
const SELECT_COLUMNS_NODE_KEY = "base.select_columns"
const LINEAR_MODEL_TRAINER_NODE_KEY = "base.linear_model_trainer"
const FILTER_ROWS_NODE_KEY = "base.filter_rows"
const AGGREGATE_ROWS_NODE_KEY = "base.aggregate_rows"
const NODE_REGISTRY = Dict(
    DEFAULT_NODE_KEY => ArrowPassthroughNode,
    ARROW_TABLE_SOURCE_NODE_KEY => ArrowTableSourceNode,
    ARROW_TABLE_SINK_NODE_KEY => ArrowTableSinkNode,
    SELECT_COLUMNS_NODE_KEY => SelectColumnsNode,
    LINEAR_MODEL_TRAINER_NODE_KEY => LinearModelTrainerNode,
    FILTER_ROWS_NODE_KEY => FilterRowsNode,
    AGGREGATE_ROWS_NODE_KEY => AggregateRowsNode,
    RENAME_COLUMNS_NODE_KEY => RenameColumnsNode,
    CAST_COLUMNS_NODE_KEY => CastColumnsNode,
    FILL_MISSING_NODE_KEY => FillMissingNode,
    DROP_MISSING_NODE_KEY => DropMissingNode,
    SORT_ROWS_NODE_KEY => SortRowsNode,
    LIMIT_ROWS_NODE_KEY => LimitRowsNode,
    SAMPLE_ROWS_NODE_KEY => SampleRowsNode,
    DISTINCT_ROWS_NODE_KEY => DistinctRowsNode,
    ADD_CONSTANT_COLUMN_NODE_KEY => AddConstantColumnNode,
    ROW_NUMBER_NODE_KEY => RowNumberNode,
    CONCAT_ROWS_NODE_KEY => ConcatRowsNode,
    INNER_JOIN_ROWS_NODE_KEY => InnerJoinRowsNode,
    BASIC_STATS_NODE_KEY => BasicStatsNode,
    TABLE_PROFILE_NODE_KEY => TableProfileNode,
    SPLIT_ROWS_NODE_KEY => SplitRowsNode,
    DERIVE_RATIO_NODE_KEY => DeriveRatioNode,
    BUCKETIZE_ROWS_NODE_KEY => BucketizeRowsNode,
    BI_OUTLET_NODE_KEY => BIOutletNode,
    TRIM_STRINGS_NODE_KEY => TrimStringsNode,
    NORMALIZE_CASE_NODE_KEY => NormalizeCaseNode,
    REPLACE_VALUES_NODE_KEY => ReplaceValuesNode,
    REGEX_EXTRACT_NODE_KEY => RegexExtractNode,
    VALIDATE_SCHEMA_NODE_KEY => ValidateSchemaNode,
    TOP_N_ROWS_NODE_KEY => TopNRowsNode,
    GROUP_FILTER_NODE_KEY => GroupFilterNode,
    ROLLING_MEAN_NODE_KEY => RollingMeanNode,
    RANK_ROWS_NODE_KEY => RankRowsNode,
    PERCENTILE_ROWS_NODE_KEY => PercentileRowsNode,
    COALESCE_COLUMNS_NODE_KEY => CoalesceColumnsNode,
    CLIP_VALUES_NODE_KEY => ClipValuesNode,
    CUMULATIVE_SUM_NODE_KEY => CumulativeSumNode,
    ROLLING_SUM_NODE_KEY => RollingSumNode,
    LAG_COLUMN_NODE_KEY => LagColumnNode,
    STRING_CONTAINS_FILTER_NODE_KEY => StringContainsFilterNode,
    COLUMN_MATH_NODE_KEY => ColumnMathNode,
    NULL_IF_NODE_KEY => NullIfNode,
    MIN_MAX_SCALE_NODE_KEY => MinMaxScaleNode,
    Z_SCORE_NODE_KEY => ZScoreNode,
    LEFT_JOIN_ROWS_NODE_KEY => LeftJoinRowsNode,
    ANTI_JOIN_ROWS_NODE_KEY => AntiJoinRowsNode,
    UNION_DISTINCT_ROWS_NODE_KEY => UnionDistinctRowsNode,
    UNPIVOT_ROWS_NODE_KEY => UnpivotRowsNode,
    PIVOT_ROWS_NODE_KEY => PivotRowsNode,
)

export ArrowPassthroughNode,
    ArrowTableSourceNode,
    ArrowTableSinkNode,
    SelectColumnsNode,
    LinearModelTrainerNode,
    FilterRowsNode,
    AggregateRowsNode,
    RenameColumnsNode,
    CastColumnsNode,
    FillMissingNode,
    DropMissingNode,
    SortRowsNode,
    LimitRowsNode,
    SampleRowsNode,
    DistinctRowsNode,
    AddConstantColumnNode,
    RowNumberNode,
    ConcatRowsNode,
    InnerJoinRowsNode,
    BasicStatsNode,
    TableProfileNode,
    SplitRowsNode,
    DeriveRatioNode,
    BucketizeRowsNode,
    BIOutletNode,
    TrimStringsNode,
    NormalizeCaseNode,
    ReplaceValuesNode,
    RegexExtractNode,
    ValidateSchemaNode,
    TopNRowsNode,
    GroupFilterNode,
    RollingMeanNode,
    RankRowsNode,
    PercentileRowsNode,
    CoalesceColumnsNode,
    ClipValuesNode,
    CumulativeSumNode,
    RollingSumNode,
    LagColumnNode,
    StringContainsFilterNode,
    ColumnMathNode,
    NullIfNode,
    MinMaxScaleNode,
    ZScoreNode,
    LeftJoinRowsNode,
    AntiJoinRowsNode,
    UnionDistinctRowsNode,
    UnpivotRowsNode,
    PivotRowsNode,
    DEFAULT_INPUT_PORT_ID,
    DEFAULT_OUTPUT_PORT_ID,
    DEFAULT_NODE_KEY,
    ARROW_TABLE_SOURCE_NODE_KEY,
    ARROW_TABLE_SINK_NODE_KEY,
    SELECT_COLUMNS_NODE_KEY,
    LINEAR_MODEL_TRAINER_NODE_KEY,
    FILTER_ROWS_NODE_KEY,
    AGGREGATE_ROWS_NODE_KEY,
    RENAME_COLUMNS_NODE_KEY,
    CAST_COLUMNS_NODE_KEY,
    FILL_MISSING_NODE_KEY,
    DROP_MISSING_NODE_KEY,
    SORT_ROWS_NODE_KEY,
    LIMIT_ROWS_NODE_KEY,
    SAMPLE_ROWS_NODE_KEY,
    DISTINCT_ROWS_NODE_KEY,
    ADD_CONSTANT_COLUMN_NODE_KEY,
    ROW_NUMBER_NODE_KEY,
    CONCAT_ROWS_NODE_KEY,
    INNER_JOIN_ROWS_NODE_KEY,
    BASIC_STATS_NODE_KEY,
    TABLE_PROFILE_NODE_KEY,
    SPLIT_ROWS_NODE_KEY,
    DERIVE_RATIO_NODE_KEY,
    BUCKETIZE_ROWS_NODE_KEY,
    BI_OUTLET_NODE_KEY,
    TRIM_STRINGS_NODE_KEY,
    NORMALIZE_CASE_NODE_KEY,
    REPLACE_VALUES_NODE_KEY,
    REGEX_EXTRACT_NODE_KEY,
    VALIDATE_SCHEMA_NODE_KEY,
    TOP_N_ROWS_NODE_KEY,
    GROUP_FILTER_NODE_KEY,
    ROLLING_MEAN_NODE_KEY,
    RANK_ROWS_NODE_KEY,
    PERCENTILE_ROWS_NODE_KEY,
    COALESCE_COLUMNS_NODE_KEY,
    CLIP_VALUES_NODE_KEY,
    CUMULATIVE_SUM_NODE_KEY,
    ROLLING_SUM_NODE_KEY,
    LAG_COLUMN_NODE_KEY,
    STRING_CONTAINS_FILTER_NODE_KEY,
    COLUMN_MATH_NODE_KEY,
    NULL_IF_NODE_KEY,
    MIN_MAX_SCALE_NODE_KEY,
    Z_SCORE_NODE_KEY,
    LEFT_JOIN_ROWS_NODE_KEY,
    ANTI_JOIN_ROWS_NODE_KEY,
    UNION_DISTINCT_ROWS_NODE_KEY,
    UNPIVOT_ROWS_NODE_KEY,
    PIVOT_ROWS_NODE_KEY,
    SOURCE_OUTPUT_PORT_ID,
    SINK_INPUT_PORT_ID,
    SELECT_COLUMNS_INPUT_PORT_ID,
    SELECT_COLUMNS_OUTPUT_PORT_ID,
    TRAINER_INPUT_PORT_ID,
    TRAINER_OUTPUT_PORT_ID,
    FILTER_ROWS_INPUT_PORT_ID,
    FILTER_ROWS_OUTPUT_PORT_ID,
    AGGREGATE_ROWS_INPUT_PORT_ID,
    AGGREGATE_ROWS_OUTPUT_PORT_ID,
    available_nodes,
    execute_passthrough

function available_nodes()
    return copy(NODE_REGISTRY)
end

function execute_passthrough(input_ref::String)
    config = configure(
        ArrowPassthroughNode,
        Dict("input_port_id" => DEFAULT_INPUT_PORT_ID, "output_port_id" => DEFAULT_OUTPUT_PORT_ID),
    )
    ctx = NodeContext(
        workflow_id = UUID("11111111-1111-1111-1111-111111111111"),
        execution_id = UUID("22222222-2222-2222-2222-222222222222"),
        node_id = UUID("33333333-3333-3333-3333-333333333333"),
        inputs = Dict(DEFAULT_INPUT_PORT_ID => (format = :arrow_ipc, ref = input_ref)),
        config = config,
    )
    return execute(ArrowPassthroughNode, ctx)
end

end
