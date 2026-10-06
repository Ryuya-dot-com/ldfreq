norm_batch_fixture <- function() {
  list(norms = data.frame(term = c("alpha", "beta", "gamma"),
    familiarity = c(6, 4, NA_real_), aoa = c(5, 8, 12), ignored = "private"),
    specs = data.frame(measure_id = c("familiarity", "aoa"),
      value_column = c("familiarity", "aoa"),
      construct_id = c("familiarity", "age_of_acquisition"),
      value_unit = c("rating", "years"), direction = c("higher", "descriptive"),
      language = "English", variety = "unspecified", population_id = "authored",
      collection_year = "not_observed", valid_min = 1, valid_max = c(7, 20)),
    resource = list(resource_id = "authored", resource_version = "1",
      creator = "Example", source_reference = "Authored demonstration",
      data_license = "Example only", transformation_id = "none",
      lookup_unit = "surface", resource_key_normalization_id = "exact"))
}

norm_batch_call <- function(documents, fixture = norm_batch_fixture(), ...) {
  lexdiv_norm_profile_batch(documents, fixture$norms, "term", fixture$specs,
    fixture$resource, ...)
}

test_that("batch norms preserve single results and all document states", {
  fixture <- norm_batch_fixture()
  docs <- list(mixed = c("alpha", "alpha", "gamma", "outside"),
    blank = character(), unmatched = "outside", unannotated = "gamma")
  original <- list(docs = docs, fixture = fixture)
  batch <- norm_batch_call(docs)
  expect_s3_class(batch, "lexdiv_norm_profile_batch")
  expect_identical(batch$status, "ok")
  expect_identical(batch$provenance$document_ids, names(docs))
  expect_identical(batch$diagnostics$documents$status, c("ok", "empty", "ok", "ok"))
  for (id in names(docs)) {
    single <- lexdiv_norm_profile(docs[[id]], fixture$norms, "term",
      fixture$specs, fixture$resource)
    for (component in c("summary", "lookup", "coverage")) {
      rows <- batch[[component]]
      actual <- rows[rows$document_id == id, names(single[[component]]), drop = FALSE]
      rownames(actual) <- NULL
      expect_identical(actual, single[[component]])
    }
    expect_identical(batch$provenance[names(single$provenance)], single$provenance)
  }
  first <- batch$summary[batch$summary$document_id == "mixed", ]
  expect_equal(first$estimate, c(6, 6, 22/3, 8.5))
  expect_equal(first$resource_coverage, c(3/4, 2/3, 3/4, 2/3))
  expect_equal(first$value_coverage, c(1/2, 1/3, 3/4, 2/3))
  expect_equal(first$annotation_coverage, c(2/3, 1/2, 1, 1))
  expect_identical(list(docs = docs, fixture = fixture), original)
  expect_false("ignored" %in% names(batch$lookup))
  expect_equal(batch$diagnostics$batch$unused_norm_column_count, 1)
})

test_that("data-frame adapters, custom columns and empty batches retain types", {
  docs <- list(second = c("beta", "alpha"), first = character())
  table <- data.frame(id = names(docs), register = c("speech", "writing"))
  table$words <- unname(docs)
  expect_identical(norm_batch_call(table, id_col = "id", terms_col = "words"),
    norm_batch_call(docs))
  empty <- norm_batch_call(setNames(list(), character()))
  expect_identical(empty$status, "empty")
  expect_identical(empty, norm_batch_call(table[FALSE, ], id_col = "id", terms_col = "words"))
  for (name in c("summary", "lookup", "coverage")) {
    expect_identical(empty[[name]], norm_batch_call(docs)[[name]][FALSE, ])
  }
  expect_equal(nrow(empty$diagnostics$documents), 0)
})

test_that("global row bound is checked before lookup and resource validation is shared", {
  docs <- list(a = c("alpha", "alpha", "gamma", "outside"), b = character())
  expect_equal(norm_batch_call(docs, max_rows = 24)$diagnostics$batch$planned_result_rows, 24)
  prepared <- 0L
  original <- getFromNamespace(".lexnorm_norms", "ldfreq")
  local_mocked_bindings(.lexnorm_norms = function(...) {
    prepared <<- prepared + 1L
    original(...)
  }, .lexnorm_lookup_long = function(...) stop("LOOKUP_REACHED"), .package = "ldfreq")
  expect_error(norm_batch_call(docs, max_rows = 23), "exceed max_rows")
  expect_identical(prepared, 1L)
  expect_error(norm_batch_call(docs, max_rows = 24), "LOOKUP_REACHED")
})

