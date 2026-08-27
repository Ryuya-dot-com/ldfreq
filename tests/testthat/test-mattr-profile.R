mattr_profile_plan <- function(window_lengths, prefix = "mattr") {
  methods <- lexdiv_methods()
  method_id <- methods$method_id[methods$metric_id == "mattr"]
  lexdiv_plan(
    presets = character(),
    grids = lexdiv_grid(
      method_id,
      parameter = "window_length",
      values = window_lengths,
      request_id_prefix = prefix
    )
  )
}

test_that("MATTR profile preserves canonical summaries and exact local windows", {
  tokens <- c("a", "b", "a", "c", "d", "a", "e")
  plan <- mattr_profile_plan(c(3, 5))
  result <- lexdiv_mattr_profile(tokens, plan)
  canonical <- lexdiv_profile(tokens, plan)

  expect_s3_class(result, "lexdiv_mattr_profile")
  expect_identical(names(result), c(
    "summary", "windows", "exposure", "diagnostics", "provenance"
  ))
  expect_identical(result$summary, canonical)
  expect_identical(result$windows$request_id, c(
    rep("mattr_1", 5L), rep("mattr_2", 3L)
  ))
  expect_equal(
    result$windows$distinct_types,
    c(2, 3, 3, 3, 3, 4, 4, 4)
  )
  expect_equal(
    result$windows$value,
    c(2 / 3, 1, 1, 1, 1, rep(4 / 5, 3L))
  )
  expect_equal(result$diagnostics$local_mean, canonical$value)
  expect_identical(result$diagnostics$reconciliation_error, c(0, 0))
  expect_identical(result$provenance$plan_md5, plan$plan_md5)
  expect_identical(result$provenance$contains_token_strings, FALSE)
})

test_that("position exposure is explicit and normalized for every request", {
  tokens <- letters[1:7]
  result <- lexdiv_mattr_profile(tokens, mattr_profile_plan(c(3, 5)))
  first <- result$exposure[result$exposure$request_id == "mattr_1", ]
  second <- result$exposure[result$exposure$request_id == "mattr_2", ]

  expect_equal(first$exposure_count, c(1, 2, 3, 3, 3, 2, 1))
  expect_equal(second$exposure_count, c(1, 2, 3, 3, 3, 2, 1))
  expect_equal(first$window_inclusion_rate, first$exposure_count / 5)
  expect_equal(second$window_inclusion_rate, second$exposure_count / 3)
  expect_equal(sum(first$nominal_observation_weight), 1)
  expect_equal(sum(second$nominal_observation_weight), 1)
  expect_identical(result$diagnostics$endpoint_exposure_count, c(1, 1))
  expect_identical(result$diagnostics$maximum_exposure_count, c(3, 3))
})

test_that("empty invalid and short inputs keep canonical missingness without details", {
  plan <- mattr_profile_plan(5)
  empty <- lexdiv_mattr_profile(character(), plan)
  short <- lexdiv_mattr_profile(c("a", "b", "c"), plan)
  invalid <- lexdiv_mattr_profile(c("a", NA_character_), plan)

  expect_identical(empty$summary$status, "missing")
  expect_identical(empty$summary$missing_reason, "empty_input")
  expect_identical(short$summary$status, "missing")
  expect_identical(
    short$summary$missing_reason, "too_short_for_requested_parameter"
  )
  expect_identical(invalid$summary$status, "invalid_input")
  expect_identical(invalid$summary$missing_reason, "invalid_token")
  for (result in list(empty, short, invalid)) {
    expect_identical(nrow(result$windows), 0L)
    expect_identical(nrow(result$exposure), 0L)
    expect_identical(result$diagnostics$window_count, 0)
    expect_true(is.na(result$diagnostics$local_mean))
  }
})

test_that("MATTR profile accepts only MATTR plans and bounds all table rows", {
  expect_error(
    lexdiv_mattr_profile(letters, lexdiv_plan()),
    "only MATTR"
  )
  tokens <- c("a", "b", "a", "c", "d", "a", "e")
  plan <- mattr_profile_plan(3)
  expect_silent(lexdiv_mattr_profile(tokens, plan, max_rows = 14))
  expect_error(
    lexdiv_mattr_profile(tokens, plan, max_rows = 13),
    "exceeds max_rows"
  )
  expect_error(
    lexdiv_mattr_profile(character(), plan, max_rows = 1),
    "exceeds max_rows"
  )
  expect_error(
    lexdiv_mattr_profile(tokens, plan, max_rows = 0),
    "max_rows"
  )
})

