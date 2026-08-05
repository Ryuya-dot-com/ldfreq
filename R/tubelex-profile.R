# Public, coverage-aware TUBELEX frequency and prevalence profile.

.tubelex_profile_contract_id <- "ldfreq-tubelex-frequency-profile"
.tubelex_profile_contract_version <- "0.1.0"
.tubelex_normalization_ids <- c(
  tubelex = "nfkc-trim-en-lower-v1",
  identity = "identity-valid-utf8-v1"
)

.tubelex_profile_terms <- function(terms) {
  if (.lexprep_is_tokenization(terms)) {
    tokenization <- .lexprep_validate_tokenization(terms)
    return(list(
      terms = unname(tokenization$tokens$surface),
      input_source = "lexdiv_tokenization",
      preprocessing_ref = tokenization$provenance
    ))
  }
  .lex_warn_likely_raw_text(
    terms,
    "terms",
    "tubelex_frequency_profile",
    "pass lexdiv_tokenize(text) instead"
  )
  list(
    terms = terms,
    input_source = "character_terms",
    preprocessing_ref = NULL
  )
}

.tubelex_normalize <- function(terms, normalization) {
  if (identical(normalization, "identity")) return(terms)
  output <- stringi::stri_trans_nfkc(terms)
  output <- stringi::stri_trim_both(output)
  output <- stringi::stri_trans_tolower(output, locale = "en")
  Encoding(output[!is.na(output)]) <- "UTF-8"
  output
}

