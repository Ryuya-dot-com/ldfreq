test_that("local file decoding retains the declared text, bytes and empty files", {
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "text-file-input.R", package = "ldfreq",
    mustWork = TRUE), e)
  directory <- tempfile("text-input-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE))
  plain <- enc2utf8("A, \"quoted\" line.\r\n\r\ne\u0301\n")
  japanese <- enc2utf8("\u308a\u3093\u3054\u3002\r\n")
  payloads <- list(plain = charToRaw(plain),
    bom = c(as.raw(c(239, 187, 191)), charToRaw(plain)),
    cp932 = as.raw(c(130, 232, 130, 241, 130, 178, 129, 66, 13, 10)),
    no_final_newline = charToRaw("last line"), empty = raw())
  expected <- list(plain, plain, japanese, "last line", "")
  for (i in seq_along(payloads)) {
    path <- file.path(directory, paste0(names(payloads)[i], ".txt"))
    writeBin(payloads[[i]], path)
    encoding <- if (names(payloads)[i] == "cp932") "CP932" else "UTF-8"
    x <- e$read_text_file(path, encoding)
    expect_identical(x$text, expected[[i]])
    expect_identical(x$source$source_bytes, length(payloads[[i]]))
    expect_identical(x$source$utf8_bom_removed, names(payloads)[i] == "bom")
    expect_identical(x$source$source_encoding, encoding)
    expect_identical(x$source$source_file, path)
    expect_identical(x$source$source_sha256 == x$source$text_sha256,
      !names(payloads)[i] %in% c("bom", "cp932"))
    expect_error(e$read_text_file(path, max_bytes = .5), "max_bytes")
  }
  x <- e$read_text_file(file.path(directory, "bom.txt"))
  saved <- file.path(directory, "record.rds")
  saveRDS(x, saved, version = 2)
  expect_identical(readRDS(saved), x)
})

test_that("representable non-ASCII file paths retain their contents", {
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]), "Non-ASCII paths require a representable native encoding")
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "text-file-input.R", package = "ldfreq", mustWork = TRUE), e)
  directory <- tempfile("unicode-path-"); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE))
  path <- file.path(directory, "\u65e5\u672c\u8a9e space.txt")
  text <- "\u308a\u3093\u3054\u3002\r\n"
  writeBin(charToRaw(text), path)
  expect_identical(e$read_text_file(path)$text, text)
})

test_that("file failures cannot silently become empty or replacement text", {
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "text-file-input.R", package = "ldfreq",
    mustWork = TRUE), e)
  path <- tempfile(fileext = ".txt")
  on.exit(unlink(path))
  expect_error(e$read_text_file(path), "existing regular file")
  expect_error(e$read_text_file(tempdir()), "existing regular file")
  writeBin(as.raw(c(195, 40)), path)
  expect_error(e$read_text_file(path), "Cannot decode|Byte round-trip")
  expect_error(e$read_text_file(path, encoding = "guess"), "does not guess")
  expect_error(e$read_text_file(path, max_bytes = 1), "exceeds max_bytes")
  writeBin(as.raw(c(65, 0, 66)), path)
  expect_error(e$read_text_file(path), "NUL")
  writeBin(as.raw(c(239, 187, 191, 65)), path)
  expect_error(e$read_text_file(path, encoding = "CP932"), "BOM conflicts")
})

test_that("authored TXT and CSV inputs retain IDs, metadata and missingness", {
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "text-file-input.R", package = "ldfreq",
    mustWork = TRUE), e)
  root <- system.file("examples", "text-input", package = "ldfreq", mustWork = TRUE)
  read_csv <- function(path) utils::read.csv(text = e$read_text_file(path)$text,
    colClasses = "character", na.strings = "<MISSING>", check.names = FALSE)
  documents <- read_csv(file.path(root, "essays.csv"))
  expect_identical(documents$document_id, sprintf("%03d", 1:31))
  texts <- vapply(documents$document_id, function(id)
    e$read_text_file(file.path(root, "texts", paste0(id, ".txt")))$text, character(1))
  expect_identical(documents$text, unname(texts))
  expect_identical(documents$text[31], "")
  metadata <- read_csv(file.path(root, "metadata.csv"))
  expect_identical(metadata$writer_id[match(c("001", "002", "031"), metadata$document_id)],
    c("example_writer_01", "example_writer_02", "example_writer_01"))
  prepared <- lexdiv_tokenize_batch(documents, tokenizer = "english", case = "lower")
  result <- lexdiv_metrics_text_batch(prepared, metrics = "ttr")
  expect_identical(result$results$document_id, documents$document_id)
  expect_equal(result$results$N, c(107, 129, 147, 117, 138, 108, 127, 149, 117, 137,
    108, 128, 147, 119, 137, 107, 128, 148, 118, 140, 108, 128, 149, 119, 138,
    110, 128, 148, 119, 139, 0))
  expect_true(is.na(result$results$value[31]))
  expect_true(nzchar(result$results$missing_reason[31]))
  mattr <- lexdiv_metrics_text_batch(prepared, metrics = "mattr", window_length = 50)
  expect_identical(which(is.finite(mattr$results$value)), 1:30)
  expect_true(is.na(mattr$results$value[31]))
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path))
  special <- data.frame(document_id = c("001", "TRUE", "NA", "empty", "missing"),
    text = c("A, \"quoted\" line.\nNext line.\n", "TRUE", "NA", "", NA_character_))
  utils::write.csv(special, path, row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")
  expect_identical(read_csv(path), special)
  csv_crlf <- utils::read.csv(text = '"document_id","text"\r\n"001","A\r\nB\r\n"\r\n',
    colClasses = "character")
  expect_identical(csv_crlf$text, "A\nB\n")  # CSV parsing has its own newline policy.
  expect_error(lexdiv_tokenize_batch(read_csv(path)), "missing")
  expect_error(lexdiv_tokenize_batch(documents[c(1, 1), ]), "unique")
})
