#!/usr/bin/env Rscript
# A fixed-model, sentence-level check; no model tuning, corpus download or plotting.
# Usage: Rscript evaluate-eslspok-amod.R test.conllu model.udpipe output-dir [library] [tokenizer]
# Obtain the pinned public test file and model separately; neither is redistributed.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% 3:5)
if (length(args) >= 4L) .libPaths(c(args[4L], .libPaths()))
tokenizer <- if (length(args) == 5L) args[5L] else "tokenizer"
stopifnot(tokenizer %in% c("tokenizer", "tokenizer=presegmented"))
library(ldfreq)
stopifnot(as.character(packageVersion("udpipe")) == "0.8.16")
source(system.file("examples", "udpipe-amod.R", package = "ldfreq", mustWork = TRUE))
corpus <- normalizePath(args[1L], mustWork = TRUE)
model_path <- normalizePath(args[2L], mustWork = TRUE)
out <- args[3L]
dir.create(out, recursive = TRUE, showWarnings = FALSE)
sha <- function(path) digest::digest(file = path, algo = "sha256")
stopifnot(sha(corpus) == "7d3b37af353205dc3b2964937e7c511e7763cdca25ec9c830638a2540ffe04be",
  sha(model_path) == "784bd0fa85e3d831fd02a55290d0acfd05c953159dc38cc33d52e1b28add9957")
lines <- readLines(corpus, encoding = "UTF-8", warn = FALSE)
ids <- sub("^# sent_id = ", "", lines[startsWith(lines, "# sent_id = ")])
text <- sub("^# text = ", "", lines[startsWith(lines, "# text = ")])
stopifnot(length(ids) == length(text), !anyDuplicated(ids),
  all(grepl("^file[0-9]+\\.txt_[0-9]+$", ids)))
roster <- data.frame(document_id = ids, segment_id = "s1", text = text,
  parser_id = paste0("sentence_", seq_along(ids)),
  source_file_id = sub("_[0-9]+$", "", ids), source_order = seq_along(ids))
if (tokenizer == "tokenizer=presegmented") stopifnot(!any(grepl("[\r\n]", roster$text)))
# document_id is the analysis sentence ID, NOT a claim of whole-document input.
gold <- udpipe::udpipe_read_conllu(corpus)
stopifnot(identical(unique(gold$sentence_id), ids),
  identical(gold$sentence, text[match(gold$sentence_id, ids)]),
  all(grepl("^[1-9][0-9]*$", gold$token_id)), all(is.na(gold$deps)),
  all(grepl("^(0|[1-9][0-9]*)$", gold$head_token_id)))
reference_metadata <- list(language = "en", analyzer = "UD-English-ESLSpok-reference",
  analyzer_version = "3feb27b9759454c4cf02263b371963137bee0d2b", dictionary = "not-applicable",
  dictionary_version = "not-applicable", unit = "UD-syntactic-word", normalization = "none",
  source_sha256 = sha(corpus), split = "test", license = "CC BY-SA 4.0",
  reference_process = "manual XPOS/dependencies; converted and manually checked UPOS; no lemmas",
  source_text = "distributed sentence text; not complete original interviews")
model_metadata <- list(language = "en", analyzer = "udpipe", analyzer_version = "0.8.16",
  dictionary = "embedded-in-model", dictionary_version = sha(model_path),
  unit = "UDPipe-syntactic-word", normalization = "none", model = basename(model_path),
  model_sha256 = sha(model_path), model_source = "https://github.com/jwijffels/udpipe.models.ud.2.5",
  model_license = "CC BY-NC-SA 4.0", tokenizer = tokenizer, tagger = "default", parser = "default")
policy <- list(feature = "ADJ-amod-NOUN including amod subtypes; surface unit",
  selection = "all sentences in the pinned test split; no parameter/model selection",
  input = "distributed sentence text with fixed reference sentence boundaries; predicted tokenization",
  comparison = "exact dependent and head codepoint spans; complete sentences only",
  failure = "retain all statuses; operational recall counts reference pairs on failed predictions as unretrieved",
  inference = "finite test-set description; no population CI or full-document diversity claim")
