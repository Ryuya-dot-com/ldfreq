family_fixture <- function(surface = c("use", "reusability", "use"),
                           upos = rep("NOUN", length(surface))) {
  list(annotations = lexdiv_import_annotations(
    data.frame(document_id = rep("d", length(surface)), segment_id = rep("s", length(surface)),
      token_index = seq_along(surface), surface = surface, lemma = surface, upos = upos),
    data.frame(document_id = c("d", "empty"), segment_id = "s",
      text = c(paste(surface, collapse = " "), "")),
    list(language = "en", analyzer = "authored", analyzer_version = "1",
      dictionary = "none", dictionary_version = "none", unit = "word", normalization = "none")),
    dictionary = data.frame(record_id = c("01", "02"), form = c("use", "reusability"),
      family_id = c("USE", "USE")),
    resource = list(resource_id = "authored", resource_version = "1", language = "en",
      source_reference = "authored fixture", data_license = "MIT", lookup_unit = "surface",
      family_definition = "Authored example only"))
}

test_that("families preserve tokens, source positions, empty documents and repetition", {
  f <- family_fixture()
  x <- do.call(lexdiv_family_profile, f)
  expect_identical(x$annotations, f$annotations)
  expect_identical(x$dictionary, f$dictionary)
  expect_identical(x$occurrences$family_id, rep("USE", 3))
  expect_identical(x$occurrences$start, c(1L, 5L, 17L))
  expect_identical(x$occurrences$pre, c("", "use ", "use reusability "))
  expect_identical(x$occurrences$post, c(" reusability use", " use", ""))
  expect_equal(x$members$n, c(2, 1))
  expect_equal(x$documents$selected_tokens, c(3, 0))
  expect_equal(x$documents$family_types, c(1, 0))
  expect_equal(x$documents$family_ttr, c(1/3, NA))
  expect_equal(x$documents$token_coverage, c(1, NA))
  expect_identical(x$documents$status, c("complete", "empty"))
  expect_equal(x$summary$family_ttr, lexdiv_metrics(rep("USE", 3), "ttr")$value)
  x <- do.call(lexdiv_family_profile, c(f, list(context_chars = 0)))
  expect_identical(x$occurrences$pre, rep("", 3))
  expect_identical(x$occurrences$post, rep("", 3))
})

test_that("unknown and multiple-family forms do not acquire invented families", {
  f <- family_fixture(c("use", "bank", "quux"))
  f$dictionary <- rbind(f$dictionary, data.frame(record_id = c("03", "04", "05"),
    form = c("bank", "bank", "use"), family_id = c("RIVER", "FINANCE", "USE")))
  x <- do.call(lexdiv_family_profile, f)
  expect_identical(x$occurrences$status, c("matched", "ambiguous", "unlisted"))
  expect_equal(x$occurrences$candidate_records, c(2, 2, 0))
  expect_equal(x$occurrences$candidate_families, c(1, 2, 0))
  expect_identical(x$occurrences$family_id, c("USE", NA_character_, NA_character_))
  expect_identical(x$candidates$record_id, c("01", "05", "03", "04"))
  expect_equal(x$summary$observed_family_types, 1)
  expect_equal(x$summary$unresolved_tokens, 2)
  expect_equal(x$summary$token_coverage, 1/3)
  expect_true(is.na(x$summary$family_types))
  expect_true(is.na(x$summary$family_ttr))
  expect_error(do.call(lexdiv_family_profile, c(f, list(max_candidates = 4))), "Dictionary")
  f <- family_fixture(rep("use", 4))
  expect_error(do.call(lexdiv_family_profile, c(f, list(max_candidates = 3))), "Expanded")
})

