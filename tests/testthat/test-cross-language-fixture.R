test_that("the cross-language semantic fixture holds for the R API", {
  fixture_path <- system.file(
    "spec",
    "cross-language-metric-fixture.json",
    package = "ldfreq"
  )
  expect_true(nzchar(fixture_path))

  fixture <- jsonlite::read_json(fixture_path, simplifyVector = FALSE)
  expect_identical(fixture$fixture_id, "ldfreq-cross-language-semantic-metrics")
  expect_identical(fixture$license, "CC0-1.0")
  expect_match(fixture$comparison_rule, "Parse and compare")
  expect_identical(
    fixture$status_mapping$available$r,
    "ok"
  )

  for (method in fixture$shared_methods) {
    observed <- lexdiv_metrics("a", metrics = method$metric_id)
    expect_identical(
      observed$method_id,
      method$method_id,
      info = method$metric_id
    )
  }

  for (case in fixture$cases) {
    tokens <- if (length(case$tokens) == 0L) {
      character()
    } else {
      unlist(case$tokens, use.names = FALSE)
    }
    for (assertion in case$assertions) {
      call <- list(tokens = tokens, metrics = assertion$metric_id)
      if (!is.null(case$parameters$segment_length)) {
        call$segment_length <- as.integer(case$parameters$segment_length)
      }
      if (!is.null(case$parameters$window_length)) {
        call$window_length <- as.integer(case$parameters$window_length)
      }
      if (!is.null(case$parameters$sample_size)) {
        call$sample_size <- as.integer(case$parameters$sample_size)
      }
      result <- do.call(lexdiv_metrics, call)
      expected_status <- fixture$status_mapping[[assertion$semantic_status]]$r
      context <- sprintf("case=%s metric=%s", case$id, assertion$metric_id)

      expect_identical(result$status, expected_status, info = context)
      if (identical(assertion$semantic_status, "available")) {
        tolerance <- fixture$numeric_tolerance$absolute +
          fixture$numeric_tolerance$relative * abs(assertion$value)
        expect_true(
          abs(result$value - assertion$value) <= tolerance,
          info = context
        )
        expect_true(is.na(result$missing_reason), info = context)
      } else {
        expect_true(is.na(result$value), info = context)
        expect_identical(
          result$missing_reason,
          assertion$missing_reason,
          info = context
        )
      }
    }
  }

  boundary <- fixture$runtime_specific_cases[[1L]]
  expect_identical(boundary$id, "mtld-threshold-boundary")
  expect_identical(boundary$parameters$minimum_factor_length, 10L)
  result <- lexdiv_metrics(
    unlist(boundary$tokens, use.names = FALSE),
    metrics = "mtld",
    mtld_threshold = boundary$parameters$threshold
  )
  expect_identical(result$method_id, boundary$r$method_id)
  expect_identical(result$status, boundary$r$status)
  tolerance <- fixture$numeric_tolerance$absolute +
    fixture$numeric_tolerance$relative * abs(boundary$r$value)
  expect_true(abs(result$value - boundary$r$value) <= tolerance)
  expect_false(identical(boundary$r$method_id, boundary$python$method_id))
  expect_false(isTRUE(all.equal(boundary$r$value, boundary$python$value)))
})
