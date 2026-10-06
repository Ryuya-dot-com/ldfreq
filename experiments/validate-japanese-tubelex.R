#!/usr/bin/env Rscript
# Usage: Rscript validate-japanese-tubelex.R table.tsv.xz [installed-library]
# The aggregate is acquired separately; no external rows are packaged as fixtures.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% 1:2)
if (length(args) == 2L) .libPaths(c(args[2L], .libPaths()))
source(system.file("examples", "japanese-tubelex.R", package = "ldfreq"))
path <- args[1L]
items <- data.frame(item_id = as.character(1:7), condition = c("A", "B", "A", "B", "A", "B", "A"),
  term = c("\u5b66\u6821", "\u98df\u3079\u305f", "\u5b66\u6821", "\uff23\uff21\uff34", "\u672a\u767b\u9332\u306e\u4f8b\u8a9e", "\u9752\u3044\u7a7a", " \u5b66\u6821 "),
  orth_base = c("\u5b66\u6821", "\u98df\u3079\u308b", "\u5b66\u6821", "\uff23\uff21\uff34", "\u672a\u767b\u9332\u306e\u4f8b\u8a9e", NA_character_, " \u5b66\u6821 "),
  base_reason = "Explicit test of supplied keys; not a tokenizer benchmark")
r <- profile_japanese_tubelex_items(items, path)
x <- r$items
stopifnot(identical(x[names(items)], items),
  identical(x$tubelex_status, c(rep("matched", 4), "unmatched", "unresolved_base", "unmatched")),
  identical(x$tubelex_count, c(29923, 83103, 29923, 184, NA, NA, NA)),
  identical(x$tubelex_lookup_term, c("\u5b66\u6821", "\u98df\u3079\u308b", "\u5b66\u6821", "cat", "\u672a\u767b\u9332\u306e\u4f8b\u8a9e", NA, " \u5b66\u6821 ")),
  isTRUE(all.equal(x$tubelex_per_million[1], 29923 / 165932178 * 1e6)),
  isTRUE(all.equal(x$tubelex_video_proportion[1], 9033 / 100660)),
  isTRUE(all.equal(x$tubelex_channel_proportion[1], 4381 / 30550)),
  identical(r$profile_item_ids, items$item_id[-6L]),
  all(r$profile$summary$input_units[r$profile$summary$weighting == "token"] == 6),
  all(r$profile$summary$input_units[r$profile$summary$weighting == "type"] == 5))
for (subset in list(items[FALSE, ], items[6L, ], items[c(5L, 7L), ])) {
  z <- profile_japanese_tubelex_items(subset, path)
  stopifnot(identical(z$items[names(subset)], subset), all(is.na(z$items$tubelex_count)))
}
fails <- function(expr, pattern) {
  error <- tryCatch({force(expr); NULL}, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error)))
}
bad <- items; bad$item_id[2] <- bad$item_id[1]
fails(profile_japanese_tubelex_items(bad, path), "unique")
bad <- items; bad$base_reason[1] <- " "
fails(profile_japanese_tubelex_items(bad, path), "base_reason")
bad <- items; bad$orth_base[1] <- "[TOTAL]"
fails(profile_japanese_tubelex_items(bad, path), "metadata")
fails(profile_japanese_tubelex_items(x, path), "output columns")
wrong <- tempfile(); writeLines("Not the pinned source", wrong)
fails(profile_japanese_tubelex_items(items, wrong), "differs")
unlink(wrong)
saved <- tempfile(); saveRDS(r, saved)
stopifnot(identical(r, readRDS(saved)))
unlink(saved)
cat("Japanese TUBELEX: installed helper, pinned bytes, denominators, keys, missingness, validation and RDS round trip OK.\n")
