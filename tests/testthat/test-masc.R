masc_fixture <- function() {
  skip_if_not_installed("xml2")
  path <- tempfile("masc-")
  dir.create(path)
  source <- system.file("extdata", "masc-example", package = "ldfreq")
  file.copy(list.files(source, full.names = TRUE), path)
  file.path(path, "example.anc")
}

masc_replace <- function(header, suffix, from, to) {
  path <- file.path(dirname(header), paste0("example", suffix))
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  writeLines(gsub(from, to, text, fixed = TRUE), path, useBytes = TRUE)
}

test_that("Penn annotations preserve text, IDs, features and ordered source positions", {
  h <- masc_fixture(); on.exit(unlink(dirname(h), recursive = TRUE))
  x <- lexdiv_read_masc(h, "authored-1")
  expect_identical(x$tokens$surface, c("We", "re-use", "words", ".", "We", "go", "."))
  expect_identical(x$tokens$annotation_id, paste0("t", 0:6))
  expect_identical(x$tokens$lemma, c("we", "re-use", "word", ".", "we", "go", "."))
  expect_identical(x$tokens$pos, c("PRP", "VBP", "NNS", ".", "PRP", "VBP", "."))
  expect_equal(x$tokens$start, c(1, 4, 11, 16, 18, 21, 23))
  expect_equal(x$tokens$end, c(2, 9, 15, 16, 19, 22, 23))
  expect_identical(x$tokens$token_index, c(1:4, 1:3))
  expect_equal(x$segments$token_count, c(4, 3))
  expect_identical(x$tokens$features[[3]][["affix"]], "s")
  expect_identical(x$documents$text, "We re-use words. We go.\n")
  expect_identical(x$documents$medium, "Written")
  expect_identical(x$provenance$token_layer, "penn")
  expect_equal(nrow(x$provenance$files), 5)
  expect_true(all(nchar(x$provenance$files$sha256) == 64))
  expect_identical(lexdiv_read_masc(h, "authored-1"), x)
  p <- tempfile(fileext = ".rds"); on.exit(unlink(p), add = TRUE)
  saveRDS(x, p); expect_identical(readRDS(p), x)
  expect_error(lexdiv_read_masc(c(h, h), "v"), "unique")
  expect_error(lexdiv_read_masc(h, "v", document_ids = character()), "document_ids|IDs")
  expect_error(lexdiv_read_masc(h, "v", max_tokens = 6), "max_tokens")
})

test_that("modern documentHeader references preserve the same annotation tables", {
  h <- masc_fixture(); on.exit(unlink(dirname(h), recursive = TRUE))
  old <- lexdiv_read_masc(h, "authored-1")
  for (change in list(c("cesHeader", "documentHeader"),
      c('type="seg"', 'f.id="f.seg"'), c('type="s"', 'f.id="f.s"'),
      c('type="penn"', 'f.id="f.penn"'), c("ann.loc=", "loc=")))
    masc_replace(h, ".anc", change[1], change[2])
  modern <- file.path(dirname(h), "example.hdr")
  file.copy(h, modern)
  x <- lexdiv_read_masc(modern, "authored-1")
  for (field in c("tokens", "segments", "documents")) expect_identical(x[[field]], old[[field]])
  expect_identical(x$provenance$reader_version, "0.2.0")
  expect_identical(x$provenance$files$sha256[-1], old$provenance$files$sha256[-1])
  expect_false(identical(x$provenance$files$sha256[1], old$provenance$files$sha256[1]))
  expect_identical(x$provenance$files$filename[1], "example.hdr")
  masc_replace(h, ".anc", 'f.id="f.penn"', 'f.id="f.ptbtok"')
  expect_error(lexdiv_read_masc(h, "v"), "one penn")
  masc_replace(h, ".anc", "documentHeader", "unknownHeader")
  expect_error(lexdiv_read_masc(h, "v"), "Expected MASC GrAF")
})

