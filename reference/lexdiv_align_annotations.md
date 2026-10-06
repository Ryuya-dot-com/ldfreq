# Align different token segmentations using original source positions

Connects complete external annotations of the same original segments by
overlapping character intervals. Reports splits, merges, complex
overlap, exact-span correspondence and internal-boundary agreement.
Optional single-label evaluation is restricted to exact span pairs. This
experimental function runs no tokenizer, model or automatic
adjudication.

## Usage

``` r
lexdiv_align_annotations(predicted, reference, column = NULL,
  labels = NULL, reference_info = NULL, context_chars = 30L,
  max_tokens = 1e6)
```

## Arguments

- predicted, reference:

  [`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
  results, unmodified, with the same document/segment ID pairs and exact
  original text, including empty segments. Token boundaries and indices
  may differ. Results follow reference segment order. Complete imports
  retain punctuation and all non-whitespace source text. Inputs with
  different segment rosters are rejected, even if their concatenated
  text is identical.

- column, labels, reference_info:

  Omit all three for geometry alone, or supply all three for optional
  label evaluation.

  [`lexdiv_evaluate_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_evaluate_annotations.md)
  defines their requirements: a plain character label column in both
  inputs, a complete unique label inventory, and explicit reference
  declarations. Missing labels use `NA_character_`. All supplied labels
  are validated, including tokens excluded from conditional evaluation.
  No tagset mapping or transfer of a compound's label to its parts is
  performed.

- context_chars:

  Non-negative whole number of original Unicode codepoints on each side
  of a group's source span, limited to that segment. Zero gives empty
  contexts. Positions are not byte offsets or grapheme-cluster indices.

- max_tokens:

  Positive whole-number limit for each imported token table; not a total
  memory or source-size limit.

## Details

The reference is the designated comparison baseline. Designating it does
not establish that its word units or labels are linguistically correct.
Interpreting differences as errors requires a declared annotation
standard and suitable independent reference data.

Token correspondence uses segment-local, one-based, inclusive Unicode
codepoint intervals. Connected components of overlapping intervals form
groups; adjacency alone does not connect them. One reference token with
several predicted tokens is a `split`; the converse is a `merge`.
Several tokens on each side form a `complex` component, with no inferred
one-to-one pairing. One token on each side is `exact` only if both
endpoints match; otherwise it is `changed_span`. Unmatched components
are `reference_only` or `prediction_only`. With complete imports these
can arise from optional whitespace tokens. Explicit whitespace tokens
and punctuation participate in all geometry counts; no filtering or
normalization occurs.

An internal boundary is the ordered pair consisting of the left token's
end and the next token's start, within one segment. This preserves
omitted whitespace gaps and differences in whitespace ownership. Segment
edges are excluded: a zero- or one-token segment has no internal
boundary. This explicit junction measure is not an implementation of
every external tokenizer benchmark's boundary convention.

For token spans and internal boundaries separately, precision is matched
divided by predicted count, recall is matched divided by reference
count, and F1 is twice matched divided by the sum of the two counts. FP
and FN are the unmatched predicted and reference counts relative to this
baseline. Zero denominators give `NA`. For token spans, precision and
recall also describe each side's coverage by exact pairs eligible for
label evaluation. These descriptive, occurrence-weighted rates provide
no confidence intervals or macro average.

Optional label evaluation uses only exact span pairs and retains both
original token indices, which can differ after an earlier split. Within
this subset, missing predictions on available references count as label
false negatives; unknown reference labels are not scored. Non-exact
spans are excluded from label TP/FP/FN, not counted as missing
predictions. Thus even perfect conditional label agreement can accompany
poor overall correspondence. Report the geometry counts and rates
alongside conditional label results. Selection-based bias cannot be
corrected by treating the aligned subset as the whole corpus.

