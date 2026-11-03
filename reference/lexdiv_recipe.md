# Reusable raw-text analysis recipes

A recipe freezes the resolved method parameters, preprocessing and
optional reference identities. Schema 1 supports raw text, surface forms
and all word tokens. External annotations, lemma/flemma reconstruction
and custom resources are outside this schema. Use the existing
annotation APIs for those analyses. Recipes contain no source text. JSON
needs the optional package `jsonlite`.

## Usage

``` r
lexdiv_recipe(
  plan = lexdiv_plan(),
  normalization = "NFC",
  case = "lower",
  keep_numbers = FALSE,
  tokenizer = "english",
  resources = character(),
  tubelex_tokenization_mismatch = "error"
)
# S3 method for class 'lexdiv_recipe'
print(x, ...)
```

## Arguments

- plan:

  A normalized
  [`lexdiv_plan()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md).
  Presets are expanded before saving.

- normalization, case, keep_numbers, tokenizer:

  See
  [`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md).

- resources:

  Unique names from `c("nj8", "tubelex")`, or
  [`character()`](https://rdrr.io/r/base/character.html). Only the
  package's pinned, already downloaded resources are supported.

- tubelex_tokenization_mismatch:

  `"error"` or `"allow"`. The built-in tokenizer differs from TUBELEX
  segmentation; including TUBELEX requires explicit `"allow"`, recorded
  as a segmentation-sensitivity analysis.

- x:

  A recipe or analysis record for compact display.

- ...:

  Unused additional arguments.

## Value

A `lexdiv_recipe` list with resolved requests and environment/resource
requirements. Save with
[`lexdiv_write()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_write.md)
and restore with
[`lexdiv_read()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_write.md).

## Examples

``` r
recipe <- lexdiv_recipe(lexdiv_plan(presets = character(),
  specs = lexdiv_spec("mattr", list(window_length = 5))))
if (requireNamespace("jsonlite", quietly = TRUE)) {
  path <- tempfile(fileext = ".json")
  lexdiv_write(recipe, path)
  restored <- lexdiv_read(path)
  stopifnot(identical(recipe, restored))
  unlink(path)
}
```
