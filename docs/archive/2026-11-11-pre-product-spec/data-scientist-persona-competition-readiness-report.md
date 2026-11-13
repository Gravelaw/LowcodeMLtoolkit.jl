# Data Scientist Persona Competition Readiness Report

Date: 2026-06-20

## Purpose

This report evaluates JuliaFlow as a local-first data science application from the perspective of a data scientist who wants to solve real predictive analytics projects end to end.

Reference projects:

- Titanic - Machine Learning from Disaster: beginner tabular binary classification.
- House Prices - Advanced Regression Techniques: advanced tabular regression with mixed feature types and leakage-sensitive validation.
- ROGII - Wellbore Geology Prediction: domain/geoscience sequential-spatial regression along horizontal wellbores.

These projects are references and examples, not the product scope. The generalized product question is: what must the application support so a data scientist can import raw local data, diagnose schema and data quality, run statistical EDA, build features, train and tune models, validate rigorously, test on held-out data, and export reproducible prediction artifacts without leaving JuliaFlow for core workflow steps?

## Source Context

- Kaggle Titanic data dictionary identifies `Survived` as the target and includes fields such as `Pclass`, `Sex`, `Age`, `SibSp`, `Parch`, `Fare`, and `Embarked`.
- Kaggle House Prices data identifies `SalePrice` as the target and includes house/property predictors such as building class, neighborhood, quality, living area, basement/garage fields, and sale conditions.
- Kaggle ROGII describes the goal as predicting geology along a horizontal wellbore. Public Kaggle snippets describe wellbore columns such as `MD`, `X`, `Y`, `Z`, `GR`, `TVT_input`, and typewell reference information.
- KNIME, Orange, and H2O references show the daily-use expectations for low-code data and ML tools: broad local data access and visual workflows, no-code widget/canvas workflows, interactive EDA, AutoML/tuning, explainability, model registry, deployment, and drift/model monitoring.

Sources:

- https://www.kaggle.com/c/titanic/data
- https://www.kaggle.com/c/house-prices-advanced-regression-techniques/data
- https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/data
- https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/703532
- https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/699289
- https://www.kaggle.com/competitions/rogii-wellbore-geology-prediction/discussion/697431
- https://www.knime.com/
- https://orangedatamining.com/
- https://h2o.ai/platform/ai-cloud/make/h2o-driverless-ai/
- https://h2o.ai/platform/ai-cloud/operate/h2o-mlops/

## Executive Summary

JuliaFlow has the right product skeleton for a local-first data science workbench: Explorer, Data, Transform, ML Studio, Visualize, Models, Deploy, Monitor, and Settings are the correct top-level surfaces. The recent Explorer/Data/Transform work also moves the application toward the right interaction model: local evidence, Plotly chart specs, a React Flow transform canvas, generated Julia code, lineage, and disabled states for unsupported sources.

The gap is that the current implementation is still mostly a fixed churn-demo experience. It can demonstrate the shape of a workflow, but it cannot yet run an arbitrary data science project end to end because it lacks generic local dataset onboarding, schema mapping, type correction, task templates, statistical EDA, validation/test management, hyperparameter tuning, and reproducible prediction/export behavior.

Readiness estimate:

- Titanic: 55/100. The generic tabular classification path is conceptually close, but local file import, target selection, preprocessing, validation/test split control, and prediction/output export are not complete.
- House Prices: 45/100. Regression and mixed-type feature engineering are not first-class yet; metric and submission support are missing.
- ROGII Wellbore: 25/100. The local-first architecture is valuable, but domain-specific depth, trajectory, typewell, sequence, and grouped validation workflows are absent.

The correct next product direction is not to hard-code these three competitions. Instead, add a generalized project layer with templates, schema roles, editable data types, statistical analysis, task type selection, feature recipes, validation/test strategy, hyperparameter tuning, experiment tracking, and prediction/export artifacts. The wellbore workflow should be a domain template built on that generalized foundation.

Terminology note: Kaggle examples use terms such as train/test/submission. In the product UI, the default data-science language should be train, validation, and test/evaluation. "Submission" should appear only when a project template or output contract requires a competition-style file.

Daily-use note: the application also needs to support multiple local workstation personas, not only competition-style data scientists. A senior data engineer, principal data scientist, MLOps engineer, and non-coding statistical/ML user all need the same local trust boundary, but they need different defaults, evidence, and workflow depth.

## Personas

### Persona A: Beginner Data Scientist, Titanic

Goal: learn an end-to-end ML workflow and submit a valid prediction file.

Needs:

- Import `train.csv`, `test.csv`, and `gender_submission.csv`.
- Identify `Survived` as binary target.
- Mark `PassengerId` as identifier.
- Create train/validation/test roles or a validation split before touching the final test file.
- Handle missing `Age`, `Cabin`, and `Embarked`.
- Encode `Sex`, `Embarked`, `Pclass`.
- Run basic statistical EDA: survival rate by group, chi-square for categorical associations, t-test/ANOVA for numeric group differences where assumptions are acceptable, and correlation checks for numeric features.
- Train simple baselines and compare metrics.
- Tune simple hyperparameters without hiding what changed.
- Export a submission CSV with `PassengerId` and `Survived`.

Primary risks:

- User confusion about target/id columns.
- Accidentally training on submission/test labels.
- Missing-value and categorical encoding defaults hidden from view.

### Persona B: Applied Data Scientist, House Prices

Goal: build a robust regression model on mixed housing features and export `SalePrice` predictions.

Needs:

- Import training data, validation/test data or holdout definitions, and an optional output/submission contract.
- Identify `SalePrice` as regression target.
- Track categorical, ordinal, numeric, date/year, and identifier roles.
- Override incorrect inferred data types, especially numeric-looking categorical codes and ordinal quality fields.
- Handle high-cardinality categorical fields and skewed numeric fields.
- Apply log transform to target or predictions when appropriate.
- Run statistical EDA: OLS baseline, residual review, Pearson/Spearman correlations, ANOVA/group comparisons for categorical drivers, multicollinearity checks, and distribution/normality checks.
- Use RMSE/RMSLE-style scoring.
- Tune model hyperparameters with cross-validation and compare against the OLS/statistical baseline.
- Detect leakage-prone fields and post-sale fields.
- Export a valid submission with `Id` and predicted `SalePrice`.

Primary risks:

- Treating all categorical fields as one-hot without guardrails.
- Wrong metric or target transform.
- No train/validation/test schema drift checks.
- No automated feature role inference.

### Persona C: Domain Data Scientist / Geoscience ML Engineer, ROGII Wellbore

Goal: predict TVT/geology along horizontal wellbores using local/proprietary drilling and typewell data.

Needs:

- Import multiple training, validation/test, evaluation well files, and typewell reference data.
- Understand `MD`, `X`, `Y`, `Z`, `GR`, `TVT_input`, target `TVT`, and well/group identifiers.
- Override incorrectly parsed data types and units, especially depth, coordinate, curve, target, and well id fields.
- Validate monotonic measured depth per well.
- Profile missing depth intervals and curve quality.
- Visualize GR vs MD, TVT vs MD, trajectory XY/XZ, and typewell alignment.
- Run statistical EDA: per-well descriptive stats, Pearson/Spearman relationships by well and interval, OLS or regularized baseline, residuals by well/depth, and group comparisons across well families or intervals.
- Create rolling, lag/lead, derivative, trajectory, spatial, and typewell-alignment features.
- Split by well/group, not random rows.
- Evaluate RMSE per well and across hidden/prediction intervals.
- Tune depth/window/model hyperparameters with grouped validation and keep a final untouched test/evaluation set.
- Export a competition submission and reproducible inference script.

Primary risks:

- Row-random validation creates misleading scores.
- Depth/trajectory leakage.
- Poor sequence continuity and physically implausible predictions.
- No domain visualization for geoscientist review.

## Current Application Fit By Surface

### Explorer

Current strengths:

- Local workspace overview, local runtime status, local artifacts, and activity evidence are relevant.
- Local-first messaging is strong for proprietary datasets.
- Artifact tree is the right pattern for raw data, processed data, models, runs, and submissions.

Current limitations:

- Project structure is generic and still oriented around the demo workflow.
- No competition/project template concept.
- No explicit train/validation/test/output readiness.
- No project-level data contract summary.

Needed:

- Project templates:
  - Binary classification competition.
  - Regression competition.
  - Wellbore/geoscience regression.
- Project readiness cards:
  - train file loaded
  - test file loaded
  - target mapped
  - id column mapped
  - validation strategy selected
  - submission format ready
- Artifact categories:
  - raw
  - processed
  - features
  - experiments
  - models
  - submissions
  - reports

### Data

Current strengths:

- Table/schema/profile/filter/sort/sampling/lineage tabs are the right foundation.
- Local source cards and explicit disabled-source reasons are good.
- Plotly EDA charts are the right direction.

Current limitations:

- No real local file picker or folder import.
- Import Local Data re-profiles the active profile; it does not let a user select arbitrary files.
- No train/validation/test/output-contract bundle concept.
- No schema mapper or target/id/feature role assignment.
- No editable schema/type layer when raw data inference is wrong.
- No generic data quality contract for ML tasks.
- No domain-specific data profiling.

Needed for all three competitions:

- Add Local Dataset Wizard:
  - choose project type
  - select train file
  - optionally select validation file
  - select test file
  - optionally select sample submission or expected prediction output contract
  - preview and validate schemas
  - assign target, id, group, timestamp/depth, and feature roles
