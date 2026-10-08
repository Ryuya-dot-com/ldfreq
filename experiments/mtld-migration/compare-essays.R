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
# Execute the helper exactly as published in the tutorial, without running the
# unrelated vignette examples or maintaining a second copy of the screen.
guide <- readLines(file.path(root, "vignettes", "designing-comparisons.Rmd"), encoding = "UTF-8")
start <- match("```{r mtld-factor-screen}", guide)
end <- start + match("```", guide[-seq_len(start)])
stopifnot(!anyNA(c(start, end)), end > start + 1L)
eval(parse(text = guide[seq.int(start + 1L, end - 1L)]))
factors <- do.call(rbind, lapply(tokens, mtld_factor_screen))
factors$document_id <- names(tokens)
rownames(factors) <- NULL
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
shortest <- pmin(factors$forward_min, factors$reverse_min, na.rm = TRUE)
summary$shortest_complete_factor <- min(shortest, na.rm = TRUE)
summary$documents_with_complete_factors <- sum(!is.na(shortest))
summary$median_document_minimum <- median(shortest, na.rm = TRUE)
summary$possible_min10_effect <- sum(factors$screen == "possible_min10_effect")
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
operators$inclusive_relative_to_strict_percent <- 100*(operators$inclusive_le/operators$strict_lt-1)

# Check the sufficient condition against both actual package methods. These
# inputs test the screen; they do not estimate a corpus prevalence.
boundary <- c(letters[1:6], "a", "b", "c", "g")
examples <- list(empty = character(), unique9 = letters[1:9],
  repeated9 = rep("a", 9), unique10 = letters[1:10],
  factor9_equal_scores = boundary,
  factor10 = c(letters[1:7], "a", "b", "c"),
  repeated50 = rep("a", 50))
check <- do.call(rbind, lapply(examples, mtld_factor_screen))
stopifnot(all(check$screen[1:3] == "legacy_ineligible"),
  is.na(check$forward_min[1]), is.na(check$forward_min[4]),
  check$forward_short[4] == 0L, check$forward_min[5] == 9L,
  check$forward_min[6] == 10L, check$forward_short[6] == 0L,
  check$reverse_short[6] == 0L)
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(20261008)
random_tokens <- replicate(1500L, {
  n <- sample(10:300, 1L)
  vocabulary <- paste0("w", seq_len(sample(1:100, 1L)))
  sample(vocabulary, n, replace = TRUE)
}, simplify = FALSE)
verify <- function(x) {
  screen <- mtld_factor_screen(x)
  new <- lexdiv_metrics(x, metrics = "mtld")
  old <- lexdiv_variant_metrics(x, variants = legacy_id)
  paired <- is.finite(new$value) && is.finite(old$value)
  equal <- if (paired) abs(new$value - old$value) <= 1e-12 else NA
  if (screen$screen == "no_min10_effect") {
    stopifnot(identical(new$value, old$value),
      identical(new$status, old$status),
      identical(new$missing_reason, old$missing_reason))
  }
  data.frame(screen, paired = paired, equal_scores = equal)
}
boundary_checks <- do.call(rbind, lapply(examples, verify))
stopifnot(boundary_checks$equal_scores[5],
  boundary_checks$screen[5] == "possible_min10_effect",
  !boundary_checks$equal_scores[7])
random_checks <- do.call(rbind, lapply(random_tokens, verify))
check_summary <- as.data.frame(with(random_checks,
  table(screen, equal_scores, useNA = "ifany")))
provenance <- list(package_version = as.character(packageVersion("ldfreq")),
  R = R.version.string, stringi = as.character(packageVersion("stringi")),
  threshold = .72, legacy_method = legacy_id, current_method = unique(current$method_id),
  sample = "30 project-authored English teaching examples and one empty document; not a learner sample",
  preprocessing = "English tokenizer, NFC, lower case, surface tokens, numbers excluded",
  paired_rule = "Both scores finite; missing values retained in document table; no imputation",
  ranks = "Average ties; Spearman on the paired documents",
  factor_screen = "Complete factors in both directions; strict < 0.72; N < 10 classified separately; no short factors guarantees no min10 effect",
  screen_checks = list(seed = 20261008, inputs = 1500,
    lengths = "Uniform integers 10:300", vocabulary_size = "Uniform integers 1:100",
    sampling = "IID uniform tokens with replacement; Mersenne-Twister/Inversion/Rejection",
    scope = "Independent deterministic check, not a reproduction of another random sample or a prevalence estimate"),
  scope = "Descriptive migration sensitivity; not population validity or CLAN comparison")
utils::write.csv(rows, file.path(out,"documents.csv"), row.names = FALSE, na = "NA")
utils::write.csv(summary, file.path(out,"summary.csv"), row.names = FALSE, na = "NA")
utils::write.csv(operators, file.path(out,"operators.csv"), row.names = FALSE, na = "NA")
utils::write.csv(factors, file.path(out,"factors.csv"), row.names = FALSE, na = "NA")
utils::write.csv(check_summary, file.path(out,"screen-checks.csv"), row.names = FALSE, na = "NA")
jsonlite::write_json(provenance, file.path(out,"provenance.json"), pretty = TRUE, auto_unbox = TRUE)
saveRDS(list(rows=rows,summary=summary,operators=operators,provenance=provenance,
  prepared=prepared,current=current,legacy=legacy,factors=factors,
  factor_screen_function=mtld_factor_screen,boundary_checks=boundary_checks,
  random_checks=random_checks), file.path(out,"analysis.rds"))
print(summary, row.names = FALSE)
print(operators[operators$input == "threshold_equal", ], row.names = FALSE)
