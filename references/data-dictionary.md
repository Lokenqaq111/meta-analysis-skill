# Data Dictionary and Validation Rules

Use the mode-specific empty template as the authoritative column order. Demonstration templates contain synthetic `Example*` rows; replace them for real analyses.

## Shared identifiers

| Field | Meaning | Validation |
|---|---|---|
| `study` | Stable study identifier | Required; `k_studies = length(unique(study))` |
| `year` | Publication/report year | Required numeric value for pairwise/prevalence modes |
| `outcome` | One named outcome | Required except prevalence; select one outcome when a study contributes several |
| `timepoint` | One named follow-up | Required for comparative modes; select one when a study contributes several |
| `study_design` | Design label such as `parallel_rct` | Cluster and crossover data stop because V2 does not estimate design corrections |
| `effect_id` | Unique effect/contrast identifier | Required for traceability; it does not replace `study` for k counting |
| `subgroup` | Optional prespecified grouping | Blank is allowed |

## Continuous pairwise

Required columns:

```text
study,year,mean_t,sd_t,n_t,mean_c,sd_c,n_c,outcome,scale,unit,timepoint,higher_is_better,change_or_final,study_design,effect_id,subgroup
```

- `n_t`, `n_c`, `sd_t`, and `sd_c` must be greater than zero.
- `higher_is_better` accepts only true/false. Mixed directions stop unless `--target-higher-is-better` is supplied; reversing a row multiplies both arm means by -1 and leaves SDs unchanged.
- MD requires one comparable scale and unit. Use SMD or separate analyses for different scales.
- Mixing change and final values under SMD generates a warning because their SDs can reflect different reliability.
- Repeated rows from one study stop by default. A shared control stops with a unit-of-analysis error.

## Binary pairwise

Required columns:

```text
study,year,event_t,n_t,event_c,n_c,outcome,timepoint,event_is_beneficial,study_design,effect_id,subgroup
```

Events must satisfy `0 <= event <= n`; sample sizes must be greater than zero. `event_is_beneficial` is required for interpretation even though RR/OR calculation itself uses event counts only.

## Generic pre-calculated effects

Required columns:

```text
study,year,TE,seTE,measure,outcome,scale,unit,timepoint,higher_is_better,change_or_final,study_design,effect_id,subgroup
```

- `seTE` must be greater than zero.
- For RR/OR/HR, `TE` and `seTE` are expected on the log scale used by `meta::metagen()`.
- Multiple effects from one study are reported as dependent; V2 does not fit a multilevel or robust-variance model.

## Network arm-level data

The network template accepts either binary arm data (`event`, `n`) or continuous arm data (`mean`, `sd`, `n`), not both in one file. Continuous network data also require `scale`, `unit`, and `higher_is_better`.

Each study needs at least two treatment arms. See [nma-limits.md](nma-limits.md) for connectivity and interpretation limits.

## Prevalence

See [prevalence.md](prevalence.md). The prevalence schema never uses intervention/control columns.

## Stops versus warnings

The engine stops on missing required cells, invalid numeric bounds, too few independent studies, unhandled cluster/crossover designs, unresolved direction conflicts, incompatible MD units, and pairwise shared controls. Warnings are copied to `data/notes.txt` and `report.md`.

