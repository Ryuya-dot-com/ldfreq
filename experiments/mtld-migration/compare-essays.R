# Run against the installed corrected package; no corpus download or model call.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
root <- normalizePath(args[1], mustWork = TRUE)
out <- args[2]
dir.create(out, recursive = TRUE, showWarnings = FALSE)
library(ldfreq)
folder <- file.path(root, "inst", "examples", "text-input", "texts")
files <- sort(list.files(folder, pattern = "[.]txt$", full.names = TRUE))
texts <- vapply(files, function(p) paste(readLines(p, encoding = "UTF-8", warn = FALSE), collapse = "\n"), character(1))
names(texts) <- tools::file_path_sans_ext(basename(files))
prepared <- lexdiv_tokenize_batch(texts, tokenizer = "english", normalization = "NFC", case = "lower")
tokens <- lapply(prepared, function(x) x$tokens$surface)
current <- lexdiv_metrics_batch(tokens, metrics = "mtld", mtld_threshold = 0.72)
legacy_id <- "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1"
legacy <- lapply(tokens, lexdiv_variant_metrics, variants = legacy_id)
old <- vapply(legacy, function(x) x$value, numeric(1))
rows <- data.frame(document_id = names(tokens), N = lengths(tokens),
  legacy_min10 = unname(old), current_nomin = current$value,
  legacy_status = vapply(legacy, function(x) x$status, character(1)),
  current_status = current$status, current_missing_reason = current$missing_reason,
  source_sha256 = vapply(files, digest::digest, character(1), algo = "sha256", file = TRUE),
  row.names = NULL)
paired <- is.finite(rows$legacy_min10) & is.finite(rows$current_nomin)
a <- rows$legacy_min10[paired]; b <- rows$current_nomin[paired]
rows$change <- rows$current_nomin - rows$legacy_min10
rows$relative_change_percent <- 100 * rows$change / rows$legacy_min10
rows$legacy_rank <- rank(rows$legacy_min10, ties.method = "average", na.last = "keep")
rows$current_rank <- rank(rows$current_nomin, ties.method = "average", na.last = "keep")
summary <- data.frame(documents = nrow(rows), paired = sum(paired), excluded = sum(!paired),
  N_min = min(rows$N[paired]), N_max = max(rows$N[paired]),
  spearman = cor(a, b, method = "spearman"),
  changed = sum(abs(b - a) > 1e-12), mean_change = mean(b-a),
  median_change = median(b-a), mean_absolute_change = mean(abs(b-a)),
  maximum_absolute_change = max(abs(b-a)),
  median_relative_change_percent = median(100*(b-a)/a),
  legacy_min = min(a), legacy_max = max(a), current_min = min(b), current_max = max(b))
# Slow, transparent reference isolates the comparison operator; not a new API.
reference_mtld <- function(x, inclusive = FALSE) {
  direction <- function(x) {
    factors <- 0; start <- 1L; n <- length(x)
    if (!n) return(NA_real_)
    for (i in seq_len(n)) {
      ttr <- length(unique(x[start:i])) / (i-start+1L)
      hit <- if (inclusive) ttr <= .72 else ttr < .72
      if (hit) { factors <- factors + 1; start <- i + 1L }
    }
    if (start <= n) factors <- factors + (1-length(unique(x[start:n]))/(n-start+1L))/(1-.72)
    if (factors > 0) n/factors else NA_real_
  }
  mean(c(direction(x), direction(rev(x))))
}
adversarial <- jsonlite::fromJSON(file.path(root,"tests","fixtures","external-metrics","inputs.json"))$cases
all_tokens <- c(adversarial, tokens)
strict <- vapply(all_tokens, reference_mtld, numeric(1))
actual <- vapply(all_tokens, function(x) lexdiv_metrics(x, metrics="mtld")$value, numeric(1))
stopifnot(isTRUE(all.equal(unname(strict), unname(actual), tolerance = 1e-12)))
operators <- data.frame(input = names(all_tokens), strict_lt = strict,
  inclusive_le = vapply(all_tokens, reference_mtld, numeric(1), inclusive = TRUE), row.names = NULL)
operators$strict_relative_to_inclusive_percent <- 100*(operators$strict_lt/operators$inclusive_le-1)
provenance <- list(package_version = as.character(packageVersion("ldfreq")),
  R = R.version.string, stringi = as.character(packageVersion("stringi")),
  threshold = .72, legacy_method = legacy_id, current_method = unique(current$method_id),
  sample = "30 project-authored English teaching examples and one empty document; not a learner sample",
  preprocessing = "English tokenizer, NFC, lower case, surface tokens, numbers excluded",
  paired_rule = "Both scores finite; missing values retained in document table; no imputation",
  ranks = "Average ties; Spearman on the paired documents",
  scope = "Descriptive migration sensitivity; not population validity or CLAN comparison")
utils::write.csv(rows, file.path(out,"documents.csv"), row.names = FALSE, na = "NA")
utils::write.csv(summary, file.path(out,"summary.csv"), row.names = FALSE, na = "NA")
utils::write.csv(operators, file.path(out,"operators.csv"), row.names = FALSE, na = "NA")
jsonlite::write_json(provenance, file.path(out,"provenance.json"), pretty = TRUE, auto_unbox = TRUE)
saveRDS(list(rows=rows,summary=summary,operators=operators,provenance=provenance,
  prepared=prepared,current=current,legacy=legacy), file.path(out,"analysis.rds"))
print(summary, row.names = FALSE)
print(operators[operators$input == "threshold_equal", ], row.names = FALSE)
