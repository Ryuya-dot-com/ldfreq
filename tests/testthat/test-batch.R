batch_function <- getFromNamespace("lexdiv_metrics_batch", "ldfreq")
single_function <- getFromNamespace("lexdiv_metrics", "ldfreq")

test_that("named-list batches preserve document and metric order", {
  documents <- list(
    second = c("a", "a", "b", "c"),
    first = c("x", "y", "x", "z")
  )
  metrics <- c("rttr", "ttr", "maas")
  result <- batch_function(documents, metrics = metrics)
  single <- single_function(documents[[1L]], metrics = metrics)
  contract <- jsonlite::read_json(
    system.file(
      "spec",
      "lexical-diversity-contract.json",
      package = "ldfreq"
    ),
    simplifyVector = FALSE
  )
  expected_fields <- c(
    unlist(
      contract$output_contract$batch_envelope$envelope_fields,
      use.names = FALSE
    ),
    unlist(contract$output_contract$result_fields, use.names = FALSE)
  )

  expect_s3_class(result, "lexdiv_results")
  expect_identical(names(result), expected_fields)
  expect_identical(
    result$document_id,
    rep(names(documents), each = length(metrics))
  )
  expect_identical(result$metric_id, rep(metrics, times = length(documents)))
  expect_identical(names(result)[-(1:3)], names(single))
  expect_identical(
    names(result)[1:3],
    c("document_id", "batch_schema_id", "batch_schema_version")
  )
  expect_true(all(result$batch_schema_id == "lexdiv-r-batch-result"))
  expect_true(all(result$batch_schema_version == "0.1.0-draft.1"))
  expect_s3_class(result, "lexdiv_batch_results")
  expect_true(inherits(result, "lexdiv_results"))
  expect_identical(attr(result, "batch_schema_id"), "lexdiv-r-batch-result")
  expect_identical(attr(result, "batch_schema_version"), "0.1.0-draft.1")
  expect_identical(attr(result, "contract_id"), attr(single, "contract_id"))
  expect_identical(
    attr(result, "contract_version"),
    attr(single, "contract_version")
  )
  expect_identical(
    attr(result, "result_schema_id"),
    attr(single, "result_schema_id")
  )
  expect_identical(
    attr(result, "result_schema_version"),
    attr(single, "result_schema_version")
  )

  first_document <- result[
    result$document_id == "second",
    -(1:3),
    drop = FALSE
  ]
  row.names(first_document) <- NULL
  class(first_document) <- class(single)
  attr(first_document, "batch_schema_id") <- NULL
  attr(first_document, "batch_schema_version") <- NULL
  single_custom_attributes <- setdiff(
    names(attributes(single)),
    c("names", "row.names", "class")
  )
  for (attribute_name in single_custom_attributes) {
    attr(first_document, attribute_name) <- attr(single, attribute_name)
  }
  expect_identical(first_document, single)
})

test_that("named-list and data-frame inputs are identical", {
  documents <- list(
    doc_b = c("a", "b", "a"),
    doc_a = character(),
    doc_c = c("x", NA_character_)
  )
  frame <- data.frame(
    document_id = names(documents),
    stringsAsFactors = FALSE
  )
  frame$tokens <- unname(documents)

  from_list <- batch_function(documents, metrics = c("ttr", "mtld"))
  from_frame <- batch_function(frame, metrics = c("ttr", "mtld"))

  expect_identical(from_frame, from_list)

  names(frame) <- c("explicit_id", "token_vectors")
  from_selected_columns <- batch_function(
    frame,
    id_col = "explicit_id",
    tokens_col = "token_vectors",
    metrics = c("ttr", "mtld")
  )
  expect_identical(from_selected_columns, from_list)
})

