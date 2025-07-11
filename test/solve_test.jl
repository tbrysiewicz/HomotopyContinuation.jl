@testset "solve" begin

    @testset "total degree (simple)" begin
        @var x y
        affine_sqr = System([
            2.3 * x^2 + 1.2 * y^2 + 3x - 2y + 3,
            2.3 * x^2 + 1.2 * y^2 + 5x + 2y - 5,
        ])
        @test count(is_success, track.(total_degree(affine_sqr; compile = false)...)) == 2

        @var x y z
        proj_square = System([
            2.3 * x^2 + 1.2 * y^2 + 3x * z - 2y * z + 3 * z^2,
            2.3 * x^2 + 1.2 * y^2 + 5x * z + 2y * z - 5 * z^2,
        ])
        @test count(is_success, track.(total_degree(proj_square; compile = false)...)) == 4

        @var x y
        affine_ov = System([
            (x^2 + y^2 + x * y - 3) * (x + 3),
            (x^2 + y^2 + x * y - 3) * (y - x + 2),
            2x + 5y - 3,
        ])
        @test count(is_success, track.(total_degree(affine_ov; compile = false)...)) == 2

        @var x y
        affine_ov_reordering = System([
            (x^2 + y^2 + x * y - 3) * (x + 3),
            2x + 5y - 3,
            (x^2 + y^2 + x * y - 3) * (y^2 - x + 2),
        ])
        tracker, starts = total_degree(affine_ov_reordering; compile = false)
        @test length(starts) == 4 * 3
        @test count(is_success, track.(tracker, starts)) == 2

        @var x y z
        proj_ov = System([
            (x^2 + y^2 + x * y - 3 * z^2) * (x + 3z),
            (x^2 + y^2 + x * y - 3 * z^2) * (y - x + 2z),
            2x + 5y - 3z,
        ])
        @test count(is_success, track.(total_degree(proj_ov; compile = false)...)) == 2

        @var x y
        proj_ov_reordering = System([
            (x^2 + y^2 + x * y - 3 * z^2) * (x + 3z),
            2x + 5y - 3z,
            (x^2 + y^2 + x * y - 3 * z^2) * (y^2 - x * z + 2 * z^2),
        ])
        tracker, starts = total_degree(proj_ov_reordering; compile = false)
        @test length(starts) == 4 * 3
        @test count(is_success, track.(tracker, starts)) == 2

        @var x y
        affine_underdetermined = System([2.3 * x^2 + 1.2 * y^2 + 3x - 2y + 3])
        @test_throws HC.FiniteException total_degree(affine_underdetermined)

        @var x y z
        proj_underdetermined = System([2.3 * x^2 + 1.2 * y^2 + 3x * z])
        @test_throws HC.FiniteException total_degree(proj_underdetermined)
    end

    @testset "total degree (variable groups)" begin
        @var x y v w
        affine_sqr = System([x * y - 2, x^2 - 4], variable_groups = [[x], [y]])
        tracker, starts = total_degree(affine_sqr; compile = false)
        @test length(collect(starts)) == 2
        @test count(is_success, track.(tracker, starts)) == 2
        @test nsolutions(solve(affine_sqr, start_system = :total_degree)) == 2

        @var x y v w
        proj_sqr =
            System([x * y - 2v * w, x^2 - 4 * v^2], variable_groups = [[x, v], [y, w]])
        tracker, starts = total_degree(proj_sqr)
        @test length(collect(starts)) == 2
        @test count(is_success, track.(tracker, starts)) == 2

        @var x y v w
        affine_ov = System(
            [(x^2 - 4) * (x * y - 2), x * y - 2, x^2 - 4],
            variable_groups = [[x], [y]],
        )
        tracker, starts = total_degree(affine_ov; compile = false)
        @test count(is_success, track.(tracker, starts)) == 2
        @var x y v w
        proj_ov = System(
            [(x^2 - 4 * v^2) * (x * y - v * w), x * y - v * w, x^2 - v^2],
            variable_groups = [[x, v], [y, w]],
        )
        tracker, starts = total_degree(proj_ov; compile = false)
        @test count(is_success, track.(tracker, starts)) == 2
    end

    @testset "polyhedral" begin
        @var x y
        affine_sqr = System([
            2.3 * x^2 + 1.2 * y^2 + 3x - 2y + 3,
            2.3 * x^2 + 1.2 * y^2 + 5x + 2y - 5,
        ])
        @test count(is_success, track.(polyhedral(affine_sqr; compile = false)...)) == 2

        @var x y z
        proj_square = System([
            2.3 * x^2 + 1.2 * y^2 + 3x * z - 2y * z + 3 * z^2,
            2.3 * x^2 + 1.2 * y^2 + 5x * z + 2y * z - 5 * z^2,
        ])
        @test count(is_success, track.(polyhedral(proj_square; compile = false)...)) == 4

        @var x y
        affine_ov = System([
            (x^2 + y^2 + x * y - 3) * (x + 3),
            (x^2 + y^2 + x * y - 3) * (y - x + 2),
            2x + 5y - 3,
        ])
        @test count(is_success, track.(polyhedral(affine_ov; compile = false)...)) == 2

        @var x y z
        proj_ov = System([
            (x^2 + y^2 + x * y - 3 * z^2) * (x + 3z),
            (x^2 + y^2 + x * y - 3 * z^2) * (y - x + 2z),
            2x + 5y - 3z,
        ])
        @test count(is_success, track.(polyhedral(proj_ov; compile = false)...)) == 2

        @var x y
        affine_underdetermined = System([2.3 * x^2 + 1.2 * y^2 + 3x - 2y + 3])
        @test_throws HC.FiniteException polyhedral(affine_underdetermined)

        @var x y z
        proj_underdetermined = System([2.3 * x^2 + 1.2 * y^2 + 3x * z])
        @test_throws HC.FiniteException polyhedral(proj_underdetermined)
    end

    @testset "overdetermined" begin
        @testset "3 by 5 minors" begin
            res = solve(
                minors();
                start_system = :total_degree,
                compile = false,
                show_progress = false,
            )
            @test count(is_success, res) == 80
            @test count(is_excess_solution, res) == 136
        end
    end

    @testset "composition" begin
        @var a b c x y z u v
        e = System([u + 1, v - 2])
        f = System([a * b - 2, a * c - 1])
        g = System([x + y, y + 3, x + 2])

        res = solve(e ∘ f ∘ g; start_system = :total_degree, compile = false)
        @test nsolutions(res) == 2

        res = solve(e ∘ f ∘ g; start_system = :polyhedral)
        @test nsolutions(res) == 2
    end

    @testset "paths to track" begin
        @var x y
        f = System([2y + 3 * y^2 - x * y^3, x + 4 * x^2 - 2 * x^3 * y])

        @test paths_to_track(f; start_system = :total_degree) == 16
        @test paths_to_track(f; start_system = :total_degree) == 16
        @test paths_to_track(f; start_system = :polyhedral) == 8
        @test paths_to_track(f; start_system = :polyhedral, only_non_zero = true) == 3
        @test paths_to_track(f) == 8
        @test_deprecated bezout_number(f) == 16
        @test mixed_volume(f) == 3

        @var x y a
        g = System([2y + a * y^2 - x * y^3, x + 4 * x^2 - 2 * x^3 * y], parameters = [a])
        @test paths_to_track(g; start_system = :total_degree) == 16
        @test paths_to_track(g; start_system = :polyhedral) == 8
    end

    @testset "solve (parameter homotopy)" begin
        # affine
        @var x a y b
        F = System([x^2 - a, x * y - a + b], [x, y], [a, b])
        s = [1, 1]
        res = solve(F, [s]; start_parameters = [1, 0], target_parameters = [2, 4])
        @test nsolutions(res) == 1
        res = solve(
            InterpretedSystem(F),
            [s];
            start_parameters = [1, 0],
            target_parameters = [2, 4],
            threading = false,
        )
        @test nsolutions(res) == 1
        res = solve(
            F,
            s;
            start_parameters = [1, 0],
            target_parameters = [2, 4],
            threading = false,
            compile = false,
        )
        @test nsolutions(res) == 1

        @var x a y b
        F = System([x^2 - a], [x, y], [a, b])
        s = [1, 1]
        @test_throws FiniteException(1) solve(
            F,
            [s];
            start_parameters = [1, 0],
            target_parameters = [2, 4],
        )

        # proj
        @var x a y b z
        F_proj = System([x^2 - a * z^2, x * y + (b - a) * z^2], [x, y, z], [a, b])
        s = [1, 1, 1]
        res = solve(F_proj, [s]; start_parameters = [1, 0], target_parameters = [2, 4])
        @test nsolutions(res) == 1
        res = solve(InterpretedSystem(F_proj), [s]; p₁ = [1, 0], p₀ = [2, 4])
        @test nsolutions(res) == 1

        F_proj_err = System([x * y + (b - a) * z^2], [x, y, z], [a, b])
        @test_throws FiniteException solve(F_proj_err, [s]; p₁ = [1, 0], p₀ = [2, 4])

        # multi-proj
        @var x y v w a b
        F_multi_proj = System(
            [x * y - a * v * w, x^2 - b * v^2],
            parameters = [a, b],
            variable_groups = [[x, v], [y, w]],
        )
        S = [
            [
                -1.808683149843597 + 0.2761582523875564im,
                -0.9043415749217985 + 0.1380791261937782im,
                -0.0422893850686111 - 0.7152002569359284im,
                -0.0422893850686111 - 0.7152002569359283im,
            ],
            [
                -0.36370464807054353 + 0.6777414371333245im,
                0.18185232403527177 - 0.33887071856666223im,
                -0.3348980281838583 - 0.7759382220656511im,
                0.3348980281838583 + 0.7759382220656511im,
            ],
        ]
        res = solve(F_multi_proj, S; start_parameters = [2, 4], target_parameters = [3, 5])
        @test nsolutions(res) == 2
        res = solve(InterpretedSystem(F_multi_proj), S; p₁ = [2, 4], p₀ = [3, 5])
        @test nsolutions(res) == 2

        F_multi_proj_err = System(
            [x * y - a * v * w],
            parameters = [a, b],
            variable_groups = [[x, v], [y, w]],
        )
        @test_throws FiniteException(1) solve(F_multi_proj_err, S; p₁ = [2, 4], p₀ = [3, 5])
    end

    @testset "solve (Homotopy)" begin
        @var x a y b
        F = System([x^2 - a, x * y - a + b], [x, y], [a, b])
        s = [1, 1]
        H = ParameterHomotopy(F, [1, 0], [2, 4])
        res = solve(H, [s])
        @test nsolutions(res) == 1
    end

    @testset "solve (start target)" begin
        @var x a y b
        f = System([x^2 - a, x * y - a + b], parameters = [a, b])
        s = [1, 1]
        res = solve(f, f, [s]; start_parameters = [1, 0], target_parameters = [2, 4])
        @test nsolutions(res) == 1

        G = FixedParameterSystem(f, [1, 0])
        F = FixedParameterSystem(f, [2, 4])
        res = solve(G, F, [s];)
        @test nsolutions(res) == 1
    end

    @testset "solve (affine sliced)" begin
        @var x y
        F = System([x^2 + y^2 - 5], [x, y])
        l1 = rand_subspace(2; codim = 1)
        l2 = rand_subspace(2; codim = 1)

        _solver, starts = solver_startsolutions(slice(F, l1), slice(F, l2))
        @test _solver.trackers[1].tracker.homotopy isa ExtrinsicSubspaceHomotopy

        @var x y
        r1 = solve(F; target_subspace = l1, compile = false)
        @test nsolutions(r1) == 2
        r2 = solve(
            F,
            solutions(r1);
            start_subspace = l1,
            target_subspace = l2,
            compile = false,
            threading = false,
            intrinsic = true,
        )
        @test nsolutions(r2) == 2
        r3 = solve(
            F,
            solutions(r1);
            start_subspace = l1,
            target_subspace = l2,
            compile = false,
            intrinsic = false,
        )
        @test nsolutions(r3) == 2

        @var x y z u v
        F = System([x^2 + y^2 - 5], [x, y, z, u, v])
        l1 = rand_subspace(5; dim = 1)
        l2 = rand_subspace(5; dim = 1)

        _solver, starts = solver_startsolutions(slice(F, l1), slice(F, l2))
        @test _solver.trackers[1].tracker.homotopy isa IntrinsicSubspaceHomotopy
    end

    @testset "solve (Vector{Expression})" begin
        @var x a y b
        F = [x^2 - a, x * y - a + b]
        s = [1, 1]
        res = solve(
            F,
            [s];
            parameters = [a, b],
            start_parameters = [1, 0],
            target_parameters = [2, 4],
        )
        @test nsolutions(res) == 1
    end

    @testset "solve (DynamicPolynomials)" begin
        @polyvar x y
        # define the polynomials
        f₁ = (x^4 + y^4 - 1) * (x^2 + y^2 - 2) + x^5 * y
        f₂ = x^2 + 2x * y^2 - 2 * y^2 - 1 / 2
        result = solve([f₁, f₂])
        @test nsolutions(result) == 18

        @polyvar x a y b
        F = [x^2 - a, x * y - a + b]
        s = [1, 1]
        res = solve(
            F,
            [s];
            variables = [x, y],
            parameters = [a, b],
            start_parameters = [1, 0],
            target_parameters = [2, 4],
            compile = false,
        )
        @test nsolutions(res) == 1
        res2 = solve(
            F,
            [s];
            variable_ordering = [y, x],
            parameters = [a, b],
            start_parameters = [1, 0],
            target_parameters = [2, 4],
            compile = false,
        )
        s = solutions(res)[1]
        s2 = solutions(res2)[1]
        @test s ≈ [s2[2], s2[1]]
    end

    @testset "change parameters" begin
        @var x a y b
        F = System([x^2 - a, x * y - a + b]; parameters = [a, b])
        s = [1.0, 1.0 + 0im]
        S, _ = solver_startsolutions(F, generic_parameters = [2.2, 3.2])
        start_parameters!(S, [1, 0])
        target_parameters!(S, [2, 4])
        @test is_success(track(S, s))
    end

    @testset "solve (threading)" begin
        res = solve(cyclic(7), threading = true, show_progress = false)
        @test nsolutions(res) == 924
    end

    @testset "stop early callback" begin
        @var x
        first_result = nothing
        results = solve(
            [(x - 3) * (x + 6) * (x + 2)];
            stop_early_cb = r -> begin
                first_result = r
                true
            end,
            threading = false,
            show_progress = false,
            start_system = :total_degree,
        )
        @test length(results) == 1
        @test first(results) === first_result

        result = let k = 0
            solve(
                [(x - 3) * (x + 6) * (x + 2)],
                stop_early_cb = r -> (k += 1) == 2,
                start_system = :total_degree,
                show_progress = false,
                threading = false,
            )
        end
        @test length(result) == 2

        # threading
        @var x y z
        first_result = nothing
        # this has 5^3 = 125 solutions, so we should definitely stop early if we
        # have less than 64 threads
        results = solve(
            [
                (x - 3) * (x + 6) * (x + 2) * (x - 2) * (x + 2.5),
                (y + 2) * (y - 2) * (y + 3) * (y + 5) * (y - 1),
                (z + 2) * (z - 2) * (z + 3) * (z + 5) * (z - 2.1),
            ];
            stop_early_cb = r -> begin
                first_result = r
                true
            end,
            threading = true,
            show_progress = false,
            start_system = :total_degree,
        )
        @test length(results) < 125
    end

    @testset "Many parameters solver" begin
        # Setup
        @var x y
        f = x^2 + y^2 - 1

        @var a b c
        l = a * x + b * y + c
        F = [f, l]

        # Compute start solutions S₀ for given start parameters p₀
        p₀ = randn(ComplexF64, 3)
        S₀ = solutions(solve(subs(F, [a, b, c] => p₀)))
        # The parameters we are intersted in
        params = [rand(3) for i = 1:100]

        result1 = solve(
            F,
            S₀,
            ;
            start_parameters = p₀,
            target_parameters = params,
            parameters = [a, b, c],
            threading = true,
        )
        @test typeof(result1) == Vector{Tuple{Result,Vector{Float64}}}
        result1 = solve(
            F,
            S₀,
            ;
            start_parameters = p₀,
            target_parameters = params,
            parameters = [a, b, c],
            show_progress = false,
            threading = false,
        )
        @test typeof(result1) == Vector{Tuple{Result,Vector{Float64}}}

        # Only keep real solutions
        result2 = solve(
            F,
            S₀,
            ;
            start_parameters = p₀,
            target_parameters = params,
            parameters = [a, b, c],
            transform_result = (r, p) -> real_solutions(r),
            threading = true,
        )
        @test typeof(result2) == Vector{Vector{Vector{Float64}}}
        @test !isempty(result2)

        # Now instead of an Array{Array{Array{Float64,1},1},1} we want to have an
        # Array{Array{Float64,1},1}
        result3 = solve(
            F,
            S₀,
            ;
            start_parameters = p₀,
            target_parameters = params,
            parameters = [a, b, c],
            transform_result = (r, p) -> real_solutions(r),
            flatten = true,
            threading = false,
        )
        @test typeof(result3) == Vector{Vector{Float64}}
        @test !isempty(result3)

        # The passed `params` do not directly need to be the target parameters.
        # Instead they can be some more concrete informations (e.g. an index)
        # and we can them by using the `transform_parameters` method
        result4 = solve(
            F,
            S₀,
            ;
            start_parameters = p₀,
            target_parameters = 1:100,
            parameters = [a, b, c],
            transform_result = (r, p) -> (real_solutions(r), p),
            transform_parameters = _ -> rand(3),
        )
        @test typeof(result4) == Vector{Tuple{Vector{Vector{Float64}},Int64}}


        @var x y
        f = System([x^2 + y^2 - 1])


        # Compute start solutions S₀ for given start parameters p₀
        l₀ = rand_subspace(2; dim = 1)
        S₀ = solutions(solve(f, target_subspace = l₀))
        # The parameters we are intersted in
        subspaces = [rand_subspace(2; dim = 1) for i = 1:100]
        result1 = solve(
            f,
            S₀;
            start_subspace = l₀,
            target_subspaces = subspaces,
            threading = false,
            intrinsic = false,
        )
        @test all(r -> nsolutions(first(r)) == 2, result1)

        @testset "Many parameters threaded" begin
            @var u1, v1, ω, α, γ, λ, ω0

            eqs = [
                -u1 * ω^2 +
                u1 * ω0^2 +
                (3 / 4) * u1^3 * α +
                (3 / 4) * u1 * v1^2 * α +
                (-1 / 2) * u1 * λ * ω0^2 +
                v1 * γ * ω,
                -v1 * ω^2 + v1 * ω0^2 + (3 / 4) * v1^3 * α - u1 * γ * ω +
                (3 / 4) * u1^2 * v1 * α +
                (1 / 2) * v1 * λ * ω0^2,
            ]

            F = System(eqs, parameters = [ω, α, γ, λ, ω0], variables = [u1, v1])

            input_array = [
                [0.9, 1.0, 0.01, 0.01, 1.1],
                [0.9105263157894737, 1.0, 0.01, 0.01, 1.1],
                [0.9210526315789473, 1.0, 0.01, 0.01, 1.1],
                [0.9315789473684211, 1.0, 0.01, 0.01, 1.1],
                [0.9421052631578948, 1.0, 0.01, 0.01, 1.1],
                [0.9526315789473684, 1.0, 0.01, 0.01, 1.1],
            ]

            generic_parameters = randn(ComplexF64, 5)

            R0 = solve(F; target_parameters = generic_parameters, threading = true)
            R1 = solve(
                F,
                solutions(R0);
                start_parameters = generic_parameters,
                target_parameters = input_array,
                threading = true,
            )

            @test length(R1) == 6
        end


    end
end
