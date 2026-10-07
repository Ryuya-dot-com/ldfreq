# Explicit teaching recipe, not an exported API or automatic Japanese analyzer.
# All texts, boundaries and lexical decisions here are authored under MIT.
# Requires quanteda >= 4.5.0 and a UTF-8 R session. Source from an installed package.

## ---- ja-files-read
sys.source(system.file("examples", "text-file-input.R", package = "ldfreq", mustWork = TRUE),
  envir = environment())
ja_file_dir <- system.file("examples", "text-input", "japanese-workflow",
  package = "ldfreq", mustWork = TRUE)
ja_document_ids <- c("variants", "homophones", "unlisted", "no_targets", "empty")
ja_files <- lapply(ja_document_ids, function(id)
  read_text_file(file.path(ja_file_dir, paste0(id, ".txt")), encoding = "UTF-8"))
ja_file_manifest <- cbind(document_id = ja_document_ids,
  do.call(rbind, lapply(ja_files, `[[`, "source")))
ja_file_segments <- data.frame(document_id = ja_document_ids, segment_id = "s1",
  text = vapply(ja_files, `[[`, character(1), "text"))
ja_file_annotations <- utils::read.csv(
  text = read_text_file(file.path(ja_file_dir, "annotations.csv"))$text,
  colClasses = "character", check.names = FALSE, na.strings = "<MISSING>")
ja_file_annotations$token_index <- as.numeric(ja_file_annotations$token_index)
ja_file_import <- ldfreq::lexdiv_import_annotations(ja_file_annotations, ja_file_segments,
  list(language = "ja", analyzer = "authored", analyzer_version = "2",
    dictionary = "none", dictionary_version = "not-applicable",
    unit = "authored-file-workflow", normalization = "none"))

## ---- ja-files-ranges
# One segment and one contiguous body range per document in this small recipe.
# Empty original files have NA/NA bounds. Titles remain in the complete import.
ja_body_ranges <- data.frame(document_id = ja_document_ids,
  start = c(5L, 4L, 1L, 1L, NA_integer_),
  end = c(nchar(ja_file_segments$text[1:4], type = "chars"), NA_integer_),
  reason = c("Exclude authored title line", "Exclude authored title line",
    "Entire file", "Entire file", "Empty original file"))

## ---- ja-files-scope
select_japanese_example_body <- function(imported, ranges) {
  s <- imported$segments; t <- imported$tokens
  if (anyDuplicated(s$document_id) || anyDuplicated(ranges$document_id) ||
      !setequal(s$document_id, ranges$document_id))
    stop("Supply one segment and one body-range row per document.")
  r <- ranges[match(s$document_id, ranges$document_id), ]
  width <- nchar(s$text, type = "chars")
  empty <- width == 0L
  if (!is.numeric(r$start) || !is.numeric(r$end) ||
      any(!is.na(r$start[empty]) | !is.na(r$end[empty])) ||
      anyNA(r$start[!empty]) || anyNA(r$end[!empty]) ||
      any(!is.finite(r$start[!empty]) | !is.finite(r$end[!empty])) ||
      any(r$start[!empty] != floor(r$start[!empty]) | r$end[!empty] != floor(r$end[!empty])) ||
      any(r$start[!empty] < 1 | r$end[!empty] > width[!empty] | r$start[!empty] > r$end[!empty]))
    stop("Use inclusive codepoint bounds within nonempty text, and NA/NA for empty files.")
  row <- match(t$document_id, s$document_id)
  inside <- t$start >= r$start[row] & t$end <= r$end[row]
  overlap <- t$end >= r$start[row] & t$start <= r$end[row]
  if (any(overlap & !inside))
    stop("A body range cuts through a token; review the range or complete annotation first.")
  # Explicit example policy: retain particles/verbs; exclude only the full stop.
  punctuation <- t$surface == "。"
  data.frame(t[c("document_id", "segment_id", "token_index", "start", "end", "surface")],
    in_body = inside, retained = inside & !punctuation,
    reason = ifelse(!inside, "outside_body", ifelse(punctuation, "full_stop", "retained")))
}
ja_file_selection <- select_japanese_example_body(ja_file_import, ja_body_ranges)

## ---- ja-files-review
ja_file_candidates <- data.frame(
  term = c("りんご", "リンゴ", "林檎", rep("はし", 3)),
  candidate_id = c(rep("apple", 3), "bridge", "chopsticks", "edge"),
  label = c(rep("林檎", 3), "橋", "箸", "端"))
