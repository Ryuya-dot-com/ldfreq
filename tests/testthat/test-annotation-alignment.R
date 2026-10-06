alignment_input <- function(text, words, labels = rep("NOUN", length(words)), id = "d") {
  metadata <- list(language = "authored", analyzer = "authored", analyzer_version = "1",
    dictionary = "none", dictionary_version = "none", unit = "authored", normalization = "none")
  data <- data.frame(document_id = rep(id, length(words)), segment_id = rep("s", length(words)),
    token_index = seq_along(words), surface = words, upos = labels)
  lexdiv_import_annotations(data, data.frame(document_id = id, segment_id = "s", text = text), metadata)
}

alignment_policy <- function() list(column = "upos", labels = c("NOUN", "VERB"),
  reference_info = list(reference_id = "authored", annotation_protocol = "authored contrast",
    label_scheme = "authored inventory", model_exposure = "shown", evaluation_role = "development"))

test_that("split, merge and complex components preserve IDs and original KWIC", {
  ref <- alignment_input("can't re-read.", c("can't", "re-read", "."))
  pred <- alignment_input("can't re-read.", c("ca", "n't", "re", "-", "read", "."))
  x <- lexdiv_align_annotations(pred, ref, context_chars = 2)
  expect_identical(x$groups$relation, c("split", "split", "exact"))
  expect_equal(x$groups$reference_n, c(1, 1, 1))
  expect_equal(x$groups$predicted_n, c(2, 3, 1))
  expect_identical(x$groups$keyword, c("can't", "re-read", "."))
  expect_identical(x$groups$pre, c("", "t ", "ad"))
  expect_identical(x$groups$post, c(" r", ".", ""))
  expect_equal(nrow(x$members), 9)
  expect_equal(x$summary$reference_n, c(3, 2))
  expect_equal(x$summary$predicted_n, c(6, 5))
  expect_equal(x$summary$matched, c(1, 2))
  expect_equal(x$summary$precision, c(1/6, 2/5))
  expect_equal(x$summary$recall, c(1/3, 1))
  expect_equal(x$summary$f1, c(2/9, 4/7))
  expect_null(x$annotation_evaluation)
  expect_identical(x$predicted, pred)
  expect_identical(x$reference, ref)
  reverse <- lexdiv_align_annotations(ref, pred)
  expect_identical(reverse$groups$relation, c("merge", "merge", "exact"))
  expect_equal(reverse$summary$precision, x$summary$recall)
  complex <- lexdiv_align_annotations(alignment_input("ABC", c("A", "BC")),
    alignment_input("ABC", c("AB", "C")))
  expect_identical(complex$groups$relation, "complex")
  expect_equal(complex$summary$matched, c(0, 0))
  expect_equal(complex$summary$f1, c(0, 0))
})

test_that("whitespace ownership, Unicode codepoints and segment edges are explicit", {
  ref <- alignment_input("a b", c("a", " ", "b"))
  pred <- alignment_input("a b", c("a", "b"))
  x <- lexdiv_align_annotations(pred, ref)
  expect_identical(x$groups$relation, c("exact", "reference_only", "exact"))
  expect_equal(x$boundaries$left_end, c(1, 1, 2))
  expect_equal(x$boundaries$right_start, c(2, 3, 3))
  expect_equal(x$summary$matched, c(2, 0))
  expect_identical(lexdiv_align_annotations(ref, pred)$groups$relation,
    c("exact", "prediction_only", "exact"))
  x <- lexdiv_align_annotations(pred, alignment_input("a b", c("a", " b")))
  expect_identical(x$groups$relation, c("exact", "changed_span"))
  expect_equal(x$summary$matched, c(1, 0))
  # Construct non-BMP and combining characters without mixed literal/escape
  # parsing; also verify the intended source before testing alignment.
  codepoints <- as.integer(c(0x732b, 0x65, 0x301, 0x1f600, 0x732b, 0x3002))
  source <- intToUtf8(codepoints)
  characters <- intToUtf8(codepoints, multiple = TRUE)
  reference_words <- c(characters[1], paste0(characters[2:3], collapse = ""), characters[4:6])
  expect_identical(utf8ToInt(source), codepoints)
  expect_identical(paste0(reference_words, collapse = ""), source)
  ref <- alignment_input(source, reference_words)
  pred <- alignment_input(source, characters)
  x <- lexdiv_align_annotations(pred, ref, context_chars = 1)
  expect_equal(x$groups$start, c(1, 2, 4, 5, 6))
  expect_identical(x$groups$keyword, ref$tokens$surface)
  expect_identical(x$groups$pre, c("", characters[c(1, 3, 4, 5)]))
  expect_identical(x$groups$relation, c("exact", "split", "exact", "exact", "exact"))
  single <- alignment_input(characters[1], characters[1])
  x <- lexdiv_align_annotations(single, single, context_chars = 0)
  expect_equal(x$summary$matched, c(1, 0))
  expect_true(is.na(x$summary$f1[2]))
  expect_equal(nrow(x$boundaries), 0)
  expect_identical(x$groups$pre, "")
  expect_identical(x$groups$post, "")
})

