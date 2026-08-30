# V2 Review Scorecard

Cycle: 4 (final branch-C audit)

Environment branch: C (`V2_VERIFIED=NO`; R/package runtime checks are BLOCKED)

| ID | Source | Check | Status | Evidence / limitation |
|---|---|---|---|---|
| R1 | Both | Repository scripts execute the analysis | PASS | CLI dispatches to repository-owned mode runners; no full prompt-generated model template remains. Runtime is BLOCKED. |
| R2 | Both | No invented data; validation precedes analysis | PASS | Blank/invalid data stop before dispatch; conversions require explicit source/formula notes. |
| R3 | GPT | Dynamic x limits preserve large MD values | PASS | 20–50 m fixture and CI limits pass. |
| R4 | Both | Correct NMA API and P-score/SUCRA terminology | PASS | Static checks plus runtime-introspection tests exist; default is exact P-score, SUCRA is explicit-only. Runtime is BLOCKED. |
| R5 | GPT | Current non-deprecated HK API | PASS | Runners require `method.random.ci`; environment/API test checks installed help/source when R exists. Runtime is BLOCKED. |
| R6 | GPT | k gates use independent-study count | PASS | Executable gates use unique study IDs at k=3/10. |
| R7 | Both | Multi-arm/dependence/direction/change-final validation | PASS | Shared control, duplicates, unsupported designs, direction, units, and change/final rules are implemented. |
| R8 | GPT | Effect-specific small-study test routing | PASS | MD/RR, OR, SMD, prevalence, k, and equal-precision paths are explicit. |
| R9 | GPT | Random-effects wording is non-absolute | PASS | Model is documented as a configurable estimand default. |
| R10 | GPT | No hard-coded MCID | PASS | Repository tests find no universal threshold values. |
| R11 | GPT + user | Independent prevalence mode runs | PASS | Independent schema, PLOGIT/PFT logic, boundary rule, subgroups, JBI report, and runtime test exist. Runtime is BLOCKED. |
| R12 | user | JBI/GRADE are manual placeholders only | PASS | No automatic scoring engine exists. |
| R13 | Both | Configurable output path | PASS | Default is `./output/<topic>` and `--outdir` overrides it. |
| R14 | Owner | Lean SKILL.md routes to scripts/references | PASS | Skill validator passes; entry point routes detailed decisions to focused references. |
| R15 | Owner | README has real URL and Claude/Cursor installs | PASS | Bilingual install instructions use the real repository URL and all requested paths. |

## Final evidence

- Branch-C suite: 30 PASS, 0 FAIL, 8 BLOCKED.
- Skill structure/frontmatter: PASS (`quick_validate.py`).
- Shell/Python syntax and `git diff --check`: PASS.
- R delimiter/static output-contract audit: PASS.

## Remaining environment limitation

R, `meta`, `metafor`, and `netmeta` runtime execution is BLOCKED. `V2_VERIFIED=NO` remains mandatory until an R environment successfully runs:

```bash
scripts/check_env.sh
tests/run_all.sh
```