ja_file_targets <- c("りんご", "リンゴ", "林檎", "はし", "ぷにょ語")
ja_file_resource <- list(resource_id = "authored-ja-file-candidates", resource_version = "1",
  source_reference = "ldfreq authored Japanese file workflow", data_license = "MIT")
ja_file_before <- ldfreq::lexdiv_ambiguity_review(ja_file_import, ja_file_targets,
  ja_file_candidates, ja_file_resource)
ja_file_context <- ja_file_before$occurrences
# Match by document + original token index, never by a sorted display's row number.
ja_file_key <- paste(ja_file_selection$document_id, ja_file_selection$token_index, sep = ":")
ja_file_context$in_body <- ja_file_selection$in_body[match(
  paste(ja_file_context$document_id, ja_file_context$token_index, sep = ":"), ja_file_key)]
ja_file_context[c("document_id", "surface", "pre", "post", "in_body", "status")]

# Authored demonstration decisions only. Title hits and the invented word
# remain unsubmitted. In a study, inspect context and use your own decisions.
ja_file_decisions <- ja_file_context[
  ja_file_context$in_body & ja_file_context$surface != "ぷにょ語",
  c("review_id", "occurrence_id")]
ja_file_decisions$status <- c(rep("selected", 5), "unresolved")
ja_file_decisions$candidate_id <- c(rep("apple", 3), "bridge", "chopsticks", NA_character_)
ja_file_decisions$reviewer <- "authored-example"
ja_file_decisions$reason <- c(rep("Author intends fruit", 3),
  "Author intends crossing a bridge", "Author intends eating with chopsticks",
  "Seeing context leaves the intended item unresolved")
ja_file_after <- ldfreq::lexdiv_ambiguity_review(ja_file_import, ja_file_targets,
  ja_file_candidates, ja_file_resource, decisions = ja_file_decisions)

## ---- ja-files-counts
ja_file_words <- ja_file_import$tokens[ja_file_selection$retained, ]
ja_file_sequences <- stats::setNames(lapply(ja_document_ids, function(id)
  ja_file_words$surface[ja_file_words$document_id == id]), ja_document_ids)
ja_file_metrics <- ldfreq::lexdiv_metrics_batch(ja_file_sequences, metrics = "ttr")
# Keep all documents. Target identity counts do not describe all body words.
ja_file_occurrences <- ja_file_after$occurrences
ja_file_occurrences$in_body <- ja_file_context$in_body[
  match(ja_file_occurrences$occurrence_id, ja_file_context$occurrence_id)]
ja_file_counts <- do.call(rbind, lapply(ja_document_ids, function(id) {
  o <- ja_file_occurrences[ja_file_occurrences$document_id == id & ja_file_occurrences$in_body, ]
  selected <- o$status == "selected"
  v <- length(unique(o$candidate_id[selected]))
  data.frame(document_id = id,
    source_N = sum(ja_file_import$tokens$document_id == id),
    outside_body_N = sum(ja_file_selection$document_id == id & !ja_file_selection$in_body),
    target_N = nrow(o), selected_N = sum(selected),
    unreviewed_N = sum(o$status == "unreviewed"), unresolved_N = sum(o$status == "unresolved"),
    no_candidates_N = sum(o$status == "no_candidates"),
    selection_coverage = if (nrow(o)) sum(selected) / nrow(o) else NA_real_,
    target_surface_V = length(unique(o$surface)),
    target_lexical_V = if (all(selected)) v else NA_integer_,
    common_surface_V = length(unique(o$surface[selected])), common_lexical_V = v)
}))
ja_file_record <- list(files = ja_file_manifest, imported = ja_file_import,
  body_ranges = ja_body_ranges, selection = ja_file_selection,
  before = ja_file_before, after = ja_file_after, decisions = ja_file_decisions,
  metrics = ja_file_metrics, counts = ja_file_counts,
  policy = "One original file per segment; declared body ranges; exclude literal full stops; exact authored single-token candidates",
  session = utils::sessionInfo())

## ---- ja-files-save
ja_file_output <- tempfile("japanese-file-review-")
dir.create(ja_file_output)
saveRDS(ja_file_record, file.path(ja_file_output, "analysis.rds"), version = 2)
utils::write.csv(ja_file_counts, file.path(ja_file_output, "target-counts.csv"),
  row.names = FALSE, fileEncoding = "UTF-8", na = "NA")
ja_file_restored <- readRDS(file.path(ja_file_output, "analysis.rds"))
stopifnot(identical(ja_file_restored, ja_file_record))
