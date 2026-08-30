run_test <- function() {
  source("scripts/common.R")
  dat <- data.frame(mean_t = c(4, 4), mean_c = c(1, 1),
                    higher_is_better = c(TRUE, FALSE))
  aligned <- align_continuous_direction(dat, TRUE)
  stopifnot(aligned$mean_t[[1]] == 4, aligned$mean_t[[2]] == -4,
            aligned$mean_c[[2]] == -1, sum(aligned$direction_flipped) == 1L)
  list(status = "PASS", detail = "Direction reversal flips means and resulting effect sign.")
}

