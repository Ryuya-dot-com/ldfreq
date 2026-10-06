# Single-label evaluation on a complete, common source segmentation.
lexdiv_evaluate_annotations <- function(predicted, reference, column, labels,
                                        reference_info, context_chars = 30L,
                                        max_tokens = 1e6) {
  max_tokens <- .lexnorm_positive_whole(max_tokens, "max_tokens")
  policy <- .lexann_policy(column, labels, reference_info)
  column <- policy$column
  labels <- policy$labels
  reference_info <- policy$reference_info
  context_chars <- .lexann_context(context_chars)
  predicted <- .lexann_validate(predicted, "predicted", max_tokens, column, labels)
  reference <- .lexann_validate(reference, "reference", max_tokens, column, labels)
  keys <- c("document_id", "segment_id")
  segment_keys <- .lexng_key(reference$segments[keys])
  segment_row <- match(segment_keys, .lexng_key(predicted$segments[keys]))
  if (anyNA(segment_row) || nrow(reference$segments) != nrow(predicted$segments) ||
      !identical(reference$segments$text, predicted$segments$text[segment_row]))
    stop("Inputs must contain the same segment IDs and exact original text, including empty segments.",
      call. = FALSE)
  token_keys <- c(keys, "token_index")
  row <- match(.lexng_key(reference$tokens[token_keys]), .lexng_key(predicted$tokens[token_keys]))
  coordinates <- c("surface", "start", "end")
  if (anyNA(row) || nrow(reference$tokens) != nrow(predicted$tokens) ||
      any(vapply(coordinates, function(key)
        !identical(reference$tokens[[key]], predicted$tokens[[key]][row]), logical(1))))
    stop("Inputs must have the same token segmentation, surfaces and source positions.", call. = FALSE)

  pairs <- reference$tokens[c(token_keys, "surface", "start", "end")]
  segment <- match(.lexng_key(pairs[keys]), segment_keys)
  source <- reference$segments$text[segment]
  width <- stringi::stri_length(source)
  pairs$pre <- stringi::stri_sub(source,
    pmax(1, pairs$start - context_chars), pairs$start - 1L)
  pairs$keyword <- pairs$surface
  pairs$post <- stringi::stri_sub(source, pairs$end + 1L,
    pmin(width, pairs$end + context_chars))
  pairs$reference_label <- reference$tokens[[column]]
  pairs$predicted_label <- predicted$tokens[[column]][row]
  out <- c(.lexann_score(pairs, reference$documents$document_id, labels), list(
    predicted = predicted, reference = reference,
    provenance = list(evaluator = "ldfreq-annotation-evaluation", evaluator_version = "0.1.0",
      column = column, labels = labels, context_chars = context_chars,
      reference_info = reference_info,
      alignment = "exact same segment IDs/text and token IDs/surfaces/codepoint positions; reference order",
      scoring = "single-label exact match on available references; absent prediction counts as false negative",
      weighting = "token occurrences; no sampling weights or macro average",
      interpretation = "descriptive reference agreement; independence, validity and holdout are caller declarations")))
  out$provenance$content_sha256 <- .lexng_hash(out)
  out
}

.lexann_context <- function(context_chars) {
  if (!is.null(attributes(context_chars)) || length(context_chars) != 1L)
    stop("context_chars must be one non-negative whole number.", call. = FALSE)
  context_chars <- .lexng_count(context_chars, "context_chars")
  context_chars
}

.lexann_policy <- function(column, labels, reference_info) {
  column <- .lexnorm_scalar_string(column, "column")
  labels <- .lexnorm_plain_character(labels, "labels")
  if (anyDuplicated(labels) || any(!nzchar(stringi::stri_trim_both(labels))))
    stop("labels must be unique, non-blank labels in the complete label inventory.", call. = FALSE)
  reference_info <- .lexnorm_plain_list(reference_info, "reference_info")
  required <- c("reference_id", "annotation_protocol", "label_scheme",
    "model_exposure", "evaluation_role")
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

  list(column = column, labels = labels, reference_info = reference_info)
}

