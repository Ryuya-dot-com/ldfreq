hdd_yule_internal <- function(name) {
  getFromNamespace(name, "ldfreq")
}

run_hdd_yule_metric <- function(name, tokens, parameters = list()) {
  hdd_yule_internal(name)(tokens, counts = NULL, parameters = parameters)
}

test_that("HD-D agrees with small exact hypergeometric oracles", {
  tokens <- c("a", "a", "b", "c")

  draw_two <- run_hdd_yule_metric(
    ".metric_hdd",
    tokens,
    list(sample_size = 2L)
  )
  draw_three <- run_hdd_yule_metric(
    ".metric_hdd",
    tokens,
    list(sample_size = 3L)
  )

  expect_identical(draw_two$metric_id, "hdd")
  expect_identical(draw_two$method_id, "hdd_expected_ttr_scaled_v1")
  expect_identical(draw_two$status, "ok")
  expect_equal(draw_two$value, 11 / 12, tolerance = 1e-12)
  expect_equal(draw_three$value, 5 / 6, tolerance = 1e-12)
  expect_identical(draw_two$requested_parameters, list(sample_size = 2L))
  expect_identical(draw_two$effective_parameters, list(sample_size = 2L))
})

test_that("HD-D preserves strict draw boundaries", {
  tokens <- c("a", "a", "b", "c")
  all_hapax <- paste0("type", seq_len(10000L))
  one_type <- rep("same", 4L)

  draw_one <- run_hdd_yule_metric(
    ".metric_hdd",
    tokens,
    list(sample_size = 1L)
  )
  draw_all <- run_hdd_yule_metric(
    ".metric_hdd",
    tokens,
    list(sample_size = length(tokens))
  )
  too_short <- run_hdd_yule_metric(
    ".metric_hdd",
    tokens,
    list(sample_size = length(tokens) + 1L)
  )

  expect_equal(draw_one$value, 1, tolerance = 1e-12)
  expect_equal(draw_all$value, 3 / 4, tolerance = 1e-12)
  expect_equal(
    run_hdd_yule_metric(
      ".metric_hdd",
      all_hapax,
      list(sample_size = 42L)
    )$value,
    1,
    tolerance = 1e-12
  )
  expect_equal(
    run_hdd_yule_metric(
      ".metric_hdd",
      one_type,
      list(sample_size = length(one_type))
    )$value,
    1 / length(one_type),
    tolerance = 0
  )
  expect_identical(too_short$status, "missing")
  expect_identical(
    too_short$missing_reason,
    "too_short_for_requested_parameter"
  )
  expect_identical(too_short$effective_parameters, list())
})

test_that("HD-D avoids overflowing combination counts", {
  tokens <- c(rep("common", 9999L), "rare")

  expect_true(is.infinite(choose(length(tokens), 500L)))
  result <- run_hdd_yule_metric(
    ".metric_hdd",
    tokens,
    list(sample_size = 500L)
  )

  # The common type is certain and the singleton is selected with probability
  # 500 / 10000, so the expected-TTR-scale result is exact in this form.
  oracle <- (1 + 500 / 10000) / 500
  expect_identical(result$status, "ok")
  expect_true(is.finite(result$value))
  expect_equal(result$value, oracle, tolerance = 1e-12)
  expect_gte(result$value, 0)
  expect_lte(result$value, 1)
})

