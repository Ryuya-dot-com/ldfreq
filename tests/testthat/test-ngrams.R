ngram_fixture <- function() {
  data.frame(document_id = c(rep("r1", 5), rep("r2", 4)),
    segment_id = c(rep("s1", 3), rep("s2", 2), rep("s1", 4)),
    token_index = c(1, 2, 3, 1, 2, 1, 2, 3, 5),
    term = c("a", "b", "a", "a", "b", "a", "b", "c", "ignored"))
}
ngram_resource <- function() {
  list(resource_id = "authored_ngrams", resource_version = "1",
    creator = "Example author", source_reference = "Authored demonstration",
    data_license = "Project-authored example", transformation_id = "none",
    lookup_unit = "adjacent_surface_ngram", resource_key_normalization_id = "identity")
}
ngram_extract <- function(data = ngram_fixture(), ...) lexdiv_ngrams(data, "identity", ...)

test_that("segments, documents and position gaps constrain adjacency", {
  x <- ngram_extract(documents = c("r2", "r1", "empty"))
  expect_equal(x$totals$opportunities, c(5, 2))
  expect_equal(x$counts$count, c(3, 1, 1, 1, 1))
  expect_equal(x$counts$document_count, c(2, 1, 1, 1, 1))
  expect_identical(x$documents$document_id, rep(c("r2", "r1", "empty"), each = 2))
  expect_equal(x$documents$opportunities, c(2, 1, 3, 1, 0, 0))
  expect_equal(x$documents$ngram_types, c(2, 1, 2, 1, 0, 0))
  expect_true(all(x$documents$status[5:6] == "empty_document"))
  expect_false(any(x$occurrences$term2 == "ignored"))
  expect_equal(x$occurrences$end_index - x$occurrences$start_index,
    x$occurrences$n - 1)
  expect_equal(ngram_extract(n = c(3, 2))$occurrences$n, c(3, 3, rep(2, 5)))
  gapped <- data.frame(document_id = "d", segment_id = "s",
    token_index = c(1, 3), term = c("make", "decision"))
  expect_equal(nrow(ngram_extract(gapped)$occurrences), 0)
})

test_that("complete and incomplete references keep zeros distinct from missing values", {
  reference <- lexdiv_ngram_reference(ngram_extract(), ngram_resource())
  target <- data.frame(document_id = "t", segment_id = "s", token_index = 1:5,
    term = c("a", "b", "a", "b", "new"))
  x <- ngram_extract(target, n = 2, documents = c("t", "empty"))
  p <- lexdiv_ngram_profile(x, reference)
  expect_identical(p$lookup$reference_status, c("listed", "listed", "listed", "not_observed"))
  expect_equal(p$lookup$reference_count, c(3, 1, 3, 0))
  expect_equal(p$summary$eligible_items, c(4, 3, 0, 0))
  expect_equal(p$summary$mean_frequency_per_million[1:2], c(350000, 800000 / 3))
  expect_equal(p$summary$lookup_coverage[1:2], c(3/4, 2/3))
  expect_equal(p$summary$value_coverage[1:2], c(1, 1))
  expect_identical(p$summary$missing_reason[3:4], rep("no_target_ngrams", 2))
  partial <- lexdiv_ngram_reference(reference$counts[1, ], ngram_resource(),
    totals = reference$totals, preprocessing_id = "identity")
  q <- lexdiv_ngram_profile(x, partial)
  expect_identical(q$lookup$reference_status, c("listed", "not_listed", "listed", "not_listed"))
  expect_equal(q$summary$value_coverage[1:2], c(1/2, 1/3))
  expect_equal(q$summary$mean_frequency_per_million[1:2], rep(600000, 2))
  expect_true(all(is.na(q$lookup$reference_count[c(2, 4)])))
  expect_identical(partial$provenance$complete, FALSE)
  expect_identical(reference$provenance$complete, TRUE)
})

test_that("empty targets and empty reference populations have typed explicit outputs", {
  x <- ngram_extract(ngram_fixture()[FALSE, ])
  ref <- lexdiv_ngram_reference(x, ngram_resource())
  p <- lexdiv_ngram_profile(x, ref)
  full <- lexdiv_ngram_profile(ngram_extract(),
    lexdiv_ngram_reference(ngram_extract(), ngram_resource()))
  for (field in c("lookup", "summary", "documents"))
    expect_identical(p[[field]], full[[field]][FALSE, ])
  expect_true(is.character(x$occurrences$term3))
  expect_true(is.double(x$counts$count))
  out <- lexdiv_ngram_profile(ngram_extract(), ref)
  expect_true(all(out$lookup$reference_status == "not_observed"))
  expect_true(all(out$lookup$reference_count == 0))
  expect_true(all(is.na(out$lookup$frequency_per_million)))
  expect_true(all(out$summary$missing_reason == "zero_reference_opportunities"))
  expect_true(all(out$summary$value_coverage == 0))
  partial <- lexdiv_ngram_reference(x$counts, ngram_resource(),
    totals = ngram_extract()$totals, preprocessing_id = "identity")
  expect_true(all(lexdiv_ngram_profile(ngram_extract(), partial)$summary$missing_reason ==
    "no_available_reference_values"))
})

