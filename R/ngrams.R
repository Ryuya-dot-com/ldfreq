# Adjacent word sequences from explicit segments and original token positions.
# No corpus, sentence splitter, normalization or network access is implicit.
.lexng_columns <- c("n", "term1", "term2", "term3")
.lexng_contract <- "ldfreq-adjacent-ngrams"

.lexng_key <- function(x) {
  # Length-prefixed UTF-8 components keep underscores, colons and separators
  # in actual terms distinct. NA is used only for the absent third bigram term.
  parts <- lapply(x, function(v) {
    v <- enc2utf8(as.character(v))
    ifelse(is.na(v), "-1:", paste0(nchar(v, type = "bytes"), ":", v))
  })
  do.call(paste0, parts)
}

.lexng_hash <- function(x) {
  x$provenance$content_sha256 <- NULL
  digest::digest(x, algo = "sha256", serializeVersion = 2L)
}

.lexng_seal <- function(x, class) {
  class(x) <- class
  x$provenance$content_sha256 <- .lexng_hash(x)
  x
}

.lexng_validate_result <- function(x, class) {
  if (!inherits(x, class) || !is.list(x) || !is.list(x$provenance) ||
      !identical(x$provenance$contract_id, .lexng_contract) ||
      !identical(x$provenance$contract_version, "0.1.0") ||
      !identical(x$provenance$content_sha256, .lexng_hash(x))) {
    stop("Use an unmodified ", class, " result, including its provenance.", call. = FALSE)
  }
  invisible(x)
}

.lexng_count <- function(x, label, minimum = 0) {
  if (!is.numeric(x) || is.object(x) || !is.null(dim(x)) ||
      anyNA(x) || any(!is.finite(x)) || any(x < minimum) ||
      any(x != floor(x)) || any(x > 2^53 - 1)) {
    stop(label, " must contain finite whole numbers >= ", minimum, ".", call. = FALSE)
  }
  as.double(x)
}

.lexng_tally <- function(occurrences, by_document = FALSE) {
  columns <- c(if (by_document) "document_id", .lexng_columns)
  key <- .lexng_key(occurrences[columns])
  first <- !duplicated(key)
  group <- match(key, key[first])
  out <- occurrences[first, columns, drop = FALSE]
  out$count <- as.double(tabulate(group, nbins = nrow(out)))
  if (!by_document) {
    unique_docs <- !duplicated(data.frame(group, document_id = occurrences$document_id))
    out$document_count <- as.double(tabulate(group[unique_docs], nbins = nrow(out)))
  }
  rownames(out) <- NULL
  out
}

