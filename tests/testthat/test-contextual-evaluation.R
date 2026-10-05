evaluation_fixture <- function(japanese = FALSE) {
  other <- if (japanese) "人気" else "paper"
  words <- c(rep("bank", 6), other, "none", "single", "bank")
  tokens <- data.frame(document_id = "d", segment_id = paste0("s", seq_along(words)),
    token_index = 1L, surface = words)
  source <- lexdiv_import_annotations(tokens, data.frame(tokens[c("document_id", "segment_id")],
    text = words), list(language = "authored", analyzer = "authored", analyzer_version = "1",
      dictionary = "none", dictionary_version = "none", unit = "test", normalization = "none"))
  candidates <- data.frame(term = c("bank", "bank", other, other, "single"),
    candidate_id = c("a", "b", "a", "b", "only"), label = c("financial", "river", "other A", "other B", "single"))
  args <- list(x = source, targets = c("bank", other, "none", "single", "absent"), candidates = candidates,
    resource = list(resource_id = "authored", resource_version = "1",
      source_reference = "Authored test inventory", data_license = "MIT"))
  review <- do.call(lexdiv_ambiguity_review, args)
  data <- review$occurrences[c(1:7, 9:10), c("review_id", "occurrence_id", "segment_text", "surface", "start", "end")]
  data$status <- "processed"; data$status[5] <- "error"
  data$reason <- "Authored transport fixture"
  k <- c(1,1,2,2,3,3,4,6,6,7,7,9)
  scores <- data.frame(occurrence_id = review$occurrences$occurrence_id[k],
    candidate_id = c("a","b","a","b","a","b","a","a","b","a","b","only"),
    score = c(2,0,0,2,1,1,5,2,0,0,2,-5))
  matrix <- matrix(c(1,0), nrow = 1, dimnames = list(review$occurrences$occurrence_id[10], NULL))
  model <- list(model_id = "authored", model_revision = "1", tokenizer_id = "authored",
    tokenizer_revision = "1", software = "test", software_version = "1",
    context_policy = "full segment; no truncation", representation = "authored values",
    score_definition = "authored scores; larger is preferred")
  x <- lexdiv_import_contextual(review, data, model, matrix, scores)
  d <- review$occurrences[c(1:7,9), c("review_id", "occurrence_id")]
  d$status <- "selected"; d$status[6] <- "unresolved"
  d$candidate_id <- c("a", "a", "b", "a", "b", NA_character_, "b", "only")
  d$reviewer <- "authored-reference"; d$reason <- "Authored criterion, not real annotation"
  reference <- do.call(lexdiv_ambiguity_review, c(args, list(decisions = d)))
  info <- list(reference_id = "authored", annotation_protocol = "Test fixture; not human evidence",
    model_exposure = "unknown", evaluation_role = "development")
  list(x = x, reference = reference, direction = "higher", reference_info = info,
    review_args = args, decisions = d)
}

evaluate_fixture <- function(f, ...) do.call(lexdiv_evaluate_contextual,
  c(f[c("x", "reference", "direction", "reference_info")], list(...)))

test_that("ranking abstains on ties and incomplete inventories with explicit denominators", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- evaluation_fixture(); out <- evaluate_fixture(f)
  expect_identical(out$pairs$prediction_status, c("unique_best", "unique_best", "tied_best",
    "incomplete_scores", "no_scores", "unique_best", "unique_best", "no_candidates", "unique_best", "no_scores"))
  expect_identical(out$pairs$predicted_candidate_id, c("a", "b", NA_character_, NA_character_,
    NA_character_, "a", "b", NA_character_, "only", NA_character_))
  expect_equal(out$summary$occurrences, 10)
  expect_equal(out$summary$reference_selected, 7)
  expect_equal(out$summary$predictions, 5)
  expect_equal(out$summary$paired, 4)
  expect_equal(out$summary$agreement, 3)
  expect_equal(out$summary$disagreement, 1)
  expect_equal(out$summary$reference_only, 3)
  expect_equal(out$summary$prediction_only, 1)
  expect_equal(out$summary$neither_available, 2)
  expect_equal(out$summary$prediction_coverage, 0.5)
  expect_equal(out$summary$reference_coverage, 0.7)
  expect_equal(out$summary$paired_coverage, 0.4)
  expect_equal(out$summary$agreement_among_paired, 3/4)
  expect_equal(out$summary$matches_among_reference_selected, 3/7)
  expect_equal(out$summary$reference_without_score, 1)
  expect_equal(out$summary$single_candidate_predictions, 1)
  expect_true(out$pairs$reference_scored[4]) # Still abstains: a rival is missing.
  expect_false(out$pairs$reference_scored[5])
  expect_true(is.na(out$pairs$reference_scored[6]))
  expect_equal(nrow(out$review_queue), 7)
  expect_equal(sum(out$confusion$n), 4)
  expect_true(all(c("bank", "paper", "single") %in% out$confusion$term))
  expect_equal(out$terms$occurrences, c(7,1,1,1,0))
  expect_true(is.na(out$terms$agreement_among_paired[5]))
  expect_identical(out$model_output, f$x)
  expect_identical(out$reference, f$reference)
  expect_identical(out$pairs$segment_text, f$x$occurrences$segment_text)
})

