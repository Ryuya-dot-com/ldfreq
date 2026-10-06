test_that("English lexical boundaries follow explicit examples", {
  cases <- list(
    list("I can\u2019t read John\u2019s well\u2011known book.",
      c("I", "can't", "read", "John's", "well-known", "book")),
    list("The U.S.A. uses e.g. examples; Dr. Lee agrees.",
      c("The", "U.S.A.", "uses", "e.g.", "examples", "Dr", "Lee", "agrees")),
    list("On 2026-10-04, pay -12.50 or 1,000.25; 3/4 is 75% and 2e-3 is .002.",
      c("On", "pay", "or", "is", "and", "is")),
    list("COVID-19 B2 2nd abc123 rock'n'roll can't won't isn't",
      c("COVID-19", "B2", "2nd", "abc123", "rock'n'roll", "can't", "won't", "isn't")),
    list("Mail a.b+tag@example.org; visit https://example.org/a?q=2 or www.example.net.",
      c("Mail", "visit", "or")),
    list("\u0301 cafe\u0301 \U0001F600 \u2014 next", c("caf\u00e9", "next")),
    list("", character()), list("!!! \U0001F600", character())
  )
  for (example in cases) {
    x <- lexdiv_tokenize(example[[1L]], tokenizer = "english")
    expect_identical(x$tokens$surface, example[[2L]])
    expect_s3_class(lexdiv_metrics_text(x, metrics = "ttr"), "lexdiv_text_results")
    processed <- stringi::stri_trans_char(stringi::stri_trans_nfc(example[[1L]]),
      "\u2018\u2019\u2010\u2011", "''--")
    expect_identical(x$tokens$surface, stringi::stri_sub(processed,
      x$tokens$start, x$tokens$end))
  }
  numeric <- lexdiv_tokenize("3.14 -12 1,000 2026-10-04 1e3 2nd", tokenizer = "english",
    keep_numbers = TRUE)
  expect_identical(numeric$tokens$surface, c("3.14", "-12", "1,000", "2026-10-04", "1e3", "2nd"))
  expect_identical(numeric$tokens$is_number, c(rep(TRUE, 5), FALSE))
  expect_equal(nrow(numeric$provenance$excluded_spans), 0)
  expect_no_error(lexdiv_metrics_text(numeric, metrics = "ttr"))
})

test_that("English normalization, offsets and exclusions survive validation", {
  x <- lexdiv_tokenize("\U0001F600 CAF\u00c9 John\u2019s 3.14 a@example.org https://example.org.",
    tokenizer = "english", case = "lower")
  expect_identical(x$tokens$surface, c("caf\u00e9", "john's"))
  expect_identical(x$tokens$start, c(3L, 8L))
  expect_identical(x$provenance$excluded_spans$reason, c("number", "email", "url"))
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(x, path)
  expect_identical(readRDS(path), x)
  expect_no_error(nj8_profile(readRDS(path), unit = "surface"))
  expect_error(tubelex_profile(x), "Treebank")
  for (field in c("start", "end", "surface", "reason")) {
    edited <- x
    edited$provenance$excluded_spans[[field]][1L] <- switch(field,
      start = 1L, end = 1L, surface = "3.15", reason = "url")
    expect_error(lexdiv_metrics_text(edited, metrics = "ttr"), "exclusion")
  }
  edited <- x
  edited$provenance$excluded_spans <- NULL
  expect_error(lexdiv_metrics_text(edited, metrics = "ttr"), "exclusion")
  expect_error(lexdiv_metrics_text(x, tokenizer = "english"), "raw text")
  expect_error(lexdiv_tokenize("abc", tokenizer = c("unicode", "english")), "tokenizer")
  expect_identical(lexdiv_tokenize("\uff21\uff22\uff23", tokenizer = "english",
    normalization = "NFKC", case = "lower")$tokens$surface, "abc")
})

test_that("Unicode defaults and saved 0.2.0 objects remain usable", {
  old <- lexdiv_tokenize("John\u2019s 3.14 2026-10-04")
  expect_identical(old$tokens$surface, c("John\u2019s", "2026-10-04"))
  old$provenance$contract_version <- "0.2.0"
  expect_no_error(lexdiv_metrics_text(old, metrics = "ttr"))
  english <- lexdiv_tokenize("John\u2019s 3.14 2026-10-04", tokenizer = "english")
  expect_identical(english$tokens$surface, "John's")
  english$provenance$contract_version <- "0.2.0"
  expect_error(lexdiv_metrics_text(english, metrics = "ttr"), "provenance")
})

