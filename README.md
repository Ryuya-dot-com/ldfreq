# ldfreq <a href="https://ryuya-dot-com.github.io/ldfreq/"><img src="man/figures/logo.svg" align="right" height="138" alt="ldfreq website" /></a>

<!-- badges: start -->
[![R-CMD-check](https://github.com/Ryuya-dot-com/ldfreq/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Ryuya-dot-com/ldfreq/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![R >= 4.1.0](https://img.shields.io/badge/R-%3E%3D%204.1.0-276DC3.svg?logo=r&logoColor=white)](https://cran.r-project.org/)
[![Dependencies: 2](https://img.shields.io/badge/dependencies-2%20(digest%2C%20stringi)-0072B2.svg)](https://github.com/Ryuya-dot-com/ldfreq/blob/main/DESCRIPTION)
<!-- badges: end -->

**Reproducible lexical diversity, vocabulary profiles, and source-linked corpus analysis in R.**

`ldfreq` measures lexical diversity and reference-vocabulary coverage while keeping every score connected to the exact words counted, preprocessing choices, coverage rates, and reasons for unavailable values.

[Get started](https://ryuya-dot-com.github.io/ldfreq/articles/getting-started.html) ·
[Guides](https://ryuya-dot-com.github.io/ldfreq/articles/index.html) ·
[Function reference](https://ryuya-dot-com.github.io/ldfreq/reference/index.html) ·
[Choosing metrics](https://ryuya-dot-com.github.io/ldfreq/articles/choosing-metrics.html) ·
[Report an issue](https://github.com/Ryuya-dot-com/ldfreq/issues)

## Why ldfreq?

- **Auditable from raw text to model table**: Every result retains counted tokens (`$token_audit`), parameter settings, and explicit `status` / `missing_reason` fields—short or empty documents are never silently dropped or turned into zeros.
- **One cohesive workflow**: Compute 13 lexical-diversity measures, profile vocabulary against frequency/level/norm/word-family lists (`TUBELEX`, `New JACET 8000`, `BNC/COCA`, `MorphoLex`, or your own tables), and inspect source contexts with KWIC concordances, dispersion, collocations, and keyness.
- **Lightweight and R-native**: Requires only **2 runtime packages** (`digest` and `stringi`), runs offline out of the box, accepts `data.frame`, `tibble`, `data.table`, and `quanteda` objects, and produces publication-ready Base-R figures (`monochrome = TRUE` supported).

<a id="installation"></a>

## Installation

Install **ldfreq 1.0.0** from GitHub (R 4.1 or later):

```r
# Using pak (recommended)
install.packages("pak")
pak::pak("Ryuya-dot-com/ldfreq")

# Or using remotes
install.packages("remotes")
remotes::install_github("Ryuya-dot-com/ldfreq@v1.0.0")
```

To install offline from a local release archive or checkout:

```r
install.packages(c("digest", "stringi"))
install.packages("ldfreq_1.0.0.tar.gz", repos = NULL, type = "source")
```

## Quick start

Pass one text to `lexdiv_metrics_text()` or a document table (`data.frame` or `tibble`) to `lexdiv_metrics_text_batch()`. English tokenization (`tokenizer = "english"`) and lowercasing (`case = "lower"`) are used by default and recorded alongside the results:

```r
library(ldfreq)

essays <- data.frame(
  document_id = c("essay_01", "essay_02", "empty_doc"),
  text = c(
    paste(
      "Students compared two versions of a short story in their writing class.",
      "They marked repeated words and discussed how each writer introduced new ideas.",
      "One group revised the opening while another group examined the ending.",
      "After reading the stories again, the students explained their choices and",
      "saved both the original texts and their revised versions for later comparison."
    ),
    "A short draft with too few words for a 50-token moving window.",
    ""
  )
)

batch <- lexdiv_metrics_text_batch(essays, metrics = c("ttr", "mattr", "hdd", "mtld"))
batch
#> <lexdiv_text_batch_results: 3 documents; 70 audited tokens>
#> <lexdiv_batch_results: 3 documents; 12 metric records; schema 0.1.0>
#>    document_id metric_id      value  status                    missing_reason  N  V
#> 1     essay_01       ttr  0.7931034      ok                              <NA> 58 46
#> 2     essay_01     mattr  0.8177778      ok                              <NA> 58 46
#> 3     essay_01       hdd  0.8312797      ok                              <NA> 58 46
#> 4     essay_01      mtld 78.4933333      ok                              <NA> 58 46
#> 5     essay_02       ttr  0.9166667      ok                              <NA> 12 11
#> 6     essay_02     mattr         NA missing too_short_for_requested_parameter 12 11
#> 7     essay_02       hdd         NA missing too_short_for_requested_parameter 12 11
#> 8     essay_02      mtld 40.3200000      ok                              <NA> 12 11
#> 9    empty_doc       ttr         NA missing                       empty_input  0  0
#> ...

# Reshape directly to a wide reporting table and plot available scores:
wide <- lexdiv_widen(batch, values_from = c("value", "status", "missing_reason", "N"))
plot(batch, metric_id = "mtld")
```

Inspect `batch$token_audit` to verify every counted word, or bridge raw texts straight into corpus search and keyness with `lexdiv_as_annotations()`:

```r
ann <- lexdiv_as_annotations(essays)
kwic <- lexdiv_concordance(ann, queries = list(story = "stor*"),
                           term_col = "term", valuetype = "glob")
plot(kwic, "story")
```

## Choose your workflow

| Research question | Main functions | Worked guide |
|---|---|---|
| How do lexical-diversity scores vary across texts or counting rules? | `lexdiv_metrics_text_batch()` → `lexdiv_widen()` / `plot()` | [From text to report](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html) |
| How do writers, tasks, or occasions compare in longitudinal designs? | `lexdiv_plan()` → `lexdiv_metrics_text_batch(..., plan = plan)` → `lexdiv_study_table()` → `lexdiv_study_model_data()` | [Repeated observations](https://ryuya-dot-com.github.io/ldfreq/articles/repeated-observations.html) |
| How frequent, familiar, or morphologically varied is the vocabulary? | `tubelex_profile_batch()`, `nj8_profile_batch()`, `lexdiv_norm_profile()`, `lexdiv_family_profile()` | [Corpus reference profiles](https://ryuya-dot-com.github.io/ldfreq/articles/corpus-reference-profiles.html) |
| Which words and contexts explain a corpus pattern? | `lexdiv_as_annotations()` → `lexdiv_concordance()` → `lexdiv_collocations()` / `lexdiv_keyness()` | [Concordance & dispersion](https://ryuya-dot-com.github.io/ldfreq/articles/concordance-and-dispersion.html) · [Keyness](https://ryuya-dot-com.github.io/ldfreq/articles/keyness-comparison.html) |
| How do I analyze Japanese texts with morphological annotations? | `lexdiv_import_annotations()` → explicit unit/POS selection → diversity or norm profiles | [Japanese annotations](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.html) |

## Optional reference data

`ldfreq` code is MIT licensed and installs **without** third-party datasets. Core diversity metrics, custom norm/reference tables, and corpus tools work completely offline. To use optional external resources (`tubelex`, `nj8`, `morpholex`, `bnccoca`, `morphynet`), inspect their license terms first and download only what you need:

```r
lexdiv_resource_info()  # source, version, license terms, and download size
lexdiv_download_resources("tubelex", accept_license = TRUE)
```

## Citation

Cite the exact `ldfreq` version used in your analysis alongside the relevant measurement methods and reference datasets:

```r
citation("ldfreq")
```

Komuro, R. (2026). *ldfreq: Reproducible Lexical Diversity and Frequency Profiles* (Version 1.0.0) [R package]. <https://github.com/Ryuya-dot-com/ldfreq/tree/v1.0.0>
