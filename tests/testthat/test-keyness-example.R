keyness_example <- function() {
  e <- new.env(parent = globalenv())
  sys.source(system.file("examples", "keyness-demo.R", package = "ldfreq", mustWork = TRUE), e)
  e
}

keyness_again <- function(e, ...) {
  s <- e$comparison$settings
  args <- c(list(x = e$annotations), s[c("target", "reference", "preprocessing_id",
    "term_col", "keep", "min_count", "max_tokens")])
  overrides <- list(...)
  args[names(overrides)] <- overrides
  do.call(e$helper$keyness_compare, args)
}

test_that("keyness uses hand-counted two-by-two tables and complete denominators", {
  e <- keyness_example(); x <- e$comparison; r <- x$results
  expect_equal(r$term, c("learn", "read", "write", "speak"))
  expect_equal(r$target_count, c(6, 1, 1, 0))
  expect_equal(r$reference_count, c(2, 5, 0, 1))
  expect_equal(r$target_other, c(2, 7, 7, 8))
  expect_equal(r$reference_other, c(6, 3, 8, 7))
  expect_equal(r$target_total, rep(8, 4))
  expect_equal(r$reference_total, rep(8, 4))
  expect_equal(r$expected_target, c(4, 3, .5, .5))
  expect_equal(r$expected_reference_other, c(4, 5, 7.5, 7.5))
  expect_equal(r$target_per_1000, c(750, 125, 125, 0))
  expect_equal(r$reference_per_1000, c(250, 625, 0, 125))
  expect_equal(r$log_ratio, c(log2(3), log2(1/5), Inf, -Inf))
  expect_equal(r$G2[1], 4 * (6 * log(1.5) + 2 * log(.5)))
  expect_equal(r$signed_G2, r$G2 * c(1, -1, 1, -1))
  expect_equal(r$target_documents, c(2, 1, 1, 0))
  expect_equal(r$reference_documents, c(2, 2, 0, 1))
  expect_equal(x$totals$counted_tokens, c(8, 8))
  expect_equal(x$totals$source_tokens, c(10, 8))
  expect_equal(x$totals$kept_tokens, c(9, 8))
  expect_equal(x$totals$missing_terms, c(1, 0))
  expect_equal(x$totals$documents, c(3, 3))
  expect_equal(table(x$token_audit$status),
    table(c(rep("counted", 16), "excluded_token", "missing_term", rep("excluded_document", 2))))
  expect_false(any(c("unknown", ".", "unlisted") %in% r$term))
  for (g in c("target", "reference")) {
    observed <- with(subset(x$document_counts, corpus == g), tapply(count, term, sum))
    expect_equal(as.numeric(observed), r[[paste0(g, "_count")]][match(names(observed), r$term)])
  }
  expect_equal(x$documents$counted_tokens[x$documents$document_id %in% c("t_empty", "r_empty", "outside")], c(0, 0, 0))
})

test_that("binomial likelihood, unequal totals and group reversal agree", {
  e <- keyness_example()
  for (ref in list(c("r1", "r2", "r_empty"), "r1", "r2")) {
    x <- keyness_again(e, reference = ref); r <- x$results
    # Independent binomial log-likelihoods: combinatorial constants cancel.
    separate <- dbinom(r$target_count, r$target_total, r$target_count/r$target_total, log = TRUE) +
      dbinom(r$reference_count, r$reference_total, r$reference_count/r$reference_total, log = TRUE)
    pooled <- (r$target_count + r$reference_count) / (r$target_total + r$reference_total)
    common <- dbinom(r$target_count, r$target_total, pooled, log = TRUE) +
      dbinom(r$reference_count, r$reference_total, pooled, log = TRUE)
    expect_equal(r$G2, 2 * (separate - common), tolerance = 1e-12)
    reversed <- keyness_again(e, target = ref, reference = x$settings$target)$results
    reversed <- reversed[match(r$term, reversed$term), ]
    expect_equal(reversed$G2, r$G2)
    expect_equal(reversed$signed_G2, -r$signed_G2)
    expect_equal(reversed$log_ratio, -r$log_ratio)
  }
  restricted <- keyness_again(e, reference = "r1")
  expect_equal(restricted$totals$counted_tokens, c(8, 4))
  expect_false(identical(restricted$provenance$comparison_id, e$comparison$provenance$comparison_id))
  flagged <- keyness_again(e, min_count = 2)
  expect_equal(flagged$results$meets_min_count, c(TRUE, TRUE, FALSE, FALSE))
  expect_equal(flagged$results[names(flagged$results) != "meets_min_count"],
    e$comparison$results[names(flagged$results) != "meets_min_count"])
  expect_identical(flagged$occurrences, e$comparison$occurrences)
  expect_identical(flagged$totals, e$comparison$totals)
})

