# JuliaFlow Base Extension

Minimal Phase 0 scaffold for official base node pack.

Files:
- `JuliaFlowBaseExtension.jl`: package entrypoint and node registry
- `nodes/ArrowPassthroughNode.jl`: sample node using Arrow IPC payload boundary

Current sample node:
- `base.arrow_passthrough`
- input port `table_in`, output port `table_out`
- validates `format = :arrow_ipc`
- requires Arrow payload `ref`
- returns payload unchanged across node boundary
