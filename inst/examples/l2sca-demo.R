# Authored structural examples; no learner data or parser-accuracy assessment.
library(ldfreq)
helper <- new.env(parent = globalenv())
sys.source(system.file("examples", "l2sca.R", package = "ldfreq", mustWork = TRUE), helper)
sys.source(system.file("examples", "l2sca-fixture.R", package = "ldfreq", mustWork = TRUE), helper)
fixture <- helper$l2sca_fixture()
analysis <- helper$l2sca_import(fixture$trace, fixture$documents)

# Decisions stay separate from the unchanged imported analysis.
review <- data.frame(document_id = analysis$documents$document_id,
  analysis_id = analysis$analysis_id, reviewer = "example author",
  decision = "include", reason = "Authored tree and declared matches inspected.")
review$decision[review$document_id == "manual_fragment_FRAG"] <- "withhold"
review$reason[review$document_id == "manual_fragment_FRAG"] <-
  "Illustrative reporting protocol excludes fragments."
review$decision[review$document_id %in% c("empty", "failed")] <- "not_applicable"
review$reason[review$document_id %in% c("empty", "failed")] <- "No reportable score."
stopifnot(!anyDuplicated(review$document_id),
  setequal(review$document_id, analysis$documents$document_id),
  all(review$analysis_id == analysis$analysis_id), !anyNA(review),
  all(review$decision %in% c("include", "withhold", "pending", "not_applicable")),
  all(nzchar(review$reason)), all(nzchar(review$reviewer)))

planned <- data.frame(observation_id = paste0("o", 1:12),
  writer_id = rep(paste0("w", 1:6), each = 2),
  task = rep(c("description", "narrative", "description"), each = 4),
  occasion = rep(c("t1", "t2"), 6))
submissions <- data.frame(observation_id = paste0("o", 1:11),
  document_id = analysis$documents$document_id)
stopifnot(!anyDuplicated(planned$observation_id), !anyDuplicated(submissions$observation_id),
  !anyDuplicated(submissions$document_id), all(submissions$observation_id %in% planned$observation_id),
  setequal(submissions$document_id, analysis$documents$document_id))
study_long <- planned[rep(seq_len(nrow(planned)), each = 3), ]
study_long$document_id <- submissions$document_id[match(study_long$observation_id, submissions$observation_id)]
study_long$measure <- rep(c("MLC", "MLT", "DC_C"), nrow(planned))
study_long <- merge(study_long, analysis$results,
  by = c("document_id", "measure"), all.x = TRUE, sort = FALSE)
study_long$status[is.na(study_long$document_id)] <- "not_submitted"
study_long$analysis_id <- analysis$analysis_id
index <- match(study_long$document_id, review$document_id)
study_long$review_status <- review$decision[index]
study_long$review_reason <- review$reason[index]
study_long$report_value <- ifelse(study_long$status == "computed" &
  study_long$review_status == "include", study_long$value, NA_real_)
study_long$report_status <- study_long$status
computed <- study_long$status == "computed"
study_long$report_status[computed] <- ifelse(study_long$review_status[computed] == "include",
  "reportable", "withheld_by_review")
study_long <- study_long[order(match(study_long$observation_id, planned$observation_id),
  match(study_long$measure, c("MLC", "MLT", "DC_C"))), ]
rownames(study_long) <- NULL
# Select one outcome and one analysis before a model; retain the full table.
model_data <- subset(study_long, measure == "MLT" & report_status == "reportable")
stopifnot(!anyDuplicated(model_data$observation_id), nrow(study_long) == 36L,
  nrow(model_data) == 7L, all(is.finite(model_data$report_value)))
record <- list(analysis = analysis, review = review, planned = planned,
  submissions = submissions, study_long = study_long, session = utils::sessionInfo())
helper$l2sca_validate(analysis)
