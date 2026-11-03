# Compare N-gram References on the Same Target Items

Applies multiple reference frequency tables to one unchanged target
extraction. Reports each reference's coverage and available-value mean,
then compares rates on the items with defined values in every reference.

## Usage

``` r
lexdiv_compare_ngrams(x, references, baseline = NULL, max_rows = 1e6)

# S3 method for class 'lexdiv_ngram_comparison'
print(x, ...)
```

## Arguments

- x:

  For `lexdiv_compare_ngrams()`, an unmodified `lexdiv_ngrams` result.
  For [`print()`](https://rdrr.io/r/base/print.html), a
  `lexdiv_ngram_comparison` object.

- references:

  A plain named list of at least two unmodified `lexdiv_ngram_reference`
  results.

- baseline:

  One name in `references`. Defaults to the first reference.

- max_rows:

  Positive whole-number ceiling on combined lookup and summary rows
  across references, checked before profiling.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

A `lexdiv_ngram_comparison` list containing `summary`, `lookup`,
`documents`, `references`, and `provenance` (with `content_sha256`).
[`print()`](https://rdrr.io/r/base/print.html) displays up to 12 summary
rows and returns `x` invisibly.

## See also

[`lexdiv_ngrams`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md),
[`lexdiv_build_ngram_reference`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_build_ngram_reference.md)

## Examples

``` r
tokens <- data.frame(document_id = "item", segment_id = "s",
  token_index = 1:3, term = c("make", "a", "choice"))
target <- lexdiv_ngrams(tokens, "authored-v1", n = 2)
resource <- lexdiv_resource_meta(
  "authored_demo",
  lookup_unit = "adjacent_surface_ngram"
)
counts <- data.frame(n = 2L, term1 = c("make", "a"),
  term2 = c("a", "decision"), term3 = NA_character_, count = c(3, 2),
  document_count = c(2, 1))
totals <- data.frame(n = 2L, opportunities = 5, documents = 2)
full <- lexdiv_ngram_reference(counts, resource, totals, "authored-v1", TRUE)
partial <- lexdiv_ngram_reference(counts[1, ], resource, totals, "authored-v1", FALSE)
compared <- lexdiv_compare_ngrams(target, list(full = full, partial = partial))
compared
#> <lexdiv_ngram_comparison: 2 references (baseline=full); 4 summary rows>
#>  reference_id document_id n weighting value_coverage common_coverage
#>          full        item 2     token            1.0             0.5
#>          full        item 2      type            1.0             0.5
#>       partial        item 2     token            0.5             0.5
#>       partial        item 2      type            0.5             0.5
#>  common_mean_frequency_per_million difference_from_baseline comparison_status
#>                              6e+05                        0                ok
#>                              6e+05                        0                ok
#>                              6e+05                        0                ok
#>                              6e+05                        0                ok
```
