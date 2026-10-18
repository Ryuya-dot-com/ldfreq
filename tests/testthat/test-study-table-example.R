study_example <- function() {
  e <- new.env(parent = globalenv())
  sys.source(system.file("examples", "repeated-study-demo.R", package = "ldfreq",
    mustWork = TRUE), e)
  e
}

test_that("the study table retains planned observations and distinct absence states", {
  e <- study_example(); x <- e$study
  expect_s3_class(x, "data.frame", exact = TRUE)
  expect_equal(nrow(x), 216)
  expect_identical(x$observation_id, rep(e$planned$observation_id, each = 2))
  expect_identical(x$request_id, rep(c("ttr", "mattr10"), 108))
  expect_identical(x$writer_id, rep(e$planned$writer_id, each = 2))
  expect_identical(x$task, e$planned$task[rep(1:108, each = 2)])
  expect_identical(x$scheduled_date, rep(e$planned$scheduled_date, each = 2))
  y <- x[x$request_id == "mattr10", ]
  expect_identical(y$input_status[1:6], c("not_submitted", "empty_text",
    "no_selected_tokens", rep("selected_tokens", 3)))
  expect_identical(y$computation_status[1:6], c("not_submitted", rep("missing", 3), "ok", "ok"))
  expect_true(is.na(y$status[1]))
  expect_identical(y$missing_reason[2:4], c("empty_input", "empty_input",
    "too_short_for_requested_parameter"))
  expect_equal(y$N[1:4], c(NA, 0, 0, 3))
  expect_identical(y$reporting_status[5], "withhold")
  expect_true(is.finite(y$value[5]))
  expect_true(is.na(y$writer_id[6]))
  expect_identical(y$writer_id[7], "007")
  # The authored three-token text gives a hand-checkable TTR but no MATTR10.
  expect_equal(x$value[x$document_id %in% "doc-004" & x$request_id == "ttr"], 2/3)
  expect_identical(e$selected$data$observation_id, sprintf("obs-%03d", 7:108))
  expect_identical(e$selected$audit$included, c(rep(FALSE, 6), rep(TRUE, 102)))
  expect_identical(e$selected$audit$missing_metadata[6], "writer_id")
  expect_identical(e$selected$audit$not_submitted, c(TRUE, rep(FALSE, 107)))
  expect_identical(e$selected$audit$not_computable, c(rep(TRUE, 4), rep(FALSE, 104)))
  expect_identical(which(e$selected$audit$not_reportable), c(1L, 5L))
})

test_that("joins use explicit IDs and preserve submitted results without recalculation", {
  e <- study_example()
  before <- serialize(list(e$planned, e$submissions, e$results, e$plan, e$reporting), NULL)
  joined <- e$helper$study_long_table(e$planned, e$submissions[107:1, ],
    e$results[214:1, ], e$plan, e$condition$id, e$reporting[214:1, ])
  expect_identical(joined, e$study)
  expect_identical(serialize(list(e$planned, e$submissions, e$results, e$plan, e$reporting), NULL), before)
  submitted <- joined[joined$submission_status == "submitted", names(e$results), drop = FALSE]
  rownames(submitted) <- NULL
  for (name in names(e$results)) expect_identical(submitted[[name]], e$results[[name]])
  planned <- e$planned[108:1, ]
  joined <- e$helper$study_long_table(planned, e$submissions, e$results, e$plan, e$condition$id)
  expect_identical(joined$observation_id, rep(planned$observation_id, each = 2))
  expect_identical(joined$reporting_status, rep("not_screened", 216))
  expect_equal(nrow(e$helper$study_model_data(joined, e$condition$id, "ttr")$data), 0)
  sub <- e$submissions; sub$input_characters[1] <- NA_integer_
  joined <- e$helper$study_long_table(e$planned, sub, e$results, e$plan, e$condition$id)
  expect_identical(joined$input_status[3:4], rep("unknown", 2))
})

test_that("all unsubmitted and all missing studies keep a complete roster", {
  e <- study_example()
  empty_results <- lexdiv_metrics_batch(setNames(list(), character()), plan = e$plan)
  x <- e$helper$study_long_table(e$planned, e$submissions[FALSE, ], empty_results,
    e$plan, e$condition$id)
  expect_equal(nrow(x), 216)
  expect_true(all(is.na(x$value)))
  expect_true(all(is.na(x$N)))
  expect_true(all(is.na(x$status)))
  expect_true(all(x$submission_status == "not_submitted"))
  expect_identical(x$specification_id, e$study$specification_id)
  expect_identical(x$requested_parameters, e$study$requested_parameters)
  selected <- e$helper$study_model_data(x, e$condition$id, "mattr10")
  expect_equal(nrow(selected$data), 0)
  expect_equal(nrow(selected$audit), 108)
  tokens <- setNames(rep(list(character()), 107), e$submissions$document_id)
  sub <- e$submissions; sub$input_characters[] <- 0L
  x <- e$helper$study_long_table(e$planned, sub,
    lexdiv_metrics_batch(tokens, plan = e$plan), e$plan, e$condition$id, e$reporting)
  expect_true(all(is.na(x$value)))
  expect_equal(nrow(e$helper$study_model_data(x, e$condition$id, "ttr")$data), 0)
  zero <- e$helper$study_long_table(e$planned[FALSE, ], sub[FALSE, ], empty_results,
    e$plan, e$condition$id)
  expect_equal(nrow(zero), 0)
  expect_identical(vapply(zero, typeof, ""), vapply(e$study, typeof, ""))
  expect_error(e$helper$study_model_data(zero, e$condition$id, "ttr"), "No planned")
})

