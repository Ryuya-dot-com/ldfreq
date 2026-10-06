response_example <- function() {
  data.frame(learner_id = rep("example", 8), item_id = paste0("i", 1:8),
    recognition = c(1, 1, 1, 0, 0, NA, 1, NA),
    recall = c(1, 1, 0, 1, 0, 0, NA, NA),
    rubric_version = "authored-v1", missing_reason = c(rep(NA_character_, 5),
      "not-administered", "lost-response", "absent"))
}

test_that("binary comparisons retain directions, denominators and raw metadata", {
  data <- response_example()
  original <- data
  result <- lexdiv_compare_responses(data, "recognition", "recall")
  expect_identical(data, original)
  expect_identical(result$responses[names(data)], data)
  expect_identical(result$counts$n, c(2L, 1L, 1L, 1L, 1L, 1L, 1L))
  expect_equal(result$summary$numerator, c(3, 1, 1, 1, 5))
  expect_equal(result$summary$denominator, c(5, 5, 5, 3, 8))
  expect_equal(result$summary$proportion, c(3/5, 1/5, 1/5, 1/3, 5/8))
  expect_identical(result$responses$comparison_outcome,
    c("both_correct", "both_correct", "test_only", "criterion_only",
      "both_incorrect", "missing_test", "missing_criterion", "missing_both"))
  expect_identical(result$provenance$test, "recognition")
  expect_identical(result$provenance$criterion, "recall")
  swapped <- lexdiv_compare_responses(data, "recall", "recognition")
  expect_identical(swapped$counts$n, result$counts$n[c(1, 3, 2, 4, 6, 5, 7)])
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(result, path)
  expect_identical(readRDS(path), result)
})

test_that("grouping retains missing strata and requires explicit repetition keys", {
  data <- rbind(transform(response_example(), occasion_id = "post"),
    transform(response_example(), occasion_id = "pre"))
  expect_error(lexdiv_compare_responses(data, "recognition", "recall", by = "occasion_id"),
    "jointly identify unique")
  result <- lexdiv_compare_responses(data, "recognition", "recall",
    keys = c("learner_id", "item_id", "occasion_id"), by = "occasion_id")
  expect_identical(unique(result$counts$occasion_id), c("post", "pre"))
  expect_identical(result$counts$n, rep(c(2L, 1L, 1L, 1L, 1L, 1L, 1L), 2))
  data <- response_example()
  data$format <- factor(c("MC", "MC", rep(NA, 6)), levels = c("unused", "MC"))
  result <- lexdiv_compare_responses(data, "recognition", "recall", by = "format")
  expect_equal(nrow(result$counts), 14)
  expect_true(all(is.na(result$counts$format[8:14])))
  expect_equal(sum(result$counts$n), nrow(data))
  expect_identical(result$responses$format, data$format)
})

test_that("composite text IDs cannot collide through delimiters or word forms", {
  data <- response_example()[1:3, ]
  data$learner_id <- c("a:b", "a", "\u5b66\u7fd2\u8005")
  data$item_id <- c("c", "b:c", "\u8a9e\u7fa9")
  data$target_form <- "bank"
  result <- lexdiv_compare_responses(data, "recognition", "recall",
    by = c("learner_id", "item_id"))
  expect_equal(nrow(result$counts), 21)
  expect_equal(sum(result$counts$n), 3)
  data$item_id <- factor(data$item_id)
  expect_no_error(lexdiv_compare_responses(data, "recognition", "recall"))
})

test_that("zero denominators and empty data remain explicit", {
  data <- response_example()
  data$recognition[] <- NA
  data$recall[] <- NA
  result <- lexdiv_compare_responses(data, "recognition", "recall")
  expect_identical(result$counts$n, c(rep(0L, 6), 8L))
  expect_equal(result$summary$denominator, c(0, 0, 0, 0, 8))
  expect_equal(result$summary$proportion, c(rep(NA_real_, 4), 0))
  data$recognition[] <- 0
  data$recall[] <- 1
  result <- lexdiv_compare_responses(data, "recognition", "recall")
  expect_true(is.na(result$summary$proportion[4]))
  empty <- lexdiv_compare_responses(data[FALSE, ], "recognition", "recall")
  expect_identical(empty$counts$n, rep(0L, 7))
  expect_true(all(is.na(empty$summary$proportion)))
  grouped <- lexdiv_compare_responses(data[FALSE, ], "recognition", "recall", by = "rubric_version")
  expect_equal(nrow(grouped$counts), 0)
  expect_equal(nrow(grouped$summary), 0)
})

test_that("invalid scores and pair identities are rejected without recoding", {
  data <- response_example()
  for (score in list(0.5, -1, 2, Inf, NaN, "1", factor("1"))) {
    bad <- data
    bad$recognition <- rep(score, nrow(bad))
    expect_error(lexdiv_compare_responses(bad, "recognition", "recall"), "Score column")
  }
  logical <- data
  logical$recognition <- as.logical(logical$recognition)
  expect_identical(lexdiv_compare_responses(logical, "recognition", "recall")$counts,
    lexdiv_compare_responses(data, "recognition", "recall")$counts)
  for (id in c("", "  ", NA_character_)) {
    bad <- data
    bad$item_id[1] <- id
    expect_error(lexdiv_compare_responses(bad, "recognition", "recall"), "labels")
  }
  expect_error(lexdiv_compare_responses(rbind(data, data[1, ]), "recognition", "recall"), "unique pairs")
  expect_error(lexdiv_compare_responses(data, "recognition", "recognition"), "distinct")
  expect_error(lexdiv_compare_responses(data, "recognition", "absent"), "must exist")
  expect_error(lexdiv_compare_responses(data, "recognition", "recall", keys = character()), "keys")
  expect_error(lexdiv_compare_responses(data, "recognition", "recall", by = c("item_id", "item_id")), "by")
  expect_error(lexdiv_compare_responses(data, "recognition", "recall", keys = "recognition"), "Score columns")
  bad <- data
  bad$comparison_outcome <- "old"
  expect_error(lexdiv_compare_responses(bad, "recognition", "recall"), "conflicts")
  bad <- data
  names(bad)[2] <- names(bad)[1]
  expect_error(lexdiv_compare_responses(bad, "recognition", "recall"), "unique column names")
})