test_that("empty and invalid documents remain local to their metric rows", {
  documents <- list(
    empty = character(),
    invalid_missing = c("a", NA_character_),
    invalid_type = 1:3,
    valid = c("a", "b", "a")
  )
  result <- batch_function(documents, metrics = c("ttr", "mtld"))

  empty_rows <- result$document_id == "empty"
  invalid_rows <- result$document_id %in% c("invalid_missing", "invalid_type")
  valid_rows <- result$document_id == "valid"

  expect_true(all(result$status[empty_rows] == "missing"))
  expect_true(all(result$missing_reason[empty_rows] == "empty_input"))
  expect_true(all(result$N[empty_rows] == 0))
  expect_true(all(result$status[invalid_rows] == "invalid_input"))
  expect_true(all(result$missing_reason[invalid_rows] == "invalid_token"))
  expect_true(all(is.na(result$N[invalid_rows])))
  expect_identical(result$status[valid_rows], c("ok", "missing"))
  expect_identical(
    result$missing_reason[valid_rows],
    c(NA_character_, "insufficient_tokens_for_formula")
  )
})

test_that("metric subsets, order, and parameters are forwarded unchanged", {
  tokens <- rep(c("a", "b", "a", "c", "d"), 12L)
  documents <- list(zeta = tokens, alpha = rev(tokens))
  arguments <- list(
    metrics = c("hdd", "mattr", "msttr", "mtld"),
    sample_size = 7,
    window_length = 9,
    segment_length = 10,
    mtld_threshold = 0.6
  )
  result <- do.call(batch_function, c(list(documents = documents), arguments))

  expect_identical(
    result$metric_id,
    rep(arguments$metrics, times = length(documents))
  )
  for (index in seq_along(documents)) {
    single <- do.call(
      single_function,
      c(list(tokens = documents[[index]]), arguments)
    )
    rows <- result$document_id == names(documents)[[index]]
    expect_identical(result$value[rows], single$value)
    expect_identical(
      unclass(result$requested_parameters[rows]),
      unclass(single$requested_parameters)
    )
    expect_identical(
      unclass(result$effective_parameters[rows]),
      unclass(single$effective_parameters)
    )
    expect_identical(
      unclass(result$diagnostics[rows]),
      unclass(single$diagnostics)
    )
  }
})

test_that("zero-document inputs return the typed long-form prototype", {
  empty_list <- setNames(vector("list", 0L), character())
  empty_frame <- data.frame(document_id = character(), stringsAsFactors = FALSE)
  empty_frame$tokens <- vector("list", 0L)
  single <- single_function(character(), metrics = c("maas", "ttr"))

  from_list <- batch_function(empty_list, metrics = c("maas", "ttr"))
  from_frame <- batch_function(empty_frame, metrics = c("maas", "ttr"))

  expect_identical(from_frame, from_list)
  expect_equal(nrow(from_list), 0L)
  expect_identical(
    names(from_list),
    c(
      "document_id", "batch_schema_id", "batch_schema_version",
      names(single)
    )
  )
  expect_s3_class(from_list, "lexdiv_batch_results")
  expect_true(inherits(from_list, "lexdiv_results"))
  expect_identical(attr(from_list, "batch_schema_id"), "lexdiv-r-batch-result")
  expect_identical(attr(from_list, "batch_schema_version"), "0.1.0-draft.1")
  expect_identical(attr(from_list, "contract_id"), attr(single, "contract_id"))
  expect_identical(
    attr(from_list, "contract_version"),
    attr(single, "contract_version")
  )
  expect_identical(
    attr(from_list, "result_schema_id"),
    attr(single, "result_schema_id")
  )
  expect_identical(
    attr(from_list, "result_schema_version"),
    attr(single, "result_schema_version")
  )
  expect_identical(from_list$document_id, character())
  expect_identical(from_list$batch_schema_id, character())
  expect_identical(from_list$batch_schema_version, character())
  expect_identical(from_list$metric_id, character())
})

