# Extract source-linked adjective and common-noun dependency pairs

Validates supplied basic Universal Dependencies (UD) trees and extracts
`amod` relations from an `ADJ` dependent to a `NOUN` head. This
experimental function connects occurrences and original context to
document counts and annotation coverage. It runs no parser or model.

## Usage

``` r
lexdiv_amod_pairs(annotations, unit = c("surface", "lemma"),
  context_chars = 30L, max_tokens = 1e6)
```

## Arguments

- annotations:

  An unmodified
  [`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
  result. Each segment must represent one sentence, including all
  syntactic words and punctuation in original order. Tokens require
  plain numeric `head` (sentence-local `token_index`, with 0 for root),
  character `deprel` (basic UD relation, optionally with a subtype), and
  character `upos` (UD tags). Missing annotations use typed `NA`, not an
  underscore. Empty segments and documents remain in the result.

- unit:

  Exact, case-sensitive `surface` (default) or `lemma` values used to
  count ordered adjective–noun types. No lowercasing, lemmatization, or
  fallback occurs. Missing lemmas do not remove detected occurrences;
  type totals are unavailable if any detected pair lacks a unit.

- context_chars:

  Non-negative whole number of Unicode codepoints on each side of the
  span enclosing both words, limited to the original segment.

- max_tokens:

  Positive whole-number input row limit, not a total memory or
  source-text size limit.

## Details

Every supplied head must refer to a different word in the same sentence
or be 0. Known cycles, out-of-range heads, multiple roots and
inconsistent root labels are rejected even in incomplete sentences.
Complete basic trees must have exactly one root. Structural validation
does not establish linguistic correctness or detect an incorrectly
declared sentence boundary.

A sentence with any missing head, relation or UPOS is excluded in full.
Other complete sentences remain observable, but totals for a document
containing an incomplete sentence are `NA`, not zero. Coverage is the
number of tokens in complete sentences divided by all supplied tokens,
including punctuation. Empty documents have zero pair/type counts and
undefined token coverage. These counts are not lexical-diversity scores.

The feature includes `amod` subtypes and requires dependent `ADJ` and
head `NOUN`. Proper nouns (`PROPN`), pronouns and other parts of speech
are outside this explicitly narrow feature. It is not every UD
adjectival modifier, an idiom detector, or an exact replication of a
study using Penn tags. Direction and non-adjacent endpoints are
retained.

Input must already represent source-aligned basic syntactic words. This
is not a CoNLL-U file reader. Multiword-token range rows, empty nodes,
and words that cannot be aligned individually to the original text are
unsupported. Supplied `deps`/`DEPS` columns containing enhanced edges
are rejected; callers must explicitly project to a basic tree and record
that choice in annotation provenance. Do not renumber only the token
column: heads must use the same sentence-local indices. No normalization
or guessed offsets are used.

`counts` describes only observed pairs with both lexical values
available. Read it alongside coverage and `pairs_with_unit`; it is not
automatically a complete reference corpus. Mutual information,
association strength, sampling uncertainty and parser accuracy are not
estimated.

## Value

A plain list with `occurrences` (both token indices, surfaces, POS,
terms and endpoints, relation, direction, token distance, enclosing span
and `pre`/`keyword`/`post` context), `counts` (observed ordered term
pairs and their frequencies), `segments` (missing annotation counts,
status and observed/total pairs), `documents` and `summary` (sentence
and token coverage, observed/total pairs and types), the complete
`annotations`, and `provenance` with the feature, unit, policies and
content hash. `keyword` includes intervening text, not just the two
words. Composite source IDs and both endpoints identify occurrences; row
numbers are not stable cross-analysis IDs. `pairs_with_unit`
distinguishes unit availability from syntactic detection.
`observed_types` remains available when a complete type total cannot be
established.

## References

Universal Dependencies, *amod: adjectival modifier*,
<https://universaldependencies.org/u/dep/amod.html>, and *CoNLL-U
Format*, <https://universaldependencies.org/format.html>.

## See also

[`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md),
[`lexdiv_align_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_align_annotations.md),
[`lexdiv_ngrams`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)

## Examples

``` r
env <- new.env(parent = baseenv())
sys.source(system.file("examples", "amod-pairs.R", package = "ldfreq",
  mustWork = TRUE), env)
x <- env$amod_pairs_example
x$reference$occurrences[c("document_id", "dependent_term", "head_term", "keyword")]
#>   document_id dependent_term head_term          keyword
#> 1     english            big   balloon Big red balloons
#> 2     english            red   balloon     red balloons
#> 3  wrong_head          small      bird      Small birds
#> 4  wrong_head          large      fish       large fish
#> 5    japanese           赤い        鳥           赤い鳥
#> 6 unavailable          quiet      bird      Quiet birds
#> 7     partial            red      bird        Red birds
#> 8     partial           blue      bird       Blue birds
x$predicted$documents
#>   document_id segments nonempty_segments complete_segments incomplete_segments
#> 1     english        1                 1                 1                   0
#> 2  wrong_head        1                 1                 1                   0
#> 3    japanese        1                 1                 1                   0
#> 4        zero        1                 1                 1                   0
#> 5 unavailable        1                 1                 0                   1
#> 6     partial        2                 2                 1                   1
#> 7       empty        1                 0                 0                   0
#>   tokens analyzed_tokens token_coverage observed_pairs pairs pairs_with_unit
#> 1      5               5            1.0              1     1               1
#> 2      6               6            1.0              2     2               2
#> 3      5               5            1.0              0     0               0
#> 4      3               3            1.0              0     0               0
#> 5      4               0            0.0              0    NA               0
#> 6      8               4            0.5              1    NA               1
#> 7      0               0             NA              0     0               0
#>   observed_types types                status
#> 1              1     1              complete
#> 2              2     2              complete
#> 3              0     0              complete
#> 4              0     0              complete
#> 5              0    NA incomplete_annotation
#> 6              1    NA incomplete_annotation
#> 7              0     0                 empty
x$differences
#>   document_id reference_pairs predicted_pairs delta_pairs reference_types
#> 1     english               2               1          -1               2
#> 2  wrong_head               2               2           0               2
#> 3    japanese               1               0          -1               1
#> 4        zero               0               0           0               0
#> 5 unavailable               1              NA          NA               1
#> 6     partial               2              NA          NA               2
#> 7       empty               0               0           0               0
#>   predicted_types reference_coverage predicted_coverage evaluated tp fp fn
#> 1               1                  1                1.0      TRUE  1  0  1
#> 2               2                  1                1.0      TRUE  1  1  1
#> 3               0                  1                1.0      TRUE  0  0  1
#> 4               0                  1                1.0      TRUE  0  0  0
#> 5              NA                  1                0.0     FALSE NA NA NA
#> 6              NA                  1                0.5     FALSE NA NA NA
#> 7               0                 NA                 NA      TRUE  0  0  0
```
