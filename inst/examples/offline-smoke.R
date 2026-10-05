# Offline installed-package smoke test for the exported ldfreq workflows.

tokens <- c("the", "cat", "saw", "the", "other", "cat")
documents <- list(
  document_a = tokens,
  document_b = c("one", "two", "one", "three")
)

single <- lexdiv_metrics(tokens, metrics = c("ttr", "rttr", "yule_k"))
expected_d <- lexdiv_metrics(
  rep(tokens, 10L),
  metrics = "expected_ttr_d"
)
tokenization <- lexdiv_tokenize("The cat saw the other cat.")
raw_text <- lexdiv_metrics_text(tokenization, metrics = c("ttr", "rttr"))
annotated_a <- lexdiv_lemmatize(
  tokenization,
  lemmas = c("the", "cat", "see", "the", "other", "cat"),
  upos = c("DET", "NOUN", "VERB", "DET", "ADJ", "NOUN"),
  backend_id = "project-authored-smoke-fixture",
  backend_version = "1",
  upos_backend_id = "project-authored-upos-fixture",
  upos_backend_version = "1"
)
annotated_b <- lexdiv_lemmatize(
  lexdiv_tokenize("The cat saw another dog."),
  lemmas = c("the", "cat", "see", "another", "dog"),
  upos = c("DET", "NOUN", "VERB", "DET", "NOUN"),
  backend_id = "project-authored-smoke-fixture",
  backend_version = "1",
  upos_backend_id = "project-authored-upos-fixture",
  upos_backend_version = "1"
)
term_overlap <- lexdiv_term_overlap(tokens, documents$document_b)
reference_coverage <- lexdiv_reference_coverage(
  documents,
  reference = c("the", "cat", "one", "two"),
  reference_id = "smoke_reference",
  details = "terms"
)
synthetic_norms <- data.frame(
  term = c("the", "cat", "other"),
  rating = c(7, 5, NA_real_),
  stringsAsFactors = FALSE
)
norm_specs <- data.frame(
  measure_id = "example_rating",
  value_column = "rating",
  construct_id = "example_construct",
  value_unit = "seven_point_rating",
  direction = "descriptive",
  language = "English",
  variety = "unspecified",
  population_id = "smoke_fixture",
  collection_year = "2025",
  valid_min = 1,
  valid_max = 7,
  stringsAsFactors = FALSE
)
norm_resource <- list(
  resource_id = "synthetic_norms",
  resource_version = "1",
  creator = "Project-authored smoke fixture",
  source_reference = "offline-smoke.R",
  data_license = "synthetic-example-only",
  transformation_id = "none",
  lookup_unit = "exact_term",
  resource_key_normalization_id = "caller-prepared-v1"
)
norm_profile <- lexdiv_norm_profile(
  c("the", "cat", "cat", "other", "outside"),
  synthetic_norms,
  "term",
  norm_specs,
  norm_resource
)
content_overlap <- lexdiv_content_overlap(
  annotated_a,
  annotated_b,
  document_ids = c("document_a", "document_b")
)
antbnc_fixture <- tempfile(fileext = ".txt")
writeLines(
  c(
    "cat\t->\tcat\tcats",
    "other\t->\tother",
    "see\t->\tsaw\tsee",
    "the\t->\tthe"
  ),
  antbnc_fixture,
  useBytes = TRUE
)
flemma_annotation <- lexdiv_flemmatize(
  tokenization,
  antbnc_fixture,
  resource_version = "project-authored-smoke-fixture"
)
unlink(antbnc_fixture)
flemma_text <- lexdiv_metrics_text(
  flemma_annotation,
  unit = "flemma",
  metrics = "ttr"
)
frequency_terms <- c("the", "cat", "saw", "the", "other", "cat")
frequency <- tubelex_profile(frequency_terms)
frequency_batch <- tubelex_profile_batch(list(a = frequency_terms, b = frequency_terms))
stopifnot(identical(frequency, frequency_batch$a),
          identical(names(frequency_batch), c("a", "b")))
