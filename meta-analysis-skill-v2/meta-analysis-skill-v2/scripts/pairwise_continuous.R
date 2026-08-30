run_pairwise_continuous <- function(dat, measure, outdir, model_type = "random",
                                    target_higher_is_better = NULL) {
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package `meta` is required. It was not installed automatically.", call. = FALSE)
  }
  measure <- toupper(measure)
  if (!measure %in% c("SMD", "MD")) stop("Continuous measure must be SMD or MD.", call. = FALSE)
  dat <- align_continuous_direction(dat, target_higher_is_better)
  k_studies <- study_count(dat)
  notes <- character()

  metacont_formals <- names(formals(meta::metacont))
  if (!"method.random.ci" %in% metacont_formals) {
    stop("Installed `meta::metacont()` lacks `method.random.ci`; upgrade or review the package API before running V2.", call. = FALSE)
  }
  call_args <- list(
    n.e = dat$n_t, mean.e = dat$mean_t, sd.e = dat$sd_t,
    n.c = dat$n_c, mean.c = dat$mean_c, sd.c = dat$sd_c,
    studlab = paste(dat$study, dat$year), data = dat,
    sm = measure, method.smd = "Hedges",
    common = identical(model_type, "common"), random = identical(model_type, "random"),
    method.tau = "REML", method.random.ci = "HK",
    prediction = identical(model_type, "random")
  )
  model <- do.call(meta::metacont, call_args)
  metrics <- model_metrics(model, model_type, ratio_measure = FALSE)
  prediction <- c(metrics$prediction_lower, metrics$prediction_upper)
  x_limits <- auto_xlim(metrics$effect, metrics$lower, metrics$upper, prediction)

  writeLines(capture.output(summary(model)), file.path(outdir, "data", "summary.txt"))
  write.csv(dat, file.path(outdir, "data", "analysis_data.csv"), row.names = FALSE)
  writeLines(paste(format(x_limits, scientific = FALSE), collapse = ","),
             file.path(outdir, "data", "forest_xlim.txt"))

  main_plot <- safe_png(
    file.path(outdir, "plots", "forest.png"),
    function() meta::forest(model, prediction = identical(model_type, "random"), xlim = x_limits,
                            label.e = "Intervention", label.c = "Control"),
    width = 2000, height = 550 + 75 * nrow(dat)
  )
  if (!main_plot$ok) stop("Forest plot failed: ", main_plot$error, call. = FALSE)

  notes <- c(notes, run_standard_diagnostics(model, measure, outdir, k_studies, model_type, nrow(dat)))
  subgroup <- run_subgroup_outputs(model, dat, outdir, "subgroup")
  notes <- c(notes, subgroup$notes)

  if (k_studies == 2L || (is.finite(metrics$tau2) && metrics$tau2 == 0)) {
    notes <- c(notes,
               "Hartung-Knapp and prediction intervals may be unstable or unexpectedly wide/narrow when k=2 or tau^2=0; interpret cautiously.")
  }
  if (k_studies < 5L) {
    notes <- c(notes, "Prediction intervals are unstable with few studies and should not be treated as a precise forecast.")
  }

  list(
    mode = "continuous", measure = measure, model_type = model_type, model = model,
    metrics = metrics, k_studies = k_studies, n_rows = nrow(dat),
    n_effects = effect_count(dat), total_n = sum(dat$n_t + dat$n_c),
    xlim = x_limits, notes = unique(notes), direction_flips = sum(dat$direction_flipped),
    subgroup_outputs = subgroup$completed
  )
}
