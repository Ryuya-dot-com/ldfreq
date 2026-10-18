# Authored texts and hand counts, MIT licensed; no learner data or model validation.
library(ldfreq)
helper <- new.env(parent = globalenv())
sys.source(system.file("examples", "readability.R", package = "ldfreq", mustWork = TRUE), helper)
segments <- data.frame(document_id = c("d1", "d1", "d1", "d2", "d3", "d4", "d5"),
  segment_id = c("s1", "s2", "heading", rep("s1", 4)),
  text = c("The cat sat.", "The dog ran.", "A heading to exclude.",
    "A little rabbit runs.", "In 1918, R.F.D. grew.", "", "Bird."))
prepared <- helper$readability_prepare(segments, language = "en",
  sentence_policy = "authored sentence boundaries; heading explicitly excluded; fragments included",
  include = segments$segment_id != "heading")
hand <- c(The = 1, cat = 1, sat = 1, dog = 1, ran = 1, A = 1, little = 2,
  rabbit = 2, runs = 1, In = 1, grew = 1, Bird = 1)
syllables <- data.frame(source_id = rep(prepared$integrity_sha256, nrow(prepared$tokens)),
  token_row = prepared$tokens$token_row,
  syllables = unname(hand[prepared$tokens$surface]), method = "authored hand count")
initial <- helper$readability_score(prepared, syllables,
  syllable_source = "hand-counted ordinary words; figure and initialism pronunciation unresolved")
reviewed <- syllables
reviewed$review_reason <- ""
reviewed$syllables[prepared$tokens$surface == "1918"] <- 4
reviewed$syllables[prepared$tokens$surface == "R.F.D."] <- 3
reviewed$review_reason[prepared$tokens$surface == "1918"] <- "nineteen eighteen: 4 syllables"
reviewed$review_reason[prepared$tokens$surface == "R.F.D."] <- "letters R, F, D spoken separately: 3 syllables"
reviewed$method[nzchar(reviewed$review_reason)] <- "declared pronunciation"
analysis <- helper$readability_score(prepared, reviewed,
  syllable_source = "authored hand count, with explicit pronunciation decisions in review_reason")

planned <- data.frame(observation_id = paste0("o", 1:6), writer_id = rep(c("w1", "w2", "w3"), each = 2),
  task = rep(c("description", "narrative"), 3), occasion = rep(c("t1", "t2"), 3))
submissions <- data.frame(observation_id = paste0("o", 1:5), document_id = paste0("d", 1:5))
stopifnot(!anyDuplicated(planned$observation_id), !anyDuplicated(submissions$observation_id),
  !anyDuplicated(submissions$document_id), all(submissions$observation_id %in% planned$observation_id),
  setequal(submissions$document_id, analysis$components$document_id))
study_long <- planned[rep(seq_len(nrow(planned)), each = 2), ]
study_long$document_id <- submissions$document_id[match(study_long$observation_id, submissions$observation_id)]
study_long$measure <- rep(c("Flesch_Reading_Ease", "Flesch_Kincaid_Grade"), nrow(planned))
study_long <- merge(study_long, analysis$results,
  by = c("document_id", "measure"), all.x = TRUE, sort = FALSE)
study_long$status[is.na(study_long$document_id)] <- "not_submitted"
study_long$analysis_id <- analysis$analysis_id
study_long <- study_long[order(match(study_long$observation_id, planned$observation_id), study_long$measure), ]
rownames(study_long) <- NULL
record <- list(initial = initial, analysis = analysis, planned = planned,
  submissions = submissions, study_long = study_long, session = utils::sessionInfo())
helper$readability_validate(analysis)
stopifnot(identical(analysis$components$words, c(6L, 4L, 4L, 0L, 1L)),
  identical(analysis$components$sentences, c(2L, 1L, 1L, 0L, 1L)),
  identical(analysis$components$syllables, c(6, 6, 9, NA_real_, 1)), nrow(study_long) == 12L)
