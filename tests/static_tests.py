#!/usr/bin/env python3
"""Branch-C checks for invariants that do not require an R runtime."""

from __future__ import annotations

import csv
import math
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RESULTS: list[tuple[str, str, str]] = []


def check(name: str, condition: bool, detail: str) -> None:
    RESULTS.append((name, "PASS" if condition else "FAIL", detail))


def blocked(name: str, detail: str) -> None:
    RESULTS.append((name, "BLOCKED", detail))


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def python_auto_xlim(values: list[float], include_null: bool = True) -> tuple[float, float]:
    finite = [value for value in values if math.isfinite(value)]
    if include_null:
        finite.append(0.0)
    lower, upper = min(finite), max(finite)
    span = upper - lower
    if span <= 0:
        span = max(max(abs(value) for value in finite), 1.0) * 0.20
    return lower - span * 0.10, upper + span * 0.10


def balanced_r_delimiters(text: str) -> bool:
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[str] = []
    quote: str | None = None
    escaped = False
    comment = False
    for char in text:
        if comment:
            if char == "\n":
                comment = False
            continue
        if quote is not None:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            continue
        if char == "#":
            comment = True
        elif char in ('"', "'", "`"):
            quote = char
        elif char in "([{":
            stack.append(char)
        elif char in ")]}":
            if not stack or stack.pop() != pairs[char]:
                return False
    return not stack and quote is None


