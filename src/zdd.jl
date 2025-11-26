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

Semantics:
- Equivalent to `zdd_change(zdd_base(mgr), i)`; represents the family containing
    exactly the singleton set `{i}`.
- Returned node belongs to `mgr`.
"""
function var(m::ZDDManager, i::Integer)::ZDDNode
    base_node = zdd_base(m)
    bdd_change_node = zdd_change(base_node, i)
    return bdd_change_node
end

"""zdd_empty(mgr; take_ref=false)

Return the empty set ZDD (terminal 0) for the manager `mgr`.

Reference management:
- `take_ref=false`: returns a thin wrapper without increasing the CUDD refcount;
    finalization is disabled.
- `take_ref=true`: increases the CUDD refcount and returns a managed wrapper
    that will be dereferenced automatically.
"""
function zdd_empty(m::ZDDManager; take_ref::Bool=false)::ZDDNode
    p = ccall((:Cudd_ReadZero, libcudd), Ptr{DdNode}, (Ptr{DdManager},), m.ptr)
    return take_ref ? _wrap_zdd_node(m, p; ref=true,  manage=true) :
                      _wrap_zdd_node(m, p; ref=false, manage=false)
end

"""zdd_base(mgr; take_ref=false)

Return the base set ZDD (terminal 1) for the manager `mgr`.
This represents the family containing only the empty set `{∅}`.

Reference management:
- `take_ref=false`: returns a thin wrapper without increasing the CUDD refcount;
    finalization is disabled.
- `take_ref=true`: increases the CUDD refcount and returns a managed wrapper
    that will be dereferenced automatically.
"""
function zdd_base(m::ZDDManager; take_ref::Bool=false)::ZDDNode
    p = ccall((:Cudd_ReadOne, libcudd), Ptr{DdNode}, (Ptr{DdManager},), m.ptr)
    return take_ref ? _wrap_zdd_node(m, p; ref=true,  manage=true) :
                      _wrap_zdd_node(m, p; ref=false, manage=false)
end

"""zdd_union(a, b)

Return the ZDD representing the union of sets `a` and `b`.

Constraints:
- Inputs must share the same manager; the result belongs to that manager.
- Errors from CUDD (e.g., `NULL` nodes) propagate via `_wrap_zdd_node` as `ErrorException`.
"""
function zdd_union(a::ZDDNode, b::ZDDNode)::ZDDNode
    m = a.m
    p = ccall((:Cudd_zddUnion, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, a.ptr, b.ptr)
    return _wrap_zdd_node(m, p)
end

"""zdd_intersect(a, b)

Return the ZDD representing the intersection of sets `a` and `b`.

Constraints:
- Inputs must share the same manager; the result belongs to that manager.
- Errors from CUDD (e.g., `NULL` nodes) propagate via `_wrap_zdd_node` as `ErrorException`.
"""
function zdd_intersect(a::ZDDNode, b::ZDDNode)::ZDDNode
    m = a.m
    p = ccall((:Cudd_zddIntersect, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, a.ptr, b.ptr)
    return _wrap_zdd_node(m, p)
end

"""zdd_diff(a, b)

Return the ZDD representing the set difference `a - b` (elements in `a` but not in `b`).

Constraints:
- Inputs must share the same manager; the result belongs to that manager.
- Errors from CUDD (e.g., `NULL` nodes) propagate via `_wrap_zdd_node` as `ErrorException`.
"""
function zdd_diff(a::ZDDNode, b::ZDDNode)::ZDDNode
    m = a.m
    p = ccall((:Cudd_zddDiff, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, a.ptr, b.ptr)
    return _wrap_zdd_node(m, p)
end

"""zdd_subset1(a, i)

Return the ZDD representing the subset of `a` containing element `i`.
This is the cofactor operation: families whose sets must include variable `i`.
"""
function zdd_subset1(a::ZDDNode, i::Integer)::ZDDNode
    m = a.m
    p = ccall((:Cudd_zddSubset1, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Cint),
              m.ptr, a.ptr, i)
    return _wrap_zdd_node(m, p)
end

"""zdd_subset0(a, i)

