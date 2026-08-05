lookup_function <- getFromNamespace(".lexres_lookup_tubelex", "ldfreq")
lookup_ref_function <- getFromNamespace(".lexres_lookup_ref", "ldfreq")
resource_ref_function <- getFromNamespace(".lexres_resource_ref", "ldfreq")
tubelex_expectation_function <- getFromNamespace(
  ".lexres_tubelex_expectation",
  "ldfreq"
)

synthetic_tubelex_load <- function() {
  words <- enc2utf8(c("apple", "the", "\u00e9"))
  resource <- list(
    word = words,
    count = c(7403, 7448605, 21),
    videos = c(3027, 103830, 10),
    channels = c(2563, 60433, 7),
    totals = list(count = 171805865, videos = 105733, channels = 68405)
  )
  resources <- list(resource)
  names(resources) <- "tubelex_en_treebank_slim_csv_gz"
  list(
    status = "ok",
    failure_reason = NA_character_,
    resource_ref = resource_ref_function(tubelex_expectation_function()),
    diagnostics = list(
      fallback_attempted = FALSE,
      download_attempted = FALSE
    ),
    manifest = list(
      lookup_unit = "surface-form",
      normalization_id = "nfkc-trim-root-lower-filtered-source-keys-v1"
    ),
    resource = resources
  )
}

test_that("the internal lookup preserves order, duplicates, and exact terms", {
  result <- lookup_function(
    c("apple", "missing", "apple", "Apple"),
    loader = synthetic_tubelex_load
  )
  repeated <- lookup_function(
    c("apple", "missing", "apple", "Apple"),
    loader = synthetic_tubelex_load
  )

  expect_identical(result, repeated)
  expect_identical(result$status, "ok")
  expect_identical(result$failure_reason, NA_character_)
  expect_identical(
    names(result),
    c(
      "status", "failure_reason", "lookup_ref", "resource_ref", "results",
      "coverage", "diagnostics"
    )
  )
  expect_identical(result$lookup_ref, lookup_ref_function())
  expect_identical(
    names(result$results),
    c(
      "query_index", "term", "matched", "resource_word", "count", "videos",
      "channels", "zipf", "video_prevalence", "channel_prevalence"
    )
  )
  expect_identical(result$results$query_index, 1:4)
  expect_identical(
    result$results$term,
    c("apple", "missing", "apple", "Apple")
  )
  expect_identical(result$results$matched, c(TRUE, FALSE, TRUE, FALSE))
  expect_identical(
    result$results$resource_word,
    c("apple", NA_character_, "apple", NA_character_)
  )
  expect_identical(result$results$count, c(7403, NA_real_, 7403, NA_real_))
  expect_true(all(is.na(result$results[!result$results$matched, 5:10])))
  expect_identical(result$diagnostics$duplicate_query_count, 1)
  expect_identical(result$diagnostics$order_preserved, TRUE)
  expect_identical(result$diagnostics$normalization_applied, FALSE)
  expect_identical(result$diagnostics$unmatched_values_are_missing, TRUE)
})

test_that("coverage distinguishes tokens and exact types", {
  result <- lookup_function(
    c("apple", "missing", "apple", "Apple"),
    loader = synthetic_tubelex_load
  )

  expect_identical(
    result$coverage,
    list(
      input_tokens = 4,
      input_types = 3,
      eligible_tokens = 4,
      eligible_types = 3,
      matched_tokens = 2,
      unmatched_tokens = 2,
      matched_types = 1,
      unmatched_types = 2,
      token_coverage = 0.5,
      type_coverage = 1 / 3
    )
  )
})

test_that("frequency and prevalence transformations follow the frozen formulas", {
  result <- lookup_function("apple", loader = synthetic_tubelex_load)
  parameters <- result$diagnostics$formula_parameters

  expect_equal(
    result$results$zipf,
    log10(1e9 * (7403 + 1) /
      (parameters$token_total + parameters$source_vocabulary_size)),
    tolerance = 1e-14
  )
  expect_equal(
    result$results$video_prevalence,
    log10((3027 + 1) / (parameters$video_total + 2)),
    tolerance = 1e-14
  )
  expect_equal(
    result$results$channel_prevalence,
    log10((2563 + 1) / (parameters$channel_total + 2)),
    tolerance = 1e-14
  )
})

test_that("case and Unicode normalization distinctions remain visible", {
  composed <- enc2utf8("\u00e9")
  decomposed <- enc2utf8("e\u0301")
  result <- lookup_function(
    c(composed, decomposed, "apple", "Apple"),
    loader = synthetic_tubelex_load
  )

  expect_identical(result$results$matched, c(TRUE, FALSE, TRUE, FALSE))
  expect_identical(result$results$term, c(composed, decomposed, "apple", "Apple"))

  unknown_marker <- composed
  Encoding(unknown_marker) <- "unknown"
  unknown_result <- lookup_function(
    unknown_marker,
    loader = synthetic_tubelex_load
  )
  expect_identical(unknown_result$results$matched, TRUE)
  expect_identical(Encoding(unknown_marker), "unknown")
})

