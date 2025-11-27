# MiniCUDD

[![CI](https://github.com/JuliaReliab/MiniCUDD.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/JuliaReliab/MiniCUDD.jl/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Julia 1.10](https://img.shields.io/badge/Julia-1.10-orange.svg)](https://julialang.org)

MiniCUDD is a lightweight, thin Julia wrapper around the CUDD BDD (Binary
Decision Diagram) library.

This package provides minimal bindings to the CUDD C API, exposing a small
set of primitives for constructing and manipulating BDDs: variable creation,
boolean operators, ITE, basic utilities (minterm counting, DAG size), and
helpers for accessing node children.

Key semantics:
- `node_level`: returns `typemax(Int)` for terminal nodes (BDD/ZDD).
- `node_id`: for BDDs uses canonical pointer for internal nodes and exact pointer for terminals; ZDDs use raw pointers.

Status
------
- Julia compatibility: `julia = "1.10"` (see `Project.toml`)
- Native dependency: CUDD (`libcudd`). You can either use a system-installed
	`libcudd` or build CUDD locally using the included build script.

Repository
----------
https://github.com/JuliaReliab/MiniCUDD.jl

Installation (development/local)
--------------------------------
Add the package in development mode from the package root:

```bash
# From the Julia REPL
import Pkg
Pkg.develop(path=".")
```

Preparing the CUDD library
--------------------------
1) If a system `libcudd` is already installed and discoverable by your OS
	 dynamic loader (e.g. `libcudd.dylib` on macOS, `libcudd.so` on Linux), the
	 package should work as-is.

2) To build CUDD locally (recommended for reproducible builds), run the
	 package build step. The build requires `git`, `autoconf`, `automake`,
	 `libtool`, `make`, and a C compiler.

Prerequisites (macOS via Homebrew):

```bash
brew update
brew install autoconf automake libtool pkg-config
# Optionally ensure command line tools are installed for a compiler:
# xcode-select --install
```

Prerequisites (Ubuntu/Debian):

```bash
sudo apt-get update
sudo apt-get install -y autoconf automake libtool pkg-config build-essential
```

```bash
# zsh/Bash
julia --project=. -e 'using Pkg; Pkg.build("MiniCUDD")'
```

The build script is `deps/build.jl`. It clones the CUDD repository, builds a
shared library, and installs it into `deps/usr/lib/` under the package tree.
After a successful build the generated `deps/deps.jl` contains the resolved
library path.

Note (macOS): macOS has special rules for dynamic library loading (SIP,
`DYLD_LIBRARY_PATH` behavior). If you run into library loading errors, add the
package's `deps/usr/lib` to your environment for the session:

```bash
export DYLD_LIBRARY_PATH=$(pwd)/deps/usr/lib:$DYLD_LIBRARY_PATH  # macOS
export LD_LIBRARY_PATH=$(pwd)/deps/usr/lib:$LD_LIBRARY_PATH    # Linux
```

Quick examples
--------------

### BDD Example

```julia
using MiniCUDD

# Create a BDD manager
mgr = BDDManager(nvars=4)
v0 = var(mgr, 0)
v1 = var(mgr, 1)

# Operations can omit the manager - it's taken from the nodes
f = bdd_and(v0, v1)  # Simpler! Manager not needed
println("DAG size: ", dag_size(f))
println("minterms: ", minterms(f, 2))  # Manager not needed here either
quit(mgr)
```

### ZDD Example

```julia
using MiniCUDD

# Create a ZDD manager
mgr = ZDDManager(nvars=4)
z0 = var(mgr, 0)  # var() works with both BDD and ZDD managers
z1 = var(mgr, 1)

# Operations can omit the manager - it's taken from the nodes
f = zdd_union(z0, z1)  # Simpler! Manager not needed
println("ZDD DAG size: ", dag_size(f))  # dag_size() works with both types
println("Set count: ", zdd_count(f))  # Manager not needed here either
quit(mgr)
```

### Custom Algorithm Example: BDD Probability (Per-Variable)

Below is an example showing how to implement a custom probability
computation over a BDD with variable-dependent probabilities. Assume each
variable `x_i` is independently true with probability `p[i]` (1-indexed vector).
We traverse the BDD using Shannon expansion:

For a non-terminal node testing variable `x_i` with then-child `T` and
else-child `E`:

`Prob(node) = p[i] * Prob(T) + (1 - p[i]) * Prob(E)`

Terminal 1 has probability 1; terminal 0 has probability 0.

We distinguish terminals via cached `node_id` of `const1` / `const0`, and use
an inner function `rec` that closes over the probability vector:

