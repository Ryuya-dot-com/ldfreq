# Versioned Raw-Text Preprocessing for Lexical-Diversity Metrics

Compute lexical diversity directly from one raw text or a multi-document
table with `lexdiv_metrics_text()`, or prepare reusable
`lexdiv_tokenization` and `lexdiv_tokenization_batch` objects with
`lexdiv_tokenize()` and `lexdiv_lemmatize()`. By default, raw English
text uses `case = "lower"` and `tokenizer = "english"` while recording
every setting in provenance.

## Usage

``` r
lexdiv_tokenize(
  x,
  normalization = "NFC",
  case = "lower",
  keep_numbers = FALSE,
  tokenizer = "english",
  id_col = "document_id",
  text_col = "text"
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
  plan = NULL,
  id_col = "document_id",
  text_col = "text",
  max_rows = 1e+06,
  metadata = NULL,
  retain_token_audit = TRUE
)

# S3 method for class 'lexdiv_tokenization'
print(x, ...)

# S3 method for class 'lexdiv_text_results'
print(x, ...)

# S3 method for class 'lexdiv_text_batch_results'
print(x, ...)
```

## Arguments

- x:

  For `lexdiv_tokenize()` and `lexdiv_metrics_text()`, one unnamed raw
  UTF-8 string, a named character vector of raw texts, an ID/text data
  frame or tibble, a single `lexdiv_tokenization` object, or a named
  list / `lexdiv_tokenization_batch` of tokenizations. For
  `lexdiv_lemmatize()`, a single `lexdiv_tokenization` or named batch of
  tokenizations. For [`print()`](https://rdrr.io/r/base/print.html), the
  result object.

- normalization:

  Unicode normalization: `"NFC"`, `"NFKC"`, or `"none"`.

- case:

  Either locale-fixed English `"lower"` (default) or `"preserve"`.

- keep_numbers:

  Whether recognized numeric tokens are retained.

- tokenizer:

  `"english"` (default) or `"unicode"`.

- id_col, text_col:

  Column names selecting unique document IDs and raw text strings in
  multi-document data-frame inputs.

- method:

  Lemma source: `"supplied"` or `"textstem"`.

- lemmas, upos:

  Aligned character vector(s) for a single tokenization, or named
  list(s) matching document IDs for a batch of tokenizations.

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
  [`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_metrics.md)
  when `plan` is `NULL`.

- plan:

  Optional normalized request plan from
  [`lexdiv_plan`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_plan.md).

- max_rows:

  Positive whole-number row ceiling for multi-document execution.

- metadata:

  Optional document-metadata data frame keyed by `id_col` for
  multi-document runs.

- retain_token_audit:

  Logical; set `FALSE` on very large multi-document corpora to omit
  per-token audit rows while keeping metric rows and provenance.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

`lexdiv_tokenize()` and `lexdiv_lemmatize()` return a
`lexdiv_tokenization` object for single-document input or an
input-ordered `lexdiv_tokenization_batch` named list for multi-document
input. `lexdiv_metrics_text()` returns a `lexdiv_text_results` list
(single document) or `lexdiv_text_batch_results` list (multiple
documents) with `results`, `token_audit`, and `preprocessing`.

## See also

[`lexdiv_flemmatize`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_flemmatize.md),
[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_metrics.md),
[`lexdiv_as_annotations`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_import_annotations.md)

## Examples

``` r
# 1. Default English lowercase preprocessing on one or several texts:
single <- lexdiv_metrics_text("Cats chase cats and dogs.", metrics = "ttr")
single$results  # N = 5, V = 4, TTR = 0.8
#> <lexdiv_results: 1 metric; contract 0.2.0>
#>   metric_id value status missing_reason N V below_quality_floor
#> 1       ttr   0.8     ok           <NA> 5 4               FALSE

texts <- c(
  essay_a = "Cats chase cats and dogs.",
  essay_b = "The reader reads a story.",
  empty = ""
)
result <- lexdiv_metrics_text(texts, metrics = "ttr")
result$results  # TTR = 0.8, 1, NA
#> <lexdiv_batch_results: 3 documents; 3 metric records; schema 0.1.0>
#>   document_id metric_id value  status missing_reason N V below_quality_floor
#> 1     essay_a       ttr   0.8      ok           <NA> 5 4               FALSE
#> 2     essay_b       ttr   1.0      ok           <NA> 5 5               FALSE
#> 3       empty       ttr    NA missing    empty_input 0 0                TRUE

# 2. Plan-based execution directly from raw texts:
plan <- lexdiv_plan(presets = character(), specs = list(
  lexdiv_spec("ttr", request_id = "ttr")
))
planned <- lexdiv_metrics_text(texts, plan = plan)
planned$results
#> <lexdiv_profile_batch_results: 3 documents; 3 specification results; schema 0.1.0>
#>   document_id request_id metric_id value  status missing_reason N V
#> 1     essay_a        ttr       ttr   0.8      ok           <NA> 5 4
#> 2     essay_b        ttr       ttr   1.0      ok           <NA> 5 5
#> 3       empty        ttr       ttr    NA missing    empty_input 0 0
#>   below_quality_floor
#> 1               FALSE
#> 2               FALSE
#> 3                TRUE

# 3. Multi-document tokenization and lemmatization through the same functions:
toks <- lexdiv_tokenize(c(d1 = "Cats ran.", d2 = "Dogs barked."))
annotated_batch <- lexdiv_lemmatize(
  toks,
  lemmas = list(d1 = c("cat", "run"), d2 = c("dog", "bark")),
  backend_id = "example-lemmas",
  backend_version = "1"
)
lexdiv_metrics_text(annotated_batch, unit = "lemma", metrics = "ttr")
#> <lexdiv_text_batch_results: 2 documents; 4 audited tokens>
#> <lexdiv_batch_results: 2 documents; 2 metric records; schema 0.1.0>
#>   document_id metric_id value status missing_reason N V below_quality_floor
#> 1          d1       ttr     1     ok           <NA> 2 2               FALSE
#> 2          d2       ttr     1     ok           <NA> 2 2               FALSE
```