lexdiv_ngrams <- function(data, preprocessing_id, n = c(2L, 3L),
    documents = NULL, id_col = "document_id", segment_col = "segment_id",
    position_col = "token_index", term_col = "term", max_ngrams = 1e6) {
  data <- .lexnorm_plain_data_frame(data, "data")
  selectors <- c(id_col, segment_col, position_col, term_col)
  for (v in list(id_col, segment_col, position_col, term_col))
    .lex_batch_scalar_name(v, "column selector")
  if (anyDuplicated(selectors) || !all(selectors %in% names(data)))
    stop("Select four distinct existing input columns.", call. = FALSE)
  preprocessing_id <- .lexnorm_scalar_string(preprocessing_id, "preprocessing_id")
  n <- .lexng_count(n, "n", 2)
  if (!length(n) || any(!n %in% c(2, 3)) || anyDuplicated(n))
    stop("n must be a non-empty, unique selection of 2 and 3.", call. = FALSE)
  n <- as.integer(n)
  max_ngrams <- .lexnorm_positive_whole(max_ngrams, "max_ngrams")
  id <- .lexnorm_plain_character(data[[id_col]], id_col, allow_zero = TRUE)
  segment <- .lexnorm_plain_character(data[[segment_col]], segment_col, allow_zero = TRUE)
  term <- .lexnorm_plain_character(data[[term_col]], term_col, allow_zero = TRUE)
  if (any(stringi::stri_detect_regex(term, "\\p{White_Space}")))
    stop("Each term must be a single token without whitespace.", call. = FALSE)
  position <- .lexng_count(data[[position_col]], position_col, 1)
  if (is.null(documents)) documents <- unique(id)
  documents <- .lexnorm_plain_character(documents, "documents", allow_zero = TRUE)
  if (anyDuplicated(documents) || !all(id %in% documents))
    stop("documents must be unique and include every input document ID.", call. = FALSE)
  group <- match(.lexng_key(data.frame(id, segment)),
    unique(.lexng_key(data.frame(id, segment))))
  same <- if (length(group) > 1L) diff(group) == 0L else logical()
  if (anyDuplicated(group[c(TRUE, !same)]) || any(diff(position)[same] <= 0))
    stop("Each document/segment must be one contiguous block with increasing positions.",
      call. = FALSE)
  # A position gap breaks adjacency even within one segment. Never sort input.
  run <- if (length(id)) cumsum(c(TRUE, !same | diff(position) != 1)) else integer()
  starts <- lapply(n, function(k) {
    i <- seq_len(max(0, length(id) - k + 1L))
    i[run[i] == run[i + k - 1L]]
  })
  planned <- sum(lengths(starts))
  if (planned > max_ngrams)
    stop("Planned n-gram occurrences exceed max_ngrams.", call. = FALSE)
  pieces <- lapply(seq_along(n), function(j) {
    i <- starts[[j]]; k <- n[j]
    data.frame(document_id = id[i], segment_id = segment[i], n = rep.int(k, length(i)),
      start_index = position[i], end_index = position[i + k - 1L],
      term1 = term[i], term2 = term[i + 1L],
      term3 = if (k == 3L) term[i + 2L] else rep.int(NA_character_, length(i)),
      stringsAsFactors = FALSE)
  })
  occurrences <- do.call(rbind, pieces)
  rownames(occurrences) <- NULL
  counts <- .lexng_tally(occurrences)
  document_counts <- .lexng_tally(occurrences, TRUE)
  doc <- data.frame(document_id = rep(documents, each = length(n)),
    n = rep(n, times = length(documents)), stringsAsFactors = FALSE)
  doc$input_tokens <- rep(as.double(tabulate(match(id, documents), length(documents))),
    each = length(n))
  doc_key <- .lexng_key(doc[c("document_id", "n")])
  doc$opportunities <- as.double(tabulate(match(
    .lexng_key(occurrences[c("document_id", "n")]), doc_key), nrow(doc)))
  doc$ngram_types <- as.double(tabulate(match(
    .lexng_key(document_counts[c("document_id", "n")]), doc_key), nrow(doc)))
  doc$status <- as.character(ifelse(doc$input_tokens == 0, "empty_document",
    ifelse(doc$opportunities == 0, "no_ngrams", "ok")))
  totals <- data.frame(n = n,
    opportunities = as.double(tabulate(match(occurrences$n, n), length(n))),
    documents = rep.int(as.double(length(documents)), length(n)))
  .lexng_seal(list(occurrences = occurrences, counts = counts,
    document_counts = document_counts, documents = doc, totals = totals,
    provenance = list(contract_id = .lexng_contract, contract_version = "0.1.0",
      preprocessing_id = preprocessing_id, n = n,
      input_columns = stats::setNames(selectors, c("document", "segment", "position", "term")),
      input_sha256 = digest::digest(list(id, segment, position, term, documents),
        algo = "sha256", serializeVersion = 2L),
      boundary_policy = "same-document-same-segment-consecutive-original-positions",
      boundary_evidence = "caller-supplied-not-independently-verified",
      normalization = "none", max_ngrams = max_ngrams,
      runtime_network_access = FALSE)), "lexdiv_ngrams")
}

