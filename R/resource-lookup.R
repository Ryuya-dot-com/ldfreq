# Internal, non-exported lexical-resource lookup and result contract.
#
# This layer intentionally preserves query terms. It does not reproduce the
# source-build normalization recorded by the TUBELEX manifest, and it never
# turns an unmatched term into a fabricated zero-frequency observation.

.lexres_lookup_contract_id <- "ldfreq-lexical-resource-lookup"
.lexres_lookup_contract_version <- "0.1.0-draft.1"
.lexres_lookup_result_schema_id <- "lexres-frequency-prevalence-result"
.lexres_lookup_result_schema_version <- "0.1.0-draft.1"
.lexres_lookup_query_normalization_id <- "identity-valid-utf8-v1"
.lexres_lookup_matching_id <- "exact-unicode-scalar-sequence-v1"
.lexres_tubelex_artifact_id <- "tubelex_en_treebank_slim_csv_gz"

.lexres_tubelex_formula_parameters <- list(
  token_total = 171805865,
  source_vocabulary_size = 613309,
  video_total = 105733,
  channel_total = 68405
)

.lexres_lookup_ref <- function() {
  list(
    contract_id = .lexres_lookup_contract_id,
    contract_version = .lexres_lookup_contract_version,
    result_schema_id = .lexres_lookup_result_schema_id,
    result_schema_version = .lexres_lookup_result_schema_version,
    lookup_unit = "surface-form",
    query_normalization_id = .lexres_lookup_query_normalization_id,
    matching_id = .lexres_lookup_matching_id
  )
}

.lexres_lookup_input <- function(terms) {
  plain_container <- is.character(terms) &&
    !is.object(terms) &&
    is.null(dim(terms)) &&
    is.null(attributes(terms))
  if (!plain_container) {
    return(list(
      ok = FALSE,
      terms = NULL,
      supplied_elements = as.double(length(terms)),
      invalid_indices = integer(),
      violations = "invalid_container"
    ))
  }
  if (!length(terms)) {
    return(list(
      ok = TRUE,
      terms = character(),
      supplied_elements = 0,
      invalid_indices = integer(),
      violations = character()
    ))
  }

  missing <- is.na(terms)
  empty <- !missing & !nzchar(terms)
  unsupported_encoding <- !missing & Encoding(terms) %in% c("bytes", "latin1")
  invalid_utf8 <- !missing & !unsupported_encoding & !validUTF8(terms)
  invalid <- missing | empty | unsupported_encoding | invalid_utf8
  if (any(invalid)) {
    violations <- character()
    if (any(missing)) violations <- c(violations, "missing_term")
    if (any(empty)) violations <- c(violations, "empty_term")
    if (any(unsupported_encoding)) {
      violations <- c(violations, "unsupported_encoding")
    }
    if (any(invalid_utf8)) violations <- c(violations, "invalid_utf8")
    return(list(
      ok = FALSE,
      terms = NULL,
      supplied_elements = as.double(length(terms)),
      invalid_indices = which(invalid),
      violations = violations
    ))
  }

  Encoding(terms) <- "UTF-8"
  list(
    ok = TRUE,
    terms = terms,
    supplied_elements = as.double(length(terms)),
    invalid_indices = integer(),
    violations = character()
  )
}

