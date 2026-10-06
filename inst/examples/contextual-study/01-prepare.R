# Run from a new study directory. All text, labels, groups and vectors below
# are authored teaching examples, NOT observations or independent judgments.
library(ldfreq)
if (!requireNamespace("quanteda", quietly = TRUE) || packageVersion("quanteda") < "4.5.0" ||
    !isTRUE(l10n_info()[["UTF-8"]]))
  stop("This example needs optional quanteda >= 4.5.0 and a UTF-8 R session.")
if (dir.exists("inputs")) stop("inputs already exists; use a new study directory.")

words <- list(
  c("Her", "bank", "approved", "a", "loan", "."),
  c("A", "bank", "holds", "deposits", "."),
  c("We", "rested", "by", "the", "bank", "."),
  c("あの", "店", "は", "人気", "が", "ある", "。"),
  c("その", "歌", "に", "人気", "が", "集まる", "。"),
  c("夜", "の", "庭", "に", "人気", "が", "ない", "。"),
  c("The", "bank", "opened", "early", "."),
  c("Water", "covered", "the", "bank", "."),
  c("この", "本", "は", "人気", "が", "高い", "。"),
  c("森", "に", "は", "人気", "が", "なかった", "。"),
  c("My", "bank", "closed", "today", "."),
  c("The", "river", "bank", "collapsed", "."),
  c("新人", "の", "人気", "が", "急上昇", "した", "。"),
  c("向こう", "に", "は", "人気", "が", "ある", "。"))
metadata <- data.frame(
  document_id = sprintf("authored-%02d", seq_along(words)),
  partition = c(rep("train", 6), rep("development", 4), rep("test", 4)),
  group_id = c(rep("train-en", 3), rep("train-ja", 3),
    rep("dev-en", 2), rep("dev-ja", 2), rep("test-en", 2), rep("test-ja", 2)),
  language = c(rep("en", 3), rep("ja", 3), rep(c("en", "ja"), each = 2, times = 2)))
segments <- data.frame(document_id = metadata$document_id, segment_id = "s1",
  text = c("Her bank approved a loan.", "A bank holds deposits.",
    "We rested by the bank.", "あの店は人気がある。", "その歌に人気が集まる。",
    "夜の庭に人気がない。", "The bank opened early.", "Water covered the bank.",
    "この本は人気が高い。", "森には人気がなかった。", "My bank closed today.",
    "The river bank collapsed.", "新人の人気が急上昇した。", "向こうには人気がある。"))
tokens <- data.frame(document_id = rep(metadata$document_id, lengths(words)),
  segment_id = "s1", token_index = sequence(lengths(words)),
  surface = unlist(words, use.names = FALSE))
candidates <- data.frame(term = c("bank", "bank", "人気", "人気"),
  candidate_id = c("financial", "river", "popularity", "human-presence"),
  label = c("financial institution", "river edge", "にんき", "ひとけ"))
resource <- list(resource_id = "authored-study", resource_version = "1",
  source_reference = "Authored candidates, not a validated sense inventory",
  data_license = "MIT")
annotation <- list(language = "en/ja", analyzer = "authored", analyzer_version = "1",
  dictionary = "none", dictionary_version = "none", unit = "authored",
  normalization = "none")
model <- list(model_id = "authored-study", model_revision = "1",
  tokenizer_id = "authored", tokenizer_revision = "1", software = "illustration",
  software_version = "1", context_policy = "full segment; no truncation",
  representation = "authored two-dimensional target vectors; no inference",
  score_definition = "no scores at import")

# A majority candidate exists for each training surface. Query vectors and
# missingness are constructed to illustrate denominator changes, not accuracy.
vectors <- rbind(c(2, 0), c(2, 1), c(0, 2), c(2, 0), c(1, 0), c(0, 2),
  c(1, 0), c(0, 1), c(1, 0), c(0, 1), c(NA, NA), c(0, 1), c(1, 0), c(1, 0))
