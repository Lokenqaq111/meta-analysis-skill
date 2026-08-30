write_report <- function(result, outdir, topic, notes = character(), population = NULL,
                         mcid_source = NULL) {
  if (identical(result$mode, "prevalence")) {
    return(write_prevalence_report(result, outdir, topic, notes, population))
  }
  if (identical(result$mode, "network")) {
    return(write_nma_report(result, outdir, topic, notes, population, mcid_source))
  }
  metrics <- result$metrics
  all_notes <- unique(c(notes, result$notes))
  pi_text <- if (is.finite(metrics$prediction_lower) && is.finite(metrics$prediction_upper)) {
    sprintf("%s to %s", format_number(metrics$prediction_lower), format_number(metrics$prediction_upper))
  } else {
    "not available"
  }
  bias_note <- grep("test|Egger|Harbord|Peters|small-study", all_notes, value = TRUE, ignore.case = TRUE)
  if (!length(bias_note)) bias_note <- "See data/small_study_effects.txt if generated."

  clinical_text <- if (is.null(mcid_source) || !nzchar(trimws(mcid_source))) {
    "MCID not provided — no clinical threshold applied."
  } else {
    sprintf("Clinical interpretation must use the supplied MCID source: %s.", mcid_source)
  }
  population_text <- if (is.null(population) || !nzchar(trimws(population))) {
    "Population context was not provided; keep interpretation statistical rather than disease-specific."
  } else {
    paste("Population:", population)
  }

  lines <- c(
    paste0("# ", topic, " — Meta-analysis report"),
    "",
    "## Statistical interpretation",
    "",
    sprintf("- Mode: %s; measure: %s; model: %s.", result$mode, result$measure, result$model_type),
    sprintf("- Pooled estimate: %s (95%% CI %s to %s).",
            format_number(metrics$effect), format_number(metrics$lower), format_number(metrics$upper)),
    sprintf("- Prediction interval: %s.", pi_text),
    sprintf("- Heterogeneity: tau^2=%s; I^2=%s; Q=%s (p=%s).",
            format_number(metrics$tau2), format_number(metrics$i2),
            format_number(metrics$q), format_number(metrics$q_p)),
    sprintf("- k_studies=%d; effect rows=%d; effect IDs=%d; total N=%s.",
            result$k_studies, result$n_rows, result$n_effects, format_count(result$total_n)),
    paste0("- Small-study-effects assessment: ", paste(bias_note, collapse = " ")),
    sprintf("- Subgroup outputs generated for: %s.",
            if (length(result$subgroup_outputs)) paste(result$subgroup_outputs, collapse = ", ") else "none"),
    "",
    "## Clinical interpretation",
    "",
    paste0("- ", population_text),
    paste0("- ", clinical_text),
    "- Direction and magnitude should be interpreted against the named outcome, scale, timepoint, and population—not against a universal rehabilitation threshold.",
    "",
    "## Writing suggestions",
    "",
    "### Results draft",
    "",
    sprintf("The synthesis included %d independent studies (N=%s). The %s model produced a pooled %s of %s (95%% CI %s to %s), with I^2=%s. Sensitivity and small-study-effect outputs are reported in the data directory where applicable.",
            result$k_studies, format_count(result$total_n), result$model_type, result$measure,
            format_number(metrics$effect), format_number(metrics$lower),
            format_number(metrics$upper), format_number(metrics$i2)),
    "",
    "### Discussion draft",
    "",
    paste("The pooled estimate should be interpreted as", if (result$model_type == "random") "an average effect across the included settings." else "a common-effect estimate under its stated assumptions.", clinical_text, "Review the notes below before drawing conclusions."),
    "",
    "Drafts above are starting points — verify all numbers against `data/summary.txt` and adapt the framing to the protocol and assessment brief.",
    "",
    "## Methods caveats",
    "",
    "- Random effects with REML is the intervention-analysis default because the target is commonly an average effect; it is not a discipline-wide law. A common-effect model can be requested.",
    "- Random-effects models give relatively more weight to smaller studies than common-effect models.",
    "- Small-k, direction alignment, multi-arm structures, and change-versus-final decisions require explicit review.",
    if (length(all_notes)) paste0("- ", all_notes),
    "",
    "## Certainty placeholders",
    "",
    "### Risk of bias (manual entry)",
    "",
    "| Study | Tool/domain | Judgement | Source/notes |",
    "|---|---|---|---|",
    "|  | RoB 2 / applicable tool |  |  |",
    "",
    "### GRADE certainty (manual entry; no automatic scoring)",
    "",
    "| Outcome | Risk of bias | Inconsistency | Indirectness | Imprecision | Publication bias | Overall certainty |",
    "|---|---|---|---|---|---|---|",
    "|  |  |  |  |  |  |  |"
  )
  writeLines(lines, file.path(outdir, "report.md"), useBytes = TRUE)
  invisible(file.path(outdir, "report.md"))
}

