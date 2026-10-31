# Import complete external annotations before selecting lexical forms or rows.
.lexann_seal <- function(x) {
  body <- unclass(x[names(x) != "integrity_sha256"])
  x$integrity_sha256 <- .concordance_hash(body)
  class(x) <- "lexdiv_annotations"
  x
}

.lexann_check <- function(x, argument = "x", max_tokens = 1e6) {
  max_tokens <- .lexnorm_positive_whole(max_tokens, "max_tokens")
  if (is.list(x) && !is.object(x) &&
      all(c("tokens", "segments", "provenance") %in% names(x)) &&
      is.list(x$provenance) &&
      identical(x$provenance$importer, "ldfreq-external-annotations") &&
      identical(x$provenance$importer_version, "0.1.0")) {
    segments <- .lexnorm_plain_data_frame(x$segments, paste0(argument, "$segments"))
    rechecked <- lexdiv_import_annotations(
      x$tokens,
      segments[setdiff(names(segments), c("token_count", "text_sha256"))],
      x$provenance$annotation,
      max_tokens = max_tokens
    )
    legacy_expected <- unclass(rechecked[c("tokens", "segments", "documents", "provenance")])
    legacy_expected$provenance$importer_version <- "0.1.0"
    if (!identical(x, legacy_expected)) {
      stop(argument, " has changed; import the complete annotations again.", call. = FALSE)
    }
    return(x)
  }
  if (!inherits(x, "lexdiv_annotations") || !is.list(x) ||
      !all(c("tokens", "segments", "documents", "provenance", "integrity_sha256") %in% names(x)) ||
      !is.list(x$provenance) ||
      !identical(x$provenance$importer, "ldfreq-external-annotations")) {
    stop(argument, " must be an unchanged, unmodified lexdiv_import_annotations() result.", call. = FALSE)
  }
  if (!is.character(x$integrity_sha256) || length(x$integrity_sha256) != 1L ||
      !identical(x$integrity_sha256,
        .concordance_hash(unclass(x[names(x) != "integrity_sha256"])))) {
    stop(argument, " has changed; import the complete annotations again.", call. = FALSE)
  }
  if (!is.data.frame(x$tokens) || nrow(x$tokens) > max_tokens) {
    stop("The number of input rows exceeds max_tokens.", call. = FALSE)
  }
  x
}

