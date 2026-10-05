overlap_annotate <- function(
    text,
    lemmas,
    upos,
    backend_id = "fixture-upos-lemma",
    backend_version = "1",
    upos_backend_id = "fixture-upos",
    upos_backend_version = "1") {
  lexdiv_lemmatize(
    lexdiv_tokenize(text, case = "lower"),
    lemmas = lemmas,
    upos = upos,
    backend_id = backend_id,
    backend_version = backend_version,
    upos_backend_id = upos_backend_id,
    upos_backend_version = upos_backend_version
  )
}

test_that("overlap measure identifiers and result columns are explicit", {
  expect_identical(
    lexdiv_overlap_ids(),
    c(
      "jaccard_types", "dice_types", "a_covered_by_b_types",
      "b_covered_by_a_types", "overlap_coefficient_types"
    )
  )
  result <- lexdiv_term_overlap(
    c("a", "b", "c"),
    c("b", "c", "d"),
    document_ids = c("draft", "reference")
  )

  expect_s3_class(result, "lexdiv_term_overlap")
  expect_s3_class(result, "lexdiv_overlap")
  expect_identical(
    names(result),
    c(
      "summary", "counts", "coverage", "shared_terms", "unique_to_a",
      "unique_to_b", "exclusions", "comparability", "preprocessing",
      "provenance"
    )
  )
  expect_identical(
    names(result$comparability),
    c("component", "value_a", "value_b", "matches")
  )
  expect_identical(result$summary$value, c(1 / 2, 2 / 3, 2 / 3, 2 / 3, 2 / 3))
  expect_identical(result$summary$numerator, c(2, 4, 2, 2, 2))
  expect_identical(result$summary$denominator, c(4, 6, 3, 3, 3))
  expect_true(all(result$summary$status == "ok"))
  expect_identical(result$summary$document_id_a, rep("draft", 5L))
  expect_identical(result$summary$document_id_b, rep("reference", 5L))
  expect_identical(
    result$summary$source_document_id,
    c(NA_character_, NA_character_, "draft", "reference", NA_character_)
  )
  expect_identical(
    result$summary$reference_document_id,
    c(NA_character_, NA_character_, "reference", "draft", NA_character_)
  )
})

test_that("subset, identical, and disjoint boundaries distinguish denominators", {
  subset_result <- lexdiv_term_overlap(c("a", "b"), c("a", "b", "c"))
  expect_equal(
    subset_result$summary$value,
    c(2 / 3, 4 / 5, 1, 2 / 3, 1)
  )
  identical_result <- lexdiv_term_overlap(c("a", "b"), c("b", "a"))
  disjoint_result <- lexdiv_term_overlap(c("a", "b"), c("c", "d"))
  expect_identical(identical_result$summary$value, rep(1, 5L))
  expect_identical(disjoint_result$summary$value, rep(0, 5L))
})

test_that("type overlap ignores repetition and order but preserves exact strings", {
  first <- lexdiv_term_overlap(
    c("A", "a", "é", "e\u0301", "A"),
    c("a", "é")
  )
  second <- lexdiv_term_overlap(
    c("e\u0301", "A", "a", "é", "a", "A"),
    c("é", "a", "a")
  )
  expect_identical(first$summary$value, second$summary$value)
  expect_identical(first$summary$type_count_a, rep(4, 5L))
  expect_identical(first$summary$shared_type_count, rep(2, 5L))
  expect_false(first$summary$value[[1L]] == 1)
})

test_that("swapping documents preserves symmetric measures and swaps directions", {
  a <- c("a", "b")
  b <- c("a", "b", "c", "d")
  forward <- lexdiv_term_overlap(a, b)$summary
  reverse <- lexdiv_term_overlap(b, a)$summary
  symmetric <- c("jaccard_types", "dice_types", "overlap_coefficient_types")
  expect_identical(
    forward$value[match(symmetric, forward$measure_id)],
    reverse$value[match(symmetric, reverse$measure_id)]
  )
  expect_identical(
    forward$value[forward$measure_id == "a_covered_by_b_types"],
    reverse$value[reverse$measure_id == "b_covered_by_a_types"]
  )
  expect_identical(
    forward$value[forward$measure_id == "b_covered_by_a_types"],
    reverse$value[reverse$measure_id == "a_covered_by_b_types"]
  )
})

