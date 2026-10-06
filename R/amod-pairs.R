# Basic UD feature extraction from a complete, source-checked annotation import.
lexdiv_amod_pairs <- function(annotations, unit = c("surface", "lemma"),
                              context_chars = 30L, max_tokens = 1e6) {
  unit <- match.arg(unit)
  context_chars <- .lexann_context(context_chars)
  max_tokens <- .lexnorm_positive_whole(max_tokens, "max_tokens")
  annotations <- .lexann_validate(annotations, "annotations", max_tokens)
  tokens <- annotations$tokens
  required <- c("head", "deprel", "upos", unit)
  if (!all(required %in% names(tokens)))
    stop("Token annotations require head, deprel, upos and the selected unit column.", call. = FALSE)
  head <- tokens$head
  if (!is.numeric(head) || !is.null(attributes(head)) || any(is.nan(head)))
    stop("head must be a plain numeric vector of sentence-local token indices or NA.", call. = FALSE)
  .lexng_count(head[!is.na(head)], "head")
  for (column in unique(c("deprel", "upos", unit))) {
    value <- tokens[[column]]
    if (!is.character(value) || !is.null(attributes(value)))
      stop(column, " must be a plain character vector; missing values use NA.", call. = FALSE)
    .lexnorm_plain_character(value[!is.na(value)], column, allow_zero = TRUE)
    if (any(!is.na(value) & !nzchar(stringi::stri_trim_both(value))))
      stop(column, " must not contain blank values.", call. = FALSE)
  }
  if (any(!is.na(tokens$upos) & !tokens$upos %in% .lexprep_upos_tags))
    stop("upos must use UD tags or NA; map other tagsets explicitly.", call. = FALSE)
  relations <- c("acl", "advcl", "advmod", "amod", "appos", "aux", "case", "cc",
    "ccomp", "clf", "compound", "conj", "cop", "csubj", "dep", "det", "discourse",
    "dislocated", "expl", "fixed", "flat", "goeswith", "iobj", "list", "mark", "nmod",
    "nsubj", "nummod", "obj", "obl", "orphan", "parataxis", "punct", "reparandum",
    "root", "vocative", "xcomp")
  base_relation <- sub(":.*$", "", tokens$deprel)
  if (any(!is.na(tokens$deprel) &
      (!grepl("^[a-z]+(:[a-z][a-z0-9_]*)?$", tokens$deprel) |
       !base_relation %in% relations | (base_relation == "root" & tokens$deprel != "root"))))
    stop("deprel must use basic UD relations, optional subtypes, or NA.", call. = FALSE)
  for (column in intersect(c("deps", "DEPS"), names(tokens))) {
    value <- tokens[[column]]
    if (!is.character(value) || !is.null(attributes(value)) ||
        any(!is.na(value) & value != "_"))
      stop("Enhanced dependencies are not supported; explicitly supply a basic-tree projection.",
        call. = FALSE)
  }

  keys <- c("document_id", "segment_id")
  segments <- annotations$segments[c(keys, "token_count")]
  group <- match(.lexng_key(tokens[keys]), .lexng_key(segments[keys]))
  rows <- split(seq_len(nrow(tokens)), factor(group, levels = seq_len(nrow(segments))))
  segments$missing_heads <- segments$missing_relations <- segments$missing_upos <- integer(nrow(segments))
  segments$status <- rep("complete", nrow(segments))
  selected <- rep(FALSE, nrow(tokens))
  head_row <- rep(NA_integer_, nrow(tokens))
  for (s in seq_along(rows)) {
    idx <- rows[[s]]
    n <- length(idx)
    if (!n) {
      segments$status[s] <- "empty"
      next
    }
    h <- head[idx]
    rel <- tokens$deprel[idx]
    fail <- function(message) stop(message, " (segment row ", s, ").", call. = FALSE)
    if (any(!is.na(h) & (h > n | h == seq_len(n))))
      fail("Each head must be 0 or a different token in the same sentence")
    paired <- !is.na(h) & !is.na(rel)
    if (any((h[paired] == 0) != (rel[paired] == "root")))
      fail("head = 0 and deprel = root must agree")
    roots <- sum(h == 0, na.rm = TRUE)
    if (roots > 1L || sum(rel == "root", na.rm = TRUE) > 1L ||
        (!anyNA(h) && roots != 1L))
      fail("A complete basic tree must have exactly one root")
    # Linear traversal; even an incomplete annotation may not contain a known cycle.
    state <- integer(n)
    for (v in seq_len(n)) {
      if (state[v]) next
      node <- v
      while (!is.na(node) && node != 0 && state[node] == 0L) {
        state[node] <- 1L
        node <- h[node]
      }
      if (!is.na(node) && node != 0 && state[node] == 1L)
        fail("Basic dependencies contain a cycle")
      node <- v
      while (!is.na(node) && node != 0 && state[node] == 1L) {
        state[node] <- 2L
        node <- h[node]
      }
    }
    segments$missing_heads[s] <- sum(is.na(h))
    segments$missing_relations[s] <- sum(is.na(rel))
    segments$missing_upos[s] <- sum(is.na(tokens$upos[idx]))
    if (anyNA(h) || anyNA(rel) || anyNA(tokens$upos[idx])) {
      segments$status[s] <- "incomplete_annotation"
      next
    }
    nonroot <- h > 0
    head_row[idx[nonroot]] <- idx[h[nonroot]]
    selected[idx] <- base_relation[idx] == "amod" & tokens$upos[idx] == "ADJ" &
      nonroot & tokens$upos[head_row[idx]] %in% "NOUN"
  }

  dependent <- which(selected)
  governor <- head_row[dependent]
  occurrences <- tokens[dependent, keys, drop = FALSE]
  for (side in c("dependent", "head")) {
    idx <- if (side == "dependent") dependent else governor
    for (column in c("token_index", "surface", "upos", "start", "end"))
      occurrences[[paste0(side, "_", column)]] <- tokens[[column]][idx]
    occurrences[[paste0(side, "_term")]] <- tokens[[unit]][idx]
  }
  occurrences$deprel <- tokens$deprel[dependent]
  occurrences$direction <- rep("dependent_before_head", length(dependent))
  occurrences$direction[dependent > governor] <- "dependent_after_head"
  occurrences$token_distance <- abs(tokens$token_index[dependent] - tokens$token_index[governor])
  occurrences$unit_available <- !is.na(occurrences$dependent_term) & !is.na(occurrences$head_term)
  occurrences$start <- pmin(occurrences$dependent_start, occurrences$head_start)
  occurrences$end <- pmax(occurrences$dependent_end, occurrences$head_end)
  source <- annotations$segments$text[group[dependent]]
  occurrences$pre <- stringi::stri_sub(source, pmax(1, occurrences$start - context_chars),
    occurrences$start - 1L)
  occurrences$keyword <- stringi::stri_sub(source, occurrences$start, occurrences$end)
  occurrences$post <- stringi::stri_sub(source, occurrences$end + 1L,
    pmin(stringi::stri_length(source), occurrences$end + context_chars))
  rownames(occurrences) <- NULL

  occurrence_group <- group[dependent]
  segments$observed_pairs <- tabulate(occurrence_group, nbins = nrow(segments))
  segments$pairs <- ifelse(segments$status == "incomplete_annotation", NA_integer_, segments$observed_pairs)
  documents <- data.frame(document_id = annotations$documents$document_id)
  summarize <- function(segment_rows, occurrence_rows) {
    s <- segments[segment_rows, , drop = FALSE]
    o <- occurrences[occurrence_rows, , drop = FALSE]
    complete <- all(s$status != "incomplete_annotation")
    tokens_n <- sum(s$token_count)
    available <- sum(s$token_count[s$status == "complete"])
    observed_types <- sum(!duplicated(.lexng_key(o[o$unit_available,
      c("dependent_term", "head_term"), drop = FALSE])))
    data.frame(segments = nrow(s), nonempty_segments = sum(s$token_count > 0),
      complete_segments = sum(s$status == "complete"),
      incomplete_segments = sum(s$status == "incomplete_annotation"),
      tokens = tokens_n, analyzed_tokens = available,
      token_coverage = if (tokens_n) available / tokens_n else NA_real_,
      observed_pairs = nrow(o), pairs = if (complete) nrow(o) else NA_integer_,
      pairs_with_unit = sum(o$unit_available), observed_types = observed_types,
      types = if (complete && all(o$unit_available)) observed_types else NA_integer_,
      status = if (!complete) "incomplete_annotation" else if (!tokens_n) "empty" else "complete")
  }
  segment_docs <- split(seq_len(nrow(segments)), factor(segments$document_id, levels = documents$document_id))
  occurrence_docs <- split(seq_len(nrow(occurrences)), factor(occurrences$document_id, levels = documents$document_id))
  documents <- cbind(documents, do.call(rbind, lapply(seq_len(nrow(documents)), function(i)
    summarize(segment_docs[[i]], occurrence_docs[[i]]))))
  rownames(documents) <- NULL
  counts <- occurrences[occurrences$unit_available, c("dependent_term", "head_term"), drop = FALSE]
  type_key <- .lexng_key(counts)
  first <- !duplicated(type_key)
  counts <- counts[first, , drop = FALSE]
  counts$n <- tabulate(match(type_key, type_key[first]), nbins = sum(first))
  rownames(counts) <- NULL
  out <- list(occurrences = occurrences, counts = counts, segments = segments,
    documents = documents, summary = summarize(seq_len(nrow(segments)), seq_len(nrow(occurrences))),
    annotations = annotations,
    provenance = list(extractor = "ldfreq-amod-pairs", extractor_version = "0.1.0",
      feature = "basic UD amod (including subtypes); dependent ADJ; head NOUN",
      unit = unit, normalization = "none", context_chars = context_chars,
      missing_policy = "exclude entire sentence if head/deprel/UPOS is missing; document totals then unavailable",
      types = "ordered dependent/head terms; exact case-sensitive matching; counts condition on available units",
      coordinates = annotations$provenance$coordinates,
      scope = "one sentence per segment; basic source-aligned syntactic words only; no enhanced dependencies or inference"))
  out$provenance$content_sha256 <- .lexng_hash(out)
  out
}
