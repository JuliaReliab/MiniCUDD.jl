# DOT export for Graphviz visualization
#
# This file contains functions to export BDD and ZDD structures to 
# Graphviz DOT language format for visualization.

"""to_dot(node; title="BDD", varlabels=nothing, terminal_labels=["F", "T"])

Generate DOT language representation for visualizing the BDD with Graphviz.

Returns a string containing the complete DOT graph description. You can save
this to a file and render it with Graphviz tools:

```
dot_str = to_dot(node, title="My BDD")
write("graph.dot", dot_str)
# Then run: dot -Tpng graph.dot -o graph.png
```

# Arguments
- `node`: A `BDDNode` to visualize
- `title`: Optional title for the graph (default: "BDD")
- `varlabels`: Optional vector/array of variable labels. If provided, variable at index i will be labeled with varlabels[i+1] (1-indexed). If not provided, variables are labeled with their index number.
- `terminal_labels`: Optional labels for terminal nodes (default: ["F", "T"])

The generated graph shows:
- Variable nodes as circles with variable labels
- Terminal nodes as squares (T/F for BDD)
- Then-edges (1-edges) as solid lines
- Else-edges (0-edges) as dashed lines

# Example
```
mgr = BDDManager(nvars=3)
x = var(mgr, 0)
y = var(mgr, 1)
z = var(mgr, 2)
f1 = bdd_and(x, y)
f2 = bdd_and(f1, z)


# Use custom variable labels
dot_str = to_dot(f2, title="x AND y AND z", varlabels=["x", "y", "z"])
```
"""
function to_dot(node::BDDNode; title::String="BDD", varlabels=nothing, terminal_labels=["F", "T"])
    buf = IOBuffer()
    terminal_ids = (node_id(const0(node.m)), node_id(const1(node.m)))
    _to_dot(buf, node; title=title, varlabels=varlabels, terminal_ids=terminal_ids, terminal_labels=terminal_labels)
    return String(take!(buf))
end

"""to_dot(node; title="ZDD", varlabels=nothing, terminal_labels=["∅", "B"])

Generate DOT language representation for visualizing the ZDD with Graphviz.

Returns a string containing the complete DOT graph description. You can save
this to a file and render it with Graphviz tools:

```
dot_str = to_dot(node, title="My ZDD")
write("graph.dot", dot_str)
# Then run: dot -Tpng graph.dot -o graph.png
```

# Arguments
- `node`: A `ZDDNode` to visualize
- `title`: Optional title for the graph (default: "ZDD")
- `varlabels`: Optional vector/array of variable labels. If provided, variable at index i will be labeled with varlabels[i+1] (1-indexed). If not provided, variables are labeled with their index number.
- `terminal_labels`: Optional labels for terminal nodes (default: ["∅", "B"])

The generated graph shows:
- Variable nodes as circles with variable labels
- Terminal nodes as squares (∅/B for ZDD)
- Then-edges (1-edges) as solid lines
- Else-edges (0-edges) as dashed lines

# Example
```
mgr = ZDDManager(nvars=3)
zddbase = zdd_base(mgr)
x = zdd_change(zddbase, 0)
y = zdd_change(x, 1)
z = zdd_change(y, 2)

# Use custom variable labels
dot_str = to_dot(z, title="x * y * z", varlabels=["x", "y", "z"])
```
"""
function to_dot(node::ZDDNode; title::String="ZDD", varlabels=nothing, terminal_labels=["∅", "B"])
    buf = IOBuffer()
    terminal_ids = (node_id(zdd_empty(node.m)), node_id(zdd_base(node.m)))
    _to_dot(buf, node; title=title, varlabels=varlabels, terminal_ids=terminal_ids, terminal_labels=terminal_labels)
    return String(take!(buf))
end

function _to_dot(io::IO, node::T; title::String, varlabels, terminal_ids, terminal_labels) where {T<:Union{BDDNode, ZDDNode}}
    if varlabels === nothing
        varlabels = String[]
        for i in 0:nvars(node.m)-1
            push!(varlabels, string(i))
        end
    end

    # Validate variable labels do not clash with terminal labels
    reserved = Set(terminal_labels)
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
    
    # Track visited nodes to avoid duplicates
    visited = Set{UInt}()
    
    println(io, "digraph \"$title\" {")
    println(io, "  rankdir=TB;")
    println(io, "  node [shape=circle];")
    println(io)
    
    # Recursive traversal
    function traverse(n::T)
        nid = node_id(n)
        if nid in visited
            return
        end
        push!(visited, nid)
        
        if nid == terminal_ids[1]
            println(io, "  node_$nid [label=\"$(terminal_labels[1])\", shape=square];")
        elseif nid == terminal_ids[2]
            println(io, "  node_$nid [label=\"$(terminal_labels[2])\", shape=square];")
        else
            # Variable node
            idx = node_index(n)
            label = string(varlabels[idx + 1])
            println(io, "  node_$nid [label=\"$label\"];")
            
            # Get children
            then_child = then_node(n)
            else_child = else_node(n)
            
            # Then-edge (solid line)
            then_nid = node_id(then_child)
            println(io, "  node_$nid -> node_$then_nid [style=solid];")
            
            # Else-edge (dashed line)
            else_nid = node_id(else_child)
            println(io, "  node_$nid -> node_$else_nid [style=dashed];")
            
            # Recursively traverse children
            traverse(then_child)
            traverse(else_child)
        end
    end
    
    traverse(node)
    
    println(io, "}")
end

"""to_dot(io, node::BDDNode; title="BDD", varlabels=nothing, terminal_labels=["F", "T"])

Write DOT language representation for BDDNode to an IO stream.

# Arguments
- `io`: An IO stream (e.g., an open file handle)
- `node`: A `BDDNode` to visualize
- `title`: Optional title for the graph
- `varlabels`: Optional vector/array of variable labels
- `terminal_labels`: Optional labels for terminal nodes (default: ["F", "T"])

# Example
```
open("graph.dot", "w") do io
    to_dot(io, node, title="My BDD", varlabels=["x", "y", "z"])
end
```
"""
function to_dot(io::IO, node::BDDNode; title::String="BDD", varlabels=nothing, terminal_labels=["F", "T"])
    terminal_ids = (node_id(const0(node.m)), node_id(const1(node.m)))
    _to_dot(io, node; title=title, varlabels=varlabels, terminal_ids=terminal_ids, terminal_labels=terminal_labels)
end

"""to_dot(io, node::ZDDNode; title="ZDD", varlabels=nothing, terminal_labels=["∅", "B"])

Write DOT language representation for ZDDNode to an IO stream.

# Arguments
- `io`: An IO stream (e.g., an open file handle)
- `node`: A `ZDDNode` to visualize
- `title`: Optional title for the graph
- `varlabels`: Optional vector/array of variable labels
- `terminal_labels`: Optional labels for terminal nodes (default: ["∅", "B"])

# Example
```
open("graph.dot", "w") do io
    to_dot(io, node, title="My ZDD", varlabels=["x", "y", "z"])
end
```
"""
function to_dot(io::IO, node::ZDDNode; title::String="ZDD", varlabels=nothing, terminal_labels=["∅", "B"])
    terminal_ids = (node_id(zdd_empty(node.m)), node_id(zdd_base(node.m)))
    _to_dot(io, node; title=title, varlabels=varlabels, terminal_ids=terminal_ids, terminal_labels=terminal_labels)
end
