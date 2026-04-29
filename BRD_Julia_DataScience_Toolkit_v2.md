# Business Requirements Document

## JuliaDS Studio — Low-Code Drag-and-Drop Data Science Toolkit
### Full CRISP-DM Coverage · Julia-Powered Compute Backend · GPU-Accelerated Workflows

---

| Field | Value |
|---|---|
| **Document Title** | JuliaDS Studio — Business Requirements Document |
| **Version** | 2.0.0 |
| **Status** | Draft — In Review |
| **Date** | 2026-03-06 |
| **Replaces** | BRD v1.0.0 (Low-Code EDA Toolkit — Concept Proposal) |
| **Classification** | Internal — Confidential |
| **Primary Author** | Product Management |
| **Reviewers** | Engineering Lead · Data Science Lead · Architecture · UX |

---

## Table of Contents

1. Executive Summary
2. Scope Revision & Change Log
3. Problem Statement
4. Product Vision & Strategic Positioning
5. CRISP-DM Framework Alignment
6. Target Users & Personas
7. Feature Requirements by CRISP-DM Phase
8. GPU Compute Requirements
9. Platform-Wide Capabilities
10. Non-Functional Requirements
11. Technical Architecture
12. Julia Ecosystem Dependency Map
13. Key Differentiators
14. Success Metrics & KPIs
15. Assumptions & Constraints
16. Out of Scope (v1.0)
17. Risks & Mitigations
18. High-Level Roadmap
19. Approvals & Sign-Off

---

## 1. Executive Summary

**JuliaDS Studio** is a low-code, drag-and-drop Data Science Toolkit that delivers a complete, end-to-end data science workflow environment through a visual web-based canvas — powered by a **Julia-language compute backend** and optionally accelerated by **GPU kernels and Julia GPU libraries**.

The product covers the full **CRISP-DM (Cross-Industry Standard Process for Data Mining)** lifecycle: from business problem framing and raw data ingestion, through data preparation, exploratory analysis, statistical insight, machine learning model construction, clustering, training, evaluation, versioning, and production deployment — all orchestrated visually without requiring deep coding proficiency.

JuliaDS Studio is explicitly designed for **data practitioners at all seniority levels**, from Junior Data Scientists running their first preprocessing pipeline to Principal Data Scientists architecting multi-stage GPU-accelerated training workflows. Each persona interacts with the same unified canvas but at a different depth of abstraction.

The product bridges the gap between point-and-click BI tools that sacrifice analytical depth, and code-first notebook environments that sacrifice speed and reproducibility. Julia's unique combination of dynamic language ergonomics, near-C numerical performance, native GPU kernel support (via CUDA.jl, AMDGPU.jl, and Metal.jl), and a first-class scientific computing ecosystem makes it the optimal backend for this class of product.

---

## 2. Scope Revision & Change Log

This document supersedes **BRD v1.0.0** in full. The following table summarises all scope changes from the prior version.

| Change Type | v1.0.0 Scope | v2.0.0 Scope |
|---|---|---|
| **Product Name** | Unnamed EDA Toolkit | JuliaDS Studio |
| **Coverage** | EDA only | Full CRISP-DM lifecycle |
| **ML / Modeling** | Out of scope (deferred v2.0) | **In scope — core requirement** |
| **Model Versioning** | Not mentioned | **In scope** |
| **Data Versioning** | Not mentioned | **In scope** |
| **Model Deployment** | Not mentioned | **In scope** |
| **Clustering** | Not mentioned | **In scope** |
| **GPU Acceleration** | Not mentioned | **In scope — first-class feature** |
| **GPU Orchestration** | Not mentioned | **In scope** |
| **Persona Depth** | Single DS persona | **Four-tier DS persona model** |
| **CRISP-DM Alignment** | Not structured | **Explicitly mapped to all 6 phases** |
| **Target User** | Broad (analysts, scientists) | **Data practitioners (all DS seniority)** |

---

## 3. Problem Statement

### 3.1 The Data Science Workflow Fragmentation Problem

Modern data science practice requires practitioners to navigate a deeply fragmented toolchain. A typical project may involve: a Jupyter notebook for EDA, a separate pipeline tool (Airflow, Prefect) for orchestration, DVC or MLflow for versioning, a training framework (PyTorch, scikit-learn) for modeling, and a separate serving layer (FastAPI, BentoML) for deployment. Each tool speaks a different language, has its own state model, and requires its own expertise.

This fragmentation creates four compounding problems:

**Context-switching cost:** Practitioners lose significant time moving between environments, reformatting data, and re-establishing execution context. Studies of data science teams indicate that 60–80% of project time is spent on data preparation and pipeline management rather than on insight generation.

**Reproducibility debt:** When workflow steps are distributed across tools, reproducing an exact model or result requires reconstructing not just the code but the environment, data state, and configuration of every tool in the chain — a notoriously error-prone process.

**Skill barrier:** The full toolchain requires mastery of multiple languages, frameworks, and DevOps concepts. This creates a de-facto ceiling for practitioners below the Senior Data Scientist level, forcing expensive senior resources to handle tasks that could be delegated.

**Performance ceiling:** Python-based tooling — the dominant language for DS toolchains — hits hard performance walls with datasets above ~50M rows or with computationally intensive training loops, forcing early adoption of distributed frameworks that introduce their own complexity overhead.

### 3.2 The Julia Performance Opportunity

Julia was designed from first principles to eliminate the "two-language problem" — the need to prototype in Python/R and rewrite hot paths in C/C++/Fortran for production performance. It offers:

- **Near-C execution speed** for numerical and array workloads via LLVM JIT compilation.
- **Native GPU kernel authorship** through CUDA.jl (NVIDIA), AMDGPU.jl (AMD), and Metal.jl (Apple Silicon) — allowing the same Julia source code to execute on CPU or GPU with minimal changes.
- **First-class parallelism**: multi-threading (via `Threads.@spawn`), distributed computing (via `Distributed.jl`), and GPU parallelism as native language features, not bolted-on libraries.
- **A rich ML and scientific computing ecosystem**: MLJ.jl (unified ML interface), Flux.jl (deep learning), DataFrames.jl, Statistics.jl, Clustering.jl, and hundreds of domain-specific packages.
- **Interoperability** with Python (PyCall.jl) and R (RCall.jl), protecting existing investments.

### 3.3 The Market Gap

No currently available tool combines: visual drag-and-drop workflow authoring + full CRISP-DM lifecycle coverage + Julia-backed computation + GPU acceleration + integrated data and model versioning. Products like KNIME, Orange, and RapidMiner offer visual workflows but are Python/Java backed and do not reach GPU-accelerated training. MLflow and DVC solve versioning but are developer-facing CLI tools. Tableau and Power BI solve visualization but not modeling or deployment.

JuliaDS Studio addresses this gap directly.

---

## 4. Product Vision & Strategic Positioning

### 4.1 Product Vision Statement

> **"A single, unified visual canvas where data practitioners at any seniority level can design, execute, iterate, and deploy end-to-end data science workflows — from raw data to production model — powered by Julia's world-class numerical performance and GPU acceleration, without the cognitive overhead of a fragmented toolchain."**

### 4.2 Core Design Principles

**Visual-first, code-possible:** Every workflow is constructed visually. Every node on the canvas has a corresponding, exportable Julia code representation. No coding is required; deep coding is always accessible.