```julia
using MiniCUDD

function prob(f::BDDNode, probs::Vector{Float64})
	length(probs) >= nvars(f.m) || error("prob vector shorter than number of variables")
	one_id  = node_id(const1(f.m))
	zero_id = node_id(const0(f.m))
	memo = Dict{UInt,Float64}()
	function rec(n::BDDNode)::Float64
		nid = node_id(n)
		if haskey(memo, nid)
			return memo[nid]
		end
		if nid == one_id
			memo[nid] = 1.0; return 1.0
		elseif nid == zero_id
			memo[nid] = 0.0; return 0.0
		end
		idx = node_index(n)              # 0-based index
		p = probs[idx + 1]               # access per-variable probability
		t_val = rec(then_node(n))
		e_val = rec(else_node(n))
		val = p * t_val + (1 - p) * e_val
		memo[nid] = val
		return val
	end
	return rec(f)
end

mgr = BDDManager(nvars=3)
x = var(mgr, 0); y = var(mgr, 1); z = var(mgr, 2)
f = (x & y) | (!x & z)
println("Prob with p=[0.5,0.5,0.5]: ", prob(f, [0.5,0.5,0.5]))   # 0.5
println("Prob with p=[0.3,0.3,0.3]: ", prob(f, [0.3,0.3,0.3]))   # 0.30 = 0.3^2 + (1-0.3)*0.3
println("Prob with p=[0.2,0.8,0.6]: ", prob(f, [0.2,0.8,0.6]))   # 0.2*0.8 + (1-0.2)*0.6 = 0.16 + 0.48 = 0.64
quit(mgr)
```

This pattern makes it easy to extend to other aggregations (e.g. expected
costs) by replacing the terminal values and combination rule.

API highlights
--------------

### BDD Operations
- Types: `BDDManager`, `BDDNode`
- Create a manager: `BDDManager(; nvars=0, slots=256, cachesize=262144)`
- Variables: `var(mgr, i)`
- Constants: `const1(mgr)`, `const0(mgr)`
- Boolean ops: `bdd_and(a, b)`, `bdd_or(a, b)`, `bdd_xor(a, b)`, `bdd_implies(a, b)`, `bdd_ite(i, t, e)`
	- Manager is automatically taken from the node arguments
- Node builder: `bdd_mk(i, t, e)` - creates a BDD node with variable index `i` and children `t` (then) and `e` (else). Internally uses ITE and CUDD's unique table for canonicalization and caching. Efficient for repeated calls.
	- Ordering constraint: `level(i) < node_level(t)` and `level(i) < node_level(e)`; violation raises an error (CUDD returns `NULL`).
	- Example: `bdd_mk(0, const1(mgr), const0(mgr)) == var(mgr, 0)`
- Utilities: `minterms(node, nvars)`, `dag_size(node)`, `node_index(node)`, `isconstant(node)`
- Child accessors: `then_node(node)`, `else_node(node)`, `then_ptr(node)`, `else_ptr(node)`

### ZDD Operations
- Types: `ZDDManager`, `ZDDNode`
- Create a manager: `ZDDManager(; nvars=0, slots=256, cachesize=262144)`
- Variables: `var(mgr, i)` (unified with BDD). Equivalent to `zdd_change(zdd_base(mgr), i)` and represents the singleton family `{i}`.
- Constants: `zdd_empty(mgr)`, `zdd_base(mgr)`
- Set ops: `zdd_union(a, b)`, `zdd_intersect(a, b)`, `zdd_diff(a, b)`
	- Manager is automatically taken from the node arguments
- Node builder: `zdd_mk(i, t, e)` - creates a ZDD node with variable index `i` and children `t` (include) and `e` (exclude). Internally uses ITE and CUDD's unique table for canonicalization and caching. Efficient for repeated calls.
	- Ordering constraint: `level(i) < node_level(t)` and `level(i) < node_level(e)`; violation raises an error (CUDD returns `NULL`).
	- Example: `zdd_mk(0, zdd_base(mgr), zdd_empty(mgr)) == var(mgr, 0)`
- Cofactors: `zdd_subset1(a, i)`, `zdd_subset0(a, i)`, `zdd_change(a, i)`, `zdd_ite(i, t, e)`
- Utilities: `zdd_count(node)` (ZDD-specific), unified utilities work too: `dag_size`, `node_index`, `isconstant`
- Child accessors: unified with BDD: `then_node(node)`, `else_node(node)`, `then_ptr(node)`, `else_ptr(node)`
- Conversion: `bdd_to_zdd`, `zdd_to_bdd`

