# Narrow batch adapter for the pre-tokenized lexical-diversity API.

.lex_batch_schema_id <- "lexdiv-r-batch-result"
.lex_batch_schema_version <- "0.1.0-draft.1"

.lex_batch_scalar_name <- function(value, argument) {
  if (
    !is.character(value) ||
      length(value) != 1L ||
      is.na(value) ||
      !nzchar(value) ||
      !is.null(attributes(value)) ||
      Encoding(value) %in% c("bytes", "latin1") ||
      !validUTF8(value)
  ) {
    stop(
      sprintf("%s must be one plain, non-empty, valid-UTF-8 character string.", argument),
      call. = FALSE
    )
  }
  Encoding(value) <- "UTF-8"
  value
}

.lex_batch_validate_ids <- function(ids, document_count) {
  if (
    !is.character(ids) ||
      !is.null(attributes(ids)) ||
      length(ids) != document_count ||
      anyNA(ids) ||
      any(!nzchar(ids)) ||
      any(Encoding(ids) %in% c("bytes", "latin1")) ||
      any(!validUTF8(ids))
  ) {
    stop(
      paste(
        "document IDs must be plain, non-empty, unique, valid-UTF-8",
        "character strings without attributes."
      ),
      call. = FALSE
    )
  }

  # In a C locale, otherwise identical valid UTF-8 bytes carrying "unknown"
  # and "UTF-8" markers need not compare equal. Canonicalize only the marker
  # on this local ID copy before duplicate detection and output. This does not
  # perform Unicode normalization.
  Encoding(ids) <- "UTF-8"
  if (anyDuplicated(ids)) {
    stop(
      paste(
        "document IDs must be plain, non-empty, unique, valid-UTF-8",
        "character strings without attributes."
      ),
      call. = FALSE
    )
  }
  ids
}

.lex_batch_column_names <- function(column_names) {
  if (
    !is.character(column_names) ||
      !is.null(attributes(column_names)) ||
      anyNA(column_names) ||
      any(Encoding(column_names) %in% c("bytes", "latin1")) ||
      any(!validUTF8(column_names))
  ) {
    stop(
      "Data-frame column names must be plain valid-UTF-8 character strings.",
      call. = FALSE
    )
  }
  Encoding(column_names) <- "UTF-8"
  column_names
}

.lex_batch_documents <- function(documents, id_col, tokens_col) {
  if (is.data.frame(documents)) {
    column_names <- .lex_batch_column_names(names(documents))
    id_matches <- which(column_names == id_col)
    tokens_matches <- which(column_names == tokens_col)
    if (length(id_matches) != 1L || length(tokens_matches) != 1L) {
      stop(
        "A data-frame input must contain exactly one selected ID column and one selected tokens column.",
        call. = FALSE
      )
    }

    ids <- .subset2(documents, id_matches)
    token_column <- .subset2(documents, tokens_matches)
    document_count <- nrow(documents)
    ids <- .lex_batch_validate_ids(ids, document_count)
    if (
      !is.list(token_column) ||
        is.data.frame(token_column) ||
        !is.null(dim(token_column)) ||
        length(token_column) != document_count
    ) {
      stop("The selected tokens column must be a list-column with one element per document.", call. = FALSE)
    }

    tokens <- lapply(seq_len(document_count), function(index) {
      .subset2(token_column, index)
    })
    return(list(ids = ids, tokens = tokens))
  }

  if (
    !is.list(documents) ||
      is.object(documents) ||
      !is.null(dim(documents)) ||
      !identical(names(attributes(documents)), "names") ||
      is.null(names(documents))
  ) {
    stop(
      "documents must be either a plain named list or a data frame with selected ID and tokens columns.",
      call. = FALSE
    )
  }

  ids <- names(documents)
  document_count <- length(documents)
  ids <- .lex_batch_validate_ids(ids, document_count)
  tokens <- lapply(seq_len(document_count), function(index) {
    .subset2(documents, index)
  })
  list(ids = ids, tokens = tokens)
}

