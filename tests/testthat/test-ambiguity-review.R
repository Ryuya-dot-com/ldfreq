ambiguity_fixture <- function(japanese = FALSE) {
  values <- if (japanese) list(c("その", "店", "は", "人気", "が", "ある", "。"),
    c("ここ", "は", "人気", "が", "ない", "。")) else
    list(c("The", "bank", "lent", "money", "."), c("The", "river", "bank", "flooded", "."))
  tokens <- data.frame(document_id = "d", segment_id = rep(c("s1", "s2"), lengths(values)),
    token_index = sequence(lengths(values)), surface = unlist(values, use.names = FALSE))
  segments <- data.frame(document_id = c("d", "d", "empty"), segment_id = c("s1", "s2", "s1"),
    text = c(if (japanese) c("その店は人気がある。", "ここは人気がない。") else
      c("The bank lent money.", "The river bank flooded."), ""))
  x <- lexdiv_import_annotations(tokens, segments, list(language = if (japanese) "ja" else "en",
    analyzer = "authored", analyzer_version = "1", dictionary = "none",
    dictionary_version = "not-applicable", unit = "authored", normalization = "none"))
  term <- if (japanese) "人気" else "bank"
  candidates <- data.frame(term = rep(term, 2), candidate_id = c("sense-a", "sense-b"),
    label = if (japanese) c("popularity", "presence of people") else c("financial institution", "river edge"))
  if (japanese) candidates$reading <- c("にんき", "ひとけ")
  list(x = x, targets = c(term, "absent"), candidates = candidates,
    resource = list(resource_id = "authored-example", resource_version = "1",
      source_reference = "Authored test candidates, not a dictionary", data_license = "MIT"))
}

ambiguity_decisions <- function(review) {
  out <- review$occurrences[c("review_id", "occurrence_id")]
  out$status <- c("selected", "unresolved")
  out$candidate_id <- c("sense-a", NA_character_)
  out$reviewer <- "author"
  out$reason <- c("Money-lending context", "Keep for adjudication")
  out
}

test_that("KWIC review retains exact occurrences, candidate multiplicity and empty sources", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- ambiguity_fixture(); r <- do.call(lexdiv_ambiguity_review, c(f, list(window = 1)))
  expect_identical(r$occurrences$pre, c("The", "river"))
  expect_identical(r$occurrences$post, c("lent", "flooded"))
  expect_identical(r$occurrences$token_index, c(2L, 3L))
  expect_identical(r$occurrences$start, c(5L, 11L))
  expect_identical(r$occurrences$end, c(8L, 14L))
  expect_identical(r$occurrences$segment_text, f$x$segments$text[1:2])
  expect_identical(r$occurrences$status, rep("unreviewed", 2))
  expect_identical(r$summary$occurrences, c(2L, 0L))
  expect_identical(r$summary$candidate_count, c(2L, 0L))
  expect_identical(r$source, f$x)
  expect_equal(length(unique(r$occurrences$occurrence_id)), 2)
  expect_true(all(is.na(r$occurrences$candidate_id)))
  expect_equal(rowSums(r$summary[c("unreviewed", "selected", "unresolved", "no_candidates")]),
    r$summary$occurrences)
})

test_that("decisions survive display ordering, changed windows and RDS/CSV round trips", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- ambiguity_fixture(); r <- do.call(lexdiv_ambiguity_review, f)
  decisions <- ambiguity_decisions(r)[2:1, ]
  rds <- tempfile(); csv <- tempfile()
  on.exit(unlink(c(rds, csv)))
  saveRDS(r, rds); expect_identical(readRDS(rds), r)
  utils::write.csv(decisions, csv, row.names = FALSE, na = "")
  decisions <- utils::read.csv(csv, colClasses = "character", na.strings = "", check.names = FALSE)
  f$candidates <- f$candidates[2:1, ]
  f$targets <- rev(f$targets)
  reviewed <- do.call(lexdiv_ambiguity_review, c(f, list(decisions = decisions, window = 0)))
  expect_identical(reviewed$occurrences$occurrence_id, r$occurrences$occurrence_id)
  expect_identical(reviewed$occurrences$review_id, r$occurrences$review_id)
  expect_identical(reviewed$occurrences$status, c("selected", "unresolved"))
  expect_identical(reviewed$occurrences$candidate_id, c("sense-a", NA_character_))
  expect_identical(reviewed$occurrences$pre, rep("", 2))
  expect_identical(reviewed$occurrences$post, rep("", 2))
  expect_identical(reviewed$source, f$x)
  expect_identical(reviewed$decisions, decisions)
})

