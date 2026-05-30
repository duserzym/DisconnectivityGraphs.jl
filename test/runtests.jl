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

@testset "deterministic tie handling" begin
    minima = [
        Minimum(:A, 0.0),
        Minimum(:B, 1.0),
        Minimum(:C, 2.0),
    ]
    saddles1 = [
        Saddle(:C, :A, 4.0),
        Saddle(:B, :C, 4.0),
        Saddle(:A, :B, 4.0),
    ]
    saddles2 = reverse(saddles1)

    tree1 = disconnectivity_tree(LandscapeGraph(minima, saddles1))
    tree2 = disconnectivity_tree(LandscapeGraph(minima, saddles2))

    @test leaf_order(tree1) == [:A, :B, :C]
    @test leaf_order(tree2) == [:A, :B, :C]
    @test tree1.nodes[tree1.root].energy == 4.0
    @test tree2.nodes[tree2.root].energy == 4.0
end

@testset "disconnected landscapes" begin
    landscape = LandscapeGraph(
        [Minimum(:A, 0.0), Minimum(:B, 1.0)],
        Saddle{Symbol,Float64}[],
    )

    tree = disconnectivity_tree(landscape)

    @test has_synthetic_root(tree)
    @test tree.nodes[tree.root].synthetic
    @test tree.nodes[tree.root].energy == 1.0
    @test_throws ErrorException disconnectivity_tree(landscape; link_disconnected=:error)
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
    @test_throws ErrorException LandscapeGraph(
        [Minimum(:A, 0.0), Minimum(:B, 1.0)],
        [Saddle(:A, :B, 2.0), Saddle(:B, :A, 2.0)],
    )
    @test_throws ErrorException LandscapeGraph(
        [Minimum(:A, 0.0), Minimum(:B, 1.0)],
        [Saddle(:A, :B, 2.0), Saddle(:A, :B, 3.0)],
    )
end
