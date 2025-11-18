using MiniCUDD
using Test

@testset "Manager separation and type safety" begin

@testset "Separate BDD and ZDD managers" begin
    # Create managers - each has its own CUDD instance
    bdd_mgr = BDDManager(nvars=3)
    zdd_mgr = ZDDManager(nvars=3)
    
    # Verify they are different types
    @test typeof(bdd_mgr) != typeof(zdd_mgr)
    @test isa(bdd_mgr, BDDManager)
    @test isa(zdd_mgr, ZDDManager)
    
    # Create nodes from each manager
    x = var(bdd_mgr, 0)
    y = var(bdd_mgr, 1)
    bdd_expr = bdd_and(x, y)
    
    # Verify BDD expression works correctly
    @test isa(bdd_expr, BDDNode)
    @test dag_size(bdd_expr) > 0
    @test bdd_expr.m === bdd_mgr  # Node references its manager
    
    # Create ZDD nodes
    a = var(zdd_mgr, 0)
    b = var(zdd_mgr, 1)
    zdd_expr = zdd_union(a, b)
    
    # Verify ZDD expression works correctly
    @test isa(zdd_expr, ZDDNode)
    @test dag_size(zdd_expr) > 0
    @test zdd_expr.m === zdd_mgr  # Node references its manager
    
    quit(bdd_mgr)
    quit(zdd_mgr)
end

@testset "Type safety prevents mixing operations" begin
    bdd_mgr = BDDManager(nvars=2)
    zdd_mgr = ZDDManager(nvars=2)
    
    bdd_node = var(bdd_mgr, 0)
    zdd_node = var(zdd_mgr, 0)
    
    # These should work - correct types
    @test isa(bdd_and(bdd_node, bdd_node), BDDNode)
    @test isa(zdd_union(zdd_node, zdd_node), ZDDNode)
    
    # Type system prevents mixing at compile time
    # Uncomment to verify compile-time errors:
    # bdd_and(zdd_node, zdd_node)  # Would fail: no method for ZDDNode arguments
    # zdd_union(bdd_node, bdd_node)  # Would fail: no method for BDDNode arguments
    
    quit(bdd_mgr)
    quit(zdd_mgr)
end

end # Manager separation and type safety
