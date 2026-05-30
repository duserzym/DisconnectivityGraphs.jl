# DisconnectivityGraphs.jl Documentation

This folder contains the Documenter.jl website source. The site includes the
package introduction, conceptual guide, public API, and rendered notebook
examples.

## Build Locally

From the package root:

```julia
using Pkg
Pkg.activate("docs")
Pkg.develop(path=".")
Pkg.instantiate()
```

Then run:

```bash
julia --project=docs docs/make.jl
```

The GitHub Actions workflow executes the notebooks with `nbconvert` before
building the site, so the deployed documentation contains static rendered HTML
versions of the examples.
