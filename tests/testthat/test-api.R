api_function <- getFromNamespace("lexdiv_metrics", "ldfreq")
metric_ids_function <- getFromNamespace("lexdiv_metric_ids", "ldfreq")

test_that("the public API emits the complete result contract", {
  result <- api_function(c("a", "a", "b", "c"))

  expect_s3_class(result, "lexdiv_results")
  expect_identical(result$metric_id, metric_ids_function())
  expect_identical(
    names(result),
    c(
      "metric_id", "method_id", "metric_contract_id",
      "metric_contract_version", "result_schema_id", "result_schema_version",
      "value", "status", "missing_reason",
      "requested_parameters", "effective_parameters", "N", "V",
      "below_quality_floor", "diagnostics"
    )
  )
  expect_identical(attr(result, "contract_id"), "ldfreq-lexical-diversity-core")
  expect_identical(attr(result, "contract_version"), "0.1.0-draft.5")
  expect_identical(attr(result, "result_schema_id"), "lexdiv-core-metric-result")
  expect_identical(attr(result, "result_schema_version"), "0.1.0-draft.1")
  expect_true(all(result$metric_contract_id == "ldfreq-lexical-diversity-core"))
  expect_true(all(result$metric_contract_version == "0.1.0-draft.5"))
  expect_true(all(result$result_schema_id == "lexdiv-core-metric-result"))
  expect_true(all(result$result_schema_version == "0.1.0-draft.1"))
  expect_true(all(vapply(result$requested_parameters, is.list, logical(1L))))
  expect_true(all(vapply(result$effective_parameters, is.list, logical(1L))))
  expect_true(all(vapply(result$diagnostics, is.list, logical(1L))))
})

test_that("the core preserves exact token distinctions", {
  canonically_distinct <- api_function(
    c("\u00e9", "e\u0301"),
    metrics = "ttr"
  )
  case_distinct <- api_function(c("A", "a"), metrics = "ttr")
  unknown_marker <- "\u00e9"
  Encoding(unknown_marker) <- "unknown"
  utf8_marker <- enc2utf8(unknown_marker)
  marker_equivalent <- api_function(
    c(unknown_marker, utf8_marker),
    metrics = "ttr"
  )

  expect_identical(canonically_distinct$value, 1)
  expect_identical(canonically_distinct$V, 2)
  expect_identical(case_distinct$value, 1)
  expect_identical(case_distinct$V, 2)
  expect_identical(marker_equivalent$value, 0.5)
  expect_identical(marker_equivalent$V, 1)
})

test_that("UTF-8 marker equivalence is independent of the C locale", {
  previous_locale <- Sys.getlocale("LC_CTYPE")
  on.exit(Sys.setlocale("LC_CTYPE", previous_locale), add = TRUE)
  selected_locale <- suppressWarnings(Sys.setlocale("LC_CTYPE", "C"))
  skip_if(!identical(selected_locale, "C"), "C LC_CTYPE is unavailable")

  unknown_marker <- rawToChar(as.raw(c(0xc3, 0xa9)))
  Encoding(unknown_marker) <- "unknown"
  utf8_marker <- unknown_marker
  Encoding(utf8_marker) <- "UTF-8"
  expect_true(all(validUTF8(c(unknown_marker, utf8_marker))))

  result <- api_function(c(unknown_marker, utf8_marker), metrics = "ttr")
  expect_identical(result$V, 1)
  expect_identical(result$value, 0.5)
  expect_identical(Encoding(unknown_marker), "unknown")
})

