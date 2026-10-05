# Transparent supervised baselines over already imported target embeddings.
lexdiv_score_contextual <- function(x, training, reference, training_info) {
  .lexctx_validate_output(x)
  .lexctx_validate_output(training)
  .lexamb_validate_review(reference)
  if (!identical(training$provenance$review_id, reference$provenance$review_id))
    stop("The training reference must use the training review snapshot.", call. = FALSE)
  if (!identical(x$review$candidates, training$review$candidates) ||
      !identical(x$review$provenance$resource, training$review$provenance$resource) ||
      !setequal(x$review$summary$term, training$review$summary$term))
    stop("Query and training must use the same targets, candidate table and resource.", call. = FALSE)
  declarations <- function(z) {
    m <- z$provenance$model
    m[sort(setdiff(names(m), "score_definition"), method = "radix")]
  }
  if (!identical(declarations(x), declarations(training)) ||
      is.null(x$embeddings) || is.null(training$embeddings) ||
      !identical(ncol(x$embeddings), ncol(training$embeddings)) ||
      !identical(colnames(x$embeddings), colnames(training$embeddings)))
    stop("Embedding matrices must have matching dimensions, column names and model declarations.",
      call. = FALSE)
  if (length(intersect(x$review$source$segments$document_id,
                       training$review$source$segments$document_id)))
    stop("Query and training document IDs must be disjoint; partition sources before importing.",
      call. = FALSE)
  if (length(intersect(x$occurrences$segment_text, training$occurrences$segment_text)))
    stop("Query and training contain identical target-bearing segment text, even if IDs differ.",
      call. = FALSE)
  training_info <- .lexnorm_plain_list(training_info, "training_info")
  required <- c("training_id", "annotation_protocol", "partition_protocol", "model_exposure")
  if (!all(required %in% names(training_info)))
    stop("training_info requires: ", paste(required, collapse = ", "), ".", call. = FALSE)
  for (field in names(training_info)) {
    training_info[[field]] <- .lexnorm_scalar_string(training_info[[field]], field)
    if (!nzchar(stringi::stri_trim_both(training_info[[field]])))
      stop("Training declarations must not be blank.", call. = FALSE)
  }
  if (!training_info$model_exposure %in% c("not_shown", "shown", "unknown"))
    stop("training_info$model_exposure must be not_shown, shown or unknown.", call. = FALSE)
  if (any(c("n_selected", "n_vectors", "prototype_status") %in% names(x$review$candidates)) ||
      any(c("reference_status", "reference_candidate_id", "reference_reviewer", "reference_reason",
        "frequency_used", "centroid_used", "centroid_status") %in% names(training$occurrences)) ||
      any(c("embedding_status", "centroid_scores", "frequency_scores", "centroid_status", "frequency_status") %in%
        names(x$occurrences)))
    stop("Input columns conflict with reserved scoring audit names.", call. = FALSE)
  t <- training$occurrences
  row <- match(t$occurrence_id, reference$occurrences$occurrence_id)
  if (anyNA(row) || anyDuplicated(row) || length(row) != nrow(reference$occurrences))
    stop("Training output and reference must have the same unique occurrences.", call. = FALSE)
  t$reference_status <- reference$occurrences$status[row]
  t$reference_candidate_id <- reference$occurrences$candidate_id[row]
  t$reference_reviewer <- reference$occurrences$reviewer[row]
  t$reference_reason <- reference$occurrences$reason[row]
  t$frequency_used <- t$reference_status == "selected"
  embedding_row <- match(t$occurrence_id, rownames(training$embeddings))
  nonzero <- rowSums(abs(training$embeddings) > 0) > 0L
  t$centroid_used <- t$frequency_used & !is.na(embedding_row) &
    (nonzero[embedding_row] %in% TRUE)
  t$centroid_status <- rep("reference_not_selected", nrow(t))
  t$centroid_status[t$frequency_used & is.na(embedding_row)] <- "missing_embedding"
  t$centroid_status[t$frequency_used & !is.na(embedding_row)] <- "zero_embedding"
  t$centroid_status[t$centroid_used] <- "used"
  candidates <- x$review$candidates
  keys <- .lexng_key(candidates[c("term", "candidate_id")])
  group <- match(.lexng_key(data.frame(term = t$surface,
    candidate_id = t$reference_candidate_id)), keys)
  candidates$n_selected <- tabulate(group[t$frequency_used], nbins = nrow(candidates))
  candidates$n_vectors <- tabulate(group[t$centroid_used], nbins = nrow(candidates))
  candidates$prototype_status <- rep("no_selected_reference", nrow(candidates))
  candidates$prototype_status[candidates$n_selected > 0L] <- "no_valid_vectors"
  prototypes <- matrix(NA_real_, nrow(candidates), ncol(training$embeddings),
    dimnames = list(keys, colnames(training$embeddings)))
  groups <- split(which(t$centroid_used), factor(group[t$centroid_used], levels = seq_len(nrow(candidates))))
  for (j in seq_len(nrow(candidates))) {
    rows <- embedding_row[groups[[j]]]
    if (!length(rows)) next
    values <- training$embeddings[rows, , drop = FALSE]
    # One common scale preserves the direction of the raw arithmetic mean.
    center <- colMeans(values / max(abs(values)))
    prototypes[j, ] <- .lexctx_unit(center)
    candidates$prototype_status[j] <- if (all(is.finite(prototypes[j, ]))) "available" else "zero_centroid"
  }
  q <- x$occurrences
  q$embedding_status <- rep("missing_embedding", nrow(q))
  qr <- match(q$occurrence_id, rownames(x$embeddings))
  present <- !is.na(qr)
  q$embedding_status[present] <- ifelse(rowSums(abs(x$embeddings[qr[present], , drop = FALSE]) > 0) > 0,
    "available", "zero_embedding")
  q$centroid_scores <- q$frequency_scores <- integer(nrow(q))
  scored <- list(centroid = vector("list", nrow(q)), frequency = vector("list", nrow(q)))
  by_term <- split(seq_len(nrow(candidates)), factor(match(candidates$term, x$review$summary$term),
    levels = seq_along(x$review$summary$term)))
  for (i in seq_len(nrow(q))) {
    idx <- by_term[[match(q$surface[i], x$review$summary$term)]]
    if (!length(idx)) next
    if (sum(candidates$n_selected[idx]) > 0L) {
      scored$frequency[[i]] <- data.frame(occurrence_id = q$occurrence_id[i],
        candidate_id = candidates$candidate_id[idx], score = as.numeric(candidates$n_selected[idx]))
      q$frequency_scores[i] <- length(idx)
    }
    valid <- idx[candidates$prototype_status[idx] == "available"]
    if (q$embedding_status[i] == "available" && length(valid)) {
      values <- as.vector(prototypes[valid, , drop = FALSE] %*% .lexctx_unit(x$embeddings[qr[i], ]))
      scored$centroid[[i]] <- data.frame(occurrence_id = q$occurrence_id[i],
        candidate_id = candidates$candidate_id[valid], score = pmax(-1, pmin(1, values)))
      q$centroid_scores[i] <- length(valid)
    }
  }
  q$centroid_status <- ifelse(q$centroid_scores == q$candidate_count, "complete_scores", "incomplete_scores")
  q$centroid_status[q$centroid_scores == 0L] <- "no_prototypes"
  q$centroid_status[q$embedding_status != "available"] <- q$embedding_status[q$embedding_status != "available"]
  q$centroid_status[q$candidate_count == 0L] <- "no_candidates"
  if (!nrow(q)) q$centroid_status <- character()
  q$frequency_status <- rep("no_selected_training", nrow(q))
  q$frequency_status[q$frequency_scores > 0L] <- "complete_scores"
  q$frequency_status[q$candidate_count == 0L] <- "no_candidates"
  outputs <- lapply(names(scored), function(method) {
    scores <- do.call(rbind, scored[[method]])
    if (is.null(scores)) scores <- data.frame(occurrence_id = character(), candidate_id = character(), score = numeric())
    data <- q[c("review_id", "occurrence_id", "segment_text", "surface", "start", "end")]
    data$status <- rep("skipped", nrow(q))
    data$status[q[[paste0(method, "_scores")]] > 0L] <- "processed"
    data$reason <- if (nrow(q)) paste0(method, ": ", q[[paste0(method, "_status")]],
      "; input: ", q$model_status, "; ", ifelse(is.na(q$model_reason), "not returned", q$model_reason)) else character()
    model <- x$provenance$model
    model$scorer <- paste0("ldfreq-", method)
    model$scorer_version <- "0.1.0"
    model$score_definition <- if (method == "centroid")
      "cosine to L2-normalized raw-vector arithmetic mean; higher is closer; not probabilities" else
      "selected training-reference count by exact surface/candidate; higher is more frequent; no smoothing"
    model$training_sha256 <- training$provenance$content_sha256
    model$training_reference_sha256 <- reference$provenance$content_sha256
    model$training_id <- training_info$training_id
    model$training_protocol <- training_info$annotation_protocol
    model$partition_protocol <- training_info$partition_protocol
    model$training_model_exposure <- training_info$model_exposure
    lexdiv_import_contextual(x$review, data, model, suggestions = scores)
  })
  names(outputs) <- names(scored)
  out <- c(outputs, list(candidates = candidates, prototypes = prototypes,
    training_occurrences = t, query_occurrences = q, query = x, training = training, reference = reference,
    provenance = list(scorer = "ldfreq-contextual-baselines", scorer_version = "0.1.0",
      training_info = training_info, direction = "higher",
      split_checks = "disjoint document IDs and no identical target-bearing segment text",
      interpretation = "supervised within-surface baselines; split validity and annotation quality require external evidence")))
  out$provenance$content_sha256 <- .lexng_hash(out)
  out
}

.lexctx_unit <- function(x) {
  scale <- max(abs(x))
  if (scale == 0) return(rep(NA_real_, length(x)))
  x <- x / scale
  x / sqrt(sum(x * x))
}
