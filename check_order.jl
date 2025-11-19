using MiniCUDD

m = ZDDManager(nvars=4)
base = zdd_base(m)

s0 = zdd_change(base, 0)
s1 = zdd_change(base, 1) 
s2 = zdd_change(base, 2)

println("s0 node_index: $(node_index(s0))")
println("s1 node_index: $(node_index(s1))")
println("s2 node_index: $(node_index(s2))")

println("\nIs smaller index closer to root? Let's check structure:")
println("s0 (should test var 0 at root):")
println(to_dot(s0, title="s0"))

println("\ns2 (should test var 0, then 1, then 2):")
println(to_dot(s2, title="s2"))

quit(m)
