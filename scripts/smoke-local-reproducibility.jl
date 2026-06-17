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

state = JuliaFlowApiGateway.foundation_state(workflow_path; store_root = store_root, backend = :file)

checkpoint_response = json_post(
    state,
    "/api/v1/checkpoints",
    Dict("tag" => "cp/repro-smoke", "summary" => "Academic reproducibility smoke checkpoint"),
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
    "/api/v1/reproducibility-bundles",
    Dict(
        "workflowId" => "wf-foundation",
        "checkpointTag" => "cp/repro-smoke",
        "dashboardId" => "dashboard-foundation",
        "notes" => "offline EDA -> model -> explain -> dashboard -> checkpoint -> export/reimport smoke",
    ),
)
require_condition(export_response.status == 200, "reproducibility export failed: $(String(export_response.body))")
export_payload = JSON3.read(String(export_response.body), Dict{String,Any})
bundle = export_payload["bundle"]

require_condition(bundle["workflow"]["workflowId"] == "wf-foundation", "bundle workflow mismatch")
require_condition(bundle["checkpoint"]["tag"] == "cp/repro-smoke", "bundle checkpoint mismatch")
require_condition(bundle["dataReferences"][1]["datasetId"] == "foundation-sales-sample", "bundle dataset reference missing")
require_condition(bundle["packageEnvironment"]["offlineOnly"] == true, "bundle package metadata is not offline-only")
require_condition(bundle["runtimeConfig"]["cloudCredentialsRequired"] == false, "bundle unexpectedly requires cloud credentials")
require_condition(bundle["modelArtifact"]["modelId"] == "foundation-linear-baseline", "bundle model artifact missing")
require_condition(bundle["explainabilityOutputs"]["method"] == "deterministic_feature_contribution", "bundle explanation missing")
require_condition(bundle["dashboardSnapshot"]["dashboardId"] == "dashboard-foundation", "bundle dashboard snapshot missing")
require_condition(length(bundle["bundleChecksumSha256"]) == 64, "bundle checksum missing")

import_state = JuliaFlowApiGateway.load_state(joinpath(home, "imported-gateway-store"))
import_response = json_post(
    import_state,
    "/api/v1/reproducibility-bundles/import",
    Dict("bundle" => bundle),
)
require_condition(import_response.status == 201, "reproducibility import failed: $(String(import_response.body))")
import_payload = JSON3.read(String(import_response.body), Dict{String,Any})
require_condition(import_payload["workflowId"] == "wf-foundation", "import workflow mismatch")
require_condition(import_payload["checkpointTag"] == "cp/repro-smoke", "import checkpoint mismatch")
require_condition(import_payload["dashboardId"] == "dashboard-foundation", "import dashboard mismatch")
require_condition(haskey(import_state.workflows, "wf-foundation"), "imported workflow not persisted")
require_condition(import_state.checkpoints[end].tag == "cp/repro-smoke", "imported checkpoint not persisted")
require_condition(haskey(import_state.published_dashboards, "dashboard-foundation"), "imported dashboard not persisted")

tampered_bundle = Dict{String,Any}(String(key) => value for (key, value) in pairs(bundle))
tampered_bundle["notes"] = "tampered"
tampered_response = json_post(
    JuliaFlowApiGateway.load_state(joinpath(home, "tampered-gateway-store")),
    "/api/v1/reproducibility-bundles/import",
    Dict("bundle" => tampered_bundle),
)
require_condition(tampered_response.status == 400, "tampered bundle was not rejected")
require_condition(occursin("checksum mismatch", String(tampered_response.body)), "tampered bundle error did not mention checksum")

println(JSON3.write(Dict(
    "status" => "passed",
    "home" => home,
    "bundleId" => bundle["bundleId"],
    "bundleChecksumSha256" => bundle["bundleChecksumSha256"],
    "workflowId" => import_payload["workflowId"],
    "checkpointTag" => import_payload["checkpointTag"],
    "dashboardId" => import_payload["dashboardId"],
)))
