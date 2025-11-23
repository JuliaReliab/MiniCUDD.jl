# Common operations for both BDD and ZDD nodes
#
# This file contains utility functions and accessors that work uniformly
# across both BDDNode and ZDDNode types using Julia's multiple dispatch.

# Complement bit helpers
@inline iscompl(p::Ptr{DdNode}) = (UInt(p) & 0x1) == 0x1
@inline compl(p::Ptr{DdNode})  = Ptr{DdNode}(UInt(p) ⊻ 0x1)

# ============================================================================
# Child pointer accessors
# ============================================================================

@inline regular(p::Ptr{DdNode}) = Ptr{DdNode}(UInt(p) & ~UInt(0x1))

"""then_ptr(node)

Return the raw then-pointer (Ptr{DdNode}) of the given node. The
pointer returned respects the complement bit of the node.
"""
@inline function then_ptr(n::BDDNode)
    p = regular(n.ptr)
    t = ccall((:Cudd_T, libcudd), Ptr{DdNode}, (Ptr{DdNode},), p)
    return t
end

@inline function then_ptr(n::ZDDNode)
    p = regular(n.ptr)
    ccall((:Cudd_T, libcudd), Ptr{DdNode}, (Ptr{DdNode},), p)
end

"""else_ptr(node)

Return the raw else-pointer (Ptr{DdNode}) of the given node. The
pointer returned respects the complement bit of the node.
"""
@inline function else_ptr(n::BDDNode)
    p = regular(n.ptr)
    e = ccall((:Cudd_E, libcudd), Ptr{DdNode}, (Ptr{DdNode},), p)
    return e
end

@inline function else_ptr(n::ZDDNode)
    p = regular(n.ptr)
    e = ccall((:Cudd_E, libcudd), Ptr{DdNode}, (Ptr{DdNode},), p)
    return e
end

# ============================================================================
# Child node accessors
# ============================================================================

"""then_node(node)

Return the node corresponding to the then-child (1-edge) of `node`.
"""
@inline function then_node(n::BDDNode)::BDDNode
    p = then_ptr(n)
    return _wrap_node(n.m, p; ref=false, manage=false)
end

@inline function then_node(n::ZDDNode)::ZDDNode
    p = then_ptr(n)
    return _wrap_zdd_node(n.m, p; ref=false, manage=false)
end

"""else_node(node)

Return the node corresponding to the else-child (0-edge) of `node`.
"""
@inline function else_node(n::BDDNode)::BDDNode
    p = else_ptr(n)
    return _wrap_node(n.m, p; ref=false, manage=false)
end

@inline function else_node(n::ZDDNode)::ZDDNode
    p = else_ptr(n)
    return _wrap_zdd_node(n.m, p; ref=false, manage=false)
end

# ============================================================================
# Utility functions
# ============================================================================

"""node_id(node)

Return a unique identifier for the given `BDDNode` or `ZDDNode`.
This is based on the canonical pointer (with complement bit cleared).
"""
@inline function node_id(x::BDDNode)::UInt
    m = x.m
    if isconstant(x)
        return UInt(x.ptr)
    else
        return UInt(regular(x.ptr))
    end
end

@inline function node_id(x::ZDDNode)::UInt
    UInt(x.ptr)
end

"""dag_size(node)

Return the DAG size (node count) of the given `BDDNode` or `ZDDNode`.
"""
@inline function dag_size(x::BDDNode)::Cint
    ccall((:Cudd_DagSize, libcudd), Cint, (Ptr{DdNode},), x.ptr)
end

@inline function dag_size(x::ZDDNode)::Cint
    ccall((:Cudd_DagSize, libcudd), Cint, (Ptr{DdNode},), x.ptr)
end

"""node_index(node)

Return the variable index tested at the root of node `n`.
"""
@inline function node_index(n::BDDNode)::Cint
    return ccall((:Cudd_NodeReadIndex, libcudd), Cint, (Ptr{DdNode},), n.ptr)
end

@inline function node_index(n::ZDDNode)::Cint
    return ccall((:Cudd_NodeReadIndex, libcudd), Cint, (Ptr{DdNode},), n.ptr)
end

"""node_level(node)

Return the current level (position in the variable ordering) of the variable
tested at the root of `node`.

For BDD nodes this queries `Cudd_ReadPerm`, for ZDD nodes `Cudd_ReadPermZdd`.
Terminal (constant) nodes return `-1`.
"""
@inline function node_level(n::BDDNode)::Int
    isconstant(n) && return typemax(Int)
    idx = node_index(n)
    return ccall((:Cudd_ReadPerm, libcudd), Cint, (Ptr{DdManager}, Cint), n.m.ptr, idx)
end

@inline function node_level(n::ZDDNode)::Int
    isconstant(n) && return typemax(Int)
    idx = node_index(n)
    return ccall((:Cudd_ReadPermZdd, libcudd), Cint, (Ptr{DdManager}, Cint), n.m.ptr, idx)
end

"""isconstant(node)

Return true if `node` is a terminal constant node.
"""
@inline function isconstant(n::BDDNode)::Bool
    return ccall((:Cudd_IsConstant, libcudd), Cint, (Ptr{DdNode},), n.ptr) != 0
end

@inline function isconstant(n::ZDDNode)::Bool
    return ccall((:Cudd_IsConstant, libcudd), Cint, (Ptr{DdNode},), n.ptr) != 0
end

# ============================================================================
# Base overrides
# ============================================================================

"""length(node)

Return the DAG size (node count) of the given `BDDNode` or `ZDDNode`.
Equivalent to `dag_size(node)`.
"""
Base.length(n::BDDNode) = Int(dag_size(n))
Base.length(n::ZDDNode) = Int(dag_size(n))

"""
    nvars(mgr::BDDManager) -> Int

Return the number of BDD variables currently defined in the CUDD manager.
"""
function nvars(mgr::BDDManager)
    return ccall((:Cudd_ReadSize, libcudd), Cint,
                 (Ptr{DdManager},), mgr.ptr)
end

"""
    nvars(mgr::ZDDManager) -> Int

Return the number of ZDD variables currently defined in the CUDD manager.
"""
function nvars(mgr::ZDDManager)
    return ccall((:Cudd_ReadZddSize, libcudd), Cint,
                 (Ptr{DdManager},), mgr.ptr)
end