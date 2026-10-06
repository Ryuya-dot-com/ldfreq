# Read-only replay: no models, inference, CSV edits or live input files are used.
library(ldfreq)
frozen <- readRDS("analysis/frozen.rds")
scores <- readRDS("analysis/test-scores.rds")
saved <- readRDS("analysis/test-evaluation.rds")
evaluations <- lapply(scores[c("centroid", "frequency")], function(x)
  lexdiv_evaluate_contextual(x, saved$reference$reference, frozen$settings$direction,
    saved$reference_info, frozen$settings$tie_tolerance))
stopifnot(identical(evaluations, saved$evaluations))

comparison <- do.call(rbind, lapply(names(evaluations), function(method)
  cbind(method = method, evaluations[[method]]$summary)))
rownames(comparison) <- NULL
left <- evaluations$centroid$pairs
right <- evaluations$frequency$pairs
row <- match(left$occurrence_id, right$occurrence_id)
stopifnot(!anyNA(row), !anyDuplicated(row), length(row) == nrow(right))
right <- right[row, ]
stopifnot(identical(left$reference_candidate_id, right$reference_candidate_id),
  identical(left$reference_status, right$reference_status))
common <- !is.na(left$matches_reference) & !is.na(right$matches_reference)
common_occurrences <- left[common, c("occurrence_id", "document_id", "surface",
  "reference_candidate_id", "pre", "keyword", "post")]
common_occurrences$centroid_matches <- left$matches_reference[common]
common_occurrences$frequency_matches <- right$matches_reference[common]
common_comparison <- data.frame(method = c("centroid", "frequency"),
  paired = sum(common), agreement = c(sum(left$matches_reference[common]),
    sum(right$matches_reference[common])))
common_comparison$agreement_among_paired <- if (sum(common))
  common_comparison$agreement / sum(common) else NA_real_
common_comparison$coverage_of_all_occurrences <- if (nrow(left)) sum(common) / nrow(left) else NA_real_

# Keep the comparison population visible: each row still has both KWIC context
# and document metadata. This example has too few observations for inference.
pairs <- do.call(rbind, lapply(names(evaluations), function(method) {
  p <- evaluations[[method]]$pairs
  at <- match(p$document_id, frozen$metadata$document_id)
  stopifnot(!anyNA(at))
  cbind(method = rep(method, nrow(p)), p,
    frozen$metadata[at, c("group_id", "language"), drop = FALSE])
}))
report <- list(purpose = frozen$design$purpose, comparison = comparison,
  common_comparison = common_comparison, common_occurrences = common_occurrences,
  pairs = pairs, terms = lapply(evaluations, function(x) x$terms),
  review_queue = lapply(evaluations, function(x) x$review_queue),
  judgments = saved$judgments)
print(comparison[c("method", "occurrences", "predictions", "paired", "agreement",
  "prediction_coverage", "agreement_among_paired", "matches_among_reference_selected")])
print(common_comparison)
message("Replayed saved judgments and scores. Values are authored, not empirical accuracy.")
# Optional local export after inspecting the report:
# write.csv(report$comparison, "comparison.csv", row.names = FALSE)
# saveRDS(report, "report.rds")