write_prevalence_report <- function(result, outdir, topic, validation_notes = character(),
                                    population = NULL) {
  metrics <- result$metrics
  all_notes <- unique(c(validation_notes, result$notes))
  pi_text <- if (is.finite(metrics$prediction_lower) && is.finite(metrics$prediction_upper)) {
    sprintf("%s%% to %s%%", format_number(100 * metrics$prediction_lower),
            format_number(100 * metrics$prediction_upper))
  } else "not available"
  population_text <- if (is.null(population) || !nzchar(trimws(population))) {
    "Population context was not supplied; do not generalize beyond the sampled professions and settings."
  } else paste("Population:", population)
  skill_root <- getOption("meta.analysis.skill_root", getwd())
  jbi_path <- file.path(skill_root, "references", "jbi-prevalence-rob.md")
  jbi_lines <- if (file.exists(jbi_path)) readLines(jbi_path, warn = FALSE) else {
    c("JBI checklist file missing — complete the manual prevalence risk-of-bias assessment before use.")
  }
  jbi_table_start <- grep("^\\| Question", jbi_lines)
  jbi_table <- if (length(jbi_table_start)) jbi_lines[seq.int(jbi_table_start[[1]], length(jbi_lines))] else jbi_lines

  lines <- c(
    paste0("# ", topic, " — Prevalence meta-analysis report"),
    "",
    "## Statistical interpretation",
    "",
    sprintf("- Main analysis: %s prevalence meta-analysis using %s and REML where applicable.",
            result$model_type, result$measure),
    sprintf("- Pooled prevalence: %s%% (95%% CI %s%% to %s%%).",
            format_number(100 * metrics$effect), format_number(100 * metrics$lower),
            format_number(100 * metrics$upper)),
    sprintf("- Prediction interval: %s.", pi_text),
    sprintf("- Heterogeneity: tau^2=%s; I^2=%s; Q=%s (p=%s).",
            format_number(metrics$tau2), format_number(metrics$i2),
            format_number(metrics$q), format_number(metrics$q_p)),
    sprintf("- k_studies=%d; prevalence rows=%d; total sampled N=%s.",
            result$k_studies, result$n_rows, format_count(result$total_n)),
    sprintf("- Sensitivity analysis status: %s.", result$sensitivity_status),
    sprintf("- Subgroup outputs generated for: %s.",
            if (length(result$subgroup_outputs)) paste(result$subgroup_outputs, collapse = ", ") else "none"),
    "",
    "## Clinical interpretation",
    "",
    paste0("- ", population_text),
    "- MCID is not applicable to a pooled prevalence estimate; no clinical threshold was applied.",
    "- Interpret the estimate with the profession, body region, recall period, country, setting, and risk-of-bias distribution.",
    "",
    "## Writing suggestions",
    "",
    "### Results draft",
    "",
    sprintf("The prevalence synthesis included %d independent studies and %s sampled participants. The pooled prevalence was %s%% (95%% CI %s%% to %s%%). Heterogeneity and the prespecified sensitivity analysis are reported in the accompanying summary files.",
            result$k_studies, format_count(result$total_n), format_number(100 * metrics$effect),
            format_number(100 * metrics$lower), format_number(100 * metrics$upper)),
    "",
    "### Discussion draft",
    "",
    "The pooled prevalence is an average across the included sampling frames and should not be assumed to apply to a different profession, body region, recall period, or setting. Boundary-event handling, heterogeneity, subgroup structure, and manual risk-of-bias judgements should be considered before drawing conclusions.",
    "",
    "Drafts above are starting points — verify all numbers against `data/summary.txt` and adapt the framing to the protocol and assessment brief.",
    "",
    "## Methods caveats",
    "",
    "- The main PLOGIT analysis uses a documented boundary-study rule; sensitivity output is secondary and stored separately.",
    "- Random effects with REML targets an average prevalence; it is a default, not a discipline-wide law.",
    "- Prediction intervals and Hartung-Knapp uncertainty can be unstable with few studies.",
    if (length(all_notes)) paste0("- ", all_notes),
    "",
    "## Certainty placeholders",
    "",
    "### JBI prevalence risk of bias (manual entry; no automatic score)",
    "",
    jbi_table
  )
  writeLines(lines, file.path(outdir, "report.md"), useBytes = TRUE)
  invisible(file.path(outdir, "report.md"))
}

