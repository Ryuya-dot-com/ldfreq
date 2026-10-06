# Import externally computed representations/suggestions without running a model.
lexdiv_import_contextual <- function(review, data, model, embeddings = NULL,
                                    suggestions = NULL) {
  .lexamb_validate_review(review)
  data <- .lexnorm_plain_data_frame(data, "data")
  anchors <- c("review_id", "occurrence_id", "segment_text", "surface", "start", "end")
  required <- c(anchors, "status", "reason")
  if (!all(required %in% names(data)))
    stop("data requires: ", paste(required, collapse = ", "), ".", call. = FALSE)
  for (field in setdiff(required, c("start", "end")))
    data[[field]] <- .lexnorm_plain_character(data[[field]], paste0("data$", field),
      allow_zero = TRUE)
  for (field in c("start", "end")) data[[field]] <- .lexng_count(data[[field]], field, 1)
  o <- review$occurrences
  row <- match(data$occurrence_id, o$occurrence_id)
  if (anyNA(row) || anyDuplicated(row))
    stop("data must identify unique, existing occurrences.", call. = FALSE)
  for (field in anchors) {
    if (any(data[[field]] != o[[field]][row]))
      stop("data$", field, " differs from the review snapshot; do not replace source anchors.",
        call. = FALSE)
  }
  if (any(!data$status %in% c("processed", "skipped", "error")) ||
      any(!nzchar(stringi::stri_trim_both(data$reason))))
    stop("Use processed, skipped or error with a non-blank reason for every returned row.",
      call. = FALSE)
  model <- .lexnorm_plain_list(model, "model")
  fields <- c("model_id", "model_revision", "tokenizer_id", "tokenizer_revision",
    "software", "software_version", "context_policy")
  if (!is.null(embeddings)) fields <- c(fields, "representation")
  if (!is.null(suggestions)) fields <- c(fields, "score_definition")
  if (!all(fields %in% names(model)))
    stop("model requires: ", paste(fields, collapse = ", "), ".", call. = FALSE)
  for (field in names(model)) {
    model[[field]] <- .lexnorm_scalar_string(model[[field]], paste0("model$", field))
    if (!nzchar(stringi::stri_trim_both(model[[field]])))
      stop("Model declarations must not be blank.", call. = FALSE)
  }
  if (model$context_policy != "full segment; no truncation")
    stop("This interface requires context_policy = 'full segment; no truncation'.", call. = FALSE)
  processed <- data$occurrence_id[data$status == "processed"]
  embedding_ids <- character()
  if (!is.null(embeddings)) {
    if (!is.matrix(embeddings) || !is.numeric(embeddings) || is.object(embeddings) ||
        ncol(embeddings) < 1L || any(!is.finite(embeddings)))
      stop("embeddings must be a finite numeric matrix with at least one dimension.", call. = FALSE)
    embedding_ids <- rownames(embeddings)
    if (is.null(embedding_ids) && nrow(embeddings) == 0L) embedding_ids <- character()
    if (length(embedding_ids) != nrow(embeddings) || anyNA(embedding_ids) ||
        anyDuplicated(embedding_ids) || any(!embedding_ids %in% processed))
      stop("Embedding row names must be unique processed occurrence IDs.", call. = FALSE)
    order <- order(match(embedding_ids, o$occurrence_id))
    embeddings <- embeddings[order, , drop = FALSE]
    embedding_ids <- embedding_ids[order]
  }
  if (is.null(suggestions)) {
    suggestions <- data.frame(occurrence_id = character(), candidate_id = character(),
      score = numeric())
  }
  suggestions <- .lexnorm_plain_data_frame(suggestions, "suggestions")
  if (!identical(sort(names(suggestions)), sort(c("occurrence_id", "candidate_id", "score"))))
    stop("suggestions requires exactly occurrence_id, candidate_id and score columns.", call. = FALSE)
  for (field in c("occurrence_id", "candidate_id"))
    suggestions[[field]] <- .lexnorm_plain_character(suggestions[[field]], field, allow_zero = TRUE)
  if (!is.numeric(suggestions$score) || !is.null(attributes(suggestions$score)) ||
      any(!is.finite(suggestions$score)))
    stop("Suggestion scores must be finite plain numeric values; their scale is declared by the caller.",
      call. = FALSE)
  if (any(!suggestions$occurrence_id %in% processed) ||
      anyDuplicated(.lexng_key(suggestions[c("occurrence_id", "candidate_id")])))
    stop("Suggestions require unique occurrence/candidate pairs for processed occurrences.", call. = FALSE)
  suggestion_row <- match(suggestions$occurrence_id, o$occurrence_id)
  candidate_row <- match(.lexng_key(data.frame(term = o$surface[suggestion_row],
    candidate_id = suggestions$candidate_id)),
    .lexng_key(review$candidates[c("term", "candidate_id")]))
  if (anyNA(candidate_row))
    stop("A suggested candidate_id is not a candidate for that occurrence's surface.", call. = FALSE)
  if (!setequal(processed, union(embedding_ids, suggestions$occurrence_id)))
    stop("Every processed occurrence must have an embedding or a suggestion.", call. = FALSE)
  reserved <- c("model_status", "model_reason", "has_embedding", "n_suggestions")
  if (any(reserved %in% names(o)))
    stop("Review token columns conflict with contextual output names.", call. = FALSE)
  o$model_status <- rep("not_returned", nrow(o))
  o$model_reason <- rep(NA_character_, nrow(o))
  o$model_status[row] <- data$status
  o$model_reason[row] <- data$reason
  o$has_embedding <- o$occurrence_id %in% embedding_ids
  o$n_suggestions <- tabulate(suggestion_row, nbins = nrow(o))
  # Keep model suggestions and human selections in distinctly named columns.
  context <- o[suggestion_row, c("document_id", "segment_id", "surface", "start", "end",
    "pre", "keyword", "post", "segment_text", "status", "candidate_id"), drop = FALSE]
  names(context)[names(context) == "status"] <- "human_status"
  names(context)[names(context) == "candidate_id"] <- "human_candidate_id"
  suggestions$label <- review$candidates$label[candidate_row]
  suggestions <- cbind(suggestions, context)
  rownames(suggestions) <- NULL
  summary <- data.frame(occurrences = nrow(o), returned = nrow(data))
  for (status in c("processed", "skipped", "error", "not_returned"))
    summary[[status]] <- sum(o$model_status == status)
  summary$with_embeddings <- sum(o$has_embedding)
  summary$with_suggestions <- sum(o$n_suggestions > 0L)
  summary$processed_proportion <- if (nrow(o)) summary$processed / nrow(o) else NA_real_
  out <- list(occurrences = o, embeddings = embeddings, suggestions = suggestions,
    summary = summary, data = data, review = review,
    provenance = list(importer = "ldfreq-contextual-output", importer_version = "0.1.0",
      review_id = review$provenance$review_id, model = model,
      coordinates = "segment-local-1-based-inclusive-Unicode-codepoints",
      interpretation = "caller-supplied model output; no inference, automatic selection or validity claim"))
  out$provenance$content_sha256 <- .lexng_hash(out)
  out
}

.lexctx_validate_output <- function(x) {
  if (!is.list(x) || !is.list(x$provenance) ||
      !identical(x$provenance$importer, "ldfreq-contextual-output") ||
      !identical(x$provenance$importer_version, "0.1.0") ||
      !identical(x$provenance$content_sha256, .lexng_hash(x)))
    stop("Use unmodified lexdiv_import_contextual() results with content fingerprints.", call. = FALSE)
  invisible(x)
}
