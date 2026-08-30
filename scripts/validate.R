read_meta_csv <- function(path) {
  if (!file.exists(path)) stop("Input file does not exist: ", path, call. = FALSE)
  tryCatch(
    utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
                    na.strings = c("NA", "NaN"), strip.white = TRUE),
    error = function(e) stop("Could not read CSV: ", conditionMessage(e), call. = FALSE)
  )
}

apply_row_selection <- function(dat, outcome = NULL, timepoint = NULL) {
  if (!is.null(outcome)) dat <- dat[trimws(as.character(dat$outcome)) == outcome, , drop = FALSE]
  if (!is.null(timepoint)) dat <- dat[trimws(as.character(dat$timepoint)) == timepoint, , drop = FALSE]
  dat
}

network_components <- function(dat) {
  treatments <- unique(trimws(as.character(dat$treatment)))
  adjacency <- setNames(lapply(treatments, function(x) character()), treatments)
  for (study_id in unique(dat$study)) {
    arms <- unique(trimws(as.character(dat$treatment[dat$study == study_id])))
    if (length(arms) < 2L) next
    pairs <- utils::combn(arms, 2L)
    for (column in seq_len(ncol(pairs))) {
      a <- pairs[1L, column]
      b <- pairs[2L, column]
      adjacency[[a]] <- unique(c(adjacency[[a]], b))
      adjacency[[b]] <- unique(c(adjacency[[b]], a))
    }
  }
  visited <- character()
  components <- list()
  for (start in treatments) {
    if (start %in% visited) next
    queue <- start
    component <- character()
    while (length(queue)) {
      node <- queue[[1]]
      queue <- queue[-1]
      if (node %in% visited) next
      visited <- c(visited, node)
      component <- c(component, node)
      queue <- unique(c(queue, adjacency[[node]]))
    }
    components[[length(components) + 1L]] <- component
  }
  components
}

