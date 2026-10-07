proposal_example <- function() {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  e <- new.env(parent = baseenv())
  for (name in c("candidate-proposals.R", "candidate-proposals-demo.R"))
    sys.source(system.file("examples", name, package = "ldfreq", mustWork = TRUE), e)
  e
}

test_that("categorical proposals preserve anchors, coverage and human judgments", {
  e <- proposal_example(); f <- e$candidate_proposals_example
  x <- f$imported
  expect_equal(x$summary[c("occurrences", "requested", "returned", "selected", "unresolved", "not_requested")],
    data.frame(occurrences = 4L, requested = 3L, returned = 3L, selected = 2L, unresolved = 1L, not_requested = 1L))
  expect_identical(x$review, f$review)
  expect_identical(x$occurrences$human_status, f$review$occurrences$status)
  expect_true(all(is.na(x$occurrences$human_candidate_id)))
  expect_false(any(c("human_status", "human_reason", "reviewer") %in% names(f$plan$anchors)))
  partial <- e$import_candidate_proposals(f$review, f$plan, f$proposals[2:1, ], f$model)
  expect_identical(partial$occurrences$proposal_status, c("selected", "selected", "not_returned", "not_requested"))
  altered <- f$plan; altered$anchors$start[1] <- 1L
  expect_error(e$import_candidate_proposals(f$review, altered, f$proposals, f$model), "Plan differs")
  bad <- f$proposals; bad$candidate_id[1] <- "not-in-inventory"
  expect_error(e$import_candidate_proposals(f$review, f$plan, bad, f$model), "does not belong")
  bad <- f$proposals; bad$candidate_id[3] <- "popularity"
  expect_error(e$import_candidate_proposals(f$review, f$plan, bad, f$model), "Only selected")
  expect_error(e$import_candidate_proposals(f$review, f$plan, f$proposals[c(1, 1), ], f$model), "unique requested")
  no_candidates <- e$prepare_candidate_proposals(f$review, f$review$occurrences$occurrence_id[4])
  bad <- f$proposals[1, ]; bad$occurrence_id <- no_candidates$anchors$occurrence_id
  expect_error(e$import_candidate_proposals(f$review, no_candidates, bad, f$model), "does not belong")
  bad$proposal_status <- "candidate_missing"; bad$candidate_id <- NA_character_
  expect_equal(e$import_candidate_proposals(f$review, no_candidates, bad, f$model)$summary$candidate_missing, 1)
  saved <- tempfile(); saveRDS(x, saved); on.exit(unlink(saved))
  expect_identical(readRDS(saved), x)
  changed_candidates <- f$review$candidates
  changed_candidates$label[1] <- "A new interpretation"
  changed_review <- lexdiv_ambiguity_review(f$review$source, f$review$summary$term,
    changed_candidates, f$review$provenance$resource)
  expect_error(e$import_candidate_proposals(changed_review, f$plan, f$proposals, f$model), "Plan differs")
})

test_that("paid calls are explicit, responses are reused, and credentials are not saved", {
  skip_if_not_installed("httr2", "1.0.0")
  skip_if_not_installed("jsonlite")
  e <- proposal_example(); f <- e$candidate_proposals_example
  dir <- tempfile(); on.exit(unlink(dir, recursive = TRUE))
  calls <- 0L
  previous_key <- Sys.getenv("OPENAI_API_KEY", unset = NA_character_)
  on.exit(if (is.na(previous_key)) Sys.unsetenv("OPENAI_API_KEY") else
    Sys.setenv(OPENAI_API_KEY = previous_key), add = TRUE)
  Sys.setenv(OPENAI_API_KEY = "test-key-not-a-real-credential")
  options_old <- options(httr2_mock = function(req) {
    calls <<- calls + 1L
    expect_identical(req$url, "https://api.openai.com/v1/responses")
    expect_false(req$options$followlocation)
    body <- req$body$data
    expect_false(body$store)
    expect_equal(body$max_output_tokens, 1024)
    expect_false(grepl("test-key-not-a-real-credential", body$input, fixed = TRUE))
    json <- jsonlite::toJSON(list(status = "completed", model = "test-model-snapshot",
      usage = list(input_tokens = 30, output_tokens = 12, total_tokens = 42),
      output = list(list(type = "message", content = list(list(type = "output_text",
        text = as.character(jsonlite::toJSON(list(proposals = f$proposals), auto_unbox = TRUE, na = "null"))))))),
      auto_unbox = TRUE)
    httr2::response(200L, headers = list("content-type" = "application/json"), body = charToRaw(json))
  })
  on.exit(options(options_old), add = TRUE)
  expect_error(e$openai_candidate_proposals(f$plan, "test-model", dir), "allow_paid")
  expect_false(dir.exists(dir)); expect_equal(calls, 0)
  run <- e$openai_candidate_proposals(f$plan, "test-model", dir, allow_paid = TRUE)
  expect_identical(run$status, "completed")
  expect_equal(calls, 1)
  Sys.unsetenv("OPENAI_API_KEY")
  replay <- e$openai_candidate_proposals(f$plan, "test-model", dir)
  expect_identical(replay, run); expect_equal(calls, 1)
  expect_equal(run$usage$total_tokens, 42)
  expect_identical(run$model$model_revision, "test-model-snapshot")
  expect_false(grepl("test-key-not-a-real-credential", jsonlite::toJSON(run, auto_unbox = TRUE), fixed = TRUE))
  expect_error(e$openai_candidate_proposals(f$plan, "other-model", dir), "differs")
  expect_error(e$openai_candidate_proposals(f$plan, "test-model", dir, max_output_tokens = 200), "differs")
  unlink(file.path(dir, "result.rds"))
  expect_error(e$openai_candidate_proposals(f$plan, "test-model", dir), "no automatic retry")
  expect_equal(calls, 1)
})

