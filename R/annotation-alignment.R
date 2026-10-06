# Source-interval correspondence; neither token indices nor labels define alignment.
lexdiv_align_annotations <- function(predicted, reference, column = NULL,
                                     labels = NULL, reference_info = NULL,
                                     context_chars = 30L, max_tokens = 1e6) {
  max_tokens <- .lexnorm_positive_whole(max_tokens, "max_tokens")
  context_chars <- .lexann_context(context_chars)
  supplied <- !vapply(list(column, labels, reference_info), is.null, logical(1))
  if (any(supplied) && !all(supplied))
    stop("Supply column, labels and reference_info together, or omit all three.", call. = FALSE)
  policy <- if (all(supplied)) .lexann_policy(column, labels, reference_info) else NULL
  predicted <- .lexann_validate(predicted, "predicted", max_tokens, column, labels)
  reference <- .lexann_validate(reference, "reference", max_tokens, column, labels)
  keys <- c("document_id", "segment_id")
  segment_keys <- .lexng_key(reference$segments[keys])
  segment_row <- match(segment_keys, .lexng_key(predicted$segments[keys]))
  if (anyNA(segment_row) || nrow(reference$segments) != nrow(predicted$segments) ||
      !identical(reference$segments$text, predicted$segments$text[segment_row]))
    stop("Inputs must contain the same segment IDs and exact original text, including empty segments.",
      call. = FALSE)

  columns <- c(keys, "token_index", "surface", "start", "end")
  members <- rbind(reference$tokens[columns], predicted$tokens[columns])
  members$side <- rep(c("reference", "predicted"),
    c(nrow(reference$tokens), nrow(predicted$tokens)))
  if (!is.null(policy))
    members$label <- c(reference$tokens[[column]], predicted$tokens[[column]])
  segment <- match(.lexng_key(members[keys]), segment_keys)
  ordered <- order(segment, members$start, members$end, members$side)
  members <- members[ordered, , drop = FALSE]
  segment <- segment[ordered]
  rownames(members) <- NULL
  members$alignment_id <- integer(nrow(members))
  # Overlap components in a sorted interval sweep: no Cartesian product.
  offset <- 0L
  for (rows in split(seq_len(nrow(members)), segment)) {
    previous_end <- c(-Inf, utils::head(cummax(members$end[rows]), -1L))
    local <- cumsum(members$start[rows] > previous_end)
    members$alignment_id[rows] <- offset + local
    offset <- offset + utils::tail(local, 1L)
  }
  group_rows <- split(seq_len(nrow(members)), members$alignment_id)
  first <- !duplicated(members$alignment_id)
  groups <- members[first, c("alignment_id", keys, "start", "end"), drop = FALSE]
  groups$end <- vapply(group_rows, function(rows) max(members$end[rows]), integer(1))
  groups$reference_n <- tabulate(members$alignment_id[members$side == "reference"], offset)
  groups$predicted_n <- tabulate(members$alignment_id[members$side == "predicted"], offset)
  groups$relation <- rep("complex", nrow(groups))
  groups$relation[groups$reference_n == 1L & groups$predicted_n > 1L] <- "split"
  groups$relation[groups$reference_n > 1L & groups$predicted_n == 1L] <- "merge"
  groups$relation[groups$reference_n == 0L] <- "prediction_only"
  groups$relation[groups$predicted_n == 0L] <- "reference_only"
  one <- groups$reference_n == 1L & groups$predicted_n == 1L
  groups$relation[one] <- "changed_span"
  exact <- vapply(group_rows, function(rows) length(rows) == 2L &&
    length(unique(members$side[rows])) == 2L &&
    length(unique(members$start[rows])) == 1L &&
    length(unique(members$end[rows])) == 1L, logical(1))
  groups$relation[exact] <- "exact"
  source <- reference$segments$text[match(.lexng_key(groups[keys]), segment_keys)]
  groups$pre <- stringi::stri_sub(source,
    pmax(1, groups$start - context_chars), groups$start - 1L)
  groups$keyword <- stringi::stri_sub(source, groups$start, groups$end)
  groups$post <- stringi::stri_sub(source, groups$end + 1L,
    pmin(stringi::stri_length(source), groups$end + context_chars))
  rownames(groups) <- NULL
  members$relation <- groups$relation[members$alignment_id]
  members$label_eligible <- members$relation == "exact"

  # A boundary is the junction (left end, right start), preserving whitespace gaps.
  junctions <- function(x, side) {
    tokens <- x$tokens
    key <- .lexng_key(tokens[keys])
    left <- which(utils::head(key, -1L) == utils::tail(key, -1L))
    out <- tokens[left, keys, drop = FALSE]
    out$left_end <- tokens$end[left]
    out$right_start <- tokens$start[left + 1L]
    out[[paste0(side, "_left_token_index")]] <- tokens$token_index[left]
    out[[paste0(side, "_right_token_index")]] <- tokens$token_index[left + 1L]
    out
  }
  ref_boundary <- junctions(reference, "reference")
  pred_boundary <- junctions(predicted, "predicted")
  boundary_keys <- c(keys, "left_end", "right_start")
  ref_key <- .lexng_key(ref_boundary[boundary_keys])
  pred_key <- .lexng_key(pred_boundary[boundary_keys])
  boundaries <- rbind(ref_boundary[boundary_keys],
    pred_boundary[!pred_key %in% ref_key, boundary_keys, drop = FALSE])
  key <- .lexng_key(boundaries[boundary_keys])
  ref_row <- match(key, ref_key)
  pred_row <- match(key, pred_key)
  for (name in setdiff(names(ref_boundary), boundary_keys))
    boundaries[[name]] <- ref_boundary[[name]][ref_row]
  for (name in setdiff(names(pred_boundary), boundary_keys))
    boundaries[[name]] <- pred_boundary[[name]][pred_row]
  boundaries$outcome <- ifelse(is.na(ref_row), "prediction_only",
    ifelse(is.na(pred_row), "reference_only", "matched"))
  boundaries <- boundaries[order(match(.lexng_key(boundaries[keys]), segment_keys),
    boundaries$left_end, boundaries$right_start), , drop = FALSE]
  rownames(boundaries) <- NULL

  ratio <- function(n, d) ifelse(d > 0, n / d, NA_real_)
  summarize <- function(member_rows, boundary_rows) {
    m <- members[member_rows, , drop = FALSE]
    b <- boundaries[boundary_rows, , drop = FALSE]
    out <- data.frame(measure = c("token_span", "internal_boundary"),
      reference_n = c(sum(m$side == "reference"), sum(b$outcome != "prediction_only")),
      predicted_n = c(sum(m$side == "predicted"), sum(b$outcome != "reference_only")),
      matched = c(sum(m$side == "reference" & m$label_eligible), sum(b$outcome == "matched")))
    out$fp <- out$predicted_n - out$matched
    out$fn <- out$reference_n - out$matched
    out$precision <- ratio(out$matched, out$predicted_n)
    out$recall <- ratio(out$matched, out$reference_n)
    out$f1 <- ratio(2 * out$matched, out$reference_n + out$predicted_n)
    out
  }
  document_ids <- reference$documents$document_id
  member_docs <- split(seq_len(nrow(members)), factor(members$document_id, levels = document_ids))
  boundary_docs <- split(seq_len(nrow(boundaries)), factor(boundaries$document_id, levels = document_ids))
  documents <- do.call(rbind, lapply(seq_along(document_ids), function(i)
    cbind(document_id = document_ids[i], summarize(member_docs[[i]], boundary_docs[[i]]))))
  rownames(documents) <- NULL
  evaluation <- NULL
  if (!is.null(policy)) {
    ref <- members[members$side == "reference" & members$label_eligible, , drop = FALSE]
    pred <- members[members$side == "predicted" & members$label_eligible, , drop = FALSE]
    pairs <- ref[c("alignment_id", keys, "token_index", "surface", "start", "end")]
    names(pairs)[names(pairs) == "token_index"] <- "reference_token_index"
    row <- match(ref$alignment_id, pred$alignment_id)
    pairs$predicted_token_index <- pred$token_index[row]
    pairs <- cbind(pairs, groups[match(ref$alignment_id, groups$alignment_id),
      c("pre", "keyword", "post"), drop = FALSE])
    rownames(pairs) <- NULL
    pairs$reference_label <- ref$label
    pairs$predicted_label <- pred$label[row]
    evaluation <- .lexann_score(pairs, document_ids, labels)
  }
  out <- list(summary = summarize(seq_len(nrow(members)), seq_len(nrow(boundaries))),
    documents = documents, groups = groups, members = members, boundaries = boundaries,
    review_queue = groups[groups$relation != "exact", , drop = FALSE],
    annotation_evaluation = evaluation, predicted = predicted, reference = reference,
    provenance = list(aligner = "ldfreq-annotation-alignment", aligner_version = "0.1.0",
      context_chars = context_chars, label_policy = policy,
      coordinates = reference$provenance$coordinates,
      alignment = "overlapping source-interval components; exact spans alone are label eligible; reference segment order",
      boundary = "internal junction (left token end, right token start); excludes segment edges; includes supplied whitespace and punctuation tokens",
      label_scope = "exact_span_pairs_only; segmentation exclusions are not label false negatives",
      interpretation = "descriptive correspondence to supplied reference; reference status and independent validity are not established"))
  out$provenance$content_sha256 <- .lexng_hash(out)
  out
}
