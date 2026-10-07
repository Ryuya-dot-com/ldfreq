annotation_evaluation_fixture <- function() {
  segments <- data.frame(document_id = c("en", "ja", "partial", "empty"),
    segment_id = "s1", text = c("cats cats run.", "\u732b\u898b\u308b\u3002", "a b c", ""))
  data <- data.frame(document_id = rep(c("en", "ja", "partial"), c(4, 3, 3)),
    segment_id = "s1", token_index = c(1:4, 1:3, 1:3),
    surface = c("cats", "cats", "run", ".", "\u732b", "\u898b\u308b", "\u3002", "a", "b", "c"),
    upos = c("NOUN", "NOUN", "VERB", "PUNCT", "NOUN", "VERB", "PUNCT",
      NA_character_, "NOUN", NA_character_),
    review_status = c(rep("selected", 7), "unresolved", "selected", "unreviewed"))
  metadata <- list(language = "authored-multilingual", analyzer = "authored", analyzer_version = "1",
    dictionary = "none", dictionary_version = "not-applicable", unit = "authored-token",
    normalization = "none")
  reference <- lexdiv_import_annotations(data, segments, metadata)
  data$upos <- c("NOUN", "VERB", "NOUN", "PUNCT", NA_character_, "NOUN", "PUNCT",
    "NOUN", NA_character_, NA_character_)
  data$review_status <- NULL
  predicted <- lexdiv_import_annotations(data, segments, metadata)
  list(predicted = predicted, reference = reference, column = "upos",
    labels = c("NOUN", "VERB", "PUNCT", "ADJ"), context_chars = 3L,
    reference_info = list(reference_id = "authored-v1", annotation_protocol = "authored illustration",
      label_scheme = "UPOS subset for an authored example", model_exposure = "shown",
      evaluation_role = "development"))
}

reimport_evaluation <- function(x) {
  lexdiv_import_annotations(x$tokens,
    x$segments[setdiff(names(x$segments), c("token_count", "text_sha256"))],
    x$provenance$annotation)
}

test_that("known references define TP, FP and FN, including absent predictions", {
  f <- annotation_evaluation_fixture()
  x <- do.call(lexdiv_evaluate_annotations, f)
  expect_equal(unname(unlist(x$summary[1:9])), c(10, 8, 7, 6, 3, 3, 2, 1, 1))
  expect_equal(x$summary$reference_coverage, .8)
  expect_equal(x$summary$prediction_coverage, .7)
  expect_equal(x$summary$paired_coverage, .6)
  expect_equal(x$summary$agreement_among_paired, .5)
  expect_equal(x$summary$matches_among_reference_available, 3/8)
  expect_identical(x$pairs$outcome, c("agreement", "disagreement", "disagreement",
    "agreement", "reference_only", "disagreement", "agreement", "prediction_only",
    "reference_only", "neither_available"))
  expect_identical(x$pairs$matches_reference,
    c(TRUE, FALSE, FALSE, TRUE, NA, FALSE, TRUE, NA, NA, NA))
  expect_equal(x$labels$reference_n, c(4, 2, 2, 0))
  expect_equal(x$labels$tp, c(1, 0, 2, 0))
  expect_equal(x$labels$fp, c(2, 1, 0, 0))
  expect_equal(x$labels$fn, c(3, 2, 0, 0))
  expect_equal(x$labels$missing_predictions, c(2, 0, 0, 0))
  expect_equal(x$labels$predictions_without_reference, c(1, 0, 0, 0))
  expect_equal(x$labels$precision, c(1/3, 0, 1, NA))
  expect_equal(x$labels$recall, c(1/4, 0, 1, NA))
  expect_equal(x$labels$f1, c(2/7, 0, 1, NA))
  expect_equal(sum(x$confusion$n), 10)
  expect_equal(sum(x$confusion$n[is.na(x$confusion$predicted_label)]), 3)
  expect_equal(nrow(x$review_queue), 7)
  expect_identical(x$predicted, f$predicted)
  expect_identical(x$reference, f$reference)
  expect_identical(x$provenance$reference_info, f$reference_info)
  expect_identical(x$reference$tokens$review_status[10], "unreviewed")
  expect_identical(x$documents$document_id, c("en", "ja", "partial", "empty"))
  expect_equal(x$documents$tokens, c(4, 3, 3, 0))
  expect_identical(x$documents$reference_complete, c(TRUE, TRUE, FALSE, TRUE))
  expect_identical(x$documents$prediction_complete, c(TRUE, FALSE, FALSE, TRUE))
  expect_true(is.na(x$documents$reference_coverage[4]))
})

test_that("equal feature counts can conceal different occurrences and document TTR", {
  x <- do.call(lexdiv_evaluate_annotations, annotation_evaluation_fixture())
  p <- subset(x$pairs, document_id == "en")
  ref <- p$surface[p$reference_label == "NOUN"]
  pred <- p$surface[p$predicted_label == "NOUN"]
  expect_equal(length(ref), 2)
  expect_equal(length(pred), 2)
  expect_equal(lexdiv_metrics(ref, metrics = "ttr")$value, .5)
  expect_equal(lexdiv_metrics(pred, metrics = "ttr")$value, 1)
  expect_equal(sum(p$reference_label == "NOUN" & p$predicted_label != "NOUN"), 1)
  expect_equal(sum(p$reference_label != "NOUN" & p$predicted_label == "NOUN"), 1)
})

