reviewed_text_fixture <- function() {
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "reviewed-text.R", package = "ldfreq", mustWork = TRUE), e)
  list(apply = e$apply_reviewed_edits,
    documents = data.frame(document_id = c("d", "empty"), writer = c("w1", "w2"),
      text = c("A freind met a friend.", "")),
    edits = data.frame(edit_id = "e1", document_id = "d", start = 3L, end = 8L,
      original = "freind", replacement = "friend", category = "spelling",
      decision = "approved", reviewer = "r1", reason = "Reviewed transposition"))
}

test_that("reviewed edits preserve originals, decisions, metadata and replay", {
  f <- reviewed_text_fixture()
  x <- f$apply(f$documents, f$edits, "spelling", "Spelling only")
  expect_identical(x$original, f$documents)
  expect_identical(x$revised$writer, f$documents$writer)
  expect_identical(x$revised$text, c("A friend met a friend.", ""))
  expect_identical(x$edits$pre, "A ")
  expect_identical(x$edits$post, " met a friend.")
  expect_equal(x$documents$applied, c(1, 0))
  expect_false(x$documents$original_sha256[1] == x$documents$revised_sha256[1])
  expect_identical(x$documents$original_sha256[2], x$documents$revised_sha256[2])
  expect_identical(f$apply(f$documents, f$edits, character(), "Original")$revised, f$documents)
  expect_identical(f$apply(f$documents, f$edits[FALSE, ], "spelling", "No proposals")$revised, f$documents)
  for (decision in c("rejected", "unresolved")) {
    edits <- f$edits; edits$decision <- decision
    y <- f$apply(f$documents, edits, "spelling", "Spelling only")
    expect_identical(y$revised, f$documents)
    expect_identical(y$edits$decision, decision)
    expect_true(is.na(y$edits$revised_start))
  }
  path <- tempfile(); on.exit(unlink(path))
  saveRDS(x, path); saved <- readRDS(path)
  expect_identical(do.call(f$apply, saved$inputs), x)
  before <- lexdiv_tokenize(x$original$text[1])
  after <- lexdiv_tokenize(x$revised$text[1])
  expect_error(lexdiv_compare_annotations(before, after), "source")
})

test_that("insertions, deletions and Unicode use original code-point positions", {
  f <- reviewed_text_fixture()
  f$documents$text <- c("\U0001f600e\u0301xy", "")
  e <- f$edits[rep(1, 5), ]
  e$edit_id <- paste0("e", 1:5)
  e$document_id[5] <- "empty"
  e$start <- c(1, 2, 4, 6, 1); e$end <- c(0, 3, 4, 5, 0)
  e$original <- c("", "e\u0301", "x", "", "")
  e$replacement <- c("hi", "\u00e9", "", "!", "new")
  x <- f$apply(f$documents, e, "spelling", "Authored coordinate test")
  expect_identical(x$revised$text, c("hi\U0001f600\u00e9y!", "new"))
  expect_equal(x$edits$revised_start, c(1, 4, 5, 6, 1))
  expect_equal(x$edits$revised_end, c(2, 4, 4, 6, 3))
  expect_identical(x$edits$pre[1], "")
  expect_identical(x$edits$post[4], "")
  expect_identical(x$original$text, f$documents$text)
  # Two alternative proposals may overlap only when at most one is applied.
  e <- rbind(f$edits, f$edits); e$edit_id <- c("a", "b")
  e$decision[2] <- "unresolved"
  f$documents$text[1] <- "A freind met a friend."
  expect_equal(f$apply(f$documents, e, "spelling", "One approved")$documents$applied[1], 1)
  e$decision[2] <- "approved"
  expect_error(f$apply(f$documents, e, "spelling", "Conflicting"), "Overlapping")
  e$start <- c(3, 5); e$end <- c(8, 5); e$original[2] <- "e"
  expect_error(f$apply(f$documents, e, "spelling", "Overlapping"), "Overlapping")
})

test_that("stale, ambiguous and incomplete edit inputs fail explicitly", {
  f <- reviewed_text_fixture()
  run <- function(e = f$edits, d = f$documents) f$apply(d, e, "spelling", "Spelling only")
  e <- f$edits; e$original <- "friend"
  expect_error(run(e), "substring mismatch")
  e <- f$edits; e$document_id <- "absent"
  expect_error(run(e), "known document_id")
  e <- f$edits; e$decision <- "suggested"
  expect_error(run(e), "Decisions")
  e <- f$edits; e$reviewer <- ""
  expect_error(run(e), "reviewer")
  e <- f$edits; e$replacement <- NA_character_
  expect_error(run(e), "replacement")
  e <- f$edits; e$replacement <- e$original
  expect_error(run(e), "must change")
  for (value in c(NA_real_, Inf, 3.5)) {
    e <- f$edits; e$start <- value
    expect_error(run(e), "finite integer")
  }
  for (value in c(0, 30)) {
    e <- f$edits; e$start <- value
    expect_error(run(e), "outside")
  }
  e <- f$edits; e$end <- 0L
  expect_error(run(e), "outside")
  e <- f$edits; e$applied <- TRUE
  expect_error(run(e), "reserved")
  d <- f$documents; d$document_id[2] <- "d"
  expect_error(run(d = d), "unique")
  d <- f$documents; d$text[1] <- NA_character_
  expect_error(run(d = d), "nonmissing")
  d <- f$documents; d$text[1] <- rawToChar(as.raw(255)); Encoding(d$text[1]) <- "bytes"
  expect_error(run(d = d), "UTF-8")
})

test_that("authored versions retain denominators, missingness and full coverage", {
  e <- new.env(parent = globalenv())
  invisible(capture.output(sys.source(system.file("examples", "reviewed-text-demo.R",
    package = "ldfreq", mustWork = TRUE), e)))
  x <- e$result
  spelling <- subset(x$metrics, document_id == "spelling" & metric_id == "ttr")
  expect_equal(spelling$N, c(5, 5, 5))
  expect_equal(spelling$V, c(4, 3, 3))
  expect_equal(spelling$value, c(.8, .6, .6))
  mattr <- subset(x$metrics, document_id == "spelling" & metric_id == "mattr")
  expect_equal(mattr$value, c(.875, .75, .75))
  expect_equal(subset(x$metrics, document_id == "grammar" & metric_id == "ttr")$N, c(4, 4, 5))
  boundary <- subset(x$metrics, document_id == "boundary" & metric_id == "mattr")
  expect_equal(boundary$N, c(3, 3, 4))
  expect_true(all(is.na(boundary$value[1:2])))
  expect_equal(boundary$value[3], 1)
  expect_true(all(is.na(subset(x$metrics, document_id == "empty")$value)))
  expect_equal(nrow(x$coverage), 18)
  expanded <- x$versions$expanded_review
  expect_identical(expanded$revised$text[5], e$documents$text[5])
  expect_equal(expanded$documents$unresolved[5], 1)
  expect_equal(expanded$documents$rejected[5], 1)
  # A real-word error need not be off-list; membership cannot decide correctness.
  expect_true(all(nj8_profile(c("too", "to"))$lookup$matched))
})
