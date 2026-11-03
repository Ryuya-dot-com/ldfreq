# ldfreq

**Reproducible lexical diversity, vocabulary profiles, and source-linked
corpus analysis in R.**

`ldfreq` measures lexical diversity and reference-vocabulary coverage
while keeping every score connected to the exact words counted,
preprocessing choices, coverage rates, and reasons for unavailable
values.

[Get
started](https://ryuya-dot-com.github.io/ldfreq/articles/getting-started.html)
· [Guides](https://ryuya-dot-com.github.io/ldfreq/articles/index.html) ·
[Function
reference](https://ryuya-dot-com.github.io/ldfreq/reference/index.html)
· [Choosing
metrics](https://ryuya-dot-com.github.io/ldfreq/articles/choosing-metrics.html)
· [Report an issue](https://github.com/Ryuya-dot-com/ldfreq/issues)

## Why ldfreq?

- **Auditable from raw text to model table**: Every result retains
  counted tokens (`$token_audit`), parameter settings, and explicit
  `status` / `missing_reason` fields—short or empty documents are never
  silently dropped or turned into zeros.
- **One cohesive workflow**: Compute 13 lexical-diversity measures,
  profile vocabulary against frequency/level/norm/word-family lists
  (`TUBELEX`, `New JACET 8000`, `BNC/COCA`, `MorphoLex`, or your own
  tables), and inspect source contexts with KWIC concordances,
  dispersion, collocations, and keyness.
- **Lightweight and R-native**: Requires only **2 runtime packages**
  (`digest` and `stringi`), runs offline out of the box, accepts
  `data.frame`, `tibble`, `data.table`, and `quanteda` objects, and
  produces publication-ready Base-R figures (`monochrome = TRUE`
  supported).

## Installation

The examples on this page use the **development snapshot 1.0.0.9001** (R
4.1 or later). It contains incompatible changes relative to stable
1.0.0; review the migration notes below before using it with an existing
analysis.

``` r

# Development snapshot from GitHub main
install.packages("pak")
pak::pak("Ryuya-dot-com/ldfreq@main")

# Or use remotes
install.packages("remotes")
remotes::install_github("Ryuya-dot-com/ldfreq@main")
```

To install the current stable release instead, use
`remotes::install_github("Ryuya-dot-com/ldfreq@v1.0.0")`. Its
documentation is included with that version; use
`browseVignettes("ldfreq")` after installation.

To install the development snapshot from its local archive:

``` r

install.packages(c("digest", "stringi"))
install.packages("ldfreq_1.0.0.9001.tar.gz", repos = NULL, type = "source")
```

### Migrating from 1.0.0

Raw-text tokenization and metric functions now default to
`case = "lower"` and `tokenizer = "english"`. To request the 1.0.0
preprocessing choices, explicitly set
`case = "preserve", tokenizer = "unicode"` and retain the recorded
settings. Different tokenization can change scores and makes direct
comparisons unsafe without examining the counting conditions.

Several former entry points and argument names have also changed.
Consult the [development change
notes](https://github.com/Ryuya-dot-com/ldfreq/blob/main/NEWS.md) for
the replacement names and the relevant help pages before reopening an
existing workflow. Stable 1.0.0 remains available unchanged.

## Quick start

Pass one text to
[`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
or a document table (`data.frame` or `tibble`) to
[`lexdiv_metrics_text_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md).
English tokenization (`tokenizer = "english"`) and lowercasing
(`case = "lower"`) are used by default and recorded alongside the
results:

``` r

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

Inspect `batch$token_audit` to verify every counted word, or bridge raw
texts straight into corpus search and keyness with
[`lexdiv_as_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md):

``` r

ann <- lexdiv_as_annotations(essays)
kwic <- lexdiv_concordance(ann, queries = list(story = "stor*"),
                           term_col = "term", valuetype = "glob")
plot(kwic, "story")
```

## Choose your workflow

Start with
[`lexdiv_metrics_text_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
for ordinary text analysis. Add the workflow tools below when the
research design or reporting task needs them.

| Research question | Main functions | Worked guide |
|----|----|----|
| How do lexical-diversity scores vary across texts or counting rules? | [`lexdiv_metrics_text_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md) → [`lexdiv_widen()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_widen.md) / [`plot()`](https://rdrr.io/r/graphics/plot.default.html) | [From text to report](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html) |
| How do writers, tasks, or occasions compare in longitudinal designs? | [`lexdiv_plan()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md) → `lexdiv_metrics_text_batch(..., plan = plan)` → [`lexdiv_study_table()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md) → [`lexdiv_study_model_data()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md) | [Repeated observations](https://ryuya-dot-com.github.io/ldfreq/articles/repeated-observations.html) |
| How frequent, familiar, or morphologically varied is the vocabulary? | [`tubelex_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md), [`nj8_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md), [`lexdiv_norm_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md), [`lexdiv_family_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_family_profile.md) | [Corpus reference profiles](https://ryuya-dot-com.github.io/ldfreq/articles/corpus-reference-profiles.html) |
| Which words and contexts explain a corpus pattern? | [`lexdiv_as_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md) → [`lexdiv_concordance()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md) → [`lexdiv_collocations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_collocations.md) / [`lexdiv_keyness()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_keyness.md) | [Concordance & dispersion](https://ryuya-dot-com.github.io/ldfreq/articles/concordance-and-dispersion.html) · [Keyness](https://ryuya-dot-com.github.io/ldfreq/articles/keyness-comparison.html) |
| How do I analyze Japanese texts with morphological annotations? | [`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md) → explicit unit/POS selection → diversity or norm profiles | [Japanese annotations](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.html) |

For repeated runs and portable reporting, development builds also
provide reusable recipes and exports, described in the [guide
index](https://ryuya-dot-com.github.io/ldfreq/articles/index.html):
[`lexdiv_recipe()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_recipe.md)
→
[`lexdiv_run_recipe()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_run_recipe.md)
→
[`lexdiv_write()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_write.md),
with saved-analysis comparison, English/Japanese calculation
descriptions, a folder CLI and a Python bridge to the same R engine.
Recipes are optional for ordinary text analysis.

## Optional reference data

`ldfreq` code is MIT licensed and installs **without** third-party
datasets. Core diversity metrics, custom norm/reference tables, and
corpus tools work completely offline. To use optional external resources
(`tubelex`, `nj8`, `morpholex`, `bnccoca`, `morphynet`), inspect their
license terms first and download only what you need:

``` r

info <- lexdiv_resource_info("tubelex")
file.show(info$notice_path)  # installed terms; no data download or internet needed
lexdiv_download_resources("tubelex", accept_license = TRUE)
```

## Citation

Cite the exact `ldfreq` version used in your analysis alongside the
relevant measurement methods and reference datasets:

``` r

citation("ldfreq")
```

The citation reports the installed version. Cite the stable release and
the development snapshot separately when both were used.