test_that("POS selection and POS matching disclose different missingness", {
  f <- family_fixture(c("use", "reusability", "."), c("VERB", NA, "PUNCT"))
  f$dictionary$upos <- c("VERB", "NOUN")
  x <- do.call(lexdiv_family_profile, f)
  expect_identical(x$occurrences$status, c("matched", "missing_pos", "unlisted"))
  expect_equal(x$summary$selected_tokens, 3)
  x <- do.call(lexdiv_family_profile, c(f, list(exclude_pos = "PUNCT")))
  expect_identical(x$occurrences$status, c("matched", "unknown_selection", "excluded"))
  expect_equal(x$summary$known_selected_tokens, 1)
  expect_true(is.na(x$summary$selected_tokens))
  expect_true(is.na(x$summary$token_coverage))
  expect_equal(x$summary$conditional_token_coverage, 1)
  expect_true(is.na(x$summary$family_ttr))
  f <- family_fixture("use", "NOUN")
  f$dictionary <- data.frame(record_id = c("v", "n"), form = "use",
    family_id = c("USE_VERB", "USE_NOUN"), upos = c("VERB", "NOUN"))
  expect_identical(do.call(lexdiv_family_profile, f)$occurrences$family_id, "USE_NOUN")
  x <- do.call(lexdiv_family_profile, c(f, list(exclude_pos = "NOUN")))
  expect_equal(x$summary$family_types, 0)
  expect_true(is.na(x$summary$family_ttr))
  expect_identical(x$summary$status, "no_selected_tokens")
})

test_that("normalization is explicit and collisions retain candidate families", {
  f <- family_fixture(c("Use", "ｕｓｅ", "reusability"))
  expect_equal(do.call(lexdiv_family_profile, f)$summary$matched_tokens, 1)
  x <- do.call(lexdiv_family_profile, c(f, list(normalization = "nfkc_lower")))
  expect_equal(x$summary$matched_tokens, 3)
  expect_identical(x$occurrences$surface, f$annotations$tokens$surface)
  expect_identical(x$occurrences$query, c("use", "use", "reusability"))
  f$dictionary <- rbind(f$dictionary,
    data.frame(record_id = "03", form = "USE", family_id = "DIFFERENT"))
  x <- do.call(lexdiv_family_profile, c(f, list(normalization = "nfkc_lower")))
  expect_identical(x$occurrences$status, c("ambiguous", "ambiguous", "matched"))
})

test_that("missing lexical units and empty resources retain honest totals", {
  f <- family_fixture(character())
  x <- do.call(lexdiv_family_profile, f)
  expect_equal(nrow(x$occurrences), 0)
  expect_equal(nrow(x$candidates), 0)
  expect_equal(nrow(x$members), 0)
  expect_identical(x$documents$status, rep("empty", 2))
  f <- family_fixture()
  f$dictionary <- f$dictionary[FALSE, ]
  x <- do.call(lexdiv_family_profile, f)
  expect_equal(x$summary$token_coverage, 0)
  expect_equal(x$summary$observed_family_types, 0)
  expect_true(is.na(x$summary$family_types))
  data <- f$annotations$tokens
  data$lemma[2] <- NA_character_
  f$annotations <- lexdiv_import_annotations(data,
    f$annotations$segments[c("document_id", "segment_id", "text")],
    f$annotations$provenance$annotation)
  f$resource$lookup_unit <- "lemma"
  x <- do.call(lexdiv_family_profile, c(f, list(unit = "lemma")))
  expect_identical(x$occurrences$status, c("unlisted", "missing_unit", "unlisted"))
})

test_that("declared resources and complete inputs survive CSV and RDS replay", {
  f <- family_fixture()
  x <- do.call(lexdiv_family_profile, f)
  csv <- tempfile(fileext = ".csv")
  rds <- tempfile(fileext = ".rds")
  on.exit(unlink(c(csv, rds)))
  write.csv(f$dictionary, csv, row.names = FALSE, fileEncoding = "UTF-8")
  f$dictionary <- read.csv(csv, colClasses = "character", fileEncoding = "UTF-8")
  expect_identical(do.call(lexdiv_family_profile, f), x)
  saveRDS(x, rds)
  y <- readRDS(rds)
  expect_identical(lexdiv_family_profile(y$annotations, y$dictionary, y$provenance$resource), x)
  f$resource$family_definition <- "Different declared definition"
  expect_false(identical(do.call(lexdiv_family_profile, f)$provenance$content_sha256,
    x$provenance$content_sha256))
  expect_identical(do.call(lexdiv_family_profile, f)$provenance$resource_sha256,
    x$provenance$resource_sha256)
})

