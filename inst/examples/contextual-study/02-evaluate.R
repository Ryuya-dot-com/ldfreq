# Run after 01-prepare.R, in the same study directory, in any R session.
library(ldfreq)
if (dir.exists("analysis")) stop("analysis already exists; keep it and start a new study run.")
design <- readRDS("inputs/design.rds")
metadata <- read.csv("inputs/metadata.csv", colClasses = "character", fileEncoding = "UTF-8")
required <- c("document_id", "partition", "group_id", "language")
if (!all(required %in% names(metadata)) || !nrow(metadata) ||
    anyNA(metadata[required]) || any(!nzchar(trimws(as.matrix(metadata[required])))) ||
    anyDuplicated(metadata$document_id) ||
    !setequal(metadata$partition, c("train", "development", "test")))
  stop("metadata needs unique documents, nonblank fields and all three partitions.")
if (any(vapply(split(metadata$partition, metadata$group_id),
    function(x) length(unique(x)) != 1L, logical(1))))
  stop("A group occurs in more than one partition; fix the study split before evaluation.")

models <- lapply(c("train", "development", "test"), function(part) {
  x <- readRDS(paste0("inputs/", part, "-model.rds"))
  if (!setequal(x$review$source$segments$document_id,
      metadata$document_id[metadata$partition == part]))
    stop("Model documents do not match the metadata partition: ", part)
  x
})
names(models) <- c("train", "development", "test")
contexts <- do.call(rbind, lapply(names(models), function(part)
  data.frame(text = models[[part]]$occurrences$segment_text,
    partition = rep(part, nrow(models[[part]]$occurrences)))))
if (any(vapply(split(contexts$partition, contexts$text),
    function(x) length(unique(x)) != 1L, logical(1))))
  stop("Identical target contexts occur in more than one partition.")
train_reference <- readRDS("inputs/train-reference.rds")$reference
dev_reference <- readRDS("inputs/development-reference.rds")$reference

# Decide model/layer/rules using development data only. This authored example
# fixes one rule in advance; it does not estimate an optimal threshold.
settings <- list(direction = "higher", tie_tolerance = 0,
  training_info = list(training_id = "authored-training",
    annotation_protocol = design$annotation_protocol,
    partition_protocol = "Declared disjoint document and artificial group IDs",
    model_exposure = "unknown"))
reference_info <- list(reference_id = "authored-reference",
  annotation_protocol = design$annotation_protocol, model_exposure = "unknown",
  evaluation_role = "development")
dev_scores <- lexdiv_score_contextual(models$development, models$train, train_reference,
  training_info = settings$training_info)
dev_evaluations <- lapply(dev_scores[c("centroid", "frequency")], function(x)
  lexdiv_evaluate_contextual(x, dev_reference, settings$direction,
    reference_info, settings$tie_tolerance))

# This saves the entire training input and chosen settings before test scoring.
# Files are not an access-control system or a guarantee of independence.
frozen <- list(settings = settings, design = design, metadata = metadata,
  training = models$train, training_reference = train_reference,
  session = sessionInfo())
if (!dir.create("analysis")) stop("Could not create a new analysis directory.")
saveRDS(list(scores = dev_scores, evaluations = dev_evaluations), "analysis/development.rds")
saveRDS(frozen, "analysis/frozen.rds")
frozen <- readRDS("analysis/frozen.rds")
test_scores <- lexdiv_score_contextual(models$test, frozen$training,
  frozen$training_reference, training_info = frozen$settings$training_info)
saveRDS(test_scores, "analysis/test-scores.rds")

# Read the test reference only after the test scores have been written.
# It remains "unknown": authored examples are not an independent held-out study.
test_reference <- readRDS("inputs/test-reference.rds")
reference_info$evaluation_role <- "unknown"
evaluations <- lapply(test_scores[c("centroid", "frequency")], function(x)
  lexdiv_evaluate_contextual(x, test_reference$reference, frozen$settings$direction,
    reference_info, frozen$settings$tie_tolerance))
judgments <- lexdiv_compare_ambiguity(test_reference$judge_a, test_reference$judge_b)
saveRDS(list(evaluations = evaluations, judgments = judgments,
  reference = test_reference, reference_info = reference_info), "analysis/test-evaluation.rds")
message("Development, frozen settings, test scores and evaluations saved separately.")
