# ldfreq

**Compare lexical diversity and vocabulary profiles while keeping the analysis
conditions attached to the results.** `ldfreq` is an R package for researchers
working with English writing, teaching materials, and other texts. It combines
lexical-diversity measures, New JACET 8000 level coverage, and TUBELEX reference
frequency with explicit preprocessing, parameter settings, and match coverage.

A difference between two scores can reflect different word units, window sizes,
or reference-list matches. `ldfreq` helps you inspect those choices and report
what was actually measured. It records non-computable requests and their reasons,
and checks that reshaped tables and plots do not mix incompatible specifications.

## Why use ldfreq?

- **Keep comparisons explicit.** Retain the formula, requested and effective
  parameters, token/type counts, and preprocessing decisions with each result.
  Short documents do not silently reduce a requested window for other documents.
- **Connect diversity with reference vocabulary.** Describe New JACET 8000
  levels and TUBELEX frequency/prevalence alongside token/type coverage. Unmatched
  terms remain visible; missing frequency values are not replaced by zero.
- **Examine sensitivity.** Compare lexical units, parameter settings, and selected
  Maas/MTLD definitions; inspect local MATTR windows and positional exposure.

These are features for describing and comparing texts. A score alone does not
establish proficiency, writing quality, measurement validity, or reliability.

## Relationship to other R packages

