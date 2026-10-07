# Public, coverage-aware TUBELEX frequency and prevalence profile.

.tubelex_profile_contract_id <- "ldfreq-tubelex-frequency-profile"
.tubelex_profile_contract_version <- "0.2.0"
.tubelex_normalization_ids <- c(
  tubelex = "nfkc-trim-en-lower-v1",
  tubelex_apostrophe = "nfkc-trim-en-lower-internal-apostrophe-v1",
  identity = "identity-valid-utf8-v1"
)

.tubelex_profile_terms <- function(terms, tokenization_mismatch) {
  if (.lexprep_is_tokenization(terms)) {
    tokenization <- .lexprep_validate_tokenization(terms)
    if (identical(tokenization_mismatch, "error")) {
      stop(
        paste0(
          "lexdiv_tokenize() does not use the bundled TUBELEX Treebank segmentation. ",
          "Supply source-aligned tokens, or explicitly set tokenization_mismatch = ",
          "\"allow\" for a segmentation-sensitivity analysis. Coverage does not verify alignment."
        ),
        call. = FALSE
      )
    }
    return(list(
      terms = unname(tokenization$tokens$surface),
      input_source = "lexdiv_tokenization",
      preprocessing_ref = tokenization$provenance,
      tokenization_alignment = "known_different_tokenizer_explicitly_allowed"
    ))
  }
  .lex_warn_likely_raw_text(
    terms,
    "terms",
    "tubelex_profile",
    "supply tokens prepared with the resource's Treebank segmentation instead"
  )
  list(
    terms = terms,
    input_source = "character_terms",
    preprocessing_ref = NULL,
    tokenization_alignment = "caller_supplied_terms_unverified"
  )
}

