ngcompare_fixture <- function() {
  resource <- list(resource_id = "authored_comparison", resource_version = "1",
    creator = "Example author", source_reference = "Authored demonstration",
    data_license = "Project-authored example", transformation_id = "none",
    lookup_unit = "adjacent_surface_ngram", resource_key_normalization_id = "identity")
  tokens <- data.frame(document_id = "d", segment_id = rep(paste0("s", 1:4), each = 2),
    token_index = rep(1:2, 4), term = c("a", "b", "a", "b", "c", "d", "x", "y"))
  target <- lexdiv_ngrams(tokens, "same", documents = c("d", "empty"))
  counts <- data.frame(n = 2L, term1 = c("a", "c", "z"), term2 = c("b", "d", "z"),
    term3 = NA_character_, count = c(3, 1, 6), document_count = c(2, 1, 4))
  totals <- data.frame(n = 2:3, opportunities = c(10, 0), documents = 5)
  a <- lexdiv_ngram_reference(counts, resource, totals, "same", complete = TRUE)
  bcounts <- counts[1, ]; bcounts$count <- 2
  b <- lexdiv_ngram_reference(bcounts, resource, totals, "same", complete = FALSE)
  list(x = target, references = list(full = a, pruned = b), tokens = tokens)
}

test_that("common items distinguish frequency changes from changing coverage", {
  f <- ngcompare_fixture(); out <- lexdiv_ngram_compare(f$x, f$references)
  s <- subset(out$summary, document_id == "d" & n == 2)
  expect_equal(s$mean_frequency_per_million, c(175000, 400000/3, 200000, 200000))
  expect_equal(s$value_coverage, c(1, 1, 1/2, 1/3))
  expect_equal(s$common_items, c(2, 1, 2, 1))
  expect_equal(s$common_coverage, c(1/2, 1/3, 1/2, 1/3))
  expect_equal(s$common_mean_frequency_per_million, c(300000, 300000, 200000, 200000))
  expect_equal(s$difference_from_baseline, c(0, 0, -100000, -100000))
  expect_identical(out$lookup$common_available, rep(c(TRUE, TRUE, FALSE, FALSE), 2))
  expect_equal(out$lookup$difference_from_baseline,
    c(0, 0, NA, NA, -100000, -100000, NA, NA))
  expect_equal(out$references$opportunities, rep(c(10, 0), 2))
  expect_equal(s$reference_documents, rep(5, 4))
  expect_identical(out$documents, f$x$documents)
  expect_identical(out$provenance$baseline, "full")
  expect_identical(out$provenance$target, f$x$provenance)
  for (id in names(f$references)) {
    p <- lexdiv_ngram_profile(f$x, f$references[[id]])
    actual <- out$summary[out$summary$reference_id == id, names(p$summary)]
    rownames(actual) <- NULL
    expect_identical(actual, p$summary)
    actual <- out$lookup[out$lookup$reference_id == id, names(p$lookup)]
    rownames(actual) <- NULL
    expect_identical(actual, p$lookup)
  }
  p <- tempfile(fileext = ".rds"); on.exit(unlink(p))
  saveRDS(list(target = f$x, references = f$references, comparison = out), p)
  saved <- readRDS(p)
  expect_identical(lexdiv_ngram_compare(saved$target, saved$references), saved$comparison)
})

test_that("baseline and all-reference intersection are explicit", {
  f <- ngcompare_fixture()
  reverse <- lexdiv_ngram_compare(f$x, f$references, baseline = "pruned")
  s <- subset(reverse$summary, document_id == "d" & n == 2)
  expect_equal(s$difference_from_baseline, c(100000, 100000, 0, 0))
  reordered <- lexdiv_ngram_compare(f$x, rev(f$references), baseline = "full")
  expect_identical(reordered$provenance$reference_order, c("pruned", "full"))
  expect_equal(subset(reordered$summary, document_id == "d" & n == 2)$difference_from_baseline,
    c(-100000, -100000, 0, 0))
  third <- lexdiv_ngram_reference(f$references$full$counts[2, ],
    f$references$full$provenance$resource, f$references$full$totals, "same", FALSE)
  out <- lexdiv_ngram_compare(f$x, c(f$references, list(third = third)))
  expect_false(any(out$lookup$common_available))
  s <- subset(out$summary, document_id == "d" & n == 2)
  expect_identical(s$comparison_status, rep("no_common_values", 6))
  expect_true(all(is.na(s$common_mean_frequency_per_million)))
  expect_true(all(is.na(s$difference_from_baseline)))
  expect_true(all(s$common_coverage == 0))
})

