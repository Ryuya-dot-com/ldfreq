args <- commandArgs(TRUE)
stopifnot(length(args) == 3L)
root <- normalizePath(args[[1]])
cache <- normalizePath(args[[2]])
corpus <- args[[3]]
pkgload::load_all(root, quiet = TRUE)
input <- file.path(cache, corpus, "extracted-private.jsonl")
con <- file(input, "r", encoding = "UTF-8")
x <- jsonlite::stream_in(con, verbose = FALSE)
close(con)
tokens <- lapply(x$text, function(text) lexdiv_tokenize(text,
  tokenizer = "english", normalization = "NFC", case = "lower",
  keep_numbers = FALSE)$tokens$surface)
names(tokens) <- x$doc_id
x$N <- lengths(tokens)
stopifnot(!anyDuplicated(x$doc_id), all(x$N > 0L))
summary <- list(corpus = corpus, documents = nrow(x), tokens = sum(x$N),
  writers = length(unique(x$writer_id[nzchar(x$writer_id)])),
  quantiles = quantile(x$N, c(0,.1,.25,.5,.75,.9,1)),
  eligible = setNames(vapply(c(100,200,400,800,1000,2000,4000),
    function(n) sum(x$N >= n), integer(1)), c(100,200,400,800,1000,2000,4000)),
  groups = as.list(table(x$group)))
saveRDS(list(metadata = x[setdiff(names(x), "text")], tokens = tokens,
  input_sha256 = digest::digest(file = input, algo = "sha256"),
  tokenization = list(tokenizer = "english", normalization = "NFC", case = "lower",
    keep_numbers = FALSE), package_version = as.character(packageVersion("ldfreq"))),
  file.path(cache, corpus, "prepared-private.rds"))
jsonlite::write_json(summary, file.path(cache, corpus, "length-summary.json"),
  auto_unbox = TRUE, pretty = TRUE, digits = 12)
print(summary)
