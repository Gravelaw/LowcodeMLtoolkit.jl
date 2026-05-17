using Test

@testset "Labs Hub Sandbox" begin
    @test get(ENV, "JULIAFLOW_HUB_SANDBOX", "1") == "1"
    @test true
end
