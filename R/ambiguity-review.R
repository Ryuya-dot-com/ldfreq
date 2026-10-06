# Review supplied lexical candidates at source-verified token occurrences.
# Search and KWIC formatting belong to quanteda; no meaning is inferred here.
lexdiv_ambiguity_review <- function(x, targets, candidates, resource,
                                    decisions = NULL, window = 5, max_tokens = 1e6) {
  x <- .lexnorm_plain_list(x, "x")
  if (!all(c("tokens", "segments", "provenance") %in% names(x)) ||
      !is.list(x$provenance) ||
      !identical(x$provenance$importer, "ldfreq-external-annotations"))
    stop("x must be an unmodified lexdiv_import_annotations() result.", call. = FALSE)
  segments <- .lexnorm_plain_data_frame(x$segments, "x$segments")
  checked <- lexdiv_import_annotations(x$tokens,
    segments[setdiff(names(segments), c("token_count", "text_sha256"))],
    x$provenance$annotation, max_tokens = max_tokens)
  if (!identical(x, checked))
    stop("x has changed; import the complete annotations again before review.", call. = FALSE)
  targets <- unique(.lexnorm_plain_character(targets, "targets"))
  if (any(stringi::stri_detect_regex(targets, "\\p{White_Space}")))
    stop("targets must be single-token surface forms without whitespace.", call. = FALSE)
  window <- .lexng_count(window, "window")
  if (length(window) != 1L || window > .Machine$integer.max)
    stop("window must be one non-negative whole number within the integer range.", call. = FALSE)
  candidates <- .lexnorm_plain_data_frame(candidates, "candidates")
  fields <- c("term", "candidate_id", "label")
  if (!all(fields %in% names(candidates)))
    stop("candidates requires term, candidate_id and label columns.", call. = FALSE)
  for (field in fields)
    candidates[[field]] <- .lexnorm_plain_character(candidates[[field]],
      paste0("candidates$", field), allow_zero = TRUE)
  if (any(!candidates$term %in% targets) ||
      anyDuplicated(.lexng_key(candidates[c("term", "candidate_id")])))
    stop("Candidate term/ID pairs must be unique and terms must occur in targets.", call. = FALSE)
  # Canonical candidate order makes review identity independent of display order.
  candidates <- candidates[order(candidates$term, candidates$candidate_id,
    method = "radix"), , drop = FALSE]
  rownames(candidates) <- NULL
  resource <- .lexnorm_plain_list(resource, "resource")
  required <- c("resource_id", "resource_version", "source_reference", "data_license")
  if (!all(required %in% names(resource)))
    stop("resource requires resource_id, resource_version, source_reference and data_license.",
      call. = FALSE)
  resource <- resource[c(required, sort(setdiff(names(resource), required), method = "radix"))]
  for (field in names(resource))
    resource[[field]] <- .lexnorm_scalar_string(resource[[field]], paste0("resource$", field))

  review_id <- digest::digest(list("ldfreq-ambiguity-review-0.1.0",
    x$provenance$input_sha256, sort(targets, method = "radix"), candidates, resource),
    algo = "sha256", serializeVersion = 2L)
  reserved <- c("review_id", "occurrence_id", "pre", "keyword", "post", "segment_text",
    "candidate_count", "status", "candidate_id", "reviewer", "reason")
  if (any(reserved %in% names(x$tokens)))
    stop("Token columns conflict with reserved review output names: ",
      paste(intersect(reserved, names(x$tokens)), collapse = ", "), call. = FALSE)
  # Whitespace-only annotations occupy their original slots as padding.
  data <- x$tokens[!stringi::stri_detect_regex(x$tokens$surface, "^\\p{White_Space}+$"), ]
  q <- lexdiv_as_quanteda(data, x$segments, max_tokens = max_tokens)
  kw <- as.data.frame(quanteda::kwic(q$tokens, targets, window = window,
    valuetype = "fixed", case_insensitive = FALSE))
  hit_key <- .lexng_key(kw[c("docname", "from")])
  row <- match(hit_key, .lexng_key(q$positions[c("quanteda_docname", "token_index")]))
  if (anyNA(row) || any(kw$from != kw$to))
    stop("KWIC hits did not preserve the expected single-token source positions.", call. = FALSE)
  # quanteda fixed matching may identify canonically equivalent Unicode forms.
  # Keep only hits whose original surface equals the unnormalized query.
  exact <- q$positions$surface[row] == as.character(kw$pattern)
  row <- row[exact]; kw <- kw[exact, , drop = FALSE]
  if (anyDuplicated(row) || any(kw$keyword != q$positions$surface[row]) ||
      !setequal(row, which(q$positions$surface %in% targets)))
    stop("KWIC hits did not preserve the expected single-token source positions.", call. = FALSE)
  hit_order <- order(row)
  row <- row[hit_order]; kw <- kw[hit_order, , drop = FALSE]
  occurrences <- q$positions[row, setdiff(names(q$positions), "quanteda_docname"), drop = FALSE]
  group <- match(.lexng_key(occurrences[c("document_id", "segment_id")]),
    .lexng_key(x$segments[c("document_id", "segment_id")]))
  identities <- .lexng_key(data.frame(occurrences[c("document_id", "segment_id", "token_index",
    "start", "end")], text_sha256 = x$segments$text_sha256[group]))
  occurrences$occurrence_id <- vapply(identities, digest::digest, character(1),
    algo = "sha256", serialize = FALSE, USE.NAMES = FALSE)
  occurrences$review_id <- rep(review_id, nrow(occurrences))
  occurrences[c("pre", "keyword", "post")] <- kw[c("pre", "keyword", "post")]
  occurrences$segment_text <- x$segments$text[group]
  counts <- tabulate(match(candidates$term, targets), nbins = length(targets))
  occurrences$candidate_count <- counts[match(occurrences$surface, targets)]
  occurrences$status <- ifelse(occurrences$candidate_count == 0L, "no_candidates", "unreviewed")
  for (field in c("candidate_id", "reviewer", "reason"))
    occurrences[[field]] <- rep(NA_character_, nrow(occurrences))
  rownames(occurrences) <- NULL

  if (is.null(decisions)) {
    decisions <- data.frame(review_id = character(), occurrence_id = character(),
      status = character(), candidate_id = character(), reviewer = character(), reason = character())
  }
  decisions <- .lexnorm_plain_data_frame(decisions, "decisions")
  required <- c("review_id", "occurrence_id", "status", "candidate_id", "reviewer", "reason")
  if (!all(required %in% names(decisions)))
    stop("decisions requires: ", paste(required, collapse = ", "), ".", call. = FALSE)
  for (field in setdiff(required, "candidate_id")) {
    decisions[[field]] <- .lexnorm_plain_character(decisions[[field]],
      paste0("decisions$", field), allow_zero = TRUE)
    if (any(!nzchar(stringi::stri_trim_both(decisions[[field]]))))
      stop("Decision fields must not contain blank-only strings.", call. = FALSE)
  }
  if (!is.character(decisions$candidate_id) || !is.null(attributes(decisions$candidate_id)))
    stop("decisions$candidate_id must be a plain character vector; unresolved uses NA.", call. = FALSE)
  supplied <- !is.na(decisions$candidate_id)
  decisions$candidate_id[supplied] <- .lexnorm_plain_character(decisions$candidate_id[supplied],
    "decisions$candidate_id", allow_zero = TRUE)
  if (any(decisions$review_id != review_id))
    stop("Decision review_id differs: source, targets, candidates or resource changed.", call. = FALSE)
  decision_row <- match(decisions$occurrence_id, occurrences$occurrence_id)
  if (anyNA(decision_row) || anyDuplicated(decision_row))
    stop("Decisions must identify unique, existing occurrences.", call. = FALSE)
  selected <- decisions$status == "selected"
  if (any(!decisions$status %in% c("selected", "unresolved")) || any(selected != supplied))
    stop("Use status selected with a candidate_id, or unresolved with candidate_id = NA.", call. = FALSE)
  selected_keys <- .lexng_key(data.frame(term = occurrences$surface[decision_row[selected]],
    candidate_id = decisions$candidate_id[selected]))
  if (any(!selected_keys %in% .lexng_key(candidates[c("term", "candidate_id")])))
    stop("A selected candidate_id is not a candidate for that occurrence's surface.", call. = FALSE)
  for (field in c("status", "candidate_id", "reviewer", "reason"))
    occurrences[[field]][decision_row] <- decisions[[field]]
  summary <- data.frame(term = targets, candidate_count = counts,
    occurrences = tabulate(match(occurrences$surface, targets), nbins = length(targets)))
  for (status in c("unreviewed", "selected", "unresolved", "no_candidates"))
    summary[[status]] <- tabulate(match(occurrences$surface[occurrences$status == status], targets),
      nbins = length(targets))
  out <- list(occurrences = occurrences, candidates = candidates, decisions = decisions, summary = summary,
    source = x, provenance = list(review = "ldfreq-ambiguity-review", review_version = "0.1.0",
      review_id = review_id, resource = resource, kwic = q$provenance, window = window,
      matching = "exact case-sensitive surface; no normalization",
      context = "quanteda token window within segment; original segment text retained",
      selection_validation = "source identity and candidate membership only; no sense inference"))
  out$provenance$content_sha256 <- .lexng_hash(out)
  out
}

