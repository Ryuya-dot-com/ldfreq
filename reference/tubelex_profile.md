# Coverage-Aware TUBELEX Frequency and Prevalence Profile

Look up surface-form frequency, video prevalence, and channel prevalence
in the byte-pinned TUBELEX-EN Treebank aggregate downloaded separately
via
[`lexdiv_download_resources`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_resources.md).

## Usage

``` r
tubelex_profile(
  terms,
  normalization = "tubelex",
  tokenization_mismatch = "error"
)

tubelex_profile_batch(
  documents,
  normalization = "tubelex",
  tokenization_mismatch = "error",
  id_col = "document_id",
  terms_col = "terms",
  max_rows = 1e6
)

# S3 method for class 'tubelex_profile'
print(x, ...)

# S3 method for class 'tubelex_profile_batch'
print(x, ...)

# S3 method for class 'tubelex_profile_batch'
plot(
  x,
  weighting = c("token", "type"),
  col = "#0072B2",
  main = NULL,
  ylab = NULL,
  ...,
  monochrome = FALSE
)
```

## Arguments

- terms:

  An ordered character vector of Treebank-aligned terms, or a
  `lexdiv_tokenization` object with `tokenization_mismatch = "allow"`.

- normalization:

  `"tubelex"`, `"tubelex_apostrophe"`, or `"identity"`.

- tokenization_mismatch:

  `"error"` (default) or `"allow"`.

- documents:

  Named list of term vectors/tokenizations, or a data frame/tibble with
  `id_col` and `terms_col`.

- id_col, terms_col:

  Column names for data-frame input.

- max_rows:

  Positive whole-number row bound checked before resource loading.

- x:

  A `tubelex_profile` or `tubelex_profile_batch` object.

- weighting:

  Weighting (`"token"` or `"type"`) for batch coverage barplot.

- col, main, ylab:

  Base-R barplot styling arguments.

- monochrome:

  Logical switch for black/grey barplot styling.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html) or
  [`graphics::barplot()`](https://rdrr.io/r/graphics/barplot.html).

## Value

`tubelex_profile()` returns a `tubelex_profile` list containing
`status`, `failure_reason`, `summary`, `lookup`, `coverage`,
`provenance`, and `diagnostics`.

`tubelex_profile_batch()` returns a structured `tubelex_profile_batch`
object containing document-major `summary`, `lookup`, and `coverage`
tables alongside `profiles` (the input-ordered named list of complete
per-document `tubelex_profile` objects), `provenance`, and
`diagnostics`.

## See also

[`tubelex_diagnostics`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_diagnostics.md),
[`lexdiv_download_resources`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_resources.md)

## Examples

``` r
if (all(lexdiv_resource_info("tubelex")$available)) {
  tokens <- c("I", "do", "n't", "think", "it", "'s", "John", "'s", "book")
  profile <- tubelex_profile(tokens)
  print(profile)

  batch <- tubelex_profile_batch(list(d1 = tokens, d2 = c("hello", "world")))
  print(batch)
  plot(batch)
}
```
