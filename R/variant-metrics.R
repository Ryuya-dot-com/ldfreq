# Explicit comparison variants for Maas and sequential MTLD.
#
# These methods live outside the frozen eleven-method core. They provide a
# bounded sensitivity surface without changing lexdiv_metrics(), its defaults,
# or its result contract.

.lexvariant_contract_id <- "ldfreq-lexical-diversity-variants"
.lexvariant_contract_version <- "0.1.0"
.lexvariant_max_thresholds <- 16L

.lexvariant_catalog <- list(
  maas_a2_ln_v1 = list(
    family = "maas",
    direction = "lower",
    scale = "a-squared",
    log_base = "e",
    reference_label = "ldfreq-core:maas",
    comparison_scope = "ldfreq-core-method"
  ),
  maas_a_ln_v1 = list(
    family = "maas",
    direction = "lower",
    scale = "a",
    log_base = "e",
    reference_label = "common-formula:maas-a-ln",
    comparison_scope = "formula-comparison-only"
  ),
  maas_a2_log10_v1 = list(
    family = "maas",
    direction = "lower",
    scale = "a-squared",
    log_base = "10",
    reference_label = "TAALED-0.32:maas",
    comparison_scope =
      "formula-aligned-with-taaled-0.32-maas-not-full-pipeline-compatibility"
  ),
  maas_a_log10_v1 = list(
    family = "maas",
    direction = "lower",
    scale = "a",
    log_base = "10",
    reference_label = "common-formula:maas-a-log10",
    comparison_scope = "formula-comparison-only"
  ),
  mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1 = list(
    family = "mtld",
    direction = "higher",
    scale = "tokens-per-factor",
    aggregation = "directional-score-mean",
    final_token_rule = "evaluate-closure-before-tail",
    reference_label = "ldfreq-core:mtld",
    comparison_scope = "ldfreq-core-method"
  ),
  mtld_seq_bidir_dirmean_lt_min10_finaltail_linear_v1 = list(
    family = "mtld",
    direction = "higher",
    scale = "tokens-per-factor",
    aggregation = "directional-score-mean",
    final_token_rule = "always-record-final-sequence-as-tail",
    reference_label = "TAALED-0.32:mtldo",
    comparison_scope =
      "factorization-and-aggregation-comparator-for-taaled-0.32-not-official-compatibility"
  ),
  mtld_seq_bidir_mfl_dirmean_lt_min10_finaltail_linear_v1 = list(
    family = "mtld",
    direction = "higher",
    scale = "adjusted-factor-length",
    aggregation = "directional-mean-factor-length-mean",
    final_token_rule = "always-record-final-sequence-as-tail",
    reference_label = "TAALED-0.32:mtldav",
    comparison_scope =
      "factorization-and-aggregation-comparator-for-taaled-0.32-not-official-compatibility"
  ),
  mtld_seq_bidir_mfl_pooled_lt_min10_finaltail_linear_v1 = list(
    family = "mtld",
    direction = "higher",
    scale = "adjusted-factor-length",
    aggregation = "pooled-mean-factor-length",
    final_token_rule = "always-record-final-sequence-as-tail",
    reference_label = "TAALED-0.32:mtld",
    comparison_scope =
      "factorization-and-aggregation-comparator-for-taaled-0.32-not-official-compatibility"
  )
)

