# Internal implementations of the contract's basic lexical-diversity metrics.
#
# These functions deliberately accept precomputed counts.  The package-level
# dispatcher can therefore validate and count a document once before evaluating
# several metrics.  Direct calls remain useful in focused tests: when `counts`
# is NULL, the shared .lex_counts() helper is used.

.basic_metric_counts <- function(tokens, counts) {
  if (is.null(counts)) {
    counts <- .lex_counts(tokens)
  }

  required <- c("N", "V", "freq", "M2")
  if (!is.list(counts) || !all(required %in% names(counts))) {
    stop(
      "`counts` must be NULL or a named list containing N, V, freq, and M2.",
      call. = FALSE
    )
  }
  counts
}

.basic_empty_parameters <- function(parameters) {
  if (!is.list(parameters) || is.data.frame(parameters)) {
    stop("`parameters` must be a named list.", call. = FALSE)
  }
  if (length(parameters) != 0L) {
    stop("This metric does not accept parameters.", call. = FALSE)
  }
  list()
}

.basic_positive_integer_parameter <- function(parameters, name, default) {
  if (!is.list(parameters) || is.data.frame(parameters)) {
    stop("`parameters` must be a named list.", call. = FALSE)
  }

  parameter_names <- names(parameters)
  if (length(parameters) > 0L &&
      (is.null(parameter_names) || anyNA(parameter_names) ||
       any(parameter_names == "") || anyDuplicated(parameter_names))) {
    stop("Every parameter must have one unique, non-empty name.", call. = FALSE)
  }

  unknown <- setdiff(parameter_names, name)
  if (length(unknown) > 0L) {
    stop(
      sprintf("Unknown parameter%s: %s.",
              if (length(unknown) == 1L) "" else "s",
              paste(unknown, collapse = ", ")),
      call. = FALSE
    )
  }

  value <- if (name %in% parameter_names) parameters[[name]] else default
  valid <- is.numeric(value) && !is.object(value) && is.null(dim(value)) &&
    length(value) == 1L && !is.na(value) && is.finite(value) && value >= 1 &&
    value == floor(value)
  if (!valid) {
    stop(
      sprintf("`%s` must be one finite numeric scalar with an integer value >= 1.",
              name),
      call. = FALSE
    )
  }

  # Keep the value numeric rather than coercing through 32-bit R integers.
  # This avoids silent overflow for a valid, very large requested length; such
  # a request will simply fail the N >= requested-length domain check.
  value
}

.basic_empty_input <- function(metric_id, method_id, requested_parameters,
                               counts, quality_floor_tokens) {
  .lex_missing(
    metric_id = metric_id,
    method_id = method_id,
    missing_reason = "empty_input",
    requested_parameters = requested_parameters,
    effective_parameters = list(),
    counts = counts,
    quality_floor_tokens = quality_floor_tokens,
    diagnostics = list()
  )
}

.metric_ttr <- function(tokens, counts = NULL, parameters = list()) {
  parameters <- .basic_empty_parameters(parameters)
  counts <- .basic_metric_counts(tokens, counts)
  if (counts$N == 0) {
    return(.basic_empty_input(
      "ttr", "ttr_v_over_n_v1", parameters, counts, 1
    ))
  }

  .lex_ok(
    metric_id = "ttr",
    method_id = "ttr_v_over_n_v1",
    value = counts$V / counts$N,
    requested_parameters = parameters,
    effective_parameters = parameters,
    counts = counts,
    quality_floor_tokens = 1,
    diagnostics = list()
  )
}

.metric_rttr <- function(tokens, counts = NULL, parameters = list()) {
  parameters <- .basic_empty_parameters(parameters)
  counts <- .basic_metric_counts(tokens, counts)
  if (counts$N == 0) {
    return(.basic_empty_input(
      "rttr", "rttr_guiraud_v_over_sqrt_n_v1", parameters, counts, 1
    ))
  }

  .lex_ok(
    metric_id = "rttr",
    method_id = "rttr_guiraud_v_over_sqrt_n_v1",
    value = counts$V / sqrt(counts$N),
    requested_parameters = parameters,
    effective_parameters = parameters,
    counts = counts,
    quality_floor_tokens = 1,
    diagnostics = list()
  )
}

.metric_cttr <- function(tokens, counts = NULL, parameters = list()) {
  parameters <- .basic_empty_parameters(parameters)
  counts <- .basic_metric_counts(tokens, counts)
  if (counts$N == 0) {
    return(.basic_empty_input(
      "cttr", "cttr_v_over_sqrt_2n_v1", parameters, counts, 1
    ))
  }

  .lex_ok(
    metric_id = "cttr",
    method_id = "cttr_v_over_sqrt_2n_v1",
    value = counts$V / sqrt(2 * counts$N),
    requested_parameters = parameters,
    effective_parameters = parameters,
    counts = counts,
    quality_floor_tokens = 1,
    diagnostics = list()
  )
}

