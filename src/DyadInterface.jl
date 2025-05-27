module DyadInterface

export TransientAnalysisSpec, SteadyStateAnalysisSpec
export simulate, run_analysis, rebuild_sol, get_simplified_model
export AbstractAnalysisSpec, AbstractAnalysisSolution, AbstractTransientAnalysisSpec,
       AnalysisSolutionMetadata, TransientAnalysisSolution,
       ArtifactType, Attribute, PlotlyVisualizationSpec
export artifacts, customizable_visualization
export serialize_solution, deserialize_solution

using Preferences: Preferences
using CommonSolve: solve
using SciMLBase: SciMLBase, DEProblem, ODEProblem, SteadyStateProblem, FullSpecialize,
                 AbstractODESolution, ODEFunction, CallbackSet, successful_retcode,
                 strip_solution
using NonlinearSolve: FastShortcutNonlinearPolyalg, TrustRegion, NewtonRaphson,
                      LevenbergMarquardt
using RecipesBase: RecipesBase, plot, @recipe, @series
using SymbolicIndexingInterface: variable_symbols, getname, symbolic_container
using ModelingToolkit: ModelingToolkit, AbstractTimeDependentSystem, ODESystem,
                       ODEProblemExpr, defaults,
                       parse_variable, Num, Equation, extend,
                       does_namespacing, toggle_namespacing, isscheduled,
                       IfLifting
using OrdinaryDiffEqDefault: DefaultODEAlgorithm
using OrdinaryDiffEqTsit5: Tsit5
using OrdinaryDiffEqRosenbrock: Rodas4
using OrdinaryDiffEqBDF: FBDF
using ADTypes: AutoForwardDiff
using UUIDs: uuid4, UUID
using PrecompileTools: @setup_workload, @compile_workload
using DataFrames: DataFrame
using StructTypes: StructTypes, Struct
using EnumX: EnumX
using Setfield: @set
using RelocatableFolders: @path
using Serialization: serialize, deserialize

include("inputs_interface.jl")
include("solution_interface.jl")
include("configs.jl")
include("transient_analysis.jl")
include("steady_state_analysis.jl")
include("overrides.jl")
include("precompile.jl")

function print_license()
    license_text = """JuliaHub products (Dyad with all its modules, and all
    Dyad packages provided through the JuliaHubRegistry) are commercial
    products of JuliaHub, Inc. They are free to use for non-commercial academic
    teaching and research purposes. For commercial users, license fees apply.
    Please refer to the End User License Agreement (https://juliahub.com/company/eula/)
    for details. Please contact sales@juliahub.com for purchasing information.

    To report any bugs, issues, or feature requests for Dyad software,
    please use the public Github repository DyadIssues, located at
    https://github.com/JuliaComputing/DyadIssues.
    """

    printstyled(stderr, "Important Note: ", bold = true)
    print(stderr, license_text)
end

function __init__()
    if Preferences.@load_preference("PrintLicense", true)
        print_license()
    end
end

end # module DyadInterface