test_that("malformed annotations fail before inventing token positions", {
  cases <- list(
    c("-seg.xml", 'anchors="0 2"', 'anchors="0 200"', "anchors"),
    c("-seg.xml", 'xml:id="r1"', 'xml:id="r0"', "unique|ID r0"),
    c("-s.xml", 'anchors="17 23"', 'anchors="15 23"', "overlap"),
    c("-s.xml", 'anchors="0 16"', 'anchors="0 14"', "fit one"),
    c("-penn.xml", 'targets="r1 r2 r3"', 'targets="r1 r3"', "Discontinuous"),
    c("-penn.xml", 'targets="r1 r2 r3"', 'targets="r1 r1"', "duplicate"),
    c("-penn.xml", 'targets="r0"', 'targets="missing"', "missing"),
    c("-penn.xml", 'targets="r4"', 'targets="r0"', "overlap"),
    c("-penn.xml", 'ref="t6"', 'ref="missing"', "one tok"),
    c("-penn.xml", 'name="affix"', 'name="base"', "unique, flat"),
    c(".anc", 'type="penn"', 'type="ptbtok"', "one penn"),
    c(".anc", 'loc="example.txt"', 'loc="../example.txt"', "header directory"),
    c(".anc", 'loc="example.txt"', 'loc="https://example.com/text"', "header directory"),
    c("-seg.xml", '<graph xmlns=', '<!DOCTYPE graph><graph xmlns=', "DTD")
  )
  for (case in cases) {
    h <- masc_fixture()
    masc_replace(h, case[1], case[2], case[3])
    expect_error(lexdiv_read_masc(h, "test"), case[4], info = paste(case, collapse = " "))
    unlink(dirname(h), recursive = TRUE)
  }
})

test_that("Unicode offsets distinguish codepoints from UTF-16 code units", {
  h <- masc_fixture(); on.exit(unlink(dirname(h), recursive = TRUE))
  graph <- function(body) paste0('<graph xmlns="http://www.xces.org/ns/GrAF/1.0/">', body, '</graph>')
  writeBin(charToRaw(enc2utf8("A \U0001f600 caf\u00e9.")), file.path(dirname(h), "example.txt"))
  penn <- paste0('<node xml:id="t', 0:3, '"><link targets="r', 0:3, '"/></node>',
    '<a label="tok" ref="t', 0:3, '"><fs><f name="msd" value="X"/></fs></a>', collapse = "")
  writeLines(graph(penn), file.path(dirname(h), "example-penn.xml"))
  for (unit in c("codepoint", "utf16")) {
    spans <- if (unit == "codepoint") c("0 1", "2 3", "4 8", "8 9") else
      c("0 1", "2 4", "5 9", "9 10")
    writeLines(graph(paste0('<region xml:id="r', 0:3, '" anchors="', spans, '"/>', collapse = "")),
      file.path(dirname(h), "example-seg.xml"))
    writeLines(graph(paste0('<region xml:id="s" anchors="0 ', if (unit == "codepoint") 9 else 10, '"/>')),
      file.path(dirname(h), "example-s.xml"))
    x <- lexdiv_read_masc(h, "unicode", offset_unit = unit)
    expect_identical(x$tokens$surface, c("A", "\U0001f600", "caf\u00e9", "."))
    expect_equal(x$tokens$start, c(1, 3, 5, 9))
    expect_equal(x$tokens$end, c(1, 3, 8, 9))
    expect_true(all(is.na(x$tokens$lemma)))
  }
  expect_error(lexdiv_read_masc(h, "unicode", offset_unit = "codepoint"), "anchors")
})

test_that("empty source documents remain in the reader's document table", {
  h <- masc_fixture(); on.exit(unlink(dirname(h), recursive = TRUE))
  writeBin(raw(), file.path(dirname(h), "example.txt"))
  for (suffix in c("-seg.xml", "-s.xml", "-penn.xml"))
    writeLines('<graph xmlns="http://www.xces.org/ns/GrAF/1.0/"/>',
      file.path(dirname(h), paste0("example", suffix)))
  x <- lexdiv_read_masc(h, "empty")
  expect_equal(nrow(x$tokens), 0)
  expect_equal(nrow(x$segments), 0)
  expect_equal(x$documents$tokens, 0)
  expect_identical(x$documents$text, "")
})