lexdiv_import_annotations <- function(data, segments, provenance, max_tokens = 1e6) {
  data <- .lexnorm_plain_data_frame(data, "data")
  segments <- .lexnorm_plain_data_frame(segments, "segments")
  keys <- c("document_id", "segment_id")
  if (!all(c(keys, "token_index", "surface") %in% names(data)) ||
      !all(c(keys, "text") %in% names(segments)))
    stop("Supply token IDs, token_index and surface, and segment IDs with text.", call. = FALSE)
  if (any(c("token_count", "text_sha256") %in% names(segments)))
    stop("token_count and text_sha256 are reserved segment output columns.", call. = FALSE)
  max_tokens <- .lexnorm_positive_whole(max_tokens, "max_tokens")
  if (nrow(data) > max_tokens)
    stop("The number of input rows exceeds max_tokens.", call. = FALSE)
  for (key in keys) {
    data[[key]] <- .lexnorm_plain_character(data[[key]], key, allow_zero = TRUE)
    segments[[key]] <- .lexnorm_plain_character(segments[[key]], key, allow_zero = TRUE)
  }
  data$surface <- .lexnorm_plain_character(data$surface, "surface", allow_zero = TRUE)
  source <- .lex_strip_names(segments$text)
  if (!is.character(source) || !is.null(attributes(source)) || anyNA(source) ||
      any(Encoding(source) %in% c("bytes", "latin1")) || any(!validUTF8(source)))
    stop("segments$text must contain plain valid-UTF-8 strings; empty text is allowed.",
      call. = FALSE)
  Encoding(source) <- "UTF-8"
  segments$text <- source
  position <- .lexng_count(data$token_index, "token_index", 1)
  segment_key <- .lexng_key(segments[keys])
  group <- match(.lexng_key(data[keys]), segment_key)
  if (!nrow(segments) || anyDuplicated(segment_key) || anyNA(group) ||
      any(diff(group) < 0))
    stop("Supply unique segments and token rows in matching segment order.", call. = FALSE)
  document_ids <- unique(segments$document_id)
  if (any(diff(match(segments$document_id, document_ids)) < 0))
    stop("Each document must occupy one contiguous block of segments.", call. = FALSE)
  provenance <- .lexnorm_plain_list(provenance, "provenance")
  required <- c("language", "analyzer", "analyzer_version", "dictionary",
    "dictionary_version", "unit", "normalization")
  if (!all(required %in% names(provenance)))
    stop("provenance requires: ", paste(required, collapse = ", "), ".", call. = FALSE)
  for (key in names(provenance)) {
    value <- provenance[[key]]
    if (identical(value, NA_character_) && !key %in% required) next
    provenance[[key]] <- .lexnorm_scalar_string(value, paste0("provenance$", key))
  }
  # Work in Unicode codepoints, not bytes, UTF-16 units or normalized text.
  # Only whitespace may occur between supplied surfaces. In particular, a
  # later repeated token cannot conceal an omitted non-whitespace token.
  rows <- split(seq_len(nrow(data)), factor(group, levels = seq_len(nrow(segments))))
  starts <- ends <- integer(nrow(data))
  width <- stringi::stri_length(data$surface)
  begins_space <- stringi::stri_detect_regex(data$surface, "^\\p{White_Space}")
  for (i in seq_len(nrow(segments))) {
    idx <- rows[[i]]
    if (!identical(position[idx], as.double(seq_along(idx))))
      stop("Import all tokens with consecutive token_index starting at 1; filter afterwards.",
        call. = FALSE)
    space <- rep(FALSE, stringi::stri_length(source[i]))
    whitespace <- stringi::stri_locate_all_regex(source[i], "\\p{White_Space}")[[1L]][, 1L]
    space[whitespace[!is.na(whitespace)]] <- TRUE
    cursor <- 1L
    for (j in idx) {
      if (begins_space[j]) {
        # An analyzer may emit CR tokens but omit LF in CRLF sequences.
        # Match the earliest exact surface after whitespace-only gaps; never
        # advance across an omitted letter, punctuation or other content.
        while (cursor <= length(space) && space[cursor] &&
            stringi::stri_sub(source[i], cursor, cursor + width[j] - 1L) != data$surface[j])
          cursor <- cursor + 1L
      } else {
        while (cursor <= length(space) && space[cursor]) cursor <- cursor + 1L
      }
      starts[j] <- cursor
      ends[j] <- cursor + width[j] - 1L
      cursor <- ends[j] + 1L
    }
    if (length(idx) && (any(ends[idx] > length(space)) ||
        any(stringi::stri_sub(source[i], starts[idx], ends[idx]) != data$surface[idx])))
      stop("Surfaces do not align exactly with original text in segment row ", i,
        "; import complete, unnormalized annotations before filtering.", call. = FALSE)
    if (cursor <= length(space) && any(!space[seq.int(cursor, length(space))]))
      stop("Unannotated non-whitespace text remains in segment row ", i, ".", call. = FALSE)
  }
  for (key in c("start", "end")) {
    computed <- if (key == "start") starts else ends
    if (key %in% names(data) &&
        !identical(.lexng_count(data[[key]], key, 1), as.double(computed)))
      stop("Supplied ", key, " does not match segment-local, 1-based codepoint positions.",
        call. = FALSE)
    data[[key]] <- computed
  }
  segments$token_count <- as.integer(lengths(rows))
  segments$text_sha256 <- vapply(source, digest::digest, character(1),
    algo = "sha256", serialize = FALSE, USE.NAMES = FALSE)
  documents <- data.frame(document_id = document_ids, stringsAsFactors = FALSE)
  rownames(data) <- rownames(segments) <- NULL
  .lexann_seal(list(tokens = data, segments = segments, documents = documents,
    provenance = list(importer = "ldfreq-external-annotations", importer_version = "0.2.0",
      coordinates = "segment-local-1-based-inclusive-Unicode-codepoints",
      alignment = "exact-surfaces-whitespace-gaps-only", normalization = "none",
      annotation = provenance,
      input_sha256 = digest::digest(list(data, segments, provenance),
        algo = "sha256", serializeVersion = 2L))))
}