test_that("random local windows agree with an independent slicing oracle", {
  set.seed(20260827)
  plan <- mattr_profile_plan(c(2, 3, 5, 7))
  vocabulary <- c("a", "b", "c", "d", "e", "f")
  for (iteration in seq_len(100L)) {
    tokens <- sample(vocabulary, sample(7:50, 1L), replace = TRUE)
    result <- lexdiv_mattr_profile(tokens, plan)
    for (request_index in seq_along(plan$specifications)) {
      specification <- plan$specifications[[request_index]]
      window_length <- specification$parameters$window_length
      expected <- vapply(
        seq_len(length(tokens) - window_length + 1L),
        function(start) {
          length(unique(tokens[start:(start + window_length - 1L)])) /
            window_length
        },
        numeric(1L)
      )
      observed <- result$windows$value[
        result$windows$request_index == request_index
      ]
      expect_equal(observed, expected)
      expect_equal(result$summary$value[[request_index]], mean(expected))
    }
  }
})

test_that("reversal reverses the local trajectory and preserves its mean", {
  tokens <- c("a", "a", "b", "c", "d", "e", "e", "e")
  plan <- mattr_profile_plan(4)
  forward <- lexdiv_mattr_profile(tokens, plan)
  backward <- lexdiv_mattr_profile(rev(tokens), plan)

  expect_equal(forward$windows$value, rev(backward$windows$value))
  expect_equal(forward$summary$value, backward$summary$value)
  expect_equal(forward$exposure$exposure_count, backward$exposure$exposure_count)
})

test_that("MATTR profile does not retain input lexical strings", {
  private_tokens <- c("private-token-a", "private-token-b", "private-token-a")
  result <- lexdiv_mattr_profile(private_tokens, mattr_profile_plan(2))
  serialized <- paste(capture.output(dput(result)), collapse = "\n")

  expect_false(grepl("private-token", serialized, fixed = TRUE))
  expect_false("term" %in% names(result$windows))
  expect_false("token" %in% names(result$exposure))
})

test_that("print summary and plot are concise and reusable", {
  one <- lexdiv_mattr_profile(letters[1:10], mattr_profile_plan(3))
  multiple <- lexdiv_mattr_profile(letters[1:10], mattr_profile_plan(c(3, 5)))
  printed <- capture.output(visibility <- withVisible(print(one)))
  expect_false(visibility$visible)
  expect_identical(visibility$value, one)
  expect_true(any(grepl("lexdiv_mattr_profile", printed, fixed = TRUE)))

  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  on.exit({
    grDevices::dev.off()
    unlink(path)
  }, add = TRUE)
  plotted <- plot(one)
  expect_identical(plotted, one$windows)
  expect_error(plot(multiple), "request_id is required")
  expect_error(plot(one, add_global_mean = NA), "add_global_mean")
  expect_error(plot(one, add_global_mean = 1), "add_global_mean")
  expect_error(plot(one, add_global_mean = c(TRUE, FALSE)), "add_global_mean")
  selected <- plot(multiple, request_id = "mattr_2", add_global_mean = FALSE)
  expect_identical(unique(selected$request_id), "mattr_2")
})

test_that("installed MATTR profile contract matches the implementation", {
  skip_if_not_installed("jsonlite")
  contract_path <- system.file(
    "spec", "mattr-profile-contract.json", package = "ldfreq"
  )
  schema_path <- system.file(
    "spec", "mattr-profile-contract.schema.json", package = "ldfreq"
  )
  expect_true(nzchar(contract_path) && file.exists(contract_path))
  expect_true(nzchar(schema_path) && file.exists(schema_path))
  contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
  schema <- jsonlite::read_json(schema_path, simplifyVector = FALSE)
  result <- lexdiv_mattr_profile(letters[1:10], mattr_profile_plan(3))

  expect_identical(contract$contract_id, result$provenance$contract_id)
  expect_identical(contract$contract_version, result$provenance$contract_version)
  expect_identical(
    contract$result_contract$schema_id,
    result$provenance$result_schema_id
  )
  expect_identical(
    unlist(contract$result_contract$components, use.names = FALSE),
    names(result)
  )
  expect_identical(
    unlist(contract$window_columns, use.names = FALSE),
    names(result$windows)
  )
  expect_identical(
    unlist(contract$exposure_columns, use.names = FALSE),
    names(result$exposure)
  )
  expect_identical(
    unlist(contract$diagnostic_columns, use.names = FALSE),
    names(result$diagnostics)
  )
  expect_identical(contract$privacy_boundary$token_strings_copied_to_result, FALSE)
  expect_identical(contract$interpretation$inferential_stability_test, FALSE)
  expect_identical(schema$properties$contract_id$const, contract$contract_id)
})
