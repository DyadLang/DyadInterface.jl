abstract type AbstractSteadyStateAnalysisSpec <: AbstractAnalysisSpec end

"""
    SteadyStateAnalysisSpec(; name, model, alg, abstol, reltol)

Steady state analysis specification, specifying how a numerical `SteadyStateProblem` would be formulated and solved.

The structure is an interface specification corresponding to
a [base analysis type in Dyad](https://symmetrical-adventure-kqpeovn.pages.github.io/design/analysis/).

When one creates an analysis in Dyad, the definition would look like

```
analysis RLCTransient
  extends SteadyState(abstol=10m, reltol=1m)
  parameter C::Capacitance=1m
  model = RLCModel(C=C)
end
```

# Keyword Arguments

  - `name`: The name of the analysis
  - `model`: An `ODESystem` representing the model that will be used for numerical integration
  - `alg`: The nonlinear solver to use as a string. Possible options are: `"auto"` (default), `"TrustRegion"`, `"LevenbergMarquardt"`, `"NewtonRaphson"`
  - `abstol`: Absolute tolerance to use during the simulation
  - `reltol`: Relative tolerance to use during the simulation
"""
@kwdef struct SteadyStateAnalysisSpec{S <: AbstractString, T1, T2, M <: ODESystem} <:
              AbstractSteadyStateAnalysisSpec
    name::Symbol = :SteadyStateAnalysis
    model::M
    alg::S = "auto"
    abstol::T1 = 1e-8
    reltol::T2 = 1e-8
    IfLifting::Bool = false
end

function setup_prob(model, overrides, ::Nothing, kwargs)
    SteadyStateProblem{true}(model, overrides; kwargs...)
end

get_alg(spec::AbstractSteadyStateAnalysisSpec) = spec.alg

function Base.show(io::IO, ::MIME"text/plain", spec::AbstractSteadyStateAnalysisSpec)
    print(io, "Steady State Analysis specification for ")
    printstyled(io, "$(nameof(spec))\n", color = :green, bold = true)
    # println(io, "overrides: [", join(spec.overrides, ", "), "]")
    alg = get_alg(spec)
    print(io, "alg: ", alg)
end

struct SteadyStateAnalysisSolution{SP, S} <: AbstractAnalysisSolution
    spec::SP
    sol::S
    prob_expr::Expr
end

function Base.show(io::IO, m::MIME"text/plain", sol::SteadyStateAnalysisSolution)
    printstyled(io, "Steady State Analysis Solutiuon for $(nameof(sol))\n",
        color = :blue, bold = true)
    show(io, m, sol.sol)
end

SciMLBase.successful_retcode(sol::SteadyStateAnalysisSolution) = successful_retcode(sol.sol)

Base.nameof(sol::SteadyStateAnalysisSolution) = sol.spec.name

SteadyStateAnalysis(; kwargs...) = run_analysis(SteadyStateAnalysisSpec(; kwargs...))

function run_analysis(spec::SteadyStateAnalysisSpec)
    # prepare
    available_algs = Dict(
        "auto" => FastShortcutNonlinearPolyalg(),
        "TrustRegion" => TrustRegion(),
        "LevenbergMarquardt" => LevenbergMarquardt(),
        "NewtonRaphson" => NewtonRaphson()
    )

    if haskey(available_algs, spec.alg)
        alg = available_algs[spec.alg]
    else
        available_algs_str = join(keys(available_algs), ", ", " and ")
        error("Nonlinear solve alg $(spec.alg) not recognized. " *
              "Choose one of: " * available_algs_str)
    end
    simplified_model = get_simplified_model(spec)
    prob = setup_prob(simplified_model, [], nothing, (;))

    # solve
    sol = solve(prob, alg; spec.abstol, spec.reltol)

    # post-process
    # workaround for solution stripping issue
    stripped_sol = maybe_strip_sol(sol, Val(true))
    sys = sol.prob.f.sys
    prob_expr = ODEProblemExpr{true}(sys, [], nothing)

    res = SteadyStateAnalysisSolution(spec, stripped_sol, prob_expr)
    return res
end

function rebuild_sol(sol::SteadyStateAnalysisSolution)
    # prob = eval(sol.prob_expr)
    # sol = sol.sol
    # TODO: for SciMLBase.NonlinearSolution it looks like @set does not work
    # full_sol = @set sol.prob = prob

    return sol.sol
end

function AnalysisSolutionMetadata(sol::SteadyStateAnalysisSolution)
    artifacts = [ArtifactMetadata(
        :SimulationSolutionTable,
        ArtifactType.DataFrame,
        "Solution timeseries table",
        "Solution timeseries table for $(nameof(sol))"
    )]
    push!(artifacts,
        ArtifactMetadata(
            :RawSolution,
            ArtifactType.Native,
            "The underlying NonlinearSolution for the analysis run.",
            "The underlying NonlinearSolution object for the analysis run."
        ),
        ArtifactMetadata(
            :SimplifiedSystem,
            ArtifactType.Native,
            "The simplified (flat) model used in the analysis.",
            "The structurally simplified model corresponding to the analysis."
        )
    )
    if !isnothing(sol.spec.model)
        push!(artifacts,
            ArtifactMetadata(
                :InitialSystem,
                ArtifactType.Native,
                "The model provided to the analysis.",
                "The initial model provided to the analysis (before symplification)."
            )
        )
    end

    full_sol = rebuild_sol(sol)
    allowed_symbols = getname.(variable_symbols(full_sol))

    AnalysisSolutionMetadata(artifacts, allowed_symbols)
end

function artifacts(sol::SteadyStateAnalysisSolution, name::Symbol)
    full_sol = rebuild_sol(sol)
    if name == :SimulationSolutionTable
        DataFrame(full_sol)
    elseif name == :RawSolution
        full_sol
    elseif name == :SimplifiedSystem
        symbolic_container(sol)
    elseif name == :InitialSystem
        sol.spec.model
    else
        error("Artifact type $name not recognized!")
    end
end

function customizable_visualization(
        ::SteadyStateAnalysisSolution, ::PlotlyVisualizationSpec)
    missing
end

function SymbolicIndexingInterface.symbolic_container(sol::SteadyStateAnalysisSolution)
    full_sol = rebuild_sol(sol)
    symbolic_container(full_sol.prob.f)
end
