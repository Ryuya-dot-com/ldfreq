#!/usr/bin/env Rscript

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 3L) {
  stop(
    "Usage: assemble-run-index.R /source-evidence /check-evidence /new/output/directory",
    call. = FALSE
  )
}
if (!requireNamespace("digest", quietly = TRUE) ||
    !requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The run-index assembler requires digest and jsonlite.", call. = FALSE)
}

source_root <- normalizePath(arguments[[1L]], mustWork = TRUE)
check_root <- normalizePath(arguments[[2L]], mustWork = TRUE)
output_requested <- arguments[[3L]]
if (file.exists(output_requested) || dir.exists(output_requested)) {
  stop("The run-index output directory must not already exist.", call. = FALSE)
}
if (!dir.create(output_requested, recursive = TRUE, mode = "0755")) {
  stop("Could not create the run-index output directory.", call. = FALSE)
}
output_root <- normalizePath(output_requested, mustWork = TRUE)

check <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}
sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}
record <- function(path, root) {
  root_prefix <- paste0(normalizePath(root, mustWork = TRUE), .Platform$file.sep)
  normalized <- normalizePath(path, mustWork = TRUE)
  list(
    path = gsub("\\\\", "/", substring(normalized, nchar(root_prefix) + 1L)),
    bytes = as.numeric(file.info(path)$size[[1L]]),
    sha256 = sha256_file(path)
  )
}

provenance_paths <- list.files(
  source_root,
  pattern = "^release-provenance[.]json$",
  full.names = TRUE,
  recursive = TRUE
)
check(
  length(provenance_paths) == 1L,
  "Exactly one release-provenance.json file is required."
)
provenance_path <- provenance_paths[[1L]]
provenance <- jsonlite::read_json(provenance_path, simplifyVector = FALSE)
result_paths <- list.files(
  check_root,
  pattern = "^check-result[.]json$",
  full.names = TRUE,
  recursive = TRUE
)
check(length(result_paths) == 5L, "Exactly five check-result.json files are required.")
results <- lapply(result_paths, jsonlite::read_json, simplifyVector = FALSE)
labels <- vapply(results, function(value) value$job_label, character(1L))
expected_labels <- c(
  "ubuntu-latest-r-release",
  "ubuntu-latest-r-devel",
  "ubuntu-latest-r-4.1",
  "macos-latest-r-release",
  "windows-latest-r-release"
)
check(setequal(labels, expected_labels) && !anyDuplicated(labels), "The check matrix labels are incomplete or duplicated.")
for (result in results) {
  check(identical(as.integer(result$exit_code), 0L), paste("Check failed:", result$job_label))
  check(
    result$effective_status %in% c("PASS", "PASS_WITH_EXPLAINED_NOTE"),
    paste("Blocking check status:", result$job_label)
  )
  if (identical(result$effective_status, "PASS_WITH_EXPLAINED_NOTE")) {
    check(
      identical(result$check_status, "Status: 1 NOTE") &&
        length(result$explained_notes) == 1L &&
        identical(result$explained_notes[[1L]]$note, "New submission"),
      paste("Unrecognized note disposition:", result$job_label)
    )
  }
  check(
    identical(result$artifact$sha256, provenance$artifact$sha256),
    paste("Artifact drift in", result$job_label)
  )
}

evidence_paths <- list.files(
  c(source_root, check_root),
  pattern = "[.](json|log|pdf|gz)$",
  full.names = TRUE,
  recursive = TRUE
)
evidence_paths <- evidence_paths[file.info(evidence_paths)$isdir %in% FALSE]
source_records <- lapply(evidence_paths[startsWith(normalizePath(evidence_paths), normalizePath(source_root))], record, root = source_root)
check_records <- lapply(evidence_paths[startsWith(normalizePath(evidence_paths), normalizePath(check_root))], record, root = check_root)

index <- list(
  schema_version = "1.0.0",
  status = "technical-matrix-complete",
  candidate = provenance$candidate,
  artifact = provenance$artifact,
  workflow = list(
    run_id = if (nzchar(Sys.getenv("GITHUB_RUN_ID"))) Sys.getenv("GITHUB_RUN_ID") else NULL,
    run_attempt = if (nzchar(Sys.getenv("GITHUB_RUN_ATTEMPT"))) Sys.getenv("GITHUB_RUN_ATTEMPT") else NULL,
    five_exact_artifact_checks_pass = TRUE,
    unexplained_notes = 0,
    required_aggregate = "Release-candidate required"
  ),
  checks = results[order(labels, method = "radix")],
  evidence_files = list(source = source_records, checks = check_records),
  go_no_go = list(
    decision = "PENDING_INDEPENDENT_REVIEW",
    reason = paste(
      "Technical completion cannot replace independent review of the exact",
      "candidate commit, workflow definition, evidence, and release scope."
    )
  )
)
jsonlite::write_json(
  index,
  file.path(output_root, "release-candidate-run-index.json"),
  auto_unbox = TRUE,
  pretty = TRUE,
  null = "null",
  digits = NA
)
message(sprintf("Release-candidate run index assembled for %s.", provenance$artifact$file))
