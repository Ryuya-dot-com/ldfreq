# Rscript --vanilla experiments/study-report/pelic.R REPO PELIC_CACHE LOCAL_OUTPUT
# Rscript --vanilla experiments/study-report/pelic.R REPO --replay LOCAL_OUTPUT
# Reuse learner-length/analysis-local.rds; no download or metric recalculation.
args <- commandArgs(TRUE)
stopifnot(length(args) == 3L)
repo <- normalizePath(args[1], mustWork = TRUE)
replay <- identical(args[2], "--replay")
output <- args[3]
dir.create(output, recursive = TRUE, showWarnings = FALSE)
output <- normalizePath(output, mustWork = TRUE)
if (output == repo || startsWith(output, paste0(repo, "/")))
  stop("Use an output directory outside the repository: it will contain corpus text.")
library(ldfreq)
stopifnot(packageVersion("ldfreq") >= "0.3.0.9003")
guide_path <- file.path(repo, "vignettes", "from-text-to-report.Rmd")
guide <- readLines(guide_path, encoding = "UTF-8")
# Execute only the existing helper definitions, not the authored-data examples.
for (label in c("report-file-setup", "report-study-join-function",
                "report-study-summary-function")) {
  start <- grep(paste0("^```\\{r ", label, "[,}]"), guide)
  stopifnot(length(start) == 1L)
  end <- which(seq_along(guide) > start & guide == "```")[1]
  expressions <- parse(text = guide[seq.int(start + 1L, end - 1L)])
  if (label == "report-file-setup") expressions <- tail(expressions, 1L)
  else expressions <- head(expressions, 1L)
  eval(expressions)
}
if (replay) {
  restored <- readRDS(file.path(output, "study.rds"))
  stopifnot(identical(digest::digest(file = guide_path, algo = "sha256"),
    restored$provenance$guide_sha256))
  original <- restored$source_analysis
  extracted <- diagnostic_rows(original$results)
  stopifnot(identical(extracted, restored$diagnostics[names(extracted)]),
    identical(restored$results$lower, original$results),
    identical(restored$inputs$lower, original$tokens))
  table <- join_study_metadata(restored$diagnostics, restored$study$metadata)
  summary <- summarize_study_documents(table, restored$study$group_keys)
  stopifnot(identical(table, restored$study$table),
    identical(summary, restored$study$summary))
  csv <- read.csv(file.path(output, "document-results.csv"),
    colClasses = vapply(table, class, character(1)),
    na.strings = "<MISSING>", encoding = "UTF-8")
  stopifnot(isTRUE(all.equal(csv, table, tolerance = 1e-14)),
    identical(readLines(file.path(output, "methods.txt"), encoding = "UTF-8"),
      restored$study$methods))
  cat("Fresh-session replay: original values/diagnostics, metadata join, summaries, CSV and methods passed.\n")
  quit(save = "no", status = 0L)
}
cache <- normalizePath(args[2], mustWork = TRUE)
source_path <- file.path(cache, "analysis-local.rds")
original <- readRDS(source_path)
p <- original$provenance
stopifnot(p$commit == "853e9e545cc7a78a70839c68e8ed293cc7ed9c2c",
  identical(p$parameters$metrics, c("ttr", "mattr", "mtld")),
  p$parameters$operator == "<", p$parameters$threshold == 0.72,
  p$parameters$window_length == 50, p$parameters$case == "lower",
  p$parameters$normalization == "NFC", p$parameters$unit == "surface",
  p$parameters$tokenizer == "english", identical(p$parameters$keep_numbers, FALSE))
for (name in names(p$input_sha256)) stopifnot(identical(
  digest::digest(file = file.path(cache, paste0(name, ".csv")), algo = "sha256"),
  p$input_sha256[[name]]))
# Read original IDs and course/task metadata; do not read text or supplied NLP output.
read_metadata <- function(name, fields) {
  path <- file.path(cache, paste0(name, ".csv"))
  columns <- names(read.csv(path, nrows = 0L))
  stopifnot(all(fields %in% columns))
  read.csv(path, colClasses = ifelse(columns %in% fields, "character", "NULL"),
    encoding = "UTF-8", check.names = FALSE)
}
selected <- original$selected_metadata
answers <- read_metadata("answer", names(selected))
courses <- read_metadata("course", c("course_id", "class_id", "level_id"))
questions <- read_metadata("question", c("question_id", "question_type_id"))
stopifnot(!anyDuplicated(answers$answer_id), !anyDuplicated(courses$course_id),
  !anyDuplicated(questions$question_id), !anyDuplicated(selected$answer_id))
