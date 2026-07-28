# Independent differential/property audit for the installed public API.
#
# This file deliberately does not call package internals. R CMD check executes
# it on every supported CI platform after installing the candidate package.

library(ldfreq)

audit_stop <- function(...) {
  stop(sprintf(...), call. = FALSE)
}

audit_close <- function(observed, expected, context) {
  tolerance <- 1e-12 + 1e-12 * abs(expected)
  if (!isTRUE(abs(observed - expected) <= tolerance)) {
    audit_stop(
      "%s: expected %.17g, observed %.17g (tolerance %.3g).",
      context,
      expected,
      observed,
      tolerance
    )
  }
}

audit_mtld_direction <- function(tokens, threshold = 0.72) {
  complete_factors <- 0
  factor_length <- 0L
  factor_types <- new.env(hash = TRUE, parent = emptyenv())

  for (token in tokens) {
    factor_length <- factor_length + 1L
    factor_types[[token]] <- TRUE
    factor_ttr <- length(ls(factor_types, all.names = TRUE)) / factor_length
    if (factor_length >= 10L && factor_ttr < threshold) {
      complete_factors <- complete_factors + 1
      factor_length <- 0L
      factor_types <- new.env(hash = TRUE, parent = emptyenv())
    }
  }

  tail_credit <- 0
  if (factor_length > 0L) {
    tail_ttr <- length(ls(factor_types, all.names = TRUE)) / factor_length
    tail_credit <- (1 - tail_ttr) / (1 - threshold)
  }
  factors <- complete_factors + tail_credit
  if (factors > 0) length(tokens) / factors else NA_real_
}

audit_mtld <- function(tokens, threshold = 0.72) {
  if (length(tokens) < 10L) {
    return(list(
      status = "missing",
      value = NA_real_,
      missing_reason = "insufficient_tokens_for_formula"
    ))
  }

  forward <- audit_mtld_direction(tokens, threshold)
  backward <- audit_mtld_direction(rev(tokens), threshold)
  if (!is.finite(forward) || !is.finite(backward)) {
    return(list(
      status = "missing",
      value = NA_real_,
      missing_reason = "no_factor"
    ))
  }
  list(
    status = "ok",
    value = (forward + backward) / 2,
    missing_reason = NA_character_
  )
}

set.seed(20260725)
labels <- c("a", ".dot", "a b", "\u00e9", "e\u0301", "猫", "x/y", "if", "1")

for (iteration in seq_len(500L)) {
  token_count <- sample(10:200, 1L)
  tokens <- sample(labels, token_count, replace = TRUE)
  threshold <- sample(c(0.55, 0.63, 0.72, 0.81, 0.9), 1L)
  observed <- lexdiv_metrics(
    tokens,
    metrics = "mtld",
    mtld_threshold = threshold
  )
  expected <- audit_mtld(tokens, threshold)

  if (!identical(observed$status, expected$status)) {
    audit_stop("MTLD status mismatch at iteration %d.", iteration)
  }
  if (identical(expected$status, "ok")) {
    audit_close(
      observed$value,
      expected$value,
      sprintf("MTLD iteration %d", iteration)
    )
  } else if (!identical(observed$missing_reason, expected$missing_reason)) {
    audit_stop("MTLD missing-reason mismatch at iteration %d.", iteration)
  }
}

