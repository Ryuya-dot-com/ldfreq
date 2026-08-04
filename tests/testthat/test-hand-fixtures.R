fixture_api <- getFromNamespace("lexdiv_metrics", "ldfreq")

test_that("all frozen hand assertions pass through the package API", {
  fixture_path <- system.file(
    "spec",
    "lexical-diversity-hand-cases.json",
    package = "ldfreq"
  )
  contract_path <- system.file(
    "spec",
    "lexical-diversity-contract.json",
    package = "ldfreq"
  )
  schema_path <- system.file(
    "spec",
    "lexical-diversity-contract.schema.json",
    package = "ldfreq"
  )
  expect_true(nzchar(fixture_path))
  expect_true(nzchar(contract_path))
  expect_true(nzchar(schema_path))

  fixture <- jsonlite::read_json(fixture_path, simplifyVector = FALSE)
  contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
  schema <- jsonlite::read_json(schema_path, simplifyVector = FALSE)
  expect_identical(contract$`$schema`, basename(schema_path))
  expect_identical(
    schema$title,
    "Language-independent lexical-diversity measurement contract"
  )
  expect_identical(fixture$contract_id, contract$contract_id)
  expect_identical(fixture$contract_version, contract$contract_version)
  expect_identical(fixture$contract_version, "0.1.0")
  expected_statuses <- c("ok", "missing", "invalid_input")
  expected_missing_reasons <- c(
    "empty_input",
    "invalid_token",
    "insufficient_tokens_for_formula",
    "too_short_for_requested_parameter",
    "zero_denominator",
    "no_factor",
    "non_convergence",
    "boundary_censored",
    "unbounded_high"
  )
  expect_identical(
    unlist(contract$output_contract$statuses, use.names = FALSE),
    expected_statuses
  )
  expect_identical(
    unlist(contract$output_contract$missing_reasons, use.names = FALSE),
    expected_missing_reasons
  )
  expect_identical(
    getFromNamespace(".lex_missing_reasons", "ldfreq"),
    expected_missing_reasons
  )
  expect_false(grepl(
    "\\bdraft\\b",
    contract$output_contract$parameter_reporting,
    ignore.case = TRUE
  ))
  contract_fields <- unlist(
    contract$output_contract$result_fields,
    use.names = FALSE
  )
  expect_identical(
    names(fixture_api("contract-check", metrics = "ttr")),
    contract_fields
  )

  methods <- setNames(
    vapply(contract$metrics, `[[`, character(1L), "method_id"),
    vapply(contract$metrics, `[[`, character(1L), "metric_id")
  )
  assertion_count <- 0L

  for (case in fixture$cases) {
    tokens <- if (length(case$tokens) == 0L) {
      character()
    } else {
      unlist(case$tokens, use.names = FALSE)
    }
    for (assertion in case$assertions) {
      assertion_count <- assertion_count + 1L
      call <- list(tokens = tokens, metrics = assertion$metric_id)
      parameters <- assertion$parameters
      if (!is.null(parameters$segment_length)) {
        call$segment_length <- parameters$segment_length
      }
      if (!is.null(parameters$window_length)) {
        call$window_length <- parameters$window_length
      }
      if (!is.null(parameters$threshold)) {
        call$mtld_threshold <- parameters$threshold
      }
      if (!is.null(parameters$sample_size)) {
        call$sample_size <- parameters$sample_size
      }

      result <- do.call(fixture_api, call)
      context <- sprintf("case=%s metric=%s", case$id, assertion$metric_id)
      expect_identical(result$method_id, unname(methods[[assertion$metric_id]]), info = context)
      expect_identical(result$status, assertion$status, info = context)
      expect_identical(result$N, as.double(case$sufficient_statistics$N), info = context)
      expect_identical(result$V, as.double(case$sufficient_statistics$V), info = context)

      if (identical(assertion$status, "ok")) {
        difference <- abs(result$value - assertion$value)
        tolerance <- fixture$numeric_tolerance$absolute +
          fixture$numeric_tolerance$relative * abs(assertion$value)
        expect_true(difference <= tolerance, info = context)
        expect_true(is.na(result$missing_reason), info = context)
      } else {
        expect_true(is.na(result$value), info = context)
        expect_identical(result$missing_reason, assertion$missing_reason, info = context)
      }

      if (!is.null(assertion$expected_diagnostics)) {
        observed_diagnostics <- result$diagnostics[[1L]]
        for (diagnostic_name in names(assertion$expected_diagnostics)) {
          expected_diagnostic <- assertion$expected_diagnostics[[diagnostic_name]]
          observed_diagnostic <- observed_diagnostics[[diagnostic_name]]
          expect_false(is.null(observed_diagnostic), info = paste(context, diagnostic_name))
          diagnostic_difference <- abs(observed_diagnostic - expected_diagnostic)
          diagnostic_tolerance <- fixture$numeric_tolerance$absolute +
            fixture$numeric_tolerance$relative * abs(expected_diagnostic)
          expect_true(
            diagnostic_difference <= diagnostic_tolerance,
            info = paste(context, diagnostic_name)
          )
        }
      }
    }
  }

  expect_identical(assertion_count, 50L)
})
