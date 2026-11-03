# Add Flemmas from a Caller-Supplied AntBNC Lemma List

Maps token surface forms to family lemmas (flemmas) using a local AntBNC
lemma-list file on either a single tokenization (`lexdiv_flemmatize()`)
or a named batch of tokenizations (`lexdiv_flemmatize_batch()`).

## Usage

``` r
lexdiv_flemmatize(
  x,
  resource,
  overrides = NULL,
  normalization = "nfkc_lower",
  resource_version = NULL,
  override_version = NULL
)

lexdiv_flemmatize_batch(
  documents,
  resource,
  overrides = NULL,
  normalization = "nfkc_lower",
  resource_version = NULL,
  override_version = NULL
)
```

## Arguments

- x:

  An object created by
  [`lexdiv_tokenize`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md).

- documents:

  A named list of `lexdiv_tokenization` objects (such as from
  [`lexdiv_tokenize_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)).

- resource:

  Path to a caller-supplied AntBNC lemma-list text file in
  `headword<TAB>-><TAB>form...` format.

- overrides:

  Optional data frame with unique `form` and `flemma` columns.

- normalization:

  `"nfkc_lower"` (default) or `"identity"`.

- resource_version, override_version:

  Optional path-free caller version labels.

## Value

`lexdiv_flemmatize()` returns a `lexdiv_tokenization` object with
`flemma`, `flemma_matched`, and `flemma_match_rule` columns.
`lexdiv_flemmatize_batch()` returns an input-ordered named list of
flemma-annotated `lexdiv_tokenization` objects.

## See also

[`lexdiv_preprocessing`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
[`nj8_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)

## Examples

``` r
fixture <- tempfile(fileext = ".txt")
writeLines(c("cat\t->\tcat\tcats", "see\t->\tsaw\tsee", "the\t->\tthe"),
  fixture, useBytes = TRUE)

batch <- lexdiv_tokenize_batch(c(d1 = "The cats saw.", d2 = "Cats see."))
flem_batch <- lexdiv_flemmatize_batch(
  batch, fixture, resource_version = "synthetic-help-fixture"
)
unlink(fixture)

lexdiv_metrics_text_batch(flem_batch, unit = "flemma", metrics = "ttr")$results
#> <lexdiv_batch_results: 2 documents; 2 metric records; schema 0.1.0>
#>   document_id metric_id value status missing_reason N V below_quality_floor
#> 1          d1       ttr     1     ok           <NA> 3 3               FALSE
#> 2          d2       ttr     1     ok           <NA> 2 2               FALSE
```