validate_data <- function(dat, mode, measure, target_higher_is_better = NULL,
                          selected_outcome = NULL, selected_timepoint = NULL) {
  mode <- tolower(mode)
  measure <- toupper(measure)
  errors <- character()
  warnings <- character()
  add_error <- function(message) errors <<- c(errors, message)
  add_warning <- function(message) warnings <<- c(warnings, message)

  if (!nrow(dat)) add_error("The CSV has no data rows.")
  common_required <- c("study")
  missing_common <- setdiff(common_required, names(dat))
  if (length(missing_common)) add_error(paste("Missing required columns:", paste(missing_common, collapse = ", ")))
  if (length(errors)) {
    return(list(ok = FALSE, errors = errors, warnings = warnings, data = dat,
                k_studies = 0L, n_rows = nrow(dat), n_effects = 0L))
  }

  dat <- apply_row_selection(dat, selected_outcome, selected_timepoint)
  if (!nrow(dat)) add_error("No rows remain after applying outcome/timepoint selection.")

  required_by_mode <- list(
    continuous = c("study", "year", "mean_t", "sd_t", "n_t", "mean_c", "sd_c", "n_c",
                   "outcome", "scale", "unit", "timepoint", "higher_is_better",
                   "change_or_final", "study_design", "effect_id", "subgroup"),
    binary = c("study", "year", "event_t", "n_t", "event_c", "n_c", "outcome",
               "timepoint", "event_is_beneficial", "study_design", "effect_id", "subgroup"),
    generic = c("study", "year", "TE", "seTE", "outcome", "scale", "unit", "timepoint",
                "higher_is_better", "change_or_final", "study_design", "effect_id", "subgroup"),
    prevalence = c("study", "year", "events", "total", "profession", "body_region",
                   "recall_period", "country", "setting", "risk_of_bias", "subgroup"),
    network = c("study", "treatment", "n", "outcome", "timepoint", "study_design", "effect_id")
  )
  if (!mode %in% names(required_by_mode)) add_error(paste("Unsupported mode:", mode))
  if (length(errors)) {
    return(list(ok = FALSE, errors = errors, warnings = warnings, data = dat,
                k_studies = study_count(dat), n_rows = nrow(dat), n_effects = effect_count(dat)))
  }

  missing_columns <- setdiff(required_by_mode[[mode]], names(dat))
  if (length(missing_columns)) add_error(paste("Missing required columns:", paste(missing_columns, collapse = ", ")))
  if (length(errors)) {
    return(list(ok = FALSE, errors = errors, warnings = warnings, data = dat,
                k_studies = study_count(dat), n_rows = nrow(dat), n_effects = effect_count(dat)))
  }

  required_nonblank <- setdiff(required_by_mode[[mode]], c("subgroup", "risk_of_bias"))
  for (column in required_nonblank) {
    if (any(is_blank(dat[[column]]))) add_error(sprintf("Required column `%s` contains an empty cell.", column))
  }

  numeric_columns <- switch(
    mode,
    continuous = c("year", "mean_t", "sd_t", "n_t", "mean_c", "sd_c", "n_c"),
    binary = c("year", "event_t", "n_t", "event_c", "n_c"),
    generic = c("year", "TE", "seTE"),
    prevalence = c("year", "events", "total"),
    network = c("n")
  )
  for (column in numeric_columns) {
    converted <- suppressWarnings(as.numeric(dat[[column]]))
    if (anyNA(converted)) add_error(sprintf("Required numeric column `%s` contains missing or non-numeric data.", column))
    dat[[column]] <- converted
  }

  if (mode == "network") {
    has_binary <- "event" %in% names(dat) && any(!is_blank(dat$event))
    has_continuous <- all(c("mean", "sd") %in% names(dat)) && any(!is_blank(dat$mean) | !is_blank(dat$sd))
    if (has_binary && has_continuous) add_error("Network CSV mixes binary and continuous arm data.")
    if (!has_binary && !has_continuous) add_error("Network CSV must provide either `event` or both `mean` and `sd`.")
    if (has_binary) {
      dat$event <- suppressWarnings(as.numeric(dat$event))
      if (anyNA(dat$event)) add_error("Network `event` contains missing or non-numeric data.")
      if (any(dat$event < 0 | dat$event > dat$n, na.rm = TRUE)) add_error("Network event counts must satisfy 0 <= event <= n.")
      dat$network_outcome_type <- "binary"
    }
    if (has_continuous) {
      dat$mean <- suppressWarnings(as.numeric(dat$mean))
      dat$sd <- suppressWarnings(as.numeric(dat$sd))
      if (anyNA(dat$mean) || anyNA(dat$sd)) add_error("Network mean/sd contains missing or non-numeric data.")
      if (any(dat$sd <= 0, na.rm = TRUE)) add_error("Network SD values must be > 0.")
      if (!"higher_is_better" %in% names(dat) || any(is_blank(dat$higher_is_better))) {
        add_error("Continuous network data requires complete `higher_is_better` values.")
      } else {
        directions <- tryCatch(parse_bool(dat$higher_is_better, "higher_is_better"), error = function(e) {
          add_error(conditionMessage(e)); rep(NA, nrow(dat))
        })
        if (length(unique(directions[!is.na(directions)])) > 1L && is.null(target_higher_is_better)) {
          add_error("Continuous network outcome directions differ; provide --target-higher-is-better.")
        }
        if (measure == "MD" && (length(nonblank_levels(dat$unit)) > 1L || length(nonblank_levels(dat$scale)) > 1L)) {
          add_error("Network MD requires comparable scales and units.")
        }
      }
      dat$network_outcome_type <- "continuous"
    }
    if (any(dat$n <= 0, na.rm = TRUE)) add_error("Network n values must be > 0.")
  }

  if (mode == "continuous") {
    if (any(dat$n_t <= 0 | dat$n_c <= 0, na.rm = TRUE)) add_error("Continuous sample sizes must be > 0.")
    if (any(dat$sd_t <= 0 | dat$sd_c <= 0, na.rm = TRUE)) add_error("Continuous SD values must be > 0.")
    directions <- tryCatch(parse_bool(dat$higher_is_better, "higher_is_better"), error = function(e) {
      add_error(conditionMessage(e)); rep(NA, nrow(dat))
    })
    if (length(unique(directions[!is.na(directions)])) > 1L && is.null(target_higher_is_better)) {
      add_error("Outcome directions differ; provide --target-higher-is-better. The validator will not guess a direction.")
    }
    if (measure == "MD") {
      if (length(nonblank_levels(dat$unit)) > 1L || length(nonblank_levels(dat$scale)) > 1L) {
        add_error("MD requires comparable scales and units; multiple scale/unit values were found.")
      }
    }
    if (measure == "SMD" && length(nonblank_levels(dat$change_or_final)) > 1L) {
      add_warning("SMD data mix change scores and final values; this can reflect different reliability and requires a prespecified decision.")
    }
  }

  if (mode == "binary") {
    if (any(dat$n_t <= 0 | dat$n_c <= 0, na.rm = TRUE)) add_error("Binary sample sizes must be > 0.")
    if (any(dat$event_t < 0 | dat$event_c < 0 | dat$event_t > dat$n_t | dat$event_c > dat$n_c, na.rm = TRUE)) {
      add_error("Binary event counts must satisfy 0 <= event <= n in each arm.")
    }
  }

  if (mode == "generic") {
    if (any(dat$seTE <= 0, na.rm = TRUE)) add_error("Generic seTE values must be > 0.")
    directions <- tryCatch(parse_bool(dat$higher_is_better, "higher_is_better"), error = function(e) {
      add_error(conditionMessage(e)); rep(NA, nrow(dat))
    })
    if (length(unique(directions[!is.na(directions)])) > 1L && is.null(target_higher_is_better)) {
      add_error("Generic effect directions differ; provide --target-higher-is-better.")
    }
    if (measure == "MD" && (length(nonblank_levels(dat$unit)) > 1L || length(nonblank_levels(dat$scale)) > 1L)) {
      add_error("Generic MD requires comparable scales and units.")
    }
    if (measure == "SMD" && length(nonblank_levels(dat$change_or_final)) > 1L) {
      add_warning("Generic SMD data mix change scores and final values; verify that the supplied effects are comparable.")
    }
  }

  if (mode == "prevalence") {
    if (any(dat$total <= 0, na.rm = TRUE)) add_error("Prevalence total values must be > 0.")
    if (any(dat$events < 0 | dat$events > dat$total, na.rm = TRUE)) {
      add_error("Prevalence values must satisfy 0 <= events <= total.")
    }
  }

  if (any(grepl("^Example", trimws(as.character(dat$study))))) {
    add_warning("Example* demonstration rows are present. Confirm that toy data are intentional before interpreting results.")
  }

  if ("study_design" %in% names(dat)) {
    unsupported_design <- grepl("cluster|crossover|cross-over", dat$study_design, ignore.case = TRUE)
    if (any(unsupported_design, na.rm = TRUE)) {
      add_error("Cluster/crossover studies were detected. V2 does not estimate the required correlation or design correction.")
    }
  }

  duplicate_study <- duplicated(trimws(as.character(dat$study))) | duplicated(trimws(as.character(dat$study)), fromLast = TRUE)
  if (any(duplicate_study) && mode %in% c("continuous", "binary")) {
    control_columns <- intersect(c("mean_c", "sd_c", "n_c", "event_c"), names(dat))
    shared_control <- FALSE
    for (study_id in unique(dat$study[duplicate_study])) {
      rows <- dat[dat$study == study_id, , drop = FALSE]
      if (length(control_columns)) {
        signatures <- do.call(paste, c(rows[control_columns], sep = "|"))
        if (anyDuplicated(signatures)) shared_control <- TRUE
      }
    }
    if (shared_control) {
      add_error("A multi-arm/shared-control structure was detected. Combine intervention arms, split the control n with justification, or use network meta-analysis.")
    } else {
      add_error("The same study contributes multiple rows. Select one outcome/timepoint/effect or provide an explicitly adjusted pre-calculated effect.")
    }
  } else if (any(duplicate_study) && mode == "generic") {
    add_warning("The same study contributes multiple pre-calculated effects; k_studies uses unique study IDs, and effect dependence remains a limitation.")
  }

  k_studies <- study_count(dat)
  if (mode %in% c("continuous", "binary", "generic", "prevalence") && k_studies < 2L) {
    add_error("Meta-analysis requires at least two independent studies; one study should be synthesized narratively.")
  }
  components <- NULL
  if (mode == "network") {
    if (k_studies < 3L) add_error("Network meta-analysis requires at least three independent studies.")
    arm_counts <- table(dat$study)
    if (any(arm_counts < 2L)) add_error("Every network study must contain at least two treatment arms.")
    components <- network_components(dat)
    if (length(components) > 1L) {
      sizes <- lengths(components)
      kept <- components[[which.max(sizes)]]
      dropped <- setdiff(unlist(components, use.names = FALSE), kept)
      add_warning(sprintf(
        "Network is disconnected. Analysis must be restricted to the largest connected component; dropped treatments: %s.",
        paste(dropped, collapse = ", ")
      ))
    }
  }

  list(
    ok = !length(errors), errors = unique(errors), warnings = unique(warnings), data = dat,
    k_studies = k_studies, n_rows = nrow(dat), n_effects = effect_count(dat),
    network_components = components
  )
}

