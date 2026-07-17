module JuliaFlowDataScienceProjectCatalog

export safe_local_dataset_id,
    data_profile_fixture,
    data_source_options,
    data_lineage_artifacts

function safe_local_dataset_id(value::AbstractString)
    normalized = lowercase(strip(String(value)))
    normalized = replace(normalized, r"[^a-z0-9._-]+" => "-")
    normalized = strip(normalized, ['-', '.', '_'])
    isempty(normalized) && return "workflow-dataset"
    return first(normalized, min(lastindex(normalized), 80))
end

function data_profile_fixture(dataset_id::AbstractString, source_uri::AbstractString)
    normalized = lowercase(String(dataset_id))
    if occursin("superstore", normalized)
        return Dict{String,Any}(
            "rowCount" => 9800,
            "schemaSummary" => [
                Dict("name" => "order_id", "type" => "String"),
                Dict("name" => "order_date", "type" => "Date"),
                Dict("name" => "segment", "type" => "String"),
                Dict("name" => "category", "type" => "String"),
                Dict("name" => "sales", "type" => "Float64"),
                Dict("name" => "profit", "type" => "Float64"),
            ],
            "profileSummary" => [
                Dict("name" => "order_id", "type" => "String", "quality" => "unique order-line key", "role" => "id", "missingCount" => 0, "distinctCount" => 5009, "outlierCount" => 0),
                Dict("name" => "order_date", "type" => "Date", "quality" => "date range ready", "role" => "timestamp", "missingCount" => 0, "distinctCount" => 1237, "outlierCount" => 0),
                Dict("name" => "segment", "type" => "String", "quality" => "3 categories", "role" => "feature", "missingCount" => 0, "distinctCount" => 3, "outlierCount" => 0),
                Dict("name" => "category", "type" => "String", "quality" => "3 categories", "role" => "feature", "missingCount" => 0, "distinctCount" => 3, "outlierCount" => 0),
                Dict("name" => "sales", "type" => "Float64", "quality" => "right-skewed; winsorize recommended", "role" => "feature", "missingCount" => 0, "distinctCount" => 5825, "outlierCount" => 181),
                Dict("name" => "profit", "type" => "Float64", "quality" => "target candidate; negative values present", "role" => "label", "missingCount" => 0, "distinctCount" => 7287, "outlierCount" => 224),
            ],
            "previewRows" => [
                Dict("order_id" => "CA-2016-152156", "order_date" => "2016-11-08", "segment" => "Consumer", "category" => "Furniture", "sales" => 261.96, "profit" => 41.91),
                Dict("order_id" => "CA-2016-152156", "order_date" => "2016-11-08", "segment" => "Consumer", "category" => "Furniture", "sales" => 731.94, "profit" => 219.58),
                Dict("order_id" => "CA-2016-138688", "order_date" => "2016-06-12", "segment" => "Corporate", "category" => "Office Supplies", "sales" => 14.62, "profit" => 6.87),
            ],
            "qualityChecks" => [
                Dict("checkId" => "dates-parse", "label" => "Order dates parse", "status" => "passed", "detail" => "Order and ship dates are typed for time-series EDA."),
                Dict("checkId" => "profit-outliers", "label" => "Profit outliers", "status" => "warning", "detail" => "224 high-leverage profit rows should be reviewed before regression."),
                Dict("checkId" => "lineage-ready", "label" => "Local artifact lineage", "status" => "passed", "detail" => "Raw, Arrow, Parquet, and DuckDB bindings are available locally."),
            ],
            "workflowReadiness" => Dict(
                "targetColumn" => "profit",
                "trainTestSplit" => "time-aware 80/20",
                "leakageWarnings" => ["Avoid using ship_date-derived delivery duration before validating order-time availability."],
                "downstreamReady" => true,
                "recommendedNextAction" => "Open Visualize for sales/profit EDA or Transform to build aggregate features.",
            ),
            "quickPlots" => [
                Dict("plotId" => "sales-category", "title" => "Sales By Category", "kind" => "bar", "field" => "category", "values" => [Dict("label" => "Furniture", "value" => 741999), Dict("label" => "Office Supplies", "value" => 719047), Dict("label" => "Technology", "value" => 836154)]),
                Dict("plotId" => "profit-segment", "title" => "Profit By Segment", "kind" => "bar", "field" => "segment", "values" => [Dict("label" => "Consumer", "value" => 134119), Dict("label" => "Corporate", "value" => 91979), Dict("label" => "Home Office", "value" => 60299)]),
            ],
        )
    end
    return Dict{String,Any}(
        "rowCount" => 12500,
        "schemaSummary" => [
            Dict("name" => "customer_id", "type" => "String"),
            Dict("name" => "tenure_months", "type" => "Int64"),
            Dict("name" => "monthly_charges", "type" => "Float64"),
            Dict("name" => "contract_type", "type" => "String"),
            Dict("name" => "churn", "type" => "Bool"),
        ],
        "profileSummary" => [
            Dict("name" => "customer_id", "type" => "String", "quality" => "unique customer key", "role" => "id", "missingCount" => 0, "distinctCount" => 12500, "outlierCount" => 0),
            Dict("name" => "tenure_months", "type" => "Int64", "quality" => "99.8% complete", "role" => "feature", "missingCount" => 25, "distinctCount" => 73, "outlierCount" => 0),
            Dict("name" => "monthly_charges", "type" => "Float64", "quality" => "0 outliers clipped", "role" => "feature", "missingCount" => 0, "distinctCount" => 1210, "outlierCount" => 0),
            Dict("name" => "contract_type", "type" => "String", "quality" => "3 categories", "role" => "feature", "missingCount" => 0, "distinctCount" => 3, "outlierCount" => 0),
            Dict("name" => "churn", "type" => "Bool", "quality" => "target balance checked", "role" => "label", "missingCount" => 0, "distinctCount" => 2, "outlierCount" => 0),
        ],
        "previewRows" => [
            Dict("customer_id" => "C-1001", "tenure_months" => 4, "monthly_charges" => 92.1, "contract_type" => "monthly", "churn" => true),
            Dict("customer_id" => "C-1002", "tenure_months" => 28, "monthly_charges" => 63.4, "contract_type" => "annual", "churn" => false),
            Dict("customer_id" => "C-1003", "tenure_months" => 13, "monthly_charges" => 108.8, "contract_type" => "monthly", "churn" => true),
        ],
        "qualityChecks" => [
            Dict("checkId" => "target-balance", "label" => "Target balance", "status" => "passed", "detail" => "Churn rate is 26.5%, suitable for stratified split."),
            Dict("checkId" => "leakage", "label" => "Leakage scan", "status" => "passed", "detail" => "No post-churn columns are marked as features."),
            Dict("checkId" => "missingness", "label" => "Missingness", "status" => "warning", "detail" => "25 tenure rows require imputation before training."),
        ],
        "workflowReadiness" => Dict(
            "targetColumn" => "churn",
            "trainTestSplit" => "stratified 80/20",
            "leakageWarnings" => String[],
            "downstreamReady" => true,
            "recommendedNextAction" => "Open ML Studio to train a local churn classifier or Transform to encode contract_type.",
        ),
        "quickPlots" => [
            Dict("plotId" => "churn-balance", "title" => "Churn Balance", "kind" => "target_balance", "field" => "churn", "values" => [Dict("label" => "retained", "value" => 9188), Dict("label" => "churned", "value" => 3312)]),
            Dict("plotId" => "contract-risk", "title" => "Risk By Contract", "kind" => "bar", "field" => "contract_type", "values" => [Dict("label" => "monthly", "value" => 0.61), Dict("label" => "annual", "value" => 0.24), Dict("label" => "two_year", "value" => 0.12)]),
        ],
    )
