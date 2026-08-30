# meta-analysis-r V2

A Claude Code / Cursor skill backed by parameterized R scripts for aggregate-data meta-analysis. V2 validates an already extracted CSV, runs a repository-owned engine, saves reproducible parameters and logs, and writes plots plus a structured Markdown report.

Supported modes:

- pairwise continuous: MD or Hedges' g SMD;
- pairwise binary: RR or OR;
- generic pre-calculated effects;
- independent single-proportion prevalence mode;
- technical frequentist network meta-analysis.

This project does not search literature, extract numeric data from PDFs, generate PRISMA flow diagrams, or automatically score GRADE, CINeMA, JBI, or risk of bias.

## Requirements

- R 4.0 or later;
- R packages `meta`, `metafor`, and `netmeta`;
- Claude Code or Cursor when used as an agent skill.

Check the actual runtime before analysis:

```bash
scripts/check_env.sh
```

If packages are missing, review `ENV_REPORT.md` and obtain approval before running:

```r
install.packages(c("meta", "metafor", "netmeta"))
```

The skill never installs packages silently.

## Install

### Claude Code

```bash
git clone https://github.com/Lokenqaq111/meta-analysis-skill.git \
  ~/.claude/skills/meta-analysis-r
```

### Cursor — user scope

```bash
git clone https://github.com/Lokenqaq111/meta-analysis-skill.git \
  ~/.cursor/skills/meta-analysis-r
```

### Cursor — project scope

From the project root:

```bash
git clone https://github.com/Lokenqaq111/meta-analysis-skill.git \
  .cursor/skills/meta-analysis-r
```

## Quick start

Copy an empty template and fill every required field:

```bash
cp templates/continuous_empty.csv my_input.csv
```

Validate without running a model:

```bash
Rscript scripts/validate.R \
  --input my_input.csv \
  --mode continuous \
  --measure SMD
```

Run the analysis:

```bash
Rscript scripts/run_analysis.R \
  --input my_input.csv \
  --mode continuous \
  --measure SMD \
  --outdir output/my-topic \
  --topic my-topic
```

The default output path is `./output/<topic>/`; `--outdir` is configurable.

## Input modes

| Mode | Template | Notes |
|---|---|---|
| `continuous` | `templates/continuous_empty.csv` | Direction is explicit; MD requires comparable units |
| `binary` | `templates/binary_empty.csv` | Comparative intervention/control events |
| `generic` | `templates/generic_empty.csv` | Pre-calculated `TE` / `seTE` |
| `prevalence` | `templates/prevalence_empty.csv` | Single-group `events` / `total`; no control columns |
| `network` | `templates/network_empty.csv` | Binary or continuous arm-level data |

Files ending in `_template.csv` contain synthetic `Example*` rows. Empty templates contain headers only.

## Reproducible output

Each successful run writes:

```text
output/<topic>/
├── analysis.log
├── report.md
├── rerun.sh
├── run_parameters.txt
├── data/
│   ├── input.csv
│   ├── validation.txt
│   ├── analysis_data.csv
│   ├── summary.txt
│   ├── notes.txt              # when warnings/skips exist
│   └── sessionInfo.txt
└── plots/
    └── ...                    # mode- and k-gated figures
```

## Defaults and limits

- Random effects with REML is the intervention default because the usual target is an average effect; it is configurable and is not a discipline-wide law.
- The current non-deprecated Hartung-Knapp API is checked at runtime.
- Diagnostics use unique study count, not CSV row count.
- Small-study tests require at least ten studies and additional effect/precision checks.
- No universal MCID is embedded. Clinical thresholds require a user-supplied, population-appropriate source.
- NMA connectivity does not establish transitivity; V2 does not claim publication-grade NMA validity.

See `references/` for the data dictionary, method rules, prevalence behavior, NMA limits, bias-test routing, report contract, and manual JBI checklist.

## Tests

```bash
tests/run_all.sh
```

With R and all packages available, the R suite runs end-to-end examples. Without R, branch-C Python/shell checks run and package-dependent tests are reported as `BLOCKED` in `TEST_LOG.md`; they are never presented as passed.

## License

MIT — see [LICENSE](LICENSE).

---

# 中文说明

`meta-analysis-r V2` 是一个面向 Claude Code / Cursor 的 Meta 分析 Skill。与 V1 每次让模型重写整份 `analysis.R` 不同，V2 直接调用仓库内参数化 R 脚本：先校验 CSV，再运行分析，并保存日志、参数、复跑脚本、图和结构化报告。

支持连续型、二分类、预计算效应量、独立患病率和技术性网络 Meta 模式。患病率使用单组 `events/total` 模板，不能与治疗组/对照组的 binary 模板混用。

硬规则：不编造或从摘要猜数值；必填空格立即停止；不静默安装 R 包；一项独立研究拒绝做 Meta；风险偏倚、GRADE 和 JBI 只留人工填写栏，不自动打分。

安装路径：

```bash
# Claude Code
git clone https://github.com/Lokenqaq111/meta-analysis-skill.git ~/.claude/skills/meta-analysis-r

# Cursor 用户级
git clone https://github.com/Lokenqaq111/meta-analysis-skill.git ~/.cursor/skills/meta-analysis-r

# Cursor 项目级
git clone https://github.com/Lokenqaq111/meta-analysis-skill.git .cursor/skills/meta-analysis-r
```

正式运行前先执行 `scripts/check_env.sh`，再用 `tests/run_all.sh` 查看当前环境实际通过、失败或受阻的测试。没有 R 时必须保留 `V2_VERIFIED=NO`，不能宣称分析管线已经实测通过。
