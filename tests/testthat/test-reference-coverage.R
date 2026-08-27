test_that("reference coverage separates token and type denominators", {
  result <- lexdiv_reference_coverage(
    list(
      repeated = c("cat", "cat", "dog"),
      other = c("bird", "unknown")
    ),
    reference = c("cat", "bird"),
    reference_id = "list"
  )

  expect_s3_class(result, "lexdiv_reference_coverage")
  expect_identical(
    result$summary$document_id,
    rep(c("repeated", "other"), each = 2L)
  )
  expect_identical(
    result$summary$weighting,
    rep(c("token", "type"), times = 2L)
  )
  expect_equal(result$summary$value, c(2 / 3, 1 / 2, 1 / 2, 1 / 2))
  expect_identical(result$summary$numerator, c(2, 1, 1, 1))
  expect_identical(result$summary$denominator, c(3, 2, 2, 2))
  expect_identical(result$summary$matched_tokens, c(2, 2, 1, 1))
  expect_identical(result$summary$matched_types, c(1, 1, 1, 1))
  expect_true(all(result$summary$status == "ok"))
  expect_true(all(is.na(result$summary$missing_reason)))
  expect_identical(
    result$summary$measure_id,
    rep(c("reference_coverage_tokens", "reference_coverage_types"), 2L)
  )
  expect_true(all(
    result$summary$reference_coverage_contract_id ==
      "ldfreq-reference-coverage"
  ))
  expect_true(all(
    result$summary$result_schema_id == "lexdiv-reference-coverage-result"
  ))
})

test_that("reference membership is exact and independent of reference repetition", {
  documents <- list(doc = c("Cat", "cat", "cafe", "caf\u00e9", "cat"))
  once <- lexdiv_reference_coverage(documents, c("cat", "caf\u00e9"))
  repeated <- lexdiv_reference_coverage(
    documents,
    c("cat", "cat", "caf\u00e9", "caf\u00e9")
  )

  expect_identical(once$summary$value, repeated$summary$value)
  expect_identical(once$summary$numerator, c(3, 2))
  expect_identical(once$summary$denominator, c(5, 4))
  expect_identical(once$reference$input_tokens, 2)
  expect_identical(repeated$reference$input_tokens, 4)
  expect_identical(once$reference$input_types, repeated$reference$input_types)
})

test_that("named-list and explicit data-frame inputs are identical", {
  documents <- list(
    zeta = c("a", "b", "a"),
    alpha = c("b", "c")
  )
  frame <- data.frame(id = names(documents), stringsAsFactors = FALSE)
  frame$units <- unname(documents)

  from_list <- lexdiv_reference_coverage(documents, c("a", "b"))
  from_frame <- lexdiv_reference_coverage(
    frame,
    c("a", "b"),
    id_col = "id",
    terms_col = "units"
  )
  expect_identical(from_frame, from_list)
})

test_that("empty and invalid document states remain explicit and local", {
  documents <- list(
    empty = character(),
    invalid_missing = c("a", NA_character_),
    invalid_type = 1:2,
    valid = c("a", "b")
  )
  result <- lexdiv_reference_coverage(documents, "a")

  empty <- result$summary$document_id == "empty"
  invalid_missing <- result$summary$document_id == "invalid_missing"
  invalid_type <- result$summary$document_id == "invalid_type"
  valid <- result$summary$document_id == "valid"
  expect_true(all(result$summary$status[empty] == "missing"))
  expect_true(all(result$summary$missing_reason[empty] == "empty_document"))
  expect_true(all(is.na(result$summary$value[empty])))
  expect_true(all(result$summary$status[invalid_missing] == "invalid_input"))
  expect_true(all(result$summary$status[invalid_type] == "invalid_input"))
  expect_true(all(
    result$summary$missing_reason[invalid_missing | invalid_type] ==
      "invalid_document"
  ))
  expect_true(all(is.na(result$summary$denominator[invalid_missing | invalid_type])))
  expect_identical(result$summary$value[valid], c(1 / 2, 1 / 2))
  expect_identical(
    result$documents$state,
    c("empty", "invalid", "invalid", "ok")
  )
})

