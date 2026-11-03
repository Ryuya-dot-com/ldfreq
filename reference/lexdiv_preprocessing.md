# Versioned Raw-Text Preprocessing for Lexical-Diversity Metrics

Compute lexical diversity directly from raw text with
`lexdiv_metrics_text()`, or prepare reusable `lexdiv_tokenization`
objects with `lexdiv_tokenize()`, `lexdiv_lemmatize()`, and
`lexdiv_lemmatize_batch()`. By default, raw English text uses
`case = "lower"` and `tokenizer = "english"` while recording every
setting in provenance.

## Usage

``` r
lexdiv_tokenize(
  text,
  normalization = "NFC",
  case = "lower",
  keep_numbers = FALSE,
  tokenizer = "english"
)

lexdiv_lemmatize(
  x,
  method = "supplied",
  lemmas = NULL,
  upos = NULL,
  backend_id = NULL,
  backend_version = NULL,
  upos_backend_id = NULL,
  upos_backend_version = NULL,
  dictionary = NULL,
  dictionary_id = NULL,
  dictionary_version = NULL
)

lexdiv_lemmatize_batch(
  documents,
  method = "supplied",
  lemmas = NULL,
  upos = NULL,
  backend_id = NULL,
  backend_version = NULL,
  upos_backend_id = NULL,
  upos_backend_version = NULL,
  dictionary = NULL,
  dictionary_id = NULL,
  dictionary_version = NULL
)

lexdiv_metrics_text(
  x,
  unit = "surface",
  word_inclusion = "all",
  normalization = "NFC",
  case = "lower",
  keep_numbers = FALSE,
  metrics = setdiff(lexdiv_metric_ids(), c("expected_ttr_d", "mtld_ma")),
  segment_length = 50L,
  window_length = 50L,
  mtld_threshold = 0.72,
  sample_size = 42L,
  expected_ttr_sample_sizes = 35:50,
  tokenizer = "english",
  plan = NULL
)

# S3 method for class 'lexdiv_tokenization'
print(x, ...)

# S3 method for class 'lexdiv_text_results'
print(x, ...)
```

## Arguments

- text:

  One plain valid-UTF-8 character string.

- normalization:

  Unicode normalization: `"NFC"`, `"NFKC"`, or `"none"`.

- case:

  Either locale-fixed English `"lower"` (default) or `"preserve"`.

- keep_numbers:

  Whether recognized numeric tokens are retained.

- tokenizer:

  `"english"` (default) or `"unicode"`.

- x:

  A `lexdiv_tokenization` object, one raw string (for
  `lexdiv_metrics_text()`), or the printed result object.

- documents:

  Named list of `lexdiv_tokenization` objects (such as from
  [`lexdiv_tokenize_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)).

- method:

  Lemma source: `"supplied"` or `"textstem"`.

- lemmas, upos:

  Aligned character vector(s) for `lexdiv_lemmatize()`, or named list(s)
  matching `documents` for `lexdiv_lemmatize_batch()`.

- backend_id, backend_version, upos_backend_id, upos_backend_version:

  Path-free backend identifiers for caller-supplied annotations.

- dictionary, dictionary_id, dictionary_version:

  Optional two-column dictionary and identifiers for
  `method = "textstem"`.

- unit:

  `"surface"`, `"lemma"`, or `"flemma"`.

- word_inclusion:

  `"all"` or `"content"` (UPOS ADJ/ADV/NOUN/PROPN/VERB).

- metrics, segment_length, window_length, mtld_threshold, sample_size,
  expected_ttr_sample_sizes:

  Metric arguments forwarded to
  [`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  when `plan` is `NULL`.

- plan:

  Optional normalized request plan from
  [`lexdiv_plan`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md).

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

`lexdiv_tokenize()` and `lexdiv_lemmatize()` return a
`lexdiv_tokenization` object. `lexdiv_lemmatize_batch()` returns an
input-ordered named list of `lexdiv_tokenization` objects.
`lexdiv_metrics_text()` returns a `lexdiv_text_results` list with
`results`, `token_audit`, and `preprocessing`.

## See also

[`lexdiv_flemmatize`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md),
[`lexdiv_text_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md),
[`lexdiv_as_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)

## Examples

``` r
# 1. Default English lowercase preprocessing:
result <- lexdiv_metrics_text("Cats chase cats and dogs.", metrics = "ttr")
result$results  # N = 5, V = 4, TTR = 0.8
#> <lexdiv_results: 1 metric; contract 0.2.0>
#>   metric_id value status missing_reason N V below_quality_floor
#> 1       ttr   0.8     ok           <NA> 5 4               FALSE

# 2. Plan-based execution directly from raw text:
plan <- lexdiv_plan(presets = character(), specs = list(
  lexdiv_spec("ttr", request_id = "ttr")
))
lexdiv_metrics_text("Cats chase cats and dogs.", plan = plan)$results
#> <lexdiv_profile_results: 1 specification; schema 0.1.0>
#>   request_id metric_id value status missing_reason N V below_quality_floor
#> 1        ttr       ttr   0.8     ok           <NA> 5 4               FALSE

# 3. Supplied lemmas and batch lemmatization:
toks <- lexdiv_tokenize_batch(c(d1 = "Cats ran.", d2 = "Dogs barked."))
annotated_batch <- lexdiv_lemmatize_batch(
  toks,
  lemmas = list(d1 = c("cat", "run"), d2 = c("dog", "bark")),
  backend_id = "example-lemmas",
  backend_version = "1"
)
lexdiv_metrics_text_batch(annotated_batch, unit = "lemma", metrics = "ttr")
#> <lexdiv_text_batch_results: 2 documents; 4 audited tokens>
#> <lexdiv_batch_results: 2 documents; 2 metric records; schema 0.1.0>
#>   document_id metric_id value status missing_reason N V below_quality_floor
#> 1          d1       ttr     1     ok           <NA> 2 2               FALSE
#> 2          d2       ttr     1     ok           <NA> 2 2               FALSE
```
