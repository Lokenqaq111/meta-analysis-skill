# V2 Review Scorecard

Cycle: 5 (independent R runtime verification)

Environment branch: A (`V2_VERIFIED=YES`; R 4.3.3, `meta` 8.5.0, `metafor` 5.0.1, `netmeta` 3.6.1)

| ID | Source | Check | Status | Evidence / limitation |
|---|---|---|---|---|
| R1 | Both | Repository scripts execute the analysis | PASS | CLI dispatches to repository-owned mode runners. Runtime examples produced SMD 0.561, MD 31.8, RR 0.628. |
| R2 | Both | No invented data; validation precedes analysis | PASS | Blank/invalid data stop before dispatch; conversions require explicit source/formula notes. |
| R3 | GPT | Dynamic x limits preserve large MD values | PASS | Runtime MD limits: -6.2, 68.2. |
| R4 | Both | Correct NMA API and P-score/SUCRA terminology | PASS | Toy NMA ran `forest.netmeta` and wrote `ranking_pscore.txt` only. Pairwise is resolved from `meta` when `netmeta` does not export it. |
| R5 | GPT | Current non-deprecated HK API | PASS | Pairwise engines use `method.random.ci = "HK"`. Installed `netmeta` uses `t-dist` instead of the meta-package `HK` string. |
| R6 | GPT | k gates use independent-study count | PASS | Executable gates use unique study IDs at k=3/10. Runtime: k=2 skips diagnostics; k=3/10 activate. |
| R7 | Both | Multi-arm/dependence/direction/change-final validation | PASS | Shared control, duplicates, unsupported designs, direction, units, and change/final rules are implemented. Direction reversal flips effect sign. |
| R8 | GPT | Effect-specific small-study test routing | PASS | MD/RR, OR, SMD, prevalence, k, and equal-precision paths are explicit. |
| R9 | GPT | Random-effects wording is non-absolute | PASS | Model is documented as a configurable estimand default. |
| R10 | GPT | No hard-coded MCID | PASS | Repository tests find no universal threshold values. |
| R11 | GPT + user | Independent prevalence mode runs | PASS | Pooled prevalence 0.1998; 0% and 100% studies retained; Inverse+REML+HK PLOGIT. |
| R12 | user | JBI/GRADE are manual placeholders only | PASS | No automatic scoring engine exists. |
| R13 | Both | Configurable output path | PASS | Default is `./output/<topic>` and `--outdir` overrides it. |
| R14 | Owner | Lean SKILL.md routes to scripts/references | PASS | Skill validator passes; entry point routes detailed decisions to focused references. |
| R15 | Owner | README has real URL and Claude/Cursor installs | PASS | Bilingual install instructions use the real repository URL and requested paths. |

## Final evidence

- Independent R suite (`tests/run_all.sh`): 10 PASS, 0 FAIL, 0 BLOCKED.
- Static Python suite (`python3 tests/static_tests.py`): 0 FAIL.
- `V2_VERIFIED=YES`.
