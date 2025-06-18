using DyadInterface
using SciMLBase
using OrdinaryDiffEqDefault, OrdinaryDiffEqTsit5
using Test
using JSON3

include("lotka_volterra.jl")
model = lotka()

include("codegen.jl")
using .LotkaVolterraTransientAnalysis

@testset "Correctness" begin
    tspan = (0.0, 1.0)
    abstol = 1e-6
    reltol = 1e-3
    alg = Tsit5()
    dt = 0.1

    spec = JSON3.read(read(joinpath(@__DIR__, "test_transientanalysis.json"), String),
        LotkaVolterraTransientSpec)
    @test spec isa LotkaVolterraTransientSpec

    sol = run_analysis(spec)
    @test SciMLBase.successful_retcode(sol)

    # note that LotkaVolterraTransientSpec changes the value for α from 1.3 to 1.1
    model = lotka(α = 1.1)
    prob = ODEProblem(model, [], tspan)
    sol2 = solve(prob, alg; abstol, reltol, saveat = 0:0.1:1)

    @testset "solution" begin
        @test sol.sol.u == sol2.u
        @test sol.sol.t == sol2.t
        @test all(diff(sol.sol.t) .≈ dt)
    end

    # Change override value in JSON
    @testset "JSON overrides" begin
        json_str = """
        {
            "name": "LotkaVolterraTransient",
            "α1": 1.6
        }
        """

        spec = JSON3.read(json_str, LotkaVolterraTransientSpec)
        sol = run_analysis(spec)
        model = lotka(α = 1.6)
        prob = ODEProblem(model, [], (0, 10))
        sol2 = solve(prob, alg; abstol = 0.01, reltol = 0.001)

        @test sol.sol.u == sol2.u
        @test sol.sol.t == sol2.t
    end
end

@testset "$i integrator" for i in ["auto", "Rodas5P", "FBDF", "Tsit5"]
    json_str = """
    {
        "name": "Lotka-Volterra",
        "alg": "$i",
        "abstol": 1e-6,
        "reltol": 1e-3,
        "start": 0,
        "stop": 1
    }
    """

    spec = JSON3.read(json_str, LotkaVolterraTransientSpec)
    # if validation fails a JSONSchema issue type is returned
    @test spec isa LotkaVolterraTransientSpec

    if i ∉ ["Rodas5P", "FBDF"]
        sol = run_analysis(spec)
        @test SciMLBase.successful_retcode(sol)
    end
end

@testset "SteadyStateAnalysis" begin
    spec = SteadyStateAnalysisSpec(;
        model, name = :lotkavolterra, abstol = 1e-6, reltol = 1e-6)
    @test spec isa SteadyStateAnalysisSpec
    sol = run_analysis(spec)
    @test SciMLBase.successful_retcode(sol)
end

@testset "run analyses" begin
    json_str = """
    {
        "name": "LotkaVolterraTransientAnalysis",
        "alg": "auto",
        "abstol": 1e-6,
        "reltol": 1e-3,
        "start": 0,
        "stop": 1
    }
    """

    spec = JSON3.read(json_str, LotkaVolterraTransientSpec)

    @test nameof(spec) == :LotkaVolterraTransientAnalysis
    @test spec.alg == "auto"
    @test spec.start == 0.0
    @test spec.stop == 1.0

    sol = run_analysis(spec)
    @test SciMLBase.successful_retcode(sol)

    json_str = """
    {
        "name": "LotkaVolterraTransientAnalysis",
        "alg": "Tsit5",
        "abstol": 0.01,
        "reltol": 0.01,
        "start": 0,
        "stop": 1.5,
        "saveat": 0
    }
    """

    spec = JSON3.read(json_str, LotkaVolterraTransientSpec)
    @test spec.alg == "Tsit5"
    @test spec.start == 0.0
    @test spec.stop == 1.5
    @test spec.abstol == 0.01
    @test spec.reltol == 0.01
end

@testset "Show Method" begin
    json_str = """
    {
        "name": "Lotka-Volterra",
        "alg": "Tsit5",
        "abstol": 0.01,
        "reltol": 0.01,
        "start": 0,
        "stop": 1.5
    }
    """

    spec = JSON3.read(json_str, LotkaVolterraTransientSpec)

    spec_ref = "Transient Analysis specification for Lotka-Volterra\n" *
               "tspan: (0.0, 1.5)\n" *
               "alg: Tsit5"
    @test sprint(io -> show(io, MIME"text/plain"(), spec)) == spec_ref
end
