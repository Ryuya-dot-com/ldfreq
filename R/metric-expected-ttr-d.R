# Deterministic expected-TTR curve-fit D implementation.

.expected_ttr_d_sample_sizes <- function(parameters) {
  if (!is.list(parameters) || is.data.frame(parameters)) {
    stop("`parameters` must be a list.", call. = FALSE)
  }
  parameter_names <- names(parameters)
  if (length(parameters) > 0L &&
      (is.null(parameter_names) || anyNA(parameter_names) ||
       any(!nzchar(parameter_names)) || anyDuplicated(parameter_names))) {
    stop("`parameters` must be a uniquely named list.", call. = FALSE)
  }
  unknown <- setdiff(parameter_names, "sample_sizes")
  if (length(unknown) > 0L) {
    stop(
      sprintf(
        "Unknown expected-TTR D parameter(s): %s.",
        paste(unknown, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  sample_sizes <- if ("sample_sizes" %in% parameter_names) {
    parameters[["sample_sizes"]]
  } else {
    35:50
  }
  valid <- is.numeric(sample_sizes) &&
    !is.object(sample_sizes) &&
    is.null(dim(sample_sizes)) &&
    is.null(attributes(sample_sizes)) &&
    length(sample_sizes) > 0L &&
    !anyNA(sample_sizes) &&
    all(is.finite(sample_sizes)) &&
    all(sample_sizes >= 2) &&
    all(sample_sizes == floor(sample_sizes)) &&
    !is.unsorted(sample_sizes, strictly = TRUE) &&
    max(sample_sizes) <= .Machine$integer.max
  if (!valid) {
    stop(
      paste0(
        "`sample_sizes` must be a non-empty, plain, strictly increasing ",
        "integer vector whose values are at least 2."
      ),
      call. = FALSE
    )
  }
  as.integer(sample_sizes)
}

.expected_ttr_d_unavailable_diagnostics <- function() {
  list(
    fit_sse = NA_real_,
    fit_rmse = NA_real_,
    sample_sizes = integer(),
    expected_ttr = numeric(),
    fitted_ttr = numeric(),
    optimizer_iterations = 100L,
    derivative_residual = NA_real_,
    near_saturation = NA
  )
}

.expected_ttr_d_model <- function(sample_sizes, D) {
  2 / (sqrt(1 + 2 * as.double(sample_sizes) / D) + 1)
}

.expected_ttr_d_deficit <- function(frequencies, sample_sizes) {
  frequencies <- sort(as.double(frequencies))
  N <- sum(frequencies)
  spectrum <- table(frequencies)
  spectrum_frequencies <- as.double(names(spectrum))
  spectrum_types <- as.double(spectrum)

  # Given that draw j has type t, its preceding j-1 draws sample a population
  # of N-1 with f_t-1 occurrences of t. Sum the probability that the current
  # draw repeats a preceding type. This computes 1 - E[TTR] directly, without
  # subtracting nearly equal numbers; singleton types contribute exactly zero.
  offsets <- seq_len(max(sample_sizes) - 1L) - 1
  deficit <- numeric(length(sample_sizes))
  for (index in which(spectrum_frequencies > 1)) {
    frequency <- spectrum_frequencies[[index]]
    log_absence <- cumsum(log1p(-pmin(
      1, (frequency - 1) / (N - 1 - offsets)
    )))
    repeated <- cumsum(-expm1(log_absence))
    deficit <- deficit + (spectrum_types[[index]] * frequency / N) *
      repeated[sample_sizes - 1L] / sample_sizes
  }
  deficit
}

.metric_expected_ttr_d <- function(tokens, counts = NULL, parameters = list()) {
  sample_sizes <- .expected_ttr_d_sample_sizes(parameters)
  requested <- list(sample_sizes = sample_sizes)
  if (is.null(counts)) {
    counts <- .lex_counts(tokens)
  }
  diagnostics <- .expected_ttr_d_unavailable_diagnostics()
  diagnostics$sample_sizes <- sample_sizes

  if (counts$N == 0L) {
    return(.lex_missing(
      metric_id = "expected_ttr_d",
      method_id = "expected_ttr_d_hypergeom_fit_v1",
      missing_reason = "empty_input",
      requested_parameters = requested,
      counts = counts,
      quality_floor_tokens = 50L,
      diagnostics = diagnostics
    ))
  }
  if (counts$N < max(sample_sizes)) {
    return(.lex_missing(
      metric_id = "expected_ttr_d",
      method_id = "expected_ttr_d_hypergeom_fit_v1",
      missing_reason = "too_short_for_requested_parameter",
      requested_parameters = requested,
      counts = counts,
      quality_floor_tokens = 50L,
      diagnostics = diagnostics
    ))
  }

  deficit <- .expected_ttr_d_deficit(counts$freq, sample_sizes)
  observed <- 1 - deficit
  diagnostics$expected_ttr <- observed
  diagnostics$near_saturation <- max(observed) >= 0.99
  if (all(counts$freq == 1)) {
    return(.lex_missing(
      metric_id = "expected_ttr_d",
      method_id = "expected_ttr_d_hypergeom_fit_v1",
      missing_reason = "unbounded_high",
      requested_parameters = requested,
      effective_parameters = requested,
      counts = counts,
      quality_floor_tokens = 50L,
      diagnostics = diagnostics
    ))
  }
  if (any(!is.finite(deficit)) || any(deficit <= 0) || any(deficit >= 1)) {
    return(.lex_missing(
      metric_id = "expected_ttr_d",
      method_id = "expected_ttr_d_hypergeom_fit_v1",
      missing_reason = "non_convergence",
      requested_parameters = requested,
      counts = counts,
      quality_floor_tokens = 50L,
      diagnostics = diagnostics
    ))
  }

  numeric_sizes <- as.double(sample_sizes)
  point_solutions <- numeric_sizes * observed * observed /
    (2 * deficit)
  if (any(!is.finite(point_solutions)) || any(point_solutions <= 0)) {
    return(.lex_missing(
      metric_id = "expected_ttr_d",
      method_id = "expected_ttr_d_hypergeom_fit_v1",
      missing_reason = "non_convergence",
      requested_parameters = requested,
      counts = counts,
      quality_floor_tokens = 50L,
      diagnostics = diagnostics
    ))
  }

  lower <- log(min(point_solutions))
  upper <- log(max(point_solutions))
  gradient <- function(log_D) {
    D <- exp(log_D)
    accumulator <- 0
    for (index in seq_along(numeric_sizes)) {
      n <- numeric_sizes[[index]]
      root <- sqrt(1 + 2 * n / D)
      root_plus_one <- root + 1
      fitted_deficit <- (2 * n / D) / (root_plus_one * root_plus_one)
      derivative <- (2 * n) /
        (D * root * root_plus_one * root_plus_one)
      accumulator <- accumulator +
        2 * (deficit[[index]] - fitted_deficit) * derivative
    }
    accumulator
  }

  if (identical(lower, upper)) {
    D <- point_solutions[[1L]]
  } else {
    lower_gradient <- gradient(lower)
    upper_gradient <- gradient(upper)
    tolerance <- 64 * .Machine$double.eps
    if (
      !is.finite(lower_gradient) || !is.finite(upper_gradient) ||
        lower_gradient > tolerance || upper_gradient < -tolerance
    ) {
      return(.lex_missing(
        metric_id = "expected_ttr_d",
        method_id = "expected_ttr_d_hypergeom_fit_v1",
        missing_reason = "non_convergence",
        requested_parameters = requested,
        counts = counts,
        quality_floor_tokens = 50L,
        diagnostics = diagnostics
      ))
    }
    if (lower_gradient == 0) {
      D <- exp(lower)
    } else if (upper_gradient == 0) {
      D <- exp(upper)
    } else {
      for (iteration in seq_len(100L)) {
        midpoint <- lower + (upper - lower) / 2
        if (gradient(midpoint) < 0) {
          lower <- midpoint
        } else {
          upper <- midpoint
        }
      }
      D <- exp(lower + (upper - lower) / 2)
    }
  }

  fitted <- .expected_ttr_d_model(sample_sizes, D)
  fitted_deficit <- (2 * numeric_sizes / D) /
    (sqrt(1 + 2 * numeric_sizes / D) + 1)^2
  residuals <- deficit - fitted_deficit
  diagnostics$fit_sse <- sum(residuals * residuals)
  diagnostics$fit_rmse <- sqrt(mean(residuals * residuals))
  diagnostics$fitted_ttr <- fitted
  diagnostics$derivative_residual <- gradient(log(D))

  .lex_ok(
    metric_id = "expected_ttr_d",
    method_id = "expected_ttr_d_hypergeom_fit_v1",
    value = D,
    requested_parameters = requested,
    effective_parameters = requested,
    counts = counts,
    quality_floor_tokens = 50L,
    diagnostics = diagnostics
  )
}
