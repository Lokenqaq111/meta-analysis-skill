# Changelog

## v2 — 2026-08-29

V2 replaces prompt-generated analysis code with repository-owned, parameterized R engines.

### Added

- CLI environment gate, validation-only command, and analysis runner.
- Pairwise continuous, binary, and generic engines.
- Independent prevalence mode with PLOGIT main analysis, boundary-study handling, PFT sensitivity analysis, conditional subgroups, and a manual JBI checklist.
- Technical NMA engine with connectivity restriction, netgraph, treatment-effect forest, netheat, optional netsplit, and exact P-score/SUCRA routing.
- Expanded data dictionary, empty templates, synthetic gold-standard examples, reproducible parameters, `rerun.sh`, logs, notes, reports, and test harness.
- Manual RoB/GRADE/JBI placeholders without automatic scoring.

### Fixed

- Removed hard-coded forest x limits; limits now cover model estimates, confidence limits, and available prediction limits.
- Replaced deprecated `hakn = TRUE` calls with runtime-checked `method.random.ci = "HK"` usage.
- Gated funnel/Baujat/radial/drapery/leave-one-out and small-study tests using unique study count.
- Separated funnel visualization from effect-specific small-study-effects testing.
- Corrected network ranking terminology: P-score is the default; SUCRA is used only when explicitly requested and supported.
- Added explicit direction alignment, MD unit checks, change/final warnings, cluster/crossover stops, and pairwise shared-control stops.
- Made output paths configurable with `./output/<topic>` as the default.
- Removed universal MCID examples and absolute claims that random effects are the only valid model for rehabilitation data.

### Deliberately not implemented

- Automatic GRADE, CINeMA, JBI, or risk-of-bias scoring.
- PRISMA flow-diagram generation.
- Numeric extraction or guessing from PDFs/abstracts.
- Publication-grade NMA validity claims.

## v1 — 2026-05-21

Initial prompt-driven prototype. V1 documented useful defaults and output ideas but did not contain a tested executable analysis engine; its original “stable” wording was too strong and is corrected here.

### Included

- Prompt instructions for pairwise and network meta-analysis.
- Four demonstration CSV templates.
- Suggested plots, report sections, REML/Hartung-Knapp defaults, and a ten-study asymmetry-test gate.
