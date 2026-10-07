japanese_file_fixture <- function() {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  env <- new.env(parent = baseenv())
  sys.source(system.file("examples", "japanese-file-workflow.R", package = "ldfreq",
    mustWork = TRUE), env)
  env
}

test_that("Japanese file review keeps title hits outside body and target counts", {
  e <- japanese_file_fixture(); x <- e$ja_file_record
  on.exit(unlink(e$ja_file_output, recursive = TRUE))
  expect_equal(x$counts$source_N, c(7, 13, 2, 1, 0))
  expect_equal(x$counts$outside_body_N, c(1, 1, 0, 0, 0))
  expect_equal(x$metrics$N, c(5, 9, 1, 0, 0))
  expect_equal(x$metrics$V, c(4, 6, 1, 0, 0))
  expect_equal(x$metrics$value, c(4/5, 6/9, 1, NA, NA))
  expect_equal(x$counts$target_N, c(3, 3, 1, 0, 0))
  expect_equal(x$counts$selected_N, c(3, 2, 0, 0, 0))
  expect_equal(x$counts$selection_coverage, c(1, 2/3, 0, NA, NA))
  expect_equal(x$counts$target_lexical_V, c(1, NA, NA, 0, 0))
  expect_equal(x$counts$common_surface_V, c(3, 1, 0, 0, 0))
  expect_equal(x$counts$common_lexical_V, c(1, 2, 0, 0, 0))
  expect_equal(rowSums(x$counts[c("selected_N", "unreviewed_N", "unresolved_N",
    "no_candidates_N")]), x$counts$target_N)
  expect_identical(x$before$source, x$after$source)
  expect_identical(x$imported$segments$text[5], "")
  expect_identical(x$imported$segments$text[1], enc2utf8("リンゴ\nりんごとリンゴと林檎。\n"))
  expect_true(all(x$after$occurrences$status[!e$ja_file_context$in_body] == "unreviewed"))
  expect_equal(x$after$occurrences$start[x$after$occurrences$document_id == "variants"],
    c(1, 5, 9, 13))
  expect_equal(sum(x$selection$reason == "outside_body"), 2)
  expect_equal(sum(x$selection$reason == "full_stop"), 6)
})

test_that("body selection rejects partial tokens and invalid scopes", {
  e <- japanese_file_fixture(); x <- e$ja_file_record
  on.exit(unlink(e$ja_file_output, recursive = TRUE))
  ranges <- x$body_ranges
  ranges$start[1] <- 6L
  expect_error(e$select_japanese_example_body(x$imported, ranges), "cuts through a token")
  for (invalid in c(0, 1.5, Inf, NA_real_)) {
    ranges <- x$body_ranges; ranges$start[1] <- invalid
    expect_error(e$select_japanese_example_body(x$imported, ranges), "codepoint bounds")
  }
  ranges <- x$body_ranges; ranges$end[1] <- 1000
  expect_error(e$select_japanese_example_body(x$imported, ranges), "codepoint bounds")
  ranges <- x$body_ranges; ranges$document_id[1] <- ranges$document_id[2]
  expect_error(e$select_japanese_example_body(x$imported, ranges), "one body-range")
  ranges <- x$body_ranges; ranges$start[5] <- 1L
  expect_error(e$select_japanese_example_body(x$imported, ranges), "NA/NA")
  # A different scope changes inclusion, while the original source stays intact.
  ranges <- x$body_ranges; ranges$start[1:2] <- 1L
  wider <- e$select_japanese_example_body(x$imported, ranges)
  expect_equal(sum(wider$retained), sum(x$selection$retained) + 2)
  expect_identical(wider$token_index, x$imported$tokens$token_index)
})

test_that("saved Japanese file records replay without re-reading original files", {
  e <- japanese_file_fixture(); x <- e$ja_file_restored
  on.exit(unlink(e$ja_file_output, recursive = TRUE))
  expect_identical(x, e$ja_file_record)
  r <- x$after
  expect_identical(lexdiv_ambiguity_review(r$source, r$summary$term, r$candidates,
    r$provenance$resource, x$decisions), r)
  expect_identical(e$select_japanese_example_body(x$imported, x$body_ranges), x$selection)
  # CSV is only a count export; the complete RDS retains sources and decisions.
  expect_equal(utils::read.csv(file.path(e$ja_file_output, "target-counts.csv"),
    fileEncoding = "UTF-8")$selected_N, c(3, 2, 0, 0, 0))
  t <- x$imported$tokens[x$selection$retained, ]
  parts <- setNames(lapply(x$imported$documents$document_id,
    function(id) t$surface[t$document_id == id]), x$imported$documents$document_id)
  expect_identical(lexdiv_metrics_batch(parts, metrics = "ttr"), x$metrics)
})
