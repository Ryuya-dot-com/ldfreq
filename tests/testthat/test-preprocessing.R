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

test_that("tokenization consumers reject corrupted offsets and number flags", {
  tokenization <- lexdiv_tokenize("one 2026 two", keep_numbers = TRUE)

  overlapping <- tokenization
  overlapping$tokens$start[[2L]] <- overlapping$tokens$start[[1L]]
  expect_error(
    lexdiv_metrics_text(overlapping, metrics = "ttr"),
    "invalid tokenization table",
    fixed = TRUE
  )

  wrong_width <- tokenization
  wrong_width$tokens$end[[1L]] <- wrong_width$tokens$end[[1L]] + 1L
  expect_error(
    lexdiv_metrics_text(wrong_width, metrics = "ttr"),
    "invalid tokenization table",
    fixed = TRUE
  )

  wrong_number_flag <- tokenization
  wrong_number_flag$tokens$is_number[[2L]] <- FALSE
  expect_error(
    lexdiv_metrics_text(wrong_number_flag, metrics = "ttr"),
    "invalid tokenization table",
    fixed = TRUE
  )

  matrix_normalization <- tokenization
  matrix_normalization$provenance$normalization <- matrix("NFC", 1L, 1L)
  expect_error(
    lexdiv_metrics_text(matrix_normalization, metrics = "ttr"),
    "invalid preprocessing provenance",
    fixed = TRUE
  )

  matrix_case <- tokenization
  matrix_case$provenance$case <- matrix("preserve", 1L, 1L)
  expect_error(
    lexdiv_metrics_text(matrix_case, metrics = "ttr"),
    "invalid preprocessing provenance",
    fixed = TRUE
  )

  matrix_keep_numbers <- tokenization
  matrix_keep_numbers$provenance$keep_numbers <- matrix(TRUE, 1L, 1L)
  expect_error(
    lexdiv_metrics_text(matrix_keep_numbers, metrics = "ttr"),
    "invalid preprocessing provenance",
    fixed = TRUE
  )
})

