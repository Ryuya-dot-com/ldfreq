# Compare word frequencies in explicit target and reference corpora

Retain corpus denominators, document-level counts and source occurrences
beside descriptive G-squared and log-ratio scores. Return an exact
term's occurrences to a source-aligned concordance without redefining
the counted vocabulary.

## Usage

``` r
lexdiv_keyness(x, target, reference, preprocessing_id,
    term_col = "surface", keep = rep(TRUE, nrow(x$tokens)), min_count = 1L,
    max_tokens = 1e6)
lexdiv_keyness_concordance(x, term, window = 5L, max_cells = 1e6)
```

## Arguments

- x:

  For comparison, an unchanged complete
  [`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
  result. For concordance, a complete unchanged keyness result,
  including a legacy `keyness_compare()` record.

- target, reference:

  Nonempty vectors of unique known document IDs, with no ID shared
  between the two corpora. Other documents remain explicitly excluded.

- preprocessing_id:

  Nonblank caller label for the chosen preprocessing and selection
  policy. It does not execute preprocessing or prove comparability.

- term_col:

  Character token column to count using exact UTF-8 keys.

- keep:

  One nonmissing logical value per original token. Missing/blank
  selected terms are unavailable and retained in coverage accounting.

- min_count:

  Positive whole pooled-count threshold, returned as a flag only. It
  does not change the vocabulary, background counts or denominator.

- max_tokens:

  Positive whole-number bound on original input token rows.

- term:

  One exact term present in the saved comparison.

- window, max_cells:

  Context width and allocation bound passed to
  [`lexdiv_concordance`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md).

## Details

Vocabulary is the union of counted terms in both corpora. Each
denominator is all counted tokens in that corpus. Two-by-two cells are
term and other-token counts. G-squared is `2 * sum(O * log(O/E))`, with
zero observed-cell contributions zero and no continuity correction.
Signed G-squared uses the direction of the rate difference; log-ratio is
the base-2 logarithm of the target rate divided by the reference rate,
without smoothing. An observed zero produces an infinite log-ratio; an
empty corpus produces missing scores with reasons. Document counts and
missing terms remain distinct from pooled token counts.

These are descriptive scores, not p-values, significance decisions or
measures of writer proficiency. Corpus representativeness, writer/task
dependence and multiple testing require separate research decisions.
Identical source-text sequences across groups are flagged; near
duplicates are not detected.

Counting requires no optional package. Returning to KWIC uses optional
quanteda (\>= 4.5.0) and restricts endpoints to the exact counted term
before matching, preserving Unicode key distinctions. Source text is
retained in the complete result. Legacy `examples/keyness.R` still
defines its old names and output shapes. See [keyness comparison
guide](https://ryuya-dot-com.github.io/ldfreq/articles/keyness-comparison.html).

## Value

`lexdiv_keyness()` returns a plain list with `results` (two-by-two
cells, totals, expected cells, per-1000 rates, log-ratio, G-squared,
signed G-squared, direction, document frequencies, threshold flag and
status), `totals`, `documents`, `document_counts`, `occurrences`,
`token_audit`, complete `source`, `settings`, `provenance` and
`integrity_sha256`. Absent document-term rows in the sparse
`document_counts` table must be interpreted with document coverage.

`lexdiv_keyness_concordance()` returns `comparison_id`, `term` and
`search`, a `lexdiv_concordance` result usable with
[`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Examples

``` r
segments <- data.frame(document_id = c("target", "reference"), segment_id = "s1",
  text = c("a a b", "a b b"))
tokens <- data.frame(document_id = rep(segments$document_id, each = 3),
  segment_id = "s1", token_index = rep(1:3, 2), surface = c("a", "a", "b", "a", "b", "b"))
source <- lexdiv_import_annotations(tokens, segments, list(language = "en",
  analyzer = "authored", analyzer_version = "1", dictionary = "none",
  dictionary_version = "none", unit = "supplied tokens", normalization = "none"))
comparison <- lexdiv_keyness(source, "target", "reference", "surface-all")
comparison$results[c("term", "target_count", "reference_count", "log_ratio")]
#>   term target_count reference_count log_ratio
#> 1    a            2               1         1
#> 2    b            1               2        -1
if (requireNamespace("quanteda", quietly = TRUE)) {
  evidence <- lexdiv_keyness_concordance(comparison, "a")
  evidence$search$occurrences
}
#>   query_id document_id segment_id from to document_from document_to start end
#> 1  feature      target         s1    1  1             1           1     1   1
#> 2  feature      target         s1    2  2             2           2     3   3
#> 3  feature   reference         s1    1  1             1           1     1   1
#>   pre keyword post matched_terms left_tokens right_tokens
#> 1           a  a b             a                     a, b
#> 2  a        a    b             a           a            b
#> 3           a  b b             a                     b, b
#>                                                      occurrence_id
#> 1 4ec6c37193104e90e9166d30bccd65daedde5cc5366753be792bbde5eba7c685
#> 2 51944ee3acabdfe00295d12799ccef0890f25477ad2ed84781c1004f2d6967b0
#> 3 d1b9abecf37571c303a07a04a4be6f02d73d1e8e16b29d8a66ac7043ad906ae9
```
