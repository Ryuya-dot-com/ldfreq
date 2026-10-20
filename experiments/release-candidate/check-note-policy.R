release_note_blocks <- function(check_lines) {
  note_positions <- grep("^\\* checking .* NOTE$", check_lines)
  check_positions <- grep("^\\* checking ", check_lines)
  lapply(note_positions, function(note_position) {
    next_positions <- check_positions[check_positions > note_position]
    note_end <- if (length(next_positions)) {
      next_positions[[1L]] - 1L
    } else {
      length(check_lines)
    }
    detail <- if (note_end > note_position) {
      check_lines[seq.int(note_position + 1L, note_end)]
    } else {
      character()
    }
    detail <- trimws(detail)
    detail <- detail[nzchar(detail)]
    list(stage = check_lines[[note_position]], detail = as.list(detail))
  })
}

release_new_submission_note <- function(note_block) {
  incoming_stage_pattern <- paste0(
    "^\\* checking CRAN incoming feasibility \\.\\.\\. ",
    "(\\[[^]]+\\] )?NOTE$"
  )
  maintainer_pattern <- paste0(
    "^Maintainer: [‘']?[^<>[:cntrl:]]+ ",
    "<[^<>[:space:]]+@[^<>[:space:]]+>[’']?[[:space:]]*$"
  )
  grepl(incoming_stage_pattern, note_block$stage) &&
    length(note_block$detail) == 2L &&
    grepl(maintainer_pattern, note_block$detail[[1L]]) &&
    identical(note_block$detail[[2L]], "New submission")
}

release_unavailable_backends_note <- function(note_block) {
  dependency_stage_pattern <- paste0(
    "^\\* checking package dependencies \\.\\.\\. ",
    "(\\[[^]]+\\] )?NOTE$"
  )
  detail <- gsub("[‘’]", "'", paste(unlist(note_block$detail), collapse = " "))
  expected <- "Packages suggested but not available for checking: 'gibasa', 'textstem'"
  grepl(dependency_stage_pattern, note_block$stage) &&
    identical(detail, expected)
}

release_non_foss_submission_note <- function(note_block) {
  if (length(note_block$detail) != 3L ||
      !identical(note_block$detail[[3L]], "Non-FOSS package license (file LICENSE)")) return(FALSE)
  note_block$detail <- note_block$detail[1:2]
  release_new_submission_note(note_block)
}

release_recorded_external_note <- function(note_block, job_label) {
  # Exact responses from the 0.4.0 artifact check, not a general URL exception.
  # The named references were verified against publisher/provider records and
  # successful peer checks of the same archive. Preserve the failed responses.
  cases <- list(
    "ubuntu-latest-r-4.1" = c(
      "Found the following (possibly) invalid DOIs:",
      "DOI: 10.1080/09296171003643098", "From: DESCRIPTION",
      "Status: Forbidden", "Message: 403", "Size of tarball: 6490351 bytes"),
    "ubuntu-latest-r-devel" = c(
      "Found the following (possibly) invalid URLs:",
      "URL: https://sites.psu.edu/xxl13/l2sca/",
      "From: inst/doc/syntactic-complexity.html", "Status: Error",
      "Message: libcurl error code 28:", "Connection timed out after 60000 milliseconds"),
    "windows-latest-r-release" = c(
      "Found the following (possibly) invalid URLs:",
      "URL: https://uclouvain.be/en/research-institutes/ilc/cecl/locness",
      "From: inst/doc/designing-comparisons.html", "Status: Error",
      "Message: libcurl error code 28:",
      "Failed to connect to uclouvain.be port 443 after 21175 ms: Could not connect to server")
  )
  if (is.null(job_label) || !job_label %in% names(cases)) return(FALSE)
  prefix <- note_block; prefix$detail <- prefix$detail[seq_len(3L)]
  release_non_foss_submission_note(prefix) &&
    identical(unlist(note_block$detail[-seq_len(3L)], use.names = FALSE), cases[[job_label]])
}

