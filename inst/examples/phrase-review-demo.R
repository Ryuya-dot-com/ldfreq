# English/Japanese authored teaching example, MIT; no corpus or model download.
# These contextual judgments illustrate a declared criterion, not a gold standard.

## ---- phrase-review-prepare
library(ldfreq)
source(system.file("examples", "phrase-list-kwic.R", package = "ldfreq",
  mustWork = TRUE), local = TRUE)
phrase_segments <- data.frame(
  document_id = c("en", "en", "en_pending", "en_pending", "ja", "ja",
    "ja_pending", "ja_pending", "no_match", "empty"),
  segment_id = c("s1", "s2", "s1", "s2", "s1", "s2", "s1", "s2", "s1", "s1"),
  text = c("The plane will take off soon.", "Please take off your coat.",
    "Later they take off.", "The crew will take off at noon.",
    "\u5f7c\u306e\u5931\u8a00\u304c\u8a08\u753b\u306e\u8db3\u3092\u5f15\u3063\u5f35\u3063\u305f\u3002",
    "\u5b50\u4f9b\u304c\u4eba\u5f62\u306e\u8db3\u3092\u5f15\u3063\u5f35\u3063\u305f\u3002",
    "\u5f7c\u306f\u8db3\u3092\u5f15\u3063\u5f35\u3063\u305f\u3002",
    "\u4f1a\u8b70\u3067\u307e\u305f\u8db3\u3092\u5f15\u3063\u5f35\u3063\u305f\u3002",
    "No listed phrase occurs here.", ""))
phrase_surfaces <- list(
  c("The", "plane", "will", "take", "off", "soon", "."),
  c("Please", "take", "off", "your", "coat", "."),
  c("Later", "they", "take", "off", "."),
  c("The", "crew", "will", "take", "off", "at", "noon", "."),
  c("\u5f7c", "\u306e", "\u5931\u8a00", "\u304c", "\u8a08\u753b", "\u306e", "\u8db3", "\u3092", "\u5f15\u3063\u5f35\u3063", "\u305f", "\u3002"),
  c("\u5b50\u4f9b", "\u304c", "\u4eba\u5f62", "\u306e", "\u8db3", "\u3092", "\u5f15\u3063\u5f35\u3063", "\u305f", "\u3002"),
  c("\u5f7c", "\u306f", "\u8db3", "\u3092", "\u5f15\u3063\u5f35\u3063", "\u305f", "\u3002"),
  c("\u4f1a\u8b70", "\u3067", "\u307e\u305f", "\u8db3", "\u3092", "\u5f15\u3063\u5f35\u3063", "\u305f", "\u3002"),
  c("No", "listed", "phrase", "occurs", "here", "."), character())
phrase_tokens <- do.call(rbind, lapply(seq_along(phrase_surfaces), function(i) {
  data.frame(document_id = rep(phrase_segments$document_id[i], length(phrase_surfaces[[i]])),
    segment_id = rep(phrase_segments$segment_id[i], length(phrase_surfaces[[i]])),
    token_index = seq_along(phrase_surfaces[[i]]), surface = phrase_surfaces[[i]])
}))
phrase_annotations <- lexdiv_import_annotations(phrase_tokens, phrase_segments,
  list(language = "en+ja", analyzer = "authored", analyzer_version = "1",
    dictionary = "none", dictionary_version = "not-applicable",
    unit = "authored-tokens", normalization = "none"))
review_phrases <- list(departure = c("take", "off"),
  departure_long = c("will", "take", "off"),
  hindrance = c("\u8db3", "\u3092", "\u5f15\u3063\u5f35\u3063", "\u305f"),
  absent = c("not", "present"))
phrase_resource <- list(resource_id = "authored-phrase-review", resource_version = "1",
  source_reference = "Original teaching list, not an established phrase inventory",
  data_license = "MIT")
phrase_keep <- !phrase_annotations$tokens$surface %in% c(".", "\u3002")
phrase_search <- phrase_list_kwic(phrase_annotations, review_phrases,
  phrase_resource, keep = phrase_keep, window = 3L)
