# ZDD (Zero-suppressed Binary Decision Diagram) operations and node management

function _wrap_zdd_node(m::ZDDManager, p::Ptr{DdNode}; ref::Bool=true, manage::Bool=true)
    p == C_NULL && error("CUDD returned NULL ZDD node")
    if ref
        ccall((:Cudd_Ref, libcudd), Cvoid, (Ptr{DdNode},), p)
    end
    n = ZDDNode(m, p, manage)
    if manage
        finalizer(n) do nn
            if nn.alive && nn.ptr != C_NULL && nn.m.alive
                ccall((:Cudd_RecursiveDerefZdd, libcudd), Cvoid,
                      (Ptr{DdManager}, Ptr{DdNode}), nn.m.ptr, nn.ptr)
                nn.alive = false
                nn.ptr = C_NULL
            end
        end
    end
    return n
end

"""close!(node::ZDDNode)

Explicitly release the CUDD reference held by the ZDD `node`. After calling
`close!` the node becomes invalid and should not be used.
"""
function close!(n::ZDDNode)
    if n.alive && n.ptr != C_NULL && n.m.alive
        ccall((:Cudd_RecursiveDerefZdd, libcudd), Cvoid,
              (Ptr{DdManager}, Ptr{DdNode}), n.m.ptr, n.ptr)
    end
    n.alive = false
    n.ptr = C_NULL
    nothing
end

"""var(mgr::ZDDManager, i)

Return the ZDD variable `i` from the manager `mgr` as a `ZDDNode`.
This creates a ZDD representing the set containing only the singleton set {i}.
"""
function var(m::ZDDManager, i::Integer)::ZDDNode
    p = ccall((:Cudd_zddIthVar, libcudd), Ptr{DdNode}, (Ptr{DdManager}, Cint), m.ptr, i)
    return _wrap_zdd_node(m, p)
end

"""zdd_empty(mgr; take_ref=false)

Return the empty set ZDD (terminal 0) for the manager `mgr`.
If `take_ref=true` the wrapper will take an additional reference and manage
the node; otherwise a non-managed thin wrapper is returned.
"""
function zdd_empty(m::ZDDManager; take_ref::Bool=false)::ZDDNode
    p = ccall((:Cudd_ReadZero, libcudd), Ptr{DdNode}, (Ptr{DdManager},), m.ptr)
    return take_ref ? _wrap_zdd_node(m, p; ref=true,  manage=true) :
                      _wrap_zdd_node(m, p; ref=false, manage=false)
end

"""zdd_base(mgr; take_ref=false)

Return the base set ZDD (terminal 1) for the manager `mgr`.
This represents the set containing only the empty set {∅}.
If `take_ref=true` the wrapper will take an additional reference and manage
the node; otherwise a non-managed thin wrapper is returned.
"""
function zdd_base(m::ZDDManager; take_ref::Bool=false)::ZDDNode
    p = ccall((:Cudd_ReadOne, libcudd), Ptr{DdNode}, (Ptr{DdManager},), m.ptr)
    return take_ref ? _wrap_zdd_node(m, p; ref=true,  manage=true) :
                      _wrap_zdd_node(m, p; ref=false, manage=false)
end

