# Explicitly sourced examples; sentence boundaries are supplied by the caller.
.readability_hash <- function(x) digest::digest(x, algo = "sha256", serializeVersion = 2L)
.readability_string <- function(x) is.character(x) && length(x) == 1L &&
  !is.na(x) && validUTF8(x) && nzchar(stringi::stri_trim_both(x))
.readability_whole <- function(x, name, minimum = 1) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) ||
      x < minimum || x != floor(x) || x > .Machine$integer.max)
    stop(paste(name, "must be one finite whole number >=", minimum), call. = FALSE)
  as.integer(x)
}
.readability_check <- function(x, kind) {
  if (!is.list(x) || !identical(x$kind, kind) || !identical(x$recipe_version, "1") ||
      !identical(x$integrity_sha256, .readability_hash(x[names(x) != "integrity_sha256"])))
    stop("The saved readability record changed; recreate it from its source.", call. = FALSE)
  invisible(x)
}

readability_prepare <- function(segments, language, sentence_policy,
    include = rep(TRUE, nrow(segments)), max_tokens = 1e6) {
  if (!identical(language, "en"))
    stop("Only explicitly declared English (language = 'en') is supported.", call. = FALSE)
  if (!.readability_string(sentence_policy))
    stop("sentence_policy must describe the supplied boundaries and exclusions.", call. = FALSE)
  max_tokens <- .readability_whole(max_tokens, "max_tokens")
  required <- c("document_id", "segment_id", "text")
  if (!is.data.frame(segments) || !all(required %in% names(segments)) || !nrow(segments) ||
      anyDuplicated(names(segments)))
    stop("segments must have document_id, segment_id and text, with at least one row.", call. = FALSE)
  segments <- as.data.frame(segments[required], stringsAsFactors = FALSE)
  if (any(!vapply(segments, function(z) is.character(z) && !anyNA(z) && all(validUTF8(z)), logical(1))) ||
      any(!nzchar(stringi::stri_trim_both(segments$document_id))) ||
      any(!nzchar(stringi::stri_trim_both(segments$segment_id))) ||
      anyDuplicated(segments[c("document_id", "segment_id")]))
    stop("Text must be valid non-missing UTF-8; IDs must be nonblank and unique within document.", call. = FALSE)
  if (!is.logical(include) || length(include) != nrow(segments) || anyNA(include))
    stop("include must have one non-missing logical value per supplied segment.", call. = FALSE)
  segments[] <- lapply(segments, enc2utf8)
  rownames(segments) <- NULL
  segments$include <- include
  tokenized <- vector("list", nrow(segments)); tokens <- tokenized
  total <- 0L
  for (i in seq_len(nrow(segments))) {
    z <- ldfreq::lexdiv_tokenize(segments$text[i], tokenizer = "english",
      normalization = "none", case = "preserve", keep_numbers = TRUE)
    total <- total + nrow(z$tokens)
    if (total > max_tokens) stop("Source exceeds max_tokens; no result was truncated.", call. = FALSE)
    t <- z$tokens
    t$segment_row <- rep(i, nrow(t))
    t$original_surface <- stringi::stri_sub(segments$text[i], t$start, t$end)
    tokens[[i]] <- t
    tokenized[[i]] <- z$provenance
  }
  tokens <- do.call(rbind, tokens); rownames(tokens) <- NULL
  tokens$token_row <- seq_len(nrow(tokens))
  tokens$document_id <- segments$document_id[tokens$segment_row]
  tokens$segment_id <- segments$segment_id[tokens$segment_row]
  tokens$counted <- segments$include[tokens$segment_row]
  segments$words <- tabulate(tokens$segment_row, nrow(segments))
  segments$counted_sentence <- segments$include & segments$words > 0
  segments$status <- ifelse(!segments$include, "excluded_segment",
    ifelse(segments$words == 0, "no_words", "counted"))
  result <- list(kind = "readability-source", recipe_version = "1", segments = segments,
    tokens = tokens, tokenization = tokenized,
    settings = list(language = language, sentence_policy = sentence_policy, max_tokens = max_tokens,
      sentence_unit = "one supplied included segment containing at least one word",
      word_unit = "ldfreq English tokenizer; numbers retained; URL/email/punctuation excluded",
      offsets = "one-based Unicode code points within original segment"),
    ldfreq_version = as.character(utils::packageVersion("ldfreq")))
  result$integrity_sha256 <- .readability_hash(result)
  result
}

