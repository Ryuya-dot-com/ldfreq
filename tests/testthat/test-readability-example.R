readability_example <- function() {
  e <- new.env(parent = globalenv())
  sys.source(system.file("examples", "readability-demo.R", package = "ldfreq", mustWork = TRUE), e)
  e
}

test_that("readability agrees with hand counts and retains out-of-range scores", {
  e <- readability_example(); x <- e$analysis
  expect_equal(x$components$words, c(6, 4, 4, 0, 1))
  expect_equal(x$components$sentences, c(2, 1, 1, 0, 1))
  expect_equal(x$components$syllables, c(6, 6, 9, NA, 1))
  expect_equal(x$results$value[x$results$measure == "Flesch_Reading_Ease"],
    c(119.19, 75.875, 12.425, NA, 121.22), tolerance = 1e-12)
  expect_equal(x$results$value[x$results$measure == "Flesch_Kincaid_Grade"],
    c(-2.62, 3.67, 12.52, NA, -3.4), tolerance = 1e-12)
  expect_equal(e$initial$components$status, c("ok", "ok", "missing_syllables", "no_words", "ok"))
  expect_equal(e$initial$components$known_syllables, c(6, 6, 2, 0, 1))
  expect_equal(e$initial$components$missing_syllable_words, c(0, 0, 2, 0, 0))
  expect_true(all(is.na(subset(e$initial$results, document_id == "d3")$value)))
  expect_true(all(x$components$below_word_threshold))
  expect_equal(x$source$segments$status, c("counted", "counted", "excluded_segment", "counted", "counted", "no_words", "counted"))
  expect_equal(sum(x$source$tokens$counted), 15)
  changed <- e$helper$readability_score(e$prepared, e$reviewed, "hand counts", short_text_words = 4)
  expect_equal(changed$components$below_word_threshold, c(FALSE, FALSE, FALSE, TRUE, TRUE))
  expect_identical(changed$results$value, x$results$value)
  expect_false(identical(changed$analysis_id, x$analysis_id))
})

test_that("word rules, exact source spans, and zero-word segments are explicit", {
  e <- readability_example(); h <- e$helper
  s <- data.frame(document_id = c("a", "a", "b", "c"), segment_id = c("1", "2", "1", "1"),
    text = c("Don't re-read R.F.D. in 1918. Visit https://example.org or a@b.org! $", "!!!", "", "   "))
  p <- h$readability_prepare(s, "en", "one authored segment per sentence")
  expect_equal(p$tokens$surface, c("Don't", "re-read", "R.F.D.", "in", "1918", "Visit", "or"))
  expect_equal(p$tokens$original_surface, p$tokens$surface)
  expect_equal(p$segments$words, c(7, 0, 0, 0))
  expect_equal(p$segments$counted_sentence, c(TRUE, FALSE, FALSE, FALSE))
  expect_equal(p$tokenization[[1]]$excluded_spans$reason, c("url", "email"))
  for (i in seq_len(nrow(p$tokens))) expect_identical(p$tokens$original_surface[i],
    stringi::stri_sub(s$text[p$tokens$segment_row[i]], p$tokens$start[i], p$tokens$end[i]))
  empty <- h$readability_prepare(s[2:4, ], "en", "no lexical words")
  hand <- data.frame(source_id = character(), token_row = integer(), syllables = numeric(), method = character())
  x <- h$readability_score(empty, hand, "no words to count")
  expect_equal(nrow(x$results), 6)
  expect_true(all(x$results$status == "no_words" & is.na(x$results$value)))
  expect_equal(x$components$words, c(0, 0, 0))
  expect_equal(x$components$known_syllables, c(0, 0, 0))
  # Curly punctuation changes the tokenizer surface, never the saved source text or offsets.
  s <- data.frame(document_id = "unicode", segment_id = "1", text = "Don\u2019t re\u2011read.")
  p <- h$readability_prepare(s, "en", "one sentence")
  expect_identical(p$segments$text, s$text)
  expect_equal(p$tokens$surface, c("Don't", "re-read"))
  expect_equal(p$tokens$original_surface, c("Don\u2019t", "re\u2011read"))
})

test_that("automatic estimates distinguish dictionary, fallback and pronunciation gaps", {
  skip_if_not_installed("nsyllable", "1.0.1")
  e <- readability_example(); h <- e$helper
  x <- h$readability_score(e$prepared)
  expect_equal(x$components$syllables, c(6, 6, NA, NA, 1))
  expect_equal(x$components$missing_syllable_words, c(0, 0, 2, 0, 0))
  expect_equal(x$syllables$method[e$prepared$tokens$surface %in% c("1918", "R.F.D.")],
    rep("pronunciation_required", 2))
  expect_identical(x$syllable_source$version, as.character(packageVersion("nsyllable")))
  expect_match(x$syllable_source$dictionary_sha256, "^[a-f0-9]{64}$")
  p <- h$readability_prepare(data.frame(document_id = "d", segment_id = "s",
    text = "Cat florpulous zzz 2nd i.e."), "en", "one sentence")
  z <- h$readability_score(p)
  expect_equal(z$syllables$method, c("dictionary", "vowel_group_estimate", "unavailable",
    "pronunciation_required", "pronunciation_required"))
  expect_equal(z$syllables$syllables, c(1, 3, NA, NA, NA))
  expect_equal(z$components$missing_syllable_words, 3)
  expect_true(all(is.na(z$results$value)))
  p <- h$readability_prepare(data.frame(document_id = "d", segment_id = "s", text = ""), "en", "empty")
  expect_equal(h$readability_score(p)$components$status, "no_words")
})