test_that("zero documents still validate global metric parameters", {
  empty_list <- setNames(vector("list", 0L), character())

  expect_error(
    batch_function(empty_list, metrics = "msttr", segment_length = 0),
    "segment_length"
  )
  expect_error(
    batch_function(empty_list, metrics = "mattr", window_length = 0),
    "window_length"
  )
  expect_error(
    batch_function(empty_list, metrics = "mtld", mtld_threshold = 1),
    "threshold"
  )
  expect_error(
    batch_function(empty_list, metrics = "hdd", sample_size = 0),
    "sample_size"
  )
  expect_error(
    batch_function(empty_list, metrics = "not_frozen"),
    "non-frozen"
  )

  ignored_local_parameter <- batch_function(
    empty_list,
    metrics = "ttr",
    segment_length = 0
  )
  expect_equal(nrow(ignored_local_parameter), 0L)

  invalid_document <- list(bad = c("a", NA_character_))
  expect_error(
    batch_function(invalid_document, metrics = "msttr", segment_length = 0),
    "segment_length"
  )
})

test_that("named-list document IDs are mandatory and strict", {
  expect_error(batch_function(list(c("a"))), "plain named list")
  expect_error(
    batch_function(setNames(list(c("a"), c("b")), c("same", "same"))),
    "document IDs"
  )
  expect_error(batch_function(setNames(list(c("a")), "")), "document IDs")
  expect_error(
    batch_function(setNames(list(c("a")), NA_character_)),
    "document IDs"
  )

  bytes_id <- enc2utf8("caf\u00e9")
  Encoding(bytes_id) <- "bytes"
  expect_error(batch_function(setNames(list(c("a")), bytes_id)), "document IDs")

  latin1_id <- iconv("caf\u00e9", from = "UTF-8", to = "latin1")
  Encoding(latin1_id) <- "latin1"
  expect_error(batch_function(setNames(list(c("a")), latin1_id)), "document IDs")

  invalid_id <- rawToChar(as.raw(255L))
  Encoding(invalid_id) <- "unknown"
  expect_false(validUTF8(invalid_id))
  expect_error(batch_function(setNames(list(c("a")), invalid_id)), "document IDs")

  attributed <- list(doc = c("a"))
  attr(attributed, "source") <- "adversarial"
  expect_error(batch_function(attributed), "plain named list")
  classed <- structure(list(doc = c("a")), class = "adversarial_list")
  expect_error(batch_function(classed), "plain named list")
})

test_that("data-frame IDs and structural columns are strict", {
  make_frame <- function() {
    value <- data.frame(document_id = c("a", "b"), stringsAsFactors = FALSE)
    value$tokens <- list(c("x"), c("y"))
    value
  }

  factor_id <- make_frame()
  factor_id$document_id <- factor(factor_id$document_id)
  expect_error(batch_function(factor_id), "document IDs")

  attributed_id <- make_frame()
  attr(attributed_id$document_id, "source") <- "adversarial"
  expect_false(is.null(attributes(attributed_id$document_id)))
  expect_error(batch_function(attributed_id), "document IDs")

  matrix_id <- make_frame()
  matrix_id$document_id <- matrix(c("a", "b"), ncol = 1L)
  expect_error(batch_function(matrix_id), "document IDs")

  duplicate_id <- make_frame()
  duplicate_id$document_id <- c("a", "a")
  expect_error(batch_function(duplicate_id), "document IDs")

  bytes_id <- make_frame()
  marked_ids <- c(enc2utf8("caf\u00e9"), "b")
  Encoding(marked_ids[[1L]]) <- "bytes"
  bytes_id$document_id <- marked_ids
  expect_identical(Encoding(bytes_id$document_id[[1L]]), "bytes")
  expect_error(batch_function(bytes_id), "document IDs")

  atomic_tokens <- make_frame()
  atomic_tokens$tokens <- c("x", "y")
  expect_error(batch_function(atomic_tokens), "list-column")

  missing_tokens <- make_frame()["document_id"]
  expect_error(batch_function(missing_tokens), "exactly one selected")

  duplicate_columns <- make_frame()
  duplicate_columns[[3L]] <- duplicate_columns$tokens
  names(duplicate_columns)[[3L]] <- "tokens"
  expect_error(batch_function(duplicate_columns), "exactly one selected")

  expect_error(
    batch_function(make_frame(), id_col = "document_id", tokens_col = "document_id"),
    "different columns"
  )
  expect_error(
    batch_function(make_frame(), id_col = structure("document_id", note = "x")),
    "id_col"
  )
})