test_that("empty-set rules never turn missing evidence into perfect overlap", {
  both <- lexdiv_term_overlap(character(), character())$summary
  a_empty <- lexdiv_term_overlap(character(), c("a"))$summary
  b_empty <- lexdiv_term_overlap(c("a"), character())$summary

  expect_true(all(both$status == "missing"))
  expect_true(all(both$missing_reason == "empty_term_sets"))
  expect_true(all(is.na(both$value)))
  expect_identical(a_empty$value, c(0, 0, NA_real_, 0, NA_real_))
  expect_identical(
    a_empty$status,
    c("ok", "ok", "missing", "ok", "missing")
  )
  expect_identical(b_empty$value, c(0, 0, 0, NA_real_, NA_real_))
})

test_that("invalid terms are atomic and never silently deleted", {
  invalid_utf8 <- rawToChar(as.raw(255L))
  Encoding(invalid_utf8) <- "bytes"
  cases <- list(
    c("a", NA_character_),
    c("a", ""),
    factor(c("a", "b")),
    matrix(c("a", "b"), nrow = 1L),
    structure(c("a", "b"), names = c("one", "two")),
    c("a", invalid_utf8)
  )
  for (value in cases) {
    result <- lexdiv_term_overlap(value, c("a"))
    expect_true(all(result$summary$status == "invalid_input"))
    expect_true(all(result$summary$missing_reason == "invalid_terms_a"))
    expect_true(all(is.na(result$summary$value)))
    expect_true(all(is.na(result$summary$type_count_a)))
  }
  both <- lexdiv_term_overlap(c(NA_character_), c(""))
  expect_true(all(both$summary$missing_reason == "invalid_terms_both"))
})

test_that("term details are opt-in and retain exact token counts", {
  counts_only <- lexdiv_term_overlap(c("b", "a", "a"), c("a", "c"))
  detailed <- lexdiv_term_overlap(
    c("b", "a", "a"),
    c("a", "c"),
    details = "terms"
  )
  expect_identical(nrow(counts_only$shared_terms), 0L)
  expect_identical(detailed$shared_terms$term, "a")
  expect_identical(detailed$shared_terms$token_count_a, 2)
  expect_identical(detailed$shared_terms$token_count_b, 1)
  expect_identical(detailed$unique_to_a$term, "b")
  expect_identical(detailed$unique_to_b$term, "c")
  expect_identical(counts_only$provenance$contains_lexical_terms, FALSE)
  expect_identical(detailed$provenance$contains_lexical_terms, TRUE)
  empty_detailed <- lexdiv_term_overlap(character(), character(), details = "terms")
  expect_identical(empty_detailed$provenance$contains_lexical_terms, FALSE)
})

test_that("measure selection and identifiers reject ambiguous requests", {
  selected <- lexdiv_term_overlap(
    c("a"),
    c("a"),
    measures = c("dice_types", "jaccard_types"),
    document_ids = c("a", "b")
  )
  expect_identical(selected$summary$measure_id, c("dice_types", "jaccard_types"))
  expect_error(lexdiv_term_overlap("a", "a", measures = character()), "non-empty")
  expect_error(
    lexdiv_term_overlap("a", "a", measures = c("jaccard_types", "jaccard_types")),
    "duplicates"
  )
  expect_error(lexdiv_term_overlap("a", "a", measures = "overlap"), "Unknown")
  expect_error(
    lexdiv_term_overlap("a", "a", document_ids = c("same", "same")),
    "distinct"
  )
  expect_error(lexdiv_term_overlap("a", "a", details = "all"), "details")
  expect_error(
    lexdiv_term_overlap("a", "a", document_ids = c("/private/a", "b")),
    "path-free"
  )
  expect_error(
    lexdiv_term_overlap("a", "a", document_ids = c("../private/a", "b")),
    "path-free"
  )
})

