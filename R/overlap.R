# Exact type-set overlap for explicit terms and annotated content words.

.lexoverlap_contract_id <- "ldfreq-lexical-overlap"
.lexoverlap_contract_version <- "0.1.0"
.lexoverlap_result_schema_id <- "lexdiv-type-overlap-result"
.lexoverlap_result_schema_version <- "0.1.0"
.lexoverlap_content_set_id <- "universal-pos-content-words"
.lexoverlap_content_set_version <- "0.1.0"

.lexoverlap_registry <- data.frame(
  measure_id = c(
    "jaccard_types",
    "dice_types",
    "a_covered_by_b_types",
    "b_covered_by_a_types",
    "overlap_coefficient_types"
  ),
  method_id = c(
    "jaccard_type_intersection_over_union_v1",
    "dice_type_twice_intersection_over_sum_v1",
    "a_covered_by_b_type_intersection_over_a_v1",
    "b_covered_by_a_type_intersection_over_b_v1",
    "overlap_coefficient_type_intersection_over_min_v1"
  ),
  symmetric = c(TRUE, TRUE, FALSE, FALSE, TRUE),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

#' List type-overlap measure identifiers
#'
#' Returns the identifiers accepted by [lexdiv_term_overlap()] and
#' [lexdiv_content_overlap()]. The set contains Jaccard, Dice, two directional
#' coverage measures, and the overlap coefficient. All are based on distinct
#' exact terms rather than token frequency.
#'
#' @return A character vector in default result order.
#' @export
lexdiv_overlap_ids <- function() {
  .lexoverlap_registry$measure_id
}

.lexoverlap_validate_measures <- function(measures) {
  if (
    !is.character(measures) || is.object(measures) || !is.null(dim(measures)) ||
      !is.null(attributes(measures)) || length(measures) == 0L ||
      anyNA(measures) || any(!nzchar(measures))
  ) {
    stop(
      "measures must be a non-empty plain character vector without missing values.",
      call. = FALSE
    )
  }
  if (anyDuplicated(measures)) {
    stop("measures must not contain duplicates.", call. = FALSE)
  }
  unknown <- setdiff(measures, lexdiv_overlap_ids())
  if (length(unknown) > 0L) {
    stop(
      sprintf("Unknown overlap measure ID(s): %s.", paste(unknown, collapse = ", ")),
      call. = FALSE
    )
  }
  measures
}

.lexoverlap_document_ids <- function(document_ids) {
  if (
    !is.character(document_ids) || is.object(document_ids) ||
      !is.null(dim(document_ids)) || !is.null(attributes(document_ids)) ||
      length(document_ids) != 2L || anyNA(document_ids) ||
      any(!nzchar(document_ids)) || anyDuplicated(document_ids) ||
      any(Encoding(document_ids) %in% c("bytes", "latin1")) ||
      any(!validUTF8(document_ids)) ||
      any(grepl("[[:cntrl:]]", document_ids)) ||
      any(vapply(document_ids, .lexprep_looks_like_path, logical(1L)))
  ) {
    stop(
      paste0(
        "document_ids must contain two distinct, path-free, plain, non-empty ",
        "valid-UTF-8 strings without control characters."
      ),
      call. = FALSE
    )
  }
  Encoding(document_ids) <- "UTF-8"
  document_ids
}

.lexoverlap_term_state <- function(terms) {
  if (
    !is.character(terms) || is.object(terms) || !is.null(dim(terms)) ||
      !is.null(attributes(terms))
  ) {
    return("invalid")
  }
  if (length(terms) == 0L) return("empty")
  if (
    anyNA(terms) || any(!nzchar(terms)) ||
      any(Encoding(terms) %in% c("bytes", "latin1")) ||
      any(!validUTF8(terms))
  ) {
    return("invalid")
  }
  "ok"
}

.lexoverlap_empty_shared <- function() {
  data.frame(
    term = character(),
    token_count_a = double(),
    token_count_b = double(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexoverlap_empty_unique <- function(side) {
  output <- data.frame(
    term = character(),
    token_count = double(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  names(output)[[2L]] <- paste0("token_count_", side)
  output
}

.lexoverlap_empty_exclusions <- function() {
  data.frame(
    document_id = character(),
    exclusion_reason = character(),
    token_count = double(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexoverlap_empty_comparability <- function() {
  data.frame(
    component = character(),
    value_a = character(),
    value_b = character(),
    matches = logical(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexoverlap_sorted_types <- function(terms) {
  types <- unique(terms)
  if (length(types) < 2L) return(types)
  types[order(types, method = "radix")]
}

.lexoverlap_type_counts <- function(terms, types) {
  if (length(types) == 0L) return(double())
  as.double(tabulate(match(terms, types), nbins = length(types)))
}

.lexoverlap_term_details <- function(terms_a, terms_b, types_a, types_b, details) {
  if (!identical(details, "terms")) {
    return(list(
      shared_terms = .lexoverlap_empty_shared(),
      unique_to_a = .lexoverlap_empty_unique("a"),
      unique_to_b = .lexoverlap_empty_unique("b")
    ))
  }
  counts_a <- .lexoverlap_type_counts(terms_a, types_a)
  counts_b <- .lexoverlap_type_counts(terms_b, types_b)
  shared <- types_a[types_a %in% types_b]
  only_a <- types_a[!(types_a %in% types_b)]
  only_b <- types_b[!(types_b %in% types_a)]
  list(
    shared_terms = data.frame(
      term = shared,
      token_count_a = counts_a[match(shared, types_a)],
      token_count_b = counts_b[match(shared, types_b)],
      stringsAsFactors = FALSE,
      check.names = FALSE
    ),
    unique_to_a = data.frame(
      term = only_a,
      token_count_a = counts_a[match(only_a, types_a)],
      stringsAsFactors = FALSE,
      check.names = FALSE
    ),
    unique_to_b = data.frame(
      term = only_b,
      token_count_b = counts_b[match(only_b, types_b)],
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  )
}

.lexoverlap_invalid_reason <- function(state_a, state_b) {
  if (identical(state_a, "invalid") && identical(state_b, "invalid")) {
    "invalid_terms_both"
  } else if (identical(state_a, "invalid")) {
    "invalid_terms_a"
  } else {
    "invalid_terms_b"
  }
}

.lexoverlap_summary <- function(
    measures,
    document_ids,
    type_count_a,
    type_count_b,
    shared_type_count,
    union_type_count,
    invalid_reason = NULL,
    empty_reason = "empty_term_sets") {
  registry <- .lexoverlap_registry[
    match(measures, .lexoverlap_registry$measure_id),
    ,
    drop = FALSE
  ]
  row_count <- nrow(registry)
  numerator <- rep.int(as.double(shared_type_count), row_count)
  denominator <- c(
    jaccard_types = union_type_count,
    dice_types = type_count_a + type_count_b,
    a_covered_by_b_types = type_count_a,
    b_covered_by_a_types = type_count_b,
    overlap_coefficient_types = min(type_count_a, type_count_b)
  )[measures]
  numerator[measures == "dice_types"] <- 2 * shared_type_count
  value <- rep.int(NA_real_, row_count)
  computable <- !is.na(numerator) & !is.na(denominator) & denominator != 0
  value[computable] <- numerator[computable] / denominator[computable]
  status <- rep.int("ok", row_count)
  missing_reason <- rep.int(NA_character_, row_count)

  if (!is.null(invalid_reason)) {
    numerator[] <- NA_real_
    denominator[] <- NA_real_
    value[] <- NA_real_
    status[] <- "invalid_input"
    missing_reason[] <- invalid_reason
  } else if (identical(type_count_a, 0L) && identical(type_count_b, 0L)) {
    value[] <- NA_real_
    status[] <- "missing"
    missing_reason[] <- empty_reason
  } else {
    zero_denominator <- denominator == 0
    value[zero_denominator] <- NA_real_
    status[zero_denominator] <- "missing"
    missing_reason[zero_denominator] <- "zero_denominator"
  }

  source_document_id <- rep.int(NA_character_, row_count)
  reference_document_id <- rep.int(NA_character_, row_count)
  source_document_id[measures == "a_covered_by_b_types"] <- document_ids[[1L]]
  reference_document_id[measures == "a_covered_by_b_types"] <- document_ids[[2L]]
  source_document_id[measures == "b_covered_by_a_types"] <- document_ids[[2L]]
  reference_document_id[measures == "b_covered_by_a_types"] <- document_ids[[1L]]

  data.frame(
    measure_id = registry$measure_id,
    method_id = registry$method_id,
    overlap_contract_id = rep.int(.lexoverlap_contract_id, row_count),
    overlap_contract_version = rep.int(.lexoverlap_contract_version, row_count),
    result_schema_id = rep.int(.lexoverlap_result_schema_id, row_count),
    result_schema_version = rep.int(.lexoverlap_result_schema_version, row_count),
    value = unname(as.double(value)),
    status = status,
    missing_reason = missing_reason,
    numerator = unname(as.double(numerator)),
    denominator = unname(as.double(denominator)),
    document_id_a = rep.int(document_ids[[1L]], row_count),
    document_id_b = rep.int(document_ids[[2L]], row_count),
    source_document_id = source_document_id,
    reference_document_id = reference_document_id,
    type_count_a = rep.int(as.double(type_count_a), row_count),
    type_count_b = rep.int(as.double(type_count_b), row_count),
    shared_type_count = rep.int(as.double(shared_type_count), row_count),
    union_type_count = rep.int(as.double(union_type_count), row_count),
    analysis_scope = rep.int("all_supplied_terms", row_count),
    unit = rep.int("term", row_count),
    content_set_id = rep.int(NA_character_, row_count),
    content_set_version = rep.int(NA_character_, row_count),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexoverlap_pair_counts <- function(
    document_ids,
    input_a,
    input_b,
    eligible_a,
    eligible_b,
    type_a,
    type_b,
    shared,
    union) {
  data.frame(
    document_id_a = document_ids[[1L]],
    document_id_b = document_ids[[2L]],
    input_token_count_a = as.double(input_a),
    input_token_count_b = as.double(input_b),
    eligible_token_count_a = as.double(eligible_a),
    eligible_token_count_b = as.double(eligible_b),
    type_count_a = as.double(type_a),
    type_count_b = as.double(type_b),
    shared_type_count = as.double(shared),
    union_type_count = as.double(union),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexoverlap_term_coverage <- function(document_ids, terms, states, type_counts) {
  input_tokens <- as.double(vapply(terms, length, integer(1L)))
  invalid <- states == "invalid"
  eligible <- input_tokens
  eligible[invalid] <- NA_real_
  excluded <- rep.int(0, 2L)
  excluded[invalid] <- NA_real_
  type_counts <- as.double(type_counts)
  selection_coverage <- ifelse(
    input_tokens == 0,
    NA_real_,
    ifelse(invalid, NA_real_, 1)
  )
  data.frame(
    document_id = document_ids,
    input_tokens = input_tokens,
    content_tokens = eligible,
    eligible_tokens = eligible,
    excluded_tokens = excluded,
    missing_upos_tokens = rep.int(0, 2L),
    non_content_upos_tokens = rep.int(0, 2L),
    missing_unit_tokens = rep.int(0, 2L),
    identity_fallback_tokens = rep.int(0, 2L),
    eligible_types = type_counts,
    upos_coverage = rep.int(NA_real_, 2L),
    unit_coverage = selection_coverage,
    content_unit_coverage = selection_coverage,
    selection_coverage = selection_coverage,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

#' Compute exact type overlap between two explicit term vectors
#'
#' Treats each vector element as one complete lexical unit and computes exact
#' type-set overlap. It performs no tokenization, normalization, case folding,
#' stemming, lemmatization, synonym expansion, or fuzzy matching. Repetition
#' affects token counts in optional detail tables but not overlap values.
#'
#' @param terms_a,terms_b Plain character vectors containing one complete term
#'   per element. Missing, empty, invalid-UTF-8, `bytes`-marked, or
#'   `latin1`-marked elements invalidate the pair; they are not silently
#'   removed.
#' @param measures A duplicate-free vector from [lexdiv_overlap_ids()].
#' @param document_ids Two distinct non-empty path-free identifiers for A and B.
#' @param details Either `"counts"` (the default) or `"terms"`. Term details
#'   retain shared and side-unique lexical items in the result object and should
#'   be requested only when that disclosure is appropriate.
#'
#' @return A `lexdiv_term_overlap` object. Its `summary` component has one row
#'   per measure with explicit numerator, denominator, direction, status, and
#'   contract identity. `counts` and `coverage` retain pair- and document-level
#'   denominators. When `details = "terms"`, `shared_terms`, `unique_to_a`, and
#'   `unique_to_b` contain exact terms and token counts. Provenance records
#'   whether those tables actually contain lexical strings, and printing the
#'   object displays a disclosure when they do.
#' @export
lexdiv_term_overlap <- function(
    terms_a,
    terms_b,
    measures = lexdiv_overlap_ids(),
    document_ids = c("text_a", "text_b"),
    details = "counts") {
  .lexoverlap_term_overlap_impl(
    terms_a,
    terms_b,
    measures = measures,
    document_ids = document_ids,
    details = details,
    warn_likely_raw_text = TRUE
  )
}

.lexoverlap_term_overlap_impl <- function(
    terms_a,
    terms_b,
    measures = lexdiv_overlap_ids(),
    document_ids = c("text_a", "text_b"),
    details = "counts",
    warn_likely_raw_text) {
  measures <- .lexoverlap_validate_measures(measures)
  document_ids <- .lexoverlap_document_ids(document_ids)
  details <- .lexprep_scalar_choice(details, c("counts", "terms"), "details")
  if (isTRUE(warn_likely_raw_text)) {
    .lex_warn_likely_raw_text(
      terms_a,
      "terms_a",
      "lexdiv_term_overlap",
      "tokenize and annotate the text before comparing terms"
    )
    .lex_warn_likely_raw_text(
      terms_b,
      "terms_b",
      "lexdiv_term_overlap",
      "tokenize and annotate the text before comparing terms"
    )
  }

  state_a <- .lexoverlap_term_state(terms_a)
  state_b <- .lexoverlap_term_state(terms_b)
  valid <- !identical(state_a, "invalid") && !identical(state_b, "invalid")
  if (valid) {
    terms_a <- .lex_canonicalize_encoding(terms_a)
    terms_b <- .lex_canonicalize_encoding(terms_b)
    types_a <- .lexoverlap_sorted_types(terms_a)
    types_b <- .lexoverlap_sorted_types(terms_b)
    shared <- sum(types_a %in% types_b)
    union <- length(types_a) + length(types_b) - shared
    type_counts <- c(length(types_a), length(types_b))
    invalid_reason <- NULL
    term_details <- .lexoverlap_term_details(
      terms_a,
      terms_b,
      types_a,
      types_b,
      details
    )
  } else {
    types_a <- types_b <- character()
    shared <- union <- NA_integer_
    type_counts <- c(NA_integer_, NA_integer_)
    invalid_reason <- .lexoverlap_invalid_reason(state_a, state_b)
    term_details <- list(
      shared_terms = .lexoverlap_empty_shared(),
      unique_to_a = .lexoverlap_empty_unique("a"),
      unique_to_b = .lexoverlap_empty_unique("b")
    )
  }

  summary <- .lexoverlap_summary(
    measures = measures,
    document_ids = document_ids,
    type_count_a = type_counts[[1L]],
    type_count_b = type_counts[[2L]],
    shared_type_count = shared,
    union_type_count = union,
    invalid_reason = invalid_reason
  )
  coverage <- .lexoverlap_term_coverage(
    document_ids,
    list(terms_a, terms_b),
    c(state_a, state_b),
    type_counts
  )
  counts <- .lexoverlap_pair_counts(
    document_ids,
    input_a = length(terms_a),
    input_b = length(terms_b),
    eligible_a = coverage$eligible_tokens[[1L]],
    eligible_b = coverage$eligible_tokens[[2L]],
    type_a = type_counts[[1L]],
    type_b = type_counts[[2L]],
    shared = shared,
    union = union
  )

  structure(
    list(
      summary = summary,
      counts = counts,
      coverage = coverage,
      shared_terms = term_details$shared_terms,
      unique_to_a = term_details$unique_to_a,
      unique_to_b = term_details$unique_to_b,
      exclusions = .lexoverlap_empty_exclusions(),
      comparability = .lexoverlap_empty_comparability(),
      preprocessing = list(
        analysis_scope = "all_supplied_terms",
        exact_matching = TRUE,
        transformations = "none"
      ),
      provenance = list(
        contract_id = .lexoverlap_contract_id,
        contract_version = .lexoverlap_contract_version,
        result_schema_id = .lexoverlap_result_schema_id,
        result_schema_version = .lexoverlap_result_schema_version,
        details = details,
        contains_lexical_terms = identical(details, "terms") &&
          any(vapply(term_details, nrow, integer(1L)) > 0L)
      )
    ),
    class = c("lexdiv_term_overlap", "lexdiv_overlap")
  )
}

.lexoverlap_content_input <- function(value, unit, argument) {
  value <- .lexprep_validate_tokenization(value, argument = argument)
  if (!("upos" %in% names(value$tokens))) {
    stop(
      sprintf(
        "%s requires UPOS annotations from lexdiv_lemmatize() for content-word selection.",
        argument
      ),
      call. = FALSE
    )
  }
  if (identical(unit, "lemma") && !("lemma" %in% names(value$tokens))) {
    stop(sprintf("%s has no lemma annotation layer.", argument), call. = FALSE)
  }
  if (identical(unit, "flemma") && !("flemma" %in% names(value$tokens))) {
    stop(sprintf("%s has no flemma annotation layer.", argument), call. = FALSE)
  }
  value
}

.lexoverlap_preprocessing_record <- function(value, document_id, unit) {
  annotation <- value$provenance$annotation
  flemma <- value$provenance$flemma_annotation
  list(
    document_id = document_id,
    tokenizer_id = value$provenance$tokenizer_id,
    tokenizer_version = value$provenance$tokenizer_version,
    normalization = value$provenance$normalization,
    case = value$provenance$case,
    keep_numbers = value$provenance$keep_numbers,
    annotation_method = annotation$method,
    annotation_backend_id = annotation$backend_id,
    annotation_backend_version = annotation$backend_version,
    upos_backend_id = annotation$upos_backend_id,
    upos_backend_version = annotation$upos_backend_version,
    flemma_method = if (identical(unit, "flemma")) flemma$method else NULL,
    flemma_backend_id = if (identical(unit, "flemma")) flemma$backend_id else NULL,
    flemma_backend_version = if (identical(unit, "flemma")) {
      flemma$backend_version
    } else {
      NULL
    },
    flemma_query_normalization = if (identical(unit, "flemma")) {
      flemma$query_normalization
    } else {
      NULL
    },
    flemma_parser_id = if (identical(unit, "flemma")) {
      flemma$parser_id
    } else {
      NULL
    },
    flemma_parser_version = if (identical(unit, "flemma")) {
      flemma$parser_version
    } else {
      NULL
    },
    flemma_resource_id = if (identical(unit, "flemma")) {
      flemma$resource_id
    } else {
      NULL
    },
    flemma_resource_version = if (identical(unit, "flemma")) {
      flemma$resource_version
    } else {
      NULL
    },
    flemma_override_present = if (identical(unit, "flemma")) {
      flemma$override_entries > 0
    } else {
      NULL
    },
    flemma_override_version = if (identical(unit, "flemma")) {
      flemma$override_version
    } else {
      NULL
    }
  )
}

.lexoverlap_comparability <- function(record_a, record_b, unit) {
  components <- data.frame(
    component = c(
      "tokenizer_id", "tokenizer_version", "normalization", "case",
      "keep_numbers", "upos_backend_id", "upos_backend_version"
    ),
    record_field = c(
      "tokenizer_id", "tokenizer_version", "normalization", "case",
      "keep_numbers", "upos_backend_id", "upos_backend_version"
    ),
    stringsAsFactors = FALSE
  )
  if (identical(unit, "lemma")) {
    components <- rbind(
      components,
      data.frame(
        component = c(
          "annotation_method", "annotation_backend_id",
          "annotation_backend_version"
        ),
        record_field = c(
          "annotation_method", "annotation_backend_id",
          "annotation_backend_version"
        ),
        stringsAsFactors = FALSE
      )
    )
  }
  if (identical(unit, "flemma")) {
    components <- rbind(
      components,
      data.frame(
        component = c(
          "flemma_method", "flemma_backend_id", "flemma_backend_version",
          "flemma_parser_id", "flemma_parser_version",
          "flemma_query_normalization", "flemma_resource_id",
          "flemma_resource_version", "flemma_override_present",
          "flemma_override_version"
        ),
        record_field = c(
          "flemma_method", "flemma_backend_id", "flemma_backend_version",
          "flemma_parser_id", "flemma_parser_version",
          "flemma_query_normalization", "flemma_resource_id",
          "flemma_resource_version", "flemma_override_present",
          "flemma_override_version"
        ),
        stringsAsFactors = FALSE
      )
    )
  }
  as_text <- function(value) {
    if (is.null(value) || length(value) == 0L || is.na(value)) {
      NA_character_
    } else if (is.logical(value)) {
      if (value) "true" else "false"
    } else {
      as.character(value)
    }
  }
  value_a <- vapply(components$record_field, function(component) {
    as_text(record_a[[component]])
  }, character(1L))
  value_b <- vapply(components$record_field, function(component) {
    as_text(record_b[[component]])
  }, character(1L))
  matches <- (is.na(value_a) & is.na(value_b)) |
    (!is.na(value_a) & !is.na(value_b) & value_a == value_b)
  if (identical(unit, "flemma")) {
    resource_version_row <- components$component == "flemma_resource_version"
    matches[resource_version_row] <-
      !is.na(value_a[resource_version_row]) &&
        !is.na(value_b[resource_version_row]) &&
        value_a[resource_version_row] == value_b[resource_version_row]

    override_version_row <- components$component == "flemma_override_version"
    override_present_a <- isTRUE(record_a$flemma_override_present)
    override_present_b <- isTRUE(record_b$flemma_override_present)
    matches[override_version_row] <- if (!override_present_a && !override_present_b) {
      TRUE
    } else if (override_present_a && override_present_b) {
      !is.na(value_a[override_version_row]) &&
        !is.na(value_b[override_version_row]) &&
        value_a[override_version_row] == value_b[override_version_row]
    } else {
      FALSE
    }
  }
  data.frame(
    component = components$component,
    value_a = unname(value_a),
    value_b = unname(value_b),
    matches = unname(matches),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexoverlap_content_coverage <- function(value, selected, document_id, unit) {
  token_table <- value$tokens
  input_tokens <- nrow(token_table)
  upos <- token_table$upos
  missing_upos <- is.na(upos)
  content <- !missing_upos & upos %in% .lexprep_content_upos
  non_content <- !missing_upos & !content
  selected_unit <- selected$audit$selected_unit
  missing_unit <- content & is.na(selected_unit)
  eligible <- content & !is.na(selected_unit)
  if (!identical(eligible, selected$audit$eligible)) {
    stop("Internal error: content-word eligibility paths disagree.", call. = FALSE)
  }
  identity_fallback <- if (identical(unit, "flemma")) {
    eligible & selected$audit$unit_match_rule == "identity"
  } else {
    rep.int(FALSE, input_tokens)
  }
  data.frame(
    document_id = document_id,
    input_tokens = as.double(input_tokens),
    content_tokens = as.double(sum(content)),
    eligible_tokens = as.double(sum(eligible)),
    excluded_tokens = as.double(input_tokens - sum(eligible)),
    missing_upos_tokens = as.double(sum(missing_upos)),
    non_content_upos_tokens = as.double(sum(non_content)),
    missing_unit_tokens = as.double(sum(missing_unit)),
    identity_fallback_tokens = as.double(sum(identity_fallback)),
    eligible_types = as.double(length(unique(selected_unit[eligible]))),
    upos_coverage = if (input_tokens == 0L) {
      NA_real_
    } else {
      sum(!missing_upos) / input_tokens
    },
    unit_coverage = if (input_tokens == 0L) {
      NA_real_
    } else {
      sum(!is.na(selected_unit)) / input_tokens
    },
    content_unit_coverage = if (sum(content) == 0L) {
      NA_real_
    } else {
      sum(eligible) / sum(content)
    },
    selection_coverage = if (input_tokens == 0L) {
      NA_real_
    } else {
      sum(eligible) / input_tokens
    },
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexoverlap_content_exclusions <- function(coverage, unit) {
  unit_reason <- paste0("missing_", unit)
  output <- do.call(rbind, lapply(seq_len(nrow(coverage)), function(index) {
    data.frame(
      document_id = rep.int(coverage$document_id[[index]], 3L),
      exclusion_reason = c("missing_upos", "non_content_upos", unit_reason),
      token_count = c(
        coverage$missing_upos_tokens[[index]],
        coverage$non_content_upos_tokens[[index]],
        coverage$missing_unit_tokens[[index]]
      ),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }))
  row.names(output) <- NULL
  output
}

#' Compute exact content-word type overlap between two annotated texts
#'
#' Selects Universal POS content words (`ADJ`, `ADV`, `NOUN`, `PROPN`, and
#' `VERB`) from two validated tokenization objects and delegates exact type-set
#' comparison to [lexdiv_term_overlap()]. It never infers POS tags or lemmas and
#' does not normalize the selected units again.
#'
#' @param x,y Objects created by [lexdiv_tokenize()] and annotated with
#'   [lexdiv_lemmatize()]. `unit = "flemma"` additionally requires
#'   [lexdiv_flemmatize()]. Raw character strings are not accepted because the
#'   package does not infer UPOS tags.
#' @param unit Exact lexical unit to compare: `"lemma"` (the default),
#'   `"surface"`, or `"flemma"`.
#' @inheritParams lexdiv_term_overlap
#' @param mismatch Action when the two texts record different tokenizer,
#'   normalization, case, annotation method/backend, or relevant flemma settings:
#'   `"error"` (the default), `"warn"`, or `"allow"`. Values are still based
#'   on exact selected terms; this argument never harmonizes inputs.
#'
#' @return A `lexdiv_content_overlap` object with the same main components as
#'   [lexdiv_term_overlap()]. `coverage` reports UPOS, content-word, selected
#'   unit, and identity-fallback counts for each document; `exclusions`
#'   aggregates exclusion reasons; and `comparability` shows whether the two
#'   preprocessing and annotation settings match. Flemma comparison uses
#'   caller-declared resource and override versions; missing versions are not
#'   treated as matches. Raw text, text hashes, resource bytes/hashes, and
#'   absolute paths are not copied into the result.
#' @export
lexdiv_content_overlap <- function(
    x,
    y,
    unit = "lemma",
    measures = lexdiv_overlap_ids(),
    document_ids = c("text_a", "text_b"),
    details = "counts",
    mismatch = "error") {
  unit <- .lexprep_scalar_choice(unit, c("lemma", "surface", "flemma"), "unit")
  measures <- .lexoverlap_validate_measures(measures)
  document_ids <- .lexoverlap_document_ids(document_ids)
  details <- .lexprep_scalar_choice(details, c("counts", "terms"), "details")
  mismatch <- .lexprep_scalar_choice(
    mismatch,
    c("warn", "error", "allow"),
    "mismatch"
  )
  x <- .lexoverlap_content_input(x, unit, "x")
  y <- .lexoverlap_content_input(y, unit, "y")
  selected_a <- .lexprep_selected_units(x, unit, "content")
  selected_b <- .lexprep_selected_units(y, unit, "content")
  preprocessing_a <- .lexoverlap_preprocessing_record(x, document_ids[[1L]], unit)
  preprocessing_b <- .lexoverlap_preprocessing_record(y, document_ids[[2L]], unit)
  comparability <- .lexoverlap_comparability(
    preprocessing_a,
    preprocessing_b,
    unit
  )
  mismatches <- comparability$component[!comparability$matches]
  if (length(mismatches) > 0L && identical(mismatch, "error")) {
    stop(
      sprintf(
        paste0(
          "x and y have different or unverifiable preprocessing or ",
          "annotation settings: %s."
        ),
        paste(mismatches, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  if (length(mismatches) > 0L && identical(mismatch, "warn")) {
    warning(
      sprintf(
        paste0(
          "x and y have different or unverifiable preprocessing or annotation settings: %s. ",
          "Exact overlap was computed; inspect $comparability."
        ),
        paste(mismatches, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  result <- .lexoverlap_term_overlap_impl(
    selected_a$units,
    selected_b$units,
    measures = measures,
    document_ids = document_ids,
    details = details,
    warn_likely_raw_text = FALSE
  )
  coverage <- rbind(
    .lexoverlap_content_coverage(x, selected_a, document_ids[[1L]], unit),
    .lexoverlap_content_coverage(y, selected_b, document_ids[[2L]], unit)
  )
  row.names(coverage) <- NULL
  result$summary$analysis_scope <- "upos_content_words"
  result$summary$unit <- unit
  result$summary$content_set_id <- .lexoverlap_content_set_id
  result$summary$content_set_version <- .lexoverlap_content_set_version
  both_empty <- result$summary$type_count_a == 0 & result$summary$type_count_b == 0
  result$summary$missing_reason[
    both_empty & result$summary$missing_reason == "empty_term_sets"
  ] <- "empty_content_sets"
  result$counts <- .lexoverlap_pair_counts(
    document_ids,
    input_a = coverage$input_tokens[[1L]],
    input_b = coverage$input_tokens[[2L]],
    eligible_a = coverage$eligible_tokens[[1L]],
    eligible_b = coverage$eligible_tokens[[2L]],
    type_a = result$summary$type_count_a[[1L]],
    type_b = result$summary$type_count_b[[1L]],
    shared = result$summary$shared_type_count[[1L]],
    union = result$summary$union_type_count[[1L]]
  )
  result$coverage <- coverage
  result$exclusions <- .lexoverlap_content_exclusions(coverage, unit)
  result$comparability <- comparability
  result$preprocessing <- list(
    unit = unit,
    content_set_id = .lexoverlap_content_set_id,
    content_set_version = .lexoverlap_content_set_version,
    content_upos = .lexprep_content_upos,
    document_a = preprocessing_a,
    document_b = preprocessing_b
  )
  result$provenance$analysis_scope <- "upos_content_words"
  result$provenance$mismatch_policy <- mismatch
  class(result) <- c("lexdiv_content_overlap", "lexdiv_overlap")
  result
}

#' @export
print.lexdiv_overlap <- function(x, ...) {
  counts <- x$counts[1L, , drop = FALSE]
  class_label <- if (inherits(x, "lexdiv_content_overlap")) {
    "lexdiv_content_overlap"
  } else {
    "lexdiv_term_overlap"
  }
  cat(sprintf(
    "<%s> %s vs %s | %s/%s shared types\n",
    class_label,
    counts$document_id_a,
    counts$document_id_b,
    format(counts$shared_type_count, trim = TRUE),
    format(counts$union_type_count, trim = TRUE)
  ))
  if (isTRUE(x$provenance$contains_lexical_terms)) {
    cat("Lexical term details retained: shared_terms, unique_to_a, unique_to_b\n")
  }
  if (inherits(x, "lexdiv_content_overlap")) {
    print(
      x$coverage[, c(
        "document_id", "eligible_tokens", "input_tokens", "eligible_types",
        "selection_coverage"
      ), drop = FALSE],
      row.names = FALSE
    )
    mismatches <- x$comparability$component[!x$comparability$matches]
    if (length(mismatches) > 0L) {
      cat(sprintf(
        "Comparability differences or unverifiable settings: %s\n",
        paste(mismatches, collapse = ", ")
      ))
    }
  }
  print(
    x$summary[, c(
      "measure_id", "value", "status", "missing_reason", "numerator",
      "denominator"
    ), drop = FALSE],
    row.names = FALSE,
    ...
  )
  invisible(x)
}
