write_utf8_fixture <- function(path, text) {
  connection <- file(path, open = "wb")
  on.exit(close(connection), add = TRUE)
  writeBin(charToRaw(enc2utf8(text)), connection)
  invisible(path)
}

test_that("directory input reads one exact UTF-8 string per file", {
  directory <- tempfile("ldfreq-texts-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)

  write_utf8_fixture(
    file.path(directory, "b_document.TXT"),
    "Second line one.\nSecond line two."
  )
  write_utf8_fixture(
    file.path(directory, "a_document.txt"),
    "Café — first document."
  )
  write_utf8_fixture(file.path(directory, "ignored.md"), "not selected")

  corpus <- lexdiv_read_texts(directory)

  expect_s3_class(corpus, "lexdiv_text_corpus")
  expect_identical(names(corpus), c("texts", "documents", "provenance"))
  expect_identical(names(corpus$texts), c("a_document", "b_document"))
  expect_identical(corpus$texts[[1L]], enc2utf8("Café — first document."))
  expect_identical(corpus$texts[[2L]], "Second line one.\nSecond line two.")
  expect_identical(
    corpus$documents$source_file,
    c("a_document.txt", "b_document.TXT")
  )
  expect_true(all(grepl("^[0-9a-f]{64}$", corpus$documents$source_sha256)))
  expect_identical(
    corpus$documents$source_sha256,
    corpus$documents$text_sha256
  )
  expect_identical(corpus$provenance$contract_id, "ldfreq-text-corpus")
  expect_identical(
    corpus$provenance$input_contract_id,
    "ldfreq-text-file-input"
  )
  expect_identical(corpus$provenance$source_mode, "directory")
  expect_identical(corpus$provenance$path_retained, FALSE)
  expect_false(any(grepl(directory, unlist(corpus), fixed = TRUE)))
})

test_that("explicit files preserve caller order and explicit IDs", {
  directory <- tempfile("ldfreq-texts-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)

  first <- write_utf8_fixture(file.path(directory, "first.data"), "one")
  second <- write_utf8_fixture(file.path(directory, "second.data"), "two")

  corpus <- lexdiv_read_texts(
    c(second, first),
    document_ids = c("document_2", "document_1")
  )

  expect_identical(
    corpus$texts,
    c(document_2 = "two", document_1 = "one")
  )
  expect_identical(corpus$provenance$source_mode, "explicit_files")
  expect_true(is.na(corpus$provenance$pattern))
})

test_that("directory recursion and filename-stem collision checks are explicit", {
  directory <- tempfile("ldfreq-texts-")
  dir.create(directory)
  dir.create(file.path(directory, "nested"))
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)

  root <- write_utf8_fixture(file.path(directory, "same.txt"), "root")
  nested <- write_utf8_fixture(
    file.path(directory, "nested", "same.txt"),
    "nested"
  )

  expect_identical(lexdiv_read_texts(directory)$texts, c(same = "root"))
  expect_error(
    lexdiv_read_texts(directory, recursive = TRUE),
    "document IDs",
    fixed = TRUE
  )
  expect_identical(
    lexdiv_read_texts(
      c(root, nested),
      document_ids = c("root_same", "nested_same")
    )$texts,
    c(root_same = "root", nested_same = "nested")
  )
})

test_that("text-file validation rejects unsafe or ambiguous inputs", {
  directory <- tempfile("ldfreq-texts-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)

  valid <- write_utf8_fixture(file.path(directory, "valid.txt"), "valid")
  duplicate <- c(valid, file.path(directory, ".", "valid.txt"))

  expect_error(lexdiv_read_texts(character()), "one or more")
  expect_error(
    lexdiv_read_texts(file.path(directory, "missing.txt")),
    "missing.txt",
    fixed = TRUE
  )
  expect_error(lexdiv_read_texts(duplicate), "same text file")
  expect_error(
    lexdiv_read_texts(c(valid, valid), document_ids = c("a", "b")),
    "same text file"
  )
  expect_error(
    lexdiv_read_texts(valid, document_ids = c("a", "b")),
    "document IDs"
  )
  expect_error(lexdiv_read_texts(directory, pattern = "["), "regular expression")
  expect_error(lexdiv_read_texts(directory, pattern = "[.]csv$"), "No matching")
  expect_error(lexdiv_read_texts(directory, max_file_bytes = 4), "max_file_bytes")
  expect_error(lexdiv_read_texts(directory, max_total_bytes = 4), "max_total_bytes")
  expect_error(lexdiv_read_texts(directory, recursive = NA), "TRUE or FALSE")
})

test_that("invalid UTF-8 and embedded NUL bytes are rejected", {
  directory <- tempfile("ldfreq-texts-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)

  invalid_utf8 <- file.path(directory, "invalid-utf8.txt")
  connection <- file(invalid_utf8, open = "wb")
  writeBin(as.raw(c(0xc3, 0x28)), connection)
  close(connection)

  embedded_nul <- file.path(directory, "embedded-nul.txt")
  connection <- file(embedded_nul, open = "wb")
  writeBin(as.raw(c(0x61, 0x00, 0x62)), connection)
  close(connection)

  expect_error(lexdiv_read_texts(invalid_utf8), "not valid UTF-8")
  expect_error(lexdiv_read_texts(embedded_nul), "embedded NUL")
})

test_that("read raw documents retain separate preprocessing audits", {
  directory <- tempfile("ldfreq-texts-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)

  write_utf8_fixture(file.path(directory, "one.txt"), "One one two.")
  write_utf8_fixture(file.path(directory, "two.txt"), "Alpha beta gamma.")

  corpus <- lexdiv_read_texts(directory)
  documents <- lapply(
    corpus$texts,
    lexdiv_metrics_text,
    case = "lower",
    metrics = "ttr"
  )

  expect_identical(names(documents), c("one", "two"))
  expect_s3_class(documents$one, "lexdiv_text_results")
  expect_identical(documents$one$results$N, 3)
  expect_equal(documents$one$results$value, 2 / 3)
  expect_identical(documents$two$results$N, 3)
  expect_equal(documents$two$results$value, 1)
  expect_false(identical(
    documents$one$preprocessing$tokenization$processed_text_sha256,
    documents$two$preprocessing$tokenization$processed_text_sha256
  ))
})

test_that("the corpus print method is path-private and returns invisibly", {
  directory <- tempfile("ldfreq-texts-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  write_utf8_fixture(file.path(directory, "document.txt"), "one two")

  corpus <- lexdiv_read_texts(directory)
  printed <- capture.output(returned <- withVisible(print(corpus)))

  expect_false(returned$visible)
  expect_identical(returned$value, corpus)
  expect_true(any(grepl("lexdiv_text_corpus", printed, fixed = TRUE)))
  expect_true(any(grepl("document.txt", printed, fixed = TRUE)))
  expect_false(any(grepl(directory, printed, fixed = TRUE)))
})

test_that("the installed text-file input contract matches runtime identity", {
  contract_path <- system.file(
    "spec", "ldfreq-text-file-input-contract.json",
    package = "ldfreq"
  )
  schema_path <- system.file(
    "spec", "ldfreq-text-file-input-contract.schema.json",
    package = "ldfreq"
  )

  expect_true(nzchar(contract_path))
  expect_true(nzchar(schema_path))
  contract <- jsonlite::read_json(contract_path, simplifyVector = TRUE)
  expect_identical(contract$contract_id, "ldfreq-text-file-input")
  expect_identical(contract$contract_version, "0.1.0")
  expect_identical(contract$decoding$encoding, "UTF-8")
  expect_identical(contract$result$absolute_path_retained, FALSE)
  expect_identical(contract$result$file_sha256_algorithm, "sha256")
})
