#!/usr/bin/env Rscript

parse_cli <- function(args) {
  result <- list()
  index <- 1L
  while (index <= length(args)) {
    token <- args[[index]]
    if (!startsWith(token, "--")) stop("Unexpected CLI token: ", token, call. = FALSE)
    key <- sub("^--", "", token)
    if (index == length(args) || startsWith(args[[index + 1L]], "--")) {
      result[[key]] <- TRUE
      index <- index + 1L
    } else {
      result[[key]] <- args[[index + 1L]]
      index <- index + 2L
    }
  }
  result
}

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[[1]]) else "scripts/run_analysis.R"
script_dir <- dirname(normalizePath(script_path, mustWork = FALSE))
options(meta.analysis.skill_root = dirname(script_dir))
source(file.path(script_dir, "common.R"))
source(file.path(script_dir, "validate.R"))
source(file.path(script_dir, "pairwise_continuous.R"))
source(file.path(script_dir, "pairwise_binary.R"))
source(file.path(script_dir, "pairwise_generic.R"))
source(file.path(script_dir, "pairwise_prevalence.R"))
source(file.path(script_dir, "nma.R"))
source(file.path(script_dir, "write_report.R"))

args <- parse_cli(commandArgs(trailingOnly = TRUE))
if (isTRUE(args$help)) {
  writeLines(c(
    "Usage:",
    "Rscript scripts/run_analysis.R --input path.csv --mode continuous|binary|generic|network|prevalence",
    "  --measure SMD|MD|RR|OR|PLOGIT --outdir output/topic --topic topic",
    "Optional: --model random|common --target-higher-is-better true|false --outcome name --timepoint value",
    "          --population text --mcid-source citation --reference treatment --ranking P-score|SUCRA"
  ))
  quit(status = 0L)
}

required_args <- c("input", "mode", "measure", "topic")
missing_args <- required_args[!vapply(required_args, function(key) !is.null(args[[key]]), logical(1))]
if (length(missing_args)) stop("Missing CLI arguments: ", paste(missing_args, collapse = ", "), call. = FALSE)

outdir <- args$outdir %||% file.path("output", args$topic)
dir.create(file.path(outdir, "data"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(outdir, "plots"), recursive = TRUE, showWarnings = FALSE)
log_path <- file.path(outdir, "analysis.log")
log_connection <- file(log_path, open = "wt")
sink(log_connection, type = "output", split = TRUE)
sink(log_connection, type = "message")
on.exit({
  try(sink(type = "message"), silent = TRUE)
  try(sink(type = "output"), silent = TRUE)
  try(close(log_connection), silent = TRUE)
}, add = TRUE)

status <- tryCatch({
  message("meta-analysis-r V2 run started at ", format(Sys.time(), tz = "UTC", usetz = TRUE))
  dat <- read_meta_csv(args$input)
  validation <- validate_data(
    dat, args$mode, args$measure,
    target_higher_is_better = args$`target-higher-is-better`,
    selected_outcome = args$outcome,
    selected_timepoint = args$timepoint
  )
  writeLines(format_validation(validation), file.path(outdir, "data", "validation.txt"))
  append_notes(file.path(outdir, "data", "notes.txt"), validation$warnings)
  if (!validation$ok) {
    append_notes(file.path(outdir, "data", "notes.txt"), paste0("ERROR: ", validation$errors))
    stop(paste(validation$errors, collapse = " "), call. = FALSE)
  }

  file.copy(args$input, file.path(outdir, "data", "input.csv"), overwrite = TRUE)
  parameter_lines <- c(
    paste0("input=", normalizePath(args$input, mustWork = FALSE)),
    paste0("mode=", tolower(args$mode)), paste0("measure=", toupper(args$measure)),
    paste0("model=", args$model %||% "random"), paste0("topic=", args$topic),
    paste0("outdir=", normalizePath(outdir, mustWork = FALSE)),
    paste0("target_higher_is_better=", args$`target-higher-is-better` %||% "not supplied"),
    paste0("outcome=", args$outcome %||% "not supplied"),
    paste0("timepoint=", args$timepoint %||% "not supplied"),
    paste0("population=", args$population %||% "not supplied"),
    paste0("mcid_source=", args$`mcid-source` %||% "not supplied"),
    paste0("reference=", args$reference %||% "not supplied"),
    paste0("ranking=", args$ranking %||% "P-score")
  )
  writeLines(parameter_lines, file.path(outdir, "run_parameters.txt"))
  rerun_pairs <- list(
    input = normalizePath(args$input, mustWork = FALSE), mode = args$mode,
    measure = args$measure, outdir = normalizePath(outdir, mustWork = FALSE),
    topic = args$topic, model = args$model %||% "random",
    `target-higher-is-better` = args$`target-higher-is-better`, outcome = args$outcome,
    timepoint = args$timepoint, population = args$population, `mcid-source` = args$`mcid-source`,
    reference = args$reference, ranking = args$ranking
  )
  rerun_tokens <- c("Rscript", shQuote(normalizePath(script_path, mustWork = FALSE)))
  for (key in names(rerun_pairs)) {
    value <- rerun_pairs[[key]]
    if (is.null(value)) next
    rerun_tokens <- c(rerun_tokens, paste0("--", key), shQuote(as.character(value)))
  }
  rerun <- paste(rerun_tokens, collapse = " ")
  writeLines(c("#!/usr/bin/env bash", "set -euo pipefail", rerun), file.path(outdir, "rerun.sh"))
  Sys.chmod(file.path(outdir, "rerun.sh"), "0755")

  result <- switch(
    tolower(args$mode),
    continuous = run_pairwise_continuous(
      validation$data, args$measure, outdir, args$model %||% "random",
      args$`target-higher-is-better`
    ),
    binary = run_pairwise_binary(validation$data, args$measure, outdir, args$model %||% "random"),
    generic = run_pairwise_generic(
      validation$data, args$measure, outdir, args$model %||% "random",
      args$`target-higher-is-better`
    ),
    prevalence = run_pairwise_prevalence(validation$data, args$measure, outdir,
                                         args$model %||% "random"),
    network = run_nma(
      validation$data, args$measure, outdir, args$model %||% "random",
      reference = args$reference, ranking_method = args$ranking %||% "P-score",
      target_higher_is_better = args$`target-higher-is-better`,
      components = validation$network_components
    ),
    stop("Unsupported mode: ", args$mode, call. = FALSE)
  )
  append_notes(file.path(outdir, "data", "notes.txt"), result$notes)
  write_report(result, outdir, args$topic, validation$warnings,
               population = args$population, mcid_source = args$`mcid-source`)
  writeLines(capture.output(sessionInfo()), file.path(outdir, "data", "sessionInfo.txt"))
  message("Analysis completed successfully: ", normalizePath(outdir, mustWork = FALSE))
  0L
}, error = function(e) {
  message("ANALYSIS FAILED: ", conditionMessage(e))
  1L
})

sink(type = "message")
sink(type = "output")
close(log_connection)
quit(status = status)
