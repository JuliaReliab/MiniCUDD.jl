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

"""then_ptr(node)

Return the raw then-pointer (Ptr{DdNode}) of the given node. The
pointer returned respects the complement bit of the node.
"""
function then_ptr(n::BDDNode)
    t = ccall((:Cudd_T, libcudd), Ptr{DdNode}, (Ptr{DdNode},), n.ptr)
    return iscompl(n.ptr) ? compl(t) : t
end

function then_ptr(n::ZDDNode)
    t = ccall((:Cudd_T, libcudd), Ptr{DdNode}, (Ptr{DdNode},), n.ptr)
    return iscompl(n.ptr) ? compl(t) : t
end

"""else_ptr(node)

Return the raw else-pointer (Ptr{DdNode}) of the given node. The
pointer returned respects the complement bit of the node.
"""
function else_ptr(n::BDDNode)
    e = ccall((:Cudd_E, libcudd), Ptr{DdNode}, (Ptr{DdNode},), n.ptr)
    return iscompl(n.ptr) ? compl(e) : e
end

function else_ptr(n::ZDDNode)
    e = ccall((:Cudd_E, libcudd), Ptr{DdNode}, (Ptr{DdNode},), n.ptr)
    return iscompl(n.ptr) ? compl(e) : e
end

# ============================================================================
# Child node accessors
# ============================================================================

"""then_node(node)

Return the node corresponding to the then-child (1-edge) of `node`.
"""
function then_node(n::BDDNode)::BDDNode
    p = then_ptr(n)
    return _wrap_node(n.m, p; ref=false, manage=false)
end

function then_node(n::ZDDNode)::ZDDNode
    p = then_ptr(n)
    return _wrap_zdd_node(n.m, p; ref=false, manage=false)
end

"""else_node(node)

Return the node corresponding to the else-child (0-edge) of `node`.
"""
function else_node(n::BDDNode)::BDDNode
    p = else_ptr(n)
    return _wrap_node(n.m, p; ref=false, manage=false)
end

function else_node(n::ZDDNode)::ZDDNode
    p = else_ptr(n)
    return _wrap_zdd_node(n.m, p; ref=false, manage=false)
end

# ============================================================================
# Utility functions
# ============================================================================

"""dag_size(node)

Return the DAG size (node count) of the given `BDDNode` or `ZDDNode`.
"""
dag_size(x::BDDNode)::Cint =
    ccall((:Cudd_DagSize, libcudd), Cint, (Ptr{DdNode},), x.ptr)

dag_size(x::ZDDNode)::Cint =
    ccall((:Cudd_DagSize, libcudd), Cint, (Ptr{DdNode},), x.ptr)

"""node_index(node)

Return the variable index tested at the root of node `n`.
"""
function node_index(n::BDDNode)::Cint
    return ccall((:Cudd_NodeReadIndex, libcudd), Cint, (Ptr{DdNode},), n.ptr)
end

function node_index(n::ZDDNode)::Cint
    return ccall((:Cudd_NodeReadIndex, libcudd), Cint, (Ptr{DdNode},), n.ptr)
end

"""node_level(node)

Return the current level (position in the variable ordering) of the variable
tested at the root of `node`.

For BDD nodes this queries `Cudd_ReadPerm`, for ZDD nodes `Cudd_ReadPermZdd`.
Terminal (constant) nodes return `-1`.
"""
function node_level(n::BDDNode)::Cint
    isconstant(n) && return Cint(-1)
    idx = node_index(n)
    return ccall((:Cudd_ReadPerm, libcudd), Cint, (Ptr{DdManager}, Cint), n.m.ptr, idx)
end

function node_level(n::ZDDNode)::Cint
    isconstant(n) && return Cint(-1)
    idx = node_index(n)
    return ccall((:Cudd_ReadPermZdd, libcudd), Cint, (Ptr{DdManager}, Cint), n.m.ptr, idx)
end

"""isconstant(node)

Return true if `node` is a terminal constant node.
"""
function isconstant(n::BDDNode)::Bool
    return ccall((:Cudd_IsConstant, libcudd), Cint, (Ptr{DdNode},), n.ptr) != 0
end

function isconstant(n::ZDDNode)::Bool
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