test_that("malformed schemas and incompatible declarations are rejected", {
  f <- family_fixture()
  for (field in c("record_id", "form", "family_id")) {
    g <- f; g$dictionary[[field]] <- NULL
    expect_error(do.call(lexdiv_family_profile, g), "requires")
    g <- f; g$dictionary[[field]][1] <- " "
    expect_error(do.call(lexdiv_family_profile, g), "blank")
  }
  g <- f; g$dictionary$record_id[] <- "same"
  expect_error(do.call(lexdiv_family_profile, g), "unique")
  g <- f; g$dictionary$record_id <- 1:2
  expect_error(do.call(lexdiv_family_profile, g), "character")
  g <- f; g$resource$lookup_unit <- "lemma"
  expect_error(do.call(lexdiv_family_profile, g), "agree")
  g <- f; g$resource$data_license <- NULL
  expect_error(do.call(lexdiv_family_profile, g), "requires")
  g <- f; g$dictionary$upos <- "NN"
  expect_error(do.call(lexdiv_family_profile, g), "UD tags")
  g <- f; g$annotations$tokens$surface[1] <- "changed"
  expect_error(do.call(lexdiv_family_profile, g), "align exactly")
  expect_error(do.call(lexdiv_family_profile, c(f, list(exclude_pos = "NN"))), "UD POS")
  expect_error(do.call(lexdiv_family_profile, c(f, list(max_tokens = 2))), "max_tokens")
})

test_that("multiple source segments and document totals do not pool document TTRs", {
  f <- family_fixture()
  data <- data.frame(document_id = c("a:b", "a:b", rep("a", 3)),
    segment_id = c("c", "c", "b:c", "b:c", "b:c"), token_index = c(1:2, 1:3),
    surface = c("a", "b", "a", "a", "a"))
  segments <- data.frame(document_id = c("a:b", "a:b", "a"),
    segment_id = c("c", "empty", "b:c"), text = c("a b", "", "a a a"))
  f$annotations <- lexdiv_import_annotations(data, segments, f$annotations$provenance$annotation)
  f$dictionary$form <- c("a", "b")
  f$dictionary$family_id <- c("a:b", "a")
  x <- do.call(lexdiv_family_profile, f)
  expect_identical(x$occurrences$document_id, data$document_id)
  expect_identical(x$occurrences$segment_id, data$segment_id)
  expect_equal(x$documents$family_ttr, c(1, 1/3))
  expect_equal(x$summary$family_ttr, 2/5)
  expect_equal(x$members$n, c(1, 1, 3))
  expect_identical(x$occurrences$post, c(" b", "", " a a", " a", ""))
})

test_that("each occurrence agrees with a separate record-by-record lookup", {
  f <- family_fixture(c("use", "Use", "reusability", "use", "unlisted"))
  f$dictionary <- rbind(f$dictionary,
    data.frame(record_id = c("03", "04", "05"), form = c("Use", "use", "use"),
      family_id = c("use", "USE", "OTHER")))
  f$dictionary$note <- c("one", "two", "three", "four", "five")
  x <- do.call(lexdiv_family_profile, f)
  for (i in seq_len(nrow(f$annotations$tokens))) {
    ref <- f$dictionary[f$dictionary$form == f$annotations$tokens$surface[i], ]
    families <- unique(ref$family_id)
    expect_identical(x$candidates$record_id[x$candidates$token_index == i], ref$record_id)
    expect_equal(x$occurrences$candidate_families[i], length(families))
    expect_identical(x$occurrences$family_id[i],
      if (length(families) == 1) families else NA_character_)
  }
  expect_identical(x$dictionary$note, f$dictionary$note)
  f$dictionary <- f$dictionary[nrow(f$dictionary):1, ]
  y <- do.call(lexdiv_family_profile, f)
  expect_identical(y$occurrences, x$occurrences)
  expect_identical(y$summary, x$summary)
})

test_that("installed example compares the same occurrences without dropping unresolved gaps", {
  env <- new.env(parent = baseenv())
  sys.source(system.file("examples", "word-families.R", package = "ldfreq", mustWork = TRUE), env)
  x <- env$word_families_example
  expect_equal(x$comparison$N, rep(4, 8))
  expect_equal(x$comparison$V, rep(c(3, 2, 2, 1), each = 2))
  expect_equal(x$comparison$value, c(.75, 1, .5, 2/3, .5, 2/3, .25, 1/3))
  expect_identical(x$profile$documents$status, c("complete", "incomplete", "empty"))
})