**CRISP-DM as the navigation spine:** The UI is organised around the six CRISP-DM phases. Users always know which phase they are in. Transitions between phases are explicit workflow checkpoints.

**Performance by default:** Julia's compilation model and GPU dispatch are managed invisibly by the platform. Users do not configure thread counts or CUDA contexts — the runtime selects the optimal execution path automatically based on dataset size, hardware availability, and node type.

**Version everything:** Data, features, models, and deployments are versioned automatically at every checkpoint. Rollback and comparison are first-class UI operations, not CLI afterthoughts.

**Persona-aware UX:** The canvas adapts its complexity and terminology to the user's declared seniority level. A Junior Data Scientist sees guided templates and plain-language node descriptions; a Principal Data Scientist sees raw Julia kernel hooks, parallelism controls, and deployment infrastructure options.

---

## 5. CRISP-DM Framework Alignment

The six phases of CRISP-DM map directly to product modules within JuliaDS Studio. Each phase is a first-class citizen of the canvas navigation.

| CRISP-DM Phase | JuliaDS Studio Module | Key Deliverable |
|---|---|---|
| **1. Business Understanding** | Project Setup & Objective Canvas | Defined problem statement, success criteria, KPI targets |
| **2. Data Understanding** | Data Ingestion & EDA Module | Dataset profiles, quality reports, insight summaries |
| **3. Data Preparation** | Data Preparation & Feature Engineering Canvas | Clean, versioned, feature-engineered datasets |
| **4. Modeling** | Model Builder & Algorithm Canvas | Trained models (CPU + GPU), clustering outputs |
| **5. Evaluation** | Model Evaluation & Comparison Dashboard | Performance metrics, error analysis, model approval |
| **6. Deployment** | Model Deployment & Serving Module | Deployed REST/gRPC endpoint, monitoring dashboard |

### 5.1 Phase Transitions & Checkpoint Gates

At each phase boundary, the platform enforces a **checkpoint gate** — a summary card that captures: what was produced in this phase, what data/model version is being carried forward, and a sign-off action. Gates are optional in individual mode and mandatory in team collaboration mode with approval workflows.

---

## 6. Target Users & Personas

### 6.1 Data Scientist Persona Tiers

The primary user group is the Data Scientist family, segmented into four seniority tiers. Each tier has distinct workflow needs, abstraction preferences, and feature expectations.

---

#### Persona DS-1: Junior Data Scientist (1–3 Years Experience)

**Background:** Recently graduated or transitioned into data science. Comfortable with basic Python/pandas and has taken structured ML courses. Understands supervised learning concepts but has limited production exposure. May be unfamiliar with Julia specifically.

**Goals:**
- Complete CRISP-DM projects end-to-end with guidance.
- Learn best practices through the scaffolded workflow structure.
- Produce reproducible, shareable work without needing to author production-grade code.
- Build confidence iterating on models without fear of breaking a pipeline.

**Frustrations:**
- Overwhelmed by toolchain setup (conda environments, Docker, MLflow config).
- Spends more time debugging infrastructure than doing data science.
- Difficulty knowing which algorithm to choose or when a preprocessing step is appropriate.
- Limited visibility into whether their model is actually performing well vs. a baseline.

**Platform Expectations:**
- Guided templates for common project types (classification, regression, clustering, time series).
- Plain-language node descriptions with tooltips explaining *why* each step exists.
- Algorithm recommendation assistant that suggests appropriate models given dataset characteristics.
- Built-in baseline comparisons so relative model performance is always visible.
- One-click environment setup; no local Julia installation required for cloud mode.
- Export to Pluto.jl notebook to begin learning Julia organically.

**Canvas Interaction Style:** Template-first. Starts from a CRISP-DM project template, fills in nodes with drag-and-drop, rarely customises node parameters deeply. Uses the "explain this node" panel frequently.

---

#### Persona DS-2: Data Scientist (4–7 Years Experience)

**Background:** Mid-level practitioner with solid production DS experience. Fluent in Python and/or R, familiar with scikit-learn, XGBoost, possibly PyTorch. Has shipped models to production. Understands the pain of fragmented toolchains firsthand. May have basic Julia awareness but not deep expertise.

**Goals:**
- Dramatically reduce the time from data ingestion to a production-ready model.
- Maintain reproducibility across experiments without manual tracking overhead.
- Run multiple modeling experiments in parallel and compare results systematically.
- Begin leveraging GPU acceleration for training without rewriting workflows.

**Frustrations:**
- MLflow/DVC setup is laborious and team adoption is inconsistent.
- Re-running experiments after data changes requires manual effort to trace data lineage.
- Hyperparameter search is time-consuming and hard to parallelise without cluster access.
- Model deployment is a handoff to engineering, introducing delays and miscommunication.

**Platform Expectations:**
- Full experiment tracking with automatic hyperparameter logging and metric capture.
- Side-by-side model comparison view across multiple experiment runs.
- GPU training toggle at the node level — no extra configuration needed.
- Automated hyperparameter search nodes (grid, random, Bayesian) with GPU parallel execution.
- One-click model deployment to a REST endpoint from the evaluation screen.
- Data versioning with automatic lineage graph showing which model was trained on which data snapshot.
- Julia code export so power users can extend nodes programmatically.

**Canvas Interaction Style:** Workflow-builder. Composes full CRISP-DM pipelines from scratch, customises node parameters, runs multiple experiment variants simultaneously, uses the comparison dashboard actively. Occasionally inspects underlying Julia code but does not rewrite nodes.

---

#### Persona DS-3: Senior Data Scientist (8–12 Years Experience)

**Background:** Highly experienced practitioner who has owned the full DS lifecycle multiple times. Deep algorithmic knowledge, production ML systems experience, and familiarity with distributed computing. Likely has opinions about Julia and may have used it in scientific computing contexts. Has been a technical mentor and reviews junior work.

**Goals:**
- Architect repeatable, high-performance data science pipelines that the whole team can execute.
- Exploit GPU compute for large-scale training (>1M row feature matrices, deep learning components).
- Implement custom algorithms and loss functions that go beyond pre-built node libraries.
- Enforce data and model governance standards across team workflows.
- Evaluate and adopt the platform as a team-wide standard, requiring deep trust in its outputs.

**Frustrations:**
- Low-code tools historically cap out before reaching the complexity of real-world problems.
- Black-box platforms make it hard to trust or audit what the tool is actually computing.
- Cannot customise or inject bespoke algorithms without abandoning the visual workflow entirely.
- GPU resources are hard to allocate and monitor across a team's concurrent workloads.

**Platform Expectations:**
- Custom Julia node authoring: write arbitrary Julia code that integrates as a first-class canvas node.
- Full access to CUDA.jl / AMDGPU.jl primitives within custom nodes.
- GPU resource dashboard: visibility into allocation, utilisation, queue depth across team workloads.
- Pipeline templating: publish team-standard workflow templates for DS-1 and DS-2 to consume.
- Model governance: mandatory evaluation gates, approval workflows before deployment promotion.
- Advanced model versioning: semantic versioning, diff view between model checkpoints, rollback.
- Data lineage graph: full provenance from raw source to deployed model feature set.
- Integration with enterprise auth (LDAP, SSO) and audit logging for compliance.

**Canvas Interaction Style:** Architect and author. Builds framework pipelines for the team, writes custom nodes in Julia, manages GPU resource allocation, reviews and approves model promotion requests, and sets governance policies.