lexdiv_ngram_reference <- function(x, resource, totals = NULL,
    preprocessing_id = NULL, complete = NULL) {
  resource <- .lexnorm_resource(resource)
  source_sha256 <- NULL
  if (inherits(x, "lexdiv_ngrams")) {
    .lexng_validate_result(x, "lexdiv_ngrams")
    if (!is.null(totals) || !is.null(preprocessing_id))
      stop("totals and preprocessing_id are taken from the extraction result.", call. = FALSE)
    totals <- x$totals
    preprocessing_id <- x$provenance$preprocessing_id
    source_sha256 <- x$provenance$content_sha256
    x <- x$counts
    if (is.null(complete)) complete <- TRUE
  } else if (is.null(complete)) complete <- FALSE
  complete <- .lexprep_scalar_flag(complete, "complete")
  preprocessing_id <- .lexnorm_scalar_string(preprocessing_id, "preprocessing_id")
  x <- .lexnorm_plain_data_frame(x, "x")
  totals <- .lexnorm_plain_data_frame(totals, "totals")
  count_columns <- c(.lexng_columns, "count", "document_count")
  if (!all(count_columns %in% names(x)) ||
      !all(c("n", "opportunities", "documents") %in% names(totals)))
    stop("Reference counts or totals are missing required columns; see help.", call. = FALSE)
  x <- x[count_columns]
  totals <- totals[c("n", "opportunities", "documents")]
  x$n <- .lexng_count(x$n, "x$n", 2)
  totals$n <- .lexng_count(totals$n, "totals$n", 2)
  if (!nrow(totals) || any(!totals$n %in% c(2, 3)) || anyDuplicated(totals$n) ||
      !all(x$n %in% totals$n)) stop("Invalid n values in reference counts/totals.", call. = FALSE)
  x$n <- as.integer(x$n); totals$n <- as.integer(totals$n)
  for (column in c("term1", "term2"))
    x[[column]] <- .lexnorm_plain_character(x[[column]], column, allow_zero = TRUE)
  if (!is.character(x$term3) || is.object(x$term3) || !is.null(dim(x$term3)) ||
      any(!is.na(x$term3[x$n == 2L])))
    stop("term3 must be character and NA for bigrams.", call. = FALSE)
  x$term3[x$n == 3L] <- .lexnorm_plain_character(x$term3[x$n == 3L],
    "trigram term3", allow_zero = TRUE)
  terms <- c(x$term1, x$term2, x$term3[x$n == 3L])
  if (any(stringi::stri_detect_regex(terms, "\\p{White_Space}")))
    stop("Reference terms must not contain whitespace.", call. = FALSE)
  if (anyDuplicated(.lexng_key(x[.lexng_columns])))
    stop("Reference n-gram keys must be unique.", call. = FALSE)
  x$count <- .lexng_count(x$count, "count", 1)
  x$document_count <- .lexng_count(x$document_count, "document_count", 1)
  totals$opportunities <- .lexng_count(totals$opportunities, "opportunities")
  totals$documents <- .lexng_count(totals$documents, "documents")
  j <- match(x$n, totals$n)
  if (any(x$document_count > x$count) || any(x$document_count > totals$documents[j]) ||
      any(totals$opportunities > 0 & totals$documents == 0))
    stop("Reference document counts are inconsistent.", call. = FALSE)
  for (i in seq_len(nrow(totals))) {
    observed <- sum(x$count[x$n == totals$n[i]])
    if (observed > totals$opportunities[i] ||
        (complete && observed != totals$opportunities[i]))
      stop("Reference count sums disagree with opportunities/completeness.", call. = FALSE)
  }
  rownames(x) <- rownames(totals) <- NULL
  .lexng_seal(list(counts = x, totals = totals,
    provenance = list(contract_id = .lexng_contract, contract_version = "0.1.0",
      resource = resource, preprocessing_id = preprocessing_id, complete = complete,
      source_extraction_sha256 = source_sha256,
      metadata_evidence = "caller-assertions-not-license-or-compatibility-certification",
      matching = "exact-UTF8-component-sequences", runtime_network_access = FALSE)),
    "lexdiv_ngram_reference")
}

