# DisconnectivityGraphs.jl Roadmap

## Purpose

Build a standalone Julia package for disconnectivity graphs and related energy
landscape visualizations, with a clean generic core and first-class support for
micromagnetic LEM/NEB data from Merrill.jl.

The immediate scientific driver is the multi-state transition-matrix problem in
`PINT_with_reversal/code/reversal_paleointensity_probability`: we need a clear
way to see how many local energy minima exist, which saddles connect them, and
which barriers dominate the probability flow during t-T-B histories.

## Design Principles

- Keep the core package independent of Merrill.jl, PlotlyJS, and notebooks.
- Represent the physical network explicitly: minima, saddle connections,
  energies, directed barriers, moments, path metadata, and convergence metadata.
- Treat micromagnetic workflows as adapters on top of a general landscape model.
- Preserve units and provenance. Energies may be joules, shifted joules, kBT, or
  free energies, but plots and constructors must label units explicitly.
- Prefer sparse algorithms. Publication runs may include many grains, many
  temperatures, and incomplete all-pair NEB networks.
- Make every visualization reproducible from tabular records saved by notebooks
  or batch jobs.

## Reference Implementations Reviewed

- `pele-python/pele`: useful model of minima plus transition states and a
  Kruskal-like connectivity merge tree. The Julia package should borrow the
  algorithmic idea, not the database assumptions.
- `IBM/topography-searcher`: useful separation of kinetic transition networks,
  graph analysis, and plotting. Its threshold-component approach is a good
  validation view for our merge tree.
- `lsmeeton/pyconnect` and bundled `disconnectionDPS`: useful legacy workflow
  for level-based basin assignment, pruning, and publication-style static
  diagrams. The file-format assumptions are too chemical-system-specific for
  direct reuse.

## Current MVP

- [x] Create package scaffold.
- [x] Add `Minimum`, `Saddle`, and `LandscapeGraph` containers.
- [x] Validate unique minima and saddle endpoint consistency.
- [x] Build an exact merge tree from saddle energies.
- [x] Add threshold component partitions for algorithm sanity checks.
- [x] Add unit tests for a three-state toy landscape.

## Phase 1: Core Landscape Model

- [ ] Add explicit `EnergyUnit` metadata or a lightweight unit-label field.
- [ ] Add directed barrier representation:
  - `barrier_forward`;
  - `barrier_reverse`;
  - absolute saddle energy inferred from minima energies and directed barriers;
  - policy for asymmetric/noisy barriers from unconverged NEB paths.
- [ ] Add optional path/profile storage for NEB reaction coordinates.
- [ ] Add basin pruning:
  - by energy threshold;
  - by minimum occupancy/probability;
  - by moment similarity;
  - by user-provided state labels.
- [ ] Add diagnostics for disconnected landscapes, duplicate saddles, and
  inconsistent directed barrier pairs.

## Phase 2: Layout and Plotting

- [ ] Implement deterministic leaf ordering:
  - by minimum energy;
  - by supplied order;
  - by net moment projection onto field direction;
  - by basin hierarchy;
  - by spectral or barycentric graph ordering for complex networks.
- [ ] Implement line-segment extraction independent of plotting backend.
- [ ] Add a Makie recipe for static publication figures.
- [ ] Add a PlotlyJS backend for notebook interactivity.
- [ ] Add export helpers for SVG, PDF, PNG, and HTML.
- [ ] Add optional overlays:
  - minima labels;
  - state probabilities;
  - net moment arrows or polarity colors;
  - NEB convergence flags;
  - active transition paths under a selected t-T-B schedule.

## Phase 3: Merrill.jl Adapter

- [ ] Add a small extension package or optional module for Merrill outputs.
- [ ] Ingest Merrill `NEBResult` values:
  - endpoint state ids;
  - forward/reverse barriers;
  - saddle index and saddle image;
  - reaction coordinate and energy profile;
  - convergence status and force traces.
