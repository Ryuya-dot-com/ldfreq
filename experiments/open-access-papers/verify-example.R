# Run against an installed package and already obtained pinned JATS sources.
# Usage: Rscript verify-example.R SOURCE_DIRECTORY OUTPUT_DIRECTORY
# R_LIBS may select a clean installation. Nothing is downloaded here.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
library(ldfreq)
script <- system.file("examples", "open-access-papers.R", package = "ldfreq")
stopifnot(nzchar(script))
source(script)
dir.create(args[2], recursive = TRUE, showWarnings = FALSE)
paths <- file.path(args[1], paste0(c("joss.00037", "joss.00655", "joss.00774"), ".jats"))
stopifnot(all(file.copy(paths, args[2], overwrite = FALSE)))
x <- run_open_paper_example(args[2], download = FALSE)
stopifnot(all(x$metrics$results$status == "ok"),
  identical(x$sources$paragraph_count, c(7L, 10L, 14L)),
  identical(x$sources$removed_citation_count, c(9L, 20L, 14L)),
  identical(x$sources$excluded_block_count, c(1L, 0L, 3L)),
  all(is.na(x$sources$author_l1)),
  all(nzchar(x$sources$title)), all(nzchar(x$sources$authors)),
  all(x$sources$license == "CC BY 4.0"),
  identical(names(x$texts), x$sources$document_id))
for (id in names(x$prepared)) {
  terms <- x$prepared[[id]]$tokens$surface
  n <- length(terms)
  counts <- as.numeric(table(terms))
  expected <- c(ttr = length(counts) / n,
    mattr = mean(vapply(seq_len(n - 50L + 1L), function(start)
      length(unique(terms[start:(start + 49L)])) / 50, numeric(1))),
    hdd = sum(1 - choose(n - counts, 42) / choose(n, 42)) / 42)
  actual <- x$metrics$results[x$metrics$results$document_id == id, ]
  stopifnot(isTRUE(all.equal(unname(expected[actual$metric_id]), actual$value,
    tolerance = 1e-12)))
  lookup <- x$nj8$lookup[x$nj8$lookup$document_id == id, ]
  coverage <- x$nj8$coverage[x$nj8$coverage$document_id == id, ]
  stopifnot(nrow(lookup) == n, sum(lookup$matched) == coverage$matched_tokens,
    sum(!lookup$matched) == coverage$off_list_tokens,
    mean(lookup$matched) == coverage$token_coverage)
}
expected_n <- c(256, 495, 935)
expected_v <- c(131, 226, 408)
ttr <- x$metrics$results[x$metrics$results$metric_id == "ttr", ]
stopifnot(all(ttr$N == expected_n), all(ttr$V == expected_v),
  all(x$nj8$coverage$matched_tokens == c(178, 322, 584)))
again <- run_open_paper_example(args[2], download = FALSE)
stopifnot(identical(x$metrics, again$metrics), identical(x$nj8, again$nj8),
  identical(x$prepared, again$prepared), identical(x$texts, again$texts),
  identical(again, readRDS(file.path(args[2], "analysis.rds"))))
# Missing/corrupt input must fail before analysis; do not repair it silently.
empty <- tempfile("open-paper-empty-")
dir.create(empty)
missing <- tryCatch(run_open_paper_example(empty), error = conditionMessage)
stopifnot(is.character(missing), grepl("Missing source:", missing, fixed = TRUE))
writeLines("changed source", file.path(empty, "joss.00037.jats"))
corrupt <- tryCatch(run_open_paper_example(empty), error = conditionMessage)
stopifnot(is.character(corrupt), grepl("Source hash mismatch:", corrupt, fixed = TRUE))
unlink(empty, recursive = TRUE)
cat("PASS: three pinned papers; extraction boundaries; independent TTR/MATTR/HD-D;",
    "NJ8 denominators; documented values; offline replay; save/read; missing/corrupt inputs.\n")
