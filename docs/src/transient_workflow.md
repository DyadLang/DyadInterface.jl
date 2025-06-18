# Getting Started: Demonstration of the DyadInterface Interface on Transient Analysis

As a demonstration of the functionality in DyadInterface, we show what the workflow looks like to
a user of the DyadInterface interface for a transient analysis on a simple ODE. DyadInterface
comes with the instantiation of a few analyses, specifically steady state and transient analysis,
and thus we can run a transient analysis using the specification from this repository.

## Creating and running the Transient Analysis

There a 3 ways in which we can create & run the transient analysis:
- julia only
- Dyad generated functions
- JSON interface for Dyad Builder

### [The Julia only version](@id julia_transient_workflow)

```@example lotka
using ModelingToolkit
using ModelingToolkit: D_nounits as D, t_nounits as t

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
    initialization_eqs = [x ~ 3.1
                          y ~ 1.5]
    eqs = Equation[D(x) ~ α * x - β * x * y
                   D(y) ~ -δ * y + γ * x * y]
    return ODESystem(eqs, t, vars, params; systems = [], name, initialization_eqs)
end
@mtkbuild model = LotkaVolterra()
```

We will now construct the transient analysis specification:
```@example lotka
using DyadInterface
spec = TransientAnalysisSpec(; model, name=:LotkaVolterraTransient, abstol = 1e-6, reltol = 1e-3, stop=10., alg="Tsit5")
```

We can then run the analysis using `run_analysis`
```@example lotka
sol = run_analysis(spec)
```

Alternatively, the Dyad kernel generates a convenient `TransientAnalysis` function, which will create the spec and call `run_analysis` on it:
```@example lotka
sol = TransientAnalysis(; model, name=:LotkaVolterraTransient, abstol = 1e-6, reltol = 1e-3, stop=10., alg="Tsit5")
```

### [The Dyad generated functions](@id dyad_transient_workflow)

Assuming we have the following Dyad code,
```
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
```
the Dyad compiler will generate the following
```@example lotka
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

function LotkaVolterraTransient(; kwargs...)
    DyadInterface.run_analysis(LotkaVolterraTransientSpec(; kwargs...))
end

export LotkaVolterraTransientSpec, LotkaVolterraTransient
```

Users can instantiate a transient analysis specification via
```julia
spec = LotkaVolterraTransientSpec()
```

We can then run the analysis using `run_analysis`
```@example lotka
sol = run_analysis(spec)
```

or directly without creating the spec

```@example lotka
sol = LotkaVolterraTransient()
```

## [The JSON interface for Dyad Builder](@id json_transient_workflow)

In the case of Dyad Builder we will have JSON files that determine the transient analysis specification.
An example JSON would be
```@example lotka
json = """
{
    "name": "LotkaVolterraTransient",
    "alg": "Tsit5",
    "abstol": 1e-6,
    "reltol": 1e-3,
    "start": 0,
    "stop": 10
}
"""
```

From this JSON we can instantiate the spec via the StructTypes interface

```@example lotka
using JSON3, DyadInterface
spec = JSON3.read(json, LotkaVolterraTransientSpec)
```

We can then run the analysis using `run_analysis`

```@example lotka
sol = run_analysis(spec)
```

## Using the results of the Transient Analysis

Running `run_analysis` gives us a `TransientAnalysisSolution` object. This object is able to do a few things:

1. It can serialize.
2. It can make visualizations, tables or other kind of artifacts.
3. It can tell you what visualizations it can make.

To see what artifacts it can provide, generate the metadata as follows:

```@example lotka
metadata = AnalysisSolutionMetadata(sol)
```

To generate the artifacts, we can just call [`artifacts`](@ref) with the name
of the artifact.

```@example lotka
names = [v.name for v in metadata.artifacts]
```

```@example lotka
using Plots

artifacts(sol, names[1])
```

```@example lotka
artifacts(sol, names[2])
```

We can also make a customizable plot, a plot that is made for other systems (such as Dyad Builder) to send
more information on how such a plot can be customized. To do this, a customizer would make an
`AbstractVisualizationSpec`:

```@example lotka
vizdef = PlotlyVisualizationSpec(
    metadata.allowed_symbols[[2, 1]], (;), [Attribute("tstart", "start time", 0.0)])
```

and pass that to the customizable visualization:

```@example lotka
customizable_visualization(sol, vizdef)
```
