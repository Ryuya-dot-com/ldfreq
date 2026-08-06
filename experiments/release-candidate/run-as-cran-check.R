#!/usr/bin/env Rscript

arguments <- commandArgs(trailingOnly = TRUE)
if (!length(arguments) %in% c(3L, 4L)) {
  stop(
    paste(
      "Usage: run-as-cran-check.R /path/to/source.tar.gz",
      "/new/output/directory job-label [note-policy]"
    ),
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
note_policy <- if (length(arguments) == 4L) {
  arguments[[4L]]
} else {
  "new-submission-only"
}
if (!nzchar(job_label)) stop("job-label must not be empty.", call. = FALSE)
allowed_note_policies <- c(
  "new-submission-only",
  "minimum-r-optional-textstem"
)
if (!note_policy %in% allowed_note_policies) {
  stop("Unrecognized check NOTE policy: ", note_policy, call. = FALSE)
}
if (identical(note_policy, "minimum-r-optional-textstem") &&
    (!identical(job_label, "ubuntu-latest-r-4.1") ||
      !grepl("^R version 4[.]1[.]", R.version.string))) {
  stop(
    paste(
      "The minimum-r-optional-textstem NOTE policy is restricted to the",
      "ubuntu-latest-r-4.1 job running R 4.1.x."
    ),
    call. = FALSE
  )
}
script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_argument) != 1L) {
  stop("Could not identify the check-runner script path.", call. = FALSE)
}
script_path <- normalizePath(sub("^--file=", "", script_argument), mustWork = TRUE)
source(file.path(dirname(script_path), "check-note-policy.R"), local = TRUE)
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
note_blocks <- release_note_blocks(check_lines)
classification <- release_classify_notes(
  check_status,
  note_blocks,
  note_policy
)
effective_status <- classification$effective_status

result <- list(
  schema_version = "1.1.0",
  job_label = job_label,
  command = "R CMD check --as-cran --no-manual <exact-source-archive>",
  exit_code = as.integer(status),
  check_status = check_status,
  effective_status = effective_status,
  note_policy = note_policy,
  explained_notes = classification$explained_notes,
  note_blocks = note_blocks,
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
