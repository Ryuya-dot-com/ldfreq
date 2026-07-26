# Internal implementation of the frozen MTLD variant.
#
# This implementation follows the package's metric contract. In particular,
# the threshold comparison is strict, complete factors require ten tokens, the
# final-tail credit is not clamped, and directional scores are averaged.

.mtld_diagnostics <- function(forward, reverse) {
  list(
    forward_score = forward$score,
    reverse_score = reverse$score,
    forward_complete_factors = forward$complete_factors,
    reverse_complete_factors = reverse$complete_factors,
    forward_tail_credit = forward$tail_credit,
    reverse_tail_credit = reverse$tail_credit
  )
}

.mtld_unavailable_diagnostics <- function() {
  list(
    forward_score = NA_real_,
    reverse_score = NA_real_,
    forward_complete_factors = NA_integer_,
    reverse_complete_factors = NA_integer_,
    forward_tail_credit = NA_real_,
    reverse_tail_credit = NA_real_
  )
}

.mtld_direction <- function(token_ids, threshold) {
  n <- length(token_ids)
  complete_factors <- 0L
  factor_length <- 0L
  factor_type_count <- 0L
  seen_generation <- integer(if (n == 0L) 0L else max(token_ids))
  generation <- 1L

  for (token_id in token_ids) {
    factor_length <- factor_length + 1L
    if (seen_generation[[token_id]] != generation) {
      seen_generation[[token_id]] <- generation
      factor_type_count <- factor_type_count + 1L
    }

    running_ttr <- factor_type_count / factor_length
    if (factor_length >= 10L && running_ttr < threshold) {
      complete_factors <- complete_factors + 1L
      factor_length <- 0L
      factor_type_count <- 0L
      if (generation == .Machine$integer.max) {
        seen_generation[] <- 0L
        generation <- 1L
      } else {
        generation <- generation + 1L
      }
    }
  }

  tail_credit <- 0
  if (factor_length > 0L) {
    tail_ttr <- factor_type_count / factor_length
    tail_credit <- (1 - tail_ttr) / (1 - threshold)
  }

  factor_denominator <- complete_factors + tail_credit
  score <- if (is.finite(factor_denominator) && factor_denominator > 0) {
    n / factor_denominator
  } else {
    NA_real_
  }

  list(
    score = score,
    complete_factors = complete_factors,
    tail_credit = tail_credit
  )
}

.mtld_parameters <- function(parameters = list()) {
  if (is.null(parameters)) {
    parameters <- list()
  }
  if (!is.list(parameters)) {
    stop("`parameters` must be a named list.", call. = FALSE)
  }
  parameter_names <- names(parameters)
  if (length(parameters) > 0L &&
      (is.null(parameter_names) || anyNA(parameter_names) ||
       any(parameter_names == "") || anyDuplicated(parameter_names))) {
    stop("`parameters` must be a uniquely named list.", call. = FALSE)
  }
  unsupported <- setdiff(parameter_names, "threshold")
  if (length(unsupported) > 0L) {
    stop(
      sprintf(
        "Unsupported MTLD parameter%s: %s. Only `threshold` is user-settable.",
        if (length(unsupported) == 1L) "" else "s",
        paste(unsupported, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  threshold <- if ("threshold" %in% parameter_names) {
    parameters[["threshold", exact = TRUE]]
  } else {
    0.72
  }
  if (!is.numeric(threshold) || is.object(threshold) || !is.null(dim(threshold)) ||
      length(threshold) != 1L ||
      is.na(threshold) || !is.finite(threshold) ||
      threshold <= 0 || threshold >= 1) {
    stop("`threshold` must be one finite number strictly between 0 and 1.", call. = FALSE)
  }
  list(threshold = as.double(threshold))
}

.metric_mtld <- function(tokens, counts = NULL, parameters = list()) {
  if (is.null(counts)) {
    counts <- .lex_counts(tokens)
  }
  reported_parameters <- .mtld_parameters(parameters)
  threshold <- reported_parameters$threshold

  if (counts$N == 0L) {
    return(.lex_missing(
      metric_id = "mtld",
      method_id = "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1",
      missing_reason = "empty_input",
      requested_parameters = reported_parameters,
      counts = counts,
      quality_floor_tokens = 50L,
      diagnostics = .mtld_unavailable_diagnostics()
    ))
  }

  if (counts$N < 10L) {
    return(.lex_missing(
      metric_id = "mtld",
      method_id = "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1",
      missing_reason = "insufficient_tokens_for_formula",
      requested_parameters = reported_parameters,
      counts = counts,
      quality_floor_tokens = 50L,
      diagnostics = .mtld_unavailable_diagnostics()
    ))
  }

  token_ids <- match(tokens, unique(tokens))
  forward <- .mtld_direction(token_ids, threshold)
  reverse <- .mtld_direction(rev(token_ids), threshold)
  diagnostics <- .mtld_diagnostics(forward, reverse)

  if (!is.finite(forward$score) || !is.finite(reverse$score)) {
    return(.lex_missing(
      metric_id = "mtld",
      method_id = "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1",
      missing_reason = "no_factor",
      requested_parameters = reported_parameters,
      counts = counts,
      quality_floor_tokens = 50L,
      diagnostics = diagnostics
    ))
  }

  .lex_ok(
    metric_id = "mtld",
    method_id = "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1",
    value = (forward$score + reverse$score) / 2,
    requested_parameters = reported_parameters,
    effective_parameters = reported_parameters,
    counts = counts,
    quality_floor_tokens = 50L,
    diagnostics = diagnostics
  )
}
