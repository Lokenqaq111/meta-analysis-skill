run_test <- function() {
  if (!requireNamespace("meta", quietly = TRUE)) {
    return(list(status = "BLOCKED", detail = "Package `meta` is not installed."))
  }
  source("scripts/common.R")
  source("scripts/validate.R")
  source("scripts/pairwise_continuous.R")
  source("scripts/pairwise_binary.R")
  outputs <- character()
  for (spec in list(
    list(path = "examples/continuous_smd/input.csv", mode = "continuous", measure = "SMD", lower = 0.20, upper = 0.75),
    list(path = "examples/continuous_md/input.csv", mode = "continuous", measure = "MD", lower = 20, upper = 50),
    list(path = "examples/binary_rr/input.csv", mode = "binary", measure = "RR", lower = 0.20, upper = 1.00)
  )) {
    dat <- utils::read.csv(spec$path, stringsAsFactors = FALSE)
    validation <- validate_data(dat, spec$mode, spec$measure)
    stopifnot(validation$ok)
    outdir <- tempfile(paste0(spec$mode, "-test-"))
    dir.create(file.path(outdir, "data"), recursive = TRUE)
    dir.create(file.path(outdir, "plots"), recursive = TRUE)
    result <- if (spec$mode == "continuous") {
      run_pairwise_continuous(validation$data, spec$measure, outdir)
    } else {
      run_pairwise_binary(validation$data, spec$measure, outdir)
    }
    stopifnot(file.exists(file.path(outdir, "plots", "forest.png")))
    stopifnot(result$metrics$effect >= spec$lower, result$metrics$effect <= spec$upper)
    outputs <- c(outputs, paste(spec$mode, spec$measure, format_number(result$metrics$effect)))
  }
  list(status = "PASS", detail = paste(outputs, collapse = "; "))
}
