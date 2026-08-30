run_test <- function() {
  if (!requireNamespace("meta", quietly = TRUE)) {
    return(list(status = "BLOCKED", detail = "Package `meta` is not installed."))
  }
  functions <- c("metacont", "metabin", "metagen", "metaprop")
  missing_current_api <- vapply(functions, function(name) {
    !"method.random.ci" %in% names(formals(get(name, envir = asNamespace("meta"))))
  }, logical(1))
  stopifnot(!any(missing_current_api))
  help_text <- capture.output(
    tools::Rd2txt(utils:::.getHelpFile(help("metacont", package = "meta")))
  )
  stopifnot(any(grepl("hakn", help_text, ignore.case = TRUE)),
            any(grepl("Deprecated", help_text, ignore.case = TRUE)))
  list(status = "PASS", detail = paste("meta", as.character(utils::packageVersion("meta")),
                                       "exposes method.random.ci and documents deprecated hakn."))
}
