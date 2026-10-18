# Authored inputs, MIT licensed; these counts are not empirical group differences.
library(ldfreq)
helper <- new.env(parent = globalenv())
for (file in c("concordance.R", "keyness.R"))
  sys.source(system.file("examples", file, package = "ldfreq", mustWork = TRUE), helper)
surfaces <- list(t1 = c("learn", "learn", "learn", "learn", "read", "."),
  t2 = c("learn", "learn", "write", "unknown"), t_empty = character(),
  r1 = c("learn", "read", "read", "read"), r2 = c("learn", "read", "read", "speak"),
  r_empty = character(), outside = c("unlisted", "unlisted"))
segments <- data.frame(document_id = names(surfaces), segment_id = "s1",
  text = vapply(surfaces, paste, collapse = " ", FUN.VALUE = ""), row.names = NULL)
tokens <- do.call(rbind, lapply(seq_along(surfaces), function(i) data.frame(
  document_id = rep(names(surfaces)[i], length(surfaces[[i]])),
  segment_id = rep("s1", length(surfaces[[i]])), token_index = seq_along(surfaces[[i]]),
  surface = surfaces[[i]])))
tokens$lemma <- tokens$surface
tokens$lemma[tokens$surface == "unknown"] <- NA_character_
annotations <- lexdiv_import_annotations(tokens, segments,
  list(language = "en", analyzer = "authored", analyzer_version = "1", dictionary = "none",
    dictionary_version = "not-applicable", unit = "authored-tokens", normalization = "none"))
comparison <- helper$keyness_compare(annotations, target = c("t1", "t2", "t_empty"),
  reference = c("r1", "r2", "r_empty"), preprocessing_id = "authored-lemma-exclude-period",
  term_col = "lemma", keep = tokens$surface != ".")
record <- list(comparison = comparison, session = utils::sessionInfo())
helper$keyness_validate(comparison)
stopifnot(identical(comparison$totals$counted_tokens, c(8, 8)),
  comparison$results$target_count[comparison$results$term == "learn"] == 6,
  comparison$results$log_ratio[comparison$results$term == "write"] == Inf,
  comparison$results$log_ratio[comparison$results$term == "speak"] == -Inf)
