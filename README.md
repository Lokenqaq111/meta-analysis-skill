# meta-analysis-r

A [Claude Code](https://claude.com/claude-code) skill for running pairwise and network meta-analyses in R. Designed for rehab / exercise-science workflows where data has already been extracted from primary studies into a CSV.

Given a filled template CSV, the skill validates the data, generates a standalone `analysis.R` script, runs it, and produces:

- a full plot bundle (forest, funnel, Baujat, radial, drapery, leave-one-out, subgroup, L'Abbé, bubble, netgraph + SUCRA — gated by what makes sense for the data)
- a Markdown report with **statistical interpretation**, **clinical interpretation**, and **ready-to-edit Results / Discussion paragraphs**

## Requirements

- R ≥ 4.0
- R packages: `meta`, `metafor`, `netmeta`

```r
install.packages(c("meta", "metafor", "netmeta"))
```

- [Claude Code](https://claude.com/claude-code) CLI

## Install

Clone into your Claude skills directory:

```bash
git clone https://github.com/<your-username>/meta-analysis-skill.git \
  ~/.claude/skills/meta-analysis-r
```

Then in any Claude Code session:

```
/meta-analysis-r
```

(Claude will read `SKILL.md` and walk you through the workflow.)

## Input modes

| Mode | When to use |
|---|---|
| Template CSV | You've already extracted data — fill `templates/{binary,continuous,generic,network}_template.csv` |
| From CASP folder | You've run [pubmed-search-casp](https://github.com/anthropics/skills) and have an `included/` folder — the skill pre-fills a `study` column from filenames |

The skill **will not invent numeric data**. Empty cells stop the run with a question, not an imputed guess.

## Output

Everything lands in `~/Desktop/meta-analysis/<topic>/`:

```
├── analysis.R          # standalone, re-runnable
├── analysis.log
├── report.md           # stats + clinical + draft paragraphs
├── data/               # summary.txt, leave_one_out.txt, etc.
└── plots/              # forest.png, funnel.png, baujat.png, ...
```

## Defaults

- **Random effects (REML)** — rehab data is heterogeneous; fixed-effect is misleading
- **Hedges' g (SMD)** for continuous outcomes on differing scales; **MD** when scales match
- **Hartung-Knapp** CI adjustment (better coverage with few studies)
- **Egger's test** only when k ≥ 10 (Cochrane recommendation)

Override any default by telling Claude in plain language.

## Versioning

See [CHANGELOG.md](CHANGELOG.md). Tagged as `v1` — the workflow is stable enough to use; expect additive changes (more plot types, more outcome modes) rather than breaking ones.

## License

MIT — see [LICENSE](LICENSE).
