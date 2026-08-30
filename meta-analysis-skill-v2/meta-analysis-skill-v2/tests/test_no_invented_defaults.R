run_test <- function() {
  files <- c("SKILL.md", "README.md", Sys.glob("scripts/*.R"), Sys.glob("references/*.md"))
  text <- paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = "\n")
  stopifnot(!grepl("6MWT MCID", text, fixed = TRUE))
  stopifnot(!grepl("BBS MCID", text, fixed = TRUE))
  stopifnot(!grepl("6MWT.*30", text))
  list(status = "PASS", detail = "No universal MCID values are embedded in skill instructions or reports.")
}

