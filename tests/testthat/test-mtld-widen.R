test_that("optional MTLD columns expose support and directional sensitivity", {
  x <- lexdiv_metrics_batch(list(
    asymmetric = c(letters[1:8], "a", "a"),
    tails = c(letters[1:8], "a", "b"), closed = rep("a", 50),
    unique = letters, empty = character(), invalid = NA_character_
  ), metrics = c("ttr", "mtld"))
  before <- serialize(x, NULL)
  default <- lexdiv_widen(x)
  expect_identical(default, lexdiv_widen(x, mtld_diagnostics = FALSE))
  wide <- lexdiv_widen(x, mtld_diagnostics = TRUE)
  for (field in names(default)) expect_identical(wide[[field]], default[[field]])
  fields <- c("forward_score", "reverse_score", "forward_complete_factors",
    "reverse_complete_factors", "forward_tail_credit", "reverse_tail_credit",
    "tail_only", "gap_pct")
  expect_identical(setdiff(names(wide), names(default)), paste0("mtld__", fields))
  expect_equal(wide$mtld__forward_score, c(14, 14, 2, NA, NA, NA))
  expect_equal(wide$mtld__reverse_score, c(10, 14, 2, NA, NA, NA))
  expect_equal(wide$mtld__forward_complete_factors, c(0, 0, 25, 0, NA, NA))
  expect_equal(wide$mtld__reverse_complete_factors, c(1, 0, 25, 0, NA, NA))
  expect_equal(wide$mtld__forward_tail_credit, c(5/7, 5/7, 0, 0, NA, NA))
  expect_equal(wide$mtld__reverse_tail_credit, c(0, 5/7, 0, 0, NA, NA))
  expect_identical(wide$mtld__tail_only, c(TRUE, TRUE, FALSE, NA, NA, NA))
  expect_equal(wide$mtld__gap_pct, c(100/3, 0, 0, NA, NA, NA))
  expect_identical(serialize(x, NULL), before)
  single <- lexdiv_widen(x, values_from = "value", mtld_diagnostics = TRUE)
  expect_identical(names(single)[1:3], c("document_id", "ttr", "mtld"))
  expect_identical(single$mtld, wide$mtld__value)
  expect_false(any(vapply(single, is.list, logical(1))))
  expect_identical(lexdiv_widen(x[0, ], mtld_diagnostics = TRUE), default[0, "document_id", drop = FALSE])
})

test_that("saved legacy MTLD and incomplete diagnostics are not recomputed", {
  old <- readRDS(test_path("..", "fixtures", "external-metrics", "legacy-core-0.1.0.rds"))$results
  before <- serialize(old, NULL)
  wide <- lexdiv_widen(old, mtld_diagnostics = TRUE)
  expect_identical(wide$mtld__value, old$value)
  expect_identical(wide$mtld__method_id, old$method_id)
  for (field in c("forward_score", "reverse_score", "forward_complete_factors",
                 "reverse_complete_factors", "forward_tail_credit", "reverse_tail_credit")) {
    expected <- vapply(old$diagnostics, function(d) {
      if (is.null(d[[field]])) NA_real_ else as.numeric(d[[field]])
    }, numeric(1))
    expect_equal(wide[[paste0("mtld__", field)]], expected)
  }
  expect_identical(serialize(old, NULL), before)
  x <- lexdiv_metrics(rep("a", 50), metrics = "mtld")
  x$diagnostics[[1]] <- list(forward_score = 2, forward_complete_factors = 25,
    reverse_score = c(2, 2), reverse_complete_factors = "25")
  partial <- lexdiv_widen(x, mtld_diagnostics = TRUE)
  expect_equal(partial$mtld__forward_score, 2)
  expect_true(is.na(partial$mtld__reverse_score))
  expect_true(is.na(partial$mtld__reverse_complete_factors))
  expect_true(is.na(partial$mtld__tail_only))
  x$diagnostics <- NULL
  absent <- lexdiv_widen(x, mtld_diagnostics = TRUE)
  expect_true(all(is.na(absent[grepl("__(forward|reverse|tail_only|gap_pct)", names(absent))])))
  expect_equal(absent$mtld__value, 2)
})

test_that("MTLD diagnostics preserve specification and name guards", {
  method <- "mtld_seq_bidir_dirmean_lt_nomin_linear_tail_v1"
  plan <- lexdiv_plan(presets = character(), specs = list(
    lexdiv_spec(method, parameters = list(threshold = .72), request_id = "standard"),
    lexdiv_spec(method, parameters = list(threshold = .5), request_id = "lower")
  ))
  x <- lexdiv_profile_batch(list(a = rep(c("a", "b"), 25)), plan)
  wide <- lexdiv_widen(x, values_from = "value", mtld_diagnostics = TRUE)
  expect_equal(wide$standard__forward_complete_factors, 16)
  expect_equal(wide$lower__forward_complete_factors, 10)
  x$request_id <- "same"
  expect_error(lexdiv_widen(x, mtld_diagnostics = TRUE), "different measurement")
  separate <- lexdiv_widen(x, names_from = "specification_id", mtld_diagnostics = TRUE)
  expect_equal(sum(grepl("__tail_only$", names(separate))), 2)
  x <- lexdiv_metrics(rep("a", 50), metrics = c("mtld", "ttr"))
  x$request_id <- c("mtld", "mtld__gap_pct")
  expect_error(lexdiv_widen(x, values_from = "value", mtld_diagnostics = TRUE), "collide")
  x$mtld__gap_pct <- "id"
  expect_error(lexdiv_widen(x, id_cols = "mtld__gap_pct", mtld_diagnostics = TRUE), "collide")
  expect_error(lexdiv_widen(rbind(x[1, ], x[1, ]), mtld_diagnostics = TRUE), "multiple rows")
  for (bad in list(NA, 1, "TRUE", logical(), c(TRUE, FALSE))) {
    expect_error(lexdiv_widen(x, mtld_diagnostics = bad), "must be TRUE or FALSE")
  }
  x <- lexdiv_metrics(rep("a", 50), metrics = "ttr")
  expect_identical(names(lexdiv_widen(x, mtld_diagnostics = TRUE)), names(lexdiv_widen(x)))
  x <- lexdiv_metrics(rep("a", 50), metrics = "mtld")
  x$method_id <- "unrecognized_method"
  expect_identical(names(lexdiv_widen(x, mtld_diagnostics = TRUE)), names(lexdiv_widen(x)))
})

test_that("scalar diagnostic tables survive CSV and complete RDS round trips", {
  x <- lexdiv_metrics_batch(list("001" = rep("a", 50), "002" = character()), metrics = "mtld")
  wide <- lexdiv_widen(x, values_from = c("value", "status"), mtld_diagnostics = TRUE)
  path <- tempfile()
  on.exit(unlink(path))
  saveRDS(list(original = x, wide = wide), path)
  expect_identical(readRDS(path), list(original = x, wide = wide))
  utils::write.csv(wide, path, row.names = FALSE, na = "")
  plain <- as.data.frame(wide)
  restored <- utils::read.csv(path, colClasses = vapply(plain, typeof, character(1)),
    na.strings = "", check.names = FALSE)
  expect_identical(names(restored), names(plain))
  for (field in names(plain)) expect_equal(restored[[field]], plain[[field]])
})
