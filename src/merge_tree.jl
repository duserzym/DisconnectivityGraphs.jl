"""
    DisconnectivityNode

A node in a disconnectivity merge tree. Leaf nodes represent minima and internal
nodes represent the saddle energy at which child basins merge.
"""
struct DisconnectivityNode{I,T<:Real}
    id::Int
    energy::T
    children::Vector{Int}
    minima::Vector{I}
end

"""
    DisconnectivityTree

The merge tree returned by [`disconnectivity_tree`](@ref). `root` indexes the
top node in `nodes`, and `leaf_for_minimum` maps each minimum id to its leaf.
"""
struct DisconnectivityTree{I,T<:Real}
    nodes::Vector{DisconnectivityNode{I,T}}
    root::Int
    leaf_for_minimum::Dict{I,Int}
end

mutable struct UnionFind
    parent::Vector{Int}
    rank::Vector{Int}
end

UnionFind(n::Integer) = UnionFind(collect(1:Int(n)), zeros(Int, Int(n)))

function find_root!(uf::UnionFind, x::Integer)
    xi = Int(x)
    parent = uf.parent[xi]
    if parent != xi
        uf.parent[xi] = find_root!(uf, parent)
    end
    return uf.parent[xi]
end

function union_roots!(uf::UnionFind, a::Integer, b::Integer)
    ra = find_root!(uf, a)
    rb = find_root!(uf, b)
    ra == rb && return ra
    if uf.rank[ra] < uf.rank[rb]
        uf.parent[ra] = rb
        return rb
    elseif uf.rank[ra] > uf.rank[rb]
        uf.parent[rb] = ra
        return ra
    else
        uf.parent[rb] = ra
        uf.rank[ra] += 1
        return ra
    end
end

"""
    disconnectivity_tree(landscape; link_disconnected=:root)

Build an exact merge tree by adding saddles from low to high energy. The method
is the same connectivity idea used by disconnectivity graph codes such as pele:
minima start as isolated leaves, and every saddle that first connects two
previously disconnected basins creates a new branch node at the saddle energy.

Set `link_disconnected=:error` to reject disconnected transition networks.
The default, `:root`, creates a final artificial root at the highest available
energy so partially sampled landscapes can still be visualized.
"""
function disconnectivity_tree(landscape::LandscapeGraph{I,T};
                              link_disconnected::Symbol=:root) where {I,T}
    n = length(landscape.minima)
    uf = UnionFind(n)
    nodes = DisconnectivityNode{I,T}[]
    leaf_for_minimum = Dict{I,Int}()

    for (i, minimum) in pairs(landscape.minima)
        node = DisconnectivityNode{I,T}(i, minimum.energy, Int[], [minimum.id])
        push!(nodes, node)
        leaf_for_minimum[minimum.id] = i
    end

    component_node = collect(1:n)
    component_minima = [[minimum.id] for minimum in landscape.minima]
    sorted_saddles = sort(landscape.saddles; by=saddle_energy)

    for saddle in sorted_saddles
        i = landscape.index[saddle.from]
        j = landscape.index[saddle.to]
        ri = find_root!(uf, i)
        rj = find_root!(uf, j)
        ri == rj && continue

        minima = vcat(component_minima[ri], component_minima[rj])
        node_id = length(nodes) + 1
        children = [component_node[ri], component_node[rj]]
        push!(nodes, DisconnectivityNode{I,T}(node_id, saddle.energy, children, minima))

        new_root = union_roots!(uf, ri, rj)
        component_node[new_root] = node_id
        component_minima[new_root] = minima
    end

    roots = unique(find_root!(uf, i) for i in 1:n)
    if length(roots) == 1
        root = component_node[only(roots)]
        return DisconnectivityTree{I,T}(nodes, root, leaf_for_minimum)
    end

    link_disconnected == :error && error("landscape transition network is disconnected")
    link_disconnected == :root || error("unknown link_disconnected policy: $link_disconnected")

    highest_minimum = maximum(minimum.energy for minimum in landscape.minima)
    highest_saddle = isempty(landscape.saddles) ? highest_minimum :
                     maximum(saddle.energy for saddle in landscape.saddles)
    root_energy = max(highest_minimum, highest_saddle)
    children = [component_node[root] for root in roots]
    minima = reduce(vcat, (component_minima[root] for root in roots))
    root = length(nodes) + 1
    push!(nodes, DisconnectivityNode{I,T}(root, root_energy, children, minima))
    return DisconnectivityTree{I,T}(nodes, root, leaf_for_minimum)
end

"""
    component_partition(landscape, threshold)

Return the connected components of minima using only saddles with
`saddle.energy <= threshold`.
"""
function component_partition(landscape::LandscapeGraph{I,T},
                             threshold::Real) where {I,T}
    n = length(landscape.minima)
    uf = UnionFind(n)
    for saddle in landscape.saddles
        saddle.energy <= threshold || continue
        union_roots!(uf, landscape.index[saddle.from], landscape.index[saddle.to])
    end

    groups = Dict{Int,Vector{I}}()
    ordered_roots = Int[]
    for (i, minimum) in pairs(landscape.minima)
        root = find_root!(uf, i)
        haskey(groups, root) || push!(ordered_roots, root)
        push!(get!(groups, root, I[]), minimum.id)
    end
    return [groups[root] for root in ordered_roots]
end

"""
    leaf_order(tree)

Return leaf minimum ids in the left-to-right order induced by the tree.
"""
function leaf_order(tree::DisconnectivityTree{I,T}) where {I,T}
    out = I[]
    function visit(node_id)
        node = tree.nodes[node_id]
        if isempty(node.children)
            push!(out, only(node.minima))
        else
            for child in node.children
                visit(child)
            end
        end
    end
    visit(tree.root)
    return out
end
