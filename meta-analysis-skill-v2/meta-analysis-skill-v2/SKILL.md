---
name: meta-analysis-r
description: Run tested R scripts for pairwise continuous, binary, generic, prevalence, or network meta-analysis after numeric data have already been extracted into CSV. Use for validation, synthesis, plots, diagnostics, and a reproducible Markdown report. Do not use for literature-only searches, protocol writing, extracting numbers from PDFs/abstracts, or automatic GRADE/CINeMA/PRISMA scoring.
metadata:
  short-description: Tested R engines for pairwise, prevalence, and network meta-analysis.
---

# R Meta-analysis V2

Use repository scripts as the analysis engine. Do not rewrite a complete `analysis.R` from a prompt.

## Hard rules

1. Never invent numeric data. An empty required cell stops validation.
2. Do not extract or estimate means, SDs, events, or sample sizes from a PDF or abstract. If the user explicitly requests a documented Cochrane 6.5.2 conversion from reported SE/CI/IQR data, record the source values, formula, and caveat in notes before analysis.
3. Never install R packages silently. Report missing packages and the exact install command, then wait for authorization.
4. Validate before analysis. Do not bypass a failed validator.
5. Refuse meta-analysis with one independent study; suggest narrative synthesis.
6. Preserve `analysis.log`, input data, parameters, `rerun.sh`, plots, summaries, notes, and `report.md` under the selected output directory.
7. Do not apply a universal MCID. Use only a population-appropriate source supplied by the user.
8. RoB, GRADE, and JBI content is a manual placeholder. Do not calculate an automatic certainty score.

## Environment gate

Run from the skill repository root:

```bash
scripts/check_env.sh
```

Read `ENV_REPORT.md`. If R or required packages are unavailable, implement/validate what is possible, mark package-dependent work `BLOCKED`, and do not claim that the analysis pipeline was runtime-verified.

## Select a mode

| Mode | Measure | Template | Use |
|---|---|---|---|
| `continuous` | `SMD` or `MD` | `templates/continuous_empty.csv` | Two-arm aggregate continuous outcomes |
| `binary` | `RR` or `OR` | `templates/binary_empty.csv` | Comparative event counts with intervention/control arms |
| `generic` | Declared effect measure | `templates/generic_empty.csv` | Pre-calculated `TE` and `seTE` |
| `prevalence` | `PLOGIT` | `templates/prevalence_empty.csv` | Single-group prevalence (`events` / `total`) |
| `network` | `RR`, `OR`, `SMD`, or `MD` | `templates/network_empty.csv` | Connected multi-treatment arm-level network |

Prevalence is an independent mode. Never put single-group prevalence data into the comparative binary template.

## Read references only when needed

- Before preparing or validating any CSV, read [references/data-dictionary.md](references/data-dictionary.md).
- For model, direction, HK, prediction-interval, and diagnostic defaults, read [references/methods-defaults.md](references/methods-defaults.md).
- For prevalence, read [references/prevalence.md](references/prevalence.md) and [references/jbi-prevalence-rob.md](references/jbi-prevalence-rob.md).
- For NMA, read [references/nma-limits.md](references/nma-limits.md); connectivity does not establish transitivity.
- When a funnel plot or asymmetry test is relevant, read [references/egger-and-bias.md](references/egger-and-bias.md).
- Before interpreting `report.md`, read [references/report-spec.md](references/report-spec.md).

## Validate

The main runner validates automatically. A validation-only call is also available:

```bash
Rscript scripts/validate.R \
  --input path/to/input.csv \
  --mode continuous \
  --measure SMD
```

When a study contributes multiple outcomes, timepoints, or pairwise rows, select one using `--outcome` / `--timepoint` or stop and ask for a prespecified dependency decision. Pairwise shared controls stop by default.

## Run

```bash
Rscript scripts/run_analysis.R \
  --input path/to/input.csv \
  --mode continuous \
  --measure SMD \
  --outdir output/topic \
  --topic topic
```

Optional arguments include:

- `--model random|common`
- `--target-higher-is-better true|false`
- `--outcome <name>` and `--timepoint <name>`
- `--population <description>` and `--mcid-source <citation>`
- NMA: `--reference <treatment>` and `--ranking P-score|SUCRA`

Default output is `./output/<topic>/`. Use a Desktop path only when the user explicitly asks for it.

## Check outputs

Confirm that the output directory contains:

- `run_parameters.txt` and executable `rerun.sh`;
- `analysis.log`;
- `data/input.csv`, `data/validation.txt`, `data/summary.txt`, `data/notes.txt` when notes exist, and `data/sessionInfo.txt`;
- gated files under `plots/` and `data/`;
- `report.md` in the required section order.

Surface analysis failures verbatim. Do not edit outputs to conceal skipped or failed diagnostics.

## Test the skill

```bash
tests/run_all.sh
```

A nonzero exit means V2 is not complete. `BLOCKED` is acceptable only when `ENV_REPORT.md` identifies environment branch B/C; every non-blocked test must pass.
