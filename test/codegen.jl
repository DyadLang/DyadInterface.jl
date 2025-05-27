module LotkaVolterraTransientAnalysis
# Codegen code

using DyadInterface

using ModelingToolkit
using ModelingToolkit: t_nounits as t
using OrdinaryDiffEqDefault
#using RuntimeGeneratedFunctions
#RuntimeGeneratedFunctions.init(@__MODULE__)

# TODO: Update dyad-kernel to emit D_nounits instead of D = Differential(t)
#D = Differential(t)
using ModelingToolkit: D_nounits as D

@component function LotkaVolterra(; name, α = 1.3, β = 0.9, γ = 0.8, δ = 1.8)
    params = @parameters begin
        (α::Float64 = α)
        (β::Float64 = β)
        (γ::Float64 = γ)
        (δ::Float64 = δ)
    end
    vars = @variables begin
        x(t)
        y(t)
    end
    defaults = Dict([
        x => (3.1),
        y => (1.5)
    ])
    eqs = Equation[D(x) ~ α * x - β * x * y
                   D(y) ~ -δ * y + γ * x * y]
    return ODESystem(eqs, t, vars, params; systems = [], defaults, name)
end

@kwdef mutable struct LotkaVolterraTransientSpec <: AbstractTransientAnalysisSpec
    name::Symbol = :LotkaVolterraTransient
    var"alg"::String = "auto"
    var"start"::Float64 = 0
    var"stop"::Float64 = 10
    var"abstol"::Float64 = 0.01
    var"reltol"::Float64 = 0.001
    var"saveat"::Float64 = 0
    var"dtmax"::Float64 = 0
    var"α1"::Float64 = 1.1
    model::Union{Nothing, ODESystem} = LotkaVolterra(; name)
end

function DyadInterface.run_analysis(spec::LotkaVolterraTransientSpec)
    spec.model = DyadInterface.update_model(spec.model, (; var"α" = spec.α1))
    base_spec = TransientAnalysisSpec(;
        name = :TransientAnalysis, alg = spec.alg, start = spec.start, stop = spec.stop,
        abstol = spec.abstol, reltol = spec.reltol, saveat = spec.saveat,
        dtmax = spec.dtmax, model = spec.model
    )
    run_analysis(base_spec)
end

export LotkaVolterraTransientSpec

end
