"""
    Minimum(id, energy; metadata=Dict{Symbol,Any}())

A local minimum in an energy landscape. `id` can be any hashable label, and
`energy` is usually an absolute energy in joules or a consistently shifted
energy in dimensionless units.
"""
struct Minimum{I,T<:Real}
    id::I
    energy::T
    metadata::Dict{Symbol,Any}

    function Minimum(id::I, energy::T; metadata=Dict{Symbol,Any}()) where {I,T<:Real}
        isnan(Float64(energy)) && error("minimum energy must not be NaN")
        return new{I,T}(id, energy, Dict{Symbol,Any}(metadata))
    end
end

"""
    Saddle(from, to, energy; metadata=Dict{Symbol,Any}())

An undirected transition-state connection between two minima. For systems with
directed barriers, store the absolute saddle energy here and keep forward and
reverse barriers in `metadata`, or construct this from the higher of
`E_minimum + barrier` for the two directions.
"""
struct Saddle{I,T<:Real}
    from::I
    to::I
    energy::T
    metadata::Dict{Symbol,Any}

    function Saddle(from::I, to::I, energy::T; metadata=Dict{Symbol,Any}()) where {I,T<:Real}
        from != to || error("saddle endpoints must be different")
        isnan(Float64(energy)) && error("saddle energy must not be NaN")
        return new{I,T}(from, to, energy, Dict{Symbol,Any}(metadata))
    end
end

"""
    LandscapeGraph(minima, saddles)

A sparse minima-transition-state network. The core disconnectivity-tree
algorithm only requires minimum energies and saddle energies; metadata can hold
micromagnetic moments, mesh names, NEB convergence metrics, or path profiles.
"""
struct LandscapeGraph{I,T<:Real}
    minima::Vector{Minimum{I,T}}
    saddles::Vector{Saddle{I,T}}
    index::Dict{I,Int}

    function LandscapeGraph(minima::AbstractVector{<:Minimum{I,T}},
                            saddles::AbstractVector{<:Saddle{I,T}}) where {I,T<:Real}
        isempty(minima) && error("landscape must contain at least one minimum")
        ids = [m.id for m in minima]
        length(unique(ids)) == length(ids) || error("minimum ids must be unique")
        index = Dict(id => i for (i, id) in pairs(ids))
        for saddle in saddles
            haskey(index, saddle.from) || error("saddle endpoint $(saddle.from) is not a minimum")
            haskey(index, saddle.to) || error("saddle endpoint $(saddle.to) is not a minimum")
        end
        return new{I,T}(collect(minima), collect(saddles), index)
    end
end

function LandscapeGraph(minima::AbstractVector{<:Minimum},
                        saddles::AbstractVector{<:Saddle})
    isempty(minima) && error("landscape must contain at least one minimum")
    ids = [m.id for m in minima]
    energies = vcat([m.energy for m in minima], [s.energy for s in saddles])
    I = promote_type(map(typeof, ids)...)
    T = promote_type(map(typeof, energies)...)
    promoted_minima = [Minimum(convert(I, m.id), convert(T, m.energy);
                         metadata=m.metadata) for m in minima]
    promoted_saddles = [Saddle(convert(I, s.from), convert(I, s.to), convert(T, s.energy);
                         metadata=s.metadata) for s in saddles]
    return LandscapeGraph(promoted_minima, promoted_saddles)
end

minimum_ids(landscape::LandscapeGraph) = [minimum.id for minimum in landscape.minima]
saddle_energy(saddle::Saddle) = saddle.energy
