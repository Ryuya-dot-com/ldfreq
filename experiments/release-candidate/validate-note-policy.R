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
