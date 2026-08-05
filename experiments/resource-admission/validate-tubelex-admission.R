#!/usr/bin/env Rscript

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) > 1L ||
    (length(arguments) == 1L && !identical(arguments[[1L]], "candidate"))) {
  stop("Usage: validate-tubelex-admission.R [candidate]", call. = FALSE)
}
if (!requireNamespace("ldfreq", quietly = TRUE)) {
  stop("Install the ldfreq candidate before running this gate.", call. = FALSE)
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The admission command requires the suggested jsonlite package.", call. = FALSE)
}

evaluate <- getFromNamespace(".lexres_evaluate_tubelex_admission", "ldfreq")
result <- evaluate()
passed <- identical(result$status, "maintainer_decision_valid") &&
  identical(result$admission_gate_passed, TRUE) &&
  identical(result$package_release_ready, FALSE) &&
  is.na(result$failure_reason) &&
  identical(result$diagnostics$release_approved_resource_count, 1)

cat(jsonlite::toJSON(result, auto_unbox = TRUE, pretty = TRUE, null = "null"))
cat("\n")
if (!isTRUE(passed)) quit(status = 1L)
