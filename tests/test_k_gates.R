run_test <- function() {
  source("scripts/common.R")
  stopifnot(!should_run_diagnostic("funnel", 2L))
  stopifnot(!should_run_diagnostic("baujat", 2L))
  stopifnot(!should_run_diagnostic("drapery", 2L))
  stopifnot(!should_run_diagnostic("leave_one_out", 2L))
  stopifnot(!should_run_diagnostic("small_study_test", 9L))
  stopifnot(should_run_diagnostic("funnel", 3L))
  stopifnot(should_run_diagnostic("small_study_test", 10L))
  list(status = "PASS", detail = "k=2 skips diagnostics; k=3/10 gates activate as specified.")
}

