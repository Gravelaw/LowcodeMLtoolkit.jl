include(joinpath(@__DIR__, "..", "services", "api-gateway", "src", "JuliaFlowApiGateway.jl"))
include(joinpath(@__DIR__, "..", "tests", "julia", "repository_contract_tests.jl"))

using .JuliaFlowApiGateway
using Test

backend = get(ENV, "JULIAFLOW_METADATA_SMOKE_BACKEND", "file")
home = get(ENV, "JULIAFLOW_HOME", mktempdir())
store_root = get(ENV, "JULIAFLOW_STORE_ROOT", joinpath(home, "metadata", "gateway-store"))
postgres_url = get(ENV, "JULIAFLOW_TEST_POSTGRES_URL", get(ENV, "JULIAFLOW_DATABASE_URL", ""))
postgres_schema = get(ENV, "JULIAFLOW_TEST_POSTGRES_SCHEMA", get(ENV, "JULIAFLOW_DATABASE_SCHEMA", "juliaflow_smoke_metadata"))

function run_shared_postgres_read_test!(connection_string::AbstractString, schema::AbstractString)
    writer = JuliaFlowApiGateway.JuliaFlowGatewayRepository.PostgreSQLGatewayRepository(connection_string; schema = schema)
    reader = JuliaFlowApiGateway.JuliaFlowGatewayRepository.PostgreSQLGatewayRepository(connection_string; schema = schema)
    JuliaFlowApiGateway.JuliaFlowGatewayRepository.ensure_repository!(writer)

    workflow_toml = read(joinpath(@__DIR__, "..", "tests", "contracts", "fixtures", "foundation.workflow.toml"), String)
    JuliaFlowApiGateway.JuliaFlowGatewayRepository.save_workflow!(writer, workflow_toml; producer = "metadata-smoke-writer")
    workflows = JuliaFlowApiGateway.JuliaFlowGatewayRepository.load_workflows(reader)
    @test haskey(workflows, "wf-foundation")
    @test workflows["wf-foundation"].name == "Foundation PoC"

    cursor = JuliaFlowApiGateway.JuliaFlowGatewayRepository.save_consumer_cursor!(writer, "metadata-smoke-reader", 7)
    @test cursor == 7
    @test JuliaFlowApiGateway.JuliaFlowGatewayRepository.load_consumer_cursor(reader, "metadata-smoke-reader") == 7
end

if backend == "file"
    mkpath(store_root)
    repo = JuliaFlowApiGateway.JuliaFlowGatewayRepository.ensure_repository!(
        JuliaFlowApiGateway.JuliaFlowGatewayRepository.FileGatewayRepository(store_root),
    )
    run_gateway_repository_contract!(repo; label = "File metadata smoke")
elseif backend == "postgres-cleanup"
    isempty(postgres_url) && error("JULIAFLOW_TEST_POSTGRES_URL or JULIAFLOW_DATABASE_URL is required for postgres metadata cleanup")
    repo = JuliaFlowApiGateway.JuliaFlowGatewayRepository.PostgreSQLGatewayRepository(postgres_url; schema = postgres_schema)
    conn = JuliaFlowApiGateway.JuliaFlowGatewayRepository.connect(repo)
    try
        JuliaFlowApiGateway.JuliaFlowGatewayRepository.execute(conn, "DROP SCHEMA IF EXISTS $(repo.schema) CASCADE;")
    finally
        JuliaFlowApiGateway.JuliaFlowGatewayRepository.close_connection(conn)
    end
elseif backend == "postgres"
    isempty(postgres_url) && error("JULIAFLOW_TEST_POSTGRES_URL or JULIAFLOW_DATABASE_URL is required for postgres metadata smoke")
    repo = JuliaFlowApiGateway.JuliaFlowGatewayRepository.PostgreSQLGatewayRepository(postgres_url; schema = postgres_schema)
    JuliaFlowApiGateway.JuliaFlowGatewayRepository.ensure_repository!(repo)
    conn = JuliaFlowApiGateway.JuliaFlowGatewayRepository.connect(repo)
    try
        run_gateway_repository_contract!(repo; label = "PostgreSQL metadata smoke")
        run_shared_postgres_read_test!(postgres_url, postgres_schema)
    finally
        try
            JuliaFlowApiGateway.JuliaFlowGatewayRepository.execute(conn, "DROP SCHEMA IF EXISTS $(repo.schema) CASCADE;")
        finally
            JuliaFlowApiGateway.JuliaFlowGatewayRepository.close_connection(conn)
        end
    end
else
    error("unsupported JULIAFLOW_METADATA_SMOKE_BACKEND: $(backend)")
end
