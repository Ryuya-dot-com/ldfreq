# Complete offline teaching example; numbers and keys are authored, not TUBELEX.
sys.source(system.file("examples", "japanese-document-profile-demo.R", package = "ldfreq", mustWork = TRUE),
  envir = environment())

## ---- ja-frequency-load
sys.source(system.file("examples", "japanese-frequency-documents.R", package = "ldfreq", mustWork = TRUE),
  envir = environment())

## ---- ja-frequency-keys
ja_frequency_keys <- ja_profile$tokens[c("document_id", "segment_id", "token_index", "start", "end", "surface")]
ja_frequency_keys$lookup_term <- ja_frequency_keys$surface
ja_frequency_keys$key_reason <- "Author-specified surface key for this teaching table"
# Apply existing authored decisions only at their original source spans.
for (i in seq_len(nrow(ja_file_after$occurrences))) {
  o <- ja_file_after$occurrences[i, ]
  row <- which(ja_frequency_keys$document_id == o$document_id &
    ja_frequency_keys$segment_id == o$segment_id &
    ja_frequency_keys$start == o$start & ja_frequency_keys$end == o$end)
  if (o$status == "selected") {
    ja_frequency_keys$lookup_term[row] <- ja_file_candidates$label[
      match(o$candidate_id, ja_file_candidates$candidate_id)]
    ja_frequency_keys$key_reason[row] <- "Explicit authored lexical decision and table-specific key"
  } else if (o$surface == "はし") {
    ja_frequency_keys$lookup_term[row] <- NA_character_
    ja_frequency_keys$key_reason[row] <- "No selected lexical candidate; key left unresolved"
  }
}

## ---- ja-frequency-reference
# Fictional values, including one observed zero and one missing annotation.
ja_demo_norms <- data.frame(word = c("林檎", "と", "を", "橋", "箸", "で", "渡る", "食べる", "見る"),
  per_million = c(10, 1000, 500, 2, 3, 200, 40, 60, 0),
  video_proportion = c(.1, .9, .8, .01, .02, .7, .2, .3, 0),
  channel_proportion = c(.2, .95, .9, .02, .03, .8, .3, .4, NA_real_))
ja_demo_measures <- names(ja_demo_norms)[-1]
ja_demo_specs <- data.frame(measure_id = ja_demo_measures, value_column = ja_demo_measures,
  construct_id = c("corpus_frequency", "video_range", "channel_range"),
  value_unit = c("occurrences_per_million_tokens", "proportion_of_videos", "proportion_of_channels"),
  direction = "descriptive", language = "Japanese", variety = "authored_example",
  population_id = "authored_demo", collection_year = "not_observed",
  valid_min = 0, valid_max = c(1e6, 1, 1))
ja_demo_resource <- list(resource_id = "authored_japanese_frequency", resource_version = "1",
  creator = "ldfreq authors", source_reference = "Fictional teaching values, not corpus estimates",
  data_license = "MIT", transformation_id = "none",
  lookup_unit = "authored_keys_with_explicit_lexical_decisions",
  resource_key_normalization_id = "identity")
ja_demo_reference <- list(norms = ja_demo_norms, key = "word", measure_specs = ja_demo_specs,
  resource = ja_demo_resource)
ja_frequency <- japanese_frequency_documents(ja_profile, ja_frequency_keys, ja_demo_reference)

## ---- ja-frequency-compare
# A second selection policy on unchanged text and unchanged lookup keys.
ja_content_selection <- ja_profile$selection
ja_content_keep <- !is.na(ja_profile$tokens$pos_group) & ja_profile$tokens$pos_group == "content"
ja_content_selection$reason[ja_content_selection$retained & !ja_content_keep] <- "outside_declared_content_group"
ja_content_selection$retained <- ja_content_selection$retained & ja_content_keep
ja_content_profile <- japanese_document_profile(ja_profile$imported, ja_content_selection,
  ja_pos_groups, condition = "authored-content-group")
ja_content_frequency <- japanese_frequency_documents(ja_content_profile, ja_frequency_keys, ja_demo_reference)
ja_frequency_comparison <- common_japanese_frequency(list(body = ja_frequency, content = ja_content_frequency))

## ---- ja-frequency-save
ja_frequency_record <- list(comparison = ja_frequency_comparison, review = ja_profile_record)
saveRDS(ja_frequency_record, file.path(ja_file_output, "frequency-analysis.rds"), version = 2)
utils::write.csv(ja_frequency$documents, file.path(ja_file_output, "frequency-documents.csv"),
  row.names = FALSE, fileEncoding = "UTF-8", na = "NA")
utils::write.csv(ja_frequency$norms$summary, file.path(ja_file_output, "frequency-summary.csv"),
  row.names = FALSE, fileEncoding = "UTF-8", na = "NA")
utils::write.csv(ja_frequency$occurrences, file.path(ja_file_output, "frequency-occurrences.csv"),
  row.names = FALSE, fileEncoding = "UTF-8", na = "NA")

## ---- ja-frequency-replay
ja_frequency_saved <- readRDS(file.path(ja_file_output, "frequency-analysis.rds"))
ja_frequency_inputs <- ja_frequency_saved$comparison$all
ja_frequency_replayed <- lapply(ja_frequency_inputs, function(x)
  japanese_frequency_documents(x$source_profile, x$keys, x$reference))
stopifnot(identical(ja_frequency_replayed, ja_frequency_inputs),
  identical(common_japanese_frequency(ja_frequency_replayed), ja_frequency_saved$comparison))
