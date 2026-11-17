# Narrow batch adapter for the pre-tokenized lexical-diversity API.

.lex_batch_schema_id <- "lexdiv-r-batch-result"
.lex_batch_schema_version <- "0.1.0"

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

.lex_batch_documents <- function(
    documents,
    id_col,
    term_col,
    extract_tokenization = FALSE) {
  if (.lex_is_tokenization_batch(documents)) {
    if (!is.list(documents) || is.null(names(documents))) {
      stop("A lexdiv_tokenization_batch object must be a named list.", call. = FALSE)
    }
    ids <- .lex_batch_validate_ids(names(documents), length(documents))
    tokens <- lapply(seq_along(documents), function(index) {
      element <- .subset2(documents, index)
      if (extract_tokenization) {
        .lexdiv_extract_tokenization_terms(element, term_col)
      } else {
        element
      }
    })
    return(list(ids = ids, tokens = tokens))
  }

  if (is.data.frame(documents)) {
    documents <- base::as.data.frame(
      documents,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      optional = TRUE
    )
    column_names <- .lex_batch_column_names(names(documents))
    id_matches <- which(column_names == id_col)
    tokens_matches <- which(column_names == term_col)
    if (length(id_matches) != 1L || length(tokens_matches) != 1L) {
      stop(
        "A data-frame input must contain exactly one selected ID column and one selected term column.",
        call. = FALSE
      )
    }

    ids <- .lex_strip_names(.subset2(documents, id_matches))
    token_column <- .subset2(documents, tokens_matches)
    document_count <- nrow(documents)
    ids <- .lex_batch_validate_ids(ids, document_count)
    if (
      !is.list(token_column) ||
        is.data.frame(token_column) ||
        !is.null(dim(token_column)) ||
        length(token_column) != document_count
    ) {
      stop("The selected term column must be a list-column with one element per document.", call. = FALSE)
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
      "documents must be either a plain named list or a data frame with selected ID and term columns.",
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

.lexdiv_metrics_batch <- function(
    documents,
    id_col = "document_id",
    term_col = "tokens",
    ...,
    plan = NULL,
    max_rows = 1e6) {
  if (!is.null(plan)) {
    if (...length() > 0L) {
      stop("With plan, omit all metric arguments in ...; put requests in the plan.", call. = FALSE)
    }
    return(.lexdiv_profile_batch(
      documents, plan = plan, id_col = id_col, term_col = term_col,
      max_rows = max_rows
    ))
  }
  if (!missing(max_rows)) {
    stop("max_rows requires a non-NULL plan.", call. = FALSE)
  }
  id_col <- .lex_batch_scalar_name(id_col, "id_col")
  term_col <- .lex_batch_scalar_name(term_col, "term_col")
  if (!.lex_is_tokenization_batch(documents) && identical(id_col, term_col)) {
    stop("id_col and term_col must select different columns.", call. = FALSE)
  }

  batch <- .lex_batch_documents(documents, id_col, term_col, extract_tokenization = TRUE)
  document_count <- length(batch$tokens)

  # Validate the selected metric set and every selected metric-local parameter
  # independently of both document count and per-document token validity. Ten
  # repeated valid tokens reach every current parameter validator without
  # requiring allocation proportional to a requested window or sample size.
  prototype <- .lexdiv_metrics_single(
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
    result <- .lexdiv_metrics_single(tokens = batch$tokens[[index]], ...)
    .lex_batch_prepend_id(result, batch$ids[[index]])
  })
  prototype <- pieces[[1L]]
  output <- do.call(base::rbind.data.frame, unname(pieces))
  row.names(output) <- NULL
  .lex_batch_restore_result_attributes(output, prototype)
}

#' @export
print.lexdiv_batch_results <- function(x, ...) {
  document_count <- if ("document_id" %in% names(x)) {
    length(unique(x$document_id))
  } else {
    0L
  }
  schema_version <- attr(x, "batch_schema_version", exact = TRUE)
  if (!is.character(schema_version) || length(schema_version) != 1L) {
    schema_version <- "unknown"
  }
  cat(sprintf(
    "<lexdiv_batch_results: %d document%s; %d metric record%s; schema %s>\n",
    document_count,
    if (document_count == 1L) "" else "s",
    nrow(x),
    if (nrow(x) == 1L) "" else "s",
    schema_version
  ))
  visible_names <- intersect(
    c(
      "document_id", "metric_id", "value", "status", "missing_reason", "N",
      "V", "below_quality_floor"
    ),
    names(x)
  )
  .print_lexdiv_table(x, visible_names, ...)
  invisible(x)
}
