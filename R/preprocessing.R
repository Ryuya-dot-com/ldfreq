# Versioned raw-text preprocessing and lexical-unit selection.
#
# The versioned lexical-diversity core continues to accept only plain ordered
# character vectors.  This file adds a separate envelope so that tokenization,
# lemmatization, and word-inclusion choices are explicit rather than hidden in
# metric computation.

.lexprep_contract_id <- "ldfreq-preprocessing"
.lexprep_contract_version <- "0.3.0"
.lexprep_tokenizer_id <- "ldfreq-unicode-word-tokenizer"
.lexprep_tokenizer_version <- "0.1.0"
.lexprep_flemma_backend_id <- "ldfreq-antbnc-flemma-adapter"
.lexprep_flemma_backend_version <- "0.1.0"
.lexprep_antbnc_resource_id <- "antbnc-lemma-list"
.lexprep_antbnc_parser_id <- "ldfreq-antbnc-parser"
.lexprep_antbnc_parser_version <- "0.1.0"
.lexprep_antbnc_max_bytes <- 25 * 1024^2
.lexprep_antbnc_cache_limit <- 4L
.lexprep_antbnc_cache <- new.env(parent = emptyenv())
.lexprep_flemma_normalization_ids <- c(
  nfkc_lower = "nfkc-trim-en-lower-v1",
  identity = "identity-valid-utf8-v1"
)
.lexprep_token_pattern <- paste0(
  "[\\p{L}\\p{M}\\p{N}]+",
  "(?:['\u2019\\-\u2010\u2011][\\p{L}\\p{M}\\p{N}]+)*"
)
.lexprep_content_upos <- c("ADJ", "ADV", "NOUN", "PROPN", "VERB")
.lexprep_upos_tags <- c(
  "ADJ", "ADP", "ADV", "AUX", "CCONJ", "DET", "INTJ", "NOUN", "NUM",
  "PART", "PRON", "PROPN", "PUNCT", "SCONJ", "SYM", "VERB", "X"
)

.lexprep_is_plain_choice <- function(value, choices) {
  is.character(value) && !is.object(value) && is.null(dim(value)) &&
    is.null(attributes(value)) && length(value) == 1L && !is.na(value) &&
    nzchar(value) && any(vapply(choices, identical, logical(1), value))
}

