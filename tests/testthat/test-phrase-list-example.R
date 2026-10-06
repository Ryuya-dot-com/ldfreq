phrase_example <- function() {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  env <- new.env(parent = globalenv())
  invisible(capture.output(sys.source(system.file("examples", "phrase-list-demo.R",
    package = "ldfreq", mustWork = TRUE), envir = env)))
  env
}

test_that("the installed phrase example preserves counts, source KWIC and denominators", {
  e <- phrase_example(); x <- e$result
  expect_equal(x$documents$source_tokens, c(15, 8, 0))
  expect_equal(x$documents$retained_tokens, c(12, 7, 0))
  expect_equal(x$documents$occurrences, c(4, 1, 0))
  expect_equal(x$documents$covered_tokens, c(9, 4, 0))
  expect_equal(x$documents$coverage, c(9/12, 4/7, NA))
  expect_equal(x$summary$occurrences, c(1, 2, 1, 1, 0))
  expect_equal(x$summary$documents, c(1, 1, 1, 1, 0))
  expect_equal(nrow(x$counts), 15)
  expect_true(all(x$counts$occurrences[x$counts$document_id == "empty"] == 0))
  hits <- x$occurrences
  expect_identical(stringi::stri_sub(hits$segment_text, hits$start, hits$end), hits$keyword)
  ja <- hits[hits$phrase_id == "japanese", ]
  expect_identical(ja$keyword, "国際協力を学ぶ")
  expect_identical(ja$pre, "連合で")
  expect_identical(ja$post, "。")
  expect_equal(c(ja$start, ja$end), c(6, 12))
  expect_false(any(hits$segment_id == "s2")) # Removing "very" must not close the gap.
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(x, path); expect_identical(readRDS(path), x)
  expect_identical(e$phrase_list_kwic(e$annotations, e$phrases, e$resource, e$keep, 2L), x)
  all_excluded <- e$phrase_list_kwic(e$annotations, e$phrases, e$resource,
    rep(FALSE, nrow(e$annotations$tokens)))
  expect_equal(nrow(all_excluded$occurrences), 0)
  expect_true(all(is.na(all_excluded$documents$coverage)))
  expect_true(all(all_excluded$counts$occurrences == 0))
  absent <- e$phrase_list_kwic(e$annotations, e$phrases["absent"], e$resource)
  expect_equal(nrow(absent$occurrences), 0)
  expect_identical(names(absent$occurrences), names(hits))
  expect_equal(absent$documents$coverage, c(0, 0, NA))
})

test_that("all overlaps and duplicate list entries retain identity without inflating coverage", {
  e <- phrase_example()
  segments <- data.frame(document_id = c("repeat", "punct", "boundary", "boundary", "other"),
    segment_id = c("s", "s", "s1", "s2", "s"), text = c("a a a a", "a , a", "a", "a", "a"))
  surfaces <- list(rep("a", 4), c("a", ",", "a"), "a", "a", "a")
  tokens <- do.call(rbind, lapply(seq_along(surfaces), function(i) data.frame(
    document_id = segments$document_id[i], segment_id = segments$segment_id[i],
    token_index = seq_along(surfaces[[i]]), surface = surfaces[[i]])))
  a <- lexdiv_import_annotations(tokens, segments, e$annotations$provenance$annotation)
  phrases <- list(pair = c("a", "a"), triple = rep("a", 3), four = rep("a", 4),
    same_pair_other_id = c("a", "a"), punctuation = c("a", ",", "a"))
  result <- e$phrase_list_kwic(a, phrases, e$resource, tokens$surface != ",", window = 0)
  expect_equal(result$summary$occurrences, c(3, 2, 1, 3, 0))
  expect_equal(result$documents$occurrences, c(9, 0, 0, 0))
  expect_equal(result$documents$covered_tokens, c(4, 0, 0, 0))
  expect_equal(result$documents$coverage, c(1, 0, 0, 0))
  hits <- result$occurrences
  expect_equal(hits$from[hits$phrase_id == "pair"], 1:3)
  expect_equal(hits$to[hits$phrase_id == "pair"], 2:4)
  expect_true(all(hits$pre == "" & hits$post == ""))
  punct <- e$phrase_list_kwic(a, phrases["punctuation"], e$resource)
  expect_identical(punct$occurrences$keyword, "a , a")
  expect_equal(punct$documents$covered_tokens, c(0, 3, 0, 0))
})

test_that("original Unicode and explicit components are not normalized or split", {
  e <- phrase_example()
  surfaces <- c("😀", "が", "猫", "が", "猫", "a_b", "a", "a", "b_a", "A", "a")
  tokens <- data.frame(document_id = "unicode", segment_id = "s",
    token_index = seq_along(surfaces), surface = surfaces)
  a <- lexdiv_import_annotations(tokens,
    data.frame(document_id = "unicode", segment_id = "s", text = paste(surfaces, collapse = " ")),
    e$annotations$provenance$annotation)
  p <- list(decomposed = c("が", "猫"), composed = c("が", "猫"),
    underscore_left = c("a_b", "a"), underscore_right = c("a", "b_a"),
    upper = c("A", "a"))
  x <- e$phrase_list_kwic(a, p, e$resource, window = 1)
  expect_equal(x$summary$occurrences, rep(1, 5))
  expect_equal(x$occurrences$from, c(2, 4, 6, 8, 10))
  expect_equal(x$occurrences$start[1], 3)
  expect_identical(x$occurrences$pre[1], "😀 ")
  expect_identical(x$occurrences$keyword[1:2], c("が 猫", "が 猫"))
  expect_identical(x$occurrences$post[5], "")
})

test_that("modified source and ambiguous phrase specifications fail before analysis", {
  e <- phrase_example(); a <- e$annotations
  a$tokens$surface[1] <- "Changed"
  expect_error(e$phrase_list_kwic(a, e$phrases, e$resource), "align")
  a <- e$annotations; a$documents$document_id[1] <- "Changed"
  expect_error(e$phrase_list_kwic(a, e$phrases, e$resource), "has changed")
  expect_error(e$phrase_list_kwic(e$annotations, list(p = "two words"), e$resource), "phrases")
  expect_error(e$phrase_list_kwic(e$annotations, list(p = c("two words", "x")), e$resource), "phrases")
  expect_error(e$phrase_list_kwic(e$annotations, unname(e$phrases), e$resource), "phrases")
  expect_error(e$phrase_list_kwic(e$annotations, c(e$phrases, e$phrases), e$resource), "phrases")
  expect_error(e$phrase_list_kwic(e$annotations, e$phrases, list()), "resource")
  expect_error(e$phrase_list_kwic(e$annotations, e$phrases, e$resource, keep = TRUE), "keep")
  expect_error(e$phrase_list_kwic(e$annotations, e$phrases, e$resource, window = 0.5), "window")
})
