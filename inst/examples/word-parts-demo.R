# Authored analyses, NOT entries copied from a licensed morphology database.
word_parts_example <- local({
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "word-parts.R", package = "ldfreq", mustWork = TRUE), e)
  segments <- data.frame(document_id = c("parts", "uncertain", "empty"), segment_id = "s",
    text = c("teachers smaller reuse transmit transmission.", "bank went quux.", ""))
  tokens <- data.frame(document_id = c(rep("parts", 6), rep("uncertain", 4)), segment_id = "s",
    token_index = c(1:6, 1:4), surface = c("teachers", "smaller", "reuse", "transmit",
      "transmission", ".", "bank", "went", "quux", "."),
    upos = c("NOUN", "ADJ", "VERB", "VERB", "NOUN", "PUNCT", "NOUN", "VERB", "X", "PUNCT"))
  annotations <- ldfreq::lexdiv_import_annotations(tokens, segments,
    list(language = "en", analyzer = "authored", analyzer_version = "1",
      dictionary = "authored", dictionary_version = "1", unit = "word", normalization = "none"))
  analyses <- data.frame(analysis_id = c("01", "02", "03", "04", "05", "b1", "b2", "w1"),
    form = c("teachers", "smaller", "reuse", "transmit", "transmission", "bank", "bank", "went"),
    completeness = c(rep("complete", 7), "unanalysed"))
  parts <- data.frame(analysis_id = c(rep("01", 3), rep("02", 2), rep("03", 2),
      rep("04", 2), rep("05", 3), "b1", "b2"),
    part_index = c(1:3, 1:2, 1:2, 1:2, 1:3, 1, 1),
    part_id = c("TEACH", "ER_AGENT", "S_PL", "SMALL", "ER_COMP", "RE_AGAIN", "USE",
      "TRANS", "MIT_MISS", "TRANS", "MIT_MISS", "ION", "BANK_FINANCE", "BANK_RIVER"),
    canonical = c("teach", "er", "s", "small", "er", "re", "use", "trans", "mit", "trans", "mit",
      "ion", "bank", "bank"),
    role = c("root", "suffix", "suffix", "root", "suffix", "prefix", "root", "prefix", "root",
      "prefix", "root", "suffix", "root", "root"),
    process = c("none", "derivation", "inflection", "none", "inflection", "derivation", "none",
      "derivation", "none", "derivation", "none", "derivation", "none", "none"),
    boundness = c("free", "bound", "bound", "free", "bound", "bound", "free", "bound", "bound",
      "bound", "bound", "bound", "free", "free"),
    realization = c("teach", "er", "s", "small", "er", "re", "use", "trans", "mit", "trans", "miss",
      "ion", "bank", "bank"))
  resource <- list(resource_id = "authored-word-parts", resource_version = "1", language = "en",
    source_reference = "ldfreq word-parts-demo.R: authored accounting examples",
    data_license = "MIT", analysis_scope = "Listed roots and overt derivational/inflectional affixes",
    analysis_basis = "Illustrative choices, including mit/miss grouping; not a validated inventory")
  profile <- e$word_parts_profile(annotations, analyses, parts, resource, exclude_pos = "PUNCT")
  # A second explicitly declared analysis keeps transmit whole. Do not overwrite
  # the first one or label either authored choice as a MorphoLex import.
  other_parts <- parts[!(parts$analysis_id == "04" & parts$role == "prefix"), ]
  i <- which(other_parts$analysis_id == "04")
  other_parts$part_index[i] <- 1L
  other_parts$part_id[i] <- "TRANSMIT"
  other_parts$canonical[i] <- other_parts$realization[i] <- "transmit"
  other_parts$boundness[i] <- "free"
  other_resource <- resource
  other_resource$resource_id <- "authored-whole-transmit"
  other_resource$analysis_basis <- "Illustrative alternative treating transmit as an undivided root"
  alternative <- e$word_parts_profile(annotations, analyses, other_parts, other_resource, exclude_pos = "PUNCT")
  list(profile = profile, alternative = alternative)
})