test_that("zero and single candidates are never interpreted as resolved meanings", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- ambiguity_fixture(); f$candidates <- f$candidates[1, ]
  r <- do.call(lexdiv_ambiguity_review, f)
  expect_true(all(r$occurrences$status == "unreviewed"))
  f$candidates <- f$candidates[FALSE, ]
  r <- do.call(lexdiv_ambiguity_review, f)
  expect_true(all(r$occurrences$status == "no_candidates"))
  expect_true(all(is.na(r$occurrences$candidate_id)))
  f$targets <- "absent"
  r <- do.call(lexdiv_ambiguity_review, f)
  expect_equal(nrow(r$occurrences), 0)
  expect_equal(r$summary$occurrences, 0)
  expect_equal(nrow(r$source$segments), 3)
  f$x <- lexdiv_import_annotations(f$x$tokens[FALSE, ],
    data.frame(document_id = "empty", segment_id = "s", text = ""), f$x$provenance$annotation)
  expect_equal(nrow(do.call(lexdiv_ambiguity_review, f)$occurrences), 0)
})

test_that("Japanese readings remain candidates and codepoint positions point to original text", {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  f <- ambiguity_fixture(TRUE); r <- do.call(lexdiv_ambiguity_review, c(f, list(window = 1)))
  expect_identical(r$occurrences$pre, c("は", "は"))
  expect_identical(r$occurrences$post, c("が", "が"))
  expect_identical(r$occurrences$start, c(5L, 4L))
  expect_identical(r$candidates$reading, c("にんき", "ひとけ"))
  expect_identical(stringi::stri_sub(r$occurrences$segment_text,
    r$occurrences$start, r$occurrences$end), c("人気", "人気"))
  decisions <- ambiguity_decisions(r)
  decisions$status <- "selected"; decisions$candidate_id <- c("sense-a", "sense-b")
  decisions$reason <- c("店の評判", "人の気配")
  reviewed <- do.call(lexdiv_ambiguity_review, c(f, list(decisions = decisions)))
  expect_identical(reviewed$occurrences$candidate_id, c("sense-a", "sense-b"))
  expect_identical(reviewed$summary$selected, c(2L, 0L))
})

test_that("stale, mismatched and duplicated decisions fail rather than silently moving rows", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- ambiguity_fixture(); r <- do.call(lexdiv_ambiguity_review, f)
  decisions <- ambiguity_decisions(r)
  for (field in c("label", "candidate_id")) {
    changed <- f; changed$candidates[[field]][1] <- "changed"
    expect_error(do.call(lexdiv_ambiguity_review, c(changed, list(decisions = decisions))), "review_id")
  }
  changed <- f; changed$resource$resource_version <- "2"
  expect_error(do.call(lexdiv_ambiguity_review, c(changed, list(decisions = decisions))), "review_id")
  changed <- f
  segments <- f$x$segments[c("document_id", "segment_id", "text")]
  segments$text[1] <- " The bank lent money."
  changed$x <- lexdiv_import_annotations(f$x$tokens[setdiff(names(f$x$tokens), c("start", "end"))],
    segments, f$x$provenance$annotation)
  expect_error(do.call(lexdiv_ambiguity_review, c(changed, list(decisions = decisions))), "review_id")
  changed <- f; changed$x$tokens$surface[2] <- "BANK"
  expect_error(do.call(lexdiv_ambiguity_review, changed), "align")
  changed <- f; changed$x$provenance$annotation$dictionary_version <- "2"
  expect_error(do.call(lexdiv_ambiguity_review, changed), "changed")
  changed <- f; changed$x$segments$text_sha256[1] <- "tampered"
  expect_error(do.call(lexdiv_ambiguity_review, changed), "changed")
  for (field in c("review_id", "occurrence_id", "status", "candidate_id", "reason", "reviewer")) {
    bad <- decisions; bad[[field]][1] <- if (field %in% c("reason", "reviewer")) " " else "unknown"
    expect_error(do.call(lexdiv_ambiguity_review, c(f, list(decisions = bad))))
  }
  expect_error(do.call(lexdiv_ambiguity_review, c(f, list(decisions = decisions[c(1, 1), ]))), "unique")
  bad <- decisions; bad$candidate_id[2] <- "sense-b"
  expect_error(do.call(lexdiv_ambiguity_review, c(f, list(decisions = bad))), "unresolved")
  bad <- decisions; bad$candidate_id[1] <- NA_character_
  expect_error(do.call(lexdiv_ambiguity_review, c(f, list(decisions = bad))), "selected")
})