write_nma_report <- function(result, outdir, topic, validation_notes = character(),
                             population = NULL, mcid_source = NULL) {
  all_notes <- unique(c(validation_notes, result$notes))
  clinical_threshold <- if (is.null(mcid_source) || !nzchar(trimws(mcid_source))) {
    "MCID not provided — no clinical threshold applied."
  } else paste("Use only the supplied MCID source:", mcid_source)
  population_text <- if (is.null(population) || !nzchar(trimws(population))) {
    "Population context was not supplied."
  } else paste("Population:", population)
  lines <- c(
    paste0("# ", topic, " — Network meta-analysis report"),
    "",
    "## Statistical interpretation",
    "",
    sprintf("- Network outcome type: %s; measure: %s; model: %s.", result$outcome_type, result$measure, result$model_type),
    sprintf("- k_studies=%d; arm rows=%d; total arm-level N=%s.",
            result$k_studies, result$n_rows, format_count(result$total_n)),
    sprintf("- Reference treatment: %s.", result$reference),
    sprintf("- Analysed connected treatments: %s.", paste(result$kept_treatments, collapse = ", ")),
    sprintf("- Dropped disconnected treatments: %s.",
            if (length(result$dropped_treatments)) paste(result$dropped_treatments, collapse = ", ") else "none"),
    sprintf("- Local inconsistency assessment: %s.", result$netsplit_status),
    sprintf("- Ranking metric: %s. Ranking uncertainty must be interpreted alongside relative-effect confidence intervals.", result$ranking_method),
    "- Relative effects are stored in `data/summary.txt`; the report does not assert that indirect comparisons are valid.",
    "",
    "## Clinical interpretation",
    "",
    paste0("- ", population_text),
    paste0("- ", clinical_threshold),
    "- Treatment rankings are secondary summaries, not evidence-certainty ratings or clinical recommendations.",
    "",
    "## Writing suggestions",
    "",
    "### Results draft",
    "",
    sprintf("The connected network included %d studies and used %s as the reference treatment. Relative effects, network geometry, inconsistency outputs, and %s rankings are provided in the data and plots directories.",
            result$k_studies, result$reference, result$ranking_method),
    "",
    "### Discussion draft",
    "",
    "Network estimates require a plausible transitivity assumption and coherent direct and indirect evidence. Ranking summaries should be discussed only after examining effect modifiers, relative-effect uncertainty, inconsistency, and risk of bias.",
    "",
    "Drafts above are starting points — verify all numbers against `data/summary.txt` and adapt the framing to the protocol and assessment brief.",
    "",
    "## Methods caveats",
    "",
    "- Connectivity does not establish transitivity.",
    "- This V2 engine provides technical NMA outputs but does not claim publication-grade NMA validity.",
    if (length(all_notes)) paste0("- ", all_notes),
    "",
    "## Certainty placeholders",
    "",
    "### Risk of bias / GRADE (manual entry; no automatic scoring)",
    "",
    "| Comparison/outcome | Risk of bias | Inconsistency | Indirectness | Imprecision | Reporting bias | Certainty |",
    "|---|---|---|---|---|---|---|",
    "|  |  |  |  |  |  |  |",
    "",
    "### Transitivity and effect-modifier review (manual entry)",
    "",
    "| Effect modifier | Distribution by direct comparison | Concern | Source/notes |",
    "|---|---|---|---|",
    "|  |  |  |  |"
  )
  writeLines(lines, file.path(outdir, "report.md"), useBytes = TRUE)
  invisible(file.path(outdir, "report.md"))
}