end

function data_source_options(dataset_id::AbstractString, source_uri::AbstractString, target_zone::AbstractString, read_mode::AbstractString, health::AbstractDict)
    artifact_stem = safe_local_dataset_id(dataset_id)
    arrow_path = "local://data/$(target_zone)/$(artifact_stem).arrow"
    parquet_path = "local://data/processed/$(artifact_stem).parquet"
    duckdb_path = String(get(health, "dataEstateDuckdbQueryPath", "local://data/_duckdb/local-data-estate.sql"))
    object_store_status = String(get(health, "objectStoreCompatibilityStatus", "unavailable"))
    object_store_ready = object_store_status == "local_compatibility"
    object_store_reason = object_store_ready ?
        "Local compatibility mode is enabled; provider credentials and network object stores remain optional compatibility work." :
        "Object-store connectors are disabled for the local appliance until explicit local compatibility is enabled."
    options = [
        Dict("mode" => "csv", "label" => "CSV raw source", "path" => source_uri, "status" => read_mode == "csv" ? "active" : "ready", "semantics" => "Raw local file read for ingest and reproducible source checks."),
        Dict("mode" => "arrow_ipc", "label" => "Arrow IPC artifact", "path" => arrow_path, "status" => read_mode == "arrow_ipc" ? "active" : "ready", "semantics" => "Fast local columnar boundary used between JuliaFlow nodes."),
        Dict("mode" => "parquet", "label" => "Parquet managed artifact", "path" => parquet_path, "status" => read_mode == "parquet" ? "active" : "ready", "semantics" => "Durable local analytics artifact for processed and feature zones."),
        Dict("mode" => "duckdb", "label" => "DuckDB query view", "path" => duckdb_path, "status" => read_mode == "duckdb" ? "active" : String(get(health, "dataEstateDuckdbStatus", "pending")), "semantics" => "Persistent local SQL view for profiling, joins, and aggregate reads."),
    ]
    append!(
        options,
        [
            Dict("mode" => "s3", "label" => "S3-compatible object store", "path" => "s3://", "status" => object_store_ready ? "available" : "unavailable", "semantics" => object_store_reason),
            Dict("mode" => "gcs", "label" => "Google Cloud Storage", "path" => "gs://", "status" => "unavailable", "semantics" => "Cloud object stores are optional compatibility work and are not enabled in local-appliance mode."),
            Dict("mode" => "azure_blob", "label" => "Azure Blob Storage", "path" => "az://", "status" => "unavailable", "semantics" => "Cloud object stores are optional compatibility work and are not enabled in local-appliance mode."),
        ],
    )
    return options
end

function data_lineage_artifacts(dataset_id::AbstractString, source_uri::AbstractString, target_zone::AbstractString, checksum::AbstractString, row_count::Integer, health::AbstractDict)
    artifact_stem = safe_local_dataset_id(dataset_id)
    duckdb_path = String(get(health, "dataEstateDuckdbQueryPath", "local://data/_duckdb/local-data-estate.sql"))
    return [
        Dict("stage" => "raw", "artifactRef" => source_uri, "format" => "csv", "checksumSha256" => checksum, "rowCount" => row_count),
        Dict("stage" => "profiled", "artifactRef" => "local://data/$(target_zone)/$(artifact_stem).arrow", "format" => "arrow_ipc", "checksumSha256" => checksum, "rowCount" => row_count),
        Dict("stage" => "processed", "artifactRef" => "local://data/processed/$(artifact_stem).parquet", "format" => "parquet", "checksumSha256" => checksum, "rowCount" => row_count),
        Dict("stage" => "query", "artifactRef" => duckdb_path, "format" => "duckdb", "checksumSha256" => checksum, "rowCount" => row_count),
    ]
end

end
