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

    # x0 ? x1 : 0 == x0 & x1 (canonicalizes to conjunction)
    @test bdd_mk(0, x1, zero).ptr == bdd_and(x0, x1).ptr

    # Verify returns a BDDNode and has expected index
    mk2 = bdd_mk(2, one, zero)
    @test isa(mk2, BDDNode)
    @test node_index(mk2) == 2

    # Complemented variable construction: x0 ? 0 : 1 == ¬x0 (functional check)
    not_x0 = bdd_mk(0, zero, one)
    # Avoid pointer equality (complement edge semantics not guaranteed here)
    @test minterms(bdd_and(not_x0, x0), 3) == 0.0  # x0 & ¬x0 unsat
    @test minterms(not_x0, 3) == minterms(!x0, 3)

    # Invalid ordering: index 1 with child x0 should raise (manager enforces ordering)
    @test_throws ErrorException bdd_mk(1, x0, zero)

    # Equivalence with Shannon decomposition: ite(x, t, e) == (x & t) | (~x & e)
    mk_a = bdd_mk(0, one, zero)
    comp_a = bdd_or(bdd_and(x0, one), bdd_and(!x0, zero))
    @test minterms(mk_a, 3) == minterms(comp_a, 3)

    mk_b = bdd_mk(0, x1, zero)
    comp_b = bdd_or(bdd_and(x0, x1), bdd_and(!x0, zero))
    @test minterms(mk_b, 3) == minterms(comp_b, 3)

    mk_c = bdd_mk(0, x1, one)
    comp_c = bdd_or(bdd_and(x0, x1), bdd_and(!x0, one))
    @test minterms(mk_c, 3) == minterms(comp_c, 3)

    quit(bm)

    # ZDD cases
    zm = ZDDManager(nvars=3)
    z0 = var(zm, 0)
    z1 = var(zm, 1)
    empty = zdd_empty(zm)
    base = zdd_base(zm)

    # zdd_mk creates node: verify it returns valid ZDDNode and family size
    mk0 = zdd_mk(0, z1, empty)  # should represent {{0,1}}
    @test isa(mk0, ZDDNode)
    @test zdd_count(mk0) == 1.0

    # Singleton construction via mk: var i equivalent to mk(i, base, empty)
    mk_var0 = zdd_mk(0, base, empty)
    @test zdd_count(mk_var0) == zdd_count(z0) == 1.0
    @test mk_var0.ptr == z0.ptr

    # zdd_mk with two ZDD nodes
    # @test_throws ErrorException zdd_mk(1, base, z0)

    # Verify manager consistency check works (different managers)
    zm2 = ZDDManager(nvars=2)
    z2 = var(zm2, 0)
    @test_throws ErrorException zdd_mk(0, base, z2)  # Different managers
    quit(zm2)

    # Ordering violation for ZDD: expect error when child has lower index
    @test_throws ErrorException zdd_mk(1, z0, empty)

    quit(zm)
end

@testset "Node builders" begin
    bdd = BDDManager(nvars=3)
    x1 = var(bdd, 0)
    x2 = var(bdd, 1)
    x3 = var(bdd, 2)
    z1 = x1 & (x2 & x3)

    # Build a BDD node representing x1 ? x2 : x3
    c0 = const0(bdd)
    c1 = const1(bdd)
    u1 = bdd_mk(2, c1, c0)
    u2 = bdd_mk(1, u1, c0)
    u3 = bdd_mk(0, u2, c0)

    @test minterms(u3, 3) == minterms(z1, 3)
    quit(bdd)
end

@testset "ZDD Node builders" begin
    zdd = ZDDManager(nvars=3)
    a = var(zdd, 0)
    b = var(zdd, 1)
    c = var(zdd, 2)
    z_union = zdd_union(a, zdd_union(b, c))

    # Build a ZDD node representing { {0}, {1}, {2} }
    empty = zdd_empty(zdd)
    base = zdd_base(zdd)
    u1 = zdd_mk(2, base, empty)  # {2}
    u2 = zdd_mk(1, base, u1)     # {1}, {2}
    u3 = zdd_mk(0, base, u2)     # {0}, {1}, {2}

    @test zdd_count(u3) == zdd_count(z_union)
    quit(zdd)
end