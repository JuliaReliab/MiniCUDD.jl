using MiniCUDD
using Test

@testset "BDD basic operations" begin
    mgr = BDDManager(nvars=3)
    
    # Test variable creation
    x = var(mgr, 0)
    y = var(mgr, 1)
    z = var(mgr, 2)
    
    @test isa(x, BDDNode)
    @test isa(y, BDDNode)
    @test isa(z, BDDNode)
    
    # Test constants
    one = const1(mgr)
    zero = const0(mgr)
    
    @test isa(one, BDDNode)
    @test isa(zero, BDDNode)
    @test isconstant(one)
    @test isconstant(zero)
    
    quit(mgr)
end

@testset "BDD boolean operations" begin
    mgr = BDDManager(nvars=3)
    x = var(mgr, 0)
    y = var(mgr, 1)
    z = var(mgr, 2)
    
    # Test AND
    f_and = bdd_and(x, y)
    @test minterms(f_and, 2) == 1.0
    
    # Test OR
    f_or = bdd_or(x, y)
    @test minterms(f_or, 2) == 3.0
    
    # Test XOR
    f_xor = bdd_xor(x, y)
    @test minterms(f_xor, 2) == 2.0
    
    # Test IMPLIES
    f_implies = bdd_implies(x, y)
    @test minterms(f_implies, 2) == 3.0
    
    # Test ITE
    f_ite = bdd_ite(x, y, z)
    @test minterms(f_ite, 3) == 4.0
    
    quit(mgr)
end

@testset "BDD utility functions" begin
    mgr = BDDManager(nvars=3)
    x = var(mgr, 0)
    y = var(mgr, 1)
    
    f = bdd_and(x, y)
    
    # Test DAG size
    @test dag_size(f) > 0
    @test dag_size(f) == 3  # x AND y has 3 nodes
    
    # Test node index
    @test node_index(f) == 0  # Root is x (index 0)
    
    # Test minterms
    @test minterms(f, 2) == 1.0
    
    # Test isconstant
    @test !isconstant(f)
    @test isconstant(const1(mgr))
    @test isconstant(const0(mgr))
    
    quit(mgr)
end

@testset "BDD then/else accessors" begin
    mgr = BDDManager(nvars=2)
    x0 = var(mgr, 0)
    x1 = var(mgr, 1)
    
    # construct x0 ∧ x1
    f_and = bdd_and(x0, x1)
    
    # Test then/else pointers
    t = then_ptr(f_and)
    e = else_ptr(f_and)
    
    # For x0 ∧ x1 the then-branch (x0=1) should be x1, else (x0=0) should be 0
    @test t == x1.ptr
    @test e == const0(mgr).ptr
    
    # Test then_node/else_node
    tnode = then_node(f_and)
    enode = else_node(f_and)
    @test minterms(tnode, 2) == 2.0  # then is x1: 2 assignments over 2 vars (2^1)
    @test minterms(enode, 2) == 0.0  # else is 0
    
    # Test with negated node
    nf = bdd_ite(f_and, const0(mgr), const1(mgr))
    
    # Complement pointer detection & inversion helper
    iscompl(p::Ptr{MiniCUDD.DdNode}) = (UInt(p) & 0x1) == 0x1
    compl(p::Ptr{MiniCUDD.DdNode})  = Ptr{MiniCUDD.DdNode}(UInt(p) ⊻ 0x1)
    
    # then should be ¬x1 and else should be 1
    @test then_ptr(nf) == compl(x1.ptr)
    @test else_ptr(nf) == const1(mgr).ptr
    
    t2 = then_node(nf)
    e2 = else_node(nf)
    @test minterms(t2, 2) == 2.0
    @test minterms(e2, 2) == 4.0  # constant 1 over 2 vars is 2^2 = 4
    
    quit(mgr)
end

@testset "BDD complex expressions" begin
    mgr = BDDManager(nvars=3)
    x = var(mgr, 0)
    y = var(mgr, 1)
    z = var(mgr, 2)
    
    # (x AND y) OR z
    # Truth table: z=1 OR (x=1 AND y=1) = 5 combinations
    # (0,0,1), (0,1,1), (1,0,1), (1,1,0), (1,1,1)
    f1 = bdd_and(x, y)
    f2 = bdd_or(f1, z)
    @test minterms(f2, 3) == 5.0
    
    # x XOR (y AND z)
    # XOR is true when exactly one operand is true
    # x=1 AND NOT(y AND z) OR x=0 AND (y AND z)
    # = 4 combinations
    f3 = bdd_and(y, z)
    f4 = bdd_xor(x, f3)
    @test minterms(f4, 3) == 4.0
    
    quit(mgr)
end
