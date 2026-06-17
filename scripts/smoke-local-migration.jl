include(joinpath(@__DIR__, "..", "services", "api-gateway", "src", "JuliaFlowApiGateway.jl"))

using .JuliaFlowApiGateway
using HTTP
using JSON3

function json_post(state, path::AbstractString, payload)
    return JuliaFlowApiGateway.route_request(
        state,
        HTTP.Request(
            "POST",
            path,
            ["Content-Type" => "application/json"],
            JSON3.write(payload),
        ),
    )
end

function require_condition(condition::Bool, message::AbstractString)
    condition || error(message)
end

home = get(ENV, "JULIAFLOW_HOME", mktempdir())
workflow_path = get(ENV, "JULIAFLOW_WORKFLOW_PATH", joinpath(@__DIR__, "..", "tests", "contracts", "fixtures", "foundation.workflow.toml"))
store_root = get(ENV, "JULIAFLOW_STORE_ROOT", joinpath(home, "metadata", "gateway-store"))
data_root = get(ENV, "JULIAFLOW_DATA_ESTATE_ROOT", joinpath(home, "data"))

mkpath(joinpath(data_root, "processed"))
write(joinpath(data_root, "processed", "migration-proof.parquet"), "local migration proof artifact\n")

state = JuliaFlowApiGateway.foundation_state(workflow_path; store_root = store_root, backend = :file)

checkpoint_response = json_post(
    state,
    "/api/v1/checkpoints",
    Dict("tag" => "cp/migration-smoke", "summary" => "Local migration smoke checkpoint"),
)
require_condition(checkpoint_response.status == 201, "checkpoint creation failed: $(String(checkpoint_response.body))")

dashboard_response = json_post(
    state,
    "/api/v1/workflows/wf-foundation/dashboards/dashboard-foundation/publish",
    Dict("visibility" => "workspace"),
)
require_condition(dashboard_response.status == 200, "dashboard publish failed: $(String(dashboard_response.body))")

export_response = json_post(
    state,
    "/api/v1/local-backups",
    Dict("notes" => "local appliance backup/restore migration smoke", "includeExecutions" => true),
)
require_condition(export_response.status == 200, "local backup export failed: $(String(export_response.body))")
export_payload = JSON3.read(String(export_response.body), Dict{String,Any})
backup = export_payload["backup"]

require_condition(backup["schemaVersion"] == "juliaflow.backup.v1", "backup schema mismatch")
require_condition(backup["workflows"][1]["workflowId"] == "wf-foundation", "backup workflow missing")
require_condition(any(item -> item["tag"] == "cp/migration-smoke", backup["checkpoints"]), "backup checkpoint missing")
require_condition(any(item -> item["dashboardId"] == "dashboard-foundation", backup["publishedDashboards"]), "backup dashboard missing")
require_condition(length(backup["backupChecksumSha256"]) == 64, "backup checksum missing")
require_condition(any(item -> item["relativePath"] == joinpath("processed", "migration-proof.parquet"), backup["dataEstate"]["artifacts"]), "backup artifact reference missing")

import_home = joinpath(home, "imported")
import_state = withenv(
    "JULIAFLOW_HOME" => import_home,
    "JULIAFLOW_DATA_ESTATE_ROOT" => joinpath(import_home, "data"),
    "JULIAFLOW_METADATA_ROOT" => joinpath(import_home, "metadata"),
) do
    JuliaFlowApiGateway.load_state(joinpath(import_home, "metadata", "gateway-store"))
end

import_response = withenv(
    "JULIAFLOW_HOME" => import_home,
    "JULIAFLOW_DATA_ESTATE_ROOT" => joinpath(import_home, "data"),
    "JULIAFLOW_METADATA_ROOT" => joinpath(import_home, "metadata"),
) do
    json_post(import_state, "/api/v1/local-backups/import", Dict("backup" => backup))
end
require_condition(import_response.status == 201, "local backup import failed: $(String(import_response.body))")
import_payload = JSON3.read(String(import_response.body), Dict{String,Any})
require_condition(import_payload["status"] == "restored_with_missing_artifacts", "missing artifact status not reported")
require_condition(any(item -> item["relativePath"] == joinpath("processed", "migration-proof.parquet"), import_payload["missingArtifacts"]), "missing artifact not reported")
require_condition("wf-foundation" in import_payload["restored"]["workflows"], "workflow not restored")
require_condition("cp/migration-smoke" in import_payload["restored"]["checkpoints"], "checkpoint not restored")
require_condition("dashboard-foundation" in import_payload["restored"]["publishedDashboards"], "dashboard not restored")
require_condition(haskey(import_state.workflows, "wf-foundation"), "imported workflow not persisted")
require_condition(any(item -> item.tag == "cp/migration-smoke", import_state.checkpoints), "imported checkpoint not persisted")
require_condition(haskey(import_state.published_dashboards, "dashboard-foundation"), "imported dashboard not persisted")

tampered_backup = Dict{String,Any}(String(key) => value for (key, value) in pairs(backup))
tampered_backup["notes"] = "tampered"
tampered_response = json_post(
    JuliaFlowApiGateway.load_state(joinpath(home, "tampered", "metadata", "gateway-store")),
    "/api/v1/local-backups/import",
    Dict("backup" => tampered_backup),
)
require_condition(tampered_response.status == 400, "tampered backup was not rejected")
require_condition(occursin("checksum mismatch", String(tampered_response.body)), "tampered backup error did not mention checksum")

println(JSON3.write(Dict(
    "status" => "passed",
    "home" => home,
    "backupId" => backup["backupId"],
    "backupChecksumSha256" => backup["backupChecksumSha256"],
    "missingArtifactCount" => length(import_payload["missingArtifacts"]),
    "restoredWorkflowCount" => length(import_payload["restored"]["workflows"]),
)))
