using DyadInterface

using Test
using Aqua
using JET
using Plots # we need it loaded for JET to be able to see the methods

@testset "Aqua" begin
    # Aqua.find_persistent_tasks_deps(DyadInterface) # this is too buggy to use with SciML and monorepos
    Aqua.test_ambiguities(DyadInterface, recursive = false)
    Aqua.test_deps_compat(DyadInterface)
    Aqua.test_piracies(DyadInterface)
    Aqua.test_project_extras(DyadInterface)
    Aqua.test_stale_deps(DyadInterface, ignore = Symbol[])
    Aqua.test_unbound_args(DyadInterface)
    Aqua.test_undefined_exports(DyadInterface)
end

# no non-const globals
non_const_names = filter(x -> !isconst(DyadInterface, x), names(DyadInterface, all = true))
# filter out gensymed names
filter!(x -> !startswith(string(x), "#"), non_const_names)
@test isempty(non_const_names)

@testset "Code linting (JET.jl)" begin
    JET.test_package(DyadInterface; target_defined_modules = true)
end
