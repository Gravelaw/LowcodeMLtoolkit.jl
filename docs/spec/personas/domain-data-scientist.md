# Persona: domain data scientist (Phase 3)

Part of the [product spec](../PRODUCT.md). Status: second persona; built on
the MVP after Phase 2 ships.

## Who

- Works with grouped or sequential data: wells, patients, machines, stores.
- Knows the domain deeply; knows that row-random validation gives scores that are too good.
- Data is private and often cannot leave the machine.

## Goals

1. Validate by group (well, patient) or by depth/time, with a test set that stays untouched.
2. See domain plots (for example, a log curve against depth) next to the model results.
3. Export a pipeline that reproduces predictions from raw files.

## Workflow: wellbore regression (ROGII-style)

| Step | User action | App behaviour | Spec / new need |
| --- | --- | --- | --- |
| 1 | Import several well files plus a typewell reference | Multi-file import into one table with a `well_id` column | PR-02 + multi-file import |
| 2 | Set `TVT` = target, `well_id` = group, `MD` = depth; fix units | Roles and units saved | PR-03 + units, depth role |
| 3 | Profile per well | Per-group statistics; non-increasing `MD` flagged | PR-04 + per-group profile |
| 4 | Add rolling, lag and derivative features of `GR` along `MD` | Features computed within each well only | New: sequence features |
| 5 | Grouped k-fold by `well_id`; lock evaluation wells | No well in both train and validation | PR-07, PR-08 |
| 6 | Train ridge and EvoTrees; tune window length and depth | Trials scored on grouped folds | PR-09–PR-11 |
| 7 | Review RMSE per well and residuals against depth | Per-group metrics and plots | PR-12, PR-13 + per-group metrics |
| 8 | Export predictions and the pipeline | Reproducible from raw files | PR-14, PR-15 |

**Acceptance (Phase 3):** steps 1–8 complete on the reference machine, and
grouped validation provably never shares a `well_id` between folds.

## New capabilities this persona adds

Multi-file import with a source column, a units and depth/time role,
per-group profiling and metrics, within-group sequence features, and domain
charts (curve against depth, XY trajectory).
