# Run a saved recipe through the R calculation APIs

No references are downloaded. Requested reference files and engine
versions must match the recipe. The record contains source texts, tokens
and optional document metadata; save it according to the study's access
rules.

## Usage

``` r
lexdiv_run_recipe(
  documents,
  recipe,
  id_col = "document_id",
  text_col = "text",
  metadata = NULL,
  condition_id = "analysis",
  allow_engine_mismatch = FALSE,
  cache_dir = NULL
)
# S3 method for class 'lexdiv_analysis'
print(x, ...)
```

## Arguments

- documents:

  Named character vector or ID/text data frame, as for
  [`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_preprocessing.md).

- recipe:

  A recipe from
  [`lexdiv_recipe()`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_recipe.md)
  or
  [`lexdiv_read()`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_write.md).

- id_col, text_col:

  Input column names.

- metadata:

  Optional document metadata, as for
  [`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_preprocessing.md).

- condition_id:

  A label for this analysis condition, not measurement identity.

- allow_engine_mismatch:

  Logical; if `TRUE`, allows executing a recipe saved under an older
  package/contract version while recording actual runtime versions and
  issuing a cross-engine warning when `stringi`/ICU differs.

- cache_dir:

  Optional directory containing downloaded optional resources.

- x:

  An analysis record for compact display.

- ...:

  Unused additional arguments.

## Value

A `lexdiv_analysis` containing the recipe, calculation environment,
source texts, complete metric results, preprocessing, resource profiles
and saved method descriptions/citations. Its `$analysis` can be passed
to
[`lexdiv_study_table()`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_study_table.md),
including after JSON restoration. The objects in `$profiles` support
[`nj8_diagnostics`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/nj8_diagnostics.md),
[`tubelex_diagnostics`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/tubelex_diagnostics.md)
and TUBELEX batch plots after restoration. NJ8 batch profiles do not
have a plot method.

## Examples

``` r
recipe <- lexdiv_recipe(lexdiv_plan(presets = character(), specs = lexdiv_spec("ttr")))
run <- lexdiv_run_recipe(c(doc1 = "A small test text."), recipe)
run$analysis$results[, c("document_id", "metric_id", "value")]
#> <lexdiv_profile_batch_results: 1 document; 1 specification result; schema unknown>
#>   document_id metric_id value
#> 1        doc1       ttr     1
```
