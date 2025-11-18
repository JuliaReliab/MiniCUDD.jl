# Operator overrides for MiniCUDD nodes
#
# BDD operators: & | ⊻ !
# ZDD set operators: union, intersect, setdiff and Unicode ∪, ∩

# Define operator methods by extending Base and adding Unicode helpers

# ========================
# BDD logical operators
# ========================

Base.:&(a::BDDNode, b::BDDNode) = bdd_and(a, b)
Base.:(|)(a::BDDNode, b::BDDNode) = bdd_or(a, b)
Base.:⊻(a::BDDNode, b::BDDNode) = bdd_xor(a, b)
Base.:!(a::BDDNode) = _wrap_node(a.m, compl(a.ptr); ref=false, manage=false)

# ========================
# ZDD set operators
# ========================

Base.union(a::ZDDNode, b::ZDDNode) = zdd_union(a, b)
Base.intersect(a::ZDDNode, b::ZDDNode) = zdd_intersect(a, b)
Base.setdiff(a::ZDDNode, b::ZDDNode) = zdd_diff(a, b)

# Arithmetic-style aliases
Base.:+(a::ZDDNode, b::ZDDNode) = zdd_union(a, b)
Base.:*(a::ZDDNode, b::ZDDNode) = zdd_intersect(a, b)
Base.:-(a::ZDDNode, b::ZDDNode) = zdd_diff(a, b)

# Unicode set operators for convenience (∪ and ∩)
# These are defined in this module (not in Base), so they are available as MiniCUDD.∪ and MiniCUDD.∩

∪(a::ZDDNode, b::ZDDNode) = zdd_union(a, b)
∩(a::ZDDNode, b::ZDDNode) = zdd_intersect(a, b)
