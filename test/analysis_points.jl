using ModelingToolkit
using ModelingToolkitStandardLibrary.Blocks
using ModelingToolkit: t_nounits as t
using DyadInterface
using Test

@named P = FirstOrder(k = 1, T = 1)
@named C = Gain(; k = -1)

eqs = [connect(P.output, C.input)
       connect(C.output, :plant_input, P.input)]
sys = ODESystem(eqs, t, systems = [P, C], name = :feedback_system)

new_sys = DyadInterface.update_model(sys, (var"P.T" = 2,))

matrices_S, _ = get_sensitivity(sys, :plant_input)
new_matrices_S, _ = get_sensitivity(new_sys, :plant_input)

@test only(matrices_S.A) == -2
@test only(new_matrices_S.A) == -1
@test only(matrices_S.B) == 1
@test only(new_matrices_S.B) == 0.5
@test matrices_S.C == new_matrices_S.C
@test matrices_S.D == new_matrices_S.D
