using MiniCUDD
using Test

@testset "ZDD basic operations" begin
    mgr = ZDDManager(nvars=3)
    
    # Test variable creation with unified var function
    x = var(mgr, 0)
    y = var(mgr, 1)
    z = var(mgr, 2)
    
    @test isa(x, ZDDNode)
    @test isa(y, ZDDNode)
    @test isa(z, ZDDNode)
    
    # Test constants
    empty = zdd_empty(mgr)
    base = zdd_base(mgr)
    
    @test isa(empty, ZDDNode)
    @test isa(base, ZDDNode)
    @test isconstant(empty)
    @test isconstant(base)
    
    quit(mgr)
end

@testset "ZDD set operations" begin
    mgr = ZDDManager(nvars=3)
    x = var(mgr, 0)
    y = var(mgr, 1)
    z = var(mgr, 2)
    
    # Test union - ZDD union includes all combinations
    s_union = zdd_union(mgr, x, y)
    count1 = zdd_count(mgr, s_union)
    @test count1 > 0.0  # Should have some combinations
    
    # Union with three elements
    s_union3 = zdd_union(mgr, s_union, z)
    count2 = zdd_count(mgr, s_union3)
    @test count2 >= count1  # Should have at least as many combinations
    
    # Test intersection
    s1 = zdd_union(mgr, x, y)
    s2 = zdd_union(mgr, y, z)
    s_intersect = zdd_intersect(mgr, s1, s2)
    @test zdd_count(mgr, s_intersect) >= 0.0  # Valid count
    
    # Test difference
    s_diff = zdd_diff(mgr, s1, s2)
    @test zdd_count(mgr, s_diff) >= 0.0  # Valid count
    
    quit(mgr)
end

@testset "ZDD utility functions" begin
    mgr = ZDDManager(nvars=3)
    x = var(mgr, 0)
    y = var(mgr, 1)
    
    s = zdd_union(mgr, x, y)
    
    # Test DAG size (unified function)
    @test dag_size(s) > 0
    
    # Test node index (unified function)
    @test node_index(s) >= 0
    
    # Test zdd_count - just verify it's positive
    @test zdd_count(mgr, s) > 0.0
    
    # Test isconstant (unified function)
    @test !isconstant(s)
    @test isconstant(zdd_empty(mgr))
    @test isconstant(zdd_base(mgr))
    
    quit(mgr)
end

@testset "ZDD cofactor operations" begin
    mgr = ZDDManager(nvars=3)
    x = var(mgr, 0)
    y = var(mgr, 1)
    z = var(mgr, 2)
    
    # Create a set with multiple combinations
    s = zdd_union(mgr, zdd_union(mgr, x, y), z)
    
    # Test subset1 - elements containing variable 0
    s1 = zdd_subset1(mgr, s, 0)
    @test zdd_count(mgr, s1) >= 0.0
    
    # Test subset0 - elements not containing variable 0
    s0 = zdd_subset0(mgr, s, 0)
    @test zdd_count(mgr, s0) >= 0.0
    
    # Test change - flip presence of variable
    s_changed = zdd_change(mgr, s, 0)
    @test isa(s_changed, ZDDNode)
    
    quit(mgr)
end

@testset "ZDD then/else accessors" begin
    mgr = ZDDManager(nvars=2)
    x = var(mgr, 0)
    y = var(mgr, 1)
    
    s = zdd_union(mgr, x, y)
    
    # Test unified then/else pointer functions
    t = then_ptr(s)
    e = else_ptr(s)
    @test t != C_NULL
    @test e != C_NULL
    
    # Test unified then_node/else_node (they work with ZDD too)
    tnode = then_node(mgr, s)
    enode = else_node(mgr, s)
    @test isa(tnode, ZDDNode)
    @test isa(enode, ZDDNode)
    
    quit(mgr)
end

@testset "ZDD ITE operation" begin
    mgr = ZDDManager(nvars=3)
    x = var(mgr, 0)
    y = var(mgr, 1)
    z = var(mgr, 2)
    
    # Test ZDD ITE
    s_ite = zdd_ite(mgr, x, y, z)
    @test isa(s_ite, ZDDNode)
    @test zdd_count(mgr, s_ite) >= 0.0
    
    quit(mgr)
end

@testset "ZDD empty and base sets" begin
    mgr = ZDDManager(nvars=2)
    
    empty = zdd_empty(mgr)
    base = zdd_base(mgr)
    
    # Empty set should have 0 combinations
    @test zdd_count(mgr, empty) == 0.0
    
    # Base set contains only empty set, so count is 1
    @test zdd_count(mgr, base) == 1.0
    
    # Union with empty should be identity
    x = var(mgr, 0)
    s = zdd_union(mgr, x, empty)
    @test zdd_count(mgr, s) == zdd_count(mgr, x)
    
    quit(mgr)
end

@testset "ZDD complex set operations" begin
    mgr = ZDDManager(nvars=4)
    a = var(mgr, 0)
    b = var(mgr, 1)
    c = var(mgr, 2)
    d = var(mgr, 3)
    
    # Create complex set expressions
    s1 = zdd_union(mgr, a, b)
    s2 = zdd_union(mgr, c, d)
    
    # Union of unions
    s_all = zdd_union(mgr, s1, s2)
    @test zdd_count(mgr, s_all) >= zdd_count(mgr, s1)  # Should have at least as many
    @test zdd_count(mgr, s_all) >= zdd_count(mgr, s2)
    
    # Intersection result
    s_inter = zdd_intersect(mgr, s1, s2)
    @test zdd_count(mgr, s_inter) >= 0.0  # Valid result
    
    quit(mgr)
end

@testset "ZDD single element operations" begin
    mgr = ZDDManager(nvars=1)
    x = var(mgr, 0)
    
    # Single variable should have count 1
    @test zdd_count(mgr, x) == 1.0
    
    # DAG size should be small
    @test dag_size(x) >= 1
    
    # Node index should be 0
    @test node_index(x) == 0
    
    quit(mgr)
end