phrase_criterion <- paste("For departure/departure_long, accept departure for a flight;",
  "for hindrance, accept hindering a plan rather than physically pulling a leg.",
  "Retain nested accepted spans. Unclear context remains unresolved.")
phrase_before <- phrase_list_review(phrase_search, criterion = phrase_criterion)

## ---- phrase-review-export
phrase_review_dir <- tempfile("ldfreq-phrase-review-")
dir.create(phrase_review_dir)
saveRDS(phrase_before, file.path(phrase_review_dir, "review-before.rds"), version = 2)
write.csv(phrase_before$occurrences, file.path(phrase_review_dir, "context.csv"),
  row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")
write.csv(phrase_before$worksheet, file.path(phrase_review_dir, "decisions.csv"),
  row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")

## ---- phrase-review-decide
# Illustrative edits to the worksheet; in a study inspect context and edit the CSV.
phrase_sheet <- phrase_before$worksheet
complete_docs <- phrase_sheet$document_id %in% c("en", "ja")
phrase_sheet$status[complete_docs & phrase_sheet$segment_id == "s1"] <- "accepted"
phrase_sheet$status[complete_docs & phrase_sheet$segment_id == "s2"] <- "rejected"
pending_docs <- phrase_sheet$document_id %in% c("en_pending", "ja_pending")
phrase_sheet$status[pending_docs & phrase_sheet$segment_id == "s1"] <- "unresolved"
submitted <- phrase_sheet$status != "unreviewed"
phrase_sheet$reviewer[submitted] <- "authored-demo-reviewer"
reasons <- c(accepted = "Authored context supplies the declared target interpretation.",
  rejected = "Removing a coat or physically pulling a doll's leg is outside the criterion.",
  unresolved = "The short authored context does not settle the interpretation.")
phrase_sheet$reason[submitted] <- unname(reasons[phrase_sheet$status[submitted]])
# Reordering must never move a decision to another source occurrence.
phrase_sheet <- phrase_sheet[rev(seq_len(nrow(phrase_sheet))), ]
write.csv(phrase_sheet, file.path(phrase_review_dir, "decisions-edited.csv"),
  row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")

## ---- phrase-review-apply
phrase_reader <- new.env(parent = baseenv())
sys.source(system.file("examples", "text-file-input.R", package = "ldfreq",
  mustWork = TRUE), phrase_reader)
phrase_csv <- phrase_reader$read_text_file(
  file.path(phrase_review_dir, "decisions-edited.csv"), encoding = "UTF-8")
phrase_connection <- textConnection(phrase_csv$text, encoding = "UTF-8")
phrase_sheet_read <- read.csv(phrase_connection, colClasses = "character",
  check.names = FALSE, na.strings = "<MISSING>", encoding = "UTF-8")
close(phrase_connection)
phrase_saved <- readRDS(file.path(phrase_review_dir, "review-before.rds"))
phrase_after <- phrase_list_review(phrase_saved$source, phrase_saved$criterion,
  worksheet = phrase_sheet_read)
phrase_after$documents[c("document_id", "occurrences", "accepted", "rejected",
  "unresolved", "unreviewed", "review_complete")]
phrase_after$documents[c("document_id", "retained_tokens", "covered_tokens",
  "accepted_covered_tokens", "accepted_coverage", "reportable_accepted_coverage")]

## ---- phrase-review-save
phrase_record <- list(before = phrase_saved, after = phrase_after,
  worksheet_input = phrase_csv, session = sessionInfo())
saveRDS(phrase_record, file.path(phrase_review_dir, "analysis.rds"), version = 2)
write.csv(phrase_after$documents, file.path(phrase_review_dir, "document-results.csv"),
  row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")
write.csv(phrase_after$counts, file.path(phrase_review_dir, "phrase-counts.csv"),
  row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")
phrase_restored <- readRDS(file.path(phrase_review_dir, "analysis.rds"))
stopifnot(identical(phrase_restored, phrase_record), identical(
  phrase_list_review(phrase_restored$after$source, phrase_restored$after$criterion,
    worksheet = phrase_restored$after$worksheet), phrase_restored$after))
