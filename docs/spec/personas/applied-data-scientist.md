# Persona: applied data scientist (primary)

Part of the [product spec](../PRODUCT.md). Status: MVP target (Phases 1–2).

## Who

- Builds tabular classification and regression models at work or in competitions.
- Knows train/validation/test discipline, metrics and common models.
- Reads Julia or Python; writes code when it is faster, but does not want to rebuild boilerplate (loading, splitting, encoding, tuning loops) for every project.
- Works on a laptop with 16 GB RAM; data is 10 MB to 1 GB.

## Goals

1. Go from raw CSV files to a validated model and a prediction file in one sitting.
2. Never leak test data into tuning by accident.
3. Hand the result to a colleague as a script that runs without the app.

## Frustrations today

- Notebooks drift: cells run out of order and results cannot be reproduced.
- Preprocessing fitted on all rows silently inflates scores.
- Python tools slow down on 10 M-row tables; visual tools hide the code.

## Workflow A: binary classification (Titanic)

| Step | User action | App behaviour | Spec |
| --- | --- | --- | --- |
| 1 | New project → "Binary classification" | Creates the project folder and manifest | PR-01 |
| 2 | Import `train.csv`, `test.csv`, `gender_submission.csv` (output contract) | Full-file read, checksums, row counts | PR-02 |
| 3 | Set `Survived` = target, `PassengerId` = id; `Pclass` → categorical | Saves roles; rejects target as a feature | PR-03 |
| 4 | Open Profile | Missing `Age`/`Cabin`/`Embarked` shown; survival rate by `Sex`/`Pclass` | PR-04 |
| 5 | Review warnings | `PassengerId` flagged if correlated with the target | PR-05 |
| 6 | Impute `Age` (median), encode `Sex`/`Embarked`, scale numerics | Parameters learned on train rows only | PR-06 |
| 7 | Stratified 5-fold, seed 42; `test.csv` locked | Fixed assignments with checksum | PR-07, PR-08 |
| 8 | Train logistic regression and EvoTrees; grid-tune tree depth | Trial table on validation folds | PR-09–PR-11 |
| 9 | Compare runs; promote the best | Side-by-side metrics (accuracy, AUC, log loss) | PR-12 |
| 10 | Explain | Coefficients / gain + permutation importance | PR-13 |
| 11 | Predict on `test.csv`, export | CSV with `PassengerId`, `Survived`; contract check passes | PR-14 |
| 12 | Export workflow | Julia project reproduces the CSV | PR-15 |

**Acceptance:** steps 1–12 complete on the reference machine with no code
typed; the exported script reproduces the prediction CSV byte for byte.

## Workflow B: regression (House Prices)

Same flow as A, with these differences:

| Step | Difference | Spec |
| --- | --- | --- |
| 3 | `SalePrice` = target, `Id` = id; `MSSubClass` and `OverallQual` changed from integer to categorical/ordinal | PR-03 |
| 4 | Skewness shown per numeric column; correlation table vs target | PR-04 |
| 6 | Log transform of the target, inverted on predictions | PR-06 |
| 7 | Random 5-fold | PR-07 |
| 8 | Ridge regression baseline and EvoTrees; metrics RMSE and RMSLE | PR-09–PR-11 |
| 10 | Residuals vs predicted chart | PR-13 |
| 11 | CSV with `Id`, `SalePrice` | PR-14 |

**Acceptance:** as for A, plus the RMSLE shown in the app equals the RMSLE
computed by the exported script within NFR-07 tolerance.

## Out of scope for this persona in the MVP

Feature-engineering code blocks, random or Bayesian search, stacking and
ensembles, model registry, deployment. These are candidates after Phase 2.
