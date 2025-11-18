using MiniCUDD
using Test

@testset "Node builders (bdd_mk / zdd_mk)" begin
    # BDD cases
    bm = BDDManager(nvars=3)
    x0 = var(bm, 0)
    x1 = var(bm, 1)
    one = const1(bm)
    zero = const0(bm)

    # bdd_mk with (1, 0) should be the variable itself
    @test bdd_mk(0, one, zero).ptr == x0.ptr

    # x0 ? x1 : 0 == x0 & x1
    @test bdd_mk(0, x1, zero).ptr == bdd_and(x0, x1).ptr

    # Verify returns a BDDNode
    mk2 = bdd_mk(2, one, zero)
    @test isa(mk2, BDDNode)
    @test node_index(mk2) == 2

    quit(bm)

    # ZDD cases
    zm = ZDDManager(nvars=3)
    z0 = var(zm, 0)
    z1 = var(zm, 1)
    empty = zdd_empty(zm)
    base = zdd_base(zm)

    # zdd_mk creates node: verify it returns valid ZDDNode
    mk0 = zdd_mk(0, z1, empty)
    @test isa(mk0, ZDDNode)

    # zdd_mk with two ZDD nodes
    mk1 = zdd_mk(1, base, z0)
    @test isa(mk1, ZDDNode)

    # Verify manager consistency check works
    zm2 = ZDDManager(nvars=2)
    z2 = var(zm2, 0)
    @test_throws ErrorException zdd_mk(0, base, z2)  # Different managers
    quit(zm2)

    quit(zm)
end
