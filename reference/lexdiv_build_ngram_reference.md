# Build an N-gram Reference from Whole-Document Chunks

Reads successive extractions and accumulates exact frequency and
document frequency without retaining every chunk's occurrence table.

## Usage

``` r
lexdiv_build_ngram_reference(
  sources,
  read_chunk,
  resource = lexdiv_resource_meta("caller_ngram_reference"),
  max_types = 1e6
)

# S3 method for class 'lexdiv_ngram_build'
print(x, ...)
```

## Arguments

- sources:

  Nonempty character vector of unique, nonempty UTF-8 source labels, in
  processing order.

- read_chunk:

  Function taking one source label and returning an unmodified
  `lexdiv_ngrams` result.

- resource:

  Resource metadata list created by
  [`lexdiv_resource_meta`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
  or supplied explicitly.

- max_types:

  Positive whole-number limit on accumulated distinct n-gram types
  across all requested `n`.

- x:

  A `lexdiv_ngram_build` object.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

A `lexdiv_ngram_build` list containing `reference` (a complete
`lexdiv_ngram_reference`), `sources`, `documents`, and `provenance`.
[`print()`](https://rdrr.io/r/base/print.html) displays reference totals
and returns `x` invisibly.

## See also

[`lexdiv_ngrams`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md),
[`lexdiv_compare_ngrams`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_ngrams.md)

## Examples

``` r
documents <- list(first = c("make", "a", "choice"),
                  second = c("make", "a", "plan"))
read <- function(id) {
  tokens <- data.frame(document_id = id, segment_id = "s",
    token_index = seq_along(documents[[id]]), term = documents[[id]])
  lexdiv_ngrams(tokens, "authored-v1")
}
built <- lexdiv_build_ngram_reference(names(documents), read)
built
#> <lexdiv_ngram_build: 2 source chunks; 2 documents; 5 n-gram types>
#>  n opportunities documents
#>  2             4         2
#>  3             2         2
```
