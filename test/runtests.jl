using Test
using DisconnectivityGraphs

@testset "disconnectivity tree" begin
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

    @test minimum_ids(landscape) == [:A, :B, :C]
    @test length(tree.nodes) == 5
    @test tree.nodes[tree.root].energy == 8.0
    @test tree.nodes[tree.root].children == [4, 3]
    @test tree.nodes[4].energy == 5.0
    @test Set(leaf_order(tree)) == Set([:A, :B, :C])

    layout = tree_layout(tree; order=[:A, :B, :C])
    @test layout.leaf_positions[:A] == 0.0
    @test layout.leaf_positions[:C] == 2.0
    @test length(layout.segments) == 6
end

@testset "threshold partitions" begin
    landscape = LandscapeGraph(
        [Minimum(:A, 0.0), Minimum(:B, 1.0), Minimum(:C, 3.0)],
        [Saddle(:A, :B, 5.0), Saddle(:B, :C, 8.0)],
    )

    @test Set.(component_partition(landscape, 4.0)) == Set.([[:A], [:B], [:C]])
    @test Set.(component_partition(landscape, 6.0)) == Set.([[:A, :B], [:C]])
    @test Set.(component_partition(landscape, 9.0)) == Set.([[:A, :B, :C]])
end

@testset "validation" begin
    @test_throws ErrorException LandscapeGraph(
        [Minimum(:A, 0.0), Minimum(:A, 1.0)],
        Saddle{Symbol,Float64}[],
    )
    @test_throws ErrorException LandscapeGraph(
        [Minimum(:A, 0.0)],
        [Saddle(:A, :B, 2.0)],
    )
end
