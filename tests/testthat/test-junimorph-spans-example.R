morph_span_recipe <- function() {
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "junimorph-spans.R", package = "ldfreq", mustWork = TRUE), e)
  e
}

morph_span_fixture <- function(text, parts, rows, e = morph_span_recipe()) {
  file <- tempfile(); on.exit(unlink(file))
  writeLines(rows, file, useBytes = TRUE)
  ref <- e$read_junimorph(file, list(resource_id = "authored", resource_version = "1",
    source_reference = "authored regression fixture", data_license = "MIT"))
  s <- data.frame(document_id = c(rep("d", length(text)), "empty"),
    segment_id = c(as.character(seq_along(text)), "1"), text = c(text, ""))
  t <- data.frame(document_id = "d", segment_id = rep(as.character(seq_along(parts)), lengths(parts)),
    token_index = sequence(lengths(parts)), surface = unlist(parts, use.names = FALSE))
  x <- lexdiv_import_annotations(t, s, list(language = "ja", analyzer = "authored",
    analyzer_version = "1", dictionary = "none", dictionary_version = "1",
    unit = "authored", normalization = "none"))
  list(e = e, ref = ref, x = x)
}

test_that("multi-token reviews preserve source, ambiguity and conditional counts", {
  e <- morph_span_recipe()
  sys.source(system.file("examples", "junimorph-spans-demo.R", package = "ldfreq", mustWork = TRUE), e)
  x <- e$junimorph_spans_example
  o <- x$reviewed$occurrences
  expect_identical(o$form, c("食べられる", "食べられる", "食べます", "開ける", "ぷにょる"))
  expect_equal(o$start, c(6, 8, 4, 3, 1))
  expect_equal(o$end, c(10, 12, 7, 5, 4))
  expect_equal(o$token_count, c(2, 2, 2, 1, 1))
  expect_equal(o$candidate_count, c(3, 3, 1, 2, 0))
  expect_identical(o$status, c("selected", "unresolved", "selected", "unreviewed", "no_candidates"))
  expect_identical(x$reviewed$source, x$initial$source)
  expect_identical(x$reviewed$source, x$annotations)
  expect_equal(x$counts$common_form_V, 2)
  expect_equal(x$counts$common_lemma_label_V, 1)
  expect_true(is.na(x$counts$full_target_lemma_V))
  expect_equal(x$counts$source_N_before, x$counts$source_N_after)
  expect_equal(x$reviewed$documents$selected, c(2, 0))
  expect_equal(x$reviewed$documents$selection_coverage[1], 2/5)
  expect_true(is.na(x$reviewed$documents$selection_coverage[2]))
  expect_equal(x$reviewed$terms$exact_spans[x$reviewed$terms$form == "未出現"], 0)
  path <- tempfile(); on.exit(unlink(path)); saveRDS(x, path)
  restored <- readRDS(path)
  expect_identical(restored, x)
  again <- e$review_morphology_spans(restored$annotations, restored$reference,
    restored$reviewed$terms$form, restored$reviewed$decisions)
  expect_identical(again, x$reviewed)
})

test_that("overlap, token mismatches and exact Unicode are explicit", {
  # Declare scalar values explicitly instead of mixing a literal non-BMP
  # character and Unicode escapes in the same platform-parsed string.
  emoji <- intToUtf8(0x1f600)
  decomposed <- intToUtf8(c(0x304b, 0x3099))
  f <- morph_span_fixture(c("あああ", paste0(emoji, decomposed, " が"), "あ あ", "あ", "あ"),
    list(c("あ", "ああ"), c(emoji, decomposed, "が"), c("あ", "あ"), "あ", "あ"),
    c("あ\tあ\tAUTHORED", "あ\tああ\tAUTHORED", "か\u3099\tか\u3099\tAUTHORED", "が\tが\tAUTHORED"))
  z <- f$e$review_morphology_spans(f$x, f$ref, window = 0)
  o <- z$occurrences[z$occurrences$segment_id == "1", ]
  expect_equal(o$start, c(1, 1, 2, 2, 3))
  expect_equal(o$end, c(1, 2, 2, 3, 3))
  expect_identical(o$boundary_status, c("token_aligned", "boundary_mismatch", "boundary_mismatch",
    "token_aligned", "boundary_mismatch"))
  expect_equal(o$overlap_n, c(1, 3, 2, 3, 1))
  expect_true(all(z$occurrences$pre == "" & z$occurrences$post == ""))
  u <- z$occurrences[z$occurrences$segment_id == "2", ]
  expect_equal(u$start, c(2, 5))
  expect_equal(u$end, c(3, 5))
  expect_identical(u$form, c("か\u3099", "が"))
  expect_equal(sum(z$occurrences$form == "ああ"), 2) # No whitespace/segment crossing.
  expect_false(anyDuplicated(z$occurrences$occurrence_id) > 0)
  d <- z$occurrences[2, c("review_id", "occurrence_id")]
  d$status <- "selected"; d$candidate_id <- "row-2"; d$reviewer <- "test"; d$reason <- "fixture"
  expect_error(f$e$review_morphology_spans(f$x, f$ref, decisions = d), "boundaries")
  # With all single-character boundaries, both nested spans can be reviewed,
  # but their overlap remains explicit instead of silently choosing the longest.
  f2 <- morph_span_fixture("ああ", list(c("あ", "あ")), c("あ\tあ\tX", "あ\tああ\tY"))
  a <- f2$e$review_morphology_spans(f2$x, f2$ref)
  d <- a$occurrences[1:2, c("review_id", "occurrence_id")]
  d$status <- "selected"; d$candidate_id <- c("row-1", "row-2"); d$reviewer <- "test"; d$reason <- "fixture"
  b <- f2$e$review_morphology_spans(f2$x, f2$ref, decisions = d)
  expect_equal(b$documents$selected_overlap_spans, c(2, 0))
  expect_equal(b$occurrences$selected_overlap_n, c(1, 1, 0))
})

