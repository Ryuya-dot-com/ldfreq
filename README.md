# ldfreq <a href="https://ryuya-dot-com.github.io/ldfreq/"><img src="man/figures/logo.svg" align="right" height="138" alt="ldfreq website" /></a>

<!-- badges: start -->
[![R-CMD-check](https://github.com/Ryuya-dot-com/ldfreq/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Ryuya-dot-com/ldfreq/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-2.0--dev-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![R >= 4.1.0](https://img.shields.io/badge/R-%3E%3D%204.1.0-276DC3.svg?logo=r&logoColor=white)](https://cran.r-project.org/)
[![Dependencies: 2](https://img.shields.io/badge/dependencies-2%20(digest%2C%20stringi)-0072B2.svg)](https://github.com/Ryuya-dot-com/ldfreq/blob/main/DESCRIPTION)
<!-- badges: end -->

**Reproducible lexical diversity, vocabulary profiles, and source-linked corpus analysis in R.**

`ldfreq` measures lexical diversity and reference-vocabulary coverage while keeping every score connected to the exact words counted, preprocessing choices, coverage rates, and reasons for unavailable values.

[2.0-dev site](https://ryuya-dot-com.github.io/ldfreq/dev/) ·
[Stable 1.0.0 site](https://ryuya-dot-com.github.io/ldfreq/) ·
[Get started](https://ryuya-dot-com.github.io/ldfreq/dev/articles/getting-started.html) ·
[Function reference](https://ryuya-dot-com.github.io/ldfreq/dev/reference/index.html) ·
[Choosing metrics](https://ryuya-dot-com.github.io/ldfreq/dev/articles/choosing-metrics.html) ·
[Report an issue](https://github.com/Ryuya-dot-com/ldfreq/issues)

## Why ldfreq?

- **Auditable from raw text to model table**: Every result retains counted tokens (`$token_audit`), parameter settings, and explicit `status` / `missing_reason` fields—short or empty documents are never silently dropped or turned into zeros.
- **Unified single- and multi-document API**: Pass one document or a corpus table (`data.frame`, `tibble`, `data.table`, or named list) to the same entry points (`lexdiv_metrics_text()`, `lexdiv_metrics()`, `lexdiv_tokenize()`, `tubelex_profile()`, `nj8_profile()`, `lexdiv_norm_profile()`).
- **One cohesive workflow**: Compute 13 lexical-diversity measures and cross-definition variants, profile vocabulary against frequency/level/norm/word-family lists (`TUBELEX`, `New JACET 8000`, `BNC/COCA` 1k–25k bands, `MorphoLex`, or custom tables), extract 2- to 12-word lexical bundles, and inspect source contexts with KWIC concordances, dispersion, collocations, and keyness.
- **Lightweight and R-native**: Requires only **2 runtime packages** (`digest` and `stringi`), runs offline out of the box, and produces publication-ready Base-R figures (`monochrome = TRUE` supported).

<a id="installation"></a>

## Installation

The `main` branch hosts the **2.0.0 development series (`1.99.0.9000`)** (R 4.1 or later), distributed directly via GitHub. It consolidates single-document and batch functions into unified entry points and standardizes argument names; review the migration notes in [NEWS.md](https://github.com/Ryuya-dot-com/ldfreq/blob/main/NEWS.md) before upgrading an existing 1.x analysis.

```r
# 2.0.0 development series from GitHub main
install.packages("pak")
pak::pak("Ryuya-dot-com/ldfreq@main")

# Or use remotes
install.packages("remotes")
remotes::install_github("Ryuya-dot-com/ldfreq@main")
```

To install the **stable 1.0.0 release** instead:

```r
remotes::install_github("Ryuya-dot-com/ldfreq@v1.0.0")
```

To install the 2.0.0 development build from a local source archive:

```r
install.packages(c("digest", "stringi"))
install.packages("ldfreq_1.99.0.9000.tar.gz", repos = NULL, type = "source")
```

### Migrating from 1.0.0 to 2.0.0-dev

- **Unified polymorphic entry points**: `lexdiv_tokenize()`, `lexdiv_lemmatize()`, `lexdiv_flemmatize()`, `lexdiv_metrics()`, `lexdiv_metrics_text()`, `nj8_profile()`, `tubelex_profile()`, and `lexdiv_norm_profile()` accept both single-document inputs and multi-document tables or named lists directly. Former separate batch-suffixed exports are retired.
- **Standardized column and cache arguments**: Token/term column selectors across multi-document functions use `term_col` (paired with `id_col = "document_id"`), and resource-backed profilers accept `cache_dir = NULL`.
- **Recorded English defaults**: Raw-text tokenization defaults to `case = "lower", tokenizer = "english"`. Pass `case = "preserve", tokenizer = "unicode"` to reproduce 1.0.0 raw-text settings. See [NEWS.md](https://github.com/Ryuya-dot-com/ldfreq/blob/main/NEWS.md) for the complete migration table.

## Quick start

Pass one text or a document table (`data.frame` or `tibble`) to `lexdiv_metrics_text()`. English tokenization (`tokenizer = "english"`) and lowercasing (`case = "lower"`) are used by default and recorded alongside the results:

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

batch <- lexdiv_metrics_text(essays, metrics = c("ttr", "mattr", "hdd", "mtld"))
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

Note that `essay_02` (12 tokens) is computable algebraically under partial-factor MTLD (`mtld_tail_only = TRUE`), whereas empirical stability floors (typically `N >= 100` for MTLD) are evaluated explicitly without altering scores via `lexdiv_screen_lengths()`.

Inspect `batch$token_audit` to verify every counted word, or bridge raw texts straight into corpus search and keyness with `lexdiv_as_annotations()` (preserving original casing and character offsets alongside normalized `term` and `is_word`):

```r
ann <- lexdiv_as_annotations(essays)
kwic <- lexdiv_concordance(ann, queries = list(story = "stor*"), valuetype = "glob")
plot(kwic, "story")
```

## Choose your workflow

Start with `lexdiv_metrics_text()` for raw texts or `lexdiv_metrics()` for pre-tokenized words. Add the workflow tools below when your research design or reporting task needs them.

| Research question | Main functions | Worked guide |
|---|---|---|
| How do lexical-diversity scores vary across texts or counting rules? | `lexdiv_metrics_text()` → `lexdiv_widen()` / `plot()` | [From text to report](https://ryuya-dot-com.github.io/ldfreq/dev/articles/from-text-to-report.html) |
| How do writers, tasks, or occasions compare in longitudinal designs? | `lexdiv_plan()` → `lexdiv_metrics_text(..., plan = plan)` → `lexdiv_screen_lengths()` → `lexdiv_study_table()` → `lexdiv_study_model_data()` | [Repeated observations](https://ryuya-dot-com.github.io/ldfreq/dev/articles/repeated-observations.html) |
| How frequent, familiar, or morphologically varied is the vocabulary? | `tubelex_profile()`, `nj8_profile()`, `lexdiv_norm_profile()`, `lexdiv_family_profile()` | [Corpus reference profiles](https://ryuya-dot-com.github.io/ldfreq/dev/articles/corpus-reference-profiles.html) |
| Which words, bundles, and contexts explain a corpus pattern? | `lexdiv_as_annotations()` → `lexdiv_concordance()` / `lexdiv_ngrams()` / `lexdiv_collocations()` / `lexdiv_keyness()` | [Concordance & dispersion](https://ryuya-dot-com.github.io/ldfreq/dev/articles/concordance-and-dispersion.html) · [Keyness](https://ryuya-dot-com.github.io/ldfreq/dev/articles/keyness-comparison.html) |
| How do I analyze Japanese texts with morphological annotations? | `lexdiv_import_annotations()` → explicit unit/POS selection → diversity or norm profiles | [Japanese annotations](https://ryuya-dot-com.github.io/ldfreq/dev/articles/japanese-annotations.html) |

For repeated runs and portable reporting, `ldfreq` also provides reusable recipes and exports (`lexdiv_recipe()` → `lexdiv_run_recipe()` → `lexdiv_write()`), saved-analysis comparison (`lexdiv_compare_analyses()`), English/Japanese calculation descriptions (`lexdiv_methods_text()`), an installed CLI (`exec/ldfreq.R`), and a standard-library Python bridge (`inst/python/ldfreq_r.py`).

## Optional reference data

`ldfreq` code is MIT licensed and installs **without** third-party datasets. Core diversity metrics, custom norm/reference tables, and corpus tools work completely offline. To use optional external resources (`tubelex`, `nj8`, `morpholex`, `bnccoca`, `morphynet`), inspect their license terms first and download only what you need:

```r
info <- lexdiv_resource_info("tubelex")
file.show(info$notice_path)  # installed terms; no data download or internet needed
lexdiv_download_resources("tubelex", accept_license = TRUE)
```

## Citation

Cite the exact `ldfreq` version used in your analysis alongside the relevant measurement methods and reference datasets:

```r
citation("ldfreq")
```

The citation reports the installed version. Cite the stable 1.0.0 release and 2.0.0 development snapshots separately when both were used.
