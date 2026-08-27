# Directional coverage of multiple explicit term vectors by one reference set.

.lexref_contract_id <- "ldfreq-reference-coverage"
.lexref_contract_version <- "0.1.0"
.lexref_result_schema_id <- "lexdiv-reference-coverage-result"
.lexref_result_schema_version <- "0.1.0"

.lexref_registry <- data.frame(
  weighting = c("token", "type"),
  measure_id = c(
    "reference_coverage_tokens",
    "reference_coverage_types"
  ),
  method_id = c(
    "document_tokens_in_reference_type_set_v1",
    "document_types_in_reference_type_set_v1"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

.lexref_looks_like_path <- function(value) {
  grepl("[/\\\\]", value) ||
    value %in% c(".", "..") ||
    grepl("^[A-Za-z]:", value) ||
    grepl("^~($|[/\\\\])", value) ||
    grepl("^file:(//)?", value, ignore.case = TRUE)
}

.lexref_validate_ids <- function(document_ids, reference_id) {
  ids <- c(document_ids, reference_id)
  if (
    !is.character(ids) || is.object(ids) || !is.null(dim(ids)) ||
      !is.null(attributes(ids)) || anyNA(ids) || any(!nzchar(ids)) ||
      anyDuplicated(ids) || any(Encoding(ids) %in% c("bytes", "latin1")) ||
      any(!validUTF8(ids)) || any(grepl("[[:cntrl:]]", ids)) ||
      any(vapply(ids, .lexref_looks_like_path, logical(1L)))
  ) {
    stop(
      paste0(
        "Document and reference IDs must be distinct, path-free, plain, ",
        "non-empty valid-UTF-8 strings without control characters."
      ),
      call. = FALSE
    )
  }
  Encoding(document_ids) <- "UTF-8"
  Encoding(reference_id) <- "UTF-8"
  list(document_ids = document_ids, reference_id = reference_id)
}

.lexref_empty_summary <- function() {
  data.frame(
    document_id = character(),
    reference_id = character(),
    weighting = character(),
    measure_id = character(),
    method_id = character(),
    reference_coverage_contract_id = character(),
    reference_coverage_contract_version = character(),
    result_schema_id = character(),
    result_schema_version = character(),
    value = double(),
    status = character(),
    missing_reason = character(),
    numerator = double(),
    denominator = double(),
    document_tokens = double(),
    document_types = double(),
    reference_tokens = double(),
    reference_types = double(),
    matched_tokens = double(),
    matched_types = double(),
    analysis_scope = character(),
    unit = character(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexref_empty_documents <- function() {
  data.frame(
    document_id = character(),
    state = character(),
    input_tokens = double(),
    input_types = double(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexref_empty_terms <- function() {
  data.frame(
    document_id = character(),
    reference_id = character(),
    term = character(),
    document_token_count = double(),
    reference_token_count = double(),
    matched = logical(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexref_warn_documents <- function(batch) {
  likely_raw <- vapply(batch$tokens, function(value) {
    is.character(value) && !is.object(value) && is.null(dim(value)) &&
      is.null(attributes(value)) && length(value) == 1L &&
      !is.na(value) && grepl("[[:space:]]", value)
  }, logical(1L))
  if (any(likely_raw)) {
    index <- which(likely_raw)[[1L]]
    .lex_warn_likely_raw_text(
      batch$tokens[[index]],
      sprintf("documents[['%s']]", batch$ids[[index]]),
      "lexdiv_reference_coverage",
      "tokenize the text before computing coverage"
    )
  }
  invisible(NULL)
}

.lexref_summary_rows <- function(
    document_id,
    reference_id,
    document_state,
    reference_state,
    document_tokens,
    document_types,
    reference_tokens,
    reference_types,
    matched_tokens,
    matched_types) {
  numerator <- c(as.double(matched_tokens), as.double(matched_types))
  denominator <- c(as.double(document_tokens), as.double(document_types))
  status <- rep.int("ok", 2L)
  missing_reason <- rep.int(NA_character_, 2L)
  value <- numerator / denominator

  if (identical(reference_state, "invalid") && identical(document_state, "invalid")) {
    numerator[] <- denominator[] <- value[] <- NA_real_
    status[] <- "invalid_input"
    missing_reason[] <- "invalid_document_and_reference"
  } else if (identical(reference_state, "invalid")) {
    numerator[] <- denominator[] <- value[] <- NA_real_
    status[] <- "invalid_input"
    missing_reason[] <- "invalid_reference"
  } else if (identical(document_state, "invalid")) {
    numerator[] <- denominator[] <- value[] <- NA_real_
    status[] <- "invalid_input"
    missing_reason[] <- "invalid_document"
  } else if (identical(document_state, "empty")) {
    value[] <- NA_real_
    status[] <- "missing"
    missing_reason[] <- "empty_document"
  }

  data.frame(
    document_id = rep.int(document_id, 2L),
    reference_id = rep.int(reference_id, 2L),
    weighting = .lexref_registry$weighting,
    measure_id = .lexref_registry$measure_id,
    method_id = .lexref_registry$method_id,
    reference_coverage_contract_id = rep.int(.lexref_contract_id, 2L),
    reference_coverage_contract_version = rep.int(.lexref_contract_version, 2L),
    result_schema_id = rep.int(.lexref_result_schema_id, 2L),
    result_schema_version = rep.int(.lexref_result_schema_version, 2L),
    value = unname(as.double(value)),
    status = status,
    missing_reason = missing_reason,
    numerator = unname(as.double(numerator)),
    denominator = unname(as.double(denominator)),
    document_tokens = rep.int(as.double(document_tokens), 2L),
    document_types = rep.int(as.double(document_types), 2L),
    reference_tokens = rep.int(as.double(reference_tokens), 2L),
    reference_types = rep.int(as.double(reference_types), 2L),
    matched_tokens = rep.int(as.double(matched_tokens), 2L),
    matched_types = rep.int(as.double(matched_types), 2L),
    analysis_scope = rep.int("all_supplied_terms", 2L),
    unit = rep.int("term", 2L),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexref_term_rows <- function(terms, types, reference_types, reference_counts,
                              document_id, reference_id) {
  if (length(types) == 0L) return(.lexref_empty_terms())
  document_counts <- .lexoverlap_type_counts(terms, types)
  reference_index <- match(types, reference_types)
  matched <- !is.na(reference_index)
  matched_reference_counts <- rep.int(0, length(types))
  matched_reference_counts[matched] <- reference_counts[reference_index[matched]]
  data.frame(
    document_id = rep.int(document_id, length(types)),
    reference_id = rep.int(reference_id, length(types)),
    term = types,
    document_token_count = document_counts,
    reference_token_count = as.double(matched_reference_counts),
    matched = matched,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

#' Compute coverage of multiple term vectors by one reference set
#'
#' Computes the proportion of each document's tokens and distinct types that
#' occur in one explicit reference term vector. Matching is exact and performs
#' no tokenization, normalization, case conversion, lemmatization, stemming,
#' synonym expansion, or fuzzy matching.
#'
#' @param documents A plain named list of term vectors, or a data frame with
#'   the columns selected by `id_col` and `terms_col`.
#' @param reference A plain character vector containing the reference terms.
#'   Repetition is retained in reference diagnostics but does not change set
#'   membership.
#' @param reference_id One path-free identifier for the reference. It must not
#'   duplicate a document ID.
#' @param id_col Name of the document-ID column for data-frame input.
#' @param terms_col Name of the term list-column for data-frame input.
#' @param details Either `"counts"` (the default) or `"terms"`. The latter
#'   retains exact document terms, counts, and match indicators.
#' @param max_rows Maximum combined number of rows across all returned data
#'   frames, checked before term-detail allocation.
#'
#' @return A `lexdiv_reference_coverage` object containing long-form `summary`,
#'   document and reference diagnostics, optional `terms`, preprocessing, and
#'   provenance components. Token and type rows retain their numerator and
#'   denominator for reuse in graphics and statistical models.
#' @export
lexdiv_reference_coverage <- function(
    documents,
    reference,
    reference_id = "reference",
    id_col = "document_id",
    terms_col = "terms",
    details = "counts",
    max_rows = 1e6) {
  id_col <- .lex_batch_scalar_name(id_col, "id_col")
  terms_col <- .lex_batch_scalar_name(terms_col, "terms_col")
  if (identical(id_col, terms_col)) {
    stop("id_col and terms_col must select different columns.", call. = FALSE)
  }
  reference_id <- .lex_batch_scalar_name(reference_id, "reference_id")
  details <- .lexprep_scalar_choice(details, c("counts", "terms"), "details")
  max_rows <- .profile_positive_integer(max_rows, "max_rows")
  batch <- .lex_batch_documents(documents, id_col, terms_col)
  ids <- .lexref_validate_ids(batch$ids, reference_id)
  batch$ids <- ids$document_ids
  reference_id <- ids$reference_id
  document_count <- length(batch$tokens)

  # Summary (2D), document diagnostics (D), and reference diagnostics (1).
  if (as.double(document_count) > (max_rows - 1) / 3) {
    stop(
      sprintf("The requested reference coverage exceeds max_rows (%s).", format(max_rows)),
      call. = FALSE
    )
  }

  .lexref_warn_documents(batch)
  .lex_warn_likely_raw_text(
    reference,
    "reference",
    "lexdiv_reference_coverage",
    "tokenize the text before using it as a reference"
  )

  reference_state <- .lexoverlap_term_state(reference)
  if (!identical(reference_state, "invalid")) {
    reference <- .lex_canonicalize_encoding(reference)
    reference_types <- .lexoverlap_sorted_types(reference)
    reference_counts <- .lexoverlap_type_counts(reference, reference_types)
    reference_type_count <- length(reference_types)
  } else {
    reference_types <- character()
    reference_counts <- double()
    reference_type_count <- NA_integer_
  }
  reference_token_count <- if (identical(reference_state, "invalid")) {
    NA_real_
  } else {
    as.double(length(reference))
  }

  states <- vapply(batch$tokens, .lexoverlap_term_state, character(1L))
  canonical_documents <- vector("list", document_count)
  document_types <- vector("list", document_count)
  document_type_counts <- rep.int(NA_real_, document_count)
  detail_rows <- 0
  for (index in seq_len(document_count)) {
    if (!identical(states[[index]], "invalid")) {
      canonical_documents[[index]] <- .lex_canonicalize_encoding(batch$tokens[[index]])
      document_types[[index]] <- .lexoverlap_sorted_types(canonical_documents[[index]])
      document_type_counts[[index]] <- length(document_types[[index]])
      if (identical(details, "terms") && !identical(reference_state, "invalid")) {
        detail_rows <- detail_rows + document_type_counts[[index]]
        if (detail_rows > max_rows - (3 * document_count + 1)) {
          stop(
            sprintf("The requested reference coverage exceeds max_rows (%s).", format(max_rows)),
            call. = FALSE
          )
        }
      }
    } else {
      canonical_documents[[index]] <- character()
      document_types[[index]] <- character()
    }
  }

  if (document_count == 0L) {
    summary <- .lexref_empty_summary()
    document_diagnostics <- .lexref_empty_documents()
    term_details <- .lexref_empty_terms()
  } else {
    summary_pieces <- vector("list", document_count)
    diagnostic_pieces <- vector("list", document_count)
    term_pieces <- if (identical(details, "terms")) {
      vector("list", document_count)
    } else {
      NULL
    }
    for (index in seq_len(document_count)) {
      state <- states[[index]]
      document_token_count <- if (identical(state, "invalid")) {
        NA_real_
      } else {
        as.double(length(canonical_documents[[index]]))
      }
      document_type_count <- document_type_counts[[index]]
      if (!identical(state, "invalid") && !identical(reference_state, "invalid")) {
        matched_tokens <- sum(canonical_documents[[index]] %in% reference_types)
        matched_types <- sum(document_types[[index]] %in% reference_types)
      } else {
        matched_tokens <- matched_types <- NA_real_
      }
      summary_pieces[[index]] <- .lexref_summary_rows(
        document_id = batch$ids[[index]],
        reference_id = reference_id,
        document_state = state,
        reference_state = reference_state,
        document_tokens = document_token_count,
        document_types = document_type_count,
        reference_tokens = reference_token_count,
        reference_types = reference_type_count,
        matched_tokens = matched_tokens,
        matched_types = matched_types
      )
      diagnostic_pieces[[index]] <- data.frame(
        document_id = batch$ids[[index]],
        state = state,
        input_tokens = document_token_count,
        input_types = document_type_count,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
      if (identical(details, "terms")) {
        term_pieces[[index]] <- if (
          !identical(state, "invalid") && !identical(reference_state, "invalid")
        ) {
          .lexref_term_rows(
            canonical_documents[[index]],
            document_types[[index]],
            reference_types,
            reference_counts,
            batch$ids[[index]],
            reference_id
          )
        } else {
          .lexref_empty_terms()
        }
      }
    }
    summary <- do.call(base::rbind.data.frame, unname(summary_pieces))
    document_diagnostics <- do.call(
      base::rbind.data.frame,
      unname(diagnostic_pieces)
    )
    term_details <- if (identical(details, "terms")) {
      do.call(base::rbind.data.frame, unname(term_pieces))
    } else {
      .lexref_empty_terms()
    }
    row.names(summary) <- row.names(document_diagnostics) <- row.names(term_details) <- NULL
  }

  reference_diagnostics <- data.frame(
    reference_id = reference_id,
    state = reference_state,
    input_tokens = reference_token_count,
    input_types = as.double(reference_type_count),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  structure(
    list(
      summary = summary,
      documents = document_diagnostics,
      reference = reference_diagnostics,
      terms = term_details,
      preprocessing = list(
        analysis_scope = "all_supplied_terms",
        exact_matching = TRUE,
        transformations = "none"
      ),
      provenance = list(
        contract_id = .lexref_contract_id,
        contract_version = .lexref_contract_version,
        result_schema_id = .lexref_result_schema_id,
        result_schema_version = .lexref_result_schema_version,
        details = details,
        max_rows = max_rows,
        contains_lexical_terms = identical(details, "terms") && nrow(term_details) > 0L
      )
    ),
    class = "lexdiv_reference_coverage"
  )
}

#' @export
print.lexdiv_reference_coverage <- function(x, ...) {
  if (
    !inherits(x, "lexdiv_reference_coverage") || !is.list(x) ||
      !is.data.frame(x$summary) || !is.data.frame(x$reference)
  ) {
    stop("x must be a lexdiv_reference_coverage object.", call. = FALSE)
  }
  reference_id <- if (nrow(x$reference) == 1L) x$reference$reference_id[[1L]] else "unknown"
  document_count <- if (is.data.frame(x$documents)) nrow(x$documents) else 0L
  cat(sprintf(
    "<lexdiv_reference_coverage: %d document%s; reference %s>\n",
    document_count,
    if (document_count == 1L) "" else "s",
    reference_id
  ))
  visible <- intersect(
    c(
      "document_id", "weighting", "value", "status", "missing_reason",
      "numerator", "denominator"
    ),
    names(x$summary)
  )
  print.data.frame(x$summary[visible], ...)
  if (isTRUE(x$provenance$contains_lexical_terms)) {
    cat(sprintf("Lexical term details retained: %d row%s in $terms.\n",
      nrow(x$terms), if (nrow(x$terms) == 1L) "" else "s"))
  }
  invisible(x)
}

#' Plot reference coverage for one weighting
#'
#' @param x A `lexdiv_reference_coverage` object.
#' @param weighting Exactly one of `"token"` or `"type"`.
#' @param col,pch,main,xlab,ylab,ylim Base-graphics settings.
#' @param ... Additional arguments passed to [graphics::plot()].
#'
#' @return Invisibly, the exact rows plotted plus their positions.
#' @export
plot.lexdiv_reference_coverage <- function(
    x,
    weighting = "token",
    col = "#0072B2",
    pch = 19,
    main = NULL,
    xlab = "document",
    ylab = "coverage",
    ylim = c(0, 1),
    ...) {
  if (
    !inherits(x, "lexdiv_reference_coverage") || !is.list(x) ||
      !is.data.frame(x$summary)
  ) {
    stop("x must be a lexdiv_reference_coverage object.", call. = FALSE)
  }
  weighting <- .lexprep_scalar_choice(weighting, c("token", "type"), "weighting")
  frame <- x$summary[
    x$summary$weighting == weighting & x$summary$status == "ok" &
      is.finite(x$summary$value),
    c(
      "document_id", "reference_id", "weighting", "measure_id", "method_id",
      "value", "numerator", "denominator"
    ),
    drop = FALSE
  ]
  if (nrow(frame) == 0L) {
    stop(sprintf("The %s-weighted coverage has no finite ok values to plot.", weighting),
      call. = FALSE)
  }
  if (is.null(main)) main <- sprintf("Reference coverage (%s weighted)", weighting)
  positions <- seq_len(nrow(frame))
  graphics::plot(
    positions,
    frame$value,
    xaxt = "n",
    xlab = xlab,
    ylab = ylab,
    ylim = ylim,
    main = main,
    col = col,
    pch = pch,
    ...
  )
  graphics::axis(1, at = positions, labels = frame$document_id)
  frame$position <- as.double(positions)
  row.names(frame) <- NULL
  invisible(frame)
}
