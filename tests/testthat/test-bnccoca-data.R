test_that("the Nation snapshot separates families, supplements and placeholders", {
  x <- bnccoca_data()
  d <- x$dictionary
  expect_equal(nrow(d), 75679L)
  expect_equal(length(unique(d$family_id)), 25000L)
  expect_equal(anyDuplicated(d$record_id), 0L)
  expect_equal(anyDuplicated(d$form), 0L)
  expect_true(all(table(d$frequency_band[d$is_headword]) == 1000L))
  expect_identical(d$headword, d$form[match(d$family_id, d$record_id)])
  expect_identical(x$resource$data_license, "CC BY-SA 4.0")
  expect_equal(nrow(x$supplementary), 29798L)
  expect_true(all(is.na(x$supplementary$frequency_band)))
  expect_identical(unique(x$supplementary$list_type),
    c("proper_names", "marginal_words", "transparent_compounds", "acronyms"))
  expect_false(any(x$catalog$included[26:30]))
  expect_identical(rownames(x$catalog), as.character(1:34))
  expect_equal(sum(x$catalog$rows[x$catalog$included]), nrow(d) + nrow(x$supplementary))
  expect_identical(unique(d$range_flag), "0")
  expect_false("REUSABILITY" %in% d$form)
  head <- d$headword[match(c("USE", "USES", "COLOR", "COLOUR", "TRANSMISSION"), d$form)]
  expect_identical(head, c("USE", "USE", "COLOUR", "COLOUR", "TRANSMIT"))
  expect_false(any(c("XWRTSSZ", "XWRTPPQ", "XWRTSSLLQ", "XWRTLLLZZXX", "SSAAWWRRT") %in%
    c(d$form, x$supplementary$form)))
  x$dictionary$form[1] <- "edited"
  expect_identical(bnccoca_data()$dictionary$form[1], "A")
})

test_that("real family lookup preserves missingness, spelling and replay", {
  env <- new.env(parent = baseenv())
  sys.source(system.file("examples", "bnccoca-families.R", package = "ldfreq",
    mustWork = TRUE), env)
  example <- env$bnccoca_example
  x <- example$profile
  expect_equal(x$documents$selected_tokens, c(4L, 2L))
  expect_equal(x$documents$matched_tokens, c(4L, 1L))
  expect_equal(x$documents$family_types, c(2L, NA_integer_))
  expect_equal(x$documents$family_ttr, c(0.5, NA_real_))
  expect_identical(tail(x$occurrences$status, 1), "unlisted")
  expect_identical(tail(x$occurrences$keyword, 1), "reusability")
  expect_equal(example$candidates$frequency_band, rep(1L, 5L))
  expect_identical(example$candidates$headword, c("USE", "USE", "COLOUR", "COLOUR", "USE"))
  identity <- lexdiv_family_profile(x$annotations, x$dictionary, x$provenance$resource)
  expect_true(all(identity$occurrences$status == "unlisted"))
  path <- tempfile()
  on.exit(unlink(path))
  saveRDS(example, path)
  restored <- readRDS(path)
  expect_identical(restored, example)
  expect_identical(lexdiv_family_profile(restored$profile$annotations,
    restored$profile$dictionary, restored$profile$provenance$resource,
    normalization = "nfkc_lower"), x)
})

test_that("common-token comparisons disclose changed denominators and incomplete totals", {
  e <- new.env(parent = baseenv())
  for (file in c("bnccoca-families.R", "family-count-comparison.R"))
    sys.source(system.file("examples", file, package = "ldfreq", mustWork = TRUE), e)
  x <- e$compare_family_counts(e$bnccoca_example$profile)
  expect_equal(x$documents$selected_tokens, c(4, 2))
  expect_equal(x$documents$common_tokens, c(4, 1))
  expect_equal(x$documents$token_coverage, c(1, .5))
  listed <- subset(x$comparison, document_id == "listed" & scope == "all_selected")
  expect_equal(listed$V, c(4, 3, 2))
  expect_equal(listed$ttr, c(1, .75, .5))
  partial <- subset(x$comparison, document_id == "unlisted")
  expect_equal(partial$N, c(2, 2, 2, 1, 1, 1))
  expect_equal(partial$V, c(2, 2, NA, 1, 1, 1))
  expect_equal(partial$ttr, c(1, 1, NA, 1, 1, 1))
  expect_identical(x$selection$common_resolved, c(rep(TRUE, 5), FALSE))
  expect_error(e$compare_family_counts(x$profile, rep(NA, 6)), "complete logical")
  expect_error(e$compare_family_counts(x$profile, TRUE), "complete logical")
  changed <- x$profile
  changed$occurrences$family_id[1] <- "invented"
  expect_error(e$compare_family_counts(changed), "unmodified")

  # Hand-counted counterexample: unknown lemma, two family candidates, an
  # excluded punctuation token, a genuinely empty document, and no common set.
  segments <- data.frame(document_id = c("partial", "empty", "unlisted"),
    segment_id = "s1", text = c("use bank .", "", "quux"))
  tokens <- data.frame(document_id = c(rep("partial", 3), "unlisted"),
    segment_id = "s1", token_index = c(1:3, 1), surface = c("use", "bank", ".", "quux"),
    lemma = c(NA_character_, "bank", ".", "quux"), upos = c("VERB", "NOUN", "PUNCT", "NOUN"))
  a <- lexdiv_import_annotations(tokens, segments,
    list(language = "en", analyzer = "authored", analyzer_version = "1",
      dictionary = "authored", dictionary_version = "1", unit = "word", normalization = "none"))
  d <- data.frame(record_id = c("1", "2", "3"), form = c("use", "bank", "bank"),
    family_id = c("USE", "BANK_A", "BANK_B"))
  resource <- list(resource_id = "authored-counting-check", resource_version = "1",
    source_reference = "hand-authored test; not Nation membership", language = "en",
    family_definition = "one USE family and two distinct BANK families",
    data_license = "MIT", lookup_unit = "surface")
  profile <- lexdiv_family_profile(a, d, resource, exclude_pos = "PUNCT")
  y <- e$compare_family_counts(profile)
  expect_equal(y$documents$selected_tokens, c(2, 0, 1))
  expect_equal(y$documents$ambiguous_tokens, c(1, 0, 0))
  expect_equal(y$documents$missing_lemma_tokens, c(1, 0, 0))
  expect_equal(y$documents$common_tokens, c(0, 0, 0))
  expect_true(all(is.na(subset(y$comparison, scope == "common_resolved")$ttr)))
  expect_equal(subset(y$comparison, document_id == "partial" & scope == "all_selected")$V,
    c(2, NA, NA))
  expect_equal(subset(y$comparison, document_id == "empty")$V, rep(0, 6))
  expect_error(e$compare_family_counts(profile, rep(TRUE, 4)), "known selection")
  z <- e$compare_family_counts(profile, c(FALSE, TRUE, FALSE, FALSE))
  expect_equal(z$documents$selected_tokens, c(1, 0, 0))
  expect_identical(z$selection$token_index, profile$annotations$tokens$token_index)
  path <- tempfile()
  on.exit(unlink(path))
  saveRDS(y, path)
  restored <- readRDS(path)
  expect_identical(e$compare_family_counts(restored$profile, restored$selection$selected), y)
})
