#!/usr/bin/env Rscript

repo_dir <- normalizePath(getwd())
test_files <- sort(Sys.glob(file.path(repo_dir, "tests", "test_*.R")))
test_files <- test_files[basename(test_files) != "test_helpers.R"]
results <- list()

for (test_file in test_files) {
  test_env <- new.env(parent = globalenv())
  outcome <- tryCatch({
    source(test_file, local = test_env)
    test_env$run_test()
  }, error = function(e) list(status = "FAIL", detail = conditionMessage(e)))
  if (is.null(outcome$status)) outcome$status <- "PASS"
  if (is.null(outcome$detail)) outcome$detail <- "Completed."
  results[[basename(test_file)]] <- outcome
}

lines <- c(
  "# Test Log",
  "",
  paste("Generated:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  "",
  "| Test | Status | Key output |",
  "|---|---|---|"
)
for (name in names(results)) {
  detail <- gsub("[\r\n|]", " ", results[[name]]$detail)
  lines <- c(lines, sprintf("| `%s` | %s | %s |", name, results[[name]]$status, detail))
}
writeLines(lines, file.path(repo_dir, "TEST_LOG.md"))

failed <- vapply(results, function(x) identical(x$status, "FAIL"), logical(1))
blocked <- vapply(results, function(x) identical(x$status, "BLOCKED"), logical(1))
env_path <- file.path(repo_dir, "ENV_REPORT.md")
if (file.exists(env_path)) {
  env_lines <- readLines(env_path, warn = FALSE)
  verified_value <- if (!any(failed) && !any(blocked)) "YES" else "NO"
  if (any(grepl("^V2_VERIFIED=", env_lines))) {
    env_lines[grepl("^V2_VERIFIED=", env_lines)] <- paste0("V2_VERIFIED=", verified_value)
  } else {
    env_lines <- c(paste0("V2_VERIFIED=", verified_value), "", env_lines)
  }
  writeLines(env_lines, env_path)
}
quit(status = if (any(failed)) 1L else 0L)

