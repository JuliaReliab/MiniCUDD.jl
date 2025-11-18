using MiniCUDD

# Example: Visualizing a BDD with Graphviz DOT export

# Create a BDD manager with 4 variables
mgr = BDDManager(nvars=4)

# Create variables
x0 = var(mgr, 0)
x1 = var(mgr, 1)
x2 = var(mgr, 2)
x3 = var(mgr, 3)

# Build a complex expression: (x0 ∧ x1) ∨ (x2 ∧ x3)
left = bdd_and(x0, x1)
right = bdd_and(x2, x3)
f = bdd_or(left, right)

println("BDD DAG size: ", dag_size(f))

# Generate DOT representation
dot_str = to_dot(f, title="(x0 ∧ x1) ∨ (x2 ∧ x3)")
println("\nDOT representation:")
println(dot_str)

# You can also write directly to a file
open("bdd_example.dot", "w") do io
    to_dot(io, f, title="My BDD")
end
println("\nDOT file written to bdd_example.dot")
println("To visualize, run: dot -Tpng bdd_example.dot -o bdd_example.png")

# Clean up
quit(mgr)

# Example with ZDD
println("\n" * "="^60)
println("ZDD Example")
println("="^60)

zmgr = ZDDManager(nvars=3)

# Create a ZDD representing the set family {{0}, {1}, {0,2}}
z0 = var(zmgr, 0)
z1 = var(zmgr, 1) 
z2 = var(zmgr, 2)

# {0}
set0 = z0

# {1}
set1 = z1

# {0,2} = change variable 2 to 1 in {0}
set0_2 = zdd_change(z0, 2)

# Union of all three sets
family = zdd_union(zdd_union(set0, set1), set0_2)

println("ZDD set count: ", zdd_count(family))

# Generate DOT for ZDD
dot_str_zdd = to_dot(family, title="{{0}, {1}, {0,2}}")
println("\nZDD DOT representation:")
println(dot_str_zdd)

open("zdd_example.dot", "w") do io
    to_dot(io, family, title="ZDD Set Family")
end
println("\nZDD DOT file written to zdd_example.dot")
println("To visualize, run: dot -Tpng zdd_example.dot -o zdd_example.png")

quit(zmgr)