test_that("context uses original segment-local codepoints without normalization", {
  f <- annotation_evaluation_fixture()
  x <- do.call(lexdiv_evaluate_annotations, f)
  expect_identical(x$pairs$pre[2], "ts ")
  expect_identical(x$pairs$post[2], " ru")
  expect_identical(x$pairs$keyword, x$pairs$surface)
  expect_identical(x$pairs$pre[c(1, 5, 8)], rep("", 3))
  expect_identical(x$pairs$post[c(4, 7, 10)], rep("", 3))
  f$context_chars <- 0
  y <- do.call(lexdiv_evaluate_annotations, f)
  expect_identical(y$pairs$pre, rep("", 10))
  expect_identical(y$pairs$post, rep("", 10))
  segments <- data.frame(document_id = "unicode", segment_id = "s",
    text = "\U0001f600 \u304b\u3099\u732b")
  data <- data.frame(document_id = "unicode", segment_id = "s", token_index = 1:3,
    surface = c("\U0001f600", "\u304b\u3099", "\u732b"), upos = "NOUN")
  f$predicted <- f$reference <- lexdiv_import_annotations(data, segments,
    f$reference$provenance$annotation)
  f$context_chars <- 2
  y <- do.call(lexdiv_evaluate_annotations, f)
  expect_identical(y$pairs$start, c(1L, 3L, 5L))
  expect_identical(y$pairs$pre[2], "\U0001f600 ")
  expect_identical(y$pairs$post[1], " \u304b")
  expect_identical(y$pairs$keyword[2], "\u304b\u3099")
})

test_that("complete imports are paired by compound IDs, not row order", {
  f <- annotation_evaluation_fixture()
  baseline <- do.call(lexdiv_evaluate_annotations, f)
  f$predicted$segments <- f$predicted$segments[c(4, 3, 2, 1), ]
  f$predicted$tokens <- f$predicted$tokens[c(8:10, 5:7, 1:4), ]
  f$predicted <- reimport_evaluation(f$predicted)
  x <- do.call(lexdiv_evaluate_annotations, f)
  for (key in c("summary", "labels", "documents", "pairs", "confusion", "review_queue"))
    expect_identical(x[[key]], baseline[[key]])
  # Delimiter concatenation would collide for these document/segment pairs.
  for (side in c("predicted", "reference")) {
    a <- f[[side]]
    for (table in c("segments", "tokens")) {
      old <- a[[table]]$document_id
      a[[table]]$document_id[old == "en"] <- "a:b"
      a[[table]]$segment_id[old == "en"] <- "c"
      a[[table]]$document_id[old == "ja"] <- "a"
      a[[table]]$segment_id[old == "ja"] <- "b:c"
    }
    f[[side]] <- reimport_evaluation(a)
  }
  y <- do.call(lexdiv_evaluate_annotations, f)
  expect_identical(y$labels, baseline$labels)
  expect_identical(y$documents$tokens, baseline$documents$tokens)
})

test_that("empty imports and unavailable labels stay explicit", {
  f <- annotation_evaluation_fixture()
  f$reference$tokens$upos[] <- NA_character_
  f$reference <- reimport_evaluation(f$reference)
  x <- do.call(lexdiv_evaluate_annotations, f)
  expect_equal(x$summary$reference_available, 0)
  expect_true(is.na(x$summary$agreement_among_paired))
  expect_true(all(is.na(x$labels$f1)))
  expect_equal(sum(x$labels$fp), 0)
  expect_equal(sum(x$labels$predictions_without_reference), 7)
  for (side in c("predicted", "reference")) {
    f[[side]]$tokens <- f[[side]]$tokens[FALSE, ]
    f[[side]]$segments <- f[[side]]$segments[4, ]
    f[[side]] <- reimport_evaluation(f[[side]])
  }
  x <- do.call(lexdiv_evaluate_annotations, f)
  expect_equal(x$summary$tokens, 0)
  expect_equal(nrow(x$documents), 1)
  expect_equal(nrow(x$pairs), 0)
  expect_equal(nrow(x$confusion), 0)
  expect_true(all(is.na(x$labels$f1)))
  expect_type(x$pairs$reference_label, "character")
  expect_identical(x$documents$document_id, "empty")
})

