# Run from the package root; no optional packages or network needed.
source("experiments/release-candidate/check-note-policy.R")
incoming <- list(stage = "* checking CRAN incoming feasibility ... NOTE",
  detail = list("Maintainer: Example Author <author@example.org>", "New submission"))
dependency <- list(stage = "* checking package dependencies ... NOTE",
  detail = list("Packages suggested but not available for checking:", "'gibasa', 'textstem'"))
classify <- function(note, policy = "minimum-r-optional-backends") {
  release_classify_notes("Status: 2 NOTEs", list(incoming, note), policy)$effective_status
}
stopifnot(classify(dependency) == "PASS_WITH_EXPLAINED_NOTES",
  classify(dependency, "new-submission-only") == "FAIL")
for (detail in list("Package suggested but not available for checking: 'unknown'",
  "Packages suggested but not available for checking: 'gibasa', 'textstem', 'unknown'",
  c("Packages suggested but not available for checking: 'gibasa', 'textstem'", "Extra unexplained note"))) {
  invalid <- dependency; invalid$detail <- as.list(detail)
  stopifnot(classify(invalid) == "FAIL")
}
cat("Minimum-R note policy accepts only the two declared optional backends.\n")
non_foss <- incoming
non_foss$detail[[3L]] <- "Non-FOSS package license (file LICENSE)"
stopifnot(release_classify_notes("Status: 1 NOTE", list(non_foss),
  "release-resource-notes")$effective_status == "FAIL",
  release_classify_notes("Status: 1 NOTE", list(non_foss),
    "new-submission-only")$effective_status == "FAIL",
  release_classify_notes("Status: 2 NOTEs", list(incoming, non_foss),
    "release-resource-notes")$effective_status == "FAIL")
unknown <- non_foss; unknown$detail[[4L]] <- "Unexpected incoming condition"
stopifnot(release_classify_notes("Status: 1 NOTE", list(unknown),
  "release-resource-notes")$effective_status == "FAIL")

size <- list(stage = "* checking installed package size ... NOTE",
  detail = as.list(c("installed size is 8.1Mb", "sub-directories of 1Mb or more:",
    "R         1.4Mb", "doc       4.4Mb")))
stopifnot(classify(size, "release-resource-notes") == "PASS_WITH_EXPLAINED_NOTES",
  classify(size, "new-submission-only") == "FAIL",
  release_classify_notes("Status: 3 NOTEs", list(incoming, dependency, size),
    "minimum-r-optional-backends")$effective_status == "PASS_WITH_EXPLAINED_NOTES",
  release_classify_notes("Status: OK", list(), "release-resource-notes")$effective_status == "PASS",
  release_classify_notes("Status: OK", list(), "minimum-r-optional-backends")$effective_status == "FAIL")
doc_only <- size
doc_only$detail <- as.list(c("installed size is 6.0Mb", "sub-directories of 1Mb or more:", "doc 4.4Mb"))
stopifnot(classify(doc_only, "release-resource-notes") == "PASS_WITH_EXPLAINED_NOTES")
for (detail in list(
  c("installed size is 10.1Mb", unlist(size$detail)[-1L]),
  c(unlist(size$detail), "cache 1.2Mb"),
  c(unlist(size$detail), "doc 1.2Mb"),
  c(unlist(size$detail), "Extra unexplained note"),
  c("installed size is 8.1Mb", "sub-directories of 1Mb or more:", "R 1.4Mb", "doc 5.1Mb"),
  c("installed size is 8.1Mb", "sub-directories of 1Mb or more:", "R 2.1Mb", "doc 4.4Mb"),
  c(unlist(size$detail), "extdata 1.2Mb")
)) {
  invalid <- size; invalid$detail <- as.list(detail)
  stopifnot(classify(invalid, "release-resource-notes") == "FAIL")
}
for (status in c("Status: 1 WARNING, 2 NOTEs", "Status: 1 ERROR", "Status: 1 NOTE")) {
  stopifnot(release_classify_notes(status, list(incoming, size),
    "release-resource-notes")$effective_status == "FAIL")
}
stopifnot(release_classify_notes("Status: 2 NOTEs", list(size, size),
  "release-resource-notes")$effective_status == "FAIL")
raw <- c(incoming$stage, unlist(incoming$detail), "", size$stage,
  paste0("  ", unlist(size$detail)), "* checking package directory ... OK", "Status: 2 NOTEs")
stopifnot(identical(release_note_blocks(raw), list(incoming, size)))
cat("Release notes reject unknown payload areas, unbounded size, duplicates, warnings and inconsistent status.\n")

