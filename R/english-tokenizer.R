# English-oriented lexical segmentation. These are measurement rules, not
# sentence parsing, linguistic annotation, or a replica of the TUBELEX pipeline.
.lexprep_english_number_pattern <- paste0(
  "[+\\-\\x{2212}]?(?:\\p{N}+(?:[.,:/\\-]\\p{N}+)*|[.,]\\p{N}+)",
  "(?:[eE][+\\-]?\\p{N}+)?[%\\x{2030}]?"
)
.lexprep_english_url_pattern <-
  "(?i:(?:https?://|www\\.)[^\\s<>\"'()\\[\\]{}]+)"
.lexprep_english_email_pattern <-
  "[\\p{L}\\p{N}._%+\\-]+@(?:[\\p{L}\\p{N}\\-]+\\.)+\\p{L}{2,}"
.lexprep_english_word_pattern <- paste0(
  "(?=[\\p{L}\\p{M}\\p{N}'\\-]*\\p{L})",
  "[\\p{L}\\p{N}][\\p{L}\\p{M}\\p{N}]*",
  "(?:['\\-][\\p{L}\\p{N}][\\p{L}\\p{M}\\p{N}]*)*"
)
.lexprep_english_token_pattern <- paste0(
  "(?:[A-Za-z]\\.){2,}|",
  .lexprep_english_number_pattern, "(?![\\p{L}\\p{M}\\p{N}'\\-])|",
  .lexprep_english_word_pattern
)

.lexprep_tokenizer_spec <- function(tokenizer) {
  if (identical(tokenizer, "english")) {
    list(
      id = "ldfreq-english-word-tokenizer", version = "0.1.0",
      pattern = .lexprep_english_token_pattern,
      number_pattern = .lexprep_english_number_pattern
    )
  } else {
    list(
      id = .lexprep_tokenizer_id, version = .lexprep_tokenizer_version,
      pattern = .lexprep_token_pattern, number_pattern = "\\p{N}+"
    )
  }
}

.lexprep_prepare_text <- function(text, normalization, case, tokenizer) {
  text <- .lexprep_normalize_text(text, normalization, case)
  if (identical(tokenizer, "english")) {
    text <- stringi::stri_trans_char(text, "\u2018\u2019\u2010\u2011", "''--")
  }
  text
}

.lexprep_exclusion_fingerprint <- function(spans) {
  records <- if (nrow(spans)) {
    paste(spans$start, spans$end, spans$surface, spans$reason,
      sep = "\t", collapse = "\n")
  } else ""
  digest::digest(charToRaw(enc2utf8(records)), algo = "sha256", serialize = FALSE)
}

.lexprep_english_extract <- function(processed, keep_numbers) {
  # A single left-to-right scan prevents words inside recognized URLs and email
  # addresses from re-entering the lexical denominator.
  pattern <- paste(
    .lexprep_english_url_pattern, .lexprep_english_email_pattern,
    .lexprep_english_token_pattern, sep = "|"
  )
  locations <- stringi::stri_locate_all_regex(
    processed, pattern, omit_no_match = TRUE
  )[[1L]]
  surfaces <- stringi::stri_sub(processed,
    from = locations[, "start"], to = locations[, "end"])
  is_url <- stringi::stri_detect_regex(surfaces,
    paste0("^(?:", .lexprep_english_url_pattern, ")$"))
  is_email <- stringi::stri_detect_regex(surfaces,
    paste0("^(?:", .lexprep_english_email_pattern, ")$"))
  is_number <- stringi::stri_detect_regex(surfaces,
    paste0("^(?:", .lexprep_english_number_pattern, ")$"))
  excluded <- is_url | is_email | (!keep_numbers & is_number)
  spans <- data.frame(
    start = as.integer(locations[excluded, "start"]),
    end = as.integer(locations[excluded, "end"]),
    surface = surfaces[excluded],
    reason = ifelse(is_url[excluded], "url",
      ifelse(is_email[excluded], "email", "number")),
    stringsAsFactors = FALSE
  )
  # ifelse(logical(0), ...) yields logical(0), not a stable text column.
  spans$reason <- as.character(spans$reason)
  list(locations = locations[!excluded, , drop = FALSE],
    surfaces = surfaces[!excluded], is_number = is_number[!excluded],
    excluded_spans = spans)
}

.lexprep_validate_english_exclusions <- function(value) {
  provenance <- value$provenance
  spans <- provenance$excluded_spans
  valid <- is.data.frame(spans) &&
    identical(names(spans), c("start", "end", "surface", "reason")) &&
    is.integer(spans$start) && is.integer(spans$end) &&
    is.character(spans$surface) && is.character(spans$reason) &&
    !anyNA(spans) && all(validUTF8(spans$surface)) &&
    !any(Encoding(spans$surface) %in% c("bytes", "latin1")) &&
    all(spans$start >= 1L & spans$end >= spans$start) &&
    all(spans$end <= provenance$processed_characters) &&
    all(stringi::stri_length(spans$surface) == spans$end - spans$start + 1L) &&
    all(spans$reason %in% c("url", "email", "number")) &&
    (!provenance$keep_numbers || !any(spans$reason == "number")) &&
    identical(provenance$excluded_spans_sha256,
      .lexprep_exclusion_fingerprint(spans))
  if (!valid) return(FALSE)
  if (nrow(spans)) {
    classified <- .lexprep_english_extract(
      paste(spans$surface, collapse = " "), keep_numbers = FALSE)
    if (!identical(classified$excluded_spans$surface, spans$surface) ||
        !identical(classified$excluded_spans$reason, spans$reason)) return(FALSE)
  }
  # Both retained tokens and excluded spans must be ordered and disjoint.
  if (nrow(spans) > 1L && any(diff(spans$start) <= 0L)) return(FALSE)
  intervals <- rbind(value$tokens[c("start", "end")], spans[c("start", "end")])
  intervals <- intervals[order(intervals$start), , drop = FALSE]
  n <- nrow(intervals)
  n < 2L || all(intervals$start[-1L] > intervals$end[-n])
}
