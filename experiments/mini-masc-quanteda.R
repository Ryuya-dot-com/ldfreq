# Feasibility probe, not a general MASC reader or a published reference norm.
# Run with an installed development ldfreq, xml2, quanteda and digest:
# Rscript experiments/mini-masc-quanteda.R /path/to/Mini-MASC.zip /output/dir
# Source: https://anc.org/data/masc/downloads/data-download/
# Archive: https://github.com/nancyide/anc-website/releases/download/datasets-2026-09-25/Mini-MASC.zip
# Mini-MASC 1.0, ANC Project, README dated 2010-09-19.
# Corpus terms: https://creativecommons.org/licenses/by/3.0/us/
# Uses supplied s/u regions; retokenizes their text with quanteda word4.
# Does not import the supplied Penn/PTB token, lemma or POS annotations.
# Outputs counts and settings, without copying corpus text or annotations.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
archive <- normalizePath(args[1], mustWork = TRUE)
output <- args[2]
for (pkg in c("ldfreq", "xml2", "quanteda", "digest", "Matrix"))
  stopifnot(requireNamespace(pkg, quietly = TRUE))
stopifnot(identical(digest::digest(archive, file = TRUE, algo = "sha256"),
  "b2ad414a4c175970c1ca01b2cbcac4980eec186fd9a7cfeaac29e41adbb9e5a6"))
members <- utils::unzip(archive, list = TRUE)
read_member <- function(name) {
  i <- match(name, members$Name)
  stopifnot(!is.na(i))
  con <- unz(archive, name, open = "rb")
  on.exit(close(con))
  readBin(con, "raw", n = members$Length[i])
}
ns <- c(g = "http://www.xces.org/ns/GrAF/1.0/")
texts <- grep("^Mini-MASC/data/[^/]+/[^/]+\\.txt$", members$Name, value = TRUE)
stopifnot(length(texts) == 8L)
segments <- lapply(texts, function(member) {
  primary <- rawToChar(read_member(member))
  Encoding(primary) <- "UTF-8"
  stopifnot(!is.na(iconv(primary, "UTF-8", "UTF-8")))
  # This archive has no non-BMP characters; this is not a general offset test.
  stopifnot(all(utf8ToInt(primary) <= 65535L))
  stem <- sub("\\.txt$", "", member)
  graph <- xml2::read_xml(read_member(paste0(stem, "-s.xml")))
  region <- xml2::xml_find_all(graph, ".//g:region", ns)
  bounds <- do.call(rbind, strsplit(xml2::xml_attr(region, "anchors"), " ", fixed = TRUE))
  stopifnot(ncol(bounds) == 2L)
  bounds <- matrix(as.integer(bounds), ncol = 2L)
  stopifnot(!anyNA(bounds), all(bounds[, 1] >= 0),
    all(bounds[, 2] > bounds[, 1]), all(bounds[, 2] <= nchar(primary)))
  ordering <- order(bounds[, 1], bounds[, 2])
  bounds <- bounds[ordering, , drop = FALSE]
  stopifnot(all(tail(bounds[, 1], -1) >= head(bounds[, 2], -1)))
  header <- xml2::read_xml(read_member(paste0(stem, ".anc")))
  document <- sub("^Mini-MASC/data/", "", stem)
  data.frame(document_id = document,
    segment_id = xml2::xml_attr(region, "id")[ordering],
    start_char0 = bounds[, 1], end_char0_exclusive = bounds[, 2],
    text = substring(primary, bounds[, 1] + 1L, bounds[, 2]),
    medium = xml2::xml_text(xml2::xml_find_first(header, ".//g:medium", ns)),
    stringsAsFactors = FALSE)
})
segments <- do.call(rbind, segments)
rownames(segments) <- NULL
segment_key <- paste(segments$document_id, segments$segment_id, sep = "::")
stopifnot(!anyNA(segments$segment_id), !anyDuplicated(segment_key))
toks <- quanteda::tokens(stats::setNames(segments$text, segment_key),
  what = "word4", remove_punct = TRUE, remove_symbols = TRUE,
  remove_numbers = FALSE, remove_url = FALSE, remove_separators = TRUE,
  split_hyphens = FALSE, split_tags = FALSE, padding = TRUE)
