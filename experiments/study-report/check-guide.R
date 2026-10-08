# Run the actual guide chunks on the published installation; no package dependency.
# Usage: Rscript --vanilla experiments/study-report/check-guide.R REPO OUTPUT
args <- commandArgs(trailingOnly = TRUE)
repo <- normalizePath(if (length(args)) args[1] else ".", mustWork = TRUE)
output <- if (length(args) > 1L) args[2] else tempfile("study-report-check-")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
stopifnot(utils::packageVersion("ldfreq") >= "0.3.0.9003")
library(ldfreq)
guide <- readLines(file.path(repo, "vignettes", "from-text-to-report.Rmd"), encoding = "UTF-8")
chunk <- function(label) {
  start <- grep(paste0("^```\\{r ", label, "[,}]"), guide)
  stopifnot(length(start) == 1L)
  end <- which(seq_along(guide) > start & guide == "```")[1]
  parse(text = guide[seq.int(start + 1L, end - 1L)])
}
run <- function(labels, env) for (label in labels) invisible(eval(chunk(label), env))
e <- new.env()
run(c("report-file-setup", "report-english-files", "report-english-pairs",
  "report-english-record", "report-study-join-function", "report-study-english-metadata",
  "report-study-table", "report-study-reference", "report-study-summary-function",
  "report-study-save"), e)
s <- e$study_summary
stopifnot(nrow(e$study_table) == 186L, nrow(s) == 6L,
  all(s$n_documents == 31L), all(s$n_writers_known == 10L),
  all(s$n_reported == 30L), all(s$n_unavailable == 1L), all(s$n_withheld == 0L),
  all(s$n_unknown_writer_documents == 0L), all(s$n_reported_writers_known == 10L),
  identical(e$study_table$document_id, e$en_table$document_id),
  identical(e$study_table$value, e$en_table$value),
  nrow(e$study_coverage) == 62L,
  all(is.na(e$study_table$nj8_token_coverage[e$study_table$document_id == "031"])))
# Check reference denominators against selected sequences, independent of the table join.
for (condition in names(e$study_references)) {
  profile <- e$study_references[[condition]]
  for (id in names(e$en_inputs[[condition]])) {
    row <- profile$coverage[profile$coverage$document_id == id, ]
    stopifnot(row$eligible_tokens == length(e$en_inputs[[condition]][[id]]))
  }
}
check_saved <- function(env) {
  restored <- readRDS(file.path(env$study_output, "study.rds"))
  stopifnot(identical(restored, env$study_record))
  csv <- read.csv(file.path(env$study_output, "document-results.csv"),
    colClasses = c(document_id = "character", writer_id = "character", task = "character"),
    na.strings = "<MISSING>", encoding = "UTF-8")
  stopifnot(identical(csv$document_id, env$study_table$document_id),
    identical(csv$writer_id, env$study_table$writer_id),
    identical(csv$task, env$study_table$task),
    identical(is.na(csv$reportable_value), is.na(env$study_table$reportable_value)))
  joined <- env$join_study_metadata(env$study_rows, restored$study$metadata)
  stopifnot(identical(joined, restored$study$table[names(joined)]))
  replayed <- lapply(restored$inputs, function(tokens)
    do.call(lexdiv_metrics_batch, c(list(tokens), restored$settings)))
  stopifnot(identical(replayed, restored$results))
  invisible(TRUE)
}
check_saved(e)
file.copy(file.path(e$study_output, "study.rds"), file.path(output, "english-study.rds"), overwrite = TRUE)
english <- list(table = e$study_table, summary = s, coverage = e$study_coverage)
# The Japanese route can start independently after the common setup.
j <- new.env()
run(c("report-file-setup", "report-japanese-files", "report-japanese-selection",
  "report-japanese-metrics", "report-japanese-record", "report-study-join-function",
  "report-study-japanese-metadata", "report-study-table", "report-study-reference",
  "report-study-summary-function", "report-study-save"), j)
s <- j$study_summary
stopifnot(nrow(j$study_table) == 30L, nrow(s) == 18L,
  is.null(j$study_references), is.null(j$study_coverage),
  !"nj8_token_coverage" %in% names(j$study_table),
  identical(j$study_table$value, j$ja_table$value),
  identical(j$study_table$reportable_value, j$ja_table$reportable_value))
unknown <- s[is.na(s$task), ]
stopifnot(nrow(unknown) == 6L, all(unknown$n_writers_known == 0L),
  all(unknown$n_unknown_writer_documents == 1L),
  unknown$n_unavailable[unknown$condition == "content" & unknown$metric_id == "ttr"] == 1L,
  unknown$n_withheld[unknown$condition == "content" & unknown$metric_id == "ttr"] == 0L,
  unknown$n_selection_incomplete[unknown$condition == "content" & unknown$metric_id == "ttr"] == 1L,
  unknown$n_reported[unknown$condition == "all_body" & unknown$metric_id == "ttr"] == 1L)
