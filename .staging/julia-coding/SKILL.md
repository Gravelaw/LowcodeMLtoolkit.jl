---
name: "julia-coding"
description: "Implement, review, refactor, or explain Julia code; set up Julia projects and packages; choose Julia libraries; and follow idiomatic Julia package, module, testing, and Pkg workflows. Use when the user wants help writing Julia, structuring a Julia package, managing Project.toml and Manifest.toml environments, selecting packages from the Julia ecosystem, or debugging Julia-specific code and package issues."
---

# Julia Coding

Use this skill for Julia implementation and review work. Prefer official Julia and Pkg documentation for language and package-manager behavior. Use JuliaPackages for ecosystem discovery, package comparison, and category scanning, then verify the chosen package against its repository or official docs before committing to it.

## Quick start

1. Identify whether the task is:
   - script or notebook work
   - a reusable package
   - package selection or ecosystem research
   - debugging, testing, or performance cleanup
2. For project setup, default to per-project environments instead of the global environment.
3. For package work, prefer standard Julia package layout and `Pkg` workflows.
4. For package recommendations, search JuliaPackages first, then validate the final candidate using upstream documentation.

## Standard workflow

### Project and environment setup

- Create or activate a project-local environment with `Pkg.activate(".")`.
- Add dependencies to the active environment instead of relying on the global default environment.
- Commit `Project.toml`; commit `Manifest.toml` when reproducibility matters for the repo or app.

### Package layout

Use the standard structure unless the repo already uses something different:

```text
MyPackage/
  Project.toml
  Manifest.toml
  src/
    MyPackage.jl
  test/
    runtests.jl
```

- Put the main module in `src/PackageName.jl`.
- Split larger packages with `include("file.jl")` from the main module file.
- Keep public API names explicit with `export` or `public` when the Julia version supports it.

### Coding rules

- Write functions, not top-level scripts, for reusable or performance-sensitive code.
- Prefer generic methods over overly concrete type restrictions unless the API genuinely requires them.
- Follow Julia naming conventions: modules and types in `PascalCase`, functions in lowercase, mutating functions with `!`.
- Use 4-space indentation, readable whitespace, and ASCII identifiers/operators unless the codebase already relies on Unicode.
- Prefer `using Foo: Foo, f` or `import Foo: f` over broad imports in package code.
- Avoid unnecessary macros, global mutable state, and catching errors that should be prevented by validation.

### Testing and docs

- Put package tests in `test/runtests.jl`.
- Use `Test` for assertions and test edge cases, not just happy paths.
- Add docstrings to exported functions, types, and modules when touching public API.
- Prefer doctest-style examples when writing user-facing examples.

## Package selection workflow

When the user needs a Julia library:

1. Search JuliaPackages by keyword, category, or trending lists.
2. Narrow to packages that match the task domain.
3. Verify maintenance and API fit from the package repository or official docs.
4. Present 1-3 candidates with tradeoffs instead of a long unfiltered list.

Read `references/julia-packages.md` for discovery guidance and `references/julia-workflow.md` for official Julia package and coding conventions.

## Quality bar

- Keep code idiomatic and package-local.
- Prefer reproducible environments.
- Do not assume a package is current or maintained just because it appears in JuliaPackages.
- For ecosystem recommendations or volatile package choices, browse and cite current sources before answering.
