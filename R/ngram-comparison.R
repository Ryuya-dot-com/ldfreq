# Compare reference choices on one unchanged target and one explicit common set.
lexdiv_ngram_compare <- function(x, references, baseline = NULL, max_rows = 1e6) {
  .lexng_validate_result(x, "lexdiv_ngrams")
  references <- .lexnorm_plain_list(references, "references")
  if (length(references) < 2L)
    stop("references must be a named list of at least two n-gram references.", call. = FALSE)
  ids <- .lex_batch_validate_ids(names(references), length(references))
  names(references) <- ids
  for (ref in references) .lexng_validate_result(ref, "lexdiv_ngram_reference")
  if (is.null(baseline)) baseline <- ids[1L]
  baseline <- .lexnorm_scalar_string(baseline, "baseline")
  if (!baseline %in% ids) stop("baseline must name one of references.", call. = FALSE)
  for (field in c("lookup_unit", "resource_key_normalization_id")) {
    declarations <- vapply(references, function(ref) ref$provenance$resource[[field]], character(1))
    if (length(unique(declarations)) != 1L)
      stop("Reference ", field, " declarations must agree.", call. = FALSE)
  }
  max_rows <- .lexnorm_positive_whole(max_rows, "max_rows")
  planned <- length(references) * (nrow(x$occurrences) + 2 * nrow(x$documents))
  if (planned > max_rows)
    stop("Planned lookup and summary rows exceed max_rows.", call. = FALSE)
  # Reuse the established per-reference arithmetic, statuses and validation.
  profiles <- lapply(references, function(ref) lexdiv_ngram_profile(x, ref))
  common <- Reduce(`&`, lapply(profiles, function(p) !is.na(p$lookup$frequency_per_million)))
  key <- .lexng_key(x$occurrences[.lexng_columns])
  group <- match(.lexng_key(x$occurrences[c("document_id", "n")]),
    .lexng_key(x$documents[c("document_id", "n")]))
  rows <- split(seq_len(nrow(x$occurrences)), factor(group, levels = seq_len(nrow(x$documents))))
  common_rows <- vector("list", 2L * nrow(x$documents))
  for (i in seq_along(rows)) {
    take <- rows[[i]][common[rows[[i]]]]
    common_rows[[2L * i - 1L]] <- take
    common_rows[[2L * i]] <- take[!duplicated(key[take])]
  }
  common_items <- as.double(lengths(common_rows))
  common_mean <- function(values) vapply(common_rows, function(take)
    if (length(take)) mean(values[take]) else NA_real_, numeric(1))
  baseline_values <- profiles[[baseline]]$lookup$frequency_per_million
  baseline_means <- common_mean(baseline_values)
  tag <- function(table, id) data.frame(reference_id = rep(id, nrow(table)), table,
    row.names = NULL, stringsAsFactors = FALSE)
  summaries <- lookups <- metadata <- vector("list", length(references))
  for (j in seq_along(references)) {
    profile <- profiles[[j]]; ref <- references[[j]]
    lookup <- profile$lookup
    lookup$common_available <- common
    lookup$difference_from_baseline <- as.double(ifelse(common,
      lookup$frequency_per_million - baseline_values, NA_real_))
    lookups[[j]] <- tag(lookup, ids[j])
    summary <- profile$summary
    total <- match(summary$n, ref$totals$n)
    summary$reference_opportunities <- ref$totals$opportunities[total]
    summary$reference_documents <- ref$totals$documents[total]
    summary$reference_complete <- rep(ref$provenance$complete, nrow(summary))
    summary$common_items <- common_items
    summary$common_coverage <- as.double(ifelse(summary$eligible_items > 0,
      common_items / summary$eligible_items, NA_real_))
    summary$common_mean_frequency_per_million <- common_mean(lookup$frequency_per_million)
    summary$difference_from_baseline <- summary$common_mean_frequency_per_million - baseline_means
    summary$comparison_status <- as.character(ifelse(summary$eligible_items == 0, "empty",
      ifelse(common_items == 0, "no_common_values", "ok")))
    summaries[[j]] <- tag(summary, ids[j])
    metadata[[j]] <- tag(data.frame(ref$totals,
      complete = rep(ref$provenance$complete, nrow(ref$totals)),
      as.data.frame(ref$provenance$resource, stringsAsFactors = FALSE),
      content_sha256 = ref$provenance$content_sha256, stringsAsFactors = FALSE), ids[j])
  }
  bind <- function(tables) {
    result <- do.call(rbind, tables); rownames(result) <- NULL; result
  }
  list(summary = bind(summaries), lookup = bind(lookups),
    documents = x$documents, references = bind(metadata),
    provenance = list(contract_id = "ldfreq-ngram-reference-comparison",
      contract_version = "0.1.0", baseline = baseline, reference_order = ids,
      target = x$provenance,
      references = lapply(references, `[[`, "provenance"),
      common_basis = "defined-rates-in-all-references-including-defined-sample-zeros",
      difference = "reference-minus-baseline-on-common-target-items",
      rate_denominator = "reference-eligible-n-gram-opportunities",
      max_rows = max_rows, runtime_network_access = FALSE))
}
