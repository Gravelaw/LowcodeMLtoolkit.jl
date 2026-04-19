# Julia Workflow Reference

Use this reference when implementing or reviewing Julia code.

## Core project workflow

- Prefer project-specific environments. Julia `Pkg` is designed around environments rather than one global dependency set.
- Activate with `Pkg.activate(".")` for local project work.
- Add dependencies to the active environment with `Pkg.add`.
- Instantiate an existing project with `Pkg.instantiate()`.

## Standard package structure

From the Pkg docs, a minimal package contains:

```text
PackageName/
  Project.toml
  src/
    PackageName.jl
```

Typical package repos also add:

```text
test/
  runtests.jl
```

## Recommended package workflow

- For a quick minimal package, use `pkg> generate PackageName`.
- For a fuller starter with CI/docs preferences, the Pkg docs recommend `PkgTemplates`.
- Put the module entry point in `src/PackageName.jl`.
- Split implementation across additional files with `include("file.jl")` from the module file.

## Coding conventions

- Use 4 spaces per indentation level.
- Write functions instead of long top-level scripts.
- Keep code generic when possible; do not overconstrain argument types without need.
- Name modules and types with capitalization and camel case.
- Name functions in lowercase; use underscores only when readability benefits.
- Suffix mutating functions with `!`.
- Prefer explicit imports in packages to reduce namespace ambiguity.
- Prefer ASCII operators and identifiers unless the codebase already uses Unicode heavily.

## Testing conventions

- Package tests run from `test/runtests.jl`.
- `Pkg.test()` runs tests in a fresh process and activates test dependencies.
- Use `Test` for assertions.
- Add test-specific dependencies through `test/Project.toml` or the older `[extras]` and `[targets]` mechanism.

## Documentation conventions

- Add docstrings to public functions, types, and modules.
- Include examples in docstrings where useful.
- Prefer doctest-style examples for user-facing API documentation.

## Source notes

This reference is based on:
- Julia Style Guide: https://docs.julialang.org/en/v1/manual/style-guide/
- Julia Modules manual: https://docs.julialang.org/en/v1/manual/modules/
- Julia Documentation manual: https://docs.julialang.org/en/v1/manual/documentation/
- Pkg introduction and environments: https://pkgdocs.julialang.org/dev/
- Creating packages: https://pkgdocs.julialang.org/v1/creating-packages/
