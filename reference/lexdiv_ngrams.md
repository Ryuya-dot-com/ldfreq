# Adjacent Bigrams and Trigrams with Local Reference Frequencies

Extracts adjacent two- and three-term sequences within explicit
segments, constructs or imports local reference counts, and reports
document-level frequency and coverage. No reference corpus, sentence
parser, download or implicit normalization is required or supplied by
these functions.

## Usage

``` r
lexdiv_ngrams(data, preprocessing_id, n = c(2L, 3L),
  documents = NULL, id_col = "document_id", segment_col = "segment_id",
  position_col = "token_index", term_col = "term", max_ngrams = 1e6)

lexdiv_ngram_reference(x, resource, totals = NULL,
  preprocessing_id = NULL, complete = NULL)

lexdiv_ngram_profile(x, reference)

# S3 method for class 'lexdiv_ngrams'
print(x, ...)
# S3 method for class 'lexdiv_ngram_reference'
print(x, ...)
# S3 method for class 'lexdiv_ngram_profile'
print(x, ...)
```

## Arguments

- data:

  A plain data frame of prepared tokens. Document and segment IDs and
  terms must be nonempty character strings without missing values. Terms
  must contain no whitespace. Each document/segment pair must occupy one
  contiguous block with strictly increasing positive whole-number
  original positions. Gaps are allowed and break adjacency. Input is
  never sorted.

- preprocessing_id:

  Required nonempty character label describing the actual segmentation,
  tokenization, exclusion, lexical-unit and normalization rules. Target
  and reference labels must agree. The label is a caller assertion, not
  verification of the preparation. Inherit it from an extraction when
  constructing a reference from that result.

- n:

  A nonempty unique selection of `2L` and `3L`, in the desired output
  order. Overlapping occurrences are counted.

- documents:

  Optional unique character document-ID roster, including all IDs in
  `data`. It preserves zero-token documents and sets summary order.
  Defaults to IDs in first-seen input order.

- id_col,segment_col,position_col,term_col:

  Four distinct column names. Extra input columns are ignored; retain
  research metadata separately by ID.

- max_ngrams:

  Positive whole-number upper bound on extracted occurrence rows,
  checked before occurrence tables and tallies are allocated. This is
  not a bound on total memory or all result rows. The default is one
  million.

- x:

  For reference construction, either an unmodified `lexdiv_ngrams`
  result or a plain count data frame. For profiling, an unmodified
  `lexdiv_ngrams` result. For printing, the corresponding result.

- resource:

  Named list with exactly these ordered nonempty character fields:
  `resource_id`, `resource_version`, `creator`, `source_reference`,
  `data_license`, `transformation_id`, `lookup_unit`,
  `resource_key_normalization_id`. These describe the reference; the
  package does not establish its suitability or permissions.

- totals:

  For external counts, a data frame with unique `n` rows and nonnegative
  whole-number `opportunities` and `documents`. Opportunities count
  eligible adjacent windows before any frequency pruning, not all word
  tokens. Required with a count table; inherited from an extraction.

- complete:

  Whether the reference lists every observed n-gram in its declared
  population. Defaults to `TRUE` for an extraction and `FALSE` for an
  external table. Complete count sums must equal opportunities for each
  `n`; incomplete sums must not exceed them. This check cannot prove
  that the declared population or completeness is accurate.

- reference:

  An unmodified `lexdiv_ngram_reference` result. It must declare totals
  for every `n` requested in the target extraction.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

`lexdiv_ngrams()` returns a `lexdiv_ngrams` list:

- occurrences:

  `document_id`, `segment_id`, `n`, `start_index`, `end_index`, `term1`,
  `term2`, `term3`. Rows follow requested `n`, then input start-row
  order. For bigrams, `term3` is `NA_character_`.

- counts:

  `n`, `term1`, `term2`, `term3`, `count`, `document_count`. Each
  distinct sequence retains its occurrence count and number of distinct
  documents, in first-occurrence order.

- document_counts:

  `document_id`, the four sequence columns, and `count`, in
  first-occurrence order.

