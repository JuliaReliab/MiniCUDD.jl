using Test
using MiniCUDD

function prob(f::BDDNode, probs::Vector{Float64})
    length(probs) >= nvars(f.m) || error("prob vector shorter than number of variables")
    one_id  = node_id(const1(f.m))
    zero_id = node_id(const0(f.m))
    memo = Dict{UInt,Float64}()
    function rec(n::BDDNode)::Float64
        nid = node_id(n)
        if haskey(memo, nid)
            return memo[nid]
        end
        if nid == one_id
            memo[nid] = 1.0; return 1.0
        elseif nid == zero_id
            memo[nid] = 0.0; return 0.0
        end
        idx = node_index(n)            # 0-based
        p = probs[idx + 1]
        tv = rec(then_node(n))
        ev = rec(else_node(n))
        val = p * tv + (1 - p) * ev
        memo[nid] = val
        return val
    end
    return rec(f)
end

@testset "README probability algorithm" begin
    mgr = BDDManager(nvars=3)
    x = var(mgr, 0)
    y = var(mgr, 1)
    z = var(mgr, 2)
    f = (x & y) | (!x & z)

    # Manual probability: enumerate minterms (8 total)
    # f true when (x=1,y=1) regardless z -> 2 minterms
    # or (x=0,z=1) regardless y -> 2 minterms; total 4/8 = 0.5 when p=0.5
    @test isapprox(prob(f, [0.5,0.5,0.5]), 0.5, atol=1e-12)

    # For p=0.3: prob(x=1)=0.3, prob(x=0)=0.7
    # Probability part1: x=1,y=1 occurs with p^2=0.09 (z free)
    # part2: x=0,z=1 occurs with (1-p)*p=0.21 (y free)
    # Total = 0.09 + 0.21 = 0.30
    @test isapprox(prob(f, [0.3,0.3,0.3]), 0.30, atol=1e-12)
    @test isapprox(prob(f, [0.2,0.8,0.6]), 0.64, atol=1e-12)  # p0*p1 + (1-p0)*p2
    quit(mgr)
end
