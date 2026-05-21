---
name: meta-analysis-r
description: Use when the user has extracted meta-analysis data (binary, continuous, generic, or multi-arm) and wants to run pairwise or network meta-analysis in R, producing forest/funnel/network plots plus a written report covering statistical interpretation, clinical meaning, and ready-to-edit Results/Discussion paragraphs. Requires R with packages meta, metafor, netmeta installed.
metadata:
  short-description: Pairwise + network meta-analysis in R with forest plot, funnel plot, and clinical/writing interpretation.
---

# R Meta-Analysis Workflow

Use this skill when the user wants to actually **run** a meta-analysis (not just search literature). Inputs are a CSV of extracted study data; outputs are plots and a Markdown report under `~/Desktop/meta-analysis/<topic>/`.

This is the natural downstream step from [[reference_pubmed_skill]] (pubmed-search-casp) — but data extraction is a manual step in between and this skill must not synthesize numeric data from PDFs.

## Core Rules

1. **Never invent data.** If a cell in the input CSV is empty or non-numeric, stop and ask. Do not impute means, SDs, or event counts from study abstracts unless the user explicitly says "estimate from abstract" and the estimate is recorded with that caveat in the report.
2. **Validate before running.** Check column types, n > 0, SD > 0, no negative counts, ≥2 studies for pairwise (≥3 + connected network for netmeta).
3. **Show the R script.** Always write the R code to a file in the output directory so the user can re-run / modify. Do not hide it inside a one-shot heredoc.
4. **Random effects by default** (REML estimator). Rehab/exercise data is almost always heterogeneous — fixed-effect is misleading. Override only if user asks.
5. **Hedges' g (SMD) by default for continuous outcomes** when scales differ; **MD** when all studies use the same scale.

## Environment Check (run once at start)

```bash
R --version
R -e 'pkgs <- c("meta","metafor","netmeta"); missing <- pkgs[!pkgs %in% rownames(installed.packages())]; if(length(missing)) cat("MISSING:", missing) else cat("OK")' 2>/dev/null | tail -3
```

If anything missing, tell the user the install command (`install.packages(c("meta","metafor","netmeta"))`) — don't silently install.

## Input Modes

### Mode A — Template CSV (primary)

User fills one of these templates depending on outcome type:

**Binary outcome** (`binary_template.csv`):
```
study,year,event_t,n_t,event_c,n_c,subgroup
Smith2020,2020,12,45,20,44,older
```

**Continuous outcome** (`continuous_template.csv`):
```
study,year,mean_t,sd_t,n_t,mean_c,sd_c,n_c,scale,subgroup
Smith2020,2020,42.1,5.3,30,38.4,6.1,30,6MWT,older
```

**Generic / pre-calculated** (`generic_template.csv`):
```
study,year,TE,seTE,subgroup
Smith2020,2020,0.34,0.12,older
```

**Network meta (long format)** (`network_template.csv`):
```
study,treatment,event,n
Smith2020,strength,12,30
Smith2020,aerobic,8,30
Smith2020,control,4,30
```
(or `study,treatment,mean,sd,n` for continuous)

Save templates inside the skill directory and copy them into the user's output folder when they ask "give me the template".

### Mode B — From CASP output folder

If the user points to a folder produced by [[reference_pubmed_skill]] (typically `~/Desktop/<topic>/included/`):

1. Read the included-articles list (filenames, PMIDs, or a manifest file if present).
2. **Generate an empty template** populated with `study` column = first-author + year extracted from filenames. All numeric columns left blank.
3. Save as `<topic>_to_fill.csv` in the output folder.
4. Tell the user: "I've created the template with N studies pre-filled. Please open it and fill the numeric columns from each study's full text. Re-run me when done."
5. **Do not proceed to analysis until the numeric columns are non-empty.**

## Workflow

1. **Confirm scope.** Ask: outcome type (binary / continuous / generic / network), effect measure (RR/OR/MD/SMD), topic/title for the output folder. If the user already named the file `binary_*.csv` etc., skip the question.

