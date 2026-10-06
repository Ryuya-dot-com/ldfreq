contextual_fixture <- function(japanese = FALSE) {
  f <- ambiguity_fixture(japanese)
  r <- do.call(lexdiv_ambiguity_review, f)
  data <- r$occurrences[c("review_id", "occurrence_id", "segment_text", "surface", "start", "end")]
  data$status <- "processed"; data$reason <- "Authored transport test, not inference"
  model <- list(model_id = "authored", model_revision = "1", tokenizer_id = "authored",
    tokenizer_revision = "1", software = "test", software_version = "1",
    context_policy = "full segment; no truncation", representation = "authored 2-dimensional values",
    score_definition = "authored uncalibrated scores; larger is preferred")
  embedding <- matrix(c(1, 0, 0, 1), 2, dimnames = list(data$occurrence_id, NULL))
  suggestions <- data.frame(occurrence_id = rep(data$occurrence_id, each = 2),
    candidate_id = rep(c("sense-a", "sense-b"), 2), score = c(2, -1, 0.5, 0.5))
  list(review = r, data = data, model = model, embeddings = embedding, suggestions = suggestions)
}

test_that("model values join by occurrence ID and human decisions are preserved", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- contextual_fixture()
  out <- do.call(lexdiv_import_contextual, f)
  expect_identical(out$review, f$review)
  expect_identical(out$occurrences$status, c("unreviewed", "unreviewed"))
  expect_true(all(is.na(out$occurrences$candidate_id)))
  expect_identical(out$suggestions$pre, rep(f$review$occurrences$pre, each = 2))
  expect_identical(out$suggestions$human_status, rep("unreviewed", 4))
  expect_equal(out$suggestions$score, c(2, -1, 0.5, 0.5))
  expect_equal(out$summary$processed_proportion, 1)
  expect_equal(out$occurrences$n_suggestions, c(2, 2))
  f$data <- f$data[2:1, ]; f$embeddings <- f$embeddings[2:1, ]
  f$suggestions <- f$suggestions[4:1, ]
  reordered <- do.call(lexdiv_import_contextual, f)
  expect_identical(reordered$embeddings, out$embeddings)
  expect_identical(reordered$occurrences, out$occurrences)
  path <- tempfile(); on.exit(unlink(path))
  saveRDS(out, path); expect_identical(readRDS(path), out)
  # A model import can be attached to a later human review of the same source.
  af <- ambiguity_fixture()
  reviewed <- do.call(lexdiv_ambiguity_review, c(af, list(decisions = ambiguity_decisions(f$review))))
  f$review <- reviewed
  result <- do.call(lexdiv_import_contextual, f)
  expect_identical(result$occurrences$status, c("selected", "unresolved"))
  expect_identical(result$review$decisions, reviewed$decisions)
  expect_identical(result$occurrences$candidate_id, c("sense-a", NA_character_))
})

test_that("skipped, error, absent and empty results stay in the denominator", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- contextual_fixture()
  f$data <- f$data[1, ]; f$embeddings <- f$embeddings[1, , drop = FALSE]; f$suggestions <- NULL
  out <- do.call(lexdiv_import_contextual, f)
  expect_equal(out$summary$processed_proportion, 0.5)
  expect_identical(out$occurrences$model_status, c("processed", "not_returned"))
  for (status in c("skipped", "error")) {
    f$data$status <- status; f$embeddings <- NULL
    out <- do.call(lexdiv_import_contextual, f)
    expect_equal(out$summary[[status]], 1)
    expect_false(any(out$occurrences$has_embedding))
    expect_equal(out$summary$processed_proportion, 0)
  }
  f$data <- f$data[FALSE, ]
  expect_equal(do.call(lexdiv_import_contextual, f)$summary$not_returned, 2)
  af <- ambiguity_fixture(); af$targets <- "absent"; af$candidates <- af$candidates[FALSE, ]
  f$review <- do.call(lexdiv_ambiguity_review, af)
  out <- do.call(lexdiv_import_contextual, f)
  expect_equal(out$summary$occurrences, 0)
  expect_true(is.na(out$summary$processed_proportion))
  expect_equal(nrow(out$suggestions), 0)
})

