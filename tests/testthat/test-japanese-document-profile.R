japanese_profile_fixture <- function() {
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "japanese-document-profile.R", package = "ldfreq", mustWork = TRUE), e)
  words <- c("学校", "がっこう", "カタカナ", "ｶﾞ", "か\u3099", "Ａ12", "ー", "々", "🙂", "。", "！", "？")
  segments <- data.frame(document_id = c("unicode", "unicode", "empty", "punct"),
    segment_id = c("s1", "s2", "s1", "s1"),
    text = c(paste0(paste(words[1:8], collapse = " "), "\r\n"), "🙂。", "", "！？"))
  tokens <- data.frame(document_id = c(rep("unicode", 10), rep("punct", 2)),
    segment_id = c(rep("s1", 8), "s2", "s2", "s1", "s1"), token_index = c(1:8, 1:2, 1:2),
    surface = words, POS1 = c(rep("名詞", 4), "XPOS", NA, "名詞", "名詞", "記号", rep("補助記号", 3)),
    goshu = c("漢", "漢", "和", "外", "*", NA, "", "和", rep("記号", 4)))
  provenance <- list(language = "ja", analyzer = "authored", analyzer_version = "1", dictionary = "none",
    dictionary_version = "none", unit = "authored", normalization = "none")
  x <- lexdiv_import_annotations(tokens, segments, provenance)
  mask <- x$tokens[c("document_id", "segment_id", "token_index", "start", "end", "surface")]
  mask$in_body <- TRUE
  mask$retained <- !words %in% c("。", "！", "？")
  mask$reason <- ifelse(mask$retained, "retained", "declared_punctuation")
  list(e = e, x = x, mask = mask, groups = c("名詞" = "content", "助詞" = "function"))
}

test_that("Japanese profiles separate codepoints, origin, POS and denominators", {
  f <- japanese_profile_fixture()
  p <- f$e$japanese_document_profile(f$x, f$mask, f$groups, "test")
  expect_equal(p$documents$source_N, c(10, 0, 2))
  expect_equal(p$documents$retained_N, c(9, 0, 0))
  expect_equal(p$documents$source_codepoints, c(30, 0, 2))
  expect_equal(p$documents$retained_codepoints, c(20, 0, 0))
  expect_equal(p$documents$pos_missing_N, c(1, 0, 0))
  expect_equal(p$documents$origin_missing_N, c(3, 0, 0))
  expect_equal(p$documents$pos_unmapped_N, c(2, 0, 0))
  expect_equal(rowSums(p$documents[c("outside_body_N", "excluded_inside_N", "retained_N")]),
    p$documents$source_N)
  a <- subset(p$characters, document_id == "unicode" & population == "retained_tokens")
  actual <- setNames(a$n, a$category)
  expected <- c(han = 3, hiragana = 5, katakana = 5, kana_shared = 2, latin = 1,
    decimal_digit = 2, mark = 1, symbol = 1, whitespace = 0, punctuation = 0, other = 0)
  expect_equal(actual[names(expected)], expected)
  expect_equal(sum(a$proportion), 1)
  expect_true(all(a$denominator == 20))
  b <- subset(p$features, document_id == "unicode" & feature == "pos_group")
  expect_equal(b$n[b$status == "missing"], 1)
  expect_equal(b$n[b$status == "unmapped"], 2)
  expect_equal(b$n[!is.na(b$category) & b$category == "content"], 6)
  expect_equal(sum(b$n), 9)
  expect_true(all(b$denominator == 9))
  expect_true(all(is.na(subset(p$characters, denominator == 0)$proportion)))
  expect_true(all(is.na(subset(p$features, denominator == 0)$proportion)))
  expect_identical(p$tokens$origin_value, f$x$tokens$goshu)
  expect_identical(p$imported, f$x)
  expect_identical(p$imported$segments$text, f$x$segments$text)
  expect_equal(p$tokens$char_kana_shared[4], 1)
  expect_equal(p$tokens$char_mark[5], 1)
  # Script is not word origin: the authored katakana token has a 和 label.
  expect_equal(p$tokens$char_katakana[3], 4)
  expect_identical(p$tokens$origin_value[3], "和")
  d <- f$e$.japanese_profile_characters(c("が", "か\u3099", "", "\U00020000"))
  expect_equal(rowSums(d), c(1, 2, 0, 1))
  expect_equal(d[, "mark"], c(0, 1, 0, 0))
  expect_equal(d[, "han"], c(0, 0, 0, 1))
  shared <- f$e$.japanese_profile_characters("\u30fc\uff70\u309b\u309c\uff9e\uff9f")
  expect_equal(unname(shared[1, "kana_shared"]), 6)
  expect_equal(sum(shared), 6)
})