.tubelex_empty_summary <- function() {
  data.frame(
    weighting = c("token", "type"),
    eligible_items = c(NA_real_, NA_real_),
    matched_items = c(NA_real_, NA_real_),
    coverage = c(NA_real_, NA_real_),
    mean_zipf = c(NA_real_, NA_real_),
    sd_zipf = c(NA_real_, NA_real_),
    mean_video_prevalence = c(NA_real_, NA_real_),
    mean_channel_prevalence = c(NA_real_, NA_real_),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.tubelex_mean <- function(value) {
  if (!length(value)) NA_real_ else mean(value)
}

.tubelex_sd <- function(value) {
  if (length(value) < 2L) NA_real_ else stats::sd(value)
}

.tubelex_profile_summary <- function(results, coverage) {
  if (!nrow(results)) {
    summary <- .tubelex_empty_summary()
    summary$eligible_items <- c(0, 0)
    summary$matched_items <- c(0, 0)
    return(summary)
  }
  token_matched <- which(results$matched %in% TRUE)
  type_first <- !duplicated(results$lookup_term)
  type_results <- results[type_first, , drop = FALSE]
  type_matched <- which(type_results$matched %in% TRUE)

  data.frame(
    weighting = c("token", "type"),
    eligible_items = c(coverage$eligible_tokens, coverage$eligible_types),
    matched_items = c(coverage$matched_tokens, coverage$matched_types),
    coverage = c(coverage$token_coverage, coverage$type_coverage),
    mean_zipf = c(
      .tubelex_mean(results$zipf[token_matched]),
      .tubelex_mean(type_results$zipf[type_matched])
    ),
    sd_zipf = c(
      .tubelex_sd(results$zipf[token_matched]),
      .tubelex_sd(type_results$zipf[type_matched])
    ),
    mean_video_prevalence = c(
      .tubelex_mean(results$video_prevalence[token_matched]),
      .tubelex_mean(type_results$video_prevalence[type_matched])
    ),
    mean_channel_prevalence = c(
      .tubelex_mean(results$channel_prevalence[token_matched]),
      .tubelex_mean(type_results$channel_prevalence[type_matched])
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.tubelex_frequency_profile <- function(
    terms,
    normalization,
    loader = .lexres_load_tubelex) {
  input <- .tubelex_profile_terms(terms)
  original_terms <- input$terms
  validated <- .lexres_lookup_input(original_terms)
  if (isTRUE(validated$ok)) {
    normalized_terms <- .tubelex_normalize(validated$terms, normalization)
    lookup <- .lexres_lookup_tubelex(normalized_terms, loader = loader)
  } else {
    normalized_terms <- original_terms
    lookup <- .lexres_lookup_tubelex(original_terms, loader = loader)
  }

  results <- lookup$results
  if (nrow(results)) {
    results$lookup_term <- results$term
    results$term <- original_terms
    results <- results[c(
      "query_index", "term", "lookup_term", "matched", "resource_word",
      "count", "videos", "channels", "zipf", "video_prevalence",
      "channel_prevalence"
    )]
  } else {
    results$lookup_term <- character()
    results <- results[c(
      "query_index", "term", "lookup_term", "matched", "resource_word",
      "count", "videos", "channels", "zipf", "video_prevalence",
      "channel_prevalence"
    )]
  }

  summary <- if (identical(lookup$status, "ok")) {
    .tubelex_profile_summary(results, lookup$coverage)
  } else {
    .tubelex_empty_summary()
  }
  original_type_count <- if (
    is.character(original_terms) && !is.object(original_terms) &&
      is.null(dim(original_terms)) && !anyNA(original_terms)
  ) {
    as.double(length(unique(original_terms)))
  } else {
    NA_real_
  }

  provenance <- list(
    contract_id = .tubelex_profile_contract_id,
    contract_version = .tubelex_profile_contract_version,
    resource = lookup$resource_ref,
    lookup = lookup$lookup_ref,
    input_source = input$input_source,
    preprocessing_ref = input$preprocessing_ref,
    query_normalization = normalization,
    query_normalization_id = unname(.tubelex_normalization_ids[[normalization]]),
    normalization_applied = identical(normalization, "tubelex"),
    original_input_types = original_type_count,
    normalized_lookup_types = if (is.character(normalized_terms) &&
      !anyNA(normalized_terms)) {
      as.double(length(unique(normalized_terms)))
    } else {
      NA_real_
    },
    unmatched_values_are_missing = TRUE,
    matched_only_summary = TRUE,
    formula_parameters = lookup$diagnostics$formula_parameters
  )
  structure(
    list(
      status = if (identical(lookup$status, "ok") && !nrow(results)) {
        "empty"
      } else {
        lookup$status
      },
      failure_reason = lookup$failure_reason,
      summary = summary,
      lookup = results,
      coverage = lookup$coverage,
      provenance = provenance,
      diagnostics = lookup$diagnostics
    ),
    class = "tubelex_frequency_profile"
  )
}

#' Compute a coverage-aware TUBELEX frequency profile
#'
#' Looks up token or type frequency, video prevalence, and channel prevalence
#' in the byte-pinned TUBELEX-EN Treebank aggregate bundled with `ldfreq`.
#' Token- and type-weighted summaries are calculated from matched terms only;
#' coverage is returned beside those conditional means. Unmatched terms remain
#' missing and are never converted to artificial zero-frequency observations.
#'
#' The lookup table retains raw token, video, and channel counts. Derived
#' values are base-10 log scores: `zipf` is a smoothed per-billion token score,
#' while video and channel prevalence are smoothed log proportions and can
#' therefore be negative. Exact formulas and denominators are returned in
#' provenance and in the installed lexical-resource lookup contract.
#'
#' @param terms A plain character vector of ordered terms, or an object returned
#'   by [lexdiv_tokenize()]. Order and duplicates are retained in the lookup
#'   table. Each character-vector element is one complete lookup term; a single
#'   string containing whitespace triggers a warning because it may be raw
#'   prose. Pass raw prose through [lexdiv_tokenize()].
#' @param normalization `"tubelex"` applies the documented NFKC, trim, and
#'   locale-fixed English lowercase query transform. `"identity"` performs an
#'   exact case- and normalization-sensitive lookup. The selected transform is
#'   recorded in provenance.
#'
#' @return A `tubelex_frequency_profile` list containing matched-only token- and
#'   type-weighted summaries, the lossless lookup table, token/type coverage,
#'   resource and formula provenance, and diagnostics.
#' @export
tubelex_frequency_profile <- function(
    terms,
    normalization = "tubelex") {
  normalization <- .lexprep_scalar_choice(
    normalization,
    c("tubelex", "identity"),
    "normalization"
  )
  .tubelex_frequency_profile(
    terms = terms,
    normalization = normalization,
    loader = .lexres_load_tubelex
  )
}

#' @export
print.tubelex_frequency_profile <- function(x, ...) {
  token_coverage <- x$coverage$token_coverage
  coverage_label <- if (is.na(token_coverage)) {
    "NA"
  } else {
    sprintf("%.1f%%", 100 * token_coverage)
  }
  cat(
    sprintf(
      "<tubelex_frequency_profile> status=%s | token coverage=%s | normalization=%s\n",
      x$status,
      coverage_label,
      x$provenance$query_normalization
    )
  )
  print(x$summary, row.names = FALSE, ...)
  invisible(x)
}
