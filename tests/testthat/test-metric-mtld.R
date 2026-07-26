metric_mtld <- getFromNamespace(".metric_mtld", "ldfreq")
lex_counts <- getFromNamespace(".lex_counts", "ldfreq")

run_mtld <- function(tokens, threshold = 0.72) {
  metric_mtld(tokens, lex_counts(tokens), list(threshold = threshold))
}

expect_mtld_value <- function(tokens, expected, tolerance = 1e-12) {
  result <- run_mtld(tokens)
  expect_identical(result$metric_id, "mtld")
  expect_identical(
    result$method_id,
    "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1"
  )
  expect_identical(result$status, "ok")
  expect_equal(result$value, expected, tolerance = tolerance)
  result
}

test_that("MTLD enforces its minimum domain and no-factor result", {
  empty <- metric_mtld(character())
  expect_identical(empty$status, "missing")
  expect_identical(empty$missing_reason, "empty_input")
  expect_identical(empty$requested_parameters, list(threshold = 0.72))
  expect_identical(empty$effective_parameters, list())

  too_short <- run_mtld(rep("a", 9L))
  expect_identical(too_short$status, "missing")
  expect_identical(
    too_short$missing_reason,
    "insufficient_tokens_for_formula"
  )
  expect_identical(too_short$requested_parameters, list(threshold = 0.72))
  expect_identical(too_short$effective_parameters, list())
  expect_true(is.na(too_short$value))

  all_hapax <- run_mtld(paste0("u", seq_len(10L)))
  expect_identical(all_hapax$status, "missing")
  expect_identical(all_hapax$missing_reason, "no_factor")
  expect_identical(all_hapax$requested_parameters, list(threshold = 0.72))
  expect_identical(all_hapax$effective_parameters, list())
  expect_true(is.na(all_hapax$value))
  expect_identical(all_hapax$diagnostics$forward_complete_factors, 0L)
  expect_identical(all_hapax$diagnostics$reverse_complete_factors, 0L)
  expect_equal(all_hapax$diagnostics$forward_tail_credit, 0)
  expect_equal(all_hapax$diagnostics$reverse_tail_credit, 0)
})

test_that("MTLD reproduces the rational tail and minimum-gate fixtures", {
  ordinary_tail <- c(paste0("u", seq_len(8L)), "u1", "u2")
  expect_mtld_value(ordinary_tail, 14)

  minimum_gate <- expect_mtld_value(rep("a", 50L), 10)
  expect_identical(
    minimum_gate$diagnostics$forward_complete_factors,
    5L
  )
  expect_identical(
    minimum_gate$diagnostics$reverse_complete_factors,
    5L
  )

  uncapped_tail <- expect_mtld_value(c(rep("a", 10L), "b", "b"), 56 / 13)
  expect_equal(
    uncapped_tail$diagnostics$forward_tail_credit,
    25 / 14,
    tolerance = 1e-12
  )
  expect_equal(
    uncapped_tail$diagnostics$reverse_tail_credit,
    25 / 14,
    tolerance = 1e-12
  )
  expect_gt(uncapped_tail$diagnostics$forward_tail_credit, 1)
  expect_gt(uncapped_tail$diagnostics$reverse_tail_credit, 1)
})

test_that("MTLD resets factor-local type state after every closure", {
  first_factor <- c(paste0("a", seq_len(7L)), rep("a1", 3L))
  second_factor <- c(paste0("b", seq_len(7L)), rep("b1", 3L))
  result <- expect_mtld_value(c(first_factor, second_factor), 10)

  expect_identical(result$diagnostics$forward_complete_factors, 2L)
  expect_identical(result$diagnostics$reverse_complete_factors, 2L)
  expect_equal(result$diagnostics$forward_tail_credit, 0)
  expect_equal(result$diagnostics$reverse_tail_credit, 0)
})