family_review_fixture <- function() {
  f <- family_fixture(c("bank", "bank", "use"))
  f$dictionary <- data.frame(record_id = c("f", "r", "u"), form = c("bank", "bank", "use"),
    family_id = c("FINANCE", "RIVER", "USE"))
  base <- do.call(lexdiv_family_profile, f)
  review <- do.call(lexdiv_ambiguity_review, c(list(x = base$annotations), base$review_input))
  decisions <- review$occurrences[1:2, c("review_id", "occurrence_id")]
  decisions$status <- "selected"
  decisions$candidate_id <- c("f", "r")
  decisions$reviewer <- "test-author"
  decisions$reason <- c("Authored finance context", "Authored river context")
  list(f = f, base = base, review = review, decisions = decisions)
}

test_that("existing reviews assign each occurrence without changing the dictionary", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- family_review_fixture()
  review <- do.call(lexdiv_ambiguity_review, c(list(x = f$base$annotations),
    f$base$review_input, list(decisions = f$decisions[2:1, ])))
  x <- do.call(lexdiv_family_profile, c(f$f, list(review = review)))
  expect_identical(x$dictionary, f$base$dictionary)
  expect_identical(x$annotations, f$base$annotations)
  expect_identical(x$occurrences$lookup_status, c("ambiguous", "ambiguous", "matched"))
  expect_identical(x$occurrences$lookup_family_id, c(NA_character_, NA_character_, "USE"))
  expect_identical(x$occurrences$family_id, c("FINANCE", "RIVER", "USE"))
  expect_identical(x$occurrences$review_record_id, c("f", "r", NA_character_))
  expect_identical(x$occurrences$review_status, c("selected", "selected", "unreviewed"))
  expect_identical(x$review, review)
  expect_equal(x$summary$family_ttr, 1)
  expect_equal(x$summary$review_selected_tokens, 2)
  expect_equal(x$summary$ambiguous_tokens, 0)
  expect_equal(x$summary$token_coverage, 1)
  expect_equal(x$members$n, c(1, 1, 1))
  y <- do.call(lexdiv_family_profile, c(f$f, list(review = f$review)))
  expect_identical(y$occurrences$family_id, f$base$occurrences$family_id)
  expect_true(is.na(y$summary$family_ttr))
})

test_that("partial decisions and explicit unresolved judgments cannot hide gaps", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- family_review_fixture()
  decisions <- f$decisions[1, ]
  review <- do.call(lexdiv_ambiguity_review, c(list(x = f$base$annotations),
    f$base$review_input, list(decisions = decisions)))
  x <- do.call(lexdiv_family_profile, c(f$f, list(review = review)))
  expect_equal(x$summary$matched_tokens, 2)
  expect_equal(x$summary$ambiguous_tokens, 1)
  expect_true(is.na(x$summary$family_ttr))
  decisions <- f$review$occurrences[3, c("review_id", "occurrence_id")]
  decisions$status <- "unresolved"; decisions$candidate_id <- NA_character_
  decisions$reviewer <- "reviewer"; decisions$reason <- "Questionable unique-family assignment"
  review <- do.call(lexdiv_ambiguity_review, c(list(x = f$base$annotations),
    f$base$review_input, list(decisions = decisions)))
  x <- do.call(lexdiv_family_profile, c(f$f, list(review = review)))
  expect_identical(x$occurrences$status, c("ambiguous", "ambiguous", "review_unresolved"))
  expect_equal(x$summary$withheld_tokens, 1)
  expect_equal(x$summary$review_unresolved_tokens, 1)
  expect_equal(x$summary$unresolved_tokens, 3)
  expect_equal(x$summary$token_coverage, 0)
  expect_true(all(is.na(x$occurrences$family_id)))
  expect_equal(nrow(x$members), 0)
})

