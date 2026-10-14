test_that("method scopes retain their catalogs and execution boundaries", {
  core <- lexdiv_methods()
  variants <- lexdiv_methods(scope = "variants")
  expect_identical(core, lexdiv_methods(scope = "core"))
  expect_identical(variants, lexdiv_variant_ids())
  expect_identical(intersect(core$method_id, variants$method_id), "maas_a2_ln_v1")
  expect_identical(ncol(core), 10L)
  expect_identical(ncol(variants), 6L)
  variant_only <- setdiff(variants$method_id, core$method_id)[[1L]]
  expect_error(lexdiv_spec(variant_only), "method_id")
  expect_identical(
    lexdiv_variant_metrics(rep("a", 50), variants = variant_only)$method_id,
    variant_only
  )
  expect_error(lexdiv_methods(scope = "all"), "arg")
  expect_error(lexdiv_methods(scope = NA_character_), "arg")
})

test_that("metric plans preserve complete results for every token state", {
  plan <- lexdiv_plan("length_50_100")
  for (tokens in list(rep(c("a", "a", "b"), 40), c("a", "b"),
                      character(), c("a", NA_character_))) {
    expect_identical(lexdiv_metrics(tokens, plan = plan), lexdiv_profile(tokens, plan))
  }
  # The second positional argument keeps its original meaning, and NULL is opt-out.
  expect_identical(lexdiv_metrics(c("a", "b"), "ttr"),
                   lexdiv_metrics(c("a", "b"), metrics = "ttr", plan = NULL))
  for (argument in c("metrics", "segment_length", "window_length",
                     "mtld_threshold", "sample_size", "expected_ttr_sample_sizes")) {
    arguments <- list(tokens = "a", plan = plan)
    arguments[[argument]] <- eval(formals(lexdiv_metrics)[[argument]])
    expect_error(do.call(lexdiv_metrics, arguments), "With plan, omit")
  }
  broken <- plan
  broken$plan_md5 <- "changed"
  expect_error(lexdiv_metrics("a", plan = broken), "integrity")
  expect_error(lexdiv_metrics("a", plan = list()), "plan")
})

test_that("batch plans keep IDs, empty cases, classes and allocation limits", {
  plan <- lexdiv_plan("length_50_100")
  documents <- list(second = rep(c("a", "b"), 60), empty = character(),
                    invalid = c("a", NA_character_))
  result <- lexdiv_metrics_batch(documents, plan = plan)
  expect_identical(result, lexdiv_profile_batch(documents, plan))
  expect_identical(unique(result$document_id), names(documents))
  expect_identical(result$missing_reason[result$document_id == "empty"],
                   rep("empty_input", 13L))
  expect_identical(result$status[result$document_id == "invalid"],
                   rep("invalid_input", 13L))

  frame <- data.frame(id = names(documents))
  frame$words <- unname(documents)
  expect_identical(lexdiv_metrics_batch(frame, "id", "words", plan = plan), result)
  expect_identical(
    lexdiv_metrics_batch(frame, "id", "words", "ttr"),
    lexdiv_metrics_batch(documents, metrics = "ttr", plan = NULL)
  )
  empty <- setNames(list(), character())
  expect_identical(lexdiv_metrics_batch(empty, plan = plan),
                   lexdiv_profile_batch(empty, plan))
  expect_identical(lexdiv_metrics_batch(frame[FALSE, ], "id", "words", plan = plan),
                   lexdiv_profile_batch(empty, plan))
  expect_identical(lexdiv_metrics_batch(documents, plan = plan, max_rows = 39), result)
  expect_error(lexdiv_metrics_batch(documents, plan = plan, max_rows = 38), "max_rows")
  expect_error(lexdiv_metrics_batch(empty, plan = plan, max_rows = 0), "max_rows")
  expect_error(lexdiv_metrics_batch(empty, plan = plan, metrics = "ttr"), "With plan, omit")
  expect_error(lexdiv_metrics_batch(empty, "document_id", "tokens", "ttr", plan = plan),
               "With plan, omit")
  expect_error(lexdiv_metrics_batch(empty, plan = plan, window_length = 50), "With plan, omit")
  expect_error(lexdiv_metrics_batch(empty, max_rows = 10), "requires a non-NULL plan")
  expect_error(lexdiv_metrics_batch(list(a = "x", a = "y"), plan = plan), "unique")

  # Stored plans and full results continue to feed existing reporting methods.
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(list(plan = plan, result = result), path)
  restored <- readRDS(path)
  expect_identical(restored$result, result)
  expect_identical(lexdiv_metrics_batch(documents, plan = restored$plan), result)
  expect_identical(lexdiv_widen(restored$result), lexdiv_widen(result))
})
