# Count exact tuples without concatenating user strings into ambiguous keys.
.nj8_diagnostic_counts <- function(lookup, columns) {
  encoded <- lapply(lookup[columns], function(x) match(x, unique(x)))
  key <- do.call(paste, c(encoded, sep = ":"))
  first <- !duplicated(key)
  group <- match(key, key[first])
  out <- lookup[first, columns, drop = FALSE]
  out$token_count <- as.double(tabulate(group, nbins = nrow(out)))
  per_document <- !duplicated(data.frame(group = group, document_id = lookup$document_id))
  out$document_count <- as.double(tabulate(group[per_document], nbins = nrow(out)))
  out <- out[order(-out$token_count, seq_len(nrow(out))), , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Diagnose NJ8 non-matches and lexical-unit transformations
#'
#' Aggregates an existing NJ8 profile without repeating tokenization, annotation,
#' or resource lookup. Counts distinguish occurrences from documents. Flags are
#' observable string changes, not judgements about annotation accuracy or word
#' difficulty. The source profile remains the occurrence-level audit trail.
#'
#' @param x An unmodified result of [nj8_profile()] or [nj8_profile_batch()].
#' @return A plain list of `unmatched_terms`, `unit_mappings`, `coverage`,
#'   `exclusion_reasons`, `provenance`, and `document_provenance`. See the help
#'   topic for grouping keys, flag definitions, and the single-document ID.
#' @export
nj8_diagnostics <- function(x) {
  batch <- inherits(x, "nj8_profile_batch")
  if (!is.list(x) || (!batch && !inherits(x, "nj8_profile"))) {
    stop("x must be a result of nj8_profile() or nj8_profile_batch().", call. = FALSE)
  }
  lookup <- x$lookup
  fields <- c("surface_term", "term", "lookup_term", "matched")
  if (!is.data.frame(lookup) || !all(fields %in% names(lookup)) ||
      !all(vapply(lookup[fields[1:3]], function(v) is.character(v) &&
        !anyNA(v) && all(validUTF8(v)), logical(1))) ||
      !is.logical(lookup$matched) || anyNA(lookup$matched) ||
      !is.list(x$provenance)) {
    stop("x has an invalid NJ8 lookup or provenance; use the unmodified profile.", call. = FALSE)
  }
  if (batch) {
    coverage <- x$coverage
    exclusions <- x$exclusion_reasons
    document_provenance <- x$document_provenance
  } else {
    lookup <- .nj8_prepend_document_id(lookup, "document_1")
    coverage <- .nj8_batch_coverage(list(x), "document_1", x)
    exclusions <- .nj8_prepend_document_id(x$diagnostics$exclusion_reasons, "document_1")
    document_provenance <- data.frame(document_id = "document_1",
      input_source = x$provenance$input_source, selected_unit = x$provenance$selected_unit,
      stringsAsFactors = FALSE)
    document_provenance$preprocessing_ref <- I(list(x$provenance$preprocessing_ref))
  }
  count_fields <- c("eligible_tokens", "matched_tokens", "off_list_tokens")
  if (!is.data.frame(coverage) || !all(c("document_id", count_fields) %in% names(coverage)) ||
      !is.character(coverage$document_id) || anyNA(coverage$document_id) ||
      anyDuplicated(coverage$document_id) || any(!nzchar(coverage$document_id)) ||
      !all(vapply(coverage[count_fields], function(v) is.numeric(v) &&
        all(is.finite(v)) && all(v >= 0), logical(1))) ||
      !is.character(lookup$document_id) || anyNA(lookup$document_id) ||
      any(!lookup$document_id %in% coverage$document_id)) {
    stop("x has invalid document IDs or coverage; use the unmodified profile.", call. = FALSE)
  }
  index <- match(lookup$document_id, coverage$document_id)
  n <- nrow(coverage)
  if (any(tabulate(index, n) != coverage$eligible_tokens) ||
      any(tabulate(index[lookup$matched], n) != coverage$matched_tokens) ||
      any(tabulate(index[!lookup$matched], n) != coverage$off_list_tokens)) {
    stop("x has inconsistent lookup and coverage counts; use the unmodified profile.", call. = FALSE)
  }
  unmatched <- .nj8_diagnostic_counts(lookup[!lookup$matched, , drop = FALSE], "lookup_term")
  mappings <- .nj8_diagnostic_counts(lookup, fields)
  mappings$unit_changed <- mappings$surface_term != mappings$term
  mappings$lookup_changed <- mappings$term != mappings$lookup_term
  numeric_label <- function(v) stringi::stri_detect_regex(v, "^\\p{N}+$")
  has_space <- function(v) stringi::stri_detect_regex(v, "\\p{White_Space}")
  mappings$numeric_introduced <- numeric_label(mappings$term) & !numeric_label(mappings$surface_term)
  mappings$whitespace_introduced <- has_space(mappings$term) & !has_space(mappings$surface_term)
  list(unmatched_terms = unmatched, unit_mappings = mappings,
    coverage = coverage, exclusion_reasons = exclusions,
    provenance = x$provenance, document_provenance = document_provenance)
}
