.tubelex_diagnostic_validate <- function(x, id) {
  fail <- function() stop(sprintf(
    "Document %s has an invalid TUBELEX profile; use the unmodified result.",
    encodeString(id, quote = '"')), call. = FALSE)
  if (!inherits(x, "tubelex_profile") || !is.list(x) ||
      !.lexprep_is_plain_choice(x$status, c("ok", "empty", "invalid_input", "resource_error")) ||
      !is.list(x$provenance) || !is.list(x$coverage) || !is.list(x$diagnostics) ||
      !identical(x$provenance$contract_id, .tubelex_profile_contract_id) ||
      !identical(x$provenance$contract_version, "0.2.0")) fail()
  p <- x$provenance
  if (!identical(p$resource, .lexres_resource_ref(.lexres_tubelex_expectation())) ||
      !identical(p$lookup, .lexres_lookup_ref()) ||
      !.lexprep_is_plain_choice(p$query_normalization, names(.tubelex_normalization_ids)) ||
      !identical(p$query_normalization_id, unname(.tubelex_normalization_ids[p$query_normalization])) ||
      !.lexprep_is_plain_choice(p$tokenization_alignment,
        c("caller_supplied_terms_unverified", "known_different_tokenizer_explicitly_allowed")) ||
      !.lexprep_is_plain_choice(p$input_source, c("character_terms", "lexdiv_tokenization"))) fail()
  if (identical(p$input_source, "character_terms")) {
    if (!is.null(p$preprocessing_ref) ||
        !identical(p$tokenization_alignment, "caller_supplied_terms_unverified")) fail()
  } else {
    prep <- p$preprocessing_ref
    fields <- c("tokenizer_id", "tokenizer_version", "normalization", "case")
    if (!is.list(prep) || !all(vapply(fields, function(field)
        .lexprep_is_path_free_identifier(prep[[field]]), logical(1))) ||
        !is.logical(prep$keep_numbers) || length(prep$keep_numbers) != 1L ||
        is.na(prep$keep_numbers) ||
        !identical(p$tokenization_alignment, "known_different_tokenizer_explicitly_allowed")) fail()
  }
  lookup <- x$lookup
  columns <- c("query_index", "term", "lookup_term", "matched", "resource_word",
    "count", "videos", "channels", "zipf", "video_prevalence", "channel_prevalence")
  if (!is.data.frame(lookup) || !identical(names(lookup), columns) ||
      !identical(lookup$query_index, seq_len(nrow(lookup))) ||
      !.lexres_lookup_input(lookup$term)$ok || !.lexres_lookup_input(lookup$lookup_term)$ok ||
      !is.logical(lookup$matched) || !is.character(lookup$resource_word) ||
      !all(vapply(lookup[columns[6:11]], is.numeric, logical(1)))) fail()
  if (!identical(lookup$lookup_term, .tubelex_normalize(lookup$term, p$query_normalization))) fail()
  resolved <- x$status %in% c("ok", "empty")
  if (resolved) {
    if (anyNA(lookup$matched) ||
        !identical(x$status, if (nrow(lookup)) "ok" else "empty") ||
        !identical(x$failure_reason, NA_character_)) fail()
    matched <- lookup$matched
    if (!identical(lookup$resource_word[matched], lookup$lookup_term[matched]) ||
        any(!is.na(lookup$resource_word[!matched])) ||
        !all(vapply(lookup[columns[6:11]], function(v)
          all(is.finite(v[matched])) && all(is.na(v[!matched])), logical(1)))) fail()
    expected_coverage <- .lexres_lookup_coverage(lookup$lookup_term, matched)
    expected_summary <- .tubelex_profile_summary(lookup, expected_coverage)
  } else {
    if (!.lexprep_is_path_free_identifier(x$failure_reason) ||
        any(!is.na(lookup$matched)) || any(!is.na(lookup$resource_word)) ||
        !all(vapply(lookup[columns[6:11]], function(v) all(is.na(v)), logical(1)))) fail()
    if (identical(x$status, "invalid_input")) {
      if (nrow(lookup) || !.lexprep_is_count(x$coverage$input_tokens)) fail()
      expected_coverage <- .lexres_lookup_coverage(supplied_elements = x$coverage$input_tokens)
    } else {
      expected_coverage <- .lexres_lookup_coverage(lookup$lookup_term)
    }
    expected_summary <- .tubelex_empty_summary()
  }
  if (!identical(x$coverage, expected_coverage) ||
      !isTRUE(all.equal(x$summary, expected_summary, tolerance = 1e-14))) fail()
  invisible(x)
}