For downstream lexical metrics, use each complete input and its original
document roster, applying a declared selection and lexical-form policy.
Using only exact pairs would remove the very segmentation differences
under study. The annotation-alignment vignette demonstrates
full-document TTR/MATTR with fixed parameters and preserves
empty/short-document missing results. POS agreement does not measure
word-sense or dependency-head accuracy.

## Value

A plain list containing:

- summary, documents:

  Overall and per-document tables with two rows per unit. The `measure`
  column identifies `token_span` or `internal_boundary`.

  Counts are `reference_n`, `predicted_n`, and `matched`. Unmatched
  counts are `fp` and `fn`; rates are `precision`, `recall`, and `f1`.
  Empty documents remain with zero counts and undefined rates.

- groups:

  Overlap components with `alignment_id`, source IDs, union
  `start`/`end`, per-side token counts, `relation`, and original context
  `pre`/`keyword`/`post`. IDs are local to this result, not permanent
  across modified inputs.

- members:

  Every imported token exactly once, carrying its group ID, `side`,
  original document/segment/token IDs, surface, positions and relation.

  `label_eligible` is logical and describes geometry, not label
  availability. When labels are requested, `label` retains the chosen
  value even on excluded tokens. Other annotations remain in the
  complete inputs; join by side and compound source IDs, not row
  numbers.

- boundaries:

  Union of observed internal junctions with source IDs and positions
  `left_end` and `right_start`. Original left/right token indices are
  retained for each side; absent indices are `NA`.

  `outcome` is `matched`, `reference_only`, or `prediction_only`.

- review_queue:

  All non-exact groups. These are differences to inspect, not
  automatically errors. Optional label disagreements have their own
  queue.

- annotation_evaluation:

  `NULL` unless labels were requested; otherwise contains tables
  `summary`, `labels`, and `documents`, plus `pairs`, `confusion`, and
  `review_queue`.

  [`lexdiv_evaluate_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_evaluate_annotations.md)
  documents the scoring rules. All label denominators are conditional on
  exact spans.

  `reference_token_index` identifies the reference token in pair rows.

  `predicted_token_index` identifies its counterpart.

- predicted, reference:

  Complete inputs, including auxiliary annotations, segments, empty
  documents and provenance.

- provenance:

  Aligner ID/version, coordinate and boundary policies, context window,
  optional label policy and reference declarations, interpretation
  limits, and a content SHA-256 fingerprint. Save the full object with
  [`saveRDS()`](https://rdrr.io/r/base/readRDS.html); the hash does not
  authenticate reference judgments.

## See also

[`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md),
[`lexdiv_evaluate_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_evaluate_annotations.md),
[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)

## Examples

``` r
segments <- data.frame(document_id = "d", segment_id = "s",
  text = "can't read.")
metadata <- list(language = "en", analyzer = "authored",
  analyzer_version = "1", dictionary = "none",
  dictionary_version = "none", unit = "authored", normalization = "none")
ref <- data.frame(document_id = "d", segment_id = "s",
  token_index = 1:3, surface = c("can't", "read", "."))
pred <- data.frame(document_id = "d", segment_id = "s",
  token_index = 1:4, surface = c("ca", "n't", "read", "."))
x <- lexdiv_align_annotations(
  lexdiv_import_annotations(pred, segments, metadata),
  lexdiv_import_annotations(ref, segments, metadata))
x$groups
#>   alignment_id document_id segment_id start end reference_n predicted_n
#> 1            1           d          s     1   5           1           2
#> 2            2           d          s     7  10           1           1
#> 3            3           d          s    11  11           1           1
#>   relation        pre keyword   post
#> 1    split              can't  read.
#> 2    exact     can't     read      .
#> 3    exact can't read       .       
x$summary
#>             measure reference_n predicted_n matched fp fn precision    recall
#> 1        token_span           3           4       2  2  1 0.5000000 0.6666667
#> 2 internal_boundary           2           3       2  1  0 0.6666667 1.0000000
#>          f1
#> 1 0.5714286
#> 2 0.8000000
```
