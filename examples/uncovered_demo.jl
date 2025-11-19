using MiniCUDD

const NodeId = Ptr{MiniCUDD.DdNode}

function zdd_uncovered(F::ZDDNode, G::ZDDNode, memo::Dict{Tuple{NodeId, NodeId}, ZDDNode})::ZDDNode
    F.m === G.m || error("ZDD managers must match")
    m = F.m
    empty_node = zdd_empty(m)
    base_node = zdd_base(m)

    function _uncovered(f::ZDDNode, g::ZDDNode)::ZDDNode
        (f.ptr == empty_node.ptr) && return empty_node
        (g.ptr == empty_node.ptr) && return f
        (g.ptr == base_node.ptr)  && return empty_node
        if f.ptr == g.ptr
            return empty_node
        end

        key = (f.ptr, g.ptr)
        get!(memo, key) do
            f_level = node_level(f)
            g_level = node_level(g)
            if f_level > g_level # ZDD tree of f is higher than g
                f_then = then_node(f)
                f_else = else_node(f)
                low = _uncovered(f_else, g)
                high = _uncovered(f_then, g)
                zdd_mk(node_index(f), high, low)
            elseif f_level < g_level # ZDD tree of g is higher than f
                g_else = else_node(g)
                _uncovered(f, g_else)
            else # level_f == level_g
                f_then = then_node(f)
                f_else = else_node(f)
                g_then = then_node(g)
                g_else = else_node(g)
                low = _uncovered(f_else, g_else)
                gunion = zdd_union(g_then, g_else)
                high = _uncovered(f_then, gunion)
                zdd_mk(node_index(f), high, low)
            end
        end
    end

    _uncovered(F, G)
end

# Demonstration of the zdd_uncovered operation.
#
# We construct:
#   F = {{0}, {1}, {0,2}}
#   G = {{0}, {2}}
# Covered sets in F are those having a subset in G:
#   {0} is covered by {0}
#   {0,2} is covered by {0} (also by {2})
# The set {1} is not covered.
# Result should be {{1}}.
if abspath(PROGRAM_FILE) == @__FILE__
        m = ZDDManager(nvars=4)
        base = zdd_base(m)
        
        # Create singletons: {0}, {1}, {2}
        s0 = zdd_change(base, 0)  # {0}
        s1 = zdd_change(base, 1)  # {1}
        s2 = zdd_change(base, 2)  # {2}
        s02 = zdd_change(zdd_change(base, 0), 2)  # {0,2}

        F = zdd_union(zdd_union(s0, s1), s02)  # {{0},{1},{0,2}}
        G = zdd_union(s0, s2)                  # {{0},{2}}

        memo = Dict{Tuple{NodeId, NodeId}, ZDDNode}()
        U = zdd_uncovered(F, G, memo)                        # {{1}}

        println("Counts: F=$(zdd_count(F)) G=$(zdd_count(G)) Uncovered=$(zdd_count(U))")
        println(to_dot(U, title="Uncovered(F,G)"))
        quit(m)
end