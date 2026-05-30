# DisconnectivityGraphs.jl

Generic Julia tools for building disconnectivity trees from minima-transition
state networks. The package is intended to support micromagnetic energy
landscapes from Merrill.jl/NEB workflows, while keeping the core data model
usable for other systems.

The current package skeleton includes:

- typed `Minimum`, `Saddle`, and `LandscapeGraph` containers;
- validation of endpoint consistency and duplicate minima;
- an exact Kruskal-style merge-tree builder;
- energy-threshold component partitions for algorithm checks.
- backend-independent tree layout segments for interactive/static plotting.

## Development Example

```julia
using DisconnectivityGraphs

minima = [Minimum(:A, 0.0), Minimum(:B, 1.0), Minimum(:C, 3.0)]
saddles = [Saddle(:A, :B, 5.0), Saddle(:B, :C, 8.0)]
landscape = LandscapeGraph(minima, saddles)

tree = disconnectivity_tree(landscape)
component_partition(landscape, 6.0)
```

## Micromagnetic Direction

The first Merrill.jl-facing adapter should ingest the multistate outputs in
`PINT_with_reversal/code/reversal_paleointensity_probability/fabian05_results`:

- basis/state tables as minima with energies, net moments, and mesh metadata;
- all-pair NEB summaries/profiles as saddle records;
- field-adjusted barriers and relaxation-time matrices as parallel views of the
  same network.

See `roadmap.md` for the execution plan.

## Interactive Notebooks

The `examples/` folder contains PlotlyJS notebooks with synthetic
micromagnetic-style landscapes. They are meant to exercise the package API and
visualization direction without requiring Merrill.jl minimization or NEB runs.
