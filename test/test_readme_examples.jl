using Test
using MiniCUDD

@testset "README BDD Example" begin
    mgr = BDDManager(nvars=4)
    v0 = var(mgr, 0)
    v1 = var(mgr, 1)
    f = bdd_and(v0, v1)
    @test dag_size(f) >= 1
    @test minterms(f, 2) == 1.0  # x & y over 2 vars has 1/4 of minterms → scaled count 1.0
    quit(mgr)
end

@testset "README ZDD Example" begin
    mgr = ZDDManager(nvars=4)
    z0 = var(mgr, 0)
    z1 = var(mgr, 1)
    f = zdd_union(z0, z1)
    @test dag_size(f) >= 1
    @test zdd_count(f) == 2.0
    quit(mgr)
end

@testset "README Operators - BDD" begin
    mgr = BDDManager(nvars=3)
    x = var(mgr, 0)
    y = var(mgr, 1)
    z = var(mgr, 2)

    f_and = x & y
    f_or  = x | y
    f_xor = x ⊻ y
    f_not = !x
    @test minterms(f_and, 3) == 2.0  # x&y true on 1/4 of 8 minterms → 2
    @test minterms(f_or, 3)  == 6.0  # x|y true on 3/4 of 8 → 6
    @test minterms(f_xor, 3) == 4.0  # xor true on 1/2 of 8 → 4
    @test minterms(bdd_and(f_not, x), 3) == 0.0

    f = (x & y) | (!x & z)
    # Evaluate expected count: cases where x=1 & y=1 (z free) or x=0 & z=1 (y free)
    # First part: 2 assignments for z → 2; Second part: 2 assignments for y → 2; total 4
    @test minterms(f, 3) == 4.0
    quit(mgr)
end

@testset "README Operators - ZDD" begin
    zm = ZDDManager(nvars=4)
    a = var(zm, 0)
    b = var(zm, 1)
    c = var(zm, 2)

    u1 = union(a, b)
    u2 = a + c
    i1 = intersect(u1, u2)
    d1 = setdiff(u1, a)
    @test zdd_count(u1) == 2.0
    @test zdd_count(u2) == 2.0
    @test zdd_count(i1) == 1.0
    @test zdd_count(d1) == 1.0

    u3 = MiniCUDD.∪(a, b)
    i2 = MiniCUDD.∩(u3, c)
    @test zdd_count(i2) == 0.0
    quit(zm)
end