test_that("label scoring is conditional and keeps both shifted token IDs", {
  ref <- alignment_input("ab c d e f", c("ab", "c", "d", "e", "f"),
    c("NOUN", "NOUN", "NOUN", NA, "VERB"))
  pred <- alignment_input("ab c d e f", c("a", "b", "c", "d", "e", "f"),
    c("NOUN", "NOUN", "NOUN", NA, "NOUN", "NOUN"))
  x <- do.call(lexdiv_align_annotations, c(list(predicted = pred, reference = ref), alignment_policy()))
  y <- x$annotation_evaluation
  expect_equal(x$summary$recall[1], 4/5)
  expect_equal(x$summary$precision[1], 4/6)
  expect_equal(y$pairs$reference_token_index, 2:5)
  expect_equal(y$pairs$predicted_token_index, 3:6)
  expect_identical(y$pairs$outcome,
    c("agreement", "reference_only", "prediction_only", "disagreement"))
  expect_equal(y$summary$tokens, 4)
  expect_equal(y$summary$agreement_among_paired, .5)
  expect_equal(y$labels$reference_n, c(2, 1))
  expect_equal(y$labels$tp, c(1, 0))
  expect_equal(y$labels$fp, c(1, 0))
  expect_equal(y$labels$fn, c(1, 1))
  expect_equal(y$labels$missing_predictions, c(1, 0))
  expect_equal(y$labels$predictions_without_reference, c(1, 0))
  expect_identical(x$members$label_eligible, x$members$relation == "exact")
  expect_identical(x$provenance$label_policy, alignment_policy())
})

test_that("empty inputs keep rosters and undefined denominators", {
  for (text in c("", " \n ")) {
    input <- alignment_input(text, character())
    x <- do.call(lexdiv_align_annotations,
      c(list(predicted = input, reference = input), alignment_policy()))
    expect_equal(nrow(x$groups), 0)
    expect_equal(nrow(x$members), 0)
    expect_equal(x$summary$reference_n, c(0, 0))
    expect_true(all(is.na(x$summary$precision)))
    expect_true(all(is.na(x$summary$recall)))
    expect_true(all(is.na(x$summary$f1)))
    expect_identical(x$documents$document_id, c("d", "d"))
    expect_equal(x$annotation_evaluation$documents$tokens, 0)
  }
  ref <- alignment_input("ab", "ab")
  pred <- alignment_input("ab", c("a", "b"))
  x <- do.call(lexdiv_align_annotations, c(list(predicted = pred, reference = ref), alignment_policy()))
  expect_equal(x$annotation_evaluation$summary$tokens, 0)
  expect_true(is.na(x$annotation_evaluation$summary$agreement_among_paired))
})

test_that("invalid inputs and mismatched sources fail before alignment", {
  ref <- alignment_input("a b", c("a", "b"))
  bad <- ref
  bad$tokens$upos[1] <- "VERB"
  expect_error(lexdiv_align_annotations(bad, ref), "has changed")
  expect_error(lexdiv_align_annotations(ref$tokens, ref), "plain list")
  expect_error(lexdiv_align_annotations(alignment_input("a  b", c("a", "b")), ref), "original text")
  expect_error(lexdiv_align_annotations(alignment_input("a b", c("a", "b"), id = "other"), ref), "segment IDs")
  expect_error(lexdiv_align_annotations(ref, ref, max_tokens = 1), "max_tokens")
  for (context in list(-1, .5, NA, "1", c(1, 2), structure(1, names = "x")))
    expect_error(lexdiv_align_annotations(ref, ref, context_chars = context), "context_chars")
  expect_error(lexdiv_align_annotations(ref, ref, column = "upos"), "together")
  args <- c(list(predicted = ref, reference = ref), alignment_policy())
  args$labels <- "VERB"
  expect_error(do.call(lexdiv_align_annotations, args), "outside labels")
  args$labels <- c("NOUN", "NOUN")
  expect_error(do.call(lexdiv_align_annotations, args), "unique")
})

