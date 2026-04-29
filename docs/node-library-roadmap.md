# JuliaFlow Node Library Scale Roadmap

Last updated: 2026-04-29

## Purpose

Track BRD node-library scale from current Tier-1 base pack toward Phase 1 / Alpha target and later Beta/GA breadth.

## Quality Tiers

- `stable`: deterministic behavior, tests assert output payloads, preserves Arrow IPC boundary, documented config. Regex-based nodes must keep bounded pattern/input checks and block obvious ReDoS patterns.
- `adapter-required`: production behavior depends on configured runtime adapter such as object-store Arrow/DataFrames reader/writer, Kafka/NATS adapter, or GPU backend; tests cover adapter contract with fixture callbacks or mocks.
- `experimental`: visible for roadmap/demo only; must be labelled as experimental and must not count toward stable BRD completion.

## Current Baseline: 50 Stable Tier-1 Nodes

Evidence:
- Registry: `extensions/base/src/JuliaFlowBaseExtension.jl`
- Implementations: `extensions/base/src/nodes/`
- Tests: `extensions/base/test/runtests.jl`

Stable families:
- source/sink: Arrow table source, Arrow passthrough, Arrow table sink
- transform: select, filter, rename, cast, fill missing, drop missing, sort, limit, sample, distinct, constant column, row number, derive ratio, bucketize, trim strings, normalize case, replace values, regex extract, validate schema, top-N rows, group filter, rolling mean, rank rows, percentile rows, coalesce columns, clip values, cumulative sum, rolling sum, lag column, string contains filter, column math, null-if, min-max scale, z-score, unpivot rows, pivot rows
- combine/aggregate/profile: aggregate, concat, inner join, left join, anti join, union distinct, basic stats, table profile, split
- ML/BI: linear model trainer, BI outlet

## Production Materialization Seam

Current status:
- Local JSON/JSONL and local object-store-style refs remain supported for dev/test fallback, with file refs disabled unless `allow_file_refs = true` and a configured storage root confines reads/writes and existing symlink targets are rejected.
- New adapter callbacks let production readers/writers materialize or persist Arrow/DataFrames-shaped refs without adding dependencies in the base pack; materialization limits bound input rows, output rows, columns, and local ref bytes.
- Callback metadata keys:
  - read: `tabular_ref_reader`, `arrow_table_reader`, or `dataframe_reader`
  - write: `tabular_ref_writer`, `arrow_table_writer`, or `dataframe_writer`
  - optional label: `tabular_adapter_name` or `tabular_materialization_adapter`

Completion boundary:
- This seam does not by itself satisfy full BRD production Arrow/DataFrames object-storage execution.
- Full completion requires package-backed or service-backed Arrow/DataFrames object-store adapter and broader stable node scale evidence.

## 50 -> 75 Node Plan

Goal: continue broadening stable data prep and BI-ready transforms while keeping adapter-required IO explicit.

Candidate additions:
- I/O adapters: CSV source/sink, Parquet source/sink, database table source/sink, HTTP JSON source, object-store list/read/write nodes.
- Data cleanup: parse date/time, split columns, deduplicate by key, type-safe date bucketing.
- Aggregation/window: top-N per group, weighted average, grouped rolling windows, calendar windows.
- Joins/blends: right/full join, lookup enrich, fuzzy key match experimental.
- BI prep: metric definition, dimension mapping, date hierarchy, KPI threshold, chart dataset output.

Acceptance for 75:
- At least 75 registered nodes.
- At least 75 registered nodes with 50+ stable nodes already output-inspected; new stable additions must include output-inspecting tests.
- Adapter-required nodes have fixture/mock adapter tests and explicit docs.
- No experimental node counted as stable.

## 75 -> 150 Node Plan

Goal: satisfy Phase 1 / Alpha breadth across source, transform, ML/stat, stream, GPU, and BI paths.

Candidate additions:
- Advanced stats: correlation, covariance, histogram, outlier detection, standardization, train/test split variants.
- ML primitives: logistic regression, k-means, PCA, model score, model metrics, cross validation adapter.
- Streaming prep: event-time assign, watermark, tumbling/sliding window, stream aggregate, dedupe by event id, sink transaction marker.
- GPU nodes: GPU matrix multiply, GPU vector transform, GPU aggregate, GPU model training primitive with CPU fallback.
- Hub/package helpers: extension manifest validate, compatibility report, package hash verify.

Acceptance for 150:
- 150 registered nodes with tier labels.
- 100+ stable or adapter-required nodes with tests.
- Runtime docs map node families to BRD requirements and quality tier.
- `docs/brd-traceability.md` links node breadth evidence before TODO completion.

## 150 -> 300+ Roadmap

Goal: Beta/GA ecosystem growth, including official packs and Hub partner packs.

Candidate directions:
- enterprise sources/sinks, geospatial, time-series, NLP, graph analytics, deep-learning adapters, visualization exports, governance/audit nodes.
- partner/Hub certification path for sandbox compatibility, hash verification, and private mirrors.