.lexann_validate <- function(x, argument, max_tokens, column = NULL, labels = NULL) {
  x <- .lexnorm_plain_list(x, argument)
  if (!all(c("tokens", "segments", "provenance") %in% names(x)) ||
      !identical(x$provenance$importer, "ldfreq-external-annotations"))
    stop(argument, " must be an unmodified lexdiv_import_annotations() result.", call. = FALSE)
  segments <- .lexnorm_plain_data_frame(x$segments, paste0(argument, "$segments"))
  checked <- lexdiv_import_annotations(x$tokens,
    segments[setdiff(names(segments), c("token_count", "text_sha256"))],
    x$provenance$annotation, max_tokens = max_tokens)
  if (!identical(x, checked))
    stop(argument, " has changed; import the complete annotations again.", call. = FALSE)
  if (is.null(column)) return(x)
  value <- x$tokens[[column]]
  if (!column %in% names(x$tokens) || !is.character(value) ||
      !is.null(attributes(value)))
    stop(argument, "$tokens must contain column as a plain character vector.", call. = FALSE)
  .lexnorm_plain_character(value[!is.na(value)], paste0(argument, "$tokens$", column),
    allow_zero = TRUE)
  if (any(!is.na(value) & !value %in% labels))
    stop(argument, " contains values outside labels; supply the complete label inventory.",
      call. = FALSE)
  x
}

.lexann_score <- function(pairs, document_ids, labels) {
  known <- !is.na(pairs$reference_label)
  available <- !is.na(pairs$predicted_label)
  paired <- known & available
  matches <- paired & pairs$reference_label == pairs$predicted_label
  pairs$matches_reference <- rep(NA, nrow(pairs))
  pairs$matches_reference[paired] <- matches[paired]
  pairs$outcome <- rep("neither_available", nrow(pairs))
  pairs$outcome[known & !available] <- "reference_only"
  pairs$outcome[!known & available] <- "prediction_only"
  pairs$outcome[paired] <- ifelse(matches[paired], "agreement", "disagreement")
  ratio <- function(n, d) ifelse(d > 0, n / d, NA_real_)
  summarize <- function(rows) {
    outcomes <- pairs$outcome[rows]
    n <- length(rows)
    out <- data.frame(tokens = n, reference_available = sum(known[rows]),
      prediction_available = sum(available[rows]), paired = sum(paired[rows]))
    for (outcome in c("agreement", "disagreement", "reference_only",
                      "prediction_only", "neither_available"))
      out[[outcome]] <- sum(outcomes == outcome)
    out$reference_coverage <- ratio(out$reference_available, n)
    out$prediction_coverage <- ratio(out$prediction_available, n)
    out$paired_coverage <- ratio(out$paired, n)
    out$agreement_among_paired <- ratio(out$agreement, out$paired)
    out$matches_among_reference_available <- ratio(out$agreement, out$reference_available)
    out$reference_complete <- out$reference_available == n
    out$prediction_complete <- out$prediction_available == n
    out
  }
  documents <- data.frame(document_id = document_ids)
  groups <- split(seq_len(nrow(pairs)), factor(match(pairs$document_id, documents$document_id),
    levels = seq_len(nrow(documents))))
  documents <- cbind(documents, do.call(rbind, lapply(groups, summarize)))
  rownames(documents) <- NULL

  count <- function(values) tabulate(match(values, labels), nbins = length(labels))
  by_label <- data.frame(label = labels,
    reference_n = count(pairs$reference_label),
    predictions_evaluated = count(pairs$predicted_label[known]),
    tp = count(pairs$reference_label[matches]),
    missing_predictions = count(pairs$reference_label[known & !available]),
    predictions_without_reference = count(pairs$predicted_label[!known]))
  by_label$fp <- by_label$predictions_evaluated - by_label$tp
  by_label$fn <- by_label$reference_n - by_label$tp
  by_label$precision <- ratio(by_label$tp, by_label$tp + by_label$fp)
  by_label$recall <- ratio(by_label$tp, by_label$tp + by_label$fn)
  by_label$f1 <- ratio(2 * by_label$tp, 2 * by_label$tp + by_label$fp + by_label$fn)

  # Sparse observed pairs include missing labels; no label-by-label dense matrix.
  confusion <- pairs[c("reference_label", "predicted_label")]
  group_keys <- .lexng_key(confusion)
  first <- !duplicated(group_keys)
  counts <- tabulate(match(group_keys, group_keys[first]), nbins = sum(first))
  confusion <- confusion[first, , drop = FALSE]
  confusion$n <- counts
  rownames(confusion) <- NULL
  list(summary = summarize(seq_len(nrow(pairs))), labels = by_label,
    documents = documents, pairs = pairs, confusion = confusion,
    review_queue = pairs[pairs$outcome != "agreement", , drop = FALSE])
}