release_resource_size_note <- function(note_block) {
  stage <- "^\\* checking installed package size \\.\\.\\. (\\[[^]]+\\] )?NOTE$"
  detail <- unlist(note_block$detail, use.names = FALSE)
  if (!grepl(stage, note_block$stage) || length(detail) < 4L ||
      !grepl("^installed size is [0-9]+[.][0-9]+Mb$", detail[[1L]]) ||
      !identical(detail[[2L]], "sub-directories of 1Mb or more:")) return(FALSE)
  total <- as.numeric(sub("^installed size is ([0-9.]+)Mb$", "\\1", detail[[1L]]))
  rows <- detail[-c(1L, 2L)]
  if (!all(grepl("^(R|doc|extdata) +[0-9]+[.][0-9]+Mb$", rows))) return(FALSE)
  directories <- sub(" +.*$", "", rows)
  sizes <- as.numeric(sub("^[^ ]+ +([0-9.]+)Mb$", "\\1", rows))
  # Baseline 9019 is 10.9 MiB; bound filesystem differences and reject new payload areas.
  total > 5 && total <= 15 && !anyDuplicated(directories) &&
    all(c("doc", "extdata") %in% directories) &&
    all(sizes >= 1 & sizes <= total) && sum(sizes) <= total + 0.2
}

release_classify_notes <- function(check_status, note_blocks, note_policy, job_label = NULL) {
  allowed_policies <- c("new-submission-only", "release-resource-notes",
    "minimum-r-optional-backends")
  if (!note_policy %in% allowed_policies) {
    stop("Unrecognized check NOTE policy: ", note_policy, call. = FALSE)
  }
  fail <- list(effective_status = "FAIL", explained_notes = list())
  count <- length(note_blocks)
  expected <- if (!count) "Status: OK" else if (count == 1L) "Status: 1 NOTE" else
    paste("Status:", count, "NOTEs")
  if (!identical(check_status, expected)) return(fail)
  kinds <- vapply(note_blocks, function(block) {
    if (release_new_submission_note(block)) return("incoming")
    if (note_policy != "new-submission-only" &&
        release_non_foss_submission_note(block)) return("incoming_non_foss")
    if (note_policy != "new-submission-only" &&
        release_recorded_external_note(block, job_label)) return("incoming_external")
    if (note_policy == "minimum-r-optional-backends" &&
        release_unavailable_backends_note(block)) return("backends")
    if (note_policy != "new-submission-only" &&
        release_resource_size_note(block)) return("size")
    "unknown"
  }, character(1L))
  if ("unknown" %in% kinds || anyDuplicated(sub("^incoming.*$", "incoming", kinds)) ||
      (note_policy == "minimum-r-optional-backends" && !"backends" %in% kinds)) return(fail)
  dispositions <- list(
    incoming = list(note = "New submission", disposition = paste(
      "Expected CRAN incoming note for a package version that has not",
      "previously been published on CRAN; no package defect is asserted.")),
    incoming_non_foss = list(note = "New submission; Non-FOSS package license (file LICENSE)",
      disposition = paste("The package is not on CRAN. Its component-specific LICENSE",
        "intentionally records non-FOSS terms, including bundled MorphoLex's",
        "CC BY-NC-SA 4.0 restriction; DESCRIPTION declares License_is_FOSS: no",
        "and License_restricts_use: yes. This disposition grants no additional rights.")),
    incoming_external = list(note = paste("New submission; Non-FOSS license; recorded external response in", job_label),
      disposition = paste("Only the exact recorded publisher/provider response is admitted.",
        "MATTR's DOI is confirmed by its publisher's article metadata; L2SCA and LOCNESS",
        "were reachable in independent/current-R checks of these references.",
        "The original HTTP 403 or connection timeout remains in the raw log.",
        "This is not a successful access claim for this runner, a waiver for other URLs,",
        "or permission to redistribute restricted resources.")),
    backends = list(
      note = "Packages suggested but not available for checking: gibasa, textstem",
      disposition = paste("Expected only in the declared R 4.1 minimum-version diagnostic:",
        "the optional backends need newer R (gibasa 4.2; textstem 4.4).",
        "The workflow deliberately omits them and _R_CHECK_FORCE_SUGGESTS_ is false.")),
    size = list(note = "Installed package size", disposition = paste(
      "The fixed release includes attributed reference data and rendered guides.",
      "The 9019 baseline is 10.9 MiB; only R/doc/extdata size rows within a",
      "15 MiB total are accepted. Source/platform/installed inventories and",
      "the file BOM independently verify the admitted payload.")))
  list(effective_status = if (!count) "PASS" else if (count == 1L)
    "PASS_WITH_EXPLAINED_NOTE" else "PASS_WITH_EXPLAINED_NOTES",
    explained_notes = unname(dispositions[kinds]))
}
