# Add Flemmas from a Caller-Supplied AntBNC Lemma List

Maps token surface forms to family lemmas (flemmas) using a local AntBNC
lemma-list file on either a single `lexdiv_tokenization` object or a
named batch of tokenizations.

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
```

## Arguments

- x:

  A single `lexdiv_tokenization` object or a named list /
  `lexdiv_tokenization_batch` of tokenizations created by
  [`lexdiv_tokenize`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_preprocessing.md).

- resource:

  Path to a caller-supplied AntBNC lemma-list text file.

- overrides:

  Optional data frame with unique `form` and `flemma` columns.

- normalization:

  `"nfkc_lower"` (default) or `"identity"`.

- resource_version, override_version:

  Optional path-free caller version labels.

## Value

For a single tokenization, a `lexdiv_tokenization` object with `flemma`,
`flemma_matched`, and `flemma_match_rule` columns. For a batch of
tokenizations, an input-ordered `lexdiv_tokenization_batch` named list
of flemma-annotated `lexdiv_tokenization` objects (parsing the AntBNC
resource once across the batch).

## See also

[`lexdiv_preprocessing`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_preprocessing.md),
[`nj8_profile`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/nj8_profile.md)

## Examples

``` r
fixture <- tempfile(fileext = ".txt")
writeLines(c("cat\t->\tcat\tcats", "see\t->\tsaw\tsee", "the\t->\tthe"),
  fixture, useBytes = TRUE)

batch <- lexdiv_tokenize(c(d1 = "The cats saw.", d2 = "Cats see."))
flem_batch <- lexdiv_flemmatize(
  batch, fixture, resource_version = "synthetic-help-fixture"
)
unlink(fixture)

lexdiv_metrics_text(flem_batch, unit = "flemma", metrics = "ttr")$results
#> <lexdiv_batch_results: 2 documents; 2 metric records; schema 0.1.0>
#>   document_id metric_id value status missing_reason N V below_quality_floor
#> 1          d1       ttr     1     ok           <NA> 3 3               FALSE
#> 2          d2       ttr     1     ok           <NA> 2 2               FALSE
```