test_that("empty and invalid references follow directional coverage rules", {
  documents <- list(empty = character(), valid = c("a", "b"))
  empty_reference <- lexdiv_reference_coverage(documents, character())
  expect_identical(empty_reference$reference$state, "empty")
  expect_true(all(is.na(empty_reference$summary$value[1:2])))
  expect_identical(empty_reference$summary$value[3:4], c(0, 0))
  expect_true(all(empty_reference$summary$status[3:4] == "ok"))

  invalid_reference <- lexdiv_reference_coverage(documents, c("a", NA_character_))
  expect_identical(invalid_reference$reference$state, "invalid")
  expect_true(all(invalid_reference$summary$status == "invalid_input"))
  expect_identical(
    invalid_reference$summary$missing_reason,
    rep("invalid_reference", 4L)
  )

  both_invalid <- lexdiv_reference_coverage(
    list(doc = c("a", NA_character_)),
    c("a", NA_character_)
  )
  expect_identical(
    both_invalid$summary$missing_reason,
    rep("invalid_document_and_reference", 2L)
  )
})

test_that("empty document containers return typed empty tables", {
  result <- lexdiv_reference_coverage(setNames(list(), character()), "a", max_rows = 1)
  expect_s3_class(result, "lexdiv_reference_coverage")
  expect_identical(nrow(result$summary), 0L)
  expect_identical(nrow(result$documents), 0L)
  expect_identical(nrow(result$reference), 1L)
  expect_identical(nrow(result$terms), 0L)
  expect_identical(names(result$summary), names(ldfreq:::`.lexref_empty_summary`()))
})

test_that("term detail is opt-in, deterministic, and analysis-ready", {
  documents <- list(
    first = c("b", "a", "b"),
    second = c("c", "a")
  )
  counts <- lexdiv_reference_coverage(documents, c("a", "b", "b"))
  detailed <- lexdiv_reference_coverage(
    documents,
    c("a", "b", "b"),
    reference_id = "wordlist",
    details = "terms"
  )

  expect_identical(nrow(counts$terms), 0L)
  expect_false(counts$provenance$contains_lexical_terms)
  expect_identical(
    detailed$terms$term,
    c("a", "b", "a", "c")
  )
  expect_identical(detailed$terms$document_token_count, c(1, 2, 1, 1))
  expect_identical(detailed$terms$reference_token_count, c(1, 2, 1, 0))
  expect_identical(detailed$terms$matched, c(TRUE, TRUE, TRUE, FALSE))
  expect_true(detailed$provenance$contains_lexical_terms)
  expect_output(print(detailed), "Lexical term details retained")
})

test_that("the row bound covers all returned tables", {
  documents <- list(a = c("a", "b"), b = "c")
  # 4 summary + 2 document + 1 reference rows.
  expect_silent(lexdiv_reference_coverage(documents, "a", max_rows = 7))
  expect_error(
    lexdiv_reference_coverage(documents, "a", max_rows = 6),
    "exceeds max_rows"
  )
  # Term details add three rows.
  expect_silent(lexdiv_reference_coverage(
    documents,
    "a",
    details = "terms",
    max_rows = 10
  ))
  expect_error(
    lexdiv_reference_coverage(
      documents,
      "a",
      details = "terms",
      max_rows = 9
    ),
    "exceeds max_rows"
  )
})

test_that("structural requests and identifiers fail closed", {
  expect_error(lexdiv_reference_coverage(list("a"), "a"), "plain named list")
  expect_error(
    lexdiv_reference_coverage(list(reference = "a"), "a"),
    "must be distinct"
  )
  expect_error(
    lexdiv_reference_coverage(list("private/file" = "a"), "a"),
    "path-free"
  )
  expect_error(
    lexdiv_reference_coverage(list(doc = "a"), "a", reference_id = "/tmp/list"),
    "path-free"
  )
  expect_error(
    lexdiv_reference_coverage(list(doc = "a"), "a", details = "all"),
    "details"
  )
  expect_error(
    lexdiv_reference_coverage(list(doc = "a"), "a", max_rows = 0),
    "max_rows"
  )
  expect_error(
    lexdiv_reference_coverage(
      data.frame(document_id = "a", terms = "a"),
      "a"
    ),
    "list-column"
  )
  expect_error(
    lexdiv_reference_coverage(
      data.frame(document_id = "a"),
      "a",
      id_col = "document_id",
      terms_col = "document_id"
    ),
    "different columns"
  )
})

