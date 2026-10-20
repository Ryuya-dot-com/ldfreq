textbook_example <- function() {
  skip_if_not_installed("quanteda", "4.5.0")
  e <- new.env(parent = globalenv())
  sys.source(system.file("examples", "textbook-progression-demo.R",
    package = "ldfreq", mustWork = TRUE), e)
  e
}

test_that("page and unit counts retain source occurrences and declared introduction", {
  e <- textbook_example(); x <- e$progression
  expected <- rbind(c(0, 2, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0),
    c(3, 3, rep(0, 10)), c(rep(0, 6), 1, 2, rep(0, 4)),
    c(rep(0, 10), 1, 0), rep(0, 12))
  expect_equal(x$pages$occurrences, as.numeric(t(expected)))
  expect_equal(x$summary$occurrences, c(6, 6, 3, 1, 0))
  expect_equal(x$summary$later_occurrences, c(4, 0, 0, NA, 0))
  expect_equal(x$summary$later_unit_coverage, c(2/5, 0, 0, NA, 0))
  expect_equal(x$summary$first_observed_page, c(2, 1, 7, 11, NA))
  expect_equal(x$summary$last_observed_page, c(9, 2, 8, 11, NA))
  expect_equal(subset(x$pages, query_id == "river")$cumulative,
    c(0, 2, 2, 2, 4, 4, 4, 4, 6, 6, 6, 6))
  expect_equal(subset(x$units, query_id == "river")$occurrences, c(2, 0, 2, 0, 2, 0))
  expect_identical(x$search, e$search)
  expect_identical(x$occurrences$occurrence_id, e$search$occurrences$occurrence_id)
  source <- x$search$source$segments
  text <- source$text[match(x$occurrences$segment_id, source$segment_id)]
  expect_identical(stringi::stri_sub(text, x$occurrences$start, x$occurrences$end),
    x$occurrences$keyword)
  expect_identical(x$occurrences$keyword[x$occurrences$query_id == "recycle"],
    c("recycle", "recycled", "recycle"))
  f <- tempfile(fileext = ".rds")
  saveRDS(e$record, f)
  expect_identical(readRDS(f), e$record)
  unlink(f)
})

test_that("missing sections and missing lemmas invalidate exact counts without erasing hits", {
  e <- textbook_example()
  # Add an unavailable exercise on the same page as a known occurrence.
  s <- rbind(e$sections[1:7, ], transform(e$sections[7, ],
    segment_id = "p07-exercise", role = "exercise", observed = FALSE, text = NA_character_),
    e$sections[8:12, ])
  x <- e$helper$textbook_progression(e$search, s, e$targets)
  z <- subset(x$pages, query_id == "recycle")
  expect_equal(z$observed_occurrences[7], 1)
  expect_true(is.na(z$occurrences[7]))
  expect_true(all(is.na(z$cumulative[7:12])))
  expect_equal(z$observed_cumulative[12], 3)
  expect_true(all(is.na(x$summary$occurrences)))
  expect_identical(x$summary$later_status,
    c("incomplete_later_units", "incomplete_later_units", "ok",
      "no_later_units", "incomplete_later_units"))
  expect_equal(x$summary$later_occurrences[3], 0) # Missingness is in its introduction unit.
  y <- e$helper$textbook_progression(e$search, s, e$targets, include = s$role == "body")
  expect_equal(y$pages$occurrences, e$progression$pages$occurrences)
  expect_equal(y$summary$occurrences, c(6, 6, 3, 1, 0))
  # A known blank page is a zero, not an unavailable page.
  expect_true(all(y$pages$occurrences[y$pages$page == 10] == 0))
  tokens <- e$tokens
  tokens$lemma[which(tokens$surface == "river")[1]] <- NA_character_
  a <- lexdiv_import_annotations(tokens, e$sections[c("document_id", "segment_id", "text")],
    e$annotations$provenance$annotation)
  q <- e$helper$concordance_search(a, e$search$queries, term_col = "lemma")
  z <- e$helper$textbook_progression(q, e$sections, e$targets)
  expect_equal(subset(z$pages, query_id == "river" & page == 2)$observed_occurrences, 1)
  expect_true(all(is.na(z$pages$occurrences[z$pages$page == 2])))
  expect_equal(z$summary$observed_occurrences[1], 5)
})