test_that("score direction, absolute tie tolerance and ordering cannot silently choose ties", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- evaluation_fixture()
  lower <- f; lower$direction <- "lower"
  expect_identical(evaluate_fixture(lower)$pairs$predicted_candidate_id[c(1,2,7)], c("b", "a", "a"))
  expect_equal(evaluate_fixture(f, tie_tolerance = 2)$summary$predictions, 1) # Singleton only.
  expect_equal(evaluate_fixture(f, tie_tolerance = 1.99)$summary$predictions, 5)
  expected <- evaluate_fixture(f)
  scores <- f$x$suggestions[rev(seq_len(nrow(f$x$suggestions))), c("occurrence_id", "candidate_id", "score")]
  f$x <- lexdiv_import_contextual(f$x$review, f$x$data[rev(seq_len(nrow(f$x$data))), ],
    f$x$provenance$model, f$x$embeddings, scores)
  f$review_args$candidates <- f$review_args$candidates[rev(seq_len(nrow(f$review_args$candidates))), ]
  f$review_args$targets <- rev(f$review_args$targets)
  f$reference <- do.call(lexdiv_ambiguity_review,
    c(f$review_args, list(decisions = f$decisions[rev(seq_len(nrow(f$decisions))), ], window = 0)))
  got <- evaluate_fixture(f)
  expect_identical(got$summary, expected$summary)
  expect_identical(got$pairs, expected$pairs)
  path <- tempfile(); on.exit(unlink(path))
  saveRDS(got,path); expect_identical(readRDS(path),got)
})

test_that("saved embedding-only output and empty references do not invent predictions", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- evaluation_fixture()
  data <- f$x$data; data$status <- "processed"
  v <- matrix(1, nrow(data), 2, dimnames = list(data$occurrence_id,NULL))
  f$x <- lexdiv_import_contextual(f$x$review,data,f$x$provenance$model,v)
  out <- evaluate_fixture(f)
  expect_equal(out$summary$predictions,0)
  expect_equal(out$summary$reference_without_score,7)
  expect_true(is.na(out$summary$agreement_among_paired))
  expect_equal(out$summary$matches_among_reference_selected,0)
  f$review_args$targets <- "absent"
  f$review_args$candidates <- f$review_args$candidates[FALSE, ]
  f$reference <- do.call(lexdiv_ambiguity_review,f$review_args)
  f$x <- lexdiv_import_contextual(f$reference,data[FALSE, ],f$x$provenance$model)
  out <- evaluate_fixture(f)
  expect_equal(out$summary$occurrences,0)
  expect_type(out$pairs$prediction_status,"character")
  expect_true(is.na(out$summary$prediction_coverage))
  expect_true(is.na(out$summary$matches_among_reference_selected))
  expect_equal(nrow(out$confusion),0)
  expect_equal(nrow(out$review_queue),0)
  expect_equal(out$terms$occurrences,0)
})

test_that("unselected reference judgments remain unavailable rather than incorrect", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- evaluation_fixture(); f$reference <- f$x$review
  out <- evaluate_fixture(f)
  expect_equal(out$summary$reference_selected,0)
  expect_equal(out$summary$prediction_only,5)
  expect_true(is.na(out$summary$agreement_among_paired))
  expect_true(is.na(out$summary$matches_among_reference_selected))
  expect_true(all(is.na(out$pairs$matches_reference)))
})

test_that("tampering, stale candidates, invalid choices and omitted declarations fail", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- evaluation_fixture()
  for (part in c("occurrences", "suggestions", "summary")) {
    bad <- f; bad$x[[part]][1, 1] <- "changed"
    expect_error(evaluate_fixture(bad), "unmodified")
  }
  bad <- f; bad$x$embeddings[1, 1] <- 100
  expect_error(evaluate_fixture(bad), "unmodified")
  bad <- f; bad$x$provenance$model$model_revision <- "2"
  expect_error(evaluate_fixture(bad), "unmodified")
  bad <- f; bad$reference$occurrences$candidate_id[1] <- "b"
  expect_error(evaluate_fixture(bad), "unmodified")
  bad <- f; bad$review_args$resource$resource_version <- "2"
  bad$reference <- do.call(lexdiv_ambiguity_review,bad$review_args)
  expect_error(evaluate_fixture(bad), "same source")
  for (v in list(NA_real_, Inf, -1, c(0,1), numeric(), "0"))
    expect_error(evaluate_fixture(f,tie_tolerance=v), "tie_tolerance")
  for (v in c("unknown", "Higher")) {
    bad <- f; bad$direction <- v
    expect_error(evaluate_fixture(bad), "direction")
  }
  for (field in names(f$reference_info)) {
    bad <- f; bad$reference_info[[field]] <- NULL
    expect_error(evaluate_fixture(bad), "requires")
  }
  bad <- f; bad$reference_info$model_exposure <- "independent"
  expect_error(evaluate_fixture(bad), "model_exposure")
  bad <- f; bad$reference_info$annotation_protocol <- " "
  expect_error(evaluate_fixture(bad), "blank")
  f$reference_info$model_exposure <- "shown"
  expect_identical(evaluate_fixture(f)$provenance$reference_info$model_exposure,"shown")
})

test_that("Japanese candidates retain their own inventory despite reused candidate IDs", {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  out <- evaluate_fixture(evaluation_fixture(TRUE))
  expect_identical(out$pairs$surface[7],"人気")
  expect_identical(out$pairs$predicted_candidate_id[7],"b")
  expect_equal(out$confusion$n[out$confusion$term=="人気"],1)
  expect_equal(out$summary$agreement,3)
})
