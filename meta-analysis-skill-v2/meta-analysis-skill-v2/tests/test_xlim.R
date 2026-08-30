run_test <- function() {
  source("scripts/common.R")
  limits <- auto_xlim(effect = c(20, 35, 50), lower = c(10, 20, 35), upper = c(35, 50, 62))
  stopifnot(limits[[1]] <= 10, limits[[2]] >= 62, limits[[2]] > 50)
  list(status = "PASS", detail = paste("MD limits:", paste(limits, collapse = ", ")))
}

