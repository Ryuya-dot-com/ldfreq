ambiguity_fixture <- function(japanese = FALSE) {
  values <- if (japanese) list(c("その", "店", "は", "人気", "が", "ある", "。"),
    c("ここ", "は", "人気", "が", "ない", "。")) else
    list(c("The", "bank", "lent", "money", "."), c("The", "river", "bank", "flooded", "."))
  tokens <- data.frame(document_id = "d", segment_id = rep(c("s1", "s2"), lengths(values)),
    token_index = sequence(lengths(values)), surface = unlist(values, use.names = FALSE))
  segments <- data.frame(document_id = c("d", "d", "empty"), segment_id = c("s1", "s2", "s1"),
    text = c(if (japanese) c("その店は人気がある。", "ここは人気がない。") else
      c("The bank lent money.", "The river bank flooded."), ""))
  x <- lexdiv_import_annotations(tokens, segments, list(language = if (japanese) "ja" else "en",
    analyzer = "authored", analyzer_version = "1", dictionary = "none",
    dictionary_version = "not-applicable", unit = "authored", normalization = "none"))
  term <- if (japanese) "人気" else "bank"
  candidates <- data.frame(term = rep(term, 2), candidate_id = c("sense-a", "sense-b"),
    label = if (japanese) c("popularity", "presence of people") else c("financial institution", "river edge"))
  if (japanese) candidates$reading <- c("にんき", "ひとけ")
  list(x = x, targets = c(term, "absent"), candidates = candidates,
    resource = list(resource_id = "authored-example", resource_version = "1",
      source_reference = "Authored test candidates, not a dictionary", data_license = "MIT"))
}

ambiguity_decisions <- function(review) {
  out <- review$occurrences[c("review_id", "occurrence_id")]
  out$status <- c("selected", "unresolved")
  out$candidate_id <- c("sense-a", NA_character_)
  out$reviewer <- "author"
  out$reason <- c("Money-lending context", "Keep for adjudication")
  out
}

