run_pairwise_generic <- function(dat, measure, outdir, model_type = "random",
                                 target_higher_is_better = NULL) {
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package `meta` is required. It was not installed automatically.", call. = FALSE)
  }
  measure <- toupper(measure)
  if (measure %in% c("SMD", "MD")) dat <- align_continuous_direction(dat, target_higher_is_better)
  k_studies <- study_count(dat)
  metagen_formals <- names(formals(meta::metagen))
  if (!"method.random.ci" %in% metagen_formals) {
    stop("Installed `meta::metagen()` lacks `method.random.ci`; review the installed package API.", call. = FALSE)
  }
  model <- do.call(meta::metagen, list(
    TE = dat$TE, seTE = dat$seTE, studlab = paste(dat$study, dat$year), data = dat,
    sm = measure, common = identical(model_type, "common"), random = identical(model_type, "random"),
    method.tau = "REML", method.random.ci = "HK", prediction = identical(model_type, "random")
  ))
  ratio_measure <- measure %in% c("RR", "OR", "HR")
  metrics <- model_metrics(model, model_type, ratio_measure)
  x_limits <- auto_xlim(metrics$effect, metrics$lower, metrics$upper,
                        c(metrics$prediction_lower, metrics$prediction_upper),
                        ratio_measure = ratio_measure, already_backtransformed = TRUE)

  writeLines(capture.output(summary(model)), file.path(outdir, "data", "summary.txt"))
  write.csv(dat, file.path(outdir, "data", "analysis_data.csv"), row.names = FALSE)
  writeLines(paste(format(x_limits, scientific = FALSE), collapse = ","),
             file.path(outdir, "data", "forest_xlim.txt"))
  main_plot <- safe_png(file.path(outdir, "plots", "forest.png"),
                        function() meta::forest(model, prediction = identical(model_type, "random"), xlim = x_limits),
                        width = 1800, height = 550 + 75 * nrow(dat))
  if (!main_plot$ok) stop("Forest plot failed: ", main_plot$error, call. = FALSE)
  notes <- run_standard_diagnostics(model, measure, outdir, k_studies, model_type, nrow(dat))
  subgroup <- run_subgroup_outputs(model, dat, outdir, "subgroup")
  notes <- c(notes, subgroup$notes)
  if (anyDuplicated(dat$study)) notes <- c(notes, "Multiple pre-calculated effects from the same study were treated as separate rows; dependence was not modelled.")
  if (k_studies == 2L || (is.finite(metrics$tau2) && metrics$tau2 == 0)) {
    notes <- c(notes, "Hartung-Knapp and prediction intervals may be unstable when k=2 or tau^2=0; interpret cautiously.")
  }
  list(
    mode = "generic", measure = measure, model_type = model_type, model = model,
    metrics = metrics, k_studies = k_studies, n_rows = nrow(dat),
    n_effects = effect_count(dat), total_n = NA_real_, xlim = x_limits,
    notes = unique(notes), subgroup_outputs = subgroup$completed
  )
}

