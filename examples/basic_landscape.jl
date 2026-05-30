using DisconnectivityGraphs

minima = [
    Minimum(:state1, 0.0; metadata=Dict(:moment => [1.0, 0.0, 0.0])),
    Minimum(:state2, 0.7; metadata=Dict(:moment => [-1.0, 0.0, 0.0])),
    Minimum(:state3, 1.2; metadata=Dict(:moment => [0.0, 1.0, 0.0])),
]

saddles = [
    Saddle(:state1, :state2, 4.1; metadata=Dict(:neb_converged => true)),
    Saddle(:state2, :state3, 5.8; metadata=Dict(:neb_converged => true)),
]

landscape = LandscapeGraph(minima, saddles)
tree = disconnectivity_tree(landscape)

@show component_partition(landscape, 4.5)
@show leaf_order(tree)