test_that("source identity prevents stale, missing and duplicate syllable rows", {
  e <- readability_example(); h <- e$helper
  a <- h$readability_score(e$prepared, e$reviewed[nrow(e$reviewed):1, ], "same hand counts")
  b <- h$readability_score(e$prepared, e$reviewed, "same hand counts")
  expect_identical(a, b)
  for (column in c("source_id", "token_row")) {
    z <- e$reviewed
    z[[column]][1] <- if (column == "source_id") "wrong" else 2L
    expect_error(h$readability_score(e$prepared, z, "hand"), "source_id/token_row")
  }
  expect_error(h$readability_score(e$prepared, e$reviewed[-1, ], "hand"), "source_id/token_row")
  expect_error(h$readability_score(e$prepared, e$reviewed, ""), "syllable_source")
  for (value in c(0, -1, .5, Inf, NaN, 1e15)) {
    z <- e$reviewed; z$syllables[1] <- value
    expect_error(h$readability_score(e$prepared, z, "hand"), "positive whole")
  }
  z <- e$reviewed; z$method[1] <- NA_character_
  expect_error(h$readability_score(e$prepared, z, "hand"), "nonblank method")
  p <- e$prepared; p$segments$text[1] <- "changed"
  expect_error(h$readability_score(p, e$reviewed, "hand"), "record changed")
  changed <- h$readability_prepare(e$segments, "en", "different sentence policy")
  expect_error(h$readability_score(changed, e$reviewed, "hand"), "source_id/token_row")
  for (field in c("value", "words", "status")) {
    x <- e$analysis; x$results[[field]][1] <- NA
    expect_error(h$readability_validate(x), "record changed")
  }
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(e$record, path, version = 2)
  reopened <- readRDS(path)
  expect_identical(reopened, e$record)
  expect_invisible(h$readability_validate(reopened$analysis))
})

test_that("boundaries, unsupported languages and invalid parameters fail explicitly", {
  e <- readability_example(); h <- e$helper
  for (lang in list("ja", "EN", NA_character_, c("en", "ja")))
    expect_error(h$readability_prepare(e$segments, lang, "supplied"), "Only explicitly")
  for (include in list(TRUE, rep(NA, 7), rep(1, 7)))
    expect_error(h$readability_prepare(e$segments, "en", "supplied", include), "include")
  expect_error(h$readability_prepare(e$segments, "en", ""), "sentence_policy")
  expect_error(h$readability_prepare(e$segments[FALSE, ], "en", "supplied"), "at least one")
  for (field in c("document_id", "segment_id", "text")) {
    s <- e$segments; s[[field]][1] <- NA_character_
    expect_error(h$readability_prepare(s, "en", "supplied"), "UTF-8")
  }
  s <- e$segments; s$segment_id[2] <- s$segment_id[1]
  expect_error(h$readability_prepare(s, "en", "supplied"), "unique")
  expect_error(h$readability_prepare(e$segments, "en", "supplied", max_tokens = 3), "no result was truncated")
  for (limit in c(-1, .5, NA, Inf))
    expect_error(h$readability_score(e$prepared, e$reviewed, "hand", short_text_words = limit), "whole number")
  p <- h$readability_prepare(e$segments, "en", "all excluded", include = rep(FALSE, 7))
  z <- e$reviewed; z$source_id <- p$integrity_sha256
  x <- h$readability_score(p, z, "excluded")
  expect_true(all(x$components$words == 0 & x$components$sentences == 0))
  expect_true(all(x$results$status == "no_words"))
})

test_that("research rows preserve writer, task, occasion and non-submissions", {
  e <- readability_example(); x <- e$study_long
  expect_equal(nrow(x), 12)
  expect_false(anyDuplicated(x[c("observation_id", "measure")]) > 0)
  for (column in c("writer_id", "task", "occasion"))
    expect_identical(x[[column]], e$planned[[column]][match(x$observation_id, e$planned$observation_id)])
  absent <- subset(x, observation_id == "o6")
  expect_equal(absent$status, rep("not_submitted", 2))
  expect_true(all(is.na(absent$value) & is.na(absent$words)))
  empty <- subset(x, document_id == "d4")
  expect_true(all(empty$status == "no_words" & empty$words == 0 & is.na(empty$value)))
  expect_equal(length(unique(x$analysis_id)), 1)
})
