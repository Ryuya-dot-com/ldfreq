# Document IDs are data, never inferred from row numbers, column order or paths.
.lextext_documents <- function(documents, id_col, text_col) {
  id_col <- .lex_batch_scalar_name(id_col, "id_col")
  text_col <- .lex_batch_scalar_name(text_col, "text_col")
  if (identical(id_col, text_col)) {
    stop("id_col and text_col must select different columns.", call. = FALSE)
  }
  if (is.data.frame(documents)) {
    columns <- .lex_batch_column_names(names(documents))
    if (sum(columns == id_col) != 1L || sum(columns == text_col) != 1L) {
      stop("documents must contain exactly one selected ID column and one selected text column.",
        call. = FALSE)
    }
    ids <- .lex_batch_validate_ids(documents[[which(columns == id_col)]], nrow(documents))
    texts <- documents[[which(columns == text_col)]]
    if (!is.character(texts) || !is.null(attributes(texts))) {
      stop("The selected text column must be a plain character vector.", call. = FALSE)
    }
  } else {
    if (!is.character(documents) || is.object(documents) ||
        !identical(names(attributes(documents)), "names")) {
      stop("documents must be a named character vector or a data frame with explicit ID and text columns.",
        call. = FALSE)
    }
    ids <- .lex_batch_validate_ids(names(documents), length(documents))
    texts <- unname(documents)
  }
  for (i in seq_along(texts)) {
    tryCatch(.lexprep_text(texts[[i]]), error = function(e) {
      stop(sprintf("Document %s: %s", encodeString(ids[[i]], quote = '"'),
        conditionMessage(e)), call. = FALSE)
    })
  }
  stats::setNames(as.list(texts), ids)
}

#' Tokenize multiple raw texts with explicit document IDs
#'
#' The tokenizer and settings are shared across documents. Missing text is an
#' error identifying the document; empty text is a valid zero-token document.
#' @param documents A named character vector or a data frame with explicit
#'   character ID and text columns. IDs must be unique and non-empty.
#' @param id_col,text_col Column names for data-frame input.
#' @inheritParams lexdiv_tokenize
#' @return An input-ordered named list of complete `lexdiv_tokenization` objects.
#' @export
lexdiv_tokenize_batch <- function(
    documents, id_col = "document_id", text_col = "text",
    normalization = "NFC", case = "preserve", keep_numbers = FALSE,
    tokenizer = "unicode") {
  texts <- .lextext_documents(documents, id_col, text_col)
  # Validate settings even for a zero-document corpus.
  lexdiv_tokenize("", normalization, case, keep_numbers, tokenizer)
  lapply(texts, lexdiv_tokenize, normalization = normalization, case = case,
    keep_numbers = keep_numbers, tokenizer = tokenizer)
}

#' Compute lexical diversity for multiple raw or annotated texts
#'
#' Retains document IDs, token audits, and complete preprocessing records beside
#' the long metric table. Existing tokenization objects keep their own settings;
#' explicit tokenizer arguments are rejected for that input form.
#' @param documents Raw texts as for [lexdiv_tokenize_batch()], or a plain named
#'   list of `lexdiv_tokenization` objects. Mixed raw/prepared lists are errors.
#' @inheritParams lexdiv_tokenize_batch
#' @inheritParams lexdiv_metrics_text
#' @param ... Metric requests forwarded to [lexdiv_metrics_text()].
#' @return A `lexdiv_text_batch_results` list containing `results`, `token_audit`,
#'   and a named `preprocessing` list. Zero-token documents retain metric rows
#'   and preprocessing but contribute no token-audit rows.
#' @export
lexdiv_metrics_text_batch <- function(
    documents, id_col = "document_id", text_col = "text",
    unit = "surface", word_inclusion = "all",
    normalization = "NFC", case = "preserve", keep_numbers = FALSE,
    tokenizer = "unicode", ...) {
  supplied <- c(normalization = !missing(normalization), case = !missing(case),
    keep_numbers = !missing(keep_numbers), tokenizer = !missing(tokenizer))
  if (is.list(documents) && !is.data.frame(documents)) {
    if (is.object(documents) || !identical(names(attributes(documents)), "names")) {
      stop("Prepared documents must be a plain named list of tokenization objects.", call. = FALSE)
    }
    names(documents) <- .lex_batch_validate_ids(names(documents), length(documents))
    if (any(supplied)) {
      stop("Tokenizer arguments apply only to raw text; prepared documents already record these choices.",
        call. = FALSE)
    }
    if (!missing(id_col) || !missing(text_col)) {
      stop("id_col and text_col apply only to data-frame input.", call. = FALSE)
    }
    prepared <- documents
    for (i in seq_along(prepared)) {
      .lexprep_validate_tokenization(prepared[[i]],
        sprintf("Document %s", encodeString(names(prepared)[[i]], quote = '"')))
    }
  } else {
    prepared <- lexdiv_tokenize_batch(documents, id_col, text_col,
      normalization, case, keep_numbers, tokenizer)
  }
  unit <- .lexprep_scalar_choice(unit, c("surface", "lemma", "flemma"), "unit")
  word_inclusion <- .lexprep_scalar_choice(word_inclusion, c("all", "content"), "word_inclusion")
  prototype <- lexdiv_metrics_batch(stats::setNames(list(), character()), ...)
  pieces <- lapply(seq_along(prepared), function(i) {
    tryCatch(lexdiv_metrics_text(prepared[[i]], unit = unit,
      word_inclusion = word_inclusion, ...), error = function(e) {
        stop(sprintf("Document %s: %s", encodeString(names(prepared)[[i]], quote = '"'),
          conditionMessage(e)), call. = FALSE)
      })
  })
  if (length(pieces)) {
    results <- do.call(base::rbind.data.frame, lapply(seq_along(pieces), function(i) {
      .lex_batch_prepend_id(pieces[[i]]$results, names(prepared)[[i]])
    }))
    results <- .lex_batch_restore_result_attributes(results, prototype)
    audits <- lapply(seq_along(pieces), function(i) {
      data.frame(document_id = rep.int(names(prepared)[[i]], nrow(pieces[[i]]$token_audit)),
        pieces[[i]]$token_audit, stringsAsFactors = FALSE)
    })
    token_audit <- do.call(base::rbind.data.frame, audits)
  } else {
    results <- prototype
    token_audit <- data.frame(document_id = character(),
      .lexprep_selected_units(lexdiv_tokenize(""), "surface", "all")$audit,
      stringsAsFactors = FALSE)
  }
  row.names(results) <- NULL
  row.names(token_audit) <- NULL
  structure(list(results = results, token_audit = token_audit,
    preprocessing = stats::setNames(lapply(pieces, `[[`, "preprocessing"), names(prepared))),
    class = "lexdiv_text_batch_results")
}

#' @export
print.lexdiv_text_batch_results <- function(x, ...) {
  cat(sprintf("<lexdiv_text_batch_results: %d documents; %d audited tokens>\n",
    length(x$preprocessing), nrow(x$token_audit)))
  print(x$results, ...)
  invisible(x)
}

#' @export
plot.lexdiv_text_batch_results <- function(x, ..., monochrome = FALSE) {
  plot(x$results, ..., monochrome = monochrome)
}