test_that("empty groups, zero frequencies and constant features are distinguished", {
  e <- keyness_example()
  for (group in c("target", "reference")) {
    args <- setNames(list(if (group == "target") "t_empty" else "r_empty"), group)
    x <- do.call(keyness_again, c(list(e = e), args))
    expect_true(all(x$results$status == paste0("empty_", group)))
    expect_true(all(is.na(x$results$G2) & is.na(x$results$log_ratio)))
    expect_true(all(is.na(x$results[[paste0(group, "_per_1000")]])))
    expect_true(all(x$results[[paste0(group, "_count")]] == 0))
  }
  z <- keyness_again(e, target = "t_empty", reference = "r_empty")
  expect_equal(nrow(z$results), 0)
  expect_equal(nrow(z$occurrences), 0)
  expect_equal(nrow(z$document_counts), 0)
  expect_true(all(z$totals$status == "no_counted_tokens"))
  expect_invisible(e$helper$keyness_validate(z))
  z <- keyness_again(e, keep = rep(FALSE, nrow(e$tokens)))
  expect_equal(nrow(z$results), 0)
  x <- keyness_again(e, keep = e$tokens$surface == "learn")
  expect_equal(x$results$status, "constant_feature")
  expect_equal(x$results$G2, 0)
  expect_equal(x$results$log_ratio, 0)
  expect_equal(x$results$direction, "equal")
  expect_true(all(is.finite(e$comparison$results$G2)))
})

test_that("source identity and missing terms remain auditable", {
  e <- keyness_example(); a <- e$annotations
  t <- e$tokens; s <- e$segments
  # Two distinct IDs with identical text are retained and visibly flagged.
  t <- rbind(t, transform(t[t$document_id == "t1", ], document_id = "copy"))
  s <- rbind(s, transform(s[s$document_id == "t1", ], document_id = "copy"))
  a <- lexdiv_import_annotations(t, s, a$provenance$annotation)
  x <- e$helper$keyness_compare(a, "t1", "copy", "same-text")
  expect_equal(x$results$G2, rep(0, nrow(x$results)))
  expect_true(all(x$documents$shared_text_across_groups[x$documents$document_id %in% c("t1", "copy")]))
  expect_false(any(x$documents$shared_text_across_groups[x$documents$corpus == "excluded"]))
  expect_equal(x$totals$counted_tokens, c(6, 6))
  t <- e$tokens; t$lemma[t$surface == "unknown"] <- "  "
  a <- lexdiv_import_annotations(t, e$segments, e$annotations$provenance$annotation)
  x <- keyness_again(e, x = a)
  expect_equal(x$totals$counted_tokens, c(8, 8))
  expect_equal(x$totals$missing_terms, c(1, 0))
})

test_that("KWIC returns exactly the counted term and original offsets", {
  skip_if_not_installed("quanteda", "4.5.0")
  e <- keyness_example(); x <- e$comparison
  for (term in x$results$term) {
    context <- e$helper$keyness_concordance(x, term)
    hits <- context$search$occurrences
    counted <- subset(x$occurrences, term == context$term)
    expect_identical(context$comparison_id, x$provenance$comparison_id)
    expect_equal(hits$document_id, counted$document_id)
    expect_equal(hits$from, counted$token_index)
    expect_equal(hits$start, counted$start)
    expect_equal(hits$end, counted$end)
    expect_equal(hits$keyword, rep(term, nrow(hits)))
  }
  t <- e$tokens
  t$lemma[1:6] <- c("A", "a", "a*", "a?", "\u00e9", "e\u0301")
  a <- lexdiv_import_annotations(t, e$segments, e$annotations$provenance$annotation)
  x <- keyness_again(e, x = a, keep = rep(TRUE, nrow(t)))
  for (term in t$lemma[1:6]) {
    if (!l10n_info()[["UTF-8"]] && term %in% t$lemma[5:6]) {
      expect_error(e$helper$keyness_concordance(x, term), "UTF-8 LC_CTYPE")
    } else {
      hits <- e$helper$keyness_concordance(x, term)$search$occurrences
      expect_equal(nrow(hits), 1)
      expect_equal(hits$from, match(term, t$lemma))
    }
  }
  expect_error(e$helper$keyness_concordance(x, "absent"), "exact term")
  expect_error(e$helper$keyness_concordance(x, "learn", max_cells = 20), "context cells")
})

test_that("saved comparisons replay, while invalid input and record edits fail", {
  e <- keyness_example(); x <- e$comparison
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(e$record, path, version = 2)
  reopened <- readRDS(path)
  expect_identical(reopened, e$record)
  expect_invisible(e$helper$keyness_validate(reopened$comparison))
  expect_identical(keyness_again(e, x = reopened$comparison$source), x)
  bad <- x; bad$results$target_count[1] <- 999
  expect_error(e$helper$keyness_validate(bad), "changed")
  bad <- e$annotations; bad$tokens$lemma[1] <- "changed"
  expect_error(keyness_again(e, x = bad), "changed")
  expect_error(keyness_again(e, x = list()), "unchanged")
  for (ids in list(character(), c("t1", "t1"), "absent", NA_character_, " ", 1))
    expect_error(keyness_again(e, target = ids), "unique, known")
  expect_error(keyness_again(e, reference = "t1"), "overlap")
  expect_error(keyness_again(e, preprocessing_id = ""), "preprocessing_id")
  expect_error(keyness_again(e, term_col = "token_index"), "character column")
  expect_error(keyness_again(e, term_col = "absent"), "character column")
  expect_error(keyness_again(e, keep = TRUE), "keep")
  expect_error(keyness_again(e, keep = rep(NA, nrow(e$tokens))), "keep")
  expect_error(keyness_again(e, min_count = 0), "min_count")
  expect_error(keyness_again(e, max_tokens = 19), "max_tokens")
})
