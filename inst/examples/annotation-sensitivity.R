# Source explicitly; this is an example workflow, not an exported package API.
# Compare supplied annotations, not their accuracy against independent gold data.
annotation_sensitivity <- function(before, after, texts, window_length = 3L) {
  if (inherits(before, "lexdiv_tokenization") || inherits(after, "lexdiv_tokenization"))
    stop("Supply named batches, including for a single document.", call. = FALSE)
  audit <- ldfreq::lexdiv_compare_annotations(before, after)
  ids <- audit$documents$document_id
  if (!length(ids) || !is.character(texts) || is.object(texts) ||
      !identical(names(attributes(texts)), "names") || anyNA(texts) ||
      anyNA(names(texts)) || anyDuplicated(names(texts)) ||
      !setequal(names(texts), ids) || any(!validUTF8(texts)) ||
      any(Encoding(texts) %in% c("bytes", "latin1")))
    stop("texts must be a named UTF-8 character vector with exactly the batch IDs.",
      call. = FALSE)
  texts <- texts[ids]
  after <- after[ids]
  for (id in ids) {
    if (!all(c("lemma", "upos") %in% names(before[[id]]$tokens)) ||
        !all(c("lemma", "upos") %in% names(after[[id]]$tokens)))
      stop("Both versions require supplied lemma and UPOS columns; missing labels may be NA.",
        call. = FALSE)
    text <- unname(texts[[id]])
    hash <- digest::digest(charToRaw(enc2utf8(text)), algo = "sha256", serialize = FALSE)
    p <- before[[id]]$provenance
    t <- before[[id]]$tokens
    if (!identical(hash, p$source_text_sha256) ||
        !identical(hash, p$processed_text_sha256) ||
        !identical(stringi::stri_sub(text, t$start, t$end), t$surface))
      stop("Original and processed text must match exactly in document ", id,
        "; this example does not map transformed-text offsets to source offsets.", call. = FALSE)
  }
  # Fixed choices make the example easy to inspect; edit explicitly for a study.
  conditions <- data.frame(condition_id = c("surface_all", "lemma_all", "lemma_content"),
    unit = c("surface", "lemma", "lemma"), inclusion = c("all", "all", "content"))
  versions <- list(before = before, after = after)
  runs <- tokens <- metrics <- coverage <- list()
  for (i in seq_len(nrow(conditions))) {
    condition <- conditions$condition_id[i]
    runs[[condition]] <- list()
    for (version in names(versions)) {
      runs[[condition]][[version]] <- list()
      for (id in ids) {
        x <- versions[[version]][[id]]
        diversity <- ldfreq::lexdiv_metrics_text(x, unit = conditions$unit[i],
          word_inclusion = conditions$inclusion[i], metrics = c("ttr", "mattr"),
          window_length = window_length)
        selection <- diversity$token_audit
        reference <- ldfreq::nj8_profile(selection$selected_unit[selection$eligible],
          unit = conditions$unit[i])
        # Reference query positions index the selected vector, not source tokens.
        positions <- which(selection$eligible)
        stopifnot(identical(reference$lookup$query_index, seq_along(positions)))
        selection$nj8_matched <- rep(NA, nrow(selection))
        selection$nj8_lookup_term <- rep(NA_character_, nrow(selection))
        selection$nj8_matched[positions] <- reference$lookup$matched
        selection$nj8_lookup_term[positions] <- reference$lookup$lookup_term
        selection$start <- x$tokens$start
        selection$end <- x$tokens$end
        selection$lemma_missing <- is.na(x$tokens$lemma)
        selection$upos_missing <- is.na(x$tokens$upos)
        header <- data.frame(document_id = id, condition_id = condition, version = version)
        k <- length(metrics) + 1L
        tokens[[k]] <- cbind(header[rep(1L, nrow(selection)), ], selection)
        metrics[[k]] <- cbind(header[rep(1L, nrow(diversity$results)), ],
          as.data.frame(diversity$results))
        p <- diversity$preprocessing
        counts <- reference$coverage
        coverage[[k]] <- cbind(header, data.frame(source_tokens = p$input_tokens,
          selected_tokens = p$eligible_tokens, excluded_tokens = p$excluded_tokens,
          selection_coverage = p$unit_coverage, reference_eligible_tokens = counts$eligible_tokens,
          matched_tokens = counts$matched_tokens, off_list_tokens = counts$off_list_tokens,
          nj8_coverage_of_eligible = counts$token_coverage,
          matched_fraction_of_source = if (p$input_tokens) counts$matched_tokens / p$input_tokens else NA_real_))
        runs[[condition]][[version]][[id]] <- list(diversity = diversity, reference = reference)
      }
    }
  }
  tokens <- do.call(rbind, tokens)
  metrics <- do.call(rbind, metrics)
  coverage <- do.call(rbind, coverage)
  rownames(tokens) <- rownames(metrics) <- rownames(coverage) <- NULL
  keys <- c("document_id", "condition_id", "metric_id")
  columns <- c(keys, "N", "V", "value", "status", "missing_reason")
  differences <- merge(metrics[metrics$version == "before", columns],
    metrics[metrics$version == "after", columns], by = keys,
    suffixes = c("_before", "_after"), sort = FALSE)
  stopifnot(nrow(differences) == length(ids) * nrow(conditions) * 2L)
  paired <- is.finite(differences$value_before) & is.finite(differences$value_after)
  differences$difference_status <- ifelse(paired, "paired", "not_computable")
  differences$delta <- ifelse(paired, differences$value_after - differences$value_before, NA_real_)
  differences$absolute_delta <- abs(differences$delta)

  changes <- audit$changes
  source <- unname(texts[changes$document_id])
  changes$pre <- stringi::stri_sub(source, pmax(1L, changes$start - 24L), changes$start - 1L)
  changes$keyword <- stringi::stri_sub(source, changes$start, changes$end)
  changes$post <- stringi::stri_sub(source, changes$end + 1L, changes$end + 24L)
  list(settings = list(example_version = "1", conditions = conditions,
      metrics = c("ttr", "mattr"), window_length = window_length,
      coordinates = "document-local-1-based-inclusive-Unicode-codepoints",
      context_characters = 24L, difference_direction = "after-minus-before",
      ldfreq_version = as.character(utils::packageVersion("ldfreq"))),
    inputs = list(before = before, after = after, texts = texts),
    audit = audit, changes = changes, tokens = tokens, metrics = metrics,
    coverage = coverage, differences = differences, runs = runs)
}
