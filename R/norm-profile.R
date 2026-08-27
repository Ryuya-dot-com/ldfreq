# Profiles from caller-supplied lexical norm tables.

.lexnorm_contract_id <- "ldfreq-generic-norm-profile"
.lexnorm_contract_version <- "0.1.0"
.lexnorm_result_schema_id <- "generic-norm-profile-result"
.lexnorm_result_schema_version <- "0.1.0"
.lexnorm_statistic_id <- "arithmetic_mean_observed_matched_only_v1"
.lexnorm_matching_id <- "exact-unicode-scalar-sequence-v1"
.lexnorm_query_normalization_id <- "identity-valid-utf8-v1"
.lexnorm_maximum_measures <- 128L
.lexnorm_weightings <- c("token", "type")
.lexnorm_directions <- c("higher", "lower", "descriptive")
.lexnorm_measure_fields <- c(
  "measure_id", "value_column", "construct_id", "value_unit", "direction",
  "language", "variety", "population_id", "collection_year", "valid_min",
  "valid_max"
)
.lexnorm_resource_fields <- c(
  "resource_id", "resource_version", "creator", "source_reference",
  "data_license", "transformation_id", "lookup_unit",
  "resource_key_normalization_id"
)

.lexnorm_stop <- function(...) {
  stop(sprintf(...), call. = FALSE)
}

.lexnorm_plain_character <- function(value, argument, allow_zero = FALSE) {
  if (
    !is.character(value) || is.object(value) || !is.null(dim(value)) ||
      !is.null(attributes(value)) || (!allow_zero && length(value) == 0L) ||
      anyNA(value) || any(!nzchar(value)) ||
      any(Encoding(value) %in% c("bytes", "latin1")) ||
      any(!validUTF8(value))
  ) {
    .lexnorm_stop(
      paste(
        "%s must be a plain valid-UTF-8 character vector without missing",
        "or empty values%s."
      ),
      argument,
      if (allow_zero) " (zero length is allowed)" else ""
    )
  }
  Encoding(value) <- "UTF-8"
  value
}

.lexnorm_scalar_string <- function(value, argument) {
  value <- .lexnorm_plain_character(value, argument)
  if (length(value) != 1L) {
    .lexnorm_stop("%s must contain exactly one value.", argument)
  }
  value
}

.lexnorm_identifier <- function(value, argument) {
  value <- .lexnorm_scalar_string(value, argument)
  if (!grepl("^[A-Za-z][A-Za-z0-9._-]*$", value)) {
    .lexnorm_stop(
      "%s must be one ASCII identifier beginning with a letter.",
      argument
    )
  }
  value
}

.lexnorm_plain_list <- function(value, argument) {
  attribute_names <- names(attributes(value))
  valid_attributes <- is.null(attribute_names) ||
    identical(attribute_names, "names")
  if (
    !is.list(value) || is.object(value) || !is.null(dim(value)) ||
      !valid_attributes || is.null(names(value)) || anyNA(names(value)) ||
      any(!nzchar(names(value))) || anyDuplicated(names(value))
  ) {
    .lexnorm_stop(
      "%s must be a plain list with unique non-empty names.",
      argument
    )
  }
  value
}

.lexnorm_plain_data_frame <- function(value, argument) {
  if (!is.data.frame(value) || !identical(class(value), "data.frame")) {
    .lexnorm_stop(
      "%s must be an ordinary data.frame without subclasses.",
      argument
    )
  }
  column_names <- names(value)
  if (
    is.null(column_names) || anyNA(column_names) || any(!nzchar(column_names)) ||
      anyDuplicated(column_names)
  ) {
    .lexnorm_stop("%s must have unique non-empty column names.", argument)
  }
  value
}

