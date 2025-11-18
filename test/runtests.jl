# BDD tests
include("test_bdd_operations.jl")
include("test_bdd_probability.jl")

# ZDD tests
include("test_zdd_operations.jl")

# Unified API tests
include("test_unified_api.jl")

# API usage and type safety tests
include("test_api_usage.jl")
include("test_type_safety.jl")
include("test_manager_separation.jl")

# DOT export tests
include("test_dot_export.jl")

# Operator override tests
include("test_ops_overrides.jl")

# Node builder helpers tests
include("test_node_builders.jl")
