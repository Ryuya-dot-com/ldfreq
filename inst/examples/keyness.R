# Source concordance.R into the same environment before these example helpers.
keyness_compare <- function(x, target, reference, preprocessing_id,
    term_col = "surface", keep = rep(TRUE, nrow(x$tokens)), min_count = 1L,
    max_tokens = 1e6) {
  min_count <- .concordance_whole(min_count, "min_count")
  max_tokens <- .concordance_whole(max_tokens, "max_tokens")
  if (!is.list(x) || !identical(x$provenance$importer, "ldfreq-external-annotations"))
    stop("Supply an unchanged lexdiv_import_annotations() result.", call. = FALSE)
  checked <- ldfreq::lexdiv_import_annotations(x$tokens,
    x$segments[setdiff(names(x$segments), c("token_count", "text_sha256"))],
    x$provenance$annotation, max_tokens = max_tokens)
  if (!identical(x, checked))
    stop("Source annotations changed; import the complete source again.", call. = FALSE)
  strings <- function(z) is.character(z) && length(z) > 0L && !anyNA(z) &&
    all(validUTF8(z)) && all(nzchar(stringi::stri_trim_both(z)))
  ids <- x$documents$document_id
  for (group in list(target, reference)) {
    if (!strings(group) || anyDuplicated(group) || !all(group %in% ids))
      stop("target and reference must each contain unique, known document IDs.", call. = FALSE)
  }
  if (length(intersect(target, reference)))
    stop("Target and reference document IDs must not overlap.", call. = FALSE)
  if (!strings(preprocessing_id) || length(preprocessing_id) != 1L)
    stop("preprocessing_id must describe one explicit selection policy.", call. = FALSE)
  if (!strings(term_col) || length(term_col) != 1L ||
      !term_col %in% names(x$tokens) || !is.character(x$tokens[[term_col]]))
    stop("term_col must name a character column in the source tokens.", call. = FALSE)
  if (!is.logical(keep) || length(keep) != nrow(x$tokens) || anyNA(keep))
    stop("keep must have one non-missing logical value per original token.", call. = FALSE)
  term <- enc2utf8(x$tokens[[term_col]])
  if (any(!validUTF8(term[!is.na(term)])))
    stop("Terms must be valid UTF-8.", call. = FALSE)
  available <- !is.na(term) & nzchar(stringi::stri_trim_both(term))
  corpus <- ifelse(ids %in% target, "target", ifelse(ids %in% reference, "reference", "excluded"))
  doc <- match(x$tokens$document_id, ids)
  counted <- corpus[doc] != "excluded" & keep & available
  token_audit <- data.frame(token_row = seq_len(nrow(x$tokens)), document_id = ids[doc],
    corpus = corpus[doc], term = term, keep = keep, available = available, counted = counted,
    status = as.character(ifelse(corpus[doc] == "excluded", "excluded_document",
      ifelse(!keep, "excluded_token", ifelse(!available, "missing_term", "counted")))))
  documents <- data.frame(document_id = ids, corpus = corpus,
    source_tokens = tabulate(doc, length(ids)), kept_tokens = tabulate(doc[keep], length(ids)),
    missing_terms = tabulate(doc[keep & !available], length(ids)),
    counted_tokens = tabulate(doc[counted], length(ids)), stringsAsFactors = FALSE)
  documents$text_sequence_sha256 <- vapply(ids, function(id)
    .concordance_hash(unname(x$segments$text[x$segments$document_id == id])), character(1))
  shared <- intersect(documents$text_sequence_sha256[corpus == "target"],
    documents$text_sequence_sha256[corpus == "reference"])
  documents$shared_text_across_groups <- corpus != "excluded" & documents$text_sequence_sha256 %in% shared
  totals <- data.frame(corpus = c("target", "reference"), documents = c(length(target), length(reference)))
  for (column in c("source_tokens", "kept_tokens", "missing_terms", "counted_tokens"))
    totals[[column]] <- vapply(totals$corpus, function(g)
      sum(documents[[column]][corpus == g]), numeric(1))
  totals$status <- ifelse(totals$counted_tokens == 0, "no_counted_tokens", "ok")
  occurrences <- x$tokens[counted, c("document_id", "segment_id", "token_index", "start", "end"), drop = FALSE]
  occurrences$token_row <- which(counted)
  occurrences$corpus <- corpus[doc[counted]]
  occurrences$term <- term[counted]
  rownames(occurrences) <- NULL
  vocabulary <- unique(occurrences$term)
  index <- match(occurrences$term, vocabulary)
  key <- paste(doc[counted], index, sep = ":")
  first <- !duplicated(key)
  document_counts <- occurrences[first, c("document_id", "corpus", "term"), drop = FALSE]
  document_counts$count <- tabulate(match(key, key[first]), nrow(document_counts))
  rownames(document_counts) <- NULL
  is_target <- occurrences$corpus == "target"
  a <- as.double(tabulate(index[is_target], length(vocabulary)))
  c <- as.double(tabulate(index[!is_target], length(vocabulary)))
  nt <- totals$counted_tokens[1]; nr <- totals$counted_tokens[2]
  b <- nt - a; d <- nr - c
  expected <- matrix(NA_real_, nrow = length(a), ncol = 4)
  if (nt + nr > 0) {
    feature <- (a + c) / (nt + nr)
    other <- (b + d) / (nt + nr)
    expected <- cbind(nt * feature, nt * other, nr * feature, nr * other)
  }
  g2 <- signed <- ratio <- rep(NA_real_, length(a))
  direction <- rep(NA_character_, length(a))
  status <- rep(if (nt == 0 && nr == 0) "empty_both" else if (nt == 0)
    "empty_target" else if (nr == 0) "empty_reference" else "ok", length(a))
  if (nt > 0 && nr > 0) {
    observed <- cbind(a, b, c, d)
    contribution <- matrix(0, nrow = length(a), ncol = 4)
    positive <- observed > 0
    contribution[positive] <- observed[positive] * log(observed[positive] / expected[positive])
    g2 <- pmax(0, 2 * rowSums(contribution))
    sign_rate <- sign(a * nr - c * nt)
    g2[sign_rate == 0] <- 0
    signed <- sign_rate * g2
    ratio <- log2(a / nt) - log2(c / nr)
    direction <- ifelse(sign_rate > 0, "target", ifelse(sign_rate < 0, "reference", "equal"))
    status[a + c == nt + nr] <- "constant_feature"
  }
  results <- data.frame(term = vocabulary, target_count = a, target_other = b,
    reference_count = c, reference_other = d,
    target_total = rep(nt, length(a)), reference_total = rep(nr, length(a)),
    expected_target = expected[, 1], expected_target_other = expected[, 2],
    expected_reference = expected[, 3], expected_reference_other = expected[, 4],
    target_per_1000 = if (nt) 1000 * a / nt else rep(NA_real_, length(a)),
    reference_per_1000 = if (nr) 1000 * c / nr else rep(NA_real_, length(a)),
    log_ratio = ratio, G2 = g2, signed_G2 = signed, direction = direction,
    target_documents = tabulate(match(document_counts$term[document_counts$corpus == "target"], vocabulary), length(a)),
    reference_documents = tabulate(match(document_counts$term[document_counts$corpus == "reference"], vocabulary), length(a)),
    meets_min_count = a + c >= min_count, status = status, stringsAsFactors = FALSE)
  settings <- list(target = target, reference = reference, preprocessing_id = preprocessing_id,
    term_col = term_col, keep = keep, counted = counted, min_count = min_count, max_tokens = max_tokens,
    vocabulary = "union-of-counted-target-and-reference-terms; exact-UTF8; no-normalization",
    denominator = "all-counted-tokens-in-each-declared-corpus",
    G2 = "2*sum(O*log(O/E)); zero-cell-contribution=0; no-continuity-correction",
    sign = "sign(target_count*reference_total-reference_count*target_total)",
    log_ratio = "log2(target_count/target_total)-log2(reference_count/reference_total); no-smoothing",
    threshold = "pooled-count-display-flag; no-change-to-denominators-or-vocabulary",
    inference = "descriptive-scores-only; no-p-values-or-significance-decisions")
  provenance <- list(recipe = "ldfreq-example-keyness", recipe_version = "1",
    ldfreq_version = as.character(utils::packageVersion("ldfreq")),
    comparison_id = .concordance_hash(list(x$provenance, settings)))
  result <- list(results = results, totals = totals, documents = documents,
    document_counts = document_counts, occurrences = occurrences, token_audit = token_audit,
    source = x, settings = settings, provenance = provenance)
  result$integrity_sha256 <- .concordance_hash(result)
  result
}

keyness_validate <- function(x) {
  if (!is.list(x) || !identical(x$provenance$recipe, "ldfreq-example-keyness") ||
      !identical(x$provenance$recipe_version, "1") ||
      !identical(x$integrity_sha256, .concordance_hash(x[names(x) != "integrity_sha256"])))
    stop("The saved keyness record changed; repeat keyness_compare().", call. = FALSE)
  invisible(x)
}

keyness_concordance <- function(x, term, window = 5L, max_cells = 1e6) {
  keyness_validate(x)
  if (!is.character(term) || length(term) != 1L || is.na(term) || !term %in% x$results$term)
    stop("term must select one exact term in the saved results.", call. = FALSE)
  selected <- x$settings$counted & !is.na(x$token_audit$term) & x$token_audit$term == term
  # Filter endpoints first: quanteda's Unicode matching must not merge count keys.
  search <- concordance_search(x$source, list(feature = term), term_col = x$settings$term_col,
    keep = selected, valuetype = "fixed", case_insensitive = FALSE,
    window = window, max_cells = max_cells)
  list(comparison_id = x$provenance$comparison_id, term = term, search = search)
}
