# JuliaFlow Node Library Scale Roadmap

Last updated: 2026-05-01

## Purpose

Track BRD node-library scale from current Tier-1 base pack toward Phase 1 / Alpha target and later Beta/GA breadth.

## Quality Tiers

- `stable`: deterministic behavior, tests assert output payloads, preserves Arrow IPC boundary, documented config. Regex-based nodes must keep bounded pattern/input checks and block obvious ReDoS patterns.
- `adapter-required`: production behavior depends on configured runtime adapter such as object-store Arrow/DataFrames reader/writer, Kafka/NATS adapter, or GPU backend; tests cover adapter contract with fixture callbacks or mocks.
- `experimental`: visible for roadmap/demo only; must be labelled as experimental and must not count toward stable BRD completion.

## Current Baseline: 150 Stable Tier-1 Nodes

Evidence:
- Registry: `extensions/base/src/JuliaFlowBaseExtension.jl`
- Implementations: `extensions/base/src/nodes/`
- Tests: `extensions/base/test/runtests.jl`

Stable families:
- source/sink: Arrow table source, Arrow passthrough, Arrow table sink, object-store list helper, package-backed Arrow/DataFrames `.arrow`/`.feather`/`.ipc` local object-store read/write, provider-neutral remote object-store Arrow IPC read/write service adapter
- transform: select, filter, rename, cast, fill missing, drop missing, sort, limit, sample, distinct, dedupe by key, constant column, row number, derive ratio, bucketize, trim strings, normalize whitespace, normalize case, replace values, regex extract/replace, split/copy/concat/drop/keep/substring columns, string length, parse date, date bucket, date parts, validate schema, top-N rows, top-N per group, group filter, rolling mean, rolling sum, moving min/max, cumulative sum/count/mean, lag/lead column, rank rows, percentile rows, quantile buckets, threshold buckets, one-hot encode, coalesce columns, clip values, string contains filter, column math, null-if, min-max scale, z-score, round/absolute/log/percent-change transforms, outlier flags, train/test split, event-time/window/watermark/sessionization/replay/exactly-once helpers, boolean flag, row hash, dataset version hash, unpivot rows, pivot rows
- combine/aggregate/profile: aggregate, weighted average, group sum/mean/min/max/count/percent-of-total, concat, inner/right/left/full/semi/anti joins, lookup enrich, union distinct, value counts, missingness summary, basic stats, table profile, type profile, split, correlation, covariance, histogram, standardization, null-rate, duplicate-rate, cardinality, stream aggregate, cross join, rows-to-columns, schema drift, column presence
- ML/BI: linear model trainer, linear score, classification threshold, confusion matrix, regression metrics, k-means assignment, PCA-style projection, feature vector, BI outlet, metric definition, dimension mapping, KPI threshold, chart dataset output, metric cards, dashboard summary, extension manifest validation, compatibility report, package hash verify, dataset lineage, policy/access decisions, GPU capability flags

## Production Materialization Seam

Current status:
- Local JSON/JSONL and local object-store-style refs remain supported for dev/test fallback, with file refs disabled unless `allow_file_refs = true` and a configured storage root confines reads/writes and existing symlink targets are rejected.
- Arrow.jl/DataFrames.jl/Tables.jl now back package materialization for `.arrow`, `.feather`, and `.ipc` refs under configured `object_store_root` / `tabular_ref_root` when `enable_arrow_dataframe_adapter = true`; provider-neutral remote object-store service adapters transfer Arrow IPC as base64 JSON envelopes when `enable_remote_object_store_adapter = true`; callback and named service-backed adapter registries remain available. Materialization limits bound input rows, output rows, columns, and local ref bytes.
- Callback metadata keys:
  - read: `tabular_ref_reader`, `arrow_table_reader`, or `dataframe_reader`
  - write: `tabular_ref_writer`, `arrow_table_writer`, or `dataframe_writer`
  - named registry: `tabular_adapter_registry`, `tabular_materialization_adapters`, or `tabular_service_adapters`
  - optional label/selector: `tabular_adapter_name` or `tabular_materialization_adapter`

Completion boundary:
- Package-backed local object-store Arrow/DataFrames execution is implemented for root-confined refs.
- Provider-neutral remote object-store service adapter execution is implemented and tested without live credentials. Provider-specific deployment manifests/credentials remain production hardening work.

## 150 -> 300+ Roadmap

Goal: grow beyond Phase 1 / Alpha breadth into Beta/GA ecosystem coverage, including official packs and Hub partner packs.

Candidate directions:
- enterprise sources/sinks: CSV/Parquet/database/HTTP variants, production object-store manifests, and governed sink commits.
- analytics domains: geospatial, time-series, NLP, graph analytics, deep-learning adapters, visualization exports, and governance/audit nodes.
- GPU/streaming depth: GPU matrix/vector/aggregate/model primitives with CPU fallback, replay adapters, and exactly-once transaction helpers.
- partner certification: sandbox compatibility, package hash verification, private mirrors, and Hub trust-policy metadata.

Acceptance for post-150 growth:
- New official packs keep tier labels and output-inspecting tests.
- Runtime docs map node families to BRD requirements and quality tier.
- `docs/brd-traceability.md` links evidence before TODO completion.
