collocation_example <- function() {
  skip_if_not_installed("quanteda", "4.5.0")
  e <- new.env(parent = globalenv())
  sys.source(system.file("examples", "collocation-demo.R", package = "ldfreq", mustWork = TRUE), e)
  e
}

test_that("adjacent association uses positional marginals with hand-counted values", {
  e <- collocation_example(); x <- e$adjacent
  r <- x$results[match(c("a", "b", "c"), x$results$context), ]
  expect_equal(r$observed, c(0, 2, 1))
  expect_equal(r$node_marginal, rep(3, 3))
  expect_equal(r$context_marginal, c(3, 3, 2))
  expect_equal(r$opportunities, rep(8, 3))
  expect_equal(r$expected, c(9/8, 9/8, 6/8))
  expect_equal(r$MI, c(-Inf, log2(16/9), log2(4/3)))
  expect_equal(r$t_score, c(NA, 7/(8 * sqrt(2)), 1/4))
  expect_equal(r$documents, c(0, 1, 1))
  expect_equal(x$documents$node_occurrences, c(2, 3, 1, 1, 0))
  expect_equal(x$documents$nodes_with_context, c(2, 1, 0, 0, 0))
  expect_equal(x$documents$candidate_slot_pairs, c(4, 4, 2, 2, 0))
  expect_equal(x$documents$eligible_pairs, c(4, 4, 0, 0, 0))
  expect_equal(x$documents$missing_terms, c(0, 0, 0, 1, 0))
  expect_equal(x$documents$node_pairs, c(2, 1, 0, 0, 0))
  # Existing n-gram extraction must identify exactly the same adjacent pairs.
  ng <- lexdiv_ngrams(e$annotations$tokens[e$search$settings$searchable, ],
    "authored", n = 2L, term_col = "lemma", documents = x$documents$document_id)
  expect_equal(x$pairs$node_position, ng$occurrences$start_index)
  expect_equal(x$pairs$context_position, ng$occurrences$end_index)
  expect_equal(x$pairs$context_term, ng$occurrences$term2)
  expect_equal(x$pairs$document_id, ng$occurrences$document_id)
})

test_that("independent Cartesian enumeration agrees across directions and boundaries", {
  e <- collocation_example(); t <- e$annotations$tokens
  # Enumerate every pair independently of the helper's distance-based extraction.
  grid <- expand.grid(i = seq_len(nrow(t)), j = seq_len(nrow(t)))
  distance <- t$token_index[grid$j] - t$token_index[grid$i]
  same <- t$document_id[grid$i] == t$document_id[grid$j] &
    t$segment_id[grid$i] == t$segment_id[grid$j]
  eligible <- e$search$settings$searchable[grid$i] & e$search$settings$searchable[grid$j]
  for (span in list(c(left = 0, right = 1), c(left = 1, right = 0),
      c(left = 2, right = 2), c(left = 0, right = 99))) {
    x <- e$helper$collocation_profile(e$search, "a", span = span)
    use <- same & eligible & distance != 0 & distance >= -span[1] & distance <= span[2]
    oracle <- grid[use, ]; oracle$distance <- distance[use]
    oracle <- oracle[order(oracle$i, oracle$distance), ]
    expect_equal(x$pairs$node_row, oracle$i)
    expect_equal(x$pairs$context_row, oracle$j)
    expect_equal(x$pairs$distance, oracle$distance)
    expect_equal(sum(x$documents$candidate_slot_pairs),
      sum(same & distance != 0 & distance >= -span[1] & distance <= span[2]))
    for (k in seq_len(nrow(x$results))) {
      row <- x$results[k, ]
      is_node <- t$lemma[oracle$i] == "a"
      is_context <- t$lemma[oracle$j] == row$context
      contingency <- table(factor(is_node, c(FALSE, TRUE)), factor(is_context, c(FALSE, TRUE)))
      expect_equal(row$observed, unname(contingency[2, 2]))
      expect_equal(row$node_marginal, sum(contingency[2, ]))
      expect_equal(row$context_marginal, sum(contingency[, 2]))
      expect_equal(row$expected, sum(contingency[2, ]) * sum(contingency[, 2]) / sum(contingency))
    }
  }
  gap <- subset(e$span$pairs, document_id %in% c("gap", "missing"))
  expect_equal(gap$distance, rep(c(2, -2), 2))
  expect_equal(gap$is_node, rep(c(TRUE, FALSE), 2))
  expect_equal(nrow(gap), 4)
  expect_equal(sum(e$span$documents$eligible_pairs), 30)
})

