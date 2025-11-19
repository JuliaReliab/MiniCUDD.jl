using Test
using MiniCUDD

@testset "node_level BDD" begin
    bm = BDDManager(nvars=4)
    v0 = var(bm, 0)
    v1 = var(bm, 1)
    v3 = var(bm, 3)
    @test node_index(v0) == 0
    @test node_index(v1) == 1
    @test node_index(v3) == 3
    # Initial ordering is identity: level == index
    @test node_level(v0) == 0
    @test node_level(v1) == 1
    @test node_level(v3) == 3
    c1 = const1(bm)
    c0 = const0(bm)
    @test node_level(c1) == -1
    @test node_level(c0) == -1
    quit(bm)
end

@testset "node_level ZDD" begin
    zm = ZDDManager(nvars=5)
    base = zdd_base(zm)
    z0 = zdd_change(base, 0)  # singleton {0}
    z2 = zdd_change(base, 2)  # singleton {2}
    z4 = zdd_change(base, 4)  # singleton {4}
    @test node_index(z0) == 0
    @test node_index(z2) == 2
    @test node_index(z4) == 4
    @test node_level(z0) == 0
    @test node_level(z2) == 2
    @test node_level(z4) == 4
    e = zdd_empty(zm)
    b = zdd_base(zm)
    @test node_level(e) == -1
    @test node_level(b) == -1
    quit(zm)
end
