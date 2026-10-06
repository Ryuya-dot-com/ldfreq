# Diagnose NJ8 non-matches and lexical-unit transformations

Counts unmatched lookup terms and surface-to-unit mappings across an
existing NJ8 profile. Preserves coverage, exclusions and
resource/preprocessing provenance without running tokenization,
annotation or lookup again.

## Usage

``` r
nj8_diagnostics(x)
```

## Arguments

- x:

  An unmodified result of
  [`nj8_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  or
  [`nj8_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md).
  A single profile receives the local document ID `"document_1"`; batch
  document IDs are preserved.

## Value

A plain list with the following components:

- unmatched_terms:

  A data frame with `lookup_term`, `token_count`, and `document_count`.
  Counts use eligible unmatched occurrences and distinct documents
  containing each exact lookup term.

- unit_mappings:

  A data frame with grouping keys `surface_term`, `term`, `lookup_term`,
  `matched`; counts `token_count`, `document_count`; and logical flags
  `unit_changed`, `lookup_changed`, `numeric_introduced`,
  `whitespace_introduced`.

- coverage:

  The original per-document coverage data frame. Single-profile coverage
  is converted to a one-row data frame with `document_id` first. Empty
  and wholly excluded documents remain visible here.

- exclusion_reasons:

  The original exclusion counts with `document_id`. Tokens excluded
  because of missing annotations do not become unmatched terms.

- provenance:

  The unchanged source profile provenance, including resource identity,
  selected unit, normalization and the resource citation.

- document_provenance:

  Document IDs, input sources, selected units and preprocessing
  references. The batch table is preserved; a corresponding one-row
  table is constructed for a single profile.

The two count tables are sorted by decreasing token count, with ties in
first occurrence order. Counts have type double. Empty tables retain the
same columns and types. Counts are pooled over documents, not averages
of document rates.

## Details

`unit_changed` compares the recorded surface and selected unit exactly.
`lookup_changed` compares the selected unit and final lookup key; this
can reflect normalization or a flemma headword-conflict decision.
`numeric_introduced` indicates a selected unit consisting entirely of
Unicode Number characters when its surface does not. It does not detect
all numeric expressions such as decimals. `whitespace_introduced`
indicates Unicode whitespace in the selected unit when its surface has
none. Neither flag changes, splits, drops or corrects the unit.

These flags describe string transformations, not annotation errors.
Unmatched terms may include inflected forms, contractions, proper names,
compounds, spelling variants, errors, or words absent from the
reference; the function does not classify them as difficult or infer
proficiency. With preselected character-vector inputs, the original
surface-to-lemma mapping is unavailable: the supplied units occupy both
fields, so unchanged flags do not validate an upstream annotation
process. Retain `x$lookup` for token positions and document IDs, and
original tokenization objects for excluded-token details.

No resource or model is loaded, downloaded or modified. Basic input
structure and token-count consistency are checked; this is not a
cryptographic integrity check of a saved profile. The result is an audit
summary, not a replacement for the full profile or a standalone analysis
of all annotation failures.

## See also

[`nj8_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md),
[`lexdiv_preprocessing`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)

## Examples

``` r
prepared <- lexdiv_tokenize_batch(c(
  essay_a = "Students have part-time jobs.",
  essay_b = "Students learn from jobs."
), tokenizer = "english", case = "lower")
profile <- nj8_profile_batch(prepared, unit = "surface")
audit <- nj8_diagnostics(profile)
audit$unmatched_terms
#>   lookup_term token_count document_count
#> 1    students           2              2
#> 2        jobs           2              2
#> 3   part-time           1              1
audit$coverage
#>   document_id input_tokens eligible_tokens excluded_tokens selection_coverage
#> 1     essay_a            4               4               0                  1
#> 2     essay_b            4               4               0                  1
#>   matched_tokens off_list_tokens token_coverage eligible_types matched_types
#> 1              1               3           0.25              4             1
#> 2              2               2           0.50              4             2
#>   off_list_types type_coverage
#> 1              3          0.25
#> 2              2          0.50

# Authored annotation example: flags record a change, not its correctness.
text <- lexdiv_tokenize("Students second", case = "lower")
annotated <- lexdiv_lemmatize(text, lemmas = c("student", "2"),
  backend_id = "authored-example", backend_version = "1")
audit <- nj8_diagnostics(nj8_profile(annotated, unit = "lemma"))
audit$unit_mappings[audit$unit_mappings$numeric_introduced, ]
#>   surface_term term lookup_term matched token_count document_count unit_changed
#> 2       second    2           2   FALSE           1              1         TRUE
#>   lookup_changed numeric_introduced whitespace_introduced
#> 2          FALSE               TRUE                 FALSE
```
