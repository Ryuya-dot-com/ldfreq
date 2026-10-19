# Authored counts, MIT licensed. These documents illustrate calculations only.
library(ldfreq)
helper <- new.env(parent = globalenv())
for (file in c("concordance.R", "lexical-ordination.R"))
  sys.source(system.file("examples", file, package = "ldfreq", mustWork = TRUE), helper)
surfaces <- list(
  d1 = c(rep("learn", 4), rep("read", 2), "write", "."),
  d2 = c(rep("learn", 3), "read", rep("speak", 2)),
  d3 = c(rep("tree", 4), rep("river", 2), "rain"),
  d4 = c(rep("tree", 2), rep("rain", 3), "wind"),
  d5 = c(rep("learn", 2), rep("river", 2), rep("write", 2)),
  d6 = c("tree", rep("read", 3), rep("speak", 2)),
  d7 = c("learn", rep("read", 4), rep("write", 2)),
  partial = c("learn", "unknown"), empty = character(),
  removed = ".", outside = "unlisted")
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
tab <- helper$ordination_table(annotations, setdiff(names(surfaces), "outside"),
  preprocessing_id = "authored-lemma-exclude-period", term_col = "lemma",
  keep = annotations$tokens$surface != ".")
jaccard <- helper$ordination_mds(tab, "jaccard")
hellinger <- helper$ordination_mds(tab, "hellinger")
ca_result <- if (requireNamespace("ca", quietly = TRUE)) helper$ordination_ca(tab) else NULL
record <- list(table = tab, ca = ca_result, jaccard = jaccard, hellinger = hellinger,
  session = utils::sessionInfo())
stopifnot(nrow(tab$active_counts) == 7L, sum(tab$active_counts) == 45,
  as.matrix(jaccard$distance)["d1", "d7"] == 0,
  as.matrix(hellinger$distance)["d1", "d7"] > 0,
  identical(tab$documents$status[8:11],
    c("incomplete_terms", "empty_source", "no_selected_tokens", "not_requested")))
