# Rscript experiments/learner-length/run.R package-root local-cache output-dir
# Explicit, noncommercial research example; downloads about 182 MB once.
args <- commandArgs(TRUE)
stopifnot(length(args) == 3L)
root <- normalizePath(args[[1]])
cache <- args[[2]]
out <- args[[3]]
dir.create(cache, recursive = TRUE, showWarnings = FALSE)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
pkgload::load_all(root, quiet = TRUE)
commit <- "853e9e545cc7a78a70839c68e8ed293cc7ed9c2c"
hashes <- c(answer = "8fc5b9dc8148f0330231d67efc2f855a6ee520aeabe2be4afdb442b3ce6e6f82",
  course = "d6b710cd284126383f96dd9fccc088ba3dcb28b5e80349cde531d565254c22c2",
  question = "0b789694740ffae6620bb3f3e65d3ed18dcde3278fa1de5d821fbcaf5873e5cf")
for (name in names(hashes)) {
  path <- file.path(cache, paste0(name, ".csv"))
  if (!file.exists(path)) download.file(paste0(
    "https://media.githubusercontent.com/media/ELI-Data-Mining-Group/PELIC-dataset/",
    commit, "/corpus_files/", name, ".csv"), path, mode = "wb")
  stopifnot(identical(digest::digest(file = path, algo = "sha256"), hashes[[name]]))
}
read <- function(name, ...) read.csv(file.path(cache, paste0(name, ".csv")),
  fileEncoding = "UTF-8", stringsAsFactors = FALSE, ...)
answers <- read("answer", colClasses = c(rep("character", 7), "NULL", "NULL"))
courses <- read("course", colClasses = "character")
questions <- read("question", colClasses = "character")
class <- courses$class_id[match(answers$course_id, courses$course_id)]
type <- questions$question_type_id[match(answers$question_id, questions$question_id)]
x <- answers[answers$version == "1" & class == "w" & type == "4", ]
stopifnot(!anyNA(x$answer_id))
# Choose the essay prompt with most distinct writers, before inspecting scores.
counts <- vapply(split(x$anon_id, x$question_id), function(z) length(unique(z)), integer(1))
question_id <- names(counts)[order(-counts, as.integer(names(counts)))][[1]]
x <- x[x$question_id == question_id, ]
x <- x[order(as.integer(x$answer_id)), ]
x <- x[!duplicated(x$anon_id), ]
prepared <- lexdiv_tokenize_batch(setNames(x$text, x$answer_id),
  tokenizer = "english", normalization = "NFC", case = "lower", keep_numbers = FALSE)
tokens <- lapply(prepared, function(z) z$tokens$surface)
results <- lexdiv_metrics_batch(tokens, metrics = c("ttr", "mattr", "mtld"), window_length = 50)
# Execute the same tutorial helpers, avoiding a second implementation.
guide <- readLines(file.path(root, "vignettes", "designing-comparisons.Rmd"))
for (label in c("mtld-support-table", "length-associations")) {
  start <- match(paste0("```{r ", label, "}"), guide) + 1L
  end <- start + which(guide[start:length(guide)] == "```")[[1]] - 2L
  eval(parse(text = guide[start:end])[[1]])
}
association <- length_associations(results)
support <- mtld_support_table(results[results$metric_id == "mtld", ])
summary <- data.frame(documents = nrow(x), unique_writers = length(unique(x$anon_id)),
  question_id = question_id, N_min = min(support$N), N_max = max(support$N),
  computed = sum(support$status == "ok"),
  tail_only_either = sum(support$tail_only, na.rm = TRUE),
  tail_only_both = sum(support$forward_complete_factors == 0 &
    support$reverse_complete_factors == 0, na.rm = TRUE),
  gap_median_percent = median(support$direction_gap_percent, na.rm = TRUE),
  gap_max_percent = max(support$direction_gap_percent, na.rm = TRUE))
# Hold the document set fixed for all prefix lengths; no concatenation/shuffling.
long <- tokens[lengths(tokens) >= 200L]
segments <- do.call(rbind, lapply(c(50L, 100L, 150L, 200L), function(n) {
  z <- lexdiv_metrics_batch(lapply(long, head, n),
    metrics = c("ttr", "mattr", "mtld"), window_length = 50)
  do.call(rbind, lapply(split(as.data.frame(z), z$metric_id), function(d) {
    ok <- d$status == "ok" & is.finite(d$value)
    data.frame(prefix_tokens = n, metric_id = d$metric_id[[1]],
      documents = nrow(d), computed = sum(ok), missing = sum(!ok),
      median = if (any(ok)) median(d$value[ok]) else NA_real_)
  }))
}))
write.csv(association, file.path(out, "length-associations.csv"), row.names = FALSE)
write.csv(summary, file.path(out, "factor-support.csv"), row.names = FALSE)
write.csv(segments, file.path(out, "prefixes.csv"), row.names = FALSE)
provenance <- list(corpus = "PELIC v1.0", commit = commit,
  doi = "10.5281/zenodo.3991977", input_sha256 = as.list(hashes),
  license = "CC BY-NC-ND 4.0 in upstream README; Zenodo metadata says CC BY-ND 4.0",
  policy = "Follow upstream noncommercial condition; no texts or token sequences redistributed",
  selection = "version 1; writing class w; essay type 4; most unique writers per prompt; ties lowest numeric question_id; first numeric answer_id per writer",
  question_id = question_id, levels = as.list(table(courses$level_id[match(x$course_id, courses$course_id)])),
  tokenizer = prepared[[1]]$provenance[c("contract_id", "contract_version",
    "tokenizer_id", "tokenizer_version")],
  parameters = list(metrics = c("ttr", "mattr", "mtld"), window_length = 50,
    threshold = 0.72, operator = "<", case = "lower", normalization = "NFC",
    unit = "surface", tokenizer = "english", keep_numbers = FALSE),
  package = as.character(packageVersion("ldfreq")), R = as.character(getRversion()),
  source_sha256 = digest::digest(file = file.path(root, "R", "metric-mtld.R"), algo = "sha256"))
jsonlite::write_json(provenance, file.path(out, "provenance.json"),
  auto_unbox = TRUE, pretty = TRUE, null = "null")
# The local record includes corpus text. Keep it outside the repository.
saveRDS(list(prepared = prepared, tokens = tokens, results = results,
  support = support, selected_metadata = x[setdiff(names(x), "text")],
  provenance = provenance), file.path(cache, "analysis-local.rds"))
print(summary); print(association); print(segments)
