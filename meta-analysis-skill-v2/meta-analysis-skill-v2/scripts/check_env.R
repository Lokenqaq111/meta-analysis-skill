#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
output_arg <- grep("^--output=", args, value = TRUE)
output_path <- if (length(output_arg)) sub("^--output=", "", output_arg[[1]]) else "ENV_REPORT.md"

line <- function(...) paste0(...)
report <- c(
  "# Environment Report",
  "",
  line("Generated: ", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  "",
  "V2_VERIFIED=NO",
  "",
  "## Runtime",
  "",
  line("- OS: ", paste(names(Sys.info()), Sys.info(), sep = "=", collapse = "; ")),
  line("- R executable: ", file.path(R.home("bin"), "R")),
  line("- R version: ", R.version.string)
)

write_probe <- tempfile(pattern = "meta-analysis-v2-write-probe-", tmpdir = getwd())
write_ok <- tryCatch({
  writeLines("write-ok", write_probe)
  unlink(write_probe)
  TRUE
}, error = function(e) FALSE)

library_status <- vapply(.libPaths(), function(path) file.access(path, 2) == 0, logical(1))
report <- c(
  report,
  line("- Repository writable: ", if (write_ok) "YES" else "NO"),
  line("- R library paths: ", paste(.libPaths(), collapse = "; ")),
  line("- Writable R library available: ", if (any(library_status)) "YES" else "NO"),
  "- Package installation attempted: NO (installation requires explicit user consent).",
  "",
  "## Required packages",
  ""
)

required <- c("meta", "metafor", "netmeta")
installed <- vapply(required, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
versions <- vapply(required, function(pkg) {
  if (installed[[pkg]]) as.character(utils::packageVersion(pkg)) else "NOT INSTALLED"
}, character(1))
report <- c(report, paste0("- `", required, "`: ", versions))

report <- c(report, "", "## `meta` API evidence", "")
if (installed[["meta"]]) {
  metacont_fun <- get("metacont", envir = asNamespace("meta"))
  metacont_args <- names(formals(metacont_fun))
  help_text <- tryCatch(
    capture.output(tools::Rd2txt(utils:::.getHelpFile(help("metacont", package = "meta")))),
    error = function(e) character()
  )
  hakn_help <- grep("hakn|method.random.ci", help_text, value = TRUE, ignore.case = TRUE)
  report <- c(
    report,
    line("- `metacont()` has `method.random.ci`: ", "method.random.ci" %in% metacont_args),
    line("- `metacont()` has `hakn`: ", "hakn" %in% metacont_args),
    "- Installed help/source evidence:",
    paste0("  - ", head(trimws(hakn_help[nzchar(trimws(hakn_help))]), 8))
  )
} else {
  report <- c(report, "- BLOCKED: `meta` is not installed; runtime API could not be inspected.")
}

report <- c(report, "", "## `netmeta` API evidence", "")
if (installed[["netmeta"]]) {
  suppressPackageStartupMessages(library(netmeta))
  netrank_fun <- get("netrank", envir = asNamespace("netmeta"))
  netrank_args <- names(formals(netrank_fun))
  forest_methods <- methods("forest")
  netrank_help <- tryCatch(
    capture.output(tools::Rd2txt(utils:::.getHelpFile(help("netrank", package = "netmeta")))),
    error = function(e) character()
  )
  report <- c(
    report,
    line("- `netrank()` has `method`: ", "method" %in% netrank_args),
    line("- `forest.netmeta` registered: ", any(grepl("forest.netmeta", forest_methods, fixed = TRUE))),
    line("- `forest.netrank` registered: ", any(grepl("forest.netrank", forest_methods, fixed = TRUE))),
    line("- Installed help mentions P-score: ", any(grepl("P-score", netrank_help, ignore.case = TRUE))),
    line("- Installed help mentions SUCRA: ", any(grepl("SUCRA", netrank_help, ignore.case = TRUE)))
  )
} else {
  report <- c(report, "- BLOCKED: `netmeta` is not installed; runtime API could not be inspected.")
}

branch <- if (all(installed)) "A" else "B"
report <- c(
  report,
  "",
  "## Gate decision",
  "",
  line("- Branch: ", branch),
  if (branch == "A") {
    "- R and all three required packages are available. Full runtime verification is permitted; `V2_VERIFIED` remains NO until `tests/run_all.sh` passes without FAIL or BLOCKED results."
  } else {
    "- R is available but one or more required packages are missing. Implement all V2 files; mark package-dependent tests BLOCKED until installation is explicitly approved."
  }
)

writeLines(report, output_path, useBytes = TRUE)
message("Wrote ", normalizePath(output_path, mustWork = FALSE))
