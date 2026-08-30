# Funnel Plots and Small-study-effects Tests

Funnel plots and formal tests are separate decisions.

## Gates

1. Draw a funnel plot only when `k_studies >= 3`; describe it as a small-study-effects visualization, not proof of publication bias.
2. Run a formal test only when `k_studies >= 10`.
3. Even at `k >= 10`, skip the test when study SEs are nearly identical because the regression has no useful precision gradient.

## Effect-specific routing

| Measure | V2 route | Reason/report label |
|---|---|---|
| MD | `method.bias = "linreg"` | Egger regression |
| RR | `method.bias = "linreg"` | Egger regression on log risk ratio |
| OR | `method.bias = "score"` | Harbord score test |
| SMD | Skip automatically | Ordinary Egger regression can have an artefactual effect-SE correlation; require a prespecified SMD-appropriate method |
| PLOGIT / prevalence | Skip automatically | No automatic test is configured; describe the absence rather than extrapolating |

Any runtime rejection by the installed package is written to notes. V2 does not silently substitute a different test.

Formal asymmetry tests generally have low power with fewer than ten studies and asymmetry can have causes other than non-reporting bias. Interpret results with study design, heterogeneity, and contour-enhanced plots.