| Existing tool | Its focus | Where ldfreq fits |
|---|---|---|
| [quanteda.textstats](https://quanteda.io/reference/textstat_lexdiv.html) | Text statistics and lexical diversity for quanteda tokens and document-feature matrices | Use prepared tokens with explicit method/parameter records, non-computability reasons, and reference-resource profiles |
| [koRpus](https://reaktanz.de/?c=hacking&s=koRpus) | Text analysis including lemma workflows, MTLD, HD-D, MTLD-MA, and detailed diagnostics | Compare the exact definitions and add a common workflow for condition tracking and reference coverage |
| [tidytext](https://juliasilge.github.io/tidytext/) | Text processing with tidy tables | Pass one-token-per-row tables through `lexdiv_as_documents()` |
| [zipfR](https://r-forge.r-project.org/projects/zipfr/) | Statistical models for word-frequency distributions and vocabulary growth | Use ldfreq for document-level descriptive measures and reference-list profiles |

Existing R packages already implement many of these metrics and document their
parameters. The contribution here is their integration with explicit comparison
conditions and resource coverage, not a claim to have invented the measures.
Same-named metrics can differ in formula, log base, aggregation, or short-text
handling. See [definition and preprocessing comparisons](https://ryuya-dot-com.github.io/ldfreq/articles/preprocessing-and-frequency.html).
No speed or empirical-validity advantage over these packages is claimed.

## Installation

The current 0.2.0 version is under development and has not been released on CRAN.
For users with access to the development repository:

```r
pak::pak("Ryuya-dot-com/ldfreq")
```

## A first analysis

```r
library(ldfreq)

texts <- c(
  first = "The student reads a book and discusses the book with a friend.",
  second = "The student explores a story and shares several ideas with a friend."
)
prepared <- lexdiv_tokenize_batch(
  texts, tokenizer = "english", normalization = "NFC", case = "lower"
)

# Window 10 illustrates the interface; choose a window for your research design.
analysis <- lexdiv_metrics_text_batch(
  prepared, metrics = c("ttr", "mattr"), window_length = 10
)
analysis$results[, c("document_id", "metric_id", "N", "V", "value", "status")]

# The bundled NJ8 table is available offline, with JACET's permission.
# This is surface-form coverage; it does not silently lemmatize the text.
levels <- nj8_profile_batch(prepared, unit = "surface")
levels$coverage
plot(analysis, metric_id = "mattr")
```

The English tokenizer runs entirely in R. It retains contractions and
hyphenated words, recognizes dotted initialisms, and records excluded URLs,
email addresses and number-like spans. Named text vectors and ID/text data
frames share the same batch interface. Existing calls keep the original
`tokenizer = "unicode"` default; select the English rules explicitly.
See [English tokenization and document input](https://ryuya-dot-com.github.io/ldfreq/articles/english-tokenization.html)
for segmentation examples, CSV/text-file input, and limitations.

These two authored sentences illustrate the workflow, not a population effect.
TTR uses the full document denominator; MATTR uses the selected local window.
NJ8 coverage asks how much of the selected vocabulary matches the list, not how
much vocabulary a writer knows. For lemma coverage, supply or explicitly generate
lemmas first. Report the selected unit, exclusions, and off-list proportion.

[From text to a report](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html) extends this example
to a reusable analysis table, an interpretation, saved results, and citations.

## Reference frequency needs its own tokenization

The bundled TUBELEX table uses NLTK Treebank tokenization. The general
`lexdiv_tokenize()` keeps contractions together and is a different tokenizer.
For example, the appropriate segmentation of this illustrative sentence is:

```r
terms <- c("I", "do", "n't", "think", "it", "'s", "John", "'s", "book")
frequency <- tubelex_profile(terms)
frequency$summary
frequency$coverage
```

For raw text, follow the optional, executable
[TUBELEX input recipe](https://ryuya-dot-com.github.io/ldfreq/articles/tubelex-input.html). It uses NLTK externally,
records its version and sentence-model identity, and reproduces the English
word-splitting and filtering steps of the pinned TUBELEX source. It does not
reproduce subtitle collection, cleaning, or deduplication. R calculations have
no Python or network dependency. Character-vector inputs remain caller-supplied;
a high match rate does not prove that arbitrary tokens use the right segmentation.

## Available analyses

| Task | Entry points |
|---|---|
| Twelve diversity measures | `lexdiv_metrics()`, `lexdiv_metrics_text()`, `lexdiv_metrics_batch()` |
| Named raw texts or document ID/text tables | `lexdiv_tokenize_batch()`, `lexdiv_metrics_text_batch()` |
| Raw text, lemmas, or externally supplied AntBNC flemmas | `lexdiv_tokenize()`, `lexdiv_lemmatize()`, `lexdiv_flemmatize()` |
| Parameter and definition sensitivity | `lexdiv_spec()`, `lexdiv_grid()`, `lexdiv_plan()`, `lexdiv_profile()`, `lexdiv_profile_batch()`, `lexdiv_variant_metrics()` |
| Local MATTR windows and exposure | `lexdiv_mattr_profile()` |
| Exact term/content-word overlap | `lexdiv_term_overlap()`, `lexdiv_content_overlap()` |
| Coverage of a supplied reference set | `lexdiv_reference_coverage()` |
| Numeric lexical norms with observed-value and annotation coverage | `lexdiv_norm_profile()` |
| Bundled or external NJ8 levels | `nj8_profile()`, `nj8_profile_batch()` |
| Bundled TUBELEX frequency/prevalence | `tubelex_profile()`, `tubelex_profile_batch()` |
| Token-table adapters, wide tables, and plots | `lexdiv_as_documents()`, `lexdiv_widen()`, `plot()` |

The twelve core measures are TTR, RTTR/Guiraud, CTTR, Herdan C, Maas a-squared,
MSTTR, MATTR, MTLD, HD-D, deterministic expected-TTR D, and Yule K/I.
`lexdiv_methods()` describes their definitions, scales, parameters, and direction.
Expected-TTR D fits an exact finite-population expectation; it is not CLAN VOCD.

`lexdiv_screen()` and `lexdiv_length_evidence()` describe advisory token-count
criteria. Passing a screen does not establish validity or precision. Missing
results do not change the requested parameters or silently remove documents.

## Learning and reporting

- [Getting started](https://ryuya-dot-com.github.io/ldfreq/articles/getting-started.html): inputs, result tables, annotation, and parameter plans.
- [From text to a report](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html): one complete workflow and what to cite.
- [Designing comparisons](https://ryuya-dot-com.github.io/ldfreq/articles/designing-comparisons.html): questions, common settings, sensitivity, answers, and limits.
- [Preprocessing and frequency](https://ryuya-dot-com.github.io/ldfreq/articles/preprocessing-and-frequency.html): lexical units, formula variants, and resource coverage.
- [TUBELEX input recipe](https://ryuya-dot-com.github.io/ldfreq/articles/tubelex-input.html): optional external token preparation.

After installation, the same articles are available with `vignette(package = "ldfreq")`.
Exact formulas and result specifications are installed under `system.file("spec",
package = "ldfreq")`. Preserve the full results with `saveRDS()`, together with
preprocessing and session information; flat exports of selected values alone
cannot retain all analysis settings.

## Data and attribution

New JACET 8000 is copyright JACET and is redistributed with permission and source
attribution. Cite JACET Basic Word Revision Committee (Ed.). (2016).
*The New JACET List of 8000 Basic Words*. Tokyo: Kirihara Shoten.
The bundled `jacet2016-8000-v1` table has all 8,000 rank/entry pairs, checked
against the official workbook. Three corrections to the supplied snapshot
(`nan`, `true`, and `false`) are documented in the
[NJ8 notice](https://github.com/Ryuya-dot-com/ldfreq/blob/main/inst/licenses/nj8/NOTICE.md).
An external data frame, CSV, or XLSX can still be supplied as `wordlist`.

TUBELEX is copyright Adam Nohejl and is distributed under BSD-3-Clause.
Cite Nohejl et al. (2025),
[Beyond Film Subtitles: Is YouTube the Best Approximation of Spoken Vocabulary?](https://aclanthology.org/2025.coling-main.641/).
The bundled resource is a slim aggregate at source commit `7cb5fb36`; no raw
subtitles are included. Its source, changes, and complete license are recorded
in the [TUBELEX notice](https://github.com/Ryuya-dot-com/ldfreq/blob/main/inst/licenses/tubelex/NOTICE.md).
NGSL, Open English WordNet, and AntBNC data are not bundled.

Use `citation("ldfreq")` for the software and cite the methods and resources
used in the analysis. The R code is MIT licensed. Bundled resources retain
their own terms; see `LICENSE` and the installed `COPYRIGHTS` file.