test_that("random type sets agree with direct set formulas", {
  set.seed(20260823)
  vocabulary <- letters[1:12]
  for (iteration in seq_len(100L)) {
    a <- sample(vocabulary, sample.int(25L, 1L) - 1L, replace = TRUE)
    b <- sample(vocabulary, sample.int(25L, 1L) - 1L, replace = TRUE)
    set_a <- unique(a)
    set_b <- unique(b)
    intersection <- length(intersect(set_a, set_b))
    union <- length(union(set_a, set_b))
    expected <- c(
      if (union == 0L) NA_real_ else intersection / union,
      if (length(set_a) + length(set_b) == 0L) {
        NA_real_
      } else {
        2 * intersection / (length(set_a) + length(set_b))
      },
      if (length(set_a) == 0L) NA_real_ else intersection / length(set_a),
      if (length(set_b) == 0L) NA_real_ else intersection / length(set_b),
      if (min(length(set_a), length(set_b)) == 0L) {
        NA_real_
      } else {
        intersection / min(length(set_a), length(set_b))
      }
    )
    expect_equal(lexdiv_term_overlap(a, b)$summary$value, expected)
  }
})

test_that("large duplicate-heavy input does not construct a token product", {
  result <- lexdiv_term_overlap(
    rep(c("a", "b"), 50000L),
    rep(c("b", "c"), 50000L)
  )
  expect_identical(result$counts$input_token_count_a, 100000)
  expect_identical(result$counts$input_token_count_b, 100000)
  expect_identical(result$counts$shared_type_count, 1)
  expect_identical(result$counts$union_type_count, 3)
})

test_that("content overlap uses the established UPOS content set", {
  x <- overlap_annotate(
    "Cats and dogs ran",
    c("cat", "and", "dog", "run"),
    c("NOUN", "CCONJ", "NOUN", "VERB")
  )
  y <- overlap_annotate(
    "Cats birds ran",
    c("cat", "bird", "run"),
    c("NOUN", "NOUN", "VERB")
  )
  result <- lexdiv_content_overlap(
    x,
    y,
    details = "terms",
    document_ids = c("essay", "model")
  )

  expect_s3_class(result, "lexdiv_content_overlap")
  expect_identical(result$summary$value, c(1 / 2, 2 / 3, 2 / 3, 2 / 3, 2 / 3))
  expect_true(all(result$summary$analysis_scope == "upos_content_words"))
  expect_true(all(result$summary$unit == "lemma"))
  expect_identical(result$shared_terms$term, c("cat", "run"))
  expect_identical(result$unique_to_a$term, "dog")
  expect_identical(result$unique_to_b$term, "bird")
  expect_identical(result$coverage$eligible_tokens, c(3, 3))
  expect_identical(result$coverage$non_content_upos_tokens, c(1, 0))
  expect_identical(result$coverage$eligible_types, c(3, 3))
  expect_identical(result$preprocessing$content_upos, c("ADJ", "ADV", "NOUN", "PROPN", "VERB"))
  expect_false(any(grepl("sha256", capture.output(str(result$preprocessing)))))

  metric_x <- lexdiv_metrics_text(
    x,
    unit = "lemma",
    word_inclusion = "content",
    metrics = "ttr"
  )
  metric_y <- lexdiv_metrics_text(
    y,
    unit = "lemma",
    word_inclusion = "content",
    metrics = "ttr"
  )
  direct <- lexdiv_term_overlap(
    metric_x$token_audit$selected_unit[metric_x$token_audit$eligible],
    metric_y$token_audit$selected_unit[metric_y$token_audit$eligible]
  )
  expect_identical(result$summary$value, direct$summary$value)
  expect_identical(result$coverage$eligible_tokens, c(
    metric_x$results$N,
    metric_y$results$N
  ))
  expect_identical(result$coverage$eligible_types, c(
    metric_x$results$V,
    metric_y$results$V
  ))
})

