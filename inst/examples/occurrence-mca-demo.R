# Authored MIT-licensed examples and judgments, not observations or WSD predictions.
library(ldfreq)
helper <- new.env(parent = globalenv())
for (script in c("concordance.R", "lexical-ordination.R", "occurrence-mca.R"))
  sys.source(system.file("examples", script, package = "ldfreq", mustWork = TRUE), helper)
text <- c("The bank approved the loan.", "A bank approved the loan.",
  "We visited the bank.", "They opened a bank.", "We borrowed from the bank.",
  "She works at a bank.", "The bank collapsed into the river.",
  "A bank rose above the stream.", "We climbed the bank.", "They reinforced a bank.",
  "We sat on the bank.", "He stood beside a bank.", "The bank increased its rates.",
  "We contacted the bank about a loan.", "They camped beside the bank.",
  "We stopped near the bank.", "The bank appeared in the exercise.")
segments <- data.frame(document_id = sprintf("d%02d", seq_along(text)),
  segment_id = "s1", text = text)
tokens <- do.call(rbind, lapply(seq_along(text), function(i) {
  words <- regmatches(text[i], gregexpr("[A-Za-z]+|[.]", text[i]))[[1L]]
  data.frame(document_id = segments$document_id[i], segment_id = "s1",
    token_index = seq_along(words), surface = words)
}))
annotations <- lexdiv_import_annotations(tokens, segments,
  list(language = "en", analyzer = "authored", analyzer_version = "1", dictionary = "none",
    dictionary_version = "not-applicable", unit = "authored-tokens", normalization = "none"))
occurrences <- annotations$tokens[annotations$tokens$surface == "bank",
  c("document_id", "segment_id", "token_index", "start", "end", "surface")]
rownames(occurrences) <- NULL
occurrences$occurrence_id <- sprintf("u%02d", seq_along(text))
occurrences$writer_id <- rep(c("author-A", "author-B", "author-C"), c(8, 4, 5))
occurrences$sense <- factor(c(rep("finance", 6), rep("river", 6),
  "finance", "finance", "river", NA, "finance"), levels = c("finance", "river", "unused-sense"))
occurrences$role <- factor(c(rep(rep(c("subject", "object", "oblique"), each = 2), 2),
  "subject", "object", "oblique", "oblique", NA))
occurrences$determiner <- factor(c(rep(c("definite", "indefinite"), 6), rep("definite", 5)))
definitions <- c(sense = "Author-intended financial institution or river edge; undecided is NA",
  role = "Target noun phrase: subject, direct object, or prepositional oblique",
  determiner = "The target phrase uses the (definite) or a (indefinite)")
tab <- helper$ordination_mca_table(annotations, occurrences, definitions,
  coding_id = "authored-bank-sense-role-determiner-v1")
result <- if (requireNamespace("ca", quietly = TRUE)) helper$ordination_mca(tab) else NULL
record <- list(table = tab, mca = result, session = sessionInfo())
stopifnot(identical(dim(tab$indicator), c(15L, 7L)), all(rowSums(tab$indicator) == 3),
  identical(tab$observations$missing_variables[16:17], c("sense", "role")))