test_that("ID duplicate detection is independent of the C locale encoding trap", {
  previous_locale <- Sys.getlocale("LC_CTYPE")
  on.exit(suppressWarnings(Sys.setlocale("LC_CTYPE", previous_locale)), add = TRUE)
  c_locale <- suppressWarnings(Sys.setlocale("LC_CTYPE", "C"))
  skip_if(!nzchar(c_locale), "The C locale is unavailable on this platform.")

  utf8_id <- rawToChar(as.raw(c(0xc3L, 0xa9L)))
  Encoding(utf8_id) <- "UTF-8"
  unknown_id <- rawToChar(as.raw(c(0xc3L, 0xa9L)))
  Encoding(unknown_id) <- "unknown"
  expect_true(validUTF8(unknown_id))

  duplicate_list <- setNames(
    list(c("a"), c("b")),
    c(utf8_id, unknown_id)
  )
  expect_error(batch_function(duplicate_list, metrics = "ttr"), "document IDs")

  duplicate_frame <- data.frame(
    document_id = c(utf8_id, unknown_id),
    stringsAsFactors = FALSE
  )
  duplicate_frame$tokens <- list(c("a"), c("b"))
  expect_error(batch_function(duplicate_frame, metrics = "ttr"), "document IDs")

  unique_list <- setNames(list(c("a")), unknown_id)
  expect_identical(Encoding(names(unique_list)), "unknown")
  result <- batch_function(unique_list, metrics = "ttr")
  expect_identical(Encoding(names(unique_list)), "unknown")
  expect_identical(Encoding(result$document_id), "UTF-8")

  unique_frame <- data.frame(document_id = unknown_id, stringsAsFactors = FALSE)
  unique_frame$tokens <- list(c("a"))
  expect_identical(Encoding(unique_frame$document_id), "unknown")
  frame_result <- batch_function(unique_frame, metrics = "ttr")
  expect_identical(Encoding(unique_frame$document_id), "unknown")
  expect_identical(Encoding(frame_result$document_id), "UTF-8")

  tokens_name_utf8 <- rawToChar(as.raw(c(0xc3L, 0xb6L)))
  Encoding(tokens_name_utf8) <- "UTF-8"
  tokens_name_unknown <- rawToChar(as.raw(c(0xc3L, 0xb6L)))
  Encoding(tokens_name_unknown) <- "unknown"
  unicode_columns <- data.frame(value = unknown_id, stringsAsFactors = FALSE)
  unicode_columns$token_value <- list(c("a"))
  names(unicode_columns) <- c(unknown_id, tokens_name_unknown)
  original_column_encodings <- Encoding(names(unicode_columns))
  selected <- batch_function(
    unicode_columns,
    id_col = utf8_id,
    tokens_col = tokens_name_utf8,
    metrics = "ttr"
  )
  expect_identical(Encoding(names(unicode_columns)), original_column_encodings)
  expect_identical(selected$value, 1)
})

test_that("only the two explicit batch container forms are accepted", {
  expect_error(batch_function(c("a", "b")), "documents must")
  expect_error(batch_function(matrix(list(c("a")), nrow = 1L)), "documents must")
  expect_error(batch_function(list()), "documents must")
})

test_that("the batch print method reports the envelope and returns invisibly", {
  result <- batch_function(list(doc = c("a", "b")), metrics = "ttr")
  printed <- capture.output(returned <- withVisible(print(result)))

  expect_true(any(grepl("lexdiv_batch_results", printed, fixed = TRUE)))
  expect_true(any(grepl("1 document", printed, fixed = TRUE)))
  expect_false(returned$visible)
  expect_identical(returned$value, result)
})