---

#### Persona DS-4: Principal Data Scientist / Lead DS (12+ Years Experience)

**Background:** Distinguished practitioner at the intersection of data science, machine learning engineering, and platform strategy. Influences technical direction, evaluates build vs. buy decisions, and sets standards for the broader organisation. Deep expertise in distributed systems, ML infrastructure, and Julia or equivalent high-performance environments. Likely evaluating JuliaDS Studio as a strategic platform investment.

**Goals:**
- Determine whether JuliaDS Studio can serve as the organisation's unified DS platform, replacing or consolidating multiple existing tools.
- Validate that the platform delivers on GPU performance claims at enterprise scale.
- Ensure the platform can integrate with existing MLOps infrastructure (Kubernetes, model registries, feature stores).
- Design the organisation's CRISP-DM process standard and enforce it through the platform.
- Prototype next-generation workflows (multi-GPU training, distributed hyperparameter search, federated data preparation) before productionising them.

**Frustrations:**
- Most "low-code" platforms are not enterprise-grade and fail at the evaluation stage when stress-tested at scale.
- Vendor lock-in risk: tools that don't export standard formats create migration risk.
- Governance and compliance requirements are often an afterthought in data science tooling.
- The Julia ecosystem, while powerful, has a steeper on-ramp for teams predominantly Python-native.

**Platform Expectations:**
- Full Julia source code export for every platform-generated workflow — zero lock-in.
- Kubernetes-native deployment: Helm charts, GPU node affinity, autoscaling policies.
- Enterprise model registry integration (MLflow Model Registry, Weights & Biases, custom).
- Feature store integration (Feast, Tecton, or native platform feature store).
- Multi-GPU and distributed training orchestration with configurable parallelism strategies.
- Role-based access control (RBAC) with fine-grained permissions per project and phase.
- SLA-level performance benchmarking reports for executive and procurement review.
- Open API specification for all platform services — integrable with existing organisational tooling.
- Audit trail and compliance reporting for regulated industry use cases (finance, healthcare).

**Canvas Interaction Style:** Strategic evaluator and platform architect. Uses the platform in evaluation mode (benchmarking, stress-testing), architects the organisation's CRISP-DM process templates, sets governance policies, and reviews platform integration with enterprise infrastructure. Delegates day-to-day workflow construction to DS-1 through DS-3.

---

### 6.2 Extended Persona Groups

Beyond the Data Scientist family, the following roles interact with JuliaDS Studio in supporting capacities.

| Persona | Role Summary | Primary Interaction |
|---|---|---|
| **Business Analyst** | Non-technical; frames business questions and consumes EDA outputs | Phase 1 (Business Understanding canvas), EDA report viewer |
| **Data Engineer** | Builds and maintains data pipelines; owns source connectors | Phase 2 ingestion configuration, data versioning, pipeline scheduling |
| **ML Engineer / MLOps** | Owns model deployment infrastructure and monitoring | Phase 6 (Deployment module), Kubernetes integration, model monitoring |
| **Domain Expert** | Subject-matter authority; validates data semantics and business rules | Phase 1 & 2; annotates data quality issues, validates feature logic |
| **Researcher / Academic** | Needs high-performance numerical computation on scientific datasets | Full CRISP-DM canvas; custom Julia node authoring; GPU kernel access |

---

## 7. Feature Requirements by CRISP-DM Phase

### 7.1 Phase 1 — Business Understanding Module

**Purpose:** Structure the data science project before a single byte of data is loaded. Define the objective, success criteria, stakeholder map, and constraints.

- **FR-001:** Project creation wizard walks users through defining the business objective, problem type (classification, regression, clustering, time-series, anomaly detection), and target KPIs.
- **FR-002:** Success criteria canvas: visual definition of model acceptance thresholds (minimum accuracy, maximum latency, cost constraints).
- **FR-003:** Stakeholder map node: record project roles, approvers, and notification routing.
- **FR-004:** Constraint canvas: document data access restrictions, regulatory requirements, and deployment environment limits before work begins.
- **FR-005:** Automatic CRISP-DM project report generation summarising Phase 1 outputs as a shareable PDF brief.
- **FR-006:** Phase 1 checkpoint gate: summary card with explicit "Proceed to Data Understanding" approval action.

---

### 7.2 Phase 2 — Data Understanding & EDA Module

**Purpose:** Ingest raw data, profile its quality, and develop an initial understanding of its structure, distributions, and relationships.

#### 7.2.1 Data Ingestion

- **FR-007:** Drag-and-drop file upload supporting: CSV, TSV, Excel (.xlsx/.xls), Parquet, JSON, JSONL, Apache Arrow (.arrow, .feather), HDF5, and Avro.
- **FR-008:** Connector library for external sources: PostgreSQL, MySQL, MariaDB, SQLite, Microsoft SQL Server, MongoDB, Snowflake, BigQuery, Amazon Redshift, Amazon S3, Azure Blob Storage, Google Cloud Storage.
- **FR-009:** REST API connector with configurable authentication (API key, OAuth2, Basic Auth) and pagination handling.
- **FR-010:** Streaming ingestion preview via Kafka topic sampling (read-only preview; full streaming in v1.1 scope).
- **FR-011:** Automatic schema inference with manual override: detect column names, data types, nullability, and primary key candidates on ingest.
- **FR-012:** Large dataset support: lazy evaluation via Arrow.jl and DataFrames.jl for datasets up to 1 billion rows; columnar execution avoids full dataset materialisation.
- **FR-013:** Dataset preview panel: first 1,000 rows, column statistics sidebar, row/column count badge.

#### 7.2.2 Data Understanding & Automated Profiling

- **FR-014:** One-click Auto-Profile generating: per-column distributions (histogram, bar for categoricals), missing value heatmap, outlier flags (IQR and Z-score), cardinality analysis, duplicate row detection, correlation matrix (Pearson, Spearman), and temporal feature detection.
- **FR-015:** GPU-accelerated profiling: when a GPU is available, correlation matrix computation and distribution fitting are dispatched to the GPU for datasets >5M rows, with automatic fallback to CPU.
- **FR-016:** Data quality score: composite score (0–100) per column and per dataset based on completeness, consistency, uniqueness, and validity.
- **FR-017:** Interactive EDA canvas: drag columns onto a chart builder to generate scatter plots, histograms, box plots, violin plots, heatmaps, pair plots, geographic choropleth maps, and time series decomposition charts.
- **FR-018:** Cross-filter interactivity: selections in one chart automatically filter all linked charts on the canvas.
- **FR-019:** Export EDA profile report as: HTML, PDF, or Markdown.
- **FR-020:** Phase 2 checkpoint gate: data quality summary, list of flagged issues, "Proceed to Data Preparation" action.

---

### 7.3 Phase 3 — Data Preparation & Feature Engineering Module

**Purpose:** Transform raw data into a clean, structured, versioned dataset ready for modelling. Engineer features that encode domain knowledge.

#### 7.3.1 Data Preparation Canvas Nodes

