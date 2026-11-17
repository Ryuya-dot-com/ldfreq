# Document IDs are data, never inferred from row numbers, column order or paths.
.lextext_documents <- function(documents, id_col, text_col) {
  id_col <- .lex_batch_scalar_name(id_col, "id_col")
  text_col <- .lex_batch_scalar_name(text_col, "text_col")
  if (identical(id_col, text_col)) {
    stop("id_col and text_col must select different columns.", call. = FALSE)
  }
  if (is.data.frame(documents)) {
    documents <- base::as.data.frame(
      documents, stringsAsFactors = FALSE, check.names = FALSE, optional = TRUE
    )
    columns <- .lex_batch_column_names(names(documents))
    if (sum(columns == id_col) != 1L || sum(columns == text_col) != 1L) {
      stop("documents must contain exactly one selected ID column and one selected text column.",
        call. = FALSE)
    }
    ids <- .lex_batch_validate_ids(
      .lex_strip_names(documents[[which(columns == id_col)]]),
      nrow(documents)
    )
    texts <- .lex_strip_names(documents[[which(columns == text_col)]])
    if (!is.character(texts) || is.object(texts) || !is.null(dim(texts)) ||
        !is.null(attributes(texts))) {
      stop("The selected text column must be a plain character vector.", call. = FALSE)
    }
  } else {
    if (!is.character(documents) || is.object(documents) ||
        !identical(names(attributes(documents)), "names")) {
      stop("x must be one plain valid-UTF-8 string, a named character vector, or a data frame with explicit ID and text columns.",
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

# Keep document-level information separate from metric and token-level fields.
.lextext_metadata <- function(metadata, ids) {
  if (is.null(metadata)) return(NULL)
  if (!is.data.frame(metadata)) {
    stop("metadata must be NULL or a data frame with a document_id column.", call. = FALSE)
  }
  metadata <- base::as.data.frame(
    metadata, stringsAsFactors = FALSE, check.names = FALSE, optional = TRUE
  )
  columns <- .lex_batch_column_names(names(metadata))
  if (any(!nzchar(columns)) || anyDuplicated(columns) || !"document_id" %in% columns) {
    stop("metadata must have unique, non-empty column names including document_id.", call. = FALSE)
  }
  names(metadata) <- columns
  metadata$document_id <- .lex_batch_validate_ids(
    .lex_strip_names(metadata$document_id),
    nrow(metadata)
  )
  if (!all(vapply(metadata, function(column) {
    is.atomic(column) && is.null(dim(column))
  }, logical(1)))) {
    stop("metadata columns must contain one atomic value per document, not lists or matrices.",
      call. = FALSE)
  }
  missing_ids <- setdiff(ids, metadata$document_id)
  extra_ids <- setdiff(metadata$document_id, ids)
  if (length(missing_ids) || length(extra_ids)) {
    stop(sprintf(
      "metadata must match the input documents exactly: %d missing ID(s), %d extra ID(s).",
      length(missing_ids), length(extra_ids)), call. = FALSE)
  }
  metadata <- metadata[match(ids, metadata$document_id),
    c("document_id", setdiff(columns, "document_id")), drop = FALSE]
  row.names(metadata) <- NULL
  metadata
}

.lexdiv_tokenize_batch <- function(
    documents, id_col = "document_id", text_col = "text",
    normalization = "NFC", case = "lower", keep_numbers = FALSE,
    tokenizer = "english") {
  texts <- .lextext_documents(documents, id_col, text_col)
  # Validate settings even for a zero-document corpus.
  .lexdiv_tokenize_single("", normalization, case, keep_numbers, tokenizer, warn_cjk = FALSE)
  out <- lapply(texts, .lexdiv_tokenize_single,
    normalization = normalization, case = case,
    keep_numbers = keep_numbers, tokenizer = tokenizer, warn_cjk = FALSE)
  if (identical(tokenizer, "english") && length(texts)) {
    cjk_hits <- names(texts)[vapply(texts, function(txt) {
      nzchar(txt) && stringi::stri_detect_regex(txt, .lexprep_cjk_pattern)
    }, logical(1L))]
    if (length(cjk_hits)) {
      shown <- paste(encodeString(utils::head(cjk_hits, 3L), quote = '"'), collapse = ", ")
      more <- if (length(cjk_hits) > 3L) sprintf(" (and %d more)", length(cjk_hits) - 3L) else ""
      warning(
        sprintf(
          "%d document(s) contain CJK (Han/Hiragana/Katakana) characters (%s%s); tokenizer = \"english\" does not segment unspaced CJK text into words. Use lexdiv_import_annotations() with a morphological analyzer for Japanese or Chinese text.",
          length(cjk_hits), shown, more
        ),
        call. = FALSE
      )
    }
  }
  out
}

.lexdiv_metrics_text_batch <- function(
    documents, id_col = "document_id", text_col = "text",
    unit = "surface", word_inclusion = "all",
    normalization = "NFC", case = "lower", keep_numbers = FALSE,
    tokenizer = "english",
    metrics = setdiff(lexdiv_metric_ids(), c("expected_ttr_d", "mtld_ma")),
    segment_length = 50L, window_length = 50L, mtld_threshold = 0.72,
    sample_size = 42L, expected_ttr_sample_sizes = 35:50,
    plan = NULL, max_rows = 1e6, metadata = NULL,
    retain_token_audit = TRUE,
    supplied_tokenizer = c(normalization = !missing(normalization), case = !missing(case),
      keep_numbers = !missing(keep_numbers), tokenizer = !missing(tokenizer)),
    supplied_id_text = c(id_col = !missing(id_col), text_col = !missing(text_col)),
    supplied_metrics = c(metrics = !missing(metrics), segment_length = !missing(segment_length),
      window_length = !missing(window_length), mtld_threshold = !missing(mtld_threshold),
      sample_size = !missing(sample_size), expected_ttr_sample_sizes = !missing(expected_ttr_sample_sizes)),
    supplied_max_rows = !missing(max_rows)) {
  retain_token_audit <- .lexprep_scalar_flag(retain_token_audit, "retain_token_audit")
  if (is.list(documents) && !is.data.frame(documents)) {
    if (is.object(documents) || !identical(names(attributes(documents)), "names")) {
      stop("Prepared documents must be a plain named list of tokenization objects.", call. = FALSE)
    }
    names(documents) <- .lex_batch_validate_ids(names(documents), length(documents))
    if (any(supplied_tokenizer)) {
      stop("Tokenizer arguments apply only to raw text; prepared documents already record these choices.",
        call. = FALSE)
    }
    if (any(supplied_id_text)) {
      stop("id_col and text_col apply only to data-frame input.", call. = FALSE)
    }
    prepared <- documents
    for (i in seq_along(prepared)) {
      .lexprep_validate_tokenization(prepared[[i]],
        sprintf("Document %s", encodeString(names(prepared)[[i]], quote = '"')))
    }
  } else {
    prepared <- .lexdiv_tokenize_batch(documents, id_col, text_col,
      normalization, case, keep_numbers, tokenizer)
  }
  metadata <- .lextext_metadata(metadata, names(prepared))
  unit <- .lexprep_scalar_choice(unit, c("surface", "lemma", "flemma"), "unit")
  word_inclusion <- .lexprep_scalar_choice(word_inclusion, c("all", "content"), "word_inclusion")

  if (!is.null(plan)) {
    if (any(supplied_metrics)) {
      stop("With plan, omit metrics and individual metric parameters; put requests in the plan.", call. = FALSE)
    }
    max_rows <- .profile_positive_integer(max_rows, "max_rows")
    plan <- .profile_validate_plan(plan)
    pieces <- lapply(seq_along(prepared), function(i) {
      tryCatch(.lexdiv_metrics_text_single(prepared[[i]], unit = unit,
        word_inclusion = word_inclusion, plan = plan,
        retain_token_audit = retain_token_audit), error = function(e) {
          stop(sprintf("Document %s: %s", encodeString(names(prepared)[[i]], quote = '"'),
            conditionMessage(e)), call. = FALSE)
        })
    })
    selected_units <- stats::setNames(
      lapply(prepared, function(tok) .lexprep_selected_units(tok, unit, word_inclusion)$units),
      names(prepared)
    )
    results <- .lexdiv_profile_batch(selected_units, plan = plan, max_rows = max_rows)
  } else {
    if (isTRUE(supplied_max_rows)) {
      stop("max_rows requires a non-NULL plan.", call. = FALSE)
    }
    prototype <- .lexdiv_metrics_batch(
      stats::setNames(list(), character()),
      metrics = metrics,
      segment_length = segment_length,
      window_length = window_length,
      mtld_threshold = mtld_threshold,
      sample_size = sample_size,
      expected_ttr_sample_sizes = expected_ttr_sample_sizes
    )
    pieces <- lapply(seq_along(prepared), function(i) {
      tryCatch(.lexdiv_metrics_text_single(
        prepared[[i]],
        unit = unit,
        word_inclusion = word_inclusion,
        metrics = metrics,
        segment_length = segment_length,
        window_length = window_length,
        mtld_threshold = mtld_threshold,
        sample_size = sample_size,
        expected_ttr_sample_sizes = expected_ttr_sample_sizes,
        retain_token_audit = retain_token_audit
      ), error = function(e) {
        stop(sprintf("Document %s: %s", encodeString(names(prepared)[[i]], quote = '"'),
          conditionMessage(e)), call. = FALSE)
      })
    })
    if (length(pieces)) {
      results <- do.call(base::rbind.data.frame, lapply(seq_along(pieces), function(i) {
        .lex_batch_prepend_id(pieces[[i]]$results, names(prepared)[[i]])
      }))
      results <- .lex_batch_restore_result_attributes(results, prototype)
    } else {
      results <- prototype
    }
  }

  empty_audit <- data.frame(
    document_id = character(),
    .lexprep_selected_units(.lexdiv_tokenize_single("", warn_cjk = FALSE), "surface", "all")$audit,
    stringsAsFactors = FALSE
  )
  if (retain_token_audit && length(pieces)) {
    audits <- lapply(seq_along(pieces), function(i) {
      data.frame(document_id = rep.int(names(prepared)[[i]], nrow(pieces[[i]]$token_audit)),
        pieces[[i]]$token_audit, stringsAsFactors = FALSE)
    })
    token_audit <- do.call(base::rbind.data.frame, audits)
  } else {
    token_audit <- empty_audit
  }
  row.names(results) <- NULL
  row.names(token_audit) <- NULL
  output <- structure(list(results = results, token_audit = token_audit,
    preprocessing = stats::setNames(lapply(pieces, `[[`, "preprocessing"), names(prepared))),
    class = "lexdiv_text_batch_results")
  if (!is.null(metadata)) output$metadata <- metadata
  output
}

#' @export
print.lexdiv_text_batch_results <- function(x, ...) {
  cat(sprintf("<lexdiv_text_batch_results: %d documents; %d audited tokens>\n",
    length(x$preprocessing), nrow(x$token_audit)))
  print(x$results, ...)
  if (!is.null(x$metadata)) {
    cat(sprintf("Metadata: %d documents; %d study fields in $metadata.\n",
      nrow(x$metadata), ncol(x$metadata) - 1L))
  }
  invisible(x)
}

#' @export
plot.lexdiv_text_batch_results <- function(x, ..., monochrome = FALSE) {
  plot(x$results, ..., monochrome = monochrome)
}