.lexamb_validate_review <- function(x) {
    if (!is.list(x) || !is.list(x$provenance) ||
        !identical(x$provenance$review, "ldfreq-ambiguity-review") ||
        !identical(x$provenance$review_version, "0.1.0") ||
        !identical(x$provenance$content_sha256, .lexng_hash(x)))
      stop("Use unmodified lexdiv_ambiguity_review() results with content fingerprints; regenerate older reviews.",
        call. = FALSE)
  invisible(x)
}

# Compare complete saved reviews without searching or changing decisions again.
lexdiv_compare_ambiguity <- function(a, b) {
  .lexamb_validate_review(a)
  .lexamb_validate_review(b)
  if (!identical(a$provenance$review_id, b$provenance$review_id))
    stop("Reviews must use the same source annotations, targets, candidates and resource snapshot.", call. = FALSE)
  ids <- a$occurrences$occurrence_id
  paired_row <- match(ids, b$occurrences$occurrence_id)
  if (anyNA(paired_row) || anyDuplicated(ids) || anyDuplicated(paired_row) ||
      length(ids) != nrow(b$occurrences))
    stop("Reviews must contain the same unique occurrence IDs.", call. = FALSE)
  pairs <- a$occurrences[c("occurrence_id", "document_id", "segment_id", "token_index",
    "start", "end", "surface", "segment_text", "candidate_count")]
  columns <- c("pre", "post", "status", "candidate_id", "reviewer", "reason")
  pairs[paste0("a_", columns)] <- a$occurrences[columns]
  pairs[paste0("b_", columns)] <- b$occurrences[paired_row, columns, drop = FALSE]
  selected_a <- pairs$a_status == "selected"
  selected_b <- pairs$b_status == "selected"
  both <- selected_a & selected_b
  pairs$same_candidate <- rep(NA, nrow(pairs))
  pairs$same_candidate[both] <- pairs$a_candidate_id[both] == pairs$b_candidate_id[both]
  pairs$outcome <- rep("neither_selected", nrow(pairs))
  pairs$outcome[selected_a & !selected_b] <- "selected_a_only"
  pairs$outcome[!selected_a & selected_b] <- "selected_b_only"
  pairs$outcome[both] <- ifelse(pairs$same_candidate[both], "agreement", "disagreement")
  outcomes <- c("agreement", "disagreement", "selected_a_only", "selected_b_only", "neither_selected")
  summarize <- function(rows) {
    p <- pairs[rows, , drop = FALSE]
    reviewed_a <- p$a_status %in% c("selected", "unresolved")
    reviewed_b <- p$b_status %in% c("selected", "unresolved")
    joint <- sum(p$a_status == "selected" & p$b_status == "selected")
    out <- data.frame(occurrences = nrow(p), no_candidates = sum(p$candidate_count == 0L),
      a_reviewed = sum(reviewed_a), b_reviewed = sum(reviewed_b),
      both_reviewed = sum(reviewed_a & reviewed_b), both_selected = joint)
    for (outcome in outcomes) out[[outcome]] <- sum(p$outcome == outcome)
    out$both_selected_proportion <- if (nrow(p)) joint / nrow(p) else NA_real_
    out$agreement_among_both_selected <- if (joint) out$agreement / joint else NA_real_
    out
  }
  targets <- a$summary$term
  rows <- split(seq_len(nrow(pairs)), factor(match(pairs$surface, targets),
    levels = seq_along(targets)))
  terms <- cbind(data.frame(term = targets), do.call(rbind, lapply(rows, summarize)))
  rownames(terms) <- NULL
  status_pairs <- pairs[c("surface", "a_status", "b_status")]
  names(status_pairs)[1] <- "term"
  keys <- .lexng_key(status_pairs)
  counts <- tabulate(match(keys, unique(keys)), nbins = length(unique(keys)))
  status_pairs <- status_pairs[!duplicated(keys), , drop = FALSE]
  status_pairs$count <- counts
  rownames(status_pairs) <- NULL
  list(summary = summarize(seq_len(nrow(pairs))), terms = terms,
    pairs = pairs, review_queue = pairs[pairs$outcome != "agreement", , drop = FALSE],
    status_pairs = status_pairs, reviews = list(a = a, b = b),
    provenance = list(comparison = "ldfreq-ambiguity-comparison", comparison_version = "0.1.0",
      review_id = a$provenance$review_id, pairing = "exact occurrence ID",
      agreement_denominator = "occurrences with a selected candidate in both reviews",
      missing_policy = "unresolved, unreviewed and no_candidates are not semantic agreements",
      interpretation = "descriptive selection agreement; no accuracy, independence or reliability claim"))
}
