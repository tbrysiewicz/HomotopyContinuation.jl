export StraightLineHomotopy

"""
    StraightLineHomotopy(G::System, F::System; gamma = 1.0)
    StraightLineHomotopy(G::AbstractSystem, F::AbstractSystem; gamma = 1.0)

Constructs the straight line homotopy ``H(x, t) = γ t G(x) + (1-t) F(x)`` where
``γ`` is `gamma`.
"""
struct StraightLineHomotopy{S<:AbstractSystem,T<:AbstractSystem} <: AbstractHomotopy
    start::S
    target::T
    γ::ComplexF64

    u::Vector{ComplexF64}
    ū::Vector{ComplexDF64}
    U::Matrix{ComplexF64}

    dv_start::LA.Transpose{ComplexF64,Matrix{ComplexF64}}
    dv_target::LA.Transpose{ComplexF64,Matrix{ComplexF64}}
end

function StraightLineHomotopy(start::ModelKit.System, target::ModelKit.System; kwargs...)
    StraightLineHomotopy(ModelKitSystem(start), ModelKitSystem(target); kwargs...)
end
function StraightLineHomotopy(start::AbstractSystem, target::AbstractSystem; γ = 1.0, gamma = γ)
    size(start) == size(target) ||
    throw(ArgumentError("Start and target do not have the same size, got $(size(start)) and $(size(target))"))

    m, n = size(start)
    u = zeros(ComplexF64, m)
    ū = zeros(ComplexDF64, m)
    U = zeros(ComplexF64, m, n)


    dv_start = LA.transpose(zeros(ComplexF64, 5, m))
    dv_target = LA.transpose(zeros(ComplexF64, 5, m))

    StraightLineHomotopy(start, target, ComplexF64(γ), u, ū, U, dv_start, dv_target)
end

Base.size(H::StraightLineHomotopy) = size(H.start)

function Base.show(io::IO, mime::MIME"text/plain", H::StraightLineHomotopy)
    println(io, typeof(H), ":")
    println(io, "γ: ", H.γ)
    println(io, "\nG: ")
    show(io, mime, H.start)
    println(io, "\n\nF:")
    show(io, mime, H.target)
end

function evaluate!(u, H::StraightLineHomotopy, x::AbstractVector{T}, t) where {T}
    evaluate!(u, H.start, x)

    if T isa ComplexDF64 || T isa DoubleF64
        evaluate!(H.ū, H.target, x)
        @inbounds u .= H.γ .* t .* u .+ (1.0 .- t) .* H.ū
    else
        evaluate!(H.u, H.target, x)
        @inbounds u .= H.γ .* t .* u .+ (1.0 .- t) .* H.u
    end
    u
end

function evaluate_and_jacobian!(
    u,
    U,
    H::StraightLineHomotopy,
    x::AbstractVector{T},
    t,
) where {T}
    evaluate_and_jacobian!(u, U, H.start, x)
    evaluate_and_jacobian!(H.u, H.U, H.target, x)
    @inbounds u .= H.γ .* t .* u .+ (1.0 .- t) .* H.u
    @inbounds U .= H.γ .* t .* U .+ (1.0 .- t) .* H.U
    nothing
end
function taylor!(u, ::Val{1}, H::StraightLineHomotopy, tx::TaylorVector{1}, t)
    x = first(vectors(tx))
    evaluate!(u, H.start, x)
    evaluate!(H.u, H.target, x)
    @inbounds u .= H.γ .* u .- H.u
end
function taylor!(u, v::Val{K}, H::StraightLineHomotopy, tx::TaylorVector, t) where {K}
    taylor!(H.dv_start, v, H.start, tx)
    taylor!(H.dv_target, v, H.target, tx)

    for i = 1:size(H, 1)
        start = H.γ * (H.dv_start[i, K] + t * H.dv_start[i, K+1])
        target = (1 - t) * H.dv_target[i, K+1] - H.dv_target[i, K]
        u[i] = start + target
    end
    u
end
