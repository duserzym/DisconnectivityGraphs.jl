# DisconnectivityGraphs.jl Documentation Notes

This folder is reserved for package documentation and publication-facing
examples. The current package is intentionally light: the core algorithms have
no plotting dependencies, while interactive demos live in `examples/` with their
own Julia environment.

## Recommended Local Workflow

From the package root:

```julia
using Pkg
Pkg.activate("examples")
Pkg.develop(path=".")
Pkg.instantiate()
```

Then open the notebooks in `examples/` with Jupyter or VS Code.

## Planned Documentation Pages

- Energy landscape data model.
- Disconnectivity tree derivation and relation to energy-threshold components.
- Merrill.jl/NEB adapter guide.
- PlotlyJS interactive recipes.
- Publication figure gallery for paleointensity-reversal workflows.
