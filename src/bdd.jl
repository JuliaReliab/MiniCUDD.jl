# BDD operations and node management

function _wrap_node(m::BDDManager, p::Ptr{DdNode}; ref::Bool=true, manage::Bool=true)
    p == C_NULL && error("CUDD returned NULL node")
    if ref
        ccall((:Cudd_Ref, libcudd), Cvoid, (Ptr{DdNode},), p)
    end
    n = BDDNode(m, p, manage)
    if manage
        finalizer(n) do nn
            if nn.alive && nn.ptr != C_NULL && nn.m.alive
                ccall((:Cudd_RecursiveDeref, libcudd), Cvoid,
                      (Ptr{DdManager}, Ptr{DdNode}), nn.m.ptr, nn.ptr)
                nn.alive = false
                nn.ptr = C_NULL
            end
        end
    end
    return n
end

"""close!(node)

Explicitly release the CUDD reference held by `node`. After calling
`close!` the node becomes invalid and should not be used.
"""
function close!(n::BDDNode)
    if n.alive && n.ptr != C_NULL && n.m.alive
        ccall((:Cudd_RecursiveDeref, libcudd), Cvoid,
              (Ptr{DdManager}, Ptr{DdNode}), n.m.ptr, n.ptr)
    end
    n.alive = false
    n.ptr = C_NULL
    nothing
end

"""var(mgr, i)

Return the BDD variable `i` from the manager `mgr` as a `BDDNode`.
"""
function var(m::BDDManager, i::Integer)::BDDNode
    p = ccall((:Cudd_bddIthVar, libcudd), Ptr{DdNode}, (Ptr{DdManager}, Cint), m.ptr, i)
    return _wrap_node(m, p)
end

"""const1(mgr; take_ref=false)

Return the logical constant 1 node for the manager `mgr`.
If `take_ref=true` the wrapper will take an additional reference and manage
the node; otherwise a non-managed thin wrapper is returned.
"""
function const1(m::BDDManager; take_ref::Bool=false)::BDDNode
    p = ccall((:Cudd_ReadOne, libcudd), Ptr{DdNode}, (Ptr{DdManager},), m.ptr)
    return take_ref ? _wrap_node(m, p; ref=true,  manage=true) :
                      _wrap_node(m, p; ref=false, manage=false)
end

"""const0(mgr; take_ref=false)

Return the logical constant 0 node for the manager `mgr`.
If `take_ref=true` the wrapper will take an additional reference and manage
the node; otherwise a non-managed thin wrapper is returned.
"""
function const0(m::BDDManager; take_ref::Bool=false)::BDDNode
    p = ccall((:Cudd_ReadLogicZero, libcudd), Ptr{DdNode}, (Ptr{DdManager},), m.ptr)
    return take_ref ? _wrap_node(m, p; ref=true,  manage=true) :
                      _wrap_node(m, p; ref=false, manage=false)
end

"""bdd_and(a, b)

Return the BDD representing logical AND of `a` and `b`.
"""
function bdd_and(a::BDDNode, b::BDDNode)::BDDNode
    m = a.m
    p = ccall((:Cudd_bddAnd, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, a.ptr, b.ptr)
    return _wrap_node(m, p)
end

"""bdd_or(a, b)

Return the BDD representing logical OR of `a` and `b`.
"""
function bdd_or(a::BDDNode, b::BDDNode)::BDDNode
    m = a.m
    p = ccall((:Cudd_bddOr, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, a.ptr, b.ptr)
    return _wrap_node(m, p)
end

"""bdd_xor(a, b)

Return the BDD representing logical XOR of `a` and `b`.
"""
function bdd_xor(a::BDDNode, b::BDDNode)::BDDNode
    m = a.m
    p = ccall((:Cudd_bddXor, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, a.ptr, b.ptr)
    return _wrap_node(m, p)
end

"""bdd_implies(a, b)

Return the BDD representing logical implication `a => b`.
"""
function bdd_implies(a::BDDNode, b::BDDNode)::BDDNode
    m = a.m
    onep = ccall((:Cudd_ReadOne, libcudd), Ptr{DdNode}, (Ptr{DdManager},), m.ptr)
    p = ccall((:Cudd_bddIte, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, a.ptr, b.ptr, onep)
    return _wrap_node(m, p)
end

"""bdd_ite(i, t, e)

Return the if-then-else BDD: `i ? t : e`.
"""
function bdd_ite(i::BDDNode, t::BDDNode, e::BDDNode)::BDDNode
    m = i.m
    p = ccall((:Cudd_bddIte, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, i.ptr, t.ptr, e.ptr)
    return _wrap_node(m, p)
end

"""minterms(x, nvars)

Return the number of minterms (as a floating-point value) of `x` assuming
`nvars` variables. This is a wrapper around `Cudd_CountMinterm`.
"""
minterms(x::BDDNode, nvars::Integer)::Float64 =
    ccall((:Cudd_CountMinterm, libcudd), Cdouble,
          (Ptr{DdManager}, Ptr{DdNode}, Cint), x.m.ptr, x.ptr, nvars)