test_that("family decisions are bound to the full source, table and counting policy", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- family_review_fixture()
  variants <- list(f$f, f$f, f$f, f$f, f$f)
  variants[[1]]$dictionary$family_id[1] <- "OTHER"
  variants[[2]]$resource$family_definition <- "Different inclusion criteria"
  variants[[3]]$resource$resource_version <- "2"
  variants[[4]]$normalization <- "nfkc_lower"
  variants[[5]]$exclude_pos <- "PUNCT"
  for (v in variants)
    expect_error(do.call(lexdiv_family_profile, c(v, list(review = f$review))), "Review differs")
  # Reimport a modified annotation instead of editing a sealed object.
  v <- f$f
  data <- v$annotations$tokens
  data$upos[1] <- "VERB"
  v$annotations <- lexdiv_import_annotations(data,
    v$annotations$segments[c("document_id", "segment_id", "text")],
    v$annotations$provenance$annotation)
  expect_error(do.call(lexdiv_family_profile, c(v, list(review = f$review))), "Review differs")
  bad <- f$review; bad$occurrences$candidate_id[1] <- "f"
  expect_error(do.call(lexdiv_family_profile, c(f$f, list(review = bad))), "unmodified")
  # A valid generic review with an incomplete candidate display is not enough.
  input <- f$base$review_input; input$candidates <- input$candidates[-1, ]
  review <- do.call(lexdiv_ambiguity_review, c(list(x = f$base$annotations), input))
  expect_error(do.call(lexdiv_family_profile, c(f$f, list(review = review))), "Review differs")
  x <- do.call(lexdiv_family_profile, c(f$f, list(review = f$review, context_chars = 0)))
  expect_identical(x$review_input, f$base$review_input)
  expect_identical(x$occurrences$pre, rep("", 3))
})

test_that("surface-based review cannot borrow another occurrence's POS or lemma candidate", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- family_fixture(c("use", "use"), c("VERB", "NOUN"))
  f$dictionary <- data.frame(record_id = c("verb", "noun"), form = "use",
    family_id = c("USE_VERB", "USE_NOUN"), upos = c("VERB", "NOUN"))
  base <- do.call(lexdiv_family_profile, f)
  review <- do.call(lexdiv_ambiguity_review, c(list(x = base$annotations), base$review_input))
  decisions <- review$occurrences[1, c("review_id", "occurrence_id")]
  decisions$status <- "selected"; decisions$candidate_id <- "noun"
  decisions$reviewer <- "test-author"; decisions$reason <- "Deliberately wrong POS"
  review <- do.call(lexdiv_ambiguity_review, c(list(x = base$annotations),
    base$review_input, list(decisions = decisions)))
  expect_error(do.call(lexdiv_family_profile, c(f, list(review = review))), "not eligible")
  f$exclude_pos <- "NOUN"
  base <- do.call(lexdiv_family_profile, f)
  review <- do.call(lexdiv_ambiguity_review, c(list(x = base$annotations), base$review_input))
  decisions <- review$occurrences[2, c("review_id", "occurrence_id")]
  decisions$status <- "selected"; decisions$candidate_id <- "verb"
  decisions$reviewer <- "test-author"; decisions$reason <- "Deliberately excluded occurrence"
  review <- do.call(lexdiv_ambiguity_review, c(list(x = base$annotations),
    base$review_input, list(decisions = decisions)))
  expect_error(do.call(lexdiv_family_profile, c(f, list(review = review))), "known-selected")
})

test_that("normalized lookup keeps original review surfaces and literal record IDs", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- family_fixture(c("Bank", "bank"))
  f$dictionary <- data.frame(record_id = c("NA", "01"), form = "bank", family_id = c("F", "R"))
  f$normalization <- "nfkc_lower"
  base <- do.call(lexdiv_family_profile, f)
  expect_setequal(base$review_input$targets, c("Bank", "bank"))
  review <- do.call(lexdiv_ambiguity_review, c(list(x = base$annotations), base$review_input))
  decisions <- review$occurrences[c("review_id", "occurrence_id")]
  decisions$status <- "selected"; decisions$candidate_id <- c("NA", "01")
  decisions$reviewer <- "test-author"; decisions$reason <- "Authored decision"
  path <- tempfile(fileext = ".csv"); on.exit(unlink(path))
  utils::write.csv(decisions, path, row.names = FALSE, na = "")
  decisions <- utils::read.csv(path, colClasses = "character", na.strings = "", check.names = FALSE)
  review <- do.call(lexdiv_ambiguity_review, c(list(x = base$annotations),
    base$review_input, list(decisions = decisions, window = 0)))
  x <- do.call(lexdiv_family_profile, c(f, list(review = review)))
  expect_identical(x$occurrences$family_id, c("F", "R"))
  expect_identical(x$occurrences$surface, c("Bank", "bank"))
  saveRDS(x, path); restored <- readRDS(path)
  p <- restored$provenance
  expect_identical(lexdiv_family_profile(restored$annotations, restored$dictionary, p$resource,
    normalization = p$normalization, review = restored$review), x)
})

