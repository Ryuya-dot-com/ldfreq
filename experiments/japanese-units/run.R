# Rscript experiments/japanese-units/run.R package-root local-cache output-dir [saved-Sudachi-RDS]
# Downloads only the two pinned public test splits and their license/README.
# Texts, annotations and any private per-document results stay in local-cache.
args <- commandArgs(TRUE)
stopifnot(length(args) %in% c(3L, 4L))
root <- normalizePath(args[1]); cache <- args[2]; out <- args[3]
dir.create(cache, recursive = TRUE, showWarnings = FALSE)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
cache <- normalizePath(cache)
stopifnot(cache != root, !startsWith(cache, paste0(root, "/")))
pkgload::load_all(root, quiet = TRUE)
source_info <- data.frame(unit = c("SUW", "LUW"),
  repository = c("UD_Japanese-GSD", "UD_Japanese-GSDLUW"),
  commit = c("33e7310b58308e85fd2b33a2fc3ef3e434f821c7", "71fd68633ab8c3439a48db3f3718c9ed80be9c6c"),
  file = c("ja_gsd-ud-test.conllu", "ja_gsdluw-ud-test.conllu"),
  sha256 = c("5f50ee6ed45c7ebda3787e593eaf5e9a225f25e53f6b4b32df778031862c843f", "ece9979804365bac228003e859d976e48634f2f9b71dc771a2f07079e8e65659"))

# A deliberately restricted reader for these pinned files, not a general
# CoNLL-U interface. Reject ranges/empty nodes and retain the original text.
read_split <- function(i) {
  s <- source_info[i, ]; folder <- file.path(cache, s$repository)
  dir.create(folder, showWarnings = FALSE)
  for (name in c(s$file, "README.md", "LICENSE.txt")) {
    path <- file.path(folder, name)
    if (!file.exists(path)) download.file(paste0("https://raw.githubusercontent.com/UniversalDependencies/",
      s$repository, "/", s$commit, "/", name), path, mode = "wb")
  }
  path <- file.path(folder, s$file)
  stopifnot(digest::digest(file = path, algo = "sha256") == s$sha256)
  lines <- readLines(path, encoding = "UTF-8")
  blocks <- split(lines[nzchar(lines)], cumsum(!nzchar(lines))[nzchar(lines)])
  segments <- tokens <- vector("list", length(blocks))
  for (j in seq_along(blocks)) {
    b <- blocks[[j]]
    field <- function(key) {
      prefix <- paste0("# ", key, " = ")
      found <- b[startsWith(b, prefix)]
      stopifnot(length(found) == 1L)
      substring(found, nchar(prefix) + 1L)
    }
    id <- field("sent_id")
    segments[[j]] <- data.frame(document_id = id, segment_id = "s1",
      text = field("text"), parallel_id = field("parallel_id"))
    rows <- strsplit(b[!startsWith(b, "#")], "\t", fixed = TRUE)
    stopifnot(length(rows) > 0L, all(lengths(rows) == 10L))
    d <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
    stopifnot(all(grepl("^[1-9][0-9]*$", d[[1]])),
      identical(as.integer(d[[1]]), seq_len(nrow(d))))
    tokens[[j]] <- data.frame(document_id = id, segment_id = "s1",
      token_index = as.integer(d[[1]]), surface = d[[2]], upos = d[[4]])
  }
  lexdiv_import_annotations(do.call(rbind, tokens), do.call(rbind, segments),
    list(language = "ja", analyzer = "published manual treebank annotations",
      analyzer_version = "UD r2.18", dictionary = "upstream UniDic annotation scheme",
      dictionary_version = "not an analyzer run", unit = s$unit,
      normalization = "none; original FORM", source_commit = s$commit,
      source_sha256 = s$sha256, data_license = "CC BY-SA 4.0"))
}
imports <- setNames(lapply(1:2, read_split), source_info$unit)
# Imported segment token counts differ; compare identity and original text only.
identity_columns <- c("document_id", "segment_id", "text", "parallel_id", "text_sha256")
stopifnot(identical(imports$SUW$segments[identity_columns], imports$LUW$segments[identity_columns]),
  nrow(imports$SUW$segments) == 543L)
alignment <- lexdiv_align_annotations(imports$SUW, imports$LUW)
alignment_counts <- as.data.frame(table(alignment$groups$relation), stringsAsFactors = FALSE)
names(alignment_counts) <- c("relation", "groups")
write.csv(alignment_counts, file.path(out, "alignment.csv"), row.names = FALSE)

