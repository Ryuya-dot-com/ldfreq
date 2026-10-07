# Align complete external token annotations with original text

Imports external annotations, including Japanese morphological analyses,
as plain tables with verified source positions and declared analysis
metadata. No analyzer, dictionary, corpus, or language-specific
segmentation is bundled or invoked. This is an experimental input
interface.

## Usage

``` r
lexdiv_import_annotations(data, segments, provenance, max_tokens = 1e6)
```

## Arguments

- data:

  Plain data frame with character `document_id`, `segment_id`, and
  `surface`, and positive whole-number `token_index`. Import all tokens,
  including punctuation, in segment order before excluding any rows.
  Indices must start at 1 and be consecutive within each segment.
  Additional columns, such as `lemma`, `orthBase`, readings, POS,
  unknown flags, and raw features, are preserved without interpretation
  or imputation. If `start`/`end` are supplied, they must agree with the
  derived segment-local, 1-based, inclusive Unicode codepoint positions.

- segments:

  Plain data frame with unique character `document_id`/ `segment_id`
  pairs and the original UTF-8 `text` for each segment. Include empty
  segments/documents. At least one segment is required; each document
  occupies one contiguous block. Segment boundaries, including sentence
  or turn boundaries, are supplied by the caller, not inferred.
  Additional columns survive. `token_count` and `text_sha256` are
  reserved.

- provenance:

  Named plain list of scalar, non-empty UTF-8 strings including
  `language`, `analyzer`, `analyzer_version`, `dictionary`,
  `dictionary_version`, `unit`, and `normalization`. Record actual
  upstream settings. Use explicit `"unknown"` or `"not-applicable"`
  labels when appropriate; they do not establish reproducibility.
  Optional fields, such as dictionary file hashes, user-dictionary
  versions, configuration, source reference and license, may be strings
  or `NA_character_`. These are caller declarations, not independently
  authenticated metadata.

- max_tokens:

  Positive whole-number ceiling on input token rows, checked before
  alignment. This is not a total memory or source-text size limit.

## Details

Surfaces are matched exactly, in order, against the supplied original
segment text. Unicode whitespace may occur between tokens and
before/after them. A token starting with whitespace uses the earliest
exact match reachable from the current cursor across whitespace only.
This also permits analyzers that emit CR but omit LF in CRLF sequences.
Other tokens begin after any whitespace at that cursor. All
non-whitespace text must be accounted for. Omitted punctuation, replaced
characters, wrong ordering, and skipped repeated words therefore cause
an error. Neither text nor surfaces are normalized. Combining marks and
supplementary characters count as Unicode codepoints, not graphemes,
bytes or UTF-16 code units.

Positions refer to `segments$text`, not to a concatenated document or to
normalized text. If upstream preprocessing changed the original
surfaces, supply the actual analyzed text and retain its relationship to
the original separately; this importer does not invent that mapping.
Supplied segment boundaries are not checked against an unsupplied full
document.

Import before selecting lexical forms and excluding punctuation,
function words or missing lemmas. Keep `token_index` unchanged after
exclusions:
[`lexdiv_ngrams`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
and
[`lexdiv_as_quanteda`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_read_masc.md)
then retain gaps instead of creating false neighbors. Core diversity
measures accept the explicitly retained sequence; their interpretation
depends on that selection. Keep selection settings and missingness
counts with the imported object.

Surface, orthographic base and lexeme are different analytical choices.
The importer does not translate source POS to UPOS, infer unknown-word
status, merge Japanese homographs, or establish compatibility with a
frequency table. The bundled NJ8 and TUBELEX profiles are English
resources. See the Japanese annotations vignette for an R-only
gibasa/UniDic recipe. Other analyzers may provide these same columns;
successful alignment is not evidence of accurate morphology or
cross-language measurement equivalence.

## Value

A plain list with:

- tokens:

  Input token columns plus verified integer `start` and `end`; existing
  coordinate columns are validated and replaced by these integers. UTF-8
  ID/surface encoding labels and row names are canonicalized.

- segments:

  Input segment columns plus original integer `token_count` and
  `text_sha256`, the SHA-256 of each UTF-8 text string.

- documents:

  One `document_id` per document, in input order, including those with
  no tokens.

- provenance:

  Importer ID/version, coordinate convention, alignment rule, importer
  normalization (always `"none"`), caller metadata in `annotation`, and
  `input_sha256` of the canonical input tables and declarations. Hashes
  describe the imported snapshot, not later modifications; they are
  reproducibility labels, not authentication or license verification.

The list can be saved with
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html) and read with
[`readRDS()`](https://rdrr.io/r/base/readRDS.html). It is not a
`lexdiv_tokenization` object and is not an input to
[`lexdiv_compare_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_annotations.md),
whose one-to-one contract is unchanged.

## See also

[`lexdiv_ambiguity_review`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md),
[`lexdiv_ngrams`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md),
[`lexdiv_as_quanteda`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_read_masc.md),
[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md),
[`vignette("japanese-annotations", package = "ldfreq")`](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.md)

## Examples

``` r
# Authored illustration, not automatic morphological analysis.
segments <- data.frame(document_id = "ja", segment_id = "s1",
  text = "\u732b\u304c\u6765\u305f\u3002")
tokens <- data.frame(document_id = "ja", segment_id = "s1", token_index = 1:5,
  surface = c("\u732b", "\u304c", "\u6765", "\u305f", "\u3002"))
x <- lexdiv_import_annotations(tokens, segments, list(
  language = "ja", analyzer = "authored", analyzer_version = "1",
  dictionary = "none", dictionary_version = "not-applicable",
  unit = "authored-example", normalization = "none"))
x$tokens
#>   document_id segment_id token_index surface start end
#> 1          ja         s1           1      猫     1   1
#> 2          ja         s1           2      が     2   2
#> 3          ja         s1           3      来     3   3
#> 4          ja         s1           4      た     4   4
#> 5          ja         s1           5      。     5   5
lexdiv_metrics(x$tokens$surface[1:4], metrics = "ttr")
#> <lexdiv_results: 1 metric; contract 0.2.0>
#>   metric_id value status missing_reason N V below_quality_floor
#> 1       ttr     1     ok           <NA> 4 4               FALSE
lexdiv_ngrams(x$tokens[1:4, ], "authored-surface-v1", term_col = "surface")
#> <lexdiv_ngrams; contract 0.1.0>
#>  document_id n input_tokens opportunities ngram_types status
#>           ja 2            4             3           3     ok
#>           ja 3            4             2           2     ok
```
