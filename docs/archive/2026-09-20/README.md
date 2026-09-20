# Historical control documents and concept BRDs

These are exact Git-blob snapshots from `a70ea67eda343655f70fe336c294f8ec9e638889`, preserved during AKS-51 on 2026-09-20. `manifest.json` records original paths, sizes, and SHA-256 checksums. Archive attributes disable newline normalization so the bytes remain verifiable across platforms.

Use the current root `Plan.md`, `docs/TODO.md`, and `docs/risk-register.md` for active decisions. Historical checkboxes, skills, machine paths, and readiness statements in these snapshots are not current delivery claims. Paths inside snapshots retain their original repository-root meaning; locate current code from the repository root, or inspect the source commit for removed paths.

- [Plan](Plan.md), [TODO](TODO.md), [risks](risk-register.md).
- [Traceability](brd-traceability.md), [tracker](project-tracker.md), [checkpoint log](checkpoint-log.md).
- [Early EDA concept](BRD_Julia_EDA_Toolkit-Claudev0.md) and [Word BRD](JuliaFlow_BRD_v1.0.docx) are historical design references. The governed BRD is still `business-requirements-v0.3.0.md` at the repository root.

Verify this snapshot with `node --test tests/contracts/control-doc-archive.test.mjs`. Do not edit historical snapshots to repair old paths; add a dated current correction instead.