test_that("content coverage separates missing UPOS, function words, and missing units", {
  x <- overlap_annotate(
    "Cats mystery and unknown",
    c("cat", NA_character_, "and", "unknown"),
    c("NOUN", "NOUN", "CCONJ", NA_character_)
  )
  y <- overlap_annotate("The and", c("the", "and"), c("DET", "CCONJ"))
  result <- lexdiv_content_overlap(x, y)

  expect_identical(result$coverage$content_tokens, c(2, 0))
  expect_identical(result$coverage$eligible_tokens, c(1, 0))
  expect_identical(result$coverage$missing_unit_tokens, c(1, 0))
  expect_identical(result$coverage$missing_upos_tokens, c(1, 0))
  expect_identical(result$coverage$non_content_upos_tokens, c(1, 2))
  expect_identical(result$summary$value, c(0, 0, 0, NA_real_, NA_real_))
  expect_identical(
    result$exclusions$token_count,
    c(1, 1, 1, 0, 2, 0)
  )

  both_function_words <- lexdiv_content_overlap(y, y)
  expect_true(all(both_function_words$summary$status == "missing"))
  expect_true(all(
    both_function_words$summary$missing_reason == "empty_content_sets"
  ))
})

test_that("content overlap rejects implicit annotation and corrupted layers", {
  bare <- lexdiv_tokenize("Cats run")
  expect_error(lexdiv_content_overlap(bare, bare), "UPOS annotations")
  expect_error(lexdiv_content_overlap("Cats run", "Dogs run"), "lexdiv_tokenize")

  annotated <- overlap_annotate(
    "Cats run",
    c("cat", "run"),
    c("NOUN", "VERB")
  )
  bad_lemma <- annotated
  bad_lemma$tokens$lemma <- factor(bad_lemma$tokens$lemma)
  expect_error(lexdiv_content_overlap(bad_lemma, annotated), "annotation layer")
  bad_backend <- annotated
  bad_backend$provenance$annotation$backend_version <- ""
  expect_error(lexdiv_content_overlap(bad_backend, annotated), "annotation layer")
  stale_counts <- annotated
  stale_counts$provenance$annotation$lemma_tokens <- 1
  expect_error(lexdiv_content_overlap(stale_counts, annotated), "annotation layer")
  bad_method <- annotated
  bad_method$provenance$annotation$method <- "guessed"
  expect_error(lexdiv_content_overlap(bad_method, annotated), "annotation layer")
  forged <- bare
  forged$tokens$upos <- c("NOUN", "VERB")
  expect_error(lexdiv_content_overlap(forged, annotated), "incomplete")
})

test_that("Universal POS input is normalized and validated at annotation time", {
  tokenization <- lexdiv_tokenize("Cats run")
  normalized <- lexdiv_lemmatize(
    tokenization,
    lemmas = c("cat", "run"),
    upos = c("noun", "verb"),
    backend_id = "fixture",
    backend_version = "1",
    upos_backend_id = "fixture-upos",
    upos_backend_version = "1"
  )
  expect_identical(normalized$tokens$upos, c("NOUN", "VERB"))
  expect_error(
    lexdiv_lemmatize(
      tokenization,
      lemmas = c("cat", "run"),
      upos = c("NOUN", "PREDICATE"),
      backend_id = "fixture",
      backend_version = "1",
      upos_backend_id = "fixture-upos",
      upos_backend_version = "1"
    ),
    "unsupported Universal POS"
  )
})

test_that("preprocessing mismatches are visible and policy controlled", {
  x <- overlap_annotate(
    "Cats run",
    c("cat", "run"),
    c("NOUN", "VERB"),
    backend_version = "1"
  )
  y <- overlap_annotate(
    "Cats run",
    c("cat", "run"),
    c("NOUN", "VERB"),
    backend_version = "2"
  )
  expect_error(
    lexdiv_content_overlap(x, y),
    "different or unverifiable preprocessing"
  )
  expect_warning(
    warned <- lexdiv_content_overlap(x, y, mismatch = "warn"),
    "annotation_backend_version"
  )
  expect_false(warned$comparability$matches[
    warned$comparability$component == "annotation_backend_version"
  ])
  expect_true(warned$comparability$matches[
    warned$comparability$component == "annotation_method"
  ])
  expect_error(
    lexdiv_content_overlap(x, y, mismatch = "error"),
    "different or unverifiable preprocessing"
  )
  allowed <- lexdiv_content_overlap(x, y, mismatch = "allow")
  expect_true(all(allowed$summary$status == "ok"))
})