test_that("invalid batches fail clearly and whitespace terms are not silently split", {
  for (invalid in list(NA_character_, 1, factor("alpha"), "", list("alpha"))) {
    expect_error(norm_batch_call(list(bad_document = invalid)), "Document.*bad_document")
  }
  expect_error(norm_batch_call(list("alpha")), "plain named list")
  expect_error(norm_batch_call(setNames(list("alpha", "beta"), c("d", "d"))), "unique")
  expect_error(norm_batch_call(list(a = "alpha"), id_col = "same", terms_col = "same"), "different")
  expect_error(norm_batch_call(list(a = "alpha"), max_rows = Inf), "positive finite whole")
  fixture <- norm_batch_fixture()
  fixture$norms$term[2] <- "alpha"
  expect_error(norm_batch_call(setNames(list(), character()), fixture), "unique")
  expect_warning(result <- norm_batch_call(list(sentence = "alpha beta")), "sentence")
  expect_identical(unique(result$lookup$term), "alpha beta")
})

test_that("shared inputs are prepared once across many valid documents", {
  prepared <- 0L
  original <- getFromNamespace(".lexnorm_norms", "ldfreq")
  local_mocked_bindings(.lexnorm_norms = function(...) {
    prepared <<- prepared + 1L
    original(...)
  }, .package = "ldfreq")
  result <- norm_batch_call(list(a = "alpha", b = "beta", empty = character()))
  expect_identical(prepared, 1L)
  expect_equal(result$provenance$document_count, 3)
})

test_that("Unicode labels and persistence retain identity without normalization", {
  fixture <- norm_batch_fixture()
  fixture$norms$term <- c("caf\u00e9", "cafe\u0301", "\u65e5\u672c")
  docs <- setNames(list(c("caf\u00e9", "cafe\u0301", "caf\u00e9"), "\u65e5\u672c"),
    c("\u6587\u66f8", "caf\u00e9"))
  result <- norm_batch_call(docs, fixture)
  expect_equal(result$diagnostics$documents$input_types, c(2, 1))
  expect_equal(result$summary$estimate[1:2], c(16/3, 5))
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(result, path)
  expect_identical(readRDS(path), result)
  output <- capture.output(returned <- withVisible(print(result)))
  expect_identical(returned$value, result)
  expect_false(returned$visible)
  expect_true(any(grepl("document-specific", output, fixed = TRUE)))
})

test_that("generated batches agree with independent count and mean arithmetic", {
  set.seed(20261004)
  fixture <- norm_batch_fixture()
  for (iteration in seq_len(25)) {
    docs <- setNames(lapply(seq_len(3), function(i)
      sample(c(fixture$norms$term, "outside"), sample(0:8, 1), replace = TRUE)),
      c("z", "a", "m"))
    result <- norm_batch_call(docs, fixture, weightings = c("type", "token"))
    expected <- lapply(seq_len(nrow(result$summary)), function(i) {
      row <- result$summary[i, ]
      words <- docs[[row$document_id]]
      if (row$weighting == "type") words <- unique(words)
      present <- words %in% fixture$norms$term
      values <- vapply(words[present], function(w)
        fixture$norms[[row$measure_id]][fixture$norms$term == w], numeric(1))
      values <- values[!is.na(values)]
      c(input = length(words), matched = sum(present), observed = length(values),
        estimate = if (length(values)) sum(values)/length(values) else NA_real_)
    })
    expected <- do.call(rbind, expected)
    expect_equal(unname(as.matrix(result$summary[c("input_units", "matched_units",
      "observed_value_units", "estimate")])), unname(expected))
  }
})

test_that("norm batch contract matches the live tables and provenance", {
  skip_if_not_installed("jsonlite")
  result <- norm_batch_call(list(a = "alpha"))
  contract <- jsonlite::read_json(system.file("spec", "norm-profile-batch-contract.json", package = "ldfreq"))
  expect_identical(contract$contract_version, result$provenance$batch_contract_version)
  expect_identical(unlist(contract$result_contract$components), names(result))
  for (table in c("summary", "lookup", "coverage")) {
    expect_identical(unlist(contract$result_contract[[paste0(table, "_columns")]]), names(result[[table]]))
  }
  expect_identical(unlist(contract$result_contract$document_diagnostic_columns), names(result$diagnostics$documents))
})
