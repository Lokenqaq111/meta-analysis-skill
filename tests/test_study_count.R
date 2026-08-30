run_test <- function() {
  source("scripts/common.R")
  dat <- data.frame(study = c("A", "A", "B", "B", "C", "C"))
  stopifnot(study_count(dat) == 3L, nrow(dat) == 6L)
  list(status = "PASS", detail = "3 unique studies are distinct from 6 rows.")
}

