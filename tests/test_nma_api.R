run_test <- function() {
  if (!requireNamespace("netmeta", quietly = TRUE) || !requireNamespace("meta", quietly = TRUE)) {
    return(list(status = "BLOCKED", detail = "Packages `netmeta` and/or `meta` are not installed."))
  }
  suppressPackageStartupMessages(library(netmeta))
  source("scripts/common.R")
  source("scripts/validate.R")
  source("scripts/nma.R")
  forest_methods <- methods("forest")
  stopifnot(any(grepl("forest.netmeta", forest_methods, fixed = TRUE)))
  stopifnot(!any(grepl("forest.netrank", forest_methods, fixed = TRUE)))
  stopifnot("method" %in% names(formals(netmeta::netrank)))
  dat <- utils::read.csv("examples/nma_toy/input.csv", stringsAsFactors = FALSE)
  validation <- validate_data(dat, "network", "RR")
  stopifnot(validation$ok)
  outdir <- tempfile("nma-test-")
  dir.create(file.path(outdir, "data"), recursive = TRUE)
  dir.create(file.path(outdir, "plots"), recursive = TRUE)
  result <- run_nma(validation$data, "RR", outdir, reference = "control",
                    ranking_method = "P-score", components = validation$network_components)
  stopifnot(identical(result$ranking_method, "P-score"))
  stopifnot(file.exists(file.path(outdir, "data", "ranking_pscore.txt")))
  stopifnot(!file.exists(file.path(outdir, "data", "ranking_sucra.txt")))
  list(status = "PASS", detail = "forest.netmeta and P-score path ran; no forest.netrank call or SUCRA relabeling.")
}

