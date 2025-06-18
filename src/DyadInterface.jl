module DyadInterface

export TransientAnalysisSpec, TransientAnalysis, SteadyStateAnalysisSpec,
       SteadyStateAnalysis
export simulate, run_analysis, rebuild_sol, get_simplified_model
export AbstractAnalysisSpec, AbstractAnalysisSolution, AbstractTransientAnalysisSpec,
       AnalysisSolutionMetadata, TransientAnalysisSolution,
       ArtifactType, Attribute, PlotlyVisualizationSpec
export artifacts, customizable_visualization
export serialize_solution, deserialize_solution
# reexports
export symbolic_container

using Preferences: Preferences
using CommonSolve: solve
using SciMLBase: SciMLBase, DEProblem, ODEProblem, SteadyStateProblem, FullSpecialize,
                 AbstractODESolution, ODEFunction, CallbackSet, successful_retcode,
                 strip_solution
using NonlinearSolve: FastShortcutNonlinearPolyalg, TrustRegion, NewtonRaphson,
                      LevenbergMarquardt
using RecipesBase: RecipesBase, plot, @recipe, @series
using SymbolicIndexingInterface: SymbolicIndexingInterface, variable_symbols, getname,
                                 symbolic_container
using ModelingToolkit: ModelingToolkit, AbstractTimeDependentSystem, ODESystem,
                       ODEProblemExpr, defaults,
                       parse_variable, Num, Equation, extend,
                       does_namespacing, toggle_namespacing, isscheduled,
                       IfLifting
using OrdinaryDiffEqDefault: DefaultODEAlgorithm
using OrdinaryDiffEqTsit5: Tsit5
using OrdinaryDiffEqRosenbrock: Rodas5P
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
    license_text = """
    JuliaHub provides Dyad Studio under the Dyad Source Available License for educational and personal use (https://github.com/DyadLang). 
    For commercial usage, please contact us (https://juliahub.com/company/contact-us-dyad).

    To report any bugs, issues, or to request features for Dyad software,
    please use the public Github repository DyadIssues, 
    located at https://github.com/JuliaComputing/DyadIssues.
    """

    printstyled(stderr, "Important Note: ", bold = true)
    print(stderr, license_text)
end

function __init__()
    if Preferences.@load_preference("PrintLicense", true) && # we should be generating output
       ccall(:jl_generating_output, Cint, ()) != 1 # we are not precompiling
        print_license()
    end
end

end # module DyadInterface
