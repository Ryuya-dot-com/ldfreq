comparison_fixture <- function() {
  tokens <- data.frame(document_id = "d", segment_id = paste0("s", 1:7),
    token_index = 1L, surface = c(rep("bank", 5), "none", "paper"))
  x <- lexdiv_import_annotations(tokens, data.frame(tokens[c("document_id", "segment_id")],
    text = tokens$surface), list(language = "en", analyzer = "authored", analyzer_version = "1",
      dictionary = "none", dictionary_version = "none", unit = "example", normalization = "none"))
  candidates <- data.frame(term = c("bank", "bank", "paper", "paper"),
    candidate_id = c("1", "2", "1", "2"), label = c("financial", "river", "material", "article"))
  resource <- list(resource_id = "example", resource_version = "1",
    source_reference = "Authored test", data_license = "MIT")
  args <- list(x = x, targets = c("bank", "none", "paper", "absent"),
    candidates = candidates, resource = resource)
  base <- do.call(lexdiv_ambiguity_review, args)
  da <- base$occurrences[c(1:4, 7), c("review_id", "occurrence_id")]
  da$status <- c("selected", "selected", "selected", "unresolved", "selected")
  da$candidate_id <- c("1", "1", "1", NA_character_, "1")
  da$reviewer <- "A"; da$reason <- "Authored A decision"
  db <- base$occurrences[c(1:5, 7), c("review_id", "occurrence_id")]
  db$status <- c("selected", "selected", "unresolved", "selected", "unresolved", "selected")
  db$candidate_id <- c("1", "2", NA_character_, "2", NA_character_, "1")
  db$reviewer <- "B"; db$reason <- "Authored B decision"
  list(args = args, base = base, da = da, db = db,
    a = do.call(lexdiv_ambiguity_review, c(args, list(decisions = da))),
    b = do.call(lexdiv_ambiguity_review, c(args, list(decisions = db))))
}

test_that("agreement denominators distinguish selection from missing or unresolved decisions", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- comparison_fixture(); z <- lexdiv_compare_ambiguity(f$a, f$b)
  expect_identical(z$pairs$outcome, c("agreement", "disagreement", "selected_a_only",
    "selected_b_only", "neither_selected", "neither_selected", "agreement"))
  expect_identical(z$pairs$same_candidate, c(TRUE, FALSE, NA, NA, NA, NA, TRUE))
  expect_identical(z$summary$occurrences, 7L)
  expect_identical(z$summary$both_selected, 3L)
  expect_equal(z$summary$both_selected_proportion, 3 / 7)
  expect_equal(z$summary$agreement_among_both_selected, 2 / 3)
  expect_identical(z$summary$agreement, 2L)
  expect_identical(z$summary$disagreement, 1L)
  expect_identical(z$summary$no_candidates, 1L)
  expect_identical(z$summary$both_reviewed, 5L)
  expect_identical(z$summary$a_reviewed, 5L)
  expect_identical(z$summary$b_reviewed, 6L)
  expect_identical(z$terms$occurrences, c(5L, 1L, 1L, 0L))
  expect_equal(z$terms$agreement_among_both_selected, c(0.5, NA, 1, NA))
  expect_equal(z$terms$both_selected_proportion, c(0.4, 0, 1, NA))
  expect_equal(sum(z$status_pairs$count), 7)
  expect_identical(z$review_queue$segment_id, paste0("s", 2:6))
  expect_identical(z$review_queue$segment_text, c(rep("bank", 4), "none"))
  expect_identical(z$reviews, list(a = f$a, b = f$b))
  reverse <- lexdiv_compare_ambiguity(f$b, f$a)
  expect_equal(reverse$summary$agreement_among_both_selected, 2 / 3)
  expect_identical(reverse$pairs$outcome[3:4], c("selected_b_only", "selected_a_only"))
  p <- tempfile(); on.exit(unlink(p)); saveRDS(z, p)
  expect_identical(readRDS(p), z)
})

test_that("sorting decisions and changing the context window retain pairing and original evidence", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- comparison_fixture()
  f$args$targets <- rev(f$args$targets)
  f$args$candidates <- f$args$candidates[4:1, ]
  b <- do.call(lexdiv_ambiguity_review, c(f$args, list(decisions = f$db[6:1, ], window = 0)))
  z <- lexdiv_compare_ambiguity(f$a, b)
  expect_equal(z$summary$agreement_among_both_selected, 2 / 3)
  expect_identical(z$terms$term, f$a$summary$term)
  expect_identical(z$pairs$b_candidate_id, f$b$occurrences$candidate_id)
  expect_identical(z$reviews$b$decisions, f$db[6:1, ])
  expect_equal(z$reviews$a$provenance$window, 5)
  expect_equal(z$reviews$b$provenance$window, 0)
})

test_that("no selections and no hits have explicit zero denominators, not perfect agreement", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- comparison_fixture(); z <- lexdiv_compare_ambiguity(f$base, f$base)
  expect_equal(z$summary$both_selected, 0)
  expect_equal(z$summary$agreement, 0)
  expect_equal(z$summary$both_selected_proportion, 0)
  expect_true(is.na(z$summary$agreement_among_both_selected))
  expect_equal(nrow(z$review_queue), 7)
  da <- f$da; da$status <- "unresolved"; da$candidate_id <- NA_character_
  unresolved <- do.call(lexdiv_ambiguity_review, c(f$args, list(decisions = da)))
  z <- lexdiv_compare_ambiguity(unresolved, unresolved)
  expect_equal(z$summary$both_reviewed, 5)
  expect_equal(z$summary$agreement, 0)
  expect_true(all(is.na(z$pairs$same_candidate)))
  f$args$targets <- "absent"; f$args$candidates <- f$args$candidates[FALSE, ]
  empty <- do.call(lexdiv_ambiguity_review, f$args)
  z <- lexdiv_compare_ambiguity(empty, empty)
  expect_equal(z$summary$occurrences, 0)
  expect_true(is.na(z$summary$both_selected_proportion))
  expect_true(is.na(z$summary$agreement_among_both_selected))
  expect_equal(nrow(z$pairs), 0)
  expect_equal(nrow(z$status_pairs), 0)
  expect_equal(nrow(z$terms), 1)
})

test_that("comparison rejects altered outputs, unsealed reviews and changed inventories", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- comparison_fixture()
  for (field in c("occurrences", "summary", "candidates", "decisions", "source")) {
    bad <- f$b; bad[[field]] <- NULL
    expect_error(lexdiv_compare_ambiguity(f$a, bad), "unmodified")
  }
  bad <- f$b; bad$occurrences$candidate_id[1] <- "2"
  expect_error(lexdiv_compare_ambiguity(f$a, bad), "unmodified")
  bad <- f$b; bad$provenance$content_sha256 <- NULL
  expect_error(lexdiv_compare_ambiguity(f$a, bad), "regenerate older")
  regenerated <- lexdiv_ambiguity_review(bad$source, bad$summary$term, bad$candidates,
    bad$provenance$resource, bad$decisions, window = bad$provenance$window)
  expect_identical(regenerated, f$b)
  expect_equal(lexdiv_compare_ambiguity(f$a, regenerated)$summary$agreement_among_both_selected, 2 / 3)
  expect_error(lexdiv_compare_ambiguity(NULL, f$b), "unmodified")
  f$args$resource$resource_version <- "2"
  other <- do.call(lexdiv_ambiguity_review, f$args)
  expect_error(lexdiv_compare_ambiguity(f$a, other), "same source")
})
