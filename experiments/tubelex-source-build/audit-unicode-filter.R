#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    "Usage: Rscript audit-unicode-filter.R <source.tsv.xz> <reviewed-artifact.csv.gz>",
    call. = FALSE
  )
}
for (package in c("digest", "stringi")) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(sprintf("The audit requires %s.", package), call. = FALSE)
  }
}

expected_source_bytes <- 4152940
expected_source_sha256 <- "4096022259d5eaa7261c3bf22c3b0af9fd58ae8eebe17894c0b34a163954f936"
expected_artifact_bytes <- 4572297
expected_artifact_sha256 <- "3731f23f3385ed630777ff56b5edbed5db46eee256ededceb0ac213016f31675"
for (input in list(
  list(path = args[[1L]], bytes = expected_source_bytes, sha256 = expected_source_sha256),
  list(path = args[[2L]], bytes = expected_artifact_bytes, sha256 = expected_artifact_sha256)
)) {
  actual_bytes <- unname(file.info(input$path)$size)
  actual_sha256 <- digest::digest(file = input$path, algo = "sha256", serialize = FALSE)
  if (!identical(as.numeric(actual_bytes), as.numeric(input$bytes)) ||
      !identical(actual_sha256, input$sha256)) {
    stop(sprintf("Pinned input identity mismatch: %s", input$path), call. = FALSE)
  }
}

source_connection <- xzfile(args[[1L]], open = "rt", encoding = "UTF-8")
source_lines <- readLines(source_connection, warn = FALSE, encoding = "UTF-8")
close(source_connection)
expected_header <- c(
  "word", "count", "videos", "channels", "count:howto", "count:gaming",
  "count:entertainment", "count:education", "count:science", "count:sports",
  "count:nonprofits", "count:autos", "count:people", "count:music",
  "count:news", "count:film", "count:travel", "count:comedy", "count:pets"
)
if (!identical(strsplit(source_lines[[1L]], "\t", fixed = TRUE)[[1L]], expected_header)) {
  stop("Pinned source header mismatch.", call. = FALSE)
}
source_words <- vapply(
  strsplit(source_lines[-1L], "\t", fixed = TRUE),
  `[[`,
  character(1L),
  1L,
  USE.NAMES = FALSE
)
source_words <- source_words[source_words != "[TOTAL]"]

artifact_connection <- gzfile(args[[2L]], open = "rt", encoding = "UTF-8")
artifact_lines <- readLines(artifact_connection, warn = FALSE, encoding = "UTF-8")
close(artifact_connection)
if (!identical(strsplit(artifact_lines[[1L]], ",", fixed = TRUE)[[1L]], expected_header)) {
  stop("Reviewed artifact header mismatch.", call. = FALSE)
}
artifact_words <- vapply(
  strsplit(artifact_lines[-1L], ",", fixed = TRUE),
  `[[`,
  character(1L),
  1L,
  USE.NAMES = FALSE
)
artifact_words <- artifact_words[artifact_words != "[TOTAL]"]

normalized <- stringi::stri_trans_tolower(
  stringi::stri_trim_both(stringi::stri_trans_nfkc(source_words)),
  locale = "und"
)
lookup_pattern <- "^'?(?:\\p{L}+)(?:['-]\\p{L}+)*$"
r_compatible <- (
  stringi::stri_length(source_words) <= 64L &
    source_words == normalized &
    stringi::stri_detect_regex(source_words, lookup_pattern)
)

extra <- setdiff(source_words[r_compatible], artifact_words)
missing <- setdiff(artifact_words, source_words[r_compatible])
cat(sprintf(
  "R/ICU retained: %d; reviewed artifact: %d; extra: %d; missing: %d\n",
  sum(r_compatible),
  length(artifact_words),
  length(extra),
  length(missing)
))

show_words <- function(label, words) {
  cat(sprintf("\n%s (%d)\n", label, length(words)))
  if (length(words)) {
    escaped <- stringi::stri_escape_unicode(words)
    code_points <- vapply(
      words,
      function(word) paste(sprintf("U+%04X", utf8ToInt(word)), collapse = " "),
      character(1L),
      USE.NAMES = FALSE
    )
    print(utils::head(data.frame(word = words, escaped, code_points), 300L), row.names = FALSE)
  }
}

show_words("R/ICU-only words", extra)
show_words("Reviewed-artifact-only words", missing)

if (length(extra) || length(missing) || sum(r_compatible) != 515292L) {
  stop("Unicode lookup-filter equivalence audit failed.", call. = FALSE)
}
cat("Unicode lookup-filter equivalence audit passed.\n")
