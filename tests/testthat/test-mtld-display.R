test_that("MTLD print exposes tail-only estimation without changing records", {
  tail <- c(letters[1:8], "a", "b")
  plan <- lexdiv_plan(presets = character(),
    specs = list(lexdiv_spec("mtld_seq_bidir_dirmean_lt_nomin_linear_tail_v1")))
  results <- list(
    lexdiv_metrics(tail, metrics = "mtld"),
    lexdiv_metrics_batch(list(tail = tail, complete = rep("a", 50)),
                         metrics = "mtld"),
    lexdiv_profile(tail, plan),
    lexdiv_profile_batch(list(tail = tail), plan),
    lexdiv_variant_metrics(tail,
      variants = "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1")
  )
  for (x in results) {
    before <- serialize(x, NULL)
    output <- capture.output(returned <- withVisible(print(x)))
    expect_true(any(grepl("mtld_tail_only", output, fixed = TRUE)))
    expect_true(any(grepl("mtld_gap_pct", output, fixed = TRUE)))
    expect_true(any(grepl("Attention:", output, fixed = TRUE)))
    expect_true(any(grepl("not a precision estimate", output, fixed = TRUE)))
    expect_identical(returned$value, x)
    expect_false(returned$visible)
    expect_identical(serialize(x, NULL), before)
  }
  # Both directions use the global TTR here: a zero gap is not reassurance.
  expect_equal(results[[1]]$diagnostics[[1]]$forward_score, 14)
  expect_equal(results[[1]]$diagnostics[[1]]$reverse_score, 14)
  one_direction <- lexdiv_metrics(c(letters[1:8], "a", "a"), metrics = "mtld")
  expect_identical(one_direction$diagnostics[[1]]$forward_complete_factors, 0L)
  expect_identical(one_direction$diagnostics[[1]]$reverse_complete_factors, 1L)
  expect_output(print(one_direction), "Attention:")
  expect_false(any(grepl("Attention:", capture.output(print(
    lexdiv_metrics(rep("a", 50), metrics = "mtld"))), fixed = TRUE)))
})

test_that("MTLD display handles unavailable diagnostics and unrelated methods", {
  for (tokens in list(character(), letters, NA_character_)) {
    x <- lexdiv_metrics(tokens, metrics = "mtld")
    expect_false(any(grepl("mtld_tail_only", capture.output(print(x)),
                          fixed = TRUE)))
  }
  x <- lexdiv_metrics(rep("a", 50), metrics = c("mtld", "ttr"))
  expect_output(print(x["value"]), "lexdiv_results")
  expect_output(print(x[0, ]), "0 metrics")
  expect_false(any(grepl("mtld_tail_only", capture.output(print(
    lexdiv_metrics(letters, metrics = "ttr"))), fixed = TRUE)))
})