synthetic_levels <- data.frame(
  NJ8 = c(1L, 1001L, 6001L, 8000L),
  Word = c("the", "see", "cat", "saw"),
  stringsAsFactors = FALSE
)
level_profile <- nj8_profile(
  flemma_annotation,
  synthetic_levels,
  unit = "flemma",
  flemma_conflict = "antbnc"
)
level_profile_batch <- nj8_profile_batch(
  list(document_a = flemma_annotation, document_b = flemma_annotation),
  synthetic_levels,
  unit = "flemma",
  flemma_conflict = "wordlist"
)
variants <- lexdiv_variant_metrics(
  rep(tokens, 10L),
  mtld_thresholds = c(0.72, 0.92)
)
batch <- lexdiv_metrics_batch(documents, metrics = c("ttr", "hdd"), sample_size = 2)
tidy_documents <- lexdiv_as_documents(data.frame(
  document_id = c("a", "a", "b"),
  token = c("one", "two", "three"),
  stringsAsFactors = FALSE
))
wide <- lexdiv_widen(
  lexdiv_metrics_batch(tidy_documents, metrics = c("ttr", "maas")),
  values_from = "value"
)

methods <- lexdiv_methods()
mattr_method <- methods$method_id[methods$metric_id == "mattr"]
mattr_4 <- lexdiv_spec(
  mattr_method,
  parameters = list(window_length = 4),
  request_id = "mattr_4"
)
plan <- lexdiv_plan(presets = character(), specs = mattr_4)
profile <- lexdiv_profile(tokens, plan)
mattr_profile <- lexdiv_mattr_profile(tokens, plan)
profile_batch <- lexdiv_profile_batch(documents, plan)
screen <- lexdiv_screen(profile_batch, floors = c(tokens_4 = 4L))

check_print_contract <- function(value) {
  visibility <- NULL
  output <- capture.output(visibility <- withVisible(print(value)))
  stopifnot(
    length(output) > 0L,
    !visibility$visible,
    identical(visibility$value, value)
  )
  invisible(TRUE)
}
invisible(lapply(
  list(
    tokenization,
    raw_text,
    variants,
    frequency,
    term_overlap,
    mattr_profile,
    norm_profile
  ),
  check_print_contract
))

stopifnot(
  identical(single$status, rep("ok", 3L)),
  identical(expected_d$status, "ok"),
  is.finite(expected_d$value),
  identical(raw_text$results$status, rep("ok", 2L)),
  identical(raw_text$results$N, c(6, 6)),
  all(term_overlap$summary$status == "ok"),
  identical(nrow(reference_coverage$summary), 4L),
  identical(reference_coverage$summary$weighting, rep(c("token", "type"), 2L)),
  all(reference_coverage$summary$status == "ok"),
  isTRUE(reference_coverage$provenance$contains_lexical_terms),
  identical(norm_profile$status, "ok"),
  identical(nrow(norm_profile$lookup), 5L),
  identical(nrow(norm_profile$summary), 2L),
  identical(norm_profile$summary$matched_units, c(4, 3)),
  identical(norm_profile$summary$observed_value_units, c(3, 2)),
  isTRUE(all.equal(
    norm_profile$summary$resource_coverage,
    c(4 / 5, 3 / 4)
  )),
  isTRUE(all.equal(
    norm_profile$summary$annotation_coverage,
    c(3 / 4, 2 / 3)
  )),
  identical(
    norm_profile$lookup$value_status,
    c("observed", "observed", "observed", "missing_annotation", "not_applicable_oov")
  ),
  identical(norm_profile$provenance$resource$resource_id, "synthetic_norms"),
  identical(norm_profile$diagnostics$runtime_network_access, FALSE),
  identical(content_overlap$summary$shared_type_count, rep(2, 5L)),
  all(content_overlap$summary$status == "ok"),
  identical(content_overlap$coverage$eligible_tokens, c(4, 3)),
  identical(flemma_text$results$status, "ok"),
  identical(flemma_text$results$N, 6),
  identical(
    flemma_annotation$provenance$flemma_annotation$resource_bundled,
    FALSE
  ),
  is.null(
    flemma_annotation$provenance$flemma_annotation$resource_source_file
  ),
  !any(grepl(
    "sha256",
    names(flemma_annotation$provenance$flemma_annotation),
    fixed = TRUE
  )),
  identical(frequency$status, "ok"),
  identical(nrow(frequency$lookup), 6L),
  is.finite(frequency$coverage$token_coverage),
  identical(level_profile$status, "ok"),
  identical(nrow(level_profile$summary), 18L),
  is.finite(level_profile$coverage$token_coverage),
  identical(level_profile$provenance$resource_bundled, FALSE),
  identical(level_profile$diagnostics$flemma_headword_conflicts, 1),
  identical(nrow(level_profile_batch$coverage), 2L),
  identical(nrow(level_profile_batch$summary), 36L),
  identical(level_profile_batch$provenance$resource_bundled, FALSE),
  identical(nrow(variants), 12L),
  all(variants$status == "ok"),
  nrow(batch) == 4L,
  all(batch$status == "ok"),
  identical(names(wide), c("document_id", "ttr", "maas")),
  identical(wide$document_id, c("a", "b")),
  identical(profile$status, "ok"),
  identical(mattr_profile$summary, profile),
  identical(nrow(mattr_profile$windows), 3L),
  identical(nrow(mattr_profile$exposure), 6L),
  identical(mattr_profile$provenance$contains_token_strings, FALSE),
  nrow(profile_batch) == 2L,
  all(profile_batch$status == "ok"),
  all(screen$passes_screen)
)

