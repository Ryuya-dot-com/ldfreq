# Coverage-Aware TUBELEX Frequency and Prevalence Profile

Look up surface-form frequency, video prevalence, and channel prevalence
for one document or a multi-document corpus in the byte-pinned
TUBELEX-EN Treebank aggregate downloaded separately via
[`lexdiv_download_resources`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_resources.md).

## Usage

``` r
tubelex_profile(
  x,
  normalization = "tubelex",
  tokenization_mismatch = "error",
  id_col = "document_id",
  term_col = "terms",
  max_rows = 1e+06,
  cache_dir = NULL
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

- x:

  For a single document, an ordered character vector of Treebank-aligned
  terms or a `lexdiv_tokenization` object (with
  `tokenization_mismatch = "allow"`). For multiple documents, a named
  list of term vectors/tokenizations, a `lexdiv_tokenization_batch`
  object, or a data frame/tibble with `id_col` and `term_col`. For
  [`print()`](https://rdrr.io/r/base/print.html) and
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html), a
  `tubelex_profile` or `tubelex_profile_batch` object.

- normalization:

  `"tubelex"`, `"tubelex_apostrophe"`, or `"identity"`.

- tokenization_mismatch:

  `"error"` (default) or `"allow"`.

- id_col, term_col:

  Column names for multi-document data-frame input.

- max_rows:

  Positive whole-number row bound checked before resource loading.

- cache_dir:

  Optional directory containing downloaded optional resources.

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

For a single document, `tubelex_profile()` returns a `tubelex_profile`
list containing `status`, `failure_reason`, `summary`, `lookup`,
`coverage`, `provenance`, and `diagnostics`.

For multiple documents, `tubelex_profile()` returns a structured
`tubelex_profile_batch` object containing document-major `summary`,
`lookup`, and `coverage` tables alongside `profiles` (the input-ordered
named list of complete per-document `tubelex_profile` objects),
`provenance`, and `diagnostics`.

## See also

[`tubelex_diagnostics`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/tubelex_diagnostics.md),
[`lexdiv_download_resources`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_resources.md)

## Examples

``` r
if (all(lexdiv_resource_info("tubelex")$available)) {
  tokens <- c("I", "do", "n't", "think", "it", "'s", "John", "'s", "book")
  profile <- tubelex_profile(tokens)
  print(profile)

  batch <- tubelex_profile(list(d1 = tokens, d2 = c("hello", "world")))
  print(batch)
  plot(batch)
}
```