test_that("UPOS backend mismatches fail closed independently of lemma backend", {
  skip_if_not_installed("textstem")
  x <- lexdiv_lemmatize(
    lexdiv_tokenize("Run"),
    method = "textstem",
    upos = "VERB",
    upos_backend_id = "tagger-a",
    upos_backend_version = "1"
  )
  y <- lexdiv_lemmatize(
    lexdiv_tokenize("Run"),
    method = "textstem",
    upos = "VERB",
    upos_backend_id = "tagger-b",
    upos_backend_version = "1"
  )
  expect_error(lexdiv_content_overlap(x, y), "upos_backend_id")
})

test_that("surface and lemma overlap are distinct estimands", {
  x <- overlap_annotate(
    "Cats run",
    c("cat", "run"),
    c("NOUN", "VERB")
  )
  y <- overlap_annotate(
    "Cat runs",
    c("cat", "run"),
    c("NOUN", "VERB")
  )
  lemma <- lexdiv_content_overlap(x, y, unit = "lemma")
  surface <- lexdiv_content_overlap(x, y, unit = "surface")
  expect_identical(lemma$summary$value, rep(1, 5L))
  expect_identical(surface$summary$value, rep(0, 5L))

  different_lemma_backend <- overlap_annotate(
    "Cat runs",
    c("cat", "run"),
    c("NOUN", "VERB"),
    backend_id = "different-lemma-backend"
  )
  expect_error(
    lexdiv_content_overlap(x, different_lemma_backend, unit = "lemma"),
    "annotation_backend_id"
  )
  expect_silent(
    lexdiv_content_overlap(x, different_lemma_backend, unit = "surface")
  )
})

test_that("content overlap accepts a validated multiword lexical unit silently", {
  x <- overlap_annotate("Ice", "ice cream", "NOUN")
  y <- overlap_annotate("Ice", "ice cream", "NOUN")
  expect_silent(result <- lexdiv_content_overlap(x, y, unit = "lemma"))
  expect_identical(result$summary$value, rep(1, 5L))
  expect_warning(
    lexdiv_term_overlap("ice cream", "ice"),
    "one string with whitespace"
  )
})

test_that("flemma overlap reports identity fallback without copying internal hashes", {
  resource <- tempfile(fileext = ".txt")
  on.exit(unlink(resource), add = TRUE)
  writeLines(
    c("cat\t->\tcat\tcats", "run\t->\tran\trun"),
    resource,
    useBytes = TRUE
  )
  x <- lexdiv_flemmatize(
    overlap_annotate(
      "Cats mystery and",
      c("cat", "mystery", "and"),
      c("NOUN", "NOUN", "CCONJ")
    ),
    resource,
    resource_version = "fixture-1"
  )
  y <- lexdiv_flemmatize(
    overlap_annotate(
      "Cat unknown",
      c("cat", "unknown"),
      c("NOUN", "NOUN")
    ),
    resource,
    resource_version = "fixture-1"
  )
  y_different_lemma_backend <- lexdiv_flemmatize(
    overlap_annotate(
      "Cat unknown",
      c("cat", "unknown"),
      c("NOUN", "NOUN"),
      backend_id = "different-lemma-backend"
    ),
    resource,
    resource_version = "fixture-1"
  )
  expect_silent(lexdiv_content_overlap(
    y,
    y_different_lemma_backend,
    unit = "flemma"
  ))
  result <- lexdiv_content_overlap(x, y, unit = "flemma", details = "terms")

  expect_identical(result$summary$value[[1L]], 1 / 3)
  expect_identical(result$shared_terms$term, "cat")
  expect_identical(result$coverage$identity_fallback_tokens, c(1, 1))
  serialized <- paste(capture.output(str(result)), collapse = "\n")
  expect_false(grepl("source_text_sha256", serialized, fixed = TRUE))
  expect_false(grepl("processed_text_sha256", serialized, fixed = TRUE))
  expect_false(grepl("source_sha256", serialized, fixed = TRUE))
  expect_false(grepl("override_canonical_sha256", serialized, fixed = TRUE))
  expect_false(grepl(normalizePath(resource), serialized, fixed = TRUE))

  stale_fallback <- x
  stale_fallback$provenance$flemma_annotation$identity_fallback_tokens <- 0
  expect_error(
    lexdiv_content_overlap(stale_fallback, y, unit = "flemma"),
    "flemma annotation layer"
  )
})

