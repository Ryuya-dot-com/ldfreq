# Rscript run-r.R package-root external-library
args <- commandArgs(TRUE)
stopifnot(length(args) == 2L)
.libPaths(c(args[[2]], .libPaths()))
pkgload::load_all(args[[1]], quiet = TRUE)
suppressPackageStartupMessages(library(koRpus.lang.en))
folder <- file.path(args[[1]], "experiments", "raw-text-comparison")
inputs <- jsonlite::read_json(file.path(folder, "inputs.json"), simplifyVector = TRUE)
rows <- list()
append <- function(case, pipeline, tokens, native_ttr, native_mtld = NA_real_) {
  common <- lexdiv_metrics(tokens, metrics = c("ttr", "mtld"))
  rows[[length(rows) + 1L]] <<- list(case = case, pipeline = pipeline,
    tokens = tokens, native_ttr = native_ttr, native_mtld = native_mtld,
    common = as.data.frame(common)[c("metric_id", "value", "status", "missing_reason", "N", "V")])
}
for (id in names(inputs)) {
  raw <- inputs[[id]]
  for (setting in c("default", "english_lower")) {
    prep <- if (setting == "default") lexdiv_tokenize(raw) else
      lexdiv_tokenize(raw, tokenizer = "english", case = "lower")
    result <- lexdiv_metrics_text(prep, metrics = c("ttr", "mtld"))$results
    append(id, paste0("ldfreq_", setting), prep$tokens$surface,
      result$value[result$metric_id == "ttr"], result$value[result$metric_id == "mtld"])
  }
  parsed <- koRpus::tokenize(raw, format = "obj", lang = "en")
  k <- suppressWarnings(koRpus::lex.div(parsed, measure = c("TTR", "MTLD"),
    quiet = TRUE, keep.tokens = TRUE))
  append(id, "koRpus_tokenize_lexdiv", k@tt$tokens, k@TTR, k@MTLD$MTLD)
  qt <- quanteda::tokens(raw)
  q <- quanteda.textstats::textstat_lexdiv(qt, measure = "TTR")
  # Mirror only the external scorer's documented token selection, not its formula.
  selected <- quanteda::tokens(qt, split_hyphens = FALSE, remove_numbers = TRUE,
    remove_symbols = TRUE, remove_punct = TRUE, remove_url = TRUE)
  selected <- quanteda::tokens_tolower(selected) # dfm() used by textstat_lexdiv
  selected <- as.list(selected)[[1L]]
  stopifnot(isTRUE(all.equal(q$TTR, length(unique(selected)) / length(selected))))
  append(id, "quanteda_tokens_textstat", selected, q$TTR)
}
for (name in c("taaled-fallback", "taaled-pylats")) {
  external <- jsonlite::read_json(file.path(folder, "results", paste0(name, ".json")))
  for (r in external$results) append(r$case, r$pipeline, unlist(r$tokens),
    r$native$ttr, r$native$mtldo)
}
summary <- do.call(rbind, lapply(rows, function(r) {
  d <- r$common
  data.frame(case = r$case, pipeline = r$pipeline,
    N = d$N[[1]], V = d$V[[1]], native_ttr = r$native_ttr,
    common_ttr = d$value[d$metric_id == "ttr"],
    native_mtld = r$native_mtld, common_mtld = d$value[d$metric_id == "mtld"],
    common_mtld_status = d$status[d$metric_id == "mtld"])
}))
stopifnot(all(abs(summary$native_ttr - summary$common_ttr) < 1e-12))
write.csv(summary, file.path(folder, "results", "summary.csv"), row.names = FALSE)
jsonlite::write_json(list(R = as.character(getRversion()),
  versions = setNames(lapply(c("ldfreq", "koRpus", "quanteda", "quanteda.textstats", "stringi"),
    function(p) as.character(packageVersion(p))),
    c("ldfreq", "koRpus", "quanteda", "quanteda.textstats", "stringi")),
  inputs_sha256 = digest::digest(file = file.path(folder, "inputs.json"), algo = "sha256"),
  results = rows), file.path(folder, "results", "tokens-and-scores.json"),
  auto_unbox = TRUE, pretty = TRUE, digits = NA, na = "null")
print(summary)
