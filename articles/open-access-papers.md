# Analyze open-access academic papers

## Start with a question and an accessible text sample

You can use ldfreq on your own collection of documents; a named research
corpus is not required. This example asks: **How can we describe
vocabulary in three academic texts while retaining the exact text
selection, calculation settings and reference coverage?** It takes three
short research-software papers through extraction, English tokenization,
diversity measures, NJ8 profiles, diagnostics, metadata joins and saved
results.

The deliberately selected papers concern text analysis, so they provide
relevant technical vocabulary for a reproducible demonstration. They are
not a random sample of academic writing. Some authors occur in more than
one paper, and published coauthored prose includes editorial decisions.
Their metadata do not establish author L1: this is an **academic-English
example**, not a verified native-speaker corpus or an assessment of
individual language ability.

## Use texts whose reuse conditions are explicit

Free access alone does not establish redistribution permission. Each of
these papers explicitly carries [CC BY
4.0](https://creativecommons.org/licenses/by/4.0/), with copyright
retained by its authors:

| Paper | Source and citation |
|----|----|
| tidytext | Silge & Robinson (2016), [Text Mining and Analysis Using Tidy Data Principles in R](https://joss.theoj.org/papers/10.21105/joss.00037) |
| tokenizers | Mullen et al. (2018), [Fast, Consistent Tokenization of Natural Language Text](https://joss.theoj.org/papers/10.21105/joss.00655) |
| quanteda | Benoit et al. (2018), [An R package for the quantitative analysis of textual data](https://joss.theoj.org/papers/10.21105/joss.00774) |

The recipe retains all author names, titles, DOI links, license and
copyright notices, source URLs, and a description of extraction changes.
Keep these with the extracted text if you share it. This use does not
imply author endorsement. The papers are analysis inputs here; their
calculated values do not compare the quality of the software they
describe.

## Run the R example

The example uses `xml2` to read the publisher’s JATS XML, avoiding PDF
headers, columns and line-break hyphenation. Install that optional
dependency once if needed. R-only tokenization, diversity and NJ8
analysis need no Python model. The following blocks are deliberately not
run during package checks or site builds; downloading is an explicit
analyst action.

``` r
# install.packages("xml2") # only if not already installed
library(ldfreq)
source(system.file("examples", "open-access-papers.R", package = "ldfreq"))

# Choose a dedicated analysis directory. Existing source files must match hashes.
papers <- run_open_paper_example("open-paper-analysis", download = TRUE)
papers$sources[, c("paper", "doi", "register", "author_l1", "paragraph_count")]
papers$analysis_table[, c("paper", "metric_id", "N", "V", "value", "status")]
papers$nj8$coverage
papers$diagnostics$unmatched_terms

# Once the three source files exist, the same recipe runs without downloading.
replayed <- run_open_paper_example("open-paper-analysis", download = FALSE)
stopifnot(identical(papers$texts, replayed$texts),
          identical(papers$metrics, replayed$metrics),
          identical(papers$nj8, replayed$nj8))
```

The script pins a publisher-repository commit and SHA-256 for each XML
file. It rejects changed bytes, an unexpected DOI or an unexpected
license URL. It is a worked recipe for these three files, not a
universal JATS importer. An unavailable source stops the run; it does
not silently substitute a newer article. Retain the downloaded XML for
offline reproduction.

## Specify what counts as the document

Each document consists of body paragraphs, including prose in list
items, in their source order. The script excludes title/author front
matter, section headings, reference lists, figures and captions, tables,
code blocks, displayed formulas, and the funding-and-support section.
Bibliographic cross-reference text is replaced by spaces. Link labels,
inline code identifiers and emphasized words remain. Whitespace is
collapsed within paragraphs, then paragraphs are joined within each
paper. This produces 7, 10 and 14 paragraphs respectively.

MATTR windows can cross the retained paragraph and section boundaries
**within** a paper, including a boundary created by removing a code
block. They never cross paper boundaries. A paragraph-level research
question would require keeping those paragraphs as separate documents,
retaining the parent-paper ID, and handling paragraphs too short for the
requested window.

The R analysis explicitly uses the English tokenizer, NFC, lowercase,
surface forms and number exclusion. NJ8 additionally applies its
documented lookup normalization. No stemming, lemmatization, stopword
filtering or error correction is applied. The three reference quantities
below have different interpretations:

- TTR describes type/token proportion for the complete selected text.
- MATTR uses a fixed 50-token window; HD-D uses sample size 42 on its
  expected-TTR scale. Both keep their requested settings across papers.
- NJ8 surface coverage is the fraction of eligible surface tokens that
  match the reference list; it is not the author’s vocabulary size.

For the pinned texts, the checked recipe produced:

| Paper      | Tokens | Types |      TTR | MATTR 50 |  HD-D 42 | NJ8 surface token coverage |
|------------|-------:|------:|---------:|---------:|---------:|---------------------------:|
| tidytext   |    256 |   131 | 0.511719 | 0.789565 | 0.808932 |           178/256 (69.53%) |
| tokenizers |    495 |   226 | 0.456566 | 0.748475 | 0.802244 |           322/495 (65.05%) |
| quanteda   |    935 |   408 | 0.436364 | 0.841377 | 0.869564 |           584/935 (62.46%) |

All nine requested metric rows were computable. Text length differs
substantially, so the decreasing TTR sequence is not evidence that the
longer papers use poorer vocabulary. The two diversity settings and
reference coverage describe these selected inputs; they do not rank
writing quality or establish a register effect.

The moderate NJ8 surface match rates make diagnostics useful. Inflected
forms, software names and specialized terms can be off-list for
different reasons. Inspect the returned terms and contexts before
interpreting a match failure. Any subsequent lemma analysis is a
separate, explicitly documented condition.

## Add TUBELEX using its input recipe

For reference frequency, use the optional [TUBELEX input
recipe](https://ryuya-dot-com.github.io/ldfreq/articles/tubelex-input.md),
which requires an explicitly prepared Python/NLTK environment. The R
English tokens above use a different segmentation. After that setup, the
following code can be run in the same R session:

``` r
jsonlite::write_json(as.list(papers$texts), "open-paper-texts.json", auto_unbox = TRUE)
script <- system.file("examples", "tubelex-tokenize.py", package = "ldfreq")
# The Python recipe refuses to overwrite an existing output file.
status <- system2("python3", c(shQuote(script), "open-paper-texts.json",
                              "open-paper-tokens.json"))
stopifnot(status == 0L)
input <- jsonlite::read_json("open-paper-tokens.json", simplifyVector = TRUE)
terms <- lapply(input$documents, function(x) as.character(unlist(x, use.names = FALSE)))
frequency <- tubelex_profile_batch(terms, normalization = "identity")
frequency_audit <- tubelex_diagnostics(frequency)
frequency_audit$summary
frequency_audit$unmatched_terms
saveRDS(list(sources = papers$sources, extraction = papers$extraction,
             preprocessing = input$preprocessing, terms = terms,
             profiles = frequency, diagnostics = frequency_audit),
        "open-paper-frequency.rds")
```

Keep TUBELEX’s own token/type denominators and match rates. Do not
substitute the R-tokenizer counts in the first table. A TUBELEX
matched-only mean describes frequency in the subtitle-derived reference
resource, not academic familiarity, author L1 or lexical employability.
Missing terms are not assigned frequency zero.

## Save enough to reproduce the analysis

`analysis.rds` contains source metadata, extraction choices, paragraphs,
texts, preprocessing, complete metrics, NJ8 lookup/coverage, diagnostics
and session information. `sources.csv`, `metrics.csv` and
`nj8-coverage.csv` are convenient table exports; the RDS is the fuller
analysis record. `ATTRIBUTION.txt` records the article credits and
modifications. The saved XML and text hashes identify the actual inputs,
while the full results preserve parameters and resource identities.

``` r
saved <- readRDS("open-paper-analysis/analysis.rds")
stopifnot(identical(replayed, saved))
citation("ldfreq")
```

Cite the articles as source texts, ldfreq and the selected diversity
methods, and JACET for NJ8. Cite Nohejl et al. (2025) and the recorded
NLTK implementation if adding TUBELEX. These three papers demonstrate a
reproducible workflow; independent usability testing and validity
studies across registers or language backgrounds remain separate
research questions.