format_validation <- function(validation) {
  c(
    sprintf("status=%s", if (validation$ok) "PASS" else "FAIL"),
    sprintf("k_studies=%d", validation$k_studies),
    sprintf("n_rows=%d", validation$n_rows),
    sprintf("n_effects=%d", validation$n_effects),
    if (length(validation$errors)) paste0("ERROR: ", validation$errors),
    if (length(validation$warnings)) paste0("WARNING: ", validation$warnings)
  )
}

if (sys.nframe() == 0L) {
  cli_args <- commandArgs(trailingOnly = TRUE)
  parsed <- list()
  index <- 1L
  while (index <= length(cli_args)) {
    key <- sub("^--", "", cli_args[[index]])
    if (index == length(cli_args)) stop("Missing value for --", key, call. = FALSE)
    parsed[[key]] <- cli_args[[index + 1L]]
    index <- index + 2L
  }
  script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[[1]]) else "scripts/validate.R"
  source(file.path(dirname(normalizePath(script_path, mustWork = FALSE)), "common.R"))
  required <- c("input", "mode", "measure")
  missing <- required[!vapply(required, function(key) !is.null(parsed[[key]]), logical(1))]
  if (length(missing)) stop("Missing CLI arguments: ", paste(missing, collapse = ", "), call. = FALSE)
  validation <- validate_data(
    read_meta_csv(parsed$input), parsed$mode, parsed$measure,
    target_higher_is_better = parsed$`target-higher-is-better`,
    selected_outcome = parsed$outcome, selected_timepoint = parsed$timepoint
  )
  writeLines(format_validation(validation))
  quit(status = if (validation$ok) 0L else 2L)
}
