run_test <- function() {
  source("scripts/common.R")
  source("scripts/validate.R")
  dat <- utils::read.csv("templates/continuous_template.csv", stringsAsFactors = FALSE)
  dat$sd_t[[1]] <- NA
  result <- validate_data(dat, "continuous", "SMD")
  stopifnot(!result$ok, any(grepl("sd_t", result$errors, fixed = TRUE)))
  multiarm <- utils::read.csv("tests/fixtures/multiarm_shared_control.csv", stringsAsFactors = FALSE)
  multiarm_result <- validate_data(multiarm, "continuous", "SMD")
  stopifnot(!multiarm_result$ok, any(grepl("shared-control", multiarm_result$errors, fixed = TRUE)))
  single <- utils::read.csv("templates/continuous_template.csv", stringsAsFactors = FALSE)[1, , drop = FALSE]
  single_result <- validate_data(single, "continuous", "SMD")
  stopifnot(!single_result$ok, any(grepl("at least two", single_result$errors, fixed = TRUE)))
  list(status = "PASS", detail = "Blank data, k=1, and shared-control multi-arm data stop validation.")
}