for (iteration in seq_len(1000L)) {
  token_count <- sample(1:40, 1L)
  tokens <- sample(letters[1:10], token_count, replace = TRUE)
  segment_length <- sample(1:45, 1L)
  window_length <- sample(1:45, 1L)
  sample_size <- sample(1:45, 1L)
  observed <- lexdiv_metrics(
    tokens,
    metrics = c(
      "ttr", "rttr", "cttr", "herdan", "maas",
      "msttr", "mattr", "hdd", "yule_k", "yule_i"
    ),
    segment_length = segment_length,
    window_length = window_length,
    sample_size = sample_size
  )

  frequencies <- as.double(tabulate(match(tokens, unique(tokens))))
  N <- length(tokens)
  V <- length(frequencies)
  M2 <- sum(frequencies^2)
  value <- setNames(observed$value, observed$metric_id)
  status <- setNames(observed$status, observed$metric_id)
  reason <- setNames(observed$missing_reason, observed$metric_id)

  audit_close(value[["ttr"]], V / N, sprintf("TTR iteration %d", iteration))
  audit_close(value[["rttr"]], V / sqrt(N), sprintf("RTTR iteration %d", iteration))
  audit_close(value[["cttr"]], V / sqrt(2 * N), sprintf("CTTR iteration %d", iteration))
  if (N > 1L) {
    audit_close(
      value[["herdan"]],
      log(V) / log(N),
      sprintf("Herdan iteration %d", iteration)
    )
    audit_close(
      value[["maas"]],
      (log(N) - log(V)) / log(N)^2,
      sprintf("Maas iteration %d", iteration)
    )
  }

  audit_close(
    value[["yule_k"]],
    10000 * (M2 - N) / N^2,
    sprintf("Yule K iteration %d", iteration)
  )
  if (M2 > V) {
    audit_close(
      value[["yule_i"]],
      V^2 / (M2 - V),
      sprintf("Yule I iteration %d", iteration)
    )
  } else if (
    !identical(status[["yule_i"]], "missing") ||
      !identical(reason[["yule_i"]], "zero_denominator")
  ) {
    audit_stop("Yule I domain mismatch at iteration %d.", iteration)
  }

  if (N >= segment_length) {
    used <- floor(N / segment_length) * segment_length
    indices <- seq_len(used)
    segments <- split(indices, ceiling(indices / segment_length))
    expected <- mean(vapply(
      segments,
      function(index) length(unique(tokens[index])) / segment_length,
      numeric(1L)
    ))
    audit_close(value[["msttr"]], expected, sprintf("MSTTR iteration %d", iteration))
  } else if (!identical(reason[["msttr"]], "too_short_for_requested_parameter")) {
    audit_stop("MSTTR short-parameter mismatch at iteration %d.", iteration)
  }

  if (N >= window_length) {
    expected <- mean(vapply(
      seq_len(N - window_length + 1L),
      function(start) {
        index <- start:(start + window_length - 1L)
        length(unique(tokens[index])) / window_length
      },
      numeric(1L)
    ))
    audit_close(value[["mattr"]], expected, sprintf("MATTR iteration %d", iteration))
  } else if (!identical(reason[["mattr"]], "too_short_for_requested_parameter")) {
    audit_stop("MATTR short-parameter mismatch at iteration %d.", iteration)
  }

  if (N >= sample_size) {
    expected <- sum(vapply(frequencies, function(frequency) {
      absence <- if (N - frequency < sample_size) {
        0
      } else {
        choose(N - frequency, sample_size) / choose(N, sample_size)
      }
      1 - absence
    }, numeric(1L))) / sample_size
    audit_close(value[["hdd"]], expected, sprintf("HD-D iteration %d", iteration))
  } else if (!identical(reason[["hdd"]], "too_short_for_requested_parameter")) {
    audit_stop("HD-D short-parameter mismatch at iteration %d.", iteration)
  }
}

exhaustive_comparisons <- 0L
for (N in seq_len(7L)) {
  powers <- 3^((seq_len(N) - 1L))
  for (code in 0:(3^N - 1L)) {
    tokens <- letters[1L + ((code %/% powers) %% 3L)]
    frequencies <- as.double(tabulate(match(tokens, unique(tokens))))
    for (local_length in seq_len(N + 1L)) {
      observed <- lexdiv_metrics(
        tokens,
        metrics = c("msttr", "mattr", "hdd"),
        segment_length = local_length,
        window_length = local_length,
        sample_size = local_length
      )
      value <- setNames(observed$value, observed$metric_id)
      reason <- setNames(observed$missing_reason, observed$metric_id)

      if (local_length > N) {
        if (!all(reason == "too_short_for_requested_parameter")) {
          audit_stop("Exhaustive short-parameter mismatch for N=%d code=%d.", N, code)
        }
      } else {
        used <- floor(N / local_length) * local_length
        indices <- seq_len(used)
        segments <- split(indices, ceiling(indices / local_length))
        expected_msttr <- mean(vapply(
          segments,
          function(index) length(unique(tokens[index])) / local_length,
          numeric(1L)
        ))
        expected_mattr <- mean(vapply(
          seq_len(N - local_length + 1L),
          function(start) {
            index <- start:(start + local_length - 1L)
            length(unique(tokens[index])) / local_length
          },
          numeric(1L)
        ))
        expected_hdd <- sum(vapply(frequencies, function(frequency) {
          absence <- if (N - frequency < local_length) {
            0
          } else {
            choose(N - frequency, local_length) / choose(N, local_length)
          }
          1 - absence
        }, numeric(1L))) / local_length

        audit_close(value[["msttr"]], expected_msttr, "exhaustive MSTTR")
        audit_close(value[["mattr"]], expected_mattr, "exhaustive MATTR")
        audit_close(value[["hdd"]], expected_hdd, "exhaustive HD-D")
      }
      exhaustive_comparisons <- exhaustive_comparisons + 3L
    }
  }
}

cat(sprintf(
  paste0(
    "Independent differential audit OK: 500 MTLD documents, 1,000 direct ",
    "formula/window/hypergeometric documents, and %d exhaustive ",
    "three-type MSTTR/MATTR/HD-D comparisons.\n"
  ),
  exhaustive_comparisons
))
