# Coverage-aware lexical level profiles from caller-supplied word lists.

.level_profile_contract_id <- "ldfreq-lexical-level-profile"
.level_profile_contract_version <- "0.1.0-draft.3"
.level_profile_batch_contract_id <- "ldfreq-lexical-level-profile-batch"
.level_profile_batch_contract_version <- "0.1.0-draft.1"
.nj8_resource_id <- "new-jacet8000"
.nj8_expected_ranks <- 8000L
.nj8_levels <- seq_len(8L)
.level_profile_normalization_ids <- c(
  nfkc_lower = "nfkc-trim-en-lower-v1",
  identity = "identity-valid-utf8-v1"
)

.level_profile_terms <- function(terms, unit) {
  if (.lexprep_is_tokenization(terms)) {
    tokenization <- .lexprep_validate_tokenization(terms)
    selected <- .lexprep_selected_units(tokenization, unit, "all")
    eligible <- selected$audit$eligible
    return(list(
      terms = unname(selected$units),
      surface_terms = unname(selected$audit$surface[eligible]),
      unit_match_rule = unname(selected$audit$unit_match_rule[eligible]),
      token_index = selected$audit$token_index[eligible],
      input_source = "lexdiv_tokenization",
      preprocessing_ref = tokenization$provenance,
      input_tokens = as.double(nrow(selected$audit)),
      eligible_tokens = as.double(sum(eligible)),
      excluded_tokens = as.double(sum(!eligible)),
      exclusion_reason = selected$audit$exclusion_reason[!eligible]
    ))
  }
  if (
    !is.character(terms) || is.object(terms) || !is.null(dim(terms)) ||
      !is.null(attributes(terms)) || anyNA(terms) || any(!nzchar(terms)) ||
      any(Encoding(terms) %in% c("bytes", "latin1")) ||
      any(!validUTF8(terms))
  ) {
    stop(
      paste(
        "terms must be a plain character vector of non-empty valid-UTF-8",
        "lexical units, or an object returned by lexdiv_tokenize()."
      ),
      call. = FALSE
    )
  }
  Encoding(terms) <- "UTF-8"
  list(
    terms = terms,
    surface_terms = terms,
    unit_match_rule = rep.int(NA_character_, length(terms)),
    token_index = seq_along(terms),
    input_source = "character_terms",
    preprocessing_ref = NULL,
    input_tokens = as.double(length(terms)),
    eligible_tokens = as.double(length(terms)),
    excluded_tokens = 0,
    exclusion_reason = character()
  )
}

.level_profile_normalize <- function(value, normalization) {
  if (identical(normalization, "identity")) return(value)
  output <- stringi::stri_trans_nfkc(value)
  output <- stringi::stri_trim_both(output)
  output <- stringi::stri_trans_tolower(output, locale = "en")
  Encoding(output) <- "UTF-8"
  output
}

.nj8_wordlist_column <- function(wordlist, column, candidates, argument) {
  if (is.null(column)) {
    available <- candidates[candidates %in% names(wordlist)]
    if (!length(available)) {
      stop(
        sprintf(
          "%s could not be detected; supply its exact column name.",
          argument
        ),
        call. = FALSE
      )
    }
    column <- available[[1L]]
  } else {
    column <- .lexprep_scalar_string(column, argument)
  }
  if (!(column %in% names(wordlist))) {
    stop(sprintf("%s is not present in wordlist.", argument), call. = FALSE)
  }
  column
}

.nj8_read_file_bytes <- function(path) {
  information <- file.info(path)
  size <- unname(information$size[[1L]])
  if (
    !isTRUE(utils::file_test("-f", path)) || !is.finite(size) || size < 1 ||
      size > 10 * 1024^2
  ) {
    stop("wordlist must identify a non-empty regular CSV or XLSX file no larger than 10 MiB.", call. = FALSE)
  }
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  bytes <- readBin(connection, what = "raw", n = as.integer(size) + 1L)
  if (!identical(as.double(length(bytes)), as.double(size))) {
    stop("wordlist changed while it was being read.", call. = FALSE)
  }
  bytes
}

