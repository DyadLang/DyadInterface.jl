using ModelingToolkit: @named, @variables, @parameters, ODESystem, complete, D_nounits,
                       t_nounits, structural_simplify

@setup_workload begin
    function _reactionsystem()
        sts = @variables s1(t_nounits)=2.0 s1s2(t_nounits)=2.0 s2(t_nounits)=2.0
        ps = @parameters k1=1.0 c1=2.0
        eqs = [D_nounits(s1) ~ -0.25 * c1 * k1 * s1 * s2
               D_nounits(s1s2) ~ 0.25 * c1 * k1 * s1 * s2
               D_nounits(s2) ~ -0.25 * c1 * k1 * s1 * s2]
        return structural_simplify(ODESystem(eqs, t_nounits; name = :reactionsystem))
    end

    @compile_workload begin
        spec = TransientAnalysisSpec(
            name = :test_sys,
            model = _reactionsystem(),
            abstol = 1e-6,
            reltol = 1e-3,
            stop = 1.0,
            saveat = [0, 1.0]
        )
        run_analysis(spec)
    end
end