test_that("profile selections reject changed anchors and preserve missing fields", {
  f <- japanese_profile_fixture(); run <- f$e$japanese_document_profile
  p <- run(f$x, f$mask, f$groups, "test")
  expect_identical(run(f$x, f$mask[nrow(f$mask):1, ], f$groups, "test"), p)
  expect_error(run(f$x, f$mask[-1, ], f$groups, "test"), "every original token")
  mask <- f$mask; mask$end[1] <- mask$end[1] + 1
  expect_error(run(f$x, mask, f$groups, "test"), "unchanged source anchors")
  mask <- f$mask; mask$retained[1] <- NA
  expect_error(run(f$x, mask, f$groups, "test"), "logical")
  mask <- f$mask; mask$in_body[1] <- FALSE
  expect_error(run(f$x, mask, f$groups, "test"), "logical")
  expect_error(run(f$x, rbind(f$mask, f$mask[1, ]), f$groups, "test"), "unique")
  expect_error(run(f$x, f$mask, c("名詞" = "content", "名詞" = "function"), "test"), "unique")
  expect_error(run(f$x, f$mask, c("*" = "content"), "test"), "nonmissing")
  changed <- f$x; changed$tokens$goshu[1] <- "和"
  expect_error(run(changed, f$mask, f$groups, "test"), "Annotations changed")
  t <- f$x$tokens; t$goshu <- NULL
  absent <- lexdiv_import_annotations(t, f$x$segments[c("document_id", "segment_id", "text")],
    f$x$provenance$annotation)
  q <- run(absent, f$mask, f$groups, "no-origin-field")
  a <- subset(q$features, feature == "origin")
  expect_false(any(a$field_present))
  expect_true(all(a$status == "missing"))
  expect_equal(a$n, c(9, 0, 0))
  expect_equal(q$documents$origin_missing_N, c(9, 0, 0))
  empty <- lexdiv_import_annotations(t[FALSE, ],
    data.frame(document_id = "empty", segment_id = "s1", text = ""), f$x$provenance$annotation)
  z <- run(empty, f$mask[FALSE, ], f$groups, "empty")
  expect_equal(z$documents$retained_N, 0)
  expect_true(all(is.na(z$features$proportion)))
  expect_true(all(z$characters$n == 0))
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(p, path, version = 2); saved <- readRDS(path)
  expect_identical(saved, p)
  expect_identical(run(saved$imported, saved$selection, saved$policy$pos_groups, saved$policy$condition), p)
})

test_that("installed authored file workflow connects profiles, decisions and measures", {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "japanese-document-profile-demo.R", package = "ldfreq", mustWork = TRUE), e)
  on.exit(unlink(e$ja_file_output, recursive = TRUE))
  p <- e$ja_profile
  expect_equal(p$documents$retained_N, c(5, 9, 1, 0, 0))
  expect_equal(p$documents$outside_body_N, c(1, 1, 0, 0, 0))
  expect_equal(p$documents$origin_missing_N, c(0, 0, 1, 0, 0))
  a <- subset(p$features, document_id == "variants" & feature == "origin" & status == "observed")
  expect_equal(a$n[match(c("漢", "和"), a$category)], c(3, 2))
  b <- subset(p$characters, document_id == "variants" & population == "retained_tokens")
  expect_equal(b$n[match(c("han", "hiragana", "katakana"), b$category)], c(2, 5, 3))
  expect_identical(e$ja_profile_record$file_review$after, e$ja_file_after)
  expect_identical(readRDS(file.path(e$ja_file_output, "document-profile.rds")), e$ja_profile_record)
  csv <- utils::read.csv(file.path(e$ja_file_output, "profile-documents.csv"), fileEncoding = "UTF-8")
  expect_equal(csv$retained_N, p$documents$retained_N)
})
