# Authored inputs, MIT licensed; no empirical learner or corpus claims.
library(ldfreq)
helper <- new.env(parent = globalenv())
for (file in c("concordance.R", "collocation.R"))
  sys.source(system.file("examples", file, package = "ldfreq", mustWork = TRUE), helper)
segments <- data.frame(document_id = c("d1", "d2", "d2", "gap", "missing", "empty"),
  segment_id = c("s1", "s1", "s2", "s1", "s1", "s1"),
  text = c("a b a b c", "a c b a", "b a", "a , b", "a gap b", ""))
surfaces <- list(c("a", "b", "a", "b", "c"), c("a", "c", "b", "a"),
  c("b", "a"), c("a", ",", "b"), c("a", "gap", "b"), character())
tokens <- do.call(rbind, lapply(seq_along(surfaces), function(i) data.frame(
  document_id = rep(segments$document_id[i], length(surfaces[[i]])),
  segment_id = rep(segments$segment_id[i], length(surfaces[[i]])),
  token_index = seq_along(surfaces[[i]]), surface = surfaces[[i]])))
tokens$lemma <- tokens$surface
tokens$lemma[tokens$surface == "gap"] <- NA_character_
annotations <- lexdiv_import_annotations(tokens, segments,
  list(language = "en", analyzer = "authored", analyzer_version = "1", dictionary = "none",
    dictionary_version = "not-applicable", unit = "authored-tokens", normalization = "none"))
search <- helper$concordance_search(annotations,
  list(a = "a", absent = "absent", phrase = c("a", "b")), term_col = "lemma",
  keep = tokens$surface != ",", window = 2L)
adjacent <- helper$collocation_profile(search, "a")
span <- helper$collocation_profile(search, "a", span = c(left = 2L, right = 2L))
record <- list(adjacent = adjacent, span = span, session = utils::sessionInfo())
helper$collocation_validate(adjacent)
helper$collocation_validate(span)
stopifnot(sum(adjacent$documents$eligible_pairs) == 8,
  sum(adjacent$documents$node_pairs) == 3,
  adjacent$results$observed[adjacent$results$context == "b"] == 2)
