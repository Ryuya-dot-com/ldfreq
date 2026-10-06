# Nation's actual list, on authored text. No POS or family labels are invented.
bnccoca_example <- local({
  reference <- ldfreq::bnccoca_data()
  segments <- data.frame(document_id = c("listed", "unlisted"), segment_id = "s1",
    text = c("use uses colour color", "use reusability"))
  tokens <- data.frame(document_id = c(rep("listed", 4), rep("unlisted", 2)),
    segment_id = "s1", token_index = c(1:4, 1:2),
    surface = c("use", "uses", "colour", "color", "use", "reusability"))
  # Authored lemmas for comparing units; no tagger is run by this example.
  tokens$lemma <- c("use", "use", "colour", "color", "use", "reusability")
  annotations <- ldfreq::lexdiv_import_annotations(tokens, segments,
    list(language = "en", analyzer = "authored token boundaries", analyzer_version = "1",
      dictionary = "none", dictionary_version = "1", unit = "word", normalization = "none"))
  profile <- ldfreq::lexdiv_family_profile(annotations, reference$dictionary,
    reference$resource, normalization = "nfkc_lower")
  # Join the frequency band by source record ID, preserving every candidate.
  candidates <- profile$candidates
  row <- match(candidates$record_id, reference$dictionary$record_id)
  candidates$headword <- reference$dictionary$headword[row]
  candidates$frequency_band <- reference$dictionary$frequency_band[row]
  list(reference = reference, profile = profile, candidates = candidates)
})
