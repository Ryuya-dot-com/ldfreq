# Authored forms and family decisions illustrate accounting, not an inventory
# validated by Nation or evidence of a learner's morphological knowledge.
word_families_example <- local({
  segments <- data.frame(document_id = c("complete", "unresolved", "empty"),
    segment_id = "s1", text = c("use uses reusability use.", "bank quux.", ""))
  data <- data.frame(document_id = c(rep("complete", 5), rep("unresolved", 3)),
    segment_id = "s1", token_index = c(1:5, 1:3),
    surface = c("use", "uses", "reusability", "use", ".", "bank", "quux", "."),
    lemma = c("use", "use", "reusability", "use", ".", "bank", "quux", "."),
    upos = c("VERB", "VERB", "NOUN", "VERB", "PUNCT", "NOUN", "NOUN", "PUNCT"))
  data$flemma <- data$lemma # Explicit authored layer; not derived from a family.
  annotations <- ldfreq::lexdiv_import_annotations(data, segments,
    list(language = "en", analyzer = "authored", analyzer_version = "1",
      dictionary = "authored", dictionary_version = "1", unit = "word",
      normalization = "none"))
  dictionary <- data.frame(record_id = sprintf("r%02d", 1:5),
    form = c("use", "uses", "reusability", "bank", "bank"),
    family_id = c("USE", "USE", "USE", "BANK_FINANCE", "BANK_RIVER"))
  resource <- list(resource_id = "authored-family-example", resource_version = "1",
    language = "en", source_reference = "ldfreq word-families.R authored example",
    data_license = "MIT", lookup_unit = "surface",
    family_definition = "Illustrative USE group and separate BANK meanings; no Nation level assigned")
  profile <- ldfreq::lexdiv_family_profile(annotations, dictionary, resource,
    exclude_pos = "PUNCT")

  # Use the SAME selected occurrences for each counting unit. Do not delete
  # unknown families and join the remaining tokens into a new MATTR sequence.
  stopifnot(profile$documents$status[1] == "complete")
  rows <- which(profile$occurrences$document_id == "complete" &
    profile$occurrences$selected %in% TRUE)
  units <- c(data[rows, c("surface", "lemma", "flemma")],
    list(family = profile$occurrences$family_id[rows]))
  comparison <- do.call(rbind, lapply(names(units), function(unit) {
    # Encode arbitrary IDs without changing equality, order or repetition.
    keys <- as.character(match(units[[unit]], unique(units[[unit]])))
    result <- ldfreq::lexdiv_metrics(keys, metrics = c("ttr", "mattr"), window_length = 3)
    data.frame(unit = unit, result[c("metric_id", "value", "N", "V")])
  }))
  list(profile = profile, comparison = comparison)
})