- documents:

  Document-major, then requested-`n`-major rows with `document_id`, `n`,
  `input_tokens`, `opportunities`, `ngram_types`, `status`. Status is
  `"empty_document"`, `"no_ngrams"` or `"ok"`. Token counts repeat
  across `n`.

- totals:

  Requested `n`, total `opportunities`, and `documents` (roster size,
  including zero-token documents).

- provenance:

  Contract identity/version, preparation label, input-column mapping,
  input and result content fingerprints, boundary policy and declared
  boundary evidence, row ceiling, normalization and network policy.

`lexdiv_ngram_reference()` returns a `lexdiv_ngram_reference` list with
`counts`, `totals`, and `provenance`. Count columns are exactly those of
the extraction's `counts`; keys must be unique and counts positive whole
numbers. Document counts cannot exceed occurrence counts or the declared
document population. Terms are matched exactly by component in UTF-8,
without case folding or Unicode normalization. Extra columns are
discarded. Provenance retains resource metadata, preparation,
completeness, source extraction fingerprint when available, and
reference content identity.

`lexdiv_ngram_profile()` returns a `lexdiv_ngram_profile` list:

- lookup:

  All target occurrence columns plus `reference_status`,
  `reference_count`, `reference_document_count`,
  `reference_opportunities`, and `frequency_per_million`. Status is
  `"listed"` for an observed reference row, `"not_observed"` for an
  absent complete-reference key (count zero), or `"not_listed"` for an
  absent incomplete-reference key (count missing). Rates equal count
  divided by reference opportunities for that `n`, times one million.
  With zero reference opportunities the rate is missing.

- summary:

  Document-major, then requested-`n`-major, then `"token"`/`"type"`
  weighting rows. Columns are `document_id`, `n`, `weighting`,
  `eligible_items`, `listed_items`, `zero_items`, `unavailable_items`,
  `lookup_coverage`, `value_coverage`, `mean_frequency_per_million`,
  `status`, `missing_reason`. Token weighting retains repetitions; type
  weighting counts each exact sequence once per document. Coverage
  denominators are eligible target occurrences or types. Lookup coverage
  counts listed keys; value coverage counts available rates.
  `zero_items` counts `"not_observed"` keys, even when a zero reference
  denominator leaves their rate undefined; `unavailable_items` counts
  missing rates. Means use available rates, including defined zeros.
  Always report coverage beside means.

- documents:

  Unchanged target document diagnostics.

- provenance:

  Target and reference provenance, reference totals, statistic and
  rate-denominator definitions, contract and content identities.

Summary status is `"empty"` with reason `"no_target_ngrams"` for zero
eligible items; coverage and mean are missing. It is `"no_values"` with
reason `"zero_reference_opportunities"` or
`"no_available_reference_values"` when no rates are available. Otherwise
it is `"ok"`, which permits partial coverage, with missing reason
`NA_character_`. Zero-document inputs retain typed zero-row tables.
Identifiers/terms/statuses are character, `n` is integer, and positions,
counts, rates and coverages are double. All three print methods display
at most 12 rows and return the complete result invisibly.

## Details

Segment boundaries must represent the study's chosen adjacency
boundaries, such as sentences or speaker turns. The function checks
declared boundaries, not their linguistic accuracy. Preserve positions
before exclusion: `make a decision` at positions 1, 2, 3 must not become
the adjacent bigram `make decision` after deleting position 2.
Renumbering destroys that evidence. The generic tokenizer's
retained-token index alone does not provide original gaps or sentence
IDs; do not pass it through as if it did. Decide punctuation,
contractions, hyphens and markup handling explicitly.

An external frequency table must supply all required counts and totals.
A published table using word-token normalization, different boundaries
or unknown pruning is not automatically compatible. A reference's zero
means unobserved in the specified sample, not impossible in English.
Unlisted keys in truncated tables retain missing values and are excluded
from means. Even a matching preparation label cannot rule out
incorrectly prepared keys.

