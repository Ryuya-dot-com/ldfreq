norm_profile_fixture <- function() {
  list(
    norms = data.frame(
      term = c("alpha", "beta", "gamma"),
      familiarity = c(6, 4, NA_real_),
      concreteness = c(2, 5, 7),
      private_note = c("a", "b", "c"),
      stringsAsFactors = FALSE
    ),
    specs = data.frame(
      measure_id = c("familiarity", "concreteness"),
      value_column = c("familiarity", "concreteness"),
      construct_id = c("subjective_familiarity", "concreteness"),
      value_unit = c("seven_point_rating", "seven_point_rating"),
      direction = c("higher", "descriptive"),
      language = c("English", "English"),
      variety = c("unspecified", "unspecified"),
      population_id = c("example_adults", "example_adults"),
      collection_year = c("2025", "2025"),
      valid_min = c(1, 1),
      valid_max = c(7, 7),
      stringsAsFactors = FALSE
    ),
    resource = list(
      resource_id = "example_norms",
      resource_version = "2025-01",
      creator = "Example creator",
      source_reference = "Example citation",
      data_license = "Example terms; verify before redistribution",
      transformation_id = "none",
      lookup_unit = "caller_prepared_term",
      resource_key_normalization_id = "caller-prepared-v1"
    )
  )
}

test_that("norm profiles preserve the frozen component and table topology", {
  fixture <- norm_profile_fixture()
  result <- lexdiv_norm_profile(
    c("alpha", "alpha", "gamma", "outside"),
    fixture$norms,
    "term",
    fixture$specs,
    fixture$resource
  )

  expect_s3_class(result, "lexdiv_norm_profile")
  expect_identical(
    names(result),
    c("status", "summary", "lookup", "coverage", "provenance", "diagnostics")
  )
  expect_identical(result$status, "ok")
  expect_identical(
    names(result$lookup),
    c("input_index", "term", "measure_id", "lookup_status", "value", "value_status")
  )
  expect_identical(
    names(result$summary),
    c(
      "result_order", "resource_id", "resource_version", "measure_id",
      "construct_id", "value_unit", "direction", "language", "variety",
      "population_id", "collection_year", "statistic_id", "weighting",
      "type_identity", "estimate", "status", "missing_reason",
      "input_units", "matched_units", "unmatched_units",
      "observed_value_units", "matched_missing_value_units",
      "resource_coverage", "value_coverage", "annotation_coverage"
    )
  )
  expect_identical(
    names(result$coverage),
    c(
      "result_order", "resource_id", "resource_version", "measure_id",
      "weighting", "input_units", "matched_units", "unmatched_units",
      "observed_value_units", "matched_missing_value_units",
      "resource_coverage", "value_coverage", "annotation_coverage"
    )
  )
  expect_equal(nrow(result$lookup), 8)
  expect_equal(nrow(result$summary), 4)
  expect_identical(
    result$lookup$measure_id,
    rep(fixture$specs$measure_id, times = 4)
  )
  expect_identical(result$lookup$term, rep(
    c("alpha", "alpha", "gamma", "outside"),
    each = 2
  ))
})

test_that("token and exact-type weighting have explicit denominators", {
  fixture <- norm_profile_fixture()
  result <- lexdiv_norm_profile(
    c("alpha", "alpha", "gamma", "outside"),
    fixture$norms,
    "term",
    fixture$specs,
    fixture$resource
  )
  token_familiarity <- result$summary[
    result$summary$measure_id == "familiarity" &
      result$summary$weighting == "token",
  ]
  type_familiarity <- result$summary[
    result$summary$measure_id == "familiarity" &
      result$summary$weighting == "type",
  ]

  expect_equal(token_familiarity$estimate, 6)
  expect_equal(token_familiarity$input_units, 4)
  expect_equal(token_familiarity$matched_units, 3)
  expect_equal(token_familiarity$observed_value_units, 2)
  expect_equal(token_familiarity$resource_coverage, 3 / 4)
  expect_equal(token_familiarity$value_coverage, 2 / 4)
  expect_equal(token_familiarity$annotation_coverage, 2 / 3)

  expect_equal(type_familiarity$estimate, 6)
  expect_equal(type_familiarity$input_units, 3)
  expect_equal(type_familiarity$matched_units, 2)
  expect_equal(type_familiarity$observed_value_units, 1)
  expect_equal(type_familiarity$resource_coverage, 2 / 3)
  expect_equal(type_familiarity$value_coverage, 1 / 3)
  expect_equal(type_familiarity$annotation_coverage, 1 / 2)
  expect_true(is.na(token_familiarity$type_identity))
  expect_identical(type_familiarity$type_identity, "exact_lookup_term")
})

