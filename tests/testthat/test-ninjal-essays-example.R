ninjal_reader_fixture <- function() {
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "ninjal-essays.R", package = "ldfreq", mustWork = TRUE), e)
  essay <- data.frame(id = c("example_01", "example_02", "empty_01"),
    writer = c("writer1", "absent", "writer1"),
    file = c("fixture-utf8.txt", "fixture-cp932.txt", "fixture-empty.txt"),
    task = "Authored fixture", check.names = FALSE)
  names(essay) <- c("\u4f5c\u6587ID", "\u57f7\u7b46\u8005ID", "\u65e5\u672c\u8a9e\u4f5c\u6587txt", "\u4f5c\u6587\u30c6\u30fc\u30de")
  writer <- data.frame(id = "writer1", language = "Authored L1", check.names = FALSE)
  names(writer) <- c("\u57f7\u7b46\u8005ID", "\u6bcd\u8a9e")
  list(read = e$read_ninjal_essays, zip = test_path("fixtures", "ninjal-essays-authored.zip"),
    essay = essay, writer = writer,
    encoding = setNames(c("UTF-8", "CP932", "UTF-8"), essay[["\u65e5\u672c\u8a9e\u4f5c\u6587txt"]]))
}

test_that("explicit decoding preserves text and metadata without guessing filenames", {
  f <- ninjal_reader_fixture()
  x <- f$read(f$zip, f$essay, f$writer, encoding = f$encoding)
  expect_identical(x$segments$text, c("\u308a\u3093\u3054\u3002\r\n\r\n", "\u30ea\u30f3\u30b4\u3002\n", ""))
  expect_identical(x$documents$utf8_bom_removed, c(TRUE, FALSE, FALSE))
  expect_identical(x$documents$document_id, f$essay[["\u4f5c\u6587ID"]])
  expect_identical(x$documents$writer_id, f$essay[["\u57f7\u7b46\u8005ID"]])
  expect_identical(x$documents$writer_metadata_status, c("matched", "missing", "matched"))
  expect_identical(x$documents$l1_reported, c("Authored L1", NA_character_, "Authored L1"))
  expect_identical(x$documents$source_encoding, c("UTF-8", "CP932", "UTF-8"))
  expect_true(all(nchar(x$documents$source_sha256) == 64))
  expect_false(x$documents$source_sha256[1] == x$documents$text_sha256[1])
  selected <- f$read(f$zip, f$essay, f$writer, rev(f$essay[["\u65e5\u672c\u8a9e\u4f5c\u6587txt"]]), f$encoding)
  expect_identical(selected$segments$text, rev(x$segments$text))
  expect_identical(selected$documents$document_id, rev(x$documents$document_id))
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(x, path)
  expect_identical(readRDS(path), x)
})

test_that("wrong encodings and ambiguous joins cannot silently corrupt imports", {
  f <- ninjal_reader_fixture()
  expect_error(f$read(f$zip, f$essay, f$writer), "Cannot decode.*fixture-cp932")
  enc <- f$encoding; enc[1] <- "CP932"
  expect_error(f$read(f$zip, f$essay, f$writer, encoding = enc), "BOM conflicts")
  expect_error(f$read(f$zip, f$essay, f$writer, encoding = f$encoding[1]), "each requested file")
  expect_error(f$read(f$zip, f$essay, f$writer, encoding = "guess"), "explicitly supplied")
  expect_error(f$read(f$zip, f$essay, rbind(f$writer, f$writer)), "unique")
  essay <- f$essay; essay[["\u65e5\u672c\u8a9e\u4f5c\u6587txt"]][2] <- essay[["\u65e5\u672c\u8a9e\u4f5c\u6587txt"]][1]
  expect_error(f$read(f$zip, essay, f$writer), "unique")
  expect_error(f$read(f$zip, f$essay, f$writer, files = "absent.txt"), "both the ZIP and essay metadata")
  essay <- f$essay; essay[["\u4f5c\u6587ID"]][1] <- NA_character_
  expect_error(f$read(f$zip, essay, f$writer), "nonmissing")
})
