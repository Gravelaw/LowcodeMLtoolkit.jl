# JuliaPackages Reference

Use this reference when the task involves discovering Julia libraries rather than coding against a known dependency.

## What JuliaPackages is good for

JuliaPackages is useful for:

- keyword search across the Julia ecosystem
- browsing by category and subcategory
- scanning trending or popular packages
- quickly finding candidate packages in domains such as plotting, optimization, data frames, notebooks, machine learning, and web frameworks

Useful entry points:

- Home / trending: https://www.juliapackages.com/
- All packages: https://www.juliapackages.com/packages
- Categories: https://www.juliapackages.com/categories

## How to use it well

1. Start with the user’s task domain and search terms.
2. Check categories if the domain is broad, for example optimization, graphics, server, or database.
3. Pull a short candidate list instead of choosing the first result blindly.
4. Verify the final package using the package repository, docs, release activity, and compatibility story.

## Candidate selection heuristics

Prefer packages that have:

- a clear problem fit
- current documentation
- recent maintenance activity
- examples that match the user’s use case
- compatibility with the Julia version or stack in the project

Be cautious with packages that are old, sparsely documented, or appear abandoned.

## Examples of common domains

- Data tables: `DataFrames.jl`
- Plotting and visualization: `Makie.jl`, `Plots.jl`
- Notebooks: `Pluto.jl`, `IJulia.jl`
- Optimization: `JuMP.jl`, `Optim.jl`
- Web frameworks: `Genie.jl`

These examples are discovery anchors, not automatic recommendations. Verify before prescribing one.

## Rule for final answers

When package choice is materially important, browse current sources before recommending a package. Use JuliaPackages to discover candidates, but treat the package repository and official docs as the final authority on installation, API shape, and maintenance.
