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

# These two observed responses require a fresh successful identity check.
release_external_case <- function(block, label) {
  prefix <- block; prefix$detail <- head(block$detail, 2L)
  if (!release_new_submission_note(prefix)) return(NULL)
  lancaster <- paste0("https://www.lancaster.ac.uk/news/articles/2017/",
    "researchers-release-largest-ever-public-collection-of-british-conversations/")
  cases <- list(
    "windows-latest-r-release" = list(id = "lancaster-dns", url = lancaster,
      verification_url = lancaster,
      identity = "Researchers release largest ever public collection of British conversations",
      detail = c("Found the following (possibly) invalid URLs:", paste("URL:", lancaster),
        "From: inst/doc/designing-comparisons.html", "Status: Error",
        "Message: libcurl error code 6:", "Could not resolve host: www.lancaster.ac.uk")),
    "ubuntu-24.04-r-4.1" = list(id = "mattr-doi-403",
      url = "https://doi.org/10.1080/09296171003643098",
      verification_url = "https://api.crossref.org/works/10.1080%2F09296171003643098",
      identity = "10.1080/09296171003643098",
      detail = c("Found the following (possibly) invalid DOIs:",
        "DOI: 10.1080/09296171003643098", "From: DESCRIPTION",
        "Status: Forbidden", "Message: 403")))
  if (is.null(label) || length(label) != 1L) return(NULL)
  case <- cases[[label]]
  if (is.null(case) || !identical(unlist(block$detail[-c(1L, 2L)], use.names = FALSE),
      case$detail)) return(NULL)
  case
}

release_external_verified <- function(case, records) {
  if (is.null(case) || length(records) != 1L) return(FALSE)
  proof <- records[[1L]]
  identical(proof$id, case$id) && identical(proof$url, case$url) &&
    identical(proof$verification_url, case$verification_url) &&
    identical(as.integer(proof$status), 200L) && identical(proof$identity, case$identity) &&
    is.character(proof$body_sha256) && length(proof$body_sha256) == 1L &&
    grepl("^[0-9a-f]{64}$", proof$body_sha256) &&
    is.character(proof$checked_at_utc) && length(proof$checked_at_utc) == 1L &&
    grepl("^[0-9-]+T[0-9:]+Z$", proof$checked_at_utc)
}

release_recheck_external <- function(case) {
  response <- curl::curl_fetch_memory(case$verification_url,
    curl::new_handle(timeout = 60, followlocation = TRUE))
  stopifnot(response$status_code == 200L)
  body <- rawToChar(response$content)
  if (case$id == "mattr-doi-403") {
    metadata <- jsonlite::fromJSON(body)$message
    stopifnot(identical(metadata$DOI, case$identity),
      any(grepl("Cutting the Gordian Knot", metadata$title, fixed = TRUE)))
  } else {
    stopifnot(grepl(case$identity, body, fixed = TRUE))
  }
  list(id = case$id, url = case$url, verification_url = case$verification_url,
    status = as.integer(response$status_code), identity = case$identity,
    verification_environment = list(os = unname(Sys.info()[["sysname"]]),
      platform = R.version$platform, r_version = R.version.string),
    body_sha256 = digest::digest(response$content, algo = "sha256", serialize = FALSE),
    checked_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
}

release_classify_notes <- function(check_status, note_blocks, note_policy, job_label = NULL,
                                   external_verifications = NULL) {
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
        release_external_verified(release_external_case(block, job_label), external_verifications))
      return("incoming_external")
    if (note_policy == "minimum-r-optional-backends" &&
        release_unavailable_backends_note(block)) return("backends")
    if (note_policy != "new-submission-only" &&
        release_resource_size_note(block)) return("size")
    "unknown"
  }, character(1L))
  if ("unknown" %in% kinds || anyDuplicated(sub("^incoming.*$", "incoming", kinds)) ||
      (note_policy == "minimum-r-optional-backends" && !"backends" %in% kinds)) return(fail)
  dispositions <- list(
    incoming_external = list(note = "New submission with a separately verified external response",
      disposition = paste("The original DNS/DOI response remains in the raw log.",
        "A fresh HTTP 200 response and expected page/DOI identity are recorded in external_verifications.",
        "Current-R peer checks of the same artifact must have clean incoming URL/DOI results.")),
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
