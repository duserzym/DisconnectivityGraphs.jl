using Documenter
using DisconnectivityGraphs

DocMeta.setdocmeta!(
    DisconnectivityGraphs,
    :DocTestSetup,
    :(using DisconnectivityGraphs);
    recursive=true,
)

repo_slug = get(ENV, "GITHUB_REPOSITORY", "yimingzhang/DisconnectivityGraphs.jl")

makedocs(;
    modules=[DisconnectivityGraphs],
    authors="Yiming Zhang",
    sitename="DisconnectivityGraphs.jl",
    checkdocs=:exports,
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link="main",
        assets=["assets/custom.css"],
        sidebar_sitename=false,
    ),
    pages=[
        "Home" => "index.md",
        "Concepts" => "concepts.md",
        "API" => "api.md",
        "Examples" => "examples.md",
    ],
)

deploydocs(;
    repo="github.com/$(repo_slug).git",
    devbranch="main",
    push_preview=true,
)