.nj8_read_wordlist <- function(wordlist, sheet) {
  if (is.character(wordlist) && !is.object(wordlist) &&
      is.null(dim(wordlist)) && is.null(attributes(wordlist)) &&
      length(wordlist) == 1L && !is.na(wordlist) && nzchar(wordlist)) {
    path <- tryCatch(
      normalizePath(wordlist, mustWork = TRUE),
      error = function(error) {
        stop(
          "wordlist file does not exist or cannot be accessed.",
          call. = FALSE
        )
      }
    )
    bytes <- .nj8_read_file_bytes(path)
    extension <- tolower(tools::file_ext(path))
    if (identical(extension, "csv")) {
      table <- tryCatch(
        suppressWarnings(
          utils::read.csv(
            path,
            stringsAsFactors = FALSE,
            check.names = FALSE,
            fileEncoding = "UTF-8-BOM"
          )
        ),
        error = function(error) {
          stop(
            sprintf(
              "wordlist CSV file '%s' could not be read.",
              basename(path)
            ),
            call. = FALSE
          )
        }
      )
      source_type <- "local_csv"
      source_sheet <- NA_character_
    } else if (identical(extension, "xlsx")) {
      if (!requireNamespace("readxl", quietly = TRUE)) {
        stop(
          "Reading an XLSX wordlist requires the suggested readxl package.",
          call. = FALSE
        )
      }
      table <- tryCatch(
        suppressWarnings(
          as.data.frame(
            readxl::read_excel(path, sheet = sheet, .name_repair = "minimal"),
            stringsAsFactors = FALSE,
            check.names = FALSE
          )
        ),
        error = function(error) {
          stop(
            sprintf(
              "wordlist XLSX sheet '%s' could not be read from file '%s'.",
              sheet,
              basename(path)
            ),
            call. = FALSE
          )
        }
      )
      source_type <- "local_xlsx"
      source_sheet <- sheet
    } else {
      stop("wordlist file must have a .csv or .xlsx extension.", call. = FALSE)
    }
    return(list(
      table = table,
      source_type = source_type,
      source_file = basename(path),
      source_sheet = source_sheet,
      source_sha256 = digest::digest(bytes, algo = "sha256", serialize = FALSE)
    ))
  }
  if (!is.data.frame(wordlist)) {
    stop("wordlist must be a data frame or the path to a local CSV or XLSX file.", call. = FALSE)
  }
  list(
    table = wordlist,
    source_type = "data_frame",
    source_file = NA_character_,
    source_sheet = NA_character_,
    source_sha256 = NA_character_
  )
}

.nj8_ranks <- function(value) {
  if (is.character(value) && !is.object(value) && is.null(dim(value)) &&
      all(grepl("^[0-9]+$", value))) {
    value <- suppressWarnings(as.numeric(value))
  }
  if (
    !is.numeric(value) || is.object(value) || !is.null(dim(value)) ||
      anyNA(value) || any(!is.finite(value)) || any(value != floor(value)) ||
      any(value < 1) || any(value > .nj8_expected_ranks)
  ) {
    stop("rank_column must contain unique integer ranks from 1 through 8000.", call. = FALSE)
  }
  value <- as.integer(value)
  if (anyDuplicated(value)) {
    stop("rank_column must not contain duplicate ranks.", call. = FALSE)
  }
  value
}

.nj8_words <- function(value) {
  if (
    !is.character(value) || is.object(value) || !is.null(dim(value)) ||
      anyNA(value) || any(!nzchar(value)) ||
      any(Encoding(value) %in% c("bytes", "latin1")) ||
      any(!validUTF8(value))
  ) {
    stop("word_column must contain non-empty valid-UTF-8 strings.", call. = FALSE)
  }
  Encoding(value) <- "UTF-8"
  value
}

.nj8_aliases <- function(word, expand_parenthetical) {
  if (!expand_parenthetical) return(word)
  matched <- stringi::stri_match_first_regex(
    word,
    "^\\s*(.+?)\\s*\\(([^()]*)\\)\\s*$"
  )
  if (is.na(matched[[1L, 1L]])) return(word)
  variants <- stringi::stri_split_fixed(
    matched[[1L, 3L]],
    ",",
    omit_empty = TRUE
  )[[1L]]
  c(matched[[1L, 2L]], stringi::stri_trim_both(variants))
}

.nj8_missing_rank_examples <- function(ranks, limit = 20L) {
  missing <- setdiff(seq_len(.nj8_expected_ranks), ranks)
  list(
    count = as.double(length(missing)),
    examples = as.integer(utils::head(missing, limit)),
    examples_truncated = length(missing) > limit
  )
}