.lexres_empty_lookup_results <- function(terms = character(), unresolved = FALSE) {
  row_count <- length(terms)
  matched <- if (unresolved) rep.int(NA, row_count) else logical(row_count)
  data.frame(
    query_index = seq_along(terms),
    term = terms,
    matched = matched,
    resource_word = rep.int(NA_character_, row_count),
    count = rep.int(NA_real_, row_count),
    videos = rep.int(NA_real_, row_count),
    channels = rep.int(NA_real_, row_count),
    zipf = rep.int(NA_real_, row_count),
    video_prevalence = rep.int(NA_real_, row_count),
    channel_prevalence = rep.int(NA_real_, row_count),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexres_lookup_coverage <- function(terms = NULL, matched = NULL, supplied_elements = NULL) {
  if (is.null(terms)) {
    return(list(
      input_tokens = as.double(supplied_elements),
      input_types = NA_real_,
      eligible_tokens = NA_real_,
      eligible_types = NA_real_,
      matched_tokens = NA_real_,
      unmatched_tokens = NA_real_,
      matched_types = NA_real_,
      unmatched_types = NA_real_,
      token_coverage = NA_real_,
      type_coverage = NA_real_
    ))
  }

  types <- unique(terms)
  input_tokens <- as.double(length(terms))
  input_types <- as.double(length(types))
  if (is.null(matched)) {
    return(list(
      input_tokens = input_tokens,
      input_types = input_types,
      eligible_tokens = input_tokens,
      eligible_types = input_types,
      matched_tokens = NA_real_,
      unmatched_tokens = NA_real_,
      matched_types = NA_real_,
      unmatched_types = NA_real_,
      token_coverage = NA_real_,
      type_coverage = NA_real_
    ))
  }

  matched_tokens <- as.double(sum(matched))
  type_first <- match(types, terms)
  matched_types <- as.double(sum(matched[type_first]))
  list(
    input_tokens = input_tokens,
    input_types = input_types,
    eligible_tokens = input_tokens,
    eligible_types = input_types,
    matched_tokens = matched_tokens,
    unmatched_tokens = input_tokens - matched_tokens,
    matched_types = matched_types,
    unmatched_types = input_types - matched_types,
    token_coverage = if (input_tokens == 0) NA_real_ else matched_tokens / input_tokens,
    type_coverage = if (input_types == 0) NA_real_ else matched_types / input_types
  )
}

.lexres_invalid_lookup <- function(input) {
  list(
    status = "invalid_input",
    failure_reason = "invalid_term",
    lookup_ref = .lexres_lookup_ref(),
    resource_ref = .lexres_resource_ref(.lexres_tubelex_expectation()),
    results = .lexres_empty_lookup_results(),
    coverage = .lexres_lookup_coverage(
      supplied_elements = input$supplied_elements
    ),
    diagnostics = list(
      input_state = "invalid",
      invalid_indices = input$invalid_indices,
      input_violations = input$violations,
      normalization_applied = FALSE,
      fallback_attempted = FALSE,
      download_attempted = FALSE
    )
  )
}

.lexres_resource_lookup_failure <- function(terms, loaded) {
  list(
    status = "resource_error",
    failure_reason = loaded$failure_reason,
    lookup_ref = .lexres_lookup_ref(),
    resource_ref = loaded$resource_ref,
    results = .lexres_empty_lookup_results(terms, unresolved = TRUE),
    coverage = .lexres_lookup_coverage(terms),
    diagnostics = list(
      input_state = "ok",
      invalid_indices = integer(),
      input_violations = character(),
      normalization_applied = FALSE,
      fallback_attempted = loaded$diagnostics$fallback_attempted,
      download_attempted = loaded$diagnostics$download_attempted,
      resource_diagnostics = loaded$diagnostics
    )
  )
}

.lexres_validate_loaded_tubelex <- function(loaded) {
  expected_ref <- .lexres_resource_ref(.lexres_tubelex_expectation())
  if (
    !is.list(loaded) || is.object(loaded) ||
      !identical(loaded$status, "ok") ||
      !identical(loaded$failure_reason, NA_character_) ||
      !identical(loaded$resource_ref, expected_ref) ||
      !is.list(loaded$manifest) ||
      !identical(loaded$manifest$lookup_unit, "surface-form") ||
      !identical(
        loaded$manifest$normalization_id,
        "nfkc-trim-root-lower-filtered-source-keys-v1"
      ) ||
      !is.list(loaded$diagnostics) ||
      !identical(loaded$diagnostics$fallback_attempted, FALSE) ||
      !identical(loaded$diagnostics$download_attempted, FALSE) ||
      !is.list(loaded$resource) ||
      !(.lexres_tubelex_artifact_id %in% names(loaded$resource))
  ) {
    .lexres_stop("Internal error: lookup requires a validated TUBELEX load result.")
  }

  resource <- loaded$resource[[.lexres_tubelex_artifact_id]]
  expected_names <- c("word", "count", "videos", "channels", "totals")
  if (!is.list(resource) || is.object(resource) ||
      !identical(names(resource), expected_names) ||
      !identical(
        resource$totals,
        list(count = 171805865, videos = 105733, channels = 68405)
      )) {
    .lexres_stop("Internal error: the TUBELEX lookup resource shape changed.")
  }
  row_count <- length(resource$word)
  if (
    !is.character(resource$word) || is.object(resource$word) ||
      !is.null(dim(resource$word)) || !is.null(attributes(resource$word)) ||
      anyNA(resource$word) || any(!nzchar(resource$word)) ||
      any(Encoding(resource$word) %in% c("bytes", "latin1")) ||
      any(!validUTF8(resource$word)) || anyDuplicated(resource$word) ||
      !all(vapply(resource[c("count", "videos", "channels")], function(field) {
        is.numeric(field) && !is.object(field) && is.null(dim(field)) &&
          is.null(attributes(field)) &&
          identical(length(field), row_count) &&
          !anyNA(field) && all(is.finite(field)) && all(field >= 0)
      }, logical(1L))) ||
      any(resource$channels > resource$videos) ||
      any(resource$videos > resource$count)
  ) {
    .lexres_stop("Internal error: the TUBELEX lookup resource is not canonical.")
  }
  resource
}

.lexres_lookup_loaded_tubelex <- function(terms, loaded) {
  if (!is.list(loaded) || is.object(loaded) ||
      (!identical(loaded$status, "ok") &&
        !identical(loaded$status, "resource_error"))) {
    .lexres_stop("Internal error: the resource loader returned an invalid status.")
  }
  if (identical(loaded$status, "resource_error")) {
    if (
      !is.character(loaded$failure_reason) ||
        length(loaded$failure_reason) != 1L ||
        is.na(loaded$failure_reason) ||
        !(loaded$failure_reason %in% .lexres_failures) ||
        !is.list(loaded$diagnostics) ||
        !identical(loaded$diagnostics$fallback_attempted, FALSE) ||
        !identical(loaded$diagnostics$download_attempted, FALSE)
    ) {
      .lexres_stop("Internal error: the resource loader returned an invalid failure.")
    }
    return(.lexres_resource_lookup_failure(terms, loaded))
  }

  resource <- .lexres_validate_loaded_tubelex(loaded)
  row_indexes <- match(terms, resource$word)
  matched <- !is.na(row_indexes)
  results <- .lexres_empty_lookup_results(terms)
  results$matched <- matched
  if (any(matched)) {
    result_indexes <- which(matched)
    resource_indexes <- row_indexes[matched]
    results$resource_word[result_indexes] <- resource$word[resource_indexes]
    results$count[result_indexes] <- resource$count[resource_indexes]
    results$videos[result_indexes] <- resource$videos[resource_indexes]
    results$channels[result_indexes] <- resource$channels[resource_indexes]

    parameters <- .lexres_tubelex_formula_parameters
    results$zipf[result_indexes] <- log10(
      1e9 * (results$count[result_indexes] + 1) /
        (parameters$token_total + parameters$source_vocabulary_size)
    )
    results$video_prevalence[result_indexes] <- log10(
      (results$videos[result_indexes] + 1) / (parameters$video_total + 2)
    )
    results$channel_prevalence[result_indexes] <- log10(
      (results$channels[result_indexes] + 1) /
        (parameters$channel_total + 2)
    )
  }

  list(
    status = "ok",
    failure_reason = NA_character_,
    lookup_ref = .lexres_lookup_ref(),
    resource_ref = loaded$resource_ref,
    results = results,
    coverage = .lexres_lookup_coverage(terms, matched),
    diagnostics = list(
      input_state = "ok",
      invalid_indices = integer(),
      input_violations = character(),
      normalization_applied = FALSE,
      duplicate_query_count = as.double(length(terms) - length(unique(terms))),
      order_preserved = TRUE,
      unmatched_values_are_missing = TRUE,
      fallback_attempted = FALSE,
      download_attempted = FALSE,
      resource_key_normalization_id = loaded$manifest$normalization_id,
      formula_parameters = .lexres_tubelex_formula_parameters
    )
  )
}

.lexres_lookup_tubelex <- function(terms, loader = .lexres_load_tubelex) {
  input <- .lexres_lookup_input(terms)
  if (!isTRUE(input$ok)) return(.lexres_invalid_lookup(input))
  if (!identical(loader, .lexres_load_tubelex) && !is.function(loader)) {
    .lexres_stop("loader must be the internal TUBELEX loader or a test seam function.")
  }
  loaded <- loader()
  .lexres_lookup_loaded_tubelex(input$terms, loaded)
}
