`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || all(is.na(x))) y else x
}

is_blank <- function(x) {
  is.na(x) | !nzchar(trimws(as.character(x)))
}

parse_bool <- function(x, field = "value") {
  if (is.logical(x)) return(x)
  value <- tolower(trimws(as.character(x)))
  out <- rep(NA, length(value))
  out[value %in% c("true", "t", "1", "yes", "y")] <- TRUE
  out[value %in% c("false", "f", "0", "no", "n")] <- FALSE
  if (anyNA(out)) {
    stop(sprintf("%s must contain only true/false values.", field), call. = FALSE)
  }
  out
}

study_count <- function(dat) {
  length(unique(trimws(as.character(dat$study[!is_blank(dat$study)]))))
}

effect_count <- function(dat) {
  if ("effect_id" %in% names(dat) && any(!is_blank(dat$effect_id))) {
    length(unique(trimws(as.character(dat$effect_id[!is_blank(dat$effect_id)]))))
  } else {
    nrow(dat)
  }
}

nonblank_levels <- function(x) {
  unique(trimws(as.character(x[!is_blank(x)])))
}

append_notes <- function(path, notes) {
  notes <- unique(notes[nzchar(trimws(notes))])
  if (!length(notes)) return(invisible(path))
  write(notes, file = path, append = file.exists(path))
  invisible(path)
}

align_continuous_direction <- function(dat, target_higher_is_better = NULL) {
  directions <- parse_bool(dat$higher_is_better, "higher_is_better")
  if (is.null(target_higher_is_better)) {
    if (length(unique(directions)) > 1L) {
      stop(
        "Outcome directions differ. Supply --target-higher-is-better true|false; direction will not be guessed.",
        call. = FALSE
      )
    }
    dat$direction_flipped <- FALSE
    return(dat)
  }

  target <- parse_bool(target_higher_is_better, "target_higher_is_better")[[1]]
  flip <- directions != target
  if (any(flip)) {
    if (all(c("mean_t", "mean_c") %in% names(dat))) {
      dat$mean_t[flip] <- -dat$mean_t[flip]
      dat$mean_c[flip] <- -dat$mean_c[flip]
    } else if ("TE" %in% names(dat)) {
      dat$TE[flip] <- -dat$TE[flip]
    } else if ("mean" %in% names(dat)) {
      dat$mean[flip] <- -dat$mean[flip]
    } else {
      stop("No supported mean/effect column is available for direction alignment.", call. = FALSE)
    }
  }
  dat$higher_is_better <- rep(target, nrow(dat))
  dat$direction_flipped <- flip
  dat
}

auto_xlim <- function(effect, lower, upper, prediction = numeric(), include_null = TRUE,
                      ratio_measure = FALSE, already_backtransformed = FALSE,
                      margin_fraction = 0.10) {
  values <- c(effect, lower, upper, prediction)
  values <- values[is.finite(values)]
  if (!length(values)) stop("Cannot calculate x limits without finite estimates.", call. = FALSE)

  if (ratio_measure && !already_backtransformed) values <- exp(values)
  null_value <- if (ratio_measure) 1 else 0
  if (include_null) values <- c(values, null_value)

  lower_limit <- min(values)
  upper_limit <- max(values)
  span <- upper_limit - lower_limit
  if (!is.finite(span) || span <= 0) {
    span <- max(abs(values), 1) * 0.20
  }
  margin <- span * margin_fraction
  limits <- c(lower_limit - margin, upper_limit + margin)
  if (ratio_measure) limits[[1]] <- max(limits[[1]], .Machine$double.eps)
  limits
}

should_run_diagnostic <- function(name, k_studies) {
  thresholds <- c(funnel = 3L, baujat = 3L, radial = 3L, drapery = 3L,
                  leave_one_out = 3L, small_study_test = 10L)
  if (!name %in% names(thresholds)) stop("Unknown diagnostic: ", name, call. = FALSE)
  k_studies >= thresholds[[name]]
}

small_study_bias_plan <- function(measure, k_studies, se_values = NULL) {
  measure <- toupper(measure)
  if (!should_run_diagnostic("small_study_test", k_studies)) {
    return(list(run = FALSE, method = NA_character_, label = "Small-study-effects test",
                reason = sprintf("Skipped: k_studies=%d (<10).", k_studies)))
  }
  if (!is.null(se_values)) {
    se_values <- se_values[is.finite(se_values) & se_values > 0]
    if (length(se_values) >= 2L) {
      relative_range <- diff(range(se_values)) / mean(se_values)
      if (is.finite(relative_range) && relative_range < 0.05) {
        return(list(run = FALSE, method = NA_character_, label = "Small-study-effects test",
                    reason = "Skipped: study precision is nearly identical, so an asymmetry regression is not informative."))
      }
    }
  }

  plan <- switch(
    measure,
    MD = list(run = TRUE, method = "linreg", label = "Egger regression", reason = ""),
    OR = list(run = TRUE, method = "score", label = "Harbord score test", reason = ""),
    RR = list(run = TRUE, method = "linreg", label = "Egger regression for log risk ratio", reason = ""),
    SMD = list(run = FALSE, method = NA_character_, label = "Small-study-effects test",
               reason = "Skipped: the ordinary Egger regression can be artefactually correlated for SMD. Use a prespecified SMD-appropriate method."),
    list(run = FALSE, method = NA_character_, label = "Small-study-effects test",
         reason = sprintf("Skipped: no automatic method is configured for %s.", measure))
  )
  plan
}

run_standard_diagnostics <- function(model, measure, outdir, k_studies, model_type,
                                     n_rows) {
  notes <- character()
  if (k_studies < 3L) {
    notes <- c(notes,
               sprintf("k_studies=%d: funnel, Baujat, radial, drapery, and leave-one-out diagnostics were skipped.", k_studies))
  } else {
    plot_specs <- list(
      funnel = function() meta::funnel(model, studlab = TRUE, contour = c(0.90, 0.95, 0.99)),
      baujat = function() meta::baujat(model, studlab = TRUE),
      radial = function() meta::radial(model),
      drapery = function() meta::drapery(model, type = "pval", legend = FALSE)
    )
    for (plot_name in names(plot_specs)) {
      result <- safe_png(file.path(outdir, "plots", paste0(plot_name, ".png")), plot_specs[[plot_name]])
      if (!result$ok) notes <- c(notes, sprintf("%s plot failed: %s", plot_name, result$error))
    }
    influence <- tryCatch(meta::metainf(model, pooled = model_type), error = function(e) e)
    if (inherits(influence, "error")) {
      notes <- c(notes, paste("Leave-one-out analysis failed:", conditionMessage(influence)))
    } else {
      writeLines(capture.output(print(influence)), file.path(outdir, "data", "leave_one_out.txt"))
      result <- safe_png(file.path(outdir, "plots", "forest_leave_one_out.png"),
                         function() meta::forest(influence), width = 2200,
                         height = 550 + 75 * n_rows)
      if (!result$ok) notes <- c(notes, paste("Leave-one-out forest failed:", result$error))
    }
  }

  bias_plan <- small_study_bias_plan(measure, k_studies, model$seTE)
  if (bias_plan$run) {
    bias_result <- tryCatch(meta::metabias(model, method.bias = bias_plan$method), error = function(e) e)
    if (inherits(bias_result, "error")) {
      notes <- c(notes, paste(bias_plan$label, "failed:", conditionMessage(bias_result)))
    } else {
      writeLines(capture.output(print(bias_result)), file.path(outdir, "data", "small_study_effects.txt"))
      notes <- c(notes, sprintf("%s was run with method.bias=%s.", bias_plan$label, bias_plan$method))
    }
  } else {
    notes <- c(notes, bias_plan$reason)
  }
  unique(notes)
}

run_subgroup_outputs <- function(model, dat, outdir, columns, prefix = "subgroup") {
  notes <- character()
  completed <- character()
  for (column in intersect(columns, names(dat))) {
    values <- trimws(as.character(dat[[column]]))
    keep <- !is_blank(values)
    if (length(unique(values[keep])) < 2L) next
    subgroup_model <- tryCatch(
      stats::update(model, subgroup = values),
      error = function(e) e
    )
    if (inherits(subgroup_model, "error")) {
      notes <- c(notes, sprintf("Subgroup `%s` failed: %s", column, conditionMessage(subgroup_model)))
      next
    }
    safe_name <- gsub("[^A-Za-z0-9_-]", "_", column)
    writeLines(capture.output(summary(subgroup_model)),
               file.path(outdir, "data", paste0(prefix, "_", safe_name, ".txt")))
    plot_result <- safe_png(
      file.path(outdir, "plots", paste0(prefix, "_", safe_name, ".png")),
      function() meta::forest(subgroup_model, prediction = FALSE),
      width = 1900, height = 650 + 85 * nrow(dat)
    )
    if (!plot_result$ok) notes <- c(notes, sprintf("Subgroup `%s` plot failed: %s", column, plot_result$error))
    completed <- c(completed, column)
  }
  list(completed = completed, notes = notes)
}

safe_png <- function(path, plot_function, width = 1600, height = 1100, res = 150) {
  grDevices::png(path, width = width, height = height, res = res)
  result <- tryCatch({
    plot_function()
    list(ok = TRUE, error = NULL)
  }, error = function(e) list(ok = FALSE, error = conditionMessage(e)))
  try(grDevices::dev.off(), silent = TRUE)
  if (!result$ok && file.exists(path)) unlink(path)
  result
}

model_metrics <- function(model, model_type = "random", ratio_measure = FALSE) {
  suffix <- if (identical(model_type, "common")) "common" else "random"
  effect <- model[[paste0("TE.", suffix)]]
  lower <- model[[paste0("lower.", suffix)]]
  upper <- model[[paste0("upper.", suffix)]]
  if (ratio_measure) {
    effect <- exp(effect)
    lower <- exp(lower)
    upper <- exp(upper)
  }
  prediction <- c(model$lower.predict %||% NA_real_, model$upper.predict %||% NA_real_)
  prediction <- prediction[is.finite(prediction)]
  if (ratio_measure && length(prediction)) prediction <- exp(prediction)
  list(
    effect = unname(effect[[1]]),
    lower = unname(lower[[1]]),
    upper = unname(upper[[1]]),
    prediction_lower = if (length(prediction)) min(prediction) else NA_real_,
    prediction_upper = if (length(prediction)) max(prediction) else NA_real_,
    tau2 = unname((model$tau2 %||% NA_real_)[[1]]),
    i2 = unname((model$I2 %||% NA_real_)[[1]]),
    q = unname((model$Q %||% NA_real_)[[1]]),
    q_p = unname((model$pval.Q %||% NA_real_)[[1]])
  )
}

format_number <- function(x, digits = 3L) {
  if (!length(x) || is.na(x) || !is.finite(x)) return("not available")
  formatC(x, digits = digits, format = "fg", flag = "#")
}

format_count <- function(x) {
  if (!length(x) || is.na(x) || !is.finite(x)) return("not available")
  format(round(x), scientific = FALSE, trim = TRUE)
}
