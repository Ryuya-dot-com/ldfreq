# Exercise the production archive scanner without rebuilding the archive.
expressions <- as.list(parse("experiments/release-candidate/generate-release-evidence.R"))
begin <- which(vapply(expressions, function(x) is.call(x) &&
  identical(x[[1L]], as.name("<-")) && identical(x[[2L]], as.name("text_extensions")), logical(1L)))
end <- which(vapply(expressions, function(x) is.call(x) &&
  identical(x[[1L]], as.name("for")) && identical(x[[2L]], as.name("index")), logical(1L)))
end <- min(end[end > begin])
stopifnot(length(begin) == 1L, is.finite(end))
local({
  directory <- tempfile("public-scan-"); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  all_paths <- file.path(directory, c("README.md", "NEWS.md"))
  relative_paths <- basename(all_paths)
  approved <- c(
    "and an optional OpenAI recipe. Paid requests require your own API key and an",
    "- Added an optional OpenAI Responses recipe using httr2. Paid requests require")
  scan <- function() {
    for (expression in expressions[seq.int(begin, end)]) eval(expression)
    scan_findings
  }
  for (i in seq_along(all_paths)) writeLines(approved[[i]], all_paths[[i]])
  stopifnot(length(scan()) == 0L)
  for (text in c("OpenAI internal workflow", "Codex notes", "/Users/example/project",
    "C:\\Users\\example", "INTERNAL-ROADMAP", paste0(approved[[1L]], " private note"))) {
    writeLines(text, all_paths[[1L]])
    stopifnot(length(scan()) > 0L)
  }
  writeLines(approved[[2L]], all_paths[[1L]])
  stopifnot(length(scan()) > 0L)
  cat("Public-scope scan permits only exact, file-specific API descriptions.\n")
})