intended <- c("financial", "financial", "river", "popularity", "popularity",
  "human-presence", "financial", "river", "popularity", "human-presence",
  "financial", "river", "popularity", NA_character_)

if (!dir.create("inputs")) stop("Could not create a new inputs directory.")
write.csv(metadata, "inputs/metadata.csv", row.names = FALSE, fileEncoding = "UTF-8")
saveRDS(list(purpose = "Authored workflow demonstration, not a validation study",
  group_definition = "Artificial groups; no real participants",
  annotation_protocol = "Author-specified labels, including disagreement and unresolved cases",
  candidates = candidates, resource = resource, annotation = annotation, model = model),
  "inputs/design.rds")

for (part in c("train", "development", "test")) {
  ids <- metadata$document_id[metadata$partition == part]
  a <- lexdiv_import_annotations(tokens[tokens$document_id %in% ids, ],
    segments[segments$document_id %in% ids, ], annotation)
  review <- lexdiv_ambiguity_review(a, c("bank", "人気"), candidates, resource)
  o <- review$occurrences
  row <- match(o$document_id, metadata$document_id)
  anchors <- o[c("review_id", "occurrence_id", "segment_text", "surface", "start", "end")]
  write.csv(anchors, paste0("inputs/", part, "-request.csv"), row.names = FALSE,
    fileEncoding = "UTF-8")
  returned <- anchors
  ok <- complete.cases(vectors[row, , drop = FALSE])
  returned$status <- ifelse(ok, "processed", "skipped")
  returned$reason <- ifelse(ok, "Authored vector", "Authored missing-vector example")
  emb <- vectors[row[ok], , drop = FALSE]
  rownames(emb) <- o$occurrence_id[ok]
  imported <- lexdiv_import_contextual(review, returned, model, emb)
  saveRDS(imported, paste0("inputs/", part, "-model.rds"))

  # In a study, collect these separately before exposing model suggestions.
  # The example labels below are authored; no human independence is claimed.
  decisions <- o[c("review_id", "occurrence_id")]
  decisions$candidate_id <- intended[row]
  decisions$status <- ifelse(is.na(decisions$candidate_id), "unresolved", "selected")
  decisions$reviewer <- "authored-A"
  decisions$reason <- "Authored illustration of a judgment"
  judge_a <- lexdiv_ambiguity_review(a, c("bank", "人気"), candidates, resource, decisions)
  write.csv(decisions, paste0("inputs/", part, "-judge-a.csv"), row.names = FALSE,
    fileEncoding = "UTF-8", na = "")
  judge_b_decisions <- decisions
  judge_b_decisions$reviewer <- "authored-B"
  if (part == "test") {
    judge_b_decisions$candidate_id[o$document_id %in% ids[3:4]] <- "human-presence"
    judge_b_decisions$status <- "selected"
  }
  judge_b <- lexdiv_ambiguity_review(a, c("bank", "人気"), candidates, resource,
    judge_b_decisions)
  write.csv(judge_b_decisions, paste0("inputs/", part, "-judge-b.csv"), row.names = FALSE,
    fileEncoding = "UTF-8", na = "")
  decisions$reviewer <- "authored-adjudicator"
  decisions$reason <- ifelse(decisions$status == "selected",
    "Authored reference choice; inspect individual judgments separately",
    "Authored unresolved reference; not forced to a candidate")
  reference <- lexdiv_ambiguity_review(a, c("bank", "人気"), candidates, resource, decisions)
  write.csv(decisions, paste0("inputs/", part, "-reference.csv"), row.names = FALSE,
    fileEncoding = "UTF-8", na = "")
  saveRDS(list(reference = reference, judge_a = judge_a, judge_b = judge_b),
    paste0("inputs/", part, "-reference.rds"))
}
message("Authored inputs saved. CSVs document these snapshots; editing a CSV does not update an RDS.")