"""zdd_union(a, b)
zdd_union(mgr, a, b)

Return the ZDD representing the union of sets `a` and `b`.
If manager is not provided, it is taken from the first node.
"""
function zdd_union(a::ZDDNode, b::ZDDNode)::ZDDNode
    m = a.m
    p = ccall((:Cudd_zddUnion, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, a.ptr, b.ptr)
    return _wrap_zdd_node(m, p)
end
zdd_union(m::ZDDManager, a::ZDDNode, b::ZDDNode)::ZDDNode = zdd_union(a, b)

"""zdd_intersect(a, b)
zdd_intersect(mgr, a, b)

Return the ZDD representing the intersection of sets `a` and `b`.
If manager is not provided, it is taken from the first node.
"""
function zdd_intersect(a::ZDDNode, b::ZDDNode)::ZDDNode
    m = a.m
    p = ccall((:Cudd_zddIntersect, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, a.ptr, b.ptr)
    return _wrap_zdd_node(m, p)
end
zdd_intersect(m::ZDDManager, a::ZDDNode, b::ZDDNode)::ZDDNode = zdd_intersect(a, b)

"""zdd_diff(a, b)
zdd_diff(mgr, a, b)

Return the ZDD representing the set difference `a - b` (elements in `a` but not in `b`).
If manager is not provided, it is taken from the first node.
"""
function zdd_diff(a::ZDDNode, b::ZDDNode)::ZDDNode
    m = a.m
    p = ccall((:Cudd_zddDiff, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, a.ptr, b.ptr)
    return _wrap_zdd_node(m, p)
end
zdd_diff(m::ZDDManager, a::ZDDNode, b::ZDDNode)::ZDDNode = zdd_diff(a, b)

"""zdd_subset1(a, i)
zdd_subset1(mgr, a, i)

Return the ZDD representing the subset of `a` containing element `i`.
This is the cofactor operation: elements that must include variable i.
If manager is not provided, it is taken from the node.
"""
function zdd_subset1(a::ZDDNode, i::Integer)::ZDDNode
    m = a.m
    p = ccall((:Cudd_zddSubset1, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Cint),
              m.ptr, a.ptr, i)
    return _wrap_zdd_node(m, p)
end
zdd_subset1(m::ZDDManager, a::ZDDNode, i::Integer)::ZDDNode = zdd_subset1(a, i)

"""zdd_subset0(a, i)
zdd_subset0(mgr, a, i)

Return the ZDD representing the subset of `a` not containing element `i`.
This is the cofactor operation: elements that must not include variable i.
If manager is not provided, it is taken from the node.
"""
function zdd_subset0(a::ZDDNode, i::Integer)::ZDDNode
    m = a.m
    p = ccall((:Cudd_zddSubset0, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Cint),
              m.ptr, a.ptr, i)
    return _wrap_zdd_node(m, p)
end
zdd_subset0(m::ZDDManager, a::ZDDNode, i::Integer)::ZDDNode = zdd_subset0(a, i)

"""zdd_change(a, i)
zdd_change(mgr, a, i)

Return the ZDD obtained by changing the presence of element `i` in all sets of `a`.
Sets containing `i` will not contain it, and sets not containing `i` will contain it.
If manager is not provided, it is taken from the node.
"""
function zdd_change(a::ZDDNode, i::Integer)::ZDDNode
    m = a.m
    p = ccall((:Cudd_zddChange, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Cint),
              m.ptr, a.ptr, i)
    return _wrap_zdd_node(m, p)
end
zdd_change(m::ZDDManager, a::ZDDNode, i::Integer)::ZDDNode = zdd_change(a, i)

"""zdd_ite(i, t, e)
zdd_ite(mgr, i, t, e)

Return the ZDD if-then-else: if `i` then `t` else `e`.
If manager is not provided, it is taken from the first node.
"""
function zdd_ite(i::ZDDNode, t::ZDDNode, e::ZDDNode)::ZDDNode
    m = i.m
    p = ccall((:Cudd_zddIte, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, i.ptr, t.ptr, e.ptr)
    return _wrap_zdd_node(m, p)
end
zdd_ite(m::ZDDManager, i::ZDDNode, t::ZDDNode, e::ZDDNode)::ZDDNode = zdd_ite(i, t, e)



"""zdd_count(z)
zdd_count(mgr, z)

Return the number of sets (combinations) in the ZDD `z` as a floating-point value.
If manager is not provided, it is taken from the node.
"""
zdd_count(z::ZDDNode)::Float64 =
    ccall((:Cudd_zddCountDouble, libcudd), Cdouble,
          (Ptr{DdManager}, Ptr{DdNode}), z.m.ptr, z.ptr)
zdd_count(m::ZDDManager, z::ZDDNode)::Float64 = zdd_count(z)



"""bdd_to_zdd(zdd_mgr, bdd_node)

Convert a BDD node to a ZDD node. The BDD must represent a cube (conjunction of literals).
Note: Both managers must wrap the same underlying CUDD manager pointer.
"""
function bdd_to_zdd(zm::ZDDManager, b::BDDNode)::ZDDNode
    # Verify same underlying manager
    b.m.ptr == zm.ptr || error("BDD and ZDD managers must share the same CUDD manager")
    p = ccall((:Cudd_zddPortFromBdd, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}),
              zm.ptr, b.ptr)
    return _wrap_zdd_node(zm, p)
end

"""zdd_to_bdd(bdd_mgr, zdd_node)

Convert a ZDD node to a BDD node.
Note: Both managers must wrap the same underlying CUDD manager pointer.
"""
function zdd_to_bdd(bm::BDDManager, z::ZDDNode)::BDDNode
    # Verify same underlying manager
    z.m.ptr == bm.ptr || error("ZDD and BDD managers must share the same CUDD manager")
    p = ccall((:Cudd_zddPortToBdd, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}),
              bm.ptr, z.ptr)
    return _wrap_node(bm, p)
end
