# Network Meta-analysis Limits

V2 provides a technical frequentist network-meta-analysis workflow; it does not establish publication-grade validity.

## Minimum technical behavior

- At least three independent studies.
- Each study has at least two arms.
- Connectivity is checked before modelling.
- If the network is disconnected, only the largest connected component is analysed and every dropped treatment is named in notes and the report. If that component has fewer than three studies, the analysis stops.
- Outputs request `netgraph`, a treatment-effect forest relative to the reference arm, `netheat`, and `netsplit` when exported by the installed package.
- Arm-level data are converted with `pairwise()` from `meta` when that export exists (current netmeta releases moved it there), otherwise from `netmeta`.

## Ranking terminology

The default ranking metric is **P-score**. Files and reports use `pscore` / `P-score` exactly. SUCRA runs only when the user requests `--ranking SUCRA` and runtime introspection confirms that `netrank()` exposes a `method` argument. P-score output is never relabelled as SUCRA.

Ranking metrics do not replace relative-effect confidence intervals. V2 adds a textual uncertainty warning rather than claiming that a ranking is a treatment recommendation.

## Manual validity checks

Connectivity does not establish transitivity. The report includes a manual table for effect-modifier distributions across direct comparisons. Review at minimum:

- population severity and baseline risk;
- intervention dose and co-interventions;
- outcome definition and timepoint;
- study design and risk of bias;
- whether all treatments were jointly randomizable.

The report records local inconsistency output or states why it was not produced. It never asserts that indirect comparisons are valid merely because code ran.

