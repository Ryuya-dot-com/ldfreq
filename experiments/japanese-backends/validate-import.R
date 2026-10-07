# Run from the repository root:
# Rscript experiments/japanese-backends/validate-import.R PYTHON OUTPUT_DIRECTORY [LOCAL_ANALYSIS_RDS]
# Requires installed ldfreq, jsonlite and quanteda. Python needs the versions
# fixed in sudachi-export.py. No installation or download occurs in this script.
# OUTPUT_DIRECTORY must be outside the repository for private corpus material.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% c(2L, 3L))
python <- path.expand(args[1])
# Resolving the venv symlink would select the base interpreter instead.
stopifnot(file.exists(python))
out <- args[2]
dir.create(out, recursive = TRUE, showWarnings = FALSE)
out <- normalizePath(out, mustWork = TRUE)
stopifnot(out != normalizePath("."), !startsWith(out, paste0(normalizePath("."), "/")))

import_json <- function(path) {
  x <- jsonlite::read_json(path, simplifyVector = TRUE)
  # JSON [] has no column types; preserve a valid zero-token input explicitly.
  tokens <- x$tokens
  if (!length(tokens)) {
    tokens <- data.frame(document_id = character(), segment_id = character(),
      token_index = integer(), surface = character(), start = integer(), end = integer())
  }
  ldfreq::lexdiv_import_annotations(tokens, x$segments, x$provenance)
}
read_exports <- function(folder) {
  setNames(lapply(c("A", "B", "C"), function(mode)
    jsonlite::read_json(file.path(folder, paste0("sudachi-", mode, "-local.json")),
      simplifyVector = TRUE)), c("A", "B", "C"))
}
run_modes <- function(segments, folder) {
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  input <- file.path(folder, "segments-local.json")
  jsonlite::write_json(segments, input, dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)
  imports <- lapply(c("A", "B", "C"), function(mode) {
    output <- file.path(folder, paste0("sudachi-", mode, "-local.json"))
    status <- system2(python, shQuote(c("experiments/japanese-backends/sudachi-export.py",
      input, output, "--mode", mode)))
    stopifnot(status == 0L)
    imported <- import_json(output)
    stopifnot(identical(imported$segments$text, enc2utf8(segments$text)),
      identical(imported$documents$document_id, unique(segments$document_id)))
    imported
  })
  setNames(imports, c("A", "B", "C"))
}
count_documents <- function(imports) {
  do.call(rbind, lapply(names(imports), function(mode) {
    x <- imports[[mode]]; t <- x$tokens
    # A declared selection, not a general definition of Japanese words.
    # Keep particles/auxiliaries; exclude whitespace and POS1 auxiliary symbols.
    eligible <- !t$pos1 %in% c("空白", "補助記号") &
      !stringi::stri_detect_regex(t$surface, "^\\p{White_Space}+$")
    do.call(rbind, lapply(x$documents$document_id, function(id) {
      original <- which(t$document_id == id)
      rows <- original[eligible[original]]
      metric <- as.data.frame(ldfreq::lexdiv_metrics(t$surface[rows], metrics = "ttr"))
      segment_rows <- x$segments$document_id == id
      data.frame(mode = mode, document_id = id,
        analyzer_N = sum(x$segments$analyzer_token_count[segment_rows]),
        zero_width_N = sum(x$segments$zero_width_token_count[segment_rows]),
        source_N = length(original),
        excluded_N = length(original) - metric$N, N = metric$N, surface_V = metric$V,
        surface_TTR = metric$value, status = metric$status, missing_reason = metric$missing_reason,
        dictionary_V = length(unique(t$dictionary_form[rows])),
        normalized_V = length(unique(t$normalized_form[rows])),
        selected_OOV_N = sum(t$is_oov[rows]))
    }))
  }))
}
reject <- function(expr, pattern) {
  error <- tryCatch({ force(expr); NULL }, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error)))
}