test_that("OOV and missing annotations remain distinct and are not imputed", {
  fixture <- norm_profile_fixture()
  result <- lexdiv_norm_profile(
    c("gamma", "outside"),
    fixture$norms,
    "term",
    fixture$specs[1, , drop = FALSE],
    fixture$resource
  )

  expect_identical(
    result$lookup$lookup_status,
    c("matched_resource", "unknown_to_resource")
  )
  expect_identical(
    result$lookup$value_status,
    c("missing_annotation", "not_applicable_oov")
  )
  expect_true(all(is.na(result$lookup$value)))
  expect_true(all(result$summary$status == "missing"))
  expect_true(all(result$summary$missing_reason == "no_observed_values"))
  expect_true(all(is.na(result$summary$estimate)))
  expect_false(result$diagnostics$oov_imputation)
  expect_false(result$diagnostics$missing_value_imputation)
  expect_false(result$diagnostics$automatic_coverage_threshold)
})

test_that("empty and wholly unmatched inputs have different states", {
  fixture <- norm_profile_fixture()
  empty <- lexdiv_norm_profile(
    character(), fixture$norms, "term", fixture$specs, fixture$resource
  )
  unmatched <- lexdiv_norm_profile(
    "outside", fixture$norms, "term", fixture$specs, fixture$resource
  )

  expect_identical(empty$status, "empty")
  expect_equal(nrow(empty$lookup), 0)
  expect_true(all(empty$summary$missing_reason == "empty_input"))
  expect_true(all(is.na(empty$summary$resource_coverage)))

  expect_identical(unmatched$status, "ok")
  expect_true(all(unmatched$summary$missing_reason == "no_matched_keys"))
  expect_true(all(unmatched$summary$resource_coverage == 0))
  expect_true(all(is.na(unmatched$summary$annotation_coverage)))
})

test_that("resource row order and unused columns cannot affect results", {
  fixture <- norm_profile_fixture()
  terms <- c("beta", "alpha", "gamma", "beta")
  original <- lexdiv_norm_profile(
    terms, fixture$norms, "term", fixture$specs, fixture$resource
  )
  reordered_norms <- fixture$norms[c(3, 1, 2), ]
  reordered_norms$another_unused <- c("secret-3", "secret-1", "secret-2")
  reordered <- lexdiv_norm_profile(
    terms, reordered_norms, "term", fixture$specs, fixture$resource
  )

  expect_identical(original$summary, reordered$summary)
  expect_identical(original$lookup, reordered$lookup)
  expect_identical(original$coverage, reordered$coverage)
  expect_equal(original$diagnostics$unused_norm_column_count, 1)
  expect_equal(reordered$diagnostics$unused_norm_column_count, 2)
  serialized <- paste(capture.output(str(reordered)), collapse = "\n")
  expect_false(grepl("secret", serialized, fixed = TRUE))
  expect_false(grepl("private_note", serialized, fixed = TRUE))
})

test_that("structurally invalid resources fail before lookup", {
  fixture <- norm_profile_fixture()
  duplicate <- fixture$norms
  duplicate$term[[3]] <- "alpha"
  expect_error(
    lexdiv_norm_profile(
      "alpha", duplicate, "term", fixture$specs, fixture$resource
    ),
    "unique"
  )

  wrong_order <- fixture$resource[rev(names(fixture$resource))]
  expect_error(
    lexdiv_norm_profile(
      "alpha", fixture$norms, "term", fixture$specs, wrong_order
    ),
    "exact ordered fields"
  )

  wrong_specs <- fixture$specs[rev(names(fixture$specs))]
  expect_error(
    lexdiv_norm_profile(
      "alpha", fixture$norms, "term", wrong_specs, fixture$resource
    ),
    "exact ordered columns"
  )

  out_of_range <- fixture$norms
  out_of_range$familiarity[[1]] <- 8
  expect_error(
    lexdiv_norm_profile(
      "alpha", out_of_range, "term", fixture$specs, fixture$resource
    ),
    "above valid_max"
  )
})

test_that("row budget covers all reusable result tables", {
  fixture <- norm_profile_fixture()
  one_spec <- fixture$specs[1, , drop = FALSE]
  expect_error(
    lexdiv_norm_profile(
      rep("alpha", 4), fixture$norms, "term", one_spec,
      fixture$resource, max_rows = 7
    ),
    "planned result rows"
  )
  result <- lexdiv_norm_profile(
    rep("alpha", 4), fixture$norms, "term", one_spec,
    fixture$resource, max_rows = 8
  )
  expect_equal(result$diagnostics$planned_lookup_rows, 4)
  expect_equal(result$diagnostics$planned_summary_rows, 2)
  expect_equal(result$diagnostics$planned_coverage_rows, 2)
  expect_equal(result$diagnostics$planned_result_rows, 8)
})