# Reuse the published diagnostic helper rather than redefining MTLD support.
guide <- readLines(file.path(root, "vignettes", "designing-comparisons.Rmd"))
start <- match("```{r mtld-support-table}", guide) + 1L
end <- start + which(guide[start:length(guide)] == "```")[1] - 2L
eval(parse(text = guide[start:end])[[1]])
measure <- function(x, eligible) {
  t <- x$tokens
  selected <- setNames(lapply(x$documents$document_id, function(id)
    t$surface[t$document_id == id & eligible]), x$documents$document_id)
  result <- lexdiv_metrics_batch(selected, metrics = c("ttr", "mattr", "mtld"), window_length = 50)
  support <- mtld_support_table(result[result$metric_id == "mtld", ])
  d <- as.data.frame(result)[c("document_id", "metric_id", "N", "V", "value", "status", "missing_reason", "below_quality_floor")]
  d$tail_only <- support$tail_only[match(d$document_id, support$document_id)]
  d$gap_percent <- support$direction_gap_percent[match(d$document_id, support$document_id)]
  d$tail_only[d$metric_id != "mtld"] <- NA
  d$gap_percent[d$metric_id != "mtld"] <- NA_real_
  # Independent count/TTR check; no second implementation of MTLD is needed here.
  tt <- d[d$metric_id == "ttr", ]
  stopifnot(identical(as.numeric(tt$N), as.numeric(lengths(selected))),
    all(tt$V == vapply(selected, function(z) length(unique(z)), integer(1))),
    isTRUE(all.equal(tt$value, tt$V / tt$N, check.attributes = FALSE)))
  list(table = d, result = result, support = support)
}
coverage <- function(x, eligible) {
  t <- x$tokens
  # Compare covered non-whitespace codepoints, not concatenated word strings.
  lapply(seq_len(nrow(x$segments)), function(i) {
    row <- t$document_id == x$segments$document_id[i] &
      t$segment_id == x$segments$segment_id[i] & eligible
    positions <- unlist(Map(seq.int, t$start[row], t$end[row]), use.names = FALSE)
    # Use codepoints (including combining marks), consistent with importer offsets.
    chars <- strsplit(x$segments$text[i], "", fixed = TRUE)[[1]]
    positions[!stringi::stri_detect_regex(chars[positions], "^\\p{White_Space}$")]
  })
}
ud <- list(); coverage_rows <- list()
for (policy in c("all_tokens", "exclude_PUNCT_SYM")) {
  selected <- lapply(imports, function(x) if (policy == "all_tokens")
    rep(TRUE, nrow(x$tokens)) else !x$tokens$upos %in% c("PUNCT", "SYM"))
  covered <- Map(coverage, imports, selected)
  same <- vapply(seq_along(covered$SUW), function(i)
    identical(covered$SUW[[i]], covered$LUW[[i]]), logical(1))
  coverage_rows[[policy]] <- data.frame(policy = policy,
    document_id = imports$SUW$documents$document_id, same_coverage = same)
  for (unit in names(imports)) {
    z <- measure(imports[[unit]], selected[[unit]])
    z$table$condition <- unit; z$table$policy <- policy
    z$table$same_coverage <- same[match(z$table$document_id, imports[[unit]]$documents$document_id)]
    ud[[paste(policy, unit)]] <- z
  }
}
stopifnot(all(coverage_rows$all_tokens$same_coverage))
ud_rows <- do.call(rbind, lapply(ud, `[[`, "table"))
write.csv(ud_rows, file.path(out, "ud-sentence-metrics.csv"), row.names = FALSE)
write.csv(do.call(rbind, coverage_rows), file.path(out, "coverage.csv"), row.names = FALSE)

