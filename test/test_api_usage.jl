using MiniCUDD
using Test

@testset "API usage demonstration" begin

@testset "BDD API usage" begin
    bdd_mgr = BDDManager(nvars=3)

    # Use unified 'var' function - dispatches to BDD creation
    x = var(bdd_mgr, 0)
    y = var(bdd_mgr, 1)
    z = var(bdd_mgr, 2)

    # Operations don't need explicit manager - it's taken from nodes!
    f = bdd_and(x, bdd_or(y, z))
    
    # Verify unified utility functions work
    @test dag_size(f) > 0
    @test minterms(f, 3) > 0
    @test isconstant(f) == false
    @test node_index(f) >= 0
    
    # Verify unified child accessor functions work
    t = then_node(f)
    e = else_node(f)
    @test dag_size(t) > 0
    @test dag_size(e) > 0
    
    quit(bdd_mgr)
end

@testset "ZDD API usage" begin
    zdd_mgr = ZDDManager(nvars=3)

    # Same 'var' function - dispatches to ZDD creation
    a = var(zdd_mgr, 0)
    b = var(zdd_mgr, 1)
    c = var(zdd_mgr, 2)

    # Operations don't need explicit manager!
    s = zdd_union(a, zdd_union(b, c))
    
    # Verify same utility functions work with ZDD
    @test dag_size(s) > 0
    @test zdd_count(s) > 0
    @test isconstant(s) == false
    @test node_index(s) >= 0
    
    # Verify same child accessors work with ZDD
    t = then_node(s)
    e = else_node(s)
    @test dag_size(t) > 0
    @test dag_size(e) > 0
    
    quit(zdd_mgr)
end

end # API usage demonstration