.lexnorm_positive_whole <- function(value, argument) {
  if (
    !is.numeric(value) || is.object(value) || !is.null(dim(value)) ||
      !is.null(attributes(value)) || length(value) != 1L || is.na(value) ||
      !is.finite(value) || value < 1 || value != floor(value)
  ) {
    .lexnorm_stop("%s must be one positive finite whole number.", argument)
  }
  as.double(value)
}

.lexnorm_terms <- function(terms) {
  .lexnorm_plain_character(terms, "terms", allow_zero = TRUE)
}

.lexnorm_resource <- function(resource) {
  resource <- .lexnorm_plain_list(resource, "resource")
  if (!identical(names(resource), .lexnorm_resource_fields)) {
    .lexnorm_stop(
      "resource must contain the exact ordered fields: %s.",
      paste(.lexnorm_resource_fields, collapse = ", ")
    )
  }
  for (field in .lexnorm_resource_fields) {
    resource[[field]] <- .lexnorm_scalar_string(
      resource[[field]],
      sprintf("resource$%s", field)
    )
  }
  resource$resource_id <- .lexnorm_identifier(
    resource$resource_id,
    "resource$resource_id"
  )
  resource
}

.lexnorm_measure_specs <- function(measure_specs) {
  measure_specs <- .lexnorm_plain_data_frame(measure_specs, "measure_specs")
  if (!identical(names(measure_specs), .lexnorm_measure_fields)) {
    .lexnorm_stop(
      "measure_specs must contain the exact ordered columns: %s.",
      paste(.lexnorm_measure_fields, collapse = ", ")
    )
  }
  if (
    nrow(measure_specs) == 0L ||
      nrow(measure_specs) > .lexnorm_maximum_measures
  ) {
    .lexnorm_stop(
      "measure_specs must contain from 1 through %d rows.",
      .lexnorm_maximum_measures
    )
  }

  character_fields <- setdiff(
    .lexnorm_measure_fields,
    c("valid_min", "valid_max")
  )
  for (field in character_fields) {
    measure_specs[[field]] <- .lexnorm_plain_character(
      measure_specs[[field]],
      sprintf("measure_specs$%s", field)
    )
  }
  for (field in c("measure_id", "construct_id")) {
    measure_specs[[field]] <- vapply(
      measure_specs[[field]],
      .lexnorm_identifier,
      character(1L),
      argument = sprintf("measure_specs$%s item", field)
    )
  }
  if (anyDuplicated(measure_specs$measure_id)) {
    .lexnorm_stop("measure_specs$measure_id must contain unique values.")
  }
  if (anyDuplicated(measure_specs$value_column)) {
    .lexnorm_stop("measure_specs$value_column must contain unique values.")
  }
  if (any(!(measure_specs$direction %in% .lexnorm_directions))) {
    .lexnorm_stop(
      "measure_specs$direction must contain only: %s.",
      paste(.lexnorm_directions, collapse = ", ")
    )
  }

  for (field in c("valid_min", "valid_max")) {
    value <- measure_specs[[field]]
    if (
      !is.numeric(value) || is.object(value) || !is.null(dim(value)) ||
        !is.null(attributes(value)) || length(value) != nrow(measure_specs) ||
        any(is.nan(value)) || any(!is.na(value) & !is.finite(value))
    ) {
      .lexnorm_stop(
        "measure_specs$%s must be a plain numeric vector of finite values or NA.",
        field
      )
    }
    measure_specs[[field]] <- as.double(value)
  }
  bounded <- !is.na(measure_specs$valid_min) &
    !is.na(measure_specs$valid_max)
  if (any(
    measure_specs$valid_min[bounded] > measure_specs$valid_max[bounded]
  )) {
    .lexnorm_stop("measure_specs valid_min cannot exceed valid_max.")
  }
  measure_specs
}

