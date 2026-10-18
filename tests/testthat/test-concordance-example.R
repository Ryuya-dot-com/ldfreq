concordance_example <- function() {
  skip_if_not_installed("quanteda", "4.5.0")
  e <- new.env(parent = globalenv())
  sys.source(system.file("examples", "concordance-demo.R", package = "ldfreq", mustWork = TRUE), e)
  e
}

concordance_input <- function(surfaces, ids = names(surfaces), segments = rep("s", length(ids))) {
  text <- vapply(surfaces, paste, collapse = " ", FUN.VALUE = "")
  tokens <- do.call(rbind, lapply(seq_along(surfaces), function(i) data.frame(
    document_id = rep(ids[i], length(surfaces[[i]])),
    segment_id = rep(segments[i], length(surfaces[[i]])),
    token_index = seq_along(surfaces[[i]]), surface = surfaces[[i]])))
  lexdiv_import_annotations(tokens, data.frame(document_id = ids, segment_id = segments, text = text),
    list(language = "en", analyzer = "authored", analyzer_version = "1", dictionary = "none",
      dictionary_version = "not-applicable", unit = "authored-tokens", normalization = "none"))
}

test_that("concordance retains lemma matches, original coordinates and zero counts", {
  e <- concordance_example(); x <- e$search; h <- x$occurrences
  expect_equal(x$documents$source_tokens, c(12, 12, 14, 3, 0))
  expect_equal(x$documents$searchable_tokens, c(12, 12, 11, 3, 0))
  expect_equal(x$counts$occurrences, c(3, 3, 3, 0, 0, 0, 0, 2, 0, 0, rep(0, 5)))
  context <- subset(h, document_id == "context")
  expect_identical(context$keyword, c("learn", "learned", "learn", "learn new", "learned new"))
  expect_equal(context$document_from, c(2, 7, 11, 2, 7))
  expect_equal(context$from, c(2, 7, 1, 2, 7))
  expect_identical(context$matched_terms[[4]], c("learn", "new"))
  expect_identical(context$pre[3], "")
  expect_identical(context$post[3], " very new")
  # Independent extraction from the saved original strings, including punctuation.
  key <- paste(e$segments$document_id, e$segments$segment_id)
  text <- e$segments$text[match(paste(h$document_id, h$segment_id), key)]
  expect_identical(stringi::stri_sub(text, h$start, h$end), h$keyword)
  expect_equal(length(unique(h$occurrence_id)), nrow(h))
  expect_identical(e$helper$concordance_search(e$annotations, x$queries,
    term_col = "lemma", keep = e$keep, window = 2L), x)
  expect_identical(x$source, e$annotations)
})

test_that("token patterns support fixed, glob, regex and explicit phrase components", {
  e <- concordance_example(); f <- e$helper$concordance_search
  a <- concordance_input(list(d = c("Learn", "learned", "learner", "unlearn", "learn", "new")))
  run <- function(pattern, type, ...) f(a, list(q = pattern), valuetype = type, ...)$occurrences$from
  expect_equal(run("learn", "fixed"), 5)
  expect_equal(run("learn", "fixed", case_insensitive = TRUE), c(1, 5))
  expect_equal(run("learn*", "glob"), c(2, 3, 5))
  expect_equal(run("learn??", "glob"), c(2, 3))
  expect_equal(run("^learn(ed)?$", "regex"), c(2, 5))
  expect_equal(run("learn", "regex"), 2:5)
  expect_equal(run(c("learn*", "new"), "glob"), 5)
  expect_length(run("learn new", "fixed"), 0)
  expect_equal(run(c("learn", "new"), "fixed"), 5)
  expect_error(run("[", "regex"))
})