test_that("quanteda adapter preserves gaps, empty segments and source mappings", {
  skip_if_not_installed("quanteda", "4.5.0")
  data <- data.frame(document_id = c("d", "d"), segment_id = "s",
    token_index = c(1, 3), surface = c("make", "decision"), start = c(1, 8))
  segments <- data.frame(document_id = c("d", "d", "empty"),
    segment_id = c("s", "all_excluded", "s"), token_count = c(4, 2, 0))
  q <- lexdiv_as_quanteda(data, segments)
  expect_identical(as.list(q$tokens), list(segment_1 = c("make", "", "decision", ""),
    segment_2 = c("", ""), segment_3 = character()))
  expect_equal(sum(quanteda::ntoken(quanteda::tokens_ngrams(q$tokens, n = 2))), 0)
  kw <- quanteda::kwic(q$tokens, "decision", valuetype = "fixed")
  expect_equal(kw$from, 3)
  expect_equal(q$positions$start[q$positions$token_index == kw$from], 8)
  expect_identical(quanteda::docvars(q$tokens)$document_id, segments$document_id)
  expect_false(q$provenance$retokenized)
  expect_equal(q$provenance$source_token_slots, 6)
  expect_identical(lexdiv_as_quanteda(data[2:1, ], segments)$tokens, q$tokens)
  p <- tempfile(fileext = ".rds"); on.exit(unlink(p))
  saveRDS(q, p); expect_identical(as.list(readRDS(p)$tokens), as.list(q$tokens))
  special <- data.frame(document_id = "d", segment_id = "s", token_index = 1:5,
    surface = c("ldfreq_padding", "ldfreq_padding_", "e\u0301", "\u00e9", "\U0001f600"))
  special_segments <- data.frame(document_id = "d", segment_id = "s", token_count = 5)
  if (isTRUE(l10n_info()[["UTF-8"]])) {
    z <- lexdiv_as_quanteda(special, special_segments)
    expect_identical(unname(as.list(z$tokens)[[1]]), special$surface)
  } else {
    expect_error(lexdiv_as_quanteda(special, special_segments), "UTF-8 LC_CTYPE")
  }
})

test_that("non-UTF-8 sessions reject non-ASCII quanteda imports without changing locale", {
  skip_if_not_installed("quanteda", "4.5.0")
  previous <- Sys.getlocale("LC_CTYPE")
  on.exit(Sys.setlocale("LC_CTYPE", previous))
  Sys.setlocale("LC_CTYPE", "C")
  data <- data.frame(document_id = "d", segment_id = "s", token_index = 1L,
    surface = "caf\u00e9")
  segments <- data.frame(document_id = "d", segment_id = "s", token_count = 1L)
  expect_error(lexdiv_as_quanteda(data, segments), "UTF-8 LC_CTYPE")
  expect_identical(Sys.getlocale("LC_CTYPE"), "C")
  data$surface <- "cafe"
  expect_identical(as.list(lexdiv_as_quanteda(data, segments)$tokens), list(segment_1 = "cafe"))
})

test_that("quanteda adapter validates positions, terms and allocation size", {
  skip_if_not_installed("quanteda", "4.5.0")
  data <- data.frame(document_id = "d", segment_id = "s", token_index = 1L, surface = "word")
  segments <- data.frame(document_id = "d", segment_id = "s", token_count = 1L)
  expect_error(lexdiv_as_quanteda(data, segments, max_tokens = 0), "max_tokens")
  expect_error(lexdiv_as_quanteda(data, transform(segments, token_count = 100), max_tokens = 10), "max_tokens")
  expect_error(lexdiv_as_quanteda(data, rbind(segments, segments)), "unique")
  expect_error(lexdiv_as_quanteda(rbind(data, data), segments), "unique")
  expect_error(lexdiv_as_quanteda(transform(data, token_index = 2), segments), "range")
  expect_error(lexdiv_as_quanteda(transform(data, token_index = 0), segments), "token_index")
  expect_error(lexdiv_as_quanteda(transform(data, segment_id = "missing"), segments), "matched")
  expect_error(lexdiv_as_quanteda(transform(data, surface = "two words"), segments), "whitespace")
  expect_error(lexdiv_as_quanteda(transform(data, surface = NA_character_), segments), "missing")
  expect_error(lexdiv_as_quanteda(transform(data, quanteda_docname = "x"), segments), "reserved")
  expect_equal(sum(quanteda::ntoken(lexdiv_as_quanteda(data[FALSE, ], segments)$tokens,
    remove_padding = TRUE)), 0)
})
