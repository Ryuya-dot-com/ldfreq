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
frequency <- tubelex_frequency_profile(tokenization)
synthetic_levels <- data.frame(
  NJ8 = c(1L, 1001L, 6001L, 8000L),
  Word = c("the", "see", "cat", "saw"),
  stringsAsFactors = FALSE
)
level_profile <- new_jacet8000_profile(
  flemma_annotation,
  synthetic_levels,
  unit = "flemma",
  flemma_conflict = "antbnc"
)
level_profile_batch <- new_jacet8000_profile_batch(
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
profile_batch <- lexdiv_profile_batch(documents, plan)
screen <- lexdiv_screen(profile_batch, floors = c(tokens_4 = 4L))

stopifnot(
  identical(single$status, rep("ok", 3L)),
  identical(expected_d$status, "ok"),
  is.finite(expected_d$value),
  identical(raw_text$results$status, rep("ok", 2L)),
  identical(raw_text$results$N, c(6, 6)),
  all(term_overlap$summary$status == "ok"),
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
  nrow(profile_batch) == 2L,
  all(profile_batch$status == "ok"),
  all(screen$passes_screen)
)

invisible(TRUE)
