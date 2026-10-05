annotation_input <- function() {
  list(data = data.frame(document_id = rep("ja", 8), segment_id = "s1",
    token_index = 1:8, surface = c("国際", "連合", "で", "国際", "協力", "を", "学ぶ", "。"),
    lemma = c("国際", "連合", "で", "国際", "協力", "を", "学ぶ", NA_character_),
    unknown = c(rep(FALSE, 7), NA)),
    segments = data.frame(document_id = c("ja", "empty"), segment_id = c("s1", "s1"),
      text = c("国際連合で国際協力を学ぶ。", "")),
    provenance = list(language = "ja", analyzer = "authored", analyzer_version = "1",
      dictionary = "none", dictionary_version = "not-applicable", unit = "authored-fine",
      normalization = "none", dictionary_sha256 = NA_character_))
}

test_that("complete annotations align with original text and retain missing features", {
  f <- annotation_input(); x <- do.call(lexdiv_import_annotations, f)
  expect_identical(x$tokens$start, c(1L, 3L, 5L, 6L, 8L, 10L, 11L, 13L))
  expect_identical(x$tokens$end, c(2L, 4L, 5L, 7L, 9L, 10L, 12L, 13L))
  expect_identical(x$tokens[names(f$data)], f$data)
  expect_identical(x$segments$token_count, c(8L, 0L))
  expect_identical(x$segments$text, f$segments$text)
  expect_identical(x$documents$document_id, c("ja", "empty"))
  expect_identical(x$provenance$annotation, f$provenance)
  expect_identical(x$provenance$normalization, "none")
  expect_identical(x$segments$text_sha256[2],
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  expect_identical(do.call(lexdiv_import_annotations, f), x)
  f$data <- x$tokens
  expect_identical(do.call(lexdiv_import_annotations, f), x)
  f$data$start[1] <- 0
  expect_error(do.call(lexdiv_import_annotations, f), "start")
  f$data$start[1] <- 2
  expect_error(do.call(lexdiv_import_annotations, f), "codepoint")
  path <- tempfile(); on.exit(unlink(path))
  saveRDS(x, path); expect_identical(readRDS(path), x)
})

test_that("codepoints, whitespace and decomposed characters are preserved", {
  f <- annotation_input()
  f$segments <- data.frame(document_id = "ja", segment_id = "s",
    text = " \U0001f600\t\u304b\u3099\u3000\u732b \u732b\n")
  f$data <- data.frame(document_id = "ja", segment_id = "s", token_index = 1:4,
    surface = c("\U0001f600", "\u304b\u3099", "猫", "猫"))
  x <- do.call(lexdiv_import_annotations, f)
  expect_identical(x$tokens$start, c(2L, 4L, 7L, 9L))
  expect_identical(x$tokens$end, c(2L, 5L, 7L, 9L))
  expect_identical(x$tokens$surface, f$data$surface)
  expect_identical(x$segments$text, f$segments$text)
  f$data$surface[2] <- "が"
  expect_error(do.call(lexdiv_import_annotations, f), "align")
  f$segments$text <- "\t　"
  f$data <- f$data[FALSE, ]
  expect_identical(do.call(lexdiv_import_annotations, f)$segments$token_count, 0L)
  f$data <- data.frame(document_id = "ja", segment_id = "s", token_index = 1:2,
    surface = c("\t", "　"))
  expect_identical(do.call(lexdiv_import_annotations, f)$tokens$start, 1:2)
})

test_that("omissions, normalization, reordered tokens and invalid IDs fail explicitly", {
  f <- annotation_input()
  for (deleted in c(1L, 4L, 8L)) {
    changed <- f
    changed$data <- f$data[-deleted, ]
    changed$data$token_index <- seq_len(nrow(changed$data))
    expect_error(do.call(lexdiv_import_annotations, changed), "align|Unannotated")
  }
  for (positions in list(c(1:7, 9), c(0:7), rep(1, 8), c(1:7, NA))) {
    changed <- f; changed$data$token_index <- positions
    expect_error(do.call(lexdiv_import_annotations, changed), "token_index")
  }
  for (surfaces in list(rep(NA_character_, 8), rep("", 8), factor(f$data$surface))) {
    changed <- f; changed$data$surface <- surfaces
    expect_error(do.call(lexdiv_import_annotations, changed), "surface")
  }
  changed <- f; changed$data$document_id[1] <- "absent"
  expect_error(do.call(lexdiv_import_annotations, changed), "segment")
  changed <- f; changed$segments <- rbind(f$segments, f$segments[1, ])
  expect_error(do.call(lexdiv_import_annotations, changed), "unique")
  changed <- f; changed$segments$text[1] <- NA_character_
  expect_error(do.call(lexdiv_import_annotations, changed), "UTF-8")
  changed <- f; changed$segments$token_count <- c(8L, 0L)
  expect_error(do.call(lexdiv_import_annotations, changed), "reserved")
  changed <- f; changed$data$surface <- NULL
  expect_error(do.call(lexdiv_import_annotations, changed), "Supply")
  expect_error(do.call(lexdiv_import_annotations, c(f, list(max_tokens = 7))), "max_tokens")
  changed <- f; changed$provenance$unit <- NULL
  expect_error(do.call(lexdiv_import_annotations, changed), "unit")
  changed <- f; changed$provenance$dictionary_version <- NA_character_
  expect_error(do.call(lexdiv_import_annotations, changed), "dictionary_version")
  changed <- f; changed$provenance$extra <- list("x")
  expect_error(do.call(lexdiv_import_annotations, changed), "extra")
})

test_that("document and segment boundaries survive metric and ngram workflows", {
  f <- annotation_input(); x <- do.call(lexdiv_import_annotations, f)
  words <- x$tokens[1:7, ]
  metrics <- lexdiv_metrics(words$surface, metrics = "ttr")
  expect_equal(metrics$N, 7)
  expect_equal(metrics$V, 6)
  expect_equal(metrics$value, 6 / 7)
  ng <- lexdiv_ngrams(words, "authored-ja-surface-v1", term_col = "surface",
    documents = x$documents$document_id)
  expect_equal(sum(ng$counts$count[ng$counts$n == 2]), 6)
  expect_equal(sum(ng$counts$count[ng$counts$n == 3]), 5)
  expect_identical(unique(ng$documents$document_id), c("ja", "empty"))
  kept <- words[!words$surface %in% c("で", "を"), ]
  gaps <- lexdiv_ngrams(kept, "authored-ja-excluded-v1", term_col = "surface")
  expect_equal(sum(gaps$counts$count[gaps$counts$n == 2]), 2)
  expect_equal(sum(gaps$counts$count[gaps$counts$n == 3]), 0)
  expect_identical(kept$token_index, c(1L, 2L, 4L, 5L, 7L))
  f$segments <- data.frame(document_id = c("a:b", "a:b", "a"),
    segment_id = c("c", "d", "b:c"), text = c("猫猫", "犬犬", "鳥鳥"))
  f$data <- data.frame(document_id = rep(f$segments$document_id, each = 2),
    segment_id = rep(f$segments$segment_id, each = 2), token_index = rep(1:2, 3),
    surface = rep(c("猫", "犬", "鳥"), each = 2))
  x <- do.call(lexdiv_import_annotations, f)
  expect_identical(x$tokens$start, rep(1:2, 3))
  ng <- lexdiv_ngrams(x$tokens, "authored", term_col = "surface")
  expect_equal(sum(ng$counts$count), 3)
  changed <- f; changed$data <- f$data[6:1, ]
  expect_error(do.call(lexdiv_import_annotations, changed), "order")
  changed <- f; changed$segments <- f$segments[c(1, 3, 2), ]; changed$data <- f$data[FALSE, ]
  expect_error(do.call(lexdiv_import_annotations, changed), "contiguous")
})

test_that("quanteda keeps original slots after Japanese annotation filtering", {
  skip_if_not_installed("quanteda")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  x <- do.call(lexdiv_import_annotations, annotation_input())
  kept <- x$tokens[c(1, 2, 4, 5, 7), ]
  q <- lexdiv_as_quanteda(kept, x$segments)
  expect_identical(unname(as.list(q$tokens)),
    list(c("国際", "連合", "", "国際", "協力", "", "学ぶ", ""), character()))
  expect_identical(q$positions$start, kept$start)
})
