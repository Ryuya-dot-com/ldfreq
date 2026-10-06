# Authored text and declared decisions. Uses bundled reference snapshots;
# these decisions illustrate accounting, not independently validated analyses.
morphology_link_example <- local({
  forms <- c("teacher", "teachers", "reusability", "reusability", "quux")
  annotations <- ldfreq::lexdiv_import_annotations(
    data.frame(document_id = "example", segment_id = "s", token_index = seq_along(forms), surface = forms),
    data.frame(document_id = c("example", "empty"), segment_id = "s", text = c(paste(forms, collapse = " "), "")),
    list(language = "en", analyzer = "authored", analyzer_version = "1", dictionary = "none",
      dictionary_version = "1", unit = "word", normalization = "none"))
  nation <- ldfreq::bnccoca_data()
  family <- ldfreq::lexdiv_family_profile(annotations, nation$dictionary, nation$resource)
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "morpholex-word-parts.R", package = "ldfreq", mustWork = TRUE), e)
  sheets <- grep("^[0-9]+-[0-9]+-[0-9]+$", names(ldfreq::morpholex_data()$sheets), value = TRUE)
  ml <- e$read_morpholex_parts(sheets = sheets, words = unique(forms))
  mn <- ldfreq::morphynet_read_derivations(system.file("extdata", "morphynet-example",
    "eng.derivational.example.tsv", package = "ldfreq", mustWork = TRUE), "en", "Nine-row teaching excerpt")
  initial <- link_morphology_candidates(family, ml, mn)
  review <- initial$reviews$morpholex
  md <- review$occurrences[review$occurrences$surface %in% c("teacher", "teachers"), c("review_id", "occurrence_id")]
  md$status <- c("selected", "unresolved")
  md$candidate_id <- c(ml$analyses$analysis_id[ml$analyses$form == "teacher"], NA_character_)
  md$reviewer <- "authored-example"
  md$reason <- c("Use the reference's recorded derivational analysis for this example",
    "Withhold selection in this example; do not infer a zero affix count")
  review <- initial$reviews$morphynet
  nd <- review$occurrences[review$occurrences$surface == "reusability", c("review_id", "occurrence_id")]
  nd$status <- c("selected", "unresolved")
  r <- mn$relations
  nd$candidate_id <- c(r$relation_id[r$target_word == "reusability" & r$source_word == "reusable" & r$morpheme == "ity"], NA_character_)
  nd$reviewer <- "authored-example"
  nd$reason <- c("Declare reusable + ity as the relation to summarize here",
    "Retain the alternative relations without choosing one")
  reviewed <- link_morphology_candidates(family, ml, mn,
    morpholex_decisions = md, morphynet_decisions = nd)
  list(initial = initial, reviewed = reviewed)
})
