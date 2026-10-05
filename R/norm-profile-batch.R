# Document composition reuses the single-document norm calculations.
.lexnorm_batch_contract_id <- "ldfreq-generic-norm-profile-batch"
.lexnorm_batch_contract_version <- "0.1.0"
.lexnorm_batch_schema_id <- "generic-norm-profile-batch-result"
.lexnorm_batch_schema_version <- "0.1.0"

.lexnorm_batch_prepare_shared <- function(norms, key, measure_specs, resource, weightings) {
  measure_specs <- .lexnorm_measure_specs(measure_specs)
  norm_input <- .lexnorm_norms(norms, key, measure_specs)
  resource <- .lexnorm_resource(resource)
  weightings <- .lexnorm_requested_weightings(weightings)
  list(
    norms = norm_input$norms,
    key = norm_input$key,
    measure_specs = measure_specs,
    resource = resource,
    weightings = weightings
  )
}

.lexnorm_batch_row_budget <- function(terms, measure_specs, weightings, max_rows) {
  max_rows <- .lexnorm_positive_whole(max_rows, "max_rows")
  document_count <- length(terms)
  term_counts <- vapply(terms, length, numeric(1L))
  measure_count <- as.double(nrow(measure_specs))
  weighting_count <- as.double(length(weightings))
  planned_lookup_rows <- sum(term_counts) * measure_count
  planned_summary_rows <- as.double(document_count) *
    measure_count * weighting_count
  planned_coverage_rows <- planned_summary_rows
  planned_result_rows <- planned_lookup_rows +
    planned_summary_rows + planned_coverage_rows
  if (!is.finite(planned_result_rows) || planned_result_rows > max_rows) {
    stop(
      sprintf(
        "planned batch result rows (%s) exceed max_rows (%s).",
        format(planned_result_rows, scientific = FALSE, trim = TRUE),
        format(max_rows, scientific = FALSE, trim = TRUE)
      ),
      call. = FALSE
    )
  }
  per_document_lookup <- term_counts * measure_count
  per_document_summary <- rep.int(
    measure_count * weighting_count,
    document_count
  )
  per_document_coverage <- per_document_summary
  per_document_total <- per_document_lookup +
    per_document_summary + per_document_coverage
  list(
    max_rows = max_rows,
    term_counts = term_counts,
    per_document_lookup = per_document_lookup,
    per_document_summary = per_document_summary,
    per_document_coverage = per_document_coverage,
    per_document_total = per_document_total,
    planned_lookup_rows = planned_lookup_rows,
    planned_summary_rows = planned_summary_rows,
    planned_coverage_rows = planned_coverage_rows,
    planned_result_rows = planned_result_rows
  )
}

.lexnorm_batch_profile_prepared <- function(terms, shared) {
  lookup <- .lexnorm_lookup_long(
    terms,
    shared$norms,
    shared$key,
    shared$measure_specs
  )
  summary <- .lexnorm_summary(
    terms,
    shared$norms,
    shared$key,
    shared$measure_specs,
    shared$weightings,
    shared$resource
  )
  list(
    status = if (length(terms)) "ok" else "empty",
    summary = summary,
    lookup = lookup,
    coverage = .lexnorm_coverage(summary)
  )
}