test_that("defined sample zeros belong to the common set but zero denominators do not", {
  f <- ngcompare_fixture(); a <- f$references$full
  counts <- a$counts[c(1, 3), ]; counts$count <- c(2, 8)
  b <- lexdiv_ngram_reference(counts, a$provenance$resource, a$totals, "same", TRUE)
  out <- lexdiv_ngram_compare(f$x, list(a = a, b = b))
  s <- subset(out$summary, document_id == "d" & n == 2)
  expect_equal(s$common_items, c(4, 3, 4, 3))
  expect_equal(s$common_coverage, rep(1, 4))
  expect_equal(s$difference_from_baseline, c(0, 0, -75000, -200000/3))
  empty <- lexdiv_ngrams(f$tokens[FALSE, ], "same")
  zero <- lexdiv_ngram_reference(empty, a$provenance$resource)
  out <- lexdiv_ngram_compare(f$x, list(a = a, zero = zero))
  expect_true(all(out$summary$common_items == 0))
  expect_true(all(is.na(out$summary$difference_from_baseline)))
  expect_identical(subset(out$summary, reference_id == "zero" & document_id == "d" & n == 2)$missing_reason,
    rep("zero_reference_opportunities", 2))
  none <- lexdiv_ngram_compare(empty, f$references)
  full <- lexdiv_ngram_compare(f$x, f$references)
  for (field in c("summary", "lookup", "documents"))
    expect_identical(none[[field]], full[[field]][FALSE, ])
  s <- subset(full$summary, document_id == "empty" | n == 3)
  expect_identical(s$comparison_status, rep("empty", nrow(s)))
  expect_true(all(is.na(s$common_coverage)))
})

test_that("inconsistent references and excessive output fail before profiling", {
  f <- ngcompare_fixture()
  expect_error(lexdiv_ngram_compare(f$x, unname(f$references)), "names")
  expect_error(lexdiv_ngram_compare(f$x, f$references[1]), "at least two")
  expect_error(lexdiv_ngram_compare(f$x, setNames(f$references, c("a", "a"))), "unique")
  expect_error(lexdiv_ngram_compare(f$x, f$references, "unknown"), "baseline")
  bad <- f$references; bad$full$totals$opportunities[1] <- 1
  expect_error(lexdiv_ngram_compare(f$x, bad), "unmodified")
  a <- f$references$full
  for (field in c("lookup_unit", "resource_key_normalization_id")) {
    resource <- a$provenance$resource; resource[[field]] <- "different"
    b <- lexdiv_ngram_reference(a$counts, resource, a$totals, "same", TRUE)
    expect_error(lexdiv_ngram_compare(f$x, list(a = a, b = b)), field)
  }
  b <- lexdiv_ngram_reference(a$counts, a$provenance$resource, a$totals, "different", TRUE)
  expect_error(lexdiv_ngram_compare(f$x, list(a = a, b = b)), "preprocessing_id")
  b <- lexdiv_ngram_reference(a$counts, a$provenance$resource, a$totals[1, ], "same", TRUE)
  expect_error(lexdiv_ngram_compare(f$x, list(a = a, b = b)), "every requested n")
  expect_equal(nrow(lexdiv_ngram_compare(f$x, f$references, max_rows = 24)$summary), 16)
  local_mocked_bindings(lexdiv_ngram_profile = function(...) stop("PROFILE_REACHED"), .package = "ldfreq")
  expect_error(lexdiv_ngram_compare(f$x, f$references, max_rows = 23), "exceed max_rows")
  expect_error(lexdiv_ngram_compare(f$x, f$references, max_rows = 24), "PROFILE_REACHED")
})

