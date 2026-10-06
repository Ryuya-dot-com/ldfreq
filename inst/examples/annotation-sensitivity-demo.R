# Offline authored examples, not corpus observations or human gold annotations.
library(ldfreq)
source(system.file("examples", "annotation-sensitivity.R", package = "ldfreq",
  mustWork = TRUE), local = TRUE)
texts <- c(lemma = "cats saw cat.", pos = "we can run and jump.",
  missing = "birds fly.", unknown = "glorp.", excluded = "and the.", empty = "")
prepared <- lexdiv_tokenize_batch(texts, normalization = "none", case = "preserve",
  tokenizer = "english")
lemmas_before <- list(lemma = c("cats", "saw", "cat"),
  pos = c("we", "can", "run", "and", "jump"), missing = c("bird", NA_character_),
  unknown = "glorp", excluded = c("and", "the"), empty = character())
upos_before <- list(lemma = c("NOUN", "VERB", "NOUN"),
  pos = c("PRON", "VERB", "VERB", "CCONJ", "VERB"), missing = c("NOUN", "VERB"),
  unknown = "NOUN", excluded = c("CCONJ", "DET"), empty = character())
lemmas_after <- lemmas_before
lemmas_after$lemma <- c("cat", "see", "cat")
lemmas_after$missing <- c("bird", "fly")
upos_after <- upos_before
upos_after$pos[2] <- "AUX"
upos_after$missing[2] <- NA_character_
annotate <- function(lemmas, upos, version) {
  setNames(lapply(names(prepared), function(id) lexdiv_lemmatize(prepared[[id]],
    lemmas = lemmas[[id]], upos = upos[[id]],
    backend_id = "authored-sensitivity", backend_version = version,
    upos_backend_id = if (any(!is.na(upos[[id]]))) "authored-sensitivity-pos" else NULL,
    upos_backend_version = if (any(!is.na(upos[[id]]))) version else NULL)), names(prepared))
}
before <- annotate(lemmas_before, upos_before, "before-v1")
after <- annotate(lemmas_after, upos_after, "after-v1")
result <- annotation_sensitivity(before, after, texts)
print(result$changes[c("document_id", "token_index", "pre", "keyword", "post",
  "before_lemma", "after_lemma", "before_upos", "after_upos")], row.names = FALSE)
print(subset(result$differences, condition_id == "lemma_content",
  select = c(document_id, metric_id, N_before, N_after, value_before,
    value_after, delta, difference_status)), row.names = FALSE)
# Save explicitly to a new local file after inspection:
# saveRDS(list(result = result, session = sessionInfo()), "annotation-sensitivity.rds")
# In another R session, source annotation-sensitivity.R, then:
# saved <- readRDS("annotation-sensitivity.rds")$result
# replay <- do.call(annotation_sensitivity,
#   c(saved$inputs, list(window_length = saved$settings$window_length)))
# stopifnot(identical(replay, saved))
