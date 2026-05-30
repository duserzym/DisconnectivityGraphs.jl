"""
    TreeSegment

A backend-independent line segment used to draw a disconnectivity tree. `kind`
is `:branch` for vertical branch segments and `:merge` for horizontal merge
segments.
"""
struct TreeSegment{T<:Real}
    x0::Float64
    y0::T
    x1::Float64
    y1::T
    kind::Symbol
    node::Int
end

"""
    TreeLayout

Plotting geometry returned by [`tree_layout`](@ref), including node positions,
leaf positions keyed by minimum id, and drawable tree line segments.
"""
struct TreeLayout{I,T<:Real}
    x::Dict{Int,Float64}
    y::Dict{Int,T}
    leaf_positions::Dict{I,Float64}
    segments::Vector{TreeSegment{T}}
end

"""
    tree_layout(tree; order=leaf_order(tree), leaf_spacing=1.0)

Compute backend-independent line segments for plotting a disconnectivity tree.
The returned `TreeLayout` can be consumed by PlotlyJS, Makie, Plots, or a custom
publication renderer.
"""
function tree_layout(tree::DisconnectivityTree{I,T};
                     order::AbstractVector{I}=leaf_order(tree),
                     leaf_spacing::Real=1.0) where {I,T}
    length(order) == length(tree.leaf_for_minimum) ||
        error("order must include every minimum exactly once")
    Set(order) == Set(keys(tree.leaf_for_minimum)) ||
        error("order must include every minimum exactly once")

    x = Dict{Int,Float64}()
    y = Dict{Int,T}()
    leaf_positions = Dict{I,Float64}()
    spacing = Float64(leaf_spacing)

    for (position, minimum_id) in pairs(order)
        node_id = tree.leaf_for_minimum[minimum_id]
        xpos = (position - 1) * spacing
        x[node_id] = xpos
        y[node_id] = tree.nodes[node_id].energy
        leaf_positions[minimum_id] = xpos
    end

    function place_internal!(node_id)
        node = tree.nodes[node_id]
        y[node_id] = node.energy
        if isempty(node.children)
            return x[node_id]
        end
        child_x = [place_internal!(child) for child in node.children]
        x[node_id] = sum(child_x) / length(child_x)
        return x[node_id]
    end

    place_internal!(tree.root)

    segments = TreeSegment{T}[]
    function add_segments!(node_id)
        node = tree.nodes[node_id]
        isempty(node.children) && return nothing
        child_x = [x[child] for child in node.children]
        push!(segments, TreeSegment{T}(minimum(child_x), node.energy,
                                       maximum(child_x), node.energy,
                                       :merge, node_id))
        for child in node.children
            push!(segments, TreeSegment{T}(x[child], y[child],
                                           x[child], node.energy,
                                           :branch, child))
            add_segments!(child)
        end
        return nothing
    end
    add_segments!(tree.root)

    return TreeLayout{I,T}(x, y, leaf_positions, segments)
end
