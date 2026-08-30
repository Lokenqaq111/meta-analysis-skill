largest_connected_component <- function(dat, components) {
  if (length(components) <= 1L) return(list(data = dat, kept = components[[1]], dropped = character()))
  kept <- components[[which.max(lengths(components))]]
  dropped <- setdiff(unique(dat$treatment), kept)
  list(data = dat[dat$treatment %in% kept, , drop = FALSE], kept = kept, dropped = dropped)
}

run_nma <- function(dat, measure, outdir, model_type = "random", reference = NULL,
                    ranking_method = "P-score", target_higher_is_better = NULL,
                    components = NULL) {
  if (!requireNamespace("netmeta", quietly = TRUE) || !requireNamespace("meta", quietly = TRUE)) {
    stop("Packages `netmeta` and `meta` are required. They were not installed automatically.", call. = FALSE)
  }
  measure <- toupper(measure)
  notes <- character()
  if (is.null(components)) components <- network_components(dat)
  restricted <- largest_connected_component(dat, components)
  dat <- restricted$data
  if (length(restricted$dropped)) {
    notes <- c(notes, paste("Disconnected treatments excluded from the analysed component:",
                            paste(restricted$dropped, collapse = ", ")))
  }
  if (study_count(dat) < 3L) stop("The largest connected network component has fewer than three studies.", call. = FALSE)

  outcome_type <- unique(dat$network_outcome_type)
  if (length(outcome_type) != 1L) stop("Network outcome type is ambiguous.", call. = FALSE)
  if (outcome_type == "continuous") dat <- align_continuous_direction(dat, target_higher_is_better)
  treatments <- unique(trimws(as.character(dat$treatment)))
  if (is.null(reference)) reference <- if ("control" %in% treatments) "control" else sort(treatments)[[1]]
  if (!reference %in% treatments) stop("Reference treatment is not in the analysed component: ", reference, call. = FALSE)

  pairwise_args <- list(treat = dat$treatment, n = dat$n, studlab = dat$study, data = dat, sm = measure)
  if (outcome_type == "binary") {
    pairwise_args$event <- dat$event
  } else {
    pairwise_args$mean <- dat$mean
    pairwise_args$sd <- dat$sd
  }
  pairwise_ns <- if ("pairwise" %in% getNamespaceExports("meta")) {
    "meta"
  } else if ("pairwise" %in% getNamespaceExports("netmeta")) {
    "netmeta"
  } else {
    NA_character_
  }
  if (is.na(pairwise_ns)) {
    stop("Neither `meta::pairwise` nor `netmeta::pairwise` is available in the installed packages.", call. = FALSE)
  }
  pairwise_data <- do.call(getExportedValue(pairwise_ns, "pairwise"), pairwise_args)
  nma_args <- list(
    TE = pairwise_data$TE, seTE = pairwise_data$seTE,
    treat1 = pairwise_data$treat1, treat2 = pairwise_data$treat2,
    studlab = pairwise_data$studlab, data = pairwise_data,
    sm = measure, reference.group = reference,
    common = identical(model_type, "common"), random = identical(model_type, "random"),
    method.tau = "REML"
  )
  nma_formals <- names(formals(netmeta::netmeta))
  if ("method.random.ci" %in% nma_formals) {
    nma_help <- tryCatch(
      paste(capture.output(tools::Rd2txt(utils:::.getHelpFile(help("netmeta", package = "netmeta")))), collapse = "\n"),
      error = function(e) ""
    )
    if (grepl("\"HK\"", nma_help, fixed = TRUE) || grepl("method.random.ci = \"HK\"", nma_help, fixed = TRUE)) {
      nma_args$method.random.ci <- "HK"
    } else if (grepl("t-dist", nma_help, fixed = TRUE)) {
      nma_args$method.random.ci <- "t-dist"
      notes <- c(notes, "Installed netmeta does not accept method.random.ci='HK'; used 't-dist' for t-based random-effects CIs.")
    }
  }
  model <- do.call(netmeta::netmeta, nma_args)
  writeLines(capture.output(summary(model)), file.path(outdir, "data", "summary.txt"))
  write.csv(dat, file.path(outdir, "data", "analysis_data.csv"), row.names = FALSE)

  plot_specs <- list(
    netgraph = function() netmeta::netgraph(model),
    forest = function() meta::forest(model, ref = reference),
    netheat = function() netmeta::netheat(model)
  )
  for (plot_name in names(plot_specs)) {
    result <- safe_png(file.path(outdir, "plots", paste0(plot_name, ".png")), plot_specs[[plot_name]],
                       width = 1800, height = 1300)
    if (!result$ok) notes <- c(notes, sprintf("%s plot failed: %s", plot_name, result$error))
  }

  netsplit_status <- "not run"
  if (exists("netsplit", envir = asNamespace("netmeta"), inherits = FALSE)) {
    split_result <- tryCatch(netmeta::netsplit(model), error = function(e) e)
    if (inherits(split_result, "error")) {
      netsplit_status <- paste("failed:", conditionMessage(split_result))
      notes <- c(notes, paste("Local inconsistency assessment (netsplit) failed:", conditionMessage(split_result)))
    } else {
      netsplit_status <- "completed"
      writeLines(capture.output(print(split_result)), file.path(outdir, "data", "netsplit.txt"))
    }
  } else {
    netsplit_status <- "BLOCKED: installed netmeta has no netsplit export"
    notes <- c(notes, netsplit_status)
  }

  requested_ranking <- tolower(ranking_method)
  ranking_method <- if (requested_ranking %in% c("sucra")) "SUCRA" else "P-score"
  netrank_formals <- names(formals(netmeta::netrank))
  rank_args <- list(x = model)
  if ("method" %in% netrank_formals) {
    rank_args$method <- ranking_method
  } else if (ranking_method == "SUCRA") {
    stop("Installed `netrank()` does not expose a `method` argument; SUCRA was not run.", call. = FALSE)
  }
  ranking <- do.call(netmeta::netrank, rank_args)
  ranking_slug <- if (ranking_method == "SUCRA") "sucra" else "pscore"
  writeLines(capture.output(print(ranking)), file.path(outdir, "data", paste0("ranking_", ranking_slug, ".txt")))
  rank_column <- if (ranking_method == "SUCRA") "SUCRA" else "Pscore"
  rank_plot <- safe_png(
    file.path(outdir, "plots", paste0("ranking_", ranking_slug, "_forest.png")),
    function() meta::forest(model, ref = reference,
                            rightcols = c("effect", "ci", rank_column),
                            sortvar = paste0("-", rank_column)),
    width = 1900, height = 1200
  )
  if (!rank_plot$ok) notes <- c(notes, paste(ranking_method, "ranking forest failed:", rank_plot$error))
  notes <- c(notes,
             sprintf("Ranking metric: %s. Rankings do not replace relative-effect confidence intervals and are not decision-grade certainty statements.", ranking_method),
             "Network connectivity is a technical prerequisite only; transitivity and effect-modifier balance require manual assessment.")

  list(
    mode = "network", measure = measure, model_type = model_type, model = model,
    metrics = list(effect = NA_real_, lower = NA_real_, upper = NA_real_,
                   prediction_lower = NA_real_, prediction_upper = NA_real_,
                   tau2 = (model$tau %||% NA_real_)^2, i2 = model$I2 %||% NA_real_,
                   q = model$Q %||% NA_real_, q_p = model$pval.Q %||% NA_real_),
    k_studies = study_count(dat), n_rows = nrow(dat), n_effects = effect_count(dat),
    total_n = sum(dat$n), notes = unique(notes), reference = reference,
    ranking_method = ranking_method, kept_treatments = restricted$kept,
    dropped_treatments = restricted$dropped, netsplit_status = netsplit_status,
    outcome_type = outcome_type
  )
}

