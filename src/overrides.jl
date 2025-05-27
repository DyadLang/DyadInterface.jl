function update_model(model::AbstractTimeDependentSystem, overrides::NamedTuple)::ODESystem
    new_ps = Num[]
    new_defs = Dict{Num, Any}()
    if does_namespacing(model)
        base_model = toggle_namespacing(model, false)
    else
        base_model = model
    end
    for (k, v) in pairs(overrides)
        model_param = parse_variable(base_model, string(k))
        push!(new_ps, parse_variable(base_model, string(k)))
        push!(new_defs, model_param => v)
    end
    extra_sys = ODESystem(Equation[], ModelingToolkit.get_iv(model), [], new_ps;
        name = nameof(model),
        description = ModelingToolkit.description(model),
        defaults = new_defs)
    if ModelingToolkit.iscomplete(model)
        complete(extend(extra_sys, model))
    else
        extend(extra_sys, model)
    end
end
