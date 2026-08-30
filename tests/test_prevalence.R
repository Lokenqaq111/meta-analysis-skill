run_test <- function() {
  if (!requireNamespace("meta", quietly = TRUE)) {
    return(list(status = "BLOCKED", detail = "Package `meta` is not installed."))
  }
  source("scripts/common.R")
  source("scripts/validate.R")
  source("scripts/pairwise_prevalence.R")
  dat <- utils::read.csv("examples/prevalence_toy/input.csv", stringsAsFactors = FALSE)
  validation <- validate_data(dat, "prevalence", "PLOGIT")
  stopifnot(validation$ok)
  outdir <- tempfile("prevalence-test-")
  dir.create(file.path(outdir, "data"), recursive = TRUE)
  dir.create(file.path(outdir, "plots"), recursive = TRUE)
  result <- run_pairwise_prevalence(validation$data, "PLOGIT", outdir)
  stopifnot(result$metrics$effect >= 0.01, result$metrics$effect <= 0.90)
  stopifnot(file.exists(file.path(outdir, "data", "summary.txt")))
  stopifnot(any(validation$data$events == 0), any(validation$data$events == validation$data$total))
  list(status = "PASS", detail = sprintf("Pooled prevalence=%0.4f; boundary studies retained.", result$metrics$effect))
}