- **FR-021:** **Filter node:** row filtering by condition, value set, or expression. Supports compound conditions with AND/OR logic.
- **FR-022:** **Missing value handler node:** strategies per column — drop, mean/median/mode impute, forward/backward fill, constant fill, or model-based imputation (KNN imputer).
- **FR-023:** **Outlier treatment node:** cap at percentile, winsorize, remove rows, or flag as binary indicator column.
- **FR-024:** **Type cast node:** explicit column type conversion with validation.
- **FR-025:** **Join/Merge node:** inner, left, right, outer, cross joins across two dataset inputs; visual key mapping.
- **FR-026:** **Pivot / Unpivot node:** reshape data between wide and long format.
- **FR-027:** **Aggregate node:** group-by with configurable aggregation functions (sum, mean, count, std, percentile, first, last, custom).
- **FR-028:** **Sort node:** multi-column ascending/descending sort.
- **FR-029:** **Sample node:** random sample, stratified sample, reservoir sample for large datasets.
- **FR-030:** **Deduplication node:** exact-match and fuzzy-match (Levenshtein distance) deduplication options.
- **FR-031:** **String processing node:** trim, lower/upper, regex extract, split, replace, tokenise.
- **FR-032:** **Date/time feature node:** extract year, month, day, weekday, hour, quarter, elapsed time, lag features.

#### 7.3.2 Feature Engineering Nodes

- **FR-033:** **Encoding node:** one-hot encoding, ordinal encoding, target encoding, binary encoding, frequency encoding for categorical columns.
- **FR-034:** **Scaling / Normalisation node:** Min-Max, Z-score standardisation, robust scaling, log transform, Box-Cox transform, Yeo-Johnson transform.
- **FR-035:** **Interaction feature node:** generate product, ratio, polynomial, and cross-join feature combinations.
- **FR-036:** **Binning node:** equal-width, equal-frequency, and custom-cut binning; supervised binning via entropy minimisation.
- **FR-037:** **Dimensionality reduction node (pre-model):** PCA, Truncated SVD, UMAP for feature reduction before modelling.
- **FR-038:** **Custom feature expression node:** free-form Julia expression on column references (e.g., `log(col_a + 1) / sqrt(col_b)`), executed on the Julia backend.
- **FR-039:** **GPU-accelerated feature computation:** large-scale scaling, encoding, and matrix operations are dispatched to GPU when available via CUDA.jl array operations.

#### 7.3.3 Data Versioning

- **FR-040:** Every dataset output from the preparation canvas is automatically assigned a **semantic version** (MAJOR.MINOR.PATCH) and a content hash.
- **FR-041:** **Dataset version registry:** browsable list of all dataset versions with provenance metadata (creation time, parent version, nodes applied, user, project).
- **FR-042:** **Data diff view:** visual comparison of schema, row counts, column statistics, and sample rows between any two dataset versions.
- **FR-043:** **Data lineage graph:** auto-generated DAG visualising the full transformation chain from every raw source to every versioned output.
- **FR-044:** Any dataset version can be pinned as a **snapshot** and used as an immutable input to a model training run.
- **FR-045:** Dataset versions are stored using an Arrow-based columnar format with optional delta encoding to minimise storage overhead.
- **FR-046:** Phase 3 checkpoint gate: feature list summary, dataset version badge, "Proceed to Modelling" action.

---

### 7.4 Phase 4 — Modelling, Algorithm & Clustering Module

**Purpose:** Train, tune, and evaluate machine learning models and clustering algorithms on prepared datasets. Support both CPU and GPU execution paths.

#### 7.4.1 Supervised Learning Nodes

- **FR-047:** **Algorithm palette:** Linear Regression, Ridge, Lasso, ElasticNet, Logistic Regression, Decision Tree, Random Forest, Gradient Boosted Trees (XGBoost.jl / LightGBM.jl), Support Vector Machine (SVM), k-Nearest Neighbours (kNN), Naïve Bayes, Neural Network (Flux.jl MLP).
- **FR-048:** All algorithms are exposed through the **MLJ.jl unified interface**, ensuring consistent model configuration, training, and evaluation APIs.
- **FR-049:** Each algorithm node exposes its hyperparameters through a structured form panel with documentation tooltips and suggested default ranges.
- **FR-050:** **Train/Test Split node:** configurable split ratio, stratification option, random seed, and cross-validation fold generation.
- **FR-051:** **Cross-Validation node:** k-fold, stratified k-fold, leave-one-out, and time-series split. Results aggregated and displayed in the evaluation dashboard.

#### 7.4.2 Deep Learning Nodes (Flux.jl)

- **FR-052:** **Neural Network designer node:** visual layer stack builder (Dense, Conv2D, LSTM, GRU, Dropout, BatchNorm, Attention) with automatic parameter count display.
- **FR-053:** Configurable loss functions: MSE, MAE, CrossEntropy, FocalLoss, Huber, custom Julia expression.
- **FR-054:** Configurable optimisers: SGD, Adam, AdaGrad, RMSProp, AdamW, LAMB.
- **FR-055:** Training progress dashboard: live loss curve, metric curves, gradient norm display, learning rate schedule visualisation.
- **FR-056:** GPU training toggle: one click dispatches the Flux.jl training loop to the available GPU device via CUDA.jl. Automatic fallback to CPU if no GPU detected.

#### 7.4.3 Hyperparameter Optimisation

- **FR-057:** **Grid Search node:** exhaustive search over a defined parameter grid; embarrassingly parallel execution across available CPU threads or GPU streams.
- **FR-058:** **Random Search node:** configurable iteration budget with random parameter sampling from defined distributions.
- **FR-059:** **Bayesian Optimisation node:** surrogate model-guided search using Gaussian Process via Surrogates.jl or BayesianOptimization.jl; GPU-accelerated surrogate fitting for large search spaces.
- **FR-060:** All hyperparameter search nodes log every trial to the experiment tracker automatically.

#### 7.4.4 Clustering Module

- **FR-061:** **K-Means node:** configurable k, initialisation strategy (k-means++, random), convergence tolerance. GPU-accelerated via CUDA.jl matrix operations for datasets >500K rows.
- **FR-062:** **DBSCAN node:** density-based clustering with epsilon and min-samples parameters; handles irregular cluster shapes and noise points.
- **FR-063:** **Hierarchical Clustering node:** Ward, complete, average, single linkage; interactive dendrogram visualisation with cut-height slider.
- **FR-064:** **Gaussian Mixture Model (GMM) node:** EM algorithm with configurable component count and covariance structure.
- **FR-065:** **HDBSCAN node:** hierarchical DBSCAN for varying-density clusters.
- **FR-066:** **Spectral Clustering node:** graph Laplacian-based clustering; GPU-accelerated eigendecomposition via CUDA.jl.
- **FR-067:** **Cluster evaluation metrics:** Silhouette Score, Davies-Bouldin Index, Calinski-Harabasz Index, Inertia (within-cluster SSE), and visual elbow plots for k selection.
- **FR-068:** **Cluster labelling panel:** assign semantic labels to cluster IDs; labels are persisted in the model version.
- **FR-069:** **Cluster visualisation:** automatic 2D projection (PCA or UMAP) of cluster assignments; colour-coded scatter plot with cluster boundary overlays.

#### 7.4.5 Time Series & Anomaly Detection Nodes

- **FR-070:** **ARIMA / SARIMA node** with auto-ARIMA parameter search.
- **FR-071:** **Prophet node** (via PyCall.jl bridge) for trend + seasonality forecasting.
- **FR-072:** **Anomaly detection node:** Isolation Forest, One-Class SVM, Local Outlier Factor, Autoencoder-based (Flux.jl).
- **FR-073:** Time-series split cross-validation enforced automatically when a temporal index column is detected.

---

