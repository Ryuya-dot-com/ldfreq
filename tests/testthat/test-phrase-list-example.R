phrase_example <- function() {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  env <- new.env(parent = globalenv())
  invisible(capture.output(sys.source(system.file("examples", "phrase-list-demo.R",
    package = "ldfreq", mustWork = TRUE), envir = env)))
  env
}

test_that("the installed phrase example preserves counts, source KWIC and denominators", {
  e <- phrase_example(); x <- e$result
  expect_equal(x$documents$source_tokens, c(15, 8, 0))
  expect_equal(x$documents$retained_tokens, c(12, 7, 0))
  expect_equal(x$documents$occurrences, c(4, 1, 0))
  expect_equal(x$documents$covered_tokens, c(9, 4, 0))
  expect_equal(x$documents$coverage, c(9/12, 4/7, NA))
  expect_equal(x$summary$occurrences, c(1, 2, 1, 1, 0))
  expect_equal(x$summary$documents, c(1, 1, 1, 1, 0))
  expect_equal(nrow(x$counts), 15)
  expect_true(all(x$counts$occurrences[x$counts$document_id == "empty"] == 0))
  hits <- x$occurrences
  expect_identical(stringi::stri_sub(hits$segment_text, hits$start, hits$end), hits$keyword)
  ja <- hits[hits$phrase_id == "japanese", ]
  expect_identical(ja$keyword, "国際協力を学ぶ")
  expect_identical(ja$pre, "連合で")
  expect_identical(ja$post, "。")
  expect_equal(c(ja$start, ja$end), c(6, 12))
  expect_false(any(hits$segment_id == "s2")) # Removing "very" must not close the gap.
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(x, path); expect_identical(readRDS(path), x)
  expect_identical(e$phrase_list_kwic(e$annotations, e$phrases, e$resource, e$keep, 2L), x)
  all_excluded <- e$phrase_list_kwic(e$annotations, e$phrases, e$resource,
    rep(FALSE, nrow(e$annotations$tokens)))
  expect_equal(nrow(all_excluded$occurrences), 0)
  expect_true(all(is.na(all_excluded$documents$coverage)))
  expect_true(all(all_excluded$counts$occurrences == 0))
  absent <- e$phrase_list_kwic(e$annotations, e$phrases["absent"], e$resource)
  expect_equal(nrow(absent$occurrences), 0)
  expect_identical(names(absent$occurrences), names(hits))
  expect_equal(absent$documents$coverage, c(0, 0, NA))
})

test_that("all overlaps and duplicate list entries retain identity without inflating coverage", {
  e <- phrase_example()
  segments <- data.frame(document_id = c("repeat", "punct", "boundary", "boundary", "other"),
    segment_id = c("s", "s", "s1", "s2", "s"), text = c("a a a a", "a , a", "a", "a", "a"))
  surfaces <- list(rep("a", 4), c("a", ",", "a"), "a", "a", "a")
  tokens <- do.call(rbind, lapply(seq_along(surfaces), function(i) data.frame(
    document_id = segments$document_id[i], segment_id = segments$segment_id[i],
    token_index = seq_along(surfaces[[i]]), surface = surfaces[[i]])))
  a <- lexdiv_import_annotations(tokens, segments, e$annotations$provenance$annotation)
  phrases <- list(pair = c("a", "a"), triple = rep("a", 3), four = rep("a", 4),
    same_pair_other_id = c("a", "a"), punctuation = c("a", ",", "a"))
  result <- e$phrase_list_kwic(a, phrases, e$resource, tokens$surface != ",", window = 0)
  expect_equal(result$summary$occurrences, c(3, 2, 1, 3, 0))
  expect_equal(result$documents$occurrences, c(9, 0, 0, 0))
  expect_equal(result$documents$covered_tokens, c(4, 0, 0, 0))
  expect_equal(result$documents$coverage, c(1, 0, 0, 0))
  hits <- result$occurrences
  expect_equal(hits$from[hits$phrase_id == "pair"], 1:3)
  expect_equal(hits$to[hits$phrase_id == "pair"], 2:4)
  expect_true(all(hits$pre == "" & hits$post == ""))
  punct <- e$phrase_list_kwic(a, phrases["punctuation"], e$resource)
  expect_identical(punct$occurrences$keyword, "a , a")
  expect_equal(punct$documents$covered_tokens, c(0, 3, 0, 0))
})

test_that("original Unicode and explicit components are not normalized or split", {
  e <- phrase_example()
  surfaces <- c("😀", "が", "猫", "が", "猫", "a_b", "a", "a", "b_a", "A", "a")
  tokens <- data.frame(document_id = "unicode", segment_id = "s",
    token_index = seq_along(surfaces), surface = surfaces)
  a <- lexdiv_import_annotations(tokens,
    data.frame(document_id = "unicode", segment_id = "s", text = paste(surfaces, collapse = " ")),
    e$annotations$provenance$annotation)
  p <- list(decomposed = c("が", "猫"), composed = c("が", "猫"),
    underscore_left = c("a_b", "a"), underscore_right = c("a", "b_a"),
    upper = c("A", "a"))
  x <- e$phrase_list_kwic(a, p, e$resource, window = 1)
  expect_equal(x$summary$occurrences, rep(1, 5))
  expect_equal(x$occurrences$from, c(2, 4, 6, 8, 10))
  expect_equal(x$occurrences$start[1], 3)
  expect_identical(x$occurrences$pre[1], "😀 ")
  expect_identical(x$occurrences$keyword[1:2], c("が 猫", "が 猫"))
  expect_identical(x$occurrences$post[5], "")
})

