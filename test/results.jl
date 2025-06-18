using DyadInterface
using SciMLBase
using OrdinaryDiffEqDefault
using SymbolicIndexingInterface
using Plots
using DataFrames
using Test
using JSON3

include("lotka_volterra.jl")
model = lotka()

spec = TransientAnalysisSpec(;
    model, name = :lotkavolterra, abstol = 1e-6, reltol = 1e-9,
    stop = 1.0, saveat = collect(range(0, 1, length = 11)))

sol = run_analysis(spec)

@test sol isa TransientAnalysisSolution
@test SciMLBase.successful_retcode(sol)

m = AnalysisSolutionMetadata(sol)

artifact_names = artifacts(sol)
@test artifact_names ==
      [:SimulationSolutionPlot, :SimulationSolutionTable,
    :RawSolution, :SimplifiedSystem, :InitialSystem]

@test length(m.artifacts) == 5
@test m.artifacts[1].name == :SimulationSolutionPlot
@test m.artifacts[1].type == ArtifactType.PlotlyPlot
@test m.artifacts[1].title == "Solution plot"
@test m.artifacts[1].description == "Transient solution plot for lotkavolterra."
@test length(m.allowed_symbols) == 2
@test m.allowed_symbols == getname.(variable_symbols(DyadInterface.rebuild_sol(sol)))

@test length(sol.sol.t) == 11

@test_nowarn artifacts(sol, m.artifacts[1].name)
@test artifacts(sol, m.artifacts[2].name) isa DataFrame

@test ModelingToolkit.isscheduled(artifacts(sol, :SimplifiedSystem))
@test !ModelingToolkit.isscheduled(artifacts(sol, :InitialSystem))
@test artifacts(sol, :RawSolution) isa ODESolution

vizdef = PlotlyVisualizationSpec(
    m.allowed_symbols[[2, 1]], (;), [Attribute("tstart", "start time", 0.0)])
@test_nowarn customizable_visualization(sol, vizdef)

@testset "SteadyStateAnalysis" begin
    spec = SteadyStateAnalysisSpec(; model, name = :lotkavolterra)
    @test spec isa SteadyStateAnalysisSpec
    sol = run_analysis(spec)
    @test SciMLBase.successful_retcode(sol)

    @test artifacts(sol, :SimulationSolutionTable) isa DataFrame

    @test length(artifacts(sol)) == 4
    @test ModelingToolkit.isscheduled(artifacts(sol, :SimplifiedSystem))
    @test !ModelingToolkit.isscheduled(artifacts(sol, :InitialSystem))
    @test artifacts(sol, :RawSolution) isa SciMLBase.NonlinearSolution
end
