# Explicit optional workflow using quanteda through the existing review API.
# Authored sentences and memberships; no independent annotation-accuracy claim.
word_family_review_example <- local({
  segments <- data.frame(document_id = c("example", "example", "empty"),
    segment_id = c("s1", "s2", "s1"),
    text = c("The bank lends money.", "The river bank floods.", ""))
  data <- data.frame(document_id = "example", segment_id = rep(c("s1", "s2"), each = 5),
    token_index = rep(1:5, 2),
    surface = c("The", "bank", "lends", "money", ".", "The", "river", "bank", "floods", "."),
    upos = c("DET", "NOUN", "VERB", "NOUN", "PUNCT", "DET", "NOUN", "NOUN", "VERB", "PUNCT"))
  annotations <- ldfreq::lexdiv_import_annotations(data, segments,
    list(language = "en", analyzer = "authored", analyzer_version = "1",
      dictionary = "authored", dictionary_version = "1", unit = "word", normalization = "none"))
  dictionary <- data.frame(record_id = sprintf("r%02d", 1:7),
    form = c("The", "bank", "bank", "lends", "money", "river", "floods"),
    family_id = c("THE", "BANK_FINANCE", "BANK_RIVER", "LEND", "MONEY", "RIVER", "FLOOD"))
  resource <- list(resource_id = "authored-contextual-families", resource_version = "1",
    language = "en", source_reference = "ldfreq word-family-review.R authored example",
    data_license = "MIT", lookup_unit = "surface",
    family_definition = "Illustrative groups with two BANK families; no Nation level assigned")
  initial <- ldfreq::lexdiv_family_profile(annotations, dictionary, resource, exclude_pos = "PUNCT")
  review <- do.call(ldfreq::lexdiv_ambiguity_review,
    c(list(x = initial$annotations), initial$review_input))
  decisions <- review$occurrences[review$occurrences$surface == "bank",
    c("review_id", "occurrence_id")]
  decisions$status <- "selected"
  decisions$candidate_id <- c("r02", "r03") # Select RECORD IDs, not family IDs.
  decisions$reviewer <- "authored-example"
  decisions$reason <- c("Lending money context", "River and flooding context")
  review <- do.call(ldfreq::lexdiv_ambiguity_review,
    c(list(x = initial$annotations), initial$review_input, list(decisions = decisions)))
  reviewed <- ldfreq::lexdiv_family_profile(annotations, dictionary, resource,
    exclude_pos = "PUNCT", review = review)
  list(initial = initial, reviewed = reviewed)
})
