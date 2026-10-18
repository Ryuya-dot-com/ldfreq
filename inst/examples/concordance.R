# Source explicitly: these are example helpers, not exported package functions.
.concordance_hash <- function(x) {
  digest::digest(x, algo = "sha256", serializeVersion = 2L)
}

.concordance_check <- function(x) {
  if (!is.list(x) || !identical(x$provenance$recipe_version, "1") ||
      !identical(x$integrity_sha256, .concordance_hash(x[names(x) != "integrity_sha256"])))
    stop("The saved concordance changed; repeat concordance_search() from its source.",
      call. = FALSE)
  invisible(x)
}

.concordance_whole <- function(x, name, minimum = 1) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) ||
      x < minimum || x != floor(x) || x > .Machine$integer.max)
    stop(name, " must be a whole number >= ", minimum, ".", call. = FALSE)
  as.integer(x)
}

concordance_search <- function(x, queries, term_col = "surface",
    valuetype = c("fixed", "glob", "regex"), case_insensitive = FALSE,
    keep = rep(TRUE, nrow(x$tokens)), window = 5L, max_cells = 1e6) {
  valuetype <- match.arg(valuetype)
  window <- .concordance_whole(window, "window", 0)
  max_cells <- .concordance_whole(max_cells, "max_cells")
  if (!is.list(x) || !identical(x$provenance$importer, "ldfreq-external-annotations"))
    stop("Supply an unchanged lexdiv_import_annotations() result.", call. = FALSE)
  checked <- ldfreq::lexdiv_import_annotations(x$tokens,
    x$segments[setdiff(names(x$segments), c("token_count", "text_sha256"))],
    x$provenance$annotation, max_tokens = max_cells)
  if (!identical(x, checked))
    stop("Source annotations changed; import the complete source again.", call. = FALSE)
  strings <- function(z) is.character(z) && length(z) > 0L && !anyNA(z) &&
    all(validUTF8(z)) && all(nzchar(stringi::stri_trim_both(z)))
  if (!is.list(queries) || !length(queries) || !strings(names(queries)) ||
      anyDuplicated(names(queries)) || !all(vapply(queries, strings, logical(1))))
    stop("queries must be a named list of nonblank token-pattern vectors with unique IDs.",
      call. = FALSE)
  if (!is.logical(case_insensitive) || length(case_insensitive) != 1L ||
      is.na(case_insensitive)) stop("case_insensitive must be TRUE or FALSE.", call. = FALSE)
  if (!is.logical(keep) || length(keep) != nrow(x$tokens) || anyNA(keep))
    stop("keep must have one non-missing logical value per original token.", call. = FALSE)
  if (!is.character(term_col) || length(term_col) != 1L || is.na(term_col) ||
      !term_col %in% names(x$tokens) || !is.character(x$tokens[[term_col]]))
    stop("term_col must name a character column in the source tokens.", call. = FALSE)
  term <- x$tokens[[term_col]]
  if (any(!validUTF8(term[!is.na(term)])))
    stop("Search terms must be valid UTF-8.", call. = FALSE)
  available <- !is.na(term) & nzchar(stringi::stri_trim_both(term))
  searchable <- keep & available
  q <- ldfreq::lexdiv_as_quanteda(x$tokens[searchable, , drop = FALSE],
    x$segments, term_col = term_col, max_tokens = max_cells)
  ids <- x$documents$document_id
  if (as.double(length(ids)) * length(queries) > max_cells)
    stop("Document-query count cells exceed max_cells.", call. = FALSE)
  seg <- x$segments
  offset <- c(0, head(cumsum(seg$token_count), -1L))
  doc_group <- match(seg$document_id, ids)
  doc_offset <- numeric(nrow(seg))
  for (i in seq_along(ids)) {
    idx <- which(doc_group == i)
    doc_offset[idx] <- c(0, head(cumsum(seg$token_count[idx]), -1L))
  }
  pieces <- vector("list", length(queries))
  total <- 0
  for (i in seq_along(queries)) {
    kw <- as.data.frame(quanteda::kwic(q$tokens, unname(queries[i]),
      window = 0L, valuetype = valuetype, case_insensitive = case_insensitive))
    group <- match(kw$docname, q$segments$quanteda_docname)
    if (anyNA(group) || any(kw$from < 1 | kw$to > seg$token_count[group]) ||
        any(kw$to - kw$from + 1L != length(queries[[i]])))
      stop("Search results do not match the original segment positions.", call. = FALSE)
    index <- order(group, kw$from, kw$to)
    kw <- kw[index, , drop = FALSE]; group <- group[index]
    first <- offset[group] + kw$from; last <- offset[group] + kw$to
    # A wildcard that can match padding must never bridge an excluded token.
    eligible <- vapply(seq_len(nrow(kw)), function(j)
      all(searchable[seq.int(first[j], last[j])]), logical(1))
    kw <- kw[eligible, , drop = FALSE]; group <- group[eligible]
    first <- first[eligible]; last <- last[eligible]
    total <- total + nrow(kw)
    if (total * (1 + 2 * as.double(window)) > max_cells)
      stop("Stored matches and context cells exceed max_cells; reduce the window or queries.",
        call. = FALSE)
    start <- x$tokens$start[first]; end <- x$tokens$end[last]
    left <- offset[group] + pmax(1, kw$from - window)
    right <- offset[group] + pmin(seg$token_count[group], kw$to + window)
    text <- seg$text[group]
    hit <- data.frame(query_id = rep(names(queries)[i], nrow(kw)),
      document_id = seg$document_id[group], segment_id = seg$segment_id[group],
      from = kw$from, to = kw$to, document_from = doc_offset[group] + kw$from,
      document_to = doc_offset[group] + kw$to, start = start, end = end,
      pre = if (window == 0L) rep("", nrow(kw)) else
        stringi::stri_sub(text, x$tokens$start[left], start - 1L),
      keyword = stringi::stri_sub(text, start, end),
      post = if (window == 0L) rep("", nrow(kw)) else
        stringi::stri_sub(text, end + 1L, x$tokens$end[right]),
      stringsAsFactors = FALSE)
    hit$matched_terms <- lapply(seq_len(nrow(hit)), function(j) term[seq.int(first[j], last[j])])
    hit$left_tokens <- lapply(seq_len(nrow(hit)), function(j)
      if (first[j] > left[j]) rev(x$tokens$surface[seq.int(left[j], first[j] - 1L)]) else character())
    hit$right_tokens <- lapply(seq_len(nrow(hit)), function(j)
      if (last[j] < right[j]) x$tokens$surface[seq.int(last[j] + 1L, right[j])] else character())
    pieces[[i]] <- hit
  }
  hits <- do.call(rbind, pieces); rownames(hits) <- NULL
  token_doc <- match(x$tokens$document_id, ids)
  documents <- data.frame(document_id = ids,
    source_tokens = tabulate(token_doc, length(ids)),
    kept_tokens = tabulate(token_doc[keep], length(ids)),
    searchable_tokens = tabulate(token_doc[searchable], length(ids)),
    missing_terms = tabulate(token_doc[keep & !available], length(ids)))
  counts <- expand.grid(document_id = ids, query_id = names(queries),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  cell <- match(hits$document_id, ids) +
    (match(hits$query_id, names(queries)) - 1L) * length(ids)
  counts$occurrences <- tabulate(cell, nrow(counts))
  settings <- list(term_col = term_col, valuetype = valuetype,
    case_insensitive = case_insensitive, keep = keep, searchable = searchable,
    window = window, max_cells = max_cells,
    matching = "quanteda-token-patterns; no-cross-segment-or-excluded-slot-match",
    context = "original-surface-token-slots; nearest-first-token-vectors",
    document_positions = "original-token-slots-in-supplied-segment-order",
    source_coordinates = "segment-local-1-based-inclusive-Unicode-codepoints")
  provenance <- list(recipe_version = "1",
    ldfreq_version = as.character(utils::packageVersion("ldfreq")),
    quanteda_version = as.character(utils::packageVersion("quanteda")),
    stringi_version = as.character(utils::packageVersion("stringi")),
    unicode = stringi::stri_info()[c("ICU.version", "Unicode.version")],
    search_id = .concordance_hash(list(x$provenance, queries, settings)))
  hits$occurrence_id <- vapply(seq_len(nrow(hits)), function(i)
    .concordance_hash(list(provenance$search_id, hits[i,
      c("query_id", "document_id", "segment_id", "from", "to")])), character(1))
  result <- list(occurrences = hits, counts = counts, documents = documents,
    source = x, queries = queries, settings = settings, provenance = provenance)
  result$integrity_sha256 <- .concordance_hash(result)
  result
}

concordance_sort <- function(x, side = c("right", "left"), depth = 1L,
    ignore_case = FALSE) {
  .concordance_check(x)
  side <- match.arg(side); depth <- .concordance_whole(depth, "depth")
  if (depth > x$settings$window)
    stop("depth exceeds the saved context window; repeat the search with a larger window.",
      call. = FALSE)
  if (!is.logical(ignore_case) || length(ignore_case) != 1L || is.na(ignore_case))
    stop("ignore_case must be TRUE or FALSE.", call. = FALSE)
  hits <- x$occurrences
  context <- hits[[paste0(side, "_tokens")]]
  keys <- lapply(seq_len(depth), function(j) {
    value <- vapply(context, function(z) if (length(z) >= j) z[j] else NA_character_, "")
    if (ignore_case) value <- stringi::stri_trans_casefold(value)
    enc2utf8(value)
  })
  # Radix character order is reproducible across locales; absent context sorts last.
  index <- do.call(order, c(keys, list(seq_len(nrow(hits)), na.last = TRUE, method = "radix")))
  hits <- hits[index, , drop = FALSE]; rownames(hits) <- NULL
  hits
}

concordance_positions <- function(x, query_id, relative = TRUE, monochrome = FALSE) {
  .concordance_check(x)
  if (!is.character(query_id) || length(query_id) != 1L || is.na(query_id) ||
      !query_id %in% names(x$queries)) stop("Choose one saved query_id.", call. = FALSE)
  for (flag in list(relative, monochrome)) if (!is.logical(flag) ||
      length(flag) != 1L || is.na(flag)) stop("Plot options must be TRUE or FALSE.", call. = FALSE)
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Install the optional ggplot2 package to draw positions.", call. = FALSE)
  hits <- x$occurrences[x$occurrences$query_id == query_id, , drop = FALSE]
  docs <- x$documents
  count <- x$counts[x$counts$query_id == query_id, ]
  ids <- docs$document_id
  docs$document <- factor(ids, levels = rev(ids))
  hits$document <- factor(hits$document_id, levels = rev(ids))
  n <- docs$source_tokens[match(hits$document_id, ids)]
  hits$position_from <- if (relative) (hits$document_from - 0.5) / n else hits$document_from
  hits$position_to <- if (relative) (hits$document_to - 0.5) / n else hits$document_to
  docs$axis_end <- if (relative) as.numeric(docs$source_tokens > 0) else docs$source_tokens
  colour <- if (monochrome) "black" else "#0072B2"
  p <- ggplot2::ggplot(hits, ggplot2::aes(x = position_from, y = document)) +
    ggplot2::geom_segment(data = docs,
      ggplot2::aes(x = 0, xend = axis_end, y = document, yend = document),
      inherit.aes = FALSE, colour = "grey75") +
    ggplot2::geom_segment(ggplot2::aes(xend = position_to, yend = document),
      colour = colour, linewidth = 0.7) +
    ggplot2::geom_point(colour = colour, shape = 3, size = 2) +
    ggplot2::scale_y_discrete(drop = FALSE, labels = stats::setNames(
      paste0(ids, " [", count$occurrences, " matches; ", docs$source_tokens, " tokens]"), ids)) +
    ggplot2::labs(x = if (relative) "Relative position in original token slots" else
      "Original token position in document", y = NULL) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank())
  if (relative) p <- p + ggplot2::scale_x_continuous(limits = c(0, 1))
  p
}