#' Make reusable tables from existing TUBELEX profiles
#'
#' Keeps document IDs, failure states, denominators and input alignment beside
#' frequency summaries, and counts unmatched terms and normalization mappings.
#' No tokenization, resource lookup or network access is performed.
#'
#' @param x One [tubelex_profile()] result or the plain named list returned by
#'   [tubelex_profile_batch()]. A zero-document named list is allowed.
#' @param max_rows Maximum number of input lookup rows plus two summary rows
#'   per document, checked before constructing aggregate tables.
#' @return A plain list with `summary`, `documents`, `unmatched_terms`,
#'   `normalization_mappings`, `provenance`, and `diagnostics`. Metadata lists
#'   retain each complete document record; the input profiles are unmodified.
#' @export
tubelex_diagnostics <- function(x, max_rows = 1e6) {
  max_rows <- .profile_positive_integer(max_rows, "max_rows")
  if (inherits(x, "tubelex_profile")) x <- list(document_1 = x)
  if (!is.list(x) || is.object(x) || !identical(names(attributes(x)), "names")) {
    stop("x must be one TUBELEX profile or a plain named list of profiles.", call. = FALSE)
  }
  ids <- .lex_batch_validate_ids(names(x), length(x))
  rows <- vapply(x, function(profile) {
    if (!is.list(profile) || !is.data.frame(profile$lookup)) {
      stop("x must contain unmodified TUBELEX profiles.", call. = FALSE)
    }
    as.double(nrow(profile$lookup))
  }, double(1))
  if (sum(rows) + 2 * length(x) > max_rows) {
    stop("The requested TUBELEX diagnostic input exceeds max_rows.", call. = FALSE)
  }
  for (i in seq_along(x)) .tubelex_diagnostic_validate(x[[i]], ids[i])
  # Condition IDs prevent pooling counts across differing query/input settings.
  # Equal settings on unverified vectors do not establish tokenizer equivalence.
  setting_fields <- c("profile_version", "resource_id", "resource_version",
    "query_normalization", "tokenization_alignment", "input_source",
    "tokenizer_id", "tokenizer_version", "text_normalization", "text_case", "keep_numbers")
  settings <- as.data.frame(stats::setNames(rep(list(character()), length(setting_fields)),
    setting_fields), stringsAsFactors = FALSE)
  pieces <- lapply(x, function(profile) {
    p <- profile$provenance; prep <- p$preprocessing_ref
    text <- function(value) if (is.null(value)) NA_character_ else as.character(value)
    data.frame(profile_version = p$contract_version, resource_id = p$resource$resource_id,
      resource_version = p$resource$resource_version, query_normalization = p$query_normalization,
      tokenization_alignment = p$tokenization_alignment, input_source = p$input_source,
      tokenizer_id = text(prep$tokenizer_id), tokenizer_version = text(prep$tokenizer_version),
      text_normalization = text(prep$normalization), text_case = text(prep$case),
      keep_numbers = text(prep$keep_numbers), stringsAsFactors = FALSE)
  })
  if (length(pieces)) settings <- do.call(rbind, pieces)
  key <- if (nrow(settings)) do.call(paste, c(lapply(settings,
    function(v) match(v, unique(v))), sep = ":")) else character()
  condition_id <- if (length(key)) paste0("condition_", match(key, unique(key))) else character()
  documents <- data.frame(document_id = ids, condition_id = condition_id,
    status = vapply(x, `[[`, character(1), "status"),
    failure_reason = vapply(x, `[[`, character(1), "failure_reason"),
    settings, stringsAsFactors = FALSE)
  for (field in names(.lexres_lookup_coverage(character(), logical()))) {
    documents[[field]] <- vapply(x, function(profile) profile$coverage[[field]], double(1))
  }
  summary <- data.frame(document_id = character(), condition_id = character(),
    status = character(), failure_reason = character(),
    .tubelex_empty_summary()[FALSE, ], stringsAsFactors = FALSE)
  summary_pieces <- lapply(seq_along(x), function(i) {
    data.frame(document_id = ids[i], condition_id = condition_id[i],
      status = x[[i]]$status, failure_reason = x[[i]]$failure_reason,
      x[[i]]$summary, stringsAsFactors = FALSE)
  })
  if (length(summary_pieces)) summary <- do.call(rbind, summary_pieces)
  lookup <- data.frame(document_id = character(), condition_id = character(),
    term = character(), lookup_term = character(), matched = logical(), stringsAsFactors = FALSE)
  lookup_pieces <- lapply(seq_along(x), function(i) {
    table <- x[[i]]$lookup
    data.frame(document_id = rep.int(ids[i], nrow(table)),
      condition_id = rep.int(condition_id[i], nrow(table)),
      table[c("term", "lookup_term", "matched")], stringsAsFactors = FALSE)
  })
  if (length(lookup_pieces)) lookup <- do.call(rbind, lookup_pieces)
  unmatched <- .nj8_diagnostic_counts(lookup[lookup$matched %in% FALSE, , drop = FALSE],
    c("condition_id", "lookup_term"))
  mappings <- .nj8_diagnostic_counts(lookup,
    c("condition_id", "term", "lookup_term", "matched"))
  mappings$lookup_changed <- mappings$term != mappings$lookup_term
  mappings$number_marker <- mappings$lookup_term == "<num>"
  rownames(documents) <- rownames(summary) <- NULL
  list(summary = summary, documents = documents, unmatched_terms = unmatched,
    normalization_mappings = mappings,
    provenance = stats::setNames(lapply(x, `[[`, "provenance"), ids),
    diagnostics = stats::setNames(lapply(x, `[[`, "diagnostics"), ids))
}
