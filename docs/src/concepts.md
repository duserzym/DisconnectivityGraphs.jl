# Concepts

Disconnectivity graphs summarize how local minima merge into basins as the
allowed saddle energy increases. They are useful when a transition matrix is too
large to interpret directly, but the physical question depends on which states
are separated by high barriers.

## Plain-Language Picture

An intuitive way to think about a disconnectivity graph is to imagine flooding a
mountain landscape with water:

1. Each local minimum is a valley where water first collects.
2. Each saddle is a mountain pass between two valleys.
3. As the water level rises, isolated lakes remain separate until the water
   reaches a pass.
4. The moment two lakes first touch, their basins merge.
5. The disconnectivity tree records those first merge events as branch points at
   the corresponding energy.

So the graph is not trying to draw every path through state space. It is a
compact answer to a simpler question: how high in energy do you have to climb
before two families of states can communicate?

This is why the vertical height of a branch matters so much:

- low merge height means the states are easily connected;
- high merge height means the states are kinetically isolated for longer;
- a deep subtree means there is a whole family of states that mix with one
  another before they connect to the rest of the landscape.

## Landscape Model

The package uses three core records:

- [`Minimum`](@ref): a local minimum with an id, energy, and metadata.
- [`Saddle`](@ref): a transition-state connection between two minima.
- [`LandscapeGraph`](@ref): a validated sparse network of minima and saddles.

Metadata is deliberately flexible. For micromagnetic workflows, a minimum can
carry a net magnetic moment, the path to a saved node-magnetization state, the
temperature at which it was relaxed, and minimizer diagnostics. A saddle can
carry NEB convergence information, the saddle image index, reaction-coordinate
profiles, or directed forward/reverse barrier estimates.

## Merge-Tree Construction

The disconnectivity tree is built by a Kruskal-style union-find algorithm:

1. Start with every local minimum as an isolated leaf.
2. Sort saddle connections from low to high energy.
3. Add saddles one by one.
4. Whenever a saddle first connects two disconnected components, create a new
   branch node at that saddle energy.
5. Continue until all sampled minima are connected, or create a final artificial
   root for disconnected sampled landscapes.

This is an exact merge tree for the sampled graph. It is independent of plotting
backend and does not require a gridded energy surface.

The artificial root deserves special treatment: it is a bookkeeping device, not
a physical transition state. It appears only when the sampled transition network
is disconnected and the package is asked to keep the result plottable. Use
[`has_synthetic_root`](@ref) to detect that case explicitly.

The implementation is also intentionally strict about ambiguous inputs:

- one representative saddle is required for each undirected minimum pair;
- duplicate saddles are rejected instead of being silently chosen;
- equal-energy saddles are ordered deterministically, so the same sampled
  landscape produces the same left-to-right tree regardless of input ordering.

## Execution Sketch

The plain-language flooding picture is useful, but the implementation is more
precise than that metaphor. The tree builder is essentially Kruskal's algorithm
applied to the sampled transition network, with extra bookkeeping so the output
is a tree rather than just a connected-component labeling.

At runtime, the algorithm maintains these structures:

- `uf`: a union-find over minimum indices;
- `nodes`: the output tree nodes, starting with one leaf per minimum;
- `component_node[root]`: the current tree node representing each connected
  component;
- `component_minima[root]`: the minima already absorbed into that component;
- `component_anchor[root]`: a deterministic tie-break anchor used to keep left
  and right child ordering stable.

The execution is best read as this pseudocode:

```text
function disconnectivity_tree(landscape)
   create one leaf node for each minimum
   initialize union-find with one component per minimum
   initialize component_node[root] = leaf node id
   initialize component_minima[root] = [minimum id]
   initialize component_anchor[root] = minimum index

   saddles = sort by (saddle energy, lower endpoint index, higher endpoint index)

   for saddle in saddles
      ri = find_root(endpoint i)
      rj = find_root(endpoint j)

      if ri == rj
         continue
      end

      left_root, right_root = roots ordered by component_anchor
      merged_minima = component_minima[left_root] + component_minima[right_root]

      create internal tree node at saddle.energy
         with children = [component_node[left_root], component_node[right_root]]
         and minima = merged_minima

      new_root = union(ri, rj)
      component_node[new_root] = new internal node id
      component_minima[new_root] = merged_minima
      component_anchor[new_root] = min(component_anchor[ri], component_anchor[rj])
   end

   if only one union-find component remains
      return tree rooted at that component's current node
   else if link_disconnected == :error
      raise an error
   else
      create a synthetic root at the highest sampled energy
      attach one child for each disconnected component
      return the tree with synthetic root
   end
end
```

There are two implementation details worth emphasizing:

1. A saddle only creates a branch if it is the first saddle that connects two
previously separate components. Saddles inside an already-connected basin are
ignored because they do not change the merge hierarchy.
2. Equal-energy saddles are not left to input order alone. The algorithm sorts
them with a deterministic secondary key and orders merged children by
`component_anchor`, so repeated runs produce the same branch geometry.

This leads to the expected complexity profile: sorting saddles costs
$O(E \log E)$, while the union-find operations are effectively near-constant
amortized time. The result is an exact disconnectivity tree for the sampled
graph, not an approximate clustering heuristic.

## Threshold Components

[`component_partition`](@ref) is a diagnostic companion to the merge tree. At a
chosen energy threshold, it reports which minima are connected by saddles below
that threshold. This gives a simple way to check the tree structure and to
compare with level-based disconnectivity graph implementations.

## Micromagnetic Interpretation

For micromagnetics, the same flooding picture still works, but the objects are
more concrete:

1. A minimum is a metastable magnetization texture or domain state.
2. A saddle is the NEB transition state that must be crossed to move from one
   magnetization state to another.
3. A high branch means thermal activation has to cross a large barrier, so the
   state is long-lived.
4. A low branch means the system can reshuffle between those states relatively
   easily.

This makes disconnectivity graphs useful for more than visual appeal. They show
which magnetic states belong to the same basin family, which bottlenecks control
reversal, and which parts of the landscape are likely to matter on laboratory or
geologic timescales.

For Merrill.jl-style data, minima are local energy minimum magnetization states
and saddles are NEB transition states between those LEM states. Directed
thermal-activation barriers can differ from state `i -> j` and `j -> i`, while a
disconnectivity graph normally needs an absolute saddle energy. The planned
adapter layer will preserve both:

- absolute saddle energy for landscape topology;
- directed barriers for transition matrices and relaxation times.

This separation is important for paleointensity-reversal work. The same
landscape can be viewed in zero field, under a selected field correction, or as
a temperature-dependent sequence of landscapes used by t-T-B probability
integration.

In that setting, the graph helps answer questions like these:

- which magnetization states are effectively trapped at a given temperature;
- which barrier is the real bottleneck for reversal;
- whether an applied field merely tilts energies slightly or fundamentally
   rewires the accessible pathways.

## Plotting Geometry

[`tree_layout`](@ref) returns line segments and leaf positions rather than a
finished plot. PlotlyJS, Makie, Plots.jl, or a publication renderer can then
draw the same tree with different styling. The notebooks in [Examples](@ref)
use this API for interactive PlotlyJS figures.