test_that("flemma overlap compares declared versions without byte identity", {
  resource_a <- tempfile(fileext = ".txt")
  resource_b <- tempfile(fileext = ".txt")
  on.exit(unlink(c(resource_a, resource_b)), add = TRUE)
  writeLines(
    c("cat\t->\tcat\tcats", "run\t->\trun\truns"),
    resource_a,
    useBytes = TRUE
  )
  writeLines(
    c("run\t->\trun\truns", "cat\t->\tcat\tcats"),
    resource_b,
    useBytes = TRUE
  )

  annotated <- overlap_annotate("Cats run", c("cat", "run"), c("NOUN", "VERB"))
  x <- lexdiv_flemmatize(annotated, resource_a, resource_version = "fixture-1")
  reordered <- lexdiv_flemmatize(
    annotated,
    resource_b,
    resource_version = "fixture-1"
  )
  expect_identical(x$tokens, reordered$tokens)
  expect_silent(lexdiv_content_overlap(x, reordered, unit = "flemma"))

  y <- lexdiv_flemmatize(annotated, resource_b, resource_version = "fixture-2")

  expect_error(
    lexdiv_content_overlap(x, y, unit = "flemma"),
    "flemma_resource_version"
  )
  allowed <- lexdiv_content_overlap(x, y, unit = "flemma", mismatch = "allow")
  resource_row <- allowed$comparability[
    allowed$comparability$component == "flemma_resource_version",
    ,
    drop = FALSE
  ]
  expect_identical(resource_row$matches, FALSE)
  expect_identical(resource_row$value_a, "fixture-1")
  expect_identical(resource_row$value_b, "fixture-2")

  unversioned_x <- lexdiv_flemmatize(annotated, resource_a)
  unversioned_y <- lexdiv_flemmatize(annotated, resource_b)
  expect_error(
    lexdiv_content_overlap(unversioned_x, unversioned_y, unit = "flemma"),
    "flemma_resource_version"
  )
  expect_warning(
    warned <- lexdiv_content_overlap(
      unversioned_x,
      unversioned_y,
      unit = "flemma",
      mismatch = "warn"
    ),
    "flemma_resource_version"
  )
  expect_false(warned$comparability$matches[
    warned$comparability$component == "flemma_resource_version"
  ])
  expect_silent(lexdiv_content_overlap(
    unversioned_x,
    unversioned_y,
    unit = "flemma",
    mismatch = "allow"
  ))

  serialized <- paste(capture.output(str(x)), collapse = "\n")
  expect_false(grepl("resource_source_sha256", serialized, fixed = TRUE))
  expect_false(grepl("override_canonical_sha256", serialized, fixed = TRUE))
})

