using Dates
using Test

const FOUNDATION_PATH = joinpath(@__DIR__, "..", "contracts", "fixtures", "foundation.workflow.toml")
const PARALLEL_PATH = joinpath(@__DIR__, "..", "contracts", "fixtures", "parallel.workflow.toml")

function sample_checkpoint(tag::String; summary::String = "checkpoint")
    return JuliaFlowApiGateway.JuliaFlowGatewayRepository.GatewayCheckpoint(
        tag = tag,
        summary = summary,
        created_at = "2026-04-18T00:00:00Z",
    )
end

function sample_execution(execution_id::String; workflow_id::String = "wf-foundation", workflow_version::String = "0.1.0")
    return JuliaFlowApiGateway.JuliaFlowGatewayRepository.GatewayExecution(
        execution_id = execution_id,
        workflow_id = workflow_id,
        workflow_version = workflow_version,
        checkpoint_tag = "cp/01-contracts-frozen",
        status = "queued",
        mode = "cpu_only",
        plan = ["node-source", "node-transform", "node-bi"],
        stages = [["node-source"], ["node-transform"], ["node-bi"]],
        node_count = 3,
        connection_count = 2,
        created_at = "2026-04-18T00:00:00Z",
    )
end

function run_gateway_repository_contract!(repo::JuliaFlowApiGateway.JuliaFlowGatewayRepository.AbstractGatewayRepository; label::AbstractString)
    foundation_toml = read(FOUNDATION_PATH, String)
    parallel_toml = read(PARALLEL_PATH, String)

    @testset "$(label) repository contract" begin
        workflow = JuliaFlowApiGateway.JuliaFlowGatewayRepository.save_workflow!(repo, foundation_toml)
        @test workflow.id == "wf-foundation"

        updated_toml = replace(foundation_toml, "Foundation PoC" => "Foundation PoC Contract Test")
        updated = JuliaFlowApiGateway.JuliaFlowGatewayRepository.save_workflow!(repo, updated_toml)
        @test updated.name == "Foundation PoC Contract Test"

        parallel = JuliaFlowApiGateway.JuliaFlowGatewayRepository.save_workflow!(repo, parallel_toml)
        @test parallel.id == "wf-parallel"

        workflows = JuliaFlowApiGateway.JuliaFlowGatewayRepository.load_workflows(repo)
        @test sort!(collect(keys(workflows))) == ["wf-foundation", "wf-parallel"]
        @test workflows["wf-foundation"].name == "Foundation PoC Contract Test"
        @test workflows["wf-parallel"].version == parallel.version
        @test workflows["wf-parallel"].name == "Parallel PoC"

        checkpoint = JuliaFlowApiGateway.JuliaFlowGatewayRepository.save_checkpoint!(repo, sample_checkpoint("cp/01-contracts-frozen"; summary = "Contracts frozen"))
        @test checkpoint.tag == "cp/01-contracts-frozen"
        JuliaFlowApiGateway.JuliaFlowGatewayRepository.save_checkpoint!(repo, sample_checkpoint("cp/01-contracts-frozen"; summary = "Contracts frozen updated"))
        checkpoints = JuliaFlowApiGateway.JuliaFlowGatewayRepository.load_checkpoints(repo)
        @test length(checkpoints) == 1
        @test checkpoints[1].summary == "Contracts frozen updated"

        execution = JuliaFlowApiGateway.JuliaFlowGatewayRepository.save_execution!(repo, sample_execution("exec-001"; workflow_version = workflows["wf-foundation"].version))
        @test execution.execution_id == "exec-001"
        JuliaFlowApiGateway.JuliaFlowGatewayRepository.save_execution!(repo, sample_execution("exec-001"; workflow_version = workflows["wf-foundation"].version))
        JuliaFlowApiGateway.JuliaFlowGatewayRepository.save_execution!(
            repo,
            sample_execution(
                "exec-002";
                workflow_id = "wf-parallel",
                workflow_version = workflows["wf-parallel"].version,
            ),
        )
        executions = JuliaFlowApiGateway.JuliaFlowGatewayRepository.load_executions(repo)
        @test [item.execution_id for item in executions] == ["exec-001", "exec-002"]
        @test executions[1].status == "queued"
        @test executions[2].workflow_id == "wf-parallel"

        invalid_toml = replace(foundation_toml, "wf-foundation" => "wf-invalid", count = 1)
        invalid_toml = replace(invalid_toml, "direction = \"input\"" => "direction = \"output\"", count = 1)
        @test_throws ErrorException JuliaFlowApiGateway.JuliaFlowGatewayRepository.save_workflow!(repo, invalid_toml)
    end
end

function with_postgres_repository(f::Function)
    connection_string = get(ENV, "JULIAFLOW_TEST_POSTGRES_URL", "")
    if isempty(connection_string)
        @test_skip "PostgreSQL integration skipped: set JULIAFLOW_TEST_POSTGRES_URL"
        return nothing
    end

    schema = get(ENV, "JULIAFLOW_TEST_POSTGRES_SCHEMA", "juliaflow_test_" * replace(string(Dates.now()), ":" => "", "-" => ""))
    repo = JuliaFlowApiGateway.JuliaFlowGatewayRepository.PostgreSQLGatewayRepository(connection_string; schema = schema)
    JuliaFlowApiGateway.JuliaFlowGatewayRepository.ensure_repository!(repo)

    conn = JuliaFlowApiGateway.JuliaFlowGatewayRepository.connect(repo)
    try
        return f(repo)
    finally
        try
            JuliaFlowApiGateway.JuliaFlowGatewayRepository.LibPQ.execute(conn, "DROP SCHEMA IF EXISTS $(repo.schema) CASCADE;")
        finally
            close(conn)
        end
    end
end
