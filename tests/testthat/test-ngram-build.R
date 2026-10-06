build_resource <- function() {
  list(resource_id = "authored_chunks", resource_version = "1",
    creator = "Example author", source_reference = "Authored sequences",
    data_license = "Project-authored example", transformation_id = "none",
    lookup_unit = "adjacent_surface_ngram", resource_key_normalization_id = "identity")
}

build_tokens <- function(id, terms, index = seq_along(terms)) {
  data.frame(document_id = rep(id, length(terms)), segment_id = rep("s", length(terms)),
    token_index = index, term = terms, stringsAsFactors = FALSE)
}

test_that("whole-document chunks agree with hand counts and bulk profiles", {
  tables <- list(a = build_tokens("d1", c("a", "b", "a", "b")),
    b = build_tokens("d2", c("a", "b", "c", "ignored"), c(1, 2, 3, 5)),
    empty = build_tokens("empty", character()))
  calls <- character()
  read <- function(id) {
    calls <<- c(calls, id)
    lexdiv_ngrams(tables[[id]], "same", n = if (id == "b") 3:2 else 2:3,
      documents = if (id == "empty") "empty" else unique(tables[[id]]$document_id))
  }
  x <- lexdiv_ngram_reference_build(names(tables), read, build_resource())
  expect_identical(calls, names(tables))
  r <- x$reference
  bi <- r$counts[r$counts$n == 2, ]
  tri <- r$counts[r$counts$n == 3, ]
  expect_identical(paste(bi$term1, bi$term2), c("a b", "b a", "b c"))
  expect_equal(bi$count, c(3, 1, 1))
  expect_equal(bi$document_count, c(2, 1, 1))
  expect_identical(paste(tri$term1, tri$term2, tri$term3), c("a b a", "b a b", "a b c"))
  expect_equal(tri$count, c(1, 1, 1))
  expect_equal(tri$document_count, c(1, 1, 1))
  expect_equal(r$totals$opportunities, c(5, 3))
  expect_equal(r$totals$documents, c(3, 3))
  expect_true(r$provenance$complete)
  expect_identical(x$documents$document_id, c("d1", "d2", "empty"))
  expect_identical(x$documents$source_id, names(tables))
  expect_equal(x$sources$opportunities, c(3, 2, 1, 2, 0, 0))
  expect_true(all(nchar(x$sources$extraction_sha256) == 64))
  expect_false("occurrences" %in% names(x))
  bulk <- lexdiv_ngrams(do.call(rbind, tables), "same", documents = c("d1", "d2", "empty"))
  direct <- lexdiv_ngram_reference(bulk, build_resource())
  target <- lexdiv_ngrams(build_tokens("target", c("a", "b", "a", "new")), "same")
  for (field in c("lookup", "summary", "documents"))
    expect_identical(lexdiv_ngram_profile(target, r)[[field]],
      lexdiv_ngram_profile(target, direct)[[field]])
  p <- tempfile(fileext = ".rds"); on.exit(unlink(p))
  saveRDS(x, p); expect_identical(readRDS(p), x)
  expect_identical(lexdiv_ngram_profile(target, readRDS(p)$reference)$lookup,
    lexdiv_ngram_profile(target, r)$lookup)
})

test_that("empty and multi-document chunks retain exact roster denominators", {
  a <- build_tokens("a", c("one", "two"))
  b <- build_tokens("b", c("one", "two"))
  read <- function(id) lexdiv_ngrams(if (id == "both") rbind(a, b) else a[FALSE, ],
    "same", documents = switch(id, both = c("a", "b"), none = character(), empty = "empty"))
  x <- lexdiv_ngram_reference_build(c("none", "both", "empty"), read, build_resource())
  expect_equal(x$reference$counts$count, 2)
  expect_equal(x$reference$counts$document_count, 2)
  expect_equal(x$reference$totals$documents, c(3, 3))
  expect_equal(x$reference$totals$opportunities, c(2, 0))
  expect_identical(x$documents$document_id, c("a", "b", "empty"))
  z <- lexdiv_ngram_reference_build(c("none", "empty"), read, build_resource())
  expect_identical(z$reference$counts, x$reference$counts[FALSE, ])
  expect_equal(z$reference$totals$documents, c(1, 1))
  expect_equal(z$reference$totals$opportunities, c(0, 0))
  expect_identical(z$documents$document_id, "empty")
})

test_that("component keys retain Unicode and literal separator distinctions", {
  terms <- list(c("a_b", "c"), c("a", "b_c"), c("e\u0301", "x"), c("\u00e9", "x"))
  read <- function(id) lexdiv_ngrams(build_tokens(id, terms[[as.integer(id)]]), "same", n = 2)
  x <- lexdiv_ngram_reference_build(as.character(1:4), read, build_resource())
  expect_equal(nrow(x$reference$counts), 4)
  expect_identical(x$reference$counts$term1, vapply(terms, `[[`, character(1), 1))
  expect_equal(x$reference$counts$count, rep(1, 4))
})

test_that("invalid chunks fail before reading later sources", {
  calls <- character()
  read <- function(id) {
    calls <<- c(calls, id)
    lexdiv_ngrams(build_tokens(id, c("a", id)), "same", n = 2)
  }
  expect_error(lexdiv_ngram_reference_build(c("one", "two", "three"), read,
    build_resource(), max_types = 1), "max_types")
  expect_identical(calls, c("one", "two"))
  expect_error(lexdiv_ngram_reference_build("one", function(id)
    lexdiv_ngrams(build_tokens(id, c("a", "b", "c")), "same"),
    build_resource(), max_types = 1), "max_types")
  for (bound in list(0, NA_real_, 1.5, "1"))
    expect_error(lexdiv_ngram_reference_build("a", read, build_resource(), bound), "max_types")
  expect_error(lexdiv_ngram_reference_build(character(), read, build_resource()), "empty")
  expect_error(lexdiv_ngram_reference_build(c("a", "a"), read, build_resource()), "unique")
  expect_error(lexdiv_ngram_reference_build("a", 1, build_resource()), "function")
  expect_error(lexdiv_ngram_reference_build("broken", function(id) stop("fixture failure"),
    build_resource()), "source 'broken': fixture failure")
  expect_error(lexdiv_ngram_reference_build("invalid", function(id) list(),
    build_resource()), "source 'invalid'")
  x <- read("a"); x$counts$count <- 100
  expect_error(lexdiv_ngram_reference_build("modified", function(id) x,
    build_resource()), "source 'modified'")
  same <- function(id) lexdiv_ngrams(build_tokens("duplicate", c("a", "b")), "same")
  expect_error(lexdiv_ngram_reference_build(c("a", "b"), same, build_resource()), "more than one")
  empty <- function(id) lexdiv_ngrams(build_tokens("unused", character()), "same", documents = "empty")
  expect_error(lexdiv_ngram_reference_build(c("a", "b"), empty, build_resource()), "more than one")
  varying <- function(id) lexdiv_ngrams(build_tokens(id, c("a", "b")), id)
  expect_error(lexdiv_ngram_reference_build(c("a", "b"), varying, build_resource()), "agree")
  n <- function(id) lexdiv_ngrams(build_tokens(id, c("a", "b")), "same", n = if (id == "a") 2 else 3)
  expect_error(lexdiv_ngram_reference_build(c("a", "b"), n, build_resource()), "agree")
})