concordance_dispersion <- function(x, query_id, parts = 10L, max_cells = 1e6) {
  .concordance_check(x)
  parts <- .concordance_whole(parts, "parts", 2)
  max_cells <- .concordance_whole(max_cells, "max_cells")
  if (!is.character(query_id) || length(query_id) != 1L || is.na(query_id) ||
      !query_id %in% names(x$queries)) stop("Choose one saved query_id.", call. = FALSE)
  if (length(x$queries[[query_id]]) != 1L)
    stop("DP in this recipe is defined for single-token queries; use the position plot for phrases.",
      call. = FALSE)
  docs <- x$documents
  if (as.double(nrow(docs)) * parts > max_cells)
    stop("Document-part cells exceed max_cells.", call. = FALSE)
  hits <- x$occurrences[x$occurrences$query_id == query_id, , drop = FALSE]
  token_doc <- match(x$source$tokens$document_id, docs$document_id)
  tables <- vector("list", nrow(docs)); summary <- vector("list", nrow(docs))
  for (i in seq_len(nrow(docs))) {
    n <- docs$source_tokens[i]
    # The same original slots define the graph and the fixed within-document bins.
    bins <- if (n) as.integer(floor((seq_len(n) - 1) * as.double(parts) / n) + 1L) else integer()
    selected <- x$settings$searchable[token_doc == i]
    position <- hits$document_from[hits$document_id == docs$document_id[i]]
    count <- tabulate(bins[position], parts)
    exposure <- tabulate(bins[selected], parts)
    total <- sum(count); denominator <- sum(exposure)
    expected <- if (denominator) exposure / denominator else rep(NA_real_, parts)
    observed <- if (total) count / total else rep(NA_real_, parts)
    reason <- if (!denominator) "no_searchable_tokens" else if (!total) "no_matches" else
      if (sum(exposure > 0) < 2L) "fewer_than_two_nonempty_parts" else NA_character_
    dp <- if (is.na(reason)) sum(abs(observed - expected)) / 2 else NA_real_
    size <- tabulate(bins, parts)
    tables[[i]] <- data.frame(document_id = docs$document_id[i], query_id = query_id,
      part = seq_len(parts),
      source_from = ifelse(size > 0, cumsum(size) - size + 1, NA_real_),
      source_to = ifelse(size > 0, cumsum(size), NA_real_), source_tokens = size,
      searchable_tokens = exposure, occurrences = count,
      expected_share = expected, observed_share = observed)
    summary[[i]] <- data.frame(document_id = docs$document_id[i], query_id = query_id,
      source_tokens = n, searchable_tokens = denominator, occurrences = total,
      parts = parts, nonempty_parts = sum(exposure > 0),
      DP = dp, status = if (is.na(reason)) "ok" else "missing", missing_reason = reason)
  }
  list(documents = do.call(rbind, summary), parts = do.call(rbind, tables),
    occurrence_ids = hits$occurrence_id,
    settings = list(measure = "DP", normalization = "none",
      partition = "floor((original_position-1)*parts/source_tokens)+1",
      parts = parts, expected = "searchable-token-share-in-each-part",
      scope = "within-document; single-token-query",
      reference = "https://doi.org/10.1075/ijcl.13.4.02gri"),
    search_id = x$provenance$search_id)
}
