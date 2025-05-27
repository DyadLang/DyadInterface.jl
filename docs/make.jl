using Documenter, DyadInterface

pages = [
    "Home" => "index.md",
    "transient_workflow.md",
    "analysis_interface.md",
    "api.md",
    "common_simulate.md"
]

ENV["GKSwstype"] = "100"
ENV["JULIA_DEBUG"] = "Documenter"

makedocs(;
    sitename = "DyadInterface",
    authors = "Chris Rackauckas",
    modules = [DyadInterface],
    clean = true, doctest = false, linkcheck = true,
    warnonly = [:missing_docs],
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", nothing) == "true",
        assets = String[],
        canonical = "https://JuliaComputing.github.io/DyadInterface.jl"),
    pages)

deploydocs(;
    repo = "github.com/JuliaComputing/DyadInterface.jl.git",
    branch = "jhub-pages",
    push_preview = true)
