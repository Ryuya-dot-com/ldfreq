#!/usr/bin/env Rscript

arguments <- commandArgs(trailingOnly = TRUE)
if (!length(arguments) || !(arguments[[1L]] %in% c("candidate", "approval"))) {
  stop(
    paste(
      "Usage: validate-tubelex-admission.R candidate |",
      "approval APPROVAL.dcf EVIDENCE_FILE REPOSITORY_COMMIT"
    ),
    call. = FALSE
  )
}
if (!requireNamespace("ldfreq", quietly = TRUE)) {
  stop("Install the ldfreq candidate before running this gate.", call. = FALSE)
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The admission command requires the suggested jsonlite package.", call. = FALSE)
}

evaluate <- getFromNamespace(".lexres_evaluate_tubelex_admission", "ldfreq")
mode <- arguments[[1L]]
if (identical(mode, "candidate")) {
  if (length(arguments) != 1L) {
    stop("candidate mode accepts no additional arguments.", call. = FALSE)
  }
  result <- evaluate()
  passed <- identical(result$status, "pending_independent_review") &&
    identical(result$admission_gate_passed, FALSE) &&
    identical(result$package_release_ready, FALSE) &&
    identical(result$failure_reason, "approval_missing")
} else {
  if (length(arguments) != 4L) {
    stop(
      "approval mode requires approval, evidence, and commit arguments.",
      call. = FALSE
    )
  }
  result <- evaluate(
    approval_path = arguments[[2L]],
    evidence_path = arguments[[3L]],
    repository_commit = arguments[[4L]]
  )
  passed <- identical(result$status, "approval_record_valid") &&
    identical(result$admission_gate_passed, TRUE) &&
    identical(result$package_release_ready, FALSE)
}

cat(jsonlite::toJSON(result, auto_unbox = TRUE, pretty = TRUE, null = "null"))
cat("\n")
if (!isTRUE(passed)) quit(status = 1L)
