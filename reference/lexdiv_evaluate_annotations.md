# Evaluate external annotation labels against an explicit reference

Pairs complete external annotations on the same source segmentation,
reports label-specific precision, recall and F1, and retains every
occurrence with original-text context. Missing references and missing
predictions remain separate. This experimental evaluator does not run an
analyzer or adjudicate human judgments.

## Usage

``` r
lexdiv_evaluate_annotations(predicted, reference, column, labels,
  reference_info, context_chars = 30L, max_tokens = 1e6)
```

## Arguments

- predicted, reference:

  Unmodified results of
  [`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
  containing the same document/segment IDs, exact original segment text,
  and token indices, surfaces and source positions. Complete imports
  include punctuation and empty segments, even when a label is
  unavailable. Document and segment order may differ between inputs;
  outputs follow the reference order. Additional input columns and
  metadata are retained in the complete inputs.

- column:

  One character column name, present in both token tables, holding a
  single categorical label per token, for example `"upos"` or `"xpos"`.
  Values must be plain valid-UTF-8 strings from `labels`, or
  `NA_character_` for unavailable labels. No case conversion, tagset
  mapping, normalization or label inference is performed.

- labels:

  Required non-empty character vector of unique, non-blank labels in the
  complete allowed inventory, in output order. This is not a target
  filter: all non-missing input labels must be in this vector. Include
  punctuation labels when used in the inputs. Unobserved classes remain
  in the label table.

- reference_info:

  Plain named list of non-blank scalar strings including `reference_id`,
  `annotation_protocol`, `label_scheme`, `model_exposure` (`not_shown`,
  `shown` or `unknown`), and `evaluation_role` (`held_out`,
  `development` or `unknown`). Describe the label definitions, sampling
  and reference construction; optional additional declarations survive.
  These are caller statements, not proof of independence, label validity
  or absence of training overlap.

- context_chars:

  Non-negative whole number of original Unicode codepoints on each side
  of the token, confined to its segment. Zero supplies empty left and
  right contexts. These are character windows, not quanteda token
  windows or grapheme clusters; a window edge can split a combining
  sequence.

- max_tokens:

  Positive whole-number ceiling for each imported token table. Checked
  before revalidating alignment; not a total memory or text-size limit.

## Details

For each label, TP counts equal prediction/reference pairs carrying that
label. FP counts that prediction on a different available reference
label. FN counts that reference label with a different or missing
prediction. Precision is TP/(TP+FP), recall is TP/(TP+FN), and F1 is
2TP/(2TP+FP+FN). A zero denominator gives `NA`; for example an
unobserved class has undefined F1, while a class with reference examples
but no predictions has recall and F1 zero and undefined precision. A
wrong available label contributes one FP to its predicted class and one
FN to its reference class.

Unavailable references are not negatives and do not contribute to TP, FP
or FN. Predictions at these positions are reported separately. Missing
predictions on available references contribute FN, even though they are
absent from the conditional agreement denominator. Precision is
conditional on the evaluated reference subset; selective reference
annotation can bias it. A non-candidate sample is needed to assess
detection failures. A reviewer status or failure reason may be stored as
an additional input column, but is not interpreted: encode an unresolved
or unreviewed label as `NA_character_`, keeping its distinct reason in
the original reference table.

Overall and per-document agreement divides exact matches by pairs with
both labels available. `matches_among_reference_available` instead
divides matches by every available reference, including positions
without a prediction. Coverage rates use every imported token, including
punctuation. All proportions are occurrence-weighted and undefined for
empty denominators. No macro average, sampling weights, confidence
intervals or independence assumptions are supplied.

The label scheme must be substantively comparable in both inputs. The
function checks literal labels and positions, not equivalence of
different tagsets. UPOS or XPOS agreement is not word-sense
disambiguation. Dependency accuracy requires matched heads as well as
labels; evaluating a dependency-label column alone does not compute LAS.
Different token or segment boundaries are rejected. For different token
boundaries on the same original segments, use
[`lexdiv_align_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_align_annotations.md)
and report geometry coverage alongside its conditional label evaluation.

