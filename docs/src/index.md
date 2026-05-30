```@raw html
<section class="dg-hero">
  <div>
    <h1>DisconnectivityGraphs.jl</h1>
    <p>Energy landscape trees for sparse minima-transition-state networks, designed for Julia workflows and micromagnetic LEM/NEB data.</p>
  </div>
  <img class="dg-logo" src="assets/logo.svg" alt="DisconnectivityGraphs.jl logo">
</section>
```

`DisconnectivityGraphs.jl` builds disconnectivity trees from local minima and
transition-state saddles. The core package is intentionally small: it validates
landscape networks, constructs exact merge trees, computes threshold-connected
components, and returns backend-independent plotting geometry.

The first target application is micromagnetic modeling, especially Merrill.jl
workflows where local energy minima, NEB barriers, magnetic moments, and
temperature-field schedules are assembled into transition matrices.

```@raw html
<div class="dg-card-grid">
  <div class="dg-card">
    <h3>Generic Core</h3>
    <p>Minima, saddles, sparse landscape graphs, merge trees, and layout segments without plotting dependencies.</p>
  </div>
  <div class="dg-card">
    <h3>Micromagnetic Ready</h3>
    <p>Metadata fields can carry grain ids, moments, mesh paths, NEB diagnostics, and transition profiles.</p>
  </div>
  <div class="dg-card">
    <h3>Interactive Examples</h3>
    <p>PlotlyJS notebooks demonstrate synthetic LEM states, t-T-B histories, barrier matrices, and probability flow.</p>
  </div>
</div>
```

## Quick Start

```julia
using DisconnectivityGraphs

minima = [
    Minimum(:A, 0.0),
    Minimum(:B, 1.0),
    Minimum(:C, 3.0),
]

saddles = [
    Saddle(:A, :B, 5.0),
    Saddle(:B, :C, 8.0),
]

landscape = LandscapeGraph(minima, saddles)
tree = disconnectivity_tree(landscape)
layout = tree_layout(tree)
component_partition(landscape, 6.0)
```

## Site Guide

- [Concepts](@ref) explains the data model, merge-tree construction, and
  micromagnetic interpretation.
- [API](@ref) lists the public Julia interfaces.
- [Examples](@ref) embeds rendered notebook demonstrations and links to their
  source notebooks.
