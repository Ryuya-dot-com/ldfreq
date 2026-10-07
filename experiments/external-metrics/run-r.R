# Run installed external implementations on exactly the supplied token vectors.
# Usage: Rscript run-r.R package-root external-library inputs.json output.json
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 4L)
.libPaths(c(args[[2L]], .libPaths()))
pkgload::load_all(args[[1L]], quiet = TRUE)
suppressPackageStartupMessages(library(koRpus.lang.en))
inputs <- jsonlite::read_json(args[[3L]], simplifyVector = TRUE)
rows <- list()
for (id in names(inputs$cases)) {
  tokens <- inputs$cases[[id]]
  ours <- lexdiv_metrics(tokens, metrics = c("mtld", "ttr", "maas", "mattr"),
                         window_length = 10)
  corpus <- suppressWarnings(koRpus::lex.div(tokens, measure = c("MTLD", "TTR"),
    case.sens = TRUE, force.lang = "en", quiet = TRUE, keep.tokens = TRUE))
  stopifnot(identical(corpus@tt$tokens, tokens))
  qt <- quanteda::as.tokens(setNames(list(tokens), id))
  stopifnot(identical(unname(as.list(qt)[[1L]]), tokens))
  q <- quanteda.textstats::textstat_lexdiv(qt, measure = c("TTR", "Maas"),
    log.base = exp(1), remove_numbers = FALSE, remove_punct = FALSE,
    remove_symbols = FALSE, remove_hyphens = FALSE)
  rows[[id]] <- list(case = id, N = length(tokens),
    ldfreq = as.data.frame(ours)[c("metric_id", "method_id", "value", "status", "missing_reason")],
    koRpus = list(mtld = corpus@MTLD$MTLD, factors = corpus@MTLD$factors,
                  ttr = corpus@TTR), quanteda.textstats = as.data.frame(q))
}
jsonlite::write_json(list(
  R = as.character(getRversion()),
  ldfreq_baseline = list(version = as.character(packageVersion("ldfreq")),
    mtld_source_sha256 = digest::digest(file = file.path(args[[1L]], "R", "metric-mtld.R"), algo = "sha256")),
  versions = setNames(lapply(c("koRpus", "koRpus.lang.en", "quanteda", "quanteda.textstats"),
    function(p) as.character(packageVersion(p))),
    c("koRpus", "koRpus.lang.en", "quanteda", "quanteda.textstats")),
  inputs_sha256 = digest::digest(file = args[[3L]], algo = "sha256"),
  parameters = list(mtld_threshold = 0.72, quanteda_log_base = exp(1),
                    case_preserved = TRUE, tokens_verified_unchanged = TRUE),
  results = rows), args[[4L]], pretty = TRUE, auto_unbox = TRUE, digits = NA,
  null = "null", na = "null")