test_that("invalid and empty token input follow precedence rules", {
  invalid_na <- api_function(c("a", NA_character_))
  invalid_empty_token <- api_function(c("a", ""))
  invalid_type <- api_function(factor(c("a", "b")))
  invalid_classed_character <- api_function(
    structure(c("a", "a", "b"), class = "adversarial_character")
  )
  invalid_matrix <- api_function(matrix(c("a", "b"), nrow = 1L))
  invalid_utf8_token <- rawToChar(as.raw(255L))
  Encoding(invalid_utf8_token) <- "bytes"
  invalid_utf8 <- api_function(c("a", invalid_utf8_token))
  valid_bytes_marked_token <- enc2utf8("\u00e9")
  Encoding(valid_bytes_marked_token) <- "bytes"
  invalid_bytes_marker <- api_function(c("a", valid_bytes_marked_token))
  latin1_token <- iconv("\u00e9", from = "UTF-8", to = "latin1")
  Encoding(latin1_token) <- "latin1"
  invalid_latin1_marker <- api_function(c("a", latin1_token))
  empty_document <- api_function(character())

  for (result in list(
    invalid_na,
    invalid_empty_token,
    invalid_type,
    invalid_classed_character,
    invalid_matrix,
    invalid_utf8,
    invalid_bytes_marker,
    invalid_latin1_marker
  )) {
    expect_true(all(result$status == "invalid_input"))
    expect_true(all(result$missing_reason == "invalid_token"))
    expect_true(all(is.na(result$N)))
    expect_true(all(is.na(result$V)))
  }
  expect_true(all(empty_document$status == "missing"))
  expect_true(all(empty_document$missing_reason == "empty_input"))
  expect_true(all(empty_document$N == 0))
  expect_true(all(empty_document$V == 0))
  expected_mtld_diagnostics <- c(
    "forward_score",
    "reverse_score",
    "forward_complete_factors",
    "reverse_complete_factors",
    "forward_tail_credit",
    "reverse_tail_credit"
  )
  invalid_mtld <- invalid_na$diagnostics[[which(invalid_na$metric_id == "mtld")]]
  empty_mtld <- empty_document$diagnostics[[which(empty_document$metric_id == "mtld")]]
  expect_identical(names(invalid_mtld), expected_mtld_diagnostics)
  expect_identical(names(empty_mtld), expected_mtld_diagnostics)
  expect_true(all(vapply(invalid_mtld, is.na, logical(1L))))
  expect_true(all(vapply(empty_mtld, is.na, logical(1L))))
})

test_that("metric selection is strict and parameters are metric-local", {
  expect_error(api_function(c("a"), metrics = character()), "non-empty")
  expect_error(api_function(c("a"), metrics = c("ttr", "ttr")), "duplicates")
  expect_error(api_function(c("a"), metrics = "expected_ttr_d"), "non-frozen")
  expect_error(
    api_function(
      c("a"),
      metrics = structure("ttr", class = "adversarial_metric_id")
    ),
    "metrics must"
  )
  expect_error(
    api_function(
      rep("a", 10L),
      metrics = "mtld",
      mtld_threshold = structure(0.72, class = "adversarial_threshold")
    ),
    "strictly between"
  )
  expect_error(
    api_function(
      rep("a", 10L),
      metrics = "mtld",
      mtld_threshold = matrix(0.72, nrow = 1L)
    ),
    "strictly between"
  )
  expect_error(
    api_function(
      c("a", "a"),
      metrics = "hdd",
      sample_size = matrix(2, nrow = 1L)
    ),
    "sample_size"
  )
  expect_error(
    api_function(
      c("a", NA_character_),
      metrics = "msttr",
      segment_length = 0
    ),
    "segment_length"
  )

  ttr_only <- api_function(c("a"), metrics = "ttr", segment_length = 0)
  expect_identical(ttr_only$status, "ok")
})

test_that("short requested parameters are explicit rather than resized", {
  result <- api_function(
    c("a", "b", "c"),
    metrics = c("msttr", "mattr", "hdd"),
    segment_length = 4,
    window_length = 4,
    sample_size = 4
  )

  expect_true(all(result$status == "missing"))
  expect_true(all(result$missing_reason == "too_short_for_requested_parameter"))
  expect_identical(result$requested_parameters[[1L]], list(segment_length = 4))
  expect_identical(result$effective_parameters[[1L]], list())
})

test_that("the result print method returns invisibly", {
  result <- api_function(c("a", "b"), metrics = "ttr")
  printed <- capture.output(returned <- withVisible(print(result)))

  expect_true(length(printed) > 0L)
  expect_false(returned$visible)
  expect_identical(returned$value, result)
})

test_that("row-level contract provenance survives common transformations", {
  first <- api_function(c("a", "b"), metrics = "ttr")
  second <- api_function(c("a", "a"), metrics = "ttr")
  combined <- rbind(first, second)

  expect_identical(
    combined$metric_contract_version,
    rep("0.1.0-draft.5", 2L)
  )
  expect_identical(
    combined$result_schema_version,
    rep("0.1.0-draft.1", 2L)
  )

  rds_path <- tempfile(fileext = ".rds")
  csv_path <- tempfile(fileext = ".csv")
  on.exit(unlink(c(rds_path, csv_path), force = TRUE), add = TRUE)
  saveRDS(combined, rds_path)
  restored <- readRDS(rds_path)
  expect_identical(restored$metric_contract_id, combined$metric_contract_id)

  atomic_provenance <- combined[c(
    "metric_id", "metric_contract_id", "metric_contract_version",
    "result_schema_id", "result_schema_version"
  )]
  write.csv(atomic_provenance, csv_path, row.names = FALSE)
  csv_restored <- read.csv(csv_path, stringsAsFactors = FALSE)
  expect_identical(
    csv_restored$metric_contract_version,
    combined$metric_contract_version
  )
})
