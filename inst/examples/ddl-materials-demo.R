# Authored English/Japanese materials, MIT; no external corpus or model download.
library(ldfreq)
helper <- new.env(parent = globalenv())
sys.source(system.file("examples", "ddl-materials.R", package = "ldfreq",
  mustWork = TRUE), helper)
example <- new.env(parent = globalenv())
sys.source(system.file("examples", "phrase-review-demo.R", package = "ldfreq",
  mustWork = TRUE), example)
# Teaching selection is a new criterion, separate from the earlier sense review.
# Include enough context to compare the actor and object in the Japanese examples.
search <- helper$phrase_list_kwic(example$phrase_annotations, example$review_phrases,
  example$phrase_resource, keep = example$phrase_keep, window = 8L)
before <- helper$phrase_list_review(search,
  criterion = paste("Select clear contrasting contexts for classroom observation.",
    "Uncertain and unexamined examples remain pending; rejection is not an error label."))
decisions <- before$worksheet
chosen <- decisions$document_id %in% c("en", "ja")
decisions$status[chosen] <- "accepted"
uncertain <- decisions$document_id %in% c("en_pending", "ja_pending") &
  decisions$segment_id == "s1"
decisions$status[uncertain] <- "unresolved"
decisions$reviewer[chosen | uncertain] <- "authored-demo-teacher"
decisions$reason[chosen] <- "A clear authored example for comparing two interpretations."
decisions$reason[uncertain] <- "Insufficient context; do not distribute this candidate."
review <- helper$phrase_list_review(before$source, before$criterion, decisions)
activities <- list(
  en = data.frame(activity_id = "observe",
    prompt = paste("1. Compare the uses of the highlighted expression.",
      "2. Group the examples and underline the context supporting each interpretation.",
      "3. Explain your proposed distinction and check another example.",
      "4. Write your own example and explain the intended meaning.", sep = "\n"),
    teacher_note = "Teacher only: contrast a flight's departure with removing clothing."),
  ja = data.frame(activity_id = "observe",
    prompt = paste(
      "1. \u592a\u5b57\u306e\u8868\u73fe\u306e\u4f7f\u3044\u65b9\u3092\u6bd4\u3079\u307e\u3057\u3087\u3046\u3002",
      "2. \u610f\u5473\u3054\u3068\u306b\u5206\u3051\u3001\u5224\u65ad\u306e\u6839\u62e0\u306b\u7dda\u3092\u5f15\u304d\u307e\u3057\u3087\u3046\u3002",
      "3. \u5171\u901a\u70b9\u3068\u9055\u3044\u3092\u8aac\u660e\u3057\u3001\u5225\u306e\u4f8b\u3067\u78ba\u304b\u3081\u307e\u3057\u3087\u3046\u3002",
      "4. \u81ea\u5206\u306e\u4f8b\u6587\u3092\u4f5c\u308a\u3001\u610f\u5473\u3092\u8aac\u660e\u3057\u307e\u3057\u3087\u3046\u3002", sep = "\n"),
    teacher_note = "Teacher only: compare obstructing a plan with physically pulling a leg.")
)
materials <- lapply(c("en", "ja"), function(language) {
  hits <- subset(review$occurrences, document_id == language &
    phrase_id %in% c("departure", "hindrance"))
  items <- data.frame(occurrence_id = rev(hits$occurrence_id), activity_id = "observe")
  sources <- unique(hits[c("document_id", "segment_id")])
  sources$citation <- paste("ldfreq authored example:", sources$document_id, sources$segment_id)
  sources$usage <- "MIT. Authored teaching examples; not observed corpus evidence."
  helper$ddl_material(review, activities[[language]], items, sources,
    title = if (language == "ja") "\u7528\u4f8b\u304b\u3089\u8868\u73fe\u3092\u8003\u3048\u308b" else
      "Explore expressions through examples", language = language)
})
names(materials) <- c("en", "ja")
stopifnot(all(vapply(materials, function(x) nrow(x$selected) == 2L, logical(1))),
  any(review$occurrences$status == "unreviewed"),
  any(review$occurrences$status == "unresolved"))
