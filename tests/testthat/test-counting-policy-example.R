test_that("counting and lookup equivalence are independent source-linked choices", {
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "lexical-counting-policy.R", package = "ldfreq",
    mustWork = TRUE), e)
  x <- e$lexical_counting_example
  forms <- subset(x$metrics, document_id == "variants" & metric_id == "ttr")
  expect_equal(forms$selected_known, rep(4, 5))
  expect_equal(forms$types_known, c(4, 4, 4, 4, 3))
  expect_equal(forms$reportable_value, c(1, 1, 1, 1, .75))
  lookup <- subset(x$coverage, document_id == "variants")
  expect_equal(lookup$exact_matched, rep(2, 5))
  expect_equal(lookup$alias_matched, rep(3, 5))
  audit <- x$runs$words_and_numerals$variants$query_audit
  expect_identical(audit$surface, c("The", "colour", "is", "color"))
  expect_identical(audit$reference_key, c("the", "color", "is", "color"))
  expect_identical(audit$token_index, 1:4)
  expect_identical(audit$alias_applied, c(FALSE, TRUE, FALSE, FALSE))
  protected <- subset(x$selections$spelling_equivalence, document_id == "protected_name")
  expect_identical(protected$alias_applied, c(FALSE, FALSE, TRUE, FALSE))
  expect_identical(protected$surface, c("Colour", "sells", "colour", "."))
  expect_identical(protected$term, c("colour", "sells", "color", "."))
  expect_identical(x$alias_info$sha256,
    digest::digest(x$aliases, algo = "sha256", serializeVersion = 2L))

  names <- subset(x$metrics, document_id == "names" & metric_id == "ttr")
  expect_equal(names$selected_known, c(4, 3, 4, 3, 4))
  expect_equal(names$reportable_value, c(.75, 1, .75, 1, .75))
  selected <- subset(x$selections$without_proper_nouns, document_id == "names")
  expect_identical(selected$eligible, c(FALSE, TRUE, TRUE, TRUE, FALSE))
  expect_identical(selected$exclusion_reason[1], "excluded_PROPN")
  numbers <- subset(x$metrics, document_id == "numerals" & metric_id == "ttr")
  expect_equal(numbers$selected_known, c(7, 7, 4, 4, 7))
  expect_equal(numbers$types_known, c(6, 6, 3, 3, 6))
  expect_true(all(is.na(subset(x$metrics, document_id == "unknown")$reportable_value)))
  expect_true(all(subset(x$metrics, document_id == "unknown")$status == "unknown_selection"))
  expect_true(all(subset(x$metrics, document_id == "unknown")$unknown_upos == 1))
  expect_true(all(is.na(subset(x$metrics, document_id == "empty")$reportable_value)))
  expect_true(all(subset(x$metrics, document_id == "empty")$status == "missing"))
  expect_equal(nrow(x$coverage), 40)

  # Full annotation preserves specialist forms and separates excluded positions.
  expect_identical(subset(x$annotation$tokens, document_id == "technical")$surface[1], "C++")
  expect_equal(nrow(subset(x$bigrams$occurrences, document_id == "symbols")), 0)
  pairs <- subset(x$bigrams$occurrences, document_id == "names")
  expect_identical(pairs$term1, c("saw", "a"))
  expect_identical(pairs$term2, c("a", "rose"))
  expect_equal(pairs$start_index, c(2, 3))
  expect_identical(x$bigrams$documents$document_id, x$annotation$documents$document_id)
  path <- tempfile(); on.exit(unlink(path))
  saveRDS(x, path)
  expect_identical(readRDS(path), x)
})

test_that("number and symbol flags are lexical rules rather than semantic labels", {
  text <- "Two 2 2nd COVID-19 3.14 75%"
  keep <- lexdiv_tokenize(text, tokenizer = "english", keep_numbers = TRUE)
  drop <- lexdiv_tokenize(text, tokenizer = "english", keep_numbers = FALSE)
  expect_identical(keep$tokens$is_number, c(FALSE, TRUE, FALSE, FALSE, TRUE, TRUE))
  expect_identical(drop$tokens$surface, c("Two", "2nd", "COVID-19"))
  expect_identical(drop$provenance$excluded_spans$surface, c("2", "3.14", "75%"))
  expect_identical(lexdiv_tokenize("C++ R&D #topic @user", tokenizer = "english")$tokens$surface,
    c("C", "R", "D", "topic", "user"))
  expect_identical(lexdiv_tokenize("can't well-known word\u2014word",
    tokenizer = "english")$tokens$surface, c("can't", "well-known", "word", "word"))
  expect_identical(lexdiv_tokenize("1,000 1000", tokenizer = "english",
    keep_numbers = TRUE)$tokens$surface, c("1,000", "1000"))
  x <- lexdiv_tokenize("Rose rose", tokenizer = "english")
  x <- lexdiv_lemmatize(x, lemmas = c("Rose", "rose"), upos = c("PROPN", "NOUN"),
    backend_id = "authored", backend_version = "1",
    upos_backend_id = "authored", upos_backend_version = "1")
  expect_equal(lexdiv_metrics_text(x, word_inclusion = "content", metrics = "ttr")$results$N, 2)
})
