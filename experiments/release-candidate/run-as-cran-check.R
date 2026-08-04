#!/usr/bin/env Rscript

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 3L) {
  stop(
    "Usage: run-as-cran-check.R /path/to/source.tar.gz /new/output/directory job-label",
    call. = FALSE
  )
}
if (!requireNamespace("digest", quietly = TRUE) ||
    !requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The check runner requires digest and jsonlite.", call. = FALSE)
}

source_archive <- normalizePath(arguments[[1L]], mustWork = TRUE)
output_requested <- arguments[[2L]]
job_label <- arguments[[3L]]
if (!nzchar(job_label)) stop("job-label must not be empty.", call. = FALSE)
if (file.exists(output_requested) || dir.exists(output_requested)) {
  stop("The check output directory must not already exist.", call. = FALSE)
}
if (!dir.create(output_requested, recursive = TRUE, mode = "0755")) {
  stop("Could not create the check output directory.", call. = FALSE)
}
output_root <- normalizePath(output_requested, mustWork = TRUE)
log_path <- file.path(output_root, "command-output.log")

old <- setwd(output_root)
on.exit(setwd(old), add = TRUE)
started <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
status <- system2(
  file.path(R.home("bin"), "R"),
  args = c("CMD", "check", "--as-cran", "--no-manual", shQuote(source_archive)),
  stdout = log_path,
  stderr = log_path
)
finished <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

check_directories <- list.dirs(output_root, full.names = TRUE, recursive = FALSE)
check_directories <- check_directories[endsWith(check_directories, ".Rcheck")]
check_log <- if (length(check_directories) == 1L) {
  file.path(check_directories[[1L]], "00check.log")
} else {
  NA_character_
}
check_lines <- if (!is.na(check_log) && file.exists(check_log)) {
  readLines(check_log, warn = FALSE)
} else {
  character()
}
status_lines <- grep("^Status:", check_lines, value = TRUE)
check_status <- if (length(status_lines)) tail(status_lines, 1L) else "Status: unavailable"
note_steps <- grep("^\\* checking .* NOTE$", check_lines, value = TRUE)
new_submission_note <- identical(check_status, "Status: 1 NOTE") &&
  length(note_steps) == 1L &&
  any(check_lines == "New submission")
effective_status <- if (identical(check_status, "Status: OK")) {
  "PASS"
} else if (new_submission_note) {
  "PASS_WITH_EXPLAINED_NOTE"
} else {
  "FAIL"
}

result <- list(
  schema_version = "1.0.0",
  job_label = job_label,
  command = "R CMD check --as-cran --no-manual <exact-source-archive>",
  exit_code = as.integer(status),
  check_status = check_status,
  effective_status = effective_status,
  explained_notes = if (new_submission_note) {
    list(list(
      note = "New submission",
      disposition = paste(
        "Expected CRAN incoming note for a package version that has not",
        "previously been published on CRAN; no package defect is asserted."
      )
    ))
  } else {
    list()
  },
  started_at_utc = started,
  finished_at_utc = finished,
  environment = list(
    os = unname(Sys.info()[["sysname"]]),
    platform = R.version$platform,
    r_version = R.version.string
  ),
  artifact = list(
    file = basename(source_archive),
    bytes = as.numeric(file.info(source_archive)$size[[1L]]),
    sha256 = digest::digest(file = source_archive, algo = "sha256", serialize = FALSE)
  ),
  check_log = if (!is.na(check_log)) basename(check_log) else NULL
)
jsonlite::write_json(
  result,
  file.path(output_root, "check-result.json"),
  auto_unbox = TRUE,
  pretty = TRUE,
  null = "null"
)

if (!identical(as.integer(status), 0L) || identical(effective_status, "FAIL")) {
  message(paste(readLines(log_path, warn = FALSE), collapse = "\n"))
  quit(status = 1L, save = "no")
}

message(sprintf("%s: %s (%s)", job_label, check_status, effective_status))