test_that("overlaps, excluded slots and segment boundaries retain their original meaning", {
  e <- concordance_example(); f <- e$helper$concordance_search
  a <- concordance_input(list(rep("a", 4), c("a", ",", "a"), "a", "a", character()),
    c("repeat", "punct", "boundary", "boundary", "empty"), c("s", "s", "s1", "s2", "s"))
  x <- f(a, list(pair = c("a", "a"), triple = rep("a", 3), copy = c("a", "a")),
    keep = a$tokens$surface != ",", window = 0)
  expect_equal(x$occurrences$from, c(1:3, 1:2, 1:3))
  expect_true(all(x$occurrences$document_id == "repeat"))
  expect_equal(length(unique(x$occurrences$occurrence_id)), 8)
  expect_true(all(x$occurrences$pre == "" & x$occurrences$post == ""))
  for (type in c("glob", "regex")) {
    pattern <- if (type == "glob") "*" else ".*"
    z <- f(a, list(q = c("a", pattern, "a")), valuetype = type,
      keep = a$tokens$surface != ",")
    expect_equal(z$occurrences$document_id, rep("repeat", 2))
  }
  for (keep in list(rep(FALSE, nrow(a$tokens)), rep(TRUE, nrow(a$tokens)))) {
    z <- f(a, list(q = "absent"), keep = keep)
    expect_equal(nrow(z$occurrences), 0)
    expect_true(all(z$counts$occurrences == 0))
    expect_equal(nrow(e$helper$concordance_sort(z)), 0)
  }
  empty <- f(concordance_input(list(empty = character())), list(q = "a"))
  expect_equal(empty$documents$source_tokens, 0)
  expect_equal(empty$counts$occurrences, 0)
})

test_that("context sorting uses nearest tokens, stable ties and absent context last", {
  e <- concordance_example()
  a <- concordance_input(list(z = c("a", "z", "node", "b", "a"),
    a = c("z", "a", "node", "a", "z"), b = c("y", "a", "node", "a", "b"),
    tie = c("y", "a", "node", "a", "b"), empty = "node"))
  x <- e$helper$concordance_search(a, list(q = "node"), window = 2)
  sort <- e$helper$concordance_sort
  expect_identical(sort(x, "left", 2)$document_id, c("b", "tie", "a", "z", "empty"))
  expect_identical(sort(x, "right", 2)$document_id, c("b", "tie", "a", "z", "empty"))
  expect_identical(sort(x, "left", 1)$document_id, c("a", "b", "tie", "z", "empty"))
  expect_setequal(sort(x)$occurrence_id, x$occurrences$occurrence_id)
  expect_error(sort(x, depth = 3), "saved context")
  a <- concordance_input(list(upper = c("node", "B"), lower = c("node", "a")))
  x <- e$helper$concordance_search(a, list(q = "node"))
  expect_identical(sort(x)$document_id, c("upper", "lower"))
  expect_identical(sort(x, ignore_case = TRUE)$document_id, c("lower", "upper"))
})

test_that("Unicode source spans stay exact under quanteda's matching semantics", {
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  e <- concordance_example()
  a <- concordance_input(list(unicode = c("\U0001f600", "か\u3099", "猫", "が", "猫", "a_b")))
  x <- e$helper$concordance_search(a, list(q = c("が", "猫"), underscore = "a_b"), window = 1)
  expect_equal(x$occurrences$from, c(2, 4, 6))
  expect_equal(x$occurrences$start, c(3, 8, 12))
  expect_identical(x$occurrences$keyword, c("か\u3099 猫", "が 猫", "a_b"))
  expect_identical(x$occurrences$pre[1], "\U0001f600 ")
  expect_identical(x$occurrences$post[3], "")
})

test_that("DP agrees with hand counts and an independent count-table calculation", {
  e <- concordance_example(); d <- e$dispersion
  expect_equal(d$documents$DP[1:2], c(0, 2/3))
  expect_identical(d$documents$missing_reason[4:5], c("no_matches", "no_searchable_tokens"))
  a <- concordance_input(list(unequal = c("x", "skip", "skip", "x", "a", "b", "c"),
    once = c("x", "a", "b", "c", "d", "e"), singleton = "x", excluded = "x"))
  keep <- a$tokens$surface != "skip" & a$tokens$document_id != "excluded"
  x <- e$helper$concordance_search(a, list(q = "x"), keep = keep)
  z <- e$helper$concordance_dispersion(x, "q", parts = 3)
  expect_equal(z$parts$source_tokens[1:3], c(3, 2, 2))
  expect_equal(z$parts$source_from[1:3], c(1, 4, 6))
  expect_equal(z$parts$source_to[1:3], c(3, 5, 7))
  expect_equal(z$parts$searchable_tokens[1:3], c(1, 2, 2))
  expect_equal(z$parts$occurrences[1:3], c(1, 1, 0))
  expect_equal(z$documents$DP[1:2], c(0.4, 2/3))
  expect_identical(z$documents$missing_reason[3:4],
    c("fewer_than_two_nonempty_parts", "no_searchable_tokens"))
  expect_true(all(is.na(z$documents$DP[3:4])))
  # Use explicit interval bounds and tabulation, not the helper's bin formula.
  position <- seq_len(7); interval <- cut(position, c(0, 3, 5, 7), labels = FALSE)
  exposure <- tabulate(interval[c(1, 4, 5, 6, 7)], 3)
  observed <- tabulate(interval[c(1, 4)], 3)
  expected <- exposure / sum(exposure)
  expect_equal(z$documents$DP[1], 0.5 * sum(abs(observed / sum(observed) - expected)))
  expect_identical(z$occurrence_ids, x$occurrences$occurrence_id)
  expect_error(e$helper$concordance_dispersion(e$search, "phrase"), "single-token")
  expect_error(e$helper$concordance_dispersion(x, "q", parts = 1), "parts")
  expect_error(e$helper$concordance_dispersion(x, "q", max_cells = 2), "cells")
})