test_that("empty input is a valid deterministic zero-row lookup", {
  first <- lookup_function(character(), loader = synthetic_tubelex_load)
  second <- lookup_function(character(), loader = synthetic_tubelex_load)

  expect_identical(first, second)
  expect_identical(first$status, "ok")
  expect_identical(nrow(first$results), 0L)
  expect_identical(first$coverage$input_tokens, 0)
  expect_identical(first$coverage$input_types, 0)
  expect_true(is.na(first$coverage$token_coverage))
  expect_true(is.na(first$coverage$type_coverage))
})

test_that("invalid input fails atomically before resource loading", {
  calls <- 0L
  counting_loader <- function() {
    calls <<- calls + 1L
    synthetic_tubelex_load()
  }
  bytes_term <- enc2utf8("\u00e9")
  Encoding(bytes_term) <- "bytes"
  latin1_term <- iconv("\u00e9", from = "UTF-8", to = "latin1")
  Encoding(latin1_term) <- "latin1"
  invalid_inputs <- list(
    c("apple", NA_character_),
    c("apple", ""),
    factor("apple"),
    matrix("apple", nrow = 1L),
    structure("apple", names = "term"),
    bytes_term,
    latin1_term
  )

  for (input in invalid_inputs) {
    result <- lookup_function(input, loader = counting_loader)
    expect_identical(result$status, "invalid_input")
    expect_identical(result$failure_reason, "invalid_term")
    expect_identical(nrow(result$results), 0L)
    expect_identical(result$diagnostics$normalization_applied, FALSE)
    expect_identical(result$diagnostics$fallback_attempted, FALSE)
    expect_identical(result$diagnostics$download_attempted, FALSE)
  }
  expect_identical(calls, 0L)
})

test_that("resource failures preserve queries without classifying them", {
  failure_loader <- function(reason) function() {
    list(
      status = "resource_error",
      failure_reason = reason,
      resource_ref = resource_ref_function(tubelex_expectation_function()),
      diagnostics = list(
        artifact_locator_id = "resource.manifest.dcf",
        artifact_id = "resource_manifest",
        detection_stage = "availability",
        fallback_attempted = FALSE,
        download_attempted = FALSE,
        observed_state = "missing"
      ),
      manifest = NULL,
      resource = NULL
    )
  }
  reasons <- c(
    "resource_unavailable",
    "hash_mismatch",
    "unsupported_resource_version",
    "schema_mismatch"
  )

  for (reason in reasons) {
    result <- lookup_function(
      c("apple", "missing"),
      loader = failure_loader(reason)
    )
    expect_identical(result$status, "resource_error")
    expect_identical(result$failure_reason, reason)
    expect_identical(result$results$term, c("apple", "missing"))
    expect_true(all(is.na(result$results$matched)))
    expect_true(all(is.na(result$results[, 4:10])))
    expect_identical(result$coverage$input_tokens, 2)
    expect_identical(result$coverage$input_types, 2)
    expect_true(is.na(result$coverage$matched_tokens))
    expect_identical(result$diagnostics$fallback_attempted, FALSE)
    expect_identical(result$diagnostics$download_attempted, FALSE)
  }
})

test_that("the installed contract records the internal and offline boundary", {
  skip_if_not_installed("jsonlite")
  contract_path <- system.file(
    "spec", "lexical-resource-lookup-contract.json",
    package = "ldfreq"
  )
  schema_path <- system.file(
    "spec", "lexical-resource-lookup-contract.schema.json",
    package = "ldfreq"
  )
  expect_true(nzchar(contract_path) && file.exists(contract_path))
  expect_true(nzchar(schema_path) && file.exists(schema_path))

  contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
  schema <- jsonlite::read_json(schema_path, simplifyVector = FALSE)
  column_names <- vapply(
    contract$result_contract$columns,
    function(column) column$name,
    character(1L)
  )
  coverage_names <- unlist(
    contract$coverage_contract$fields,
    use.names = FALSE
  )
  empty_result <- lookup_function(
    character(),
    loader = synthetic_tubelex_load
  )

  expect_identical(contract$contract_id, "ldfreq-lexical-resource-lookup")
  expect_identical(contract$contract_version, "0.1.0-draft.1")
  expect_identical(contract$status, "internal-release-candidate")
  expect_identical(contract$public_api, FALSE)
  expect_identical(contract$release_approved, TRUE)
  expect_identical(contract$input_contract$normalization_applied, FALSE)
  expect_identical(
    contract$matching_contract$unmatched_measurements,
    "missing-not-zero"
  )
  expect_identical(column_names, names(empty_result$results))
  expect_identical(coverage_names, names(empty_result$coverage))
  expect_identical(contract$runtime_policy$network_access, FALSE)
  expect_identical(contract$runtime_policy$download, FALSE)
  expect_identical(contract$runtime_policy$fallback, FALSE)
  expect_identical(
    schema$title,
    "ldfreq internal lexical-resource lookup contract"
  )
  expect_identical(schema$additionalProperties, FALSE)
})
