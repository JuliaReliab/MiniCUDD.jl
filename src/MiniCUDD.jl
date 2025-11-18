"""
MiniCUDD

A lightweight thin Julia wrapper around the CUDD BDD library.

This module provides minimal bindings to create and manipulate Binary Decision
Diagrams (BDDs) and Zero-suppressed Binary Decision Diagrams (ZDDs) via the CUDD C API.
It exposes `BDDManager` and `ZDDManager` types that own CUDD managers, and `BDDNode`
and `ZDDNode` values representing BDD/ZDD nodes. The API focuses on fundamental
operations (variable creation, boolean operators, ITE, set operations) and utility
helpers (minterm counting, DAG size, etc.).

Basic usage for BDDs:

```
using MiniCUDD

mgr = BDDManager(nvars=4)
v0 = var(mgr, 0)
v1 = var(mgr, 1)
f = bdd_and(mgr, v0, v1)
println("nodes: ", dag_size(f))
quit(mgr)
```

Basic usage for ZDDs:

```
using MiniCUDD

mgr = ZDDManager(nvars=4)
z0 = var(mgr, 0)  # var() dispatches based on manager type
z1 = var(mgr, 1)
f = zdd_union(mgr, z0, z1)
println("count: ", zdd_count(mgr, f))
quit(mgr)
```

Notes:
- This wrapper calls into `libcudd` via `ccall`. Ensure CUDD is installed and
    `libcudd` is available on `LD_LIBRARY_PATH` (or platform equivalent).
- Objects returned from functions manage CUDD references using finalizers.
    Use `close!` to explicitly release a node if desired.
"""
module MiniCUDD
using Libdl

include(joinpath(@__DIR__, "..", "deps", "deps.jl"))
const libcudd = libcudd_path

export BDDManager, ZDDManager
export BDDNode, ZDDNode
export var, const1, const0
export minterms, dag_size
export node_index, isconstant
export then_ptr, else_ptr
export close!, quit

export bdd_and, bdd_or, bdd_xor, bdd_implies, bdd_ite
export then_node, else_node

export zdd_empty, zdd_base
export zdd_union, zdd_intersect, zdd_diff
export zdd_subset1, zdd_subset0, zdd_change, zdd_ite
export zdd_count

export bdd_to_zdd, zdd_to_bdd

mutable struct DdManager end
mutable struct DdNode    end

const Cuint   = Base.Cuint
const Csize_t = Base.Csize_t

"""Abstract base type for CUDD managers."""
abstract type AbstractManager end

"""A handle that owns a CUDD manager pointer for BDD operations.

`BDDManager` wraps a `Ptr{DdManager}` and tracks whether the manager has been
closed. Finalizers will call `Cudd_Quit` when the manager is garbage-collected
unless `quit` was called explicitly.
"""
mutable struct BDDManager <: AbstractManager
    ptr::Ptr{DdManager}
    alive::Bool
end

"""A handle that owns a CUDD manager pointer for ZDD operations.

`ZDDManager` wraps a `Ptr{DdManager}` and tracks whether the manager has been
closed. Finalizers will call `Cudd_Quit` when the manager is garbage-collected
unless `quit` was called explicitly.
"""
mutable struct ZDDManager <: AbstractManager
    ptr::Ptr{DdManager}
    alive::Bool
end

# Internal helper to initialize a CUDD manager
function _init_manager(T::Type{<:AbstractManager}; nvars::Int=0, slots::Int=256, cachesize::Int=262144)
    mgr = ccall((:Cudd_Init, libcudd), Ptr{DdManager},
                (Cuint,Cuint,Cuint,Cuint,Csize_t),
                nvars, 0, slots, cachesize, Csize_t(0))
    mgr == C_NULL && error("Cudd_Init failed")
    m = T(mgr, true)
    finalizer(m) do mm
        if mm.alive && mm.ptr != C_NULL
            ccall((:Cudd_Quit, libcudd), Cvoid, (Ptr{DdManager},), mm.ptr)
            mm.alive = false
            mm.ptr = C_NULL
        end
    end
    return m
end

"""BDDManager(; nvars=0, slots=256, cachesize=262144)

Create a new CUDD manager for BDD operations.

Arguments
- `nvars::Int`: initial number of BDD variables.
- `slots::Int`: unique table size parameter passed to CUDD.
- `cachesize::Int`: cache size parameter passed to CUDD.

Returns a `BDDManager` instance. Call `quit(mgr)` to free resources explicitly.
"""
BDDManager(; nvars::Int=0, slots::Int=256, cachesize::Int=262144) =
    _init_manager(BDDManager; nvars=nvars, slots=slots, cachesize=cachesize)

"""ZDDManager(; nvars=0, slots=256, cachesize=262144)

Create a new CUDD manager for ZDD operations.

Arguments
- `nvars::Int`: initial number of ZDD variables.
- `slots::Int`: unique table size parameter passed to CUDD.
- `cachesize::Int`: cache size parameter passed to CUDD.

Returns a `ZDDManager` instance. Call `quit(mgr)` to free resources explicitly.
"""
ZDDManager(; nvars::Int=0, slots::Int=256, cachesize::Int=262144) =
    _init_manager(ZDDManager; nvars=nvars, slots=slots, cachesize=cachesize)

function quit(m::AbstractManager)
    if m.alive && m.ptr != C_NULL
        ccall((:Cudd_Quit, libcudd), Cvoid, (Ptr{DdManager},), m.ptr)
        m.alive = false
        m.ptr = C_NULL
    end
    nothing
end

# Forward declarations of node types (defined in respective files)
"""A managed BDD node.

`BDDNode` holds a pointer to a CUDD `DdNode` together with the owning
`BDDManager`. Nodes increment CUDD reference counts on creation and decrement
them when garbage-collected. Use `close!(node)` to release a node early.
"""
mutable struct BDDNode
    m::BDDManager
    ptr::Ptr{DdNode}
    alive::Bool
end

"""A managed ZDD node.

`ZDDNode` holds a pointer to a CUDD `DdNode` together with the owning
`ZDDManager`. ZDD nodes increment CUDD reference counts on creation and decrement
them when garbage-collected. Use `close!(node)` to release a node early.

Note: ZDDs use the same underlying DdNode structure as BDDs but have different
semantics - they are zero-suppressed, meaning nodes with a 0-edge pointing to
the terminal 0 are eliminated.
"""
mutable struct ZDDNode
    m::ZDDManager
    ptr::Ptr{DdNode}
    alive::Bool
end

# Include BDD operations
include("bdd.jl")

# Include ZDD operations
include("zdd.jl")

# Include common operations (works with both BDD and ZDD)
include("common.jl")

end