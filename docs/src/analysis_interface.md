# Julia Side Analysis Interface

In Dyad, an analysis is a runnable query that can be performed on
a model to produce a solution object that is used to build various
visualizations to display to the user information about the model.
The Dyad Analysis Interface is the Julia-level interface for
calling analysis queries and interacting with the solution object.

## High-Level Definition

All analyses are defined in terms of extending other analyses. At the lowest level we have the special `Analysis`
type in Dyad which is extended by all analyses defined by julia packages. We call these analyses "base analyses".
When a user writes an analysis for a specific context, they will extend one of the base analyses.
This new analysis is named "derived analysis" and it can reference one or more models and it has its own parameters
besides the parameters inherited from the base analysis.

## Creating analyses in Dyad

1. A base analysis is specified according to a JSON schema inside .dyad files. This schema should live in the metadata section of a corresponding .dyad file in a top level folder `dyad` with its name matching the abstract spec, i.e. `dyad/TransientAnalysis.dyad` defines the `TransientAnalysisSpec` with its associated "TransientAnalysisSolution".
2. To define a derived analysis, the user would write Dyad code that extends one of the base analysis types.
3. The Dyad kernel will codegen julia code specific to that derived analysis.
4. To run an analysis, a user can either call the derived analysis constructor `<DerivedAnalysisName>Spec` and then `run_analysis`.
5. `run_analysis(spec::AbstractAnalysisSpec)` returns an `AbstractAnalysisSolution`.
6. One can know what the available artifacts from an `AbstractAnalysisSolution` are by running the command `AnalysisSolutionMetadata(::AbstractAnalysisSolution)`. This
metadata is designed to be a serializable object which can be
stored by Dyad Builder to allow for querying the available visualizations
in absence of the `AbstractAnalysisSolution`.
7. For artifacts, such as a standard plot or the generation of a standard data table, `artifacts(::AbstractAnalysisSolution, name::Symbol)` is called using the name of the artifact.
8. Each `AbstractAnalysisSolution` can also be imbued with a "customizable visualization". For the customizable visualization, more customization options are given to the user / Dyad Builder provider, such as the front end allowing the user to choose colors, fonts, etc. For this visualization, the provider
gives a `AbstractCustomizableVisualizationSpec` from which
`customizable_visualization(::AbstractAnalysisSolution, ::AbstractCustomizableVisualizationSpec)` should return a visualization of the "standard form" which satisfies the given spec.
If the analysis does not have customizable visualizations, then this method does not need to be implemented and the default fallback of `missing` will be used.

## Creating analyses in julia only

If one wants to use the DyadInterface interface without using the Dyad codegen, then they would only interact with
base analyses. In this case it is recommended to have control over the MTK model creation too. The dyad kernel
generates functions that can build the ready-to-use `ODESystem` for a particular model, but they also add a
caching layer which is to be used by the `<DerivedAnalysisName>Spec` constructors.
If you are using the base analysis interface, then you should create the model from scratch and not use the cached version.

In this case the steps would be:

1. Create a base analysis spec by first defining an abstract type `AbstractCustomAnalysisSpec <: AbstractAnalysisSpec` and then a `CustomAnalysisSpec <: AbstractCustomAnalysisSpec`.
2. Create a `CustomAnalysisSolution <: AbstractAnalysisSolution` that is a fully serializable struct (via [`serialize_solution`](@ref)).
3. Define `DyadInterface.run_analysis(spec::CustomAnalysisSpec)` that returns a `CustomAnalysisSolution`.
4. Define `DyadInterface.AnalysisSolutionMetadata(::CustomAnalysisSolution)` such that it returns the available artifacts that your analysis defines.
5. Define `DyadInterface.artifacts(res::CustomAnalysisSolution, name::Symbol)` which returns the requested artifact from your result based on the `name` that is passed.
6. Define `DyadInterface.customizable_visualization(sol::CustomAnalysisSolution, ::AbstractCustomizableVisualizationSpec)` for vizualizations that take user input.

## Creating analyses from Dyad Builder

With the current design Dyad Builder can only create derived analyses. As such the user will first select from one of the predefined base analyses types and then fill in the inherited base analysis parameters.
The use can potentially add new analysis parameters if they want to override model parameters. For example if a model associated to the analysis has a parameter `p` with a default value of 1, the user can override it at the analysis level (without chanigng the original model) by creating an analysis parameter `p` that will be identically mapped to the model
parameter `p` by the Dyad codegen. In this way we can generate JSON files that specify values for `p` and change its value
without re-running the codegen. Only if the structure of the analysis changes (like adding new analysis parameters) we will need to re-run the codegen.

## Abstract Interface Definitions

```@docs
DyadInterface.AbstractAnalysisSpec
DyadInterface.AbstractAnalysisSolution
DyadInterface.AbstractCustomizableVisualizationSpec
```

### Reusable interface utilities

When creating new analyses, it can be useful to be able to reuse the translation of certain parts of the spec.

```@docs
DyadInterface.ODEProblemConfig
```

Another reusable part is getting a structurally simplified model out of an analysis spec. This can be useful
over just calling `structural_simplify` in your own analysis becasue it also handles adding additional passes.

```@docs
DyadInterface.get_simplified_model
```

## Interface Metadata Queries

```@docs
DyadInterface.ArtifactMetadata
DyadInterface.AnalysisSolutionMetadata
DyadInterface.rebuild_sol
```

## Customizable Visualizations

```@docs
DyadInterface.Attribute
DyadInterface.PlotlyVisualizationSpec
DyadInterface.customizable_visualization
```

## Artifacts

```@docs
DyadInterface.artifacts
DyadInterface.ArtifactType
DyadInterface.ArtifactType.PlotlyPlot
DyadInterface.ArtifactType.DataFrame
DyadInterface.ArtifactType.Download
```

## Running analyses

```@docs
DyadInterface.run_analysis
```


## Serialization

The results of [`run_analysis`](@ref) are serialized and can be deserialized to inspect earlier runs.
The analysis author can customize this step if needed.

```@docs
DyadInterface.serialize_solution
DyadInterface.deserialize_solution
```