policy$tokenizer_condition <- tokenizer
policy$role <- if (tokenizer == "tokenizer") "fixed initial evaluation" else
  "development check of explicit sentence-boundary setting after initial failures; not an untouched final test"
saveRDS(list(policy = policy, reference = reference_metadata, model = model_metadata,
  roster = roster, session = sessionInfo()), file.path(out, "design.rds"))

capture <- function(expr) tryCatch(force(expr), error = function(e) list(error = conditionMessage(e)))
status <- function(x) {
  if (!is.null(x[["error"]])) x[["error"]] else if (all(x$pairs$documents$status %in% c("complete", "empty")))
    "complete" else "incomplete_annotation"
}
reference <- lapply(seq_len(nrow(roster)), function(i) capture({
  rows <- gold[gold$sentence_id == ids[i], ]
  tokens <- data.frame(document_id = ids[i], segment_id = "s1",
    token_index = as.numeric(rows$token_id), surface = rows$token, lemma = rows$lemma,
    upos = rows$upos, head = as.numeric(rows$head_token_id), deprel = rows$dep_rel)
  imported <- lexdiv_import_annotations(tokens, roster[i, ], reference_metadata)
  list(imported = imported, pairs = lexdiv_amod_pairs(imported, unit = "surface"))
}))
raw_path <- file.path(out, "raw-predictions.rds")
if (file.exists(raw_path)) {
  cached <- readRDS(raw_path)
  stopifnot(identical(cached$roster, roster), identical(cached$metadata, model_metadata))
  raw <- cached$output
} else {
  model <- udpipe::udpipe_load_model(model_path)
  raw <- lapply(seq_len(nrow(roster)), function(i) {
    capture(udpipe::udpipe_annotate(model, x = roster$text[i], doc_id = roster$parser_id[i],
      tokenizer = tokenizer, tagger = "default", parser = "default"))
  })
  saveRDS(list(roster = roster, metadata = model_metadata, output = raw), raw_path)
}
writeLines(vapply(raw, function(x) if (inherits(x, "udpipe_connlu")) x$conllu else "",
  character(1)), file.path(out, "predicted.conllu"))
prediction <- lapply(seq_along(raw), function(i) capture({
  if (!is.null(raw[[i]][["error"]])) stop(raw[[i]][["error"]])
  imported <- import_udpipe_sentences(raw[[i]], roster[i, ], model_metadata)
  list(imported = imported, pairs = lexdiv_amod_pairs(imported, unit = "surface"))
}))
sentences <- roster[c("document_id", "source_file_id", "source_order")]
sentences$reference_status <- vapply(reference, status, character(1))
sentences$prediction_status <- vapply(prediction, status, character(1))
sentences$reference_pairs <- vapply(reference, function(x)
  if (status(x) == "complete") x$pairs$documents$pairs else NA_integer_, integer(1))
sentences$prediction_pairs <- vapply(prediction, function(x)
  if (status(x) == "complete") x$pairs$documents$pairs else NA_integer_, integer(1))
sentences$paired <- sentences$reference_status == "complete" & sentences$prediction_status == "complete"
sentences$tp <- sentences$fp <- sentences$fn <- rep(NA_integer_, nrow(sentences))
keys <- c("document_id", "segment_id", "dependent_start", "dependent_end", "head_start", "head_end")
contexts <- c("dependent_surface", "head_surface", "pre", "keyword", "post")
comparisons <- list()
for (i in which(sentences$paired)) {
  r <- reference[[i]]$pairs$occurrences[c(keys, contexts)]
  p <- prediction[[i]]$pairs$occurrences[c(keys, contexts)]
  r$in_reference <- rep(TRUE, nrow(r)); p$in_prediction <- rep(TRUE, nrow(p))
  comparison <- merge(r, p, by = keys, all = TRUE, sort = FALSE, suffixes = c("_reference", "_prediction"))
  comparison$in_reference[is.na(comparison$in_reference)] <- FALSE
  comparison$in_prediction[is.na(comparison$in_prediction)] <- FALSE
  comparison$outcome <- with(comparison,
    ifelse(in_reference & in_prediction, "tp", ifelse(in_reference, "fn", "fp")))
  for (label in c("tp", "fp", "fn")) sentences[i, label] <- sum(comparison$outcome == label)
  comparisons[[length(comparisons) + 1L]] <- comparison
}
occurrences <- do.call(rbind, comparisons)
paired <- sentences[sentences$paired, ]
stopifnot(nrow(paired) > 0, all(paired$tp + paired$fn == paired$reference_pairs),
  all(paired$tp + paired$fp == paired$prediction_pairs))
