using Test
using MiniCUDD

@testset "DOT export for BDD" begin
    mgr = BDDManager(nvars=3)
    
    # Simple BDD: x0 AND x1
    v0 = var(mgr, 0)
    v1 = var(mgr, 1)
    f = bdd_and(v0, v1)
    
    dot_str = to_dot(f)
    
    # Check that DOT string contains expected elements
    @test occursin("digraph", dot_str)
    @test occursin("rankdir=TB", dot_str)
    @test occursin("shape=circle", dot_str)
    @test occursin("shape=square", dot_str)
    @test occursin("style=solid", dot_str)
    @test occursin("style=dashed", dot_str)
    
    # Test with custom title
    dot_str2 = to_dot(f, title="Test BDD")
    @test occursin("\"Test BDD\"", dot_str2)
    
    quit(mgr)
end

@testset "DOT export label conflict checks" begin
    # BDD: varlabels must not contain T/F
    mgr = BDDManager(nvars=2)
    v0 = var(mgr, 0)
    v1 = var(mgr, 1)
    f = bdd_and(v0, v1)
    @test_throws ArgumentError to_dot(f, varlabels=["T", "y"])  # contains reserved T
    @test_throws ArgumentError to_dot(f, varlabels=["x", "F"])  # contains reserved F
    quit(mgr)

    # ZDD: varlabels must not contain ∅/B
    zm = ZDDManager(nvars=2)
    z0 = var(zm, 0)
    z1 = var(zm, 1)
    g = zdd_union(z0, z1)
    @test_throws ArgumentError to_dot(g, varlabels=["∅", "a"])  # contains reserved ∅
    @test_throws ArgumentError to_dot(g, varlabels=["B", "a"])   # contains reserved B
    quit(zm)
end

@testset "DOT export for ZDD" begin
    mgr = ZDDManager(nvars=3)
    
    # Simple ZDD: {0} ∪ {1}
    z0 = var(mgr, 0)
    z1 = var(mgr, 1)
    f = zdd_union(z0, z1)
    
    dot_str = to_dot(f)
    
    # Check that DOT string contains expected elements
    @test occursin("digraph", dot_str)
    @test occursin("rankdir=TB", dot_str)
    @test occursin("shape=circle", dot_str)
    @test occursin("shape=square", dot_str)
    @test occursin("style=solid", dot_str)
    @test occursin("style=dashed", dot_str)
    
    # Test with custom title
    dot_str2 = to_dot(f, title="Test ZDD")
    @test occursin("\"Test ZDD\"", dot_str2)
    
    quit(mgr)
end

@testset "DOT export to IO" begin
    mgr = BDDManager(nvars=2)
    v0 = var(mgr, 0)
    v1 = var(mgr, 1)
    f = bdd_or(v0, v1)
    
    # Test writing to IOBuffer
    io = IOBuffer()
    to_dot(io, f, title="IO Test")
    dot_str = String(take!(io))
    
    @test occursin("digraph \"IO Test\"", dot_str)
    @test occursin("->", dot_str)
    
    quit(mgr)
end

@testset "DOT export for constant nodes" begin
    mgr = BDDManager(nvars=2)
    
    # Test constant 1
    c1 = const1(mgr)
    dot_str = to_dot(c1, title="Constant 1")
    @test occursin("digraph", dot_str)
    @test occursin("shape=square", dot_str)
    
    # Test constant 0
    c0 = const0(mgr)
    dot_str = to_dot(c0, title="Constant 0")
    @test occursin("digraph", dot_str)
    @test occursin("shape=square", dot_str)
    
    quit(mgr)
end

@testset "DOT export for complex BDD" begin
    mgr = BDDManager(nvars=4)
    
    # Create a more complex expression: (x0 ∧ x1) ∨ (x2 ∧ x3)
    v0 = var(mgr, 0)
    v1 = var(mgr, 1)
    v2 = var(mgr, 2)
    v3 = var(mgr, 3)
    
    left = bdd_and(v0, v1)
    right = bdd_and(v2, v3)
    f = bdd_or(left, right)
    
    dot_str = to_dot(f, title="Complex BDD")
    
    # Should have multiple variable nodes (without 'x' prefix)
    @test occursin("label=\"0\"", dot_str) || occursin("label=\"1\"", dot_str) || 
          occursin("label=\"2\"", dot_str) || occursin("label=\"3\"", dot_str)
    @test occursin("->", dot_str)
    
    quit(mgr)
end
