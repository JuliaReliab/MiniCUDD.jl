# DOT export for Graphviz visualization
#
# This file contains functions to export BDD and ZDD structures to 
# Graphviz DOT language format for visualization.

"""to_dot(node; title="BDD", varlabels=nothing)

Generate DOT language representation for visualizing the BDD/ZDD with Graphviz.

Returns a string containing the complete DOT graph description. You can save
this to a file and render it with Graphviz tools:

```
dot_str = to_dot(node, title="My BDD")
write("graph.dot", dot_str)
# Then run: dot -Tpng graph.dot -o graph.png
```

# Arguments
- `node`: A `BDDNode` or `ZDDNode` to visualize
- `title`: Optional title for the graph (default: "BDD" for BDDNode, "ZDD" for ZDDNode)
- `varlabels`: Optional vector/array of variable labels. If provided, variable at index i will be labeled with varlabels[i+1] (1-indexed). If not provided, variables are labeled with their index number.

The generated graph shows:
- Variable nodes as circles with variable labels
- Terminal nodes as squares (T/F for BDD, ∅/B for ZDD)
- Then-edges (1-edges) as solid lines
- Else-edges (0-edges) as dashed lines

# Example
```
mgr = BDDManager(nvars=3)
v0 = var(mgr, 0)
v1 = var(mgr, 1)
f = bdd_and(v0, v1)

# Use custom variable labels
dot_str = to_dot(f, title="x AND y", varlabels=["x", "y", "z"])
```
"""
function to_dot(node::Union{BDDNode, ZDDNode}; title::String="", varlabels=nothing)
    # Determine default title based on node type
    if isempty(title)
        title = node isa BDDNode ? "BDD" : "ZDD"
    end
    
    # Validate variable labels do not clash with terminal labels
    if varlabels !== nothing
        reserved = node isa BDDNode ? Set(["T", "F"]) : Set(["∅", "B"])
        conflicts = String[]
        for lbl in varlabels
            s = string(lbl)
            if s in reserved
                push!(conflicts, s)
            end
        end
        if !isempty(conflicts)
            throw(ArgumentError("varlabels contain reserved terminal labels $(collect(reserved)); conflicting: $(unique(conflicts))"))
        end
    end
    
    # Track visited nodes to avoid duplicates
    visited = Set{Ptr{DdNode}}()
    io = IOBuffer()
    
    println(io, "digraph \"$title\" {")
    println(io, "  rankdir=TB;")
    println(io, "  node [shape=circle];")
    println(io)
    
    # Helper to get node ID - for terminals include complement bit to distinguish T/F
    node_id(p::Ptr{DdNode}, is_terminal::Bool) = is_terminal ? string(UInt(p), base=16) : string(UInt(p) & ~UInt(0x1), base=16)
    
    # Recursive traversal
    function traverse(n::Union{BDDNode, ZDDNode})
        ptr = n.ptr
        # Get canonical pointer (remove complement bit)
        canonical = Ptr{DdNode}(UInt(ptr) & ~UInt(0x1))
        
        # For terminals, track with complement bit; for non-terminals, track canonical
        visit_key = isconstant(n) ? ptr : canonical
        if visit_key in visited
            return
        end
        push!(visited, visit_key)
        
        if isconstant(n)
            # Terminal node - use full pointer with complement bit for ID
            nid = node_id(ptr, true)
            if n isa BDDNode
                # In CUDD, const1 is the actual terminal node, const0 is its complement
                # Check if the original pointer has complement bit set
                c1_canonical = Ptr{DdNode}(UInt(const1(n.m).ptr) & ~UInt(0x1))
                if canonical == c1_canonical
                    # This is the constant 1 terminal node
                    # Check complement bit in original pointer to determine label
                    label = iscompl(ptr) ? "F" : "T"
                else
                    # Shouldn't happen in standard BDDs, but handle gracefully
                    label = "?"
                end
            else  # ZDDNode
                # For ZDD, check both empty and base terminals
                empty_canonical = Ptr{DdNode}(UInt(zdd_empty(n.m).ptr) & ~UInt(0x1))
                base_canonical = Ptr{DdNode}(UInt(zdd_base(n.m).ptr) & ~UInt(0x1))
                if canonical == empty_canonical
                    label = iscompl(ptr) ? "B" : "∅"
                elseif canonical == base_canonical
                    label = iscompl(ptr) ? "∅" : "B"
                else
                    label = "?"
                end
            end
            println(io, "  node_$nid [label=\"$label\", shape=square];")
        else
            # Variable node - use canonical pointer for ID
            nid = node_id(canonical, false)
            idx = node_index(n)
            # Use custom label if provided, otherwise use index
            label = if varlabels !== nothing && idx + 1 <= length(varlabels)
                string(varlabels[idx + 1])
            else
                string(idx)
            end
            println(io, "  node_$nid [label=\"$label\"];")
            
            # Get children
            then_child = then_node(n)
            else_child = else_node(n)
            
            # Then-edge (solid line) - use appropriate ID based on whether child is terminal
            then_nid = node_id(then_child.ptr, isconstant(then_child))
            println(io, "  node_$nid -> node_$then_nid [style=solid];")
            
            # Else-edge (dashed line) - use appropriate ID based on whether child is terminal
            else_nid = node_id(else_child.ptr, isconstant(else_child))
            println(io, "  node_$nid -> node_$else_nid [style=dashed];")
            
            # Recursively traverse children
            traverse(then_child)
            traverse(else_child)
        end
    end
    
    traverse(node)
    
    println(io, "}")
    return String(take!(io))
end

"""to_dot(io, node; title="BDD", varlabels=nothing)

Write DOT language representation to an IO stream.

# Arguments
- `io`: An IO stream (e.g., an open file handle)
- `node`: A `BDDNode` or `ZDDNode` to visualize
- `title`: Optional title for the graph
- `varlabels`: Optional vector/array of variable labels

# Example
```
open("graph.dot", "w") do io
    to_dot(io, node, title="My BDD", varlabels=["x", "y", "z"])
end
```
"""
function to_dot(io::IO, node::Union{BDDNode, ZDDNode}; title::String="", varlabels=nothing)
    write(io, to_dot(node; title=title, varlabels=varlabels))
end
