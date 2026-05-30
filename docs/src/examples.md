# Examples

The notebooks in `examples/` use lightweight synthetic micromagnetic-style data.
They are designed to be fast enough for documentation builds while preserving
the data shapes we expect from real Merrill.jl LEM/NEB workflows.

The GitHub Actions documentation workflow executes these notebooks and writes
rendered HTML into the documentation site. If you are building docs locally
without running the notebook rendering step, the embedded frames below may be
empty until the HTML files are generated.

## Running Locally

From the package root:

```julia
using Pkg
Pkg.activate("examples")
Pkg.develop(path=".")
Pkg.instantiate()
```

Then open the notebooks in Jupyter, VS Code, or another notebook frontend.

## Synthetic Micromagnetic Landscape

Source notebook:
[`examples/01_synthetic_micromagnetic_landscape.ipynb`](https://github.com/yimingzhang/DisconnectivityGraphs.jl/blob/main/examples/01_synthetic_micromagnetic_landscape.ipynb)

This example constructs synthetic LEM-like minima, NEB-like saddles, an
interactive disconnectivity tree, and a PlotlyJS 3D cone visualization of
magnetization textures.

```@raw html
<p><a class="notebook-link" href="assets/notebooks/01_synthetic_micromagnetic_landscape.html">Open rendered notebook in a full page</a></p>
<iframe class="notebook-frame" src="assets/notebooks/01_synthetic_micromagnetic_landscape.html" title="Rendered synthetic micromagnetic landscape notebook"></iframe>
```

## Temperature-Field Schedule Demo

Source notebook:
[`examples/02_temperature_field_schedule_demo.ipynb`](https://github.com/yimingzhang/DisconnectivityGraphs.jl/blob/main/examples/02_temperature_field_schedule_demo.ipynb)

This example pairs the same landscape concept with a synthetic t-T-B history,
field-adjusted barrier matrices, relaxation-time heatmaps, and a compact
probability evolution demonstration.

```@raw html
<p><a class="notebook-link" href="assets/notebooks/02_temperature_field_schedule_demo.html">Open rendered notebook in a full page</a></p>
<iframe class="notebook-frame" src="assets/notebooks/02_temperature_field_schedule_demo.html" title="Rendered temperature-field schedule notebook"></iframe>
```
