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
expected_evidence_names <- c(
  "package_file_bom", "dependency_sbom", "resource_bom"
)
check(
  setequal(names(provenance$evidence), expected_evidence_names) &&
    !anyDuplicated(names(provenance$evidence)),
  "The release provenance has an incomplete evidence identity set."
)
expected_source_identities <- c(
  list(artifact = provenance$artifact, manual = provenance$manual),
  provenance$evidence
)
all_source_files <- list.files(
  source_root,
  full.names = TRUE,
  recursive = TRUE
)
all_source_files <- all_source_files[file.info(all_source_files)$isdir %in% FALSE]
for (identity_name in names(expected_source_identities)) {
  expected_identity <- expected_source_identities[[identity_name]]
  identity_paths <- all_source_files[
    basename(all_source_files) == expected_identity$file
  ]
  check(
    length(identity_paths) == 1L,
    paste("Missing or duplicated source evidence:", identity_name)
  )
  check(
    identical(
      as.numeric(file.info(identity_paths[[1L]])$size),
      as.numeric(expected_identity$bytes)
    ) && identical(
      sha256_file(identity_paths[[1L]]),
      expected_identity$sha256
    ),
    paste("Source evidence identity drift:", identity_name)
  )
}
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
maintainer_pattern <- paste0(
  "^Maintainer: [‘']?[^<>[:cntrl:]]+ ",
  "<[^<>[:space:]]+@[^<>[:space:]]+>[’']?[[:space:]]*$"
)
incoming_stage_pattern <- paste0(
  "^\\* checking CRAN incoming feasibility \\.\\.\\. ",
  "(\\[[^]]+\\] )?NOTE$"
)
dependency_stage_pattern <- paste0(
  "^\\* checking package dependencies \\.\\.\\. ",
  "(\\[[^]]+\\] )?NOTE$"
)
expected_environments <- list(
  "ubuntu-latest-r-release" = c("Linux", "linux"),
  "ubuntu-latest-r-devel" = c("Linux", "linux"),
  "ubuntu-latest-r-4.1" = c("Linux", "linux"),
  "macos-latest-r-release" = c("Darwin", "apple-darwin"),
  "windows-latest-r-release" = c("Windows", "mingw32")
)
r_version_number <- function(value) {
  if (!is.character(value) || length(value) != 1L ||
      !grepl("^R version [0-9]+[.][0-9]+[.][0-9]+", value)) {
    return(NA_character_)
  }
  sub("^R version ([0-9]+[.][0-9]+[.][0-9]+).*$", "\\1", value)
}
release_r_version <- r_version_number(provenance$environment$r_version)
check(!is.na(release_r_version), "The build-source R version is unrecognized.")
for (result in results) {
  check(
    identical(result$schema_version, "1.1.0"),
    paste("Unrecognized check-result schema:", result$job_label)
  )
  expected_environment <- expected_environments[[result$job_label]]
  check(
    identical(result$environment$os, expected_environment[[1L]]) &&
      is.character(result$environment$platform) &&
      length(result$environment$platform) == 1L &&
      grepl(expected_environment[[2L]], result$environment$platform),
    paste("Check environment does not match its label:", result$job_label)
  )
  if (identical(result$job_label, "ubuntu-latest-r-devel")) {
    check(
      grepl("^R Under development ", result$environment$r_version),
      "The R-devel check did not use R Under development."
    )
  } else if (identical(result$job_label, "ubuntu-latest-r-4.1")) {
    check(
      grepl("^R version 4[.]1[.]", result$environment$r_version),
      "The minimum-R check did not use R 4.1.x."
    )
  } else {
    check(
      identical(
        r_version_number(result$environment$r_version),
        release_r_version
      ),
      paste("Release-R version drift:", result$job_label)
    )
  }
  check(identical(as.integer(result$exit_code), 0L), paste("Check failed:", result$job_label))
  check(
    result$effective_status %in% c(
      "PASS", "PASS_WITH_EXPLAINED_NOTE", "PASS_WITH_EXPLAINED_NOTES"
    ),
    paste("Blocking check status:", result$job_label)
  )
  expected_note_policy <- if (identical(
    result$job_label,
    "ubuntu-latest-r-4.1"
  )) {
    "minimum-r-optional-textstem"
  } else {
    "new-submission-only"
  }
  check(
    identical(result$note_policy, expected_note_policy),
    paste("Wrong check NOTE policy:", result$job_label)
  )
  if (identical(result$job_label, "ubuntu-latest-r-4.1")) {
    check(
      identical(result$effective_status, "PASS_WITH_EXPLAINED_NOTES"),
      "The minimum-R check did not record both expected NOTE dispositions."
    )
  }
  if (identical(result$effective_status, "PASS")) {
    check(
      identical(result$check_status, "Status: OK") &&
        length(result$explained_notes) == 0L &&
        length(result$note_blocks) == 0L,
      paste("Inconsistent passing check record:", result$job_label)
    )
  } else if (identical(
    result$effective_status,
    "PASS_WITH_EXPLAINED_NOTE"
  )) {
    check(
      identical(result$check_status, "Status: 1 NOTE") &&
        length(result$explained_notes) == 1L &&
        identical(result$explained_notes[[1L]]$note, "New submission") &&
        length(result$note_blocks) == 1L &&
        grepl(incoming_stage_pattern, result$note_blocks[[1L]]$stage) &&
        length(result$note_blocks[[1L]]$detail) == 2L &&
        grepl(maintainer_pattern, result$note_blocks[[1L]]$detail[[1L]]) &&
        identical(
          result$note_blocks[[1L]]$detail[[2L]],
          "New submission"
        ),
      paste("Unrecognized note disposition:", result$job_label)
    )
  } else {
    textstem_pattern <- paste0(
      "^Package suggested but not available for checking: ",
      "[‘']textstem[’']$"
    )
    check(
      identical(result$job_label, "ubuntu-latest-r-4.1") &&
        identical(result$check_status, "Status: 2 NOTEs") &&
        length(result$explained_notes) == 2L &&
        identical(result$explained_notes[[1L]]$note, "New submission") &&
        identical(
          result$explained_notes[[2L]]$note,
          "Package suggested but not available for checking: textstem"
        ) &&
        length(result$note_blocks) == 2L &&
        grepl(incoming_stage_pattern, result$note_blocks[[1L]]$stage) &&
        length(result$note_blocks[[1L]]$detail) == 2L &&
        grepl(maintainer_pattern, result$note_blocks[[1L]]$detail[[1L]]) &&
        identical(
          result$note_blocks[[1L]]$detail[[2L]],
          "New submission"
        ) &&
        grepl(dependency_stage_pattern, result$note_blocks[[2L]]$stage) &&
        length(result$note_blocks[[2L]]$detail) == 1L &&
        grepl(textstem_pattern, result$note_blocks[[2L]]$detail[[1L]]),
      paste("Unrecognized minimum-R note disposition:", result$job_label)
    )
  }
  check(
    identical(result$artifact$sha256, provenance$artifact$sha256),
    paste("Artifact drift in", result$job_label)
  )
}

