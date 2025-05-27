using DyadInterface
using SnoopCompile, SnoopCompileCore
using Test

include("codegen.jl")
using .LotkaVolterraTransientAnalysis

tinf_simspec = @snoop_inference LotkaVolterraTransientSpec()
@test inclusive(tinf_simspec) < 5

spec = LotkaVolterraTransientSpec()
tinf_run = @snoop_inference run_analysis(spec)
@test inclusive(tinf_run) < 50
