public_analysis_fixture <- function() {
  readRDS(test_path("..", "fixtures", "public-analysis-api-v1.rds"))
}

test_that("public study calls retain the frozen 9005 table and selection", {
  old <- public_analysis_fixture()$study
  before <- serialize(old, NULL)
  expect_identical(do.call(lexdiv_study_table, old$inputs), old$table)
  expect_identical(do.call(lexdiv_study_table, unname(old$inputs)), old$table)
  expect_identical(lexdiv_study_model_data(old$table, "surface-all", "ttr"), old$selected)
  expect_identical(serialize(old, NULL), before)
  legacy <- new.env(parent = baseenv())
  sys.source(system.file("examples", "study-table.R", package = "ldfreq", mustWork = TRUE), legacy)
  expect_identical(formals(legacy$study_long_table), formals(lexdiv_study_table))
  expect_identical(do.call(legacy$study_long_table, old$inputs), old$table)
  expect_identical(legacy$study_model_data(old$table, "surface-all", "ttr"), old$selected)
})

test_that("saved legacy concordances support public operations without rewriting", {
  old <- public_analysis_fixture()
  x <- old$concordance$search
  before <- serialize(x, NULL)
  expect_identical(lexdiv_concordance_sort(x, "right", 2L), old$concordance$sorted)
  expect_identical(lexdiv_concordance_dispersion(x, "word", 3L), old$concordance$dispersion)
  current <- lexdiv_collocations(old$collocation$search, "a")
  for (name in c("results", "pairs", "documents", "search", "settings"))
    expect_identical(current[[name]], old$collocation$adjacent[[name]])
  expect_identical(serialize(x, NULL), before)
  altered <- x
  altered$counts$occurrences[1] <- altered$counts$occurrences[1] + 1L
  expect_error(lexdiv_concordance_sort(altered), "changed")
  expect_error(lexdiv_concordance_dispersion(x, "phrase"), "single-token")
  expect_error(lexdiv_collocations(x, "phrase"), "single-token")
})

test_that("public keyness retains old count populations and empty groups", {
  old <- public_analysis_fixture()$keyness$comparison
  s <- old$settings
  args <- c(list(x = old$source), s[c("target", "reference", "preprocessing_id",
    "term_col", "keep", "min_count", "max_tokens")])
  current <- do.call(lexdiv_keyness, args)
  for (name in c("results", "totals", "documents", "document_counts", "occurrences",
                 "token_audit", "source", "settings"))
    expect_identical(current[[name]], old[[name]])
  expect_identical(do.call(lexdiv_keyness, unname(args)), current)
  expect_error(lexdiv_keyness(old$source, s$target, s$target, s$preprocessing_id), "overlap")
  empty <- lexdiv_keyness(old$source, "t_empty", "r_empty", "all-empty")
  expect_identical(empty$totals$status, c("no_counted_tokens", "no_counted_tokens"))
  expect_equal(nrow(empty$results), 0)
})

test_that("new concordance class adds dispatch without changing occurrences", {
  skip_if_not_installed("quanteda", "4.5.0")
  old <- public_analysis_fixture()
  x <- old$concordance$search
  s <- x$settings
  args <- c(list(x = x$source, queries = x$queries), s[c("term_col", "valuetype",
    "case_insensitive", "keep", "window", "max_cells")])
  current <- do.call(lexdiv_concordance, args)
  expect_s3_class(current, "lexdiv_concordance", exact = TRUE)
  for (name in c("occurrences", "counts", "documents", "source", "queries", "settings"))
    expect_identical(current[[name]], x[[name]])
  expect_identical(do.call(lexdiv_concordance, unname(args)), current)
  expect_identical(lexdiv_concordance_sort(current, "right", 2), old$concordance$sorted)
  expect_identical(lexdiv_concordance_dispersion(current, "word", 3), old$concordance$dispersion)
  legacy <- new.env(parent = baseenv())
  sys.source(system.file("examples", "concordance.R", package = "ldfreq", mustWork = TRUE), legacy)
  legacy_search <- do.call(legacy$concordance_search, args)
  expect_identical(class(legacy_search), "list")
  expect_identical(legacy_search$occurrences, current$occurrences)
  expect_identical(formals(legacy$concordance_search), formals(lexdiv_concordance))
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(current, path, version = 2)
  expect_identical(readRDS(path), current)
  context <- lexdiv_keyness_concordance(old$keyness$comparison, "learn", window = 2L)
  expect_s3_class(context$search, "lexdiv_concordance", exact = TRUE)
  expect_identical(context$search$occurrences, old$keyness$context$search$occurrences)
  expect_identical(context$comparison_id, old$keyness$context$comparison_id)
  altered <- old$keyness$comparison
  altered$results$G2[1] <- altered$results$G2[1] + 1
  expect_error(lexdiv_keyness_concordance(altered, "learn"), "changed")
})

test_that("public position plots retain all documents and return selected data invisibly", {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not_installed("ggplot2")
  old <- public_analysis_fixture()$concordance$search
  x <- lexdiv_concordance(old$source, old$queries, term_col = old$settings$term_col,
    keep = old$settings$keep, window = old$settings$window)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  before <- serialize(x, NULL)
  color <- withVisible(plot(x, "word"))
  mono <- withVisible(plot(x, "word", monochrome = TRUE))
  expect_false(color$visible)
  expect_false(mono$visible)
  expect_identical(color$value, mono$value)
  expect_identical(color$value$documents$document_id, x$documents$document_id)
  expect_identical(color$value$occurrences$occurrence_id,
    x$occurrences$occurrence_id[x$occurrences$query_id == "word"])
  expect_true("empty" %in% color$value$documents$document_id)
  expect_true(any(color$value$counts$occurrences == 0L))
  expect_equal(nrow(plot(x, "absent")$occurrences), 0)
  expect_error(plot(x, "word", monochrome = NA), "TRUE or FALSE")
  expect_error(plot(x, "unknown"), "query_id")
  expect_error(plot(x, "word", typo = TRUE), "Unsupported")
  expect_identical(serialize(x, NULL), before)
})
