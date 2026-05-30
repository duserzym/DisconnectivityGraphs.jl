# Concepts

Disconnectivity graphs summarize how local minima merge into basins as the
allowed saddle energy increases. They are useful when a transition matrix is too
large to interpret directly, but the physical question depends on which states
are separated by high barriers.

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

## Threshold Components

[`component_partition`](@ref) is a diagnostic companion to the merge tree. At a
chosen energy threshold, it reports which minima are connected by saddles below
that threshold. This gives a simple way to check the tree structure and to
compare with level-based disconnectivity graph implementations.

## Micromagnetic Interpretation

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

## Plotting Geometry

[`tree_layout`](@ref) returns line segments and leaf positions rather than a
finished plot. PlotlyJS, Makie, Plots.jl, or a publication renderer can then
draw the same tree with different styling. The notebooks in [Examples](@ref)
use this API for interactive PlotlyJS figures.
