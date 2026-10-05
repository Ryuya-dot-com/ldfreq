sensitivity_example <- function() {
  env <- new.env(parent = globalenv())
  invisible(capture.output(sys.source(system.file("examples", "annotation-sensitivity-demo.R",
    package = "ldfreq", mustWork = TRUE), envir = env)))
  env
}

test_that("the installed sensitivity example links authored changes to hand-counted effects", {
  e <- sensitivity_example(); x <- e$result
  expect_equal(x$audit$documents$changed_tokens, c(2, 1, 1, 0, 0, 0))
  expect_identical(x$changes$keyword, c("cats", "saw", "can", "fly"))
  expect_identical(x$changes$pre[1], "")
  expect_identical(x$changes$post[1], " saw cat.")
  d <- subset(x$differences, document_id == "lemma" & condition_id == "lemma_all")
  expect_equal(d$N_before, c(3, 3))
  expect_equal(d$V_after, c(2, 2))
  expect_equal(d$value_before, c(1, 1))
  expect_equal(d$value_after, c(2/3, 2/3))
  expect_equal(d$delta, c(-1/3, -1/3))
  expect_equal(d$absolute_delta, c(1/3, 1/3))
  pos <- subset(x$differences, document_id == "pos" & condition_id == "lemma_content")
  expect_equal(pos$N_before, c(3, 3))
  expect_equal(pos$N_after, c(2, 2))
  expect_true(is.na(pos$delta[pos$metric_id == "mattr"]))
  expect_identical(pos$difference_status[pos$metric_id == "mattr"], "not_computable")
  expect_false(is.na(pos$missing_reason_after[pos$metric_id == "mattr"]))
  s <- subset(x$differences, condition_id == "surface_all" & difference_status == "paired")
  expect_true(all(s$delta == 0))
  expect_equal(nrow(x$differences), 36)
  expect_equal(nrow(x$metrics), 72)
})

test_that("annotation selection and reference matching retain different denominators", {
  e <- sensitivity_example(); x <- e$result
  c <- subset(x$coverage, document_id == "lemma" & condition_id == "lemma_all")
  expect_equal(c$source_tokens, c(3, 3))
  expect_equal(c$selection_coverage, c(1, 1))
  expect_equal(c$nj8_coverage_of_eligible, c(2/3, 1))
  c <- subset(x$coverage, document_id == "missing" & condition_id == "lemma_content")
  expect_equal(c$selection_coverage, c(.5, .5))
  expect_equal(c$nj8_coverage_of_eligible, c(1, 1))
  expect_equal(c$matched_fraction_of_source, c(.5, .5))
  t <- subset(x$tokens, document_id == "missing" & condition_id == "lemma_content" & token_index == 2)
  expect_identical(t$exclusion_reason, c("missing_lemma", "missing_upos"))
  expect_true(all(is.na(t$nj8_matched)))
  expect_equal(subset(x$tokens, document_id == "pos" & condition_id == "lemma_content" &
    version == "after" & eligible)$token_index, c(3, 5))
  expect_true(all(subset(x$coverage, document_id == "unknown")$nj8_coverage_of_eligible == 0))
  excluded <- subset(x$coverage, document_id == "excluded" & condition_id == "lemma_content")
  expect_true(all(is.na(excluded$nj8_coverage_of_eligible)))
  expect_equal(excluded$matched_fraction_of_source, c(0, 0))
  empty <- subset(x$coverage, document_id == "empty")
  expect_true(all(is.na(empty$selection_coverage) & is.na(empty$matched_fraction_of_source)))
  expect_false(any(x$tokens$document_id == "empty"))
  expect_true(all(subset(x$differences, document_id == "empty")$difference_status == "not_computable"))
})

test_that("saved inputs replay and document pairing uses IDs", {
  e <- sensitivity_example(); x <- e$result
  expect_identical(e$annotation_sensitivity(e$before, rev(e$after), rev(e$texts)), x)
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(x, path); saved <- readRDS(path)
  expect_identical(do.call(e$annotation_sensitivity,
    c(saved$inputs, list(window_length = saved$settings$window_length))), x)
  unchanged <- e$annotation_sensitivity(e$before, e$before, e$texts)
  expect_equal(nrow(unchanged$changes), 0)
  expect_identical(names(unchanged$changes), names(x$changes))
  expect_true(all(unchanged$differences$delta[unchanged$differences$difference_status == "paired"] == 0))
  expect_identical(e$before, x$inputs$before)
  expect_identical(e$after, x$inputs$after)
})

test_that("source context is checked in Unicode coordinates and transformed text is rejected", {
  e <- sensitivity_example()
  text <- "\U0001f600 cafe\u0301 cats."
  annotate <- function(x, lemmas) lexdiv_lemmatize(x, lemmas = lemmas,
    upos = c("NOUN", "NOUN"), backend_id = "authored", backend_version = "1",
    upos_backend_id = "authored", upos_backend_version = "1")
  raw <- lexdiv_tokenize(text, normalization = "none", case = "preserve")
  a <- list(unicode = annotate(raw, c("cafe\u0301", "cats")))
  b <- list(unicode = annotate(raw, c("cafe", "cat")))
  x <- e$annotation_sensitivity(a, b, c(unicode = text))
  expect_equal(x$changes$start, c(3, 9))
  expect_identical(x$changes$keyword, c("cafe\u0301", "cats"))
  expect_identical(x$changes$pre[1], "\U0001f600 ")
  normalized <- list(unicode = annotate(lexdiv_tokenize(text, normalization = "NFC"), c("cafe", "cat")))
  expect_error(e$annotation_sensitivity(normalized, normalized, c(unicode = text)), "processed text")
  wrong <- e$texts; wrong[1] <- "cats saw cat!"
  expect_error(e$annotation_sensitivity(e$before, e$after, wrong), "processed text")
  expect_error(e$annotation_sensitivity(e$before, e$after, unname(e$texts)), "batch IDs")
  expect_error(e$annotation_sensitivity(e$before, e$after, e$texts[-1]), "batch IDs")
  expect_error(e$annotation_sensitivity(e$before, e$after, e$texts, 0), "window_length")
  expect_error(e$annotation_sensitivity(e$before$lemma, e$after$lemma, e$texts[1]), "named batches")
})

test_that("lemma edits leave exact surface-phrase matches unchanged", {
  skip_if_not_installed("quanteda", "4.5.0")
  e <- sensitivity_example()
  search <- function(x) quanteda::kwic(quanteda::as.tokens(list(
    lemma = x$lemma$tokens$surface)), pattern = quanteda::phrase("saw cat"),
    valuetype = "fixed", case_insensitive = FALSE)
  a <- search(e$before); b <- search(e$after)
  expect_identical(a, b)
  expect_equal(a$from, 2)
  expect_equal(a$to, 3)
})