inventory_paths <- sort(list.files(
  check_root,
  pattern = "^package-resource-inventory-evidence[.]json$",
  full.names = TRUE,
  recursive = TRUE
), method = "radix")
check(
  length(inventory_paths) == 3L,
  "Exactly three current-R resource-inventory records are required."
)
check_root_prefix <- paste0(check_root, .Platform$file.sep)
inventory_relative_paths <- gsub(
  "\\\\",
  "/",
  substring(
    normalizePath(inventory_paths, mustWork = TRUE),
    nchar(check_root_prefix) + 1L
  )
)
inventory_labels <- sub("/.*$", "", inventory_relative_paths)
inventory_labels <- sub("^release-check-", "", inventory_labels)
expected_inventory_labels <- c(
  "ubuntu-latest-r-release",
  "macos-latest-r-release",
  "windows-latest-r-release"
)
check(
  setequal(inventory_labels, expected_inventory_labels) &&
    !anyDuplicated(inventory_labels),
  "The current-R resource-inventory labels are incomplete or duplicated."
)
inventories <- lapply(
  inventory_paths,
  jsonlite::read_json,
  simplifyVector = FALSE
)
for (index in seq_along(inventories)) {
  inventory_record <- inventories[[index]]
  inventory_label <- inventory_labels[[index]]
  check(
    identical(
      inventory_record$status,
      "source-platform-installed-resource-inventory-ok"
    ),
    paste("Resource inventory failed:", inventory_label)
  )
  matching_result <- results[[match(inventory_label, labels)]]
  check(
    identical(inventory_record$environment, matching_result$environment),
    paste("Resource inventory environment drift:", inventory_label)
  )
  check(
    identical(
      inventory_record$source_archive_origin,
      "provided-exact-release-candidate"
    ) && identical(
      inventory_record$comparison_authority,
      "provided-exact-source-archive"
    ),
    paste("Wrong resource comparison authority:", inventory_label)
  )
  check(
    identical(
      inventory_record$source_archive$sha256,
      provenance$artifact$sha256
    ),
    paste("Resource inventory artifact drift:", inventory_label)
  )
  check(
    identical(as.numeric(inventory_record$release_approved_resource_count), 1) &&
      identical(inventory_record$undeclared_extdata_observed, FALSE),
    paste("Resource boundary changed:", inventory_label)
  )
}
inventory_summaries <- lapply(seq_along(inventories), function(index) {
  inventory_record <- inventories[[index]]
  list(
    job_label = inventory_labels[[index]],
    status = inventory_record$status,
    environment = inventory_record$environment,
    comparison_authority = inventory_record$comparison_authority,
    artifact = inventory_record$source_archive,
    release_approved_resource_count =
      inventory_record$release_approved_resource_count,
    undeclared_extdata_observed =
      inventory_record$undeclared_extdata_observed,
    assertions = inventory_record$assertions
  )
})

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
  schema_version = "1.1.0",
  status = "technical-matrix-complete",
  candidate = provenance$candidate,
  artifact = provenance$artifact,
  workflow = list(
    run_id = if (nzchar(Sys.getenv("GITHUB_RUN_ID"))) Sys.getenv("GITHUB_RUN_ID") else NULL,
    run_attempt = if (nzchar(Sys.getenv("GITHUB_RUN_ATTEMPT"))) Sys.getenv("GITHUB_RUN_ATTEMPT") else NULL,
    five_exact_artifact_checks_pass = TRUE,
    three_current_r_resource_inventories_pass = TRUE,
    unexplained_notes = 0,
    required_aggregate = "Release-candidate required"
  ),
  checks = results[order(labels, method = "radix")],
  resource_inventories = inventory_summaries[
    order(inventory_labels, method = "radix")
  ],
  evidence_files = list(source = source_records, checks = check_records),
  go_no_go = list(
    decision = "PENDING_MAINTAINER_RELEASE_DECISION",
    reason = paste(
      "The technical matrix and recorded resource decision do not replace the",
      "maintainer's final go/no-go judgment for the exact release candidate."
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