test_that("modified source and ambiguous phrase specifications fail before analysis", {
  e <- phrase_example(); a <- e$annotations
  a$tokens$surface[1] <- "Changed"
  expect_error(e$phrase_list_kwic(a, e$phrases, e$resource), "align")
  a <- e$annotations; a$documents$document_id[1] <- "Changed"
  expect_error(e$phrase_list_kwic(a, e$phrases, e$resource), "has changed")
  expect_error(e$phrase_list_kwic(e$annotations, list(p = "two words"), e$resource), "phrases")
  expect_error(e$phrase_list_kwic(e$annotations, list(p = c("two words", "x")), e$resource), "phrases")
  expect_error(e$phrase_list_kwic(e$annotations, unname(e$phrases), e$resource), "phrases")
  expect_error(e$phrase_list_kwic(e$annotations, c(e$phrases, e$phrases), e$resource), "phrases")
  expect_error(e$phrase_list_kwic(e$annotations, e$phrases, list()), "resource")
  expect_error(e$phrase_list_kwic(e$annotations, e$phrases, e$resource, keep = TRUE), "keep")
  expect_error(e$phrase_list_kwic(e$annotations, e$phrases, e$resource, window = 0.5), "window")
})

phrase_review_example <- function() {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  env <- new.env(parent = globalenv())
  invisible(capture.output(sys.source(system.file("examples", "phrase-review-demo.R",
    package = "ldfreq", mustWork = TRUE), envir = env)))
  env
}

test_that("phrase decisions retain states, empty documents and overlap-aware coverage", {
  e <- phrase_review_example(); x <- e$phrase_after; d <- x$documents
  expect_identical(d$document_id, c("en", "en_pending", "ja", "ja_pending", "no_match", "empty"))
  expect_equal(d$retained_tokens, c(11, 11, 18, 13, 5, 0))
  expect_equal(d$occurrences, c(3, 3, 2, 2, 0, 0))
  expect_equal(d$accepted, c(2, 0, 1, 0, 0, 0))
  expect_equal(d$rejected, c(1, 0, 1, 0, 0, 0))
  expect_equal(d$unresolved, c(0, 1, 0, 1, 0, 0))
  expect_equal(d$unreviewed, c(0, 2, 0, 1, 0, 0))
  expect_equal(d$covered_tokens, c(5, 5, 8, 8, 0, 0))
  expect_equal(d$accepted_covered_tokens, c(3, 0, 4, 0, 0, 0))
  expect_equal(d$accepted_coverage, c(3/11, 0, 4/18, 0, 0, NA))
  expect_equal(d$reportable_accepted_coverage, c(3/11, NA, 4/18, NA, 0, NA))
  expect_identical(d$review_complete, c(TRUE, FALSE, TRUE, FALSE, TRUE, TRUE))
  states <- c("accepted", "rejected", "unresolved", "unreviewed")
  expect_equal(rowSums(d[states]), d$occurrences)
  expect_equal(rowSums(x$counts[states]), x$counts$occurrences)
  expect_equal(nrow(x$counts), 24L)
  expect_true(all(x$counts$occurrences[x$counts$phrase_id == "absent"] == 0L))
  expect_identical(x$source, e$phrase_search)
  expect_identical(x$source$source, e$phrase_annotations)
  expect_identical(stringi::stri_sub(x$occurrences$segment_text,
    x$occurrences$start, x$occurrences$end), x$occurrences$keyword)
  expect_identical(x$worksheet$occurrence_id, e$phrase_before$worksheet$occurrence_id)
  expect_true(all(vapply(x$worksheet, is.character, logical(1))))
  expect_identical(e$phrase_record, e$phrase_restored)
  # Fixed hand-counts also check that all accepted nested lengths (3 + 2)
  # do not inflate the English union (3), nor change the token denominator (11).
  en <- subset(x$occurrences, document_id == "en" & status == "accepted")
  expect_equal(sum(en$to - en$from + 1L), 5L)
  expect_equal(d$accepted_covered_tokens[1], 3L)
  all_unreviewed <- e$phrase_before$documents
  expect_true(all(is.na(all_unreviewed$reportable_accepted_coverage[1:4])))
})

