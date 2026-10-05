# Explicitly run this example after loading it with source(). It does nothing
# on package load. Requires ldfreq and the optional xml2 package.
# The three papers are CC BY 4.0, copyright their respective authors.
# Metadata, source XML, attribution and extraction changes are saved together.
run_open_paper_example <- function(directory, download = FALSE) {
  for (pkg in c("ldfreq", "xml2", "digest")) {
    if (!requireNamespace(pkg, quietly = TRUE)) stop("Install package: ", pkg)
  }
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  directory <- normalizePath(directory, mustWork = TRUE)
  sources <- data.frame(
    document_id = c("joss.00037", "joss.00655", "joss.00774"),
    paper = c("tidytext", "tokenizers", "quanteda"),
    year = c(2016L, 2018L, 2018L),
    commit = c("5b453b09ce6c28c5639d2d81cd8e452451ff3c9a",
      "cb515f9fbaad00f782d43c0df81bd16fbb8708ac",
      "3efd1f4566c4ccd00c4ffaa6eb0949b547a5ce74"),
    sha256 = c("9fb12efcbe2ae9a5ace2c8f8aa5a38863855e1cdb51d5a9908b47ee8174b5dcb",
      "fb46eedbd8e54ac03d219d561ceb9eb0840f7d7068e267f1bd309f5ac6a975ac",
      "c710224d41301b589a9cc6eae10ef5223448ec32b2d5eb43f6ef04fd9a4b38f5"),
    stringsAsFactors = FALSE
  )
  sources$doi <- paste0("10.21105/", sources$document_id)
  sources$article_url <- paste0("https://joss.theoj.org/papers/", sources$doi)
  sources$source_url <- paste0(
    "https://raw.githubusercontent.com/openjournals/joss-papers/",
    sources$commit, "/", sources$document_id, "/10.21105.",
    sources$document_id, ".jats")
  sources$license <- "CC BY 4.0"
  sources$license_url <- "https://creativecommons.org/licenses/by/4.0/"
  sources$language <- "English"
  sources$register <- "research software paper"
  sources$author_l1 <- NA_character_
  sources$l1_evidence <- "not established by the source metadata"
  sources$title <- sources$authors <- sources$copyright <- character(3)
  sources$text_sha256 <- character(3)
  sources$paragraph_count <- integer(3)
  sources$removed_citation_count <- integer(3)
  sources$excluded_block_count <- integer(3)
  texts <- setNames(vector("list", nrow(sources)), sources$document_id)
  paragraphs <- texts
  excluded <- paste(
    ".//body//fig", ".//body//table-wrap", ".//body//code",
    ".//body//preformat", ".//body//disp-formula",
    ".//body//sec[@id='funding-and-support']", sep = "|")
  paragraph_xpath <- ".//body//p[not(ancestor::p)]"
  normalize_space <- function(x) trimws(gsub("[[:space:]]+", " ", x))
  for (i in seq_len(nrow(sources))) {
    path <- file.path(directory, paste0(sources$document_id[i], ".jats"))
    if (!file.exists(path)) {
      if (!isTRUE(download)) stop("Missing source: ", path,
        ". Explicitly use download = TRUE to fetch the pinned papers.")
      utils::download.file(sources$source_url[i], path, mode = "wb", quiet = TRUE)
    }
    if (!identical(digest::digest(path, algo = "sha256", file = TRUE),
                   sources$sha256[i])) stop("Source hash mismatch: ", path)
    doc <- xml2::read_xml(path, options = "NONET")
    license <- xml2::xml_find_first(doc, ".//permissions/license")
    href <- xml2::xml_attr(license, "xlink:href", ns = xml2::xml_ns(doc))
    if (!identical(href, sources$license_url[i])) stop("Unexpected source license")
    doi <- xml2::xml_text(xml2::xml_find_first(doc, ".//article-id[@pub-id-type='doi']"))
    if (!identical(doi, sources$doi[i])) stop("Unexpected source DOI")
    sources$title[i] <- normalize_space(xml2::xml_text(
      xml2::xml_find_first(doc, ".//article-title")))
    sources$authors[i] <- paste(normalize_space(xml2::xml_text(
      xml2::xml_find_all(doc, ".//contrib[@contrib-type='author']/string-name"))),
      collapse = "; ")
    sources$copyright[i] <- normalize_space(xml2::xml_text(
      xml2::xml_find_first(doc, ".//copyright-statement")))
    blocks <- xml2::xml_find_all(doc, excluded)
    sources$excluded_block_count[i] <- length(blocks)
    xml2::xml_remove(blocks)
    refs <- xml2::xml_find_all(doc, ".//body//xref[@ref-type='bibr']")
    sources$removed_citation_count[i] <- length(refs)
    xml2::xml_text(refs) <- " "
    p <- normalize_space(xml2::xml_text(xml2::xml_find_all(doc, paragraph_xpath)))
    p <- p[nzchar(p)]
    if (!length(p)) stop("No body paragraphs: ", sources$document_id[i])
    paragraphs[[i]] <- p
    texts[[i]] <- paste(p, collapse = "\n\n")
    sources$paragraph_count[i] <- length(p)
    sources$text_sha256[i] <- digest::digest(enc2utf8(texts[[i]]),
      algo = "sha256", serialize = FALSE)
  }
  texts <- unlist(texts, use.names = TRUE)
  prepared <- ldfreq::lexdiv_tokenize_batch(texts, tokenizer = "english",
    normalization = "NFC", case = "lower", keep_numbers = FALSE)
  metrics <- ldfreq::lexdiv_metrics_text_batch(prepared,
    metrics = c("ttr", "mattr", "hdd"), window_length = 50L, sample_size = 42L)
  levels <- ldfreq::nj8_profile_batch(prepared, unit = "surface")
  diagnostics <- ldfreq::nj8_diagnostics(levels)
  # Join only a unique metadata table; retain every metric's status and reason.
  stopifnot(!anyDuplicated(sources$document_id))
  metadata <- sources[match(metrics$results$document_id, sources$document_id), ]
  stopifnot(identical(metadata$document_id, metrics$results$document_id))
  analysis_table <- cbind(metadata[, c("paper", "register", "author_l1")],
    metrics$results)
  rownames(analysis_table) <- NULL
  changes <- paste(
    "Body paragraphs, including list-item prose, in source order; headings,",
    "front matter and reference lists excluded by selection. Figures, tables,",
    "code, displayed formulas and the funding-and-support section removed.",
    "Bibliographic cross-reference text replaced by spaces; inline emphasis,",
    "code identifiers and link labels retained. Whitespace collapsed within",
    "paragraphs; paragraphs joined within each paper, never between papers."
  )
  result <- list(sources = sources, extraction = list(changes = changes,
    excluded_xpath = excluded, paragraph_xpath = paragraph_xpath),
    paragraphs = paragraphs, texts = texts, prepared = prepared,
    metrics = metrics, nj8 = levels, diagnostics = diagnostics,
    analysis_table = analysis_table, session = utils::sessionInfo())
  saveRDS(result, file.path(directory, "analysis.rds"))
  stopifnot(identical(result, readRDS(file.path(directory, "analysis.rds"))))
  utils::write.csv(analysis_table, file.path(directory, "metrics.csv"), row.names = FALSE)
  utils::write.csv(sources, file.path(directory, "sources.csv"), row.names = FALSE)
  utils::write.csv(levels$coverage, file.path(directory, "nj8-coverage.csv"), row.names = FALSE)
  notice <- c("JOSS open-paper example: attribution and changes", "",
    "Papers: CC BY 4.0, copyright the respective article authors.",
    "https://creativecommons.org/licenses/by/4.0/", "",
    unlist(lapply(seq_len(nrow(sources)), function(i) c(
      paste0(sources$authors[i], " (", sources$year[i], "). ", sources$title[i], "."),
      sources$article_url[i], sources$copyright[i], ""))),
    "Changes to the extracted text:", changes,
    "Analysis additionally uses NFC normalization, lowercasing, the ldfreq",
    "English tokenizer and number exclusion. No author endorsement is implied.")
  writeLines(notice, file.path(directory, "ATTRIBUTION.txt"), useBytes = TRUE)
  result
}
