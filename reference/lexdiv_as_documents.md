# Convert Token Containers to Named Documents

Preserves document identity and token order while converting supported
containers to the named-list input used by
[`lexdiv_metrics_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md).

## Usage

``` r
lexdiv_as_documents(
  x,
  id_col = "document_id",
  token_col = "token"
)
```

## Arguments

- x:

  A named list of character token vectors, a data frame or tibble with
  one token per row, or a quanteda tokens object. Raw text is not
  tokenized.

- id_col:

  The document-ID column in data-frame input.

- token_col:

  The plain character token column in data-frame input.

## Value

A plain named list of character vectors, preserving document and token
order.

## See also

[`lexdiv_metrics_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md),
[`lexdiv_metrics_text_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)

## Examples

``` r
tokens <- data.frame(document_id = c("a", "a", "b", "b"),
  token = c("one", "two", "three", "three"))
documents <- lexdiv_as_documents(tokens)
lexdiv_metrics_batch(documents, metrics = "ttr")
#> <lexdiv_batch_results: 2 documents; 2 metric records; schema 0.1.0>
#>   document_id metric_id value status missing_reason N V below_quality_floor
#> 1           a       ttr   1.0     ok           <NA> 2 2               FALSE
#> 2           b       ttr   0.5     ok           <NA> 2 1               FALSE
```