test_that("HD-D validates sample_size without silently changing it", {
  tokens <- rep(c("a", "b"), 25L)

  expect_equal(
    run_hdd_yule_metric(".metric_hdd", tokens)$requested_parameters$sample_size,
    42L
  )
  expect_equal(
    run_hdd_yule_metric(
      ".metric_hdd",
      tokens,
      list(sample_size = 2)
    )$value,
    run_hdd_yule_metric(
      ".metric_hdd",
      tokens,
      list(sample_size = 2L)
    )$value,
    tolerance = 0
  )

  invalid <- list(
    list(sample_size = 0L),
    list(sample_size = 1.5),
    list(sample_size = NA_integer_),
    list(sample_size = Inf),
    list(sample_size = c(1L, 2L)),
    list(sample_size = "2"),
    list(sample_size = structure(2, class = "not-a-plain-number")),
    list(draw_size = 2L),
    list(2L),
    data.frame(sample_size = 2L)
  )
  for (parameters in invalid) {
    expect_error(
      run_hdd_yule_metric(".metric_hdd", tokens, parameters)
    )
  }

  large_request <- run_hdd_yule_metric(
    ".metric_hdd",
    tokens,
    list(sample_size = .Machine$integer.max + 1)
  )
  expect_identical(large_request$status, "missing")
  expect_equal(
    large_request$requested_parameters$sample_size,
    .Machine$integer.max + 1,
    tolerance = 0
  )
})

test_that("Yule K and I agree with hand-derived frequency moments", {
  mixed <- c("a", "a", "b", "c")
  repeated <- rep("a", 4L)

  mixed_k <- run_hdd_yule_metric(".metric_yule_k", mixed)
  mixed_i <- run_hdd_yule_metric(".metric_yule_i", mixed)
  repeated_k <- run_hdd_yule_metric(".metric_yule_k", repeated)
  repeated_i <- run_hdd_yule_metric(".metric_yule_i", repeated)

  expect_identical(mixed_k$method_id, "yule_k_m2_tokens_v1")
  expect_identical(
    mixed_i$method_id,
    "yule_i_types_v2_over_m2_minus_v_v1"
  )
  expect_equal(mixed_k$value, 1250, tolerance = 1e-12)
  expect_equal(mixed_i$value, 3, tolerance = 1e-12)
  expect_equal(repeated_k$value, 7500, tolerance = 1e-12)
  expect_equal(repeated_i$value, 1 / 15, tolerance = 1e-12)
})

test_that("Yule I reports the all-hapax zero denominator", {
  all_hapax <- c("a", "b", "c", "d")

  result_i <- run_hdd_yule_metric(".metric_yule_i", all_hapax)
  result_k <- run_hdd_yule_metric(".metric_yule_k", all_hapax)

  expect_identical(result_i$status, "missing")
  expect_identical(result_i$missing_reason, "zero_denominator")
  expect_true(is.na(result_i$value))
  expect_equal(result_k$value, 0, tolerance = 1e-12)
})

test_that("HD-D and Yule metrics depend on frequencies, not token order", {
  tokens <- c("a", "b", "a", "c", "d", "a", "b", "e")
  permutations <- list(
    tokens,
    rev(tokens),
    tokens[c(3L, 7L, 1L, 8L, 4L, 2L, 6L, 5L)]
  )

  hdd <- vapply(
    permutations,
    function(x) run_hdd_yule_metric(
      ".metric_hdd",
      x,
      list(sample_size = 4L)
    )$value,
    numeric(1L)
  )
  yule_k <- vapply(
    permutations,
    function(x) run_hdd_yule_metric(".metric_yule_k", x)$value,
    numeric(1L)
  )
  yule_i <- vapply(
    permutations,
    function(x) run_hdd_yule_metric(".metric_yule_i", x)$value,
    numeric(1L)
  )

  expect_equal(hdd, rep(hdd[[1L]], length(hdd)), tolerance = 0)
  expect_equal(yule_k, rep(yule_k[[1L]], length(yule_k)), tolerance = 0)
  expect_equal(yule_i, rep(yule_i[[1L]], length(yule_i)), tolerance = 0)
})

test_that("empty documents preserve the contract reason precedence", {
  hdd <- run_hdd_yule_metric(
    ".metric_hdd",
    character(),
    list(sample_size = 2L)
  )
  yule_k <- run_hdd_yule_metric(".metric_yule_k", character())
  yule_i <- run_hdd_yule_metric(".metric_yule_i", character())

  expect_identical(hdd$missing_reason, "empty_input")
  expect_identical(yule_k$missing_reason, "empty_input")
  expect_identical(yule_i$missing_reason, "empty_input")
})