test_that("flemma override presence and declared versions fail closed", {
  resource <- tempfile(fileext = ".txt")
  on.exit(unlink(resource), add = TRUE)
  writeLines("cat\t->\tcat\tcats", resource, useBytes = TRUE)
  annotated <- overlap_annotate("Cats run", c("cat", "run"), c("NOUN", "VERB"))
  no_override <- lexdiv_flemmatize(
    annotated,
    resource,
    resource_version = "fixture-1"
  )
  empty_override <- lexdiv_flemmatize(
    annotated,
    resource,
    overrides = data.frame(form = character(), flemma = character()),
    resource_version = "fixture-1"
  )
  expect_silent(lexdiv_content_overlap(
    no_override,
    empty_override,
    unit = "flemma"
  ))
  expect_error(
    lexdiv_flemmatize(
      annotated,
      resource,
      overrides = data.frame(form = character(), flemma = character()),
      resource_version = "fixture-1",
      override_version = "unused"
    ),
    "override_version must be NULL"
  )

  x_override <- lexdiv_flemmatize(
    annotated,
    resource,
    overrides = data.frame(form = "cats", flemma = "feline"),
    resource_version = "fixture-1",
    override_version = "override-1"
  )
  y_override <- lexdiv_flemmatize(
    annotated,
    resource,
    overrides = data.frame(form = "cats", flemma = "cat"),
    resource_version = "fixture-1",
    override_version = "override-2"
  )
  expect_error(
    lexdiv_content_overlap(x_override, y_override, unit = "flemma"),
    "flemma_override_version"
  )
  expect_error(
    lexdiv_content_overlap(no_override, x_override, unit = "flemma"),
    "flemma_override_present"
  )

  unversioned_a <- lexdiv_flemmatize(
    annotated,
    resource,
    overrides = data.frame(form = "cats", flemma = "feline"),
    resource_version = "fixture-1"
  )
  unversioned_b <- lexdiv_flemmatize(
    annotated,
    resource,
    overrides = data.frame(form = "cats", flemma = "feline"),
    resource_version = "fixture-1"
  )
  expect_error(
    lexdiv_content_overlap(unversioned_a, unversioned_b, unit = "flemma"),
    "flemma_override_version"
  )

  different_resource_label <- lexdiv_flemmatize(
    annotated,
    resource,
    resource_version = "fixture-2"
  )
  expect_silent(lexdiv_content_overlap(
    no_override,
    different_resource_label,
    unit = "lemma"
  ))
})

test_that("installed overlap contract matches measures and privacy behavior", {
  skip_if_not_installed("jsonlite")
  contract_path <- system.file(
    "spec", "lexical-overlap-contract.json",
    package = "ldfreq"
  )
  schema_path <- system.file(
    "spec", "lexical-overlap-contract.schema.json",
    package = "ldfreq"
  )
  expect_true(nzchar(contract_path) && file.exists(contract_path))
  expect_true(nzchar(schema_path) && file.exists(schema_path))
  contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
  schema <- jsonlite::read_json(schema_path, simplifyVector = FALSE)
  measure_ids <- vapply(contract$measures, `[[`, character(1L), "measure_id")
  method_ids <- vapply(contract$measures, `[[`, character(1L), "method_id")
  result <- lexdiv_term_overlap("a", "a")

  expect_identical(contract$contract_id, "ldfreq-lexical-overlap")
  expect_identical(contract$contract_version, "0.2.0")
  expect_identical(contract$status, "normative")
  expect_identical(measure_ids, lexdiv_overlap_ids())
  expect_identical(method_ids, result$summary$method_id)
  expect_identical(
    unlist(contract$content_words$upos, use.names = FALSE),
    c("ADJ", "ADV", "NOUN", "PROPN", "VERB")
  )
  expect_identical(contract$privacy_boundary$raw_text_copied_to_result, FALSE)
  expect_identical(contract$privacy_boundary$text_hash_copied_to_result, FALSE)
  expect_identical(contract$privacy_boundary$term_details_opt_in, TRUE)
  expect_identical(
    contract$privacy_boundary$internally_computed_flemma_hash_copied_to_result,
    FALSE
  )
  expect_identical(contract$comparability_contract$default_mismatch_policy, "error")
  expect_identical(
    contract$result_contract$term_detail_disclosure,
    "provenance-flag-and-print-notice"
  )
  expect_identical(schema$properties$contract_id$const, contract$contract_id)
  expect_identical(
    schema$properties$contract_version$const,
    contract$contract_version
  )
})

test_that("overlap printing shows values and content coverage", {
  term <- lexdiv_term_overlap(c("a", "b"), c("b", "c"))
  expect_output(print(term), "shared types")
  detailed <- lexdiv_term_overlap(c("a", "b"), c("b", "c"), details = "terms")
  expect_output(print(detailed), "Lexical term details retained")
  x <- overlap_annotate("Cats run", c("cat", "run"), c("NOUN", "VERB"))
  content <- lexdiv_content_overlap(x, x)
  printed <- capture.output(visible <- withVisible(print(content)))
  expect_true(any(grepl("eligible_tokens", printed, fixed = TRUE)))
  expect_false(visible$visible)
  expect_identical(visible$value, content)
})
