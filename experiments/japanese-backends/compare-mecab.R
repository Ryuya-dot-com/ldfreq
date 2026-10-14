# From the repository root, with ldfreq, gibasa, jsonlite, digest and stringi:
# Rscript experiments/japanese-backends/compare-mecab.R PYTHON UNIDIC_LITE_DIR OUTPUT_DIR
# Python requires fugashi. This script does not install or download anything.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 3L)
python <- path.expand(args[1]) # Do not resolve a venv executable's symlink.
dic_dir <- normalizePath(args[2], mustWork = TRUE)
out <- args[3]
dir.create(out, recursive = TRUE, showWarnings = FALSE)
out <- normalizePath(out, mustWork = TRUE)
segments <- data.frame(document_id = c("compound", "inflection", "suffix", "variants",
  "homograph", "unknown", "spaces", "crlf", "decomposed", "fullwidth",
  "ellipsis", "compatibility", "literal_escape", "quotes", "empty", "only_space"),
  segment_id = "s1", text = c("国際連合で国際協力を学ぶ。", "食べられなかった。学びました。",
  "学生たちの楽しさと国際化。", "りんごとリンゴと林檎。", "橋を渡り、箸を使う。",
  "ＡＩで学びました。 qzxv😀", "  猫\t猫　犬  ", "猫\r\n犬😀\r\n",
  "か\u3099くせい。", "ＡＢＣとABC、１２３と123。", "猫…猫。", "㍿で働く。",
  "猫\\r犬", "「猫」、\"犬\"。", "", " \t\r\n"))
jsonlite::write_json(segments, file.path(out, "segments.json"), dataframe = "rows",
  auto_unbox = TRUE, pretty = TRUE)

# Run the actual published recipe, not a second R implementation of it.
guide <- readLines("vignettes/japanese-annotations.Rmd", warn = FALSE)
first <- which(guide == "analyze_unidic <- function(segments, dic_dir) {")
last <- which(guide == "analysis <- analyze_unidic(ja_segments, dic_dir)") - 1L
stopifnot(length(first) == 1L, length(last) == 1L, last > first)
eval(parse(text = guide[first:last]))
analysis <- analyze_unidic(segments, dic_dir)
r <- analysis$tokens

# Use the same home configuration if present. Otherwise both use an empty file.
rc <- path.expand("~/.mecabrc")
if (!file.exists(rc)) {
  rc <- file.path(out, "mecabrc")
  writeLines("", rc)
}
stopifnot(identical(digest::digest(file = rc, algo = "sha256"),
  analysis$configuration_sha256))
status <- system2(python, shQuote(c("experiments/japanese-backends/fugashi-parity.py",
  file.path(out, "segments.json"), dic_dir, rc, file.path(out, "fugashi.json"))))
stopifnot(status == 0L)
py <- jsonlite::read_json(file.path(out, "fugashi.json"), simplifyVector = TRUE)
shared <- c("document_id", "segment_id", "token_index", "surface", "raw_feature",
  "POS1", "orthBase")
stopifnot(identical(r[shared], py$tokens[shared]))
hashes <- setNames(lapply(names(py$provenance$dictionary_sha256), function(name)
  digest::digest(file = file.path(dic_dir, name), algo = "sha256")),
  names(py$provenance$dictionary_sha256))
stopifnot(identical(hashes, py$provenance$dictionary_sha256))
metadata <- list(language = "ja", analyzer = "gibasa/MeCab",
  analyzer_version = as.character(utils::packageVersion("gibasa")),
  dictionary = "unidic-lite", dictionary_version = "1.0.8 (UniDic 2.1.2)",
  unit = "UniDic-short-unit-analysis", normalization = "none",
  settings = "unidic26; split=FALSE; partial=FALSE; no user dictionary",
  configuration_sha256 = analysis$configuration_sha256)
metadata <- c(metadata, setNames(hashes, paste0(names(hashes), "_sha256")))
imported <- ldfreq::lexdiv_import_annotations(r, segments, metadata)
t <- imported$tokens
stopifnot(identical(t$surface, r$surface), identical(t$raw_feature, r$raw_feature),
  identical(t$start, py$tokens$start), identical(t$end, py$tokens$end),
  identical(imported$segments$text, segments$text))
metadata$analyzer <- "fugashi/MeCab"
metadata$analyzer_version <- py$provenance$fugashi
py_imported <- ldfreq::lexdiv_import_annotations(py$tokens, segments, metadata)
stopifnot(identical(t$surface, py_imported$tokens$surface),
  identical(t$start, py_imported$tokens$start), identical(t$end, py_imported$tokens$end))
counts <- do.call(rbind, lapply(seq_len(nrow(py$counts)), function(i) {
  expected <- py$counts[i, ]
  unit <- expected$unit
  keep <- t$document_id == expected$document_id &
    !t$POS1 %in% c("空白", "補助記号") &
    !stringi::stri_detect_regex(t$surface, "\\p{White_Space}") & !is.na(t[[unit]])
  metric <- as.data.frame(ldfreq::lexdiv_metrics(t[[unit]][keep], metrics = "ttr"))
  stopifnot(metric$N == expected$N, metric$V == expected$V,
    isTRUE(all.equal(metric$value, expected$ttr, tolerance = 1e-15)))
  data.frame(document_id = expected$document_id, unit = unit,
    N = metric$N, V = metric$V, ttr = metric$value)
}))
saved <- list(gibasa = imported, fugashi = py_imported, counts = counts)
saveRDS(saved, file.path(out, "comparison.rds"))
stopifnot(identical(saved, readRDS(file.path(out, "comparison.rds"))))
utils::write.csv(counts, file.path(out, "counts.csv"), row.names = FALSE, na = "")
summary <- list(documents = nrow(segments), tokens = nrow(t), count_rows = nrow(counts),
  same_surface_and_raw_features = TRUE, same_codepoint_positions = TRUE,
  independent_python_N_V_TTR = TRUE, RDS_roundtrip = TRUE,
  gibasa = as.character(utils::packageVersion("gibasa")),
  ldfreq = as.character(utils::packageVersion("ldfreq")), R = R.version.string,
  python = py$provenance, guide_sha256 = digest::digest(
    file = "vignettes/japanese-annotations.Rmd", algo = "sha256"))
jsonlite::write_json(summary, file.path(out, "summary.json"), auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("PASS: %d authored documents, %d identical analyzer rows, %d count rows; positions and RDS.\n",
  nrow(segments), nrow(t), nrow(counts)))
