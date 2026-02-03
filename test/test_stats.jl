using MiniCUDD
using Test

@testset "Manager stats wrappers" begin
    mgr = Manager(nvars=2)

    # create a few nodes to bump counts
    x0 = var(mgr, 0)
    x1 = var(mgr, 1)
    f = bdd_and(mgr, x0, x1)

    cur = node_count(mgr)
    peak = peak_node_count(mgr)
    mem = memory_in_use(mgr)
    maxmem = max_memory(mgr)

    @test cur >= 0
    @test peak >= cur
    @test mem >= 0
    @test maxmem >= 0

    close!(f)
    close!(x0)
    close!(x1)
    quit(mgr)
end