test_that("literal matching, repeated words, boundaries, whitespace and invalid inputs are explicit", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- ambiguity_fixture()
  f$x <- lexdiv_import_annotations(data.frame(document_id = "d", segment_id = "s", token_index = 1:5,
    surface = c("Bank", "*", "bank", " ", "bank")),
    data.frame(document_id = "d", segment_id = "s", text = "Bank*bank bank"), f$x$provenance$annotation)
  f$targets <- c("bank", "*")
  r <- do.call(lexdiv_ambiguity_review, c(f, list(window = 1)))
  expect_identical(r$occurrences$token_index, c(2L, 3L, 5L))
  expect_identical(r$summary$occurrences, c(2L, 1L))
  expect_identical(r$occurrences$status, c("no_candidates", "unreviewed", "unreviewed"))
  expect_identical(r$occurrences$pre[3], "")
  f <- ambiguity_fixture()
  for (window in list(-1, NA_real_, 1.5, c(1, 2), numeric(), Inf))
    expect_error(do.call(lexdiv_ambiguity_review, c(f, list(window = window))), "window")
  expect_error(do.call(lexdiv_ambiguity_review, c(f, list(max_tokens = 1))), "max_tokens")
  f$candidates <- rbind(f$candidates, f$candidates[1, ])
  expect_error(do.call(lexdiv_ambiguity_review, f), "unique")
  f <- ambiguity_fixture(); f$candidates$term[1] <- "other"
  expect_error(do.call(lexdiv_ambiguity_review, f), "targets")
  f <- ambiguity_fixture(); f$targets <- "two words"
  expect_error(do.call(lexdiv_ambiguity_review, f), "single-token")
})

test_that("candidate IDs cannot be borrowed from another target", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- ambiguity_fixture(); f$targets <- c(f$targets, "money")
  f$candidates <- rbind(f$candidates, data.frame(term = "money", candidate_id = "currency",
    label = "currency"))
  r <- do.call(lexdiv_ambiguity_review, f)
  decisions <- r$occurrences[1, c("review_id", "occurrence_id")]
  decisions$status <- "selected"; decisions$candidate_id <- "currency"
  decisions$reviewer <- "author"; decisions$reason <- "Deliberately mismatched target"
  expect_error(do.call(lexdiv_ambiguity_review, c(f, list(decisions = decisions))), "not a candidate")
})

test_that("Unicode display and codepoint spans retain decomposed and supplementary characters", {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  f <- ambiguity_fixture()
  f$x <- lexdiv_import_annotations(data.frame(document_id = "d", segment_id = "s", token_index = 1:4,
    surface = c("\U0001f600", "e\u0301", "\u00e9", "e\u0301")),
    data.frame(document_id = "d", segment_id = "s", text = "\U0001f600 e\u0301 \u00e9 e\u0301"),
    f$x$provenance$annotation)
  f$targets <- c("e\u0301", "\u00e9"); f$candidates <- f$candidates[FALSE, ]
  r <- do.call(lexdiv_ambiguity_review, f)
  expect_identical(r$occurrences$start, c(3L, 6L, 8L))
  expect_identical(r$occurrences$end, c(4L, 6L, 9L))
  expect_identical(r$summary$occurrences, c(2L, 1L))
  expect_identical(stringi::stri_sub(r$occurrences$segment_text,
    r$occurrences$start, r$occurrences$end), f$x$tokens$surface[2:4])
  f$targets <- "e\u0301"
  expect_identical(do.call(lexdiv_ambiguity_review, f)$occurrences$token_index, c(2L, 4L))
  f$targets <- "\u00e9"
  expect_identical(do.call(lexdiv_ambiguity_review, f)$occurrences$token_index, 3L)
})