summarize <- function(d) do.call(rbind, lapply(split(d, interaction(d$policy, d$condition, d$metric_id, drop = TRUE)), function(z) {
  finite <- is.finite(z$value) & z$status == "ok"
  data.frame(policy = z$policy[1], condition = z$condition[1], metric = z$metric_id[1],
    documents = nrow(z), finite = sum(finite), missing = sum(!finite),
    N_min = min(z$N), N_median = median(z$N), N_max = max(z$N),
    V_median = median(z$V), median = if (any(finite)) median(z$value[finite]) else NA_real_,
    below_floor = sum(z$below_quality_floor),
    tail_only = if (z$metric_id[1] == "mtld") sum(z$tail_only, na.rm = TRUE) else NA_integer_)
}))
paired <- function(d, left, right) do.call(rbind, lapply(split(d, interaction(d$policy, d$metric_id, drop = TRUE)), function(z) {
  a <- z[z$condition == left, ]; b <- z[z$condition == right, ]
  stopifnot(identical(a$document_id, b$document_id))
  ok <- is.finite(a$value) & is.finite(b$value) & a$status == "ok" & b$status == "ok"
  av <- a$value[ok]; bv <- b$value[ok]
  data.frame(policy = a$policy[1], metric = a$metric_id[1], left = left, right = right,
    total = nrow(a), finite_pairs = sum(ok), missing_pairs = sum(!ok),
    changed_pairs = sum(abs(av - bv) > 1e-12),
    spearman = if (length(unique(av)) > 1L && length(unique(bv)) > 1L) cor(av, bv, method = "spearman") else NA_real_,
    median_absolute_change = if (any(ok)) median(abs(av - bv)) else NA_real_)
}))
write.csv(summarize(ud_rows), file.path(out, "ud-summary.csv"), row.names = FALSE)
# Also retain the same-coverage subset, with its denominator; never silently
# describe a POS-filtering difference as a boundary-only effect.
ud_matched <- ud_rows[ud_rows$same_coverage, ]; ud_matched$policy <- paste0(ud_matched$policy, "_same_coverage")
write.csv(paired(rbind(ud_rows, ud_matched), "SUW", "LUW"), file.path(out, "ud-paired.csv"), row.names = FALSE)
saveRDS(list(imports = imports, alignment = alignment, measures = ud), file.path(cache, "ud-analysis-local.rds"))

private_provenance <- NULL
if (length(args) == 4L) {
  previous <- readRDS(args[4]); local <- list()
  stopifnot(identical(names(previous$imports), c("A", "B", "C")))
  for (mode in names(previous$imports)) {
    x <- previous$imports[[mode]]; t <- x$tokens
    stopifnot(identical(x$segments$text, previous$imports$A$segments$text),
      identical(x$segments$document_id, previous$imports$A$segments$document_id))
    keep <- !t$pos1 %in% c("\u7a7a\u767d", "\u88dc\u52a9\u8a18\u53f7") &
      !stringi::stri_detect_regex(t$surface, "^\\p{White_Space}+$")
    z <- measure(x, keep); z$table$condition <- mode; z$table$policy <- "saved_Sudachi_surface"
    old <- previous$counts[previous$counts$mode == mode, ]
    tt <- z$table[z$table$metric_id == "ttr", ]
    stopifnot(identical(tt$document_id, old$document_id), all(tt$N == old$N),
      all(tt$V == old$surface_V), all(tt$value == old$surface_TTR))
    z$coverage <- coverage(x, keep); local[[mode]] <- z
  }
  same <- vapply(seq_along(local$A$coverage), function(i)
    identical(local$A$coverage[[i]], local$C$coverage[[i]]), logical(1))
  d <- do.call(rbind, lapply(local, `[[`, "table"))
  write.csv(summarize(d), file.path(out, "sudachi-summary.csv"), row.names = FALSE)
  write.csv(paired(d, "A", "C"), file.path(out, "sudachi-paired.csv"), row.names = FALSE)
  saveRDS(local, file.path(cache, "sudachi-metrics-local.rds"))
  private_provenance <- list(input_sha256 = digest::digest(file = args[4], algo = "sha256"),
    documents = length(same), same_coverage_A_C = sum(same),
    annotations = lapply(previous$imports, function(x) x$provenance$annotation[intersect(
      c("language", "analyzer", "analyzer_version", "dictionary", "dictionary_version",
        "unit", "normalization", "system.dic_sha256", "sudachi.json_sha256",
        "char.def_sha256", "rewrite.def_sha256", "unk.def_sha256"), names(x$provenance$annotation))]))
}
jsonlite::write_json(list(sources = source_info, release = "UD r2.18", split = "entire test split",
  language = "ja", form = "surface; no case or Unicode normalization", window_length = 50,
  mtld = "threshold .72; strict <; no minimum; linear tail; direction mean",
  package = as.character(packageVersion("ldfreq")), R = as.character(getRversion()),
  license = "UD inputs CC BY-SA 4.0; no corpus texts or annotation tables redistributed",
  private = private_provenance), file.path(out, "provenance.json"), auto_unbox = TRUE, pretty = TRUE, null = "null")
print(summarize(ud_rows))
if (length(args) == 4L) { print(summarize(d)); print(paired(d, "A", "C")) }