test_that("altered imports, different sources and changed boundaries are rejected", {
  f <- annotation_evaluation_fixture()
  changed <- f; changed$predicted$tokens$upos[1] <- "VERB"
  expect_error(do.call(lexdiv_evaluate_annotations, changed), "has changed")
  changed <- f; changed$predicted$segments$text[4] <- " "
  changed$predicted <- reimport_evaluation(changed$predicted)
  expect_error(do.call(lexdiv_evaluate_annotations, changed), "original text")
  changed <- f; changed$predicted$segments <- changed$predicted$segments[-4, ]
  changed$predicted <- reimport_evaluation(changed$predicted)
  expect_error(do.call(lexdiv_evaluate_annotations, changed), "segment IDs")
  changed <- f
  changed$predicted$tokens <- changed$predicted$tokens[-2, ]
  changed$predicted$tokens$surface[1] <- "cats cats"
  changed$predicted$tokens$token_index[1:3] <- 1:3
  changed$predicted$tokens$start <- changed$predicted$tokens$end <- NULL
  changed$predicted <- reimport_evaluation(changed$predicted)
  expect_error(do.call(lexdiv_evaluate_annotations, changed), "segmentation")
  expect_error(lexdiv_evaluate_annotations(f$predicted, f$reference, "upos", f$labels,
    f$reference_info, max_tokens = 9), "max_tokens")
  changed <- f; changed$predicted <- list(tokens = f$predicted$tokens)
  expect_error(do.call(lexdiv_evaluate_annotations, changed), "unmodified")
})

test_that("label inventories and reference declarations are explicit", {
  f <- annotation_evaluation_fixture()
  for (value in list(c("NOUN", "VERB"), c("NOUN", "NOUN"), character(),
                    c("NOUN", " "), NA_character_, factor(f$labels))) {
    changed <- f; changed$labels <- value
    expect_error(do.call(lexdiv_evaluate_annotations, changed), "labels|inventory")
  }
  for (value in list(NA_character_, "absent", c("upos", "surface"))) {
    changed <- f; changed$column <- value
    expect_error(do.call(lexdiv_evaluate_annotations, changed), "column")
  }
  for (value in list(factor(f$predicted$tokens$upos), rep(TRUE, 10), rep("", 10))) {
    changed <- f; changed$predicted$tokens$upos <- value
    changed$predicted <- reimport_evaluation(changed$predicted)
    expect_error(do.call(lexdiv_evaluate_annotations, changed), "character|empty")
  }
  for (value in list(-1, .5, NA_real_, Inf, numeric(), c(1, 2), "1")) {
    changed <- f; changed$context_chars <- value
    expect_error(do.call(lexdiv_evaluate_annotations, changed), "context_chars")
  }
  for (field in names(f$reference_info)) {
    changed <- f; changed$reference_info[[field]] <- NULL
    expect_error(do.call(lexdiv_evaluate_annotations, changed), "requires")
  }
  for (value in c("", " ", "independent")) {
    changed <- f; changed$reference_info$model_exposure <- value
    expect_error(do.call(lexdiv_evaluate_annotations, changed), "empty|blank|model_exposure")
  }
  changed <- f; changed$reference_info$evaluation_role <- "test"
  expect_error(do.call(lexdiv_evaluate_annotations, changed), "evaluation_role")
})

test_that("saving inputs and settings exactly reproduces evaluation", {
  f <- annotation_evaluation_fixture()
  x <- do.call(lexdiv_evaluate_annotations, f)
  path <- tempfile(); on.exit(unlink(path))
  saveRDS(list(inputs = f, evaluation = x), path, version = 2)
  restored <- readRDS(path)
  expect_identical(do.call(lexdiv_evaluate_annotations, restored$inputs), restored$evaluation)
  expect_identical(.lexng_hash(x), x$provenance$content_sha256)
})

test_that("no predictions gives undefined precision but zero recall for observed classes", {
  f <- annotation_evaluation_fixture()
  f$predicted$tokens$upos[] <- NA_character_
  f$predicted <- reimport_evaluation(f$predicted)
  x <- do.call(lexdiv_evaluate_annotations, f)
  expect_true(all(is.na(x$labels$precision)))
  expect_equal(x$labels$recall, c(0, 0, 0, NA))
  expect_equal(x$labels$f1, c(0, 0, 0, NA))
  expect_equal(x$summary$matches_among_reference_available, 0)
  expect_true(is.na(x$summary$agreement_among_paired))
})

test_that("installed example keeps document metric differences and missingness together", {
  env <- new.env(parent = baseenv())
  sys.source(system.file("examples", "annotation-evaluation.R", package = "ldfreq",
    mustWork = TRUE), envir = env)
  x <- env$annotation_evaluation_example
  expect_equal(x$differences$delta_ttr, c(.5, .5, NA, NA, NA))
  expect_equal(x$differences$reference_nouns, c(2, 2, NA, 1, 0))
  expect_equal(x$differences$predicted_nouns, c(2, 2, 1, NA, 0))
  expect_identical(x$differences$reference_status,
    c("ok", "ok", "incomplete_annotation", "ok", "missing"))
  expect_identical(x$differences$predicted_status,
    c("ok", "ok", "ok", "incomplete_annotation", "missing"))
  expect_equal(subset(x$document_scores, missing_labels > 0)$observed_selected, c(1, 1))
  expect_equal(x$evaluation$summary$tokens, 17)
  expect_equal(x$evaluation$summary$reference_available, 16)
  expect_equal(x$evaluation$summary$agreement, 11)
  expect_identical(do.call(lexdiv_evaluate_annotations, x$inputs), x$evaluation)
})