.metric_herdan <- function(tokens, counts = NULL, parameters = list()) {
  parameters <- .basic_empty_parameters(parameters)
  counts <- .basic_metric_counts(tokens, counts)
  if (counts$N == 0) {
    return(.basic_empty_input(
      "herdan", "herdan_c_logv_over_logn_v1", parameters, counts, 2
    ))
  }
  if (counts$N <= 1) {
    return(.lex_missing(
      metric_id = "herdan",
      method_id = "herdan_c_logv_over_logn_v1",
      missing_reason = "insufficient_tokens_for_formula",
      requested_parameters = parameters,
      effective_parameters = list(),
      counts = counts,
      quality_floor_tokens = 2,
      diagnostics = list()
    ))
  }

  .lex_ok(
    metric_id = "herdan",
    method_id = "herdan_c_logv_over_logn_v1",
    value = log(counts$V) / log(counts$N),
    requested_parameters = parameters,
    effective_parameters = parameters,
    counts = counts,
    quality_floor_tokens = 2,
    diagnostics = list()
  )
}

.metric_maas <- function(tokens, counts = NULL, parameters = list()) {
  parameters <- .basic_empty_parameters(parameters)
  counts <- .basic_metric_counts(tokens, counts)
  if (counts$N == 0) {
    return(.basic_empty_input(
      "maas", "maas_a2_ln_v1", parameters, counts, 2
    ))
  }
  if (counts$N <= 1) {
    return(.lex_missing(
      metric_id = "maas",
      method_id = "maas_a2_ln_v1",
      missing_reason = "insufficient_tokens_for_formula",
      requested_parameters = parameters,
      effective_parameters = list(),
      counts = counts,
      quality_floor_tokens = 2,
      diagnostics = list()
    ))
  }

  log_n <- log(counts$N)
  .lex_ok(
    metric_id = "maas",
    method_id = "maas_a2_ln_v1",
    value = (log_n - log(counts$V)) / (log_n^2),
    requested_parameters = parameters,
    effective_parameters = parameters,
    counts = counts,
    quality_floor_tokens = 2,
    diagnostics = list()
  )
}

.metric_msttr <- function(tokens, counts = NULL, parameters = list()) {
  segment_length <- .basic_positive_integer_parameter(
    parameters, "segment_length", 50
  )
  requested <- list(segment_length = segment_length)
  counts <- .basic_metric_counts(tokens, counts)
  if (counts$N == 0) {
    return(.basic_empty_input(
      "msttr", "msttr_nonoverlap_complete_drop_v1", requested, counts, 50
    ))
  }
  if (counts$N < segment_length) {
    return(.lex_missing(
      metric_id = "msttr",
      method_id = "msttr_nonoverlap_complete_drop_v1",
      missing_reason = "too_short_for_requested_parameter",
      requested_parameters = requested,
      effective_parameters = list(),
      counts = counts,
      quality_floor_tokens = 50,
      diagnostics = list()
    ))
  }

  segment_count <- floor(counts$N / segment_length)
  ttr_sum <- 0
  for (segment in seq_len(segment_count)) {
    first <- (segment - 1) * segment_length + 1
    last <- first + segment_length - 1
    ttr_sum <- ttr_sum + length(unique(tokens[first:last])) / segment_length
  }

  .lex_ok(
    metric_id = "msttr",
    method_id = "msttr_nonoverlap_complete_drop_v1",
    value = ttr_sum / segment_count,
    requested_parameters = requested,
    effective_parameters = requested,
    counts = counts,
    quality_floor_tokens = 50,
    diagnostics = list()
  )
}

.metric_mattr <- function(tokens, counts = NULL, parameters = list()) {
  window_length <- .basic_positive_integer_parameter(
    parameters, "window_length", 50
  )
  requested <- list(window_length = window_length)
  counts <- .basic_metric_counts(tokens, counts)
  if (counts$N == 0) {
    return(.basic_empty_input(
      "mattr", "mattr_sliding_step1_v1", requested, counts, 50
    ))
  }
  if (counts$N < window_length) {
    return(.lex_missing(
      metric_id = "mattr",
      method_id = "mattr_sliding_step1_v1",
      missing_reason = "too_short_for_requested_parameter",
      requested_parameters = requested,
      effective_parameters = list(),
      counts = counts,
      quality_floor_tokens = 50,
      diagnostics = list()
    ))
  }

  # Convert exact token identities to integer IDs once, then update the number
  # of distinct types in O(1) per one-token slide.
  token_ids <- match(tokens, unique(tokens))
  type_count <- max(token_ids)
  first_window <- seq_len(window_length)
  window_frequencies <- tabulate(token_ids[first_window], nbins = type_count)
  distinct <- as.double(sum(window_frequencies > 0))
  distinct_sum <- distinct
  window_count <- counts$N - window_length + 1

  if (window_count > 1) {
    for (start in seq.int(2, window_count)) {
      outgoing <- token_ids[start - 1]
      window_frequencies[outgoing] <- window_frequencies[outgoing] - 1
      if (window_frequencies[outgoing] == 0) {
        distinct <- distinct - 1
      }

      incoming <- token_ids[start + window_length - 1]
      if (window_frequencies[incoming] == 0) {
        distinct <- distinct + 1
      }
      window_frequencies[incoming] <- window_frequencies[incoming] + 1
      distinct_sum <- distinct_sum + distinct
    }
  }

  .lex_ok(
    metric_id = "mattr",
    method_id = "mattr_sliding_step1_v1",
    value = distinct_sum / (window_count * window_length),
    requested_parameters = requested,
    effective_parameters = requested,
    counts = counts,
    quality_floor_tokens = 50,
    diagnostics = list()
  )
}