.lexprep_scalar_choice <- function(value, choices, argument) {
  if (!.lexprep_is_plain_choice(value, choices)) {
    stop(
      sprintf(
        "%s must be exactly one of: %s.",
        argument,
        paste(choices, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  value
}

.lexprep_scalar_flag <- function(value, argument) {
  if (
    !is.logical(value) || is.object(value) || !is.null(dim(value)) ||
      !is.null(attributes(value)) || length(value) != 1L || is.na(value)
  ) {
    stop(sprintf("%s must be TRUE or FALSE.", argument), call. = FALSE)
  }
  value
}

.lexprep_scalar_string <- function(value, argument) {
  if (
    !is.character(value) || is.object(value) || !is.null(dim(value)) ||
      !is.null(attributes(value)) || length(value) != 1L || is.na(value) ||
      !nzchar(value) || Encoding(value) %in% c("bytes", "latin1") ||
      !validUTF8(value)
  ) {
    stop(
      sprintf("%s must be one plain, non-empty valid-UTF-8 string.", argument),
      call. = FALSE
    )
  }
  Encoding(value) <- "UTF-8"
  value
}

.lexprep_looks_like_path <- function(value) {
  grepl("[/\\\\]", value) ||
    value %in% c(".", "..") ||
    grepl("^[A-Za-z]:", value) ||
    grepl("^~($|[/\\\\])", value) ||
    grepl("^file:(//)?", value, ignore.case = TRUE)
}

.lexprep_is_path_free_identifier <- function(value) {
  is.character(value) && !is.object(value) && is.null(dim(value)) &&
    is.null(attributes(value)) && length(value) == 1L && !is.na(value) &&
    nzchar(value) && !(Encoding(value) %in% c("bytes", "latin1")) &&
    validUTF8(value) && !grepl("[[:cntrl:]]", value) &&
    !.lexprep_looks_like_path(value)
}

.lexprep_is_count <- function(value, minimum = 0, maximum = Inf) {
  is.numeric(value) && !is.object(value) && is.null(dim(value)) &&
    length(value) == 1L && !is.na(value) && is.finite(value) &&
    value >= minimum && value <= maximum && value == floor(value)
}

.lexprep_is_optional_path_free_identifier <- function(value) {
  is.null(value) || .lexprep_is_path_free_identifier(value)
}

.lexprep_coverage_matches <- function(count, total, coverage) {
  if (total == 0L) {
    is.numeric(coverage) && length(coverage) == 1L && is.na(coverage)
  } else {
    is.numeric(coverage) && length(coverage) == 1L && !is.na(coverage) &&
      identical(as.double(coverage), as.double(count / total))
  }
}

.lexprep_flemma_override_version_is_valid <- function(annotation) {
  if (
    !is.list(annotation) || is.object(annotation) ||
      !.lexprep_is_count(annotation$override_entries)
  ) {
    return(FALSE)
  }
  if (annotation$override_entries == 0) {
    is.null(annotation$override_version)
  } else {
    .lexprep_is_optional_path_free_identifier(annotation$override_version)
  }
}

.lexprep_upos_identity_is_valid <- function(annotation, expected_upos_tokens) {
  if (!is.list(annotation) || is.object(annotation)) return(FALSE)
  if (expected_upos_tokens == 0) {
    is.null(annotation$upos_backend_id) &&
      is.null(annotation$upos_backend_version)
  } else {
    .lexprep_is_path_free_identifier(annotation$upos_backend_id) &&
      .lexprep_is_path_free_identifier(annotation$upos_backend_version)
  }
}

.lexprep_annotation_backend_is_valid <- function(annotation) {
  if (!is.list(annotation) || is.object(annotation)) return(FALSE)
  method <- annotation$method
  if (
    !.lexprep_is_plain_choice(method, c("supplied", "textstem")) ||
      !.lexprep_is_path_free_identifier(annotation$backend_id) ||
      !.lexprep_is_path_free_identifier(annotation$backend_version)
  ) {
    return(FALSE)
  }
  !identical(method, "textstem") ||
    identical(annotation$backend_id, "textstem::lemmatize_words")
}

.lexprep_flemma_identity_rows_are_valid <- function(token_table, annotation) {
  if (
    !is.list(annotation) || is.object(annotation) ||
      !.lexprep_is_plain_choice(
        annotation$query_normalization,
        c("nfkc_lower", "identity")
      )
  ) {
    return(FALSE)
  }
  identity <- token_table$flemma_match_rule == "identity"
  if (!any(identity)) return(TRUE)
  expected <- .lexprep_flemma_normalize(
    token_table$surface[identity],
    annotation$query_normalization
  )
  identical(
    unname(token_table$flemma[identity]),
    unname(expected)
  )
}

.lexprep_scalar_identifier <- function(value, argument) {
  value <- .lexprep_scalar_string(value, argument)
  if (grepl("[[:cntrl:]]", value) || .lexprep_looks_like_path(value)) {
    stop(
      sprintf("%s must be a path-free identifier without control characters.", argument),
      call. = FALSE
    )
  }
  value
}

.lexprep_text <- function(text) {
  if (
    !is.character(text) || is.object(text) || !is.null(dim(text)) ||
      !is.null(attributes(text)) || length(text) != 1L || is.na(text) ||
      Encoding(text) %in% c("bytes", "latin1") || !validUTF8(text)
  ) {
    stop(
      "text must be one plain valid-UTF-8 character string.",
      call. = FALSE
    )
  }
  Encoding(text) <- "UTF-8"
  text
}

.lexprep_optional_annotation <- function(value, size, argument) {
  if (is.null(value)) return(rep.int(NA_character_, size))
  if (
    !is.character(value) || is.object(value) || !is.null(dim(value)) ||
      !is.null(attributes(value)) || length(value) != size ||
      any(!is.na(value) & !nzchar(value)) ||
      any(!is.na(value) & Encoding(value) %in% c("bytes", "latin1")) ||
      any(!is.na(value) & !validUTF8(value))
  ) {
    stop(
      sprintf(
        "%s must be a plain character vector aligned one-to-one with the tokens; missing values are allowed.",
        argument
      ),
      call. = FALSE
    )
  }
  Encoding(value[!is.na(value)]) <- "UTF-8"
  value
}

.lexprep_required_strings <- function(value, argument) {
  if (
    !is.character(value) || is.object(value) || !is.null(dim(value)) ||
      !is.null(attributes(value)) || anyNA(value) || any(!nzchar(value)) ||
      any(Encoding(value) %in% c("bytes", "latin1")) ||
      any(!validUTF8(value))
  ) {
    stop(
      sprintf(
        "%s must contain plain, non-empty valid-UTF-8 strings.",
        argument
      ),
      call. = FALSE
    )
  }
  Encoding(value) <- "UTF-8"
  value
}

.lexprep_is_tokenization <- function(value) {
  inherits(value, "lexdiv_tokenization") && is.list(value) &&
    identical(names(value), c("tokens", "provenance")) &&
    is.data.frame(value$tokens) && is.list(value$provenance)
}

.lexprep_validate_annotation_column <- function(value, size, argument) {
  is.character(value) &&
    !is.object(value) &&
    is.null(dim(value)) &&
    length(value) == size &&
    all(is.na(value) | nzchar(value)) &&
    all(is.na(value) | !(Encoding(value) %in% c("bytes", "latin1"))) &&
    all(is.na(value) | validUTF8(value))
}

.lexprep_token_fingerprint <- function(tokens) {
  records <- if (nrow(tokens)) {
    paste(tokens$token_index, tokens$start, tokens$end, tokens$surface,
      tokens$is_number, sep = "\t", collapse = "\n")
  } else {
    ""
  }
  digest::digest(charToRaw(enc2utf8(records)), algo = "sha256", serialize = FALSE)
}

.lexprep_is_sha256 <- function(value) {
  is.character(value) && !is.object(value) && is.null(attributes(value)) &&
    length(value) == 1L && !is.na(value) && grepl("^[0-9a-f]{64}$", value)
}

.lexprep_validate_tokenization <- function(value, argument = "x") {
  if (!.lexprep_is_tokenization(value)) {
    stop(
      sprintf("%s must be created by lexdiv_tokenize().", argument),
      call. = FALSE
    )
  }
  required <- c("token_index", "start", "end", "surface", "is_number")
  if (!all(required %in% names(value$tokens))) {
    stop(sprintf("%s has an invalid tokenization table.", argument), call. = FALSE)
  }
  row_count <- nrow(value$tokens)
  provenance <- value$provenance
  tokenizer <- if (identical(provenance$tokenizer_id, "ldfreq-english-word-tokenizer")) {
    "english"
  } else "unicode"
  specification <- .lexprep_tokenizer_spec(tokenizer)
  positions_are_valid <-
    is.integer(value$tokens$start) &&
      length(value$tokens$start) == row_count &&
      !anyNA(value$tokens$start) &&
      is.integer(value$tokens$end) &&
      length(value$tokens$end) == row_count &&
      !anyNA(value$tokens$end)
  if (
    !identical(value$tokens$token_index, seq_len(row_count)) ||
      !positions_are_valid ||
      !is.character(value$tokens$surface) ||
      length(value$tokens$surface) != row_count ||
      anyNA(value$tokens$surface) || any(!nzchar(value$tokens$surface)) ||
      any(Encoding(value$tokens$surface) %in% c("bytes", "latin1")) ||
      any(!validUTF8(value$tokens$surface)) ||
      !is.logical(value$tokens$is_number) || anyNA(value$tokens$is_number)
  ) {
    stop(sprintf("%s has an invalid tokenization table.", argument), call. = FALSE)
  }
  if (row_count > 0L) {
    offsets_are_valid <-
      all(value$tokens$start >= 1L) &&
        all(value$tokens$end >= value$tokens$start) &&
        all(
          stringi::stri_length(value$tokens$surface) ==
            value$tokens$end - value$tokens$start + 1L
        ) &&
        (
          row_count == 1L ||
            all(value$tokens$start[-1L] > value$tokens$end[-row_count])
        )
    number_flags_are_valid <- identical(
      value$tokens$is_number,
      stringi::stri_detect_regex(value$tokens$surface,
        paste0("^(?:", specification$number_pattern, ")$"))
    )
    if (!offsets_are_valid || !number_flags_are_valid) {
      stop(sprintf("%s has an invalid tokenization table.", argument), call. = FALSE)
    }
  }

  provenance_is_valid <-
    is.list(provenance) && !is.object(provenance) &&
      identical(provenance$contract_id, .lexprep_contract_id) &&
      (identical(provenance$contract_version, .lexprep_contract_version) ||
        (identical(tokenizer, "unicode") &&
          identical(provenance$contract_version, "0.2.0"))) &&
      identical(provenance$tokenizer_id, specification$id) &&
      identical(provenance$tokenizer_version, specification$version) &&
      identical(provenance$token_pattern, specification$pattern) &&
      .lexprep_is_sha256(provenance$source_text_sha256) &&
      .lexprep_is_sha256(provenance$processed_text_sha256) &&
      .lexprep_is_sha256(provenance$token_table_sha256) &&
      .lexprep_is_count(provenance$input_characters) &&
      .lexprep_is_count(provenance$processed_characters) &&
      .lexprep_is_plain_choice(
        provenance$normalization,
        c("NFC", "NFKC", "none")
      ) &&
      .lexprep_is_plain_choice(provenance$case, c("preserve", "lower")) &&
      is.logical(provenance$keep_numbers) && !is.object(provenance$keep_numbers) &&
      is.null(dim(provenance$keep_numbers)) &&
      is.null(attributes(provenance$keep_numbers)) &&
      length(provenance$keep_numbers) == 1L && !is.na(provenance$keep_numbers) &&
      is.numeric(provenance$output_tokens) &&
      length(provenance$output_tokens) == 1L &&
      identical(as.double(provenance$output_tokens), as.double(row_count))
  if (!provenance_is_valid) {
    stop(sprintf(
      "%s has invalid preprocessing provenance; recreate it with lexdiv_tokenize() and reapply annotations.",
      argument
    ), call. = FALSE)
  }
  surfaces <- value$tokens$surface
  content_is_valid <-
    all(value$tokens$end <= provenance$processed_characters) &&
      all(stringi::stri_detect_regex(surfaces, paste0("^(?:", specification$pattern, ")$"))) &&
      identical(surfaces, .lexprep_prepare_text(
        surfaces, provenance$normalization, provenance$case, tokenizer
      )) &&
      (provenance$keep_numbers || !any(value$tokens$is_number)) &&
      identical(provenance$token_table_sha256, .lexprep_token_fingerprint(value$tokens))
  if (!content_is_valid) {
    stop(sprintf(
      "%s has token content inconsistent with its preprocessing provenance; recreate it with lexdiv_tokenize().",
      argument
    ), call. = FALSE)
  }
  if (identical(tokenizer, "english") &&
      !.lexprep_validate_english_exclusions(value)) {
    stop(sprintf("%s has invalid tokenizer exclusion records.", argument), call. = FALSE)
  }

  annotation_columns <- c("lemma", "upos")
  annotation_present <- annotation_columns %in% names(value$tokens)
  if (any(annotation_present) && !all(annotation_present)) {
    stop(sprintf("%s has an incomplete lemma/UPOS annotation layer.", argument), call. = FALSE)
  }
  if (all(annotation_present)) {
    annotation <- provenance$annotation
    expected_lemma_tokens <- as.double(sum(!is.na(value$tokens$lemma)))
    expected_upos_tokens <- as.double(sum(!is.na(value$tokens$upos)))
    expected_lemma_coverage <- if (row_count == 0L) {
      NA_real_
    } else {
      expected_lemma_tokens / row_count
    }
    expected_upos_coverage <- if (row_count == 0L) {
      NA_real_
    } else {
      expected_upos_tokens / row_count
    }
    upos_identity_is_valid <- .lexprep_upos_identity_is_valid(
      annotation,
      expected_upos_tokens
    )
    annotation_is_valid <-
      .lexprep_validate_annotation_column(
        value$tokens$lemma,
        row_count,
        "lemma"
      ) &&
      .lexprep_validate_annotation_column(
        value$tokens$upos,
        row_count,
        "upos"
      ) &&
      all(is.na(value$tokens$upos) | value$tokens$upos %in% .lexprep_upos_tags) &&
      .lexprep_annotation_backend_is_valid(annotation) &&
      upos_identity_is_valid &&
      identical(annotation$lemma_tokens, expected_lemma_tokens) &&
      identical(annotation$lemma_coverage, expected_lemma_coverage) &&
      identical(annotation$upos_tokens, expected_upos_tokens) &&
      identical(annotation$upos_coverage, expected_upos_coverage)
    if (!annotation_is_valid) {
      stop(sprintf("%s has an invalid lemma/UPOS annotation layer.", argument), call. = FALSE)
    }
  }

  flemma_columns <- c("flemma", "flemma_matched", "flemma_match_rule")
  flemma_present <- flemma_columns %in% names(value$tokens)
  if (any(flemma_present) && !all(flemma_present)) {
    stop(sprintf("%s has an incomplete flemma annotation layer.", argument), call. = FALSE)
  }
  if (all(flemma_present)) {
    rule <- value$tokens$flemma_match_rule
    matched <- value$tokens$flemma_matched
    flemma_table_is_valid <-
      .lexprep_validate_annotation_column(
        value$tokens$flemma,
        row_count,
        "flemma"
      ) &&
      !anyNA(value$tokens$flemma) &&
      is.logical(matched) && length(matched) == row_count && !anyNA(matched) &&
      is.character(rule) && !is.object(rule) && is.null(dim(rule)) &&
      length(rule) == row_count && !anyNA(rule) &&
      all(rule %in% c("antbnc", "override", "identity")) &&
      identical(matched, rule != "identity")
    if (!flemma_table_is_valid) {
      stop(sprintf("%s has an invalid flemma annotation layer.", argument), call. = FALSE)
    }

    flemma_annotation <- provenance$flemma_annotation
    expected_matched_tokens <- as.double(sum(matched))
    expected_matched_coverage <- if (row_count == 0L) {
      NA_real_
    } else {
      expected_matched_tokens / row_count
    }
    expected_identity_tokens <- as.double(sum(rule == "identity"))
    expected_override_tokens <- as.double(sum(rule == "override"))
    expected_resource_rule_tokens <- as.double(sum(rule == "antbnc"))
    flemma_is_valid <-
      is.list(flemma_annotation) && !is.object(flemma_annotation) &&
      identical(flemma_annotation$method, "antbnc") &&
      identical(flemma_annotation$lexical_unit, "flemma") &&
      identical(flemma_annotation$backend_id, .lexprep_flemma_backend_id) &&
      identical(
        flemma_annotation$backend_version,
        .lexprep_flemma_backend_version
      ) &&
      identical(flemma_annotation$parser_id, .lexprep_antbnc_parser_id) &&
      identical(flemma_annotation$parser_version, .lexprep_antbnc_parser_version) &&
      identical(flemma_annotation$resource_id, .lexprep_antbnc_resource_id) &&
      .lexprep_is_optional_path_free_identifier(
        flemma_annotation$resource_version
      ) &&
      identical(flemma_annotation$resource_source_type, "local_text") &&
      .lexprep_is_count(flemma_annotation$source_records, minimum = 1) &&
      .lexprep_is_count(
        flemma_annotation$mapping_records,
        minimum = flemma_annotation$source_records
      ) &&
      .lexprep_is_count(
        flemma_annotation$resource_matched_tokens,
        maximum = row_count
      ) &&
      flemma_annotation$resource_matched_tokens >= expected_resource_rule_tokens &&
      flemma_annotation$resource_matched_tokens <=
        expected_resource_rule_tokens + expected_override_tokens &&
      .lexprep_coverage_matches(
        flemma_annotation$resource_matched_tokens,
        row_count,
        flemma_annotation$resource_match_coverage
      ) &&
      .lexprep_flemma_override_version_is_valid(flemma_annotation) &&
      (expected_override_tokens == 0 || flemma_annotation$override_entries > 0) &&
      .lexprep_is_plain_choice(
        flemma_annotation$query_normalization,
        c("nfkc_lower", "identity")
      ) &&
      .lexprep_flemma_identity_rows_are_valid(
        value$tokens,
        flemma_annotation
      ) &&
      identical(
        flemma_annotation$query_normalization_id,
        unname(.lexprep_flemma_normalization_ids[[
          flemma_annotation$query_normalization
        ]])
      ) &&
      identical(flemma_annotation$input_tokens, as.double(row_count)) &&
      identical(flemma_annotation$matched_tokens, expected_matched_tokens) &&
      identical(
        flemma_annotation$matched_coverage,
        expected_matched_coverage
      ) &&
      identical(
        flemma_annotation$identity_fallback_tokens,
        expected_identity_tokens
      ) &&
      identical(
        flemma_annotation$override_tokens,
        expected_override_tokens
      ) &&
      identical(
        flemma_annotation$unknown_form_policy,
        "normalized-surface-identity-fallback"
      ) &&
      identical(flemma_annotation$resource_bundled, FALSE) &&
      identical(flemma_annotation$runtime_download, FALSE)
    if (!flemma_is_valid) {
      stop(sprintf("%s has an invalid flemma annotation layer.", argument), call. = FALSE)
    }
  }
  value
}

.lexprep_normalize_text <- function(text, normalization, case) {
  normalized <- switch(
    normalization,
    none = text,
    NFC = stringi::stri_trans_nfc(text),
    NFKC = stringi::stri_trans_nfkc(text)
  )
  if (identical(case, "lower")) {
    normalized <- stringi::stri_trans_tolower(normalized, locale = "en")
  }
  Encoding(normalized) <- "UTF-8"
  normalized
}

#' Tokenize one raw text with a versioned Unicode word contract
#'
#' Extracts Unicode letter/mark/number sequences while preserving internal
#' apostrophes and hyphens. Punctuation is not returned as a token. Unicode
#' normalization, case handling, and pure-number inclusion are explicit
#' parameters and are recorded in the returned provenance.
#'
#' @param text One plain valid-UTF-8 character string. An empty string is valid
#'   and returns zero tokens.
#' @param normalization Unicode normalization applied before token extraction:
#'   `"NFC"`, `"NFKC"`, or `"none"`.
#' @param case Either `"preserve"` or locale-fixed English `"lower"`.
#' @param keep_numbers Whether tokens consisting only of Unicode numbers are
#'   retained. Alphanumeric tokens such as `"COVID-19"` are retained under
#'   either setting.
#' @param tokenizer `"unicode"` preserves the original word rules.
#'   `"english"` uses the English lexical rules, excludes URLs and email
#'   addresses, recognizes number-like expressions and dotted initialisms,
#'   and canonicalizes curly apostrophes and hyphen typography. It keeps
#'   contractions and hyphenated words intact. Neither method is Treebank.
#'
#' @return A `lexdiv_tokenization` object containing a token table and a
#'   versioned preprocessing provenance record. The `surface` column can be
#'   supplied directly to [lexdiv_metrics()].
#' @export
lexdiv_tokenize <- function(
    text,
    normalization = "NFC",
    case = "preserve",
    keep_numbers = FALSE,
    tokenizer = "unicode") {
  text <- .lexprep_text(text)
  normalization <- .lexprep_scalar_choice(
    normalization,
    c("NFC", "NFKC", "none"),
    "normalization"
  )
  case <- .lexprep_scalar_choice(case, c("preserve", "lower"), "case")
  keep_numbers <- .lexprep_scalar_flag(keep_numbers, "keep_numbers")
  tokenizer <- .lexprep_scalar_choice(tokenizer, c("unicode", "english"), "tokenizer")
  specification <- .lexprep_tokenizer_spec(tokenizer)
  processed <- .lexprep_prepare_text(text, normalization, case, tokenizer)

  if (identical(tokenizer, "english")) {
    extracted <- .lexprep_english_extract(processed, keep_numbers)
    locations <- extracted$locations
    surfaces <- extracted$surfaces
    is_number <- extracted$is_number
  } else {
    locations <- stringi::stri_locate_all_regex(
      processed,
      .lexprep_token_pattern,
      omit_no_match = TRUE
    )[[1L]]
    if (is.null(dim(locations)) || nrow(locations) == 0L) {
      locations <- matrix(integer(), nrow = 0L, ncol = 2L)
      colnames(locations) <- c("start", "end")
      surfaces <- character()
      is_number <- logical()
    } else {
      surfaces <- stringi::stri_sub(
        processed,
        from = locations[, "start"],
        to = locations[, "end"]
      )
      is_number <- stringi::stri_detect_regex(surfaces, "^\\p{N}+$")
      if (!keep_numbers && any(is_number)) {
        retained <- !is_number
        locations <- locations[retained, , drop = FALSE]
        surfaces <- surfaces[retained]
        is_number <- is_number[retained]
      }
    }
  }
  Encoding(surfaces) <- "UTF-8"

  token_table <- data.frame(
    token_index = seq_along(surfaces),
    start = as.integer(locations[, "start"]),
    end = as.integer(locations[, "end"]),
    surface = surfaces,
    is_number = is_number,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  provenance <- list(
    contract_id = .lexprep_contract_id,
    contract_version = .lexprep_contract_version,
    tokenizer_id = specification$id,
    tokenizer_version = specification$version,
    normalization = normalization,
    case = case,
    keep_numbers = keep_numbers,
    token_pattern = specification$pattern,
    source_text_sha256 = digest::digest(
      charToRaw(enc2utf8(text)),
      algo = "sha256",
      serialize = FALSE
    ),
    processed_text_sha256 = digest::digest(
      charToRaw(enc2utf8(processed)),
      algo = "sha256",
      serialize = FALSE
    ),
    token_table_sha256 = .lexprep_token_fingerprint(token_table),
    input_characters = as.double(stringi::stri_length(text)),
    processed_characters = as.double(stringi::stri_length(processed)),
    output_tokens = as.double(nrow(token_table)),
    annotation = NULL
  )
  if (identical(tokenizer, "english")) {
    provenance$excluded_spans <- extracted$excluded_spans
    provenance$excluded_spans_sha256 <- .lexprep_exclusion_fingerprint(extracted$excluded_spans)
  }
  structure(
    list(tokens = token_table, provenance = provenance),
    class = "lexdiv_tokenization"
  )
}

#' Add explicit lemmas and optional universal POS tags
#'
#' Adds a lemma layer to an object created by [lexdiv_tokenize()]. Lemmas may be
#' supplied by the caller with an explicit backend identity, or computed using
#' the optional `textstem` package. This function does not silently choose or
#' download a model.
#'
#' @param x A `lexdiv_tokenization` object.
#' @param method Either `"supplied"` or `"textstem"`.
#' @param lemmas For `method = "supplied"`, a character vector aligned with the
#'   token rows. Missing lemmas are allowed and later reported as exclusions.
#' @param upos Optional aligned Universal POS tags. Missing values are allowed.
#'   Non-missing tags are uppercased and must belong to the Universal POS
#'   inventory; unsupported labels are errors rather than non-content words.
#'   The `textstem` backend supplies lemmas only; it does not infer UPOS. Supply
#'   tags explicitly when a later `word_inclusion = "content"` analysis is
#'   required.
#' @param backend_id,backend_version Required path-free lemma-backend
#'   identifiers for supplied annotations. For `textstem`, package identity and
#'   installed version are recorded automatically and these arguments must be
#'   `NULL`.
#' @param upos_backend_id,upos_backend_version Path-free UPOS-backend
#'   identifiers, required whenever any UPOS tag is present. They are kept
#'   separate from lemma-backend identity even when one pipeline created both.
#'
#' @return The tokenization object with `lemma` and `upos` columns and an
#'   annotation provenance record.
#' @export
lexdiv_lemmatize <- function(
    x,
    method = "supplied",
    lemmas = NULL,
    upos = NULL,
    backend_id = NULL,
    backend_version = NULL,
    upos_backend_id = NULL,
    upos_backend_version = NULL) {
  x <- .lexprep_validate_tokenization(x)
  method <- .lexprep_scalar_choice(
    method,
    c("supplied", "textstem"),
    "method"
  )
  row_count <- nrow(x$tokens)

  if (identical(method, "supplied")) {
    if (is.null(lemmas)) {
      stop("lemmas must be supplied when method = \"supplied\".", call. = FALSE)
    }
    lemmas <- .lexprep_optional_annotation(lemmas, row_count, "lemmas")
    backend_id <- .lexprep_scalar_identifier(backend_id, "backend_id")
    backend_version <- .lexprep_scalar_identifier(
      backend_version,
      "backend_version"
    )
  } else {
    if (!is.null(lemmas)) {
      stop("lemmas must be NULL when method = \"textstem\".", call. = FALSE)
    }
    if (!is.null(backend_id) || !is.null(backend_version)) {
      stop(
        "backend_id and backend_version must be NULL when method = \"textstem\".",
        call. = FALSE
      )
    }
    if (!requireNamespace("textstem", quietly = TRUE)) {
      stop(
        "method = \"textstem\" requires the suggested textstem package.",
        call. = FALSE
      )
    }
    lemmas <- unname(textstem::lemmatize_words(x$tokens$surface))
    lemmas <- .lexprep_optional_annotation(lemmas, row_count, "textstem lemmas")
    backend_id <- "textstem::lemmatize_words"
    backend_version <- as.character(utils::packageVersion("textstem"))
  }
  upos <- .lexprep_optional_annotation(upos, row_count, "upos")
  upos[!is.na(upos)] <- toupper(upos[!is.na(upos)])
  unsupported_upos <- unique(upos[!is.na(upos) & !(upos %in% .lexprep_upos_tags)])
  if (length(unsupported_upos) > 0L) {
    stop(
      sprintf(
        "upos contains unsupported Universal POS tag(s): %s.",
        paste(unsupported_upos, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  has_upos <- any(!is.na(upos))
  supplied_upos_identity <- !is.null(upos_backend_id) ||
    !is.null(upos_backend_version)
  if (has_upos && !supplied_upos_identity) {
    stop(
      "upos_backend_id and upos_backend_version are required when UPOS tags are present.",
      call. = FALSE
    )
  } else if (has_upos) {
    if (is.null(upos_backend_id) || is.null(upos_backend_version)) {
      stop(
        "upos_backend_id and upos_backend_version must be supplied together.",
        call. = FALSE
      )
    }
    upos_backend_id <- .lexprep_scalar_identifier(
      upos_backend_id,
      "upos_backend_id"
    )
    upos_backend_version <- .lexprep_scalar_identifier(
      upos_backend_version,
      "upos_backend_version"
    )
  } else if (supplied_upos_identity) {
    stop(
      "UPOS backend identity must not be supplied when no UPOS tags are present.",
      call. = FALSE
    )
  }

  x$tokens$lemma <- lemmas
  x$tokens$upos <- upos
  x$provenance$annotation <- list(
    method = method,
    backend_id = backend_id,
    backend_version = backend_version,
    upos_backend_id = upos_backend_id,
    upos_backend_version = upos_backend_version,
    lemma_tokens = as.double(sum(!is.na(lemmas))),
    lemma_coverage = if (row_count == 0L) {
      NA_real_
    } else {
      sum(!is.na(lemmas)) / row_count
    },
    upos_tokens = as.double(sum(!is.na(upos))),
    upos_coverage = if (row_count == 0L) {
      NA_real_
    } else {
      sum(!is.na(upos)) / row_count
    }
  )
  x
}

.lexprep_flemma_normalize <- function(value, normalization) {
  if (identical(normalization, "identity")) return(value)
  output <- stringi::stri_trans_nfkc(value)
  output <- stringi::stri_trim_both(output)
  output <- stringi::stri_trans_tolower(output, locale = "en")
  Encoding(output) <- "UTF-8"
  output
}

.lexprep_antbnc_file <- function(resource) {
  resource <- .lexprep_scalar_string(resource, "resource")
  path <- tryCatch(
    normalizePath(resource, mustWork = TRUE),
    error = function(error) {
      stop(
        "AntBNC resource file does not exist or cannot be accessed.",
        call. = FALSE
      )
    }
  )
  information <- file.info(path)
  size <- unname(information$size[[1L]])
  if (
    !isTRUE(utils::file_test("-f", path)) || !is.finite(size) || size < 1 ||
      size > .lexprep_antbnc_max_bytes
  ) {
    stop(
      "AntBNC resource must be a non-empty regular file no larger than 25 MiB.",
      call. = FALSE
    )
  }
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  bytes <- readBin(connection, what = "raw", n = as.integer(size) + 1L)
  if (!identical(as.double(length(bytes)), as.double(size))) {
    stop("AntBNC resource changed while it was being read.", call. = FALSE)
  }
  list(
    source_sha256 = digest::digest(bytes, algo = "sha256", serialize = FALSE),
    bytes = bytes
  )
}

.lexprep_antbnc_parse <- function(resource, normalization) {
  source <- .lexprep_antbnc_file(resource)
  cache_key <- paste(
    source$source_sha256,
    normalization,
    .lexprep_antbnc_parser_version,
    sep = ":"
  )
  if (exists(cache_key, envir = .lexprep_antbnc_cache, inherits = FALSE)) {
    cached <- get(cache_key, envir = .lexprep_antbnc_cache, inherits = FALSE)
    return(list(
      mapping = cached$mapping,
      diagnostics = cached$diagnostics
    ))
  }
  connection <- rawConnection(source$bytes, open = "rb")
  on.exit(close(connection), add = TRUE)
  lines <- tryCatch(
    readLines(connection, encoding = "UTF-8", warn = FALSE),
    error = function(error) {
      stop("AntBNC resource is not valid UTF-8 text.", call. = FALSE)
    }
  )
  if (any(!validUTF8(lines))) {
    stop("AntBNC resource is not valid UTF-8 text.", call. = FALSE)
  }
  if (!length(lines) || any(!nzchar(lines))) {
    stop("AntBNC resource contains an empty or invalid record.", call. = FALSE)
  }
  fields <- strsplit(lines, "\t", fixed = TRUE)
  valid <- lengths(fields) >= 3L & vapply(
    fields,
    function(value) identical(value[[2L]], "->"),
    logical(1)
  )
  if (!all(valid)) {
    stop(
      "AntBNC resource records must use 'headword<TAB>-><TAB>form...' format.",
      call. = FALSE
    )
  }
  headwords <- vapply(fields, `[[`, character(1), 1L)
  forms <- lapply(fields, function(value) value[-c(1L, 2L)])
  if (
    any(!nzchar(headwords)) || any(lengths(forms) < 1L) ||
      any(!nzchar(unlist(forms, use.names = FALSE)))
  ) {
    stop("AntBNC resource contains an empty headword or form.", call. = FALSE)
  }
  headwords <- .lexprep_flemma_normalize(headwords, normalization)
  if (any(!nzchar(headwords)) || anyDuplicated(headwords)) {
    stop(
      "AntBNC resource headwords must be unique after normalization.",
      call. = FALSE
    )
  }
  form_values <- .lexprep_flemma_normalize(
    unlist(forms, use.names = FALSE),
    normalization
  )
  form_headwords <- rep.int(headwords, lengths(forms))
  if (any(!nzchar(form_values)) || anyDuplicated(form_values)) {
    stop(
      "AntBNC resource forms must map uniquely after normalization.",
      call. = FALSE
    )
  }
  prepared <- list(
    mapping = data.frame(
      form = form_values,
      flemma = form_headwords,
      stringsAsFactors = FALSE,
      check.names = FALSE
    ),
    diagnostics = list(
      source_records = as.double(length(headwords)),
      mapping_records = as.double(length(form_values)),
      duplicate_headwords = 0,
      ambiguous_forms = 0,
      parser_id = .lexprep_antbnc_parser_id,
      parser_version = .lexprep_antbnc_parser_version
    )
  )
  cached_keys <- ls(envir = .lexprep_antbnc_cache, all.names = TRUE)
  if (length(cached_keys) >= .lexprep_antbnc_cache_limit) {
    rm(
      list = sort(cached_keys, method = "radix")[[1L]],
      envir = .lexprep_antbnc_cache
    )
  }
  assign(cache_key, prepared, envir = .lexprep_antbnc_cache)
  list(
    mapping = prepared$mapping,
    diagnostics = prepared$diagnostics
  )
}

.lexprep_flemma_overrides <- function(overrides, normalization) {
  if (is.null(overrides)) {
    return(list(
      mapping = data.frame(
        form = character(),
        flemma = character(),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    ))
  }
  if (
    !is.data.frame(overrides) ||
      !all(c("form", "flemma") %in% names(overrides))
  ) {
    stop(
      "overrides must be NULL or a data frame with form and flemma columns.",
      call. = FALSE
    )
  }
  form <- .lexprep_required_strings(overrides$form, "override form column")
  flemma <- .lexprep_required_strings(
    overrides$flemma,
    "override flemma column"
  )
  if (length(form) != length(flemma)) {
    stop("override form and flemma columns must have the same length.", call. = FALSE)
  }
  if (length(form) == 0L) {
    return(list(
      mapping = data.frame(
        form = character(),
        flemma = character(),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    ))
  }
  form <- .lexprep_flemma_normalize(form, normalization)
  flemma <- .lexprep_flemma_normalize(flemma, normalization)
  if (any(!nzchar(form)) || any(!nzchar(flemma)) || anyDuplicated(form)) {
    stop(
      "override forms must be non-empty and unique after normalization.",
      call. = FALSE
    )
  }
  list(
    mapping = data.frame(
      form = form,
      flemma = flemma,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  )
}

#' Add flemmas from a caller-supplied AntBNC lemma list
#'
#' Maps token surface forms to family lemmas (flemmas) using a local AntBNC
#' lemma-list file. No resource is bundled or downloaded. Unknown forms retain
#' their normalized surface form so that downstream profiles count them as
#' off-list rather than silently excluding them. Optional explicit overrides
#' are applied after the AntBNC lookup.
#'
#' @param x A `lexdiv_tokenization` object.
#' @param resource Path to a caller-supplied AntBNC lemma-list text file in
#'   `headword<TAB>-><TAB>form...` format.
#' @param overrides Optional data frame with unique `form` and `flemma` columns.
#' @param normalization Either case-insensitive `"nfkc_lower"` or exact
#'   `"identity"` matching.
#' @param resource_version Optional caller-declared resource version. It must
#'   be path-free. Strict flemma overlap treats a missing version as
#'   unverifiable; the package does not infer content identity from file bytes.
#' @param override_version Optional caller-declared version for a non-empty
#'   override table. It must be path-free. Supplying it without overrides is an
#'   error. Strict flemma overlap treats unversioned overrides as unverifiable.
#'
#' @return The tokenization object with `flemma`, `flemma_matched`, and
#'   `flemma_match_rule` columns plus flemma resource provenance.
#' @export
lexdiv_flemmatize <- function(
    x,
    resource,
    overrides = NULL,
    normalization = "nfkc_lower",
    resource_version = NULL,
    override_version = NULL) {
  x <- .lexprep_validate_tokenization(x)
  normalization <- .lexprep_scalar_choice(
    normalization,
    c("nfkc_lower", "identity"),
    "normalization"
  )
  if (!is.null(resource_version)) {
    resource_version <- .lexprep_scalar_identifier(
      resource_version,
      "resource_version"
    )
  }
  if (!is.null(override_version)) {
    override_version <- .lexprep_scalar_identifier(
      override_version,
      "override_version"
    )
  }
  prepared <- .lexprep_antbnc_parse(resource, normalization)
  overrides <- .lexprep_flemma_overrides(overrides, normalization)
  override_entries <- nrow(overrides$mapping)
  if (override_entries == 0L && !is.null(override_version)) {
    stop(
      "override_version must be NULL when overrides are absent or empty.",
      call. = FALSE
    )
  }
  surface <- .lexprep_flemma_normalize(x$tokens$surface, normalization)
  matched_index <- match(surface, prepared$mapping$form)
  matched <- !is.na(matched_index)
  flemma <- prepared$mapping$flemma[matched_index]
  flemma[!matched] <- surface[!matched]
  match_rule <- ifelse(matched, "antbnc", "identity")

  override_index <- match(surface, overrides$mapping$form)
  overridden <- !is.na(override_index)
  if (any(overridden)) {
    flemma[overridden] <- overrides$mapping$flemma[override_index[overridden]]
    match_rule[overridden] <- "override"
  }
  recognized <- matched | overridden
  Encoding(flemma) <- "UTF-8"
  x$tokens$flemma <- unname(flemma)
  x$tokens$flemma_matched <- unname(recognized)
  x$tokens$flemma_match_rule <- unname(match_rule)

  row_count <- nrow(x$tokens)
  x$provenance$flemma_annotation <- list(
    method = "antbnc",
    lexical_unit = "flemma",
    backend_id = .lexprep_flemma_backend_id,
    backend_version = .lexprep_flemma_backend_version,
    parser_id = prepared$diagnostics$parser_id,
    parser_version = prepared$diagnostics$parser_version,
    resource_id = .lexprep_antbnc_resource_id,
    resource_version = resource_version,
    resource_source_type = "local_text",
    resource_bundled = FALSE,
    runtime_download = FALSE,
    query_normalization = normalization,
    query_normalization_id = unname(
      .lexprep_flemma_normalization_ids[[normalization]]
    ),
    source_records = prepared$diagnostics$source_records,
    mapping_records = prepared$diagnostics$mapping_records,
    input_tokens = as.double(row_count),
    matched_tokens = as.double(sum(recognized)),
    matched_coverage = if (row_count == 0L) {
      NA_real_
    } else {
      sum(recognized) / row_count
    },
    resource_matched_tokens = as.double(sum(matched)),
    resource_match_coverage = if (row_count == 0L) {
      NA_real_
    } else {
      sum(matched) / row_count
    },
    override_tokens = as.double(sum(overridden)),
    override_entries = as.double(override_entries),
    override_version = override_version,
    identity_fallback_tokens = as.double(sum(!matched & !overridden)),
    unknown_form_policy = "normalized-surface-identity-fallback"
  )
  x
}

.lexprep_selected_units <- function(x, unit, word_inclusion) {
  token_table <- x$tokens
  row_count <- nrow(token_table)
  exclusion_reason <- rep.int(NA_character_, row_count)

  if (unit %in% c("lemma", "flemma")) {
    if (!(unit %in% names(token_table))) {
      stop(
        sprintf(
          "unit = \"%s\" requires an object returned by lexdiv_%s().",
          unit,
          if (identical(unit, "lemma")) "lemmatize" else "flemmatize"
        ),
        call. = FALSE
      )
    }
    selected <- token_table[[unit]]
    exclusion_reason[is.na(selected)] <- paste0("missing_", unit)
  } else {
    selected <- token_table$surface
  }

  if (identical(word_inclusion, "content")) {
    if (!("upos" %in% names(token_table))) {
      stop(
        "word_inclusion = \"content\" requires UPOS annotations from lexdiv_lemmatize().",
        call. = FALSE
      )
    }
    missing_upos <- is.na(token_table$upos)
    non_content <- !missing_upos & !(token_table$upos %in% .lexprep_content_upos)
    exclusion_reason[missing_upos] <- "missing_upos"
    exclusion_reason[non_content] <- "non_content_upos"
  }

  eligible <- is.na(exclusion_reason)
  audit <- data.frame(
    token_index = token_table$token_index,
    surface = token_table$surface,
    selected_unit = selected,
    unit_match_rule = if (
      identical(unit, "flemma") &&
        "flemma_match_rule" %in% names(token_table)
    ) {
      token_table$flemma_match_rule
    } else {
      rep.int(NA_character_, row_count)
    },
    upos = if ("upos" %in% names(token_table)) {
      token_table$upos
    } else {
      rep.int(NA_character_, row_count)
    },
    eligible = eligible,
    exclusion_reason = exclusion_reason,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  list(units = unname(selected[eligible]), audit = audit)
}

#' Compute lexical-diversity metrics from one raw or annotated text
#'
#' Tokenizes raw text, or consumes an existing tokenization object, selects
#' surface forms, explicit lemmas, or flemmas, optionally restricts analysis to Universal
#' POS content words, and then calls the versioned [lexdiv_metrics()] core. The
#' core result schema remains unchanged; preprocessing is returned in a
#' separate auditable envelope.
#'
#' @param x One raw character string or a `lexdiv_tokenization` object. When an
#'   existing tokenization is supplied, its recorded `normalization`, `case`,
#'   `keep_numbers`, and `tokenizer` choices are authoritative; supplying any of those
#'   tokenizer arguments again is an error.
#' @param unit One of `"surface"`, `"lemma"`, or `"flemma"`. Lemma and flemma
#'   analyses require the corresponding annotations on a `lexdiv_tokenization`
#'   object; raw character input supports surface analysis only.
#' @param word_inclusion Either all word tokens or the defined UPOS content set
#'   `ADJ`, `ADV`, `NOUN`, `PROPN`, and `VERB`. Content-word selection requires
#'   UPOS annotations; `textstem` does not create them.
#' @inheritParams lexdiv_tokenize
#' @inheritParams lexdiv_metrics
#'
#' @return A `lexdiv_text_results` list with `results`, `token_audit`, and
#'   `preprocessing` components.
#' @export
lexdiv_metrics_text <- function(
    x,
    unit = "surface",
    word_inclusion = "all",
    normalization = "NFC",
    case = "preserve",
    keep_numbers = FALSE,
    metrics = lexdiv_metric_ids(),
    segment_length = 50L,
    window_length = 50L,
    mtld_threshold = 0.72,
    sample_size = 42L,
    expected_ttr_sample_sizes = 35:50,
    tokenizer = "unicode") {
  supplied_tokenizer_arguments <- c(
    normalization = !missing(normalization),
    case = !missing(case),
    keep_numbers = !missing(keep_numbers),
    tokenizer = !missing(tokenizer)
  )
  if (
    .lexprep_is_tokenization(x) &&
      any(supplied_tokenizer_arguments)
  ) {
    stop(
      paste0(
        paste(names(supplied_tokenizer_arguments)[supplied_tokenizer_arguments],
          collapse = ", "
        ),
        " apply only when x is raw text. A lexdiv_tokenization already records ",
        "these choices; call lexdiv_tokenize() again to change them."
      ),
      call. = FALSE
    )
  }
  unit <- .lexprep_scalar_choice(
    unit,
    c("surface", "lemma", "flemma"),
    "unit"
  )
  word_inclusion <- .lexprep_scalar_choice(
    word_inclusion,
    c("all", "content"),
    "word_inclusion"
  )
  tokenization <- if (.lexprep_is_tokenization(x)) {
    .lexprep_validate_tokenization(x)
  } else {
    lexdiv_tokenize(
      text = x,
      normalization = normalization,
      case = case,
      keep_numbers = keep_numbers,
      tokenizer = tokenizer
    )
  }
  selected <- .lexprep_selected_units(tokenization, unit, word_inclusion)
  results <- lexdiv_metrics(
    tokens = selected$units,
    metrics = metrics,
    segment_length = segment_length,
    window_length = window_length,
    mtld_threshold = mtld_threshold,
    sample_size = sample_size,
    expected_ttr_sample_sizes = expected_ttr_sample_sizes
  )
  token_count <- nrow(selected$audit)
  eligible_count <- sum(selected$audit$eligible)
  preprocessing <- list(
    contract_id = .lexprep_contract_id,
    contract_version = .lexprep_contract_version,
    tokenization = tokenization$provenance,
    selected_unit = unit,
    word_inclusion = word_inclusion,
    content_upos = if (identical(word_inclusion, "content")) {
      .lexprep_content_upos
    } else {
      character()
    },
    input_tokens = as.double(token_count),
    eligible_tokens = as.double(eligible_count),
    excluded_tokens = as.double(token_count - eligible_count),
    unit_coverage = if (token_count == 0L) NA_real_ else eligible_count / token_count
  )
  structure(
    list(
      results = results,
      token_audit = selected$audit,
      preprocessing = preprocessing
    ),
    class = "lexdiv_text_results"
  )
}

#' @export
print.lexdiv_tokenization <- function(x, ...) {
  cat(
    sprintf(
      "<lexdiv_tokenization> %d token%s | %s | %s | numbers=%s | %s %s\n",
      nrow(x$tokens),
      if (nrow(x$tokens) == 1L) "" else "s",
      x$provenance$normalization,
      x$provenance$case,
      if (isTRUE(x$provenance$keep_numbers)) "kept" else "removed",
      x$provenance$tokenizer_id,
      x$provenance$tokenizer_version
    )
  )
  print(x$tokens, row.names = FALSE, ...)
  invisible(x)
}

#' @export
print.lexdiv_text_results <- function(x, ...) {
  cat(
    sprintf(
      "<lexdiv_text_results> %d/%d eligible tokens | unit=%s | inclusion=%s\n",
      as.integer(x$preprocessing$eligible_tokens),
      as.integer(x$preprocessing$input_tokens),
      x$preprocessing$selected_unit,
      x$preprocessing$word_inclusion
    )
  )
  print(x$results, ...)
  invisible(x)
}
