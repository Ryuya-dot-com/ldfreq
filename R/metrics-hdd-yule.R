# Internal implementations of the frozen HD-D and Yule metric variants.

.hdd_sample_size <- function(parameters) {
  if (!is.list(parameters) || is.data.frame(parameters)) {
    stop("`parameters` must be a list.", call. = FALSE)
  }

  parameter_names <- names(parameters)
  if (length(parameters) > 0L &&
      (is.null(parameter_names) || anyNA(parameter_names) ||
       any(!nzchar(parameter_names)) || anyDuplicated(parameter_names))) {
    stop("`parameters` must be a uniquely named list.", call. = FALSE)
  }

  unknown <- setdiff(parameter_names, "sample_size")
  if (length(unknown) > 0L) {
    stop(
      sprintf("Unknown HD-D parameter(s): %s.", paste(unknown, collapse = ", ")),
      call. = FALSE
    )
  }

  sample_size <- if ("sample_size" %in% parameter_names) {
    parameters[["sample_size"]]
  } else {
    42L
  }

  valid <- is.numeric(sample_size) &&
    !is.object(sample_size) &&
    is.null(dim(sample_size)) &&
    length(sample_size) == 1L &&
    !is.na(sample_size) &&
    is.finite(sample_size) &&
    sample_size >= 1 &&
    sample_size == floor(sample_size)

  if (!valid) {
    stop("`sample_size` must be one integer greater than or equal to 1.", call. = FALSE)
  }

  sample_size
}

.metric_hdd <- function(tokens, counts = NULL, parameters = list()) {
  sample_size <- .hdd_sample_size(parameters)
  requested <- list(sample_size = sample_size)

  if (is.null(counts)) {
    counts <- .lex_counts(tokens)
  }

  if (counts$N == 0L) {
    return(.lex_missing(
      metric_id = "hdd",
      method_id = "hdd_expected_ttr_scaled_v1",
      missing_reason = "empty_input",
      requested_parameters = requested,
      counts = counts,
      quality_floor_tokens = 42L
    ))
  }

  if (counts$N < sample_size) {
    return(.lex_missing(
      metric_id = "hdd",
      method_id = "hdd_expected_ttr_scaled_v1",
      missing_reason = "too_short_for_requested_parameter",
      requested_parameters = requested,
      counts = counts,
      quality_floor_tokens = 42L
    ))
  }

  N <- as.double(counts$N)
  draw <- as.double(sample_size)
  frequencies <- as.double(counts$freq)
  frequency_levels <- sort(unique(frequencies))
  frequency_multiplicity <- tabulate(
    match(frequencies, frequency_levels),
    nbins = length(frequency_levels)
  )

  presence_probability <- vapply(
    frequency_levels,
    function(frequency) {
      available_without_type <- N - frequency

      # The contract defines choose(a, b) as zero when b > a.  Otherwise,
      # evaluate 1 - choose(N-f, n) / choose(N, n) without ever forming
      # either (potentially infinite) combination count.  The two products
      # below are algebraically identical; selecting the shorter one limits
      # work, while log1p/expm1 avoid cancellation when absence is near one.
      if (draw > available_without_type) {
        return(1)
      }

      if (draw <= frequency) {
        offsets <- seq_len(draw) - 1
        log_absence <- sum(log1p(-frequency / (N - offsets)))
      } else {
        offsets <- seq_len(frequency) - 1
        log_absence <- sum(log1p(-draw / (N - offsets)))
      }

      -expm1(log_absence)
    },
    numeric(1L)
  )

  value <- sum(as.double(frequency_multiplicity) * presence_probability) / draw

  .lex_ok(
    metric_id = "hdd",
    method_id = "hdd_expected_ttr_scaled_v1",
    value = value,
    requested_parameters = requested,
    effective_parameters = requested,
    counts = counts,
    quality_floor_tokens = 42L
  )
}

.metric_yule_k <- function(tokens, counts = NULL, parameters = list()) {
  if (!is.list(parameters) || length(parameters) != 0L) {
    stop("Yule's K does not accept parameters.", call. = FALSE)
  }

  if (is.null(counts)) {
    counts <- .lex_counts(tokens)
  }

  if (counts$N == 0L) {
    return(.lex_missing(
      metric_id = "yule_k",
      method_id = "yule_k_m2_tokens_v1",
      missing_reason = "empty_input",
      counts = counts,
      quality_floor_tokens = 100L
    ))
  }

  N <- as.double(counts$N)
  value <- 10000 * (as.double(counts$M2) - N) / (N * N)

  .lex_ok(
    metric_id = "yule_k",
    method_id = "yule_k_m2_tokens_v1",
    value = value,
    counts = counts,
    quality_floor_tokens = 100L
  )
}

.metric_yule_i <- function(tokens, counts = NULL, parameters = list()) {
  if (!is.list(parameters) || length(parameters) != 0L) {
    stop("Yule's I does not accept parameters.", call. = FALSE)
  }

  if (is.null(counts)) {
    counts <- .lex_counts(tokens)
  }

  if (counts$N == 0L) {
    return(.lex_missing(
      metric_id = "yule_i",
      method_id = "yule_i_types_v2_over_m2_minus_v_v1",
      missing_reason = "empty_input",
      counts = counts,
      quality_floor_tokens = 100L
    ))
  }

  V <- as.double(counts$V)
  denominator <- as.double(counts$M2) - V
  if (denominator <= 0) {
    return(.lex_missing(
      metric_id = "yule_i",
      method_id = "yule_i_types_v2_over_m2_minus_v_v1",
      missing_reason = "zero_denominator",
      counts = counts,
      quality_floor_tokens = 100L
    ))
  }

  .lex_ok(
    metric_id = "yule_i",
    method_id = "yule_i_types_v2_over_m2_minus_v_v1",
    value = (V * V) / denominator,
    counts = counts,
    quality_floor_tokens = 100L
  )
}
