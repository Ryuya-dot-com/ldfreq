# Descriptive comparison to an explicit reference, without changing judgments.
lexdiv_evaluate_contextual <- function(x, reference, direction, reference_info,
                                      tie_tolerance = 0) {
  if (!is.list(x) || !is.list(x$provenance) ||
      !identical(x$provenance$importer, "ldfreq-contextual-output") ||
      !identical(x$provenance$importer_version, "0.1.0") ||
      !identical(x$provenance$content_sha256, .lexng_hash(x)))
    stop("x must be an unmodified lexdiv_import_contextual() result.", call. = FALSE)
  .lexamb_validate_review(reference)
  if (!identical(x$provenance$review_id, reference$provenance$review_id))
    stop("Model output and reference must use the same source, targets, candidates and resource snapshot.",
      call. = FALSE)
  direction <- .lexnorm_scalar_string(direction, "direction")
  if (!direction %in% c("higher", "lower"))
    stop("direction must explicitly be higher or lower.", call. = FALSE)
  if (!is.numeric(tie_tolerance) || !is.null(attributes(tie_tolerance)) ||
      length(tie_tolerance) != 1L || !is.finite(tie_tolerance) || tie_tolerance < 0)
    stop("tie_tolerance must be one finite non-negative number.", call. = FALSE)
  reference_info <- .lexnorm_plain_list(reference_info, "reference_info")
  required <- c("reference_id", "annotation_protocol", "model_exposure", "evaluation_role")
  if (!all(required %in% names(reference_info)))
    stop("reference_info requires: ", paste(required, collapse = ", "), ".", call. = FALSE)
  for (field in names(reference_info)) {
    reference_info[[field]] <- .lexnorm_scalar_string(reference_info[[field]], field)
    if (!nzchar(stringi::stri_trim_both(reference_info[[field]])))
      stop("Reference declarations must not be blank.", call. = FALSE)
  }
  if (!reference_info$model_exposure %in% c("not_shown", "shown", "unknown") ||
      !reference_info$evaluation_role %in% c("held_out", "development", "unknown"))
    stop("Use model_exposure not_shown/shown/unknown and evaluation_role held_out/development/unknown.",
      call. = FALSE)
  o <- x$occurrences
  row <- match(o$occurrence_id, reference$occurrences$occurrence_id)
  if (anyNA(row) || anyDuplicated(row) || length(row) != nrow(reference$occurrences))
    stop("Model output and reference must contain the same unique occurrences.", call. = FALSE)
  pairs <- o[c("occurrence_id", "document_id", "segment_id", "token_index", "surface",
    "start", "end", "pre", "keyword", "post", "segment_text", "candidate_count",
    "model_status", "model_reason", "n_suggestions")]
  fields <- c("status", "candidate_id", "reviewer", "reason")
  pairs[paste0("reference_", fields)] <- reference$occurrences[row, fields, drop = FALSE]
  pairs$prediction_status <- rep("no_scores", nrow(o))
  pairs$prediction_status[o$candidate_count == 0L] <- "no_candidates"
  pairs$predicted_candidate_id <- rep(NA_character_, nrow(o))
  pairs$best_score <- rep(NA_real_, nrow(o))
  pairs$best_count <- integer(nrow(o))
  # Split once; candidate IDs are scoped to the surface, never pooled across words.
  s <- x$suggestions
  groups <- split(seq_len(nrow(s)), factor(match(s$occurrence_id, o$occurrence_id),
    levels = seq_len(nrow(o))))
  for (i in seq_len(nrow(o))) {
    idx <- groups[[i]]
    if (!length(idx)) next
    scores <- s$score[idx]
    best <- if (direction == "higher") max(scores) else min(scores)
    at_best <- abs(scores - best) <= tie_tolerance
    pairs$best_score[i] <- best
    pairs$best_count[i] <- sum(at_best)
    if (length(idx) != o$candidate_count[i]) {
      pairs$prediction_status[i] <- "incomplete_scores"
    } else if (sum(at_best) != 1L) {
      pairs$prediction_status[i] <- "tied_best"
    } else {
      pairs$prediction_status[i] <- "unique_best"
      pairs$predicted_candidate_id[i] <- s$candidate_id[idx[at_best]]
    }
  }
  predicted <- pairs$prediction_status == "unique_best"
  selected <- pairs$reference_status == "selected"
  paired <- predicted & selected
  pairs$matches_reference <- rep(NA, nrow(pairs))
  pairs$matches_reference[paired] <- pairs$predicted_candidate_id[paired] ==
    pairs$reference_candidate_id[paired]
  pairs$reference_scored <- rep(NA, nrow(pairs))
  pairs$reference_scored[selected] <- .lexng_key(data.frame(
    occurrence_id = pairs$occurrence_id[selected], candidate_id = pairs$reference_candidate_id[selected])) %in%
    .lexng_key(s[c("occurrence_id", "candidate_id")])
  pairs$outcome <- rep("neither_available", nrow(pairs))
  pairs$outcome[predicted & !selected] <- "prediction_only"
  pairs$outcome[!predicted & selected] <- "reference_only"
  pairs$outcome[paired] <- ifelse(pairs$matches_reference[paired], "agreement", "disagreement")
  summarize <- function(rows) {
    p <- pairs[rows, , drop = FALSE]
    n <- nrow(p)
    out <- data.frame(occurrences = n, reference_selected = sum(p$reference_status == "selected"),
      predictions = sum(p$prediction_status == "unique_best"), paired = sum(!is.na(p$matches_reference)),
      reference_without_score = sum(p$reference_scored %in% FALSE),
      single_candidate_predictions = sum(p$prediction_status == "unique_best" & p$candidate_count == 1L))
    for (status in c("no_candidates", "no_scores", "incomplete_scores", "tied_best"))
      out[[status]] <- sum(p$prediction_status == status)
    for (outcome in c("agreement", "disagreement", "reference_only", "prediction_only", "neither_available"))
      out[[outcome]] <- sum(p$outcome == outcome)
    out$prediction_coverage <- if (n) out$predictions / n else NA_real_
    out$reference_coverage <- if (n) out$reference_selected / n else NA_real_
    out$paired_coverage <- if (n) out$paired / n else NA_real_
    out$agreement_among_paired <- if (out$paired) out$agreement / out$paired else NA_real_
    out$matches_among_reference_selected <- if (out$reference_selected)
      out$agreement / out$reference_selected else NA_real_
    out
  }
  targets <- x$review$summary$term
  rows <- split(seq_len(nrow(pairs)), factor(match(pairs$surface, targets), levels = seq_along(targets)))
  terms <- cbind(data.frame(term = targets), do.call(rbind, lapply(rows, summarize)))
  rownames(terms) <- NULL
  confusion <- pairs[paired, c("surface", "reference_candidate_id", "predicted_candidate_id"), drop = FALSE]
  names(confusion)[1L] <- "term"
  keys <- .lexng_key(confusion)
  counts <- tabulate(match(keys, unique(keys)), nbins = length(unique(keys)))
  confusion <- confusion[!duplicated(keys), , drop = FALSE]
  confusion$n <- counts
  rownames(confusion) <- NULL
  out <- list(summary = summarize(seq_len(nrow(pairs))), terms = terms, pairs = pairs,
    confusion = confusion, review_queue = pairs[pairs$outcome != "agreement", , drop = FALSE],
    model_output = x, reference = reference,
    provenance = list(evaluator = "ldfreq-contextual-evaluation", evaluator_version = "0.1.0",
      direction = direction, tie_tolerance = tie_tolerance, reference_info = reference_info,
      prediction_policy = "unique best within tolerance, only when every supplied inventory candidate is scored",
      weighting = "occurrences; pooled proportions are not word-level macro averages",
      interpretation = "descriptive reference agreement; independence, reference validity and holdout are caller declarations"))
  out$provenance$content_sha256 <- .lexng_hash(out)
  out
}