empty <- s[!is.na(s$task) & s$task == "zero-input", ]
stopifnot(nrow(empty) == 6L, all(empty$n_documents == 2L),
  all(empty$n_reported == 0L), all(is.na(empty$mean)), all(is.na(empty$sd)),
  all(is.na(empty$median)), all(s$n_reported[s$metric_id == "mattr"] == 0L),
  all(is.na(s$sd[s$n_reported < 2L])))
check_saved(j)
file.copy(file.path(j$study_output, "study.rds"), file.path(output, "japanese-study.rds"), overwrite = TRUE)
expect_error <- function(expr) {
  error <- tryCatch({force(expr); NULL}, error = identity)
  stopifnot(inherits(error, "error"))
  conditionMessage(error)
}
join <- e$join_study_metadata; rows <- e$study_rows; meta <- e$study_metadata
bad <- meta; bad$document_id <- as.numeric(bad$document_id)
rejections <- c(numeric_ids = expect_error(join(rows, bad)),
  duplicate_metadata = expect_error(join(rows, rbind(meta, meta[1, ]))),
  missing_metadata = expect_error(join(rows, meta[-1, ])))
bad <- meta; bad$document_id[1] <- "not-in-study"
rejections <- c(rejections, different_roster = expect_error(join(rows, bad)))
bad <- meta; bad$value <- 1
rejections <- c(rejections, column_collision = expect_error(join(rows, bad)))
bad <- meta; bad$document_id[1] <- NA_character_
rejections <- c(rejections, missing_id = expect_error(join(rows, bad)))
bad <- meta; bad$document_id[1] <- " "
rejections <- c(rejections, blank_id = expect_error(join(rows, bad)))
bad <- meta; bad$writer_id[1] <- ""
rejections <- c(rejections, blank_writer = expect_error(join(rows, bad)))
bad <- meta; names(bad)[3] <- "writer_id"
rejections <- c(rejections, duplicate_column = expect_error(join(rows, bad)))
stopifnot(identical(join(rows, meta[rev(seq_len(nrow(meta))), ]), join(rows, meta)))
unicode <- meta; unicode$task <- "\u65e5\u672c\u8a9e"
stopifnot(all(join(rows, unicode)$task == "\u65e5\u672c\u8a9e"))
summary <- e$summarize_study_documents; keys <- e$study_group_keys
rejections <- c(rejections,
  duplicate_results = expect_error(summary(rbind(e$study_table, e$study_table[1, ]), keys)),
  dropped_setting = expect_error(summary(e$study_table, setdiff(keys, "window_length"))))
# Hand-specified values make the reporting and document weighting independent of LD formulas.
fixture <- e$study_table[rep(1, 4), ]
fixture$document_id <- c("a", "b", "c", "d")
fixture$writer_id <- c("writer-A", "writer-A", NA, "writer-B")
fixture$value <- c(1, 3, 9, NA_real_)
fixture$reportable_value <- c(1, 3, NA_real_, NA_real_)
fixture$selection_complete <- c(TRUE, TRUE, FALSE, TRUE)
fixture$status <- c("ok", "ok", "ok", "undefined")
f <- summary(fixture, keys)
stopifnot(nrow(f) == 1L, f$n_documents == 4L, f$n_writers_known == 2L,
  f$n_unknown_writer_documents == 1L, f$n_calculated == 3L, f$n_reported == 2L,
  f$n_unavailable == 1L, f$n_withheld == 1L, f$n_reported_writers_known == 1L,
  f$n_selection_incomplete == 1L,
  f$mean == 2, f$median == 2, isTRUE(all.equal(f$sd, sqrt(2))))
# Distinct parameter values and missing group labels must not be pooled or dropped.
changed <- fixture; changed$window_length <- 99
split <- summary(rbind(fixture, changed), keys)
stopifnot(nrow(split) == 2L, all(split$n_documents == 4L), all(split$mean == 2))
labels <- fixture; labels$task <- c("a.b", "a", "NA", NA_character_)
label_summary <- summary(labels, keys)
stopifnot(nrow(label_summary) == 4L, sum(is.na(label_summary$task)) == 1L,
  sum(label_summary$task == "NA", na.rm = TRUE) == 1L)
reordered <- summary(e$study_table[rev(seq_len(nrow(e$study_table))), ], keys)
sort_summary <- function(x) {
  x <- x[order(x$condition, x$task, x$metric_id), ]; rownames(x) <- NULL; x
}
stopifnot(isTRUE(all.equal(sort_summary(reordered), sort_summary(english$summary))))
saveRDS(list(english = english, japanese = list(table = j$study_table, summary = s),
  rejections = rejections, arithmetic = f, session = sessionInfo()),
  file.path(output, "guide-validation.rds"), version = 2)
cat("English/Japanese independent paths, 216 diagnostic rows, 24 summary groups,",
  length(rejections), "rejections, unknown/empty/singleton cases, settings, arithmetic and CSV/RDS replay passed.\n")