- Add source support:
  - CSV first
  - Parquet and Arrow next
  - folder import
  - multi-file dataset collections
  - LAS for wellbore later
- Add schema diagnostics:
  - train/validation/test column mismatch
  - missing target
  - id uniqueness
  - categorical cardinality
  - numeric skew
  - leakage candidates
  - duplicate rows
  - row order and group/depth checks

Schema diagnostics and type management must become a first-class Data workspace section. A data scientist needs to see inferred type, recommended type, semantic role, example values, parse failures, missingness, units, and downstream impact for every column. The UI must allow explicit type overrides before transforms run:

- parse as integer, float, decimal, string, categorical, ordinal, boolean, date, datetime, duration, geometry/coordinate, depth/index, or identifier
- set categorical levels and ordinal order
- set units and unit conversions
- set nullable/non-nullable expectations
- choose parse rules for thousands separators, decimal separators, date formats, missing tokens, and trimming
- mark columns as target, id, group, validation/test-only, leakage risk, ignore, weight, time, depth, coordinate, or feature
- preview how the override changes profile, plots, transforms, and generated Julia code
- persist the schema contract and attach it to lineage

Needed for ROGII:

- Well collection view.
- Per-well depth ranges.
- Monotonic MD validation.
- Curve availability matrix.
- Missing interval chart.
- Typewell/reference file binding.

### Transform

Current strengths:

- React Flow canvas is the correct workflow editor.
- Palette, node settings, before/after preview, generated Julia code, logs, and artifacts are the right interaction model.

Current limitations:

- Palette is generic and demo-oriented.
- Node edits are not yet a full persisted pipeline authoring experience.
- No task-specific recipes.
- No grouped/depth validation nodes.
- No submission-building node.

Needed for all three competitions:

- Reusable transform recipes:
  - missing value imputation
  - categorical encoding
  - ordinal encoding
  - target transform
  - train/validation/test alignment
  - feature selection
  - leakage check
  - split builder
  - submission builder
- Node contracts:
  - typed input/output schemas
  - schema diff preview
  - train/validation/test synchronized transforms
  - generated Julia code per node
  - persisted config

Needed for House Prices:

- ordinal feature mapping
- log target transform
- skewed numeric transform
- rare category handling
- train/validation/test category alignment

Needed for ROGII:

- sort by well and MD
- resample by depth step
- rolling window features
- lag/lead features
- GR smoothing
- derivative/gradient features
- trajectory features
- distance to typewell
- typewell alignment/correlation
- grouped split by well
- prediction-zone masking
- TVT smoothing/postprocessing

### Visualize

Current strengths:

- EDA, dashboard, diagnostics, and compare modes are conceptually useful.
- Plotly is the right local chart layer.

Current limitations:

- Many visuals are static CSS placeholders.
- Visualization does not adapt deeply to task type.
- No submission-oriented charts.
- No linked table/chart interactions.
- No statistical analysis workflow for hypothesis testing, correlations, baseline OLS, or grouped comparisons.

Needed for all competitions:

- Generic EDA:
  - descriptive statistics
  - target distribution
  - missingness heatmap
  - categorical cardinality
  - numeric distributions
  - correlation matrix
  - train/validation/test drift
  - predictions vs actual
  - residual plots
- Statistical workflow:
  - basic OLS and regularized linear baseline
  - coefficient table with confidence intervals
  - residual diagnostics and heteroskedasticity warnings
  - Pearson and Spearman correlation analysis
  - t-test for two-group numeric comparisons
  - chi-square test for categorical association
  - ANOVA for multi-group numeric comparisons
  - non-parametric alternatives or assumption warnings where appropriate
  - effect sizes, p-values, multiple-testing notes, and plain-language interpretation
  - feature/target association ranking separated from causal claims
- Submission diagnostics:
  - prediction distribution vs train target
  - outlier predictions
  - row count and id coverage

Needed for ROGII:

- GR vs MD track.
- TVT/target vs MD track.
- true vs predicted TVT along well.
- trajectory XY/XZ plots.
- typewell GR/TVT alignment view.
- per-well error plots.
- physically implausible jump flags.

### ML Studio

Current strengths:

- MLJ framing, metrics, feature importance, experiment tracker, and generated Julia code are aligned with the product goal.

Current limitations:

- Current experiment UI is classification-centric.
- No user-selected task type.
- No regression metrics.
- No algorithm search/autotune surface.
- No grouped CV.
- No explicit validation/test workflow that protects a final held-out test/evaluation set.
- No hyperparameter tuning workflow with trial comparison, search space, and reproducibility evidence.
- No prediction/output export workflow.

Needed:

- Task type selection:
  - binary classification
  - multiclass classification
  - regression
  - ranking/time-series later