lexdiv_ngram_profile <- function(x, reference) {
  .lexng_validate_result(x, "lexdiv_ngrams")
  .lexng_validate_result(reference, "lexdiv_ngram_reference")
  if (!identical(x$provenance$preprocessing_id, reference$provenance$preprocessing_id))
    stop("Target and reference preprocessing_id must agree; inspect the actual preparation.",
      call. = FALSE)
  if (!all(x$totals$n %in% reference$totals$n))
    stop("The reference must declare totals for every requested n.", call. = FALSE)
  lookup <- x$occurrences
  key <- .lexng_key(lookup[.lexng_columns])
  j <- match(key, .lexng_key(reference$counts[.lexng_columns]))
  listed <- !is.na(j)
  total <- reference$totals$opportunities[match(lookup$n, reference$totals$n)]
  lookup$reference_status <- as.character(ifelse(listed, "listed",
    if (reference$provenance$complete) "not_observed" else "not_listed"))
  lookup$reference_count <- reference$counts$count[j]
  lookup$reference_document_count <- reference$counts$document_count[j]
  if (reference$provenance$complete) {
    lookup$reference_count[!listed] <- 0
    lookup$reference_document_count[!listed] <- 0
  }
  lookup$reference_opportunities <- total
  lookup$frequency_per_million <- as.double(ifelse(total > 0,
    lookup$reference_count / total * 1e6, NA_real_))
  docs <- x$documents
  summary <- docs[rep(seq_len(nrow(docs)), each = 2L), c("document_id", "n"), drop = FALSE]
  summary$weighting <- rep(c("token", "type"), nrow(docs))
  for (name in c("eligible_items", "listed_items", "zero_items", "unavailable_items"))
    summary[[name]] <- numeric(nrow(summary))
  for (name in c("lookup_coverage", "value_coverage", "mean_frequency_per_million"))
    summary[[name]] <- rep.int(NA_real_, nrow(summary))
  summary$status <- rep.int(NA_character_, nrow(summary))
  summary$missing_reason <- rep.int(NA_character_, nrow(summary))
  # Group once; documents remain separate, including explicitly empty ones.
  groups <- match(.lexng_key(lookup[c("document_id", "n")]),
    .lexng_key(docs[c("document_id", "n")]))
  rows <- split(seq_len(nrow(lookup)), factor(groups, levels = seq_len(nrow(docs))))
  for (i in seq_len(nrow(docs))) for (w in seq_len(2L)) {
    take <- rows[[i]]
    if (w == 2L) take <- take[!duplicated(key[take])]
    k <- (i - 1L) * 2L + w
    size <- length(take)
    summary$eligible_items[k] <- size
    summary$listed_items[k] <- sum(lookup$reference_status[take] == "listed")
    summary$zero_items[k] <- sum(lookup$reference_status[take] == "not_observed")
    values <- lookup$frequency_per_million[take]
    known <- !is.na(values)
    summary$unavailable_items[k] <- sum(!known)
    if (size) {
      summary$lookup_coverage[k] <- summary$listed_items[k] / size
      summary$value_coverage[k] <- sum(known) / size
    }
    summary$status[k] <- if (!size) "empty" else if (!any(known)) "no_values" else "ok"
    summary$missing_reason[k] <- if (!size) "no_target_ngrams" else if (!any(known)) {
      total_n <- reference$totals$opportunities[match(docs$n[i], reference$totals$n)]
      if (total_n == 0) "zero_reference_opportunities" else "no_available_reference_values"
    } else NA_character_
    if (any(known)) summary$mean_frequency_per_million[k] <- mean(values[known])
  }
  rownames(summary) <- NULL
  .lexng_seal(list(summary = summary, lookup = lookup, documents = docs,
    provenance = list(contract_id = .lexng_contract, contract_version = "0.1.0",
      target = x$provenance, reference = reference$provenance,
      reference_totals = reference$totals,
      statistic = "arithmetic-mean-available-values-by-document-n-weighting",
      rate_denominator = "reference-eligible-n-gram-opportunities",
      runtime_network_access = FALSE)), "lexdiv_ngram_profile")
}

.lexng_print <- function(x, class, table, ...) {
  .lexng_validate_result(x, class)
  cat(sprintf("<%s; contract 0.1.0>\n", class))
  print.data.frame(utils::head(x[[table]], 12L), row.names = FALSE, ...)
  if (nrow(x[[table]]) > 12L) cat("... additional rows omitted\n")
  invisible(x)
}

print.lexdiv_ngrams <- function(x, ...) .lexng_print(x, "lexdiv_ngrams", "documents", ...)
print.lexdiv_ngram_reference <- function(x, ...) .lexng_print(x, "lexdiv_ngram_reference", "totals", ...)
print.lexdiv_ngram_profile <- function(x, ...) .lexng_print(x, "lexdiv_ngram_profile", "summary", ...)
