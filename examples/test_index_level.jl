using MiniCUDD

m = BDDManager(nvars=4)
b0 = var(m, 0)
b1 = var(m, 1)
b2 = var(m, 2)
b3 = var(m, 3)

println("BDD variable node indices and levels:")
for (i, b) in enumerate([b0, b1, b2, b3])
    println("  Variable $i: node_index=$(node_index(b)), node_level=$(node_level(b))")
end

g1 = b0 & b2 | b1
g2 = b1 | b3 & b0
g3 = g1 & g2
println("\nBDD nodes in g3:")
println(to_dot(g3, title="g3"))

zm = ZDDManager(nvars=4)
base = zdd_base(zm)
z0 = zdd_change(base, 0)
z1 = zdd_change(base, 1)
z2 = zdd_change(base, 2)
z3 = zdd_change(base, 3)

println("\nZDD variable node indices and levels:")
for (i, z) in enumerate([z0, z1, z2, z3])
    println("  Variable $i: node_index=$(node_index(z)), node_level=$(node_level(z))")
end

h1 = zdd_union(z0, z2)
h2 = zdd_union(z1, z3)
h3 = zdd_union(h1, h2)
println("\nZDD nodes in h3:")
println(to_dot(h3, title="h3"))

zdd_empty_ptr = zdd_empty(zm).ptr
zdd_base_ptr = zdd_base(zm).ptr
println("\nZDD terminal checks:")
println("  empty ptr: $zdd_empty_ptr")
println("  base ptr: $zdd_base_ptr")

bdd_empty_ptr = const0(m).ptr
bdd_one_ptr = const1(m).ptr
println("\nBDD terminal checks:")
println("  zero ptr: $bdd_empty_ptr")
println("  one ptr: $bdd_one_ptr")

mgr = ZDDManager(nvars=3)
zddbase = zdd_base(mgr)
x = zdd_change(zddbase, 0)
y = zdd_change(x, 1)
z = zdd_change(y, 2)

# Use custom variable labels
dot_str = to_dot(z, title="x * y * z", varlabels=["x", "y", "z"])
println("\nZDD representing x * y * z:")
println(dot_str)