test_that("selection, unknown introductions, reordered targets and queries stay explicit", {
  e <- textbook_example(); f <- e$helper$textbook_progression
  none <- f(e$search, e$sections, e$targets, include = rep(FALSE, 12))
  expect_true(all(none$pages$status == "not_selected"))
  expect_true(all(none$pages$occurrences == 0))
  expect_true(all(none$summary$later_status == "no_later_units"))
  targets <- e$targets[5:1, ]; targets$introduction_unit[1] <- NA_integer_
  x <- f(e$search, e$sections, targets)
  expect_identical(x$summary$query_id, targets$query_id)
  expect_equal(x$summary$occurrences, c(0, 1, 3, 6, 6))
  expect_identical(x$summary$later_status[1], "unknown_introduction")
  expect_true(is.na(x$summary$later_units[1]))
  # A phrase remains a saved contiguous match, with no cross-section bridging.
  q <- e$helper$concordance_search(e$annotations,
    list(phrase = c("the", "river"), absent = c("ideas", "we")), term_col = "lemma")
  x <- f(q, e$sections, data.frame(query_id = c("phrase", "absent"),
    introduction_unit = c(1, 1)))
  expect_equal(x$summary$occurrences, c(5, 0))
  expect_true(all(x$occurrences$to - x$occurrences$from == 1))
})

test_that("ambiguous, reordered and altered inputs fail before aggregation", {
  e <- textbook_example(); f <- e$helper$textbook_progression
  check <- function(s = e$sections, t = e$targets, ...) f(e$search, s, t, ...)
  bad <- e$sections; bad$segment_id[2] <- bad$segment_id[1]
  expect_error(check(bad), "unique IDs")
  expect_error(check(e$sections[12:1, ]), "ordered")
  bad <- e$sections; bad$page[2] <- 1; bad$unit[2] <- 2
  expect_error(check(bad), "ordered|exactly one unit")
  bad <- e$sections; bad$observed[1] <- FALSE
  expect_error(check(bad), "Observed sections")
  expect_error(check(e$sections[-1, ]), "Observed sections")
  bad <- e$sections; bad$document_id[1] <- "another-book"
  expect_error(check(bad), "unique IDs")
  bad <- e$targets; bad$query_id[1] <- "extra"
  expect_error(check(t = bad), "Targets")
  bad <- e$targets; bad$introduction_unit[1] <- 7
  expect_error(check(t = bad), "Targets")
  expect_error(check(include = TRUE), "logical flags")
  expect_error(check(max_cells = 89), "cells")
  altered <- e$search; altered$counts$occurrences[1] <- 99
  expect_error(f(altered, e$sections, e$targets), "changed")
  # One book can contain several observed sections on a page, but source order is fixed.
  s <- e$sections; s$page[2] <- 1
  z <- check(s)
  expect_equal(subset(z$pages, query_id == "planet" & page == 1)$occurrences, 6)
  expect_equal(subset(z$pages, query_id == "river" & page == 1)$occurrences, 2)
})

test_that("plots retain zeros, missing cells, selected scope and unmodified saved data", {
  skip_if_not_installed("ggplot2")
  e <- textbook_example(); draw <- e$helper$textbook_progression_plot
  for (by in c("page", "unit")) for (mono in c(FALSE, TRUE)) {
    p <- draw(e$progression, by, monochrome = mono)
    expect_no_warning(ggplot2::ggplot_build(p))
    expect_null(p$labels$title); expect_null(p$labels$subtitle); expect_null(p$labels$caption)
    expect_equal(nrow(p$data), if (by == "page") 60 else 30)
    expect_identical(levels(p$data$target), rev(e$targets$query_id))
  }
  expect_equal(draw(e$progression, cumulative = TRUE)$data$value,
    e$progression$pages$cumulative)
  none <- e$helper$textbook_progression(e$search, e$sections, e$targets, rep(FALSE, 12))
  expect_true(all(draw(none)$data$display_label == "\u2014"))
  altered <- e$progression; altered$pages$occurrences[1] <- 1
  expect_error(draw(altered), "changed")
  expect_error(draw(e$progression, cumulative = NA), "flags")
})