Return the ZDD representing the subset of `a` not containing element `i`.
This is the cofactor operation: families whose sets must not include variable `i`.
"""
function zdd_subset0(a::ZDDNode, i::Integer)::ZDDNode
    m = a.m
    p = ccall((:Cudd_zddSubset0, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Cint),
              m.ptr, a.ptr, i)
    return _wrap_zdd_node(m, p)
end

"""zdd_change(a, i)

Return the ZDD obtained by toggling the presence of element `i` in all sets of `a`.
Sets containing `i` will not contain it, and sets not containing `i` will contain it.
"""
function zdd_change(a::ZDDNode, i::Integer)::ZDDNode
    m = a.m
    p = ccall((:Cudd_zddChange, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Cint),
              m.ptr, a.ptr, i)
    return _wrap_zdd_node(m, p)
end

"""zdd_ite(i, t, e)

Return the ZDD if-then-else: if `i` then `t` else `e`.

Constraints:
- All inputs must belong to the same manager; the result belongs to that manager.
- Errors from CUDD (e.g., `NULL` nodes) propagate via `_wrap_zdd_node` as `ErrorException`.
"""
function zdd_ite(i::ZDDNode, t::ZDDNode, e::ZDDNode)::ZDDNode
    m = i.m
    p = ccall((:Cudd_zddIte, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}, Ptr{DdNode}, Ptr{DdNode}),
              m.ptr, i.ptr, t.ptr, e.ptr)
    return _wrap_zdd_node(m, p)
end



"""zdd_count(z)

Return the number of sets (combinations) in the ZDD `z` as a floating-point value.
"""
function zdd_count(z::ZDDNode)::Float64
    ccall((:Cudd_zddCountDouble, libcudd), Cdouble,
          (Ptr{DdManager}, Ptr{DdNode}), z.m.ptr, z.ptr)
end

"""bdd_to_zdd(zdd_mgr, bdd_node)

Convert a BDD node to a ZDD node. The BDD must represent a cube (conjunction of literals).

Constraints:
- `bdd_node.m.ptr` must equal `zdd_mgr.ptr` (shared underlying CUDD manager).
- Errors from CUDD propagate via `_wrap_zdd_node`.
"""
function bdd_to_zdd(zm::ZDDManager, b::BDDNode)::ZDDNode
    # Verify same underlying manager
    b.m.ptr == zm.ptr || error("BDD and ZDD managers must share the same CUDD manager")
    p = ccall((:Cudd_zddPortFromBdd, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}),
              zm.ptr, b.ptr)
    return _wrap_zdd_node(zm, p)
end

"""zdd_mk(i, t, e)

Create a ZDD node with top variable index `i` and children `t` (then/include) and `e` (else/exclude).

Behavior and constraints:
- Equivalent to `zdd_ite(var(m, i), t, e)` under the manager of `t`/`e`.
- Children must belong to the same manager as the new node.
- Ordering constraint: `level(i) < node_level(t)` and `level(i) < node_level(e)`.
    If this constraint is violated, construction fails (CUDD returns `NULL`) and an
    `ErrorException` is thrown by the wrapper.
"""
function zdd_mk(i::Integer, high::ZDDNode, low::ZDDNode)::ZDDNode
    mgr = high.m
    level = zdd_node_level(mgr, i)
    @assert level < node_level(high) && level < node_level(low)
    p = ccall((:My_ZddMakeNode, libmycudd), Ptr{DdNode},
              (Ptr{DdManager}, Cint, Ptr{DdNode}, Ptr{DdNode}),
              mgr.ptr, i, high.ptr, low.ptr)
    return _wrap_zdd_node(mgr, p)
end

"""zdd_to_bdd(bdd_mgr, zdd_node)

Convert a ZDD node to a BDD node.

Constraints:
- `zdd_node.m.ptr` must equal `bdd_mgr.ptr` (shared underlying CUDD manager).
- Errors from CUDD propagate via `_wrap_node`.
"""
function zdd_to_bdd(bm::BDDManager, z::ZDDNode)::BDDNode
    # Verify same underlying manager
    z.m.ptr == bm.ptr || error("ZDD and BDD managers must share the same CUDD manager")
    p = ccall((:Cudd_zddPortToBdd, libcudd), Ptr{DdNode},
              (Ptr{DdManager}, Ptr{DdNode}),
              bm.ptr, z.ptr)
    return _wrap_node(bm, p)
end
