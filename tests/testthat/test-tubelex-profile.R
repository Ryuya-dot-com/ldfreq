profile_lookup_function <- getFromNamespace(
  ".tubelex_frequency_profile",
  "ldfreq"
)
profile_resource_ref <- getFromNamespace(".lexres_resource_ref", "ldfreq")
profile_expectation <- getFromNamespace(".lexres_tubelex_expectation", "ldfreq")

synthetic_profile_tubelex_load <- function() {
  words <- enc2utf8(c("apple", "the", "é"))
  resources <- list(list(
    word = words,
    count = c(7403, 7448605, 21),
    videos = c(3027, 103830, 10),
    channels = c(2563, 60433, 7),
    totals = list(count = 171805865, videos = 105733, channels = 68405)
  ))
  names(resources) <- "tubelex_en_treebank_slim_csv_gz"
  list(
    status = "ok",
    failure_reason = NA_character_,
    resource_ref = profile_resource_ref(profile_expectation()),
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

test_that("TUBELEX query normalization is explicit and coverage-aware", {
  normalized <- profile_lookup_function(
    c("Apple", "apple", "missing"),
    normalization = "tubelex",
    loader = synthetic_profile_tubelex_load
  )
  identity <- profile_lookup_function(
    c("Apple", "apple", "missing"),
    normalization = "identity",
    loader = synthetic_profile_tubelex_load
  )

  expect_s3_class(normalized, "tubelex_frequency_profile")
  expect_identical(normalized$status, "ok")
  expect_identical(normalized$lookup$term, c("Apple", "apple", "missing"))
  expect_identical(normalized$lookup$lookup_term, c("apple", "apple", "missing"))
  expect_identical(normalized$lookup$matched, c(TRUE, TRUE, FALSE))
  expect_identical(identity$lookup$matched, c(FALSE, TRUE, FALSE))
  expect_identical(normalized$coverage$token_coverage, 2 / 3)
  expect_identical(normalized$coverage$type_coverage, 0.5)
  expect_identical(normalized$provenance$original_input_types, 3)
  expect_identical(normalized$provenance$normalized_lookup_types, 2)
  expect_identical(normalized$provenance$normalization_applied, TRUE)
  expect_identical(identity$provenance$normalization_applied, FALSE)
})

test_that("token- and type-weighted summaries remain conditional on matches", {
  result <- profile_lookup_function(
    c("apple", "apple", "the", "missing"),
    normalization = "identity",
    loader = synthetic_profile_tubelex_load
  )
  apple_zipf <- result$lookup$zipf[result$lookup$term == "apple"][[1L]]
  the_zipf <- result$lookup$zipf[result$lookup$term == "the"]

  expect_identical(result$summary$weighting, c("token", "type"))
  expect_equal(
    result$summary$mean_zipf[result$summary$weighting == "token"],
    mean(c(apple_zipf, apple_zipf, the_zipf)),
    tolerance = 1e-14
  )
  expect_equal(
    result$summary$mean_zipf[result$summary$weighting == "type"],
    mean(c(apple_zipf, the_zipf)),
    tolerance = 1e-14
  )
  expect_identical(result$summary$eligible_items, c(4, 3))
  expect_identical(result$summary$matched_items, c(3, 2))
  expect_true(is.na(result$lookup$zipf[result$lookup$term == "missing"]))
  expect_identical(result$provenance$unmatched_values_are_missing, TRUE)
  expect_identical(result$provenance$matched_only_summary, TRUE)
})

test_that("a tokenization object can feed the TUBELEX profile without ambiguity", {
  tokenization <- lexdiv_tokenize("Apple apple missing")
  result <- profile_lookup_function(
    tokenization,
    normalization = "tubelex",
    loader = synthetic_profile_tubelex_load
  )

  expect_identical(result$provenance$input_source, "lexdiv_tokenization")
  expect_identical(
    result$provenance$preprocessing_ref$tokenizer_id,
    "ldfreq-unicode-word-tokenizer"
  )
  expect_identical(result$lookup$term, c("Apple", "apple", "missing"))
})

test_that("invalid profile inputs fail atomically before resource loading", {
  calls <- 0L
  counting_loader <- function() {
    calls <<- calls + 1L
    synthetic_profile_tubelex_load()
  }
  result <- profile_lookup_function(
    factor("apple"),
    normalization = "tubelex",
    loader = counting_loader
  )

  expect_identical(result$status, "invalid_input")
  expect_identical(result$failure_reason, "invalid_term")
  expect_identical(calls, 0L)
  expect_identical(nrow(result$lookup), 0L)
  expect_true(all(is.na(result$summary$mean_zipf)))
})

test_that("resource failures preserve terms and unresolved measurements", {
  failure_loader <- function() {
    list(
      status = "resource_error",
      failure_reason = "resource_unavailable",
      resource_ref = profile_resource_ref(profile_expectation()),
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
  result <- profile_lookup_function(
    c("Apple", "missing"),
    normalization = "tubelex",
    loader = failure_loader
  )

  expect_identical(result$status, "resource_error")
  expect_identical(result$lookup$term, c("Apple", "missing"))
  expect_identical(result$lookup$lookup_term, c("apple", "missing"))
  expect_true(all(is.na(result$lookup$matched)))
  expect_true(all(is.na(result$summary$mean_zipf)))
})

test_that("the installed TUBELEX profile contract records the conditional release state", {
  skip_if_not_installed("jsonlite")
  contract_path <- system.file(
    "spec", "tubelex-frequency-profile-contract.json",
    package = "ldfreq"
  )
  schema_path <- system.file(
    "spec", "tubelex-frequency-profile-contract.schema.json",
    package = "ldfreq"
  )
  expect_true(nzchar(contract_path) && file.exists(contract_path))
  expect_true(nzchar(schema_path) && file.exists(schema_path))
  contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
  schema <- jsonlite::read_json(schema_path, simplifyVector = FALSE)
  empty <- profile_lookup_function(
    character(),
    normalization = "tubelex",
    loader = synthetic_profile_tubelex_load
  )

  expect_identical(
    contract$contract_id,
    "ldfreq-tubelex-frequency-profile"
  )
  expect_identical(contract$contract_version, "0.1.0-draft.1")
  expect_identical(
    contract$status,
    "public-api-release-candidate"
  )
  expect_identical(contract$public_api, TRUE)
  expect_identical(contract$release_approved, TRUE)
  expect_identical(
    unlist(contract$lookup_columns, use.names = FALSE),
    names(empty$lookup)
  )
  expect_identical(contract$summary$matched_only, TRUE)
  expect_identical(
    contract$summary$unmatched_measurements,
    "missing-not-zero"
  )
  expect_identical(schema$properties$contract_id$const, contract$contract_id)
})