### Visualization
- `to_dot(node; title="BDD", varlabels=nothing, terminal_labels=["F","T"])` - generate DOT language representation for Graphviz (BDD)
- `to_dot(node; title="ZDD", varlabels=nothing, terminal_labels=["∅","B"])` - generate DOT language representation for Graphviz (ZDD)
- `to_dot(io, node; ...)` - write DOT representation to an IO stream

Example:
```julia
mgr = BDDManager(nvars=3)
v0 = var(mgr, 0)
v1 = var(mgr, 1)
f = bdd_and(v0, v1)

# Generate DOT string (default numeric labels)
dot_str = to_dot(f, title="My BDD")

# Use custom variable labels
dot_str2 = to_dot(f, title="x & y", varlabels=["x", "y", "z"])  # 1-based indexing

# Or write to file
open("graph.dot", "w") do io
    to_dot(io, f, title="My BDD")
end

# Render with Graphviz: dot -Tpng graph.dot -o graph.png
quit(mgr)
```

The generated graph shows:
- Variable nodes as circles labeled with index or custom label (no 'x' prefix)
- Terminal nodes as squares: T/F (BDD), ∅/B (ZDD)
- Then-edges (1-edges) as solid lines
- Else-edges (0-edges) as dashed lines

Notes:
- `varlabels` must not contain reserved terminal labels: for BDD `T`/`F`, for ZDD `∅`/`B` (collision is rejected).
- If `varlabels` is provided, it is 1-indexed (`varlabels[i+1]` is used for variable `i`).
- Node IDs in DOT use `node_id` semantics described above for stable visualization.

### Operators

#### BDD logical operators
- `a & b` → `bdd_and(a, b)`
- `a | b` → `bdd_or(a, b)`
- `a ⊻ b` → `bdd_xor(a, b)`
- `!a` → logical complement of `a` (via complemented edges)

Examples:
```julia
mgr = BDDManager(nvars=3)
x = var(mgr, 0)
y = var(mgr, 1)
z = var(mgr, 2)

f_and = x & y                 # same as bdd_and(x, y)
f_or  = x | y                 # same as bdd_or(x, y)
f_xor = x ⊻ y                 # same as bdd_xor(x, y)
f_not = !x                    # complement-edge (no refcount change)

# Compose operations
f = (x & y) | (!x & z)        # Shannon-style expression
println(minterms(f, 3))
quit(mgr)
```

#### ZDD set operators
- `union(a, b)` → `zdd_union(a, b)`
- `intersect(a, b)` → `zdd_intersect(a, b)`
- `setdiff(a, b)` → `zdd_diff(a, b)`
- Shorthands: `a + b` (union), `a * b` (intersection), `a - b` (difference)
- Unicode: `a ∪ b` (union), `a ∩ b` (intersection)

Examples:
```julia
zm = ZDDManager(nvars=4)
a = var(zm, 0)    # singleton {0}
b = var(zm, 1)    # singleton {1}
c = var(zm, 2)    # singleton {2}

u1 = union(a, b)  # { {0}, {1} }
u2 = a + c        # { {0}, {2} }
i1 = intersect(u1, u2)  # { {0} }
d1 = setdiff(u1, a)     # { {1} }

# Unicode convenience
u3 = a ∪ b
i2 = u3 ∩ c              # empty family
println(zdd_count(i2))
quit(zm)
```

### Resource Management
- `close!(node)` - explicitly release a node
- `quit(mgr)` - free manager resources

Tests
-----
Unit tests live in `test/`. If the native library is available, run the tests
from the project root with:

```bash
julia --project=. -e 'using Pkg; Pkg.test("MiniCUDD")'
```

Contributing
------------
- Issues and pull requests are welcome.
- Building native libraries can differ across environments; consider adding CI
	(GitHub Actions or a Docker-based runner) that sets up and builds CUDD for
	reproducible testing.

License
-------
This package is licensed under the MIT License. See the included `LICENSE`
file for the full text.

Author
------
Hiroyuki Okamura <okamu@hiroshima-u.ac.jp>

Notes
-----
This README was written from the package sources (`deps/build.jl`,
`src/MiniCUDD.jl`, `Project.toml`). Tell me if you want additional sections
such as API reference, examples, or CI configuration snippets.

CI hint
-------
If you want GitHub Actions to run tests, you can either:

- Build CUDD during the workflow (requires autoconf/automake/libtool and a
	C toolchain). This is reproducible but increases CI runtime.
- Provide prebuilt `libcudd` binaries for each runner and download them in
	the workflow. This is faster but requires maintaining binaries.

I can add a starter `.github/workflows/ci.yml` that attempts to build CUDD on
Linux and macOS. Tell me which approach you prefer and I will add the CI file.