# The real bundled NJ8 resource is available without a file path or network.
bundled_levels <- nj8_profile(c("true", "false", "nan", "ldfreq_not_a_word"))
stopifnot(
  isTRUE(bundled_levels$provenance$resource_bundled),
  identical(bundled_levels$lookup$rank, c(326L, 2382L, 6926L, NA_integer_)),
  bundled_levels$diagnostics$missing_rank_count == 0
)

# English text input requires no Python, network or model download.
english_texts <- data.frame(document_id = c("essay", "empty"),
  text = c("The cat can't read. 3.14 https://example.org", ""))
english_tokens <- lexdiv_tokenize_batch(english_texts, tokenizer = "english", case = "lower")
english_batch <- lexdiv_metrics_text_batch(english_tokens, metrics = "ttr")
stopifnot(
  identical(english_tokens$essay$tokens$surface, c("the", "cat", "can't", "read")),
  identical(english_tokens$essay$provenance$excluded_spans$reason, c("number", "url")),
  identical(english_batch$results$document_id, c("essay", "empty")),
  identical(english_batch$results$status, c("ok", "missing")),
  identical(names(english_batch$preprocessing), c("essay", "empty"))
)
check_print_contract(english_batch)

# Source-linked label evaluation and downstream noun TTR, without a model.
annotation_demo <- new.env(parent = baseenv())
sys.source(system.file("examples", "annotation-evaluation.R", package = "ldfreq",
  mustWork = TRUE), envir = annotation_demo)
annotation_result <- annotation_demo$annotation_evaluation_example
stopifnot(
  is.function(lexdiv_evaluate_annotations),
  identical(annotation_result$differences$delta_ttr[1:2], c(.5, .5)),
  all(is.na(annotation_result$differences$delta_ttr[3:5])),
  annotation_result$evaluation$summary$reference_only == 1,
  annotation_result$evaluation$summary$prediction_only == 1
)

# Different token boundaries retain global correspondence beside label agreement.
alignment_env <- new.env(parent = baseenv())
sys.source(system.file("examples", "annotation-alignment.R", package = "ldfreq",
  mustWork = TRUE), alignment_env)
alignment <- alignment_env$annotation_alignment_example$alignment
stopifnot(is.function(lexdiv_align_annotations),
  alignment$summary$matched[1] == 4,
  alignment$annotation_evaluation$summary$agreement_among_paired == 1)

# Basic UD pairs retain endpoint errors even when document counts agree.
amod_env <- new.env(parent = baseenv())
sys.source(system.file("examples", "amod-pairs.R", package = "ldfreq",
  mustWork = TRUE), amod_env)
amod <- amod_env$amod_pairs_example
stopifnot(is.function(lexdiv_amod_pairs), amod$differences$delta_pairs[2] == 0,
  amod$differences$fp[2] == 1, amod$differences$fn[2] == 1,
  all(is.na(amod$differences$delta_pairs[5:6])))

invisible(TRUE)