test_that("each repeated node-context position counts, with KWIC and original text links", {
  e <- collocation_example(); x <- e$span
  pairs <- x$pairs[x$pairs$is_node, ]
  hits <- x$search$occurrences
  h <- hits[match(pairs$occurrence_id, hits$occurrence_id), ]
  expect_false(anyNA(h$occurrence_id))
  expect_equal(pairs$node_position, h$from)
  expect_equal(pairs$node_start, h$start)
  expect_equal(pairs$node_end, h$end)
  expect_equal(pairs$document_id, h$document_id)
  t <- e$annotations$tokens
  # The two a nodes in d1 both pair with b at position 2.
  expect_equal(subset(pairs, document_id == "d1" & context_position == 2)$node_position, c(1, 3))
  expect_equal(nrow(unique(x$pairs[c("node_row", "context_row")])), nrow(x$pairs))
  for (i in seq_len(nrow(pairs))) {
    s <- subset(e$segments, document_id == pairs$document_id[i] & segment_id == pairs$segment_id[i])
    expect_identical(stringi::stri_sub(s$text, pairs$context_start[i], pairs$context_end[i]),
      t$surface[pairs$context_row[i]])
  }
})

test_that("thresholds flag rows without changing the sample, and zero differs from missing", {
  e <- collocation_example(); f <- e$helper$collocation_profile
  x <- f(e$search, "a", min_count = 2)
  expect_equal(x$pairs, e$adjacent$pairs)
  expect_equal(x$results$expected, e$adjacent$results$expected)
  expect_equal(x$results$meets_min_count, x$results$context == "b")
  z <- f(e$search, "absent")
  expect_true(all(z$results$status == "no_node_opportunities"))
  expect_true(all(is.na(z$results$MI) & is.na(z$results$t_score)))
  expect_equal(z$results$observed, rep(0, nrow(z$results)))
  expect_false("gap" %in% x$results$context)
  search <- e$helper$concordance_search(e$annotations, list(a = "a"), keep = rep(FALSE, nrow(e$tokens)))
  none <- f(search, "a")
  expect_equal(nrow(none$results), 0)
  expect_equal(nrow(none$pairs), 0)
  expect_true(is.character(none$results$status))
  expect_true(all(none$documents$status == "no_eligible_pairs"))
  expect_equal(sum(none$documents$candidate_slot_pairs), 12)
  empty <- lexdiv_import_annotations(e$tokens[FALSE, ],
    subset(e$segments, document_id == "empty"), e$annotations$provenance$annotation)
  s <- e$helper$concordance_search(empty, list(a = "a"))
  z <- f(s, "a")
  expect_equal(nrow(z$pairs), 0)
  expect_equal(z$documents$candidate_slot_pairs, 0)
  expect_equal(z$documents$node_occurrences, 0)
  expect_invisible(e$helper$collocation_validate(z))
})

test_that("pattern nodes pool matched positions while context terms retain exact identity", {
  e <- collocation_example()
  s <- e$helper$concordance_search(e$annotations, list(ab = "^[ab]$"),
    valuetype = "regex", term_col = "lemma", keep = e$tokens$surface != ",")
  x <- e$helper$collocation_profile(s, "ab")
  expect_equal(sum(x$pairs$is_node), 7)
  expect_equal(sum(x$results$observed), 7)
  expect_equal(unique(x$results$node_marginal), 7)
  expect_true(all(x$pairs$node_term[x$pairs$is_node] %in% c("a", "b")))
  t <- e$tokens; t$lemma[2] <- "B"
  source <- lexdiv_import_annotations(t, e$segments, e$annotations$provenance$annotation)
  s <- e$helper$concordance_search(source, list(a = "A"),
    term_col = "lemma", case_insensitive = TRUE, keep = t$surface != ",")
  x <- e$helper$collocation_profile(s, "a")
  expect_true(all(c("B", "b") %in% x$results$context))
  expect_equal(x$results$observed[x$results$context %in% c("B", "b")], c(1, 1))
})

test_that("saved records replay exactly and invalid or altered inputs fail", {
  e <- collocation_example(); f <- e$helper$collocation_profile
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(e$record, path, version = 2)
  reopened <- readRDS(path)
  expect_identical(reopened, e$record)
  expect_invisible(e$helper$collocation_validate(reopened$span))
  expect_identical(f(reopened$span$search, "a", span = c(left = 2L, right = 2L)), reopened$span)
  bad <- reopened$span; bad$pairs$context_row[1] <- 99L
  expect_error(e$helper$collocation_validate(bad), "changed")
  bad <- e$search; bad$source$tokens$lemma[1] <- "changed"
  expect_error(f(bad, "a"), "changed")
  expect_error(f(e$search, "phrase"), "single-token")
  expect_error(f(e$search, "unknown"), "query_id")
  for (span in list(c(1, 2), c(right = 1, left = 2), c(left = 0, right = 0),
      c(left = -1, right = 1), c(left = NA_real_, right = 1), c(left = 1.5, right = 1)))
    expect_error(f(e$search, "a", span = span), "span")
  expect_error(f(e$search, "a", min_count = 0), "min_count")
  expect_error(f(e$search, "a", max_pairs = 11), "Candidate slot pairs")
  expect_equal(nrow(f(e$search, "a", max_pairs = 12)$pairs), 8)
})
