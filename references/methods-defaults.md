# Methods Defaults

## Model target

Intervention modes default to a random-effects model with REML because the usual target is an average effect across settings. This is a configurable default, not a rule that all rehabilitation data require random effects. Use `--model common` when the protocol and estimand justify a common-effect model.

Random-effects models give relatively more weight to smaller studies than common-effect models. The report states this explicitly.

## Continuous measures

- Use MD only when studies use a comparable scale and unit.
- Use Hedges' g SMD when studies measure the same construct using different scales.
- Align scale directions before synthesis. V2 never guesses a missing direction.
- Do not combine clearly different constructs merely because SMD is available.

## Hartung-Knapp and prediction intervals

The runners use the installed `meta` package's current `method.random.ci = "HK"` interface and never call the deprecated `hakn = TRUE` form. `scripts/check_env.R` records runtime API evidence.

When `k=2` or `tau^2=0`, notes and reports warn that Hartung-Knapp confidence intervals and prediction intervals may be unstable or unexpectedly wide/narrow. Prediction intervals with few studies require cautious interpretation.

## Diagnostics

- Funnel plot: `k_studies >= 3`.
- Baujat, radial, drapery, and leave-one-out: `k_studies >= 3`.
- Small-study-effects test: `k_studies >= 10`, plus effect-specific and precision checks described in [egger-and-bias.md](egger-and-bias.md).

All gates use unique study IDs rather than CSV row count.

## Clinical thresholds

No MCID is embedded as a universal default. A clinical threshold is applied only when the user supplies a population-appropriate source. Otherwise the report states: `MCID not provided — no clinical threshold applied`.

## Source guidance

- Cochrane Handbook, Chapter 10: analysis and meta-analysis methods.
- Cochrane Handbook, Chapter 13: missing evidence and small-study effects.

