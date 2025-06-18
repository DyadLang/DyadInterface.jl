# Right now, this file just tests
# that the Makie recipe for the transient analysis
# works the same as the Makie recipe for the actual solution,
# over a few different cases.

using Test

using Makie
using DyadInterface, ModelingToolkit

include("codegen.jl")
using .LotkaVolterraTransientAnalysis

@mtkbuild lotka = LotkaVolterraTransientAnalysis.LotkaVolterra()

@testset "Transient analysis plot equivalent to regular solution plot" begin
    spec = LotkaVolterraTransientSpec(; name = :lotka, model = lotka)
    lotka.α = 1.1
    mtk_sol = solve(ODEProblem(lotka, [], (spec.start, spec.stop));
        abstol = spec.abstol, reltol = spec.reltol)
    dyad_sol = run_analysis(spec)

    @test mtk_sol.t == dyad_sol.sol.t
    @test mtk_sol.u == dyad_sol.sol.u

    mf, ma, mp = Makie.plot(mtk_sol; denseplot = false)
    df, da, dp = Makie.plot(dyad_sol; denseplot = false)

    @test Makie.plotsym.(mp.plots) == Makie.plotsym.(dp.plots)

    for i in 1:2
        @test getindex.(mp.plots[i].args) == getindex.(dp.plots[i].args)
    end
end
