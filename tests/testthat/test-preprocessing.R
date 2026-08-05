test_that("Unicode tokenization is deterministic and parameterized", {
  text <- enc2utf8("Café — John's well-being, 2026; COVID-19 and 3.14.")
  first <- lexdiv_tokenize(text)
  second <- lexdiv_tokenize(text)

  expect_identical(first, second)
  expect_s3_class(first, "lexdiv_tokenization")
  expect_identical(
    first$tokens$surface,
    enc2utf8(c("Café", "John's", "well-being", "COVID-19", "and"))
  )
  expect_identical(first$tokens$token_index, 1:5)
  expect_false(any(first$tokens$is_number))
  expect_identical(first$provenance$normalization, "NFC")
  expect_identical(first$provenance$case, "preserve")
  expect_identical(first$provenance$keep_numbers, FALSE)
  expect_match(first$provenance$source_text_sha256, "^[0-9a-f]{64}$")

  with_numbers <- lexdiv_tokenize(text, keep_numbers = TRUE)
  expect_identical(
    with_numbers$tokens$surface,
    enc2utf8(c(
      "Café", "John's", "well-being", "2026", "COVID-19", "and", "3", "14"
    ))
  )
  expect_identical(
    with_numbers$tokens$is_number,
    c(FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, TRUE, TRUE)
  )
})

test_that("normalization and case choices remain visible", {
  decomposed <- enc2utf8("Cafe\u0301 CAFÉ")
  nfc <- lexdiv_tokenize(decomposed, normalization = "NFC", case = "lower")
  none <- lexdiv_tokenize(decomposed, normalization = "none", case = "preserve")

  expect_identical(nfc$tokens$surface, enc2utf8(c("café", "café")))
  expect_false(identical(nfc$tokens$surface, none$tokens$surface))
  expect_identical(nfc$provenance$normalization, "NFC")
  expect_identical(nfc$provenance$case, "lower")
  expect_false(identical(
    nfc$provenance$processed_text_sha256,
    none$provenance$processed_text_sha256
  ))
})

test_that("empty and punctuation-only texts return valid zero-token objects", {
  empty <- lexdiv_tokenize("")
  punctuation <- lexdiv_tokenize("... — !!!")

  expect_identical(nrow(empty$tokens), 0L)
  expect_identical(nrow(punctuation$tokens), 0L)
  expect_identical(empty$tokens$surface, character())
  expect_identical(empty$provenance$output_tokens, 0)
})

test_that("supplied lemma and UPOS layers require explicit backend provenance", {
  tokenization <- lexdiv_tokenize("Cats and dogs ran")
  annotated <- lexdiv_lemmatize(
    tokenization,
    lemmas = c("cat", "and", "dog", "run"),
    upos = c("NOUN", "CCONJ", "NOUN", "VERB"),
    backend_id = "fixture-lemmatizer",
    backend_version = "1.0"
  )

  expect_identical(annotated$tokens$lemma, c("cat", "and", "dog", "run"))
  expect_identical(annotated$tokens$upos, c("NOUN", "CCONJ", "NOUN", "VERB"))
  expect_identical(
    annotated$provenance$annotation$backend_id,
    "fixture-lemmatizer"
  )
  expect_identical(annotated$provenance$annotation$lemma_coverage, 1)

  expect_error(
    lexdiv_lemmatize(tokenization, lemmas = rep("x", 4L)),
    "backend_id"
  )
  expect_error(
    lexdiv_lemmatize(
      tokenization,
      lemmas = c("cat"),
      backend_id = "fixture",
      backend_version = "1"
    ),
    "aligned"
  )
})

test_that("caller-supplied AntBNC resources create auditable flemmas", {
  path <- antbnc_fixture_file()
  on.exit(unlink(path), add = TRUE)
  tokenization <- lexdiv_tokenize(
    "Went studies unknown interested saw",
    case = "preserve"
  )
  annotated <- lexdiv_flemmatize(tokenization, path)
  repeated <- lexdiv_flemmatize(tokenization, path)

  expect_identical(annotated, repeated)
  expect_identical(
    annotated$tokens$flemma,
    c("go", "study", "unknown", "interest", "see")
  )
  expect_identical(
    annotated$tokens$flemma_matched,
    c(TRUE, TRUE, FALSE, TRUE, TRUE)
  )
  expect_identical(
    annotated$tokens$flemma_match_rule,
    c("antbnc", "antbnc", "identity", "antbnc", "antbnc")
  )
  annotation <- annotated$provenance$flemma_annotation
  expect_identical(annotation$method, "antbnc")
  expect_identical(annotation$lexical_unit, "flemma")
  expect_identical(annotation$resource_source_file, basename(path))
  expect_match(annotation$resource_source_sha256, "^[0-9a-f]{64}$")
  expect_identical(annotation$source_records, 5)
  expect_identical(annotation$mapping_records, 20)
  expect_identical(annotation$matched_tokens, 4)
  expect_identical(annotation$identity_fallback_tokens, 1)
  expect_identical(annotation$resource_bundled, FALSE)
  expect_identical(annotation$runtime_download, FALSE)

  diversity <- lexdiv_metrics_text(
    annotated,
    unit = "flemma",
    metrics = "ttr"
  )
  expect_identical(diversity$preprocessing$selected_unit, "flemma")
  expect_identical(diversity$results$N, 5)
  expect_identical(diversity$results$V, 5)
  expect_identical(
    diversity$token_audit$unit_match_rule,
    annotated$tokens$flemma_match_rule
  )
})