.lexann_complete_spans <- function(seg_text, w_start, w_end, w_num) {
  len <- stringi::stri_length(seg_text)
  if (len == 0L) {
    return(data.frame(
      start = integer(), end = integer(), surface = character(),
      is_word = logical(), is_number = logical(),
      stringsAsFactors = FALSE
    ))
  }
  g_from <- if (length(w_start)) c(1L, w_end + 1L) else 1L
  g_to <- if (length(w_start)) c(w_start - 1L, len) else len
  valid_gaps <- which(g_from <= g_to)
  gap_starts <- gap_ends <- integer()
  for (k in valid_gaps) {
    sub <- stringi::stri_sub(seg_text, g_from[k], g_to[k])
    loc <- stringi::stri_locate_all_regex(
      sub, "\\P{White_Space}+", omit_no_match = TRUE
    )[[1L]]
    if (!is.null(dim(loc)) && nrow(loc) > 0L) {
      gap_starts <- c(gap_starts, as.integer(g_from[k] + loc[, 1L] - 1L))
      gap_ends <- c(gap_ends, as.integer(g_from[k] + loc[, 2L] - 1L))
    }
  }
  all_start <- c(as.integer(w_start), gap_starts)
  all_end <- c(as.integer(w_end), gap_ends)
  all_word <- c(rep.int(TRUE, length(w_start)), rep.int(FALSE, length(gap_starts)))
  all_num <- c(as.logical(w_num), rep.int(FALSE, length(gap_starts)))
  if (!length(all_start)) {
    return(data.frame(
      start = integer(), end = integer(), surface = character(),
      is_word = logical(), is_number = logical(),
      stringsAsFactors = FALSE
    ))
  }
  ord <- order(all_start)
  all_start <- all_start[ord]
  all_end <- all_end[ord]
  surfaces <- stringi::stri_sub(seg_text, all_start, all_end)
  Encoding(surfaces) <- "UTF-8"
  data.frame(
    start = all_start,
    end = all_end,
    surface = surfaces,
    is_word = all_word[ord],
    is_number = all_num[ord],
    stringsAsFactors = FALSE
  )
}

