#!/usr/bin/env Rscript
# Usage: Rscript validate-wlsp-polysemy.R polysemous.txt [installed-library]
# No external source rows or ratings are bundled as fixtures.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% 1:2)
if (length(args) == 2L) .libPaths(c(args[2L], .libPaths()))
library(ldfreq)
source(system.file("examples", "wlsp-polysemy.R", package = "ldfreq"))
path <- args[1L]
ref <- read_wlsp_polysemy(path)
# An independent all-character read checks original keys and numeric cells.
raw <- utils::read.delim(path, encoding = "UTF-8", quote = "", comment.char = "",
  colClasses = "character", check.names = FALSE)
stopifnot(nrow(raw) == 100827L, identical(ref$data[1:4], raw[1:4]),
  identical(ref$data$VALUE, as.numeric(raw$VALUE)), any(ref$data$VALUE < 0),
  all(is.na(ref$measure_specs[c("valid_min", "valid_max")])),
  ref$resource$data_license == "CC BY-NC-SA 3.0")
words <- raw$WORD[match(c("92892", "63221", "86619", "55980"), raw$WID)]
stopifnot(!anyNA(words))
items <- data.frame(item_id = paste0("item_", 1:8), condition = rep(c("A", "B"), 4),
  term = c("\u4eba\u6c17", "\u4eba\u6c17", "\u72ac", "\u72ac", "\u5b66\u6821",
    "unmatched", "unresolved", "\u4eba\u6c17"),
  norm_word = c(words[1:3], words[3:4], "deliberately absent source WORD", NA, words[1]),
  mapping_reason = "Authored software check; no contextual validity claim")
initial <- review_wlsp_polysemy_items(items, path)
stopifnot(identical(initial$items[names(items)], items),
  identical(initial$items$polysemy_candidate_count, c(1L, 1L, 2L, 2L, 1L, 0L, 0L, 1L)),
  identical(initial$items$polysemy_status, c(rep("unreviewed", 5), "unmatched", "unresolved_key", "unreviewed")),
  all(is.na(initial$items$polysemy_value)), initial$coverage$with_candidates == 6L,
  initial$coverage$selected == 0L)
decisions <- data.frame(item_id = items$item_id[c(1:4, 8)],
  wid = c("92892", "63221", "86619", "1739", "92892"),
  reason = "Explicit authored correspondence, not validated experimental items")
z <- review_wlsp_polysemy_items(items, path, decisions[5:1, ])
selected <- c(1:4, 8)
expected <- as.numeric(raw$VALUE[match(decisions$wid, raw$WID)])
stopifnot(identical(z$items[names(items)], items),
  identical(z$items$polysemy_wid[selected], decisions$wid),
  identical(z$items$polysemy_value[selected], expected),
  identical(z$profile_item_ids, decisions$item_id),
  all(is.na(z$items$polysemy_value[5:7])), z$coverage$selected == 5L,
  z$coverage$selection_coverage == 5/8, z$coverage$value_coverage == 5/8,
  isTRUE(all.equal(z$profile$summary$estimate,
    c(mean(expected), mean(expected[!duplicated(decisions$wid)])))),
  identical(z$profile$summary$input_units, c(5, 4)))
for (subset in list(items[FALSE, ], items[6, , drop = FALSE], items[7, , drop = FALSE])) {
  r <- review_wlsp_polysemy_items(subset, path)
  stopifnot(identical(r$items[names(subset)], subset), nrow(r$candidates) == 0L,
    is.character(r$items$polysemy_status), r$profile$status == "empty",
    all(is.na(r$items$polysemy_value)))
  if (!nrow(subset)) stopifnot(is.na(r$coverage$value_coverage))
}
fails <- function(expr, pattern) {
  error <- tryCatch({force(expr); NULL}, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error)))
}
bad <- decisions; bad$wid[1] <- "033333"
fails(review_wlsp_polysemy_items(items, path, bad), "WID")
bad$wid[1] <- "33333"
fails(review_wlsp_polysemy_items(items, path, bad), "norm_word")
bad <- decisions; bad$wid[1] <- "86619"
fails(review_wlsp_polysemy_items(items, path, bad), "norm_word")
bad <- decisions; bad$item_id[1] <- items$item_id[7]
fails(review_wlsp_polysemy_items(items, path, bad), "norm_word")
bad <- decisions; bad$item_id[1] <- bad$item_id[2]
fails(review_wlsp_polysemy_items(items, path, bad), "unique")
bad <- decisions; bad$wid <- as.integer(bad$wid)
fails(review_wlsp_polysemy_items(items, path, bad), "plain")
bad <- items; bad$item_id[2] <- bad$item_id[1]
fails(review_wlsp_polysemy_items(bad, path), "unique")
bad <- items; bad$mapping_reason[1] <- "\u3000"
fails(review_wlsp_polysemy_items(bad, path), "mapping_reason")
fails(review_wlsp_polysemy_items(z$items, path), "output columns")
bad <- items; bad$norm_word[1] <- paste0(" ", words[1])
stopifnot(review_wlsp_polysemy_items(bad, path)$items$polysemy_status[1] == "unmatched")
wrong <- tempfile(); writeLines("Not the pinned file", wrong)
fails(read_wlsp_polysemy(wrong), "differs"); unlink(wrong)

# Reuse the existing KWIC review with explicitly mapped source WIDs as candidates.
x <- lexdiv_import_annotations(data.frame(document_id = "d", segment_id = c("s1", "s2"),
  token_index = 1L, surface = items$term[1:2]),
  data.frame(document_id = "d", segment_id = c("s1", "s2"), text = items$term[1:2]),
  list(language = "ja", analyzer = "authored", analyzer_version = "1", dictionary = "none",
    dictionary_version = "none", unit = "authored-single-token", normalization = "none"))
idx <- match(decisions$wid[1:2], ref$data$WID)
candidates <- data.frame(term = items$term[1:2], candidate_id = ref$data$WID[idx],
  label = ref$data$WORD[idx], classification = ref$data$LABEL[idx])
kw <- lexdiv_ambiguity_review(x, unique(items$term[1:2]), candidates, ref$resource)
choices <- kw$occurrences[c("review_id", "occurrence_id")]
choices$status <- "selected"; choices$candidate_id <- decisions$wid[1:2]
choices$reviewer <- "software-test"; choices$reason <- "Authored integration, not sense validation"
kw <- lexdiv_ambiguity_review(x, unique(items$term[1:2]), candidates, ref$resource, choices)
occurrence_items <- data.frame(item_id = kw$occurrences$occurrence_id, term = kw$occurrences$surface,
  norm_word = ref$data$WORD[match(kw$occurrences$candidate_id, ref$data$WID)],
  mapping_reason = kw$occurrences$reason)
kd <- data.frame(item_id = occurrence_items$item_id, wid = kw$occurrences$candidate_id,
  reason = kw$occurrences$reason)
joined <- review_wlsp_polysemy_items(occurrence_items, path, kd)
stopifnot(identical(joined$items$polysemy_wid, kw$occurrences$candidate_id),
  identical(joined$items$polysemy_value, expected[1:2]))
bundle <- list(items = z, kwic = kw, joined = joined, reference = ref)
p <- tempfile(); saveRDS(bundle, p); stopifnot(identical(readRDS(p), bundle)); unlink(p)
cat("WLSP polysemy: original source columns, signed estimates, explicit keys and choices, full-item coverage, independent means, KWIC and RDS replay OK.\n")
