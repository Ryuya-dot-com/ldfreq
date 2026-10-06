# Offline authored examples; these are not learner observations or gold corrections.
library(ldfreq)
source(system.file("examples", "reviewed-text.R", package = "ldfreq",
  mustWork = TRUE), local = TRUE)
documents <- data.frame(
  document_id = c("spelling", "grammar", "boundary", "real_word", "uncertain", "empty"),
  writer_id = paste0("authored-", 1:6), task = "illustration",
  text = c("A freind met a friend.", "She has beautiful garden.", "I like alot.",
    "I went too school.", "I saw a glorp in Kyoto.", ""))
edits <- data.frame(edit_id = paste0("e", 1:6),
  document_id = c("spelling", "grammar", "boundary", "real_word", "uncertain", "uncertain"),
  start = c(3L, 9L, 8L, 8L, 9L, 18L), end = c(8L, 8L, 11L, 10L, 13L, 22L),
  original = c("freind", "", "alot", "too", "glorp", "Kyoto"),
  replacement = c("friend", "a ", "a lot", "to", "globe", "Tokyo"),
  category = c("spelling", "grammar", "word_boundary", "real_word", "lexical_choice", "proper_name"),
  decision = c(rep("approved", 4), "unresolved", "rejected"),
  reviewer = c(rep("example-author", 4), "", "example-author"),
  reason = c("Authored transposition", "Authored article insertion",
    "Authored word-boundary repair", "Authored context-dependent substitution",
    "Intended meaning unknown", "No basis for changing the place name"))
policies <- list(original = list(categories = character(), policy = "Preserve all observed text."),
  spelling_reviewed = list(categories = "spelling", policy = "Apply approved spelling edits only; preserve grammar and word boundaries."),
  expanded_review = list(categories = unique(edits$category), policy = "Apply all approved edits, including grammar and word boundaries; this changes the measurement target."))
versions <- runs <- metric_rows <- coverage_rows <- list()
for (version in names(policies)) {
  versions[[version]] <- do.call(apply_reviewed_edits,
    c(list(documents = documents, edits = edits), policies[[version]]))
  # Tokenize each complete version afresh. Token IDs/offsets cannot be paired
  # across revised strings; preserve these objects and their own provenance.
  prepared <- lexdiv_tokenize_batch(versions[[version]]$revised,
    tokenizer = "english", normalization = "NFC", case = "lower")
  diversity <- lexdiv_metrics_text_batch(prepared, unit = "surface",
    metrics = c("ttr", "mattr"), window_length = 4L)
  reference <- nj8_profile_batch(prepared, unit = "surface")
  runs[[version]] <- list(prepared = prepared, diversity = diversity, reference = reference)
  metric_rows[[version]] <- cbind(version = version, as.data.frame(diversity$results))
  coverage_rows[[version]] <- cbind(version = version, reference$coverage)
}
result <- list(versions = versions, runs = runs,
  metrics = do.call(rbind, metric_rows), coverage = do.call(rbind, coverage_rows),
  settings = list(metrics = c("ttr", "mattr"), window_length = 4L,
    unit = "surface", tokenizer = "english", normalization = "NFC", case = "lower",
    ldfreq_version = as.character(packageVersion("ldfreq"))))
rownames(result$metrics) <- rownames(result$coverage) <- NULL
print(subset(result$metrics, metric_id == "ttr",
  select = c(document_id, version, N, V, value, status)), row.names = FALSE)
# Four tokens is only an illustrative MATTR window, not a study recommendation.
# Save all versions, decisions, sources, settings and session details locally:
# saveRDS(list(result = result, session = sessionInfo()), "reviewed-text.rds")
# saved <- readRDS("reviewed-text.rds")$result
# Reapply an edited version without using the revised text as its new source:
# stopifnot(identical(do.call(apply_reviewed_edits,
#   saved$versions$expanded_review$inputs), saved$versions$expanded_review))