test_that("missing lemmas change denominators without closing source gaps", {
  e <- concordance_example()
  a <- concordance_input(list(d = c("a", "gap", "b", "end")))
  tokens <- a$tokens; tokens$lemma <- c("a", NA, "b", " ")
  a <- lexdiv_import_annotations(tokens, a$segments[c("document_id", "segment_id", "text")],
    a$provenance$annotation)
  z <- e$helper$concordance_search(a, list(single = "b", phrase = c("a", "b")), term_col = "lemma")
  expect_equal(z$counts$occurrences, c(1, 0))
  expect_equal(z$documents$missing_terms, 2)
  expect_equal(z$documents$searchable_tokens, 2)
  expect_equal(z$occurrences$document_from, 3)
  expect_identical(z$occurrences$pre, "a gap ")
})

test_that("plots use saved IDs, common source coordinates and retain empty documents", {
  skip_if_not_installed("ggplot2")
  e <- concordance_example(); draw <- e$helper$concordance_positions
  p <- draw(e$search, "word"); abs <- draw(e$search, "phrase", relative = FALSE)
  expect_identical(p$data$occurrence_id, e$dispersion$occurrence_ids)
  expect_equal(p$data$position_from[1:3], (c(1, 5, 9) - 0.5) / 12)
  expect_equal(abs$data$position_from, c(2, 7))
  expect_equal(abs$data$position_to, c(3, 8))
  expect_identical(levels(p$data$document), rev(e$search$documents$document_id))
  expect_equal(p$layers[[1]]$data$axis_end, c(1, 1, 1, 1, 0))
  expect_null(p$labels$title); expect_null(p$labels$subtitle); expect_null(p$labels$caption)
  expect_identical(draw(e$search, "word", monochrome = TRUE)$layers[[3]]$aes_params$colour, "black")
  expect_no_warning(ggplot2::ggplot_build(p))
  expect_no_warning(ggplot2::ggplot_build(draw(e$search, "absent")))
})

test_that("invalid input and changed saved searches are rejected, while RDS preserves the record", {
  e <- concordance_example(); f <- e$helper$concordance_search; a <- e$annotations
  expect_error(f(a, list("learn")), "queries")
  expect_error(f(a, list(q = "x", q = "y")), "queries")
  expect_error(f(a, list(q = " ")), "queries")
  expect_error(f(a, list(q = "x"), keep = TRUE), "keep")
  expect_error(f(a, list(q = "x"), term_col = "unknown"), "term_col")
  expect_error(f(a, list(q = "x"), case_insensitive = NA), "case_insensitive")
  expect_error(f(a, list(q = "x"), window = 0.5), "window")
  expect_error(f(a, list(q = "x"), max_cells = 1), "max_tokens")
  expect_error(f(a, list(q = "learn"), window = 50, max_cells = 100), "context cells")
  changed <- a; changed$documents$document_id[1] <- "altered"
  expect_error(f(changed, list(q = "x")), "Source annotations changed")
  for (field in c("occurrences", "counts", "settings", "source")) {
    changed <- e$search; changed[[field]] <- NULL
    expect_error(e$helper$concordance_sort(changed), "saved concordance changed")
    expect_error(e$helper$concordance_dispersion(changed, "word"), "saved concordance changed")
  }
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(e$record, path); restored <- readRDS(path)
  expect_identical(restored, e$record)
  expect_identical(e$helper$concordance_sort(restored$search, "right", 2), restored$sorted)
  expect_identical(e$helper$concordance_dispersion(restored$search, "word", 3), restored$dispersion)
})
