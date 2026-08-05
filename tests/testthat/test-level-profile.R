nj8_fixture <- function() {
  data.frame(
    NJ8 = c(1L, 1000L, 1001L, 2001L, 6001L, 8000L),
    Word = c(
      "the", "mom (mum, mummy)", "develop", "analysis", "rare", "extreme"
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

test_that("New JACET profiles expose exact and cumulative token/type rates", {
  result <- new_jacet8000_profile(
    c("The", "mum", "develop", "rare", "unknown", "the"),
    nj8_fixture()
  )

  expect_s3_class(result, "new_jacet8000_profile")
  expect_s3_class(result, "lexical_level_profile")
  expect_identical(result$status, "ok")
  expect_identical(
    names(result$summary),
    c(
      "weighting", "level", "level_label", "items", "proportion",
      "cumulative_items", "cumulative_proportion"
    )
  )
  expect_identical(result$lookup$level, c(1L, 1L, 2L, 7L, NA_integer_, 1L))
  token <- result$summary[result$summary$weighting == "token", ]
  type <- result$summary[result$summary$weighting == "type", ]
  expect_identical(token$items, c(3, 1, 0, 0, 0, 0, 1, 0, 1))
  expect_equal(token$proportion, c(3, 1, 0, 0, 0, 0, 1, 0, 1) / 6)
  expect_equal(token$cumulative_proportion[1:8], c(3, 4, 4, 4, 4, 4, 5, 5) / 6)
  expect_true(is.na(token$cumulative_proportion[[9L]]))
  expect_identical(type$items, c(2, 1, 0, 0, 0, 0, 1, 0, 1))
  expect_identical(result$coverage$token_coverage, 5 / 6)
  expect_identical(result$coverage$type_coverage, 4 / 5)
  expect_identical(result$provenance$off_list_in_denominator, TRUE)
  expect_identical(result$provenance$resource_bundled, FALSE)
  expect_identical(result$provenance$runtime_download, FALSE)
})

test_that("normalization and parenthetical expansion remain explicit", {
  default <- new_jacet8000_profile(c("The", "mum"), nj8_fixture())
  identity <- new_jacet8000_profile(
    c("The", "mum"),
    nj8_fixture(),
    normalization = "identity"
  )
  no_alias <- new_jacet8000_profile(
    "mum",
    nj8_fixture(),
    expand_parenthetical = FALSE
  )

  expect_identical(default$lookup$matched, c(TRUE, TRUE))
  expect_identical(identity$lookup$matched, c(FALSE, TRUE))
  expect_identical(no_alias$lookup$matched, FALSE)
  expect_identical(default$diagnostics$parenthetical_aliases_added, 2)
  expect_identical(no_alias$diagnostics$parenthetical_aliases_added, 0)
  expect_identical(
    default$provenance$query_normalization_id,
    "nfkc-trim-en-lower-v1"
  )
})

test_that("annotated tokenizations retain lemma exclusions and token indexes", {
  tokenization <- lexdiv_tokenize("Cats missing")
  annotated <- lexdiv_lemmatize(
    tokenization,
    lemmas = c("cat", NA_character_),
    backend_id = "test-backend",
    backend_version = "1"
  )
  wordlist <- data.frame(NJ8 = 1L, Word = "cat", stringsAsFactors = FALSE)
  result <- new_jacet8000_profile(
    annotated,
    wordlist,
    unit = "lemma"
  )

  expect_identical(result$lookup$term, "cat")
  expect_identical(result$lookup$token_index, 1L)
  expect_identical(result$coverage$input_tokens, 2)
  expect_identical(result$coverage$eligible_tokens, 1)
  expect_identical(result$coverage$selection_coverage, 0.5)
  expect_identical(result$coverage$token_coverage, 1)
  expect_identical(result$diagnostics$exclusion_reasons$reason, "missing_lemma")
  expect_identical(result$diagnostics$exclusion_reasons$tokens, 1)
})

test_that("AntBNC flemma conflicts remain explicit and selectable", {
  path <- antbnc_fixture_file()
  on.exit(unlink(path), add = TRUE)
  tokenization <- lexdiv_tokenize("Interesting interests saw")
  annotated <- lexdiv_flemmatize(tokenization, path)
  wordlist <- data.frame(
    NJ8 = c(1L, 2L, 7001L, 8000L),
    Word = c("interest", "see", "interesting", "saw"),
    stringsAsFactors = FALSE
  )

  antbnc <- new_jacet8000_profile(
    annotated,
    wordlist,
    unit = "flemma",
    flemma_conflict = "antbnc"
  )
  wordlist_first <- new_jacet8000_profile(
    annotated,
    wordlist,
    unit = "flemma",
    flemma_conflict = "wordlist"
  )

  expect_identical(antbnc$lookup$surface_term, c("Interesting", "interests", "saw"))
  expect_identical(antbnc$lookup$term, c("interest", "interest", "see"))
  expect_identical(antbnc$lookup$level, c(1L, 1L, 1L))
  expect_identical(antbnc$lookup$headword_conflict, c(TRUE, FALSE, TRUE))
  expect_identical(
    antbnc$lookup$headword_conflict_resolution,
    c("antbnc", "none", "antbnc")
  )
  expect_identical(
    antbnc$lookup$conflicting_surface_rank,
    c(7001L, NA_integer_, 8000L)
  )
  expect_identical(wordlist_first$lookup$level, c(8L, 1L, 8L))
  expect_identical(
    wordlist_first$lookup$headword_conflict_resolution,
    c("wordlist", "none", "wordlist")
  )
  expect_identical(antbnc$diagnostics$flemma_headword_conflicts, 2)
  expect_identical(antbnc$diagnostics$flemma_cross_level_conflicts, 2)
  expect_identical(antbnc$provenance$flemma_conflict_policy, "antbnc")
  expect_identical(wordlist_first$provenance$flemma_conflict_policy, "wordlist")
  expect_error(
    new_jacet8000_profile(
      annotated,
      wordlist,
      unit = "flemma",
      flemma_conflict = "error"
    ),
    "Interesting, saw"
  )
})

test_that("flemma overrides can resolve New JACET headword conflicts upstream", {
  path <- antbnc_fixture_file()
  on.exit(unlink(path), add = TRUE)
  overrides <- data.frame(
    form = c("interesting", "saw"),
    flemma = c("interesting", "saw"),
    stringsAsFactors = FALSE
  )
  annotated <- lexdiv_flemmatize(
    lexdiv_tokenize("Interesting saw"),
    path,
    overrides = overrides
  )
  wordlist <- data.frame(
    NJ8 = c(7001L, 8000L),
    Word = c("interesting", "saw"),
    stringsAsFactors = FALSE
  )
  result <- new_jacet8000_profile(annotated, wordlist, unit = "flemma")

  expect_identical(result$lookup$level, c(8L, 8L))
  expect_false(any(result$lookup$headword_conflict))
  expect_identical(result$diagnostics$flemma_headword_conflicts, 0)
  expect_true(all(result$lookup$unit_match_rule == "override"))
})

test_that("empty profiles retain all levels and undefined rates", {
  result <- new_jacet8000_profile(character(), nj8_fixture())

  expect_identical(result$status, "empty")
  expect_identical(nrow(result$lookup), 0L)
  expect_identical(nrow(result$summary), 18L)
  expect_true(all(result$summary$items == 0))
  expect_true(all(is.na(result$summary$proportion)))
  expect_true(is.na(result$coverage$token_coverage))
  expect_true(is.na(result$coverage$type_coverage))
})

test_that("local CSV provenance is exact and version labels are deterministic", {
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  utils::write.csv(nj8_fixture(), path, row.names = FALSE, fileEncoding = "UTF-8")
  result <- new_jacet8000_profile("the", path)
  repeated <- new_jacet8000_profile("the", nj8_fixture())

  expect_identical(result$provenance$resource_source_type, "local_csv")
  expect_identical(result$provenance$resource_source_file, basename(path))
  expect_match(result$provenance$resource_source_sha256, "^[0-9a-f]{64}$")
  expect_identical(
    result$provenance$resource_canonical_sha256,
    repeated$provenance$resource_canonical_sha256
  )
  expect_identical(result$provenance$resource_version, repeated$provenance$resource_version)
})

test_that("successful results and failures do not disclose absolute paths", {
  private_directory <- file.path(tempdir(), "ldfreq-private-path", "nested")
  dir.create(private_directory, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(private_directory, "private-list.csv")
  on.exit(unlink(file.path(tempdir(), "ldfreq-private-path"), recursive = TRUE), add = TRUE)
  utils::write.csv(nj8_fixture(), path, row.names = FALSE, fileEncoding = "UTF-8")

  result <- new_jacet8000_profile("the", path)
  printed <- paste(capture.output(print(result)), collapse = "\n")
  inspected <- paste(capture.output(str(result)), collapse = "\n")
  expect_identical(result$provenance$resource_source_file, basename(path))
  expect_false(grepl(private_directory, printed, fixed = TRUE))
  expect_false(grepl(private_directory, inspected, fixed = TRUE))

  missing_path <- file.path(private_directory, "missing", "secret.xlsx")
  missing_error <- tryCatch(
    new_jacet8000_profile("the", missing_path),
    error = conditionMessage
  )
  expect_identical(
    missing_error,
    "wordlist file does not exist or cannot be accessed."
  )
  expect_false(grepl(private_directory, missing_error, fixed = TRUE))

  if (requireNamespace("readxl", quietly = TRUE)) {
    broken_path <- file.path(private_directory, "broken.xlsx")
    writeBin(charToRaw("not an XLSX workbook"), broken_path)
    broken_error <- tryCatch(
      new_jacet8000_profile("the", broken_path),
      error = conditionMessage
    )
    expect_identical(
      broken_error,
      "wordlist XLSX sheet '新J8' could not be read from file 'broken.xlsx'."
    )
    expect_false(grepl(private_directory, broken_error, fixed = TRUE))
  }
})

test_that("rank and entry validation rejects ambiguous structural inputs", {
  duplicated_rank <- data.frame(
    NJ8 = c(1L, 1L),
    Word = c("a", "b"),
    stringsAsFactors = FALSE
  )
  expect_error(
    new_jacet8000_profile("a", duplicated_rank),
    "duplicate ranks"
  )
  out_of_range <- data.frame(NJ8 = 8001L, Word = "a", stringsAsFactors = FALSE)
  expect_error(
    new_jacet8000_profile("a", out_of_range),
    "1 through 8000"
  )
  expect_error(
    new_jacet8000_profile(
      "a",
      data.frame(rank = 1L, term = "a"),
      rank_column = "NJ8"
    ),
    "rank_column is not present"
  )

  collision <- data.frame(
    NJ8 = c(1001L, 1L),
    Word = c("same", "same"),
    stringsAsFactors = FALSE
  )
  resolved <- new_jacet8000_profile("same", collision)
  expect_identical(resolved$lookup$rank, 1L)
  expect_identical(resolved$diagnostics$normalized_collisions_resolved, 1)
  expect_identical(resolved$diagnostics$collision_policy, "lowest-rank-entry-wins")
})

test_that("official Japanese XLSX column names are auto-detected", {
  official_shape <- data.frame(
    `新J8順位` = c(1L, 6926L, 8000L),
    `代表レマ` = c("the", "nan", "extremist"),
    品詞 = c("冠詞類", "名詞", "名詞"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  result <- new_jacet8000_profile(c("nan", "extremist"), official_shape)

  expect_identical(result$lookup$rank, c(6926L, 8000L))
  expect_identical(result$lookup$level, c(7L, 8L))
  expect_identical(result$diagnostics$rank_column, "新J8順位")
  expect_identical(result$diagnostics$word_column, "代表レマ")
})

test_that("New JACET batch output is document-major and lossless", {
  documents <- list(
    first = c("The", "develop", "unknown"),
    second = character()
  )
  result <- new_jacet8000_profile_batch(
    documents,
    nj8_fixture(),
    unit = "surface"
  )
  first <- new_jacet8000_profile(
    documents$first,
    nj8_fixture(),
    unit = "surface"
  )

  expect_s3_class(result, "new_jacet8000_profile_batch")
  expect_s3_class(result, "lexical_level_profile_batch")
  expect_identical(result$status, "ok")
  expect_identical(unique(result$summary$document_id), c("first", "second"))
  expect_identical(result$summary$document_id, rep(c("first", "second"), each = 18L))
  expect_identical(result$lookup$document_id, rep.int("first", 3L))
  expect_identical(
    result$summary[result$summary$document_id == "first", -1L],
    first$summary
  )
  expect_identical(result$lookup[, -1L], first$lookup)
  expect_identical(result$coverage$eligible_tokens, c(3, 0))
  expect_identical(result$coverage$token_coverage, c(2 / 3, NA_real_))
  expect_identical(result$document_diagnostics$status, c("ok", "empty"))
  expect_identical(result$provenance$document_count, 2)
  expect_identical(result$provenance$resource_bundled, FALSE)
  expect_identical(result$provenance$returned_rows, 39)
})

test_that("New JACET batch accepts explicit data-frame IDs and lemma objects", {
  annotated <- lexdiv_lemmatize(
    lexdiv_tokenize("Cats missing"),
    lemmas = c("cat", NA_character_),
    backend_id = "test-backend",
    backend_version = "1"
  )
  frame <- data.frame(doc = c("b", "a"), stringsAsFactors = FALSE)
  frame$units <- I(list(annotated, c("rare", "unknown")))
  wordlist <- data.frame(
    NJ8 = c(1L, 6001L),
    Word = c("cat", "rare"),
    stringsAsFactors = FALSE
  )
  result <- new_jacet8000_profile_batch(
    frame,
    wordlist,
    id_col = "doc",
    terms_col = "units",
    unit = "lemma"
  )

  expect_identical(result$coverage$document_id, c("b", "a"))
  expect_identical(result$coverage$selection_coverage, c(0.5, 1))
  expect_identical(result$coverage$token_coverage, c(1, 0.5))
  expect_identical(result$exclusion_reasons$document_id, "b")
  expect_identical(result$exclusion_reasons$reason, "missing_lemma")
  expect_identical(result$document_provenance$input_source, c(
    "lexdiv_tokenization", "character_terms"
  ))
  expect_true(is.list(result$document_provenance$preprocessing_ref))
  expect_identical(
    result$document_provenance$preprocessing_ref[[1L]]$contract_id,
    "ldfreq-preprocessing"
  )
})

test_that("New JACET batch preserves flemma conflict policies", {
  path <- antbnc_fixture_file()
  on.exit(unlink(path), add = TRUE)
  annotated <- lexdiv_flemmatize(
    lexdiv_tokenize("Interesting interests saw"),
    path
  )
  wordlist <- data.frame(
    NJ8 = c(1L, 2L, 7001L, 8000L),
    Word = c("interest", "see", "interesting", "saw"),
    stringsAsFactors = FALSE
  )
  antbnc <- new_jacet8000_profile_batch(
    list(doc = annotated),
    wordlist,
    unit = "flemma",
    flemma_conflict = "antbnc"
  )
  wordlist_first <- new_jacet8000_profile_batch(
    list(doc = annotated),
    wordlist,
    unit = "flemma",
    flemma_conflict = "wordlist"
  )

  expect_identical(antbnc$lookup$level, c(1L, 1L, 1L))
  expect_identical(wordlist_first$lookup$level, c(8L, 1L, 8L))
  expect_identical(antbnc$document_diagnostics$flemma_headword_conflicts, 2)
  expect_identical(antbnc$document_diagnostics$flemma_cross_level_conflicts, 2)
  expect_error(
    new_jacet8000_profile_batch(
      list(doc = annotated),
      wordlist,
      unit = "flemma",
      flemma_conflict = "error"
    ),
    "Interesting, saw"
  )
})

test_that("empty and oversized New JACET batches are explicit", {
  empty <- new_jacet8000_profile_batch(
    setNames(list(), character()),
    nj8_fixture(),
    unit = "surface"
  )
  expect_identical(empty$status, "empty")
  expect_identical(nrow(empty$summary), 0L)
  expect_identical(nrow(empty$lookup), 0L)
  expect_identical(nrow(empty$coverage), 0L)
  expect_identical(empty$provenance$document_count, 0)

  expect_error(
    new_jacet8000_profile_batch(
      list(a = c("the", "develop")),
      nj8_fixture(),
      unit = "surface",
      max_rows = 19
    ),
    "exceeds max_rows"
  )
  expect_error(
    new_jacet8000_profile_batch(
      list(a = "the"),
      nj8_fixture(),
      unit = "surface",
      max_rows = 0
    ),
    "positive finite integer"
  )
})

test_that("New JACET batch results do not retain absolute resource paths", {
  private_directory <- file.path(tempdir(), "ldfreq-private-batch", "nested")
  dir.create(private_directory, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(private_directory, "private-list.csv")
  on.exit(unlink(file.path(tempdir(), "ldfreq-private-batch"), recursive = TRUE), add = TRUE)
  utils::write.csv(nj8_fixture(), path, row.names = FALSE, fileEncoding = "UTF-8")

  result <- new_jacet8000_profile_batch(
    list(document = "the"),
    path,
    unit = "surface"
  )
  printed <- paste(capture.output(print(result)), collapse = "\n")
  inspected <- paste(capture.output(str(result)), collapse = "\n")
  expect_identical(result$provenance$resource_source_file, basename(path))
  expect_false(grepl(private_directory, printed, fixed = TRUE))
  expect_false(grepl(private_directory, inspected, fixed = TRUE))
})

test_that("the base plot overlays a denominator-visible cumulative profile", {
  result <- new_jacet8000_profile(
    c("the", "mum", "develop", "unknown"),
    nj8_fixture()
  )
  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  on.exit({
    grDevices::dev.off()
    unlink(path)
  }, add = TRUE)
  plot_data <- plot(
    result,
    weighting = "type",
    scale = "proportion",
    show_legend = FALSE
  )
  without_off_list <- plot(
    result,
    weighting = "token",
    scale = "count",
    include_off_list = FALSE,
    show_legend = FALSE
  )

  expect_identical(nrow(plot_data), 9L)
  expect_identical(plot_data$level_label[[9L]], "Off-list")
  expect_identical(plot_data$exact_plot_value[[9L]], 0.25)
  expect_true(is.na(plot_data$cumulative_plot_value[[9L]]))
  expect_identical(nrow(without_off_list), 8L)
})

test_that("the installed level-profile contract matches the public result", {
  skip_if_not_installed("jsonlite")
  contract_path <- system.file(
    "spec", "lexical-level-profile-contract.json",
    package = "ldfreq"
  )
  schema_path <- system.file(
    "spec", "lexical-level-profile-contract.schema.json",
    package = "ldfreq"
  )
  expect_true(nzchar(contract_path) && file.exists(contract_path))
  expect_true(nzchar(schema_path) && file.exists(schema_path))
  contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
  schema <- jsonlite::read_json(schema_path, simplifyVector = FALSE)
  result <- new_jacet8000_profile(character(), nj8_fixture())

  expect_identical(contract$contract_id, "ldfreq-lexical-level-profile")
  expect_identical(contract$contract_version, "0.1.0-draft.3")
  expect_identical(contract$resource_boundary$caller_supplied, TRUE)
  expect_identical(contract$resource_boundary$bundled, FALSE)
  expect_identical(contract$resource_boundary$downloaded, FALSE)
  expect_identical(contract$provenance$source_filename_only, TRUE)
  expect_identical(contract$provenance$absolute_path_retained, FALSE)
  expect_identical(contract$provenance$absolute_path_printed, FALSE)
  expect_identical(contract$provenance$absolute_path_echoed_in_errors, FALSE)
  expect_identical(
    contract$batch$contract_id,
    "ldfreq-lexical-level-profile-batch"
  )
  expect_identical(contract$batch$contract_version, "0.1.0-draft.1")
  expect_identical(contract$batch$resource_read_validate_normalize_hash_count, 1L)
  expect_identical(contract$batch$absolute_path_retained, FALSE)
  expect_identical(
    unlist(contract$lookup_columns, use.names = FALSE),
    names(result$lookup)
  )
  expect_identical(
    unlist(contract$summary_columns, use.names = FALSE),
    names(result$summary)
  )
  expect_identical(
    schema$properties$contract_id$const,
    contract$contract_id
  )
})
