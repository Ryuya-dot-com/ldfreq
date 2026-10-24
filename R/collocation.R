# Shared implementation for the public API and legacy installed examples.
# Pair opportunities use original positions, not a compressed token stream.
collocation_profile <- function(search, query_id, span = c(left = 0L, right = 1L),
    min_count = 1L, max_pairs = 1e6) {
  .concordance_check(search)
  if (!is.character(query_id) || length(query_id) != 1L || is.na(query_id) ||
      !query_id %in% names(search$queries))
    stop("query_id must select one saved query.", call. = FALSE)
  if (length(search$queries[[query_id]]) != 1L)
    stop("Collocation nodes must be single-token queries.", call. = FALSE)
  if (!is.numeric(span) || length(span) != 2L ||
      !identical(names(span), c("left", "right")))
    stop("span must be c(left = ..., right = ...) in original token slots.", call. = FALSE)
  span <- vapply(span, .concordance_whole, integer(1), name = "span", minimum = 0)
  if (!any(span > 0L)) stop("span must include at least one other slot.", call. = FALSE)
  min_count <- .concordance_whole(min_count, "min_count")
  max_pairs <- .concordance_whole(max_pairs, "max_pairs")
  source <- search$source; tokens <- source$tokens; segments <- source$segments
  n <- segments$token_count
  potential <- numeric(length(n))
  for (width in span) {
    m <- pmin(width, pmax(0, n - 1))
    potential <- potential + n * m - m * (m + 1) / 2
  }
  # Refuse the full candidate space before allocating; never truncate a sample.
  if (sum(potential) > max_pairs)
    stop("Candidate slot pairs exceed max_pairs; reduce the span or source size.", call. = FALSE)
  group <- rep(seq_along(n), n)
  maximum <- max(c(0, n - 1))
  distances <- c(-seq_len(min(span[1], maximum)), seq_len(min(span[2], maximum)))
  pieces <- lapply(distances, function(distance) {
    first <- seq_len(max(0, nrow(tokens) - abs(distance)))
    second <- first + abs(distance)
    same <- group[first] == group[second]
    i <- if (distance > 0) first[same] else second[same]
    j <- if (distance > 0) second[same] else first[same]
    eligible <- search$settings$searchable[i] & search$settings$searchable[j]
    data.frame(node_row = i[eligible], context_row = j[eligible],
      distance = rep(distance, sum(eligible)))
  })
  pairs <- if (length(pieces)) do.call(rbind, pieces) else
    data.frame(node_row = integer(), context_row = integer(), distance = integer())
  pairs <- pairs[order(pairs$node_row, pairs$distance), , drop = FALSE]
  rownames(pairs) <- NULL
  hit <- search$occurrences[search$occurrences$query_id == query_id, , drop = FALSE]
  # Imported segments and tokens share a complete, stable segment order.
  offsets <- c(0, utils::head(cumsum(n), -1L))
  hit_group <- match(paste0(nchar(hit$document_id, type = "bytes"), ":", hit$document_id,
    hit$segment_id), paste0(nchar(segments$document_id, type = "bytes"), ":",
    segments$document_id, segments$segment_id))
  hit_rows <- offsets[hit_group] + hit$from
  if (anyNA(hit_rows) || anyDuplicated(hit_rows) || any(hit$from != hit$to))
    stop("Saved node occurrences do not identify unique single-token positions.", call. = FALSE)
  matched <- match(pairs$node_row, hit_rows)
  pairs$is_node <- !is.na(matched)
  pairs$occurrence_id <- hit$occurrence_id[matched]
  pairs$document_id <- tokens$document_id[pairs$node_row]
  pairs$segment_id <- tokens$segment_id[pairs$node_row]
  pairs$node_position <- tokens$token_index[pairs$node_row]
  pairs$context_position <- tokens$token_index[pairs$context_row]
  pairs$node_start <- tokens$start[pairs$node_row]
  pairs$node_end <- tokens$end[pairs$node_row]
  pairs$context_start <- tokens$start[pairs$context_row]
  pairs$context_end <- tokens$end[pairs$context_row]
  term <- enc2utf8(tokens[[search$settings$term_col]])
  pairs$node_term <- term[pairs$node_row]
  pairs$context_term <- term[pairs$context_row]
  terms <- unique(pairs$context_term)
  index <- match(pairs$context_term, terms)
  observed <- tabulate(index[pairs$is_node], length(terms))
  context_marginal <- tabulate(index, length(terms))
  node_marginal <- sum(pairs$is_node)
  total <- nrow(pairs)
  expected <- if (total) node_marginal * (context_marginal / total) else numeric()
  mi <- t_score <- rep(NA_real_, length(terms))
  positive <- observed > 0 & expected > 0
  mi[positive] <- log2(observed[positive] / expected[positive])
  mi[observed == 0 & expected > 0] <- -Inf
  t_score[positive] <- (observed[positive] - expected[positive]) / sqrt(observed[positive])
  seen <- !duplicated(data.frame(context = index, document_id = pairs$document_id))
  node_seen <- !duplicated(data.frame(context = index[pairs$is_node],
    document_id = pairs$document_id[pairs$is_node]))
  results <- data.frame(context = terms, observed = observed,
    node_marginal = rep(node_marginal, length(terms)), context_marginal = context_marginal,
    opportunities = rep(total, length(terms)), expected = expected, MI = mi, t_score = t_score,
    documents = tabulate(index[pairs$is_node][node_seen], length(terms)),
    context_documents = tabulate(index[seen], length(terms)),
    meets_min_count = observed >= min_count,
    status = as.character(ifelse(expected == 0, "no_node_opportunities",
      ifelse(observed == 0, "zero_observed", "ok"))), stringsAsFactors = FALSE)
  documents <- search$documents
  ids <- documents$document_id
  documents$node_occurrences <- tabulate(match(hit$document_id, ids), length(ids))
  documents$candidate_slot_pairs <- vapply(ids, function(id)
    sum(potential[segments$document_id == id]), numeric(1))
  documents$eligible_pairs <- tabulate(match(pairs$document_id, ids), length(ids))
  documents$excluded_pairs <- documents$candidate_slot_pairs - documents$eligible_pairs
  documents$node_pairs <- tabulate(match(pairs$document_id[pairs$is_node], ids), length(ids))
  nodes_with_pairs <- unique(pairs$node_row[pairs$is_node])
  documents$nodes_with_context <- tabulate(match(tokens$document_id[nodes_with_pairs], ids), length(ids))
  documents$status <- ifelse(documents$eligible_pairs == 0, "no_eligible_pairs",
    ifelse(documents$node_pairs == 0, "no_node_opportunities", "ok"))
  settings <- list(query_id = query_id, span = span, min_count = min_count, max_pairs = max_pairs,
    opportunities = "ordered-token-pairs-within-supplied-segments-and-original-slot-span",
    eligibility = "both-endpoints-searchable; intervening-slots-do-not-block-or-compress-distance",
    context_identity = "exact-UTF8-selected-terms; no-case-or-Unicode-normalization",
    marginals = "node-matching-pair-rows; context-term-pair-rows; all-eligible-pair-rows",
    expected = "node_marginal * context_marginal / opportunities",
    MI = "log2(observed / expected)", t_score = "(observed - expected) / sqrt(observed)",
    zero_observed = "MI=-Inf when expected>0; t_score=NA", smoothing = "none",
    frequency_threshold = "display-flag-only; full-counts-and-marginals-retained")
  result <- list(results = results, pairs = pairs, documents = documents, search = search,
    settings = settings, provenance = list(recipe_version = "1",
      ldfreq_version = as.character(utils::packageVersion("ldfreq")),
      search_id = search$provenance$search_id))
  result$integrity_sha256 <- .concordance_hash(result)
  result
}

collocation_validate <- function(x) {
  if (!is.list(x) || !identical(x$provenance$recipe_version, "1") ||
      !identical(x$integrity_sha256, .concordance_hash(x[names(x) != "integrity_sha256"])))
    stop("The saved collocation record changed; repeat collocation_profile().", call. = FALSE)
  .concordance_check(x$search)
  invisible(x)
}

lexdiv_collocations <- collocation_profile
