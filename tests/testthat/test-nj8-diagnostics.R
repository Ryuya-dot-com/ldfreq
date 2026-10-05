test_that("diagnostic counts distinguish occurrences, documents and normalization", {
  words <- data.frame(NJ8 = 1L, Word = "known")
  p <- nj8_profile_batch(list(a = c("UNKNOWN", "unknown", "known", "x"),
    b = c("unknown", "x", "x"), empty = character()), words, unit = "surface")
  saved <- serialize(p, NULL)
  d <- nj8_diagnostics(p)
  expect_identical(d$unmatched_terms, data.frame(lookup_term = c("unknown", "x"),
    token_count = c(3, 3), document_count = c(2, 2)))
  expect_identical(d$coverage, p$coverage)
  expect_identical(d$provenance, p$provenance)
  expect_identical(d$document_provenance, p$document_provenance)
  expect_identical(serialize(p, NULL), saved)
  expect_equal(sum(d$unit_mappings$token_count), 7)
  expect_true(d$unit_mappings$lookup_changed[d$unit_mappings$surface_term == "UNKNOWN"])
  expect_false(any(d$unit_mappings$unit_changed))
  expect_identical(unserialize(serialize(d, NULL)), d)
})

test_that("mapping flags are descriptive and missing lemmas stay excluded", {
  p <- lexdiv_tokenize("Students second compound third missing", case = "lower")
  p <- lexdiv_lemmatize(p, lemmas = c("student", "2", "two words", "\uff13", NA),
    backend_id = "hand-example", backend_version = "1")
  x <- nj8_profile(p, data.frame(NJ8 = 1L, Word = "student"), unit = "lemma")
  d <- nj8_diagnostics(x)
  expect_identical(d$unit_mappings$unit_changed, rep(TRUE, 4))
  expect_identical(d$unit_mappings$numeric_introduced, c(FALSE, TRUE, FALSE, TRUE))
  expect_identical(d$unit_mappings$whitespace_introduced, c(FALSE, FALSE, TRUE, FALSE))
  expect_identical(d$unit_mappings$lookup_changed, c(FALSE, FALSE, FALSE, TRUE))
  expect_identical(d$unmatched_terms$lookup_term, c("2", "two words", "3"))
  expect_identical(d$coverage$excluded_tokens, 1)
  expect_identical(d$exclusion_reasons, data.frame(document_id = "document_1",
    reason = "missing_lemma", tokens = 1))
  expect_identical(d$document_provenance$preprocessing_ref[[1]], x$provenance$preprocessing_ref)
  expect_identical(d$provenance$selected_unit, "lemma")
})

test_that("empty, all-matched and wholly excluded profiles retain typed tables", {
  empty <- nj8_diagnostics(nj8_profile(character()))
  zero <- nj8_diagnostics(nj8_profile_batch(setNames(list(), character())))
  expect_identical(empty$unmatched_terms, zero$unmatched_terms)
  expect_identical(empty$unit_mappings, zero$unit_mappings)
  expect_equal(nrow(empty$coverage), 1)
  expect_equal(nrow(zero$coverage), 0)
  expect_identical(empty$unmatched_terms$token_count, double())
  expect_identical(empty$unit_mappings$numeric_introduced, logical())
  matched <- nj8_diagnostics(nj8_profile("the"))
  expect_equal(nrow(matched$unmatched_terms), 0)
  expect_equal(nrow(matched$unit_mappings), 1)
  p <- lexdiv_lemmatize(lexdiv_tokenize("word"), lemmas = NA_character_,
    backend_id = "missing-example", backend_version = "1")
  excluded <- nj8_diagnostics(nj8_profile_batch(list(a = p)))
  expect_equal(nrow(excluded$unit_mappings), 0)
  expect_identical(excluded$coverage$excluded_tokens, 1)
  expect_identical(excluded$exclusion_reasons$reason, "missing_lemma")
  whitespace <- suppressWarnings(nj8_profile(" ", unit = "surface"))
  expect_identical(nj8_diagnostics(whitespace)$unmatched_terms$lookup_term, "")
})

test_that("grouping does not collide on user punctuation and uses literal IDs", {
  p <- nj8_profile_batch(list("a:b" = c("x:y", "x", "x:y"),
    "a" = c("x:y", "x")), data.frame(NJ8 = 1L, Word = "other"), normalization = "identity")
  d <- nj8_diagnostics(p)
  expect_identical(d$unmatched_terms$lookup_term, c("x:y", "x"))
  expect_identical(d$unmatched_terms$token_count, c(3, 2))
  expect_identical(d$unmatched_terms$document_count, c(2, 2))
  # Independent counting oracle for generated corpora, including empty documents.
  set.seed(7104)
  for (i in 1:25) {
    docs <- setNames(lapply(1:4, function(j) sample(c("known", "a:b", "A", "a", "\u00e9"),
      sample(0:25, 1), replace = TRUE)), paste0("d", 1:4))
    x <- nj8_profile_batch(docs, data.frame(NJ8 = 1L, Word = "known"), normalization = "identity")
    y <- nj8_diagnostics(x)
    expect_equal(sum(y$unmatched_terms$token_count), sum(x$coverage$off_list_tokens))
    for (k in seq_len(nrow(y$unmatched_terms))) {
      term <- y$unmatched_terms$lookup_term[k]
      expect_equal(y$unmatched_terms$token_count[k], sum(vapply(docs, function(z) sum(z == term), 0L)))
      expect_equal(y$unmatched_terms$document_count[k], sum(vapply(docs, function(z) term %in% z, TRUE)))
    }
  }
})

test_that("diagnostics reject wrong inputs and inconsistent profile counts", {
  expect_error(nj8_diagnostics(c("the", "word")), "must be a result")
  expect_error(nj8_diagnostics(list()), "must be a result")
  x <- nj8_profile_batch(list(a = "the"))
  x$lookup$matched[1] <- NA
  expect_error(nj8_diagnostics(x), "invalid NJ8 lookup")
  x <- nj8_profile_batch(list(a = "the"))
  x$coverage$eligible_tokens <- 2
  expect_error(nj8_diagnostics(x), "inconsistent lookup")
  x <- nj8_profile_batch(list(a = "the"))
  x$lookup$document_id <- "other"
  expect_error(nj8_diagnostics(x), "invalid document IDs")
})
