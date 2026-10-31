# ldfreq

**Lexical diversity, vocabulary profiles and corpus comparisons in R.**
Keep the original text, token choices, reference coverage and measurement settings
connected to the results you report.

[Guides](https://ryuya-dot-com.github.io/ldfreq/articles/index.html) ·
[Function reference](https://ryuya-dot-com.github.io/ldfreq/reference/index.html) ·
[Metric selection](https://ryuya-dot-com.github.io/ldfreq/articles/choosing-metrics.html) ·
[Issues](https://github.com/Ryuya-dot-com/ldfreq/issues)

<a id="installation"></a>

## Install

Install **ldfreq 1.0.0** (R 4.1 or later):

```r
install.packages(c("digest", "stringi"))
# From a local checkout or release tarball:
install.packages(".", repos = NULL, type = "source")
library(ldfreq)
```

Optional integrations state their additional packages in the relevant guide.
Use `browseVignettes("ldfreq")` for guides matching your installed version.
Earlier releases remain available in the [release archive](https://github.com/Ryuya-dot-com/ldfreq/releases).

## Start with your text

`lexdiv_metrics_text()` and `lexdiv_tokenize()` default to `tokenizer = "english"`
and `case = "lower"` while recording the exact preprocessing contract in provenance,
and pipe directly into `lexdiv_widen()`:

```r
text <- paste(
  "Students compared two versions of a short story in their writing class.",
  "They marked repeated words and discussed how each writer introduced new ideas.",
  "One group revised the opening while another group examined the ending.",
  "After reading the stories again, the students explained their choices and",
  "saved both the original texts and their revised versions for later comparison."
)
result <- lexdiv_metrics_text(text, metrics = c("mattr", "hdd", "mtld"))
result

# Check counted words, reshape directly to a wide table, and retain the full record.
head(result$token_audit)
report <- result |>
  lexdiv_widen(values_from = c("value", "status", "missing_reason", "N"))
report
saveRDS(list(text = text, analysis = result, report = report), "analysis.rds")
```

Use `lexdiv_metrics(tokens, ...)` for an already ordered character vector of
words, and `lexdiv_metrics_text_batch()` for multiple named texts, data frames,
or tibbles. Pass `plan = lexdiv_plan(...)` directly to any of the four metric
functions for multi-parameter plans, and bridge raw texts directly into corpus
search or keyness with `lexdiv_as_annotations()`.

## Follow a workflow

| Your question | Connected workflow |
|---|---|
| How do scores vary across texts or counting choices? | `lexdiv_metrics_text_batch()` → `lexdiv_widen()` / `plot()`. [Text to report](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html) |
| How do writers, tasks or occasions compare? | `lexdiv_metrics_text_batch(docs, plan = plan)` → `lexdiv_study_table()` → `lexdiv_study_model_data()`. [Study tables and models](https://ryuya-dot-com.github.io/ldfreq/articles/repeated-observations.html) |
| How frequent, familiar or morphologically varied are the words? | `lexdiv_norm_profile(terms, norms, key = "word")` or `nj8_profile()` / `tubelex_profile_batch()`. [Lexical norms](https://ryuya-dot-com.github.io/ldfreq/articles/corpus-reference-profiles.html) |
| Which words and contexts explain a corpus pattern? | `lexdiv_as_annotations()` → `lexdiv_concordance(..., term_col = "term")` → `plot()` / `lexdiv_collocations()`; `lexdiv_keyness()`. [Search](https://ryuya-dot-com.github.io/ldfreq/articles/concordance-and-dispersion.html), [keyness](https://ryuya-dot-com.github.io/ldfreq/articles/keyness-comparison.html) |
| How do I prepare Japanese text? | `lexdiv_import_annotations()` → explicit word selection → diversity or reference profiles. [Japanese workflows](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.html) |

## Optional reference data

The package code is MIT licensed. Third-party reference data are **not bundled**.
Inspect the terms for the resource you need, then explicitly download it:

```r
lexdiv_resource_info("tubelex")  # source, fixed version, license and size
# After reviewing the linked terms:
lexdiv_download_resources("tubelex", accept_license = TRUE)
```

## Cite the version you used

```r
citation("ldfreq")
```

Komuro, R. (2026). *ldfreq: Reproducible Lexical Diversity and Frequency Profiles*
(Version 1.0.0) [R package].