test_that("stale text, positions, IDs and review changes are rejected", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- contextual_fixture()
  for (field in c("review_id", "segment_text", "surface")) {
    bad <- f; bad$data[[field]][1] <- "changed"
    expect_error(do.call(lexdiv_import_contextual, bad), "snapshot")
  }
  for (field in c("start", "end")) {
    bad <- f; bad$data[[field]][1] <- bad$data[[field]][1] + 1
    expect_error(do.call(lexdiv_import_contextual, bad), "snapshot")
  }
  bad <- f; bad$data$occurrence_id[1] <- "foreign"
  expect_error(do.call(lexdiv_import_contextual, bad), "existing")
  bad <- f; bad$data <- bad$data[c(1, 1), ]
  expect_error(do.call(lexdiv_import_contextual, bad), "unique")
  bad <- f; bad$review$occurrences$segment_text[1] <- "changed"
  expect_error(do.call(lexdiv_import_contextual, bad), "unmodified")
  af <- ambiguity_fixture(); af$resource$resource_version <- "2"
  bad <- f; bad$review <- do.call(lexdiv_ambiguity_review, af)
  expect_error(do.call(lexdiv_import_contextual, bad), "snapshot")
})

test_that("malformed embeddings, suggestions and provenance fail explicitly", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- contextual_fixture()
  for (value in c(NA_real_, Inf, NaN)) {
    bad <- f; bad$embeddings[1, 1] <- value
    expect_error(do.call(lexdiv_import_contextual, bad), "finite")
    bad <- f; bad$suggestions$score[1] <- value
    expect_error(do.call(lexdiv_import_contextual, bad), "finite")
  }
  for (ids in list(NULL, c("foreign", "other"), rep(rownames(f$embeddings)[1], 2))) {
    bad <- f; rownames(bad$embeddings) <- ids
    expect_error(do.call(lexdiv_import_contextual, bad), "row names")
  }
  bad <- f; bad$data$status[1] <- "skipped"
  expect_error(do.call(lexdiv_import_contextual, bad), "processed")
  bad <- f; bad$embeddings <- NULL; bad$suggestions <- NULL
  expect_error(do.call(lexdiv_import_contextual, bad), "Every processed")
  bad <- f; bad$suggestions$candidate_id[1] <- "foreign"
  expect_error(do.call(lexdiv_import_contextual, bad), "not a candidate")
  bad <- f; bad$suggestions <- bad$suggestions[c(1, 1), ]
  expect_error(do.call(lexdiv_import_contextual, bad), "unique")
  bad <- f; bad$suggestions$occurrence_id[1] <- "foreign"
  expect_error(do.call(lexdiv_import_contextual, bad), "processed")
  for (field in names(f$model)) {
    bad <- f; bad$model[[field]] <- NULL
    expect_error(do.call(lexdiv_import_contextual, bad), "requires")
  }
  bad <- f; bad$model$context_policy <- "truncated"
  expect_error(do.call(lexdiv_import_contextual, bad), "no truncation")
  bad <- f; bad$data$reason[1] <- " "
  expect_error(do.call(lexdiv_import_contextual, bad), "reason")
  bad <- f; bad$data$status[1] <- "selected"
  expect_error(do.call(lexdiv_import_contextual, bad), "processed")
  # Suggestion-only import is valid; it does not manufacture embeddings.
  f$embeddings <- NULL
  expect_null(do.call(lexdiv_import_contextual, f)$embeddings)
})

test_that("Japanese codepoints and JSON transport preserve original anchors", {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not_installed("jsonlite")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  f <- contextual_fixture(TRUE)
  text <- jsonlite::toJSON(f$data, dataframe = "rows", auto_unbox = TRUE)
  f$data <- jsonlite::fromJSON(text)
  out <- do.call(lexdiv_import_contextual, f)
  expect_equal(out$occurrences$start, c(5, 4))
  expect_identical(stringi::stri_sub(out$occurrences$segment_text,
    out$occurrences$start, out$occurrences$end), c("人気", "人気"))
  bad <- f; bad$data$start <- bad$data$start - 1L
  expect_error(do.call(lexdiv_import_contextual, bad), "snapshot")
  expect_identical(out$review$candidates$reading, c("にんき", "ひとけ"))
})
