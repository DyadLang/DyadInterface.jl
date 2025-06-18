#=
Dyad syntax:
component LotkaVolterra
  parameter α::Real = 1.3
  parameter β::Real = 0.9
  parameter γ::Real = 0.8
  parameter δ::Real = 1.8

  variable x::Real
  variable y::Real
relations
  initial x = 3.1
  initial y = 1.5
  der(x) = α*x - β*x*y
  der(y) = -δ*y + γ*x*y
end

analysis LotkaVolterraTransient
  extends TransientAnalysis(alg="auto", abstol=0.01, reltol=0.001, start=0, stop=10)
  parameter α1::Real = 1.1

  model = LotkaVolterra(α=α1)
end
=#

include("codegen.jl")

using Test
using DyadInterface
using JSON3
using ModelingToolkit, SciMLBase
using Plots
using .LotkaVolterraTransientAnalysis
using Malt
using Pkg
using SymbolicIndexingInterface

json_str = """
    {
        "name": "LotkaVolterraTransient",
        "alg": "auto",
        "abstol": 1e-6,
        "reltol": 1e-3,
        "start": 0,
        "stop": 1,
        "saveat": 0,
        "α1": 1.1
    }
    """
payload = JSON3.read(json_str, LotkaVolterraTransientSpec)

result = run_analysis(payload)
@test SciMLBase.successful_retcode(result)
# check that stop is updated from the default of 10
@test result.sol.t[end] == 1

@testset "Serialization" begin
    serialize_solution(joinpath(@__DIR__, "result.jls"), result)
    sb_v = Pkg.Operations.Context().env.manifest[findfirst(
        v -> v.name == "SciMLBase", Pkg.Operations.Context().env.manifest)].version
    mtk_v = Pkg.Operations.Context().env.manifest[findfirst(
        v -> v.name == "ModelingToolkit",
        Pkg.Operations.Context().env.manifest)].version

    worker = Malt.Worker()

    result2 = Malt.remote_eval_fetch(worker,
        quote
            using Pkg
            Pkg.activate(; temp = true)
            Pkg.add(name = "SciMLBase", version = $sb_v)
            Pkg.pin("SciMLBase")
            Pkg.add(name = "ModelingToolkit", version = $mtk_v)
            Pkg.pin("ModelingToolkit")
            Pkg.add(["Plots", "JSON3", "StructTypes"])
            Pkg.add("OrdinaryDiffEqDefault")
            using ModelingToolkit, SciMLBase, Plots, JSON3

            @info "loaded"

            Pkg.develop(path = joinpath(@__DIR__, ".."))
            using DyadInterface
            include(joinpath(@__DIR__, "codegen.jl"))
            using .LotkaVolterraTransientAnalysis

            r = deserialize_solution(joinpath(
                @__DIR__, "result.jls"))
            @info "done"
            r
        end
    )

    @test result.sol == result2.sol
    @test result.prob_expr == result2.prob_expr
    @test result.spec == result2.spec

    rm(joinpath(@__DIR__, "result.jls"))
end

# to use symbolic indexing we need to rebuild the sol
sol = rebuild_sol(result)
rebuilt_model = symbolic_container(sol.prob.f)

@test defaults(rebuilt_model)[rebuilt_model.α] == 1.1
# test that the parameter override was successful
@test sol.ps[rebuilt_model.α] == 1.1

@testset "user workflows" begin
    spec = LotkaVolterraTransientSpec()
    result = run_analysis(spec)
    @test SciMLBase.successful_retcode(result)

    # update analysis parameter
    spec.stop = 5
    result = run_analysis(spec)
    @test SciMLBase.successful_retcode(result)
    @test result.sol.t[end] == 5

    # update model parameter
    spec.α1 = 1.6
    result = run_analysis(spec)
    @test SciMLBase.successful_retcode(result)
    # users would usually interact with plotting features, where rebuild_sol happens automatically
    sol = rebuild_sol(result)
    @test sol.ps[rebuilt_model.α] == 1.6

    # plot results
    @test_nowarn artifacts(result, :SimulationSolutionPlot)

    # plot fallback for interactive usage (special cased for TransientAnalysis)
    @test_nowarn plot(result)
    @test_nowarn plot(result, idxs = 1)

    model = symbolic_container(result)
    @test_nowarn plot(result, idxs = model.x + 1)
end