- [ ] Ingest Merrill thermal-activation matrices:
  - `TransitionBarrier`;
  - `barrier_matrix`;
  - `field_adjusted_barrier_matrix`;
  - `transition_rate_matrix`;
  - relaxation-time matrices.
- [ ] Add adapters for `fabian05_results` in `PINT_with_reversal`:
  - basis CSVs;
  - state CSVs;
  - barrier CSVs;
  - NEB profile CSVs;
  - probability trace CSVs.
- [ ] Preserve micromagnetic metadata:
  - grain id;
  - mesh path;
  - temperature;
  - field vector;
  - magnetic moment;
  - helicity/vortex diagnostics;
  - minimizer and convergence details.

## Phase 4: Multi-Temperature and Field-Adjusted Landscapes

- [ ] Add `LandscapeSchedule` for landscapes sampled across temperature and
  field values.
- [ ] Support interpolation of minima energies, moments, and barriers across
  temperature, matching the Fabian-style integration code.
- [ ] Display a family of disconnectivity graphs across temperature.
- [ ] Add "field-adjusted disconnectivity graph" views for selected field
  directions and intensities.
- [ ] Add relaxation-time y-axis transforms:
  - barrier energy;
  - E/kBT;
  - log10 relaxation time in seconds/years/Myr/Gyr.

## Phase 5: Probability-Flow Integration Views

- [ ] Link a Markov generator to a landscape graph.
- [ ] Plot transition matrices beside disconnectivity graphs.
- [ ] Overlay final or time-dependent occupancy on minima.
- [ ] Animate a t-T-B path through the landscape:
  - temperature axis;
  - field vector;
  - occupied basins;
  - dominant transition bottlenecks.
- [ ] Provide visual checks for stable-field versus reversal-field histories.

## Phase 6: Performance

- [ ] Keep merge-tree construction `O(E log E)` with union-find.
- [ ] Support sparse saddle networks without requiring all-pair NEB paths.
- [ ] Add streaming/table iterators for large CSV batches.
- [ ] Add tests with 100-grain Nikolaisen-style result sets.
- [ ] Benchmark large networks and many temperature slices.

## Phase 7: Validation

- [ ] Reproduce toy landscapes with known merge order.
- [ ] Cross-check threshold partitions against merge-tree branch structure.
- [ ] Compare selected examples against pele/topography-searcher outputs.
- [ ] Validate Merrill adapters on PLAG158/PLAG163 multistate outputs.
- [ ] Add regression tests using small frozen CSV fixtures.

## Phase 8: Publication Figures

- [ ] Figure: representative grain 3D state grid plus disconnectivity graph.
- [ ] Figure: energy-barrier matrix and relaxation-time matrix.
- [ ] Figure: probability flow through stable-field and reversal-field t-T-B
  histories.
- [ ] Figure: ensemble final polarity distribution showing weak apparent
  remanence after reversal cooling despite strong pre- and post-reversal fields.
- [ ] Figure: sensitivity to peak field strength within 10-100 microtesla.

## Open Scientific Decisions

- How to represent a saddle when forward and reverse NEB barriers imply slightly
  different absolute saddle energies.
- Whether to plot zero-field, field-adjusted, or temperature-adjusted landscapes
  as the default for paleointensity arguments.
- How aggressively to prune high-energy or poorly converged states without
  hiding physically important transition routes.
- Whether the publication figures should emphasize individual-grain energy
  landscapes, ensemble probability distributions, or both equally.

## First Integration Target

Use the existing outputs in:

```text
PINT_with_reversal/code/reversal_paleointensity_probability/fabian05_results
```

Start with a representative grain that already has multiple LEM states and
all-pair NEB profiles. Build a `LandscapeGraph`, compare the disconnectivity
tree to the transition-barrier matrix in notebook 05, and then use the same
object in notebook 06 manuscript-sensitivity plots.
