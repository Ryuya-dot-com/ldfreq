test_that("basic help examples compute and save results without reference data", {
  withr::local_options(ldfreq.resource_dir = tempfile("absent-reference-cache-"))
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  for (topic in c("lexdiv_as_documents", "lexdiv_widen", "plot.lexdiv_results",
                  "lexdiv_metrics_text_batch")) {
    env <- new.env(parent = globalenv())
    suppressMessages(utils::example(topic, package = "ldfreq", local = env,
      character.only = TRUE, ask = FALSE, echo = FALSE))
    if (topic == "lexdiv_as_documents") {
      expect_identical(env$documents, list(a = c("one", "two"), b = c("three", "three")))
    } else if (topic == "lexdiv_widen") {
      expect_equal(env$wide$mtld__N, c(10L, 0L))
      expect_true(is.na(env$wide$mtld__value[[2L]]))
    } else if (topic == "plot.lexdiv_results") {
      # The default preserves case: "Words" and "words" are distinct.
      expect_equal(env$text_result$results$value, 1)
      expect_false(exists("profile", envir = env, inherits = FALSE))
    } else {
      expect_identical(env$restored$texts, env$texts)
      expect_identical(env$restored$analysis, env$result)
      expect_equal(env$result$results$value, c(.8, 1, NA_real_))
      expect_identical(env$with_study$metadata$document_id, c("essay_a", "essay_b", "empty"))
    }
    expect_false(dir.exists(getOption("ldfreq.resource_dir")))
  }
})