### 7.5 Phase 5 — Model Evaluation & Comparison Module

**Purpose:** Rigorously evaluate trained models against success criteria defined in Phase 1, compare experiment runs, and approve models for promotion to deployment.

#### 7.5.1 Evaluation Metrics & Dashboards

- **FR-074:** **Classification metrics:** Accuracy, Precision, Recall, F1, F-beta, ROC-AUC, PR-AUC, Matthews Correlation Coefficient, Cohen's Kappa, Confusion Matrix.
- **FR-075:** **Regression metrics:** RMSE, MAE, MAPE, SMAPE, R², Adjusted R², Residual plots.
- **FR-076:** **Clustering metrics:** Silhouette, Davies-Bouldin, Calinski-Harabasz, external validation (Adjusted Rand Index, NMI) when ground truth labels are available.
- **FR-077:** **Calibration analysis:** reliability diagram and Brier Score for probabilistic classifiers.
- **FR-078:** **Feature importance panel:** SHAP values (via Shapley.jl / SHAP.jl), permutation importance, and built-in tree feature importance where applicable.
- **FR-079:** **Error analysis view:** interactive table of highest-error predictions with feature values, allowing users to identify systematic failure patterns.
- **FR-080:** **Threshold tuner:** interactive slider for binary classifiers to explore precision/recall trade-off at different decision thresholds; optimal threshold recommendation.

#### 7.5.2 Experiment Tracking & Model Comparison

- **FR-081:** All training runs are logged automatically to the **Experiment Tracker** — no manual logging required. Captured metadata: algorithm, hyperparameters, training dataset version, evaluation metrics, training duration, GPU utilisation, model size.
- **FR-082:** **Experiment comparison table:** side-by-side view of N selected runs with delta columns highlighting metric improvements over a baseline.
- **FR-083:** **Metric parallel coordinates plot:** multi-metric visualisation across experiments for identifying trade-off frontiers.
- **FR-084:** Statistical significance testing between model pairs (paired t-test on cross-validation folds) to prevent spurious "improvement" declarations.

#### 7.5.3 Model Versioning

- **FR-085:** Every trained model is automatically registered in the **Model Registry** with a semantic version, algorithm identifier, training dataset version reference, and performance metric snapshot.
- **FR-086:** **Model diff:** compare hyperparameters, training data version, and evaluation metrics between any two registered model versions.
- **FR-087:** Model lifecycle states: `Candidate` → `Staging` → `Production` → `Archived`. Transitions require explicit promotion actions and optionally require approvals from DS-3/DS-4 roles.
- **FR-088:** **Model rollback:** one-click rollback of a Production model to any prior Staging or Production version.
- **FR-089:** Models are serialised using BSON.jl (Julia-native) and optionally exported to ONNX format for cross-platform compatibility.
- **FR-090:** Phase 5 checkpoint gate: summary of best model, metric vs. success criteria comparison, "Promote to Deployment" action button.

---

### 7.6 Phase 6 — Model Deployment & Serving Module

**Purpose:** Deploy approved models to production serving infrastructure, monitor model health, and manage deployed versions.

#### 7.6.1 Model Serving

- **FR-091:** One-click deployment of any Production-state model to a **Julia-native REST API endpoint** via Genie.jl or HTTP.jl serving layer.
- **FR-092:** Automatically generated OpenAPI 3.0 specification for every deployed model endpoint.
- **FR-093:** Batch prediction node: schedule bulk scoring jobs against stored datasets with configurable frequency.
- **FR-094:** **Containerised deployment package:** generate a ready-to-deploy Docker image containing the Julia runtime, model artefact, and serving code, with no manual Dockerfile authoring.
- **FR-095:** **Kubernetes deployment manifest generation:** Helm chart export with configurable replica count, resource requests/limits, GPU node affinity, and horizontal pod autoscaling policy.
- **FR-096:** A/B testing deployment: route a configurable percentage of traffic to a Candidate model alongside the current Production model, with live metric comparison.

#### 7.6.2 Model Monitoring

- **FR-097:** **Data drift monitoring:** compare incoming request feature distributions against training data distributions using KS test, PSI, and Jensen-Shannon divergence; alert on threshold breach.
- **FR-098:** **Prediction drift monitoring:** track output distribution shift over time; configurable alert thresholds.
- **FR-099:** **Model performance monitoring:** for labelled feedback loops, track live accuracy/RMSE/F1 against deployment baselines.
- **FR-100:** **Monitoring dashboard:** time-series charts for all drift and performance metrics; configurable alert routing (email, Slack, PagerDuty webhook).
- **FR-101:** Automatic model retraining trigger: when drift exceeds threshold, create a new CRISP-DM project run pre-seeded with updated data and current model hyperparameters.

#### 7.6.3 Deployment Versioning

- **FR-102:** Every deployment event is recorded: model version, deployment timestamp, configuration snapshot, traffic split policy, deploying user.
- **FR-103:** Full deployment history is visible in the Model Registry with one-click rollback to any prior deployment configuration.

---

## 8. GPU Compute Requirements

Julia's native GPU programming capabilities are a first-class architectural component of JuliaDS Studio, not an optional extension. The following requirements govern GPU integration throughout the platform.

### 8.1 Supported GPU Backends

- **FR-104:** **NVIDIA GPU support** via **CUDA.jl**: full support for CUDA 11.x and 12.x; requires compatible NVIDIA driver on host; tested on RTX 3000/4000 series, A100, H100.
- **FR-105:** **AMD GPU support** via **AMDGPU.jl**: ROCm 5.x+ compatible GPUs; tested on RX 6000/7000 series and MI200/MI300 data centre cards.
- **FR-106:** **Apple Silicon GPU support** via **Metal.jl**: MPS (Metal Performance Shaders) backend for M1/M2/M3/M4 class chips; prioritised for local development and laptop use cases.
- **FR-107:** **Automatic GPU detection and fallback**: at session initialisation, the Julia runtime probes for available GPU devices and registers them in the Resource Manager. If no GPU is available, all GPU-dispatched operations fall back transparently to optimised CPU execution with a UI notification.

### 8.2 GPU Dispatch Model

- **FR-108:** **Automatic GPU dispatch for qualifying operations**: the platform automatically selects GPU execution for: matrix multiplications above a configurable size threshold, correlation matrix computation, PCA/SVD on matrices >10K×10K, neural network training batches, k-means clustering on datasets >500K rows, hyperparameter search parallel trial execution.
- **FR-109:** **Manual GPU dispatch override**: users can explicitly force GPU or CPU execution per node via an advanced settings toggle. Senior and Principal DS personas see GPU memory utilisation estimates before execution.
- **FR-110:** **GPU memory management**: the Julia runtime manages GPU memory allocation, deallocation, and garbage collection for all dispatched operations. Users never interact with raw GPU memory APIs directly.
- **FR-111:** **Multi-GPU support**: for DS-3 and DS-4 personas, multi-GPU data parallelism is exposed for Flux.jl training via `Flux.DataParallel` and `CUDA.jl` multi-device APIs, configurable from the neural network node panel.
- **FR-112:** **Distributed GPU training**: model training workloads can be distributed across multiple nodes with GPU accelerators using `Distributed.jl` combined with `CUDA.jl`, configured via the cluster configuration panel.

### 8.3 GPU-Accelerated Workflow Operations

The following operations receive native GPU acceleration throughout the CRISP-DM phases:

| Operation | Julia Library | GPU Backend | Benefit |
|---|---|---|---|
| Correlation matrix (large datasets) | CUDA.jl CuArrays | NVIDIA / AMD | 10–50× speedup vs CPU |
| PCA / SVD | LinearAlgebra.jl on CuArray | NVIDIA / AMD / Metal | Enables 100M+ row PCA |
| K-Means clustering | CUDA.jl distance kernels | NVIDIA / AMD | 20–100× speedup |
| Spectral clustering eigendecomp | CUDA.jl | NVIDIA / AMD | 5–30× speedup |
| Neural network training | Flux.jl + CUDA.jl | NVIDIA / AMD / Metal | Order-of-magnitude speedup |
| Bayesian optimisation surrogate | CUDA.jl | NVIDIA | Parallel acquisition function |
| Hyperparameter search | Distributed.jl + CUDA.jl | NVIDIA / AMD | Parallel trial execution |
| Feature matrix scaling | CuArrays broadcasting | NVIDIA / AMD / Metal | Vectorised GPU BLAS |
| SHAP value computation | Custom CUDA kernel | NVIDIA | Full dataset SHAP feasible |
| Batch inference serving | CUDA.jl | NVIDIA / AMD | High-throughput prediction |

### 8.4 GPU Resource Management

- **FR-113:** **GPU Resource Dashboard**: real-time panel showing per-device GPU utilisation (%), VRAM usage (GB / total), active Julia worker count per device, queued job count, and temperature (where reported by driver).
- **FR-114:** **GPU job queue**: when GPU demand exceeds capacity, jobs are queued with estimated wait times displayed to the user. Priority queuing available to DS-3/DS-4 roles.
- **FR-115:** **GPU cost estimation** (cloud mode): before dispatching a large GPU job, display estimated cost in cloud GPU credits and estimated duration based on dataset size and algorithm complexity.
- **FR-116:** **GPU profiling mode** (DS-3/DS-4): toggle detailed CUDA/ROCm kernel profiling to inspect memory bandwidth, occupancy, and compute throughput per node execution. Exportable as a profiling report.

### 8.5 GPU-Enhanced Application & Platform Performance

Beyond compute acceleration of individual algorithms, GPU capabilities improve overall platform performance in the following ways:

- **FR-117:** **Large-scale EDA rendering**: auto-profiling histograms and correlation matrices for datasets >10M rows are rendered via GPU-backed Makie.jl (WGLMakie with WebGL) to maintain sub-second chart interactivity.
- **FR-118:** **Canvas rendering**: the visual workflow canvas itself leverages WebGL-accelerated rendering (via React Flow / Pixi.js) to maintain fluid performance with 500+ node graphs.
- **FR-119:** **Real-time data preview acceleration**: column statistics in the dataset preview panel are computed using CuArrays for large datasets, reducing preview latency from seconds to milliseconds.
- **FR-120:** **Inference throughput**: deployed model endpoints dispatch batch inference to GPU when request batch size exceeds a configurable threshold, enabling high-throughput production serving.

---

## 9. Platform-Wide Capabilities

### 9.1 Code Export & Reproducibility

- **FR-121:** Any canvas workflow can be exported as a clean, idiomatic Julia script (`.jl`).
- **FR-122:** Export as a Pluto.jl reactive notebook (`.jl` Pluto format).
- **FR-123:** Export as a Jupyter notebook (`.ipynb`) via IJulia.jl kernel.
- **FR-124:** Each canvas node has a "View Julia Code" toggle revealing the exact generated Julia code. This code is auditable and can be copied directly.
- **FR-125:** Git integration: commit any canvas workflow, dataset version, or model version directly to a connected Git repository from within the platform.
- **FR-126:** **Workflow reproducibility checksum**: a cryptographic hash of the complete workflow (nodes, parameters, data version, model version, Julia package environment) is stored with every checkpoint to enable exact reproduction.

### 9.2 Experiment Tracking

- **FR-127:** Integrated experiment tracker (inspired by MLflow/W&B but Julia-native) captures all training runs without user configuration.
- **FR-128:** Experiment runs are grouped by project and CRISP-DM phase.
- **FR-129:** Export experiment run logs to MLflow or Weights & Biases via adapter integrations (DS-3/DS-4 feature).

### 9.3 Collaboration

- **FR-130:** Share canvas projects via link with read-only or edit permissions.
- **FR-131:** Comment annotations on any node, dataset version, or model version.
- **FR-132:** Real-time collaborative editing of canvas workflows (multi-user, conflict-free via CRDT).
- **FR-133:** Workspace and project management: organisations, teams, and projects with RBAC.
- **FR-134:** Activity feed: per-project audit log of all user actions, version transitions, and deployment events.

### 9.4 Scheduling & Automation

- **FR-135:** **Pipeline scheduler**: schedule any saved canvas workflow to execute on a cron schedule or on data-arrival trigger.
- **FR-136:** **Retraining automation**: configure a model to retrain automatically when a new data snapshot is available or when drift alert fires.
- **FR-137:** **Notification system**: configurable alerts for job completion, failure, drift breach, and model promotion via email, Slack, and webhook.

---

## 10. Non-Functional Requirements

| Category | Requirement | Target |
|---|---|---|
| **Performance — CPU** | Auto-profiling 10M-row dataset (CPU baseline) | < 10 seconds |
| **Performance — GPU** | Auto-profiling 10M-row dataset (GPU-accelerated) | < 2 seconds |
| **Performance — Training** | Neural network training 1M rows, 50 epochs, GPU | < 5 minutes on A100-class GPU |
| **Latency — Charts** | Interactive chart render for datasets ≤ 1M rows | < 500ms |
| **Latency — Inference** | REST endpoint p99 single-record prediction | < 50ms |
| **Scalability** | Concurrent active user sessions | 500+ on standard cloud cluster |
| **Availability** | Cloud SaaS uptime SLA | 99.9% monthly |
| **Data Scale** | Maximum supported dataset size (lazy eval) | 1 billion rows |
| **Model Artefact Size** | Maximum single registered model artefact | 20GB |
| **Security** | Data encryption at rest and in transit | AES-256 / TLS 1.3 |
| **Compliance** | Target certifications | SOC 2 Type II, ISO 27001 |
| **Accessibility** | Web UI standard | WCAG 2.1 AA |
| **Portability** | Deployment modes | Cloud SaaS, Docker (self-hosted), Local desktop |
| **Interoperability** | Model export format | BSON (native), ONNX |
| **TTFP Mitigation** | Julia time-to-first-plot / first-run latency | Precompiled sysimage; < 3s cold start for canvas sessions |
| **GPU Fault Tolerance** | Behaviour on GPU OOM / device failure | Graceful fallback to CPU with user notification; no session crash |
| **Audit Log Retention** | Platform audit logs | Minimum 2 years |

---

## 11. Technical Architecture

