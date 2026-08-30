run_pairwise_binary <- function(dat, measure, outdir, model_type = "random") {
  if (!requireNamespace("meta", quietly = TRUE)) {
    stop("Package `meta` is required. It was not installed automatically.", call. = FALSE)
  }
  measure <- toupper(measure)
  if (!measure %in% c("RR", "OR")) stop("Binary measure must be RR or OR.", call. = FALSE)
  k_studies <- study_count(dat)
  notes <- character()
  metabin_formals <- names(formals(meta::metabin))
  if (!"method.random.ci" %in% metabin_formals) {
    stop("Installed `meta::metabin()` lacks `method.random.ci`; review the installed package API.", call. = FALSE)
  }
  call_args <- list(
    event.e = dat$event_t, n.e = dat$n_t, event.c = dat$event_c, n.c = dat$n_c,
    studlab = paste(dat$study, dat$year), data = dat, sm = measure, method = "MH",
    common = identical(model_type, "common"), random = identical(model_type, "random"),
    method.tau = "REML", method.random.ci = "HK",
    prediction = identical(model_type, "random")
  )
  if ("MH.exact" %in% metabin_formals) call_args$MH.exact <- TRUE
  model <- do.call(meta::metabin, call_args)
  metrics <- model_metrics(model, model_type, ratio_measure = TRUE)
  prediction <- c(metrics$prediction_lower, metrics$prediction_upper)
  x_limits <- auto_xlim(metrics$effect, metrics$lower, metrics$upper, prediction,
                        ratio_measure = TRUE, already_backtransformed = TRUE)

  writeLines(capture.output(summary(model)), file.path(outdir, "data", "summary.txt"))
  write.csv(dat, file.path(outdir, "data", "analysis_data.csv"), row.names = FALSE)
  writeLines(paste(format(x_limits, scientific = FALSE), collapse = ","),
             file.path(outdir, "data", "forest_xlim.txt"))
  main_plot <- safe_png(
    file.path(outdir, "plots", "forest.png"),
    function() meta::forest(model, prediction = identical(model_type, "random"), xlim = x_limits,
                            label.e = "Intervention", label.c = "Control"),
    width = 1900, height = 550 + 75 * nrow(dat)
  )
  if (!main_plot$ok) stop("Forest plot failed: ", main_plot$error, call. = FALSE)

  labbe_result <- safe_png(file.path(outdir, "plots", "labbe.png"),
                           function() meta::labbe(model, studlab = TRUE))
  if (!labbe_result$ok) notes <- c(notes, paste("L'Abbe plot failed:", labbe_result$error))
  notes <- c(notes, run_standard_diagnostics(model, measure, outdir, k_studies, model_type, nrow(dat)))
  subgroup <- run_subgroup_outputs(model, dat, outdir, "subgroup")
  notes <- c(notes, subgroup$notes)

  zero_rows <- dat$event_t == 0 | dat$event_c == 0 | dat$event_t == dat$n_t | dat$event_c == dat$n_c
  if (any(zero_rows)) {
    notes <- c(notes, "Zero/all-event arms were detected. Exact Mantel-Haenszel pooling was requested when supported; double-zero studies may not inform RR/OR.")
  }
  if (k_studies == 2L || (is.finite(metrics$tau2) && metrics$tau2 == 0)) {
    notes <- c(notes, "Hartung-Knapp and prediction intervals may be unstable when k=2 or tau^2=0; interpret cautiously.")
  }

  list(
    mode = "binary", measure = measure, model_type = model_type, model = model,
    metrics = metrics, k_studies = k_studies, n_rows = nrow(dat),
    n_effects = effect_count(dat), total_n = sum(dat$n_t + dat$n_c),
    xlim = x_limits, notes = unique(notes), subgroup_outputs = subgroup$completed
  )
}