.tubelex_normalize <- function(terms, normalization) {
  if (identical(normalization, "identity")) return(terms)
  output <- stringi::stri_trans_nfkc(terms)
  output <- stringi::stri_trim_both(output)
  output <- stringi::stri_trans_tolower(output, locale = "en")
  if (identical(normalization, "tubelex_apostrophe")) {
    # A term-level typography transform, not a raw-text tokenizer. Preserve
    # trailing quotation marks; convert internal apostrophes and clitic starts.
    output <- stringi::stri_replace_all_regex(
      output,
      "(?:(?<=[\\p{L}\\p{M}\\p{N}])|^)[\u2019\u2032](?=[\\p{L}\\p{M}\\p{N}])",
      "'"
    )
  }
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

.tubelex_profile <- function(
    terms,
    normalization,
    loader = .lexres_load_tubelex,
    tokenization_mismatch = "error") {
  input <- .tubelex_profile_terms(terms, tokenization_mismatch)
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
    tokenization_alignment = input$tokenization_alignment,
    tokenization_mismatch = tokenization_mismatch,
    query_normalization = normalization,
    query_normalization_id = unname(.tubelex_normalization_ids[[normalization]]),
    normalization_applied = !identical(normalization, "identity"),
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
    class = "tubelex_profile"
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
#' @param terms A plain character vector of source-prepared ordered terms, or an object returned
#'   by [lexdiv_tokenize()] with explicit mismatch opt-in. Order and duplicates are retained in the lookup
#'   table. Each character-vector element is one complete lookup term; a single
#'   string containing whitespace triggers a warning because it may be raw
#'   prose. General word segmentation is not the resource's Treebank segmentation.
#' @param normalization `"tubelex"` applies the documented NFKC, trim, and
#'   locale-fixed English lowercase query transform. `"identity"` performs an
#'   exact case- and normalization-sensitive lookup. The selected transform is
#'   recorded in provenance. `"tubelex_apostrophe"` additionally converts internal
#'   typographic apostrophes and clitic starts, without splitting contractions.
#' @param tokenization_mismatch `"error"` rejects general tokenization objects;
#'   `"allow"` records their explicit use for segmentation sensitivity. Character
#'   vectors remain caller-prepared terms whose segmentation is not verified.
#'
#' The bundled CSV is decoded as UTF-8 independently of LC_CTYPE. C/POSIX
#' sessions can query ASCII and explicitly encoded UTF-8 terms. Schema-failure
#' printing retains the machine-readable reason and suggests checking the
#' resource and encoding; a non-UTF-8 locale is a possible cause in older loaders,
#' not proof of the cause of every schema failure.
#'
#' @return A `tubelex_profile` list containing matched-only token- and
#'   type-weighted summaries, the lossless lookup table, token/type coverage,
#'   resource and formula provenance, and diagnostics.
#' @export
tubelex_profile <- function(
    terms,
    normalization = "tubelex",
    tokenization_mismatch = "error") {
  normalization <- .lexprep_scalar_choice(
    normalization,
    names(.tubelex_normalization_ids),
    "normalization"
  )
  tokenization_mismatch <- .lexprep_scalar_choice(
    tokenization_mismatch, c("error", "allow"), "tokenization_mismatch"
  )
  .tubelex_profile(
    terms = terms,
    normalization = normalization,
    loader = .lexres_load_tubelex,
    tokenization_mismatch = tokenization_mismatch
  )
}

#' Profile several documents with one validated TUBELEX resource load
#'
#' @param documents An explicitly named list, or an ID/list-column data frame.
#' @inheritParams tubelex_profile
#' @param id_col,terms_col Column names for data-frame input.
#' @param max_rows Maximum combined lookup and summary rows across documents.
#' @return An input-ordered named list of complete `tubelex_profile` objects.
#' @export
tubelex_profile_batch <- function(
    documents,
    normalization = "tubelex",
    tokenization_mismatch = "error",
    id_col = "document_id",
    terms_col = "terms",
    max_rows = 1e6) {
  normalization <- .lexprep_scalar_choice(
    normalization, names(.tubelex_normalization_ids), "normalization"
  )
  tokenization_mismatch <- .lexprep_scalar_choice(
    tokenization_mismatch, c("error", "allow"), "tokenization_mismatch"
  )
  id_col <- .lex_batch_scalar_name(id_col, "id_col")
  terms_col <- .lex_batch_scalar_name(terms_col, "terms_col")
  if (identical(id_col, terms_col)) {
    stop("id_col and terms_col must select different columns.", call. = FALSE)
  }
  max_rows <- .profile_positive_integer(max_rows, "max_rows")
  batch <- .lex_batch_documents(documents, id_col, terms_col)
  # Fail on known tokenizer mismatches and row limits before touching resources.
  inputs <- lapply(batch$tokens, .tubelex_profile_terms,
    tokenization_mismatch = tokenization_mismatch)
  planned_rows <- sum(vapply(inputs, function(input) {
    as.double(length(input$terms)) + 2
  }, numeric(1L)))
  if (planned_rows > max_rows) {
    stop("The requested TUBELEX batch exceeds max_rows.", call. = FALSE)
  }
  loaded <- NULL
  loader <- function() {
    if (is.null(loaded)) loaded <<- .lexres_load_tubelex()
    loaded
  }
  output <- lapply(batch$tokens, .tubelex_profile,
    normalization = normalization, loader = loader,
    tokenization_mismatch = tokenization_mismatch)
  stats::setNames(output, batch$ids)
}

#' @export
print.tubelex_profile <- function(x, ...) {
  token_coverage <- x$coverage$token_coverage
  coverage_label <- if (is.na(token_coverage)) {
    "NA"
  } else {
    sprintf("%.1f%%", 100 * token_coverage)
  }
  cat(
    sprintf(
      "<tubelex_profile> status=%s | token coverage=%s | normalization=%s\n",
      x$status,
      coverage_label,
      x$provenance$query_normalization
    )
  )
  if (identical(x$status, "resource_error")) {
    cat("Resource failure:", x$failure_reason, "\n")
    if (identical(x$failure_reason, "schema_mismatch")) {
      violations <- x$diagnostics$resource_diagnostics$schema_violations
      if (length(violations)) cat("Schema checks:", paste(violations, collapse = ", "), "\n")
      cat("Check the bundled resource and UTF-8 decoding; LC_CTYPE =",
        Sys.getlocale("LC_CTYPE"), "\n")
      if (!isTRUE(l10n_info()[["UTF-8"]])) {
        cat("Older loaders can fail in a non-UTF-8 locale; update ldfreq or try a UTF-8 locale.\n")
      }
    }
  }
  print(x$summary, row.names = FALSE, ...)
  invisible(x)
}