test_that("supplied lemma and UPOS layers require explicit backend provenance", {
  tokenization <- lexdiv_tokenize("Cats and dogs ran")
  annotated <- lexdiv_lemmatize(
    tokenization,
    lemmas = c("cat", "and", "dog", "run"),
    upos = c("NOUN", "CCONJ", "NOUN", "VERB"),
    backend_id = "fixture-lemmatizer",
    backend_version = "1.0",
    upos_backend_id = "fixture-tagger",
    upos_backend_version = "2.0"
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
  expect_identical(annotation$backend_id, "ldfreq-antbnc-flemma-adapter")
  expect_identical(annotation$backend_version, "0.1.0")
  expect_identical(annotation$resource_id, "antbnc-lemma-list")
  expect_null(annotation$resource_version)
  expect_false("resource_source_file" %in% names(annotation))
  expect_false("resource_source_sha256" %in% names(annotation))
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

test_that("annotation provenance counts are validated with and without UPOS", {
  no_upos <- lexdiv_lemmatize(
    lexdiv_tokenize("Cats run"),
    lemmas = c("cat", "run"),
    backend_id = "fixture-lemmatizer",
    backend_version = "1"
  )
  stale_no_upos <- no_upos
  stale_no_upos$provenance$annotation$lemma_tokens <- 999
  expect_error(
    lexdiv_metrics_text(stale_no_upos, unit = "lemma", metrics = "ttr"),
    "invalid lemma/UPOS annotation layer"
  )

  malformed <- no_upos
  malformed$provenance$annotation <- "not-a-record"
  expect_error(
    lexdiv_metrics_text(malformed, unit = "lemma", metrics = "ttr"),
    "invalid lemma/UPOS annotation layer"
  )

  forged_method <- no_upos
  forged_method$provenance$annotation$method <- "textstem"
  expect_error(
    lexdiv_metrics_text(forged_method, unit = "lemma", metrics = "ttr"),
    "invalid lemma/UPOS annotation layer"
  )

  matrix_method <- no_upos
  matrix_method$provenance$annotation$method <- matrix("textstem", 1L, 1L)
  matrix_method$provenance$annotation$backend_id <- "forged-backend"
  expect_error(
    lexdiv_metrics_text(matrix_method, unit = "lemma", metrics = "ttr"),
    "invalid lemma/UPOS annotation layer"
  )

  if (requireNamespace("textstem", quietly = TRUE)) {
    textstem_annotation <- lexdiv_lemmatize(
      lexdiv_tokenize("Cats run"),
      method = "textstem"
    )
    textstem_annotation$provenance$annotation$backend_id <- "forged-backend"
    expect_error(
      lexdiv_metrics_text(
        textstem_annotation,
        unit = "lemma",
        metrics = "ttr"
      ),
      "invalid lemma/UPOS annotation layer"
    )
  }
})

test_that("flemma provenance is validated before measurement", {
  path <- antbnc_fixture_file()
  on.exit(unlink(path), add = TRUE)
  annotated <- lexdiv_flemmatize(
    lexdiv_tokenize("Went unknown"),
    path,
    resource_version = "fixture-004"
  )
  assert_invalid <- function(value) {
    expect_error(
      lexdiv_metrics_text(value, unit = "flemma", metrics = "ttr"),
      "invalid flemma annotation layer"
    )
  }

  malformed_table <- annotated
  malformed_table$tokens$flemma_matched <- c("yes", "no")
  assert_invalid(malformed_table)

  stale_mapping_count <- annotated
  stale_mapping_count$provenance$flemma_annotation$mapping_records <- 0
  assert_invalid(stale_mapping_count)

  stale_resource_count <- annotated
  stale_resource_count$provenance$flemma_annotation$resource_matched_tokens <- 99
  assert_invalid(stale_resource_count)

  stale_resource_coverage <- annotated
  stale_resource_coverage$provenance$flemma_annotation$resource_match_coverage <- 0
  assert_invalid(stale_resource_coverage)

  impossible_resource_count <- annotated
  impossible_resource_count$provenance$flemma_annotation$resource_matched_tokens <- 2
  impossible_resource_count$provenance$flemma_annotation$resource_match_coverage <- 1
  assert_invalid(impossible_resource_count)

  impossible_override_version <- annotated
  impossible_override_version$provenance$flemma_annotation$override_version <- "unused"
  assert_invalid(impossible_override_version)

  impossible_override_rule <- annotated
  impossible_override_rule$tokens$flemma_match_rule[[1L]] <- "override"
  impossible_override_rule$tokens$flemma_matched[[1L]] <- TRUE
  impossible_override_rule$provenance$flemma_annotation$override_tokens <- 1
  impossible_override_rule$provenance$flemma_annotation$matched_tokens <- 1
  impossible_override_rule$provenance$flemma_annotation$matched_coverage <- 0.5
  impossible_override_rule$provenance$flemma_annotation$resource_matched_tokens <- 1
  impossible_override_rule$provenance$flemma_annotation$resource_match_coverage <- 0.5
  impossible_override_rule$provenance$flemma_annotation$identity_fallback_tokens <- 1
  assert_invalid(impossible_override_rule)

  forged_identity <- annotated
  forged_identity$tokens$flemma[[2L]] <- "fabricated"
  assert_invalid(forged_identity)

  exact_identity <- lexdiv_flemmatize(
    lexdiv_tokenize("Mystery", case = "preserve"),
    path,
    normalization = "identity",
    resource_version = "fixture-004"
  )
  expect_identical(exact_identity$tokens$flemma, "Mystery")
  exact_identity$tokens$flemma <- "fabricated"
  assert_invalid(exact_identity)

  matrix_identity <- lexdiv_flemmatize(
    lexdiv_tokenize("Cats", case = "preserve"),
    path,
    normalization = "identity",
    resource_version = "fixture-004"
  )
  matrix_identity$tokens$flemma <- "cats"
  matrix_identity$provenance$flemma_annotation$query_normalization <-
    matrix("identity", 1L, 1L)
  assert_invalid(matrix_identity)
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
    resource_version = "fixture-004",
    override_version = "analysis-overrides-1"
  )

  expect_identical(
    annotated$tokens$flemma,
    c("interesting", "interested", "saw")
  )
  expect_true(all(annotated$tokens$flemma_matched))
  expect_true(all(annotated$tokens$flemma_match_rule == "override"))
  expect_identical(
    annotated$provenance$flemma_annotation$backend_version,
    "0.1.0"
  )
  expect_identical(
    annotated$provenance$flemma_annotation$resource_version,
    "fixture-004"
  )
  expect_identical(
    annotated$provenance$flemma_annotation$override_entries,
    3
  )
  expect_identical(
    annotated$provenance$flemma_annotation$override_version,
    "analysis-overrides-1"
  )
})

test_that("flemma overrides do not derive byte-level identities", {
  path <- antbnc_fixture_file()
  on.exit(unlink(path), add = TRUE)
  tokenization <- lexdiv_tokenize("Interesting interested saw")
  overrides <- data.frame(
    form = c("interesting", "interested", "saw"),
    flemma = c("interesting", "interested", "saw"),
    stringsAsFactors = FALSE
  )
  reordered <- overrides[c(3L, 1L, 2L), , drop = FALSE]

  first <- lexdiv_flemmatize(
    tokenization,
    path,
    overrides = overrides,
    resource_version = "fixture-004",
    override_version = "analysis-overrides-1"
  )
  second <- lexdiv_flemmatize(
    tokenization,
    path,
    overrides = reordered,
    resource_version = "fixture-004",
    override_version = "analysis-overrides-1"
  )

  expect_identical(first$tokens, second$tokens)
  expect_false(
    "override_canonical_sha256" %in%
      names(first$provenance$flemma_annotation)
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
  expect_false(
    "resource_source_file" %in% names(copied$provenance$flemma_annotation)
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
    backend_version = "1.0",
    upos_backend_id = "fixture-tagger",
    upos_backend_version = "1.0"
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
    backend_version = "1.0",
    upos_backend_id = "fixture-tagger",
    upos_backend_version = "1.0"
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

test_that("annotation and flemma version identities reject path-like values", {
  tokenization <- lexdiv_tokenize("Cats run")
  expect_error(
    lexdiv_lemmatize(
      tokenization,
      lemmas = c("cat", "run"),
      upos = c("NOUN", "VERB"),
      backend_id = "/private/example/model",
      backend_version = "1"
    ),
    "path-free identifier"
  )
  expect_error(
    lexdiv_lemmatize(
      tokenization,
      lemmas = c("cat", "run"),
      upos = c("NOUN", "VERB"),
      backend_id = "fixture",
      backend_version = "C:\\private\\model"
    ),
    "path-free identifier"
  )
  expect_error(
    lexdiv_lemmatize(
      tokenization,
      lemmas = c("cat", "run"),
      backend_id = "../private/model",
      backend_version = "1"
    ),
    "path-free identifier"
  )

  resource <- antbnc_fixture_file()
  on.exit(unlink(resource), add = TRUE)
  expect_error(
    lexdiv_flemmatize(
      tokenization,
      resource,
      resource_version = "../private/resource"
    ),
    "path-free identifier"
  )
  expect_error(
    lexdiv_flemmatize(
      tokenization,
      resource,
      overrides = data.frame(form = "cats", flemma = "cat"),
      resource_version = "fixture-004",
      override_version = "../private/overrides"
    ),
    "path-free identifier"
  )
})

test_that("UPOS identity is always explicit and separate from lemma identity", {
  expect_error(
    lexdiv_lemmatize(
      lexdiv_tokenize("Cats run"),
      lemmas = c("cat", "run"),
      upos = c("NOUN", "VERB"),
      backend_id = "combined-fixture",
      backend_version = "1"
    ),
    "upos_backend_id"
  )
  supplied <- lexdiv_lemmatize(
    lexdiv_tokenize("Cats run"),
    lemmas = c("cat", "run"),
    upos = c("NOUN", "VERB"),
    backend_id = "combined-fixture",
    backend_version = "1",
    upos_backend_id = "fixture-tagger",
    upos_backend_version = "2"
  )
  expect_identical(
    supplied$provenance$annotation$upos_backend_id,
    "fixture-tagger"
  )
  expect_identical(
    supplied$provenance$annotation$upos_backend_version,
    "2"
  )

  skip_if_not_installed("textstem")
  expect_error(
    lexdiv_lemmatize(
      lexdiv_tokenize("Cats run"),
      method = "textstem",
      upos = c("NOUN", "VERB")
    ),
    "upos_backend_id"
  )
  tagged <- lexdiv_lemmatize(
    lexdiv_tokenize("Cats run"),
    method = "textstem",
    upos = c("NOUN", "VERB"),
    upos_backend_id = "fixture-tagger",
    upos_backend_version = "2"
  )
  expect_identical(
    tagged$provenance$annotation$backend_id,
    "textstem::lemmatize_words"
  )
  expect_identical(
    tagged$provenance$annotation$upos_backend_id,
    "fixture-tagger"
  )
})

test_that("tokenizer arguments cannot be silently ignored for tokenized input", {
  tokenization <- lexdiv_tokenize("Cat cat", case = "preserve")

  expect_error(
    lexdiv_metrics_text(tokenization, case = "lower", metrics = "ttr"),
    "case apply only when x is raw text"
  )
  expect_error(
    lexdiv_metrics_text(
      tokenization,
      normalization = "NFKC",
      keep_numbers = TRUE,
      metrics = "ttr"
    ),
    "normalization, keep_numbers apply only when x is raw text"
  )
})

test_that("the raw-text adapter forwards expected-TTR D sample sizes", {
  tokens <- rep(c("a", "b", "a", "c"), 5)
  from_text <- lexdiv_metrics_text(
    paste(tokens, collapse = " "),
    metrics = "expected_ttr_d",
    expected_ttr_sample_sizes = 2:4
  )
  from_tokens <- lexdiv_metrics(
    tokens,
    metrics = "expected_ttr_d",
    expected_ttr_sample_sizes = 2:4
  )

  expect_identical(
    from_text$results$requested_parameters,
    from_tokens$requested_parameters
  )
  expect_identical(from_text$results$value, from_tokens$value)
  expect_identical(from_text$results$status, from_tokens$status)
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
  expect_identical(contract$contract_version, "0.3.0")
  expect_identical(contract$status, "normative")
  expect_identical(contract$public_api, TRUE)
  expect_identical(
    unlist(contract$lexical_units$content_upos, use.names = FALSE),
    c("ADJ", "ADV", "NOUN", "PROPN", "VERB")
  )
  expect_identical(
    unlist(contract$lexical_units$choices, use.names = FALSE),
    c("surface", "lemma", "flemma")
  )
  expect_identical(
    unlist(contract$annotation$upos_inventory, use.names = FALSE),
    c(
      "ADJ", "ADP", "ADV", "AUX", "CCONJ", "DET", "INTJ", "NOUN",
      "NUM", "PART", "PRON", "PROPN", "PUNCT", "SCONJ", "SYM",
      "VERB", "X"
    )
  )
  expect_identical(contract$annotation$unsupported_upos, "error")
  expect_identical(contract$annotation$path_like_backend_identity, "error")
  expect_identical(
    contract$annotation$textstem_with_caller_upos,
    "separate-upos-backend-identity-required"
  )
  expect_identical(contract$result_boundary$metric_core_schema_changed, FALSE)
  expect_identical(
    contract$result_boundary$existing_tokenization_argument_policy,
    "reject-explicit-normalization-case-keep_numbers-or-tokenizer"
  )
  expect_identical(schema$properties$contract_id$const, contract$contract_id)
  expect_identical(
    schema$properties$contract_version$const,
    contract$contract_version
  )
})