j <- match(selected$answer_id, answers$answer_id)
stopifnot(!anyNA(j))
matched <- answers[j, names(selected), drop = FALSE]
rownames(matched) <- rownames(selected) <- NULL
stopifnot(identical(matched, selected))
course_rows <- match(selected$course_id, courses$course_id)
task_rows <- match(selected$question_id, questions$question_id)
stopifnot(!anyNA(course_rows), !anyNA(task_rows), all(selected$version == "1"),
  all(courses$class_id[course_rows] == "w"),
  all(questions$question_type_id[task_rows] == "4"))
metadata <- data.frame(document_id = selected$answer_id,
  writer_id = selected$anon_id, task = selected$question_id,
  course_id = selected$course_id, course_level = courses$level_id[course_rows],
  corpus = p$corpus, stringsAsFactors = FALSE)
stopifnot(nrow(metadata) == 16L, length(unique(metadata$writer_id)) == 16L,
  !anyNA(metadata), all(metadata$task == "3042"), all(metadata$course_level == "3"),
  identical(metadata$document_id, names(original$tokens)),
  identical(names(original$prepared), names(original$tokens)),
  identical(original$tokens, lapply(original$prepared, function(x) x$tokens$surface)))
rows <- diagnostic_rows(original$results)
stopifnot(nrow(rows) == 48L, !anyDuplicated(rows[c("document_id", "metric_id")]),
  identical(unique(rows$document_id), metadata$document_id),
  all(rows$N == lengths(original$tokens)[match(rows$document_id, names(original$tokens))]))
mtld_method <- "mtld_seq_bidir_dirmean_lt_nomin_linear_tail_v1"
stopifnot(all(rows$method_id[rows$metric_id == "mtld"] == mtld_method))
for (i in seq_len(nrow(rows))) {
  expected <- switch(rows$metric_id[i], ttr = list(),
    mattr = list(window_length = 50), mtld = list(threshold = 0.72))
  stopifnot(identical(original$results$requested_parameters[[i]], expected),
    identical(original$results$effective_parameters[[i]], expected))
}
rows$condition <- "lower"
rows$window_length <- ifelse(rows$metric_id == "mattr", 50, NA_real_)
rows$mtld_threshold <- ifelse(rows$metric_id == "mtld", 0.72, NA_real_)
rows$reportable_value <- rows$value
rows$selection_complete <- TRUE
table <- join_study_metadata(rows, metadata)
keys <- c("corpus", "task", "course_level", "condition", "metric_id", "method_id",
  "window_length", "mtld_threshold")
summary <- summarize_study_documents(table, keys)
# Preserve original result fields and verify summaries directly against saved values.
stopifnot(identical(table[names(rows)], rows), identical(table$value, original$results$value),
  identical(join_study_metadata(rows, metadata[rev(seq_len(nrow(metadata))), ]), table),
  nrow(summary) == 3L, all(summary$n_documents == 16L),
  all(summary$n_writers_known == 16L), all(summary$n_reported == 16L),
  all(summary$n_unavailable == 0L), all(summary$n_withheld == 0L))
for (i in seq_len(nrow(summary))) {
  values <- original$results$value[original$results$metric_id == summary$metric_id[i]]
  stopifnot(identical(summary$mean[i], mean(values)),
    identical(summary$sd[i], sd(values)), identical(summary$median[i], median(values)))
}
mtld <- table[table$metric_id == "mtld", ]
diagnostics <- data.frame(documents = nrow(mtld), unique_writers = length(unique(mtld$writer_id)),
  N_min = min(mtld$N), N_max = max(mtld$N),
  tail_only_either = sum(mtld$mtld_tail_only),
  below_floor = sum(mtld$below_quality_floor),
  gap_median_percent = median(mtld$mtld_gap_percent),
  gap_max_percent = max(mtld$mtld_gap_percent))
