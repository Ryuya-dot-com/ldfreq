test_that("data-frame essays become a validated ordered text corpus", {
  data <- data.frame(
    essay_id = c("essay_02", "essay_01"),
    essay_text = enc2utf8(c("Café essay.", "Second essay.")),
    source_sheet = c("Essays", "Essays"),
    source_row = c(3L, 2L),
    stringsAsFactors = FALSE
  )

  corpus <- lexdiv_text_corpus(
    data,
    id_col = "essay_id",
    text_col = "essay_text",
    metadata_cols = c("source_sheet", "source_row")
  )

  expect_s3_class(corpus, "lexdiv_text_corpus")
  expect_identical(names(corpus), c("texts", "documents", "provenance"))
  expect_identical(names(corpus$texts), c("essay_02", "essay_01"))
  expect_identical(corpus$texts[[1L]], enc2utf8("Café essay."))
  expect_identical(
    names(corpus$documents),
    c(
      "document_id", "text_bytes", "text_sha256",
      "source_sheet", "source_row"
    )
  )
  expect_identical(corpus$documents$source_row, c(3L, 2L))
  expect_true(all(grepl("^[0-9a-f]{64}$", corpus$documents$text_sha256)))
  expect_identical(corpus$provenance$contract_id, "ldfreq-text-corpus")
  expect_identical(corpus$provenance$input_type, "data_frame")
  expect_identical(
    corpus$provenance$metadata_cols,
    c("source_sheet", "source_row")
  )
  expect_identical(corpus$provenance$text_transformed, FALSE)
})

test_that("empty texts and zero-row corpora remain explicit", {
  with_empty <- lexdiv_text_corpus(data.frame(
    document_id = c("empty", "nonempty"),
    text = c("", "one"),
    stringsAsFactors = FALSE
  ))
  zero <- lexdiv_text_corpus(data.frame(
    document_id = character(),
    text = character(),
    stringsAsFactors = FALSE
  ))

  expect_identical(with_empty$texts[[1L]], "")
  expect_identical(with_empty$documents$text_bytes, c(0, 3))
  expect_identical(zero$texts, setNames(character(), character()))
  expect_identical(nrow(zero$documents), 0L)
  expect_identical(zero$provenance$document_count, 0L)
})

test_that("tabular text input rejects implicit or ambiguous coercions", {
  valid <- data.frame(
    document_id = c("one", "two"),
    text = c("first", "second"),
    metadata = c("a", "b"),
    stringsAsFactors = FALSE
  )

  expect_error(lexdiv_text_corpus(list()), "data frame")
  expect_error(
    lexdiv_text_corpus(transform(valid, document_id = c(1, 2))),
    "document IDs"
  )
  expect_error(
    lexdiv_text_corpus(transform(valid, document_id = c("same", "same"))),
    "document IDs"
  )
  expect_error(
    lexdiv_text_corpus(transform(valid, text = c("first", NA_character_))),
    "text column"
  )
  expect_error(
    lexdiv_text_corpus(transform(valid, text = factor(text))),
    "text column"
  )
  expect_error(
    lexdiv_text_corpus(valid, id_col = "text", text_col = "text"),
    "different columns"
  )
  expect_error(
    lexdiv_text_corpus(valid, metadata_cols = "missing"),
    "exactly one"
  )
  expect_error(
    lexdiv_text_corpus(valid, metadata_cols = "text"),
    "may not include"
  )
  reserved <- valid
  reserved$text_sha256 <- c("x", "y")
  expect_error(
    lexdiv_text_corpus(reserved, metadata_cols = "text_sha256"),
    "reserved"
  )
  list_metadata <- valid
  list_metadata$metadata <- list(list(a = 1), list(b = 2))
  expect_error(
    lexdiv_text_corpus(list_metadata, metadata_cols = "metadata"),
    "atomic value"
  )
})

test_that("tabular corpora feed independent raw-text analyses", {
  corpus <- lexdiv_text_corpus(data.frame(
    document_id = c("one", "two"),
    text = c("One one two.", "Alpha beta gamma."),
    stringsAsFactors = FALSE
  ))
  documents <- lapply(
    corpus$texts,
    lexdiv_metrics_text,
    case = "lower",
    metrics = "ttr"
  )

  expect_identical(names(documents), c("one", "two"))
  expect_equal(documents$one$results$value, 2 / 3)
  expect_equal(documents$two$results$value, 1)
})

test_that("text corpus printing omits text and returns invisibly", {
  corpus <- lexdiv_text_corpus(data.frame(
    document_id = "essay",
    text = "private essay contents",
    source_sheet = "Essays",
    stringsAsFactors = FALSE
  ), metadata_cols = "source_sheet")
  printed <- capture.output(returned <- withVisible(print(corpus)))

  expect_false(returned$visible)
  expect_identical(returned$value, corpus)
  expect_true(any(grepl("lexdiv_text_corpus", printed, fixed = TRUE)))
  expect_true(any(grepl("Essays", printed, fixed = TRUE)))
  expect_false(any(grepl("private essay contents", printed, fixed = TRUE)))
})

test_that("the installed text-corpus contract matches runtime identity", {
  contract_path <- system.file(
    "spec", "ldfreq-text-corpus-contract.json",
    package = "ldfreq"
  )
  schema_path <- system.file(
    "spec", "ldfreq-text-corpus-contract.schema.json",
    package = "ldfreq"
  )

  expect_true(nzchar(contract_path))
  expect_true(nzchar(schema_path))
  contract <- jsonlite::read_json(contract_path, simplifyVector = TRUE)
  expect_identical(contract$contract_id, "ldfreq-text-corpus")
  expect_identical(contract$contract_version, "0.1.0")
  expect_identical(contract$result$text_retained_in_manifest, FALSE)
  expect_identical(contract$result$text_sha256_algorithm, "sha256")
})