Use document completeness and occurrence selections when connecting
annotation errors to lexical metrics. A partial reference cannot define
a full-document reference score without further assumptions. The
annotation-evaluation vignette and installed example connect noun
selection to TTR with non-computable results retained. The separate
[`lexdiv_compare_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_annotations.md)
compares lemma/UPOS/flemma changes in `lexdiv_tokenization` objects
without judging which annotation is correct.

## Value

A plain list with:

- summary, documents:

  Overall and per-document counts and rates. Counts include `tokens` and
  the available-reference count `reference_available`. The
  available-prediction count is `prediction_available`. The `paired`
  count has both labels. The five outcomes below are also counted.

  `reference_coverage` describes available references among all tokens.
  `prediction_coverage` describes available predictions among all
  tokens. `paired_coverage` describes tokens with both labels.
  `agreement_among_paired` gives conditional agreement.
  `matches_among_reference_available` gives the all-reference match
  rate.

  The flags `reference_complete` and `prediction_complete` mean no label
  is missing in that document; both are vacuously true for empty
  documents, whose rates remain `NA`.

- labels:

  One row per requested label. Support is `reference_n`; the number of
  predictions on available references is `predictions_evaluated`. Error
  counts are `tp`, `fp`, and `fn`. A subset of FN is
  `missing_predictions`.

  `predictions_without_reference` counts predictions at positions with
  no reference. The rates are `precision`, `recall`, and `f1`.
  Case-sensitive exact labels are used.

- pairs:

  Every token, with compound source IDs, original `surface`, `start` and
  `end`; context fields `pre`, `keyword` and `post`; labels
  `reference_label` and `predicted_label`; nullable `matches_reference`;
  and `outcome`.

  The five outcomes are `agreement`, `disagreement`, `reference_only`,
  `prediction_only`, and `neither_available`. Matches are `NA` unless
  both labels exist. Join to complete source tables by
  document/segment/token IDs, not row numbers.

- confusion:

  Sparse counts of observed reference/prediction label pairs, including
  `NA` combinations, in first-observed order. Unobserved combinations
  are omitted; an absent combination has zero occurrences.

- review_queue:

  All non-agreement rows from `pairs`, including unavailable
  comparisons. A missing reference is not classified as an error.

- predicted, reference:

  Complete original inputs, including auxiliary status/reviewer/reason
  columns, segments, empty documents and provenance.

- provenance:

  Evaluator ID/version, label column and inventory, context window,
  scoring and weighting policies, reference declarations, and a content
  SHA-256 reproducibility fingerprint. This is not authentication of
  human labels. Save the complete result and settings with
  [`saveRDS()`](https://rdrr.io/r/base/readRDS.html).

## See also

[`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
for source-checked input.

[`lexdiv_compare_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_annotations.md)
for changes without a reference.

[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
for downstream diversity measures.

See also the annotation-evaluation vignette.

## Examples

``` r
segments <- data.frame(document_id = "d", segment_id = "s",
  text = "cats cats run.")
tokens <- data.frame(document_id = "d", segment_id = "s",
  token_index = 1:4, surface = c("cats", "cats", "run", "."),
  upos = c("NOUN", "NOUN", "VERB", "PUNCT"))
metadata <- list(language = "en", analyzer = "authored",
  analyzer_version = "1", dictionary = "none", dictionary_version = "none",
  unit = "authored-token", normalization = "none")
reference <- lexdiv_import_annotations(tokens, segments, metadata)
tokens$upos <- c("NOUN", "VERB", "NOUN", "PUNCT")
predicted <- lexdiv_import_annotations(tokens, segments, metadata)
evaluation <- lexdiv_evaluate_annotations(predicted, reference, "upos",
  c("NOUN", "VERB", "PUNCT"), list(reference_id = "authored-v1",
    annotation_protocol =
      "Authored illustration, not independent human evidence",
    label_scheme = "UPOS subset", model_exposure = "shown",
    evaluation_role = "development"))
evaluation$labels
#>   label reference_n predictions_evaluated tp missing_predictions
#> 1  NOUN           2                     2  1                   0
#> 2  VERB           1                     1  0                   0
#> 3 PUNCT           1                     1  1                   0
#>   predictions_without_reference fp fn precision recall  f1
#> 1                             0  1  1       0.5    0.5 0.5
#> 2                             0  1  1       0.0    0.0 0.0
#> 3                             0  0  0       1.0    1.0 1.0
evaluation$review_queue[, c("pre", "keyword", "post",
  "reference_label", "predicted_label")]
#>          pre keyword  post reference_label predicted_label
#> 2      cats     cats  run.            NOUN            VERB
#> 3 cats cats      run     .            VERB            NOUN
```
