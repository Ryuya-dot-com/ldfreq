# Authored inputs, MIT licensed; these illustrate searches, not learner outcomes.
library(ldfreq)
helper <- new.env(parent = globalenv())
sys.source(system.file("examples", "concordance.R", package = "ldfreq", mustWork = TRUE), helper)

segments <- data.frame(document_id = c("spread", "cluster", "context", "context", "absent", "empty"),
  segment_id = c("s1", "s1", "s1", "s2", "s1", "s1"),
  text = c("learn a b c learn d e f learn g h i",
    "learn learn learn a b c d e f g h i",
    "We learn new words. They learned new words.", "learn very new words", "read a book", ""))
surfaces <- list(c("learn", "a", "b", "c", "learn", "d", "e", "f", "learn", "g", "h", "i"),
  c(rep("learn", 3), letters[1:9]),
  c("We", "learn", "new", "words", ".", "They", "learned", "new", "words", "."),
  c("learn", "very", "new", "words"), c("read", "a", "book"), character())
tokens <- do.call(rbind, lapply(seq_along(surfaces), function(i) data.frame(
  document_id = rep(segments$document_id[i], length(surfaces[[i]])),
  segment_id = rep(segments$segment_id[i], length(surfaces[[i]])),
  token_index = seq_along(surfaces[[i]]), surface = surfaces[[i]])))
tokens$lemma <- tolower(tokens$surface)
tokens$lemma[tokens$surface == "learned"] <- "learn"
annotations <- lexdiv_import_annotations(tokens, segments,
  list(language = "en", analyzer = "authored", analyzer_version = "1",
    dictionary = "none", dictionary_version = "not-applicable", unit = "authored-tokens",
    normalization = "none"))
# An explicit illustrative policy; excluded slots still block phrase matches.
keep <- !tokens$surface %in% c(".", "very")
search <- helper$concordance_search(annotations,
  list(word = "learn", phrase = c("learn", "new"), absent = "unlisted"),
  term_col = "lemma", keep = keep, window = 2L)
sorted <- helper$concordance_sort(search, side = "right", depth = 2L)
dispersion <- helper$concordance_dispersion(search, "word", parts = 3L)
record <- list(search = search, sorted = sorted, dispersion = dispersion,
  sort = list(side = "right", depth = 2L, ignore_case = FALSE),
  session = utils::sessionInfo())
stopifnot(identical(dispersion$occurrence_ids,
  search$occurrences$occurrence_id[search$occurrences$query_id == "word"]),
  isTRUE(all.equal(dispersion$documents$DP[1:2], c(0, 2/3))))