.lex_batch_restore_result_attributes <- function(output, source) {
  source_attributes <- attributes(source)
  custom_attributes <- setdiff(
    names(source_attributes),
    c("names", "row.names", "class")
  )
  for (attribute_name in custom_attributes) {
    attr(output, attribute_name) <- source_attributes[[attribute_name]]
  }
  class(output) <- class(source)
  output
}

.lex_batch_prepend_id <- function(result, document_id) {
  source <- result
  result_names <- names(result)
  result[["document_id"]] <- rep.int(document_id, nrow(result))
  result[["batch_schema_id"]] <- rep.int(.lex_batch_schema_id, nrow(result))
  result[["batch_schema_version"]] <- rep.int(
    .lex_batch_schema_version,
    nrow(result)
  )
  result <- result[c(
    "document_id", "batch_schema_id", "batch_schema_version", result_names
  )]
  result <- .lex_batch_restore_result_attributes(result, source = source)
  attr(result, "batch_schema_id") <- .lex_batch_schema_id
  attr(result, "batch_schema_version") <- .lex_batch_schema_version
  class(result) <- c("lexdiv_batch_results", class(source))
  result
}

#' Compute frozen lexical-diversity metrics for multiple tokenized documents
#'
#' This narrow adapter accepts either a plain named list of token vectors or a
#' data frame containing an explicit character ID column and a list-column of
#' token vectors. It performs no tokenization or normalization. Structurally
#' invalid containers stop; invalid token vectors are represented by the same
#' per-metric `invalid_input` records as [lexdiv_metrics()].
#'
#' @param documents A plain named list, or a data frame with the columns selected
#'   by `id_col` and `tokens_col`.
#' @param id_col Name of the explicit document-ID column for data-frame input.
#' @param tokens_col Name of the token list-column for data-frame input.
#' @param ... Arguments forwarded unchanged to [lexdiv_metrics()].
#'
#' @return A long-form `lexdiv_batch_results` data frame ordered by document and
#'   then requested metric. The explicit document/batch envelope is followed by
#'   all single-document result columns, whose schema identity is preserved.
#' @export
lexdiv_metrics_batch <- function(
    documents,
    id_col = "document_id",
    tokens_col = "tokens",
    ...) {
  id_col <- .lex_batch_scalar_name(id_col, "id_col")
  tokens_col <- .lex_batch_scalar_name(tokens_col, "tokens_col")
  if (identical(id_col, tokens_col)) {
    stop("id_col and tokens_col must select different columns.", call. = FALSE)
  }

  batch <- .lex_batch_documents(documents, id_col, tokens_col)
  document_count <- length(batch$tokens)

  # Validate the selected metric set and every selected metric-local parameter
  # independently of both document count and per-document token validity. Ten
  # repeated valid tokens reach every current parameter validator without
  # requiring allocation proportional to a requested window or sample size.
  prototype <- lexdiv_metrics(
    tokens = rep.int("lexdiv_batch_parameter_probe", 10L),
    ...
  )

  if (document_count == 0L) {
    output <- prototype[FALSE, , drop = FALSE]
    output <- .lex_batch_prepend_id(output, character())
    row.names(output) <- NULL
    return(output)
  }

  pieces <- lapply(seq_len(document_count), function(index) {
    result <- lexdiv_metrics(tokens = batch$tokens[[index]], ...)
    .lex_batch_prepend_id(result, batch$ids[[index]])
  })
  prototype <- pieces[[1L]]
  output <- do.call(base::rbind.data.frame, unname(pieces))
  row.names(output) <- NULL
  .lex_batch_restore_result_attributes(output, prototype)
}

#' @export
print.lexdiv_batch_results <- function(x, ...) {
  document_count <- length(unique(x$document_id))
  cat(sprintf(
    "<lexdiv_batch_results: %d document%s; %d metric record%s; schema %s>\n",
    document_count,
    if (document_count == 1L) "" else "s",
    nrow(x),
    if (nrow(x) == 1L) "" else "s",
    attr(x, "batch_schema_version", exact = TRUE)
  ))
  visible <- x[c(
    "document_id", "metric_id", "value", "status", "missing_reason", "N", "V",
    "below_quality_floor"
  )]
  print.data.frame(visible, ...)
  invisible(x)
}