segments <- data.frame(document_id = c("compound", "variants", "unicode", "repeated",
  "repeated", "empty", "space", "punctuation", "ellipsis"),
  segment_id = c(rep("s1", 4), "s2", rep("s1", 4)),
  text = c("国家公務員", "😀りんごとリンゴと林檎。",
    "  か\u3099くせい\r\nＡＢＣ\tです。  ", "「はし」ははし。", "猫と猫。", "", " \t\r\n", "。", "猫…猫。"))
imports <- run_modes(segments, file.path(out, "authored"))
counts <- count_documents(imports)
stopifnot(all(counts$N[counts$document_id == "compound"] == c(3L, 2L, 1L)),
  all(counts$N[counts$document_id %in% c("empty", "space", "punctuation")] == 0L),
  all(is.na(counts$surface_TTR[counts$document_id == "empty"])))
variant <- subset(counts, document_id == "variants")
stopifnot(all(variant$N == 5L), all(variant$surface_V == 4L), all(variant$normalized_V == 2L))
ellipsis <- subset(counts, document_id == "ellipsis")
stopifnot(all(ellipsis$analyzer_N == 6L), all(ellipsis$zero_width_N == 2L),
  all(ellipsis$source_N == 4L), all(ellipsis$N == 2L), all(ellipsis$surface_V == 1L),
  all(counts$analyzer_N == counts$zero_width_N + counts$source_N),
  all(counts$source_N == counts$excluded_N + counts$N))
t <- imports$A$tokens
stopifnot(t$start[t$document_id == "variants" & t$surface == "りんご"] == 2L,
  any(t$surface == "か\u3099く" & t$dictionary_form == "がく"),
  any(t$surface == "ＡＢＣ" & t$dictionary_form == "ABC"))
alignment <- ldfreq::lexdiv_align_annotations(imports$A, imports$C)
compound <- subset(alignment$groups, document_id == "compound")
stopifnot(nrow(compound) == 1L, compound$relation == "split",
  compound$predicted_n == 3L, compound$reference_n == 1L, compound$keyword == "国家公務員")

# Independent R source matching must reject byte-like positions and normalized
# surfaces. Reusing decision IDs across segmentation settings must also fail.
raw <- jsonlite::read_json(file.path(out, "authored/sudachi-A-local.json"), simplifyVector = TRUE)
bad <- raw$tokens; bad$start[bad$document_id == "variants" & bad$surface == "りんご"] <- 5L
reject(ldfreq::lexdiv_import_annotations(bad, raw$segments, raw$provenance), "Supplied start")
bad <- raw$tokens; bad$surface[bad$surface == "ＡＢＣ"] <- "ABC"
reject(ldfreq::lexdiv_import_annotations(bad, raw$segments, raw$provenance), "Surfaces do not align")
bad <- raw$tokens; bad$token_index[2] <- 1L
reject(ldfreq::lexdiv_import_annotations(bad, raw$segments, raw$provenance), "consecutive")

targets <- c("りんご", "リンゴ", "林檎", "国家")
candidates <- data.frame(term = targets[1:3], candidate_id = "apple", label = "林檎")
resource <- list(resource_id = "authored-sudachi-apple", resource_version = "1",
  source_reference = "Authored fruit context in validate-import.R", data_license = "MIT")
initial <- ldfreq::lexdiv_ambiguity_review(imports$A, targets, candidates, resource)
stopifnot(sum(initial$occurrences$status == "unreviewed") == 3L,
  sum(initial$occurrences$status == "no_candidates") == 1L)
decisions <- initial$occurrences[initial$occurrences$surface %in% targets[1:3],
  c("review_id", "occurrence_id")]
