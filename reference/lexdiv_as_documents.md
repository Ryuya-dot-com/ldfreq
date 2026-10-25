# Convert token containers to named documents

Preserves document identity and token order while converting supported
containers to the input used by
[`lexdiv_metrics_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md).

## Usage

``` r
lexdiv_as_documents(
  x,
  document_col = "document_id",
  token_col = "token"
)
```

## Arguments

- x:

  A named list of plain character token vectors, a data frame with one
  token per row, or a quanteda tokens object. Raw text is not tokenized.

- document_col:

  The document-ID column in data-frame input.

- token_col:

  The plain character token column in data-frame input.

## Value

A plain named list of plain character vectors, preserving document and
token order.

## Details

`lexdiv_as_documents()` groups tidy token rows by first document
appearance while preserving row order within each document. A quanteda
tokens object is converted through its registered
[`as.list()`](https://rdrr.io/r/base/list.html) method, so ldfreq does
not add a runtime dependency on quanteda. Raw text is not tokenized by
this adapter. Each selected ID or token column must occur exactly once.
Empty lists and zero-row token tables return the same named empty list,
accepted by both
[`lexdiv_metrics_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
and
[`lexdiv_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md).

A one-token-per-row table has no row for a document with zero selected
tokens. Retain the original document roster and represent those
documents explicitly as named
[`character()`](https://rdrr.io/r/base/character.html) vectors before
batch calculation. The adapter cannot recover IDs absent from the
supplied table. For raw text, including empty texts,
[`lexdiv_metrics_text_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
retains the declared IDs.

## See also

[`lexdiv_metrics_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md),
[`lexdiv_metrics_text_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
for raw text.

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
