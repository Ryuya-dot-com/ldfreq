test_that("tidy token rows become ordered named documents", {
  tidy <- data.frame(
    doc = c("b", "a", "b", "a"),
    word = c("first-b", "first-a", "second-b", "second-a"),
    stringsAsFactors = FALSE
  )
  documents <- lexdiv_as_documents(tidy, "doc", "word")
  expect_identical(names(documents), c("b", "a"))
  expect_identical(documents$b, c("first-b", "second-b"))
  expect_identical(documents$a, c("first-a", "second-a"))

  batch <- lexdiv_metrics_batch(documents, metrics = "ttr")
  expect_identical(batch$document_id, c("b", "a"))
  expect_identical(batch$value, c(1, 1))
})

test_that("named lists retain document boundaries and reject invalid inputs", {
  documents <- list(a = c("a", "a"), b = c("b", "c"))
  expect_identical(lexdiv_as_documents(documents), documents)

  expect_error(lexdiv_as_documents(unname(documents)), "unique, non-empty names")
  expect_error(
    lexdiv_as_documents(data.frame(document_id = "a", token = 1)),
    "plain character token column"
  )
})

test_that("real quanteda tokens retain document boundaries", {
  skip_if_not_installed("quanteda")
  documents <- list(a = c("a", "a"), b = c("b", "c"), empty = character())
  expect_identical(lexdiv_as_documents(quanteda::as.tokens(documents)), documents)
})

test_that("long results widen without recomputation", {
  documents <- list(a = c("a", "a", "b"), b = c("x", "y", "z"))
  long <- lexdiv_metrics_batch(documents, metrics = c("ttr", "maas"))
  wide <- lexdiv_widen(long, values_from = "value")

  expect_s3_class(wide, "lexdiv_wide_results")
  expect_identical(names(wide), c("document_id", "ttr", "maas"))
  expect_identical(wide$document_id, c("a", "b"))
  expect_identical(wide$ttr, long$value[long$metric_id == "ttr"])
  expect_identical(wide$maas, long$value[long$metric_id == "maas"])

  detailed <- lexdiv_widen(long)
  expect_true(all(c(
    "ttr__value", "ttr__status", "ttr__method_id",
    "maas__below_quality_floor"
  ) %in% names(detailed)))
  expect_identical(detailed$ttr__method_id, rep("ttr_v_over_n_v1", 2L))
})

test_that("profile request IDs remain distinct in wide output", {
  plan <- lexdiv_plan("length_50_100")
  profile <- lexdiv_profile_batch(
    list(a = rep(c("a", "b"), 60L)),
    plan
  )
  wide <- lexdiv_widen(profile, values_from = "value")
  expect_true(all(c("msttr", "msttr_100", "mattr", "mattr_100") %in% names(wide)))

  duplicated <- rbind(profile[1L, ], profile[1L, ])
  expect_error(lexdiv_widen(duplicated), "multiple rows")
})

test_that("base plots return their plotted data invisibly", {
  batch <- lexdiv_metrics_batch(
    list(a = c("a", "a", "b"), b = c("x", "y", "z")),
    metrics = c("ttr", "maas")
  )
  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  on.exit({
    grDevices::dev.off()
    unlink(path)
  }, add = TRUE)

  plotted <- plot(batch, metric_id = "ttr")
  expect_identical(plotted$label, c("a", "b"))
  expect_identical(plotted$value, c(2 / 3, 1))
  expect_error(plot(batch), "metric_id must select one")

  text_result <- lexdiv_metrics_text("a a b", metrics = "ttr")
  plotted_text <- plot(text_result)
  expect_identical(plotted_text$label, "ttr")
  expect_identical(plotted_text$value, 2 / 3)
  expect_error(
    plot(structure(list(results = data.frame()), class = "lexdiv_text_results")),
    "lexdiv_text_results object"
  )

  tubelex <- structure(
    list(summary = data.frame(
      weighting = c("token", "type"),
      coverage = c(0.75, 0.5),
      stringsAsFactors = FALSE
    )),
    class = "tubelex_profile"
  )
  coverage <- plot(tubelex)
  expect_identical(coverage$coverage, c(0.75, 0.5))
})
