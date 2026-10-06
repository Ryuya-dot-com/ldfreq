# Evaluate annotations and their effect on document scores

## Start with the analysis that uses the annotations

Suppose a study compares the diversity of nouns across texts. A POS
tagger decides which words enter each noun sequence. Two taggers may
select the same number of nouns while selecting different words. A count
comparison alone cannot reveal whether those selections change the
diversity score.

[`lexdiv_evaluate_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_evaluate_annotations.md)
connects three checks: agreement with an explicit reference at each
source position; label-specific detection errors and missingness; and
document coverage needed to interpret downstream metrics. The example
below then uses the existing
[`lexdiv_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
to compare noun TTR. The question determines that selection and metric;
the evaluator does not choose them for you.

This design follows the distinction between feature-level annotation
evaluation and effects on text indices in Kyle and Eguchi (2024),
[doi:10.1016/j.rmal.2024.100120](https://doi.org/10.1016/j.rmal.2024.100120).
It does not reproduce their dependency analysis or establish a universal
accuracy threshold. Our sentences and labels are authored illustrations,
including deliberately wrong and unavailable labels. They are not
independent human annotations or a performance benchmark for English or
Japanese.

## Run the complete example offline

The installed script requires only ldfreq and its ordinary dependencies.
It does not invoke Python, download a model, load a corpus, or write
files.

``` r
source(system.file("examples", "annotation-evaluation.R", package = "ldfreq"))
example <- annotation_evaluation_example
evaluated <- example$evaluation
evaluated$documents[, c("document_id", "tokens", "reference_available",
  "prediction_available", "agreement", "disagreement", "reference_only", "prediction_only")]
#>      document_id tokens reference_available prediction_available agreement
#> 1        english      5                   5                    5         3
#> 2       japanese      6                   6                    6         4
#> 3  reference_gap      3                   2                    3         2
#> 4 prediction_gap      3                   3                    2         2
#> 5          empty      0                   0                    0         0
#>   disagreement reference_only prediction_only
#> 1            2              0               0
#> 2            2              0               0
#> 3            0              0               1
#> 4            0              1               0
#> 5            0              0               0
```

The five documents include English and Japanese examples, an unresolved
reference label, an unavailable prediction, and an empty document. An
empty document stays in the roster and has undefined coverage, not zero
coverage.

## Supply your own predictions and reference

Each input comes from
[`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md).
Supply all token surfaces, including punctuation, with original segment
text and consecutive token IDs. Unavailable labels are `NA_character_`;
do not delete the corresponding rows. Extra columns can hold separate
reviewer judgments, unresolved/unreviewed statuses and
prediction-failure reasons. The evaluator preserves those columns in its
complete inputs but does not interpret their names or adjudicate them.

``` r
head(example$inputs$reference$tokens)
#>   document_id segment_id token_index surface  upos review_status
#> 1     english         s1           1    cats  NOUN      selected
#> 2     english         s1           2     and CCONJ      selected
#> 3     english         s1           3    cats  NOUN      selected
#> 4     english         s1           4     run  VERB      selected
#> 5     english         s1           5       . PUNCT      selected
#> 6    japanese         s1           1      猫  NOUN      selected
#>             reviewer start end
#> 1 authored-reference     1   4
#> 2 authored-reference     6   8
#> 3 authored-reference    10  13
#> 4 authored-reference    15  17
#> 5 authored-reference    18  18
#> 6 authored-reference     1   1
example$inputs$reference$segments
#>      document_id segment_id               text token_count
#> 1        english         s1 cats and cats run.           5
#> 2       japanese         s1     猫が猫を見る。           6
#> 3  reference_gap         s1        dogs sleep.           3
#> 4 prediction_gap         s1        birds sing.           3
#> 5          empty         s1                              0
#>                                                        text_sha256
#> 1 6e97d8274dd51f44641a92d2914311cb0d39b96544ab5a979f5ccd1c634fdf99
#> 2 0295a3e71b80c36c1dc2ef2218724134ecb05c799457ff960d9ffbe39cc885d9
#> 3 7fd3367d5104581e84192af4ce43f774bdf7179f2062739c8c8c7fafef4c26bd
#> 4 a89a90825ccefc63f32f8978662437308019b5ca2b5bd1d966b856734a46f33f
#> 5 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
example$inputs$reference_info
#> $reference_id
#> [1] "authored-reference-v1"
#> 
#> $annotation_protocol
#> [1] "Authored illustration; labels were not independently collected"
#> 
#> $label_scheme
#> [1] "UPOS subset for authored tokens"
#> 
#> $model_exposure
#> [1] "shown"
#> 
#> $evaluation_role
#> [1] "development"
```

In real work, replace the authored source, predictions and labels with
your local data. Import them separately, recording the actual analyzer
and dictionary versions, token unit and normalization. Assign the
reference only after following your annotation protocol. Retain original
individual judgments separately from adjudication, and record who made
them. `model_exposure = "not_shown"` and `evaluation_role = "held_out"`
are declarations, not checks that establish blinding, independence or
absence of training overlap.

Evaluate one categorical column at a time with a complete label
inventory:

``` r
evaluated_again <- lexdiv_evaluate_annotations(
  predicted = example$inputs$predicted,
  reference = example$inputs$reference,
  column = "upos",
  labels = example$inputs$labels,
  reference_info = example$inputs$reference_info,
  context_chars = 12L
)
stopifnot(identical(evaluated, evaluated_again))
```

For an actual UPOS analysis, use your full UPOS inventory; for Penn XPOS
or a Japanese POS scheme, supply that scheme’s labels and definitions.
`labels` is the allowed inventory, not a filter of the feature you want
to report. Unexpected labels cause an error instead of disappearing from
the evaluation. Both tables must use comparable label meanings. The
function does not map different tagsets, and matching label strings
alone does not establish equivalence.

The two imports must describe the same document/segment IDs, exact
segment text and token surfaces/positions. Different document or segment
order is allowed and matched by IDs; a changed token or segment boundary
is rejected. Do not force a split/merged word into a one-to-one match by
reassigning row numbers. That requires a separate boundary-alignment
analysis. See [Japanese
annotations](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.md)
for an external morphology input example.

## Interpret label-specific errors with their denominators

``` r
evaluated$labels
#>   label reference_n predictions_evaluated tp missing_predictions
#> 1  NOUN           6                     6  4                   0
#> 2  VERB           3                     2  0                   1
#> 3 CCONJ           1                     1  1                   0
#> 4   ADP           2                     2  2                   0
#> 5 PUNCT           4                     4  4                   0
#>   predictions_without_reference fp fn precision    recall        f1
#> 1                             0  2  2 0.6666667 0.6666667 0.6666667
#> 2                             1  2  3 0.0000000 0.0000000 0.0000000
#> 3                             0  0  0 1.0000000 1.0000000 1.0000000
#> 4                             0  0  0 1.0000000 1.0000000 1.0000000
#> 5                             0  0  0 1.0000000 1.0000000 1.0000000
evaluated$summary[, c("tokens", "reference_coverage", "prediction_coverage",
  "agreement_among_paired", "matches_among_reference_available")]
#>   tokens reference_coverage prediction_coverage agreement_among_paired
#> 1     17          0.9411765           0.9411765              0.7333333
#>   matches_among_reference_available
#> 1                            0.6875
```

For a label such as `NOUN`, a true positive (TP) is a noun in both
inputs. A false positive (FP) is a predicted noun with an available
non-noun reference. A false negative (FN) is a reference noun with a
different **or missing** prediction. Precision is `TP / (TP + FP)`,
recall is `TP / (TP + FN)`, and F1 is `2 * TP / (2 * TP + FP + FN)`.

A missing reference is not a non-noun. Its prediction contributes to
`predictions_without_reference`, not FP. A missing prediction on a known
noun contributes to `missing_predictions` and FN. Thus
`agreement_among_paired` describes only positions with both labels,
while `matches_among_reference_available` also includes reference
positions the predictor failed to label. All zero-denominator rates
remain `NA`. Punctuation is included in the overall rates; report the
specific classes relevant to your question rather than relying on one
pooled agreement value.

These are unweighted occurrence counts for the supplied sample. If
references were checked only on predicted nouns, noun precision is
conditional on that reviewed subset and false negatives elsewhere cannot
be estimated. Sample complete segments, including non-candidates, to
assess detection failures. Keep any deliberately oversampled
rare-feature strata separate from a population estimate unless their
sampling probabilities are accounted for.

## Return from a false positive or negative to the source

All occurrences have context, including those the predictor did not mark
as the target. The following extracts noun errors while excluding
unavailable references from the FP calculation:

``` r
pairs <- evaluated$pairs
known <- !is.na(pairs$reference_label)
false_positives <- known & pairs$predicted_label %in% "NOUN" &
  !pairs$reference_label %in% "NOUN"
false_negatives <- pairs$reference_label %in% "NOUN" &
  !pairs$predicted_label %in% "NOUN"
shown <- c("document_id", "token_index", "pre", "keyword", "post",
  "reference_label", "predicted_label")
pairs[false_positives | false_negatives, shown]
#>    document_id token_index          pre keyword     post reference_label
#> 3      english           3    cats and     cats     run.            NOUN
#> 4      english           4 ts and cats      run        .            VERB
#> 8     japanese           3         猫が      猫 を見る。            NOUN
#> 10    japanese           5     猫が猫を    見る       。            VERB
#>    predicted_label
#> 3             VERB
#> 4             NOUN
#> 8             VERB
#> 10            NOUN
```

`pre`, `keyword` and `post` use the original text. The window is
measured in Unicode codepoints and stays inside the segment, so it works
without an additional tokenizer for either language. Its edge may cut a
combining sequence; it is not a grapheme count or quanteda token window.
Read the full source segment when more context is needed. The
document/segment/token keys link back to the preserved annotation
tables, including reviewer or failure reasons; source positions are
segment-local, 1-based and inclusive.

`review_queue` contains disagreements and all unavailable comparisons. A
row in that queue is a request for examination, not a declaration that
the model is wrong. Use a separate decision table and reimport a new
reference snapshot when correcting labels. Re-evaluation of those
corrected development labels does not become independent held-out
validation.

## Check the effect on each document

The installed script fixes the analysis to **exact supplied surfaces of
nouns** and TTR. No lowercasing, lemmatization or normalization is
performed. It requires complete labels in a condition before computing
its document score: an unknown label could change the selected noun
sequence.

``` r
example$differences
#>      document_id reference_nouns predicted_nouns reference_ttr predicted_ttr
#> 1        english               2               2           0.5             1
#> 2       japanese               2               2           0.5             1
#> 3  reference_gap              NA               1            NA             1
#> 4 prediction_gap               1              NA           1.0            NA
#> 5          empty               0               0            NA            NA
#>   delta_ttr      reference_status      predicted_status
#> 1       0.5                    ok                    ok
#> 2       0.5                    ok                    ok
#> 3        NA incomplete_annotation                    ok
#> 4        NA                    ok incomplete_annotation
#> 5        NA               missing               missing
example$document_scores[, c("document_id", "condition", "missing_labels",
  "observed_selected", "selected_total", "ttr", "status")]
#>       document_id condition missing_labels observed_selected selected_total ttr
#> 1         english reference              0                 2              2 0.5
#> 2         english predicted              0                 2              2 1.0
#> 3        japanese reference              0                 2              2 0.5
#> 4        japanese predicted              0                 2              2 1.0
#> 5   reference_gap reference              1                 1             NA  NA
#> 6   reference_gap predicted              0                 1              1 1.0
#> 7  prediction_gap reference              0                 1              1 1.0
#> 8  prediction_gap predicted              1                 1             NA  NA
#> 9           empty reference              0                 0              0  NA
#> 10          empty predicted              0                 0              0  NA
#>                   status
#> 1                     ok
#> 2                     ok
#> 3                     ok
#> 4                     ok
#> 5  incomplete_annotation
#> 6                     ok
#> 7                     ok
#> 8  incomplete_annotation
#> 9                missing
#> 10               missing
```

In both the English and Japanese example, each condition selects two
nouns. The reference selects the same surface twice (`cats` or `猫`),
giving TTR `1 / 2 = 0.5`. The prediction instead includes `run` or
`見る`, giving TTR `2 / 2 = 1`. The difference, predicted minus
reference, is `+0.5` in each document. The unchanged count concealed a
false positive and a false negative. These deterministic examples
demonstrate the mechanism, not its prevalence or size in a corpus, and
not equivalence of English and Japanese measurement.

For the reference-gap document, a reference-derived noun total and TTR
are `NA`, even though an observed noun is present. The prediction-gap
document has the converse limitation. `observed_selected` remains useful
as a partial count, while `selected_total` is unknown. The empty
document has zero selected tokens and an undefined TTR. None of these
documents silently disappears from the comparison.

Choose other metrics and parameters according to your research question
using
[`lexdiv_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
or the profile APIs. Keep selection, lexical form, window size and
reference resources fixed across paired conditions, and retain metric
failure reasons. An incomplete reference supports evaluation on reviewed
positions, not an unqualified full-document reference score. For larger
studies, link participant/task/register metadata by document ID;
repeated texts and tokens from one participant are not independent
observations for uncertainty estimation. The function provides
descriptive counts, not confidence intervals or a universal F1
requirement.

## Save the inputs, policy and results

The example object contains both complete inputs, reference
declarations, the evaluation and document-score settings. Keep these
together:

``` r
saveRDS(example, "annotation-evaluation.rds", version = 2)
restored <- readRDS("annotation-evaluation.rds")
replayed <- do.call(lexdiv_evaluate_annotations, restored$inputs)
stopifnot(identical(replayed, restored$evaluation))
```

Keep the installed script, package version and
[`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) with the
result to reproduce the document-score calculation too. CSV exports are
convenient for review, but alone do not preserve complete nested
metadata or the types of all-missing columns. Stored hashes identify
snapshots; they do not authenticate human judgments. When using
restricted corpora, keep the saved source-containing objects under the
corresponding access conditions rather than including them in a
distributable package.

This evaluator concerns one categorical label on fixed token boundaries.
It does not compute dependency-head attachment accuracy, identify word
senses, or establish psychological validity. The separate [annotation
sensitivity
guide](https://ryuya-dot-com.github.io/ldfreq/articles/auditing-vocabulary-profiles.md)
compares lemma/UPOS/flemma changes without designating either side as a
reference.
