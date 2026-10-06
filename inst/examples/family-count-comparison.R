# Source explicitly; this recipe is not an exported API. Counts use the supplied
# surface/lemma strings verbatim. Lookup normalization belongs to the profile.
compare_family_counts <- function(profile, selected = profile$occurrences$selected) {
  hash <- profile$provenance$content_sha256
  check <- profile
  check$provenance$content_sha256 <- NULL
  if (!identical(profile$provenance$method, "ldfreq-family-profile") ||
      !identical(hash, digest::digest(check, algo = "sha256", serializeVersion = 2L)))
    stop("Supply an unmodified family profile.", call. = FALSE)
  o <- profile$occurrences
  t <- profile$annotations$tokens
  ids <- c("document_id", "segment_id", "token_index")
  if (!identical(o[ids], t[ids]) || !is.character(t$lemma) ||
      any(!is.na(t$lemma) & !nzchar(t$lemma)))
    stop("Aligned annotations require a supplied lemma column; unknown lemmas use NA.", call. = FALSE)
  if (!is.logical(selected) || length(selected) != nrow(o) || anyNA(selected) ||
      any(selected & !(o$selected %in% TRUE)))
    stop("selected must be a complete logical vector within the profile's known selection.", call. = FALSE)
  common <- selected & o$status == "matched" & !is.na(t$lemma)
  selection <- cbind(t[ids], data.frame(selected = selected, common_resolved = common))
  units <- list(surface = t$surface, lemma = t$lemma, family = o$family_id)
  comparison <- documents <- list()
  for (id in profile$documents$document_id) {
    in_document <- o$document_id == id
    take <- in_document & selected
    n <- sum(take)
    matched <- sum(take & o$status == "matched")
    documents[[id]] <- data.frame(document_id = id, input_tokens = sum(in_document),
      selected_tokens = n, excluded_tokens = sum(in_document & !selected),
      matched_tokens = matched, unresolved_tokens = n - matched,
      unlisted_tokens = sum(take & o$status == "unlisted"),
      ambiguous_tokens = sum(take & o$status == "ambiguous"),
      missing_unit_tokens = sum(take & o$status == "missing_unit"),
      missing_pos_tokens = sum(take & o$status == "missing_pos"),
      withheld_tokens = sum(take & o$status == "review_unresolved"),
      missing_lemma_tokens = sum(take & is.na(t$lemma)),
      common_tokens = sum(in_document & common),
      token_coverage = if (n) matched / n else NA_real_)
    scopes <- list(all_selected = take, common_resolved = in_document & common)
    for (scope in names(scopes)) {
      rows <- scopes[[scope]]
      for (unit in names(units)) {
        values <- units[[unit]][rows]
        known <- !is.na(values)
        observed <- length(unique(values[known]))
        complete <- all(known)
        comparison[[length(comparison) + 1L]] <- data.frame(document_id = id,
          scope = scope, unit = unit, N = length(values), known_tokens = sum(known),
          observed_types = observed, V = if (complete) observed else NA_integer_,
          ttr = if (complete && length(values)) observed / length(values) else NA_real_,
          status = if (!length(values)) "empty" else if (complete) "complete" else "incomplete")
      }
    }
  }
  comparison <- do.call(rbind, comparison)
  documents <- do.call(rbind, documents)
  rownames(comparison) <- rownames(documents) <- NULL
  list(documents = documents, comparison = comparison, selection = selection,
    profile = profile,
    settings = list(example_version = "1", counting_keys = "supplied surface and lemma verbatim",
      common_scope = "selected occurrences with an assigned family and a known lemma",
      missing_family = "no identity fallback; whole-selection V/TTR remain unavailable",
      sequence = "source IDs retained; common subset used for types/TTR only, not sliding windows"))
}
