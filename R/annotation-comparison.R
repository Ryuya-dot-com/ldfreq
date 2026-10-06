# Compare annotations only after establishing one-to-one token identity.
.lexannotation_documents <- function(x, argument) {
  if (!is.list(x) || is.object(x) ||
      !identical(names(attributes(x)), "names")) {
    stop(sprintf("%s must be a plain named list of tokenizations.", argument), call. = FALSE)
  }
  names(x) <- .lex_batch_validate_ids(names(x), length(x))
  for (i in seq_along(x)) {
    .lexprep_validate_tokenization(x[[i]],
      sprintf("%s document %s", argument, encodeString(names(x)[[i]], quote = '"')))
  }
  x
}

.lexannotation_changed <- function(before, after) {
  missing_before <- is.na(before)
  missing_after <- is.na(after)
  (missing_before != missing_after) |
    (!missing_before & !missing_after & before != after)
}

#' Compare two annotation versions of the same tokenized documents
#'
#' Checks source text, preprocessing and token alignment before comparing lemma,
#' UPOS and flemma columns. Named batches are paired by document ID, preserving
#' the order of the first batch. Differences are descriptive, not error labels.
#'
#' @param before,after Two tokenizations, or two plain named lists of
#'   tokenizations. Both must have the same original texts and tokenization.
#' @param max_tokens Maximum total number of paired token positions, checked
#'   before constructing the change tables.
#' @return A plain list with document-level `documents`, token-level
#'   `changes`, and complete before/after `provenance`. No input is modified.
#' @export
lexdiv_compare_annotations <- function(before, after, max_tokens = 1e6) {
  max_tokens <- .profile_positive_integer(max_tokens, "max_tokens")
  single_before <- inherits(before, "lexdiv_tokenization")
  single_after <- inherits(after, "lexdiv_tokenization")
  if (single_before != single_after) {
    stop("before and after must both be single tokenizations or both be named lists.", call. = FALSE)
  }
  if (single_before) {
    before <- list(document_1 = before)
    after <- list(document_1 = after)
  }
  before <- .lexannotation_documents(before, "before")
  after <- .lexannotation_documents(after, "after")
  ids <- names(before)
  if (!setequal(ids, names(after))) {
    stop("before and after must contain exactly the same document IDs.", call. = FALSE)
  }
  after <- after[match(ids, names(after))]
  base_columns <- c("token_index", "start", "end", "surface", "is_number")
  preprocessing <- c("source_text_sha256", "processed_text_sha256",
    "tokenizer_id", "tokenizer_version", "normalization", "case", "keep_numbers",
    "token_pattern", "input_characters", "processed_characters")
  counts <- vapply(before, function(x) as.double(nrow(x$tokens)), double(1))
  if (sum(counts) > max_tokens) {
    stop("The paired token count exceeds max_tokens.", call. = FALSE)
  }
  for (i in seq_along(before)) {
    if (!identical(before[[i]]$tokens[base_columns], after[[i]]$tokens[base_columns]) ||
        !identical(before[[i]]$provenance[preprocessing],
          after[[i]]$provenance[preprocessing])) {
      stop(sprintf("Document %s must have the same source text, preprocessing and token rows.",
        encodeString(ids[[i]], quote = '"')), call. = FALSE)
    }
  }
  layers <- c("lemma", "upos", "flemma")
  documents <- data.frame(document_id = ids, tokens = unname(counts),
    stringsAsFactors = FALSE)
  changes <- data.frame(document_id = character(), token_index = integer(),
    start = integer(), end = integer(), surface = character(), stringsAsFactors = FALSE)
  for (layer in layers) {
    documents[[paste0("before_has_", layer)]] <- vapply(before,
      function(x) layer %in% names(x$tokens), logical(1))
    documents[[paste0("after_has_", layer)]] <- vapply(after,
      function(x) layer %in% names(x$tokens), logical(1))
    documents[[paste0(layer, "_changed_tokens")]] <- rep.int(0, length(ids))
    changes[[paste0("before_", layer)]] <- character()
    changes[[paste0("after_", layer)]] <- character()
    changes[[paste0(layer, "_changed")]] <- logical()
  }
  documents$changed_tokens <- rep.int(0, length(ids))
  pieces <- vector("list", length(ids))
  for (i in seq_along(before)) {
    tokens <- before[[i]]$tokens
    rows <- data.frame(document_id = rep.int(ids[[i]], nrow(tokens)),
      tokens[c("token_index", "start", "end", "surface")], stringsAsFactors = FALSE)
    changed <- rep.int(FALSE, nrow(tokens))
    for (layer in layers) {
      a <- before[[i]]$tokens[[layer]]
      b <- after[[i]]$tokens[[layer]]
      if (is.null(a)) a <- rep.int(NA_character_, nrow(tokens))
      if (is.null(b)) b <- rep.int(NA_character_, nrow(tokens))
      difference <- .lexannotation_changed(a, b)
      rows[[paste0("before_", layer)]] <- a
      rows[[paste0("after_", layer)]] <- b
      rows[[paste0(layer, "_changed")]] <- difference
      documents[[paste0(layer, "_changed_tokens")]][i] <- sum(difference)
      changed <- changed | difference
    }
    documents$changed_tokens[i] <- sum(changed)
    pieces[[i]] <- rows[changed, , drop = FALSE]
  }
  if (length(pieces)) changes <- do.call(base::rbind.data.frame, pieces)
  row.names(changes) <- NULL
  list(documents = documents, changes = changes,
    provenance = list(before = lapply(before, `[[`, "provenance"),
      after = lapply(after, `[[`, "provenance")))
}
