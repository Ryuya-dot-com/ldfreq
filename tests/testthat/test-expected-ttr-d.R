test_that("expected-TTR D matches independent reference fixtures", {
  mixed <- lexdiv_metrics(
    c("a", "a", "b", "c"),
    metrics = "expected_ttr_d",
    expected_ttr_sample_sizes = 2:4
  )
  identical_tokens <- lexdiv_metrics(
    rep("a", 50L),
    metrics = "expected_ttr_d"
  )
  doubletons <- lexdiv_metrics(
    rep(paste0("t", 1:25), each = 2L),
    metrics = "expected_ttr_d"
  )
  one_doubleton <- lexdiv_metrics(
    c("repeated", "repeated", paste0("u", 1:48)),
    metrics = "expected_ttr_d"
  )

  expect_equal(mixed$value, 5.89933823137413, tolerance = 1e-12)
  expect_equal(
    mixed$diagnostics[[1L]]$expected_ttr,
    c(11 / 12, 5 / 6, 3 / 4),
    tolerance = 1e-12
  )
  expect_equal(identical_tokens$value, 0.0123079761475342, tolerance = 1e-12)
  expect_equal(doubletons$value, 16.5829617773068, tolerance = 1e-12)
  expect_equal(one_doubleton$value, 1211.12893898358, tolerance = 1e-12)
  expect_identical(mixed$method_id, "expected_ttr_d_hypergeom_fit_v1")
  expect_identical(mixed$requested_parameters[[1L]], list(sample_sizes = 2:4))
  expect_identical(mixed$effective_parameters[[1L]], list(sample_sizes = 2:4))
  expect_true(is.finite(mixed$diagnostics[[1L]]$fit_sse))
  expect_true(is.finite(mixed$diagnostics[[1L]]$derivative_residual))
})

test_that("expected-TTR D exposes strict boundaries and validation", {
  short <- lexdiv_metrics(
    c("a", "a", "b"),
    metrics = "expected_ttr_d",
    expected_ttr_sample_sizes = 2:4
  )
  all_hapax <- lexdiv_metrics(
    paste0("u", 1:50),
    metrics = "expected_ttr_d"
  )
  expect_identical(short$status, "missing")
  expect_identical(short$missing_reason, "too_short_for_requested_parameter")
  expect_identical(all_hapax$status, "missing")
  expect_identical(all_hapax$missing_reason, "unbounded_high")
  expect_true(all_hapax$diagnostics[[1L]]$near_saturation)

  expect_error(
    lexdiv_metrics(
      rep("a", 50), metrics = "expected_ttr_d",
      expected_ttr_sample_sizes = c(35, 35)
    ),
    "strictly increasing"
  )
  expect_error(
    lexdiv_metrics(
      rep("a", 50), metrics = "expected_ttr_d",
      expected_ttr_sample_sizes = 1:2
    ),
    "at least 2"
  )
})

test_that("expected-TTR D depends on the frequency spectrum, not order", {
  tokens <- c(rep("a", 10), rep("b", 8), rep("c", 7), paste0("u", 1:25))
  forward <- lexdiv_metrics(tokens, metrics = "expected_ttr_d")
  backward <- lexdiv_metrics(rev(tokens), metrics = "expected_ttr_d")
  expect_identical(forward$value, backward$value)
  expect_identical(forward$diagnostics, backward$diagnostics)
})
