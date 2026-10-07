test_that("bundled TUBELEX retains UTF-8 words under C LC_CTYPE", {
  previous <- Sys.getlocale("LC_CTYPE")
  on.exit(Sys.setlocale("LC_CTYPE", previous), add = TRUE)
  selected <- suppressWarnings(Sys.setlocale("LC_CTYPE", "C"))
  skip_if(!identical(selected, "C"), "C LC_CTYPE is unavailable")

  terms <- c("the", "cat", "caf\u00e9")
  result <- tubelex_profile(terms)
  expect_identical(result$status, "ok")
  expect_true(all(result$lookup$matched))
  expect_identical(result$lookup$count, c(7448605, 8983, 244))
  expect_identical(charToRaw(result$lookup$resource_word[[3]]),
    as.raw(c(0x63, 0x61, 0x66, 0xc3, 0xa9)))
  expect_identical(result$lookup$term, terms)
  expect_identical(nj8_profile(c("the", "cat"))$status, "ok")
})

test_that("schema failure printing suggests encoding checks without changing the reason", {
  previous <- Sys.getlocale("LC_CTYPE")
  on.exit(Sys.setlocale("LC_CTYPE", previous), add = TRUE)
  selected <- suppressWarnings(Sys.setlocale("LC_CTYPE", "C"))
  skip_if(!identical(selected, "C"), "C LC_CTYPE is unavailable")
  result <- ldfreq:::.tubelex_profile("the", "identity", loader = function() list(
    status = "resource_error", failure_reason = "schema_mismatch",
    resource_ref = ldfreq:::.lexres_resource_ref(ldfreq:::.lexres_tubelex_expectation()),
    diagnostics = list(fallback_attempted = FALSE, download_attempted = FALSE,
      schema_violations = "word_format"),
    manifest = NULL, resource = NULL
  ))
  output <- paste(capture.output(print(result)), collapse = "\n")
  expect_match(output, "schema_mismatch")
  expect_match(output, "word_format")
  expect_match(output, "LC_CTYPE = C", fixed = TRUE)
  expect_match(output, "non-UTF-8 locale", fixed = TRUE)
  expect_identical(result$failure_reason, "schema_mismatch")
  expect_true(all(is.na(result$lookup$count)))
})
