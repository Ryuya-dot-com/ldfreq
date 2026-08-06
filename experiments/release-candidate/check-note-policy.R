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

release_unavailable_textstem_note <- function(note_block) {
  dependency_stage_pattern <- paste0(
    "^\\* checking package dependencies \\.\\.\\. ",
    "(\\[[^]]+\\] )?NOTE$"
  )
  textstem_pattern <- paste0(
    "^Package suggested but not available for checking: ",
    "[‘']textstem[’']$"
  )
  grepl(dependency_stage_pattern, note_block$stage) &&
    length(note_block$detail) == 1L &&
    grepl(textstem_pattern, note_block$detail[[1L]])
}

release_classify_notes <- function(check_status, note_blocks, note_policy) {
  allowed_policies <- c(
    "new-submission-only",
    "minimum-r-optional-textstem"
  )
  if (!note_policy %in% allowed_policies) {
    stop("Unrecognized check NOTE policy: ", note_policy, call. = FALSE)
  }
  if (identical(check_status, "Status: OK") && !length(note_blocks)) {
    return(list(effective_status = "PASS", explained_notes = list()))
  }

  new_submission_only <-
    identical(check_status, "Status: 1 NOTE") &&
    length(note_blocks) == 1L &&
    release_new_submission_note(note_blocks[[1L]])
  minimum_r_notes <-
    identical(note_policy, "minimum-r-optional-textstem") &&
    identical(check_status, "Status: 2 NOTEs") &&
    length(note_blocks) == 2L &&
    release_new_submission_note(note_blocks[[1L]]) &&
    release_unavailable_textstem_note(note_blocks[[2L]])

  if (new_submission_only) {
    return(list(
      effective_status = "PASS_WITH_EXPLAINED_NOTE",
      explained_notes = list(list(
        note = "New submission",
        disposition = paste(
          "Expected CRAN incoming note for a package version that has not",
          "previously been published on CRAN; no package defect is asserted."
        )
      ))
    ))
  }
  if (minimum_r_notes) {
    return(list(
      effective_status = "PASS_WITH_EXPLAINED_NOTES",
      explained_notes = list(
        list(
          note = "New submission",
          disposition = paste(
            "Expected CRAN incoming note for a package version that has not",
            "previously been published on CRAN; no package defect is asserted."
          )
        ),
        list(
          note = "Package suggested but not available for checking: textstem",
          disposition = paste(
            "Expected only in the declared R 4.1 minimum-version diagnostic:",
            "textstem is an optional backend, the workflow deliberately does",
            "not install it before R 4.4, and _R_CHECK_FORCE_SUGGESTS_ is false."
          )
        )
      )
    ))
  }
  list(effective_status = "FAIL", explained_notes = list())
}
