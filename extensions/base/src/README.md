# JuliaFlow Base Extension

Phase 1 starter pack for the official base node extension with 50 registered Tier-1 table/source/sink/model/BI nodes.

Files:
- `JuliaFlowBaseExtension.jl`: package entrypoint and node registry
- `nodes/ArrowPassthroughNode.jl`: sample node using Arrow IPC payload boundary
- `nodes/ArrowTableSourceNode.jl`: source node that emits an Arrow table reference
- `nodes/ArrowTableSinkNode.jl`: sink node that validates an Arrow input and reports destination metadata
- `nodes/SelectColumnsNode.jl`: projects materialized tabular rows while preserving Arrow IPC payload shape
- `nodes/FilterRowsNode.jl`: filters materialized tabular rows with simple comparison predicates
- `nodes/AggregateRowsNode.jl`: groups materialized rows and computes count/sum/mean/min/max aggregates
- `nodes/TierOneTableNodes.jl`: stable prep/stat/BI nodes including trim, case normalization, replacement, regex extract, schema validation, top-N, group filter, rolling mean/sum, rank, percentiles, coalesce, clipping, lag, math, joins, union, pivot, and unpivot
- `nodes/LinearModelTrainerNode.jl`: trains deterministic first-pass linear coefficients from materialized rows, with explicit non-materialized fallback

Representative starter nodes:
- source/sink: `base.arrow_table_source`, `base.arrow_passthrough`, `base.arrow_table_sink`
- transform: `base.select_columns`, `base.filter_rows`, `base.rename_columns`, `base.cast_columns`, `base.fill_missing`, `base.drop_missing`, `base.sort_rows`, `base.limit_rows`, `base.sample_rows`, `base.distinct_rows`, `base.add_constant_column`, `base.row_number`, `base.derive_ratio`, `base.bucketize_rows`, `base.trim_strings`, `base.normalize_case`, `base.replace_values`, `base.regex_extract`, `base.validate_schema`, `base.top_n_rows`, `base.group_filter`, `base.rolling_mean`, `base.rank_rows`, `base.percentile_rows`, `base.coalesce_columns`, `base.clip_values`, `base.cumulative_sum`, `base.rolling_sum`, `base.lag_column`, `base.string_contains_filter`, `base.column_math`, `base.null_if`, `base.min_max_scale`, `base.z_score`, `base.unpivot_rows`, `base.pivot_rows`
- combine/aggregate/profile: `base.aggregate_rows`, `base.concat_rows`, `base.inner_join_rows`, `base.left_join_rows`, `base.anti_join_rows`, `base.union_distinct_rows`, `base.basic_stats`, `base.table_profile`, `base.split_rows`
- ML/BI: `base.linear_model_trainer`, `base.bi_outlet`

Current characteristics:
- All table nodes validate `format = :arrow_ipc` and require payload `ref`.
- Passthrough/source/sink keep boundary-focused behavior.
- Select/filter/aggregate/trainer and Tier-1 table nodes materialize deterministic results from inline `rows` or from external refs resolved through `NodeContext.metadata`.
- External ref materialization supports test/dev storage seams: `tabular_payload_store`, `load_tabular_payload` / `load_tabular_rows`, `tabular_ref_root`, root-gated `file://` JSON/JSONL row fixtures, and configurable materialization limits while preserving Arrow IPC payload shape.
- Object-store style refs support local-root persistence/materialization via `object_store_root` / `tabular_ref_root` for source+sink roundtrips without new dependencies; `file://` refs require `allow_file_refs = true` plus a configured root, and all refs stay realpath-confined to that root with existing symlink targets rejected. Production materialization can now be supplied through callback adapters: `tabular_ref_reader` / `arrow_table_reader` / `dataframe_reader` and `tabular_ref_writer` / `arrow_table_writer` / `dataframe_writer`. Package-backed Arrow/DataFrames object-store adapters and node scale beyond 50 remain future work.

Phase 1 intent:
- prove the extension registry path with representative node categories
- replace placeholder forwarding for Tier-1 transform/aggregate/model nodes with tested deterministic behavior
- stay within the Julia node SDK contract for `configure`, `infer_output_schema`, `execute`, and `on_stream_event`
