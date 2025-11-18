using MiniCUDD
using Test

@testset "Unified var function" begin
    # Test that var() works with both manager types
    bdd_mgr = BDDManager(nvars=2)
    zdd_mgr = ZDDManager(nvars=2)
    
    # var() should return BDDNode with BDDManager
    bdd_node = var(bdd_mgr, 0)
    @test isa(bdd_node, BDDNode)
    
    # var() should return ZDDNode with ZDDManager
    zdd_node = var(zdd_mgr, 0)
    @test isa(zdd_node, ZDDNode)
    
    quit(bdd_mgr)
    quit(zdd_mgr)
end

@testset "Unified dag_size function" begin
    # dag_size() should work with both node types
    bdd_mgr = BDDManager(nvars=2)
    zdd_mgr = ZDDManager(nvars=2)
    
    bdd_node = var(bdd_mgr, 0)
    zdd_node = var(zdd_mgr, 0)
    
    # Both should return valid DAG sizes
    @test dag_size(bdd_node) > 0
    @test dag_size(zdd_node) > 0
    
    quit(bdd_mgr)
    quit(zdd_mgr)
end

@testset "Unified node_index function" begin
    # node_index() should work with both node types
    bdd_mgr = BDDManager(nvars=3)
    zdd_mgr = ZDDManager(nvars=3)
    
    bdd_node = var(bdd_mgr, 1)
    zdd_node = var(zdd_mgr, 2)
    
    # Both should return valid indices
    @test node_index(bdd_node) >= 0
    @test node_index(zdd_node) >= 0
    
    quit(bdd_mgr)
    quit(zdd_mgr)
end

@testset "Unified isconstant function" begin
    # isconstant() should work with both node types
    bdd_mgr = BDDManager(nvars=2)
    zdd_mgr = ZDDManager(nvars=2)
    
    # Regular nodes should not be constant
    @test !isconstant(var(bdd_mgr, 0))
    @test !isconstant(var(zdd_mgr, 0))
    
    # Constant nodes should be constant
    @test isconstant(const1(bdd_mgr))
    @test isconstant(const0(bdd_mgr))
    @test isconstant(zdd_base(zdd_mgr))
    @test isconstant(zdd_empty(zdd_mgr))
    
    quit(bdd_mgr)
    quit(zdd_mgr)
end

@testset "Unified then_ptr and else_ptr functions" begin
    # then_ptr() and else_ptr() should work with both node types
    bdd_mgr = BDDManager(nvars=2)
    zdd_mgr = ZDDManager(nvars=2)
    
    bdd_x = var(bdd_mgr, 0)
    bdd_y = var(bdd_mgr, 1)
    bdd_f = bdd_and(bdd_x, bdd_y)
    
    zdd_x = var(zdd_mgr, 0)
    zdd_y = var(zdd_mgr, 1)
    zdd_s = zdd_union(zdd_x, zdd_y)
    
    # Both should return valid pointers
    @test then_ptr(bdd_f) != C_NULL
    @test else_ptr(bdd_f) != C_NULL
    @test then_ptr(zdd_s) != C_NULL
    @test else_ptr(zdd_s) != C_NULL
    
    quit(bdd_mgr)
    quit(zdd_mgr)
end

@testset "Unified then_node and else_node functions" begin
    # then_node() and else_node() should work with both manager types
    bdd_mgr = BDDManager(nvars=2)
    zdd_mgr = ZDDManager(nvars=2)
    
    bdd_x = var(bdd_mgr, 0)
    bdd_y = var(bdd_mgr, 1)
    bdd_f = bdd_and(bdd_x, bdd_y)
    
    zdd_x = var(zdd_mgr, 0)
    zdd_y = var(zdd_mgr, 1)
    zdd_s = zdd_union(zdd_x, zdd_y)
    
    # Should return correct node types (no manager argument needed)
    @test isa(then_node(bdd_f), BDDNode)
    @test isa(else_node(bdd_f), BDDNode)
    @test isa(then_node(zdd_s), ZDDNode)
    @test isa(else_node(zdd_s), ZDDNode)
    
    quit(bdd_mgr)
    quit(zdd_mgr)
end

@testset "Type safety - different managers" begin
    # Ensure that mixing manager types is caught
    bdd_mgr = BDDManager(nvars=2)
    zdd_mgr = ZDDManager(nvars=2)
    
    bdd_node = var(bdd_mgr, 0)
    zdd_node = var(zdd_mgr, 0)
    
    # These should work - nodes contain their managers
    @test isa(then_node(bdd_node), BDDNode)
    @test isa(then_node(zdd_node), ZDDNode)
    
    quit(bdd_mgr)
    quit(zdd_mgr)
end

@testset "Multiple dispatch consistency" begin
    # Verify that the same function names work correctly with different types
    bdd_mgr = BDDManager(nvars=3)
    zdd_mgr = ZDDManager(nvars=3)
    
    # Create variables using the same function name
    bdd_vars = [var(bdd_mgr, i) for i in 0:2]
    zdd_vars = [var(zdd_mgr, i) for i in 0:2]
    
    # Verify all nodes are created correctly
    @test all(isa(n, BDDNode) for n in bdd_vars)
    @test all(isa(n, ZDDNode) for n in zdd_vars)
    
    # Verify utility functions work on all nodes
    @test all(dag_size(n) > 0 for n in bdd_vars)
    @test all(dag_size(n) > 0 for n in zdd_vars)
    @test all(!isconstant(n) for n in bdd_vars)
    @test all(!isconstant(n) for n in zdd_vars)
    
    quit(bdd_mgr)
    quit(zdd_mgr)
end