- Baselines:
  - constant/most frequent
  - linear/logistic
  - tree ensemble
  - gradient boosting
- Metrics:
  - accuracy, AUC, F1, log loss for classification
  - RMSE, MAE, RMSLE, R2 for regression
  - group/per-well RMSE for ROGII
- Validation:
  - train/validation/test split
  - random holdout
  - k-fold
  - stratified k-fold
  - grouped k-fold
  - leave-one-group/well-out
  - blocked/depth split
  - final test/evaluation lock to prevent accidental iterative tuning on test data
- Hyperparameter tuning:
  - manual trials
  - grid search
  - random search
  - Bayesian/SMBO-style search when available
  - early stopping where supported
  - nested validation option for serious model selection
  - search-space editor with parameter bounds and categorical choices
  - trial table with metric, runtime, seed, fold summary, and selected artifacts
  - best-run promotion to model registry with clear distinction between validation score and final test score
- Experiment comparison:
  - metric leaderboard
  - feature set
  - transform version
  - seed
  - runtime
  - submission artifact link

### Models

Current strengths:

- Local model registry and artifact evidence are useful.

Current limitations:

- Model cards are generic.
- Metrics are partially hard-coded around churn.
- No task-specific model cards.
- No submission/version linkage.

Needed:

- Model card fields:
  - task type
  - target
  - id column
  - train rows
  - validation strategy
  - metric
  - feature pipeline version
  - leakage checks
  - dataset hash
  - submission files generated
- ROGII model card additions:
  - wells used for training
  - held-out wells
  - depth ranges
  - curves used
  - typewell strategy
  - smoothing/postprocessing
  - known failure wells

### Deploy

Current strengths:

- Local endpoint and batch scorer concepts are relevant.

Current limitations:

- Data scientists usually need batch prediction and output/submission export before HTTP serving.
- No CLI/script export for reproducible submission generation.

Needed:

- Batch inference target:
  - select model
  - select test dataset
  - run predictions
  - validate submission schema
  - export CSV
- Reproducible local runner:
  - `run_submission.jl`
  - locked manifest
  - input/output paths
  - checksum evidence

### Monitor

Current strengths:

- Runtime and artifact monitoring are useful after the model exists.

Current limitations:

- Competition workflows need run/submission monitoring more than endpoint monitoring.

Needed:

- Submission history.
- Run reproducibility status.
- Data drift between train/validation/test.
- Prediction distribution drift across submissions.
- Metric history and leaderboard notes.

### Settings

Current strengths:

- Local-first controls fit all three workflows.

Needed:

- Default project storage location per competition.
- Kaggle dataset path setting or import root.
- Local package/environment lock.
- Optional Kaggle CLI integration as a local-only convenience.
- Disk usage warnings for multi-file/domain projects.

## Generalized Capability Matrix

| Capability | Titanic | House Prices | ROGII Wellbore | Current App | Required Priority |
| --- | --- | --- | --- | --- | --- |
| Local train/validation/test import | required | required | required, multi-file | partial UI only | P0 |
| Output/submission contract import | required for competition output | required for competition output | required for competition output | missing | P0 |
| Target/id mapping | required | required | required | missing | P0 |
| Schema validation and type override | simple | advanced | domain/group/depth/unit-aware | partial profile only | P0 |
| Statistical EDA | basic group tests | OLS, correlations, ANOVA, residuals | per-well stats, OLS, correlations by interval | mostly missing | P0 |
| Missing value handling | required | required | required by curve/depth | partial/demo | P0 |
| Categorical encoding | required | required | maybe geology labels | partial/demo | P0 |
| Numeric transforms | useful | required | required | partial/demo | P1 |
| Train/validation/test transform alignment | required | required | required | missing | P0 |
| Validation/test strategy | stratified validation, final test | k-fold/regression validation, final test | grouped/depth validation, final test | missing/declarative only | P0 |
| Hyperparameter tuning | useful/simple | required | required with grouped validation | missing | P0 |
| Regression metrics | not needed | required | required | missing in UI | P0 |
| Classification metrics | required | not primary | maybe auxiliary | partial | P0 |
| Domain charts | not needed | not needed | required | missing | P1 |
| Prediction/output export | required | required | required | missing | P0 |
| Reproducible runner | useful | useful | required | partial code preview | P1 |
| Model registry | useful | useful | useful | partial | P1 |
| Local endpoint | optional | optional | optional | partial | P2 |

## Cross-Competition Workflow Needed

1. Create project from template.
2. Import local project files.
3. Confirm dataset roles:
   - train
   - validation
   - test
   - optional output/submission contract
   - target
   - id
   - group/depth/time where applicable