#' Convert raw texts or tokenizations into source-aligned corpus annotations
#'
#' Bridges `ldfreq`'s raw-text preprocessing and corpus-analysis workflows
#' ([lexdiv_concordance()], [lexdiv_collocations()], [lexdiv_keyness()],
#' [lexdiv_ambiguity_review()], and [lexdiv_family_profile()]) by partitioning
#' every non-whitespace span in each document while distinguishing lexical word
#' tokens (`is_word = TRUE` and normalized/cased `term`) from punctuation and
#' excluded spans (`is_word = FALSE`, `term = NA_character_`).
#'
#' @param documents A named character vector of texts, a data frame or tibble
#'   containing `id_col` and `text_col`, a single `lexdiv_tokenization` object,
#'   or a named list of `lexdiv_tokenization` objects. A single unnamed string
#'   is assigned document ID `"document_1"`.
#' @param texts Required only when `documents` is a `lexdiv_tokenization`
#'   object or named list of tokenizations: the original raw texts (as a
#'   matching character vector or data frame) verified against each
#'   tokenization's `source_text_sha256`.
#' @param id_col,text_col Column names for data-frame inputs.
#' @param normalization,case,keep_numbers,tokenizer Preprocessing parameters
#'   used when `documents` supplies raw texts directly. Ignored when
#'   `documents` already contains `lexdiv_tokenization` objects.
#' @param language Path-free language code recorded in annotation provenance.
#' @param max_tokens Maximum total token/non-word spans across all documents.
#' @return A sealed `lexdiv_annotations` object ready for
#'   [lexdiv_concordance()], [lexdiv_keyness()], and related corpus tools.
#' @export
lexdiv_as_annotations <- function(
    documents,
    texts = NULL,
    id_col = "document_id",
    text_col = "text",
    normalization = "NFC",
    case = "lower",
    keep_numbers = FALSE,
    tokenizer = "english",
    language = "en",
    max_tokens = 1e6) {
  language <- .lexnorm_scalar_string(language, "language")
  max_tokens <- .lexnorm_positive_whole(max_tokens, "max_tokens")

  is_tok_input <- inherits(documents, "lexdiv_tokenization") ||
    (is.list(documents) && !is.data.frame(documents) && length(documents) > 0L &&
      all(vapply(documents, inherits, logical(1L), "lexdiv_tokenization")))

  if (is_tok_input) {
    if (is.null(texts)) {
      stop(
        "Supply texts alongside lexdiv_tokenization inputs so exact segment text and non-word spans can be verified.",
        call. = FALSE
      )
    }
    if (inherits(documents, "lexdiv_tokenization")) {
      documents <- list(document_1 = documents)
      if (is.character(texts) && !is.object(texts) && is.null(dim(texts)) &&
          length(texts) == 1L && is.null(names(texts))) {
        texts <- c(document_1 = texts)
      }
    }
    tok_list <- .lexannotation_documents(documents, "documents")
    text_map <- .lextext_documents(texts, id_col, text_col)
    if (!setequal(names(tok_list), names(text_map))) {
      stop("documents and texts must contain the exact same document IDs.", call. = FALSE)
    }
    raw_texts <- unname(unlist(text_map[names(tok_list)]))
    ids <- names(tok_list)
    first_prov <- tok_list[[1L]]$provenance
    tok_kind <- if (identical(first_prov$tokenizer_id, "ldfreq-english-word-tokenizer")) {
      "english"
    } else {
      "unicode"
    }
    has_lemma <- all(vapply(tok_list, function(z) "lemma" %in% names(z$tokens), logical(1L)))
    has_upos <- all(vapply(tok_list, function(z) "upos" %in% names(z$tokens), logical(1L)))
    has_flemma <- all(vapply(tok_list, function(z) "flemma" %in% names(z$tokens), logical(1L)))

    token_pieces <- vector("list", length(ids))
    seg_texts <- character(length(ids))
    running <- 0
    for (i in seq_along(ids)) {
      tk <- tok_list[[i]]
      p <- tk$provenance
      if (!identical(p$tokenizer_id, first_prov$tokenizer_id) ||
          !identical(p$normalization, first_prov$normalization) ||
          !identical(p$case, first_prov$case) ||
          !identical(p$keep_numbers, first_prov$keep_numbers)) {
        stop("All tokenizations in documents must share the same preprocessing settings.", call. = FALSE)
      }
      raw_i <- .lexprep_text(raw_texts[[i]])
      raw_hash <- digest::digest(charToRaw(enc2utf8(raw_i)), algo = "sha256", serialize = FALSE)
      if (!identical(raw_hash, p$source_text_sha256)) {
        stop(sprintf("Supplied text for document %s does not match source_text_sha256.",
          encodeString(ids[[i]], quote = '"')), call. = FALSE)
      }
      proc_i <- .lexprep_prepare_text(raw_i, p$normalization, p$case, tok_kind)
      seg_texts[[i]] <- proc_i
      spans <- .lexann_complete_spans(
        proc_i, tk$tokens$start, tk$tokens$end, tk$tokens$is_number
      )
      running <- running + nrow(spans)
      if (running > max_tokens) {
        stop("The number of input rows exceeds max_tokens.", call. = FALSE)
      }
      word_idx <- which(spans$is_word)
      term_vec <- rep.int(NA_character_, nrow(spans))
      term_vec[word_idx] <- tk$tokens$surface
      df <- data.frame(
        document_id = rep.int(ids[[i]], nrow(spans)),
        segment_id = rep.int("s1", nrow(spans)),
        token_index = seq_len(nrow(spans)),
        surface = spans$surface,
        term = term_vec,
        is_word = spans$is_word,
        is_number = spans$is_number,
        stringsAsFactors = FALSE
      )
      if (has_lemma) {
        col <- rep.int(NA_character_, nrow(spans))
        col[word_idx] <- tk$tokens$lemma
        df$lemma <- col
      }
      if (has_upos) {
        col <- rep.int(NA_character_, nrow(spans))
        col[word_idx] <- tk$tokens$upos
        df$upos <- col
      }
      if (has_flemma) {
        col <- rep.int(NA_character_, nrow(spans))
        col[word_idx] <- tk$tokens$flemma
        df$flemma <- col
      }
      df$start <- spans$start
      df$end <- spans$end
      token_pieces[[i]] <- df
    }
    token_data <- if (length(token_pieces)) {
      do.call(base::rbind.data.frame, token_pieces)
    } else {
      data.frame(
        document_id = character(), segment_id = character(),
        token_index = integer(), surface = character(), term = character(),
        is_word = logical(), is_number = logical(),
        start = integer(), end = integer(), stringsAsFactors = FALSE
      )
    }
    seg_df <- data.frame(
      document_id = ids,
      segment_id = rep.int("s1", length(ids)),
      text = seg_texts,
      stringsAsFactors = FALSE
    )
    dict_id <- if (has_flemma) {
      first_prov$flemma_annotation$resource_id
    } else if (has_lemma && !is.null(first_prov$annotation$dictionary)) {
      first_prov$annotation$dictionary$id
    } else {
      "none"
    }
    dict_ver <- if (has_flemma) {
      ver <- first_prov$flemma_annotation$resource_version
      if (is.null(ver)) "unversioned" else ver
    } else if (has_lemma && !is.null(first_prov$annotation$dictionary)) {
      first_prov$annotation$dictionary$version
    } else {
      "none"
    }
    prov <- list(
      language = language,
      analyzer = first_prov$tokenizer_id,
      analyzer_version = first_prov$tokenizer_version,
      dictionary = dict_id,
      dictionary_version = dict_ver,
      unit = if (has_flemma) "flemma" else if (has_lemma) "lemma" else "term",
      normalization = paste0(first_prov$normalization, ":", first_prov$case)
    )
    return(lexdiv_import_annotations(token_data, seg_df, prov, max_tokens = max_tokens))
  }

  if (!is.null(texts)) {
    stop("texts must be NULL when documents supplies raw text directly.", call. = FALSE)
  }
  if (is.character(documents) && !is.object(documents) && is.null(dim(documents)) &&
      length(documents) == 1L && is.null(names(documents))) {
    documents <- c(document_1 = documents)
  }
  normalization <- .lexprep_scalar_choice(
    normalization, c("NFC", "NFKC", "none"), "normalization"
  )
  case <- .lexprep_scalar_choice(case, c("preserve", "lower"), "case")
  keep_numbers <- .lexprep_scalar_flag(keep_numbers, "keep_numbers")
  tokenizer <- .lexprep_scalar_choice(tokenizer, c("unicode", "english"), "tokenizer")
  spec <- .lexprep_tokenizer_spec(tokenizer)
  text_map <- .lextext_documents(documents, id_col, text_col)
  doc_ids <- names(text_map)
  if (!length(doc_ids)) {
    stop("Supply at least one document to convert into annotations.", call. = FALSE)
  }

  token_pieces <- vector("list", length(doc_ids))
  seg_texts <- character(length(doc_ids))
  running <- 0
  for (i in seq_along(doc_ids)) {
    raw_i <- text_map[[i]]
    seg_i <- switch(
      normalization,
      none = raw_i,
      NFC = stringi::stri_trans_nfc(raw_i),
      NFKC = stringi::stri_trans_nfkc(raw_i)
    )
    Encoding(seg_i) <- "UTF-8"
    seg_texts[[i]] <- seg_i
    scan_i <- if (identical(tokenizer, "english")) {
      stringi::stri_trans_char(seg_i, "\u2018\u2019\u2010\u2011", "''--")
    } else {
      seg_i
    }
    if (identical(tokenizer, "english")) {
      ex <- .lexprep_english_extract(scan_i, keep_numbers)
      w_start <- as.integer(ex$locations[, "start"])
      w_end <- as.integer(ex$locations[, "end"])
      w_num <- ex$is_number
    } else {
      loc <- stringi::stri_locate_all_regex(
        scan_i, .lexprep_token_pattern, omit_no_match = TRUE
      )[[1L]]
      if (is.null(dim(loc)) || nrow(loc) == 0L) {
        w_start <- w_end <- integer()
        w_num <- logical()
      } else {
        surf <- stringi::stri_sub(scan_i, loc[, "start"], loc[, "end"])
        is_num <- stringi::stri_detect_regex(surf, "^\\p{N}+$")
        keep_mask <- if (keep_numbers) rep.int(TRUE, length(is_num)) else !is_num
        w_start <- as.integer(loc[keep_mask, "start"])
        w_end <- as.integer(loc[keep_mask, "end"])
        w_num <- is_num[keep_mask]
      }
    }
    spans <- .lexann_complete_spans(seg_i, w_start, w_end, w_num)
    running <- running + nrow(spans)
    if (running > max_tokens) {
      stop("The number of input rows exceeds max_tokens.", call. = FALSE)
    }
    term_vec <- rep.int(NA_character_, nrow(spans))
    if (any(spans$is_word)) {
      term_vec[spans$is_word] <- .lexprep_prepare_text(
        spans$surface[spans$is_word], "none", case, tokenizer
      )
    }
    token_pieces[[i]] <- data.frame(
      document_id = rep.int(doc_ids[[i]], nrow(spans)),
      segment_id = rep.int("s1", nrow(spans)),
      token_index = seq_len(nrow(spans)),
      surface = spans$surface,
      term = term_vec,
      is_word = spans$is_word,
      is_number = spans$is_number,
      start = spans$start,
      end = spans$end,
      stringsAsFactors = FALSE
    )
  }
  token_data <- do.call(base::rbind.data.frame, token_pieces)
  rownames(token_data) <- NULL
  seg_df <- data.frame(
    document_id = doc_ids,
    segment_id = rep.int("s1", length(doc_ids)),
    text = seg_texts,
    stringsAsFactors = FALSE
  )
  prov <- list(
    language = language,
    analyzer = spec$id,
    analyzer_version = spec$version,
    dictionary = "none",
    dictionary_version = "none",
    unit = "term",
    normalization = paste0(normalization, ":", case)
  )
  lexdiv_import_annotations(token_data, seg_df, prov, max_tokens = max_tokens)
}

#' @export
print.lexdiv_annotations <- function(x, ...) {
  .lexann_check(x, "x", max_tokens = .Machine$integer.max)
  doc_n <- nrow(x$documents)
  seg_n <- nrow(x$segments)
  tok_n <- nrow(x$tokens)
  cat(sprintf(
    "<lexdiv_annotations: %d document%s; %d segment%s; %d token%s; analyzer %s>\n",
    doc_n, if (doc_n == 1L) "" else "s",
    seg_n, if (seg_n == 1L) "" else "s",
    tok_n, if (tok_n == 1L) "" else "s",
    x$provenance$annotation$analyzer
  ))
  shown <- utils::head(x$tokens, 12L)
  print.data.frame(shown, row.names = FALSE, ...)
  if (tok_n > nrow(shown)) {
    cat(sprintf("... %d additional token row%s omitted\n",
      tok_n - nrow(shown), if (tok_n - nrow(shown) == 1L) "" else "s"))
  }
  invisible(x)
}
