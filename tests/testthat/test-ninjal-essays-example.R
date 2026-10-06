ninjal_reader_fixture <- function() {
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "ninjal-essays.R", package = "ldfreq", mustWork = TRUE), e)
  essay <- data.frame("作文ID" = c("example_01", "example_02", "empty_01"),
    "執筆者ID" = c("writer1", "absent", "writer1"),
    "日本語作文txt" = c("fixture-utf8.txt", "fixture-cp932.txt", "fixture-empty.txt"),
    "作文テーマ" = "Authored fixture", check.names = FALSE)
  writer <- data.frame("執筆者ID" = "writer1", "母語" = "Authored L1", check.names = FALSE)
  list(read = e$read_ninjal_essays, zip = test_path("fixtures", "ninjal-essays-authored.zip"),
    essay = essay, writer = writer,
    encoding = setNames(c("UTF-8", "CP932", "UTF-8"), essay[["日本語作文txt"]]))
}

test_that("explicit decoding preserves text and metadata without guessing filenames", {
  f <- ninjal_reader_fixture()
  x <- f$read(f$zip, f$essay, f$writer, encoding = f$encoding)
  expect_identical(x$segments$text, c("りんご。\r\n\r\n", "リンゴ。\n", ""))
  expect_identical(x$documents$utf8_bom_removed, c(TRUE, FALSE, FALSE))
  expect_identical(x$documents$document_id, f$essay[["作文ID"]])
  expect_identical(x$documents$writer_id, f$essay[["執筆者ID"]])
  expect_identical(x$documents$writer_metadata_status, c("matched", "missing", "matched"))
  expect_identical(x$documents$l1_reported, c("Authored L1", NA_character_, "Authored L1"))
  expect_identical(x$documents$source_encoding, c("UTF-8", "CP932", "UTF-8"))
  expect_true(all(nchar(x$documents$source_sha256) == 64))
  expect_false(x$documents$source_sha256[1] == x$documents$text_sha256[1])
  selected <- f$read(f$zip, f$essay, f$writer, rev(f$essay[["日本語作文txt"]]), f$encoding)
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
  essay <- f$essay; essay[["日本語作文txt"]][2] <- essay[["日本語作文txt"]][1]
  expect_error(f$read(f$zip, essay, f$writer), "unique")
  expect_error(f$read(f$zip, f$essay, f$writer, files = "absent.txt"), "both the ZIP and essay metadata")
  essay <- f$essay; essay[["作文ID"]][1] <- NA_character_
  expect_error(f$read(f$zip, essay, f$writer), "nonmissing")
})