def main() -> int:
    required_files = [
        "SKILL.md", "README.md", "CHANGELOG.md", "ENV_REPORT.md",
        "scripts/common.R",
        "scripts/validate.R",
        "scripts/run_analysis.R",
        "scripts/pairwise_continuous.R",
        "scripts/pairwise_binary.R",
        "scripts/pairwise_generic.R",
        "scripts/pairwise_prevalence.R",
        "scripts/nma.R",
        "scripts/write_report.R",
        "templates/continuous_empty.csv",
        "examples/continuous_smd/input.csv",
        "examples/continuous_md/input.csv",
        "examples/binary_rr/input.csv",
        "examples/prevalence_toy/input.csv",
        "examples/nma_toy/input.csv",
        "templates/prevalence_empty.csv",
        "references/jbi-prevalence-rob.md",
        "references/data-dictionary.md",
        "references/methods-defaults.md",
        "references/prevalence.md",
        "references/nma-limits.md",
        "references/report-spec.md",
        "references/egger-and-bias.md",
        "tests/test_validate.R",
        "tests/test_study_count.R",
        "tests/test_direction.R",
        "tests/test_xlim.R",
        "tests/test_k_gates.R",
        "tests/test_prevalence.R",
        "tests/test_nma_api.R",
        "tests/test_meta_api.R",
        "tests/test_no_invented_defaults.R",
    ]
    missing = [path for path in required_files if not (ROOT / path).exists()]
    check("cycle1_structure", not missing, "Missing: " + ", ".join(missing) if missing else "Core V2 files exist.")

    empty_rows = read_csv(ROOT / "templates/continuous_empty.csv")
    check("empty_template_header_only", empty_rows == [], "continuous_empty.csv has no data rows.")

    headers = next(csv.reader((ROOT / "templates/continuous_empty.csv").open(encoding="utf-8")))
    required_headers = {
        "study", "year", "mean_t", "sd_t", "n_t", "mean_c", "sd_c", "n_c",
        "outcome", "scale", "unit", "timepoint", "higher_is_better",
        "change_or_final", "study_design", "effect_id", "subgroup",
    }
    check("continuous_schema", required_headers.issubset(headers), "Expanded continuous schema is present.")

    blank_row = {column: "value" for column in headers}
    blank_row["sd_t"] = ""
    required_numeric = ("year", "mean_t", "sd_t", "n_t", "mean_c", "sd_c", "n_c")
    has_blank = any(not blank_row[column].strip() for column in required_numeric)
    check("empty_cell_stops", has_blank, "Blank required numeric cell is detected before analysis.")

    studies = ["A", "A", "B", "B", "C", "C"]
    check("unique_study_count", len(set(studies)) == 3 and len(studies) == 6,
          "Six rows are counted as three independent studies.")

    effects = [4.0, 3.0]
    directions = [True, False]
    aligned = [effect if direction else -effect for effect, direction in zip(effects, directions)]
    check("direction_flip", aligned == [4.0, -3.0], "Opposite direction changes effect sign only.")

    md_limits = python_auto_xlim([20.0, 35.0, 50.0, 10.0, 62.0])
    check("md_xlim", md_limits[0] <= 10.0 and md_limits[1] >= 62.0 and md_limits[1] > 50.0,
          f"Calculated limits {md_limits} cover MD estimates and CIs.")

    common_text = (ROOT / "scripts/common.R").read_text(encoding="utf-8")
    continuous_text = (ROOT / "scripts/pairwise_continuous.R").read_text(encoding="utf-8")
    combined = common_text + continuous_text
    check("no_fixed_xlim", "c(-3, 2)" not in combined and "auto_xlim(" in combined,
          "No fixed SMD-scale xlim remains in the engine.")
    check("no_deprecated_hakn", "hakn = TRUE" not in combined and "method.random.ci" in continuous_text,
          "The engine uses method.random.ci and does not call hakn=TRUE.")
    check("k_gates_in_code", "run_standard_diagnostics(" in continuous_text
          and "if (k_studies < 3L)" in common_text
          and "small_study_test = 10L" in common_text,
          "Central diagnostic gates use independent-study count at k=3/10.")
    check("egger_routing", all(token in common_text for token in ('MD =', 'OR =', 'RR =', 'SMD =')),
          "Small-study test selection is routed by effect measure.")

    md_rows = read_csv(ROOT / "examples/continuous_md/input.csv")
    observed_mds = [float(row["mean_t"]) - float(row["mean_c"]) for row in md_rows]
    check("md_example_scale", min(observed_mds) >= 20 and max(observed_mds) <= 50,
          f"MD example differences are {observed_mds} metres.")

    prevalence_header = next(csv.reader((ROOT / "templates/prevalence_empty.csv").open(encoding="utf-8")))
    prevalence_required = {
        "study", "year", "events", "total", "profession", "body_region",
        "recall_period", "country", "setting", "risk_of_bias", "subgroup",
    }
    check("prevalence_schema", prevalence_required.issubset(prevalence_header)
          and not {"event_t", "event_c", "n_t", "n_c"}.intersection(prevalence_header),
          "Prevalence is an independent single-proportion schema.")
    prevalence_rows = read_csv(ROOT / "examples/prevalence_toy/input.csv")
    boundary_ok = any(int(row["events"]) == 0 for row in prevalence_rows) and any(
        int(row["events"]) == int(row["total"]) for row in prevalence_rows
    )
    check("prevalence_boundary_fixture", boundary_ok,
          "Synthetic prevalence fixture contains 0% and 100% studies.")

    nma_text = (ROOT / "scripts/nma.R").read_text(encoding="utf-8")
    check("nma_api_static", "forest(netrank" not in nma_text
          and 'ranking_method = "P-score"' in nma_text
          and 'ranking_slug <- if (ranking_method == "SUCRA") "sucra" else "pscore"' in nma_text,
          "NMA uses a netmeta forest path and exact dynamic P-score/SUCRA file naming.")
    check("nma_limits_static", "netsplit" in nma_text and "netheat" in nma_text
          and "Disconnected treatments excluded" in nma_text,
          "NMA requests connectivity restriction, netheat, and netsplit when available.")

    multiarm_rows = read_csv(ROOT / "tests/fixtures/multiarm_shared_control.csv")
    first_study = [row for row in multiarm_rows if row["study"] == "MultiArmA"]
    control_signatures = {(row["mean_c"], row["sd_c"], row["n_c"]) for row in first_study}
    validator_text = (ROOT / "scripts/validate.R").read_text(encoding="utf-8")
    check("multiarm_shared_control", len(first_study) == 2 and len(control_signatures) == 1
          and "multi-arm/shared-control" in validator_text,
          "Shared-control fixture is detected and validator contains an explicit stop.")

    report_text = (ROOT / "scripts/write_report.R").read_text(encoding="utf-8")
    check("manual_certainty_only", "no automatic scoring" in report_text
          and "JBI prevalence risk of bias" in report_text,
          "JBI/GRADE sections are manual placeholders.")
    check("configurable_outdir", 'file.path("output", args$topic)' in (ROOT / "scripts/run_analysis.R").read_text(encoding="utf-8"),
          "CLI defaults to configurable ./output/<topic>.")

    instruction_text = "\n".join(
        (ROOT / path).read_text(encoding="utf-8") for path in ("SKILL.md", "README.md")
    )
    no_mcid_defaults = "6MWT MCID" not in instruction_text and "BBS MCID" not in instruction_text
    check("no_hardcoded_mcid_in_instructions", no_mcid_defaults,
          "No universal MCID examples remain in SKILL.md/README.md." if no_mcid_defaults
          else "V1 universal MCID examples still need removal from instructions.")

    skill_text = (ROOT / "SKILL.md").read_text(encoding="utf-8")
    readme_text = (ROOT / "README.md").read_text(encoding="utf-8")
    changelog_text = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    check("lean_skill_router", "metacont(" not in skill_text and "scripts/run_analysis.R" in skill_text
          and "references/data-dictionary.md" in skill_text,
          "SKILL.md routes to repository scripts/references and embeds no full model template.")
    clone_url = "https://github.com/Lokenqaq111/meta-analysis-skill.git"
    check("installation_docs", readme_text.count(clone_url) >= 3
          and "~/.claude/skills/meta-analysis-r" in readme_text
          and "~/.cursor/skills/meta-analysis-r" in readme_text
          and ".cursor/skills/meta-analysis-r" in readme_text,
          "README documents the real Claude and Cursor clone paths.")
    check("changelog_v2", "## v2" in changelog_text and "Automatic GRADE" in changelog_text
          and "prompt-driven prototype" in changelog_text,
          "CHANGELOG records V2 scope, exclusions, and corrected V1 maturity wording.")
    combined_docs = skill_text + readme_text
    check("nonabsolute_model_wording", "fixed-effect is misleading" not in combined_docs
          and "固定效应会误导" not in combined_docs,
          "Random effects are documented as a configurable default, not a discipline law.")
    check("no_fixed_desktop_path", "~/Desktop" not in combined_docs,
          "No fixed Desktop output path remains.")

    r_files = sorted((ROOT / "scripts").glob("*.R")) + sorted((ROOT / "tests").glob("*.R"))
    unbalanced = [str(path.relative_to(ROOT)) for path in r_files
                  if not balanced_r_delimiters(path.read_text(encoding="utf-8"))]
    check("r_delimiter_sanity", not unbalanced,
          "Balanced R delimiters in all scripts/tests." if not unbalanced
          else "Unbalanced delimiters: " + ", ".join(unbalanced))
    all_r_text = "\n".join(path.read_text(encoding="utf-8") for path in r_files)
    check("no_silent_install_call", "install.packages(" not in all_r_text,
          "No executable R script calls install.packages().")
    run_text = (ROOT / "scripts/run_analysis.R").read_text(encoding="utf-8")
    check("reproducible_output_contract", all(token in run_text for token in (
        '"analysis.log"', '"run_parameters.txt"', '"rerun.sh"', '"sessionInfo.txt"',
    )) and "write_report(" in run_text,
          "CLI records log, parameters, rerun script, session info, and report.")
    validate_text = (ROOT / "scripts/validate.R").read_text(encoding="utf-8")
    check("validation_cli", "if (sys.nframe() == 0L)" in validate_text
          and 'quit(status = if (validation$ok) 0L else 2L)' in validate_text,
          "validate.R exposes a standalone nonzero-exit CLI.")
    example_files = sorted((ROOT / "examples").glob("*/input.csv"))
    non_example_ids = []
    for path in example_files:
        for row in read_csv(path):
            if not row["study"].startswith("Example"):
                non_example_ids.append(f"{path.parent.name}:{row['study']}")
    check("synthetic_example_labels", not non_example_ids,
          "Every gold-standard fixture uses an Example* study ID." if not non_example_ids
          else "Non-Example IDs: " + ", ".join(non_example_ids))

    if shutil.which("Rscript") is None:
        for name in (
            "continuous_smd_runtime", "continuous_md_runtime", "binary_rr_runtime",
            "diagnostic_plot_runtime", "prevalence_runtime", "nma_runtime",
            "meta_api_runtime", "netmeta_api_runtime",
        ):
            blocked(name, "Rscript is unavailable (environment branch C).")

    log_lines = [
        "# Test Log",
        "",
        "Environment branch: C (Python/shell fallback; R-dependent tests are BLOCKED).",
        "",
        "| Test | Status | Key output |",
        "|---|---|---|",
    ]
    for name, status, detail in RESULTS:
        log_lines.append(f"| `{name}` | {status} | {detail.replace('|', '/')} |")
    (ROOT / "TEST_LOG.md").write_text("\n".join(log_lines) + "\n", encoding="utf-8")
    return 1 if any(status == "FAIL" for _, status, _ in RESULTS) else 0


if __name__ == "__main__":
    raise SystemExit(main())