test_that("MTLD accepts arbitrary non-empty valid Unicode token keys", {
  unusual_types <- c(
    "\u00e9",
    "e\u0301",
    "\U0001f642",
    "a/b",
    "line\nbreak",
    "`quoted`",
    "0",
    "_"
  )
  tokens <- c(unusual_types, unusual_types[[1L]], unusual_types[[2L]])
  result <- expect_mtld_value(tokens, 14)

  expect_identical(result$N, 10L)
  expect_identical(result$V, 8L)
})

test_that("MTLD averages directional scores rather than factor counts", {
  asymmetric <- c(rep("a", 10L), "b", "c", "d", "e")
  result <- expect_mtld_value(asymmetric, 917 / 103)

  expect_equal(result$diagnostics$forward_score, 14, tolerance = 1e-12)
  expect_equal(
    result$diagnostics$reverse_score,
    392 / 103,
    tolerance = 1e-12
  )
  expect_equal(
    result$value,
    mean(c(
      result$diagnostics$forward_score,
      result$diagnostics$reverse_score
    )),
    tolerance = 1e-12
  )
})

test_that("MTLD uses a strict threshold boundary", {
  boundary <- c(
    paste0("u", seq_len(18L)),
    rep("u1", 7L),
    "x", "x"
  )
  result <- expect_mtld_value(boundary, 27)
  expect_equal(result$diagnostics$forward_score, 27, tolerance = 1e-12)
  expect_equal(result$diagnostics$reverse_score, 27, tolerance = 1e-12)
})

test_that("MTLD emits the complete six-field diagnostic interface", {
  expected_names <- c(
    "forward_score",
    "reverse_score",
    "forward_complete_factors",
    "reverse_complete_factors",
    "forward_tail_credit",
    "reverse_tail_credit"
  )

  expect_identical(
    names(run_mtld(c(paste0("u", seq_len(8L)), "u1", "u2"))$diagnostics),
    expected_names
  )
  expect_identical(
    names(run_mtld(rep("a", 9L))$diagnostics),
    expected_names
  )
})

test_that("MTLD accepts only a valid threshold parameter", {
  tokens <- rep("a", 10L)
  counts <- lex_counts(tokens)
  default <- metric_mtld(tokens, counts, list())
  explicit <- metric_mtld(tokens, counts, list(threshold = 0.72))
  expect_equal(default$value, explicit$value, tolerance = 1e-12)
  expect_identical(default$requested_parameters, list(threshold = 0.72))
  expect_identical(default$effective_parameters, list(threshold = 0.72))

  expect_error(
    metric_mtld(tokens, counts, list(minimum_complete_factor_length = 1L)),
    "Only `threshold` is user-settable",
    fixed = TRUE
  )
  expect_error(metric_mtld(tokens, counts, list(threshold = 0)), "strictly between")
  expect_error(metric_mtld(tokens, counts, list(threshold = 1)), "strictly between")
  expect_error(metric_mtld(tokens, counts, list(threshold = Inf)), "strictly between")
  expect_error(metric_mtld(tokens, counts, list(threshold = c(0.7, 0.8))), "strictly between")
})

test_that("MTLD is invariant to reversal and bijective type relabeling", {
  documents <- list(
    c(rep("a", 10L), "b", "c", "d", "e"),
    c(paste0("u", seq_len(18L)), rep("u1", 7L), "x", "x"),
    rep(c("a", "a", "b", "c"), 20L)
  )

  for (tokens in documents) {
    original <- run_mtld(tokens)
    reversed <- run_mtld(rev(tokens))
    relabeled <- run_mtld(paste0("type:", match(tokens, unique(tokens))))

    expect_identical(original$status, "ok")
    expect_equal(original$value, reversed$value, tolerance = 1e-12)
    expect_equal(original$value, relabeled$value, tolerance = 1e-12)
    expect_equal(
      original$diagnostics$forward_score,
      reversed$diagnostics$reverse_score,
      tolerance = 1e-12
    )
    expect_equal(
      original$diagnostics$reverse_score,
      reversed$diagnostics$forward_score,
      tolerance = 1e-12
    )
  }
})