.lexnorm_norms <- function(norms, key, measure_specs) {
  norms <- .lexnorm_plain_data_frame(norms, "norms")
  key <- .lexnorm_scalar_string(key, "key")
  if (!(key %in% names(norms))) {
    .lexnorm_stop("key must name one column in norms.")
  }
  value_columns <- measure_specs$value_column
  missing_columns <- setdiff(value_columns, names(norms))
  if (length(missing_columns)) {
    .lexnorm_stop(
      "norms is missing requested value column%s: %s.",
      if (length(missing_columns) == 1L) "" else "s",
      paste(missing_columns, collapse = ", ")
    )
  }
  if (key %in% value_columns) {
    .lexnorm_stop("key cannot also be a requested value_column.")
  }

  norm_keys <- .lexnorm_plain_character(
    norms[[key]],
    sprintf("norms$%s", key),
    allow_zero = TRUE
  )
  if (anyDuplicated(norm_keys)) {
    .lexnorm_stop(
      paste(
        "norms key values must be unique; duplicate exact keys are not",
        "resolved by resource row order."
      )
    )
  }
  norms[[key]] <- norm_keys

  for (index in seq_len(nrow(measure_specs))) {
    column <- value_columns[[index]]
    values <- norms[[column]]
    if (
      !is.numeric(values) || is.object(values) || !is.null(dim(values)) ||
        !is.null(attributes(values)) || length(values) != nrow(norms) ||
        any(is.nan(values)) || any(!is.na(values) & !is.finite(values))
    ) {
      .lexnorm_stop(
        "norms$%s must be a plain numeric vector of finite values or NA.",
        column
      )
    }
    values <- as.double(values)
    observed <- !is.na(values)
    lower <- measure_specs$valid_min[[index]]
    upper <- measure_specs$valid_max[[index]]
    if (!is.na(lower) && any(values[observed] < lower)) {
      .lexnorm_stop("norms$%s contains a value below valid_min.", column)
    }
    if (!is.na(upper) && any(values[observed] > upper)) {
      .lexnorm_stop("norms$%s contains a value above valid_max.", column)
    }
    norms[[column]] <- values
  }
  list(norms = norms, key = key)
}

.lexnorm_requested_weightings <- function(weightings) {
  weightings <- .lexnorm_plain_character(weightings, "weightings")
  if (anyDuplicated(weightings)) {
    .lexnorm_stop("weightings must not contain duplicate values.")
  }
  if (any(!(weightings %in% .lexnorm_weightings))) {
    .lexnorm_stop(
      "weightings must contain only: %s.",
      paste(.lexnorm_weightings, collapse = ", ")
    )
  }
  weightings
}

.lexnorm_row_budget <- function(terms, measure_specs, weightings, max_rows) {
  max_rows <- .lexnorm_positive_whole(max_rows, "max_rows")
  measure_count <- as.double(nrow(measure_specs))
  weighting_count <- as.double(length(weightings))
  lookup_rows <- as.double(length(terms)) * measure_count
  summary_rows <- measure_count * weighting_count
  coverage_rows <- summary_rows
  planned_rows <- lookup_rows + summary_rows + coverage_rows
  if (!is.finite(planned_rows) || planned_rows > max_rows) {
    .lexnorm_stop(
      "planned result rows (%s) exceed max_rows (%s).",
      format(planned_rows, scientific = FALSE, trim = TRUE),
      format(max_rows, scientific = FALSE, trim = TRUE)
    )
  }
  list(
    max_rows = max_rows,
    lookup_rows = lookup_rows,
    summary_rows = summary_rows,
    coverage_rows = coverage_rows,
    planned_rows = planned_rows
  )
}