2. **Validate the CSV.**
   - Required columns present
   - No NA in required numeric columns
   - n, sd, event counts ≥ 0; sd, n strictly > 0
   - ≥2 studies (pairwise) or ≥3 studies forming connected network (netmeta)
   - For binary: warn (don't block) on zero cells — `meta` handles continuity correction automatically

3. **Create output folder.** `~/Desktop/meta-analysis/<topic>/` with subfolders `plots/` and `data/` (copy input CSV into `data/`).

4. **Generate the R script** (`analysis.R`) into the output folder. Template structure below.

5. **Run the script.** `R --no-save < analysis.R > analysis.log 2>&1`. Check exit code; if it fails, surface the R error verbatim and stop.

6. **Write the Markdown report** (`report.md`) — see structure below.

7. **Tell the user** the output path and list the three artifacts (analysis.R, plots/*.png, report.md).

## Required Plot Set

Every run produces a **standard plot bundle** so the user gets the full diagnostic picture, not just the headline forest plot. Conditional plots are gated by what makes sense given the data.

| Plot | Always? | Skip condition | What it shows |
|---|---|---|---|
| Forest (main) | yes | — | Pooled effect + per-study effects |
| Funnel | yes (k≥3) | k<3 | Small-study effects, asymmetry. Egger's test only if k≥10. |
| Baujat | yes (k≥3) | k<3 | Which studies drive heterogeneity vs. drive the pooled estimate |
| Radial (Galbraith) | yes (k≥3) | k<3 | Precision-weighted view of each study's effect |
| Drapery | yes (k≥3) | k<3 | CI curves across p-value thresholds |
| Leave-one-out forest (`metainf`) | yes (k≥3) | k<3 | Sensitivity: pooled estimate omitting each study |
| Forest (subgroup) | conditional | `subgroup` col absent or <2 levels | Effect by subgroup, between-group Q |
| L'Abbé | conditional | not a binary outcome | Event rates intervention vs. control (binary only) |
| Bubble | conditional | no meta-regression with continuous moderator | Effect vs. continuous covariate |
| Netgraph + SUCRA forest | conditional | not network mode | Network structure, treatment ranking |

**Drawing the funnel plot is separate from running Egger's test.** Draw the plot whenever k≥3 (it's a visualization, not a test); only run `metabias()` when k≥10 (Cochrane recommendation — Egger is underpowered below that).

## R Script Template (continuous outcome example)

```r
library(meta)
library(metafor)

dat <- read.csv("data/<input>.csv", stringsAsFactors = FALSE)

m <- metacont(
  n.e = n_t, mean.e = mean_t, sd.e = sd_t,
  n.c = n_c, mean.c = mean_c, sd.c = sd_c,
  studlab = paste(study, year),
  data = dat,
  sm = "SMD",          # or "MD" if all same scale
  method.smd = "Hedges",
  random = TRUE, common = FALSE,
  method.tau = "REML",
  hakn = TRUE          # Hartung-Knapp adjustment, better CI with few studies
)

sink("data/summary.txt"); print(summary(m)); sink()

# 1. Main forest
# Width must be ≥2000 when leftcols carries all 7 columns + the effect-size
# panel — narrower canvas crops x-axis labels on the right.
# Pass xlim explicitly so the axis labels (e.g. -3, -2, -1, 0, 1, 2) fit
# inside the panel rather than against the edge.
png("plots/forest.png", width = 2000, height = 80 + 55 * nrow(dat) + 150, res = 150)
forest(m, leftcols = c("studlab","n.e","mean.e","sd.e","n.c","mean.c","sd.c"),
       label.e = "Intervention", label.c = "Control", prediction = TRUE,
       xlim = c(-3, 2))
dev.off()

# 2. Funnel (always draw if k>=3; contour-enhanced)
if (nrow(dat) >= 3) {
  png("plots/funnel.png", width = 1000, height = 1000, res = 150)
  funnel(m, studlab = TRUE, contour = c(0.9, 0.95, 0.99),
         col.contour = c("grey80","grey60","grey40"))
  legend("topright",
         legend = c("p>0.1","0.05<p<0.1","p<0.05"),
         fill = c("grey80","grey60","grey40"), bty = "n", cex = 0.8)
  dev.off()
}
# Egger only if k>=10
if (nrow(dat) >= 10) {
  eg <- metabias(m, method.bias = "linreg")
  sink("data/egger.txt"); print(eg); sink()
} else {
  cat("Egger test skipped: k =", nrow(dat), "(<10, underpowered).\n",
      file = "data/notes.txt", append = TRUE)
}

# 3. Baujat — heterogeneity contribution vs. influence
png("plots/baujat.png", width = 1100, height = 1000, res = 150)
baujat(m, studlab = TRUE)
dev.off()

# 4. Radial (Galbraith)
png("plots/radial.png", width = 1100, height = 1000, res = 150)
radial(m)
dev.off()

# 5. Drapery — CI curves
png("plots/drapery.png", width = 1200, height = 900, res = 150)
drapery(m, type = "pval", legend = FALSE)
dev.off()

# 6. Leave-one-out sensitivity
# Width must be ≥2200 — metainf forest adds SMD/95%-CI/P-value/Tau2/Tau/I²
# columns on the right, narrower canvas truncates the I² column.
# Do NOT pass smlab — it renders at the same y-position as the SMD column
# header and collides into "omittSMD" garbage. metainf uses its own default
# title "Leave-One-Out Meta-Analysis" which sits above the panel cleanly.
inf <- metainf(m, pooled = "random")
sink("data/leave_one_out.txt"); print(inf); sink()
png("plots/forest_loo.png", width = 2300, height = 80 + 55 * nrow(dat) + 150, res = 150)
forest(inf)
dev.off()

# 7. Subgroup forest (if applicable)
# Height must account for: header rows + per-study rows + per-subgroup
# overhead (subgroup label + subtotal + heterogeneity line) + overall
# summary + subgroup-differences test row. Undersizing crops the plot.
if ("subgroup" %in% names(dat) && length(unique(dat$subgroup)) >= 2) {
  ms <- update(m, subgroup = subgroup)
  n_sub <- length(unique(dat$subgroup))
  h_sub <- 150 + 55 * nrow(dat) + 110 * n_sub + 250
  png("plots/forest_subgroup.png",
      width = 1700, height = h_sub, res = 150)
  forest(ms, prediction = FALSE)
  dev.off()
  sink("data/subgroup.txt"); print(summary(ms)); sink()
}

# L'Abbé: binary outcomes only — use labbe(m) inside the metabin branch
# Bubble: requires metareg() with a continuous moderator — use bubble(metareg(m, ~mod))
```

For **binary** outcomes (`metabin(...)`): add a L'Abbé plot — `png("plots/labbe.png", ...); labbe(m, studlab = TRUE); dev.off()`. Use `sm = "RR"` or `"OR"`, `method = "MH"`, `MH.exact = TRUE`.

For **meta-regression** (if a continuous moderator column is present, e.g. `mean_age`, `intervention_weeks`): run `mr <- metareg(m, ~mean_age)`, then `png("plots/bubble.png", ...); bubble(mr, studlab = TRUE); dev.off()`. Save `print(mr)` to `data/metareg.txt`.

For **netmeta**: use `pairwise()` to convert long format then `netmeta(..., sm = "SMD", reference.group = "control")`. Bundle should include `netgraph()` (network structure), `forest()` (treatment effects vs. reference), `forest(netrank(n), sortvar = -P.score)` (SUCRA ranking), and a `netheat()` heatmap for inconsistency.

## Report Structure (report.md)

Always three sections, in this order:

### 1. Statistical interpretation

- Pooled effect, 95% CI, prediction interval if available
- Heterogeneity: τ², I², Cochran's Q + p-value — interpret using Higgins thresholds (25/50/75%) but call out that I² depends on study size
- Number of studies, total participants
- Publication bias: Egger result if ≥10 studies; if <10, say so and don't speculate
- Subgroup difference test result if subgroups present

### 2. Clinical interpretation

- Translate the effect size into clinical language for the specific population
- For SMD: convert back to the original scale using a representative study's SD; compare to MCID if known (e.g. 6MWT MCID ≈ 30m for older adults, BBS MCID ≈ 4 points)
- Comment on whether the CI crosses the MCID — "statistically significant but clinically uncertain" is a common honest finding
- Mention relevant moderators (age, intervention dose, baseline severity) only if subgroup/meta-regression supports it; otherwise stay descriptive

### 3. Writing suggestions

Two short draft paragraphs (~150 words each) the user can paste and edit:
- **Results paragraph**: study count, participants, pooled effect with CI, heterogeneity, subgroup/sensitivity findings. PRISMA-style.
- **Discussion paragraph**: clinical meaning, comparison to prior reviews if the user mentions any, limitations (heterogeneity sources, risk-of-bias from CASP, small-study effects), implications for exercise prescription.

End with a one-line caveat: "Drafts above are starting points — verify all numbers against `data/summary.txt` and adapt the framing to your assessment brief."

## Output Folder Layout

```
~/Desktop/meta-analysis/<topic>/
├── analysis.R
├── analysis.log
├── report.md
├── data/
│   ├── <input>.csv         (copy of user's input)
│   ├── summary.txt
│   ├── leave_one_out.txt
│   ├── egger.txt           (if k≥10)
│   ├── subgroup.txt        (if subgroups)
│   ├── metareg.txt         (if meta-regression)
│   └── notes.txt           (any skips/caveats)
└── plots/
    ├── forest.png
    ├── funnel.png          (k≥3)
    ├── baujat.png          (k≥3)
    ├── radial.png          (k≥3)
    ├── drapery.png         (k≥3)
    ├── forest_loo.png      (k≥3)
    ├── forest_subgroup.png (if subgroups)
    ├── labbe.png           (binary only)
    ├── bubble.png          (meta-regression only)
    ├── netgraph.png        (network mode only)
    └── netrank_forest.png  (network mode only)
```

## When to refuse / push back

- User asks for a meta-analysis with 1 study → refuse, suggest narrative synthesis instead
- User asks to "estimate the missing SDs" → push back; offer SD-from-SE / SD-from-CI / SD-from-IQR formulas (Cochrane Handbook 6.5.2) and ask which the source paper actually reports
- User asks to combine clearly heterogeneous outcomes (e.g. 6MWT seconds with gait speed m/s) without standardization → push back, recommend SMD or splitting into separate analyses
- Network has disconnected components → run pairwise on the connected piece, tell the user which arms are disconnected
