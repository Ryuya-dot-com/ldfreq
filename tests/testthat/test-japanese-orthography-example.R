japanese_orthography_fixture <- function(boundaries = FALSE) {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  env <- new.env(parent = baseenv())
  sys.source(system.file("examples", "japanese-orthography.R", package = "ldfreq",
    mustWork = TRUE), env)
  if (boundaries) env$japanese_boundary_example else env$japanese_orthography_example
}

test_that("spelling variation and homophones have different counting effects", {
  x <- japanese_orthography_fixture()
  d <- x$counts[match(c("variants", "homophones", "unlisted", "no_targets", "empty"),
    x$counts$document_id), ]
  expect_equal(d$source_N, c(6, 12, 2, 1, 0))
  expect_equal(d$target_N, c(3, 3, 1, 0, 0))
  expect_equal(d$selected_N, c(3, 2, 0, 0, 0))
  expect_equal(d$selection_coverage, c(1, 2/3, 0, NA, NA))
  expect_equal(d$surface_V, c(3, 1, 1, 0, 0))
  expect_equal(d$lexical_V, c(1, NA, NA, 0, 0))
  expect_equal(d$common_surface_V, c(3, 1, 0, 0, 0))
  expect_equal(d$common_lexical_V, c(1, 2, 0, 0, 0))
  expect_equal(d$unresolved_N, c(0, 1, 0, 0, 0))
  expect_equal(d$no_candidates_N, c(0, 0, 1, 0, 0))
  expect_true(all(x$initial$occurrences$status[1:6] == "unreviewed"))
  expect_true(all(is.na(x$occurrences$lexical_id[6:7])))
  expect_identical(x$occurrences$lexical_id[4:5], c("bridge", "chopsticks"))
})

test_that("boundary review restores a target without changing original kana", {
  x <- japanese_orthography_fixture(boundaries = TRUE)
  a <- x$alignment
  changed <- a$groups[a$groups$relation != "exact", ]
  expect_identical(changed$keyword, "はし")
  expect_equal(changed$start, 4)
  expect_equal(changed$end, 5)
  expect_identical(changed$relation, "split")
  expect_equal(changed$predicted_n, 2)
  expect_equal(changed$reference_n, 1)
  expect_identical(x$inputs$split$segments$text, x$inputs$reviewed$segments$text)
  expect_equal(x$before_review$occurrences$start, 1)
  expect_equal(x$review$occurrences$start, c(1, 4))
  expect_equal(x$review$occurrences$end, c(2, 5))
  expect_identical(x$review$occurrences$surface, c("はし", "はし"))
  expect_identical(x$review$occurrences$candidate_id, c("bridge", "chopsticks"))
  expect_false("lemma" %in% names(x$inputs$reviewed$tokens))
  d <- x$scores[x$scores$document_id == "boundary", ]
  expect_identical(d$condition, c("split", "reviewed"))
  expect_equal(d$N, c(7, 6))
  expect_equal(d$V, c(7, 5))
  expect_equal(d$value, c(1, 5/6))
  empty <- x$scores[x$scores$document_id == "empty", ]
  expect_equal(empty$N, c(0, 0))
  expect_true(all(is.na(empty$value)))

  r <- x$review
  decisions <- r$decisions
  decisions$review_id <- x$before_review$provenance$review_id
  expect_error(lexdiv_ambiguity_review(r$source, "はし", r$candidates,
    r$provenance$resource, decisions), "review_id differs")
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(x, path); saved <- readRDS(path)
  expect_identical(saved, x)
  expect_identical(lexdiv_align_annotations(saved$inputs$split, saved$inputs$reviewed), a)
})

test_that("review keeps kana, source coordinates and unresolved alternatives", {
  x <- japanese_orthography_fixture()
  o <- x$occurrences
  expect_identical(o$surface, c("りんご", "リンゴ", "林檎", rep("はし", 3), "ぷにょ語"))
  expect_identical(o$keyword, o$surface)
  expect_equal(o$start, c(1, 5, 9, 1, 1, 1, 1))
  expect_equal(o$end, c(3, 7, 10, 2, 2, 2, 4))
  expect_identical(substr(o$segment_text, o$start, o$end), o$surface)
  expect_equal(o$candidate_count, c(1, 1, 1, 3, 3, 3, 0))
  expect_identical(x$initial$source, x$review$source)
  expect_identical(x$initial$source, x$imported)
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(x, path); restored <- readRDS(path)
  expect_identical(restored, x)
  r <- restored$review
  expect_identical(lexdiv_ambiguity_review(r$source, r$summary$term,
    r$candidates, r$provenance$resource, r$decisions), r)
  bad <- r$decisions; bad$candidate_id[1] <- "bridge"
  expect_error(lexdiv_ambiguity_review(r$source, r$summary$term,
    r$candidates, r$provenance$resource, bad), "not a candidate")
})
