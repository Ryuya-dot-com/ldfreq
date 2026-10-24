#!/usr/bin/env Rscript

arguments <- commandArgs(trailingOnly = TRUE)
if (!length(arguments) %in% c(3L, 4L, 5L)) {
  stop(
    paste(
      "Usage: run-as-cran-check.R /path/to/source.tar.gz",
      "/new/output/directory job-label [note-policy] [completed-check-directory]"
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
note_policy <- if (length(arguments) >= 4L) {
  arguments[[4L]]
} else {
  "new-submission-only"
}
if (!nzchar(job_label)) stop("job-label must not be empty.", call. = FALSE)
allowed_note_policies <- c(
  "new-submission-only",
  "release-resource-notes",
  "minimum-r-optional-backends"
)
if (!note_policy %in% allowed_note_policies) {
  stop("Unrecognized check NOTE policy: ", note_policy, call. = FALSE)
}
if (identical(note_policy, "minimum-r-optional-backends") &&
    (!identical(job_label, "ubuntu-24.04-r-4.1") ||
      !grepl("^R version 4[.]1[.]", R.version.string))) {
  stop(
    paste(
      "The minimum-r-optional-backends NOTE policy is restricted to the",
      "ubuntu-24.04-r-4.1 job running R 4.1.x."
    ),
    call. = FALSE
  )
}
remote_url_checks <- !tolower(Sys.getenv(
  "_R_CHECK_CRAN_INCOMING_SKIP_URL_CHECKS_IF_REMOTE_", "false"
)) %in% c("true", "t", "1")
if (!identical(remote_url_checks, job_label != "ubuntu-24.04-r-4.1")) {
  stop("Remote URL checks may be delegated only by the R 4.1 diagnostic.", call. = FALSE)
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
reused_check <- NULL
classification_environment <- list(os = unname(Sys.info()[["sysname"]]),
  platform = R.version$platform, r_version = R.version.string,
  remote_url_checks = remote_url_checks)
if (length(arguments) == 5L) {
  prior_root <- normalizePath(arguments[[5L]], winslash = "/", mustWork = TRUE)
  prior_path <- file.path(prior_root, "check-result.json")
  prior <- jsonlite::read_json(prior_path, simplifyVector = FALSE)
  stopifnot(identical(prior$schema_version, "1.2.0"),
    identical(prior$job_label, job_label), identical(prior$note_policy, note_policy),
    identical(as.integer(prior$exit_code), 0L),
    identical(prior$command, "R CMD check --as-cran --no-manual <exact-source-archive>"),
    identical(prior$environment$os, unname(Sys.info()[["sysname"]])),
    identical(prior$environment$platform, R.version$platform),
    identical(prior$environment$r_version, R.version.string) ||
      (identical(job_label, "ubuntu-24.04-r-devel") &&
        grepl("^R Under development ", prior$environment$r_version) &&
        grepl("^R Under development ", R.version.string)),
    identical(prior$environment$remote_url_checks, remote_url_checks),
    identical(prior$artifact$sha256, digest::digest(file = source_archive, algo = "sha256")),
    identical(as.numeric(prior$artifact$bytes), as.numeric(file.info(source_archive)$size)))
  for (path in list.files(prior_root, recursive = TRUE, full.names = TRUE)) {
    relative <- substring(normalizePath(path, winslash = "/"), nchar(prior_root) + 2L)
    if (identical(relative, "check-result.json")) relative <- "check-result-before-reclassification.json"
    destination <- file.path(output_root, relative)
    dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
    stopifnot(file.copy(path, destination))
  }
  started <- prior$started_at_utc; finished <- prior$finished_at_utc
  status <- as.integer(prior$exit_code)
  reused_check <- list(run_id = Sys.getenv("CHECK_EVIDENCE_RUN"),
    original_result_sha256 = digest::digest(file = prior_path, algo = "sha256"),
    original_effective_status = prior$effective_status,
    classification_environment = classification_environment,
    reclassified_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
} else {
  started <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  status <- system2(file.path(R.home("bin"), "R"),
    args = c("CMD", "check", "--as-cran", "--no-manual", shQuote(source_archive)),
    stdout = log_path, stderr = log_path)
  finished <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

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
if (!is.null(reused_check)) {
  stopifnot(identical(prior$check_status, check_status),
    identical(prior$note_blocks, note_blocks))
  for (stage in c("examples", "tests", "re-building of vignette outputs")) {
    stopifnot(any(grepl(paste0("^\\* checking ", stage, " \\.\\.\\. .*OK$"), check_lines)))
  }
}
classification <- release_classify_notes(
  check_status,
  note_blocks,
  note_policy,
  job_label
)
effective_status <- classification$effective_status

result <- list(
  schema_version = "1.2.0",
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
  reused_check = reused_check,
  environment = if (is.null(reused_check)) classification_environment else prior$environment,
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
