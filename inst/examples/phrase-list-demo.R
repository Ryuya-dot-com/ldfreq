# Authored English/Japanese example, MIT licensed. No corpus/list is downloaded.
library(ldfreq)
source(system.file("examples", "phrase-list-kwic.R", package = "ldfreq", mustWork = TRUE),
  local = TRUE)

segments <- data.frame(document_id = c("en", "en", "ja", "empty"),
  segment_id = c("s1", "s2", "s1", "s1"),
  text = c("In the end of the day, in the end.", "in the very end",
    "国際連合で国際協力を学ぶ。", ""))
surfaces <- list(c("In", "the", "end", "of", "the", "day", ",", "in", "the", "end", "."),
  c("in", "the", "very", "end"), c("国際", "連合", "で", "国際", "協力", "を", "学ぶ", "。"), character())
tokens <- do.call(rbind, lapply(seq_along(surfaces), function(i) data.frame(
  document_id = rep(segments$document_id[i], length(surfaces[[i]])),
  segment_id = rep(segments$segment_id[i], length(surfaces[[i]])),
  token_index = seq_along(surfaces[[i]]), surface = surfaces[[i]])))
annotations <- lexdiv_import_annotations(tokens, segments,
  list(language = "en+ja", analyzer = "authored", analyzer_version = "1",
    dictionary = "none", dictionary_version = "not-applicable", unit = "authored-tokens",
    normalization = "none"))
phrases <- list(long = c("In", "the", "end", "of", "the", "day"),
  nested = c("the", "end"), short = c("in", "the", "end"),
  japanese = c("国際", "協力", "を", "学ぶ"), absent = c("not", "present"))
resource <- list(resource_id = "authored-phrase-demo", resource_version = "1",
  source_reference = "Original ldfreq example; not an established phrase inventory",
  data_license = "MIT")
# These exclusions are illustrative, not a recommended stopword/punctuation policy.
keep <- !annotations$tokens$surface %in% c(",", ".", "。", "very")
result <- phrase_list_kwic(annotations, phrases, resource, keep, window = 2L)
print(result$occurrences[c("phrase_id", "document_id", "segment_id", "from", "to",
  "start", "end", "pre", "keyword", "post")], row.names = FALSE)
print(result$documents, row.names = FALSE)
print(result$summary, row.names = FALSE)