test_that("malformed token tables fail without sorting or guessing", {
  x <- ngram_fixture()
  for (values in list(c(1, 1, 3), c(2, 1, 3), c(0, 2, 3), c(1, NA, 3), c(1, 2.5, 3))) {
    y <- x; y$token_index[1:3] <- values
    expect_error(ngram_extract(y))
  }
  y <- x; y$segment_id[2] <- "different"
  expect_error(ngram_extract(y), "contiguous block")
  for (v in list(NA_character_, "", "two words", "a\tb")) {
    y <- x; y$term[1] <- v
    expect_error(ngram_extract(y))
  }
  y <- x; y$term <- factor(y$term)
  expect_error(ngram_extract(y), "plain")
  expect_error(ngram_extract(documents = "r1"), "include every")
  expect_error(ngram_extract(documents = c("r1", "r2", "r1")), "unique")
  for (n in list(integer(), c(2, 2), 1, 4, NA, "2")) expect_error(ngram_extract(n = n))
  expect_error(ngram_extract(id_col = c("a", "b")))
  expect_error(ngram_extract(position_col = "document_id"), "distinct")
  expect_error(lexdiv_ngrams(x, ""), "empty")
  names(x) <- c("id", "segment", "position", "word")
  adapted <- lexdiv_ngrams(x, "identity", id_col = "id", segment_col = "segment",
    position_col = "position", term_col = "word")
  expect_identical(adapted$occurrences, ngram_extract()$occurrences)
})

test_that("row limit is checked before occurrence tallying", {
  expect_equal(nrow(ngram_extract(max_ngrams = 7)$occurrences), 7)
  local_mocked_bindings(.lexng_tally = function(...) stop("TALLY_REACHED"), .package = "ldfreq")
  expect_error(ngram_extract(max_ngrams = 6), "exceed max_ngrams")
  expect_error(ngram_extract(max_ngrams = 7), "TALLY_REACHED")
})

test_that("reference tables validate counts, completeness and compatible declarations", {
  x <- ngram_extract(); resource <- ngram_resource()
  build <- function(counts = x$counts, totals = x$totals, complete = TRUE)
    lexdiv_ngram_reference(counts, resource, totals, "identity", complete)
  expect_error(build(x$counts[-1, ]), "count sums")
  expect_error(build(rbind(x$counts, x$counts[1, ])), "unique")
  for (v in list(0, -1, 1.5, NA, Inf)) {
    y <- x$counts; y$count[1] <- v
    expect_error(build(y))
  }
  y <- x$counts; y$document_count[1] <- 3
  expect_error(build(y), "document counts")
  y <- x$counts; y$term3[1] <- "unexpected"
  expect_error(build(y), "term3")
  y <- x$counts; y$term3[4] <- NA_character_
  expect_error(build(y), "trigram term3")
  y <- x$counts; y$term1[1] <- "a b"
  expect_error(build(y), "whitespace")
  y <- x$totals; y$opportunities[1] <- 4
  expect_error(build(totals = y, complete = FALSE), "count sums")
  expect_error(build(totals = x$totals[1, ]), "Invalid n")
  expect_error(build(complete = NA), "TRUE or FALSE")
  expect_error(lexdiv_ngram_reference(x, resource, totals = x$totals), "taken from")
  expect_error(lexdiv_ngram_reference(x, resource[-1]), "exact ordered fields")
  ref <- build()
  expect_error(lexdiv_ngram_profile(lexdiv_ngrams(ngram_fixture(), "other"), ref), "preprocessing_id")
  only2 <- lexdiv_ngram_reference(ngram_extract(n = 2), resource)
  expect_error(lexdiv_ngram_profile(x, only2), "every requested n")
})

test_that("term identities are Unicode-exact and cannot collide through separators", {
  terms <- c("a_b", "c", "a", "b_c", "a:1", "x|y", "é", "e\u0301")
  x <- data.frame(document_id = "a:b", segment_id = rep(1:4, each = 2),
    token_index = rep(1:2, 4), term = terms)
  x$segment_id <- as.character(x$segment_id)
  z <- ngram_extract(x, n = 2)
  expect_equal(nrow(z$counts), 4)
  ref <- lexdiv_ngram_reference(z, ngram_resource())
  y <- x; y$term[7:8] <- rev(y$term[7:8])
  p <- lexdiv_ngram_profile(ngram_extract(y, n = 2), ref)
  expect_identical(p$lookup$reference_status, c(rep("listed", 3), "not_observed"))
})