test_that("overlap sweep agrees with an independent graph traversal", {
  # Every pair of partitions of four codepoints; no geometry-based shortcut
  # in the oracle: form all overlaps, then traverse the adjacency graph.
  words <- lapply(0:7, function(mask) {
    cuts <- which(as.logical(intToBits(mask)[1:3]))
    substring("abcd", c(1L, cuts + 1L), c(cuts, 4L))
  })
  correct <- logical()
  for (a in words) for (b in words) {
    x <- lexdiv_align_annotations(alignment_input("abcd", b), alignment_input("abcd", a))
    m <- x$members
    adjacency <- outer(m$start, m$end, "<=") & outer(m$end, m$start, ">=")
    component <- integer(nrow(m))
    for (i in seq_len(nrow(m))) if (!component[i]) {
      reached <- i
      repeat {
        expanded <- which(colSums(adjacency[reached, , drop = FALSE]) > 0)
        if (identical(expanded, reached)) break
        reached <- expanded
      }
      component[reached] <- i
    }
    correct <- c(correct, identical(outer(component, component, "=="),
      outer(m$alignment_id, m$alignment_id, "==")))
  }
  expect_true(all(correct))
})

test_that("compound IDs and reordered segments preserve reference order", {
  input <- alignment_input("a", "a")
  segments <- data.frame(document_id = c("a:b", "a:b", "a", "empty"),
    segment_id = c("c", "c2", "b:c", "c"), text = c("abc", "猫。", "abc", ""))
  data <- data.frame(document_id = rep(segments$document_id[1:3], c(2, 2, 2)),
    segment_id = rep(segments$segment_id[1:3], c(2, 2, 2)), token_index = rep(1:2, 3),
    surface = c("ab", "c", "猫", "。", "a", "bc"))
  ref <- lexdiv_import_annotations(data, segments, input$provenance$annotation)
  pred <- lexdiv_import_annotations(data[c(5:6, 3:4, 1:2), ], segments[c(3, 2, 1, 4), ],
    input$provenance$annotation)
  x <- lexdiv_align_annotations(pred, ref)
  y <- lexdiv_align_annotations(ref, ref)
  for (table in c("summary", "documents", "groups", "members", "boundaries", "review_queue"))
    expect_identical(x[[table]], y[[table]])
  expect_equal(x$summary$reference_n, c(6, 3))
  expect_equal(x$summary$matched, c(6, 3))
  expect_identical(x$documents$document_id, rep(c("a:b", "a", "empty"), each = 2))
  # Same document text is insufficient if the segment roster differs.
  segments$segment_id[2] <- "other"
  data$segment_id[3:4] <- "other"
  changed <- lexdiv_import_annotations(data, segments, input$provenance$annotation)
  expect_error(lexdiv_align_annotations(changed, ref), "segment IDs")
})

test_that("installed example links whole-document metrics and saved replay", {
  env <- new.env(parent = baseenv())
  sys.source(system.file("examples", "annotation-alignment.R", package = "ldfreq", mustWork = TRUE), env)
  x <- env$annotation_alignment_example
  expect_equal(x$alignment$summary$reference_n[1], 9)
  expect_equal(x$alignment$summary$predicted_n[1], 15)
  expect_equal(x$alignment$summary$matched[1], 4)
  expect_equal(x$alignment$annotation_evaluation$summary$agreement_among_paired, 1)
  ttr <- subset(x$differences, metric_id == "ttr")
  expect_equal(ttr$reference_N, c(4, 4, 1, 0))
  expect_equal(ttr$predicted_N, c(8, 6, 1, 0))
  expect_equal(ttr$delta, c(0, -1/12, 0, NA))
  expect_true(all(is.na(subset(x$document_scores, document_id == "short" & metric_id == "mattr")$value)))
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(x, path, version = 2)
  restored <- readRDS(path)
  expect_identical(do.call(lexdiv_align_annotations, restored$inputs), restored$alignment)
  expect_identical(restored, x)
})