#' List supported Maas and MTLD comparison variants
#'
#' @return A data frame describing every method accepted by
#'   [lexdiv_variant_metrics()]. Formula-level references to another tool do
#'   not assert tokenizer, missing-value, or end-to-end compatibility.
#' @export
lexdiv_variant_ids <- function() {
  methods <- .lexvariant_catalog
  output <- data.frame(
    family = vapply(methods, `[[`, character(1L), "family"),
    method_id = names(methods),
    direction = vapply(methods, `[[`, character(1L), "direction"),
    scale = vapply(methods, `[[`, character(1L), "scale"),
    reference_label = vapply(
      methods,
      `[[`,
      character(1L),
      "reference_label"
    ),
    comparison_scope = vapply(
      methods,
      `[[`,
      character(1L),
      "comparison_scope"
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  row.names(output) <- NULL
  output
}

.lexvariant_validate_methods <- function(variants) {
  if (
    !is.character(variants) || is.object(variants) || !is.null(dim(variants)) ||
      !is.null(attributes(variants)) || length(variants) == 0L ||
      anyNA(variants) || any(!nzchar(variants)) || anyDuplicated(variants)
  ) {
    stop(
      "variants must be a plain, non-empty, duplicate-free character vector.",
      call. = FALSE
    )
  }
  unknown <- setdiff(variants, names(.lexvariant_catalog))
  if (length(unknown)) {
    stop(
      sprintf("Unknown variant ID(s): %s.", paste(unknown, collapse = ", ")),
      call. = FALSE
    )
  }
  variants
}

.lexvariant_validate_thresholds <- function(thresholds) {
  if (
    !is.numeric(thresholds) || is.object(thresholds) ||
      !is.null(dim(thresholds)) || !is.null(attributes(thresholds)) ||
      length(thresholds) == 0L || length(thresholds) > .lexvariant_max_thresholds ||
      anyNA(thresholds) || any(!is.finite(thresholds)) ||
      any(thresholds <= 0 | thresholds >= 1) || anyDuplicated(thresholds)
  ) {
    stop(
      sprintf(
        "mtld_thresholds must contain 1 to %d distinct finite numbers strictly between 0 and 1.",
        .lexvariant_max_thresholds
      ),
      call. = FALSE
    )
  }
  as.double(thresholds)
}

.lexvariant_mtld_factorize <- function(token_ids, threshold) {
  token_count <- length(token_ids)
  lengths <- integer()
  proportions <- numeric()
  is_tail <- logical()
  factor_length <- 0L
  factor_type_count <- 0L
  seen_generation <- integer(max(token_ids))
  generation <- 1L

  for (position in seq_len(token_count)) {
    token_id <- token_ids[[position]]
    factor_length <- factor_length + 1L
    if (seen_generation[[token_id]] != generation) {
      seen_generation[[token_id]] <- generation
      factor_type_count <- factor_type_count + 1L
    }
    factor_ttr <- factor_type_count / factor_length
    final_token <- position == token_count

    if (final_token) {
      lengths <- c(lengths, factor_length)
      proportions <- c(
        proportions,
        (1 - factor_ttr) / (1 - threshold)
      )
      is_tail <- c(is_tail, TRUE)
    } else if (factor_length >= 10L && factor_ttr < threshold) {
      lengths <- c(lengths, factor_length)
      proportions <- c(proportions, 1)
      is_tail <- c(is_tail, FALSE)
      factor_length <- 0L
      factor_type_count <- 0L
      generation <- generation + 1L
    }
  }
  list(
    lengths = lengths,
    proportions = proportions,
    is_tail = is_tail
  )
}

.lexvariant_adjusted_lengths <- function(direction) {
  eligible <- is.finite(direction$proportions) & direction$proportions > 0
  direction$lengths[eligible] / direction$proportions[eligible]
}

.lexvariant_mtld_diagnostics <- function(forward, reverse, aggregation) {
  list(
    aggregation = aggregation,
    minimum_complete_factor_length = 10L,
    threshold_comparison = "strict-less-than",
    final_token_rule = "always-record-final-sequence-as-tail",
    forward_factor_lengths = forward$lengths,
    forward_factor_proportions = forward$proportions,
    forward_is_tail = forward$is_tail,
    reverse_factor_lengths = reverse$lengths,
    reverse_factor_proportions = reverse$proportions,
    reverse_is_tail = reverse$is_tail
  )
}

.lexvariant_mtld_value <- function(method_id, tokens, threshold) {
  token_ids <- match(tokens, unique(tokens))
  forward <- .lexvariant_mtld_factorize(token_ids, threshold)
  reverse <- .lexvariant_mtld_factorize(rev(token_ids), threshold)
  method <- .lexvariant_catalog[[method_id]]
  aggregation <- method$aggregation

  if (identical(aggregation, "directional-score-mean")) {
    denominators <- c(sum(forward$proportions), sum(reverse$proportions))
    value <- if (all(is.finite(denominators) & denominators > 0)) {
      mean(length(tokens) / denominators)
    } else {
      NA_real_
    }
  } else {
    forward_lengths <- .lexvariant_adjusted_lengths(forward)
    reverse_lengths <- .lexvariant_adjusted_lengths(reverse)
    if (identical(aggregation, "directional-mean-factor-length-mean")) {
      value <- if (length(forward_lengths) && length(reverse_lengths)) {
        mean(c(mean(forward_lengths), mean(reverse_lengths)))
      } else {
        NA_real_
      }
    } else {
      pooled <- c(forward_lengths, reverse_lengths)
      value <- if (length(pooled)) mean(pooled) else NA_real_
    }
  }

  list(
    value = value,
    diagnostics = .lexvariant_mtld_diagnostics(
      forward,
      reverse,
      aggregation
    )
  )
}

.lexvariant_maas_value <- function(method_id, counts) {
  method <- .lexvariant_catalog[[method_id]]
  log_function <- if (identical(method$log_base, "10")) log10 else log
  log_n <- log_function(counts$N)
  a_squared <- (log_n - log_function(counts$V)) / (log_n^2)
  value <- if (identical(method$scale, "a")) sqrt(a_squared) else a_squared
  list(
    value = value,
    diagnostics = list(
      formula_scale = method$scale,
      log_base = method$log_base
    )
  )
}

.lexvariant_record <- function(
    method_id,
    parameters,
    counts,
    input_state,
    tokens = NULL) {
  method <- .lexvariant_catalog[[method_id]]
  family <- method$family
  missing_reason <- NA_character_
  status <- "ok"
  value <- NA_real_
  diagnostics <- list()

  if (identical(input_state, "invalid_token")) {
    status <- "invalid_input"
    missing_reason <- "invalid_token"
  } else if (identical(input_state, "empty_input")) {
    status <- "missing"
    missing_reason <- "empty_input"
  } else if (identical(family, "maas") && counts$N <= 1L) {
    status <- "missing"
    missing_reason <- "insufficient_tokens_for_formula"
  } else if (identical(family, "mtld") && counts$N < 10L) {
    status <- "missing"
    missing_reason <- "insufficient_tokens_for_formula"
  } else if (identical(
    method_id,
    "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1"
  )) {
    core <- .metric_mtld(tokens, counts, parameters)
    value <- core$value
    status <- core$status
    missing_reason <- core$missing_reason
    diagnostics <- core$diagnostics
  } else if (identical(family, "mtld")) {
    computed <- .lexvariant_mtld_value(
      method_id,
      tokens,
      parameters$threshold
    )
    value <- computed$value
    diagnostics <- computed$diagnostics
    if (!is.finite(value)) {
      value <- NA_real_
      status <- "missing"
      missing_reason <- "no_factor"
    }
  } else {
    computed <- .lexvariant_maas_value(method_id, counts)
    value <- computed$value
    diagnostics <- computed$diagnostics
  }

  list(
    family = family,
    method_id = method_id,
    value = as.double(value),
    status = status,
    missing_reason = missing_reason,
    requested_parameters = parameters,
    N = counts$N,
    V = counts$V,
    direction = method$direction,
    scale = method$scale,
    reference_label = method$reference_label,
    comparison_scope = method$comparison_scope,
    diagnostics = diagnostics
  )
}

.lexvariant_data_frame <- function(records) {
  output <- data.frame(
    family = vapply(records, `[[`, character(1L), "family"),
    method_id = vapply(records, `[[`, character(1L), "method_id"),
    variant_contract_id = rep.int(.lexvariant_contract_id, length(records)),
    variant_contract_version = rep.int(
      .lexvariant_contract_version,
      length(records)
    ),
    value = vapply(records, `[[`, numeric(1L), "value"),
    status = vapply(records, `[[`, character(1L), "status"),
    missing_reason = vapply(records, `[[`, character(1L), "missing_reason"),
    N = vapply(records, function(record) as.double(record$N), numeric(1L)),
    V = vapply(records, function(record) as.double(record$V), numeric(1L)),
    direction = vapply(records, `[[`, character(1L), "direction"),
    scale = vapply(records, `[[`, character(1L), "scale"),
    reference_label = vapply(
      records,
      `[[`,
      character(1L),
      "reference_label"
    ),
    comparison_scope = vapply(
      records,
      `[[`,
      character(1L),
      "comparison_scope"
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  output$requested_parameters <- I(lapply(
    records,
    `[[`,
    "requested_parameters"
  ))
  output$diagnostics <- I(lapply(records, `[[`, "diagnostics"))
  output <- output[c(
    "family", "method_id", "variant_contract_id",
    "variant_contract_version", "value", "status", "missing_reason",
    "requested_parameters", "N", "V", "direction", "scale",
    "reference_label",
    "comparison_scope", "diagnostics"
  )]
  row.names(output) <- NULL
  class(output) <- c("lexdiv_variant_results", "data.frame")
  output
}

#' Compute explicit Maas and sequential-MTLD variants
#'
#' Computes a bounded set of formula and aggregation variants without changing
#' the frozen [lexdiv_metrics()] core. Multiple MTLD thresholds are expanded in
#' request order. TAALED-relevant rows describe formula/factorization scope only
#' and do not claim end-to-end compatibility with its preprocessing, missing-
#' value behavior, or licensed implementation.
#'
#' The installed `lexical-diversity-variant-contract.json` file records every
#' exact Maas formula, log base, MTLD tail rule, and aggregation identity.
#'
#' @param tokens Input accepted by [lexdiv_metrics()].
#' @param variants A plain, non-empty, duplicate-free vector selected from the
#'   `method_id` column of [lexdiv_variant_ids()].
#' @param mtld_thresholds One to 16 distinct MTLD thresholds strictly between
#'   zero and one. Each requested MTLD method is expanded over this vector.
#'
#' @return A `lexdiv_variant_results` long data frame. Maas rows occur once per
#'   method; MTLD rows occur once per method-threshold combination.
#' @export
lexdiv_variant_metrics <- function(
    tokens,
    variants = lexdiv_variant_ids()$method_id,
    mtld_thresholds = 0.72) {
  variants <- .lexvariant_validate_methods(variants)
  thresholds <- .lexvariant_validate_thresholds(mtld_thresholds)

  .lex_warn_likely_raw_text(
    tokens,
    "tokens",
    "lexdiv_variant_metrics",
    "tokenize the text with lexdiv_tokenize() first"
  )

  input_state <- .lex_input_state(tokens)
  if (identical(input_state, "ok")) {
    tokens <- .lex_canonicalize_encoding(tokens)
  }
  counts <- if (identical(input_state, "invalid_token")) {
    .lex_invalid_counts()
  } else {
    .lex_counts(tokens)
  }

  records <- list()
  for (method_id in variants) {
    method <- .lexvariant_catalog[[method_id]]
    parameters <- if (identical(method$family, "mtld")) {
      lapply(thresholds, function(threshold) list(threshold = threshold))
    } else {
      list(list())
    }
    for (parameter in parameters) {
      records[[length(records) + 1L]] <- .lexvariant_record(
        method_id = method_id,
        parameters = parameter,
        counts = counts,
        input_state = input_state,
        tokens = tokens
      )
    }
  }
  .lexvariant_data_frame(records)
}

#' @export
print.lexdiv_variant_results <- function(x, ...) {
  cat(sprintf(
    "<lexdiv_variant_results: %d row%s; contract %s>\n",
    nrow(x),
    if (nrow(x) == 1L) "" else "s",
    .lexvariant_contract_version
  ))
  visible <- intersect(
    c(
      "family", "method_id", "reference_label", "value", "status",
      "missing_reason", "N", "V"
    ),
    names(x)
  )
  print.data.frame(x[visible], ...)
  invisible(x)
}
