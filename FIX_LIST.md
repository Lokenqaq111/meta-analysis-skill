# V2 Fix List

Cycle: 5 (independent R runtime verification)

Independent retest on 2026-08-30 with R 4.3.3, `meta` 8.5.0, `metafor` 5.0.1, `netmeta` 3.6.1.

## Resolved during independent verification

- Prevalence main analysis now requests `method = "Inverse"` so PLOGIT can use REML/HK. Current `meta` defaults PLOGIT to GLMM, which only accepts `method.tau = "ML"`.
- Network validation no longer requires `year`; that field is pairwise/prevalence-only, matching the data dictionary and network templates.
- NMA uses `meta::pairwise` when `netmeta` no longer exports it, and maps `method.random.ci` to `t-dist` when the installed `netmeta` does not accept `HK`.

## Remaining

No FAIL or BLOCKED test remains. `V2_VERIFIED=YES`.