# Exercise the production aggregation loop against a synthetic R 4.1 record.
local({
  directory <- tempfile("release-note-record-"); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  raw <- c(incoming$stage, unlist(incoming$detail), dependency$stage,
    unlist(dependency$detail), size$stage, unlist(size$detail),
    "* checking package directory ... OK", "Status: 3 NOTEs")
  log <- file.path(directory, "00check.log"); writeLines(raw, log)
  blocks <- release_note_blocks(raw)
  disposition <- release_classify_notes("Status: 3 NOTEs", blocks,
    "minimum-r-optional-backends")
  labels <- "ubuntu-latest-r-4.1"
  results <- list(c(list(schema_version = "1.2.0", job_label = labels,
    environment = list(os = "Linux", platform = "x86_64-pc-linux-gnu",
      r_version = "R version 4.1.3 (synthetic fixture)", remote_url_checks = FALSE),
    exit_code = 0L, note_policy = "minimum-r-optional-backends",
    check_status = "Status: 3 NOTEs", note_blocks = blocks,
    artifact = list(sha256 = "fixture")), disposition))
  result_paths <- file.path(directory, "check-result.json")
  expected_environments <- list("ubuntu-latest-r-4.1" = c("Linux", "linux"))
  provenance <- list(artifact = list(sha256 = "fixture"))
  check <- function(condition, message) if (!isTRUE(condition)) stop(message)
  expressions <- parse("experiments/release-candidate/assemble-run-index.R")
  loops <- Filter(function(x) is.call(x) && identical(x[[1L]], as.name("for")) &&
    any(grepl("raw check log", deparse(x), fixed = TRUE)), as.list(expressions))
  stopifnot(length(loops) == 1L)
  eval(loops[[1L]])
  original <- results
  results[[1L]]$environment$remote_url_checks <- NULL
  failure <- tryCatch({ eval(loops[[1L]]); NULL }, error = conditionMessage)
  stopifnot(grepl("URL-check scope", failure, fixed = TRUE))
  results <- original
  results[[1L]]$explained_notes[[1L]]$disposition <- "unreviewed exception"
  failure <- tryCatch({ eval(loops[[1L]]); NULL }, error = conditionMessage)
  stopifnot(grepl("disposition disagree", failure, fixed = TRUE))
  results <- original
  writeLines(sub("doc", "cache", raw, fixed = TRUE), log)
  failure <- tryCatch({ eval(loops[[1L]]); NULL }, error = conditionMessage)
  stopifnot(grepl("disposition disagree", failure, fixed = TRUE))
  cat("Run-index aggregation rejects edited dispositions and divergent raw logs.\n")
})

# Historical exceptions must not admit old non-FOSS or URL findings for the current package.
external_cases <- list(
  "ubuntu-latest-r-4.1" = c(
    "Found the following (possibly) invalid DOIs:",
    "DOI: 10.1080/09296171003643098",
    "From: DESCRIPTION",
    "Status: Forbidden",
    "Message: 403",
    "Size of tarball: 6490351 bytes"),
  "ubuntu-latest-r-devel" = c(
    "Found the following (possibly) invalid URLs:",
    "URL: https://sites.psu.edu/xxl13/l2sca/",
    "From: inst/doc/syntactic-complexity.html",
    "Status: Error",
    "Message: libcurl error code 28:",
    "Connection timed out after 60000 milliseconds"),
  "windows-latest-r-release" = c(
    "Found the following (possibly) invalid URLs:",
    "URL: https://uclouvain.be/en/research-institutes/ilc/cecl/locness",
    "From: inst/doc/designing-comparisons.html",
    "Status: Error",
    "Message: libcurl error code 28:",
    "Failed to connect to uclouvain.be port 443 after 21175 ms: Could not connect to server")
)
for (label in names(external_cases)) {
  block <- non_foss; block$detail <- c(block$detail, as.list(external_cases[[label]]))
  minimum <- identical(label, "ubuntu-latest-r-4.1")
  notes <- if (minimum) list(block, dependency) else list(block)
  policy <- if (minimum) "minimum-r-optional-backends" else "release-resource-notes"
  status <- if (minimum) "Status: 2 NOTEs" else "Status: 1 NOTE"
  stopifnot(release_classify_notes(status, notes, policy, label)$effective_status == "FAIL",
    release_classify_notes(status, notes, policy, "unverified-job")$effective_status == "FAIL")
  original <- notes
  notes[[1L]]$detail[[5L]] <- "URL: https://unverified.example/"
  stopifnot(release_classify_notes(status, notes, policy, label)$effective_status == "FAIL")
  notes <- original; notes[[1L]]$detail <- c(notes[[1L]]$detail, "Another unexplained finding")
  stopifnot(release_classify_notes(status, notes, policy, label)$effective_status == "FAIL")
}
cat("Historical external-response exceptions are no longer accepted.\n")