test_that("empty, partial and malformed envelopes remain saved without replay requests", {
  skip_if_not_installed("httr2", "1.0.0")
  skip_if_not_installed("jsonlite")
  e <- proposal_example(); f <- e$candidate_proposals_example
  parent <- tempfile(); dir.create(parent); on.exit(unlink(parent, recursive = TRUE))
  previous_key <- Sys.getenv("OPENAI_API_KEY", unset = NA_character_)
  on.exit(if (is.na(previous_key)) Sys.unsetenv("OPENAI_API_KEY") else
    Sys.setenv(OPENAI_API_KEY = previous_key), add = TRUE)
  Sys.setenv(OPENAI_API_KEY = "test-key")
  responses <- list("42", "null", '{"status":"completed","output":[42]}',
    '{"status":"completed","output":[{"type":"message","content":[{"type":"output_text","text":[1,2]}]}]}')
  for (rows in list(f$proposals[2, ], f$proposals[3, ], f$proposals[FALSE, ])) {
    text <- as.character(jsonlite::toJSON(list(proposals = rows), auto_unbox = TRUE, na = "null"))
    responses[[length(responses) + 1L]] <- as.character(jsonlite::toJSON(list(status = "completed",
      output = list(list(type = "message", content = list(list(type = "output_text", text = text))))),
      auto_unbox = TRUE))
  }
  old <- options(httr2_mock = NULL); on.exit(options(old), add = TRUE)
  for (i in seq_along(responses)) {
    options(httr2_mock = function(req) httr2::response(200L,
      headers = list("content-type" = "application/json"), body = charToRaw(responses[[i]])))
    path <- file.path(parent, paste0("run", i))
    run <- e$openai_candidate_proposals(f$plan, "test-model", path, allow_paid = TRUE)
    expect_identical(run$status, if (i <= 4) "invalid_output" else "partial")
    options(httr2_mock = function(req) stop("Replay must not send"))
    expect_identical(e$openai_candidate_proposals(f$plan, "test-model", path), run)
  }
})

test_that("refusal, incomplete and invalid replies never become chosen candidates", {
  skip_if_not_installed("httr2", "1.0.0")
  skip_if_not_installed("jsonlite")
  e <- proposal_example(); f <- e$candidate_proposals_example
  parent <- tempfile(); dir.create(parent); on.exit(unlink(parent, recursive = TRUE))
  previous_key <- Sys.getenv("OPENAI_API_KEY", unset = NA_character_)
  on.exit(if (is.na(previous_key)) Sys.unsetenv("OPENAI_API_KEY") else
    Sys.setenv(OPENAI_API_KEY = previous_key), add = TRUE)
  Sys.setenv(OPENAI_API_KEY = "test-key")
  replies <- list(
    list(status = "completed", output = list(list(type = "message", content = list(list(type = "refusal", refusal = "No"))))),
    list(status = "incomplete", output = list()),
    list(status = "completed", output = list(list(type = "message", content = list(list(type = "output_text", text = "not JSON"))))),
    list(status = "completed", output = list(list(type = "message", content = list(list(type = "output_text",
      text = as.character(jsonlite::toJSON(list(proposals = f$proposals[c(1, 1), ]), auto_unbox = TRUE))))))))
  expected <- c("refused", "incomplete", "invalid_output", "invalid_output", "http_error", "transport_error")
  old <- options(httr2_mock = NULL); on.exit(options(old), add = TRUE)
  for (i in seq_along(expected)) {
    options(httr2_mock = function(req) {
      if (i == 6) stop("Simulated connection loss")
      if (i == 5) return(httr2::response(429L, body = charToRaw("private error details")))
      httr2::response(200L, headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(replies[[i]], auto_unbox = TRUE)))
    })
    run <- e$openai_candidate_proposals(f$plan, "test-model", file.path(parent, paste0("run", i)), allow_paid = TRUE)
    expect_identical(run$status, expected[i]); expect_equal(nrow(run$proposals), 0)
    imported <- e$import_candidate_proposals(f$review, f$plan, run$proposals, run$model)
    expect_equal(imported$summary$not_returned, 3)
    expect_true(file.exists(file.path(parent, paste0("run", i), "result.rds")))
  }
})
