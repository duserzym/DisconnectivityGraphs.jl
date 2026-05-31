"""
    TreeSegment

A backend-independent line segment used to draw a disconnectivity tree.
Rectangular layouts use `:branch` for vertical branch segments and `:merge` for
horizontal merge segments. Sloped layouts use `:sloped_branch` for child-parent
branches and `:merge_cap` for optional short merge-energy caps.
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
    EnergyScale

Piecewise-linear display transform for disconnectivity plots. The transform is
identity-like for compact landscapes, and compresses one unusually large energy
gap when the tree would otherwise spend most of the vertical space on an empty
interval. Tick labels remain in the original energy units.
"""
struct EnergyScale
    data_min::Float64
    data_max::Float64
    split_low::Float64
    split_high::Float64
    lower_display_fraction::Float64
    gap_display_fraction::Float64
    compressed::Bool
end

function _finite_energy_values(values)
    finite = sort(unique(Float64(v) for v in values if isfinite(Float64(v))))
    isempty(finite) && error("energy values must contain at least one finite value")
    return finite
end

function _median_sorted(values::AbstractVector{<:Real})
    n = length(values)
    n > 0 || error("cannot take median of an empty vector")
    mid = (n + 1) ÷ 2
    return isodd(n) ? Float64(values[mid]) : 0.5 * (Float64(values[mid]) + Float64(values[mid + 1]))
end

"""
    smart_energy_scale(values; lower_display_fraction=0.72, gap_display_fraction=0.06,
                       min_gap_fraction=0.25, gap_factor=3.0,
                       compress_top_gap=true)

Build an [`EnergyScale`](@ref) from the energy distribution. If a single gap is
both a substantial fraction of the full energy range and much larger than the
typical gap, that empty interval is compressed in display coordinates. This is
useful for disconnectivity trees with tightly clustered minima and a very high
top-level merge. By default, a dominant top gap is compressible because it
usually represents empty barrier height between the last local basin merger and
the final merger rather than additional minima.
"""
function smart_energy_scale(values;
                            lower_display_fraction::Real=0.72,
                            gap_display_fraction::Real=0.06,
                            min_gap_fraction::Real=0.25,
                            gap_factor::Real=3.0,
                            compress_top_gap::Bool=true)
    finite = _finite_energy_values(values)
    data_min = first(finite)
    data_max = last(finite)
    data_max > data_min || return EnergyScale(data_min, data_max, data_max, data_max,
        Float64(lower_display_fraction), Float64(gap_display_fraction), false)

    gaps = diff(finite)
    positive_gaps = [gap for gap in gaps if gap > 0]
    if isempty(positive_gaps)
        return EnergyScale(data_min, data_max, data_max, data_max,
            Float64(lower_display_fraction), Float64(gap_display_fraction), false)
    end

    gap_idx = argmax(gaps)
    largest_gap = gaps[gap_idx]
    typical_gap = _median_sorted(sort(positive_gaps))
    full_range = data_max - data_min
    interior_gap = 1 < gap_idx < length(finite) - 1
    top_gap = compress_top_gap && gap_idx == length(finite) - 1 && length(finite) >= 4
    compress = (interior_gap || top_gap) &&
        largest_gap >= Float64(min_gap_fraction) * full_range &&
        largest_gap >= Float64(gap_factor) * max(typical_gap, eps(Float64))

    if !compress
        return EnergyScale(data_min, data_max, data_max, data_max,
            Float64(lower_display_fraction), Float64(gap_display_fraction), false)
    end

    return EnergyScale(data_min, data_max, finite[gap_idx], finite[gap_idx + 1],
        Float64(lower_display_fraction), Float64(gap_display_fraction), true)
end

"""
    display_energy(scale, energy)

Map an energy value to display coordinates. The result is in normalized vertical
plot coordinates; use [`display_yticks`](@ref) for original-unit tick labels.
"""
function display_energy(scale::EnergyScale, energy::Real)
    e = Float64(energy)
    if !scale.compressed
        denom = max(scale.data_max - scale.data_min, eps(Float64))
        return (e - scale.data_min) / denom
    end

    lower_span = max(scale.split_low - scale.data_min, eps(Float64))
    upper_span = max(scale.data_max - scale.split_high, eps(Float64))
    upper_start = scale.lower_display_fraction + scale.gap_display_fraction

    if e <= scale.split_low
        return scale.lower_display_fraction * (e - scale.data_min) / lower_span
    elseif e >= scale.split_high
        return upper_start + (1.0 - upper_start) * (e - scale.split_high) / upper_span
    else
        return scale.lower_display_fraction +
            scale.gap_display_fraction * (e - scale.split_low) / (scale.split_high - scale.split_low)
    end