toks <- quanteda::tokens_tolower(toks)
token_list <- as.list(toks)
# Keep gaps: renumbering after punctuation removal would invent adjacency.
rows <- lapply(seq_along(token_list), function(i) {
  keep <- which(nzchar(token_list[[i]]))
  data.frame(document_id = rep(segments$document_id[i], length(keep)),
    segment_id = rep(segments$segment_id[i], length(keep)),
    token_index = keep, term = token_list[[i]][keep], stringsAsFactors = FALSE)
})
prepared <- do.call(rbind, rows)
documents <- unique(segments$document_id)
x <- ldfreq::lexdiv_ngrams(prepared,
  preprocessing_id = "mini-masc-1.0-s-regions-quanteda-4.5.0-word4-lower-punct-symbol-gaps",
  documents = documents)
stopifnot(as.character(utils::packageVersion("quanteda")) == "4.5.0")
# Unit separator is only a probe key; validate absence rather than assume it.
sep <- "\u001f"
stopifnot(!any(grepl(sep, prepared$term, fixed = TRUE)))
results <- lapply(2:4, function(n) {
  ng <- quanteda::tokens_ngrams(toks, n = n, concatenator = sep)
  # Sum across segments before evaluating document frequency.
  mat <- quanteda::dfm_group(quanteda::dfm(ng), groups = segments$document_id)
  if (n <= 3L) {
    expected <- x$counts[x$counts$n == n, ]
    keys <- do.call(paste, c(expected[paste0("term", seq_len(n))], sep = sep))
    i <- match(quanteda::featnames(mat), keys)
    stopifnot(!anyNA(i), length(i) == nrow(expected),
      all(as.numeric(Matrix::colSums(mat)) == expected$count[i]),
      all(as.numeric(quanteda::docfreq(mat)) == expected$document_count[i]))
    per_doc <- x$documents[x$documents$n == n, ]
    j <- match(quanteda::docnames(mat), per_doc$document_id)
    stopifnot(all(as.numeric(Matrix::rowSums(mat)) == per_doc$opportunities[j]))
  }
  data.frame(n = n, opportunities = sum(quanteda::ntoken(ng)),
    types = quanteda::nfeat(mat), documents = quanteda::ndoc(mat))
})
comparison <- do.call(rbind, results)
# An authored counterexample: losing padding creates a spurious bigram.
demo <- quanteda::as.tokens(list(example = c("make", "a", "decision")))
padded <- quanteda::tokens_remove(demo, "a", valuetype = "fixed", padding = TRUE)
collapsed <- quanteda::tokens_remove(demo, "a", valuetype = "fixed", padding = FALSE)
stopifnot(quanteda::ntoken(quanteda::tokens_ngrams(padded, n = 2)) == 0L,
  identical(as.list(quanteda::tokens_ngrams(collapsed, n = 2))[[1]], "make_decision"))
kw <- quanteda::kwic(toks, "the", valuetype = "fixed", window = 3)
stopifnot(nrow(kw) > 0, all(kw$docname %in% segment_key))
dir.create(output, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(comparison, file.path(output, "mini-masc-quanteda-counts.csv"), row.names = FALSE)
log <- c("PASS: Mini-MASC feasibility probe, not a validated general reader.",
  paste("Archive SHA256:", digest::digest(archive, file = TRUE, algo = "sha256")),
  paste("Documents:", length(documents), "supplied regions:", nrow(segments),
    "retained tokens:", nrow(prepared)),
  "Bigram/trigram counts, document frequencies and opportunities agree with ldfreq.",
  "4-gram aggregation and KWIC ran through quanteda; ldfreq still supports n=2,3 only.",
  "Padding counterexample confirmed. No corpus text saved in output.",
  "Not verified: Penn/PTB annotation imports, Unicode offset generality, OANC scalability.",
  capture.output(print(comparison, row.names = FALSE)), capture.output(sessionInfo()))
writeLines(log, file.path(output, "mini-masc-quanteda-probe.log"))
cat(paste(head(log, 7L), collapse = "\n"), "\n")
