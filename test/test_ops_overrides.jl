using Test
using MiniCUDD

@testset "ZDD operator overrides (+, *, -)" begin
    mgr = ZDDManager(nvars=4)
    z0 = var(mgr, 0)
    z1 = var(mgr, 1)
    z2 = var(mgr, 2)

    # + is union
    @test (z0 + z1).ptr == zdd_union(z0, z1).ptr
    # * is intersection
    @test (z0 * z1).ptr == zdd_intersect(z0, z1).ptr
    # - is difference
    @test (z0 - z1).ptr == zdd_diff(z0, z1).ptr

    # Mixed combinations
    @test ((z0 + z1) * z2).ptr == zdd_intersect(zdd_union(z0, z1), z2).ptr
    @test ((z0 + z1) - z2).ptr == zdd_diff(zdd_union(z0, z1), z2).ptr

    quit(mgr)
end
