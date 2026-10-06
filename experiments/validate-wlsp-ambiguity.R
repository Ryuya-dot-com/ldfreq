#!/usr/bin/env Rscript
# Usage: Rscript validate-wlsp-ambiguity.R bunruidb-fam.csv [installed-library]
# Separately obtained source; no external rows or ratings are bundled as fixtures.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% 1:2)
if (length(args) == 2L) .libPaths(c(args[2L], .libPaths()))
library(ldfreq)
source(system.file("examples", "wlsp-items.R", package = "ldfreq"))
path <- args[1L]
targets <- c("\u4eba\u6c17", "\u4e0a\u624b", "\u5b66\u6821", "\u672a\u767b\u9332\u306e\u4f8b\u8a9e")
inventory <- wlsp_ambiguity_candidates(c(targets, targets[1]), path)
stopifnot(identical(inventory$coverage$term, targets),
  identical(inventory$coverage$wlsp_candidate_count, c(2L, 7L, 1L, 0L)),
  identical(inventory$candidates$candidate_id[1:2], c("002375", "033333")),
  identical(inventory$resource$data_license, "CC BY-NC-SA 3.0"),
  !any(c("know", "read", "write", "speak", "listen") %in% names(inventory$candidates)))
# Independent mapping against the actual source columns, preserving character IDs.
raw <- utils::read.csv(path, fileEncoding = "UTF-8", colClasses = "character", check.names = FALSE)
rows <- match(inventory$candidates$candidate_id, raw[[1]])
stopifnot(!anyNA(rows), identical(inventory$candidates$term, raw[[13]][rows]),
  identical(inventory$candidates$reading, raw[[14]][rows]),
  identical(inventory$candidates$classification, raw[[8]][rows]),
  identical(inventory$candidates$record_type, raw[[3]][rows]))
empty <- wlsp_ambiguity_candidates(targets[4], path)
stopifnot(nrow(empty$candidates) == 0L, empty$coverage$wlsp_candidate_count == 0L)
fails <- function(expr, pattern) {
  error <- tryCatch({force(expr); NULL}, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error)))
}
for (bad in list(character(), NA_character_, "", factor("a"), 1))
  fails(wlsp_ambiguity_candidates(bad, path), "terms")
wrong <- tempfile(); writeLines("Not the inspected table", wrong)
fails(wlsp_ambiguity_candidates(targets, wrong), "differs")
unlink(wrong)

# Authored one-token segments verify the connection; they do not disambiguate context.
x <- lexdiv_import_annotations(data.frame(document_id = "ja", segment_id = paste0("s", 1:4),
  token_index = 1L, surface = targets),
  data.frame(document_id = "ja", segment_id = paste0("s", 1:4), text = targets),
  list(language = "ja", analyzer = "authored", analyzer_version = "1", dictionary = "none",
    dictionary_version = "none", unit = "authored-single-token", normalization = "none"))
review <- lexdiv_ambiguity_review(x, targets, inventory$candidates, inventory$resource)
stopifnot(identical(review$occurrences$candidate_count, c(2L, 7L, 1L, 0L)),
  identical(review$occurrences$status, c(rep("unreviewed", 3), "no_candidates")))
da <- review$occurrences[1, c("review_id", "occurrence_id")]
da$status <- "selected"; da$candidate_id <- "002375"
da$reviewer <- "A"; da$reason <- "Authored comparison, not contextual validation"
db <- da; db$candidate_id <- "033333"; db$reviewer <- "B"
a <- lexdiv_ambiguity_review(x, targets, inventory$candidates, inventory$resource, da)
b <- lexdiv_ambiguity_review(x, targets, inventory$candidates, inventory$resource, db)
z <- lexdiv_compare_ambiguity(a, b)
stopifnot(z$summary$both_selected == 1L, z$summary$disagreement == 1L,
  z$summary$both_selected_proportion == 1/4, z$summary$agreement_among_both_selected == 0,
  nrow(z$review_queue) == 4L)
p <- tempfile(); saveRDS(z, p); stopifnot(identical(readRDS(p), z)); unlink(p)
cat("WLSP: pinned local inventory, independent source columns, missingness, exact IDs, KWIC, comparison and RDS round trip OK.\n")