```
╔══════════════════════════════════════════════════════════════════╗
║                    FRONTEND  (Web UI)                           ║
║  React 18 + TypeScript                                           ║
║  React Flow (visual canvas)  ·  D3.js / VegaLite (charts)       ║
║  WebGL / WGLMakie bridge (GPU-accelerated rendering)             ║
║  TailwindCSS  ·  shadcn/ui                                       ║
╚══════════════════════════╤═══════════════════════════════════════╝
                           │  REST + WebSocket (TLS 1.3)
╔══════════════════════════▼═══════════════════════════════════════╗
║              API GATEWAY & ORCHESTRATION LAYER                   ║
║  Genie.jl (Julia HTTP framework)  or  HTTP.jl                    ║
║  Session management  ·  Job queue (Redis)                        ║
║  Auth (JWT / OAuth2 / SSO)  ·  RBAC enforcement                  ║
╚══════════════════════════╤═══════════════════════════════════════╝
                           │  Julia Worker Pool Dispatch
           ┌───────────────┼────────────────────┐
           ▼               ▼                    ▼
╔══════════════╗  ╔═════════════════╗  ╔════════════════════╗
║  CPU WORKER  ║  ║   GPU WORKER    ║  ║  DISTRIBUTED       ║
║  POOL        ║  ║   POOL          ║  ║  WORKER CLUSTER    ║
║              ║  ║                 ║  ║                    ║
║ DataFrames   ║  ║ CUDA.jl         ║  ║ Distributed.jl     ║
║ Statistics   ║  ║ AMDGPU.jl       ║  ║ MPI.jl             ║
║ MLJ.jl       ║  ║ Metal.jl        ║  ║ Dagger.jl          ║
║ Clustering   ║  ║ Flux.jl GPU     ║  ║ Multi-GPU training ║
║ Arrow.jl     ║  ║ CuArrays        ║  ║                    ║
╚══════════════╝  ╚═════════════════╝  ╚════════════════════╝
           │               │                    │
           └───────────────┴────────────────────┘
                           │
╔══════════════════════════▼═══════════════════════════════════════╗
║              PLATFORM SERVICES LAYER                             ║
║  Data Version Registry (Arrow + DVC-compatible)                  ║
║  Model Registry (BSON.jl + ONNX export)                          ║
║  Experiment Tracker (Julia-native; MLflow adapter)               ║
║  Pipeline Scheduler (cron + event triggers)                      ║
║  Monitoring Service (drift detection, alerting)                  ║
╚══════════════════════════╤═══════════════════════════════════════╝
                           │
╔══════════════════════════▼═══════════════════════════════════════╗
║                  DATA & STORAGE LAYER                            ║
║  Object Storage: S3 / GCS / Azure Blob (dataset + model artefacts)║
║  Metadata DB: PostgreSQL (versions, lineage, experiments)        ║
║  Cache: Redis (session state, job queue, preview cache)          ║
║  RDBMS Connectors: PG / MySQL / Snowflake / BigQuery             ║
║  Apache Arrow IPC (in-process columnar exchange)                 ║
╚══════════════════════════╤═══════════════════════════════════════╝
                           │  (Cloud Mode)
╔══════════════════════════▼═══════════════════════════════════════╗
║              DEPLOYMENT & SERVING LAYER                          ║
║  Kubernetes (Helm charts, GPU node affinity, HPA)                ║
║  Model REST Endpoints (Genie.jl serving)                         ║
║  Docker image builder (per-model containerisation)               ║
║  A/B traffic splitter · Monitoring agent sidecar                 ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 12. Julia Ecosystem Dependency Map

| Domain | Julia Package(s) | Version Target | Purpose |
|---|---|---|---|
| Data frames & manipulation | DataFrames.jl, DataFramesMeta.jl | 1.6+ | Core tabular operations |
| Columnar / lazy I/O | Arrow.jl, Parquet.jl, HDF5.jl | Latest stable | Large file I/O, versioned storage |
| Statistics | Statistics.jl (stdlib), StatsBase.jl, HypothesisTests.jl | Latest stable | Descriptive stats, hypothesis testing |
| ML unified interface | MLJ.jl + MLJModelInterface.jl | Latest stable | All supervised learning models |
| Deep learning | Flux.jl | 0.14+ | Neural networks, GPU training |
| GPU — NVIDIA | CUDA.jl | 5.x | CUDA kernels, CuArrays |
| GPU — AMD | AMDGPU.jl | Latest stable | ROCm kernels |
| GPU — Apple | Metal.jl | Latest stable | MPS kernels |
| Clustering | Clustering.jl | Latest stable | K-Means, DBSCAN, hierarchical |
| Dimensionality reduction | MultivariateStats.jl, UMAP.jl | Latest stable | PCA, UMAP, tSNE |
| Visualisation | Makie.jl (WGLMakie), VegaLite.jl | Latest stable | Interactive charts, GPU render |
| Bayesian optimisation | BayesianOptimization.jl / Surrogates.jl | Latest stable | HPO |
| Time series | TimeSeries.jl, StateSpaceModels.jl | Latest stable | ARIMA, decomposition |
| Anomaly detection | OutlierDetection.jl | Latest stable | Isolation Forest, LOF |
| SHAP / interpretability | Shapley.jl | Latest stable | Feature importance |
| Model serialisation | BSON.jl | Latest stable | Model artefact storage |
| ONNX export | ONNX.jl | Latest stable | Cross-platform model export |
| Web framework | Genie.jl / HTTP.jl | Latest stable | REST API, WebSocket |
| Distributed computing | Distributed.jl (stdlib), Dagger.jl | Latest stable | Multi-node parallelism |
| Python interop | PyCall.jl | Latest stable | Prophet, scikit-learn bridge |
| R interop | RCall.jl | Latest stable | R model bridges |
| Reactive notebooks | Pluto.jl | Latest stable | Notebook export |

---

## 13. Key Differentiators

| Capability | JuliaDS Studio | KNIME | RapidMiner | Databricks | MLflow + DVC |
|---|---|---|---|---|---|
| Full CRISP-DM visual coverage | ✅ | ✅ | ✅ | ⚠️ Partial | ❌ |
| Julia-powered backend | ✅ | ❌ (Java) | ❌ (Java/Python) | ❌ (Python/Scala) | ❌ |
| Native GPU acceleration | ✅ First-class | ❌ | ❌ | ⚠️ Via Spark ML | ❌ |
| Multi-GPU training | ✅ | ❌ | ❌ | ✅ | ❌ |
| Integrated data versioning | ✅ | ❌ | ❌ | ⚠️ Delta Lake | ✅ (DVC) |
| Integrated model versioning | ✅ | ❌ | ⚠️ | ✅ | ✅ |
| Visual model deployment | ✅ | ⚠️ | ⚠️ | ✅ | ❌ |
| Drag-and-drop model builder | ✅ | ✅ | ✅ | ❌ | ❌ |
| Code export (reproducible) | ✅ Julia | ⚠️ KNIME format | ❌ | ✅ Python | ✅ |
| 1B+ row dataset support | ✅ (Arrow lazy) | ❌ | ❌ | ✅ | ❌ |
| Self-hostable (Docker/K8s) | ✅ | ✅ | ✅ | ❌ | ✅ |
| Built-in drift monitoring | ✅ | ❌ | ❌ | ✅ | ❌ |
| 4-tier persona-aware UX | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## 14. Success Metrics & KPIs

### Product Adoption

- 500 registered users within 3 months of public beta; 2,500 within 6 months.
- 40% of registered users complete at least one full CRISP-DM workflow (Phase 1 through Phase 6) within their first 30 days.
- 25% of active projects include at least one GPU-accelerated training node.

### Performance Benchmarks

- Auto-profiling (CPU): 10M-row dataset completes in under 10 seconds on 8-core cloud instance.
- Auto-profiling (GPU): 10M-row dataset completes in under 2 seconds on single A100 GPU.
- Neural network training: 95th percentile training job for 1M-row, 10-feature dataset, 100 epochs, completes in under 3 minutes on GPU.
- Model deployment latency: p50 < 20ms, p99 < 50ms for single-record REST inference.

### Quality & Engagement

- Average session length: > 35 minutes for DS-2 and above personas.
- Code export rate: > 35% of completed projects export a Julia script or notebook.
- Model deployment rate: > 20% of models reaching Phase 5 evaluation are promoted to deployment.
- NPS: ≥ 50 at 90-day post-launch survey across all persona tiers.

### Reliability

- Platform uptime: ≥ 99.9% monthly in cloud SaaS mode.
- GPU job failure rate (excluding out-of-memory): < 0.5% of dispatched GPU jobs.
- Data version integrity: zero checksum mismatches in dataset version registry.

---

## 15. Assumptions & Constraints

### Assumptions

- Users access the platform via modern web browsers (Chrome 110+, Firefox 115+, Safari 16+, Edge 110+).
- Julia 1.10+ is the minimum supported runtime version; Julia 1.11+ is the target for precompilation improvements.
- For GPU features, users are responsible for ensuring compatible GPU drivers are installed in self-hosted deployments; cloud SaaS manages GPU drivers internally.
- The v1.0 release targets structured tabular data as the primary data type. Unstructured data (text documents, raw images, audio) is out of scope for v1.0.
- Cloud SaaS is the primary delivery model; self-hosted Docker is a simultaneous v1.0 deliverable; Kubernetes Helm chart follows in v1.1.
- The development team includes engineers with Julia expertise; Julia training for Python-native engineers is budgeted as part of team onboarding.

### Constraints

- **Julia TTFP:** Julia's time-to-first-execution latency must be masked via precompiled system images and persistent warm Julia worker processes. Cold start for a new session must not exceed 3 seconds in cloud mode.
- **GPU availability:** GPU-accelerated features degrade gracefully to CPU when hardware is unavailable. The product must be fully functional (at reduced performance) on CPU-only deployments.
- **ONNX export coverage:** Not all Julia-native model types have full ONNX support at time of writing; BSON.jl native serialisation is the primary artefact format, with ONNX as best-effort export.
- **Browser GPU (WebGL):** Canvas and chart WebGL rendering requires the user's browser to have hardware acceleration enabled; a software fallback renderer is provided with a performance warning.
- **v1.0 scope budget:** Advanced NLP/LLM nodes, streaming real-time ingestion (Kafka consumer), and federated learning capabilities are deferred to v2.0.

---

## 16. Out of Scope (v1.0)

The following capabilities are explicitly deferred and will be considered for subsequent release versions.

- Large Language Model (LLM) integration and natural language query interface ("Ask your data").
- Real-time streaming ingestion (full Kafka consumer, Kinesis) — preview mode only in v1.0.
- Federated learning and privacy-preserving ML.
- AutoML: fully automated algorithm selection and feature engineering without user input.
- Advanced geospatial analysis beyond choropleth map rendering (routing, spatial joins, raster data).
- Mobile application (iOS / Android).
- Unstructured data modelling (raw image classification, NLP text pipelines).
- Fine-tuning of foundation models (LLMs, Vision Transformers).
- Built-in feature store (external feature store integration via API is in scope).

---

## 17. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation Strategy |
|---|---|---|---|
| Julia TTFP latency degrades UX | High | High | Precompiled PackageCompiler.jl sysimage; persistent warm worker pool per session; lazy module loading |
| GPU driver incompatibility in self-hosted deployments | Medium | High | Pre-validated Docker images with pinned NVIDIA/AMD driver versions; detailed compatibility matrix in docs |
| GPU OOM crashes during large training jobs | Medium | High | Pre-execution VRAM estimation; configurable batch size auto-tuning; graceful CPU fallback with session preservation |
| Julia ecosystem maturity vs. Python | Medium | Medium | PyCall.jl bridge for critical Python-only packages (Prophet, some AutoML); clearly documented fallback strategies |
| Canvas performance degradation with 500+ node workflows | Medium | Medium | WebGL-accelerated canvas rendering; node virtualisation for off-screen elements; incremental DAG evaluation |
| Data privacy risk for cloud uploads | High | High | End-to-end encryption; on-premise Docker option; data residency configuration; SOC 2 audit programme |
| Model versioning storage cost at scale | Low | Medium | Delta-encoded artefact storage; configurable retention policies; tier-based artefact archival |
| Competitive response from established platforms | High | Medium | Focus on Julia performance + GPU differentiation; open-source core to build community moat |
| Team Julia skill ramp-up | Medium | Medium | Invest in Julia training for team; hire Julia-experienced engineers; leverage Discourse and JuliaCon community |
| ONNX export gaps for Julia models | Medium | Low | Default to BSON native; ONNX as opt-in; document known gaps; contribute to ONNX.jl upstream |

---

## 18. High-Level Roadmap

| Phase | Timeline | Scope |
|---|---|---|
| **Phase 0 — Foundation** | Months 1–3 | Julia compute API scaffold, React canvas shell, CSV/Parquet ingestion, 10 core data prep nodes, CPU auto-profiling, basic chart engine. Internal engineering dog-food only. |
| **Phase 1 — Alpha** | Months 4–6 | Full CRISP-DM canvas navigation, 35 data prep nodes, supervised ML nodes (MLJ.jl), K-Means clustering, experiment tracker, data versioning v1, Julia/Pluto export, model registry v1. DS-2 and DS-3 persona testing. |
| **Phase 2 — GPU Beta** | Months 7–9 | GPU dispatch layer (CUDA.jl, AMDGPU.jl), Flux.jl neural network designer, GPU-accelerated profiling and clustering, multi-GPU training, GPU resource dashboard, hyperparameter search nodes, Bayesian optimisation. Private beta with DS-3/DS-4 cohort. |
| **Phase 3 — Full Beta** | Months 10–12 | Model deployment (REST endpoint + Docker), monitoring and drift detection, RBAC and team collaboration, Phase 5 model evaluation dashboard, SHAP explainability, model rollback, Metal.jl (Apple Silicon) support. Open public beta. |
| **Phase 4 — GA v1.0** | Months 13–15 | Cloud SaaS launch, Kubernetes Helm charts, enterprise auth (SSO/LDAP), audit logging, pipeline scheduler, comprehensive documentation, onboarding flows, SOC 2 audit initiation. |
| **Phase 5 — v1.1** | Months 16–18 | Streaming ingestion (Kafka), feature store integration (Feast/Tecton), A/B deployment traffic splitting, advanced time series module, Weights & Biases / MLflow adapter. |
| **Phase 6 — v2.0** | Month 19+ | AutoML nodes, LLM integration, natural language query, federated learning, unstructured data pipelines, advanced geospatial module. |

---

## 19. Approvals & Sign-Off

| Role | Name | Signature | Date |
|---|---|---|---|
| **Product Owner** | | | |
| **Engineering Lead** | | | |
| **Data Science Lead** | | | |
| **ML/MLOps Lead** | | | |
| **UX Design Lead** | | | |
| **Security & Compliance** | | | |
| **Executive Sponsor** | | | |

---

*JuliaDS Studio BRD v2.0.0 — This is a living document. All requirements are subject to revision following stakeholder review, technical discovery, and user research. Version history is maintained in the project Git repository. Next scheduled review: 2026-04-06.*