4. Review schema diagnostics and correct inferred data types.
5. Run profiling, quality checks, and statistical EDA.
6. Build transform pipeline.
7. Select task type and metric.
8. Select validation strategy and lock final test/evaluation data.
9. Train statistical and ML baselines.
10. Tune hyperparameters on validation only.
11. Compare experiments and promote the best validation run.
12. Evaluate once on final test/evaluation data.
13. Generate predictions.
14. Validate output/submission format.
15. Export predictions or submission CSV.
16. Save reproducibility bundle.

## Recommended Backlog

### P0 - Make Any Kaggle-Style Tabular Project Possible

1. Local Dataset Wizard
   - file picker for train/validation/test data
   - optional output/submission contract picker
   - CSV profile
   - local path/handle evidence
   - no cloud upload semantics

2. Project Template System
   - binary classification
   - regression
   - domain/sequential regression placeholder

3. Schema Role Mapper
   - target
   - id
   - feature
   - ignore
   - group
   - time/depth
   - validation/test-only
   - leakage risk

4. Schema Diagnostics And Type Overrides
   - inferred type vs selected type
   - semantic role and units
   - parse error preview
   - categorical/ordinal level management
   - date/time/depth parsing rules
   - generated Julia schema contract
   - lineage evidence for type changes

5. Output Contract
   - expected columns
   - row count
   - id coverage
   - prediction/export CSV generation

6. Task And Metric Selection
   - classification metrics
   - regression metrics
   - metric shown throughout ML Studio, Visualize, Models, and submission validation

7. Validation And Test Workflow
   - train/validation/test assignment
   - cross-validation strategy
   - grouped and blocked validation options
   - final test lock
   - clear labels for validation score vs test score

8. Train/Validation/Test Transform Alignment
   - same preprocessing fitted on train and applied to test
   - generated Julia code
   - lineage artifact

9. Statistical EDA Workflow
   - descriptive statistics
   - OLS baseline
   - t-test
   - chi-square test
   - ANOVA
   - Pearson correlation
   - Spearman correlation
   - residual diagnostics
   - assumption warnings and non-causal interpretation notes

10. Hyperparameter Tuning Workflow
   - search-space editor
   - manual/grid/random search
   - validation-only tuning
   - trial table
   - best-run promotion
   - reproducible seeds and artifacts

### P1 - Make It Productive For Serious Data Scientists

1. Transform recipes:
   - missing values
   - one-hot/ordinal encoding
   - rare category handling
   - numeric scaling
   - skew/log transforms
   - leakage check

2. Experiment tracker:
   - baseline runs
   - model family
   - metric history
   - feature pipeline version
   - seed and runtime

3. Plotly EDA upgrade:
   - real Plotly charts in Visualize
   - train/validation/test drift
   - target distribution
   - residuals/prediction diagnostics
   - statistical test result plots and tables

4. Reproducibility bundle:
   - generated Julia training script
   - generated Julia inference/submission script
   - Project/Manifest evidence
   - dataset hashes

### P1/P2 - Make ROGII/Wellbore Practical

1. Wellbore Project Template
   - train wells
   - test wells
   - typewell/reference files
   - TVT target
   - grouped validation by well

2. Well Data Profile
   - wells count
   - rows per well
   - MD range
   - coordinate range
   - missing curve intervals
   - non-monotonic MD flags

3. Wellbore Transform Pack
   - sort by well and MD
   - resample by depth
   - rolling GR statistics
   - lag/lead features
   - trajectory features
   - typewell alignment features
   - TVT smoothing

4. Domain Visualizations
   - GR vs MD
   - TVT vs MD
   - true vs predicted TVT by well
   - XY/XZ trajectory
   - typewell alignment

5. Domain Evaluation
   - RMSE overall
   - RMSE per well
   - prediction-zone RMSE
   - continuity/jump diagnostics

## Acceptance Criteria

### Titanic Done Means

- User selects training, validation/test, and optional output/submission CSVs.
- App maps `Survived` target and `PassengerId` id.
- App supports a validation split and keeps the final test/output data separate from tuning.
- App allows type and role correction for imported columns.
- App runs basic statistical EDA: descriptive tables, categorical association checks, and numeric group comparisons.
- App builds a preprocessing pipeline.
- App trains at least one local model.
- App shows validation metrics and records any hyperparameter tuning trials.
- App exports a valid submission CSV.
- Generated Julia script can reproduce the submission locally.

### House Prices Done Means

- User selects training, validation/test, and optional output/submission CSVs.
- App maps `SalePrice` target and `Id` id.
- App supports train/validation/test strategy and cross-validation.
- App allows type overrides for categorical-looking numeric fields and ordinal fields.
- App runs OLS/statistical baseline, Pearson/Spearman correlations, ANOVA/group comparisons, and residual diagnostics.
- App supports regression metrics.
- App supports target/log transform or prediction postprocessing.
- App supports hyperparameter tuning and separates validation selection from final test evaluation.
- App validates train/validation/test schema alignment.
- App exports a valid `Id`, `SalePrice` submission.
- App displays residual/prediction diagnostics.

