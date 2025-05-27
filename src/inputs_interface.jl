"""
    AbstractAnalysisSpec

The abstract type for all analysis specifications that maps to Dyad analyses.
The subtypes of this type will use [`run_analysis`](@ref) to perfom analyses.
The result of an analysis is always a subtype of [`AbstractAnalysisSolution`](@ref).

The argument to `run_analysis` is a base analysis specification defined on the Julia side
as a `struct` that subtypes [`AbstractAnalysisSpec`](@ref) and referenced
on the Dyad side via a `partial analysis` that extends `Analysis`.
Base analysis specifications can be built either manually via their constructors
or by derived analysis specifications that are created by the codegen.
To manually build a base analysis specification like the [`TransientAnalysisSpec`](@ref),
one can use

```julia
model = MyModel() # build an MTK model
spec = TransientAnalysisSpec(;
    model, name = :MyModelTransient, abstol = 1e-6, reltol = 1e-3, stop = 10.0)
```

For more details, check out [the julia workflow for the Transient Analysis](@ref julia_transient_workflow).

The difference between a base analysis and a derived one is that a base analysis
does not impose defaults for all of its fields, but the values need to be provided
upon construction.
A derived analysis will have default values for all its parameters and it will
build the appropriate base analysis.
Since base analyses and derived ones share behaviours, it is recommended to define
an abstract type togheter with the base type.
As an example, one can write a `show` method for the abstract type that corresponds
to the analysis and that would then also provide a `show` method that will work for
the derived analysis specifications that will be defined by the codegen.
Suppose we want to build an analysis named `CustomAnalysis`.
In this case we would have the following:

```julia
abstract type AbstractCustomAnalysisSpec <: AbstractAnalysisSpec end

@kwdef struct CustomAnalysisSpec{M, T} <: AbstractCustomAnalysisSpec
    name::Symbol
    model::M
    analysis_parameter::T
end
```

which define the base analysis and if we have a particular model, `ModelA`,
a custom analysis created by the codegen would be something like

```julia
@kwdef mutable struct ModelACustomAnalysisSpec <: AbstractCustomAnalysisSpec
    name::Symbol = :ModelACustomAnalysis
    analysis_parameter::Float64 = 1.0
    model::Union{Nothing, ODESystem} = ModelA(; name)
end
```

and one would use this in the following way:

```julia
spec = ModelACustomAnalysisSpec()
run_analysis(spec)
```

The derived analysis specification is used to fully represent a concrete analysis declaratively
and it can be mapped to a JSON file which can be used by Dyad Builder to interact in an efficient
manner with the analysis by avoiding codegen on non-structural analysis modifications.
For more details see the [the JSON workflow for the Transient Analysis](@ref json_transient_workflow).

The corresponding Dyad code would be

```
partial analysis CustomAnalysis
  extends Analysis
  parameter analysis_parameter::Real

  model::Empty = Empty()
end
```

for the base analysis, which should be placed in a `.dyad` file inside a `YourPackage/dyad` folder, and

```
analysis ModelACustomAnalysis
  extends CustomAnalysis(analysis_parameter=1.0)
  model = ModelA()
end
```

for the derived analysis that an user would write. The `model` parameter is separate from other
parameters of the analysis because one can also override model parameters inside an analysis:

```
analysis ModelACustomAnalysis
  extends CustomAnalysis(analysis_parameter=1.0)
  parameter model_parameter1::Real = 1
  model = ModelA(model_parameter=model_parameter1)
end
```

Note that the analysis parameter `model_parameter1` is mapped to the model parameter `model_parameter`,
so the parameters in the analysis are not restricted to the names inside the model.
For more details see the [the Dyad workflow for the Transient Analysis](@ref dyad_transient_workflow).

The base analysis also needs a JSON schema

```json
{
  "title": "CustomAnalysis",
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "description": "Analysis Type",
      "default": "CustomAnalysis"
    },
    "model": {
      "type": "object",
      "description": "Model to simulate",
      "dyad:type": "component"
    },
    "analysis_parameter": {
      "type": "number",
      "description": "Analysis parameter"
    },
    "required": [
      "name",
      "analysis_parameter"
    ]
  }
}
```

which should be placed in a root folder named `assets`. In the future this step should be simplified
so that we only require just one source for the analysis definition.
For a complete implementation, see the `TransientAnalysis`.

Note that currently for an analysis to be recognized, the `.dyad` file that defines it must be inside of
a component library.
"""
abstract type AbstractAnalysisSpec end

StructTypes.StructType(::Type{<:AbstractAnalysisSpec}) = StructTypes.Mutable()
Base.nameof(spec::AbstractAnalysisSpec) = spec.name

function Base.:(==)(
        spec1::AbstractAnalysisSpec, spec2::AbstractAnalysisSpec)
    mapreduce(f -> getfield(spec1, f) == getfield(spec2, f), &, fieldnames(typeof(spec1)))
end

"""
    run_analysis(spec::AbstractAnalysisSpec)::AbstractAnalysisSolution

Runs the analysis corresponding to the specification. The return type should always be a subtype of
[`AbstractAnalysisSolution`](@ref) and be something serializable.

# Positional Arguments

  - `spec`: `AbstractAnalysisSpec` object.
"""
function run_analysis(::AbstractAnalysisSpec) end

"""
    simulate(spec::AbstractAnalysisSpec; kwargs...)

Common interface for simulations of [`AbstractAnalysisSpec`](@ref)s.
Packages that extend this might also add additional arguments.
While this would not be directly used by Dyad, higher level functions,
such as `run_analysis` can use this function.

# Positional Arguments

  - `spec`: [`AbstractAnalysisSpec`](@ref) object.

# Keyword Arguments

  - `kwargs`: Extra keyword arguments to override extra keyword arguments used
    in the construction the specification. This can be useful for simulating multiple times
    with different solve configurations, like tolerances without reconstructing
    the `AbstractAnalysisSpec` object.
"""
function simulate(spec::AbstractAnalysisSpec; kwargs...) end