test_that("Raw-text batch calls retain IDs, empty documents and complete results", {
  docs <- data.frame(id = c("second", "first", "empty"),
    essay = c("The cat can\u2019t run. 3.14", "Cat cat.", ""))
  prepared <- lexdiv_tokenize_batch(docs, id_col = "id", text_col = "essay",
    tokenizer = "english", case = "lower")
  expect_identical(names(prepared), docs$id)
  direct <- lexdiv_metrics_text_batch(docs, id_col = "id", text_col = "essay",
    tokenizer = "english", case = "lower", metrics = c("ttr", "mattr"), window_length = 3)
  result <- lexdiv_metrics_text_batch(prepared, metrics = c("ttr", "mattr"), window_length = 3)
  expect_identical(result, direct)
  expect_identical(names(result), c("results", "token_audit", "preprocessing"))
  expect_identical(names(result$preprocessing), docs$id)
  expect_equal(result$results$N, c(4, 4, 2, 2, 0, 0))
  expect_equal(result$results$value[c(1, 3)], c(1, 0.5))
  expect_identical(result$results$status, c("ok", "ok", "ok", "missing", "missing", "missing"))
  expect_identical(unique(result$token_audit$document_id), docs$id[1:2])
  expect_identical(nj8_profile_batch(prepared, unit = "surface")$coverage$document_id, docs$id)
  for (i in seq_along(prepared)) {
    single <- lexdiv_metrics_text(prepared[[i]], metrics = c("ttr", "mattr"), window_length = 3)
    expect_identical(result$preprocessing[[i]], single$preprocessing)
    expect_equal(result$results$value[result$results$document_id == docs$id[[i]]], single$results$value)
  }
  expect_output(print(result), "3 documents")
  expect_identical(suppressMessages(lexdiv_widen(result$results))$document_id, docs$id)
})

test_that("Batch input errors identify missing text and never invent document IDs", {
  expect_error(lexdiv_tokenize_batch(c("text", "text")), "named character")
  expect_error(lexdiv_tokenize_batch(c(a = "x", a = "y")), "unique")
  expect_error(lexdiv_tokenize_batch(c(a = "x", bad = NA_character_)), 'Document "bad"')
  expect_error(lexdiv_tokenize_batch(data.frame(document_id = "a", text = factor("text"))), "character")
  expect_error(lexdiv_tokenize_batch(data.frame(document_id = "a", text = "text"), text_col = "document_id"), "different")
  expect_error(lexdiv_metrics_text_batch(list(a = "text")), 'Document "a"')
  prepared <- lexdiv_tokenize_batch(c(a = "text"))
  expect_error(lexdiv_metrics_text_batch(prepared, case = "lower"), "raw text")
  expect_error(lexdiv_metrics_text_batch(prepared, text_col = "text"), "data-frame")
  expect_error(lexdiv_metrics_text_batch(prepared, unit = "lemma"), 'Document "a"')
  empty <- stats::setNames(character(), character())
  expect_identical(lexdiv_tokenize_batch(empty), stats::setNames(list(), character()))
  result <- lexdiv_metrics_text_batch(empty, metrics = "ttr", tokenizer = "english")
  expect_equal(nrow(result$results), 0)
  expect_equal(nrow(result$token_audit), 0)
  expect_length(result$preprocessing, 0)
  expect_error(lexdiv_tokenize_batch(empty, tokenizer = "guess"), "tokenizer")
  expect_error(lexdiv_metrics_text_batch(empty, metrics = "mattr", window_length = 0), "window_length")
})

test_that("Annotated English batches preserve exclusions and comparison boundaries", {
  annotate <- function(rule) lexdiv_lemmatize(
    lexdiv_tokenize("Cats and cats run", tokenizer = rule, case = "lower"),
    lemmas = c("cat", "and", "cat", NA_character_),
    upos = c("NOUN", "CCONJ", "NOUN", "VERB"),
    backend_id = "example-lemma", backend_version = "1",
    upos_backend_id = "example-upos", upos_backend_version = "1"
  )
  english <- annotate("english")
  result <- lexdiv_metrics_text_batch(list(a = english, b = english),
    unit = "lemma", word_inclusion = "content", metrics = c("ttr", "mattr"),
    window_length = 2)
  expect_equal(result$results$N, rep(2, 4))
  expect_equal(result$results$value, rep(0.5, 4))
  expect_identical(result$token_audit$exclusion_reason[1:4],
    c(NA_character_, "non_content_upos", NA_character_, "missing_lemma"))
  expect_identical(result$preprocessing$a$tokenization, english$provenance)
  expect_error(lexdiv_content_overlap(english, annotate("unicode")), "tokenizer_id")
  expect_no_error(lexdiv_content_overlap(english, english))
  plot_path <- tempfile(fileext = ".pdf")
  grDevices::pdf(plot_path)
  on.exit({grDevices::dev.off(); unlink(plot_path)})
  expect_error(plot(result), "metric_id")
  drawn <- withVisible(plot(result, metric_id = "ttr"))
  expect_false(drawn$visible)
  expect_identical(drawn$value$document_id, c("a", "b"))
  expect_equal(drawn$value$value, c(0.5, 0.5))
})

test_that("English contract and batch schemas describe live outputs", {
  skip_if_not_installed("jsonlite")
  contract <- jsonlite::read_json(system.file("spec", "ldfreq-preprocessing-contract.json",
    package = "ldfreq"), simplifyVector = TRUE)
  prepared <- lexdiv_tokenize("cat 3.14", tokenizer = "english")
  english <- contract$tokenizer$english
  expect_identical(english$tokenizer_id, prepared$provenance$tokenizer_id)
  expect_identical(english$tokenizer_version, prepared$provenance$tokenizer_version)
  expect_identical(english$excluded_spans_columns, names(prepared$provenance$excluded_spans))
  result <- lexdiv_metrics_text_batch(list(a = prepared), metrics = "ttr")
  expect_identical(contract$result_boundary$raw_text_batch$metrics_return_components, names(result))
})