### ROGII Done Means

- User imports multi-file well training, validation/test, evaluation, and typewell data.
- App maps `MD`, `X`, `Y`, `Z`, `GR`, `TVT_input`, target `TVT`, and well id/group roles.
- App allows type/unit overrides for depth, coordinate, curve, target, and well identifier fields.
- App validates per-well depth order and missing intervals.
- App runs per-well statistical EDA, correlation analysis, OLS/regularized baseline, and residual diagnostics by well/depth.
- App builds depth/trajectory/typewell features.
- App uses grouped or depth-aware validation and keeps final test/evaluation data locked.
- App supports hyperparameter tuning over window, feature, and model parameters using grouped validation.
- App shows well log/trajectory plots.
- App exports a valid prediction submission.
- Generated Julia pipeline reproduces raw-to-submission output.

## Daily Local Workstation Personas

The competition examples expose project mechanics, but daily adoption depends on whether JuliaFlow can replace the ordinary workstation tools people use every week. The target is not only "can a demo run?" It is "can a local user trust this as the first tool opened for data and ML work?"

External low-code tool signals:

- KNIME-style signal: users expect a broad visual workflow surface with file/database connectors, reusable nodes, branchable pipelines, data preparation, model training, and operational handoff.
- Orange-style signal: users expect widget-based no-code exploration, fast visual feedback, and understandable analysis flow for teaching, exploration, and non-programmer usage.
- H2O-style signal: users expect automated feature engineering/model search, model interpretation, scoring pipelines, registry, deployment, and model monitoring/drift evidence.

JuliaFlow should absorb these expectations through local-first Julia workflows rather than copying the exact product shape.

### Persona 1: Senior Data Engineer

Daily goal: ingest local and workstation-adjacent data, validate it, transform it into durable analytical and feature-ready artifacts, and hand it to analysts, scientists, and model workflows with lineage.

Typical local hardware:

- CPU-only workstation for routine ingestion, profiling, joins, and batch transformation.
- CPU/GPU workstation when feature generation or downstream model preparation needs accelerated compute.

Current JuliaFlow fit: 40/100.

Strengths:

- Data and Transform have the right top-level surfaces.
- Explorer already exposes local artifact evidence.
- Transform has a React Flow canvas, grouped palette, validation, history, generated Julia code, logs, and before/after previews.
- The local data estate, Arrow/Parquet direction, DuckDB evidence, and no-cloud boundary match this persona well.

Missing for daily use:

- Real local source onboarding for files, folders, SQLite, DuckDB, PostgreSQL, MySQL, and USB/import paths, with unsupported sources disabled until backed by a gateway handler.
- Schema registry and schema contract management across raw, processed, feature, validation, and test datasets.
- Editable data types, semantic roles, units, parse rules, and lineage for every correction.
- Data quality rules: null thresholds, uniqueness, referential integrity, range checks, duplicate checks, data diffs, and failed-row quarantine.
- Join diagnostics: key coverage, cardinality, duplicate keys, unmatched rows, and leakage warnings.
- Incremental refresh and local scheduling for repeatable pipelines.
- Materialization controls for CSV, Arrow IPC, Parquet, DuckDB tables/views, and feature-ready artifacts.
- Pipeline versioning, rollback, run comparison, and reproducible generated Julia scripts.
- Local resource planning for CPU threads, memory limits, disk footprint, and optional GPU use.

Daily-use acceptance criteria:

- A senior data engineer can create a local project, register multiple data sources, correct schema/type issues, build a reusable transform pipeline, validate quality checks, run it on a schedule or manual refresh, and produce lineage-backed artifacts without writing code.
- Every data source or connector shown in the UI is either functional or visibly disabled with a reason.

### Persona 2: Principal Data Scientist

Daily goal: move from raw local data to defensible model evidence: EDA, statistical analysis, feature engineering, validation/test design, modeling, tuning, explainability, and reproducible outputs.

Typical local hardware:

- CPU-only workstation for EDA, statistics, baselines, small models, and reproducibility checks.
- CPU/GPU workstation for larger tuning runs, gradient-boosted/deep models, and parallel experiments.

Current JuliaFlow fit: 45/100.

Strengths:

- The application has the right route set: Data, Transform, Visualize, ML Studio, Models, Monitor, and Deploy.
- Plotly-compatible chart specs are the right direction for interactive EDA.
- Generated Julia code and local artifacts fit reproducible science.
- The app already has model/evidence surfaces that can become proper model cards and experiment records.

Missing for daily use:

