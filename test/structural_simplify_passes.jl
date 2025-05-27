using ModelingToolkit
using ModelingToolkit: D_nounits as D, t_nounits as t
using DyadInterface
using SciMLBase
using Test

@testset "IfLifting" begin
    @mtkmodel SimpleAbs begin
        @variables begin
            x(t) = 1
            y(t)
        end
        @equations begin
            D(x) ~ abs(y)
            y ~ sin(t)
        end
    end

    @named model = SimpleAbs()
    spec = TransientAnalysisSpec(;
        name = :test, model, stop = 1.0, abstol = 1e-6, reltol = 1e-6, IfLifting = true)
    res = @test_nowarn run_analysis(spec)

    @test SciMLBase.successful_retcode(res)
end