end

function _nice_step(raw_step)
    raw_step > 0 || return 1.0
    exponent = floor(log10(raw_step))
    fraction = raw_step / 10.0^exponent
    nice_fraction = fraction <= 1.0 ? 1.0 :
        fraction <= 2.0 ? 2.0 :
        fraction <= 5.0 ? 5.0 : 10.0
    return nice_fraction * 10.0^exponent
end

function _nice_ticks(lo, hi; target_count::Int=5)
    hi > lo || return [lo]
    step = _nice_step((hi - lo) / max(target_count - 1, 1))
    start = ceil(lo / step) * step
    stop = floor(hi / step) * step
    ticks = collect(start:step:stop)
    isempty(ticks) && return [lo, hi]
    first(ticks) > lo && pushfirst!(ticks, lo)
    last(ticks) < hi && push!(ticks, hi)
    return unique(ticks)
end

"""
    display_yticks(scale; target_count=6)

Return `(positions, labels)` for plotting a smart-scaled energy axis. Positions
are transformed display coordinates; labels are original energy values.
"""
function display_yticks(scale::EnergyScale; target_count::Int=6)
    if !scale.compressed
        ticks = _nice_ticks(scale.data_min, scale.data_max; target_count)
    else
        lower_count = max(3, ceil(Int, 0.6 * target_count))
        upper_count = max(2, target_count - lower_count + 1)
        ticks = vcat(
            _nice_ticks(scale.data_min, scale.split_low; target_count=lower_count),
            _nice_ticks(scale.split_high, scale.data_max; target_count=upper_count),
        )
        push!(ticks, scale.split_low, scale.split_high)
        ticks = sort(unique(ticks))
    end

    positions = [display_energy(scale, tick) for tick in ticks]
    labels = [abs(tick) >= 100 || (abs(tick) > 0 && abs(tick) < 0.01) ?
        string(round(tick; sigdigits=3)) :
        string(round(tick; digits=2)) for tick in ticks]
    return positions, labels
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

"""
    tree_segments(tree, layout=tree_layout(tree); style=:rectangular,
                  merge_cap_fraction=0.12, max_merge_cap_width=0.22)

Return drawable line segments for a tree layout.

`style=:rectangular` returns the conventional disconnectivity graph geometry
stored in `layout.segments`. `style=:sloped` connects each child directly to its
parent merge node while preserving the exact parent and child energy
coordinates. Short merge caps keep the barrier energy visually explicit without
requiring long horizontal bars that can obscure closely spaced minima.
"""
function tree_segments(tree::DisconnectivityTree{I,T},
                       layout::TreeLayout{I,T}=tree_layout(tree);
                       style::Symbol=:rectangular,
                       merge_cap_fraction::Real=0.12,
                       max_merge_cap_width::Real=0.22) where {I,T}
    if style == :rectangular
        return layout.segments
    elseif style != :sloped
        error("unknown tree segment style: $(style)")
    end

    segments = TreeSegment{T}[]
    cap_fraction = max(Float64(merge_cap_fraction), 0.0)
    max_cap = max(Float64(max_merge_cap_width), 0.0)

    function add_sloped_segments!(node_id::Int)
        node = tree.nodes[node_id]
        isempty(node.children) && return nothing

        child_x = [layout.x[child] for child in node.children]
        if cap_fraction > 0.0 && length(child_x) > 1
            span = maximum(child_x) - minimum(child_x)
            cap_half_width = min(0.5 * cap_fraction * max(span, 1.0), 0.5 * max_cap)
            if cap_half_width > 0.0
                push!(segments, TreeSegment{T}(
                    layout.x[node_id] - cap_half_width,
                    layout.y[node_id],
                    layout.x[node_id] + cap_half_width,
                    layout.y[node_id],
                    :merge_cap,
                    node_id,
                ))
            end
        end

        for child in node.children
            push!(segments, TreeSegment{T}(
                layout.x[child],
                layout.y[child],
                layout.x[node_id],
                layout.y[node_id],
                :sloped_branch,
                child,
            ))
            add_sloped_segments!(child)
        end
        return nothing
    end

    add_sloped_segments!(tree.root)
    return segments
end
