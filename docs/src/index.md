# DisconnectivityGraphs.jl

`DisconnectivityGraphs.jl` builds disconnectivity trees from sparse networks of
local minima and transition-state saddles.

The package separates three layers:

1. Core graph construction: minima, saddles, validation, merge trees, and line
   segment layouts.
2. Optional visualization: PlotlyJS notebooks now; Makie/PlotlyJS recipes later.
3. Domain adapters: Merrill.jl micromagnetic LEM/NEB outputs, transition
   matrices, and t-T-B probability schedules.

The first demonstrations are in `examples/`.
