# JuliaFlow Base Extension

Minimal Phase 1 starter pack for the official base node extension.

Files:
- `JuliaFlowBaseExtension.jl`: package entrypoint and node registry
- `nodes/ArrowPassthroughNode.jl`: sample node using Arrow IPC payload boundary
- `nodes/ArrowTableSourceNode.jl`: source node that emits an Arrow table reference
- `nodes/ArrowTableSinkNode.jl`: sink node that validates an Arrow input and reports destination metadata
- `nodes/SelectColumnsNode.jl`: transform placeholder that records a projection intent
- `nodes/LinearModelTrainerNode.jl`: ML placeholder that emits model metadata from a table input

Representative starter nodes:
- `base.arrow_table_source`
- `base.arrow_passthrough`
- `base.arrow_table_sink`
- `base.select_columns`
- `base.linear_model_trainer`

Current characteristics:
- `base.arrow_passthrough`
- input port `table_in`, output port `table_out`
- validates `format = :arrow_ipc`
- requires Arrow payload `ref`
- returns payload unchanged across node boundary

Phase 1 intent:
- prove the extension registry path with more than one node category
- keep execution honest by surfacing warnings where behavior is still placeholder-only
- stay within the Julia node SDK contract for `configure`, `infer_output_schema`, `execute`, and `on_stream_event`
