# Shared in-memory corpus boundary for raw text documents.

.lexcorpus_contract_id <- "ldfreq-text-corpus"
.lexcorpus_contract_version <- "0.1.0"
.lexcorpus_manifest_fields <- c("document_id", "text_bytes", "text_sha256")

.lexcorpus_texts <- function(value, document_count) {
  if (
    !is.character(value) || is.object(value) || !is.null(dim(value)) ||
      !is.null(attributes(value)) || length(value) != document_count ||
      anyNA(value) || any(Encoding(value) %in% c("bytes", "latin1")) ||
      any(!validUTF8(value))
  ) {
    stop(
      paste(
        "The selected text column must contain one plain valid-UTF-8",
        "character string per document; empty strings are allowed."
      ),
      call. = FALSE
    )
  }
  Encoding(value) <- "UTF-8"
  value
}

.lexcorpus_metadata_names <- function(value, column_names, id_col, text_col) {
  if (is.null(value)) return(character())
  if (
    !is.character(value) || is.object(value) || !is.null(dim(value)) ||
      !is.null(attributes(value)) || anyNA(value) || any(!nzchar(value)) ||
      any(Encoding(value) %in% c("bytes", "latin1")) ||
      any(!validUTF8(value)) || anyDuplicated(value)
  ) {
    stop(
      "metadata_cols must be a plain, duplicate-free vector of valid column names.",
      call. = FALSE
    )
  }
  Encoding(value) <- "UTF-8"
  if (any(value %in% c(id_col, text_col))) {
    stop("metadata_cols may not include id_col or text_col.", call. = FALSE)
  }
  if (any(value %in% .lexcorpus_manifest_fields)) {
    stop(
      "metadata_cols may not replace reserved document-manifest fields.",
      call. = FALSE
    )
  }
  matches <- vapply(value, function(column) {
    sum(column_names == column)
  }, integer(1))
  if (any(matches != 1L)) {
    stop(
      "Every metadata_cols entry must select exactly one data-frame column.",
      call. = FALSE
    )
  }
  value
}

.lexcorpus_metadata_column <- function(value, document_count, column) {
  if (
    is.data.frame(value) || is.list(value) || !is.null(dim(value)) ||
      length(value) != document_count
  ) {
    stop(
      sprintf(
        "Metadata column '%s' must be one atomic value per document.",
        column
      ),
      call. = FALSE
    )
  }
  value
}

.lexcorpus_text_sha256 <- function(texts) {
  vapply(texts, function(text) {
    digest::digest(charToRaw(text), algo = "sha256", serialize = FALSE)
  }, character(1), USE.NAMES = FALSE)
}

#' Create a validated raw-text corpus from a data frame
#'
#' Converts an in-memory data frame, including a tibble produced by
#' `readxl::read_excel()`, into the same named raw-document corpus used by
#' [lexdiv_read_texts()]. Excel reading and dataset-specific reshaping remain
#' explicit upstream steps.
#'
#' @param data A data frame with one row per document.
#' @param id_col Name of the explicit document-ID column.
#' @param text_col Name of the raw-text column. Empty strings represent valid
#'   empty documents; missing values are rejected.
#' @param metadata_cols Optional column names to copy into the text-free
#'   document manifest. Select source sheet, source row, grouping, or other
#'   audit columns explicitly rather than retaining every input column.
#'
#' @return A `lexdiv_text_corpus` list containing `texts`, a named character
#'   vector in input-row order; `documents`, a text-free manifest; and
#'   `provenance`, the versioned conversion choices. The manifest always records
#'   UTF-8 text byte counts and SHA-256 identities.
#'
#' @details
#' Document IDs must be explicit, unique, non-empty valid-UTF-8 strings. The
#' function does not coerce numeric IDs, factors, missing values, or list-column
#' text. It performs no tokenization, normalization, row grouping, workbook
#' reading, or implicit column selection.
#'
#' For Excel data, use `readxl::read_excel()` and dataset-specific `dplyr` or
#' `tidyr` operations first. Preserve the original workbook separately, create
#' one processed row per essay, and include source sheet/row columns in
#' `metadata_cols` when row-level traceability is required.
#'
#' @export
lexdiv_text_corpus <- function(
    data,
    id_col = "document_id",
    text_col = "text",
    metadata_cols = NULL) {
  if (!is.data.frame(data)) {
    stop("data must be a data frame with one row per document.", call. = FALSE)
  }
  id_col <- .lex_batch_scalar_name(id_col, "id_col")
  text_col <- .lex_batch_scalar_name(text_col, "text_col")
  if (identical(id_col, text_col)) {
    stop("id_col and text_col must select different columns.", call. = FALSE)
  }

  column_names <- .lex_batch_column_names(names(data))
  id_matches <- which(column_names == id_col)
  text_matches <- which(column_names == text_col)
  if (length(id_matches) != 1L || length(text_matches) != 1L) {
    stop(
      "data must contain exactly one selected ID column and one selected text column.",
      call. = FALSE
    )
  }
  metadata_cols <- .lexcorpus_metadata_names(
    metadata_cols,
    column_names,
    id_col,
    text_col
  )

  document_count <- nrow(data)
  document_ids <- .lex_batch_validate_ids(
    .subset2(data, id_matches),
    document_count
  )
  texts <- .lexcorpus_texts(.subset2(data, text_matches), document_count)
  names(texts) <- document_ids

  documents <- data.frame(
    document_id = document_ids,
    text_bytes = as.double(nchar(texts, type = "bytes")),
    text_sha256 = .lexcorpus_text_sha256(texts),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  for (column in metadata_cols) {
    matches <- which(column_names == column)
    documents[[column]] <- .lexcorpus_metadata_column(
      .subset2(data, matches),
      document_count,
      column
    )
  }
  row.names(documents) <- NULL

  provenance <- list(
    contract_id = .lexcorpus_contract_id,
    contract_version = .lexcorpus_contract_version,
    input_type = "data_frame",
    id_col = id_col,
    text_col = text_col,
    metadata_cols = metadata_cols,
    document_count = document_count,
    encoding = "UTF-8",
    text_transformed = FALSE
  )
  structure(
    list(texts = texts, documents = documents, provenance = provenance),
    class = "lexdiv_text_corpus"
  )
}

#' @export
print.lexdiv_text_corpus <- function(x, ...) {
  cat(sprintf(
    "<lexdiv_text_corpus: %d document%s; %.0f text bytes; contract %s>\n",
    length(x$texts),
    if (length(x$texts) == 1L) "" else "s",
    sum(x$documents$text_bytes),
    x$provenance$contract_version
  ))
  print.data.frame(x$documents, ..., row.names = FALSE)
  invisible(x)
}