counts <- colSums(paired[c("tp", "fp", "fn")])
ratio <- function(a, b) if (b > 0) unname(a / b) else NA_real_
failed_ref_pairs <- sum(sentences$reference_pairs[
  sentences$reference_status == "complete" & !sentences$paired])
summary <- data.frame(sentences = nrow(sentences), source_file_groups = length(unique(sentences$source_file_id)),
  reference_complete = sum(sentences$reference_status == "complete"),
  prediction_complete = sum(sentences$prediction_status == "complete"), paired = nrow(paired),
  tp = unname(counts["tp"]), fp = unname(counts["fp"]), fn = unname(counts["fn"]),
  precision = ratio(counts["tp"], counts["tp"] + counts["fp"]),
  recall = ratio(counts["tp"], counts["tp"] + counts["fn"]),
  f1 = ratio(2 * counts["tp"], 2 * counts["tp"] + counts["fp"] + counts["fn"]),
  reference_pairs_on_failed_predictions = failed_ref_pairs,
  operational_recall = ratio(counts["tp"], sum(sentences$reference_pairs, na.rm = TRUE)),
  equal_counts = sum(paired$reference_pairs == paired$prediction_pairs),
  equal_counts_wrong_occurrences = sum(paired$reference_pairs == paired$prediction_pairs & paired$fp + paired$fn > 0),
  reference_positive_sentences = sum(paired$reference_pairs > 0),
  count_mae = mean(abs(paired$prediction_pairs - paired$reference_pairs)))
result <- list(summary = summary, sentences = sentences, occurrences = occurrences,
  reference = reference, prediction = prediction, policy = policy,
  reference_metadata = reference_metadata, model_metadata = model_metadata)
saveRDS(result, file.path(out, "evaluation.rds"))
write.csv(summary, file.path(out, "summary.csv"), row.names = FALSE)
write.csv(sentences, file.path(out, "sentences.csv"), row.names = FALSE, na = "NA")
write.csv(occurrences, file.path(out, "occurrences.csv"), row.names = FALSE, na = "NA")
review <- occurrences[occurrences$outcome != "tp", ]
review$review_status <- rep("unreviewed", nrow(review))
for (side in c("reference", "prediction")) {
  annotations <- if (side == "reference") reference else prediction
  for (field in c("dependent_upos", "deprel", "head_surface"))
    review[[paste0("at_dependent_", field, "_", side)]] <- rep(NA_character_, nrow(review))
  for (j in seq_len(nrow(review))) {
    tokens <- annotations[[match(review$document_id[j], ids)]]$imported$tokens
    k <- which(tokens$start == review$dependent_start[j] & tokens$end == review$dependent_end[j])
    if (length(k) != 1L) next
    review[j, paste0("at_dependent_dependent_upos_", side)] <- tokens$upos[k]
    review[j, paste0("at_dependent_deprel_", side)] <- tokens$deprel[k]
    head <- tokens$head[k]
    if (!is.na(head) && head > 0)
      review[j, paste0("at_dependent_head_surface_", side)] <- tokens$surface[head]
  }
}
write.csv(review, file.path(out, "review-queue.csv"), row.names = FALSE, na = "NA")
print(summary, row.names = FALSE)
print(table(sentences$reference_status)); print(table(sentences$prediction_status))
