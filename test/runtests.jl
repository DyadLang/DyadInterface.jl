using SafeTestsets
using Test

@testset verbose=true "DyadInterface.jl" begin
    @safetestset "QA" include("qa.jl")
    @safetestset "Latency" include("latency.jl")
    @safetestset "Analysis" include("analysis.jl")
    @safetestset "Analysis points" include("analysis_points.jl")
    @safetestset "Additional passes" include("structural_simplify_passes.jl")
    @safetestset "Results" include("results.jl")
    @safetestset "Full pipeline" include("pipeline.jl")
    # @safetestset "Deprecations" include("deprecations.jl")
end