- Project setup that asks for problem type, target, id/group/time/depth roles, validation/test roles, metric, and output contract.
- Statistical EDA workbench: descriptive stats, OLS, t-test, chi-square, ANOVA, Pearson, Spearman, residual diagnostics, assumption warnings, and leakage checks.
- Editable schema diagnostics for incorrect inferred data types, categorical-looking numeric fields, ordinal fields, dates, units, and target/id leakage.
- Validation and test manager with random, stratified, grouped, blocked/time-based, depth-aware, and final test-lock strategies.
- Hyperparameter tuning workflow: grid/random/manual search, validation-only selection, trial table, best-run promotion, seeds, and reproducible artifacts.
- Baseline modeling and model family comparison for classification, regression, ranking, clustering, and domain templates.
- Model interpretability: feature importance, partial dependence/ICE-style views where practical, residual plots, local explanations, limitations, and model cards.
- Prediction/output export for holdout, test, batch scoring, and competition-style output contracts.

Daily-use acceptance criteria:

- A principal data scientist can import a new tabular or domain dataset, correct schema roles, run statistics, define validation/test strategy, train baselines, tune models, inspect diagnostics, export predictions, and reproduce the result from generated Julia code.
- Validation and test terminology is consistent across Data, Transform, ML Studio, Models, Monitor, and Deploy.

### Persona 3: MLOps Engineer Focused On Training, Drift, And Evaluation

Daily goal: turn local training into controlled, repeatable model operations: runs, evaluation gates, registry, deployment, scoring, drift monitoring, retraining evidence, and rollback.

Typical local hardware:

- CPU-only workstation for registry, evaluation, batch scoring, monitoring, and governance.
- CPU/GPU workstation for scheduled training, larger tuning jobs, and accelerated evaluation workloads.

Current JuliaFlow fit: 35/100.

Strengths:

- Models, Deploy, Monitor, Settings, and local hardware/runtime evidence are already present as product surfaces.
- Local package/runtime, reproducibility bundle, backup/restore, and offline Hub work align with workstation MLOps.
- Existing execution records and explainability evidence provide a foundation for run provenance.

Missing for daily use:

- Training pipeline orchestration with explicit stages: data snapshot, feature pipeline, train, validate, tune, evaluate, register, package, score, monitor.
- Model registry lifecycle: candidate, validated, approved, deployed, deprecated, archived, with version comparison and artifact checksums.
- Evaluation gates: metric thresholds, fairness/segment checks where applicable, data quality checks, drift checks, explainability presence, and reproducibility bundle requirements.
- Drift monitoring: reference dataset selection, current scoring dataset, schema drift, data drift, prediction drift, target drift when labels arrive, and segment/well/group drift.
- Retraining triggers and local jobs with manual approval, scheduled approval, or disabled state.
- Batch scoring and local endpoint scoring with comparable output contracts.
- Local alerts and review queues for failing quality, evaluation, drift, or endpoint health.
- CPU/GPU run resource logs: selected backend, device, memory, duration, utilization, and fallback reason.
- Rollback and model lineage from deployed model back to training data, transform pipeline, tuning run, and validation/test evidence.

Daily-use acceptance criteria:

- An MLOps engineer can promote a locally trained model only after evaluation gates pass, deploy it locally for batch or endpoint scoring, monitor drift against a reference dataset, and roll back to a prior version with full local artifact lineage.
- Monitor should show model health and drift/evaluation evidence, not only workflow execution evidence.

### Persona 4: Non-Coding User With Statistics And ML Knowledge

Daily goal: use statistics and ML concepts without coding: import data, choose roles, run EDA, pick a modeling task, validate results, interpret outputs, and produce a report or prediction file.

Typical local hardware:

- CPU-only workstation for most learning, EDA, and small project work.
- CPU/GPU workstation when the project template recommends heavier tuning or model families.

Current JuliaFlow fit: 30/100.

Strengths:

- The route shell is understandable.
- A low-code canvas, palette, and settings drawer can work well for non-coders.
- Local-first messaging is clear and reassuring.

Missing for daily use:

- Guided project wizard with plain-language choices for data source, target, id, validation/test data, problem type, and success metric.
- Recommended EDA checklist with explanations: missingness, distributions, outliers, group comparisons, correlations, statistical tests, and assumptions.
- Safe modeling defaults: baseline first, validation before tuning, final test lock, and warnings when choices are statistically risky.
- Natural-language explanations of metrics, validation/test separation, leakage, statistical assumptions, and model limitations.
- Template workflows for classification, regression, clustering, forecasting/time or depth-aware data, and batch prediction.
- Inline help and disabled-state reasons for every control that is not ready.
- One-click report export that includes data profile, EDA, selected transforms, validation results, tuning summary, model card, limitations, and reproducibility information.
- Visual no-code editing for schema/type correction and transform configuration.

Daily-use acceptance criteria:

- A non-coding user can finish a small classification or regression project without writing Julia, while still understanding what data was used, how validation worked, which assumptions were made, why a model was selected, and how to rerun the workflow locally.

