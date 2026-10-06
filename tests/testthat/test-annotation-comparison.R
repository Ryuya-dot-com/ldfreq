annotation_fixture <- function(lemmas = c("cat", "see", "cat"), upos = NULL,
                               version = "1") {
  lexdiv_lemmatize(lexdiv_tokenize("Cats saw cats.", case = "lower"),
    lemmas = lemmas, upos = upos, backend_id = "fixture", backend_version = version,
    upos_backend_id = if (any(!is.na(upos))) "fixture-pos" else NULL,
    upos_backend_version = if (any(!is.na(upos))) "1" else NULL)
}

test_that("annotation comparisons count missing transitions and layer changes separately", {
  before <- annotation_fixture(c("cat", "see", NA_character_),
    c("NOUN", "VERB", "NOUN"))
  after <- annotation_fixture(c("cat", "see_PAST", "cat"),
    c("NOUN", NA_character_, "VERB"), version = "2")
  saved <- list(before, after)
  audit <- lexdiv_compare_annotations(before, after)
  expect_identical(list(before, after), saved)
  expect_identical(audit$changes$token_index, before$tokens$token_index[2:3])
  expect_identical(audit$changes$surface, c("saw", "cats"))
  expect_identical(audit$changes$lemma_changed, c(TRUE, TRUE))
  expect_identical(audit$changes$upos_changed, c(TRUE, TRUE))
  expect_identical(audit$changes$flemma_changed, c(FALSE, FALSE))
  expect_equal(audit$documents$changed_tokens, 2)
  expect_equal(audit$documents$lemma_changed_tokens, 2)
  expect_equal(audit$documents$upos_changed_tokens, 2)
  expect_identical(audit$provenance$before$document_1, before$provenance)
  expect_identical(audit$provenance$after$document_1, after$provenance)
  path <- tempfile()
  on.exit(unlink(path))
  saveRDS(list(before = before, after = after, audit = audit), path)
  expect_identical(readRDS(path), list(before = before, after = after, audit = audit))
})

test_that("all missing/present label transitions use exact comparisons", {
  values <- c(NA_character_, "a", "b")
  for (a in values) for (b in values) {
    before <- annotation_fixture(rep(a, 3))
    after <- annotation_fixture(rep(b, 3))
    expected <- if (identical(a, b)) 0 else 3
    audit <- lexdiv_compare_annotations(before, after)
    expect_equal(audit$documents$lemma_changed_tokens, expected)
    expect_equal(nrow(audit$changes), expected)
    expect_false(anyNA(audit$changes$lemma_changed))
  }
  same_labels <- lexdiv_compare_annotations(annotation_fixture(),
    annotation_fixture(version = "different-resource-label"))
  expect_equal(nrow(same_labels$changes), 0)
  expect_false(identical(same_labels$provenance$before, same_labels$provenance$after))
})

test_that("batch pairing uses IDs and retains empty documents and layer presence", {
  blank <- lexdiv_tokenize("")
  annotated_blank <- lexdiv_lemmatize(blank, lemmas = character(),
    backend_id = "fixture", backend_version = "1")
  a <- annotation_fixture()
  b <- annotation_fixture(c("cat", NA_character_, "cat"))
  before <- list(essay = a, blank = blank)
  after <- list(blank = annotated_blank, essay = b)
  audit <- lexdiv_compare_annotations(before, after)
  expect_identical(audit$documents$document_id, c("essay", "blank"))
  expect_identical(names(audit$provenance$after), c("essay", "blank"))
  expect_equal(audit$documents$tokens, c(3, 0))
  expect_equal(audit$documents$changed_tokens, c(1, 0))
  expect_identical(audit$documents$before_has_lemma, c(TRUE, FALSE))
  expect_identical(audit$documents$after_has_lemma, c(TRUE, TRUE))
  expect_identical(audit$changes$document_id, "essay")
  expect_identical(audit$changes$after_lemma, NA_character_)
  expect_equal(nrow(lexdiv_compare_annotations(blank, annotated_blank)$changes), 0)
  bare <- lexdiv_tokenize("Cats saw cats.", case = "lower")
  added <- lexdiv_compare_annotations(bare, a)
  expect_equal(added$documents$lemma_changed_tokens, 3)
  expect_false(added$documents$before_has_lemma)
  expect_true(added$documents$after_has_lemma)
  all_missing <- annotation_fixture(rep(NA_character_, 3))
  expect_equal(nrow(lexdiv_compare_annotations(bare, all_missing)$changes), 0)
  empty <- stats::setNames(list(), character())
  zero <- lexdiv_compare_annotations(empty, empty)
  expect_equal(nrow(zero$documents), 0)
  expect_equal(nrow(zero$changes), 0)
  expect_identical(names(zero$changes), names(audit$changes))
  expect_identical(zero$provenance$before, empty)
})

test_that("different sources or segmentation never receive positional annotation joins", {
  before <- annotation_fixture()
  expect_error(lexdiv_compare_annotations(before,
    lexdiv_tokenize("Cats saw cats!", case = "lower")), "same source text")
  expect_error(lexdiv_compare_annotations(before,
    lexdiv_tokenize("Cats saw cats.", case = "lower", tokenizer = "english")),
    "same source text")
  expect_error(lexdiv_compare_annotations(before,
    lexdiv_tokenize("cats saw cats.", case = "lower")), "same source text")
  expect_error(lexdiv_compare_annotations(before,
    lexdiv_tokenize("Cats saw.", case = "lower")), "same source text")
  expect_error(lexdiv_compare_annotations(list(a = before), list(b = before)),
    "same document IDs")
  expect_error(lexdiv_compare_annotations(before, list(a = before)), "both")
  expect_error(lexdiv_compare_annotations(list(before), list(before)), "named list")
  expect_error(lexdiv_compare_annotations(list(a = before, a = before),
    list(a = before, a = before)), "unique")
  expect_error(lexdiv_compare_annotations("text", "text"), "named list")
  expect_error(lexdiv_compare_annotations(before, before, max_tokens = 2), "exceeds")
  expect_equal(nrow(lexdiv_compare_annotations(before, before, max_tokens = 3)$changes), 0)
  expect_error(lexdiv_compare_annotations(list(a = before, b = before),
    list(a = before, b = before), max_tokens = 5), "exceeds")
  expect_error(lexdiv_compare_annotations(before, before, max_tokens = Inf), "max_tokens")
  broken <- before
  broken$provenance$annotation$lemma_tokens <- 0
  expect_error(lexdiv_compare_annotations(before, broken), "annotation")
})

test_that("flemma labels and delimiter-containing identifiers remain distinct", {
  path <- tempfile()
  on.exit(unlink(path))
  writeLines(c("cat\t->\tcat\tcats", "see\t->\tsee\tsaw"), path)
  tokens <- lexdiv_tokenize("cats saw unknown", case = "lower")
  first <- lexdiv_flemmatize(tokens, path, resource_version = "fixture")
  second <- lexdiv_flemmatize(tokens, path,
    overrides = data.frame(form = "saw", flemma = "saw"),
    resource_version = "fixture", override_version = "reviewed")
  audit <- lexdiv_compare_annotations(list("essay:1" = first), list("essay:1" = second))
  expect_identical(audit$changes$document_id, "essay:1")
  expect_identical(audit$changes$before_flemma, "see")
  expect_identical(audit$changes$after_flemma, "saw")
  expect_equal(audit$documents$flemma_changed_tokens, 1)
  expect_identical(audit$provenance$after[["essay:1"]]$flemma_annotation$override_version,
    "reviewed")
})