readability_score <- function(prepared, syllables = NULL, syllable_source = NULL,
    short_text_words = 100L) {
  .readability_check(prepared, "readability-source")
  short_text_words <- .readability_whole(short_text_words, "short_text_words", 0)
  t <- prepared$tokens
  source_id <- prepared$integrity_sha256
  if (is.null(syllables)) {
    if (!is.null(syllable_source))
      stop("syllable_source is supplied only with caller-provided syllables.", call. = FALSE)
    if (!requireNamespace("nsyllable", quietly = TRUE))
      stop("Install nsyllable for estimates, or supply a source-bound syllable table.", call. = FALSE)
    lower <- stringi::stri_trans_tolower(t$surface, locale = "en")
    dictionary <- nsyllable::data_syllables_en
    estimate <- as.numeric(nsyllable::nsyllable(lower))
    kind <- ifelse(lower %in% names(dictionary), "dictionary", "vowel_group_estimate")
    # Digits and dotted initialisms require a declared pronunciation, not a vowel guess.
    pronunciation <- stringi::stri_detect_regex(t$surface, "[0-9]|^(?:[A-Za-z]\\.){2,}$")
    estimate[pronunciation] <- NA_real_
    kind[is.na(estimate)] <- "unavailable"
    kind[pronunciation] <- "pronunciation_required"
    syllables <- data.frame(source_id = rep(source_id, nrow(t)), token_row = t$token_row,
      syllables = estimate, method = kind, stringsAsFactors = FALSE)
    syllable_source <- list(method = "nsyllable estimates; digits and dotted initialisms withheld",
      package = "nsyllable", version = as.character(utils::packageVersion("nsyllable")),
      dictionary_sha256 = .readability_hash(dictionary), lower_case = "stringi English locale",
      missing = "retained as NA; no one-syllable substitution")
  } else {
    required <- c("source_id", "token_row", "syllables", "method")
    if (!is.data.frame(syllables) || !all(required %in% names(syllables)) ||
        anyDuplicated(names(syllables)) || nrow(syllables) != nrow(t) ||
        !is.character(syllables$source_id) || anyNA(syllables$source_id) ||
        any(syllables$source_id != source_id) || !is.numeric(syllables$token_row) ||
        anyNA(syllables$token_row) || anyDuplicated(syllables$token_row) ||
        !setequal(syllables$token_row, t$token_row))
      stop("Supply exactly one source_id/token_row syllable row per prepared token.", call. = FALSE)
    if (!.readability_string(syllable_source))
      stop("syllable_source must describe the caller's counting or review method.", call. = FALSE)
    syllables <- syllables[match(t$token_row, syllables$token_row), , drop = FALSE]
    syllable_source <- list(method = syllable_source, package = NA_character_, version = NA_character_)
  }
  n <- syllables$syllables
  if (!is.numeric(n) || any(!is.na(n) & (!is.finite(n) | n < 1 | n != floor(n) | n > .Machine$integer.max)) ||
      any(is.nan(n)) || !is.character(syllables$method) || anyNA(syllables$method) ||
      any(!validUTF8(syllables$method)) || any(!nzchar(stringi::stri_trim_both(syllables$method))))
    stop("Syllable counts must be positive whole numbers or NA, with a nonblank method per token.", call. = FALSE)
  rownames(syllables) <- NULL
  ids <- unique(prepared$segments$document_id)
  d <- match(t$document_id, ids)
  included <- t$counted
  known <- included & !is.na(n)
  W <- tabulate(d[included], length(ids))
  S <- tabulate(match(prepared$segments$document_id[prepared$segments$counted_sentence], ids), length(ids))
  missing <- tabulate(d[included & is.na(n)], length(ids))
  known_syllables <- numeric(length(ids))
  if (any(known)) {
    totals <- rowsum(n[known], d[known], reorder = FALSE)
    known_syllables[as.integer(rownames(totals))] <- totals[, 1]
  }
  Sy <- known_syllables
  Sy[missing > 0 | W == 0] <- NA_real_
  status <- ifelse(W == 0, "no_words", ifelse(missing > 0, "missing_syllables", "ok"))
  fre <- fk <- rep(NA_real_, length(ids))
  ok <- status == "ok"
  fre[ok] <- 206.835 - 1.015 * W[ok] / S[ok] - 84.6 * Sy[ok] / W[ok]
  fk[ok] <- .39 * W[ok] / S[ok] + 11.8 * Sy[ok] / W[ok] - 15.59
  components <- data.frame(document_id = ids, words = W, sentences = S, syllables = Sy,
    known_syllables = known_syllables, missing_syllable_words = missing,
    below_word_threshold = W < short_text_words, status = status, stringsAsFactors = FALSE)
  settings <- list(short_text_words = short_text_words,
    threshold = "advisory flag only; does not suppress scores or establish validity",
    Flesch_Reading_Ease = "206.835 - 1.015 * W/S - 84.6 * Sy/W",
    Flesch_Kincaid_Grade = "0.39 * W/S + 11.8 * Sy/W - 15.59",
    aggregation = "whole included text; ratios of document totals; no sentence-score averaging",
    interpretation = "formula estimates under recorded counts; no clipping or ability classification")
  analysis_id <- .readability_hash(list(source_id, syllables, syllable_source, settings))
  results <- components[rep(seq_along(ids), each = 2L), , drop = FALSE]
  results$measure <- rep(c("Flesch_Reading_Ease", "Flesch_Kincaid_Grade"), length(ids))
  results$value <- as.vector(rbind(fre, fk))
  results$analysis_id <- analysis_id
  rownames(results) <- NULL
  result <- list(kind = "readability-result", recipe_version = "1", results = results,
    components = components, source = prepared, syllables = syllables,
    syllable_source = syllable_source, settings = settings, analysis_id = analysis_id)
  result$integrity_sha256 <- .readability_hash(result)
  result
}

readability_validate <- function(x) .readability_check(x, "readability-result")