.lexnorm_batch_prepend_document_id <- function(table, document_id) {
  output <- data.frame(
    document_id = rep.int(document_id, nrow(table)),
    table,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  rownames(output) <- NULL
  output
}

.lexnorm_batch_bind_component <- function(profiles, ids, component, prototype) {
  if (!length(profiles)) {
    return(.lexnorm_batch_prepend_document_id(
      prototype[[component]][FALSE, , drop = FALSE],
      character()
    ))
  }
  pieces <- lapply(seq_along(profiles), function(index) {
    .lexnorm_batch_prepend_document_id(
      profiles[[index]][[component]],
      ids[[index]]
    )
  })
  output <- do.call(base::rbind.data.frame, unname(pieces))
  rownames(output) <- NULL
  output
}

lexdiv_norm_profile_batch <- function(
    documents,
    norms,
    key,
    measure_specs,
    resource,
    weightings = c("token", "type"),
    id_col = "document_id",
    terms_col = "terms",
    max_rows = 1e6) {
  id_col <- .lex_batch_scalar_name(id_col, "id_col")
  terms_col <- .lex_batch_scalar_name(terms_col, "terms_col")
  if (identical(id_col, terms_col)) {
    stop("id_col and terms_col must select different columns.", call. = FALSE)
  }
  max_rows <- .lexnorm_positive_whole(max_rows, "max_rows")
  batch <- .lex_batch_documents(documents, id_col, terms_col)
  batch$terms <- lapply(seq_along(batch$tokens), function(i) {
    terms <- tryCatch(.lexnorm_terms(batch$tokens[[i]]), error = function(e) {
      stop(sprintf("Document %s: %s", encodeString(batch$ids[[i]], quote = '"'),
        conditionMessage(e)), call. = FALSE)
    })
    .lex_warn_likely_raw_text(terms,
      sprintf("document %s", encodeString(batch$ids[[i]], quote = '"')),
      "lexdiv_norm_profile_batch",
      "tokenize and apply the resource's documented preprocessing first")
    terms
  })
  shared <- .lexnorm_batch_prepare_shared(
    norms,
    key,
    measure_specs,
    resource,
    weightings
  )
  budget <- .lexnorm_batch_row_budget(
    batch$terms,
    shared$measure_specs,
    shared$weightings,
    max_rows
  )
  prototype <- .lexnorm_batch_profile_prepared(character(), shared)
  profiles <- lapply(batch$terms, .lexnorm_batch_profile_prepared, shared = shared)
  summary <- .lexnorm_batch_bind_component(profiles, batch$ids, "summary", prototype)
  lookup <- .lexnorm_batch_bind_component(profiles, batch$ids, "lookup", prototype)
  coverage <- .lexnorm_batch_bind_component(profiles, batch$ids, "coverage", prototype)

  document_diagnostics <- data.frame(
    document_id = batch$ids,
    status = vapply(profiles, `[[`, character(1L), "status"),
    input_terms = as.double(budget$term_counts),
    input_types = vapply(batch$terms, function(terms) {
      as.double(length(unique(terms)))
    }, numeric(1L)),
    planned_lookup_rows = as.double(budget$per_document_lookup),
    planned_summary_rows = as.double(budget$per_document_summary),
    planned_coverage_rows = as.double(budget$per_document_coverage),
    planned_result_rows = as.double(budget$per_document_total),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  provenance <- list(
    contract_id = .lexnorm_contract_id,
    contract_version = .lexnorm_contract_version,
    result_schema_id = .lexnorm_result_schema_id,
    result_schema_version = .lexnorm_result_schema_version,
    resource = shared$resource,
    measure_specs = shared$measure_specs,
    statistic_id = .lexnorm_statistic_id,
    matching_id = .lexnorm_matching_id,
    query_normalization_id = .lexnorm_query_normalization_id,
    type_identity = "exact_lookup_term",
    weightings = shared$weightings,
    batch_contract_id = .lexnorm_batch_contract_id,
    batch_contract_version = .lexnorm_batch_contract_version,
    batch_result_schema_id = .lexnorm_batch_schema_id,
    batch_result_schema_version = .lexnorm_batch_schema_version,
    document_count = as.double(length(batch$ids)),
    document_ids = batch$ids
  )

  diagnostics <- list(
    documents = document_diagnostics,
    batch = list(
      document_count = as.double(length(batch$ids)),
      resource_rows = as.double(nrow(shared$norms)),
      measure_count = as.double(nrow(shared$measure_specs)),
      weighting_count = as.double(length(shared$weightings)),
      unused_norm_column_count = as.double(length(setdiff(
        names(shared$norms),
        c(shared$key, shared$measure_specs$value_column)
      ))),
      planned_lookup_rows = as.double(budget$planned_lookup_rows),
      planned_summary_rows = as.double(budget$planned_summary_rows),
      planned_coverage_rows = as.double(budget$planned_coverage_rows),
      planned_result_rows = as.double(budget$planned_result_rows),
      max_rows = budget$max_rows,
      document_order_preserved = TRUE,
      input_order_preserved_in_lookup = TRUE,
      resource_row_order_affects_result = FALSE,
      oov_imputation = FALSE,
      missing_value_imputation = FALSE,
      automatic_coverage_threshold = FALSE,
      document_pooling = FALSE,
      composite_score = FALSE,
      parallel_execution = FALSE,
      runtime_network_access = FALSE
    )
  )

  structure(
    list(
      status = if (length(batch$ids)) "ok" else "empty",
      summary = summary,
      lookup = lookup,
      coverage = coverage,
      provenance = provenance,
      diagnostics = diagnostics
    ),
    class = "lexdiv_norm_profile_batch"
  )
}

print.lexdiv_norm_profile_batch <- function(x, ...) {
  if (!inherits(x, "lexdiv_norm_profile_batch") || !is.list(x)) {
    stop("x must be a lexdiv_norm_profile_batch object.", call. = FALSE)
  }
  resource <- x$provenance$resource
  cat(sprintf(
    paste0(
      "<lexdiv_norm_profile_batch: %s; %d document%s; %s@%s; ",
      "%d measure%s; %d summary row%s; %d lookup row%s; schema %s>\n"
    ),
    x$status,
    x$provenance$document_count,
    if (x$provenance$document_count == 1) "" else "s",
    resource$resource_id,
    resource$resource_version,
    x$diagnostics$batch$measure_count,
    if (x$diagnostics$batch$measure_count == 1) "" else "s",
    nrow(x$summary),
    if (nrow(x$summary) == 1L) "" else "s",
    nrow(x$lookup),
    if (nrow(x$lookup) == 1L) "" else "s",
    x$provenance$batch_result_schema_version
  ))
  visible <- c(
    "document_id", "measure_id", "weighting", "estimate", "status",
    "missing_reason", "resource_coverage", "annotation_coverage"
  )
  shown <- utils::head(x$summary[visible], 12L)
  print.data.frame(shown, row.names = FALSE, ...)
  omitted <- nrow(x$summary) - nrow(shown)
  if (omitted > 0L) {
    cat(sprintf(
      "... %d additional summary row%s omitted\n",
      omitted,
      if (omitted == 1L) "" else "s"
    ))
  }
  cat("Means remain document-specific and conditional; inspect $coverage.\n")
  invisible(x)
}
