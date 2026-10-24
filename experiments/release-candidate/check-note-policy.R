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

release_resource_size_note <- function(note_block) {
  stage <- "^\\* checking installed package size \\.\\.\\. (\\[[^]]+\\] )?NOTE$"
  detail <- unlist(note_block$detail, use.names = FALSE)
  if (!grepl(stage, note_block$stage) || length(detail) < 3L ||
      !grepl("^installed size is +[0-9]+[.][0-9]+Mb$", detail[[1L]]) ||
      !identical(detail[[2L]], "sub-directories of 1Mb or more:")) return(FALSE)
  total <- as.numeric(sub("^installed size is +([0-9.]+)Mb$", "\\1", detail[[1L]]))
  rows <- detail[-c(1L, 2L)]
  if (!all(grepl("^(R|doc) +[0-9]+[.][0-9]+Mb$", rows))) return(FALSE)
  directories <- sub(" +.*$", "", rows)
  sizes <- as.numeric(sub("^[^ ]+ +([0-9.]+)Mb$", "\\1", rows))
  # Current reference-free package: rendered guides, not cached datasets.
  total > 5 && total <= 10 && !anyDuplicated(directories) &&
    "doc" %in% directories &&
    all(sizes >= 1 & sizes <= ifelse(directories == "doc", 5, 2)) &&
    sum(sizes) <= total + 0.2
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
    backends = list(
      note = "Packages suggested but not available for checking: gibasa, textstem",
      disposition = paste("Expected only in the declared R 4.1 minimum-version diagnostic:",
        "the optional backends need newer R (gibasa 4.2; textstem 4.4).",
        "The workflow deliberately omits them and _R_CHECK_FORCE_SUGGESTS_ is false.")),
    size = list(note = "Installed package size", disposition = paste(
      "The package contains rendered guides; optional reference data are downloaded separately.",
      "Only R/doc size rows within a 10 MiB total, at most 2 MiB of R code",
      "and 5 MiB of documentation, are accepted. Source/platform/installed inventories and",
      "the file BOM independently verify the admitted payload.")))
  list(effective_status = if (!count) "PASS" else if (count == 1L)
    "PASS_WITH_EXPLAINED_NOTE" else "PASS_WITH_EXPLAINED_NOTES",
    explained_notes = unname(dispositions[kinds]))
}