.nj8_prepare_wordlist <- function(
    wordlist,
    rank_column,
    word_column,
    sheet,
    normalization,
    expand_parenthetical) {
  source <- .nj8_read_wordlist(wordlist, sheet)
  rank_column <- .nj8_wordlist_column(
    source$table,
    rank_column,
    c("\u65b0J8\u9806\u4f4d", "NJ8"),
    "rank_column"
  )
  word_column <- .nj8_wordlist_column(
    source$table,
    word_column,
    c("\u4ee3\u8868\u30ec\u30de", "Word"),
    "word_column"
  )
  ranks <- .nj8_ranks(source$table[[rank_column]])
  words <- .nj8_words(source$table[[word_column]])
  if (length(ranks) != length(words)) {
    stop("rank_column and word_column must have the same length.", call. = FALSE)
  }

  aliases <- lapply(words, .nj8_aliases, expand_parenthetical = expand_parenthetical)
  alias_counts <- lengths(aliases)
  alias_table <- data.frame(
    lookup_term = unlist(aliases, use.names = FALSE),
    rank = rep.int(ranks, alias_counts),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  alias_table$lookup_term <- .level_profile_normalize(
    alias_table$lookup_term,
    normalization
  )
  if (any(!nzchar(alias_table$lookup_term))) {
    stop("wordlist contains an empty term after normalization.", call. = FALSE)
  }
  alias_table <- alias_table[
    order(alias_table$lookup_term, alias_table$rank, method = "radix"),
    ,
    drop = FALSE
  ]
  collision_count <- sum(duplicated(alias_table$lookup_term))
  alias_table <- alias_table[!duplicated(alias_table$lookup_term), , drop = FALSE]
  alias_table$level <- as.integer(ceiling(alias_table$rank / 1000))
  rownames(alias_table) <- NULL

  canonical_text <- paste0(ranks, "\t", enc2utf8(words), collapse = "\n")
  canonical_sha256 <- digest::digest(
    charToRaw(enc2utf8(canonical_text)),
    algo = "sha256",
    serialize = FALSE
  )
  missing <- .nj8_missing_rank_examples(ranks)
  list(
    aliases = alias_table,
    source = source,
    diagnostics = list(
      source_entries = as.double(length(ranks)),
      rank_column = rank_column,
      word_column = word_column,
      lookup_entries = as.double(nrow(alias_table)),
      parenthetical_aliases_added = as.double(sum(pmax(alias_counts - 1L, 0L))),
      normalized_collisions_resolved = as.double(collision_count),
      collision_policy = "lowest-rank-entry-wins",
      expected_rank_count = as.double(.nj8_expected_ranks),
      missing_rank_count = missing$count,
      missing_rank_examples = missing$examples,
      missing_rank_examples_truncated = missing$examples_truncated,
      canonical_sha256 = canonical_sha256
    )
  )
}

.level_profile_summary_one <- function(level, matched, weighting) {
  denominator <- length(level)
  level_counts <- tabulate(level[matched], nbins = length(.nj8_levels))
  off_list_count <- sum(!matched)
  proportion <- if (denominator == 0L) {
    rep.int(NA_real_, length(.nj8_levels) + 1L)
  } else {
    c(level_counts, off_list_count) / denominator
  }
  cumulative_items <- c(cumsum(level_counts), NA_real_)
  cumulative_proportion <- if (denominator == 0L) {
    rep.int(NA_real_, length(.nj8_levels) + 1L)
  } else {
    c(cumsum(level_counts) / denominator, NA_real_)
  }
  data.frame(
    weighting = rep.int(weighting, length(.nj8_levels) + 1L),
    level = c(.nj8_levels, NA_integer_),
    level_label = c(paste("Level", .nj8_levels), "Off-list"),
    items = as.double(c(level_counts, off_list_count)),
    proportion = as.double(proportion),
    cumulative_items = as.double(cumulative_items),
    cumulative_proportion = as.double(cumulative_proportion),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.level_profile_summary <- function(lookup) {
  token_summary <- .level_profile_summary_one(
    lookup$level,
    lookup$matched,
    "token"
  )
  type_first <- !duplicated(lookup$lookup_term)
  type_summary <- .level_profile_summary_one(
    lookup$level[type_first],
    lookup$matched[type_first],
    "type"
  )
  rbind(token_summary, type_summary)
}

.level_profile_coverage <- function(input, lookup) {
  type_first <- !duplicated(lookup$lookup_term)
  eligible_types <- sum(type_first)
  matched_tokens <- sum(lookup$matched)
  matched_types <- sum(lookup$matched[type_first])
  list(
    input_tokens = input$input_tokens,
    eligible_tokens = input$eligible_tokens,
    excluded_tokens = input$excluded_tokens,
    selection_coverage = if (input$input_tokens == 0) {
      NA_real_
    } else {
      input$eligible_tokens / input$input_tokens
    },
    matched_tokens = as.double(matched_tokens),
    off_list_tokens = as.double(nrow(lookup) - matched_tokens),
    token_coverage = if (!nrow(lookup)) NA_real_ else matched_tokens / nrow(lookup),
    eligible_types = as.double(eligible_types),
    matched_types = as.double(matched_types),
    off_list_types = as.double(eligible_types - matched_types),
    type_coverage = if (!eligible_types) NA_real_ else matched_types / eligible_types
  )
}

.nj8_profile_options <- function(
    unit,
    flemma_conflict,
    normalization,
    expand_parenthetical,
    sheet,
    resource_version) {
  unit <- .lexprep_scalar_choice(
    unit,
    c("surface", "lemma", "flemma"),
    "unit"
  )
  flemma_conflict <- .lexprep_scalar_choice(
    flemma_conflict,
    c("antbnc", "wordlist", "error"),
    "flemma_conflict"
  )
  if (!identical(unit, "flemma") && !identical(flemma_conflict, "antbnc")) {
    stop(
      "flemma_conflict is only used when unit = \"flemma\".",
      call. = FALSE
    )
  }
  normalization <- .lexprep_scalar_choice(
    normalization,
    c("nfkc_lower", "identity"),
    "normalization"
  )
  expand_parenthetical <- .lexprep_scalar_flag(
    expand_parenthetical,
    "expand_parenthetical"
  )
  sheet <- .lexprep_scalar_string(sheet, "sheet")
  if (!is.null(resource_version)) {
    resource_version <- .lexprep_scalar_string(
      resource_version,
      "resource_version"
    )
  }
  list(
    unit = unit,
    flemma_conflict = flemma_conflict,
    normalization = normalization,
    expand_parenthetical = expand_parenthetical,
    sheet = sheet,
    resource_version = resource_version
  )
}

.nj8_profile_from_prepared <- function(input, prepared, options) {
  unit <- options$unit
  flemma_conflict <- options$flemma_conflict
  normalization <- options$normalization
  selected_lookup_terms <- .level_profile_normalize(
    input$terms,
    normalization
  )
  surface_lookup_terms <- .level_profile_normalize(
    input$surface_terms,
    normalization
  )
  selected_index <- match(
    selected_lookup_terms,
    prepared$aliases$lookup_term
  )
  surface_index <- match(surface_lookup_terms, prepared$aliases$lookup_term)
  headword_conflict <- if (identical(unit, "flemma")) {
    !is.na(surface_index) & surface_lookup_terms != selected_lookup_terms
  } else {
    rep.int(FALSE, length(selected_lookup_terms))
  }
  if (identical(flemma_conflict, "error") && any(headword_conflict)) {
    examples <- unique(input$surface_terms[headword_conflict])
    stop(
      sprintf(
        paste0(
          "flemma headword conflicts were found for %d token(s); examples: %s. ",
          "Choose flemma_conflict = \"antbnc\" or \"wordlist\", or supply explicit overrides."
        ),
        sum(headword_conflict),
        paste(utils::head(examples, 5L), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  use_surface <- headword_conflict & identical(flemma_conflict, "wordlist")
  lookup_terms <- selected_lookup_terms
  lookup_terms[use_surface] <- surface_lookup_terms[use_surface]
  matched_index <- match(lookup_terms, prepared$aliases$lookup_term)
  matched <- !is.na(matched_index)
  conflict_resolution <- rep.int("none", length(lookup_terms))
  conflict_resolution[headword_conflict] <- if (
    identical(flemma_conflict, "wordlist")
  ) {
    "wordlist"
  } else {
    "antbnc"
  }
  conflicting_surface_rank <- rep.int(NA_integer_, length(lookup_terms))
  conflicting_surface_level <- rep.int(NA_integer_, length(lookup_terms))
  conflicting_surface_rank[headword_conflict] <- as.integer(
    prepared$aliases$rank[surface_index[headword_conflict]]
  )
  conflicting_surface_level[headword_conflict] <- as.integer(
    prepared$aliases$level[surface_index[headword_conflict]]
  )
  lookup <- data.frame(
    query_index = seq_along(input$terms),
    token_index = as.integer(input$token_index),
    surface_term = input$surface_terms,
    term = input$terms,
    lookup_term = lookup_terms,
    unit_match_rule = input$unit_match_rule,
    headword_conflict = headword_conflict,
    headword_conflict_resolution = conflict_resolution,
    conflicting_surface_rank = conflicting_surface_rank,
    conflicting_surface_level = conflicting_surface_level,
    matched = matched,
    rank = as.integer(prepared$aliases$rank[matched_index]),
    level = as.integer(prepared$aliases$level[matched_index]),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  summary <- .level_profile_summary(lookup)
  coverage <- .level_profile_coverage(input, lookup)
  version <- if (is.null(options$resource_version)) {
    paste0(
      "canonical-sha256-",
      substr(prepared$diagnostics$canonical_sha256, 1L, 12L)
    )
  } else {
    options$resource_version
  }
  provenance <- list(
    contract_id = .level_profile_contract_id,
    contract_version = .level_profile_contract_version,
    resource_id = .nj8_resource_id,
    resource_version = version,
    resource_source_type = prepared$source$source_type,
    resource_source_file = prepared$source$source_file,
    resource_source_sheet = prepared$source$source_sheet,
    resource_source_sha256 = prepared$source$source_sha256,
    resource_canonical_sha256 = prepared$diagnostics$canonical_sha256,
    resource_bundled = FALSE,
    runtime_download = FALSE,
    input_source = input$input_source,
    preprocessing_ref = input$preprocessing_ref,
    selected_unit = unit,
    flemma_conflict_policy = if (identical(unit, "flemma")) {
      flemma_conflict
    } else {
      NA_character_
    },
    query_normalization = normalization,
    query_normalization_id = unname(
      .level_profile_normalization_ids[[normalization]]
    ),
    expand_parenthetical = options$expand_parenthetical,
    level_rule = "ceiling(rank/1000)",
    profile_denominator = "all-eligible-items",
    off_list_in_denominator = TRUE
  )
  exclusion_counts <- table(input$exclusion_reason)
  exclusion_diagnostics <- data.frame(
    reason = names(exclusion_counts),
    tokens = as.double(exclusion_counts),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  structure(
    list(
      status = if (nrow(lookup)) "ok" else "empty",
      summary = summary,
      lookup = lookup,
      coverage = coverage,
      provenance = provenance,
      diagnostics = c(
        prepared$diagnostics,
        list(
          exclusion_reasons = exclusion_diagnostics,
          flemma_headword_conflicts = as.double(sum(headword_conflict)),
          flemma_cross_level_conflicts = as.double(sum(
            headword_conflict & !is.na(selected_index) &
              prepared$aliases$level[selected_index] !=
                prepared$aliases$level[surface_index],
            na.rm = TRUE
          ))
        )
      )
    ),
    class = c("new_jacet8000_profile", "lexical_level_profile")
  )
}

.nj8_positive_integer <- function(value, argument) {
  if (
    !is.numeric(value) || is.object(value) || !is.null(dim(value)) ||
      !is.null(attributes(value)) || length(value) != 1L || is.na(value) ||
      !is.finite(value) || value < 1 || value != floor(value)
  ) {
    stop(sprintf("%s must be one positive finite integer.", argument), call. = FALSE)
  }
  as.double(value)
}

.nj8_prepend_document_id <- function(table, document_id) {
  data.frame(
    document_id = rep.int(document_id, nrow(table)),
    table,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.nj8_bind_document_tables <- function(profiles, ids, component, prototype) {
  if (!length(profiles)) {
    return(.nj8_prepend_document_id(
      prototype[[component]][FALSE, , drop = FALSE],
      character()
    ))
  }
  pieces <- lapply(seq_along(profiles), function(index) {
    .nj8_prepend_document_id(profiles[[index]][[component]], ids[[index]])
  })
  output <- do.call(base::rbind.data.frame, unname(pieces))
  rownames(output) <- NULL
  output
}

.nj8_batch_coverage <- function(profiles, ids, prototype) {
  make_row <- function(profile, document_id) {
    data.frame(
      document_id = document_id,
      as.data.frame(profile$coverage, stringsAsFactors = FALSE),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }
  if (!length(profiles)) {
    return(make_row(prototype, NA_character_)[FALSE, , drop = FALSE])
  }
  output <- do.call(
    base::rbind.data.frame,
    lapply(seq_along(profiles), function(index) {
      make_row(profiles[[index]], ids[[index]])
    })
  )
  rownames(output) <- NULL
  output
}

#' Profile lexical coverage by New JACET 8000 frequency level
#'
#' Creates token- and type-weighted exact and cumulative lexical profiles from
#' a caller-supplied copy of New JACET 8000. The word list is required at call
#' time and is never bundled, downloaded, or copied into the returned object.
#' Ranks 1--8000 are mapped to eight 1,000-rank levels. Off-list items retain a
#' separate denominator-visible row rather than being discarded.
#'
#' @param terms A plain character vector of ordered lexical units, or an object
#'   returned by [lexdiv_tokenize()]. For an annotated tokenization, `unit` may
#'   select lemmas or flemmas.
#' @param wordlist A data frame containing New JACET 8000 ranks and entries, or
#'   the path to the official local XLSX file or a local CSV file. No resource
#'   is downloaded.
#' @param rank_column,word_column Optional names of the rank and entry columns.
#'   `NULL` auto-detects the official Japanese rank and representative-lemma
#'   headers, or the compatible CSV headers `"NJ8"` and `"Word"`.
#' @param sheet XLSX sheet containing the list. The official workbook uses
#'   its New JACET 8000 sheet. Ignored for data-frame and CSV input.
#' @param unit One of `"surface"`, `"lemma"`, or `"flemma"`. With a plain
#'   character input, this labels the units already supplied by the caller.
#' @param flemma_conflict For flemma-annotated tokenizations, how to resolve a
#'   surface form that is itself a New JACET headword but maps to a different
#'   flemma: retain the `"antbnc"` mapping, prefer the `"wordlist"` headword,
#'   or raise an `"error"`. Explicit flemma overrides are applied upstream by
#'   [lexdiv_flemmatize()].
#' @param normalization `"nfkc_lower"` applies NFKC, trimming, and
#'   locale-fixed English lowercasing to both queries and list entries;
#'   `"identity"` performs an exact lookup.
#' @param expand_parenthetical Whether an entry such as `"mom (mum, mummy)"`
#'   contributes its parenthetical comma-separated aliases at the same rank.
#' @param resource_version Optional caller-supplied version label. If `NULL`, a
#'   label derived from the canonical rank-entry SHA-256 is used.
#'
#' @return A `new_jacet8000_profile` object containing `summary`, lossless query
#'   `lookup`, token/type `coverage`, resource provenance, and validation
#'   diagnostics. `summary$proportion` uses all eligible items as its
#'   denominator; `cumulative_proportion` is the rate at or below each level.
#'   The installed `lexical-level-profile-contract.json` records the exact
#'   denominator, normalization, conflict, and resource-boundary rules.
#' @export
new_jacet8000_profile <- function(
    terms,
    wordlist,
    rank_column = NULL,
    word_column = NULL,
    sheet = "\u65b0J8",
    unit = "lemma",
    flemma_conflict = "antbnc",
    normalization = "nfkc_lower",
    expand_parenthetical = TRUE,
    resource_version = NULL) {
  options <- .nj8_profile_options(
    unit,
    flemma_conflict,
    normalization,
    expand_parenthetical,
    sheet,
    resource_version
  )
  input <- .level_profile_terms(terms, options$unit)
  prepared <- .nj8_prepare_wordlist(
    wordlist,
    rank_column,
    word_column,
    options$sheet,
    options$normalization,
    options$expand_parenthetical
  )
  .nj8_profile_from_prepared(input, prepared, options)
}

#' Profile New JACET 8000 levels for multiple documents
#'
#' Applies the same lexical-level profile contract to a plain named list or an
#' explicit ID/list-column data frame. The caller-supplied word list is read,
#' validated, normalized, and hashed once for the whole batch.
#'
#' @inheritParams new_jacet8000_profile
#' @param documents A plain named list of character vectors or tokenization
#'   objects, or a data frame with the columns selected by `id_col` and
#'   `terms_col`.
#' @param id_col Name of the explicit document-ID column for data-frame input.
#' @param terms_col Name of the list-column containing character vectors or
#'   tokenization objects for data-frame input.
#' @param max_rows Maximum combined number of summary and token-lookup rows.
#'
#' @return A `new_jacet8000_profile_batch` object with document-major summary
#'   and lookup tables, one coverage and diagnostic row per document, explicit
#'   exclusions, shared resource provenance, and document preprocessing
#'   provenance.
#' @export
new_jacet8000_profile_batch <- function(
    documents,
    wordlist,
    rank_column = NULL,
    word_column = NULL,
    sheet = "\u65b0J8",
    unit = "lemma",
    flemma_conflict = "antbnc",
    normalization = "nfkc_lower",
    expand_parenthetical = TRUE,
    resource_version = NULL,
    id_col = "document_id",
    terms_col = "terms",
    max_rows = 1e6) {
  id_col <- .lex_batch_scalar_name(id_col, "id_col")
  terms_col <- .lex_batch_scalar_name(terms_col, "terms_col")
  if (identical(id_col, terms_col)) {
    stop("id_col and terms_col must select different columns.", call. = FALSE)
  }
  max_rows <- .nj8_positive_integer(max_rows, "max_rows")
  options <- .nj8_profile_options(
    unit,
    flemma_conflict,
    normalization,
    expand_parenthetical,
    sheet,
    resource_version
  )
  batch <- .lex_batch_documents(documents, id_col, terms_col)
  # Validate every document and enforce the combined summary/lookup bound
  # before reading or transforming the external resource.
  inputs <- lapply(batch$tokens, .level_profile_terms, unit = options$unit)
  lookup_rows <- sum(vapply(
    inputs,
    function(input) input$eligible_tokens,
    numeric(1L)
  ))
  summary_rows <- 18 * as.double(length(inputs))
  if (lookup_rows + summary_rows > max_rows) {
    stop(
      sprintf("The requested level-profile batch exceeds max_rows (%s).", format(max_rows)),
      call. = FALSE
    )
  }
  prepared <- .nj8_prepare_wordlist(
    wordlist,
    rank_column,
    word_column,
    options$sheet,
    options$normalization,
    options$expand_parenthetical
  )
  prototype <- .nj8_profile_from_prepared(
    .level_profile_terms(character(), options$unit),
    prepared,
    options
  )
  profiles <- lapply(
    inputs,
    .nj8_profile_from_prepared,
    prepared = prepared,
    options = options
  )
  summary <- .nj8_bind_document_tables(
    profiles,
    batch$ids,
    "summary",
    prototype
  )
  lookup <- .nj8_bind_document_tables(
    profiles,
    batch$ids,
    "lookup",
    prototype
  )
  coverage <- .nj8_batch_coverage(profiles, batch$ids, prototype)
  document_diagnostics <- data.frame(
    document_id = batch$ids,
    status = vapply(profiles, `[[`, character(1L), "status"),
    flemma_headword_conflicts = vapply(
      profiles,
      function(profile) profile$diagnostics$flemma_headword_conflicts,
      numeric(1L)
    ),
    flemma_cross_level_conflicts = vapply(
      profiles,
      function(profile) profile$diagnostics$flemma_cross_level_conflicts,
      numeric(1L)
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (length(profiles)) {
    exclusion_pieces <- lapply(seq_along(profiles), function(index) {
      .nj8_prepend_document_id(
        profiles[[index]]$diagnostics$exclusion_reasons,
        batch$ids[[index]]
      )
    })
    exclusion_reasons <- do.call(
      base::rbind.data.frame,
      unname(exclusion_pieces)
    )
    rownames(exclusion_reasons) <- NULL
  } else {
    exclusion_reasons <- .nj8_prepend_document_id(
      prototype$diagnostics$exclusion_reasons,
      character()
    )
  }
  document_provenance <- data.frame(
    document_id = batch$ids,
    input_source = vapply(
      profiles,
      function(profile) profile$provenance$input_source,
      character(1L)
    ),
    selected_unit = rep.int(options$unit, length(profiles)),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  document_provenance$preprocessing_ref <- I(lapply(
    profiles,
    function(profile) profile$provenance$preprocessing_ref
  ))
  shared_provenance <- prototype$provenance
  shared_provenance$input_source <- NULL
  shared_provenance$preprocessing_ref <- NULL
  shared_provenance$batch_contract_id <- .level_profile_batch_contract_id
  shared_provenance$batch_contract_version <- .level_profile_batch_contract_version
  shared_provenance$document_count <- as.double(length(profiles))
  shared_provenance$max_rows <- max_rows
  shared_provenance$returned_rows <- as.double(nrow(summary) + nrow(lookup))
  structure(
    list(
      status = if (length(profiles)) "ok" else "empty",
      summary = summary,
      lookup = lookup,
      coverage = coverage,
      document_diagnostics = document_diagnostics,
      exclusion_reasons = exclusion_reasons,
      document_provenance = document_provenance,
      provenance = shared_provenance,
      resource_diagnostics = prepared$diagnostics
    ),
    class = c(
      "new_jacet8000_profile_batch",
      "lexical_level_profile_batch"
    )
  )
}

#' @export
print.new_jacet8000_profile_batch <- function(x, ...) {
  document_count <- nrow(x$coverage)
  token_count <- sum(x$coverage$eligible_tokens)
  conflict_count <- sum(x$document_diagnostics$flemma_headword_conflicts)
  cat(sprintf(
    paste0(
      "<new_jacet8000_profile_batch: %d document%s; %s eligible token%s; ",
      "unit=%s; conflicts=%s>\n"
    ),
    document_count,
    if (document_count == 1L) "" else "s",
    format(token_count, scientific = FALSE),
    if (token_count == 1) "" else "s",
    x$provenance$selected_unit,
    format(conflict_count, scientific = FALSE)
  ))
  visible <- x$coverage[c(
    "document_id", "eligible_tokens", "token_coverage",
    "eligible_types", "type_coverage"
  )]
  print.data.frame(visible, ...)
  invisible(x)
}

#' @export
print.lexical_level_profile <- function(x, ...) {
  token_coverage <- x$coverage$token_coverage
  coverage_label <- if (is.na(token_coverage)) {
    "NA"
  } else {
    sprintf("%.1f%%", 100 * token_coverage)
  }
  cat(sprintf(
    "<new_jacet8000_profile> status=%s | token coverage=%s | unit=%s\n",
    x$status,
    coverage_label,
    x$provenance$selected_unit
  ))
  print(x$summary[x$summary$weighting == "token", ], row.names = FALSE, ...)
  invisible(x)
}

#' Plot a lexical level profile
#'
#' Draws exact level rates or counts as bars and, by default, overlays the
#' cumulative profile through Level 8. The off-list bar is shown separately and
#' is not appended to the cumulative curve.
#'
#' @param x A result returned by [new_jacet8000_profile()].
#' @param weighting Either `"token"` or `"type"`.
#' @param scale Plot exact and cumulative `"proportion"` values or `"count"`
#'   values.
#' @param show_cumulative Whether to overlay the cumulative series.
#' @param include_off_list Whether to include the separate off-list bar.
#' @param bar_col,cumulative_col Colors for the bars and cumulative curve.
#' @param main,xlab,ylab Optional plot labels.
#' @param show_legend Whether to draw a compact legend.
#' @param ... Additional arguments passed to [graphics::barplot()].
#'
#' @return Invisibly, the rows and plotting values used to draw the figure.
#' @export
plot.lexical_level_profile <- function(
    x,
    weighting = "token",
    scale = "proportion",
    show_cumulative = TRUE,
    include_off_list = TRUE,
    bar_col = "#4C78A8",
    cumulative_col = "#E45756",
    main = NULL,
    xlab = "New JACET 8000 frequency level",
    ylab = NULL,
    show_legend = TRUE,
    ...) {
  if (!inherits(x, "lexical_level_profile") || !is.data.frame(x$summary)) {
    stop("x must be a lexical level profile.", call. = FALSE)
  }
  weighting <- .lexprep_scalar_choice(
    weighting,
    c("token", "type"),
    "weighting"
  )
  scale <- .lexprep_scalar_choice(scale, c("proportion", "count"), "scale")
  show_cumulative <- .lexprep_scalar_flag(show_cumulative, "show_cumulative")
  include_off_list <- .lexprep_scalar_flag(include_off_list, "include_off_list")
  show_legend <- .lexprep_scalar_flag(show_legend, "show_legend")
  rows <- x$summary[x$summary$weighting == weighting, , drop = FALSE]
  if (!include_off_list) rows <- rows[!is.na(rows$level), , drop = FALSE]
  exact <- if (identical(scale, "proportion")) rows$proportion else rows$items
  cumulative <- if (identical(scale, "proportion")) {
    rows$cumulative_proportion
  } else {
    rows$cumulative_items
  }
  if (is.null(main)) {
    main <- sprintf("New JACET 8000 lexical profile (%s)", weighting)
  }
  if (is.null(ylab)) {
    ylab <- if (identical(scale, "proportion")) {
      sprintf("Proportion of all eligible %ss", weighting)
    } else {
      sprintf("Number of %ss", weighting)
    }
  }
  finite_values <- c(exact[is.finite(exact)], cumulative[is.finite(cumulative)])
  upper <- if (!length(finite_values) || max(finite_values) <= 0) {
    1
  } else {
    max(finite_values) * 1.08
  }
  bar_colors <- ifelse(is.na(rows$level), "#B8B8B8", bar_col)
  positions <- graphics::barplot(
    height = ifelse(is.na(exact), 0, exact),
    names.arg = rows$level_label,
    col = bar_colors,
    border = NA,
    ylim = c(0, upper),
    main = main,
    xlab = xlab,
    ylab = ylab,
    ...
  )
  cumulative_rows <- which(!is.na(rows$level) & is.finite(cumulative))
  if (show_cumulative && length(cumulative_rows)) {
    graphics::lines(
      positions[cumulative_rows],
      cumulative[cumulative_rows],
      col = cumulative_col,
      lwd = 2,
      type = "b",
      pch = 16
    )
  }
  if (show_legend) {
    labels <- "Exact level"
    line_types <- NA_integer_
    points <- 15L
    colors <- bar_col
    line_widths <- NA_real_
    point_sizes <- 1.4
    if (show_cumulative && length(cumulative_rows)) {
      labels <- c(labels, "Cumulative through level")
      line_types <- c(line_types, 1L)
      points <- c(points, 16L)
      colors <- c(colors, cumulative_col)
      line_widths <- c(line_widths, 2)
      point_sizes <- c(point_sizes, 1)
    }
    graphics::legend(
      "right",
      legend = labels,
      lty = line_types,
      pch = points,
      col = colors,
      lwd = line_widths,
      pt.cex = point_sizes,
      bty = "n"
    )
  }
  invisible(data.frame(
    rows,
    exact_plot_value = exact,
    cumulative_plot_value = cumulative,
    stringsAsFactors = FALSE,
    check.names = FALSE
  ))
}
