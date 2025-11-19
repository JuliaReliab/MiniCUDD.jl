using MiniCUDD

# Debug version with tracing
m = ZDDManager(nvars=4)
z0 = var(m, 0)
z1 = var(m, 1)
z2 = var(m, 2)

# Check what we actually built
F = zdd_union(zdd_union(z0, z1), zdd_change(z0, 2))
G = zdd_union(z0, z2)

println("z0 (var 0):")
println(to_dot(z0, title="z0"))
println("\nz1 (var 1):")
println(to_dot(z1, title="z1"))
println("\nz2 (var 2):")
println(to_dot(z2, title="z2"))

println("\nF = union(union(z0,z1), change(z0,2)):")
println(to_dot(F, title="F"))
println("F count: $(zdd_count(F))")

println("\nG = union(z0, z2):")
println(to_dot(G, title="G"))
println("G count: $(zdd_count(G))")

# Check terminal pointers
empty_ptr = zdd_empty(m).ptr
base_ptr = zdd_base(m).ptr
println("\nTerminal checks:")
println("empty ptr: $empty_ptr")
println("base ptr: $base_ptr")
println("F.ptr: $(F.ptr)")
println("G.ptr: $(G.ptr)")
println("F is constant: $(isconstant(F))")
println("G is constant: $(isconstant(G))")

quit(m)
