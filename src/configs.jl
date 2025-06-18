struct ODEProblemConfig{A, T, S, AT, RT, D}
    alg::A
    tspan::T
    saveat::S
    abstol::AT
    reltol::RT
    dtmax::D
end

"""
    ODEProblemConfig(spec::AbstractAnalysisSpec)

Translate ODEProblem specific analysis specification attributes from strings to their julia native counterparts.

### Compatible specs need the following fields:

    - `alg`
    - `start`
    - `stop`
    - `abstol`
    - `reltol`

### The following optional fileds are also supported:

    - `saveat`
    - `dtmax`

### The fields that one can use from this struct are:

    - `alg`: the ODE integrator to use (supported values in the spec are: "auto", "Rodas5P", "FBDF", "Tsit5").
    - `tspan`: the timespan of the problem (obtained from `start` & `stop` in the spec).
    - `saveat`: the `saveat` keyword to be passed when solving. Optional in the spec, defaults to `Float64[]`.
    - `abstol`: the `abstol` keyword to be passed when solving.
    - `reltol`: the `reltol` keyword to be passed when solving.
    - `dtmax`: the `dtmax` keyword to be passed when solving. Optional in the spec, defaults to `spec.stop - spec.start`.
"""
function ODEProblemConfig(spec::AbstractAnalysisSpec)
    # prepare
    available_algs = Dict{String, SciMLBase.AbstractODEAlgorithm}(
        "auto" => DefaultODEAlgorithm(autodiff = AutoForwardDiff()),
        "Rodas5P" => Rodas5P(),
        "FBDF" => FBDF(),
        "Tsit5" => Tsit5()
    )
    if haskey(available_algs, spec.alg)
        alg = available_algs[spec.alg]
    else
        available_algs_str = join(keys(available_algs), ", ", " and ")
        error("ODE integration alg $(spec.alg) not recognized. " *
              "Choose one of: " * available_algs_str)
    end

    if hasproperty(spec, :dtmax)
        dtmax = !iszero(spec.dtmax) ? spec.dtmax : spec.stop - spec.start
    else
        dtmax = spec.stop - spec.start
    end

    if hasproperty(spec, :saveat)
        saveat = iszero(spec.saveat) ? Float64[] : spec.saveat
    else
        saveat = Float64[]
    end

    ODEProblemConfig(alg, (spec.start, spec.stop), saveat, spec.abstol, spec.reltol, dtmax)
end

"""
    get_simplified_model(spec::AbstractAnalysisSpec)

This function takes in a AbstractAnalysisSpec and returns a structurally simplified model. If the model is already simmplified
in the spec it just returns that. If the spec has additional passes (only `IfLifting` for now) for `structural_simplify`,
they are applied.

The spec needs to contain the model in `.model`. For `IfLifting`, a boolean field with the same name must be present.
"""
function get_simplified_model(spec::AbstractAnalysisSpec)
    model = spec.model
    if isscheduled(model)
        hasproperty(spec, :IfLifting) && spec.IfLifting &&
            @warn "IfLifting=true passed to an already simplified model, ignoring."
        model
    else
        if hasproperty(spec, :IfLifting) && spec.IfLifting
            structural_simplify(model, additional_passes = [IfLifting])
        else
            structural_simplify(model)
        end
    end
end