test_that("likely raw prose warns but exact multiword terms remain supported", {
  expect_warning(
    lexdiv_reference_coverage(list(doc = "raw prose here"), "token"),
    "one string with whitespace"
  )
  expect_warning(
    lexdiv_reference_coverage(list(doc = "token"), "raw prose here"),
    "one string with whitespace"
  )
  expect_warning(
    result <- lexdiv_reference_coverage(
      list(doc = c("ice cream", "shop")),
      c("ice cream", "store")
    ),
    NA
  )
  expect_identical(result$summary$numerator, c(1, 1))
})

test_that("randomized values equal direct exact-membership formulas", {
  set.seed(20260827)
  alphabet <- c("a", "b", "c", "d", "e")
  for (iteration in seq_len(100L)) {
    document <- sample(alphabet, sample(1:30, 1L), replace = TRUE)
    reference <- sample(alphabet, sample(0:10, 1L), replace = TRUE)
    result <- lexdiv_reference_coverage(list(doc = document), reference)
    expected <- c(
      sum(document %in% unique(reference)) / length(document),
      sum(unique(document) %in% unique(reference)) / length(unique(document))
    )
    expect_equal(result$summary$value, expected)
  }
})

test_that("installed reference coverage contract matches the implementation", {
  skip_if_not_installed("jsonlite")
  contract_path <- system.file(
    "spec", "reference-coverage-contract.json", package = "ldfreq"
  )
  schema_path <- system.file(
    "spec", "reference-coverage-contract.schema.json", package = "ldfreq"
  )
  expect_true(nzchar(contract_path) && file.exists(contract_path))
  expect_true(nzchar(schema_path) && file.exists(schema_path))
  contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
  schema <- jsonlite::read_json(schema_path, simplifyVector = FALSE)
  result <- lexdiv_reference_coverage(list(doc = c("a", "b")), "a")

  expect_identical(contract$contract_id, result$provenance$contract_id)
  expect_identical(contract$contract_version, result$provenance$contract_version)
  expect_identical(
    contract$result_contract$schema_id,
    result$provenance$result_schema_id
  )
  expect_identical(
    unlist(contract$result_contract$components, use.names = FALSE),
    names(result)
  )
  expect_identical(
    unlist(contract$result_contract$summary_columns, use.names = FALSE),
    names(result$summary)
  )
  expect_identical(
    unlist(contract$result_contract$document_columns, use.names = FALSE),
    names(result$documents)
  )
  expect_identical(
    unlist(contract$result_contract$reference_columns, use.names = FALSE),
    names(result$reference)
  )
  expect_identical(
    unlist(contract$result_contract$term_columns, use.names = FALSE),
    names(result$terms)
  )
  expect_identical(
    vapply(contract$measures, `[[`, character(1L), "measure_id"),
    result$summary$measure_id
  )
  expect_identical(
    vapply(contract$measures, `[[`, character(1L), "method_id"),
    result$summary$method_id
  )
  expect_identical(contract$privacy_boundary$term_details_opt_in, TRUE)
  expect_identical(contract$privacy_boundary$text_hash_copied_to_result, FALSE)
  expect_identical(schema$properties$contract_id$const, contract$contract_id)
  expect_identical(
    unlist(
      schema$properties$result_contract$properties$components$const,
      use.names = FALSE
    ),
    names(result)
  )
})

test_that("print and plot preserve reusable values", {
  result <- lexdiv_reference_coverage(
    list(a = c("a", "a", "b"), empty = character(), b = c("b", "c")),
    "a"
  )
  printed <- capture.output(visible <- withVisible(print(result)))
  expect_true(any(grepl("lexdiv_reference_coverage", printed, fixed = TRUE)))
  expect_false(visible$visible)
  expect_identical(visible$value, result)

  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  on.exit({
    grDevices::dev.off()
    unlink(path)
  }, add = TRUE)

  plot_data <- plot(result, weighting = "type")
  expect_identical(plot_data$document_id, c("a", "b"))
  expect_identical(plot_data$value, c(1 / 2, 0))
  expect_identical(plot_data$numerator, c(1, 0))
  expect_identical(plot_data$denominator, c(2, 2))
  expect_identical(plot_data$position, c(1, 2))
  expect_error(plot(result, weighting = "both"), "weighting")
  expect_error(
    plot(lexdiv_reference_coverage(list(empty = character()), "a")),
    "no finite ok values"
  )
})
