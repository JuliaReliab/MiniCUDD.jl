using MiniCUDD

# Test the local recursive implementation
m = ZDDManager(nvars=4)
z0 = var(m, 0)
z1 = var(m, 1)
z2 = var(m, 2)

# Test case 1: Expected {{1}}
F = zdd_union(zdd_union(z0, z1), zdd_change(z0, 2))  # {{0},{1},{0,2}}
G = zdd_union(z0, z2)                                # {{0},{2}}

println("Test 1: F={{0},{1},{0,2}}, G={{0},{2}}")
println("  F count: $(zdd_count(F))")  # Should be 3 (but actually 4 due to base set?)
println("  G count: $(zdd_count(G))")  # Should be 2 (but actually 5?)

# Let me check what these actually represent
println("\nF DOT:")
println(to_dot(F, title="F"))
println("\nG DOT:")
println(to_dot(G, title="G"))

quit(m)
