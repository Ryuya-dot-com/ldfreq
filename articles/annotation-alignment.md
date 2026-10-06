# Compare token boundaries before comparing labels and document scores

## Why token numbers are insufficient

One analyzer keeps `can't` as one token; another supplies `ca` and
`n't`. Every later token index shifts, although the original text is
unchanged. Japanese compounds create the same practical problem:
`国際連合` and `国際 | 連合` require different word units. Comparing
rows would pair unrelated occurrences. Comparing only the tokens that
match could hide most of the change.

[`lexdiv_align_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_align_annotations.md)
compares original source positions and connects three distinct
quantities: segmentation correspondence across all tokens, optional
label agreement on exactly corresponding spans, and the complete
sequences needed for document metrics. Its reference is a comparison
baseline; neither segmentation is automatically the correct linguistic
unit.

## Import the complete annotations

Use
[`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
separately for each analyzer’s output, with the same original
document/segment IDs and text. Keep all non-whitespace source text,
including punctuation, before applying analytical exclusions. The
importer checks every surface and records segment-local, one-based,
inclusive Unicode codepoint positions. No text normalization or
retokenization occurs here. Byte offsets, UTF-16 offsets and grapheme
clusters are different coordinate systems. Changed segment rosters are
rejected rather than guessed into alignment.

The installed, authored English/Japanese example runs entirely offline:

``` r
env <- new.env(parent = baseenv())
sys.source(system.file("examples", "annotation-alignment.R",
  package = "ldfreq", mustWork = TRUE), env)
example <- env$annotation_alignment_example
aligned <- example$alignment
aligned$groups[c("document_id", "keyword", "reference_n",
                 "predicted_n", "relation")]
#>   document_id  keyword reference_n predicted_n relation
#> 1     english    can't           1           2    split
#> 2     english    can't           1           2    split
#> 3     english  re-read           1           3    split
#> 4     english        .           1           1    exact
#> 5    japanese 国際連合           1           2    split
#> 6    japanese       と           1           1    exact
#> 7    japanese 国際連合           1           2    split
#> 8    japanese       。           1           1    exact
#> 9       short       猫           1           1    exact
```

The relation is directional: `split` means one reference token and
multiple predicted tokens; `merge` means the reverse. `complex` means
overlapping many-to-many spans, such as `AB | C` versus `A | BC`. A
single token on each side with different endpoints is `changed_span`.
Optional explicit whitespace tokens can produce `reference_only` or
`prediction_only` groups. No labels are propagated from a whole compound
to its parts.

`aligned$review_queue` contains all non-exact groups with `pre`,
`keyword` and `post` for reading the original context. Join its
`alignment_id` to `aligned$members` to recover every token on both
sides. The original compound IDs and both complete inputs preserve other
annotations and reviewer notes. These group IDs identify this result,
not a permanent registry of occurrences.

## Report correspondence and conditional label agreement separately

``` r
aligned$summary
#>             measure reference_n predicted_n matched fp fn precision    recall
#> 1        token_span           9          15       4 11  5 0.2666667 0.4444444
#> 2 internal_boundary           6          12       6  6  0 0.5000000 1.0000000
#>          f1
#> 1 0.3333333
#> 2 0.6666667
aligned$annotation_evaluation$summary[
  c("tokens", "reference_available", "paired", "agreement_among_paired")]
#>   tokens reference_available paired agreement_among_paired
#> 1      4                   4      4                      1
```

Only four pairs have identical spans out of nine reference tokens and
fifteen predicted tokens: reference-side coverage is `4 / 9`, and
predicted-side coverage is `4 / 15`. All four paired labels agree.
Reporting only their 100% agreement would obscure the segmentation
differences. Punctuation participates in these counts; do not describe
them as content-word accuracy.

The `token_span` row’s recall and precision give these respective
coverage rates. The `internal_boundary` row compares junctions defined
by **both** the left token’s end and the right token’s start. This
preserves whitespace gaps and ownership; compulsory segment edges are
excluded. Zero- and one-token segments therefore have no boundary
denominator, yielding `NA`, not a perfect score. This declared junction
convention may differ from an external benchmark.

To request label evaluation, supply all of `column`, `labels`, and
`reference_info`, using the same inventory and reference declarations as
[`lexdiv_evaluate_annotations()`](https://ryuya-dot-com.github.io/ldfreq/articles/annotation-evaluation.md).
Omit all three for geometry alone. The conditional label evaluator
retains both original token indices and counts missing predictions on
available references as false negatives. Non-exact spans are outside its
label denominators, with their exclusion reasons visible in
`members$relation`. Labels absent on exact spans remain explicit too.
Interpret errors only against a suitable reference standard; these
authored labels provide no accuracy evidence for a real analyzer.

## Calculate document metrics from each complete sequence

``` r
example$differences
#>   document_id metric_id reference_N predicted_N reference_V predicted_V
#> 1     english       ttr           4           8           3           6
#> 2     english     mattr           4           8           3           6
#> 3    japanese       ttr           4           6           3           4
#> 4    japanese     mattr           4           6           3           4
#> 5       short       ttr           1           1           1           1
#> 6       short     mattr           1           1           1           1
#> 7       empty       ttr           0           0           0           0
#> 8       empty     mattr           0           0           0           0
#>   reference_value predicted_value       delta reference_status predicted_status
#> 1            0.75       0.7500000  0.00000000               ok               ok
#> 2            0.75       0.8500000  0.10000000               ok               ok
#> 3            0.75       0.6666667 -0.08333333               ok               ok
#> 4            0.75       0.8333333  0.08333333               ok               ok
#> 5            1.00       1.0000000  0.00000000               ok               ok
#> 6              NA              NA          NA          missing          missing
#> 7              NA              NA          NA          missing          missing
#> 8              NA              NA          NA          missing          missing
```

The Japanese example changes from four tokens and three types to six
tokens and four types. TTR changes from `3 / 4 = 0.75` to `4 / 6`, a
difference of `-1 / 12`. The English example changes from four to eight
tokens while TTR stays `0.75`: unchanged TTR does not imply unchanged
segmentation. The example also calculates MATTR with a fixed four-token
window. One-token and empty documents remain in the roster with their
metric-specific missing reasons; the requested window is not silently
reduced.

This comparison uses **all supplied surface tokens**, including
punctuation, with no POS selection or normalization. That explicit
policy isolates the segmentation contrast. For a content-word or lemma
analysis, declare the selection and lexical-form rules, retain
missing-label coverage, and do not infer a full-document score from an
incomplete reference. Metrics across different units show sensitivity to
those units; they do not establish that one analyzer yields a more valid
psychological measure. Use the whole input for each condition, rather
than computing diversity on the matched subset.

## Save and replay without rerunning an analyzer

``` r
saveRDS(example, "annotation-alignment.rds", version = 2)
restored <- readRDS("annotation-alignment.rds")
replayed <- do.call(lexdiv_align_annotations, restored$inputs)
stopifnot(identical(replayed, restored$alignment))
```

The saved object includes the original inputs, reference declarations,
metric settings and results. Keep the installed script, package version
and [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) too.
Source-containing RDS files remain subject to the original data’s access
conditions. This workflow needs no bundled corpus or model; it does not
perform word-sense disambiguation or dependency-head evaluation.
Independent reference construction and evaluation on the actual research
population are separate from this reproducible demonstration.
