export SemialgebraicSetsHCSolver

function ModelKit.System(V::SemialgebraicSets.AbstractAlgebraicSet; kwargs...)
    ModelKit.System(SemialgebraicSets.equalities(V); kwargs...)
end

"""
    SemialgebraicSetsHCSolver(; excess_residual_tol = nothing, real_atol = 1e-6, real_rtol = 0.0, compile = false, options...)

Construct a `SemialgebraicSets.AbstractAlgebraicSolver` to be used in `SemialgebraicSets`.
`options` are all valid options for [`solve`](@ref).

Solutions with imaginary part larger than the specified tolerances are
filtered out (see [`is_real`](@ref) for details).

For overdetermined systems, `excess_residual_tol` can be set to a `Float64`
value. Excess solutions that have a residual smaller than `excess_residual_tol`
are reconsidered as a success.

## Example

```
julia> using HomotopyContinuation, SemialgebraicSets;

julia> solver = SemialgebraicSetsHCSolver(; show_progress = false)
SemialgebraicSetsHCSolver(; compile = :none, show_progress = false)

julia> @polyvar x y
(x, y)

julia> V = @set x^2 == 1 && y^2 == 2 solver
Algebraic Set defined by 2 equalities
 x^2 - 1.0 = 0
 y^2 - 2.0 = 0

julia> collect(V)
4-element Array{Array{Float64,1},1}:
 [1.0, 1.414213562373095]
 [1.0, -1.414213562373095]
 [-1.0, 1.414213562373095]
 [-1.0, -1.414213562373095]
```
"""
struct SemialgebraicSetsHCSolver <: SemialgebraicSets.AbstractAlgebraicSolver
    excess_residual_tol::Union{Nothing,Float64}
    real_atol::Float64
    real_rtol::Float64
    options::Any
end
function SemialgebraicSetsHCSolver(;
    excess_residual_tol = nothing,
    real_atol = 1e-6,
    real_rtol = 0.0,
    real_tol = nothing,
    compile = :none,
    options...,
)
    if real_tol !== nothing
        Base.depwarn(
            "The `real_tol` keyword argument is deprecated and will be removed in a future version. Use `real_atol` instead.",
            :SemialgebraicSetsHCSolver,
        )
        real_atol = real_tol
    end
    SemialgebraicSetsHCSolver(
        excess_residual_tol,
        real_atol,
        real_rtol,
        (compile = compile, options...),
    )
end

function SemialgebraicSets.default_gröbner_basis_algorithm(
    ::Any,
    ::SemialgebraicSetsHCSolver,
)
    return SemialgebraicSets.NoAlgorithm()
end

function SemialgebraicSets.promote_for(
    ::Type{T},
    ::Type{SemialgebraicSetsHCSolver},
) where {T}
    return float(T)
end

function Base.show(io::IO, solver::SemialgebraicSetsHCSolver)
    print(io, "SemialgebraicSetsHCSolver(; ")
    if solver.excess_residual_tol !== nothing
        print(io, "excess_residual_tol = ", solver.excess_residual_tol)
        print(io, ", ")
    end
    print(io, "real_atol = ", solver.real_atol)
    print(io, ", ")
    print(io, "real_rtol = ", solver.real_rtol)
    print(io, ", ")
    join(
        io,
        [
            "$(k) = $(v isa Symbol ? Expr(:quote, v) : v)" for
            (k, v) in pairs(solver.options)
        ],
        ", ",
    )
    print(io, ")")
end

function _reconsider_excess_solutions(tracker, results, tol) end
function _reconsider_excess_solutions(tracker::OverdeterminedTracker, results, tol::Float64)
    check = tracker.excess_solution_check
    for result in results
        if result.return_code == :excess_solution
            result.return_code = :success
            _excess_solution_residual_check!(result, check.system, check.newton_cache, tol)
        end
    end
end

function SemialgebraicSets.solve(
    V::SemialgebraicSets.AbstractAlgebraicSet,
    hcsolver::SemialgebraicSetsHCSolver,
)
    F = System(V)
    m, n = size(F)
    # Check that we can have isolated solutions
    m ≥ n || return nothing
    solver, starts = solver_startsolutions(F; hcsolver.options...)
    results = solve(solver, starts)
    _reconsider_excess_solutions(
        first(solver.trackers),
        results,
        hcsolver.excess_residual_tol,
    )
    # Only return real, non-singular solutions
    return real_solutions(
        results;
        real_atol = hcsolver.real_atol,
        real_rtol = hcsolver.real_rtol,
        only_nonsingular = true,
    )
end
