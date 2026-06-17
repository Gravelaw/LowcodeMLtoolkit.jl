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

artifact_hash = get(ENV, "JULIAFLOW_OFFLINE_HUB_ARTIFACT_HASH", "")
home = get(ENV, "JULIAFLOW_HOME", mktempdir())
workflow_path = get(ENV, "JULIAFLOW_WORKFLOW_PATH", joinpath(@__DIR__, "..", "tests", "contracts", "fixtures", "foundation.workflow.toml"))
store_root = get(ENV, "JULIAFLOW_STORE_ROOT", joinpath(home, "metadata", "gateway-store"))

state = JuliaFlowApiGateway.foundation_state(workflow_path; store_root = store_root, backend = :file)
health = JSON3.read(JuliaFlowApiGateway.healthcheck(state), Dict{String,Any})

require_condition(get(health, "hubCacheStatus", "") == "ready", "offline Hub cache is not ready")
require_condition(get(health, "hubOfflineInstallReady", false) == true, "offline Hub install proof is not ready")
require_condition(get(health, "hubBundledExtensionCount", 0) >= 1, "no bundled Hub extension found")

function offline_manifest(extension_id::AbstractString, package_ref::AbstractString, sandbox_command::AbstractString)
    return Dict(
        "extensionId" => extension_id,
        "name" => extension_id == "juliaflow-offline-proof" ? "Offline Proof Pack" : "Unsafe Offline Proof Pack",
        "version" => "0.1.0",
        "publisher" => "official",
        "summary" => "Local offline Hub install proof without external registry access.",
        "packageRef" => package_ref,
        "tags" => ["official", "offline", "local-first"],
        "engineCompatibility" => "alpha-core",
        "requiredContractVersion" => "0.1.0",
        "supportedCheckpoints" => ["cp/00-foundation", "cp/01-contracts-frozen", "cp/02-alpha-core", "cp/03-alpha-gpu-bi"],
        "compatibleCheckpoints" => ["cp/00-foundation", "cp/01-contracts-frozen", "cp/02-alpha-core", "cp/03-alpha-gpu-bi"],
        "dependencies" => String[],
        "publisherIdentity" => "official:juliaflow",
        "artifactHashes" => Dict("package" => artifact_hash),
        "compatibilitySandboxCommand" => sandbox_command,
        "mirrorRefs" => ["mirror://offline/offline-proof"],
    )
end

register_response = json_post(
    state,
    "/api/v1/hub/extensions/register",
    Dict("manifest" => offline_manifest("juliaflow-offline-proof", "hub://offline/offline-proof", "julia --project=. extensions/labs/test/runtests.jl")),
)
require_condition(register_response.status == 201, "offline extension registration failed")

enable_response = json_post(
    state,
    "/api/v1/hub/extensions/juliaflow-offline-proof/install",
    Dict("action" => "enable"),
)
require_condition(enable_response.status == 200, "offline extension enable failed: $(String(enable_response.body))")
enabled_payload = JSON3.read(String(enable_response.body), Dict{String,Any})
verification = enabled_payload["extension"]["verification"]
require_condition(verification["verified"] == true, "offline extension verification did not pass")
require_condition(verification["artifacts"]["status"] == "passed", "offline artifact verification failed")
require_condition(verification["mirrors"]["status"] == "passed", "offline mirror verification failed")
require_condition(verification["sandbox"]["status"] == "passed", "offline sandbox verification failed")

unsafe_register_response = json_post(
    state,
    "/api/v1/hub/extensions/register",
    Dict("manifest" => offline_manifest("juliaflow-offline-unsafe-proof", "hub://offline/unsafe-proof", "python -m unsafe")),
)
require_condition(unsafe_register_response.status == 201, "unsafe extension registration failed")
unsafe_enable_response = json_post(
    state,
    "/api/v1/hub/extensions/juliaflow-offline-unsafe-proof/install",
    Dict("action" => "enable"),
)
require_condition(unsafe_enable_response.status == 409, "unsafe extension enable was not blocked")

println(JSON3.write(Dict(
    "status" => "passed",
    "home" => home,
    "extensionId" => "juliaflow-offline-proof",
    "artifactStorePath" => get(health, "hubArtifactStorePath", ""),
    "mirrorRegistryPath" => get(health, "hubMirrorRegistryPath", ""),
)))