test_that("bigrams and trigrams use their own reference denominators and requested order", {
  resource <- ngcompare_fixture()$references$full$provenance$resource
  target <- lexdiv_ngrams(data.frame(document_id = "d", segment_id = "s",
    token_index = 1:3, term = c("a", "b", "c")), "same", n = c(3L, 2L))
  counts <- data.frame(n = c(2L, 2L, 2L, 3L, 3L),
    term1 = c("a", "b", "z", "a", "z"), term2 = c("b", "c", "z", "b", "z"),
    term3 = c(NA, NA, NA, "c", "z"), count = c(3, 1, 6, 1, 1), document_count = 1)
  a <- lexdiv_ngram_reference(counts, resource,
    data.frame(n = 2:3, opportunities = c(10, 2), documents = 5), "same", TRUE)
  counts$count <- c(2, 2, 6, 3, 1)
  b <- lexdiv_ngram_reference(counts, resource,
    data.frame(n = c(3L, 2L), opportunities = c(4, 10), documents = 5), "same", TRUE)
  out <- lexdiv_ngram_compare(target, list(a = a, b = b))
  expect_identical(out$lookup$n, rep(c(3L, 2L, 2L), 2))
  expect_equal(out$summary$reference_opportunities, c(2, 2, 10, 10, 4, 4, 10, 10))
  expect_equal(out$summary$common_mean_frequency_per_million,
    c(500000, 500000, 200000, 200000, 750000, 750000, 200000, 200000))
  expect_equal(out$summary$difference_from_baseline, c(0, 0, 0, 0, 250000, 250000, 0, 0))
})

test_that("generated reference comparisons agree with a direct component-wise oracle", {
  set.seed(613)
  resource <- ngcompare_fixture()$references$full$provenance$resource
  pairs <- data.frame(term1 = c("a_b", "a", "\u00e9", "e\u0301"),
    term2 = c("c", "b_c", "word", "word"))
  for (iteration in 1:10) {
    selected <- sample(1:4, 7, replace = TRUE)
    doc <- rep(c("two", "one"), length.out = 7)
    tokens <- data.frame(document_id = rep(doc, each = 2),
      segment_id = rep(as.character(1:7), each = 2), token_index = rep(1:2, 7),
      term = as.vector(t(as.matrix(pairs[selected, ]))))
    x <- lexdiv_ngrams(tokens, "exact", n = 2, documents = c("two", "one", "empty"))
    references <- list(); rates <- matrix(NA_real_, nrow = 7, ncol = 3)
    for (j in 1:3) {
      count <- sample(1:8, 4, replace = TRUE)
      keep <- if (j == 1) rep(TRUE, 4) else sample(c(TRUE, FALSE), 4, replace = TRUE)
      table <- data.frame(n = 2L, pairs, term3 = NA_character_, count = count, document_count = 1)
      references[[paste0("ref", j)]] <- lexdiv_ngram_reference(table[keep, ], resource,
        data.frame(n = 2L, opportunities = sum(count), documents = 1), "exact", j == 1)
      for (i in 1:7) {
        match_row <- which(pairs$term1 == tokens$term[2*i-1] & pairs$term2 == tokens$term[2*i])
        if (keep[match_row]) rates[i,j] <- count[match_row] / sum(count) * 1e6
      }
    }
    out <- lexdiv_ngram_compare(x, references)
    common <- apply(rates, 1, function(v) all(!is.na(v)))
    expect_equal(out$lookup$frequency_per_million, as.vector(rates))
    expect_identical(out$lookup$common_available, rep(common, 3))
    expected_means <- expected_differences <- numeric()
    for (j in 1:3) for (id in c("two", "one", "empty")) for (weight in c("token", "type")) {
      take <- which(doc == id & common)
      if (weight == "type") take <- take[!duplicated(pairs[selected[take], ])]
      expected_means <- c(expected_means, if (length(take)) mean(rates[take,j]) else NA_real_)
      expected_differences <- c(expected_differences,
        if (length(take)) mean(rates[take,j]) - mean(rates[take,1]) else NA_real_)
    }
    expect_equal(out$summary$common_mean_frequency_per_million, expected_means)
    expect_equal(out$summary$difference_from_baseline, expected_differences)
  }
})