test_that("reference rows and decisions cannot be silently substituted", {
  f <- morph_span_fixture("ああ", list(c("あ", "あ")), c("あ\tあ\tX", "あ\tあ\tX", "あ\tああ\tY"))
  expect_equal(nrow(f$ref$records), 3)
  expect_identical(f$ref$records$source_row, 1:3)
  a <- f$e$review_morphology_spans(f$x, f$ref)
  d <- a$occurrences[1, c("review_id", "occurrence_id")]
  d$status <- "selected"; d$candidate_id <- "row-3"; d$reviewer <- "test"; d$reason <- "fixture"
  expect_error(f$e$review_morphology_spans(f$x, f$ref, decisions = d), "does not belong")
  d$candidate_id <- "row-1"
  expect_error(f$e$review_morphology_spans(f$x, f$ref, decisions = rbind(d, d)), "unique")
  d$status <- "unresolved"
  expect_error(f$e$review_morphology_spans(f$x, f$ref, decisions = d), "NA candidate_id")
  d$status <- "selected"; d$review_id <- "stale"
  expect_error(f$e$review_morphology_spans(f$x, f$ref, decisions = d), "review_id differs")
  d$review_id <- a$provenance$review_id
  new_segmentation <- morph_span_fixture("ああ", list("ああ"), c("あ\tあ\tX", "あ\tあ\tX", "あ\tああ\tY"))
  expect_error(f$e$review_morphology_spans(new_segmentation$x, f$ref, decisions = d), "review_id differs")
  new_reference <- morph_span_fixture("ああ", list(c("あ", "あ")), c("あ\tあ\tZ", "あ\tあ\tX", "あ\tああ\tY"))
  expect_error(f$e$review_morphology_spans(f$x, new_reference$ref, decisions = d), "review_id differs")
  expect_error(f$e$review_morphology_spans(f$x, f$ref, targets = "あ", decisions = d), "review_id differs")
  d$reason <- " "
  expect_error(f$e$review_morphology_spans(f$x, f$ref, decisions = d), "nonblank")
  changed <- f$ref; changed$records$features[1] <- "changed"
  expect_error(f$e$review_morphology_spans(f$x, changed), "unmodified")
  changed <- f$x; changed$tokens$surface[1] <- "い"
  expect_error(f$e$review_morphology_spans(changed, f$ref), "align")
  expect_error(f$e$review_morphology_spans(f$x, f$ref, window = -1), "window")
  expect_error(f$e$review_morphology_spans(f$x, f$ref, targets = "あ あ"), "targets")
  empty <- f$e$review_morphology_spans(f$x, f$ref, targets = "未出現")
  expect_equal(nrow(empty$occurrences), 0)
  expect_equal(empty$documents$exact_spans, c(0, 0))
  path <- tempfile(); on.exit(unlink(path)); writeLines("a\tb", path)
  expect_error(f$e$read_junimorph(path, f$ref$resource), "three tab-separated")
  writeLines("a\tb c\tX", path)
  expect_error(f$e$read_junimorph(path, f$ref$resource), "whitespace")
  writeBin(as.raw(c(0xff, 0x09, 0x61, 0x09, 0x62)), path)
  expect_error(f$e$read_junimorph(path, f$ref$resource), "UTF-8")
})
