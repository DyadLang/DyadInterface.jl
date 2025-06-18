module DyadInterfaceMakieExt

using DyadInterface: TransientAnalysisSolution, rebuild_sol
import Makie

Makie.plottype(::TransientAnalysisSolution) = Makie.Lines

function Makie.used_attributes(T::Type{<:Makie.Plot}, sol::TransientAnalysisSolution)
    Makie.used_attributes(T, sol.sol)
end

function Makie.convert_arguments(plottype::T, sol::TransientAnalysisSolution;
        kwargs...) where {T <: Type{<:Makie.AbstractPlot}}
    return Makie.convert_arguments(plottype, rebuild_sol(sol); kwargs...)
end

end
