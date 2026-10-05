test_that("TUBELEX diagnostic tables preserve documents and conditional summaries", {
  profiles <- tubelex_profile_batch(list(b = c("Apple", "apple", "zzunmatchedxyz", "zzunmatchedxyz"),
    a = c("the", "zzunmatchedxyz"), blank = character(), bad = c("the", NA_character_)))
  copy <- unserialize(serialize(profiles, NULL))
  report <- tubelex_diagnostics(profiles)
  expect_identical(profiles, copy)
  expect_identical(report$documents$document_id, names(profiles))
  expect_identical(report$summary$document_id, rep(names(profiles), each = 2L))
  expect_identical(report$documents$status, c("ok", "ok", "empty", "invalid_input"))
  expect_identical(report$summary$mean_zipf,
    unlist(lapply(profiles, function(x) x$summary$mean_zipf), use.names = FALSE))
  expect_identical(report$unmatched_terms$lookup_term, "zzunmatchedxyz")
  expect_identical(report$unmatched_terms$token_count, 3)
  expect_identical(report$unmatched_terms$document_count, 2)
  expect_identical(report$documents$token_coverage, c(0.5, 0.5, NA_real_, NA_real_))
  expect_equal(report$documents$eligible_tokens, c(4, 2, 0, NA))
  expect_identical(report$provenance, lapply(profiles, `[[`, "provenance"))
  expect_identical(report$diagnostics, lapply(profiles, `[[`, "diagnostics"))
  expect_true(any(report$normalization_mappings$lookup_changed))
  saved <- tempfile(fileext = ".rds"); on.exit(unlink(saved))
  saveRDS(list(profiles = profiles, report = report), saved)
  restored <- readRDS(saved)
  expect_identical(tubelex_diagnostics(restored$profiles), restored$report)
  expect_identical(tubelex_diagnostics(profiles$b)$documents$document_id, "document_1")
})

test_that("empty batches and all-unmatched documents retain typed results", {
  empty <- tubelex_diagnostics(stats::setNames(list(), character()))
  expect_identical(nrow(empty$summary), 0L)
  expect_identical(nrow(empty$documents), 0L)
  expect_identical(nrow(empty$unmatched_terms), 0L)
  expect_identical(empty$provenance, stats::setNames(list(), character()))
  result <- tubelex_diagnostics(tubelex_profile(c("zzunmatchedxyz", "<num>")))
  expect_identical(result$summary$coverage, c(0, 0))
  expect_true(all(is.na(result$summary$mean_zipf)))
  expect_identical(result$normalization_mappings$number_marker, c(FALSE, TRUE))
  expect_equal(sum(result$unmatched_terms$token_count), 2)
})

test_that("unresolved lookups are distinct from confirmed non-matches", {
  loader <- function() list(status = "resource_error", failure_reason = "resource_unavailable",
    resource_ref = ldfreq:::.lexres_resource_ref(ldfreq:::.lexres_tubelex_expectation()),
    diagnostics = list(fallback_attempted = FALSE, download_attempted = FALSE),
    manifest = NULL, resource = NULL)
  failed <- ldfreq:::.tubelex_profile(c("Apple", "zzunmatchedxyz"),
    normalization = "tubelex", loader = loader)
  result <- tubelex_diagnostics(failed)
  expect_identical(result$documents$status, "resource_error")
  expect_identical(result$documents$eligible_tokens, 2)
  expect_true(is.na(result$documents$unmatched_tokens))
  expect_equal(nrow(result$unmatched_terms), 0L)
  expect_true(all(is.na(result$normalization_mappings$matched)))
  expect_true(all(is.na(result$summary$mean_zipf)))
})

test_that("different preparation conditions never pool unmatched counts", {
  x <- tubelex_profile(c("Missingxyz", "<num>"), normalization = "identity")
  y <- tubelex_profile(c("Missingxyz", "<num>"), normalization = "tubelex")
  z <- tubelex_profile(lexdiv_tokenize("Missingxyz", tokenizer = "english"),
    tokenization_mismatch = "allow")
  report <- tubelex_diagnostics(list(x = x, y = y, z = z, duplicate = x))
  expect_identical(report$documents$condition_id,
    c("condition_1", "condition_2", "condition_3", "condition_1"))
  markers <- subset(report$unmatched_terms, lookup_term == "<num>")
  expect_identical(markers$document_count, c(2, 1))
  expect_identical(report$documents$tokenization_alignment[3],
    "known_different_tokenizer_explicitly_allowed")
  expect_identical(report$documents$tokenizer_id[3], "ldfreq-english-word-tokenizer")
  expect_true(is.na(report$documents$tokenizer_id[1]))
})

test_that("invalid shapes, inconsistent summaries and excessive inputs fail", {
  x <- tubelex_profile(c("apple", "zzunmatchedxyz"))
  expect_error(tubelex_diagnostics(list(x)), "plain named list")
  expect_error(tubelex_diagnostics(list(a = x, a = x)), "unique")
  expect_error(tubelex_diagnostics(c("apple", "the")), "plain named list")
  expect_error(tubelex_diagnostics(x, max_rows = 3), "max_rows")
  expect_error(tubelex_diagnostics(x, max_rows = NA), "max_rows")
  changed <- x; changed$coverage$matched_tokens <- 0
  expect_error(tubelex_diagnostics(changed), "invalid TUBELEX")
  changed <- x; changed$summary$mean_zipf[1] <- 0
  expect_error(tubelex_diagnostics(changed), "invalid TUBELEX")
  changed <- x; changed$lookup$matched[1] <- NA
  expect_error(tubelex_diagnostics(changed), "invalid TUBELEX")
  changed <- x; changed$lookup$lookup_term[1] <- "the"
  expect_error(tubelex_diagnostics(changed), "invalid TUBELEX")
  changed <- x; changed$provenance$query_normalization_id <- "unknown"
  expect_error(tubelex_diagnostics(changed), "invalid TUBELEX")
  changed <- x; changed$provenance$input_source <- "lexdiv_tokenization"
  expect_error(tubelex_diagnostics(changed), "invalid TUBELEX")
  changed <- x; changed$provenance$contract_version <- "0.1.0"
  expect_error(tubelex_diagnostics(changed), "invalid TUBELEX")
})

test_that("installed diagnostic contract matches reusable table columns", {
  skip_if_not_installed("jsonlite")
  contract <- jsonlite::read_json(system.file("spec", "tubelex-frequency-profile-contract.json",
    package = "ldfreq"))$diagnostic_tables
  result <- tubelex_diagnostics(stats::setNames(list(), character()))
  expect_identical(names(result), unlist(contract$components, use.names = FALSE))
  expect_identical(names(result$summary), unlist(contract$summary_columns, use.names = FALSE))
  expect_identical(names(result$unmatched_terms), unlist(contract$unmatched_columns, use.names = FALSE))
  expect_identical(names(result$normalization_mappings), unlist(contract$mapping_columns, use.names = FALSE))
  expect_false(contract$resource_lookup_repeated)
  expect_false(contract$learner_ability_inferred)
})