stopifnot(identical(mtld$forward_complete_factors,
  as.numeric(original$support$forward_complete_factors)),
  identical(mtld$reverse_complete_factors, as.numeric(original$support$reverse_complete_factors)),
  isTRUE(all.equal(mtld$mtld_gap_percent, original$support$direction_gap_percent)))
methods <- c(sprintf(paste(
  "We reused PELIC v1.0 (Juffs, Han, & Naismith, 2020; doi:10.5281/zenodo.3991977),",
  "upstream commit %s. The saved selection retained original writing-class essay",
  "responses, chose the prompt with most distinct writers (ties: lowest numeric",
  "question ID), and retained the first numeric answer ID per writer.",
  "This yielded %d documents by %d writers for prompt %s, all at recorded course",
  "level %s. Course level was contextual metadata, not a calibrated ability score."),
  p$commit, nrow(metadata), length(unique(metadata$writer_id)),
  unique(metadata$task), unique(metadata$course_level)),
  sprintf(paste(
  "The saved calculations used ldfreq %s, its English tokenizer, NFC normalization,",
  "lowercase surface forms and number exclusion. Spelling and grammatical forms",
  "were retained; no lemmatization, correction or content-POS filtering was applied.",
  "Metrics were full-document TTR, MATTR with window 50, and MTLD method %s:",
  "strict TTR < 0.72, no minimum factor length, final-token closure checks,",
  "linear residual credit (1 - TTR) / (1 - 0.72), arithmetic mean of directions."),
  p$package, mtld_method),
  sprintf(paste(
  "Reporting used ldfreq %s and the from-text-to-report guide helpers.",
  "Metadata were matched by original document ID against byte-verified source files.",
  "All %d document values per metric were reported, with document-weighted mean,",
  "sample SD and median. Unavailable and withheld counts were zero. Complete-factor",
  "counts, the advisory length flag and forward/reverse gaps were retained; gaps",
  "describe order sensitivity, not standard errors or confidence intervals.",
  "Flags did not automatically exclude documents. No reference vocabulary,",
  "group comparison, ability inference or inferential test was added."),
  as.character(packageVersion("ldfreq")), nrow(metadata)))
record <- list(source_analysis = original, settings = list(metrics = p$parameters$metrics,
  window_length = 50, mtld_threshold = 0.72), inputs = list(lower = original$tokens),
  results = list(lower = original$results), diagnostics = rows,
  study = list(metadata = metadata, table = table, summary = summary, group_keys = keys,
    diagnostic_summary = diagnostics, methods = methods),
  provenance = list(source_record_sha256 = digest::digest(file = source_path, algo = "sha256"),
    guide_sha256 = digest::digest(file = guide_path, algo = "sha256"),
    script_sha256 = digest::digest(file = file.path(repo, "experiments", "study-report", "pelic.R"),
      algo = "sha256"), reporting_package = as.character(packageVersion("ldfreq")),
    session = sessionInfo()))
saveRDS(record, file.path(output, "study.rds"), version = 2)
for (name in c("document-results", "descriptive-statistics", "diagnostic-summary")) {
  object <- switch(name, "document-results" = table, "descriptive-statistics" = summary,
    "diagnostic-summary" = diagnostics)
  write.csv(object, file.path(output, paste0(name, ".csv")), row.names = FALSE,
    na = "<MISSING>", fileEncoding = "UTF-8")
}
writeLines(enc2utf8(methods), file.path(output, "methods.txt"), useBytes = TRUE)
restored <- readRDS(file.path(output, "study.rds"))
stopifnot(identical(restored, record), identical(restored$source_analysis, original))
csv <- read.csv(file.path(output, "document-results.csv"),
  colClasses = vapply(table, class, character(1)),
  na.strings = "<MISSING>", encoding = "UTF-8")
stopifnot(isTRUE(all.equal(csv, table, tolerance = 1e-14)))
print(summary[c("metric_id", "n_documents", "n_writers_known", "n_reported", "mean", "sd", "median")])
print(diagnostics)
cat("Source metadata, 48 result rows, 3 summaries, original diagnostics and CSV/RDS round trip passed.\n")
