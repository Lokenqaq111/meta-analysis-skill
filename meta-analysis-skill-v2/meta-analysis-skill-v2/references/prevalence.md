# Prevalence Mode

Prevalence is an independent single-proportion mode. Do not place prevalence data in the comparative binary template.

## Schema

```text
study,year,events,total,profession,body_region,recall_period,country,setting,risk_of_bias,subgroup
```

`events` and `total` are required numeric values with `total > 0` and `0 <= events <= total`. Other listed context fields are required except that `risk_of_bias` and `subgroup` may be blank pending manual appraisal.

## Main analysis

The main analysis uses `meta::metaprop()` with logit-transformed proportions (`PLOGIT`), REML for random-effects heterogeneity, and the current Hartung-Knapp API when available.

For studies with 0% or 100% prevalence, the inverse-variance PLOGIT call requests a 0.5 continuity correction for boundary studies only (`method.incr = "only0"`) when the installed package exposes those arguments. The report records this rule.

## Sensitivity analysis

V2 attempts a Freeman-Tukey (`PFT`) sensitivity analysis with the same data. It is secondary, not a replacement for the prespecified PLOGIT analysis. If the installed package cannot run it, the result is marked `BLOCKED` in notes rather than invented.

## Outputs

- Pooled prevalence and 95% CI.
- Prediction interval when available, with a small-k warning.
- Conditional subgroup analyses for `body_region`, `country`, `profession`, `recall_period`, and `setting` when a column has at least two non-empty levels.
- Manual JBI checklist copied into `report.md` from [jbi-prevalence-rob.md](jbi-prevalence-rob.md).

V2 does not automatically score JBI items or convert them into evidence certainty.

