# Offline installed-package smoke test for the exported ldfreq workflows.

tokens <- c("the", "cat", "saw", "the", "other", "cat")
documents <- list(
  document_a = tokens,
  document_b = c("one", "two", "one", "three")
)

single <- lexdiv_metrics(tokens, metrics = c("ttr", "rttr", "yule_k"))
tokenization <- lexdiv_tokenize("The cat saw the other cat.")
raw_text <- lexdiv_metrics_text(tokenization, metrics = c("ttr", "rttr"))
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
  identical(raw_text$results$status, rep("ok", 2L)),
  identical(raw_text$results$N, c(6, 6)),
  identical(flemma_text$results$status, "ok"),
  identical(flemma_text$results$N, 6),
  identical(
    flemma_annotation$provenance$flemma_annotation$resource_bundled,
    FALSE
  ),
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
  identical(profile$status, "ok"),
  nrow(profile_batch) == 2L,
  all(profile_batch$status == "ok"),
  all(screen$passes_screen)
)

invisible(TRUE)
