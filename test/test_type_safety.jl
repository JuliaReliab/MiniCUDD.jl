using MiniCUDD
using Test

@testset "Type safety" begin

@testset "BDD operations without manager argument" begin
    bdd_mgr = BDDManager(nvars=3)
    x = var(bdd_mgr, 0)
    y = var(bdd_mgr, 1)
    z = var(bdd_mgr, 2)
    
    # Boolean operations - manager not needed!
    f = bdd_and(x, y)
    g = bdd_or(f, z)
    
    @test dag_size(g) > 0
    @test minterms(g, 3) > 0
    
    quit(bdd_mgr)
end

@testset "ZDD operations without manager argument" begin
    zdd_mgr = ZDDManager(nvars=3)
    a = var(zdd_mgr, 0)
    b = var(zdd_mgr, 1)
    c = var(zdd_mgr, 2)
    
    # Set operations - manager not needed!
    s1 = zdd_union(a, b)
    s2 = zdd_union(s1, c)
    
    @test dag_size(s2) > 0
    @test zdd_count(s2) > 0
    
    quit(zdd_mgr)
end

@testset "Type distinction between BDD and ZDD" begin
    # This demonstrates the type system prevents mixing BDD and ZDD operations
    bdd_mgr = BDDManager(nvars=2)
    zdd_mgr = ZDDManager(nvars=2)
    
    bdd_node = var(bdd_mgr, 0)
    zdd_node = var(zdd_mgr, 0)
    
    # Verify correct types
    @test isa(bdd_node, BDDNode)
    @test isa(zdd_node, ZDDNode)
    @test isa(bdd_mgr, BDDManager)
    @test isa(zdd_mgr, ZDDManager)
    @test !isa(bdd_node, ZDDNode)
    @test !isa(zdd_node, BDDNode)
    
    quit(bdd_mgr)
    quit(zdd_mgr)
end

end # Type safety
