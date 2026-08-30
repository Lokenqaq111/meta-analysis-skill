prevalence_metrics <- function(model, model_type = "random") {
  raw <- model_metrics(model, model_type, ratio_measure = FALSE)
  transform <- function(x) if (is.finite(x)) stats::plogis(x) else NA_real_
  raw$effect <- transform(raw$effect)
  raw$lower <- transform(raw$lower)
  raw$upper <- transform(raw$upper)
  raw$prediction_lower <- transform(raw$prediction_lower)
  raw$prediction_upper <- transform(raw$prediction_upper)
  raw
}

run_pairwise_prevalence <- function(dat, measure, outdir, model_type = "random") {
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package `meta` is required. It was not installed automatically.", call. = FALSE)
  }
  measure <- toupper(measure)
  if (!measure %in% c("PLOGIT")) {
    stop("V2 prevalence main analysis currently requires PLOGIT.", call. = FALSE)
  }
  k_studies <- study_count(dat)
  notes <- character()
  metaprop_formals <- names(formals(meta::metaprop))
  if (!"method.random.ci" %in% metaprop_formals) {
    stop("Installed `meta::metaprop()` lacks `method.random.ci`; review the installed package API.", call. = FALSE)
  }
  call_args <- list(
    event = dat$events, n = dat$total, studlab = paste(dat$study, dat$year), data = dat,
    sm = "PLOGIT", common = identical(model_type, "common"),
    random = identical(model_type, "random"), method.tau = "REML",
    method.random.ci = "HK", prediction = identical(model_type, "random")
  )
  # Current meta defaults PLOGIT to GLMM, which only accepts method.tau = "ML".
  # The documented V2 main analysis is inverse-variance PLOGIT + REML + HK.
  if ("method" %in% metaprop_formals) call_args$method <- "Inverse"
  if ("incr" %in% metaprop_formals) call_args$incr <- 0.5
  if ("method.incr" %in% metaprop_formals) call_args$method.incr <- "only0"
  model <- do.call(meta::metaprop, call_args)
  metrics <- prevalence_metrics(model, model_type)
  raw_limits <- auto_xlim(metrics$effect, metrics$lower, metrics$upper,
                          c(metrics$prediction_lower, metrics$prediction_upper), include_null = TRUE)
  x_limits <- c(max(0, raw_limits[[1]]), min(1, raw_limits[[2]]))

  writeLines(capture.output(summary(model)), file.path(outdir, "data", "summary.txt"))
  write.csv(dat, file.path(outdir, "data", "analysis_data.csv"), row.names = FALSE)
  writeLines(paste(format(x_limits, scientific = FALSE), collapse = ","),
             file.path(outdir, "data", "forest_xlim.txt"))
  main_plot <- safe_png(
    file.path(outdir, "plots", "forest.png"),
    function() meta::forest(model, prediction = identical(model_type, "random"), xlim = x_limits,
                            xlab = "Prevalence"),
    width = 1900, height = 550 + 75 * nrow(dat)
  )
  if (!main_plot$ok) stop("Prevalence forest plot failed: ", main_plot$error, call. = FALSE)

  sensitivity_args <- call_args
  sensitivity_args$sm <- "PFT"
  sensitivity <- tryCatch(do.call(meta::metaprop, sensitivity_args), error = function(e) e)
  sensitivity_status <- "PASS"
  if (inherits(sensitivity, "error")) {
    sensitivity_status <- "BLOCKED"
    notes <- c(notes, paste("BLOCKED: Freeman-Tukey sensitivity analysis failed:", conditionMessage(sensitivity)))
  } else {
    writeLines(capture.output(summary(sensitivity)), file.path(outdir, "data", "sensitivity_pft.txt"))
    notes <- c(notes, "Sensitivity analysis used the Freeman-Tukey transformation (PFT); it is secondary to the prespecified PLOGIT main analysis.")
  }

  zero_or_all <- dat$events == 0 | dat$events == dat$total
  if (any(zero_or_all)) {
    notes <- c(notes,
               "Zero/100% prevalence studies were retained. The PLOGIT inverse-variance analysis requested a 0.5 continuity correction only for boundary studies; the PFT sensitivity analysis used its package-defined handling.")
  }
  notes <- c(notes, run_standard_diagnostics(model, "PLOGIT", outdir, k_studies, model_type, nrow(dat)))
  subgroup <- run_subgroup_outputs(
    model, dat, outdir,
    c("body_region", "country", "profession", "recall_period", "setting"),
    prefix = "prevalence_subgroup"
  )
  notes <- c(notes, subgroup$notes)
  if (k_studies < 5L) notes <- c(notes, "The prevalence prediction interval is unstable with few studies.")
  if (k_studies == 2L || (is.finite(metrics$tau2) && metrics$tau2 == 0)) {
    notes <- c(notes, "Hartung-Knapp uncertainty can be unstable when k=2 or tau^2=0; interpret cautiously.")
  }

  list(
    mode = "prevalence", measure = "PLOGIT", model_type = model_type, model = model,
    metrics = metrics, k_studies = k_studies, n_rows = nrow(dat),
    n_effects = effect_count(dat), total_n = sum(dat$total), xlim = x_limits,
    notes = unique(notes), subgroup_outputs = subgroup$completed,
    sensitivity_status = sensitivity_status
  )
}