decisions$status <- "selected"; decisions$candidate_id <- "apple"
decisions$reviewer <- "authored-example"
decisions$reason <- "Author intends fruit; not inferred from normalized_form"
review <- ldfreq::lexdiv_ambiguity_review(imports$A, targets, candidates, resource, decisions)
stopifnot(sum(review$occurrences$status == "selected") == 3L,
  sum(review$occurrences$status == "no_candidates") == 1L,
  identical(review$occurrences$surface, initial$occurrences$surface))
reject(ldfreq::lexdiv_ambiguity_review(imports$C, targets, candidates, resource, decisions),
  "review_id|occurrence_id")
# All-empty input must work without a fabricated token row.
empty <- run_modes(segments[segments$document_id == "empty", ], file.path(out, "all-empty"))
stopifnot(all(vapply(empty, function(x) nrow(x$tokens) == 0L, logical(1))))

# A compatibility character with multiple lexical tokens cannot be assigned
# disjoint original spans. Refuse it instead of deleting a lexical component.
unsupported <- data.frame(document_id = "compatibility", segment_id = "s1", text = "㍿")
input <- file.path(out, "unsupported.json")
jsonlite::write_json(unsupported, input, dataframe = "rows", auto_unbox = TRUE)
log <- file.path(out, "unsupported.log")
status <- system2(python, shQuote(c("experiments/japanese-backends/sudachi-export.py", input,
  file.path(out, "unsupported-output.json"), "--mode", "A")), stdout = log, stderr = log)
stopifnot(status != 0L, any(grepl("Non-symbol zero-width", readLines(log))))

result <- list(imports = imports, counts = counts, alignment = alignment, review = review,
  decisions = decisions, exports = read_exports(file.path(out, "authored")), session = sessionInfo())
saveRDS(result, file.path(out, "authored-local.rds"), version = 2)
restored <- readRDS(file.path(out, "authored-local.rds"))
stopifnot(identical(restored, result), identical(count_documents(restored$imports), counts),
  identical(ldfreq::lexdiv_ambiguity_review(restored$imports$A, targets, candidates,
    resource, restored$decisions), review))
write.csv(counts, file.path(out, "authored-counts.csv"), row.names = FALSE)
cat("Authored checks passed: 8 documents / 9 segments; 3 modes; offsets, empty input, KWIC, zero-width audit, rejection and RDS.\n")

if (length(args) == 3L) {
  # Reuse the previously saved full text. No title removal, correction or
  # independently adjudicated labels are introduced in this diagnostic run.
  previous <- readRDS(args[3])$annotations
  local <- run_modes(previous$segments[c("document_id", "segment_id", "text")],
    file.path(out, "corpus-local"))
  counts <- count_documents(local)
  stopifnot(all(counts$analyzer_N == counts$zero_width_N + counts$source_N),
    all(counts$source_N == counts$excluded_N + counts$N))
  comparisons <- list(A_C = ldfreq::lexdiv_align_annotations(local$A, local$C),
    A_gibasa = ldfreq::lexdiv_align_annotations(local$A, previous))
  result <- list(imports = local, counts = counts, comparisons = comparisons,
    exports = read_exports(file.path(out, "corpus-local")),
    session = sessionInfo(), interpretation = "descriptive correspondence; neither input is gold")
  saveRDS(result, file.path(out, "corpus-local.rds"), version = 2)
  restored <- readRDS(file.path(out, "corpus-local.rds"))
  stopifnot(identical(restored, result), identical(count_documents(restored$imports), counts))
  write.csv(counts, file.path(out, "corpus-document-counts-local.csv"), row.names = FALSE)
  totals <- aggregate(counts[c("analyzer_N", "zero_width_N", "source_N", "excluded_N", "N", "selected_OOV_N")],
    counts["mode"], sum)
  totals$documents <- length(unique(counts$document_id))
  write.csv(totals, file.path(out, "corpus-totals.csv"), row.names = FALSE)
  cat("Local corpus source-position and RDS checks passed. Aggregate token counts:\n")
  print(totals, row.names = FALSE)
}
