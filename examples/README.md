# Interactive Examples

These notebooks use lightweight synthetic micromagnetic-style data. They do not
run Merrill.jl minimization or NEB. Instead, they mimic the output structure we
expect from real LEM/NEB workflows: minima with magnetic moments, saddle
energies, barrier matrices, and field/temperature schedules.

Before running a notebook from this directory:

```julia
using Pkg
Pkg.activate(".")
Pkg.develop(path="..")
Pkg.instantiate()
```

Notebooks:

- `01_synthetic_micromagnetic_landscape.ipynb`: synthetic LEM states,
  disconnectivity tree, and interactive 3D cone visualizations.
- `02_temperature_field_schedule_demo.ipynb`: synthetic t-T-B schedule,
  field-adjusted transition barriers, relaxation-time heatmaps, and probability
  evolution.