test_that("phrase worksheets refuse changed anchors, stale criteria and partial decisions", {
  e <- phrase_review_example(); w <- e$phrase_after$worksheet
  apply <- function(sheet = w, criterion = e$phrase_criterion, result = e$phrase_search)
    e$phrase_list_review(result, criterion, worksheet = sheet)
  for (field in setdiff(names(w), c("status", "reviewer", "reason"))) {
    edited <- w; edited[[field]][1] <- paste0(edited[[field]][1], "changed")
    expect_error(apply(edited), if (field == "occurrence_id") "every original" else "fixed worksheet")
  }
  expect_error(apply(w[-1, ]), "every original")
  expect_error(apply(rbind(w, w[1, ])), "every original")
  edited <- w; edited$from <- as.numeric(edited$from)
  expect_error(apply(edited), "as character")
  expect_error(apply(criterion = "Changed interpretation criterion."), "fixed worksheet")
  expect_error(apply(criterion = " "), "criterion")
  edited <- w; edited$status[1] <- "selected"
  expect_error(apply(edited), "Status must")
  edited$status[1] <- NA_character_
  expect_error(apply(edited), "Status must")
  for (field in c("reviewer", "reason")) {
    edited <- w; edited[[field]][which(edited$status == "unresolved")[1]] <- "  "
    expect_error(apply(edited), "reviewer and reason")
    edited <- w; edited[[field]][which(edited$status == "unreviewed")[1]] <- "partly filled"
    expect_error(apply(edited), "partly filled")
  }
  changed <- e$phrase_search; changed$occurrences$keyword[1] <- "changed"
  expect_error(apply(result = changed), "search result changed")
  changed <- e$phrase_search; changed$documents$retained_tokens[1] <- 999L
  expect_error(apply(result = changed), "search result changed")
  changed <- e$phrase_search; changed$provenance$input_sha256 <- "changed"
  expect_error(apply(result = changed), "search result changed")
  resource <- e$phrase_resource; resource$resource_version <- "2"
  changed <- e$phrase_list_kwic(e$phrase_annotations, e$review_phrases, resource,
    e$phrase_keep, window = 3L)
  expect_error(apply(result = changed), "fixed worksheet")
  phrases <- e$review_phrases; phrases$absent <- c("still", "absent")
  changed <- e$phrase_list_kwic(e$phrase_annotations, phrases, e$phrase_resource,
    e$phrase_keep, window = 3L)
  expect_error(apply(result = changed), "fixed worksheet")
  keep <- e$phrase_keep; keep[1] <- FALSE
  changed <- e$phrase_list_kwic(e$phrase_annotations, e$review_phrases, e$phrase_resource,
    keep, window = 3L)
  expect_error(apply(result = changed), "fixed worksheet")
  # A valid source edit outside the phrase preserves its span but invalidates review.
  tokens <- e$phrase_tokens; tokens$surface[1] <- "Our"
  segments <- e$phrase_segments; segments$text[1] <- sub("^The", "Our", segments$text[1])
  annotations <- lexdiv_import_annotations(tokens, segments,
    e$phrase_annotations$provenance$annotation)
  changed <- e$phrase_list_kwic(annotations, e$review_phrases, e$phrase_resource,
    e$phrase_keep, window = 3L)
  expect_identical(changed$occurrences$start, e$phrase_search$occurrences$start)
  expect_identical(changed$occurrences$keyword, e$phrase_search$occurrences$keyword)
  expect_error(apply(result = changed), "fixed worksheet")
})

test_that("reviewing absent matches and duplicate phrase IDs preserves the search population", {
  e <- phrase_example()
  result <- e$phrase_list_kwic(e$annotations, e$phrases["absent"], e$resource, e$keep)
  reviewed <- e$phrase_list_review(result, "Retain listed occurrences.")
  expect_equal(nrow(reviewed$worksheet), 0L)
  expect_identical(reviewed$documents$review_complete, rep(TRUE, 3))
  expect_equal(reviewed$documents$reportable_accepted_coverage, c(0, 0, NA))
  expect_identical(e$phrase_list_review(result, reviewed$criterion, reviewed$worksheet), reviewed)
  excluded <- e$phrase_list_kwic(e$annotations, e$phrases, e$resource,
    rep(FALSE, nrow(e$annotations$tokens)))
  reviewed <- e$phrase_list_review(excluded, "Retain listed occurrences.")
  expect_true(all(reviewed$documents$review_complete))
  expect_true(all(is.na(reviewed$documents$reportable_accepted_coverage)))
  # Duplicated spellings under distinct list IDs have distinct decisions.
  phrases <- list(first = c("in", "the", "end"), second = c("in", "the", "end"))
  result <- e$phrase_list_kwic(e$annotations, phrases, e$resource, e$keep)
  before <- e$phrase_list_review(result, "Accept both listed IDs.")
  sheet <- before$worksheet
  expect_equal(nrow(sheet), 2L) # The deleted 'very' still blocks a third/fourth hit.
  expect_equal(length(unique(sheet$occurrence_id)), 2L)
  sheet$status <- "accepted"; sheet$reviewer <- "demo"; sheet$reason <- "Both IDs in scope."
  after <- e$phrase_list_review(result, before$criterion, sheet)
  expect_equal(after$documents$accepted, c(2, 0, 0))
  expect_equal(after$documents$accepted_covered_tokens, c(3, 0, 0))
  expect_equal(after$documents$reportable_accepted_coverage, c(3/12, 0, NA))
})