## Cross-Persona Daily Usage Requirements

| Capability | Senior Data Engineer | Principal Data Scientist | MLOps Engineer | Non-Coding Stats/ML User |
| --- | --- | --- | --- | --- |
| Local project and dataset wizard | Required | Required | Required | Required |
| Source connectors and import state | Required | Required | Useful | Required |
| Schema/type diagnostics and overrides | Required | Required | Required for gates | Required, guided |
| Data quality rules and lineage | Required | Required | Required | Guided summaries |
| Statistical EDA workbench | Useful | Required | Useful for evaluation | Required, guided |
| Transform pipeline canvas | Required | Required | Required | Required, simplified |
| Validation/test manager | Required for data handoff | Required | Required for gates | Required, guarded |
| Hyperparameter tuning | Useful | Required | Required for training ops | Guided presets |
| Experiment/run tracker | Useful | Required | Required | Simplified |
| Model registry lifecycle | Handoff | Required | Required | Simplified |
| Drift and evaluation monitoring | Useful | Required | Required | Summary only |
| Local batch/endpoint scoring | Handoff | Required | Required | Guided export |
| CPU/GPU resource profiles | Required for scale | Required for tuning | Required | Presets |
| Report/reproducibility bundle | Required | Required | Required | Required |

## Daily-Use Backlog Addendum

P0 additions before claiming daily data/ML workstation readiness:

1. Local project/dataset wizard covering train, validation, test/evaluation, optional output contract, local file/folder evidence, and release-mode empty states.
2. Schema/type manager with role mapping, type overrides, units, parse diagnostics, categorical/ordinal handling, and generated Julia schema contracts.
3. Statistical EDA workbench covering descriptive statistics, OLS, t-test, chi-square, ANOVA, Pearson, Spearman, residual diagnostics, assumptions, and non-causal language.
4. Validation/test manager covering split strategy, grouped/blocked/time/depth strategies, final test lock, metric selection, and schema alignment.
5. Hyperparameter tuning and experiment-trial tracker with search-space editor, validation-only selection, reproducible seeds, artifacts, and best-run promotion.
6. Prediction/output export for holdout, test/evaluation, batch scoring, and output-contract CSVs.
7. Guided no-code mode that makes every high-risk decision visible, explained, and reversible.

P1 additions for serious daily adoption:

1. Data-engineering connector and quality-rule pack for files, watched folders, DuckDB, SQLite, PostgreSQL, MySQL, data diffs, join diagnostics, and incremental refresh.
2. MLOps evaluation and drift dashboard with reference datasets, current datasets, schema/data/prediction/target drift, evaluation gates, and retraining review state.
3. Model registry lifecycle with candidate/validated/approved/deployed/deprecated/archive states, artifact checksums, and rollback.
4. Local job scheduling for data refresh, transform runs, training, scoring, monitoring, and report generation.
5. CPU/GPU run resource profiles with backend, device, memory, duration, utilization, and fallback evidence.
6. AutoML/recommendation layer that suggests baselines, transforms, model families, tuning spaces, and statistical checks without hiding the generated Julia code.

P2 additions for domain and team depth:

1. Domain template framework for wellbore, time-series, tabular regression/classification, and other scientific workflows.
2. Local feature-store/cache layer over Parquet/DuckDB artifacts with lineage and schema contracts.
3. Advanced deployment packaging for local batch jobs, local REST endpoints, and offline reproducibility bundles.
4. Optional external connectors only after local states, disabled states, and trust boundaries are clear.

## Product Positioning

JuliaFlow should not be a Kaggle-only tool. The better positioning is:

> A local-first, low-code Julia workbench for reproducible tabular, scientific, and domain ML workflows.

Kaggle-style competitions are a useful forcing function because they require the same primitives real projects require:

- local data onboarding
- schema contracts
- editable data types and semantic roles
- statistical EDA
- feature engineering
- validation discipline
- hyperparameter tuning
- repeatable training
- prediction export
- artifact lineage
- human-readable diagnostics

## Implementation Recommendation

Build this in three vertical slices:

1. Generic Tabular Data Science MVP
   - Local file wizard, schema mapper, editable types, validation/test setup, classification/regression task setup, statistical EDA, baseline training, simple tuning, and prediction/output export.

2. Advanced Tabular Regression
   - House Prices template, regression metrics, target transforms, validation/test drift, OLS/statistical workflow, hyperparameter tuning, and residual diagnostics.

3. Wellbore Domain Template
   - Multi-file well import, depth-aware profiling, type/unit overrides, grouped validation, wellbore statistical EDA, tuning over depth/window parameters, well log visualizations, and wellbore transform pack.

This sequencing avoids overfitting the product to ROGII while still making the wellbore project possible once the generalized substrate is in place.
