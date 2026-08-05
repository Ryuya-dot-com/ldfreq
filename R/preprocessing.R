# Versioned raw-text preprocessing and lexical-unit selection.
#
# The frozen lexical-diversity core continues to accept only plain ordered
# character vectors.  This file adds a separate envelope so that tokenization,
# lemmatization, and word-inclusion choices are explicit rather than hidden in
# metric computation.

.lexprep_contract_id <- "ldfreq-preprocessing"
.lexprep_contract_version <- "0.1.0-draft.2"
.lexprep_tokenizer_id <- "ldfreq-unicode-word-tokenizer"
.lexprep_tokenizer_version <- "0.1.0"
.lexprep_antbnc_id <- "antbnc-lemma-list"
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

.lexprep_scalar_choice <- function(value, choices, argument) {
  if (
    !is.character(value) || is.object(value) || !is.null(dim(value)) ||
      length(value) != 1L || is.na(value) || !nzchar(value) ||
      !(value %in% choices)
  ) {
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
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
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

.lexprep_validate_tokenization <- function(value) {
  if (!.lexprep_is_tokenization(value)) {
    stop("x must be created by lexdiv_tokenize().", call. = FALSE)
  }
  required <- c("token_index", "start", "end", "surface", "is_number")
  if (!all(required %in% names(value$tokens))) {
    stop("x has an invalid tokenization table.", call. = FALSE)
  }
  row_count <- nrow(value$tokens)
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
    stop("x has an invalid tokenization table.", call. = FALSE)
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
      stringi::stri_detect_regex(value$tokens$surface, "^\\p{N}+$")
    )
    if (!offsets_are_valid || !number_flags_are_valid) {
      stop("x has an invalid tokenization table.", call. = FALSE)
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
#'
#' @return A `lexdiv_tokenization` object containing a token table and a
#'   versioned preprocessing provenance record. The `surface` column can be
#'   supplied directly to [lexdiv_metrics()].
#' @export
lexdiv_tokenize <- function(
    text,
    normalization = "NFC",
    case = "preserve",
    keep_numbers = FALSE) {
  text <- .lexprep_text(text)
  normalization <- .lexprep_scalar_choice(
    normalization,
    c("NFC", "NFKC", "none"),
    "normalization"
  )
  case <- .lexprep_scalar_choice(case, c("preserve", "lower"), "case")
  keep_numbers <- .lexprep_scalar_flag(keep_numbers, "keep_numbers")
  processed <- .lexprep_normalize_text(text, normalization, case)

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
    tokenizer_id = .lexprep_tokenizer_id,
    tokenizer_version = .lexprep_tokenizer_version,
    normalization = normalization,
    case = case,
    keep_numbers = keep_numbers,
    token_pattern = .lexprep_token_pattern,
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
    input_characters = as.double(stringi::stri_length(text)),
    processed_characters = as.double(stringi::stri_length(processed)),
    output_tokens = as.double(nrow(token_table)),
    annotation = NULL
  )
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
#'   The `textstem` backend supplies lemmas only; it does not infer UPOS. Supply
#'   tags explicitly when a later `word_inclusion = "content"` analysis is
#'   required.
#' @param backend_id,backend_version Required provenance strings for supplied
#'   annotations. For `textstem`, package identity and installed version are
#'   recorded automatically.
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
    backend_version = NULL) {
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
    backend_id <- .lexprep_scalar_string(backend_id, "backend_id")
    backend_version <- .lexprep_scalar_string(
      backend_version,
      "backend_version"
    )
  } else {
    if (!is.null(lemmas)) {
      stop("lemmas must be NULL when method = \"textstem\".", call. = FALSE)
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

  x$tokens$lemma <- lemmas
  x$tokens$upos <- upos
  x$provenance$annotation <- list(
    method = method,
    backend_id = backend_id,
    backend_version = backend_version,
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
    path = path,
    source_file = basename(path),
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
      source = source[c("source_file", "source_sha256")],
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
    source = source[c("source_file", "source_sha256")],
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
      ),
      canonical_sha256 = NA_character_
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
  form <- .lexprep_flemma_normalize(form, normalization)
  flemma <- .lexprep_flemma_normalize(flemma, normalization)
  if (any(!nzchar(form)) || any(!nzchar(flemma)) || anyDuplicated(form)) {
    stop(
      "override forms must be non-empty and unique after normalization.",
      call. = FALSE
    )
  }
  canonical_order <- order(form, method = "radix")
  canonical_text <- paste0(
    form[canonical_order],
    "\t",
    flemma[canonical_order],
    collapse = "\n"
  )
  list(
    mapping = data.frame(
      form = form,
      flemma = flemma,
      stringsAsFactors = FALSE,
      check.names = FALSE
    ),
    canonical_sha256 = digest::digest(
      charToRaw(enc2utf8(canonical_text)),
      algo = "sha256",
      serialize = FALSE
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
#' @param resource_version Optional caller-supplied resource version. By
#'   default, a label derived from the exact file SHA-256 is used.
#'
#' @return The tokenization object with `flemma`, `flemma_matched`, and
#'   `flemma_match_rule` columns plus flemma resource provenance.
#' @export
lexdiv_flemmatize <- function(
    x,
    resource,
    overrides = NULL,
    normalization = "nfkc_lower",
    resource_version = NULL) {
  x <- .lexprep_validate_tokenization(x)
  normalization <- .lexprep_scalar_choice(
    normalization,
    c("nfkc_lower", "identity"),
    "normalization"
  )
  if (!is.null(resource_version)) {
    resource_version <- .lexprep_scalar_string(
      resource_version,
      "resource_version"
    )
  }
  prepared <- .lexprep_antbnc_parse(resource, normalization)
  overrides <- .lexprep_flemma_overrides(overrides, normalization)
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

  version <- if (is.null(resource_version)) {
    paste0(
      "sha256-",
      substr(prepared$source$source_sha256, 1L, 12L)
    )
  } else {
    resource_version
  }
  row_count <- nrow(x$tokens)
  x$provenance$flemma_annotation <- list(
    method = "antbnc",
    lexical_unit = "flemma",
    backend_id = .lexprep_antbnc_id,
    backend_version = version,
    parser_id = prepared$diagnostics$parser_id,
    parser_version = prepared$diagnostics$parser_version,
    resource_source_type = "local_text",
    resource_source_file = prepared$source$source_file,
    resource_source_sha256 = prepared$source$source_sha256,
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
    override_entries = as.double(nrow(overrides$mapping)),
    override_canonical_sha256 = overrides$canonical_sha256,
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
    exclusion_reason[is.na(exclusion_reason) & missing_upos] <- "missing_upos"
    exclusion_reason[is.na(exclusion_reason) & non_content] <- "non_content_upos"
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
#' POS content words, and then calls the frozen [lexdiv_metrics()] core. The
#' core result schema remains unchanged; preprocessing is returned in a
#' separate auditable envelope.
#'
#' @param x One raw character string or a `lexdiv_tokenization` object.
#' @param unit One of `"surface"`, `"lemma"`, or `"flemma"`.
#' @param word_inclusion Either all word tokens or the frozen UPOS content set
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
    sample_size = 42L) {
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
      keep_numbers = keep_numbers
    )
  }
  selected <- .lexprep_selected_units(tokenization, unit, word_inclusion)
  results <- lexdiv_metrics(
    tokens = selected$units,
    metrics = metrics,
    segment_length = segment_length,
    window_length = window_length,
    mtld_threshold = mtld_threshold,
    sample_size = sample_size
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
      "<lexdiv_tokenization> %d token%s | %s | %s | numbers=%s\n",
      nrow(x$tokens),
      if (nrow(x$tokens) == 1L) "" else "s",
      x$provenance$normalization,
      x$provenance$case,
      if (isTRUE(x$provenance$keep_numbers)) "kept" else "removed"
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