test_that("public signature has no implicit normalization control", {
  expect_identical(
    names(formals(lexdiv_norm_profile)),
    c("terms", "norms", "key", "measure_specs", "resource", "weightings", "max_rows")
  )
  expect_warning(
    lexdiv_norm_profile(
      "alpha beta", norm_profile_fixture()$norms, "term",
      norm_profile_fixture()$specs, norm_profile_fixture()$resource
    ),
    "one string with whitespace"
  )
  expect_null(getS3method("plot", "lexdiv_norm_profile", optional = TRUE))
  expect_null(getS3method("summary", "lexdiv_norm_profile", optional = TRUE))
  expect_null(getS3method("as.data.frame", "lexdiv_norm_profile", optional = TRUE))
})

test_that("print is bounded, coverage-explicit, and returns its input", {
  fixture <- norm_profile_fixture()
  measure_count <- 8L
  specs <- fixture$specs[rep(1, measure_count), ]
  specs$measure_id <- paste0("measure_", seq_len(measure_count))
  specs$value_column <- paste0("value_", seq_len(measure_count))
  norms <- fixture$norms["term"]
  for (column in specs$value_column) norms[[column]] <- c(1, 2, 3)
  result <- lexdiv_norm_profile(
    "alpha", norms, "term", specs, fixture$resource
  )

  output <- capture.output(returned <- print(result))
  expect_identical(returned, result)
  expect_true(any(grepl("4 additional summary rows omitted", output, fixed = TRUE)))
  expect_true(any(grepl("inspect $coverage", output, fixed = TRUE)))
  expect_lt(length(output), 40)
})

test_that("normative contract matches the live result", {
  skip_if_not_installed("jsonlite")
  fixture <- norm_profile_fixture()
  result <- lexdiv_norm_profile(
    "alpha", fixture$norms, "term", fixture$specs, fixture$resource
  )
  contract <- jsonlite::read_json(system.file(
    "spec", "norm-profile-contract.json", package = "ldfreq"
  ))
  schema <- jsonlite::read_json(system.file(
    "spec", "norm-profile-contract.schema.json", package = "ldfreq"
  ))

  expect_identical(contract$contract_version, result$provenance$contract_version)
  expect_identical(contract$result_contract$schema_version,
    result$provenance$result_schema_version)
  expect_identical(unlist(contract$result_contract$components), names(result))
  expect_identical(unlist(contract$result_contract$lookup_columns), names(result$lookup))
  expect_identical(unlist(contract$result_contract$summary_columns), names(result$summary))
  expect_identical(unlist(contract$result_contract$coverage_columns), names(result$coverage))
  expect_identical(schema$properties$contract_version$const, "0.1.0")
})

test_that("randomized results agree with an independent direct oracle", {
  fixture <- norm_profile_fixture()
  set.seed(260827)

  for (iteration in seq_len(100)) {
    resource_size <- sample.int(15, 1)
    keys <- paste0("w", seq_len(resource_size))
    values <- sample(c(NA_real_, seq(-5, 5, by = 0.5)), resource_size, replace = TRUE)
    norms <- data.frame(term = keys, score = values, stringsAsFactors = FALSE)
    specs <- fixture$specs[1, , drop = FALSE]
    specs$measure_id <- "score"
    specs$value_column <- "score"
    specs$construct_id <- "random_score"
    specs$direction <- "descriptive"
    specs$valid_min <- -5
    specs$valid_max <- 5
    terms <- sample(
      c(keys, "outside_a", "outside_b"),
      sample.int(30, 1) - 1L,
      replace = TRUE
    )
    result <- lexdiv_norm_profile(
      terms, norms, "term", specs, fixture$resource
    )

    for (weighting in c("token", "type")) {
      selected <- if (weighting == "token") terms else terms[!duplicated(terms)]
      indices <- match(selected, keys)
      matched <- !is.na(indices)
      observed_values <- values[indices[matched]]
      observed_values <- observed_values[!is.na(observed_values)]
      row <- result$summary[result$summary$weighting == weighting, ]

      expect_equal(row$input_units, length(selected))
      expect_equal(row$matched_units, sum(matched))
      expect_equal(row$observed_value_units, length(observed_values))
      expected_mean <- if (length(observed_values)) {
        mean(sort(observed_values, method = "radix"))
      } else {
        NA_real_
      }
      expect_equal(row$estimate, expected_mean)
      expected_resource_coverage <- if (length(selected)) {
        sum(matched) / length(selected)
      } else {
        NA_real_
      }
      expected_annotation_coverage <- if (sum(matched)) {
        length(observed_values) / sum(matched)
      } else {
        NA_real_
      }
      expect_equal(row$resource_coverage, expected_resource_coverage)
      expect_equal(row$annotation_coverage, expected_annotation_coverage)
    }
  }
})