test_that("RDS, CSV imports, bounded printing and mutation checks retain evidence", {
  x <- ngram_extract(); ref <- lexdiv_ngram_reference(x, ngram_resource())
  p <- lexdiv_ngram_profile(x, ref)
  path <- tempfile(fileext = ".rds")
  for (item in list(x, ref, p)) {
    saveRDS(item, path)
    expect_identical(readRDS(path), item)
    expect_output(expect_invisible(print(item)), "contract 0.1.0")
  }
  utils::write.csv(ref$counts, path, row.names = FALSE, na = "")
  imported <- utils::read.csv(path, na.strings = "", colClasses = c(
    term1 = "character", term2 = "character", term3 = "character"))
  rebuilt <- lexdiv_ngram_reference(imported, ngram_resource(), ref$totals, "identity", TRUE)
  expect_identical(rebuilt$counts, ref$counts)
  expect_identical(lexdiv_ngram_profile(x, rebuilt)$summary, p$summary)
  changed <- x; changed$occurrences$term1[1] <- "changed"
  expect_error(lexdiv_ngram_profile(changed, ref), "unmodified")
  changed <- ref; changed$totals$opportunities[1] <- 500
  expect_error(lexdiv_ngram_profile(x, changed), "unmodified")
  unlink(path)
})

test_that("generated extractions agree with an independent nested-loop oracle", {
  set.seed(517)
  for (iteration in seq_len(25)) {
    docs <- rep(c("d1", "d2"), each = 10)
    seg <- rep(rep(c("s1", "s2"), each = 5), 2)
    pos <- rep(1:5, 4)
    d <- data.frame(document_id = docs, segment_id = seg, token_index = pos,
      term = sample(c("a", "b", "a_b", "c:d", "é"), 20, replace = TRUE))
    d <- d[sample(c(TRUE, FALSE), 20, replace = TRUE, prob = c(.8, .2)), ]
    rownames(d) <- NULL
    z <- ngram_extract(d, documents = c("d1", "d2", "empty"))
    expected <- list()
    for (k in 2:3) for (i in seq_len(nrow(d))) {
      take <- i + seq.int(0L, k - 1L)
      if (max(take) > nrow(d)) next
      piece <- d[take, ]
      if (length(unique(piece$document_id)) != 1L ||
          length(unique(piece$segment_id)) != 1L || any(diff(piece$token_index) != 1)) next
      expected[[length(expected) + 1L]] <- data.frame(document_id = piece$document_id[1],
        segment_id = piece$segment_id[1], n = as.integer(k),
        start_index = as.double(piece$token_index[1]), end_index = as.double(piece$token_index[k]),
        term1 = piece$term[1], term2 = piece$term[2],
        term3 = if (k == 3) piece$term[3] else NA_character_)
    }
    expected <- if (length(expected)) do.call(rbind, expected) else z$occurrences[FALSE, ]
    rownames(expected) <- NULL
    expect_equal(z$occurrences, expected, ignore_attr = TRUE)
    for (j in seq_len(nrow(z$counts))) {
      same <- expected$n == z$counts$n[j] & expected$term1 == z$counts$term1[j] &
        expected$term2 == z$counts$term2[j]
      if (z$counts$n[j] == 3) same <- same & !is.na(expected$term3) & expected$term3 == z$counts$term3[j]
      expect_equal(z$counts$count[j], sum(same))
      expect_equal(z$counts$document_count[j], length(unique(expected$document_id[same])))
    }
  }
})

test_that("installed n-gram contract fixes live table boundaries and storage", {
  contract <- jsonlite::read_json(system.file("spec", "adjacent-ngram-contract.json",
    package = "ldfreq"))
  x <- ngram_extract()
  ref <- lexdiv_ngram_reference(x, ngram_resource())
  profile <- lexdiv_ngram_profile(x, ref)
  for (kind in c("extraction", "reference", "profile")) {
    object <- switch(kind, extraction = x, reference = ref, profile = profile)
    specification <- contract[[kind]]
    expect_identical(class(object), specification$class)
    expect_identical(object$provenance$contract_id, contract$contract_id)
    expect_identical(object$provenance$contract_version, contract$contract_version)
    expect_identical(names(object), unlist(specification$components))
    for (table in setdiff(names(object), "provenance"))
      expect_identical(names(object[[table]]), unlist(specification[[paste0(table, "_columns")]]))
  }
  expect_identical(names(ref$provenance$resource), unlist(contract$reference$resource_fields))
  expect_type(x$occurrences$n, "integer")
  expect_type(x$occurrences$start_index, "double")
  expect_type(profile$summary$eligible_items, "double")
  expect_false(profile$provenance$runtime_network_access)
})