Save whole results with
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html) and
[`readRDS()`](https://rdrr.io/r/base/readRDS.html). Content fingerprints
detect accidental modifications before subsequent calls; they are not
signatures or permission checks. To change a reference, reconstruct it
from revised counts, totals and metadata instead of editing its result.
Corpus text and counts remain local unless the user separately shares
them; local processing does not establish permission to redistribute
inputs or outputs. Source text need not be bundled with a reference
table or package.

These descriptive frequencies are not association scores, lexical
employability or proficiency estimates. There is no MI, t-score,
smoothing, automatic threshold, skip-gram, semantic matching or document
pooling. Bundled TUBELEX unigram counts cannot recover observed n-gram
co-occurrences.

## See also

[`lexdiv_ngram_compare`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_compare.md),
[`lexdiv_norm_profile_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile_batch.md),
[`lexdiv_reference_coverage`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_reference_coverage.md),
[`tubelex_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)

## Examples

``` r
# Authored, pre-segmented example; no external corpus.
tokens <- data.frame(document_id = c(rep("r1", 3), rep("r2", 3)),
  segment_id = "s1", token_index = rep(1:3, 2),
  term = c("make", "a", "decision", "make", "a", "plan"))
extracted <- lexdiv_ngrams(tokens, "authored-sentences-surface-v1")
extracted$counts
#>   n term1    term2    term3 count document_count
#> 1 2  make        a     <NA>     2              2
#> 2 2     a decision     <NA>     1              1
#> 3 2     a     plan     <NA>     1              1
#> 4 3  make        a decision     1              1
#> 5 3  make        a     plan     1              1
resource <- list(resource_id = "authored_demo", resource_version = "1",
  creator = "Example author", source_reference = "Authored token sequences",
  data_license = "Project-authored example", transformation_id = "none",
  lookup_unit = "adjacent_surface_ngram", resource_key_normalization_id = "identity")
reference <- lexdiv_ngram_reference(extracted, resource)
target <- tokens[1:3, ]
target$term[3] <- "choice"
result <- lexdiv_ngram_profile(
  lexdiv_ngrams(target, "authored-sentences-surface-v1"), reference)
result$lookup
#>   document_id segment_id n start_index end_index term1  term2  term3
#> 1          r1         s1 2           1         2  make      a   <NA>
#> 2          r1         s1 2           2         3     a choice   <NA>
#> 3          r1         s1 3           1         3  make      a choice
#>   reference_status reference_count reference_document_count
#> 1           listed               2                        2
#> 2     not_observed               0                        0
#> 3     not_observed               0                        0
#>   reference_opportunities frequency_per_million
#> 1                       4                 5e+05
#> 2                       4                 0e+00
#> 3                       2                 0e+00
print(result)
#> <lexdiv_ngram_profile; contract 0.1.0>
#>  document_id n weighting eligible_items listed_items zero_items
#>           r1 2     token              2            1          1
#>           r1 2      type              2            1          1
#>           r1 3     token              1            0          1
#>           r1 3      type              1            0          1
#>  unavailable_items lookup_coverage value_coverage mean_frequency_per_million
#>                  0             0.5              1                     250000
#>                  0             0.5              1                     250000
#>                  0             0.0              1                          0
#>                  0             0.0              1                          0
#>  status missing_reason
#>      ok           <NA>
#>      ok           <NA>
#>      ok           <NA>
#>      ok           <NA>
# Import a pruned aggregate without converting its missing rows to zero.
partial <- lexdiv_ngram_reference(reference$counts[reference$counts$count > 1, ],
  resource, totals = reference$totals,
  preprocessing_id = "authored-sentences-surface-v1", complete = FALSE)
lexdiv_ngram_profile(lexdiv_ngrams(target,
  "authored-sentences-surface-v1"), partial)$summary
#>   document_id n weighting eligible_items listed_items zero_items
#> 1          r1 2     token              2            1          0
#> 2          r1 2      type              2            1          0
#> 3          r1 3     token              1            0          0
#> 4          r1 3      type              1            0          0
#>   unavailable_items lookup_coverage value_coverage mean_frequency_per_million
#> 1                 1             0.5            0.5                      5e+05
#> 2                 1             0.5            0.5                      5e+05
#> 3                 1             0.0            0.0                         NA
#> 4                 1             0.0            0.0                         NA
#>      status                missing_reason
#> 1        ok                          <NA>
#> 2        ok                          <NA>
#> 3 no_values no_available_reference_values
#> 4 no_values no_available_reference_values
```
