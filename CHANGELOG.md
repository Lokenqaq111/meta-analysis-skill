# Changelog

## v1 — 2026-05-21

First tagged release. Workflow is stable; future versions will be additive.

### Included
- Pairwise meta-analysis: continuous (MD / SMD-Hedges), binary (RR / OR, MH), generic (TE / seTE)
- Network meta-analysis via `netmeta` (continuous + binary, long format)
- Two input modes: filled template CSV, or auto-template from a `pubmed-search-casp` `included/` folder
- Standard plot bundle: forest (main + leave-one-out + subgroup), funnel (contour-enhanced), Baujat, radial (Galbraith), drapery, L'Abbé (binary), bubble (meta-regression), netgraph + SUCRA forest (network)
- Three-section Markdown report: statistical interpretation, clinical interpretation, ready-to-edit Results + Discussion paragraphs
- Defaults: random effects (REML), Hartung-Knapp CI, Egger gated at k ≥ 10
- Refuses to impute missing numeric data
