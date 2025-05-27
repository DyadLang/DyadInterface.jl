using ModelingToolkit
using ModelingToolkit: D_nounits as D, t_nounits

function lotka(; α = 1.3)
    t = t_nounits
    @variables x(t)=3.1 y(t)=1.5
    @parameters α=α β=0.9 γ=0.8 δ=1.8
    eqs = [D(x) ~ α * x - β * x * y, D(y) ~ -δ * y + γ * x * y]
    return complete(ODESystem(eqs, t, name = :lotka))
end
