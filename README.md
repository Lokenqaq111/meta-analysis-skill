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

---

# 中文版

## meta-analysis-r

一个用于在 R 中跑配对（pairwise）和网状（network）Meta 分析的 [Claude Code](https://claude.com/claude-code) 技能。面向康复 / 运动科学方向的工作流——前提是你已经从原始研究里提取好数据并整理成 CSV。

给定一个填好的模板 CSV，这个技能会：校验数据 → 生成一份独立可复跑的 `analysis.R` 脚本 → 执行它，然后产出：

- 一整套图（forest、funnel、Baujat、radial、drapery、leave-one-out、subgroup、L'Abbé、bubble、netgraph + SUCRA —— 会根据数据本身判断哪些图有意义、哪些跳过）
- 一份 Markdown 报告，包含**统计学解读**、**临床意义解读**，以及**可以直接拿去改的 Results / Discussion 段落草稿**

## 运行要求

- R ≥ 4.0
- R 包：`meta`、`metafor`、`netmeta`

```r
install.packages(c("meta", "metafor", "netmeta"))
```

- [Claude Code](https://claude.com/claude-code) 命令行

## 安装

克隆到你的 Claude skills 目录：

```bash
git clone https://github.com/<your-username>/meta-analysis-skill.git \
  ~/.claude/skills/meta-analysis-r
```

然后在任意 Claude Code 会话中：

```
/meta-analysis-r
```

（Claude 会读取 `SKILL.md` 并带你走完整个流程。）

## 两种输入模式

| 模式 | 适用场景 |
|---|---|
| 模板 CSV | 你已经把数据提取好了——直接填写 `templates/{binary,continuous,generic,network}_template.csv` |
| 从 CASP 文件夹开始 | 你已经跑过 [pubmed-search-casp](https://github.com/anthropics/skills) 并得到了 `included/` 文件夹——技能会根据文件名预先填好 `study` 列 |

技能**不会自己编造数值数据**。如果某格是空的，它会直接停下来问你，而不是随便补一个估计值。

## 输出结构

所有产物都会落在 `~/Desktop/meta-analysis/<topic>/`：

```
├── analysis.R          # 独立的、可以重新跑的脚本
├── analysis.log
├── report.md           # 统计 + 临床 + 段落草稿
├── data/               # summary.txt、leave_one_out.txt 等
└── plots/              # forest.png、funnel.png、baujat.png ……
```

## 默认配置

- **随机效应模型（REML）** —— 康复数据异质性高，固定效应会误导结论
- 不同量表的连续型结局用 **Hedges' g (SMD)**；量表一致时用 **MD**
- **Hartung-Knapp** 置信区间校正（研究数较少时覆盖率更好）
- **Egger's test** 仅在 k ≥ 10 时启用（Cochrane 推荐）

任意默认值都可以直接用自然语言告诉 Claude 来覆盖。

## 版本说明

参见 [CHANGELOG.md](CHANGELOG.md)。当前标签为 `v1` —— 工作流已经稳定到可以直接使用；后续主要是增量更新（更多图类型、更多结局类型），而不是破坏性改动。

## 许可证

MIT —— 详见 [LICENSE](LICENSE)。