test_that("ambiguous joins and incompatible plans fail before constructing a table", {
  e <- study_example()
  join <- function(planned = e$planned, sub = e$submissions, result = e$results,
                   plan = e$plan, reporting = e$reporting, ...) {
    e$helper$study_long_table(planned, sub, result, plan, e$condition$id, reporting, ...)
  }
  p <- e$planned; p$observation_id[2] <- p$observation_id[1]
  expect_error(join(planned = p), "unique character")
  p <- e$planned; p$value <- 1
  expect_error(join(planned = p), "collide")
  sub <- e$submissions; sub$observation_id[2] <- sub$observation_id[1]
  expect_error(join(sub = sub), "at most one")
  sub <- e$submissions; sub$document_id[2] <- sub$document_id[1]
  expect_error(join(sub = sub), "at most one")
  sub <- e$submissions; sub$observation_id[2] <- "unplanned"
  expect_error(join(sub = sub), "known observation")
  sub <- e$submissions; sub$input_characters[4] <- -1
  expect_error(join(sub = sub), "nonnegative")
  sub$input_characters[4] <- 0
  expect_error(join(sub = sub), "zero-character")
  expect_error(join(result = e$results[-1, ]), "exactly one row")
  expect_error(join(result = rbind(e$results, e$results[1, ])), "exactly one row")
  r <- e$results; r$document_id[1] <- "other"
  expect_error(join(result = r), "exactly one row")
  r <- e$results; r$specification_id[1] <- "changed"
  expect_error(join(result = r), "do not match")
  r <- e$results; r$requested_parameters[[2]]$window_length <- 11L
  expect_error(join(result = r), "do not match")
  r <- e$results; r$N[8] <- r$N[8] + 1
  expect_error(join(result = r), "same selected tokens")
  r <- e$results; r$value[1] <- 0
  expect_error(join(result = r), "inconsistent")
  expect_error(join(reporting = e$reporting[-1, ]), "cover exactly")
  report <- e$reporting; report$reporting_reason[1] <- ""
  expect_error(join(reporting = report), "nonblank reasons")
  expect_error(join(max_rows = 215), "exceeds max_rows")
  expect_error(join(plan = lexdiv_plan("canonical")), "exactly one row|do not match")
})

test_that("model selection rejects pooled identities and tracks missing covariates", {
  e <- study_example()
  select <- function(x, ...) e$helper$study_model_data(x, e$condition$id, "mattr10", ...)
  expect_error(select(rbind(e$study, e$study)), "one row per observation")
  x <- e$study; x$specification_id[4] <- "other"
  expect_error(select(x), "one specification")
  x <- e$study; x$document_id[16] <- x$document_id[14]
  expect_error(select(x), "multiple model observations")
  x <- e$study; x$score <- rep(1, nrow(x)); x$score[14] <- NA_real_
  selected <- select(x, required = c("writer_id", "task", "occasion", "score"))
  expect_equal(nrow(selected$data), 101)
  expect_identical(selected$audit$missing_metadata[7], "score")
  x <- e$study; x$condition_id <- "alternative"
  both <- rbind(e$study, x)
  # Base rbind can discard custom factor contrasts; declare them after binding.
  contrasts(both$task) <- contrasts(e$study$task)
  expect_identical(select(both), e$selected)
})

test_that("the saved record round-trips types, factors, provenance and selected IDs", {
  e <- study_example()
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(e$record, path); saved <- readRDS(path)
  expect_identical(saved$study, e$study)
  expect_identical(saved$prepared, e$prepared)
  expect_identical(saved$plan, e$plan)
  rebuilt <- e$helper$study_long_table(saved$planned, saved$submissions, saved$results,
    saved$plan, saved$condition$id, saved$reporting)
  expect_identical(rebuilt, saved$study)
  selected <- do.call(e$helper$study_model_data, c(list(study = rebuilt), saved$selection))
  expect_identical(selected, saved$selected)
  expect_identical(contrasts(selected$data$task), contrasts(e$planned$task))
  expect_identical(levels(selected$data$task), c("description", "argument"))
})

test_that("compound IDs cannot collide across document and request fields", {
  e <- study_example()
  p <- lexdiv_plan(presets = character(), specs = list(
    lexdiv_spec("ttr_v_over_n_v1", request_id = "c"),
    lexdiv_spec("mattr_sliding_step1_v1", list(window_length = 2), "b.c")))
  planned <- data.frame(observation_id = c("001", "002"),
    writer_id = c("01", "02"), task = c("a.b", "a"), occasion = c(0, 0))
  sub <- data.frame(observation_id = planned$observation_id,
    document_id = c("a.b", "a"), input_characters = c(5L, 7L))
  result <- lexdiv_metrics_batch(list("a.b" = c("a", "b", "a"),
    a = c("a", "a", "a", "a")), plan = p)
  joined <- e$helper$study_long_table(planned, sub, result, p, "surface")
  expect_equal(joined$value, c(2/3, 1, 1/4, 1/2))
  expect_identical(joined$document_id, c("a.b", "a.b", "a", "a"))
})

test_that("ordinary lmer input uses exactly the declared model rows", {
  skip_if_not_installed("lme4")
  e <- study_example()
  fit <- lme4::lmer(e$record$model_formula, data = e$selected$data,
    REML = TRUE, na.action = na.fail)
  expect_identical(rownames(stats::model.frame(fit)), e$selected$data$observation_id)
  expect_equal(stats::nobs(fit), 102)
  expect_equal(length(unique(stats::model.frame(fit)$writer_id)), 18)
  expect_true(is.logical(lme4::isSingular(fit)))
})