test_that("lemma-dependent candidates and unknown selection stay occurrence-specific", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- family_fixture(c("saw", "saw"), c("VERB", "NOUN"))
  data <- f$annotations$tokens
  data$lemma <- c("see", "saw")
  f$annotations <- lexdiv_import_annotations(data,
    f$annotations$segments[c("document_id", "segment_id", "text")],
    f$annotations$provenance$annotation)
  f$dictionary <- data.frame(record_id = c("see", "saw"), form = c("see", "saw"),
    family_id = c("SEE", "SAW"))
  f$unit <- "lemma"; f$resource$lookup_unit <- "lemma"
  base <- do.call(lexdiv_family_profile, f)
  review <- do.call(lexdiv_ambiguity_review, c(list(x = base$annotations), base$review_input))
  decisions <- review$occurrences[1, c("review_id", "occurrence_id")]
  decisions$status <- "selected"; decisions$candidate_id <- "saw"
  decisions$reviewer <- "test-author"; decisions$reason <- "Deliberately wrong lemma"
  wrong <- do.call(lexdiv_ambiguity_review, c(list(x = base$annotations),
    base$review_input, list(decisions = decisions)))
  expect_error(do.call(lexdiv_family_profile, c(f, list(review = wrong))), "not eligible")
  decisions$candidate_id <- "see"
  right <- do.call(lexdiv_ambiguity_review, c(list(x = base$annotations),
    base$review_input, list(decisions = decisions)))
  expect_identical(do.call(lexdiv_family_profile, c(f, list(review = right)))$occurrences$family_id,
    c("SEE", "SAW"))
  data$upos[1] <- NA_character_
  f$annotations <- lexdiv_import_annotations(data,
    f$annotations$segments[c("document_id", "segment_id", "text")],
    f$annotations$provenance$annotation)
  f$exclude_pos <- "PUNCT"
  base <- do.call(lexdiv_family_profile, f)
  review <- do.call(lexdiv_ambiguity_review, c(list(x = base$annotations), base$review_input))
  decisions <- review$occurrences[1, c("review_id", "occurrence_id")]
  decisions$status <- "unresolved"; decisions$candidate_id <- NA_character_
  decisions$reviewer <- "test-author"; decisions$reason <- "Unknown selection is not a family judgment"
  review <- do.call(lexdiv_ambiguity_review, c(list(x = base$annotations),
    base$review_input, list(decisions = decisions)))
  expect_error(do.call(lexdiv_family_profile, c(f, list(review = review))), "known-selected")
  f$dictionary <- f$dictionary[FALSE, ]
  base <- do.call(lexdiv_family_profile, f)
  expect_identical(base$review_input$targets, character())
  expect_equal(nrow(base$review_input$candidates), 0)
})

test_that("installed contextual-family example retains empty docs and exact counts", {
  skip_if_not_installed("quanteda", "4.5.0")
  env <- new.env(parent = baseenv())
  sys.source(system.file("examples", "word-family-review.R", package = "ldfreq", mustWork = TRUE), env)
  x <- env$word_family_review_example
  expect_equal(x$initial$documents$unresolved_tokens, c(2, 0))
  expect_equal(x$reviewed$documents$selected_tokens, c(8, 0))
  expect_equal(x$reviewed$documents$family_types, c(7, 0))
  expect_equal(x$reviewed$documents$family_ttr, c(7/8, NA))
  expect_equal(x$reviewed$documents$review_selected_tokens, c(2, 0))
})