test_that("explicit flemma overrides take precedence over AntBNC", {
  path <- antbnc_fixture_file()
  on.exit(unlink(path), add = TRUE)
  tokenization <- lexdiv_tokenize("Interesting interested saw")
  overrides <- data.frame(
    form = c("interesting", "interested", "saw"),
    flemma = c("interesting", "interested", "saw"),
    stringsAsFactors = FALSE
  )
  annotated <- lexdiv_flemmatize(
    tokenization,
    path,
    overrides = overrides,
    resource_version = "fixture-004"
  )

  expect_identical(
    annotated$tokens$flemma,
    c("interesting", "interested", "saw")
  )
  expect_true(all(annotated$tokens$flemma_matched))
  expect_true(all(annotated$tokens$flemma_match_rule == "override"))
  expect_identical(
    annotated$provenance$flemma_annotation$backend_version,
    "fixture-004"
  )
  expect_identical(
    annotated$provenance$flemma_annotation$override_entries,
    3
  )
  expect_match(
    annotated$provenance$flemma_annotation$override_canonical_sha256,
    "^[0-9a-f]{64}$"
  )
})

test_that("AntBNC validation is deterministic and path-private", {
  private_directory <- file.path(tempdir(), "ldfreq-antbnc-private", "nested")
  dir.create(private_directory, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(private_directory, "antbnc-private.txt")
  on.exit(
    unlink(file.path(tempdir(), "ldfreq-antbnc-private"), recursive = TRUE),
    add = TRUE
  )
  writeLines("go\t->\tgo\twent", path, useBytes = TRUE)
  result <- lexdiv_flemmatize(lexdiv_tokenize("went"), path)
  inspected <- paste(capture.output(str(result)), collapse = "\n")
  expect_false(grepl(private_directory, inspected, fixed = TRUE))

  copied_path <- file.path(private_directory, "renamed-identical-resource.txt")
  expect_true(file.copy(path, copied_path))
  copied <- lexdiv_flemmatize(lexdiv_tokenize("went"), copied_path)
  expect_identical(
    copied$provenance$flemma_annotation$resource_source_file,
    basename(copied_path)
  )

  missing_error <- tryCatch(
    lexdiv_flemmatize(
      lexdiv_tokenize("went"),
      file.path(private_directory, "missing", "secret.txt")
    ),
    error = conditionMessage
  )
  expect_identical(
    missing_error,
    "AntBNC resource file does not exist or cannot be accessed."
  )
  expect_false(grepl(private_directory, missing_error, fixed = TRUE))

  duplicated <- antbnc_fixture_file(c(
    "go\t->\tgo\twent",
    "wend\t->\twent\twend"
  ))
  on.exit(unlink(duplicated), add = TRUE)
  expect_error(
    lexdiv_flemmatize(lexdiv_tokenize("went"), duplicated),
    "forms must map uniquely"
  )
  expect_error(
    lexdiv_flemmatize(
      lexdiv_tokenize("went"),
      path,
      overrides = data.frame(form = c("went", "went"), flemma = c("go", "wend"))
    ),
    "override forms must be non-empty and unique"
  )
})

test_that("raw, lemma, and content-word analyses preserve separate provenance", {
  tokenization <- lexdiv_tokenize("Cats and cat ran run")
  annotated <- lexdiv_lemmatize(
    tokenization,
    lemmas = c("cat", "and", "cat", "run", "run"),
    upos = c("NOUN", "CCONJ", "NOUN", "VERB", "VERB"),
    backend_id = "fixture-lemmatizer",
    backend_version = "1.0"
  )
  surface <- lexdiv_metrics_text(tokenization, metrics = "ttr")
  lemma <- lexdiv_metrics_text(annotated, unit = "lemma", metrics = "ttr")
  content <- lexdiv_metrics_text(
    annotated,
    unit = "lemma",
    word_inclusion = "content",
    metrics = "ttr"
  )

  expect_s3_class(surface, "lexdiv_text_results")
  expect_identical(surface$results$value, 1)
  expect_identical(lemma$results$value, 3 / 5)
  expect_identical(content$results$value, 0.5)
  expect_identical(content$results$N, 4)
  expect_identical(content$results$V, 2)
  expect_identical(content$preprocessing$selected_unit, "lemma")
  expect_identical(content$preprocessing$word_inclusion, "content")
  expect_identical(content$preprocessing$unit_coverage, 4 / 5)
  expect_identical(
    content$token_audit$exclusion_reason,
    c(NA_character_, "non_content_upos", NA_character_, NA_character_, NA_character_)
  )
})

test_that("missing annotations are excluded and quantified instead of imputed", {
  tokenization <- lexdiv_tokenize("one two three")
  annotated <- lexdiv_lemmatize(
    tokenization,
    lemmas = c("one", NA_character_, "three"),
    upos = c("NUM", NA_character_, "NOUN"),
    backend_id = "fixture-lemmatizer",
    backend_version = "1.0"
  )
  result <- lexdiv_metrics_text(annotated, unit = "lemma", metrics = "ttr")

  expect_identical(result$results$N, 2)
  expect_identical(result$preprocessing$excluded_tokens, 1)
  expect_identical(result$preprocessing$unit_coverage, 2 / 3)
  expect_identical(
    result$token_audit$exclusion_reason,
    c(NA_character_, "missing_lemma", NA_character_)
  )
})

test_that("the optional textstem backend records identity and usable lemmas", {
  skip_if_not_installed("textstem")

  tokenization <- lexdiv_tokenize(
    "The cats were running and studies.",
    case = "lower"
  )
  annotated <- lexdiv_lemmatize(tokenization, method = "textstem")
  result <- lexdiv_metrics_text(
    annotated,
    unit = "lemma",
    metrics = c("ttr", "rttr")
  )

  expect_identical(
    annotated$tokens$lemma,
    c("the", "cat", "be", "run", "and", "study")
  )
  expect_identical(annotated$provenance$annotation$method, "textstem")
  expect_identical(
    annotated$provenance$annotation$backend_id,
    "textstem::lemmatize_words"
  )
  expect_identical(
    annotated$provenance$annotation$backend_version,
    as.character(utils::packageVersion("textstem"))
  )
  expect_identical(annotated$provenance$annotation$lemma_coverage, 1)
  expect_true(all(result$results$status == "ok"))
})

test_that("raw-text structural input errors are rejected before measurement", {
  expect_error(lexdiv_tokenize(c("one", "two")), "one plain")
  expect_error(lexdiv_tokenize(NA_character_), "one plain")
  expect_error(lexdiv_tokenize(factor("one")), "one plain")
  expect_error(lexdiv_tokenize("one", normalization = "nfc"), "exactly one")
  expect_error(lexdiv_tokenize("one", keep_numbers = 1), "TRUE or FALSE")
})

test_that("the installed preprocessing contract matches the public implementation", {
  skip_if_not_installed("jsonlite")
  contract_path <- system.file(
    "spec", "ldfreq-preprocessing-contract.json",
    package = "ldfreq"
  )
  schema_path <- system.file(
    "spec", "ldfreq-preprocessing-contract.schema.json",
    package = "ldfreq"
  )
  expect_true(nzchar(contract_path) && file.exists(contract_path))
  expect_true(nzchar(schema_path) && file.exists(schema_path))
  contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
  schema <- jsonlite::read_json(schema_path, simplifyVector = FALSE)

  expect_identical(contract$contract_id, "ldfreq-preprocessing")
  expect_identical(contract$contract_version, "0.1.0-draft.2")
  expect_identical(contract$status, "public-api-candidate")
  expect_identical(contract$public_api, TRUE)
  expect_identical(
    unlist(contract$lexical_units$content_upos, use.names = FALSE),
    c("ADJ", "ADV", "NOUN", "PROPN", "VERB")
  )
  expect_identical(
    unlist(contract$lexical_units$choices, use.names = FALSE),
    c("surface", "lemma", "flemma")
  )
  expect_identical(contract$result_boundary$metric_core_schema_changed, FALSE)
  expect_identical(schema$properties$contract_id$const, contract$contract_id)
  expect_identical(
    schema$properties$contract_version$const,
    contract$contract_version
  )
})
