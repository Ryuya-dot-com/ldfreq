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

Install the fixed release **1.0.0** below (R 4.1 or later).

```r
install.packages(c("digest", "stringi"))
install.packages(
  "https://github.com/Ryuya-dot-com/ldfreq/releases/download/v1.0.0/ldfreq_1.0.0.tar.gz",
  repos = NULL, type = "source"
)
library(ldfreq)
```

Optional integrations state their additional packages in the relevant guide.
Use `browseVignettes("ldfreq")` for guides matching your installed version.
Earlier releases remain available in the [release archive](https://github.com/Ryuya-dot-com/ldfreq/releases).

## Start with your text

```r
text <- paste(
  "Students compared two versions of a short story in their writing class.",
  "They marked repeated words and discussed how each writer introduced new ideas.",
  "One group revised the opening while another group examined the ending.",
  "After reading the stories again, the students explained their choices and",
  "saved both the original texts and their revised versions for later comparison."
)
result <- lexdiv_metrics_text(text, tokenizer = "english", case = "lower",
  metrics = c("mattr", "hdd", "mtld"))
result$results[c("metric_id", "value", "N", "status", "missing_reason")]

# Check counted words, make a report table, and retain the full analysis.
head(result$token_audit)
report <- lexdiv_widen(result$results,
  values_from = c("value", "status", "missing_reason", "N"))
report
saveRDS(list(text = text, analysis = result, report = report), "analysis.rds")
```

This connects **text → scores and counted words → report table → saved record**.
Reopen it with `readRDS("analysis.rds")`; the full record retains information
that a values-only table would lose. The [first-analysis guide](https://ryuya-dot-com.github.io/ldfreq/articles/getting-started.html)
extends this to several documents, missing scores and a plot.

Use `lexdiv_metrics(tokens, ...)` for an already ordered character vector of
words, and `lexdiv_metrics_text_batch()` for multiple named texts. Inspect
`status` and `missing_reason`: an unavailable score is not zero. Keep window
and sample sizes fixed when comparing documents.

## Choose a measure for your question

For local lexical variety, start with **MATTR at a fixed window size**. Our
evidence covers English surface words at window 50; check its consistency for
your material, especially short texts. Use **HD-D at a
fixed sample size** when the distribution of word frequencies, rather than
local sequence, is the target. MTLD and MTLD-MA measure factor lengths and need
particular care with short texts. TTR is useful at a controlled length; it is
strongly affected by length otherwise.

The [metric-selection guide](https://ryuya-dot-com.github.io/ldfreq/articles/choosing-metrics.html)
explains these choices using published research and PELIC, ICNALE, OANC and
BAWE results, including length sensitivity, sampling agreement, missing scores
and actual external-tool comparisons. No single measure answers every research question.

<a id="choose-a-research-question"></a>

## Follow a workflow

Choose a question, then follow the linked example. The [connection map](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html#connect-the-analysis-steps)
shows the inputs, functions and outputs for each route.

| Your question | Connected workflow |
|---|---|
| How do scores vary across texts or counting choices? | `lexdiv_metrics_text_batch()` → inspect counts and status → `lexdiv_widen()` / `plot()`. [Text to report](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html) |
| How do writers, tasks or occasions compare? | Tokens + measurement plan → `lexdiv_metrics_batch()` → planned-observation table → one response per observation. [Study tables and models](https://ryuya-dot-com.github.io/ldfreq/articles/repeated-observations.html) |
| How frequent, familiar or morphologically varied are the words? | Terms + declared reference → word matches and coverage → document summary. [Lexical norms](https://ryuya-dot-com.github.io/ldfreq/articles/corpus-reference-profiles.html), [families and affixes](https://ryuya-dot-com.github.io/ldfreq/articles/word-families-and-affixes.html) |
| Which words and contexts explain a corpus pattern? | Complete annotations → `lexdiv_concordance()` → positions / `lexdiv_collocations()`; `lexdiv_keyness()` → source contexts. [Search](https://ryuya-dot-com.github.io/ldfreq/articles/concordance-and-dispersion.html), [keyness](https://ryuya-dot-com.github.io/ldfreq/articles/keyness-comparison.html) |
| How do I prepare Japanese text? | `lexdiv_import_annotations()` → explicit word selection → diversity or reference profiles. [Japanese workflows](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.html) |

## Optional reference data

The package code is MIT licensed. Third-party reference data are **not bundled**.
Inspect the terms for the resource you need, then explicitly download it:

```r
lexdiv_resource_info("tubelex")  # source, fixed version, license and size
# After reviewing the linked terms:
lexdiv_download_resources("tubelex", accept_license = TRUE)
```

The verified cache is reused offline; installation and ordinary calculations
do not download data. MorphoLex remains CC BY-NC-SA 4.0, BNC/COCA CC BY-SA 4.0,
MorphyNet CC BY-SA 3.0, TUBELEX BSD-3-Clause, and NJ8 has its own permission and
attribution terms. Downloading a resource does not change its license.

## Cite the version you used

```r
citation("ldfreq")
```

Komuro, R. (2026). *ldfreq: Reproducible Lexical Diversity and Frequency Profiles*
(Version 1.0.0) [R package].
[Fixed release](https://github.com/Ryuya-dot-com/ldfreq/tree/v1.0.0).

Also cite the selected measurement methods and any reference data you use.
See [CITATION.cff](https://github.com/Ryuya-dot-com/ldfreq/blob/v1.0.0/CITATION.cff), [license](https://github.com/Ryuya-dot-com/ldfreq/blob/v1.0.0/LICENSE.md), and
[release notes](https://ryuya-dot-com.github.io/ldfreq/news/index.html).
