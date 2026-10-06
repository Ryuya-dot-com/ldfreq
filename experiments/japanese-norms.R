# Repository runner for the public, local-file example. Run from package root:
# Rscript experiments/japanese-norms.R data_AoA.csv data_boi.csv NEW_OUTPUT_DIR
# For independent use of either resource, see vignette("japanese-norms").
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop("Usage: japanese-norms.R data_AoA.csv data_boi.csv NEW_OUTPUT_DIR")
}
if (file.exists(args[3L])) stop("Choose a new output directory.")
source(file.path("inst", "examples", "japanese-norms.R"))
items <- data.frame(item_id = paste0("example_", 1:5),
  condition = c("A", "A", "B", "B", "B"),
  term = c("学校", "研究", "学校", "辞書", "未登録の例語"))
aoa <- profile_japanese_norm_items(items, args[1L], "aoa")
boi <- profile_japanese_norm_items(items, args[2L], "boi")
index <- match(aoa$items$item_id, boi$items$item_id)
stopifnot(!anyNA(index))
combined <- aoa$items
combined$boi_mean <- boi$items$norm_mean[index]
combined$boi_value_status <- boi$items$norm_value_status[index]
result <- list(aoa = aoa, boi = boi, combined = combined, session = sessionInfo())
summary <- rbind(aoa$profile$summary, boi$profile$summary)
if (!dir.create(args[3L], recursive = TRUE)) stop("Cannot create output directory.")
saveRDS(result, file.path(args[3L], "profiles.rds"))
write.csv(combined, file.path(args[3L], "items.csv"), row.names = FALSE,
  fileEncoding = "UTF-8")
write.csv(summary, file.path(args[3L], "summary.csv"), row.names = FALSE,
  fileEncoding = "UTF-8")
print(summary[, c("measure_id", "weighting", "estimate", "resource_coverage",
  "value_coverage", "annotation_coverage")], row.names = FALSE)
# The MIT code license does not relicense imported ratings or output extracts.