.lexnorm_empty_lookup <- function() {
  data.frame(
    input_index = integer(),
    term = character(),
    measure_id = character(),
    lookup_status = character(),
    value = double(),
    value_status = character(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexnorm_lookup_long <- function(terms, norms, key, measure_specs) {
  term_count <- length(terms)
  measure_count <- nrow(measure_specs)
  if (!term_count) return(.lexnorm_empty_lookup())

  matched_index <- match(terms, norms[[key]])
  matched <- !is.na(matched_index)
  value_matrix <- matrix(
    NA_real_,
    nrow = term_count,
    ncol = measure_count
  )
  if (any(matched)) {
    for (measure_index in seq_len(measure_count)) {
      column <- measure_specs$value_column[[measure_index]]
      value_matrix[matched, measure_index] <-
        norms[[column]][matched_index[matched]]
    }
  }
  values <- as.double(t(value_matrix))
  matched_long <- rep(matched, each = measure_count)
  observed <- matched_long & !is.na(values)
  value_status <- rep.int("not_applicable_oov", length(values))
  value_status[matched_long] <- "missing_annotation"
  value_status[observed] <- "observed"

  data.frame(
    input_index = rep(seq_along(terms), each = measure_count),
    term = rep(terms, each = measure_count),
    measure_id = rep.int(measure_specs$measure_id, times = term_count),
    lookup_status = ifelse(
      matched_long,
      "matched_resource",
      "unknown_to_resource"
    ),
    value = values,
    value_status = value_status,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexnorm_stable_mean <- function(value) {
  mean(sort(value, method = "radix"))
}

.lexnorm_summary_row <- function(
    terms,
    norms,
    key,
    measure_spec,
    weighting,
    resource,
    result_order) {
  selected_terms <- if (identical(weighting, "token")) {
    terms
  } else {
    terms[!duplicated(terms)]
  }
  input_units <- length(selected_terms)
  matched_index <- match(selected_terms, norms[[key]])
  matched <- !is.na(matched_index)
  matched_units <- sum(matched)
  values <- rep.int(NA_real_, input_units)
  if (matched_units) {
    values[matched] <- norms[[measure_spec$value_column]][matched_index[matched]]
  }
  observed <- matched & !is.na(values)
  observed_units <- sum(observed)

  if (!input_units) {
    status <- "missing"
    missing_reason <- "empty_input"
  } else if (!matched_units) {
    status <- "missing"
    missing_reason <- "no_matched_keys"
  } else if (!observed_units) {
    status <- "missing"
    missing_reason <- "no_observed_values"
  } else {
    status <- "ok"
    missing_reason <- NA_character_
  }

  data.frame(
    result_order = as.integer(result_order),
    resource_id = resource$resource_id,
    resource_version = resource$resource_version,
    measure_id = measure_spec$measure_id,
    construct_id = measure_spec$construct_id,
    value_unit = measure_spec$value_unit,
    direction = measure_spec$direction,
    language = measure_spec$language,
    variety = measure_spec$variety,
    population_id = measure_spec$population_id,
    collection_year = measure_spec$collection_year,
    statistic_id = .lexnorm_statistic_id,
    weighting = weighting,
    type_identity = if (identical(weighting, "type")) {
      "exact_lookup_term"
    } else {
      NA_character_
    },
    estimate = if (identical(status, "ok")) {
      .lexnorm_stable_mean(values[observed])
    } else {
      NA_real_
    },
    status = status,
    missing_reason = missing_reason,
    input_units = as.double(input_units),
    matched_units = as.double(matched_units),
    unmatched_units = as.double(input_units - matched_units),
    observed_value_units = as.double(observed_units),
    matched_missing_value_units = as.double(matched_units - observed_units),
    resource_coverage = if (!input_units) {
      NA_real_
    } else {
      matched_units / input_units
    },
    value_coverage = if (!input_units) {
      NA_real_
    } else {
      observed_units / input_units
    },
    annotation_coverage = if (!matched_units) {
      NA_real_
    } else {
      observed_units / matched_units
    },
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexnorm_summary <- function(
    terms,
    norms,
    key,
    measure_specs,
    weightings,
    resource) {
  row_count <- nrow(measure_specs) * length(weightings)
  rows <- vector("list", row_count)
  result_order <- 0L
  for (measure_index in seq_len(nrow(measure_specs))) {
    for (weighting in weightings) {
      result_order <- result_order + 1L
      rows[[result_order]] <- .lexnorm_summary_row(
        terms = terms,
        norms = norms,
        key = key,
        measure_spec = measure_specs[measure_index, , drop = FALSE],
        weighting = weighting,
        resource = resource,
        result_order = result_order
      )
    }
  }
  output <- do.call(base::rbind.data.frame, rows)
  rownames(output) <- NULL
  output
}

.lexnorm_coverage <- function(summary) {
  fields <- c(
    "result_order", "resource_id", "resource_version", "measure_id",
    "weighting", "input_units", "matched_units", "unmatched_units",
    "observed_value_units", "matched_missing_value_units",
    "resource_coverage", "value_coverage", "annotation_coverage"
  )
  summary[fields]
}

#' Profile terms with caller-supplied lexical norms
#'
#' Computes token- and/or type-weighted arithmetic means for one or more
#' lexical-norm variables. Matching is exact: the function neither tokenizes
#' nor normalizes the supplied terms. Means use observed values from matched
#' keys only. Resource coverage and annotation coverage are therefore returned
#' separately and should accompany every interpretation of an estimate.
#'
#' @param terms A plain character vector with one caller-prepared lookup term
#'   per element. Zero length is allowed. Terms are retained in `lookup`.
#' @param norms An ordinary data frame containing one unique key column and the
#'   numeric norm columns named by `measure_specs`. Other columns are ignored
#'   and are not copied into the result.
#' @param key One string naming the exact-match key column in `norms`.
#' @param measure_specs An ordinary data frame with the exact ordered columns
#'   `measure_id`, `value_column`, `construct_id`, `value_unit`, `direction`,
#'   `language`, `variety`, `population_id`, `collection_year`, `valid_min`,
#'   and `valid_max`. IDs must be unique; `direction` is `"higher"`,
#'   `"lower"`, or `"descriptive"`; numeric bounds may be `NA`.
#' @param resource A plain named list with the exact ordered fields
#'   `resource_id`, `resource_version`, `creator`, `source_reference`,
#'   `data_license`, `transformation_id`, `lookup_unit`, and
#'   `resource_key_normalization_id`. These are caller assertions recorded for
#'   provenance; they do not establish redistribution rights.
#' @param weightings A non-empty subset of `c("token", "type")`, without
#'   duplicates. Type identity is the exact lookup term after no package-side
#'   transformation.
#' @param max_rows A positive whole-number bound on the combined rows planned
#'   for `lookup`, `summary`, and `coverage`, checked before result allocation.
#'
#' @return A `lexdiv_norm_profile` list with `status`, `summary`, `lookup`,
#'   `coverage`, `provenance`, and `diagnostics`. `summary` contains conditional
#'   observed matched-only means and their denominators. `lookup` contains one
#'   input-major, measure-minor row per term and measure. `coverage` is the
#'   analysis-ready denominator projection of `summary`. No missing value is
#'   imputed and no automatic coverage threshold is applied.
#'
#' @details The three coverage rates have different denominators:
#'   `resource_coverage = matched_units / input_units`,
#'   `value_coverage = observed_value_units / input_units`, and
#'   `annotation_coverage = observed_value_units / matched_units`. A matched
#'   key with an `NA` norm is `missing_annotation`; an unmatched key is
#'   `not_applicable_oov`. The function does not infer a universal direction,
#'   compare unlike scales, form composite scores, or approve a data license.
#'
#' @export
lexdiv_norm_profile <- function(
    terms,
    norms,
    key,
    measure_specs,
    resource,
    weightings = c("token", "type"),
    max_rows = 1e6) {
  terms <- .lexnorm_terms(terms)
  .lex_warn_likely_raw_text(
    terms,
    "terms",
    "lexdiv_norm_profile",
    "tokenize and apply the resource's documented preprocessing first"
  )
  measure_specs <- .lexnorm_measure_specs(measure_specs)
  norm_input <- .lexnorm_norms(norms, key, measure_specs)
  norms <- norm_input$norms
  key <- norm_input$key
  resource <- .lexnorm_resource(resource)
  weightings <- .lexnorm_requested_weightings(weightings)
  budget <- .lexnorm_row_budget(terms, measure_specs, weightings, max_rows)

  lookup <- .lexnorm_lookup_long(terms, norms, key, measure_specs)
  summary <- .lexnorm_summary(
    terms,
    norms,
    key,
    measure_specs,
    weightings,
    resource
  )
  coverage <- .lexnorm_coverage(summary)

  structure(
    list(
      status = if (length(terms)) "ok" else "empty",
      summary = summary,
      lookup = lookup,
      coverage = coverage,
      provenance = list(
        contract_id = .lexnorm_contract_id,
        contract_version = .lexnorm_contract_version,
        result_schema_id = .lexnorm_result_schema_id,
        result_schema_version = .lexnorm_result_schema_version,
        resource = resource,
        measure_specs = measure_specs,
        statistic_id = .lexnorm_statistic_id,
        matching_id = .lexnorm_matching_id,
        query_normalization_id = .lexnorm_query_normalization_id,
        type_identity = "exact_lookup_term",
        weightings = weightings
      ),
      diagnostics = list(
        input_terms = as.double(length(terms)),
        input_types = as.double(length(unique(terms))),
        resource_rows = as.double(nrow(norms)),
        measure_count = as.double(nrow(measure_specs)),
        unused_norm_column_count = as.double(length(setdiff(
          names(norms),
          c(key, measure_specs$value_column)
        ))),
        planned_lookup_rows = budget$lookup_rows,
        planned_summary_rows = budget$summary_rows,
        planned_coverage_rows = budget$coverage_rows,
        planned_result_rows = budget$planned_rows,
        max_rows = budget$max_rows,
        input_order_preserved_in_lookup = TRUE,
        resource_row_order_affects_result = FALSE,
        oov_imputation = FALSE,
        missing_value_imputation = FALSE,
        automatic_coverage_threshold = FALSE,
        composite_score = FALSE,
        runtime_network_access = FALSE
      )
    ),
    class = "lexdiv_norm_profile"
  )
}

#' @param x A `lexdiv_norm_profile` object.
#' @param ... Additional arguments passed to [print.data.frame()].
#'
#' @return `print.lexdiv_norm_profile()` returns `x` invisibly.
#' @rdname lexdiv_norm_profile
#' @export
print.lexdiv_norm_profile <- function(x, ...) {
  if (!inherits(x, "lexdiv_norm_profile") || !is.list(x)) {
    stop("x must be a lexdiv_norm_profile object.", call. = FALSE)
  }
  resource <- x$provenance$resource
  cat(sprintf(
    paste0(
      "<lexdiv_norm_profile: %s; %s@%s; %d measure%s; ",
      "%d lookup row%s; schema %s>\n"
    ),
    x$status,
    resource$resource_id,
    resource$resource_version,
    x$diagnostics$measure_count,
    if (x$diagnostics$measure_count == 1) "" else "s",
    nrow(x$lookup),
    if (nrow(x$lookup) == 1L) "" else "s",
    x$provenance$result_schema_version
  ))
  display_limit <- 12L
  visible <- c(
    "measure_id", "weighting", "estimate", "status", "missing_reason",
    "resource_coverage", "annotation_coverage"
  )
  shown <- utils::head(x$summary[visible], display_limit)
  print.data.frame(shown, row.names = FALSE, ...)
  omitted <- nrow(x$summary) - nrow(shown)
  if (omitted > 0L) {
    cat(sprintf("... %d additional summary row%s omitted\n", omitted,
      if (omitted == 1L) "" else "s"))
  }
  cat("Means are conditional on observed matched values; inspect $coverage.\n")
  invisible(x)
}
